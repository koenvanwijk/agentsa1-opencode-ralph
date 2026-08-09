#!/usr/bin/env python3
"""Generic metadata generator driver. Task solutions must not modify this file."""
import argparse
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from loader import load_metadata
from render import render_config, render_runtime


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("metadata", type=Path)
    parser.add_argument("--out", type=Path, default=ROOT / "generated")
    args = parser.parse_args()
    metadata = load_metadata(args.metadata)
    args.out.mkdir(parents=True, exist_ok=True)
    config_template = (ROOT / "templates/config.py.tmpl").read_text()
    runtime_template = (ROOT / "templates/runtime.py.tmpl").read_text()
    (args.out / "config.py").write_text(render_config(metadata, config_template))
    (args.out / "runtime.py").write_text(render_runtime(metadata, runtime_template))


if __name__ == "__main__":
    main()

