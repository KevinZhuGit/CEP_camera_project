import logging
import ok
import numpy as np

#logging.basicConfig(format='%(levelname)-6s[%(filename)s:%(lineno)d] %(message)s'
#                    ,level=logging.DEBUG)

class api(object):

    error_msg = {  0 : "Success!",
                  -1 : "Non-descript failure",
                  -2 : "Timeout",
                  -3 : "DoneNotHigh",
                  -4 : "TransferError",
                  -5 : "CommunicationError",
                  -6 : "InvalidBitStream",
                  -7 : "FileError",
                  -8 : "DeviceNotOpen",
                  -9 : "InvalidEndpoint",
                  -10: "InvalidBlockSize",
                  -11: "I2CRestrictedAddress",
                  -12: "I2CBitError",
                  -13: "I2CNack",
                  -14: "I2CUnknownStatus",
                  -15: "UnsupportedFeature",
                  -16: "FIFOUnderflow",
                  -17: "FIFOOverflow",
                  -18: "DataAlignmentError",
                  -19: "InvalidResetProfile",
                  -20: "InvalidParameter",
                 }


    def __init__(self,bitfile,reConfFPGA=True):

        #Following code is compatible with FPoIP. Remember to setup correct okFP_REALM system variable on the client side
        self.devices = ok.FrontPanelDevices()

        # self.dev = ok.okCFrontPanel()

        # for i in range(self.dev.GetDeviceCount()):

        #     logging.info('Device[{0}] Model: {1}'.format(i, self.dev.GetDeviceListModel(i)))
        #     logging.info('Device[{0}] Serial: {1}'.format(i, self.dev.GetDeviceListSerial(i)))

        # self.dev.OpenBySerial("")
        self.dev = self.devices.Open()


        if(reConfFPGA):
          error = self.dev.ConfigureFPGA(bitfile)
          assert error == 0, self.error_msg.get(error)
          logging.info("Configure: "+self.error_msg.get(error))
        else:
          logging.info("Did not configure FPGA.")  


        error = self.dev.IsFrontPanelEnabled()
        assert error == True, "FrontPanel host interface not detected."
        logging.info("FrontPanel host interface enabled.")

    def istriggered(self, addr, value):
        self.dev.UpdateTriggerOuts()
        return self.dev.IsTriggered(addr, value)

    def trigger_in(self, addr, value):
        error = self.dev.ActivateTriggerIn(addr, value)
        assert error == 0, self.error_msg[error]

    def wire_in(self, addr, value):
        error = self.dev.SetWireInValue(addr, value);
        assert error >= 0, self.error_msg.get(error)
        error = self.dev.UpdateWireIns();
        assert error >= 0, self.error_msg.get(error)
        logging.debug("Addr.0x{:02X} wire input {}".format(addr, value))

    def wire_out(self, addr):
        error = self.dev.UpdateWireOuts()
        assert error >= 0, self.error_msg.get(error)
        value = self.dev.GetWireOutValue(addr)
        logging.debug("Addr.0x{:02X} wire output {}".format(addr, value))
        return value

    def write(self, addr, container):
        error = self.dev.WriteToPipeIn(addr, container)
        assert error >= 0, self.error_msg.get(error)
        logging.debug("PipeIn from Addr.0x{:02X}".format(addr))
        return error

    def read(self, addr, container):
        error = self.dev.ReadFromPipeOut(addr, container)
        assert error >= 0, self.error_msg.get(error)
        logging.debug("PipeOut from Addr.0x{:02X}".format(addr))
        return error

    def block_write(self, addr, block_size, container):
        error = self.dev.WriteToBlockPipeIn(addr, block_size, container)
        assert error >= 0, self.error_msg.get(error)
        logging.debug("BlockPipeIn from Addr.0x{:02X}".format(addr))
        return error

    def block_read(self, addr, block_size, container):
        error = self.dev.ReadFromBlockPipeOut(addr, block_size, container)
        assert error >= 0, self.error_msg.get(error)
        logging.debug("BlockPipeOut from Addr.0x{:02X}".format(addr))
        return error


