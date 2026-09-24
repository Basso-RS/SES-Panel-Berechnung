# SES Panelberechnung

Dieses Projekt dient der automatisierten Vorauslegung und Berechnung von Sandwich-Panels (bestehend aus CFK-Deckschichten und Kernmaterial). Der Fokus liegt dabei auf dem physikalischen Nachweis der strukturellen Eigenschaften und Durchbiegungen, wie sie typischerweise im **Formula Student Structural Equivalency Spreadsheet (SES)** gefordert werden.

## 🎯 Ziele der Entwicklung

Die aktuelle Entwicklung zielt auf folgende Kernpunkte ab:
- **Automatisierung der SES-Nachweise**: Schnelle, reproduzierbare Berechnung von Steifigkeiten und Verformungen von flachen Sandwich-Strukturen unter Biegebelastung (z. B. 3-Punkt-Biegeversuch).
- **Modulare und saubere Architektur**: Konsequente Trennung von Eingabedaten (`02_Data`), physikalischen Berechnungsfunktionen (`01_Functions`) und der eigentlichen Ausführung (`00_Scripts`).
- **Bestimmung essenzieller Kennwerte**: 
  - Äquivalente Biegesteifigkeit ($EI$) des Sandwich-Verbunds.
  - Schubsteifigkeit ($S$) unter Berücksichtigung des Kerns.
  - Maximalkraft ($F_{max}$) bei einer definierten Durchbiegung (z. B. Vorgabe: $w = 12,7$ mm).
  - Berechnung des Kraft-Weg-Verlaufs und der absorbierten Energie in Joule.
- **Erweiterbarkeit**: Eine solide Basis schaffen für spätere Erweiterungen wie Versagenskriterien (Spannungsnachweise) oder automatisierte Exporte.

---

## 📖 User-Guide (Work in Progress)

*Hinweis: Dieser Abschnitt wird im Laufe der weiteren Entwicklung zu einem detaillierten Benutzerhandbuch ausgebaut.*

### 1. Projektstruktur
- `00_Scripts/`: Einstiegsskripte für Einzelsimulation (`Calculate_Single_Panel.m`), Optimierung (`Optimize_Panel.m`) und Benchmarks (`Benchmark_Panels.m`).
- `01_Functions/`: Physikalische und mathematische Kernfunktionen (KLT, Hashin, Durchbiegung, Energie, Gewichtsberechnung).
- `02_Data/`: Materialdatenbank (`materials.csv`), Regelwerke (FSG) und experimentelle Prüfstands-Daten.
- `03_Research/`: Forschungsberichte, Voruntersuchungen, extrahierte Daten und KI-Entwicklungsartefakte.

### 2. Nutzung (Kurzanleitung)
1. **Einzelsimulation**: Öffne `01_Functions/Scenariodata.m` für den gewünschten Lagenaufbau und führe `00_Scripts/Calculate_Single_Panel.m` (oder `RunMe.m`) aus.
2. **Laminat-Optimierung**: Führe `00_Scripts/Optimize_Panel.m` aus, um automatisiert das leichteste regelkonforme Laminat mit Zielsteifigkeit und Mindestenergie zu finden.
3. **Validierung / Benchmark**: Führe `00_Scripts/Benchmark_Panels.m` aus, um die Simulation gegen alle realen Prüfstandsergebnisse abzugleichen.
