[English](./README.md) | **한국어**

# 환율 민감도 기반 클러스터링과 동조지수를 이용한 산업별 월간 수익률 예측

> 팀 프로젝트 · 2025.03–2025.06<br>
> 학술대회 논문 1편과 연결된 금융 데이터 분석 프로젝트

## 프로젝트 개요

이 팀 프로젝트는 환율 민감도 기반 군집화, 산업 간 동조 정보, Random Forest 모델을 이용해 산업별 월간 수익률을 예측하는 방법을 탐색했습니다.

이 저장소는 서로 관련되지만 구분이 필요한 두 범위를 설명합니다.

1. 학술대회 논문과 연결된 원 팀 연구 파이프라인
2. Walk-Forward 예측을 위한 별도의 공개 R 구현

공개 구현은 원 연구 파이프라인 전체를 재현하지 않습니다. 특히 고정된 `sector_map`을 사용하며 원 프로젝트의 K-Means 단계를 구현하지 않습니다.

## 연구 질문

환율 민감도에 따른 군집과 산업 간 동조 신호가 다음 달 산업 수익률 예측에 도움이 될 수 있는가?

이 프로젝트는 수업에서 배운 군집화와 예측 방법을 금융 데이터에 적용했습니다. 새로운 알고리즘이나 독창적인 모델을 제안했다고 주장하지 않습니다.

## 프로젝트 상태

| 항목 | 상태 |
|---|---|
| 프로젝트 형태 | 팀 프로젝트 |
| 원 프로젝트 기간 | 2025.03–2025.06 |
| 원 연구 파이프라인 | 개요만 문서화되며 이 저장소에서 완전히 재현되지 않음 |
| 공개 R 구현 | [`src/predict_monthly_returns.R`](src/predict_monthly_returns.R)의 `PORTFOLIO_REFACTORED_VERSION` |
| 공개 입력 데이터 | 포함하지 않음 |
| 성능 검증 | 원본 입력 데이터로 재실행 필요 |
| 재현성 | `CONDITIONAL_REPRODUCIBILITY` |
| 전체 실행 | `FULL_RUN_NOT_VERIFIED` |
| 논문 | 학술대회 논문 1편 |

원본 시장 데이터, 논문 전문, 팀 내부 자료는 재배포 권리와 팀의 공개 범위를 확인하기 전까지 포함하지 않습니다.

## 데이터

원 프로젝트 자료에는 다음 범위가 기재되어 있습니다.

- 대상: KOSPI 대형주 50개
- 기간: 2023.05–2025.04
- 주요 입력: 종목별 일별 수익률, USD/KRW 수익률, 외국인 지분율 변화

원본 데이터가 포함되어 있지 않으므로 행 수, 결측 처리 결과, 종목 구성, 기간을 이 저장소만으로 독립적으로 재검증할 수 없습니다.

공개 R 스크립트는 다음 파일을 입력으로 가정합니다.

```text
data/merged_50stocks_fx_multi.csv
```

| 컬럼 | 용도 |
|---|---|
| `종목` | 종목 식별자 |
| `일자` | 거래일 |
| `ret` | 종목 수익률 |
| `fore_chg` | 외국인 지분율 변화 |
| `USD_ret` | USD/KRW 수익률 |

자료형, 날짜 형식, 검증 규칙과 실제 과거 파일에서 확인한 스키마는 [`data/README.ko.md`](./data/README.ko.md), [`data/schema.csv`](./data/schema.csv), [`data/column_description.md`](./data/column_description.md)에 정리했습니다. 실제 또는 합성 데이터 행은 포함하지 않았습니다. 출처별 재배포 조건과 팀 동의를 확인하기 전에는 원본 또는 파생 데이터를 공개하지 않습니다.

## 방법론

원 팀 프로젝트는 수업에서 배운 다음 세 가지 방법을 결합했습니다.

