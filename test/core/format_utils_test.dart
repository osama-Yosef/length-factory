import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:length_factory/core/utils/format_utils.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('FormatUtils', () {
    group('currency()', () {
      test('formats integer amount with ج.م suffix', () {
        final result = FormatUtils.currency(500);
        expect(result, contains('ج.م'));
        expect(result, contains('500'));
      });

      test('formats decimal amount correctly', () {
        expect(FormatUtils.currency(1500.50), contains('1,500.5'));
      });

      test('formats zero correctly', () {
        final result = FormatUtils.currency(0);
        expect(result, contains('0'));
        expect(result, contains('ج.م'));
      });

      test('formats large numbers with commas', () {
        expect(FormatUtils.currency(10000), contains('10,000'));
      });
    });

    group('date()', () {
      test('formats date as dd/MM/yyyy', () {
        expect(FormatUtils.date(DateTime(2026, 7, 1)), equals('01/07/2026'));
      });
    });

    group('orderStatus()', () {
      test('maps every known status', () {
        expect(FormatUtils.orderStatus('pending'), equals('منتظر'));
        expect(FormatUtils.orderStatus('preparing'), equals('جارٍ التنفيذ'));
        expect(FormatUtils.orderStatus('completed'), equals('مكتمل'));
        expect(FormatUtils.orderStatus('cancelled'), equals('ملغي'));
      });

      test('unknown status returns the raw status', () {
        expect(FormatUtils.orderStatus('unknown'), equals('unknown'));
      });
    });

    group('paymentStatus()', () {
      test('maps every known status', () {
        expect(FormatUtils.paymentStatus('unpaid'), equals('غير مدفوع'));
        expect(FormatUtils.paymentStatus('partially_paid'), equals('مدفوع جزئيًا'));
        expect(FormatUtils.paymentStatus('paid'), equals('مدفوع'));
      });
    });

    test('role() maps roles to Arabic', () {
      expect(FormatUtils.role('admin'), 'مدير');
      expect(FormatUtils.role('worker'), 'عامل');
      expect(FormatUtils.role('customer'), 'عميل');
    });
  });
}
