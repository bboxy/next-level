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

#define DEFAULT_BG 7

static int get_pixel(int x, int y)
{
	uint32_t *addr;
	uint32_t data;
	unsigned char r;
	unsigned char g;
	unsigned char b;
	if (x < 0) {
		return DEFAULT_BG;
	}
	if (x > width) {
		return DEFAULT_BG;
	}
	if (y < 0) {
		return DEFAULT_BG;
	}
	if (y > height) {
		return DEFAULT_BG;
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

static unsigned char *buffer = NULL;
static int buffer_index = 0;


static void stripe(SDL_Surface *pic, int x, int y_s, int y_e, int no_change)
{
    int y, index, i, pixel;
    buffer_index = 0;
    for(y=y_s; y < y_e; ++y)
    {
        unsigned char byte;
        for(i=0; i < 8; i+=2)
        {
	    index = get_pixel(x+i, y);
            switch(index)
            {
                case 3 :
                case 7 : pixel = 0; break;
                case 5 :
                case 1 : pixel = 1; break;
                case 0 : pixel = 2; break;
                case 10 : pixel = 3; break;
                case 11 : pixel = 3; break;
                default : printf("wrong pixel %d\n", index); exit(-1);
            }
            byte = (byte << 2) | pixel;
            if (no_change != 0)
            {
                set_pixel_rgb(pic, x+i, y, 
                        0xff-palette_data[index][0],
                        0xff-palette_data[index][1],
                        0xff-palette_data[index][2]);
                set_pixel_rgb(pic, x+i+1, y, 
                        0xff-palette_data[index][0],
                        0xff-palette_data[index][1],
                        0xff-palette_data[index][2]);
            }
        }
        buffer[buffer_index++] = byte;
    }
}

static void stripe_bonsai(SDL_Surface *pic, int x, int y_s, int y_e)
{
    int y, index, i, pixel;
    buffer_index = 0;
    for(y=y_s; y < y_e; ++y)
    {
        unsigned char byte;
        for(i=0; i < 8; i+=2)
        {
	    index = get_pixel(x+i, y);
            switch(index)
            {
                case 7 : pixel = 1; break;
                default : pixel = 0; break; 
            }
            byte = (byte << 2) | pixel;
            set_pixel_rgb(pic, x+i, y, 
                    0xff-palette_data[index][0],
                    0xff-palette_data[index][1],
                    0xff-palette_data[index][2]);
            set_pixel_rgb(pic, x+i+1, y, 
                    0xff-palette_data[index][0],
                    0xff-palette_data[index][1],
                    0xff-palette_data[index][2]);
        }
        buffer[buffer_index++] = byte;
    }
}

static void convert_bg(SDL_Surface *pic, int x_s, int y_s, int w, int h, char *outfile)
{
        if (w & 7)
        {
            printf("error w\n");
            exit(-1);
        }
        buffer = (char *)malloc(height);
        int x;
        memset(buffer, 0, height);
        FILE *f = fopen(outfile, "wb");
        printf("w = %d\n", w);
        if (strcmp("fuck", outfile) != 0)
        {
            buffer[0] = w/8;
        }
        else
        {
            buffer[0] = w/4;
        }
        buffer[1] = h;
        fwrite(buffer, 1, 2, f);
	for(x = x_s; x < x_s + w; x+=8) {
                stripe(pic, x, y_s, y_s+h, strcmp("fuck", outfile) != 0);
                fwrite(buffer, 1, h, f);
	}
        if (strcmp("fuck", outfile) == 0)
        {
	    for(x = x_s; x < x_s + w; x+=8) {
                    stripe_bonsai(pic, x, y_s, y_s+h);
                    fwrite(buffer, 1, h, f);
	    }
        }
        fclose(f);
        free(buffer);
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
	SDL_UnlockSurface(mainscreen);
	SDL_Flip(mainscreen);
}

void main_loop(char *file, int x, int y, int w, int h, char *outfile)
{
	SDL_Surface *pic;
	FILE *f;
	
	pic = load_image(file);
	if (!pic) {
		printf("load failed\n");
		exit(-1);
	}
	if (pic->format->BitsPerPixel < 15) {
		printf("wrong format\n");
		exit(-1);
	}
	SDL_FreeSurface(mainscreen);
	mainscreen = SDL_SetVideoMode(pic->w*2, (pic->h*2), 32, 
			SDL_DOUBLEBUF | SDL_HWSURFACE);
	width = pic->w;
	height = pic->h;
	pitch = pic->pitch;
	pixels = (uint32_t*)(pic->pixels);
	format = pic->format;
        convert_bg(pic, x, y, w, h, outfile);
	paintscreen();
	for (;;) {
		SDL_Event event;
		if (SDL_WaitEvent(&event)) {
			if (event.type == SDL_QUIT || event.type == SDL_KEYDOWN) {
				return;
			}
			if (event.type == SDL_USEREVENT) {
				paintscreen();
			}
		}
	}
}

int main(int argc, char **argv)
{
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);
    init_y_u_v();
    mainscreen = SDL_SetVideoMode(320,56, 32, 
			SDL_DOUBLEBUF | SDL_HWSURFACE);
    main_loop("gfx/Size_v_004.png", 0, 2, 136, 137, "spr_size");  // size
    main_loop("gfx/Matters_v_005.png", 138, 29, 184, 105, "spr_matters");    //matters
    main_loop("gfx/next_level.png", 2, 45, 152, 92, "spr_next");  // next
    main_loop("gfx/next_level.png", 156, 44, 168, 110, "spr_level");   // level
    main_loop("gfx/per_form_v001.png", 0, 0, 80, 54, "spr_per");   // per
    main_loop("gfx/per_form_v001.png", 82, 61, 136, 118, "spr_form");   // form
    main_loop("gfx/ers_v001.png", 216, 38, 104, 123, "spr_ers");   // ers
    main_loop("gfx/Bonsaitree.png", 24, 8, 56, 24, "spr_bonsai");   // bonsai
    SDL_Quit();
    return 0;
}