1. **K-Means 군집화**: 수업에서 배운 군집화 방법을 금융 데이터에 적용
2. **Random Forest**: 수업에서 배운 예측 방법을 산업별 월간 수익률 예측에 적용
3. **Walk-Forward Validation**: 일반적인 랜덤 분할 대신 시간 순서를 지키며 시계열 예측 모델을 평가

Seokjun Lee와 Minsung Lee는 팀 프로젝트의 Walk-Forward Validation 구조를 함께 설계하고 구현했습니다.

K-Means와 Random Forest는 수업에서 배운 방법을 적용한 것입니다. 팀이 새로 개발한 알고리즘으로 설명하지 않으며, Seokjun Lee가 단독으로 설계하거나 구현한 것으로도 설명하지 않습니다.

## 공개 구현 상태

| 항목 | 공개 구현 |
|---|---|
| 언어 | R |
| 라이브러리 | tidyverse, lubridate, randomForest |
| 산업 분류 | 고정 `sector_map` |
| K-Means | 구현되지 않음 |
| 검증 | Expanding Walk-Forward |
| 모델 | `historical_mean`, `rf_baseline`, `rf_with_sync` |
| 평가지표 | RMSE, Hit Rate |

공개 스크립트는 다음 순서로 동작합니다.

1. 입력 파일과 필수 컬럼을 확인한 뒤 결측값과 비유한값을 제거합니다.
2. 고정된 `sector_map`으로 종목을 산업에 연결합니다.
3. 월별 `mean_ret`, `mean_fx`, `mean_flow`를 계산합니다.
4. 각 기준월마다 `t`월까지 이용 가능한 데이터만 사용해 동조 피처를 다시 계산합니다.
5. 연속된 다음 달인 `t+1`을 예측합니다.
6. Lift 임계값 1.4와 최소 동조 이력 6개월을 사용합니다.
7. 동일한 학습 행과 테스트월에서 3개 모델을 비교합니다.
8. 최소 12개의 공통 학습 행 이후 평가를 시작하고 `ntree = 300`을 사용하며, 전체 결과와 산업별 최근 6개 예측 월을 출력합니다.

현재 `avg_corr` 설계는 초기 fold에서 미래 월을 사용하지 않습니다. 전체 기간의 미래 분포를 볼 수 있는 분위수 경계 처리도 제거했습니다. Lift 기준을 충족하는 파트너가 없으면 `avg_corr = 0`, `partner_count = 0`으로 기록하며, `partner_count`는 점검용으로만 남기고 현재 모델 입력에는 사용하지 않습니다.

과거 개선 수치를 검증된 결과로 제시하지 않습니다. 원본 입력 데이터와 실행 산출물이 없으므로 수치를 게시하기 전에 성능을 독립적으로 다시 검증해야 합니다.

## 나의 기여

- 담당 종목 데이터를 수집·전처리하고 팀 공통 형식으로 정리
- Minsung Lee와 함께 시계열 예측 모델 평가를 위한 Walk-Forward Validation 구조 설계 및 구현

역할 범위:

- 논문 원고는 Minsung Lee가 작성
- Seokjun Lee의 논문 역할은 **공동저자**
- Seokjun Lee는 K-Means, Random Forest, 프로젝트 전체를 단독으로 설계하거나 구현했다고 주장하지 않음

## 한계

