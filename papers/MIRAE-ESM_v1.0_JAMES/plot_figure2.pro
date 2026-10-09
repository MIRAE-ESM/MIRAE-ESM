pro plot_figure2, rtnt, tas

  ; time
  n_years = 1000
  years   = findgen(n_years) + 1

  ; load matplotlib
  py = python.import('matplotlib.pyplot')

  ; figure size
  fig = py.figure(figsize=[10, 3.6])

  ; panel (a)
  ax0 = fig.add_subplot(1, 2, 1)

  void = ax0.plot(years, rtnt, color='darkgray', linewidth=0.5, label='Annual Mean')

  rtnt_smooth = ts_smooth(rtnt, 30)
  void = ax0.plot(years, rtnt_smooth, color='black', linewidth=1.5, label='30-yr Running Mean')

  void = ax0.set_xlim(1,1000)
  void = ax0.set_ylim(-1.7, 1.7)
  void = ax0.axhline(0.0, color='red', linestyle='--', linewidth=1.5)
  void = ax0.set_xlabel('Spin-up Year', fontsize=12)
  void = ax0.set_ylabel('Net TOA Flux [$\mathrm{W\ m^{-2}}$]', fontsize=12)
  void = ax0.set_title('(a) Net TOA Radiative Flux', loc='left', fontweight='bold', fontsize=14)
  void = ax0.grid(1, alpha=0.2)

  ; panel (b)
  ax1 = fig.add_subplot(1, 2, 2)

  tas = tas - 273.15
  void = ax1.plot(years, tas, color='darkgray', linewidth=0.5, label='Annual Mean')

  tas_smooth = ts_smooth(tas, 30)
  void = ax1.plot(years, tas_smooth, color='black', linewidth=1.5, label='30-yr Running Mean')

  void = ax1.set_xlim(1,1000)
  void = ax1.set_ylim(12.3,14.2)
  void = ax1.set_yticks([12.5,13.0,13.5,14.0])
  void = ax1.set_xlabel('Spin-up Year', fontsize=12)
  void = ax1.set_ylabel('Air Temperature [$\mathrm{^{\circ}C}$]', fontsize=12)
  void = ax1.set_title('(b) Global Mean Surface Temp.', loc='left', fontweight='bold', fontsize=14)
  void = ax1.legend(loc='lower right', frameon=0, fontsize=12)
  void = ax1.grid(1, alpha=0.2)

  ; save figure
  void = py.tight_layout()
  void = py.savefig('figure2.png', dpi=600, bbox_inches='tight')

  print, 'Figure 2 generated successfully.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_spinup_rtnt.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'rtnt'), rtnt
ncdf_close, ncid

ncid = ncdf_open('data/MIRAE-ESM_v1.0_spinup_tas.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'tas'), tas
ncdf_close, ncid

plot_figure2, rtnt, tas

spawn, 'display -resize 20% figure2.png &'

end
