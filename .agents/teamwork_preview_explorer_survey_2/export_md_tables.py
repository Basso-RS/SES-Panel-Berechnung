import json
import sys

def to_float(val):
    if val is None:
        return None
    if isinstance(val, (int, float)):
        return float(val)
    try:
        s = str(val).strip().replace(',', '.')
        return float(s)
    except Exception:
        return None

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    with open('overview_extracted.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    p24 = [d for d in data if str(d.get('Testpanel', '')).startswith('24_')]
    p26 = [d for d in data if str(d.get('Testpanel', '')).startswith('26_')]
    p27 = [d for d in data if str(d.get('Testpanel', '')).startswith('27_') and to_float(d.get('3PB_MaxKraft[N]')) is not None]

    for label, series in [("2024 Test Series (24_02 to 24_21)", p24),
                          ("2026 Test Series (26_01 to 26_27)", p26),
                          ("2027 Test Series (27_01 to 27_04)", p27)]:
        print(f"\n### {label}\n")
        print("| Panel ID | Layup (Aufbau) | Core [mm] | Skin t [mm] | Fmax [N] | Gradient [N/mm] | E [GPa] | UTS [MPa] | Energy [J] | Weight [g] | Comment |")
        print("|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|")
        for p in series:
            pid = str(p.get('Testpanel', ''))
            aufbau = str(p.get('Aufbau', '-'))
            core = str(p.get('b(mm)', '-'))
            tt = f"{to_float(p.get('SkinThickness_Top')):.2f}" if to_float(p.get('SkinThickness_Top')) is not None else "-"
            fmax = f"{abs(to_float(p.get('3PB_MaxKraft[N]'))):.1f}" if to_float(p.get('3PB_MaxKraft[N]')) is not None else "-"
            grad = f"{to_float(p.get('Gradient')):.1f}" if to_float(p.get('Gradient')) is not None else "-"
            emod = f"{to_float(p.get('E(GPa)')):.1f}" if to_float(p.get('E(GPa)')) is not None else "-"
            uts = f"{to_float(p.get('RigCompliance(N/mm)_σUTS(MPa)')):.1f}" if to_float(p.get('RigCompliance(N/mm)_σUTS(MPa)')) is not None else "-"
            ene = f"{to_float(p.get('Energy[J]')):.1f}" if to_float(p.get('Energy[J]')) is not None else "-"
            w = f"{to_float(p.get('Weight[g]_measured[g]')):.1f}" if to_float(p.get('Weight[g]_measured[g]')) is not None else "-"
            comm = str(p.get('Kommentar', '-')) if p.get('Kommentar') is not None else "-"
            print(f"| `{pid}` | `{aufbau}` | {core} | {tt} | {fmax} | {grad} | {emod} | {uts} | {ene} | {w} | {comm} |")

if __name__ == '__main__':
    main()
