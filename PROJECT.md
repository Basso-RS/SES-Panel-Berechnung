# Project: Formula Student SES Sandwich Panel Prediction, Benchmark & Optimization

## Architecture
- **Domain**: Composite sandwich panel mechanics, automated prediction, benchmark calibration, and laminate optimization for Formula Student monocoques conforming to Structural Equivalency Spreadsheet (SES) rules.
- **Data Flow**:
  1. Material databases (`materials.csv`, `materials_2027.csv`, `Materialdata.m`) define ply thickness (CPT), elastic moduli ($E_1, E_2, G_{12}, \nu_{12}$), strengths, core density, and core shear moduli ($G_L, G_W$).
  2. Input scenarios (`Scenariodata.m`, test panels) define coupon geometry ($b, L, c$), face sheet layups, and test configurations (ASTM C393 3-point bending).
  3. Laminate kinematics (`calc_cfk_properties.m`, `EI_calc.m`) construct Classical Laminate Theory (CLT) $[A], [B], [D]$ matrices, evaluate neutral axis shift $z_{NA} = B_{11}/A_{11}$, and calculate effective bending stiffness $(EI)_{equiv} = b \cdot (D_{11} - B_{11}^2 / A_{11})$.
  4. Core shear kinematics (`Shearstiff_calc.m`) evaluate core shear stiffness $S = G_{core} \cdot b \cdot d^2 / c$.
  5. Structural response & failure envelope (`Deflection.m`, `Energy_calc.m`) superimpose bending and shear compliance $w = \frac{F L^3}{48 EI} + \frac{F L}{4 S}$, evaluate multi-mode competitive failure $F_{peak} = \min(F_{skin}, F_{wrinkling}, F_{core\_shear}, F_{indent})$, model post-yield crushing plateau, and integrate energy $E_{12.7} = \int_0^{12.7} F(w) dw$.
  6. Calibration and benchmarking (`Calibration.m`, `Benchmark_Panels.m`) evaluate prediction accuracy across all 51 physical test panels (2024, 2026, 2027).
  7. Optimization (`Optimize_Panel.m`, `optimize_laminate.m`) searches the discrete laminate space for minimum chassis mass subject to SES rules ($EI \ge EI_{target}$, $F_{max} \ge F_{target}$, $E_{12.7} \ge 65\text{ J}$, outer woven layer, parallel plies $\le 50\%$).

