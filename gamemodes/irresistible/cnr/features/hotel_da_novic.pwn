/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\hotel_da_novic.pwn
 * Purpose: hotel da novic with operational apartments (very dated)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_AFLOORS                 ( 20 )

/* ** Variables ** */
enum E_FLAT_DATA
{
	E_OWNER[ 24 ],    		E_NAME[ 30 ], 		E_LOCKED,
	bool: E_CREATED,		E_FURNITURE
};

static stock
	g_apartmentData                 [ 19 ] [ E_FLAT_DATA ], // A1 = 19 Floors
	g_apartmentElevator             = INVALID_OBJECT_ID,
	g_apartmentElevatorGate         = INVALID_OBJECT_ID,
    g_apartmentElevatorLevel        = 0,
	g_apartmentElevatorDoor1		[ MAX_AFLOORS ]	= INVALID_OBJECT_ID,
	g_apartmentElevatorDoor2		[ MAX_AFLOORS ] = INVALID_OBJECT_ID,
	p_apartmentEnter                [ MAX_PLAYERS char ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// Load apartments
	mysql_function_query( dbHandle, "SELECT * FROM `APARTMENTS`", true, "NovicHotel_Load", "" );

	// Apartments
	CreateDynamicObject( 4587, -1971.51, 1356.26, 65.32, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 28.26, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 55.54, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 82.77, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 109.89, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 4605, -1992.10, 1353.31, 1.11, 0.00, 0.00, -180.00, .priority = 1 );

	g_apartmentElevator = CreateDynamicObject( 18755, -1955.09, 1365.51, 8.36, 0.00, 0.00, 90.00 );

	for( new level, Float: Z; level < MAX_AFLOORS; level++ )
	{
		switch( level )
		{
		    case 0:     Z = 8.36;
		    case 1:     Z = 17.03;
		    default:    Z = 17.03 + ( ( level - 1 ) * 5.447 );
		}
		g_apartmentElevatorDoor1[ level ] = CreateDynamicObject( 18756, -1955.05, 1361.64, Z, 0.00, 0.00, -90.00 );
		g_apartmentElevatorDoor2[ level ] = CreateDynamicObject( 18757, -1955.05, 1361.64, Z, 0.00, 0.00, -90.00 );
	}

	// Bank
	g_bankvaultData[ CITY_SF ] [ E_OBJECT ] = CreateDynamicObject( 18766, -1412.565063, 859.274536, 983.132873, 0.000000, 90.000000, 90.000000 );
	g_bankvaultData[ CITY_LV ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ CITY_LV ] [ E_WORLD ] );
	g_bankvaultData[ CITY_LS ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ CITY_LS ] [ E_WORLD ] );
	SetDynamicObjectMaterial( g_bankvaultData[ CITY_SF ] [ E_OBJECT ], 0, 18268, "mtbtrackcs_t", "mp_carter_cage", -1 );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( PRESSED( KEY_SECONDARY_ATTACK ) )
	{
		// Call Elevator Down
		if ( CanPlayerExitEntrance( playerid ) && ! IsPlayerTied( playerid ) && ! IsPlayerInAnyVehicle( playerid ) )
		{
			if ( IsPlayerInArea( playerid, -2005.859375, -1917.968750, 1339.843750, 1396.484375 ) && GetPlayerInterior( playerid ) == 0 )
			{
				GetDynamicObjectPos( g_apartmentElevator, X, Y, Z );
				if ( IsPlayerInRangeOfPoint( playerid, 2.0, X, Y, Z ) )
				{
					ClearAnimations( playerid ); // clear-fix

				    if ( IsDynamicObjectMoving( g_apartmentElevator ) )
				        return SendError( playerid, "You must wait for the elevator to stop operating to select a floor again." );

	                szLargeString = "Ground Floor\n";

	                for ( new i = 0; i < sizeof( g_apartmentData ); i++ ) // First floor
	                {
	                    if ( g_apartmentData[ i ] [ E_CREATED ] ) {
	                    	format( szLargeString, sizeof( szLargeString ), "%s%s - %s\n", szLargeString, g_apartmentData[ i ] [ E_OWNER ], g_apartmentData[ i ] [ E_NAME ] );
	                    } else {
						    strcat( szLargeString, "$5,000,000 - Available For Purchase!\n" );
						}
					}

					ShowPlayerDialog( playerid, DIALOG_APARTMENTS, DIALOG_STYLE_LIST, "{FFFFFF}Apartments", szLargeString, "Select", "Cancel" );
					return 1;
				}

				for ( new floors = 0; floors < MAX_AFLOORS; floors++ )
				{
					GetDynamicObjectPos( g_apartmentElevatorDoor1[ floors ], X, Y, Z );
                	if ( IsPlayerInRangeOfPoint( playerid, 4.0, X, Y, Z ) )
                	{
						ClearAnimations( playerid ); // clear-fix
					    if ( IsDynamicObjectMoving( g_apartmentElevator ) ) {
		       				SendError( playerid, "The elevator is operating, please wait." );
		       				break;
						}

	    				PlayerPlaySound( playerid, 1085, 0.0, 0.0, 0.0 );
						NovicHotel_CallElevator( floors ); // First floor
						break;
                	}
				}

				UpdatePlayerEntranceExitTick( playerid );
				return 1;
			}
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_APARTMENTS && response )
	{
		new Float: X, Float: Y, Float: Z;
		GetDynamicObjectPos( g_apartmentElevator, X, Y, Z );
		if ( !IsPlayerInRangeOfPoint( playerid, 2.0, X, Y, Z ) )
			return SendError( playerid, "You must be near the elevator to use this!" );

	    if ( listitem == 0 ) NovicHotel_CallElevator( 0 );
	    else
	    {
			new id = listitem - 1;
			p_apartmentEnter{ playerid } = id;
			if ( strmatch( g_apartmentData[ id ] [ E_OWNER ], "No-one" ) || isnull( g_apartmentData[ id ] [ E_OWNER ] ) || !g_apartmentData[ id ] [ E_CREATED ] )
			{
			 	ShowPlayerDialog( playerid, DIALOG_APARTMENTS_BUY, DIALOG_STYLE_MSGBOX, "{FFFFFF}Are you interested?", "{FFFFFF}This apartment is available for sale. The price is $5,000,000.\nIf you wish to buy it, please click 'Purchase'.", "Purchase", "Deny" );
			}
			else if ( !strmatch( g_apartmentData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
			    if ( g_apartmentData[ id ] [ E_LOCKED ] ) {
					return SendError( playerid, "This apartment has been locked by its owner." );
				}
			}
	    	NovicHotel_CallElevator( id + 1 );
		}
	}
	else if ( dialogid == DIALOG_APARTMENTS_BUY && response )
	{
	    if ( NovicHotel_GetPlayerApartments( playerid ) > 0 )
	        return SendError( playerid, "You can only own one apartment." );

	    if ( GetPlayerCash( playerid ) < 5000000 )
	        return SendError( playerid, "You don't have enough money for this ($5,000,000)." );

		GivePlayerCash( playerid, -5000000 );

		new aID = p_apartmentEnter{ playerid };
		g_apartmentData[ aID ] [ E_CREATED ] = true;
		format( g_apartmentData[ aID ] [ E_OWNER ], 24, "%s", ReturnPlayerName( playerid ) );
		format( g_apartmentData[ aID ] [ E_NAME ], 30, "Apartment %d", aID );
		g_apartmentData[ aID ] [ E_LOCKED ] = 0;

		format( szNormalString, 100, "INSERT INTO `APARTMENTS` VALUES (%d,'%s','Apartment %d',0)", aID, mysql_escape( ReturnPlayerName( playerid ) ), aID );
	    mysql_single_query( szNormalString );

		SendServerMessage( playerid, "You have purchased an apartment for "COL_GOLD"$5,000,000"COL_WHITE"." );
	}
	else if ( dialogid == DIALOG_FLAT_CONFIG && response )
	{
		for( new id, x = 0; id < sizeof( g_apartmentData ); id ++ )
		{
			if ( g_apartmentData[ id ] [ E_CREATED ] && strmatch( g_apartmentData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
		       	if ( x == listitem )
		      	{
					SetPVarInt( playerid, "flat_editing", id );
		      	    SendServerMessage( playerid, "You are now controlling the settings over "COL_GREY"%s", g_apartmentData[ id ] [ E_NAME ] );
		      		ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
		      		break;
				}
		      	x++;
			}
		}
	}
	else if ( dialogid == DIALOG_FLAT_CONTROL )
	{
	    if ( !response )
	        return cmd_flat( playerid, "config" );

		switch( listitem )
		{
		    case 0:
		    {
		    	SetPlayerSpawnLocation( playerid, "APT", GetPVarInt( playerid, "flat_editing" ) );
				SendServerMessage( playerid, "You have set your spawning location to the specified apartment. To stop this you can use \"/flat stopspawn\"." );
				ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
			}
			case 1:
			{
		        new id = GetPVarInt( playerid, "flat_editing" );
             	g_apartmentData[ id ] [ E_LOCKED ] = ( g_apartmentData[ id ] [ E_LOCKED ] == 1 ? 0 : 1 );
				mysql_single_query( sprintf( "UPDATE `APARTMENTS` SET `LOCKED`=%d WHERE `ID`=%d", g_apartmentData[ id ] [ E_LOCKED ], id  ) );
				SendServerMessage( playerid, "You have %s the specified apartment.", g_apartmentData[ id ] [ E_LOCKED ] == 1 ? ( "locked" ) : ( "unlocked" ) );
				ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
			}
		    case 2:
		    {
		   		ShowPlayerDialog( playerid, DIALOG_FLAT_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Owned Apartments", ""COL_WHITE"Input the apartment title you want to change with:", "Submit", "Back" );
			}
		    case 3: ShowPlayerDialog( playerid, DIALOG_YOU_SURE_APART, DIALOG_STYLE_MSGBOX, "{FFFFFF}Owned Apartments", ""COL_WHITE"Are you sure that you want to sell your apartment?", "Yes", "No" );
		}
	}
	else if ( dialogid == DIALOG_YOU_SURE_APART )
	{
		if ( ! response )
   			return ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );

		new id = GetPVarInt( playerid, "flat_editing" );

		g_apartmentData[ id ] [ E_CREATED ] = false;
		strcpy( g_apartmentData[ id ] [ E_OWNER ], "No-one" );
		// format( g_apartmentData[ id ] [ E_OWNER ], MAX_PLAYER_NAME, "%s", "No-one" );
		format( g_apartmentData[ id ] [ E_NAME ], 30, "Apartment %d", id );
		g_apartmentData[ id ] [ E_LOCKED ] = 0;

		format( szNormalString, 40, "DELETE FROM `APARTMENTS` WHERE `ID`=%d", id );
	    mysql_single_query( szNormalString );

        GivePlayerCash( playerid, 3000000 );
        printf( "%s(%d) sold their apartment", ReturnPlayerName( playerid ), playerid );

   		return SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have successfully sold your apartment for "COL_GOLD"$3,000,000"COL_WHITE".");
	}
	else if ( dialogid == DIALOG_FLAT_TITLE )
	{
	    if ( !response )
	        return ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );

		if ( !strlen( inputtext ) )
			return ShowPlayerDialog( playerid, DIALOG_FLAT_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Owned Apartments", ""COL_WHITE"Input the apartment title you want to change with:\n\n"COL_RED"Must be more than 0 characters.", "Submit", "Back" );

		new id = GetPVarInt( playerid, "flat_editing" );
		mysql_single_query( sprintf( "UPDATE `APARTMENTS` SET `NAME`='%s' WHERE `ID`=%d", mysql_escape( inputtext ), id ) );
		format( g_apartmentData[ id ] [ E_NAME ], 30, "%s", inputtext );
 		SendServerMessage( playerid, "You have successfully changed the name of your apartment." );
  		ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
	}
	return 1;
}

hook OnDynamicObjectMoved( objectid )
{
	if ( objectid == g_apartmentElevator )
	{
		DestroyDynamicObject( g_apartmentElevatorGate ), g_apartmentElevatorGate = INVALID_OBJECT_ID;

		new Float: Y, Float: Z, i = g_apartmentElevatorLevel;
		GetDynamicObjectPos( g_apartmentElevatorDoor1[ i ], Y, Y, Z );
		MoveDynamicObject( g_apartmentElevatorDoor1[ i ], -1956.8068, Y, Z, 5.0 );

		GetDynamicObjectPos( g_apartmentElevatorDoor2[ i ], Y, Y, Z );
		MoveDynamicObject( g_apartmentElevatorDoor2[ i ], -1953.3468, Y, Z, 5.0 );
		return 1;
	}
	return 1;
}

/* ** SQL Threads ** */
thread NovicHotel_Load( )
{
	new
		rows, fields, i = -1, aID,
		Field[ 5 ],
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			cache_get_field_content( i, "ID", Field ),			aID = strval( Field );
			cache_get_field_content( i, "OWNER", g_apartmentData[ aID ] [ E_OWNER ], dbHandle, 24 );
			cache_get_field_content( i, "NAME", g_apartmentData[ aID ] [ E_NAME ], dbHandle, 30 );
			cache_get_field_content( i, "LOCKED", Field ), g_apartmentData[ aID ] [ E_LOCKED ] = strval( Field );
			g_apartmentData[ aID ] [ E_CREATED ] = true;
		}
	}
	printf( "[FLATS]: %d apartments have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

/* ** Commands ** */
CMD:flat( playerid, params[ ] )
{
	new count = 0;
	szBigString[ 0 ] = '\0';
	for( new i; i < sizeof( g_apartmentData ); i++ ) if ( g_apartmentData[ i ] [ E_CREATED ] )
	{
		if ( strmatch( g_apartmentData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
		{
		    count++;
		    format( szBigString, sizeof( szBigString ), "%s%s\n", szBigString, g_apartmentData[ i ] [ E_NAME ] );
		}
	}
	if ( count == 0 ) return SendError( playerid, "You don't own any apartments." );

	ShowPlayerDialog( playerid, DIALOG_FLAT_CONFIG, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", szBigString, "Select", "Cancel" );
	return 1;
}

/* ** Functions ** */
stock NovicHotel_IsOwner( playerid, apartmentid ) {
	return g_apartmentData[ apartmentid ] [ E_CREATED ] && strmatch( g_apartmentData[ apartmentid ] [ E_OWNER ], ReturnPlayerName( playerid ) );
}

stock NovicHotel_SetPlayerToFloor( playerid, floor )
{
	pauseToLoad( playerid );
    SetPlayerInterior( playerid, 0 );
    SetPlayerFacingAngle( playerid, 180.0 );
    SetPlayerPos( playerid, -1955.0114, 1360.8344, 17.03 + ( floor * 5.447 ) );
	return 1;
}

stock NovicHotel_UpdateOwnerName( playerid, const newName[ ] )
{
	mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE `APARTMENTS` SET `OWNER` = '%e' WHERE `OWNER` = '%e'", newName, ReturnPlayerName( playerid ) );
	mysql_single_query( szNormalString );

	for( new i = 0; i < sizeof( g_apartmentData ); i++ ) {
		if ( strmatch( g_apartmentData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) {
			format( g_apartmentData[ i ] [ E_OWNER ], 24, "%s", newName );
		}
	}
	return 1;
}

stock NovicHotel_CallElevator( level )
{
	new Float: Z, Float: LastZ;

	if ( level >= MAX_AFLOORS )
	    return -1; // Invalid Floor

	switch( level ) {
	    case 0:     Z = 8.36;
	    case 1:     Z = 17.03;
	    default:    Z = 17.03 + ( ( level - 1 ) * 5.447 );
	}

	GetDynamicObjectPos( g_apartmentElevatorDoor1[ g_apartmentElevatorLevel ], LastZ, LastZ, LastZ );
	MoveDynamicObject( g_apartmentElevatorDoor1[ g_apartmentElevatorLevel ], -1955.05, 1361.64, LastZ, 5.0 );
	MoveDynamicObject( g_apartmentElevatorDoor2[ g_apartmentElevatorLevel ], -1955.05, 1361.64, LastZ, 5.0 );

	DestroyDynamicObject( g_apartmentElevatorGate ), g_apartmentElevatorGate = INVALID_OBJECT_ID;
	g_apartmentElevatorGate = CreateDynamicObject( 19304, -1955.08, 1363.74, LastZ, 0.00, 0.00, 0.00 );
 	SetObjectInvisible( g_apartmentElevatorGate ); // Just looks ugly...
	MoveDynamicObject( g_apartmentElevatorGate, -1955.08, 1363.74, Z, 7.0 );

	MoveDynamicObject( g_apartmentElevator, -1955.09, 1365.51, Z, 7.0 );

	g_apartmentElevatorLevel = level; // For the last level.
	return 1;
}

stock NovicHotel_GetPlayerApartments( playerid )
{
	for( new i; i < sizeof( g_apartmentData ); i++ ) if ( g_apartmentData[ i ] [ E_CREATED ] )
	{
		if ( strmatch( g_apartmentData[ i ][ E_OWNER ], ReturnPlayerName( playerid ) ) )
		    return 1;
	}
	return 0;
}
