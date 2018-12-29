/*
 * Irresistible Gaming (c) 2018
 * Developed by Simon, edited by Lorenc
 * Module: colours.inc
 * Purpose: colors and its functions
 */

/* ** Colours ** */
#define COL_GREEN               	"{6EF83C}"
#define COL_LGREEN               	"{91FA6B}"
#define COL_RED                 	"{F81414}"
#define COL_BLUE		           	"{00C0FF}"
#define COL_LRED                	"{FFA1A1}"
#define COL_GOLD                	"{FFDC2E}"
#define COL_PLATINUM                "{E0E0E0}"
#define COL_DIAMOND                	"{4EE2EC}"
#define COL_GREY                    "{C0C0C0}"
#define COL_PINK                    "{FF0770}"
#define COL_PURPLE 					"{885EAD}"
#define COL_WHITE                   "{FFFFFF}"
#define COL_ORANGE                  "{FF7500}"
#define COL_GANG                    "{009999}"
#define COL_YELLOW                  "{FFFF00}"
#define COL_BLACK					"{333333}"
#define COL_BRONZE 					"{CD7F32}"
#define COL_FIREMAN 				"{A83434}"
#define COLOR_RDMZONES 				0x00CC0010
#define COLOR_GREEN             	0x00CC00FF
#define COLOR_RED               	0xFF0000FF
#define COLOR_BLUE                  0x00C0FFFF
#define COLOR_YELLOW            	0xFFFF00FF
#define COLOR_ORANGE            	0xEE9911FF
#define COLOR_POLICE              	0x3E7EFF70
#define COLOR_GREY                  0xC0C0C0FF
#define COLOR_WHITE                 0xFFFFFFFF
#define COLOR_PINK                  0xFF0770FF
#define COLOR_GOLD                  0xFFDC2EFF
#define COLOR_DEFAULT               0xFFFFFF70
#define COLOR_WANTED2               0xFFEC41E2
#define COLOR_WANTED6               0xFF9233FF
#define COLOR_WANTED12              0xF83245FF
#define COLOR_FBI                   0x0035FF70
#define COLOR_ARMY                  0x954BFF70
#define COLOR_CIA                   0x19197000
#define COLOR_FIREMAN               0xA8343470
#define COLOR_MEDIC                 0x00FF8070
#define COLOR_CONNECT				0x22BB22AA
#define COLOR_DISCONNECT			0xC0C0C0AA
#define COLOR_TIMEOUT				0x990099AA
#define COLOR_KICK					0xFFCC00AA

/* ** Functions ** */
stock setRed( color, red ) // Set the red intensity on a colour.
{
	if ( red > 0xFF )
	    red	= 0xFF;
	else if ( red < 0x00 )
	    red	= 0x00;

	return ( color & 0x00FFFFFF ) | ( red << 24 );
}

stock setGreen( color, green ) // Set the green intensity on a colour.
{
	if ( green > 0xFF )
	    green	= 0xFF;
	else if ( green < 0x00 )
	    green	= 0x00;

	return ( color & 0xFF00FFFF ) | ( green << 16 );
}

stock setBlue( color, blue ) // Set the blue intensity on a colour.
{
	if ( blue > 0xFF )
	    blue	= 0xFF;
	else if ( blue < 0x00 )
	    blue	= 0x00;

	return ( color & 0xFFFF00FF ) | ( blue << 8 );
}

stock setAlpha( color, alpha ) // Set the alpha intensity on a colour.
{
	if ( alpha > 0xFF )
	    alpha	= 0xFF;
	else if ( alpha < 0x00 )
	    alpha	= 0x00;

	return ( color & 0xFFFFFF00 ) | alpha;
}

stock stripRed( color ) // Remove all red from a colour.
	return ( color ) & 0x00FFFFFF;

stock stripGreen( color ) // Remove all green from a colour.
	return ( color ) & 0xFF00FFFF;

stock stripBlue( color ) // Remove all blue from a colour.
	return ( color ) & 0xFFFF00FF;

stock stripAlpha( color ) // Remove all alpha from a colour.
	return ( color ) & 0xFFFFFF00;

stock fillRed( color ) // Fill all red in a colour.
	return ( color ) | 0xFF000000;

stock fillGreen( color ) // Fill all green in a colour.
	return ( color ) | 0x00FF0000;

stock fillBlue( color ) // Fill all blue in a colour.
	return ( color ) | 0x0000FF00;

stock fillAlpha( color ) // Fill all alpha in a colour.
	return ( color ) | 0x000000FF;

stock getRed( color ) // Get the intensity of red in a colour.
	return ( color >> 24 ) & 0x000000FF;

stock getGreen( color ) // Get the intensity of green in a colour.
	return ( color >> 16 ) & 0x000000FF;

stock getBlue( color ) // Get the intensity of blue in a colour.
	return ( color >> 8 ) & 0x000000FF;

stock getAlpha( color ) // Get the intensity of alpha in a colour.
	return ( color ) & 0x000000FF;

stock makeColor( red=0, green=0, blue=0, alpha=0 ) // Make a colour with the specified intensities.
	return ( setAlpha( setBlue( setGreen( setRed( 0x00000000, red ), green ), blue ), alpha ) );

stock setColor( color, red = -1, green = -1, blue = -1, alpha = -1 ) // Set the properties of a colour.
{
	if ( red != -1 )
	    color = setRed    ( color, red );
	if ( green != -1 )
	    color = setGreen  ( color, green );
	if ( blue != -1 )
	    color = setBlue   ( color, blue );
	if ( alpha != -1 )
	    color = setAlpha  ( color, alpha );

	return color;
}
