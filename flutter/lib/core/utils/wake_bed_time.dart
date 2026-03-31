import 'time_hhmm.dart';

/// 同一天内起床 / 就寝（与 [NotificationService.scheduleReminders] 一致）。
class WakeBedTime {
  WakeBedTime._();

  static const int lastMinuteOfDay = 23 * 60 + 59;

  static int minutesFromHhMm(String raw) {
    final td = timeOfDayFromHhMm(raw);
    return td.hour * 60 + td.minute;
  }

  static String hhMmFromMinutes(int total) {
    final m = total.clamp(0, lastMinuteOfDay);
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  /// 用户新选起床时间后，保证 [wake] &lt; [bed]（同一天）。
  static WakeBedPickResult afterWakePick({
    required String newWakeHhMm,
    required String bedHhMm,
  }) {
    var wake = minutesFromHhMm(newWakeHhMm);
    var bed = minutesFromHhMm(bedHhMm);
    var adjusted = false;
    if (wake >= bed) {
      adjusted = true;
      bed = wake + 60;
      if (bed > lastMinuteOfDay) bed = lastMinuteOfDay;
      if (wake >= bed) {
        bed = wake + 1;
        if (bed > lastMinuteOfDay) bed = lastMinuteOfDay;
      }
      if (wake >= bed) {
        bed = lastMinuteOfDay;
        wake = bed - 1;
      }
    }
    final w = hhMmFromMinutes(wake);
    final b = hhMmFromMinutes(bed);
    return WakeBedPickResult(
      wake: w,
      bed: b,
      snackMessage: adjusted ? '起床须早于就寝，已自动将就寝时间调整为 $b' : null,
    );
  }

  /// 用户新选就寝时间后，保证 [wake] &lt; [bed]（同一天）。
  static WakeBedPickResult afterBedPick({
    required String wakeHhMm,
    required String newBedHhMm,
  }) {
    var wake = minutesFromHhMm(wakeHhMm);
    var bed = minutesFromHhMm(newBedHhMm);
    var adjusted = false;
    if (wake >= bed) {
      adjusted = true;
      wake = bed - 60;
      if (wake < 0) wake = 0;
      if (wake >= bed) {
        wake = bed - 1;
        if (wake < 0) wake = 0;
      }
      if (wake >= bed) {
        wake = 0;
        bed = 1;
      }
    }
    final w = hhMmFromMinutes(wake);
    final b = hhMmFromMinutes(bed);
    return WakeBedPickResult(
      wake: w,
      bed: b,
      snackMessage: adjusted ? '起床须早于就寝，已自动将起床时间调整为 $w' : null,
    );
  }
}

class WakeBedPickResult {
  const WakeBedPickResult({
    required this.wake,
    required this.bed,
    this.snackMessage,
  });

  final String wake;
  final String bed;
  final String? snackMessage;
}
