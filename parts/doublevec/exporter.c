#include <math.h>
#include <stdio.h>
#include <inttypes.h>
#include <limits.h>

#define PI atan2 (0.0, -1.0)

const double d = 4.0;

//Octoeder
//charside and spriteside: find smallest y and x value: subtract that offset from each point, so stuff is centered upper left in each area, movement however has full x and yoffset, then both should be able to be combined? on top off taht add a globaö offste to move whole object?

//#include "elite.h"
//#include "iso.h"
//#include "octo.h"
//#include "pyramid.h"

unsigned int get_y_min(int tx1, int ty1, int tx2, int ty2, int tx3, int ty3) {
    unsigned int y_min = 0;
    int y = ty1;
    int x = tx1;

    if (ty2 == y && tx2 > x) {
        y_min = 1;
        y = ty2;
        x = tx2;
    }
    if (ty2 <  y) {
        y_min = 1;
        y = ty2;
        x = tx2;
    }
    if (ty3 == y && tx3 > x) {
        y_min = 2;
        y = ty3;
        x = tx3;
    }
    if (ty3 <  y) {
        y_min = 2;
        y = ty3;
        x = tx3;
    }
    return y_min;
}

unsigned int get_y_max(int tx1, int ty1, int tx2, int ty2, int tx3, int ty3) {
    unsigned int y_max = 0;
    int y = ty1;
    int x = tx1;
    if (ty2 == y && tx2 > x) {
        y_max = 1;
        y = ty2;
        x = tx2;
    }
    if (ty2 >  y) {
        y_max = 1;
        y = ty2;
        x = tx2;
    }
    if (ty3 == y && tx3 > x) {
        y_max = 2;
        y = ty3;
        x = tx3;
    }
    if (ty3 >  y) {
        y_max = 2;
        y = ty3;
        x = tx3;
    }
    return y_max;
}

