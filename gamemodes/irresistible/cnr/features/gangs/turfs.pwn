/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\gangs\turfs.pwn
 * Purpose: turfing module for gangs
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#if defined MAX_FACILITIES
	#define MAX_TURFS 				( sizeof( g_gangzoneData ) + MAX_FACILITIES )
#else
	#define MAX_TURFS 				( sizeof( g_gangzoneData ) )
#endif

#define INVALID_GANG_TURF 			( -1 )

#define TAKEOVER_NEEDED_PEOPLE		( 1 )

#define COLOR_GANGZONE				0x00000080
#define COLOR_HARDPOINT				0xFF000080

/* ** Variables ** */
enum e_GANG_ZONE_DATA
{
	Float: E_MIN_X,
	Float: E_MIN_Y,
	Float: E_MAX_X,
	Float: E_MAX_Y,
	E_CITY
};

static const
	g_gangzoneData[ ] [ e_GANG_ZONE_DATA ] =
	{
		{ -1725.0, 1301.5, -1538.0, 1437.5, CITY_SF },
		{ -2868.0, 1012.5, -2768.0, 1217.5, CITY_SF },
		{ -2497.0, 932.5, -2392.0, 1069.5, CITY_SF },
		{ -2054.0, 1084.5, -1892.0, 1171.5, CITY_SF },
		{ -1569.0, 822.5, -1418.0, 1019.5, CITY_SF },
		{ -2088.0, 570.5, -2010.0, 728.5, CITY_SF },
		{ -2526.0, 571.5, -2391.0, 705.5, CITY_SF },
		{ -2766.0, 324.5, -2651.0, 426.5, CITY_SF },
		{ -2386.0, 70.5, -2273.0, 227.5, CITY_SF },
		{ -2139.0, 115.5, -2013.0, 311.5, CITY_SF },
		{ -2001.0, 69.5, -1911.0, 219.5, CITY_SF },
		{ -2096.0, -279.5, -2011.0, -111.5, CITY_SF },
		{ -2523.0, -321.5, -2264.0, -215.5, CITY_SF },
		{ -2153.0, -515.5, -1960.0, -374.5, CITY_SF },
		{ -2000.0, 853.5, -1904.0, 913.5, CITY_SF }
	}
;

/* ** Variables ** */
enum E_TURF_ZONE_DATA {
	E_ID,

	E_OWNER,
	E_COLOR,

	E_AREA,
	E_FACILITY_GANG
};

new
	g_gangTurfData					[ MAX_TURFS ] [ E_TURF_ZONE_DATA ],
	Iterator: turfs 				< MAX_TURFS >,

	g_gangHardpointTurf				= INVALID_GANG_TURF,
	g_gangHardpointPreviousTurf 	= INVALID_GANG_TURF,
	g_gangHardpointAttacker			= INVALID_GANG_ID,
	g_gangHardpointCaptureTime 		[ MAX_GANGS ]

;

/* ** Forwards ** */
forward OnPlayerUpdateGangZone( playerid, zoneid );

stock Float: Turf_GetHardpointPrizePool( Float: max_payout = 500000.0 )
{
	new
		Float: total_payout = float( Iter_Count( Player ) ) * 10000.0;

	return total_payout < max_payout ? total_payout : max_payout;
}

/* ** Hooks ** */
hook OnGameModeInit( )
{
	/* ** Gangzone Allocation ** */
	for ( new i = 0; i < sizeof( g_gangzoneData ); i ++ ) {
		Turf_Create( g_gangzoneData[ i ] [ E_MIN_X ], g_gangzoneData[ i ] [ E_MIN_Y ], g_gangzoneData[ i ] [ E_MAX_X ], g_gangzoneData[ i ] [ E_MAX_Y ], INVALID_GANG_ID, COLOR_GANGZONE );
	}
	return 1;
}

