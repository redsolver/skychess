import 'dart:convert';

import 'package:skychess/app.dart';
import 'package:skychess/main.dart';
import 'package:skychess/widget/app_bar.dart';
import 'package:skychess/widget/game_ended.dart';
import 'package:skychess/widget/sky_button.dart';
import 'package:skychess/widget/user.dart';
import 'package:skynet/skynet.dart';

class UserPage extends StatefulWidget {
  final String userId;
  UserPage(this.userId);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  void initState() {
    // TODO More efficient
    mySkyService.loadChessGamesForUser(widget.userId).listen((event) {
      setState(() {
        if (allGames == null) allGames = [];
        allGames.addAll(event);
      });
    });
    super.initState();
  }

  List<Post> allGames;
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < maxBoardHeight;

    return Scaffold(
      appBar: buildSkyChessAppBar(context, 'User'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxBoardHeight,
          ),
          child: ListView.builder(
            itemCount: 1 + (allGames?.length ?? 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        UserWidget(widget.userId),
                        if (widget.userId == mySkyService.userId)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SkyButton(
                              // child: Text('Edit profile'),
                              color: SkyColors.red,
                              label: 'Edit profile',
                              onPressed: () {
                                // TODO !!! Link to Profile Editor
                              },
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    // TODO Show more profile information here
                    //Text(''),
                    SizedBox(
                      height: 32,
                    ),
                  ],
                );
              }
              if (allGames == null) {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ));
              }
              final game = allGames[index - 1];
              final ext = game.content.ext['skychess'];

              final gameId = ext['gameId'] ?? game.content.link.split('/').last;

              final size = isMobile ? 150 : 300.0;
              final metadataWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(game.ts))}\n'),
                  Text(
                      'Variant: ${ext['settings']['variant']}\nTime Control: ${ext['settings']['timeControl']}\n'),
                  if (ext.containsKey('opening'))
                    Text(
                        'Opening: ${ext['opening']['eco']} ${ext['opening']['name']}\n'),
                  if (ext.containsKey('san')) Text(ext['san']),
                  // Text(ext.toString()),
                ],
              );

              return InkWell(
                borderRadius: borderRadius,
                onTap: () => context.beamToNamed('/watch/$gameId'),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: size,
                            height: size,
                            child: GamePage(
                              false,
                              staticFen: game.content.ext['skychess']['fen'],
                              fullUI: false,
                              availableWidth: size,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(
                                height: 8,
                              ),
                              UserWidget(ext['players']['black']['userId']),
                              isMobile
                                  ? SizedBox(
                                      height: size - 48 * 2 - 8 * 2,
                                    )
                                  : SizedBox(
                                      height: size - 48 * 2 - 8 * 2,
                                      child: ext['endState'] == null
                                          ? null
                                          : Center(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: GameEndedWidget(
                                                  ext['endState'],
                                                  showTitle: false,
                                                ),
                                              ),
                                            ),
                                    ),
                              UserWidget(ext['players']['white']['userId']),
                              const SizedBox(
                                height: 8,
                              ),
                            ],
                          ),
                          if (!isMobile) ...[
                            SizedBox(
                              width: 16,
                            ),
                            Flexible(
                              child: metadataWidget,
                            ),
                          ]
                        ],
                      ),
                      if (isMobile) ...[
                        Row(
                          children: [
                            Flexible(child: metadataWidget),
                            if (ext['endState'] != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: GameEndedWidget(
                                  ext['endState'],
                                  showTitle: false,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
