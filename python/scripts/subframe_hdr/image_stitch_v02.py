import cmath
import numpy as np
import cv2
import os
import sys
import matplotlib.pyplot as plt
import PIL
import time
from cv2 import CV_8U
from PIL import Image
import pandas as pd


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

def read_vref_csv(vref_file, exposure_time=65.7e-3, nuSubs=870):
    tic=time.time()
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
    # vref_all[:,1] = butter_lowpass_filter(vref_all[:,1],5e3,1e6,6)

    vref        = np.interp(t*exposure_time,vref_all[:,0],vref_all[:,1])
    vref        = np.interp(vref,[0,np.max(vref)],[1,0])
    print("\nDone in {}".format(time.time()-tic));tic=time.time()

    return {'t': t, 'vref':vref, 'vref_all':vref_all}

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


input_path =  "../../image/image_v04"
output_path = "../../image/image_v04/image_640_480_v02"

width = 680
height = 480
image        = np.zeros((height,width),dtype=np.float64)
image_log    = np.zeros((height,width),dtype=np.uint8)

#image= []
row_start = 0
row_increment = 60
nuSubs = 870

least_count = nuSubs/(2**16-1)

# vref_data = read_vref_csv(input_path+'/f1_65ms_0.48_3.6.csv',exposure_time=65.7e-3,nuSubs=nuSubs)
vref_data = get_vref_ideal(nuSubs)

vref = vref_data['vref']
t    = vref_data['t']



for i in range(8):
    InputFile   = '{}/{:02d}/subbyte_0011'.format(input_path, i)
    outputFile  = '{}/{:02d}/subimg_0011'.format(input_path, i)
    data = bytearray(np.load(InputFile+'.npy'))
    comp_out = 1-arrange_adc2(data).astype(float)
    np.save(outputFile+'.npy',comp_out)


    comp_out2 = np.moveaxis(comp_out,0,2)    

    fluxMean    = getFluxMeanyWeanie(comp_out2,vref,t)
    adc2        = fluxMean['adc2_raw']
    adc2_log    = np.interp(np.log10(adc2),[np.log10(least_count),np.log10(nuSubs)],[0,255]).astype(np.uint8)
    np.save(    os.path.join(input_path,     'flux_row_{:04d}_{:04d}.npy'.format(i, 11)),       adc2)
    cv2.imwrite(os.path.join(input_path, 'flux_log_row_{:04d}_{:04d}.png'.format(i, 11)),   adc2_log)

    print(comp_out.shape)
    comp_mean = np.mean(comp_out,axis=0)
    print(comp_mean.shape)
    # cv2.imshow('subframe',comp_out.mean(axis=0))
    # cv2.waitKey(0)
    
    image[row_start:(row_start + row_increment),:]      = comp_out.mean(axis=0)
    image_log[row_start:(row_start + row_increment),:]  = adc2_log[:,:]
    row_start += row_increment


# sys.exit()

row_start = 0
for i in range(7):
   
    image[(row_start + row_increment+1),::2] = image[(row_start + row_increment+1),1::2] 
    image[(row_start + row_increment+2),::2] = image[(row_start + row_increment+2),1::2] 
    image[(row_start + row_increment+3),::2] = image[(row_start + row_increment+3),1::2] 
    image[(row_start + row_increment-1),::2] = (image[(row_start + row_increment-1),1::2] + image[(row_start + row_increment-1),::2] )/2
    # image[(row_start + row_increment),::2] = (image[(row_start + row_increment),1::2] + image[(row_start + row_increment),::2] )/2
    image[(row_start + row_increment),::2] = (image[(row_start + row_increment),::2] + (9*image[(row_start + row_increment+1),::2]))/10
    image[(row_start + row_increment-2),::2] = image[(row_start + row_increment-2),1::2] 
    image[(row_start + row_increment-3),::2] = image[(row_start + row_increment-3),1::2] 



    image_log[(row_start + row_increment+1),::2] =  image_log[(row_start + row_increment+1),1::2] 
    image_log[(row_start + row_increment+2),::2] =  image_log[(row_start + row_increment+2),1::2] 
    image_log[(row_start + row_increment+3),::2] =  image_log[(row_start + row_increment+3),1::2] 
    image_log[(row_start + row_increment-1),::2] = (image_log[(row_start + row_increment-1),1::2] + image_log[(row_start + row_increment-1),::2] )/2
    # image_log[(row_start + row_increment),::2] = (image_log[(row_start + row_increment),1::2] + image_log[(row_start + row_increment),::2] )/2
    image_log[(row_start + row_increment),::2]   = (image_log[(row_start + row_increment),::2] + (9*image_log[(row_start + row_increment+1),::2]))/10
    image_log[(row_start + row_increment-2),::2] = image_log[(row_start + row_increment-2),1::2] 
    image_log[(row_start + row_increment-3),::2] = image_log[(row_start + row_increment-3),1::2] 



    row_start += row_increment



cv2.imshow('final',image)
cv2.imshow('final_log',image_log)

#plt.imshow(image)
#plt.show()
cv2.waitKey(0)
print('save')
np.save(output_path+'.npy', image)

print('save_png')
cv2.imwrite(output_path+'.png', (image*256).astype(np.uint8))
