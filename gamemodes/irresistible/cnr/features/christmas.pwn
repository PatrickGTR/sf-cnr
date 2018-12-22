/*
 * Irresistible Gaming (c) 2018
 * Developed by SA-MP Team, Lorenc
 * Module: cnr\features\christmas.pwn
 * Purpose: official SF-CNR christmas in-game implementation
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Easter Egg Implementation ** */
#if !defined __cnr__eastereggs
	#tryinclude "irresistible\cnr\features\eastereggs.pwn"
#endif

#if defined EASTEREGG_LABEL
	#undef EASTEREGG_LABEL
	#define EASTEREGG_LABEL 		"[XMAS BOX]"
#endif

#if defined EASTEREGG_NAME
	#undef EASTEREGG_NAME
	#define EASTEREGG_NAME 			"Xmas Box"
#endif

#if defined EASTEREGG_MODEL
	#undef EASTEREGG_MODEL
	#define EASTEREGG_MODEL 		randarg( 19054, 19055, 19056, 19057, 19058 )
#endif

/* ** Definitions ** */
#define NUM_FERRIS_CAGES        	10
#define FERRIS_WHEEL_ID         	18877
#define FERRIS_CAGE_ID          	18879
#define FERRIS_BASE_ID         		18878
#define FERRIS_DRAW_DISTANCE    	300.0
#define FERRIS_WHEEL_SPEED      	0.01
#define FERRIS_WHEEL_Z_ANGLE  		-90.0

/* ** Variables ** */
static stock Float: gFerrisOrigin[ 3 ] = { -1980.192138, 884.195495, 59.326107 };
static stock Float: gFerrisCageOffsets[ NUM_FERRIS_CAGES ] [ 3 ] = {
	{ 0.0699, 0.0600, -11.7500 },
	{ -6.9100, -0.0899, -9.5000 },
	{ 11.1600, 0.0000, -3.6300 },
	{ -11.1600, -0.0399, 3.6499 },
	{ -6.9100, -0.0899, 9.4799 },
	{ 0.0699, 0.0600, 11.7500 },
	{ 6.9599, 0.0100, -9.5000 },
	{ -11.1600, -0.0399, -3.6300 },
	{ 11.1600, 0.0000, 3.6499 },
	{ 7.0399, -0.0200, 9.3600 }
};
static stock gFerrisWheel;
static stock gFerrisBase;
static stock gFerrisCages[ NUM_FERRIS_CAGES ];
static stock Float: gCurrentTargetYAngle = 0.0;
static stock gWheelTransAlternate = 0;
static stock Text: g_ChristmasTD[ 6 ];

/* ** Hooks ** */
hook OnScriptInit( ) {
	// Christmas Textdraws
	XMAS_InitializeTextdraws( );
	XMAS_InitializeObjects( );

	// Create Ferris Wheel
	gFerrisWheel = CreateObject( FERRIS_WHEEL_ID, gFerrisOrigin[0], gFerrisOrigin[1], gFerrisOrigin[2], 0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, FERRIS_DRAW_DISTANCE );
    gFerrisBase = CreateObject( FERRIS_BASE_ID, gFerrisOrigin[0], gFerrisOrigin[1], gFerrisOrigin[2], 0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, FERRIS_DRAW_DISTANCE );

	new
		x = 0;

	while ( x != NUM_FERRIS_CAGES ) {
        gFerrisCages[x] = CreateObject( FERRIS_CAGE_ID, gFerrisOrigin[0], gFerrisOrigin[1], gFerrisOrigin[2], 0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, FERRIS_DRAW_DISTANCE );
        AttachObjectToObject( gFerrisCages[x], gFerrisWheel, gFerrisCageOffsets[x][0], gFerrisCageOffsets[x][1], gFerrisCageOffsets[x][2], 0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, 0 );
		x ++;
	}

	SetTimer( "XMAS_RotateWheel", 3 * 1000, 0 );
	return 1;
}

