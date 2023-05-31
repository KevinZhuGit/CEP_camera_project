import numpy as np
import cv2
import matplotlib.pyplot as plt
import os
import matplotlib as mpl
from scipy.optimize import curve_fit

import scipy.io



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
	y = -1*gain*x + offset
	y[x<fwc] = 10
	return y

def findgainFit(y,x,fwc):
	x = np.asarray(x)
	y = np.asarray(y)


	cutoff = np.where(x>fwc)[-1][-1]	
	print(cutoff)	
	x = x[cutoff:]
	y = y[cutoff:]

	return np.polyfit(x,y,1)


def convert2Mat(avgAll,stdAll,saveFolder):

	for i in range(len(avgAll)):
		data = {
			'avg':avgAll[i,:,:],
			'std':stdAll[i,:,:]
		}
		saveFile = os.path.join(saveFolder,str(i).zfill(3)+'.mat')
		print(saveFile)
		scipy.io.savemat(saveFile,data)
class clickOnMe(object):
	def __init__(self,expList,avgImgs,stdImgs):
		print("starting Interactive class")
		self.expList = expList
		self.avgImgs = avgImgs
		self.stdImgs = stdImgs
		self.avgImgFigIndex = 10
		self.systemRespFigIndex=11
		self.varianceFigIndex = 12
		self.pixelList =[]
		self.gainFitList = []
		self.fitLine = True

	def showAvgImg(self,exposureTime,figIndex):
		expList=self.expList
		avgImgs=self.avgImgs
		

		imgIndex 	= abs(expList- exposureTime).argmin()
		print("Ploting average image {} with exposure time {}us".format(imgIndex,expList[imgIndex]))

		figIndex = self.avgImgFigIndex
		plt.close(figIndex)
		fig = plt.figure(figIndex,(8,6))
		# plt.clf()
		ax = fig.subplots(ncols=1)

		im=ax.imshow(avgImgs[imgIndex,:,:])
		fig.colorbar(im)

		cid = fig.canvas.mpl_connect('button_press_event', self.addPixel)


	def openAvgImg(self,event):
		print('%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
			('double' if event.dblclick else 'single', event.button,
			event.x, event.y, event.xdata, event.ydata))
		self.showAvgImg(event.xdata,10)

	def addPixel(self,event):
		print('%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' %
			('double' if event.dblclick else 'single', event.button,
			event.x, event.y, event.xdata, event.ydata))

		r = int(round(event.ydata))
		c = int(round(event.xdata))

		avgData = self.avgImgs[:,r,c]
		stdData = self.stdImgs[:,r,c]

		self.pixelList.append([r,c])
		if(self.fitLine):
			# p,pcov 	= curve_fit(gainModel,avgData,stdData**2,p0=gainIC,bounds=(gainMin,gainMax),maxfev=10000)
			p 		= findgainFit(stdData**2,avgData,3750)
			self.gainFitList.append(p)
		self.plotSysResp()
		# self.plotVariance()
		self.plotVarianceModel()

	def plotSysResp(self):
		expList = self.expList
		avgImgs = self.avgImgs
		stdImgs = self.stdImgs
		figIndex = self.systemRespFigIndex

		plt.close(figIndex)
		fig=plt.figure(figIndex)
		ax = fig.subplots(ncols=1)

		for pixel in self.pixelList:
			r = pixel[0]
			c = pixel[1]
			ax.plot(expList,avgImgs[:,r,c],'-o',label='row:{:03d} col:{:03d}'.format(r,c))		
		plt.xlabel('exposure time (us)')
		plt.ylabel('ADC value')
		plt.legend()

	def plotVariance(self):
		expList = self.expList
		avgImgs = self.avgImgs
		stdImgs = self.stdImgs
		figIndex = self.varianceFigIndex

		plt.close(figIndex)
		fig=plt.figure(figIndex)
		ax = fig.subplots(ncols=1)

		for pixel in self.pixelList:
			r = pixel[0]
			c = pixel[1]
			ax.plot(avgImgs[:,r,c],stdImgs[:,r,c]**2,'-o',label='row:{:03d} col:{:03d}'.format(r,c))		
		plt.xlabel('ADC value')
		plt.ylabel('variance')
		plt.legend()

	def plotVarianceModel(self):
		expList = self.expList
		avgImgs = self.avgImgs
		stdImgs = self.stdImgs
		figIndex = self.varianceFigIndex

		gainIC 		= [0.02,	1000,	10]
		gainMax 	= [1,		100000,	100000]
		gainMin		= [0,		0,		0]

		plt.close(figIndex)
		fig=plt.figure(figIndex)
		ax = fig.subplots(ncols=1)


		gainFit = np.zeros((nop,3))



		for pixel,p in zip(self.pixelList,self.gainFitList):
			r = pixel[0]
			c = pixel[1]

			avgData = avgImgs[:,r,c]
			stdData = stdImgs[:,r,c]

			plt.plot(avgData,stdData**2,'x',linewidth=1,alpha=0.7)
			# plt.plot(avgData,gainModel(avgData,p[0],p[1],p[2]),linewidth=2,alpha=0.7,label="({:03d}x{:03d}) y={:04.2f}x+{:6.2f}".format(r,c,p[0],p[1]))
			plt.plot(avgData,p[0]*avgData+p[1],linewidth=2,alpha=0.7,label="({:03d}x{:03d}) y={:04.2f}x+{:6.2f}".format(r,c,p[0],p[1]))

		plt.xlabel('ADC value')
		plt.ylabel('variance')
		plt.legend()



