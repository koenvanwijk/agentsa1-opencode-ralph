#!/bin/bash
# verify.sh <workdir> — exit 0 = pass
W="$1"
python3 - "$W" << 'PY'
import sys, importlib.util
w = sys.argv[1]
spec = importlib.util.spec_from_file_location("fizzbuzz", f"{w}/fizzbuzz.py")
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
cases = {3:"Fizz", 5:"Buzz", 15:"FizzBuzz", 7:"7", 1:"1", 9:"Fizz", 10:"Buzz"}
for n, exp in cases.items():
    got = m.fizzbuzz(n)
    assert got == exp, f"fizzbuzz({n})={got!r} != {exp!r}"
print("ok")
PY
