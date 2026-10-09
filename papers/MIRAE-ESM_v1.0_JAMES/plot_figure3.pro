pro plot_figure3, ohc, sal, amoc

  ; time
  n_years = 1000
  years   = findgen(n_years) + 1

  ; load matplotlib & numpy
  py = python.import('matplotlib.pyplot')
  np = python.import('numpy')

  ; figure size
  fig = py.figure(figsize=[5, 9])

  ; panel (a)
  ax0 = fig.add_subplot(3, 1, 1)

  void = ax0.plot(years, (ohc[*,0]-ohc[0,0])*1e-21, color='lightseagreen', linewidth=1.5, label='0m-700m')
  void = ax0.plot(years, (ohc[*,1]-ohc[0,1])*1e-21, color='dodgerblue', linewidth=1.5, label='700m-2000m')
  void = ax0.plot(years, (ohc[*,2]-ohc[0,2])*1e-21, color='navy', linewidth=1.5, label='>2000m')

  void = ax0.set_ylabel('OHC Anomaly [$\mathrm{ZJ}$]', fontsize=12)
  void = ax0.set_title('(a) Ocean Heat Content', loc='left', fontweight='bold', fontsize=14)
  void = ax0.legend(loc='lower right', frameon=0, fontsize=10)
  void = ax0.grid(1, alpha=0.2)

  ; panel (b)
  ax1 = fig.add_subplot(3, 1, 2, sharex=ax0)

  void = ax1.plot(years, sal, color='darkgray', linewidth=0.5)
  void = ax1.plot(years, ts_smooth(sal,30), color='black', linewidth=1.5)

  void = ax1.set_ylabel('Salinity [$\mathrm{psu}$]', fontsize=12)
  void = ax1.tick_params(axis='y', labelsize=8)
  void = ax1.set_title('(b) Global Mean Salinity', loc='left', fontweight='bold', fontsize=14)
  void = ax1.grid(1, alpha=0.2)

  main = python.import('__main__')
  ticker = python.import('matplotlib.ticker')

  py_cmd = "def sal_fmt(x, pos):" + $
           "\n    ref = 34.726" + $
           "\n    diff = x - ref" + $
           "\n    if abs(diff) < 0.00001:" + $
           "\n        return '{:.3f}'.format(x)" + $
           "\n    else:" + $
           "\n        return '{:+.4f}'.format(diff)"

  void = python.run(py_cmd)

  void = ax1.yaxis.set_major_formatter(ticker.FuncFormatter(main.sal_fmt))

  my_ticks = np.arange(34.7257, 34.7264, 0.0001)
  void = ax1.set_yticks(my_ticks)
  void = ax1.set_ylim(34.72565, 34.72635)

  ; panel (c)
  ax2 = fig.add_subplot(3, 1, 3, sharex=ax0)

  ; RAPID: mean and STD of annual means for 2005-2023
  rapid_mean = 16.9160
  rapid_std  = 1.26224

  void = ax2.plot(years, amoc, color='darkgray', linewidth=0.5, label='Annual Mean')
  void = ax2.plot(years, ts_smooth(amoc,30), color='black', linewidth=1.5, label='30-yr Running Mean')

  ; Observed interannual variability: mean +/- 1 STD
  void = ax2.axhspan(rapid_mean-rapid_std, rapid_mean+rapid_std, $
                    color='royalblue', alpha=0.15, linewidth=0, $
                    label='RAPID Mean $\pm$ 1 STD', zorder=2)

  ; Observed mean
  void = ax2.axhline(rapid_mean, color='royalblue', linestyle='--', $
                    linewidth=1.5, label='RAPID Mean (2005-2023)', zorder=3)

  void = ax2.set_xlim(1,1000)
  void = ax2.set_ylabel('AMOC [$\mathrm{Sv}$]', fontsize=12)
  void = ax2.set_xlabel('Spin-up Year', fontsize=12)
  void = ax2.set_title('(c) AMOC Strength (26.5$\mathbf{^{\circ}N}$)', loc='left', fontweight='bold', fontsize=14)
  void = ax2.legend(loc='lower right', frameon=0, fontsize=10)
  void = ax2.grid(1, alpha=0.2)
  void = ax2.set_ylim(0, 21)

  ; save figure
  void = py.tight_layout()
  void = py.savefig('figure3.png', dpi=600, bbox_inches='tight')

  print, 'Figure 3 generated successfully.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_spinup_ohc.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'ohc'), ohc
ncdf_close, ncid

ncid = ncdf_open('data/MIRAE-ESM_v1.0_spinup_sal.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'sal'), sal
ncdf_close, ncid

ncid = ncdf_open('data/MIRAE-ESM_v1.0_spinup_amoc.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'amoc'), amoc
ncdf_close, ncid

plot_figure3, ohc, sal, amoc

spawn, 'display -resize 20% figure3.png &'

end
