#!/bin/bash
# verify.sh <workdir> — transactional WAL replay over 4 files (6850 lines) + snapshot.txt.
# Discriminators: strict field/key/value parsing (leading zeros, tabs, double/
# trailing/leading spaces, case, sign, decimal, hex), transaction working-copy
# semantics (rolled-back SET/DEL/drain must not leak: ghost, apple, banana),
# rejection checked against the working copy (ADD apple after in-txn DEL),
# rejects logged even inside rolled-back/dangling txns (02:170, 04:1760/1770),
# nested-BEGIN / no-txn COMMIT/ROLLBACK rejects, txn spanning the 02->03 file
# boundary (nutmeg deleted, bonus created), DANGLING txn at EOF discarded and
# not counted as rolled back (cherry survives, phantom absent, apple not
# +999999), lowercase `rollback`/`commit` as the last lines (case-insensitive
# parsers corrupt state AND stats), equal-value SUB drains zilch to exactly 0,
# off-by-one overdraft (02:520), tie tiea/tieb, malformed-line COUNT in
# stats.txt, triple exact output files.
W="$1"
for f in final.txt rejected.txt stats.txt; do
  [ -f "$W/$f" ] || { echo "no $f"; exit 1; }
done
python3 - "$W" << 'PY'
import sys
expected_final = """apple 97814
bonus 59505
lemon 58990
mango 54998
kiwi 51737
cherry 45253
durian 42225
grape 19997
banana 16088
honey 14377
elder 13795
tiea 7777
tieb 7777
zilch 0"""
expected_rejected = """01.wal:200 COMMIT
01.wal:431 BEGIN
01.wal:640 DEL
01.wal:800 SUB
01.wal:1450 ROLLBACK
02.wal:170 ADD
02.wal:520 SUB
02.wal:1050 DEL
03.wal:25 ADD
03.wal:380 COMMIT
03.wal:800 SUB
03.wal:1500 SUB
04.wal:450 SUB
04.wal:900 ROLLBACK
04.wal:1760 SUB
04.wal:1770 BEGIN"""
expected_stats = """malformed 27
rejected 16
committed 5
rolled_back 3"""
ok = True
for fname, expected in (("final.txt", expected_final),
                        ("rejected.txt", expected_rejected),
                        ("stats.txt", expected_stats)):
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
