import openpyxl
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    wb = openpyxl.load_workbook('02_Data/Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm', data_only=True, read_only=True)
    
    # Check sheets of interest
    target_sheets = ['26_17', '26_18', '26_19', '26_11', '26_12', '27_01', '27_02', '27_03', '27_04', '24_11_3P', '24_12_3P', '24_13_3P']
    for name in target_sheets:
        if name not in wb.sheetnames:
            print(f"Sheet {name} not found!")
            continue
        ws = wb[name]
        print(f"\n{'='*50}\nSheet: {name}\n{'='*50}")
        # Print first 25 rows, columns A-L
        for r in range(1, 25):
            row_vals = [ws.cell(r, c).value for c in range(1, 13)]
            if any(v is not None for v in row_vals):
                print(f"Row {r:2d}: {row_vals}")

if __name__ == '__main__':
    main()
