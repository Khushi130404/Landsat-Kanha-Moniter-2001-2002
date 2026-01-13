# ============================================================
# NDVI SMOOTHING USING SAVITZKY-GOLAY FILTER
# ============================================================

library(dplyr)
library(lubridate)
library(zoo)
library(signal)    # for sgolayfilt
library(ggplot2)

# --- Input / Output folders ---
input_dir  <- "D:/Landsat_Kanha_Moniter_2001_2002/Data_Table/processed"
output_dir <- "D:/Landsat_Kanha_Moniter_2001_2002/Data_Table/sg_smoothed"
plot_dir   <- file.path(output_dir, "plots")

if (!dir.exists(output_dir)) dir.create(output_dir)
if (!dir.exists(plot_dir)) dir.create(plot_dir)

# --- List CSV files ---
csv_files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
if(length(csv_files)==0) stop("❌ No CSV files found!")

# --- Loop through each region ---
for(file in csv_files) {
  
  cat("Processing:", basename(file), "\n")
  
  ndvi <- read.csv(file, stringsAsFactors = FALSE)
  
  # --- Parse dates ---
  ndvi$date <- as.Date(ndvi$date)
  
  # --- Fill any NA in ndvi_interp with linear approx for SG filter ---
  ndvi$ndvi_interp <- na.approx(ndvi$ndvi_interp, x=ndvi$date, na.rm=FALSE)
  
  # --- Apply Savitzky-Golay filter ---
  # window size must be odd; poly order = 2
  window_size <- 7
  if(window_size %% 2 == 0) window_size <- window_size + 1  # ensure odd
  
  ndvi$ndvi_sg <- sgolayfilt(ndvi$ndvi_interp, p = 2, n = window_size)
  
  # --- Save smoothed CSV ---
  out_csv <- paste0(tools::file_path_sans_ext(basename(file)), "_SG.csv")
  write.csv(ndvi, file.path(output_dir, out_csv), row.names = FALSE)
  cat("✅ Saved CSV:", out_csv, "\n")
  
  # --- Plot smoothed curve ---
  p <- ggplot(ndvi, aes(x=date)) +
    geom_line(aes(y=ndvi_interp), color="grey50", linewidth=0.6) +  # interpolated
    geom_line(aes(y=ndvi_sg), color="blue", linewidth=1) +          # SG-smoothed
    scale_x_date(date_breaks="1 month", date_labels="%b (%Y)") +
    labs(
      title="NDVI SG Smoothed Time Series",
      subtitle=tools::file_path_sans_ext(basename(file)),
      x="Date (Apr 2001 → Apr 2002)",
      y="NDVI"
    ) +
    theme_minimal(base_size=13) +
    theme(axis.text.x = element_text(angle=45, hjust=1))
  
  out_plot <- paste0(tools::file_path_sans_ext(basename(file)), "_NDVI_SG.png")
  ggsave(filename=file.path(plot_dir, out_plot), plot=p, width=10, height=5, dpi=300)
  cat("✅ Saved plot:", out_plot, "\n\n")
}

cat("🎉 All regions processed: SG smoothing + plots generated.\n")
