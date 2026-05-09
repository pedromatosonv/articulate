import {
  buildRealtimeSessionConfig,
  type PracticeModeId,
  type ProficiencyId
} from "../domain/practice";

export type ConnectionStatus = "idle" | "connecting" | "connected" | "failed";

export interface RealtimeServerEvent {
  type: string;
  [key: string]: unknown;
}

interface ConnectOptions {
  mode: PracticeModeId;
  proficiency: ProficiencyId;
  audioElement: HTMLAudioElement;
  onEvent: (event: RealtimeServerEvent) => void;
  onStatusChange: (status: ConnectionStatus) => void;
}

export class RealtimeSession {
  private peerConnection?: RTCPeerConnection;
  private dataChannel?: RTCDataChannel;
  private localStream?: MediaStream;
  private localTrack?: MediaStreamTrack;
  private localSender?: RTCRtpSender;
  private audioElement?: HTMLAudioElement;

  async connect(options: ConnectOptions): Promise<void> {
    this.disconnect();
    options.onStatusChange("connecting");

    const peerConnection = new RTCPeerConnection();
    const dataChannel = peerConnection.createDataChannel("oai-events");
    const audioTransceiver = peerConnection.addTransceiver("audio", {
      direction: "sendrecv"
    });

    peerConnection.ontrack = (event) => {
      const [remoteStream] = event.streams;
      if (remoteStream) {
        options.audioElement.srcObject = remoteStream;
        void options.audioElement.play().catch(() => undefined);
      }
    };

    dataChannel.addEventListener("message", (event) => {
      try {
        options.onEvent(JSON.parse(event.data) as RealtimeServerEvent);
      } catch {
        options.onEvent({
          type: "notice",
          message: "Received an unreadable Realtime event."
        });
      }
    });

    dataChannel.addEventListener("close", () => {
      options.onStatusChange("idle");
    });

    this.peerConnection = peerConnection;
    this.dataChannel = dataChannel;
    this.localSender = audioTransceiver.sender;
    this.audioElement = options.audioElement;

    const offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    if (!offer.sdp) {
      throw new Error("Could not create a WebRTC offer.");
    }

    const response = await fetch("/api/realtime/call", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        sdp: offer.sdp,
        mode: options.mode,
        proficiency: options.proficiency
      })
    });

    const answerSdp = await response.text();
    if (!response.ok) {
      throw new Error(answerSdp || "Could not start the Realtime session.");
    }

    await peerConnection.setRemoteDescription({
      type: "answer",
      sdp: answerSdp
    });

    await this.waitForDataChannel(dataChannel);
    options.onStatusChange("connected");
  }

  async startSpeaking(): Promise<void> {
    const localTrack = await this.ensureMicrophoneTrack();
    localTrack.enabled = true;
  }

  stopSpeaking(): void {
    if (this.localTrack) {
      this.localTrack.enabled = false;
    }
  }

  sendText(text: string): void {
    this.sendEvent({
      type: "conversation.item.create",
      item: {
        type: "message",
        role: "user",
        content: [
          {
            type: "input_text",
            text
          }
        ]
      }
    });
    this.sendEvent({
      type: "response.create",
      response: {
        output_modalities: ["audio"]
      }
    });
  }

  updateSession(mode: PracticeModeId, proficiency: ProficiencyId): void {
    this.sendEvent({
      type: "session.update",
      session: buildRealtimeSessionConfig(mode, proficiency)
    });
  }

  disconnect(): void {
    this.stopSpeaking();
    this.dataChannel?.close();
    this.peerConnection?.close();
    this.localStream?.getTracks().forEach((track) => track.stop());
    if (this.audioElement) {
      this.audioElement.srcObject = null;
    }
    this.dataChannel = undefined;
    this.peerConnection = undefined;
    this.localStream = undefined;
    this.localTrack = undefined;
    this.localSender = undefined;
    this.audioElement = undefined;
  }

  private async ensureMicrophoneTrack(): Promise<MediaStreamTrack> {
    if (!this.localSender) {
      throw new Error("Connect before speaking.");
    }

    if (this.localTrack && this.localTrack.readyState === "live") {
      return this.localTrack;
    }

    const localStream = await navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true
      }
    });
    const [localTrack] = localStream.getAudioTracks();

    if (!localTrack) {
      throw new Error("No microphone track is available.");
    }

    localTrack.enabled = false;
    await this.localSender.replaceTrack(localTrack);
    this.localStream = localStream;
    this.localTrack = localTrack;
    return localTrack;
  }

  private sendEvent(event: unknown): void {
    if (!this.dataChannel || this.dataChannel.readyState !== "open") {
      throw new Error("Realtime session is not connected.");
    }
    this.dataChannel.send(JSON.stringify(event));
  }

  private waitForDataChannel(dataChannel: RTCDataChannel): Promise<void> {
    if (dataChannel.readyState === "open") {
      return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
      const timeout = window.setTimeout(() => {
        reject(new Error("Realtime data channel did not open."));
      }, 15_000);

      dataChannel.addEventListener(
        "open",
        () => {
          window.clearTimeout(timeout);
          resolve();
        },
        { once: true }
      );
      dataChannel.addEventListener(
        "error",
        () => {
          window.clearTimeout(timeout);
          reject(new Error("Realtime data channel failed to open."));
        },
        { once: true }
      );
    });
  }
}
