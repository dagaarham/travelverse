import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final _date = DateFormat('d MMM yyyy');
  static final _shortDate = DateFormat('d MMM');
  static final _rupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _compact = NumberFormat.compact(locale: 'en_IN');

  static String date(DateTime d) => _date.format(d);
  static String shortDate(DateTime d) => _shortDate.format(d);
  static String range(DateTime a, DateTime b) =>
      a.year == b.year ? '${_shortDate.format(a)} – ${_date.format(b)}' : '${date(a)} – ${date(b)}';
  static String rupees(num n) => _rupees.format(n);
  static String compact(num n) => _compact.format(n);
  static String rating(double r) => r.toStringAsFixed(1);

  static String timeAgo(DateTime t, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(t);
  }

  static String greeting({DateTime? now}) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
