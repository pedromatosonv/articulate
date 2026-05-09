import { describe, expect, it } from "vitest";
import {
  buildInstructions,
  buildRealtimeSessionConfig
} from "../domain/practice";
import { titleFromText, clampScale } from "../state/sessionStore";

describe("practice session configuration", () => {
  it("builds mode and proficiency specific Realtime instructions", () => {
    const instructions = buildInstructions("interview", "advanced");

    expect(instructions).toContain("realistic job interview");
    expect(instructions).toContain("Learner level: Advanced");
    expect(instructions).toContain("Try this:");
    expect(instructions).toContain("focused web app");
  });

  it("keeps the realtime session on gpt-realtime-2 with semantic VAD", () => {
    const config = buildRealtimeSessionConfig("conversation", "intermediate");

    expect(config.model).toBe("gpt-realtime-2");
    expect(config.audio.input.turn_detection.type).toBe("semantic_vad");
    expect(config.audio.output.voice).toBe("marin");
  });
});

describe("session helpers", () => {
  it("derives concise titles from learner text", () => {
    expect(
      titleFromText("  Can we practice my Amazon interview answer, please? ")
    ).toBe("Can we practice my Amazon interview");
  });

  it("clamps content zoom to supported bounds", () => {
    expect(clampScale(0.2)).toBe(0.85);
    expect(clampScale(2)).toBe(1.3);
    expect(clampScale(1.02)).toBe(1);
  });
});
