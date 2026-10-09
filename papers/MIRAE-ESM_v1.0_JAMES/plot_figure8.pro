pro get_best, best, lon=lon, lat=lat

   file = '/home/sul/DATA/CVDP/obs/best.tas.185001-202412.nc'

   ncid = ncdf_open(file)
   ncdf_varget, ncid, ncdf_varid(ncid, 'longitude'), lon
   ncdf_varget, ncid, ncdf_varid(ncid, 'latitude'), lat
   ncdf_varget, ncid, ncdf_varid(ncid, 'land_mask'), mask
   ncdf_varget, ncid, ncdf_varid(ncid, 'tas'), best
   ncdf_close, ncid

   best = best[*,*,(1985-1850)*12:(2014-1850)*12+11]
   nanid = where(best lt -71.3 or best gt 39.9)
   best[nanid] = !values.f_nan

   best = reform(best,n_elements(lon),n_elements(lat),12,30)
   best = mean(best,4,/nan)

end

pro set_minmax, data, vmin, vmax

    data[where(data lt vmin, /null)] = vmin
    data[where(data ge vmax, /null)] = vmax - 0.001
    data[where(finite(data) eq 0, /null)] = 1e20

end

pro draw_tas_spatial_distribution, obs_djf, obs_jja, bias_djf, bias_jja, lon, lat, lon0, lat0

    ; 1. Import Python Modules
    py = Python.Import('matplotlib.pyplot')
    cm = Python.Import('matplotlib.cm')
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
    cmap_tas = py.get_cmap('RdYlBu_r', 16)
    void = cmap_tas.set_over(color='lightgray')
    
    cmap_bias = py.get_cmap('RdBu_r', 16)
    void = cmap_bias.set_over(color='lightgray')

    ; 3. Create Figure
    fig = py.figure(figsize=[10, 10])
    cls = builtins.getattr(ccrs, 'Robinson')
    ax_proj = cls.__call__()
    cls = builtins.getattr(ccrs, 'PlateCarree')
    proj = cls.__call__()

    ; Set min-max value and masking
    vmin = -40.
    vmax = 40.
    set_minmax, obs_djf, vmin, vmax
    set_minmax, obs_jja, vmin, vmax

    vmin_bias = -12.
    vmax_bias = 12.
    set_minmax, bias_djf, vmin_bias, vmax_bias
    set_minmax, bias_jja, vmin_bias, vmax_bias

    ; ---------------------------------------------------------
    ; BEST (DJF)
    ; ---------------------------------------------------------
    ax1 = fig.add_axes(Python.List([0., 0.53, 0.5, 0.25]), projection=ax_proj)
    void = ax1.set_title('BEST (DJF)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im1 = ax1.pcolormesh(lon0, lat0, obs_djf, transform=proj, $
                         cmap=cmap_tas, vmin=vmin, vmax=vmax, shading='flat')
    void = ax1.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray', zorder=1)
    void = ax1.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; BEST (JJA)
    ; ---------------------------------------------------------
    ax2 = fig.add_axes(Python.List([0., 0.25, 0.5, 0.25]), projection=ax_proj)
    void = ax2.set_title('BEST (JJA)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im2 = ax2.pcolormesh(lon0, lat0, obs_jja, transform=proj, $
                         cmap=cmap_tas, vmin=vmin, vmax=vmax, shading='flat')
    void = ax2.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray', zorder=1)
    void = ax2.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (DJF)
    ; ---------------------------------------------------------
    ax3 = fig.add_axes(Python.List([0.5, 0.53, 0.5, 0.25]), projection=ax_proj)
    void = ax3.set_title('MIRAE-ESM - BEST (DJF)', fontsize=14, fontweight='bold')
    
    im3 = ax3.pcolormesh(lon, lat, bias_djf, transform=proj, $
                         cmap=cmap_bias, vmin=vmin_bias, vmax=vmax_bias, shading='flat')
    void = ax3.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray', zorder=1)
    void = ax3.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (JJA)
    ; ---------------------------------------------------------
    ax4 = fig.add_axes(Python.List([0.5, 0.25, 0.5, 0.25]), projection=ax_proj)
    void = ax4.set_title('MIRAE-ESM - BEST (JJA)', fontsize=14, fontweight='bold')
    
    im4 = ax4.pcolormesh(lon, lat, bias_jja, transform=proj, $
                         cmap=cmap_bias, vmin=vmin_bias, vmax=vmax_bias, shading='flat')
    void = ax4.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray', zorder=1)
    void = ax4.coastlines(linewidth=0.5)

    ; Colorbar
    cax1 = fig.add_axes(Python.List([0.1, 0.22, 0.3, 0.015]))
    cb1 = fig.colorbar(im1, cax=cax1, orientation='horizontal', label='Temperature [$\mathrm{^{\circ}C}$]')
    void = cb1.set_ticks(np.arange(-40,50,10))

    ; Colorbar for Bias
    cax2 = fig.add_axes(Python.List([0.6, 0.22, 0.3, 0.015]))
    cb2 = fig.colorbar(im3, cax=cax2, orientation='horizontal', label='Bias [$\mathrm{^{\circ}C}$]')
    void = cb2.set_ticks(np.arange(-12,15,3))

    ; Text
    void = ax1.text(0., 1., 'Mean=13.10', transform=ax1.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax2.text(0., 1., 'Mean=16.38', transform=ax2.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(0., 1., 'Mean=-2.07', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(1., 1., 'RMSE=4.49', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(1., 0.95, 'r=0.99', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(0., 1., 'Mean=1.07', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 1., 'RMSE=3.19', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 0.95, 'r=0.99', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))

    ; 4. Save
    void = fig.savefig('figure8.png', dpi=600, bbox_inches='tight')
    print, 'Figure 6 saved.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_tas_1985-2014.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
ncdf_varget, ncid, ncdf_varid(ncid, 'tas'), tas
ncdf_close, ncid

get_best, best, lon=lon0, lat=lat0

tas = shift(tas,96,0,0)
lon = shift(lon,96)
id = where(lon ge 180.)
lon[id] = lon[id] - 360.

best_re = tas
for m=0, 11 do begin
   temp = interpolate_2d(best[*,*,m], lon0, lat0, lon, lat)
   best_re[*,*,m] = temp
endfor

bias = tas - best_re

obs_djf = mean(best[*,*,[0,1,11]],3)
obs_jja = mean(best[*,*,[5,6,7]],3)
bias_djf = mean(bias[*,*,[0,1,11]],3)
bias_jja = mean(bias[*,*,[5,6,7]],3)

print, gmean(obs_djf, lat0), gmean(obs_jja, lat0)
print, gmean(bias_djf, lat), gmean(bias_jja, lat)
print, sqrt(gmean((bias_djf)^2,lat)), sqrt(gmean((bias_jja)^2,lat))
print, correlate_nan(mean(tas[*,*,[0,1,11]],3),mean(best_re[*,*,[0,1,11]],3))
print, correlate_nan(mean(tas[*,*,[5,6,7]],3),mean(best_re[*,*,[5,6,7]],3))

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

draw_tas_spatial_distribution, obs_djf, obs_jja, bias_djf, bias_jja, lons, lats, lons0, lats0

spawn, 'display -resize 20% figure8.png &'

end
