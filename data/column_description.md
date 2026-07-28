# Column Description / 컬럼 설명

This document is based on the column names observed in the historical integrated CSV and the current public R script. It contains no data rows.

이 문서는 과거 통합 CSV에서 확인한 컬럼명과 현재 공개 R 스크립트를 기준으로 작성했으며 데이터 행은 포함하지 않습니다.

## Required by the public script / 공개 스크립트 필수 컬럼

| Column | Expected R type | Description | Confirmation needed |
|---|---|---|---|
| `종목` | character | Stock identifier used by the fixed `sector_map` / 고정 `sector_map`에 사용하는 종목 식별자 | Naming convention |
| `일자` | Date | Trading date in ISO `YYYY-MM-DD` / ISO 형식 거래일 | Calendar and timezone convention |
| `ret` | double | Stock return / 종목 수익률 | Return definition and unit |
| `fore_chg` | double | Change in foreign ownership ratio / 외국인 지분율 변화 | Construction and unit |
| `USD_ret` | double | USD/KRW return / USD/KRW 수익률 | Quote convention, return definition and unit |

## Additional historical columns / 추가 과거 컬럼

The historical table also contains price, volume, market-capitalization, foreign-ownership, CNY/EUR/JPY/USD level, and currency-return fields. These fields are listed in [`schema.csv`](./schema.csv), but they are not required by `src/predict_monthly_returns.R`.

과거 테이블에는 가격·거래량·시가총액·외국인 보유·CNY/EUR/JPY/USD 환율 수준 및 수익률 필드도 있습니다. 전체 목록은 [`schema.csv`](./schema.csv)에 기록했으며 `src/predict_monthly_returns.R`의 필수 입력은 아닙니다.

## Status / 상태

- Source provider: `SOURCE_CONFIRMATION_REQUIRED`
- Redistribution rights: `LICENSE_REVIEW_REQUIRED`
- Team permission: `TEAM_PERMISSION_REQUIRED`
- Public data rows: not included / 미포함
