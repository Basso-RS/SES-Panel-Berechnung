import openpyxl
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    wb = openpyxl.load_workbook('02_Data/Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm', data_only=True, read_only=True)
    ws = wb['Overview']
    for r_idx, row in enumerate(ws.iter_rows(values_only=True), start=1):
        val = row[0]
        if val and any(str(val).startswith(pre) for pre in ['24_', '26_', '27_']):
            kommentar = row[4]
            aufbau = row[1]
            core = row[10]
            if kommentar or ('core' in str(aufbau).lower()):
                print(f"{val:<7} | Core: {str(core):<5} | Aufbau: {str(aufbau):<45} | Komment: {str(kommentar)}")

if __name__ == '__main__':
    main()
