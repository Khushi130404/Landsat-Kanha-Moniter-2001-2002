import matplotlib.pyplot as plt
from qgis.core import QgsProject

def plot_ndvi_apr_to_mar(
    layer_name,
    start_year,
    ndvi_field="median_ndvi",
    year_field="year",
    month_field="month",
    day_field="day"
):
    """
    Plot NDVI from Apr(start_year) to Mar(start_year+1)
    """

    layer = QgsProject.instance().mapLayersByName(layer_name)[0]

    # Apr → Mar order
    month_order = [4,5,6,7,8,9,10,11,12,1,2,3]
    month_names = {
        1:"Jan", 2:"Feb", 3:"Mar", 4:"Apr",
        5:"May", 6:"Jun", 7:"Jul", 8:"Aug",
        9:"Sep", 10:"Oct", 11:"Nov", 12:"Dec"
    }
    month_index = {m:i+1 for i,m in enumerate(month_order)}

    x_vals = []
    y_vals = []

    for f in layer.getFeatures():
        try:
            year  = int(f[year_field])
            month = int(f[month_field])
            day   = int(f[day_field])
            ndvi  = float(f[ndvi_field])
        except:
            continue

        # NDVI validity
        if ndvi <= 0 or ndvi > 1:
            continue

        # ---- YEAR LOGIC FIX ----
        if month >= 4:
            if year != start_year:
                continue
        else:  # Jan–Mar
            if year != start_year + 1:
                continue

        if month not in month_index:
            continue

        # Month position + small daily offset
        x = month_index[month] + (day / 31.0) * 0.3
        x_vals.append(x)
        y_vals.append(ndvi)

    if not x_vals:
        print("⚠ No valid data points found")
        return

    # Sort chronologically
    x_vals, y_vals = zip(*sorted(zip(x_vals, y_vals)))

    # ------------------------
    # PLOT
    # ------------------------
    plt.figure(figsize=(14,5))
    plt.scatter(x_vals, y_vals, s=60)
    plt.plot(x_vals, y_vals, alpha=0.6)

    plt.xticks(
        ticks=range(1,13),
        labels=[month_names[m] for m in month_order]
    )

    plt.xlabel("Month (Apr → Mar)")
    plt.ylabel("NDVI")
    plt.title(f"NDVI Time Series — Apr {start_year} to Mar {start_year+1}")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

plot_ndvi_apr_to_mar(
    layer_name="se_kanha_table",
    start_year=2001
)
