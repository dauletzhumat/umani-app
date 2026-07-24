import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class DraftLineItem {
  const DraftLineItem({required this.name, required this.price});

  final String name;
  final String price;

  factory DraftLineItem.fromJson(Map<String, dynamic> json) {
    return DraftLineItem(
      name: json['name'] as String,
      price: json['price'] as String,
    );
  }
}

class DraftTransaction {
  const DraftTransaction({
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.suggestedCategoryId,
    required this.lineItems,
  });

  final String? merchant;
  final String? amount;
  final String currency;
  final String? suggestedCategoryId;
  final List<DraftLineItem> lineItems;

  factory DraftTransaction.fromJson(Map<String, dynamic> json) {
    return DraftTransaction(
      merchant: json['merchant'] as String?,
      amount: json['amount'] as String?,
      currency: json['currency'] as String,
      suggestedCategoryId: json['suggestedCategoryId'] as String?,
      lineItems:
          (json['lineItems'] as List<dynamic>)
              .map((item) => DraftLineItem.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ReceiptScanResult {
  const ReceiptScanResult({
    required this.receiptScanId,
    required this.status,
    this.draftTransaction,
  });

  final String receiptScanId;
  final String status;
  final DraftTransaction? draftTransaction;

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) {
    final draft = json['draftTransaction'] as Map<String, dynamic>?;
    return ReceiptScanResult(
      receiptScanId: json['receiptScanId'] as String,
      status: json['status'] as String,
      draftTransaction:
          draft != null ? DraftTransaction.fromJson(draft) : null,
    );
  }
}

/// Raw HTTP calls to /ocr/scans (docs/08_API.md §18).
///
/// storagePath is expected to already point at an uploaded receipt image
/// (docs/08_API.md §18: "файл предварительно загружен в Supabase Storage
/// клиентом"). No task anywhere builds that client-side Supabase Storage
/// upload step, so ReceiptScanScreen passes the locally-captured image's
/// device path through as a storagePath placeholder — real upload wiring
/// is a separate, currently-unbuilt piece.
class OcrRemoteDatasource {
  OcrRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ReceiptScanResult> createScan(String storagePath) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ocr/scans',
        data: {'storagePath': storagePath},
      );
      return ReceiptScanResult.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final ocrRemoteDatasourceProvider = Provider<OcrRemoteDatasource>((ref) {
  return OcrRemoteDatasource(ref.watch(apiClientProvider));
});
