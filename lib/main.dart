import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/pages/auth/phone_auth.dart';
import 'package:track_wealth/pages/dashboard/dashboard.dart';
import 'package:track_wealth/pages/dashboard/portfolio/add_new_portfolio.dart';
import 'package:track_wealth/pages/profile/profile.dart';
import 'pages/auth/auth_page.dart';
import 'common/services/dashboard.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_wealth/common/services/auth.dart';

// TODO: создать коллекцию tradeHistory с документами для каждого пользователя
// {'secId': {'datetime', 'boardId', 'price', 'quantity', 'shortName', 'currency', 'comission', 'note', 'type': 'buy'(sell,deposit,withdraw,earn,spend)}
// для типа earn/spend 'info': {'type': 'dividends/comission/...',}}

// TODO: добавить функционал в addOperation для акций -> проверять:
// есть ли secId
// хватает ли денег (при покупке)
// сохранять в tradeHistory
// менять assets (quantity, meanPrice), все остальное пересчитывается тут

// TODO: добавить функционал в addOperation для денег ->
// если type == spend, проверить, хватает ли средств
// если type == earn, добавить необходимость указать информацию (пришли дивы, заплатил комиссию, др)
// добавить tradeHistory
// изменить currencies

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => DashboardState()),
        ChangeNotifierProvider(create: (ctx) => TableState()),
        Provider<AuthService>(
          create: (ctx) => AuthService(FirebaseAuth.instance),
        ),
        StreamProvider<User?>(
          initialData: null,
          create: (ctx) => ctx.read<AuthService>().authStateChanges,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('ru'),
        ],
        themeMode: ThemeMode.system,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Rubik',
        ),
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Rubik',
        ),
        title: 'TrackWealth',
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => AuthenticationWrapper(),
          '/auth': (context) => AuthPage(),
          '/auth/phone': (context) => PhoneAuthPage(),
          '/dashboard': (context) => Dashboard(),
          '/dashboard/add': (context) => AddNewPortfolio(),
          '/profile': (context) => ProfilePage(),
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Firebase initialization error! ${snapshot.error.toString()}');
          return Text('Firebase initialization error!');
        } else if (snapshot.hasData) {
          return StreamBuilder(
            stream: context.read<AuthService>().authStateChanges,
            builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.data?.uid != null) {
                return Dashboard();
              } else {
                return AuthPage();
              }
            },
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
