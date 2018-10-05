/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_TREES                   ( 16 )

/* ** Variables ** */
enum E_TREE_DATA
{
	E_OBJECT,       		Float: E_HEALTH,
	Text3D: E_LABEL,    	bool: E_CUT,    		bool: E_CHOPPED,
	Float: E_X,         	Float: E_Y,     		Float: E_Z
};

static stock
	Float: g_treeExportLocations   	[ ] [ 3 ] =
	{
	    { -520.2759, -504.32880, 24.6917 },
		{ -377.7403, -1438.5587, 25.7266 },
		{ -62.98320, -1122.2581, 1.21400 },
		{ 89.445900, -311.85220, 1.57810 },
		{ 362.28260, 865.053800, 20.4063 },
		{ 2399.5352, 2798.89310, 10.8203 },
		{ -2002.906, -2409.2000, 30.6250 }
	},
	p_treeExportLocation            [ MAX_PLAYERS ] = { 0xFF, ... },
	g_treeData                      [ MAX_TREES ] [ E_TREE_DATA ],
	Iterator: trees 				< MAX_TREES >,
 	g_LogCountObject 				= INVALID_OBJECT_ID,
	g_LogsInStock 					= 0
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// pickups
	CreateDynamicPickup( 341, 2, -2327.8730, -100.6307, 35.2878 ); // Chainsaw @Garcia
	// CreateDynamicPickup( 341, 2, -2069.1431, 1788.9657, 43.7386 ); // Chainsaw @Alcatraz

	// create the sign for wood count
	SetDynamicObjectMaterialText( CreateDynamicObject( 19353, -2337.8610, -107.4217, 36.2978, 0.0000, 0.0000, 90.0551 ), 0, "Wood Chipper", 130, "impact", 80, 0, -1, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19353, -2336.3244, -113.2057, 40.6778, 0.0000, 0.0000, 179.9560 ), 0, "Lumberjack", 130, "impact", 100, 0, -1, 0, 1 );
	SetDynamicObjectMaterialText( ( g_LogCountObject = CreateDynamicObject( 3074, -2329.4724, -106.0164, 33.1678, 0.0000, 0.0000, 90.000000 ) ), 0, "0 Logs Ready", 130, "Arial", 0, 1, -1, 0, 1);
	SetDynamicObjectMaterial( CreateDynamicObject( 12814, -2337.1, -94.00, 34.28, 0.0, 0.0, 270.0, .streamdistance = 500.0, .priority = 100 ), 0, 19381, "all_walls", "desgreengrass" );
	SetDynamicObjectMaterial( CreateDynamicObject( 12814, -2337.6, -105.3, 34.28, 0.0, 0.0, 90.00, .streamdistance = 500.0, .priority = 100 ), 0, 19381, "all_walls", "desgreengrass" );

	// create the trees near san fierro
	Lumberjack_CreateTree( -2358.10000000, -84.60000000, 34.10000000 );
	Lumberjack_CreateTree( -2349.90000000, -85.40000000, 34.10000000 );
	Lumberjack_CreateTree( -2341.20000000, -86.20000000, 34.10000000 );
	Lumberjack_CreateTree( -2341.20000000, -93.70000000, 34.10000000 );
	Lumberjack_CreateTree( -2350.90000000, -92.80000000, 34.10000000 );
	Lumberjack_CreateTree( -2357.40000000, -92.20000000, 34.10000000 );
	Lumberjack_CreateTree( -2357.90000000, -97.40000000, 34.10000000 );
	Lumberjack_CreateTree( -2350.90000000, -98.10000000, 34.10000000 );
	Lumberjack_CreateTree( -2341.70000000, -99.00000000, 34.10000000 );
	Lumberjack_CreateTree( -2334.80000000, -86.00000000, 34.10000000 );
	Lumberjack_CreateTree( -2334.90000000, -93.20000000, 34.10000000 );
	Lumberjack_CreateTree( -2334.80000000, -98.80000000, 34.10000000 );
	Lumberjack_CreateTree( -2335.00000000, -103.9000000, 34.10000000 );
	Lumberjack_CreateTree( -2341.50000000, -103.5000000, 34.10000000 );
	Lumberjack_CreateTree( -2350.40000000, -103.3000000, 34.10000000 );
	Lumberjack_CreateTree( -2358.34000000, -103.0300000, 34.10000000 );
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	new
		keys, weaponid;

	GetPlayerKeys( playerid, keys, weaponid, weaponid );
	weaponid = GetPlayerWeapon( playerid );

	if ( ( keys & KEY_FIRE ) && weaponid == 9 ) // Lumberjack
	{
		new
			Float: fX, Float: fY, Float: fZ;

	    foreach ( new i : trees ) if ( ! g_treeData[ i ] [ E_CUT ] )
	    {
	 		if ( GetDynamicObjectPos( g_treeData[ i ] [ E_OBJECT ], fX, fY, fZ ) )
	 		{
				fZ += 2.3;

				if ( IsPlayerInRangeOfPoint( playerid, 2.0, fX, fY, fZ ) )
				{
					if ( g_treeData[ i ] [ E_HEALTH ] > 0.0 )
					{
						if ( ( g_treeData[ i ] [ E_HEALTH ] -= ( 1.75 + fRandomEx( 1, 5 ) ) ) < 0.0 )
							g_treeData[ i ] [ E_HEALTH ] = 0.0;

			           	UpdateDynamic3DTextLabelText( g_treeData[ i ] [ E_LABEL ], COLOR_YELLOW, sprintf( "%0.1f", g_treeData[ i ] [ E_HEALTH ] ) );
					}
					else
		   			{
			            GivePlayerCash( playerid, 250 );
					    g_treeData[ i ] [ E_HEALTH ] = 0.0;
						g_treeData[ i ] [ E_CUT ] = true;
						GetDynamicObjectPos( g_treeData[ i ] [ E_OBJECT ], fX, fY, fZ );
						MoveDynamicObject( g_treeData[ i ] [ E_OBJECT ], fX + 0.1, fY + 0.1, fZ + 0.1, ( 0.05 ), 90.0, 0.0, 0.0 );
			            SendServerMessage( playerid, "You have cut the tree down, now chop the logs down! "COL_ORANGE"/wood chop{FFFFFF}!" );
			           	UpdateDynamic3DTextLabelText( g_treeData[ i ] [ E_LABEL ], COLOR_YELLOW, sprintf( "%0.1f", g_treeData[ i ] [ E_HEALTH ] ) );
					}
					break;
				}
			}
	    }
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	Lumberjack_StopDelivery( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	if ( Lumberjack_StopDelivery( playerid ) ) {
 		GameTextForPlayer( playerid, "~r~job stopped!", 4000, 0 );
	}
	return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate )
{
    if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER ) { // Driver has a new state?
		if ( Lumberjack_StopDelivery( playerid ) ) {
	 		GameTextForPlayer( playerid, "~r~job stopped!", 4000, 0 );
		}
    }
	return 1;
}

hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;

	if ( p_LumberjackDeliver[ playerid ] == checkpointid )
	{
		new
			Float: fDistance = GetDistanceFromPointToPoint( -2330.8535, -113.9084, g_treeExportLocations[ p_treeExportLocation[ playerid ] ] [ 0 ], g_treeExportLocations[ p_treeExportLocation[ playerid ] ] [ 1 ] ),
			iTimeElapsed = g_iTime - p_LumberjackTimeElapsed[ playerid ],
			iTheoreticalFinish = floatround( fDistance / 30.0 ) // distance / 25m/s (2000m / 25m/s)
		;

		// Check if it is really quick to finish
		if ( iTimeElapsed < iTheoreticalFinish ) {
		    SendServerMessage( playerid, "You've been kicked due to suspected teleport hacking (0xBC-%d-%d).", iTheoreticalFinish, iTimeElapsed );
	    	KickPlayerTimed( playerid );
	    	return 1;
		}

	    new cash = floatround( fDistance ) + 5000;
        DestroyDynamicRaceCP( p_LumberjackDeliver[ playerid ] );
        p_LumberjackDeliver[ playerid ] = 0xFFFF;
		ShowPlayerHelpDialog( playerid, 7500, "Great job! You've earned ~y~%s~w~~h~!~n~~n~Navigate to the import location to pack your truck with logs.~n~~n~~y~~h~Info: The truck blip has been updated, navigate to it.", cash_format( cash ) );
        //SendServerMessage( playerid, "You've made "COL_GOLD"%s"COL_WHITE" from exporting. Go and pick another box up!"  );
	    GivePlayerCash( playerid, cash );
	    GivePlayerScore( playerid, 5 );

		DestroyDynamicMapIcon( p_LumberjackMapIcon[ playerid ] );
		p_LumberjackMapIcon[ playerid ] = CreateDynamicMapIconEx( -2330.8535, -113.9084, 34.00, 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
	    p_LumberjackReturn[ playerid ] = CreateDynamicRaceCP( 0, -2330.8535, -113.9084, 34.00, g_treeExportLocations[ p_treeExportLocation[ playerid ] ] [ 0 ], g_treeExportLocations[ p_treeExportLocation[ playerid ] ] [ 1 ], g_treeExportLocations[ p_treeExportLocation[ playerid ] ] [ 2 ], 4.0, -1, -1, playerid );
		Beep( playerid );
		return 1;
	}

	else if ( p_LumberjackReturn[ playerid ] == checkpointid )
	{
	    if ( g_LogsInStock < 1 )
	    	return SendError( playerid, "There is not enough logs in stock to export." );

        DestroyDynamicRaceCP( p_LumberjackReturn[ playerid ] );
        p_LumberjackReturn[ playerid ] = 0xFFFF;
        g_LogsInStock--;
        UpdateWoodStockObject( );
		new id = random( sizeof( g_treeExportLocations ) );
		p_treeExportLocation[ playerid ] = id;

		DestroyDynamicMapIcon( p_LumberjackMapIcon[ playerid ] );
		p_LumberjackMapIcon[ playerid ] = CreateDynamicMapIconEx( g_treeExportLocations[ id ] [ 0 ], g_treeExportLocations[ id ] [ 1 ], g_treeExportLocations[ id ] [ 2 ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );

		ShowPlayerHelpDialog( playerid, 7500, "You've packed your truck with logs. ~g~~h~Navigate your way to the export location.~n~~n~Info:~y~~h~ The truck blip has been updated, navigate to it." );
        p_LumberjackDeliver[ playerid ] = CreateDynamicRaceCP( 0, g_treeExportLocations[ id ] [ 0 ], g_treeExportLocations[ id ] [ 1 ], g_treeExportLocations[ id ] [ 2 ], -2330.8535, -113.9084, 34.00, 4.0, -1, -1, playerid );
       	Beep( playerid );
		return 1;
	}
	return 1;
}

hook OnServerGameDayEnd( )
{
	foreach ( new i : trees ) if ( g_treeData[ i ] [ E_CHOPPED ] )
	{
		DestroyDynamicObject( g_treeData[ i ] [ E_OBJECT ] );
		g_treeData[ i ] [ E_CUT ] = false;
		g_treeData[ i ] [ E_CHOPPED ] = false;
		g_treeData[ i ] [ E_HEALTH ] = 100.0;
		UpdateDynamic3DTextLabelText( g_treeData[ i ] [ E_LABEL ], COLOR_YELLOW, "100.0" );
		g_treeData[ i ] [ E_OBJECT ] = CreateDynamicObject( 618, g_treeData[ i ] [ E_X ], g_treeData[ i ] [ E_Y ], g_treeData[ i ] [ E_Z ], 0.0, 0.0, 0.0 );
	}
	return 1;
}

/* ** Commands ** */
CMD:wood( playerid, params[ ] )
{
	new
	    Float: X, Float: Y, Float: Z;

	if ( strmatch( params, "chop" ) )
	{
	    new
	    	count = 0;

	   	foreach ( new i : trees )
	    {
			if ( g_treeData[ i ] [ E_CUT ] == false ) continue;
			GetDynamicObjectPos( g_treeData[ i ] [ E_OBJECT ], X, Y, Z );

			if ( IsPlayerInRangeOfPoint( playerid, 4.0, X, Y, Z ) && g_treeData[ i ] [ E_CHOPPED ] == false )
			{
			    StopDynamicObject( g_treeData[ i ] [ E_OBJECT ] );
			    DestroyDynamicObject( g_treeData[ i ] [ E_OBJECT ] );
			    g_treeData[ i ] [ E_OBJECT ] = CreateDynamicObject( 831, X, Y, Z + 0.75, 0.0, 0.0, 0.0 );
			    SetPlayerPos( playerid, X, Y + 2, Z + 0.75 );
			    p_Wood[ playerid ]++;
			    g_treeData[ i ] [ E_CHOPPED ] = true;
			    count++;
			    GivePlayerCash( playerid, 250 );
				SendServerMessage( playerid, "Tree successfully chopped into smaller pieces. Go to the wood chipper and type "COL_ORANGE"/wood chip{FFFFFF}!" );
				break;
		  	}
	    }

		if ( ! count ) {
			SendError( playerid, "You are not next to any chopped tree." );
		}
		return 1;
	}
	else if ( strmatch( params, "chip" ) )
	{
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this feature while in a vehicle." );
	    if ( IsPlayerInRangeOfPoint( playerid, 4.0, -2338.20, -106.51, 34.00 ) )
	    {
	        if ( p_Wood[ playerid ] < 1 )
	            return SendError( playerid, "You are not carrying any chopped wood." );

		    new object = CreateDynamicObject( 14872, -2338.20, -106.51, 34.00, -27.78, 89.40, 1.92 );
		    MoveDynamicObject( object, -2338.20, -106.51, 33.5, 0.10 );
			Streamer_Update( playerid ); // SyncObject( playerid );
            PlayerPlaySound( playerid, 1153, -2338.20, -106.51, 33.99 );
            GivePlayerCash( playerid, 500 );
		    SetTimerEx( "lumberjack_RemoveWood", 9000, false, "d", object );
            p_Wood[ playerid ]--;
            g_LogsInStock ++;
           	UpdateWoodStockObject( );
			return SendServerMessage( playerid, "You've placed a chopped log in the wood chipper. You have made a total of "COL_GOLD"$1,000!" );
		}
		else
		{
			return SendError( playerid, "You are not next to the wood chipper." );
		}
	}
	else if ( strmatch( params, "start" ) )
	{
		if ( p_StartedLumberjack{ playerid } == true )
		    return SendError( playerid, "You are already doing this job." );

	    if ( !IsPlayerInAnyVehicle( playerid ) )
	        return SendError( playerid, "You are not in any vehicle." );

		if ( GetVehicleModel( GetPlayerVehicleID( playerid ) ) != 455 )
	        return SendError( playerid, "You are not inside the wood exporting truck." );

		if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER )
		    return SendError( playerid, "You must be a driver of this vehicle to proceed." );

 		if ( g_LogsInStock < 1 )
	    	return SendError( playerid, "There is not enough logs in stock to export." );

		new id = random( sizeof( g_treeExportLocations ) );
		p_treeExportLocation[ playerid ] = id;

		static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;
		DestroyDynamicMapIcon( p_LumberjackMapIcon[ playerid ] );
		p_LumberjackMapIcon[ playerid ] = CreateDynamicMapIconEx( -2330.8535, -113.9084, 34.00, 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );

		p_LumberjackTimeElapsed[ playerid ] = g_iTime;
		p_LumberjackReturn[ playerid ] = CreateDynamicRaceCP( 0, -2330.8535, -113.9084, 34.00, g_treeExportLocations[ id ] [ 0 ], g_treeExportLocations[ id ] [ 1 ], g_treeExportLocations[ id ] [ 2 ], 4.0, -1, -1, playerid );
		p_StartedLumberjack{ playerid } = true;

		ShowPlayerHelpDialog( playerid, 7500, "A ~g~~h~truck blip~w~~h~ has been shown on your radar. Go to where the truck blip is located to export and import logs." );
		return 1;
	}
	else if ( strmatch( params, "stop" ) )
	{
		if ( Lumberjack_StopDelivery( playerid ) ) {
	 		return GameTextForPlayer( playerid, "~r~job stopped!", 4000, 0 );
		} else {
		    return SendError( playerid, "You are not doing this job." );
		}
	}
	return SendUsage( playerid, "/wood [CHOP/CHIP/START/STOP]" );
}

