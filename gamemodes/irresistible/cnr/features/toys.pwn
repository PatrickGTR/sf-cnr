/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\toys.pwn
 * Purpose: toy system for players (attach objects to player)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_TOYS                ( sizeof( g_ToyData ) )
#define MAX_TOY_UNLOCKS 		( 200 ) // should be ideally MAX_TOYS

#define CATEGORY_WATCHES 		( 0 )
#define CATEGORY_BERETS 		( 1 )
#define CATEGORY_HATS 			( 2 )
#define CATEGORY_HEADPHONES 	( 3 )
#define CATEGORY_MASKS 			( 4 )
#define CATEGORY_MOTORCYCLE 	( 5 )
#define CATEGORY_GUITARS		( 6 )
#define CATEGORY_GLASSES 		( 7 )
#define CATEGORY_HANDHELD 		( 8 )
#define CATEGORY_WEAPONS 		( 9 )
#define CATEGORY_MISC 			( 10 )
#define CATEGORY_VIP 			( 11 )

#define MODEL_PREVIEW_TOY 		( 15 )

/* ** Variables ** */
enum E_ATTACHED_DATA
{
	E_ENABLED, 			E_MODELID, 		E_BONE,
	Float: E_OX,		Float: E_OY, 	Float: E_OZ,
	Float: E_RX, 		Float: E_RY, 	Float: E_RZ,
	Float: E_SX, 		Float: E_SY, 	Float: E_SZ,
	E_COLOR, 			E_SQL_ID
};

enum E_TOY_DATA
{
	E_CATEGORY, 		E_ID,			E_NAME[ 24 ],
	E_MODEL, 			E_PRICE,		E_DEFAULT_BONE
};

