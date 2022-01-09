import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/features/dashboard/portfolio/service/portfolio.dart';

import 'auth.dart';

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

String getSignInErrorMessage(String errorCode) {
  switch (errorCode) {
    case 'wrong-password':
      return 'Неверный пароль, либо пользователь с такой почтой использует вход через соц. сети.';
    case 'user-not-found':
      return 'Пользователь с такой почтой не найден.';
    case 'too-many-requests':
      return 'Превышено количество попыток входа. Пожалуйста, попробуйте позже.';
    case 'invalid-verification-code':
      return 'Неверный код';
    default:
      return errorCode;
  }
}

String getSignUpErrorMessage(String errorCode) {
  switch (errorCode) {
    case 'weak-password':
      return 'Слишком простой пароль.';
    case 'email-already-in-use':
      return 'Пользователь с такой почтой уже существует.';
    default:
      return errorCode;
  }
}

void userLogout(context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            child: Text(
              'Да',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              await context.read<AuthService>().signOut();

              // trigger to reload DashboardState
              context.read<PortfolioState>().loadDataState = null;

              // не popUntil, т.к. home закрылся после popAndPushNamed(context, '/dashboard'))
              Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
              Navigator.popAndPushNamed(context, '/');
            },
          ),
          TextButton(
            child: Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      );
    },
  );
}
