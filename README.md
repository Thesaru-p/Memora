# Memora - Ebbinghaus Spaced Repetition Multi-Agent System
> Powered by **Jac Platform** (`jaclang`) and hosted on **JacHammer** (`jachammer.ai`).  
> Designed for **AI Hackathon 2026 Sri Lanka**.

Memora is a mobile application and multi-agent system designed to conquer Hermann Ebbinghaus's forgetting curve (where ~50% of lecture materials are forgotten within 24 hours). Students upload lecture notes or photos of slides, an Object-Spatial Knowledge Graph is constructed in Jac, and a 24-hour proactive notification prompts a 3–4 minute micro-quiz to refresh the memory curve.

---

## 📁 Conflict-Free Architecture & Developer Ownership

The repository is modularized so that 3 developers can work concurrently without merge conflicts:

```
Memora/
├── backend/                      # 100% Jac Backend
│   ├── graph.jac                 # [Dev 2] Knowledge Graph Nodes (Subject, Lecture, Concept, Quiz, Question)
│   ├── ebbinghaus.jac            # [Dev 3] Retention Decay Math R(t) = exp(-t/S) & Stability Recalibration
│   └── agents/                   # Multi-Agent Walkers
│       ├── lecture_analyzer.jac  # [Dev 2] Multimodal Slide & Note Vision Concept Extractor
│       ├── graph_builder.jac     # [Dev 2] Native Graph Stitcher (root ++> ...)
│       ├── quiz_planner.jac      # [Dev 3] Spatial Concept Priority Selector
│       ├── quiz_generator.jac    # [Dev 3] Grounded MCQ & Active Recall Question Creator
│       ├── evaluator.jac         # [Dev 3] Semantic Grading, Misconception Debrief & Stability Updates
│       ├── scheduler.jac         # [Dev 3] Day-1 (24h) Alert & Review Window Notification Agent
│       └── analytics.jac         # [Dev 3] Ebbinghaus Curve Tracker & Performance Analytics Agent
├── mobile/                       # [Dev 1] React Native (Expo) Mobile App
│   ├── src/
│   │   ├── api/client.ts         # Standardized API Service connecting to Jac Walkers
│   │   ├── types/index.ts        # TypeScript data contracts matching Jac Schemas
│   │   └── screens/
│   │       ├── DashboardScreen.tsx      # Retention Health Dial, Quick Actions & Alerts
│   │       ├── LectureUploadScreen.tsx  # Note & Slide Photo Ingestion
│   │       ├── QuizScreen.tsx           # 3-4 Min Micro-Quiz Player with Timer
│   │       ├── QuizResultsScreen.tsx    # Missed Answers Debrief & Pedagogical Explanations
│   │       ├── AnalyticsScreen.tsx      # Ebbinghaus Decay Curve Line Chart & Quiz History
│   │       └── KnowledgeGraphScreen.tsx # Interactive Visual Concept Map ("Skill Tree")
│   ├── App.tsx                   # Main Navigation Router
│   ├── package.json
│   └── app.json
├── tests/                        # Automated Jac Test Suite
│   ├── test_forgetting_curve.jac # [Dev 3] Tests for Retention Math & Stability Updates
│   └── test_graph.jac            # [Dev 2] Tests for Graph Nodes & Prerequisite Edges
├── main.jac                      # Root Jac Coordinator & Public REST Walker Endpoints
├── jac.toml                      # Jac Project Config
├── PLAN.md                       # Complete Architectural Specification
├── WORK_MATRIX.md                # 3-Developer Task Breakdown & Milestones
├── rules.md                      # Competition Rules
└── .env.example                  # OpenRouter API Key Template
```

---

## 🚀 Quickstart

### 1. Jac Backend Setup & Execution
Ensure `jaclang` is installed (`pip install jaclang`):

```bash
# Install Jac's LLM delegation runtime once
jac install byllm

# Verify Jac version
jac --version

# Run the Jac multi-agent backend entrypoint (loads .env first on Windows)
.\tools\run_jac.ps1 run main.jac

# Run backend REST API server (exposing public walkers)
.\tools\run_jac.ps1 start main.jac
```

### 2. Running Automated Jac Tests
```bash
# Run all unit tests
.\tools\run_jac.ps1 test tests/test_forgetting_curve.jac
.\tools\run_jac.ps1 test tests/test_graph.jac
```

### 3. Mobile App Setup (Dev 1)
```bash
cd mobile
npm install
npx expo start
```
Scan the QR code in **Expo Go** on Android/iOS or press `w` to view inside a browser phone preview.

---

## 🌐 Public Walker API Endpoints

The Jac backend exposes the following public walkers for the mobile client:

| Walker Endpoint | Method | Purpose |
| :--- | :--- | :--- |
| `POST /walker/ingest_lecture` | POST | Extracts concepts from notes/slides and anchors them to the Jac graph |
| `POST /walker/get_dashboard` | POST | Retrieves subject overview, retention health %, and streak counter |
| `POST /walker/get_quiz` | POST | Plans and generates a 3-4 minute micro-quiz targeting fading concepts |
| `POST /walker/submit_quiz` | POST | Grades answers, returns missed question explanations, and recalibrates stability |
| `POST /walker/get_graph_data` | POST | Supplies nodes and edges for the mobile visual concept map |
| `POST /walker/get_analytics` | POST | Returns historical Ebbinghaus retention curve coordinates and test trends |
| `POST /walker/get_notifications`| POST | Delivers Day-1 alerts and review reminders |

## ✅ Features implemented so far

Memora currently demonstrates the complete learning loop with a Jac backend and a temporary Expo mobile UI:

- Lecture notes can be entered and sent to the `ingest_lecture` walker.
- Lecture content is represented as structured concepts with summaries, rules, difficulty, and prerequisites.
- Concepts are organized in a persistent Object-Spatial knowledge graph.
- The dashboard shows retention health, active concepts, study streak, and the next review topic.
- Fading concepts can be prioritized for a short 3–4 minute quiz.
- The quiz flow supports timed multiple-choice questions and answer submission.
- Quiz results show accuracy, missed answers, explanations, and recalibrated concept stability.
- Ebbinghaus retention, review intervals, notification urgency, and mastery calculations are implemented as deterministic Jac logic.
- Analytics exposes retention-curve points, quiz history, mastery distribution, and estimated time saved.
- The mobile client includes fallback demo data, so the full UI flow can be previewed without a running backend.

### LLM integration status

The project is configured for OpenRouter through `OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, and `REASONING_MODEL` in `jac.toml`. The intended LLM roles are:

- **Lecture analysis:** extract concepts, summaries, formulas, and prerequisites from notes or images.
- **Quiz generation:** create grounded MCQs and active-recall questions with distractors.
- **Evaluation support:** explain misconceptions and assist with semantic grading.

The live paths are now wired through `by llm()` for lecture concept extraction, quiz-question generation, and misconception explanations. Deterministic seeded responses remain as a safe per-call fallback, so the UI and walker contracts still work if a model response is unavailable.

---

## 🏆 Hackathon Compliance
- **≥ 80% Jac Language Code**: Core cognitive decay math, graph storage, traversal, and all agents are implemented 100% in Jac.
- **Object-Spatial Persistence**: Graphs persist natively from `root` without an external database.
- **Hosted on JacHammer**: Ready for deployment to `jachammer.ai`.
