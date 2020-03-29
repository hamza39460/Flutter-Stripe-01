import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stripe_payment/stripe_payment.dart';

class PaymentScreen extends StatefulWidget {
  FirebaseAuth _auth;
  FirebaseUser user;
  GoogleSignIn _googleSignIn;
  Firestore _db;
  PaymentScreen(this._auth, this.user, this._googleSignIn, this._db);
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    StripePayment.setOptions(StripeOptions(
        publishableKey: "pk_test_FzwVJpo0wWxVjOPPMChDkmW900e2NHveZl"));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        title: Text("STRIPE PAYMENTS"),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              signOutGoogle();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SignInButtonBuilder(
              text: 'Pay via Stripe',
              icon: Icons.credit_card,
              onPressed: (){
                startPaymentProcess();
                },
              backgroundColor: Colors.blueGrey[700],
            )
          ],
        ),
      ),
    );
  }

  void signOutGoogle() async {
    await widget._googleSignIn.signOut();

    print("User Sign Out");
  }

  final HttpsCallable INTENT = CloudFunctions.instance
  .getHttpsCallable(functionName: 'createPaymentIntent');

  startPaymentProcess() {
    StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest())
        .then((paymentMethod) {
          double amount=100*100.0; // multipliying with 100 to change $ to cents
      INTENT.call(<String, dynamic>{'amount': amount,'currency':'usd'}).then((response) {
        confirmDialog(response.data["client_secret"],paymentMethod); //function for confirmation for payment
      });
    });
  }

confirmDialog(String clientSecret,PaymentMethod paymentMethod) {
    var confirm = AlertDialog(
      title: Text("Confirm Payement"),
      content: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "Make Payment",
             // style: TextStyle(fontSize: 25),
            ),
            Text("Charge amount:\$100")
          ],
        ),
      ),
      actions: <Widget>[
        new RaisedButton(
          child: new Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
             final snackBar = SnackBar(content: Text('Payment Cancelled'),);
             Scaffold.of(context).showSnackBar(snackBar);
          },
        ),
        new RaisedButton(
          child: new Text('Confirm'),
          onPressed: () {
            Navigator.of(context).pop();
            confirmPayment(clientSecret, paymentMethod); // function to confirm Payment
          },
        ),
      ],
    );
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return confirm;
        });
  }
  

  confirmPayment(String sec, PaymentMethod paymentMethod) {
    StripePayment.confirmPaymentIntent(
      PaymentIntent(clientSecret: sec, paymentMethodId: paymentMethod.id),
    ).then((val) {
      addPaymentDetailsToFirestore(); //Function to add Payment details to firestore
            final snackBar = SnackBar(content: Text('Payment Successfull'),);
            Scaffold.of(context).showSnackBar(snackBar);
          });
    }  
    void addPaymentDetailsToFirestore() {
      widget._db.collection("Users").document(widget.user.email).collection("Payments").add({
      "currency":"USD",
      'amount':'100',
    });
    }
}
