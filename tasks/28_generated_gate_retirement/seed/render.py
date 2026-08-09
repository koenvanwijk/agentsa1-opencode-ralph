def class_name(signal_name):
    return "".join(part.capitalize() for part in signal_name.split("_"))


def render_config(metadata, template):
    classes = []
    defaults = []
    if metadata.attribute_folding_enabled:
        for name, signal in metadata.signals.items():
            cls = class_name(name) + "Config"
            fields = [f"    enabled: bool = {signal['enabled']!r}"]
            if signal["foldable_attributes"]:
                fields.append("    attributes: tuple[str, ...] = ()")
            classes.append("@dataclass\nclass " + cls + ":\n" + "\n".join(fields))
            defaults.append(f"    {name}: {cls} = field(default_factory={cls})")
    else:
        classes.append("@dataclass\nclass SignalConfig:\n    enabled: bool = False")
        for name, signal in metadata.signals.items():
            defaults.append(
                f"    {name}: SignalConfig = field(default_factory=lambda: SignalConfig(enabled={signal['enabled']!r}))"
            )
    return template.replace("{{CONFIG_CLASSES}}", "\n\n".join(classes)).replace(
        "{{DEFAULT_CONFIG}}", "\n".join(defaults)
    )


def render_runtime(metadata, template):
    blocks = []
    for name, signal in metadata.signals.items():
        cls = class_name(name) + "Runtime"
        if metadata.attribute_folding_enabled and signal["foldable_attributes"]:
            body = (
                "    def fold_key(self, point):\n"
                "        dropped = set(self.config.attributes)\n"
                "        return tuple(sorted((k, v) for k, v in point.items() if k not in dropped))"
            )
        else:
            body = "    def fold_key(self, point):\n        return tuple(sorted(point.items()))"
        blocks.append(
            f"class {cls}:\n    def __init__(self, config):\n        self.config = config\n\n{body}"
        )
    return template.replace("{{RUNTIME_CLASSES}}", "\n\n".join(blocks))

