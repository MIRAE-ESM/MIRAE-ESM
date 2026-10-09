#!/usr/bin/env python3
"""Figure 4: final-100-year spin-up AMOC and modern RAPID reference.

Dependencies: numpy, matplotlib, netCDF4. Python 3.9 compatible.
Run with defaults: python plot_figure4.py
Model glob: ../cycle10/????/ORCA2_1m_*_diaptr.nc (directory labels 1901-2000).
RAPID: /home/sul/DATA/RAPID/moc_vertical.nc (2005-2023).
Model directory labels identify spin-up years, not a historical comparison.
Each model year must contain all 12 months exactly once with matching time bounds.
Model annual means use interval-duration weights by default; annual profiles
have equal weights across years. Both STD bands use ddof=1, not standard errors.
The original plot styling, axis limits and 600-dpi PNG output are retained.
"""
import argparse
import calendar
import glob
from pathlib import Path
import warnings

import numpy as np
from netCDF4 import Dataset, num2date
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter


def read_array(variable):
    """netCDF4 automatically masks _FillValue and missing_value."""
    return np.ma.asarray(variable[:], dtype=float).filled(np.nan)


def check_units(variable, expected):
    actual = getattr(variable, 'units', '').strip()
    if actual.lower() != expected.lower():
        raise ValueError(f'{variable.name}: expected {expected}, found {actual!r}')


def positive_depth(z):
    if not np.all(np.isfinite(z)):
        raise ValueError('Depth coordinates contain missing values.')
    if np.any(z < 0) and np.any(z > 0):
        raise ValueError('Mixed depth signs: inspect the depth convention.')
    return np.abs(z)


def weighted_time_mean(a, w):
    w = w.reshape((-1,) + (1,) * (a.ndim - 1))
    valid = np.isfinite(a)
    numerator = np.sum(np.where(valid, a, 0.0) * w, axis=0)
    denominator = np.sum(valid * w, axis=0)
    return np.divide(numerator, denominator,
                     out=np.full_like(numerator, np.nan), where=denominator > 0)


def sort_unique_axis(coord, data, axis, name):
    """Remove duplicate coordinate rows only when their data are identical."""
    order = np.argsort(coord, kind='stable')
    coord, data = coord[order], np.take(data, order, axis=axis)
    keep = []
    for i, value in enumerate(coord):
        if keep and value == coord[keep[-1]]:
            previous = np.take(data, keep[-1], axis=axis)
            current = np.take(data, i, axis=axis)
            if not np.array_equal(previous, current, equal_nan=True):
                raise ValueError(
                    f'{name}={value:g} is duplicated with DIFFERENT data. '
                    'Do not average these rows automatically. Inspect nav_lat/'
                    'depthw and the diagnostic grid; provide the coordinate values '
                    'and row indices to resolve the ambiguity.')
            print(f'Removing identical duplicate {name}={value:g}')
        else:
            keep.append(i)
    return coord[keep], np.take(data, keep, axis=axis)


def annual_statistics(a):
    """Require all requested years at each grid point; use sample SD."""
    good = np.all(np.isfinite(a), axis=0)
    mean = np.full(a.shape[1:], np.nan)
    std = np.full(a.shape[1:], np.nan)
    mean[good] = a[:, good].mean(axis=0)
    std[good] = a[:, good].std(axis=0, ddof=1)
    return mean, std


