import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/entities/order_entity.dart';

/// Builds an Arabic (RTL) PDF invoice for an order and prints / shares it.
class InvoicePdfService {
  pw.ThemeData? _theme;

  Future<pw.ThemeData> _loadTheme() async {
    return _theme ??= pw.ThemeData.withFont(
      base: await PdfGoogleFonts.cairoRegular(),
      bold: await PdfGoogleFonts.cairoBold(),
    );
  }

  Future<Uint8List> build(OrderEntity order, {bool showPrices = true}) async {
    final theme = await _loadTheme();
    final doc = pw.Document(title: 'فاتورة ${order.orderNumber}', theme: theme);
    const primary = PdfColor.fromInt(0xFF1D4ED8);
    const border = PdfColor.fromInt(0xFFCBD5E1);
    const soft = PdfColor.fromInt(0xFFEFF4FF);

    pw.Widget cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.right}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(AppConstants.appName,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primary)),
                  pw.Text(showPrices ? 'فاتورة طلب' : 'أمر تشغيل'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('رقم الطلب: #${order.orderNumber}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('التاريخ: ${FormatUtils.dateTime(order.createdAt)}'),
                  pw.Text('الحالة: ${FormatUtils.orderStatus(order.status)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: soft,
              border: pw.Border.all(color: border),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('العميل: ${order.customerName}'),
                if (showPrices) pw.Text('الهاتف: ${order.customerPhone}'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: border),
            columnWidths: showPrices
                ? const {
                    0: pw.FlexColumnWidth(4),
                    1: pw.FlexColumnWidth(1.4),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                  }
                : const {0: pw.FlexColumnWidth(4), 1: pw.FlexColumnWidth(1.4)},
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: soft),
                children: [
                  cell('المنتج', bold: true),
                  cell('الكمية', bold: true, align: pw.TextAlign.center),
                  if (showPrices) ...[
                    cell('سعر الوحدة', bold: true),
                    cell('الإجمالي', bold: true),
                  ],
                ],
              ),
              for (final item in order.items)
                pw.TableRow(children: [
                  cell(item.productName),
                  cell('${item.quantity}', align: pw.TextAlign.center),
                  if (showPrices) ...[
                    cell(FormatUtils.currency(item.unitPrice)),
                    cell(FormatUtils.currency(item.lineTotal)),
                  ],
                ]),
            ],
          ),
          pw.SizedBox(height: 12),
          if (showPrices)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('حالة الدفع: ${FormatUtils.paymentStatus(order.paymentStatus)}'),
                pw.Text(
                  'الإجمالي: ${FormatUtils.currency(order.totalPrice)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primary),
                ),
              ],
            ),
          if (order.hasCustomerNote) ...[
            pw.SizedBox(height: 12),
            pw.Text('ملاحظة العميل: ${order.customerNote}'),
          ],
          pw.SizedBox(height: 32),
          pw.Center(
            child: pw.Text('شكرًا لتعاملكم معنا',
                style: const pw.TextStyle(color: PdfColor.fromInt(0xFF475569))),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> printInvoice(OrderEntity order, {bool showPrices = true}) async {
    final bytes = await build(order, showPrices: showPrices);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'invoice-${order.orderNumber}');
  }

  Future<void> shareInvoice(OrderEntity order) async {
    final bytes = await build(order);
    await Printing.sharePdf(bytes: bytes, filename: 'invoice-${order.orderNumber}.pdf');
  }
}
