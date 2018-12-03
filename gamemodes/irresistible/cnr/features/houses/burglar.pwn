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
#define MAX_BURGLARY_SLOTS          8

#define PROGRESS_CRACKING 			0
#define PROGRESS_BRUTEFORCE 		1

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
		format( szSmallString, sizeof( szSmallString ), "vburg_%d_items", vehicleid );
		if ( GetGVarInt( szSmallString ) > 0 )
		{
			new
				Float: X, Float: Y, Float: Z,
				Float: pX, Float: pY, Float: pZ;

			GetPlayerPos( playerid, pX, pY, pZ );

			Beep( playerid );
			GameTextForPlayer( playerid, "Go to the truck blip on your radar for money!", 3000, 1 );
			SendServerMessage( playerid, "Note! You have %d stolen goods that you can export for money!", GetGVarInt( szSmallString ) );

			static
				szCity[ MAX_ZONE_NAME ],
				aPlayer[ 1 ];

			aPlayer[ 0 ] = playerid;
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );

			Get2DCity( szCity, pX, pY, pZ );

			if ( strmatch( szCity, "Los Santos" ) )
			{
				X = 2522.1677;
				Y = -1717.4137;
				Z = 13.6086;
			}
			else if ( strmatch( szCity, "Las Venturas" ) )
			{
				X = 2481.6812;
				Y = 1315.8477;
				Z = 10.6797;
			}
			else // default SF if not LV and LS
			{
				X = -2480.2461;
				Y = 6.0720;
				Z = 25.6172;
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
		if ( p_PawnStoreExport[ playerid ] != 0xFFFF )
		{
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = 0xFFFF;
			DestroyDynamicRaceCP( p_PawnStoreExport[ playerid ] );
			p_PawnStoreExport[ playerid ] = 0xFFFF;
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
		    new
				szItems[ 18 ],
				cashEarned,
				items, score
			;
			format( szItems, sizeof( szItems ), "vburg_%d_items", vehicleid );
			for( new i; i < GetGVarInt( szItems ) + 1; i++ )
			{
				format( szSmallString, sizeof( szSmallString ), "vburg_%d_%d", vehicleid, i );
				if ( GetGVarInt( szSmallString ) != 0 )
				{
				    cashEarned += floatround( float( g_houseFurniture[ GetGVarInt( szSmallString ) ] [ E_COST ] ) * 0.5 );
				    DeleteGVar( szSmallString );
				}
			}
			items = GetGVarInt( szItems );
			score = floatround( items / 2 );
			GivePlayerScore( playerid, score == 0 ? 1 : score );
			//GivePlayerExperience( playerid, E_BURGLAR, float( items ) * 0.2 );
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = 0xFFFF;
			DestroyDynamicRaceCP( p_PawnStoreExport[ playerid ] );
			p_PawnStoreExport[ playerid ] = 0xFFFF;
			GivePlayerCash( playerid, cashEarned );
			StockMarket_UpdateEarnings( E_STOCK_PAWN_STORE, cashEarned, 1.0 );
			GivePlayerWantedLevel( playerid, items * 2 );
			SendServerMessage( playerid, "You have sold %d furniture item(s) to the Pawn Store, earning you "COL_GOLD"%s"COL_WHITE".", GetGVarInt( szItems ), cash_format( cashEarned ) );
			DeleteGVar( szItems );
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
			if ( ! IsPlayerAttachedObjectSlotUsed( playerid, 3 ) ) {
				return SendError( playerid, "You aren't holding anything!" );
			}

			format( szSmallString, sizeof( szSmallString ), "vburg_%d_items", attached_vehicle );

			if ( GetGVarInt( szSmallString ) >= MAX_BURGLARY_SLOTS ) {
				return SendError( playerid, "You can only carry %d items in this vehicle.", MAX_BURGLARY_SLOTS );
			}

			new
				Float: angle;

			GetVehicleZAngle( attached_vehicle, angle );

			SetGVarInt( szSmallString, GetGVarInt( szSmallString ) + 1 );
			SetGVarInt( sprintf( "vburg_%d_%d", attached_vehicle, GetGVarInt( szSmallString ) ), GetPVarInt( playerid, "stolen_fid" ) );

			RemovePlayerAttachedObject( playerid, 3 );
			ClearAnimations( playerid );
			SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
			DeletePVar( playerid, "stolen_fid" );

			SetPlayerFacingAngle( playerid, angle );
			SendServerMessage( playerid, "You have placed a "COL_GREY"%s"COL_WHITE" in this Boxville. "COL_ORANGE"[%d/%d]", g_houseFurniture[ GetPVarInt( playerid, "stolen_fid" ) ] [ E_NAME ], GetGVarInt( szSmallString ), MAX_BURGLARY_SLOTS );
			ApplyAnimation( playerid, "CARRY", "putdwn105", 4.0, 0, 0, 0, 0, 0 );
			return 1;
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:burglar( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You are not a civilian." );
	if ( !IsPlayerJob( playerid, JOB_BURGLAR ) ) return SendError( playerid, "You are not a burglar." );

	if ( isnull( params ) ) return SendUsage( playerid, "/burglar [CRACKPW/STEAL/STORE]" );
	else if ( strmatch( params, "crackpw" ) )
	{
		if ( GetPVarInt( playerid, "crackpw_cool" ) > g_iTime ) return SendError( playerid, "You must wait 40 seconds before using this command again." );

		// businesses
		/*foreach ( new handle : business )
		{
			if ( IsPlayerInDynamicCP( playerid, g_businessData[ handle ] [ E_ENTER_CP ] ) )
			{
				if ( g_iTime > g_businessData[ handle ] [ E_CRACKED_TS ] && g_businessData[ handle ] [ E_CRACKED ] ) g_businessData[ handle ] [ E_CRACKED ] = false; // The Virus Is Disabled.

				if ( IsBusinessAssociate( playerid, handle ) )
					return SendError( playerid, "You are an associate of this business, you cannot crack it." );

				if ( g_businessData[ handle ] [ E_CRACKED_WAIT ] > g_iTime )
				    return SendError( playerid, "This house had its password recently had a cracker run through. Come back later." );

				if ( g_businessData[ handle ] [ E_CRACKED ] || g_businessData[ handle ] [ E_BEING_CRACKED ] )
				    return SendError( playerid, "This house is currently being cracked or is already cracked." );

				// alert
				foreach ( new ownerid : Player ) if ( IsBusinessAssociate( ownerid, handle ) ) {
					SendClientMessageFormatted( ownerid, -1, ""COL_RED"[BURGLARY]"COL_WHITE" %s(%d) is attempting to break into your business %s"COL_WHITE"!", ReturnPlayerName( playerid ), playerid, g_businessData[ handle ] [ E_NAME ] );
				}

				// crack pw
                g_businessData[ handle ] [ E_BEING_CRACKED ] = true;
                SetPVarInt( playerid, "crackpw_biz", handle );
                SetPVarInt( playerid, "crackpw_cool", g_iTime + 40 );
				ShowProgressBar( playerid, "Cracking Password", PROGRESS_CRACKING_BIZ, 7500, COLOR_WHITE );
	            return 1;
			}
		}*/

		// houses
		foreach ( new i : houses )
		{
			if ( IsPlayerInDynamicCP( playerid, g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] ) && !strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
				if ( g_iTime > g_houseData[ i ] [ E_CRACKED_TS ] && g_houseData[ i ] [ E_CRACKED ] ) g_houseData[ i ] [ E_CRACKED ] = false; // The Virus Is Disabled.

				if ( g_houseData[ i ] [ E_CRACKED_WAIT ] > g_iTime )
				    return SendError( playerid, "This house had its password recently had a cracker run through. Come back later." );

				if ( strmatch( g_houseData[ i ] [ E_PASSWORD ], "N/A" ) )
				    return SendError( playerid, "This house does not require cracking as it doesn't have a password." );

				if ( g_houseData[ i ] [ E_CRACKED ] || g_houseData[ i ] [ E_BEING_CRACKED ] )
				    return SendError( playerid, "This house is currently being cracked or is already cracked." );

		        if ( IsHouseOnFire( i ) )
			       	return SendError( playerid, "This house is on fire, you cannot crack it!" ), 1;

                g_houseData[ i ] [ E_BEING_CRACKED ] = true;
                p_HouseCrackingPW[ playerid ] = i;
                SetPVarInt( playerid, "crackpw_cool", g_iTime + 40 );
				ShowProgressBar( playerid, "Cracking Password", PROGRESS_CRACKING, 7500, COLOR_WHITE );
	            return 1;
			}
		}

		// businesses
		SendError( playerid, "You are not standing in any house or business checkpoint." );
	}
	else if ( strmatch( params, "steal" ) )
	{
		new houseid = p_InHouse[ playerid ];

	    if ( houseid == -1 )
	    	return SendError( playerid, "You're not inside any house." );

    	if ( IsPlayerHomeOwner( playerid, houseid ) )
    		return SendError( playerid, "You can't steal a piece of furniture from your house!" );

	    new Float: distance = 99999.99, furniture_slot = ITER_NONE;
		new objectid = GetClosestFurniture( houseid, playerid, distance, furniture_slot );
		new modelid = Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID );
		new furniture_id = getFurnitureID( modelid );

    	if ( objectid == INVALID_OBJECT_ID || furniture_slot == ITER_NONE )
    		return SendError( playerid, "No furniture is in this house." );

		if ( distance > 3.0 )
			return SendError( playerid, "You are not close to any furniture." );

		if ( g_houseFurniture[ furniture_id ] [ E_CATEGORY ] != FC_ELECTRONIC && g_houseFurniture[ furniture_id ] [ E_CATEGORY ] != FC_WEAPONS )
			return SendError( playerid, "The furniture you're near is not an electronic." );

		if ( IsPlayerAttachedObjectSlotUsed( playerid, 3 ) )
			return SendError( playerid, "Your hands are busy at the moment." );

		if ( IsPointToPoint( 150.0, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ], g_houseData[ houseid ] [ E_EZ ], -2480.1426, 5.5302, 25.6172 ) )
			return SendError( playerid, "This house is prohibited from burglarly features as it is too close to the Pawn Store." );

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
	else SendUsage( playerid, "/burglar [CRACKPW/STEAL]" );
	return 1;
}