def model_section(paths, expected_year, weighting, target_lat, lat_min, lat_max):
    arrays, weights, months = [], [], []
    lat = depth = None
    for path in paths:
        with Dataset(path) as ds:
            var = ds.variables['zomsfatl']
            check_units(var, 'Sv')
            check_units(ds.variables['depthw'], 'm')
            if var.dimensions != ('time_counter', 'depthw', 'y', 'x'):
                raise ValueError(f'Unexpected zomsfatl dimensions: {var.dimensions}')
            if len(ds.dimensions['x']) != 1:
                raise ValueError('Expected x=1.')
            data = read_array(var)[..., 0]
            newlat = read_array(ds.variables['nav_lat'])[:, 0]
            newdepth = positive_depth(read_array(ds.variables['depthw']))
            if lat is not None and (
                not np.array_equal(lat, newlat, equal_nan=True) or
                not np.array_equal(depth, newdepth, equal_nan=True)
            ):
                raise ValueError(f'Grid changed within year {expected_year}: {path}')
            lat, depth = newlat, newdepth
            tv = ds.variables['time_counter']
            bounds = read_array(ds.variables[getattr(tv, 'bounds', 'time_counter_bounds')])
            cal = getattr(tv, 'calendar', 'standard')
            units = tv.units
            begin = num2date(bounds[:, 0], units, calendar=cal)
            finish = num2date(bounds[:, 1], units, calendar=cal)
            if len(begin) != data.shape[0]:
                raise ValueError(f'Time/data dimension mismatch: {path}')
            for a, b in zip(begin, finish):
                next_y = a.year + (a.month == 12)
                next_m = a.month % 12 + 1
                if (a.year != expected_year or a.day != 1 or
                    (a.hour, a.minute, a.second) != (0, 0, 0) or
                    (b.year, b.month, b.day, b.hour, b.minute, b.second) !=
                    (next_y, next_m, 1, 0, 0, 0)):
                    raise ValueError(
                        f'{path}: bounds {a} to {b} do not describe one complete '
                        f'month in directory year {expected_year}. Check the '
                        'calendar years and whether these are historical or spin-up files.')
                months.append(a.month)
                weights.append((b - a).total_seconds())
            arrays.append(data)
    if sorted(months) != list(range(1, 13)):
        raise ValueError(f'{expected_year}: expected months 1-12 exactly once; got {months}')
    a = np.concatenate(arrays, axis=0)
    w = np.asarray(weights) if weighting == 'bounds' else np.ones(len(weights))
    section = weighted_time_mean(a, w)
    section[~np.all(np.isfinite(a), axis=0)] = np.nan
    print(f'Model {expected_year}: {len(paths)} file(s), 12 complete months, '
          f'{weighting}-weighted annual mean')

    for name, values in [('Latitude', lat), ('Depth', depth)]:
        unique, counts = np.unique(values[np.isfinite(values)], return_counts=True)
        for value in unique[counts > 1]:
            print(f'{name} duplicate: {value:g}; original zero-based indices '
                  f'{np.flatnonzero(values == value).tolist()}')
    # Limit to the requested latitude domain, retaining bracketing rows at
    # its edges and at the profile latitude. Northern folded/halo rows outside
    # this domain need not participate in the plot or interpolation.
    finite_lat = lat[np.isfinite(lat)]
    if not finite_lat.size:
        raise ValueError('No valid latitude coordinates.')
    lower, upper = min(lat_min, target_lat), max(lat_max, target_lat)
    below, above = finite_lat[finite_lat <= lower], finite_lat[finite_lat >= upper]
    lower = below.max() if below.size else finite_lat.min()
    upper = above.min() if above.size else finite_lat.max()
    keep = np.isfinite(lat) & (lat >= lower) & (lat <= upper)
    print(f'Using latitude rows within {lower:g} to {upper:g} degrees; '
          f'excluding {(~keep).sum()} rows.')
    lat, section = lat[keep], section[:, keep]
    lat, section = sort_unique_axis(lat, section, 1, 'latitude')
    depth, section = sort_unique_axis(depth, section, 0, 'depth')
    if not lat[0] <= target_lat <= lat[-1]:
        raise ValueError('Target latitude is outside the model grid.')
    # Linear interpolation between the adjacent latitude rows, at each depth.
    # NaNs are retained rather than interpolated across missing ocean cells.
    profile = np.array([np.interp(target_lat, lat, row) for row in section])
    if not np.any(np.isfinite(profile)):
        raise ValueError('No valid model profile at the target latitude.')
    return lat, depth, section, profile


