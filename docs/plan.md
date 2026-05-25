# Implementation Plan: Xeneon Edge Electricity Price Widget

## Decisions

| Topic | Choice |
|---|---|
| Display | Full day — 24 hours, 00–23, fixed order |
| Annual consumption | Hardcoded 1,900 kWh |
| Technology | Vanilla HTML/JS/CSS (no build step, no dependencies) |
| Design | Warm Amber — see below |

---

## File Structure

```
widget/
├── index.html          — all logic, SVG rendering and animation
├── manifest.json       — iCUE widget metadata
└── resources/
    └── icon.svg        — white single-colour SVG, transparent background
```

Packaged as a zip for iCUE Widget Builder.

---

## Warm Amber Design

Design based on Claude Design mockup (2026-05-25), Warm Amber variant.

### Colours

| Token | Value |
|---|---|
| Background | `#0e0a08` |
| Background overlay | `radial-gradient(ellipse 80% 60% at 30% 120%, rgba(217,119,87,0.18), transparent 60%), radial-gradient(ellipse 70% 50% at 80% -20%, rgba(217,119,87,0.10), transparent 60%)` |
| Text | `#f6efe8` |
| Text muted | `rgba(246,239,232,0.45)` |
| Grid lines | `rgba(246,239,232,0.07)` |
| Bar (spot portion) | `#b8542e` |
| Bar (tariff cap) | `#e89668` |
| Current hour (spot) | `#ffd166` |
| Current hour (tariff) | `#fff2c2` |
| Current hour outline | `#ffe27a` |
| Current hour label | `#ffe27a` |
| Glow colour | `#ffd166` |

### Layout (design space, 2560×720)

```
padding: top 64 · right 80 · bottom 80 · left 180
barGap: 18 px
barWidth: (plotW − 23 × 18) / 24
```

### Visual Elements

- **Stacked bars:** Bar is two-tone — spot portion (base colour `#b8542e`) + tariff cap (lighter `#e89668`). The two-tone reads as "layered on top", not as a gap.
- **Current hour:** Golden colour (`#ffd166`) + pulsing glow filter (`feGaussianBlur stdDeviation=14`, opacity 0.25→0.75→0.25, 2.2s) + white outline (2px) + **"NU" pill** below x-axis label.
- **Y-axis:** Ticks at 0, 0.25, 0.50 … DKK/kWh. Baseline solid, others dashed (`2 6`). Labels left of plot.
- **X-axis:** Hour labels 00–23, current hour bold + brighter colour.
- **Title:** `Elpris · 24 t · DK1` top left, uppercase, muted colour.

---

## Price Calculation

Source: `docs/elpris-spec.md` — no deviations permitted.

```
SURCHARGE    = 6.00        # Gasel (øre/kWh)
ENERGINET    = 21.34       # network + system + TSO tariffs (øre/kWh)
DUTY         = 0.80        # øre/kWh (2026–2027)
ANNUAL_KWH   = 1900        # kWh/year

var_excl = spot + SURCHARGE + l_net_tariff(hour, month) + ENERGINET + DUTY
var_incl = var_excl × 1.25
fixed    = 934 / ANNUAL_KWH × 100    # = 49.16 øre/kWh
allin    = var_incl + fixed
```

**SVG rendering data format:**
```js
{ hour, spot: var_incl, total: allin }
// spot = variable portion (var_incl), total = all-in (incl. fixed network subscription)
// Tariff cap height = total − spot = fixed = 49.16 øre/kWh (constant)
```

**L-net tariff table** (excl. VAT, from 1 May 2026):

| Period | Off-peak 00–05 | Peak 06–16, 21–23 | High-peak 17–20 |
|---|---|---|---|
| Summer (Apr–Sep) | 5.34 | 8.01 | 20.82 |
| Winter (Oct–Mar) | 5.34 | 16.02 | 48.05 |

---

## Data Fetching

```
GET https://www.elprisenligenu.dk/api/v1/prices/YYYY/MM-DD_DK1.json
```

- No API key. No personal data sent.
- Fetches today's prices on startup.
- Refreshes at midnight (new day).
- Error state: display "No data" text in plot area.

---

## Responsive Sizes (Xeneon Edge `dashboard_lcd`)

| Size | Resolution | Adaptation |
|---|---|---|
| Small | 840×344 | SVG scales via `viewBox` + `preserveAspectRatio` |
| Medium | 840×696 | same |
| Large | 1688×696 | same |
| XL | 2536×696 | ~1:1 |

SVG is designed at 2560×720 and scales automatically to all sizes via `viewBox="0 0 2560 720"` + `preserveAspectRatio="xMidYMid meet"`.

---

## manifest.json (key fields)

```json
{
  "id": "dk.carbonicdk.elpris",
  "name": "Elpris DK1",
  "description": "Hourly Danish electricity price incl. all charges and tariffs (Gasel/L-net/DK1)",
  "version": "1.0.0",
  "supported_devices": [{ "type": "dashboard_lcd" }],
  "interactive": false
}
```

---

## Build Order

1. `manifest.json` + `resources/icon.svg`
2. Price calculation in JS (`calcPrice(spotOere, hour, month)`)
3. Data fetch + parsing
4. SVG rendering (static, no animation yet)
5. Warm Amber colours + layout
6. Pulsing glow animation on current hour
7. Test in browser at all 4 Xeneon Edge sizes
8. Package as zip and test in iCUE Widget Builder
