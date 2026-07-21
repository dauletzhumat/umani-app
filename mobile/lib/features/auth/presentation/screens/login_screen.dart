import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// docs/04_User_Flows.md §3, Экран 3.2.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.onOtpSent, this.onRegisterTap});

  /// Called with the identifier once the OTP has been sent.
  final void Function(String identifier) onOtpSent;
  final VoidCallback? onRegisterTap;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController(text: '+7');
  bool _useEmail = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _identifierController.text.trim().isNotEmpty && !_isSubmitting;

  void _toggleMode() {
    setState(() {
      _useEmail = !_useEmail;
      _identifierController.text = _useEmail ? '' : '+7';
    });
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).login(identifier);
      if (!mounted) return;
      widget.onOtpSent(identifier);
    } on ApiException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorMessage = l10n.errorMessageForCode(error.code, error.message);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authLoginTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _identifierController,
                keyboardType:
                    _useEmail ? TextInputType.emailAddress : TextInputType.phone,
                autofillHints: [
                  _useEmail ? AutofillHints.email : AutofillHints.telephoneNumber,
                ],
                decoration: InputDecoration(
                  labelText:
                      _useEmail
                          ? l10n.authIdentifierLabelEmail
                          : l10n.authIdentifierLabelPhone,
                ),
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _toggleMode,
                  child: Text(
                    _useEmail ? l10n.authUsePhone : l10n.authUseEmail,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(l10n.authGetLoginCode),
              ),
              if (widget.onRegisterTap != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onRegisterTap,
                  child: Text(l10n.authRegisterLink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