- 원본 데이터가 이 공개 저장소에 포함되지 않아 이 저장소만으로 실행 결과와 성능을 독립적으로 검증할 수 없습니다.
- 공개 코드는 K-Means 군집화를 재현하지 않고 고정 산업 매핑을 사용합니다.
- 기재된 24개월이 맞다면 동조관계 추정과 모델 학습에 표본이 작습니다.
- 일별 수익률의 월평균은 월 복리수익률과 다르므로 해석 전에 `ret`의 정의와 단위를 확인해야 합니다.
- Lift 임계값 1.4와 최소 이력 6개월은 고정값이며 민감도 분석을 수행하지 않았습니다.
- 현재 스크립트는 중복된 `(종목, 일자)` 키를 거부하지 않으므로 중복 행이 월평균을 바꿀 수 있습니다.
- 전체 기간 경계 처리를 제거했기 때문에 극단값의 영향을 받을 수 있으며, 향후 전처리는 각 fold의 학습 기간에서만 추정해야 합니다.
- Walk-Forward 구조는 시간 순서를 지키지만 Random Forest 튜닝, 거래비용, 예측구간, 통계적 유의성 검증은 포함하지 않습니다.
- 두 Random Forest 모델에 같은 fold seed를 사용해도 predictor 구성이 달라 동일한 bootstrap 표본을 보장하지 않습니다.
- Hit Rate는 수익률의 크기나 경제적 가치를 보여주지 않으므로 평가 월 수와 함께 해석해야 합니다.

## 배운 점과 개선 방향

이 프로젝트를 다시 정리하면서 연구의 품질은 분석 결과뿐 아니라 데이터와 코드를 다른 사람이 재현할 수 있는 형태로 관리하는 데에도 달려 있다는 점을 배웠습니다.

팀원들이 서로 다른 담당 종목을 수집하고 정리했기 때문에 프로젝트 초기부터 공통 컬럼 형식과 전처리 기준을 정했어야 했습니다.

예측 모델을 평가하는 과정에서는 일반적인 랜덤 분할보다 시간 순서를 반영한 Walk-Forward Validation이 필요하다는 점도 배웠습니다.

향후 프로젝트에서는 데이터 버전, 전처리 기준, 모델 설정, 실험 결과를 처음부터 함께 기록할 계획입니다. 또한 논문의 방법론과 공개 구현의 차이를 더 명확하게 문서화하겠습니다.

## 논문

이민성, 홍찬기, 추민주, 이석준, 우지영, “환율 민감도 기반 클러스터링과 동조지수를 이용한 산업별 월간 수익률 예측,” *한국컴퓨터정보학회 2025 하계학술대회 논문집*, 제33권 제2호, pp. 959–961, 2025.07.

- Seokjun Lee — 역할: **공동저자**
- 논문 원고: Minsung Lee 작성
- [DBpia 공식 문헌 정보](https://www.dbpia.co.kr/journal/articleDetail?nodeId=NODE12337990)
- 논문 원문 PDF는 저작권과 팀 공개 범위를 확인하기 전까지 포함하지 않습니다.

이 저장소에 연결된 논문은 이 1편뿐입니다.

## 재현 방법

필요한 R 패키지를 설치합니다.

```bash
Rscript requirements.R
```

공개 분석 스크립트를 실행합니다.

```bash
Rscript src/predict_monthly_returns.R
```

필요한 로컬 입력 파일:

```text
data/merged_50stocks_fx_multi.csv
```

명령과 입력 계약은 공개되어 있지만 비공개 입력 데이터가 없으면 수치 결과를 재현할 수 없습니다. 로컬 파일을 준비하기 전에 [`data/README.ko.md`](./data/README.ko.md)를 확인하세요.

재현성 상태: `CONDITIONAL_REPRODUCIBILITY` / `FULL_RUN_NOT_VERIFIED`.

## 저장소 구조

```text
exchange-rate-synchronization/
├── README.md
├── README.ko.md
├── requirements.R
├── THIRD_PARTY_NOTICES.md
├── data/
│   ├── README.md
│   ├── README.ko.md
│   ├── schema.csv
│   ├── column_description.md
│   └── merged_50stocks_fx_multi.csv  # 로컬 전용, Git에서 제외
├── reports/
│   └── figures/
│       └── README.md
└── src/
    └── predict_monthly_returns.R
```

[한국어 프로필로 돌아가기](https://github.com/jun5007/jun5007/blob/main/README.ko.md) · [한국어 포트폴리오 보기](https://jun5007.github.io/ko/)
