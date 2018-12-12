/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: facilities.inc
 * Purpose: gang facilities module
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define FACILITY_TAKEOVER_ENABLED 	( false )

#define	MAX_FACILITIES 				( 32 )
#define MAX_FACILITY_BOMB 			( 2 )

#define FACILITY_SPAWN_FEE			( 2000 )

#define FACILITY_AMMU_RESPECT 		( 75000.0 )
#define FACILITY_BLOWUP_TIME 		( 10 )

// #define DIALOG_GANG_JOIN 			( 9238 )
// #define DIALOG_FACILITY_AMMU 		( 9239 )
// #define DIALOG_FACILITY_AMMU_BUY 	( 9299 )

/* ** Macros ** */
#define Facility_IsValid(%0) \
	(0 <= %0 < MAX_FACILITIES && Iter_Contains(gangfacilities, %0))

/* ** Variables ** */
enum E_GANG_FACILITIES
{
	E_GANG_SQL_ID,					E_TURF_ID,						E_INTERIOR_TYPE,
	E_WORLD,

	Text3D: E_LABEL[ 2 ],			E_CHECKPOINT[ 2 ],

	Float: E_X, 					Float: E_Y, 					Float: E_Z,

	E_AMMU_CP,						E_SHOP_CP,						E_CANNON_CP,
	E_TRAVEL_CP,					E_MECHANIC_CP,

	bool: E_WAR,					E_WAR_TIMER,					E_WAR_TICK,

	E_BOMB_OBJECT[ 2 ],				E_BLOWUP_COUNT[ 2 ],
	bool: E_BLOWN[ 2 ]
};

enum E_FACILITY_INTERIOR
{
	Float: E_POS[ 3 ],
	Float: E_CANNON_POS[ 3 ],
	Float: E_AMMU_POS[ 4 ],
	Float: E_SHOP_POS[ 4 ],
	Float: E_TRAVEL_POS[ 4 ],
	Float: E_ATM_POS[ 4 ],
	Float: E_BOMB_POS_1[ 4 ],
	Float: E_BOMB_POS_2[ 4 ],
	Float: E_MECHANIC_POS[ 4 ]
};

new
	g_gangFacilityInterior 			[ ] [ E_FACILITY_INTERIOR ] =
	{
		// default interior
		{
			{ 238.9165, 1872.3391, 1861.4607 },
			{ 212.4133, 1822.7343, 1856.4138 },
			{ 248.5042, 1797.5060, 1857.4143, 0.000000 },
			{ 259.9110, 1850.9300, 1858.7600, 0.000000 },
			{ 261.0079, 1869.5808, 1858.7600, 90.00000 },
			{ 262.5575, 1850.0053, 1858.3671, 180.0000 },
			{ 246.7225, 1816.1835, 1855.3718, 90.00000 },
			{ 246.7225, 1827.7545, 1855.3718, 90.00000 },
			{ 244.6742, 1843.2554, 1858.7576, 0.000000 }
		}
	},
	g_gangFacilities 				[ MAX_FACILITIES ] [ E_GANG_FACILITIES ],
	// g_gangsWithFacilities 		[ MAX_FACILITIES ],
	Iterator: gangfacilities 		< MAX_FACILITIES >
