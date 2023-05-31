import glob
import random
import numpy as np
import pandas as pd
from scipy.io import loadmat
import matplotlib.pyplot as plt
from matplotlib.pyplot import imshow
from scipy.optimize import curve_fit


def per_pixel_stats(path, filenames, height, width):
  """
  Returns per pixel mean, std and variance given 3D matrices 
  (number of images captured per exposure x height x width) 
  for a list of exposure times
  
  Assumes: 
  1. exposure times and filenames of 3D matrices are 1:1 mappings
  2. input data is in MATLAB .mat format

  Parameters:
      path (string): directory containing data
      filenames (list of strings): list of filenames -- one filename per exposure
      height (int): height of image in number of pixels
      width (int): width of image in number of pixels

  Returns:
      avg_m (ndarray): 2D matrix (number of exposures x width x height matrix) 
                       of mean value per pixel
      std_m (ndarray): 2D matrix (number of exposures x width x height matrix) 
                       of std value per pixel
      var_m (ndarray): 2D matrix (number of exposures x width x height matrix) 
                       of variance per pixel
  """
  shape = (len(filenames), height, width)
  avg_m = np.zeros(shape).astype(np.float32)
  std_m = np.zeros(shape).astype(np.float32)
  var_m = np.zeros(shape).astype(np.float32)

  for i, f in enumerate(filenames):
    mat = loadmat(path+f)['allImgs'] # TODO: Needs to be modified based on input datatype
    mat[mat < 0] = 0 # Rahul says all negative values are just set to zero
    avg_m[i,:,:] = mat.mean(axis=0)
    std_m[i,:,:] = mat.std(axis=0)
    var_m[i,:,:] = np.square(mat.std(axis=0))
  
  return avg_m, std_m, var_m

