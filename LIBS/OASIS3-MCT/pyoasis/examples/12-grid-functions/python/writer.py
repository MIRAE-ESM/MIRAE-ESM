#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy as np
import math

comp = pyoasis.Component("writer")

print(comp)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

nx_loc = 18
ny_loc = 18
nx_global = comm_size*nx_loc
ny_global = ny_loc

dp_conv = math.pi/180.

partition = pyoasis.BoxPartition(comm_rank*nx_loc, nx_loc, ny_loc, nx_global)

dx = 360.0/nx_global
dy = 180.0/ny_global

lon = np.array([-180. + comm_rank*nx_loc*dx + float(i)*dx
                + dx/2.0 for i in range(nx_loc)],
               dtype=np.float64)
lon = np.tile(lon, (ny_loc, 1)).T

lat = np.array([-90.0 + float(j)*dy + dy/2.0 for j in range(ny_loc)],
               dtype=np.float64)
lat = np.tile(lat, (nx_loc, 1))

grid = pyoasis.Grid('pyoa', nx_global, ny_global, lon, lat, partition)

ncrn = 4
clo = pyoasis.asarray(np.zeros((nx_loc, ny_loc, ncrn), dtype=np.float64))
clo[:, :, 0] = lon[:, :] - dx/2.0
clo[:, :, 1] = lon[:, :] + dx/2.0
clo[:, :, 2] = clo[:, :, 1]
clo[:, :, 3] = clo[:, :, 0]
cla = pyoasis.asarray(np.zeros((nx_loc, ny_loc, ncrn), dtype=np.float64))
cla[:, :, 0] = lat[:, :] - dy/2.0
cla[:, :, 1] = cla[:, :, 0]
cla[:, :, 2] = lat[:, :] + dy/2.0
cla[:, :, 3] = cla[:, :, 2]

grid.set_corners(clo, cla)

msk = np.zeros((nx_loc, ny_loc), dtype=np.int32)
if comm_rank == 0:
    msk[4:6, 2:16] = 1
    msk[6:11, (8, 9, 14, 15)] = 1
    msk[11, (8, 9, 10, 13, 14, 15)] = 1
    msk[12, 9:15] = 1
    msk[13, 10:14] = 1
elif comm_rank == 1:
    msk[(3, 14), 14:16] = 1
    msk[(4, 13), 12:16] = 1
    msk[(5, 12), 11:15] = 1
    msk[(6, 11), 10:13] = 1
    msk[(7, 10), 9:12] = 1
    msk[8:10, 2:11] = 1
elif comm_rank == 2:
    msk[(4, 13), 4:14] = 1
    msk[(5, 12), 3:15] = 1
    msk[(6, 11), 2:5] = 1
    msk[(6, 11), 13:16] = 1
    msk[7:11, 2:4] = 1
    msk[7:11, 14:16] = 1

grid.set_mask(msk, companion="STFC")

frc = np.ones((nx_loc, ny_loc), dtype=np.float64)
frc = np.where(msk == 1, 0.0, 1.0)

grid.set_frac(frc, companion="STFC")

area = np.zeros((nx_loc, ny_loc), dtype=np.float64)
area[:, :] = dp_conv * \
            np.abs(np.sin(cla[:, :, 2] * dp_conv) -
                   np.sin(cla[:, :, 0] * dp_conv)) * \
            np.abs(clo[:, :, 1]-clo[:, :, 0])

grid.set_area(area)

angle = np.zeros((nx_loc, ny_loc), dtype=np.float64)

grid.set_angle(angle)

if comm_rank == 0:
    nx_mono = 180
    ny_mono = 90
    dxm = 360.0 / nx_mono
    dym = 180.0 / ny_mono

    lonm = np.array([float(i) * dxm
                    + dxm/2.0 for i in range(nx_mono)],
                    dtype=np.float64)
    lonm = np.tile(lonm, (ny_mono, 1)).T

    latm = np.array([-90.0 + float(j) * dym
                    + dym/2.0 for j in range(ny_mono)],
                    dtype=np.float64)
    latm = np.tile(latm, (nx_mono, 1))

    grid2 = pyoasis.Grid('mono', nx_mono, ny_mono, lonm, latm)

    ncrnm = 4
    clom = pyoasis.asarray(np.zeros((nx_mono, ny_mono, ncrnm),
                           dtype=np.float64))
    clom[:, :, 0] = lonm[:, :] - dxm/2.0
    clom[:, :, 1] = lonm[:, :] + dxm/2.0
    clom[:, :, 2] = clom[:, :, 1]
    clom[:, :, 3] = clom[:, :, 0]
    clam = pyoasis.asarray(np.zeros((nx_mono, ny_mono, ncrnm),
                           dtype=np.float64))
    clam[:, :, 0] = latm[:, :] - dym/2.0
    clam[:, :, 1] = clam[:, :, 0]
    clam[:, :, 2] = latm[:, :] + dym/2.0
    clam[:, :, 3] = clam[:, :, 2]
    grid2.set_corners(clom, clam)

    mskm = np.zeros((nx_mono, ny_mono), dtype=np.int32)
    mskm = np.where(np.power(lonm[:, :]-180., 2) +
                    np.power(latm[:, :], 2) < 30*30, 1, 0)
    grid2.set_mask(mskm)

    frcm = np.ones((nx_mono, ny_mono), dtype=np.float64)
    frcm = np.where(mskm == 1, 0.0, 1.0)

    grid2.set_frac(frcm)

    aream = np.zeros((nx_mono, ny_mono), dtype=np.float64)
    aream[:, :] = dp_conv * np.abs(np.sin(clam[:, :, 2] * dp_conv)
                  - np.sin(clam[:, :, 0] * dp_conv))\
                    * np.abs(clom[:, :, 1]-clom[:, :, 0])

    grid2.set_area(aream)

    anglem = np.zeros((nx_mono, ny_mono), dtype=np.float64)

    grid2.set_angle(anglem)

    grid2.write()