;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	// preload gang and facility
	mysql_function_query( dbHandle, "SELECT `GANG_FACILITIES`.`ID` as `FACILITY_ID`, `GANGS`.*, `GANG_FACILITIES`.* FROM `GANGS` JOIN `GANG_FACILITIES` ON `GANGS`.`ID` = `GANG_FACILITIES`.`GANG_ID`", true, "OnGangFaciltiesLoad", "d", INVALID_PLAYER_ID );

	// initialize facility objects
	initializeFacilityObjects( );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( CanPlayerExitEntrance( playerid ) )
	{
		new
			gangid = GetPlayerGang( playerid );

		foreach ( new facility : gangfacilities )
		{
			// entrance
			if ( checkpointid == g_gangFacilities[ facility ] [ E_CHECKPOINT ] [ 0 ] )
			{
				new turfid = g_gangFacilities[ facility ] [ E_TURF_ID ];
				new facility_gangid = Turf_GetFacility( turfid );

				// not in the gang / not a turf owner
				if ( ! ( Turf_GetOwner( turfid ) == gangid || facility_gangid == gangid ) )
				{
					if ( ! IsGangPrivate( facility_gangid ) && gangid == INVALID_GANG_ID )
					{
						SetPVarInt( playerid, "gang_facility_join", facility_gangid ); // store gang id
						return ShowPlayerDialog(
							playerid, DIALOG_GANG_JOIN, DIALOG_STYLE_MSGBOX,
							sprintf( "{%06x}%s", g_gangData[ facility_gangid ] [ E_COLOR ] >>> 8, g_gangData[ facility_gangid ] [ E_NAME ] ),
							""COL_WHITE"This gang is a public gang, would you like to join it?",
							"Yes", "No"
						);
					}
					else
					{
						return SendError( playerid, "You are not in the gang of this facility. Capture it to enter." );
					}
				}

				new
					int_type = g_gangFacilities[ facility ] [ E_INTERIOR_TYPE ];

				// begin entrance
	        	pauseToLoad( playerid );
	        	SetPVarInt( playerid, "in_facility", facility );
	        	PlayerPlaySound( playerid, 1, 0.0, 0.0, 0.0 );
			    UpdatePlayerEntranceExitTick( playerid );
				SetPlayerPos( playerid, g_gangFacilityInterior[ int_type ] [ E_POS ] [ 0 ], g_gangFacilityInterior[ int_type ] [ E_POS ] [ 1 ], g_gangFacilityInterior[ int_type ] [ E_POS ] [ 2 ] );
			  	SetPlayerVirtualWorld( playerid, g_gangFacilities[ facility ] [ E_WORLD ] );
				SetPlayerInterior( playerid, 0 );
				break;
			}

			// exit
			else if ( checkpointid == g_gangFacilities[ facility ] [ E_CHECKPOINT ] [ 1 ] )
			{
	        	PlayerPlaySound( playerid, 0, 0.0, 0.0, 0.0 );
				TogglePlayerControllable( playerid, 0 );
			    UpdatePlayerEntranceExitTick( playerid );
				SetTimerEx( "ope_Unfreeze", 1250, false, "d", playerid );
				SetPlayerPosEx( playerid, g_gangFacilities[ facility ] [ E_X ], g_gangFacilities[ facility ] [ E_Y ], g_gangFacilities[ facility ] [ E_Z ], 0 );
				SetPlayerVirtualWorld( playerid, 0 );
				break;
			}

			// ammunation
			else if ( checkpointid == g_gangFacilities[ facility ] [ E_AMMU_CP ] )
			{
				return ShowAmmunationMenu( playerid, "{FFFFFF}Gang Facility - Purchase Weapons", DIALOG_FACILITY_AMMU );
			}

			// shop
			else if ( checkpointid == g_gangFacilities[ facility ] [ E_SHOP_CP ] )
			{
				return ShowPlayerShopMenu( playerid );
			}

			// fast travel
			else if ( checkpointid == g_gangFacilities[ facility ] [ E_TRAVEL_CP ] )
			{
				if ( GetPlayerWantedLevel( playerid ) )
					return SendError( playerid, "You cannot travel while you are wanted." );

				return ShowPlayerAirportMenu( playerid );
			}

			// mechanic
			else if ( checkpointid == g_gangFacilities[ facility ] [ E_MECHANIC_CP ] )
			{
				return ShowPlayerGangVehicleMenu( playerid, facility );
			}

			// orbital cannon
			else if ( checkpointid == g_gangFacilities[ facility ] [ E_CANNON_CP ] )
			{
				if ( GetPlayerCash( playerid ) < 250000 )
					return SendError( playerid, "You need at least $250,000 available to begin operating the orbital cannon." );

				if ( GetPlayerClass( playerid ) != CLASS_CIVILIAN )
					return SendError( playerid, "You must be a civilian to use this feature." );

				if ( StartPlayerOrbitalCannon( playerid, facility ) )
				{
					return SendServerMessage( playerid, "You are now operating this facility's orbital cannon." );
				}
				else
				{
					return SendError( playerid, "The orbital cannon of this facility is currently in use." );
				}
			}
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_GANG_JOIN && response )
	{
		if ( p_GangID[ playerid ] != -1 ) {
			return SendServerMessage( playerid, "You are already in a gang." );
		}

		new
			joining_gang = GetPVarInt( playerid, "gang_facility_join" );

		if ( IsGangPrivate( joining_gang ) ) {
			return SendError( playerid, "You can no longer join this gang as it is private." );
		}

		if ( ! SetPlayerGang( playerid, joining_gang ) ) {
			SendError( playerid, "You can no longer join this gang." );
		}
		return 1;
	}

	else if ( dialogid == DIALOG_FACILITY_AMMU && response )
	{
		new player_gang = GetPlayerGang( playerid );

		if ( ! Iter_Contains( gangs, player_gang ) )
			return SendError( playerid, "You are not in any gang." );

		new Float: discount = ( FACILITY_AMMU_RESPECT - float( g_gangData[ player_gang ] [ E_RESPECT ] ) ) / FACILITY_AMMU_RESPECT;

		SetPVarInt( playerid, "facility_weapon_cat", listitem );
      	RedirectAmmunation( playerid, listitem, "{FFFFFF}Gang Facility - Purchase Weapons", DIALOG_FACILITY_AMMU_BUY, discount );
	}

	else if ( dialogid == DIALOG_FACILITY_AMMU_BUY )
	{
		if ( response )
		{
			new facility = GetPVarInt( playerid, "in_facility" );

			if ( ! Iter_Contains( gangfacilities, facility ) )
				return SendError( playerid, "Cannot identify current gang facility. Please enter facility again." );

			new facility_gangid = Turf_GetFacility( g_gangFacilities[ facility ] [ E_TURF_ID ] );

			if ( ! Iter_Contains( gangs, facility_gangid ) ) return SendError( playerid, "You are not in any gang." );
		    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot buy weapons in jail." );
		    if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot buy weapons in an event." );
			if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED || !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You are unable to purchase any weapons at this time." );

			new gun_category = GetPVarInt( playerid, "facility_weapon_cat" );
			new Float: gun_discount = ( FACILITY_AMMU_RESPECT - float( g_gangData[ facility_gangid ] [ E_RESPECT ] ) ) / FACILITY_AMMU_RESPECT;

			// make sure player doesnt get credited money lol
			if ( gun_discount < 0.0 ) {
				gun_discount = 0.0;
			}

		    for( new i, x = 0; i < sizeof( g_AmmunationWeapons ); i++ )
		    {
		        if ( g_AmmunationWeapons[ i ] [ E_MENU ] == gun_category )
		        {
		            if ( x == listitem )
		            {
		                new price = floatround( g_AmmunationWeapons[ i ] [ E_PRICE ] * gun_discount ); // Change the discount here!!

					 	if ( price > GetPlayerCash( playerid ) )
						{
						    SendError( playerid, "You don't have enough money for this." );
      						RedirectAmmunation( playerid, gun_category, "{FFFFFF}Gang Facility - Purchase Weapons", DIALOG_FACILITY_AMMU_BUY, gun_discount );
							return 1;
						}

						GivePlayerCash( playerid, -price );
						StockMarket_UpdateEarnings( E_STOCK_AMMUNATION, price, .factor = 0.25 );

						if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 101 ) SetPlayerArmour( playerid, float( g_AmmunationWeapons[ i ] [ E_AMMO ] ) );
						else if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 102 ) {
							p_ExplosiveBullets[ playerid ] += g_AmmunationWeapons[ i ] [ E_AMMO ];
							ShowPlayerHelpDialog( playerid, 3000, "Press ~r~~k~~CONVERSATION_NO~~w~ to activate explosive bullets." );
						}
						else GivePlayerWeapon( playerid, g_AmmunationWeapons[ i ] [ E_WEPID ], g_AmmunationWeapons[ i ] [ E_AMMO ] );

      					RedirectAmmunation( playerid, gun_category, "{FFFFFF}Gang Facility - Purchase Weapons", DIALOG_FACILITY_AMMU_BUY, gun_discount );
						SendServerMessage( playerid, "You have purchased %s(%d) for "COL_GOLD"%s"COL_WHITE"%s.", g_AmmunationWeapons[ i ] [ E_NAME ], g_AmmunationWeapons[ i ] [ E_AMMO ], price > 0.0 ? cash_format( price ) : ( "FREE" ) );
						break;
		            }
		            x ++;
		        }
		    }
		}
		else return ShowAmmunationMenu( playerid, "{FFFFFF}Gang Facility - Purchase Weapons", DIALOG_FACILITY_AMMU );
	}

	else if ( dialogid == DIALOG_FACILITY_SPAWN )
	{
		if ( ! response )
			return ShowPlayerSpawnMenu( playerid );

		new gangid = p_GangID[ playerid ];

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "You are not in any gang." ), ShowPlayerSpawnMenu( playerid );

		static city[ MAX_ZONE_NAME ], location[ MAX_ZONE_NAME ];

		szLargeString = ""COL_WHITE"City\t"COL_WHITE"Location\n";

		new x = 0;

		foreach ( new handle : gangfacilities ) if ( g_gangData[ gangid ] [ E_SQL_ID ] == g_gangFacilities[ handle ] [ E_GANG_SQL_ID ] )
		{
			if ( x == listitem )
			{
				new
					Float: X, Float: Y;

				Turf_GetCentrePos( g_gangFacilities[ handle ] [ E_TURF_ID ], X, Y );

			    Get2DCity( city, X, Y );
			    GetZoneFromCoordinates( location, X, Y );

        		SetPlayerSpawnLocation( playerid, "GNG", handle );
			 	SendServerMessage( playerid, "Spawning has been set the gang facility located in "COL_GREY"%s, %s"COL_WHITE".", location, city );
			 	break;
			}
			x ++;
		}
		return 1;
	}
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
		new Float: infront_x, Float: infront_y;

		for ( new row = 0; row < rows; row ++ )
		{
			// new facility_sql_id = cache_get_field_content_int( row, "FACILITY_ID", dbHandle );
			new gang_sql_id = cache_get_field_content_int( row, "GANG_ID", dbHandle );
			new gangid = ITER_NONE;

			// reset name and join message appropriately
			cache_get_field_content( row, "NAME", gang_name, dbHandle, sizeof( gang_name ) );
			cache_get_field_content( row, "JOIN_MSG", join_msg, dbHandle, sizeof( join_msg ) );

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

					g_gangFacilities[ id ] [ E_WORLD ] = id + 1;
					g_gangFacilities[ id ] [ E_INTERIOR_TYPE ] = GetFacilityInteriorType( gang_sql_id );
					g_gangFacilities[ id ] [ E_X ] = cache_get_field_content_float( row, "ENTER_X", dbHandle );
					g_gangFacilities[ id ] [ E_Y ] = cache_get_field_content_float( row, "ENTER_Y", dbHandle );
					g_gangFacilities[ id ] [ E_Z ] = cache_get_field_content_float( row, "ENTER_Z", dbHandle );

					g_gangFacilities[ id ] [ E_CHECKPOINT ] [ 0 ] = CreateDynamicCP( g_gangFacilities[ id ] [ E_X ], g_gangFacilities[ id ] [ E_Y ], g_gangFacilities[ id ] [ E_Z ], 1.0, -1, -1, -1, 100.0 );

			        format( szNormalString, sizeof( szNormalString ), "Gang Facility\n"COL_WHITE" %s", gang_name );
			        g_gangFacilities[ id ] [ E_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( szNormalString, g_gangData[ gangid ] [ E_COLOR ], g_gangFacilities[ id ] [ E_X ], g_gangFacilities[ id ] [ E_Y ], g_gangFacilities[ id ] [ E_Z ], 20.0 );

					// create interior
					new type = g_gangFacilities[ id ] [ E_INTERIOR_TYPE ];

					g_gangFacilities[ id ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_gangFacilityInterior[ type ] [ E_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_POS ] [ 2 ], 1.0, g_gangFacilities[ id ] [ E_WORLD ], -1, -1, 100.0 );
					g_gangFacilities[ id ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, g_gangFacilityInterior[ type ] [ E_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_POS ] [ 2 ], 20.0 );

					// ammunation man
					CreateDynamicActor( 179, g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 2 ], g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 3 ], true, 100.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					infront_x = g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 0 ] + 2.0 * floatsin( -g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 3 ], degrees );
					infront_y = g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 1 ] + 2.0 * floatcos( -g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 3 ], degrees );

					g_gangFacilities[ id ] [ E_AMMU_CP ] = CreateDynamicCP( infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 2 ], 1.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
					CreateDynamic3DTextLabel( "[AMMU-NATION]", COLOR_GOLD, infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					// orbital cannon
					g_gangFacilities[ id ] [ E_CANNON_CP ] = CreateDynamicCP( g_gangFacilityInterior[ type ] [ E_CANNON_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_CANNON_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_CANNON_POS ] [ 2 ], 1.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
					CreateDynamic3DTextLabel( "[ORBITAL CANNON]", COLOR_GOLD, g_gangFacilityInterior[ type ] [ E_CANNON_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_CANNON_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_CANNON_POS ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					// shop actor
					CreateDynamicActor( 211, g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 2 ], g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 3 ], true, 100.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					infront_x = g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 0 ] + 2.0 * floatsin( -g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 3 ], degrees );
					infront_y = g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 1 ] + 2.0 * floatcos( -g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 3 ], degrees );

					g_gangFacilities[ id ] [ E_SHOP_CP ] = CreateDynamicCP( infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 2 ], 1.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
					CreateDynamic3DTextLabel( "[24/7]", COLOR_GOLD, infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_SHOP_POS ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					// fast travel actor
					CreateDynamicActor( 61, g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 2 ], g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 3 ], true, 100.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					infront_x = g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 0 ] + 2.0 * floatsin( -g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 3 ], degrees );
					infront_y = g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 1 ] + 2.0 * floatcos( -g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 3 ], degrees );

					g_gangFacilities[ id ] [ E_TRAVEL_CP ] = CreateDynamicCP( infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 2 ], 1.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
					CreateDynamic3DTextLabel( "[FAST TRAVEL]", COLOR_GOLD, infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_TRAVEL_POS ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					// mechanic actor
					CreateDynamicActor( 268, g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 2 ], g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 3 ], true, 100.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					infront_x = g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 0 ] + 2.0 * floatsin( -g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 3 ], degrees );
					infront_y = g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 1 ] + 2.0 * floatcos( -g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 3 ], degrees );

					g_gangFacilities[ id ] [ E_MECHANIC_CP ] = CreateDynamicCP( infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 2 ], 1.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
					CreateDynamic3DTextLabel( "[GANG VEHICLES]", COLOR_GOLD, infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_MECHANIC_POS ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					// create atm
					CreateATM( g_gangFacilityInterior[ type ] [ E_ATM_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_ATM_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_ATM_POS ] [ 2 ], g_gangFacilityInterior[ type ] [ E_ATM_POS ] [ 3 ], 0.0, g_gangFacilities[ id ] [ E_WORLD ] );

					// more actors
					ApplyDynamicActorAnimation( CreateDynamicActor( 70, 212.868576, 1819.894531, 1856.413818, 117.200050, true, 100.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] ), "COP_AMBIENT", "Coplook_loop", 4.1, 1, 1, 1, 1, 0 );
					ApplyDynamicActorAnimation( CreateDynamicActor( 70, 213.705627, 1827.192993, 1856.413818, 60.300289, true, 100.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] ), "COP_AMBIENT", "Coplook_think", 4.1, 1, 1, 1, 1, 0 );

				#if FACILITY_TAKEOVER_ENABLED == true
					// labels
					CreateDynamic3DTextLabel( "Server\n"COL_WHITE"Press ALT to Plant C4", COLOR_GREY, g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
					CreateDynamic3DTextLabel( "Server\n"COL_WHITE"Press ALT to Plant C4", COLOR_GREY, g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
				#endif
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
stock SetPlayerToGangFacility( playerid, gangid, facilityid )
{
	if ( g_gangData[ gangid ] [ E_BANK ] < FACILITY_SPAWN_FEE ) {
		return 0;
	}

	// preload interior
	pauseToLoad( playerid );
	UpdatePlayerEntranceExitTick( playerid );

	// set player position
	SetPlayerPos( playerid, g_gangFacilities[ facilityid ] [ E_X ], g_gangFacilities[ facilityid ] [ E_Y ], g_gangFacilities[ facilityid ] [ E_Z ] );
	SetPlayerVirtualWorld( playerid, 0 );
	SetPlayerInterior( playerid, 0 );

	// charge the gang per spawn
	GiveGangCash( gangid, -FACILITY_SPAWN_FEE );
	return 1;
}

stock GetFacilityInteriorType( gang_sql_id )
{
	#pragma unused gang_sql_id
	// todo
	return 0;
}

stock GetGangIDFromFacilityID( facilityid ) {
	foreach ( new f : gangs ) if ( g_gangFacilities[ facilityid ] [ E_GANG_SQL_ID ] == g_gangData[ f ] [ E_SQL_ID ] ) {
		return f;
	}
	return ITER_NONE;
}

stock GetGangFacilityPos( facilityid, &Float: X, &Float: Y, &Float: Z ) {
	X = g_gangFacilities[ facilityid ] [ E_X ];
	Y = g_gangFacilities[ facilityid ] [ E_Y ];
	Z = g_gangFacilities[ facilityid ] [ E_Z ];
}

#if FACILITY_TAKEOVER_ENABLED == true
CMD:plant( playerid, params[ ] ) {
	PlantFacilityC4( playerid, GetPVarInt( playerid, "in_facility" ) );
	return 1;
}

CMD:war( playerid, params[ ] ) {
	StartFacilityWar( GetPVarInt( playerid, "in_facility" ), 0 );
	return 1;
}

#define PROGRESS_FACILITY_PLANT 10
stock PlantFacilityC4( playerid, facility )
{
	new type = g_gangFacilities[ facility ] [ E_INTERIOR_TYPE ];
	new Float: infront_x, Float: infront_y, Float: infront_z;

	if ( IsPlayerInRangeOfPoint( playerid, 2.0, g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 2 ] ) )
	{
		if ( IsValidDynamicObject( g_gangFacilities[ facility ] [ E_BOMB_OBJECT ] [ 0 ] ) )
			return 1;

		infront_x = g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 0 ] + 0.75 * floatsin( g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 3 ], degrees );
		infront_y = g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 1 ] + 0.75 * floatcos( g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 3 ], degrees );
		infront_z = g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 2 ] - 0.5;

		SetPlayerFacingAngle( playerid, g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 3 ] );
		ShowProgressBar( playerid, "Planting C4", PROGRESS_FACILITY_PLANT, 3000, COLOR_RED, 0 );
	}

	else if ( IsPlayerInRangeOfPoint( playerid, 2.0, g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 2 ] ) )
	{
		if ( IsValidDynamicObject( g_gangFacilities[ facility ] [ E_BOMB_OBJECT ] [ 1 ] ) )
			return 1;

		infront_x = g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 0 ] + 0.75 * floatsin( g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 3 ], degrees );
		infront_y = g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 1 ] + 0.75 * floatcos( g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 3 ], degrees );
		infront_z = g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 2 ] - 0.5;

		SetPlayerFacingAngle( playerid, g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 3 ] );
		ShowProgressBar( playerid, "Planting C4", PROGRESS_FACILITY_PLANT, 3000, COLOR_RED, 1 );
	}

	else return 1;

	TogglePlayerControllable( playerid, 0 );
	SetPlayerPos( playerid, infront_x, infront_y, infront_z );

	SetPVarInt( playerid, "planting_facility", facility );
	return 1;
}

