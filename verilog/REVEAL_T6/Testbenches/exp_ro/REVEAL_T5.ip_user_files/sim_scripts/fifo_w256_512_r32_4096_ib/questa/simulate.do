onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib fifo_w256_512_r32_4096_ib_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_w256_512_r32_4096_ib.udo}

run -all

quit -force
