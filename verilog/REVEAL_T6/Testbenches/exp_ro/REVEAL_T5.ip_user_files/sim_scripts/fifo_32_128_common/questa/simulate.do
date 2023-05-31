onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib fifo_32_128_common_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_32_128_common.udo}

run -all

quit -force
