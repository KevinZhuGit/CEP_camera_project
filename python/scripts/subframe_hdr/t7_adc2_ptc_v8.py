# from multiprocessing import set_start_method
# set_start_method("spawn")

import numpy as np
import matplotlib.pyplot as plt
import os,sys
import cv2
import time
import pandas as pd
from scipy.signal import butter, lfilter, freqz
import glob

from multiprocessing import Pool
# from multiprocessing import get_context
from multiprocessing import Process

np.seterr(divide='ignore') # ignore divide by zero



#mergeMertens = cv2.createMergeMertens()
#mergeMertens.setContrastWeight(1)
#mergeMertens.setContrastWeight(1)
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
    if(len(comp_out.shape)==2):
        [pixN,nuSubs] = comp_out.shape
        rows = 1
        cols = pixN
    else:
        [rows,cols,nusubs] = comp_out.shape
        comp_out    = comp_out.reshape(-1,nusubs)
        pixN        = comp_out.shape[0]

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

data_folders = { 
                1:['/nobackup/rahulgulve/Project/T7/20220828/f1_65ms_0.48_4.1_60rows_ptc_v3_t6Exp000058Mask900_PTC_baby/t6Exp000058Mask900_PTC_baby',
                    '../f1_65ms_0.48_3.6.csv', 'f1', 'subbyte_x20_N_870_led_{}.npz'],
                2:['/nobackup/rahulgulve/Project/T7/20220828/f1_65ms_0.48_4.1_60rows_ptc_v3_t6Exp000058Mask900_PTC/t6Exp000058Mask900_PTC',
                    '../f1_65ms_0.48_3.6.csv', 'f1', 'subbyte_x200_N_870_led_{:04d}.npz'],
                3:['/nobackup/rahulgulve/Project/T7/20220830/f1_0.4_3.6_t6Exp000060Mask900_PTC/f1_t6Exp000060Mask900_PTC',
                    '../f1_65ms_0.48_3.6.csv', 'f1','subbyte_x200_N_870_{}.npz',16],
                4:['/nobackup/RahulGulve/Home/Documents/Project/CameraSystems/ptc/f1_0.4_3.6_t6Exp000060Mask900_PTC/f1_t6Exp000060Mask900_PTC',
                    '../f1_68.4ms_0.2_3.8.csv', 'f1','subbyte_x200_N_870_{}.npz',6],
                5:['../../image/20220831_f1_68.4_0.8_3.7/t6Exp000060Mask900_PTC',
                    '../f1_68.4ms_0.2_3.8.csv', 'f1','subbyte_x2000_N_870_{}.npz',6],
                 }
TLEDOnList        = np.concatenate([np.linspace(1,10,10,    dtype=int),
                                   np.logspace(1,4,91, dtype=int)])

data_index          = 5

exposure_time       = 68.4e-3 * 68.4/67


data_folder         = os.path.join(data_folders[data_index][0])
vref_file           = os.path.join(data_folder  ,data_folders[data_index][1])
data_name           = data_folders[data_index][2]
file_format         = data_folders[data_index][3]
nuCores             = data_folders[data_index][4]

allFiles            = [f.split('/')[-1] for f in glob.glob(os.path.join(data_folder,file_format.format('*')))]
allFiles.sort()


if(len(allFiles)==0):
    print("Could not find correct files")
    sys.exit()

subbyte_file        = os.path.join(data_folder,'subbyte_{}.npz')
subimg_file         = os.path.join(data_folder,'subimage_{}_{}.npz')
flux_file           = os.path.join(data_folder,'flux_{}_{:04d}.npz')
flux_log_file       = os.path.join(data_folder,'flux_log_{}_{:04d}.png')

mean_file           = os.path.join(data_folder,'../mean_{}.npz')
var_file            = os.path.join(data_folder,'../variance_{}.npz')
meanDN_file         = os.path.join(data_folder,'../meanDN_{}.npz')
varDN_file          = os.path.join(data_folder,'../varianceDN_{}.npz')

badimgs_file        = os.path.join(data_folder,'badimg.npy')

all_mean_file       = os.path.join(data_folder,'../all_mean.npz')
all_var_file        = os.path.join(data_folder,'../all_var.npz')

all_meanDN_file     = os.path.join(data_folder,'../all_meanDN.npz')
all_varDN_file      = os.path.join(data_folder,'../all_varDN.npz')

valid_pixels_file   = os.path.join(data_folder,'../valid_pixels.npy')


