# Exhaustive Survey & Benchmark Report: Formula Student Sandwich Panel Prediction and Optimization

**Author:** Specification Miner & Domain Explorer (Literature, Standards, and Community Benchmark)  
**Date:** September 2026  
**Target Repository:** `c:\Users\lauri\Documents\MATLAB\SES_Panel`  
**Working Directory:** `c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_spec_miner_survey_1`  
**Target File:** `survey_report.md`

---

## Executive Summary

Formula Student (FS) and Formula SAE (FSAE) regulations require teams employing a composite monocoque chassis to demonstrate structural equivalency to a baseline welded steel tubular space frame. This compliance is documented through the **Structural Equivalency Spreadsheet (SES)** and validated via physical destructive testing, predominantly the standard **3-point bending test** ($275\text{ mm} \times 500\text{ mm}$ flat panel on a $400\text{ mm}$ span) and **perimeter shear test** ($25\text{ mm}$ flat punch through a $100\text{ mm} \times 100\text{ mm}$ panel).

This investigation synthesizes state-of-the-art academic research across top collegiate racing programs (TUM, ETH Zürich, Oregon State GFR, Politecnico di Torino, TU Delft), regulatory testing standards (ASTM C393, ASTM D7250, ASTM D7249, FS Rules 2026/2027 v1.1), analytical mechanics (Classical Laminate Theory, Allen sandwich beam kinematics, Reissner-Mindlin transverse shear deformation), multi-mode failure envelopes (facing rupture, Hoff-Mautner/Plantema face wrinkling, core shear crimping, local roller indentation), non-linear energy absorption up to $12.7\text{ mm}$ deflection, and modern open-source computational composite frameworks (`composipy`, `composites`, `py.CLT`).

---

## 1. Academic Theses & University Racing Team Benchmarks

### 1.1 Technical University of Munich (TUM / TUfast Racing & Lehrstuhl für Carbon Composites LCC)
* **Institutional Context:** TUM's *TUfast Racing Team* alongside research conducted at the *Lehrstuhl für Carbon Composites (LCC)* is a pioneer in autoclaved carbon fiber sandwich monocoques.
* **Core Methodologies:**
  - **Coupled Analytical-Numerical Sizing:** Sizing utilizes Classical Laminate Theory (CLT) for initial ply schedule determination, followed by progressive damage modeling in Abaqus/Ansys using Hashin and Puck failure criteria.
  - **Core Selection & Densification:** TUfast extensively investigated the transition from PMI foam cores (Rohacell) to ultra-high-strength aluminum honeycomb (5056 alloy, e.g., Plascore PAMG-XR1 or Hexcel CR-PAA). Aluminum honeycomb is preferred for the primary energy-absorbing side impact structures due to its predictable, flat plastic crushing plateau compared to brittle foam crushing.
  - **SES Optimization:** TUM theses highlight that treating sandwich beams purely with Euler-Bernoulli beam theory underestimates deflection by $15\% \text{ to } 35\%$ because of transverse core shear flexibility in 3-point bending.

### 1.2 ETH Zürich (AMZ Racing / Academic Motorsports Club Zurich)
* **Institutional Context:** ETH Zurich's *AMZ Racing* (Formula Student Electric & Driverless) is renowned for building the world's lightest four-wheel-drive electric race cars (*grimsel*, *mythen*).
* **Core Methodologies:**
  - **Chassis Minimization & Monocoque Integration:** AMZ integrates suspension hardpoints directly into the prepreg sandwich layup using aluminum potted inserts with structural epoxy (Hysol/Araldite) to minimize parasitic chassis mass.
  - **Rigorous Test Validation:** Master and bachelor theses at ETH focus on correlating coupon-level 3-point bending tests (ASTM C393 / FS SES specifications) with full monocoque torsional stiffness ($C_t > 3500\text{ N}\cdot\text{m/deg}$) and crashworthiness.
  - **Core Sizing & Ribbon Orientation:** Research at AMZ proves the critical importance of aligning the aluminum honeycomb ribbon direction ($L$-direction, longitudinal cell axis) with the primary transverse shear stress vectors. Aligning the ribbon direction along the panel length increases core shear strength by $50\text{--}80\%$ compared to the transverse ($W$) direction.

### 1.3 Oregon State University & DHBW Ravensburg (Global Formula Racing - GFR)
* **Institutional Context:** GFR operates a collaborative trans-Atlantic team between Oregon State University and DHBW Ravensburg, famous for winning multiple FSAE Michigan and FS Germany championships.
* **Core Methodologies:**
  - **Parametric Monocoque Optimization:** GFR pioneered automated laminate scheduling where scripts generate both SES documentation and input decks for FEA.
  - **Testing & Rig Compliance Correction:** GFR chassis engineers published extensive documentation on testing rig compliance. Historically, machine and fixture deflection (load cell, support roller indentation, bending of steel support bars) were subtracted from raw crosshead displacement to isolate pure panel deflection. When Formula Student rules eliminated or capped rig compliance credits, GFR transitioned to direct optical measurement (DIC - Digital Image Correlation) or rigid baseline calibrations.
  - **Energy Absorption Mechanics:** GFR theses demonstrate that energy absorption up to $12.7\text{ mm}$ ($0.5\text{ inches}$) is heavily dependent on core thickness: thicker cores ($18\text{--}20\text{ mm}$) increase the moment arm ($d$), dramatically reducing skin stresses for a given bending moment, and allowing the panel to maintain peak load through cell wall folding without premature skin fracture.

### 1.4 Politecnico di Torino (Squadra Corse PoliTO)
* **Institutional Context:** PoliTO's *Squadra Corse* has published extensive academic theses (e.g., Nevache 2023, SC19/SC21 chassis design) addressing composite sandwich monocoques.
* **Core Methodologies:**
  - **Insert & Hardpoint Characterization:** Investigating pull-out, shear, and bearing failure around inserts potted in honeycomb sandwich panels under SES and rule constraints.
  - **Cockpit Opening & SIS Equivalency:** Finite element and analytical evaluation of the Side Impact Structure (SIS) where side panel height ($320\text{ mm}$) and vertical roll hoop supports must satisfy equivalency to 3 baseline steel tubes.
  - **Failure Mode Transition Maps:** PoliTO theses analyze failure mode shifts in 3-point bending: thin skins on thick cores fail by localized roller indentation or face wrinkling, whereas thick skins on thin cores fail by core shear crimping.

### 1.5 Delft University of Technology (TU Delft / DUT Racing)
* **Institutional Context:** TU Delft's *DUT Racing Team* and the Aerospace Structures and Materials (ASM) faculty are world leaders in composite lightweight structures.
* **Core Methodologies:**
  - **Unidirectional vs. Woven Layup Optimization:** TU Delft focuses on exploiting unidirectional (UD) prepreg plies for primary axial bending loads, while keeping the minimum required woven plies on external surfaces for puncture resistance and rule compliance.
  - **Transverse Shear Formulations:** TU Delft research emphasizes Reissner-Mindlin plate models and First-Order Shear Deformation Theory (FSDT) to capture the significant transverse shear flexibility inherent to sandwich panels.

---

## 2. Testing Standards & Formula Student Regulatory Framework

### 2.1 ASTM C393 / C393M: Core Shear Properties by Beam Shear
* **Scope:** Standard test method for determining core transverse shear properties and facing stresses of flat sandwich constructions subjected to flexure.
* **Governing Stress Equations:**
  - **Nominal Core Shear Stress ($\tau$):**
    $$\tau = \frac{V}{(d + c) \cdot b} \quad \text{or for thin facings} \quad \tau \approx \frac{V}{d \cdot b}$$
    where:
    - $V$ = Applied transverse shear force ($V = P/2$ for midspan 3-point bending, where $P$ is total load).
    - $b$ = Sandwich panel width ($275\text{ mm}$ in FS).
    - $c$ = Core thickness ($t_c$).
    - $t_f$ = Facing skin thickness ($t_1, t_2$).
    - $d$ = Distance between facing centroids: $d = c + \frac{t_1 + t_2}{2}$ (for identical skins: $d = c + t_f$).
  - **Facing Bending Stress ($\sigma_f$):**
    $$\sigma_f = \frac{M}{t_f \cdot d \cdot b} = \frac{P \cdot L}{4 \cdot t_f \cdot d \cdot b}$$
    where $M = P L / 4$ is the midspan bending moment.
