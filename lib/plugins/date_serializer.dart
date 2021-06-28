class DateParser {

  static String regExp = "";

  static DateTime deserialize(String date){
    try {
      if (date == null || date.toLowerCase() == "0001-01-01T00:00:00.0000000".toLowerCase()) {
        return DateTime.fromMillisecondsSinceEpoch(-2147483648);
      }

      // String afterDate = _formatStr(date);

      List<int> listParams = _stringToList(date);

      DateTime timeParser = DateTime(listParams.elementAt(0), listParams.elementAt(1), listParams.elementAt(2), listParams.elementAt(3), listParams.elementAt(4), listParams.elementAt(5));


      return timeParser;
    } catch (ex) {
      ex.toString();
    }
    return null;
  }

  static DateTime deserializeString(String date){
    try {

      bool isUsingTimeZone = false;
      if (date.contains("+")){
        isUsingTimeZone = true;
      }
      String replacers = date.replaceFirst(RegExp("T"), " ");
      if(isUsingTimeZone){
        replacers = _removeTimeZone(replacers);
      }

      return DateTime.parse(replacers);
    } catch (ex){
      ex.toString();
    }
    return null;
  }

  static String _removeTimeZone(String date){
    try {
      int timeZoneIndex = date.indexOf(RegExp(r"[+]"));
      // String timeZones = date.substring(timeZoneIndex, date.length);
      String dateIndex = date.substring(0, timeZoneIndex);
      // String dateRemovedTimeZone = date.replaceAll(RegExp(timeZones), "");
      return dateIndex;
    } catch (ex) {
      ex.toString();
    }
    return null;
  }

  static List<int> _stringToList(String date){
    try {
      bool isUsingTimeZone = false;

      if(date.contains("+")){
        isUsingTimeZone = true;
      }

      List<int> dateInt = List<int>();
      RegExp exp = RegExp(r"(\w+)");
      Iterable<Match> m = exp.allMatches(date);
      String timeZone = "";

      for(int i = 0; i < 3; i++){
        Match mValue = m.elementAt(i);
        String dateValue = mValue.group(0);

        if (i != 2){
          dateInt.add(int.parse(dateValue));
          continue;
        }

        String dateWithHours = dateValue;
        String newDateHours = dateWithHours.replaceFirst(RegExp("T"), "-");
        Iterable<Match> m2 = RegExp(r"(\w+)").allMatches(newDateHours);
        dateInt.add(int.parse(m2.elementAt(0).group(0)));
        dateInt.add(int.parse(m2.elementAt(1).group(0)));
      }

      for(int i = 3; i < 5; i++){
        Match mValue = m.elementAt(i);
        String dateValue = mValue.group(0);
        dateInt.add(int.parse(dateValue));
      }

      if(isUsingTimeZone) {
        timeZone = m.elementAt(5).group(0);
        timeZone = timeZone + "+" + m.elementAt(6).group(0);
        // Doesn't support time value yet
      }

      return dateInt;
    } catch (ex) {
      ex.toString();
    }

    return null;
  }
}
