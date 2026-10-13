# SES Panel Calculation & Optimization Suite – User Guide (v1.0)
**Leitfaden für die Nutzung des Matlabskriptes**  
*Formula Student Monocoque SES Auslegung (Saisons 2026 / 2027) | Version 1.0*

---

## 📑 Inhaltsübersicht des Gesamtdokuments

* [📊 Tabellenverzeichnis](#-tabellenverzeichnis)
* [🔤 Abkürzungsverzeichnis](#-abkürzungsverzeichnis)
* **[1. Erste Schritte, Systemgrenzen & Quick Start](#1-erste-schritte-systemgrenzen--quick-start)**
  * [1.1 Grundverständnis & Systemgrenzen (WICHTIGER HINWEIS)](#11-grundverständnis--systemgrenzen-wichtiger-hinweis)
  * [1.2 Kurzbeschreibung & Systemzweck](#12-kurzbeschreibung--systemzweck)
  * [1.3 Repository klonen mit Sourcetree](#13-repository-klonen-mit-sourcetree)
  * [1.4 Quick Start (In 4 Schritten zur ersten Berechnung)](#14-quick-start-in-4-schritten-zur-ersten-berechnung)
* **[2. Erweiterte Konfiguration & Kalibrierung](#2-erweiterte-konfiguration--kalibrierung)**
  * [2.1 Erweiterte Layup-Syntax & Sonderregeln](#21-erweiterte-layup-syntax--sonderregeln)
  * [2.2 Kalibrierungs- & Fertigungseinstellungen (`Calibration.m`)](#22-kalibrierungs--fertigungseinstellungen-calibrationm)
* **[3. Die Haupt-Workflows](#3-die-haupt-workflows)**
  * [3.1 Workflow 1: Einzelsimulation eines Panels (`Calculate_Single_Panel.m`)](#31-workflow-1-einzelsimulation-eines-panels-calculate_single_panelm)
  * [3.2 Workflow 2: Automatisierte Laminat-Optimierung (`Optimize_Panel.m`)](#32-workflow-2-automatisierte-laminat-optimierung-optimize_panelm)
* **[4. Troubleshooting & Fehlerbehebung](#4-troubleshooting--fehlerbehebung)**
  * [4.1 Syntax- & Eingabefehler im Layup](#41-syntax---eingabefehler-im-layup)
  * [4.2 Materialdaten & RAM-Cache](#42-materialdaten--ram-cache)
  * [4.3 Unplausible Simulationsergebnisse](#43-unplausible-simulationsergebnisse)
  * [4.4 Probleme bei der Laminat-Optimierung](#44-probleme-bei-der-laminat-optimierung)
  * [4.5 Dateisystem, Pfade & PDF-Export](#45-dateisystem-pfade--pdf-export)
* **[5. Sonderfunktionen & Fortgeschrittene Workflows](#5-sonderfunktionen--fortgeschrittene-workflows)**
  * [5.1 Benchmark-Suite zur Modellvalidierung (`Benchmark_Panels.m`)](#51-benchmark-suite-zur-modellvalidierung-benchmark_panelsm)
  * [5.2 Messdaten-Abgleich & Continuous Improvement](#52-messdaten-abgleich--continuous-improvement)
  * [5.3 Fertigungsrichtlinien für den Panelbau](#53-fertigungsrichtlinien-für-den-panelbau)
  * [5.4 Einfluss der Kerndicke & Parameterstudien](#54-einfluss-der-kerndicke--parameterstudien)
* **[6. Referenz: Materialkatalog & FSG-Regeln](#6-referenz-materialkatalog--fsg-regeln)**
  * [6.1 Material-Datenbank & Kennwerte](#61-material-datenbank--kennwerte)
  * [6.2 Laminat-Regeln nach Formula Student (FSG T 3.5)](#62-laminat-regeln-nach-formula-student-fsg-t-35)

---

## 📊 Tabellenverzeichnis

* [Tabelle 1.1: Materialkürzel und Basisfunktionen im Lagenaufbau](#tabelle-11-materialkürzel-und-basisfunktionen-im-lagenaufbau)
* [Tabelle 6.1: Übersicht der hinterlegten Werkstoffdaten in materials.csv](#tabelle-61-übersicht-der-hinterlegten-werkstoffdaten-in-materialscsv)

---

## 🔤 Abkürzungsverzeichnis

Die folgende Übersicht definiert alle im Leitfaden sowie in der Simulations- und Nachweisumgebung verwendeten Fachbegriffe, Regelwerkskürzel und Werkstoffklassen inklusive ihrer Verlinkung zu den maßgeblichen Textstellen:

| Kürzel | Vollständige Bezeichnung / Bedeutung |
| :--- | :--- |
| <a id="abk-astm"></a>**[ASTM](#52-messdaten-abgleich--continuous-improvement)** | American Society for Testing and Materials (Prüfnorm, z. B. ASTM C393 für Sandwich-Biegeversuche) |
| <a id="abk-cfk"></a>**[CFK](#12-kurzbeschreibung--systemzweck)** | Kohlenstofffaserverstärkter Kunststoff (engl. *CFRP*, Carbon Fiber Reinforced Polymer) |
| <a id="abk-clpt"></a>**[CLPT](#11-grundverständnis--systemgrenzen-wichtiger-hinweis)** | Classical Laminated Plate Theory (Klassische Laminattheorie nach Kirchhoff/Mindlin) |
| <a id="abk-cp"></a>**[CP](#53-fertigungsrichtlinien-für-den-panelbau)** | Coupling Film (Struktureller Epoxidharz-Klebefilm zur Wabenkernanbindung, z. B. CP006) |
| <a id="abk-csv"></a>**[CSV](#61-material-datenbank--kennwerte)** | Comma-Separated Values (Dateiformat der Werkstoffdatenbank `materials.csv`) |
| <a id="abk-ei"></a>**[EI](#31-workflow-1-einzelsimulation-eines-panels-calculate_single_panelm)** | Äquivalente Biegesteifigkeit ($E \cdot I$, Produkt aus Biegemodul und Flächenträgheitsmoment) |
| <a id="abk-fsg"></a>**[FSG](#62-laminat-regeln-nach-formula-student-fsg-t-35)** | Formula Student Germany (Internationales Konstruktions- und Sicherheitsregelwerk) |
| <a id="abk-gui"></a>**[GUI](#13-repository-klonen-mit-sourcetree)** | Graphical User Interface (Grafische Benutzeroberfläche, z. B. Atlassian Sourcetree) |
| <a id="abk-hm"></a>**[HM](#61-material-datenbank--kennwerte)** | High Modulus (Hochmodul-Kohlenstofffaser mit hoher Steifigkeit, z. B. M40J) |
| <a id="abk-im"></a>**[IM](#61-material-datenbank--kennwerte)** | Intermediate Modulus (Intermediat-Modul-Faser mit hoher Zugfestigkeit, z. B. T800S) |
| <a id="abk-l"></a>**[L](#22-kalibrierungs--fertigungseinstellungen-calibrationm)** | Ribbon- bzw. Längsrichtung bei Wabenkernen (Richtung höchster Kernschubsteifigkeit) |
| <a id="abk-pbo"></a>**[PBO](#61-material-datenbank--kennwerte)** | Poly(p-phenylen-2,6-benzobisoxazol) (Schlagzähe Hochleistungsfaser Zylon) |
| <a id="abk-pdf"></a>**[PDF](#31-workflow-1-einzelsimulation-eines-panels-calculate_single_panelm)** | Portable Document Format (Druckfertiges Exportformat für Prüf- und Optimierungsberichte) |
| <a id="abk-ram"></a>**[RAM](#42-materialdaten--ram-cache)** | Random-Access Memory (Arbeitsspeicher, vgl. MATLAB-Funktionscache `clear functions`) |
| <a id="abk-ses"></a>**[SES](#12-kurzbeschreibung--systemzweck)** | Structural Equivalency Spreadsheet (Reglement-Nachweisdokument der Monocoque-Sicherheit) |
| <a id="abk-ud"></a>**[UD](#tabelle-11-materialkürzel-und-basisfunktionen-im-lagenaufbau)** | Unidirektional (Fasergelege mit paralleler Faserorientierung zur Hauptlastaufnahme) |
| <a id="abk-uts"></a>**[UTS](#31-workflow-1-einzelsimulation-eines-panels-calculate_single_panelm)** | Ultimate Tensile Strength (Zugfestigkeit bzw. Deckhaut-Bruchspannung im Biegeversuch) |
| <a id="abk-w"></a>**[W](#22-kalibrierungs--fertigungseinstellungen-calibrationm)** | Width- bzw. Querrichtung bei Wabenkernen (senkrecht zur Ribbon-Richtung) |

---

## 1. Erste Schritte, Systemgrenzen & Quick Start

### 1.1 Grundverständnis & Systemgrenzen (WICHTIGER HINWEIS)

> [!CAUTION]
> **Theoretische Simulation vs. Reale Fertigung**  
> Die Berechnungen dieses Tools basieren auf analytischen Modellen (Klassische Laminattheorie und Schubkorrektur nach Reissner-Mindlin/Allen) unter Annahme idealer Materialeigenschaften. Die realen Prüfstandsergebnisse weichen in Abhängigkeit von der **Fertigungsqualität** ab.

* **Einfluss der Fertigungsqualität**: Faktoren wie der effektive Anpressdruck im Heißpress-/Autoklavverfahren (~6 bar), Temperaturzyklen, Faserauslenkung, Porengehalt und Harzaufnahme der offenen Wabenkammern beeinflussen die Steifigkeit und Festigkeit maßgeblich.
* **Erwartete Abweichung**: Eine Abweichung von **ca. 10 %** zwischen Simulation und Prüfstandsergebnis ist bei sorgfältiger, reproduzierbarer Prepreg-Fertigung normal und als Auslegungskorridor zu berücksichtigen.
* **Nichtlinearität der Energieaufnahme ($E_{12.7}$)**: Während der elastische Anstieg (Gradient $c_{3pt}$) sehr präzise vorhergesagt werden kann, unterliegt die Energieberechnung bis zur Normdurchbiegung von $12{,}7\text{ mm}$ größeren Streuungen. Dies liegt am hochgradig nichtlinearen, progressiven Nachbruch- und Faltmechanismus der Wabenkernzellen nach Erreichen der Maximalkraft. Um eine Aussage treffen zu können, ob die Energy passt, wurden Versagensmodi hinzugefügt (Weitere Informationen in der Dokumentation).
* **Verweis auf die Technische Dokumentation**: Detaillierte Hintergrundinformationen zu den Versagensmodi, Nachweisführungen und Auslegungskriterien sind in der separaten [Technischen Dokumentation](../05_Dokumentation/README.md) hinterlegt.

---

### 1.2 Kurzbeschreibung & Systemzweck

Das Tool dient der schnellen, reproduzierbaren Vorauslegung und regelwerkskonformen Nachweisführung von Faserverbund-Sandwichstrukturen (CFK-Deckschichten mit Aluminium-Wabenkern oder Hartschaum) für das Formula Student Monocoque.

Es bildet den genormten **3-Punkt-Biegeversuch** (nach ASTM C393 / D7250) rechnerisch ab und ermittelt die für das **Structural Equivalency Spreadsheet (SES)** geforderten Strukturkennwerte:
1. Äquivalente Biegesteifigkeit ($EI$) des Verbunds
2. Kernschubsteifigkeit ($S$)
3. Elastischer Biegemodul und Steifigkeitsgradient ($c_{3pt}$)
4. Maximale Bruchkraft ($F_{max}$) unter Berücksichtigung konkurrierender Versagensmodi
5. Energieabsorption ($E_{12.7}$) bis $12{,}7\text{ mm}$ Stempelweg

---

### 1.3 Repository klonen mit Sourcetree

Für die Versionsverwaltung und den teamweiten Abgleich wird Atlassian Sourcetree empfohlen:

1. **Repository-URL kopieren**: Kopiere die Git-Klon-URL (HTTPS oder SSH) aus deinem GitLab- oder GitHub-Projekt.
2. **Sourcetree öffnen**: Klicke oben auf die Registerkarte **„Klonen / Neu“** (*Clone*).
3. **Pfade angeben**:
   * **Quellpfad / URL**: Füge die kopierte Git-URL ein.
   * **Zielfeld**: Wähle dein lokales Arbeitsverzeichnis (z. B. `C:\Users\<Benutzer>\Documents\MATLAB\SES_Panel`).
4. **Klonen ausführen**: Klicke auf **„Klonen“**. Sourcetree lädt alle Dateien, Skripte und Materialdatenbanken herunter.
5. **Branch prüfen**: Stelle sicher, dass du auf dem Haupt-Branch (`main` bzw. `master`) arbeitest.

---

### 1.4 Quick Start: In 4 Schritten zur ersten Berechnung

Das gesamte Pfad- und Umgebungsmanagement ist automatisiert. In vier Schritten führst du deine erste Simulation durch:

#### Schritt 1: Projekt in MATLAB initialisieren
Öffne MATLAB und navigiere in das geklonte Projektverzeichnis. Öffne die Projektdatei:
```matlab
open('SES_Panelberechnung.prj');
```
*Hintergrund*: Durch das Öffnen des MATLAB-Projekts werden alle erforderlichen Unterordner (`00_Scripts`, `01_Functions`, `02_Data`) automatisch in den MATLAB-Suchpfad aufgenommen.

#### Schritt 2: Panel & Lagenaufbau prüfen
Öffne die Datei `01_Functions/Scenariodata.m`. Hier ist der zu berechnende Prüfkörper definiert:
```matlab
Scenario.panel.b     = 275;   % mm Panel-Breite
Scenario.panel.l     = 400;   % mm Stützweite
Scenario.panel.w     = 12.7;  % mm Max. Durchbiegung

% Beispiel-Lagenaufbau (Baseline-Panel 26_20)
Scenario.name   = '26_20';
Scenario.core_t = 18;        % 18 mm Wabenkern
Scenario.layup  = '45t7/0m/0m/0m/21m/45t7/cp/18core/cp/45t7/-21m/0m/0m/0m/45t7';
```
Passe bei Bedarf den Namen, die Kerndicke (`core_t`) oder den Layup-String an und speichere die Datei.

Zu beachten ist hier die angegebene Abkürzungskonvention der Material- und Lagen-Tokens:
* **Faserlagen**: Zusammensetzung aus `[Winkel][Kürzel]`, z. B. `45t7` ($+45^\circ$ T700-Gewebe) oder `-21m` ($-21^\circ$ M40J-UD).
* **Wabenkern**: Deklaration über `[Dicke]core`, z. B. `18core` für $18\text{ mm}$ Aluwabe in Ribbon-Richtung (*L-Richtung*). Bei Querausrichtung: `18corew`.
* **Klebefilm**: `cp` deklariert den beidseitig am Kern erforderlichen Harzfilm (CP006).

#### Tabelle 1.1: Materialkürzel und Basisfunktionen im Lagenaufbau

| Kürzel | Materialbezeichnung | Typ | Funktion / Eigenschaften |
| :--- | :--- | :---: | :--- |
| `t7` | T700 Fabric | Gewebe | Zähe Sichtlage ($45^\circ$) & Kernanbindung |
| `m` | M40J UD | UD | Hauptlastaufnahme ($0^\circ, \pm 21^\circ$, Hochmodul) |
| `f` | M40J Fabric | Gewebe | Hochsteife Decklage (Hochmodul-Gewebe) |
| `t8` | T800S UD | UD | Hochfeste Zwischenlagen (IM-Faser) |
| `z` | ZZ300T | Gewebe | Zylon/PBO für maximale Energieaufnahme |
| `a` | SIGAPREG A W173 | Gewebe | Aramid/Kevlar für Durchschlagschutz |
| `cp` | Coupling Film CP006 | Harz | Klebefilm zwischen Kern und Deckhaut |
| `core` | PAMG 5056 Aluwabe | Kern | Wabenkern (z. B. `18core`) |

#### Schritt 3: Simulation starten
Führe das Haupt-Berechnungsskript aus dem Ordner `00_Scripts` aus:
```matlab
Calculate_Single_Panel
```
*(Alternativ: Datei `00_Scripts/Calculate_Single_Panel.m` im MATLAB-Editor öffnen und `F5` drücken).*

#### Schritt 4: Ergebnisse einsehen
Nach Abschluss der Berechnung (Rechenzeit typischerweise $< 0{,}1\text{ Sekunden}$):
1. **Terminal-Report**: Im MATLAB Command Window erscheint eine detaillierte Zusammenfassung aller Steifigkeits-, Festigkeits- und Kennwerte.
2. **Automatischer PDF-Prüfbericht**: Das Skript erzeugt automatisch einen DIN-A4-Prüfbericht und legt diesen mit Zeitstempel im persönlichen **`Downloads`**-Verzeichnis ab:
   ```text
   C:\Users\<Benutzer>\Downloads\SES_Report_Single_Panel_26_20_<Zeitstempel>.pdf
   ```

---

## 2. Erweiterte Konfiguration & Kalibrierung

Nachdem im Quick Start (Abschnitt 1.4) die grundlegende Geometrie und das Erstellen eines Standard-Laminats in `Scenariodata.m` vorgestellt wurden, behandelt dieses Kapitel weiterführende Syntax-Regeln, Sonderfunktionen und die physikalischen Kalibrierungsparameter.

### 2.1 Erweiterte Layup-Syntax & Sonderregeln

Über die Standard-Definition hinaus stehen in `Scenariodata.m` folgende Funktionen und Konventionen zur Verfügung:

1. **Symmetrische Kurzschreibweise (`sym`)**:
   * Ist die Unterseite exakt spiegelsymmetrisch zur Oberseite aufgebaut, kann nach dem Kern das Schlüsselwort `sym` gesetzt werden.
   * Der Parser spiegelt automatisch alle Lagen vor dem Kern spiegelbildlich auf die Unterseite und kehrt dabei die Vorzeichen von Winkellagen automatisch um (z. B. $+21^\circ \to -21^\circ$).

   ```matlab
   % Kompakte symmetrische Notation:
   Scenario.layup = '45t7/0m/21m/cp/18core/sym';

   % Entspricht vollständig aufgelöst:
   % '45t7/0m/21m/cp/18core/cp/-21m/0m/45t7'
   ```

2. **Kernausrichtung L- vs. W-Richtung (`core` vs. `corew`)**:
   * **Standard (`18core`)**: Ribbon- bzw. L-Richtung parallel zur Längsachse ($G_L = 550\text{ MPa}$). Dies ist der Standard für maximale Tragfähigkeit.
   * **Querausrichtung (`18corew`)**: Einbau um $90^\circ$ gedreht (W-Richtung). Der Schubmodul sinkt auf $G_W = 230\text{ MPa}$, was zu spürbar höherer Schubverformung führt.

3. **Vorrichtungsspiel & Setzweg (`panel.slack`)**:
   * In `Scenario.panel.slack = 0.0;` kann ein Setzweg der Prüfaufnahme in $\text{mm}$ hinterlegt werden.
   * Dieser Versatz verschiebt den Kraftanstieg auf der Wegachse und dient dem exakten Abgleich mit Prüfstandskurven, falls bei Prüfbeginn Vorrichtungsspiel vorliegt.

4. **Schichtreihenfolge & Belastungsrichtung**:
   * Die Notation im Layup-String erfolgt strikt von **oben nach unten**:
   * **Vor dem Kern (Oberseite)**: Kontaktzone mit dem Biegestempel $\to$ Druckbeanspruchung im 3-Punkt-Biegeversuch.
   * **Nach dem Kern (Unterseite)**: Auflage auf den Stützrollen $\to$ Zugbeanspruchung.
   * *(Wichtig: Bei asymmetrischen Aufbauten entscheidet diese Orientierung maßgeblich darüber, ob Faserzug- oder Faserdruckversagen die Maximalkraft limitiert.)*

---

### 2.2 Kalibrierungs- & Fertigungseinstellungen (`Calibration.m`)

In der Datei `01_Functions/Calibration.m` sind die zentralen Kalibrierungswerte für Fertigungseinflüsse, Materialkorrekturen und das Versagensmodell hinterlegt.

> [!WARNING]
> **Zentrale Modellparameter**  
> Diese Parameter bilden das physikalische Fundament des gesamten Simulationsmodells.  
> **Änderungen dürfen nur mit triftigem Grund vorgenommen werden**, da sie direkte Auswirkungen auf alle Berechnungsergebnisse und die Validierung gegen Prüfstandsergebnisse haben!

```matlab
% Auszug aus 01_Functions/Calibration.m:
Calib.thickness_factor    = 0.95;   % Bauteildicke nach Aushärtung (95% Nenndicke, erhöht E-Modul um 1/0.95)
Calib.core_dir            = 'L';    % Wabenkern-Richtung ('L' = Ribbon, 'W' = Quer)
Calib.include_core_shear  = true;   % Kernschubverzerrung nach ASTM C393 Dreipunktbiegung (Timoshenko)
Calib.fixture_stiffness   = 22218;  % [N/mm] Exakte SES Rig Compliance aus Steel-Tube-Kalibrierversuch
Calib.post_fail_factor    = 0.250;  % Restkraftplateau nach Peak (F_post = F_max * factor)
Calib.failure_criterion   = 'hashin';% 'hashin' oder 'fixed_strain'
Calib.softening_factor    = 0.95;   % Sekanten-Softeningfaktor vor Peak
Calib.indentation_depth   = 0.15;   % Lokale Rolleneindrückung [mm]
Calib.energy_mode         = 'to_peak';% Energieberechnung ('to_peak' oder 'ses_total')
```

#### Parameter im Detail für begründete Anpassungen:

* **Kompaktierungsfaktor (`thickness_factor`)**: Berücksichtigt die reale Kompaktierung des Prepregs unter Druck im Heißpressverfahren ($\approx 6\text{ bar}$). Ein Wert von $0{,}95$ bedeutet, dass das ausgehärtete Laminat $95\text{ \%}$ der theoretischen Nenndicke erreicht. Durch die Verringerung der Schichtdicke bei gleichbleibender Fasermasse steigt der wirksame E-Modul physikalisch um $1 / 0{,}95$.
* **Prüfstands- & Vorrichtungssteifigkeit (Rig Compliance) (`fixture_stiffness`)**: Reale Prüfmaschinen (z. B. Zwick/Roell) und Vorrichtungsaufnahmen verformen sich unter Prüfkraft elastisch. Im Berechnungsmodell wird diese Nachgiebigkeit über eine Reihenschaltung der Federsteifigkeiten als „virtueller Prüfstand“ abgebildet:
  $$
  \frac{1}{K_{\text{ges}}} = \frac{1}{K_{\text{Biegung}}} + \frac{1}{K_{\text{Schub}}} + \frac{1}{K_{\text{rig}}} = \frac{L^3}{48 \, EI} + \frac{L}{4 \, S} + \frac{1}{K_{\text{rig}}}
  $$
  Der Wert $K_{\text{rig}} = 22\,218\text{ N/mm}$ stammt direkt aus dem offiziellen Formula Student SES Baseline Steel Tube Test (T3.2) mit zwei kalibrierten Stahlrohren auf $400\text{ mm}$ Stützweite. Dadurch bleiben alle Messdaten in der Excel-Tabelle $100\,\%$ unverfälschte Rohdaten, während die Simulation die reale Maschinenelastizität physikalisch exakt einrechnet.
* **Kernschubanteil nach Timoshenko (`include_core_shear`)**: Berücksichtigt neben der reinen Deckhautbiegung ($L^3 / (48 EI)$) die transversale Kernschubverzerrung nach ASTM C393 ($L / (4 S)$). Bei Sandwichplatten mit Wabenkern kann der Schubanteil je nach Kerndicke und Faseraufbau $15\,\%$ bis $30\,\%$ der elastischen Gesamtdurchbiegung ausmachen.
* **Kernausrichtung (`core_dir`)**: Hauptausrichtung des Wabenkerns.
  * `'L'`: Längs-/Ribbon-Richtung ($G_{core} = 550\text{ MPa}$) für maximale Tragfähigkeit in Längsrichtung.
  * `'W'`: Querrichtung ($G_{core} = 230\text{ MPa}$). Führt zu deutlich höherer Schubverformung und geringerem Steifigkeitsgradienten.
* **Versagenskriterium (`failure_criterion`)**: Bruchhypothese für die Deckschichten.
  * `'hashin'`: Differenziert zwischen Faserzug, Faserdruck, Matrixzug und Matrixdruck unter Spannungsinteraktion.
  * `'fixed_strain'`: Einfacher Dehnungsnachweis bei Erreichen einer vorgegebenen Grenzdehnung.
* **Nachbruchfaktor (`post_fail_factor`)**: Definiert das Restkraft-Niveau nach dem ersten Versagens-Peak ($F_{post} = F_{max} \cdot \text{factor}$). Dieser Wert wurde experimentell über alle Prüfstandsdaten der Saisons 2024–2027 kalibriert ($0{,}250 = 25\,\%$ Resttragfähigkeit).
* **Energiemodus (`energy_mode`)**: Definiert das Integrationsintervall für die absorbierte Verformungsenergie:
  * `'to_peak'`: Berechnet die Energieaufnahme bis zum ersten Faserbruch bei $F_{max}$. Wird genutzt, um die Berechnung 1:1 mit den realen Prüfstands-Messwerten aus `02_Data/Pruefstand_Rohdaten_Benchmark.xlsx` zu vergleichen.
  * `'ses_total'`: Vollständige Energieintegration über den gesamten Weg von $0$ bis $12{,}7\text{ mm}$ (inklusive Wabenstauchung nach dem Bruch). Wird für den offiziellen Formula Student SES-Nachweis zwingend gefordert.

---

## 3. Die Haupt-Workflows

Das Tool bietet zwei primäre Arbeitsabläufe für die Monocoque-Auslegung: die schnelle Einzelsimulation eines Prüfkörpers und die automatisierte Optimierung zur Gewichtsminimierung unter Einhaltung aller SES- und FSG-Vorgaben.

### 3.1 Workflow 1: Einzelsimulation eines Panels (`Calculate_Single_Panel.m`)

Dieser Workflow dient der schnellen Berechnung und Überprüfung eines fest definierten Laminataufbaus (z. B. zur Vorbereitung eines physischen 3-Punkt-Biegeversuchs oder zur finalen Kennwertermittlung für das SES-Formular).

#### Ablauf & Durchführung
1. **Eingaben prüfen**: In der Datei `01_Functions/Scenariodata.m` Geometrie und Lagenaufbau festlegen und speichern.
2. **Skript starten**: Die Datei `00_Scripts/Calculate_Single_Panel.m` im MATLAB-Editor öffnen und mit `F5` (oder Klick auf **Run**) ausführen.

#### Auswertung des Terminal-Reports
Die Berechnung wird in wenigen Millisekunden abgeschlossen. Im MATLAB Command Window wird ein detaillierter, in fünf Abschnitte gegliederter Prüfbericht ausgegeben:

* **Geometrie**: Dicken der oberen und unteren Deckhaut, Kerndicke mit Orientierung (Ribbon `'L'` oder Quer `'W'`) sowie die Gesamtsandwichdicke.
* **Gewicht & Flächenmasse**: Gesamtmasse des $400 \times 275\text{ mm}$ Prüfkörpers in Gramm, gesamtes Flächengewicht in $\text{g/m}^2$ sowie die prozentualen Massenanteile der CFK-Deckhäute, des Wabenkerns und des Klebefilms (`cp`).
* **Steifigkeit (Stiffness)**: Elastizitätsmodul der Deckschichten ($E$), äquivalente Biegesteifigkeit ($EI$), axiales Flächenträgheitsmoment ($I$) und der maßgebliche SES-Prüfstandsgradient in $\text{N/mm}$.
* **Festigkeit & Versagen (Strength & Failure)**: Deckhaut-Bruchspannung ($UTS$), Maximalkraft ($F_{max}$), Versagensweg bei Maximalkraft ($w_{max}$) sowie der identifizierte primäre Versagensmodus.  
  *Wichtiger Hinweis zur Modellgenauigkeit*: Je nach auftretendem Versagensmodus unterscheidet sich die Linearität der Kraft-Weg-Kennlinie maßgeblich, wodurch die berechnete Energieaufnahme mehr oder weniger vertrauenswürdig ist:
  * *Deckhautbruch (UTS)*: Faserzug- oder Faserdruckversagen der Deckschichten. Durch das überwiegend linear-elastische Verhalten der Fasern bis zum Bruchpunkt weist die Energieberechnung hier die **höchste Linearität und Vertrauenswürdigkeit** auf.
  * *Kernschubbruch (Core Shear)*: Schubversagen der Aluminiumwaben bei hoher Querkraft. Plastische Verformungen der Zellwände vor dem Peak mindern die Linearität, wodurch die berechnete Energie moderaten Streuungen unterliegt.
  * *Deckhautknicken (Wrinkling)*: Lokales Stabilitätsversagen (Beulen) der Deckhaut über den Wabenkammern. Dieses plötzliche, geometrisch nichtlineare Versagen reagiert extrem sensibel auf Fertigungseinflüsse, weshalb der Energieberechnung hier **am wenigsten vertraut** werden kann.
* **Energieaufnahme (Energy Absorption)**: Absorbierte Verformungsenergie in Joule ($J$) im gewählten Modus (`'to_peak'` für den direkten Prüfstandsabgleich oder `'ses_total'` für den SES-Regelwerksnachweis).

#### Automatischer PDF-Prüfbericht
Das Skript erzeugt automatisch einen DIN-A4-Prüfbericht und legt diesen mit Zeitstempel im persönlichen **`Downloads`**-Verzeichnis ab:
```text
Downloads/SES_Report_Single_Panel_<Szenarioname>_<Zeitstempel>.pdf
```
Der Bericht fasst alle Kennwerte übersichtlich zusammen und eignet sich direkt zur Dokumentation für das SES-Submissionspaket oder die technische Abnahme (Scrutineering).

---

### 3.2 Workflow 2: Automatisierte Laminat-Optimierung (`Optimize_Panel.m`)

Das Skript `00_Scripts/Optimize_Panel.m` führt eine mehrkriterielle Optimierung durch. Ziel ist es, aus allen regelkonformen Kombinationen von Fasermaterialien, Lagenanzahlen und Orientierungswinkeln das leichteste Sandwich-Laminat zu ermitteln, das alle geforderten Strukturkennwerte erfüllt.

#### Zielwerte definieren (`Targets`)
Die Mindestanforderungen an das optimierte Panel werden direkt im Konfigurationsabschnitt von `Optimize_Panel.m` hinterlegt:

```matlab
Targets = struct();
Targets.safety_factor = 1.0;    % Sicherheitsfaktor auf Zielwerte (z.B. 1.0 = keine Reserve, 1.1 = +10%)
Targets.Gradient      = 3000;   % Mindest-Gradient [N/mm]
Targets.Energy        = 60;     % Mindest-Energieaufnahme [J]
Targets.EI            = 0;      % Mindest-Biegesteifigkeit [N*mm^2]
Targets.UTS           = 0;      % Mindest-Deckhautfestigkeit [MPa]
Targets.E             = 0;      % Mindest-E-Modul Deckhaut [GPa]
Targets.F_max         = 0;      % Mindest-Bruchkraft [N]
Targets.t_skin_max    = 0;      % Max. Deckhautdicke [mm]
```

* **Sicherheitsfaktor (`safety_factor`)**: Skaliert alle aktivierten Mindest-Targets intern mit diesem Faktor (z. B. $1{,}10$ für $10\,\%$ Reserve: $3000\text{ N/mm} \cdot 1{,}10 = 3300\text{ N/mm}$).
* **Inaktiv-Schalter (`0`)**: Jeder Zielwert mit dem Wert `0` wird vom Optimierungsalgorithmus ignoriert und stellt keine Restriktion dar.

#### Fertigungs- & Regelwerksgrenzen (`OptSettings`)
Zur Einhaltung von Fertigungsstandards und FSG-Vorgaben stehen folgende Optionen zur Verfügung:

```matlab
OptSettings.min_plies             = 4;           % Mindestanzahl Lagen je Deckhaut
OptSettings.max_plies             = 8;           % Maximalanzahl Lagen je Deckhaut
OptSettings.angle_mode            = 'simple';    % 'simple' ([0, +/-21]) oder 'advanced'
OptSettings.material_pool         = 'all';       % 'all' oder 'standard'
OptSettings.sichtlage_active      = true;        % FSG-Sichtlage zwingend aktiv
OptSettings.sichtlage_material    = {'t7', 'f'}; % Erlaubte Sichtlagengewebe
OptSettings.sichtlage_angle       = 45;          % Sichtlagenwinkel in Grad
OptSettings.core_interface_fabric = true;        % Gewebelage zur Kernanbindung
```

* **Lagenbegrenzung (`min_plies` / `max_plies`)**: Definiert den Suchbereich für die Einzellagen pro Deckhaut (Standard: 4 bis 8 Lagen).
* **Winkelmodus (`angle_mode`)**: `'simple'` nutzt die bewährten Standardwinkel ($0^\circ, \pm 21^\circ$); `'advanced'` erweitert den Suchraum um $\pm 30^\circ, \pm 45^\circ, \pm 60^\circ$.
* **Sichtlage (`sichtlage_active`)**: Garantiert die Einhaltung der FSG-Regel T 3.5.7 (äußerste Lage muss zwingend einlagiges Gewebe sein, Standard: $+45^\circ$ `t7` oder `f`).
* **Kernanbindung (`core_interface_fabric`)**: Erzwingt eine Gewebelage direkt am Wabenkern, um Delaminationsrisiken vorzubeugen.

#### Auswertung der Optimierungsergebnisse
Nach Ausführung von `Optimize_Panel.m` werden vier Ergebnisformate bereitgestellt:
1. **Vorher/Nachher-Vergleich im Terminal**: Direkte Gegenüberstellung der Baseline (aus `Scenariodata.m`) gegen das Optimum mit genauer Massenersparnis in Gramm und Prozent.
2. **TOP-5 Rangliste**: Auflistung der 5 leichtesten regelkonformen Laminate inklusive Halbschalen-Layup-String zur direkten Übernahme.
3. **Kraft-Weg-Vergleichsplot**: Visuelle Gegenüberstellung der Arbeitskurven von Baseline (Rot) und Optimum (Grün) mit Markierung von $F_{max}$ und der geforderten Gradienten-Grenzlinie.
4. **PDF-Optimierungsbericht**: Automatischer Export der gesamten Zusammenfassung als PDF in den **`Downloads`**-Ordner.

---

## 4. Troubleshooting & Fehlerbehebung

Dieses Kapitel bietet schnelle Hilfe bei typischen Eingabefehlern, Fehlermeldungen in MATLAB und unplausiblen Berechnungsergebnissen.

### 4.1 Syntax- & Eingabefehler im Layup

Der Parser (`parse_layup.m`) zerlegt den Lagenaufbau-String entlang der Trennzeichen `'/'`. Weicht die Syntax von der Konvention ab, reagiert das System mit Fehlermeldungen oder unerwarteten Modellen:

* **Unbekanntes Materialkürzel**:
  ```text
  Error: Material xyz nicht in materials.csv gefunden.
  ```
  *Ursache*: Ein Token wurde falsch getippt oder die Reihenfolge von Winkel und Material wurde vertauscht (z. B. `m0` statt `0m` oder `f45` statt `45f`). Der Parser erwartet immer zuerst den Winkel (inkl. Vorzeichen), direkt gefolgt vom Kürzel.
* **Falsche Vorzeichenplatzierung**:
  Ein Token wie `45-m` wird als Winkel $45^\circ$ und Material `'-m'` interpretiert. Das Vorzeichen muss zwingend ganz vorne stehen (z. B. `-45m` oder `-21m`).
* **Vergessener Kern-Token (`core`)**:
  Wird kein Kern (z. B. `18core`) angegeben, interpretiert das Tool den Aufbau als monolithisches Voll-CFK-Laminat ohne Sandwich-Kern. Die Kernhöhe wird zu `NaN` gesetzt und die Kernschubberechnung entfällt.
* **Fehlender Klebefilm (`cp`)**:
  Wird `cp` vor und nach dem Kern weggelassen, bricht die Simulation zwar nicht ab, aber die berechnete Panelmasse ist ca. $100\text{ g/m}^2$ pro Deckhaut zu niedrig. Für regelkonforme SES-Berechnungen ist der Klebefilm beidseitig Pflicht.
* **Fehlerhafte Symmetrie-Syntax (`sym`)**:
  Der Token `sym` darf ausschließlich als letztes Element nach dem Kern stehen (z. B. `.../18core/cp/sym`). Werden nach `sym` weitere Lagen notiert, wird das Schlüsselwort als Material-Token fehlinterpretiert.

---

### 4.2 Materialdaten & Datenbankprobleme

Die Materialwerte werden zentral über die Datei `02_Data/materials.csv` verwaltet. Beim Bearbeiten oder Hinzufügen von Datensätzen sind folgende Punkte zu beachten:

* **Werteänderung in CSV wird in MATLAB nicht übernommen**:
  Die Funktion `load_materials.m` nutzt aus Performancegründen einen internen RAM-Cache (Singleton-Muster). Wird die CSV-Datei extern in Excel oder einem Editor geändert, greift MATLAB weiterhin auf die im Speicher liegenden Altwerte zu.  
  *Lösung*: Vor einem erneuten Rechenlauf den Speicher über das Command Window leeren:
  ```matlab
  clear functions; % Leert den persistenten Material-Cache
  ```
  Alternativ kann das Neuladen mit `load_materials([], true)` erzwungen werden.
* **Falsches CSV-Trennzeichen**:
  Die Datei `materials.csv` muss zwingend mit Semikolon (`;`) als Spaltentrennzeichen gespeichert werden. Werden Kommata oder Tabulatoren verwendet, schlägt das Einlesen fehl (`detectImportOptions`).
* **Fehlende Festigkeitskennwerte in CSV**:
  Sind Kennwerte wie $X_t, X_c, Y_t, Y_c$ oder $S_{12}$ in der CSV-Tabelle leer oder $\le 0$, setzt der Parser automatisch einen Schutzwert von $10^6\text{ MPa}$. In diesem Fall meldet das Tool keinen Faserbruch für diese Lage.

---

### 4.3 Unplausible Simulationsergebnisse

Weichen die Ergebnisse drastisch von Erfahrungswerten oder Prüfstandsdaten ab, liegt meist eine Fehleinstellung in den Parametern vor:

* **Biegesteifigkeit oder Gradient deutlich zu niedrig**:
  * *Kernorientierung*: Steht der Kern auf Querausrichtung (`'W'`), halbiert sich der Schubmodul von $550\text{ MPa}$ auf $230\text{ MPa}$. Dadurch wachsen die Schubverformungen massiv an.
  * *Kompaktierung*: Wurde `thickness_factor` in `Calibration.m` versehentlich verstellt? Der Standardwert liegt bei $0{,}95$.
* **Kraft-Weg-Kurve ist horizontal verschoben**:
  Liegt die simulierte Kurve parallel versetzt zur realen Prüfstandskurve, ist in `Scenariodata.m` ein Vorrichtungsspiel eingetragen (`Scenario.panel.slack`). Für theoretische Panel-Auslegungen gehört der Wert auf $0{,}0\text{ mm}$.
* **Berechnete Energie passt nicht zum Prüfstandsversuch**:
  * *Energiemodus prüfen*: In `Calibration.m` prüfen, ob `'to_peak'` (Abgleich bis $F_{max}$) oder `'ses_total'` ($0$ bis $12{,}7\text{ mm}$ inkl. Restplateau) aktiv ist.
  * *Versagensmodus beachten*: Tritt Deckhautknicken (Wrinkling) auf, ist der Realversuch stark von geometrischen Fertigungsungenauigkeiten geprägt. Die theoretische Energieberechnung besitzt hier konstruktionsbedingt die größte Unsicherheit.

---

### 4.4 Probleme bei der Laminat-Optimierung

Beim Ausführen des Skripts `00_Scripts/Optimize_Panel.m` können folgende Konstellationen auftreten:

* **Meldung: `KEINE zulässige Lösung gefunden, die alle Targets erfüllt!`**:
  * *Sicherheitsfaktor zu hoch*: Bei aktivem Sicherheitsfaktor (z. B. `safety_factor = 1.25`) steigen die Anforderungen um $25\,\%$.
  * *Lagenfenster zu eng*: Wenn `max_plies = 6` gewählt ist, der geforderte Gradient aber mindestens 8 Lagen verlangt, existiert im gewählten Suchraum keine physikalisch machbare Lösung. `max_plies` schrittweise anheben.
  * *Widersprüchliche Randbedingungen*: Ein hoher Gradient in Kombination mit einer extrem strengen Dickenbegrenzung (`t_skin_max`) schließt alle tragfähigen Laminate aus.
* **Lange Rechenzeit bei der Optimierung**:
  Steht `angle_mode` auf `'advanced'`, untersucht der Algorithmus sämtliche Winkelkombinationen aus $[21^\circ, 30^\circ, 45^\circ, 60^\circ]$. Dadurch wächst die Anzahl der Kandidaten exponentiell an. Für schnelle Iterationen immer `'simple'` nutzen.

---

### 4.5 Dateisystem, Pfade & PDF-Export

* **`Unrecognized function or variable`**:
  MATLAB findet die Funktionen nicht.  
  *Lösung*: Vor Arbeitsbeginn immer die Projektdatei `SES_Panelberechnung.prj` im Hauptverzeichnis doppelklicken. Dadurch werden alle Unterordner (`00_Scripts`, `01_Functions`, `02_Data`) automatisch dem MATLAB-Suchpfad hinzugefügt.
* **PDF-Export schlägt fehl oder Datei wird nicht aktualisiert**:
  Die Funktion `export_pdf_report.m` speichert Berichte standardmäßig im Ordner `Downloads`. Ist ein bereits erzeugter PDF-Bericht in einem externen PDF-Viewer (z. B. Adobe Acrobat) geöffnet, sperrt Windows die Datei gegen Überschreiben.  
  *Lösung*: PDF-Viewer schließen oder das Dokument im Viewer freigeben.

---

## 5. Sonderfunktionen & Fortgeschrittene Workflows

Dieses Kapitel behandelt erweiterte Werkzeuge zur empirischen Modellvalidierung, den kontinuierlichen Datenabgleich mit Prüfstandsversuchen sowie fundamentale Fertigungsrichtlinien für den physischen Bau von SES-Testpanels.

### 5.1 Benchmark-Suite zur Modellvalidierung (`Benchmark_Panels.m`)

Das Skript `Benchmark_Panels.m` (bzw. die Kernfunktion `run_benchmark.m`) dient der kontinuierlichen Überprüfung der Modellgüte. Es führt einen vollautomatisierten Abgleich zwischen den theoretischen Simulationsergebnissen und den realen Messwerten aller gefertigten Formula-Student-Panels durch.

#### Architektur & Live-Rohdatenauswertung
Im Gegensatz zu statischen Tabellenwerten arbeitet die Benchmark-Suite direkt auf den realen Prüfmaschinen-Messdaten:
* **Single Source of Truth**: Sämtliche Panel-Definitionen und Kraft-Weg-Messkurven werden zentral in der Datei `02_Data/Pruefstand_Rohdaten_Benchmark.xlsx` gepflegt.
* **Automatisierte Messkurven-Analyse**: Die Funktion `evaluate_test_curve.m` liest die Rohdaten (`Traversenweg_mm` und `Kraft_N`) für jedes Panel ein. Sie bereinigt Vorlast- und Setzeffekte automatisch, ermittelt die Maximalkraft $F_{\max}$, berechnet über eine lineare Regression (im Bereich $15\,\%$ bis $45\,\% \, F_{\max}$) den realen Steifigkeitsgradienten $c_{3pt}$ und integriert die absorbierte Energie exakt bis zum [SES](#abk-ses)-Normstempelweg von $12{,}70\text{ mm}$.
* **Identische Berechnungskette**: Für jedes Panel ruft das Benchmark-Tool exakt die modulare Standard-Simulationskette des Projekts auf (`Scenariodata`, `Calibration`, `Materialdata`, `EI_calc`, `Shearstiff_calc`, `Deflection`, `Energy_calc`). Es finden keinerlei isolierte Sonderberechnungen statt.
* **Duale Deckhautdicken-Erfassung für asymmetrische Panels**: Um asymmetrische Monocoque-Panels (z. B. unterschiedliche Lagendicken auf Druck- und Zugseite gemäß [FSG](#abk-fsg) T 3.5.4) exakt abzugleichen, erfasst der Benchmark getrennte Messwerte für Obergurt und Untergurt (`Deckhautdicke_oben_mm` und `Deckhautdicke_unten_mm`). Die Suite vergleicht beide Seiten individuell mit der Laminattheorie und schaltet die Tabellenausgabe bei asymmetrischen Aufbauten automatisch in die getrennte Darstellung `oben / unten`.
* **In-Memory Caching**: Um wiederholte Auswertungen in Sekundenbruchteilen ($< 0{,}05\text{ s}$) durchzuführen, werden die berechneten Prüfstandskennwerte persistent im Arbeitsspeicher ([RAM](#abk-ram)) vorgehalten. Über den Befehl `run_benchmark('reload')` kann das Neulesen der Excel-Datei jederzeit erzwungen werden.

#### Aktiver Datenbestand (28 Panels)
Der Benchmark filtert und validiert aktuell 28 aussagekräftige Fertigungspanels aus drei Saisons:
* **Saison 2024 (17 Panels)**: Fertigungspanels `24_02` bis `24_18` (ohne die irregulären Proben `24_19` und `24_20`).
* **Saison 2026 (7 Panels)**: Aktuelle Monocoque-Panels `26_12` bis `26_21` (unter Ausschluss von Frühausfällen durch Fertigungsfehler wie Delamination bei `26_17` und Sonderwerkstoffen bei `26_19`).
* **Saison 2027 (4 Panels)**: Neueste Prüfpanels `27_01` bis `27_04` inklusive der Panels mit $20\text{ mm}$ Wabenkern.

#### Prioritäre Zielgrößen & Korrelationsgüte
Für das Monocoque-Chassis-Team und die offizielle Nachweisführung im [SES](#abk-ses) sind zwei Kennwerte von überragender Bedeutung:
1. **Steifigkeitsgradient ($\text{Gradient}$ in $\text{N/mm}$)**: Maßgeblich für die Einhaltung der Mindeststeifigkeit des Cockpits und der Seitenwände.
2. **Energieaufnahme ($\text{Energy}$ in $\text{J}$)**: Maßgeblich für den Nachweis der Crash- und Verformungsenergie bis $12{,}7\text{ mm}$.

Zusätzlich dient der Dickenabgleich der Fertigungskontrolle: Bei symmetrischen Aufbauten erfolgt der Vergleich kompakt einzeilig ($t_{\text{test}}$ vs. $t_{\text{calc}}$), während bei asymmetrischen Panels beide Deckhäute getrennt als $t_{\text{top}}/t_{\text{bot}}$ mit individuellen prozentualen Abweichungen ausgewiesen werden (z. B. `0.65/0.65` vs. `0.84/0.64 mm`). Die Benchmark-Statistik dokumentiert dies als `MAE Dicke (o/u)`.

Dank der physikalischen Reihenschaltung von Plattenbiegung, Wabenkern-Schubverzerrung nach [ASTM](#abk-astm) C393 und der realen Prüfstands-Compliance ($K_{\text{rig}} = 22\,218\text{ N/mm}$ aus dem offiziellen SES Baseline Steel Tube Test T3.2) liegt die mittlere absolute Abweichung (MAE) über alle 28 Panels bei ca. $12{,}7\,\%$ für den Gradienten und unter $10\,\%$ bei den aktuellen 2026er Monocoque-Panels.

Nach jedem Gesamtlauf erzeugt das Skript automatisch einen druckfertigen DIN-A4-Prüfbericht im [PDF](#abk-pdf)-Format im Ordner **`Downloads`**:
```text
Downloads/SES_Report_Benchmark_Validation_<Zeitstempel>.pdf
```

---

### 5.2 Messdaten-Abgleich & Continuous Improvement

Das Berechnungsmodell ist kein statisches Tool, sondern ein lernendes System, das kontinuierlich an realen Biegeversuchen geschärft wird.

> [!IMPORTANT]
> **Wichtiger Leitsatz: Pflicht zur lückenlosen Panel-Aufnahme**  
> **Jedes neu gefertigte und im 3-Punkt-Biegeversuch geprüfte SES-Panel MUSS zwingend und unverzüglich in die Benchmark-Datenbasis aufgenommen werden!**  
> 
> Das Unterlassen oder selektive Auslassen von Prüfkörpern verfälscht die empirische Vertrauensbasis des gesamten Monocoques. Nur durch eine lückenlose Erfassung aller realen Tests ist gewährleistet, dass:
> 1. die globale Modellkalibrierung (`Calibration.m`) Fertigungsschwankungen und Aushärteeffekte realitätsgetreu abbildet,
> 2. unerwartete Schadens- oder Versagensmodi (z. B. Kernschubversagen, Deckhautdelamination) sofort erkannt und konstruktiv behoben werden,
> 3. die offizielle [SES](#abk-ses)-Einreichung bei den Formula-Student-Bewerben von den Scrutineers beanstandungsfrei abgenommen wird.

#### Workflow: Neues Prüfpanel in 4 Schritten einpflegen
Sobald ein Prüfkörper auf der Universalprüfmaschine getestet und die Kraft-Weg-Messreihe exportiert wurde, erfolgt die Aufnahme in vier standardisierten Schritten:

1. **Panel-Stammdaten eintragen**:  
   Öffne die Excel-Datei `02_Data/Pruefstand_Rohdaten_Benchmark.xlsx` und navigiere zum ersten Tabellenblatt `Panels`. Füge am Ende der Tabelle eine neue Zeile mit den Parametern des Prüflings ein:
   * `Panel_ID`: Eindeutiges Saisons-Kürzel (z. B. `27_05`).
   * `Layup`: Der vollständige, syntaktisch korrekte Lagenaufbaustring (z. B. `45t7/0m/0m/21m/45t7/cp/18core/sym`).
   * `Kerndicke_mm`: Nominale Kernhöhe in $\text{mm}$ (z. B. $18$ oder $20$).
   * `Deckhautdicke_oben_mm`: Real mit der Mikrometer-Schraube gemessene Dicke der oberen Deckhaut (Druckseite / Stempelkontakt) nach der Heißpressung.
   * `Deckhautdicke_unten_mm`: Real gemessene Dicke der unteren Deckhaut (Zugseite / Auflage auf den Stützrollen).
   *(Hinweis zu asymmetrischen Panels: Bei asymmetrischen Lagenaufbauten müssen beide Deckhäute getrennt gemessen und eingetragen werden. Bei symmetrischen Laminaten sind beide Werte identisch).*

2. **Rohdaten-Tabellenblatt anlegen**:  
   Erstelle in derselben Arbeitsmappe ein neues Tabellenblatt, dessen Name exakt der `Panel_ID` entspricht (z. B. Blattname `27_05`).  
   Füge die unformatierten Messwerte der Prüfmaschine spaltenweise ein:
   * Spalte A (`Traversenweg_mm`): Stempelweg bzw. Durchbiegung $w$ in $\text{mm}$.
   * Spalte B (`Kraft_N`): Gemessene Prüfkraft $F$ in $\text{N}$.
   * *(Optional Spalte C `Zeit_s`: Zeitstempel der Messung).*

3. **Benchmark mit Neuladen ausführen**:  
   Starte den Benchmark in MATLAB mit erzwungenem Cache-Reload, um die neuen Excel-Daten einzulesen:
   ```matlab
   % Im MATLAB Command Window:
   run_benchmark('reload');
   % Oder alternativ über das Gesamtskript:
   Benchmark_Panels;
   ```

4. **Ergebnisse prüfen & Modell abgleichen**:  
   Im Terminal-Report und im generierten [PDF](#abk-pdf)-Bericht die relative Abweichung für Gradient und Energie prüfen:
   * **Normalbereich ($\le 10\,\%$ Abweichung)**: Auslegung und Fertigungsqualität sind bestätigt.
   * **Signifikante Abweichung ($> 15\,\%$)**: Prüfen, ob ein unerwarteter Versagensmodus vorlag (z. B. Schälung der Deckhaut durch fehlenden Klebefilm [CP](#abk-cp) oder Quereinbau des Wabenkerns [W](#abk-w)). Bei systematischen Abweichungen über mehrere Proben können die Fertigungskorrekturfaktoren in `01_Functions/Calibration.m` nachjustiert werden.

---

### 5.3 Fertigungsrichtlinien für den Panelbau

Aus den Benchmark-Ergebnissen und Schadensanalysen realer Prüfstandstests leiten sich fundamentale Richtlinien für den Panelbau ab:

* **Beidseitiger Klebefilm (`cp`)**: Zwischen Wabenkern und CFK-Deckhaut muss zwingend auf beiden Seiten eine Schicht Epoxidharz-Klebefilm ($\approx 150\text{ g/m}^2$) eingebracht werden. Ein Weglassen oder unzureichender Anpressdruck führt zu vorzeitiger Deckhaut-Delamination bei Bruchteilen der Auslegungslast.
* **Gewebelage als Kernanbindung**: Direkt auf den Klebefilm sollte immer mindestens eine Gewebelage (z. B. `45t7` oder `45f`) gelegt werden. Reine $0^\circ$-UD-Lagen am Kern neigen unter Querkraft zu Schälbeanspruchungen und lokaler Faserabplatzung an den Wabenstegen.
* **Heißpress-Aushärtung**: Um den im Berechnungsmodell hinterlegten Kompaktierungsfaktor von $0{,}95$ zu erreichen, müssen die Panels in einer Heißpresse unter definiertem Druck ($\approx 6\text{ bar}$) gehärtet werden. Eine reine Vakuuminfusion oder Vakuumsackhärtung im Ofen erreicht nicht die erforderliche Faservolumenfraktion und führt zu weicheren Deckhäuten.
* **Wabenkern-Orientierung einhalten**: Vor dem Zuschnitt ist die Ribbon-Richtung (`'L'`) der Wabenblöcke eindeutig zu markieren und parallel zur Prüf- bzw. Hauptlastrichtung einzubauen. Ein versehentlicher Quereinbau (`'W'`) reduziert den Kernschubmodul von $550\text{ MPa}$ auf $230\text{ MPa}$ und halbiert die Schubtragfähigkeit.

---

### 5.4 Einfluss der Kerndicke & Parameterstudien

Die Biegesteifigkeit ($EI$) eines Sandwich-Panels wird primär durch den Abstand der Deckhäute bestimmt (Steiner-Anteil):
$$
(EI)_{\text{equiv}} \approx E_{\text{skin}} \cdot b \cdot t_{\text{skin}} \cdot \frac{d^2}{2}
$$
wobei $d = t_{\text{core}} + t_{\text{skin}}$ den Hebelarm der Deckhautmitten darstellt.

#### Kerndicken im direkten Vergleich
* **10 mm Kern**: Sehr kompakter Aufbau für enge Bauraumbereiche. Wegen des geringen Abstands treten jedoch sehr hohe Kernschubspannungen auf ($\tau_{\text{core}} > 2{,}4\text{ MPa}$). Bei geringen Lagenzahlen dominiert Kernschubbruch als primärer Versagensmodus.
* **18 mm Kern**: Der bewährte Standard für Monocoque-Seitenwände und Cockpitstrukturen mit optimaler Balance aus Bauraumbedarf, Beulsteifigkeit und Kernschubreserve.
* **20 mm Kern**: Durch die Erhöhung von $18$ auf $20\text{ mm}$ wächst der Hebelarm $d$ um über $11\,\%$. Dadurch kann die Deckhautdicke bei gleichem Biegegradienten signifikant reduziert werden.

---

## 6. Referenz: Materialkatalog & [FSG](#abk-fsg)-Regeln

Dieses Kapitel dokumentiert alle in der zentralen Materialdatenbank (`materials.csv`) hinterlegten Werkstoffe, deren Kennwerte und anerkannte Syntax-Aliase sowie die maßgeblichen Laminat-Regeln nach dem Formula-Student-Regelwerk.

### 6.1 Material-Datenbank & Kennwerte

Alle Materialkarten werden über die Datei `02_Data/materials.csv` als Single Source of Truth verwaltet. Die Werte entsprechen den mechanischen Eigenschaften nach der Aushärtung im Heißpressverfahren ($\approx 6\text{ bar}$):

#### Tabelle 6.1: Übersicht der hinterlegten Werkstoffdaten in materials.csv

| Token | Bezeichnung | Typ | $E_1$ [GPa] | $X_t$ [MPa] | $t_{\text{ply}}$ [mm] | $\rho$ [$\text{g/cm}^3$] | Aliase |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `f` | M40J Fabric | [CFK](#abk-cfk)-Gewebe | $86{,}8$ | $864$ | $0{,}23$ | $1{,}49$ | `fm40j`, `m40jf`, `mf` |
| `m` | M40J UD | [CFK](#abk-cfk)-[UD](#abk-ud) | $175{,}6$ | $2273$ | $0{,}21$ | $1{,}52$ | `ud`, `m40jud` |
| `t7` | T700 Fabric | [CFK](#abk-cfk)-Gewebe | $58{,}2$ | $1120$ | $0{,}31$ | $1{,}51$ | `t`, `t700`, `ft` |
| `t8` | T800S UD | [CFK](#abk-cfk)-[UD](#abk-ud) | $155{,}7$ | $3344$ | $0{,}15$ | $1{,}54$ | `t800`, `t800s`, `u8` |
| `z` | ZZ300T | Zylon-Gewebe | $51{,}9$ | $988$ | $0{,}38$ | $0{,}78$ | `zz300t` |
| `a` | SIGAPREG A W173 | Aramid-Gewebe | $26{,}0$ | $590$ | $0{,}23$ | $1{,}33$ | `aramid`, `kevlar` |
| `cp` | Coupling Film | Klebefilm ([CP](#abk-cp)) | -- | -- | $0{,}15$ | $1{,}00$ | `cp` |
| `core` | Aluminium 5056 | Wabenkern | -- | -- | $18{,}0$ | $0{,}075$ | `core`, `corew` |

#### Einsatzzwecke der Kernmaterialien
* **M40J [UD](#abk-ud) (`m`)**: [Hochmodulfaser](#abk-hm) für maximale Längssteifigkeit ($E_1 = 175{,}6\text{ GPa}$). Bildet das Rückgrat für hohe Biegegradienten bei minimaler Lagenzahl.
* **T700 Fabric (`t7`)**: Hochfestes Standardgewebe ($X_t = 1120\text{ MPa}$). Durch die hohe Dehnfähigkeit ideal als robuste, schlagfeste Sichtlage gemäß [FSG](#abk-fsg)-Reglement.
* **T800S [UD](#abk-ud) (`t8`)**: [Intermediat-Modul-Faser](#abk-im) mit extremer Zugfestigkeit ($X_t = 3344\text{ MPa}$). Eignet sich besonders für zugbeanspruchte Unterseiten zur Verhinderung vorzeitigen Faserbruchs.
* **M40J Fabric (`f`)**: [Hochmodul](#abk-hm)-Gewebe ($E_1 = 86{,}8\text{ GPa}$). Verbindet hohe Steifigkeit mit Gewebestruktur; optimal als Anbindelage am Kern.
* **Zylon ZZ300T (`z`)**: [PBO](#abk-pbo)-Faser mit extremer Bruchzähigkeit und Energieaufnahme für Crash- und Splitterschutzzonen.
* **Klebefilm ([CP](#abk-cp))**: Unverzichtbare Epoxidharz-Kopplungsschicht ($\approx 150\text{ g/m}^2$) zur formschlüssigen Wabenkernanbindung.

---

### 6.2 Laminat-Regeln nach Formula Student ([FSG](#abk-fsg) T 3.5)

Bei der Auslegung und manuellen Definition von Laminaten müssen folgende Regelwerksgrenzen zwingend eingehalten werden:

* **Sichtlagen-Regel ([FSG](#abk-fsg) T 3.5.7)**: Die äußerste Lage jeder Sandwich-Deckhaut muss zwingend einlagiges Gewebe sein (z. B. `45t7` oder `45f`). Reines [UD](#abk-ud)-Gelege an der Außenseite ist nach Regelwerk unzulässig.
* **Parallellagen-Begrenzung ([FSG](#abk-fsg) T 3.5.3)**: Maximal $50\,\%$ der Einzellagen einer Deckhaut dürfen in die gleiche Faserrichtung orientiert sein. Beispielsweise sind bei einem 4-Lagen-Aufbau höchstens zwei $0^\circ$-Lagen erlaubt.
* **Asymmetrie-Regel der Deckhäute ([FSG](#abk-fsg) T 3.5.4)**: Unterscheiden sich die Dicken der oberen und unteren Deckhaut ($t_{\text{top}} \ne t_{\text{lower}}$), darf das Dickenverhältnis nicht beliebig gewählt werden. Die dünnere Deckhaut ($t_{\text{min}}$) muss mindestens $40\,\%$ der Dicke der stärkeren Deckhaut ($t_{\text{max}}$) betragen:
  $$
  t_{\text{min}} \ge \min(0{,}40 \cdot t_{\text{max}}, \, 1{,}0\text{ mm})
  $$
  Erreicht die dünnere Deckhaut mindestens $1{,}0\text{ mm}$ Dicke, ist jedes Dickenverhältnis regelkonform. Beim physischen 3-Punkt-Biegeversuch für den [SES](#abk-ses)-Nachweis muss bei asymmetrischen Aufbauten die schwächere Deckhaut auf Zug (Unterseite) getestet werden.
* **Kernanbindung & Klebefilm**: Der Klebefilm (`cp`) muss beidseitig zwischen Kern und Deckhaut verbaut sein. Für den standardmäßigen [SES](#abk-ses)-Nachweis wird ein symmetrischer Aufbau (`sym`) empfohlen, um Schäl- und Kopplungseffekte zu minimieren.




