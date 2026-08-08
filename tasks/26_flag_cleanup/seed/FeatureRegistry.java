import java.util.EnumSet;
import java.util.Set;

public class FeatureRegistry {
    private static final Set<Feature> ENABLED =
        EnumSet.of(Feature.DARK_MODE, Feature.MULTI_REGION);

    public static boolean isEnabled(Feature f) {
        return ENABLED.contains(f);
    }

    public static String label(Feature f) {
        switch (f) {
            case DARK_MODE:     return "Dark mode";
            case BETA_SEARCH:   return "Beta search";
            case MULTI_REGION:  return "Multi-region";
            case LEGACY_EXPORT: return "Legacy export (off)";
            case OLD_BILLING:   return "Old billing (off)";
            default:            return "?";
        }
    }
}
