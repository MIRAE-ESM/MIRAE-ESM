pro draw_o3_spatial_distribution, oz, oz0, oz00, lon, lat, lon0, lat0

    time = findgen(366)+0.5
    z1 = transpose(oz0)
    z1[where(z1 lt 210)] = 210
    z1[where(finite(z1) eq 0)] = -9999
    z2 = transpose(oz)
    z2[where(z2 lt 210)] = 210
    z2[where(finite(z2) eq 0)] = -9999
    z3 = transpose((oz-oz00)/oz00*100.)
    z3[where(z3 lt -30)] = -30
    z3[where(finite(z3) eq 0)] = -9999

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
    cmap = py.get_cmap('jet', 18)
    void = cmap.set_under('lightgray')
    cmap_bias = py.get_cmap('RdBu_r', 18)
    void = cmap_bias.set_under('lightgray')

    ; 3. Create Figure
    fig = py.figure(figsize=[10, 4])

    ; ---------------------------------------------------------
    ; OMI
    ; ---------------------------------------------------------
    ax1 = fig.add_axes(Python.List([0.05, 0.2, 0.28, 0.7]))
    void = ax1.set_title('OMI', fontsize=14, fontweight='bold')

    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im1 = ax1.pcolormesh(time, lat0, z1, $
                         cmap=cmap, vmin=210, vmax=480)
    ;void = ax1.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    ;void = ax1.coastlines(linewidth=0.5)
    void = ax1.set_ylabel('Latitude')
    void = ax1.set_xlabel('Month')
    void = ax1.set_ylim(-90,90)
    void = ax1.set_xlim(0.5,365.5)
    void = ax1.set_xticks(python.list([15.5,45,74.5,105,135,166,196.5,227.5,258,288.5,319,349]))
    void = ax1.set_xticklabels(['J','F','M','A','M','J','J','A','S','O','N','D'])
    void = ax1.set_yticks(python.list([-90,-60,-30,0,30,60,90]))
    void = ax1.set_yticklabels(['$\mathrm{90^{\circ}S}$','$\mathrm{60^{\circ}S}$','$\mathrm{30^{\circ}S}$', $
                           'EQ','$\mathrm{30^{\circ}N}$','$\mathrm{60^{\circ}N}$','$\mathrm{90^{\circ}N}$'])

    ; ---------------------------------------------------------
    ; MIRAE-ESM
    ; ---------------------------------------------------------
    ax2 = fig.add_axes(Python.List([0.35, 0.2, 0.28, 0.7]))
    void = ax2.set_title('MIRAE-ESM', fontsize=14, fontweight='bold')

    ; Using pcolormesh with 2D lon/lat arrays
    ; shading='nearest' or 'auto' prevents the grid line artifacts
    im2 = ax2.pcolormesh(time, lat, z2, $
                         cmap=cmap, vmin=210, vmax=480)
    ;void = ax2.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    ;void = ax2.coastlines(linewidth=0.5)
    ;void = ax2.set_ylabel('Latitude')
    void = ax2.set_xlabel('Month')
    void = ax2.set_ylim(-90,90)
    void = ax2.set_xlim(0.5,365.5)
    void = ax2.set_xticks(python.list([15.5,45,74.5,105,135,166,196.5,227.5,258,288.5,319,349]))
    void = ax2.set_xticklabels(['J','F','M','A','M','J','J','A','S','O','N','D'])
    void = ax2.set_yticks(python.list())
    ;void = ax2.set_yticklabels(['90$^\circ$S','60$^\circ$S','30$^\circ$S','EQ','30$^\circ$N','60$^\circ$N','90$^\circ$N'])

    ; ---------------------------------------------------------
    ; Bias
    ; ---------------------------------------------------------
    ax3 = fig.add_axes(Python.List([0.65, 0.2, 0.28, 0.7]))
    void = ax3.set_title('Bias', fontsize=14, fontweight='bold')

    im3 = ax3.pcolormesh(time, lat, z3, $
                         cmap=cmap_bias, vmin=-30, vmax=30, shading='flat')
    ;void = ax3.add_feature(builtins.getattr(cfeature, 'OCEAN'), facecolor='lightgray')
    ;void = ax3.coastlines(linewidth=0.5)
    ;void = ax3.set_ylabel('Latitude')
    void = ax3.set_xlabel('Month')
    void = ax3.set_ylim(-90,90)
    void = ax3.set_xlim(0.5,365.5)
    void = ax3.set_xticks(python.list([15.5,45,74.5,105,135,166,196.5,227.5,258,288.5,319,349]))
    void = ax3.set_xticklabels(['J','F','M','A','M','J','J','A','S','O','N','D'])
    void = ax3.set_yticks(python.list())
    ;void = ax3.set_yticklabels(['90$^\circ$S','60$^\circ$S','30$^\circ$S','EQ','30$^\circ$N','60$^\circ$N','90$^\circ$N'])

    ; Colorbar
    cax1 = fig.add_axes(Python.List([0.165, 0.05, 0.35, 0.015]))
    cb1 = fig.colorbar(im1, cax=cax1, orientation='horizontal', label='Total Column Ozone [Dobson Unit]')
    void = cb1.set_ticks(python.list([210,240,270,300,330,360,390,420,450,480]))
    ;void = cb1.set_ticklabels(bounds)

    ; Colorbar for Bias
    cax2 = fig.add_axes(Python.List([0.65, 0.05, 0.28, 0.015]))
    cb2 = fig.colorbar(im3, cax=cax2, orientation='horizontal', label='Bias [%]')
    void = cb2.set_ticks(python.list([-30,-20,-10,0,10,20,30]))

    ; Text
    void = ax1.text(.99, .99, '285.4 DU', transform=ax1.transAxes, $
                    fontsize=10, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))
    void = ax2.text(.99, .99, '321.5 DU', transform=ax2.transAxes, $
                    fontsize=10, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))
    void = ax3.text(.99, .99, '+12.6%', transform=ax3.transAxes, $
                    fontsize=10, color='black', ha='right', va='top', $
                    bbox=Python.Dict(facecolor='white', edgecolor='black', alpha=1))

    ; 4. Save
    void = fig.savefig('figure13.png', dpi=600, bbox_inches='tight')
    print, 'Figure 13 saved.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_tco_2005-2014.nc4')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat
