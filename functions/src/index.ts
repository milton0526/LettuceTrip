/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

// 1
export const chatMessageSent = functions.firestore
    .document("trips/{tripId}/chatRoom/{messageId}")
    .onCreate((snapshot, context) => { 
// 2
      const message = snapshot.data(); 
      const recipientId = message.id;
      console.log("RECIPIENT ID: " + recipientId);
// 3
      admin.firestore.CollectionReference('trips')
          .once("value").then((tokenSnapshot) => {
            const token = String(tokenSnapshot.val());
            const payload = {
              notification: {
                title: String(message.userID),
                body: String(message.message),
                sound: "default",
              }, 
            };
            admin.messaging().sendToDevice(token, payload);
          }
          );
      return Promise.resolve;
    });