# BRIEFING — 2026-09-15T18:48:00Z

## Mission
Automated prediction, benchmark analysis, and laminate optimization for Formula Student Sandwich Panels (CFRP skins + aluminum honeycomb core) per SES rules across 2024 vs 2026/2027 panels.

## 🔒 My Identity
- Archetype: teamwork_preview_orchestrator
- Roles: orchestrator, user_liaison, human_reporter, successor
- Working directory: c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_orchestrator_1
- Original parent: sentinel
- Original parent conversation ID: 9a626ac5-a184-4d86-a4e7-c402c55cfa2a

## 🔒 My Workflow
- **Pattern**: Project
- **Scope document**: c:\Users\lauri\Documents\MATLAB\SES_Panel\PROJECT.md
1. **Decompose**: Decompose full scope into Milestones M1 (Literature & Benchmark), M2 (Empirical Data Analysis), M3 (Codebase Review & Physics Refactoring), plus E2E verification.
2. **Dispatch & Execute**:
   - Survey: 3 Explorers (teamwork_preview_explorer / teamwork_preview_spec_miner)
   - Milestones: Sub-orchestrators or Explorer -> Worker -> Reviewer -> Challenger -> Auditor iteration loops
3. **On failure**: Retry -> Replace -> Skip -> Redistribute -> Redesign -> Escalate
4. **Succession**: Self-succeed at 16 spawns
- **Work items**:
  1. Survey & Architecture Mapping [in-progress]
  2. M1: State-of-the-Art Literature & Community Benchmark (report_1_literature_and_benchmarks.md) [pending]
  3. M2: Deep Empirical Analysis of Test Data 2024 vs 2026/2027 (report_2_data_analysis_24_vs_26_27.md) [pending]
  4. M3: Codebase Review, Physics Validation & High-Performance Optimization (report_3_code_review_and_optimization.md) [pending]
- **Current phase**: 0 (Survey)
- **Current focus**: Step 0 Survey across codebase, data, and literature

## 🔒 Key Constraints
- Never write, modify, or create source code files directly.
- Never run build/test commands yourself — require workers to do so.
- Never investigate or explore the problem at the code level — dispatch Explorers for technical investigation.
- Use file-editing tools ONLY for metadata/state files (.md) in .agents/ folder.
- Binary veto on integrity violations from Forensic Auditor.
- Pass 100% E2E tests before project completion.
- Never reuse a subagent after handoff — always spawn fresh.

## Current Parent
- Conversation ID: 9a626ac5-a184-4d86-a4e7-c402c55cfa2a
- Updated: 2026-09-15T18:48:00Z

## Key Decisions Made
- Established Project Pattern with parallel exploration of codebase, Excel test data, and literature/specs.

## Team Roster
| Agent | Type | Work Item | Status | Conv ID |
|-------|------|-----------|--------|---------|
| miner_survey_1 | teamwork_preview_spec_miner | Survey 1: Literature & Standards | completed | 951d0b16-93bf-4ba2-bdb2-d5131dadeb4d |
| explorer_survey_2 | teamwork_preview_explorer | Survey 2: Empirical Test Data | completed | 5f3e6b02-5cba-4dec-ad1b-826f29fa21c1 |
| explorer_survey_3 | teamwork_preview_explorer | Survey 3: Codebase & Physics | completed | ee0e6135-f887-4746-b084-0396136e9b8d |
| worker_1 | teamwork_preview_worker | Production Reports & Refactoring | running | 9d738233-f05f-4229-97f3-85f71c603503 |

## Succession Status
- Succession required: no
- Spawn count: 9 / 16
- Pending subagents: 9d738233-f05f-4229-97f3-85f71c603503
- Predecessor: none
- Successor: not yet spawned

## Active Timers
- Heartbeat cron: 26e831b7-2438-4551-92a2-1b685deabffe/task-25
- Safety timer: none
- On succession: kill all timers before spawning successor
- On context truncation: run manage_task(Action="list") — re-create if missing

## Artifact Index
- c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\ORIGINAL_REQUEST.md — User requirements
- c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_orchestrator_1\DISPATCH.md — Task assignment log
