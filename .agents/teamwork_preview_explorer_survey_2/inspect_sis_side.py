import openpyxl
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    wb = openpyxl.load_workbook('02_Data/Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm', data_only=True, read_only=True)
    ws = wb['T3.15 T3.5 SIS Side']
    print(f"Sheet: T3.15 T3.5 SIS Side")
    for r in range(1, 45):
        row_vals = [ws.cell(r, c).value for c in range(1, 15)]
        if any(v is not None for v in row_vals):
            print(f"R{r:2d}: {[v for v in row_vals if v is not None]}")

if __name__ == '__main__':
    main()