goodpixels = np.zeros((60,680),dtype=np.bool)
goodpixels[::int((60-4)/12),::int((680-30)/17/2/1.5)] = True
goodpixels[:,:]             = True
goodpixels[[0,1,2,3,-1],:]  = False
goodpixels[:,:30]           = False
goodpixels[:,80:120]        = False
goodpixels[:,440:480]       = False
Npix                        = len(np.where(goodpixels.flatten())[0])
# goodpixels[:33,327:364]     = False


REARRANGE_IMGS        = False
READ_VREF_CSV         = False
CALCULATE_INTENSITY   = False
CREATE_EVENT_VIDEO    = False
CALCULATE_MEAN        = False
CALCULATE_VARIANCE    = False
COMBINE_MEAN_VAR      = False

CALCULATE_MEAN_VAR_UINT = False
COMBINE_MEAN_VAR_UINT = True

PLOT_MEAN_VS_VARIANCE = True
CHECK_IF_VALID        = False




if __name__ == '__main__':

    nuIntensities           = len(allFiles)
    nuSubs                  = 870
    nuSamples               = 2000
    if(REARRANGE_IMGS | CALCULATE_INTENSITY | CALCULATE_MEAN | CALCULATE_VARIANCE):
        subByteArrayFile        = os.path.join(data_folder,allFiles[0])
        f_subByteArray          = np.load(subByteArrayFile)
        subByteArray            = f_subByteArray['img'] 

        dataSample              = subByteArray[-1]
        compOutSample           = arrange_adc2(bytearray(dataSample),rows=60)

        nuSamples               = subByteArray.shape[0]
        [nuSubs, rows, cols]    = compOutSample.shape

        # allImgs                 = np.zeros([nuIntensities, nuSubs, rows, cols],dtype=np.bool)


        badimgs     = np.concatenate([[]])
        goodimgs    = np.array([np.arange(nuIntensities)])
        missedImgs  = np.array([])


    tic = time.time()
    if(REARRANGE_IMGS):

        for l in range(0,nuIntensities):
            f = allFiles[l]
            print("rearranging images for led intensity {}".format(f))
            subByteArrayFile        = os.path.join(data_folder,allFiles[l])
            f_subByteArray          = np.load(subByteArrayFile)
            subByteArray            = f_subByteArray['img']

            def rearrange_img_mp(index_file):
                save_file = os.path.join(data_folder,'subimage_{}_{}.npz'.format(f[8:-4],index_file))
                if(os.path.isfile(save_file)):
                    print("This exists already {:04d}".format(index_file))
                    return 0
                else:
                    print("Loading and arranging subimage {:04d} of {:04d} ".format(index_file,nuSamples),end='\r')    
                    dataSample  = subByteArray[index_file]
                    imgSample   = arrange_adc2(bytearray(dataSample),rows=60).astype(np.bool)
                    np.savez_compressed(save_file,comp_out=imgSample)

            with Pool(nuCores) as p:
                # p.map(rearrange_img_mp,range(nuSamples))
                p.map(rearrange_img_mp,range(nuCores))
        
            print("\nDone in {}".format(time.time()-tic));tic=time.time()




    if(READ_VREF_CSV):
        print("Reading vref csv file")
        N = nuSubs
        t = np.linspace(0,1,N)
        vref_csv    = vref_file
        df          = pd.read_csv(vref_csv, sep=',', header=None, error_bad_lines=False)
        print("\nDone in {}".format(time.time()-tic));tic=time.time()
        print("getting data")
        vref_all    = df.values[20:-1].astype(float)
        print("\nDone in {}".format(time.time()-tic));tic=time.time()
        print("filtering data")
        vref_all[:,1] = butter_lowpass_filter(vref_all[:,1],5e3,1e6,6)
        vref        = np.interp(t*exposure_time,vref_all[:,0],vref_all[:,1])
        # vref        = np.interp(vref,[0,np.max(vref)],[1,0])
        vref        = np.interp(vref,[np.min(vref),np.max(vref)],[1,0])
        print("\nDone in {}".format(time.time()-tic));tic=time.time()


    if(CALCULATE_INTENSITY):
        for l in range(nuIntensities):
            f = allFiles[l]
            print("Calculating intensity images for file {} {}".format(l, f))

            def calculate_flux_mp(i):
                read_file     = subimg_file.format(f[8:-4],i)
                save_file_npz = flux_file.format(f[8:-4],i)
                save_file_png = flux_log_file.format(f[8:-4],i)

                if(os.path.isfile(save_file_npz)):
                    print("this file already exists {}".format(i),end="\r")
                    return 0

                print("Re-Reading subimage {:04d} of {:04d}".format(i,nuSamples),end='\r')
                f_imgSample = np.load(read_file)
                imgSample   = f_imgSample['comp_out']


                least_count = nuSubs/(2**16-1)  
                comp_out    = 1-np.moveaxis(imgSample,0,2)

                comp_out    = comp_out[goodpixels,:]


                fluxMean    = getFluxMeanyWeanie(comp_out,vref,t)
                adc2        = fluxMean['adc2_raw']
                adc2_log    = np.interp(np.log10(adc2),[np.log10(least_count),np.log10(nuSubs)],[0,255]).astype(np.uint8)
                np.savez_compressed(save_file_npz, adc2=adc2)
                cv2.imwrite(save_file_png,   adc2_log)
                return 1



            procs = []

            # for i in range(nuCores):
            for i in range(nuSamples):
                setNew=False
                if(len(procs)!=nuCores):
                    p = Process(target=calculate_flux_mp,args=(i,))
                    procs.append(p)
                    procs[i].start()
                else:
                    while(1):
                        for pi in range(nuCores):
                            if procs[pi].is_alive():
                                pass
                            else:
                                procs[pi] = Process(target=calculate_flux_mp,args=(i,))
                                procs[pi].start()
                                setNew=True
                                break
                        if(setNew):
                            break

            # make sure all the jobs are finished before moving forwards
            for pi in range(nuCores):
                procs[pi].join()



