import os
import numpy as np
import time

depth = 512

prefix = """
;Created by src/verilog/REVEAL_T6/scripts/create_row_map_coe.py
;Created on {time}
;-RaulGool
;width = 9
;depth = {depth}
;radix = 10
memory_initialization_radix = 10;
memory_initialization_vector = 
""".format(time=time.ctime(),depth=depth)


row_map = []
memory = prefix
for i in range(depth):
	# new_row = int(i//2*4+i%2)
	new_row = i
	row_map.append(new_row)
	if(i%8==0):
		memory = memory+'\n'
	memory = memory + '{: 5d}'.format(new_row%512) + ' '

memory = memory + ';\n'

suffix = """
;good luck
"""
memory = memory + suffix
print(memory)