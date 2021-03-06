import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:pinput/pin_put/pin_put.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:track_wealth/core/util/app_color.dart';
import 'package:track_wealth/core/util/decorations.dart';
import 'package:track_wealth/features/auth/service/auth.dart';
import 'package:track_wealth/features/auth/service/auth_helpers.dart';

class PhoneAuthPage extends StatefulWidget {
  @override
  _PhoneAuthPageState createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> with SingleTickerProviderStateMixin {
  bool validPhone = false;
  bool validCode = false;

  bool isCodeSent = false;
  TextEditingController phoneNumberController = MaskedTextController(mask: '+7 (000) 000-00-00');
  FocusNode phoneNumberFocusNode = FocusNode();
  TextEditingController codeController = TextEditingController();
  FocusNode codeFocusNode = FocusNode();

  Timer? sendCodeAgainTimer;
  final int resendTimeout = 119;
  late int sendCodeAgainSecondsLeft;
  bool canSendAgain = false;

  late String phoneVerificationId;
  late ConfirmationResult webAuthResult;

  bool isError = false;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    sendCodeAgainSecondsLeft = resendTimeout;
  }

  @override
  void dispose() {
    super.dispose();
    if ((sendCodeAgainTimer != null) && sendCodeAgainTimer!.isActive) sendCodeAgainTimer!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Text(
                    !isCodeSent ? '?????????????? ?????????? ????????????????, ?????????? ?????????? ?????? ????????????????????????????????????.' : '???????????????? ?????? ?? ??????????',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 30),
                  phoneTextField(),
                ],
              ),
            ),
            if (isCodeSent) ...{codeTextField(), submitButton()} else nextButton(),
          ],
        ),
      ),
    );
  }

  Widget nextButton() {
    return sampleButton(
      title: '??????????',
      onTap: () {
        authenticatePhoneNumber();
        setState(() {
          isCodeSent = true;
          codeController.text = '';
          restartSendAgainTimer();
        });
        codeFocusNode.requestFocus();
      },
      canTap: validPhone,
    );
  }

  Widget submitButton() {
    return sampleButton(
      title: '??????????????????????',
      onTap: submitCode,
      canTap: validCode,
    );
  }

  Widget phoneTextField() {
    return TextFormField(
      focusNode: phoneNumberFocusNode,
      controller: phoneNumberController,
      style: TextStyle(fontSize: 22),
      textAlign: isCodeSent ? TextAlign.center : TextAlign.start,
      decoration: myInputDecoration.copyWith(
        disabledBorder: InputBorder.none,
        counterText: '',
        hintText: '+7 (999) 999-99-99',
      ),
      keyboardType: TextInputType.number,
      enabled: !isCodeSent,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (String value) {
        setState(() => validPhone = value.length >= 11);
      },
    );
  }

  Widget codeTextField() {
    BoxDecoration eachFieldDecoration = BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColor.selected)),
    );
    Color textColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);
    return Column(
      children: [
        Text(
          isError ? errorMsg : '?????????????? ?????? ???? ??????',
          textAlign: TextAlign.center,
          style: TextStyle(color: isError ? Colors.red : textColor),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
          child: PinPut(
            onTap: () => setState(() => isError = false),
            focusNode: codeFocusNode,
            controller: codeController,
            fieldsCount: 6,
            followingFieldDecoration: eachFieldDecoration,
            selectedFieldDecoration: eachFieldDecoration,
            submittedFieldDecoration: eachFieldDecoration,
            textStyle: TextStyle(fontSize: 22),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (String code) {
              setState(() => validCode = code.length == 6);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              child: Text('???????????????? ??????????', style: TextStyle(color: AppColor.selected)),
              onPressed: changePhoneNumber,
            ),
            TextButton(
              child: Text(
                canSendAgain ? '?????????????????? ??????????' : '?????????????????? ??????????: $sendCodeAgainSecondsLeft',
                style: TextStyle(color: canSendAgain ? AppColor.selected : Colors.grey),
              ),
              onPressed: canSendAgain ? sendCodeAgain : null,
            ),
          ],
        )
      ],
    );
  }

  Widget sampleButton({
    required String title,
    bool canTap = true,
    required void Function() onTap,
  }) {
    return InkWell(
      child: Container(
        width: 150,
        height: 50,
        decoration: roundedBoxDecoration,
        child: Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 22, color: canTap ? AppColor.selected : Colors.grey),
          ),
        ),
      ),
      onTap: canTap ? onTap : null,
    );
  }

  void changePhoneNumber() {
    setState(() {
      phoneNumberController.text = '';
      isCodeSent = false;
      validPhone = validCode = false;
      if (sendCodeAgainTimer!.isActive) sendCodeAgainTimer!.cancel();
    });
    Future.delayed(const Duration(milliseconds: 300)).then((value) => phoneNumberFocusNode.requestFocus());
  }

  void startSendAgainTimer() {
    const oneSec = const Duration(seconds: 1);
    sendCodeAgainTimer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (sendCodeAgainSecondsLeft == 0) {
          setState(() {
            timer.cancel();
            canSendAgain = true;
          });
        } else {
          setState(() {
            sendCodeAgainSecondsLeft--;
          });
        }
      },
    );
  }

  void restartSendAgainTimer() {
    setState(() {
      canSendAgain = false;
      sendCodeAgainSecondsLeft = resendTimeout;
      startSendAgainTimer();
    });
  }

  void sendCodeAgain() {
    authenticatePhoneNumber();
    restartSendAgainTimer();
  }

  void authenticatePhoneNumber() async {
    String phoneNumber = phoneNumberController.text; // .replaceAll(RegExp(r'[^0-9+]+'), ''), // ???????????? + ?? ??????????

    if (kIsWeb) {
      webAuthResult = await context.read<AuthService>().webSignInWithPhoneNumber(phoneNumber);
      setState(() {});
    } else {
      await context.read<AuthService>().signInWithPhoneNumber(
            context: context,
            phoneNumber: phoneNumber,
            codeSent: (String verificationId, int? forceResendingToken) {
              setState(() => phoneVerificationId = verificationId);
            },
          );
    }
  }

  void submitCode() async {
    codeFocusNode.unfocus();
    if (kIsWeb) {
      try {
        await webAuthResult.confirm(codeController.text);
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        codeErrorUpdate(e.code);
      }
    } else {
      PhoneAuthCredential creds = PhoneAuthProvider.credential(
        verificationId: phoneVerificationId,
        smsCode: codeController.text,
      );
      String res = await context.read<AuthService>().signInWithCreds(creds);
      if ((res == 'Signed in') || (res == 'session-expired'))
        Navigator.pushNamed(context, '/dashboard');
      else
        codeErrorUpdate(res);
    }
  }

  void codeErrorUpdate(String errorCode) {
    isError = true;
    codeController.text = '';
    setState(() => errorMsg = getSignInErrorMessage(errorCode));
  }
}
