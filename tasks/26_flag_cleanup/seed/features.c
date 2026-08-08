#include "features.h"

const char *feature_name(feature_t f) {
    switch (f) {
        case FEATURE_DARK_MODE:     return "dark_mode";
        case FEATURE_BETA_SEARCH:   return "beta_search";
        case FEATURE_MULTI_REGION:  return "multi_region";
        case FEATURE_LEGACY_EXPORT: return "legacy_export";
        case FEATURE_OLD_BILLING:   return "old_billing";
        case FEATURE__COUNT:
        default:                    return "unknown";
    }
}
