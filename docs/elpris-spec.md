# Danish Electricity Price Calculator — Specification

## Purpose
Calculate the total Danish electricity price hour by hour based on spot price plus fixed charges.

---

## Data Sources

### Spot Price
- **API:** `https://www.elprisenligenu.dk/api/v1/prices/[YYYY]/[MM]-[DD]_DK1.json`
- **Price area:** DK1 (west of the Great Belt)
- **Format:** JSON array with `time_start`, `time_end`, `DKK_per_kWh` (excl. VAT and charges)
- Tomorrow's prices available from approx. 13:00

---

## Settlement Method (important)

**Hourly settlement (flex settlement).** Gasel settles hour by hour on the actual Nord Pool DK1 spot price. There is only one spot price per hour per price area, so the raw electricity price is identical across suppliers. The difference between them lies solely in surcharges + subscription, not in the raw power.

**Consequence for the calculation:** Use the actual spot price for EACH individual hour (`DKK_per_kWh` from the hourly JSON array). Never calculate on a monthly average — that corresponds to the old profile settlement and gives an incorrect result for an hourly-settled product.

```
for each hour of the day:
    price(hour) = spot(hour) + surcharge + l_net_tariff(hour) + 21.34 + 0.80
daily_cost = sum(price(hour) × consumption(hour))   # weighted by actual hourly consumption
```

---

## Price Components (all excl. VAT)

### Electricity Supplier (SELECTED: Gasel)
Change `surcharge` and `subscription_year` when switching supplier.

**Gasel "El til børspris 6 øre"** — active agreement:
| Item | Price |
|---|---|
| Surcharge | 6.00 øre/kWh |
| Subscription | 0 DKK/month |
| Lock-in | None |

Alternative (for comparison): OK El Lavt Forbrug = 19.00 øre/kWh surcharge, 0 DKK/month

### Energinet / State (2026 tariffs) — excl. VAT
| Item | Price |
|---|---|
| Network tariff (transport) | 4.30 øre/kWh |
| System tariff | 7.20 øre/kWh |
| Transmission tariff (TSO) | 9.84 øre/kWh |
| **Total Energinet** | **21.34 øre/kWh** |

Confirmed against Gasel's display (5.38 + 9.00 + 12.30 = 26.68 øre/kWh incl. VAT = 21.34 excl.).
TSO tariff was missing in an earlier version of this file.

### Electricity Duty (2026–2027)
| Item | Price |
|---|---|
| Electricity duty | 0.80 øre/kWh |

### L-net Network Tariff (residential, C-tariff) — excl. VAT
Valid from 1 May 2026. Source: `https://www.l-net.dk/media/1333/tariffer_20260501.pdf`

| Period | Off-peak (00–06) | Peak (06–17 & 21–24) | High-peak (17–21) |
|---|---|---|---|
| Summer (Apr–Sep) | 5.34 øre/kWh | 8.01 øre/kWh | 20.82 øre/kWh |
| Winter (Oct–Mar) | 5.34 øre/kWh | 16.02 øre/kWh | 48.05 øre/kWh |

**L-net network subscription (C):** 934 DKK/year incl. VAT (748 DKK excl.).
Fixed amount independent of supplier. At 1,900 kWh/year = 934 / 1,900 × 100 = **49.16 øre/kWh incl. VAT**.
Confirmed against Gasel's display (49.18 øre/kWh).

---

## Calculation Formula

Two steps: the **variable** hourly price (depends on spot + tariff), and the **all-in** price where the fixed network subscription is amortised over annual consumption.

```
# Parameters
surcharge    = 6.00      # Gasel (øre/kWh). OK Lavt Forbrug = 19.00
annual_kwh   = 1900      # kWh/year (Brænderigården 7)
l_net_tariff = determined from hour and month (see table above)

# 1) Variable kWh price (hourly settled) — excl. fixed network subscription
var_excl_vat = spot + surcharge + l_net_tariff + 21.34 + 0.80
var_incl_vat = var_excl_vat × 1.25

# 2) Fixed network subscription per kWh (incl. VAT)
fixed_per_kwh = 934 / annual_kwh × 100        # = 49.16 øre/kWh at 1900 kWh

# 3) All-in kWh price
allin_incl_vat = var_incl_vat + fixed_per_kwh
```

All amounts in øre/kWh unless otherwise stated. Gasel has 0 DKK supplier subscription;
the fixed amount in the calculation is L-net's network subscription, which is the same regardless of supplier.

---

## Time Logic for L-net Tariff

```
summer = April (4) through September (9) inclusive
winter = October (10) through March (3) inclusive

off-peak  = hours 0–5   (00:00–06:00)
peak      = hours 6–16 and hours 21–23  (06:00–17:00 & 21:00–24:00)
high-peak = hours 17–20  (17:00–21:00)
```

---

## Example (Gasel, summer, high-peak, spot = 30 øre/kWh, 1900 kWh/year)

```
Variable:  (30 + 6 + 20.82 + 21.34 + 0.80) × 1.25 = 98.70 øre/kWh
Fixed:     934 / 1900 × 100                        = 49.16 øre/kWh
All-in:    98.70 + 49.16                           = 147.86 øre/kWh ≈ 1.48 DKK/kWh
```

The variable portion drops significantly in off-peak/summer; the fixed portion (49.16 øre) is constant and accounts for a relatively large share at low consumption.

---

## Maintenance Notes
- Spot prices from elprisenligenu.dk are already in DKK and excl. VAT and charges
- L-net tariffs typically updated 1 April (summer switch) and 1 October (winter switch) — check `https://www.l-net.dk/priser-og-gebyrer/` for new PDFs
- Energinet tariffs apply throughout 2026 and 2027
- Electricity duty is set to EU minimum in 2026 and 2027 (0.80 øre/kWh excl. VAT)
