#include <stdio.h>
#include <inttypes.h>
#include <string.h>
#include <limits.h>
#include <stdarg.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>

#define Y_SIZE 2

static int COL_BG    = 14;
static int COL_MC1   = 15;
static int COL_MC2   = 12;
static int switch_line = 1000;

static unsigned int width;
static unsigned int height;
static unsigned int pitch;
static uint32_t *pixels;
static SDL_PixelFormat *format;
static int y_pos_to_print;
static int x_pos_to_print;
static unsigned char charset_c64[2084];
static SDL_Surface *mainscreen;

static int find_char(uint8_t* charset, uint8_t* block, int pos);
static int is_hires(int bx, int by);

typedef struct _boxes {
	int x;
	int y;
	int x2;
	int y2;
	int clash;
	struct _boxes *next;
} Boxes;

static Boxes *clashes = NULL;
static Boxes *left_up = NULL;
static Boxes *right_down = NULL;
static Boxes *sprite_boxes = NULL;
static uint8_t *colormap;
static uint8_t *charmap;
static int w_blocks;
static int h_blocks;
static uint8_t charset[65536];
static int cs_num;

#define KILL { char *a = NULL; *a = 0; }

static unsigned char palette_data[18][3] = {
	{  0,  0,  0},
	{255,255,255},
	{126, 53, 43},
	{110,183,193},
	{127, 59,166},
	{ 92,160, 53},
	{ 51, 39,153},
	{203,215,101},
	{133, 83, 28},
	{ 80, 60,  0},
	{180,107, 97},
	{ 74, 74, 74},
	{117,117,117},
	{163,231,124},
	{112,100,214},
	{163,163,163},
	{255,  0,  0},
	{  0,255,  0}
};

static double y_u_v[18][3];

static void add_element(Boxes **box_list, int x, int y, int x2, int y2, int clash)
{
	Boxes *new_box;
	Boxes *current, *last;

	new_box = (Boxes *)malloc(sizeof(Boxes));
	new_box->x = x;
	new_box->y = y;
	new_box->x2 = x2;
	new_box->y2 = y2;
	new_box->clash = clash;
	new_box->next = NULL;
	
	current = *box_list;
	if (!current) {
		*box_list = new_box;
	}
	else {
		last = NULL;
		while(current) {
			if ((current->y >= y) && (current->x >= x)) {
				if (!last) {
					*box_list = new_box;
				} else {
					last->next = new_box;
				}
				new_box->next = current;
				return;
			}
			last = current;
			current = current->next;
		}
		last->next = new_box;
	}
}

static void add_clash(int x, int y, int clash) {
	add_element(&clashes, x, y, 0, 0, clash);
}

static void add_left_up(int x, int y) {
	add_element(&left_up, x, y, 0, 0, 0);
}

static void add_right_down(int x, int y) {
	add_element(&right_down, x, y, 0, 0, 0);
}

static void add_sprite_box(int x, int y, int x2, int y2)
{
	add_element(&sprite_boxes, x, y, x2, y2, 0);
}

static void init_y_u_v(void)
{
	int i;
	double y,u,v;
	for(i=0; i < 18; ++i) {
		y = 0.299 * ((double)(palette_data[i][0])) / 255.0 
			+ 0.587 * ((double)(palette_data[i][1])) / 255.0
			+ 0.114 * ((double)(palette_data[i][2])) / 255.0;
		u = ((((double)(palette_data[i][2])) / 255.0) - y) * 0.493;
		v = ((((double)(palette_data[i][0])) / 255.0) - y) * 0.877;
		y_u_v[i][0] = y;
		y_u_v[i][1] = u;
		y_u_v[i][2] = v;
		//printf("%lf %lf %lf\n", y, u, v);
	}
}
static void set_pixel_rgb(SDL_Surface *pic, int x, int y, unsigned char r, unsigned char g, unsigned char b)
{
	uint32_t data;
	uint32_t *pointer;
	if ((x < 0) || x >= pic->w) {
		return;
	}
	if ((y < 0) || y >= pic->h) {
		return;
	}
	data = ((uint32_t)r) << pic->format->Rshift;
	data |= ((uint32_t)g) << pic->format->Gshift;
	data |= ((uint32_t)b) << pic->format->Bshift;
	pointer = (uint32_t *)(((char *)pic->pixels) + y*pic->pitch) + x;
	*pointer = data;
}

