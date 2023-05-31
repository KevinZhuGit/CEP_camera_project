import numpy as np
import pandas as pd
import random
import cv2
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.pyplot import imshow

import os
import glob
import logging
import time

from scipy.optimize import curve_fit
import scipy.io
from scipy.io import loadmat


# logging.basicConfig(format='%(levelname)-6s[%(filename)s:%(lineno)d] %(message)s'
#                     ,level=logging.DEBUG)


class camModel():
    def __init__(self,H=320,W=648):
        logging.info("characterize")
        self.height = H
        self.width  = W

    def per_pixel_stats(self, path):
        """
        Returns per pixel mean, std and variance given 3D matrices 
        (number of images captured per exposure x height x width) 
        for a list of exposure times

        Assumes: 
        1. exposure times and filenames of 3D matrices are 1:1 mappings
        2. input data is in MATLAB .mat format

        Parameters:
            path (string)                : directory containing data
            filenames (list of strings)    : list of filenames -- one filename per exposure
            height (int)                : height of image in number of pixels
            width (int)                    : width of image in number of pixels

        Returns:
            avg_m (ndarray): 2D matrix (number of exposures x width x height matrix) 
                           of mean value per pixel
            std_m (ndarray): 2D matrix (number of exposures x width x height matrix) 
                           of std value per pixel
            var_m (ndarray): 2D matrix (number of exposures x width x height matrix) 
                           of variance per pixel
        """

        height = self.height
        width  = self.width

        # List of filenames in sorted order, smallest to largest exposure time
        fnames = glob.glob(path + '/*.mat')
        fnames.sort()
        filenames = [f.split('/')[-1].replace('.mat', '') for f in fnames]        


        self.shape = (len(filenames), height, width)
        shape = self.shape
        avg_m = np.zeros(shape).astype(np.float32)
        std_m = np.zeros(shape).astype(np.float32)
        var_m = np.zeros(shape).astype(np.float32)

        for i, f in enumerate(filenames):
            mat = loadmat(path+f)['allImgs'] # TODO: Needs to be modified based on input datatype
            mat[mat < 0] = 0 # Rahul says all negative values are just set to zero
            avg_m[i,:,:] = mat.mean(axis=0)
            std_m[i,:,:] = mat.std(axis=0)
            var_m[i,:,:] = np.square(mat.std(axis=0))

        self.exposures = np.array([float(f)*4/1e3 for f in filenames])
        self.avg_m, self.std_m, self.var_m = avg_m.copy(), std_m.copy(), var_m.copy()
        self.filenames = filenames

        return avg_m, std_m, var_m

    def updatePixelStats(self, avg_m, std_m, var_m):
        """
        Update internal pixel variables
        """
        self.avg_m, self.std_m, self.var_m = avg_m.copy(), std_m.copy(), var_m.copy()

    def piecewiseSystemModel(self, t, gain_dn, bl, sat_time, fwc, tol1, tol2):
        """
        Returns a piecewise function modeling a linear system response

        Parameters:
            t (ndarray): array of exposure times in us
            gain_dn (float): gain of model
            bl (float): black point of model
            sat_time (float): time of saturation of model
            fwc (float): full well capacity of model
            tol1 (float): tolerance for first piecewise joint
            tol2 (float): tolerance for second piecewise joint

        Returns:
            (ndarray): a piecewise function of our linear camera model
        """
        return np.piecewise(
            t, 
            [(t < tol1), (t < sat_time) & (t >= tol1), (t >= sat_time)], 
            [ lambda x: bl,
              lambda x: (-1.0)*gain_dn*x+bl-tol2, 
              lambda x: (-1.0)*gain_dn*sat_time+(-1.0)*tol2*tol1+bl-tol2-fwc
            ]
            )

    def curvefitSystemModel(self,x,gain,offset,sat_time):
        """
        Returns ideal value for linear system model
    
        Parameters:
            x (ndarray)     : exposure time
            gain (float)    : gain value
            offset(float)     : offset for linear fit
            sat_time(float) : saturation time for which pixel is saturated

        Returns:
            pixel output with linear response and saturation limit
        """

        x = np.asarray(x)
        y = gain*x + offset
        y[x>sat_time] = gain*sat_time + offset

        return y

    def applyCurvefitSystemModel(self,pixels,H=320,W=648):
        """
            Returns gain model parameters such as DN vs exp_time slope, saturation time and offset for a line fit.
        
        Parameters:
            pixels : Is a list of (x,y) co-ordinates

        Returns:
            gainModelParameters: the gain parameters calculated at every location (x,y)

        """
        exp     = self.exposures
        avgImgs = self.avg_m

        #Parameters to help curve fit
        gainModelIC = [-2.7,3000,400]
        gainMin    = [-40,1500,100]
        gainMax    = [-0.5,5000,1000]


        nuParam     = 3
        #optimized parameters will be stored here
        gainModelPara = np.zeros((H,W,nuParam))

        i = 0
        for pix in pixels:
            (r,c) = pix
            i = i+1

            logging.debug("processing row:{:03d} col:{:03d}".format(r,c))
            print("\rprocessing row:{:03d} col:{:03d} | {:05.2f}% | ".format(r,c,i/len(pixels)*100), end='')

            try:
                tic = time.time()
                gainModelPara[r,c,:], pcov =curve_fit(self.curvefitSystemModel,exp[:],avgImgs[:,r,c],\
                    p0=gainModelIC,bounds=(gainMin,gainMax))
                tac = time.time()
                print("time:{:07.2f}ms".format((tac-tic)*1000),end="")
            except:
                gainModelPara[r,c,:] = gainModelPara[r-1,c-1,:]
                print("\nSkipping pixel")
            

        logging.debug("Done modelling")
        self.gainModelPara = gainModelPara
        self.setTargetGainPara()

        return self.gainModelPara

    def loadCurvefitSystemModel(self,gainModelFile,udpateTarget=True):
        """
        returns self.gainModelPara
        Parameter:
            gainModelFile: .npy file that contains array of size HxWx3        
        """
        assert os.path.isfile(gainModelFile)
        gainModelPara = np.load(gainModelFile)

        assert np.array_equal(gainModelPara.shape, [self.shape[1],self.shape[2],3]), gainModelPara.shape
        self.gainModelPara = gainModelPara.copy()

        if(udpateTarget):
            self.setTargetGainPara()

        return self.gainModelPara

    def setTargetGainPara(self,roi=[[0,0],[240,320]],gainModelPara=None):
        if(gainModelPara==None):
            gainModelPara = self.gainModelPara

        x1,y1 = roi[0]
        x2,y2 = roi[1]

        gainModelPara[gainModelPara==0] = np.nan
        self.targetSlope  = np.nanmin(gainModelPara[x1:x2,y1:y2,0])
        self.targetOffset = np.nanmax(gainModelPara[x1:x2,y1:y2,1])

        return self.targetSlope,self.targetOffset

    def calculateFittedValueFull(self,gainModelPara=None):
        """
            Returns adjusted value of all the input data
            based on the gain model
        Parameters:
            gainModelPara:  Is of dimension H x W x 3

        Returns
                
        """
        if(gainModelPara ==None):
            gainModelPara = self.gainModelPara.copy()

        gainModelPara[gainModelPara==0] = np.nan

        # Target for model fitting
        targetSlope,targetOffset = self.targetSlope,self.targetOffset
        # targetSlope  = np.nanmin(gainModelPara[:,:,0])
        # targetOffset = np.nanmax(gainModelPara[:,:,1])

        currentSlope  = gainModelPara[:,:,0]
        currentOffset = gainModelPara[:,:,1]

        y = np.zeros(self.shape,dtype=np.float32)

        for i in range(self.shape[0]):
            y[i,:,:] = (self.avg_m[i,:,:] - currentOffset)*targetSlope/currentSlope + targetOffset

        self.avg_calibrated = y
 
        return self.avg_calibrated

    def calculateFittedImage(self,y,gainModelPara=None):
        """
            Returns calirated image

        Parameters:
            y(2darray) : Is 2d array of size HxW or equal first two axes of gainModelPara
            gainModelPara() : Is array fo size HxWx3

        Returns:
            y':         calibrated y value based on the gainModelPara
        """

        if(gainModelPara ==None):
            gainModelPara = self.gainModelPara.copy()

        gainModelPara[gainModelPara==0] = np.nan

        # Target for model fitting
        targetSlope,targetOffset = self.targetSlope,self.targetOffset
        # targetSlope  = np.nanmin(gainModelPara[:,:,0])
        # targetOffset = np.nanmax(gainModelPara[:,:,1])

        currentSlope  = gainModelPara[:,:,0]
        currentOffset = gainModelPara[:,:,1]

        # for pix in pixels:
        y_cal       = np.zeros(y.shape)

        y_cal[:,:]  = (y - currentOffset)*targetSlope/currentSlope + targetOffset


        return y_cal

    def calcualteFittedPixel(self,y,pixels,gainModelPara=None):
        """
            Returns calirated image

        Parameters:
            y(1darray)          : Is 1d array of values of pixels mentioned in pixels array
            pixels(2d array)    : Is array of pixel locations (x,y)
            gainModelPara()     : Parameters used for linear fitting calculated for the whole array

        Returns:
            y'                  : calibrated y value based on the gainModelPara
        """
        if(gainModelPara ==None):
            gainModelPara = self.gainModelPara.copy()

        # check if taget is defined earlier
        try:
            self.targetSlope
            self.targetOffset
        except:
            self.setTargetGainPara()

        gainModelPara[gainModelPara==0] = np.nan

        # Target for model fitting
        targetSlope,targetOffset = self.targetSlope,self.targetOffset


        pixels      = np.asarray(pixels)
        assert pixels.shape[0] == len(y)

        # for pix in pixels:
        y_cal       = np.zeros(y.shape)
        for i in range(len(y)):
            (x,y) = pixels[i,:]
            currentSlope, currentOffset  = gainModelPara[x,y,0:2]
            y_cal[i] =  (y - currentOffset)*targetSlope/currentSlope + targetOffset

        return y_cal