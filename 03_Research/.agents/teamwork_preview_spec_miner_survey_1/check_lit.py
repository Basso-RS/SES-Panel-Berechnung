import re
import zlib
import os

pdf_paths = [
    r"G:\Meine Ablage\Literatur\THE HANDBOOK OF SANDWICH CONSTRUCTION.pdf",
    r"G:\Meine Ablage\Literatur\Analysis_and_Design_of_Structural_Sandwi.pdf",
    r"G:\Meine Ablage\Literatur\CLT.pdf"
]

for p in pdf_paths:
    if os.path.exists(p):
        print(f"Found: {p}, size: {os.path.getsize(p)} bytes")
    else:
        print(f"Not found: {p}")