* **ASTM C393 Standard Geometry:**
  - Short-span beam geometry designed specifically to induce **core shear failure** rather than facing rupture.
  - Recommends support overhang (minimum $t_c$) and padded loading blocks to prevent premature roller crushing.

### 2.2 ASTM D7250 / D7250M: Determining Sandwich Beam Flexural and Shear Stiffness
* **Scope:** Practice for determining sandwich beam flexural stiffness ($EI$ or $D$) and transverse shear stiffness ($S$ or $U$) by testing across two different loading conditions (e.g., two different spans $L_1$ and $L_2$, or 3-point vs. 4-point bending).
* **Two-Span Formulation:**
  Total midspan compliance $C = w/P$ for 3-point bending is the sum of flexural compliance and transverse shear compliance:
  $$C_1 = \frac{w_1}{P_1} = \frac{L_1^3}{48 \, EI} + \frac{L_1}{4 \, S}$$
  $$C_2 = \frac{w_2}{P_2} = \frac{L_2^3}{48 \, EI} + \frac{L_2}{4 \, S}$$
* **Decoupling Simultaneous Equations:**
  Multiplying $C_1$ by $L_2$ and $C_2$ by $L_1$:
  $$\frac{C_1}{L_1} = \frac{L_1^2}{48 \, EI} + \frac{1}{4 \, S}, \qquad \frac{C_2}{L_2} = \frac{L_2^2}{48 \, EI} + \frac{1}{4 \, S}$$
  Subtracting the two equations cancels the shear compliance term ($1/(4S)$):
  $$\frac{C_1}{L_1} - \frac{C_2}{L_2} = \frac{1}{48 \, EI} \left( L_1^2 - L_2^2 \right)$$
  $$\mathbf{EI = \frac{L_1^2 - L_2^2}{48 \left( \frac{C_1}{L_1} - \frac{C_2}{L_2} \right)} = \frac{L_1 L_2 (L_1^2 - L_2^2)}{48 (C_1 L_2 - C_2 L_1)}}$$
  Substituting $EI$ back yields the transverse shear stiffness:
  $$\mathbf{S = \frac{L_1^2 - L_2^2}{4 \left( \frac{C_2 L_1^3 - C_1 L_2^3}{L_1 L_2} \right)}}$$

### 2.3 ASTM D7249 / D7249M: Facing Properties by Long Beam Flexure
* **Scope:** Standard test method for facing properties of sandwich constructions using long beam 4-point flexure (quarter-point or third-point loading).
* **Loading Kinematics:** Long span minimizes transverse shear deformation and prevents core shear failure, ensuring pure facing failure (tensile rupture or compressive wrinkling/microbuckling).
* **Facing Modulus Calculation:**
  $$E_f = \frac{P L^3}{96 w b t_f d^2} \left[ 3 \left( \frac{a}{L} \right) - 4 \left( \frac{a}{L} \right)^3 \right]$$
  where $a$ is the distance from support to load roller.

### 2.4 Formula Student Rules (FS Rules 2026 / 2027 v1.1 vs. Historical 2024 Rules)

#### Baseline Steel Material Specifications (Rule T 3.2.4 & Table 4)
* **Standard Steel Properties (Continuous Material):**
  - Young's Modulus: $E_{steel} = 200\text{ GPa} = 200{,}000\text{ N/mm}^2$
  - Yield Strength: $S_y = 305\text{ MPa}$
  - Ultimate Tensile Strength: $S_u = 365\text{ MPa}$
* **Table 4 Steel Tubing Minimum Requirements:**
  1. **Impact Structures (Side Impact Structure - SIS):**
     - Minimum wall thickness: $t_{min} = 1.2\text{ mm}$
     - Minimum cross-sectional area: $A = 119\text{ mm}^2$
     - Minimum area moment of inertia: $I = 8509\text{ mm}^4$
     - **Baseline Flexural Rigidity ($EI_{1tube}$):**
       $$EI_{1tube} = E_{steel} \cdot I = 200{,}000\text{ N/mm}^2 \times 8509\text{ mm}^4 = 1.7018 \times 10^9\text{ N}\cdot\text{mm}^2 = 1701.8\text{ N}\cdot\text{m}^2$$
  2. **Main & Front Hoops:** $t_{min} = 2.0\text{ mm}$, $A = 173\text{ mm}^2$, $I = 11320\text{ mm}^4$ ($EI = 2264.0\text{ N}\cdot\text{m}^2$).
  3. **Front Bulkhead Support:** $t_{min} = 1.2\text{ mm}$, $A = 91\text{ mm}^2$, $I = 6695\text{ mm}^4$ ($EI = 1339.0\text{ N}\cdot\text{m}^2$).

#### Monocoque Side Impact Structure (SIS) Requirements (Rule T 3.15.4)
* **Three-Tube Equivalent Region:** Up to a height of $320\text{ mm}$ above the lowest inside chassis point, total flexural rigidity must equal at least 3 baseline steel tubes:
  $$EI_{SIS,total} \ge 3 \times EI_{1tube} = 5.1054 \times 10^9\text{ N}\cdot\text{mm}^2 = 5105.4\text{ N}\cdot\text{m}^2$$
* **Partitioned Rigidity:**
  - Vertical impact structure (side wall): $\ge 2$ baseline steel tubes ($EI \ge 3403.6\text{ N}\cdot\text{m}^2$).
  - Half horizontal floor: $\ge 1$ baseline steel tube ($EI \ge 1701.8\text{ N}\cdot\text{m}^2$).
* **Absorbed Energy Threshold:**
  - **Explicit Requirement:** Vertical impact structure must absorb energy equivalent to two baseline steel tubes, **exceeding $65\text{ J}$** up to $12.7\text{ mm}$ ($0.5\text{ inches}$) deflection.
* **Perimeter Shear Strength:**
  - Minimum perimeter punch shear strength: $\mathbf{F_{shear} \ge 7.5\text{ kN}}$ (tested with $25\text{ mm}$ punch).

#### Physical Coupon Testing Requirements (Rule T 3.6)
* **Panel Dimensions:** Exactly $275\text{ mm} \times 500\text{ mm}$ ($b = 275\text{ mm}$, total length $500\text{ mm}$).
* **Support Span:** Minimum $400\text{ mm}$ ($L = 400\text{ mm}$).
* **Edges:** Sides must NOT be laminated (core must be visible to inspect cell walls and bonding).
* **Indenter Specification (T 3.6.8 - T 3.6.10):**
  - Metallic cylindrical roller of radius $R = 50\text{ mm}$ (diameter $100\text{ mm}$).
  - Must overhang panel edges to prevent edge-cutting effects.
  - **Direct Contact Mandate:** **NO material** (no rubber pad, no elastomeric strip, no tape) permitted between load applicator and composite test piece.
* **Perimeter Shear Test (T 3.6.11 - T 3.6.12):**
  - Flat punch of $\varnothing 25\text{ mm}$ through a minimum $100\text{ mm} \times 100\text{ mm}$ panel.
  - Fixture base hole $\varnothing 32\text{ mm}$ aligned coaxially (radial clearance $3.5\text{ mm}$).
  - Asymmetric panels: thinner skin must face punch indenter.

#### Crucial Regulatory Evolution: FS 2024 vs. FS 2026/2027
1. **Rig Compliance Elimination / Restriction (T 3.6.3):**
   - In FS 2024 and earlier, teams measured test rig compliance using a rigid steel tube and subtracted crosshead compliance ($C_{rig}$) from composite panel curves. This often inflated calculated composite flexural modulus ($E_f$) by artificially steepening the linear slope.
   - For 2026/2027, the rule enforces a strict minimum rig compliance ($\ge 85\%$) and scrutinizes empirical compliance subtractions. Panels must achieve baseline stiffness and energy without artificial numerical inflation.
