
import numpy as np
#import matplotlib.pyplot as plt
from matplotlib import pyplot as plt
from PIL import Image
from tools import bmpmerge
import argparse

# k=np.ones((320,512),dtype=np.uint8)*255
# k[:,0::2] = 0
# img = Image.fromarray(k).convert('1')
# img.save("maskfile/t6_alternate.bmp")  
#

ap = argparse.ArgumentParser()
ap.add_argument("-f", "--file_name", type=str, default="./maskfile/t6_merge.bmp",
                help="save file name")
ap.add_argument("-s", "--select_source", type=float, default=1,
                help="select source mask files")
ap.add_argument("-n", "--number_repeat", type=int, default=1,
                help="Number of repetition")
ap.add_argument("-nd", "--display", action="store_false", help="diplay mask file image")
ap.add_argument("-i", "--invert", action="store_true", help="invert mask data")
args = ap.parse_args()


mask_files1 = [ './maskfile/t6_line.bmp',
                './maskfile/t6_f.bmp',
                './maskfile/t6_e.bmp',
                './maskfile/t6_d.bmp',
                './maskfile/t6_c.bmp',
                './maskfile/t6_b.bmp',
                './maskfile/t6_a.bmp'
                ]

mask_files2  = ['./maskfile/t6_all0.bmp',
                './maskfile/t6_all1.bmp'
                ]
mask_files2_1= ['./maskfile/t6_all1.bmp',
                './maskfile/t6_all1.bmp'
                ]
mask_files2_2= ['./maskfile/t6_all0.bmp',
                './maskfile/t6_all0.bmp'
                ]

mask_files3  = ['./maskfile/t6_A.bmp',
                './maskfile/t6_A.bmp']

mask_files4 = [ './maskfile/t6_merge_cp.bmp'
                ]

mask_files5 = ['./maskfile/t6_intersect_1.bmp',
               './maskfile/t6_intersect_2.bmp',]


mask_files6  = ['./maskfile/t6_all1.bmp',
                './maskfile/t6_all1.bmp'
                ]

mask_files11  = [ './maskfile/t6_strip20v.bmp',
                 './maskfile/t6_strip21v.bmp'
                ]

mask_files11_1= [ './maskfile/t6_strip20v.bmp',
                 './maskfile/t6_strip20v.bmp'
                ]

mask_files11_2= [ './maskfile/t6_strip21v.bmp',
                 './maskfile/t6_strip21v.bmp'
                ]

mask_files12 = ['./maskfile/t6_CMC_mask_flipped.bmp',
                './maskfile/t6_CMC_mask_flipped.bmp']

mask_files13 = ['./maskfile/t6_alternate.bmp',
                './maskfile/t6_alternate.bmp']

mask_files14 = ['./maskfile/t6_binaryColCode.bmp',
                './maskfile/t6_binaryColCode.bmp']

mask_files15 = ['./maskfile/t6_2x2_1.bmp',
                './maskfile/t6_2x2_2.bmp',
                './maskfile/t6_2x2_3.bmp',
                './maskfile/t6_2x2_4.bmp']

mask_files16 = ['./maskfile/t6_strip_h.bmp',
                './maskfile/t6_strip_h.bmp']

mask_files17 = ['./maskfile/t6_all1.bmp',
                './maskfile/t6_all0.bmp']

if args.select_source == 1:
    mask_files = mask_files1
    order = [0,1,2,3,4,5,6]

elif args.select_source == 2:
    mask_files = mask_files2
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]
    
elif args.select_source == 2.1:
    mask_files = mask_files2_1
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]
    
elif args.select_source == 2.2:
    mask_files = mask_files2_2
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]    

elif args.select_source == 3:
    mask_files = mask_files3
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]

elif args.select_source == 4:
    mask_files = mask_files4
    order = [0]

elif args.select_source == 5:
    mask_files = mask_files5
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]
elif args.select_source == 6:
    mask_files = mask_files6
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]


elif args.select_source == 11:
    mask_files = mask_files11
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]

elif args.select_source == 11.1:
    mask_files = mask_files11_1
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]

elif args.select_source == 11.2:
    mask_files = mask_files11_2
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]

elif args.select_source == 12:
    mask_files = mask_files12
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]

elif args.select_source == 13:
    mask_files = mask_files13
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]
        
elif args.select_source == 14:
    mask_files = mask_files14
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]

elif args.select_source == 15:
    mask_files = mask_files15
    if args.invert:
        order = [3,2,1,0]
    else:
        order = [0,1,2,3]

elif args.select_source == 15.1:
    mask_files = mask_files15
    if args.invert:
        order = [0,0,0,0]
    else:
        order = [0,0,0,0]

elif args.select_source == 16:
    mask_files = mask_files16
    if args.invert:
        order = [1,0]
    else:
        order = [0,1]
    
elif int(args.select_source) == 17:
    mask_files = mask_files17

    k = round((args.select_source-int(args.select_source))*100)
    total_subs = 99
    order = np.zeros(total_subs, dtype=np.int)
    for i in range(k):
        order[total_subs-i-1]=1


else:
    mask_files = mask_files2
    order = [0,1]



print(order)
bmpmerge(args.file_name, mask_files, repeat=args.number_repeat, order=order, show=args.display)