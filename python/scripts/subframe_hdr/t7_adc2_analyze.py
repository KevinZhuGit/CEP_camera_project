import numpy as np
import matplotlib.pyplot as plt
import os
import cv2
import time
import pandas as pd
from scipy.signal import butter, lfilter, freqz


mergeMertens = cv2.createMergeMertens()
mergeMertens.setContrastWeight(1)
mergeMertens.setContrastWeight(1)
def hdr2ldr(img,vmin=0,vmax=1,LSB=4):
    """
        img:        2D np.uint16
        vmin,vmax:  scaling output images even further
        LSB:        What is the noise-free LSB in uint16. 
                    The 16-bit input image will be divide into (16-8-LSB+1)x 8-bit images
    """
    LSB    = int(LSB)
    nuImgs = 16-8-LSB+1 # number of 8-bit images

    # split 16-bit image into 8-bit images
    imgs = np.zeros((nuImgs,img.shape[0],img.shape[1]),dtype=np.uint8)
    for i in range(nuImgs):
        imgs[i,:,:] = np.interp(img,[0,2**(i+8+LSB)-1],[0,2**8-1]).astype(np.uint8)

    # fuse images to create hdr image
    fusion = mergeMertens.process(imgs[:,:,:])
    fusion = np.interp(fusion,[vmin,vmax],[0,2**16-1]).astype(np.uint16)
    return fusion

def butter_lowpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return b, a

def butter_lowpass_filter(data, cutoff, fs, order=5):
    b, a = butter_lowpass(cutoff, fs, order=order)
    y = lfilter(b, a, data)
    return y

def arrange_adc2(image, rows=480, ADCsPerCh=20):
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

data_folders = {
                1:['t7_sin_f1_v_0.48_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600','../t7_sin_f1_t_67.41.csv'],
                2:['t7_sin_f2_v_0.48_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600','../t7_sin_f2_t_32.8.csv'],
                3:['t7_sin_f3_v_0.48_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600','../t7_sin_f3_t_21.9.csv'],
                4:['t7_sin_f4_v_0.48_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600','../t7_sin_f4_t_16.4.csv'],

                5:['t7_sin_f1_v_0_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600',   '../t7_sin_f1_t_67.41.csv'],
                6:['t7_sin_f2_v_0_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600',   '../t7_sin_f2_t_33.1.csv'],
                7:['t7_sin_f3_v_0_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600',   '../t7_sin_f3_t_21.9.csv'],
                8:['t7_sin_f4_v_0_to_3.9_ph_11.6_t6Exp000042Mask600/t6Exp000042Mask600',   '../t7_sin_f4_t_16.4.csv'],

                9:['t7_const_3v3_t6Exp000042Mask600'],
                10:['t7_const_3v9_t6Exp000042Mask600'],

                11:['t7_sin_f1_v_0_to_3.9_ph_11.6_t6Exp000278Mask121/t6Exp000278Mask121','../t7_sin_f1_71.8.csv','f1'],
                12:['t7_sin_f2_v_0_to_3.9_ph_11.6_t6Exp000278Mask121/t6Exp000278Mask121','../t7_sin_f2_35.5.csv','f2'],
                13:['t7_sin_f3_v_0_to_3.9_ph_11.6_t6Exp000278Mask121/t6Exp000278Mask121','../t7_sin_f3_23.6.csv','f3'],
                14:['t7_sin_f4_v_0_to_3.9_ph_11.6_t6Exp000278Mask121/t6Exp000278Mask121','../t7_sin_f4_17.5.csv','f4']
                }

data_index = 14
current_data        = data_folders[data_index][0]
current_vref        = data_folders[data_index][1]
current_data_name   = data_folders[data_index][2]

data = bytearray(np.load(os.path.join('../../image/{}'.format(current_data),'subbyte_0014.npy')))
vref_csv = os.path.join("../../image/{}".format(current_data),current_vref)


df = pd.read_csv(vref_csv, sep=',', header=None)
vref_all = df.values[20:-1].astype(float)
vref_all[:,1] = butter_lowpass_filter(vref_all[:,1],5e3,1e6,6)


comp_out = 1-arrange_adc2(data).astype(np.float)
[nuImgs, rows, cols] = comp_out.shape

exposure_time = 67*1e-3
N = nuImgs
t = np.linspace(0,1,N)
vref = np.interp(t*exposure_time,vref_all[:,0],vref_all[:,1])
vref = np.interp(vref,[0,np.max(vref)],[1,0])


np.save('data/comp_out_{}.npy'.format(current_data_name),np.moveaxis(comp_out,0,2))

# exit()

comp_out = np.moveaxis(comp_out,0,2).reshape(-1,N)
pixN = comp_out.shape[0]

comp_event = np.diff(comp_out,axis=1,prepend=0)