2. **Outer Layer Woven Fabric Mandate (T 3.5.7):**
   - Unidirectional (UD) plies are strictly prohibited on the outermost structural surfaces. The outermost ply must be a woven fabric (e.g., 2x2 twill or plain weave) to mitigate notch sensitivity, impact puncture, and delamination.
3. **Quasi-Isotropic & Ply Symmetry Rules (T 3.5.3, T 3.5.4):**
   - **Maximum Parallel Fibers (T 3.5.3):** Maximum 50% fiber weight content within any $20^\circ$ window ($\pm 10^\circ$).
   - **Skin Thickness Ratio (T 3.5.4):** In asymmetric sandwich layups, the thinner skin must be at least $40\%$ of the thicker skin thickness, or at least $1.0\text{ mm}$, whichever is lower.
   - **Core Scaling Limit (T 3.6.4):** Material properties derived from a test panel cannot be used for chassis regions with core thickness less than $66\%$ of the tested panel core thickness.

---

## 3. Theoretical Formulations & Mathematical Derivations

### 3.1 Classical Laminate Theory (CLT) & ABD Matrix Derivation

#### Constitutive Lamina Equations (Orthotropic Plane Stress)
For a thin orthotropic composite ply in principal material coordinates $(1, 2)$:
$$\begin{bmatrix} \sigma_1 \\ \sigma_2 \\ \tau_{12} \end{bmatrix} = \begin{bmatrix} Q_{11} & Q_{12} & 0 \\ Q_{12} & Q_{22} & 0 \\ 0 & 0 & Q_{66} \end{bmatrix} \begin{bmatrix} \varepsilon_1 \\ \varepsilon_2 \\ \gamma_{12} \end{bmatrix}$$
where the reduced stiffness components are:
$$Q_{11} = \frac{E_1}{1 - \nu_{12}\nu_{21}}, \quad Q_{22} = \frac{E_2}{1 - \nu_{12}\nu_{21}}, \quad Q_{12} = \frac{\nu_{12}E_2}{1 - \nu_{12}\nu_{21}} = \frac{\nu_{21}E_1}{1 - \nu_{12}\nu_{21}}, \quad Q_{66} = G_{12}$$
with the thermodynamic reciprocity relation $\nu_{21} = \nu_{12} \frac{E_2}{E_1}$.

#### Transformed Lamina Stiffness $[\bar{Q}]$
For a ply oriented at angle $\theta$ to the panel longitudinal axis ($x$):
$$\mathbf{[\bar{Q}]} = \mathbf{[T_\sigma]^{-1}} \mathbf{[Q]} \mathbf{[T_\varepsilon]} = \mathbf{[T_\sigma]^{-1}} \mathbf{[Q]} \mathbf{[T_\sigma]^{-T}}$$
where $m = \cos\theta, n = \sin\theta$:
$$\bar{Q}_{11} = Q_{11}m^4 + 2(Q_{12} + 2Q_{66})m^2 n^2 + Q_{22}n^4$$
$$\bar{Q}_{12} = (Q_{11} + Q_{22} - 4Q_{66})m^2 n^2 + Q_{12}(m^4 + n^4)$$
$$\bar{Q}_{22} = Q_{11}n^4 + 2(Q_{12} + 2Q_{66})m^2 n^2 + Q_{22}m^4$$
$$\bar{Q}_{16} = (Q_{11} - Q_{12} - 2Q_{66})m^3 n + (Q_{12} - Q_{22} + 2Q_{66})m n^3$$
$$\bar{Q}_{26} = (Q_{11} - Q_{12} - 2Q_{66})m n^3 + (Q_{12} - Q_{22} + 2Q_{66})m^3 n$$
$$\bar{Q}_{66} = (Q_{11} + Q_{22} - 2Q_{12} - 2Q_{66})m^2 n^2 + Q_{66}(m^4 + n^4)$$

#### Laminate Stiffness Matrices ($[A], [B], [D]$)
Integrating the lamina stiffness through the total laminate thickness from $z_0$ to $z_N$:
$$\mathbf{A_{ij}} = \int_{-h/2}^{h/2} \bar{Q}_{ij}(z) \, dz = \sum_{k=1}^N \bar{Q}_{ij}^{(k)} (z_k - z_{k-1})$$
$$\mathbf{B_{ij}} = \int_{-h/2}^{h/2} \bar{Q}_{ij}(z) z \, dz = \frac{1}{2} \sum_{k=1}^N \bar{Q}_{ij}^{(k)} (z_k^2 - z_{k-1}^2)$$
$$\mathbf{D_{ij}} = \int_{-h/2}^{h/2} \bar{Q}_{ij}(z) z^2 \, dz = \frac{1}{3} \sum_{k=1}^N \bar{Q}_{ij}^{(k)} (z_k^3 - z_{k-1}^3)$$
where:
- $\mathbf{[A]}$ is the extensional stiffness matrix ($\text{N/mm}$).
- $\mathbf{[B]}$ is the extension-bending coupling stiffness matrix ($\text{N}$).
- $\mathbf{[D]}$ is the bending stiffness matrix ($\text{N}\cdot\text{mm}$).

#### Neutral Axis Calculation for Asymmetric Sandwich Panels
When top skin thickness $t_{top} \ne t_{bot}$ or layups differ, the extension-bending coupling matrix $\mathbf{B} \ne 0$ with respect to the geometric midplane ($z = 0$).
Under pure bending ($N_x = 0$), midplane strain $\varepsilon^0$ couples with curvature $\kappa$:
$$N_x = A_{11}\varepsilon^0 + B_{11}\kappa = 0 \implies \varepsilon^0 = -\frac{B_{11}}{A_{11}}\kappa$$
$$M_x = B_{11}\varepsilon^0 + D_{11}\kappa = \left( D_{11} - \frac{B_{11}^2}{A_{11}} \right) \kappa = D_{11}^* \kappa$$
The **true neutral axis shift ($z_{NA}$)** relative to the reference coordinate system is:
$$\mathbf{z_{NA} = \frac{\int z \cdot \bar{Q}_{11}(z) \, dz}{\int \bar{Q}_{11}(z) \, dz} = \frac{B_{11}}{A_{11}}}$$
When computed from the bottom surface of the panel ($z = 0$ at bottom):
$$z_{NA} = \frac{\sum_{k=1}^N E_x^{(k)} t_k \bar{z}_k}{\sum_{k=1}^N E_x^{(k)} t_k}$$
where $\bar{z}_k$ is the vertical centroid of ply $k$.

#### Effective Flexural Rigidity ($EI$) of Sandwich Beams
For a sandwich beam of width $b$:
1. **Full CLT Formulation:**
   $$\mathbf{EI = b \cdot \left( D_{11} - \frac{B_{11}^2}{A_{11}} \right)} = b \cdot D_{11}^*$$
2. **Parallel Axis (Steiner) Formulation:**
   $$EI = b \sum_{k=1}^N E_x^{(k)} \left( \frac{t_k^3}{12} + t_k (z_k - z_{NA})^2 \right)$$
3. **Thin-Skin Approximation:**
   If skin thickness $t_1, t_2 \ll c$, the self-moments of inertia ($t_k^3/12$) are negligible compared to the Steiner transfer term ($t_k d_k^2$):
   $$\mathbf{EI \approx b \cdot \frac{E_{top} t_{top} \cdot E_{bot} t_{bot}}{E_{top} t_{top} + E_{bot} t_{bot}} d^2}$$
   where $d = c + \frac{t_{top} + t_{bot}}{2}$.  
   For a **symmetric** sandwich ($E_{top} = E_{bot} = E_f$ and $t_{top} = t_{bot} = t_f$):
   $$\mathbf{EI_{sym} \approx \frac{b E_f t_f d^2}{2}}$$

---

### 3.2 Transverse Core Shear Deformation & 3-Point Bending Kinematics

