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
- `00_Scripts/`: Enthält das ausführende Hauptskript (`RunMe.m`). Hier läuft die Berechnung zusammen.
- `01_Functions/`: Beinhaltet die mathematischen und physikalischen Kernfunktionen (`EI_calc.m`, `Shearstiff_calc.m`, `Deflection.m`).
- `02_Data/`: Beinhaltet die Definition der Eingabedaten und Randbedingungen (`Materialdata.m`).

### 2. Nutzung (Kurzanleitung)
1. **Parameter anpassen**: Öffne die Datei `02_Data/Materialdata.m` in MATLAB. Hier kannst du die Geometrie des Panels (Breite, Stützweite) sowie die Materialkennwerte (Dicken, E-Modul der Deckschichten, Schubmodul des Kerns) eintragen.
2. **Berechnung starten**: Führe das Skript `00_Scripts/RunMe.m` aus.
3. **Ergebnisse ablesen**: Alle berechneten Werte (Kräfte, Energie, Steifigkeiten) werden am Ende im MATLAB-Workspace in der Struktur `Results` gespeichert. 

### 3. Ausstehende / Geplante Features
- [ ] Visualisierung des Kraft-Weg-Verlaufs als Diagramm.
- [ ] Berechnung kritischer Versagenslasten (Kernschubversagen, Deckschichtversagen).
- [ ] Möglicher automatisierter Export der Ergebnisse direkt in das Excel-Sheet (`FS26_SES_...xlsx`).
