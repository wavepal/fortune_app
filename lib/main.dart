import 'package:flutter/material.dart';
import 'package:fortune_app/coin_flip_page.dart';
import 'package:fortune_app/database_helper.dart';
import 'dart:math';

import 'package:fortune_app/dice_page.dart';
import 'package:fortune_app/login_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Инициализация Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация sqflite_ffi
  sqfliteFfiInit();

  // Установка фабрики базы данных
  databaseFactory = databaseFactoryFfi;

  // Инициализация базы данных
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Колесо Фортуны',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final int userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Главная'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage(userId: userId)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              // Выход из аккаунта
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildCard(context, 'Колесо Фортуны', Icons.casino, FortuneWheelPage(title: 'Колесо Фортуны', userId: userId)),
          _buildCard(context, 'Генератор чисел', Icons.numbers, RandomNumberGeneratorPage(userId: userId)),
          _buildCard(context, 'Генератор списков', Icons.list, RandomListGeneratorPage(userId: userId)),
          _buildCard(context, 'Кубики', Icons.casino, DicePage(userId: userId)),
          _buildCard(context, 'Монета', Icons.monetization_on, CoinFlipPage(userId: userId)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class FortuneWheelPage extends StatefulWidget {
  final String title;
  final int userId;

  const FortuneWheelPage({super.key, required this.title, required this.userId});

  @override
  State<FortuneWheelPage> createState() => _FortuneWheelPageState();
}

class _FortuneWheelPageState extends State<FortuneWheelPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<String> items = ['Элемент 1', 'Элемент 2', 'Элемент 3', 'Элемент 4', 'Элемент 5', 'Элемент 6'];
  TextEditingController _textController = TextEditingController();
  double _spinDuration = 5.0;
  double _finalAngle = 0.0;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: _spinDuration.round()),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _result = _getSelectedItem(); // Обновляем результат только по завершении
        });
      }
    });
    _textController.text = items.join('\n');
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateItems() {
    setState(() {
      items = _textController.text.split('\n').where((e) => e.trim().isNotEmpty).toList();
    });
  }

  String _getSelectedItem() {
    // Округляем угол в диапазон от 0 до 2π (полный оборот)
    double normalizedAngle = _finalAngle % (2 * pi);

    // Рассчитываем угол каждого сектора
    double sectorAngle = 2 * pi / items.length;

    // Определяем индекс сектора, на который указывает стрелка (сверху колеса)
    int selectedIndex = (items.length - (normalizedAngle / sectorAngle).floor() - 1) % items.length;

    return items[selectedIndex];
  }

  void _spinWheel() {
    setState(() {
      _result = '';
      _finalAngle = Random().nextDouble() * 2 * pi + 2 * pi * 4;
    });
    _controller.duration = Duration(seconds: _spinDuration.round());
    _controller.forward(from: 0).then((_) {
      String result = _getSelectedItem();
      DatabaseHelper.instance.addHistory(widget.userId, 'Колесо Фортуны', result);
      setState(() {
        _result = result;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: 'Введите варианты (каждый с новой строки)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _updateItems();
                  },
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _animation.value * _finalAngle,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: CustomPaint(
                        painter: WheelPainter(items: items),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Icon(Icons.arrow_left, size: 40, color: const Color.fromARGB(255, 255, 255, 255)),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Выпало: $_result',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 20),
              Slider(
                value: _spinDuration,
                min: 1,
                max: 10,
                divisions: 9,
                label: _spinDuration.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _spinDuration = value;
                  });
                },
              ),
              Text('Время вращения: ${_spinDuration.round()} сек'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _spinWheel,
                child: Text('Крутить колесо'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> items;

  WheelPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    for (int i = 0; i < items.length; i++) {
      final paint = Paint()
        ..color = Colors.primaries[i % Colors.primaries.length]
        ..style = PaintingStyle.fill;

      final startAngle = 2 * pi * i / items.length;
      final sweepAngle = 2 * pi / items.length;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i],
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: radius * 0.8);

      final double textX = centerX + (radius * 0.6) * cos(startAngle + sweepAngle / 2);
      final double textY = centerY + (radius * 0.6) * sin(startAngle + sweepAngle / 2);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(startAngle + sweepAngle / 2 + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RandomNumberGeneratorPage extends StatefulWidget {
  final int userId;

  const RandomNumberGeneratorPage({Key? key, required this.userId}) : super(key: key);

  @override
  _RandomNumberGeneratorPageState createState() => _RandomNumberGeneratorPageState();
}

class _RandomNumberGeneratorPageState extends State<RandomNumberGeneratorPage> {
  int _min = 1;
  int _max = 10;
  int _count = 5;
  bool _noDuplicates = false;
  List<int> _generatedNumbers = [];
  bool _isListView = false;

  void _generateNumbers() {
    setState(() {
      if (_noDuplicates && _count > (_max - _min + 1)) {
        _count = _max - _min + 1;
      }
      
      Set<int> numbers = {};
      while (numbers.length < _count) {
        int randomNumber = _min + Random().nextInt(_max - _min + 1);
        if (!_noDuplicates || !numbers.contains(randomNumber)) {
          numbers.add(randomNumber);
        }
      }
      _generatedNumbers = numbers.toList();
      
      // Сохраняем результат в истории
      String result = _generatedNumbers.join(', ');
      DatabaseHelper.instance.addHistory(widget.userId, 'Генератор чисел', result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Генератор случайных чисел'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'От'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _min = int.tryParse(value) ?? 1),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'До'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _max = int.tryParse(value) ?? 10),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Количество'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _count = int.tryParse(value) ?? 5),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _noDuplicates,
                  onChanged: (value) => setState(() => _noDuplicates = value ?? false),
                ),
                Text('Без дубликатов'),
                Spacer(),
                ElevatedButton(
                  onPressed: _generateNumbers,
                  child: Text('Сгенерировать'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Полученные результаты:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Row(
              children: [
                Text('Вид:'),
                SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [!_isListView, _isListView],
                  onPressed: (index) => setState(() => _isListView = index == 1),
                  children: [Icon(Icons.view_module), Icon(Icons.view_list)],
                ),
              ],
            ),
            SizedBox(height: 8),
            _isListView
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _generatedNumbers.length,
                    itemBuilder: (context, index) => Text(_generatedNumbers[index].toString()),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _generatedNumbers.map((number) => Chip(label: Text(number.toString()))).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class RandomListGeneratorPage extends StatefulWidget {
  final int userId;

  const RandomListGeneratorPage({Key? key, required this.userId}) : super(key: key);

  @override
  _RandomListGeneratorPageState createState() => _RandomListGeneratorPageState();
}

class _RandomListGeneratorPageState extends State<RandomListGeneratorPage> {
  TextEditingController _listController = TextEditingController();
  List<String> _randomizedList = [];

  @override
  void initState() {
    super.initState();
    _listController.text = '1\n2\n3\n4\n5';
  }

  void _randomizeList() {
    setState(() {
      _randomizedList = _listController.text.split('\n')..shuffle();
      
      // Сохраняем результат в истории
      String result = _randomizedList.join(', ');
      DatabaseHelper.instance.addHistory(widget.userId, 'Генератор списков', result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Генератор случайных списков'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _listController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Введите элементы списка, каждый с новой строки',
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _randomizeList,
                child: Text('Рандомизировать'),
              ),
            ),
            SizedBox(height: 16),
            if (_randomizedList.isNotEmpty) ...[
              Text('Результат:', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _randomizedList.length,
                  itemBuilder: (context, index) {
                    return Text(_randomizedList[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final int userId;

  const HistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = DatabaseHelper.instance.getHistory(widget.userId);
    });
  }

  Future<void> _deleteHistoryItem(int id) async {
    await DatabaseHelper.instance.deleteHistoryItem(id);
    _refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('История')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('История пуста'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var item = snapshot.data![index];
                return Dismissible(
                  key: Key(item['id'].toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteHistoryItem(item['id']);
                  },
                  child: ListTile(
                    title: Text(item['type']),
                    subtitle: Text(item['result']),
                    trailing: Text(item['timestamp']),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
