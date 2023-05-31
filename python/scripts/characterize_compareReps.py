import glob
import random
import numpy as np
import pandas as pd
from scipy.io import loadmat
import matplotlib.pyplot as plt
from matplotlib.pyplot import imshow
from scipy.optimize import curve_fit
import os

def gainModel(x,gain,offset,sat_time):
	x = np.asarray(x)
	y = gain*x + offset
	y[x>sat_time] = gain*sat_time + offset
	return y

def noiseModel(x,gain,offset):
	return gain*x + offset

def applyGainModel(exp,avgImgs,rows,cols,H=320,W=648):
	"""
		Returns gain model parameters such as DN vs exp_time slope, saturation time and offset for a line fit.

		exp: exposure time array in ms
		avgImgs: input image(HxW)  arrayfor each exposure value
		row,cols: set of rows and cols for which model should be calculated
	"""

	#Parameters to help curve fit
	gainModelIC = [-2.7,4700,400]
	gainMin	= [-40,3500,100]
	gainMax	= [-1,5000,1000]	

	#optimized parameters will be stored here
	gainModelPara = np.zeros((3,H,W))
	print(exp[:].shape,avgImgs.shape)
	for r in rows:
		for c in cols:
			gainModelPara[:,r,c],pcov =curve_fit(gainModel,exp[:],avgImgs[:,r,c],\
			 p0=gainModelIC,bounds=(gainMin,gainMax))
			print("processing row:{:03d} col:{:03d}".format(r,c),end='\r')
	print("Done modelling")
	return gainModelPara

def applyNoiseModel(exp,avgImgs,varImgs,sat_time,rows,cols,H=320,W=648):
	"""
		Returns noise model parameters such as var vs avg slope and offset for a line fit.
		exp: exposure time array in ms
		avgImgs: input array of average image(HxW) for each exposure value
		vaImgs:  input array of variance of the image(HxW) for each exposure
		row,cols: set of rows and cols for which model should be calculated
		sat: exposure time in ms above which pixel is saturated
	"""
	noiseFitIC 	= [-0.16,1000]
	noiseFitMax = [-0.13,1302]
	noiseFitMin = [-0.21,600]
	

	#optimized parameters will be stored here
	noiseModelPara = np.zeros((2,H,W))
	for r in rows:
		for c in cols:
			validpoints = np.nonzero(exp[:] < sat_time[r,c])
			x = avgImgs[validpoints,r,c].flatten()
			y = varImgs[validpoints,r,c].flatten()
			noiseModelPara[:,r,c],pcov = curve_fit(noiseModel,x,y,\
				p0=noiseFitIC,bounds=(noiseFitMin, noiseFitMax))
			print("processing row:{:03d} col:{:03d}".format(r,c),end='\r')
	print("")
	return noiseModelPara

# path of directory containing images
DIR = "./image/20210211/rawData/matlab/mask2_tap1/"
saveLoc = "./image/20210211/processed/mask2_tap1/condensed/"

DIR = "./image/20210215/rawData/matlab/mask4_rep02_tap1/"
saveLoc = "./image/20210215/processed/mask4_rep02_tap1/condensed/"

# List of filenames in sorted order, smallest to largest exposure time
fnames = glob.glob(DIR + '/*.mat')
fnames.sort()
filenames = [f.split('/')[-1].replace('.mat', '') for f in fnames]



# The dimesions of the input data were previously determined to be 320 x 648
WIDTH = 648
HEIGHT = 320



# Region of interest: whole region
X,Y = 320,648
R,H = 320,648

folder 		= "./image/20210217_2100/rawData/mask{:01d}_rep{:02d}_tap{:01d}/t6Exp{:06d}Mask{:01d}_Rep_{:03d}_tap{:01d}__t6_merge.bmp"
saveFolder 	= "./image/20210217_2100/processed/mask{:01d}_rep{:02d}_tap{:01d}/"
matFolder 	= "./image/20210217_2100/rawData/matlab/mask{:01d}_rep{:02d}_tap{:01d}/"



########## READ VALUES ##########
mask_num 	= 4
repList 	= [1,2,4,8]
maskList 	= [4]
tapList 	= [1]
expList 	= np.logspace(np.log10(262),np.log10(50000),30)

expValue	= np.zeros((len(repList),len(expList)))
avgImgs 	= np.zeros((len(repList),len(expList),R,H))
stdImgs 	= np.zeros((len(repList),len(expList),R,H))

rep_index = 0
exp_index = 0
for rep_num in repList:
# for mask_num in maskList:
	mask_num = maskList[0]
	for tap in tapList:
		for exp in expList:
			readFolder = saveFolder.format(mask_num,rep_num,tap)
			avg = np.load(os.path.join(readFolder,"avg_{:06d}.npy".format(int(exp))))
			std = np.load(os.path.join(readFolder,"std_{:06d}.npy".format(int(exp))))
			avgImgs[rep_index,exp_index,:,:] = avg[:,:]
			stdImgs[rep_index,exp_index,:,:] = std[:,:]

			# print("Reading",saveFolder.format(mask_num,rep_num,tap),int(exp),np.mean(np.mean(np.mean(avg[:,:].astype(np.float)))))

			exp_index += 1
		exp_index = 0

		# expValue[i,:] = expList[:]*mask_num
		expValue[rep_index,:] = expList[:]*mask_num*4 #4 because slow bitfile(11.2) was used 
		rep_index += 1


########## SAVE/READ model ##########

gainModelPara 	= np.zeros((len(repList),3,HEIGHT,WIDTH))
noiseModelPara	= np.zeros((len(repList),2,HEIGHT,WIDTH))

