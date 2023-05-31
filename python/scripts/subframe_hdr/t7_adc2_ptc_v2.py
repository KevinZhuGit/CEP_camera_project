import numpy as np
import matplotlib.pyplot as plt
import os,sys
import cv2
import time
import pandas as pd
from scipy.signal import butter, lfilter, freqz
from multiprocessing import Pool

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


def getFluxMeanyWeanie(comp_out,vref,t):
    [rows,cols,nusubs] = comp_out.shape
    comp_out = comp_out.reshape(-1,nusubs)
    pixN = comp_out.shape[0]

    comp_event = np.diff(comp_out,axis=1,prepend=0)

    comp_event_sub_mean = []
    L_calculated_mean = -np.ones([pixN,1000])

    for i in range(pixN):
        event_where = np.where(comp_event[i,:]>0)
        comp_event_sub_mean.append(event_where)
        n = np.asarray(event_where).flatten()
        nVals = len(n)
        if(nVals!=0):
            L_calculated_mean[i,:nVals] = vref[n]/t[n]

    least_count             = nuSubs/(2**16-1)
    adc2                    = np.asarray(np.mean(np.ma.masked_values(L_calculated_mean,-1),axis=1))
    adc2[adc2<=least_count] = least_count
    adc2[np.isinf(adc2)]    = least_count

    adc2      = adc2.reshape(rows,cols)
    adc2_mean = np.interp(adc2,(least_count,nuSubs),(1,2**16-1)).astype(np.uint16).reshape(rows,cols)

    comp_event = comp_event.reshape([rows,cols,-1])

    return {'adc2_uint16':adc2_mean,'adc2_raw':adc2,'L':L_calculated_mean,
            'comp_event':comp_event,'comp_event_sub':comp_event_sub_mean}

data_folders = { 1:['f1_65ms_0.48_3.6_60rows_ptc_v1_t6Exp000053Mask900/t6Exp000053Mask900','../f1_65ms_0.48_3.6.csv','f1'],
                 2:['f1_65ms_0.48_3.6_60rows_ptc_v1_t6Exp000058Mask900/t6Exp000058Mask900','../f1_65ms_0.48_3.6.csv','f1']
                 }

data_index          = 2
exposure_time       = 65.7e-3

current_data        = data_folders[data_index][0]
current_vref        = data_folders[data_index][1]
current_data_name   = data_folders[data_index][2]

nuSamples             = 500
REARRANGE_IMGS        = False
READ_VREF_CSV         = True
REREAD_IMGS           = False
CALCULATE_INTENSITY   = False
CREATE_EVENT_VIDEO    = False
CALCULATE_MEAN        = True
CALCULATE_VARIANCE    = True
PLOT_MEAN_VS_VARIANCE = True
CHECK_IF_VALID        = True


dataSample  = np.load(os.path.join('../../image/{}'.format(current_data),'subbyte_0014.npy'))
imgSample   = arrange_adc2(dataSample,rows=60)
[nuSubs, rows, cols] = imgSample.shape
allImgs     = np.zeros([nuSamples, nuSubs, rows, cols],dtype=np.bool)

badimgs = np.concatenate([
                np.arange(0,30),
                np.arange(410,420)
            ])
goodimgs = np.array([ 
        54,  55,  56,  57,  58,  59, 126, 127, 128, 129, 130, 170, 171,
        172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184,
        185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197,
        198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210,
        216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 230,
        231, 232, 233, 234, 253, 254, 255, 256, 257, 258, 259, 260, 261,
        264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276,
        277, 278, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291,
        292, 293, 294, 295, 298, 299, 300, 301, 302, 303, 304, 305, 306,
        307, 308, 309, 310, 311, 312, 315, 316, 317, 318, 319, 320, 321,
        322, 323, 324, 325, 326, 327, 332, 333, 334, 335, 336, 337, 338,
        339, 340, 341, 342, 343, 344, 345, 346, 349, 350, 351, 352, 353,
        354, 355, 356, 357, 358, 359, 360, 361, 366, 367, 368, 369, 370,
        371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 383, 384,
        385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 451, 452, 453,
        454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 468,
        486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498])


missedImgs = np.array([170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 191, 192, 197, 219, 220, 221, 226, 227, 228, 229, 233, 253, 254, 255, 256, 332, 333, 334, 335, 345, 346, 347, 348, 349])


