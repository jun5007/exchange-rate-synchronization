**English** | [한국어](./README.ko.md)

# Input Data Contract

The public R script expects the following local file:

```text
data/merged_50stocks_fx_multi.csv
```

This contract applies only to the separate public R implementation. It does not document or reproduce the full research pipeline linked to the conference Publication.

The original market, exchange-rate, and foreign-ownership data are not included. Do not publish the source or derived dataset until its redistribution terms and the team's publication agreement have been confirmed.

## Source status

The expected input combines stock returns, USD/KRW returns, and changes in foreign ownership ratios. The specific data providers, extraction fields, collection dates, and licenses are not preserved in the public repository. They must be confirmed from the original team materials before preparing or publishing a replacement input file.

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

## Illustrative synthetic row

The following row only demonstrates the schema. It is not a record from the original project data.

```csv
종목,일자,ret,fore_chg,USD_ret
삼성전자,2024-01-02,0.0012,0.0003,-0.0008
삼성전자,2024-01-03,-0.0006,-0.0001,0.0005
SK하이닉스,2024-01-02,0.0018,0.0002,-0.0008
```

## Local placement

```text
exchange-rate-synchronization/
├─ data/
│  ├─ README.md
│  ├─ README.ko.md
│  └─ merged_50stocks_fx_multi.csv  # local only; ignored by Git
├─ src/
│  └─ predict_monthly_returns.R
└─ requirements.R
```

The repository's `.gitignore` keeps `merged_50stocks_fx_multi.csv` and other raw data files out of Git while allowing this documentation file.

---

[Back to English Project README](../README.md)