comp_event_sub_mean    = []
L_calculated_mean = -np.ones([pixN,50])
if(0):
    for i in range(pixN):
        comp_event_sub_mean.append(np.where(comp_event[i,:]>0))
        n = np.asarray(np.where(comp_event[i,:]>0)).flatten()
        nVals = len(n)
        if(nVals!=0):
            L_calculated_mean[i,:nVals] = vref[n]/t[n]

    adc2   = np.asarray(np.mean(np.ma.masked_values(L_calculated_mean,-1),axis=1)).reshape(rows,cols)
    adc2[adc2<=0] = np.min(adc2[adc2>0])
    adc2[np.isinf(adc2)] = np.min(adc2[adc2>0])

    adc2_mean = np.interp(adc2,(np.min(adc2),120),(1,2**16-1)).astype(np.uint16)

    adc2_mean_log = np.interp(np.log10(adc2_mean),(0,np.log10(2**16)),(0,255)).astype(np.uint8)
    np.save('data/mean_{}.npy'.format(current_data_name),adc2_mean)
    cv2.imwrite("data/log_mean_{}.png".format(current_data_name),adc2_mean_log)
    # cv2.imwrite("expfusion_mean_{}")

comp_event_sub    = []
L_calculated = -np.ones([pixN,50])
nVals_all = np.zeros(pixN)
if(1):
    for i in range(pixN):
        comp_event_sub.append(np.where(comp_event[i,:]>0))
        n = np.asarray(np.where(comp_event[i,:]>0)).flatten()
        n_before = np.asarray(np.where(comp_event[i, :] > 0)).flatten() - 1
        nVals = len(n)
        nVals_all[i] = nVals

        #Regression general line
        # if nVals > 1 :
        #     ys = (vref[n] + vref[n_before])/ 2
        #     xs = (t[n] + t[n_before]) / 2

        #     coeffs = np.polyfit(xs, ys, 1)
        #     L_esti = coeffs[0]

        # else:
        #     if t[n] > 0:
        #         L_esti = vref[n] / t[n]
        #     else:
        #         L_esti = 0


        # L_calculated[i,:nVals] = L_esti

        #Regression line at 0
    #     if nVals > 1:
    #         ys = (vref[n] + vref[n_before]) / 2
    #         xs = (t[n] + t[n_before]) / 2

    #         L_esti = np.sum(ys*xs) / np.sum(xs**2)

    #         # This was trying to penalize lines that dont go through mid
    #         #  points but it did not show much difference
    #         # L_esti = np.sum(vref[n] * t[n] + vref[n_before]*t[n_before]) / np.sum(t[n]**2 + t[n_before]**2)


    #     else:
    #         if t[n] > 0:
    #         	L_esti = vref[n] / t[n]
    #         else:
    #         	L_esti = 0

    #     L_calculated[i, :nVals] = L_esti

    # adc2   = np.asarray(np.mean(np.ma.masked_values(L_calculated,-1),axis=1)).reshape(rows,cols)
    # adc2[adc2<=0] = np.min(adc2[adc2>0])
    # adc2[np.isinf(adc2)] = np.min(adc2[adc2>0])

    # adc2_regression = np.interp(adc2,(np.min(adc2),120),(1,2**16-1)).astype(np.uint16)

    # adc2_reg_log = np.interp(np.log10(adc2_regression),(0,np.log10(2**16)),(0,255)).astype(np.uint8)
    # np.save('data/reg_{}.npy'.format(current_data_name),adc2_reg_log)
    # cv2.imwrite("data/log_reg_{}.png".format(current_data_name),adc2_reg_log)



if(0):
    comp_event = comp_event.reshape(rows,cols,-1)
    # comp_event = np.abs(comp_event)
    # comp_event[comp_event<0] = 0;


    font                   = cv2.FONT_HERSHEY_SIMPLEX
    bottomLeftCornerOfText = (10,50)
    fontScale              = 1
    fontColor              = (255,100,100)
    thickness              = 2
    lineType               = 2

    for i in range(nuImgs):
        comp_event_posneg = np.zeros([rows,cols,3],dtype=np.uint8) #bgr
        comp_event_posneg[:,:,1][comp_event[:,:,i]>0] = 255
        comp_event_posneg[:,:,2][comp_event[:,:,i]<0] = 255

        img = cv2.putText(comp_event_posneg,'{:03d}'.format(i), 
            bottomLeftCornerOfText, 
            font, 
            fontScale,
            fontColor,
            thickness,
            lineType)


        cv2.imshow('subframes',img)
        cv2.waitKey(1)
        # cv2.imwrite('data/{:03d}.png'.format(i),(comp_event[:,:,i]*255).astype(np.uint8))
        cv2.imwrite('data/{:03d}.png'.format(i),(img).astype(np.uint8))
        time.sleep(1/10)

    cv2.destroyAllWindows()

    os.system("ffmpeg -framerate 10 -pattern_type glob -i 'data/*.png' \
                -c:v libx265 -r 30 -pix_fmt yuv420p t7_680x480_subframe_events_{}.mp4".format(current_data_name))

    nuEvent = [len(np.where(comp_event[i,:,:]>0)[0]) for i in range(nuImgs-1)]


# plt.figure();plt.imshow(np.log10(adc2),cmap='gray',vmin=0,vmax=5)