hook OnServerTickSecond( )
{
	new
		hardpoint_turf = g_gangHardpointTurf;

	if ( hardpoint_turf == INVALID_GANG_TURF ) {
		return Turf_CreateHardpoint( );
	}

	if ( g_gangHardpointAttacker != INVALID_GANG_ID )
	{
		new total_in_turf = Turf_GetPlayersInTurf( hardpoint_turf );
		new attacking_members = GetPlayersInGangZone( hardpoint_turf, g_gangHardpointAttacker );

		// no attacking members inside the turf
		if ( ! attacking_members )
		{
			new
				new_attacker = INVALID_GANG_ID;

			foreach ( new playerid : Player ) if ( GetPlayerGang( playerid ) != INVALID_GANG_ID && IsPlayerInDynamicArea( playerid, g_gangTurfData[ hardpoint_turf ] [ E_AREA ] ) && Turf_IsAbleToTakeover( playerid ) ) {
				new_attacker = GetPlayerGang( playerid );
				break;
			}

			if ( new_attacker != INVALID_GANG_ID ) {
				SendClientMessageToGang( g_gangHardpointAttacker, g_gangData[ g_gangHardpointAttacker ] [ E_COLOR ], "[TURF] "COL_WHITE"The territory hardpoint is now being contested by %s!", ReturnGangName( new_attacker ) );
			}

			Turf_SetHardpointAttacker( new_attacker );
		}

		new
			current_attacker = g_gangHardpointAttacker;

		// the attacker could be changed from above, so double checking
		if ( current_attacker != INVALID_GANG_ID )
		{
			// add seconds
			g_gangHardpointCaptureTime[ current_attacker ] ++;

			// get potential earnings
			new total_capture_seconds = Turf_GetTotalCaptureSeconds( );

			// alert gang members
			foreach ( new playerid : Player ) if ( GetPlayerGang( playerid ) != INVALID_GANG_ID && IsPlayerInDynamicArea( playerid, g_gangTurfData[ hardpoint_turf ] [ E_AREA ] ) && Turf_IsAbleToTakeover( playerid ) )
			{
				new player_gang = GetPlayerGang( playerid );

				// calculate player earnings
				new potential_earnings = total_capture_seconds > 0 ? floatround( float( g_gangHardpointCaptureTime[ player_gang ] ) / float( total_capture_seconds ) * Turf_GetHardpointPrizePool( ) ) : 0;

	    		// message the attacker that they gotta attack
	    		if ( player_gang == current_attacker )
	    		{
	    			new
	    				rivals_members = total_in_turf - attacking_members;

	    			if ( rivals_members ) {
	        			ShowPlayerHelpDialog( playerid, 1500, "~b~Defend~w~ from %d enemy gang member%s!~n~~n~Earning potential is ~g~%s", rivals_members, rivals_members == 1 ? ( "" ) : ( "s" ), cash_format( potential_earnings ) );
	    			} else {
	    				ShowPlayerHelpDialog( playerid, 1500, "~g~%s~w~ is in control now %d seconds!~n~~n~Earning potential is ~g~%s", ReturnGangName( current_attacker ), g_gangHardpointCaptureTime[ current_attacker ], cash_format( potential_earnings ) );
	    			}
	        	}

	        	// message the defender
	        	else if ( player_gang != current_attacker ) {
	        		ShowPlayerHelpDialog( playerid, 1500, "~r~Kill~w~ %d %s member%s!~n~~n~Earning potential is ~r~%s", attacking_members, ReturnGangName( current_attacker ), attacking_members == 1 ? ( "" ) : ( "s" ), cash_format( potential_earnings ) );
	        	}
	        }
	   	}
	}
	else
	{
		new
			new_attacker = INVALID_GANG_ID;

		foreach ( new playerid : Player ) if ( GetPlayerGang( playerid ) != INVALID_GANG_ID && IsPlayerInDynamicArea( playerid, g_gangTurfData[ hardpoint_turf ] [ E_AREA ] ) && Turf_IsAbleToTakeover( playerid ) ) {
			new_attacker = GetPlayerGang( playerid );
			break;
		}

		Turf_SetHardpointAttacker( new_attacker );
	}
	return 1;
}

stock Turf_GetPlayersInTurf( turfid )
{
	new
		players_accum = 0;

	foreach ( new g : gangs ) {
		players_accum += GetPlayersInGangZone( turfid, g );
	}
	return players_accum;
}

stock Turf_CreateHardpoint( )
{
	// reset gang accumulated time
	for ( new i = 0; i < sizeof ( g_gangHardpointCaptureTime ); i ++ ) {
		g_gangHardpointCaptureTime[ i ] = 0;
	}

	// force a random turf at all times
	new
		random_turf = INVALID_GANG_TURF;

	do {
		random_turf = random( sizeof( g_gangzoneData ) );
	}
	while ( random_turf == g_gangHardpointPreviousTurf );

	// allocate new hardpoint
	g_gangHardpointTurf = random_turf;
	g_gangHardpointAttacker = INVALID_GANG_ID;

	// update hardpoint textdraw
	foreach ( new playerid : Player )
	{
		if ( g_gangHardpointPreviousTurf != INVALID_GANG_TURF && IsPlayerInDynamicArea( playerid, g_gangTurfData[ g_gangHardpointPreviousTurf ] [ E_AREA ] ) ) {
			CallLocalFunction( "OnPlayerUpdateGangZone", "dd", playerid, g_gangHardpointPreviousTurf );
		}
		else if ( g_gangHardpointTurf != INVALID_GANG_TURF && IsPlayerInDynamicArea( playerid, g_gangTurfData[ g_gangHardpointTurf ] [ E_AREA ] ) ) {
			CallLocalFunction( "OnPlayerUpdateGangZone", "dd", playerid, g_gangHardpointTurf );
		}
	}

	// redraw gangzones
	Turf_RedrawGangZonesForAll( );
	printf("New Hardpoint" );
	return 1;
}

