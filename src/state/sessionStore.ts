import type { PracticeModeId, ProficiencyId } from "../domain/practice";

export type TranscriptRole = "learner" | "coach" | "system";

export interface TranscriptItem {
  id: string;
  role: TranscriptRole;
  text: string;
  isStreaming: boolean;
  createdAt: string;
}

export interface ChatSession {
  id: string;
  title: string;
  mode: PracticeModeId;
  proficiency: ProficiencyId;
  messages: TranscriptItem[];
  createdAt: string;
  updatedAt: string;
}

const sessionsKey = "articulate.sessions.v2";
const contentScaleKey = "articulate.contentScale.v1";

export const zoom = {
  minimum: 0.85,
  maximum: 1.3,
  step: 0.05,
  defaultScale: 1
};

export function createId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function createTranscriptItem(
  role: TranscriptRole,
  text: string,
  isStreaming = false
): TranscriptItem {
  return {
    id: createId(),
    role,
    text,
    isStreaming,
    createdAt: new Date().toISOString()
  };
}

export function titleFromText(text: string): string {
  const words = text
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 6)
    .join(" ")
    .replace(/[.,!?;:]+$/u, "");

  return words.length > 0 ? words.slice(0, 60) : "New Chat";
}

export function createNewSession(
  mode: PracticeModeId = "conversation",
  proficiency: ProficiencyId = "intermediate"
): ChatSession {
  const now = new Date().toISOString();
  return {
    id: createId(),
    title: "New Chat",
    mode,
    proficiency,
    messages: [],
    createdAt: now,
    updatedAt: now
  };
}

export function loadSessions(): ChatSession[] {
  if (typeof localStorage === "undefined") {
    return createSeedSessions();
  }

  try {
    const stored = localStorage.getItem(sessionsKey);
    if (!stored) {
      return createSeedSessions();
    }

    const parsed = JSON.parse(stored) as ChatSession[];
    if (!Array.isArray(parsed) || parsed.length === 0) {
      return createSeedSessions();
    }

    return parsed.sort(sortByUpdatedAt);
  } catch {
    return createSeedSessions();
  }
}

export function saveSessions(sessions: ChatSession[]): void {
  if (typeof localStorage === "undefined") {
    return;
  }
  localStorage.setItem(sessionsKey, JSON.stringify(sessions));
}

export function loadContentScale(): number {
  if (typeof localStorage === "undefined") {
    return zoom.defaultScale;
  }

  const stored = localStorage.getItem(contentScaleKey);
  if (stored === null) {
    return zoom.defaultScale;
  }

  const raw = Number(stored);
  return Number.isFinite(raw) ? clampScale(raw) : zoom.defaultScale;
}

export function saveContentScale(value: number): void {
  if (typeof localStorage === "undefined") {
    return;
  }
  localStorage.setItem(contentScaleKey, String(clampScale(value)));
}

export function clampScale(value: number): number {
  const rounded = Math.round(value / zoom.step) * zoom.step;
  return Math.min(zoom.maximum, Math.max(zoom.minimum, Number(rounded.toFixed(2))));
}

export function sortByUpdatedAt(a: ChatSession, b: ChatSession): number {
  return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
}

function createSeedSessions(): ChatSession[] {
  const now = new Date();
  const iso = (offsetMinutes: number) =>
    new Date(now.getTime() - offsetMinutes * 60_000).toISOString();
  const daysAgo = (days: number) =>
    new Date(now.getTime() - days * 24 * 60 * 60_000).toISOString();

  const sessions: ChatSession[] = [
    {
      id: createId(),
      title: "Job Interview Practice",
      mode: "interview",
      proficiency: "intermediate",
      createdAt: iso(42),
      updatedAt: iso(3),
      messages: [
        {
          id: createId(),
          role: "coach",
          text:
            "Great! Let's do a job interview practice. I'll be the interviewer.\n\nQuestion: Can you tell me a little about yourself?",
          isStreaming: false,
          createdAt: iso(39)
        },
        {
          id: createId(),
          role: "learner",
          text:
            "Sure. I'm a software engineer with around 4 years of experience building web applications. I enjoy solving problems and working in a team.",
          isStreaming: false,
          createdAt: iso(35)
        },
        {
          id: createId(),
          role: "coach",
          text:
            "Try this: I have around four years of experience building web applications.\nWhy: It sounds more natural and precise.\nQuestion: What kind of engineering work do you enjoy most?",
          isStreaming: false,
          createdAt: iso(32)
        }
      ]
    },
    {
      id: createId(),
      title: "Small Talk at Work",
      mode: "smallTalk",
      proficiency: "intermediate",
      createdAt: iso(78),
      updatedAt: iso(78),
      messages: []
    },
    {
      id: createId(),
      title: "Travel English",
      mode: "conversation",
      proficiency: "beginner",
      createdAt: daysAgo(1),
      updatedAt: daysAgo(1),
      messages: []
    },
    {
      id: createId(),
      title: "Giving Opinions",
      mode: "conversation",
      proficiency: "advanced",
      createdAt: daysAgo(3),
      updatedAt: daysAgo(3),
      messages: []
    }
  ];

  return sessions.sort(sortByUpdatedAt);
}
