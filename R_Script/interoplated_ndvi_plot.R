# ============================================================
# NDVI TIME-SERIES PLOT (APR 2001 → APR 2002)
# ============================================================

library(dplyr)
library(ggplot2)
library(lubridate)

# -----------------------------
# INPUT / OUTPUT FOLDERS
# -----------------------------
input_dir  <- "D:/Landsat_Kanha_Moniter_2001_2002/Data_Table/data_interpolated"
output_dir <- "D:/Landsat_Kanha_Moniter_2001_2002/image/plot_interpolation"

if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# -----------------------------
# LIST FILES
# -----------------------------
csv_files <- list.files(
  input_dir,
  pattern = "_5day_interpolated\\.csv$",
  full.names = TRUE
)

# -----------------------------
# LOOP THROUGH REGIONS
# -----------------------------
for (file in csv_files) {
  
  cat("Plotting:", basename(file), "\n")
  
  ndvi <- read.csv(file, stringsAsFactors = FALSE)
  
  ndvi$date <- as.Date(ndvi$date)
  
  # Remove edge NA values
  ndvi <- ndvi %>% filter(!is.na(ndvi_interp))
  
  # -------------------------
  # TIME-SERIES PLOT
  # -------------------------
  p <- ggplot(ndvi, aes(x = date, y = ndvi_interp)) +
    geom_line(color = "blue", linewidth = 0.8) +
    geom_point(color = "red", size = 1) +
    
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b (%Y)"
    ) +
    
    labs(
      title = "Interpolated NDVI Time Series",
      subtitle = tools::file_path_sans_ext(basename(file)),
      x = "Time (Apr 2001 – Apr 2002)",
      y = "Interpolated NDVI"
    ) +
    
    theme_minimal(base_size = 13) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  # -------------------------
  # SAVE PLOT
  # -------------------------
  out_plot <- paste0(
    tools::file_path_sans_ext(basename(file)),
    "_NDVI_Apr2001_Apr2002.png"
  )
  
  ggsave(
    filename = file.path(output_dir, out_plot),
    plot = p,
    width = 10,
    height = 5,
    dpi = 300
  )
  
  cat("Saved:", out_plot, "\n\n")
}

cat("✅ NDVI time-series plots generated correctly.\n")
