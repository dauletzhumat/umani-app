import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/datasources/ocr_remote_datasource.dart';
import '../../data/services/receipt_capture_service.dart';
import 'receipt_preview_screen.dart';

enum _ScanState { idle, working, permissionDenied, error }

/// Camera entry point for scanning a receipt (docs/04_User_Flows.md §6,
/// Экран 6.2). Shows an illustrative frame + capture button rather than
/// an embedded live camera preview — see ReceiptCaptureService's own doc
/// comment for why. On a denied camera permission, offers a way back to
/// manual entry instead of a dead end (this task's own test-plan).
class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key, required this.onManualEntryFallback});

  final VoidCallback onManualEntryFallback;

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  _ScanState _state = _ScanState.idle;
  String? _errorMessage;

  Future<void> _capture() async {
    setState(() {
      _state = _ScanState.working;
      _errorMessage = null;
    });

    final capture = await ref.read(receiptCaptureServiceProvider).captureReceipt();

    if (capture.outcome == ReceiptCaptureOutcome.cancelled) {
      if (!mounted) return;
      setState(() => _state = _ScanState.idle);
      return;
    }

    if (capture.outcome == ReceiptCaptureOutcome.permissionDenied) {
      if (!mounted) return;
      setState(() => _state = _ScanState.permissionDenied);
      return;
    }

    try {
      final result = await ref
          .read(ocrRemoteDatasourceProvider)
          .createScan(capture.imagePath!);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewScreen(scanResult: result),
        ),
      );
      if (!mounted) return;
      setState(() => _state = _ScanState.idle);
    } on ApiException catch (exception) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _state = _ScanState.error;
        _errorMessage = l10n.errorMessageForCode(
          exception.code,
          exception.message,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptScanTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_state) {
            _ScanState.permissionDenied => _buildPermissionDenied(l10n),
            _ScanState.working => const CircularProgressIndicator(),
            _ScanState.error => _buildError(l10n),
            _ScanState.idle => _buildIdle(l10n),
          },
        ),
      ),
    );
  }

  Widget _buildIdle(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 220,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.receiptScanInstruction, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _capture,
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(l10n.receiptScanCaptureButton),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.no_photography_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          l10n.receiptScanPermissionDeniedMessage,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.onManualEntryFallback,
          child: Text(l10n.receiptScanManualEntryFallback),
        ),
      ],
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 16),
        Text(_errorMessage ?? l10n.errorNetwork, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _state = _ScanState.idle),
          child: Text(l10n.receiptScanCaptureButton),
        ),
        TextButton(
          onPressed: widget.onManualEntryFallback,
          child: Text(l10n.receiptScanManualEntryFallback),
        ),
      ],
    );
  }
}
