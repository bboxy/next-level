const int object = 1;
const int num_frames = 94;
const int min_color_sprite = 0;
const int min_color_char = 0;
const int color_offset_sprite = 1;
const int color_offset_char = 1;
const double pattern_factor = 15.0;

const double scaling = 48.0;
const double factor_x1 = 3.0;
const double factor_y1 = 0.0;
const double factor_z1 = 1.5;

const double factor_x2 = 0.0;
const double factor_y2 = 3.0;
const double factor_z2 = 1.5;

const int num_faces1 = 4;
const int num_vertices1 = 5;

const double width = 0.6;
const double depth = 0.59;
const double height = 1.0;

double vertices1[][3] = {
{ 0.0, 0.0, 0.0 },
{ 0.0000000, (2.0*width), 0.0000000 },
{ 0.0000000, -width, (2.0*depth) },
{ -height, -width, -depth },
{ height, -width, -depth }
};

int faces1[][4] = {
{ 1, 3, 2, 0x03 },
{ 1, 4, 3, 0x06 },
{ 2, 4, 1, 0x09 },
{ 3, 4, 2, 0x0b }
};

const int num_faces2 = 4;
const int num_vertices2 = 5;

double vertices2[][3] = {
{ 0.0, 0.0, 0.0 },
{ 0.0000000, -(2.0*width), 0.0000000 },
{ 0.0000000, width, -(2.0*depth) },
{ height, width, depth },
{ -height, width, depth }
};

int faces2[][4] = {
{ 1, 3, 2, 0x03 },
{ 1, 4, 3, 0x06 },
{ 2, 4, 1, 0x09 },
{ 3, 4, 2, 0x0b }
};
