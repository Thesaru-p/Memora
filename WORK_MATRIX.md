# Memora - Team Work Distribution Matrix
> **AI Hackathon 2026 Sri Lanka**  
> **Team Size:** 3 Developers  
> **Target:** At least 80% Jac-native implementation (`jaclang`)

---

## 1. Developer Role Overview

| Member | Primary Role | Domain Ownership | Implementation Stack |
| :--- | :--- | :--- | :--- |
| **Developer 1** | **Frontend & Mobile UI Lead** | Mobile Client, UI/UX, Navigation, Visual Analytics, Notifications | React Native (Expo) / JacHammer Mobile Runner |
| **Developer 2** | **Backend Dev A (Ingestion & Graph Agents)** | Knowledge Graph Topology, Slide/Handwriting Vision Ingestion, Analyzer Agent, Graph Builder Agent | 100% Jac (`memora_graph.jac`, `agents/`, `by llm()`) |
| **Developer 3** | **Backend Dev B (Cognitive Engine & Quiz Agents)** | Ebbinghaus Mathematical Engine, Quiz Planning, Question Generation, Semantic Evaluator, Calibration & Analytics | 100% Jac (`ebbinghaus.jac`, `agents/`, `by llm()`) |

---

## 2. Detailed Work Breakdown Matrix

| Module / Component | Task Description | Primary Owner | Jac / Tech Mechanism | Est. Delivery | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Graph Schema** | Define persistent `SubjectNode`, `LectureNode`, `ConceptNode`, and typed edges (`depends_on`, `subconcept_of`, `relates_to`) | **Dev 2** | Jac `node`, `edge`, Object-Spatial Persistence from `root` | 10:30 AM | Ready |
| **Ebbinghaus Math Engine** | Implement retention decay $R(t) = e^{-\Delta t/S}$ and post-quiz stability recalibration equations | **Dev 3** | Jac pure logic & mathematical functions (`ebbinghaus.jac`) | 10:30 AM | Ready |
| **Mobile Shell & Nav** | Initialize Expo TypeScript app, design theme, setup stack navigation between screens | **Dev 1** | Expo SDK / React Navigation | 10:45 AM | Ready |
| **Vision & Ingestion Agent** | Multi-modal prompt (`by llm()`) to extract structured concepts from slides & handwritten note photos | **Dev 2** | Jac `walker:pub ingest_lecture` + `nvidia/nemotron-3.5-super-vl:free` | 11:30 AM | Planned |
| **Graph Builder Agent** | Traverse persistent graph from `root`, instantiate `ConceptNode`s, stitch prerequisite relations | **Dev 2** | Jac `walker` traversing native graph (`root ++> ...`) | 12:00 PM | Planned |
| **Quiz Planner Agent** | Traverse concept nodes, compute live $R(t)$, select 3–5 high-priority fading concepts for 3-4 min quiz | **Dev 3** | Jac `walker:pub plan_quiz` with spatial graph traversal | 12:00 PM | Planned |
| **Quiz Generator Agent** | Generate grounded MCQ & active recall questions with pedagogical distractors from node content | **Dev 3** | Jac `walker` + `by llm()` (`nvidia/nemotron-3-ultra:free`) | 12:45 PM | Planned |
| **Upload & Note Input Screen** | Mobile UI for typing notes or selecting slide/handwriting photos with processing animations | **Dev 1** | React Native Camera/Picker + API call to `ingest_lecture` | 12:45 PM | Planned |
| **Quiz Runner Screen** | Time-boxed 3–4 minute quiz player with 45s countdown timer, option selection, and progress bar | **Dev 1** | React Native animated timer + Quiz state machine | 01:30 PM | Planned |
| **Quiz Evaluator & Calibration** | Semantic grading of answers, generate 1–2 sentence misconception explanations, update $S$ and $R$ | **Dev 3** | Jac `walker:pub submit_quiz` + `by llm()` + in-place node update | 02:15 PM | Planned |
| **Missed Answers Debrief Screen** | Post-quiz results view showing score, missed questions, correct answers, and pedagogical explanation cards | **Dev 1** | React Native expandable cards rendering Walker debrief report | 02:45 PM | Planned |
| **Analytics Agent & Walkers** | Compute historical retention curve coordinates and mastery distributions | **Dev 3** | Jac `walker:pub get_analytics` | 03:00 PM | Planned |
| **Performance & Analytics Screen** | Visual line chart tracking memory retention % over days (decay + quiz jumps) and streak counter | **Dev 1** | SVG / Chart library rendering Ebbinghaus curves | 03:30 PM | Planned |
| **Knowledge Graph Visualizer** | Interactive visual concept map / "Skill Tree" color-coded (🟢 Green, 🟡 Yellow, 🔴 Red) | **Dev 1 & Dev 2** | Jac `get_graph_data` walker + Mobile interactive canvas | 04:00 PM | Planned |
| **End-to-End Testing & Polish** | Verify full cycle (Upload $\to$ 24h Alert $\to$ 3-min Quiz $\to$ Debrief $\to$ Analytics), check Jac test suite | **All Devs** | `jac test tests/*.jac` + Expo Go live testing | 04:45 PM | Planned |
| **Demo Video & Presentation** | Record 2–3 minute demo walk-through highlighting Ebbinghaus problem, Jac multi-agent solution, and UI | **All Devs** | Screen recording + pitch deck alignment | 05:15 PM | Planned |

