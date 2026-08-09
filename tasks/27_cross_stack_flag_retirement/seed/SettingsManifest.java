import java.util.Map;

public final class SettingsManifest {
  private final Map<String, Boolean> settings;

  public SettingsManifest(Map<String, Boolean> settings) {
    this.settings = settings;
  }

  public boolean getPartnerProgramCardsEnabled() {
    return settings.getOrDefault("PARTNER_PROGRAM_CARDS_ENABLED", true);
  }

  public boolean getProgramSlugUrlsEnabled() {
    return settings.getOrDefault("PROGRAM_SLUG_URLS_ENABLED", false);
  }

  public static String[] settingDescriptions() {
    return new String[] {
      "PARTNER_PROGRAM_CARDS_ENABLED: Enable showing partner program cards.",
      "PROGRAM_SLUG_URLS_ENABLED: Enable URLs with program slugs."
    };
  }
}

