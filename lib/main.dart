import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:beamer/beamer.dart';
import 'package:chess/chess.dart' as c;
import 'package:clipboard/clipboard.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:skychess/app.dart';
import 'package:skychess/app_theme.dart';
import 'package:skychess/page/home.dart';
import 'package:skychess/page/user.dart';
import 'package:skychess/service/openings.dart';
import 'package:skychess/theme_data.dart';
import 'package:skychess/widget/app_bar.dart';
import 'package:skychess/widget/game_ended.dart';
import 'package:skychess/widget/sky_button.dart';
import 'package:skychess/widget/user.dart';
import 'package:skynet/skynet.dart';

void main() async {
  SkynetConfig.host = 'skytter.hns.siasky.net'; // TODO Dynamic portal loading

  mySkyService.init();

  colorsBox = await Hive.openBox('gameColors');
  dataBox = await Hive.openBox('data');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // final String hash;

  MyApp();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AppTheme(
      data: (theme) => buildThemeData(context, theme),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp.router(
          title: 'SkyChess',
          routeInformationParser: BeamerRouteInformationParser(),
          routerDelegate: BeamerRouterDelegate(
            // TODO notFoundRedirect: SimpleBeamLocation(state, routes, navBuilder),
            locationBuilder: SimpleLocationBuilder(
              routes: {
                '/': (context) => HomePage(),
                '/play/:gameKey': (context) => GamePage(
                      true,
                      gameKey: context
                          .currentBeamLocation.state.pathParameters['gameKey'],
                    ),
                '/watch/:gameId': (context) => GamePage(
                      false,
                      gameId: context
                          .currentBeamLocation.state.pathParameters['gameId'],
                    ),
                '/user/:userId': (context) => UserPage(
                      context
                          .currentBeamLocation.state.pathParameters['userId'],
                    ),
              },
            ),
          ),
          theme: theme,
        );
      },
    );
  }
}

class GamePage extends StatefulWidget {
  final bool isPlaying;
  final String gameKey;
  final String gameId;
  final String staticFen;
  final bool fullUI;
  final double availableWidth;

  GamePage(
    this.isPlaying, {
    this.gameKey,
    this.gameId,
    this.staticFen,
    this.fullUI = true,
    this.availableWidth,
  });

  @override
  _GamePageState createState() => _GamePageState();
}

Color getColorForPiece(c.Color color) {
  return color == c.Color.BLACK ? Colors.blue.shade600 : Colors.yellowAccent;
}

class _GamePageState extends State<GamePage> {
  final chess = new c.Chess();

  String fen = '';
  String san = '';

  c.Color ownColor = c.Color.BLACK;

  String ownColorName;

  @override
  void initState() {
    if (widget.isPlaying) {
    } else {
      ownColor = c.Color.WHITE;
    }
    super.initState();
    if (widget.staticFen == null) {
      _startGame();
    } else {
      chess.load(widget.staticFen);
    }
  }

  SkynetUser skynetUser;

  int skyDBRevision = 0;

  dynamic currentData;

  Opening opening;

  void generateStateDisplay() async {
    fen = chess.generate_fen();
    san = chess.san_moves().join(' ');

    final currentFen = fen;

    final currentOpening = await openingsService.calculateOpening(
      chess.history.map((element) {
        return element.move.fromAlgebraic + element.move.toAlgebraic;
      }).toList(),
    );
    if (currentOpening == null) {
      // TODO
      return;
    }
    if (fen == currentFen) {
      if (opening?.eco != currentOpening.eco) {
        setState(() {
          opening = currentOpening;
        });
      }
    }
  }

/* TODO void moveWithStockfish() async {
    final fen = chess.generate_fen();
    final res = await http.get(Uri.http('localhost:3000', '/bestmove', {
      'fen': fen,
    }));

    print(res.body);

    await broadcastMove(null, sanMove: res.body);
  } */

  Future<void> loadCurrentData() async {
    final file = await getFile(
      skynetUser,
      'skychess-game',
    );
    currentData = json.decode(file.asString);
  }

