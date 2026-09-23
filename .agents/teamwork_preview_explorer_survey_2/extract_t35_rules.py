import zlib
import re
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    with open('02_Data/FS-Rules_2026_v1.1.pdf', 'rb') as f:
        data = f.read()

    stream_re = re.compile(rb'stream[\r\n]+(.*?)[\r\n]+endstream', re.DOTALL)
    
    all_chunks = []
    for match in stream_re.finditer(data):
        raw = match.group(1)
        try:
            decomp = zlib.decompress(raw).decode('latin1', errors='ignore')
            tj_blocks = re.findall(r'\[(.*?)\]\s*TJ', decomp, re.DOTALL)
            for block in tj_blocks:
                strings = re.findall(r'\((.*?)\)', block)
                line = "".join(strings)
                if line:
                    all_chunks.append(line)
            tj_singles = re.findall(r'\((.*?)\)\s*Tj', decomp, re.DOTALL)
            for s in tj_singles:
                if s:
                    all_chunks.append(s)
        except Exception:
            pass

    full = " ".join(all_chunks)
    
    for m in re.finditer(r'T3\.5\.\d+|T3\.6\.[1-8]', full):
        idx = m.start()
        rule_num = m.group(0)
        snippet = full[idx:idx+450]
        print(f"\n=== {rule_num} ===")
        print(snippet[:350])

if __name__ == '__main__':
    main()
