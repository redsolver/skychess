import 'dart:math';

class Utils {
  static String truncateWithEllipsis(String str, int maxLength) {
    return (str.length <= maxLength)
        ? str
        : '${str.substring(0, maxLength)}...';
  }

  static String formatCount(int count) {
    final str = '$count';
    return count >= 10000
        ? str.substring(0, str.length - 3) +
            ' ' +
            str.substring(str.length - 3, str.length)
        : '$count';
  }

  /* static String formatDate(DateTime dt) {
    return DateFormat.Hms().format(dt) +
        ' on ' +
        DateFormat.yMMMEd().format(dt);
  } */

  static final chars =
      'abcdefghijklmnopqrstuvxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static String generateUniqueString(int length) {
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  static String generateUniqueStringSecure(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
