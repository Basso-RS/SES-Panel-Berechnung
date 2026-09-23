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
    
    print(f"Total 24 panels: {len(p24)}")
    print(f"Total 26 panels: {len(p26)}")
    print(f"Total 27 panels with test data: {len(p27)}")
    
    fmt = "{:<7} | {:<42} | {:<5} | {:<6} | {:<10} | {:<8} | {:<7} | {:<7} | {:<8} | {:<8} | {:<8} | {:<8}"
    
    for label, series in [("2024 PANELS (24_xx)", p24), ("2026 PANELS (26_xx)", p26), ("2027 PANELS (27_xx)", p27)]:
        print("\n" + "="*125)
        print(label)
        print("="*125)
        print(fmt.format("Panel", "Aufbau", "Core", "t_top", "Fmax [N]", "Grad", "E[GPa]", "UTS[MPa]", "Ene[J]", "W[g]", "tau_out", "tau_in"))
        print("-" * 125)
        for p in series:
            pid = str(p.get('Testpanel', ''))
            aufbau = str(p.get('Aufbau', ''))[:40]
            core = str(p.get('b(mm)', ''))
            
            tt_v = to_float(p.get('SkinThickness_Top'))
            tt = f"{tt_v:.2f}" if tt_v is not None else ""
            
            fmax_v = to_float(p.get('3PB_MaxKraft[N]'))
            fmax = f"{fmax_v:.1f}" if fmax_v is not None else ""
            
            grad_v = to_float(p.get('Gradient'))
            grad = f"{grad_v:.1f}" if grad_v is not None else ""
            
            emod_v = to_float(p.get('E(GPa)'))
            emod = f"{emod_v:.1f}" if emod_v is not None else ""
            
            uts_v = to_float(p.get('RigCompliance(N/mm)_σUTS(MPa)'))
            uts = f"{uts_v:.1f}" if uts_v is not None else ""
            
            ene_v = to_float(p.get('Energy[J]'))
            ene = f"{ene_v:.1f}" if ene_v is not None else ""
            
            w_v = to_float(p.get('Weight[g]_measured[g]'))
            w = f"{w_v:.1f}" if w_v is not None else ""
            
            to_v = to_float(p.get('σShearouterPeek(MPa)'))
            tau_o = f"{to_v:.1f}" if to_v is not None else ""
            
            ti_v = to_float(p.get('σShearinnerPeek(MPa)'))
            tau_i = f"{ti_v:.1f}" if ti_v is not None else ""
            
            print(fmt.format(pid, aufbau, core, tt, fmax, grad, emod, uts, ene, w, tau_o, tau_i))

if __name__ == '__main__':
    main()
