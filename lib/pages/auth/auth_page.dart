import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/auth_service.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/pages/auth/phone_auth.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  bool showPassword = false;
  bool canAuth = false;
  bool isLogin = true;
  String authResult = '';
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "TRACKWEALTH",
                    style: TextStyle(color: AppColor.selectedDrawerItem, fontSize: 44, fontFamily: 'RussoOne'),
                  ),
                  SizedBox(height: 20),
                  Text(isLogin ? 'Вход' : 'Регистрация', style: TextStyle(fontSize: 30)),
                  SizedBox(height: 20),
                  Text('Через социальные сети'),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      socialAuthButton(
                        'google',
                        color: Color(0xffFF5941),
                        onTap: () => socialAuthenticate('google'),
                      ),
                      SizedBox(width: 5),
                      socialAuthButton(
                        'facebook',
                        color: Color(0xff1877F2),
                        onTap: () => socialAuthenticate('facebook'),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      socialAuthButton(
                        'vkontakte',
                        color: Color(0xff2787F5),
                        onTap: () => socialAuthenticate('vkontakte'),
                      ),
                      SizedBox(width: 5),
                      socialAuthButton(
                        'phone',
                        color: Color(0xff0c2233),
                        onTap: () => socialAuthenticate('phone'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text('С паролем'),
                  SizedBox(height: 10),
                  loginPasswordTextFields(),
                  if (authResult.isNotEmpty) ...{
                    SizedBox(height: 10),
                    SizedBox(
                      width: 385,
                      child: Text(
                        authResult,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  },
                  SizedBox(height: 10),
                  authButton(),
                  SizedBox(height: 10),
                  restorePasswordButton(),
                  changeAuthMethod(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget socialAuthButton(String title, {Color color = Colors.white, required void Function() onTap}) {
    return InkWell(
      child: Container(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 70),
          child: SizedBox(
            height: 50,
            width: 50,
            child: Image.asset(
              'assets/images/auth/$title.png',
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
            ),
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget loginPasswordTextFields() {
    Color borderColor = (Theme.of(context).brightness == Brightness.dark ? AppColor.grey : Colors.black).withOpacity(.3);
    return Container(
      height: 150,
      width: 385,
      decoration: roundedBoxDecoration.copyWith(
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          customTextField(emailController, labelText: 'Почта'),
          Divider(color: borderColor, thickness: 1, height: 1),
          customTextField(passwordController, labelText: 'Пароль', isPassword: true),
        ],
      ),
    );
  }

  Widget customTextField(TextEditingController controller, {required String labelText, bool isPassword = false}) {
    return Flexible(
      child: Center(
        child: TextField(
          onTap: () async {
            setState(() => authResult = '');

            Future.delayed(Duration(milliseconds: 300)).then(
              (value) => scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 100),
              ),
            );
          },
          onChanged: (value) => validateFields(),
          autocorrect: false,
          obscureText: isPassword ? !showPassword : false,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25),
          controller: controller,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: !isPassword ? TextInputType.emailAddress : null,
          onSubmitted: isPassword
              ? canAuth
                  ? (value) => authenticate()
                  : null
              : null,
          decoration: InputDecoration(
            hintText: labelText,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            counterText: '',
            suffixIcon: (isPassword && controller.text != '')
                ? IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: AppColor.darkGrey,
                    ),
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget restorePasswordButton() {
    return TextButton(
      child: Text('Восстановить пароль'),
      onPressed: () {},
    );
  }

  Widget changeAuthMethod() {
    return TextButton(
      child: Text(isLogin ? 'Зарегистрироваться' : 'Войти'),
      onPressed: () {
        setState(() => isLogin = !isLogin);
      },
    );
  }

  void validateFields() {
    if (emailController.text.isValidEmail() && passwordController.text.isNotEmpty) {
      canAuth = true;
    } else {
      canAuth = false;
    }
    setState(() {});
  }

  Widget authButton() {
    return InkWell(
      child: Container(
        height: 70,
        width: 385,
        decoration: roundedBoxDecoration.copyWith(
          color: canAuth ? Color(0xFF2A5BDD) : Colors.black87,
        ),
        child: Center(
          child: Text(
            isLogin ? 'Войти' : 'Зарегистрироваться',
            style: TextStyle(fontSize: 22, color: canAuth ? Colors.white : Colors.grey),
          ),
        ),
      ),
      onTap: canAuth ? authenticate : null,
    );
  }

  Future<void> authenticate() async {
    if (isLogin) {
      //! Sign in
      authResult = await context.read<AuthenticationService>().signIn(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      setState(() {}); // if error => show authResult as error message
    } else {
      //! Register
      authResult = await context.read<AuthenticationService>().signUp(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      setState(() {});
    }
  }

  Future<void> socialAuthenticate(String method) async {
    switch (method) {
      case 'google':
        return await context.read<AuthenticationService>().signInWithGoogle();

      case 'facebook':
        return await context.read<AuthenticationService>().signInWithFacebook();
      case 'vkontakte':
        return await context.read<AuthenticationService>().signInWithVk();
      case 'phone':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => PhoneAuthPage()));
        break;
      default:
        print('Auth method $method is not recognized');
    }
  }
}