class cameraModel():
  def __init__(self,shape,exposures,avg_m,std_m,var_m):
    self.shape = shape
    self.exposures = exposures
    self.avg_m = avg_m
    self.std_m = std_m
    self.var_m = var_m

    assert len(exposures) ==shape[0], \
    "Total number of exposures, #{} must be equal to shape[0], #{}".format(len(exposures),shape[0])
    assert self.avg_m.shape    == self.shape, \
    "avg_m.shape {} should be equal to input shape {}".format(self.avg_m.shape,self.shape)
    assert self.std_m.shape    == self.shape, \
    "avg_m.shape {} should be equal to input shape {}".format(self.std_m.shape,self.shape)
    assert self.var_m.shape    == self.shape, \
    "avg_m.shape {} should be equal to input shape {}".format(self.var_m.shape,self.shape)

    # Must feed in initial guesses -- should be tweaked per camera
    self.systemMax   = [200000,  6500, 0.4, 2500, 0.002, 1000]
    self.systemMin   = [10000 ,  0,    0.002, -50, 0, 0]
    self.systemIC    = [20000 ,  4500,   0.05, 0, 0.0008, 200]

  
  def systemModel(self, t, gain_dn, bl, sat_time, fwc, tol1, tol2):
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

  def apply_model_per_pixel(self,pixels,PRE=4,TOL=2):
    """
    Returns the model fit parameters such as:  
    gain, black level, saturation time, read noise, full well capacity, snr

    Parameters:
      pixels : Is a list of (x,y) co-ordinates
      PRE (int): number of exposures at the beginning (nonlinear regions) to exclude
      TOL (int): number of exposures to decrease to from the estimated time of saturation
    """
    exposures = self.exposures
    avg_m     = self.avg_m
    std_m     = self.std_m
    var_m     = self.var_m

    # Define shape of data to save fits in
    shape = (self.shape[1],self.shape[2])
    
    # Define matrices to save fits
    gain_dn_m   = np.zeros(shape).astype(np.float32)  # In units DN / sec
    gain_conv_m = np.zeros(shape).astype(np.float32)  # In units e- / 8bit DN
    var_ns_m    = np.zeros(shape).astype(np.float32)
    black_pt_m  = np.zeros(shape)
    snr_m       = np.zeros((len(exposures), shape[0], shape[1])).astype(np.float32)
    fwc_m       = np.zeros(shape).astype(np.float32)
    sat_time_m  = np.zeros(shape).astype(np.int8)
    tol1_m      = np.zeros(shape).astype(np.float32)
    tol2_m      = np.zeros(shape).astype(np.float32)

    for pix in pixels:
      (x,y) = pix

      # Find constants
      try:
        fit, pcov = curve_fit(
            systemModel, 
            exposures, 
            avg_m[:,x,y], 
            p0=systemIC, 
            bounds=(systemMin, systemMax), 
            ftol=0.01, 
            xtol=0.001
          )
        SAT = np.where(exposures >= fit[2])[0][0]-TOL
        # Get values
        gain_dn_m[x,y] = fit[0]
        black_pt_m[x,y] = fit[1]
        sat_time_m[x,y] = SAT
        fwc_m[x,y] = fit[3]
        tol1_m[x,y] = fit[4]
        tol2_m[x,y] = fit[5]
        # Find gain conversion and read noise
        m, b = np.polyfit(avg_m[PRE:SAT,x,y], var_m[PRE:SAT,x,y], 1)
        gain_conv_m[x,y] = (-1.0)*m  # e-/DN
        var_ns_m[x,y] = b

        # Find SNR
        snr_m[:SAT,x,y] = avg_m[:SAT,x,y] / std_m[:SAT,x,y]

      except:
      # except RuntimeError:
        # If something is wrong, set all other results to nan
        SAT = -1
        print("Could not fit", x, y)
        gain_dn_m[x,y] = np.nan
        black_pt_m[x,y] = np.nan
        sat_time_m[x,y] = -1
        fwc_m[x,y] = np.nan
        tol1_m[x,y] = np.nan
        tol2_m[x,y] = np.nan
        gain_conv_m[x,y] = np.nan
        var_ns_m[x,y] = np.nan
        snr_m[:SAT,x,y] = np.nan
      
      # print("Processing: {:5.2f}%".format(((y_end-y_start)*x+y)\
      #   /(y_end-y_start)/(x_end-x_start)*100),end='\r')

    return gain_dn_m, black_pt_m, sat_time_m, fwc_m, tol1_m, tol2_m, gain_conv_m, var_ns_m, snr_m


  def apply_model(self, exposures, avg_m, std_m, var_m, height, width, x_start=0, x_end=None, y_start=0, y_end=None, PRE=4, TOL=2):
    """
    Returns the model fit parameters such as:  
    gain, black level, saturation time, read noise, full well capacity, snr

    Parameters:
        exposures (ndarray): list of exposure times in float
        avg_m (ndarray): 2D matrix (height x width) of mean DN measured per pixel
        std_m (ndarray): 2D matrix (height x width) of std DN measured per pixel
        var_m (ndarray): 2D matrix (height x width) of variance in DN measured per pixel
        height (int): height of image in number of pixels
        width (int): width of image in number of pixels
        x_start (int): index marking start of region of interest (width)
        x_end (int): index marking end of region of interest (width)
        y_start (int): index marking start of region of interest (height)
        y_end (int): index marking end of region of interest (height)
        PRE (int): number of exposures at the beginning (nonlinear regions) to exclude
        TOL (int): number of exposures to decrease to from the estimated time of saturation

    Returns:
        gain_dn_m (ndarray): 2D matrix (height x width) of system gain in DN/s
        black_pt_m (ndarray): 2D matrix (height x width) of black level in DN
        sat_time_m (ndarray): 2D matrix (height x width) of index in list of exposures that saturation occurs
        fwc_m (ndarray): 2D matrix (height x width) of full well capacity in DN
        tol1_m (ndarray): 2D matrix (height x width) of tolerance in the region of low exposures
        tol2_m (ndarray): 2D matrix (height x width) of tolerance in the region just before saturation
        gain_conv_m (ndarray): 2D matrix (height x width) of conversion gain in DN/e-
        var_ns_m (ndarray): 2D matrix (height x width) of read noise squared in DN^2
        snr_m (ndarray): 2D matrix (height x width) of analytical SNR
    """
    # If no region of interest is defined, set to img dimensions
    if x_end is None:
      x_end = height
    if y_end is None: 
      y_end = width

    # Define shape of data to save fits in
    shape = (height, width)

    # Define matrices to save fits
    gain_dn_m = np.zeros(shape).astype(np.float32)  # In units DN / sec
    gain_conv_m = np.zeros(shape).astype(np.float32)  # In units e- / 8bit DN
    var_ns_m = np.zeros(shape).astype(np.float32)
    black_pt_m = np.zeros(shape)
    snr_m = np.zeros((len(exposures), shape[0], shape[1])).astype(np.float32)
    fwc_m = np.zeros(shape).astype(np.float32)
    sat_time_m = np.zeros(shape).astype(np.int8)
    tol1_m = np.zeros(shape).astype(np.float32)
    tol2_m = np.zeros(shape).astype(np.float32)

    # Iterate overregion of interest
    for x in range(x_start, x_end):
      for y in range(y_start, y_end): 

        # Find constants
        try:
          fit, pcov = curve_fit(
              systemModel, 
              exposures, 
              avg_m[:,x,y], 
              p0=systemIC, 
              bounds=(systemMin, systemMax), 
              ftol=0.01, 
              xtol=0.001
            )
          SAT = np.where(exposures >= fit[2])[0][0]-TOL

          # Get values
          gain_dn_m[x,y] = fit[0]
          black_pt_m[x,y] = fit[1]
          sat_time_m[x,y] = SAT
          fwc_m[x,y] = fit[3]
          tol1_m[x,y] = fit[4]
          tol2_m[x,y] = fit[5]
          # Find gain conversion and read noise
          m, b = np.polyfit(avg_m[PRE:SAT,x,y], var_m[PRE:SAT,x,y], 1)
          gain_conv_m[x,y] = (-1.0)*m  # e-/DN
          var_ns_m[x,y] = b

          # Find SNR
          snr_m[:SAT,x,y] = avg_m[:SAT,x,y] / std_m[:SAT,x,y]
      
        except:
        # except RuntimeError:
          # If something is wrong, set all other results to nan
          print("Could not fit", x, y)
          gain_dn_m[x,y] = np.nan
          black_pt_m[x,y] = np.nan
          sat_time_m[x,y] = -1
          fwc_m[x,y] = np.nan
          tol1_m[x,y] = np.nan
          tol2_m[x,y] = np.nan
          gain_conv_m[x,y] = np.nan
          var_ns_m[x,y] = np.nan
          snr_m[:SAT,x,y] = np.nan
        
        print("Processing: {:5.2f}%".format(((y_end-y_start)*x+y)\
          /(y_end-y_start)/(x_end-x_start)*100),end='\r')
    return gain_dn_m, black_pt_m, sat_time_m, fwc_m, tol1_m, tol2_m, gain_conv_m, var_ns_m, snr_m

  def apply_model_full_array(self, PRE=4, TOL=2):
    (HEIGHT,WIDTH) = self.shape
    return self.apply_model(
                self.exposures,
                self.avg_m,
                self.std_m,
                self.var_m,
                x_start = 0,      y_start = 0,
                x_end   = HEIGHT, y_end   = WIDTH,
                PRE=PRE, TOL=TOL)



