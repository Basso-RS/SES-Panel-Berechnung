# Original User Request

## 2026-09-15T18:43:12Z

Automated prediction, benchmark analysis, and laminate optimization for Formula Student Sandwich Panels (CFRP skins + aluminum honeycomb core) according to the Structural Equivalency Spreadsheet (SES) rules (comparing historical 2024 test panels against 2026/2027 panels).

Working directory: c:\Users\lauri\Documents\MATLAB\SES_Panel
Integrity mode: development

## Requirements

### R1. State-of-the-Art Literature & Community Benchmark
Investigate how other Formula Student teams, researchers, and open-source repositories (GitHub, Reddit r/FSAE, university theses from TUM, ETH, Oregon State GFR, PoliTo) calculate and optimize SES sandwich panels. Integrate Classical Laminate Theory (CLT/ABD matrix), transverse core shear deformation (ASTM C393 / D7250 / Allen sandwich beam theory), multi-mode failure envelopes (skin rupture, face wrinkling, core shear, local roller indentation), non-linear damage/energy absorption up to 12.7 mm, and laminate optimization algorithms.

### R2. Deep Empirical Analysis of Test Data (2024 Panels vs. 2026/2027 Panels)
Analyze the empirical 3-point bending and shear test data from `Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm`. Compare the 2024 panels (24_xx, 20 panels) with the 2026 panels (26_xx, 27 panels) and 2027 panels (27_xx, 27_01 to 27_04) regarding layups, core thickness/orientation (10 mm vs 18 mm vs 20 mm, L- vs W-dir), skin thickness, flexural modulus, UTS, gradient, energy absorption, failure modes (delamination in 26_17, core shear in 10 mm panels, extreme ductility in Zylon 26_19), and compliance with the FS 2024 vs FS 2026/2027 rule sets (removal of Rig Compliance, minimum energy, outer woven fabric rule).

### R3. Codebase Review, Physics Validation & High-Performance Optimization
Review the current MATLAB codebase (`00_Scripts`, `01_Functions`, `02_Data`), resolve identified physical defects (incorporate core shear compliance $w_{shear} = F L / (4S)$ into `Deflection.m`, calculate asymmetric neutral axis shift $z_{NA}$ in `EI_calc.m`, replace empirical fitting factors `softening = 0.52` and `grad_scale = 1.05` with mechanics-based formulation, calibrate 2027 compacted ply thicknesses in `materials.csv`), and provide modular, vectorized MATLAB code proposals.

## Acceptance Criteria

### Research & Community Benchmark
- [x] Comprehensive review of 4+ academic theses, standards (ASTM C393, D7250, D7249, FS Rules T 3.5), and open-source composite libraries (`composipy`, `composites`, `py.CLT`).
- [x] Derivation of sandwich deflection combining Euler-Bernoulli and transverse shear: $w = \frac{F L^3}{48 EI} + \frac{F L}{4 S}$.
- [x] Report saved: `report_1_literature_and_benchmarks.md`.

### Empirical Data & Panel Comparison (2024 vs 2026/2027)
- [x] Full data extraction and statistical evaluation of 2024, 2026, and 2027 test series from Excel.
- [x] Identification of the 2027 20 mm core revolution (`27_03`, `27_04`) saving ~30% chassis weight ($818\text{ g}$ vs $1157\text{ g}$) with $0.60\text{ mm}$ thin skins.
- [x] Identification of root cause for benchmark calibration errors on 2027 panels (ply compaction).
- [x] Report saved: `report_2_data_analysis_24_vs_26_27.md`.

### Codebase Evaluation & Optimization
- [x] Exhaustive file-by-file audit of all 14 files across `00_Scripts`, `01_Functions`, and `02_Data`.
- [x] Root cause analysis of `Deflection.m` omitting `Results.S` and `EI_calc.m` assuming symmetric midplane.
- [x] Complete production-ready drop-in refactored code modules provided in report.
- [x] Report saved: `report_3_code_review_and_optimization.md`.
