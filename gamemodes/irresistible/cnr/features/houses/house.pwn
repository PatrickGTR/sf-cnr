/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Error checking ** */
#if !defined __sfcnr__houses
	#define __sfcnr__houses
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_HOUSES                  ( 2000 )
#define MAX_HOUSE_WEAPONS           ( 7 ) 		// (do not change)
#define HOUSE_MAPICON_RADIUS 		( 25.0 )

#define H_DEFAULT_X					266.4996
#define H_DEFAULT_Y					304.9577
#define H_DEFAULT_Z					999.1484

#define PROGRESS_BRUTEFORCE 		1

/* ** Macros ** */
#define IsPlayerHomeOwner(%0,%1)	( strmatch( g_houseData[ %1 ] [ E_OWNER ], ReturnPlayerName( %0 ) ) )

/* ** Variables ** */
enum E_HOUSE_DATA
{
	E_OWNER[ 24 ],    	E_HOUSE_NAME[ 30 ],

	Float: E_EX,      	Float: E_EY,           	Float: E_EZ,
	Float: E_TX,     	Float: E_TY,          	Float: E_TZ,

	E_COST,        		E_INTERIOR_ID,          E_CHECKPOINT[ 2 ],
	E_WORLD, 			Text3D: E_LABEL [ 2 ], 	E_PASSWORD[ 5 ],

	bool: E_CRACKED, 	bool: E_BEING_CRACKED,  E_CRACKED_TS,
	E_CRACKED_WAIT,		E_MAP_ICON
};

enum E_HINTERIOR_DATA
{
	E_NAME[ 19 ], 		Float: E_EX, 				Float: E_EY,
	Float: E_EZ, 		E_INTERIOR_ID, 				E_COST,
	bool: E_VIP,		Float: E_PREVIEW_POS[ 3 ],	Float: E_PREVIEW_LOOKAT[ 3 ]
};

