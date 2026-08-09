import java.util.Map;

public final class ProgramFormBuilderTest {
  public static void main(String[] args) {
    SettingsManifest settings =
        new SettingsManifest(Map.of("PARTNER_PROGRAM_CARDS_ENABLED", true));
    ProgramFormBuilder builder = new ProgramFormBuilder("https://example.test", settings);
    assert builder.availableProgramTypes().contains(ProgramType.EXTERNAL);
    assert builder
        .buildProgramSlugFieldForPartnerProgramsRollout(
            "benefit finder", true, ProgramType.EXTERNAL)
        .contains("external program ID");
  }
}

