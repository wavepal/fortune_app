import 'package:flutter/material.dart';
import 'dart:math';

import 'package:fortune_app/database_helper.dart';

class CoinFlipPage extends StatefulWidget {
  final int userId;

  const CoinFlipPage({Key? key, required this.userId}) : super(key: key);

  @override
  _CoinFlipPageState createState() => _CoinFlipPageState();
}

class _CoinFlipPageState extends State<CoinFlipPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHeads = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCoin() {
    setState(() {
      _isHeads = Random().nextBool();
      
      // Сохраняем результат в истории
      String result = _isHeads ? 'Орел' : 'Решка';
      DatabaseHelper.instance.addHistory(widget.userId, 'Монета', result);
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Подбрось монету')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_animation.value * pi),
                  child: Container(
                    width: 200,
                    height: 200,
                    child: _animation.value <= 0.5 ?
                      _buildCoinSide(isHeads: !_isHeads) :
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child: _buildCoinSide(isHeads: _isHeads),
                      ),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _flipCoin,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Подбросить монету', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoinSide({required bool isHeads}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        gradient: RadialGradient(
          center: Alignment(0.1, -0.1),
          focal: Alignment(0.1, -0.1),
          focalRadius: 0.15,
          radius: 0.8,
          colors: [
            Colors.yellow[300]!,
            Colors.yellow[500]!,
            Colors.yellow[700]!,
          ],
        ),
      ),
      child: Center(
        child: Text(
          isHeads ? 'О' : 'Р',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.yellow[800],
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
