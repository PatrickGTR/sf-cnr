/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: apartments.inc
 * Purpose: apartment system for visage
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_VISAGE_APARTMENTS    	13
#define MAX_PASSCODE				5

// dialogs
// #define DIALOG_VISAGE_APTS 			17317
// #define DIALOG_VISAGE_APT_PW 		17318
// #define DIALOG_VISAGE_APT_CONFIG 	17319
// #define DIALOG_VISAGE_APT_TRANSFER	17320
// #define DIALOG_VISAGE_APT_TITLE		17321
// #define DIALOG_VISAGE_APT_PASSCODE	17322
// #define DIALOG_VISAGE_SPAWN			17333

/* ** Constants ** */
static const Float: VISAGE_APARTMENT_ENTRANCE[ 3 ] = { 2670.9922, 1637.9547, 1508.3590 };
static const Float: VISAGE_APARTMENT_EXIT[ 3 ] = { 1983.7786, 1909.4755, 84.3009 };

stock const VISAGE_APARTMENT_INT = 0;
stock const VISAGE_APARTMENT_WORLD[ 13 ] = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 };

/* ** Variables ** */
enum E_APARTMENT_DATA
{
	E_SQL_ID,				E_OWNER_ID,

	E_WORLD,				E_TITLE[ 30 ], 			E_PASSCODE[ MAX_PASSCODE ],
	bool: E_GAMBLING,		E_EXIT_CP,				E_OWNER_NAME[ MAX_PLAYER_NAME ]
};

new
	g_VisageApartmentData        	[ MAX_VISAGE_APARTMENTS ] [ E_APARTMENT_DATA ],
	Iterator: visageapartments 		< MAX_VISAGE_APARTMENTS >,
	g_entranceCheckpoint 			= -1
;

/* ** Functions ** */
thread OnVisageApartmentLoad( )
{
	new
		i, rows, fields;

	cache_get_data( rows, fields );
	if ( rows )
	{
		for ( i = 0; i < rows; i ++ )
		{
			new
				handle = Iter_Free( visageapartments );

			if ( handle != ITER_NONE )
			{
				// set variables
				g_VisageApartmentData[ handle ] [ E_SQL_ID ] = cache_get_field_content_int( i, "ID", dbHandle );
				g_VisageApartmentData[ handle ] [ E_OWNER_ID ] = cache_get_field_content_int( i, "OWNER_ID", dbHandle );
				g_VisageApartmentData[ handle ] [ E_WORLD ] = cache_get_field_content_int( i, "WORLD", dbHandle );
				cache_get_field_content( i, "TITLE", g_VisageApartmentData[ handle ] [ E_TITLE ], dbHandle, 30 );
				cache_get_field_content( i, "OWNER", g_VisageApartmentData[ handle ] [ E_OWNER_NAME ], dbHandle, MAX_PLAYER_NAME );
				cache_get_field_content( i, "PASSCODE", g_VisageApartmentData[ handle ] [ E_PASSCODE ], dbHandle, MAX_PASSCODE );

				// erase a null password
				if ( strmatch( g_VisageApartmentData[ handle ] [ E_PASSCODE ], "NULL" ) ) {
					g_VisageApartmentData[ handle ] [ E_PASSCODE ] [ 0 ] = '\0';
				}

				// appearance
				CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, VISAGE_APARTMENT_EXIT[ 0 ], VISAGE_APARTMENT_EXIT[ 1 ], VISAGE_APARTMENT_EXIT[ 2 ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, -1, g_VisageApartmentData[ handle ] [ E_WORLD ] );
				g_VisageApartmentData[ handle ] [ E_EXIT_CP ] = CreateDynamicCP( VISAGE_APARTMENT_EXIT[ 0 ], VISAGE_APARTMENT_EXIT[ 1 ], VISAGE_APARTMENT_EXIT[ 2 ], 1.0, .worldid = g_VisageApartmentData[ handle ] [ E_WORLD ], .streamdistance = 50.0 );

				// add to array
				Iter_Add( visageapartments, handle );
			}
			else print( "[VISAGE APARTMENT ERROR] Visage apartment limit has been breached." );
		}
		printf( "[VISAGE APARTMENTS]: %d apartments have been loaded.", i );
	}
}

/* ** Hooks ** */
hook OnGameModeInit( )
{
	// initialize objects
	InitializeCasinoApartments( );

	// query
	mysql_function_query( dbHandle, "SELECT u.`NAME` as `OWNER`, a.* FROM `VISAGE_APARTMENTS` a LEFT JOIN `USERS` u ON a.`OWNER_ID`=u.`ID`", true, "OnVisageApartmentLoad", "" );

	// create checkpoints
	CreateDynamic3DTextLabel( "[PRIVATE APARTMENTS]", COLOR_GOLD, VISAGE_APARTMENT_ENTRANCE[ 0 ], VISAGE_APARTMENT_ENTRANCE[ 1 ], VISAGE_APARTMENT_ENTRANCE[ 2 ], 20.0 );
	g_entranceCheckpoint = CreateDynamicCP( VISAGE_APARTMENT_ENTRANCE[ 0 ], VISAGE_APARTMENT_ENTRANCE[ 1 ], VISAGE_APARTMENT_ENTRANCE[ 2 ], 2.0, .streamdistance = 100.0 );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( CanPlayerExitEntrance( playerid ) ) {
		// enter the apartment
		if ( checkpointid == g_entranceCheckpoint ) {
			return ShowPlayerVisageApartments( playerid ), 1;
		}

		// exit the apartment
		foreach ( new handle : visageapartments ) {
			if ( checkpointid == g_VisageApartmentData[ handle ] [ E_EXIT_CP ] ) {
				pauseToLoad( playerid );
				UpdatePlayerEntranceExitTick( playerid );
				DeletePVar( playerid, "in_visage_apartment" );
				SetPlayerInterior( playerid, VISAGE_INTERIOR );
				SetPlayerVirtualWorld( playerid, VISAGE_WORLD );
				SetPlayerPos( playerid, VISAGE_APARTMENT_ENTRANCE[ 0 ], VISAGE_APARTMENT_ENTRANCE[ 1 ], VISAGE_APARTMENT_ENTRANCE[ 2 ] );
				return 1;
			}
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VISAGE_APTS && response )
	{
		new
			x = 0;

		foreach ( new handle : visageapartments )
		{
			if ( x == listitem )
			{
				new
					account_id = GetPlayerAccountID( playerid );

				if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] != account_id && ! isnull( g_VisageApartmentData[ handle ] [ E_PASSCODE ] ) ) {
					SetPVarInt( playerid, "visage_accessing_apt", handle );
					return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_PW, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartments -"COL_RED" Password Restricted", ""COL_WHITE"This apartment requires a passcode to access. Please enter it below.", "Access", "Back" );
				} else {
					SetPlayerToVisageApartment( playerid, handle );
				}
			}
			x ++;
		}
		return 1;
	}
	else if ( dialogid == DIALOG_VISAGE_APT_PW )
	{
		if ( ! response )
			return ShowPlayerVisageApartments( playerid );

		new
			handle = GetPVarInt( playerid, "visage_accessing_apt" );

		if ( ! Iter_Contains( visageapartments, handle ) )
			return SendError( playerid, "You have attempted to access an invalid apartment." );

		new
			passcode[ MAX_PASSCODE ];

		if ( sscanf( inputtext, "s["#MAX_PASSCODE"]", passcode ) ) return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_PW, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartments -"COL_RED" Password Restricted", ""COL_WHITE"This apartment requires a passcode to access. Please enter it below.", "Access", "Back" );
		else if ( ! strmatch( passcode, g_VisageApartmentData[ handle ] [ E_PASSCODE ] ) ) return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_PW, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartments -"COL_RED" Password Restricted", ""COL_WHITE"This apartment requires a passcode to access. Please enter it below.\n\n"COL_RED"Incorrect passcode! Access denied.", "Access", "Back" );
		else SetPlayerToVisageApartment( playerid, handle );
	}
	else if ( dialogid == DIALOG_VISAGE_APT_CONFIG && response )
	{
		new
			handle = GetPVarInt( playerid, "in_visage_apartment" );

		if ( ! Iter_Contains( visageapartments, handle ) )
			return SendError( playerid, "You have attempted to modify an invalid apartment." );

		if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] != GetPlayerAccountID( playerid ) )
			return SendError( playerid, "You are not the owner of this apartment." );

		switch ( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_TRANSFER, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter the player name or id of the user to transfer apartment ownership to:", "Transfer", "Back" );
			case 1: ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_TITLE, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter your new apartment title below:", "Edit", "Back" );
			case 2: ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_PASSCODE, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter your new apartment passcode below:", "Edit", "Back" );
		}
		return 1;
	}
	else if ( dialogid == DIALOG_VISAGE_APT_TRANSFER )
	{
		if ( ! response )
			return cmd_visage( playerid, "config" );

		new
			handle = GetPVarInt( playerid, "in_visage_apartment" );

		if ( ! Iter_Contains( visageapartments, handle ) )
			return SendError( playerid, "You have attempted to modify an invalid apartment." );

		if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] != GetPlayerAccountID( playerid ) )
			return SendError( playerid, "You are not the owner of this apartment." );

		new
			ownerid;

		if ( sscanf( inputtext, "u", ownerid ) ) return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_TRANSFER, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter the player name or id of the user to transfer apartment ownership to:\n\n"COL_RED"Invalid Player ID.", "Transfer", "Back" );
		else if ( ! IsPlayerConnected( ownerid ) || IsPlayerNPC( ownerid ) ) return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_TRANSFER, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter the player name or id of the user to transfer apartment ownership to:\n\n"COL_RED"Invalid Player ID.", "Transfer", "Back" );
		else
		{
			// set owner
			g_VisageApartmentData[ handle ] [ E_OWNER_ID ] = GetPlayerAccountID( ownerid );
			format( g_VisageApartmentData[ handle ] [ E_OWNER_NAME ], MAX_PLAYER_NAME, "%s", ReturnPlayerName( ownerid ) );

			// save to database
			mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE `VISAGE_APARTMENTS` SET `OWNER_ID`=%d WHERE `ID`=%d", g_VisageApartmentData[ handle ] [ E_OWNER_ID ], g_VisageApartmentData[ handle ] [ E_SQL_ID ] );
            mysql_single_query( szNormalString );

            // message
            return SendServerMessage( playerid, "Your apartment ownership has been transferred to "COL_GREY"%s"COL_WHITE".", ReturnPlayerName( ownerid ) );
		}
	}
	else if ( dialogid == DIALOG_VISAGE_APT_TITLE )
	{
		if ( ! response )
			return cmd_visage( playerid, "config" );

		new
			handle = GetPVarInt( playerid, "in_visage_apartment" );

		if ( ! Iter_Contains( visageapartments, handle ) )
			return SendError( playerid, "You have attempted to modify an invalid apartment." );

		if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] != GetPlayerAccountID( playerid ) )
			return SendError( playerid, "You are not the owner of this apartment." );

		// todo
		new
			title[ 30 ];

		if ( sscanf( inputtext, "S[30]", title ) ) return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_TITLE, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter your new apartment title below:\n\n"COL_RED"Must be between 3 and 30 characters.", "Edit", "Back" );
		else if ( ! ( 3 <= strlen( title ) < sizeof ( title ) - 1 ) )  return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_TITLE, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter your new apartment title below:\n\n"COL_RED"Must be between 3 and 30 characters.", "Edit", "Back" );
		else
		{
			// format title
			format( g_VisageApartmentData[ handle ] [ E_TITLE ], sizeof ( title ), "%s", title );

			// save to database
			mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE `VISAGE_APARTMENTS` SET `TITLE` = '%e' WHERE `ID`=%d", title, g_VisageApartmentData[ handle ] [ E_SQL_ID ] );
            mysql_single_query( szNormalString );

            // message
            return SendServerMessage( playerid, "Your apartment title is now: "COL_GREY"%s"COL_WHITE".", title );
		}
	}
	else if ( dialogid == DIALOG_VISAGE_APT_PASSCODE )
	{
		if ( ! response )
			return cmd_visage( playerid, "config" );

		new
			handle = GetPVarInt( playerid, "in_visage_apartment" );

		if ( ! Iter_Contains( visageapartments, handle ) )
			return SendError( playerid, "You have attempted to modify an invalid apartment." );

		if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] != GetPlayerAccountID( playerid ) )
			return SendError( playerid, "You are not the owner of this apartment." );

		if ( strlen( inputtext ) <= 0 )
		{
			// reset passcode
			g_VisageApartmentData[ handle ] [ E_PASSCODE ] = '\0';
            mysql_single_query( sprintf( "UPDATE `VISAGE_APARTMENTS` SET `PASSCODE`=NULL WHERE `ID`=%d", g_VisageApartmentData[ handle ] [ E_SQL_ID ] ) );
            return SendServerMessage( playerid, "Your apartment passcode has been reset.", g_VisageApartmentData[ handle ] [ E_PASSCODE ] );
		}
		else
		{
			new
				passcode;

			if ( sscanf( inputtext, "d", passcode ) ) return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_PASSCODE, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter your new apartment passcode below:\n\nEnter nothing to make it accessibly by everyone.\n\n"COL_RED"Passcode must be an integer between 0000 and 9999", "Edit", "Back" );
			else if ( ! ( 1000 <= passcode <= 9999 ) ) return ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_PASSCODE, DIALOG_STYLE_INPUT, ""COL_GOLD"Visage Apartment", ""COL_WHITE"Enter your new apartment passcode below:\n\nEnter nothing to make it accessibly by everyone.\n\n"COL_RED"Passcode must be an integer between 0000 and 9999", "Edit", "Back" );
			else
			{
				// set owner
				format( g_VisageApartmentData[ handle ] [ E_PASSCODE ], MAX_PASSCODE, "%d", passcode );

				// save to database
				mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE `VISAGE_APARTMENTS` SET `PASSCODE`='%e' WHERE `ID`=%d", g_VisageApartmentData[ handle ] [ E_PASSCODE ], g_VisageApartmentData[ handle ] [ E_SQL_ID ] );
	            mysql_single_query( szNormalString );

	            // message
	            return SendServerMessage( playerid, "Your apartment passcode has been set to "COL_GREY"%s"COL_WHITE".", g_VisageApartmentData[ handle ] [ E_PASSCODE ] );
			}
		}
	}
	else if ( dialogid == DIALOG_VISAGE_SPAWN )
	{
		if ( ! response )
			return ShowPlayerSpawnMenu( playerid );

		new
			x = 0;

		foreach ( new handle : visageapartments ) if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] == GetPlayerAccountID( playerid ) ) {
			if ( x == listitem ) {
				SetPlayerSpawnLocation( playerid, "VIZ", handle );
				SendServerMessage( playerid, "Visage apartment spawning has been set at "COL_GREY"%s"COL_WHITE".", g_VisageApartmentData[ handle ] [ E_TITLE ] );
				break;
			}
			x ++;
		}
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:visage( playerid, params[ ] )
{
	if ( strmatch( params, "config" ) )
	{
		new
			handle = GetPVarInt( playerid, "in_visage_apartment" );

		if ( ! Iter_Contains( visageapartments, handle ) ) return SendError( playerid, "You are not inside of any apartment" );
		else if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] != GetPlayerAccountID( playerid ) ) return SendError( playerid, "You do not own this apartment." );
		else {
			ShowPlayerDialog( playerid, DIALOG_VISAGE_APT_CONFIG, DIALOG_STYLE_LIST, ""COL_GOLD"Visage Apartment", "Transfer Ownership\nChange Apartment Title\nChange Apartment Passcode", "Select", "Close" );
		}
		return 1;
	}
	else if ( strmatch( params, "spawn" ) )
	{
		SendServerMessage( playerid, "We have changed the command to simply "COL_GREY"/spawn"COL_WHITE"." );
		return ShowPlayerSpawnMenu( playerid );
	}
	return SendUsage( playerid, "/visage [CONFIG/SPAWN]" );
}