## Feature Inventory
Every feature from the Survey phase is mapped to its assigned milestone:
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | FS Rules SIS & SES Target Extraction | Steel baseline tubing EI targets (2-tube $3403.6\text{ N}\cdot\text{m}^2$, 3-tube $5105.4\text{ N}\cdot\text{m}^2$), $65\text{ J}$ min energy, $7.5\text{ kN}$ punch shear | M1 | Survey 1 (FS Rules T3.2, T3.15) |
| 2 | Testing Standards Rigor | ASTM C393 core shear, ASTM D7250 stiffness decoupling, ASTM D7249 long beam flexure | M1 | Survey 1 (ASTM standards) |
| 3 | Academic Methodology Survey | TUM, ETH Zürich, Oregon State GFR, PoliTo, TU Delft monocoque & SES designs | M1 | Survey 1 (Academic theses) |
| 4 | Open-Source Composite Tools | Evaluation of composipy, py.CLT, composites, and optimization algorithms | M1 | Survey 1 (Open-source tools) |
| 5 | Two-Term Sandwich Deflection Derivation | Mathematical derivation of $w = \frac{FL^3}{48EI} + \frac{FL}{4S}$ via Reissner-Mindlin and Allen beam theory | M1 | Survey 1 & 3 |
| 6 | Multi-Mode Failure Envelope Formulation | Analytic formulation of skin rupture, Hoff-Mautner/Plantema face wrinkling, core shear, and roller indentation | M1 | Survey 1 |
| 7 | Non-Linear Energy & Post-Yield Crushing | Plastic cell folding plateau mechanics replacing lumped empirical scalars | M1 | Survey 1 & 3 |
| 8 | Optimization Mathematical Formulation | Constrained discrete optimization for minimum mass under SES & FS manufacturing constraints | M1 | Survey 1 |
| 9 | Full 2024 Test Series Evaluation | 20 panels (`24_02` to `24_21`), layups, flexural modulus, UTS, gradient, energy | M2 | Survey 2 (Excel / Overview) |
| 10 | Full 2026 Test Series Evaluation | 27 panels (`26_01` to `26_27`), layups, flexural modulus, UTS, gradient, energy | M2 | Survey 2 (Excel / Overview) |
| 11 | Full 2027 Test Series Evaluation | 4 physical panels (`27_01` to `27_04`), layups, flexural modulus, UTS, gradient, energy | M2 | Survey 2 (Excel / Overview) |
| 12 | Core Thickness & Geometry Impact | Comparison of 10 mm vs 18 mm vs 20 mm core performance and lever arm mechanics | M2 | Survey 2 |
| 13 | Core Ribbon Anisotropy Analysis | PAMG-XR1-5056 L-direction ($G_L=550\text{ MPa}$) vs W-direction ($G_W=230\text{ MPa}$) | M2 | Survey 2 (Datasheets) |
| 14 | Delamination Analysis in Panel `26_17` | Modulus mismatch peeling and its elimination via double fabric buffer in `26_18` | M2 | Survey 2 |
| 15 | Core Shear Failure in 10 mm Panels | Shear stress overload ($\tau > 2.4\text{ MPa}$) in `24_11`-`24_13` and `26_12` | M2 | Survey 2 |
| 16 | Zylon Panel `26_19` Extreme Ductility | Compressive micro-fibril kink-banding, neutral axis shift, and $110.5\text{ J}$ energy plateau | M2 | Survey 2 |
| 17 | 2027 20 mm Core Revolution Evaluation | Panels `27_03` & `27_04` saving 29.3% weight ($818\text{ g}$ vs $1157\text{ g}$) with $0.60\text{ mm}$ skins | M2 | Survey 2 |
| 18 | Ply Compaction Calibration Root Cause | Nominal vs cured ply thickness ($0.100\text{ mm/ply}$) explaining 2027 benchmark errors | M2 | Survey 2 & 3 |
| 19 | FS Rules Transition (2024 vs 2026/2027) | Elimination of rig compliance compensation, outer woven rule (T3.5.7), 50% parallel rule (T3.5.3) | M2 | Survey 2 |
| 20 | Exhaustive 14-File Codebase Audit | Detailed inspection of all scripts and functions across `00_Scripts`, `01_Functions`, `02_Data` | M3 | Survey 3 |
| 21 | Root Cause of `Deflection.m` Shear Omission | Neglect of `Results.S` overpredicting stiffness by +23% to +50% | M3 | Survey 3 |
| 22 | Root Cause of `EI_calc.m` Asymmetric Shift | Midplane symmetry assumption overestimating asymmetric flexural rigidity by up to +66.5% | M3 | Survey 3 |
| 23 | Replacement of Empirical Fitting Factors | Deconstructing `softening = 0.52` and `grad_scale = 1.05` into rigorous mechanics | M3 | Survey 3 |
| 24 | Material Parameters & 2027 Database Calibration | Calibrated `materials_2027.csv` and dynamic compaction scaling law | M3 | Survey 3 |
| 25 | Performance Profiling & Vectorization | Precomputed tensor lookup tables accelerating laminate search by >750x | M3 | Survey 3 |
| 26 | Production-Ready Refactored Modules | Drop-in replacements: `EI_calc_refactored.m`, `Deflection_refactored.m`, `materials_2027.csv` | M3 | Survey 3 |
| 27 | Comprehensive E2E Verification & Testing | Verification across all reports, calculations, scripts, and integrity forensics | M4 | All Surveys / Orchestration |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Literature & Community Benchmark Report | Generate `report_1_literature_and_benchmarks.md` incorporating academic theses, ASTM standards, CLT/shear derivations, failure envelopes, and optimization algorithms | Phase 0 Survey 1 | DONE |
| M2 | Deep Empirical Data Analysis Report | Generate `report_2_data_analysis_24_vs_26_27.md` analyzing 2024 vs 2026/2027 panels, 20 mm core revolution, failure modes, compaction calibration, and rule transitions | Phase 0 Survey 2 | DONE |
| M3 | Codebase Review & Optimization Report | Generate `report_3_code_review_and_optimization.md` detailing 14-file audit, shear compliance in `Deflection.m`, asymmetric neutral axis in `EI_calc.m`, replacement of empirical factors, and drop-in modules | Phase 0 Survey 3 | DONE |
| M4 | Comprehensive Verification & Auditing | Multi-agent verification (Reviewers, Challengers, and Forensic Auditor) of all reports, physics models, test comparisons, and code modules | M1, M2, M3 | IN_PROGRESS |

