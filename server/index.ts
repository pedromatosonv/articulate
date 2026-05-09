import dotenv from "dotenv";
import express from "express";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  buildRealtimeSessionConfig,
  isPracticeModeId,
  isProficiencyId,
  type PracticeModeId,
  type ProficiencyId
} from "../src/domain/practice";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");

dotenv.config({ path: path.join(rootDir, ".env.local"), override: false, quiet: true });
dotenv.config({ path: path.join(rootDir, ".env"), override: false, quiet: true });

const app = express();
const port = Number(process.env.PORT ?? 8787);

app.use(express.json({ limit: "1mb" }));

app.get("/api/health", (_req, res) => {
  res.json({ ok: true });
});

app.post("/api/realtime/call", async (req, res) => {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: "OPENAI_API_KEY is not configured." });
    return;
  }

  const body = req.body as {
    sdp?: unknown;
    mode?: unknown;
    proficiency?: unknown;
  };

  if (typeof body.sdp !== "string" || body.sdp.trim().length === 0) {
    res.status(400).json({ error: "A WebRTC SDP offer is required." });
    return;
  }

  const mode: PracticeModeId = isPracticeModeId(body.mode)
    ? body.mode
    : "conversation";
  const proficiency: ProficiencyId = isProficiencyId(body.proficiency)
    ? body.proficiency
    : "intermediate";

  const form = new FormData();
  form.set("sdp", body.sdp);
  form.set(
    "session",
    JSON.stringify(buildRealtimeSessionConfig(mode, proficiency))
  );

  try {
    const response = await fetch("https://api.openai.com/v1/realtime/calls", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`
      },
      body: form
    });

    const answer = await response.text();
    if (!response.ok) {
      res
        .status(response.status)
        .type("text/plain")
        .send(answer || "OpenAI Realtime call setup failed.");
      return;
    }

    res.status(201).type("application/sdp").send(answer);
  } catch (error) {
    console.error("Realtime call setup failed:", error);
    res.status(502).json({ error: "Could not create Realtime session." });
  }
});

const distDir = path.join(rootDir, "dist");
if (existsSync(distDir)) {
  app.use(express.static(distDir));
  app.use((req, res, next) => {
    if (req.method === "GET" && req.accepts("html")) {
      res.sendFile(path.join(distDir, "index.html"));
      return;
    }
    next();
  });
}

app.listen(port, () => {
  console.log(`Articulate server listening on http://localhost:${port}`);
});
