import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skychess/app.dart';
import 'package:skychess/widget/sky_button.dart';
import 'package:skychess/widget/user.dart';

PreferredSizeWidget buildSkyChessAppBar(BuildContext context, [String path]) {
  return AppBar(
    leading: Navigator.of(context).canPop()
        ? IconButton(
            icon: Icon(FontAwesomeIcons.home),
            onPressed: () {
              context.beamToNamed('/');
              // Navigator.of(context).pop();
            })
        : null,
    title: Text(path == null ? 'SkyChess' : 'SkyChess / $path'),
    actions: [
      StreamBuilder(
        initialData: mySkyService.isLoggedIn.value,
        stream: mySkyService.isLoggedIn.values,
        builder: (context, snapshot) {
          print(snapshot);

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                  /* valueColor:
                          AlwaysStoppedAnimation(Theme.of(context).accentColor), */

                  ),
            );
          }

          // AccountWidget(),
          if (snapshot.data) {
            return Center(child: UserWidget(mySkyService.userId));

            // Text('Logged in as ${}');
          } else {
            return Center(
              child: SkyButton(
                child: Text('Login with MySky'),
                color: Theme.of(context).accentColor,
                filled: true,
                onPressed: () {
                  mySkyService.requestLoginAccess();
                },
              ),
            );
          }
        },
      ),
      SizedBox(
        width: 8,
      ),
    ],
  );
}
