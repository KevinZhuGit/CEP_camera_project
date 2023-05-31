import numpy as np
import cv2
import matplotlib.pyplot as plt
import os
import matplotlib as mpl
from scipy.optimize import curve_fit

import scipy.io

def getImages(folder,nuAvg=10):
	# blkImgAvg 	= np.asarray(\
	# 			  np.load(\
	# 			  os.path.join(folder,'t6_black_image_avg.npy')),\
	# 			  dtype=np.float)
	# blkImgList 	= np.tile(blkImgAvg,(nuAvg,1,1))

	[r,c] = [320,648]

	allImgs = np.zeros((nuAvg+2,r,c))

	for i in range(nuAvg):
		file = os.path.join(folder,str(i).zfill(4)+'.npy')
		allImgs[i,:,:] = np.asarray(np.load(file),dtype=np.float)


	# allImgs[0:-2,:,:] = blkImgList - allImgs[0:-2,:,:]

	allImgs[-2,:,:] = np.mean(allImgs[0:-2,:,:],axis=0)
	allImgs[-1,:,:] = np.std(allImgs[0:-2,:,:],axis=0)

	return allImgs

def genAvgStdFiles(folderRead,prefix,repList,expList,nuAvg=10):

	noe				= len(expList)
	[r,c]			= [320,648]
	avgImgs = np.zeros((noe,r,c))
	stdImgs = np.zeros((noe,r,c))

	for rep in repList:
		exp_index = 0
		for exp in expList:
			folderLocal = folder.format(exp=str(exp).zfill(6),rep=str(rep).zfill(3))
			if(os.path.isdir(folderLocal)):
				print(folderLocal)
				allImgs = getImages(folderLocal,nuAvg=nuAvg)
				avgImgs[exp_index,:,:] = allImgs[-2,:,:]
				stdImgs[exp_index,:,:] = allImgs[-1,:,:]
				np.save(prefix+'_avg_rep{:03d}_exp{:06d}.npy'.format(rep,exp),\
					allImgs[-2,:,:])
				np.save(prefix+'_std_rep{:03d}_exp{:06d}.npy'.format(rep,exp),\
					allImgs[-1,:,:])
			else:
				pass
			exp_index += 1

	return [avgImgs,stdImgs]

def genAvgStdFiles2(folderRead,folderSave,nuAvg=20):
	return 1

def getAllAvgStd(readFolder,rep,r=320,c=648):
	allFiles = []
	for file in sorted(os.listdir(readFolder)):
		if(os.path.isdir(os.path.join(readFolder,file))):
			continue
		info = file.split('_')
		if(info[-2]=='rep{:03d}'.format(rep)):
				allFiles.append(file)


	files 	= [os.path.join(readFolder,f) for f in allFiles]

	nof 	= int(len(files)/2)

	avgAll	= np.zeros((nof,r,c))
	stdAll	= np.zeros((nof,r,c))

	std_index 		= 0
	avg_index 		= 0
	for path in files:		
		#lowLight__std_rep032_exp001500.npy
		file = path.split('/')[-1][:-4]
		info = file.split('_')
		if(info[-3]=='std'):
			stdAll[std_index,:,:] = np.load(path)
			std_index += 1
			print(std_index,file)
		elif(info[-3]=='avg'):
			avgAll[avg_index,:,:] = np.load(path)
			avg_index += 1
			print(avg_index,file,np.mean(avgAll[avg_index-1,:,:]))


	sortByAvg = np.argsort(np.mean(avgAll,axis=(1,2)))
	avgAll = np.array([avgAll[i,:,] for i in sortByAvg])
	stdAll = np.array([stdAll[i,:,] for i in sortByAvg])
	return avgAll, stdAll

def getAllAvgStd2(readFolder,r=320,c=648):

	files = [os.path.join(readFolder,f) for f in sorted(os.listdir(readFolder))]

	#getBlackImage e.g. ./image/rep032/t6_black_image_avg.npy
	# print("black image is: ",files[-1])
	# blkImg  = np.load(files[-1]).astype(np.float)

	nof = len(files[:])//2
	avgAll	= np.zeros((nof,r,c))
	stdAll	= np.zeros((nof,r,c))

	std_index 		= 0
	avg_index 		= 0

	for path in files:
		# print(path)
		#path = ./image/rep032/std_le004999.npy
		f = path[15:18]

		#path = ./image/20201101/processed/rep032/std_04100.0.npy
		f = path[34:37]

		# ./image/20201106/processed/mask1_tap1/std_045000.npy
		f = path[38:41]		

		# ./image/20201112_ADC_Data/processed/std_002400.npy
		f = path[36:39]
		if(f=='std'):
			stdAll[std_index,:,:] = np.load(path).astype(np.float)
			std_index += 1
			print(std_index,path)
		elif(f=='avg'):
			# avgAll[avg_index,:,:] = blkImg - np.load(path)
			avgAll[avg_index,:,:] = np.load(path).astype(np.float)
			avg_index += 1
			print(avg_index,path,np.mean(avgAll[avg_index-1,:,:]))
		else:
			print("could not load:",path)

	sortByAvg = np.argsort(np.mean(avgAll,axis=(1,2)))
	print(sortByAvg)
	avgAll[avgAll<0] = 0

	# avgAll = np.array([avgAll[i,:,:] for i in sortByAvg[::-1]])
	# stdAll = np.array([stdAll[i,:,:] for i in sortByAvg[::-1]])
	return avgAll, stdAll



