import os

lit_dir = r"G:\Meine Ablage\Literatur"

for root, dirs, files in os.walk(lit_dir):
    for f in files:
        if any(k in f.lower() for k in ["sandwich", "clt", "c393", "d7250", "d7249", "allen", "fsae", "ses", "honeycomb", "core", "jones"]):
            full = os.path.join(root, f)
            print(f"{f} -> {full} ({os.path.getsize(full)} bytes)")
