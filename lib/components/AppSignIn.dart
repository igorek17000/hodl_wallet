import 'dart:convert';

import 'package:cryptowallet/screens/main_screen.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../components/AppSignUp.dart';
import '../utils/Constants.dart';
import '../utils/Urls.dart';
import '../utils/get_cookie.dart';
import '../utils/httpProxy.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'AppSignUp.dart';

class AppSignIn extends StatefulWidget {
  @override
  _AppSignInState createState() => _AppSignInState();
}

class _AppSignInState extends State<AppSignIn> {
  var signInController = {
    'email': new TextEditingController(),
    'password': new TextEditingController(),
  };

  var hidePassword = true;
  var hidePasswordIcon = FontAwesomeIcons.eye;
  var signInKey = GlobalKey<FormState>();
  var scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    String defaultFontFamily = 'Roboto-Light.ttf';
    double defaultFontSize = 14;
    double defaultIconSize = 17;

    return Scaffold(
        key: scaffoldKey,
        body: SafeArea(
          child: Container(
            child: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: signInKey,
              child: ListView(
                reverse: true,
                shrinkWrap: true,
                padding: EdgeInsets.all(32),
                children: <Widget>[
                  InkWell(
                    child: Container(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Icon(Icons.close),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: Image.asset("assets/logo.png"),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: signInController['email'],
                        showCursor: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(
                              width: 0,
                              style: BorderStyle.none,
                            ),
                          ),
                          filled: true,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Color(0xFF666666),
                            size: defaultIconSize,
                          ),
                          hintStyle: TextStyle(
                              color: Color(0xFF666666),
                              fontFamily: defaultFontFamily,
                              fontSize: defaultFontSize),
                          hintText: "Email",
                        ),
                        validator: MultiValidator([
                          EmailValidator(
                            errorText: 'Not a valid email',
                          ),
                          RequiredValidator(
                            errorText: 'Required',
                          ),
                        ]),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: signInController['password'],
                        showCursor: true,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(
                              width: 0,
                              style: BorderStyle.none,
                            ),
                          ),
                          filled: true,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Color(0xFF666666),
                            size: defaultIconSize,
                          ),
                          suffixIcon: GestureDetector(
                            child: Icon(
                              hidePasswordIcon,
                              color: Color(0xFF666666),
                              size: defaultIconSize,
                            ),
                            onTap: () {
                              if (hidePassword) {
                                hidePassword = false;
                                hidePasswordIcon = FontAwesomeIcons.eyeSlash;
                              } else {
                                hidePassword = true;
                                hidePasswordIcon = FontAwesomeIcons.eye;
                              }
                              setState(() {});
                            },
                          ),
                          hintStyle: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: defaultFontFamily,
                            fontSize: defaultFontSize,
                          ),
                          hintText: "Password",
                        ),
                        validator: RequiredValidator(
                          errorText: 'Required',
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          "Forgot your password?",
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: defaultFontFamily,
                            fontSize: defaultFontSize,
                            fontStyle: FontStyle.normal,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Container(
                        width: double.infinity,
                        child: RaisedButton(
                          padding: EdgeInsets.all(17.0),
                          onPressed: () async {
                            signInUser();
                          },
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Poppins-Medium.ttf',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          color: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(15.0)),
                        ),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFFF2F3F7)),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          child: Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontFamily: defaultFontFamily,
                              fontSize: defaultFontSize,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AppSignUp()),
                            )
                          },
                          child: Container(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.blue,
                                fontFamily: defaultFontFamily,
                                fontSize: defaultFontSize,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ].reversed.toList(),
              ),
            ),
          ),
        ));
  }

  void signInUser() async {
    if (signInKey.currentState.validate()) {
      var usefulResponseHeaders = await getSessionCookie();

      final formData = {
        'email': signInController['email'].text,
        'password': signInController['password'].text,
        'csrfToken': usefulResponseHeaders[CSRF_TOKEN_HEADER_NAME]
      };

      var response = await useHttpProxy().post(
        Uri.parse("${Urls.ROOT_URL}/api/login"),
        headers: {
          "Content-Type": "application/json",
          "X-Action": "login",
          'Cookie':
              "$SESSION_COOKIE_NAME=${usefulResponseHeaders[SESSION_COOKIE_NAME]}"
        },
        body: json.encode(formData),
      );

      var responseJson = json.decode(response.body);

      if (responseJson['status'] == 'success') {
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            'Sign in successful',
          ),
        ));

        var userVerified =
            response.headers['set-cookie'].split(';')[0].split('=');

        var pref = await SharedPreferences.getInstance();
        if (userVerified[0] == USER_VERIFIED) {
          pref.setString(USER_VERIFIED, userVerified[1]);
          pref.setString(
              SESSION_COOKIE_NAME, usefulResponseHeaders[SESSION_COOKIE_NAME]);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
        );
      } else if (responseJson['status'] == 'error') {
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            responseJson['error'],
          ),
        ));
      }
    }
  }
}