static void set_pixel_rgb_2x2(SDL_Surface *pic, int x, int y, unsigned char r, unsigned char g, unsigned char b)
{
	set_pixel_rgb(pic, x*2, y*2, r,g,b);
	set_pixel_rgb(pic, x*2+1, y*2, r,g,b);
	set_pixel_rgb(pic, x*2, y*2+1, r,g,b);
	set_pixel_rgb(pic, x*2+1, y*2+1, r,g,b);
}

static void print_char(SDL_Surface *pic, unsigned char ch)
{
	int i;
	int j;
	unsigned char c;
	unsigned char *ptr = charset_c64 + ((int)ch)*8;
	for(j=0; j < 8; ++j) {
		c = *ptr++;
		for(i=0; i < 8; ++i) {
			if (c & 0x80) {
				set_pixel_rgb(pic, x_pos_to_print+i,
					y_pos_to_print+j*Y_SIZE, 0xff, 0xff, 0xff);
			#if Y_SIZE > 1
				set_pixel_rgb(pic, x_pos_to_print+i,
					y_pos_to_print+j*Y_SIZE+1, 0xff, 0xff, 0xff);
			#endif
			}
			c <<=1;
		}
	}
	x_pos_to_print += 8;
}

static void gprintf(const char *format, ...)
{
	int i;
	char str[256];
	char c;
	va_list ap;
	va_start(ap, format);
	vsnprintf(str, 256, format, ap);
	va_end(ap);
	for(i=0; i < 256; ++i) {
		c = str[i];
		if (!c) {
			break;
		}
		if (c >= 'a' && c <= 'z') {
			c-= 'a'-1;
		} else  if (c == '\n') {
			continue;
		} else if (c == '@') {
			c = 0;
		}
		print_char(mainscreen, c); 
	}
	x_pos_to_print = 8;
	y_pos_to_print += 8*Y_SIZE;
}

static int get_index(unsigned char r, unsigned char g, unsigned char b)
{
	int i;
	double y_d;
	double u_d;
	double v_d;
	double min_difference = 1e+80;
	int min_index = -1;
	double difference;
	double y,u,v;
	double y_t,u_t,v_t;
	
	static int once = 0;
	y = 0.299 * ((double)r)/255.0 + 0.587 * ((double)g)/255.0 + 0.114 * ((double)b)/255.0;
	u = (((double)(b) / 255.0) - y) * 0.493;
	v = (((double)(r) / 255.0) - y) * 0.877;
	for(i=0; i < 18; ++i)
	{
		//if (! once) {
		//	printf("%d %lf %lf %lf <-> %lf %lf %lf\n",
		//		i, y,u,v,y_u_v[i][0], y_u_v[i][1], y_u_v[i][2]);
		//}
		y_d = (y - y_u_v[i][0]); 
		u_d = (u - y_u_v[i][1]); 
		v_d = (v - y_u_v[i][2]);
		difference = y_d *y_d + u_d * u_d + v_d * v_d;
		if (difference < min_difference) {
			min_difference = difference;
			min_index = i;
		}
	}
	once = 1;
	if (min_index < 0) {
		KILL;
	}
	return min_index;
}

static int get_pixel(int x, int y)
{
	uint32_t *addr;
	uint32_t data;
	unsigned char r;
	unsigned char g;
	unsigned char b;
	if (x < 0) {
		KILL;
	}
	if (x > width) {
		KILL;
	}
	if (y < 0) {
		KILL;
	}
	if (y > height) {
		KILL;
	}
	addr = (uint32_t *)((char *)pixels + (y * pitch)) + x;
	data = *addr;
	r = (unsigned char)((data & format->Rmask) >> (format->Rshift));
	g = (unsigned char)((data & format->Gmask) >> (format->Gshift));
	b = (unsigned char)((data & format->Bmask) >> (format->Bshift));
	//printf("%08x %02x %02x %02x ,",data, r,g,b);
	return get_index(r,g,b);
}

static void copy_left_pixel(int x, int y)
{
	uint32_t *addr;
	uint32_t data;
	if (x < 1) {
		KILL;
	}
	if (x > width) {
		KILL;
	}
	if (y < 0) {
		KILL;
	}
	if (y > height) {
		KILL;
	}
	addr = (uint32_t *)((char *)pixels + (y * pitch)) + (x-1);
	data = *addr;
	addr[1] = data;
}

