import { Bot, Loader2, Mic2, UserRound } from "lucide-react";
import type { TranscriptItem } from "../state/sessionStore";

interface TranscriptProps {
  messages: TranscriptItem[];
  isRecording: boolean;
}

export function Transcript({ messages, isRecording }: TranscriptProps) {
  const visibleMessages = messages.filter((message) => message.role !== "system");

  return (
    <section className="transcript-panel" aria-label="Transcript">
      {visibleMessages.length === 0 ? (
        <div className="empty-transcript">
          <div className="empty-icon">
            <Bot size={36} />
          </div>
          <h2>Ready</h2>
          <p>Connect, speak, or type a prompt.</p>
        </div>
      ) : (
        <div className="transcript-list">
          {visibleMessages.map((item) => (
            <TranscriptRow item={item} key={item.id} />
          ))}
        </div>
      )}

      <div className={isRecording ? "listening-indicator active" : "listening-indicator"}>
        <span>{isRecording ? "Coach is listening. Speak naturally." : "Ready for practice."}</span>
        {isRecording ? <Mic2 size={17} /> : null}
      </div>
    </section>
  );
}

function TranscriptRow({ item }: { item: TranscriptItem }) {
  const isCoach = item.role === "coach";

  return (
    <article className={isCoach ? "transcript-row coach" : "transcript-row learner"}>
      {isCoach ? <Avatar kind="coach" /> : null}
      <div className="bubble">
        <div className="bubble-header">
          <span>{isCoach ? "Coach" : "You"}</span>
          <time>{timeLabel(item.createdAt)}</time>
          {item.isStreaming ? <Loader2 className="spin" size={13} /> : null}
        </div>
        {isCoach ? (
          <CoachText text={item.text} />
        ) : (
          <p className="plain-message">{item.text}</p>
        )}
      </div>
      {!isCoach ? <Avatar kind="learner" /> : null}
    </article>
  );
}

function Avatar({ kind }: { kind: "coach" | "learner" }) {
  return (
    <span className={`avatar ${kind}`} aria-hidden="true">
      {kind === "coach" ? <Bot size={16} /> : <UserRound size={15} />}
    </span>
  );
}

function CoachText({ text }: { text: string }) {
  const segments = segmentCoachMessage(text);

  return (
    <div className="coach-text">
      {segments.map((segment, index) =>
        segment.label ? (
          <div className={`coach-section ${labelClass(segment.label)}`} key={index}>
            <strong>{segment.label}</strong>
            <p>{segment.text}</p>
          </div>
        ) : (
          <p className="plain-message" key={index}>
            {segment.text}
          </p>
        )
      )}
    </div>
  );
}

function segmentCoachMessage(text: string) {
  const lines = text
    .split(/\n+/)
    .map((line) => line.trim())
    .filter(Boolean);

  if (lines.length === 0) {
    return [{ text, label: undefined as string | undefined }];
  }

  return lines.map((line) => {
    const match = /^(Try this|Why|Question):\s*(.*)$/u.exec(line);
    if (!match) {
      return { text: line, label: undefined };
    }
    return { label: match[1], text: match[2] };
  });
}

function labelClass(label: string) {
  return label.toLowerCase().replace(/\s+/gu, "-");
}

function timeLabel(isoDate: string) {
  return new Intl.DateTimeFormat(undefined, {
    hour: "numeric",
    minute: "2-digit"
  }).format(new Date(isoDate));
}
