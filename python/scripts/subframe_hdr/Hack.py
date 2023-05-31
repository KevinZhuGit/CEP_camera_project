from pickletools import uint8
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

def getFluxMeanyWeanie(comp_out,vref,t,Hack):
    if(len(comp_out.shape)==2):
        [pixN,nuSubs] = comp_out.shape
        rows = 1
        cols = pixN
    else:
        [rows,cols,nusubs] = comp_out.shape
        comp_out    = comp_out.reshape(-1,nusubs)
        pixN        = comp_out.shape[0]
    
    comp_event = np.diff(comp_out,axis=1,prepend=0,append=0)
    if (Hack):
        comp_event[:,160:235] = 0
        comp_event[:,407:453] = 0
        comp_event[:,640:670] = 0   
        comp_event[:,866:870] = 0 

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

def getFluxRegBeg(comp_out,vref,t,Hack):
    if(len(comp_out.shape)==2):
        [pixN,nuSubs] = comp_out.shape
        rows = 1
        cols = pixN
    else:
        [rows,cols,nusubs] = comp_out.shape
        comp_out    = comp_out.reshape(-1,nusubs)
        pixN        = comp_out.shape[0]

    comp_event = np.diff(comp_out,axis=1,prepend=0)
    if (Hack):

        comp_event[:,160:235] = 0
        comp_event[:,407:453] = 0
        comp_event[:,640:670] = 0   
        comp_event[:,866:870] = 0 

    comp_event_sub  = []
    L_calculated = -np.ones([pixN,50])
    for i in range(pixN):
        event_where = np.where(comp_event[i,:]>0)
        comp_event_sub.append(event_where)
        n = np.asarray(event_where).flatten()
        n_before = np.asarray(event_where).flatten() - 1
        nVals = len(n)


        #Regression general line
        # if nVals > 1 :
        #   ys = (vref[n] + vref[n_before])/ 2
        #   xs = (t[n] + t[n_before]) / 2

        #   coeffs = np.polyfit(xs, ys, 1)
        #   L_esti = coeffs[0]

        # else:
        #   if t[n] > 0:
        #       L_esti = vref[n] / t[n]
        #   else:
        #       L_esti = 0


        # L_calculated[i,:nVals] = L_esti


        if nVals > 1:
            ys = (vref[n] + vref[n_before]) / 2
            xs = (t[n] + t[n_before]) / 2

            L_esti = np.sum(ys*xs) / np.sum(xs**2)

            # This was trying to penalize lines that dont go through mid
            #  points but it did not show much difference
            L_esti = np.sum(vref[n] * t[n] + vref[n_before]*t[n_before])/np.sum(t[n]**2 + t[n_before]**2)


        else:
            if t[n] > 0:
                L_esti = vref[n] / t[n]
            else:
                L_esti = 0

        L_calculated[i, :nVals] = L_esti        



    least_count             = nuSubs/(2**16-1)
    adc2                    = np.asarray(np.mean(np.ma.masked_values(L_calculated,-1),axis=1))
    adc2[adc2<=least_count] = least_count
    adc2[np.isinf(adc2)]    = least_count

    adc2            = adc2.reshape(rows,cols)
    adc2_regression = np.interp(adc2,(least_count,nuSubs),(1,2**16-1)).astype(np.uint16).reshape(rows,cols)
    comp_event = comp_event.reshape([rows,cols,-1])



    return {'adc2_uint16':adc2_regression,'adc2_raw':adc2,'L':L_calculated,
            'comp_event':comp_event,'comp_event_sub':comp_event_sub}

