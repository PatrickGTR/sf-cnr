/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define	MAX_FACILITIES 				( 16 )

enum E_GANG_FACILITIES
{
	E_GANG_SQL_ID,					E_TURF_ID,

	Text3D: E_LABEL[ 2 ],			E_CHECKPOINT[ 2 ],

	Float: E_X, 					Float: E_Y, 			Float: E_Z
};

/* ** Variables ** */
new
	g_gangFacilities 				[ MAX_FACILITIES ] [ E_GANG_FACILITIES ],
	// g_gangsWithFacilities 			[ MAX_FACILITIES ],
	Iterator: gangfacilities 		< MAX_FACILITIES >
;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	// preload gang and facility
	mysql_function_query( dbHandle, "SELECT `GANG_FACILITIES`.`ID` as `FACILITY_ID`, `GANGS`.*, `GANG_FACILITIES`.* FROM `GANGS` JOIN `GANG_FACILITIES` ON `GANGS`.`ID` = `GANG_FACILITIES`.`GANG_ID`", true, "OnGangFaciltiesLoad", "d", INVALID_PLAYER_ID );
	return 1;
}

/* ** Threads ** */
thread OnGangFaciltiesLoad( )
{
	new rows;
	cache_get_data( rows, tmpVariable );

	if ( rows )
	{
		new gang_name[ 30 ], join_msg[ 96 ];

		for ( new row = 0; row < rows; row ++ )
		{
			// new facility_sql_id = cache_get_field_content_int( row, "FACILITY_ID", dbHandle );
			new gang_sql_id = cache_get_field_content_int( row, "GANG_ID", dbHandle );
			new gangid = ITER_NONE;

			// reset name and join message appropriately
			cache_get_field_content( row, "NAME", gang_name, dbHandle, sizeof( gang_name ) );
			cache_get_field_content( row, "JOIN_MSG", join_msg, dbHandle, sizeof( join_msg ) );

			printf( "Gang: %s, Join msg: %s", gang_name, join_msg );

			// check for existing gang
			foreach ( new g : gangs ) if ( g_gangData[ g ] [ E_SQL_ID ] == gang_sql_id ) {
				gangid = g;
				break;
			}

			// create gang if not exists
			if ( gangid == ITER_NONE )
			{
				gangid = CreateGang( gang_name,
					cache_get_field_content_int( row, "LEADER", dbHandle ),
					cache_get_field_content_int( row, "COLOR", dbHandle ),
					cache_get_field_content_int( row, "KILLS", dbHandle ),
					cache_get_field_content_int( row, "DEATHS", dbHandle ),
					cache_get_field_content_int( row, "BANK", dbHandle ),
					cache_get_field_content_int( row, "SCORE", dbHandle ),
					cache_get_field_content_int( row, "RESPECT", dbHandle ),
					!! cache_get_field_content_int( row, "INVITE_ONLY", dbHandle ),
					join_msg, true, gang_sql_id
				);
			}

			// process gang creation
			if ( gangid != ITER_NONE )
			{
				// create facility
				new id = Iter_Free( gangfacilities );

				if ( id != ITER_NONE )
				{
					g_gangFacilities[ id ] [ E_GANG_SQL_ID ] = cache_get_field_content_int( row, "GANG_ID", dbHandle );

					// create turf
					new turf_id = Turf_Create(
						cache_get_field_content_float( row, "ZONE_MIN_X", dbHandle ),
						cache_get_field_content_float( row, "ZONE_MIN_Y", dbHandle ),
						cache_get_field_content_float( row, "ZONE_MAX_X", dbHandle ),
						cache_get_field_content_float( row, "ZONE_MAX_Y", dbHandle ),
						gangid, setAlpha( g_gangData[ gangid ] [ E_COLOR ], 0x90 ), gangid
					);

					// error check
					if ( turf_id == ITER_NONE ) printf("[GANG FACILITIES] [*CRITICAL ERROR*] Not enough turfs are available to create for facility %d.", g_gangFacilities[ id ] [ E_GANG_SQL_ID ] );

					// add to iterator
					Iter_Add( gangfacilities, id );

					// set variables
					g_gangFacilities[ id ] [ E_GANG_SQL_ID ] = gang_sql_id;
					g_gangFacilities[ id ] [ E_TURF_ID ] = turf_id;

					g_gangFacilities[ id ] [ E_X ] = cache_get_field_content_float( row, "ENTER_X", dbHandle );
					g_gangFacilities[ id ] [ E_Y ] = cache_get_field_content_float( row, "ENTER_Y", dbHandle );
					g_gangFacilities[ id ] [ E_Z ] = cache_get_field_content_float( row, "ENTER_Z", dbHandle );

					g_gangFacilities[ id ] [ E_CHECKPOINT ] [ 0 ] = CreateDynamicCP( g_gangFacilities[ id ] [ E_X ], g_gangFacilities[ id ] [ E_Y ], g_gangFacilities[ id ] [ E_Z ], 1.0, -1, 0, -1, 100.0 );

			        format( szNormalString, sizeof( szNormalString ), "Gang Facility\n"COL_WHITE" %s", gang_name );
			        g_gangFacilities[ id ] [ E_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( szNormalString, g_gangData[ gangid ] [ E_COLOR ], g_gangFacilities[ id ] [ E_X ], g_gangFacilities[ id ] [ E_Y ], g_gangFacilities[ id ] [ E_Z ], 20.0 );
				}
				else
				{
					printf("[GANG FACILITIES] [ERROR] No more slows available to insert more facilities (%d)!", MAX_FACILITIES );
					break;
				}
			}
		}
	}
	return 1;
}

/* ** Functions ** */
stock SetPlayerToGangFacility( playerid, handle )
{
	// preload interior
	pauseToLoad( playerid );
	UpdatePlayerEntranceExitTick( playerid );

	// set player position
	SetPlayerPos( playerid, g_gangFacilities[ handle ] [ E_X ], g_gangFacilities[ handle ] [ E_Y ], g_gangFacilities[ handle ] [ E_Z ] );
	SetPlayerVirtualWorld( playerid, 0 );
	SetPlayerInterior( playerid, 0 );
}
/*
new gz_gangzoneid = 0;
new gz_state = 0;
new Float: gz_minx;
new Float: gz_miny;
new Float: gz_maxx;
new Float: gz_maxy;

CMD:switch( playerid, params[ ] ) {
	gz_state = strval( params );

	if ( gz_state == 2 ) printf("%f, %f, %f, %f\n", gz_minx, gz_miny, gz_maxx, gz_maxy);
	return 1;
}

hook OnPlayerUpdate( playerid )
{
	static Float: X, Float: Y, Float: Z;

	if ( gz_state != 2 )
	{
		GetPlayerPos( playerid, X, Y, Z );

		if ( gz_state == 0 ) gz_minx = X, gz_miny = Y;
		else if ( gz_state == 1 ) gz_maxx = X, gz_maxy = Y;

		GangZoneDestroy( gz_gangzoneid );
		gz_gangzoneid = GangZoneCreate( gz_minx, gz_miny, gz_maxx, gz_maxy );
		GangZoneShowForPlayer( playerid, gz_gangzoneid, COLOR_RED );
	}
	return 1;
}*/

/* ** SCHEMA ** */
/*
	CREATE TABLE IF NOT EXISTS GANG_FACILITIES (
		ID int(11) AUTO_INCREMENT primary key,
		GANG_ID int(11),
		ENTER_X float,
		ENTER_Y float,
		ENTER_Z float,
		ZONE_MIN_X float,
		ZONE_MIN_Y float,
		ZONE_MAX_X float,
		ZONE_MAX_Y float
	);

	TRUNCATE TABLE GANG_FACILITIES;
	INSERT INTO GANG_FACILITIES (GANG_ID, ENTER_X, ENTER_Y, ENTER_Z, ZONE_MIN_X, ZONE_MIN_Y, ZONE_MAX_X, ZONE_MAX_Y) VALUES
	(14, -2056.4568,453.9176,35.1719, -2068, 446.5, -2009, 501.5),
	(6977, -1697.5094,883.6597,24.8982, -1723, 857.5, -1642, 911.5),
	(3885, -1606.2400,773.2818,7.1875, -1642, 755.5, -1563, 829.5),
	(4011, -1715.8917,1018.1326,17.9178,-1803, 964.5, -1722, 1037.5),
	(4011, -2754.3115, 90.5159, 7.0313, -2763, 78.5, -2710, 154.5),
	(7138, -2588.1001,59.9101,4.3544,-2613, 49.5, -2532, 79.5);

	CREATE TABLE IF NOT EXISTS GANG_FACILITIES_VEHICLES (
		`ID` int(11) primary key auto_increment,
		`GANG_ID` int(11),
		`MODEL` int(3),
		`PRICE` int(11),
		`COLOR1` int(3),
		`COLOR2` int(3),
		`PAINTJOB` tinyjob(1)
		`MODS` varchar(96)
	);
 */