/* ** Functions ** */
stock Lumberjack_CreateTree( Float: X, Float: Y, Float: Z )
{
	new
		treeid = Iter_Free( trees );

	if ( treeid != -1 )
	{
		Iter_Add( trees, treeid );
	    g_treeData[ treeid ] [ E_CUT ] = false;
	    g_treeData[ treeid ] [ E_CHOPPED ] = false;
	    g_treeData[ treeid ] [ E_X ] = X;
	    g_treeData[ treeid ] [ E_Y ] = Y;
	    g_treeData[ treeid ] [ E_Z ] = Z;
	    g_treeData[ treeid ] [ E_OBJECT ] = CreateDynamicObject( 618, X, Y, Z, 0.0, 0.0, 0.0 );
	    g_treeData[ treeid ] [ E_HEALTH ] = 100.0;
		g_treeData[ treeid ] [ E_LABEL ] = CreateDynamic3DTextLabel( "100.0", COLOR_YELLOW, X, Y, Z + 0.5, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1 );
	}
	return treeid;
}

function lumberjack_RemoveWood( objectid ) {
	StopDynamicObject( objectid ), DestroyDynamicObject( objectid );
}

stock UpdateWoodStockObject( ) {
	return SetDynamicObjectMaterialText( g_LogCountObject, 0, sprintf( "%d Logs Ready", g_LogsInStock ), 130, "Arial", 0, 1, -1, 0, 1 );
}

stock Lumberjack_StopDelivery( playerid )
{
	if ( ! p_StartedLumberjack{ playerid } )
		return 0;

	p_StartedLumberjack{ playerid } = false;
    DestroyDynamicRaceCP( p_LumberjackReturn[ playerid ] );
    p_LumberjackReturn[ playerid ] = 0xFFFF;
    DestroyDynamicRaceCP( p_LumberjackDeliver[ playerid ] );
    p_LumberjackDeliver[ playerid ] = 0xFFFF;
    p_treeExportLocation[ playerid ] = 0xFF;
	DestroyDynamicMapIcon( p_LumberjackMapIcon[ playerid ] );
	p_LumberjackMapIcon[ playerid ] = 0xFFFF;
 	return 1;
}
