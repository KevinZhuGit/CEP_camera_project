import os, sys
import glob
import re
import logging
import numpy as np
from scipy import misc
from bitstring import BitArray
import PIL
from PIL import Image, ImageOps
import matplotlib.pyplot as plt

logging.basicConfig(format='%(levelname)-6s[%(filename)s:%(lineno)d] %(message)s'
                    #,level=logging.DEBUG)
                    ,level=logging.INFO)


def PTCImgCal(BlackImg, SrcImg):
    """
    calculate rms noise for t4 image
    """
    assert isinstance(BlackImg, np.ndarray), 'Wrong data type'
    assert isinstance(SrcImg, np.ndarray), 'Wrong data type'
    assert BlackImg.shape==SrcImg.shape, "Image size is different"
    start = 6
    end = 318
    blk_b1 = BlackImg[:,start:end]
    blk_b2 = BlackImg[:,(324+start):(324+end)]
    img_b1 = SrcImg[:,start:end]
    img_b2 = SrcImg[:,(324+start):(324+end)]
    h,w = blk_b1.shape
    Np = h*w
    blk_b1_avg = np.mean(blk_b1)
    blk_b2_avg = np.mean(blk_b2)
    img_b1_avg = np.mean(img_b1)
    img_b2_avg = np.mean(img_b2)

    Var_b1 = np.sum(np.square((blk_b1-blk_b1_avg)-(img_b1-img_b1_avg)))/(2*Np)
    Var_b2 = np.sum(np.square((blk_b2-blk_b2_avg)-(img_b2-img_b2_avg)))/(2*Np)

    return np.sqrt(Var_b1), np.sqrt(Var_b2)

def ContrastCal(BlackImg, SrcImg):
    """
    calculate bucket contrast
    """
    assert isinstance(BlackImg, np.ndarray), 'Wrong data type'
    assert isinstance(SrcImg, np.ndarray), 'Wrong data type'
    assert BlackImg.shape==SrcImg.shape, "Image size is different"
    h,w = BlackImg.shape
    Buck1Black = BlackImg[:,:int(w/2)]
    Buck2Black = BlackImg[:,int(w/2):]
    Buck1 = Buck1Black - SrcImg[:,:int(w/2)]
    Buck2 = Buck2Black - SrcImg[:,int(w/2):]
    #Buck1[Buck1 < 0] = 0
    #Buck2[Buck2 < 0] = 0
    constrast = (Buck2 - Buck1)/(Buck1 + Buck2)
    return constrast

def ImgAvg(image_list):
    """
    calculate the average from an image list
    @in: image data list
    @return: average image
    """
    assert isinstance(image_list[0], PIL.PngImagePlugin.PngImageFile), 'Wrong data type'

    average = image_list[0]
    for i in range(len(image_list)):
        img = image_list[i]
        average = Image.blend(average, img, 1.0/(i+1))

    return average

def BlackCali(file_list,black_img_data):

    assert os.path.exists(black_img_data), "{} doesn't exists".format(black_img_data)
    black = np.load(black_img_data)

    if file_list[0].find(".npy")!=-1:
        print("File list length: {}".format(len(file_list)))
        for i in file_list:
            print(i)
            temp = np.load(i)
            temp = black - temp
            np.save(i,temp)
    else:
        raise NameError("No npy file found")

def GainCali(file_list,gain_img_data):

    assert os.path.exists(gain_img_data), "{} doesn't exists".format(gain_img_data)
    gain = np.load(gain_img_data)
    assert gain.shape[2]==3, "Gain calibration data wrong. Shape {}".format(gain.shape)

    if file_list[0].find(".npy")!=-1:
        print("File list length: {}".format(len(file_list)))
        for i in file_list:
            print(i)
            temp = np.load(i)
            temp = (temp-gain[:,:,0])*gain[:,:,1] + gain[:,:,2]
            #temp = (temp-gain[:,:,0])*gain[:,:,1]
            #temp = temp*gain[:,:,1]
            temp[:,:6] = 0
            temp[:,324-10:324+10] = 0
            temp[:,648-6:] = 0
            np.save(i,temp)
    else:
        raise NameError("No npy file found")

