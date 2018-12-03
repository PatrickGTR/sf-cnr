 /*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\houses\burglar.pwn
 * Purpose: burglarly system (to steal house furniture)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error checking ** */
#if !defined MAX_FURNITURE
	#error "Furniture system must be enabled for this module to work."
#endif

/* ** Definitions ** */
#define MAX_BURGLARY_SLOTS          ( 8 )

#define PROGRESS_CRACKING 			( 0 )
#define PROGRESS_BRUTEFORCE 		( 1 )

/* ** Variables ** */
static stock
	p_PawnStoreExport				[ MAX_PLAYERS ] = { -1, ... },
	p_PawnStoreMapIcon 				[ MAX_PLAYERS ] = { -1, ... }
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	DestroyDynamicRaceCP( p_PawnStoreExport[ playerid ] );
	p_PawnStoreExport[ playerid ] = -1;
	DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
	p_PawnStoreMapIcon[ playerid ] = -1;
	return 1;
}

hook OnPlayerDriveVehicle( playerid, vehicleid )
{
	new
		model = GetVehicleModel( GetPlayerVehicleID( playerid ) );

	if ( model == 498 && p_Class[ playerid ] != CLASS_POLICE )
	{
		new num_furniture = GetGVarInt( sprintf( "vburg_%d_items", vehicleid ) );
		new cash_value = GetGVarInt( sprintf( "vburg_%d_cash", vehicleid ) );

		if ( num_furniture > 0 )
		{
			new
				Float: X, Float: Y, Float: Z,
				Float: pX, Float: pY, Float: pZ;

			GetPlayerPos( playerid, pX, pY, pZ );

			Beep( playerid );
			GameTextForPlayer( playerid, "Go to the truck blip on your radar for money!", 3000, 1 );
			SendServerMessage( playerid, "You have %d stolen goods that you can export for "COL_GOLD"%s"COL_WHITE"!", num_furniture, cash_format( cash_value ) );

			static
				szCity[ MAX_ZONE_NAME ],
				aPlayer[ 1 ];

			aPlayer[ 0 ] = playerid;
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );

			Get2DCity( szCity, pX, pY, pZ );

			if ( strmatch( szCity, "Los Santos" ) ) {
				X = 2522.1677, Y = -1717.4137, Z = 13.6086;
			}
			else if ( strmatch( szCity, "Las Venturas" ) ) {
				X = 2481.6812, Y = 1315.8477, Z = 10.6797;
			}
			else { // default SF if not LV and LS
				X = -2480.2461, Y = 6.0720, Z = 25.6172;
			}

			p_PawnStoreMapIcon[ playerid ] = CreateDynamicMapIconEx( X, Y, Z, 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
			p_PawnStoreExport[ playerid ] = CreateDynamicRaceCP( 1, X, Y, Z, 0.0, 0.0, 0.0, 4.0, -1, -1, playerid );
		}
	}
	return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate )
{
    if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER ) // Driver has a new state?
    {
		if ( p_PawnStoreExport[ playerid ] != -1 )
		{
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = -1;
			DestroyDynamicRaceCP( p_PawnStoreExport[ playerid ] );
			p_PawnStoreExport[ playerid ] = -1;
		}
    }
	return 1;
}

hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;

	if ( checkpointid == p_PawnStoreExport[ playerid ] )
	{
	    new vehicleid = GetPlayerVehicleID( playerid );
	    if ( GetVehicleModel( vehicleid ) == 498 )
	    {
		    new cash_earned = GetGVarInt( sprintf( "vburg_%d_cash", vehicleid ) );
			new num_furniture = GetGVarInt( sprintf( "vburg_%d_items", vehicleid ) );
			new score = floatround( num_furniture / 2 );

			GivePlayerScore( playerid, score == 0 ? 1 : score );
			//GivePlayerExperience( playerid, E_BURGLAR, float( num_furniture ) * 0.2 );
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = -1;
			DestroyDynamicRaceCP( p_PawnStoreExport[ playerid ] );
			p_PawnStoreExport[ playerid ] = -1;
			GivePlayerCash( playerid, cash_earned );
			StockMarket_UpdateEarnings( E_STOCK_PAWN_STORE, cash_earned, 1.0 );
			GivePlayerWantedLevel( playerid, num_furniture * 2 );
			SendServerMessage( playerid, "You have sold %d furniture item(s) to the Pawn Store, earning you "COL_GOLD"%s"COL_WHITE".", num_furniture, cash_format( cash_earned ) );
			ResetVehicleBurglaryData( vehicleid );
		}
	}
	return 1;
}

