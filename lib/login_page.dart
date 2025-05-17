import 'package:flutter/material.dart';
import 'package:fortune_app/database_helper.dart';
import 'package:fortune_app/register_page.dart';
import 'package:fortune_app/main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      bool isAuthenticated = await DatabaseHelper.instance.authenticateUser(_username, _password);
      if (isAuthenticated) {
        int userId = await DatabaseHelper.instance.getUserId(_username);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage(userId: userId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неверное имя пользователя или пароль')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Вход')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Имя пользователя'),
                validator: (value) => value!.isEmpty ? 'Введите имя пользователя' : null,
                onSaved: (value) => _username = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Введите пароль' : null,
                onSaved: (value) => _password = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Войти'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: Text('Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