hook OnPlayerConnect( playerid ) {
	XMAS_RemoveBuildings( playerid );
	return 1;
}

hook OnObjectMoved( objectid ) {
    if ( objectid == gFerrisWheel ) {
   		SetTimer( "XMAS_RotateWheel", 3 * 1000, 0 );
    }
	return 1;
}

hook OnPlayerLoadTextdraws( playerid ) {
	for ( new i = 0; i < sizeof ( g_ChristmasTD ); i ++ ) {
		TextDrawShowForPlayer( playerid, g_ChristmasTD[ i ] );
	}
	return 1;
}

hook OnPlayerUnloadTextdraws( playerid ) {
	for ( new i = 0; i < sizeof ( g_ChristmasTD ); i ++ ) {
		TextDrawHideForPlayer( playerid, g_ChristmasTD[ i ] );
	}
	return 1;
}

/* ** Functions ** */
static stock UpdateWheelTarget( ) {
    if ( ( gCurrentTargetYAngle += 36.0 ) >= 360.0) {  // There are 10 carts, so 360 / 10
		gCurrentTargetYAngle = 0.0;
    }
	gWheelTransAlternate = ! gWheelTransAlternate;
}

function XMAS_RotateWheel( ) {
    new
    	Float: fModifyWheelZPos = 0.0;

    UpdateWheelTarget( );

    if ( gWheelTransAlternate )
    	fModifyWheelZPos = 0.05;

    MoveObject( gFerrisWheel, gFerrisOrigin[ 0 ], gFerrisOrigin[ 1 ], gFerrisOrigin[ 2 ] + fModifyWheelZPos, FERRIS_WHEEL_SPEED, 0.0, gCurrentTargetYAngle, FERRIS_WHEEL_Z_ANGLE );
}

