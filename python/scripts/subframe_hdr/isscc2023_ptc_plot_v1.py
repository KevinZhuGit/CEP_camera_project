import numpy as np
import matplotlib.pyplot as plt

img_mean_loc = '../../image/20220831_f1_68.4_0.8_3.7/all_mean.npz'
img_var_loc  = '../../image/20220831_f1_68.4_0.8_3.7/all_var.npz'
plot_label   = 'f1'

# img_mean_loc = '/media/raulgool/e490e3f5-ad5b-4634-982d-823a3aca123b/image/20220831_f4_17.1_0.8_3.7/all_mean.npz'
# img_var_loc  = '/media/raulgool/e490e3f5-ad5b-4634-982d-823a3aca123b/image/20220831_f4_17.1_0.8_3.7/all_var.npz'
# plot_label   = 'f4_mean'

# img_mean_loc = '../../image/20220831_f4_17.1_0.8_3.7/mean_reg_x2000_N_870_220831_235104.npz'
# img_var_loc  = '../../image/20220831_f4_17.1_0.8_3.7/variance_reg_x2000_N_870_220831_235104.npz'
# plot_label   = 'f4_regression'



img_mean_all_f	= np.load(img_mean_loc)
img_var_all_f 	= np.load(img_var_loc)



img_mean_all = img_mean_all_f['mean'].flatten()
img_var_all  =  img_var_all_f['var'].flatten()

order 		 = np.argsort(img_mean_all)
img_mean_all = img_mean_all[order]
img_var_all  = img_var_all[order]


x = img_mean_all.copy()
y = img_var_all.copy()


y_ = np.diff(y,prepend=y[0])
k  = y_<1e9/2**16
x1 = x[k]
y1 = y[k]


y_ = np.diff(y1,prepend=y[0])
k  = y_<0.1e9/2**16
x2 = x1[k]
y2 = y1[k]


y_ = np.diff(y2,prepend=y[0])
k  = y_<1e8/2**16
x3 = x2[k]
y3 = y2[k]





plt.figure(1)
# plt.clf()
plt.plot(x,y,label='0')
plt.plot(x1,y1,label='1')
plt.plot(x2,y2,label='2')
plt.plot(x3,y3,label='3')
plt.legend()
plt.show()

x = x3.copy()
y = y3.copy()
n = np.interp(np.logspace(-3,3,1000),x,np.arange(len(x))).astype(int)
snr = 20*np.log10(x/y**0.5)

nNew = []
for i in range(len(n)-1):
	l = n[i]
	r = n[i+1]
	if(l==r):
		continue
	else:
		k=np.argmin(y[l:r])
		# print(l,r,k)
	nNew.append(l+k)
	



fs_title = 18
fs_label = 14
fs_ticks = 12
fig = plt.figure(2,figsize=(8,8))
# plt.clf()
ax 	= fig.add_subplot(1,1,1)

# ax.semilogx(x[n],snr[n],'-',linewidth=2,label=plot_label)
ax.semilogx(x[nNew],snr[nNew],'-',linewidth=2,label=plot_label)
ax.grid()
ax.set_ylim(0,50)
ax.set_xlim(0.01,1000)
ax.set_title('PHOTON TRANSFER CURVE',fontsize=fs_title)
ax.set_xlabel('MEASURED FLUX (A.U.)',fontsize=fs_label)
ax.set_ylabel('SNR (dB)',fontsize=fs_label)
ax.tick_params(axis='both', which='major', labelsize=fs_ticks)
plt.show()