int check_faces(int num_f, int face, int (*faces)[4], int* done, int* t_x, int* t_y) {
    //fprintf(stderr, "num: %d x1: %03d y1: %03d   x2: %03d y2: %03d   x3: %03d y3: %03d\n", face, t_x[faces[face][0]], t_y[faces[face][0]], t_x[faces[face][1]], t_y[faces[face][1]], t_x[faces[face][2]], t_y[faces[face][2]]);
    unsigned int sy_min;
    unsigned int sy_max;

    unsigned int ty_min;
    unsigned int ty_max;
    int i, j, k;
    int edge = 0;

    int sx1;
    int sy1;
    int sx2;
    int sy2;
    int sx3;
    int sy3;

    sy_min = get_y_min(t_x[faces[face][0]], t_y[faces[face][0]], t_x[faces[face][1]], t_y[faces[face][1]], t_x[faces[face][2]], t_y[faces[face][2]]);
    sy_max = get_y_max(t_x[faces[face][0]], t_y[faces[face][0]], t_x[faces[face][1]], t_y[faces[face][1]], t_x[faces[face][2]], t_y[faces[face][2]]);

    sx1 = t_x[faces[face][sy_min]];
    sx2 = t_x[faces[face][(sy_min + 2) % 3]];
    sx3 = t_x[faces[face][(sy_min + 1) % 3]];
    sy1 = t_y[faces[face][sy_min]];
    sy2 = t_y[faces[face][(sy_min + 2) % 3]];
    sy3 = t_y[faces[face][(sy_min + 1) % 3]];

    for (i = 0; i < num_f; i++) {
        if (i != face && !done[i]) {
            //do we have common vertices?

            ty_min = get_y_min(t_x[faces[i][0]], t_y[faces[i][0]], t_x[faces[i][1]], t_y[faces[i][1]], t_x[faces[i][2]], t_y[faces[i][2]]);
            ty_max = get_y_max(t_x[faces[i][0]], t_y[faces[i][0]], t_x[faces[i][1]], t_y[faces[i][1]], t_x[faces[i][2]], t_y[faces[i][2]]);

            //another edges on right side?
            if ((sy_min + 2) % 3 != sy_max) {
                for (k = 0; k < 3; k++) {
                    //edge from source matches on edge of dst?
                    if (sx1 == t_x[faces[i][k]] && sy1 == t_y[faces[i][k]] && sx2 == t_x[faces[i][(k + 1) % 3]] && sy2 == t_y[faces[i][(k + 1) % 3]]) {
                        return 1;
                    }
                }
                for (k = 0; k < 3; k++) {
                    //second edge too?
                    if (sx2 == t_x[faces[i][k]] && sy2 == t_y[faces[i][k]] && sx3 == t_x[faces[i][(k + 1) % 3]] && sy3 == t_y[faces[i][(k + 1) % 3]]) {
                        return 1;
                    }
                }
                for (k = 0; k < 3; k++) {
                    //check if anything touches middle point
                    if (sx2 == t_x[faces[i][k]] && sy2 == t_y[faces[i][k]]) {
                        return 1;
                    }
                }
            } else {
                for (k = 0; k < 3; k++) {
                    //edge from source matches on edge of dst?
                    if (sx1 == t_x[faces[i][k]] && sy1 == t_y[faces[i][k]] && sx2 == t_x[faces[i][(k + 1) % 3]] && sy2 == t_y[faces[i][(k + 1) % 3]]) {
                        return 1;
                    }
                }
                //face to the right with a common point at y_min may not have anything below our y_min
                //use determinant for that purpose, so point with y_max of other face must be on the right hand side, clockwise
                //same as signed area, negative = anticlockwise, else, clockwise
                for (k = 0; k < 3; k++) {
                    if (sx1 == t_x[faces[i][k]] && sy1 == t_y[faces[i][k]] && sy1 < t_y[faces[i][ty_max]]) {
                        if ((t_x[faces[i][ty_max]] - sx2) * (sy1 - sy2) - (t_y[faces[i][ty_max]] - sy2) * (sx1 - sx2) < 0) {
                            return 1;
                        }
                    }
                }
                //face to the right with a common point at y_max may not have anything above our y_max
                //use determinant for that purpose, so point with y_min of other face must be on the right hand side, clockwise
                //same as signed area, negative = anticlockwise, else, clockwise
                for (k = 0; k < 3; k++) {
                    if (sx2 == t_x[faces[i][k]] && sy2 == t_y[faces[i][k]] && sy2 > t_y[faces[i][ty_min]]) {
                        if ((t_x[faces[i][ty_min]] - sx2) * (sy1 - sy2) - (t_y[faces[i][ty_min]] - sy2) * (sx1 - sx2) < 0) {
                            return 1;
                        }
                    }
                }
            }
            //D = (px-p1x)*(p2y-p1y)-(py-p1y)*(p2x-p1x)
            //determinante

        }
    }
    return 0;
}

double distance(double p1x, double p1y, double p2x, double p2y) {
    return sqrtf((p2x - p1x) * (p2x - p1x) + (p2y - p1y) * (p2y - p1y));
}

double midpoint(double p1, double p2, double p3) {
	return (p1 + p2 + p3) / 3;
}