hook OnPlayerProgressUpdate( playerid, progressid, bool: canceled, params )
{
	if ( progressid == PROGRESS_CRACKING || progressid == PROGRESS_BRUTEFORCE ) {
        if ( !IsPlayerSpawned( playerid ) || !IsPlayerInDynamicCP( playerid, g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CHECKPOINT ] [ 0 ] ) || !IsPlayerConnected( playerid ) || IsPlayerInAnyVehicle( playerid ) || canceled ) {
        	return g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_BEING_CRACKED ] = false, StopProgressBar( playerid ), 1;
        }
	}
	return 1;
}

hook OnProgressCompleted( playerid, progressid, params )
{
	if ( progressid == PROGRESS_CRACKING )
	{
	   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_BEING_CRACKED ] = false;
		g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_WAIT ] = g_iTime + 300;

		if ( random( 101 ) < 75 )
		{
			g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED ] = true;
		   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_TS ] = g_iTime + 120;
			SendServerMessage( playerid, "You have successfully cracked this houses' password. You have two minutes to do your thing." );
			GivePlayerWantedLevel( playerid, 12 );
			GivePlayerScore( playerid, 2 );
			//GivePlayerExperience( playerid, E_BURGLAR );
			ach_HandleBurglaries( playerid );
		}
		else
		{
			new szLocation[ MAX_ZONE_NAME ];
			GetZoneFromCoordinates( szLocation, g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_EX ], g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_EY ], g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_EZ ] );
			SendClientMessageToCops( -1, ""COL_BLUE"[BURGLARY]"COL_WHITE" %s has failed to crack a houses' password near %s.", ReturnPlayerName( playerid ), szLocation );
			SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have failed to crack this houses' password." );
			GivePlayerWantedLevel( playerid, 6 );
			CreateCrimeReport( playerid );
		}
	}
	else if ( progressid == PROGRESS_BRUTEFORCE )
	{
	   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_BEING_CRACKED ] = false;
		g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_WAIT ] = g_iTime + 30;

        if ( random( 101 ) < 75  )
        {
			g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED ] = true;
		   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_TS ] = g_iTime + 60;
			SendServerMessage( playerid, "You have successfully brute forced this houses' password. This lasts for one minute." );
        }
        else SendServerMessage( playerid, "You have failed to brute force this houses' password." );
	}
	return 1;
}

hook OnPlayerEnterHouse( playerid, houseid )
{
	// alert burglar of any furniture
	if ( ! IsPlayerHomeOwner( playerid, houseid ) && IsPlayerJob( playerid, JOB_BURGLAR ) && GetPlayerClass( playerid ) == CLASS_CIVILIAN ) {
		if ( Iter_Count( housefurniture[ houseid ] ) ) {
			ShowPlayerHelpDialog( playerid, 4000, "This house has furniture to rob.~n~~n~Press ~g~~h~~k~~VEHICLE_ENTER_EXIT~~w~ near the furniture you want to steal." );
		} else {
			ShowPlayerHelpDialog( playerid, 4000, "~r~This house has no furniture to rob." );
		}
	}
	return 1;
}

