import numpy as np
import os
from characterize.characterize import camModel
import matplotlib.pyplot as plt
import time
import cv2

# The dimesions of the input data were previously determined to be 320 x 648
WIDTH = 648
HEIGHT = 320

########## READ VALUES ##########
mask_num 	= 4
rep_num 	= 32

path 		= "./image/20210516_2000/rawData/matlab/mask4_rep32_tap1/"
gainModelFile = './image/20210516_2000/processed/mask4_rep32_tap1/gainModelPara.npy'


# Create pixel array that needs to be calibrate
rows 	= np.arange(HEIGHT)
cols 	= np.arange(WIDTH)
# rows	= np.arange(19,240,50)
# cols 	= np.arange(19,324,50)

pixels = np.array(np.meshgrid(rows,cols)).T.reshape(-1,2)


# initialzie camera model
t6 = camModel()
#Read all data and calculate 
t6.per_pixel_stats(path)


############## FIT MODEL ##############

useOldData = input("Do you want to use existing data y/n:")
if(useOldData=='y'):
	gainModelPara 	= t6.loadCurvefitSystemModel(gainModelFile)

elif(useOldData=='n'):
	gainModelPara 	= t6.applyCurvefitSystemModel(pixels)
	np.save(gainModelFile,gainModelPara)

# create a pixel array that needs to be plotted
pixels = []
for x in np.arange(19,240,    50):
	for y in np.arange(19,324,50):
		pixels.append((x,y))

# if(useOldData != 'y' and useOldData != 'n'):
# 	gainModelPara 	= t6.applyCurvefitSystemModel(pixels)

############## calibrate ##############
fittedData = t6.calculateFittedValueFull()

#######################################
############ VISUALIZATION ############
plt.ion()
jetmap 	= plt.get_cmap('jet')
k 		= np.reshape(jetmap(np.arange(240*648)/648/240)[:,:3],(240,-1,3))

############ PLOT RAW DATA ############
fig = plt.figure(1)
plt.clf()
ax = fig.subplots(ncols=1)
for pix in pixels:
	(r,c) = pix
	ax.plot(t6.exposures[:],t6.avg_m[:,r,c],\
					'.-',color=k[r,c,:],alpha=0.5,linewidth=2,markersize=1)

	gainFit = gainModelPara[r,c,:]
	ax.plot(t6.exposures[:],t6.curvefitSystemModel(t6.exposures[:],\
		gainFit[0],gainFit[1],gainFit[2]),
		'--',color='black',linewidth=1,alpha=0.2,markersize=1)

############ PLOT CAL DATA ############
fig = plt.figure(2)
plt.clf()
ax = fig.subplots(ncols=1)
for pix in pixels:
	(r,c) = pix
	ax.plot(t6.exposures[:],fittedData[:,r,c],\
		'^-',color=k[r,c,:],linewidth=2,alpha=0.2,markersize=5)

############ SHOW ############
plt.show()
input()

########## See videos ##########
folder 		= "./image/20210516_2000/rawData/mask{:01d}_rep{:02d}_tap{:01d}/t6Exp{:06d}Mask{:01d}_Rep_{:03d}_tap{:01d}__t6_optimal_sl_shifted.bmp" 

expList 	= np.logspace(np.log10(840),np.log10(10000),20)
mask_num 	= 4
rep_num 	= 32
nof 		= 50
tap 		= 1

img_name = 'RAW'
cv2.namedWindow(img_name)
def nothing():
	return 0
cv2.createTrackbar('Zoom', img_name, 5, 40, nothing)

calibWindow = "Calibration Window"
cv2.namedWindow(calibWindow)



maxLvl		= 4000

cv2.namedWindow("")
while 1:
	for exp in expList :
		f = folder.format(mask_num,rep_num,tap,int(exp),mask_num,rep_num,tap)
		blkImgAvg 	= np.asarray(\
					  np.load(\
					  os.path.join(f,'t6_black_image_avg.npy')),\
					  dtype=np.float)
		for i in range(0,nof):
			factor = cv2.getTrackbarPos('Zoom',img_name)

			file = os.path.join(f,str(i).zfill(4)+'.npy')

			img = np.asarray(np.load(file),dtype=np.float)
			img_cal = t6.calculateFittedImage(img)
			img 	= blkImgAvg - img


			img 	= (np.clip(img,    0,maxLvl)*255/maxLvl).astype(np.uint8)
			img_cal = (255-np.clip(img_cal,0,maxLvl)*255/maxLvl).astype(np.uint8)

			img_scaled = cv2.resize(img,None,fx=factor/5, fy=factor/5,
                                     # interpolation = cv2.INTER_NEAREST)
                                     interpolation = cv2.INTER_LINEAR)

			cv2.imshow(img_name,img_scaled)
			cv2.imshow(calibWindow,cv2.resize(img_cal,None,fx=factor/5, fy=factor/5,\
                                     # interpolation = cv2.INTER_NEAREST))
                                     interpolation = cv2.INTER_LINEAR))

			time.sleep(0.033)


			key = cv2.waitKey(1)
			if(key==27): break