static stock XMAS_InitializeTextdraws( ) {
	// recreate current coin textdraw so it overlaps xmas (1)
	if ( g_CurrentCoinsTD != Text: INVALID_TEXT_DRAW ) {
		TextDrawDestroy( g_CurrentCoinsTD );
		g_CurrentCoinsTD = Text: INVALID_TEXT_DRAW;
	}

	// begin xmas textdraws
	g_ChristmasTD[ 0 ] = TextDrawCreate(527.000000, 360.000000, "box");
	TextDrawBackgroundColor(g_ChristmasTD[ 0 ], 0);
	TextDrawFont(g_ChristmasTD[ 0 ], 5);
	TextDrawLetterSize(g_ChristmasTD[ 0 ], 0.500000, 1.000000);
	TextDrawColor(g_ChristmasTD[ 0 ], -1);
	TextDrawSetOutline(g_ChristmasTD[ 0 ], 0);
	TextDrawSetProportional(g_ChristmasTD[ 0 ], 1);
	TextDrawSetShadow(g_ChristmasTD[ 0 ], 1);
	TextDrawUseBox(g_ChristmasTD[ 0 ], 1);
	TextDrawBoxColor(g_ChristmasTD[ 0 ], 255);
	TextDrawTextSize(g_ChristmasTD[ 0 ], 15.000000, 19.000000);
	TextDrawSetPreviewModel(g_ChristmasTD[ 0 ], 19056);
	TextDrawSetPreviewRot(g_ChristmasTD[ 0 ], 0.000000, 0.000000, -50.000000, 1.000000);
	TextDrawSetSelectable(g_ChristmasTD[ 0 ], 0);

	g_ChristmasTD[ 1 ] = TextDrawCreate(504.000000, 308.000000, "tree");
	TextDrawBackgroundColor(g_ChristmasTD[ 1 ], 0);
	TextDrawFont(g_ChristmasTD[ 1 ], 5);
	TextDrawLetterSize(g_ChristmasTD[ 1 ], 0.449999, 1.000000);
	TextDrawColor(g_ChristmasTD[ 1 ], -1);
	TextDrawSetOutline(g_ChristmasTD[ 1 ], 0);
	TextDrawSetProportional(g_ChristmasTD[ 1 ], 1);
	TextDrawSetShadow(g_ChristmasTD[ 1 ], 1);
	TextDrawUseBox(g_ChristmasTD[ 1 ], 1);
	TextDrawBoxColor(g_ChristmasTD[ 1 ], 255);
	TextDrawTextSize(g_ChristmasTD[ 1 ], 75.000000, 80.000000);
	TextDrawSetPreviewModel(g_ChristmasTD[ 1 ], 19076);
	TextDrawSetPreviewRot(g_ChristmasTD[ 1 ], 0.000000, 0.000000, 0.000000, 1.000000);
	TextDrawSetSelectable(g_ChristmasTD[ 1 ], 0);

	g_ChristmasTD[ 2 ] = TextDrawCreate(541.000000, 360.000000, "box");
	TextDrawBackgroundColor(g_ChristmasTD[ 2 ], 0);
	TextDrawFont(g_ChristmasTD[ 2 ], 5);
	TextDrawLetterSize(g_ChristmasTD[ 2 ], 0.500000, 1.000000);
	TextDrawColor(g_ChristmasTD[ 2 ], -1);
	TextDrawSetOutline(g_ChristmasTD[ 2 ], 0);
	TextDrawSetProportional(g_ChristmasTD[ 2 ], 1);
	TextDrawSetShadow(g_ChristmasTD[ 2 ], 1);
	TextDrawUseBox(g_ChristmasTD[ 2 ], 1);
	TextDrawBoxColor(g_ChristmasTD[ 2 ], 255);
	TextDrawTextSize(g_ChristmasTD[ 2 ], 15.000000, 19.000000);
	TextDrawSetPreviewModel(g_ChristmasTD[ 2 ], 19057);
	TextDrawSetPreviewRot(g_ChristmasTD[ 2 ], 0.000000, 0.000000, -50.000000, 1.000000);
	TextDrawSetSelectable(g_ChristmasTD[ 2 ], 0);

	g_ChristmasTD[ 3 ] = TextDrawCreate(527.000000, 316.000000, "    ~n~  .  .    .      . ~n~ .   .   .    . .  .~n~  .  .    . ~n~ .   . .    .     . ~n~    .    .    .  . ~n~ .  .   ");
	TextDrawBackgroundColor(g_ChristmasTD[ 3 ], 0);
	TextDrawFont(g_ChristmasTD[ 3 ], 1);
	TextDrawLetterSize(g_ChristmasTD[ 3 ], 0.250000, 1.099998);
	TextDrawColor(g_ChristmasTD[ 3 ], -1);
	TextDrawSetOutline(g_ChristmasTD[ 3 ], 0);
	TextDrawSetProportional(g_ChristmasTD[ 3 ], 1);
	TextDrawSetShadow(g_ChristmasTD[ 3 ], 1);
	TextDrawSetSelectable(g_ChristmasTD[ 3 ], 0);

	g_ChristmasTD[ 4 ] = TextDrawCreate(537.000000, 311.000000, "    ~n~  .  .    .      . ~n~ .   .   .    . .  .~n~  .  .    . ~n~ .   . .    .     . ~n~    .    .    .  . ~n~ .  .   ");
	TextDrawBackgroundColor(g_ChristmasTD[ 4 ], 0);
	TextDrawFont(g_ChristmasTD[ 4 ], 1);
	TextDrawLetterSize(g_ChristmasTD[ 4 ], 0.250000, 1.099998);
	TextDrawColor(g_ChristmasTD[ 4 ], -1);
	TextDrawSetOutline(g_ChristmasTD[ 4 ], 0);
	TextDrawSetProportional(g_ChristmasTD[ 4 ], 1);
	TextDrawSetShadow(g_ChristmasTD[ 4 ], 1);
	TextDrawSetSelectable(g_ChristmasTD[ 4 ], 0);

	g_ChristmasTD[ 5 ] = TextDrawCreate(552.000000, 324.000000, "~r~M~g~e~r~r~g~r~r~y~n~____~g~C~r~h~g~r~r~i~g~s~r~t~g~m~r~a~g~s");
	TextDrawBackgroundColor(g_ChristmasTD[ 5 ], 255);
	TextDrawFont(g_ChristmasTD[ 5 ], 3);
	TextDrawLetterSize(g_ChristmasTD[ 5 ], 0.250000, 1.200000);
	TextDrawColor(g_ChristmasTD[ 5 ], -1);
	TextDrawSetOutline(g_ChristmasTD[ 5 ], 1);
	TextDrawSetProportional(g_ChristmasTD[ 5 ], 1);
	TextDrawSetSelectable(g_ChristmasTD[ 5 ], 0);

	// recreate current coin textdraw so it overlaps xmas (2)
	if ( g_CurrentCoinsTD == Text: INVALID_TEXT_DRAW ) {
		g_CurrentCoinsTD = TextDrawCreate(529.000000, 348.000000, "Total Coins");
		TextDrawBackgroundColor(g_CurrentCoinsTD, 255);
		TextDrawFont(g_CurrentCoinsTD, 3);
		TextDrawLetterSize(g_CurrentCoinsTD, 0.230000, 1.000000);
		TextDrawColor(g_CurrentCoinsTD, -1);
		TextDrawSetOutline(g_CurrentCoinsTD, 1);
		TextDrawSetProportional(g_CurrentCoinsTD, 1);
	}
}