# path of directory containing images
DIR = "./image/20210211/rawData/matlab/mask2_tap1/"
saveLoc = "./image/20210211/processed/mask2_tap1/condensed/"

DIR = "./image/20210215/rawData/matlab/mask4_rep02_tap1/"
saveLoc = "./image/20210215/processed/mask4_rep02_tap1/condensed/"

DIR     = "./image/20210516_2000/rawData/matlab/mask4_rep32_tap1/"
saveLoc = "./image/20210516_2000/processed/mask4_rep32_tap1/condensed/"

# List of filenames in sorted order, smallest to largest exposure time
fnames = glob.glob(DIR + '/*.mat')
fnames.sort()
filenames = [f.split('/')[-1].replace('.mat', '') for f in fnames]


# The convention I had with Rahul was that there is a 1:1 mapping 
# between exposure time and filename
exposures = np.array([float(f)/1e6 for f in filenames])
exposures = np.array([float(f)*4/1e6 for f in filenames])


# The dimesions of the input data were previously determined to be 320 x 648
WIDTH   = 648
HEIGHT  = 320

# Region of interest: whole region
X = 320
Y = 648


useOldData = input("Do you want to use existing data y/n:")
if(useOldData=='y' or useOldData=='Y'):
  exposures   = np.load(saveLoc+"exposures.npy")
  avg_m       = np.load(saveLoc+"avg_m.npy")
  std_m       = np.load(saveLoc+"std_m.npy")
  var_m       = np.load(saveLoc+"var_m.npy")

  gain_dn_m   = np.load(saveLoc+"gain_dn_m.npy")  
  black_pt_m  = np.load(saveLoc+"black_pt_m.npy") 
  sat_time_m  = np.load(saveLoc+"sat_time_m.npy") 
  fwc_m       = np.load(saveLoc+"fwc_m.npy")      
  tol1_m      = np.load(saveLoc+"tol1_m.npy")     
  tol2_m      = np.load(saveLoc+"tol2_m.npy")     
  gain_conv_m = np.load(saveLoc+"gain_conv_m.npy")
  var_ns_m    = np.load(saveLoc+"var_ns_m.npy")   
  snr_m       = np.load(saveLoc+"snr_m.npy")      

