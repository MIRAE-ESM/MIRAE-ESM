import os
import glob
import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from scipy.stats import linregress


# ============================================================
# Settings
# ============================================================

start_year = 1979
end_year   = 2014

# ------------------------------------------------------------
# MIRAE-ESM
# ------------------------------------------------------------

data_dir = "/home/sul/MIRAE-ESM/RUNDIRS/v4/historical"
sst_name = "sst"

# ------------------------------------------------------------
# ERSSTv5
# ------------------------------------------------------------

ersst_file = os.path.expanduser(
    "~/DATA/CVDP/obs/ersstv5.185401-202412.nc"
)


# ============================================================
# 1. Read ERSSTv5
# ============================================================

print("Reading ERSSTv5...")

ds_ersst = xr.open_dataset(ersst_file,decode_times=False)

# ERSSTv5 starts from January 1854
ersst_start = (start_year - 1854) * 12
ersst_end   = (end_year - 1854 + 1) * 12

ersst = ds_ersst["sst"].isel(
    time=slice(ersst_start, ersst_end)
)

# Monthly -> annual mean
ersst_annual = (
    ersst
    .coarsen(time=12, boundary="trim")
    .mean()
)

# Explicit year coordinate
years = np.arange(start_year, end_year + 1)

ersst_annual = ersst_annual.assign_coords(
    time=years
)

print("ERSST annual data:")
print(ersst_annual)


# ============================================================
# 2. Read MIRAE-ESM
# ============================================================

print("\nReading MIRAE-ESM...")

annual_sst = []

for year in years:

    monthly_files = sorted(
        glob.glob(
            os.path.join(
                data_dir,
                str(year),
                f"grims.{year}[0-9][0-9].monthly.nc"
            )
        )
    )

    if len(monthly_files) != 12:
        print(
            f"WARNING: {year}: "
            f"found {len(monthly_files)} monthly files"
        )

    monthly_data = []

    for f in monthly_files:

        ds = xr.open_dataset(f,decode_times=False)

        sst = ds[sst_name].isel(time=0).load()

        monthly_data.append(sst)

        ds.close()

    # Annual mean
    year_mean = xr.concat(
        monthly_data,
        dim="month"
    ).mean(dim="month")

    annual_sst.append(year_mean)


mirae_annual = xr.concat(
    annual_sst,
    dim="time"
)

mirae_annual = mirae_annual.assign_coords(
    time=years
)

print("MIRAE-ESM annual data:")
print(mirae_annual)


# ============================================================
# 3. Longitude handling
# ============================================================

# Make sure longitude is 0–360 for both datasets

if np.any(mirae_annual.lon.values < 0):
    mirae_annual = (
        mirae_annual
        .assign_coords(
            lon=(mirae_annual.lon % 360)
        )
        .sortby("lon")
    )

if np.any(ersst_annual.lon.values < 0):
    ersst_annual = (
        ersst_annual
        .assign_coords(
            lon=(ersst_annual.lon % 360)
        )
        .sortby("lon")
    )


# ============================================================
# 4. Calculate linear trend
# ============================================================

def calculate_trend(data, years):

    nlat = data.sizes["lat"]
    nlon = data.sizes["lon"]

    trend = np.full(
        (nlat, nlon),
        np.nan
    )

    x = np.asarray(years)

    for i in range(nlat):

        for j in range(nlon):

            y = data[:, i, j].values

            valid = np.isfinite(y)

            if np.sum(valid) >= 2:

                slope, intercept, r, p, stderr = \
                    linregress(
                        x[valid],
                        y[valid]
                    )

                # °C/year -> °C/decade
                trend[i, j] = slope * 10.0

    return xr.DataArray(
        trend,
        coords={
            "lat": data.lat,
            "lon": data.lon
        },
        dims=["lat", "lon"],
        name="sst_trend"
    )


print("\nCalculating ERSSTv5 trend...")

ersst_trend = calculate_trend(
    ersst_annual,
    years
)

print("Calculating MIRAE-ESM trend...")

mirae_trend = calculate_trend(
    mirae_annual,
    years
)


# ============================================================
# 5. Color settings
# ============================================================

# 0.2°C interval
levels = np.arange(
    -0.5,
    0.51,
    0.05
)

# Discrete colormap
cmap = plt.get_cmap(
    "RdBu_r",
    len(levels) - 1
)

norm = mcolors.BoundaryNorm(
    levels,
    cmap.N,
    clip=True
)


# ============================================================
# 6. Plot
# ============================================================

projection = ccrs.Robinson(
    central_longitude=180
)

data_crs = ccrs.PlateCarree()


# ------------------------------------------------------------
# Figure
# ------------------------------------------------------------

fig = plt.figure(
    figsize=(10, 5)
)


# Explicit axes positions
# [left, bottom, width, height]

ax1 = fig.add_axes(
    [0.025, 0.17, 0.465, 0.70],
    projection=projection
)

ax2 = fig.add_axes(
    [0.510, 0.17, 0.465, 0.70],
    projection=projection
)


# ============================================================
# 7. Common map settings
# ============================================================

for ax in [ax1, ax2]:

    ax.set_global()

    ax.add_feature(
        cfeature.LAND,
        facecolor="lightgray",
        edgecolor="none",
        zorder=2
    )

    ax.coastlines(
        linewidth=0.6,
        zorder=3
    )


# ============================================================
# 8. ERSSTv5
# ============================================================

im1 = ax1.pcolormesh(
    ersst_trend.lon,
    ersst_trend.lat,
    ersst_trend,
    cmap=cmap,
    norm=norm,
    shading="auto",
    transform=data_crs,
    zorder=1
)

ax1.set_title(
    "(a) ERSSTv5",
    fontsize=14,
    fontweight='bold',
    pad=8
)


# ============================================================
# 9. MIRAE-ESM
# ============================================================

im2 = ax2.pcolormesh(
    mirae_trend.lon,
    mirae_trend.lat,
    mirae_trend,
    cmap=cmap,
    norm=norm,
    shading="auto",
    transform=data_crs,
    zorder=1
)

ax2.set_title(
    "(b) MIRAE-ESM",
    fontsize=14,
    fontweight='bold',
    pad=8
)


# ============================================================
# 10. Common colorbar
# ============================================================

# Explicit colorbar position
cax = fig.add_axes(
    [0.25, 0.2, 0.50, 0.025]
)

cbar = fig.colorbar(
    im2,
    cax=cax,
    orientation="horizontal",
    ticks=levels[::2]
)

cbar.set_label(
    "SST trend (°C decade$^{-1}$)",
    fontsize=12
)

cbar.ax.tick_params(
    labelsize=10
)


# ============================================================
# 11. Figure title
# ============================================================

#fig.suptitle(
#    "SST Trend (1979–2014)",
#    fontsize=16,
#    y=0.96
#)


# ============================================================
# 12. Save
# ============================================================

output_file = "figure6.png"

plt.savefig(
    output_file,
    dpi=600,
    bbox_inches="tight"
)

plt.show()

print(f"\nSaved: {output_file}")
