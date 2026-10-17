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
# Verify Jac version
jac --version

# Run the Jac multi-agent backend entrypoint
jac run main.jac

# Run backend REST API server (exposing public walkers)
jac start main.jac
```

### 2. Running Automated Jac Tests
```bash
# Run all unit tests
jac test tests/test_forgetting_curve.jac
jac test tests/test_graph.jac
```

### 3. Mobile App Setup (Dev 1)

The JacHammer entry point is a Jac mobUI mobile dashboard (`client_kind = "mobui"`
in `jac.toml`). It uses native-compatible components and a phone-width layout;
JacHammer can render the same components in its browser preview.
To run this Jac UI on a device with a current Jac runtime:

```bash
jac setup react-native
jac start main.jac --client react-native --dev
```

Android/iOS builds require their native development tools. The separate Expo
client below remains owned by Dev 1.

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
| `POST /walker/get_openrouter_status` | POST | Reports whether the backend loaded its API key; `{"verify": true}` tests the ingestion model |
| `POST /walker/get_quiz` | POST | Plans and generates a 3-4 minute micro-quiz targeting fading concepts |
| `POST /walker/submit_quiz` | POST | Grades answers, returns missed question explanations, and recalibrates stability |
| `POST /walker/get_graph_data` | POST | Supplies nodes and edges for the mobile visual concept map |
| `POST /walker/get_analytics` | POST | Returns historical Ebbinghaus retention curve coordinates and test trends |
| `POST /walker/get_notifications`| POST | Delivers Day-1 alerts and review reminders |

---

## 🏆 Hackathon Compliance
- **≥ 80% Jac Language Code**: Core cognitive decay math, graph storage, traversal, and all agents are implemented 100% in Jac.
- **Object-Spatial Persistence**: Graphs persist natively from `root` without an external database.
- **Hosted on JacHammer**: Ready for deployment to `jachammer.ai`.

### Checking OpenRouter in JacHammer

The mobile dashboard's **OpenRouter · Lecture AI** card reads the configuration
from the running backend, without returning any API key or key fragment. An amber
**Key loaded · not tested** means the key is present, not that OpenRouter accepted
it. Tap **Test OpenRouter** to send a small prompt through the same request helper
and vision-model override used by lecture ingestion. This uses one model request;
opening or refreshing the dashboard does not automatically call OpenRouter.

Green **Connection verified** means the model returned an answer. Other statuses
identify a missing key, authentication/access failure, rate limit, network timeout,
or missing final answer. Lecture ingestion separately requires a valid structured
response containing 4-8 concepts. If extraction fails, the endpoint returns an
error and writes no lecture or concept nodes; it never substitutes demo concepts.

For temporary JacHammer testing, the mobile preview includes a **Vision ingestion
test** card. Enter a subject and lecture title, choose a JPG, PNG, or WebP image up
to 5 MB, and tap **Extract image concepts**. The browser converts the selected
image to base64 and calls `ingest_lecture`; no JacHammer CLI is required.

Run the offline diagnostic tests with `jac test tests/test_openrouter_status.jac`
and `jac test tests/test_lecture_analyzer.jac`.