#            with Pool(6) as p:
            # with get_context("spawn").Pool(6) as p:
#                p.map(calculate_flux_mp,range(nuSamples))
            

            print("\nDone in {}".format(time.time()-tic));tic=time.time()

    # sys.exit()

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

        plt.figure();plt.plot(img_fom)
        print("\nDone in {}".format(time.time()-tic));tic=time.time()

    if(CALCULATE_MEAN):
        for l in range(nuIntensities):
            f = allFiles[l]
            print("Calculating mean image for file {} {}".format(l, f))
    
            img_sum = np.zeros(Npix)
            least_count = nuSubs/(2**16-1)
            n=0    
            for i in range(nuSamples):
    
                # if i in badimgs: 
                #     continue 
                # elif i in goodimgs:
                #     pass
                # else:
                #     continue

                read_file_npz = flux_file.format(f[8:-4],i)

                if(os.path.isfile(read_file_npz)):
                    print("Re-Reading subimage {} of {}".format(i,nuSamples),end='\r')
                    img_i_f     = np.load(read_file_npz)        
                    img_i       = img_i_f['adc2']
                else:
                    print(i)
                    continue

                img_sum += img_i.flatten()
                n       += 1

            img_mean = img_sum / n
            save_file_npz = mean_file.format(f[8:-4])
            np.savez_compressed(save_file_npz,mean=img_mean)
            print("\nDone in {}".format(time.time()-tic));tic=time.time()

    if(CALCULATE_VARIANCE):
        for l in range(nuIntensities):
            f = allFiles[l]
            print("Calculating mean image for file {} {}".format(l, f))
    
            img_sum     = np.zeros(Npix)
            img_mean_f  = np.load(mean_file.format(f[8:-4]))
            img_mean    = img_mean_f['mean']
            n=0    
            for i in range(nuSamples):
                read_file_npz = flux_file.format(f[8:-4],i)

                if(os.path.isfile(read_file_npz)):
                    print("Re-Reading subimage {} of {}".format(i,nuSamples),end='\r')
                    img_i_f     = np.load(read_file_npz)        
                    img_i       = img_i_f['adc2']
                else:
                    print(i)

                img_sum += np.square(img_i.flatten()-img_mean)
                n       += 1

            img_var = img_sum / n
            np.savez_compressed(var_file.format(f[8:-4]),var=img_var)

            print("\nDone in {}".format(time.time()-tic));tic=time.time()

    if(CALCULATE_MEAN_VAR_UINT):
        for l in range(nuIntensities):
            f = allFiles[l]
            print("Calculating mean image for file {} {}".format(l, f))
    
            img_sum = np.zeros(Npix)
            least_count = nuSubs/(2**16-1)
            n=0    
            for i in range(10,nuSamples):
                read_file_npz = flux_file.format(f[8:-4],i)

                if(os.path.isfile(read_file_npz)):
                    print("Re-Reading subimage {} of {}".format(i,nuSamples),end='\r')
                    img_i_f     = np.load(read_file_npz)        
                    img_i       = img_i_f['adc2']
                else:
                    print(i)
                    continue

                img_i = np.interp(img_i,[0,nuSubs],[0,2**16-1]).astype(np.uint16)

                img_sum += img_i.flatten()
                n       += 1

            img_mean = img_sum / n
            save_file_npz = meanDN_file.format(f[8:-4])
            np.savez_compressed(save_file_npz,mean=img_mean)
            print("\nDone in {}".format(time.time()-tic));tic=time.time()


            img_sum     = np.zeros(Npix)
            img_mean_f  = np.load(meanDN_file.format(f[8:-4]))
            img_mean    = img_mean_f['mean']
            n=0    
            for i in range(nuSamples):
                read_file_npz = flux_file.format(f[8:-4],i)

                if(os.path.isfile(read_file_npz)):
                    print("Re-Reading subimage {} of {}".format(i,nuSamples),end='\r')
                    img_i_f     = np.load(read_file_npz)        
                    img_i       = img_i_f['adc2']
                else:
                    print(i)

                img_i = np.interp(img_i,[0,nuSubs],[0,2**16-1]).astype(np.uint16)

                img_sum += np.square(img_i.flatten()-img_mean)
                n       += 1

            img_var = img_sum / n
            np.savez_compressed(varDN_file.format(f[8:-4]),var=img_var)


    if(COMBINE_MEAN_VAR):
        img_mean_all = np.zeros((nuIntensities, Npix))
        img_var_all  = np.zeros((nuIntensities, Npix))
        for l in range(nuIntensities):
            f = allFiles[l]
            img_mean_f  = np.load(mean_file.format(f[8:-4]))
            img_mean    = img_mean_f['mean']
            img_var_f  = np.load(var_file.format(f[8:-4]))
            img_var    = img_var_f['var']

            img_mean_all[l,:,] = img_mean
            img_var_all[l,:,] = img_var


        np.savez_compressed(all_mean_file, mean=img_mean_all)
        np.savez_compressed(all_var_file,  var =img_var_all)


    if(COMBINE_MEAN_VAR_UINT):
        img_mean_all = np.zeros((nuIntensities, Npix))
        img_var_all  = np.zeros((nuIntensities, Npix))
        for l in range(nuIntensities):
            f = allFiles[l]
            img_mean_f  = np.load(meanDN_file.format(f[8:-4]))
            img_mean    = img_mean_f['mean']
            img_var_f  = np.load(varDN_file.format(f[8:-4]))
            img_var    = img_var_f['var']

            img_mean_all[l,:,] = img_mean
            img_var_all[l,:,] = img_var


        np.savez_compressed(all_meanDN_file, mean=img_mean_all)
        np.savez_compressed(all_varDN_file,  var =img_var_all)

    if(PLOT_MEAN_VS_VARIANCE):
        img_mean_f = np.load(all_mean_file)
        img_var_f  = np.load(all_var_file)
        img_meanDN_f = np.load(all_meanDN_file)
        img_varDN_f  = np.load(all_varDN_file)

        img_mean1   = img_mean_f['mean']
        img_var1    = img_var_f['var']
        img_mean2   = img_meanDN_f['mean']
        img_var2    = img_varDN_f['var']


        img_mean_all = img_mean2.flatten()
        img_var_all  =  img_var2.flatten()
        order = np.argsort(img_mean_all)
        img_mean_all = img_mean_all[order]
        img_var_all  = img_var_all[order]


        # mean_ranges = [0,     220,   800,  847,  860, 1000]
        # valid_var    = [480, 48000, 26160, 9240, 4050]
        # valid_pixels = np.zeros(Npix,dtype=np.bool)
        # for i in range(len(valid_var)):
        #     new_range = np.logical_and(img_mean_all>= mean_ranges[i], img_mean_all<=mean_ranges[i+1])
        #     new_valid_pixels = np.logical_and(new_range,img_var_all<valid_var[i])
        #     valid_pixels = np.logical_or(valid_pixels,new_valid_pixels)
        valid_pixels = np.load(valid_pixels_file)
        # plt.scatter(img_mean_all[order],img_var_all[order])

        snr = 20*np.log10(img_mean_all/(img_var_all**0.5))
        cks = 11 # convolve_kernel_size
        snr_average = np.convolve(snr[valid_pixels],np.ones(cks))[int(cks//2):-int(cks//2)]/cks

        plt.figure();plt.clf()
        plt.semilogx(img_mean_all[valid_pixels],snr[valid_pixels])
        plt.semilogx(img_mean_all[valid_pixels],snr_average,)
        plt.ylim([0,50])
        plt.show()
        print("\nDone in {}".format(time.time()-tic));tic=time.time()

    sys.exit()

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
        #             L_esti = vref[n] / t[n]
        #         else:
        #             L_esti = 0

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