def ptcModel(x,nF,gain,exp,fwc):
	x = np.asarray(x)
	y = np.sqrt(nF**2 + gain*np.power(x,exp))
	y[x>fwc] = 0
	return y

def gainModel(x,gain,offset,fwc):
	x = np.asarray(x)
	y = gain*x + offset
	y[x>fwc] = 0
	return y

def convert2Mat(avgAll,stdAll,saveFolder):

	for i in range(len(avgAll)):
		data = {
			'avg':avgAll[i,:,:],
			'std':stdAll[i,:,:]
		}
		saveFile = os.path.join(saveFolder,str(i).zfill(3)+'.mat')
		print(saveFile)
		scipy.io.savemat(saveFile,data)

def convert2PNG(saveFolder,data):
	if(not(os.path.isdir(saveFolder))):
		os.system()


if(0):
	folder 		= "./image/20201112_ADC_Data/rawData/{}"
	saveFolder 	= "./image/20201112_ADC_Data/processed/"
	matFolder 	= "./image/20201112_ADC_Data/matlab/"

	nuSamp		= 200 #number of samples in folder

	voltageList = 	np.arange(100,2500,100)

	k = np.zeros((nuSamp,320,648))

	for volt in voltageList:
		#read from this folder
		f = folder.format(volt)

		#save .mat in this folder
		fMatSave = os.path.join(matFolder,"{:04d}.mat".format(int(volt)))

		if(os.path.isdir(f)):
			f1 = f
			# print(fMatSave)
			print(f)

			k=getImages(f1,nuAvg=100)
			data = {
				'allImgs':k[0:100,:,:].astype(np.uint16),
			}

			scipy.io.savemat(fMatSave,data)

			fNpySave = os.path.join(saveFolder,"avg_{:06d}.npy".format(int(volt)))
			np.save(fNpySave,k[-2,:,:])
			fNpySave = os.path.join(saveFolder,"std_{:06d}.npy".format(int(volt)))
			np.save(fNpySave,k[-1,:,:])

			print(np.mean(np.mean(k[:-2,:,:].astype(np.float))))

		else:
			print("Skipping: ", f )
	
	print("DONE")
	while(1):
		pass


rep = 1
tap = 1

readFolder 		= "./image/20201112_ADC_Data/processed"

voltList = 	np.arange(100,2500,100)

# [avgImgs,stdImgs] = getAllAvgStd(readFolder,rep)
[avgImgs,stdImgs] = getAllAvgStd2(readFolder)


cols = np.arange(19,324,50)
cols = np.arange(19,324,50) + 324*(tap-1)
rows = np.arange(19,240,50)
# rows = [100]
# cols = [160]
# rows = [40,120,200]

points = np.zeros((len(rows),len(cols)))
points = np.array([[[r,c] for c in cols] for r in rows])


jetmap = plt.get_cmap('jet')

plt.ion()
# k = np.reshape(jetmap(np.arange(240*648)/648/240)[:,:3],(240,-1,3))

k = np.transpose(np.reshape(jetmap(np.arange(240*324)/324/240)[:,:3],(324,-1,3)), axes=(1,0,2))

fig=plt.figure(1)
plt.clf()
ax=fig.subplots(ncols=1)
for c in cols:
	firstRow = True
	for r in rows:
		if(firstRow==True):
			ax.plot(voltList,avgImgs[:,r,c],'o-',color=k[r,c,:],linewidth=1,alpha=0.6,label="Column: {:03d}".format(c))
		else:
			ax.plot(voltList,avgImgs[:,r,c],'o-',color=k[r,c,:],linewidth=1,alpha=0.6)
		firstRow = False

plt.grid()
plt.xticks(voltList,rotation=90)
plt.yticks(np.arange(0,6000,500))
plt.xlabel('ADC input voltage (mV)')
plt.ylabel('ADC output (DN)')
plt.legend()
plt.title("ADC response")

plt.figure(2)
plt.clf()
plt.imshow(k)
plt.scatter(points[:,:,1],points[:,:,0],color='w')


