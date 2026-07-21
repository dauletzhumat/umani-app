import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/usecases/start_guest_session.dart';

/// docs/04_User_Flows.md §3, Экран 4 — "Начать пользоваться".
class AuthChoiceScreen extends ConsumerStatefulWidget {
  const AuthChoiceScreen({
    super.key,
    required this.onRegisterTap,
    required this.onLoginTap,
    required this.onGuestStarted,
  });

  final VoidCallback onRegisterTap;
  final VoidCallback onLoginTap;

  /// Called once a guest session is up — straight to initial setup, no
  /// phone/OTP screens in between.
  final VoidCallback onGuestStarted;

  @override
  ConsumerState<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends ConsumerState<AuthChoiceScreen> {
  bool _isStartingGuestSession = false;
  String? _errorMessage;

  Future<void> _continueAsGuest() async {
    setState(() {
      _isStartingGuestSession = true;
      _errorMessage = null;
    });

    try {
      await ref.read(startGuestSessionProvider).call();
      if (!mounted) return;
      setState(() => _isStartingGuestSession = false);
      widget.onGuestStarted();
    } on ApiException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorMessage = l10n.errorMessageForCode(error.code, error.message);
        _isStartingGuestSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: widget.onRegisterTap,
                child: Text(l10n.authSignUpButton),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: widget.onLoginTap,
                child: Text(l10n.authLogInButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isStartingGuestSession ? null : _continueAsGuest,
                child:
                    _isStartingGuestSession
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(l10n.authContinueAsGuest),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
