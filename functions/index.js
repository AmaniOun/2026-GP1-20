
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {Translate} = require("@google-cloud/translate").v2;

initializeApp();

const translator = new Translate();

setGlobalOptions({
  region: "us-central1",
  maxInstances: 2,
});

exports.translatePlantCare = onCall(
    {
      timeoutSeconds: 30,
      memory: "256MiB",
      maxInstances: 2,
      enforceAppCheck: true,
    },
    async (request) => {
      const text = request.data?.text;
      if (typeof text !== "string" ||
          text.trim().length === 0 ||
          text.length > 3000) {
        throw new HttpsError(
            "invalid-argument",
            "Text must be between 1 and 3000 characters.",
        );
      }

      const cleanText = text.trim();

      try {
        const [translatedText] = await translator.translate(cleanText, {
          from: "en",
          to: "ar",
          format: "text",
        });

        return {
          translatedText,
          cached: false,
        };
      } catch (error) {
        console.error("Plant care translation failed:", error);
        throw new HttpsError(
            "internal",
            "Unable to translate plant care text.",
        );
      }
    },
);