ncdf_varget, ncid, ncdf_varid(ncid, 'tco'), oz
ncdf_close, ncid

ncid = ncdf_open('data/OMI_tco_2005-2014.nc4')
ncdf_varget, ncid, ncdf_varid(ncid, 'lon'), lon0
ncdf_varget, ncid, ncdf_varid(ncid, 'lat'), lat0
ncdf_varget, ncid, ncdf_varid(ncid, 'tco'), oz0
ncdf_close, ncid

oz00=oz
for d=0,364 do begin
  oz00[*,*,d] = interpolate_2d(oz0[*,*,d], lon0, lat0, lon, lat)
endfor

nanid = where(finite(oz00) eq 0)
oz[nanid] = !values.f_nan

m1 = gmean(mean(oz,3,/nan),lat)
m2 = gmean(mean(oz0,3,/nan),lat0)
print, m1, m2, (m1-m2)/m2*100.

oz = mean(oz,1,/nan)
oz0 = mean(oz0,1,/nan)
oz00 = mean(oz00,1,/nan)

get_t62_grid, yedge=yedge
lons = lon-360./192.*0.5
lons = [lons,lon[-1]+360./192.*0.5]
lats = reverse(yedge)

lons0 = findgen(361)-180.
lats0 = findgen(181)-90.

draw_o3_spatial_distribution, oz, oz0, oz00, lons, lats, lons0, lats0

spawn, 'display -resize 20% figure13.png &'

end
