import { useState } from "react";
import {
  CheckCircle2,
  Circle,
  Loader2,
  Mic,
  MoreHorizontal,
  Pencil,
  Send,
  StopCircle,
  TriangleAlert,
  X
} from "lucide-react";
import {
  type PracticeModeId,
  type ProficiencyId,
  practiceModes,
  proficiencyLevels,
  practiceModeTitle,
  proficiencyTitle
} from "../domain/practice";
import type { ChatSession } from "../state/sessionStore";
import type { ConnectionStatus } from "../realtime/realtimeSession";
import { Transcript } from "./Transcript";

interface PracticePaneProps {
  connectionStatus: ConnectionStatus;
  contentScaleLabel: string;
  isRecording: boolean;
  lastError?: string;
  model: string;
  session: ChatSession;
  typedPrompt: string;
  onChangeMode: (mode: PracticeModeId) => void;
  onChangeProficiency: (proficiency: ProficiencyId) => void;
  onClearError: () => void;
  onClearTranscript: () => void;
  onDeleteSession: () => void;
  onRenameSession: (title: string) => void;
  onSendPrompt: () => void;
  onSetTypedPrompt: (value: string) => void;
  onStartSpeaking: () => void;
  onStopSpeaking: () => void;
  onToggleConnection: () => void;
}

export function PracticePane({
  connectionStatus,
  contentScaleLabel,
  isRecording,
  lastError,
  model,
  session,
  typedPrompt,
  onChangeMode,
  onChangeProficiency,
  onClearError,
  onClearTranscript,
  onDeleteSession,
  onRenameSession,
  onSendPrompt,
  onSetTypedPrompt,
  onStartSpeaking,
  onStopSpeaking,
  onToggleConnection
}: PracticePaneProps) {
  const [isRenaming, setIsRenaming] = useState(false);
  const [draftTitle, setDraftTitle] = useState(session.title);

  function commitRename() {
    onRenameSession(draftTitle);
    setIsRenaming(false);
  }

  return (
    <main className="practice-pane">
      <header className="practice-header">
        <div className="header-top">
          <div className="title-line">
            {isRenaming ? (
              <input
                className="title-input"
                value={draftTitle}
                onChange={(event) => setDraftTitle(event.target.value)}
                onBlur={commitRename}
                onKeyDown={(event) => {
                  if (event.key === "Enter") {
                    commitRename();
                  }
                  if (event.key === "Escape") {
                    setIsRenaming(false);
                    setDraftTitle(session.title);
                  }
                }}
                autoFocus
                aria-label="Chat title"
              />
            ) : (
              <h1>{session.title}</h1>
            )}
            <button
              className="icon-button"
              type="button"
              onClick={() => {
                setDraftTitle(session.title);
                setIsRenaming(true);
              }}
              aria-label="Rename chat"
              title="Rename chat"
            >
              <Pencil size={17} />
            </button>
          </div>

          <div className="header-actions">
            <button
              className={`status-button ${connectionStatus}`}
              type="button"
              onClick={onToggleConnection}
            >
              {statusIcon(connectionStatus)}
              {statusTitle(connectionStatus)}
            </button>
            <span className="model-chip">{model}</span>
            <details className="menu-button">
              <summary aria-label="Chat actions">
                <MoreHorizontal size={18} />
              </summary>
              <div className="menu-popover">
                <button type="button" onClick={onClearTranscript}>
                  Clear Chat
                </button>
                <button className="danger" type="button" onClick={onDeleteSession}>
                  Delete Chat
                </button>
              </div>
            </details>
          </div>
        </div>

        <div className="session-controls">
          <label className="select-control">
            <span>Mode</span>
            <select
              value={session.mode}
              onChange={(event) =>
                onChangeMode(event.target.value as PracticeModeId)
              }
            >
              {practiceModes.map((mode) => (
                <option key={mode.id} value={mode.id}>
                  {mode.title}
                </option>
              ))}
            </select>
          </label>
          <label className="select-control">
            <span>Level</span>
            <select
              value={session.proficiency}
              onChange={(event) =>
                onChangeProficiency(event.target.value as ProficiencyId)
              }
            >
              {proficiencyLevels.map((level) => (
                <option key={level.id} value={level.id}>
                  {level.title}
                </option>
              ))}
            </select>
          </label>
          <div className="session-summary">
            {practiceModeTitle(session.mode)} / {proficiencyTitle(session.proficiency)} ·{" "}
            {contentScaleLabel}
          </div>
        </div>
      </header>

      {lastError ? (
        <div className="error-banner" role="alert">
          <TriangleAlert size={17} />
          <span>{lastError}</span>
          <button type="button" onClick={onClearError} aria-label="Dismiss">
            <X size={16} />
          </button>
        </div>
      ) : null}

      <Transcript messages={session.messages} isRecording={isRecording} />

      <footer className="composer">
        <button
          className={isRecording ? "record-button recording" : "record-button"}
          type="button"
          onClick={isRecording ? onStopSpeaking : onStartSpeaking}
        >
          {isRecording ? <StopCircle size={24} /> : <Mic size={24} />}
          {isRecording ? "Stop" : "Speak"}
        </button>
        <div className="prompt-box">
          <textarea
            value={typedPrompt}
            onChange={(event) => onSetTypedPrompt(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
                event.preventDefault();
                onSendPrompt();
              }
            }}
            placeholder="Type your message..."
            rows={1}
          />
          <span>Command + Enter to send</span>
        </div>
        <button
          className="send-button"
          type="button"
          onClick={onSendPrompt}
          disabled={!typedPrompt.trim()}
        >
          <Send size={21} />
          Send
        </button>
      </footer>
    </main>
  );
}

function statusTitle(status: ConnectionStatus) {
  switch (status) {
    case "connecting":
      return "Connecting";
    case "connected":
      return "Connected";
    case "failed":
      return "Retry";
    case "idle":
    default:
      return "Connect";
  }
}

function statusIcon(status: ConnectionStatus) {
  switch (status) {
    case "connecting":
      return <Loader2 className="spin" size={16} />;
    case "connected":
      return <CheckCircle2 size={16} />;
    case "failed":
      return <TriangleAlert size={16} />;
    case "idle":
    default:
      return <Circle size={16} />;
  }
}