hook OnProgressCompleted( playerid, progressid, params )
{
	if ( progressid == PROGRESS_FACILITY_PLANT )
	{
		new facility = GetPVarInt( playerid, "planting_facility" );

		if ( ! Iter_Contains( gangfacilities, facility ) || ( params != 0 && params != 1 ) )
			return 0;

		new type = g_gangFacilities[ facility ] [ E_INTERIOR_TYPE ];

		// plant according to which site
		if ( ! params )
		{
			g_gangFacilities[ facility ] [ E_BOMB_OBJECT ] [ 0 ] = CreateDynamicObject( 363,
				g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 2 ],
				0.000000, 0.000000, g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 3 ],
				.worldid = g_gangFacilities[ facility ] [ E_WORLD ]
			);

			// alarm
			foreach ( new i : Player ) if ( GetPVarInt( i, "in_facility" ) == facility ) {
				PlayerPlaySound( i, 14800, g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 2 ] );
			}
		}
		else
		{
			g_gangFacilities[ facility ] [ E_BOMB_OBJECT ] [ 1 ] = CreateDynamicObject( 363,
				g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 2 ],
				0.000000, 0.000000, g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 3 ],
				.worldid = g_gangFacilities[ facility ] [ E_WORLD ]
			);

			// alarm
			foreach ( new i : Player ) if ( GetPVarInt( i, "in_facility" ) == facility ) {
				PlayerPlaySound( i, 14800, g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 2 ] );
			}
		}

		TogglePlayerControllable( playerid, 1 );
		g_gangFacilities[ facility ] [ E_BLOWN ] [ params ] = false;
		g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ params ] = FACILITY_BLOWUP_TIME + 1;
		return 1;
	}
	return 1;
}

