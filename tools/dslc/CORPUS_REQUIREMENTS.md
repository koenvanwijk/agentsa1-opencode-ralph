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
  "examples_good": "examples/good/"
}
```

`examples_bad` is **optioneel** — zie §4: de slechte voorbeelden worden normaal
door de loop afgeleid uit de goede, niet extern aangeleverd. Neem het alleen op
als je met de hand een edge-case-bad-voorbeeld toevoegt.

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
    good/*.<ext>          # geldige voorbeelden — de EXTERNE deliverable (grondwaarheid)
    bad/                  # OPTIONEEL: alleen met de hand toegevoegde edge cases
      *.<ext>             #   (normaal leidt de loop de bad-set af, zie §4)
      *.expect            #   sidecar met de verwachte diagnose
```

Zie [`corpus_template/flags/`](./corpus_template/flags/) voor een volledig
ingevuld voorbeeld (inclusief afgeleide-bad-voorbeelden ter illustratie).

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

Dit deel bepaalt of de kwaliteitspoort werkt. **Belangrijk: de goede voorbeelden
zijn de grondwaarheid; de slechte worden daaruit afgeleid, niet verzonnen.**

### Geldige voorbeelden (`examples/good/`) — de externe deliverable
Dit is het enige voorbeeld-materiaal dat de externe corpus-taak hoeft te leveren.
Prima om ze uit een bestaand archief te halen.
- **Self-contained en compileerbaar in isolatie** — geen externe deps, geen
  impliciete context. Anders is de linter-selftest onbetrouwbaar.
- **Coverage**: elk construct uit `spec/grammar.md` heeft ≥ 1 geldig voorbeeld.
  Ongedekte constructen kan de linter niet leren.
- **Minimaal per feature is de voorkeur** (kleinste voorbeeld dat één construct
  toont) — het levert schone snippets voor de cheatsheet. Grote, echte
  archief-bestanden mogen ook: ze dienen als accept-test; de builder distilleert
  er zelf minimale snippets uit voor de cheatsheet.

### Ongeldige voorbeelden — AFGELEID, niet aangeleverd
Slechte voorbeelden komen **niet** uit het archief (dat bevat ze niet) en worden
**niet** vrij door de LLM verzonnen. De loop genereert ze deterministisch met
per-rule-id **mutatie-operatoren**: neem een geldig `good/`-bestand en breek het
op precies één manier (bijv. `DUPLICATE_FEATURE` = dupliceer het eerste blok;
`BAD_DEFAULT` = vervang `default on` door een ongeldige waarde).

- De mutator kent de geïnjecteerde fout, dus hij emit de `.expect` zelf:
  ```
  expect-error: DUPLICATE_FEATURE at line 7
  ```
  → één fout per voorbeeld, en "bevat exact die fout, verder geldig" geldt
  **per constructie** (acceptatiecriterium #5 wordt automatisch waar).
- **Elke rule-id uit de fout-catalogus (§5) krijgt zo ≥ 1 bad-voorbeeld.** De
  testset: alle `good` moeten passeren, elk afgeleid `bad` moet falen met de
  verwachte rule-id.
- Alleen fouten die mutatie niet kan synthetiseren mogen als *herzien*
  `examples/bad/`-voorbeeld met de hand worden toegevoegd — nooit blind
  LLM-gegenereerd.

### Trust-grens (waarom afgeleid, niet LLM-verzonnen)
De testset die de linter beoordeelt moet **onafhankelijk** zijn van de LLM die de
linter maakt. Zou de LLM zowel de linter áls de slechte voorbeelden leveren, dan
keurt een mogelijk-gehallucineerde linter zichzelf goed met een
mogelijk-gehallucineerde testset (circulair). Daarom:

| artefact | bron | vertrouwd omdat |
|---|---|---|
| goede voorbeelden | extern archief (curated) | grondwaarheid, review |
| mutatie-operatoren | kleine, herziene tooling in `dslc` | triviaal per stuk te controleren |
| afgeleide slechte voorbeelden + `.expect` | mutator | correct per constructie |
| **linter/grammar + cheatsheet** | **LLM (builder)** | **wordt tegen bovenstaande getest** |

De LLM mag hooguit mutatie-operatoren *voorstellen*; elke operator is klein genoeg
om met de hand te reviewen voordat hij deel van de vertrouwde tooling wordt.

## 5. Fout-catalogus — `spec/common-mistakes.md`

De veelgemaakte fouten, elk met:
- een **stabiele rule-id** in `UPPER_SNAKE_CASE` (bijv. `DUPLICATE_FEATURE`);
- een korte uitleg;
- een minimaal **fout ↔ goed** paar.

Dezelfde rule-ids worden gebruikt in (a) de linter-diagnoses, (b) het
"veelgemaakte fouten"-blok van de cheatsheet — precies waar een klein model op
struikelt — (c) de `.expect`-bestanden, en (d) de mutatie-operatoren (§4): elke
rule-id ↔ één operator die die fout in een `good/`-bestand injecteert. Alle vier
moeten identieke ids gebruiken.

## 6. Governance (org-regels)

- Alleen materiaal waarvan ICT de IP-rechten heeft.
- Geen vertrouwelijke (R1/R2) of persoonsgegevens in spec of voorbeelden —
  voorbeelden synthetisch/geanonimiseerd houden.
- Geen secrets/credentials in voorbeelden (ze worden in de loop gecompileerd).

---

## Acceptatiecriterium

De **externe** corpus-taak is klaar voor een DSL wanneer:

1. `manifest.json` valideert tegen `manifest.schema.json` en alle paden bestaan;
2. elk construct uit `spec/grammar.md` ≥ 1 `good/`-voorbeeld heeft;
3. `spec/common-mistakes.md` elke fout een stabiele rule-id + een minimaal
   fout↔goed paar geeft (dit voedt de mutatie-operatoren);
4. alle `good/`-voorbeelden bevestigd geldig zijn (referentie-parser of review) —
   zij zijn de grondwaarheid.

De **loop** levert daarna (buiten de externe deliverable):

5. per rule-id een mutatie-operator die de fout in een `good/`-bestand injecteert
   en de bijbehorende `.expect` emit — waarmee de afgeleide bad-set per
   constructie "exact die fout, verder geldig" is;
6. de gegenereerde linter + cheatsheet, gevalideerd via `dslc selftest`: alle
   `good` passeren, elk afgeleid `bad` faalt met de verwachte rule-id.

Pas na een groene `dslc selftest` gaat de gebruikelijke keep/rollback-poort de
assets scoren op de echte DSL-taken.

> **Status (`flags`).** Deliverables 5 en 6 zijn geïmplementeerd voor de
> `flags`-DSL: de mutatie-operatoren staan in [`mutators/flags.py`](./mutators/flags.py)
> (één per rule-id, los van de linter — de trust-grens) en de poort draait via
> `python3 dslc.py selftest` (groen: 2/2 good, 16 afgeleide bad-mutanten, 8
> rule-ids). De linter `grammars/flags.py` emit nu stabiele `[RULE_ID]`-tags. Het
> enige nog niet-geautomatiseerde stuk is de **builder** die linter+cheatsheet
> zélf uit de corpus genereert; hier is de linter met de hand geschreven en wordt
> hij door dezelfde poort getoetst.
