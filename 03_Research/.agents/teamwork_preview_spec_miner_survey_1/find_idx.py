with open(r"c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_spec_miner_survey_1\rules_extracted.txt", "r", encoding="utf-8", errors="ignore") as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if "T3GeneralChassisDesign" in line or "T3.5" in line or "T3.4" in line or "T3.2" in line:
        print(f"Index {idx}: {line.strip()}")
