import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/access_token_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// docs/04_User_Flows.md §3, Экран 3.3. [resendOtp] is register or login —
/// whichever screen sent us here (identical "send OTP" call either way).
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({
    super.key,
    required this.identifier,
    required this.onVerified,
    required this.resendOtp,
  });

  final String identifier;

  /// Called with `isNewUser` once verification succeeds.
  final void Function(bool isNewUser) onVerified;
  final Future<void> Function(String identifier) resendOtp;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  static const _codeLength = 6;
  static const _resendCooldown = Duration(seconds: 30);

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _cooldownTimer;
  int _secondsRemaining = _resendCooldown.inSeconds;
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
    _startCooldown();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = _resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == _codeLength) {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final code = _code;
    if (code.length != _codeLength) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyOtp(widget.identifier, code);
      await SessionStorage().saveRefreshToken(result.refreshToken);
      ref.read(accessTokenProvider.notifier).set(result.accessToken);
      if (!mounted) return;
      widget.onVerified(result.isNewUser);
    } on ApiException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorMessage = l10n.errorMessageForCode(error.code, error.message);
        _isSubmitting = false;
      });
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await widget.resendOtp(widget.identifier);
      if (!mounted) return;
      _startCooldown();
    } on ApiException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorMessage = l10n.errorMessageForCode(error.code, error.message);
      });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.otpSentTo(widget.identifier), style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _codeLength,
                  (index) => _DigitField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onDigitChanged(index, value),
                    autofillHints:
                        index == 0 ? const [AutofillHints.oneTimeCode] : null,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _secondsRemaining == 0 && !_isResending ? _resend : null,
                child: Text(
                  _secondsRemaining > 0
                      ? l10n.otpResendIn(_secondsRemaining)
                      : l10n.otpResend,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DigitField extends StatelessWidget {
  const _DigitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.autofillHints,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        autofillHints: autofillHints,
        decoration: const InputDecoration(counterText: ''),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