def convert2PNG(saveFolder,data):
	if(not(os.path.isdir(saveFolder))):
		os.system()


rep = 1
readFolder = './image/rep{:03d}'.format(rep)
readFolder = './image/20201103/processed/rep{:03d}'.format(rep)
maskType 		= 'rep: {:03d}'.format(rep)

mask,tap = 2,1
readFolder = './image/20210211/processed/mask{}_tap{}/'.format(mask,tap)
# expList 	= np.concatenate((np.logspace(np.log10(54),np.log10(20000),30),np.arange(25000,100000,5000),np.arange(100000,300000,20000)))*mask
expList 	= np.concatenate((np.logspace(np.log10(27),np.log10(20000),30),np.arange(25000,100000,5000),np.arange(100000,300000,20000),np.arange(300000,500000,50000)))
expList 	= np.logspace(np.log10(27),np.log10(30000),50)

# [avgImgs,stdImgs] = getAllAvgStd(readFolder,rep)
[avgImgs,stdImgs] = getAllAvgStd2(readFolder)


cols = np.arange(19,324,25)
cols = np.arange(19,324,25) + 324*(tap-1)
cols = np.concatenate((np.arange(0,320,75),np.arange(0,320,75)+324))
rows = np.arange(19,240,25)
# cols = [160]
# rows = [40,120,200]

points = np.zeros((len(rows),len(cols)))
points = np.array([[[r,c] for c in cols] for r in rows])


jetmap = plt.get_cmap('jet')

plt.ion()
k = np.reshape(jetmap(np.arange(240*648)/648/240)[:,:3],(240,-1,3))

# k = np.transpose(np.reshape(jetmap(np.arange(240*324)/324/240)[:,:3],(324,-1,3)), axes=(1,0,2))


#interactive class
plots = clickOnMe(expList,avgImgs,stdImgs)


fig=plt.figure(1)
plt.clf()
ax=fig.subplots(ncols=1)
for r in rows:
	for c in cols:
		ax.plot(expList,avgImgs[:,r,c],'o-',color=k[r,c,:],linewidth=1,alpha=0.7)

plt.figure(2)
plt.clf()
plt.imshow(k)
plt.scatter(points[:,:,1],points[:,:,0],color='w')
cid = fig.canvas.mpl_connect('button_press_event', plots.openAvgImg)

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
cols = [100]
rows = [312]
# # rows = np.arange(296,320)

# cols = np.arange(19,324,50)
# rows = np.arange(119,240,50)

nop = len(cols)*len(rows)


index=0
fig = plt.figure(5,(8,6))
fig.clf()
ax = fig.subplots(ncols=1)

gainIC 		= [0.02,	1000,	10]
gainMax 	= [1,		100000,	100000]
gainMin		= [0,		0,		0]

gainFit = np.zeros((nop,3))

for r in rows:
	for c in cols:
		avgData = avgImgs[:,r,c]
		stdData = stdImgs[:,r,c]
		
		gainFit[index,:],pcov 	= curve_fit(gainModel,avgData,stdData**2,p0=gainIC,bounds=(gainMin,gainMax),maxfev=10000)



		plt.plot(avgData,stdData**2,'x',color=jetmap(index/nop),linewidth=1,alpha=0.7)

		p = gainFit[index,:]
		plt.plot(avgData,gainModel(avgData,p[0],p[1],p[2]),color=jetmap(index/nop),linewidth=2,alpha=0.7,label="({:03d}x{:03d}) y={:04.2f}x+{:6.2f}".format(r,c,p[0],p[1]))



		index += 1

plt.legend()



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


# #Interactive figure
# fig = plt.figure(7,(8,6))
# fig.clf()
# ax = fig.subplots(ncols=1)
