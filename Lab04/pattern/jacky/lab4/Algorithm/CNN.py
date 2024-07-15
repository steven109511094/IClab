from icecream import ic
import sys
from CNN_function import conv, fc, fp2hex, hex2fp
import numpy as np

def CNN(PAT_NUM,DEBUG,in_file_dir,out_file_dir,debug_log_dir):
  with open(in_file_dir, 'r') as file:
    file_in = file.readlines()

  NUM = int(file_in[0])

  # Store the original stdout
  original_stdout = sys.stdout
  # Redirect stdout and stderr to a file
  sys.stdout = open(debug_log_dir, 'w')
  sys.stderr = sys.stdout


  # print(f"Reading in {NUM} patterns\n")

  if(DEBUG == True):
    out_file_dir = './redirect.txt'

  with open(out_file_dir, 'w') as f:
      for i in range(NUM):
        opt    = int(file_in[1 + 8 * i + 0])
        img11  = np.array([hex2fp(val) for val in file_in[1 + 8 * i + 1].split()], dtype=np.float32)
        img12  = np.array([hex2fp(val) for val in file_in[1 + 8 * i + 2].split()], dtype=np.float32)
        img13  = np.array([hex2fp(val) for val in file_in[1 + 8 * i + 3].split()], dtype=np.float32)
        ker1   = np.array([hex2fp(val) for val in file_in[1 + 8 * i + 4].split()], dtype=np.float32)
        ker2   = np.array([hex2fp(val) for val in file_in[1 + 8 * i + 5].split()], dtype=np.float32)
        ker3   = np.array([hex2fp(val) for val in file_in[1 + 8 * i + 6].split()], dtype=np.float32)
        weight = np.array([hex2fp(val) for val in file_in[1 + 8 * i + 7].split()], dtype=np.float32)

        # OPT
        # 0   ReLU        zero
        # 1   tanh        zero
        # 2   sigmoid    replication
        # 3   softplut   replication

        hex2_fp_numpy = np.vectorize(fp2hex)

        conv11,pad11 = conv(opt//2, img11, ker1)
        conv12,pad12 = conv(opt//2, img12, ker2)
        conv13,pad13 = conv(opt//2, img13, ker3)

        fmap1 = conv11 + conv12 + conv13
        pool1 = np.array(
                [max(fmap1[0],  fmap1[1],  fmap1[4],  fmap1[5] ),
                 max(fmap1[2],  fmap1[3],  fmap1[6],  fmap1[7] ),
                 max(fmap1[8],  fmap1[9],  fmap1[12], fmap1[13]),
                 max(fmap1[10], fmap1[11], fmap1[14], fmap1[15])], dtype=np.float32)

        # There is a unknown bug when doing matmul using numpy
        fc1 = fc(pool1, weight)

        norm1 = (fc1 - min(fc1))/(max(fc1) - min(fc1))


        if opt == 0: # RelU
          vect1 = np.maximum(norm1, 0)
        elif opt == 1: # tanh
          vect1 = (np.exp(norm1) - np.exp(-norm1)) / (np.exp(norm1) + np.exp(-norm1))
        elif opt == 2: # sigmoid
          vect1 = 1 / (1 + np.exp(-norm1))
        elif opt == 3: # softPlus
          vect1 = np.log(1 + np.exp(norm1))

        # ic(DEBUG)

        if DEBUG == False:
          for e in vect1:
            tmph = fp2hex(e)
            f.write(f"{tmph} ")

          # f.write(f"//{vect1[0][0]:.4f} {vect1[1][0]:.4f} {vect1[2][0]:.4f} {vect1[3][0]:.4f}")
          f.write(f"\n")

        elif i == PAT_NUM and DEBUG == True:
          print(f"PATTERN NUM: {PAT_NUM}")
          print("=================================INPUT================================")
          ic(opt)
          ic(img11)
          ic(img12)
          ic(img13)
          ic(ker1)
          ic(ker2)
          ic(ker3)
          ic(weight)
          # their hex representation
          ic(hex2_fp_numpy(img11))
          ic(hex2_fp_numpy(img12))
          ic(hex2_fp_numpy(img13))
          ic(hex2_fp_numpy(ker1))
          ic(hex2_fp_numpy(ker2))
          ic(hex2_fp_numpy(ker3))
          ic(hex2_fp_numpy(weight))

          print("=================================Intermediate Values================================")
          ic(pad11,pad12,pad13)
          ic(conv11, conv12, conv13)

          # Perform hex2fp function on all the element in conv11
          conv11_h = np.vectorize(fp2hex)(conv11)
          conv12_h = np.vectorize(fp2hex)(conv12)
          conv13_h = np.vectorize(fp2hex)(conv13)
          ic(conv11_h, conv12_h, conv13_h)

          ic(fmap1)
          fmap1_h = np.vectorize(fp2hex)(fmap1)
          ic(fmap1_h)

          ic(pool1)
          pool1_h = np.vectorize(fp2hex)(pool1)
          ic(pool1_h)

          ic(fc1)
          fc1_h = np.vectorize(fp2hex)(fc1)
          ic(fc1_h)

          ic(norm1)
          norm1_h = np.vectorize(fp2hex)(norm1)
          ic(norm1_h)

          print("=================================Output================================")
          ic(vect1)
          vect1_h = np.vectorize(fp2hex)(vect1)
          ic(vect1_h)

          break

  # Reset stdout back to its original value
  sys.stdout = original_stdout

  f.close()