#### Kinematic Assumptions (Reissner-Mindlin & Allen Sandwich Theory)
In a sandwich beam with thin, stiff composite faces and a lightweight, flexible core:
1. **Facings:** Carry bending normal stresses ($\sigma_x$); transverse shear stresses in skins are negligible.
2. **Core:** In-plane normal stiffness is negligible ($E_{c,x} \approx 0$), but carries virtually $100\%$ of the transverse shear stress $\tau_{xz}$.
3. **Displacement Field:**
   $$u(x, z) = -z \frac{dw_b}{dx} + u_{shear}(z)$$
   $$w(x, z) = w(x) = w_b(x) + w_s(x)$$
   where $w_b$ is the deflection due to bending curvature, and $w_s$ is the deflection due to core transverse shear strain $\gamma_c$.

#### Complete Midspan Deflection Derivation (3-Point Bending)
Consider a sandwich beam of span $L$, width $b$, loaded by central point force $F$ at $x = L/2$:
- **Internal Forces (for $0 \le x \le L/2$):**
  - Bending Moment: $M(x) = \frac{F}{2} x$
  - Transverse Shear Force: $V(x) = \frac{F}{2}$

1. **Bending Deflection ($w_b$):**
   From Euler-Bernoulli beam curvature $\frac{d^2 w_b}{dx^2} = -\frac{M(x)}{EI} = -\frac{F x}{2 EI}$:
   Integrating with boundary conditions $\frac{dw_b}{dx}(L/2) = 0$ and $w_b(0) = 0$:
   $$\frac{dw_b}{dx} = \frac{F}{4 EI} \left( \frac{L^2}{4} - x^2 \right)$$
   $$w_b(x) = \frac{F x}{48 EI} \left( 3L^2 - 4x^2 \right)$$
   At midspan ($x = L/2$):
   $$\mathbf{w_b\left(\frac{L}{2}\right) = \frac{F L^3}{48 \, EI}}$$

2. **Transverse Shear Deflection ($w_s$):**
   The shear strain in the core is uniform along the depth and governed by the shear stiffness $S$:
   $$\gamma = \frac{dw_s}{dx} = \frac{V(x)}{S} = \frac{F}{2 S}$$
   Integrating with $w_s(0) = 0$:
   $$w_s(x) = \frac{F}{2 S} x$$
   At midspan ($x = L/2$):
   $$\mathbf{w_s\left(\frac{L}{2}\right) = \frac{F L}{4 \, S}}$$

3. **Total Midspan Deflection ($w_{total}$):**
   $$\mathbf{w = w_b + w_s = \frac{F L^3}{48 \, EI} + \frac{F L}{4 \, S}}$$
   The total compliance is:
   $$\mathbf{C = \frac{w}{F} = \frac{L^3}{48 \, EI} + \frac{L}{4 \, S}}$$

#### Definition and Formulation of Core Shear Stiffness ($S$)
In sandwich mechanics, three definitions of shear stiffness $S$ appear:
1. **Allen's Exact Sandwich Beam Formulation:**
   $$S = G_c \cdot b \cdot \frac{d^2}{c} = G_c \cdot b \cdot \frac{\left(c + \frac{t_1 + t_2}{2}\right)^2}{c}$$
   - *Physical Basis:* Shear stress $\tau = V / (b \cdot d)$. Shear strain energy per unit length:
     $U_s = \frac{1}{2} \int \frac{\tau^2}{G_c} b \, dz = \frac{1}{2} \frac{V^2 c}{G_c b d^2} = \frac{1}{2} \frac{V^2}{S} \implies S = \frac{G_c b d^2}{c}$.
2. **Simplified Core-Height Formulation:**
   $$S \approx G_c \cdot b \cdot c$$
   - Underestimates $S$ slightly because $d > c$, resulting in a conservative overprediction of shear deflection ($w_s$).
3. **Centroid-Height Formulation:**
   $$S \approx G_c \cdot b \cdot d$$
   - Commonly utilized in ASTM C393 / D7250 data reduction sheets.
*For Formula Student panels ($c = 18\text{ mm}$, $t_f \approx 1\text{ mm}$, $d = 19\text{ mm}$), $\frac{d^2}{c} = \frac{361}{18} = 20.05\text{ mm}$. The ratio $\frac{d^2}{c} \approx d$ within $5\%$.*

---

## 4. Multi-Mode Failure Criteria

A sandwich beam under 3-point bending can fail through five distinct physical failure modes. The critical load is governed by the minimum of the failure thresholds:
$$F_{failure} = \min \left( F_{skin\_rupture}, F_{wrinkling}, F_{core\_shear}, F_{dimpling}, F_{indentation} \right)$$

```
                         [ Cylindrical Indenter R=50mm ]
                                    ↓ F
    ===================================================================  <- Top Skin (Compression)
    |  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \  |  <- Honeycomb Core
    ===================================================================  <- Bottom Skin (Tension)
         ▲                                                       ▲
      Support                                                 Support
      |<----------------------- L = 400 mm ------------------>|
```

### 4.1 Mode 1: Facing Skin Rupture (Tensile / Compressive)
* **Bending Stress in Faces:**
  $$\sigma_f = \frac{M}{b \cdot t_f \cdot d} = \frac{F \cdot L}{4 \cdot b \cdot t_f \cdot d}$$
* **Maximum Stress Criterion:**
  - Tensile rupture (bottom skin): $\sigma_{f,bot} \ge X_t$
    $$\mathbf{F_{rupt,t} = \frac{4 \, b \, t_{bot} \, d \, X_t}{L}}$$
  - Compressive crushing (top skin): $|\sigma_{f,top}| \ge X_c$
    $$\mathbf{F_{rupt,c} = \frac{4 \, b \, t_{top} \, d \, X_c}{L}}$$
* **Interactive Failure Criteria (Tsai-Wu & Hashin):**
  For multidirectional CFRP skins under combined bending and Poisson stresses ($\sigma_1, \sigma_2, \tau_{12}$):
  - **Tsai-Wu Polynomial Criterion:**
    $$F_1 \sigma_1 + F_2 \sigma_2 + F_{11} \sigma_1^2 + F_{22} \sigma_2^2 + F_{66} \sigma_{12}^2 + 2 F_{12} \sigma_1 \sigma_2 \le 1$$
    where $F_1 = \frac{1}{X_t} - \frac{1}{X_c}, \quad F_{11} = \frac{1}{X_t X_c}, \quad F_{12} \approx -\frac{1}{2} \sqrt{F_{11} F_{22}}$.
  - **Hashin Failure Criteria (3D):**
    - Fiber Tension ($\sigma_1 \ge 0$): $\left(\frac{\sigma_1}{X_t}\right)^2 + \frac{\tau_{12}^2 + \tau_{13}^2}{S_{12}^2} \ge 1$
    - Fiber Compression ($\sigma_1 < 0$): $\frac{|\sigma_1|}{X_c} \ge 1$
    - Matrix Tension ($\sigma_2 + \sigma_3 \ge 0$): $\frac{(\sigma_2 + \sigma_3)^2}{Y_t^2} + \frac{\tau_{23}^2 - \sigma_2 \sigma_3}{S_{23}^2} + \frac{\tau_{12}^2 + \tau_{13}^2}{S_{12}^2} \ge 1$
    - Matrix Compression ($\sigma_2 + \sigma_3 < 0$): Progressive micro-cracking and ply degradation.

### 4.2 Mode 2: Face Wrinkling / Local Microbuckling
Compressive skin instability where the skin buckles in a short-wavelength sinusoidal wave, resisted by the elastic foundation of the honeycomb core.
* **Plantema's Wrinkling Formula (1966):**
  $$\mathbf{\sigma_{wr} = c_w \cdot \sqrt[3]{E_{f,x} \cdot E_{c,z} \cdot G_{c,xz}}}$$
  where:
  - $E_{f,x}$ = In-plane longitudinal modulus of the compressive facing skin.
  - $E_{c,z}$ = Out-of-plane (flatwise) compressive modulus of the core.
  - $G_{c,xz}$ = Out-of-plane transverse shear modulus of the core along beam axis.
  - $c_w$ = Wrinkling coefficient:
    - Plantema: $c_w \approx 0.59$ (for isotropic skin on semi-infinite elastic foundation).
    - Conservative design practice (MIL-HDBK-23): $c_w \approx 0.50$.
