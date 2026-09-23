import json
import openpyxl
import sys
import numpy as np

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

def analyze_curve_sheet(ws):
    if ws is None:
        return None
    pts = []
    for row in ws.iter_rows(min_row=32, values_only=True):
        if not row or len(row) < 4:
            continue
        c_d = to_float(row[1])
        if c_d is None and len(row) > 2:
            c_d = to_float(row[2])
        c_f = to_float(row[3])
        if c_d is None or c_f is None:
            continue
        pts.append((abs(c_d), abs(c_f)))
    if not pts:
        return None
        
    max_d = max(p[0] for p in pts)
    max_f = max(p[1] for p in pts)
    d_at_max_f = [p[0] for p in pts if p[1] == max_f][0]
    f_at_max_d = pts[-1][1]
    
    total_energy = 0.0
    energy_12_7 = 0.0
    f_at_12_7 = None
    
    for i in range(1, len(pts)):
        d0, f0 = pts[i-1]
        d1, f1 = pts[i]
        delta_d = d1 - d0
        if delta_d > 0:
            trapz = 0.5 * (f0 + f1) * delta_d / 1000.0
            total_energy += trapz
            if d1 <= 12.7:
                energy_12_7 += trapz
            elif d0 < 12.7:
                frac = (12.7 - d0) / delta_d
                f_mid = f0 + frac * (f1 - f0)
                energy_12_7 += 0.5 * (f0 + f_mid) * (12.7 - d0) / 1000.0
                f_at_12_7 = f_mid
                
    if f_at_12_7 is None and max_d >= 12.7:
        for i in range(len(pts)-1):
            if pts[i][0] <= 12.7 <= pts[i+1][0]:
                d0, f0 = pts[i]
                d1, f1 = pts[i+1]
                if d1 > d0:
                    f_at_12_7 = f0 + (12.7 - d0)/(d1 - d0) * (f1 - f0)
                break
                
    return {
        'max_f': max_f,
        'd_at_max_f': d_at_max_f,
        'max_d': max_d,
        'f_at_max_d': f_at_max_d,
        'f_at_12_7': f_at_12_7,
        'energy_12_7': energy_12_7 if max_d >= 12.7 else None,
        'total_energy': total_energy
    }

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    with open('overview_extracted.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    wb = openpyxl.load_workbook('02_Data/Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm', data_only=True, read_only=True)
    
    p24 = [d for d in data if str(d.get('Testpanel', '')).startswith('24_')]
    p26 = [d for d in data if str(d.get('Testpanel', '')).startswith('26_')]
    p27 = [d for d in data if str(d.get('Testpanel', '')).startswith('27_') and to_float(d.get('3PB_MaxKraft[N]')) is not None]

    print("=== SUMMARY METRICS ===")
    for name, series in [("2024 Series", p24), ("2026 Series", p26), ("2027 Series", p27)]:
        valid_fmax = [abs(to_float(p.get('3PB_MaxKraft[N]'))) for p in series if to_float(p.get('3PB_MaxKraft[N]')) is not None and abs(to_float(p.get('3PB_MaxKraft[N]'))) > 0]
        valid_grad = [to_float(p.get('Gradient')) for p in series if to_float(p.get('Gradient')) is not None and to_float(p.get('Gradient')) > 0]
        valid_emod = [to_float(p.get('E(GPa)')) for p in series if to_float(p.get('E(GPa)')) is not None and to_float(p.get('E(GPa)')) > 0]
        valid_uts = [to_float(p.get('RigCompliance(N/mm)_σUTS(MPa)')) for p in series if to_float(p.get('RigCompliance(N/mm)_σUTS(MPa)')) is not None and to_float(p.get('RigCompliance(N/mm)_σUTS(MPa)')) > 0]
        valid_energy = [to_float(p.get('Energy[J]')) for p in series if to_float(p.get('Energy[J]')) is not None and to_float(p.get('Energy[J]')) > 0]
        valid_weight = [to_float(p.get('Weight[g]_measured[g]')) for p in series if to_float(p.get('Weight[g]_measured[g]')) is not None and to_float(p.get('Weight[g]_measured[g]')) > 0]
        valid_ttop = [to_float(p.get('SkinThickness_Top')) for p in series if to_float(p.get('SkinThickness_Top')) is not None and to_float(p.get('SkinThickness_Top')) > 0]
        
        print(f"\n{name} (N = {len(series)}):")
        print(f"  Fmax [N]: count={len(valid_fmax)}, min={min(valid_fmax):.1f}, mean={np.mean(valid_fmax):.1f}, max={max(valid_fmax):.1f}")
        print(f"  Grad [N/mm]: count={len(valid_grad)}, min={min(valid_grad):.1f}, mean={np.mean(valid_grad):.1f}, max={max(valid_grad):.1f}")
        print(f"  E-Modul [GPa]: count={len(valid_emod)}, min={min(valid_emod):.1f}, mean={np.mean(valid_emod):.1f}, max={max(valid_emod):.1f}")
        print(f"  UTS [MPa]: count={len(valid_uts)}, min={min(valid_uts):.1f}, mean={np.mean(valid_uts):.1f}, max={max(valid_uts):.1f}")
        print(f"  Energy [J]: count={len(valid_energy)}, min={min(valid_energy):.1f}, mean={np.mean(valid_energy):.1f}, max={max(valid_energy):.1f}")
        print(f"  Weight [g]: count={len(valid_weight)}, min={min(valid_weight):.1f}, mean={np.mean(valid_weight):.1f}, max={max(valid_weight):.1f}")
        print(f"  Skin t_top [mm]: count={len(valid_ttop)}, min={min(valid_ttop):.2f}, mean={np.mean(valid_ttop):.2f}, max={max(valid_ttop):.2f}")

if __name__ == '__main__':
    main()
