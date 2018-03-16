/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: apartments.inc
 * Purpose: apartment system for visage
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_VISAGE_APARTMENTS    	13
#define MAX_PASSCODE				4

// dialogs
#define DIALOG_VISAGE_APTS 			17317
#define DIALOG_VISAGE_APT_PW 		17318
#define DIALOG_VISAGE_APT_CONFIG 	17319
#define DIALOG_VISAGE_APT_TRANSFER	17320
#define DIALOG_VISAGE_APT_TITLE		17321
#define DIALOG_VISAGE_APT_PASSCODE	17322

/* ** Constants ** */
static const
	Float: VISAGE_APARTMENT_ENTRANCE[ 3 ] = { 0.0, 0.0, 0.0 },
	Float: VISAGE_APARTMENT_EXIT[ 3 ] = { 0.0, 0.0, 0.0 }
;

/* ** Variables ** */
enum E_APARTMENT_DATA
{
	E_OWNER_ID,    			E_TITLE[ 30 ], 			E_PASSCODE[ MAX_PASSCODE ],
	bool: E_GAMBLING,		E_EXIT_CP,				E_OWNER_NAME[ MAX_PLAYER_NAME ],

	E_WORLD,				E_INTERIOR
};

new
	g_VisageApartmentData        	[ MAX_VISAGE_APARTMENTS ] [ E_APARTMENT_DATA ],
	Iterator: visageapartments 		< MAX_VISAGE_APARTMENTS >,
	p_VisageApartmentSpawn 			[ MAX_PLAYERS ],
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
				g_VisageApartmentData[ handle ] [ E_OWNER_ID ] = cache_get_field_content_int( i, "OWNER_ID", dbHandle );
				g_VisageApartmentData[ handle ] [ E_INTERIOR ] = cache_get_field_content_int( i, "INTERIOR", dbHandle );
				g_VisageApartmentData[ handle ] [ E_WORLD ] = cache_get_field_content_int( i, "WORLD", dbHandle );
				cache_get_field_content( i, "TITLE", g_VisageApartmentData[ handle ] [ E_TITLE ], dbHandle, 30 );
				cache_get_field_content( i, "OWNER", g_VisageApartmentData[ handle ] [ E_OWNER_NAME ], dbHandle, MAX_PLAYER_NAME );
				cache_get_field_content( i, "PASSCODE", g_VisageApartmentData[ handle ] [ E_PASSCODE ], dbHandle, 4 );

				// appearance
				CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, VISAGE_APARTMENT_EXIT[ 0 ], VISAGE_APARTMENT_EXIT[ 1 ], VISAGE_APARTMENT_EXIT[ 2 ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, g_VisageApartmentData[ handle ] [ E_INTERIOR ], g_VisageApartmentData[ handle ] [ E_WORLD ] );
				g_VisageApartmentData[ handle ] [ E_EXIT_CP ] = CreateDynamicCP( VISAGE_APARTMENT_EXIT[ 0 ], VISAGE_APARTMENT_EXIT[ 1 ], VISAGE_APARTMENT_EXIT[ 2 ], 1.0, g_VisageApartmentData[ handle ] [ E_INTERIOR ], g_VisageApartmentData[ handle ] [ E_WORLD ], -1, 50.0 );

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
	// query
	mysql_function_query( dbHandle, "SELECT u.`NAME` as `OWNER`, a.* FROM `VISAGE_APARTMENTS` a LEFT JOIN `USERS` u ON a.`OWNER_ID`=u.`ID`", true, "OnVisageApartmentLoad", "" );

	// create checkpoints
	CreateDynamic3DTextLabel( "[PRIVATE APARTMENTS]", COLOR_GOLD, VISAGE_APARTMENT_ENTRANCE[ 0 ], VISAGE_APARTMENT_ENTRANCE[ 1 ], VISAGE_APARTMENT_ENTRANCE[ 2 ], 20.0 );
	g_entranceCheckpoint = CreateDynamicCP( VISAGE_APARTMENT_ENTRANCE[ 0 ], VISAGE_APARTMENT_ENTRANCE[ 1 ], VISAGE_APARTMENT_ENTRANCE[ 2 ], 2.0, 0, -1, -1, 100.0 );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( checkpointid == g_entranceCheckpoint ) {
		return ShowPlayerVisageApartments( playerid ), 1;
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VISAGE_APTS && response )
	{
		new
			x = -1;

		foreach ( new handle : visageapartments )
		{
			if ( x ++ == listitem )
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

		// todo
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

		// todo
	}
	return 1;
}

/* ** Functions ** */
stock ShowPlayerVisageApartments( playerid )
{
	szLargeString = ""COL_WHITE"Owner\n"COL_WHITE"Title\n";
	foreach ( new handle : visageapartments ) {
		format( szLargeString, sizeof ( szLargeString ), "%s"COL_GREY"%s\t%s\n", szLargeString, g_VisageApartmentData[ handle ] [ E_OWNER_NAME ], g_VisageApartmentData[ handle ] [ E_TITLE ] );
	}
	ShowPlayerDialog( playerid, DIALOG_VISAGE_APTS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Visage Apartment", szLargeString, "Access", "Close" );
	return 1;
}

stock SetPlayerToVisageApartment( playerid, handle )
{
	// set player position
	SetPVarInt( playerid, "in_visage_apartment", handle );
	SetPlayerPos( playerid, VISAGE_APARTMENT_EXIT[ 0 ], VISAGE_APARTMENT_EXIT[ 1 ], VISAGE_APARTMENT_EXIT[ 2 ] );
	SetPlayerVirtualWorld( playerid, g_VisageApartmentData[ handle ] [ E_WORLD ] );
	SetPlayerInterior( playerid, g_VisageApartmentData[ handle ] [ E_INTERIOR ] );

	// greeting
	SendServerMessage( playerid, "You are now inside of the "COL_GREY"%s"COL_WHITE"'s apartment.", g_VisageApartmentData[ handle ] [ E_TITLE ] );
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
		// todo
	}
	return 1;
}

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS `VISAGE_APARTMENTS` (
		`ID` int(11) primary key auto_increment,
		`OWNER_ID` int(11),
		`TITLE` varchar(30) DEFAULT "Apartment",
		`PASSCODE` varchar(4) DEFAULT NULL,
		`INTERIOR` int(11) DEFAULT 1,
		`WORLD` int(11) DEFAULT 1,
		`GAMBLING` tinyint(1) DEFAULT 0
	)
*/