hook OnGangUnload( gangid, bool: deleted )
{
	g_gangHardpointCaptureTime[ gangid ] = 0;
	return 1;
}

hook OnServerGameDayEnd( )
{
	new
		total_capture_seconds = Turf_GetTotalCaptureSeconds( );

	// payout gangs if there is any capable
	if ( total_capture_seconds )
	{
		// payout gangs
		foreach ( new g : gangs )
		{
			new Float: capture_ratio = float( g_gangHardpointCaptureTime[ g ] ) / float( total_capture_seconds );
			new earnings = floatround( capture_ratio * Turf_GetHardpointPrizePool( ) );

			if ( earnings > 0 )
			{
				g_gangData[ g ] [ E_RESPECT ] += floatround( capture_ratio * 100.0 ); // give the gang a % of respect out of how much they captured

				GiveGangCash( g, earnings );
				SaveGangData( g );

				SendClientMessageToGang( g, g_gangData[ g ] [ E_COLOR ], "[GANG] "COL_GOLD"%s"COL_WHITE" has been earned from territories and deposited in the gang bank account.", cash_format( earnings ) );
			}
		}
	}

	// reset hardpoint
	g_gangHardpointPreviousTurf = g_gangHardpointTurf;
	g_gangHardpointTurf = INVALID_GANG_TURF;
	return 1;
}

hook OnPlayerSpawn( playerid )
{
	Turf_RedrawPlayerGangZones( playerid );
	return 1;
}