def Png2Npy(file_list):

    if file_list[0].find(".png")!=-1:
        print("File list length: {}".format(len(file_list)))
        for i in file_list:
            temp = misc.imread(i)
            np.save(i.replace("png","npy"),temp)
    else:
        raise NameError("No png file found")

def Npy2Png(file_list):

    if file_list[0].find(".npy")!=-1:
        print("File list length: {}".format(len(file_list)))
        for i in file_list:
            print(i)
            temp = np.load(i)
            to_name = i.replace("npy","png")
            print(to_name)
            misc.imsave(to_name,temp)
    else:
        raise NameError("No npy file found")

def ImgFileAvg(image_file_list):
    """
    calculate the average from an image list
    @in: image data list
    @return: average image
    """
    #print(type(image_file_list[0]))
    #assert isinstance(image_file_list[0], str), 'Wrong data type'

    if image_file_list[0].find(".npy")!=-1:
        print("Averaging image list length: {}".format(len(image_file_list)))
        #img_list = [misc.imread(i) for i in image_file_list]
        img_list = [np.load(i) for i in image_file_list]
        return np.mean(img_list, axis=0)
    else:
        raise NameError("Need npy data")
    #pattern = re.compile(".npy")
    #if pattern.match(image_file_list[0]):
    #    print("Averaging image list length: {}".format(len(image_file_list)))
    #    #img_list = [misc.imread(i) for i in image_file_list]
    #    img_list = [np.load(i) for i in image_file_list]
    #    return np.mean(img_list, axis=0)
    #else:
    #    raise NameError("Need npy data")

    #average = misc.imread(image_file_list[0])
    #logging.info("Do ImgFileAvg... Dtype:"+str(average.dtype))
    #for i in range(len(image_file_list)):
    #    img = misc.imread(image_file_list[i])
    #    alpha = 1./(i+1)
    #    average = average*(1.-alpha)+img*alpha

    #return average


def GetImgList(dir, img_format='png'):
    """
    read image list from a folder
    @in: directory
    @return: image data list
    """
    assert os.path.exists(dir), 'Directory does not exist'

    image_list = []
    #for filename in glob.glob(dir+'/*.png'):
    for filename in glob.glob(dir+'/*.'+img_format):
        im = Image.open(filename)
        image_list.append(im)
    logging.debug('image list length {}'.format(len(image_list)))
    return image_list

def GetImgFileList(dir, pattern):
    """
    read image list from a folder
    @in: directory
    @return: image file list
    """
    assert os.path.exists(dir), 'Directory does not exist'
    logging.info("GetImgFileList from "+dir)

    image_file_list = []
    temp = glob.glob(dir+pattern)
    if len(temp):
        print("Found {} pattern in {}".format(pattern, dir))
    else:
        raise NameError("No {} pattern found".format(pattern))
    for filename in temp:
        image_file_list.append(filename)
    logging.info('image file list length {}'.format(len(image_file_list)))
    return image_file_list

def ImgShow(image):
    #print(type(image))
    assert isinstance(image, np.ndarray), 'Wrong data type'
    #assert isinstance(image, PIL.Image.Image), 'Wrong data type'
    fig = plt.figure()
    ax = fig.add_subplot(111)
    color = "inferno"
    img = ax.imshow(image, interpolation='nearest', cmap = color, vmin = -1, vmax = 1)
    plt.colorbar(img)
    plt.show()