/* ** Functions ** */
stock ShowPlayerVisageApartments( playerid )
{
	szLargeString = ""COL_WHITE"Owner\t"COL_WHITE"Title\n";
	foreach ( new handle : visageapartments ) {
		format( szLargeString, sizeof ( szLargeString ), "%s"COL_GREY"%s\t%s\n", szLargeString, g_VisageApartmentData[ handle ] [ E_OWNER_NAME ], g_VisageApartmentData[ handle ] [ E_TITLE ] );
	}
	ShowPlayerDialog( playerid, DIALOG_VISAGE_APTS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Visage Apartment", szLargeString, "Access", "Close" );
	return 1;
}

stock SetPlayerToVisageApartment( playerid, handle )
{
	// pause to load
	pauseToLoad( playerid );

	// so they dont instantly exit
	UpdatePlayerEntranceExitTick( playerid );

	// set player position
	SetPVarInt( playerid, "in_visage_apartment", handle );
	SetPlayerPos( playerid, VISAGE_APARTMENT_EXIT[ 0 ], VISAGE_APARTMENT_EXIT[ 1 ], VISAGE_APARTMENT_EXIT[ 2 ] );
	SetPlayerVirtualWorld( playerid, g_VisageApartmentData[ handle ] [ E_WORLD ] );
	SetPlayerInterior( playerid, VISAGE_APARTMENT_INT );

	// greeting
	SendServerMessage( playerid, "You are now inside of the "COL_GREY"%s"COL_WHITE".", g_VisageApartmentData[ handle ] [ E_TITLE ] );
}

// purpose: creates the player associated apartments
static stock InitializeCasinoApartments( )
{
	// Visage Apartment
	for ( new worldid = 0; worldid < sizeof( VISAGE_APARTMENT_WORLD ); worldid ++ ) {
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.661743, 1914.424804, 79.601951, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1994.449218, 1884.952758, 79.601951, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2004.888793, 1884.992919, 85.264495, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1982.909790, 1913.835815, 83.722656, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1995.665649, 1915.413085, 84.282653, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1979.837280, 1895.915283, 84.282653, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1993.625000, 1901.715698, 78.544792, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1991.619384, 1903.713989, 83.722656, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1993.621337, 1901.721191, 83.722656, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1982.911743, 1909.958740, 88.692619, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1991.613647, 1903.726074, 78.544792, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1982.909790, 1905.994750, 83.722656, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		CreateDynamicObject( 19273, 1983.361083, 1911.785644, 84.628677, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 948, 1983.600341, 1914.543701, 83.288696, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1981.448242, 1893.984619, 84.282653, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1993.454833, 1887.915161, 78.544792, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1993.446777, 1887.917114, 78.544792, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1981.458862, 1893.979125, 83.034774, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1981.468872, 1893.989135, 83.034774, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1993.621337, 1896.980468, 92.282592, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1986.308105, 1903.982910, 89.782653, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		CreateDynamicObject( 2137, 1980.834960, 1895.928710, 83.250732, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2305, 1980.834960, 1894.977783, 83.250732, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2137, 1980.834960, 1896.908447, 83.250732, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2135, 1980.834960, 1897.899414, 83.250732, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2135, 1980.834960, 1898.888183, 83.250732, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2137, 1981.825927, 1894.976562, 83.250732, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2137, 1982.806640, 1894.976562, 83.250732, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2136, 1984.778564, 1894.976562, 83.250732, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2137, 1984.776855, 1894.976562, 83.250732, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2137, 1980.834960, 1899.878417, 83.250732, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2137, 1980.834960, 1900.869384, 83.250732, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1985.770263, 1894.721191, 71.800598, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14424, "dr_gsnew", "mp_gs_kitchwall", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1985.770263, 1895.721191, 71.800598, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14424, "dr_gsnew", "mp_gs_kitchwall", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1985.770263, 1896.721191, 71.800598, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14424, "dr_gsnew", "mp_gs_kitchwall", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1985.770263, 1897.721191, 71.800598, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14424, "dr_gsnew", "mp_gs_kitchwall", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1985.770263, 1898.721191, 71.800598, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14424, "dr_gsnew", "mp_gs_kitchwall", -16 );
		CreateDynamicObject( 1739, 1986.796630, 1898.349609, 84.180664, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 1739, 1986.796630, 1897.000000, 84.170654, 0.000000, 0.000000, 12.399991, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 1739, 1986.796630, 1895.768798, 84.180664, 0.000000, 0.000000, -22.099998, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2139, 1984.762695, 1898.737792, 83.230712, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2139, 1984.762695, 1897.768066, 83.230712, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2139, 1984.762695, 1896.787353, 83.230712, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2139, 1984.762695, 1895.806640, 83.230712, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2139, 1984.762695, 1894.827148, 83.230712, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2140, 1982.893066, 1902.996582, 83.292724, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 2140, 1981.561767, 1902.996582, 83.292724, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11744, 1986.031005, 1898.284179, 84.330688, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11744, 1986.031005, 1897.073974, 84.330688, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11744, 1986.031005, 1895.782958, 84.330688, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11707, 1984.501708, 1897.107910, 84.120666, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19940, 1992.918212, 1900.991699, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19940, 1990.614746, 1903.052856, 84.790649, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19822, 1992.904296, 1900.227783, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19821, 1992.904296, 1900.448242, 84.790649, 0.000000, 0.000000, 43.199996, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19820, 1992.892089, 1900.710937, 84.790649, 0.000000, 0.000000, 43.199996, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19822, 1992.904296, 1901.708496, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19824, 1992.904296, 1901.508300, 84.800659, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19822, 1989.802978, 1903.079833, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19824, 1990.043212, 1903.019775, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19820, 1990.343505, 1903.059814, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19821, 1990.864013, 1903.079833, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 19824, 1991.333251, 1903.079833, 84.790649, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 1544, 1992.956298, 1901.189453, 84.790588, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 1543, 1992.956298, 1900.969238, 84.790588, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 1544, 1990.605468, 1903.050048, 84.790588, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 1543, 1991.135986, 1903.100097, 84.790588, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 1808, 1988.953369, 1894.689208, 83.272491, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1993.451171, 1887.909912, 83.722656, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.661743, 1884.971435, 79.601951, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1998.248657, 1884.992919, 85.264495, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2008.669921, 1888.752929, 85.264495, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2008.669921, 1910.636108, 85.264495, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2008.669921, 1895.393188, 85.264495, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2008.669921, 1903.994750, 85.264495, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2008.671508, 1899.891967, 85.841941, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1996.665649, 1896.968994, 87.758689, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1996.665649, 1921.847900, 87.758689, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1971.665649, 1896.968994, 87.758689, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1971.665649, 1921.847900, 87.758689, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19454, 2008.238403, 1899.906250, 84.982055, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 18029, "genintintsmallrest", "GB_restaursmll05", -69904 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1990.859985, 1884.992919, 85.264495, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1984.218017, 1884.992919, 85.264495, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1980.809814, 1884.961425, 79.601959, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		CreateDynamicObject( 11727, 2008.314941, 1904.036865, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11727, 2008.314941, 1907.036865, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11727, 2008.314941, 1910.036865, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11727, 2008.314941, 1913.036865, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11727, 2008.314941, 1895.664550, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11727, 2008.314941, 1892.664550, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11727, 2008.314941, 1889.664550, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 11727, 2008.314941, 1886.664550, 87.240608, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1980.878051, 1904.002807, 83.722656, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		CreateDynamicObject( 638, 1983.773315, 1905.277221, 83.990600, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 18756, 1985.204223, 1909.457153, 85.249107, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		CreateDynamicObject( 18757, 1985.200561, 1909.448852, 85.244979, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1992.364257, 1902.420532, 82.782791, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "ah_carp1", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1996.164916, 1902.420532, 82.776794, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "ah_carp1", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1996.164916, 1897.489624, 82.772796, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "ah_carp1", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1992.364257, 1897.498657, 82.784790, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "ah_carp1", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1995.770019, 1915.411010, 83.034774, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1982.918823, 1915.986816, 83.034774, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1979.847045, 1907.206665, 83.034774, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.652221, 1902.449829, 83.026802, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654174, 1897.488403, 83.028800, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1995.774536, 1884.966796, 83.028800, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1970.775024, 1884.966796, 83.028800, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1993.734741, 1884.956787, 83.032798, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1995.676635, 1884.956787, 83.036796, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.664184, 1897.918579, 83.038803, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.664184, 1922.916625, 83.038803, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1979.838256, 1897.928344, 83.028800, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
		SetDynamicObjectMaterial( CreateDynamicObject( 19454, 1994.047973, 1901.686523, 85.392059, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ worldid ], VISAGE_APARTMENT_INT ), 0, 18029, "genintintsmallrest", "GB_restaursmll05", -69904 );
	}

	// Ashley Apartment
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 1988.261962, 1914.888305, 86.762825, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, "Ashley's Apartment", 120, "Comic Sans MS", 64, 1, -52429, 0, 1 );
	CreateDynamicObject( 948, 1983.599975, 1914.543945, 83.289001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19940, 1992.917968, 1900.991943, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19940, 1990.614990, 1903.052978, 84.791000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19822, 1992.904052, 1900.228027, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19821, 1992.904052, 1900.447998, 84.791000, 0.000000, 0.000000, 43.200000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19820, 1992.891967, 1900.711059, 84.791000, 0.000000, 0.000000, 43.200000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19822, 1992.904052, 1901.708007, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19824, 1992.904052, 1901.508056, 84.801002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19822, 1989.802978, 1903.079956, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19824, 1990.042968, 1903.020019, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19820, 1990.343994, 1903.060058, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19821, 1990.864013, 1903.079956, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19824, 1991.333007, 1903.079956, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1544, 1992.956054, 1901.188964, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1543, 1992.956054, 1900.968994, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1544, 1990.604980, 1903.050048, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1543, 1991.135986, 1903.099975, 84.791000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1904.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1907.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1910.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1913.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1895.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1892.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1889.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1886.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14891, 1984.292968, 1890.530029, 85.569000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14888, 1981.849975, 1887.232055, 84.111000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 16151, 2007.610961, 1890.974975, 83.640998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14890, 1980.894042, 1891.415039, 84.289001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2084, 1992.672973, 1888.204956, 83.278999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, 8839, "vgsecarshow", "lightred2_32", 0 );
	CreateDynamicObject( 2245, 1992.639038, 1888.000976, 84.458999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19317, 1992.203979, 1888.743041, 84.051002, -8.000000, 0.000000, -162.300003, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1828, 1988.062011, 1889.428955, 83.268997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 11717, 1991.748046, 1904.704956, 83.291000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, 8839, "vgsecarshow", "lightred2_32", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11717, 1994.847045, 1901.754028, 83.291000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, 8839, "vgsecarshow", "lightred2_32", 0 );
	CreateDynamicObject( 948, 1994.401000, 1904.489013, 83.240997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1994.401000, 1899.498046, 83.240997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1989.369995, 1904.489013, 83.240997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2255, 1980.813964, 1891.467041, 85.119003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2256, 1991.715942, 1904.239990, 85.669998, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2254, 1994.142944, 1901.635986, 85.710998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2726, 1981.689941, 1888.769042, 83.619003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1510, 1981.680053, 1888.769042, 83.929000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 16779, 1989.160034, 1889.270019, 87.238998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1702, 2000.827026, 1902.366943, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1702, 1999.467041, 1899.116943, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1702, 2004.438964, 1901.108032, 83.285003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1702, 2002.817016, 1897.704956, 83.285003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1433, 2001.786987, 1900.089965, 83.444999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2244, 2001.732055, 1900.087036, 84.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 2, 822, "gta_proc_ferns", "veg_bush2", -8734095 );
	CreateDynamicObject( 2726, 2002.089965, 1899.803955, 84.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2726, 2000.999023, 1900.614990, 83.635002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1485, 2000.999023, 1900.614990, 83.794998, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1510, 2000.999023, 1900.614990, 83.944999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1510, 2002.089965, 1899.803955, 84.625000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2026, 2001.682983, 1899.994018, 87.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 2008.140014, 1899.874023, 85.535003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 2008.235961, 1899.276000, 84.144996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, "$", 130, "Arial", 50, 1, -1, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 2008.235961, 1900.447021, 84.144996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, "$", 130, "Arial", 50, 1, -1, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 2008.235961, 1899.677001, 84.144996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, "$", 130, "Arial", 50, 1, -1, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 2008.235961, 1900.067016, 84.144996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, "$", 130, "Arial", 50, 1, -1, 0, 1 );
	tmpVariable = CreateDynamicObject( 2623, 1995.246948, 1887.946044, 84.834999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 0, 8839, "vgsecarshow", "lightred2_32", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 8839, "vgsecarshow", "lightred2_32", 1 );
	CreateDynamicObject( 14820, 1996.265014, 1888.011962, 84.254997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2232, 1996.275024, 1889.426025, 83.845001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2232, 1996.275024, 1886.564941, 83.845001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19128, 1999.874023, 1891.788940, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19128, 1999.874023, 1887.847045, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2773, 1996.227050, 1913.718994, 83.792999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2773, 1993.347045, 1913.718994, 83.792999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 13187, 2002.598022, 1914.932006, 85.485000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, 19174, "samppictures", "samppicture4", 0 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1994.813964, 1914.990966, 85.614997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, "BLACKJACK", 130, "Times new roman", 70, 0, -38476, 0, 1 );
	CreateDynamicObject( 638, 2000.806030, 1914.500976, 83.964996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 638, 2004.326049, 1914.500976, 83.964996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 2007.816040, 1902.025024, 83.245002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 2007.816040, 1897.765014, 83.245002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19292, 2001.482055, 1889.791992, 83.434997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19292, 2001.482055, 1889.791992, 83.434997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19292, 2001.482055, 1889.791992, 83.434997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19292, 2001.482055, 1889.791992, 83.434997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 2007.943969, 1885.687988, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 1994.303955, 1885.687988, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 2007.813964, 1914.499023, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2325, 1992.218017, 1894.743041, 84.735000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2327, 1992.000000, 1894.706054, 85.444999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2327, 1992.360961, 1894.706054, 85.444999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2327, 1992.181030, 1894.706054, 85.444999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1550, 1991.527954, 1894.691040, 83.665000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1550, 1992.749023, 1894.691040, 83.665000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1829, 1982.564941, 1892.767944, 83.745002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 1991.218994, 1893.479003, 85.464996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, 14737, "whorewallstuff", "ah_painting1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 1988.310058, 1893.479003, 85.464996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, 14737, "whorewallstuff", "ah_painting2", 0 );
	CreateDynamicObject( 19786, 1992.977050, 1887.991943, 85.474998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1993.422973, 1890.686035, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1983.336059, 1909.404052, 86.815002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT ), 0, "Top Floor", 130, "Times new roman", 60, 1, -38476, 0, 1 );
	CreatePokerTable( 100000, 2000, 1998.760009, 1907.958984, 83.654998, 4, VISAGE_APARTMENT_WORLD[ 0 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 1994.765991, 1912.642944, 84.275001, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ] );
	CreateRouletteTable( 2004.796997, 1908.604003, 84.324996, 0.000000, VISAGE_APARTMENT_WORLD[ 0 ] );

	// Banging7Grams Apartment
	CreateDynamicObject( 1212, 2004.691040, 1892.906005, 84.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1212, 2004.845947, 1893.161987, 84.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2233, 1993.900024, 1900.006958, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1212, 2004.999023, 1892.963989, 84.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2906, 1980.696044, 1898.010986, 84.363998, -4.400000, -1.600000, 176.399993, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2908, 1986.005004, 1898.262939, 84.394996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 14446, 1982.119018, 1889.348022, 83.845001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1891.790039, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 19474, 2004.661987, 1892.957031, 83.675003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 16779, 2002.489990, 1900.362060, 87.394996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2025, 1983.201049, 1892.989013, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1891.790039, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1886.017944, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1886.017944, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 19786, 1994.022949, 1901.682983, 86.095001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11724, 1994.411010, 1901.603027, 83.805000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11725, 1994.437011, 1901.610961, 83.694999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 14446, 1982.119018, 1889.348022, 83.845001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 1723, 1999.529052, 1904.839965, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2001.671020, 1898.396972, 83.254997, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2003.772949, 1902.567993, 83.254997, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1886.287963, 83.275001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19580, 1985.504028, 1897.422973, 84.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1886.287963, 84.595001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1885.927001, 87.285003, 0.000000, 180.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1889.910034, 83.275001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 11724, 1992.532958, 1887.912963, 83.785003, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 2233, 1993.900024, 1904.189941, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2232, 1994.328979, 1885.817993, 86.806999, 161.399993, -0.600000, -45.500000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 0, "", "", 0 );
	CreateDynamicObject( 2232, 2008.240966, 1885.421997, 86.755996, 18.100000, 179.699996, -139.699996, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2600, 2007.569946, 1908.994018, 84.016998, 0.000000, 0.000000, 130.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2232, 2007.766967, 1914.479003, 86.824996, 18.100000, 179.699996, 330.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 1994.477050, 1885.854003, 83.257003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1889.910034, 84.584999, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1829, 2007.324951, 1886.514038, 83.773002, 0.000000, 0.000000, -135.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1828, 1984.531982, 1889.536010, 83.264999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1895, 1991.697998, 1904.314941, 85.822998, 0.000000, 0.000000, -179.800003, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1889.938964, 85.885002, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2099, 1993.942993, 1893.895019, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19604, 2008.135986, 1899.901000, 84.285003, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 2008.615966, 1897.828979, 85.705001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "black64", 0 );
	CreateDynamicObject( 18688, 1994.331054, 1901.467041, 81.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 15038, 2007.630981, 1914.468017, 83.897003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2003.339965, 1893.567993, 83.264999, 0.000000, 0.000000, 90.099998, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2003.381958, 1892.562988, 83.305000, 0.000000, 0.000000, 90.099998, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2005.942993, 1893.496948, 83.275001, 0.000000, 0.000000, -91.599998, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2005.894042, 1892.390991, 83.224998, 0.000000, 0.000000, -94.900001, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.956054, 1888.548950, 87.275001, 0.000000, 180.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1887.238037, 87.275001, 0.000000, 180.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19632, 1992.571044, 1887.899047, 83.524002, -70.599998, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11725, 1992.409057, 1887.921020, 83.665000, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19786, 1992.922973, 1887.916992, 85.165000, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 16779, 1985.288940, 1889.286010, 87.404998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19172, 1980.343017, 1889.343994, 86.095001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2165, 1986.828002, 1885.921020, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2356, 1986.665039, 1887.214965, 83.294998, 0.000000, 0.000000, 155.199996, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2002, 1984.881958, 1886.032958, 83.264999, 0.000000, 1.200000, 157.800003, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1988.870971, 1887.140014, 83.264999, 0.000000, 0.000000, 110.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1988.381958, 1888.637939, 83.324996, 0.000000, 0.000000, 70.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1827, 1990.395996, 1888.362060, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2801, 1990.306030, 1888.435058, 83.305000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2251, 1980.765014, 1893.017944, 85.095001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2251, 1980.765014, 1885.864990, 85.095001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2105, 1980.696044, 1892.093017, 84.714996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2105, 1980.696044, 1886.569946, 84.714996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14455, 1991.040039, 1893.280029, 84.955001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1985.717041, 1893.213012, 83.264999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1991.984985, 1893.250000, 83.305000, 0.000000, 0.000000, -176.699996, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 639, 1983.884033, 1884.715942, 85.855003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 639, 1989.666015, 1884.715942, 85.855003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 639, 1998.198974, 1884.715942, 85.855003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 639, 2004.050048, 1884.715942, 85.855003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1896, 1991.699951, 1905.595947, 84.285003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11691, 2005.000000, 1888.753051, 83.275001, 0.000000, 0.000000, 42.599998, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2005.688964, 1887.938964, 83.172996, 0.000000, 0.000000, -137.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2004.651000, 1889.995971, 83.285003, 0.000000, 0.000000, 41.500000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2003.776000, 1889.156982, 83.285003, 0.000000, 0.000000, 41.500000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 2008.615966, 1901.991943, 85.705001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "black64", 0 );
	CreateDynamicObject( 1664, 2004.010009, 1888.776000, 84.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1664, 2005.031005, 1889.746948, 84.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1212, 2004.969970, 1888.541015, 84.095001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1212, 2004.900024, 1888.364990, 84.095001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1212, 2004.874023, 1888.803955, 84.095001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1212, 2004.702026, 1888.496948, 84.095001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2315, 2000.637939, 1900.994018, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 2003.123046, 1904.093994, 83.317001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 2002.892944, 1899.140991, 83.317001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19437, 1985.083007, 1910.640991, 83.212997, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 8839, "vgsecarshow", "lightblue_64", -16777216 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19437, 1985.083007, 1908.229980, 83.212997, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 8839, "vgsecarshow", "lightblue_64", -16777216 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19437, 1985.084960, 1909.389038, 83.214996, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 8839, "vgsecarshow", "lightblue_64", -255000576 );
	CreateDynamicObject( 2010, 1986.604003, 1911.296020, 83.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2773, 1985.141967, 1911.485961, 83.803001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1983.784057, 1911.296020, 83.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19437, 1985.084960, 1909.389038, 83.214996, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT ), 0, 8839, "vgsecarshow", "lightblue_64", -255000576 );
	CreateDynamicObject( 2773, 1985.141967, 1907.453002, 83.803001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1983.784057, 1907.443969, 83.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1986.656005, 1907.443969, 83.214996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3524, 1982.336059, 1909.373046, 84.723999, 31.899999, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19175, 1993.957031, 1888.229980, 85.864997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2221, 2000.663940, 1901.729980, 83.885002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreatePokerTable( 100000, 2000, 1994.038208, 1911.641723, 83.664710, 4, VISAGE_APARTMENT_WORLD[ 1 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 2006.777954, 1912.025024, 84.264999, 270.000000, VISAGE_APARTMENT_WORLD[ 1 ] );
	CreateRouletteTable( 1999.801025, 1912.094970, 84.315002, 90.000000, VISAGE_APARTMENT_WORLD[ 1 ] );

	// Brad Apartment
	CreateDynamicObject( 2233, 1993.900024, 1900.006958, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2906, 1980.696044, 1898.010986, 84.363998, -4.400000, -1.600000, 176.399993, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2908, 1986.005004, 1898.262939, 84.394996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14651, 2003.956054, 1890.062011, 85.394996, 0.000000, 0.000000, 140.100006, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19786, 1994.072998, 1901.682983, 85.614997, 3.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11724, 1994.411010, 1901.603027, 83.805000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11725, 1994.437011, 1901.610961, 83.694999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2001.529052, 1903.839965, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2003.671020, 1897.396972, 83.254997, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2005.772949, 1901.567993, 83.254997, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19580, 1985.504028, 1897.422973, 84.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2233, 1993.900024, 1904.189941, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2232, 1994.328979, 1885.817993, 86.806999, 161.399993, -0.600000, -45.500000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, 0, "", "", 0 );
	CreateDynamicObject( 2232, 2008.240966, 1885.421997, 86.755996, 18.100000, 179.699996, -139.699996, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2600, 2007.569946, 1908.994018, 84.016998, 0.000000, 0.000000, 130.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2232, 2007.766967, 1914.479003, 86.824996, 18.100000, 179.699996, 330.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2099, 1993.942993, 1893.895019, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2965, 2004.576049, 1889.796020, 84.235000, 0.000000, 0.000000, 49.900001, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18688, 1994.331054, 1901.467041, 81.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 15038, 2007.630981, 1914.468017, 83.897003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2315, 2002.637939, 1899.994018, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 2005.123046, 1903.093994, 83.317001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 2004.892944, 1898.140991, 83.317001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2733, 1992.885986, 1887.114990, 86.305000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, 18055, "genintsmlrst_split", "GB_restaursmll16b", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2733, 1992.885986, 1887.114990, 84.584999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, 18055, "genintsmlrst_split", "GB_restaursmll17b", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2733, 1992.885986, 1888.725952, 86.315002, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, 18055, "genintsmlrst_split", "GB_restaursmll17a", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2733, 1992.885986, 1888.725952, 84.605003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, 18055, "genintsmlrst_split", "GB_restaursmll16a", 0 );
	CreateDynamicObject( 2010, 1994.500000, 1885.833007, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 1982.423950, 1893.478027, 85.571998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, 14802, "lee_bdupsflat", "Bdup_Poster", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19327, 1980.366943, 1889.381958, 85.815002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, 14737, "whorewallstuff", "ah_painting2", 0 );
	CreateDynamicObject( 14446, 1982.073974, 1889.478027, 83.864997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2835, 1984.373046, 1889.000000, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 951, 1982.634033, 1885.901000, 84.014999, 0.000000, 0.000000, 37.400001, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2206, 1986.166992, 1885.959960, 83.285003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1714, 1985.043945, 1887.130004, 83.285003, 0.000000, 0.000000, 18.399999, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19893, 1985.265991, 1886.181030, 84.224998, 0.000000, 0.000000, -169.500000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 1, 14737, "whorewallstuff", "ah_painting1", 0 );
	CreateDynamicObject( 2196, 1984.967041, 1886.490966, 84.205001, 0.000000, 0.000000, 24.200000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2164, 1986.708007, 1893.448974, 83.271003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 1992.233032, 1885.828979, 83.324996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 2007.870971, 1885.833007, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1990.803955, 1905.479980, 83.275001, 0.000000, 0.000000, 137.199996, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1993.500000, 1905.933959, 83.275001, 0.000000, 0.000000, -152.500000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1820, 1991.338989, 1906.152954, 83.263000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14804, 1991.631958, 1905.001953, 84.303001, 0.000000, 0.000000, -133.699996, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19906, 1989.886962, 1914.927978, 87.352996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, "Brads Hotel", 130, "Times new Roman", 70, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19906, 1989.886962, 1914.927978, 86.623001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, "Room", 130, "Times new Roman", 70, 0, -16777216, 0, 1 );
	CreateDynamicObject( 640, 1989.848022, 1914.374023, 83.944999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2666, 1983.452026, 1909.348999, 86.584999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT ), 0, "10", 130, "TIMES NEW ROMAN", 110, 0, -16777216, 0, 1 );
	CreateDynamicObject( 1724, 1999.197998, 1898.532958, 83.264999, 0.000000, 0.000000, 101.199996, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1724, 1999.113037, 1901.229003, 83.264999, 0.000000, 0.000000, 74.099998, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11665, 1995.609008, 1888.282958, 83.995002, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreatePokerTable( 100000, 2000, 1999.035034, 1893.290039, 83.654998, 4, VISAGE_APARTMENT_WORLD[ 2 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 2006.358032, 1911.515014, 84.264999, 270.000000, VISAGE_APARTMENT_WORLD[ 2 ] );
	CreateRouletteTable( 1999.801025, 1912.094970, 84.315002, 90.000000, VISAGE_APARTMENT_WORLD[ 2 ] );

	// Daniel Apartment
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1991.682006, 1904.172973, 86.000999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, "Daniel's", 130, "Times New Roman", 70, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1991.682006, 1904.180053, 85.070999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, "Apartment", 130, "Times New Roman", 70, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2007.673950, 1897.963989, 82.768997, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 13724, "docg01_lahills", "ab_tile2", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2007.673950, 1898.925048, 82.768997, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 13724, "docg01_lahills", "ab_tile2", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2007.673950, 1902.426025, 82.764999, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 13724, "docg01_lahills", "ab_tile2", -16 );
	CreateDynamicObject( 11727, 2008.314941, 1904.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1907.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1910.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1913.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1895.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1892.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1889.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1886.665039, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19861, 2003.012939, 1885.984008, 86.694999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "black64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2001.166992, 1886.280029, 81.537002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 2233, 2005.550048, 1885.689941, 84.037002, 0.000000, 0.000000, -160.800003, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19861, 1999.314941, 1885.984985, 86.694999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "black64", -16 );
	CreateDynamicObject( 2233, 1996.078002, 1885.885986, 84.037002, 0.000000, 0.000000, 168.699996, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 2001.167968, 1886.708984, 78.777000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2001.166992, 1885.499023, 85.166999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 2315, 1998.837036, 1890.108032, 83.304000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2315, 2003.798950, 1890.108032, 83.304000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 1996.958007, 1889.859008, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2000.667968, 1891.890014, 83.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2001.697021, 1889.859008, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2006.058959, 1891.890014, 83.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 2001.161010, 1892.456054, 83.306999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 2001.161010, 1889.347045, 83.306999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19525, 2003.786010, 1890.871948, 83.796997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19571, 1998.764038, 1890.338012, 83.817001, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19571, 1998.715942, 1891.369995, 83.817001, 90.000000, 45.299999, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2858, 2003.739013, 1890.223999, 83.857002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2861, 2003.667968, 1891.464965, 83.827003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.363037, 1884.901977, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.385009, 1884.901977, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.863037, 1884.901977, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.363037, 1884.901977, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.863037, 1884.901977, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1991.363037, 1884.901977, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1993.863037, 1884.901977, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.885009, 1884.901977, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.385009, 1884.901977, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.885009, 1884.901977, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1991.385009, 1884.901977, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1993.885009, 1884.901977, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1992.854980, 1885.001953, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1990.624023, 1885.001953, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.395019, 1885.001953, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.176025, 1885.001953, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.953979, 1885.001953, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.723999, 1885.001953, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1992.854980, 1885.001953, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1990.625000, 1885.001953, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.395996, 1885.001953, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.175048, 1885.001953, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2005.671020, 1914.943969, 84.285003, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 1897, 1981.724975, 1885.001953, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1979.843017, 1889.493041, 88.184997, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 14563, "triad_main", "casinowall1", -260011385 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1981.291992, 1889.493041, 82.794998, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 14563, "triad_main", "casinowall1", -260011385 );
	CreateDynamicObject( 19937, 1986.072998, 1890.404052, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19937, 1986.072998, 1888.494018, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19786, 1986.182983, 1889.453979, 84.945999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 1214, "metal", "CJ_FRAME_Glass", 0 );
	CreateDynamicObject( 2233, 1986.469970, 1891.489013, 83.294998, 0.000000, 0.000000, -73.900001, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2233, 1986.260009, 1886.774047, 83.294998, 0.000000, 0.000000, -107.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2206, 1992.436035, 1888.482055, 83.264999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2298, 1984.286010, 1888.166992, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 2, 16150, "ufo_bar", "GEwhite1_64", -260011385 );
	CreateDynamicObject( 19893, 1992.437988, 1887.479003, 84.214996, 0.000000, 0.000000, -97.900001, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2196, 1992.151977, 1887.318969, 84.194999, 0.000000, 0.000000, 95.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1714, 1991.379028, 1887.640991, 83.264999, 0.000000, 0.000000, 78.500000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1985.880981, 1913.443969, 84.285003, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2003.668945, 1915.453979, 84.285003, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1995.697998, 1914.941040, 83.032997, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1991.676025, 1913.441040, 83.032997, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
	CreateDynamicObject( 1897, 1983.944946, 1885.001953, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1991.676025, 1914.441040, 83.032997, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 14388, "dr_gsnew", "AH_flroortile12", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1987.887939, 1915.453979, 84.285003, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1991.640991, 1913.443969, 72.044998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1991.640991, 1925.453979, 84.055000, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19887, 1983.145996, 1913.508056, 84.282997, 90.000000, 90.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 18202, "w_towncs_t", "hatwall256hi", 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19887, 1985.166992, 1915.430053, 84.282997, 90.000000, 90.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 18202, "w_towncs_t", "hatwall256hi", 1 );
	CreateDynamicObject( 19887, 1985.166992, 1915.449951, 84.282997, 90.000000, 90.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2000.256958, 1912.958984, 85.413002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16646, "a51_alpha", "stanwind_nt", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1993.615966, 1912.958984, 85.413002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16646, "a51_alpha", "stanwind_nt", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1986.977050, 1912.958984, 85.413002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16646, "a51_alpha", "stanwind_nt", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 1991.640991, 1913.443969, 99.455001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2002.659057, 1913.447021, 84.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2003.659057, 1913.447021, 84.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2002.571044, 1913.448974, 84.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 1601, 1999.947998, 1913.484985, 85.055000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1601, 1989.786987, 1913.484985, 86.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1601, 1994.876953, 1913.484985, 85.105003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1603, 1992.994995, 1913.441040, 86.205001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1605, 1990.814941, 1913.907958, 85.254997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1606, 1997.650024, 1914.347045, 86.065002, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2007.865966, 1899.906982, 79.236999, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 2229, 2008.161987, 1901.907958, 84.154998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2229, 2008.151977, 1897.286987, 84.154998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19284, 2008.848022, 1900.027954, 83.355003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19281, 2008.848022, 1900.027954, 83.355003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18648, 2008.630981, 1898.937988, 83.904998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18648, 2008.630981, 1900.818969, 83.904998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2229, 2008.151977, 1897.657958, 83.735000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2229, 2008.171997, 1901.537963, 83.735000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19281, 1984.949951, 1898.296997, 90.035003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19940, 2007.146972, 1899.930053, 84.016998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 6056, "venice_law", "stonewall_la", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19940, 2007.146972, 1899.930053, 83.616996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 6056, "venice_law", "stonewall_la", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19940, 2007.146972, 1900.911010, 83.027000, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 6056, "venice_law", "stonewall_la", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19940, 2007.146972, 1898.938964, 83.027000, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 6056, "venice_law", "stonewall_la", -16 );
	CreateDynamicObject( 2028, 2007.182983, 1899.953979, 83.717002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2855, 2007.150024, 1899.306030, 83.635002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2828, 2007.189941, 1900.020996, 84.007003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1569, 2005.387939, 1914.463989, 83.247001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2600, 2007.756958, 1910.902954, 84.035003, 0.000000, 0.000000, 46.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 3, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	CreateDynamicObject( 1985, 1989.043945, 1891.079956, 86.330001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19087, 1989.043945, 1891.069946, 88.690002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT ), 0, 19355, "none", "none", -268435456 );
	CreateDynamicObject( 1726, 2003.411987, 1903.020996, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2005.401977, 1896.796997, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2002.491943, 1898.909057, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11665, 1994.938964, 1911.328979, 84.004997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1824, 2001.761962, 1907.947021, 83.735000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2571, 1993.225952, 1906.005004, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 638, 2007.762939, 1906.098022, 83.974998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreatePokerTable( 100000, 2000, 2004.666015, 1899.875000, 83.635002, 4, VISAGE_APARTMENT_WORLD[ 3 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 1995.259033, 1901.642944, 84.285003, 90.000000, VISAGE_APARTMENT_WORLD[ 3 ] );

	// MrFreeze Apartment
	CreateDynamicObject( 948, 1983.599975, 1914.543945, 83.289001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1990.859985, 1884.993041, 85.263999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1984.218017, 1884.993041, 85.263999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "CJ_FRAME_Glass", -16 );
	CreateDynamicObject( 11727, 2008.314941, 1904.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1907.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1910.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2008.314941, 1913.036987, 87.240997, 90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1998.047973, 1909.453979, 82.801002, 90.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 2001.048950, 1891.963012, 80.794998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 2001.048950, 1901.963012, 80.794998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 2003.316040, 1898.139038, 80.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "ah_carp1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1991.053955, 1909.453979, 82.796997, 90.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1981.074951, 1909.453979, 82.796997, 90.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1991.089965, 1885.001953, 85.876998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 14902, "gen_pol_vegas", "pol_win_kb", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 1984.480957, 1885.001953, 85.876998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 14902, "gen_pol_vegas", "pol_win_kb", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11686, 2001.000976, 1888.512939, 83.294998, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 3, 18028, "cj_bar2", "GB_nastybar01", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11717, 1997.417968, 1892.916992, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 18028, "cj_bar2", "GB_nastybar08", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11717, 2000.459960, 1892.916992, 83.285003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 18028, "cj_bar2", "GB_nastybar08", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11717, 2001.628051, 1892.916992, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 18028, "cj_bar2", "GB_nastybar08", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11717, 2004.651000, 1892.916992, 83.285003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 18028, "cj_bar2", "GB_nastybar08", -16 );
	CreateDynamicObject( 2315, 1998.949951, 1892.151977, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2315, 2003.130981, 1892.151977, 83.294998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1548, 2003.114013, 1892.884033, 83.815002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1548, 1998.953979, 1892.884033, 83.815002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11725, 1994.536987, 1901.718017, 83.675003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2828, 1994.376953, 1901.738037, 84.305000, 0.000000, 0.000000, -103.099998, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11724, 1994.428955, 1901.727050, 83.785003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 2003.469970, 1898.142944, 80.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 1997.099975, 1909.989013, 80.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	CreateDynamicObject( 951, 2006.183959, 1885.675048, 84.035003, 0.000000, 0.000000, -45.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 951, 1995.881958, 1885.675048, 84.035003, 0.000000, 0.000000, 45.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2295, 1990.045043, 1888.805053, 83.235000, 0.000000, 0.000000, 86.199996, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2295, 1990.213989, 1886.823974, 83.235000, 0.000000, 0.000000, 112.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19786, 1992.956054, 1887.870971, 85.175003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 1, 14860, "gf1", "mp_apt1_pos4", -16 );
	CreateDynamicObject( 2028, 1992.407958, 1888.161010, 83.385002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 1581, 1992.409057, 1887.532958, 83.305000, 90.000000, 16.500000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 14860, "gf1", "mp_apt1_pos4", -16 );
	CreateDynamicObject( 2300, 1984.855957, 1888.223999, 83.315002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 356, 1980.743041, 1889.125000, 84.249000, 95.099998, 90.000000, 4.199999, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 370, 1980.900024, 1891.765014, 83.635002, 0.000000, 0.000000, 96.599998, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 371, 1981.625000, 1888.676025, 83.525001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19825, 1980.380981, 1889.505981, 86.055000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2813, 1980.739013, 1888.206054, 84.544998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2102, 1981.052001, 1890.870971, 84.525001, 0.000000, 0.000000, 82.400001, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2828, 1980.928955, 1888.262939, 85.144996, 0.000000, 0.000000, -78.800003, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2833, 1984.564941, 1889.092041, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2206, 1986.811035, 1885.963012, 83.264999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19940, 1983.875976, 1893.336059, 85.305000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2726, 1984.609008, 1893.281982, 85.665000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 2726, "lee_txd", "Strip_lamp", -1043950 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2726, 1983.128051, 1893.281982, 85.665000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 2726, "lee_txd", "Strip_lamp", -251710301 );
	CreateDynamicObject( 1734, 1988.020019, 1890.114013, 87.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2726, 1983.619018, 1893.281982, 85.665000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 2726, "lee_txd", "Strip_lamp", -255 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2726, 1984.119018, 1893.281982, 85.665000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 2726, "lee_txd", "Strip_lamp", -251680154 );
	CreateDynamicObject( 1741, 1987.223022, 1891.983032, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14863, 1989.635009, 1890.483032, 83.864997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19999, 1985.832031, 1886.892944, 83.294998, 0.000000, 0.000000, -22.899999, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19893, 1985.739013, 1886.046997, 84.205001, 0.000000, 0.000000, 167.100006, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 638, 1991.619018, 1904.619995, 83.967002, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2406, 1980.487060, 1885.737060, 84.504997, -6.599999, 0.000000, 102.199996, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2779, 1994.822021, 1914.161010, 83.257003, 0.000000, 0.000000, -11.399999, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2778, 1992.615966, 1914.288940, 83.257003, 0.000000, 0.000000, 5.500000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 1987.650024, 1914.352050, 83.236999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 2003.411010, 1899.983032, 79.084999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 15048, "labigsave", "AH_fancyceil", -16 );
	CreateDynamicObject( 948, 2005.488037, 1906.451049, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 2002.526977, 1911.463012, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2002.277954, 1909.913940, 83.271003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 1998.826049, 1907.892944, 83.271003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1824, 2001.505981, 1901.890991, 83.764999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2311, 2000.498046, 1908.100952, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2000.592041, 1904.053955, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2002.583007, 1899.682983, 83.254997, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19443, 2008.060058, 1899.911010, 85.708000, 87.599998, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "black64", -16 );
	CreateDynamicObject( 1896, 2006.427978, 1899.936035, 84.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19814, 2008.010009, 1899.886962, 85.074996, 2.299999, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 4 ], VISAGE_APARTMENT_INT ), 0, 7584, "miragecasino2", "visagesign2_256", 0 );

	// Hariexy Apartment
	CreateDynamicObject( 2069, 2007.516967, 1901.884033, 83.305000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 2007.516967, 1897.953002, 83.305000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 2006.339965, 1901.489990, 83.254997, 0.000000, 0.000000, -32.099998, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 2007.218994, 1898.996948, 83.254997, 0.000000, 0.000000, -141.600006, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19796, 2008.137939, 1902.000000, 85.555000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, "H", 100, "Times new Roman", 120, 0, -12490271, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19796, 2008.137939, 1900.288940, 85.555000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, "Z", 100, "Times new Roman", 120, 0, -12490271, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19796, 2008.137939, 1901.119018, 85.574996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, "&", 100, "Times new Roman", 120, 0, -12490271, 0, 1 );
	CreateDynamicObject( 2245, 2007.597045, 1899.985961, 84.035003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2083, 2007.222045, 1900.468994, 83.285003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.363037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.385009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.863037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.363037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.863037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1991.363037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1993.863037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.885009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.385009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.885009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1991.385009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1993.885009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1992.854980, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1990.624023, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.395019, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.176025, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.953979, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.723999, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1992.854980, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1990.625000, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.395996, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.175048, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 1897, 1983.953979, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -268435456 );
	CreateDynamicObject( 1897, 1981.724975, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1905.531005, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1908.562011, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1911.521972, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1902.540039, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1894.160034, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1891.159057, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1888.189941, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1897.151000, 75.125000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1911.501953, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1908.551025, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1905.540039, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1902.541015, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1894.239990, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1891.222045, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1888.170043, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.654052, 1897.141967, 84.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 1897, 1981.732055, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -268435456 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 1989.121948, 1893.572021, 88.775001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 1979.491943, 1893.572021, 88.764999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 1980.260009, 1890.189941, 88.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 1976.479980, 1885.380981, 88.764999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19355, 1993.034057, 1888.796997, 85.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19355, 1993.036010, 1887.026977, 85.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	tmpVariable = CreateDynamicObject( 1761, 2006.012939, 1888.547973, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 16102, "des_cen", "CJ-COUCHL2", 0 );
	SetDynamicObjectMaterial( tmpVariable, 0, 11717, "ab_wooziec", "ab_fabricRed", 0 );
	tmpVariable = CreateDynamicObject( 1761, 2002.072021, 1890.150024, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 16102, "des_cen", "CJ-COUCHL2", 0 );
	SetDynamicObjectMaterial( tmpVariable, 0, 11717, "ab_wooziec", "ab_fabricRed", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2007.713012, 1891.222045, 71.553001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2007.713012, 1892.222045, 71.553001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2007.713012, 1890.222045, 71.553001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	tmpVariable = CreateDynamicObject( 19786, 2007.840942, 1891.203979, 84.694999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 10226, "sfeship1", "CJ_TV_SCREEN", -16 );
	SetDynamicObjectMaterial( tmpVariable, 0, 10226, "sfeship1", "CJ_TV_SCREEN", -16777216 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2688, 2007.354003, 1891.840942, 83.444999, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2688, 2007.354003, 1890.579956, 83.444999, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2688, 2007.354003, 1890.579956, 83.644996, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2688, 2007.354003, 1890.579956, 83.845001, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2688, 2007.354003, 1891.840942, 83.845001, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2688, 2007.354003, 1891.840942, 83.644996, 90.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	CreateDynamicObject( 1827, 2004.833984, 1891.230957, 83.245002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2083, 1994.797973, 1888.605957, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2083, 1994.797973, 1886.296020, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 15038, 1994.343994, 1887.961059, 83.855003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2600, 2004.140014, 1886.688964, 84.065002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 1451, 1998.176025, 1887.171997, 84.084999, 0.000000, 0.000000, 158.699996, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "des_ghotwood1", 0 );
	CreateDynamicObject( 19993, 1998.994995, 1887.876953, 83.245002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19993, 1998.844970, 1887.697021, 83.245002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19847, 1998.019042, 1888.397949, 83.334999, -5.599999, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2029, 2004.984008, 1906.921997, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 2964, "k_pool", "Bow_bar_tabletop_wood", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2029, 2004.984008, 1908.901977, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 2964, "k_pool", "Bow_bar_tabletop_wood", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19327, 2004.985961, 1907.223999, 83.294998, -90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 3922, "bistro", "Tablecloth", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19327, 2004.985961, 1909.593994, 83.294998, -90.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 3922, "bistro", "Tablecloth", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2124, 2003.965942, 1909.395019, 84.095001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 1594, "chairsntable", "wood02", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2124, 2003.965942, 1907.413940, 84.095001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 1594, "chairsntable", "wood02", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2124, 2006.006958, 1907.413940, 84.095001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 1594, "chairsntable", "wood02", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2124, 2006.015991, 1909.395019, 84.095001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 1594, "chairsntable", "wood02", -16 );
	CreateDynamicObject( 19525, 2004.973022, 1908.418945, 84.086997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11744, 2004.712036, 1909.416015, 84.105003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11744, 2005.233032, 1909.416015, 84.105003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11744, 2004.712036, 1907.415039, 84.105003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11744, 2005.233032, 1907.405029, 84.105003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2259, 1986.818969, 1914.427978, 85.224998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 1, 2259, "picture_frame_clip", "CJ_PAINTING6", -16 );
	CreateDynamicObject( 2259, 1990.318969, 1914.427978, 85.224998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2259, 1993.818969, 1914.427978, 85.224998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 1, 2259, "picture_frame_clip", "CJ_PAINTING4", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2259, 1997.318969, 1914.427978, 85.224998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 1, 2259, "picture_frame_clip", "CJ_PAINTING12", -16 );
	CreateDynamicObject( 948, 1992.144042, 1914.526000, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1988.644042, 1914.526000, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1995.644042, 1914.526000, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18765, 2003.114013, 1919.892944, 84.955001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, "H & Z", 130, "Times new roman", 80, 1, -16777216, 0, 1 );
	CreateDynamicObject( 11727, 1999.619995, 1914.406005, 87.245002, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 2001.619995, 1914.406005, 87.245002, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicObject( 1761, 2003.982055, 1893.812011, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 16102, "des_cen", "CJ-COUCHL2", 0 );
	SetDynamicObjectMaterial( tmpVariable, 0, 11717, "ab_wooziec", "ab_fabricRed", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2573, 1985.152954, 1892.993041, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 3, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2576, 1992.484008, 1890.235961, 83.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	CreateDynamicObject( 19787, 1992.973999, 1887.857055, 85.285003, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 1983.322998, 1889.748046, 88.345001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1983.319946, 1884.957031, 84.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 14446, 1985.151977, 1889.162963, 83.855003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2834, 1987.904052, 1888.659057, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1736, 1983.713989, 1889.139038, 86.205001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 1979.000976, 1885.369995, 88.684997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT ), 0, 6287, "pierc_law2", "ws_vic_wood1", -16 );
	CreateDynamicObject( 14705, 1992.595947, 1889.376953, 85.694999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2828, 1992.626953, 1887.901000, 84.394996, 0.000000, 0.000000, 83.099998, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2241, 1989.110961, 1893.024047, 83.745002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2241, 1991.071044, 1893.024047, 83.745002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1731, 1983.561035, 1891.140014, 84.595001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1731, 1983.561035, 1887.088989, 84.595001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2251, 1983.858032, 1885.857055, 84.114997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2195, 1992.620971, 1885.961059, 83.894996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1828, 2002.431030, 1901.511962, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1703, 1995.317016, 1900.677001, 83.264999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1703, 1998.317016, 1902.677978, 83.264999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1822, 1996.306030, 1901.147949, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2100, 1999.911987, 1914.708007, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2811, 1991.538940, 1905.027954, 83.754997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2126, 1991.067016, 1904.545043, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2260, 1991.677001, 1904.696044, 85.233001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2280, 1994.635986, 1901.729003, 85.114997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 1994.766967, 1903.723022, 83.324996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 1991.536010, 1905.004028, 82.084999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2076, 1986.762939, 1909.417968, 86.523002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2076, 1991.762939, 1909.417968, 86.523002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2076, 1996.762939, 1909.417968, 86.523002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 5 ], VISAGE_APARTMENT_INT );

	// Harpreet Apartment
	SetDynamicObjectMaterial( CreateDynamicObject( 2298, 1988.984008, 1889.255981, 83.264999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 2, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	CreateDynamicObject( 2238, 1992.734008, 1889.239013, 84.194999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2238, 1992.734008, 1886.588012, 84.194999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1736, 1992.629028, 1887.943969, 85.694999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2225, 1980.318969, 1889.609008, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2231, 1980.385986, 1888.791992, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2231, 1980.385986, 1890.692993, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2231, 1980.489990, 1887.833007, 83.285003, 0.000000, 0.000000, 115.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2231, 1980.645996, 1891.619995, 83.285003, 0.000000, 0.000000, 65.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 1980.621948, 1889.514038, 86.313003, 9.600000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, "CONNECTING...", 130, "Grandma's Television", 20, 0, -1, -16777216, 1 );
	CreateDynamicObject( 1702, 1984.057006, 1890.446044, 83.275001, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1705, 1983.687988, 1892.425048, 83.275001, 0.000000, 0.000000, -77.599998, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1705, 1983.761962, 1887.453979, 83.275001, 0.000000, 0.000000, -111.199996, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2315, 1982.426025, 1888.766967, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2661, 1980.385986, 1889.494018, 84.617996, 9.600000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, "L G", 130, "Grandma's Television", 50, 0, -1, 0, 1 );
	CreateDynamicObject( 2202, 1986.615966, 1885.957031, 83.254997, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2202, 1988.597045, 1885.957031, 83.254997, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2684, 1988.535034, 1885.852050, 84.264999, -76.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2684, 1988.573974, 1885.852050, 84.275001, -76.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2684, 1988.437988, 1885.852050, 84.241996, -76.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2684, 1988.370971, 1885.852050, 84.224998, -76.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", -16 );
	tmpVariable = CreateDynamicObject( 2854, 1987.651000, 1885.852050, 84.475997, 0.000000, -8.399999, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 0, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterial( tmpVariable, 2, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2684, 1986.722045, 1885.852050, 84.307998, -76.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2684, 1986.412963, 1885.852050, 84.234001, -76.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", -16 );
	CreateDynamicObject( 2195, 1991.203002, 1893.081054, 83.904998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2195, 1988.703002, 1893.081054, 83.904998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2195, 1986.203002, 1893.081054, 83.904998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.659057, 1894.088989, 75.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.659057, 1891.129028, 75.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.659057, 1905.489013, 75.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.659057, 1908.458984, 75.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.659057, 1911.558959, 75.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.659057, 1888.108032, 75.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 1726, 2004.615966, 1911.496948, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2006.626953, 1905.474975, 83.264999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 2002.991943, 1906.671997, 83.264999, 0.000000, 0.000000, 111.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 2002.735961, 1909.211059, 83.264999, 0.000000, 0.000000, 78.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.017944, 1908.478027, 71.555000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.017944, 1909.478027, 71.555000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.017944, 1907.478027, 71.555000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 19786, 2008.197021, 1908.479003, 84.894996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1787, 2007.883056, 1908.441040, 84.125000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19825, 2008.113037, 1908.449951, 86.464996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2661, 2007.485961, 1909.255004, 83.625000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 1214, "metal", "CJ_FRAME_Glass", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2661, 2007.485961, 1907.764038, 83.625000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, 1214, "metal", "CJ_FRAME_Glass", -16 );
	CreateDynamicObject( 2006, 2007.546997, 1908.250000, 83.625000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2006, 2007.546997, 1908.709960, 83.625000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2779, 2007.600952, 1892.650024, 83.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2681, 2007.600952, 1889.568969, 83.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2778, 2007.600952, 1886.598022, 83.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 2006.957031, 1889.836059, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 2006.957031, 1892.916992, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 2006.957031, 1886.845947, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1824, 2000.207031, 1889.510986, 83.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1703, 1999.213989, 1891.713989, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1703, 2001.234985, 1887.243041, 83.264999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 1997.881958, 1889.546997, 83.260002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 2002.654052, 1889.546997, 83.260002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 638, 1994.343017, 1888.505004, 83.964996, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1994.477050, 1886.114013, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1827, 2004.937011, 1908.416992, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2259, 1988.760986, 1914.415039, 85.035003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2255, 1998.562988, 1914.415039, 85.035003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2254, 1993.871948, 1914.875000, 85.495002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2256, 2003.442993, 1914.885009, 85.334999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18656, 1996.290039, 1916.478027, 81.915000, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18656, 2000.781005, 1916.478027, 81.915000, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18656, 1991.188964, 1916.478027, 81.915000, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11724, 1994.435058, 1901.686035, 83.785003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19632, 1994.564941, 1901.713989, 83.294998, 0.000000, 0.000000, 86.500000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2257, 1991.650024, 1904.270996, 85.535003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11665, 2006.547973, 1899.923950, 83.974998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19609, 1999.407958, 1897.129028, 83.275001, 0.000000, 0.000000, -148.399993, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19616, 2000.413940, 1900.162963, 83.264999, 0.000000, 0.000000, -49.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19317, 2000.526000, 1899.656982, 84.043998, -7.300000, 0.000000, -26.100000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19318, 2000.255004, 1900.718994, 83.962997, -15.500000, 0.000000, -159.600006, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19611, 1998.243041, 1899.801025, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19610, 1998.243041, 1899.801025, 84.915000, 0.000000, 0.000000, -113.400001, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11719, 1980.624023, 1898.061035, 84.305000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1994.057983, 1901.673950, 86.154998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, "Visage", 130, "Times new Roman", 100, 0, COLOR_GOLD, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1994.057983, 1901.673950, 85.105003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT ), 0, "Casino", 130, "Times new Roman", 110, 0, COLOR_GOLD, 0, 1 );
	CreateDynamicActor( 257, 1981.520019, 1897.949951, 84.285003, 90.000000, 1, 100.0, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicActor( 251, 1997.329956, 1899.079956, 84.285003, 0.000000, 1, 100.0, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	ApplyDynamicActorAnimation( tmpVariable, "STRIP", "STR_Loop_B", 4.1, 1, 1, 1, 1, 0 );
	tmpVariable = CreateDynamicActor( 140, 1998.829956, 1900.949951, 84.285003, 0.000000, 1, 100.0, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	ApplyDynamicActorAnimation( tmpVariable, "STRIP", "STR_A2B", 4.1, 1, 1, 1, 1, 0 );
	tmpVariable = CreateDynamicActor( 138, 1984.079956, 1889.349975, 84.245002, 78.300003, 1, 100.0, VISAGE_APARTMENT_WORLD[ 6 ], VISAGE_APARTMENT_INT );
	ApplyDynamicActorAnimation( tmpVariable, "beach", "ParkSit_W_loop", 4.1, 1, 1, 1, 1, 0 );

	// Nibble Apartment
	tmpVariable = CreateDynamicObject( 2259, 1989.623046, 1904.677001, 83.805000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2259, 1994.614013, 1901.666992, 85.345001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 1, 14517, "im_xtra", "CJ_PAINTING13", -16 );
	tmpVariable = CreateDynamicObject( 2259, 1989.623046, 1904.677001, 84.805000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14517, "im_xtra", "CJ_PLANT", -16 );
	tmpVariable = CreateDynamicObject( 2259, 1989.623046, 1904.677001, 85.805000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14517, "im_xtra", "CJ_PLANT", -16 );
	tmpVariable = CreateDynamicObject( 2259, 1993.662963, 1904.687988, 83.805000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14517, "im_xtra", "CJ_PLANT", -16 );
	tmpVariable = CreateDynamicObject( 2259, 1993.662963, 1904.687988, 84.805000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14517, "im_xtra", "CJ_PLANT", -16 );
	tmpVariable = CreateDynamicObject( 2259, 1993.662963, 1904.687988, 85.805000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14517, "im_xtra", "CJ_PLANT", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1993.000976, 1885.974975, 79.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "sa_wood08_128", -16 );
	CreateDynamicObject( 19937, 1992.754028, 1886.873046, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 1993.000976, 1889.905029, 79.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "sa_wood08_128", -16 );
	CreateDynamicObject( 2906, 1980.696044, 1898.010986, 84.363998, -4.400000, -1.600000, 176.399993, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2908, 1986.005004, 1898.262939, 84.394996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19825, 1992.911987, 1887.975952, 86.555000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2165, 1985.906005, 1885.978027, 83.254997, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1714, 1985.437988, 1886.885009, 83.275001, 0.000000, 0.000000, 19.899999, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2331, 1985.276000, 1893.088989, 83.535003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2025, 1983.201049, 1892.989013, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1891.790039, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1886.017944, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1886.017944, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	SetDynamicObjectMaterial( CreateDynamicObject( 14446, 1982.119018, 1889.348022, 83.845001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 19580, 1985.504028, 1897.422973, 84.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2232, 1994.328979, 1885.817993, 86.806999, 161.399993, -0.600000, -45.500000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 0, "", "", 0 );
	CreateDynamicObject( 2232, 2008.240966, 1885.421997, 86.755996, 18.100000, 179.699996, -139.699996, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2232, 2007.766967, 1914.479003, 86.824996, 18.100000, 179.699996, 330.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 1994.477050, 1885.854003, 83.257003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 15038, 2007.630981, 1914.468017, 83.897003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19786, 1993.012939, 1887.906982, 85.164001, -1.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 16779, 1985.288940, 1889.286010, 87.404998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19172, 1980.343017, 1889.343994, 86.095001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1988.870971, 1887.140014, 83.264999, 0.000000, 0.000000, 110.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1988.381958, 1888.637939, 83.324996, 0.000000, 0.000000, 70.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1827, 1990.395996, 1888.362060, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2801, 1990.306030, 1888.435058, 83.305000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2251, 1980.765014, 1893.017944, 85.095001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2251, 1980.765014, 1885.864990, 85.095001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2105, 1980.696044, 1892.093017, 84.714996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2105, 1980.696044, 1886.569946, 84.714996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19937, 1992.754028, 1888.782958, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1991.681030, 1904.133056, 86.425003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "Welcome", 130, "Times new Roman", 70, 0, -16768462, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1991.681030, 1904.133056, 85.625000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "To", 130, "Times new Roman", 70, 0, -16768462, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1992.181030, 1904.133056, 84.824996, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "Nibble's", 130, "Times new Roman", 70, 0, -16768462, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1991.181030, 1904.133056, 84.025001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "Apartment", 130, "Times new Roman", 70, 0, -16768462, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 9131, 2007.827026, 1900.542968, 83.665000, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 9131, 2007.828979, 1899.303955, 83.666999, 0.000000, 90.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19843, 2007.946044, 1901.687988, 84.997001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19843, 2007.946044, 1898.157958, 84.997001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19843, 2007.946044, 1901.687988, 85.997001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19843, 2007.946044, 1898.157958, 85.997001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	CreateDynamicObject( 2230, 2008.136962, 1897.478027, 83.574996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2230, 2008.136962, 1901.748046, 83.525001, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2245, 2007.807983, 1898.166992, 85.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2194, 2007.807983, 1901.667968, 85.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2828, 2007.843017, 1898.155029, 86.044998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1785, 2007.843017, 1901.687011, 86.144996, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2388, 2008.008056, 1898.031005, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2388, 2008.008056, 1902.291992, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19298, 2008.730957, 1900.022949, 83.584999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2003.038940, 1903.090942, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2005.038940, 1896.538940, 83.264999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2001.389038, 1898.890014, 83.264999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1888.954956, 84.894996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1889.954956, 84.894996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1886.954956, 84.894996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1887.954956, 84.894996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1888.005004, 84.845001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1887.005004, 84.845001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1890.005004, 84.845001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1993.458984, 1889.005004, 84.845001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT ), 0, "N", 130, "Times new roman", 100, 0, -16777216, 0, 1 );
	CreateDynamicObject( 2315, 2003.316040, 1900.718994, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2315, 2003.316040, 1899.046997, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1824, 1999.762939, 1889.105957, 83.714996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 1998.741943, 1891.317993, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2000.751953, 1886.806030, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11724, 1994.433959, 1901.659057, 83.794998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11725, 1994.530029, 1901.656982, 83.654998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19916, 1980.322998, 1901.786987, 83.224998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2571, 2005.572998, 1909.540039, 83.294998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2627, 1998.211059, 1912.979003, 83.266998, 0.000000, 0.000000, 147.199996, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2628, 1989.592041, 1914.009033, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2630, 1994.291015, 1910.447998, 83.275001, 0.000000, 0.000000, 110.599998, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2629, 1991.772949, 1914.152954, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2628, 1994.083984, 1914.009033, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2817, 1990.160034, 1910.527954, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2818, 1988.218994, 1911.509033, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19174, 2003.204956, 1914.909057, 85.794998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2100, 2005.437988, 1914.798950, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2603, 2002.336059, 1913.328002, 83.714996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2913, 1991.327026, 1914.706054, 84.233001, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2915, 2002.566040, 1912.223999, 83.422996, 0.000000, 0.000000, 147.699996, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1994.270996, 1893.975952, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 2007.829956, 1885.854003, 83.257003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 7 ], VISAGE_APARTMENT_INT );

	// RoyceGate Apartment
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1997.808959, 1915.401000, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1998.808959, 1915.401000, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1999.808959, 1915.401000, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1999.308959, 1915.401000, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1998.308959, 1915.401000, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1998.838989, 1914.548950, 81.654998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1999.838989, 1914.548950, 81.654998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1997.838989, 1914.548950, 81.654998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 19786, 1998.852050, 1914.743041, 84.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1999.530029, 1914.317016, 83.944999, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1999.530029, 1914.317016, 83.794998, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1999.530029, 1914.317016, 83.644996, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1999.530029, 1914.317016, 83.495002, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1998.088989, 1914.317016, 83.495002, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1998.088989, 1914.317016, 83.644996, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1998.088989, 1914.317016, 83.794998, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19566, 1998.088989, 1914.317016, 83.944999, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", -16 );
	CreateDynamicObject( 19619, 1998.373046, 1914.014038, 83.722999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 1996.121948, 1910.756958, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2001.723999, 1912.758056, 83.245002, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 2000.536010, 1909.035034, 83.245002, 0.000000, 0.000000, -148.500000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1998.045043, 1908.604003, 83.245002, 0.000000, 0.000000, 149.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2083, 1999.360961, 1909.098999, 83.285003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1827, 1998.901000, 1912.099975, 83.224998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 1996.427001, 1909.662963, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2069, 2001.427978, 1909.662963, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14455, 1990.125000, 1914.769042, 84.925003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3801, 1995.597045, 1914.630004, 85.735000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3801, 1994.097045, 1914.630004, 85.735000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3801, 1992.597045, 1914.630004, 85.735000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2026, 2000.748046, 1901.824951, 87.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2026, 2000.748046, 1901.824951, 87.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2026, 2000.748046, 1890.573974, 87.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2026, 2000.748046, 1890.573974, 87.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1991.228027, 1909.171020, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1991.228027, 1910.171020, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1991.228027, 1909.671020, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1991.228027, 1908.671020, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1991.238037, 1908.661010, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 18762, 1991.238037, 1908.661010, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 130, "Times new roman", 100, 1, -16777216, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1991.238037, 1910.171997, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1991.239990, 1909.392944, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 638, 1992.125976, 1909.418945, 83.955001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1991.238037, 1908.661010, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2691, 1991.771972, 1909.392944, 85.375000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "R", 120, "Times new roman", 120, 0, -16777216, 0, 1 );
	CreateDynamicObject( 2592, 1994.220947, 1887.895019, 84.184997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2325, 1994.130004, 1887.890014, 84.875000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1834, 1994.189941, 1889.011962, 84.105003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11686, 2006.011962, 1891.866943, 83.275001, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1895, 1994.219970, 1901.599975, 85.584999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2350, 2004.990966, 1893.395019, 83.675003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2350, 2004.889038, 1892.199951, 83.675003, 0.000000, 0.000000, -39.500000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2350, 2004.990966, 1890.463989, 83.675003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14651, 2000.697021, 1891.767944, 85.385002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1724, 2003.302001, 1887.129028, 83.275001, 0.000000, 0.000000, -157.100006, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1724, 2000.427978, 1886.749023, 83.275001, 0.000000, 0.000000, 167.800003, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2083, 2000.826049, 1886.182983, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14446, 1987.394042, 1891.714965, 83.855003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1987.561035, 1884.947021, 84.285003, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1987.551025, 1884.957031, 84.285003, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 13734, "hillcliff_lahills", "des_ranchwall1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1987.541015, 1884.947021, 84.285003, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 2104, 1989.227050, 1885.769042, 83.285003, 0.000000, 0.000000, -163.399993, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2229, 1989.609008, 1885.777954, 83.285003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2229, 1984.978027, 1885.777954, 83.285003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2028, 1987.147949, 1886.807983, 83.375000, 0.000000, 0.000000, -82.800003, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19786, 1986.436035, 1885.496948, 85.359001, 9.399999, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1987.551025, 1893.968017, 84.285003, 0.000000, 90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 13734, "hillcliff_lahills", "des_ranchwall1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19437, 1988.300048, 1885.381958, 85.375000, 90.000000, 0.000000, 89.699996, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	CreateDynamicObject( 19786, 1988.715942, 1885.478027, 85.361999, 9.800000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19437, 1986.800048, 1885.383056, 85.375999, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 1675, "wshxrefhse", "greygreensubuild_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1988.078979, 1886.900024, 83.264999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 912, 1992.563964, 1889.104003, 83.834999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 913, 1992.563964, 1889.094970, 85.224998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 912, 1992.563964, 1886.682983, 83.834999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 913, 1992.563964, 1886.703979, 85.224998, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", 0 );
	CreateDynamicObject( 2241, 1992.468017, 1887.876953, 83.794998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2204, 1980.394042, 1886.016967, 83.264999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2204, 1980.394042, 1892.657958, 83.264999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2206, 1980.842041, 1889.437988, 83.264999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19999, 1981.937011, 1890.250000, 83.285003, 0.000000, 0.000000, -76.099998, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19893, 1980.834960, 1890.594970, 84.214996, 0.000000, 0.000000, 64.099998, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2196, 1980.387939, 1890.635986, 84.208000, 0.000000, 0.000000, 72.400001, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 15038, 2007.597045, 1886.375000, 83.904998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19806, 1987.609008, 1888.322998, 86.678001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2286, 2002.845947, 1914.886962, 85.404998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 2254, "picture_frame_clip", "CJ_PAINTING8", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2286, 2005.655029, 1914.886962, 85.404998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 2254, "picture_frame_clip", "CJ_PAINTING27", 0 );
	CreateDynamicObject( 2257, 1991.749023, 1904.250976, 85.944999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18749, 1998.840942, 1914.598022, 84.775001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1991.354003, 1894.404052, 85.794998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "Kitchen", 130, "Times new roman", 110, 0, -16777216, 0, 1 );
	CreateDynamicObject( 948, 1992.740966, 1902.876953, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2754, 1991.400024, 1894.937988, 84.144996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1829, 1985.767944, 1899.942993, 83.764999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2484, 1984.967041, 1897.541015, 85.105003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 16779, 1983.197998, 1898.536010, 87.355003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2231, 1993.932006, 1885.796997, 86.476997, 29.000000, 0.000000, 135.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2231, 2008.012939, 1885.258056, 86.503997, 29.000000, 0.000000, -135.100006, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2231, 2008.227050, 1914.655029, 86.469001, 22.299999, 0.000000, -36.599998, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19617, 1983.411987, 1905.355957, 85.315002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14820, 2005.979003, 1899.894042, 84.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicObject( 2623, 2006.964965, 1899.906982, 84.796997, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 0, 10226, "sfeship1", "CJ_WOOD5", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 10226, "sfeship1", "CJ_WOOD5", 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2230, 2006.300048, 1900.922973, 83.684997, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 2, 10226, "sfeship1", "CJ_WOOD5", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2230, 2006.329956, 1898.230957, 83.684997, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 2, 10226, "sfeship1", "CJ_WOOD5", 0 );
	CreateDynamicObject( 1834, 1994.189941, 1886.821044, 84.105003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19128, 2001.900024, 1897.698974, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19128, 2001.900024, 1901.671020, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19172, 2008.134033, 1899.899047, 85.644996, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19174, 1987.495971, 1893.463012, 85.815002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2284, 1983.113037, 1892.996948, 85.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2281, 1980.839965, 1890.355957, 85.425003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19173, 2005.635986, 1899.865966, 83.694999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, "Streaming", 130, "David", 70, 0, -1, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2898, 1983.770996, 1909.444946, 83.264999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT ), 0, 10412, "hotel1", "carpet_red_256", -16 );
	CreateDynamicActor( 172, 2006.579956, 1891.839965, 84.277000, 90.000000, 1, 100.0, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreatePokerTable( 100000, 2000, 2004.244018, 1906.128051, 83.665000, 4, VISAGE_APARTMENT_WORLD[ 8 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 1995.291992, 1901.633056, 84.285003, 90.000000, VISAGE_APARTMENT_WORLD[ 8 ] );
	CreateRouletteTable( 2005.384033, 1911.152954, 84.315002, 0.000000, VISAGE_APARTMENT_WORLD[ 8 ] );

	// Shini Apartment
	tmpVariable = CreateDynamicObject( 2608, 1992.967041, 1904.390014, 85.084999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 2, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14624, "mafcasmain", "cof_wood2", 0 );
	tmpVariable = CreateDynamicObject( 2608, 1990.324951, 1904.390014, 85.084999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 1, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 2, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 16646, "a51_alpha", "stanwind_nt", 0 );
	SetDynamicObjectMaterial( tmpVariable, 0, 14624, "mafcasmain", "cof_wood2", 0 );
	CreateDynamicObject( 2010, 1991.605957, 1904.418945, 83.252998, 0.000000, 0.000000, -60.700000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18932, 1990.000976, 1904.390014, 84.574996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18929, 1989.651000, 1904.390014, 84.574996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18928, 1990.350952, 1904.390014, 84.574996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18930, 1990.701049, 1904.390014, 84.574996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18931, 1991.051025, 1904.390014, 84.574996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18927, 1989.651000, 1904.390014, 85.074996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18934, 1989.970947, 1904.390014, 85.074996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18935, 1990.291015, 1904.390014, 85.074996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18933, 1990.610961, 1904.390014, 85.074996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18928, 1990.931030, 1904.390014, 85.074996, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18951, 1989.620971, 1904.390014, 85.525001, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18947, 1989.964965, 1904.390014, 85.525001, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18948, 1990.308959, 1904.390014, 85.525001, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18949, 1990.652954, 1904.390014, 85.525001, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18950, 1990.996948, 1904.390014, 85.525001, 0.000000, -90.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11727, 1991.634033, 1904.213012, 86.165000, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1736, 1983.723999, 1909.395019, 86.722999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11713, 1989.125976, 1903.714965, 84.855003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1823, 2004.828979, 1910.022949, 83.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1822, 2001.576049, 1910.619995, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14820, 2006.135009, 1899.879028, 84.235000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2778, 1991.800048, 1914.360961, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1706, 2004.806030, 1913.192993, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14651, 1998.987060, 1888.619995, 85.535003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicObject( 2623, 2007.113037, 1899.917968, 84.815002, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 0, 14624, "mafcasmain", "cof_wood2", -16 );
	SetDynamicObjectMaterial( tmpVariable, 1, 14624, "mafcasmain", "cof_wood2", 1 );
	CreateDynamicObject( 19295, 2009.584960, 1899.756958, 89.915000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19296, 2007.654052, 1899.756958, 90.114997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2230, 2006.472045, 1898.253051, 83.875000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 2, 14624, "mafcasmain", "cof_wood2", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2230, 2006.472045, 1900.943969, 83.875000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 2, 14624, "mafcasmain", "cof_wood2", -16 );
	CreateDynamicObject( 11719, 1980.659057, 1898.214965, 84.324996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19625, 1980.629028, 1898.214965, 84.324996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1706, 2005.827026, 1908.880981, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1823, 2004.828979, 1910.973022, 83.282997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1705, 2001.767944, 1912.220947, 83.275001, 0.000000, 0.000000, 42.599998, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1705, 2002.293945, 1909.386962, 83.275001, 0.000000, 0.000000, 136.600006, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19128, 2002.296997, 1902.066040, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19128, 2002.296997, 1898.087036, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2681, 1990.249023, 1914.360961, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2779, 1988.688964, 1914.360961, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 1990.582031, 1913.776977, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 1989.031005, 1913.776977, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 1992.052978, 1913.776977, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19355, 1994.052978, 1901.660034, 85.794998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 0, "Shinis Apartment", 130, "Times new Roman", 70, 0, -1, 0, 1 );
	CreateDynamicObject( 633, 2007.755004, 1885.885009, 84.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 633, 1994.614013, 1886.135009, 84.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2600, 2004.015991, 1886.296997, 84.044998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2600, 2007.947021, 1889.098022, 84.044998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2256, 2005.026000, 1914.906005, 85.565002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.363037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.385009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.863037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.363037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.863037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1991.363037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1993.863037, 1884.891967, 86.184997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.885009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.385009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.885009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1991.385009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1993.885009, 1884.891967, 83.974998, 0.000000, 180.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1992.854980, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1990.624023, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.395019, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.176025, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.953979, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.723999, 1884.952026, 83.474998, 90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1992.854980, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1990.625000, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1988.395996, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1986.175048, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1983.953979, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1897, 1981.724975, 1884.952026, 87.324996, -90.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1979.843017, 1889.392944, 88.184997, 0.000000, 90.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 0, 14563, "triad_main", "casinowall1", -260011385 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 1981.291992, 1889.392944, 82.794998, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 0, 14563, "triad_main", "casinowall1", -260011385 );
	CreateDynamicObject( 19937, 1986.072998, 1890.303955, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19937, 1986.072998, 1888.394042, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicObject( 19786, 1986.182983, 1889.354003, 84.945999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 0, 1214, "metal", "CJ_FRAME_Glass", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 14738, "whorebar", "AH_whoredoor", 0 );
	CreateDynamicObject( 2233, 1986.469970, 1891.389038, 83.294998, 0.000000, 0.000000, -73.900001, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2233, 1986.260009, 1886.673950, 83.294998, 0.000000, 0.000000, -107.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2206, 1992.436035, 1888.381958, 83.264999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2298, 1984.286010, 1888.067016, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 2, 16150, "ufo_bar", "GEwhite1_64", -260011385 );
	CreateDynamicObject( 19893, 1992.437988, 1887.379028, 84.214996, 0.000000, 0.000000, -97.900001, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2196, 1992.151977, 1887.219970, 84.194999, 0.000000, 0.000000, 95.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1714, 1991.379028, 1887.541015, 83.264999, 0.000000, 0.000000, 78.500000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19327, 1980.354003, 1889.407958, 85.565002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 0, 14737, "whorewallstuff", "ah_painting2", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 1983.213012, 1893.472045, 85.605003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 0, 2255, "picture_frame_clip", "CJ_PAINTING9", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 1985.692993, 1893.472045, 85.605003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 0, 14737, "whorewallstuff", "AH_paintbond", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 1988.204956, 1893.472045, 85.605003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT ), 0, 14737, "whorewallstuff", "ah_painting1", -16 );
	CreateDynamicObject( 3503, 1981.071044, 1892.733032, 84.595001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19571, 2005.340942, 1910.810058, 83.815002, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19571, 2005.340942, 1911.670043, 83.815002, 90.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicActor( 178, 2006.780029, 1899.910034, 84.277000, 90.000000, 1, 100.0, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	ApplyDynamicActorAnimation( tmpVariable, "strip", "PUN_HOLLER", 4.1, 1, 1, 1, 1, 0 );
	CreateDynamicActor( 237, 1984.270019, 1896.339965, 84.285003, -90.000000, 1, 100.0, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicActor( 246, 1981.209960, 1898.030029, 84.285003, 90.000000, 1, 100.0, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	ApplyDynamicActorAnimation( tmpVariable, "FOOD", "SHP_Thank", 4.1, 1, 1, 1, 1, 0 );
	tmpVariable = CreateDynamicActor( 87, 1981.420043, 1892.569946, 84.285003, -108.599998, 1, 100.0, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	ApplyDynamicActorAnimation( tmpVariable, "STRIP", "STR_Loop_B", 4.1, 1, 1, 1, 1, 0 );
	tmpVariable = CreateDynamicActor( 214, 2005.540039, 1908.880004, 84.955001, 80.599998, 1, 100.0, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	ApplyDynamicActorAnimation( tmpVariable, "BEACH", "Lay_Bac_Loop", 4.1, 1, 1, 1, 1, 0 );
	CreatePokerTable( 100000, 2000, 2003.521240, 1892.146850, 83.654998, 4, VISAGE_APARTMENT_WORLD[ 9 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 1995.287963, 1901.667968, 84.275001, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ] );
	CreateRouletteTable( 1996.678955, 1911.754028, 84.305000, 90.000000, VISAGE_APARTMENT_WORLD[ 9 ] );

	// Veloxity_ Apartment
	CreateDynamicObject( 339, 2008.173950, 1899.629028, 86.485000, 0.000000, 45.000000, 101.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 339, 2008.110961, 1900.157958, 86.485000, -1.000000, -320.000000, 274.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2233, 1993.900024, 1900.006958, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1609, 2007.926025, 1899.999023, 84.775001, 90.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2906, 1980.696044, 1898.010986, 84.363998, -4.400000, -1.600000, 176.399993, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2908, 1986.005004, 1898.262939, 84.394996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 14446, 1982.119018, 1889.348022, 83.845001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 2964, 1998.697998, 1888.451049, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1891.790039, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 16779, 2002.489990, 1900.362060, 87.394996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1891.790039, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1886.017944, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 19786, 1994.022949, 1901.682983, 86.095001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11724, 1994.411010, 1901.603027, 83.805000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11725, 1994.437011, 1901.610961, 83.694999, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2323, 1981.831054, 1886.017944, 83.245002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 1723, 1999.529052, 1904.839965, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2001.671020, 1898.396972, 83.254997, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1723, 2003.772949, 1902.567993, 83.254997, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1814, 2000.050048, 1901.081054, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19580, 1985.504028, 1897.422973, 84.315002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2858, 2000.529785, 1901.568969, 83.754783, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 14446, 1982.119018, 1889.348022, 83.845001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 2161, 1992.916015, 1886.287963, 83.275001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1886.287963, 84.595001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2233, 1993.900024, 1904.189941, 83.285003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2232, 1994.328979, 1885.817993, 86.806999, 161.399993, -0.600000, -45.500000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 0, "", "", 0 );
	CreateDynamicObject( 2232, 2008.240966, 1885.421997, 86.755996, 18.100000, 179.699996, -139.699996, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2600, 2007.569946, 1908.994018, 84.016998, 0.000000, 0.000000, 130.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2232, 2007.766967, 1914.479003, 86.824996, 18.100000, 179.699996, 330.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2001, 1994.477050, 1885.854003, 83.257003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1885.927001, 87.285003, 0.000000, 180.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2241, 2007.761962, 1885.853027, 83.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1889.910034, 83.275001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1895, 1991.517944, 1904.314941, 85.123001, 0.000000, 0.000000, -179.800003, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3104, 1999.286987, 1888.312988, 84.285003, -38.599998, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3105, 1998.151000, 1888.384033, 84.285003, -45.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3000, 1999.474975, 1888.764038, 84.205001, 82.500000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 338, 1997.275024, 1888.095947, 83.411003, 17.700000, -8.899999, 100.400001, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 18688, 1994.331054, 1901.467041, 81.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 15038, 2007.630981, 1914.468017, 83.897003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 11724, 1992.532958, 1887.912963, 83.785003, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 2161, 1992.916015, 1889.910034, 84.584999, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1889.909057, 85.885002, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.956054, 1888.548950, 87.275001, 0.000000, 180.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2161, 1992.916015, 1887.238037, 87.275001, 0.000000, 180.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19632, 1992.571044, 1887.899047, 83.524002, -70.599998, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11725, 1992.409057, 1887.921020, 83.665000, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 19786, 1992.922973, 1887.916992, 85.165000, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, 10789, "xenon_sfse", "ws_white_wall1", -259308269 );
	CreateDynamicObject( 16779, 1985.288940, 1889.286010, 87.404998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19172, 1980.343017, 1889.343994, 86.095001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2165, 1986.828002, 1885.921020, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2356, 1986.665039, 1887.214965, 83.294998, 0.000000, 0.000000, 155.199996, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2002, 1984.881958, 1886.032958, 83.264999, 0.000000, 1.200000, 157.800003, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1988.870971, 1887.140014, 83.264999, 0.000000, 0.000000, 110.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 1988.381958, 1888.637939, 83.324996, 0.000000, 0.000000, 70.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1827, 1990.395996, 1888.362060, 83.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2801, 1990.306030, 1888.435058, 83.305000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2251, 1980.765014, 1893.017944, 85.095001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2251, 1980.765014, 1885.864990, 85.095001, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2105, 1980.696044, 1892.093017, 84.714996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2105, 1980.696044, 1886.569946, 84.714996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 14455, 1989.057983, 1893.280029, 84.955001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1983.735961, 1893.213012, 83.264999, 0.000000, 0.000000, 134.500000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1990.156005, 1893.144042, 83.305000, 0.000000, 0.000000, -176.699996, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 639, 1983.884033, 1884.715942, 85.855003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 639, 1989.666015, 1884.715942, 85.855003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11690, 2004.662963, 1894.484985, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2003.558959, 1894.516967, 83.264999, 0.000000, 0.000000, 90.099998, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2004.817016, 1895.519042, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2005.639038, 1894.521972, 83.264999, 0.000000, 0.000000, 270.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1720, 2004.687988, 1893.442016, 83.264999, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1664, 2004.625000, 1893.906005, 84.205001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1664, 2004.625000, 1895.036987, 84.205001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1212, 2004.629028, 1894.430053, 84.056999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2010, 1994.365966, 1894.034057, 83.294998, 0.000000, 0.000000, 140.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11713, 1983.464965, 1905.215942, 85.235000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19325, 1989.410766, 1914.895507, 85.692817, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT ), 0, "Visage Apartment", 120, "Times New Roman", 64, 1, -16777216, 0, 1 );
	CreatePokerTable( 100000, 2000, 2003.975219, 1889.492553, 83.664772, 4, VISAGE_APARTMENT_WORLD[ 10 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 2004.537963, 1912.535034, 84.264999, 0.000000, VISAGE_APARTMENT_WORLD[ 10 ] );
	CreateRouletteTable( 1998.226074, 1912.094970, 84.315002, 90.000000, VISAGE_APARTMENT_WORLD[ 10 ] );

	// Zach Apartment
	CreateDynamicObject( 2833, 1999.135986, 1886.714965, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2833, 2002.697998, 1886.714965, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2082, 2000.930053, 1886.744018, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 2003.681030, 1887.312011, 83.264999, 0.000000, 0.000000, 200.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1727, 2000.004028, 1887.020996, 83.264999, 0.000000, 0.000000, 160.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3806, 2006.870971, 1884.599975, 83.495002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3806, 2009.072021, 1886.730957, 83.495002, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 3806, 1996.209960, 1884.599975, 83.495002, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	tmpVariable = CreateDynamicObject( 18090, 2001.792968, 1913.066040, 85.824996, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( tmpVariable, 1, 16150, "ufo_bar", "GEwhite1_64", 1 );
	SetDynamicObjectMaterial( tmpVariable, 2, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( tmpVariable, 3, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( tmpVariable, 4, 16150, "ufo_bar", "GEwhite1_64", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 16150, "ufo_bar", "GEwhite1_64", 1 );
	SetDynamicObjectMaterial( tmpVariable, 6, 16150, "ufo_bar", "GEwhite1_64", 1 );
	SetDynamicObjectMaterial( tmpVariable, 7, 16150, "ufo_bar", "GEwhite1_64", 1 );
	SetDynamicObjectMaterial( tmpVariable, 8, 16150, "ufo_bar", "GEwhite1_64", 1 );
	SetDynamicObjectMaterial( tmpVariable, 9, 16150, "ufo_bar", "GEwhite1_64", 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1911.968994, 84.277000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2006.145996, 1911.968994, 84.277000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 1491, 2006.636962, 1911.863037, 83.257003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1912.948974, 84.277000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2008.656982, 1913.948974, 84.277000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2007.656982, 1911.968994, 98.257003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18980, 2006.946044, 1911.968994, 98.257003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", -16 );
	CreateDynamicObject( 19824, 2000.628051, 1914.619995, 84.922996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19824, 2001.427978, 1914.619995, 84.932998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19824, 2001.427978, 1914.619995, 84.922996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2298, 1984.293945, 1887.942016, 83.224998, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2106, 1980.550048, 1890.630004, 83.745002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2106, 1980.550048, 1887.928955, 83.745002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2826, 1983.421997, 1887.911010, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2108, 1981.279052, 1886.188964, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2108, 1981.279052, 1892.592041, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2241, 1992.588989, 1885.708984, 83.735000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2126, 2004.488037, 1899.417968, 83.264999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2003.958007, 1901.948974, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1726, 2005.979003, 1897.776000, 83.275001, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2255, 1992.444946, 1888.197021, 85.764999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2235, 2007.285034, 1885.451049, 83.245002, 0.000000, 0.000000, 45.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 10226, "sfeship1", "CJ_WOOD5", -16 );
	CreateDynamicObject( 2252, 2007.276000, 1886.187011, 83.972999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2254, 1993.973022, 1887.878051, 85.563003, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 14867, 1987.050048, 1893.136962, 84.794998, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 10226, "sfeship1", "CJ_WOOD5", 0 );
	tmpVariable = CreateDynamicObject( 2296, 1994.406005, 1900.701049, 83.275001, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( tmpVariable, 7, 10226, "sfeship1", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( tmpVariable, 5, 10226, "sfeship1", "CJ_WOOD5", -16 );
	SetDynamicObjectMaterial( tmpVariable, 3, 10226, "sfeship1", "CJ_WOOD5", -16 );
	CreateDynamicObject( 1764, 1998.092041, 1902.823974, 83.264999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 13187, 1990.779052, 1914.920043, 85.464996, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 19174, "samppictures", "samppicture1", -16 );
	CreateDynamicObject( 1765, 1995.878051, 1903.693969, 83.285003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1765, 1996.879028, 1899.562988, 83.285003, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 1815, 1995.812011, 1901.203979, 83.294998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 10226, "sfeship1", "CJ_WOOD5", 0 );
	CreateDynamicObject( 11686, 2003.235961, 1911.991943, 83.205001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 11686, 2000.823974, 1911.989990, 83.203002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 1998.767944, 1914.687011, 84.682998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 12954, "sw_furniture", "CJ_WOOD5", -16 );
	CreateDynamicObject( 15038, 1994.326049, 1889.291015, 83.864997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 15038, 1994.326049, 1886.600952, 83.864997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2259, 2007.671997, 1899.890014, 84.985000, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2084, 2007.895019, 1900.079956, 83.254997, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 16780, 1997.743041, 1894.781005, 87.245002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1828, 1986.619018, 1889.512939, 83.275001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2094, 1991.411010, 1888.694946, 83.315002, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19786, 1992.677978, 1888.182006, 84.944999, 0.000000, 0.000000, -90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2600, 1985.135986, 1885.588012, 84.055000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2206, 1989.776977, 1886.000976, 83.294998, 0.000000, 0.000000, 180.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19893, 1989.196044, 1886.064941, 84.235000, 0.000000, 0.000000, -154.199996, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1714, 1988.661010, 1887.145996, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1824, 1999.119995, 1894.737060, 83.735000, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19822, 2002.904052, 1914.661987, 85.449996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 948, 1996.688964, 1914.473999, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1665, 1996.370971, 1901.615966, 83.815002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1543, 1996.633056, 1901.569946, 83.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1544, 1996.292968, 1901.959960, 83.785003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 638, 2007.733032, 1904.369018, 83.944999, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 2244, 1997.743041, 1914.552001, 84.572998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 1999.707031, 1911.295043, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 2001.217041, 1911.064941, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1716, 2002.878051, 1911.295043, 83.254997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1488, 1998.749023, 1914.114990, 85.894996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1488, 1998.749023, 1914.114990, 84.915000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19823, 2001.141967, 1914.681030, 84.934997, 0.000000, 0.000000, -76.300003, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19823, 2000.892944, 1914.660034, 84.934997, 0.000000, 0.000000, -118.500000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19821, 2000.753051, 1914.660034, 85.464996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19821, 2001.003051, 1914.660034, 85.464996, 0.000000, 0.000000, 97.199996, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19818, 2001.292968, 1914.660034, 85.555000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19818, 2001.532958, 1914.660034, 85.555000, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	SetDynamicObjectMaterial( CreateDynamicObject( 2550, 2003.574951, 1914.173950, 82.563003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "metalic128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2550, 2002.593994, 1914.173950, 82.563003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "metalic128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2550, 2001.623046, 1914.173950, 82.563003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "metalic128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2550, 2000.651977, 1914.173950, 82.563003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "metalic128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2550, 1999.671020, 1914.173950, 82.563003, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 1676, "wshxrefpump", "metalic128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19428, 2004.060058, 1914.870971, 82.642997, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19428, 1999.566040, 1914.901000, 82.483001, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT ), 0, 16150, "ufo_bar", "GEwhite1_64", 0 );
	CreateDynamicObject( 1512, 2000.175048, 1911.675048, 84.492996, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19940, 2001.468017, 1914.666015, 84.922996, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19940, 2001.468017, 1914.666015, 85.462997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19940, 2003.089965, 1914.666015, 85.462997, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19940, 2002.639038, 1914.666015, 84.922996, 0.000000, 0.000000, 90.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1544, 2001.853027, 1911.968994, 84.343002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1544, 2002.133056, 1911.968994, 84.343002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1951, 2004.484008, 1911.993041, 84.502998, 0.000000, 0.000000, -88.500000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 1665, 2003.105957, 1911.493041, 84.322998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19921, 2002.542968, 1914.349975, 84.523002, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 19896, 2000.426025, 1911.635986, 84.322998, 0.000000, 0.000000, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateDynamicObject( 355, 1998.281982, 1911.954956, 84.282997, 94.500000, 100.800003, 53.398998, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreatePokerTable( 100000, 2000, 2002.390014, 1906.432983, 83.675003, 4, VISAGE_APARTMENT_WORLD[ 11 ], VISAGE_APARTMENT_INT );
	CreateBlackjackTable( 50000, 1991.609985, 1905.417968, 84.282997, 180.000000, VISAGE_APARTMENT_WORLD[ 11 ] );
	CreateRouletteTable( 2004.093994, 1892.959960, 84.315002, 0.000000, VISAGE_APARTMENT_WORLD[ 11 ] );
}

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS `VISAGE_APARTMENTS` (
		`ID` int(11) primary key auto_increment,
		`OWNER_ID` int(11),
		`TITLE` varchar(30) DEFAULT "Apartment",
		`PASSCODE` varchar(4) DEFAULT NULL,
		`WORLD` int(11) DEFAULT NULL,
		`GAMBLING` tinyint(1) DEFAULT 0
	);

	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (690025,10,1);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (277833,11,1);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (13,12,1);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (30,13,0);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (435396,15,0);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (493400,16,0);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (483892,17,0);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (140,14,0);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (658457,18,0);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (314783,19,1);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (479950,20,0);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (38,21,1);
	INSERT INTO `VISAGE_APARTMENTS`(`OWNER_ID`, `WORLD`,`GAMBLING`) VALUES (25,22,1);
*/