hook OnPlayerEnterDynArea( playerid, areaid )
{
	if ( ! IsPlayerNPC( playerid ) )
	{
		new
			first_turf = Turf_GetFirstTurf( playerid );

		// update textdraws
		CallLocalFunction( "OnPlayerUpdateGangZone", "dd", playerid, first_turf );
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}

stock Turf_SetHardpointAttacker( gangid )
{
	if ( g_gangHardpointAttacker == INVALID_GANG_ID && gangid == INVALID_GANG_ID )
		return;

	// set current attacker
  	g_gangHardpointAttacker = gangid;

  	// alert gang
  	if ( gangid != INVALID_GANG_ID ) {
 		SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[TURF] "COL_WHITE"The gang is now contesting the territory hardpoint!" );
  	}

  	// update label
	foreach ( new playerid : Player ) if ( g_gangHardpointTurf != INVALID_GANG_TURF && IsPlayerInDynamicArea( playerid, g_gangTurfData[ g_gangHardpointTurf ] [ E_AREA ] ) ) {
		CallLocalFunction( "OnPlayerUpdateGangZone", "dd", playerid, g_gangHardpointTurf );
	}

  	// redraw
  	Turf_RedrawGangZonesForAll( );
}

hook OnPlayerLeaveDynArea( playerid, areaid )
{
	if ( ! IsPlayerNPC( playerid ) )
	{
		new
			total_areas = GetPlayerNumberDynamicAreas( playerid );

		// reduced to another area
		if ( total_areas )
		{
			new
				first_turf = Turf_GetFirstTurf( playerid );

			CallLocalFunction( "OnPlayerUpdateGangZone", "dd", playerid, first_turf );
		}

		// if the player is in no areas, then they left
		else CallLocalFunction( "OnPlayerUpdateGangZone", "dd", playerid, INVALID_GANG_TURF );
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}

public OnPlayerUpdateGangZone( playerid, zoneid )
{
	if ( ! IsPlayerMovieMode( playerid ) )
	{
		if ( zoneid == INVALID_GANG_TURF )
			return PlayerTextDrawSetString( playerid, g_ZoneOwnerTD[ playerid ], "_" );

		if ( g_gangTurfData[ zoneid ] [ E_FACILITY_GANG ] != INVALID_GANG_ID ) {
			PlayerTextDrawSetString( playerid, g_ZoneOwnerTD[ playerid ], sprintf( "~p~(FACILITY)~n~~w~~h~%s", ReturnGangName( g_gangTurfData[ zoneid ] [ E_OWNER ] ) ) );
		} else {
			if ( g_gangTurfData[ g_gangHardpointTurf ] [ E_ID ] != g_gangTurfData[ zoneid ] [ E_ID ] ) {
				PlayerTextDrawSetString( playerid, g_ZoneOwnerTD[ playerid ], "~b~~h~(INACTIVE HARDPOINT)~n~~w~~h~Unchallenged" );
			} else {
				PlayerTextDrawSetString( playerid, g_ZoneOwnerTD[ playerid ], sprintf( "~r~~h~(ACTIVE HARDPOINT)~n~~w~~h~%s", g_gangHardpointAttacker != INVALID_GANG_ID ? ( ReturnGangName( g_gangHardpointAttacker ) ) : ( "Unchallenged" ) ) );
			}
		}
	}
	return 1;
}

/* ** Functions ** */
stock Turf_Create( Float: min_x, Float: min_y, Float: max_x, Float: max_y, owner_id = INVALID_GANG_ID, color = COLOR_GANGZONE, facility_gang_id = INVALID_GANG_ID )
{
	new
		id = Iter_Free( turfs );

	if ( id != ITER_NONE )
	{
		// set turf owners
		g_gangTurfData[ id ] [ E_OWNER ] = owner_id;
		g_gangTurfData[ id ] [ E_COLOR ] = color;
		g_gangTurfData[ id ] [ E_FACILITY_GANG ] = facility_gang_id;

		// create area
		g_gangTurfData[ id ] [ E_ID ] = GangZoneCreate( min_x, min_y, max_x, max_y );
		g_gangTurfData[ id ] [ E_AREA ] = CreateDynamicRectangle( min_x, min_y, max_x, max_y, 0, 0 );

		// add to iterator
		Iter_Add( turfs, id );
	}
	return id;
}

stock Turf_GetOwner( id ) {
	return g_gangTurfData[ id ] [ E_OWNER ];
}

stock Turf_GetFacility( id ) {
	return g_gangTurfData[ id ] [ E_FACILITY_GANG ];
}

stock Turf_GetFirstTurf( playerid )
{
	new
		current_areas[ 4 ];

	GetPlayerDynamicAreas( playerid, current_areas );

	foreach( new i : Reverse(turfs) )
	{
		if ( current_areas[ 0 ] == g_gangTurfData[ i ] [ E_AREA ] || current_areas[ 1 ] == g_gangTurfData[ i ] [ E_AREA ] || current_areas[ 2 ] == g_gangTurfData[ i ] [ E_AREA ] || current_areas[ 3 ] == g_gangTurfData[ i ] [ E_AREA ] )
		{
			return i;
		}
	}
	return -1;
}

stock Turf_ResetGangTurfs( gangid )
{
 	foreach ( new z : turfs )
 	{
 		if ( g_gangTurfData[ z ] [ E_OWNER ] == gangid )
 		{
			new
				facility_gang = g_gangTurfData[ z ] [ E_FACILITY_GANG ];

		   	if ( g_gangTurfData[ z ] [ E_FACILITY_GANG ] != INVALID_GANG_ID && Iter_Contains( gangs, g_gangTurfData[ z ] [ E_FACILITY_GANG ] ) )
		   	{
	    		g_gangTurfData[ z ] [ E_COLOR ] = setAlpha( g_gangData[ facility_gang ] [ E_COLOR ], 0x80 );
	 			g_gangTurfData[ z ] [ E_OWNER ] = facility_gang;
				GangZoneShowForAll( g_gangTurfData[ z ] [ E_ID ], g_gangTurfData[ z ] [ E_COLOR ] );
		   	}
		   	else
		   	{
	 			g_gangTurfData[ z ] [ E_COLOR ] = COLOR_GANGZONE;
	 			g_gangTurfData[ z ] [ E_OWNER ] = INVALID_GANG_ID;
				GangZoneShowForAll( g_gangTurfData[ z ] [ E_ID ], COLOR_GANGZONE );
		   	}
 		}
 	}
}

stock Turf_ShowGangOwners( playerid )
{
	if ( ! Iter_Count( turfs ) )
		return SendError( playerid, "There is currently no trufs on the server." );

	szHugeString[ 0 ] = '\0';

	foreach( new turfid : turfs )
	{
		new
			szLocation[ MAX_ZONE_NAME ], Float: min_x, Float: min_y;

		Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ turfid ] [ E_AREA ], E_STREAMER_MIN_X, min_x );
		Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ turfid ] [ E_AREA ], E_STREAMER_MIN_Y, min_y );

		GetZoneFromCoordinates( szLocation, min_x, min_y );

	    if ( g_gangTurfData[ turfid ][ E_OWNER ] == INVALID_GANG_ID ) {
	    	format( szHugeString, sizeof( szHugeString ), "%s%s\t"COL_GREY"Unoccupied\n", szHugeString, szLocation );
	    }
	    else {
	    	format( szHugeString, sizeof( szHugeString ), "%s%s\t{%06x}%s\n", szHugeString, szLocation, g_gangTurfData[ turfid ][ E_COLOR ] >>> 8 , ReturnGangName( g_gangTurfData[ turfid ][ E_OWNER ] ) );
	    }
	}
	return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, ""COL_WHITE"Gang Turfs", szHugeString, "Close", "" );
}

