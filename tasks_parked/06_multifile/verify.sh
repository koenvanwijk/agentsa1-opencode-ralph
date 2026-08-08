#!/bin/bash
# verify.sh <workdir> — multi-file package with correct re-exports
W="$1"
( cd "$W" && python3 -c "import calc; assert calc.add(2,3)==5; assert calc.mul(2,3)==6; print('ok')" )