def bmpmerge(dst_name, src_list, repeat=1, order=[0], show=True):
    assert isinstance(dst_name, str), 'Wrong data type'
    for i in range(len(src_list)):
        assert os.path.exists(src_list[i]),\
            "{} file does not exist".format(src_list[i])

    list_im = []

    logging.info("Mask data generation...")
    for i in src_list:
        logging.info("source: {}".format(i))
    mask_files = [src_list[i] for i in order]

    for j in mask_files:
        print(j)
        print(repeat)
        for i in range(repeat):
            list_im.append(j)

    imgs = [Image.open(i) for i in list_im]
    for i in range(len(imgs)):
        assert isinstance(imgs[i], PIL.BmpImagePlugin.BmpImageFile), 'Wrong data type'

    h,w = imgs[0].size
    img = Image.new('1',(h,w*len(imgs)), 0)

    for i in range(len(imgs)):
        img.paste(imgs[i],(0,w*i))

    img.save(dst_name)
    if show:
        plt.imshow(img)
        plt.show()

def BmpInvt(src_file,dst_file):
    image = np.asarray(Image.open(src_file).convert("L"))

    img = Image.new('1',(image.shape[1],image.shape[0]), 1)
    pixels = img.load()
    for i in range(img.size[0]):
        for j in range(img.size[1]):
            if(image[j,i]==255):
                pixels[i,j] =0
    img.save(dst_file)

##############################
# noise analysis
#############################
"""
Created on Wed Nov 28 2018

@author: Navid

Written for T3 debuging to characterize noise behavior of the system. Saved
images are read and analyzed (for offline analysis).

"""

def cal_noise_1rowrepeat(TestsPath, colrange):
    """
    This function calculates the row/col noise of the captured images and saves
    them as csv files.
    The image should be composed of several row reads from the same pixel-bucket.

    TestsPath: determines where all the saved images are, all of them will be processed.
    colrange: range of the columns that should be analyzed.
    """
    print("Calculateing row noise at ", TestsPath)
    images = [img for img in os.listdir(TestsPath) if(img[-4:] == ".npy" and img[:5] != "black" )]
    imagecur = np.load(TestsPath + "/" + images[0],'r')
    h, w = imagecur.shape
    w_new = len(colrange)
    allstdr = np.zeros((len(images)+1,h))
    allstdr[0,:] = np.arange(h)
    allstdc = np.zeros((len(images)+1,w_new))
    allstdc[0,:] = colrange
    allmeanr = np.zeros((len(images)+1,h))
    allmeanr[0,:] = np.arange(h)
    allmeanc = np.zeros((len(images)+1,w_new))
    allmeanc[0,:] = colrange
    for i in range(len(images)):
        print(i,images[i])
        imagecur = np.load(TestsPath + "/" + images[i],'r')
        meanrows = np.zeros((1, h))
        meanrows = np.mean(imagecur[:,colrange], axis = 1)
        allmeanr[i+1,:] = meanrows
        meancols = np.zeros((w_new, 1))
        meancols = np.mean(imagecur[:,colrange], axis = 0)
        allmeanc[i+1,:] = meancols
        stdrows = np.zeros((1, h))
        stdrows = np.std(imagecur[:,colrange], axis = 1)
        allstdr[i+1,:] = stdrows
        stdcols = np.zeros((w_new, 1))
        stdcols = np.std(imagecur[:,colrange], axis = 0)
        allstdc[i+1,:] = stdcols
    np.savetxt(TestsPath + "/" + "mean_rows.csv", allmeanr.reshape(-1,h), delimiter = ",")
    np.savetxt(TestsPath + "/" + "mean_cols.csv", allmeanc.reshape(-1,w_new), delimiter = ",")
    np.savetxt(TestsPath + "/" + "std_rows.csv", allstdr.reshape(-1,h), delimiter = ",")
    np.savetxt(TestsPath + "/" + "std_cols.csv", allstdc.reshape(-1,w_new), delimiter = ",")

