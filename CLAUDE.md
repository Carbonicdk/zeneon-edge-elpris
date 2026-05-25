# Elpris Widget

Calculates and displays the actual, hour-by-hour Danish electricity price for:
- **Address:** Brænderigården 7, 2. tv, 7500 Holstebro
- **Price area:** DK1 (west of the Great Belt)
- **Grid operator:** L-net (fixed by address, cannot be changed)
- **Electricity supplier:** Gasel "El til børspris + 6 øre/kWh" (hourly settled, no lock-in, 0 DKK supplier subscription)

## Goal
Fetch the spot price per hour and add the fixed components, so the widget shows the real
all-in kWh price for each hour of the day. The user cannot shift consumption, so the purpose
is overview and price insight, not consumption management.

## Data Source
Hourly spot price from elprisenligenu.dk (free, no key required):
```
GET https://www.elprisenligenu.dk/api/v1/prices/[YYYY]/[MM]-[DD]_DK1.json
```
Returns an array with `DKK_per_kWh` per hour (excl. VAT and charges).
Tomorrow's prices available from approx. 13:00.

## Price Calculation
`docs/elpris-spec.md` is the single source of truth for all constants and formulas. Summary:
```
var_excl_vat    = spot + 6.00 + l_net_tariff(hour, season) + 21.34 + 0.80
var_incl_vat    = var_excl_vat × 1.25
fixed_per_kwh   = 934 / annual_kwh × 100        # L-net network subscription, incl. VAT
allin_incl_vat  = var_incl_vat + fixed_per_kwh
```
All figures cross-checked against Gasel's and L-net's official displays (May 2026).
Always use the actual hourly price, never a monthly average (the product is hourly settled).

## Implementation Decisions (resolved)
- **Technology:** Vanilla HTML/JS/CSS — iCUE Widget Builder format (zip with `index.html` + `manifest.json`)
- **Display:** Full day, 24 hours fixed 00–23, Warm Amber dark-mode design
- **Annual consumption:** Hardcoded 1,900 kWh
- See `docs/plan.md` for the full plan including design tokens and layout

## iCUE Widget Builder Documentation
Official Corsair/Elgato widget documentation lives at the project root:
- `docs/` — widget concepts, controls, plugins (plus `elpris-spec.md` and `plan.md`)
- `references/` — technical references (manifest, meta-tags, responsive scaling, security)
- `skill.md` — source for `.claude/commands/icue-widget-builder.md`

Use `/icue-widget-builder` to activate the skill's workflow when working on the widget.

## Coding Principles (apply to all code in this repo)
1. Simple beats complex. No over-engineering.
2. No fallbacks: one correct path, no alternatives.
3. One way to do things, not many.
4. Clarity beats backwards compatibility.
5. Fail fast: throw errors when preconditions are not met.
6. No backups: trust the primary mechanism.
7. Fix root cause, not symptoms.
8. Don't expand scope. Solve what is asked; mention adjacent issues separately.
9. Minimal comments, only where the logic is non-obvious.

## Maintenance (update when sources change)
- **L-net tariffs:** typically change 1 April (summer) and 1 October (winter).
  Fetch new PDF from https://www.l-net.dk/priser-og-gebyrer/
- **Energinet/TSO tariffs:** adjusted quarterly. Cross-check against an actual supplier display.
- **Electricity duty:** 0.80 øre/kWh excl. VAT applies only 2026–2027 (green tax reform, act L24).
- **Network subscription:** 934 DKK/year incl. VAT (L-net C-tariff).
