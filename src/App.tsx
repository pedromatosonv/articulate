import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { SettingsPanel } from "./components/SettingsPanel";
import { Sidebar } from "./components/Sidebar";
import { PracticePane } from "./components/PracticePane";
import {
  type PracticeModeId,
  type ProficiencyId,
  practiceModeTitle,
  proficiencyTitle,
  realtimeModel
} from "./domain/practice";
import {
  type ChatSession,
  clampScale,
  createNewSession,
  createTranscriptItem,
  loadContentScale,
  loadSessions,
  saveContentScale,
  saveSessions,
  sortByUpdatedAt,
  titleFromText,
  zoom
} from "./state/sessionStore";
import {
  type ConnectionStatus,
  RealtimeSession,
  type RealtimeServerEvent
} from "./realtime/realtimeSession";

export default function App() {
  const initialSessions = useMemo(() => loadSessions(), []);
  const [sessions, setSessions] = useState<ChatSession[]>(initialSessions);
  const [selectedSessionId, setSelectedSessionId] = useState(() => {
    return initialSessions[0]?.id ?? createNewSession().id;
  });
  const [searchText, setSearchText] = useState("");
  const [typedPrompt, setTypedPrompt] = useState("");
  const [contentScale, setContentScaleState] = useState(loadContentScale);
  const [connectionStatus, setConnectionStatus] =
    useState<ConnectionStatus>("idle");
  const [isRecording, setIsRecording] = useState(false);
  const [lastError, setLastError] = useState<string | undefined>();
  const [settingsOpen, setSettingsOpen] = useState(false);

  const audioRef = useRef<HTMLAudioElement | null>(null);
  const realtimeRef = useRef<RealtimeSession | null>(null);

  const selectedSession = useMemo(() => {
    return sessions.find((session) => session.id === selectedSessionId) ?? sessions[0];
  }, [selectedSessionId, sessions]);

  const selectedMode = selectedSession?.mode ?? "conversation";
  const selectedProficiency = selectedSession?.proficiency ?? "intermediate";

  useEffect(() => {
    saveSessions(sessions);
  }, [sessions]);

  useEffect(() => {
    saveContentScale(contentScale);
  }, [contentScale]);

  useEffect(() => {
    return () => {
      realtimeRef.current?.disconnect();
    };
  }, []);

  async function connect() {
    if (!audioRef.current || connectionStatus === "connected") {
      return;
    }

    setLastError(undefined);
    setIsRecording(false);

    const session = new RealtimeSession();
    realtimeRef.current = session;

    try {
      await session.connect({
        mode: selectedMode,
        proficiency: selectedProficiency,
        audioElement: audioRef.current,
        onEvent: handleRealtimeEvent,
        onStatusChange: setConnectionStatus
      });
    } catch (error) {
      setConnectionStatus("failed");
      setLastError(error instanceof Error ? error.message : "Connection failed.");
      session.disconnect();
      realtimeRef.current = null;
    }
  }

  async function disconnect() {
    realtimeRef.current?.disconnect();
    realtimeRef.current = null;
    setIsRecording(false);
    setConnectionStatus("idle");
  }

  async function toggleConnection() {
    if (connectionStatus === "connected" || connectionStatus === "connecting") {
      await disconnect();
      return;
    }
    await connect();
  }

  async function startSpeaking() {
    if (connectionStatus !== "connected") {
      await connect();
    }

    try {
      await realtimeRef.current?.startSpeaking();
      setIsRecording(true);
    } catch (error) {
      setLastError(error instanceof Error ? error.message : "Could not start recording.");
    }
  }

  function stopSpeaking() {
    try {
      realtimeRef.current?.stopSpeaking();
      setIsRecording(false);
    } catch (error) {
      setLastError(error instanceof Error ? error.message : "Could not stop recording.");
    }
  }

  async function sendTypedPrompt() {
    const text = typedPrompt.trim();
    if (!text) {
      return;
    }

    setTypedPrompt("");
    appendLearnerMessage(text, true);

    if (connectionStatus !== "connected") {
      await connect();
    }

    try {
      realtimeRef.current?.sendText(text);
    } catch (error) {
      setTypedPrompt(text);
      setLastError(error instanceof Error ? error.message : "Could not send prompt.");
    }
  }

  function handleRealtimeEvent(event: RealtimeServerEvent) {
    switch (event.type) {
      case "session.created":
      case "session.updated":
        setConnectionStatus("connected");
        break;
      case "conversation.item.input_audio_transcription.completed":
      case "conversation.item.input_audio_transcription.done":
        if (typeof event.transcript === "string" && event.transcript.trim()) {
          appendLearnerMessage(event.transcript, true);
        }
        break;
      case "response.output_audio_transcript.delta":
      case "response.audio_transcript.delta":
      case "response.output_text.delta":
      case "response.text.delta":
        if (typeof event.delta === "string" && event.delta) {
          appendCoachDelta(event.delta);
        }
        break;
      case "response.done":
        finishCoachMessage();
        setIsRecording(false);
        break;
      case "input_audio_buffer.speech_started":
        setIsRecording(true);
        break;
      case "input_audio_buffer.speech_stopped":
        setIsRecording(false);
        break;
      case "error":
        setIsRecording(false);
        setLastError(eventMessage(event, "Realtime API returned an error."));
        break;
      case "notice":
        setLastError(eventMessage(event, "Received a Realtime notice."));
        break;
      default:
        break;
    }
  }

  function createChat() {
    const session = createNewSession(selectedMode, selectedProficiency);
    setSessions((current) => [session, ...current]);
    setSelectedSessionId(session.id);
  }

  function deleteCurrentSession() {
    setSessions((current) => {
      const next = current.filter((session) => session.id !== selectedSessionId);
      if (next.length > 0) {
        setSelectedSessionId(next[0].id);
        return next;
      }

      const replacement = createNewSession(selectedMode, selectedProficiency);
      setSelectedSessionId(replacement.id);
      return [replacement];
    });
  }

  function clearTranscript() {
    updateSelectedSession((session) => ({
      ...session,
      messages: [],
      updatedAt: new Date().toISOString()
    }));
  }

  function renameCurrentSession(title: string) {
    const normalized = title.trim().slice(0, 60);
    if (!normalized) {
      return;
    }

    updateSelectedSession((session) => ({
      ...session,
      title: normalized,
      updatedAt: new Date().toISOString()
    }));
  }

  function changeMode(mode: PracticeModeId) {
    updateSelectedSession((session) => ({
      ...session,
      mode,
      updatedAt: new Date().toISOString()
    }));
    if (connectionStatus === "connected") {
      realtimeRef.current?.updateSession(mode, selectedProficiency);
    }
  }

  function changeProficiency(proficiency: ProficiencyId) {
    updateSelectedSession((session) => ({
      ...session,
      proficiency,
      updatedAt: new Date().toISOString()
    }));
    if (connectionStatus === "connected") {
      realtimeRef.current?.updateSession(selectedMode, proficiency);
    }
  }

  function setContentScale(value: number) {
    setContentScaleState(clampScale(value));
  }

  function appendLearnerMessage(text: string, shouldRetitle = false) {
    const item = createTranscriptItem("learner", text);
    updateSelectedSession((session) => {
      const shouldRename = shouldRetitle && session.title === "New Chat";
      return {
        ...session,
        title: shouldRename ? titleFromText(text) : session.title,
        messages: [...session.messages, item],
        updatedAt: new Date().toISOString()
      };
    });
  }

  function appendCoachDelta(delta: string) {
    updateSelectedSession((session) => {
      const messages = [...session.messages];
      let streamingIndex = -1;
      for (let index = messages.length - 1; index >= 0; index -= 1) {
        if (messages[index].role === "coach" && messages[index].isStreaming) {
          streamingIndex = index;
          break;
        }
      }

      if (streamingIndex >= 0) {
        messages[streamingIndex] = {
          ...messages[streamingIndex],
          text: `${messages[streamingIndex].text}${delta}`
        };
      } else {
        messages.push(createTranscriptItem("coach", delta, true));
      }

      return {
        ...session,
        messages,
        updatedAt: new Date().toISOString()
      };
    });
  }

  function finishCoachMessage() {
    updateSelectedSession((session) => ({
      ...session,
      messages: session.messages.map((item) =>
        item.isStreaming ? { ...item, isStreaming: false } : item
      ),
      updatedAt: new Date().toISOString()
    }));
  }

  function updateSelectedSession(updater: (session: ChatSession) => ChatSession) {
    setSessions((current) =>
      current
        .map((session) =>
          session.id === selectedSessionId ? updater(session) : session
        )
        .sort(sortByUpdatedAt)
    );
  }

  const filteredSessions = useMemo(() => {
    const query = searchText.trim().toLowerCase();
    if (!query) {
      return sessions;
    }

    return sessions.filter((session) => {
      return (
        session.title.toLowerCase().includes(query) ||
        practiceModeTitle(session.mode).toLowerCase().includes(query) ||
        proficiencyTitle(session.proficiency).toLowerCase().includes(query) ||
        session.messages.some((message) =>
          message.text.toLowerCase().includes(query)
        )
      );
    });
  }, [searchText, sessions]);

  return (
    <div
      className="app-shell"
      style={{ "--content-scale": contentScale } as CSSProperties}
    >
      <Sidebar
        sessions={filteredSessions}
        selectedSessionId={selectedSessionId}
        searchText={searchText}
        onSearchChange={setSearchText}
        onCreateChat={createChat}
        onSelectSession={setSelectedSessionId}
        onOpenSettings={() => setSettingsOpen(true)}
      />

      {selectedSession && (
        <PracticePane
          connectionStatus={connectionStatus}
          contentScaleLabel={`${Math.round(contentScale * 100)}%`}
          isRecording={isRecording}
          lastError={lastError}
          model={realtimeModel}
          session={selectedSession}
          typedPrompt={typedPrompt}
          onChangeMode={changeMode}
          onChangeProficiency={changeProficiency}
          onClearError={() => setLastError(undefined)}
          onClearTranscript={clearTranscript}
          onDeleteSession={deleteCurrentSession}
          onRenameSession={renameCurrentSession}
          onSendPrompt={() => void sendTypedPrompt()}
          onSetTypedPrompt={setTypedPrompt}
          onStartSpeaking={() => void startSpeaking()}
          onStopSpeaking={stopSpeaking}
          onToggleConnection={() => void toggleConnection()}
        />
      )}

      <SettingsPanel
        contentScale={contentScale}
        isOpen={settingsOpen}
        mode={selectedMode}
        proficiency={selectedProficiency}
        onChangeMode={changeMode}
        onChangeProficiency={changeProficiency}
        onClose={() => setSettingsOpen(false)}
        onResetZoom={() => setContentScale(zoom.defaultScale)}
        onSetContentScale={setContentScale}
      />

      <audio ref={audioRef} className="remote-audio" autoPlay />
    </div>
  );
}

function eventMessage(event: RealtimeServerEvent, fallback: string): string {
  const message = event.message;
  if (typeof message === "string") {
    return message;
  }

  const error = event.error;
  if (
    error &&
    typeof error === "object" &&
    "message" in error &&
    typeof error.message === "string"
  ) {
    return error.message;
  }

  return fallback;
}
