import 'package:skychess/app.dart';
import 'package:skychess/main.dart';
import 'package:skychess/widget/user.dart';
import 'package:chess/chess.dart' as c;

class GameEndedWidget extends StatelessWidget {
  final Map<String, dynamic> endState;

  final bool showTitle;

  GameEndedWidget(this.endState, {this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    if (endState['in_draw']) {
      return Card(
        color: almostBlack,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle) ...[
                Text(
                  'Game ended',
                  style: TextStyle(fontSize: 28),
                ),
                SizedBox(
                  height: 16,
                ),
              ],
              Text(
                'Draw',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                endState['in_stalemate']
                    ? 'Reason: In Stalemate'
                    : endState['insufficient_material']
                        ? 'Reason: Insufficient Material'
                        : endState['in_threefold']
                            ? 'Reason: In threefold repetition'
                            : 'Reason: Too many moves',
              ),
            ],
          ),
        ),
      );
    }

    final winnerColor = endState[
        'winnerColor']; //chess.turn == c.Color.WHITE ? 'black' : 'white';
    final winnerUserId = endState[
        'winnerUserId']; //currentData['players'][winnerColor]['userId'];

    return Card(
      color: almostBlack,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                'Game ended',
                style: TextStyle(fontSize: 28),
              ),
              SizedBox(
                height: 16,
              ),
            ],
            UserWidget(winnerUserId),
            SizedBox(
              height: 8,
            ),
            Text(
              'won the game',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: getColorForPiece(
                  winnerColor == 'black' ? c.Color.BLACK : c.Color.WHITE,
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text('by checkmate'),
          ],
        ),
      ),
    );
  }
}
