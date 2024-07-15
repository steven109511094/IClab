from CNN import CNN
from CNN_pattern_gen import CNN_pattern_gen
import random

def main():
  random.seed(1234)
  PAT_NUM = 10000
  PAT_GEN = False
  DEBUG   = True
  PAT_TO_DEBUG = 1234

  in_file_dir = './lab4/Verilog/input.txt'
  out_file_dir = './lab4/Verilog/output.txt'
  debug_log_dir = './lab4/Algorithm/debug.log'

  if PAT_GEN == True:
    CNN_pattern_gen(PAT_NUM, in_file_dir)

  CNN(PAT_NUM=PAT_TO_DEBUG,
      DEBUG=DEBUG,
      in_file_dir=in_file_dir,
      out_file_dir=out_file_dir,
      debug_log_dir=debug_log_dir)

  print("Done!")
  return

if __name__ == "__main__":
    main()