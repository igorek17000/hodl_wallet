import 'dart:convert';
import 'package:flutter/material.dart';
import '../components/AppSignIn.dart';
import '../utils/Constants.dart';
import '../utils/Urls.dart';
import '../utils/get_cookie.dart';
import '../utils/httpProxy.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class AppSignUp extends StatefulWidget {
  @override
  _AppSignUpState createState() => _AppSignUpState();
}

class _AppSignUpState extends State<AppSignUp> {
  final signUpController = {
    'fullName': new TextEditingController(),
    'email': new TextEditingController(),
    'password': new TextEditingController(),
    'confirmPassword': new TextEditingController(),
  };

  var phoneNumber = '';

  final TextEditingController controller = TextEditingController();

  String initialCountry = 'NG';

  PhoneNumber number = PhoneNumber(isoCode: 'NG');

  @override
  Widget build(BuildContext context) {
    String defaultFontFamily = 'Roboto-Light.ttf';
    double defaultFontSize = 14;
    double defaultIconSize = 17;

    String passwordValidator(String value) {
      if (value.trim().length < 6) {
        return "password must be six(6) or more characters";
      }
      return null;
    }

    var scaffoldKey = GlobalKey<ScaffoldState>();

    var signUpKey = GlobalKey<FormState>();

    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: Container(
            child: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: signUpKey,
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
                    child: Image.asset("assets/logo.png"),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    validator: MinLengthValidator(
                      6,
                      errorText: "Fullname must be at least five(5) characters",
                    ),
                    controller: signUpController['fullName'],
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
                        FontAwesomeIcons.user,
                        color: Color(0xFF666666),
                        size: defaultIconSize,
                      ),
                      hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: defaultFontFamily,
                          fontSize: defaultFontSize),
                      hintText: "Full Name",
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    controller: signUpController['email'],
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
                  SizedBox(
                    height: 15,
                  ),
                  InternationalPhoneNumberInput(
                    onInputChanged: (number) {
                      phoneNumber = number.phoneNumber;
                    },
                    inputDecoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide: BorderSide(
                          width: 0,
                          style: BorderStyle.none,
                        ),
                      ),
                      filled: true,
                      hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: defaultFontFamily,
                          fontSize: defaultFontSize),
                      hintText: "Phone",
                    ),
                    selectorConfig: SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.disabled,
                    selectorTextStyle: TextStyle(color: Colors.black),
                    initialValue: number,
                    formatInput: false,
                    keyboardType: TextInputType.numberWithOptions(
                        signed: true, decimal: true),
                    inputBorder: OutlineInputBorder(),
                    onSaved: (PhoneNumber number) {},
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    validator: passwordValidator,
                    controller: signUpController['password'],
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
                    // ignore: missing_return
                    validator: (value) {
                      var firstValidated = passwordValidator(value);
                      if (firstValidated == null &&
                          value != signUpController['password'].text) {
                        return 'password and confirm password mismatch';
                      } else
                        return firstValidated;
                    },
                    controller: signUpController['confirmPassword'],
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
                      )),
                  SizedBox(
                    height: 15,
                  ),
                  Container(
                    width: double.infinity,
                    child: RaisedButton(
                      padding: EdgeInsets.all(17.0),
                      onPressed: () async {
                        sendSignUpRequest(
                            signUpKey: signUpKey, scaffoldKey: scaffoldKey);
                      },
                      child: Text(
                        "Sign Up",
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
                        "Already have an account? ",
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: defaultFontFamily,
                          fontSize: defaultFontSize,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AppSignIn()),
                        );
                      },
                      child: Container(
                        child: Text(
                          "Sign In",
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
        )),
      ),
    );
  }

  void sendSignUpRequest({signUpKey, scaffoldKey}) async {
    if (signUpKey.currentState.validate()) {
      var usefulResponseHeaders = await getSessionCookie();

      var checkEmailExistsResponse = await useHttpProxy()
          .post(Uri.parse('${Urls.ROOT_URL}/api/userEmailExists'),
              body: json.encode({
                'email': signUpController['email'].text,
                'csrfToken': usefulResponseHeaders[CSRF_TOKEN_HEADER_NAME]
              }),
              headers: {
            'Cookie':
                "$SESSION_COOKIE_NAME=${usefulResponseHeaders[SESSION_COOKIE_NAME]}",
            'Content-Type': 'application/json'
          });

      if (json.decode(checkEmailExistsResponse.body)['exists']) {
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            'Email already taken',
          ),
        ));
      } else {
        final formData = {
          'userName': signUpController['fullName'].text,
          'email': signUpController['email'].text,
          'phone': phoneNumber,
          'password': signUpController['password'].text,
          'passoword2': signUpController['confirmPassword'].text,
          'csrfToken': usefulResponseHeaders[CSRF_TOKEN_HEADER_NAME]
        };

        var response = await useHttpProxy().post(
          Uri.parse("${Urls.ROOT_URL}/api/login"),
          headers: {
            "Content-Type": "application/json",
            "X-Action": "sign-up",
            'Cookie':
                "$SESSION_COOKIE_NAME=${usefulResponseHeaders[SESSION_COOKIE_NAME]}"
          },
          body: json.encode(formData),
        );
        if (json.decode(response.body)['status'] == 'success') {
          signUpController['fullName'].text = '';
          signUpController['email'].text = '';
          phoneNumber = '';
          signUpController['password'].text = '';
          signUpController['confirmPassword'].text = '';

          scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text(
              'Sign up successful',
            ),
          ));
        }
      }
    }
  }
}
