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



# The dimesions of the input data were previously determined to be 320 x 648
WIDTH = 648
HEIGHT = 320



# Region of interest: whole region
X,Y = 320,648
R,H = 320,648

saveFolder1	= "./image/20210217_2000/processed/mask{:01d}_rep{:02d}_tap{:01d}/"
saveFolder2	= "./image/20210217_2100/processed/mask{:01d}_rep{:02d}_tap{:01d}/"

########## READ VALUES ##########
repList 	= [1,2,4,8]
maskList 	= [4]
tapList 	= [1]
expList 	= np.logspace(np.log10(262),np.log10(50000),30)

expValue	= np.zeros((len(repList),len(expList)))
avgImgs1 	= np.zeros((len(repList),len(expList),R,H))
stdImgs1 	= np.zeros((len(repList),len(expList),R,H))

avgImgs2 	= np.zeros((len(repList),len(expList),R,H))
stdImgs2 	= np.zeros((len(repList),len(expList),R,H))

rep_index = 0
exp_index = 0
for rep_num in repList:
# for mask_num in maskList:
	mask_num = maskList[0]
	for tap in tapList:
		for exp in expList:
			readFolder = saveFolder1.format(mask_num,rep_num,tap)
			avg = np.load(os.path.join(readFolder,"avg_{:06d}.npy".format(int(exp))))
			std = np.load(os.path.join(readFolder,"std_{:06d}.npy".format(int(exp))))
			avgImgs1[rep_index,exp_index,:,:] = avg[:,:]
			stdImgs1[rep_index,exp_index,:,:] = std[:,:]

			readFolder = saveFolder2.format(mask_num,rep_num,tap)
			avg = np.load(os.path.join(readFolder,"avg_{:06d}.npy".format(int(exp))))
			std = np.load(os.path.join(readFolder,"std_{:06d}.npy".format(int(exp))))
			avgImgs2[rep_index,exp_index,:,:] = avg[:,:]
			stdImgs2[rep_index,exp_index,:,:] = std[:,:]

			# print("Reading",saveFolder.format(mask_num,rep_num,tap),int(exp),np.mean(np.mean(np.mean(avg[:,:].astype(np.float)))))

			exp_index += 1
		exp_index = 0

		# expValue[i,:] = expList[:]*mask_num
		expValue[rep_index,:] = expList[:]*mask_num*4 #4 because slow bitfile(11.2) was used 
		rep_index += 1


########## SAVE/READ model ##########

gainModelPara1 	= np.zeros((len(repList),3,HEIGHT,WIDTH))
noiseModelPara1	= np.zeros((len(repList),2,HEIGHT,WIDTH))
gainModelPara2 	= np.zeros((len(repList),3,HEIGHT,WIDTH))
noiseModelPara2	= np.zeros((len(repList),2,HEIGHT,WIDTH))

# useOldData = input("Do you want to use existing data y/n:")
useOldData = 'y'
if(useOldData=='y' or useOldData=='Y'):
	for rep_num,rep_index in zip(repList,range(len(repList))):
		mask_num = maskList[0]
		for tap in tapList:
			readFolder = saveFolder1.format(mask_num,rep_num,tap)
			gainModelPara1[rep_index,:,:,:] = np.load(os.path.join(readFolder,"gainModel.npy"))
			noiseModelPara1[rep_index,:,:,:] = np.load(os.path.join(readFolder,"noiseModel.npy"))

			readFolder = saveFolder2.format(mask_num,rep_num,tap)
			gainModelPara2[rep_index,:,:,:] = np.load(os.path.join(readFolder,"gainModel.npy"))
			noiseModelPara2[rep_index,:,:,:] = np.load(os.path.join(readFolder,"noiseModel.npy"))

#valid cols and rows
cols = np.concatenate((np.arange(19,324,10),np.arange(20,324,10)))
rows = np.concatenate((np.arange(19,320,10),np.arange(20,320,10),[311,312,313])) 


# pixels to be plotted
cols = np.arange(19,324,100)
rows = np.arange(19,240,100)

neighbor = 140
cols = [neighbor-1,neighbor]
rows = [neighbor-1,neighbor]

# DEFINE jetmap colorscheme
plt.ion()
jetmap = plt.get_cmap('jet')
k = np.reshape(jetmap(np.arange(240*648)/648/240)[:,:3],(240,-1,3))
color = ['tab:blue','tab:orange','tab:green','tab:red']

figsize = (8,6)