stock Turf_GetCentrePos( zoneid, &Float: X, &Float: Y ) // should return the centre but will do for now
{
	Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_X, X );
	Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_Y, Y );
}

stock GetPlayersInGangZone( z, g )
{
	if ( g == INVALID_GANG_ID )
		return 0;

	new
		count = 0;

	foreach ( new i : Player ) if ( p_GangID[ i ] == g && IsPlayerInDynamicArea( i, g_gangTurfData[ z ] [ E_AREA ] ) && Turf_IsAbleToTakeover( i ) ) {
		count++;
	}
	return count;
}

stock Turf_IsAbleToTakeover( i ) {
	new
		Float: Z;

	GetPlayerPos( i, Z, Z, Z );
	return p_Class[ i ] == CLASS_CIVILIAN && ! p_AntiSpawnKillEnabled{ i } && ! IsPlayerPassive( i ) && GetPlayerState( i ) != PLAYER_STATE_SPECTATING && ! IsPlayerAFK( i ) && Z <= 250.0;
}

stock Turf_RedrawPlayerGangZones( playerid )
{
	foreach ( new x : turfs )
    {
    	if ( g_gangHardpointTurf == g_gangTurfData[ x ] [ E_ID ] ) {
    		if ( g_gangHardpointAttacker != INVALID_GANG_ID ) {
	    		GangZoneStopFlashForPlayer( playerid, g_gangTurfData[ x ] [ E_ID ] );
	    		GangZoneFlashForPlayer( playerid, g_gangTurfData[ x ] [ E_ID ], setAlpha( g_gangData[ g_gangHardpointAttacker ] [ E_COLOR ], 0x80 ) );
    		} else {
		        GangZoneHideForPlayer( playerid, g_gangTurfData[ x ] [ E_ID ] );
		        GangZoneShowForPlayer( playerid, g_gangTurfData[ x ] [ E_ID ], g_gangHardpointTurf == g_gangTurfData[ x ] [ E_ID ] ? COLOR_HARDPOINT : g_gangTurfData[ x ] [ E_COLOR ] );
    		}
    	} else {
	        GangZoneHideForPlayer( playerid, g_gangTurfData[ x ] [ E_ID ] );
	        GangZoneShowForPlayer( playerid, g_gangTurfData[ x ] [ E_ID ], g_gangTurfData[ x ] [ E_COLOR ] );
    	}
    }
    return 1;
}

stock Turf_RedrawGangZonesForAll( )
{
	foreach ( new x : turfs )
    {
    	if ( g_gangHardpointTurf == g_gangTurfData[ x ] [ E_ID ] ) {
    		if ( g_gangHardpointAttacker != INVALID_GANG_ID ) {
	    		GangZoneStopFlashForAll( g_gangTurfData[ x ] [ E_ID ] );
	    		GangZoneFlashForAll( g_gangTurfData[ x ] [ E_ID ], setAlpha( g_gangData[ g_gangHardpointAttacker ] [ E_COLOR ], 0x80 ) );
    		} else {
		        GangZoneHideForAll( g_gangTurfData[ x ] [ E_ID ] );
		        GangZoneShowForAll( g_gangTurfData[ x ] [ E_ID ], g_gangHardpointTurf == g_gangTurfData[ x ] [ E_ID ] ? COLOR_HARDPOINT : g_gangTurfData[ x ] [ E_COLOR ] );
    		}
    	} else {
	        GangZoneHideForAll( g_gangTurfData[ x ] [ E_ID ] );
	        GangZoneShowForAll( g_gangTurfData[ x ] [ E_ID ], g_gangTurfData[ x ] [ E_COLOR ] );
    	}
    }
    return 1;
}

stock Turf_GetTotalCaptureSeconds( ) {

	new
		accum_seconds = 0;

	for ( new i = 0; i < sizeof ( g_gangHardpointCaptureTime ); i ++ ) {
		accum_seconds += g_gangHardpointCaptureTime[ i ];
	}
	return accum_seconds;
}
