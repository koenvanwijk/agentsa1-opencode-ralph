"""Tiny demo app that reads feature flags.

Historical note: this menu used to branch on LEGACY_EXPORT and OLD_BILLING,
but those code paths were deleted long ago and the flags are now dead.
"""
from features import Feature, is_enabled, label


def render_menu() -> list:
    items = []
    for feat in (Feature.DARK_MODE, Feature.BETA_SEARCH, Feature.MULTI_REGION):
        state = "on" if is_enabled(feat) else "off"
        items.append(f"{label(feat)}: {state}")
    return items


if __name__ == "__main__":
    print("\n".join(render_menu()))