#RAW data plot for all constant masks
fig=plt.figure(1,figsize=figsize)
plt.clf()
ax=fig.subplots(2,2,sharex=True,sharey=True)
for rep_num,rep_index in zip(repList,range(len(repList))):
	print(rep_index)
	# gainModelPara = applyGainModel(expValue[rep_index,10:]/1e3,avgImgs[rep_index,10:,:,:],rows,cols)

	sp = ax[rep_index//2,rep_index%2] #current subplot
	
	colorInd = 0
	for r in rows:
		x = expValue[rep_index,:]/1e3
		for c in cols:
			y = avgImgs1[rep_index,:,r,c]
			sp.plot(x,y,'o-',color=color[colorInd],linewidth=1,alpha=1,markersize=2)

			gainFit = gainModelPara1[rep_index,:,r,c]
			y = gainModel(x,gainFit[0],gainFit[1],gainFit[2])
			sp.plot(x,y,'--',color=color[colorInd],linewidth=1,alpha=1,markersize=1,label='y={:04.1f}x+{:04.1f}'.format(gainFit[0],gainFit[1]))

			colorInd += 1

	sp.grid()
	sp.legend()
	sp.set_ylim((500,5000))
	sp.set_title("Repetition #{:02d}".format(rep_num))
plt.suptitle('Raw data for constant masks')

#RAW data plot for changing masks
fig=plt.figure(2,figsize=figsize)
plt.clf()
ax=fig.subplots(2,2,sharex=True,sharey=True)
for rep_num,rep_index in zip(repList,range(len(repList))):
	print(rep_index)
	# gainModelPara = applyGainModel(expValue[rep_index,10:]/1e3,avgImgs[rep_index,10:,:,:],rows,cols)
	sp = ax[rep_index//2,rep_index%2] #current subplot

	colorInd = 0
	for r in rows:
		x = expValue[rep_index,:]/1e3
		for c in cols:
			y = avgImgs2[rep_index,:,r,c]
			sp.plot(x,y,'o-',color=color[colorInd],linewidth=1,alpha=1,markersize=2)

			gainFit = gainModelPara2[rep_index,:,r,c]
			y = gainModel(x,gainFit[0],gainFit[1],gainFit[2])
			sp.plot(x,y,'--',color=color[colorInd],linewidth=1,alpha=1,markersize=1,label='y={:04.1f}x+{:04.1f}'.format(gainFit[0],gainFit[1]))
			colorInd += 1

	sp.set_ylim(500,5000)
	sp.legend()
	sp.grid()
	sp.set_title("Repetition #{:02d}".format(rep_num))
plt.suptitle('Raw data for changing masks')

#data adjusted for slopes
fig=plt.figure(3,figsize=figsize)
plt.clf()
ax=fig.subplots(2,2,sharex=True,sharey=True)
for rep_num,rep_index in zip(repList,range(len(repList))):
	print(rep_index)
	# gainModelPara = applyGainModel(expValue[rep_index,10:]/1e3,avgImgs[rep_index,10:,:,:],rows,cols)
	sp = ax[rep_index//2,rep_index%2] #current subplot

	refGain = gainModelPara1[rep_index,0,rows[0],cols[0]]

	colorInd = 0
	for r in rows:
		x = expValue[rep_index,:]/1e3
		for c in cols:
			gainFit = gainModelPara2[rep_index,:,r,c]

			gainFactor = refGain/gainModelPara1[rep_index,0,r,c]

			y = avgImgs2[rep_index,:,r,c]
			sp.plot(x,y,'o-',color=color[colorInd],linewidth=1,alpha=1,markersize=2)

			y = gainModel(x,gainFit[0],gainFit[1],gainFit[2])
			sp.plot(x,y,'--',color=color[colorInd],linewidth=1,alpha=1,markersize=1,label='y={:4.1f}x+{:4.1f}'.format(gainFit[0]*gainFactor,gainFit[1]))
			colorInd += 1

	sp.set_ylim(500,5000)
	sp.legend()
	sp.grid()
	sp.set_title("Repetition #{:02d}".format(rep_num))
plt.suptitle('slope value adjusted based on constant mask')


avgImgs = avgImgs1
stdImgs = stdImgs1
gainModelPara = gainModelPara1
noiseModelPara= noiseModelPara1

noiseFitIC 	= [-0.16,1000]
noiseFitMax = [-0.13,1302]
noiseFitMin = [-0.21,600]

fig=plt.figure(9)
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

# input()