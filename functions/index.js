const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyNewTemplate = functions.firestore
    .document("templates/{templateId}")
    .onCreate(async (snapshot, context) => {
        const templateData = snapshot.data() || {};
        const templateName = templateData.name || "A new template";
        const templateId = context.params.templateId;

        const payload = {
            notification: {
                title: "New Template Added!",
                body: `Check out the new ${templateName} template.`,
            },
            data: {
                templateId: templateId,
                title: "New Template Added!",
                body: `Check out the new ${templateName} template.`,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "new_templates_channel",
                    priority: "high",
                    icon: "ic_notification",
                    color: "#1A6B4A",
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
            topic: "all_users",
        };

        try {
            await admin.messaging().send(payload);
            console.log(`Successfully sent notification for template ${templateId}`);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    });
