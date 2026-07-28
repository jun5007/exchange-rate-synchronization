**English** | [한국어](./README.ko.md)

# Input Data Contract

The public R script expects the following local file:

```text
data/merged_50stocks_fx_multi.csv
```

This contract applies only to the separate public R implementation. It does not document or reproduce the full research pipeline linked to the conference Publication.

The original market, exchange-rate, and foreign-ownership data are not included. Do not publish the source or derived dataset until its redistribution terms and the team's publication agreement have been confirmed.

## Source status

Status: `SOURCE_CONFIRMATION_REQUIRED`

Historical project materials describe 50 large-cap KOSPI stocks covering 2023.05–2025.04 and combining stock-market, USD/KRW, and foreign-ownership fields. The specific providers, extraction fields, collection dates, acquisition procedure, and licenses are not preserved well enough to claim a reproducible download source. They must be confirmed from the original team materials before preparing or publishing a replacement input file.

No verified acquisition script was found. Obtain each input from a permitted official or licensed source, reproduce the required five-column contract, and place the resulting local-only file at the path above.

## Required columns

| Column | R type | Required format | Meaning |
|---|---|---|---|
| `종목` | character | Non-empty stock name matching the script's `sector_map` | Stock identifier |
| `일자` | Date | ISO `YYYY-MM-DD` | Trading date |
| `ret` | double | Finite numeric value | Stock return used by the public implementation |
| `fore_chg` | double | Finite numeric value | Change in foreign ownership ratio |
| `USD_ret` | double | Finite numeric value | USD/KRW return |

Additional columns are allowed and are read with inferred types. Rows missing any required value, rows with non-finite numeric values, and stocks absent from the fixed `sector_map` are excluded by the script.

The intended row grain is one stock on one trading date (`종목` × `일자`). The current script does not reject duplicate keys, so duplicates can change the monthly averages and must be checked before execution.

Before interpreting results, confirm the unit and construction method of `ret`, `fore_chg`, and `USD_ret`. In particular, a daily arithmetic return and a percentage-point value must not be treated as interchangeable.

## Schema documentation

- [`schema.csv`](./schema.csv) records the 26 columns observed in the historical integrated table without publishing any data rows.
- [`column_description.md`](./column_description.md) separates the five columns required by the public script from additional historical fields.
- No real or synthetic sample rows are included.

## Local placement

```text
exchange-rate-synchronization/
├─ data/
│  ├─ README.md
│  ├─ README.ko.md
│  ├─ schema.csv
│  ├─ column_description.md
│  └─ merged_50stocks_fx_multi.csv  # local only; ignored by Git
├─ src/
│  └─ predict_monthly_returns.R
└─ requirements.R
```

The repository's `.gitignore` keeps `merged_50stocks_fx_multi.csv` and other raw data files out of Git while allowing the reviewed schema documentation.

---

[Back to English Project README](../README.md)
