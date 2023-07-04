"use strict";
/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.helloWorld = void 0;
const https_1 = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
// Start writing functions
// https://firebase.google.com/docs/functions/typescript
exports.helloWorld = (0, https_1.onRequest)((request, response) => {
    logger.info("Hello logs!", { structuredData: true });
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
    }
    else {
        const userData = userWhoTriggered.data();
        const token = userData === null || userData === void 0 ? void 0 : userData.deviceToken;
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
//# sourceMappingURL=index.js.map