export const realtimeModel = "gpt-realtime-2";
export const realtimeVoice = "marin";

export type PracticeModeId =
  | "conversation"
  | "interview"
  | "pronunciation"
  | "smallTalk";

export type ProficiencyId = "beginner" | "intermediate" | "advanced";

export interface PracticeMode {
  id: PracticeModeId;
  title: string;
  icon: string;
  coachingDirective: string;
}

export interface ProficiencyLevel {
  id: ProficiencyId;
  title: string;
  directive: string;
}

export const practiceModes: PracticeMode[] = [
  {
    id: "conversation",
    title: "Conversation",
    icon: "message-circle",
    coachingDirective:
      "Run an open-ended English conversation. Ask one natural follow-up question after each answer."
  },
  {
    id: "interview",
    title: "Interview",
    icon: "users",
    coachingDirective:
      "Run a realistic job interview. Ask one interview question at a time, then give concise feedback on structure and clarity."
  },
  {
    id: "pronunciation",
    title: "Pronunciation",
    icon: "waveform",
    coachingDirective:
      "Focus on pronunciation, rhythm, and stress. Ask the learner to repeat short phrases and explain corrections simply."
  },
  {
    id: "smallTalk",
    title: "Small Talk",
    icon: "coffee",
    coachingDirective:
      "Practice casual small talk for work and social situations. Keep it relaxed and idiomatic."
  }
];

export const proficiencyLevels: ProficiencyLevel[] = [
  {
    id: "beginner",
    title: "Beginner",
    directive: "Use short sentences, slower speech, and frequent examples."
  },
  {
    id: "intermediate",
    title: "Intermediate",
    directive:
      "Use natural everyday English and correct recurring grammar or word-choice issues."
  },
  {
    id: "advanced",
    title: "Advanced",
    directive:
      "Use native-level phrasing and challenge the learner to be more precise and concise."
  }
];

export function isPracticeModeId(value: unknown): value is PracticeModeId {
  return practiceModes.some((mode) => mode.id === value);
}

export function isProficiencyId(value: unknown): value is ProficiencyId {
  return proficiencyLevels.some((level) => level.id === value);
}

export function practiceModeTitle(modeId: PracticeModeId): string {
  return practiceModes.find((mode) => mode.id === modeId)?.title ?? modeId;
}

export function proficiencyTitle(proficiencyId: ProficiencyId): string {
  return (
    proficiencyLevels.find((level) => level.id === proficiencyId)?.title ??
    proficiencyId
  );
}

export function buildInstructions(
  modeId: PracticeModeId,
  proficiencyId: ProficiencyId
): string {
  const mode = practiceModes.find((item) => item.id === modeId)!;
  const proficiency = proficiencyLevels.find(
    (item) => item.id === proficiencyId
  )!;

  return `You are an English practice coach in a focused web app.
Speak only in English unless the learner explicitly asks for Portuguese.
Keep spoken answers concise: one correction, one short explanation, and one follow-up question.
Do not overpraise. Be direct, warm, and practical.
${mode.coachingDirective}
Learner level: ${proficiency.title}. ${proficiency.directive}
If the learner makes a grammar, pronunciation, or vocabulary mistake, format the answer as short separated lines:
Try this: <a better version>
Why: <one short reason>
Question: <one natural follow-up question>
If no correction is needed, answer briefly and ask one follow-up question.`;
}

export function buildRealtimeSessionConfig(
  modeId: PracticeModeId,
  proficiencyId: ProficiencyId
) {
  return {
    type: "realtime",
    model: realtimeModel,
    instructions: buildInstructions(modeId, proficiencyId),
    max_output_tokens: 1200,
    output_modalities: ["audio"],
    audio: {
      input: {
        format: {
          type: "audio/pcm",
          rate: 24000
        },
        turn_detection: {
          type: "semantic_vad"
        },
        noise_reduction: {
          type: "near_field"
        },
        transcription: {
          model: "gpt-4o-mini-transcribe"
        }
      },
      output: {
        format: {
          type: "audio/pcm"
        },
        voice: realtimeVoice
      }
    }
  };
}
