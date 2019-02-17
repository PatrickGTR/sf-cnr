/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\gps.pwn
 * Purpose: basic GPS navigation system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_GPS_WAYPOINTS			( 81 )

/* ** Variables ** */
enum E_GPS_DATA
{
	E_NAME[ 24 ],   	E_HELPER[ 72 ],		E_CITY,
	E_FREQUENCY,

	Float: E_Y,         Float: E_Z, 		Float: E_X,

	E_ID // used for sorting algo
};

static stock
	g_gpsData						[ MAX_GPS_WAYPOINTS ] [ E_GPS_DATA ],
	g_sortedGpsData 				[ MAX_GPS_WAYPOINTS ] [ E_GPS_DATA ], // store sorted information here
	Iterator: gpswaypoint 			< MAX_GPS_WAYPOINTS >,
	bool: p_GPSToggled            	[ MAX_PLAYERS char ],
	p_GPSTimer                      [ MAX_PLAYERS ] = { -1, ... },
	p_GPSObject                   	[ MAX_PLAYERS ] = { INVALID_OBJECT_ID, ... },
	p_GPSDestName 					[ MAX_PLAYERS ] [ 24 ],
	g_GpsLastSorted					= -1
;

/* ** Hooks ** */
hook OnScriptInit( playerid )
{
	// reset gps ids by default
	for ( new gpsid = 0; gpsid < sizeof( g_gpsData ); gpsid ++ ) {
		g_gpsData[ gpsid ] [ E_ID ] = ITER_NONE;
	}

	// create gps routes
	CreateNavigation( "Misty's Bar", 			-2242.1438, -88.0866, 35.3203, CITY_SF, "Pool Minigame" );
	CreateNavigation( "Paintball", 				-2172.2017, 252.1113, 35.3388, CITY_SF, "Deathmatching lobbies" );
	CreateNavigation( "Shipyard", 				-1547.4066, 123.6555, 3.55472, CITY_SF, "Exporting vehicles" );
	CreateNavigation( "Bombshop", 				-1923.3926, 303.6380, 41.0469, CITY_SF, "Buy C4" );
	CreateNavigation( "Bank", 					-1496.8027, 919.8218, 7.18752, CITY_SF, "Manage your money" );
	CreateNavigation( "Police Station", 		-1609.2813, 712.9857, 13.7334, CITY_SF, "Blow up jail cells" );
	CreateNavigation( "City Hall", 				-2766.4087, 375.5447, 6.33470, CITY_SF, "Change your job/city" );
	CreateNavigation( "Supa Save", 				-2446.3350, 752.2393, 35.1719, CITY_SF, "Buy items and materials" );
	CreateNavigation( "Vehicle Dealership", 	-2521.1895, -624.942, 132.780, CITY_SF, "Buy personal vehicles" );
	CreateNavigation( "Trucking", 				-2127.8599, -228.7343, 35.323, CITY_SF, "Trucking minijob" );
	CreateNavigation( "Airport",                -1422.4063, -286.5081, 14.148, CITY_SF, "Fast-travel between cities" );
	CreateNavigation( "V.I.P Lounge",           -1880.7598, 822.3964, 35.1778, CITY_SF, ""COL_GOLD"V.I.P weapon locker" );
	CreateNavigation( "Lumberjack",          	-2323.5676, -97.25822, 35.307, CITY_SF, "Lumberjack minijob" );
	CreateNavigation( "Ammu-Nation",			-2626.6299, 208.2514, 4.81250, CITY_SF, "Buy guns" );
	CreateNavigation( "Pawnshop",				-2490.2256, -16.9206, 25.6172, CITY_SF, "Buy toys/Burglar minivans" );
	CreateNavigation( "Hospital", 				-2658.3201, 639.5060, 14.4531, CITY_SF, "Buy cure/healing" );
	CreateNavigation( "Wang Cars", 				-1983.6909, 288.7863, 34.8125, CITY_SF, "Modshop" );
	CreateNavigation( "Train Station", 			-1979.9883, 138.0498, 27.6875, CITY_SF, "Traindriver Minijob" );
	CreateNavigation( "Mining Field", 			-2232.9792, 251.5285, 34.8770, CITY_SF, "Mining Minijob" );
	CreateNavigation( "Duel Arena", 			-2232.9792, 251.5285, 34.8770, CITY_SF, "Waged Duels" );
	CreateNavigation( "Battle Royale Arena",	-2109.6680, -444.147, 38.7344, CITY_SF, "Battle royale minigame" );

	#if ENABLE_CITY_LV == true
	// Las Venturas
	CreateNavigation( "The Visage Casino", 		2017.1334, 1916.4141, 12.3424, CITY_LV, "High limit gambling minigames" );
	CreateNavigation( "4 Dragons Casino",		2025.3047, 1008.4356, 10.3846, CITY_LV, "Medium limit gambling minigames" );
	CreateNavigation( "Caligula's Casino", 		2191.3186, 1677.9497, 11.9736, CITY_LV, "Low limit gambling minigames" );
	CreateNavigation( "Airport", 				1705.3646, 1607.9652, 10.0580, CITY_LV, "Fast-travel between cities" );
	CreateNavigation( "City Hall", 				2414.9258, 1123.4523, 10.8203, CITY_LV, "Change your job/city" );
	CreateNavigation( "Hospital", 				1606.8169, 1837.1116, 10.8203, CITY_LV, "Buy cure/healing" );
	CreateNavigation( "Ammu-Nation", 			2537.8972, 2083.8586, 10.8203, CITY_LV, "Buy guns" );
	CreateNavigation( "Bombshop", 				1998.7263, 2298.5562, 10.8203, CITY_LV, "Buy C4" );
	CreateNavigation( "Bank",					2442.1279, 2376.0293, 11.5376, CITY_LV, "Manage your money" );
	CreateNavigation( "Autobahn", 				1948.6851, 2068.7463, 11.0610, CITY_LV, "Buy personal vehicles" );
	CreateNavigation( "Police Department", 		2288.0063, 2429.8960, 10.8203, CITY_LV, "Blow up jail cells" );
	CreateNavigation( "Shipyard", 				1633.7454, 2330.6860, 10.8203, CITY_LV, "Exporting vehicles" );
	CreateNavigation( "Quarry", 				343.09180, 877.98650, 20.4063, CITY_LV, "Mining minijob" );
	CreateNavigation( "V.I.P Lounge", 			1966.8428, 1623.2175, 12.8621, CITY_LV, ""COL_GOLD"V.I.P weapon locker" );
	CreateNavigation( "Pawnshop",				2482.4395, 1326.4077, 10.8203, CITY_LV, "Buy toys" );
	CreateNavigation( "Fort Carson", 			-135.5214, 1148.3502, 19.5938, CITY_LV, "" );
	CreateNavigation( "Las Payasadas", 			-233.0320, 2700.0896, 62.5391, CITY_LV, "" );
	CreateNavigation( "El Quebrados", 			-1491.172, 2603.0425, 55.6897, CITY_LV, "" );
	CreateNavigation( "Las Barrancas",          -805.4283, 1539.6168, 26.9609, CITY_LV, "" );
	#endif

	#if ENABLE_CITY_LS == true
	// Los Santos
	CreateNavigation( "Vehicle Dealership", 	540.27090, -1282.3586, 17.2422, CITY_LS, "Buy personal vehicles" );
	CreateNavigation( "Bank", 					593.73800, -1244.3899, 18.0622, CITY_LS, "Manage your money" );
	CreateNavigation( "Airport", 				1961.4990, -2193.5586, 13.5469, CITY_LS, "Fast-travel between cities" );
	CreateNavigation( "City Hall", 				1480.1451, -1737.7921, 13.5469, CITY_LS, "Change your job/city" );
	CreateNavigation( "Police Station", 		1539.8739, -1675.8989, 13.5469, CITY_LS, "Blow up jail cells" );
	CreateNavigation( "Ammu-Nation", 			1362.1816, -1282.4746, 13.5469, CITY_LS, "Buy guns" );
	CreateNavigation( "Ammu-Nation", 			2400.6345, -1975.4139, 13.3828, CITY_LS, "Buy guns"	);
	CreateNavigation( "V.I.P Lounge", 			1805.5667, -1582.5602, 13.4951, CITY_LS, ""COL_GOLD"V.I.P weapon locker" );
	CreateNavigation( "Bombshop", 				1911.2462, -1775.8755, 13.3828, CITY_LS, "Buy C4" );
	CreateNavigation( "Trainstation", 			1750.6547, -1945.8823, 13.5613, CITY_LS, "Traindriver Minijob" );
	CreateNavigation( "Shipyard", 				2615.8606, -2226.5325, 13.3828, CITY_LS, "Exporting vehicles" );
	CreateNavigation( "Pawnshop",				2507.3076, -1724.6044, 13.5469, CITY_LS, "Buy toys" );
	CreateNavigation( "Modshop", 				1041.0688, -1027.9791, 32.1016, CITY_LS, "" );
	CreateNavigation( "Lowrider Modshop", 		2645.3145, -2033.6381, 13.5540, CITY_LS, "" );
	CreateNavigation( "Grove Street", 			2487.0481, -1668.7418, 13.3438, CITY_LS, "" );
	CreateNavigation( "Angel Pine", 			-2143.302, -2395.7650, 30.6250, CITY_LS, "" );
	CreateNavigation( "Blueberry", 				234.78340, -128.77670, 1.42970, CITY_LS, "" );
	CreateNavigation( "Dillimore", 				680.57570, -539.80190, 16.1803, CITY_LS, "" );
	CreateNavigation( "Montgomery", 			1317.5898, 313.541300, 19.4063, CITY_LS, "" );
	CreateNavigation( "Palomino Creek", 		2335.9343, 31.8564000, 26.4819, CITY_LS, "" );
	#endif
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_GPS && response )
	{
		if ( p_GPSToggled{ playerid } == true || !IsPlayerInAnyVehicle( playerid ) )
		    return SendError( playerid, "An error has occurred." ), 0;

		new
			x = 0;

	    for( new i = 0; i < sizeof( g_sortedGpsData ); i ++ ) if ( Iter_Contains( gpswaypoint, g_sortedGpsData[ i ] [ E_ID ] ) )
		{
	        if ( g_sortedGpsData[ i ] [ E_CITY ] == GetPVarInt( playerid, "gps_city" ) )
			{
		       	if ( x == listitem )
		      	{
		      		new
		      			gpsid = g_sortedGpsData[ i ] [ E_ID ];

					g_gpsData[ gpsid ] [ E_FREQUENCY ] ++; // increase frequency
					GPS_SetPlayerWaypoint( playerid, g_gpsData[ gpsid ] [ E_NAME ], g_gpsData[ gpsid ] [ E_X ], g_gpsData[ gpsid ] [ E_Y ], g_gpsData[ gpsid ] [ E_Z ] );
					SendClientMessageFormatted( playerid, -1, ""COL_GREY"[GPS]"COL_WHITE" You have set your destination to %s. Follow the arrow to reach your destination.", g_gpsData[ gpsid ] [ E_NAME ] );
		      		break;
				}
		      	x++;
			}
		}
	}
	else if ( dialogid == DIALOG_GPS_CITY && response )
	{
		if ( p_GPSToggled{ playerid } == true || !IsPlayerInAnyVehicle( playerid ) )
		    return SendError( playerid, "An error has occurred." ), 0;

		new
			server_time = GetServerTime( );

		// store current sort into gangs & sort by respect intelligently
		if ( server_time > g_GpsLastSorted )
		{
			g_sortedGpsData = g_gpsData;
			g_GpsLastSorted = server_time + 10;
			SortDeepArray( g_sortedGpsData, E_FREQUENCY, .order = SORT_DESC );
		}

		// clear out large string for this one
		szLargeString = ""COL_WHITE"Location\t"COL_WHITE"Known For\n";

		// add location and its purpose
	    for ( new i = 0; i < sizeof( g_sortedGpsData ); i ++ ) if ( Iter_Contains( gpswaypoint, g_sortedGpsData[ i ] [ E_ID ] ) && g_sortedGpsData[ i ] [ E_CITY ] == listitem ) {
			format( szLargeString, sizeof( szLargeString ), "%s%s\t{666666}%s\n", szLargeString, g_sortedGpsData[ i ] [ E_NAME ], g_sortedGpsData[ i ] [ E_HELPER ] );
	    }

	    SetPVarInt( playerid, "gps_city", listitem );

	    ShowPlayerDialog( playerid, DIALOG_GPS, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}GPS - Navigator", szLargeString, "Select", "Cancel");
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	GPS_StopNavigation( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	GPS_StopNavigation( playerid );
	return 1;
}

/* ** Commands ** */
CMD:gps( playerid, params[ ] )
{
	if ( p_GPSToggled{ playerid } )
	{
		GPS_StopNavigation( playerid );
		return SendServerMessage( playerid, "You have de-activated your GPS." ), 1;
	}
	else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You have to be a driver of a vehicle to use this a command." );
	else if ( GetPlayerInterior( playerid ) != 0 ) return SendError( playerid, "You must be outside of the interior." );
    else if ( ! strcmp( params, "atm", false, 3 ) )
	{
        new Float: oX, Float: oY, Float: oZ;
        new atmID = GetClosestATM( playerid );
        GetATMPos( atmID, oX, oY, oZ );
        GPS_SetPlayerWaypoint( playerid, "Closest ATM", oX, oY, oZ );
		SendClientMessage( playerid, -1, ""COL_GREY"[GPS]"COL_WHITE" You have set your destination to closest atm." );
    }
    else if ( ! strcmp( params, "vehicle", false, 7 ) )
	{
        new vehName[ 24 ];

        if ( sscanf( params[ 8 ], "s[24]", vehName ) ) return SendUsage( playerid, "/gps vehicle [NAME]" );

        new Float: vXp, Float: vYp, Float: vZp, vehID = GetVehicleModelFromName( vehName );

		if ( vehID == -1 ) return SendError( playerid, "Invalid vehicle name." );

        GetVehiclePos( GetClosestVehicleModel( playerid, vehID ), vXp, vYp, vZp );

		SendClientMessageFormatted( playerid, -1, ""COL_GREY"[GPS]"COL_WHITE" You have set your destination to closest %s.", GetVehicleName( vehID ) );

        GPS_SetPlayerWaypoint( playerid, sprintf( "Closest %s", GetVehicleName( vehID ) ), vXp, vYp, vZp );
    }
	else
	{
        ShowPlayerDialog( playerid, DIALOG_GPS_CITY, DIALOG_STYLE_LIST, "{FFFFFF}GPS - Choose City", "San Fierro\nLas Venturas\nLos Santos", "Select", "Cancel" );
		SendClientMessage( playerid, -1, ""COL_GREY"[TIP]"COL_WHITE" You can locate a vehicle model or ATM using "COL_GREY"/gps [VEHICLE/ATM]"COL_WHITE"." );
	}
	return 1;
}

/* ** Functions ** */
stock CreateNavigation( const name[ 24 ], Float: X, Float: Y, Float: Z, city, const helper[ 72 ] )
{
	new
		gpsid = Iter_Free( gpswaypoint );

	if ( gpsid != ITER_NONE )
	{
		Iter_Add( gpswaypoint, gpsid );
		format( g_gpsData[ gpsid ] [ E_NAME ], 24, "%s", name );
		format( g_gpsData[ gpsid ] [ E_HELPER ], 72, "%s", helper );
	    g_gpsData[ gpsid ] [ E_X ] = X;
	    g_gpsData[ gpsid ] [ E_Y ] = Y;
	    g_gpsData[ gpsid ] [ E_Z ] = Z;
	    g_gpsData[ gpsid ] [ E_CITY ] = city;
	    g_gpsData[ gpsid ] [ E_ID ] = gpsid;
	}
    return 1;
}

stock GPS_StopNavigation( playerid )
{
	p_GPSToggled{ playerid } = false;
	DestroyDynamicObject( p_GPSObject[ playerid ] );
	KillTimer( p_GPSTimer[ playerid ] );
	p_GPSTimer[ playerid ] = -1;
  	p_GPSObject[ playerid ] = INVALID_OBJECT_ID;
	PlayerTextDrawHide( playerid, p_GPSInformation[ playerid ] );
}

stock GPS_SetPlayerWaypoint( playerid, const destName[ ], Float: destX, Float: destY, Float: destZ )
{
	p_GPSToggled{ playerid } = true;
	format( p_GPSDestName[ playerid ], sizeof( p_GPSDestName[ ] ), "%s", destName );

	DestroyDynamicObject( p_GPSObject[ playerid ] );
	p_GPSObject[ playerid ] = CreateDynamicObject( 1318, 0.0, 0.0, 0.0, 0.0, 0.0, 0 );

	KillTimer( p_GPSTimer[ playerid ] );
	p_GPSTimer[ playerid ] = SetTimerEx( "GPS_Update", 100, true, "dfff", playerid, destX, destY, destZ );

	PlayerTextDrawShow( playerid, p_GPSInformation[ playerid ] );
}

function GPS_Update( playerid, Float: destX, Float: destY, Float: destZ )
{
	static Float: fRY, Float: fRZ, Float: fAZ;
	static Float: X, Float: Y, Float: Z;

	if ( ! IsPlayerInAnyVehicle( playerid ) )
	{
		GPS_StopNavigation( playerid );
	  	SendServerMessage( playerid, "You have de-activated your GPS." );
	  	return 1;
	}

	new
		Float: distance = GetPlayerDistanceFromPoint( playerid, destX, destY, destZ );

	if ( distance < 10.0 )
	{
    	GPS_StopNavigation( playerid );
	  	return SendServerMessage( playerid, "You have reached your destination." );
	}

	new
		vehicleid = GetPlayerVehicleID( playerid );

	GetVehiclePos( vehicleid, X, Y, Z );
	GetVehicleZAngle( vehicleid, fAZ );

	fRY = floatsqroot( floatpower( ( destX - X ), 2.0 ) + floatpower( ( destY - Y ), 2.0 ) );
	fRY = floatabs( atan2( fRY, Z - destZ ) );
	fRZ = atan2( destY - Y, destX - X ) + 180.0;

    AttachDynamicObjectToVehicle( p_GPSObject[ playerid ], vehicleid, 0.0, 0.0, 1.5, 0.0, fRY, fRZ - fAZ );
	PlayerTextDrawSetString( playerid, p_GPSInformation[ playerid ], sprintf( "~g~Location:~w~ %s~n~~g~Distance:~w~ %0.2fm", p_GPSDestName[ playerid ], distance ) );
	return 1;
}

stock GetClosestVehicleModel( playerid, id ){
    new closest = -1, Float: closestDist = 8000.00, Float: distance, Float: pX, Float: pY, Float: pZ;
	GetPlayerPos( playerid, pX, pY, pZ );
    for ( new i = 0; i < MAX_VEHICLES; i++ ) {
		if ( GetVehicleModel( i ) == id ) {
            distance = GetVehicleDistanceFromPoint( i, pX, pY, pZ );
            if ( closestDist > distance ){
                closestDist = distance;
                closest = i;
            }
		}
    }
    return closest;
}