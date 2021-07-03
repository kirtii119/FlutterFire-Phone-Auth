//since there are mixed versions present here, this project needs to be run with the following command $flutter run --no-sound-null-safety

//// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Fire: Phone Auth'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<FirebaseApp>
      _firebaseApp; //The method is asynchronous and returns a Future
  TextEditingController _phoneNumber =
      TextEditingController(); //controller for Enter phone number text field
  TextEditingController _otp =
      TextEditingController(); //controller for Enter otp text field

  bool isLoggedIn = false;
  bool otpSent =
      false; //boolean variables to track the state the render UI accordingly
  late String
      uid; //for storing unique identification of every user which the firebase returns
  late String
      _verificationId; //for storing Verification ID when otp is sent(It is different from verfication code i.e. OTP)

  void _verifyOTP() async {
    // called when verify otp button is clicked

    final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp
            .text); //Returns a new instance of AuthCredential that is associated with a phone number

    try {
      await FirebaseAuth.instance.signInWithCredential(
          credential); //Tries to sign in a user with the given AuthCredential.

      if (FirebaseAuth.instance.currentUser != null) {
        //accessing the signed in user
        setState(() {
          //calls the build function to render the UI according to the boolean variable values set
          isLoggedIn = true;
          uid = FirebaseAuth.instance.currentUser.uid;
        });
      }
    } catch (e) {
      print(e); //prints firebase generated expection, if any
    }
  }

  void _sendOTP() async {
    // called when send otp button is clicked
    //verifyphonenumber method is called from firebase when phone no. is provided, the function has some call backs which must be handled
    await FirebaseAuth.instance.verifyPhoneNumber(
        //all these functions are defined below
        phoneNumber: _phoneNumber.text, //gets text from phonenumber controller
        verificationCompleted:
            verificationCompleted, //Automatic handling of the SMS code on Android devices.
        verificationFailed:
            verificationFailed, //Handle failure events such as invalid phone numbers or whether the SMS quota has been exceeded.
        codeSent:
            codeSent, //Handle when a code has been sent to the device from Firebase, used to prompt users to enter the code.
        codeAutoRetrievalTimeout:
            codeAutoRetrievalTimeout); //Handle a timeout of when automatic SMS code handling fails.

    setState(() {
      otpSent = true;
    });
  }

  void codeAutoRetrievalTimeout(String verificationId) {
    //this handler will be called if the device has not automatically resolved an SMS message within a certain timeframe
    setState(() {
      _verificationId = verificationId;
      otpSent = true;
    });
  }

  void codeSent(String verificationId, [int? a]) {
    //int a is resend token integer which is not used in this project

    setState(() {
      _verificationId = verificationId;
      otpSent = true;
    });
  }

  void verificationFailed(FirebaseAuthException exception) {
    print(exception
        .message); //firebase has its set of defined exceptions and returns the one which occurs, if at all
    setState(() {
      isLoggedIn = false;
      otpSent = false;
    });
  }

  void verificationCompleted(PhoneAuthCredential credential) async {
    //returns the credentials for the user of type phoneauthcredential
    await FirebaseAuth.instance.signInWithCredential(
        credential); //sign in the user using the received credentials
    if (FirebaseAuth.instance.currentUser != null) {
      setState(() {
        isLoggedIn = true;
        uid = FirebaseAuth.instance.currentUser.uid;
      });
    } else {
      print("Failed to Sign In");
    }
  }

  @override
  void initState() {
    //first method to be called after widget is created, called only once
    super.initState();
    _firebaseApp = Firebase
        .initializeApp(); //future is initialised here beacuse Firebase.initializeApp() should be called before usage of any flutterfire plugin
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: FutureBuilder(
          //to know the current state of future and act accordingly
          //
          future: _firebaseApp,
          builder: (context, snapshot) {
            //builder is called after future is received
            if (snapshot.connectionState ==
                ConnectionState
                    .waiting) //ConnectionState.waiting is snapshot property which tells that the future is non-null but isn't completed
              return CircularProgressIndicator();
            //ternery operators used to decide the UI layout which needs to be rendered
            return isLoggedIn
                ? Center(
                    child: Text(
                        'Welcome User!\nYour uid is: $uid'), //if user is logged in
                  )
                : otpSent
                    ? Column(
                        //if OTP is sent
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextField(
                            controller: _otp,
                            decoration: InputDecoration(
                              hintText: "Enter your OTP",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _verifyOTP,
                            child: Text("Sign In"),
                          ),
                        ],
                      )
                    : Column(
                        //if otp is not sent
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          TextField(
                            controller: _phoneNumber,
                            decoration: InputDecoration(
                              hintText: "Enter your phone number",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _sendOTP,
                            child: Text("Send OTP"),
                          ),
                        ],
                      );
          },
        ),
      ),
    );
  }
}