new
	g_houseInteriors[ ] [ E_HINTERIOR_DATA ] =
  	{
      	{ "Cattus Interior",   	H_DEFAULT_X, H_DEFAULT_Y, H_DEFAULT_Z, 	2,  0,	false, { 266.60010, 302.42820, 999.14840 }, { 271.44260, 306.64240, 999.15580 } },
   		{ "Assum Interior",   	243.71980, 304.963500, 999.14840, 	1,  10000,	false, { 249.61870, 300.89080, 999.14840 }, { 244.85410, 305.49680, 999.14840 } },
      	{ "Fossor Interior", 	2218.4036, -1076.2621, 1050.4844,	1,	15000,	false, { 2202.6704, -1078.198, 1050.4844 }, { 2211.8030, -1074.362, 1050.4844 } },
      	//{ "Angusto Interior", 	260.98790, 1284.29470, 1080.2578,	4,	20000,	false, { 253.80180, 1294.2167, 1080.2578 }, { 258.55260, 1288.3639, 1080.2578 } },
      	{ "Organum Interior", 	309.37170, 311.674700, 1003.3047,	4,  25000,	false, { 310.13720, 310.80550, 1003.3047 }, { 300.02930, 300.86170, 1003.5391 } },
      	//{ "Bulbus Interior", 	-68.84510, 1351.19570, 1080.2109,	6,	25000,	false, { -71.41990, 1366.0359, 1080.2185 }, { -64.59070, 1360.7052, 1080.2185 } },
      	//{ "Vindemia Interior", 	295.08510, 1472.25520, 1080.2578,	15,	25000,	false, { 290.14430, 1488.8372, 1080.2578 }, { 294.96960, 1483.6603, 1080.2578 } },
      	{ "Aurora Interior", 	-2170.344, 639.502500, 1052.3750,	1,	30000,	false, { -2168.073, 646.40000, 1057.5938 }, { -2158.598, 638.13010, 1057.5861 } },
      	{ "Fragor Interior",   	318.58580, 1114.47920, 1083.8828,	5,	35000,	false, { 326.31450, 1117.5468, 1083.8828 }, { 317.28550, 1122.6113, 1083.8828 } },
      	//{ "Mundus Interior", 	24.012500, 1340.15890, 1084.3750,	10,	40000,	false, { 19.801100, 1340.7814, 1084.3750 }, { 34.253800, 1342.9272, 1084.3750 } },
      	{ "Artus Interior", 	2237.5259, -1081.6458, 1049.0234,	2,	40000,	false, { 2236.2290, -1081.065, 1049.0234 }, { 2244.2285, -1069.357, 1049.0234 } },
      	{ "Caelum Interior", 	2233.6931, -1115.2620, 1050.8828,	5,	40000,	false, { 2235.1128, -1114.911, 1050.8828 }, { 2229.8982, -1105.175, 1050.8903 } },
      	{ "Rotta Interior",		2495.9663, -1692.0857, 1014.7422,	3,	50000,	false, { 2491.1794, -1694.953, 1014.7461 }, { 2497.4587, -1704.258, 1014.7422 } },
      	{ "Ascensor Interior", 	2317.8369, -1026.7662, 1050.2178,	9,	50000,	false, { 2320.9111, -1025.776, 1050.2109 }, { 2319.0242, -1014.091, 1050.2109 } },
      	{ "Colonel Interior",	2807.5693, -1174.7520, 1025.5703,	8,	60000,	false, { 2812.0911, -1173.043, 1025.5703 }, { 2806.0210, -1165.486, 1025.5703 } },
      	//{ "Godfather Interior", 140.28170, 1365.92150, 1083.8594,	5,	65000,	false, { 135.53440, 1366.6400, 1083.8615 }, { 143.49590, 1375.7461, 1083.8668 } },
      	{ "Recens Interior",	2270.4192, -1210.5172, 1047.5625,	10,	70000,	false, { 2248.2854, -1207.207, 1049.0234 }, { 2261.0574, -1213.011, 1049.0234 } },
      	{ "Novus Interior",		2365.2341, -1135.5957, 1050.8826,	8,	72000,	false, { 2375.3567, -1121.340, 1050.8750 }, { 2367.7095, -1130.863, 1050.8826 } },
      	{ "Securuse Interior",	2324.3826, -1149.5442, 1050.7101,	12,	80000,	false, { 2317.5684, -1136.016, 1054.3047 }, { 2333.1262, -1147.694, 1050.7031 } },
      	//{ "Lorem Interior", 	234.13900, 1063.72110, 1084.2123,	6,	82500,	false, { 235.83530, 1070.2394, 1084.1903 }, { 226.63560, 1073.0388, 1086.2266 } },
      	//{ "Domus Interior", 	225.73480, 1021.44500, 1084.0177,	7,	120000,	false, { 224.76680, 1022.3558, 1084.0150 }, { 241.65380, 1037.2081, 1084.0118 } },
      	{ "Madd Doggs Mansion", 1260.6455, -785.46530, 1091.9063,	5,	1337,	true , { 1262.1033, -772.6712, 1091.9063 }, { 1282.7361, -783.5193, 1089.9375 } },
      	{ "Butcher Interior", 	964.93310, 2160.13210, 1011.0303, 	1,	1337,	true , { 933.67050, 2118.9556, 1012.8329 }, { 947.38930, 2163.8730, 1011.0234 } },
      	{ "Bar Interior", 		501.93780, -67.563000, 998.75780, 	11, 1337,	true , { 511.80380, -68.01930, 999.25000 }, { 490.78870, -78.92080, 998.75780 } },
      	{ "Casino Interior", 	1133.1831, -15.833100, 1000.6797, 	12, 1337,	true , { 1114.8433, -12.31790, 1003.0643 }, { 1136.3059, 2.6477000, 1000.6797 } }
  	},
	g_houseData                     [ MAX_HOUSES ] [ E_HOUSE_DATA ],
	Iterator: houses 				< MAX_HOUSES >,

	szg_houseInteriors				[ 24 * sizeof( g_houseInteriors ) ],
	g_HouseWeapons					[ MAX_HOUSES ] [ MAX_HOUSE_WEAPONS ],
	g_HouseWeaponAmmo				[ MAX_HOUSES ] [ MAX_HOUSE_WEAPONS ],

	p_InHouse                       [ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// load all house interiors into a string once
	for( new i = 0; i < sizeof( g_houseInteriors ); i++ ) {
		format( szg_houseInteriors, sizeof( szg_houseInteriors ), "%s%s%s\n", szg_houseInteriors, g_houseInteriors[ i ] [ E_VIP ] ? ( COL_GOLD ) : "", g_houseInteriors[ i ] [ E_NAME ] );
	}

	// load all houses
	mysql_function_query( dbHandle, "SELECT * FROM `HOUSES`", true, "OnHouseLoad", "" );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_HOUSE_CONFIG && response )
	{
		if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "You're not inside any house." );
	   	if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
	   	DeletePVar( playerid, "gate_edititem" ); // Definitely not in the gate dialog lol
		switch( listitem )
		{
		    case 0: ShowPlayerDialog( playerid, DIALOG_HOUSE_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Set House Title", ""COL_WHITE"Input the house title you want to change with:", "Confirm", "Back" );
		    case 1: ShowPlayerDialog( playerid, DIALOG_HOUSE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", szg_houseInteriors, "Select", "Back" );
		    case 2: ShowPlayerDialog( playerid, DIALOG_HOUSE_SET_PW, DIALOG_STYLE_INPUT, "{FFFFFF}Set House Password", ""COL_WHITE"Enter your desired house password below.\n\n"COL_GREY"Note:"COL_WHITE" You can disable it by typing \"N/A\" (without the quotation marks).", "Confirm", "Back" );
			case 3: ShowHouseWeaponStorage( playerid );
			case 4: ShowPlayerDialog( playerid, DIALOG_FURNITURE, DIALOG_STYLE_LIST, "{FFFFFF}Furniture", "Purchase Furniture\nSelect Furniture Easily\nSelect Furniture Manually\nSelect Furniture Nearest\n"COL_RED"Remove All Furniture", "Confirm", "Back" );
		}
	}
	else if ( dialogid == DIALOG_HOUSE_WEAPONS )
	{
	 	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "You're not inside any house." );
	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
			if ( g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] != 0 )
			{
				GivePlayerWeapon( playerid, g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ], g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] );
			    SendServerMessage( playerid, "You have withdrawn your "COL_GREY"%s"COL_WHITE" with %d ammo.", ReturnWeaponName( g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] ), g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] );
                g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] = 0;
			    g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] = -1;
                SaveHouseWeaponStorage( p_InHouse[ playerid ] );
			    ShowHouseWeaponStorage( playerid );
			}
			else
			{
				if ( listitem > 2 && p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
				p_HouseWeaponAddSlot{ playerid } = listitem;
				ShowPlayerDialog( playerid, DIALOG_HOUSE_WEAPONS_ADD, DIALOG_STYLE_MSGBOX, "{FFFFFF}House Weapon Storage", "{FFFFFF}Would you like to insert your current weapon into this slot?", "Insert", "Back" );
			}
	    }
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_WEAPONS_ADD )
	{
	    if ( response )
	    {
	    	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );
	        if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "You're not inside any house." );
	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
			if ( IsMeleeWeapon( GetPlayerWeapon( playerid ) ) )
			{
			    SendError( playerid, "You cannot insert melee weapons." );
			    cmd_h( playerid, "config" );
			    return 1;
			}
			new current_weapon = GetPlayerWeapon( playerid );
			new current_ammo = GetPlayerAmmo( playerid );
			if ( ( 16 <= current_weapon <= 18 ) || current_weapon == 35 ) {
			    SendError( playerid, "You cannot store this weapon." );
			    cmd_h( playerid, "config" );
			    return 1;
			}
			if ( current_ammo > 0x7FFF || current_ammo <= 0 ) current_ammo = 0x7FFF;
			listitem = p_HouseWeaponAddSlot{ playerid };
            g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] = current_weapon;
            g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] = current_ammo;
            SendServerMessage( playerid, "You have inserted your "COL_GREY"%s"COL_WHITE" into your weapon storage.", ReturnWeaponName( current_weapon ) );
            RemovePlayerWeapon( playerid, current_weapon );
         	SaveHouseWeaponStorage( p_InHouse[ playerid ] );
			ShowHouseWeaponStorage( playerid );
	    }
	    else ShowHouseWeaponStorage( playerid );
	}
	else if ( dialogid == DIALOG_HOUSE_SET_PW )
	{
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "You're not inside any house." );
	        else if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
			else if ( !strlen( inputtext ) || strlen( inputtext ) > 4 )
			{
			    SendError( playerid, "Your password must vary between 0 and 4 characters." );
				ShowPlayerDialog( playerid, DIALOG_HOUSE_SET_PW, DIALOG_STYLE_INPUT, "{FFFFFF}Set House Password", ""COL_WHITE"Enter your desired house password below.\n\n"COL_GREY"Note:"COL_WHITE" You can disable it by typing \"N/A\" or \"NULL\" (without the quotation marks).", "Confirm", "Back" );
			}
			else if ( strmatch( inputtext, "N/A" ) || strmatch( inputtext, "NULL" ) )
			{
				format( g_houseData[ p_InHouse[ playerid ] ] [ E_PASSWORD ], 4, "N/A" );
			    SendServerMessage( playerid, "You have successfully disabled your house's password." );
			    format( szNormalString, 60, "UPDATE `HOUSES` SET `PASSWORD`='N/A' WHERE `ID`=%d", p_InHouse[ playerid ] );
			    mysql_single_query( szNormalString );
			    cmd_h( playerid, "config" );
			}
			else
			{
			    SendServerMessage( playerid, "You have changed your house password to "COL_GREY"%s"COL_WHITE".", inputtext );
			    format( g_houseData[ p_InHouse[ playerid ] ] [ E_PASSWORD ], 5, "%s", inputtext );
			    format( szNormalString, 60, "UPDATE `HOUSES` SET `PASSWORD`='%s' WHERE `ID`=%d", mysql_escape( inputtext ), p_InHouse[ playerid ] );
			    mysql_single_query( szNormalString );
			    cmd_h( playerid, "config" );
			}
	    }
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_INTERIORS )
	{
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 )
				return SendError( playerid, "You're not inside any house." );

	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
				return SendError( playerid, "You are not the owner of this house." );

			p_ViewingInterior{ playerid } = listitem;
			ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", "Purchase House Interior\nPreview House Interior", "Select", "Back" );
		}
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_INT_CONFIRM )
	{
		if ( response )
		{
	        if ( p_InHouse[ playerid ] == -1 )
				return SendError( playerid, "You're not inside any house." );

	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
				return SendError( playerid, "You are not the owner of this house." );

			new
				intid = p_ViewingInterior{ playerid };

			switch( listitem )
			{
				case 0:
				{
					if ( g_houseInteriors[ intid ] [ E_COST ] > GetPlayerCash( playerid ) )
					{
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", "Purchase House Interior\nPreview House Interior", "Select", "Back" );
						SendError( playerid, "This interior costs "COL_GOLD"%s"COL_WHITE". You don't have this amount.", cash_format( g_houseInteriors[ intid ] [ E_COST ] ) );
					}
					else if ( g_houseInteriors[ intid ] [ E_VIP ] && !p_VIPLevel[ playerid ] )
					{
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", "Purchase House Interior\nPreview House Interior", "Select", "Back" );
						SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
					}
					else if ( ArePlayersInHouse( p_InHouse[ playerid ], playerid ) )
					{
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", "Purchase House Interior\nPreview House Interior", "Select", "Back" );
						SendError( playerid, "You cannot purchase a house interior if there are people inside the building." );
					}
					else
					{
						if ( g_houseInteriors[ intid ] [ E_VIP ] && p_VIPLevel[ playerid ] && ( ( p_VIPExpiretime[ playerid ] - g_iTime ) / 86400 ) < 3 )
							return SendError( playerid, "You need more than 3 days of V.I.P in order to complete this." );

					    new houseid = p_InHouse[ playerid ];
					    GivePlayerCash( playerid, -( g_houseInteriors[ intid ] [ E_COST ] ) );

					    if ( intid != 0 )
							SendServerMessage( playerid, "You have purchased a %s for "COL_GOLD"%s"COL_WHITE". This has been applied to the House ID %d.", g_houseInteriors[ intid ] [ E_NAME ], cash_format( g_houseInteriors[ intid ] [ E_COST ] ), houseid );
						else
						    SendServerMessage( playerid, "You have successfully reset your interior to the default interior." );

		                destroyAllFurniture( houseid );
						FillHomeWithFurniture( houseid, intid );
						g_houseData[ houseid ] [ E_TX ] = g_houseInteriors[ intid ] [ E_EX ];
					    g_houseData[ houseid ] [ E_TY ] = g_houseInteriors[ intid ] [ E_EY ];
					    g_houseData[ houseid ] [ E_TZ ] = g_houseInteriors[ intid ] [ E_EZ ];
					    g_houseData[ houseid ] [ E_INTERIOR_ID ] = g_houseInteriors[ intid ] [ E_INTERIOR_ID ];
					    SetPlayerPos( playerid, g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ] );
					    SetPlayerInterior( playerid, g_houseInteriors[ intid ] [ E_INTERIOR_ID ] );
					    DestroyDynamicCP( g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] );
					    g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ], 1.0, g_houseData[ houseid ] [ E_WORLD ], g_houseData[ houseid ] [ E_INTERIOR_ID ], -1, 50.0 );
						format( szBigString, sizeof( szBigString ), "UPDATE HOUSES SET TX=%f, TY=%f, TZ=%f, INTERIOR=%d WHERE ID=%d", g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ], g_houseData[ houseid ] [ E_INTERIOR_ID ], houseid );
						mysql_single_query( szBigString );
						DestroyDynamic3DTextLabel( g_houseData[ houseid ] [ E_LABEL ] [ 1 ] );
						g_houseData[ houseid ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, g_houseData[ houseid ] [ E_TX ], g_houseData[ houseid ] [ E_TY ], g_houseData[ houseid ] [ E_TZ ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ houseid ] [ E_WORLD ] );
						pauseToLoad( playerid );
					}
				}
				case 1:
				{
					if ( p_WantedLevel[ playerid ] ) {
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", "Purchase House Interior\nPreview House Interior", "Select", "Back" );
						return SendError( playerid, "This feature requires you not to have a wanted level." );
					}
					if ( ArePlayersInHouse( p_InHouse[ playerid ], playerid ) ) {
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", "Purchase House Interior\nPreview House Interior", "Select", "Back" );
						return SendError( playerid, "You cannot view a house interior if there are people inside the building." );
					}
					TogglePlayerControllable( playerid, 0 );
				    SetPlayerPos( playerid, g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ] );
				    SetPlayerInterior( playerid, g_houseInteriors[ intid ] [ E_INTERIOR_ID ] );
					InterpolateCameraPos( playerid, g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], 15000, CAMERA_MOVE );
					InterpolateCameraLookAt( playerid, g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, 15000, CAMERA_MOVE );
					SendServerMessage( playerid, "You are now previewing "COL_GREY"%s "COL_GOLD"%s"COL_WHITE". Press your enter key to stop.", g_houseInteriors[ intid ] [ E_NAME ], cash_format( g_houseInteriors[ intid ] [ E_COST ] ) );
					SetPVarInt( playerid, "viewing_houseints", 1 );
				}
			}
		}
		else ShowPlayerDialog( playerid, DIALOG_HOUSE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}House Interiors", szg_houseInteriors, "Select", "Back" );
	}
	else if ( dialogid == DIALOG_HOUSE_TITLE )
	{
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 )
				return SendError( playerid, "You're not inside any house." );

	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
				return SendError( playerid, "You are not the owner of this house." );

	        if ( ! ( 1 <= strlen( inputtext ) <= 30 ) )
				return ShowPlayerDialog( playerid, DIALOG_HOUSE_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Set House Title", ""COL_WHITE"Input the house title you want to change with:\n\n"COL_RED"Must be between 1 and 30 characters.", "Confirm", "Back" );

			if ( textContainsIP( inputtext ) )
				return SendError( playerid, "We do not condone advertising." );

			new houseid = p_InHouse[ playerid ];
			format( g_houseData[ houseid ] [ E_HOUSE_NAME ], 30, "%s", inputtext);
			mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE `HOUSES` SET `NAME`='%s' WHERE `ID`=%d", g_houseData[ houseid ] [ E_HOUSE_NAME ], p_InHouse[ playerid ] );
			mysql_single_query( szNormalString );
			format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" %s(%d)\n"COL_GOLD"Owner:"COL_WHITE" %s\n"COL_GOLD"Price:"COL_WHITE" %s", g_houseData[ houseid ] [ E_HOUSE_NAME ], houseid, g_houseData[ houseid ] [ E_OWNER ], cash_format( g_houseData[ houseid ] [ E_COST ] ) );
 			UpdateDynamic3DTextLabelText( g_houseData[ houseid ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );
 			SendServerMessage( playerid, "You have successfully changed the name of your house." );
 			cmd_h( playerid, "config" );
	    }
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_PW && response )
	{
		new i = p_PasswordedHouse[ playerid ];
		if ( !strlen( inputtext ) || strlen( inputtext ) > 4 || strmatch( inputtext, "N/A" ) || !strmatch( inputtext, g_houseData[ i ] [ E_PASSWORD ] ) ) ShowPlayerDialog( playerid, DIALOG_HOUSE_PW, DIALOG_STYLE_PASSWORD, "{FFFFFF}House Authentication", ""COL_GREEN"This house is password locked!\n"COL_WHITE"You may only enter this house if you enter the correct password.\n\n"COL_RED"Incorrect Password!", "Enter", "Cancel" );
		else
		{
			if ( !IsPlayerInRangeOfPoint( playerid, 3.0, g_houseData[ i ] [ E_EX ], g_houseData[ i ] [ E_EY ], g_houseData[ i ] [ E_EZ ] ) ) return SendError( playerid, "You are not near the house entrance!" );
			SendServerMessage( playerid, "Password correct. Access has been granted." );
			p_InHouse[ playerid ] = i;
			UpdatePlayerEntranceExitTick( playerid );
			SetPlayerPos( playerid, g_houseData[ i ] [ E_TX ], g_houseData[ i ] [ E_TY ], g_houseData[ i ] [ E_TZ ] );
		  	SetPlayerVirtualWorld( playerid, g_houseData[ i ] [ E_WORLD ] );
			SetPlayerInterior( playerid, g_houseData[ i ] [ E_INTERIOR_ID ] );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:bruteforce( playerid, params[ ] )
{
	/* ** ANTI SPAM ** */
    if ( GetPVarInt( playerid, "last_bruteforce" ) > g_iTime ) return SendError( playerid, "You must wait 30 seconds before using this command again." );
    /* ** END OF ANTI SPAM ** */

	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This command is restricted for F.B.I agents." );
	if ( !( p_inFBI{ playerid } == true && p_inArmy{ playerid } == false && p_inCIA{ playerid } == false ) ) return SendError( playerid, "This command is restricted for F.B.I agents." );

	foreach ( new i : houses )
	{
		if ( IsPlayerInDynamicCP( playerid, g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] ) && !strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
		{
			if ( g_iTime > g_houseData[ i ] [ E_CRACKED_TS ] && g_houseData[ i ] [ E_CRACKED ] ) g_houseData[ i ] [ E_CRACKED ] = false; // The Virus Is Disabled.

			if ( g_houseData[ i ] [ E_CRACKED_WAIT ] > g_iTime )
			    return SendError( playerid, "This house had its password recently had a cracker run through. Come back later." );

			if ( strmatch( g_houseData[ i ] [ E_PASSWORD ], "N/A" ) )
			    return SendError( playerid, "This house does not require cracking as it doesn't have a password." );

			if ( g_houseData[ i ] [ E_CRACKED ] || g_houseData[ i ] [ E_BEING_CRACKED ] )
			    return SendError( playerid, "This house is currently being cracked or is already cracked." );

	        if ( IsHouseOnFire( i ) )
		       	return SendError( playerid, "This house is on fire, you cannot bruteforce it!" ), 1;

            g_houseData[ i ] [ E_BEING_CRACKED ] = true;
            p_HouseCrackingPW[ playerid ] = i;
            SetPVarInt( playerid, "last_bruteforce", g_iTime + 30 );
			ShowProgressBar( playerid, "Brute Forcing Password", PROGRESS_BRUTEFORCE, 5000, COLOR_BLUE );
            return 1;
		}
	}
	SendError( playerid, "You are not standing in any house checkpoint." );
	return 1;
}

CMD:h( playerid, params[ ] )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	if ( ! p_VIPLevel[ playerid ] && p_OwnedHouses[ playerid ] > GetPlayerHouseSlots( playerid ) && ! strmatch( params, "sell" ) ) {
		ResetSpawnLocation( playerid );
		return SendError( playerid, "Please renew your V.I.P or sell this home to match your house allocated limit (/h sell)." );
	}

	new
	    ID = p_InHouse[ playerid ],
	    query[ 140 ]
	;
	if ( strmatch( params, "spawn" ) )
	{
		SendServerMessage( playerid, "We have changed the command to simply "COL_GREY"/spawn"COL_WHITE"." );
		return ShowPlayerSpawnMenu( playerid );
	}
	else if ( strmatch( params, "config" ) )
	{
		if ( ID == -1 ) return SendError( playerid, "You're not in any house." );
		else if ( !strmatch( g_houseData[ ID ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
		else
		{
			szBigString = ""COL_WHITE"Option\t"COL_WHITE"Current Value\n";

			format(szBigString, sizeof( szBigString ), "%sSet House Title\t%s\nUpgrade Interior\t\nSet House Password\t"COL_GREY"%s\nWeapon Storage\t\nFurniture\t\n",
				szBigString,
				g_houseData[ ID ] [ E_HOUSE_NAME ],
				g_houseData[ ID ] [ E_PASSWORD ] );

		    ShowPlayerDialog( playerid, DIALOG_HOUSE_CONFIG, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}House Configuration", szBigString, "Select", "Cancel" );
		    //ShowPlayerDialog( playerid, DIALOG_HOUSE_CONFIG, DIALOG_STYLE_LIST, "{FFFFFF}House Configuration", "Set House Title\nUpgrade Interior\nSet House Password\nWeapon Storage\nFurniture", "Select", "Cancel" );
		}
		return 1;
	}
	else if ( strmatch( params, "buy" ) )
	{
		if ( p_OwnedHouses[ playerid ] >= GetPlayerHouseSlots( playerid ) ) return SendError( playerid, "You cannot purchase any more houses, you've reached the limit." );
		if ( GetPlayerScore( playerid ) < 200 ) return SendError( playerid, "You need at least 200 score to buy a house." );

		foreach ( new i : houses )
		{
			if ( IsPlayerInDynamicCP( playerid, g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] ) || ( ID != -1 && ID == i ) )
			{
			    if ( strmatch( g_houseData[ i ] [ E_OWNER ], "No-one" ) )
			    {
			        if ( GetPlayerCash( playerid ) < g_houseData[ i ] [ E_COST ] )
						return SendError( playerid, "You don't have enough money to purchase this house." );

					if ( g_houseData[ i ] [ E_COST ] == 1337 && !p_VIPLevel[ playerid ] )
						return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );

					GivePlayerCash( playerid, -( g_houseData[ i ] [ E_COST ] ) );
					autosaveStart( playerid, true ); // force_save
					SendServerMessage( playerid, "You have bought this home for "COL_GOLD"%s"COL_WHITE"!", cash_format( g_houseData[ i ] [ E_COST ] ) );
                    SetHouseOwner( i, ReturnPlayerName( playerid ) );

					p_OwnedHouses[ playerid ] ++;
					return 1;
				}
			    else return SendError( playerid, "This house isn't for sale." );
			}
		}
		return SendError( playerid, "You are not around any house entrances." );
	}
	else if ( strmatch( params, "sell" ) )
	{
	    if ( ID == -1 ) return SendError( playerid, "You're not in any house." );
		else if ( !strmatch( g_houseData[ ID ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
		else
		{
			format( szBigString, sizeof( szBigString ), "[SELL] [%s] %s | %s | %d\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), g_houseData[ ID ][ E_OWNER ], ID );
		    AddFileLogLine( "log_houses.txt", szBigString );
			p_OwnedHouses[ playerid ] --;
			format( g_houseData[ ID ] [ E_PASSWORD ], 4, "N/A" );
			format( g_houseData[ ID ] [ E_OWNER ], 7, "No-one" );
			format( g_houseData[ ID ] [ E_HOUSE_NAME ], 5, "Home" );
			for( new i; i < MAX_HOUSE_WEAPONS; i++ ) { g_HouseWeapons[ ID ] [ i ] = 0, g_HouseWeaponAmmo[ ID ] [ i ] = -1; }
			SaveHouseWeaponStorage( ID );
			GivePlayerCash( playerid, ( g_houseData[ ID ] [ E_COST ] / 2 ) );
			destroyAllFurniture( ID );
			FillHomeWithFurniture( ID, 0 );
			g_houseData[ ID ] [ E_TX ] = g_houseInteriors[ 0 ] [ E_EX ];
			g_houseData[ ID ] [ E_TY ] = g_houseInteriors[ 0 ] [ E_EY ];
			g_houseData[ ID ] [ E_TZ ] = g_houseInteriors[ 0 ] [ E_EZ ];
			g_houseData[ ID ] [ E_INTERIOR_ID ] = 2;
			format( query, sizeof( query ), "UPDATE HOUSES SET OWNER='No-one',PASSWORD='N/A',NAME='Home',TX=%f,TY=%f,TZ=%f,INTERIOR=%d WHERE ID=%d", g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], g_houseData[ ID ] [ E_INTERIOR_ID ], ID );
		    mysql_single_query( query );
			format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" Home(%d)\n"COL_GOLD"Owner:"COL_WHITE" No-one\n"COL_GOLD"Price:"COL_WHITE" %s", ID, cash_format( g_houseData[ ID ] [ E_COST ] ) );
			UpdateDynamic3DTextLabelText( g_houseData[ ID ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );
			DestroyDynamic3DTextLabel( g_houseData[ ID ] [ E_LABEL ] [ 1 ] );
			g_houseData[ ID ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ ID ] [ E_WORLD ] );
			DestroyDynamicCP( g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] );
			g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 1.0, g_houseData[ ID ] [ E_WORLD ], g_houseData[ ID ] [ E_INTERIOR_ID ], -1, 50.0 );
			SetPlayerPos( playerid, g_houseData[ ID ] [ E_EX ], g_houseData[ ID ] [ E_EY ], g_houseData[ ID ] [ E_EZ ] );
			DestroyDynamicMapIcon( g_houseData[ ID ] [ E_MAP_ICON ] );
			SetPlayerInterior( playerid, 0 );
			SetPlayerVirtualWorld( playerid, 0 );
			SendServerMessage( playerid, "You have successfully sold your house for "COL_GOLD"%s", cash_format( ( g_houseData[ ID ] [ E_COST ] / 2 ) ) );
		}
		return 1;
	}
	else if ( strmatch( params, "offer cancel" ) )
	{
		new
			bool: bResults = false;

		foreach(new i : Player)
		{
			if ( p_HouseOfferer[ i ] == playerid )
			{
				bResults = true;
				p_HouseOfferer		[ i ] = INVALID_PLAYER_ID;
				p_HouseOfferTicks	[ i ] = 0;
				p_HouseSellingID	[ i ] = 0;
				p_HouseSellingPrice	[ i ] = 0;
			}
		}

		if ( bResults )
			return SendServerMessage( playerid, "You have successfully canceled all house offers you have made to players." );

		return SendError( playerid, "You have not made any house offers to anybody." );
	}
	else if ( strmatch( params, "offer take" ) )
	{
		new
			houseid = p_HouseSellingID[ playerid ],
			sellerid = p_HouseOfferer[ playerid ],
			sellingprice = p_HouseSellingPrice[ playerid ]
		;

		if ( !IsPlayerConnected( sellerid ) ) SendError( playerid, "The person who offered you a house is no longer online." );
		else if ( p_HouseOfferTicks[ playerid ] < g_iTime ) SendError( playerid, "This house offer has expired %d seconds ago.", g_iTime - p_HouseOfferTicks[ playerid ] );
		else if ( GetPlayerCash( playerid ) < p_HouseSellingPrice[ playerid ] ) SendError( playerid, "You do not have enough money to accept this offer (%s).", cash_format( p_HouseSellingPrice[ playerid ] ) );
		else if ( g_houseData[ houseid ] [ E_COST ] <= 1337 && !p_VIPLevel[ playerid ] ) SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
		else if ( p_OwnedHouses[ playerid ] >= GetPlayerHouseSlots( playerid ) ) SendError( playerid, "You cannot purchase any more houses, you've reached the limit." );
		else
		{
			format( szBigString, sizeof( szBigString ), "[SELL TO] [%s] %s | %s | %s | %d\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), ReturnPlayerName( sellerid ), cash_format( sellingprice ), houseid );
		    AddFileLogLine( "log_houses.txt", szBigString );

			p_OwnedHouses[ sellerid ] --;
			p_OwnedHouses[ playerid ] ++;

		    // destroyAllFurniture( houseid );
			SetHouseOwner( houseid, ReturnPlayerName( playerid ), .buyerid = playerid );

			GivePlayerCash( playerid, -sellingprice );
			GivePlayerCash( sellerid, sellingprice );

			SendServerMessage( sellerid, "You have successfully sold your house for "COL_GOLD"%s"COL_WHITE" to %s(%d)!", cash_format( p_HouseSellingPrice[ playerid ] ), ReturnPlayerName( playerid ), playerid );
			SendServerMessage( playerid, "You have successfully bought %s(%d)'s home for "COL_GOLD"%s"COL_WHITE"!", ReturnPlayerName( sellerid ), sellerid, cash_format( p_HouseSellingPrice[ playerid ] ) );
		}
		return ( p_HouseOfferer[ playerid ] = INVALID_PLAYER_ID ), ( p_HouseOfferTicks[ playerid ] = 0 ), 1;
	}
	else if ( !strcmp( params, "offer", false, 5 ) )
	{
	    new offerid, price;

	    if ( ID == -1 ) return SendError( playerid, "You're not in any house." );
		else if ( !strmatch( g_houseData[ ID ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
	    else if ( sscanf( params[ 6 ], "ud", offerid, price ) ) return SendUsage( playerid, "/h offer [PLAYER_ID] [PRICE]" );
	    else if ( !IsPlayerConnected( offerid ) ) return SendError( playerid, "This player is not connected." );
	    else if ( offerid == playerid ) return SendError( playerid, "You cannot make a house offer to yourself." );
	    else if ( price > 30000000 ) return SendError( playerid, "The maximum amount you can sell a house for is $30,000,000." );
	    else if ( price < g_houseData[ ID ] [ E_COST ] / 2 ) return SendError( playerid, "You cannot sell your house to somebody for less than half its cost." );
		else if ( GetDistanceBetweenPlayers( playerid, offerid ) > 4.0 ) return SendError( playerid, "You cannot send offers to players who are not near you." );
		else if ( p_HouseOfferTicks[ offerid ] > g_iTime ) return SendError( playerid, "Please wait %d seconds to make an house price offer to this player again.", p_HouseOfferTicks[ offerid ] - g_iTime );
		else if ( g_houseData[ ID ] [ E_COST ] <= 1337 && !p_VIPLevel[ offerid ] ) return SendError( playerid, "You cannot offer V.I.P homes to sell to regular players." );
		else if ( p_OwnedHouses[ offerid ] >= GetPlayerHouseSlots( offerid ) ) return SendError( playerid, "This player cannot purchase any more houses, they have reached the limit." );
		else
	    {
	    	// Cannot sell to non vip vip homes k
			p_HouseOfferer[ offerid ] = playerid;
			p_HouseOfferTicks[ offerid ] = g_iTime + 15;
			p_HouseSellingID[ offerid ] = ID;
			p_HouseSellingPrice[ offerid ] = price;
			SendServerMessage( offerid, "%s(%d) wishes to offer his house (id %d) for %s to you. Use "COL_GREY"/h offer take"COL_WHITE" to take the offer.", ReturnPlayerName( playerid ), playerid, ID, cash_format( price ) );
			SendServerMessage( playerid, "You have offered %s(%d) %s for your house (id %d), cancel the offer with "COL_GREY"/h offer cancel"COL_WHITE".", ReturnPlayerName( offerid ), offerid, cash_format( price ), ID );
	    }
	    return 1;
	}
	return SendUsage( playerid, "/h [CONFIG/BUY/SELL/OFFER/OFFER TAKE/OFFER CANCEL]" );
}

/* ** SQL Threads ** */
thread OnHouseLoad( )
{
	new
		rows, fields, i = -1,
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		static weapon_info[ 40 ], house_name[ 30 ], password[ 5 ], owner[ 24 ];

		while( ++ i < rows )
		{
			// set name., owner, password again (less memory)
			cache_get_field_content( i, "NAME", house_name, dbHandle, 30 );
			cache_get_field_content( i, "PASSWORD", password, dbHandle, 5 );
			cache_get_field_content( i, "OWNER", owner, dbHandle, 24 );

			// create home handle
			new house_sql_id = cache_get_field_content_int( i, "ID", dbHandle );
			new handle = CreateHouse( house_name,
				cache_get_field_content_int( i, "COST", dbHandle ),
				cache_get_field_content_float( i, "EX", dbHandle ),
				cache_get_field_content_float( i, "EY", dbHandle ),
				cache_get_field_content_float( i, "EZ", dbHandle ),
				cache_get_field_content_float( i, "TX", dbHandle ),
				cache_get_field_content_float( i, "TY", dbHandle ),
				cache_get_field_content_float( i, "TZ", dbHandle ),
				cache_get_field_content_int( i, "INTERIOR", dbHandle ),
				password, owner, house_sql_id
			);

			if ( handle != ITER_NONE ) {
				// store weapon information
				cache_get_field_content( i, "WEAPONS", weapon_info ), sscanf( weapon_info, "p<.>e<ddddddd>", g_HouseWeapons[ handle ] );
				cache_get_field_content( i, "AMMO", weapon_info ), sscanf( weapon_info, "p<.>e<ddddddd>", g_HouseWeaponAmmo[ handle ] );
			}
		}
	}
	printf( "[HOUSES]: %d houses have been loaded. (Tick: %dms)", rows, GetTickCount( ) - loadingTick );

	// Make Lorenc the owner of unowned VIP houses
	foreach ( new houseid : houses ) if ( g_houseData[ houseid ] [ E_COST ] < 10000 ) {
		if ( strmatch( g_houseData[ houseid ] [ E_OWNER ], "No-one" ) ) {
			SetHouseOwner( houseid, "Lorenc" );
		}
	}

	// The server crashes when the fires aren't correctly loaded.
	CreateFire( );
	return 1;
}

/* ** Functions ** */
stock CreateHouse( house_name[ 30 ], cost, Float: eX, Float: eY, Float: eZ, Float: tX = H_DEFAULT_X, Float: tY = H_DEFAULT_Y, Float: tZ = H_DEFAULT_Z, interior = 2, password[ 5 ] = "N/A", owner[ 24 ] = "No-one", sql_id = ITER_NONE )
{
	new
		hID = ( 0 <= sql_id < MAX_HOUSES ) ? sql_id : Iter_Free( houses );

	if ( Iter_Contains( houses, sql_id ) )
		hID = ITER_NONE;

	if ( hID != ITER_NONE )
	{
		Iter_Add( houses, hID );

		// set house name, password, owner
		format( g_houseData[ hID ] [ E_HOUSE_NAME ], 30, "%s", house_name );
		format( g_houseData[ hID ] [ E_PASSWORD ], 5, "%s", password );
		format( g_houseData[ hID ] [ E_OWNER ], 24, "%s", owner );

		// set home variables
		g_houseData[ hID ] [ E_COST ] = cost;
		g_houseData[ hID ] [ E_EX ] = eX;
		g_houseData[ hID ] [ E_EY ] = eY;
		g_houseData[ hID ] [ E_EZ ] = eZ;
		g_houseData[ hID ] [ E_TX ] = tX;
		g_houseData[ hID ] [ E_TY ] = tY;
		g_houseData[ hID ] [ E_TZ ] = tZ;
		g_houseData[ hID ] [ E_INTERIOR_ID ] = interior;
		g_houseData[ hID ] [ E_WORLD ] = ( hID + MAX_HOUSES );

		// reset weapons (in case)
		for( new i; i < MAX_HOUSE_WEAPONS; i++ ) {
		    g_HouseWeapons[ hID ] [ i ] = 0, g_HouseWeaponAmmo[ hID ] [ i ] = -1;
		}

		// prefurnish home
		if ( sql_id == ITER_NONE ) FillHomeWithFurniture( hID, 0 );

		// set global
		g_houseData[ hID ] [ E_MAP_ICON ] = strmatch( owner, "No-one" ) ? CreateDynamicMapIcon( eX, eY, eZ, 31, 0, -1, -1, -1, HOUSE_MAPICON_RADIUS ) : -1;

		g_houseData[ hID ] [ E_CHECKPOINT ] [ 0 ] = CreateDynamicCP( eX, eY, eZ, 1.0, -1, 0, -1, 100.0 );
		g_houseData[ hID ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( tX, tY, tZ, 1.0, g_houseData[ hID ] [ E_WORLD ], g_houseData[ hID ] [ E_INTERIOR_ID ], -1, 100.0 );

		format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" %s(%d)\n"COL_GOLD"Owner:"COL_WHITE" %s\n"COL_GOLD"Price:"COL_WHITE" %s", g_houseData[ hID ] [ E_HOUSE_NAME ], hID, g_houseData[ hID ] [ E_OWNER ], cash_format( cost ) );

	    g_houseData[ hID ] [ E_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( szBigString, COLOR_WHITE, eX, eY, eZ, 20.0 );
		g_houseData[ hID ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, tX, tY, tZ, 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ hID ] [ E_WORLD ] );

		// insert if non existant prior
		if ( sql_id == ITER_NONE ) {
			format( szBigString, sizeof( szBigString ), "INSERT INTO `HOUSES` VALUES (%d,'Home','No-one',%d,%f,%f,%f,%f,%f,%f,%d,'N/A','0.0.0.0.0.0.0.','-1.-1.-1.-1.-1.-1.-1.')", hID, cost, eX, eY, eZ, tX, tY, tZ, interior );
			mysql_single_query( szBigString );
		}
	}
	return hID;
}

stock DestroyHouse( houseid )
{
	if ( ! Iter_Contains( houses, houseid ) )
	    return 0;

	new
	    query[ 40 ],
		playerid = GetPlayerIDFromName( g_houseData[ houseid ] [ E_OWNER ] )
	;

	if ( IsPlayerConnected( playerid ) )
	{
	    SendClientMessage( playerid, -1, ""COL_PINK"[HOUSE]"COL_WHITE" One of your houses has been destroyed.");
		p_OwnedHouses[ playerid ] --;
	}

	format( query, sizeof( query ), "DELETE FROM HOUSES WHERE ID=%d", houseid );
	mysql_single_query( query );
    destroyAllFurniture( houseid );
	g_houseData[ houseid ] [ E_HOUSE_NAME ] [ 0 ] = '\0';
	g_houseData[ houseid ] [ E_OWNER ] [ 0 ] = '\0';
	DestroyDynamicMapIcon( g_houseData[ houseid ] [ E_MAP_ICON ] );
	DestroyDynamicCP( g_houseData[ houseid ] [ E_CHECKPOINT ] [ 0 ] );
	DestroyDynamicCP( g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] );
	DestroyDynamic3DTextLabel( g_houseData[ houseid ] [ E_LABEL ] [ 0 ] );
	DestroyDynamic3DTextLabel( g_houseData[ houseid ] [ E_LABEL ] [ 1 ] );
	Iter_Remove( houses, houseid );
	return 1;
}

stock SetHouseForAuction( ID )
{
	if ( ID == -1 )
		return 0;

	if ( ! Iter_Contains( houses, ID ) )
	    return 0;

	new
	    query[ 128 ],
		player = GetPlayerIDFromName( g_houseData[ ID ] [ E_OWNER ] )
	;

	if ( IsPlayerConnected( player ) )
	{
	    SendClientMessage( player, -1, ""COL_PINK"[HOUSE]"COL_WHITE" One of your houses has been taken for auction.");
		p_OwnedHouses[ player ] --;
	}
	for( new i; i < MAX_HOUSE_WEAPONS; i++ ) { g_HouseWeapons[ ID ] [ i ] = 0, g_HouseWeaponAmmo[ ID ] [ i ] = -1; }
	format( g_houseData[ ID ] [ E_PASSWORD ], 4, "N/A" );
	format( g_houseData[ ID ] [ E_OWNER ], 7, "No-one" );
	format( g_houseData[ ID ] [ E_HOUSE_NAME ], 5, "Home" );
	g_houseData[ ID ] [ E_TX ] = g_houseInteriors[ 0 ] [ E_EX ];
	g_houseData[ ID ] [ E_TY ] = g_houseInteriors[ 0 ] [ E_EY ];
	g_houseData[ ID ] [ E_TZ ] = g_houseInteriors[ 0 ] [ E_EZ ];
	g_houseData[ ID ] [ E_INTERIOR_ID ] = 2;
	destroyAllFurniture( ID );
	FillHomeWithFurniture( ID, 0 );
	format( query, sizeof( query ), "UPDATE HOUSES SET OWNER='No-one',PASSWORD='N/A',NAME='Home',TX=%f,TY=%f,TZ=%f,INTERIOR=%d WHERE ID=%d", g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], g_houseData[ ID ] [ E_INTERIOR_ID ], ID );
    mysql_single_query( query );
	format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" Home(%d)\n"COL_GOLD"Owner:"COL_WHITE" No-one\n"COL_GOLD"Price:"COL_WHITE" %s", ID, cash_format( g_houseData[ ID ] [ E_COST ] ) );
	UpdateDynamic3DTextLabelText( g_houseData[ ID ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString);
	DestroyDynamic3DTextLabel( g_houseData[ ID ] [ E_LABEL ] [ 1 ] );
	g_houseData[ ID ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ ID ] [ E_WORLD ] );
	DestroyDynamicCP( g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] );
	g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 1.0, g_houseData[ ID ] [ E_WORLD ], g_houseData[ ID ] [ E_INTERIOR_ID ], -1, 50.0 );
	DestroyDynamicMapIcon( g_houseData[ ID ] [ E_MAP_ICON ] );
	g_houseData[ ID ] [ E_MAP_ICON ] = CreateDynamicMapIcon( g_houseData[ ID ] [ E_EX ], g_houseData[ ID ] [ E_EY ], g_houseData[ ID ] [ E_EZ ], 31, 0, -1, -1, -1, HOUSE_MAPICON_RADIUS );
	return 1;
}

