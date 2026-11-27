import 'dart:typed_data';
import '../../data/models/member.dart';
import '../../data/models/payment.dart';
import 'formatters.dart';
import 'receipt_downloader_stub.dart'
    if (dart.library.js_interop) 'receipt_downloader_web.dart' as platform;

/// Generates a minimal, standards-compliant single-page PDF receipt and
/// triggers a browser file download on web platforms.
class ReceiptDownloader {
  ReceiptDownloader._();

  static String _escapePdfText(String input) {
    final ascii = input.replaceAll('₹', 'INR ').replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
    return ascii
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  /// Builds valid single-page PDF bytes for [payment].
  static Uint8List buildPdfBytes({
    required Payment payment,
    Member? member,
  }) {
    final memberName = member?.name ?? 'Member';
    final memberId = member?.id ?? payment.memberId;
    final memberEmail = member?.email ?? '';

    final lines = <String>[
      'FITPULSE GYM & WELLNESS - OFFICIAL PAYMENT RECEIPT',
      '------------------------------------------------------------',
      'Invoice Number : ${payment.invoiceNumber}',
      'Transaction ID : ${payment.id}',
      'Payment Date   : ${AppFormatters.formatDate(payment.date)}',
      'Status         : ${payment.status.toUpperCase()}',
      'Payment Method : ${payment.paymentMethod}',
      '------------------------------------------------------------',
      'Billed To      : $memberName',
      'Member ID      : $memberId',
      if (memberEmail.isNotEmpty) 'Email          : $memberEmail',
      '------------------------------------------------------------',
      'Service        : ${payment.effectiveServiceName}',
      'Subtotal       : ${AppFormatters.formatCurrency(payment.effectiveSubtotal)}',
      'GST (18%)      : ${AppFormatters.formatCurrency(payment.effectiveTaxAmount)}',
      'Total Paid     : ${AppFormatters.formatCurrency(payment.amount)}',
      '------------------------------------------------------------',
      'Computer-generated receipt. No signature required.',
    ];

    final streamBuffer = StringBuffer('BT\n/F1 11 Tf\n50 750 Td\n16 TL\n');
    for (var i = 0; i < lines.length; i++) {
      final escaped = _escapePdfText(lines[i]);
      if (i == 0) {
        streamBuffer.writeln('($escaped) Tj');
      } else {
        streamBuffer.writeln('T* ($escaped) Tj');
      }
    }
    streamBuffer.writeln('ET');
    final contentStream = streamBuffer.toString();

    final objects = <String>[
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n',
      '4 0 obj\n<< /Length ${contentStream.length} >>\nstream\n$contentStream\nendstream\nendobj\n',
      '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n',
    ];

    final pdf = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (final obj in objects) {
      offsets.add(pdf.length);
      pdf.write(obj);
    }

    final xrefOffset = pdf.length;
    pdf.writeln('xref');
    pdf.writeln('0 ${objects.length + 1}');
    pdf.writeln('0000000000 65535 f ');
    for (var i = 1; i <= objects.length; i++) {
      pdf.writeln('${offsets[i].toString().padLeft(10, '0')} 00000 n ');
    }
    pdf.writeln('trailer');
    pdf.writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>');
    pdf.writeln('startxref');
    pdf.writeln('$xrefOffset');
    pdf.write('%%EOF');

    return Uint8List.fromList(pdf.toString().codeUnits);
  }

  /// Generates and downloads `${payment.invoiceNumber}.pdf` when supported.
  static Future<void> downloadReceiptPdf({
    required Payment payment,
    Member? member,
  }) async {
    final bytes = buildPdfBytes(payment: payment, member: member);
    await platform.savePdfBytes(
      bytes: bytes,
      fileName: '${payment.invoiceNumber}.pdf',
    );
  }
}
