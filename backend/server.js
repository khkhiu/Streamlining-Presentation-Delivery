require("dotenv").config();
const express = require("express");
const multer = require("multer");
const axios = require("axios");
const { BlobServiceClient } = require("@azure/storage-blob");

const app = express();
const port = 5000;

app.use(express.json());
const upload = multer({ storage: multer.memoryStorage() });

const AZURE_STORAGE_CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;
const blobServiceClient = BlobServiceClient.fromConnectionString(AZURE_STORAGE_CONNECTION_STRING);
const containerClient = blobServiceClient.getContainerClient("trainer-videos");

// Upload script and generate video
app.post("/upload", async (req, res) => {
  const { text } = req.body;

  // 1. Convert Text-to-Speech using Azure AI Speech
  const speechRes = await axios.post("https://api.text-to-speech.com/generate", {
    text,
    voice: "en-US-JennyNeural",
  });

  const audioUrl = speechRes.data.audioUrl;

  // 2. Generate video (simulate with placeholder URL)
  const videoUrl = `https://placeholder.com/video/${new Date().getTime()}`;

  // 3. Store in Azure Blob Storage
  const blobName = `trainer_${Date.now()}.mp4`;
  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  await blockBlobClient.uploadData(audioUrl, { blobHTTPHeaders: { blobContentType: "video/mp4" } });

  res.json({ success: true, videoUrl });
});

// Get stored videos
app.get("/videos", async (req, res) => {
  let videoList = [];
  for await (const blob of containerClient.listBlobsFlat()) {
    videoList.push({ id: blob.name, url: `https://youraccount.blob.core.windows.net/trainer-videos/${blob.name}` });
  }
  res.json(videoList);
});

// Handle Q&A with Azure OpenAI
app.post("/ask", async (req, res) => {
  const { question } = req.body;

  const aiResponse = await axios.post("https://api.openai.com/v1/chat/completions", {
    model: "gpt-4",
    messages: [{ role: "system", content: "You are a virtual trainer." }, { role: "user", content: question }],
  }, { headers: { Authorization: `Bearer ${process.env.OPENAI_API_KEY}` } });

  res.json({ answer: aiResponse.data.choices[0].message.content });
});

app.listen(port, () => console.log(`Server running on port ${port}`));
