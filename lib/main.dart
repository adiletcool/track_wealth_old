import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:page_transition/page_transition.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/widgets/shimmers.dart';
import 'features/add_operation/add_operation.dart';
import 'features/auth/service/auth.dart';
import 'features/auth/ui/auth.dart';
import 'features/auth/ui/phone_auth.dart';
import 'features/calendar/calendar.dart';
import 'features/dashboard/add_portfolio/add_portfolio.dart';
import 'features/dashboard/dashboard.dart';
import 'features/dashboard/portfolio/service/portfolio.dart';
import 'features/dashboard/portfolio/service/table_state.dart';
import 'features/dashboard/portfolio_settings/settings.dart';
import 'features/settings/settings.dart';
import 'features/trends/trends.dart';

// TODO: добавить функционал в addOperation для денег ->
// если type == spend, проверить, хватает ли средств
// если type == earn, добавить необходимость указать информацию (пришли дивы, заплатил комиссию, др)

// restore user password
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => PortfolioState()),
        ChangeNotifierProvider(create: (ctx) => TableState()),
        Provider<AuthService>(create: (ctx) => AuthService(FirebaseAuth.instance)),
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
        initialRoute: '/',
        routes: {
          '/dashboard': (context) => DashboardPage(),
        },
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
              return PageTransition(child: AuthenticationWrapper(), type: PageTransitionType.rightToLeft);
            case '/auth':
              return PageTransition(child: AuthPage(), type: PageTransitionType.rightToLeft);
            case '/auth/phone':
              return PageTransition(child: PhoneAuthPage(), type: PageTransitionType.rightToLeft);
            case '/dashboard/add_portfolio':
              return PageTransition(child: AddPortfolioPage(settings.arguments as AddPortfolioArgs), type: PageTransitionType.rightToLeft);
            case '/dashboard/add_operation':
              return PageTransition(child: AddOperationPage(), type: PageTransitionType.rightToLeft);
            case '/dashboard/settings':
              return PageTransition(child: PortfolioSettingsPage(settings.arguments as PortfolioSettingsAgrs), type: PageTransitionType.rightToLeft);
            case '/calendar':
              return PageTransition(child: CalendarPage(), type: PageTransitionType.leftToRight);
            case '/trends':
              return PageTransition(child: TrendsPage(), type: PageTransitionType.leftToRight);
            case '/settings':
              return PageTransition(child: SettingsPage(), type: PageTransitionType.leftToRight);
          }
        },
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
