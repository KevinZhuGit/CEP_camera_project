import matplotlib.pyplot as plt
import numpy as np
import os

folder = '../../image/20210903_contrast_right_t6Exp000265Mask004'
# folder = '../../image/20210903_contrast_left_t6Exp000265Mask004'

raw_file 	= 'raw_r{:02d}_m{:02d}_{:04d}.npy'
black_file 	= 'black_r{:02d}_m{:02d}.npy'
k = 3 	#file to plot
mask_num = 4
rep_num = 1

for rep_num in range(1,11):
	for k in range(4):
		raw 	= np.load(os.path.join(folder,raw_file.format(rep_num,mask_num,k)))
		black 	= np.load(os.path.join(folder,black_file.format(rep_num,mask_num)))

		img = black-raw
		img[img<0] = 0
		t1 = img[:,:320]
		t2 = img[:,324:324+320]

		num = t1-t2
		den = t1+t2
		valid = (den!=0)

		contrast = num/den
		print("rep: {:02d} index: {:02d}  Mean: {:05.3f} invalid: {:06f}".format(rep_num,k,np.mean(contrast[valid]),320*320-contrast[valid].size))

plt.ion()

fig, ax = plt.subplots(figsize=(8,8),ncols=1);#ax1 = ax.twinx();;ax1.grid()
ax.grid()

# plt.imshow(contrast,cmap='plasma',vmax=1,vmin=-1)
# plt.colorbar()

histOP = ax.hist(contrast[valid].flatten(), bins=51,alpha=0.5, density=False, facecolor='red')

num = num[valid]
den = den[valid]


N_points = 100000
n_bins = 20

# Generate a normal distribution, center at x=0 and y=5
x = np.random.randn(N_points)
y = .4 * x + np.random.randn(100000) + 5

fig, axs = plt.subplots(1, 2, sharey=True, tight_layout=True)

# We can set the number of bins with the `bins` kwarg
axs[0].hist(x, bins=n_bins)
axs[1].hist(y, bins=n_bins)
