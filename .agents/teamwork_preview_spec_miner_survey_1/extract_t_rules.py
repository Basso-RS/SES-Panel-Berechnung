with open(r"c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_spec_miner_survey_1\rules_extracted.txt", "r", encoding="utf-8", errors="ignore") as f:
    lines = f.readlines()

capturing = False
t_lines = []
for i, line in enumerate(lines):
    if "T2" in line or "T 2" in line or "T3" in line or "T 3" in line:
        capturing = True
    if capturing:
        t_lines.append(line)
        if "T4" in line or "T 4" in line or len(t_lines) > 2500:
            if "T4" in line:
                break

with open(r"c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_spec_miner_survey_1\rules_t2_t3.txt", "w", encoding="utf-8") as out_f:
    out_f.writelines(t_lines)

print(f"Captured {len(t_lines)} lines of T2/T3 rules.")