elif(useOldData=='n' or useOldData=='N'):
  np.save(saveLoc+"exposures.npy",exposures)

  avg_m, std_m, var_m = per_pixel_stats(DIR, filenames, HEIGHT, WIDTH)

  np.save(saveLoc+"avg_m.npy",avg_m)
  np.save(saveLoc+"std_m.npy",std_m)
  np.save(saveLoc+"var_m.npy",var_m)

  gain_dn_m, black_pt_m, sat_time_m, fwc_m, tol1_m, tol2_m, gain_conv_m, var_ns_m, snr_m = apply_model(
      exposures, 
      avg_m, 
      std_m, 
      var_m,
      HEIGHT, 
      WIDTH,
      x_end=X, 
      y_end=Y
    )



  np.save(saveLoc+"gain_dn_m.npy",gain_dn_m)
  np.save(saveLoc+"black_pt_m.npy",black_pt_m)
  np.save(saveLoc+"sat_time_m.npy",sat_time_m)
  np.save(saveLoc+"fwc_m.npy",fwc_m)
  np.save(saveLoc+"tol1_m.npy",tol1_m)
  np.save(saveLoc+"tol2_m.npy",tol2_m)
  np.save(saveLoc+"gain_conv_m.npy",gain_conv_m)
  np.save(saveLoc+"var_ns_m.npy",var_ns_m)
  np.save(saveLoc+"snr_m.npy",snr_m)
else:
  print("\nNo data detected. Errors ahead")


# consolidate data
avg_m, std_m, var_m = per_pixel_stats(DIR, filenames, HEIGHT, WIDTH)
shape = avg_m.shape

# t6 camera model
t6 = cameraModel(shape,exposures,avg_m,std_m,var_m)