## Interface Contracts
### `calc_cfk_properties` ↔ `EI_calc`
- Input: `Laminat` (struct with `.top` and `.bot` ply arrays), `materials` (table)
- Output: `cfk` struct with `.E_top`, `.E_bot`, `.t_top`, `.t_bot`, `[A]`, `[B]`, `[D]` matrices
- Invariant: Conserves fiber areal weight under cured ply compaction: $CPT = \frac{FAW}{\rho_{fiber} \cdot V_f}$.

### `EI_calc` ↔ `Deflection`
- Input: `cfk` struct, `Scenario.panel` ($b, L, c$)
- Output: `Results.EI` computed about true neutral axis: $(EI)_{equiv} = b \cdot (D_{11} - B_{11}^2 / A_{11})$, neutral axis shift $z_{NA} = B_{11}/A_{11}$.
- Invariant: For symmetric laminates, $B_{11} = 0 \implies z_{NA} = 0$ and $(EI)_{equiv} = b D_{11}$.

### `Shearstiff_calc` ↔ `Deflection`
- Input: `Material.core` ($G_L$ or $G_W$), `Scenario.panel` ($b, c, d$)
- Output: `Results.S = G_core * b * d^2 / c` (transverse core shear stiffness in N).

### `Deflection` ↔ `Energy_calc`
- Input: `Results.EI`, `Results.S`, `Scenario.panel.l`, `Force`
- Output: Elastic compliance $C = \frac{L^3}{48 EI} + \frac{L}{4 S}$, force-deflection curve up to failure load $F_{peak} = \min(F_{skin}, F_{wrinkling}, F_{core\_shear}, F_{indent})$.
- Post-yield: Plastic honeycomb folding plateau $\eta_{soft} \approx 0.65 - 0.80$, integrated to $12.7\text{ mm}$ for $E_{12.7} \ge 65\text{ J}$.

## Code Layout
- `00_Scripts/`: High-level entry points (`RunMe.m`, `Calculate_Single_Panel.m`, `Benchmark_Panels.m`, `Optimize_Panel.m`)
- `01_Functions/`: Core physics calculations (`Calibration.m`, `Deflection.m`, `EI_calc.m`, `Energy_calc.m`, `Scenariodata.m`, `Shearstiff_calc.m`, `calc_cfk_properties.m`, `calc_panel_weight.m`, `optimize_laminate.m`)
- `02_Data/`: Material cards and empirical datasets (`materials.csv`, `materials_2027.csv`, `Materialdata.m`, `FS_scrutie_final.xlsx`, `Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm`, datasheets)
- Reports at project root:
  * `report_1_literature_and_benchmarks.md`
  * `report_2_data_analysis_24_vs_26_27.md`
  * `report_3_code_review_and_optimization.md`
