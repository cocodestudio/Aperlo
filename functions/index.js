const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

exports.notifyNewTemplate = functions.firestore
    .document('templates/{templateId}')
    .onCreate(async (snapshot, context) => {
    
    if (admin.apps.length === 0) {
        admin.initializeApp();
    }

    const templateData = snapshot.data();
    const templateName = templateData.name || "A new template";
    
    const payload = {
        notification: {
            title: "New Template Added!",
            body: `Check out the new ${templateName} template.`,
        },
        data: {
            templateId: context.params.templateId
        },
        topic: "all_users"
    };
    
    try {
        await admin.messaging().send(payload);
        console.log(`Successfully sent notification for template ${context.params.templateId}`);
    } catch (error) {
        console.error("Error sending notification:", error);
    }
});