CMD:bruteforce( playerid, params[ ] )
{
	/* ** ANTI SPAM ** */
    if ( GetPVarInt( playerid, "last_bruteforce" ) > g_iTime ) return SendError( playerid, "You must wait 30 seconds before using this command again." );
    /* ** END OF ANTI SPAM ** */

	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This command is restricted for F.B.I agents." );
	if ( !( p_inFBI{ playerid } == true && p_inArmy{ playerid } == false && p_inCIA{ playerid } == false ) ) return SendError( playerid, "This command is restricted for F.B.I agents." );

	foreach ( new i : houses )
	{
		if ( IsPlayerInDynamicCP( playerid, g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] ) && !strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
		{
			if ( g_iTime > g_houseData[ i ] [ E_CRACKED_TS ] && g_houseData[ i ] [ E_CRACKED ] ) g_houseData[ i ] [ E_CRACKED ] = false; // The Virus Is Disabled.

			if ( g_houseData[ i ] [ E_CRACKED_WAIT ] > g_iTime )
			    return SendError( playerid, "This house had its password recently had a cracker run through. Come back later." );

			if ( strmatch( g_houseData[ i ] [ E_PASSWORD ], "N/A" ) )
			    return SendError( playerid, "This house does not require cracking as it doesn't have a password." );

			if ( g_houseData[ i ] [ E_CRACKED ] || g_houseData[ i ] [ E_BEING_CRACKED ] )
			    return SendError( playerid, "This house is currently being cracked or is already cracked." );

	        if ( IsHouseOnFire( i ) )
		       	return SendError( playerid, "This house is on fire, you cannot bruteforce it!" ), 1;

            g_houseData[ i ] [ E_BEING_CRACKED ] = true;
            p_HouseCrackingPW[ playerid ] = i;
            SetPVarInt( playerid, "last_bruteforce", g_iTime + 30 );
			ShowProgressBar( playerid, "Brute Forcing Password", PROGRESS_BRUTEFORCE, 5000, COLOR_BLUE );
            return 1;
		}
	}
	SendError( playerid, "You are not standing in any house checkpoint." );
	return 1;
}

stock ResetVehicleBurglaryData( vehicleid )
{
    if ( GetVehicleModel( vehicleid ) != 498 )
        return 0;

	new szString[ 18 ];

	for( new i; i < MAX_BURGLARY_SLOTS; i++ ) {
		format( szString, sizeof( szString ), "vburg_%d_%d", vehicleid, i ), DeleteGVar( szString );
	}

    format( szString, sizeof( szString ), "vburg_%d_items", vehicleid );
    DeleteGVar( szString );
	return 1;
}

stock RemovePlayerStolensFromHands( playerid )
{
	DeletePVar( playerid, "stolen_fid" );
	RemovePlayerAttachedObject( playerid, 3 );
	SetPlayerSpecialAction( playerid, 0 );
	return 1;
}
