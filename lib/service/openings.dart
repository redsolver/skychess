import 'dart:convert';

import 'package:flutter/services.dart';

class OpeningsService {
  Map<String, List> data;

  Future<Opening> calculateOpening(List<String> moves) async {
    print('calculateOpening $moves');
    if (data == null) {
      await loadOpenings();
    }
    var str = moves.join(' ');

    while (str.length > 0) {
      if (data.containsKey(str)) {
        print('FOUND OPENING');
        final op = data[str];
        return Opening(op[0], op[1], str);
      }
      if (str.length <= 4) {
        return null;
      }
      str = str.substring(0, str.length - 5);
    }
    return null;
  }

  Future<void> loadOpenings() async {
    data = json
        .decode(await rootBundle.loadString('assets/openings.json'))
        .cast<String, List>();
  }
}

class Opening {
  String eco;
  String name;
  String moves;
  Opening(this.eco, this.name, this.moves);

  Map<String, dynamic> toJson() => {
        'eco': eco,
        'name': name,
        'moves': moves,
      };
}
