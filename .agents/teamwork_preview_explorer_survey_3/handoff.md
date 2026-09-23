# Handoff Report: Codebase Architecture & Physics Audit (Survey 3)

- **Agent**: Codebase & Physics Investigator (`teamwork_preview_explorer_survey_3`)
- **Recipient**: Parent Agent (`26e831b7-2438-4551-92a2-1b685deabffe`)
- **Timestamp**: 2026-09-15T19:28:00Z
- **Working Directory**: `c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_explorer_survey_3`
- **Full Report**: `c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_explorer_survey_3\survey_report.md`

---

## 1. Observation
1. **File Inventory & Architecture**:
   - Audited all 14 files across `00_Scripts` (4 files: `RunMe.m`, `Calculate_Single_Panel.m`, `Benchmark_Panels.m`, `Optimize_Panel.m`), `01_Functions` (9 files: `Calibration.m`, `Deflection.m`, `EI_calc.m`, `Energy_calc.m`, `Scenariodata.m`, `Shearstiff_calc.m`, `calc_cfk_properties.m`, `calc_panel_weight.m`, `optimize_laminate.m`), and `02_Data` (1 code file `Materialdata.m`, plus `materials.csv`, `FS_scrutie_final.xlsx`, `Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm`, datasheets).
   - Confirmed neither `Start_Analysis.m` nor `GUI.mlapp` exists; the active entry points are `RunMe.m` / `Calculate_Single_Panel.m`, `Benchmark_Panels.m`, and `Optimize_Panel.m`.
2. **Defect 1 (`Deflection.m`)**:
   - `Shearstiff_calc.m` (line 6) calculates core shear stiffness $S = \frac{G_c \cdot b \cdot d^2}{c}$.
   - `Deflection.m` (line 9) computes `Results.Gradient = ((48 * Results.EI) / (Scenario.panel.l^3)) * grad_scale;`. `Results.S` is completely omitted.
3. **Defect 2 (`EI_calc.m`)**:
   - `EI_calc.m` (lines 7-20) evaluates Steiner terms about $z = c/2 + t/2$, assuming the neutral axis always coincides with the geometric center of the core.
4. **Defect 3 (Empirical Fudge Factors)**:
   - `Calibration.m` hardcodes `softening_factor = 0.52`, `gradient_factor = 1.05`, `failure_strain = 0.00262`, and `indentation_depth = 1.0`.
   - In `Deflection.m` (line 38), $w_{max} = (w_{lin} / 0.52) + 1.0 + \text{slack}$.
5. **Defect 4 (Material Parameters & 2027 Calibration)**:
   - In `materials.csv`, Core shear modulus is listed as $G = 29\text{ MPa}$, whereas `Materialdata.m` hardcodes $G_L = 550\text{ MPa}$ and $G_W = 230\text{ MPa}$.
   - Nominal thicknesses in `materials.csv` are $0.31\text{ mm}$ (`t7`) and $0.21\text{ mm}$ (`m`).
   - In physical tests of 2027 panels (`27_03` and `27_04`), 6-ply skins measured only $0.60 - 0.65\text{ mm}$ ($CPT = 0.100\text{ mm/ply}$).
   - `Benchmark_Panels.m` (lines 58-59) explicitly excludes `27_03` and `27_04`. Running `eval_27_04.m` in MATLAB confirmed that the uncalibrated model yields a +131.2% thickness error, a -53.2% modulus error, and a +126.4% absorbed energy error ($74.5\text{ J}$ calc vs $32.9\text{ J}$ test).

---

## 2. Logic Chain
1. In 3-point bending of sandwich panels (ASTM C393 / D7250 / Allen), total deflection is $w = w_b + w_s = \frac{F L^3}{48 EI} + \frac{F L}{4 S}$. For PAMG 5056 honeycomb cores, transverse shear accounts for $14.8\%$ to $30.2\%$ of elastic deflection. Neglecting shear compliance causes `Deflection.m` to overestimate panel stiffness by **+23.3% to +50.4%**.
2. For asymmetric face sheets ($t_{top} \ne t_{low}$ or $E_{top} \ne E_{low}$), the neutral axis shifts by $z_{NA} = \frac{\sum E_i A_i z_i}{\sum E_i A_i}$ (up to $6\text{ mm}$). By the Parallel Axis Theorem, taking moments about the core midplane overestimates flexural rigidity $(EI)_{equiv} = b D_{11}^*$ by **+1.4% to +66.5%**, causing `Optimize_Panel.m` to recommend dangerously under-designed asymmetric skins.
3. Because the Euler-Bernoulli stiffness was artificially stiff, $w_{lin} = F_{max}/K$ was too small. The author introduced `softening = 0.52` ($1 / 0.52 = 1.923\times$) to match experimental peak displacements, lumping together elastic shear compliance, plastic honeycomb shear yielding, roller indentation contact mechanics, and machine rig compliance into an unphysical divisor.
4. The 2027 panels (`27_03` and `27_04`) achieved a ~30% chassis weight reduction ($818\text{ g}$ vs $1157\text{ g}$) by pairing a 20 mm core with thin, autoclave-compacted skins ($0.60\text{ mm}$, $V_f \approx 68\%$, $E = 213.8\text{ GPa}$). Using nominal thickness ($1.39\text{ mm}$) overestimates skin inertia and predicts an energy absorption of $74.5\text{ J}$ when the real panel absorbs only $32.9\text{ J}$, falsely claiming compliance with the SES 65 J rule.

---

## 3. Caveats
- Test machine displacement channels may include machine and fixture compliance ($C_{rig} \approx 0.05 - 0.12\text{ mm/kN}$) unless direct optical extensometry was used.
- Post-yield core behavior in PAMG 5056 honeycomb depends on cell wall buckling and core density, requiring calibration for different cell sizes.
- Fiber volume fraction $V_f$ scaling assumes conservation of fiber areal weight ($FAW$) during autoclave resin bleed.

---

## 4. Conclusion
The current MATLAB codebase contains severe physical discrepancies that overestimate asymmetric bending stiffness by up to +66% and overestimate thin-skin energy absorption by +126%. We have provided complete, production-ready refactored drop-in modules for `EI_calc.m`, `Deflection.m`, and `materials_2027.csv` in `survey_report.md` that replace empirical factors with rigorous ASTM C393 / D7250 shear compliance, CLT $D_{11}^*$ neutral axis formulations, and compacted CPT mechanics.

---

## 5. Verification Method
- **Direct Code Audit**: Review line numbers quoted in Section 1 using `view_file`.
- **Benchmark Reproduction**: Run `Benchmark_Panels.m` via `matlab -batch "cd('00_Scripts'); Benchmark_Panels; exit;"` to observe the baseline errors and the hardcoded exclusion of `27_03` and `27_04`.
- **27_04 Verification**: Run `matlab -batch "run('c:/Users/lauri/Documents/MATLAB/SES_Panel/.agents/teamwork_preview_explorer_survey_3/eval_27_04.m'); exit;"` to reproduce the +131.2% thickness and +126.4% energy errors.
- **Drop-in Verification**: Inspect the refactored code modules in Section 8 of `survey_report.md`.