# Choose coordinates of a random pixel
x = random.randint(0,219)
y = (random.randint(0,319)//2)*2
print("Pixel chosen:", x,y)

pixels = ((100,100),(x,y))

gain_dn_m, black_pt_m, sat_time_m, fwc_m, tol1_m, tol2_m, gain_conv_m, var_ns_m, snr_m = t6.apply_model_per_pixel(
  pixels
)



SAT = sat_time_m[x,y]
print("SAT:{:f}".format(SAT))




fig = plt.figure(figsize=(12, 4))
plt.plot(
    exposures[:SAT]*1000, 
    t6.systemModel(exposures[:SAT], gain_dn_m[x,y], black_pt_m[x,y], SAT, fwc_m[x,y], tol1_m[x,y], tol2_m[x,y]),
    linestyle="-", 
    label=r"Fit: y = {0:.2f}t+{1:.2f}".format(gain_dn_m[x,y], black_pt_m[x,y]), 
    color='orange'
  )
plt.scatter(exposures*1000, avg_m[:,x,y], label="sensor | gain=1x", s=12)
plt.xlabel("Exposure [ms]")
plt.ylabel("Output [DN]")
plt.title("Left Tap System Response [DN]")
plt.legend()
plt.grid()





fig, ax1 = plt.subplots(figsize=(10, 4))

color = 'tab:blue'
ax1.set_xlabel("Exposure [ms]")
ax1.set_ylabel("Tap1 Response [DN]", color=color)
ax1.scatter(exposures*1000, avg_m[:,x,y], color=color, s=16, alpha=0.9, label='tap 1 -- response')
ax1.plot(
    exposures[:SAT]*1000, 
    t6.systemModel(exposures[:SAT], gain_dn_m[x,y], black_pt_m[x,y], SAT, fwc_m[x,y], tol1_m[x,y], tol2_m[x,y]),
    linestyle="-", 
    label=r"Fit: y = -{0:.0f}t+{1:.0f}".format(gain_dn_m[x,y], black_pt_m[x,y]+tol1_m[x,y]), 
    color='tab:orange',
    alpha=1,
    linewidth=1.5
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
ax2.scatter(exposures*1000, avg_m[:,x,y+324], color=color, s=16, alpha=0.5, label='tap 2 -- leakage')

ax2.legend(loc=7)

plt.title("Tap1 ON | Tap2 OFF: pixel (%d, %d)" % (x,y))
fig.tight_layout()  # otherwise the right y-label is slightly clipped



fig, ax1 = plt.subplots(figsize=(10, 4))
plt.scatter(exposures[:32]*1000, avg_m[:32,x,y], color='tab:blue', s=16, alpha=0.9, label='tap 1 -- response')
plt.scatter(exposures[:32]*1000, avg_m[:32,x,y+324], color='tab:purple', s=16, alpha=0.8, label='tap 2 -- leakage')
plt.xlabel("Exposure [ms]")
plt.ylabel("Tap Response [DN]")
plt.grid()
plt.legend()
plt.title("Tap1 ON | Tap2 OFF: pixel (%d, %d)" % (x,y))





# System Response -- Number of electrons
# The data points are the squares of the SNR calculated.

fig = plt.figure(figsize=(10, 4))
plt.plot(avg_m[:SAT,x,y], -gain_conv_m[x,y]*avg_m[:SAT,x,y]+var_ns_m[x,y], linestyle="-", label=r"Fit: y = -{0:.2f}t+{1:.2f}".format(gain_conv_m[x,y],var_ns_m[x,y]), color='orange')
plt.scatter(avg_m[:,x,y], var_m[:,x,y], label="sensor", s=12)
plt.xlabel("Average DN")
plt.ylabel("Variance [DN]^2")
plt.title("Tap1 ON | Tap2 OFF: pixel (%d, %d)" % (x,y))
plt.legend()
plt.grid()


gain = 1/gain_conv_m[x,y] # number of e- / DN
np.sqrt(var_ns_m[x,y]) # read noise


plt.show()