hook OnPlayerAttemptBreakIn( playerid, houseid, businessid )
{
	new is_fbi = GetPlayerClass( playerid ) == CLASS_POLICE && p_inFBI{ playerid } && ! p_inArmy{ playerid } && ! p_inCIA{ playerid };
	new is_burglar = GetPlayerClass( playerid ) == CLASS_CIVILIAN && IsPlayerJob( playerid, JOB_BURGLAR );

	// prohibit non-cop,
	if ( ! ( ! is_fbi && is_burglar || ! is_burglar && is_fbi ) )
		return 0;

	if ( IsValidHouse( houseid ) )
	{
		new current_time = GetServerTime( );
		new crackpw_cooldown = GetPVarInt( playerid, "crack_housepw_cool" );

		if ( crackpw_cooldown > current_time ) {
			return SendError( playerid, "You are unable to attempt a house break-in for %d seconds.", crackpw_cooldown - current_time ), 0;
		}

		if ( current_time > g_houseData[ houseid ] [ E_CRACKED_TS ] && g_houseData[ houseid ] [ E_CRACKED ] )
			g_houseData[ houseid ] [ E_CRACKED ] = false; // The Virus Is Disabled.

		if ( g_houseData[ houseid ] [ E_CRACKED_WAIT ] > current_time )
		    return SendError( playerid, "This house had its password recently had a cracker run through. Come back later." ), 0;

		if ( g_houseData[ houseid ] [ E_CRACKED ] || g_houseData[ houseid ] [ E_BEING_CRACKED ] )
			return SendError( playerid, "This house is currently being cracked or is already cracked." ), 0;

        if ( IsHouseOnFire( houseid ) )
	       	return SendError( playerid, "This house is on fire, you cannot crack it!" ), 0;

        g_houseData[ houseid ] [ E_BEING_CRACKED ] = true;
        p_HouseCrackingPW[ playerid ] = houseid;
        SetPVarInt( playerid, "crack_housepw_cool", current_time + 40 );

		if ( is_fbi ) {
			ShowProgressBar( playerid, "Brute Forcing Password", PROGRESS_BRUTEFORCE, 5000, COLOR_BLUE );
		} else {
			ShowProgressBar( playerid, "Cracking Password", PROGRESS_CRACKING, 7500, COLOR_WHITE );
		}
		return 1;
	}
	return 1;
}

hook OnVehicleCreated( vehicleid, model_id )
{
	if ( model_id == 498 )
	{
		new
			attachable_area = CreateDynamicSphere( 0.0, 0.0, 0.0, 2.5 );

		AttachDynamicAreaToVehicle( attachable_area, vehicleid, 0.0, -4.0, 0.0 );
		SetGVarInt( "burglar_boxville_area", vehicleid, attachable_area );
		SetGVarInt( "burglar_boxville_veh", attachable_area, vehicleid );
	}
	return 1;
}

hook OnVehicleDestroyed( vehicleid )
{
	if ( GetGVarType( "burglar_boxville_veh", vehicleid ) != GLOBAL_VARTYPE_NONE ) // destroy mining area
	{
		new
			areaid = GetGVarInt( "burglar_boxville_veh", vehicleid );

		DestroyDynamicArea( areaid );
		DeleteGVar( "burglar_boxville_veh", vehicleid );
		DeleteGVar( "burglar_boxville_area", vehicleid );
	}
	return 1;
}

hook OnVehicleSpawn( vehicleid )
{
	ResetVehicleBurglaryData( vehicleid );
	return 1;
}

