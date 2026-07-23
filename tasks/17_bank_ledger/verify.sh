#!/bin/bash
# verify.sh <workdir> — exact ledger replay over 3 log files (4200 lines) + accounts.csv.
# Discriminators: strict field/amount/id parsing (leading zeros, tabs, trailing
# space, case), malformed-vs-rejected distinction, overdraft strictness (equal
# allowed: A1012 drained to exactly 0), self-transfer reject, unknown-account
# reject on all three ops, cross-file processing order, near-EOF lines
# (2024-03.log:1398 valid deposit, :1400 rejected), tie A1013/A1014, dollar
# formatting from integer cents, dual exact output files.
W="$1"
[ -f "$W/statement.txt" ] || { echo "no statement.txt"; exit 1; }
[ -f "$W/rejected.txt" ]  || { echo "no rejected.txt"; exit 1; }
python3 - "$W" << 'PY'
import sys
expected_statement = """A1005 erin $7983.83
A1007 grace $7374.32
A1004 dave $6576.80
A1009 ivan $6404.89
A1003 carol $6036.78
A1006 frank $5514.51
A1011 mallory $5445.06
A1010 judy $5002.18
A1001 alice $4101.38
A1002 bob $3811.42
A1008 heidi $3156.88
A1013 peggy $1234.56
A1014 quinn $1234.56
A1012 oscar $0.00"""
expected_rejected = """2024-01.log:611 DEPOSIT
2024-01.log:778 WITHDRAW
2024-01.log:1380 TRANSFER
2024-02.log:402 WITHDRAW
2024-02.log:556 TRANSFER
2024-02.log:900 TRANSFER
2024-03.log:501 TRANSFER
2024-03.log:1396 WITHDRAW
2024-03.log:1400 WITHDRAW"""
ok = True
for fname, expected in (("statement.txt", expected_statement),
                        ("rejected.txt", expected_rejected)):
    got = open(f"{sys.argv[1]}/{fname}").read()
    if got.rstrip("\n") != expected:
        print(f"{fname} does not match expected output")
        print("--- got ---")
        print(got)
        ok = False
if not ok:
    sys.exit(1)
print("ok")
PY
