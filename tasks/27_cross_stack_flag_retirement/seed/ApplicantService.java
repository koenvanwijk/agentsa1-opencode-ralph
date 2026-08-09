import java.util.ArrayList;
import java.util.List;

public final class ApplicantService {
  private final SettingsManifest settingsManifest;

  public ApplicantService(SettingsManifest settingsManifest) {
    this.settingsManifest = settingsManifest;
  }

  public List<ProgramType> relevantPrograms(List<ProgramType> programs) {
    List<ProgramType> relevant = new ArrayList<>();
    for (ProgramType programType : programs) {
      if (programType == ProgramType.DEFAULT
          || (programType == ProgramType.EXTERNAL
              && settingsManifest.getPartnerProgramCardsEnabled())) {
        relevant.add(programType);
      }
    }
    return relevant;
  }
}

