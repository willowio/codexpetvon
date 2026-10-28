"""Read a metadata field for the Linux shell installer (Python 3 stdlib only)."""
import json
import sys
with open(sys.argv[2], encoding="utf-8") as source:
    value = json.load(source)[sys.argv[1]]
if type(value) not in (str, int):
    raise ValueError("Unsupported metadata value")
print(value)
