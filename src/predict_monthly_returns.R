############################################################
# 산업별 월간 수익률 예측
#
# 공개 구현 범위:
# - 고정 sector_map을 사용한 산업 매핑
# - 예측 시점까지의 데이터만 사용한 월별 동조 피처
# - 동일 fold의 단순 기준선 / RF baseline / RF + 동조 피처 비교
#
# 원 프로젝트 제목에는 클러스터링이 포함되지만, 이 공개
# 스크립트는 K-Means 군집화를 재현하지 않는다.
############################################################

pkgs <- c("tidyverse", "lubridate", "randomForest")
inst <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
if (length(inst)) {
  install.packages(inst)
}

library(tidyverse)
library(lubridate)
library(randomForest)

set.seed(42)

############################################################
# 1. 데이터 로딩과 입력 검증
############################################################

data_path <- file.path("data", "merged_50stocks_fx_multi.csv")

if (!file.exists(data_path)) {
  stop(
    "입력 파일이 없습니다: ", data_path, "\n",
    "README의 데이터 컬럼 설명을 확인하세요."
  )
}

df2 <- read_csv(
  data_path,
  col_types = cols(
    종목 = col_character(),
    일자 = col_date(format = ""),
    ret = col_double(),
    fore_chg = col_double(),
    USD_ret = col_double(),
    .default = col_guess()
  )
)

required_columns <- c(
  "종목", "일자", "ret", "fore_chg", "USD_ret"
)
missing_columns <- setdiff(required_columns, names(df2))

if (length(missing_columns) > 0) {
  stop(
    "필수 컬럼이 없습니다: ",
    paste(missing_columns, collapse = ", ")
  )
}

df_clean <- df2 %>%
  drop_na(all_of(required_columns)) %>%
  filter(
    if_all(
      all_of(c("ret", "fore_chg", "USD_ret")),
      is.finite
    )
  )

############################################################
# 2. 종목 -> 산업 고정 매핑
#
# 이 테이블은 K-Means 결과가 아니다. 원 프로젝트의 군집화
# 단계와 혼동하지 않도록 공개 예측 코드에서는 고정 매핑으로
# 명시한다.
############################################################

sector_map <- tribble(
  ~종목,             ~산업,
  # 반도체
  "SK하이닉스",       "반도체",
  "삼성전자",         "반도체",
  "DB하이텍",         "반도체",
  "한미반도체",       "반도체",
  "원익IPS",          "반도체",
  # 자동차
  "현대차",           "자동차",
  "기아",             "자동차",
  "현대모비스",       "자동차",
  "현대위아",         "자동차",
  "SNT모티브",        "자동차",
  # 화학
  "LG화학",           "화학",
  "롯데케미칼",       "화학",
  "SK케미칼",         "화학",
  "한화솔루션",       "화학",
  "금호석유화학",     "화학",
  # 건설
  "현대건설",         "건설",
  "GS건설",           "건설",
  "DL이앤씨",         "건설",
  "대우건설",         "건설",
  "HDC현대산업개발",  "건설",
  # 금융
  "KB금융",           "금융",
  "하나금융지주",     "금융",
  "우리금융지주",     "금융",
  "메리츠금융지주",   "금융",
  "신한지주",         "금융",
  # 유통·소매
  "이마트",           "유통_소매",
  "롯데쇼핑",         "유통_소매",
  "BGF리테일",        "유통_소매",
  "GS리테일",         "유통_소매",
  "신세계",           "유통_소매",
  # 에너지·정유
  "S-Oil",            "에너지_정유",
  "SK이노베이션",     "에너지_정유",
  "한국가스공사",     "에너지_정유",
  "한국전력",         "에너지_정유",
  "GS",               "에너지_정유",
  # 바이오·제약
  "셀트리온",         "바이오_제약",
  "삼성바이오로직스", "바이오_제약",
  "유한양행",         "바이오_제약",
  "한미약품",         "바이오_제약",
  "종근당",           "바이오_제약",
  # 미디어·엔터
  "CJ ENM",           "미디어_엔터",
  "스튜디오드래곤",   "미디어_엔터",
  "JYP Ent.",         "미디어_엔터",
  "iMBC",             "미디어_엔터",
  "콘텐트리중앙",     "미디어_엔터",
  # 통신
  "SK텔레콤",         "통신",
  "KT",               "통신",
  "LG유플러스",       "통신",
  "SK스퀘어",         "통신",
  "KTis",             "통신"
)

