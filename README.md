# 🧠 Agentic Chat App

A real-time chat application built using **Flutter** and **Django Channels**, enhanced with an **Agentic AI Assistant** powered by **Ollama + RAG (Retrieval-Augmented Generation)**. This app supports **file sharing**, **AI-based summaries**, and **reply suggestions**, with a sleek UI.

---

## 🚀 Features

- 💬 Real-time messaging via WebSocket
- 🤖 Local AI Assistant (Ollama) integration
- 📁 File upload and preview in chat
- 📄 AI-powered file summarization (PDFs)
- 💡 AI reply suggestions and chat summarization
- 📂 RAG system with FAISS & sentence-transformers
- 🎯 Floating AI assistant UI in Flutter
- 🎨 Clean UI with avatars, timestamps, and suggestions

---

## 🧩 Tech Stack

| Layer      | Technologies Used                                           |
| ---------- | ----------------------------------------------------------- |
| Frontend   | Flutter, Dart, Dio, FilePicker, WebSocket                   |
| Backend    | Django, Django Channels, FastAPI                            |
| AI Layer   | Ollama (local LLM), Langchain, FAISS, sentence-transformers |
| Realtime   | WebSocket, Redis (via Docker)                               |
| Storage    | Uploaded file caching & static file server                  |
| Deployment | Locally tested (to be deployed)                             |

---

## 📸 Demo Preview

### 🔹 1. Real-Time Chat + AI Suggestions (Part 1)

![Real-Time Chat + AI](Chat_Application.gif)

### 🔹 2. Real-Time Chat + AI Suggestions (Part 2)

![File Sharing](</Chat_Application%20(1).gif>)

### 🔹 3. Real-Time Chat + AI Suggestions (Part 3)

![File Summarization](</Chat_Application%20(2).gif>)

---

## 🧠 How the AI Works

### 📍 Local Ollama LLM

Runs a lightweight Mistral model locally for chat, summaries, and suggestions.

### 🧠 RAG Pipeline

- PDFs are embedded using sentence-transformers
- FAISS vector search retrieves relevant chunks
- Langchain orchestrates responses using LLM + context

---

## 📁 Project Structure

```plaintext
Chat_Application/
├── chat_flutter/         # Flutter frontend
│   └── lib/main.dart     # Main UI logic
├── chatproject/          # Django backend for chat
│   └── consumers.py      # WebSocket consumer
├── agent_backend/        # FastAPI backend for AI + RAG
│   └── main.py           # Handles summarization, AI chat
├── uploaded_files/       # Cached user uploads
└── README.md
```
