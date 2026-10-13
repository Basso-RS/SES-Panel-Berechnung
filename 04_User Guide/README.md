# 04_User Guide – Formula Student SES Panelberechnung

Dieses Verzeichnis enthält das offizielle Benutzerhandbuch zur MATLAB SES Panel Calculation & Optimization Suite (Saisons 2026 / 2027).

---

## 📄 Verfügbare Versionen

1. **PDF-Handbuch (Druck- & Leseversion):**
   - [`User_Guide_v1.0.pdf`](./User_Guide_v1.0.pdf) – Das fertig gesetzte Gesamtdokument mit formatierten Tabellen, Formeln und Schaubildern.

2. **Online- & Markdown-Version:**
   - [`README.md im Hauptverzeichnis`](../README.md) – Schnelle Navigation und interaktive Leseansicht direkt im Repository.

---

## 🛠️ LaTeX-Quellcode

- **Hauptdokument:** `User_Guide.tex`
- **Kapitel:** Ordner `chapters/`
  - `00_abkuerzungen.tex`
  - `01_erste_schritte_quickstart.tex`
  - `02_eingaben_konfiguration.tex`
  - `03_haupt_workflows.tex`
  - `04_troubleshooting_faq.tex`
  - `05_sonderfunktionen_advanced.tex`
  - `06_referenz_materialien.tex`

### Kompilierungshinweis
Zum Neukompilieren (z. B. mit `pdflatex` oder `latexmk`):
```bash
latexmk -pdf User_Guide.tex
```
*Hinweis: LaTeX-Build-Artefakte (`*.aux`, `*.log`, `*.toc` etc.) werden über die `.gitignore` automatisch ignoriert.*