useOldData = input("Do you want to use existing data y/n:")
if(useOldData=='y' or useOldData=='Y'):
	for rep_num,rep_index in zip(repList,range(len(repList))):
		mask_num = maskList[0]
		for tap in tapList:
			readFolder = saveFolder.format(mask_num,rep_num,tap)
			gainModelPara[rep_index,:,:,:] = np.load(os.path.join(readFolder,"gainModel.npy"))

			readFolder = saveFolder.format(mask_num,rep_num,tap)
			noiseModelPara[rep_index,:,:,:] = np.load(os.path.join(readFolder,"noiseModel.npy"))



elif(useOldData=='n' or useOldData=='N'):
	cols = np.arange(19,324,50)
	rows = np.arange(19,240,50)

	cols = np.concatenate((np.arange(19,324,10),np.arange(20,324,10)))
	rows = np.concatenate((np.arange(19,320,10),np.arange(20,320,10),[311,312,313])) 

	for rep_num,rep_index in zip(repList,range(len(repList))):
		mask_num = maskList[0]
		for tap in tapList:
			#calculate gain model
			gainModelPara[rep_index,:,:,:] = applyGainModel(expValue[rep_index,10:]/1e3,avgImgs[rep_index,10:,:,:],rows,cols,H=320,W=648)

			#save gain model
			fNpySave = os.path.join(saveFolder.format(mask_num,rep_num,tap),"gainModel.npy".format(int(exp)))
			np.save(fNpySave,gainModelPara[rep_index,:,:,:])

			#calculate gain model
			noiseModelPara[rep_index,:,:,:] = applyNoiseModel(expValue[rep_index,:]/1e3,avgImgs[rep_index,:,:,:],stdImgs[rep_index,:,:,:]**2,gainModelPara[rep_index,2,:,:],rows,cols,H=320,W=648)

			#save gain model
			fNpySave = os.path.join(saveFolder.format(mask_num,rep_num,tap),"noiseModel.npy".format(int(exp)))
			np.save(fNpySave,noiseModelPara[rep_index,:,:,:])




# pixels to be plotted
cols = np.arange(19,324,100)
rows = np.arange(19,240,100)

# cols = np.arange(0,324,25)
# rows = np.arange(0,240,25)

# cols = np.asarray([119])
# rows = np.asarray([10,80,160,239])


# DEFINE jetmap colorscheme
plt.ion()
jetmap = plt.get_cmap('jet')
k = np.reshape(jetmap(np.arange(240*648)/648/240)[:,:3],(240,-1,3))

gainModelIC = [-2.7,4700,400]
gainMin	= [-20,3500,100]
gainMax	= [-1,5000,1000]

fig=plt.figure(1)
plt.clf()
ax=fig.subplots(2,2,sharex=True,sharey=True)
for rep_num,rep_index in zip(repList,range(len(repList))):
	print(rep_index)
	# gainModelPara = applyGainModel(expValue[rep_index,10:]/1e3,avgImgs[rep_index,10:,:,:],rows,cols)

	for r in rows:
		for c in cols:
			ax[rep_index//2,rep_index%2].plot(expValue[rep_index,:]/1e3,avgImgs[rep_index,:,r,c],\
				'.-',color=k[r,c,:],linewidth=1,alpha=1/len(cols)**0.5,markersize=1)
			# gainFit,pcov =curve_fit(gainModel,expValue[rep_index,10:]/1e3,avgImgs[rep_index,10:,r,c] ,p0=	gainModelIC,bounds=(gainMin,gainMax))
			gainFit = gainModelPara[rep_index,:,r,c]
			ax[rep_index//2,rep_index%2].plot(expValue[rep_index,:]/1e3,gainModel(expValue[rep_index,:]/1e3,gainFit[0],gainFit[1],gainFit[2]),\
				'--',color='black',linewidth=1,alpha=1/len(cols)**0.5,markersize=1)

	ax[rep_index//2,rep_index%2].grid()
	ax[rep_index//2,rep_index%2].set_title("Repetition #{:02d}".format(rep_num))



noiseFitIC 	= [-0.16,1000]
noiseFitMax = [-0.13,1302]
noiseFitMin = [-0.21,600]

fig=plt.figure(2)
plt.clf()
ax=fig.subplots(2,2,sharex=True,sharey=True)
for rep_num,rep_index in zip(repList,range(len(repList))):
	print(rep_index)
	for r in rows:
		for c in cols:
			#raw data
			x = avgImgs[rep_index,:,r,c]
			y = stdImgs[rep_index,:,r,c]**2
			ax[rep_index//2,rep_index%2].plot(x,y,\
				'.-',color=k[r,c,:],linewidth=1,alpha=1/len(cols)**0.5,markersize=2)

			#fit model
			sat_time = gainModelPara[rep_index,2,r,c]
			validpoints = np.nonzero(expValue[rep_index,:]/1e3 < sat_time)
			x = avgImgs[rep_index,validpoints,r,c].flatten()
			y = stdImgs[rep_index,validpoints,r,c].flatten()**2
			# noiseFit,pcov = curve_fit(noiseModel,x,y,\
			# 	p0=noiseFitIC,bounds=(noiseFitMin, noiseFitMax))

			noiseFit = noiseModelPara[rep_index,:,r,c]
			#plot model
			x = avgImgs[rep_index,validpoints,r,c].flatten()
			y = noiseModel(x,noiseFit[0],noiseFit[1]).flatten()
			ax[rep_index//2,rep_index%2].plot(x,y,\
				'--',color=k[r,c,:],linewidth=1,alpha=1/len(cols)**0.5,markersize=1)

	ax[rep_index//2,rep_index%2].grid()
	ax[rep_index//2,rep_index%2].set_title("Repetition #{:02d}".format(rep_num))
