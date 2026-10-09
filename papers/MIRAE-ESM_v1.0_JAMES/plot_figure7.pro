pro get_ersst, sst, lon=lon, lat=lat

   file = '/home/sul/DATA/CVDP/obs/ersstv5.185401-202412.nc'

   ncid = ncdf_open(file)
   ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
   ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
   ncdf_varget, ncid, ncdf_varid(ncid, 'sst'), sst
   ncdf_close, ncid

   sst = sst[*,*,(1985-1854)*12:(2014-1854)*12+11]
   nanid = where(sst lt -3. or sst gt 45.)
   sst[nanid] = !values.f_nan
   sst = mean(sst,3,/nan)

end

pro draw_sst_spatial_distribution, model_sst, obs_sst, bias, lons, lats, lons0, lats0

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
    cmap_sst = py.get_cmap('RdYlBu_r', 16)
    void = cmap_sst.set_over(color='lightgray')
    
    cmap_bias = py.get_cmap('RdBu_r', 16)
    void = cmap_bias.set_over(color='lightgray')

    ; 3. Create Figure
    fig = py.figure(figsize=[10, 10])
    cls = builtins.getattr(ccrs, 'Robinson')
    ax_proj = cls.__call__(central_longitude=180.0)
    cls = builtins.getattr(ccrs,'PlateCarree')
    proj = cls.__call__()

    ; Set min-max value and masking
    vmin = -2.
    vmax = 30.
    model_sst[where(model_sst lt vmin, /null)] = vmin
    model_sst[where(model_sst ge vmax, /null)] = vmax - 0.001
    model_sst[where(finite(model_sst) eq 0, /null)] = 1e20
    obs_sst[where(obs_sst lt vmin, /null)] = vmin
    obs_sst[where(obs_sst ge vmax, /null)] = vmax - 0.001
    obs_sst[where(finite(obs_sst) eq 0, /null)] = 1e20

    vmin_bias = -4.
    vmax_bias = 4.
    bias[where(bias lt vmin_bias, /null)] = vmin_bias
    bias[where(bias ge vmax_bias, /null)] = vmax_bias - 0.001
    bias[where(finite(bias) eq 0, /null)] = 1e20

    ; ---------------------------------------------------------
    ; (a) ERSSTv5
    ; ---------------------------------------------------------
    ax1 = fig.add_axes(Python.List([0.25, 0.53, 0.5, 0.25]), projection=ax_proj)
    void = ax1.set_title('(a) ERSSTv5', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im1 = ax1.pcolormesh(lons0, lats0, obs_sst, transform=proj, $
                         cmap=cmap_sst, vmin=vmin, vmax=vmax, shading='flat')
    void = ax1.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax1.coastlines(linewidth=0.5)

    ;gl1 = ax1.gridlines(draw_labels=Python.True, linewidth=0.5, color='gray', alpha=0.5, linestyle='--')
    ;void = builtins.setattr(gl1, 'xlabels_top', Python.False)
    ;void = builtins.setattr(gl1, 'ylabels_right', Python.False)

    ;lon_ticks = Python.List([60, 120, 180, -120, -60])
    ;void = builtins.setattr(gl1, 'xlocator', mticker.FixedLocator(lon_ticks))
    ;void = builtins.setattr(gl1, 'xformatter', lon_formatter)

    ;lat_ticks = Python.List([-90, -60, -30, 0, 30, 60, 90])
    ;void = builtins.setattr(gl1, 'ylocator', mticker.FixedLocator(lat_ticks))
    ;void = builtins.setattr(gl1, 'yformatter', lat_formatter)

    ; ---------------------------------------------------------
    ; (b) MIRAE-ESM
    ; ---------------------------------------------------------
    ax2 = fig.add_axes(Python.List([0., 0.25, 0.5, 0.25]), projection=ax_proj)
    void = ax2.set_title('(b) MIRAE-ESM', fontsize=14, fontweight='bold')
    
    im2 = ax2.pcolormesh(lons, lats, model_sst, transform=proj, $
                         cmap=cmap_sst, vmin=vmin, vmax=vmax, shading='flat')
    void = ax2.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax2.coastlines(linewidth=0.5)

    ;gl2 = ax2.gridlines(draw_labels=Python.True, linewidth=0.5, color='gray', alpha=0.5, linestyle='--')
    ;void = builtins.setattr(gl2, 'xlabels_top', Python.False)
    ;void = builtins.setattr(gl2, 'ylabels_right', Python.False)

    ;lon_ticks = Python.List([60, 120, 180, -120, -60])
    ;void = builtins.setattr(gl2, 'xlocator', mticker.FixedLocator(lon_ticks))
    ;void = builtins.setattr(gl2, 'xformatter', lon_formatter)

    ;lat_ticks = Python.List([-90, -60, -30, 0, 30, 60, 90])
    ;void = builtins.setattr(gl2, 'ylocator', mticker.FixedLocator(lat_ticks))
    ;void = builtins.setattr(gl2, 'yformatter', lat_formatter)

    ; Colorbar
    cax1 = fig.add_axes(Python.List([0.1, 0.22, 0.3, 0.015]))
    cb1 = fig.colorbar(im2, cax=cax1, orientation='horizontal', label='Temperature [$\mathrm{^{\circ}C}$]')
    void = cb1.set_ticks(np.arange(0,32,4))

    ; ---------------------------------------------------------
    ; (c) Model Bias
    ; ---------------------------------------------------------
    ax3 = fig.add_axes(Python.List([0.5, 0.25, 0.5, 0.25]), projection=ax_proj)
    void = ax3.set_title('(c) Model Bias ((b) - (a))', fontsize=14, fontweight='bold')
    
    im3 = ax3.pcolormesh(lons, lats, bias, transform=proj, $
                         cmap=cmap_bias, vmin=vmin_bias, vmax=vmax_bias, shading='flat')
    void = ax3.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax3.coastlines(linewidth=0.5)

    ; Colorbar for Bias
    cax2 = fig.add_axes(Python.List([0.6, 0.22, 0.3, 0.015]))
    cb2 = fig.colorbar(im3, cax=cax2, orientation='horizontal', label='Bias [$\mathrm{^{\circ}C}$]')
    void = cb2.set_ticks(np.arange(-4,5,1))

    ; Text
    void = ax1.text(0., 1., 'Mean=18.22', transform=ax1.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax2.text(0., 1., 'Mean=18.40', transform=ax2.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(0., 1., 'Mean=0.15', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='left', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(1., 1., 'RMSE=1.29', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))
    void = ax3.text(1., 0.95, 'r=0.99', transform=ax3.transAxes, $
                    fontsize=9, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='none', alpha=0))

    ; 4. Save
    void = fig.savefig('figure7.png', dpi=600, bbox_inches='tight')
    print, 'Figure 7 saved.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_sst_1985-2014.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
ncdf_varget, ncid, ncdf_varid(ncid, 'sst'), sst
ncdf_close, ncid

get_ersst, ersst, lon=lon0, lat=lat0

ersst_re = interpolate_2d(ersst, lon0, lat0, lon, lat)
bias = sst - ersst_re

print, gmean(sst,lat), gmean(ersst,lat0), gmean(bias,lat)
print, sqrt(gmean((sst-ersst_re)^2,lat)), correlate_nan(sst,ersst_re)

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

draw_sst_spatial_distribution, sst, ersst, bias, lons, lats, lons0, lats0

spawn, 'display -resize 20% figure7.png &'

end
