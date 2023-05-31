# Short bitfile Description from current branch
## Convention
`Reveal_Top_<camera_name>_<branch_name>_<version>.bit`

## Branch
 Characterization

## Description
| bitfile        | Branch      |Description  |
| :------------- |:----------  |:----------  |
| 11.1 | 
| 11.2 | |CLKMi 4x slower
| 11.3 | |CLKMi 14MHz
| 11.4 | |CLKMi 14MHz and mask applied from 320to0
| 12   | |CLKMi 14MHz Hardcoded readout value
| 13   | |CLKMi 50 MHz, with new block for multiple triggers copied from t4_a75
| 13.2 | |CLKMi 25 MHz, same as before
| 13.2.2| | same as before, but tx_clk_out is ignored and tx_clk used in verilog instead
| 13.3 | |CLKMi 25 MHz, Exposure module changed to be exactly like T4
| 13.4 | |Same as 13.3 but Select[5] can be configured to read reset frame every alternate time
| 14   | |taken from 13.4 with CAM_TG must be triggered
| 14.1 | |taken from 13.3 + CLKMi 50MHz with CAM_TG must be triggered
| 14.2 | |CLKMi 200 MHz, exposure module changed back to t6
| 14.3 | |CLKMi 100 MHz, exposure module changed back to t6
| 15   | Characterization| Replaced the projector trigger with contrast LED
| 15.1 | Characterization| 15 + CLKMi=200MHz
| 16   | Characterization| 15 + CLKMi=100MHz. New variable called `NumExp` allows to do multiple exposures with single readout
| 01   | t7_based_on_t6 | from characterization T6
| 01.02| t7_based_on_t6 | added bora's readout module
| 01.03| t7_based_on_t6 | replaced the readout module to match new timing diagram
| 01.04| t7_based_on_t6 | added image sensor SPI. Was able to see test output pattern from serializer
| 01.05| t7_based_on_t6 | Reduce TX_CLK to 25 MHz. Removed T4 Readout completely. Could see VREF dependent readout
| 01.06| t7_based_on_t6 | Removing unnecessary stuff from varvalueselector.
| 01.07| t7_based_on_t6 | Added the row_decoder controller
| 02.01| t7_based_on_t6 | constraint file based on adapter board
| 02.02| t7_based_on_t6 | 
| 02.03| t7_based_on_t6 | 02.01 with programmable mask size.
| 02.07| t7_based_on_t6 | shows uniform output with constant reference voltage
| 02.08| t7_based_on_t6 | fixed some of the signals
| 02.09| t7_based_on_t6 | digout_test is connected. MSTREAM is connected to constant value
| 03.01| t7_based_on_t6 | programmable IMG_SIZE
| 03.02| t7_based_on_t6 | lowered the img_start_address in ddr controller
| 03.03| t7_based_on_t6 | programmable IMG_SIZE but reading only 12 channels
| 03.04| t7_based_on_t6 | data is latched on DCLK
| 03.05| t7_based_on_t6 | data is latched back to TX_CLK. Fixed PIXRES, programmable PIXLEFT/RIGHTBUCK_SEL
| 03.06| t7_based_on_t6 | PIXVTG_GLOB can be controlled to verify the pixel array
| 03.07| t7_based_on_t6 | All the masking signals are constant except clk and des2nd
| 03.08| t7_based_on_t6 | 03.07 + CLKM=25MHz
| 03.09| t7_based_on_t6 | 03.06 + constraint file fixed to address switched DEC_EN DEC_SEL
| 03.10| t7_based_on_t6 | t6 size mask upload works
| 03.11| t7_based_on_t6 | t6 size mask upload but across all 20 channels
| 03.12| t7_based_on_t6 | 3.10 + 17 channel readout
| 03.13| t7_based_on_t6 | fixed the adc parser
| 04.01| t7_based_on_t6 | new exposure module to code the whole sensor
| 04.02| t7_based_on_t6 | modified ddr_ctl to include states for storing subframe readout
| 05.01| t7_based_on_t6 | implemented readout full
| 05.03| t7_based_on_t6 | implemented readout full + ddr_ctl can now store and stop when enough subframe readout is done
| 05.04| t7_based_on_t6 | regenerated bitfile with timing optimizations directive
| 05.05| t7_based_on_t6 | waits to read the subframe image before starting next exposure
| 05.06| t7_based_on_t6 | with LDO
| 06.01| t7_based_on_t6 | merged readout
| 06.01.02| t7_based_on_t6 | flow time optimized directive (takes same time as default)
| 06.02| t7_based_on_t6 | added row_map table for adc2
| 06.03| t7_based_on_t6 | fixed some decoder issue
| 06.04| t7_based_on_t6 | added trigger to double check the sub_img_cnt
| 06.05| t7_based_on_t6 | fixed the rowmap memory timing 
| 06.06| t7_based_on_t6 | adc2 can start after some delay. MASKE_EN connected to Select
| 06.07| t7_based_on_t6 | control cotrast LED
