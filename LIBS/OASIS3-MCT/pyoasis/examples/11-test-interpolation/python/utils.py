def grid_longname(grid):
    grid_ln = {"torc": "ORCA 2 deg",
               "nogt": "ORCA 1 deg",
               "nogh": "ORCA 0.25 deg",
               "to25": "ORCA 0.25 deg",
               "bggd": "reg. lon/lat 144x143",
               "ssea": "red. Gaussian T127",
               "sse7": "red. Gaussian T127 (7 corners)",
               "t359": "red. Gaussian T359",
               "icos": "icosahedral Dynamico",
               "icoh": "HR icosahedral Dynamico"}
    return grid_ln[grid]


def grid_shape(grid):
    grid_sz = {"torc": [182, 149],
               "nogt": [362, 294],
               "nogh": [1442, 1050],
               "to25": [1442, 1050],
               "bggd": [144, 143],
               "ssea": [24572, 1],
               "sse7": [24572, 1],
               "t359": [181724, 1],
               "icos": [15212, 1],
               "icoh": [2016012, 1]}

    return grid_sz[grid][0], grid_sz[grid][1]


def grid_size(grid):
    nx, ny = grid_shape(grid)
    return nx * ny


def grid_perio(grid):
    grid_pe = {"torc": ["P", 2],
               "nogt": ["P", 2],
               "nogh": ["P", 2],
               "to25": ["P", 2],
               "bggd": ["P", 0],
               "ssea": ["P", 0],
               "sse7": ["P", 0],
               "t359": ["P", 0],
               "icos": ["P", 0],
               "icoh": ["P", 0]}

    return grid_pe[grid]


def grid_struct(grid):
    grid_st = {"torc": "LR",
               "nogt": "LR",
               "nogh": "LR",
               "to25": "LR",
               "bggd": "LR",
               "ssea": "D",
               "sse7": "D",
               "t359": "D",
               "icos": "U",
               "icoh": "U"}

    return grid_st[grid]


valid_grids = ('torc', 'nogt', 'bggd', 'sse7', 'icos')
ocean_grids = ('torc', 'nogt')


def grid_is_valid(grid):
    return grid in valid_grids


def grid_is_ocean(grid):
    return grid in ocean_grids


def grid_is_hr(grid):
    return grid in ('icoh', 'to25', 'nogh')


def write_namcouple(sgrid, dgrid, has_graphics):
    namcouple = open("namcouple", "w")
    print("############################################", file=namcouple)
    print("$NFIELDS", file=namcouple)
    print("1", file=namcouple)
    print("$END", file=namcouple)
    print("############################################", file=namcouple)
    print("$RUNTIME", file=namcouple)
    print("21600", file=namcouple)
    print("$END", file=namcouple)
    print("############################################", file=namcouple)
    print("$NLOGPRT", file=namcouple)
    print("0 0", file=namcouple)
    print("$END", file=namcouple)
    print("############################################", file=namcouple)
    print("$STRINGS", file=namcouple)
    if has_graphics:
        print("FSENDANA FRECVANA 1 7200 1 rst.nc EXPORTED", file=namcouple)
    else:
        print("FSENDANA FRECVANA 1 7200 1 rst.nc EXPOUT", file=namcouple)
    print("{} {} {} {} {} {}".format(grid_shape(sgrid)[0], grid_shape(sgrid)[1],
                                     grid_shape(dgrid)[0], grid_shape(dgrid)[1],
                                     sgrid, dgrid), file=namcouple)
    print("{} {} {} {}".format(grid_perio(sgrid)[0], grid_perio(sgrid)[1],
                               grid_perio(dgrid)[0], grid_perio(dgrid)[1]),
                               file=namcouple)
    print("SCRIPR", file=namcouple)
    print("CONSERV {} SCALAR LATLON 1 FRACAREA FIRST".format(grid_struct(sgrid)),
                                                             file=namcouple)
    print("$END", file=namcouple)
    namcouple.close()