void output_frame(int num_v, int num_f, double (*vertices)[3], int (*faces)[4], double deg_x, double deg_y, double deg_z, int plane) {
    int i;
    int t_x[num_v];
    int t_y[num_v];

    int u_x[256];
    int u_y[256];

    double v_x[num_v];
    double v_y[num_v];
    double v_z[num_v];

    double x, y, z;
    double x_, y_, z_;

    double sam;

    //int p_old;

    int v0_x, v1_x, v2_x;
    int v0_y, v1_y, v2_y;
    unsigned int y_min, y_max;

    int done[num_f];

    int processed;
    int pattern;
    int edge;

    double normal_x[num_f];
    double normal_y[num_f];
    double normal_z[num_f];
    double normal[num_f];

    int off_x, off_y;
    int off_xm, off_ym;

    int k;

    int space_x, space_y;

    double r;

    double circle_r;
    double circle_x;
    double circle_y;
    double dx;
    double dy;

    int p, p1, p2, p3;
    int used_vertices = 0;

        for (i = 0; i < num_v; i++) {
            //rotate this shit
            x_ = vertices[i][0] * cosf(deg_z) - vertices[i][1] * sinf(deg_z);
            y_ = vertices[i][0] * sinf(deg_z) + vertices[i][1] * cosf(deg_z);

            x = x_;
            y = y_;

            y_ = y * cosf(deg_y) - vertices[i][2] * sinf(deg_y);
            z_ = y * sinf(deg_y) + vertices[i][2] * cosf(deg_y);

            y = y_;
            z = z_;

            x_ = z * sinf(deg_x) + x * cosf(deg_x);
            z_ = z * cosf(deg_x) - x * sinf(deg_x);

            v_x[i] = x_ / (1.0 + z_ / d);
            v_y[i] = y_ / (1.0 + z_ / d);
            v_z[i] = z_ / (1.0 + z_ / d);

            //perspective
            t_x[i] = ((x_ / (1.0 + z_ / d)) * scaling + 64.0) + 0.5;
            t_y[i] = ((y_ / (1.0 + z_ / d)) * scaling + 64.0) + 0.5;
        }
        for (i = 0; i < num_f; i++) {
            done[i] = 0;
        }

        off_x = INT_MAX; off_y = INT_MAX;
        off_xm = INT_MIN; off_ym = INT_MIN;
        processed = 0;
        used_vertices = 0;
        for (i = 0; i < num_f; i++) {
            //area transformed / area untransformed = normalized normal?
            normal_x[i] = (v_y[faces[i][1]] - v_y[faces[i][0]]) * (v_z[faces[i][2]] - v_z[faces[i][0]]) - (v_y[faces[i][2]] - v_y[faces[i][0]]) * (v_z[faces[i][1]] - v_z[faces[i][0]]);
            normal_y[i] = (v_z[faces[i][1]] - v_z[faces[i][0]]) * (v_x[faces[i][2]] - v_x[faces[i][0]]) - (v_z[faces[i][2]] - v_z[faces[i][0]]) * (v_x[faces[i][1]] - v_x[faces[i][0]]);
            normal_z[i] = (v_x[faces[i][1]] - v_x[faces[i][0]]) * (v_y[faces[i][2]] - v_y[faces[i][0]]) - (v_x[faces[i][2]] - v_x[faces[i][0]]) * (v_y[faces[i][1]] - v_y[faces[i][0]]);
            normal[i] = normal_z[i] / sqrtf(((normal_x[i] * normal_x[i]) + (normal_y[i] * normal_y[i]) + (normal_z[i] * normal_z[i])));
            if (normal[i] > 0) normal[i] = 0;
            //culling via signed area
            sam = (t_y[faces[i][1]] - t_y[faces[i][0]]) * (t_x[faces[i][2]] - t_x[faces[i][1]]) - (t_x[faces[i][1]] - t_x[faces[i][0]]) * (t_y[faces[i][2]] - t_y[faces[i][1]]);
            //mark culled faces as done
            if(sam <= 0) {
                done[i] = 1;
                processed++;
            } else {
                //create a list of used vertices
                u_x[used_vertices] = t_x[faces[i][0]];
                u_y[used_vertices] = t_y[faces[i][0]];
                used_vertices++;
                u_x[used_vertices] = t_x[faces[i][1]];
                u_y[used_vertices] = t_y[faces[i][1]];
                used_vertices++;
                u_x[used_vertices] = t_x[faces[i][2]];
                u_y[used_vertices] = t_y[faces[i][2]];
                used_vertices++;

                if (off_x > t_x[faces[i][0]]) off_x = t_x[faces[i][0]];
                if (off_x > t_x[faces[i][1]]) off_x = t_x[faces[i][1]];
                if (off_x > t_x[faces[i][2]]) off_x = t_x[faces[i][2]];
                if (off_y > t_y[faces[i][0]]) off_y = t_y[faces[i][0]];
                if (off_y > t_y[faces[i][1]]) off_y = t_y[faces[i][1]];
                if (off_y > t_y[faces[i][2]]) off_y = t_y[faces[i][2]];

                if (off_xm < t_x[faces[i][0]]) off_xm = t_x[faces[i][0]];
                if (off_xm < t_x[faces[i][1]]) off_xm = t_x[faces[i][1]];
                if (off_xm < t_x[faces[i][2]]) off_xm = t_x[faces[i][2]];
                if (off_ym < t_y[faces[i][0]]) off_ym = t_y[faces[i][0]];
                if (off_ym < t_y[faces[i][1]]) off_ym = t_y[faces[i][1]];
                if (off_ym < t_y[faces[i][2]]) off_ym = t_y[faces[i][2]];
            }
        }
        if (object == 4 && plane == 2) {
            if (processed == 4) processed = num_f;
            //for (i = 0; i < num_f; i++) {
            //    done [i] = 1;
            //}
            //if (deg_z > PI && deg_z < 2.0 * PI) {
                //done[i] = 1;
                //processed++;
                //}
        }

//        circle_r = (double)INT_MAX;
//        circle_x = 0;
//        circle_y = 0;
//
//        for (p1 = 0; p1 < used_vertices; p1++) {
//            for (p2 = 0; p2 < used_vertices; p2++) {
//                if (p1 != p2) {
//                    p = 0;
//                    dx = (u_x[p1] + u_x[p2]) / 2.0;
//                    dy = (u_y[p1] + u_y[p2]) / 2.0;
//                    r = distance(u_x[p1], u_y[p1], dx, dy);
//                    if (r < circle_r) {
//                        for (p = 0; p < used_vertices; p++) {
//                            //point is outside of circle
//                            if (r < distance(u_x[p], u_y[p], dx, dy)) break;
//                        }
//                    }
//                    if (p == used_vertices) {
//                        circle_r = r;
//                        circle_x = dx;
//                        circle_y = dy;
//                    }
//                }
//            }
//        }
//
//        for (p1 = 0; p1 < used_vertices; p1++) {
//            for (p2 = 0; p2 < used_vertices; p2++) {
//                for (p3 = 0; p3 < used_vertices; p3++) {
//                    if (p1 != p2 != p3) {
//                        p = 0;
//                        dx = midpoint(u_x[p1], u_x[p2], u_x[p3]);
//                        dy = midpoint(u_y[p1], u_y[p2], u_y[p3]);
//                        r = distance(u_x[p1], u_y[p1], dx, dy);
//                        if (r < circle_r) {
//                            for (p = 0; p < used_vertices; p++) {
//                                if (r < distance(u_x[p], u_y[p], dx, dy)) break;
//                            }
//                        }
//                        if (p == used_vertices) {
//                            circle_r = r;
//                            circle_x = dx;
//                            circle_y = dy;
//                        }
//                    }
//                }
//            }
//        }
//
//        fprintf(stderr, "ficken %.2f %.2f %.2f\n", circle_r, circle_x, circle_y);

        //fprintf(stderr, "off_x: %d off_y %d\n", off_x, off_y);
        //fprintf(stderr, "off_xm: %d off_ym %d\n", off_xm, off_ym);

        space_x = off_x - ((124 - (off_xm - off_x)) / 2);
        //align to MC pixels
        space_x = space_x / 2;
        space_x = space_x * 2;
        space_y = off_y - ((124 - (off_ym - off_y)) / 2);

        //space_x = (int)(circle_x - circle_r);
        //space_y = (int)(circle_y - circle_r);

        if (space_x > 512 || !used_vertices) space_x = 0;
        if (space_y > 512 || !used_vertices) space_y = 0;

        //if (space_x < 255 && space_y < 255) {
        //}

//        r = 64.0;
//
//        for (y = -r; y < r; y++) {
//            for (x = -r; x < r; x++) {
//                for (i = 0; i < num_f; i++) {
//                    if (!done[i]) {
//                        if ( sqrtf( ((r - (t_x[faces[i][0]] + (double)x)) * (r - (t_x[faces[i][0]] + (double)x))) + ((r - (t_y[faces[i][0]] + (double)y)) * (r - (t_y[faces[i][0]] + (double)y))) ) > r) break;
//                        if ( sqrtf( ((r - (t_x[faces[i][1]] + (double)x)) * (r - (t_x[faces[i][1]] + (double)x))) + ((r - (t_y[faces[i][1]] + (double)y)) * (r - (t_y[faces[i][1]] + (double)y))) ) > r) break;
//                        if ( sqrtf( ((r - (t_x[faces[i][2]] + (double)x)) * (r - (t_x[faces[i][2]] + (double)x))) + ((r - (t_y[faces[i][2]] + (double)y)) * (r - (t_y[faces[i][2]] + (double)y))) ) > r) break;
//                    }
//                }
//                if (i == num_f) goto match;
//            }
//        }
//match:
//        space_x = x;
//        space_y = y;

        //XXX TODO make bit 7 of space_x alwaysset as framemarker? -> as soon as first byte of face >= $80, next frame?
        //bit 0 is also available, as it is always forced to zero due to mc pixel size, so offset_x is always a multiple of 2
        //if (processed == num_f) {
        //    printf("!byte $ff\n");
        //} else {
        //}
        if (space_x >= 128) fprintf(stderr, "saubatz!\n");
        while (processed < num_f) {
            for (i = 0; i < num_f; i++) {
                if (!done[i]) {
                    y_min = get_y_min(t_x[faces[i][0]], t_y[faces[i][0]], t_x[faces[i][1]], t_y[faces[i][1]], t_x[faces[i][2]], t_y[faces[i][2]]);
                    y_max = get_y_max(t_x[faces[i][0]], t_y[faces[i][0]], t_x[faces[i][1]], t_y[faces[i][1]], t_x[faces[i][2]], t_y[faces[i][2]]);
                    edge = check_faces(num_f, i, faces, done, t_x, t_y);
                    if (!edge) break;
                }
            }
            //fprintf(stderr, "\n");

            if (i < num_f) {
                //fprintf(stderr, "num: %d\n", i);
                //fprintf(stderr, "num: %d x: % 3d y: % 3d\n", 0, t_x[faces[i][0]], t_y[faces[i][0]]);
                //fprintf(stderr, "num: %d x: % 3d y: % 3d\n", 1, t_x[faces[i][1]], t_y[faces[i][1]]);
                //fprintf(stderr, "num: %d x: % 3d y: % 3d\n", 2, t_x[faces[i][2]], t_y[faces[i][2]]);

                processed++;
                done[i] = 1;


                v0_x = t_x[faces[i][(y_max + 0) % 3]] - space_x;
                v1_x = t_x[faces[i][(y_max + 1) % 3]] - space_x;
                v2_x = t_x[faces[i][(y_max + 2) % 3]] - space_x;

                v0_y = t_y[faces[i][(y_max + 0) % 3]] - space_y;
                v1_y = t_y[faces[i][(y_max + 1) % 3]] - space_y;
                v2_y = t_y[faces[i][(y_max + 2) % 3]] - space_y;

                //fprintf(stderr, "v0_x: %d\n", v0_x);
                //fprintf(stderr, "v1_x: %d\n", v1_x);
                //fprintf(stderr, "v2_x: %d\n", v2_x);
                //fprintf(stderr, "v0_y: %d\n", v0_y);
                ////fprintf(stderr, "v1_y: %d\n", v1_y);
                //fprintf(stderr, "v2_y: %d\n", v2_y);

                if (v0_x < 0) fprintf(stderr, "v0_x: %d\n", v0_x);
                if (v1_x < 0) fprintf(stderr, "v1_x: %d\n", v1_x);
                if (v2_x < 0) fprintf(stderr, "v2_x: %d\n", v2_x);
                if (v0_y < 0) fprintf(stderr, "v0_y: %d\n", v0_y);
                if (v1_y < 0) fprintf(stderr, "v1_y: %d\n", v1_y);
                if (v2_y < 0) fprintf(stderr, "v2_y: %d\n", v2_y);

                pattern = ((normal[i] * - 1.0) * pattern_factor) ;//faces[i][3];
		if (pattern > 0xb) pattern = 0xb;
                if (plane == 1) {
                    if (pattern < min_color_char) pattern = min_color_char;
                    pattern += color_offset_char;
                } else {
                    if (pattern < min_color_sprite) pattern = min_color_sprite;
                    pattern += color_offset_sprite;
                }
		v1_y = ((v1_y << 1) | (pattern & 0x8) >> 3);// & 0xff;
		v1_x = ((v1_x << 1) | (pattern & 0x4) >> 2);// & 0xff;
		v2_y = ((v2_y << 1) | (pattern & 0x2) >> 1);// & 0xff;
		v2_x = ((v2_x << 1) | (pattern & 0x1) >> 0);// & 0xff;

                printf("!byte $%02x,$%02x,$%02x,$%02x,$%02x,$%02x\n", v0_y, v0_x, v1_y, v1_x, v2_y, v2_x);
            }
        }
        printf(";space_x: %d space_y %d\n", space_x, space_y);
        printf("!byte $%02x,$%02x\n", (space_x + 64), space_y + 64 | 0x80);
}

