import struct
import numpy as np
from icecream import ic

def fp2hex(float_number):
    hex_value = struct.unpack('<I', struct.pack('<f', float_number))[0]
    return format(hex_value, 'x')

def hex2fp(hex_value):
  fp_value = struct.unpack('<f',struct.pack('<I',int(hex_value,16)))[0]
  return fp_value

def fc(pool, weight):
  pool = pool.reshape((2,2))
  weight = weight.reshape((2,2))
  fc_result = np.zeros((4,1), dtype='float32')

  for i in range(2):
      for j in range(2):
          partial_mult = np.float32(0) #TODO
          for k in range(2):
              partial_mult += pool[i,k] * weight[k,j]
          fc_result[i*2+j] = partial_mult

  fc_result.reshape((4,))
  return fc_result

def conv(opt_0, img, ker):
  pad = np.random.rand(6, 6).astype(np.float32)
  if(opt_0 == 1): # Replication padding
    pad[0][0] = img[0]
    pad[0][1] = img[0]
    pad[0][2] = img[1]
    pad[0][3] = img[2]
    pad[0][4] = img[3]
    pad[0][5] = img[3]

    pad[1][0] = img[0]
    pad[1][1] = img[0]
    pad[1][2] = img[1]
    pad[1][3] = img[2]
    pad[1][4] = img[3]
    pad[1][5] = img[3]

    pad[2][0] = img[4]
    pad[2][1] = img[4]
    pad[2][2] = img[5]
    pad[2][3] = img[6]
    pad[2][4] = img[7]
    pad[2][5] = img[7]

    pad[3][0] = img[8]
    pad[3][1] = img[8]
    pad[3][2] = img[9]
    pad[3][3] = img[10]
    pad[3][4] = img[11]
    pad[3][5] = img[11]

    pad[4][0] = img[12]
    pad[4][1] = img[12]
    pad[4][2] = img[13]
    pad[4][3] = img[14]
    pad[4][4] = img[15]
    pad[4][5] = img[15]

    pad[5][0] = img[12]
    pad[5][1] = img[12]
    pad[5][2] = img[13]
    pad[5][3] = img[14]
    pad[5][4] = img[15]
    pad[5][5] = img[15]
  else: # zero
    pad[0][0] = 0
    pad[0][1] = 0
    pad[0][2] = 0
    pad[0][3] = 0
    pad[0][4] = 0
    pad[0][5] = 0

    pad[1][0] = 0
    pad[1][1] = img[0]
    pad[1][2] = img[1]
    pad[1][3] = img[2]
    pad[1][4] = img[3]
    pad[1][5] = 0

    pad[2][0] = 0
    pad[2][1] = img[4]
    pad[2][2] = img[5]
    pad[2][3] = img[6]
    pad[2][4] = img[7]
    pad[2][5] = 0

    pad[3][0] = 0
    pad[3][1] = img[8]
    pad[3][2] = img[9]
    pad[3][3] = img[10]
    pad[3][4] = img[11]
    pad[3][5] = 0

    pad[4][0] = 0
    pad[4][1] = img[12]
    pad[4][2] = img[13]
    pad[4][3] = img[14]
    pad[4][4] = img[15]
    pad[4][5] = 0

    pad[5][0] = 0
    pad[5][1] = 0
    pad[5][2] = 0
    pad[5][3] = 0
    pad[5][4] = 0
    pad[5][5] = 0

  # ic(pad)

  rslt = np.random.rand(16).astype(np.float32)
  for i in range(4):
    for j in range(4):
      tmp1 = ker[0] * pad[ i ][j] + ker[1] * pad[ i ][j+1] + ker[2] * pad[ i ][j+2]
      tmp2 = ker[3] * pad[i+1][j] + ker[4] * pad[i+1][j+1] + ker[5] * pad[i+1][j+2]
      tmp3 = ker[6] * pad[i+2][j] + ker[7] * pad[i+2][j+1] + ker[8] * pad[i+2][j+2]
      rslt[i * 4 + j] = tmp1 + tmp2 + tmp3

  return rslt,pad