grid.write()

var_out = pyoasis.Var("FSENDOCN", partition, OASIS.OUT)
var_in = pyoasis.Var("FRECVATM", partition, OASIS.IN)

comp.enddef()

date = int(0)
field = pyoasis.asarray(msk)
var_out.put(date, field)
var_in.get(date, field)

try:
    import netCDF4
    import cartopy.crs as ccrs
    import matplotlib.pyplot as plt
    import matplotlib.collections
    from matplotlib.colors import ListedColormap
except ImportError:
    if comm_rank == 0:
        print("The example completed correctly\n")
        print("but no plotting library available.\n")
        print("Install netcdf, matplotlib and cartopy\n")
        print("for plotting the results\n")
        print("In the meantime you can visualize the\n")
        print("contents of work/masks.nc with ncview work/masks.nc")
    exit(0)

if comm_rank == 0:
    def caramelbleucm():
        rcol = np.hstack((np.linspace(0.1, 0.0, 30 - 0 + 1)[:-1],
                          np.linspace(0.0, 0.8, 47 - 30 + 1)[:-1],
                          np.linspace(0.8, 1.0, 52 - 47 + 1)[:-1],
                          np.linspace(1.0, 1.0, 70 - 52 + 1)[:-1],
                          np.linspace(1.0, 1.0, 100 - 70 + 1)))
        gcol = np.hstack((np.linspace(0.1, 0.9, 30 - 0 + 1)[:-1],
                          np.linspace(0.9, 1.0, 47 - 30 + 1)[:-1],
                          np.linspace(1.0, 1.0, 52 - 47 + 1)[:-1],
                          np.linspace(1.0, 0.9, 70 - 52 + 1)[:-1],
                          np.linspace(0.9, 0.1, 100 - 70 + 1)))
        bcol = np.hstack((np.linspace(1.0, 1.0, 30 - 0 + 1)[:-1],
                          np.linspace(1.0, 1.0, 47 - 30 + 1)[:-1],
                          np.linspace(1.0, 0.8, 52 - 47 + 1)[:-1],
                          np.linspace(0.8, 0.0, 70 - 52 + 1)[:-1],
                          np.linspace(0.0, 0.1, 100 - 70 + 1)))
        alph = np.linspace(1.0, 1.0, 101)

        cm = np.array((np.transpose(rcol), np.transpose(gcol),
                       np.transpose(bcol), np.transpose(alph)))
        cm = np.transpose(cm)
        newmap = ListedColormap(cm, name='CaramelBleu')
        return newmap

    dgrid = 'pyoa'
    gf = netCDF4.Dataset('grids.nc', 'r')
    lons = gf.variables[dgrid + '.lon'][:, :].flatten()
    lats = gf.variables[dgrid + '.lat'][:, :].flatten()
    n_points = lons.size
    dgrid_corners = len(gf.dimensions['crn_' + dgrid])
    dlon = gf.variables[dgrid + '.clo'][:].reshape(dgrid_corners, -1)
    dlat = gf.variables[dgrid + '.cla'][:].reshape(dgrid_corners, -1)
    gf.close()

    mf = netCDF4.Dataset('masks.nc', 'r')
    msi = mf.variables[dgrid + '.msk'][:].flatten()
    da_msk = msi == 1
    mf.close()

    da_lonlat = np.transpose(np.array([dlon, dlat]))
    da_lonlat = np.delete(da_lonlat, np.where(da_msk), axis=0)

    dp_conv = math.pi / 180.
    field1 = 2.0 + np.sin(2.0 * lats * dp_conv) ** 4.0 * \
             np.cos(4.0 * lons * dp_conv)

    field1 = np.delete(field1, np.where(da_msk))

    ti_str = "Grid and mask created by PyOasis"
    fig = plt.figure(0, figsize=(8.25, 4.125), frameon=True)
    plt.suptitle(ti_str)
    cmap = caramelbleucm()
    sd_proj = ccrs.PlateCarree()
    di_ax = plt.subplot(111, projection=sd_proj)
    di_ax.set_global()
    # di_ax.coastlines(resolution='110m', linewidth=0.5)
    di_pc = matplotlib.collections.PolyCollection(da_lonlat)
    di_pc.set_array(field1)
    di_pc.set_cmap(cmap)
    di_pc.set_edgecolor('black')
    di_pc.set_linewidth(0.3)
    di_ax.add_collection(di_pc)
    di_gl = di_ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                            linewidth=0.0, linestyle=':', color='gray')
    di_gl.top_labels = False
    di_gl.right_labels = False
    di_ax.set_title('Precomputed mask')

    plt.subplots_adjust(left=0.10, right=0.90, wspace=0.05, hspace=0.)
    plt.show()

del comp
