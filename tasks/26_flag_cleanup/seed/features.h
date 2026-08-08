#ifndef FEATURES_H
#define FEATURES_H

typedef enum {
    FEATURE_DARK_MODE,
    FEATURE_BETA_SEARCH,
    FEATURE_MULTI_REGION,
    FEATURE_LEGACY_EXPORT, /* unused: superseded CSV export path */
    FEATURE_OLD_BILLING,   /* unused: pre-2021 billing engine */
    FEATURE__COUNT
} feature_t;

const char *feature_name(feature_t f);

#endif /* FEATURES_H */