static stock XMAS_InitializeObjects( ) {
	CreateDynamicObject( 19055, -1990.166992, 864.238342, 46.277915, 0.000000, 0.000000, 20.900016, -1, -1, -1 );
	CreateDynamicObject( 19054, -1990.166992, 865.756652, 46.277915, 0.000000, 0.000000, -36.999988, -1, -1, -1 );
	CreateDynamicObject( 19056, -1990.170898, 902.708251, 46.283397, 0.000000, 0.000000, -6.500008, -1, -1, -1 );
	CreateDynamicObject( 19057, -1990.170898, 904.158630, 46.283397, 0.000000, 0.000000, 33.200038, -1, -1, -1 );
	CreateDynamicObject( 19076, -1960.199951, 883.420837, 40.779701, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19054, -1913.123413, 903.901245, 37.067810, 0.000000, 0.000000, -26.700006, -1, -1, -1 );
	CreateDynamicObject( 19055, -1913.123413, 901.710388, 37.067810, 0.000000, 0.000000, 83.599983, -1, -1, -1 );
	CreateDynamicObject( 19054, -1913.123413, 899.559997, 37.067810, 0.000000, 0.000000, 33.599998, -1, -1, -1 );
	CreateDynamicObject( 19055, -1913.123413, 897.318847, 37.067810, 0.000000, 0.000000, -113.499992, -1, -1, -1 );
	CreateDynamicObject( 19054, -1913.123413, 895.288757, 37.067810, 0.000000, 0.000000, 47.499992, -1, -1, -1 );
	CreateDynamicObject( 19054, -1913.123413, 871.685729, 37.067810, 0.000000, 0.000000, -163.199996, -1, -1, -1 );
	CreateDynamicObject( 19057, -1913.123413, 869.714904, 37.067810, 0.000000, 0.000000, -138.599990, -1, -1, -1 );
	CreateDynamicObject( 19054, -1913.123413, 867.794372, 37.067810, 0.000000, 0.000000, 172.199996, -1, -1, -1 );
	CreateDynamicObject( 19057, -1913.123413, 865.902648, 37.067810, 0.000000, 0.000000, -31.699998, -1, -1, -1 );
	CreateDynamicObject( 19054, -1913.123413, 864.141967, 37.067810, 0.000000, 0.000000, 20.999998, -1, -1, -1 );
	CreateDynamicObject( 14781, -1923.749633, 883.934326, 37.555038, 180.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19362, -1924.662963, 885.004394, 38.564865, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	CreateDynamicObject( 14781, -1923.749633, 882.993408, 35.545097, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1914.621948, 893.343383, 34.945636, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1914.621948, 889.172058, 34.945636, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19054, -1960.196777, 884.483337, 41.419750, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19054, -1960.196777, 882.332214, 41.419750, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19054, -1958.985595, 883.352722, 41.419750, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19054, -1961.407226, 883.352722, 41.419750, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19055, -1961.598388, 884.766845, 41.419750, 0.000000, 0.000000, 45.000000, -1, -1, -1 );
	CreateDynamicObject( 19055, -1958.761352, 881.929992, 41.419750, 0.000000, 0.000000, 45.000000, -1, -1, -1 );
	CreateDynamicObject( 19055, -1958.740966, 884.781005, 41.419750, 0.000000, 0.000000, 45.000000, -1, -1, -1 );
	CreateDynamicObject( 19055, -1961.627685, 881.909240, 41.419750, 0.000000, 0.000000, 45.000000, -1, -1, -1 );
	CreateDynamicObject( 19056, -1960.196777, 881.021911, 40.939743, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19056, -1960.196777, 885.773681, 40.939743, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19056, -1957.674804, 883.353637, 40.939743, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19056, -1962.748168, 883.353637, 40.939743, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1368, -1960.212036, 892.285949, 41.799720, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1368, -1960.212036, 874.533325, 41.799720, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1368, -1941.692138, 887.039489, 38.207855, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1368, -1941.692138, 879.719299, 38.207855, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1368, -1945.309936, 883.423828, 38.197319, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 1368, -1930.977539, 880.215209, 35.105972, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1368, -1930.977539, 886.997497, 35.105972, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1914.621948, 873.447204, 34.945636, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1914.621948, 877.618530, 34.945636, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19056, -1914.580932, 880.313171, 34.971942, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19056, -1914.580932, 886.454772, 34.971942, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19058, -1991.090332, 887.821411, 44.806953, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19058, -1991.090332, 880.550292, 44.806953, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1442, -1915.238281, 864.467773, 35.014106, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1442, -1915.238281, 903.890075, 35.014106, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1442, -1988.080688, 864.217590, 44.803161, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1442, -1988.080688, 904.078918, 44.803161, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19632, -1988.073730, 904.090698, 44.919692, 0.000000, 0.000000, 10.800002, -1, -1, -1 );
	CreateDynamicObject( 19632, -1988.058227, 864.234619, 44.923168, 0.000000, 0.000000, 57.100028, -1, -1, -1 );
	CreateDynamicObject( 19632, -1915.236572, 864.451171, 35.034103, 0.000000, 0.000000, -82.799964, -1, -1, -1 );
	CreateDynamicObject( 19632, -1915.260009, 903.911315, 35.044105, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1968.948730, 896.733276, 44.753192, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1968.948730, 892.563598, 44.753192, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1968.948730, 888.393005, 44.753192, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1968.948730, 884.223327, 44.753192, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1968.948730, 880.053405, 44.753192, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1968.948730, 875.880737, 44.753192, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1968.948730, 871.709899, 44.753192, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1951.933593, 872.124633, 41.649730, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1951.933593, 876.295043, 41.649730, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1951.933593, 880.466003, 41.649730, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1951.933593, 883.704345, 41.649730, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1951.933593, 896.217712, 41.649730, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1951.933593, 892.047058, 41.649730, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1951.933593, 887.876403, 41.649730, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1931.757934, 896.624206, 38.037651, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1931.757934, 892.452636, 38.037651, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1931.757934, 888.279968, 38.037651, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1931.757934, 884.109680, 38.037651, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1931.757934, 879.938720, 38.037651, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1931.757934, 875.768249, 38.037651, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1931.757934, 871.595153, 38.037651, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1991.081787, 869.517211, 45.103157, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1991.081787, 873.688171, 45.103157, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1991.081787, 877.858886, 45.103157, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1991.081787, 898.840332, 45.103157, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1991.081787, 894.669311, 45.103157, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1991.081787, 890.498535, 45.103157, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1986.537719, 905.283508, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1982.366088, 905.283508, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1978.193847, 905.283508, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1974.023315, 905.283508, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1969.861816, 905.283508, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19054, -1968.207763, 905.295349, 45.203125, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19054, -1968.207763, 863.075866, 45.203125, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1965.819946, 905.283508, 44.639053, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1961.714355, 905.283508, 43.900638, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1957.607666, 905.283508, 43.162265, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1953.503417, 905.283508, 42.423858, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1949.398071, 905.283508, 41.685455, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1945.291748, 905.283508, 40.947078, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1941.185913, 905.283508, 40.208671, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1937.080932, 905.283508, 39.470226, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1932.975097, 905.283508, 38.731807, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1928.869506, 905.283508, 37.993415, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1924.765136, 905.283508, 37.254966, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1920.660644, 905.283508, 36.516548, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1916.555541, 905.283508, 35.778156, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1965.819946, 863.071472, 44.639053, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1961.715820, 863.071472, 43.900600, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1957.610473, 863.071472, 43.162178, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1953.506347, 863.071472, 42.423713, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1949.400512, 863.071472, 41.685306, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1945.296264, 863.071472, 40.946849, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1941.191040, 863.071472, 40.208423, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1937.085205, 863.071472, 39.470031, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1932.979003, 863.071472, 38.731658, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1928.872558, 863.071472, 37.993270, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1924.768432, 863.071472, 37.254817, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1920.662963, 863.071472, 36.516376, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1916.557495, 863.071472, 35.777973, 0.000000, 10.199996, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1969.861816, 863.081298, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1974.033569, 863.081298, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1978.204956, 863.081298, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1982.374755, 863.081298, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 970, -1986.545532, 863.081298, 45.093143, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1981.318725, 876.172485, 43.703216, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1981.302490, 892.748596, 43.713214, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1964.193603, 892.210510, 40.619171, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1964.193603, 875.377563, 40.629169, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1944.263061, 876.137756, 37.007785, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1944.263061, 893.183776, 37.027782, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1927.143920, 876.179809, 33.925994, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1927.143920, 893.216491, 33.945991, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	CreateDynamicObject( 19054, -1939.954589, 885.231994, 39.872791, 0.000000, 0.000000, 79.699996, -1, -1, -1 );
	CreateDynamicObject( 19054, -1939.954589, 881.600891, 39.872791, 0.000000, 0.000000, -108.000007, -1, -1, -1 );
	CreateDynamicObject( 19054, -1943.519165, 885.231994, 39.872791, 0.000000, 0.000000, -67.200004, -1, -1, -1 );
	CreateDynamicObject( 19054, -1943.505371, 881.600891, 39.872791, 0.000000, 0.000000, -141.799987, -1, -1, -1 );
	CreateDynamicObject( 19058, -1941.754150, 881.600891, 39.872791, 0.000000, 0.000000, 74.699996, -1, -1, -1 );
	CreateDynamicObject( 19056, -1941.706054, 885.231994, 39.872791, 0.000000, 0.000000, 170.599975, -1, -1, -1 );
	CreateDynamicObject( 19057, -1943.519165, 883.381103, 39.872791, 0.000000, 0.000000, 138.300018, -1, -1, -1 );
	CreateDynamicObject( 19055, -1939.954589, 883.370727, 39.872791, 0.000000, 0.000000, 81.799987, -1, -1, -1 );
	CreateDynamicObject( 1368, -1968.305175, 883.454528, 41.799720, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1232, -1932.382568, 869.303527, 40.457759, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1232, -1932.382568, 898.965209, 40.457759, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1232, -1952.375610, 899.008850, 44.069667, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1232, -1952.375610, 869.334289, 44.069667, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1232, -1969.552490, 869.300231, 47.162998, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1232, -1969.552490, 899.063720, 47.162998, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 673, -1932.995117, 876.320007, 37.477912, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 673, -1932.995117, 890.913452, 37.477912, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 673, -1932.995117, 883.503051, 37.477912, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 673, -1950.178710, 890.533081, 37.477912, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 673, -1950.069702, 883.562988, 37.477912, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 673, -1950.018432, 876.320007, 37.477912, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19632, -1968.157226, 870.733032, 41.849769, 0.000000, 0.000000, 32.599971, -1, -1, -1 );
	CreateDynamicObject( 1442, -1968.140625, 870.696655, 41.759723, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1442, -1968.140625, 897.419677, 41.759723, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19632, -1968.157226, 897.443725, 41.849769, 0.000000, 0.000000, 70.300056, -1, -1, -1 );
	CreateDynamicObject( 1442, -1950.745605, 870.678466, 38.087886, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19632, -1950.727783, 870.700927, 38.262760, 0.000000, 0.000000, 131.800018, -1, -1, -1 );
	CreateDynamicObject( 1442, -1950.745605, 897.410827, 38.087886, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19632, -1950.727783, 897.453674, 38.262760, 0.000000, 0.000000, 24.600015, -1, -1, -1 );
	CreateDynamicObject( 1442, -1930.942504, 871.082885, 35.034164, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1442, -1930.942504, 897.425231, 35.034164, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19632, -1930.949340, 871.114379, 35.084106, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19632, -1930.949340, 897.454650, 35.084106, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 673, -1950.069702, 876.710510, 37.477912, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19362, -1921.921875, 885.004394, 38.554866, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19362, -1924.662963, 881.963317, 38.574863, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19362, -1921.922485, 881.963317, 38.564865, 0.000000, -90.000000, 0.000000, -1, -1, -1 ), 0, 3914, "snow", "mp_snow", 0 );
}

static stock XMAS_RemoveBuildings( playerid ) {
	RemoveBuildingForPlayer( playerid, 713, -1920.1875, 882.1953, 34.1406, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1990.3359, 866.3281, 45.2422, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1990.3359, 863.8750, 45.2422, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1980.9063, 866.9375, 46.7813, 0.25 );
	RemoveBuildingForPlayer( playerid, 673, -1963.9375, 877.9766, 40.7266, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1961.0625, 875.3984, 43.6797, 0.25 );
	RemoveBuildingForPlayer( playerid, 715, -1956.3750, 877.7422, 49.0313, 0.25 );
	RemoveBuildingForPlayer( playerid, 673, -1950.0547, 876.2578, 37.2500, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1941.1875, 875.3984, 40.0469, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1928.0469, 875.3984, 37.0156, 0.25 );
	RemoveBuildingForPlayer( playerid, 673, -1926.3750, 878.5234, 34.1484, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1913.0234, 868.8125, 36.4531, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1913.0234, 864.8672, 36.4531, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1913.0234, 870.9219, 36.4531, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1961.0625, 892.7266, 43.6797, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1990.3359, 902.1250, 45.2422, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1990.3359, 904.5781, 45.2422, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1980.9063, 901.7031, 46.7813, 0.25 );
	RemoveBuildingForPlayer( playerid, 673, -1956.5703, 886.2031, 40.7891, 0.25 );
	RemoveBuildingForPlayer( playerid, 673, -1950.0547, 887.5234, 37.2500, 0.25 );
	RemoveBuildingForPlayer( playerid, 673, -1927.5313, 888.5625, 34.1484, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1928.0469, 892.7266, 37.0156, 0.25 );
	RemoveBuildingForPlayer( playerid, 1232, -1941.1875, 892.7266, 40.0469, 0.25 );
	RemoveBuildingForPlayer( playerid, 1226, -1906.7188, 893.7422, 38.1484, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1913.0234, 894.1094, 36.4531, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1913.0234, 904.5781, 36.4531, 0.25 );
	RemoveBuildingForPlayer( playerid, 649, -1913.0234, 902.4688, 36.4531, 0.25 );
}