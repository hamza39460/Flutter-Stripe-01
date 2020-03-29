const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

const firestore = admin.firestore();
const settings = { timestampInSnapshots: true };
firestore.settings(settings)
const stripe = require('stripe')('sk_test_NkjWqElyi47h9mFflhbYCUj100O3ccrRv3');
exports.createPaymentIntent = functions.https.onCall((data, context) => {
    return stripe.paymentIntents.create({
    amount: data.amount,
    currency: data.currency,
    payment_method_types: ['card'],

  });
});