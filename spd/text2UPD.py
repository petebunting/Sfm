#! /home/osian/miniconda3/bin/python
'''
Description: A script to convert photogrammetric points stored within a text file into the Unsorted Pulse Data (UPD) format.
Author: Osian Roberts.
Date: 3/5/2019.
'''
import argparse, sys, os, h5py, spdpy

def progress_bar(n_tasks, progress):
    ''' A function to display a progress bar on the unix terminal. '''
    barLength, status = 50, ''
    progress = float(progress) / float(n_tasks)
    if progress >= 1.0:
        progress = 1
        status = 'Done. \n'
    block = round(barLength * progress)
    text = '\r{} {:.0f}% {}'.format('#' * block + '-' * (barLength - block), round(progress * 100, 0), status)
    sys.stdout.write(text)
    sys.stdout.flush()


def txt2UPD(Input, Output, Header, separator, x_col, y_col, z_col, r_col, g_col, b_col):
    '''
    A function to convert a text file into the UPD format.

    Input: input text file path. 
    Output: output UPD file path.
    separator: column separator/delimiter for the input text file.
    x_col: column index of the x coordinates.
    y_col: column index of the y coordinates.
    z_col: column index of the z coordinates.
    r_col: column index of the red color channel.
    g_col: column index of the green color channel.
    b_col: column index of the blue color channel.
    '''
    # try to open the input text file:
    try:
        f = open(Input, 'r')
        n_points = sum([1 for line in f])
        f.seek(0)
        if Header == True:
            f.readline()
    except Exception:
        sys.exit('Error: unable to read input text file.')

    print('Creating the output file: '+os.path.basename(Output))
    UPD = spdpy.createSPDFile(Output)
    spdWriter = spdpy.SPDPyNoIdxWriter()
    spdWriter.open(UPD, Output)
    UPD.setReceiveWaveformDefined(0)
    UPD.setTransWaveformDefined(0)
    UPD.setDecomposedPtDefined(0)
    UPD.setDiscretePtDefined(1)
    UPD.setOriginDefined(0)
    UPD.setHeightDefined(0)
    UPD.setRgbDefined(1)
    UPD.setGeneratingSoftware('Python.')
    UPD.setUserMetaField('Processed by Osian!')

    # iterate through each line in the input file:
    for idx, line in enumerate(f):
        line = line.strip('\n').split(separator)
        try:
            # create point:
            Point = spdpy.createSPDPointPy()
            Point.returnID = 1 # this is set to 1 as Photogrammetry cannot receive multiple-returns.
            Point.x = float(line[x_col])
            Point.y = float(line[y_col])
            Point.z = float(line[z_col])
            Point.height = 0.0
            Point.amplitudeReturn = (int(line[r_col]) + int(line[g_col]) + int(line[b_col])) / 3
            Point.red = int(line[r_col])
            Point.green = int(line[g_col])
            Point.blue = int(line[b_col])
            Point.classification = 1 # 1 = unclassified
            Point = [Point]

            # assign point to pulse:
            Pulse = spdpy.createSPDPulsePy()
            Pulse.numberOfReturns = 1 # this is set to 1 as Photogrammetry cannot receive multiple-returns.
            Pulse.pts = Point

            spdWriter.writeData([Pulse])
            del Pulse, Point
        except Exception:
            continue
        del line
        progress_bar(n_points, idx+1)

    # close the upd file:
    f.close()
    spdWriter.close(UPD)
    print('Done.')

###############################################################################################################

parser = argparse.ArgumentParser(prog='txt2UPD', description='A script to convert photogrammetric points stored within a text file into the Unsorted Pulse Data (UPD) format.')
parser._action_groups.pop()
required = parser.add_argument_group('Required Arguments')
required.add_argument('-input', metavar='', type=str, help='Path to the input text file.')
required.add_argument('-out', metavar='', type=str, help='Path to the output UPD file.')

optional = parser.add_argument_group('Optional Arguments')
optional.add_argument('-header', metavar='', type=bool, default=False, help='Boolean indicating whether to skip the first header line.')
optional.add_argument('-sep', metavar='', type=str, default=',', help='Delimiter. Default == comma.')
optional.add_argument('-x', metavar='', type=int, default=0, help='Column index for x coordinates. Default=0.')
optional.add_argument('-y', metavar='', type=int, default=1, help='Column index for y coordinates. Default=1.')
optional.add_argument('-z', metavar='', type=int, default=2, help='Column index for z coordinates. Default=2.')
optional.add_argument('-r', metavar='', type=int, default=3, help='Column index for the red color channel. Default=3.')
optional.add_argument('-g', metavar='', type=int, default=4, help='Column index for the green color channel. Default=4.')
optional.add_argument('-b', metavar='', type=int, default=5, help='Column index for the blue color channel. Default=5.')
args = parser.parse_args()

if not args.input:
    parser.print_help()
    sys.exit('\n' + 'Error: Please specify an input text file.')
elif not args.out:
    parser.print_help()
    sys.exit('\n' + 'Error: Please specify an output UPD.')
elif not os.path.exists(args.input):
    parser.print_help()
    sys.exit('\n' + 'Error: input file not found. Please check the file path.')
else:
    txt2UPD(args.input, args.out, args.header, args.sep, args.x, args.y, args.z, args.r, args.g, args.b)

