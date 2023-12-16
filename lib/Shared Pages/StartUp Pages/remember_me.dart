// remember_me.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RememberMeWidget extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Function(bool) onRememberMeChanged;

  const RememberMeWidget({super.key, 
    required this.usernameController,
    required this.passwordController,
    required this.onRememberMeChanged,
  });

  @override
  _RememberMeWidgetState createState() => _RememberMeWidgetState();
}

class _RememberMeWidgetState extends State<RememberMeWidget> {
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMeState();
  }

  void _loadRememberMeState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _rememberMe = prefs.getBool('rememberMe') ?? false;
    widget.onRememberMeChanged(_rememberMe);
    if (_rememberMe) {
      widget.usernameController.text = prefs.getString('username') ?? '';
      widget.passwordController.text = prefs.getString('password') ?? '';
    }
  });
}

  void _saveRememberMeState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('rememberMe', _rememberMe);
  if (_rememberMe) {
    prefs.setString('username', widget.usernameController.text);
    prefs.setString('password', widget.passwordController.text);
  }
}

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 22.0),
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value!;
              widget.onRememberMeChanged(_rememberMe);
              _saveRememberMeState();
            });
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 4.0),
          child: Text('Remember me'),
        ),
      ],
    );
  }
}
