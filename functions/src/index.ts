// functions/src/index.ts

import * as functions from "firebase-functions";
// --- ON IMPORTE LE NOUVEAU PACKAGE ---
import { GoogleGenerativeAI } from "@google/generative-ai";

// On définit les options d'exécution
const runtimeOptions: functions.RuntimeOptions = {
  timeoutSeconds: 60,
  memory: "256MB",
};

// --- ON INITIALISE LE CLIENT GEMINI ---
// On récupère la clé API depuis la configuration sécurisée
const genAI = new GoogleGenerativeAI(functions.config().gemini.key);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" }); // On choisit le modèle 'flash', rapide et gratuit

export const summarizeText = functions
  .runWith(runtimeOptions)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "La fonction doit être appelée par un utilisateur authentifié.",
      );
    }

    const text = data.text;
    if (!text || typeof text !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "La fonction doit être appelée avec un argument 'text' de type string.",
      );
    }

    try {
      // --- NOUVELLE LOGIQUE D'APPEL À L'API GEMINI ---
      const prompt = `Résume le texte suivant pour un étudiant, de manière claire et concise, en extrayant les concepts clés. TEXTE: "${text}"`;
      
      const result = await model.generateContent(prompt);
      const response = await result.response;
      const summary = response.text();

      return { summary: summary };

    } catch (error) {
      console.error("Erreur de l'API Google AI:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Erreur lors de la génération du résumé.",
      );
    }
  });