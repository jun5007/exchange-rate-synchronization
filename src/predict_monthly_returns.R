############################################################
# 산업별 월간 수익율 예측
# 0. 패키지 설치 & 로드 ------------------------------------
############################################################
pkgs <- c("tidyverse", "lubridate", "cluster", "factoextra", "randomForest", "scales")
inst <- pkgs[!(pkgs %in% installed.packages()[,"Package"])]
if(length(inst)) install.packages(inst)
library(tidyverse); library(lubridate); library(cluster); library(factoextra); library(randomForest)




## 1. 데이터 로딩 -------------------------------------------------
data_path <- file.path("data", "merged_50stocks_fx_multi.csv")
df2 <- read_csv(data_path,
               col_types = cols(
                 종목 = col_character(),
                 일자 = col_date(format = ""),
                 .default = col_double())
)

## 2-A. 클러스터링용 feature 집계 ---------------------------------
feat <- df2 %>%                     # ⇢ 이 블록 안에서만
  drop_na(ret, USD_ret, fore_chg) %>%   # 필요한 NA 제거
  group_by(종목) %>% 
  summarise(
    FX_sens_USD    = cor(ret, USD_ret),
    FX_sens_EUR    = cor(ret, EUR_ret),
    FX_sens_JPY    = cor(ret, JPY100_ret),
    FX_sens_CNY    = cor(ret, CNY_ret),
    Foreigner_flow = mean(fore_chg, na.rm = TRUE),
    .groups = "drop"
  )

## 2-B. 예측용 전처리 --------------------------------------------
df_clean <- df2 %>%                 # 원본 df2 재사용
  drop_na(ret, fore_chg, USD_ret, EUR_ret, JPY100_ret, CNY_ret) %>% 
  mutate(
    fore_chg = scales::squish(fore_chg,
                              quantile(fore_chg, c(.01,.99)))
  )

#★ 0-1. “동조지수 mean_corr” 계산 코드 추가
############################################################################
# 2-C. 종목별 동조지수(mean_corr) 계산  ------------------------------
############################################################################
# 1) 월별 TRUE/FALSE 행렬  → Lift >= 1.4
bin <- df_clean %>% 
  mutate(yearmon = floor_date(일자, "month"), up = ret > 0) %>%
  group_by(yearmon, 종목) %>% summarise(up = any(up), .groups = "drop") %>% 
  pivot_wider(names_from = 종목, values_from = up, values_fill = FALSE)

mat <- bin %>% select(-yearmon) %>% mutate(across(everything(), as.integer)) %>% as.matrix()
N  <- nrow(mat);  p <- colSums(mat)/N;  pAB <- crossprod(mat)/N
lift_mat <- pAB / outer(p, p); diag(lift_mat) <- NA
idx <- which(lift_mat >= 1.4, arr.ind = TRUE)

# 2) 월별 수익률 상관계수 행렬
ret_mat  <- df_clean %>% 
  mutate(yearmon = floor_date(일자, "month")) %>% 
  group_by(yearmon, 종목) %>% summarise(ret = mean(ret), .groups = "drop") %>% 
  pivot_wider(names_from = 종목, values_from = ret) %>% 
  select(-yearmon) %>% as.matrix()
corr_mat <- cor(ret_mat, use = "pair")

# 3) 각 종목의 mean_corr
mean_corr <- tibble(
  종목 = colnames(mat),
  mean_corr = map_dbl(colnames(mat), \(stk){
    partners <- c(colnames(mat)[idx[idx[,1]==which(colnames(mat)==stk),2]],
                  colnames(mat)[idx[idx[,2]==which(colnames(mat)==stk),1]])
    if(length(partners)==0) 0 else mean(corr_mat[stk, partners], na.rm = TRUE)
  })
)







############################################################
# 예측 시작
# df_clean : NA·이상치 제거 완료, 컬럼 = 일자 / 종목 / 산업 /
#            ret, fore_chg, USD_ret  (+ 추가 환율 _ret 가능)
############################################################

library(dplyr); library(lubridate); library(randomForest); library(ggplot2)


#섹터
names(df_clean)


############################################################
# A. 종목 → 산업 매핑 테이블 만들기 -------------------------
############################################################
sector_map <- tribble(
  ~종목,           ~산업,
  # 반도체
  "SK하이닉스",     "반도체",
  "삼성전자",       "반도체",
  "DB하이텍",       "반도체",
  "한미반도체",     "반도체",
  "원익IPS",        "반도체",
  # 자동차
  "현대차",         "자동차",
  "기아",           "자동차",
  "현대모비스",     "자동차",
  "현대위아",       "자동차",
  "SNT모티브",      "자동차",
  # 화학
  "LG화학",         "화학",
  "롯데케미칼",     "화학",
  "SK케미칼",       "화학",
  "한화솔루션",     "화학",
  "금호석유화학",       "화학",
  # 건설
  "현대건설",       "건설",
  "GS건설",         "건설",
  "DL이앤씨",       "건설",
  "대우건설",       "건설",
  "HDC현대산업개발", "건설",
  # 금융
  "KB금융",         "금융",
  "하나금융지주",   "금융",
  "우리금융지주",   "금융",
  "메리츠금융지주", "금융",
  "신한지주",       "금융",
  # 유통·소매
  "이마트",         "유통_소매",
  "롯데쇼핑",       "유통_소매",
  "BGF리테일",      "유통_소매",
  "GS리테일",       "유통_소매",
  "신세계",       "유통_소매",
  # 에너지·정유
  "S-Oil",          "에너지_정유",
  "SK이노베이션",    "에너지_정유",
  "한국가스공사",    "에너지_정유",
  "한국전력",       "에너지_정유",
  "GS",       "에너지_정유",
  # 바이오·제약
  "셀트리온",       "바이오_제약",
  "삼성바이오로직스","바이오_제약",
  "유한양행",       "바이오_제약",
  "한미약품",       "바이오_제약",
  "종근당",       "바이오_제약",
  # 미디어·엔터
  "CJ ENM",         "미디어_엔터",
  "스튜디오드래곤", "미디어_엔터",
  "JYP Ent.",       "미디어_엔터",
  "iMBC",           "미디어_엔터",
  "콘텐트리중앙",           "미디어_엔터",
  # 통신
  "SK텔레콤",       "통신",
  "KT",             "통신",
  "LG유플러스",     "통신",
  "SK스퀘어",       "통신",
  "KTis",           "통신"
)

