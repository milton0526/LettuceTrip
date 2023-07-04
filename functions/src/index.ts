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

const db = admin.firestore();

exports.userTriggeredNotifications = functions
  .region("asia-east1") // You can change this to be a region closer to you
  .firestore
  .document("trips/{tripId}/chatRoom/{messageId}")
  .onCreate(async (snapshot, context) => {
    const triggerSnapshot = snapshot.data();
    const triggeredUserId = triggerSnapshot.userID;
    const userReference = db.collection("users").doc(`${triggeredUserId}`);
    const userWhoTriggered = await userReference.get();

    if (!userWhoTriggered.exists) {
      functions.logger.error("No such document", triggeredUserId);
      return;
    } else {
      const userData = userWhoTriggered.data();
      const token = userData?.deviceToken;

      const payload = {
        notification: {
          title: "New trigger!",
          body: "You triggered a notification to yourself",
        },
      };

      const response = await admin.messaging().sendToDevice(token, payload);
      response.results.forEach((result) => {
        const error = result.error;
        if (error) {
          functions.logger.error("Failed sending notification", token, error);
        }
      });
      return;
    }
  });
