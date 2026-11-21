import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => res.json({ ok: true, service: "PocketAI API" }));

app.post("/api/chat", async (req, res) => {
  try {
    const { message, history = [] } = req.body ?? {};
    if (typeof message !== "string" || !message.trim()) {
      return res.status(400).json({ error: "A non-empty message is required." });
    }
    if (!process.env.OPENAI_API_KEY) {
      return res.status(503).json({ error: "AI service is not configured on the server." });
    }

    const input = [
      { role: "system", content: "You are PocketAI, a helpful, clear, friendly personal assistant. Be honest about uncertainty." },
      ...history.slice(-12).filter(item =>
        item && ["user", "assistant"].includes(item.role) && typeof item.content === "string"
      ),
      { role: "user", content: message }
    ];

    const upstream = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || "gpt-4o-mini",
        input,
        max_output_tokens: 900
      })
    });

    const payload = await upstream.json();
    if (!upstream.ok) {
      return res.status(upstream.status).json({ error: payload.error?.message || "AI provider request failed." });
    }

    const reply = (payload.output || [])
      .flatMap(item => item.content || [])
      .filter(part => part.type === "output_text")
      .map(part => part.text)
      .join("\n")
      .trim();

    if (!reply) return res.status(502).json({ error: "The AI provider returned no text." });
    res.json({ reply });
  } catch (error) {
    console.error("Chat request failed:", error);
    res.status(500).json({ error: "Internal server error." });
  }
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`PocketAI backend listening on ${port}`));
