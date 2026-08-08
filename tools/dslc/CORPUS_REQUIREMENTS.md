# DSL-corpus — requirements

Contract tussen de (externe) documentatie-/voorbeeld-corpus per DSL en de
**builder-stap** van de Ralph-loop. De builder distilleert uit deze corpus
automatisch drie dingen:

1. een **cheatsheet** (`grammars/<naam>.md`) — de wegwijzer die het kleine model
   on-demand ophaalt;
2. een **linter/grammar** (`grammars/<naam>.py`) — de compiler-feedback;
3. de **golden self-test set** — waarmee de gegenereerde linter deterministisch
   wordt gevalideerd vóór hij gecommit wordt.

Elke eis hieronder staat er omdat één van die drie hem nodig heeft. Een DSL die
aan het [acceptatiecriterium](#acceptatiecriterium) voldoet, kan de loop zonder
mensenhand oppakken.

> **Waarom dit een contract is.** De ruwe corpus leeft extern en wordt door een
> aparte taak gevuld. De loop leest hem alleen; hij mag nooit de context van het
> gescoorde model vullen. De dure "lees de hele corpus" gebeurt één keer, in de
> context van de capabele builder, en levert kleine gecachte artefacten op.

---

## 1. Discoverability — `manifest.json` per DSL

De gap-detector moet `extensie → corpus` kunnen mappen zonder giswerk. Elke DSL
levert precies één `manifest.json` in zijn root, gevalideerd tegen
[`manifest.schema.json`](./manifest.schema.json):

```json
{
  "name": "flags",
  "extensions": [".flags"],
  "version": "1.0",
  "spec": "spec/grammar.md",
  "mistakes": "spec/common-mistakes.md",
  "examples_good": "examples/good/",
  "examples_bad": "examples/bad/"
}
```

Zonder manifest weet de loop niet wélke DSL de bottleneck-taak raakt en kan
"stale" (corpus-versie veranderd → assets herbouwen) niet gedetecteerd worden.

## 2. Vaste layout

```
<dsl>/
  manifest.json
  spec/
    grammar.md            # gezaghebbende syntax/regels
    common-mistakes.md    # fout-catalogus met stabiele rule-ids
  examples/
    good/*.<ext>          # geldige, in isolatie compileerbare voorbeelden
    bad/
      *.<ext>             # ongeldige voorbeelden (één fout per bestand)
      *.expect            # verwachte diagnose per bad-voorbeeld (sidecar)
```

Zie [`corpus_template/flags/`](./corpus_template/flags/) voor een volledig
ingevuld voorbeeld.

## 3. De spec (voedt cheatsheet + linter)

- **Gezaghebbend en compleet genoeg om geldig van ongeldig te scheiden** — geen
  marketing-prose, maar de regels: tokens, structuur, constraints,
  verplichte/optionele velden.
- **Gechunkt**: losse bestanden, elk klein genoeg om gericht te lezen (richtlijn
  < ~3.000 tokens per bestand). De builder mag nooit één megadocument moeten
  inladen.
- **Plain text / Markdown** — geen PDF, scans of binaire formaten. Machine-
  leesbaar.
- **Geversioneerd** via `version` in het manifest, zodat "stale" detecteerbaar
  is.

## 4. Voorbeelden — de kern van de golden self-test

Dit deel bepaalt of de kwaliteitspoort werkt.

### Geldige voorbeelden (`examples/good/`)
- **Self-contained en compileerbaar in isolatie** — geen externe deps, geen
  impliciete context. Anders is de linter-selftest onbetrouwbaar.
- **Minimaal per feature**: het kleinste voorbeeld dat één construct toont, niet
  één groot voorbeeld dat alles mengt. Levert schone canonieke snippets voor de
  cheatsheet.
- **Coverage**: elk construct uit `spec/grammar.md` heeft ≥ 1 geldig voorbeeld.
  Ongedekte constructen kan de linter niet leren.

### Ongeldige voorbeelden (`examples/bad/`)
- Bij elk `bad/x.<ext>` hoort een sidecar `x.expect` met de verwachte diagnose —
  de **reden**, niet alleen "faalt":
  ```
  expect-error: DUPLICATE_FEATURE at line 7
  ```
  Meerdere verwachte fouten = meerdere `expect-error:`-regels.
- **Één fout per voorbeeld** — geïsoleerd, zodat de selftest test of de linter om
  de júiste reden afkeurt en niet toevallig.
- **Elke rule-id uit de fout-catalogus (§5) heeft ≥ 1 bad-voorbeeld.** Dit is
  letterlijk de testset: alle `good` moeten passeren, alle `bad` moeten falen met
  de verwachte rule-id.

## 5. Fout-catalogus — `spec/common-mistakes.md`

De veelgemaakte fouten, elk met:
- een **stabiele rule-id** in `UPPER_SNAKE_CASE` (bijv. `DUPLICATE_FEATURE`);
- een korte uitleg;
- een minimaal **fout ↔ goed** paar.

Dezelfde rule-ids worden gebruikt in (a) de linter-diagnoses, (b) het
"veelgemaakte fouten"-blok van de cheatsheet — precies waar een klein model op
struikelt — en (c) de `.expect`-bestanden. De drie moeten identieke ids
gebruiken.

## 6. Governance (org-regels)

- Alleen materiaal waarvan ICT de IP-rechten heeft.
- Geen vertrouwelijke (R1/R2) of persoonsgegevens in spec of voorbeelden —
  voorbeelden synthetisch/geanonimiseerd houden.
- Geen secrets/credentials in voorbeelden (ze worden in de loop gecompileerd).

---

## Acceptatiecriterium

Een DSL-corpus is "klaar" voor de loop wanneer:

1. `manifest.json` valideert tegen `manifest.schema.json` en alle paden bestaan;
2. elk construct uit `spec/grammar.md` ≥ 1 `good/`-voorbeeld heeft;
3. elke rule-id uit `spec/common-mistakes.md` ≥ 1 `bad/`-voorbeeld mét `.expect`
   heeft, en elke `.expect` verwijst naar een bestaande rule-id;
4. alle `good/`-voorbeelden bevestigd geldig zijn (referentie-parser of review) —
   zij zijn de grondwaarheid;
5. alle `bad/`-voorbeelden precies de in hun `.expect` genoemde fout(en) bevatten
   en verder geldig zouden zijn.

Voldoet de corpus hieraan, dan kan de builder er deterministisch een linter +
cheatsheet uit distilleren en zichzelf ertegen valideren via `dslc selftest`.