function OnFacilityWarUpdate( facility )
{
	new
		type = g_gangFacilities[ facility ] [ E_INTERIOR_TYPE ];

	// decrement timer
	if ( g_gangFacilities[ facility ] [ E_WAR_TICK ] -- <= 0 ) {
		print( "End Round" );
	}

	// bomb timers
	for ( new siteid = 0; siteid < 2; siteid ++ ) if ( g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ siteid ] >= 0 )
	{
		if ( g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ siteid ] -- <= 0 && IsValidDynamicObject( g_gangFacilities[ facility ] [ E_BOMB_OBJECT ] [ siteid ] ) )
		{
			if ( siteid == 0 ) {
				CreateExplosion( g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_1 ] [ 2 ], 0, 10.0 );
			} else if ( siteid == 1 ) {
				CreateExplosion( g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 0 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 1 ], g_gangFacilityInterior[ type ] [ E_BOMB_POS_2 ] [ 2 ], 0, 10.0 );
			}

			Streamer_SetIntData( STREAMER_TYPE_OBJECT, g_gangFacilities[ facility ] [ E_BOMB_OBJECT ] [ siteid ], E_STREAMER_MODEL_ID, 18689 );
			g_gangFacilities[ facility ] [ E_BLOWN ] [ siteid ] = true;
		}
	}
	return ShowServerStatus( facility );
}

