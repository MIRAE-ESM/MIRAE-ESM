pro plot_figure5, tas, obsx1, obsy1, obsx2, obsy2

  ; --- 1. Data Preparation (IDL Side) ---
  n_years = 165
  years   = findgen(n_years) + 1850

  ; --- 2. Initialize Python Bridge ---
  py = python.import('matplotlib.pyplot')

  ; --- 3. Create Figure & Axes Individually ---
  fig = py.figure(figsize=[5, 3.5])

  ax0 = fig.add_subplot(1, 1, 1)

  ; --- 4. Plotting Panel : TAS ---
  void = ax0.plot(years, tas, color='red', linewidth=1.5, label='MIRAE-ESM v1.0', alpha=0.8)
  void = ax0.plot(obsx1, obsy1, color='gray', ls='--', linewidth=1.5, label='GISTEMPv4', alpha=0.8)
  void = ax0.plot(obsx2, obsy2, color='black', linewidth=1.5, label='HadCRUT5', alpha=0.8)

  void = ax0.set_ylim(-1.2, 1.7)
  void = ax0.set_xlim(1850, 2014)
  void = ax0.set_ylabel('Air Temperature [$\mathrm{^{\circ}C}$]', fontsize=12)
  void = ax0.set_xlabel('Year', fontsize=12)
  void = ax0.set_title('Global Mean Surface Temperature', loc='center', fontweight='bold', fontsize=14)
  void = ax0.legend(loc='best', frameon=0, fontsize=10)
  void = ax0.grid(1, alpha=0.2)

  ; --- 5. Layout & Export ---
  void = py.tight_layout()
  void = py.savefig('figure5.png', dpi=600, bbox_inches='tight')

  print, 'Figure 5 generated successfully.'

end

ncid = ncdf_open('data/MIRAE-ESM_v1.0_historical_tas.nc')
ncdf_varget, ncid, ncdf_varid(ncid, 'tas'), tas
ncdf_close, ncid

readcol, 'data/GLB.Ts+dSST.csv', obsx1, obsy1, $
         /nan, delimiter=',', format='L,X,X,X,X,X,X,X,X,X,X,X,X,F', skipline=2
readcol, 'data/HadCRUT.5.1.0.0.analysis.summary_series.global.annual.csv', obsx2, obsy2, $
         /nan, delimiter=',', format='L,F', skipline=1

tas = tas - mean(tas[1961-1850:1990-1850])
obsy1 = obsy1 - mean(obsy1[1961-1880:1990-1880])

plot_figure5, tas, obsx1, obsy1, obsx2, obsy2

spawn, 'display -resize 20% figure5.png &'

end
