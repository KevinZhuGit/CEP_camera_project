from mainWindow import mainWindow
import matplotlib.pyplot as plt

class charMe(mainWindow):
	def __init__(self,title):
		super(charMe,self).__init__(title)


if __name__ == '__main__':
	gui = charMe("T6")
	gui.readData('../python/image/20210211/processed/mask2_tap1/condensed/')
	# gui.readData('../python/image/20210215/processed/mask4_rep10_tap1/condensed/')
	# gui.readData('../python/image/20210215/processed/mask4_rep02_tap1/condensed/')
	# gui.readData('../python/image/20210215/processed/mask4_rep01_tap1/condensed/')
	gui.exposureUpdate(0)
	gui.showWindow()
	plt.close('all')