stock StartFacilityWar( facility, attacker )
{
	if ( g_gangFacilities[ facility ] [ E_WAR ] )
		return 0;

	g_gangFacilities[ facility ] [ E_WAR ] = true;
	g_gangFacilities[ facility ] [ E_WAR_TICK ] = 300;
	g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 0 ] = FACILITY_BLOWUP_TIME + 1;
	g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 1 ] = FACILITY_BLOWUP_TIME + 1;
	g_gangFacilities[ facility ] [ E_WAR_TIMER ] = SetTimerEx( "OnFacilityWarUpdate", 960, true, "d", facility );
	return 1;
}

stock EndFacilityWar( facility, bool: attacker_won )
{
	if ( ! g_gangFacilities[ facility ] [ E_WAR ] )
		return 1;

	g_gangFacilities[ facility ] [ E_WAR ] = 0;

	// add respect
	if ( attacker_won )
	{
		new
			defender_facility_count = 0;

		foreach ( new f : gangfacilities ) if ( g_gangFacilities[ f ] [ E_GANG_SQL_ID ] == g_gangFacilities[ facility ] [ E_GANG_SQL_ID ] ) {
			defender_facility_count ++;
		}

		new
			respect_earned = floatround( float( g_gangFacilities[ attacker ] [ E_RESPECT ] ) * ( 0.25 / float( defender_facility_count ) ) );

		printf("Earned %d respect (defender had %d facilities)", respect_earned, defender_facility_count);
	}
	return 1;
}

static stock ShowServerStatus( facility )
{
	new
		color[ 2 ] = "g";

	if ( g_gangFacilities[ facility ] [ E_WAR_TICK ] < 150 ) color = "y";
	else if ( g_gangFacilities[ facility ] [ E_WAR_TICK ] < 30 ) color = "r";

	format( szNormalString, sizeof( szNormalString ), "~%s~~h~Time Remaining: %s~w~~n~~n~Server 1: ", color, TimeConvert ( g_gangFacilities[ facility ] [ E_WAR_TICK ] ) );

	// server 1
	if ( g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 0 ] > FACILITY_BLOWUP_TIME ) {
		strcat( szNormalString, "~g~Secure~w~~n~" );
	} else if ( g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 0 ] <= 0 ) {
		strcat( szNormalString, "~r~Blown~w~~n~" );
	} else {
		format( szNormalString, sizeof( szNormalString ), "%s~r~~h~~h~%d until blown~w~~n~", szNormalString, g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 0 ] );
	}

	strcat( szNormalString, "Server 2: ");

	// server 2
	if ( g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 1 ] >= 10 ) {
		strcat( szNormalString, "~g~Secure~w~" );
	} else if ( g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 1 ] <= 0 ) {
		strcat( szNormalString, "~r~Blown~w~" );
	} else {
		format( szNormalString, sizeof( szNormalString ), "%s~r~~h~~h~%d until blown", szNormalString, g_gangFacilities[ facility ] [ E_BLOWUP_COUNT ] [ 1 ] );
	}

	// alert
	foreach ( new i : Player ) if ( GetPVarInt( i, "in_facility" ) == facility ) {
		ShowPlayerHelpDialog( i, 0, szNormalString );
	}
	return 1;
}
#endif

