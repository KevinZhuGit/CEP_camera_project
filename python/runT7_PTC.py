#!/usr/bin/env python3
import os
import sys
import numpy as np
import time
import cv2
from PIL import Image 
import matplotlib.pyplot as plt
import io
import atexit
from datetime import datetime

sys.path.insert(0, "./api")
from t6 import *
from usefulFunctions import *


[row, col] = [480, 680] #sensor resolution



cmap_heat = plt.get_cmap('inferno')
# hdr2ldr image
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
    fusion = mergeMertens.process(imgs[:,:,:col])
    fusion = np.interp(fusion,[vmin,vmax],[0,2**16-1]).astype(np.uint16)
    return fusion


def nothing(umm):
    """
        doesn't do anything. Need this for some image trackbar thingy
    """

    pass

def getADCs(cam, rows, NSUB, adc1_en=True, adc2_en = True):
    """
        cam: camera class handle
        returns: 2d array of size 320x648
    """
    if(adc2_en):
        raw_adc2   = cam.adc2_read(NSUB)
    else:
        raw_adc2 = None

    if(adc1_en):
        raw_adc1   = cam.imread()
    else:
        raw_adc1 = None

    return raw_adc1, raw_adc2
    # return raw

def arrangeImg(cam,raw_adc1=None,raw_adc2=None,rows_adc1=480,rows_adc2=480,adc2_PerCh=16):
    if(raw_adc1!=None):
        img_adc1 = cam.arrange_raw_T7(raw_adc1,rows_adc1)
    else:
        img_adc1 = np.zeros((row,col*2),dtype=np.uint16)
    if(raw_adc2!=None):
        img_adc2 = (1-cam.arrange_adc2(raw_adc2,rows=rows_adc2,ADCsPerCh=adc2_PerCh))
    else:
        img_adc2 = np.zeros((row,col),dtype=np.uint16)

    return img_adc1,img_adc2

def getImg(cam,rows):
    """
        cam: camera class handle
        returns: 2d array of size 320x648
    """
    # tap,colsPerADC,ADCsPerCh,ch,nob = 2,2,20,12,12
    # cam.frame_length   = int(rows*tap*colsPerADC*ADCsPerCh*ch*nob/8*256/240)
    tap,colsPerADC,ADCsPerCh,ch,nob = 2,2,20,17,12
    cam.frame_length   = int(rows*tap*colsPerADC*ADCsPerCh*ch*nob/8*256/255)
    # cam.frame_length = 108*4*320*2*2 # t6
    # cam.frame_length = int((480*40*17*2*12*256/255) // 8) #t7

    raw              = cam.imread()
    # raw_img          = cam.arrange_raw(raw,rows)
    # tic = time.time()
    raw_img          = cam.arrange_raw_T7(raw,rows)
    # logging.info('rearrange time: {}'.format(time.time()-tic))
    return raw, raw_img    

def getSubImg(cam,NSUB):
    pread=bytearray(int(680*480*256/255*NSUB/8));
    t6.read(0xa3,pread)

    mean = (1-cam.arrange_adc2(pread))*(2**16-1)

    return mean.astype(np.uint16)

