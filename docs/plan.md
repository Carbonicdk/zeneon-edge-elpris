# Implementeringsplan: Xeneon Edge Elpris Widget

## Beslutninger

| Emne | Valg |
|---|---|
| Visning | Hele døgnet — 24 timer, 00–23, fast rækkefølge |
| Årsforbruget | Hardcoded 1.900 kWh |
| Teknologi | Vanilla HTML/JS/CSS (ingen build-trin, ingen dependencies) |
| Design | Warm Amber — se nedenfor |

---

## Filstruktur

```
widget/
├── index.html          — al logik, SVG-rendering og animation
├── manifest.json       — iCUE widget-metadata
└── resources/
    └── icon.svg        — hvid enkeltfarvet SVG, transparent baggrund
```

Pakkes som zip til iCUE Widget Builder.

---

## Warm Amber design

Designet er baseret på Claude Design-mockup (2026-05-25), Warm Amber-varianten.

### Farver

| Token | Værdi |
|---|---|
| Baggrund | `#0e0a08` |
| Baggrund overlay | `radial-gradient(ellipse 80% 60% at 30% 120%, rgba(217,119,87,0.18), transparent 60%), radial-gradient(ellipse 70% 50% at 80% -20%, rgba(217,119,87,0.10), transparent 60%)` |
| Tekst | `#f6efe8` |
| Tekst dæmpet | `rgba(246,239,232,0.45)` |
| Grid-linjer | `rgba(246,239,232,0.07)` |
| Søjle (spot-del) | `#b8542e` |
| Søjle (tarif-cap) | `#e89668` |
| Nuværende time (spot) | `#ffd166` |
| Nuværende time (tarif) | `#fff2c2` |
| Nuværende time outline | `#ffe27a` |
| Nuværende time label | `#ffe27a` |
| Glow-farve | `#ffd166` |

### Layout (designrum, 2560×720)

```
padding: top 64 · right 80 · bottom 80 · left 180
barGap: 18 px
barWidth: (plotW − 23 × 18) / 24
```

### Visuelle elementer

- **Stacked bars:** Søjlen er todelt — spot-del (bundfarve `#b8542e`) + tarif-cap (lysere `#e89668`). To-tonen læses som "lagt ovenpå", ikke som et hul.
- **Nuværende time:** Gylden farve (`#ffd166`) + pulserende glow-filter (`feGaussianBlur stdDeviation=14`, opacity 0.25→0.75→0.25, 2.2s) + hvid outline (2px) + **"NU"-pille** under x-akse-label.
- **Y-akse:** Ticks ved 0, 0.25, 0.50 … kr/kWh. Baseline solid, øvrige stiplede (`2 6`). Labels venstre for plot.
- **X-akse:** Time-labels 00–23, nuværende time fed + lysere farve.
- **Titel:** `Elpris · 24 t · DK1` øverst venstre, versaler, dæmpet farve.

---

## Prisberegning

Kilde: `docs/elpris-spec.md` — ingen afvigelser tilladt.

```
TILLAEG      = 6.00        # Gasel (øre/kWh)
ENERGINET    = 21.34       # nettarif + systemtarif + TSO (øre/kWh)
ELAFGIFT     = 0.80        # øre/kWh (2026–2027)
AARSFORBRUG  = 1900        # kWh/år

var_ekskl = spotpris + TILLAEG + l_net_tarif(time, måned) + ENERGINET + ELAFGIFT
var_inkl  = var_ekskl × 1.25
fast_kwh  = 934 / AARSFORBRUG × 100    # = 49,16 øre/kWh
allin     = var_inkl + fast_kwh
```

**Dataformat til SVG-rendering:**
```js
{ hour, spot: allin_inkl_moms, total: allin_inkl_moms }
// spot = variabel del (var_inkl), total = allin (inkl. fast netabonnement)
// Tarif-cap = total − spot = fast_kwh = 49,16 øre/kWh (konstant)
```

**L-net tarif-tabel** (ekskl. moms, pr. 1. maj 2026):

| Periode | Lavlast 00–05 | Højlast 06–16, 21–23 | Spidslast 17–20 |
|---|---|---|---|
| Sommer (apr–sep) | 5,34 | 8,01 | 20,82 |
| Vinter (okt–mar) | 5,34 | 16,02 | 48,05 |

---

## Datahentning

```
GET https://www.elprisenligenu.dk/api/v1/prices/YYYY/MM-DD_DK1.json
```

- Ingen API-nøgle. Ingen persondata sendes.
- Henter dagens priser ved opstart.
- Hvis `Date.now()` > kl. 13:00 lokal tid: hent også morgendagens priser (vises ikke i v1).
- Refresh: ved midnat (ny dag) og ved opstart.
- Fejlhåndtering: vis "Ingen data" tekst i plot-området.

---

## Responsive størrelser (Xeneon Edge `dashboard_lcd`)

| Størrelse | Opløsning | Tilpasning |
|---|---|---|
| Small | 840×344 | `transform: scale(840/2560)` på SVG |
| Medium | 840×696 | scale + øget padding top |
| Large | 1688×696 | scale |
| XL | 2536×696 | ~1:1 |

SVG'en er designet i 2560×720 og skaleres med `viewBox` + `preserveAspectRatio="xMidYMid meet"` så den passer i alle størrelser automatisk.

---

## manifest.json (nøglefelter)

```json
{
  "id": "dk.carbonicdk.elpris",
  "name": "Elpris DK1",
  "description": "Time-for-time elpris inkl. alle afgifter og tariffer (Gasel/L-net/DK1)",
  "version": "1.0.0",
  "supported_devices": [{ "type": "dashboard_lcd" }],
  "interactive": false
}
```

---

## Rækkefølge

1. `manifest.json` + `resources/icon.svg`
2. Prisberegning i JS (`calcPrice(spotOere, hour, month)`)
3. Data-fetch + parsing
4. SVG-rendering (statisk, ingen animation endnu)
5. Warm Amber farver + layout
6. Pulserende glow-animation på nuværende time
7. Test i browser ved alle 4 Xeneon Edge-størrelser
8. Pak som zip og test i iCUE Widget Builder