# fig=plt.figure(3,(8,6))
# plt.clf()
# ax = fig.subplots(ncols=1)
# ax.grid('Major')
# for r in rows:
# 	for c in cols:
# 		ax.plot(np.log10(4000-avgImgs[:,r,c]),np.log10(stdImgs[:,r,c]),'x',color=k[r,c,:],linewidth=1,alpha=0.7)
# plt.xlabel("log(average - offset)",fontsize=14)
# # plt.xticks(range(0,4000,400),rotation=45,fontsize=14)
# plt.ylabel("log(std. deviation) DN",fontsize=14)
# plt.yticks(fontsize=14)

# plt.xlim( -2, 4)
# plt.ylim(0.6,1.6)
# plt.title(maskType+" rep:{:03d}".format(rep),fontsize=18)


# fig=plt.figure(4,(8,6))
# plt.clf()
# ax = fig.subplots(ncols=1)
# ax.grid('Major')
# for r in rows:
# 	for c in cols:
# 		ax.plot(avgImgs[:,r,c],stdImgs[:,r,c]**2,'x',color=jetmap((r*324+c)/324/240),linewidth=1,alpha=0.7)

# plt.xlabel("average - offset",fontsize=14)
# # plt.xticks(range(0,4000,400),rotation=45,fontsize=14)
# plt.ylabel("variance DN^2",fontsize=14)
# plt.yticks(fontsize=14)
# plt.title(maskType+" rep:{:03d}".format(rep),fontsize=18)
# plt.savefig("scripts/results/characterize_mean_vs_variance_"+maskType+"_rep:{:03d}.png".format(rep),bbox_inches='tight', dpi=300)


# #special row
# cols = [100]
# rows = [312]
# rows = np.arange(296,320)
# fig=plt.figure(3)
# for r in rows:
# 	for c in cols:
# 		plt.plot(np.log10(avgImgs[:,r,c]),np.log10(stdImgs[:,r,c]),'^',color=jetmap((r-rows[0])/len(rows)),linewidth=2,alpha=1,markersize=10)
# plt.savefig("scripts/results/characterize_PTC_"+maskType+"_rep:{:03d}.png".format(rep),bbox_inches='tight',dpi=300)


# ###Curve fitting

# ### Conversion Gain 
# cols = [100]
# rows = [312]
# # rows = np.arange(296,320)

# # cols = np.arange(19,324,50)
# # rows = np.arange(19,240,50)

# nop = len(cols)*len(rows)


# index=0
# fig = plt.figure(5,(8,6))
# fig.clf()
# ax = fig.subplots(ncols=1)

# gainIC 		= [0.2,		100,	5000]
# gainMax 	= [1,		500,	5000]
# gainMin		= [0.01,	0,		1000]

# gainFit = np.zeros((nop,3))

# for r in rows:
# 	for c in cols:
# 		avgData = avgImgs[:,r,c]
# 		stdData = stdImgs[:,r,c]
		
# 		gainFit[index,:],pcov 	= curve_fit(gainModel,avgData,stdData**2,p0=	gainIC,bounds=(gainMin,gainMax))



# 		plt.plot(avgData,stdData**2,'x',color=jetmap(index/nop),linewidth=1,alpha=0.7)

# 		p = gainFit[index,:]
# 		plt.plot(avgData,gainModel(avgData,p[0],p[1],p[2]),color=jetmap(index/nop),linewidth=2,alpha=0.7,label="({:03d}x{:03d}) y={:04.2f}x+{:6.2f}".format(r,c,p[0],p[1]))



# 		index += 1

# plt.legend()



# index=0
# fig = plt.figure(6,(8,6))
# fig.clf()
# ax = fig.subplots(ncols=1)

# ptcIC 	= [8,	6,		0.5,	200]
# ptcMin	= [0,	0,		0.2,	200]
# ptcMax 	= [100,	100,	1,		3500]

# ptcFit = np.zeros((nop,4))
# delta = 1e-6
# for r in rows:
# 	for c in cols:
# 		avgData = avgImgs[:,r,c]
# 		stdData = stdImgs[:,r,c]

# 		ptcIC[3] = gainFit[index,2]
# 		ptcMin[3] = gainFit[index,2]-delta
# 		ptcMax[3] = gainFit[index,2]+delta

# 		# ptcFit[index,:],pcov 	= curve_fit(ptcModel,avgData,stdData,p0=ptcIC,bounds=(ptcMin,ptcMax),maxfev=10000,method='dogbox')



# 		plt.plot(np.log10(avgData),np.log10(stdData),'x',color=jetmap(index/nop),linewidth=1,alpha=0.7)

# 		p = ptcFit[index,:]
		
# 		plt.plot(np.log10(avgData),np.log10(ptcModel(avgData,p[0],p[1],p[2],p[3])),color=jetmap(index/nop),\
# 			linewidth=2,alpha=0.7,label="({:03d}x{:03d}) nf={:04.2f} fwc={:06.1f} {:.2f}x^{:.2f}".format(r,c,p[0],p[3],p[1],p[2]))



# 		index += 1

# plt.legend()