stock SetHouseOwner( houseid, szOwner[ MAX_PLAYER_NAME ], buyerid = INVALID_PLAYER_ID )
{
	if ( ! Iter_Contains( houses, houseid ) || isnull( szOwner ) )
		return 0;

	new
		query[ 128 ]
	;
	format( g_houseData[ houseid ] [ E_OWNER ], 24, "%s", szOwner );

	format( query, sizeof( query ), "UPDATE HOUSES SET OWNER='%s' WHERE ID=%d", mysql_escape( szOwner ), houseid );
	mysql_single_query( query );

	// transfer furniture to account
	if ( buyerid != INVALID_PLAYER_ID ) {
		mysql_single_query( sprintf( "UPDATE `FURNITURE` SET `OWNER`=%d WHERE `HOUSE_ID`=%d", p_AccountID[ buyerid ], houseid ) );
	}

	DestroyDynamicMapIcon( g_houseData[ houseid ] [ E_MAP_ICON ] );
	format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" Home(%d)\n"COL_GOLD"Owner:"COL_WHITE" %s\n"COL_GOLD"Price:"COL_WHITE" %s", houseid, g_houseData[ houseid ] [ E_OWNER ], cash_format( g_houseData[ houseid ] [ E_COST ] ) );
 	UpdateDynamic3DTextLabelText( g_houseData[ houseid ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString);
	return 1;
}