hook OnPlayerEnterDynArea( playerid, areaid )
{
    // mining dunes
	if ( GetGVarType( "burglar_boxville_area", areaid ) != GLOBAL_VARTYPE_NONE )
	{
		new attached_vehicle = GetGVarInt( "burglar_boxville_area", areaid );
		new attached_model = GetVehicleModel( attached_vehicle );

		if ( attached_model == 498 )
		{
			if ( GetPVarType( playerid, "stolen_fid" ) == PLAYER_VARTYPE_NONE ) {
				return 1; // return SendError( playerid, "You aren't holding anything!" );
			}

			new stolen_furniture_count = GetGVarInt( sprintf( "vburg_%d_items", attached_vehicle ) );

			if ( stolen_furniture_count >= MAX_BURGLARY_SLOTS ) {
				return SendError( playerid, "You can only carry %d items in this vehicle.", MAX_BURGLARY_SLOTS );
			}

			static
				Float: angle;

			GetVehicleZAngle( attached_vehicle, angle );

			new stolen_furniture_id = GetPVarInt( playerid, "stolen_fid" );
			new stolen_furniture_value = floatround( float( g_houseFurniture[ stolen_furniture_id ] [ E_COST ] ) * 0.5 );
			new stolen_cash_accumulative = GetGVarInt( sprintf( "vburg_%d_cash", attached_vehicle ) );

			SetGVarInt( sprintf( "vburg_%d_items", attached_vehicle ), stolen_furniture_count + 1 );
			SetGVarInt( sprintf( "vburg_%d_cash", attached_vehicle ), stolen_cash_accumulative + stolen_furniture_value );

			RemovePlayerAttachedObject( playerid, 3 );
			ClearAnimations( playerid );
			SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );

			SetPlayerFacingAngle( playerid, angle );
			SendServerMessage( playerid, "You have placed a "COL_GREY"%s"COL_WHITE" in this Boxville. "COL_ORANGE"[%d/%d]", g_houseFurniture[ stolen_furniture_id ] [ E_NAME ], stolen_furniture_count + 1, MAX_BURGLARY_SLOTS );

			ApplyAnimation( playerid, "CARRY", "putdwn105", 4.0, 0, 0, 0, 0, 0 );
			DeletePVar( playerid, "stolen_fid" );
			return 1;
		}
	}
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_SECONDARY_ATTACK ) && IsPlayerJob( playerid, JOB_BURGLAR ) && GetPlayerClass( playerid ) == CLASS_CIVILIAN )
	{
		new
			houseid = GetPlayerEnteredHouse( playerid );

		if ( IsValidHouse( houseid ) && ! IsPlayerHomeOwner( playerid, houseid ) )
		{
		    new Float: distance = 99999.99, furniture_slot = ITER_NONE;
			new objectid = GetClosestFurniture( houseid, playerid, distance, furniture_slot );
			new modelid = Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID );
			new furniture_id = getFurnitureID( modelid );

	    	if ( objectid == INVALID_OBJECT_ID || furniture_slot == ITER_NONE )
	    		return SendError( playerid, "No furniture is in this house." );

			if ( distance > 3.0 )
				return SendError( playerid, "You are not close to any furniture." );

			if ( g_houseFurniture[ furniture_id ] [ E_CATEGORY ] != FC_ELECTRONIC && g_houseFurniture[ furniture_id ] [ E_CATEGORY ] != FC_WEAPONS )
				return ShowPlayerHelpDialog( playerid, 3000, "The furniture you're near is not an electronic or weapon." );

			if ( IsPlayerAttachedObjectSlotUsed( playerid, 3 ) )
				return ShowPlayerHelpDialog( playerid, 3000, "Your hands are busy at the moment." );

			if ( IsPointToPoint( 150.0, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ], g_houseData[ houseid ] [ E_EZ ], -2480.1426, 5.5302, 25.6172 ) )
				return ShowPlayerHelpDialog( playerid, 3000, "~r~This house is protected from burglaries." );

			new Float: playerZ, Float: furnitureZ;
			GetPlayerPos( playerid, playerZ, playerZ, playerZ );
			GetDynamicObjectPos( objectid, furnitureZ, furnitureZ, furnitureZ );

			// apply animation
	    	if ( playerZ - furnitureZ <= 0.0 ) ApplyAnimation( playerid, "CARRY", "liftup105", 4.0, 0, 0, 0, 0, 0 );
	    	else if ( playerZ - furnitureZ <= 0.45 ) ApplyAnimation( playerid, "CARRY", "liftup05", 4.0, 0, 0, 0, 0, 0 );
	    	else ApplyAnimation( playerid, "CARRY", "liftup", 4.0, 0, 0, 0, 0, 0 );

			// Alert
			SendServerMessage( playerid, "You have stolen a "COL_GREY"%s"COL_WHITE". Store it in a Boxville to transport the item.", g_houseFurniture[ furniture_id ] [ E_NAME ] );
			SetPlayerSpecialAction( playerid, SPECIAL_ACTION_CARRY );
			SetPVarInt( playerid, "stolen_fid", furniture_id );
			SetPlayerAttachedObject( playerid, 3, 1220, 5, 0.043999, 0.222999, 0.207000, 14.400002, 15.799994, 0.000000, 0.572999, 0.662000, 0.665000 );
		}

	}
	return 1;
}

/* ** Functions ** */
stock ResetVehicleBurglaryData( vehicleid )
{
    DeleteGVar( sprintf( "vburg_%d_cash", vehicleid ) );
    DeleteGVar( sprintf( "vburg_%d_items", vehicleid ) );
	return 1;
}

stock RemovePlayerStolensFromHands( playerid )
{
	DeletePVar( playerid, "stolen_fid" );
	RemovePlayerAttachedObject( playerid, 3 );
	SetPlayerSpecialAction( playerid, 0 );
	return 1;
}