---

## 3. Jac Codebase Ratio Strategy (>80% Jac Compliance)

To strictly comply with the **≥ 80% Jac code rule**:
1. **All Business Logic in Jac**: Concept extraction, graph traversal, Ebbinghaus decay math, quiz planning, question generation, semantic grading, and analytics calculation live entirely inside `.jac` files.
2. **Lean Mobile Client**: The React Native client is kept as a thin, reactive presentation layer whose state is driven 100% by Jac walkers.
3. **Native Object-Spatial Programming**: Leveraging Jac's native `node`, `edge`, and `walker` constructs eliminates external ORMs and custom SQL/NoSQL code.

---

## 4. API & Walker Contract Agreement

All communication between Frontend (**Dev 1**) and Backend (**Dev 2 & 3**) follows standardized Jac walker endpoints:

| Endpoint | Method | Input Parameters | Output Response Payload | Owner |
| :--- | :--- | :--- | :--- | :--- |
| `POST /walker/ingest_lecture` | POST | `{ "subject": str, "title": str, "notes_text": str, "image_b64"?: str }` | `{ "lecture_id": str, "extracted_concepts": list[dict], "graph_nodes_count": int }` | **Dev 2** |
| `POST /walker/get_dashboard` | POST | `{ "subject": str }` | `{ "subject_name": str, "retention_pct": float, "pending_quizzes": list, "streak": int }` | **Dev 2** |
| `POST /walker/get_graph_data` | POST | `{ "subject": str }` | `{ "nodes": list[dict], "edges": list[dict] }` | **Dev 2** |
| `POST /walker/plan_quiz` | POST | `{ "subject": str }` | `{ "quiz_id": str, "duration_seconds": int, "questions": list[dict] }` | **Dev 3** |
| `POST /walker/submit_quiz` | POST | `{ "quiz_id": str, "answers": list[dict] }` | `{ "score": float, "accuracy_pct": float, "recalibrated_concepts": list[dict], "missed_explanations": list[dict] }` | **Dev 3** |
| `POST /walker/get_analytics` | POST | `{ "subject": str }` | `{ "retention_curve": list[dict], "quiz_history": list[dict], "mastery_distribution": dict }` | **Dev 3** |
| `POST /walker/get_notifications`| POST | `{ "subject": str }` | `{ "notifications": list[dict] }` | **Dev 3** |

---

## 5. Hackathon Submission Checklist (Target: 5:30 PM)

- [x] Repository structured with `jac.toml`, `main.jac`, `rules.md`, `PLAN.md`, `WORK_MATRIX.md`.
- [ ] At least 80% of project code written in Jac.
- [ ] Working GitHub repository with clear commit history.
- [ ] Tested and verified with `jac test`.
- [ ] Project hosted / previewable on JacHammer (`jachammer.ai`).
- [ ] Pitch deck covering problem, solution, Ebbinghaus science, and novelty.
- [ ] Starred official Jac repository: `https://github.com/jaseci-labs/jac`.
- [ ] Working demo video submitted by 5:30 PM.
