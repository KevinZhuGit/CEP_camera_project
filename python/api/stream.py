from threading import Thread
import queue
from t6 import T6
import time
import numpy as np
import logging

logging.basicConfig(format='%(levelname)-6s[%(filename)s:%(lineno)d] %(message)s'
                    ,level=logging.DEBUG)

class CamVideoStream(object):

    frame_all = np.zeros([320,2*108*3], dtype=np.uint32)

    def __init__(self, camera, bitfile,reConfFPGA=True):
        assert camera == 't2' or camera == 't3' or camera == 't4' or camera == 't6',\
            "Unknown Camera. 't2'/'t3'/'t4'/'t6'"
        if camera == 't2':
            from t2 import T2
            self.stream = T2(bitfile)
        elif camera == 't3':
            from t3 import T3
            self.stream = T3(bitfile)
        elif camera == 't4':
            from t4 import T4
            self.stream = T4(bitfile,reConfFPGA=reConfFPGA)
        elif camera == 't6':
            from t6 import T6
            self.stream = T6(bitfile,reConfFPGA=reConfFPGA)
        #self.frame = self.stream.im,read()
        self.q = queue.Queue(maxsize=10)
        self.stopped = False

    def start(self):
        self.stream.readout_reset()

#    def update(self):

    def read(self):
        return self.stream.arrange(self.stream.imread())

    def read_raw(self):
        #print("time: {}".format(time.time()))
        #return self.stream.arrange(self.stream.imread2())
        return self.stream.arrange_raw(self.stream.imread())
        # return self.stream.imread_arrange()

    def stop(self):
        self.stopped = True

