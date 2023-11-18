import imageio
import math
import numpy as np

values = []
nof_values = 24*2*2*2

for x in range(nof_values):
  percentage = x / nof_values + 0.001
  value = 128.5 + 127.5 * math.sin(2 * math.pi * percentage)
  values.append(math.floor(value))
values.append(0)

print("dc.b")
print(values)