new
	g_ToyCategory[ ] [ ] =
	{
		{ "Watches" },  { "Berets" }, { "Hats" }, { "Headphones" }, { "Masks" },
		{ "Motorcycle Helmets" }, { "Guitars" }, { "Glasses" }, { "Handheld" },
		{ "Weapons" }, { "Miscellaneous" }, { "V.I.P" }
	},
 	g_ToyData[ ] [ E_TOY_DATA ] =
	{
		// WATCHES
		{ CATEGORY_WATCHES, 0, 	"Rolex Datejust II", 		19039, 220000,	5 },
		{ CATEGORY_WATCHES, 1, 	"Rolex Datejust I", 		19042, 160000,	5 },
		{ CATEGORY_WATCHES, 2, 	"Rolex Explorer", 			19040, 140800,	5 },
		{ CATEGORY_WATCHES, 3, 	"Rolex Sky-Dweller", 	 	19041, 95000,	5 },
		{ CATEGORY_WATCHES, 4, 	"G-Shock Camo", 	 		19053, 25000,	5 },
		{ CATEGORY_WATCHES, 5, 	"G-Shock Navy Camo", 	 	19048, 20000,	5 },
		{ CATEGORY_WATCHES, 6, 	"G-Shock Pink Camo", 	 	19049, 17500,	5 },
		{ CATEGORY_WATCHES, 7, 	"G-Shock Orange Camo", 		19051, 17500,	5 },
		{ CATEGORY_WATCHES, 8, 	"G-Shock Purple", 	 		19047, 10000,	5 },
		{ CATEGORY_WATCHES, 9, 	"G-Shock Pink", 	 		19045, 10000,	5 },
		{ CATEGORY_WATCHES, 10, "G-Shock Green", 			19046, 5000,	5 },

		// BERET
		{ CATEGORY_BERETS, 11, 	"Camo Beret", 				18924, 750,		2 },
		// { CATEGORY_BERETS, 12,	"Gucci Black", 				18921, 340,		2 },
		// { CATEGORY_BERETS, 13,	"Gucci Red", 				18922, 340,		2 },
		// { CATEGORY_BERETS, 14,	"Gucci Blue", 				18923, 340,		2 },

		// HATS
		{ CATEGORY_HATS, 126,	"Witch Hat",				19528, 6666,	2 }, // special
		{ CATEGORY_HATS, 93,	"Santa Hat",				19064, 5000,	2 }, // special
		{ CATEGORY_HATS, 15,	"Gangsta Beanie", 			19067, 1300, 	2 },
		{ CATEGORY_HATS, 16,	"Snake Skin Hat", 			18973, 1000, 	2 },
		{ CATEGORY_HATS, 17,	"Tiger Print Hat", 			18970, 1000, 	2 },
		{ CATEGORY_HATS, 18,	"Skull Beanie", 			19069, 1000, 	2 },
		{ CATEGORY_HATS, 19,	"Boxing Helmet", 			18952, 900, 	2 },
		// { CATEGORY_HATS, 20,	"Knit Cap Grey", 			18954, 800, 	2 },
		// { CATEGORY_HATS, 21,	"Knit Cap Black", 			18953, 800, 	2 },
		{ CATEGORY_HATS, 22,	"Dukes Hat", 				18972, 800, 	2 },
		{ CATEGORY_HATS, 23,	"Cowboy Hat", 				18962, 800, 	2 },
		{ CATEGORY_HATS, 24,	"Trucker Cap", 				18961, 700, 	2 },
		//{ CATEGORY_HATS, 25,	"Black Bowler", 			18944, 500, 	2 },
		{ CATEGORY_HATS, 26,	"White Fedora", 			19488, 500, 	2 },
		//{ CATEGORY_HATS, 27,	"Blue Bowler", 				18945, 500, 	2 },
		{ CATEGORY_HATS, 28,	"Island Fedora", 				18946, 500, 	2 },
		{ CATEGORY_HATS, 29,	"Bloody Fedora", 				18950, 500, 	2 },
		// { CATEGORY_HATS, 30,	"Yellow Bowler", 			18951, 500, 	2 },
		{ CATEGORY_HATS, 31,	"Skater Bucket Hat", 		18968, 500, 	2 },
		//{ CATEGORY_HATS, 32,	"Fishing Cap", 				18969, 500, 	2 },
		{ CATEGORY_HATS, 33,	"Black Top Hat", 			19352, 500, 	2 },
		{ CATEGORY_HATS, 34,	"White Top Hat", 			19487, 500, 	2 },
		{ CATEGORY_HATS, 35,	"Fireman Helmet", 			19330, 400, 	2 },
		{ CATEGORY_HATS, 36,	"Sheriff Hat", 				19099, 300, 	2 },
		{ CATEGORY_HATS, 37,	"Camo Cap", 				18926, 240, 	2 },
		{ CATEGORY_HATS, 38,	"Chicken Hat",				19137, 240,		2 },
		{ CATEGORY_HATS, 39,	"BurgerShot Hat", 			19094, 240, 	2 },
		{ CATEGORY_HATS, 40,	"Police Cap", 				18636, 240, 	2 },
		{ CATEGORY_HATS, 41,	"Gas Mask",					19472, 240,		2 },

		// HEADPHONES
		{ CATEGORY_HEADPHONES, 41,	"White Beats", 			19421, 550, 	2 },
		{ CATEGORY_HEADPHONES, 42,	"Black Beats", 			19422, 550, 	2 },
		{ CATEGORY_HEADPHONES, 43,	"Red Beats", 			19423, 550, 	2 },
		{ CATEGORY_HEADPHONES, 44,	"Blue Beats", 			19424, 550, 	2 },

		// MASKS
		{ CATEGORY_MASKS, 96, 	"Gucci Balaclava",			19801, 	10000,	2 },
		{ CATEGORY_MASKS, 45,	"Black Mask",				18912, 	6000,	2 },
		{ CATEGORY_MASKS, 46,	"Green Mask",				18913, 	5200,	2 },
		{ CATEGORY_MASKS, 47,	"Weed Bandana",				18894, 	4500,	2 },
		{ CATEGORY_MASKS, 48,	"Gimp Mask",				19163, 	300,	2 },
		{ CATEGORY_MASKS, 49,	"Hockey Mask White",		19036, 	250,	2 },
		{ CATEGORY_MASKS, 50,	"Hockey Mask Red",			19037, 	250,	2 },
		{ CATEGORY_MASKS, 51,	"Blue Bandana",				18897, 	100,	2 },
		{ CATEGORY_MASKS, 53,	"Grove Mask",				18913, 	200,	2 },
		{ CATEGORY_MASKS, 54,	"Zorro Mask",				18974, 	100,	2 },

		// MOTORCYCLE HELMETS
		{ CATEGORY_MOTORCYCLE, 87, "Fire Flame Helmet",		18645, 	1000,	2 },
		{ CATEGORY_MOTORCYCLE, 88, "Blue Helmet",			18976, 	800,	2 },
		{ CATEGORY_MOTORCYCLE, 89, "Red Helmet",			18977, 	700,	2 },
		{ CATEGORY_MOTORCYCLE, 90, "White Helmet",			18978, 	700,	2 },
		{ CATEGORY_MOTORCYCLE, 91, "Pink Helmet",			18979, 	500,	2 },

		// GUITARS
		{ CATEGORY_GUITARS, 55,	"Warlock Guitar",			19319, 	1250,	1 },
		{ CATEGORY_GUITARS, 56,	"Flying Guitar",			19318, 	800,	1 },
		{ CATEGORY_GUITARS, 57,	"Bass Guitar",				19317, 	400,	1 },

		// GLASSES
		{ CATEGORY_GLASSES, 58,	"Oakley Ferrari", 			19006, 900, 	2 },
		{ CATEGORY_GLASSES, 59,	"Armani Aviator Classic", 	19022, 840, 	2 },
		// { CATEGORY_GLASSES, 61,	"Armani Aviator Blue" , 	19023, 840, 	2 },
		// { CATEGORY_GLASSES, 62,	"Armani Aviator Purple", 	19024, 840, 	2 },
		{ CATEGORY_GLASSES, 63,	"Armani Aviator Pink", 		19025, 840, 	2 },
		// { CATEGORY_GLASSES, 64,	"Armani Aviator Orange", 	19027, 840, 	2 },
		// { CATEGORY_GLASSES, 65,	"Armani Aviator Yellow", 	19028, 840, 	2 },
		// { CATEGORY_GLASSES, 65,	"Armani Aviator Green", 	19029, 840, 	2 },
		// { CATEGORY_GLASSES, 66,	"Gucci Techno Yellow" , 	19017, 650, 	2 },
		// { CATEGORY_GLASSES, 67,	"Gucci Techno Salmon" , 	19018, 650, 	2 },
		{ CATEGORY_GLASSES, 68,	"Gucci Techno Red" , 		19019, 650, 	2 },
		{ CATEGORY_GLASSES, 69,	"Gucci Techno Blue" , 		19020, 650, 	2 },
		{ CATEGORY_GLASSES, 70,	"Gucci Techno Green" , 		19021, 650, 	2 },
		// { CATEGORY_GLASSES, 71,	"Versace Vintage", 			19033, 520, 	2 },
		// { CATEGORY_GLASSES, 72,	"Versace Havana Wrap", 		19030, 490, 	2 },
		{ CATEGORY_GLASSES, 73,	"Oakley Whisker", 			19008, 400, 	2 },
		{ CATEGORY_GLASSES, 76,	"Versace Marble Square", 	19035, 380, 	2 },

		// HANDHELD
		{ CATEGORY_HANDHELD, 100, "Antique Sword", 			19590, 	15000, 	6 },
		{ CATEGORY_HANDHELD, 101, "Microphone", 			19610, 	900, 	6 },
		{ CATEGORY_HANDHELD, 102, "Police Radio", 			19942, 	750, 	6 },
		{ CATEGORY_HANDHELD, 103, "Left Boxing Glove", 		19555, 	250, 	6 },
		{ CATEGORY_HANDHELD, 104, "Right Boxing Glove", 	19556, 	250, 	5 },
		{ CATEGORY_HANDHELD, 105, "Briefcase", 				19624, 	100, 	6 },

		// WEAPONS
		{ CATEGORY_WEAPONS, 125, "RPG", 					359, 13337, 1 },
		{ CATEGORY_WEAPONS, 124, "Heatseeker", 				360, 13337, 1 },
		{ CATEGORY_WEAPONS, 123, "Minigun", 				362, 13337, 1 },
		{ CATEGORY_WEAPONS, 121, "Spas 12", 				351, 9000, 1 },
		{ CATEGORY_WEAPONS, 122, "M4", 						356, 9000, 1 },
		{ CATEGORY_WEAPONS, 119, "Sawn-off Shotgun", 		350, 8000, 1 },
		{ CATEGORY_WEAPONS, 120, "Sniper", 					358, 8000, 1 },
		{ CATEGORY_WEAPONS, 118, "Shotgun", 				349, 6000, 1 },
		{ CATEGORY_WEAPONS, 117, "Desert Eagle", 			348, 5000, 1 },
		{ CATEGORY_WEAPONS, 116, "Rifle", 					357, 3000, 1 },
		{ CATEGORY_WEAPONS, 115, "Tec 9", 					372, 2900, 1 },
		{ CATEGORY_WEAPONS, 114, "Mac 10", 					352, 2500, 1 },
		{ CATEGORY_WEAPONS, 109, "Purple Dildo", 			321, 690, 1 },
		{ CATEGORY_WEAPONS, 108, "Parachute", 				371, 600, 1 },
		{ CATEGORY_WEAPONS,	107, "Pool Cue",				338, 400, 1 },
		{ CATEGORY_WEAPONS, 106, "Brass Knuckles", 			331, 250, 1 },

		// MISC
		{ CATEGORY_MISC, 99, "Gold Bar", 					19941, 	38000,	1 },
		{ CATEGORY_MISC, 74, "Cowboy Boots",				11735, 	3000,	1 },
		{ CATEGORY_MISC, 77, "Marijuana Roll",				2901, 	2000, 	1 },
		{ CATEGORY_MISC, 75, "Pistol Holster",				19773, 	1000,	1 },
		{ CATEGORY_MISC, 79, "Police Light",   				19419, 	600,	1 },
		{ CATEGORY_MISC, 94, "Xmas Box 1",					19054,  500,	1 },
		{ CATEGORY_MISC, 95, "Xmas Box 2",					19056,  500,	1 },
		{ CATEGORY_MISC, 80, "Surf Board",					2406,  	250,	1 },
		{ CATEGORY_MISC, 97, "Skateboard",					19878, 	200, 	1 },
		{ CATEGORY_MISC, 81, "Glider",         				2512, 	150,	1 },
		{ CATEGORY_MISC, 82, "Plane",          				2510, 	120,	1 },
		{ CATEGORY_MISC, 98, "Hiker Backpack", 				19559, 	100, 	1 },
		{ CATEGORY_MISC, 78, "Backpack",					3026,	90,		1 },
		{ CATEGORY_MISC, 83, "Rubbish Bin",   				1343, 	80,		1 },
		{ CATEGORY_MISC, 84, "Chainsaw Dildo",				19086, 	69,		5 },
		{ CATEGORY_MISC, 85, "Easter Egg",					19344, 	50,		2 },
		{ CATEGORY_MISC, 86, "Hippobin",					1371, 	50,		1 },
		{ CATEGORY_MISC, 92, "Pumpkin",						19320, 	10,		1 },

		// VIP
		{ CATEGORY_VIP, -1,	"Small Fire",     				18688,	0,		1 },
		{ CATEGORY_VIP, -1,	"Dynamite",      				1654,	0,		6 },
		{ CATEGORY_VIP, -1,	"Caution Barrel", 				1218,	0,		1 },
		{ CATEGORY_VIP, -1,	"Gas Tank",    					918,	0,		1 },
		{ CATEGORY_VIP, -1,	"Parrot",         				19079, 	0,	   15 },
		{ CATEGORY_VIP, -1,	"Money Stack", 					1212, 	0,		6 },
		{ CATEGORY_VIP, -1,	"Turtle", 						1609, 	0,		1 },
		{ CATEGORY_VIP, -1,	"S.W.A.T Helmet", 				19141, 	0,		2 },
		{ CATEGORY_VIP, -1,	"S.W.A.T Armour", 				19142, 	0,		1 },
		{ CATEGORY_VIP, -1, "Construction Vest",			19904, 	0,		1 },
		{ CATEGORY_VIP, -1, "Sledge Hammer", 				19631, 	0,		5 },
		{ CATEGORY_VIP, -1, "Laser Sight", 					18643, 	0,		5 },
		{ CATEGORY_VIP, -1,	"Better Santa Hat",     		19065,	0,		2 }
	},
	p_AttachedObjectsData     	[ MAX_PLAYERS ] [ 3 ] [ E_ATTACHED_DATA ],
	p_ToySlotSelected			[ MAX_PLAYERS char ],
	p_ToyCategorySelected 		[ MAX_PLAYERS char ],
	p_ToyIDSelected 			[ MAX_PLAYERS char ],
	bool: p_ToyUnlocked     	[ MAX_PLAYERS ] [ MAX_TOY_UNLOCKS char ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	for ( new i = 0; i < MAX_TOY_UNLOCKS; i ++ )
	{
		p_ToyUnlocked[ playerid ] { i } = false;

		// reset attached toy data in the loop .. reusing it
		if ( i < sizeof( p_AttachedObjectsData[ ] ) ) {
			resetPlayerToys( playerid, i );
		}
	}
	return 1;
}

