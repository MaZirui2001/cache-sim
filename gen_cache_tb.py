import sys
from random import randint
import os
if not os.path.exists('./build'):
    os.makedirs('./build')

# read testbench template
verilog_head = ''
verilog_tail = ''
with open('./template/template_tb.sv', 'r') as f:
    verilog_head, verilog_tail = f.read().split('/* SPLIT */')
# 创建build文件夹

len = len(sys.argv)
if len != 3: 
    print('    Usage:\n        python gen_cache_tb.py [TOTAL_WORD_NUM][TOTAL_TEST_NUM]')
    print('    Example:\n        python generate_cache_tb.py 4096 8192')
else:
    # given main memory size
    try:
        TOTAL_WORD_NUM = int( sys.argv[1] )
    except:
        print('    *** Error: parameter must be integer, not %s' % (sys.argv[3], ) )
        sys.exit(-1)
    
    # given total test number
    try:
        TOTAL_TEST_NUM = int( sys.argv[2] )
    except:
        print('    *** Error: parameter must be integer, not %s' % (sys.argv[3], ) )
        sys.exit(-1)
    
    verilog = verilog_head % (TOTAL_WORD_NUM, TOTAL_TEST_NUM, )

    SPLIT_BOUND = TOTAL_WORD_NUM // 2

    # generate i_addr_rom and d_addr_rom
    i_addr_rom = [(randint(0, SPLIT_BOUND//4-1)) << 2 for i in range(TOTAL_TEST_NUM)]
    d_addr_rom = [(randint(SPLIT_BOUND//4, TOTAL_WORD_NUM//4-1)) << 2 for i in range(TOTAL_TEST_NUM)]
    wdata_rom  = [randint(0, 2**32-1) for i in range(TOTAL_TEST_NUM)]
    wvalid_rom = [(randint(1, 2) << 3) | (randint(0, 1) << 2) | (randint(0, 2))  for i in range(TOTAL_TEST_NUM)]
    
    for i in range(TOTAL_TEST_NUM):
        verilog += "    i_addr_rom[%5d] = 'h%08x; \t" % (i, i_addr_rom[i])
        verilog += "    d_addr_rom[%5d] = 'h%08x; \t" % (i, d_addr_rom[i])
        verilog += "    wdata_rom[%5d] = 'h%08x; \t" % (i, wdata_rom[i])
        verilog += "    mem_type_rom[%5d] = 'h%02x; \n" % (i, wvalid_rom[i])
    verilog += verilog_tail
    # make coe file
    coe = 'memory_initialization_radix=16;\nmemory_initialization_vector=\n'
    for i in range(65536):
        coe += '%08x\n' % (i,)
    with open('./build/memory.coe', 'w') as f:
        f.write(coe)
    with open('./build/cache_tb.sv', 'w') as f:
        f.write(verilog)
    
    # print(verilog)