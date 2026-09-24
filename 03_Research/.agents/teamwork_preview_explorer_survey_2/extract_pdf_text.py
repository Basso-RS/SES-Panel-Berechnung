import zlib
import re
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    with open('02_Data/FS-Rules_2026_v1.1.pdf', 'rb') as f:
        data = f.read()

    stream_re = re.compile(rb'stream[\r\n]+(.*?)[\r\n]+endstream', re.DOTALL)
    
    extracted_text = []
    for match in stream_re.finditer(data):
        raw = match.group(1)
        try:
            decomp = zlib.decompress(raw).decode('latin1', errors='ignore')
            # Extract TJ blocks: [(text)-123(more text)]TJ
            tj_blocks = re.findall(r'\[(.*?)\]\s*TJ', decomp, re.DOTALL)
            for block in tj_blocks:
                strings = re.findall(r'\((.*?)\)', block)
                line = "".join(strings)
                if line:
                    extracted_text.append(line)
            # Extract Tj blocks: (text)Tj
            tj_singles = re.findall(r'\((.*?)\)\s*Tj', decomp, re.DOTALL)
            for s in tj_singles:
                if s:
                    extracted_text.append(s)
        except Exception:
            pass

    full = " ".join(extracted_text)
    print(f"Total extracted words/text: {len(full)} chars")
    
    # Now let's search for rules on composite / monocoque / T3 / SES / woven / compliance
    terms = ['woven', 'weave', 'rig compliance', 'compliance', 'outer layer', 'T 3.5', 'T 3.4', 'T 3.3', 'T 3.2', 'T 3.1', 'monocoque', 'sandwich', 'core', 'equivalent', 'SES']
    for t in terms:
        matches = [m.start() for m in re.finditer(re.escape(t), full, re.IGNORECASE)]
        print(f"Term '{t}': {len(matches)} occurrences")
        for idx in matches[:3]:
            print(f"   [{t}]: ... {full[max(0, idx-80):min(len(full), idx+150)]} ...")

if __name__ == '__main__':
    main()