def get_vref_ideal(nuSubs=1000,type='HALF_SIN',f=1,noisy=False,mu=0,NF=8):
    N = nuSubs
    t = np.linspace(0,1,N)
    if(noisy):
        vref_noise_mu      = 0
        vref_noise_sigma   = 1/2**(NF)
        vref_noise = np.random.normal(self.vref_noise_mu, self.vref_noise_sigma,N)
    else:
        vref_noise_mu      = 0
        vref_noise_sigma   = 0
        vref_noise = np.zeros(N)

    if(type=='SIN'):
        vref =  -np.sin(np.pi*(t*2*f-0.5))*0.5+0.5
    elif(type=='RAMP'):
        vref =  1-t
    elif(type=='CONST'):
        vref =  np.ones(len(t))*0.5
    elif(type=='OVER1'):
        vref =  1/(2-t)
    elif(type=='QUADRATIC'):
        vref =  6.75*t*(1-t)**2
    elif(type=='EQUI-ANGLE'):
        vref =  t*np.tan(np.pi/2*(1-t))
    elif(type=='CONVENTIONAL'):
        vref =  1/(0*t)
    elif(type=='HALF_SIN'):
        vref = np.zeros(N)
        step_size = int(N//f)
        total_steps = N//step_size + 1
        for i in range(total_steps):
            x1,x2  = i*step_size,min((i+1)*step_size,N)
            vref[x1:x2] = -np.sin(np.pi*(t[x1:x2]*f-0.5))*0.5+0.5
            if(i%2==1):
                vref[x1:x2] = 1 - vref[x1:x2]
        vref[1:] = vref[0:-1]
    vref = vref + vref_noise
    return {'t': t, 'vref':vref}

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

def imwrite_autoscale(filename, image, low=2,high=98):
    low, high     = np.percentile(image,[low,high])
    image = np.interp(image,[low,high],[0,255]).astype(np.uint8)
    cv2.imwrite(filename,image)


input_path_f4 = "./dataDir/20220906_f4_0.8_3.7_vrst_3v_17.1ms"
InputFile_f4 = '{}/Image_01.npy'.format(input_path_f4)
output_path_f4 = "./dataDir/20220906_f4_0.8_3.7_vrst_3v_17.1ms/Image_"

input_path_f4 = "./dataDir/20220907/F4"
InputFile_f4 = '{}/Image_01_f4.npy'.format(input_path_f4)
output_path_f4 = "./dataDir/20220907/F4/Image_"

input_path_f1 = "./dataDir/20220906_f1_0.8_3.7_vrst_3v_68ms"
InputFile_f1 = '{}/Image_01.npy'.format(input_path_f1)
output_path_f1 = "./dataDir/20220906_f1_0.8_3.7_vrst_3v_68ms/Image_"

PROCESS_F4  =True
PROCESS_F1  =False
STITCH_F1   =False
STITCH_F4   =False


if (PROCESS_F4):
    imgSample       = np.load(InputFile_f4).astype(float)
    comp_out        =np.moveaxis(imgSample,0,2)

    [rows,cols,nusubs]  = comp_out.shape
    nuSubs=nusubs
    comp_out    = comp_out.reshape(-1,nusubs)
    pixN        = comp_out.shape[0]

    comp_event = np.diff(comp_out,axis=1,prepend=0,append=0)
    # print(comp_event[238158,:])

    vref_all    = get_vref_ideal(nuSubs=nusubs,f=4)
    t           = vref_all['t']

    t[0:-1]     = t[1:nusubs]
    vref        = vref_all['vref']
    vref        = vref+0.05
    # tt =np.linspace(0,870,871)
    # plt.plot(t*870,vref,color='black')
    # plt.plot(tt,comp_event[191746,:],color='blue')  #238158  255869
    # plt.show()

    print('Processing mean F4')
    fluxMean    = getFluxMeanyWeanie(comp_out,vref,t,Hack=True)
    least_count = nusubs/(2**16-1) 
    adc2        = fluxMean['adc2_raw']
    adc2_log    = np.interp(np.log10(adc2),[np.log10(least_count),np.log10(nuSubs)],[0,255]).astype(np.uint8)
    # print(adc2_log.shape)
    adc2_new    = np.reshape(adc2_log,(imgSample.shape[1],imgSample.shape[2]))
    plt.title('Mean F4')
    plt.imshow(adc2_new)
    plt.show()

    cv2.imwrite(output_path_f4+'Mean.png', (adc2_new[:,30:670]))
    np.save(output_path_f4+'Mean.npy', adc2_new)

    print('Processing regression F4')
    fluxRegr          = getFluxRegBeg(comp_out,vref,t,Hack=True)
    adc_regr          = fluxRegr['adc2_raw'].reshape(imgSample.shape[1],imgSample.shape[2])
    adc2_log_regr     = np.interp(np.log10(adc_regr),[np.log10(least_count),np.log10(nuSubs)],[0,255]).astype(np.uint8)
    adc2_new_regr     = np.reshape(adc2_log_regr,(imgSample.shape[1],imgSample.shape[2]))

    # adc2_new_regr[bad_pixel]=255
    
    plt.title('Regression F4')
    plt.imshow(adc2_new_regr)
    plt.show()
    cv2.imwrite(output_path_f4+'Regr.png', (adc2_new_regr[:,30:670]))
    np.save(output_path_f4+'Regr.npy', adc2_new_regr)
    np.save(output_path_f4+'Regr_raw.npy',adc_regr[:,30:670])

    # IMAGE SNIPPET
    r1=286
    c1=85
    r2=460
    c2=254

    r11=181
    c11=461
    r22=355
    c22=635

    plt.title('Minion snippet Mean F4')
    plt.imshow(adc2_new[r1:r2,c1:c2])
    plt.show()

    plt.title('Bulb snippet Mean F4')
    plt.imshow(adc2_new[r11:r22,c11:c22])
    plt.show()

    plt.title('Minion snippet Regression F4')
    plt.imshow(adc2_new_regr[r1:r2,c1:c2])
    plt.show()

    plt.title('Bulb snippet Regression F4')
    plt.imshow(adc2_new_regr[r11:r22,c11:c22])
    plt.show()

    print('Saving snippets')
    # cv2.imwrite(output_path_f4+'Regr_inset_minion.png', (adc2_new[r1:r2,c1:c2]))
    # cv2.imwrite(output_path_f4+'Regr_inset_bulb.png', (adc2_new[r11:r22,c11:c22]))
    # cv2.imwrite(output_path_f4+'Regr_inset_minion.png', (adc2_new_regr[r1:r2,c1:c2]))
    # cv2.imwrite(output_path_f4+'Regr_inset_bulb.png', (adc2_new_regr[r11:r22,c11:c22]))
    imwrite_autoscale(output_path_f4+'Mean_inset_minion.png',   (adc2_new[r1:r2,c1:c2]))
    imwrite_autoscale(output_path_f4+'Mean_inset_bulb.png',     (adc2_new[r11:r22,c11:c22]))
    imwrite_autoscale(output_path_f4+'Regr_inset_minion.png',   (adc2_new_regr[r1:r2,c1:c2]))
    imwrite_autoscale(output_path_f4+'Regr_inset_bulb.png',     (adc2_new_regr[r11:r22,c11:c22]))

    [nuSubs,rows,cols]  =imgSample.shape
    cmap_heat = plt.get_cmap('inferno')


    sub_start=0
    for i in range(4):
        if i<3:
            img_combined = np.zeros((rows,cols),dtype=np.uint8)
            subframe_incrmnt = 220
            img_temp=imgSample[sub_start:sub_start+subframe_incrmnt,:,:]
            img_combined = np.mean(img_temp,axis=0)
            img = cmap_heat(img_combined)
            sub_start=sub_start+subframe_incrmnt
            plt.imshow(img)
            plt.show()
            output_path1 = output_path_f4+'{:1d}'.format(i)
            cv2.imwrite(output_path1+'_220.png', (255*cmap_heat(img_combined[:,30:670])[:,:,[2,1,0]]))
        else:
            img_combined = np.zeros((rows,cols),dtype=np.uint8)
            subframe_incrmnt = 210
            img_temp=imgSample[sub_start:sub_start+subframe_incrmnt,:,:]
            img_combined = np.mean(img_temp,axis=0)
            img = cmap_heat(img_combined)
            sub_start=sub_start+subframe_incrmnt
            plt.imshow(img)
            plt.show()
            output_path1 = output_path_f4+'{:1d}'.format(i)
            cv2.imwrite(output_path1+'_220.png', (255*cmap_heat(img_combined[:,30:670])[:,:,[2,1,0]]))
            print('saved 4 Sum image')


if (PROCESS_F1):
    imgSample       = np.load(InputFile_f1).astype(float)
    cmap_heat = plt.get_cmap('inferno')
    cv2.imwrite(output_path_f1+'subframe_heat.png',(255*cmap_heat(np.mean(imgSample[:,:,30:670],axis=0))[:,:,[2,1,0]]).astype(np.uint))


    comp_out        =np.moveaxis(imgSample,0,2)
    [rows,cols,nusubs]  = comp_out.shape

    nuSubs=nusubs
    comp_out    = comp_out.reshape(-1,nusubs)
    pixN        = comp_out.shape[0]
    # print(comp_out.shape)
    comp_event = np.diff(comp_out,axis=1,prepend=0,append=0)


    vref_all    = get_vref_ideal(nuSubs=nusubs,f=1)
    t           = vref_all['t']

    t[0:-1]     = t[1:nusubs]
    vref        = vref_all['vref']

    print('Processing Mean F1')
    fluxMean    = getFluxMeanyWeanie(comp_out,vref,t,Hack=False)
    least_count = nusubs/(2**16-1) 
    adc2        = fluxMean['adc2_raw']
    adc2_log    = np.interp(np.log10(adc2),[np.log10(least_count),np.log10(nuSubs)],[0,255]).astype(np.uint8)
    # print(adc2_log.shape)
    adc2_new    = np.reshape(adc2_log,(imgSample.shape[1],imgSample.shape[2]))
    plt.title('Mean F1')
    plt.imshow(adc2_new)
    plt.show()

 
    cv2.imwrite(output_path_f1+'Mean.png', (adc2_new[:,30:670]))
    np.save(output_path_f1+'Mean.npy', adc2_new)

    print('Processing regression F1')
    fluxRegr          = getFluxRegBeg(comp_out,vref,t,Hack=False)
    adc_regr          = fluxRegr['adc2_raw']
    adc2_log_regr     = np.interp(np.log10(adc_regr),[np.log10(least_count),np.log10(nuSubs)],[0,255]).astype(np.uint8)
    adc2_new_regr     = np.reshape(adc2_log_regr,(imgSample.shape[1],imgSample.shape[2]))
    # adc2_new_regr[bad_pixel]=255
    plt.title('Regression F1')
    plt.imshow(adc2_new_regr)
    plt.show()
    cv2.imwrite(output_path_f1+'Regr.png', (adc2_new_regr[:,30:670]))
    np.save(output_path_f1+'Regr.npy', adc2_new_regr)

    # IMAGE SNIPPET
    r1=270
    c1=370
    r2=460
    c2=560

    r11=245
    c11=125
    r22=435
    c22=315

    plt.title('Minion snippet Mean F1')
    plt.imshow(adc2_new[r1:r2,c1:c2])
    plt.show()

    plt.title('Bulb snippet Mean F1')
    plt.imshow(adc2_new[r11:r22,c11:c22])
    plt.show()

    plt.title('Minion snippet Regression F1')
    plt.imshow(adc2_new_regr[r1:r2,c1:c2])
    plt.show()

    plt.title('Bulb snippet Regression F1')
    plt.imshow(adc2_new_regr[r11:r22,c11:c22])
    plt.show()

    print('Saving snippets')

    imwrite_autoscale(output_path_f1+'Mean_inset_minion.png', adc2_new[r1:r2,c1:c2])
    imwrite_autoscale(output_path_f1+'Mean_inset_bulb.png', (adc2_new[r11:r22,c11:c22]))
    imwrite_autoscale(output_path_f1+'Regr_inset_minion.png', (adc2_new_regr[r1:r2,c1:c2]))
    imwrite_autoscale(output_path_f1+'Regr_inset_bulb.png', (adc2_new_regr[r11:r22,c11:c22]))


if (STITCH_F1):
    width = 680
    height = 480
    image_00= np.zeros((870,height,width),dtype=np.bool)
    image_snippet_00 = np.zeros((870,60,680),dtype=np.bool)
    image_01= np.zeros((870,height,width),dtype=np.bool)
    image_snippet_01 = np.zeros((870,60,680),dtype=np.bool)
    #image= []
    row_start = 0
    row_increment = 50


    for i in range(12):
        # print(i)
        print('Rearranging row segment {:2d}'.format(i),end='\r')
        InputFile_00 = '{}/{:02d}_00/subbyte_0005'.format(input_path_f1, i)
        InputFile_01 = '{}/{:02d}_01/subbyte_0005'.format(input_path_f1, i)
        data_00 = bytearray(np.load(InputFile_00+'.npy'))
        data_01 = bytearray(np.load(InputFile_01+'.npy'))
        comp_out_00 = 1-arrange_adc2(data_00).astype(float)
        comp_out_01 = 1-arrange_adc2(data_01).astype(float)
 

        image_snippet_00 = comp_out_00
        image_snippet_01 = comp_out_01


    
    

        if i==0:
            # print(row_start)
            image_00[:,row_start:(row_start + 50),::2]  = image_snippet_00[:,0:50,::2]
            image_00[:,row_start:(row_start + 50),1::2] = image_snippet_01[:,0:50,::2]
            image_01[:,row_start:(row_start + 50),1::2] = image_snippet_00[:,0:50,1::2]
            image_01[:,row_start:(row_start + 50),0::2] = image_snippet_01[:,0:50,1::2]
            row_start += 50
            
        if i<11 and i>0:
            # print(row_start)
        
            image_00[:,row_start:(row_start + 40),::2]  = image_snippet_00[:,10:50,::2]
            image_00[:,row_start:(row_start + 40),1::2] = image_snippet_01[:,10:50,::2]
            image_01[:,row_start:(row_start + 40),1::2] = image_snippet_00[:,10:50,1::2]
            image_01[:,row_start:(row_start + 40),0::2] = image_snippet_01[:,10:50,1::2]
            row_start += 40
        if i >=11:
            # print(row_start)
        
            image_00[:,row_start:(row_start + 30),::2]  = image_snippet_00[:,10:40,::2]
            image_00[:,row_start:(row_start + 30),1::2] = image_snippet_01[:,10:40,::2]
            image_01[:,row_start:(row_start + 30),1::2] = image_snippet_00[:,10:40,1::2]
            image_01[:,row_start:(row_start + 30),0::2] = image_snippet_01[:,10:40,1::2]
            row_start += 30

    
    
    





    # cv2.imshow('final',image)
    plt.title('Plot 00 F1')
    plt.imshow(np.mean(image_00,axis=0),vmin=0,cmap='gray')
    plt.show()
    plt.title('Plot 00 F4 Filament')
    plt.imshow(np.mean(image_00,axis=0),vmin=0.95,cmap='gray')
    plt.show()
    plt.title('Plot 01 F1')
    plt.imshow(np.mean(image_01,axis=0),vmin=0,cmap='gray')
    plt.show()
    plt.title('Plot 01 F4 Filament')
    plt.imshow(np.mean(image_01,axis=0),vmin=0.95,cmap='gray')
    plt.show()

    cv2.waitKey(0)
    print('save_npy')
    np.save(output_path_f1+'00.npy', image_00)
    np.save(output_path_f1+'01.npy', image_00)

    print('save_png')
    cv2.imwrite(output_path_f1+'00.png', (np.mean(image_00,axis=0)*255).astype(float))
    cv2.imwrite(output_path_f1+'01.png', (np.mean(image_01,axis=0)*255).astype(float))

if (STITCH_F4):
    width = 680
    height = 480
    image_00= np.zeros((870,height,width),dtype=np.bool)
    image_snippet_00 = np.zeros((870,60,680),dtype=np.bool)
    image_01= np.zeros((870,height,width),dtype=np.bool)
    image_snippet_01 = np.zeros((870,60,680),dtype=np.bool)
    #image= []
    row_start = 0
    row_increment = 50


    for i in range(12):
        print('Rearranging row segment {:2d}'.format(i),end='\r')
        InputFile_00 = '{}/{:02d}_00/subbyte_0005'.format(input_path_f4, i)
        InputFile_01 = '{}/{:02d}_01/subbyte_0005'.format(input_path_f4, i)
        data_00 = bytearray(np.load(InputFile_00+'.npy'))
        data_01 = bytearray(np.load(InputFile_01+'.npy'))
        comp_out_00 = 1-arrange_adc2(data_00).astype(float)
        comp_out_01 = 1-arrange_adc2(data_01).astype(float)
 

        image_snippet_00 = comp_out_00
        image_snippet_01 = comp_out_01


    
    

        if i==0:
            # print(row_start)
            image_00[:,row_start:(row_start + 50),::2]  = image_snippet_00[:,0:50,::2]
            image_00[:,row_start:(row_start + 50),1::2] = image_snippet_01[:,0:50,::2]
            image_01[:,row_start:(row_start + 50),1::2] = image_snippet_00[:,0:50,1::2]
            image_01[:,row_start:(row_start + 50),0::2] = image_snippet_01[:,0:50,1::2]
            row_start += 50
            
        if i<11 and i>0:
            # print(row_start)
        
            image_00[:,row_start:(row_start + 40),::2]  = image_snippet_00[:,10:50,::2]
            image_00[:,row_start:(row_start + 40),1::2] = image_snippet_01[:,10:50,::2]
            image_01[:,row_start:(row_start + 40),1::2] = image_snippet_00[:,10:50,1::2]
            image_01[:,row_start:(row_start + 40),0::2] = image_snippet_01[:,10:50,1::2]
            row_start += 40
        if i >=11:
            # print(row_start)
        
            image_00[:,row_start:(row_start + 30),::2]  = image_snippet_00[:,10:40,::2]
            image_00[:,row_start:(row_start + 30),1::2] = image_snippet_01[:,10:40,::2]
            image_01[:,row_start:(row_start + 30),1::2] = image_snippet_00[:,10:40,1::2]
            image_01[:,row_start:(row_start + 30),0::2] = image_snippet_01[:,10:40,1::2]
            row_start += 30

    
    
    





    # cv2.imshow('final',image)
    plt.title('Plot 00 F4')
    plt.imshow(np.mean(image_00,axis=0),vmin=0,cmap='gray')
    plt.show()
    plt.title('Plot 00 F4 Filament')
    plt.imshow(np.mean(image_00,axis=0),vmin=0.95,cmap='gray')
    plt.show()
    plt.title('Plot 01 F4')
    plt.imshow(np.mean(image_01,axis=0),vmin=0,cmap='gray')
    plt.show()
    plt.title('Plot 00 F4')
    plt.imshow(np.mean(image_01,axis=0),vmin=0.95,cmap='gray')
    plt.show()

    cv2.waitKey(0)
    print('save_npy')
    np.save(output_path_f4+'00.npy', image_00)
    np.save(output_path_f4+'01.npy', image_00)

    print('save_png')
    cv2.imwrite(output_path_f4+'00.png', (np.mean(image_00,axis=0)*255).astype(float))
    cv2.imwrite(output_path_f4+'01.png', (np.mean(image_01,axis=0)*255).astype(float))
