with open(r"c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_spec_miner_survey_1\rules_extracted.txt", "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

# Let's search for "T 3." headings or "Monocoque"
import re
sections = re.findall(r"(T\s*3\.[0-9]+[^\n]*)", text)
print("Found T3 sections:")
for s in set(sections):
    print("  ", s)

# Search for "3-point bending" or "SES" or "woven" or "core"
print("\n--- Searches for core / woven / 3-point ---")
for line in text.splitlines():
    if any(k in line.lower() for k in ["3-point", "woven", "core", "equivalency", "rig compliance", "12.7", "energy"]):
        if len(line.strip()) > 15:
            print(line.strip()[:100])