static void copy_right_pixel(int x, int y)
{
	uint32_t *addr;
	uint32_t data;
	if (x < 0) {
		KILL;
	}
	if (x >= width) {
		KILL;
	}
	if (y < 0) {
		KILL;
	}
	if (y > height) {
		KILL;
	}
	addr = (uint32_t *)((char *)pixels + (y * pitch)) + (x);
	data = addr[1];
	*addr = data;
}

static int convert(void)
{
    int bx, by;
    int x, y;
    int hires;
    int colram;
    int pix;
    int clash;

    uint8_t bits;
    uint8_t byte;
    uint8_t block[8];
    FILE* fw;

    int charpos;
    int temp;
    int oldpos;
    

    w_blocks = width/8;
    h_blocks = height/8;
    
    gprintf("size is %dx%d\n", w_blocks, h_blocks);
    colormap = (uint8_t *)malloc(w_blocks * h_blocks);
    charmap = (uint8_t *)malloc(w_blocks * h_blocks);
    cs_num = 0;
    charpos = 0;
    /* make the first char the empty one */
    if (COL_BG == 11) {
    	memset(&charset[cs_num * 0x800 + charpos * 8], 0xffffffff, 8);
    } else {
    	memset(&charset[cs_num * 0x800 + charpos * 8], 0, 8);
    }
    charpos++;
    
    for (by = 0; by < height; by += 8) {
        oldpos = charpos;
	if (by >= switch_line * 8) {
		switch_line = 1000;
                cs_num++;
                gprintf("starting new charset %d @ y = $%02x, x = $%02x, %d chars remain unsused\n", cs_num, by, bx / 8, temp - oldpos);
                charpos = 0;
    		/* make the first char the empty one */
    		if (COL_BG == 11) {
    			memset(&charset[cs_num * 0x800 + charpos * 8], 0xffffffff, 8);
    		} else {
    			memset(&charset[cs_num * 0x800 + charpos * 8], 0, 8);
    		}
    		charpos++;
                //reset x position so that we redo line on next charset
	}
        for (bx = 0; bx < width; bx += 8) {
            hires = is_hires(bx, by);
            colram = -1;
            clash = 0;
            for (y = 0; y < 8; y++) {
                byte = 0;
                for (x = 0; x < 8; x++) {
                    pix = get_pixel(bx + x, by + y);
		    //printf("%1X", pix);
                    if(!hires) {
		    	if (pix == COL_BG) {
                                bits = 0;
                        }
			else if (pix == COL_MC1) {
                                bits = 1;
			}
			else if (pix == COL_MC2) {
                                bits = 2;
			} else {
                            if (colram < 0) colram = pix + 8;
                            else if (colram != pix + 8) clash = 1;
                            bits = 3;
			    if (colram >= 16) {
			    	clash = 3;
			    }
                        }
                        byte = (byte << 2) | bits;
                        //skip one pixel (multicolor!)
                        x++;
                    } else {
                        if(pix != COL_BG) {
                            bits = 1;
			    if (colram >= 8)  clash = 4;
                            else if (colram < 0) colram = pix;
                            else if (colram != pix) clash = 2;
                        } else {
                            bits = 0;
                        }
                        byte = (byte << 1) | bits;
                    }
                }
                block[y] = byte;
            }

//save some more chars by transforming empty chars to filled chars with color 0
//            if (block[0] == 0x55 || block[0] == 0xaa || block[0] == 0x00) {
//                for (y = 0; y < 8; y++) {
//                    if (block[0] != block[y]) break;
//                }
//                //all lines are equal
//                if (y == 8) {
//                    if(block[0] == 0) {
//                        colram = 0;
//                        hires = 1;
//                        memset(&block[0], 0xff, 8);
//                    }
//                }
//            }

            if (clash) {
                  gprintf("colram clash (%d)@ x=%d, y=%d\n", clash, bx, by);
		  add_clash(bx, by, clash);
            }
            if (colram < 0) colram = (1 ^ hires) * 8;

            temp = find_char(&charset[cs_num * 0x800], &block[0], charpos);
            charmap[by / 8 * w_blocks + bx / 8] = temp;
            colormap[by / 8 * w_blocks + bx / 8] = colram;

            //FIXME: else the bankswitch would fall into an area that is not shown, thus we can miss the bankswitch completely and we display garbage. (there are only 3 lines of splits that switch $dd00)
            if (temp > 253) {
                //row doesn't fit into charset anymore, do next split
                memset(&charset[cs_num * 0x800 + oldpos * 8], 0x00, (charpos - oldpos) * 8);
                cs_num++;
                gprintf("starting new charset %d @ y = $%02x, x = $%02x, %d chars remain unsused\n", cs_num, by, bx / 8, temp - oldpos);
                charpos = 0;
    		/* make the first char the empty one */
    		if (COL_BG == 11) {
    			memset(&charset[cs_num * 0x800 + charpos * 8], 0xffffffff, 8);
    		} else {
    			memset(&charset[cs_num * 0x800 + charpos * 8], 0, 8);
    		}
    		charpos++;
                //reset x position so that we redo line on next charset
                bx = -8;
            } else {
                //add block to charset
                if (temp == charpos) {
                    memcpy(&charset[cs_num * 0x800 + charpos * 8], &block[0], 8);
                    charpos++;
                }
            }
            //if(charpos == 1) {
            //    memset(&charset[cs_num * 0x800 + charpos * 8], 0xff, 8);
            //    charpos++;
            //}

        }
    }
    gprintf("first unused char: %d\n", charpos);
    #if 0
    fw = fopen("charset.bin", "wb");
    fwrite(&charset[0],1,0x9000,fw);
    fclose(fw);

    fw = fopen("colormap.bin", "wb");
    fwrite(&colormap[0],1,w_blocks * h_blocks,fw);
    fclose(fw);

    fw = fopen("charmap.bin", "wb");
    fwrite(&charmap[0],1,w_blocks * h_blocks,fw);
    fclose(fw);
    #endif
    return 0;
}

