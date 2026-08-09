#!/bin/bash
set -euo pipefail
W="$1"
T="$(cd "$(dirname "$0")" && pwd)"

fail() { echo "GATE-FAIL: $*" >&2; exit 1; }

required=(
  SettingsManifest.java ProgramType.java ApplicantService.java
  ProgramFormBuilder.java ProgramMetaDataEditView.java ProgramNewOneView.java
  ProgramFormBuilderTest.java env-var-docs.json feature-flags.conf FLAGS.md check.sh
)
for f in "${required[@]}"; do
  [ -f "$W/$f" ] || fail "required file missing: $f"
done

# No answer tree or Git repository is present in a trial. Reject attempts to add
# either, and reject every common spelling of the retired flag across text files.
[ ! -e "$W/.git" ] || fail "trial must remain history-free"
[ ! -e "$W/after" ] || fail "answer/after directory is not allowed"

if grep -RniE --exclude='*.class' --exclude-dir=build \
  'PARTNER_PROGRAM_CARDS_ENABLED|partner_program_cards_enabled|partnerProgramCardsEnabled|getPartnerProgramCardsEnabled|partner program cards feature|partner-program-card(s)? feature flag' \
  "$W" >/dev/null; then
  grep -RniE --exclude='*.class' --exclude-dir=build \
    'PARTNER_PROGRAM_CARDS_ENABLED|partner_program_cards_enabled|partnerProgramCardsEnabled|getPartnerProgramCardsEnabled|partner program cards feature|partner-program-card(s)? feature flag' \
    "$W" >&2 || true
  fail "retired flag or rollout wording remains"
fi

# Preserve the unrelated setting in code, config, and docs.
grep -q 'PROGRAM_SLUG_URLS_ENABLED' "$W/SettingsManifest.java" \
  || fail "unrelated Java setting was removed"
grep -q 'PROGRAM_SLUG_URLS_ENABLED' "$W/env-var-docs.json" \
  || fail "unrelated environment-variable documentation was removed"
grep -q 'PROGRAM_SLUG_URLS_ENABLED' "$W/feature-flags.conf" \
  || fail "unrelated configuration was removed"
grep -q 'PROGRAM_SLUG_URLS_ENABLED' "$W/FLAGS.md" \
  || fail "unrelated human documentation was removed"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$W"/*.java "$tmp/"

python3 - "$W" <<'PY' || fail "Java source invariant checks failed"
from pathlib import Path
import re, sys
w = Path(sys.argv[1])

for path in w.glob("*.java"):
    text = path.read_text()
    assert text.count("{") == text.count("}"), f"unbalanced braces in {path.name}"
    assert text.count("(") == text.count(")"), f"unbalanced parentheses in {path.name}"
    assert re.search(rf"public (?:final )?(?:class|enum) {re.escape(path.stem)}\b", text)

app = (w / "ApplicantService.java").read_text()
assert re.search(r"public\s+ApplicantService\s*\(\s*\)", app)
assert "SettingsManifest" not in app
assert "ProgramType.DEFAULT" in app and "ProgramType.EXTERNAL" in app
assert "ProgramType.PRE_SCREENER_FORM" not in re.search(
    r"relevantPrograms\s*\([^)]*\)\s*\{(.*)\n\s*\}", app, re.S
).group(1).split("return relevant", 1)[0]

builder = (w / "ProgramFormBuilder.java").read_text()
assert "SettingsManifest" not in builder
assert re.search(r"public\s+ProgramFormBuilder\s*\(\s*String\s+baseUrl\s*\)", builder)
assert re.search(
    r"buildProgramSlugField\s*\(\s*String\s+adminName\s*,\s*boolean\s+creating\s*,\s*ProgramType\s+programType\s*\)",
    builder,
)
assert all(name in builder for name in (
    "ProgramType.DEFAULT", "ProgramType.EXTERNAL", "ProgramType.PRE_SCREENER_FORM"
))
assert "external program ID" in builder
assert "hosted program URL identifier" in builder
assert 'baseUrl + "/programs/" + slugify(adminName)' in builder

for name in ("ProgramMetaDataEditView", "ProgramNewOneView"):
    text = (w / f"{name}.java").read_text()
    assert "SettingsManifest" not in text
    assert re.search(rf"public\s+{name}\s*\(\s*String\s+baseUrl\s*\)", text)
    assert "super(baseUrl);" in text
PY

if command -v javac >/dev/null 2>&1; then
  cat >"$tmp/HiddenBehaviorTest.java" <<'JAVA'
import java.lang.reflect.Constructor;
import java.util.List;
import java.util.Map;

public final class HiddenBehaviorTest {
  private static void require(boolean value, String message) {
    if (!value) throw new AssertionError(message);
  }

  public static void main(String[] args) throws Exception {
    Constructor<ApplicantService> applicantCtor = ApplicantService.class.getConstructor();
    ApplicantService service = applicantCtor.newInstance();
    List<ProgramType> result = service.relevantPrograms(
        List.of(ProgramType.DEFAULT, ProgramType.EXTERNAL, ProgramType.PRE_SCREENER_FORM));
    require(result.equals(List.of(ProgramType.DEFAULT, ProgramType.EXTERNAL)),
        "external programs must be permanently visible without a settings dependency");

    Constructor<ProgramFormBuilder> builderCtor =
        ProgramFormBuilder.class.getConstructor(String.class);
    ProgramFormBuilder builder = builderCtor.newInstance("https://example.test");
    require(builder.availableProgramTypes().equals(
        List.of(ProgramType.DEFAULT, ProgramType.EXTERNAL, ProgramType.PRE_SCREENER_FORM)),
        "all three program types must remain available");
    require(builder.buildProgramSlugField("benefit finder", true, ProgramType.EXTERNAL)
        .contains("external program ID"), "external creation label changed");
    require(builder.buildProgramSlugField("benefit finder", true, ProgramType.DEFAULT)
        .contains("hosted program URL identifier"), "default creation label changed");
    require(builder.buildProgramSlugField("Benefit Finder", false, ProgramType.DEFAULT)
        .equals("https://example.test/programs/benefit-finder"), "default edit URL changed");

    new ProgramMetaDataEditView("https://example.test");
    new ProgramNewOneView("https://example.test");

    SettingsManifest settings = new SettingsManifest(Map.of("PROGRAM_SLUG_URLS_ENABLED", true));
    require(settings.getProgramSlugUrlsEnabled(), "unrelated setting behaviour changed");
    for (String description : SettingsManifest.settingDescriptions()) {
      require(!description.toLowerCase().contains("external"),
          "retired setting description remains");
    }
  }
}
JAVA

  (cd "$tmp" && javac -Xlint:all *.java && java -ea HiddenBehaviorTest) \
    || fail "Java compilation or hidden behaviour checks failed"
fi

python3 - "$W/env-var-docs.json" <<'PY' || fail "JSON structure check failed"
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
settings = data.get("settings", {})
assert list(settings) == ["PROGRAM_SLUG_URLS_ENABLED"]
assert settings["PROGRAM_SLUG_URLS_ENABLED"] == {
    "mode": "ADMIN_READABLE",
    "description": "Enable URLs with program slugs.",
    "type": "bool",
    "required": False,
}
PY

# The supplied visible check must still be useful and executable.
(cd "$W" && bash ./check.sh) >/dev/null \
  || fail "supplied check.sh failed"

echo "GATE-PASS: history-free cross-stack flag retirement is complete" >&2
