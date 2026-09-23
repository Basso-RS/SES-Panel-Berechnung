import json
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    with open('overview_extracted.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for pid in ['27_01', '27_02', '27_03', '27_04', '26_16', '26_17', '26_18', '26_19', '26_20', '26_21']:
        matches = [d for d in data if str(d.get('Testpanel', '')) == pid]
        if not matches:
            continue
        p = matches[0]
        print(f"Panel: {pid}")
        print(f"  Aufbau: {p.get('Aufbau')}")
        print(f"  Kommentar: {p.get('Kommentar')}")
        print(f"  SkinThickness_Top: {p.get('SkinThickness_Top')}")
        print(f"  Bottom: {p.get('Bottom')}")
        print(f"  GemesseneLagendicke_Top: {p.get('GemesseneLagendicke_Top')}")
        print(f"  BerechneteLagendicke_Top: {p.get('BerechneteLagendicke_Top')}")
        print(f"  b(mm) core: {p.get('b(mm)')}")
        print(f"  Weight: {p.get('Weight[g]_measured[g]')}")
        print(f"  Fmax: {p.get('3PB_MaxKraft[N]')}")
        print(f"  Grad: {p.get('Gradient')}")
        print(f"  E: {p.get('E(GPa)')}")
        print(f"  UTS: {p.get('RigCompliance(N/mm)_σUTS(MPa)')}")
        print(f"  Energy: {p.get('Energy[J]')}")
        print()

if __name__ == '__main__':
    main()