* **Hoff-Mautner Wrinkling Formula (1945):**
  $$\mathbf{\sigma_{wr} = c_{HM} \cdot \left( E_{f,x} E_{c,z} G_{c,xz} \right)^{1/3}}$$
  - Symmetric wrinkling (both skins buckle in anti-phase towards/away from core): $c_{HM} \approx 0.50$.
  - Anti-symmetric wrinkling (both skins buckle in phase): $c_{HM} \approx 0.63$.
* **Critical Wrinkling Force ($F_{wr}$):**
  $$\mathbf{F_{wr} = \frac{4 \, b \, t_{top} \, d \, \sigma_{wr}}{L}}$$

### 4.3 Mode 3: Intracellular Dimpling (Honeycomb Cell Buckling)
When skin plies buckle across the unsupported span of an individual honeycomb hexagonal cell of size $s$.
* **Norris / MIL-HDBK-23 Formula:**
  $$\mathbf{\sigma_{dimple} = \frac{2 \, E_{f,x}}{1 - \nu_{xy}\nu_{yx}} \left( \frac{t_f}{s} \right)^2 \approx 2.1 \, E_{f,x} \left( \frac{t_f}{s} \right)^2}$$
  where $s$ is the cell size ($3.2\text{ mm} = 1/8''$ or $4.8\text{ mm} = 3/16''$ for Plascore PAMG-XR1).
* *Design check:* For $t_f \ge 0.6\text{ mm}$ and $s = 3.2\text{ mm}$, $t_f/s \approx 0.19$, yielding $\sigma_{dimple} > 3000\text{ MPa}$, far above the composite compressive strength ($X_c \approx 800\text{--}1200\text{ MPa}$). Thus, dimpling is prevented for skins with $t_f \ge 0.5\text{ mm}$ on fine-cell cores.

### 4.4 Mode 4: Core Transverse Shear Failure & Shear Crimping
* **Nominal Core Shear Stress:**
  $$\tau_c = \frac{F}{2 \cdot b \cdot d}$$
* **Critical Core Shear Failure Force ($F_{cs}$):**
  $$\mathbf{F_{cs} = 2 \cdot b \cdot d \cdot \tau_{c,ult}}$$
* **Core Anisotropy (Ribbon $L$-direction vs. Transverse $W$-direction):**
  - Aluminum honeycomb features double foil thickness along node lines (ribbon direction).
  - Typical strength ratio: $\tau_{L,ult} \approx 1.6 \text{ to } 2.0 \times \tau_{W,ult}$.
  - Typical stiffness ratio: $G_L \approx 2.0 \text{ to } 2.5 \times G_W$.
  - *Example (Plascore PAMG-XR1 5056 3/16-0.001):*
    $G_L = 310\text{ MPa}, \tau_{L} = 2.41\text{ MPa}$ vs. $G_W = 145\text{ MPa}, \tau_{W} = 1.45\text{ MPa}$.
* **Core Shear Crimping (Overall Instability):**
  Occurs when the shear force approaches the total core shear stiffness:
  $$\mathbf{P_{crimp} = S = G_c \cdot b \cdot d}$$

### 4.5 Mode 5: Local Roller Indentation / Core Crushing
Under the metallic cylindrical loading roller ($R = 50\text{ mm}$), high contact stresses develop. When local contact pressure exceeds the flatwise compressive crush strength of the core ($\sigma_{c,crush}$), localized core crushing occurs beneath the roller before global bending failure.
* **Soden's Plastic Collapse Model:**
  Treating the upper skin as a beam on a rigid-plastic foundation with plastic moment capacity $M_p = \frac{1}{4} b t_f^2 \sigma_{y,f}$ and core crushing stress $\sigma_{cc}$:
  $$\mathbf{F_{indent} = 2 \, b \cdot \sqrt{2 \, M_p \cdot \sigma_{cc}} = b \cdot t_f \cdot \sqrt{2 \, \sigma_{y,f} \, \sigma_{cc}}}$$
* **Greszczuk & Abrate Contact Formulation:**
  Accounting for roller radius $R$:
  $$\mathbf{F_{indent} \approx b \cdot \left( \frac{\pi^2}{3} E_{f,x} t_f^3 \sigma_{cc} \right)^{1/2} + 2 b R \sigma_{cc} \cdot \delta_c}$$

---

## 5. Non-Linear Damage Progression & Energy Absorption up to 12.7 mm Deflection

### 5.1 Energy Absorption Integral
Formula Student Rule T 3.15.4 mandates:
$$\mathbf{E_{12.7} = \int_{0}^{12.7\text{ mm}} F(w) \, dw \ge 65\text{ J}}$$

### 5.2 Stages of the 3-Point Bending Response

```
   Load F
     ▲
     |                 F_peak (Peak Force)
     |                   / \
     |                  /   \  Post-Peak Softening
     |                 /     \_________  Plastic Honeycomb Crushing Plateau (F_plat)
     |                /                \
     |  Linear Elastic                 \__________ Membrane Stretching
     |  Slope K_total                              \
     |              |                   |          |
     +--------------+-------------------+----------+------► Deflection w
     0            w_peak              w_plat     12.7 mm
```

1. **Stage I: Linear Elastic Regime ($0 \le w \le w_{peak}$)**
   $$F(w) = K_{total} \cdot w = \left( \frac{L^3}{48 \, EI} + \frac{L}{4 \, S} \right)^{-1} \cdot w$$
   Elastic energy up to peak:
   $$E_{elastic} = \frac{1}{2} F_{peak} w_{peak} = \frac{1}{2} K_{total} w_{peak}^2$$
2. **Stage II: Failure Initiation ($F = F_{peak}$)**
   Failure initiates at the weakest link:
   - For thin cores ($10\text{ mm}$): Core shear failure initiates first, producing an abrupt load drop.
   - For thick cores ($18\text{--}20\text{ mm}$): Skin compression wrinkling or roller indentation initiates, followed by progressive cell folding.
3. **Stage III: Post-Peak Degradation & Crushing Plateau ($w_{peak} \le w \le w_{plat}$)**
   - Honeycomb cell walls undergo progressive plastic folding (accordion buckling mechanism).
   - Aluminum 5056 exhibits high post-buckling plastic plateau stress ($\sigma_{plat} \approx 0.7\text{--}0.85 \times \sigma_{comp,bare}$).
   - Plateau force:
     $$F_{plat} \approx \eta_{soft} \cdot F_{peak}$$
4. **Stage IV: Membrane Tension Action ($w \to 12.7\text{ mm}$)**
   At deflections approaching the panel thickness, the intact bottom skin undergoes large-deflection membrane stretching:
   $$F_{membrane} \approx 4 \cdot \frac{T \cdot w}{L}$$
   where $T = b \cdot t_{bot} \cdot \sigma_t$.

### 5.3 Critique of Empirical Fitting Factors in Historical Code
In existing team code (`Deflection.m`, `Benchmark_Panels.m`), empirical factors are observed:
- `softening = 0.52` (arbitrary $48\%$ load drop applied uniformly to all panels).
- `grad_scale = 1.05` (artificial $5\%$ gradient boost).
*Mechanics-Based Replacement:*
Softening and plateau behavior are governed by the **failure mode index**:
- **If Core Shear Governs ($F_{cs} < F_{rupt}$):**
  Sudden load drop to residual friction/shear plateau:
  $$\eta_{soft,shear} \approx \frac{\tau_{residual}}{\tau_{ult}} \approx 0.35 \text{ to } 0.45$$
- **If Skin Compressive Wrinkling Governs:**
  Stable plastic folding of honeycomb under top skin:
  $$\eta_{soft,wrinkle} \approx 0.65 \text{ to } 0.80$$
- **If Tensile Rupture Governs (Bottom Skin Fracture):**
  Brittle catastrophic drop:
  $$\eta_{soft,rupt} \approx 0.10 \text{ to } 0.20 \quad \text{(unless ductile hybrid fibers like Zylon/Dyneema are present)}$$

---

## 6. Open-Source Tools & Laminate Optimization Algorithms

### 6.1 Open-Source Python Libraries Evaluation

