import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static final _currencyFmt = NumberFormat('#,##0.##', 'en');
  static final _dateFmt = DateFormat('dd/MM/yyyy', 'en');
  static final _timeFmt = DateFormat('hh:mm a', 'ar');

  static String currency(double amount) => '${_currencyFmt.format(amount)} ج.م';

  static String date(DateTime dt) => _dateFmt.format(dt);

  static String dateTime(DateTime dt) => '${_dateFmt.format(dt)} – ${_timeFmt.format(dt)}';

  static String orderStatus(String status) {
    switch (status) {
      case 'pending':    return 'منتظر';
      case 'preparing':  return 'جارٍ التنفيذ';
      case 'completed':  return 'مكتمل';
      case 'cancelled':  return 'ملغي';
      default:           return status;
    }
  }

  static String paymentStatus(String status) {
    switch (status) {
      case 'unpaid':         return 'غير مدفوع';
      case 'partially_paid': return 'مدفوع جزئيًا';
      case 'paid':           return 'مدفوع';
      default:               return status;
    }
  }

  static String role(String role) {
    switch (role) {
      case 'admin':    return 'مدير';
      case 'worker':   return 'عامل';
      case 'customer': return 'عميل';
      default:         return role;
    }
  }
}
