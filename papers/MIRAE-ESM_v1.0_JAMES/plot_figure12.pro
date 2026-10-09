pro draw_aod_spatial_distribution, aod_djf, aod_jja, aod0_djf, aod0_jja, bias_djf, bias_jja, lon, lat, lon0, lat0

    ; 1. Import Python Modules
    py = Python.Import('matplotlib.pyplot')
    cm = Python.Import('matplotlib.cm')
    colors_mod = Python.Import('matplotlib.colors')
    gs_mod = Python.Import('matplotlib.gridspec')
    ccrs = Python.Import('cartopy.crs')
    builtins = Python.Import('__builtin__')
    mticker = Python.Import('matplotlib.ticker')
    gridliner_mod = Python.Import('cartopy.mpl.gridliner')
    lat_formatter = builtins.getattr(gridliner_mod, 'LATITUDE_FORMATTER')
    lon_formatter = builtins.getattr(gridliner_mod, 'LONGITUDE_FORMATTER')
    cfeature = Python.Import('cartopy.feature')
    np = Python.Import('numpy')

    ; 2. Setup Colormap (Gray for Land/NaN)
    bounds = [0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.8, 1.0, 1.25, 1.5]
    cmap = py.get_cmap('YlOrRd')
    void = cmap.set_over(color='lightgray')
    norm = colors_mod.BoundaryNorm(bounds, cmap.N)

    cmap_bias = py.get_cmap('RdBu_r', 16)
    void = cmap_bias.set_over(color='lightgray')

    ; 3. Create Figure
    fig = py.figure(figsize=[10, 10])
    cls = builtins.getattr(ccrs, 'Robinson')
    ax_proj = cls.__call__(central_longitude=0.0)
    cls = builtins.getattr(ccrs, 'PlateCarree')
    proj = cls.__call__()

    aod_djf[where(aod_djf ge 1.5,/null)] = 1.5 - 0.001
    aod_djf[where(finite(aod_djf) eq 0,/null)] = 1e20
    aod_jja[where(aod_jja ge 1.5,/null)] = 1.5 - 0.001
    aod_jja[where(finite(aod_jja) eq 0,/null)] = 1e20
    aod0_djf[where(aod0_djf ge 1.5,/null)] = 1.5 - 0.001
    aod0_djf[where(finite(aod0_djf) eq 0,/null)] = 1e20
    aod0_jja[where(aod0_jja ge 1.5,/null)] = 1.5 - 0.001
    aod0_jja[where(finite(aod0_jja) eq 0,/null)] = 1e20
    bias_djf[where(bias_djf ge 0.8,/null)] = 0.8 - 0.001
    bias_djf[where(finite(bias_djf) eq 0,/null)] = 1e20
    bias_jja[where(bias_jja ge 0.8,/null)] = 0.8 - 0.001
    bias_jja[where(finite(bias_jja) eq 0,/null)] = 1e20

    ; ---------------------------------------------------------
    ; MODIS (DJF)
    ; ---------------------------------------------------------
    ax1 = fig.add_axes(Python.List([0, 0.7, 0.5, 0.25]), projection=ax_proj)
    void = ax1.set_title('MODIS (DJF)', fontsize=14, fontweight='bold')

    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im1 = ax1.pcolormesh(lon0, lat0, aod0_djf, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    ;void = ax1.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax1.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MODIS (JJA)
    ; ---------------------------------------------------------
    ax2 = fig.add_axes(Python.List([0.5, 0.7, 0.5, 0.25]), projection=ax_proj)
    void = ax2.set_title('MODIS (JJA)', fontsize=14, fontweight='bold')

    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im2 = ax2.pcolormesh(lon0, lat0, aod0_jja, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    ;void = ax2.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax2.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (DJF)
    ; ---------------------------------------------------------
    ax3 = fig.add_axes(Python.List([0., 0.42, 0.5, 0.25]), projection=ax_proj)
    void = ax3.set_title('MIRAE-ESM (DJF)', fontsize=14, fontweight='bold')

    im3 = ax3.pcolormesh(lon, lat, aod_djf, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    ;void = ax3.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax3.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias (DJF)
    ; ---------------------------------------------------------
    ax4 = fig.add_axes(Python.List([0., 0.05, 0.5, 0.25]), projection=ax_proj)
    void = ax4.set_title('MIRAE-ESM - MODIS (DJF)', fontsize=14, fontweight='bold')

    im4 = ax4.pcolormesh(lon, lat, bias_djf, transform=proj, $
                         cmap=cmap_bias, vmin=-0.8, vmax=0.8, shading='flat')
    ;void = ax4.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax4.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (JJA)
    ; ---------------------------------------------------------
    ax5 = fig.add_axes(Python.List([0.5, 0.42, 0.5, 0.25]), projection=ax_proj)
    void = ax5.set_title('MIRAE-ESM (JJA)', fontsize=14, fontweight='bold')

    im5 = ax5.pcolormesh(lon, lat, aod_jja, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    ;void = ax5.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax5.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias (JJA)
    ; ---------------------------------------------------------
    ax6 = fig.add_axes(Python.List([0.5, 0.05, 0.5, 0.25]), projection=ax_proj)
    void = ax6.set_title('MIRAE-ESM - MODIS (JJA)', fontsize=14, fontweight='bold')

    im6 = ax6.pcolormesh(lon, lat, bias_jja, transform=proj, $
                         cmap=cmap_bias, vmin=-0.8, vmax=0.8, shading='flat')
    ;void = ax6.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax6.coastlines(linewidth=0.5)

    ; Colorbar
    cax1 = fig.add_axes(Python.List([0.25, 0.38, 0.5, 0.015]))
    cb1 = fig.colorbar(im1, cax=cax1, orientation='horizontal', label='Aerosol Optical Depth')
    void = cb1.set_ticks(bounds)
    void = cb1.set_ticklabels(bounds)

    ; Colorbar for Bias
    cax3 = fig.add_axes(Python.List([0.25, 0.01, 0.5, 0.015]))
    cb3 = fig.colorbar(im4, cax=cax3, orientation='horizontal', label='Bias')

    ; Text
    void = ax1.text(0., 1., 'Mean=0.162', transform=ax1.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax2.text(0., 1., 'Mean=0.188', transform=ax2.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(0., 1., 'Mean=0.169', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(0., 1., 'Mean=0.006', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax5.text(0., 1., 'Mean=0.187', transform=ax5.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(0., 1., 'Mean=-0.001', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 1., 'RMSE=0.08', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 0.95, 'r=0.76', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(1., 1., 'RMSE=0.11', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(1., 0.95, 'r=0.71', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))

    ; 4. Save
    void = fig.savefig('figure12.png', dpi=600, bbox_inches='tight')
    print, 'Figure 12 saved.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_aod_2005-2014.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
ncdf_varget, ncid, ncdf_varid(ncid, 'aod'), aod
ncdf_close, ncid

ncid = ncdf_open('data/MODIS_aod_2005-2014.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon0
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat0
ncdf_varget, ncid, ncdf_varid(ncid, 'aod'), aod0
ncdf_close, ncid

aod00=aod
for m=0,11 do begin
  aod00[*,*,m] = interpolate_2d(aod0[*,*,m], lon0, lat0, lon, lat)
endfor

nanid = where(finite(aod00) eq 0)
aod[nanid] = !values.f_nan

aod_djf = mean(aod[*,*,[-1,0,1]],3,/nan)
aod_jja = mean(aod[*,*,[5,6,7]],3,/nan)
aod0_djf = mean(aod0[*,*,[-1,0,1]],3,/nan)
aod0_jja = mean(aod0[*,*,[5,6,7]],3,/nan)
aod00_djf = mean(aod00[*,*,[-1,0,1]],3,/nan)
aod00_jja = mean(aod00[*,*,[5,6,7]],3,/nan)
bias_djf = aod_djf - aod00_djf
bias_jja = aod_jja - aod00_jja

print, gmean(aod0_djf,lat0), gmean(aod0_jja,lat0)
print, gmean(aod_djf,lat), gmean(aod_jja,lat)
print, gmean(bias_djf,lat), gmean(bias_jja,lat)
print, sqrt(gmean((aod_djf-aod00_djf)^2,lat)), sqrt(gmean((aod_jja-aod00_jja)^2,lat))
print, correlate_nan(aod_djf, aod00_djf), correlate_nan(aod_jja, aod00_jja)

lons = fltarr(n_elements(lon)+1)
dx = 0.5 * (lon[1] - lon[0])
lons[0] = lon[0] - dx
lons[-1] = lon[-1] + dx
for i=1, n_elements(lons)-2 do lons[i] = (lon[i-1]+lon[i])*0.5

lats = fltarr(n_elements(lat)+1)
lats[0] = -90.
lats[-1] = 90.
for j=1, n_elements(lats)-2 do lats[j] = (lat[j-1]+lat[j])*0.5

lons0 = fltarr(n_elements(lon0)+1)
dx = 0.5 * (lon0[1] - lon0[0])
lons0[0] = lon0[0] - dx
lons0[-1] = lon0[-1] + dx
for i=1, n_elements(lons0)-2 do lons0[i] = (lon0[i-1]+lon0[i])*0.5

lats0 = fltarr(n_elements(lat0)+1)
lats0[0] = -90.
lats0[-1] = 90.
for j=1, n_elements(lats0)-2 do lats0[j] = (lat0[j-1]+lat0[j])*0.5

draw_aod_spatial_distribution, aod_djf, aod_jja, aod0_djf, aod0_jja, bias_djf, bias_jja, lons, lats, lons0, lats0

spawn, 'display -resize 20% figure12.png &'

end