hook OnPlayerSpawn( playerid )
{
	reloadPlayerToys( playerid );
	return 1;
}

hook OnPlayerLogin( playerid )
{
	new
		accountid = GetPlayerAccountID( playerid );

	mysql_function_query( dbHandle, sprintf( "SELECT * FROM `TOY_UNLOCKS` WHERE `USER_ID`=%d", accountid ), true, "OnToyLoad", "d", playerid );
	mysql_function_query( dbHandle, sprintf( "SELECT * FROM `TOYS` WHERE `USER_ID`=%d", accountid ), true, "OnToyOffsetLoad", "d", playerid );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( checkpointid == g_Checkpoints[ CP_PAWNSHOP ] ) {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_BUY, DIALOG_STYLE_LIST, "{FFFFFF}Purchase Toys", getToyCategories( .pawnshop = true ), "Select", "Cancel" );
	}
	return 1;
}

hook OnPlayerEditAttachedObj( playerid, response, index, modelid, boneid, Float:fOffsetX, Float:fOffsetY, Float:fOffsetZ, Float:fRotX, Float:fRotY, Float:fRotZ, Float:fScaleX, Float:fScaleY, Float:fScaleZ )
{
	new slot = p_ToySlotSelected{ playerid };
	new color = p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ];

	if ( response )
	{
		new bool: modded;

	    if ( fScaleX < 0.1 || fScaleX > 2.5 ) fScaleX = 1.0, modded = true;
	    if ( fScaleY < 0.1 || fScaleY > 2.5 ) fScaleY = 1.0, modded = true;
	    if ( fScaleZ < 0.1 || fScaleZ > 2.5 ) fScaleZ = 1.0, modded = true;
	    if ( modded ) SendServerMessage( playerid, "Some scaling parts were either too small, or too big. They have been scaled to the default size." );

	   	p_AttachedObjectsData[ playerid ] [ slot ] [ E_BONE ] = boneid;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_OX ] = fOffsetX;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_OY ] = fOffsetY;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_OZ ] = fOffsetZ;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_RX ] = fRotX;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_RY ] = fRotY;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_RZ ] = fRotZ;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_SX ] = fScaleX;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_SY ] = fScaleY;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_SZ ] = fScaleZ;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_MODELID ] = modelid;

		RemovePlayerAttachedObject( playerid, index );
		SetPlayerAttachedObject( playerid, index, modelid, boneid, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ, color, color );

		format( szBigString, sizeof( szBigString ), "UPDATE `TOYS` SET `OX`=%f,`OY`=%f,`OZ`=%f,`RX`=%f,`RY`=%f,`RZ`=%f,`SX`=%f,`SY`=%f,`SZ`=%f WHERE `ID`=%d", fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ, p_AttachedObjectsData[ playerid ] [ slot ] [ E_SQL_ID ] );
		mysql_single_query( szBigString );

		//printf("SetPlayerAttachedObject( playerid, %d, %d, %d, %f, %f, %f, %f, %f, %f, %f, %f, %f );",index, modelid, boneid, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ );
	}
	else
	{
		// User Cancelled
		RemovePlayerAttachedObject( playerid, index );
		SetPlayerAttachedObject( playerid, index, p_AttachedObjectsData[ playerid ] [ slot ] [ E_MODELID ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_BONE ],
			p_AttachedObjectsData[ playerid ] [ slot ] [ E_OX ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_OY ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_OZ ],
			p_AttachedObjectsData[ playerid ] [ slot ] [ E_RX ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_RY ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_RZ ],
			p_AttachedObjectsData[ playerid ] [ slot ] [ E_SX ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_SY ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_SZ ],
			color, color
		);
	}
	showToyEditMenu( playerid, slot );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_TOYS_MAIN && response )
	{
		if ( !listitem )
		{
			if ( !p_AttachedObjectsData[ playerid ] [ 0 ] [ E_ENABLED ] && !p_AttachedObjectsData[ playerid ] [ 1 ] [ E_ENABLED ] && !p_AttachedObjectsData[ playerid ] [ 2 ] [ E_ENABLED ] )
				return SendError( playerid, "All attached toys are already disabled." );

			format( szNormalString, sizeof( szNormalString ), "UPDATE `TOYS` SET `ENABLED`=0 WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
			mysql_single_query( szNormalString );

			RemovePlayerAttachedObject( playerid, 9 );
			RemovePlayerAttachedObject( playerid, 8 );
			RemovePlayerAttachedObject( playerid, 7 );
			p_AttachedObjectsData[ playerid ] [ 0 ] [ E_ENABLED ] = 0;
			p_AttachedObjectsData[ playerid ] [ 1 ] [ E_ENABLED ] = 0;
			p_AttachedObjectsData[ playerid ] [ 2 ] [ E_ENABLED ] = 0;
			return SendServerMessage( playerid, "All attached toys have been disabled." );
		}

		p_ToySlotSelected{ playerid } = listitem - 1;
		if ( p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_BONE ] ) {
			showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
		} else {
          	ShowPlayerDialog( playerid, DIALOG_TOYS, DIALOG_STYLE_LIST, "{FFFFFF}Toys", getToyCategories( ), "Select", "Back" );
      	}
	}
	else if ( dialogid == DIALOG_TOYS_ITEMS )
	{
	    if ( !response )
	    	return ShowPlayerDialog( playerid, DIALOG_TOYS, DIALOG_STYLE_LIST, "{FFFFFF}Toys", getToyCategories( ), "Select", "Back" );

		for( new id, x = 0; id < MAX_TOYS; id++ )
		{
			if ( g_ToyData[ id ] [ E_CATEGORY ] == p_ToyCategorySelected{ playerid } )
			{
		       	if ( x == listitem )
		      	{
		      		p_ToyIDSelected{ playerid } = id;

				    if ( g_ToyData[ id ] [ E_ID ] == -1 )
				    {
						showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid } );

				    	if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
				        	return SendError( playerid, "You must be a V.I.P to use this, to become one visit "COL_GREY"donate.sfcnr.com" ), 1;

						if ( ( ( p_VIPExpiretime[ playerid ] - g_iTime ) / 86400 ) < 3 )
							return SendError( playerid, "You need more than 3 days of V.I.P in order to complete this." ), 1;
				    }

				    if ( g_ToyData[ id ] [ E_ID ] != -1 && !p_ToyUnlocked[ playerid ] { g_ToyData[ id ] [ E_ID ] } )
				    {
						showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid } );
						return SendError( playerid, "You have not unlocked this toy." );
				    }

		      		SendServerMessage( playerid, "You have selected "COL_GREY"%s"COL_WHITE". Proceed with bone selection to place the toy.", g_ToyData[ id ] [ E_NAME ] );
		      		ShowPlayerDialog( playerid, DIALOG_TOYS_BONE, DIALOG_STYLE_LIST, "{FFFFFF}Toys - Bones", ""COL_GREY"Use Default Bone\nSpine\nHead\nLeft Upper Arm\nRight Upper Arm\nLeft Hand\nRight Hand\nLeft Thigh\nRight Thigh\nLeft Foot\nRight Foot\nRight Calf\nLeft Calf\nLeft Forearm\nRight Forearm\nLeft Clavicle\nRight Clavicle\nNeck\nJaw", "Select", "Back" );
					break;
		   		}
		      	x ++;
			}
		}
	}
	else if ( dialogid == DIALOG_TOYS_ITEMS_BUY )
	{
	    if ( !response )
	    	return ShowPlayerDialog( playerid, DIALOG_TOYS_BUY, DIALOG_STYLE_LIST, "{FFFFFF}Purchase Toys", getToyCategories( .pawnshop = true ), "Select", "Cancel" );

		for( new id, x = 0; id < MAX_TOYS; id++ )
		{
			if ( g_ToyData[ id ] [ E_CATEGORY ] == p_ToyCategorySelected{ playerid } )
			{
		       	if ( x == listitem )
		      	{
		      		SetPVarInt( playerid, "toy_item", id );
					ShowPlayerDialog( playerid, DIALOG_TOY_PREVIEW, DIALOG_STYLE_TABLIST, "{FFFFFF}Purchase Toys", sprintf( "Purchase Toy\t"COL_GOLD"%s\nPreview Toy\t ", cash_format( g_ToyData[ id ] [ E_PRICE ] ) ), "Select", "Back" );
		      		break;
		   		}
		      	x ++;
			}
		}
	}
	else if ( dialogid == DIALOG_TOY_PREVIEW )
	{
		if ( ! response )
			return showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );

		new
			id = GetPVarInt( playerid, "toy_item" );

		if ( ! ( 0 <= id < sizeof( g_ToyData ) ) )
			return SendError( playerid, "An error has occurred, please try again." );

		switch ( listitem )
		{
			// bought
			case 0:
			{
				if ( p_ToyUnlocked[ playerid ] { g_ToyData[ id ] [ E_ID ] } )
			    {
					showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );
					return SendError( playerid, "You have already bought this toy." );
			    }

	      		if ( GetPlayerCash( playerid ) < g_ToyData[ id ] [ E_PRICE ] )
	      		{
					showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );
					return SendError( playerid, "You cannot afford this toy." );
	      		}

			    UnlockPlayerToy( playerid, g_ToyData[ id ] [ E_ID ] );
			    GivePlayerCash( playerid, -g_ToyData[ id ] [ E_PRICE ] );
				StockMarket_UpdateEarnings( E_STOCK_PAWN_STORE, g_ToyData[ id ] [ E_PRICE ], 0.25 );
				showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );
	      		SendServerMessage( playerid, "You have bought a "COL_GREY"%s"COL_WHITE" for "COL_GOLD"%s"COL_WHITE".", g_ToyData[ id ] [ E_NAME ], cash_format( g_ToyData[ id ] [ E_PRICE ] ) );
			}

			// preview
			case 1:
			{
				return ShowPlayerModelPreview( playerid, MODEL_PREVIEW_TOY, "Toy Preview", g_ToyData[ id ] [ E_MODEL ] );
			}
		}
	}
	else if ( dialogid == DIALOG_TOYS_BONE || dialogid == DIALOG_TOYS_BONE_EDIT )
	{
		new
			iSlot = p_ToySlotSelected{ playerid };

	    if ( !response && dialogid == DIALOG_TOYS_BONE )
			return showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid } );

	    if ( !response && dialogid == DIALOG_TOYS_BONE_EDIT )
			return showToyEditMenu( playerid, iSlot );

	    if ( !listitem ) {
    		p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] = g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_DEFAULT_BONE ];
	        SendServerMessage( playerid, "You have now placed your toy on the default bone." );
	    }
	    else {
	        p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] = listitem;
	        SendServerMessage( playerid, "You have now placed your toy on this bone." );
	    }

		RemovePlayerAttachedObject( playerid, 7 + iSlot );
	    SetPlayerAttachedObject( playerid, 7 + iSlot, g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_MODEL ], p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] );

	    p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_ENABLED ] = 1;
		p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_MODELID ] = g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_MODEL ];

	    if ( dialogid == DIALOG_TOYS_BONE ) {
			format( szBigString, sizeof( szBigString ), "INSERT INTO `TOYS`(`USER_ID`,`SLOT_ID`,`ENABLED`,`MODEL_ID`,`BONE`) VALUES (%d,%d,1,%d,%d)", p_AccountID[ playerid ], iSlot, g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_MODEL ], p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] );
			mysql_function_query( dbHandle, szBigString, true, "OnPlayerAddToy", "dd", playerid, iSlot );
	    } else {
			format( szNormalString, sizeof( szNormalString ), "UPDATE `TOYS` SET `BONE`=%d,`OX`=0,`OY`=0,`OZ`=0,`RX`=0,`RY`=0,`RZ`=0,`SX`=1,`SY`=1,`SZ`=1 WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SQL_ID ] );
			mysql_single_query( szNormalString );
	    }

		showToyEditMenu( playerid, iSlot );
	}
	else if ( dialogid == DIALOG_TOYS_COLOR )
	{
		new
			slot = p_ToySlotSelected{ playerid };

	    if ( !response )
			return showToyEditMenu( playerid, slot );

		new
			hexcode[ 7 ];

		if ( sscanf( inputtext, "S(000000)[7]", hexcode ) ) SendError( playerid, "Please ensure your hex is 6 characters at maximum (RRGGBB)." );
		else if ( ! isHex( hexcode ) ) SendError( playerid, "This is not a valid hex code." );
		else
		{
			if ( strmatch( hexcode, "000000" ) )
			{
		    	p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ] = 0;
		    	mysql_single_query( sprintf( "UPDATE `TOYS` SET `COLOR`=0 WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ slot ] [ E_SQL_ID ] ) );
				SendServerMessage( playerid, "You have reset your toy's color." );
			}
			else
			{
				new
					final_hex;

				if ( ! sscanf( sprintf( "0xFF%s", hexcode ), "h", final_hex ) )
				{
			    	p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ] = final_hex;
			    	mysql_single_query( sprintf( "UPDATE `TOYS` SET `COLOR`=%d WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_SQL_ID ] ) );
					SendServerMessage( playerid, "You have set your toy's color to {%s}%s"COL_WHITE".", hexcode, hexcode );
				}
				else SendError( playerid, "This is not a valid hex code." );
			}
			return reloadPlayerToys( playerid );
		}
		return showToyEditMenu( playerid, slot );
	}
	else if ( dialogid == DIALOG_TOYS_EDIT )
	{
		if ( !response )
			return cmd_toys( playerid, "" );

		switch( listitem )
		{
			case 0:
			{
				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] ) {
					SendError( playerid, "You cannot edit a disabled toy." );
					return showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
				}

			    EditAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } );
			    SendServerMessage( playerid, "You are now editing a toy." );
			}
			case 1:
			{
				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] ) {
					SendError( playerid, "You cannot reselect a bone of a disabled toy." );
					return showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
				}

				ShowPlayerDialog( playerid, DIALOG_TOYS_BONE_EDIT, DIALOG_STYLE_LIST, "{FFFFFF}Toys - Bones", ""COL_GREY"Use Default Bone\nSpine\nHead\nLeft Upper Arm\nRight Upper Arm\nLeft Hand\nRight Hand\nLeft Thigh\nRight Thigh\nLeft Foot\nRight Foot\nRight Calf\nLeft Calf\nLeft Forearm\nRight Forearm\nLeft Clavicle\nRight Clavicle\nNeck\nJaw", "Select", "Back" );
			    SendServerMessage( playerid, "You are now reselecting your toy's bone." );
			}
			case 2:
			{
				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] ) {
					SendError( playerid, "You cannot set the color of a disabled toy." );
					return showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
				}

				ShowPlayerDialog( playerid, DIALOG_TOYS_COLOR, DIALOG_STYLE_INPUT, "{FFFFFF}Toys - Color", ""COL_WHITE"Please specify the color (hex) code as "COL_RED"RR"COL_GREEN"GG"COL_BLUE"BB"COL_WHITE" below:", "Select", "Back" );
			    SendServerMessage( playerid, "You are now editing your toy's color, enter nothing or 000000 to reset it." );
			}
			case 3:
			{
				p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] = !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ];

				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] )
				{
					RemovePlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } );
					SendServerMessage( playerid, "You have disabled this toy." );
				}
				else
				{
					RemovePlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } ); // Just incase.
					SetPlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid }, p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_MODELID ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_BONE ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_OX ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_OY ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_OZ ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_RX ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_RY ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_RZ ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SX ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SY ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SZ ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_COLOR ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_COLOR ]
					);
					SendServerMessage( playerid, "You have enabled this toy." );
				}

				format( szNormalString, sizeof( szNormalString ), "UPDATE `TOYS` SET `ENABLED`=%d WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SQL_ID ] );
				mysql_single_query( szNormalString );

				showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
			}
			case 4:
			{
				RemovePlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } );
			   	p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_BONE ] = 0;
				p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_MODELID ] = 0;

				format( szNormalString, sizeof( szNormalString ), "DELETE FROM `TOYS` WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SQL_ID ] );
				mysql_single_query( szNormalString );

				SendServerMessage( playerid, "You have removed this toy." );
				cmd_toys( playerid, "" );
			}
		}
	}
	else if ( dialogid == DIALOG_TOYS ) {
		if ( !response )
			return cmd_toys( playerid, "" );

		p_ToyCategorySelected{ playerid } = listitem;
		showToyCategoryItems( playerid, listitem );
	}
	else if ( dialogid == DIALOG_TOYS_BUY && response ) {
		p_ToyCategorySelected{ playerid } = listitem;
		showToyCategoryItems( playerid, listitem, .pawnshop = true );
	}
	return 1;
}

