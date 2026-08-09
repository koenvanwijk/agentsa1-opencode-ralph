import java.util.List;

public class ProgramFormBuilder {
  private final SettingsManifest settingsManifest;
  private final String baseUrl;

  public ProgramFormBuilder(String baseUrl, SettingsManifest settingsManifest) {
    this.baseUrl = baseUrl;
    this.settingsManifest = settingsManifest;
  }

  public List<ProgramType> availableProgramTypes() {
    if (settingsManifest.getPartnerProgramCardsEnabled()) {
      return List.of(ProgramType.DEFAULT, ProgramType.EXTERNAL, ProgramType.PRE_SCREENER_FORM);
    }
    return List.of(ProgramType.DEFAULT, ProgramType.PRE_SCREENER_FORM);
  }

  public String buildProgramSlugField(String adminName, boolean creating) {
    if (!settingsManifest.getPartnerProgramCardsEnabled()) {
      return creating
          ? "Enter an identifier used in this program's applicant-facing URL"
          : baseUrl + "/programs/" + slugify(adminName);
    }
    return buildProgramSlugFieldForPartnerProgramsRollout(
        adminName, creating, ProgramType.DEFAULT);
  }

  public String buildProgramSlugFieldForPartnerProgramsRollout(
      String adminName, boolean creating, ProgramType programType) {
    if (creating) {
      return programType == ProgramType.EXTERNAL
          ? "Enter the external program ID"
          : "Enter the hosted program URL identifier";
    }
    return programType == ProgramType.EXTERNAL
        ? "The external program ID can't be changed"
        : baseUrl + "/programs/" + slugify(adminName);
  }

  private static String slugify(String value) {
    return value.toLowerCase().replace(' ', '-');
  }
}

