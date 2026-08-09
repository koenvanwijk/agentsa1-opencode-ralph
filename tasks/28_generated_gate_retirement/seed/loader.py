from dataclasses import dataclass
import json
from pathlib import Path

import yaml


@dataclass(frozen=True)
class Metadata:
    component: str
    description: str
    attribute_folding_enabled: bool
    signals: dict


def load_metadata(path):
    raw = yaml.safe_load(Path(path).read_text())
    schema = json.loads(Path(__file__).with_name("metadata-schema.json").read_text())
    unknown = set(raw) - set(schema["allowed_top_level"])
    missing = set(schema["required_top_level"]) - set(raw)
    if unknown:
        raise ValueError(f"unknown metadata keys: {sorted(unknown)}")
    if missing:
        raise ValueError(f"missing metadata keys: {sorted(missing)}")
    return Metadata(
        component=raw["component"],
        description=raw["description"],
        attribute_folding_enabled=raw.get("attribute_folding_enabled", True),
        signals=raw["signals"],
    )