hook OnPlayerEndModelPreview( playerid, handleid )
{
	if ( handleid == MODEL_PREVIEW_TOY )
	{
		new
			id = GetPVarInt( playerid, "toy_item" );

		SendServerMessage( playerid, "You have finished looking at this toy preview." );
		return ShowPlayerDialog( playerid, DIALOG_TOY_PREVIEW, DIALOG_STYLE_TABLIST, "{FFFFFF}Purchase Toys", sprintf( "Purchase Toy\t"COL_GOLD"%s\nPreview Toy\t ", cash_format( g_ToyData[ id ] [ E_PRICE ] ) ), "Select", "Back" ), Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

/* ** Commands ** */
CMD:toys( playerid, params[ ] )
{
	if ( !IsPlayerSpawned( playerid ) )
		return SendError( playerid, "You cannot use this command while you are not spawned." );

	return ShowPlayerToys( playerid );
}

/* ** SQL Threads ** */
thread OnToyLoad( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		rows, fields, i = -1
	;

	cache_get_data( rows, fields );
	if ( rows ) {
		while( ++i < rows ) {
			new iToy = cache_get_field_content_int( i, "TOY_ID", dbHandle );

			if ( iToy < MAX_TOY_UNLOCKS ) // Must be something wrong otherwise...
				p_ToyUnlocked[ playerid ] { iToy } = true;
		}
	}
	return 1;
}

thread OnToyOffsetLoad( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		rows, fields, i = -1
	;

	cache_get_data( rows, fields );
	if ( rows ) {
		while( ++i < rows ) {
			new
				iSlot = cache_get_field_content_int( i, "SLOT_ID", dbHandle );

			if ( iSlot < sizeof( p_AttachedObjectsData[ ] ) ) {
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SQL_ID ] = cache_get_field_content_int( i, "ID", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_ENABLED ] = cache_get_field_content_int( i, "ENABLED", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_MODELID ] = cache_get_field_content_int( i, "MODEL_ID", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] = cache_get_field_content_int( i, "BONE", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_OX ] = cache_get_field_content_float( i, "OX", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_OY ] = cache_get_field_content_float( i, "OY", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_OZ ] = cache_get_field_content_float( i, "OZ", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_RX ] = cache_get_field_content_float( i, "RX", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_RY ] = cache_get_field_content_float( i, "RY", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_RZ ] = cache_get_field_content_float( i, "RZ", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SX ] = cache_get_field_content_float( i, "SX", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SY ] = cache_get_field_content_float( i, "SY", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SZ ] = cache_get_field_content_float( i, "SZ", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_COLOR ] = cache_get_field_content_int( i, "COLOR", dbHandle );
			}
		}
	}
	return 1;
}

thread OnPlayerAddToy( playerid, slotid ) {
	p_AttachedObjectsData[ playerid ] [ slotid ] [ E_SQL_ID ] = cache_insert_id( );
	return 1;
}


/* ** Functions ** */
stock getToyCategories( bool: pawnshop = false )
{
	static
		szToyCategory[ 150 ],
		szPawnCategory[ 150 ];

	if ( szToyCategory[ 0 ] == '\0' ) {
		for( new i = 0; i < sizeof( g_ToyCategory ); i++ )
			format( szToyCategory, sizeof( szToyCategory ), "%s%s\n", szToyCategory, g_ToyCategory[ i ] );
	}

	if ( szPawnCategory[ 0 ] == '\0' ) {
		for( new i = 0; i < sizeof( g_ToyCategory ); i++ ) if ( i != CATEGORY_VIP )
			format( szPawnCategory, sizeof( szPawnCategory ), "%s%s\n", szPawnCategory, g_ToyCategory[ i ] );
	}

	return pawnshop ? szPawnCategory : szToyCategory;
}

stock showToyCategoryItems( playerid, category, bool: pawnshop = false )
{
	erase( szLargeString );

	for( new i = 0; i < sizeof( g_ToyData ); i++ )
	{
		if ( g_ToyData[ i ] [ E_CATEGORY ] == category )
		{
			if ( pawnshop ) {
				format( szLargeString, sizeof( szLargeString ), "%s%s%s\t"COL_GOLD"%s\n", szLargeString, p_ToyUnlocked[ playerid ] { g_ToyData[ i ] [ E_ID ] } ? ( #COL_LGREEN ) : ( #COL_WHITE ), g_ToyData[ i ] [ E_NAME ], cash_format( g_ToyData[ i ] [ E_PRICE ] ) );
			} else {
				format( szLargeString, sizeof( szLargeString ), "%s%s%s\n", szLargeString, g_ToyData[ i ] [ E_ID ] != -1 ? ( !p_ToyUnlocked[ playerid ] { g_ToyData[ i ] [ E_ID ] } ? ( "{3D3D3D}" ) : ( "{FFFFFF}" ) ) : ( COL_GOLD ), g_ToyData[ i ] [ E_NAME ] );
			}
		}
	}

	if ( pawnshop ) {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_ITEMS_BUY, DIALOG_STYLE_TABLIST, pawnshop ? ( "{FFFFFF}Purchase Toys" ) : ( "{FFFFFF}Toys" ), szLargeString, "Select", "Back" );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_ITEMS, DIALOG_STYLE_LIST, pawnshop ? ( "{FFFFFF}Purchase Toys" ) : ( "{FFFFFF}Toys" ), szLargeString, "Select", "Back" );
	}
}

stock UnlockPlayerToy( playerid, toy_id )
{
	if ( toy_id > MAX_TOY_UNLOCKS )
		return;

	p_ToyUnlocked[ playerid ] { toy_id } = true;
	format( szNormalString, 72, "INSERT INTO `TOY_UNLOCKS`(`USER_ID`, `TOY_ID`) VALUES (%d, %d)", p_AccountID[ playerid ], toy_id);
	mysql_single_query( szNormalString );
}

stock resetPlayerToys( playerid, slot ) {
   	p_AttachedObjectsData[ playerid ] [ slot ] [ E_ENABLED ] = 0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_MODELID ] = 0;
   	p_AttachedObjectsData[ playerid ] [ slot ] [ E_BONE ] = 0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_OX ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_OY ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_OZ ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_RX ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_RY ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_RZ ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_SX ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_SY ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_SZ ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ] = 0;
}

