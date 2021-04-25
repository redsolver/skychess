import 'package:skychess/app.dart';
import 'package:skychess/util/utils.dart';
import 'package:skynet/src/skystandards/profile.dart';

Widget buildUsernameWidget(
  String userId,
  Profile profile,
  BuildContext context, {
  bool bold = false,
  bool italic = false,
  double fontSize,
}) {
  final color = userId == mySkyService.userId
      ? SkyColors.red
      : /*  dp.isFollowing(user.id)
          ? SkyColors.follow
          : dp.isFollowingPrivately(user.id)
              ? SkyColors.private
              : */
      Theme.of(context).colorScheme.onSurface;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '${Utils.truncateWithEllipsis(profile.username ?? '[none]', 29)}',
        style: TextStyle(
          color: color,
          fontWeight: bold ? FontWeight.bold : null,
          fontStyle: italic ? FontStyle.italic : null,
          fontSize: fontSize,
        ),
      ),
    ],
  );
}
