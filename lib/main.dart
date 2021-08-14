import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'common/services/auth.dart';
import 'common/services/dashboard.dart';

import 'pages/auth/auth.dart';
import 'pages/auth/phone_auth.dart';
import 'pages/profile/profile.dart';
import 'pages/dashboard/dashboard.dart';
import 'pages/dashboard/portfolio/add_portfolio.dart';
import 'pages/analysis/analysis.dart';
import 'pages/trades/trades.dart';
import 'pages/calendar/calendar.dart';
import 'pages/trends/trends.dart';
import 'pages/settings/setting.dart';

import 'pages/shimmers/shimmers.dart';

// TODO: добавить страницу для редактирования портфеля (см не final Portfolio поля) с возможностью его удаления
// TODO: см todo хэдера

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
        // StreamProvider<User?>(
        //   initialData: null,
        //   create: (ctx) => ctx.read<AuthService>().authStateChanges,
        // ),
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
          '/profile': (context) => ProfilePage(),
          '/dashboard': (context) => DashboardPage(),
          '/dashboard/add': (context) => AddPortfolioPage(),
          '/analysis': (context) => AnalysisPage(),
          '/trades': (context) => TradesPage(),
          '/calendar': (context) => CalendarPage(),
          '/trends': (context) => TrendsPage(),
          '/settings': (context) => SettingsPage(),
        },
        initialRoute: '/',
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return ConnectivityBuilder(
      builder: (context, isConnected, status) {
        if (status == ConnectivityStatus.none) {
          return DashboardShimmer();
        } else {
          return FutureBuilder(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Firebase initialization error!\n${snapshot.error.toString()}');
              } else if (snapshot.hasData) {
                return StreamBuilder<User?>(
                  stream: context.read<AuthService>().authStateChanges,
                  builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.data?.uid != null) {
                      Future.microtask(() => Navigator.popAndPushNamed(context, '/dashboard')); // Перенаправляем после выполнения build
                      return Container();
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
      },
    );
  }

  final connectionSnackbar = SnackBar(
    content: Text('Отсутствует подключение к интернету.'),
    duration: const Duration(seconds: 4),
  );
}
