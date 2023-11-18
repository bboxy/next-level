const int object = 5;
const int num_frames = 134;
const int min_color_sprite = 3;
const int min_color_char = 0;
const int color_offset_sprite = 1;
const int color_offset_char = 1;
const double pattern_factor = 12.0;

const double scaling = 45.0;
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
const double height = 0.5;

const int num_faces1 = 6;
const int num_vertices1 = 9;

double vertices1[][3] = {
{0.0, 0.0, 0.0},
{1.00000000, -1.00000000, 0.00000000},
{0.50000000, -1.00000000, 0.86602540},
{-0.50000000, -1.00000000, 0.86602540},
{-1.00000000, -1.00000000, 0.00000000000000012246468},
{-0.50000000, -1.00000000, -0.86602540},
{0.50000000, -1.00000000, -0.86602540},
{0.00000000, 1.00000000, 0.00000000},
{0.00000000, -1.00000000, 0.00000000},
};

int faces1[][4] = {
{1, 7, 2, 0},
{3, 7, 4, 0},
{5, 7, 6, 0},

{3, 8, 2, 0},
{5, 8, 4, 0},
{1, 8, 6, 0},
};
//a cube
const int num_faces2 = 6;
const int num_vertices2 = 9;

double vertices2[][3] = {
{0.0, 0.0, 0.0},
{1.00000000, -1.00000000, 0.00000000},
{0.50000000, -1.00000000, 0.86602540},
{-0.50000000, -1.00000000, 0.86602540},
{-1.00000000, -1.00000000, 0.00000000000000012246468},
{-0.50000000, -1.00000000, -0.86602540},
{0.50000000, -1.00000000, -0.86602540},
{0.00000000, 1.00000000, 0.00000000},
{0.00000000, -1.00000000, 0.00000000},
};

int faces2[][4] = {
{2, 7, 3, 0},
{4, 7, 5, 0},
{6, 7, 1, 0},

{2, 8, 1, 0},
{4, 8, 3, 0},
{6, 8, 5, 0},
};



