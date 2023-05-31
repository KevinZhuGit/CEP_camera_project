import tkinter as tk
import random
from PIL import ImageTk, Image  
import numpy as np
import matplotlib.pyplot as plt
import time

class mainWindow():
	def __init__(self,title="Camera Characterization",h=320,w=648):
		self.window = tk.Tk()
		self.window.title(title)
		self.setGeometry(1080,720)

		self.height = h
		self.width 	= w

		self.window.bind('<Motion>',self.mouseMotion)

		sclExp = tk.Scale(self.window,command=lambda value: self.exposureUpdate(value),\
			label="EXP",from_=0, to=49,orient=tk.HORIZONTAL,tickinterval=5,\
			sliderlength=10,length=self.width)
		sclExp.grid(column=0,row=0,columnspan=6,rowspan=1)


		self.lbl_exp = tk.Label(self.window,text="Exp. Time")
		self.lbl_exp.grid(column=7,row=0,columnspan=2)

		self.info_str= tk.StringVar()
		self.info_str.set("HELLO WALLS")
		
		self.cvs = tk.Canvas(self.window,width=self.width, height=self.height)
		self.cvs.grid(column=0,row=1,columnspan=6,rowspan=24)
		self.cvs_winfo_rootx = self.cvs.winfo_x()
		self.cvs_winfo_rooty = self.cvs.winfo_y()
		print(self.cvs_winfo_rootx,self.cvs_winfo_rooty)
		# self.cvs.create_image(0,0,image=self.window.img,anchor='nw')
		
		self.cvs.bind('<Button-1>',self.mouseButton1)
		self.cvs.bind('<B1-Motion>',lambda event: self.mouseButton1Motion(event))

		# Create labels for left and right taps
		lbl = tk.Label(self.window, text="TAP 1")
		lbl.grid(column=1,row=26)
		lbl = tk.Label(self.window, text="TAP 2")
		lbl.grid(column=4,row=26)

		# Text entries for lower and upper limits
		lbl = tk.Label(self.window,text="low clip",anchor='s')
		lbl.grid(column=7,row=1)
		self.txt_lo = tk.Entry(self.window,width=10)
		self.txt_lo.grid(column=7,row=2)
		self.txt_lo.insert(0,'200')

		lbl = tk.Label(self.window,text="high clip",anchor='s')
		lbl.grid(column=8,row=1)
		self.txt_hi = tk.Entry(self.window,width=10)
		self.txt_hi.grid(column=8,row=2)
		self.txt_hi.insert(0,'4500')

		# Text entries for pixel location
		lbl = tk.Label(self.window,text="pix: x",anchor='s')
		lbl.grid(column=7,row=3)
		self.txt_pixX = tk.Entry(self.window,width=10)
		self.txt_pixX.grid(column=7,row=4)
		self.txt_pixX.insert(0,'100')

		lbl = tk.Label(self.window,text="pix: y",anchor='s')
		lbl.grid(column=8,row=3)
		self.txt_pixY = tk.Entry(self.window,width=10)
		self.txt_pixY.grid(column=8,row=4)
		self.txt_pixY.insert(0,'100')

		#Information string
		self.lbl_info = tk.Label(self.window,textvariable=self.info_str)
		self.lbl_info.grid(column=0,row=27,columnspan=6,rowspan=1)

		#buttons
		btnPlot = tk.Button(self.window, text="Click Me",command=lambda: self.plotVariance(lbl,txt))
		btnPlot.grid(column=1,row=27)

		btnPlot = tk.Button(self.window,text="avg",command=lambda: self.plotAvg())
		btnPlot.grid(column=7,row=5)

		btnPlot = tk.Button(self.window,text="var",command=lambda: self.plotVar())
		btnPlot.grid(column=8,row=5)

		btnPlot = tk.Button(self.window,text="hist",command=lambda: self.plotHist())
		btnPlot.grid(column=7,row=6)

		btnPlot = tk.Button(self.window,text="Close all",command=lambda: self.plotClose())
		btnPlot.grid(column=8,row=27)


		self.cvs_x = 0
		self.cvs_y = 0




	#GUI functions
	def mouseMotion(self,event):
		# self.window_x, self.window_y = event.x, event.y
		self.window_x = self.window.winfo_pointerx() - self.window.winfo_rootx()
		self.window_y = self.window.winfo_pointery() - self.window.winfo_rooty()

		cvs_x = self.window_x - self.cvs_winfo_rootx
		cvs_y = self.window_y - self.cvs_winfo_rooty
		if(cvs_x>=0 and cvs_x<self.width and cvs_y>=0 and cvs_y<self.height):
			self.cvs_x 	= cvs_x%(self.width//2)
			self.cvs_y 	= cvs_y
		
		x = self.cvs_x
		y = self.cvs_y
		
		self.info_str.set("({:03d}, {:03d}) avg:{:6.1f} std:{:6.1f}".format(x,y,
			self.avg_m[self.value,y,x],self.std_m[self.value,y,x]))


	def mouseButton1(self,event):
		print("Button pressed at pixel: ",self.cvs_x,self.cvs_y)
		self.pix_x = self.cvs_x
		self.pix_y = self.cvs_y
		
		self.txt_pixX.delete(0,tk.END)
		self.txt_pixY.delete(0,tk.END)	
		self.txt_pixX.insert(tk.END,self.pix_x)
		self.txt_pixY.insert(tk.END,self.pix_y)

	def mouseButton1Motion(self,event):
		i=1
		# print("dragging")

	def getWindow(self):
		return self.window

	def showWindow(self):
		self.window.mainloop()

	def setGeometry(self,width,height):
		self.window.geometry('{:d}x{:d}'.format(width,height))

	def updateGUI(self):
		print(updateGUI)

	def imageFormat(self,image,upper=4700,lower=500):
		img_tmp = 255 - (np.clip(image, lower, upper)-lower)*255/(upper-lower)
		img_tmp = img_tmp.astype(np.uint8)
		
		return ImageTk.PhotoImage(Image.fromarray(img_tmp))
	# def 

	#Events
	def plotVariance(self,lbl,txt):
		lbl.configure(text="Button was clicked !! {:s}".format(txt.get()))
		print("plotting Variance")

	def exposureUpdate(self,value):
		value 		= int(value)
		self.value 	= value
		self.exp 	= self.exposures[value]
		self.img 	= self.imageFormat(self.avg_m[value],\
			upper=float(self.txt_hi.get()),\
			lower=float(self.txt_lo.get()))

		self.lbl_exp.configure(text="Exp Time = {:8.4f}ms".format(self.exp*1000))
		
		self.cvs.create_image(0,0,image=self.img,anchor='nw')
		self.cvs_winfo_rootx = self.cvs.winfo_x()
		self.cvs_winfo_rooty = self.cvs.winfo_y()
		print(self.cvs_winfo_rootx,self.cvs_winfo_rooty)

		print("{:02d}: {:f}".format(value,self.exposures[value]))
		self.lbl_exp.configure()

	#Data
	def readData(self,readFolder):
		self.exposures   = np.load(readFolder+"exposures.npy")
		self.avg_m 		 = np.load(readFolder+"avg_m.npy")
		self.std_m 		 = np.load(readFolder+"std_m.npy")
		self.var_m 		 = np.load(readFolder+"var_m.npy")

		self.gain_dn_m   = np.load(readFolder+"gain_dn_m.npy")  
		self.black_pt_m  = np.load(readFolder+"black_pt_m.npy") 
		self.sat_time_m  = np.load(readFolder+"sat_time_m.npy") 
		self.fwc_m       = np.load(readFolder+"fwc_m.npy")      
		self.tol1_m      = np.load(readFolder+"tol1_m.npy")     
		self.tol2_m      = np.load(readFolder+"tol2_m.npy")     
		self.gain_conv_m = np.load(readFolder+"gain_conv_m.npy")
		self.var_ns_m    = np.load(readFolder+"var_ns_m.npy")   
		self.snr_m       = np.load(readFolder+"snr_m.npy")      

	def systemModel(self,t, gain_dn, bl, sat_time, fwc, tol1, tol2):
		"""
		Returns a piecewise function modeling a linear system response

		Parameters:
		t (ndarray): array of exposure times in us
		gain_dn (float): gain of model
		bl (float): black point of model
		sat_time (float): time of saturation of model
		fwc (float): full well capacity of model
		tol1 (float): tolerance for first piecewise joint
		tol2 (float): tolerance for second piecewise joint

		Returns:
		(ndarray): a piecewise function of our linear camera model

		"""
		return np.piecewise(
			t, 
			[(t < tol1), (t < sat_time) & (t >= tol1), (t >= sat_time)], 
			[ lambda x: bl,
			lambda x: (-1.0)*gain_dn*x+bl-tol2, 
			lambda x: (-1.0)*gain_dn*sat_time+(-1.0)*tol2*tol1+bl-tol2-fwc
			]
		)

	def plotAvg(self):
		x = int(self.txt_pixY.get())
		y = int(self.txt_pixX.get())

		plt.ion()
		SAT = self.sat_time_m[x,y]
		print("SAT:{:f}".format(SAT))
		# fig = plt.figure(figsize=(12, 4))
		fig, ax1 = plt.subplots(figsize=(10, 4))
		color = 'tab:blue'
		ax1.set_xlabel("Exposure [ms]")
		ax1.set_ylabel("Tap1 Response [DN]", color=color)
		ax1.scatter(self.exposures*1000, self.avg_m[:,x,y], color=color, s=16, alpha=0.9, label='tap 1 -- response')

		ax1.plot(
			self.exposures[:SAT]*1000, 
			self.systemModel(self.exposures[:SAT], self.gain_dn_m[x,y], self.black_pt_m[x,y],\
			 SAT, self.fwc_m[x,y], self.tol1_m[x,y], self.tol2_m[x,y]),
			linestyle="-", 
			label=r"Fit: y = {0:.2f}t+{1:.2f}".format(self.gain_dn_m[x,y], self.black_pt_m[x,y]), 
			color='orange'
			)
		major_ticks = np.arange(0, 501, 100)
		minor_ticks = np.arange(0, 501, 25)		
		ax1.set_xticks(major_ticks)
		ax1.set_xticks(minor_ticks, minor=True)
		ax1.legend()
		plt.grid(axis='both')
		
		ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
		color = 'tab:purple'
		ax2.set_ylabel("Tap2 Response [DN]", color=color)  # we already handled the x-label with ax1
		ax2.scatter(self.exposures*1000, self.avg_m[:,x,y+324], color=color, s=16, alpha=0.5, label='tap 2 -- leakage')

		ax2.legend(loc=7)

		plt.title("Tap1 & Tap2 OFF: pixel (%d, %d)" % (x,y))
		fig.tight_layout()  # otherwise the right y-label is slightly clipped
		# plt.show()

	def plotVar(self):
		x = int(self.txt_pixY.get())
		y = int(self.txt_pixX.get())

		SAT = self.sat_time_m[x,y]
		print("SAT:{:f}".format(SAT))

		plt.ion()
		fig = plt.figure(figsize=(10, 4))
		plt.plot(self.avg_m[:SAT,x,y], -self.gain_conv_m[x,y]*self.avg_m[:SAT,x,y]+self.var_ns_m[x,y], linestyle="-", label=r"Fit: y = -{0:.2f}t+{1:.2f}".format(self.gain_conv_m[x,y],self.var_ns_m[x,y]), color='orange')
		plt.scatter(self.avg_m[:,x,y], self.var_m[:,x,y], label="sensor", s=12)
		plt.xlabel("Average DN")
		plt.ylabel("Variance [DN]^2")
		plt.title("Tap1 ON | Tap2 OFF: pixel (%d, %d)" % (x,y))
		plt.legend()
		plt.grid()
		# time.sleep(5)
		# plt.close('all')
		# plt.show()

	def plotClose(self):
		plt.close('all')

	def plotHist(self):
		fig = plt.figure(figsize=(18, 8))
		grid = plt.GridSpec(2, 3, wspace=0.4, hspace=0.5)
		ax1 = fig.add_subplot(grid[0, 0], title="Gain Conversion Factor")
		ax2 = fig.add_subplot(grid[0, 1:],title="Histogram of Gain Conversion Factor [e-/DN]", xlabel="Gain Conversion Factor [e-/DN]", ylabel="Normalized Counts")
		ax3 = fig.add_subplot(grid[1, 0], title="Variance")
		ax4 = fig.add_subplot(grid[1, 1:], title="Histogram of Variance", xlabel="Variance [std^2]", ylabel="Normalized Counts")

		im1 = ax1.imshow(self.gain_conv_m, cmap='gray', vmin=np.min(self.gain_conv_m), vmax=np.max(self.gain_conv_m), interpolation='none')
		fig.colorbar(im1, ax=ax1)
		n, bins, patches = ax2.hist(self.gain_conv_m.flatten(), 100, density=True, alpha=0.6)
		ax2.grid('on')

		im3 = ax3.imshow(self.var_ns_m, cmap='gray', vmin=np.min(self.var_ns_m), vmax=np.max(self.var_ns_m), interpolation='none')
		fig.colorbar(im3, ax=ax3)
		n, bins, patches = ax4.hist(self.var_ns_m.flatten(), 100, density=True, alpha=0.6)
		ax4.grid('on')

if __name__ == '__main__':
	root=mainWindow("T6")




	root.showWindow()