############################################################
# B. df_clean에 산업 컬럼 붙이기 ----------------------------
############################################################
#df_clean <- df_clean %>% 
  #left_join(sector_map, by = "종목")    # 새 컬럼 '산업' 생성

#df_clean <- df_clean %>% 
  #left_join(sector_map, by = "종목") %>%     # 산업
  #left_join(mean_corr,  by = "종목")         # ★ 동조지수
df_clean <- df_clean %>% 
  left_join(sector_map, by = "종목") %>%   # ← 산업 컬럼 생성
  left_join(mean_corr,  by = "종목")       # ← 동조지수 추가


# 만약 매핑되지 않아 NA가 생긴 종목이 있으면 확인
if(any(is.na(df_clean$산업))){
  warning("산업 매핑이 안 된 종목이 있습니다. sector_map을 확인하세요.")
}

## 매핑되지 않은(산업이 NA인) 종목 목록 확인 -------------------
unmapped <- df_clean %>% 
  filter(is.na(산업)) %>% 
  distinct(종목)       # 중복 제거

print(unmapped)




# 3. 월별 요약 + 예측 타깃 만들기 ---------------------------------
industry_m <- df_clean %>%
  mutate(yearmon = floor_date(일자, "month")) %>%
  group_by(산업, yearmon) %>%
  summarise(
    mean_ret  = mean(ret, na.rm = TRUE),
    mean_fx   = mean(USD_ret, na.rm = TRUE),
    mean_flow = mean(fore_chg, na.rm = TRUE),
    avg_corr  = mean(mean_corr, na.rm = TRUE),   # ★ 추가
    .groups = "drop"
  ) %>%
  arrange(산업, yearmon) %>%
  group_by(산업) %>%
  mutate(next_ret = lead(mean_ret)) %>%
  ungroup() %>%
  drop_na() # 마지막 NA 제거

# 4. Walk-Forward Random Forest 예측 -------------------------------
set.seed(42)

#mean_corr이 도입되는 산업들
corr_sector <- c("미디어_엔터", "반도체", "금융",
                 "에너지_정유", "바이오_제약")

predict_all <- list()

for(ind in unique(industry_m$산업)){
  
  df_ind <- industry_m %>% filter(산업 == ind)
  n      <- nrow(df_ind)
  out    <- tibble()
  
  ## (1) 산업별로 예측 공식 결정 ─────────────────────────────
  fml <- if (ind %in% corr_sector) {
    next_ret ~ mean_ret + mean_fx + mean_flow + avg_corr
  } else {
    next_ret ~ mean_ret + mean_fx + mean_flow
  }
  
  ## (2) Walk-Forward 루프 ----------------------------------
  for(i in 13:n){               # 최소 12개월 학습 후 매달 예측
    train <- df_ind[1:(i-1), ]
    test  <- df_ind[i, , drop = FALSE]
    
    rf   <- randomForest(fml, data = train, ntree = 300)
    pred <- predict(rf, test)
    
    out <- bind_rows(
      out,
      tibble(산업 = ind,
             yearmon = test$yearmon,
             actual  = test$next_ret,
             pred    = pred)
    )
  }
  predict_all[[ind]] <- out
}
result <- bind_rows(predict_all)

# 5. 최근 6개월 예측만 시각화용 추출 -------------------------------
result_recent <- result %>%
  group_by(산업) %>%
  arrange(yearmon) %>%
  slice_tail(n = 6) %>%
  ungroup()




# 6. 최근 6개월 기준 산업별 RMSE & HitRate 계산 ---------------------

perf_recent <- result_recent %>%
  mutate(
    hit = sign(pred) == sign(actual)
  ) %>%
  group_by(산업) %>%
  summarise(
    RMSE    = sqrt(mean((pred - actual)^2)),
    HitRate = mean(hit),
    n_month = n(),
    .groups = "drop"
  )

print(perf_recent)




# 7. 산업별 그래프 저장 or 출력 -----------------------------------
industries <- unique(result_recent$산업)

for(ind in industries){
  p <- result_recent %>%
    filter(산업 == ind) %>%
    ggplot(aes(x = yearmon)) +
    geom_line(aes(y = actual, color = "실제 수익률"), linewidth = 1) +
    geom_line(aes(y = pred,   color = "예측 수익률"), linewidth = 1) +
    scale_color_manual(values = c("실제 수익률" = "blue", "예측 수익률" = "red")) +
    labs(title = paste0(ind, " 산업 - 최근 6개월 예측 결과"),
         x = "월", y = "수익률") +
    theme_minimal() +
    theme(legend.title = element_blank(),
          axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
}



