import numpy as np
import os
import matplotlib.pyplot as plt
cmap_heat = plt.get_cmap('plasma')

filePre = 'mask_{:04d}_ledExp_{:05.2f}'

# pixels to be plotted
cols = np.arange(19,324,50)
rows = np.arange(19,320,50)
nuPixels = cols.shape[0]*rows.shape[0]
pixels = np.zeros((nuPixels,2),dtype=np.int) 
pixels[:,0] = np.repeat(rows,len(cols))
pixels[:,1] = np.tile(cols,len(rows))


def getLists(folder,ledExpList,maskList):
	nuSamples = len(ledExpList)
	nuCases   = len(maskList)

	meanList = np.zeros((nuCases,nuPixels, nuSamples))
	stdList = np.zeros((nuCases,nuPixels, nuSamples))

	for onMasksNu, c in zip(maskList, range(nuCases)):
		blackFile = os.path.join(folder,filePre.format(onMasksNu,0))
		meanBlack = np.load(blackFile+'_mean.npy')
		for ledExp,s in zip(ledExpList,range(nuSamples)):
			file = os.path.join(folder,filePre.format(onMasksNu,ledExp))
			mean = meanBlack - np.load(file+'_mean.npy')
			# mean = 2**12-np.load(file+'_mean.npy')
			std  = np.load(file+'_std.npy')
			for p in range(nuPixels):
				meanList[c,p,s] = mean[pixels[p,0],pixels[p,1]]
				stdList[c,p,s]  = std[pixels[p,0],pixels[p,1]]

	return [meanList,stdList]

SuperMaskList = np.array([1,2,4,8,16,32,64,128,256,512,900,999])
maxSubframes = 900
meanAll 	= {}
stdAll  	= {}
illumAll 	= {}

for onMasksNu in SuperMaskList:
	meanAll[onMasksNu] = np.zeros((nuPixels,1))
	stdAll[onMasksNu] = np.zeros((nuPixels,1))
	illumAll[onMasksNu] = np.zeros((1))


# data01
folder = '../../image/PTC/data_01'
exposure 	= 26.5
ledExpList = exposure*np.logspace(-2,0,40)
maskList   = np.array([1,2,4,8,16,32,64,128,256,512,999])

[meanList,stdList] = getLists(folder,ledExpList,maskList)
stdList[:,:,0] = stdList[:,:,1]
nuSamples = len(ledExpList)
nuCases   = len(maskList)

for i in range(nuCases):
	meanAll[maskList[i]] = np.concatenate((meanAll[maskList[i]],meanList[i,]),axis=1)
	stdAll[maskList[i]]  = np.concatenate((stdAll[maskList[i]],stdList[i,]),axis=1)
	illumAll[maskList[i]] = np.concatenate((illumAll[maskList[i]],[ledExpList[i]]))
# # data02
folder = '../../image/PTC/data_02'
exposure 	= 26.5*5
ledExpList = exposure*np.logspace(-1,0,20)
maskList   = np.array([1,2,4,8,16])#,32])


[meanList,stdList] = getLists(folder,ledExpList,maskList)
stdList[:,:,0] = stdList[:,:,1]
nuSamples = len(ledExpList)
nuCases   = len(maskList)
for i in range(nuCases):
	meanAll[maskList[i]] = np.concatenate((meanAll[maskList[i]],meanList[i,]),axis=1)
	stdAll[maskList[i]]  = np.concatenate((stdAll[maskList[i]],stdList[i,]),axis=1)
	illumAll[maskList[i]] = np.concatenate((illumAll[maskList[i]],[ledExpList[i]]))

#data03
folder = '../../image/PTC/data_03'
exposure 	= 26.5
ledExpList = exposure*np.logspace(-4,0,20)[:8]
maskList   = np.array([16,32,64,128,256,512,999])[::-1]

[meanList,stdList] = getLists(folder,ledExpList,maskList)
stdList[:,:,0] = stdList[:,:,1]
nuSamples = len(ledExpList)
nuCases   = len(maskList)
for i in range(nuCases):
	meanAll[maskList[i]] = np.concatenate((meanAll[maskList[i]],meanList[i,]),axis=1)
	stdAll[maskList[i]]  = np.concatenate((stdAll[maskList[i]],stdList[i,]),axis=1)
	illumAll[maskList[i]] = np.concatenate((illumAll[maskList[i]],[ledExpList[i]]))

