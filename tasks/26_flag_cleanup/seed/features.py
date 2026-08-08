from enum import Enum


class Feature(Enum):
    DARK_MODE = "dark_mode"
    BETA_SEARCH = "beta_search"
    MULTI_REGION = "multi_region"
    LEGACY_EXPORT = "legacy_export"   # unused: superseded CSV export path
    OLD_BILLING = "old_billing"       # unused: pre-2021 billing engine


# Module-level list of every flag (kept in sync with the enum on purpose:
# leaving a removed member referenced here breaks `import features`).
ALL_FEATURES = (
    Feature.DARK_MODE,
    Feature.BETA_SEARCH,
    Feature.MULTI_REGION,
    Feature.LEGACY_EXPORT,
    Feature.OLD_BILLING,
)

# Flags the application actually consults at runtime.
ENABLED = {
    Feature.DARK_MODE: True,
    Feature.BETA_SEARCH: False,
    Feature.MULTI_REGION: True,
}


def is_enabled(feature: Feature) -> bool:
    return ENABLED.get(feature, False)


def label(feature: Feature) -> str:
    names = {
        Feature.DARK_MODE: "Dark mode",
        Feature.BETA_SEARCH: "Beta search",
        Feature.MULTI_REGION: "Multi-region",
        Feature.LEGACY_EXPORT: "Legacy export (off)",
        Feature.OLD_BILLING: "Old billing (off)",
    }
    return names.get(feature, "?")