static int find_char(uint8_t* charset, uint8_t* block, int pos)
{
    int res = 0;
    int y;

    //no identic char found, return
    if (res == pos) return res;
    for (y = 0; y < 8; y++) {
        if (charset[res * 8 + y] != block[y]) {
            //advance to next char
            y = -1; res++;
            //no identic char found, return
            if (res == pos) return res;
        }
    }
    return res;
}

static int is_hires(int bx, int by) {
    int x, y;
    for (y = 0; y < 8; y++) {
        for (x = 0; x < 8; x+=2) {
            if (get_pixel(bx + x, by + y) != get_pixel(bx + x, by + y)) return 1;
        }
    }
    return 0;
}

static SDL_Surface *load_image(const char *filename)
{
	SDL_Surface *temp;
	SDL_Surface *return_val;
	temp = IMG_Load(filename);
	if (!temp) {
		return NULL;
	}
	return_val = SDL_DisplayFormatAlpha(temp);
	SDL_FreeSurface(temp);
	return return_val;
}

static Uint32 timer_callback(Uint32 interval, void *param)
{
	SDL_Event event;
	SDL_UserEvent userevent;
	userevent.type = SDL_USEREVENT;
	userevent.code = 0;
	userevent.data1 = NULL;
	userevent.data2 = NULL;
	event.type = SDL_USEREVENT;
	event.user = userevent;
	SDL_PushEvent(&event);
	return (interval);
}

static int clash_print = 1;

static void paint_box(Boxes *b)
{
	int xl,yl,xh,yh;
	int i;
	xl = b->x * 8 *2;
	xh = b->x2 * 8 * 2 + 15;
	yl = b->y * 8 *2;
	yh = b->y2 * 8 * 2 + 15;
	for(i=xl; i <= xh; ++i) {
		set_pixel_rgb(mainscreen, i, yl, 0xff,0xff,0xff);		
		set_pixel_rgb(mainscreen, i, yh, 0xff,0xff,0xff);		
	}
	for(i=yl; i <= yh; ++i) {
		set_pixel_rgb(mainscreen, xl, i, 0xff,0xff,0xff);		
		set_pixel_rgb(mainscreen, xh, i, 0xff,0xff,0xff);		
	}
}

static void paint_sprite_boxes(void)
{
	Boxes *current;
	current = sprite_boxes;
	while(current) {
		paint_box(current);
		current = current->next;
	}
}

static int check_pattern(uint8_t *ptr, uint8_t pattern)
{
	int i;
	for(i=0; i < 8; ++i) {
		if (ptr[i] != pattern) {
			break;
		}
	}
	return i==8;
}

