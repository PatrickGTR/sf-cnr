/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: facilities.inc
 * Purpose: gang facilities module
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define	MAX_FACILITIES 				( 24 )

#define FACILITY_AMMU_RESPECT 		( 75000.0 )

#define DIALOG_GANG_JOIN 			( 9238 )
#define DIALOG_FACILITY_AMMU 		( 9239 )
#define DIALOG_FACILITY_AMMU_BUY 	( 9299 )

/* ** Variables ** */
enum E_GANG_FACILITIES
{
	E_GANG_SQL_ID,					E_TURF_ID,				E_INTERIOR_TYPE,
	E_WORLD,

	Text3D: E_LABEL[ 2 ],			E_CHECKPOINT[ 2 ],

	Float: E_X, 					Float: E_Y, 			Float: E_Z,

	E_AMMU_CP
};

enum E_FACILITY_INTERIOR
{
	Float: E_X, 					Float: E_Y, 			Float: E_Z,

	Float: E_AMMU_POS[ 4 ] 			//Float: E_MECHANIC_POS[ 4 ]
};

new
	g_gangFacilityInterior 			[ ] [ E_FACILITY_INTERIOR ] =
	{
		{ 228.2063, 1872.4011, 1463.7345, { 248.4965, 1797.5060, 1457.4143, 0.000000 } }
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
			    UpdatePlayerEntranceExitTick( playerid );
				SetPlayerPos( playerid, g_gangFacilityInterior[ int_type ] [ E_X ], g_gangFacilityInterior[ int_type ] [ E_Y ], g_gangFacilityInterior[ int_type ] [ E_Z ] );
			  	SetPlayerVirtualWorld( playerid, g_gangFacilities[ facility ] [ E_WORLD ] );
				SetPlayerInterior( playerid, 0 );
				break;
			}

			// exit
			else if ( checkpointid == g_gangFacilities[ facility ] [ E_CHECKPOINT ] [ 1 ] )
			{
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
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_GANG_JOIN && response )
	{
		if ( p_GangID[ playerid ] != -1 )
			return SendServerMessage( playerid, "You are already in a gang." );

		new
			joining_gang = GetPVarInt( playerid, "gang_facility_join" );

		if ( ! Iter_Contains( gangs, joining_gang ) || IsGangPrivate( joining_gang ) )
			return SendError( playerid, "You can no longer join this gang." );

		p_GangID[ playerid ] = joining_gang;
	    if ( GetPlayerWantedLevel( playerid ) < 1 ) SetPlayerColor( playerid, g_gangData[ joining_gang ] [ E_COLOR ] );
		mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=%d WHERE `ID`=%d", g_gangData[ joining_gang ] [ E_SQL_ID ], GetPlayerAccountID( playerid ) ) );
		SendClientMessageToGang( joining_gang, g_gangData[ joining_gang ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has joined the gang.", ReturnPlayerName( playerid ), playerid );
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
			new player_gang = GetPlayerGang( playerid );

			if ( ! Iter_Contains( gangs, player_gang ) ) return SendError( playerid, "You are not in any gang." );
		    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot buy weapons in jail." );
		    if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot buy weapons in an event." );
			if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED || !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You are unable to purchase any weapons at this time." );

			new gun_category = GetPVarInt( playerid, "facility_weapon_cat" );
			new Float: gun_discount = ( FACILITY_AMMU_RESPECT - float( g_gangData[ player_gang ] [ E_RESPECT ] ) ) / FACILITY_AMMU_RESPECT;

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

						if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 101 ) SetPlayerArmour( playerid, float( g_AmmunationWeapons[ i ] [ E_AMMO ] ) );
						else GivePlayerWeapon( playerid, g_AmmunationWeapons[ i ] [ E_WEPID ], g_AmmunationWeapons[ i ] [ E_AMMO ] );

      					RedirectAmmunation( playerid, gun_category, "{FFFFFF}Gang Facility - Purchase Weapons", DIALOG_FACILITY_AMMU_BUY, gun_discount );
						SendServerMessage( playerid, "You have purchased %s(%d) for "COL_GOLD"%s"COL_WHITE"%s.", g_AmmunationWeapons[ i ] [ E_NAME ], g_AmmunationWeapons[ i ] [ E_AMMO ], price > 0.0 ? number_format( price ) : ( "FREE" ) );
						break;
		            }
		            x ++;
		        }
		    }
		}
		else return ShowAmmunationMenu( playerid, "{FFFFFF}Gang Facility - Purchase Weapons", DIALOG_FACILITY_AMMU );
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

					g_gangFacilities[ id ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_gangFacilityInterior[ type ] [ E_X ], g_gangFacilityInterior[ type ] [ E_Y ], g_gangFacilityInterior[ type ] [ E_Z ], 1.0, g_gangFacilities[ id ] [ E_WORLD ], -1, -1, 100.0 );
					g_gangFacilities[ id ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, g_gangFacilityInterior[ type ] [ E_X ], g_gangFacilityInterior[ type ] [ E_Y ], g_gangFacilityInterior[ type ] [ E_Z ], 20.0 );

					// ammunation man
					CreateDynamicActor( 179, g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 0 ], g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 1 ], g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 2 ], g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 3 ], true, 100.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );

					new Float: infront_x = g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 0 ] + 2.0 * floatsin( g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 3 ], degrees );
					new Float: infront_y = g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 1 ] + 2.0 * floatcos( g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 3 ], degrees );

					g_gangFacilities[ id ] [ E_AMMU_CP ] = CreateDynamicCP( infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 2 ], 1.0, g_gangFacilities[ id ] [ E_WORLD ], -1, -1, 100.0 );
					CreateDynamic3DTextLabel( "[AMMU-NATION]", COLOR_GOLD, infront_x, infront_y, g_gangFacilityInterior[ type ] [ E_AMMU_POS ] [ 2 ], 20.0, .worldid = g_gangFacilities[ id ] [ E_WORLD ] );
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

