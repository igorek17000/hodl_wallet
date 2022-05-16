import 'dart:convert';

import 'package:flutter/material.dart';
import '../components/ForgotPassword.dart';
import '../utils/Constants.dart';
import '../utils/Urls.dart';
import '../utils/get_cookie.dart';
import '../utils/httpProxy.dart';
import 'package:form_field_validator/form_field_validator.dart';

class GetResetCode extends StatefulWidget {
  @override
  _GetResetCodeState createState() => _GetResetCodeState();
}

class _GetResetCodeState extends State<GetResetCode> {
  final getResetCodeController = {
    'email': new TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    String defaultFontFamily = 'Roboto-Light.ttf';
    double defaultFontSize = 14;
    double defaultIconSize = 17;

    var scaffoldKey = GlobalKey<ScaffoldState>();

    var resetCodeKey = GlobalKey<FormState>();

    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: Container(
            child: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: resetCodeKey,
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
                    controller: getResetCodeController['email'],
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
                        Icons.email_outlined,
                        color: Color(0xFF666666),
                        size: defaultIconSize,
                      ),
                      fillColor: Color(0xFFF2F3F5),
                      hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: defaultFontFamily,
                          fontSize: defaultFontSize),
                      hintText: "Email",
                    ),
                    validator: MultiValidator(
                      [
                        RequiredValidator(
                          errorText: "Required",
                        ),
                        EmailValidator(
                          errorText: 'Not a valid email',
                        ),
                      ],
                    ),
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
                        if (resetCodeKey.currentState.validate()) {
                          var usefulResponseHeaders = await getSessionCookie();

                          final formData = {
                            'email': getResetCodeController['email'].text,
                            'csrfToken':
                                usefulResponseHeaders[CSRF_TOKEN_HEADER_NAME]
                          };

                          var response = await useHttpProxy().post(
                            Uri.parse("${Urls.ROOT_URL}/api/userEmailExists"),
                            headers: {
                              "Content-Type": "application/json",
                              'Cookie':
                                  "$SESSION_COOKIE_NAME=${usefulResponseHeaders[SESSION_COOKIE_NAME]}"
                            },
                            body: json.encode(formData),
                          );

                          var responseJson = json.decode(response.body);

                          if (responseJson['exists']) {
                            var getResetCode = await useHttpProxy().post(
                              Uri.parse("${Urls.ROOT_URL}/api/get_reset_code"),
                              headers: {
                                "Content-Type": "application/json",
                                'Cookie':
                                    "$SESSION_COOKIE_NAME=${usefulResponseHeaders[SESSION_COOKIE_NAME]}"
                              },
                              body: json.encode(formData),
                            );

                            var getResetCodeJson =
                                json.decode(getResetCode.body);

                            if (getResetCodeJson['status'] == 'success') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPassword(),
                                ),
                              );
                            } else {
                              scaffoldKey.currentState.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error sending verification code to email',
                                  ),
                                ),
                              );
                            }
                          } else {
                            scaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Email not registered',
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