stock SwitchHouseOwners( ID, playerid, buyerid )
{
	if ( IsPlayerConnected( playerid ) )
	{
		p_OwnedHouses[ playerid ] --;
		SetPlayerInterior( playerid, 0 );
		SetPlayerVirtualWorld( playerid, 0 );
		SendServerMessage( playerid, "You have successfully sold your house for "COL_GOLD"%s", cash_format( ( g_houseData[ ID ] [ E_COST ] / 2 ) ) );
		SetPlayerPos( playerid, g_houseData[ ID ] [ E_EX ], g_houseData[ ID ] [ E_EY ], g_houseData[ ID ] [ E_EZ ] );
	}

	strcpy( g_houseData[ ID ] [ E_PASSWORD ], "N/A" );
	strcpy( g_houseData[ ID ] [ E_HOUSE_NAME ], "Home" );
	format( g_houseData[ ID ] [ E_OWNER ], 7, "%s", ReturnPlayerName( buyerid ) );

	format( szBigString, sizeof( szBigString ), "UPDATE HOUSES SET OWNER='%s',PASSWORD='N/A',NAME='Home' WHERE ID=%d", mysql_escape( ReturnPlayerName( buyerid ) ) , ID );
    mysql_single_query( szBigString );

	format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" Home(%d)\n"COL_GOLD"Owner:"COL_WHITE" No-one\n"COL_GOLD"Price:"COL_WHITE" %s", ID, cash_format( g_houseData[ ID ] [ E_COST ] ) );
	UpdateDynamic3DTextLabelText( g_houseData[ ID ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );

	DestroyDynamic3DTextLabel( g_houseData[ ID ] [ E_LABEL ] [ 1 ] );
	g_houseData[ ID ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ ID ] [ E_WORLD ] );

	DestroyDynamicCP( g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] );
	g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 1.0, g_houseData[ ID ] [ E_WORLD ], g_houseData[ ID ] [ E_INTERIOR_ID ], -1, 50.0 );

	DestroyDynamicMapIcon( g_houseData[ ID ] [ E_MAP_ICON ] );
}