tic = time.time()
if(REARRANGE_IMGS):
    global k
    k = 0
    def rearrange_img_mp(index_file):
        global k
        k = k+1
        print("Loading and arranging subimage {:04d}, {:04d} of {:04d} ".format(index_file,k,nuSamples),end='\r')    
        dataSample  = np.load(os.path.join('../../image/{}'.format(current_data),'subbyte_{:04d}.npy'.format(index_file)))
        imgSample   = arrange_adc2(bytearray(dataSample),rows=60).astype(np.bool)
        np.save(os.path.join('../../image/{}'.format(current_data),'subimg_{:04d}.npy'.format(index_file)),imgSample)

    with Pool(7) as p:
        p.map(rearrange_img_mp,range(nuSamples))

    # for i in range(nuSamples):
    #     print("Loading and arranging subimage {} of {}".format(i,nuSamples),end='\r')    
    #     dataSample = np.load(os.path.join('../../image/{}'.format(current_data),'subbyte_{:04d}.npy'.format(i)))
    #     imgSample   = arrange_adc2(bytearray(dataSample),rows=60).astype(np.bool)
    #     # allImgs[i,:] = imgSample
    #     np.save(os.path.join('../../image/{}'.format(current_data),'subimg_{:04d}.npy'.format(i)),imgSample)
    print("\nDone in {}".format(time.time()-tic));tic=time.time()



if(READ_VREF_CSV):
    print("Reading vref csv file")
    N = nuSubs
    t = np.linspace(0,1,N)
    vref_csv    = os.path.join("../../image/{}".format(current_data),current_vref)
    df          = pd.read_csv(vref_csv, sep=',', header=None, error_bad_lines=False)
    print("\nDone in {}".format(time.time()-tic));tic=time.time()
    print("getting data")
    vref_all    = df.values[20:-1].astype(float)
    print("\nDone in {}".format(time.time()-tic));tic=time.time()
    print("filtering data")
    # vref_all[:,1] = butter_lowpass_filter(vref_all[:,1],5e3,1e6,6)
    vref        = np.interp(t*exposure_time,vref_all[:,0],vref_all[:,1])
    vref        = np.interp(vref,[0,np.max(vref)],[1,0])
    print("\nDone in {}".format(time.time()-tic));tic=time.time()


if(REREAD_IMGS):
    k = 0
    def calculate_flux_mp(i):
        print("Re-Reading subimage {:04d}, {:04d} of {:04d}".format(i,k,nuSamples),end='\r')
        imgSample = np.load(os.path.join('../../image/{}'.format(current_data),'subimg_{:04d}.npy'.format(i)))
        # allImgs[i,:,:,:] = imgSample[:,:,:]
        # print("\nDone in {}".format(time.time()-tic));tic=time.time()

        if(CALCULATE_INTENSITY):
        # for i in range(nuSamples):
            # print("Calculating intensity {} of {}".format(i,nuSamples),end='\r')
            # comp_out = 1-np.moveaxis(allImgs[i,:],0,2)
            comp_out    = 1-np.moveaxis(imgSample,0,2)
            fluxMean    = getFluxMeanyWeanie(comp_out,vref,t)
            adc2        = fluxMean['adc2_raw']
            adc2_log    = np.interp(np.log10(fluxMean['adc2_uint16'])/np.log10(nuSubs),[0,1],[0,255]).astype(np.uint8)
            np.save(    os.path.join('../../image/{}'.format(current_data),     'flux_{:04d}.npy'.format(i)),       adc2)
            cv2.imwrite(os.path.join('../../image/{}'.format(current_data), 'flux_log_{:04d}.png'.format(i)),   adc2_log)

    with Pool(1) as p:
        p.map(calculate_flux_mp,missedImgs)

    # for i in range(0,nuSamples):
    #     print("Re-Reading subimage {} of {}".format(i,nuSamples),end='\r')
    #     imgSample = np.load(os.path.join('../../image/{}'.format(current_data),'subimg_{:04d}.npy'.format(i)))
    #     # allImgs[i,:,:,:] = imgSample[:,:,:]
    # # print("\nDone in {}".format(time.time()-tic));tic=time.time()

    #     if(CALCULATE_INTENSITY):
    #     # for i in range(nuSamples):
    #         print("Calculating intensity {} of {}".format(i,nuSamples),end='\r')
    #         # comp_out = 1-np.moveaxis(allImgs[i,:],0,2)
    #         comp_out = 1-np.moveaxis(imgSample,0,2)
    #         fluxMean = getFluxMeanyWeanie(comp_out,vref,t)
    #         adc2        = fluxMean['adc2_raw']
    #         adc2_log    = np.interp(np.log10(fluxMean['adc2_uint16'])/np.log10(nuSubs),[0,1],[0,255]).astype(np.uint8)
    #         np.save(    os.path.join('../../image/{}'.format(current_data),     'flux_{:04d}.npy'.format(i)),       adc2)
    #         cv2.imwrite(os.path.join('../../image/{}'.format(current_data), 'flux_log_{:04d}.png'.format(i)),   adc2_log)

    print("\nDone in {}".format(time.time()-tic));tic=time.time()

if(CHECK_IF_VALID):
    print("Checking if valid image")
    img_fom = np.zeros(nuSamples)
    valid = []
    window=10
    for i in range(2,nuSamples):
        current_file = os.path.join('../../image/{}'.format(current_data), 'flux_{:04d}.npy'.format(i))
        if(os.path.isfile(current_file)):
            img_i = np.load(current_file)        
            img_fom[i] = np.mean(img_i[17:35,350:450].flatten())
        else:
            print(i,end=' ')

            # if(img_fom[i]>np.mean())
        # img_fom[i] = np.min(img_i.flatten())
    # for i in range(nuSamples):

    plt.figure();plt.plot(img_fom)
    print("\nDone in {}".format(time.time()-tic));tic=time.time()