static stock initializeFacilityObjects( )
{
	tmpVariable = CreateDynamicObject( 16647, 249.156005, 1860.953002, 1860.366943, 0.000000, 0.000000, 180.000000, -1, -1, -1, .streamdistance = -1 );
	SetDynamicObjectMaterial( tmpVariable, 1, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 2, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 7, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 14, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 13, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 8, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 15, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 3587, "snpedhusxref", "comptwindo1", 0 );
	tmpVariable = CreateDynamicObject( 16643, 248.727005, 1869.989013, 1861.852050, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 3, 16643, "none", "none", 1 );
	SetDynamicObjectMaterial( tmpVariable, 4, 16643, "none", "none", 1 );
	CreateDynamicObject( 16651, 247.906005, 1825.625000, 1855.562011, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 16650, 247.703002, 1823.843994, 1856.555053, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, 5722, "sunrise01_lawn", "plainglass", 0 );
	tmpVariable = CreateDynamicObject( 16665, 223.429992, 1822.741943, 1856.406005, 0.000000, 0.000000, 0.000000, -1, -1, -1, .streamdistance = -1 );
	SetDynamicObjectMaterial( tmpVariable, 0, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 2, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 8419, "vgsbldng1", "black32", 0 );
	CreateDynamicObject( 16648, 244.703002, 1905.211059, 1859.906005, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 16640, 263.429992, 1840.782958, 1857.109985, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 19786, 211.182998, 1822.728027, 1859.890991, 7.900000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ACTIVE", 130, "ARIAL", 60, 1, 0, -16777216, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "\nACTIVE", 130, "ARIAL", 100, 1, -65536, -16777216, 1 );
	tmpVariable = CreateDynamicObject( 19786, 211.244003, 1822.728027, 1860.186035, 7.900000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ORBITAL CANNON", 130, "ARIAL", 50, 1, 0, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "ORBITAL CANNON", 130, "ARIAL", 50, 1, -1, 0, 1 );
	tmpVariable = CreateDynamicObject( 19786, 212.235000, 1818.493041, 1859.784057, 7.900000, 0.000000, 117.599998, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "\nACTIVE", 130, "arial", 110, 1, -65536, -16777216, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "\nACTIVE", 130, "arial", 110, 1, -16777216, -16777216, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19786, 212.212005, 1826.942993, 1859.744018, 7.900000, 0.000000, 62.299999, -1, -1, -1 ), 0, 1676, "wshxrefpump", "black64", 0 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19786, 212.212005, 1826.942993, 1859.744018, 7.900000, 0.000000, 62.299999, -1, -1, -1 ), 1, "\nACTIVE", 130, "arial", 110, 1, -65536, -16777216, 1 );
	tmpVariable = CreateDynamicObject( 19786, 212.285003, 1818.517944, 1860.119018, 7.900000, 0.000000, 117.599998, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "ORBITAL CANNON", 130, "Arial", 50, 1, -1, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ORBITAL CANNON", 130, "Arial", 50, 1, 0, 0, 1 );
	tmpVariable = CreateDynamicObject( 19786, 212.263000, 1826.916992, 1860.088989, 7.900000, 0.000000, 62.299999, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "ORBITAL CANNON", 130, "Arial", 50, 1, -1, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ORBITAL CANNON", 130, "Arial", 50, 1, 0, 0, 1 );
	CreateDynamicObject( 16782, 210.367004, 1822.741943, 1857.602050, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 16662, 211.934005, 1823.194946, 1856.639038, 0.000000, 0.000000, 63.000000, -1, -1, -1 );
	CreateDynamicObject( 3526, 222.003005, 1828.145019, 1855.504028, 0.000000, 0.000000, 68.900001, -1, -1, -1 );
	CreateDynamicObject( 3526, 224.410995, 1826.500000, 1855.504028, 0.000000, 0.000000, 41.799999, -1, -1, -1 );
	CreateDynamicObject( 3526, 221.975997, 1817.296997, 1855.504028, 0.000000, 0.000000, -69.500000, -1, -1, -1 );
	CreateDynamicObject( 3526, 224.350006, 1818.922973, 1855.504028, 0.000000, 0.000000, -41.700000, -1, -1, -1 );
	CreateDynamicObject( 964, 253.541000, 1797.566040, 1856.404052, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 964, 252.100997, 1797.566040, 1856.404052, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 964, 253.220993, 1797.251953, 1857.343994, 0.000000, 0.000000, -167.699996, -1, -1, -1 );
	CreateDynamicObject( 355, 254.179992, 1799.074951, 1856.722045, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 355, 254.179992, 1798.395019, 1856.722045, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 355, 254.179992, 1798.734985, 1856.722045, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 2358, 252.067993, 1797.734008, 1857.472045, 0.000000, 0.000000, -130.000000, -1, -1, -1 );
	CreateDynamicObject( 2358, 253.134002, 1797.234985, 1858.391967, 0.000000, 0.000000, 175.800003, -1, -1, -1 );
	CreateDynamicObject( 2359, 251.667007, 1796.734008, 1857.501953, 0.000000, 0.000000, 14.500000, -1, -1, -1 );
	CreateDynamicObject( 923, 252.889007, 1805.036010, 1857.281982, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 923, 250.542999, 1804.788940, 1857.281982, 0.000000, 0.000000, 11.699999, -1, -1, -1 );
	CreateDynamicObject( 18637, 251.001998, 1796.952026, 1856.943969, 80.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 18637, 250.341995, 1796.952026, 1856.943969, 80.000000, 0.000000, 180.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2063, 241.001007, 1799.272949, 1857.303955, 0.000000, 0.000000, 134.600006, -1, -1, -1 ), 0, 2063, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2063, 244.800003, 1797.186035, 1857.303955, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 2063, "none", "none", 0 );
	CreateDynamicObject( 1271, 246.636001, 1797.443969, 1856.803955, 0.000000, 0.000000, 19.600000, -1, -1, -1 );
	CreateDynamicObject( 1271, 242.404006, 1798.142944, 1856.803955, 0.000000, 0.000000, -74.000000, -1, -1, -1 );
	CreateDynamicObject( 1271, 243.054000, 1797.572021, 1856.803955, 0.000000, 0.000000, -39.700000, -1, -1, -1 );
	CreateDynamicObject( 1271, 242.751998, 1797.739013, 1857.463989, 0.000000, 0.000000, 154.000000, -1, -1, -1 );
	CreateDynamicObject( 19602, 240.326995, 1799.930053, 1857.303955, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19602, 240.619995, 1799.656982, 1857.303955, 0.000000, 0.000000, 47.200000, -1, -1, -1 );
	CreateDynamicObject( 19602, 240.996994, 1799.318969, 1857.303955, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2040, 241.138000, 1799.099975, 1858.183959, 0.000000, 0.000000, 45.000000, -1, -1, -1 );
	CreateDynamicObject( 2040, 241.533996, 1798.703979, 1858.183959, 0.000000, 0.000000, 21.200000, -1, -1, -1 );
	CreateDynamicObject( 2036, 244.300003, 1797.150024, 1857.254028, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2036, 245.289001, 1797.150024, 1857.693969, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2035, 244.819000, 1797.150024, 1856.784057, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2035, 245.429000, 1797.150024, 1858.104003, 0.000000, 0.000000, 11.600000, -1, -1, -1 );
	CreateDynamicObject( 19515, 243.938995, 1797.230957, 1858.313964, 0.000000, -90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19515, 244.578994, 1797.230957, 1858.313964, 0.000000, -90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 359, 241.255996, 1798.937011, 1857.703979, 90.000000, 0.000000, 135.000000, -1, -1, -1 );
	CreateDynamicObject( 359, 239.716995, 1800.338989, 1857.154052, -8.399999, -88.400001, 138.899993, -1, -1, -1 );
	CreateDynamicObject( 359, 239.397003, 1800.671997, 1857.188964, -8.399999, -88.400001, 138.899993, -1, -1, -1 );
	CreateDynamicObject( 2056, 246.738006, 1797.470947, 1857.154052, -90.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2056, 246.554992, 1797.300048, 1857.173950, -90.000000, 0.000000, 43.099998, -1, -1, -1 );
	CreateDynamicObject( 1654, 241.621994, 1798.675048, 1857.404052, 0.000000, 0.000000, 124.300003, -1, -1, -1 );
	CreateDynamicObject( 1654, 241.350006, 1798.915039, 1857.404052, 0.000000, 0.000000, 175.399993, -1, -1, -1 );
	CreateDynamicObject( 370, 239.292999, 1801.390991, 1856.764038, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 16654, 248.358993, 1782.765991, 1856.819946, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 0, 18038, "vegas_munation", "mp_gun_floorred", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 18038, "vegas_munation", "mp_gun_floorred", 0 );
	CreateDynamicObject( 16646, 245.960998, 1865.586059, 1860.828002, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 16642, 247.242004, 1823.897949, 1858.843994, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 3, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 11, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 7, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 12, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 245.067001, 1827.708984, 1855.163940, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 246.557998, 1827.848999, 1855.163940, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 245.067001, 1816.129028, 1855.163940, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 246.548004, 1816.269042, 1855.163940, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	CreateDynamicObject( 14532, 244.511001, 1818.031982, 1857.404052, 0.000000, 0.000000, -64.099998, -1, -1, -1 );
	CreateDynamicObject( 14532, 244.520996, 1829.708984, 1857.413940, 0.000000, 0.000000, -64.099998, -1, -1, -1 );
	CreateDynamicObject( 3388, 244.970993, 1825.399047, 1853.524047, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 3388, 245.981002, 1825.399047, 1853.524047, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 3388, 244.970993, 1818.328979, 1853.524047, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 3388, 245.960998, 1818.328979, 1853.524047, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 16658, 283.406005, 1818.578002, 1855.991943, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 6, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( tmpVariable, 7, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( tmpVariable, 8, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( tmpVariable, 11, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	CreateDynamicObject( 16661, 287.554992, 1820.008056, 1855.218994, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 16659, 287.601989, 1819.647949, 1856.977050, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 11714, 277.506011, 1821.741943, 1858.069946, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 262.069000, 1817.915039, 1851.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 272.069000, 1817.915039, 1851.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 282.069000, 1817.915039, 1851.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 292.058990, 1817.915039, 1851.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 302.049011, 1817.915039, 1851.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 262.069000, 1827.906005, 1851.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	CreateDynamicObject( 16641, 272.330993, 1805.993041, 1855.167968, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 3397, 239.138000, 1829.255004, 1853.711059, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 3397, 239.138000, 1816.213012, 1853.711059, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1989, 239.065994, 1822.729980, 1853.711059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1989, 239.065994, 1823.711059, 1853.711059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1989, 239.065994, 1821.739990, 1853.711059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1714, 240.231002, 1816.511962, 1853.691040, 0.000000, 0.000000, -60.000000, -1, -1, -1 );
	CreateDynamicObject( 1714, 240.320999, 1828.269042, 1853.691040, 0.000000, 0.000000, -110.199996, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 238.559005, 1825.869018, 1855.470947, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16644, "a51_detailstuff", "a51_map", 0 );
	CreateDynamicObject( 2615, 238.597000, 1828.056030, 1855.931030, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1811.739013, 1863.703979, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1821.369018, 1863.703979, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1831.000000, 1863.703979, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1833.501953, 1863.702026, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	CreateDynamicObject( 11714, 297.735992, 1821.741943, 1858.069946, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 249.175994, 1857.734008, 1863.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 248.505996, 1857.734008, 1863.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 247.845993, 1857.734008, 1863.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11730, 247.186004, 1857.734008, 1863.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 246.535995, 1857.734008, 1863.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11730, 245.886001, 1857.734008, 1863.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2206, 246.013000, 1860.954956, 1863.024047, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 1675, "wshxrefhse", "greygreensubuild_128", 0 );
	CreateDynamicObject( 1714, 246.960998, 1859.885009, 1863.073974, 0.000000, 0.000000, -151.199996, -1, -1, -1 );
	CreateDynamicObject( 356, 246.848999, 1860.711059, 1864.024047, -89.900001, 2.500000, -1.399999, -1, -1, -1 );
	CreateDynamicObject( 2043, 246.582000, 1861.208007, 1864.063964, 0.000000, 0.000000, -59.299999, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2167, 242.563003, 1862.652954, 1863.104003, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 1675, "wshxrefhse", "greygreensubuild_128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2167, 241.652999, 1862.652954, 1863.104003, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 1675, "wshxrefhse", "greygreensubuild_128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19787, 241.391006, 1857.465942, 1864.854003, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 16150, "ufo_bar", "black32", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19787, 243.671005, 1857.465942, 1864.854003, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 16150, "ufo_bar", "black32", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11714, 238.455993, 1872.332031, 1859.208984, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 19799, "all_vault", "liftdoorsac256", -16 );
	// SetDynamicObjectMaterialText( CreateDynamicObject( 7909, 263.942993, 1861.439941, 1862.397949, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, "The Lost And Damned", 120, "impact", 48, 0, 0xFF964B00, 0, 1 );
	tmpVariable = CreateDynamicObject( 19926, 248.494995, 1798.292968, 1856.375976, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 0, 4552, "ammu_lan2", "newall4-4", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 4552, "ammu_lan2", "newall4-4", 0 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 247.796997, 1806.805053, 1859.504028, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, "Ammunation", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19327, 233.839004, 1821.076049, 1858.443969, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "Authorized personnel\nONLY", 120, "IMPACT", 25, 0, -4671304, 0, 1 );
	tmpVariable = CreateDynamicObject( 19173, 245.843002, 1827.785034, 1857.543945, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "SERVERS", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "SERVERS", 120, "IMPACT", 84, 1, 0, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 295.842010, 1821.823974, 1857.980957, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 279.122009, 1821.823974, 1857.980957, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19741, 249.591003, 1868.484985, 1857.511962, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16375, "des_boneyard", "roucghstone", -256 );
	CreateDynamicObject( 922, 242.257003, 1805.038940, 1857.333984, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 248.867004, 1842.296997, 1860.644042, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, "Server Room", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 234.757003, 1822.738037, 1859.463989, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "Orbital Cannon", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	tmpVariable = CreateDynamicObject( 19173, 245.843002, 1816.214965, 1857.543945, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "SERVERS", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "SERVERS", 120, "IMPACT", 84, 1, 0, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19875, 238.533996, 1871.010986, 1860.458984, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, 16649, "a51", "a51_weedoors", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19875, 238.535003, 1873.715942, 1860.458984, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16649, "a51", "a51_weedoors", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3061, 247.550003, 1841.797973, 1868.943969, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 5722, "sunrise01_lawn", "plainglass", -16 );
	CreateDynamicObject( 18981, 252.274002, 1873.482055, 1857.004028, 0.000000, 90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 11400, 243.199996, 1850.332031, 1863.477050, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19917, 242.819000, 1850.366943, 1861.944946, -63.799999, 0.000000, -90.500000, -1, -1, -1 );
	CreateDynamicObject( 19899, 241.804000, 1842.675048, 1857.727050, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19917, 239.598007, 1843.348022, 1857.727050, 0.000000, 0.000000, -73.400001, -1, -1, -1 );
	CreateDynamicObject( 3565, 249.134002, 1875.989990, 1859.078002, 0.000000, 0.000000, -12.500000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19817, 244.731994, 1855.046997, 1856.496948, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 12923, "sw_block05", "dustyconcrete", 0 );
	CreateDynamicObject( 19929, 238.908996, 1845.779052, 1857.732055, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2475, 238.576004, 1845.092041, 1857.786987, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 2475, 238.576004, 1845.973022, 1857.786987, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19903, 238.886993, 1852.663940, 1857.744018, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19903, 238.886993, 1857.545043, 1857.744018, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19817, 244.731994, 1859.936035, 1856.505004, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 12923, "sw_block05", "dustyconcrete", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19817, 244.731994, 1850.213012, 1856.496948, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 12923, "sw_block05", "dustyconcrete", 0 );
	CreateDynamicObject( 1002, 238.729995, 1845.829956, 1860.006958, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1014, 238.535003, 1845.823974, 1859.274047, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1650, 239.013000, 1846.689941, 1858.963989, 0.000000, 0.000000, 25.200000, -1, -1, -1 );
	CreateDynamicObject( 19921, 239.309997, 1845.805053, 1858.758056, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19621, 239.005004, 1844.909057, 1858.761962, 0.000000, 0.000000, -147.699996, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19355, 245.260803, 1842.088012, 1860.215576, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 10249, "ottos2_sfw", "ottos_pics_sfe", 0 );
	CreateDynamicObject( 19815, 238.535003, 1855.029052, 1860.095825, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19815, 238.535003, 1855.029052, 1859.104858, 0.000000, 180.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1999, 244.522003, 1843.942016, 1857.735961, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2059, 244.578002, 1844.083007, 1858.573974, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1984, 258.829010, 1851.767944, 1857.656005, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1848, 262.945007, 1855.573974, 1857.625976, 0.000000, 0.000000, 270.000000, -1, -1, -1 );
	CreateDynamicObject( 341, 256.651123, 1855.343017, 1858.655761, 0.000000, 28.199998, -109.299942, -1, -1, -1 );
	CreateDynamicObject( 1842, 259.781005, 1855.352050, 1858.107055, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1995, 256.463989, 1851.837036, 1857.586059, 0.000000, 0.000000, 270.000000, -1, -1, -1 );
	CreateDynamicObject( 1995, 256.493988, 1852.828979, 1857.586059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1995, 256.463989, 1854.759033, 1857.586059, 0.000000, 0.000000, 270.000000, -1, -1, -1 );
	CreateDynamicObject( 1995, 256.493988, 1855.750976, 1857.586059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 944, 251.302017, 1856.556518, 1858.638427, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 341, 256.467956, 1855.982666, 1858.664794, 0.000000, 28.199998, -107.400222, -1, -1, -1 );
	CreateDynamicObject( 918, 256.495544, 1851.684448, 1858.817626, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1650, 256.497772, 1852.841674, 1858.757568, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1650, 256.614929, 1853.054931, 1858.757568, 0.000000, 0.000000, -24.800024, -1, -1, -1 );
	CreateDynamicObject( 918, 256.495544, 1852.335083, 1858.817626, 0.000000, 0.000000, -66.499977, -1, -1, -1 );
	CreateDynamicObject( 19329, 259.889465, 1849.657836, 1859.798583, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2164, 261.189849, 1872.801391, 1857.736572, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2162, 263.488403, 1871.236206, 1857.736572, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 2161, 263.488403, 1869.464477, 1857.736572, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 2162, 263.488403, 1868.134765, 1857.736572, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 2164, 259.419281, 1872.801391, 1857.736572, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2167, 258.498840, 1872.801391, 1857.736572, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2165, 260.386077, 1868.690551, 1857.736572, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 2310, 259.283569, 1868.564941, 1858.307128, 0.000000, 0.000000, -137.900177, -1, -1, -1 );
	CreateDynamicObject( 2472, 263.625640, 1869.469970, 1859.107910, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 1685, 257.151245, 1863.329711, 1858.477294, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 3800, 260.969757, 1862.297241, 1857.726562, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 3798, 262.515991, 1862.757446, 1857.706542, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1348, 257.097320, 1864.635742, 1858.427246, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1891, 259.709838, 1859.312500, 1857.666503, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1885, 256.321441, 1859.682617, 1857.696533, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1885, 256.321441, 1858.931884, 1857.696533, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 238.587280, 1849.567504, 1860.304809, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "Gang Vehicles", 120, "Impact", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 263.417633, 1869.281738, 1860.304809, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, "Fast Travel", 120, "Impact", 84, 0, -13421773, 0, 1 );
}

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
