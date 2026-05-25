# Elpris Widget

Beregner og viser den faktiske, time-for-time danske elpris for:
- **Adresse:** Brænderigården 7, 2. tv, 7500 Holstebro
- **Prisområde:** DK1 (vest for Storebælt)
- **Netselskab:** L-net (kan ikke vælges, bestemt af adressen)
- **Elleverandør:** Gasel "El til børspris + 6 øre/kWh" (timeafregnet, ingen binding, 0 kr. leverandørabonnement)

## Mål
Hent spotprisen pr. time og læg de faste komponenter på, så widget'en viser den reelle
all-in kWh-pris for hver time i døgnet. Brugeren kan ikke flytte sit forbrug, så formålet
er overblik og prisindsigt, ikke forbrugsstyring.

## Datakilde
Spotpris pr. time fra elprisenligenu.dk (gratis, ingen nøgle):
```
GET https://www.elprisenligenu.dk/api/v1/prices/[YYYY]/[MM]-[DD]_DK1.json
```
Returnerer et array med `DKK_per_kWh` pr. time (ekskl. moms og afgifter).
Morgendagens priser er tilgængelige fra ca. kl. 13.

## Prisberegning
`docs/elpris-spec.md` er den eneste sandhed for alle konstanter og formler. Kort:
```
var_ekskl_moms  = spotpris + 6.00 + l_net_tarif(time, sæson) + 21.34 + 0.80
var_inkl_moms   = var_ekskl_moms × 1.25
fast_pr_kwh     = 934 / aarsforbrug × 100        # L-net netabonnement, inkl. moms
allin_inkl_moms = var_inkl_moms + fast_pr_kwh
```
Alle tal er krydstjekket mod Gasels og L-nets officielle visning (maj 2026).
Brug ALTID den faktiske timepris, aldrig et månedsgennemsnit (produktet er timeafregnet).

## Kodeprincipper (gælder al kode i dette repo)
1. Simpelt slår komplekst. Ingen overengineering.
2. Ingen fallbacks: én korrekt vej, ingen alternativer.
3. Én måde at gøre tingene på, ikke mange.
4. Klarhed slår bagudkompatibilitet.
5. Fail fast: kast fejl når forudsætninger ikke er opfyldt.
6. Ingen backups: stol på den primære mekanisme.
7. Fix root cause, ikke symptomer.
8. Udvid ikke scope. Løs det der bliver bedt om; nævn tilstødende problemer separat.
9. Minimale kommentarer, kun hvor logikken ikke er åbenlys.

## Implementeringsbeslutninger (fastlagt)
- **Teknologi:** Vanilla HTML/JS/CSS — iCUE Widget Builder format (zip med `index.html` + `manifest.json`)
- **Visning:** Hele døgnet, 24 timer fast 00–23, Warm Amber dark-mode design
- **Årsforbruget:** Hardcoded 1.900 kWh
- Se `docs/plan.md` for fuld plan inkl. design-tokens og layout

## iCUE Widget Builder dokumentation
Corsair/Elgato's officielle widget-dokumentation ligger i `Corsair Downloads/WidgetBuilder/`:
- `docs/` — widget-koncepter, controls, plugins
- `references/` — tekniske referencer (manifest, meta-tags, responsive scaling, sikkerhed)
- `skill.md` — installeret som `.claude/commands/icue-widget-builder.md`

Brug `/icue-widget-builder` for at aktivere skillens workflow ved widget-arbejde.

## Vedligehold (skal opdateres når kilderne ændrer sig)
- **L-net tariffer:** skifter typisk 1. april (sommer) og 1. oktober (vinter).
  Hent ny PDF fra https://www.l-net.dk/priser-og-gebyrer/
- **Energinet/TSO-tariffer:** justeres kvartalsvist. Tjek mod en faktisk leverandørvisning.
- **Elafgift:** 0,80 øre/kWh ekskl. moms gælder kun 2026–2027 (grøn skattereform, lov L24).
- **Netabonnement:** 934 kr./år inkl. moms (L-net C-tarif).