  void _startGame() async {
    await Future.delayed(Duration(milliseconds: 10));
    showLoadingDialog(context, 'Loading game...');

    if (widget.isPlaying) {
      skynetUser = SkynetUser.fromSeedAsync(
        await SkynetUser.skyIdSeedToEd25519Seed(
          widget.gameKey,
        ),
      );

      await skynetUser.init();
    } else {
      skynetUser = SkynetUser.fromId(widget.gameId);
    }

    await loadCurrentData();

    if (widget.isPlaying) {
      ownColorName = colorsBox.get(widget.gameKey);
      print('ownColorName init $ownColorName');
    }

    if (currentData['players']['white']['state'] == 'ready' &&
        currentData['players']['black']['state'] == 'ready') {
      if (currentData['san'].isNotEmpty) {
        for (final String move in currentData['san'].split(' ')) {
          if (move.endsWith('.')) continue;
          chess.move(move);
        }
      }
      if (widget.isPlaying) {
        if (ownColorName == null) {
          showErrorDialog(
              context, 'There are already 2 players in this game', '');
          throw 'Error: There are already 2 players in this game';
        }
      }
    } else {
      if (widget.isPlaying) {
        if (ownColorName == null ||
            currentData['players'][ownColorName]['state'] != 'ready') {
          if (ownColorName == null) {
            ownColorName = currentData['players']['white']['state'] == 'ready'
                ? 'black'
                : 'white';

            colorsBox.put(widget.gameKey, ownColorName);
          }

          currentData['players'][ownColorName]['state'] = 'ready';
          for (int i = 0; i < 350; i++) {
            if (mySkyService.isLoggedIn.value != null) {
              print('[waited for login] ${i * 20}ms');
              break;
            }
            await Future.delayed(Duration(milliseconds: 20));
          }
          currentData['players'][ownColorName]['userId'] = mySkyService.userId;

          await setFile(
            skynetUser,
            'skychess-game',
            SkyFile(
              content: utf8.encode(
                json.encode(
                  currentData,
                ),
              ),
              filename: 'skychess-game.json',
            ),
          );
        } else {
          context.pop();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Invite opponent'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Click to copy invite link'),
                    onTap: () {
                      FlutterClipboard.copy(
                              '${window.location.protocol}//${window.location.host}/#/play/${widget.gameKey}')
                          .then((value) => print('copied'));
                    },
                    trailing: Icon(FontAwesomeIcons.copy),
                  ),
                  ListTile(
                    leading: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                    title: Text('Waiting on opponent...'),
                  ),
                ],
              ),
            ),
            barrierDismissible: false,
          );

          while (true) {
            await Future.delayed(Duration(seconds: 2));
            await loadCurrentData();
            if (currentData['players']['white']['state'] == 'ready' &&
                currentData['players']['black']['state'] == 'ready') {
              break;
            }
          }
        }
      }
    }
    if (widget.isPlaying) {
      print('ownColorName $ownColorName');
      ownColor = ownColorName == 'white' ? c.Color.WHITE : c.Color.BLACK;
    }
    context.pop();

    generateStateDisplay();
    possibleMoveWidgets = [];
    renderPieces();
    setState(() {});

    while (true) {
      //print('loop');

      await Future.delayed(Duration(seconds: 1));

      if (!mounted) break;
      if (gameDone) break;
      final res = await getEntry(skynetUser, 'skychess-live');

      //print('res $res');

      if (res != null) {
        //print('res.entry.revision ${res.entry.revision}');
        if (skyDBRevision < res.entry.revision) {
          skyDBRevision = res.entry.revision;

          final data = utf8.decode(res.entry.data);

          print(data);

          final parts = data.split(' ');

          final length = int.parse(parts[0]);

          if (length > chess.history.length) {
            for (int i = length - chess.history.length; i > 0; i--) {
              chess.move(parts[i]);
            }
            generateStateDisplay();

            possibleMoveWidgets = [];
            renderPieces();
            setState(() {});

            /* if (chess.turn == ownColor) {
              moveWithStockfish();
            } */
          }
        }
      }
    }
  }

  List<Widget> pieceWidgets;

  List<Widget> possibleMoveWidgets = [];

  Alignment alignmentFromPosition(int i) {
    final x = i % 8;
    final y = ((i - x) / 16).round();
    return Alignment(
      (x / 3.5 - 1),
      (ownColor == c.Color.WHITE ? 1 : -1) * (y / 3.5 - 1),
    );
  }

  int lastPossiblePieceHover;

  bool gameDone = false;
  Map<String, dynamic> endState;

  void renderPieces() {
    // int total = 0;

    final widgets = <Widget>[];

    if (chess.in_checkmate || chess.in_draw) {
      if (!gameDone) {
        gameDone = true;

        setState(() {});
      }
    }
    print(chess.in_check);

    for (int i = 0; i < 128; i++) {
      final piece = chess.board[i];
      if (piece == null) continue;

      // print('$x | $y');
      // total += piece.hashCode;
      //

      widgets.add(
        AnimatedAlign(
          key: ValueKey(piece),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutSine,
          alignment: alignmentFromPosition(i),
          child: InkWell(
            onTap: (widget.isPlaying && chess.turn == ownColor && !gameDone)
                ? () {
                    //print('$x | $y');
                    if (lastPossiblePieceHover == i &&
                        possibleMoveWidgets.isNotEmpty) {
                      setState(() {
                        possibleMoveWidgets = [];
                      });

                      return;
                    }

                    lastPossiblePieceHover = i;
                    final moves =
                        chess.generate_moves().where((move) => move.from == i);

                    /* print(chess.generate_moves());
              print(chess.moves());

              print(moves.first.fromAlgebraic);
              print(moves.first.toAlgebraic); */
                    // print(chess.move_to_san(moves.first));

                    /* chess.make_move(move);
                      possibleMoveWidgets = [];
                      renderPieces();
                      setState(() {}); */

                    possibleMoveWidgets = [];

                    for (final move in moves)
                      possibleMoveWidgets.add(Align(
                        alignment: alignmentFromPosition(move.to),
                        child: InkWell(
                          onTap: () async {
                            /*        print('calculating san...');

                            print('san $san'); */
                            // final san = chess.move_to_san(move);

                            await broadcastMove(move);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(4.0 + (iconSize * 0.2)),
                            child: Icon(
                              MdiIcons.circle,
                              // getIconForPiece(piece.type),
                              size: iconSize * 0.6,
                              color: getColorForPiece(piece.color)
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                      ));
                    setState(() {});
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: piece.type == c.PieceType.KING &&
                      piece.color == chess.turn &&
                      chess.in_check
                  ? DecoratedIcon(
                      getIconForPiece(piece.type),
                      shadows: [
                        BoxShadow(
                          blurRadius: getIconSize(context) * 0.05,
                          color: Colors.red,
                        ),
                        BoxShadow(
                          blurRadius: getIconSize(context) * 0.1,
                          color: Colors.red,
                        ),
                        BoxShadow(
                          blurRadius: getIconSize(context) * 0.2,
                          color: Colors.red,
                        ),
                        BoxShadow(
                          blurRadius: getIconSize(context) * 0.3,
                          color: Colors.red,
                        ),
                        /*   BoxShadow(
                          blurRadius: getIconSize(context) * 0.4,
                          color: Colors.red,
                        ), */
                      ],
                      // ,
                      size: iconSize,
                      color: getColorForPiece(piece.color),
                    )
                  : Icon(
                      getIconForPiece(piece.type),
                      size: iconSize,
                      color: getColorForPiece(piece.color),
                    ),
            ),
          ),
        ),
      );
    }
    pieceWidgets = widgets;
  }

  double getIconSize(BuildContext context) {
    return min(widget.availableWidth ?? MediaQuery.of(context).size.width,
                maxBoardHeight) /
            8 -
        8;
  }

  Future broadcastMove(c.Move move, {String sanMove}) async {
    final rev = skyDBRevision;

    if (move == null) {
      move = chess.generate_moves().firstWhere((element) {
        return element.fromAlgebraic == sanMove.substring(0, 2) &&
            element.toAlgebraic == sanMove.substring(2);
      });
    }

    chess.make_move(move);
    generateStateDisplay();

    possibleMoveWidgets = [];
    renderPieces();

    setState(() {});

    while (rev == skyDBRevision) {
      print('[loop] set own move');
      try {
        var str = '${chess.history.length}';

        for (final move in chess.getHistory().reversed) {
          final moveStr = ' ${move}';

          if (str.length + moveStr.length > 100) {
            break;
          }
          str += moveStr;
        }

        final res = await setEntryHelper(
          skynetUser,
          'skychess-live',
          utf8.encode(str),
          revision: skyDBRevision + 1,
        );

        if (res == true) {
          break;
        }
      } catch (e, st) {
        print(e);
        print(st);
      }
      await Future.delayed(Duration(seconds: 2));
    }
    if (skyDBRevision % 7 == 0) {
      try {
        saveGame();
      } catch (e) {
        print('Error while saving game'); // TODO show error
      }
    }
  }

  Future<void> saveGame() async {
    currentData['san'] = chess.san_moves().join(' ');
    await setFile(
      skynetUser,
      'skychess-game',
      SkyFile(
        content: utf8.encode(
          json.encode(
            currentData,
          ),
        ),
        filename: 'skychess-game.json',
      ),
    );
  }

  double iconSize = 0;

  Widget _buildUserRow(c.Color currentColor) {
    if (currentData == null) return SizedBox();

    final color = currentColor == c.Color.WHITE ? 'white' : 'black';

    final state = currentData['players'][color]['state'];
    final userId = currentData['players'][color]['userId'];

    return SizedBox(
      height: 56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == 'ready') UserWidget(userId),
          Spacer(),
          if (chess.turn == currentColor) Text('Current Turn'),
          SizedBox(
            width: 8,
          ),
          Container(
            height: 32,
            width: 32,
            color: getColorForPiece(currentColor).withOpacity(
              chess.turn == currentColor ? 1 : 0.2,
            ),
          ),
          SizedBox(
            width: 8,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> buildEndState() {
    final winnerColor = chess.turn == c.Color.WHITE ? 'black' : 'white';
    return {
      'in_draw': chess.in_draw,
      'in_stalemate': chess.in_stalemate,
      'insufficient_material': chess.insufficient_material,
      'in_threefold_repetition': chess.in_threefold_repetition,
      'too_many_moves': chess.half_moves >= 100,
      'gave_up': false,
      'winnerColor': winnerColor,
      'winnerUserId': currentData['players'][winnerColor]['userId'],
    };
  }

  Widget _buildGameDoneWidget() {
    if (endState == null) endState = buildEndState();
    return GameEndedWidget(endState);
  }

  @override
  Widget build(BuildContext context) {
    iconSize = min(widget.availableWidth ?? MediaQuery.of(context).size.width,
                maxBoardHeight) /
            8 -
        8;

    if (pieceWidgets == null) {
      renderPieces();
    }

    return Scaffold(
        appBar: widget.fullUI
            ? buildSkyChessAppBar(
                context,
                widget.isPlaying ? 'In game' : 'Watching game',
              )
            : null,
        backgroundColor: Colors.black,
        body: Row(
          // mainAxisSize: widget.fullUI ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.fullUI)
              Expanded(
                  child: gameDone
                      ? Center(
                          child: _buildGameDoneWidget(),
                        )
                      : SizedBox()),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: /* min(widget.availableWidth ?? double.infinity, */
                      maxBoardHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.fullUI) ...[
                    Expanded(
                      child: SizedBox(),
                    ),
                    _buildUserRow(
                      ownColor == c.Color.WHITE ? c.Color.BLACK : c.Color.WHITE,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                  ],
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: min(
                        widget.availableWidth ?? double.infinity,
                        maxBoardHeight,
                      ),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      /* width: 200,
                            height: 200, */
                      child: Stack(
                        children: [
                          Table(
                            defaultColumnWidth: FlexColumnWidth(),
                            border: TableBorder.all(
                              color: Colors.white,
                              width: 1,
                            ),
                            children: [
                              for (int y = 0; y < 8; y++)
                                TableRow(
                                  children: [
                                    for (int x = 0; x < 8; x++)
                                      TableCell(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Container(
                                            alignment: y == 7
                                                ? Alignment.bottomLeft
                                                : Alignment.topRight,
                                            height: 10,
                                            color: (x + y) % 2 == 1
                                                ? almostBlack
                                                : Colors.black,
                                            child: !widget.fullUI
                                                ? null
                                                : y == 7 && x == 7
                                                    ? Stack(
                                                        children: [
                                                          Align(
                                                            alignment: Alignment
                                                                .bottomLeft,
                                                            child: Text(' h'),
                                                          ),
                                                          Align(
                                                            alignment: Alignment
                                                                .topRight,
                                                            child: Text(
                                                                ownColor ==
                                                                        c.Color
                                                                            .WHITE
                                                                    ? '1 '
                                                                    : '8 '),
                                                          ),
                                                        ],
                                                      )
                                                    : y == 7
                                                        ? Text(
                                                            ' ${'abcdefgh'[x]}')
                                                        : x == 7
                                                            ? Text(
                                                                '${ownColor == c.Color.WHITE ? (8 - y) : (y + 1)} ')
                                                            : null,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                            ],
                          ),
                          if (chess.history.isNotEmpty) ...[
                            for (final pos in [
                              chess.history.last.move.from,
                              chess.history.last.move.to,
                            ])
                              Align(
                                alignment: alignmentFromPosition(pos),
                                child: Container(
                                  width: iconSize + 8,
                                  height: iconSize + 8,
                                  color: getColorForPiece(
                                    chess.history.last.move.color,
                                  ).withOpacity(0.3),
                                ),
                              ),
                          ],
                          ...pieceWidgets,
                          ...possibleMoveWidgets,
                        ],
                      ),
                    ),
                  ),
                  if (widget.fullUI) ...[
                    SizedBox(
                      height: 8,
                    ),
                    _buildUserRow(
                      ownColor,
                    ),
                    Expanded(
                      child: SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
            /*   ],
            ), */

            if (widget.fullUI)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkyButton(
                        onPressed: () {
                          FlutterClipboard.copy(
                                  '${window.location.protocol}//${window.location.host}/#/watch/${skynetUser.id}')
                              .then((value) => print('copied'));
                        },
                        child: Text('Copy public watch-only link'),
                        color: SkyColors.follow,
                      ),
                      /*     ElevatedButton(
                          onPressed: () {
                            moveWithStockfish();
                          },
                          child: Text('Manually move with Stockfish'),
                        ), */
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: SelectableText(
                          (opening == null
                                  ? ''
                                  : 'Opening: ${opening.eco} ${opening.name}') +
                              '\n\n' +
                              fen +
                              '\n\n' +
                              san,
                        ),
                      ),
                      if (!widget.isPlaying && gameDone)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                FontAwesomeIcons.arrowLeft,
                              ),
                              onPressed: chess.history.isEmpty
                                  ? null
                                  : () {
                                      final move = chess.undo_move();
                                      undoneMoves.add(chess.move_to_san(move));
                                      generateStateDisplay();

                                      renderPieces();
                                      setState(() {});
                                    },
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            IconButton(
                              icon: Icon(
                                FontAwesomeIcons.arrowRight,
                              ),
                              onPressed: undoneMoves.isEmpty
                                  ? null
                                  : () {
                                      chess.move(undoneMoves.removeLast());

                                      generateStateDisplay();

                                      // possibleMoveWidgets = [];
                                      renderPieces();
                                      setState(() {});
                                    },
                            ),
                          ],
                        ),
                      if (gameDone && widget.isPlaying)
                        SkyButton(
                          color: SkyColors.follow,
                          filled: true,
                          child: Text('Publish Game'),
                          onPressed: () async {
                            showLoadingDialog(context, 'Publishing game...');
                            try {
                              generateStateDisplay();

                              currentData['fen'] = fen;
                              currentData['san'] = san;
                              await saveGame();

                              final gameId = skynetUser.id;

                              final opponentColor =
                                  ownColorName == 'black' ? 'white' : 'black';

                              final userId = currentData['players']
                                  [opponentColor]['userId'];

                              final profile = await mySkyService.profileDAC
                                  .getProfile(userId);
                              final username = profile?.username ?? 'Anonymous';

                              final map = Map.from(currentData);
                              map['gameId'] = gameId;
                              map['endState'] = buildEndState();
                              map['opening'] = opening.toJson();

                              final ref = await mySkyService.feedDAC.createPost(
                                PostContent(
                                  ext: {
                                    'skychess': map,
                                  },
                                  link:
                                      'sia://skychess.hns/#/watch/$gameId', // TODO Change final domain to SkyChess
                                  // TODO Maybe add screenshot plugin to create image
                                  // TODO maybe create gif or video of game
                                  tags: ['skychess'],
                                  text:
                                      '', // TODO Add turn count, endgame state and opening name to title or text
                                  // TODO Add game variant and time settings to title or text
                                  textContentType: 'text/plain',
                                  title: 'Chess Game vs $username',
                                  // TODO topics: '', maybe add chess
                                ),
                              );
                              print(ref);
                              /*    } */
                              context.pop();
                              showSuccessDialog(
                                  context, 'Game posted successfully.');
                            } catch (e, st) {
                              print(e);
                              context.pop();
                              showErrorDialog(context, e, st);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ));
  }

  final undoneMoves = <String>[];
}

const map = {
  c.PieceType.BISHOP: MdiIcons.chessBishop,
  c.PieceType.KING: MdiIcons.chessKing,
  c.PieceType.KNIGHT: MdiIcons.chessKnight,
  c.PieceType.PAWN: MdiIcons.chessPawn,
  c.PieceType.QUEEN: MdiIcons.chessQueen,
  c.PieceType.ROOK: MdiIcons.chessRook,
};

IconData getIconForPiece(c.PieceType type) {
  return map[type];

  //   true ? MdiIcons.chessKing : FontAwesomeIcons.chessPawn,
}