def showImg(win,img,cam=None,show=True,\
            raw=False,gain=False,black=False,dynamic=False,hdr=False,\
            crop = False, crop_loc = [175,235,185,245], \
            heatmap=False,drawLines=False,edgeDetectFlag=False,f=1,max_scale=6000):
    """
        can return and/or show raw, black, gain, dynamic calibrated images

        win: name of the cv2 window where image should be showed
        img: np.uint16 2d (r x c) or 3d array of size (N x r x c)
        cam: camera handle

            FLAGS
        show:       show image in win
        raw:        don't scale show as it is
        gain:       do gain calibration
        black:      do black calibration
        dynamic:    dynamically adjust black and white levels
        heatmap:    gray to heatmap
        hdr:        combine 16-bit image to show on 8-bit display
        crop:       crop the image

            Optional Values/Handles
        f:          scale the image
        max_scale:  maxium allwed pixel value(saturation value) after black calibration
        trackbar:   trackbar name
        drawLines:  draw horizontal lines at 25, 50 and 75% of the image height
        crop_loc: location where to crop
    

        output
        img: the image being showed
    """

    if(raw):
        # cv2.imshow(win,img)
        img = img
    elif(gain):
        img = cam.image_scale6(img,gain=gain, black=black, max_scale=2**13-1)
    elif(black):
        img = cam.image_scale6(img,gain=False,black=True,max_scale=max_scale)
    elif(dynamic):
        img = cam.image_scale6(img,gain=False,black=False,dynamic=True)
    elif(hdr):
        LSB = np.floor(np.log2(2**16/max_scale)) #LSB without noise
        img = hdr2ldr(img,vmin=0,vmax=1,LSB=LSB)
    elif(heatmap):
        # re-formatting array to make sure we can use it for 2d arrays as well
        img = img.reshape((-1,img.shape[-2],img.shape[-1]))
        # img = np.interp(img,[0,2**16-1],[0,1])
        img_combined = np.mean(img,axis=0)

        #apply colormap
        img = cmap_heat(img_combined)[:,:,[2,1,0]]
        img = np.interp(img,[0,1],[0,2**16-1]).astype(np.uint16)

    if(edgeDetectFlag):
        [img,stuff] = edgeDetect(img,minVal=100,maxVal=200,aperature=3,key='d')


    if(drawLines):
        if(len(img.shape)==2):
            img = cv2.cvtColor(img,cv2.COLOR_GRAY2BGR) #add RGB channels to grayscal image
        img[:, ::32   ,2] = 2**16-1
        # img[:, 1::32  ,2] = 2**16-1
        # img[:, 39::32 ,2] = 2**16-1
        # img[(row*2)//4, : ,1] = 2**16-1
        # img[(row*3)//4, : ,2] = 2**16-1

    if(crop):
        if(len(img.shape)==2):
            img = cv2.cvtColor(img,cv2.COLOR_GRAY2BGR) #add RGB channels to grayscal image
        [r1,c1,r2,c2] = crop_loc
        img[r1:r2,       [c1,c2],     2] = 2**16-1
        img[[r1,r2],      c1:c2,      2] = 2**16-1
        img[r1:r2,   [c1+col,c2+col], 2] = 2**16-1
        img[[r1,r2],  c1+col:c2+col,  2] = 2**16-1

        cropped_img = np.concatenate([img[r1-1:r2+1,c1-1:c2+1],img[r1-1:r2+1,c1+col-1:c2+col+1]],axis=1)

    if(show):
        cv2.imshow(win,cv2.resize((img),None,fx=f,fy=f,\
        # interpolation=cv2.INTER_LINEAR))
        interpolation=cv2.INTER_NEAREST))
        if(crop):
            cv2.imshow(win+'(cropped)',cv2.resize((cropped_img),None,fx=f*10,fy=f*10,\
            interpolation=cv2.INTER_NEAREST))
    return img



def exit_handler(cam):
    """
        Add code here that you want to execute when you close the camera.
        For example, you may want to print the parameters you updated 
            during camera operation.
    """

    cam.dev.Close()
    # In this function, all the lines below this are optional
    os.system('pkill feh') 
    os.system('python3 ~/customErrorScript.py') #this is optional

    print("EXIT SCRIPT")
    print("exposure-----------: {}".format(exposure))
    print("rows_sub_img-------: {}".format(rows_sub_img))
    print("adc2_spacing-------: {}".format(adc2_spacing))