static int complete_black(int ch, int color)
{
	
	uint8_t *ptr = charset + ch*8;
	/* test for hires */
	if (!check_pattern(ptr, 0xff)) {
			return 0;
	}
	if ((color == 0x8) || (color == 0x0)) {
		return 1;
	}
	return 0;
}

static void write_sprite_box(FILE *f, Boxes *b)
{
	int color, ch;
	int x,y;
	fprintf(f, "!byte %d, %d", b->x2 - b->x +1, b->y2 - b->y +1);
	for(x=b->x; x <= b->x2; ++x) {
		for(y=b->y; y <= b->y2; ++y) {
			if (y == b->y) {
				fprintf(f, "\n!byte ");
			} else {
				fprintf(f, ", ");
			}
			color = colormap[y * w_blocks + x];
			ch = charmap[y * w_blocks + x];
			if (!complete_black(ch, color)) {
				color |= 0xf0;
			} else {
				ch = 0;
				color = 0;
			}
			if (color) {
	    			if (color == 0xf8 && COL_BG == 11) {
	    				color = 0xfc;
	    			}
				fprintf(f, "$%02x,$%02x", color, ch);
			} else {
				fprintf(f, "$%02x", color);
			}
		}
	}
	fprintf(f, "\n");
}

static void write_sprite_boxes(FILE *f)
{
	Boxes *current;
	current = sprite_boxes;
	while(current) {
		write_sprite_box(f, current);
		current = current->next;
	}	
}

static void paint_clashes(void)
{ 
	Boxes *cl;
	int x,y;

	cl = clashes;
	while(cl) {
		for(y=0; y < 8; ++y) {
			for(x=0; x < 8; ++x) {
				switch (cl->clash) {
					case 1:
						set_pixel_rgb(mainscreen,
							(cl->x+x)*2+1, (cl->y+y)*2+1,
						 	0xff,0xff,0x00);
						break;
					case 2:
						set_pixel_rgb(mainscreen,
							(cl->x+x)*2+1, (cl->y+y)*2+1,
						 	0xff,0xff,0xff);
						break;
					case 3:
						set_pixel_rgb(mainscreen,
							(cl->x+x)*2+1, (cl->y+y)*2+1,
						 	0xff,0x00,0xff);
						break;
					case 4:
						set_pixel_rgb(mainscreen,
							(cl->x+x)*2+1, (cl->y+y)*2+1,
						 	0x00,0xff,0x00);
						break;
					default: break;
				}
			}
		}
		cl=cl->next;
	}
}

static unsigned char buffer[512/8*56];
static int buffer_index = 0;

void set_buffer_pixel(int index)
{
    if (index)
    {
        unsigned char bit = 0x80 >> (buffer_index & 7);
        int byte = buffer_index / 8;
        buffer[byte] |= bit;
    }
    ++buffer_index;
}

static void convert_bg(void)
{
        int index, x, y ;
        memset(buffer, 0, sizeof(buffer));
	for(y = 0; y < height; ++y) {
		for(x = 0; x < width; ++x) {
			index = get_pixel(x, y);
                        set_buffer_pixel(index);
		}
	}
        FILE *f = fopen("pic.raw", "wb");
        fwrite(buffer, 1, sizeof(buffer), f);
        fclose(f);
}

static void paintscreen(void)
{
	int index;
	int x,y;
	SDL_LockSurface(mainscreen);
	for(y = 0; y < height; ++y) {
		for(x = 0; x < width; ++x) {
			index = get_pixel(x, y);
			//printf("%01x", index);
			set_pixel_rgb_2x2(mainscreen, x, y, 
				palette_data[index][0],
				palette_data[index][1],
				palette_data[index][2]); 
		}
		//printf("\n");
	}
	clash_print = !clash_print;
	paint_sprite_boxes();
	if (clash_print) {
		paint_clashes();
	}
	SDL_UnlockSurface(mainscreen);
	SDL_Flip(mainscreen);
}

static void remove_markers(SDL_Surface *pic)
{
	int j,i;
	int index;
	for(j=0; j < pic->h; ++j) {
		for(i=0; i < pic->w; ++i) {
			index = get_pixel(i,j);
			if (index == 16) {
				copy_right_pixel(i,j);
				printf("left %d %d\n", i, j);
				add_left_up(i/8, j/8);
			}
			if (index == 17) {
				copy_left_pixel(i,j);
				printf("left %d %d\n", i, j);
				add_right_down(i/8, j/8);
			}
		}
		//printf("\n");
	}
}

