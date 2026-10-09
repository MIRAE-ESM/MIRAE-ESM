pro get_gpcp, gpcp, lon=lon, lat=lat

   file = '/home/sul/DATA/CVDP/obs/gpcp.mon.mean.197901-202412.nc'

   ncid = ncdf_open(file)
   ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
   ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
   ncdf_varget, ncid, ncdf_varid(ncid, 'precip'), gpcp
   ncdf_close, ncid

   gpcp = gpcp[*,*,(1985-1979)*12:(2014-1979)*12+11]
   nanid = where(gpcp lt 0. or gpcp gt 100.)
   gpcp[nanid] = !values.f_nan

   gpcp = reform(gpcp,n_elements(lon),n_elements(lat),12,30)
   gpcp = mean(gpcp,4,/nan)

end

pro set_minmax, data, vmin, vmax

    data[where(data lt vmin, /null)] = vmin
    data[where(data ge vmax, /null)] = vmax - 0.001
    data[where(finite(data) eq 0, /null)] = 1e20

end

pro draw_pr_spatial_distribution, pr_djf, pr_jja, obs_djf, obs_jja, bias_djf, bias_jja, lon, lat, lon0, lat0

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
    bounds = ['0', '0.1', '0.5', '1', '2', '3', '4', '6', '8', '10', '12', '15', '20']
    bounds_pr = interpol(float(bounds),25)
    cmap_pr = py.get_cmap('YlGnBu')
    norm_pr = colors_mod.BoundaryNorm(bounds_pr, cmap_pr.N)
    void = cmap_pr.set_over(color='lightgray')
    
    bounds2 = ['-8', '-6', '-4', '-2', '-1', '-0.5', '0.5', '1', '2', '4', '6', '8']
    bounds_bias = interpol(float(bounds2),23)
    cmap_bias = py.get_cmap('BrBG')
    norm_bias = colors_mod.BoundaryNorm(bounds_bias, cmap_bias.N)
    void = cmap_bias.set_over(color='lightgray')

    ; 3. Create Figure
    fig = py.figure(figsize=[10, 10])
    cls = builtins.getattr(ccrs, 'Robinson')
    ax_proj = cls.__call__(central_longitude=180.0)
    cls = builtins.getattr(ccrs, 'PlateCarree')
    proj = cls.__call__()

    ; Set min-max value and masking
    vmin = 0.
    vmax = 20.
    set_minmax, pr_djf, vmin, vmax
    set_minmax, pr_jja, vmin, vmax
    set_minmax, obs_djf, vmin, vmax
    set_minmax, obs_jja, vmin, vmax

    vmin_bias = -8.
    vmax_bias = 8.
    set_minmax, bias_djf, vmin_bias, vmax_bias
    set_minmax, bias_jja, vmin_bias, vmax_bias

    ; ---------------------------------------------------------
    ; GPCP (DJF)
    ; ---------------------------------------------------------
    ax1 = fig.add_axes(Python.List([0., 0.7, 0.5, 0.25]), projection=ax_proj)
    void = ax1.set_title('GPCP (DJF)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im1 = ax1.pcolormesh(lon0, lat0, obs_djf, transform=proj, $
                         cmap=cmap_pr, norm=norm_pr, shading='flat')
    ;void = ax1.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax1.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; GPCP (JJA)
    ; ---------------------------------------------------------
    ax2 = fig.add_axes(Python.List([0.5, 0.7, 0.5, 0.25]), projection=ax_proj)
    void = ax2.set_title('GPCP (JJA)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im2 = ax2.pcolormesh(lon0, lat0, obs_jja, transform=proj, $
                         cmap=cmap_pr, norm=norm_pr, shading='flat')
    ;void = ax2.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax2.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (DJF)
    ; ---------------------------------------------------------
    ax3 = fig.add_axes(Python.List([0., 0.42, 0.5, 0.25]), projection=ax_proj)
    void = ax3.set_title('MIRAE-ESM (DJF)', fontsize=14, fontweight='bold')
    
    im3 = ax3.pcolormesh(lon, lat, pr_djf, transform=proj, $
                         cmap=cmap_pr, norm=norm_pr, shading='flat')
    ;void = ax3.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax3.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias (DJF)
    ; ---------------------------------------------------------
    ax4 = fig.add_axes(Python.List([0., 0.05, 0.5, 0.25]), projection=ax_proj)
    void = ax4.set_title('MIRAE-ESM - GPCP (DJF)', fontsize=14, fontweight='bold')
    
    im4 = ax4.pcolormesh(lon, lat, bias_djf, transform=proj, $
                         cmap=cmap_bias, norm=norm_bias, shading='flat')
    ;void = ax4.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax4.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM (JJA)
    ; ---------------------------------------------------------
    ax5 = fig.add_axes(Python.List([0.5, 0.42, 0.5, 0.25]), projection=ax_proj)
    void = ax5.set_title('MIRAE-ESM (JJA)', fontsize=14, fontweight='bold')
    
    im5 = ax5.pcolormesh(lon, lat, pr_jja, transform=proj, $
                         cmap=cmap_pr, norm=norm_pr, shading='flat')
    ;void = ax5.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax5.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias (JJA)
    ; ---------------------------------------------------------
    ax6 = fig.add_axes(Python.List([0.5, 0.05, 0.5, 0.25]), projection=ax_proj)
    void = ax6.set_title('MIRAE-ESM - GPCP (JJA)', fontsize=14, fontweight='bold')
    
    im6 = ax6.pcolormesh(lon, lat, bias_jja, transform=proj, $
                         cmap=cmap_bias, norm=norm_bias, shading='flat')
    ;void = ax6.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    void = ax6.coastlines(linewidth=0.5)

    ; Colorbar
    cax1 = fig.add_axes(Python.List([0.25, 0.38, 0.5, 0.015]))
    cb1 = fig.colorbar(im1, cax=cax1, orientation='horizontal', label='Precipitation [$\mathrm{mm\ day^{-1}}$]')
    void = cb1.set_ticks(python.list(float(bounds)))
    void = cb1.set_ticklabels(bounds)

    ; Colorbar for Bias
    cax2 = fig.add_axes(Python.List([0.25, 0.01, 0.5, 0.015]))
    cb2 = fig.colorbar(im4, cax=cax2, orientation='horizontal', label='Bias [$\mathrm{mm\ day^{-1}}$]')
    void = cb2.set_ticks(python.list(float(bounds2)))
    void = cb2.set_ticklabels(bounds2)

    ; Text
    void = ax1.text(0., 1., 'Mean=2.70', transform=ax1.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax2.text(0., 1., 'Mean=2.71', transform=ax2.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(0., 1., 'Mean=3.00', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(0., 1., 'Mean=0.31', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax5.text(0., 1., 'Mean=3.11', transform=ax5.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(0., 1., 'Mean=0.39', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 1., 'RMSE=1.19', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax4.text(1., 0.95, 'r=0.91', transform=ax4.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(1., 1., 'RMSE=1.37', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax6.text(1., 0.95, 'r=0.89', transform=ax6.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))

    ; 4. Save
    void = fig.savefig('figure9.png', dpi=600, bbox_inches='tight')
    print, 'Figure 9 saved.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_pr_1985-2014.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
ncdf_varget, ncid, ncdf_varid(ncid, 'pr'), pr
ncdf_close, ncid

get_gpcp, gpcp, lon=lon0, lat=lat0

gpcp_re = pr
for m=0, 11 do begin
   temp = interpolate_2d(gpcp[*,*,m], lon0, lat0, lon, lat)
   gpcp_re[*,*,m] = temp
endfor

bias = pr - gpcp_re

pr_djf = mean(pr[*,*,[0,1,11]],3)
pr_jja = mean(pr[*,*,[5,6,7]],3)
obs_djf = mean(gpcp[*,*,[0,1,11]],3)
obs_jja = mean(gpcp[*,*,[5,6,7]],3)
bias_djf = mean(bias[*,*,[0,1,11]],3)
bias_jja = mean(bias[*,*,[5,6,7]],3)

print, gmean(obs_djf, lat0), gmean(obs_jja, lat0)
print, gmean(pr_djf, lat), gmean(pr_jja, lat)
print, gmean(bias_djf, lat), gmean(bias_jja, lat)
print, sqrt(gmean((bias_djf)^2,lat)), sqrt(gmean((bias_jja)^2,lat))
print, correlate_nan(mean(pr[*,*,[0,1,11]],3),mean(gpcp_re[*,*,[0,1,11]],3))
print, correlate_nan(mean(pr[*,*,[5,6,7]],3),mean(gpcp_re[*,*,[5,6,7]],3))

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

draw_pr_spatial_distribution, pr_djf, pr_jja, obs_djf, obs_jja, bias_djf, bias_jja, lons, lats, lons0, lats0

spawn, 'display -resize 20% figure9.png &'

end
