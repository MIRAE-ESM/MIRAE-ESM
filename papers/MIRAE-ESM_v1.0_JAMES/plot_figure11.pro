pro get_sic_data, sic, lon=lon, lat=lat

   file = 'data/sic_clim.nc'

   ncid = ncdf_open(file)

   ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
   ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat

   ncdf_varget, ncid, ncdf_varid(ncid, 'sic'), sic

   ncdf_close, ncid

   sic[where(sic eq -9999.)] = !values.f_nan
   sic[where(sic eq -999.)] = 0.

   id = where(lon lt 0.)
   lon[id] = lon[id]+360.
   lon = shift(lon,720)
   sic = shift(sic,720,0,0)

end

pro set_minmax, data, vmin, vmax

    data[where(data lt vmin, /null)] = vmin
    data[where(data ge vmax, /null)] = vmax - 0.001
    data[where(finite(data) eq 0, /null)] = 1e20

end

pro draw_sic_spatial_distribution, sic, sic0, bias, sic_nh, sic_sh, sic0_nh, sic0_sh, lon, lat, lon0, lat0

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
    mpath = Python.Import('matplotlib.path')
    
    ; 2. Setup Colormap (Gray for Land/NaN)
    bounds = np.arange(0,1.1,0.1)
    cmap = py.get_cmap('PuBu')
    norm = colors_mod.BoundaryNorm(bounds, cmap.N)
    void = cmap.set_over(color='lightgray')
    bounds_bias = [-0.6,-0.5,-0.4,-0.3,-0.2,-0.1,-0.05,0.05,0.1,0.2,0.3,0.4,0.5,0.6]
    cmap_bias = py.get_cmap('RdBu_r')
    norm_bias = colors_mod.BoundaryNorm(bounds_bias, cmap_bias.N)
    void = cmap_bias.set_over(color='lightgray')
    
    python.theta = np.linspace(0, 2*np.pi, 100)
    python.center = python.list([0.5, 0.5])
    python.radius = 0.5
    python.run, 'import numpy as np'
    python.run, 'import matplotlib.path as mpath'
    Python.run, 'verts=np.vstack([np.sin(theta), np.cos(theta)]).T'
    python.run, 'circle = mpath.Path(verts * radius + center)'

    ; 3. Create Figure
    fig = py.figure(figsize=[10, 10])
    cls = builtins.getattr(ccrs, 'NorthPolarStereo')
    ax_proj_nh = cls.__call__(central_longitude=0)
    cls = builtins.getattr(ccrs, 'SouthPolarStereo')
    ax_proj_sh = cls.__call__(central_longitude=0)
    cls = builtins.getattr(ccrs, 'PlateCarree')
    proj = cls.__call__()

    ; Set min-max value and masking
    vmin = bounds[0]
    vmax = bounds[-1]
    set_minmax, sic, vmin, vmax
    set_minmax, sic0, vmin, vmax

    vmin_bias = bounds_bias[0]
    vmax_bias = bounds_bias[-1]
    set_minmax, bias, vmin_bias, vmax_bias

    ; ---------------------------------------------------------
    ; NOAA/NSIDC CDR Sea Ice - NH
    ; ---------------------------------------------------------
    ax1 = fig.add_axes(Python.List([0., 0.7, 0.3, 0.3]), projection=ax_proj_nh)
    void = ax1.set_extent(Python.List([-180, 180, 45, 90]), proj)
    void = ax1.set_boundary(python.circle, transform=ax1.transAxes)
    void = ax1.set_title('(a) NOAA/NSIDC CDR (NH)', fontsize=14, fontweight='bold')
   
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im1 = ax1.pcolormesh(lon0, lat0, sic0, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    void = ax1.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax1.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM Sea Ice - NH
    ; ---------------------------------------------------------
    ax2 = fig.add_axes(Python.List([0.32, 0.7, 0.3, 0.3]), projection=ax_proj_nh)
    void = ax2.set_extent(Python.List([-180, 180, 45, 90]), proj)
    void = ax2.set_boundary(python.circle, transform=ax2.transAxes)
    void = ax2.set_title('(b) MIRAE-ESM (NH)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im2 = ax2.pcolormesh(lon, lat, sic, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    void = ax2.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax2.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias - NH
    ; ---------------------------------------------------------
    ax3 = fig.add_axes(Python.List([0.64, 0.7, 0.3, 0.3]), projection=ax_proj_nh)
    void = ax3.set_extent(Python.List([-180, 180, 45, 90]), proj)
    void = ax3.set_boundary(python.circle, transform=ax3.transAxes)
    void = ax3.set_title('(c) Bias (NH)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im3 = ax3.pcolormesh(lon, lat, bias, transform=proj, $
                         cmap=cmap_bias, norm=norm_bias, shading='flat')
    void = ax3.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax3.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; NOAA/NSIDC CDR Sea Ice - SH
    ; ---------------------------------------------------------
    ax4 = fig.add_axes(Python.List([0., 0.35, 0.3, 0.3]), projection=ax_proj_sh)
    void = ax4.set_extent(Python.List([-180, 180, -90, -45]), proj)
    void = ax4.set_boundary(python.circle, transform=ax4.transAxes)
    void = ax4.set_title('(d) NOAA/NSIDC CDR (SH)', fontsize=14, fontweight='bold')
   
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im4 = ax4.pcolormesh(lon0, lat0, sic0, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    void = ax4.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax4.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; MIRAE-ESM Sea Ice - SH
    ; ---------------------------------------------------------
    ax5 = fig.add_axes(Python.List([0.32, 0.35, 0.3, 0.3]), projection=ax_proj_sh)
    void = ax5.set_extent(Python.List([-180, 180, -90, -45]), proj)
    void = ax5.set_boundary(python.circle, transform=ax5.transAxes)
    void = ax5.set_title('(e) MIRAE-ESM (SH)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im5 = ax5.pcolormesh(lon, lat, sic, transform=proj, $
                         cmap=cmap, norm=norm, shading='flat')
    void = ax5.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax5.coastlines(linewidth=0.5)

    ; ---------------------------------------------------------
    ; Bias - SH
    ; ---------------------------------------------------------
    ax6 = fig.add_axes(Python.List([0.64, 0.35, 0.3, 0.3]), projection=ax_proj_sh)
    void = ax6.set_extent(Python.List([-180, 180, -90, -45]), proj)
    void = ax6.set_boundary(python.circle, transform=ax6.transAxes)
    void = ax6.set_title('(f) Bias (SH)', fontsize=14, fontweight='bold')
    
    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im6 = ax6.pcolormesh(lon, lat, bias, transform=proj, $
                         cmap=cmap_bias, norm=norm_bias, shading='flat')
    void = ax6.add_feature(builtins.getattr(cfeature, 'LAND'), facecolor='lightgray', zorder=1)
    void = ax6.coastlines(linewidth=0.5)

    ; Colorbar
    cax1 = fig.add_axes(Python.List([0.11, 0.32, 0.4, 0.015]))
    cb1 = fig.colorbar(im1, cax=cax1, orientation='horizontal', label='Sea Ice Concentration')
    void = cb1.set_ticks(np.arange(0,1.2,0.2))

    ; Colorbar
    cax2 = fig.add_axes(Python.List([0.665, 0.32, 0.25, 0.015]))
    cb2 = fig.colorbar(im3, cax=cax2, orientation='horizontal', label='Bias')
    void = cb2.set_ticks([-0.6,-0.4,-0.2,0,0.2,0.4,0.6])

    ax7 = fig.add_axes(Python.List([0.05, 0., 0.37, 0.24]))

    mon = findgen(12)+1
    sic0_nh = sic0_nh * 1e-12
    sic_nh = sic_nh * 1e-12
    sic0_sh = sic0_sh * 1e-12
    sic_sh = sic_sh * 1e-12

    void = ax7.plot(mon, sic0_nh, color='black', linewidth=1, label='NOAA/NSIDC CDR')
    void = ax7.plot(mon, sic_nh, color='red', linewidth=1, label='MIRAE-ESM')
    void = ax7.set_xlim(0.5,12.5)
    void = ax7.set_ylim(0,19)
    void = ax7.set_xticks(python.list([1,2,3,4,5,6,7,8,9,10,11,12]))
    void = ax7.set_ylabel('Sea Ice Area [$10^{12}\ \mathrm{m}^2$]')
    void = ax7.set_xlabel('Month')
    void = ax7.set_title('(g) NH Sea Ice Area', fontweight='bold')
    void = ax7.grid(1, alpha=0.2)

    ax8 = fig.add_axes(Python.List([0.52, 0., 0.37, 0.24]))

    void = ax8.plot(mon, sic0_sh, color='black', linewidth=1, label='NOAA/NSIDC CDR')
    void = ax8.plot(mon, sic_sh, color='red', linewidth=1, label='MIRAE-ESM')
    void = ax8.set_xlim(0.5,12.5)
    void = ax8.set_ylim(0,19)
    void = ax8.set_xticks(python.list([1,2,3,4,5,6,7,8,9,10,11,12]))
    void = ax8.set_ylabel('Sea Ice Area [$10^{12}\ \mathrm{m}^2$]')
    void = ax8.set_xlabel('Month')
    void = ax8.set_title('(h) SH Sea Ice Area', fontweight='bold')
    void = ax8.legend(loc='upper left', frameon=0, fontsize=10)
    void = ax8.grid(1, alpha=0.2)

    ; Text
    void = ax1.text(.5, .1, '$Area = 9.40 \times 10^{12}\ \mathrm{m}^2$', transform=ax1.transAxes, $
                    fontsize=12, color='black', ha='center', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))
    void = ax2.text(.5, .1, '$Area = 9.41 \times 10^{12}\ \mathrm{m}^2$', transform=ax2.transAxes, $
                    fontsize=12, color='black', ha='center', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))
    void = ax3.text(.5, .1, '$Bias = +0.14\%$', transform=ax3.transAxes, $
                    fontsize=12, color='black', ha='center', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))
    void = ax4.text(.5, .1, '$Area = 9.60 \times 10^{12}\ \mathrm{m}^2$', transform=ax4.transAxes, $
                    fontsize=12, color='black', ha='center', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))
    void = ax5.text(.5, .1, '$Area = 4.42 \times 10^{12}\ \mathrm{m}^2$', transform=ax5.transAxes, $
                    fontsize=12, color='black', ha='center', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))
    void = ax6.text(.5, .1, '$Bias = -53.9\%$', transform=ax6.transAxes, $
                    fontsize=12, color='black', ha='center', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))

    ; 4. Save
    void = fig.savefig('figure11.png', dpi=600, bbox_inches='tight')
    print, 'Figure 11 saved.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_sic_1985-2014.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
