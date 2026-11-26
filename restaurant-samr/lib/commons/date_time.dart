
import 'package:intl/intl.dart';

class DateTimes{

static String getFormattedDateTime() {
  DateTime now = DateTime.now();
  String formatted = DateFormat("dd MMM yyyy h:mma").format(now);
  return formatted;
}
}