from pynq import Overlay
overlay = Overlay('/home/xilinx/pynq/tensorcore.bit')

######################################################################################################

overlay.is_loaded()
help(overlay)

######################################################################################################

tensor_stat = overlay.tensorcore_0
help(tensor_stat)

######################################################################################################

# Configure Register (Address 0x00) Format
#  ______________________________________________________________________________________________
# | 31 -- 28 | 27 -- 26 | 25 --     | 24  -- 21     |20 -- 17 | 16   |  15 --12  | 11 -- 1   | 0 |
# | Feat Sel, X-4b,Y-2b | Bias/Zero | Psum Index-4b |Out Shift| Relu | Ouput Sel*| Wgt Sel** | NA|
#  ----------------------------------------------------------------------------------------------
# for version 0.1, Ouput Sel should set as same as Psum Index
# for version 0.1, Weight Sel only use two bit and 4 index are utilized
# for version 0.1, Feat Sel X should be <12

tensor_stat.write(0x00,0b0000_00_0_0001_0000_0_0001_00000000000_1)

######################################################################################################

# Write the Feature map, a 6 row 12 column table with each element of 8 bit
# Address Space Mapping Format (a 32-bit word includes 4 elements)
# ____________________________________________________
#        | Col 1,2,3,4 | Col 5,6,7,8 | Col 9,10,11,12 |
# Row 0  |     0x04    |     0x08    |       0x0c     | 
# Row 1  |     0x10    |     0x14    |       0x18     |
# Row 2  |     0x1c    |     0x20    |       0x24     |
# Row 3  |     0x28    |     0x2c    |       0x30     |
# Row 4  |     0x34    |     0x38    |       0x3c     |
# Row 5  |     0x40    |     0x44    |       0x48     |
# ----------------------------------------------------

# Write in the feature, I put the value same as the (x-y) coordinate, MSB=Row, LSB=Column
tensor_stat.write(0x04,0x04030201)
tensor_stat.write(0x08,0x08070605)
tensor_stat.write(0x0c,0x0c0b0a09)
tensor_stat.write(0x10,0x14131211)
tensor_stat.write(0x14,0x18171615)
tensor_stat.write(0x18,0x1c1b1a19)
tensor_stat.write(0x1c,0x24232221)
tensor_stat.write(0x20,0x28272625)
tensor_stat.write(0x24,0x2c2b2a29)
tensor_stat.write(0x28,0x34333231)
tensor_stat.write(0x2c,0x38373635)
tensor_stat.write(0x30,0x3c3b3a39)
tensor_stat.write(0x34,0x44434241)
tensor_stat.write(0x38,0x48474645)
tensor_stat.write(0x3c,0x4c4b4a49)
tensor_stat.write(0x40,0x54535251)
tensor_stat.write(0x44,0x58575655)
tensor_stat.write(0x48,0x5c5b5a59)

######################################################################################################

# Write the Weight Memory
# each weight kernal window is set to 3x3 with each element of 7bit, map in two 32b word
# The total memeory size is 2x4x8 (each kernel x memory depth x slice number)
# in the future version, memory will be changed as DMA
# The weight memory address begins from 0x100, Here is a mapping rule between Wgt_sel cfg and real weight output
#
#  Wgt Sel| Slice 1 | Slice 2 | Slice 3 | Slice 4 | Slice 5 | Slice 6 | Slice 7 | Slice 8 |
#  -------| ------- | ------- | ------- | ------- | ------- | ------- | ------- | ------- |
#   00    | 0x104/0 | 0x124/0 | 0x144/0 | 0x164/0 | 0x184/0 | 0x1a4/0 | 0x1c4/0 | 0x1e4/0 |
#   01    | 0x10c/8 | 0x12c/8 | 0x14c/8 | 0x16c/8 | 0x18c/8 | 0x1ac/8 | 0x1cc/8 | 0x1ec/8 |
#   10    | 0x114/0 | 0x134/0 | 0x154/0 | 0x174/0 | 0x194/0 | 0x1b4/0 | 0x1d4/0 | 0x1f4/0 |
#   11    | 0x11c/8 | 0x13c/8 | 0x15c/8 | 0x17c/8 | 0x19c/8 | 0x1bc/8 | 0x1dc/8 | 0x1fc/8 |
# ----------------------------------------------------------------------------------------

# Write in the weight, for easy debug, I put one element in the each 3x3 kernel as 1
# Write for Wgt_Sel=00

tensor_stat.write(0x104,0b0_0000000_0000000_0000000_0000000_000)
tensor_stat.write(0x100,    0b0000_0000000_0000000_0000000_0000001)
tensor_stat.write(0x124,0b0_0000000_0000000_0000000_0000000_000)
tensor_stat.write(0x120,    0b0000_0000000_0000000_0000001_0000000)
tensor_stat.write(0x144,0b0_0000000_0000000_0000000_0000000_000)
tensor_stat.write(0x140,    0b0000_0000000_0000001_0000000_0000000)
tensor_stat.write(0x164,0b0_0000000_0000000_0000000_0000000_000)
tensor_stat.write(0x160,    0b0000_0000001_0000000_0000000_0000000)
tensor_stat.write(0x184,0b0_0000000_0000000_0000000_0000000_000)
tensor_stat.write(0x180,    0b0001_0000000_0000000_0000000_0000000)
tensor_stat.write(0x1a4,0b0_0000000_0000000_0000000_0000001_000)
tensor_stat.write(0x1a0,    0b0000_0000000_0000000_0000000_0000000)
tensor_stat.write(0x1c4,0b0_0000000_0000000_0000001_0000000_000)
tensor_stat.write(0x1c0,    0b0000_0000000_0000000_0000000_0000000)
tensor_stat.write(0x1e4,0b0_0000000_0000001_0000000_0000000_000)
tensor_stat.write(0x1e0,    0b0000_0000000_0000000_0000000_0000000)

# The rest weight is not written here

# Write the bais Memory (first of all set to zero)

tensor_stat.write(0x60, 0)
tensor_stat.write(0x64, 0)

# Readout the Tensor Compuation Result
psum0 = tensor_stat.read(0x80)
psum1 = tensor_stat.read(0x84)
print("The tensor results are",hex(psum1),hex(psum0)) 

######################################################################################################

# How to accumulate ?

# MOV the caculation result to the bias reg
tensor_stat.write(0x60, psum0)
tensor_stat.write(0x64, psum1)

# Reset the Configuration and turn on the bias accumulation
tensor_stat.write(0x00,0b0001_00_1_0001_0000_0_0001_00000000000_1)

# Readout the Tensor Compuation Result Again
psum0 = tensor_stat.read(0x80)
psum1 = tensor_stat.read(0x84)
print("The tensor results are",hex(psum1),hex(psum0)) 

######################################################################################################

# Readout the Debug bus
db0 = tensor_stat.read(0x88)
db1 = tensor_stat.read(0x8c)
db2 = tensor_stat.read(0x90)
db3 = tensor_stat.read(0x94)
print("Debug Bus are",hex(db0),hex(db1),hex(db2),hex(db3))

######################################################################################################



