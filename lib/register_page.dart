import 'package:flutter/material.dart';
import 'package:fortune_app/database_helper.dart';
import 'package:fortune_app/login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        int userId = await DatabaseHelper.instance.createUser(_username, _password);
        if (userId != -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Регистрация успешна. Теперь вы можете войти.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при регистрации. Попробуйте другое имя пользователя.')),
          );
        }
      } catch (e) {
        print('Ошибка при регистрации: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла ошибка при регистрации. Попробуйте еще раз.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация')),
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
                onPressed: _register,
                child: Text('Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
