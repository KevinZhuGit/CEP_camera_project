import numpy as np
import os
import cv2
import time

folder = "./image/mirror_test_0214-2300/"
file =  "average_band_w{:02d}_s{:02d}_t4Exp000087Mask161-PW10.0_HT10000.0_DL672500.0_img0020.png"
file = "original_band_w{:02d}_s{:02d}_t4Exp000087Mask161-PW10.0_HT10000.0_DL672500.0_img0020.png"

width = np.arange(1,50)
space = np.arange(2,60,2)


font 		= cv2.FONT_HERSHEY_SIMPLEX 
window_name = 'Image'
org 		= (150, 300)
fontScale 	= 1
color 		= (255,0,0)
thickness 	= 2

cv2.namedWindow(window_name)
s = 14
fno = 0
for w in width:
	for s in space:
		img = cv2.imread(folder+file.format(w,s),-1)
		img = cv2.cvtColor(img,cv2.COLOR_GRAY2RGB)

		info = "Width: {:02d} Spacing: {:02d}".format(w,s)

		img = cv2.putText(img, info, org, font,  
	                   fontScale, color, thickness, cv2.LINE_AA) 

		cv2.imshow(window_name,img)
		key = cv2.waitKey(1)
		time.sleep(0.010)
		if(key==27):
			break

		cv2.imwrite('./image/workDir/{:04d}.png'.format(fno),img)
		fno += 1