if __name__ == '__main__':

    # ====================================
    # Users can change these variables
    # Variables to play with for baby users
    # maskfile    = 'maskfile/t6_cats_256.bmp'
    # maskfile    = 'maskfile/t7_allOneZero_100x.bmp'
    maskfile    = 'maskfile/t7_allOne_600x.bmp'
    # maskfile    = 'maskfile/t7_gradient_masks_256.bmp'
    # maskfile    = 'maskfile/t7_triangle_50x.bmp'
    # maskfile    = 'maskfile/t7_all1_16x.bmp'
    # maskfile    = 'maskfile/t7_mask_test.bmp'
    if(1):
        subFrameNum = 1100           # Number of subframes
        exposure    = 60         # =(exposure time(us) per subframe)/2. must be larger than 26.2*repNum. Sorry it's kinda weird right now
        numSubRO    = 1024
        rows_sub_img = int(60)
        adc2_PerCh  = 20

        rows_test    = 480
        rows_masking = 60
        
        adc2_spacing        = 4718
        adc2_spacing_step   = 10
        row_start           = 0
        trigWaitTime        = 8172
    if(0):
        subFrameNum = 121           # Number of subframes
        exposure    = 278         # =(exposure time(us) per subframe)/2. must be larger than 26.2*repNum. Sorry it's kinda weird right now
        numSubRO    = 120
        rows_sub_img = int(480)
        adc2_PerCh  = 20

        rows_test    = 480
        rows_masking = 480
        
        adc2_spacing        = 55000
        adc2_spacing_step   = 10
        row_start           = 0
        trigWaitTime        = 10

    PTC_METHOD1 = False
    PTC_METHOD2 = True

    MASTER_MODE = True          # Running camera without a trigger. Set it to false to run it based on trigger

    # ---------------------------------    
    # Variables to play with for bigger baby users
    # bitfile     = "bitfile/Reveal_Top_t7_based_on_t6_test_02.bit" # CLKMi 100 MHz, exposure module changed back to t6
    bitfile       = "bitfile/Reveal_Top_t7_based_on_t6_06.07.bit"
    repNum        = 1             # Number of repetition per subframe
    memMaskNum    = subFrameNum   # Number of masks in the memory
    exposureRep   = 1             # number of projector scans before 1 readout
    exposure_step = 1             # minium step is 0.005


    # ====================================
    adc1_en = 0
    adc2_en = 1

    # ======Don't modify lines BELOW THIS=======
    # just some necessary stuff. 
    l_par={} #local parameters
    l_par['bitfile'] = bitfile
    l_par['maskfile'] = maskfile
    l_par['subFrameNum'] = subFrameNum
    l_par['repNum'] = repNum
    l_par['memMaskNum'] = memMaskNum
    l_par['exposure'] = exposure
    l_par['exposureRep'] = exposureRep
    l_par['row'] = row
    l_par['col'] = col
    l_par['exposure_step'] = exposure_step

    # ---------------------------------    

    # Disable logging
    logging.disable(logging.DEBUG)
    logging.info("Disabling debug logging")

    # ---------------------------------    

    # initialize camera
    t6 = T6(bitfile) # program camera
    t6.param_set(t6.param['MU_NUM_ROW'],rows_masking)
    t6.param_set(t6.param['MASK_SIZE'],rows_masking*subFrameNum*repNum*16)

    t6.param_set(t6.param['IMG_SIZE'],int((rows_test*40*17*2*12*256/255)//32))

    t6.param_set(t6.param['SUB_IMG_SIZE'],int((rows_sub_img*2*adc2_PerCh*17*numSubRO*1*256/255)//32))
    t6.param_set(t6.param['UNIT_SUB_IMG_SIZE'],int((rows_sub_img*2*adc2_PerCh*17*1*1*256/255)//32))
    t6.param_set(t6.param['N_SUBREADOUTS'],int(numSubRO))
    t6.unit_subframe_length = round(rows_sub_img*17*2*adc2_PerCh*256/255//8)
    t6.adc2_container = bytearray(round(t6.unit_subframe_length*numSubRO))

    # set camera to be in MASTER or SLAVE mode
    if(MASTER_MODE): # to run camera in master mode. Does not wait for any external trigger
        Select_val =np.packbits([
                     0,0,0,1, 0,adc2_en,adc1_en,1,   # 31:24
                     0,0,0,0, 0,0,0,0,   # 23:16
                     0,0,0,0, 0,0,0,0,   # 15:8
                     0,1,1,1, 0,0,0,0 ]) #  7:0 
        Select_val = np.sum(np.multiply(Select_val,[2**24,2**16,2**8,1])).astype(np.uint32)
        t6.param_set(t6.param['Select'], int(Select_val)) #free run mode
    else: # to run the camera in slave mode. It waits for trigger. 
            # 3.3V trigger must be connected to 
        t6.param_set(t6.param['Select'], 0x80000000) #free run mode

    TADC = 20
    t6.param_set(t6.param['ADC1_TADC'],     TADC)
    # t6.param_set(t6.param['ADC1_T3'],     int(TADC*1.5))
    t6.param_set(t6.param['ADC1_T2_1'],     int(TADC*16))   # > TADC*14
    t6.param_set(t6.param['ADC1_T2_0'],     int(TADC*16)+20)
    t6.param_set(t6.param['ADC1_T3'],       int(TADC*16))
    t6.param_set(t6.param['ADC1_T4'],       int(TADC*17))     # > TADC*14
    t6.param_set(t6.param['ADC1_T5'],       4)                # > TADC*14
    t6.param_set(t6.param['ADC1_T6'],       1)    #  =1
    t6.param_set(t6.param['ADC1_T7'],       30)   #  > 20
    t6.param_set(t6.param['ADC1_T8'],       2)
    t6.param_set(t6.param['ADC1_T9'],       2+20)
    t6.param_set(t6.param['ADC1_Tcolumn'],  int(TADC*17 + 30*14 + 4)) #T4 + T7*12 + T5
    t6.param_set(t6.param['ADC1_NUM_ROW'],  rows_test+1)

    t6.param_set(t6.param['ADC2_NUM_ROW'],  int(rows_sub_img+1))
    t6.param_set(t6.param['ADC2_Wait'],     100)
    t6.param_set(t6.param['ADC2_Tcolumn'],  50) #T4 + T7*12 + T5
    t6.param_set(t6.param['ADC2_T2_1'],     18)
    t6.param_set(t6.param['ADC2_T2_0'],     20)
    t6.param_set(t6.param['ADC2_T7'],       3+adc2_PerCh)
    t6.param_set(t6.param['ADC2_T8'],       3)
    t6.param_set(t6.param['ADC2_T9'],       3+adc2_PerCh)

    
    t6.param_set(t6.param['MSTREAM_Select'],0xAAAAAAAA)

    # t6.param_set(t6.param['TrigOnTime'],)
    trigOffTime = adc2_spacing
    t6.param_set(t6.param['TrigOffTime'],    trigOffTime)
    t6.param_set(t6.param['TrigWaitTime'],   trigWaitTime)
    t6.param_set(t6.param['TrigNo'],        numSubRO)

    t6.param_set(t6.param['T_DEC_SEL_0'],   2  )
    t6.param_set(t6.param['T_DEC_SEL_1'],   0  )
    t6.param_set(t6.param['T_DEC_EN_0'],    4 )
    t6.param_set(t6.param['T_DEC_EN_1'],    0 )
    t6.param_set(t6.param['T_DONE_1'],2)


    TLEDOnList        = np.concatenate([np.linspace(1,10,10,    dtype=int),
                                       np.logspace(1,4,91, dtype=int)])
    TLEDOnIndex       = 0
    t6.param_set(t6.param['TLEDNo'   ], 1)
    t6.param_set(t6.param['TLEDOff'  ], 2) 
    t6.param_set(t6.param['TLEDOn'   ], int(TLEDOnList[TLEDOnIndex]))
    t6.param_set(t6.param['TLEDWait' ], 200)  


    t6.param_set(t6.param['ROWADD_INCRMNT'], 240)

    adc2_rowmap = np.repeat(np.arange(480).reshape(480,1),2,axis=1)
    adc2_rowmap[0:240:2,1]   = adc2_rowmap[:120,0]*4
    adc2_rowmap[1:240:2,1]   = adc2_rowmap[:120,0]*4+1
    adc2_rowmap[240:480:2,1] = adc2_rowmap[:120,0]*4
    adc2_rowmap[241:480:2,1] = adc2_rowmap[:120,0]*4+1
    # adc2_rowmap[:,1] = 480-adc2_rowmap[:,1]
    # adc2_rowmap[adc2_rowmap<0] = 0
    # t6.setRowMap(adc2_rowmap)
    # sys.exit()

    atexit.register(exit_handler,t6)
    # t6.UploadMaskDummy(maskfile,memMaskNum)
    t6.UploadMask(maskfile,memMaskNum)
    t6.SetMaskParam(subFrameNum, repNum)
    t6.SetExposure(exposure)
    # t6.param_set(t6.param['NumExp'],int(exposureRep))

    # reset, do one exposure and wait till images are readout
    t6.readout_reset()
    time.sleep(1)
    # ======Don't modify lines ABOVE THIS=======


    # create imshow windows
    raw ='C2B' ;cv2.namedWindow(raw)
    cv2.createTrackbar('Zoom', raw, 5, 40, nothing); f=1
    hdr='C2B_(HDR2LDR)';cv2.namedWindow(hdr) # this may or may not work well


    saveFlag = False # set flag to save the image. Can be set by pressing 's' during camera operation
    enable_key_read = True

    # it will try to create following directory to save images if it doesn't existss
    saveDir = os.path.join('./image/t6Exp{:06d}Mask{:03d}_PTC'.format(\
                                int(exposure),subFrameNum),'')
    # number of images to save
    saveNum         = 2000
    rawBuffer       = np.zeros((saveNum,row,col*2),        dtype=np.uint16) # buffer for raw images
    blackBuffer     = np.zeros((saveNum,row,col*2),        dtype=np.uint16) # buffer for black calibrated images
    raw_adc1_buffer = np.zeros((saveNum, t6.frame_length), dtype=np.uint8)
    raw_adc2_buffer = np.zeros((saveNum, numSubRO*t6.unit_subframe_length), dtype=np.uint8)
    # following 3 lines are to calcualte frame rate.
    # press 'f' to ~pay respect~ find current frame rate.
    FRAMENUM = 0
    prev_time = time.time()
    prev_fNum = FRAMENUM

    [r1,c1,r2,c2]     = [102, 233, 162, 293]

    goodpixels = np.zeros((60,680),dtype=np.bool)
    goodpixels[::int((60-4)/12),::int((680-30)/17/2/1.5)] = True
    goodpixels[:,:]             = True
    goodpixels[[0,1,2,3,-1],:]  = False
    goodpixels[:,:30]           = False
    goodpixels[:,80:120]        = False
    goodpixels[:,440:480]       = False

    # This is the loop to view sensor output as video.
    while True:
        if(saveFlag):
            showFlag = False
        else:
            showFlag = True

        raw_adc1,raw_adc2=getADCs(t6,row,NSUB=numSubRO,adc1_en=adc1_en,adc2_en=adc2_en)

        if(showFlag):
            img_adc1,img_adc2=arrangeImg(t6,raw_adc1,raw_adc2,rows_adc1=rows_test,rows_adc2=rows_sub_img,adc2_PerCh=adc2_PerCh)
            
            k = np.sum(img_adc2[:,goodpixels],axis=0)
            for i in range(numSubRO):
                if(np.any(i==k)):
                    continue
                else:
                    print(i,end=' ')
            print()



            f=cv2.getTrackbarPos('Zoom',raw)/5 #image scale factor
            if(adc1_en):
                blackCal_img = showImg(raw, cam=t6, show=True,
                            img=img_adc1, black=True, dynamic=False, 
                            # img=raw_img, raw=False, black=False, dynamic=True, 
                            # img=2**16-1-raw_img*16, raw=True, black=False, dynamic=False,
                            # drawLines = True,
                            # crop_loc = [r1,c1,r2,c2], crop = True, 
                            max_scale=2048,f=f)
            if(adc2_en):
                showImg("subframes",img=img_adc2, cam=t6, heatmap=True)

        FRAMENUM += 1 # For measuring FPS


        # do something based on inputs
        if(enable_key_read):
            key = cv2.waitKey(1)
            ### CLOSE ###
        if key==27: # this is ESC key
            cv2.destroyAllWindows()
            t6.dev.Close()
            break
            ### SAVE ###
        elif(key==ord('s')): # start saving
            logging.info("Saving #{} images".format(saveNum))
            saveFlag=True;saveIndex = 0;blackUpdate=False;brightUpdate=False

        elif(key==ord('p')):
            loggin.info("STARTING PTC")
            enable_key_read = False

            ### SAVE ###
            # If saving, load images in buffer before saving
        if(saveFlag==True):
            
            raw_adc2_buffer[saveIndex,:]    = np.frombuffer(raw_adc2,dtype=np.uint8)
            saveIndex+=1
            time.sleep(0.1)
            print(saveIndex,end='\r')
            if(saveIndex == saveNum):
                saveIndex = 0
    
                if(PTC_METHOD1):

                    t6.imsave(raw_adc2_buffer,saveDir,'subbyte_x{}_N_{}_led_{:04d}.npz'.format(\
                                    saveNum,numSubRO,TLEDOnList[TLEDOnIndex]))


                    raw_adc2 = bytearray(raw_adc2_buffer[-1,:])
                    _,img_adc2=arrangeImg(t6,None,raw_adc2,rows_adc1=rows_test,rows_adc2=rows_sub_img,adc2_PerCh=adc2_PerCh)
                    adc2_heatmap = showImg("subframes",img=img_adc2, cam=t6, heatmap=True)
                    t6.imsave(adc2_heatmap, saveDir,'subbyte_x{}_N_{}_led_{:04d}.png'.format(\
                                    saveNum,numSubRO,TLEDOnList[TLEDOnIndex]))


                    TLEDOnIndex += 1
                    if(TLEDOnIndex==len(TLEDOnList)):
                        saveFlag = False
                        continue
                    t6.param_set(t6.param['TLEDOn'   ], int(TLEDOnList[TLEDOnIndex]))


                if(PTC_METHOD2):
                    saveFlag = False
                    t6.imsave(raw_adc2_buffer,saveDir,'subbyte_x{}_N_{}_{}.npz'.format(\
                    saveNum,numSubRO,datetime.now().strftime("%y%m%d_%H%M%S")))


                    raw_adc2 = bytearray(raw_adc2_buffer[-1,:])
                    _,img_adc2=arrangeImg(t6,None,raw_adc2,rows_adc1=rows_test,rows_adc2=rows_sub_img,adc2_PerCh=adc2_PerCh)
                    adc2_heatmap = showImg("subframes",img=img_adc2, cam=t6, heatmap=True)
                    t6.imsave(adc2_heatmap, saveDir,'subbyte_x{}_N_{}_{}.png'.format(\
                    saveNum,numSubRO,datetime.now().strftime("%y%m%d_%H%M%S")))

                logging.info("Done saving {:04d}".format(TLEDOnList[TLEDOnIndex]))

