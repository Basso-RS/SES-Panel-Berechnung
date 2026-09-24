import zlib
import re
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    with open('02_Data/FS-Rules_2026_v1.1.pdf', 'rb') as f:
        data = f.read()

    stream_re = re.compile(rb'stream[\r\n]+(.*?)[\r\n]+endstream', re.DOTALL)
    text_chunks = []
    for match in stream_re.finditer(data):
        raw = match.group(1)
        try:
            decomp = zlib.decompress(raw)
            # extract readable strings
            text_chunks.append(decomp.decode('latin1', errors='ignore'))
        except Exception:
            pass

    full_text = "\n".join(text_chunks)
    print(f"Decompressed text length: {len(full_text)} characters")

    # Search for SES, T3, composite, sandwich, woven, etc.
    queries = [
        r'T\s*3\.\d+',
        r'woven',
        r'rig\s*compliance',
        r'12\.7',
        r'sandwich',
        r'honeycomb',
        r'structural\s*equivalency',
        r'energy',
        r'T\s*3\.5'
    ]

    for q in queries:
        matches = list(re.finditer(q, full_text, re.IGNORECASE))
        print(f"Query '{q}': {len(matches)} matches")
        for m in matches[:5]:
            start = max(0, m.start() - 100)
            end = min(len(full_text), m.end() + 200)
            clean = " ".join(full_text[start:end].split())
            print(f"   Snippet: ... {clean} ...")

if __name__ == '__main__':
    main()
