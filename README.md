**English** | [한국어](./README.ko.md)

# Forecasting Monthly Industry Returns Using Exchange-Rate Sensitivity-Based Clustering and a Synchronization Index

> Team Project · 2025.03–2025.06<br>
> Financial data analysis project linked to 1 conference publication

## Project Overview

This team project explored monthly industry return forecasting using exchange-rate sensitivity-based clustering, cross-industry synchronization information, and Random Forest models.

The repository documents two related but distinct scopes:

1. the original team research pipeline connected to the conference publication; and
2. a separate public R implementation for Walk-Forward forecasting.

The public implementation does not reproduce the full research pipeline. In particular, it uses a fixed `sector_map` and does not implement the original K-Means stage.

## Research Question

Can groupings based on exchange-rate sensitivity and synchronization signals between industries support next-month industry return forecasting?

The project applied clustering and prediction methods learned in class to financial data. It does not claim to introduce a new algorithm or a novel model.

## Project Status

| Item | Status |
|---|---|
| Project type | Team Project |
| Original project period | 2025.03–2025.06 |
| Original research pipeline | Documented at a high level; not fully reproduced here |
| Public R implementation | Available in [`src/predict_monthly_returns.R`](src/predict_monthly_returns.R) |
| Public input data | Not included |
| Performance verification | Requires rerunning with the original input data |
| Publication | 1 conference paper |

Original market data, the full paper, and internal team materials remain excluded until redistribution rights and the team's publication scope are confirmed.

## Data

The original project materials describe the following scope:

- Universe: 50 large-cap KOSPI stocks
- Period: 2023.05–2025.04
- Main inputs: daily stock returns, USD/KRW returns, and changes in foreign ownership ratios

Because the original data is not included, the row count, missing-value treatment, stock composition, and period cannot be independently reverified from this repository.

The public R script expects:

```text
data/merged_50stocks_fx_multi.csv
```

| Column | Purpose |
|---|---|
| `종목` | Stock identifier |
| `일자` | Trading date |
| `ret` | Stock return |
| `fore_chg` | Change in foreign ownership ratio |
| `USD_ret` | USD/KRW return |

Data types, date format, validation rules, and illustrative synthetic rows are documented in [`data/README.md`](./data/README.md). The original or derived datasets should not be published until source-specific redistribution terms and team consent are confirmed.

## Methodology

The original team project combined three course-based methods:

1. **K-Means clustering** to apply a clustering method learned in class to financial data.
2. **Random Forest** to apply a prediction method learned in class to monthly industry return forecasting.
3. **Walk-Forward Validation** to evaluate a time-series prediction model without using a random train-test split.

Seokjun Lee and Minsung Lee jointly designed and implemented the Walk-Forward Validation structure for the team project.

K-Means and Random Forest were applications of methods learned in class. They are not presented as algorithms developed by the team, and they are not presented as Seokjun Lee's sole design or implementation.

## Public Implementation Status

| Item | Public implementation |
|---|---|
| Language | R |
| Libraries | tidyverse, lubridate, randomForest |
| Industry grouping | Fixed `sector_map` |
| K-Means | Not implemented |
| Validation | Expanding Walk-Forward |
| Models | `historical_mean`, `rf_baseline`, `rf_with_sync` |
| Metrics | RMSE, Hit Rate |

The public script:

1. checks the input file and required columns, then removes missing and non-finite observations;
2. joins stocks to industries through the fixed `sector_map`;
3. calculates monthly `mean_ret`, `mean_fx`, and `mean_flow`;
4. recalculates the synchronization feature at each cutoff using only data available through month `t`;
5. predicts the consecutive next month, `t+1`;
6. uses a Lift threshold of 1.4 and a minimum synchronization history of 6 months;
7. compares all 3 models on common training rows and the same test month;
8. starts evaluation after at least 12 common training rows, uses `ntree = 300`, and reports overall results and the most recent 6 prediction months per industry.

