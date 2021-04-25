import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:skychess/service/mysky.dart';
import 'package:skychess/service/openings.dart';
import 'package:skychess/widget/sky_button.dart';

export 'package:flutter/material.dart';
export 'package:context_extensions/context_extensions.dart';
export 'package:beamer/beamer.dart';

final mySkyService = MySkyService();
final openingsService = OpeningsService();

final borderRadius = BorderRadius.circular(8);

Box<String> colorsBox;
Box dataBox;

const maxBoardHeight = 712.0;

const almostBlack = Color(0xff181818);

final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');

class SkyColors {
  static const follow = Color(0xff19B417);

  static const lightGreen = Color(0xffd5ecdb);

  static const private = Color(0xff248ADB);

  static const red = Color(0xffEC1873);
  static const lightRed = Color(0xffFFC5DE);

/*   static Color get black => rd.isDarkTheme ? Colors.white : Color(0xff000000); */

  // rd.isDark

  static const grey1 = Color(0xff737373); // Dark
  static const grey2 = Color(0xff8c8c8c); // Normal

  static const grey3 = Color(0xff969696); // actions in dark theme

  static const grey4 = Color(0xffcccccc); // Light

/*   static Color get darkGrey => rd.isDarkTheme ? grey3 : grey1;
  static Color get grey => rd.isDarkTheme ? const Color(0xffA5A5A5) : grey2; */
  // static Color get veryLightGrey =>

  /* static Color get headerGreen =>
      rd.isDarkTheme ? Color(0xff303030) : lightGreen; */
}

void showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: ListTile(
        leading: CircularProgressIndicator(),
        title: Text(message),
      ),
    ),
    barrierDismissible: false,
  );
}

void showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: ListTile(
        leading: Icon(
          FontAwesomeIcons.checkCircle,
          color: SkyColors.follow,
        ),
        title: Text(message),
      ),
      actions: [
        SkyButton(
          child: Text('Ok'),
          color: SkyColors.follow,
          onPressed: Navigator.of(context).pop,
        ),
      ],
    ),
    barrierDismissible: true,
  );
}

void showErrorDialog(BuildContext context, dynamic e, dynamic st) {
  print(st);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Error'),
      content: ListTile(
        leading: Icon(
          FontAwesomeIcons.exclamationTriangle,
          color: SkyColors.red,
        ),
        title: Text(e.toString()),
      ),
    ),
    barrierDismissible: false,
  );
}
