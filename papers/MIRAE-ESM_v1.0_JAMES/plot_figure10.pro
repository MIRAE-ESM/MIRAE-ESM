pro get_cf_ceres, swcf, lwcf, lon=lon, lat=lat

   file = '/home/sul/GRIMs-NEMO/obsdata/CERES_EBAF_Ed4.2.1_Subset_CLIM01-CLIM12.nc'

   ncid = ncdf_open(file)

   ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
   ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat

   ncdf_varget, ncid, ncdf_varid(ncid, 'toa_cre_sw_clim'), swcf
   ncdf_varget, ncid, ncdf_varid(ncid, 'toa_cre_lw_clim'), lwcf

   ncdf_close, ncid

end

pro set_minmax, data, vmin, vmax

    data[where(data lt vmin, /null)] = vmin
    data[where(data ge vmax, /null)] = vmax - 0.001
    data[where(finite(data) eq 0, /null)] = 1e20

end

pro draw_cf_spatial_distribution, swcf, lwcf, swcf0, lwcf0, swbias, lwbias, lon, lat, lon0, lat0

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
    bounds_sw = [-120, -100, -80, -60, -40, -20, -10, -5, 0]
    bounds_sw2 = interpol(bounds_sw, 17)
    cmap_sw = py.get_cmap('YlGnBu_r')
    norm_sw = colors_mod.BoundaryNorm(bounds_sw2, cmap_sw.N)
    void = cmap_sw.set_over(color='lightgray')
    bounds_lw = [0, 5, 10, 20, 30, 40, 50, 60, 70, 80]
    bounds_lw2 = interpol(bounds_lw, 19)
    cmap_lw = py.get_cmap('YlOrRd')
    norm_lw = colors_mod.BoundaryNorm(bounds_lw2, cmap_lw.N)
    void = cmap_lw.set_over(color='lightgray')
    
    bounds_bias = [-40, -30, -20, -10, -5, 5, 10, 20, 30, 40]
    bounds_bias2 = interpol(bounds_bias, 19)
    cmap_bias = py.get_cmap('RdBu_r')
    norm_bias = colors_mod.BoundaryNorm(bounds_bias2,cmap_bias.N)
    void = cmap_bias.set_over(color='lightgray')

    ; 3. Create Figure
    fig = py.figure(figsize=[10, 10])
    cls = builtins.getattr(ccrs, 'Robinson')
    ax_proj = cls.__call__(central_longitude=180.0)
    cls = builtins.getattr(ccrs, 'PlateCarree')
    proj = cls.__call__()

    ; Set min-max value and masking
    vmin_sw = bounds_sw[0]
    vmax_sw = bounds_sw[-1] - 0.001
    set_minmax, swcf, vmin_sw, vmax_sw
    set_minmax, swcf0, vmin_sw, vmax_sw

    vmin_lw = bounds_lw[0]
    vmax_lw = bounds_lw[-1] - 0.001
    set_minmax, lwcf, vmin_lw, vmax_lw
    set_minmax, lwcf0, vmin_lw, vmax_lw

    vmin_bias = bounds_bias[0]
    vmax_bias = bounds_bias[-1] - 0.001
    set_minmax, swbias, vmin_bias, vmax_bias
    set_minmax, lwbias, vmin_bias, vmax_bias

    ; ---------------------------------------------------------
    ; CERES (SWCF)
    ; ---------------------------------------------------------
    ax1 = fig.add_axes(Python.List([0., 0.7, 0.5, 0.25]), projection=ax_proj)
    void = ax1.set_title('CERES (SWCF)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im1 = ax1.pcolormesh(lon0, lat0, swcf0, transform=proj, $
                         cmap=cmap_sw, norm=norm_sw, shading='flat')
    ;void = ax1.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax1.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; CERES (LWCF)
    ; ---------------------------------------------------------
    ax2 = fig.add_axes(Python.List([0.5, 0.7, 0.5, 0.25]), projection=ax_proj)
    void = ax2.set_title('CERES (LWCF)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im2 = ax2.pcolormesh(lon0, lat0, lwcf0, transform=proj, $
                         cmap=cmap_lw, norm=norm_lw, shading='flat')
    ;void = ax2.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax2.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (SWCF)
    ; ---------------------------------------------------------
    ax3 = fig.add_axes(Python.List([0., 0.42, 0.5, 0.25]), projection=ax_proj)
    void = ax3.set_title('MIRAE-ESM (SWCF)', fontsize=14, fontweight='bold')
    
    im3 = ax3.pcolormesh(lon, lat, swcf, transform=proj, $
                         cmap=cmap_sw, norm=norm_sw, shading='flat')
    ;void = ax3.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax3.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias (SWCF)
    ; ---------------------------------------------------------
    ax4 = fig.add_axes(Python.List([0., 0.05, 0.5, 0.25]), projection=ax_proj)
    void = ax4.set_title('MIRAE-ESM - CERES (SWCF)', fontsize=14, fontweight='bold')
    
    im4 = ax4.pcolormesh(lon, lat, swbias, transform=proj, $
                         cmap=cmap_bias, norm=norm_bias, shading='flat')
    ;void = ax4.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax4.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (LWCF)
    ; ---------------------------------------------------------
    ax5 = fig.add_axes(Python.List([0.5, 0.42, 0.5, 0.25]), projection=ax_proj)
    void = ax5.set_title('MIRAE-ESM (LWCF)', fontsize=14, fontweight='bold')
    
    im5 = ax5.pcolormesh(lon, lat, lwcf, transform=proj, $
                         cmap=cmap_lw, norm=norm_lw, shading='flat')
    ;void = ax5.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax5.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias (LWCF)
    ; ---------------------------------------------------------
    ax6 = fig.add_axes(Python.List([0.5, 0.05, 0.5, 0.25]), projection=ax_proj)
    void = ax6.set_title('MIRAE-ESM - CERES (LWCF)', fontsize=14, fontweight='bold')
    
    im6 = ax6.pcolormesh(lon, lat, lwbias, transform=proj, $
                         cmap=cmap_bias, norm=norm_bias, shading='flat')
    ;void = ax6.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax6.coastlines(linewidth=0.5)

    ; Colorbar
    cax1 = fig.add_axes(Python.List([0.1, 0.38, 0.3, 0.015]))
    cb1 = fig.colorbar(im1, cax=cax1, orientation='horizontal', label='Cloud Forcing [$\mathrm{W\ m^{-2}}$]')
    void = cb1.set_ticks(bounds_sw)
    void = cb1.set_ticklabels(bounds_sw)

    ; Colorbar
    cax2 = fig.add_axes(Python.List([0.6, 0.38, 0.3, 0.015]))
    cb2 = fig.colorbar(im2, cax=cax2, orientation='horizontal', label='Cloud Forcing [$\mathrm{W\ m^{-2}}$]')
    void = cb2.set_ticks(bounds_lw)
    void = cb2.set_ticklabels(bounds_lw)

    ; Colorbar for Bias
    cax3 = fig.add_axes(Python.List([0.25, 0.01, 0.5, 0.015]))
    cb3 = fig.colorbar(im4, cax=cax3, orientation='horizontal', label='Bias [$\mathrm{W\ m^{-2}}$]')
    void = cb3.set_ticks(bounds_bias)
    void = cb3.set_ticklabels(bounds_bias)

    ; Text
    void = ax1.text(0., 1., 'Mean=-45.4', transform=ax1.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax2.text(0., 1., 'Mean=25.7', transform=ax2.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(0., 1., 'Mean=-47.4', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(0., 1., 'Mean=-2.04', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax5.text(0., 1., 'Mean=20.3', transform=ax5.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(0., 1., 'Mean=-5.40', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 1., 'RMSE=12.4', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 0.95, 'r=0.88', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(1., 1., 'RMSE=7.65', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(1., 0.95, 'r=0.92', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))

    ; 4. Save
    void = fig.savefig('figure10.png', dpi=600, bbox_inches='tight')
    print, 'Figure 10 saved.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_cf_2005-2014.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
ncdf_varget, ncid, ncdf_varid(ncid, 'swcf'), swcf
ncdf_varget, ncid, ncdf_varid(ncid, 'lwcf'), lwcf
ncdf_close, ncid

get_cf_ceres, swcf0, lwcf0, lon=lon0, lat=lat0

swcf00 = swcf
lwcf00 = lwcf
for m=0, 11 do begin
   swcf00[*,*,m] = interpolate_2d(swcf0[*,*,m], lon0, lat0, lon, lat)
   lwcf00[*,*,m] = interpolate_2d(lwcf0[*,*,m], lon0, lat0, lon, lat)
endfor

swcf = mean(swcf,3)
lwcf = mean(lwcf,3)
swcf0 = mean(swcf0,3)
lwcf0 = mean(lwcf0,3)
swcf00 = mean(swcf00,3)
lwcf00 = mean(lwcf00,3)

swbias = swcf - swcf00
lwbias = lwcf - lwcf00

print, gmean(swcf, lat), gmean(lwcf, lat)
print, gmean(swcf0, lat0), gmean(lwcf0, lat0)
print, gmean(swbias, lat), gmean(lwbias, lat)
print, sqrt(gmean((swbias)^2,lat)), sqrt(gmean((lwbias)^2,lat))
print, correlate_nan(swcf, swcf00)
print, correlate_nan(lwcf, lwcf00)

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

draw_cf_spatial_distribution, swcf, lwcf, swcf0, lwcf0, swbias, lwbias, lons, lats, lons0, lats0

spawn, 'display -resize 20% figure10.png &'

end
