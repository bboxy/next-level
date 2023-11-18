import imageio
import math
import numpy as np

def do(filename1, filename2, output_filename):
  print("Loading two binary colimages:")
  print(filename1)
  print(filename2)
  print("They only contain colous in the low 4 bits of a byte.")
  print("Put the second file's nybbles in the high nybble.")

  try:
    with open(filename1, "rb") as f:
      numpy_data_1 = np.fromfile(f,np.dtype('B'))
  except IOError:
    print('Error While Opening the file %s' % filename1)

  try:
    with open(filename2, "rb") as f:
      numpy_data_2 = np.fromfile(f,np.dtype('B'))
  except IOError:
    print('Error While Opening the file %s' % filename2)

  print(numpy_data_1)
  print(numpy_data_2)

  nof_bytes = len(numpy_data_1)
  print("Nof bytes = %d" % nof_bytes)

  for byte_no in range(nof_bytes):
    col1 = numpy_data_1[byte_no]
    col2 = numpy_data_2[byte_no]
    numpy_data_1[byte_no] = col1 + col2 * 16

  print("Saving as a new filename.")
  print(output_filename)

  byte_data = bytes(numpy_data_1)
  with open(output_filename,"wb") as f:
    f.write(byte_data)
    f.close()

do ("colimage_0_dither.bin", "colimage_1_dither.bin", "colimage_01.bin")
do ("colimage_2_dither.bin", "colimage_3_dither.bin", "colimage_23.bin")