df_clean <- df_clean %>%
  left_join(sector_map, by = "종목")

unmapped <- df_clean %>%
  filter(is.na(산업)) %>%
  distinct(종목)

if (nrow(unmapped) > 0) {
  warning(
    "산업 매핑이 없는 종목을 제외합니다: ",
    paste(unmapped$종목, collapse = ", ")
  )
}

df_clean <- df_clean %>%
  filter(!is.na(산업))

if (nrow(df_clean) == 0) {
  stop("필수 전처리와 산업 매핑 후 남은 관측치가 없습니다.")
}

############################################################
# 3. 산업·월 단위 요약
############################################################

industry_monthly <- df_clean %>%
  mutate(yearmon = floor_date(일자, "month")) %>%
  group_by(산업, yearmon) %>%
  summarise(
    mean_ret  = mean(ret, na.rm = TRUE),
    mean_fx   = mean(USD_ret, na.rm = TRUE),
    mean_flow = mean(fore_chg, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(산업, yearmon)

############################################################
# 4. 시점별 동조 피처 계산
#
# cutoff 월의 피처는 cutoff 월까지의 월별 산업 수익률만 사용한다.
# 월 상승 여부는 "해당 월의 산업 평균수익률 > 0"으로 정의한다.
# 이는 일별 ret 중 하나라도 양수인 any(ret > 0)보다 월 방향을
# 직접 나타내며, 거래일 수가 많을 때 TRUE가 포화되는 문제를 줄인다.
############################################################

lift_threshold <- 1.4
min_sync_months <- 6L

calculate_sync_at_cutoff <- function(
  monthly_data,
  cutoff,
  lift_threshold = 1.4,
  min_history = 6L
) {
  sectors <- sort(unique(monthly_data$산업))
  output <- tibble(
    산업 = sectors,
    yearmon = cutoff,
    avg_corr = NA_real_,
    partner_count = 0L
  )

  history <- monthly_data %>%
    filter(yearmon <= cutoff) %>%
    select(yearmon, 산업, mean_ret) %>%
    pivot_wider(names_from = 산업, values_from = mean_ret) %>%
    arrange(yearmon)

  if (nrow(history) < min_history) {
    return(output)
  }

  for (sector in sectors) {
    if (!(sector %in% names(history))) {
      next
    }

    target_ret <- history[[sector]]
    partner_corrs <- numeric(0)

    for (partner in setdiff(sectors, sector)) {
      if (!(partner %in% names(history))) {
        next
      }

      partner_ret <- history[[partner]]
      valid <- is.finite(target_ret) & is.finite(partner_ret)

      if (sum(valid) < min_history) {
        next
      }

      target_up <- target_ret[valid] > 0
      partner_up <- partner_ret[valid] > 0
      p_target <- mean(target_up)
      p_partner <- mean(partner_up)

      if (p_target == 0 || p_partner == 0) {
        next
      }

      pair_lift <- mean(target_up & partner_up) / (p_target * p_partner)
      pair_corr <- cor(target_ret[valid], partner_ret[valid])

      if (
        is.finite(pair_lift) &&
        pair_lift >= lift_threshold &&
        is.finite(pair_corr)
      ) {
        partner_corrs <- c(partner_corrs, pair_corr)
      }
    }

    row_index <- which(output$산업 == sector)
    output$partner_count[row_index] <- length(partner_corrs)
    output$avg_corr[row_index] <- if (length(partner_corrs) == 0) {
      0
    } else {
      mean(partner_corrs)
    }
  }

  output
}

cutoffs <- sort(unique(industry_monthly$yearmon))
sync_by_month <- map_dfr(
  seq_along(cutoffs),
  function(index) {
    calculate_sync_at_cutoff(
      industry_monthly,
      cutoffs[[index]],
      lift_threshold = lift_threshold,
      min_history = min_sync_months
    )
  }
)

industry_m <- industry_monthly %>%
  left_join(sync_by_month, by = c("산업", "yearmon")) %>%
  arrange(산업, yearmon) %>%
  group_by(산업) %>%
  mutate(
    next_ret = lead(mean_ret),
    target_month = lead(yearmon)
  ) %>%
  ungroup() %>%
  filter(
    !is.na(next_ret),
    target_month == yearmon %m+% months(1)
  )

############################################################
# 5. 동일 fold에서 세 모델을 비교하는 Walk-Forward 검증
############################################################

base_predictors <- c("mean_ret", "mean_fx", "mean_flow")
sync_predictors <- c(base_predictors, "avg_corr")
min_train_rows <- 12L

fit_rf_once <- function(train, test, predictors, seed) {
  set.seed(seed)
  formula <- reformulate(predictors, response = "next_ret")
  model <- randomForest(formula, data = train, ntree = 300)
  as.numeric(predict(model, test))
}

predict_all <- list()

for (industry_name in sort(unique(industry_m$산업))) {
  industry_data <- industry_m %>%
    filter(산업 == industry_name) %>%
    arrange(yearmon)

  n_rows <- nrow(industry_data)
  industry_predictions <- list()

  if (n_rows <= min_train_rows) {
    next
  }

  for (test_index in seq.int(min_train_rows + 1L, n_rows)) {
    train_raw <- industry_data[seq_len(test_index - 1L), , drop = FALSE]
    test_row <- industry_data[test_index, , drop = FALSE]

    # 두 RF가 완전히 같은 학습 표본을 사용하도록 avg_corr까지
    # 존재하는 행만 공통 학습 집합에 포함한다.
    train_common <- train_raw %>%
      select(next_ret, all_of(sync_predictors)) %>%
      drop_na() %>%
      filter(if_all(everything(), is.finite))

    test_values <- unlist(
      test_row[1, sync_predictors],
      use.names = FALSE
    )
    test_complete <- all(is.finite(as.numeric(test_values)))

    if (nrow(train_common) < min_train_rows || !test_complete) {
      next
    }

    fold_seed <- 42L + test_index

    predictions <- tibble(
      산업 = industry_name,
      yearmon = test_row$target_month,
      actual = test_row$next_ret,
      model = c("historical_mean", "rf_baseline", "rf_with_sync"),
      pred = c(
        mean(train_common$next_ret),
        fit_rf_once(
          train_common,
          test_row,
          base_predictors,
          seed = fold_seed
        ),
        fit_rf_once(
          train_common,
          test_row,
          sync_predictors,
          seed = fold_seed
        )
      ),
      train_n = nrow(train_common)
    )

    industry_predictions[[length(industry_predictions) + 1L]] <- predictions
  }

  predict_all[[industry_name]] <- bind_rows(industry_predictions)
}

result <- bind_rows(predict_all)

if (nrow(result) == 0) {
  stop(
    "평가 가능한 Walk-Forward fold가 없습니다. ",
    "월별 표본 수, avg_corr 생성 구간과 산업 매핑을 확인하세요."
  )
}

############################################################
# 6. 전체 및 최근 최대 6개 예측 월의 성능
############################################################

summarise_performance <- function(predictions) {
  predictions %>%
    mutate(hit = sign(pred) == sign(actual)) %>%
    group_by(산업, model) %>%
    summarise(
      RMSE = sqrt(mean((pred - actual)^2)),
      HitRate = mean(hit),
      n_month = n(),
      .groups = "drop"
    )
}

perf_all <- summarise_performance(result)

result_recent <- result %>%
  group_by(산업, model) %>%
  arrange(yearmon, .by_group = TRUE) %>%
  slice_tail(n = 6) %>%
  ungroup()

perf_recent <- summarise_performance(result_recent)

cat("\n전체 Out-of-Sample 성능\n")
print(perf_all)

cat("\n산업별 최근 최대 6개 예측 월 성능\n")
print(perf_recent)

############################################################
# 7. 최근 예측 시각화
############################################################

for (industry_name in sort(unique(result_recent$산업))) {
  plot_predictions <- result_recent %>%
    filter(산업 == industry_name)

  plot_actual <- plot_predictions %>%
    distinct(yearmon, actual)

  chart <- ggplot() +
    geom_line(
      data = plot_actual,
      aes(x = yearmon, y = actual, color = "actual"),
      linewidth = 1
    ) +
    geom_line(
      data = plot_predictions,
      aes(x = yearmon, y = pred, color = model),
      linewidth = 0.8
    ) +
    labs(
      title = paste0(industry_name, " 산업 - 최근 Walk-Forward 예측"),
      x = "월",
      y = "수익률",
      color = NULL
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  print(chart)
}
