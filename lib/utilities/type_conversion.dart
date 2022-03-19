


// ignore: unused_element
final String _classString = 'TypeConversion'.toUpperCase();

int boolToInt(bool value) => value ? 1 : 0;

bool intToBool(int value) => value == 0 ? false : true;

String boolToStr(bool value) => value.toString();

/// true if value > 0 or is 'true'
bool strToBool(String value) {
  int? intValue = int.tryParse(value);
  if (intValue != null) return intValue > 0;
  if (value == 'true') return true;
  return false;
}

