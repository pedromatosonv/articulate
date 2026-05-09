import {
  AudioWaveform,
  Coffee,
  MessageCircle,
  Plus,
  Search,
  Settings,
  Users
} from "lucide-react";
import type { ChatSession } from "../state/sessionStore";
import { practiceModeTitle } from "../domain/practice";

interface SidebarProps {
  sessions: ChatSession[];
  selectedSessionId: string;
  searchText: string;
  onSearchChange: (value: string) => void;
  onCreateChat: () => void;
  onSelectSession: (id: string) => void;
  onOpenSettings: () => void;
}

export function Sidebar({
  sessions,
  selectedSessionId,
  searchText,
  onSearchChange,
  onCreateChat,
  onSelectSession,
  onOpenSettings
}: SidebarProps) {
  const groups = groupSessions(sessions);

  return (
    <aside className="sidebar" aria-label="Chat history">
      <div className="sidebar-header">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true">
            <AudioWaveform size={18} />
          </span>
          <span>Articulate</span>
        </div>

        <button className="primary-button wide" type="button" onClick={onCreateChat}>
          <Plus size={18} />
          New Chat
        </button>

        <label className="search-field">
          <Search size={17} aria-hidden="true" />
          <input
            value={searchText}
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder="Search chats..."
            type="search"
          />
        </label>
      </div>

      <div className="history-list">
        {groups.map((group) =>
          group.sessions.length > 0 ? (
            <section className="history-group" key={group.title}>
              <h2>{group.title}</h2>
              <div className="history-rows">
                {group.sessions.map((session) => (
                  <button
                    className={
                      session.id === selectedSessionId
                        ? "history-row selected"
                        : "history-row"
                    }
                    key={session.id}
                    type="button"
                    onClick={() => onSelectSession(session.id)}
                  >
                    {iconForMode(session.mode)}
                    <span className="history-text">
                      <span className="history-title">{session.title}</span>
                      <span className="history-meta">
                        {relativeDate(session.updatedAt)} ·{" "}
                        {practiceModeTitle(session.mode)}
                      </span>
                    </span>
                  </button>
                ))}
              </div>
            </section>
          ) : null
        )}
      </div>

      <div className="sidebar-footer">
        <button className="plain-row-button" type="button" onClick={onOpenSettings}>
          <Settings size={19} />
          Settings
        </button>
      </div>
    </aside>
  );
}

function groupSessions(sessions: ChatSession[]) {
  const now = new Date();

  return [
    {
      title: "Today",
      sessions: sessions.filter((session) => dayDistance(session.updatedAt, now) === 0)
    },
    {
      title: "Yesterday",
      sessions: sessions.filter((session) => dayDistance(session.updatedAt, now) === 1)
    },
    {
      title: "Previous 7 Days",
      sessions: sessions.filter((session) => {
        const distance = dayDistance(session.updatedAt, now);
        return distance > 1 && distance < 7;
      })
    },
    {
      title: "Older",
      sessions: sessions.filter((session) => dayDistance(session.updatedAt, now) >= 7)
    }
  ];
}

function dayDistance(isoDate: string, relativeTo: Date): number {
  const date = new Date(isoDate);
  const start = new Date(
    relativeTo.getFullYear(),
    relativeTo.getMonth(),
    relativeTo.getDate()
  ).getTime();
  const sessionStart = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate()
  ).getTime();
  return Math.floor((start - sessionStart) / 86_400_000);
}

function relativeDate(isoDate: string): string {
  const distance = dayDistance(isoDate, new Date());
  if (distance === 0) {
    return "Today";
  }
  if (distance === 1) {
    return "Yesterday";
  }
  if (distance < 7) {
    return `${distance} days ago`;
  }
  return new Intl.DateTimeFormat(undefined, {
    month: "numeric",
    day: "numeric",
    year: "2-digit"
  }).format(new Date(isoDate));
}

function iconForMode(mode: ChatSession["mode"]) {
  const props = { size: 18, "aria-hidden": true };
  switch (mode) {
    case "interview":
      return <Users {...props} />;
    case "pronunciation":
      return <AudioWaveform {...props} />;
    case "smallTalk":
      return <Coffee {...props} />;
    case "conversation":
    default:
      return <MessageCircle {...props} />;
  }
}