The current `avg_corr` design avoids using future months in earlier folds. Full-period quantile clipping was also removed because it could expose future distribution information. If no partner meets the Lift threshold, the script records `avg_corr = 0` and `partner_count = 0`; `partner_count` is retained for inspection but is not currently used as a model input.

No historical improvement figure is presented as a verified result. Without the original input data and execution artifacts, performance must be independently revalidated before any numerical result is reported.

## My Contribution

- Collected, preprocessed, and aligned the stocks assigned to me to the team's shared format.
- Co-designed and implemented the Walk-Forward Validation structure for time-series prediction evaluation with Minsung Lee.

Role boundaries:

- Minsung Lee wrote the paper manuscript.
- Seokjun Lee's publication role is **Co-author**.
- Seokjun Lee does not claim sole design or implementation of K-Means, Random Forest, or the full project.

## Limitations

- The original data is unavailable, so execution results and performance cannot be independently verified from this repository.
- The public code does not reproduce K-Means clustering and instead uses a fixed industry mapping.
- If the documented 24-month period is correct, the sample is small for synchronization estimation and model training.
- A monthly mean of daily returns is not the same as a compounded monthly return; the definition and unit of `ret` must be confirmed before interpretation.
- The Lift threshold of 1.4 and the minimum 6-month history are fixed values without sensitivity analysis.
- Duplicate `(종목, 일자)` keys are not rejected by the current script and could change monthly averages.
- Extreme values may affect the implementation because full-period clipping was removed; any future preprocessing should be estimated only from each fold's training period.
- The Walk-Forward structure preserves time order, but Random Forest tuning, transaction costs, prediction intervals, and statistical significance tests are not included.
- The two Random Forest models use the same fold seed, but different predictor sets do not guarantee identical bootstrap samples.
- Hit Rate does not measure return magnitude or economic value and should be interpreted together with the number of evaluated months.

## Lessons Learned and Next Steps

Revisiting this project showed me that research quality depends not only on analytical results but also on keeping data and code in a form that others can reproduce.

Because team members collected and organized different assigned stocks, common column formats and preprocessing rules should have been defined at the beginning of the project.

While implementing the prediction evaluation, I also learned why time-series models require Walk-Forward Validation rather than a general random split.

In future projects, I plan to record data versions, preprocessing rules, model settings, and experiment results from the start. I will also document the differences between a paper's methodology and its public implementation more explicitly.

## Publication

이민성, 홍찬기, 추민주, 이석준, 우지영, “환율 민감도 기반 클러스터링과 동조지수를 이용한 산업별 월간 수익률 예측,” *한국컴퓨터정보학회 2025 하계학술대회 논문집*, 제33권 제2호, pp. 959–961, 2025.07.

- Seokjun Lee — Role: **Co-author**
- Manuscript: written by Minsung Lee
- [Official paper record on DBpia](https://www.dbpia.co.kr/journal/articleDetail?nodeId=NODE12337990)
- The full paper PDF is not included until copyright and team-publication permissions are confirmed.

This is the only publication associated with this repository.

## Reproduction

Install the required R packages:

```bash
Rscript requirements.R
```

Run the public analysis script:

```bash
Rscript src/predict_monthly_returns.R
```

Required local input:

```text
data/merged_50stocks_fx_multi.csv
```

The commands and input contract are public, but numerical results cannot be reproduced without the unpublished input data. See [`data/README.md`](./data/README.md) before preparing a local file.

## Repository Structure

```text
exchange-rate-synchronization/
├── README.md
├── README.ko.md
├── requirements.R
├── data/
│   ├── README.md
│   ├── README.ko.md
│   └── merged_50stocks_fx_multi.csv  # local only; ignored by Git
└── src/
    └── predict_monthly_returns.R
```

[Back to English Profile](https://github.com/jun5007) · [View English Portfolio](https://jun5007.github.io/)