stock GetPlayerOwnedHouses( playerid )
{
	new
		count = 0;

	foreach ( new i : houses ) if ( IsPlayerHomeOwner( playerid, i ) ) {
		count ++;
	}
	return count;
}

stock ShowHouseWeaponStorage( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

    new id = p_InHouse[ playerid ];
	if ( id == -1 ) return SendError( playerid, "You're not inside any house." );
	if ( !strmatch( g_houseData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "You are not the owner of this house." );
    szLargeString[ 0 ] = '\0';
    for( new i = 0; i < MAX_HOUSE_WEAPONS; i++ )
    {
		if ( g_HouseWeapons[ id ] [ i ] != 0 )
			format( szLargeString, sizeof( szLargeString ), "%s%s%s(%d)\n", szLargeString, i > 2 ? (""#COL_GOLD"") : ("{FFFFFF}"), ReturnWeaponName( g_HouseWeapons[ id ] [ i ] ), g_HouseWeaponAmmo[ id ] [ i ] );
		else
			strcat( szLargeString, i > 2 ? ( ""COL_GOLD"Empty\n" ) : ( ""COL_WHITE"Empty\n" ) );

	}
	ShowPlayerDialog( playerid, DIALOG_HOUSE_WEAPONS, DIALOG_STYLE_LIST, "{FFFFFF}House Weapon Storage", szLargeString, "Withdraw", "Back" );
	return 1;
}

stock SaveHouseWeaponStorage( houseid )
{
	new szWeapon[ 21 ], szAmmo[ 50 ];
    for( new i; i < MAX_HOUSE_WEAPONS; i++ )
    {
        format( szWeapon, sizeof( szWeapon ), "%s%d.", szWeapon, g_HouseWeapons[ houseid ] [ i ] );
        format( szAmmo, sizeof( szAmmo ), "%s%d.", szAmmo, g_HouseWeaponAmmo[ houseid ] [ i ] );
	}
	format( szBigString, sizeof( szBigString ), "UPDATE `HOUSES` SET `WEAPONS`='%s',`AMMO`='%s' WHERE `ID`=%d", szWeapon, szAmmo, houseid );
	mysql_single_query( szBigString );
	return 1;
}

stock ArePlayersInHouse( houseid, owner )
{
	foreach ( new i : Player ) if ( i != owner )
	{
		if ( p_InHouse[ i ] == houseid )
		{
			if ( GetPlayerVirtualWorld( i ) == g_houseData[ houseid ] [ E_WORLD ] )
				return true;

			p_InHouse[ i ] = -1; // They're bugged probably
		}
	}
	return false;
}
