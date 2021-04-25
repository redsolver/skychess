import 'dart:convert';
import 'dart:math';

import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:skychess/app.dart';
import 'package:skychess/model/game_settings.dart';
import 'package:skychess/util/utils.dart';
import 'package:skychess/widget/app_bar.dart';
import 'package:skychess/widget/sky_button.dart';
import 'package:skychess/widget/user.dart';
import 'package:skynet/skynet.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSkyChessAppBar(context),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Player List',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Currently hard-coded, dynamic soon with the Social DAC'),
                SizedBox(
                  height: 12,
                ),
                UserWidget(
                    '611f0e3730c028d618362aaaa19b00aa50bdf31480c627baf006abcc88f1c97a'),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SkyButton(
                child: Text(
                  'Create a game',
                  style: TextStyle(
                    fontSize: 34,
                  ),
                ),
                color: Theme.of(context).accentColor,
                filled: true,
                onPressed: createGame,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void createGame() async {
    final settings = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create a new game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Variant'),
              subtitle: Text('Standard'),
            ),
            ListTile(
              title: Text('Time Control'),
              subtitle: Text('Unlimited'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: context.pop,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: SkyColors.follow,
              ),
            ),
          ),
          SkyButton(
            color: SkyColors.follow,
            filled: true,
            onPressed: () => context.pop(GameSettings()),
            child: Text('Create'),
          ),
        ],
      ),
    );
    if (settings != null) {
      showLoadingDialog(context, 'Creating game...');
      print('CREATE GAME $settings');
      final gameKey = Utils.generateUniqueString(11);
      print(gameKey);
      final skynetUser = SkynetUser.fromSeedAsync(
        await SkynetUser.skyIdSeedToEd25519Seed(
          gameKey,
        ),
      );
      await skynetUser.init();

      // TODO Use Skynet Entropy Beacon
      final ownColor = Random.secure().nextBool() ? 'white' : 'black';

      final initialData = {
        'settings': settings,
        'players': {
          'white': {
            'userId': null,
            'state': 'none',
          },
          'black': {
            'userId': null,
            'state': 'none',
          }
        },
        'san': '',
      };

      colorsBox.put(gameKey, ownColor);

      initialData['players'][ownColor]['state'] = 'ready';
      initialData['players'][ownColor]['userId'] = mySkyService.userId;

      await setFile(
        skynetUser,
        'skychess-game',
        SkyFile(
          content: utf8.encode(
            json.encode(
              initialData,
            ),
          ),
          filename: 'skychess-game.json',
        ),
      );

      context.pop();

      context.beamToNamed('/play/$gameKey');

      // Beamer.of(context).beamToNamed('/books/2');
    }
  }
}
