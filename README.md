# 🤖 Smart AI Meeting Assistant

An intelligent meeting analysis platform that leverages cutting-edge AI technologies to transform how teams conduct, analyze, and retrieve insights from their meetings.

## ✨ Key AI Features

### 🎯 **Advanced Speech Processing**
- **Whisper Integration**: State-of-the-art speech-to-text transcription with multi-language support
- **Speaker Diarization**: Automatic identification and separation of different speakers
- **Audio Enhancement**: Noise reduction and voice clarity optimization using pyannote.audio

### 🧠 **Intelligent Analysis Engine**
- **Action Item Extraction**: AI-powered identification of tasks, assignments, and deadlines from natural conversation
- **Sentiment Analysis**: Real-time mood detection and meeting atmosphere analysis (tense, productive, neutral, etc.)
- **Executive Summary Generation**: Automatic creation of 4-part structured summaries including discussions, decisions, action plans, and critical deadlines

### 🔍 **RAG-Powered Memory System**
- **Vector Database Integration**: ChromaDB with pgvector for efficient semantic search
- **Contextual Memory**: Long-term storage of all meeting transcripts with embedding-based retrieval
- **Smart Q&A**: Ask questions about any historical meeting and get precise, context-aware answers

### 🚀 **Large Language Model Integration**
- **Groq Llama 3.3 70B**: Ultra-fast inference for real-time analysis
- **Multi-task Processing**: Simultaneous transcript correction, task extraction, and sentiment analysis
- **Intelligent Chat Interface**: Natural language queries across entire meeting history

## 🏗️ Architecture

### Backend (FastAPI + Python)
```python
# AI Services Stack
- FastAPI 0.109.0          # High-performance async web framework
- SQLAlchemy 2.0.25        # Modern ORM with async support
- pgvector                 # Vector similarity search
- OpenAI Whisper          # Speech-to-text
- pyannote.audio          # Speaker diarization
- Groq + Llama 3.3 70B    # LLM inference
- ChromaDB                # Vector database
- Sentence Transformers    # Text embeddings
```

### Frontend (React + Vite)
```javascript
// Modern Web Stack
- React 19.2.0            # Latest React with concurrent features
- Vite 7.2.4              # Lightning-fast build tool
- TailwindCSS 3.4.17      # Utility-first CSS framework
- Heroicons               # Professional icon library
- Axios                   # HTTP client with async/await
```

### Database Layer
- **PostgreSQL 16** with pgvector extension for hybrid relational-vector queries
- **ChromaDB** for persistent vector storage and semantic search
- **Docker Compose** for reproducible development environment

## 🎬 AI Workflow

### 1. **Audio Ingestion**
```
Meeting Audio → Whisper → Raw Transcript → Speaker Diarization → Structured Segments
```

### 2. **AI Processing Pipeline**
```
Transcript → LLM Analysis → {
  • Action Items (with date parsing)
  • Sentiment Score (1-10 scale)
  • Executive Summary
  • Corrected Transcript
}
```

### 3. **Memory & Retrieval**
```
Meeting Segments → Embeddings → Vector Database → Semantic Search → Contextual Answers
```

## 🚀 Getting Started

### Prerequisites
- Python 3.9+
- Node.js 18+
- Docker & Docker Compose
- Groq API Key

### Quick Setup

1. **Clone & Environment Setup**
```bash
git clone <repository-url>
cd meeting_ai_project
cp backend/.env.example backend/.env
# Add your GROQ_API_KEY to .env
```

2. **Database & Services**
```bash
docker-compose up -d  # Starts PostgreSQL with pgvector
```

3. **Backend Setup**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

4. **Frontend Setup**
```bash
cd web_panel
npm install
npm run dev
```

## 🎯 AI Capabilities in Action

### **Smart Task Extraction**
The AI identifies actionable items with:
- **Assignee Detection**: "Ali will handle this" → Assigned to Ali
- **Date Parsing**: "by next Friday" → 2024-02-14 17:00
- **Confidence Scoring**: Reliability metrics for each extracted task

### **Intelligent Search**
Ask natural questions and get precise answers:
- "What did we decide about the budget?"
- "Who was assigned the mobile app fixes?"
- "Show me all meetings where we discussed server costs"

### **Sentiment Intelligence**
Real-time mood analysis with:
- **Emotional Detection**: Tense, productive, neutral, formal
- **Productivity Scoring**: 1-10 scale for meeting effectiveness
- **Trend Analysis**: Track meeting atmosphere over time

## 📊 API Endpoints

### AI Analysis
```http
POST /api/v1/meetings/{id}/analyze
POST /api/v1/meetings/{id}/transcribe
GET /api/v1/meetings/search?q={query}
```

### LLM Interactions
```http
POST /api/v1/ai/chat
POST /api/v1/ai/summarize
POST /api/v1/ai/extract-tasks
```

## 🔧 Configuration

### AI Model Settings
```python
# backend/app/services/llm_service.py
MODEL_NAME = "llama-3.3-70b-versatile"  # Groq's fastest model
EMBEDDING_MODEL = "all-MiniLM-L6-v2"     # Lightweight, fast embeddings
```

### Database Vector Extension
```sql
-- Automatically enabled via lifespan
CREATE EXTENSION IF NOT EXISTS vector;
```

## 🎨 Frontend Features

- **Real-time Transcripts**: Live streaming of AI-processed meeting content
- **Interactive Dashboard**: Meeting analytics and sentiment trends
- **Smart Search**: Natural language search across all meetings
- **Task Management**: AI-extracted action items with deadlines
- **Team Collaboration**: Multi-user support with role-based access

## 🚀 Performance

- **Transcription**: Real-time with Whisper (1-2x faster than real-time)
- **LLM Inference**: Sub-second responses with Groq
- **Vector Search**: Millisecond semantic queries
- **Memory Storage**: Efficient compression for thousands of meeting hours

## 🔮 Future AI Enhancements

- **Multi-language Support**: Expanded transcription capabilities
- **Real-time Translation**: Live meeting translation
- **Predictive Analytics**: Meeting outcome predictions
- **Voice Cloning**: Personalized AI assistants
- **Integration Hub**: Connect with Slack, Teams, Calendar apps

## 📝 License

This project represents the cutting edge of AI-powered meeting intelligence. Built with passion for making meetings more productive and insightful.

---

**🤖 Built with Advanced AI: Whisper + Llama 3.3 + ChromaDB + FastAPI**
