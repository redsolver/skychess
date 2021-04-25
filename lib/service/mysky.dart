import 'package:flutter/foundation.dart';
import 'package:simple_observable/simple_observable.dart';
import 'package:skynet/skynet.dart';

class MySkyService {
  final mySky = MySky();

  final profileDAC = ProfileDAC();

  final feedDAC = FeedDAC();

  final isLoggedIn = Observable<bool>(initialValue: null);

  String userId;

  Future<void> init() async {
    print('init');
    const dataDomain = kDebugMode ? 'localhost' : 'skytter.hns';
    print('DATA_DOMAIN $dataDomain');
    await mySky.load(
      dataDomain,
    ); // TODO Change to skychess.hns

    await mySky.loadDACs([feedDAC]);

    print('loaded DACs');

    while (true) {
      // print('check...');
      try {
        final loggedIn = await mySky.checkLogin();

        print('loggedIn $loggedIn');

        if (loggedIn) {
          userId = await mySky.userId();
          print('userId $userId');
        }

        isLoggedIn.setValue(loggedIn);
        break;
      } catch (e) {
        // print(e);
      }
      await Future.delayed(Duration(milliseconds: 200));
    }
  }

// Only do when checkLogin is false and user presses button
  Future<void> requestLoginAccess() async {
    final res = await mySky.requestLoginAccess();

    if (res == true) {
      userId = await mySky.userId();
      isLoggedIn.setValue(true);
    }
  }

  // TODO Only load posts published by skychess skapp
  Stream<List<Post>> loadChessGamesForUser(String userId) async* {
    await for (final page in feedDAC.loadPostsForUser(userId)) {
      yield page
          .where((post) => post?.content?.ext?.containsKey('skychess') ?? false)
          .toList();
      // yield page;
    }
  }
}
