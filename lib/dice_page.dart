import 'package:flutter/material.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fortune_app/database_helper.dart';

class DicePage extends StatefulWidget {
  final int userId;

  const DicePage({Key? key, required this.userId}) : super(key: key);

  @override
  _DicePageState createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<int> _diceValues = [1, 1, 1, 1, 1, 1];
  int _numberOfDice = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rollDice() {
    setState(() {
      for (int i = 0; i < _numberOfDice; i++) {
        _diceValues[i] = Random().nextInt(6) + 1;
      }
      
      // Сохраняем результат в истории
      String result = _diceValues.take(_numberOfDice).join(', ');
      DatabaseHelper.instance.addHistory(widget.userId, 'Кубики', result);
    });
    _controller.forward(from: 0);
  }

  IconData _getDiceIcon(int value) {
    switch (value) {
      case 1: return FontAwesomeIcons.diceOne;
      case 2: return FontAwesomeIcons.diceTwo;
      case 3: return FontAwesomeIcons.diceThree;
      case 4: return FontAwesomeIcons.diceFour;
      case 5: return FontAwesomeIcons.diceFive;
      case 6: return FontAwesomeIcons.diceSix;
      default: return FontAwesomeIcons.dice;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Кубики')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _numberOfDice; i++)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RotationTransition(
                    turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
                    child: FaIcon(_getDiceIcon(_diceValues[i]), size: 50, color: Colors.blue),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),
          Slider(
            value: _numberOfDice.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            label: _numberOfDice.toString(),
            onChanged: (double value) {
              setState(() {
                _numberOfDice = value.toInt();
              });
            },
          ),
          ElevatedButton(
            onPressed: _rollDice,
            child: Text('Бросить кубики'),
          ),
        ],
      ),
    );
  }
}