def rapid_profile(path, start_year, end_year, min_coverage):
    with Dataset(path) as ds:
        v = ds.variables['stream_function_mar']
        check_units(v, 'Sv')
        check_units(ds.variables['depth'], 'm')
        if v.dimensions != ('depth', 'time'):
            raise ValueError(f'Unexpected RAPID dimensions: {v.dimensions}')
        a = read_array(v)
        depth = positive_depth(read_array(ds.variables['depth']))
        tv = ds.variables['time']
        times = num2date(tv[:], tv.units, calendar=getattr(tv, 'calendar', 'standard'))
        # This product is regularly sampled twice daily. Fail on changed cadence
        # rather than silently computing an inappropriate sample mean.
        delta = np.array([(b - a).total_seconds() for a, b in zip(times[:-1], times[1:])])
        if not np.allclose(delta, 43200.0):
            raise ValueError('RAPID time axis is not regular 12-hour sampling.')
        years = np.array([t.year for t in times])
        print('RAPID version:', getattr(ds, 'version', '(absent)'))
        print('RAPID full record:', times[0], 'to', times[-1])

    annual = []
    for year in range(start_year, end_year + 1):
        values = a[:, years == year]
        expected = (366 if calendar.isleap(year) else 365) * 2
        if values.shape[1] != expected:
            raise ValueError(f'{year}: not a complete calendar year on the time axis.')
        count = np.isfinite(values).sum(axis=1)
        mean = np.divide(np.nansum(values, axis=1), count,
                         out=np.full(depth.shape, np.nan), where=count > 0)
        mean[count / expected < min_coverage] = np.nan
        annual.append(mean)
    annual = np.stack(annual)
    # Equal weight for each annual profile, consistent with the Figure 3c
    # annual-mean comparison. Require all requested years at each depth.
    good = np.all(np.isfinite(annual), axis=0)
    mean, std = np.full(depth.shape, np.nan), np.full(depth.shape, np.nan)
    mean[good] = annual[:, good].mean(axis=0)
    std[good] = annual[:, good].std(axis=0, ddof=1)
    if not good.any():
        raise ValueError('No RAPID depths meet coverage requirements in every year.')
    if not good.all():
        warnings.warn(f'{(~good).sum()} RAPID depths excluded by annual coverage checks.')
    iz = np.argsort(depth)
    if np.any(np.diff(depth[iz]) <= 0):
        raise ValueError('Duplicate RAPID depths.')
    return depth[iz], mean[iz], std[iz]


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--model', '--model-glob', dest='model',
                   default='../cycle10/????/ORCA2_1m_*_diaptr.nc',
                   help='Quoted glob pattern; parent directory is the model year label.')
    p.add_argument('--model-start-year', type=int, default=1901)
    p.add_argument('--model-end-year', type=int, default=2000)
    p.add_argument('--rapid', default='/home/sul/DATA/RAPID/moc_vertical.nc')
    p.add_argument('--model-weighting', choices=['bounds', 'equal'], default='bounds')
    p.add_argument('--model-label', default='MIRAE-ESM')
    p.add_argument('--start-year', type=int, default=2005)
    p.add_argument('--end-year', type=int, default=2023)
    p.add_argument('--min-coverage', type=float, default=0.90,
                   help='Minimum valid fraction in EACH RAPID year at each depth.')
    p.add_argument('--rapid-std', action='store_true', default=True, help='Show RAPID interannual SD (default).')
    p.add_argument('--no-rapid-std', dest='rapid_std', action='store_false')
    p.add_argument('--model-std', action='store_true', default=True, help='Show model interannual SD (default).')
    p.add_argument('--no-model-std', dest='model_std', action='store_false')
    p.add_argument('--latitude', type=float, default=26.5)
    p.add_argument('--lat-min', type=float, default=-30)
    p.add_argument('--lat-max', type=float, default=70)
    p.add_argument('--max-depth', type=float, default=5000)
    p.add_argument('--color-limit', type=float, default=20)
    p.add_argument('--output', default='figure4')
    args = p.parse_args()
    if (args.end_year <= args.start_year or args.model_end_year <= args.model_start_year
        or not 0 < args.min_coverage <= 1):
        p.error('Require at least two years and 0 < min-coverage <= 1.')
    if args.color_limit <= 0 or args.max_depth <= 0 or args.lat_max <= args.lat_min:
        p.error('Invalid plotting limits.')

    matched = sorted(set(glob.glob(args.model)))
    if not matched:
        raise FileNotFoundError(f'No files match {args.model!r}')
    by_year = {}
    for path in matched:
        name = Path(path).parent.name
        if not (len(name) == 4 and name.isdigit()):
            raise ValueError(f'Expected a four-digit calendar-year directory: {path}')
        by_year.setdefault(int(name), []).append(path)
    sections, profiles = [], []
    lat = zm = None
    for year in range(args.model_start_year, args.model_end_year + 1):
        if year not in by_year:
            raise FileNotFoundError(f'No model files for {year}; pattern={args.model}')
        la, zz, sec, prof = model_section(
            by_year[year], year, args.model_weighting, args.latitude, args.lat_min, args.lat_max)
        if lat is not None and (not np.array_equal(lat, la) or not np.array_equal(zm, zz)):
            raise ValueError(f'Model latitude/depth grid changed in {year}.')
        lat, zm = la, zz
        sections.append(sec)
        profiles.append(prof)
    section, _ = annual_statistics(np.stack(sections))
    pm, sm = annual_statistics(np.stack(profiles))
    print(f'Model: {len(profiles)} annual profiles from spin-up directory labels '
          f'{args.model_start_year}-{args.model_end_year}; these are not observational dates.')
    zr, pr, sr = rapid_profile(args.rapid, args.start_year, args.end_year, args.min_coverage)
    plt.rcParams.update({'font.size': 11, 'axes.labelsize': 12,
                         'axes.titlesize': 13, 'axes.titleweight': 'bold',
                         'pdf.fonttype': 42, 'ps.fonttype': 42})
    fig = plt.figure(figsize=(10, 5), constrained_layout=True)
    gs = fig.add_gridspec(2, 2, width_ratios=[2.1, 1], height_ratios=[1, .045])
    ax = fig.add_subplot(gs[0, 0])
    ap = fig.add_subplot(gs[0, 1], sharey=ax)
    cax = fig.add_subplot(gs[1, 0])
    levels = np.linspace(-args.color_limit, args.color_limit, 21)
    filled = ax.contourf(lat, zm, np.ma.masked_invalid(section), levels=levels,
                         cmap='RdBu_r', extend='both', corner_mask=False)
    lines = ax.contour(lat, zm, np.ma.masked_invalid(section), levels=levels[::2],
                        colors='k', linewidths=.45, alpha=.6, corner_mask=False)
    ax.clabel(lines, inline=True, fontsize=8, fmt='%g')
    ax.axvline(args.latitude, color='k', linestyle='--', linewidth=1.1)
    ax.text(args.latitude + 1, 250, f'{args.latitude:g}' + r'$\mathbf{^\circ}$N', fontsize=10)
    ax.set(xlim=(args.lat_min, args.lat_max), ylim=(args.max_depth, 0),
           xlabel='Latitude', ylabel='Depth [m]')
    ax.xaxis.set_major_formatter(FuncFormatter(
        lambda x, pos: '0' if x == 0 else f'{abs(x):g}' + r'$\mathbf{^\circ}$' + ('N' if x > 0 else 'S')))
    ax.set_title('(a) Atlantic Overturning Streamfunction', loc='left')
    fig.colorbar(filled, cax=cax, orientation='horizontal', label='Overturning Streamfunction [Sv]')

    ap.plot(pm, zm, color='black', linewidth=2, label=args.model_label)
    if args.model_std:
        ap.fill_betweenx(zm, pm - sm, pm + sm, color='gray', alpha=.22,
                         linewidth=0, zorder=1, label='MIRAE-ESM $\pm$1 STD')
    ap.plot(pr, zr, color='royalblue', linewidth=2, linestyle='--',
            label=f'RAPID ({args.start_year}-{args.end_year})')
    if args.rapid_std:
        ap.fill_betweenx(zr, pr - sr, pr + sr, color='royalblue', alpha=.15,
                         linewidth=0, zorder=1, label='RAPID $\pm$1 STD')
    #if args.model_std or args.rapid_std:
    #    ap.text(.9, .3, r'Shading: $\pm$1 STD', transform=ap.transAxes,
    #            va='top', fontsize=9)
    ap.axvline(0, color='0.5', linewidth=.7)
    ap.set_xlim(-9,24)
    ap.set_xlabel('Overturning Streamfunction [Sv]')
    ap.set_title(f'(b) Profile at {args.latitude:g}' + r'$\mathbf{^\circ}$N', loc='left')
    ap.tick_params(labelleft=False)
    ap.grid(alpha=.2)
    ap.legend(loc='lower right', fontsize=9, frameon=False)
    # Each profile remains on its native depth grid: no unnecessary smoothing
    # or vertical extrapolation is needed for plotting two lines.
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    #for suffix in ('.png', '.pdf'):
    fig.savefig(str(out) + '.png', dpi=600, bbox_inches='tight')
    plt.close(fig)
    #print(f'Saved: {out}.png and {out}.pdf')
    print(f'Saved: {out}.png')
    print('STD: sample standard deviation (ddof=1) across annual-mean profiles.')
    print('Maximum of mean model profile (Sv):', np.nanmax(pm))
    print('Maximum of mean RAPID profile (Sv):', np.nanmax(pr))
    print('These are maxima of mean profiles, NOT means of instantaneous maxima.')


if __name__ == '__main__':
    main()