static void find_next(int x, int y, int *dest_x, int *dest_y)
{
	Boxes *current;
	Boxes *best;
	int max_distance;
	int min_diff = 1000;
	current = right_down;
	best = NULL;
	while(current) {
		if ((current->x >= x) && (current->y >= y) && !(current->clash)) {
			max_distance = current->x - x;
			if ((current->y - y) > max_distance) {
				max_distance = current->y - y;
			}
			if (max_distance < min_diff) {
				min_diff = max_distance;
				best = current;
			}
		}
		current = current->next;	
	}
	if (!best) {
		printf("Cannot find bottom right of (%d, %d)!!!!\n", x*8, y*8);
		exit(-1);
	}
	*dest_x = best->x;
	*dest_y = best->y;
	best->clash = 1;	/* mark it as used */
}

static void calculate_boxes(void)
{
	Boxes *current;
	int dest_x, dest_y;
	current = left_up;
	while(current) {
		dest_x = 1000;
		dest_y = 1000;
		find_next(current->x, current->y, &dest_x, &dest_y);
		printf("%d %d -> %d %d\n", current->x, current->y, dest_x, dest_y);
		add_sprite_box(current->x, current->y, dest_x, dest_y);
		current = current->next;
	}
}

int main(int argc, char **argv)
{
	SDL_Surface *pic;
	FILE *f;
	
	if (argc < 2) {
		printf("usage : %s <picture> [bg [mc1 [mc2 [data_file [charsetname]]]]]\n", argv[0]);
	}
	if (argc >= 3) {
		COL_BG = atoi(argv[2]);
	}
	if (argc >= 4) {
		COL_MC1 = atoi(argv[3]);
	}
	if (argc >= 5) {
		COL_MC2 = atoi(argv[4]);
	}
	if (argc >= 8 ) {
		switch_line= atoi(argv[7]);
	}
	SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);
	init_y_u_v();
	f = fopen("c64chars", "rb");
	if (!f) {
		printf("cannot open c64chars\n");
		exit(-1);
	}
	fread(charset_c64, sizeof(charset_c64), 1, f);
	fclose(f);
	mainscreen = SDL_SetVideoMode(320,56, 32, 
			SDL_DOUBLEBUF | SDL_HWSURFACE);
	if (argc < 2) {
		pic = load_image("pic.png");
	} else {
		pic = load_image(argv[1]);
	}
	if (!pic) {
		printf("load failed\n");
		return -1;
	}
	if (pic->format->BitsPerPixel < 15) {
		printf("wrong format\n");
		return -1;
	}
	SDL_FreeSurface(mainscreen);
	mainscreen = SDL_SetVideoMode(pic->w*2, (pic->h*2), 32, 
			SDL_DOUBLEBUF | SDL_HWSURFACE);
	width = pic->w;
	height = pic->h;
	pitch = pic->pitch;
	pixels = (uint32_t*)(pic->pixels);
	format = pic->format;
    #if 0
	y_pos_to_print = (pic->h*2)+8;
	x_pos_to_print = 8;
	//printf("screen bits per pixel : %d\n",
		//mainscreen->format->BitsPerPixel);
	remove_markers(pic);
	convert();
	calculate_boxes();
	if (argc >= 6) {
		FILE *f;
		f = fopen(argv[5], "w");
		if (!f) {
			printf("cannot open \"%s\"\n", argv[5]);
			exit(-1);
		}
		write_sprite_boxes(f);
		fclose(f);
	} else {
		write_sprite_boxes(stdout);
	}
	if (argc >= 7 ) {
		FILE *f;
		f = fopen(argv[6], "w");
		if (!f) {
			printf("cannot open \"%s\"\n", argv[6]);
			exit(-1);
		}
    		fwrite(&charset[0],1,(cs_num+1) * 0x800,f);
		fclose(f);
	}
	SDL_AddTimer(500, timer_callback, NULL);
    #endif
        convert_bg();
	paintscreen();
	if (argc >= 9 ) {
		SDL_Quit();
		return 0;
	}
	for (;;) {
		SDL_Event event;
		if (SDL_WaitEvent(&event)) {
			if (event.type == SDL_QUIT || event.type == SDL_KEYDOWN) {
				exit(0);
			}
			if (event.type == SDL_USEREVENT) {
				paintscreen();
			}
		}
	}
	SDL_Quit();
	return 0;
}