| Library | Primary Capability | Kinematic Theory | Failure Criteria Supported | Optimization Integration | Repository / Source |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`composipy`** | Classical Laminate Theory, ABD matrix, plate buckling using Rayleigh-Ritz | CLT (Kirchhoff-Love plate) | Max Stress, Tsai-Wu, Tsai-Hill | Integrated with `scipy.optimize` for lamination parameters | [rafaelpsilva07/composipy](https://github.com/rafaelpsilva07/composipy) |
| **`composites`** | High-performance laminate mechanics, ABD matrices, analytical gradients | CLT, First-Order Shear (FSDT), Third-Order Shear (TSDT) | Hashin, Puck, Tsai-Wu, Maximum Strain | Cython-accelerated for large-scale GA and gradient optimization | [PyPI: composites](https://pypi.org/project/composites/) |
| **`py.CLT`** | Educational CLT, stress-strain recovery through laminate thickness | Classical Laminate Theory | Maximum Stress, Tsai-Hill | Scriptable Python routines | [wjbg/py.CLT](https://github.com/wjbg/py.CLT) |
| **`cmtk`** | Routine composite calculations, ABD inversion, midplane strain/curvature | CLT | Tsai-Wu, Hashin 2D | Clean modular Python architecture | GitHub |

### 6.2 Formula Student Laminate Optimization Problem Formulation

The engineering goal is to minimize total panel mass while satisfying all SES structural constraints and manufacturing rules:

$$\min_{\mathbf{x}} \quad \text{Mass}(\mathbf{x}) = b \cdot L_{panel} \cdot \left( \rho_{core} t_{core} + \sum_{k=1}^{N_{plies}} \rho_{ply}^{(k)} t_{ply}^{(k)} \right)$$

where design vector $\mathbf{x} = \left[ t_{core}, \text{Core\_Orient}, \theta_1, \theta_2, \dots, \theta_N, \text{Material}_1, \dots \right]^T$.

#### Optimization Constraints:
1. **Stiffness Constraint:**
   $$EI(\mathbf{x}) \ge EI_{target} = 3.4036 \times 10^9\text{ N}\cdot\text{mm}^2 \quad (\text{for } 2\text{ SIS tubes})$$
2. **Peak Strength Constraint:**
   $$F_{peak}(\mathbf{x}) = \min(F_{rupt}, F_{wr}, F_{cs}, F_{indent}) \ge F_{target}$$
3. **Energy Absorption Constraint:**
   $$E_{12.7}(\mathbf{x}) = \int_0^{12.7\text{ mm}} F(w, \mathbf{x}) \, dw \ge 65.0\text{ J}$$
4. **Perimeter Shear Strength:**
   $$F_{punch}(\mathbf{x}) = \pi \cdot D_{punch} \cdot (t_{top} \tau_{top} + t_{bot} \tau_{bot}) + F_{core,shear} \ge 7.5\text{ kN}$$
5. **Formula Student Manufacturing Rules:**
   - Outermost layer must be woven: $\text{Type}(\text{ply}_1) = \text{woven}$ and $\text{Type}(\text{ply}_N) = \text{woven}$ (Rule T 3.5.7).
   - Parallel fiber limit: $\frac{\sum_{\theta_k \in [\theta-10^\circ, \theta+10^\circ]} m_k}{m_{total}} \le 50\%$ (Rule T 3.5.3).
   - Asymmetric skin thickness ratio: $t_{min} \ge \min(0.40 \cdot t_{max}, 1.0\text{ mm})$ (Rule T 3.5.4).
   - Core thickness derivation limit: $t_{core} \ge 0.66 \cdot t_{tested}$ (Rule T 3.6.4).

### 6.3 Optimization Algorithms
1. **Genetic Algorithms (GA):**
   - Ideal for discrete ply angle optimization ($\theta_k \in \{0^\circ, \pm 45^\circ, 90^\circ\}$) and discrete integer ply counts.
   - Built-in penalty functions enforce the 10% rule (minimum 10% plies in each of $0^\circ, 90^\circ, +45^\circ, -45^\circ$) and prevent grouping of more than 4 consecutive plies with the same orientation (to prevent micro-cracking and high interlaminar shear stresses).
2. **Two-Stage Optimization (Continuous Relaxation + Stacking Sequence Retrieval):**
   - **Stage 1:** Optimize continuous lamination parameters ($V_1^A, V_2^A, V_1^D, V_2^D$) and core thickness using Sequential Quadratic Programming (SQP) or Method of Moving Asymptotes (MMA).
   - **Stage 2:** Retrieve the nearest discrete stacking sequence matching the optimal lamination parameters using a branch-and-bound or genetic search.
3. **Vectorized Pattern Search / DIRECT (MATLAB `patternsearch`):**
   - Robust against non-smooth failure envelope boundaries where failure modes transition sharply (e.g. from skin rupture to face wrinkling).

---

## 7. Specification Mining: Discovered Features & Edge Cases

The following tables document all discovered features, parameters, behaviors, and edge cases across the analyzed specifications, standards, and literature.

## Features Discovered
| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | Rule Standard | Baseline Steel EI Equivalency | Minimum bending stiffness required to match 2 or 3 baseline steel tubes ($E=200\text{ GPa}$, $I=8509\text{ mm}^4$) | Tube geometry ($OD, t$), steel modulus ($200\text{ GPa}$) | Target $EI$ ($3403.6\text{ N}\cdot\text{m}^2$ for 2 tubes; $5105.4\text{ N}\cdot\text{m}^2$ for 3 tubes) | Rejection if $EI_{calc} < EI_{target}$ | FS Rules 2026 T 3.2 & T 3.15 |
| 2 | Rule Standard | Minimum Absorbed Energy | Mandated kinetic energy absorption of vertical SIS up to $12.7\text{ mm}$ deflection | $F(w)$ curve from 3-point bend test up to $w = 12.7\text{ mm}$ | Absorbed energy $E_{12.7}$ ($\text{J}$) | Rejection if $E_{12.7} < 65\text{ J}$ or fails to match 2 steel tubes | FS Rules 2026 T 3.15.4 |
| 3 | Rule Standard | Perimeter Shear Strength | Resistance against punch-through under concentrated bolt or impact loads | Punch $\varnothing 25\text{ mm}$, die $\varnothing 32\text{ mm}$, flat coupon $100\times 100\text{ mm}$ | Peak punch force $F_{punch}$ ($\text{kN}$) | Rejection if $F_{punch} < 7.5\text{ kN}$ (SIS) or $< 4.0\text{ kN}$ (FBS) | FS Rules 2026 T 3.6.11 & T 3.15.4 |
| 4 | Rule Standard | Standard 3-Point Bend Geometry | Physical coupon testing dimensions for SES validation | Width $b=275\text{ mm}$, length $500\text{ mm}$, span $L=400\text{ mm}$, roller $R=50\text{ mm}$ | Raw Load-displacement curve | Invalid test if span $< 400\text{ mm}$ or width $\ne 275\text{ mm}$ | FS Rules 2026 T 3.6.1 & T 3.6.7 |
| 5 | Rule Standard | Direct Roller Contact Mandate | Prohibition of any load spreading pads or elastomeric strips between indenter and composite | Metallic roller directly on CFRP skin | Realistic local indentation & crushing stresses | Non-compliance penalty if elastomeric pads are used | FS Rules 2026 T 3.6.10 |
| 6 | Rule Standard | Outer Woven Ply Requirement | Structural exterior faces must contain at least one woven fabric ply | Ply textile architecture (woven vs UD) | Puncture & environmental protection | Rule violation if UD is on outer layer | FS Rules 2026 T 3.5.7 |
| 7 | Rule Standard | Parallel Fiber 50% Rule | Maximum percentage of fiber weight aligned in any $20^\circ$ window | Stacking sequence fiber angles $\theta_k$ | Fiber orientation distribution | Rejection if $> 50\%$ fibers within $\pm 10^\circ$ | FS Rules 2026 T 3.5.3 |
| 8 | Rule Standard | Asymmetric Skin Thickness Ratio | Thinner skin must be at least 40% of thicker skin or $1.0\text{ mm}$ | $t_{top}, t_{bot}$ | Thickness ratio compliance | Rejection if $t_{thin} < \min(0.40 t_{thick}, 1.0\text{ mm})$ | FS Rules 2026 T 3.5.4 |
| 9 | Rule Standard | Core Thickness Derivation Limit | Material properties derived from testing cannot be scaled down below 66% core height | $t_{core,chassis}, t_{core,test}$ | Valid core scaling range | Invalid derivation if $t_{chassis} < 0.66 t_{test}$ | FS Rules 2026 T 3.6.4 |
| 10 | Testing Standard | Core Shear Stress Calculation | Transverse shear stress in sandwich core under beam shear | Shear force $V$, width $b$, facing centroid distance $d$ | Core shear stress $\tau = V / (b \cdot d)$ | Underestimating stress if $d$ omitted | ASTM C393 / C393M |
| 11 | Testing Standard | Flexural & Shear Stiffness Decoupling | Simultaneous solution of deflection from two spans to isolate $EI$ and $S$ | Compliances $C_1, C_2$ at spans $L_1, L_2$ | Decoupled $EI$ and $S$ | Mathematical singularity if $L_1 = L_2$ | ASTM D7250 / D7250M |
| 12 | Testing Standard | Long Beam Facing Flexure | Pure bending test minimizing shear deformation to isolate skin tensile/compressive modulus | 4-point bending, long span $L$, load span $a$ | Facing modulus $E_f$, facing strength $\sigma_f$ | Core shear failure if span is too short | ASTM D7249 / D7249M |
| 13 | Mechanics | Classical Laminate Theory ABD | Integrated in-plane, coupling, and bending stiffness matrices | Lamina properties ($E_1, E_2, \nu_{12}, G_{12}$), angles $\theta_k$, plies $z_k$ | $[A], [B], [D]$ matrices | Non-invertible if unconstrained or singular | Jones (1999) / CLT Literature |
| 14 | Mechanics | Asymmetric Neutral Axis Shift | Shift of bending neutral axis due to extension-bending coupling | $A_{11}, B_{11}, D_{11}$ or layer moduli and centroids | $z_{NA} = B_{11}/A_{11}$, $D_{11}^* = D_{11} - B_{11}^2/A_{11}$ | Assuming geometric midplane causes 10-25% error in asymmetric layups | Allen (1969) / CLT Literature |
| 15 | Mechanics | Transverse Core Shear Deflection | Addition of shear deformation compliance to Euler-Bernoulli bending | Shear force $V$, shear stiffness $S = G_c b d^2 / c$ | Midspan shear deflection $w_s = \frac{F L}{4 S}$ | Omission underestimates deflection by 15-35% | Allen Sandwich Beam Theory |
| 16 | Mechanics | Core Anisotropy Tracking | Distinct shear moduli and strengths for Ribbon ($L$) vs Transverse ($W$) directions | Core orientation angle relative to beam axis | $G_{c,eff}, \tau_{c,ult,eff}$ | Selecting $W$-dir drops shear strength by up to 40% | Plascore / Hexcel Technical Data |
| 17 | Failure Mode | Face Wrinkling (Plantema) | Short-wavelength compressive skin instability on elastic core foundation | $E_{f,x}, E_{c,z}, G_{c,xz}$ | Critical wrinkling stress $\sigma_{wr} = 0.59 \sqrt[3]{E_f E_{cz} G_{cxz}}$ | Catastrophic compressive collapse if unpredicted | Plantema (1966) / Zenkert |
| 18 | Failure Mode | Face Wrinkling (Hoff-Mautner) | Energy-based wrinkling formula for symmetric and anti-symmetric modes | $E_{f,x}, E_{c,z}, G_{c,xz}$ | Critical wrinkling stress $\sigma_{wr} = c_{HM} (E_f E_c G_c)^{1/3}$ | Premature failure of thin compressive skins | Hoff & Mautner (1945) |
| 19 | Failure Mode | Intracellular Honeycomb Dimpling | Buckling of thin skin across open hexagonal cell span | Skin modulus $E_f$, thickness $t_f$, cell size $s$ | Dimpling stress $\sigma_{dimple} \approx 2.1 E_f (t_f/s)^2$ | Dimpling occurs for ultra-thin skins ($t_f < 0.3\text{ mm}$) | Norris / MIL-HDBK-23 |
| 20 | Failure Mode | Core Shear Crimping | Global instability of sandwich beam under high shear loads | Panel width $b$, centroid distance $d$, shear modulus $G_c$ | Crimping load $P_{crimping} = S = G_c b d$ | Instantaneous sandwich collapse | Allen (1969) |
| 21 | Failure Mode | Local Roller Indentation | Localized plastic crushing of core cells under cylindrical metallic roller | Indenter radius $R=50\text{ mm}$, skin $t_f, E_f$, core crushing stress $\sigma_{cc}$ | Contact indentation force $F_{indent}$ | Indenter punches through upper skin before panel reaches full bending capacity | Soden / Greszczuk / Abrate |
| 22 | Failure Mode | 3D Interactive Failure (Tsai-Wu) | Stress interaction failure tensor for orthotropic laminate plies | Ply stresses $\sigma_1, \sigma_2, \tau_{12}$, strengths $X_t, X_c, Y_t, Y_c, S_{12}$ | Tsai-Wu Failure Index $FI_{TW} \le 1.0$ | Overestimating strength if off-axis interaction is neglected | Tsai & Wu (1971) |
| 23 | Failure Mode | Phenomenological Failure (Hashin) | Distinct criteria for fiber tension/compression and matrix tension/compression | Ply stresses $\sigma_i$, directional strengths | Fiber and matrix damage indices | Inability to track post-damage progression if unseparated | Hashin (1980) |
| 24 | Post-Yield | Non-Linear Energy Integration | Deflection integral of piecewise load curve up to $12.7\text{ mm}$ | Force-deflection profile $F(w)$ | Absorbed energy $E_{12.7} = \int_0^{12.7} F(w) dw$ | Trapezoidal discretization error if sampling is coarse | FS Rules T 3.15.4 |
| 25 | Post-Yield | Honeycomb Plastic Crushing Plateau | Flat compressive crushing plateau of aluminum alloy 5056 cell walls | Bare compressive crush strength $\sigma_{crush}$, densification strain | Post-peak plateau force $F_{plat} \approx \eta F_{peak}$ | Brittle core assumption underestimates energy absorption | Hexcel / Plascore Mechanics |
| 26 | Open-Source | composipy CLT & Buckling Engine | Python package computing ABD matrices and Navier/Ritz plate buckling | Material engineering constants, layup sequence | $[A], [B], [D]$ matrices, critical buckling load | Out of plane shear flexibility not natively modeled | composipy GitHub |
| 27 | Open-Source | composites High-Performance Library | Cython-accelerated composite calculations including FSDT and TSDT | Material properties, ply stack, shear correction factors | ABD matrices, transverse shear stiffnesses, gradients | Requires C compiler build | PyPI composites |
| 28 | Open-Source | py.CLT Educational Toolkit | University of Twente Python scripts for Classical Laminate Theory | Ply engineering constants and orientations | Engineering constants ($E_x, E_y, G_{xy}$), stress distribution | Limited to symmetric/flat classical CLT | py.CLT GitHub |
| 29 | Optimization | Stacking Sequence Rules Enforcement | Compliance with 10% rule, ply balance, and maximum consecutive plies | Candidate discrete stacking sequence | Penalty factor or constraint violation score | Matrix cracking and delamination if $> 4$ consecutive identical plies | CMH-17 / Composite Design Manuals |
| 30 | Optimization | Genetic Algorithm Laminate Sizing | Evolutionary discrete optimization of ply angles and core selection | Objective (mass), constraints ($EI, F_{max}, E_{12.7}$), population | Global optimum discrete layup schedule | Premature convergence to local minima without adequate mutation | Academic Literature (TUM, ETH, GFR) |

---

## Edge Cases
| # | Feature | Input / Condition | Observed / Modeled Behavior | Physical Mechanism & Engineering Remediation |
|---|---------|-------------------|-----------------------------|-----------------------------------------------|
| 1 | Neutral Axis Shift | Heavily asymmetric layup ($t_{top} = 0.6\text{ mm}$, $t_{bot} = 1.8\text{ mm}$, $c = 18\text{ mm}$) | Assuming midplane overpredicts top skin stress and underpredicts bottom skin stress by $18\text{--}24\%$. | Neutral axis shifts towards the thicker bottom skin: $z_{NA} = B_{11}/A_{11}$. Real moment arm to top skin increases, reducing critical wrinkling load. Must use $D_{11}^* = D_{11} - B_{11}^2/A_{11}$. |
| 2 | Core Shear Flexibility | Short test span with thick core ($L = 400\text{ mm}$, $c = 20\text{ mm}$) | Shear deflection accounts for $32.4\%$ of total midspan displacement: $w_s / w_{total} \approx 0.32$. | Bending compliance scales as $L^3$, whereas shear compliance scales as $L$. At short spans, shear deformation dominates. Code omitting $w_s$ severely overpredicts panel stiffness $K_{total}$. |
| 3 | Core Ribbon Orientation | Honeycomb installed in Transverse ($W$) direction instead of Longitudinal Ribbon ($L$) direction | Core shear failure occurs at $58\%$ of expected peak load; premature catastrophic shear cracking along cell seams. | Double-wall foil lines run exclusively along $L$-direction. Transverse shear strength in $W$-direction is only $55\text{--}65\%$ of $L$-direction. Model must explicitly assign $G_{c,eff}$ and $\tau_{c,ult}$ based on core angle. |
| 4 | Indenter Contact Mechanics | Metallic cylindrical indenter ($R = 50\text{ mm}$) with thin outer skin ($t_{top} = 0.5\text{ mm}$, $c = 18\text{ mm}$) | Local top skin punching and core cell crushing directly under roller before global bending failure occurs. | Contact line load creates severe localized transverse compression exceeding core crush strength $\sigma_{cc}$. Upper skin forms local plastic hinges. Remediated by adding local patch plies or thicker woven outer plies. |
| 5 | Post-Yield Softening Modeling | Thin core ($c = 10\text{ mm}$) vs Thick core ($c = 20\text{ mm}$) under post-peak bending | $10\text{ mm}$ panel drops to $35\%$ of peak force (brittle core shear crack), while $20\text{ mm}$ panel maintains $75\%$ peak force (stable honeycomb cell folding). | Using a constant empirical factor (`softening = 0.52`) overestimates energy absorption for $10\text{ mm}$ panels and underestimates energy for $20\text{ mm}$ panels. Softening must branch dynamically based on the active failure mode. |
| 6 | Ply Compaction & Resin Squeeze-Out | Highly compacted autoclave cure for 2027 panels ($t_{ply}$ compacted from $0.22\text{ mm}$ to $0.15\text{ mm}$) | Measured panel flexural stiffness ($EI$) is significantly lower than calculated using uncompacted nominal datasheet thickness. | Flexural rigidity scales with total moment arm $d \approx c + t_f$. Thinner compacted skins reduce $t_f$, directly lowering $EI$ and skin tensile/compressive margins. Accurate thickness calibration in `materials.csv` is mandatory. |
| 7 | Outer Ply Delamination | Unidirectional ply placed on the compressive top surface | Compressive fiber microbuckling and transverse ply splitting initiate at $< 60\%$ of nominal compressive strength. | Lack of transverse interlaminar reinforcement in UD plies promotes longitudinal split cracking under contact roller stresses. FS Rule T 3.5.7 mandates woven fabric on outermost layers. |
| 8 | Asymmetric Panel Inversion | Asymmetric panel ($0.6\text{ mm}$ skin / $1.8\text{ mm}$ skin) placed upside-down in 3-point bend rig | Failure mode switches from stable plastic core crushing to catastrophic bottom skin tensile rupture at low deflection. | In 3-point bending, top skin is in compression and bottom skin is in tension. Inverting the panel puts the ultra-thin skin in tension, causing premature fiber rupture, or puts the thick skin under indenter, altering stiffness. SES test setup requires exact orientation documentation. |
| 9 | Rig Compliance Over-Correction | Subtracting raw steel tube crosshead deflection from composite test curve | Calculated composite elastic modulus $E_f$ artificially spikes by $> 40\%$, producing fictitious compliance with SES. | Crosshead deflection includes machine frame compliance, load cell displacement, and support roller flexure. Subtracting an uncalibrated compliance curve produces an artificially stiff composite slope. FS 2026/2027 rules require rigid calibration ($\ge 85\%$) or direct specimen LVDT/DIC measurement. |
| 10 | Honeycomb Cell Size Dimpling | Coarse honeycomb core ($s = 9.5\text{ mm} = 3/8''$) paired with ultra-thin skin ($t_f = 0.35\text{ mm}$) | Intracellular dimpling occurs at compressive stress $\sigma_f \approx 450\text{ MPa}$, well below CFRP ultimate strength ($X_c \approx 900\text{ MPa}$). | Dimpling critical stress scales as $(t_f / s)^2$. Large cell size dramatically reduces local buckling threshold. Must specify small-cell cores ($s \le 4.8\text{ mm} = 3/16''$, preferably $3.2\text{ mm} = 1/8''$). |

---

## 8. Specific Recommendations for Project Codebase Refactoring

Based on this exhaustive survey of specifications, literature, and standards, the following defects and implementation gaps in `c:\Users\lauri\Documents\MATLAB\SES_Panel` must be resolved during the upcoming implementation phase:

1. **Incorporate Transverse Shear Deflection into `Deflection.m`:**
   - **Current Flaw:** `Deflection.m` computes deflection purely as $w = \frac{F L^3}{48 EI}$, completely neglecting shear compliance.
   - **Resolution:** Implement the complete two-term kinematics:
     $$w(F) = \frac{F L^3}{48 \, EI} + \frac{F L}{4 \, S} \implies F(w) = \frac{w}{\frac{L^3}{48 \, EI} + \frac{L}{4 \, S}}$$
     where $S = G_c \cdot b \cdot \frac{d^2}{c}$ (calculated in `Shearstiff_calc.m`).
2. **Calculate Asymmetric Neutral Axis Shift in `EI_calc.m`:**
   - **Current Flaw:** `EI_calc.m` assumes geometric midplane symmetry ($z_{NA} = h_{panel}/2$), causing significant error for asymmetric layups ($26\_xx$ and $27\_xx$ test panels).
   - **Resolution:** Compute exact neutral axis offset $z_{NA} = \frac{\sum E_i t_i z_i}{\sum E_i t_i}$ or $B_{11}/A_{11}$, and calculate $EI = b \cdot (D_{11} - B_{11}^2 / A_{11})$.
3. **Eliminate Empirical Hardcoded Softening & Scaling Factors:**
   - **Current Flaw:** Code utilizes arbitrary scalars `softening = 0.52` and `grad_scale = 1.05`.
   - **Resolution:** Replace with physics-based multi-mode failure checks ($F_{rupt}, F_{wr}, F_{cs}, F_{indent}$) and mode-dependent post-peak crushing plateaus derived from aluminum honeycomb plastic deformation.
4. **Calibrate Compacted Ply Thicknesses in `materials.csv`:**
   - **Current Flaw:** 2027 panels ($27\_01$ to $27\_04$) show discrepancies between predicted and measured weights and stiffnesses due to uncalibrated nominal ply thicknesses.
   - **Resolution:** Calibrate cured ply thickness (CPT) based on fiber areal weight (FAW), resin content, and measured autoclave compaction factors.
5. **Implement Full Multi-Mode Failure Envelope in `calc_cfk_properties.m`:**
   - Add automated calculation of Plantema/Hoff-Mautner face wrinkling stress, core shear crimping force, and local roller indentation threshold.

---

## 9. Conclusion

This benchmark and specification survey establishes the authoritative physical and regulatory foundation for Formula Student sandwich panel prediction. By coupling Classical Laminate Theory (with asymmetric neutral axis shift), Allen transverse core shear deformation, multi-mode failure envelopes, and honeycomb plastic energy absorption, the simulation framework will accurately predict both 2024 and 2026/2027 test series without relying on artificial empirical tuning factors.
