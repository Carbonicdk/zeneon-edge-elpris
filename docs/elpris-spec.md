# Dansk elprisberegner – specifikation

## Formål
Beregn den samlede danske elpris time for time baseret på spotpris + faste tillæg.

---

## Datakilder

### Spotpris
- **API:** `https://www.elprisenligenu.dk/api/v1/prices/[YYYY]/[MM]-[DD]_DK1.json`
- **Prisområde:** DK1 (vest for Storebælt)
- **Format:** JSON-array med `time_start`, `time_end`, `DKK_per_kWh` (ekskl. moms og afgifter)
- Morgendagens priser tilgængelige fra ca. kl. 13

---

## Afregningsmetode (vigtigt)

**Timeafregnet (flexafregnet).** Gasel afregner time for time på den faktiske Nord Pool
DK1-spotpris. Der findes kun én spotpris pr. time pr. prisområde, så den rå elpris er
identisk på tværs af elleverandører. Forskellen mellem dem ligger udelukkende i
tillæg + abonnement, ikke i råstrømmen.

**Konsekvens for beregningen:** Brug den faktiske spotpris for HVER enkelt time
(`DKK_per_kWh` fra det timeopdelte JSON-array). Beregn aldrig på et månedsgennemsnit
– det svarer til den gamle profilafregning og giver et forkert resultat for et
timeafregnet produkt.

```
for hver time i døgnet:
    pris(time) = spotpris(time) + tillaeg + l_net_tarif(time) + 11.50 + 0.80
døgnpris = sum(pris(time) × forbrug(time))   # vægtet efter faktisk timeforbrug
```

---

## Priskomponenter (alle ekskl. moms)

### Elleverandør (VALGT: Gasel)
Skift `tillaeg` og `abonnement_aar` ved leverandørskift.

**Gasel "El til børspris 6 øre"** — aktiv aftale:
| Post | Pris |
|---|---|
| Pristillæg | 6,00 øre/kWh |
| Abonnement | 0 kr./md. |
| Binding | Ingen |

Alternativ (til sammenligning): OK El Lavt Forbrug = 19,00 øre/kWh tillæg, 0 kr./md.

### Energinet / Staten (tariffer 2026) – ekskl. moms
| Post | Pris |
|---|---|
| Nettarif (transport) | 4,30 øre/kWh |
| Systemtarif | 7,20 øre/kWh |
| Transmissionstarif (TSO) | 9,84 øre/kWh |
| **Total Energinet** | **21,34 øre/kWh** |

Bekræftet mod Gasels visning (5,38 + 9,00 + 12,30 = 26,68 øre/kWh inkl. moms = 21,34 ekskl.).
TSO-tariffen manglede i tidligere version af denne fil.

### Elafgift (2026–2027)
| Post | Pris |
|---|---|
| Elafgift | 0,80 øre/kWh |

### L-net nettarif (privat, C-tarif) – ekskl. moms
Gyldig pr. 1. maj 2026. Kilde: `https://www.l-net.dk/media/1333/tariffer_20260501.pdf`

| Periode | Lavlast (00–06) | Højlast (06–17 & 21–24) | Spidslast (17–21) |
|---|---|---|---|
| Sommer (apr–sep) | 5,34 øre/kWh | 8,01 øre/kWh | 20,82 øre/kWh |
| Vinter (okt–mar) | 5,34 øre/kWh | 16,02 øre/kWh | 48,05 øre/kWh |

**L-net netabonnement (C):** 934 kr./år inkl. moms (748 kr. ekskl.).
Fast beløb uafhængigt af leverandør. Ved 1.900 kWh/år = 934 / 1.900 × 100 = **49,16 øre/kWh inkl. moms**.
Bekræftet mod Gasels visning (49,18 øre/kWh).

---

## Beregningsformel

To trin: den **variable** timepris (afhænger af spot + tarif), og den **all-in** pris
hvor det faste netabonnement amortiseres over årsforbruget.

```
# Parametre
tillaeg      = 6.00      # Gasel (øre/kWh). OK Lavt Forbrug = 19.00
aarsforbrug  = 1900      # kWh/år (Brænderigården 7)
l_net_tarif  = bestem ud fra time og måned (se tabel ovenfor)

# 1) Variabel kWh-pris (timeafregnet) – ekskl. det faste netabonnement
var_ekskl_moms = spotpris + tillaeg + l_net_tarif + 21.34 + 0.80
var_inkl_moms  = var_ekskl_moms × 1.25

# 2) Fast netabonnement pr. kWh (inkl. moms)
fast_pr_kwh = 934 / aarsforbrug × 100        # = 49,16 øre/kWh ved 1900 kWh

# 3) All-in kWh-pris
allin_inkl_moms = var_inkl_moms + fast_pr_kwh
```

Alle beløb i øre/kWh medmindre andet er angivet. Gasel har 0 kr. leverandør-abonnement;
det faste beløb i regnestykket er L-nets netabonnement, som er ens uanset leverandør.

---

## Tidslogik for L-net tarif

```
sommer = april (4) til september (9) inklusiv
vinter = oktober (10) til marts (3) inklusiv

lavlast   = time 0–5   (kl. 00:00–06:00)
højlast   = time 6–16 og time 21–23  (kl. 06:00–17:00 & 21:00–24:00)
spidslast = time 17–20  (kl. 17:00–21:00)
```

---

## Eksempel (Gasel, sommer, spidslast, spotpris = 30 øre/kWh, 1900 kWh/år)

```
Variabel:  (30 + 6 + 20.82 + 21.34 + 0.80) × 1.25 = 98,70 øre/kWh
Fast:      934 / 1900 × 100                        = 49,16 øre/kWh
All-in:    98,70 + 49,16                           = 147,86 øre/kWh ≈ 1,48 kr./kWh
```

Den variable del falder markant i lavlast/sommer; den faste del (49,16 øre) er konstant
og fylder relativt meget ved lavt forbrug.

---

## Noter
- Spotpriser fra elprisenligenu.dk er allerede i DKK og ekskl. moms og afgifter
- L-net-tariffer opdateres typisk 1. april (sommerskift) og 1. oktober (vinterskift) – tjek `https://www.l-net.dk/priser-og-gebyrer/` for nye PDF'er
- Energinet-tariffer gælder hele 2026 og 2027
- Elafgiften er sat til EU-minimum i 2026 og 2027 (0,80 øre/kWh ekskl. moms)
