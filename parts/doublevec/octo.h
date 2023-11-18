const int object = 2;
const int num_frames = 152;
const int min_color_sprite = 0;
const int min_color_char = 0;
const int color_offset_sprite = 1;
const int color_offset_char = 1;
const double pattern_factor = 12.0;

const int num_faces1 = 4;
const int num_vertices1 = 7;
const double scaling = 100.0;
const double factor_x1 = 3.0;
const double factor_y1 = 2.0;
const double factor_z1 = 1.0;
//const double factor_x1 = 1.5;
//const double factor_y1 = 1.5;
//const double factor_z1 = 0.5;

const double factor_x2 = factor_x1;
const double factor_y2 = factor_y1;
const double factor_z2 = factor_z1;

const double size = 0.50;
const double height = 1.0;
double vertices1[][3] = {
{0.0, 0.0, 0.0},
{size, 0.0000000, 0.0000000},
{-size, 0.0000000, 0.0000000},
{0.0000000, size, 0.0000000},
{0.0000000, -size, 0.0000000},
{0.0000000, 0.0000000, height},
{0.0000000, 0.0000000, -height},
};

int faces1[][4] = {
//{1, 5, 4, 0x4},
{1, 6, 3, 0x6},
//{2, 5, 3, 0x8},
{2, 6, 4, 0xb},
//{3, 5, 1, 0x4},
{3, 6, 2, 0x6},
//{4, 5, 2, 0x8},
{4, 6, 1, 0xb},
};
//a cube
const int num_faces2 = 4;
const int num_vertices2 = 7;

double vertices2[][3] = {
{0.0, 0.0, 0.0},
{size, 0.0000000, 0.0000000},
{-size, 0.0000000, 0.0000000},
{0.0000000, size, 0.0000000},
{0.0000000, -size, 0.0000000},
{0.0000000, 0.0000000, height},
{0.0000000, 0.0000000, -height},
};

int faces2[][4] = {
{1, 5, 4, 0x4},
//{1, 6, 3, 0x6},
{2, 5, 3, 0x8},
//{2, 6, 4, 0xb},
{3, 5, 1, 0x4},
//{3, 6, 2, 0x6},
{4, 5, 2, 0x8},
//{4, 6, 1, 0xb},
};
