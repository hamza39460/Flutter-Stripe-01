import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stripe_test/ui/PaymentScreen.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser user;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Firestore _db = Firestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      appBar: AppBar(
        title: Text("STRIPE PAYMENTS"),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SignInButton(
              Buttons.Google,
              onPressed: () async {
                await signInWithGoogle().then((value) {
                  print("going");
                  adduserToDB();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentScreen(_auth,user,_googleSignIn,_db)),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount =
        await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return 'signInWithGoogle succeeded: $user';
  }

  adduserToDB() {
    //print("here");
    _db.collection("Users").document(user.email).collection("Personal Details").add({
      "Name":user.displayName
    });
  }
}
