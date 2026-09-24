import re
import zlib

pdf_path = r"c:\Users\lauri\Documents\MATLAB\SES_Panel\02_Data\FS-Rules_2026_v1.1.pdf"

with open(pdf_path, "rb") as f:
    content = f.read()

stream_pattern = re.compile(rb"stream[\r\n]+(.*?)[\r\n]+endstream", re.DOTALL)
decompressed_chunks = []

for match in stream_pattern.finditer(content):
    try:
        decomp = zlib.decompress(match.group(1))
        decompressed_chunks.append(decomp.decode("latin1", errors="ignore"))
    except Exception:
        pass

full_raw = "\n".join(decompressed_chunks)

def parse_pdf_text(text):
    out = []
    # match Tj and TJ blocks
    for line in text.splitlines():
        # Match [(...)]TJ
        tj_matches = re.findall(r"\((.*?)\)", line)
        if tj_matches:
            # combine characters
            combined = "".join(tj_matches)
            if combined.strip():
                out.append(combined)
    return "\n".join(out)

parsed = parse_pdf_text(full_raw)

with open(r"c:\Users\lauri\Documents\MATLAB\SES_Panel\.agents\teamwork_preview_spec_miner_survey_1\rules_extracted.txt", "w", encoding="utf-8") as out_f:
    out_f.write(parsed)

print(f"Parsed {len(parsed)} characters. Searching for key rule sections...")

# Let's search for "T 3." or "T3." or "monocoque" sections
lines = parsed.splitlines()
for i, l in enumerate(lines):
    if "T 3." in l or "T3." in l or "T 1.1" in l or "T 2." in l:
        print(f"L{i}: {l}")
        # print surrounding
        for j in range(max(0, i-2), min(len(lines), i+15)):
            print(f"   {lines[j]}")
        print("-" * 50)
