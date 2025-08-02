// functions/src/index.ts

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";
import pdfParse from "pdf-parse";


// Initialisation (une seule fois)
admin.initializeApp();

// --- CONFIGURATION ---
const runtimeOptions: functions.RuntimeOptions = {
  timeoutSeconds: 300,
  memory: "512MB",
};

const genAI = new GoogleGenerativeAI(functions.config().gemini.key);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

// --- FONCTIONS "HELPER" POUR LES APPELS À L'IA ---

async function callGeminiForAnalysis(text: string): Promise<{ title: string; subject: string }> {
  const prompt = `Analyse le texte suivant. Donne-moi un titre pertinent de 5 mots maximum et détecte le sujet principal parmi cette liste : [Histoire, Biologie, Mathématiques, Physique, Général]. Formate ta réponse UNIQUEMENT en JSON valide comme ceci : {"title": "Ton titre suggéré", "subject": "Sujet détecté"}. TEXTE: "${text.substring(0, 4000)}"`;
  const result = await model.generateContent(prompt);
  const response = result.response;
  const jsonString = response.text().trim().replace(/^```json\s*|```\s*$/g, "");
  try {
    const analysis = JSON.parse(jsonString);
    return { title: analysis.title || "Titre non généré", subject: analysis.subject || "Général" };
  } catch (error) {
    console.error("Erreur de parsing JSON pour l'analyse:", jsonString);
    return { title: "Titre de la note", subject: "Général" };
  }
}

async function callGeminiForSummary(text: string): Promise<string> {
  const prompt = `Résume le texte suivant pour un étudiant, de manière claire et concise, en extrayant les concepts clés. TEXTE: "${text.substring(0, 8000)}"`;
  const result = await model.generateContent(prompt);
  const response = result.response;
  return response.text();
}

// --- FONCTIONS EXPORTÉES (VOS ENDPOINTS API) ---

export const summarizeText = functions.runWith(runtimeOptions).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Utilisateur non authentifié.");
  }
  const text = data.text;
  if (!text || typeof text !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Le paramètre 'text' est manquant ou invalide.");
  }
  
  // *** CORRECTION ICI : On utilise la fonction helper ***
  const summary = await callGeminiForSummary(text);
  return { summary: summary };
});

export const analyzeNote = functions.runWith(runtimeOptions).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Utilisateur non authentifié.");
  }
  const text = data.text;
  if (!text || typeof text !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Le paramètre 'text' est manquant ou invalide.");
  }

  // *** CORRECTION ICI : On utilise la fonction helper ***
  const analysis = await callGeminiForAnalysis(text);
  return { title: analysis.title, subject: analysis.subject };
});

export const processPdfFromUrl = functions
  .runWith(runtimeOptions)
  .https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError("unauthenticated", "Utilisateur non authentifié.");
    }
    const fileUrl = data.url;
    if (!fileUrl || typeof fileUrl !== "string") {
      throw new functions.https.HttpsError("invalid-argument", "L'URL du fichier est manquante.");
    }
    const userId = context.auth.uid;

    try {
      // 1. Télécharger le fichier depuis l'URL
      const response = await fetch(fileUrl);
      if (!response.ok) {
        throw new Error(`Failed to fetch PDF: ${response.statusText}`);
      }
      const fileBuffer = await response.arrayBuffer();

      // 2. Extraire le texte
      const pdfData = await pdfParse(Buffer.from(fileBuffer));
      const pdfText = pdfData.text;

      // 3. Appeler l'IA
      const analysis = await callGeminiForAnalysis(pdfText);
      const summary = await callGeminiForSummary(pdfText);
      
      // 4. Créer la note
      await admin.firestore().collection("notes").add({
        title: analysis.title,
        subject: analysis.subject,
        content: pdfText,
        summary: summary,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        userId: userId,
        pdfUrl: fileUrl, // <-- On sauvegarde l'URL qu'on a reçue
        originalFileName: data.fileName, // <-- On attend aussi le nom du fichier
      });

      console.log(`Note créée pour l'utilisateur ${userId} depuis le PDF.`);
      return { success: true };

    } catch (error) {
      console.error(`Erreur lors du traitement du PDF depuis l'URL ${fileUrl}:`, error);
      throw new functions.https.HttpsError("internal", "Erreur lors du traitement du PDF.");
    }
});
// DANS functions/src/index.ts

export const generateQuiz = functions
  .runWith(runtimeOptions)
  .https.onCall(async (data, context) => {
    // ... (vos vérifications d'authentification et de texte sont bonnes)

    try {
      const prompt = `Ta seule et unique tâche est de générer un quiz à partir d'un texte.
      - Le quiz doit contenir 5 questions à choix multiples (QCM).
      - Chaque question doit avoir 4 options de réponse.
      - Tu dois indiquer la bonne réponse.
      - Ta réponse doit être UNIQUEMENT un objet JSON valide, sans aucun texte avant ou après.
      - Le JSON doit être un tableau d'objets.
      - Chaque objet doit contenir les clés "question", "options" (un tableau de 4 chaînes), et "answer" (la chaîne de la bonne réponse).
      - Ne réponds rien d'autre que le JSON. N'ajoute pas de texte comme "Bien sûr, voici le quiz".

      TEXTE À ANALYSER:
      "${data.text.substring(0, 8000)}"`;
      
      const result = await model.generateContent(prompt);
      const response = await result.response;
      
      const jsonString = response.text().trim().replace(/^```json\s*|```\s*$/g, "");
      
      // --- DÉBUT DE LA CORRECTION ---
      try {
        // On essaie de parser le JSON
        const quiz = JSON.parse(jsonString);
        // Si ça réussit, on le renvoie
        return { quiz: quiz };
      } catch (e) {
        // Si le parsing échoue (parce que Gemini n'a pas renvoyé de JSON)
        console.error("Erreur de parsing JSON pour le quiz. Réponse de l'IA:", jsonString);
        // On renvoie une erreur claire à l'application
        throw new functions.https.HttpsError(
          "internal",
          "L'IA n'a pas pu générer un quiz valide. Le texte est peut-être trop court ou ambigu."
        );
      }
      // --- FIN DE LA CORRECTION ---

    } catch (error) {
      console.error("Erreur de l'API Google AI (generateQuiz):", error);
      throw new functions.https.HttpsError("internal", "Erreur lors de la génération du quiz.");
    }
  });