import time
import re
import logging
import scipy.misc
from scipy.ndimage.filters import gaussian_filter
from fpga import api
import numpy as np
import cv2
import os,sys
from bitstring import BitArray
from PIL import Image
import numpngw

logging.basicConfig(format='%(levelname)-6s[%(filename)s:%(lineno)d] %(message)s'
                    ,level=logging.DEBUG)


class T6(api):

    address = {'mk_routine_rst': 0x00,
               'wire_check_set': 0x01,
                     'param_en': 0x02,
                     'param_in': 0x03,
                   'param_addr': 0x04,
                   'rowmap_set': 0x0A,
                     'chip_rst': 0x10,
                 'wire_check_o': 0x20,
                     'fifo_cnt': 0x21,
                    'param_out': 0x22,
                     'exposure': 0x11,
                      'pat_num': 0x12,
                  'mem_pat_num': 0x14,
                    'sys_start': 0x40,
                     'mem_mode': 0x13,
                      'trigger': 0x53,
                    'fifo_flag': 0x6a,
                       'mem_wr': 0x80,
                      'ldo_spi': 0x81,
                      'cis_spi': 0x82,
                       'mem_rd': 0xA0,
                        'image': 0xB0,
                      'adc2_rd': 0xA3
               }

    param = {      'numPattern' : 0,
                    'Texp_ctrl' : 1,
                    'Tdes2_d' : 2,
                    'Tdes2_w' : 3,
                    'Tmsken_d' : 4,
                    'Tmsken_w' : 5,
                    'Tgsub_w' : 6,
                    'Tgl_Res' : 7,
                    'Tproj_dly' : 8,
                    'Tadd' : 9,
                    'NumRep' : 10,
                    'NumGsub' : 11,
                    'TExpRST' : 12,
                    'Tdrain_w' : 13,
                    'imgCountTrig' : 14,
                    'TdrainR_d' : 15,
                    'TdrainF_d' : 16,
                    'TLedOn' : 17,
                    'Select' : 18,
                 'CAM_TG_pulseWid' : 19,
                 'CAM_TG_HoldTime' : 20,
                    'CAM_TG_delay' : 21,
                       'MASK_SIZE' : 22,
                        'IMG_SIZE' : 23,
                     'T_DEC_SEL_0' : 24,
                     'T_DEC_SEL_1' : 25,
                      'T_DEC_EN_0' : 26,
                      'T_DEC_EN_1' : 27,
                        'T_DONE_1' : 28,
                  'MSTREAM_Select' : 29,
                      'MU_NUM_ROW' : 30,
                    'SUB_IMG_SIZE' : 31,
                    'ADC1_Tcolumn' : 32,
                         'ADC1_T1' : 33,
                       'ADC1_T2_1' : 34,
                       'ADC1_T2_0' : 35,
                         'ADC1_T3' : 36,
                         'ADC1_T4' : 37,
                         'ADC1_T5' : 38,
                         'ADC1_T6' : 39,
                         'ADC1_T7' : 40,
                         'ADC1_T8' : 41,
                         'ADC1_T9' : 42,
                       'ADC1_TADC' : 43,
                    'ADC1_NUM_ROW' : 44,
                       'ADC1_Wait' : 45,
                       'T_MU_wait' : 46,
                    'ADC2_Tcolumn' : 47,
                         'ADC2_T1' : 48,
                       'ADC2_T2_1' : 49,
                       'ADC2_T2_0' : 50,
                         'ADC2_T3' : 51,
                         'ADC2_T4' : 52,
                         'ADC2_T5' : 53,
                         'ADC2_T6' : 54,
                         'ADC2_T7' : 55,
                         'ADC2_T8' : 56,
                         'ADC2_T9' : 57,
                       'ADC2_TADC' : 58,
                    'ADC2_NUM_ROW' : 59,
                       'ADC2_Wait' : 60,
                       'T_MU_wait' : 61,
                          'TrigNo' : 62,
                     'TrigOffTime' : 63,
                      'TrigOnTime' : 64,
                'UNIT_SUB_IMG_SIZE': 65,
                    'N_SUBREADOUTS': 66,
                      'spi_control': 67,
                         'i2c_data': 68,
                      'i2c_control': 69,
                   'ROWADD_INCRMNT': 70,
                     'TrigWaitTime': 71,
                           'TLEDNo': 72,
                          'TLEDOff': 73,
                           'TLEDOn': 74,
                         'TLEDWait': 75
            }

    
    # voltages for LDO
    voltages = np.array([3.3, 0.8, 0.6, 3.3,  # VRES/VSEL, VSSRES/VDRN, VSSTG, VTG
                         3.3, 3.3, 2.6, 3.3,  # VRST, VROWMASK, VDDPIX, AVDD33_ADC/AVDD33
                         3.3, 3.3, 3.3, 3.3]) # ...............................  
    
    # this is 96-bit on chip. To configure mask upload settings
    cis_spi_mu = [  '0100001000110000', '0000000000000000', # 95:80, 79:64
                    '0000000000000000', '0000000000000000', # 63:48, 47:32
                    '0000000000000000', '1000000000000000', # 31:16, 15:00
                    '0000000000000010', '0000000000000000']

    # this is only 48-bit on chip. To configure all other settings
    cis_spi_ro = [  '0000000000000000', '0000000000000000', # GARBJ, GARBJ
                    '0000000000000000', '0000000000011101', # GARBJ, 47:32
                    '1100000001111100', '1101111101000011', # 31:16, 15:00
                    '0000000000000001', '0000000000000000'] # <slave_select>


    col, row, tab, ch = 108, 320, 2, 3
    #frame_length = 552960
    # frame_length    = col*4*row*tab*2 # t6
    frame_length            = round((480*40*17*2*12*256/255) // 8) #t7
    unit_subframe_length    = round(480*40*17*1*1*256/255/8)

    adc2_container = bytearray(unit_subframe_length)
    adc1_container = bytearray(frame_length)

    BLOCK_SIZE      = 512
    
    # trying to fix importing t4 from path outside of Cam_API_py and still have it work
    # use module relative paths
    black_img_file  = os.path.join(os.path.dirname(__file__), 't6_black_image_avg.npy')
    bright_img_file = os.path.join(os.path.dirname(__file__), 't6_bright_image_avg.npy')
    gain_mat_file   = os.path.join(os.path.dirname(__file__), 'gain_mat.npy')
    gain_cali_file  = os.path.join(os.path.dirname(__file__), 't6_gain_cali.npy')
    img_map_file    = os.path.join(os.path.dirname(__file__), 't6_img_map.npy')
    img_graymap_file = os.path.join(os.path.dirname(__file__),'t6_img_graymap.npy')
    mask_map_file   = os.path.join(os.path.dirname(__file__), 't6_mask_map.npy')
    adc2_map_file   = os.path.join(os.path.dirname(__file__), 't7_adc2_map_1bit.npy')

        
    black_flag = False
    black_scale_flag = False
    gain_flag = False
    gain_scale_flag = False
    scale_flag = False
    MaskNumInMem=0
    MaskNumForCam=0
    MaskRepetition=0
    ldo_delay = 0.1


    def __init__(self, bitfile,reConfFPGA=True):

        super(T6, self).__init__(bitfile)
        logging.info("Bitfile: {}".format(bitfile))
        if(reConfFPGA):        

            self.LDOConf(self.voltages)           
            time.sleep(1)
            self.CISConf(self.cis_spi_mu)
            time.sleep(1)
            self.CISConf(self.cis_spi_ro)

            time.sleep(5)
            self.wire_in(self.address['mk_routine_rst'], 0x04)
            self.wire_in(self.address['mk_routine_rst'], 0x00)
            #self.wire_in(self.address['mask'], 0xfff)
            self.wire_in(self.address['chip_rst'], 0x01)
            #self.wire_in(self.address['chip_rst'], 0x00)
            self.wire_in(self.address['exposure'], 1)
            self.wire_in(self.address['pat_num'], 1)


            # self.param_set(self.param['imgCountTrig'],3000)
            self.param_set(self.param['TExpRST'], 10000) # 200MHz
            self.param_set(self.param['Tproj_dly'], 100)
            self.param_set(self.param['NumRep'], 1)
            self.param_set(self.param['NumGsub'], 0)
            self.param_set(self.param['Tdrain_w'], 0)

            self.param_set(self.param['Tgsub_w'], 100)
            self.param_set(self.param['TdrainF_d'], 20)
            self.param_set(self.param['TdrainR_d'], 10)

            #DELAY+WIDTH<=15
            self.param_set(self.param['Tmsken_d'], 4)
            self.param_set(self.param['Tmsken_w'], 11)

            self.param_set(self.param['Select'], 0x80000000)  # enable slave mode




    
        else:
            logging.info("Did not configure FPGA with bitfile")
            self.wire_in(self.address['mk_routine_rst'], 0x04)
            self.wire_in(self.address['mk_routine_rst'], 0x00)
            self.wire_in(self.address['chip_rst'], 0x01)


        self.mapping = self.ImgMapCal()
        # self.mapping = self.ImgGrayMapCal()

        self.mkmapping = self.MaskMapCal()
        if(os.path.exists(self.black_img_file)):
            self.black_img = np.load(self.black_img_file)
        if(os.path.exists(self.gain_cali_file)):
            self.gain_cali = np.load(self.gain_cali_file)
        if(os.path.exists(self.bright_img_file)):
            self.bright_img = np.load(self.bright_img_file)
            #self.coeff_mat = np.load(self.gain_cali_file)
            #self.coeff_mat[324:] = self.coeff_mat[0:324]
        if(os.path.exists(self.adc2_map_file)):
            self.adc2_map_1row = np.load(self.adc2_map_file).flatten()


###################################################

    def UploadMask(self, mask_file, MaskNum):
        """
        mask_file@in: mask file name and path
        MaskNum@in: give mask number which will be set in memory control
        """
        # reset camera
        self.wire_in(self.address['chip_rst'], 0x01)
        logging.info("Camera Stopped.")
        self.fmaskupload(mask_file)
        logging.info("Mask {} uploaded.".format(mask_file))
        self.wire_in(self.address['mem_pat_num'], MaskNum)
        self.MaskNumInMem=MaskNum
        logging.info("Mask #{}".format(MaskNum))

    def UploadMaskDummy(self, mask_file, MaskNum):
        """
    Dummy version of the mask upload which sets all variables except uploading mask to memory
        mask_file@in: mask file name and path
        MaskNum@in: give mask number which will be set in memory control
        """
        # reset camera
        self.wire_in(self.address['chip_rst'], 0x01)
        logging.info("Camera Stopped.")
    # self.fmaskupload(mask_file)
        # memory mask upload mode
        self.wire_in(self.address['mem_mode'], 0x01)
        self.wire_in(self.address['mk_routine_rst'], 0x04)
        self.wire_in(self.address['mk_routine_rst'], 0x01)
        logging.info("Mask {} was ***NOT*** uploaded.".format(mask_file))
        self.wire_in(self.address['mem_pat_num'], MaskNum)
        self.MaskNumInMem=MaskNum
        logging.info("Mask #{}".format(MaskNum))        
 
    def readout_reset(self):
        self.wire_in(self.address['chip_rst'], 0x01)
        self.wire_in(self.address['chip_rst'], 0x00)

    def chip_reset(self):
        self.wire_in(self.address['mk_routine_rst'], 0x04)
        self.wire_in(self.address['mk_routine_rst'], 0x00)
        #self.wire_in(self.address['mask'], 0xfff)
        self.wire_in(self.address['chip_rst'], 0x01)
    
    def Pause(self):
        self.wire_in(self.address['chip_rst'], 0x01)
        logging.info("Camera Stopped.")

    def Resume(self):
        self.wire_in(self.address['chip_rst'], 0x00)
        logging.info("Camera Stopped.")
    
    def SetMaskParam(self, MaskNum, MaskRepNum=1):
        """
        MaskNum@in: set mask number applied in camera
        MaskRepNum@in: each mask repetition time in camera
        """
        # reset camera
        assert self.MaskNumInMem>0, "Please upload mask to camera first."
        assert self.MaskNumInMem%MaskNum==0, "CamMask #{} should dividable by MemMask #{}".format(MaskNum, self.MaskNumInMem)
        self.wire_in(self.address['pat_num'], MaskNum)
        logging.info("Camera mask #{}".format(MaskNum))
        self.MaskNumForCam=MaskNum
        self.param_set(self.param['NumRep'], MaskRepNum)
        logging.info("Camera mask repetition #{}".format(MaskRepNum))
        self.MaskRepetition=MaskRepNum

    def SetExposure(self, value):
        """
        value@in: exposure time in us
        """
        assert self.MaskNumForCam != 0, "Please set mask parameter to camera first."
        assert self.MaskRepetition != 0, "Please set mask parameter to camera first."
        logging.info("Setting Camera exposure #{}us ...".format(value))

        maskuploadtime = 26195 # 26195ns for maskupload, 200MHz freq. 5n
        SetAsClk = int((value*1000-maskuploadtime*self.MaskRepetition)/5-2)

        assert SetAsClk > 0, "Exposure time should larger than {}us".format((10+maskuploadtime*self.MaskRepetition)/1000)

        self.wire_in(self.address['exposure'], SetAsClk)
        logging.info("Camera exposure setting finished. #{} clk".format(SetAsClk))

    def getimg(self, mode='raw'):
        """
        mode = 'raw'/'black'
        """
        assert mode == 'raw' or 'black', "No {} mode. 'raw' or 'black'".format(mode)

        if mode == 'raw':
            self.showMode()
        if mode == 'black':
            self.showMode(black_scale=True)

        return self.arrange(self.imread())

    def nothing(self, x):
        pass

    def imshow(self, numbers = None):

        img_name = 'image'
        cv2.namedWindow(img_name)
        cv2.createTrackbar('Zoom', img_name, 10, 30, self.nothing)

        while True:

            factor = cv2.getTrackbarPos('Zoom',img_name)
            if factor == 0: factor = 1

            #img=self.arrange(self.imread())
            img=self.getimg()

            img_scaled = cv2.resize(img,None,fx=factor/10, fy=factor/10,
                                    interpolation = cv2.INTER_LINEAR)

            cv2.imshow(img_name, img_scaled)

            k=cv2.waitKey(1)
            if k==27: break

        cv2.destroyAllWindows()

    def setRowMap(self,rowmapGuide):
        logging.info("rewriting row map")
        set_write   = '0'+'{:015b}'+'{:016b}'
        done_write  = '1'+'{:015b}'+'{:016b}'
        totalRows   = len(rowmapGuide);      i=0;
        for current_map in rowmapGuide:
            from_row  = current_map[0]
            to_row    = current_map[1]
            write_value = int(set_write.format(from_row,to_row),2)
            done_value  = int(done_write.format(from_row,to_row),2)
            self.wire_in(self.address['rowmap_set'],write_value)
            time.sleep(1/1000)
            self.wire_in(self.address['rowmap_set'],done_value)
            time.sleep(1/1000)
            self.wire_in(self.address['rowmap_set'],write_value)
            time.sleep(1/1000)
            print("{}/{} done".format(i,totalRows),end='\r')
        self.wire_in(self.address['rowmap_set'],0)

#######################################################

    def showMode(self, black=False, black_scale=False, gain=False, gain_scale=False, scale=False):
        if black or black_scale and os.path.exists(self.black_img_file):
            if black_scale:
                self.black_scale_flag = True
            else:
                self.black_flag = True
            print("Black calliberation On")
        elif gain or gain_scale and os.path.exists(self.gain_cali_file):
            if gain_scale:
                self.gain_scale_flag = True
            else:
                self.gain_flag = True
            print("Black calliberation On")
            print("Gain calliberation On")
        elif scale:
            print("Normal scale On")
            self.scale_flag = True
        else:
            print("Raw image On")


    def LDOConf(self, voltages):
        '''
        Takes in voltage values used to set LDOs on board and configures
        byte stream to send to SPI_master module.
        ----------------------------------------------------------
        Variables

        SlaveSel:  1-hot encoded mask for chip select
        Addr:      8 bit pattern for DAC addr. Ordered as 0,0,0...A2,A1,A0
        Voltage:   8 bit pattern to control LDO voltage. Ordered from Msb -> Lsb
        Mode:      Currently unused in SPI_master. Can be used to change SPI mode later
                   for different CPOL and CPAH configurations.
        ------------------------------------------------------------
        Output to SPI_master
        
        words are formatted as { SS | Mode | Voltage | Addr } in python
        FPGA flips byte order so words recieved as { Addr | Voltage | Mode | SS } by SPI_master
        '''
    
    
        # SPI order as { SS | Mode | Voltage | Addr } per row
        SPI = np.array([
            # CS_1
            '00000001', '00000000', '________', '00000000',
            '00000001', '00000000', '________', '00000001',
            '00000001', '00000000', '________', '00000010',
            '00000001', '00000000', '________', '00000011',
            # CS_2
            '00000010', '00000000', '________', '00000000',
            '00000010', '00000000', '________', '00000001',
            '00000010', '00000000', '________', '00000010',
            '00000010', '00000000', '________', '00000011',
            # CS_3
            '00000100', '00000000', '________', '00000000',
            '00000100', '00000000', '________', '00000001',
            '00000100', '00000000', '________', '00000010',
            '00000100', '00000000', '________', '00000011'
        ])

        
        # get 0->255 int that gives voltage out 
        voltages = np.rint((voltages/5)*256).astype(int)    
        # convert int to 8'b binary representation
        for i in range(len(voltages)):
            SPI[4*i+2] = np.binary_repr(voltages[i], width=8)
        
        # convert to bytes to send out to FPGA
        byte_pattern = bytes(int(SPI[i],2) for i in range(len(SPI)))
        self.write(self.address['ldo_spi'], byte_pattern)


    def CISConf(self, data):
        self.wire_in(self.address['chip_rst'], 0x01)
        self.wire_in(self.address['chip_rst'], 0x00)
        arr = np.array(list(data[0]), dtype='|S1')
        for i in range(1,len(data),1):
            arr = np.vstack((arr,np.array(list(data[i]), dtype='|S1')))
        arr=arr.reshape(-1,32)
        # correct inverted captured image
        arrange = np.flip(np.arange(32*3),axis=0) # vertical flip
        data = arr[:3,:].flatten()
        data = data[arrange].reshape(-1,32)
        arr = np.vstack((data,arr[3,:]))

        arrange = np.arange(32).reshape(4,-1)[[3,2,1,0],:]
        arr = arr[:,arrange.flatten()]

        p = arr.flatten().tobytes()
        pattern = bytearray(int(p[i:i+8],2) for i in range(0, len(p), 8))
        print(len(pattern))
        self.write(self.address['cis_spi'], pattern)


    def ImgMapCal(self):
        if os.path.exists(self.img_map_file):
            imgmap = np.load(self.img_map_file)
            print("Loading exist image mapping data...")
        else:
            imgmap = np.arange(self.tab*self.row*self.col*self.ch).reshape(-1,3)
            #imgmap = np.arange(self.tab*self.row*107*self.ch).reshape(-1,3)
            imgmap = np.concatenate(np.vsplit(imgmap,self.row*self.tab),axis=1)
            imgmap = imgmap.transpose().reshape(-1,self.col*self.ch*self.tab)
            #imgmap = imgmap.transpose().reshape(-1,107*self.ch*self.tab)
            np.save(self.img_map_file,imgmap)
            print("Calculating image mapping data...")

        # one column shift in bucket 2
        # h,w=imgmap.shape
        # imgmap[:,int(w/2):w-1] = imgmap[:,int(w/2)+1:w]

        return imgmap

    def int2gray(self,n):
        n ^= (n>>1)
        return bin(n)[2:]


    def ImgGrayMapCal(self):
        if os.path.exists(self.img_graymap_file):
            imgmap = np.load(self.img_graymap_file)
            print("Loading exist image mapping data...")
        else:        
            imgmap = np.arange(self.tab*self.row*self.col*self.ch).reshape(-1,3)
            #imgmap = np.arange(self.tab*self.row*107*self.ch).reshape(-1,3)
            imgmap = np.concatenate(np.vsplit(imgmap,self.row*self.tab),axis=1)
            imgmap = imgmap.transpose().reshape(-1,self.col*self.ch*self.tab)
            gray = np.concatenate(([int(self.int2gray(i),2) for i in range(256)],[int(self.int2gray(i),2)+256 for i in range(320-256)]))
            imgmap = imgmap[gray,:]

            np.save(self.img_graymap_file,imgmap)
            print("Calculating image mapping data...")


        # one column shift in bucket 2
        h,w=imgmap.shape
        imgmap[:,int(w/2):w-1] = imgmap[:,int(w/2)+1:w]

        return imgmap

    def MaskMapCal(self,width=512, ch_num=16):
        if False:
        # if os.path.exists(self.mask_map_file):
            imgmap = np.load(self.mask_map_file)
            print("Loading exist mask mapping data...")
        else:
            a = np.arange(width)
            # a = np.concatenate((a[64:],a[:64]))
            a = a.reshape(ch_num,-1)
            # ch_map = np.arange(ch_num)
            ch_map = [8,  9, 10, 11, 12, 13, 14, 15, 
                      0,  1,  2,  3,  4,  6,  5,  7]#, 16, 17, 18, 19]
            a[:,:] = a[ch_map,:]
            a = a.flatten()
            ch_width = int(width/ch_num)
            imgmap = a[0::ch_width]
            for i in range(1,ch_width):
                imgmap = np.concatenate((imgmap, a[i::ch_width]))
            np.save(self.mask_map_file,imgmap)
            print("Calculating mask mapping data...")
        return imgmap

    def average_cal(self, time=100, save=False, dir='./image/ave/'):
        """
        calculate the average value of image
        """
        if not os.path.exists(dir):
            os.mkdir(dir)

        black_img = np.zeros([self.row,self.col*self.ch*self.tab])

        for i in range(time):
            black_img += self.arrange_raw(self.imread())
        black_img /= time
        print(black_img)
        np.save(self.black_img_file,black_img)

    def black_cal(self, time=100):
        """
        Cover camera lens and calculate the average value of black level
        """
        black_img = np.zeros([self.row,self.col*self.ch*self.tab])
        for i in range(time):
            black_img += self.arrange_raw(self.imread())
        black_img /= time
        print(black_img)
        np.save(self.black_img_file,black_img)


    def gain_cal(self, num_samps=100):
        cal_mat_gain = np.zeros([self.row,self.col*self.ch*self.tab],dtype=np.float32)
        if (os.path.exists(self.black_img_file)==False):
            # print(~os.path.exists("./image/black_level_calib.npy"))
            print("Perform black level calibration first")
        else :
            for i in range(num_samps):
                cal_mat_gain += self.arrange_raw(self.imread())

            cal_mat_gain = cal_mat_gain/num_samps
            cal_mat_gain = self.black_img - cal_mat_gain
            col_gain_mean = np.mean(cal_mat_gain,0)
            med_gain = np.median(col_gain_mean[10:300])
            coeff_mat = med_gain/col_gain_mean
            print(coeff_mat)
            np.save(self.gain_mat_file,coeff_mat)

    def gain_cal2d(self,num_samps=100):
        bright_img = np.zeros([self.row,self.col*self.ch*self.tab],dtype=np.float32)
        if (os.path.exists(self.black_img_file)==False):
            # print(~os.path.exists("./image/black_level_calib.npy"))
            print("Perform black level calibration first")
        else :
            for i in range(num_samps):
                bright_img += self.arrange_raw(self.imread())
            
            # #Black calibrated averaged output 
            # bright_img  = self.black_img - bright_img/num_samps
            # bright_img[bright_img<0] = 0
            # med_gain    = np.median(bright_img[:240,:])
            # gain_arr    = med_gain/bright_img
            # print(med_gain,gain_arr)
            # np.save(self.gain_cali_file,gain_arr)

        np.save(self.bright_img_file, bright_img/num_samps)

    def param_set(self, addr, value):
        self.wire_in(self.address['param_en'], 0)
        self.wire_in(self.address['param_addr'], addr)
        self.wire_in(self.address['param_in'], value)
        self.wire_in(self.address['param_en'], 1)
        self.wire_in(self.address['param_en'], 0)
        if self.wire_out(self.address['param_out']) != value:
            logging.error("Parameter set failed. A.{}/V.{}".format(addr,value))
            exit(1)

    def readout_reset(self):
        self.wire_in(self.address['chip_rst'], 0x01)
        self.wire_in(self.address['chip_rst'], 0x00)

    def wire_in_check(self, addr, value):
        self.wire_in(addr, value)
        self.wire_check(addr, value)

    def wire_check(self, addr, value):
        self.wire_in(self.address['wire_check_set'], addr)
        cnt = 0
        #while self.wire_out(self.address['wire_check_o']) != value:
        #    self.wire_in(addr, value)
        #    cnt += 1
        #    if(cnt > 10):
        #        logging.error("Wire check failed. A.{}/V.{}".format(addr,value))
        #        exit(1)

    def memory_test(self, msk_size=320*64,msk_num=10):
        # set mask number
        self.wire_in(self.address['pat_num'], msk_num)
        self.wire_in(self.address['mem_pat_num'], msk_num)
        # memory readback mode
        self.wire_in(self.address['mem_mode'], 0x00)
        # reset
        self.wire_in(self.address['mk_routine_rst'], 0x04)
        # write mode
        self.wire_in(self.address['mk_routine_rst'], 0x02)

        times = msk_size*msk_num
        target = bytearray(os.urandom(times))
        result = bytearray(times)

        self.block_write(self.address['mem_wr'], self.BLOCK_SIZE, target)

        # read mode
        self.wire_in(self.address['mk_routine_rst'], 0x04)
        self.wire_in(self.address['mk_routine_rst'], 0x01)
        self.block_read(self.address['mem_rd'], self.BLOCK_SIZE, result)

        for i in range(times):
            if result[i] != target[i]:
                logging.error("Memory Test failed. Total:{} No.{}". \
                              format(times,i))
                for j in range(10):
                    logging.error("Memory Test failed. R:{:02x}/T:{:02x}". \
                                  format(result[i+j],target[j]))
                exit(1)
        logging.info("Memory Test passed.")





    def fmaskupload(self, file_name,dummy=False):
        assert isinstance(file_name, str), "Need a file name"
        assert file_name.lower().endswith('.bmp'), "Wrong file type, should be .bmp"

        pattern = self.loadMask(file_name)
        result = bytearray(len(pattern))

        # reset
        self.wire_in(self.address['mk_routine_rst'], 0x04)
        # write mode
        self.wire_in(self.address['mk_routine_rst'], 0x02)
        
        if(dummy):
            pass
        else:
            self.block_write(self.address['mem_wr'], self.BLOCK_SIZE, pattern)

        # read mode
        self.wire_in(self.address['mk_routine_rst'], 0x01)

        # check ddr3 calibration finished.
        while True:
            self.dev.UpdateTriggerOuts()
            if self.istriggered(self.address['fifo_flag'], 0x08):
                break;
            else:
                logging.info("DDR3 calibrating...")
                time.sleep(1)


        # memory readback mode
        #self.wire_in(self.address['mem_mode'], 0x00)
        #self.wire_in(self.address['mk_routine_rst'], 0x04)
        #self.wire_in(self.address['mk_routine_rst'], 0x01)
        #length = self.block_read(self.address['mem_rd'], self.BLOCK_SIZE, result)
        #logging.info("Read back length: {}".  format(length))

        #for i in range(len(pattern)):
        #    if result[i] != pattern[i]:
        #        logging.error("Memory Test failed. Total:{} No.{}". \
        #                      format(len(pattern),i))
        #        for j in range(10):
        #            logging.error("Memory Test failed. R:{:02x}/T:{:02x}". \
        #                          format(result[i+j],pattern[i+j]))
        #        exit(1)
        #logging.info("Memory Test passed.")

        # memory mask upload mode
        self.wire_in(self.address['mem_mode'], 0x01)
        self.wire_in(self.address['mk_routine_rst'], 0x04)
        self.wire_in(self.address['mk_routine_rst'], 0x01)


    def loadMask(self, filename, row=320, ch_num=16):
        """
        row: 2D image row number
        """

        file = open(filename, 'rb') #open bmp file
        file.seek(10,0)
        offset = int.from_bytes(file.read(4), 'little') #where the first pixel starts
        file.seek(18, 0)
        width = int.from_bytes(file.read(4), 'little')
        file.seek(22,0)
        height = int.from_bytes(file.read(4), 'little')

        print("2D image row size: {}".format(row))
        print("mask data size: {}x{}".format(height, width))
        print("mask numbers: {:f}".format(height/row))

        # img = cv2.imread(filename,CV2.IMREAD_GRAYSCALE).astype(bool)

        print(height%row)
        assert height%row == 0, "Wrong mask data size"
        imageSize = int(width * height / 8) #in bytes. Using 1 bit per pixel (black or white)

        pattern = bytearray(imageSize)
        mask = bytearray(imageSize)

        file.seek(offset, 0)
        mask = file.read(imageSize)
        file.close()

        toBin = BitArray(bytes=mask).bin
        toArray = np.array(list(toBin),dtype='|S1').reshape(height, width)
        p = toArray[:, self.mkmapping]
        p = p.flatten().tobytes()
        pattern = bytearray(int(p[i:i+8],2) for i in range(0, len(p), 8))

        # resize bytearray to fit blockwrite length
        size = (int(imageSize/512)+1)*512 - imageSize
        logging.info("Added Size: {}".format(imageSize/512.))
        #extra = pattern + pattern + pattern+ pattern+ pattern+ pattern+ pattern+ pattern+ bytearray(size)
        extra = pattern+ bytearray(size)
        print("data arragement finished.")

        return pattern
        #return extra



    def arrange1(self, image):
        col, row, tab, ch = 108, 320, 2, 3

        r_margin = np.full((tab, col*ch), 2**16-1)
        c_margin = np.full((row*tab+tab, 2), 2**16-1)
        temp=np.frombuffer(image, dtype=np.uint16)[:tab*row*col*4].reshape(-1,4)
        img=np.concatenate(np.vsplit(temp[:,:ch],row*tab),axis=1).transpose().reshape(-1,col*ch)
        img=np.concatenate((img, r_margin), axis=0)
        img=np.concatenate((c_margin, img), axis=1)

        i = np.arange(row*tab+tab)
        i = np.concatenate((i[0::tab], i[1::tab]))
        #return img[i,:]
        return self.image_scale(img[i,:])

    def arrange(self, image):
        #temp=np.frombuffer(image, dtype=np.uint16)[:tab*row*col*4].reshape(-1,4)
        #img=np.concatenate(np.vsplit(temp[:,:ch],row*tab),axis=1).transpose().reshape(-1,col*ch*tab)
        #img=np.concatenate(np.vsplit(temp[:,:ch],row*tab),axis=1).transpose().reshape(-1,col*ch)
        # get image data
        #temp=np.frombuffer(image, dtype=np.uint16)[:self.tab*self.row*self.col*4]
        temp=np.frombuffer(image, dtype=np.uint16)
        # delete dummy data
        temp = temp.reshape(-1,4)[:,:self.ch].flatten()
        # mapping data
        img = temp[self.mapping]
        #print(" ".join('{:08b}'.format(x) for x in img[1,4:14]))
        #print(img[1][:10])

        logging.debug(np.mean(img[:,6:312]))
        # logging.debug(" ".join('{:014b}'.format(x) for x in img[1,4:14]))
        
        # correct left right flip in each individual bucket        
        img_yflip = np.zeros(img.shape)
        img_yflip[:,:324] = img[:,:324][:,::-1]
        img_yflip[:,324:] = img[:,324:][:,::-1]
        
        img_yflip = img

        if(self.gain_flag):
            logging.debug("gain")
            return self.image_scale2(img_yflip)
            #return self.image_scale2(img)            
        elif(self.gain_scale_flag):
            logging.debug("gain scale")
            return self.image_scale4(img_yflip)
            #return self.image_scale4(img)            
        elif(self.black_flag):
            logging.debug("black")
            return self.image_scale1(img_yflip)
            #return self.image_scale1(img)            
        elif(self.black_scale_flag):
            logging.debug("black scale")
            return self.image_scale3(img_yflip)
            #return self.image_scale3(img)            
        elif(self.scale_flag):
            logging.debug("normal scale")
            return self.image_scale(img_yflip)
            #return self.image_scale(img)            
        else:
            logging.debug("raw")
            return img_yflip
            #return img
            
    def arrange_raw(self, image, rows):
        taps, colsPerADC, ADCsPerCh, ch = 2, 2, 20, 12
        cols = colsPerADC*ADCsPerCh*ch


        img = np.frombuffer(image,dtype=np.uint8) 

        img2=img.reshape(-1,8,4)[:,:,::-1]
        img3=np.unpackbits(img2,axis=2).reshape(-1,256) # recover the bits as stored in fifo



        img4 = img3[:,16:] # get rid of padded bits

        noch    = 12 # total number of channels
        nob     = 12 # number of bits per channel
        img5 = img4.reshape(-1,nob,noch,20)         # convert into 12 separate data channels
        # img6 = np.moveaxis(img5,[1,2,3],[3,1,2])[:,:,::-1]    
        img6 = np.moveaxis(img5,1,3)[:,:,:,::-1]
        # img6 = img6[:,:,::-1]    
        # at this point
        # AXES: 
        #    0: Each conversion (#rows x #taps x #cols/ADC)
        #    1: each digital channel
        #    2: columns serialized by each channel
        #    3: the bits for each column

        img7_shape = np.array(img6.shape); img7_shape[-1] = 16
        img7    = np.zeros(img7_shape,dtype=bool)
        img7[:,:,:,-12:] = img6.copy()
        # img8 = np.packbits(img7,axis=-1).view(np.uint16).reshape(img7_shape[:-1])
        img8    = np.packbits(img7,axis=-1).astype(np.uint16)
        img8    = img8[:,:,:,0]*256+img8[:,:,:,1]
        # col_map = np.arange(20)
        # col_map = [19,9,14,4,18,8,13,3,16,6,11,1,17,7,12,2,15,5,10,0]
        col_map = [0, 4, 12, 8, 16, 2, 6, 14, 10, 18, 1, 5, 13, 9, 17, 3, 7, 15, 11, 19]

        ch_map  = [0,1,2,6,5,3,4,7,8,9,10,11]
        img8    = img8[:,ch_map,:]
        img9 = img8[:,:,[col_map]].reshape(rows,taps,colsPerADC,ADCsPerCh*ch)


        img10 = np.zeros((rows,taps,colsPerADC*ADCsPerCh*ch),dtype=np.uint16)
        img10[:,:,0::2] =   img9[:,:,0,:]
        img10[:,:,1::2] =   img9[:,:,1,:]

        img11 = np.concatenate([img10[:,0,:],img10[:,1,:]],axis=1)
        
        return img11    


    def arrange_raw_T7(self,image,rows):
        tics = [['img0',time.time()]]
        ##rows:480, col:680, taps:2
        taps, colsPerADC, ADCsPerCh, ch = 2, 2, 20, 17
        cols = colsPerADC*ADCsPerCh*ch

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
        img4_1 = img4_1.reshape(-1,(int(np.shape(img4_1)[1]*15/20)),20)
        img4_1 = np.moveaxis(img4_1,0,1)
        img4_1 = img4_1.reshape(-1,340)
        tics.append(['img4',time.time()])

        noch    = 17 # total number of channels
        nob     = 12 # number of bits per channel
        img5 = img4_1.reshape(-1,nob,noch,20)         # convert into 12 separate data channels
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

        # img7_shape       = np.array(img6.shape); img7_shape[-1] = 16
        # img7             = np.zeros(img7_shape,dtype=bool)
        # img7[:,:,:,-12:] = img6
        # pad_loc          = np.zeros((4,2),dtype=int);pad_loc[-1,0]=16-nob
        # img7             = np.pad(img6,[[0,0],[0,0],[0,0],[4,0]])
        img7    = img6
        tics.append(['img7',time.time()])
        img8    = np.packbits(img7,axis=-1).astype(np.uint16)
        tics.append(['img8_packbits',time.time()])
        # img8    = img8[:,:,:,0]*256+img8[:,:,:,1]
        img8      = (img8[:,:,:,0]<<4).astype(np.uint16) + (img8[:,:,:,1]>>4).astype(np.uint16)
        # col_map = np.arange(20)
        # col_map = [19,9,14,4,18,8,13,3,16,6,11,1,17,7,12,2,15,5,10,0]
        col_map = [0, 4, 12, 8, 16, 2, 6, 14, 10, 18, 1, 5, 13, 9, 17, 3, 7, 15, 11, 19]

        ch_map  = np.arange(17)
        ch_map  = [0,1,2,3,4,5,6,7,11,10,8,9,12,13,14,15,16]

        img8    = img8[:,ch_map,:]
        img9 = img8[:,:,[col_map]].reshape(rows,taps,colsPerADC,ADCsPerCh*ch)
        tics.append(['img9',time.time()])


        img10 = np.zeros((rows,taps,colsPerADC*ADCsPerCh*ch),dtype=np.uint16)
        img10[:,:,0::2] =   img9[:,:,0,:]
        img10[:,:,1::2] =   img9[:,:,1,:]
        tics.append(['img10',time.time()])

        img11 = np.concatenate([img10[:,0,:],img10[:,1,:]],axis=1)
        tics.append(['img11',time.time()])

        img12 = img11

        # 2x ODDCOL_EN time
        # img12 = np.zeros(img11.shape, dtype=np.uint16)
        # img12[:,1:680:2] = img11[:,0:680:2]
        # img12[:,0:680:2] = img11[:,680::2]
        # img12[:,681::2] = img11[:,1:680:2]
        # img12[:,680::2] = img11[:,681::2]

        # 2x ROWADD cycles
        img12 = np.zeros(img11.shape, dtype=np.uint16)
        img12[0::2,1:680:2] = img11[:240,0:680:2]
        img12[1::2,1:680:2] = img11[:240,680::2]
        img12[0::2,0:680:2] = img11[240:,0:680:2]
        img12[1::2,0:680:2] = img11[240:,680::2]

        img12[0::2,681::2] = img11[:240,1:680:2]
        img12[1::2,681::2] = img11[:240,681::2]
        img12[0::2,680::2] = img11[240:,1:680:2]
        img12[1::2,680::2] = img11[240:,681::2]
        
        # for i in range(1,len(tics)):
        #     logging.info("arrange_raw_t7 {}:{}".format(tics[i][0],(tics[i][1]-tics[i-1][1])*1000))

        return img12

    def arrange_adc2(self, image, rows=480, ADCsPerCh=20):
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

        # img3 = np.unpackbits(img2,axis=2).reshape(-1,256*4).astype(bool)
        # tics.append(['img3',time.time()])
        # img6 = img3[:,self.adc2_map_1row]
        # tics.append(['img6',time.time()])
        # img6=img6.reshape(-1,ch,ADCsPerCh,nob)
        # tics.append(['img6_reshape',time.time()])

        # at this point
        # AXES: 
        #    0: Each conversion (#rows x #taps x #cols/ADC)
        #    1: each digital channel
        #    2: columns serialized by each channel
        #    3: the bits for each column

        img7_shape = np.array(img6.shape); img7_shape[-1] = 1; img7_shape[2]=ADCsPerCh
        img7    = np.zeros(img7_shape,dtype=bool)
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

    def image_scale6(self,image,gain=False,black=True,dynamic=False,max_scale = 3000):
        
        [row,col,tab] = [480, 680, self.tab]

        x1 = self.black_img.astype(np.float32)
        y1 = np.median(x1)

        y2 = np.zeros((row,col*tab)) # target median

        if(gain):
            # assert black==True, "Black cal must be ON if gain needs to be ON"
            x2 = self.bright_img.astype(np.float32)
            y2_left  = np.median(x2[:,30:col-10].flatten()) # target median left tap
            y2_right = np.median(x2[:,col+30:2*col-10].flatten()) # target median right tap

            y2[:,:col] = y2_left
            y2[:,col:] = y2_right

            # y2 = np.median(x2)
            [num,den] = [(y2-y1),(x2-x1)]
            num[den==0] = 0
            den[den==0] = np.inf
            m = num/den
            c = y1-num/den*x1

            logging.debug(np.mean(m[100:110,100:110]))
            img = m*image + c
            img = y1 - img
            img[img<0] = 0

        elif(black):
            img = self.black_img - image
            img[img<0] = 0
        elif(dynamic):
            percentile = 5
            min_lvl = np.percentile(np.concatenate((image[:,:320],image[:,324:644]),axis=1),5)
            max_lvl = np.percentile(image,95)
            img = 2**16-1 - (np.clip(image, min_lvl, max_lvl)-min_lvl)*(2**16-1)/(max_lvl-min_lvl)
            return img.astype(np.uint16)
        else:
            img = image.astype(np.float32)
        # Clip values between 0 and 3000 and scale to 0 to 2**16-1
        img = (np.clip(img,0,max_scale)*(2**16-1)/max_scale).astype(np.uint16)

        return img


    def imread(self):
        # container = bytearray(self.frame_length)
        cnt = 0
        cnt1=1
        #self.trigger_in(self.address['trigger'], 0)
        while True:

            #time.sleep(0.05)
            self.dev.UpdateTriggerOuts()
            if self.istriggered(self.address['fifo_flag'], 0x02):
                logging.debug("fifo_cnt: "+str(self.wire_out(self.address['fifo_cnt'])))
                self.dev.UpdateTriggerOuts()
                self.read(self.address['image'], self.adc1_container)
                #print("".join('{:02x}'.format(x) for x in container[:8]))
                #print(" ".join('{:08b}'.format(x) for x in container[:8]))
                #toBin = BitArray(bytes=container).bin
                #print(toBin[:16]+" "+toBin[16:32]+" "+toBin[32:48]+" "+toBin[48:64])
                #self.trigger_in(self.address['trigger'], 0)
                return self.adc1_container

            cnt += 1
            #self.state_check();
            if cnt % 1000 == 999:
                bt=self.wire_out(self.address['fifo_cnt'])
                print("fifo_cnt: "+str(bt))
                print(cnt1)
                cnt1 += 1
                print("empty: "+str(self.istriggered(self.address['fifo_flag'], 0x04)))
                print("prg_full: "+str(self.istriggered(self.address['fifo_flag'], 0x02)))
                print("full: "+str(self.istriggered(self.address['fifo_flag'], 0x01)))
                #self.read(self.address['image'], container)

    def adc2_read(self,NSUB):
        cnt = 0
        self.dev.UpdateTriggerOuts()
        while True:
            if self.istriggered(self.address['fifo_flag'], 0x10):
                self.read(self.address['adc2_rd'],self.adc2_container)
                self.dev.UpdateTriggerOuts()

            cnt+=1
            if(cnt%1000==999):
                logging.info('stuck reading adc2 cnt:{:04d}'.format(cnt))
            # t6.read(0xa3,pread)
            return self.adc2_container



    def imsave(self, image, dir, filename,full=False):
        if not os.path.exists(dir):
            os.mkdir(dir)
        #pattern =re.compile(".png")
        #if pattern.match(filename):

        if filename.find(".png")!=-1:
            #print(image.dtype)
            if full:
                numpngw.write_png(dir+filename,image)
            else:
                #scipy.misc.imsave(dir+filename,image)
                cv2.imwrite(dir+filename, image)
        #pattern =re.compile(".npy")
        #if pattern.match(filename):
        if filename.find(".npy")!=-1:
            #print(image.dtype)
            np.save(dir+filename,image)
        if filename.find(".npz")!=-1:
            #print(image.dtype)
            np.savez_compressed(dir+filename,img=image)



if __name__ == "__main__":

    #bitfile = "./bitfile/t4/Reveal_Top_multi3.bit"
    bitfile="bitfile/Reveal_Top_3.bit"
    # bitfile="bitfile/Reveal_Top.bit"

    t6=T6(bitfile)
    # t6.param_set(self.param['Select'], 0x80000000)  # disable slave mode
    # t6.fmaskupload("./maskfile/t4_merge.bmp")
    # t6.set_exposure(10000)
    # t6.set_pattern_num(10)

    input("Press enter after SPI")

    t6.UploadMaskDummy('',10)
    t6.SetMaskParam(5,2)
    t6.SetExposure(2000)
    t6.readout_reset()
    t6.gain_flag = False
    t6.black_flag = False
    t6.black_scale_flag = False
    t6.imshow()
