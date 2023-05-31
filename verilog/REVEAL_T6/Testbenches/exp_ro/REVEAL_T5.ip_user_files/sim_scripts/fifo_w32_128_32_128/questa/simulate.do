onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib fifo_w32_128_32_128_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_w32_128_32_128.udo}

run -all

quit -force