def cal_tempnoise_1rowrepeat(TestsPath, colrange):
    """
    This function first substracts the average of the rows from the image and
    calculates the row/col noise of the resulting image. This should remove the
    FPN and the saved csv file should reflect the temporal noise results only.
    The image should be composed of several row reads from the same pixel-bucket.

    TestsPath: determines where all the saved images are, all of them will be processed.
    colrange: range of the columns that should be analyzed.
    """
    print("Calculating temporal row noise at ", TestsPath)
    if not os.path.exists(TestsPath+'/.temp'):
        os.makedirs(TestsPath+'/.temp')

    images = [img for img in os.listdir(TestsPath) \
              if(img[-4:] == ".npy" and img[:3] != "ave" and img[:5] != "black")]
    imagecur = np.load(TestsPath + "/" + images[0],'r')
    h, w = imagecur.shape
    w_new = len(colrange)
    allstdr = np.zeros((len(images)+1,h))
    allstdr[0,:] = np.arange(h)
    allstdc = np.zeros((len(images)+1,w_new))
    allstdc[0,:] = colrange
    allmeanr = np.zeros((len(images)+1,h))
    allmeanr[0,:] = np.arange(h)
    allmeanc = np.zeros((len(images)+1,w_new))
    allmeanc[0,:] = colrange

    for i in range(len(images)):
        print(i,images[i])
        imagecur = np.load(TestsPath + "/" + images[i],'r')
        # calculate col average
        avgcur = np.mean(imagecur, axis = 0)
        np.save(TestsPath + "/.temp/average_" + images[i], avgcur)
        # substract col average
        imagecur = imagecur - avgcur
        # calculate row average
        meanrows = np.mean(imagecur[:,colrange], axis = 1)
        allmeanr[i+1,:] = meanrows
        # calculate col average
        meancols = np.mean(imagecur[:,colrange], axis = 0)
        allmeanc[i+1,:] = meancols
        # calculate row std
        stdrows = np.std(imagecur[:,colrange], axis = 1)
        allstdr[i+1,:] = stdrows
        # calculate col std
        stdcols = np.std(imagecur[:,colrange], axis = 0)
        allstdc[i+1,:] = stdcols
    np.savetxt(TestsPath + "/" + "mean_rows.csv", allmeanr.reshape(-1,h), delimiter = ",")
    np.savetxt(TestsPath + "/" + "mean_cols.csv", allmeanc.reshape(-1,w_new), delimiter = ",")
    np.savetxt(TestsPath + "/" + "std_rows.csv", allstdr.reshape(-1,h), delimiter = ",")
    np.savetxt(TestsPath + "/" + "std_cols.csv", allstdc.reshape(-1,w_new), delimiter = ",")

