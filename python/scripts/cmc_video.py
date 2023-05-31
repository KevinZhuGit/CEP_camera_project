import numpy as np
import cv2
import time

def getScaledPng(folder):
	black = np.asarray(np.load("../api/t6_black_image_avg.npy"),dtype=np.float)

	N=800
	allIms = np.zeros([N,320,648])

	ul = 2000

	for i in range(1,N+1):
		# print(folder+"{:04d}.npy".format(i-1))
		allIms[i-1,:,:] = black - np.asarray(np.load(folder+"{:04d}.npy".format(i)),dtype=np.float)

	allIms[allIms<0] = 0
	allIms[allIms>ul] = ul
	allIms = allIms*255/ul

	return np.asarray(allIms,dtype=np.uint8)
	# return allIms

def showTaps(tap):
	cv2.namedWindow("TAP")
	index = 0
	for i in range(len(tap)):
		cv2.imshow("TAP",tap[i,:,:])
		key = cv2.waitKey(1)

		# time.sleep(1/24)
		time.sleep(1/100)
		index+=1
	# cv2.destroyAllWindows()

def saveTaps(tap,prefix):
	index=0
	for img in tap:
		cv2.imwrite(prefix+"_{:04d}.png".format(index),img)
		index+=1

folder = "../image/t6Exp002000Mask15_name_t6_merge.bmp/"
allIms = getScaledPng(folder)


tap1 = allIms[:,:240,2:322]
tap2 = allIms[:,:240,326:646]
# showTaps(allIms[:,:240,2:322])
showTaps(tap2)

saveTaps(tap1,folder+"tap1")
saveTaps(tap2,folder+"tap2")

#ffmpeg -r 30 -start_number 0 -i tap1_%04d.png -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -vframes 800 -vcodec libx264 -crf 25 -pix_fmt yuv420p tap1_.mp4