stock showToyEditMenu( playerid, slot )
{
	if ( p_AttachedObjectsData[ playerid ] [ slot ] [ E_ENABLED ] ) {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_EDIT, DIALOG_STYLE_LIST, "{FFFFFF}Toys", ""COL_WHITE"Edit Toy Position\n"COL_WHITE"Edit Toy Bone\n"COL_WHITE"Edit Toy Color\nDisable Toy\n"COL_LRED"Remove Toy", "Select", "Back" );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_EDIT, DIALOG_STYLE_LIST, "{FFFFFF}Toys", ""COL_BLACK"Edit Toy Position\n"COL_BLACK"Edit Toy Bone\n"COL_BLACK"Edit Toy Color\nEnable Toy", "Select", "Back" );
	}
}

stock reloadPlayerToys( playerid )
{
	for ( new i = 0; i < sizeof ( p_AttachedObjectsData[ ] ); i ++ ) {
		if ( p_AttachedObjectsData[ playerid ] [ i ] [ E_ENABLED ] ) {
			RemovePlayerAttachedObject( playerid, 7 + i );
			SetPlayerAttachedObject( playerid, 7 + i, p_AttachedObjectsData[ playerid ] [ i ] [ E_MODELID ], p_AttachedObjectsData[ playerid ] [ i ] [ E_BONE ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_OX ], p_AttachedObjectsData[ playerid ] [ i ] [ E_OY ], p_AttachedObjectsData[ playerid ] [ i ] [ E_OZ ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_RX ], p_AttachedObjectsData[ playerid ] [ i ] [ E_RY ], p_AttachedObjectsData[ playerid ] [ i ] [ E_RZ ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_SX ], p_AttachedObjectsData[ playerid ] [ i ] [ E_SY ], p_AttachedObjectsData[ playerid ] [ i ] [ E_SZ ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_COLOR ], p_AttachedObjectsData[ playerid ] [ i ] [ E_COLOR ]
			);
		}
	}
	return 1;
}

stock ShowPlayerToys( playerid )
{
	new
		iToy[ 3 ] [ 24 ] = { { "None" }, { "None" }, { "None" } };

	for( new i = 0; i < sizeof( g_ToyData ); i++ ) {
 		for( new x = 0; x < sizeof( iToy ); x++ ) {
			if ( g_ToyData[ i ] [ E_MODEL ] == p_AttachedObjectsData[ playerid ] [ x ] [ E_MODELID ] )
				strcpy( iToy[ x ], g_ToyData[ i ] [ E_NAME ] );
 		}
 	}

	format( szNormalString, sizeof( szNormalString ), ""COL_GREY"Disable All Toys\nSlot 1 (%s)\nSlot 2 (%s)\nSlot 3 (%s)", iToy[ 0 ], iToy[ 1 ], iToy[ 2 ] );
	return ShowPlayerDialog( playerid, DIALOG_TOYS_MAIN, DIALOG_STYLE_LIST, "{FFFFFF}Toys", szNormalString, "Select", "Close" ), 1;
}