def cal_noise_mult_capt(TestsPath, colrange, rowrange):
    """
    This function calculates the row/col noise of the captured images and saves
    them as csv files.
    The image should be composed of several row reads from the same pixel-bucket.

    TestsPath: determines where all the saved images are, all of them will be processed.
    colrange: range of the columns that should be analyzed.
    rowrange: range of the rows that should be analyzed.
    """
    print("Calculateing row noise of multiple rows at", TestsPath)
    images = [img for img in os.listdir(TestsPath) \
              if(img[-4:] == ".npy" and img[:5] != "black")]
    imagecur = np.load(TestsPath + "/" + images[0],'r')
    h, w = imagecur.shape
    for i in range(len(images)):
        imagecur = np.load(TestsPath + "/" + images[i],'r')
        meancols = np.zeros((w, 1))
        meancols = np.mean(imagecur, axis = 0)
        np.save(TestsPath + "/.temp/average_" + images[i], meancols)
    w = len(colrange)
    h = len(rowrange)
    allstdr = np.zeros((2,h))
    allstdr[0,:] = rowrange
    allstdc = np.zeros((2,w))
    allstdc[0,:] = colrange
    allmeanr = np.zeros((2,h))
    allmeanr[0,:] = rowrange
    allmeanc = np.zeros((2,w))
    allmeanc[0,:] = colrange
    allimgs = np.zeros((h,w,len(images)))
    for i in range(len(images)):
        imagecur = np.load(TestsPath + "/" + images[i],'r')
        print(imagecur.shape)
        allimgs[:,:,i] = imagecur[rowrange,colrange]
    meanrows = np.zeros((1, h))
    meanrows = np.mean(np.mean(allimgs, axis = 2), axis = 1)
    allmeanr[1,:] = meanrows
    meancols = np.zeros((w, 1))
    meancols = np.mean(np.mean(allimgs, axis = 2), axis = 0)
    allmeanc[1,:] = meancols
    stdrows = np.zeros((1, h))
    stdrows = np.std(np.mean(allimgs, axis = 1), axis = 2)
    allstdr[1,:] = stdrows
    stdcols = np.zeros((w, 1))
    stdcols = np.std(np.mean(allimgs, axis = 0), axis = 2)
    allstdc[1,:] = stdcols

    np.savetxt(TestsPath + "/" + "mean_rows.csv", allmeanr.reshape(-1,h), delimiter = ",")
    np.savetxt(TestsPath + "/" + "mean_cols.csv", allmeanc.reshape(-1,w), delimiter = ",")
    np.savetxt(TestsPath + "/" + "std_rows.csv", allstdr.reshape(-1,h), delimiter = ",")
    np.savetxt(TestsPath + "/" + "std_cols.csv", allstdc.reshape(-1,w), delimiter = ",")

def sketch_noise(TestsPath):
    curfolder = os.getcwd()
    os.chdir(TestsPath)
    rowmean = np.loadtxt("mean_rows.csv", delimiter = ",")
    colmean = np.loadtxt("mean_cols.csv", delimiter = ",")
    rowstd = np.loadtxt("std_rows.csv", delimiter = ",")
    colstd = np.loadtxt("std_cols.csv", delimiter = ",")
    os.chdir(curfolder)
    h, w1 = rowmean.shape
    h, w2 = colmean.shape

    f_mean_row, ax_mean_row = plt.subplots((h-1), 1, sharey=False, num="row mean")
    f_mean_row.suptitle('row mean')
    f_mean_col, ax_mean_col = plt.subplots((h-1), 1, sharey=False, num="col mean")
    f_mean_col.suptitle('col mean')
    f_std_row, ax = plt.subplots((h-1), 1, sharey=True, num='row std')
    f_std_row.suptitle('row std')
    x1 = rowmean[0,:]
    x2 = colmean[0,:]
    for i in range(0,h-1):
        ax_mean_row[i].plot(x1[4:], rowmean[i+1,4:], linestyle='None', marker='^', label=str(i))
        ax_mean_row[i].legend()
        ax_mean_col[i].plot(x2[:], colmean[i+1,:], linestyle='None', marker='^', label=str(i))
        ax_mean_col[i].legend()

        ax[i].plot(x1[4:],rowstd[i+1,4:], label=str(i))
        ax[i].legend()
        # plt.plot(x1,rowstd[i+1,:])
        #plt.figure('col mean')
        #plt.plot(x2, colmean[i+1,:], linestyle='-', marker='^', label=str(i))
        plt.figure('col std')
        plt.plot(x2,colstd[i+1,:], label=str(i))
        plt.legend()


        print("Row mean mean is", np.mean(rowmean[i+1,:]), \
              "and row mean std is", np.mean(rowstd[i+1,:]))
        print("Column mean mean is", np.mean(colmean[i+1,:]), \
              "and column mean std is", np.mean(colstd[i+1,:]))
    #plt.legend()
    #f_std_row.legend(loc=0)
    plt.show()

