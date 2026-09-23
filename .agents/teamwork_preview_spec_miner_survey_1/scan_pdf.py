import re
import zlib

pdf_path = r"c:\Users\lauri\Documents\MATLAB\SES_Panel\02_Data\FS-Rules_2026_v1.1.pdf"

with open(pdf_path, "rb") as f:
    content = f.read()

# find streams
stream_pattern = re.compile(rb"stream[\r\n]+(.*?)[\r\n]+endstream", re.DOTALL)
decompressed_text = []

for match in stream_pattern.finditer(content):
    stream_data = match.group(1)
    try:
        decomp = zlib.decompress(stream_data)
        decompressed_text.append(decomp.decode("latin1", errors="ignore"))
    except Exception:
        pass

all_text = "\n".join(decompressed_text)
print(f"Extracted text length: {len(all_text)}")

# Look for T3, T 3, SES, equivalency, sandwich
for line in all_text.splitlines():
    if any(k in line for k in ["T 3.5", "T3.5", "T 3.4", "T 3.6", "SES", "sandwich", "monocoque", "Equivalency", "C393", "D7250", "D7249"]):
        # clean PDF BT/ET formatting if present
        clean = re.sub(r"\([^\)]*\)", lambda m: m.group(0), line)
        if len(line.strip()) > 5:
            print(line[:120])
