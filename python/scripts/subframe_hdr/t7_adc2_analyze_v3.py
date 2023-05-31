import numpy as np
import matplotlib.pyplot as plt
import os, sys
import cv2
import time
import pandas as pd
from scipy.signal import butter, lfilter, freqz


def arrange_adc2(image, rows=60, ADCsPerCh=20):
    tics = [['img0',time.time()]]
    ##rows:480, col:680, taps:2
    taps, colsPerADC, ch = 1, 2, 17
    cols = colsPerADC*ADCsPerCh*ch
    # rows = 480
    nuImgs = round(len(image)/taps/cols/rows*8*255/256)
    img = np.frombuffer(image,dtype=np.uint8)
    tics.append(['img1',time.time()])

    img2=img.reshape(-1,8,4)[:,:,::-1]
    tics.append(['img2',time.time()])

    img3=np.unpackbits(img2,axis=2).reshape(-1,256) # recover the bits as stored in fifo
    tics.append(['img3',time.time()])

    img4 = img3[:,1:] # get rid of padded bits

    #reorder columns from 15 split unevenly to all 20 in a row
    img4_1 = img4.reshape(-1,17,15)
    img4_1 = np.moveaxis(img4_1,0,1)
    img4_1 = img4_1.reshape(-1,(int(np.shape(img4_1)[1]*15/ADCsPerCh)),ADCsPerCh)
    img4_1 = np.moveaxis(img4_1,0,1)
    img4_1 = img4_1.reshape(-1,17*ADCsPerCh)
    tics.append(['img4',time.time()])

    noch    = 17 # total number of channels
    nob     = 1  # number of bits per channel
    img5 = img4_1.reshape(-1,nob,noch,ADCsPerCh)         # convert into 12 separate data channels
    tics.append(['img5',time.time()])

    # img6 = np.moveaxis(img5,[1,2,3],[3,1,2])[:,:,::-1]    
    img6 = np.moveaxis(img5,1,3)[:,:,:,::-1]
    tics.append(['img6',time.time()])

    # at this point
    # AXES: 
    #    0: Each conversion (#rows x #taps x #cols/ADC)
    #    1: each digital channel
    #    2: columns serialized by each channel
    #    3: the bits for each column

    img7_shape = np.array(img6.shape); img7_shape[-1] = 1; img7_shape[2]=ADCsPerCh
    img7    = np.zeros(img7_shape,dtype=np.bool)
    img7[:,:,:ADCsPerCh,-nob:] = img6.copy()
    tics.append(['img7',time.time()])

    # img8 = np.packbits(img7,axis=-1).view(np.uint16).reshape(img7_shape[:-1])
    img8    = img7.copy()
    tics.append(['img8',time.time()])

    # col_order = np.arange(ADCsPerCh)
    col_order =  [19, 9, 14, 4, 18, 8,13, 3,  16, 6, 11, 1, 17, 7, 12, 2,15, 5, 10, 0]
    # col_map =  [0, 4, 12, 8, 16, 2, 6, 14, 10, 18, 1, 5, 13, 9, 17, 3, 7, 15, 11, 19]
    col_map = np.argsort(col_order[:ADCsPerCh])[::-1]

    ch_map  = np.arange(ch)
    ch_map  = [0,1,2,3,4,5,6,7,11,10,8,9,12,13,14,15,16]

    img8    = img8[:,:,col_map]
    tics.append(['img8_mapped',time.time()])

    img9 = img8[:,ch_map,:].reshape(nuImgs,rows,taps,colsPerADC,ADCsPerCh*ch)
    tics.append(['img9',time.time()])

    img10 = np.zeros((nuImgs,rows,taps,colsPerADC*ADCsPerCh*ch),dtype=np.uint16)
    img10[:,:,:,0::2] =   img9[:,:,:,0,:]
    img10[:,:,:,1::2] =   img9[:,:,:,1,:]
    tics.append(['img10',time.time()])

    # for i in range(1,len(tics)):
    #     logging.info("arrange_adc2 {}:{}".format(tics[i][0],(tics[i][1]-tics[i-1][1])*1000))

    return img10.reshape(nuImgs,rows,cols)


common_folder = '/home/raulgool/Documents/UofT/Project/CameraSystems/T6/src/python/image/rotating_stick'
# data_folder   = 'rotating_stick_halfsine_x{freq}_1v1_2v8_{period}ms/t6Exp000060Mask900_02{current}3ma'
data_folder   = 'rotating_stick_halfsine_x{freq}_1v1_2v8_{period}ms/t6Exp000060Mask900_constant2'
file_name     = 'subbyte_row_0240_{:04d}.npz'
                

for fx in range(4):
    [freq, period]  = [[1,68.4],[4,17.1],[8,8.55],[16,4.275]][fx]

    # current         = np.arange(9,dtype=int)[4]
    for current in np.arange(9,dtype=int)[0:1]:
        # file_index      = 10
        for file_index in range(20):
            current_folder  = os.path.join(common_folder,data_folder.format(freq=freq,period=period,current=current))
            read_file       = os.path.join(current_folder,file_name.format(file_index))
            write_file_mp4  = read_file[:-4]+'.mp4'


            data_f          = np.load(read_file)
            data            = data_f['img']
            comp_out        = arrange_adc2(data)


            # sys.exit()

            # comp_out = np.moveaxis(comp_out,0,2).reshape(-1,N)
            # pixN = comp_out.shape[0]

            comp_event          = np.diff(comp_out,axis=0,prepend=1)
            [nuImgs,rows,cols]  = comp_event.shape

            if(1):
                font                   = cv2.FONT_HERSHEY_SIMPLEX
                bottomLeftCornerOfText = (10,50)
                fontScale              = 1
                fontColor              = (255,100,100)
                thickness              = 2
                lineType               = 2

                for i in range(nuImgs):
                    comp_event_posneg = np.zeros([rows,cols,3],dtype=np.uint8) #bgr
                    comp_event_posneg[:,:,1][comp_event[i,:,:]<0] = 255
                    comp_event_posneg[:,:,2][comp_event[i,:,:]>0] = 255

                    img = cv2.putText(comp_event_posneg,'{:03d}'.format(i), 
                        bottomLeftCornerOfText, 
                        font, 
                        fontScale,
                        fontColor,
                        thickness,
                        lineType)

                    if(0):
                        cv2.imshow('subframes',img)
                        cv2.waitKey(1)
                        time.sleep(1/30)

                    # cv2.imwrite('data/{:03d}.png'.format(i),(comp_event[:,:,i]*255).astype(np.uint8))
                    cv2.imwrite('data/{:03d}.png'.format(i),(img).astype(np.uint8))

                cv2.destroyAllWindows()

                os.system("ffmpeg -framerate 30 -pattern_type glob -i 'data/*.png' \
                            -c:v libx265 -r 30 -pix_fmt yuv420p -y {write_file_mp4}".format(write_file_mp4=write_file_mp4))

                # nuEvent = [len(np.where(comp_event[i,:,:]>0)[0]) for i in range(nuImgs-1)]


            # plt.figure();plt.imshow(np.log10(adc2),cmap='gray',vmin=0,vmax=5)