#def StripPatAnalyze(SrcNpyFile, DstNpyFile):
def StripPatAnalyze(SrcNpyFile):
    """
    load .npy format image
    split image into two images according to strip mask pattern
    @in: .npy image data
    """
    img = np.load(SrcNpyFile)
    h,w=img.shape
    print(h,w)


    # for 2 strip patterns
    #a = np.arange(0,h,2)
    #b = np.arange(1,h,2)
    #h_order=np.concatenate((a,b))
    #print(np.concatenate((a,b)))
    # for 3 strip patterns horizontal
    #a = np.arange(0,int(h/3),3)
    #b = np.arange(1,int(h/3),3)
    #c = np.arange(2,int(h/3),3)
    #h_order=np.concatenate((a,b))
    #h_order=np.concatenate((h_order,c))
    #print(np.concatenate((a,b)))
    # for 2 strip patterns virtical
    #a = np.arange(0,w,2)
    #b = np.arange(1,w,2)
    #w_order=np.concatenate((a,b))
    #print(w_order)
    # for 3 strip patterns virtical
    #a = np.arange(0,w,3)
    #b = np.arange(1,w,3)
    #c = np.arange(2,w,3)
    #w_order=np.concatenate((a,b))
    #w_order=np.concatenate((w_order,c))
    # for 4 bayer patterns
    #a = np.arange(0,h,2)
    #b = np.arange(1,h,2)
    #h_order=np.concatenate((a,b))
    #a = np.arange(0,w,2)
    #b = np.arange(1,w,2)
    #w_order=np.concatenate((a,b))
    a = np.arange(0,h,2)
    b = np.arange(1,h,2)
    h_order=np.concatenate((a,b))
    a = np.arange(0,int(w/2),2)
    b = np.arange(1,int(w/2),2)
    w_order=np.concatenate((a,b))
    a = np.arange(int(w/2),w,2)
    w_order=np.concatenate((w_order,a))
    a = np.arange(int(w/2)+1,w,2)
    w_order=np.concatenate((w_order,a))

    org_to_name = SrcNpyFile.replace(".npy",".png")
    split_to_name = SrcNpyFile.replace(".npy","_split.png")
    misc.imsave(org_to_name,img)
    #misc.imsave(split_to_name,img[h_order,:])
    img = img[h_order,:]
    img = img[:,w_order]
    misc.imsave(split_to_name,img)

    #plt.imshow(img)
    #plt.show()





if __name__ == '__main__':

    #dir = './image'
    #dir_list = os.listdir(dir)
    #print(dir_list)
    ##print(dir_list[0]+'/*.png')
    #input("press any key to continue...")
    ## black level
    #dir_black = dir + '/' + dir_list[2]
    #black=ImgAvg(GetImgList(dir_black))

    ## image level
    #dir_src = dir + '/' + dir_list[0]
    #image=ImgAvg(GetImgList(dir_src))

    #result = ContrastCal(np.asarray(black), np.asarray(image))
    #ImgShow(result)
    #ImgShow(result)


    ##### Example for analysing a single image containing several reads from the same row
    #runFolder = os.getcwd() #"./SavedData" #This is where the images are saved
    #colrange = np.arange(50,250)
    #runFolder = "./image"
    #average_them(runFolder)
    #cal_tempnoise_1rowrepeat(runFolder, colrange)
    ##average_them(runFolder)
    #sketch_noise(runFolder)

    ###### Example for analysing multiple images of several reads with several rows
    #runFolder = "D:/Projects/Python_Meas_Results/T3/Rahul_image"
    #colrange = np.arange(100,900)
    #rowrange = np.arange(0,20)
    #cal_noise_mult_capt(runFolder, colrange, rowrange)
    #sketch_noise(runFolder)

    dir = './image'
    dir_list = os.listdir(dir)
    print(dir_list)
    for i in dir_list:
        colrange = np.arange(10,310)
        #average_them(dir+'/'+i)
        cal_tempnoise_1rowrepeat(dir+'/'+i, colrange)
        #cal_noise_1rowrepeat(dir+'/'+i, colrange)
        sketch_noise(dir+'/'+i)
