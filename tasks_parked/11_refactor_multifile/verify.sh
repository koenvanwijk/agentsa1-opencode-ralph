#!/bin/bash
# verify.sh <workdir> — multi-file refactor: slugify moved to utils.py, imported in app.py
W="$1"
[ -f "$W/utils.py" ] || { echo "no utils.py"; exit 1; }
grep -q "def slugify" "$W/utils.py" || { echo "slugify not in utils.py"; exit 1; }
grep -q "def slugify" "$W/app.py" && { echo "slugify still defined in app.py"; exit 1; }
grep -qE "from utils import|import utils" "$W/app.py" || { echo "app.py does not import from utils"; exit 1; }
( cd "$W" && python3 -c "import app, utils; assert app.slugify('Hello World')=='hello-world'; assert utils.slugify('A B C')=='a-b-c'; assert app.greeting('X')=='Hello, X!'; print('ok')" )