# 
#data04
folder = '../../image/PTC/data_04'
exposure 	= 26.5
ledExpList = exposure*np.logspace(-4,0,40)
maskList   = np.array([900])

[meanList,stdList] = getLists(folder,ledExpList,maskList)
stdList[:,:,0] = stdList[:,:,1]	
nuSamples = len(ledExpList)
nuCases   = len(maskList)
# stdList[0,:,:] = stdAll[999][:,:40]
for i in range(nuCases):
	meanAll[maskList[i]] = np.concatenate((meanAll[maskList[i]],meanList[i,]),axis=1)
	stdAll[maskList[i]]  = np.concatenate((stdAll[maskList[i]],stdList[i,]),axis=1)
	illumAll[maskList[i]] = np.concatenate((illumAll[maskList[i]],[ledExpList[i]]))

stdAll[900] = stdAll[999]
meanAll[900] = meanAll[999]
SuperMaskList = np.array([1,2,4,8,16,32,64,128,256,512,900])

# SORT THE ARRAY 
for i in meanAll:
	for p in range(nuPixels):
		j = np.argsort(meanAll[i][p,:])
		meanAll[i][p,:] = meanAll[i][p,j]
		stdAll[i][p,:] = stdAll[i][p,j]


nuPlots = len(SuperMaskList)
color = cmap_heat(np.arange(1,nuPlots+1)/nuPlots)*0.9

plt.ion()
plt.figure(1)
plt.clf()
p = 16
for onMasksNu,i in zip(SuperMaskList,range(nuPlots)):
	plt.semilogx(meanAll[onMasksNu][p,:]*maxSubframes/onMasksNu,stdAll[onMasksNu][p,:]**2,label="{:03d}".format(onMasksNu),\
		color=color[i])
plt.legend(title="n/1000 masks are ON")

#PTC
plt.figure(2)
plt.clf()
for onMasksNu,i in zip(SuperMaskList,range(nuPlots)):
	plt.plot(np.log10(meanAll[onMasksNu][p,:]),np.log10(stdAll[onMasksNu][p,:]),'o-',label="{:03d}".format(onMasksNu),\
		color=color[i])
plt.legend(title="n/1000 masks are ON")
plt.xlabel('log10(PIXEL VALUE (DN))',fontsize=20)
plt.ylabel('log10(NOISE)',fontsize=20)
plt.title("PHOTON TRANSFER CURVE")

#Dynamic range
plt.figure(3)
plt.clf()
allSNR = np.zeros((2,10000));snrIndex=0
for onMasksNu,i in zip(SuperMaskList,range(nuPlots)):
	illum 	= np.log10(meanAll[onMasksNu][p,:]*maxSubframes/onMasksNu)
	illum 	= meanAll[onMasksNu][p,:]*maxSubframes/onMasksNu
	signal 	= 20*np.log10(meanAll[onMasksNu][p,:])
	noise 	= 20*np.log10(stdAll[onMasksNu][p,:])
	snr = signal-noise
	if(i==0):
		mask = np.logical_and(snr<100, snr>0)
	else:
		mask = np.logical_and(snr<36, snr>0)
	nuvalidElements = len(illum[mask])
	allSNR[0,snrIndex:snrIndex+nuvalidElements] = illum[mask]
	allSNR[1,snrIndex:snrIndex+nuvalidElements] = snr[mask]
	snrIndex += nuvalidElements
	plt.semilogx(illum[mask],snr[mask],'o-',\
		label="{:03d}".format(onMasksNu), color=color[i])
plt.legend(title="n/1000 masks are ON")
plt.yticks(np.linspace(0,40,5))
plt.grid(which='major',linewidth=1.5,color='gray',alpha=0.7)
plt.grid(which='minor',alpha=0.5)
plt.xlabel('HDR SIGNAL (D.N.)',fontsize=20)
plt.ylabel('SNR (dB)',fontsize=20)
plt.xlim(1,10**7)
plt.ylim(0,45)
# plt.ylim((-10,40))

plt.show()
# input()