stock GetFacilityInteriorType( gang_sql_id )
{
	#pragma unused gang_sql_id
	// todo
	return 0;
}

static stock initializeFacilityObjects( )
{
	tmpVariable = CreateDynamicObject( 16647, 249.156005, 1860.953002, 1460.366943, 0.000000, 0.000000, 180.000000, -1, -1, -1, .streamdistance = -1 );
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
	CreateDynamicObject( 16641, 279.890991, 1807.014038, -44.832000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 16643, 248.727005, 1869.989013, 1461.852050, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 3, 16643, "none", "none", 1 );
	SetDynamicObjectMaterial( tmpVariable, 4, 16643, "none", "none", 1 );
	CreateDynamicObject( 16651, 247.906005, 1825.625000, 1455.562011, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 16650, 247.703002, 1823.843994, 1456.555053, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, 5722, "sunrise01_lawn", "plainglass", 0 );
	tmpVariable = CreateDynamicObject( 16665, 223.429992, 1822.741943, 1456.406005, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 0, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 2, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 8419, "vgsbldng1", "black32", 0 );
	CreateDynamicObject( 16648, 244.703002, 1905.211059, 1459.906005, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 16640, 263.429992, 1840.782958, 1457.109985, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 19786, 211.182998, 1822.728027, 1459.890991, 7.900000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ACTIVE", 130, "ARIAL", 60, 1, 0, -16777216, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "\nACTIVE", 130, "ARIAL", 100, 1, -65536, -16777216, 1 );
	tmpVariable = CreateDynamicObject( 19786, 211.244003, 1822.728027, 1460.186035, 7.900000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ORBITAL CANNON", 130, "ARIAL", 50, 1, 0, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "ORBITAL CANNON", 130, "ARIAL", 50, 1, -1, 0, 1 );
	tmpVariable = CreateDynamicObject( 19786, 212.235000, 1818.493041, 1459.784057, 7.900000, 0.000000, 117.599998, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "\nACTIVE", 130, "arial", 110, 1, -65536, -16777216, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "\nACTIVE", 130, "arial", 110, 1, -16777216, -16777216, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19786, 212.212005, 1826.942993, 1459.744018, 7.900000, 0.000000, 62.299999, -1, -1, -1 ), 0, 16658, "a51", "wallgreyred128", 0 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19786, 212.212005, 1826.942993, 1459.744018, 7.900000, 0.000000, 62.299999, -1, -1, -1 ), 1, "\nACTIVE", 130, "arial", 110, 1, -65536, -16777216, 1 );
	tmpVariable = CreateDynamicObject( 19786, 212.285003, 1818.517944, 1460.119018, 7.900000, 0.000000, 117.599998, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "ORBITAL CANNON", 130, "Arial", 50, 1, -1, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ORBITAL CANNON", 130, "Arial", 50, 1, 0, 0, 1 );
	tmpVariable = CreateDynamicObject( 19786, 212.263000, 1826.916992, 1460.088989, 7.900000, 0.000000, 62.299999, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "ORBITAL CANNON", 130, "Arial", 50, 1, -1, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "ORBITAL CANNON", 130, "Arial", 50, 1, 0, 0, 1 );
	CreateDynamicObject( 16782, 210.367004, 1822.741943, 1457.602050, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 16662, 211.934005, 1823.194946, 1456.639038, 0.000000, 0.000000, 63.000000, -1, -1, -1 );
	CreateDynamicObject( 3526, 222.003005, 1828.145019, 1455.504028, 0.000000, 0.000000, 68.900001, -1, -1, -1 );
	CreateDynamicObject( 3526, 224.410995, 1826.500000, 1455.504028, 0.000000, 0.000000, 41.799999, -1, -1, -1 );
	CreateDynamicObject( 3526, 221.975997, 1817.296997, 1455.504028, 0.000000, 0.000000, -69.500000, -1, -1, -1 );
	CreateDynamicObject( 3526, 224.350006, 1818.922973, 1455.504028, 0.000000, 0.000000, -41.700000, -1, -1, -1 );
	CreateDynamicObject( 964, 253.541000, 1797.566040, 1456.404052, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 964, 252.100997, 1797.566040, 1456.404052, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 964, 253.220993, 1797.251953, 1457.343994, 0.000000, 0.000000, -167.699996, -1, -1, -1 );
	CreateDynamicObject( 355, 254.179992, 1799.074951, 1456.722045, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 355, 254.179992, 1798.395019, 1456.722045, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 355, 254.179992, 1798.734985, 1456.722045, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 2358, 252.067993, 1797.734008, 1457.472045, 0.000000, 0.000000, -130.000000, -1, -1, -1 );
	CreateDynamicObject( 2358, 253.134002, 1797.234985, 1458.391967, 0.000000, 0.000000, 175.800003, -1, -1, -1 );
	CreateDynamicObject( 2359, 251.667007, 1796.734008, 1457.501953, 0.000000, 0.000000, 14.500000, -1, -1, -1 );
	CreateDynamicObject( 923, 252.889007, 1805.036010, 1457.281982, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 923, 250.542999, 1804.788940, 1457.281982, 0.000000, 0.000000, 11.699999, -1, -1, -1 );
	CreateDynamicObject( 18637, 251.001998, 1796.952026, 1456.943969, 80.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 18637, 250.341995, 1796.952026, 1456.943969, 80.000000, 0.000000, 180.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2063, 241.001007, 1799.272949, 1457.303955, 0.000000, 0.000000, 134.600006, -1, -1, -1 ), 0, 2063, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2063, 244.800003, 1797.186035, 1457.303955, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 2063, "none", "none", 0 );
	CreateDynamicObject( 1271, 246.636001, 1797.443969, 1456.803955, 0.000000, 0.000000, 19.600000, -1, -1, -1 );
	CreateDynamicObject( 1271, 242.404006, 1798.142944, 1456.803955, 0.000000, 0.000000, -74.000000, -1, -1, -1 );
	CreateDynamicObject( 1271, 243.054000, 1797.572021, 1456.803955, 0.000000, 0.000000, -39.700000, -1, -1, -1 );
	CreateDynamicObject( 1271, 242.751998, 1797.739013, 1457.463989, 0.000000, 0.000000, 154.000000, -1, -1, -1 );
	CreateDynamicObject( 19602, 240.326995, 1799.930053, 1457.303955, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19602, 240.619995, 1799.656982, 1457.303955, 0.000000, 0.000000, 47.200000, -1, -1, -1 );
	CreateDynamicObject( 19602, 240.996994, 1799.318969, 1457.303955, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2040, 241.138000, 1799.099975, 1458.183959, 0.000000, 0.000000, 45.000000, -1, -1, -1 );
	CreateDynamicObject( 2040, 241.533996, 1798.703979, 1458.183959, 0.000000, 0.000000, 21.200000, -1, -1, -1 );
	CreateDynamicObject( 2036, 244.300003, 1797.150024, 1457.254028, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2036, 245.289001, 1797.150024, 1457.693969, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2035, 244.819000, 1797.150024, 1456.784057, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2035, 245.429000, 1797.150024, 1458.104003, 0.000000, 0.000000, 11.600000, -1, -1, -1 );
	CreateDynamicObject( 19515, 243.938995, 1797.230957, 1458.313964, 0.000000, -90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19515, 244.578994, 1797.230957, 1458.313964, 0.000000, -90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 359, 241.255996, 1798.937011, 1457.703979, 90.000000, 0.000000, 135.000000, -1, -1, -1 );
	CreateDynamicObject( 359, 239.716995, 1800.338989, 1457.154052, -8.399999, -88.400001, 138.899993, -1, -1, -1 );
	CreateDynamicObject( 359, 239.397003, 1800.671997, 1457.188964, -8.399999, -88.400001, 138.899993, -1, -1, -1 );
	CreateDynamicObject( 2056, 246.738006, 1797.470947, 1457.154052, -90.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2056, 246.554992, 1797.300048, 1457.173950, -90.000000, 0.000000, 43.099998, -1, -1, -1 );
	CreateDynamicObject( 1654, 241.621994, 1798.675048, 1457.404052, 0.000000, 0.000000, 124.300003, -1, -1, -1 );
	CreateDynamicObject( 1654, 241.350006, 1798.915039, 1457.404052, 0.000000, 0.000000, 175.399993, -1, -1, -1 );
	CreateDynamicObject( 370, 239.292999, 1801.390991, 1456.764038, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 16654, 248.358993, 1782.765991, 1456.819946, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 0, 18038, "vegas_munation", "mp_gun_floorred", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 18038, "vegas_munation", "mp_gun_floorred", 0 );
	CreateDynamicObject( 16646, 245.960998, 1865.586059, 1460.828002, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 16642, 247.242004, 1823.897949, 1458.843994, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 3, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 11, 6038, "lawwhitebuilds", "brwall_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 7, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( tmpVariable, 12, 17538, "losflor4_lae2", "tarmacplain_bank", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 245.067001, 1827.708984, 1455.163940, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 246.557998, 1827.848999, 1455.163940, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 245.067001, 1816.129028, 1455.163940, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3384, 246.548004, 1816.269042, 1455.163940, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 3384, "none", "none", 0 );
	CreateDynamicObject( 14532, 244.511001, 1818.031982, 1457.404052, 0.000000, 0.000000, -64.099998, -1, -1, -1 );
	CreateDynamicObject( 14532, 244.520996, 1829.708984, 1457.413940, 0.000000, 0.000000, -64.099998, -1, -1, -1 );
	CreateDynamicObject( 3388, 244.970993, 1825.399047, 1453.524047, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 3388, 245.981002, 1825.399047, 1453.524047, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 3388, 244.970993, 1818.328979, 1453.524047, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 3388, 245.960998, 1818.328979, 1453.524047, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	tmpVariable = CreateDynamicObject( 16658, 283.406005, 1818.578002, 1455.991943, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 6, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( tmpVariable, 7, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( tmpVariable, 8, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( tmpVariable, 11, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	CreateDynamicObject( 16661, 287.554992, 1820.008056, 1455.218994, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 16659, 287.601989, 1819.647949, 1456.977050, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 11714, 277.506011, 1821.741943, 1458.069946, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 262.069000, 1817.915039, 1451.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 272.069000, 1817.915039, 1451.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 282.069000, 1817.915039, 1451.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 292.058990, 1817.915039, 1451.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 302.049011, 1817.915039, 1451.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, 262.069000, 1827.906005, 1451.145019, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16640, "a51", "ws_castironwalk", -16 );
	CreateDynamicObject( 16641, 272.330993, 1805.993041, 1455.167968, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 3397, 239.138000, 1829.255004, 1453.711059, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 3397, 239.138000, 1816.213012, 1453.711059, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1989, 239.065994, 1822.729980, 1453.711059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1989, 239.065994, 1823.711059, 1453.711059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1989, 239.065994, 1821.739990, 1453.711059, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1714, 240.231002, 1816.511962, 1453.691040, 0.000000, 0.000000, -60.000000, -1, -1, -1 );
	CreateDynamicObject( 1714, 240.320999, 1828.269042, 1453.691040, 0.000000, 0.000000, -110.199996, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19328, 238.559005, 1825.869018, 1455.470947, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16644, "a51_detailstuff", "a51_map", 0 );
	CreateDynamicObject( 2615, 238.597000, 1828.056030, 1455.931030, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1811.739013, 1463.703979, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1821.369018, 1463.703979, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1831.000000, 1463.703979, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 247.826004, 1833.501953, 1463.702026, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 16656, "a51_labs", "ws_trainstationwin1", 0 );
	CreateDynamicObject( 11714, 297.735992, 1821.741943, 1458.069946, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 249.175994, 1857.734008, 1463.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 248.505996, 1857.734008, 1463.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 247.845993, 1857.734008, 1463.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11730, 247.186004, 1857.734008, 1463.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11729, 246.535995, 1857.734008, 1463.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11730, 245.886001, 1857.734008, 1463.093994, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 11730, "none", "none", -251658241 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2206, 246.013000, 1860.954956, 1463.024047, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 1675, "wshxrefhse", "greygreensubuild_128", 0 );
	CreateDynamicObject( 1714, 246.960998, 1859.885009, 1463.073974, 0.000000, 0.000000, -151.199996, -1, -1, -1 );
	CreateDynamicObject( 356, 246.848999, 1860.711059, 1464.024047, -89.900001, 2.500000, -1.399999, -1, -1, -1 );
	CreateDynamicObject( 2043, 246.582000, 1861.208007, 1464.063964, 0.000000, 0.000000, -59.299999, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2167, 242.563003, 1862.652954, 1463.104003, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 1675, "wshxrefhse", "greygreensubuild_128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2167, 241.652999, 1862.652954, 1463.104003, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 1675, "wshxrefhse", "greygreensubuild_128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19787, 241.391006, 1857.465942, 1464.854003, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 16150, "ufo_bar", "black32", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19787, 243.671005, 1857.465942, 1464.854003, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, 16150, "ufo_bar", "black32", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 11714, 238.455993, 1872.332031, 1459.208984, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 19799, "all_vault", "liftdoorsac256", -16 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 7909, 263.942993, 1861.439941, 1462.397949, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, "! Work In Progress !", 120, "impact", 48, 0, -16711936, 0, 1 );
	tmpVariable = CreateDynamicObject( 19926, 248.494995, 1798.292968, 1456.375976, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( tmpVariable, 0, 4552, "ammu_lan2", "newall4-4", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 4552, "ammu_lan2", "newall4-4", 0 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 247.796997, 1806.805053, 1459.504028, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, "Ammunation", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19327, 233.839004, 1821.076049, 1458.443969, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "Authorized personnel\nONLY", 120, "IMPACT", 25, 0, -4671304, 0, 1 );
	tmpVariable = CreateDynamicObject( 19173, 245.843002, 1827.785034, 1457.543945, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "SERVERS", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "SERVERS", 120, "IMPACT", 84, 1, 0, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 295.842010, 1821.823974, 1457.980957, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 279.122009, 1821.823974, 1457.980957, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16644, "a51_detailstuff", "concretegroundl1_256", -47 );
	CreateDynamicObject( 19618, 238.981002, 1819.521972, 1454.151000, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 3787, 252.636001, 1843.160034, 1458.297973, 0.000000, 0.000000, 6.000000, -1, -1, -1 );
	CreateDynamicObject( 1685, 250.477996, 1856.599975, 1458.527954, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 964, 249.166000, 1858.026977, 1457.767944, 0.000000, 0.000000, -140.899993, -1, -1, -1 );
	CreateDynamicObject( 964, 248.787994, 1856.234985, 1457.767944, 0.000000, 0.000000, -87.400001, -1, -1, -1 );
	CreateDynamicObject( 1348, 251.755996, 1858.241943, 1458.517944, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19741, 249.591003, 1868.484985, 1457.511962, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 16375, "des_boneyard", "roucghstone", -256 );
	CreateDynamicObject( 922, 242.257003, 1805.038940, 1457.333984, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 248.867004, 1842.296997, 1460.644042, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, "Server Room", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 2662, 234.757003, 1822.738037, 1459.463989, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "Orbital Cannon", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	tmpVariable = CreateDynamicObject( 19173, 245.843002, 1816.214965, 1457.543945, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( tmpVariable, 0, "SERVERS", 120, "IMPACT", 84, 0, -13421773, 0, 1 );
	SetDynamicObjectMaterialText( tmpVariable, 1, "SERVERS", 120, "IMPACT", 84, 1, 0, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19875, 227.824996, 1873.713012, 1462.730957, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16649, "a51", "a51_weedoors", -16 );
	CreateDynamicObject( 16649, 231.477005, 1872.359008, 1461.961059, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 16649, 231.477005, 1872.359008, 1461.961059, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19875, 227.824996, 1871.010986, 1462.730957, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, 16649, "a51", "a51_weedoors", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19875, 227.815002, 1870.931030, 1462.730957, 0.000000, 0.000000, -90.000000, -1, -1, -1 ), 0, 16649, "a51", "a51_weedoors", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19875, 227.815002, 1873.796020, 1462.730957, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 16649, "a51", "a51_weedoors", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3061, 247.550003, 1841.797973, 1468.943969, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 5722, "sunrise01_lawn", "plainglass", -16 );
	CreateDynamicObject( 2960, 239.701995, 1844.417968, 1460.024047, 0.000000, 90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2960, 239.701995, 1849.417968, 1460.024047, 0.000000, 90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2960, 242.901992, 1849.417968, 1460.024047, 0.000000, 90.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2960, 242.901992, 1844.417968, 1460.024047, 0.000000, 90.000000, 0.000000, -1, -1, -1 );
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
