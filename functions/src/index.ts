// functions/src/index.ts

import * as functions from "firebase-functions";
import OpenAI from "openai";
import {onCall, HttpsError} from "firebase-functions/v2/https";

// On ne fait PAS l'initialisation ici.

export const summarizeText = onCall(async (request) => {
  // On fait l'initialisation À L'INTÉRIEUR de la fonction
  const openai = new OpenAI({
    apiKey: functions.config().openai.key,
  });

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "...");
  }

  const text = request.data.text;
  if (!text || typeof text !== "string") {
    throw new HttpsError("invalid-argument", "...");
  }

  try {
    const response = await openai.chat.completions.create({
      // ... (le reste de la fonction est identique)
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "Tu es un assistant expert...",
        },
        {
          role: "user",
          content: text,
        },
      ],
    });

    const summary = response.choices[0]?.message?.content;
    return {summary: summary};
  } catch (error) {
    console.error("Erreur de l'API OpenAI:", error);
    throw new HttpsError("internal", "...");
  }
});