if(CALCULATE_MEAN):
    print("Calculating mean")
    img_sum = np.zeros([rows,cols])
    least_count = nuSubs/(2**16-1)
    n=0    
    for i in range(nuSamples):
        if i in badimgs: 
            continue 
        elif i in goodimgs:
            pass
        else:
            continue

        print("Re-Reading subimage {} of {}".format(i,nuSamples),end='\r')
        img_i = np.load(os.path.join('../../image/{}'.format(current_data), 'flux_{:04d}.npy'.format(i)))
        img_i = np.interp(img_i,(least_count,nuSubs),(1,2**16-1))
        img_sum += img_i
        n       += 1
    img_mean = img_sum / n
    np.save(os.path.join('../../image/{}/..'.format(current_data), 'mean_{:04d}.npy'.format(i)),img_mean)
    print("\nDone in {}".format(time.time()-tic));tic=time.time()

if(CALCULATE_VARIANCE):
    print("Calculating variance")
    img_sum  = np.zeros([rows,cols])
    img_mean = np.load(os.path.join('../../image/{}/..'.format(current_data), 'mean_{:04d}.npy'.format(i)))
    least_count = nuSubs/(2**16-1)

    n=0
    for i in range(nuSamples):
        if i in badimgs: 
            continue 
        elif i in goodimgs:
            pass
        else:
            continue
        print("Re-Reading subimage {} of {}".format(i,nuSamples),end='\r')
        img_i    = np.load(os.path.join('../../image/{}'.format(current_data), 'flux_{:04d}.npy'.format(i)))
        img_i = np.interp(img_i,(least_count,nuSubs),(1,2**16-1))
        img_sum += np.square(img_i-img_mean)
        n       += 1
    img_var = img_sum / n
    np.save(os.path.join('../../image/{}/..'.format(current_data), 'variance_{:04d}.npy'.format(i)),img_var)
    print("\nDone in {}".format(time.time()-tic));tic=time.time()

if(PLOT_MEAN_VS_VARIANCE):
    img_mean = np.load(os.path.join('../../image/{}/..'.format(current_data), 'mean_{:04d}.npy'.format(i)))
    img_var  = np.load(os.path.join('../../image/{}/..'.format(current_data), 'variance_{:04d}.npy'.format(i)))

    img_mean_all = img_mean[:,130:].flatten()
    img_var_all  =  img_var[:,130:].flatten()

    order = np.argsort(img_mean_all)
    # plt.scatter(img_mean_all[order],img_var_all[order])

    snr = 20*np.log10(img_mean_all/(img_var_all**0.5))
    plt.figure()
    plt.semilogx(img_mean_all[order],snr[order])
    print("\nDone in {}".format(time.time()-tic));tic=time.time()

if(CREATE_EVENT_VIDEO):
    comp_event = np.diff(comp_out,axis=-1,prepend=0)
    comp_event = comp_event#.reshape(rows,cols,-1)
    # comp_event = np.abs(comp_event)
    # comp_event[comp_event<0] = 0;


    font                   = cv2.FONT_HERSHEY_SIMPLEX
    bottomLeftCornerOfText = (10,50)
    fontScale              = 1
    fontColor              = (255,100,100)
    thickness              = 2
    lineType               = 2

    for i in range(nuSubs):
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
        # cv2.imwrite('data/{:03d}.png'.format(i),(img).astype(np.uint8))
        time.sleep(1/30)

    cv2.destroyAllWindows()

    # os.system("ffmpeg -framerate 10 -pattern_type glob -i 'data/*.png' \
    #             -c:v libx265 -r 30 -pix_fmt yuv420p t7_680x480_subframe_events_{}.mp4".format(current_data_name))




    print("\nDone in {}".format(time.time()-tic));tic=time.time()

print("\nDone in {}".format(time.time()-tic));tic=time.time()

# np.save(os.path.join('../../image/{}/..'.format(current_data),'all_subimg.npy'),allImgs)

sys.exit()


# exit()

comp_out = np.moveaxis(comp_out,0,2).reshape(-1,N)
pixN = comp_out.shape[0]

comp_event = np.diff(comp_out,axis=1,prepend=0)

comp_event_sub_mean    = []
L_calculated_mean = -np.ones([pixN,50])
if(0):
    for i in range(pixN):
        comp_event_sub_mean.apped(np.where(comp_event[i,:]>0))
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




    nuEvent = [len(np.where(comp_event[i,:,:]>0)[0]) for i in range(nuImgs-1)]


# plt.figure();plt.imshow(np.log10(adc2),cmap='gray',vmin=0,vmax=5)