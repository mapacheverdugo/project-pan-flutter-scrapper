/// Convert YYMMDD to YYYY-MM-DD assuming the year is 2000 + the year
/// [date] The date to convert in YYMMDD format
/// Returns The date in YYYY-MM-DD format or null if the date is not valid
String? tryGetIsoDateFromNoSeparatorYYMMDD(String date) {
  if (date.length < 6) return null;
  final year = date.substring(0, 2);
  final month = date.substring(2, 4);
  final day = date.substring(4, 6);
  final yearInt = int.tryParse(year);
  if (yearInt == null) return null;
  return nullIfNotValidDate('${2000 + yearInt}-$month-$day');
}

/// Convert YYMMDD to YYYY-MM-DD assuming the year is 2000 + the year
/// [date] The date to convert in YYMMDD format
/// Returns The date in YYYY-MM-DD format or throw an error if the date is not valid
String getIsoDateFromNoSeparatorYYMMDD(String date) {
  final result = tryGetIsoDateFromNoSeparatorYYMMDD(date);
  if (result == null) {
    throw Exception('Invalid date');
  }
  return result;
}

/// Convert YYYYMMDD to YYYY-MM-DD
/// [date] The date to convert in YYYYMMDD format
/// Returns The date in YYYY-MM-DD format or null if the date is not valid
String? tryGetIsoDateFromNoSeparatorYYYYMMDD(String date) {
  if (date.length < 8) return null;
  final year = date.substring(0, 4);
  final month = date.substring(4, 6);
  final day = date.substring(6, 8);
  return nullIfNotValidDate('$year-$month-$day');
}

/// Convert YYYYMMDD to YYYY-MM-DD
/// [date] The date to convert in YYYYMMDD format
/// Returns The date in YYYY-MM-DD format or throw an error if the date is not valid
String getIsoDateFromNoSeparatorYYYYMMDD(String date) {
  final result = tryGetIsoDateFromNoSeparatorYYYYMMDD(date);
  if (result == null) {
    throw Exception('Invalid date');
  }
  return result;
}

/// Convert DDMMYYYY to YYYY-MM-DD
/// [date] The date to convert in DDMMYYYY format
/// Returns The date in YYYY-MM-DD format or null if the date is not valid
String? tryGetIsoDateFromNoSeparatorDDMMYYYY(String date) {
  if (date.length < 8) return null;
  final day = date.substring(0, 2);
  final month = date.substring(2, 4);
  final year = date.substring(4, 8);
  return nullIfNotValidDate('$year-$month-$day');
}

/// Convert DDMMYYYY to YYYY-MM-DD
/// [date] The date to convert in DDMMYYYY format
/// Returns The date in YYYY-MM-DD format or throw an error if the date is not valid
String getIsoDateFromNoSeparatorDDMMYYYY(String date) {
  final result = tryGetIsoDateFromNoSeparatorDDMMYYYY(date);
  if (result == null) {
    throw Exception('Invalid date');
  }
  return result;
}

/// Check if a date is valid
/// [date] The date to check
/// Returns True if the date is valid, false otherwise
bool isValidDate(String? date) {
  final dateOrNull = nullIfNotValidDate(date);
  return dateOrNull != null;
}

/// Add months to a date
/// [date] The date to add months to
/// [months] The number of months to add
/// Returns The date in YYYY-MM-DD format
String addMonthsToDate(String date, int months) {
  final dateObject = DateTime.tryParse(date);
  if (dateObject == null) {
    throw Exception('Invalid date');
  }
  final newDate = DateTime(
    dateObject.year,
    dateObject.month + months,
    dateObject.day,
  );
  return newDate.toIso8601String().split('T')[0];
}

/// Validate a date and return it the same date or throw an error if it is not valid
/// [date] The date to validate
/// Returns The date in YYYY-MM-DD format
String validateDate(String? date) {
  final dateOrNull = nullIfNotValidDate(date);
  if (dateOrNull == null) {
    throw Exception('Invalid date');
  }
  return dateOrNull;
}

/// Check if a date is valid and return it the same date or null if it is not
/// [date] The date to check
/// Returns The date in YYYY-MM-DD format or null if the date is not valid
String? nullIfNotValidDate(String? date) {
  if (date == null || date.isEmpty) {
    return null;
  }
  final dateObject = DateTime.tryParse(date);
  if (dateObject == null) {
    return null;
  }
  return date;
}

/// Convert milliseconds to YYYY-MM-DD
/// [milliseconds] The milliseconds to convert
/// Returns The date in YYYY-MM-DD format
String getIsoDateFromMilliseconds(int milliseconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  return date.toIso8601String().split('T')[0];
}

/// Convert DD/MM/YYYY or D/M/YYYY to YYYY-MM-DD
/// [date] The date to convert in DD/MM/YYYY format
/// Returns The date in YYYY-MM-DD format
String getIsoDateFromSlashSeparatedDDMMYYYYDate(String date) {
  final parts = date.split('/');
  if (parts.length != 3) {
    throw Exception('Invalid date format');
  }
  final day = parts[0].padLeft(2, '0');
  final month = parts[1].padLeft(2, '0');
  final year = parts[2];

  return '$year-$month-$day';
}

/// Convert ISO date time to YYYY-MM-DD
/// [dateTime] The date time to convert in ISO format
/// Returns The date in YYYY-MM-DD format
String getIsoDateFromIsoDateTime(String dateTime) {
  return dateTime.split('T')[0];
}

/// Convert ISO date time to HH:mm:SS time
/// [dateTime] The date time to convert in ISO format
/// Returns The time in HH:mm:SS format
String getTimeFromIsoDateTime(String dateTime) {
  final timePart = dateTime.split('T')[1];
  return timePart.split('.')[0];
}

/// Convert YYYYMMDD HH:mm:SS date time to YYYY-MM-DD
/// [dateTime] The date time to convert in YYYYMMDD HH:mm:SS format
/// Returns The date in YYYY-MM-DD format
String getIsoDateFromNoSeparatorYYYYMMDDHHmmSS(String dateTime) {
  final noSeparatorDate = dateTime.split(' ')[0];
  return getIsoDateFromNoSeparatorYYYYMMDD(noSeparatorDate);
}

/// Convert YYYYMMDD HH:mm:SS date time to HH:mm:SS time
/// [dateTime] The date time to convert in YYYYMMDD HH:mm:SS format
/// Returns The time in HH:mm:SS format
String getTimeFromNoSeparatorYYYYMMDDHHmmSS(String dateTime) {
  return dateTime.split(' ')[1];
}

