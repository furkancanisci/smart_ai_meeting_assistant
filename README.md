# 🤖 Smart AI Meeting Assistant

An intelligent meeting analysis platform that leverages cutting-edge AI technologies to transform how teams conduct, analyze, and retrieve insights from their meetings.

## Pictures

<img width="233" height="802" alt="Ekran Resmi 2026-02-12 20 19 13" src="https://github.com/user-attachments/assets/3a8929e2-dedd-4961-b2ee-53ba54685c2a" />
<img width="238" height="816" alt="Ekran Resmi 2026-02-12 20 19 40" src="https://github.com/user-attachments/assets/9685bb12-b841-464f-ac44-ed0f87551871" />
<img width="232" height="823" alt="Ekran Resmi 2026-02-12 20 20 18" src="https://github.com/user-attachments/assets/20d0b537-9d28-482e-a79f-76b9fed73109" />


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

### Mobile App (Flutter)
```dart
// Cross-Platform Mobile Stack
- Flutter 3.x             # Modern UI framework
- flutter_local_notifications # Scheduled notifications
- permission_handler      # Android permissions management
- timezone               # Time zone handling
- http                   # API communication
```

## 🔔 Mobile Notification System

### **Smart Task Reminders**
- **Scheduled Notifications**: Automatic task reminders at specified times (default: 17:00)
- **Exact Alarm Support**: Android 12+ compatible precise timing
- **Background Processing**: Notifications work even when app is closed
- **Permission Management**: Smart permission requests with user-friendly dialogs

### **Notification Features**
- **Task-Based Reminders**: Individual notifications for each upcoming task
- **Time-Based Scheduling**: Configurable daily reminder times
- **Multi-Notification Support**: Staggered notifications to prevent conflicts
- **Test Functionality**: Immediate test notifications for debugging

### **Android Integration**
```xml
<!-- Required Permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### **Notification Service API**
```dart
// Core Methods
await NotificationService().init();                    // Initialize service
await NotificationService().scheduleDailyStatusCheck(tasks); // Schedule reminders
await NotificationService().showImmediateNotification(); // Test notification
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

5. **Mobile App Setup**
```bash
cd mobile
flutter pub get
flutter run  # For development
flutter build apk  # For production
```

### Mobile Configuration
- Update API base URL in `lib/services/api_service.dart`
- Configure notification times in `lib/services/notification_service.dart`
- Android permissions automatically handled by the app

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

## � Mobile App Features

- **Smart Notifications**: Scheduled task reminders with exact timing
- **Permission Management**: Automatic handling of Android notification permissions
- **Test Functionality**: Built-in notification testing for debugging
- **Background Processing**: Notifications work when app is closed
- **API Integration**: Seamless connection to backend services
- **Cross-Platform**: Flutter-based for iOS and Android compatibility

## �🚀 Performance

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