int main () {
    int max_frames = 256;
    int frame;
    double deg_x = 0.0;
    double deg_y = 0.0;
    double deg_z = 0.0;

    for (frame = 0; frame < num_frames; frame++) {

        deg_x = 2 * PI / (double)max_frames * frame * factor_x1;
        deg_y = 2 * PI / (double)max_frames * frame * factor_y1;
        deg_z = 2 * PI / (double)max_frames * frame * factor_z1;

        //output_frame(num_vertices, num_faces, vertices, faces, deg_x, deg_y, deg_z);
        output_frame(num_vertices1, num_faces1, vertices1, faces1, deg_x, deg_y, deg_z,1);

        deg_x = 2 * PI / (double)max_frames * frame * factor_x2;
        deg_y = 2 * PI / (double)max_frames * frame * factor_y2;
        deg_z = 2 * PI / (double)max_frames * frame * factor_z2;
        output_frame(num_vertices2, num_faces2, vertices2, faces2, deg_x, deg_y, deg_z,2);

	frame++;
        deg_x = 2 * PI / (double)max_frames * frame * factor_x2;
        deg_y = 2 * PI / (double)max_frames * frame * factor_y2;
        deg_z = 2 * PI / (double)max_frames * frame * factor_z2;

        //output_frame(num_vertices, num_faces, vertices, faces, deg_x, deg_y, deg_z);
        output_frame(num_vertices2, num_faces2, vertices2, faces2, deg_x, deg_y, deg_z,2);
        deg_x = 2 * PI / (double)max_frames * frame * factor_x1;
        deg_y = 2 * PI / (double)max_frames * frame * factor_y1;
        deg_z = 2 * PI / (double)max_frames * frame * factor_z1;
        output_frame(num_vertices1, num_faces1, vertices1, faces1, deg_x, deg_y, deg_z,1);
    }
    return 0;
}