ncdf_varget, ncid, ncdf_varid(ncid, 'sic'), sic
ncdf_close, ncid

get_sic_data, sic0, lon=lon0, lat=lat0

; regrid
sic_re = sic0
for m=0, 11 do begin
   sic_re[*,*,m] = interpolate_2d(sic[*,*,m], lon, lat, lon0, lat0)
endfor

; mask
nanid = where(finite(sic0) eq 0, /null)
sic_re[nanid] = !values.f_nan

; mask
nanid = where(finite(sic_re) eq 0, /null)
sic0[nanid] = !values.f_nan

area1 = ctm_boxsize(ctm_grid(ctm_type('GRIMS_28L')),/m2)
area2 = ctm_boxsize(ctm_grid(ctm_type('GENERIC',res=[0.25,0.25],halfpolar=0)),/m2)

sic_nh = fltarr(12)
sic_sh = fltarr(12)
sic0_nh = fltarr(12)
sic0_sh = fltarr(12)
for m=0, 11 do begin
   sic_nh[m] = total(sic_re[*,360:719,m]*area2[*,360:719],/nan)
   sic_sh[m] = total(sic_re[*,0:359,m]*area2[*,0:359],/nan)
   sic0_nh[m] = total(sic0[*,360:719,m]*area2[*,360:719],/nan)
   sic0_sh[m] = total(sic0[*,0:359,m]*area2[*,0:359],/nan)
endfor

sic = mean(sic,3,/nan)
sic0 = mean(sic0,3,/nan)
sic_re = mean(sic_re,3,/nan)
bias = sic_re - sic0

print, mean(sic_nh), mean(sic_sh)
print, mean(sic0_nh), mean(sic0_sh)
print, mean(sic_nh)/mean(sic0_nh), mean(sic_sh)/mean(sic0_sh)

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

draw_sic_spatial_distribution, sic_re, sic0, bias, sic_nh, sic_sh, sic0_nh, sic0_sh, lons0, lats0, lons0, lats0

spawn, 'display -resize 20% figure11.png &'

end
