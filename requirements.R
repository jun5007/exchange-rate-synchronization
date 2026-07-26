packages <- c(
  "tidyverse",
  "lubridate",
  "randomForest"
)

installed <- rownames(installed.packages())
missing <- packages[!(packages %in% installed)]

if (length(missing) > 0) {
  install.packages(missing)
}
