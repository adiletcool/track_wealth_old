import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/auth/auth_page.dart';
import 'common/drawer_state.dart';
import 'common/portfolio_state.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_wealth/common/auth_service.dart';

import 'page_wrapper/page_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => DrawerState()),
        ChangeNotifierProvider(create: (ctx) => PortfolioState()),
        Provider<AuthenticationService>(
          create: (ctx) => AuthenticationService(FirebaseAuth.instance),
        ),
        StreamProvider<User /*?*/ >(
          initialData: null,
          create: (ctx) => ctx.read<AuthenticationService>().authStateChanges,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('ru'),
        ],
        title: 'TrackWealth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.light, fontFamily: 'Rubik'),
        home: FutureBuilder(
          future: _initialization,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Firebase initialization error! ${snapshot.error.toString()}');
              return Text('Firebase initialization error!');
            } else if (snapshot.hasData) {
              return AuthenticationWrapper();
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User /*?*/ firebaseUser = context.watch<User /*?*/ >();
    if (firebaseUser != null) {
      return PageWrapper();
    } else {
      return AuthPage();
    }
  }
}