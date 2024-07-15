import random
from icecream import ic
from CNN_function import fp2hex, hex2fp

def CNN_pattern_gen(NUM,file_dir):
  img11 = []
  img12 = []
  img13 = []
  ker1 = []
  ker2 = []
  ker3 = []
  weight = []

  with open(file_dir, 'w') as f:
    f.write(f"{NUM}\n")
    for i in range(NUM):
      # Opt
      opt = random.randint(0, 3)
      f.write(f"{opt}\n")
      # img11
      for k in range(16):
        if i == 0:
          tmp = 1
        elif i == 1:
          tmp = 1
        else:
          tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
        tmh = fp2hex(tmp)
        tmf = hex2fp(tmh)
        img11.append(tmf)
        f.write(f"{tmh} ")
      f.write("\n")

      # img12
      for k in range(16):
        if i == 0:
          tmp = 1
        elif i == 1:
          tmp = 2
        else:
          tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
        tmh = fp2hex(tmp)
        tmf = hex2fp(tmh)
        img12.append(tmf)
        f.write(f"{tmh} ")
      f.write("\n")

      # img13
      for k in range(16):
        if i == 0:
          tmp = 1
        elif i == 1:
          tmp = -1
        else:
          tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
        tmh = fp2hex(tmp)
        tmf = hex2fp(tmh)
        img13.append(tmf)
        f.write(f"{tmh} ")
      f.write("\n")

      # ker1
      for k in range(9):
        if i == 0 or i == 1:
          tmp = random.choices([0.1,0.5])[0]
        else:
          tmp = random.uniform(0, 0.5) * random.choice([1, -1])
        # ic(tmp)
        tmh = fp2hex(tmp)
        tmf = hex2fp(tmh)
        ker1.append(tmf)
        f.write(f"{tmh} ")
      f.write("\n")
      # ker2
      for k in range(9):
        if i == 0 or i == 1:
          tmp = random.choices([0.1,0.5])[0]
        else:
          tmp = random.uniform(0, 0.5) * random.choice([1, -1])

        tmh = fp2hex(tmp)
        tmf = hex2fp(tmh)
        ker2.append(tmf)
        f.write(f"{tmh} ")
      f.write("\n")
      # ker3
      for k in range(9):
        if i == 0 or i == 1:
          tmp = random.choices([0.1,0.5])[0]
        else:
          tmp = random.uniform(0, 0.5) * random.choice([1, -1])

        tmh = fp2hex(tmp)
        tmf = hex2fp(tmh)
        ker3.append(tmf)
        f.write(f"{tmh} ")
      f.write("\n")

      # weight
      for k in range(4):
        if i == 0 or i == 1:
          tmp = random.choices([0.1,0.5])[0]
        else:
          tmp = random.uniform(0, 0.5) * random.choice([1, -1])
        tmh = fp2hex(tmp)
        tmf = hex2fp(tmh)
        weight.append(tmf)
        f.write(f"{tmh} ")
      f.write("\n")
