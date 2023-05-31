import numpy as np
import cv2
import matplotlib.pyplot as plt
import os

folder 		= './image/t6Exp005000Mask4_Tap{tap}/t6Exp005000Mask4_Rep{rep}__t6_merge.bmp'
folder 		= './image/t6Exp002000Mask4_Tap{tap}/t6Exp002000Mask4_Rep{rep}__t6_merge.bmp'

repList 	= range(1,40,1)
repList 	= [2,10,15,20,30,38]
repList 	= [1,2,4,8,15,20,25,30,35]

nuAvg 		= 10
tap 		= 2
# store averaged images in the numpy lists
rindex = 0
for r in repList:
	for i in range(nuAvg):
		file = os.path.join(folder.format(rep=str(r).zfill(3), tap=tap),str(i).zfill(4)+'.npy')
		if(i==0):
			avgImg = np.asarray(np.load(file),dtype=np.float)
		else:
			avgImg += np.asarray(np.load(file),dtype=np.float)

	if(rindex==0):
		avgImgList = np.zeros((len(repList),avgImg.shape[0],avgImg.shape[1]))
		blkImgList = np.zeros((len(repList),avgImg.shape[0],avgImg.shape[1]))		

	avgImgList[rindex,:,:] = avgImg[:,:]/nuAvg
	blkImgList[rindex,:,:] = np.load(os.path.join(folder.format(rep=str(r).zfill(3),tap=tap),'t6_black_image_avg.npy'))

	rindex += 1

# compute contrast
imgList = np.clip(blkImgList - avgImgList,0,1500)
t1List = imgList[:,:,:324]
t2List = imgList[:,:,324:]

contrast =	np.divide(t1List - t2List, t1List + t2List)
contrast[np.isnan(contrast)] = 0


plt.ion()
fig = plt.figure(1)
axs	= fig.subplots(nrows=3,ncols=3)
for r in range(0,len(repList)):
	ax = axs[r//3,r%3]
	# ax.hist(contrast[r,:,:].flatten(),bins=30,alpha=1)
	ax.imshow(contrast[r,:,:],cmap='jet',vmax=1,vmin=-1)
	ax.set_title("rep: {:02d}".format(r))

# plt.legend([str(r) for r in repList])
plt.show()

#row-296 doesn't exist among rows 1-320
testRows 	= np.concatenate(((200,250,282,294),range(296,320)),axis=0)
rowMedians 	= np.zeros((len(testRows),len(repList)))
rindex = 0
for r in testRows:
	rowMedians[rindex,:] = np.median(contrast[:,r,:],axis=1)
	rindex += 1

xaxis = np.arange(len(rowMedians))

fig = plt.figure(3,figsize=(12,6))
fig.clf()
ax = fig.subplots(ncols=1)
ax.grid('Major')
ax.plot(xaxis,rowMedians,'^--',linewidth=2,markersize=7,alpha=0.7)
testRowsFromTable = testRows
testRowsFromTable[testRows<296] += 1
plt.xticks(xaxis,testRows,rotation=45,fontsize=14)
plt.xlabel("Row Number",fontsize=14)
plt.yticks(fontsize=14)
plt.ylabel("Median of contrast",fontsize=14)
plt.legend(['{:02d}'.format(rep) for rep in repList],fontsize=14,title="Repetition Number")
plt.savefig("scripts/TestRow_Tap{}_ContrastMedians.png".format(tap),bbox_inches='tight')
plt.show()

testIndex = 20
rowUT = testRows[testIndex]
repMedians 	= np.zeros(len(repList))
rindex = 0
for r in repList:
	repMedians[rindex] = np.median(contrast[rindex,rowUT,:])
	rindex += 1

fig=plt.figure(4)
plt.plot(repMedians,'^--',linewidth=2,markersize=7,alpha=0.7)
plt.grid('Major')
plt.xticks(np.arange(len(repList)),repList,rotation=45,fontsize=14)
plt.xlabel("Repetition Number",fontsize=14)
plt.yticks(fontsize=14)
plt.ylabel("Median of contrast",fontsize=14)
plt.title('Test Row Number: {}'.format(testRowsFromTable[testIndex]),fontsize=14)
plt.savefig("scripts/TestRow:{}_Tap{}_ContrastMedians.png".format(testRowsFromTable[testIndex],tap),bbox_inches='tight')
plt.show()	
