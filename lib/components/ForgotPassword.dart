import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../components/ForgotPassword.dart';
import '../utils/Constants.dart';
import '../utils/Urls.dart';
import '../utils/get_cookie.dart';
import '../utils/httpProxy.dart';
import 'package:form_field_validator/form_field_validator.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final forgetPasswordController = {
    'reset_code': new TextEditingController(),
    'password': new TextEditingController(),
    'confirmPassword': new TextEditingController(),
  };
  String passwordValidator(String value) {
    if (value.trim().length < 6) {
      return "password must be six(6) or more characters";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String defaultFontFamily = 'Roboto-Light.ttf';
    double defaultFontSize = 14;
    double defaultIconSize = 17;

    var scaffoldKey = GlobalKey<ScaffoldState>();

    var forgotPasswordKey = GlobalKey<FormState>();

    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: Container(
            child: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: forgotPasswordKey,
          child: ListView(
            shrinkWrap: true,
            reverse: true,
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
                    child: Image.asset("assets/images/ic_app_icon.png"),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    controller: forgetPasswordController['reset_code'],
                    showCursor: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide: BorderSide(
                          width: 0,
                          style: BorderStyle.none,
                        ),
                      ),
                      filled: true,
                      prefixIcon: Icon(
                        FontAwesomeIcons.key,
                        color: Color(0xFF666666),
                        size: defaultIconSize,
                      ),
                      fillColor: Color(0xFFF2F3F5),
                      hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: defaultFontFamily,
                          fontSize: defaultFontSize),
                      hintText: "Reset Code",
                    ),
                    validator: RequiredValidator(
                      errorText: "Required",
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    validator: passwordValidator,
                    controller: forgetPasswordController['password'],
                    showCursor: true,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
                      fillColor: Color(0xFFF2F3F5),
                      hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: defaultFontFamily,
                          fontSize: defaultFontSize),
                      hintText: "Password",
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    validator: (value) {
                      var firstValidated = passwordValidator(value);
                      if (firstValidated == null &&
                          value != forgetPasswordController['password'].text) {
                        return 'password and confirm password mismatch';
                      } else
                        return firstValidated;
                    },
                    controller: forgetPasswordController['confirmPassword'],
                    obscureText: true,
                    showCursor: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
                      fillColor: Color(0xFFF2F3F5),
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: defaultFontFamily,
                        fontSize: defaultFontSize,
                      ),
                      hintText: "Confirm Password",
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: double.infinity,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF666666),
                          size: defaultIconSize,
                        ),
                        Text(
                          "Please all details are required",
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: defaultFontFamily,
                            fontSize: defaultFontSize,
                            fontStyle: FontStyle.normal,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
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
                        if (forgotPasswordKey.currentState.validate()) {
                          var usefulResponseHeaders = await getSessionCookie();

                          final formData = {
                            'reset_code':
                                forgetPasswordController['reset_code'].text,
                            'change_password':
                                forgetPasswordController['password'].text,
                            'csrfToken':
                                usefulResponseHeaders[CSRF_TOKEN_HEADER_NAME]
                          };

                          var response = await useHttpProxy().post(
                            Uri.parse("${Urls.ROOT_URL}/api/change_password"),
                            headers: {
                              "Content-Type": "application/json",
                              'Cookie':
                                  "$SESSION_COOKIE_NAME=${usefulResponseHeaders[SESSION_COOKIE_NAME]}"
                            },
                            body: json.encode(formData),
                          );

                          var responseJson = json.decode(response.body);

                          if (responseJson['status'] == 'success') {
                            scaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Password Changed successfully",
                                ),
                              ),
                            );
                          } else {
                            scaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error while changing password",
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        "Get Reset Code",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Poppins-Medium.ttf',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      color: Color(0xFFBC1F26),
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(15.0),
                          side: BorderSide(color: Color(0xFFBC1F26))),
                    ),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFF2F3F7)),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ].reversed.toList(),
          ),
        )),
      ),
    );
  }
}
