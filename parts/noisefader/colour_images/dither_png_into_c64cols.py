import imageio
import math
import numpy as np

def get_c64col(r,g,b):
  pal = [
    (0x00, 0x00, 0x00),
    (0xFF, 0xFF, 0xFF),
    (0x68, 0x37, 0x2B),
    (0x70, 0xA4, 0xB2),
    (0x6F, 0x3D, 0x86),
    (0x58, 0x8D, 0x43),
    (0x35, 0x28, 0x79),
    (0xB8, 0xC7, 0x6F),
    (0x6F, 0x4F, 0x25),
    (0x43, 0x39, 0x00),
    (0x9A, 0x67, 0x59),
    (0x44, 0x44, 0x44),
    (0x6C, 0x6C, 0x6C),
    (0x9A, 0xD2, 0x84),
    (0x6C, 0x5E, 0xB5),
    (0x95, 0x95, 0x95),
  ];
  best_col_no = -1
  best_col_distance = 1000000
  for col_no in range(16):
    dist = math.sqrt((r-pal[col_no][0])*(r-pal[col_no][0]) + (g-pal[col_no][1])*(g-pal[col_no][1]) + (b-pal[col_no][2])*(b-pal[col_no][2]))
    if (dist < best_col_distance):
      best_col_distance = dist
      best_col_no = col_no
  return pal[best_col_no]

def do(filename):
  im = imageio.imread('%s.png' % filename)
  print(im.shape)

  # 41, 128, 4

  (height, width, channels) = im.shape

  imf = np.zeros([height,width,channels],dtype=np.float)


  for y in range(height):
    for x in range(width):
      for c in range(3):
        imf[y][x][c] = im[y][x][c]

  brightness_factor = 0.88

  for y in range(height):
    for x in range(width):
      r = imf[y][x][0] * brightness_factor
      g = imf[y][x][1] * brightness_factor
      b = imf[y][x][2] * brightness_factor
      closest_c64col = get_c64col(r,g,b)
      im[y][x][0] = closest_c64col[0]
      im[y][x][1] = closest_c64col[1]
      im[y][x][2] = closest_c64col[2]

      quant_error_r = r - closest_c64col[0]
      quant_error_g = g - closest_c64col[1]
      quant_error_b = b - closest_c64col[2]

      #pixels[x + 1][y    ] := pixels[x + 1][y    ] + quant_error × 7 / 16
      try:
        imf[y][x+1][0] += quant_error_r * 7.0 / 16
        imf[y][x+1][1] += quant_error_g * 7.0 / 16
        imf[y][x+1][2] += quant_error_b * 7.0 / 16
      except:
        pass

      #pixels[x - 1][y + 1] := pixels[x - 1][y + 1] + quant_error × 3 / 16
      try:
        imf[y+1][x-1][0] += quant_error_r * 3.0 / 16
        imf[y+1][x-1][1] += quant_error_g * 3.0 / 16
        imf[y+1][x-1][2] += quant_error_b * 3.0 / 16
      except:
        pass

      #pixels[x    ][y + 1] := pixels[x    ][y + 1] + quant_error × 5 / 16
      try:
        imf[y+1][x][0] += quant_error_r * 5.0 / 16
        imf[y+1][x][1] += quant_error_g * 5.0 / 16
        imf[y+1][x][2] += quant_error_b * 5.0 / 16
      except:
        pass

      #pixels[x + 1][y + 1] := pixels[x + 1][y + 1] + quant_error × 1 / 16
      try:
        imf[y+1][x+1][0] += quant_error_r * 1.0 / 16
        imf[y+1][x+1][1] += quant_error_g * 1.0 / 16
        imf[y+1][x+1][2] += quant_error_b * 1.0 / 16
      except:
        pass

  wrote = imageio.imwrite('%s_dither.png' % filename, im)


for file_no in range(4):
  filename = 'colimage_%d' % file_no
  do(filename)
