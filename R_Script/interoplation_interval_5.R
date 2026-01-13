# ============================================================
# SHAPE-PRESERVING NDVI 5-DAY INTERPOLATION (PCHIP)
# ============================================================

library(dplyr)
library(zoo)
library(lubridate)
library(splines)

# -----------------------------
# FIXED STUDY PERIOD
# -----------------------------
study_start <- as.Date("2001-04-01")
study_end   <- as.Date("2002-04-30")

# -----------------------------
# INPUT / OUTPUT FOLDERS
# -----------------------------
input_dir  <- "D:/Landsat_Kanha_Moniter_2001_2002/Data_Table/data_raw"
output_dir <- "D:/Landsat_Kanha_Moniter_2001_2002/Data_Table/data_interpolated"

if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# -----------------------------
# LIST ALL CSV FILES
# -----------------------------
csv_files <- list.files(
  input_dir,
  pattern = "\\.csv$",   # <- match all CSVs
  full.names = TRUE
)

if(length(csv_files) == 0){
  stop("❌ No CSV files found in input folder! Check path or pattern.")
}

# -----------------------------
# PROCESS EACH REGION
# -----------------------------
for (file in csv_files) {
  
  cat("Processing:", basename(file), "\n")
  
  ndvi <- read.csv(file, stringsAsFactors = FALSE)
  
  # ---- FIX DATE FORMAT (DD-MM-YYYY)
  ndvi$date <- as.Date(ndvi$date, format = "%d-%m-%Y")
  
  # ---- CONVERT 'nan' TO NA
  ndvi$median_ndvi <- as.numeric(ndvi$median_ndvi)
  
  # ---- KEEP STUDY PERIOD ONLY
  ndvi <- ndvi %>%
    filter(date >= study_start & date <= study_end) %>%
    arrange(date)
  
  # ---- CREATE 5-DAY REGULAR TIMELINE
  date_5day <- seq(
    from = study_start,
    to   = study_end,
    by   = "5 days"
  )
  
  ndvi_5day <- data.frame(date = date_5day)
  
  # ---- MERGE NDVI + LANDSAT
  ndvi_merge <- merge(
    ndvi_5day,
    ndvi[, c("date", "median_ndvi", "landsat")],
    by = "date",
    all.x = TRUE
  )
  
  # ---- SHAPE-PRESERVING INTERPOLATION (PCHIP)
  ndvi_merge$ndvi_interp <- na.spline(
    ndvi_merge$median_ndvi,
    x = ndvi_merge$date,
    method = "monoH.FC",
    na.rm = FALSE
  )
  
  # ---- FILL LANDSAT (LAST OBSERVATION)
  ndvi_merge$landsat <- na.locf(
    ndvi_merge$landsat,
    na.rm = FALSE
  )
  
  # ---- RECOMPUTE DATE COMPONENTS
  ndvi_merge$year  <- year(ndvi_merge$date)
  ndvi_merge$month <- month(ndvi_merge$date)
  ndvi_merge$day   <- day(ndvi_merge$date)
  
  # ---- SAVE OUTPUT
  out_file <- paste0(
    tools::file_path_sans_ext(basename(file)),
    "_5day_interpolated_shape.csv"
  )
  
  write.csv(
    ndvi_merge,
    file.path(output_dir, out_file),
    row.names = FALSE
  )
  
  cat("✅ Saved:", out_file, "\n\n")
}

cat("🎉 Shape-preserving 5-day interpolation completed for all regions.\n")
