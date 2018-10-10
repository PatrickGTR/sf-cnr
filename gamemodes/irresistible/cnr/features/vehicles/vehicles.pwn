/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\vehicles\vehicles.pwn
 * Purpose: personal vehicle system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_BUYABLE_VEHICLES        ( 20 + VIP_MAX_EXTRA_SLOTS )
#define MAX_CAR_MODS                15

/* ** Variables ** */
enum E_CAR_DATA
{
	E_VEHICLE_ID,       bool: E_CREATED,        	bool: E_LOCKED,
	Float: E_X,         Float: E_Y,             	Float: E_Z,
	Float: E_ANGLE,     E_OWNER_ID,            		E_PRICE,
	E_COLOR[ 2 ],       E_MODEL,                    E_PLATE[ 32 ],
	E_PAINTJOB,			E_SQL_ID,					E_GARAGE
};

new
	g_vehicleData                	[ MAX_PLAYERS ] [ MAX_BUYABLE_VEHICLES ] [ E_CAR_DATA ],
	bool: g_buyableVehicle        	[ MAX_VEHICLES char ],
	g_vehicleModifications          [ MAX_PLAYERS ] [ MAX_BUYABLE_VEHICLES ] [ MAX_CAR_MODS ]
;

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VEHICLE_SPAWN && response )
	{
		if ( !listitem )
		{
			for( new id; id < MAX_BUYABLE_VEHICLES; id ++ )
				if ( g_vehicleData[ playerid ] [ id ] [ E_CREATED ] && g_vehicleData[ playerid ] [ id ] [ E_OWNER_ID ] == p_AccountID[ playerid ] && IsValidVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ) )
			 		RespawnBuyableVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] );

			SendServerMessage( playerid, "You have respawned all your vehicles." );
		}
		else
		{
			for( new id, x = 1; id < MAX_BUYABLE_VEHICLES; id ++ )
			{
				if ( g_vehicleData[ playerid ] [ id ] [ E_CREATED ] && g_vehicleData[ playerid ] [ id ] [ E_OWNER_ID ] == p_AccountID[ playerid ] && IsValidVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ) )
				{
			       	if ( x == listitem )
			      	{
						RespawnBuyableVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] );
						SendServerMessage( playerid, "You have respawned your "COL_GREY"%s"COL_WHITE".", GetVehicleName( GetVehicleModel( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ) ) );
					 	break;
			   		}
			      	x ++;
				}
			}
		}
	}
	else if ( dialogid == DIALOG_VEHICLE_LOCATE && response )
	{
		if ( GetPlayerInterior( playerid ) || GetPlayerVirtualWorld( playerid ) )
			return SendError( playerid, "You cannot use this feature inside of an interior." );

		for( new id, x = 0; id < MAX_BUYABLE_VEHICLES; id ++ )
		{
			if ( g_vehicleData[ playerid ] [ id ] [ E_CREATED ] == true && g_vehicleData[ playerid ] [ id ] [ E_OWNER_ID ] == p_AccountID[ playerid ] && IsValidVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ) )
			{
		       	if ( x == listitem )
		      	{
		      		if ( GetPlayerCash( playerid ) < 10000 )
		      			return SendError( playerid, "You need $10,000 to bring your vehicle to you." );

				    new
					    Float: X, Float: Y, Float: Z;

		      		foreach( new i : Player )
		      		{
		      			if( GetPlayerVehicleID( i ) == g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] )
		      			{
		      				GetPlayerPos( i, X, Y, Z );
		      				SetPlayerPos( i, X, Y, ( Z + 0.5 ) );
		      				SendServerMessage( i, "You have been thrown out of the vehicle as the owner has teleported it away!" );
		      			}
		      		}

					// get the player's position again
					GetPlayerPos( playerid, X, Y, Z );

					// get nearest node
					new Float: nodeX, Float: nodeY, Float: nodeZ, Float: nextX, Float: nextY;
					new nodeid = NearestNodeFromPoint( X, Y, Z );
					new nextNodeid = NearestNodeFromPoint( X, Y, Z, 9999.9, nodeid );

					GetNodePos( nextNodeid, nextX, nextY, nodeZ );
					GetNodePos( nodeid, nodeX, nodeY, nodeZ );

					new
						Float: rotation = atan2( nextY - nodeY, nextX - nodeX ) - 90.0;

					SetVehiclePos( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], nodeX, nodeY, nodeZ + 1.0 );
					SetVehicleZAngle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], rotation );
					LinkVehicleToInterior( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], 0 );
					SetVehicleVirtualWorld( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], 0 );

					// alert
					Beep( playerid );
					GivePlayerCash( playerid, -10000 );
					p_VehicleBringCooldown[ playerid ] = g_iTime + 120;
					SendServerMessage( playerid, "You have brought your "COL_GREY"%s"COL_WHITE". Check the nearest road for it.", GetVehicleName( GetVehicleModel( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ) ) );
					break;
		   		}
		      	x ++;
			}
		}
	}
	return 1;
}

hook OnPlayerDriveVehicle( playerid, vehicleid )
{
	if ( g_buyableVehicle{ vehicleid } == true )
	{
		new ownerid, slotid;
		new v = getVehicleSlotFromID( vehicleid, ownerid, slotid );

		if ( v == -1 ) {
			return 1; // ignore if unowned/erroneous
		}

		if ( ownerid == playerid )
		{
			SendClientMessage(playerid, -1, ""COL_GREY"[VEHICLE]"COL_WHITE" Welcome back to your vehicle.");
			Beep( playerid );
			GetVehicleParamsEx( vehicleid, engine, lights, alarm, doors, bonnet, boot, objective );
			SetVehicleParamsEx( vehicleid, VEHICLE_PARAMS_ON, lights, VEHICLE_PARAMS_OFF, doors, bonnet, boot, objective );
			return 1;
		}
        else
	    {
			if ( g_vehicleData[ ownerid ] [ slotid ] [ E_LOCKED ] == true )
			{
				if ( p_AdminLevel[ playerid ] < 3 || !p_AdminOnDuty{ playerid } )
				{
					new
						model_id = GetVehicleModel( vehicleid );

					GetVehicleParamsEx( vehicleid, engine, lights, alarm, doors, bonnet, boot, objective );
					SetVehicleParamsEx( vehicleid, VEHICLE_PARAMS_ON, lights, VEHICLE_PARAMS_ON, doors, bonnet, boot, objective );

					// Remove helicopter bottoms
					if ( GetGVarInt( "heli_gunner", vehicleid ) && ( model_id == 487 || model_id == 497 ) ) {
						DestroyDynamicObject( GetGVarInt( "heli_gunner", vehicleid ) );
						DeleteGVar( "heli_gunner", vehicleid );
					}

					SyncObject( playerid, 1 ); // Just sets the players position where the vehicle is.
					SendError( playerid, "You cannot drive this car, it has been locked by the owner." );
				}
				else SendClientMessage( playerid, -1, ""COL_PINK"[ADMIN]"COL_GREY" This is a locked vehicle." );
			}
			else SendClientMessageFormatted( playerid, -1, ""COL_GREY"[VEHICLE]"COL_WHITE" This vehicle is owned by %s.", ReturnPlayerName( ownerid ) );
		}
	}
	return 1;
}

hook OnEnterExitModShop( playerid, enterexit, interiorid )
{
	if ( enterexit == 0 )
	{
		new
		    vehicleid = GetPlayerVehicleID( playerid );

	    if ( IsValidVehicle( vehicleid ) )
	    {
			if ( g_buyableVehicle{ vehicleid } == true )
			{
		        new
		        	ownerid = INVALID_PLAYER_ID,
		        	v = getVehicleSlotFromID( vehicleid, ownerid )
		        ;
			    if ( ownerid == playerid && v != -1 )
			    {
			        if ( UpdateBuyableVehicleMods( playerid, v ) )
			        {
			        	new
				        	szMods[ MAX_CAR_MODS * 10 ];

						for( new i; i < MAX_CAR_MODS; i++ ) {
							format( szMods, sizeof( szMods ), "%s%d.", szMods, g_vehicleModifications[ playerid ] [ v ] [ i ] );
						}

						format( szBigString, sizeof( szBigString ), "UPDATE `VEHICLES` SET `MODS`='%s' WHERE `ID`=%d", szMods, g_vehicleData[ playerid ] [ v ] [ E_SQL_ID ] );
						mysql_single_query( szBigString );
			        }
			        else SendError( playerid, "Couldn't update your vehicle mods due to an unexpected error (0x82FF)." );
			    }
			}
		}
	}
	return 1;
}

hook OnVehiclePaintjob( playerid, vehicleid, paintjobid )
{
	if ( g_buyableVehicle{ vehicleid } == true )
	{
	    new
	    	ownerid = INVALID_PLAYER_ID,
	    	v = getVehicleSlotFromID( vehicleid, ownerid )
	    ;
	    if ( ownerid == playerid && v != -1 )
	    {
	        g_vehicleData[ playerid ] [ v ] [ E_PAINTJOB ] = paintjobid;
	        SaveVehicleData( playerid, v );
	    }
	}
	return 1;
}

hook OnVehicleRespray( playerid, vehicleid, color1, color2 )
{
    if ( g_buyableVehicle{ vehicleid } == true )
    {
	    new
	    	ownerid = INVALID_PLAYER_ID,
	    	v = getVehicleSlotFromID( vehicleid, ownerid )
	    ;
	    if ( ownerid == playerid && v != -1 )
		{
			g_vehicleData[ playerid ] [ v ] [ E_COLOR ] [ 0 ] = color1;
	        g_vehicleData[ playerid ] [ v ] [ E_COLOR ] [ 1 ] = color2;
	        SaveVehicleData( playerid, v );
		}
    }
	return 1;
}

/* ** Commands ** */
CMD:vehicle( playerid, params[ ] ) return cmd_v( playerid, params );
CMD:v( playerid, params[ ] )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

#if VIP_ALLOW_OVER_LIMIT == false
	// force hoarders to sell
	if ( ! p_VIPLevel[ playerid ] && p_OwnedVehicles[ playerid ] > GetPlayerVehicleSlots( playerid ) && ! strmatch( params, "sell" ) && ! strmatch( params, "bring" ) ) {
		for( new i = 0; i < p_OwnedVehicles[ playerid ]; i++ ) if ( g_vehicleData[ playerid ] [ i ] [ E_OWNER_ID ] == p_AccountID[ playerid ] ) {
			g_vehicleData[ playerid ] [ i ] [ E_LOCKED ] = false;
		}
		return SendError( playerid, "Please renew your V.I.P or sell this vehicle to match your vehicle allocated limit. (/v sell/bring only)" );
	}
#endif

	new
		vehicleid = GetPlayerVehicleID( playerid ),
		ownerid = INVALID_PLAYER_ID
	;

	if ( isnull( params ) ) return SendUsage( playerid, "/v [SELL/COLOR/LOCK/PARK/RESPAWN/BRING/DATA/PLATE/PAINTJOB/RESET]" );
	else if ( strmatch( params, "sell" ) )
	{
		new v = getVehicleSlotFromID( vehicleid, ownerid );
	    if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You need to be in a vehicle to use this command." );
		else if ( v == -1 ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else if ( g_buyableVehicle{ vehicleid } == false ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else if ( playerid != ownerid ) return SendError( playerid, "You cannot sell this vehicle." );
		else
		{
			format( szBigString, sizeof( szBigString ), "[SELL] [%s] %s | %d | %s\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), v, GetVehicleName( GetVehicleModel( g_vehicleData[ playerid ] [ v ] [ E_VEHICLE_ID ] ) ) );
		    AddFileLogLine( "log_destroycar.txt", szBigString );
            GivePlayerCash( playerid, ( g_vehicleData[ playerid ] [ v ] [ E_PRICE ] / 2 ) );
			SendClientMessageFormatted( playerid, -1, ""COL_GREY"[VEHICLE]"COL_WHITE" You have sold this vehicle for half the price it was (%s).", cash_format( ( g_vehicleData[ playerid ] [ v ] [ E_PRICE ] / 2 ) ) );
            DestroyBuyableVehicle( playerid, v );
		}
	}
	else if ( strmatch( params, "lock" ) )
	{
		new v = getVehicleSlotFromID( vehicleid, ownerid  );
	    if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You need to be in a vehicle to use this command." );
		else if ( v == -1 ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else if ( g_buyableVehicle{ vehicleid } == false ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else if ( playerid != ownerid ) return SendError( playerid, "You cannot lock this vehicle." );
		else
		{
		    g_vehicleData[ playerid ] [ v ] [ E_LOCKED ] = !g_vehicleData[ playerid ] [ v ] [ E_LOCKED ];
			SendClientMessageFormatted( playerid, -1, ""COL_GREY"[VEHICLE]"COL_WHITE" You have %s this vehicle.", g_vehicleData[ playerid ] [ v ] [ E_LOCKED ] == true ? ( "locked" ) : ( "un-locked" ) );
            SaveVehicleData( playerid, v );
		}
	}
	else if ( strmatch( params, "park" ) )
	{
		new v = getVehicleSlotFromID( vehicleid, ownerid  ), Float: X, Float: Y, Float: Z, Float: Angle;
	    if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You need to be in a vehicle to use this command." );
	    else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You need to be a driver to use this command." );
		else if ( v == -1 ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else if ( playerid != ownerid ) return SendError( playerid, "You cannot park this vehicle." );
		else
		{
	        if ( IsVehicleUpsideDown( GetPlayerVehicleID( playerid ) ) ) return SendError( playerid, "Sorry, you're just going to have to ditch your car as soon as possible." );

	        new
	        	iBreach = PlayerBreachedGarageLimit( playerid, v );

	        if ( iBreach == -1 ) return SendError( playerid, "You cannot park vehicles that are not owned by the owner of this garage." );
	        if ( iBreach == -2 ) return SendError( playerid, "This garage has already reached its capacity of %d vehicles.", GetGarageVehicleCapacity( p_InGarage[ playerid ] ) );

			GetVehiclePos( vehicleid, X, Y, Z );
			GetVehicleZAngle( vehicleid, Angle );
			g_vehicleData[ playerid ] [ v ] [ E_X ] = X, g_vehicleData[ playerid ] [ v ] [ E_Y ] = Y, g_vehicleData[ playerid ] [ v ] [ E_Z ] = Z, g_vehicleData[ playerid ] [ v ] [ E_ANGLE ] = Angle;
			PutPlayerInVehicle( playerid, RespawnBuyableVehicle( vehicleid, playerid ), 0 );
 			SetTimerEx( "timedUpdates_RBV", 25, false, "ddf", playerid, INVALID_VEHICLE_ID, -1000.0 );
            SaveVehicleData( playerid, v );
        	SendClientMessage( playerid, -1, ""COL_GREY"[VEHICLE]"COL_WHITE" You have parked this vehicle." );
		}
	}
	else if ( strmatch( params, "respawn" ) )
	{
		if ( p_OwnedVehicles[ playerid ] > 0 )
		{
		    szLargeString = ""COL_GREY"Respawn All Vehicles\n";
			for( new i; i < p_OwnedVehicles[ playerid ]; i++ )
		    {
				if ( g_vehicleData[ playerid ] [ i ] [ E_OWNER_ID ] == p_AccountID[ playerid ] && IsValidVehicle( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ] ) ) {
				    format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, GetVehicleName( GetVehicleModel( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ] ) ) );
				}
		    }
		    ShowPlayerDialog( playerid, DIALOG_VEHICLE_SPAWN, DIALOG_STYLE_LIST, "{FFFFFF}Spawn your vehicle", szLargeString, "Select", "Cancel" );
		}
		else SendError( playerid, "You don't own any vehicles." );
	}
	else if ( strmatch( params, "locate" ) ) return SendServerMessage( playerid, "This feature has been replaced with "COL_GREY"/v bring"COL_WHITE"." );
	else if ( strmatch( params, "bring" ) )
	{
		if ( p_VehicleBringCooldown[ playerid ] > g_iTime )
			return SendError( playerid, "You must wait %s before using this feature again.", secondstotime( p_VehicleBringCooldown[ playerid ] - g_iTime ) );

		if ( p_OwnedVehicles[ playerid ] > 0 )
		{
		    szLargeString = ""COL_WHITE"Bringing your vehicle to you will cost $10,000!\n";
			for( new i; i < p_OwnedVehicles[ playerid ]; i++ )
		    {
				if ( g_vehicleData[ playerid ] [ i ] [ E_OWNER_ID ] == p_AccountID[ playerid ] && IsValidVehicle( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ] ) ) {
				    format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, GetVehicleName( GetVehicleModel( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ] ) ) );
				}
			}
		    ShowPlayerDialog( playerid, DIALOG_VEHICLE_LOCATE, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Bring Vehicle", szLargeString, "Select", "Cancel" );
		}
		else SendError( playerid, "You don't own any vehicles." );
	}
	else if ( strmatch( params, "data" ) )
	{
		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You are not in any vehicle." );
		else if ( g_buyableVehicle{ GetPlayerVehicleID( playerid ) } == false ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else
		{
			new v = getVehicleSlotFromID( vehicleid, ownerid );
	        if ( playerid != ownerid ) return SendError( playerid, "You don't own this vehicle." );

			format( szBigString, sizeof( szBigString ),	""COL_GREY"Vehicle Owner:"COL_WHITE" %s\n"\
			                            ""COL_GREY"Vehicle Type:"COL_WHITE" %s\n"\
			                            ""COL_GREY"Vehicle ID:"COL_WHITE" %d\n"\
			                            ""COL_GREY"Vehicle Price:"COL_WHITE" %s",
			                            ReturnPlayerName( ownerid ), GetVehicleName( GetVehicleModel( GetPlayerVehicleID( playerid ) ) ),
			                            g_vehicleData[ playerid ] [ v ] [ E_SQL_ID ], cash_format( g_vehicleData[ playerid ] [ v ] [ E_PRICE ] ) );
			ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Vehicle Data", szBigString, "Okay", "" );
		}
	}
	else if ( !strcmp( params, "color", false, 4 ) )
	{
		new
		    color1, color2
		;
		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You must be inside a vehicle to use this command." );
	    else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You need to be a driver to use this command." );
		else if ( sscanf( params[ 6 ], "dd", color1, color2 ) ) return SendUsage( playerid, "/v color [COLOR_1] [COLOR_2]" );
		else if ( g_buyableVehicle{ GetPlayerVehicleID( playerid ) } == false ) return SendError( playerid, "This isn't a buyable vehicle." );
		else if ( GetPlayerCash( playerid ) < 100 ) return SendError( playerid, "You don't have enough cash for this." );
		else if ( color1 > 255 || color1 < 0 || color2 > 255 || color2 < 0 ) return SendError( playerid, "Invalid vehicle color ID." );
		else
		{
	        new vID = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid );
	        if ( playerid != ownerid ) return SendError( playerid, "You don't own this vehicle." );
	        if ( IsVehicleUpsideDown( GetPlayerVehicleID( playerid ) ) ) return SendError( playerid, "Sorry, you're just going to have to ditch your car as soon as possible." );
	        g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 0 ] = color1;
	        g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 1 ] = color2;
	    	GivePlayerCash( playerid, -100 );
			PutPlayerInVehicle( playerid, RespawnBuyableVehicle( vehicleid, playerid ), 0 );
	        SaveVehicleData( playerid, vID );
			SendServerMessage( playerid, "You have successfully changed your vehicle colors." );
		}
	}
	else if ( !strcmp( params, "plate", false, 4 ) )
	{
		new
		    szPlate[ 32 ]
		;
		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You must be inside a vehicle to use this command." );
	    else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You need to be a driver to use this command." );
		else if ( sscanf( params[ 6 ], "s[32]", szPlate ) ) return SendUsage( playerid, "/v plate [TEXT]" );
		else if ( g_buyableVehicle{ GetPlayerVehicleID( playerid ) } == false ) return SendError( playerid, "This isn't a buyable vehicle." );
		else
		{
	        new vID = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid );
	        if ( playerid != ownerid ) return SendError( playerid, "You don't own this vehicle." );
			if ( IsBoatVehicle( GetVehicleModel( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] ) ) || IsAirVehicle( GetVehicleModel( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] ) ) ) return SendError( playerid, "Sorry, this feature is not available on planes and boats." );
	        if ( IsVehicleUpsideDown( GetPlayerVehicleID( playerid ) ) ) return SendError( playerid, "Sorry, you're just going to have to ditch your car as soon as possible." );
			format( g_vehicleData[ playerid ] [ vID ] [ E_PLATE ], 32, "%s", szPlate );
			PutPlayerInVehicle( playerid, RespawnBuyableVehicle( vehicleid, playerid ), 0 );
	        SaveVehicleData( playerid, vID );
			SendServerMessage( playerid, "Your have changed your vehicle's number plate to "COL_GREY"%s"COL_WHITE".", szPlate );
		}
	}
	else if ( !strcmp( params, "paintjob", false, 7 ) )
	{
		new
		    paintjobid
		;
		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You must be inside a vehicle to use this command." );
	    else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You need to be a driver to use this command." );
		else if ( sscanf( params[ 9 ], "d", paintjobid ) ) return SendUsage( playerid, "/v paintjob [PAINT_JOB_ID]" );
		else if ( g_buyableVehicle{ GetPlayerVehicleID( playerid ) } == false ) return SendError( playerid, "This isn't a buyable vehicle." );
		else if ( GetPlayerCash( playerid ) < 500 ) return SendError( playerid, "You don't have enough cash for this." );
		else if ( paintjobid < 0 || paintjobid > 3 ) return SendError( playerid, "Please specify a paintjob between 0 to 3." );
		else
		{
	        new vID = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid );
	        if ( playerid != ownerid ) return SendError( playerid, "You don't own this vehicle." );
			if ( !IsPaintJobVehicle( GetVehicleModel( GetPlayerVehicleID( playerid ) ) ) ) return SendError( playerid, "This vehicle cannot have a paintjob installed." );
			if ( IsVehicleUpsideDown( GetPlayerVehicleID( playerid ) ) ) return SendError( playerid, "Sorry, you're just going to have to ditch your car as soon as possible." );
	        g_vehicleData[ playerid ] [ vID ] [ E_PAINTJOB ] = paintjobid;
		    ChangeVehiclePaintjob( GetPlayerVehicleID( playerid ), paintjobid );
		    GivePlayerCash( playerid, -500 );
			PutPlayerInVehicle( playerid, RespawnBuyableVehicle( vehicleid, playerid ), 0 );
	        SaveVehicleData( playerid, vID );
		}
	}
	else if ( !strcmp( params, "toggle", false, 5 ) )
	{
		new v = getVehicleSlotFromID( vehicleid, ownerid );
	    if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You need to be in a vehicle to use this command." );
	    else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You need to be a driver to use this command." );
		else if ( v == -1 ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else if ( playerid != ownerid ) return SendError( playerid, "This vehicle does not belong to you." );
		else
		{
			if ( !strlen( params[ 7 ] ) )
				return SendUsage( playerid, "/v toggle [DOORS/BONNET/BOOT/LIGHTS/WINDOWS]" );

			GetVehicleParamsEx( vehicleid, engine, lights, alarm, doors, bonnet, boot, objective );

			if ( !strcmp( params[ 7 ], "doors", true, 5 ) ) {
				if ( !strlen( params[ 13 ] ) ) return SendUsage( playerid, "/v toggle doors [OPEN/CLOSE]" );
				if ( strmatch( params[ 13 ], "open" ) ) {
					SetVehicleParamsCarDoors( vehicleid, 1, 1, 1, 1 );
					return SendServerMessage( playerid, "You have opened the doors of this vehicle." );
				}
				else if ( strmatch( params[ 13 ], "close" ) ) {
					SetVehicleParamsCarDoors( vehicleid, 0, 0, 0, 0 );
					return SendServerMessage( playerid, "You have closed the doors of this vehicle." );
				}
				else {
					return SendUsage( playerid, "/v toggle doors [OPEN/CLOSE]" );
				}
			}

			else if ( !strcmp( params[ 7 ], "windows", true, 7 ) ) {
				if ( !strlen( params[ 15 ] ) ) return SendUsage( playerid, "/v toggle windows [OPEN/CLOSE]" );
				if ( strmatch( params[ 15 ], "open" ) ) {
					SetVehicleParamsCarWindows( vehicleid, 0, 0, 0, 0 );
					return SendServerMessage( playerid, "You have opened the windows of this vehicle." );
				}
				else if ( strmatch( params[ 15 ], "close" ) ) {
					SetVehicleParamsCarWindows( vehicleid, 1, 1, 1, 1 );
					return SendServerMessage( playerid, "You have closed the windows of this vehicle." );
				}
				else {
					return SendUsage( playerid, "/v toggle windows [OPEN/CLOSE]" );
				}
			}

			else if ( strmatch( params[ 7 ], "bonnet" ) ){
				SendServerMessage( playerid, "You have %s the bonnet of this vehicle.", ( bonnet = !bonnet ) ? ( "opened" ) : ( "closed" ) );
			}

			else if ( strmatch( params[ 7 ], "boot" ) ) {
				SendServerMessage( playerid, "You have %s the boot of this vehicle.", ( boot = !boot ) ? ( "opened" ) : ( "closed" ) );
			}

			else if ( strmatch( params[ 7 ], "lights" ) ) {
				SendServerMessage( playerid, "You have %s the lights of this vehicle.", ( lights = !lights ) ? ( "switched on" ) : ( "switched off" ) );
			}

			else {
				return SendUsage( playerid, "/v toggle [DOORS/BONNET/BOOT/LIGHTS/WINDOWS]" );
			}

			return SetVehicleParamsEx( vehicleid, engine, lights, alarm, doors, bonnet, boot, objective );
		}
	}
	else if ( strmatch( params, "reset" ) )
	{
		new v = getVehicleSlotFromID( vehicleid, ownerid );
	    if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You need to be in a vehicle to use this command." );
	    else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You need to be a driver to use this command." );
		else if ( v == -1 ) return SendError( playerid, "This vehicle isn't a buyable vehicle." );
		else if ( playerid != ownerid ) return SendError( playerid, "This vehicle does not belong to you." );
		else
		{
			if ( IsVehicleUpsideDown( vehicleid ) ) return SendError( playerid, "Sorry, you're just going to have to ditch your car as soon as possible." );
			ResetBuyableVehicleMods( playerid, v, 0 );
		    ChangeVehiclePaintjob( vehicleid, 3 );
		    g_vehicleData[ playerid ] [ v ] [ E_PAINTJOB ] = 3;
	        g_vehicleData[ playerid ] [ v ] [ E_COLOR ] [ 0 ] = 0;
	        g_vehicleData[ playerid ] [ v ] [ E_COLOR ] [ 1 ] = 0;
			PutPlayerInVehicle( playerid, RespawnBuyableVehicle( vehicleid, playerid ), 0 );
	        SaveVehicleData( playerid, v );
			SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have reset your vehicle's appearance." );
		}
	}
	else SendUsage( playerid, "/v [SELL/COLOR/LOCK/PARK/RESPAWN/BRING/DATA/PLATE/PAINTJOB/TOGGLE/RESET]" );
	return 1;
}

/* ** SQL Threads ** */
thread OnVehicleLoad( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		rows, fields, i = -1, vID,
		Query[ 76 ]
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			for( vID = 0; vID < MAX_BUYABLE_VEHICLES; vID++ )
				if ( !g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] ) break;

			if ( vID >= MAX_BUYABLE_VEHICLES )
				continue;

			if ( g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] )
			    continue;

			cache_get_field_content( i, "PLATE", g_vehicleData[ playerid ] [ vID ] [ E_PLATE ], dbHandle, 32 );
			cache_get_field_content( i, "MODS", Query ), sscanf( Query, "p<.>e<ddddddddddddddd>", g_vehicleModifications[ playerid ] [ vID ] );

			g_vehicleData[ playerid ] [ vID ] [ E_SQL_ID ] 		= cache_get_field_content_int( i, "ID", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_OWNER_ID ] 	= cache_get_field_content_int( i, "OWNER", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_MODEL ] 		= cache_get_field_content_int( i, "MODEL", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_LOCKED ] 		= !!cache_get_field_content_int( i, "LOCKED", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_X ] 			= cache_get_field_content_float( i, "X", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_Y ] 			= cache_get_field_content_float( i, "Y", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_Z ] 			= cache_get_field_content_float( i, "Z", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_ANGLE ] 		= cache_get_field_content_float( i, "ANGLE", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 0 ] = cache_get_field_content_int( i, "COLOR1", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 1 ] = cache_get_field_content_int( i, "COLOR2", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_PRICE ] 		= cache_get_field_content_int( i, "PRICE", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_PAINTJOB ] 	= cache_get_field_content_int( i, "PAINTJOB", dbHandle );
			g_vehicleData[ playerid ] [ vID ] [ E_GARAGE ] 		= cache_get_field_content_int( i, "GARAGE", dbHandle );

			new iVehicle = CreateVehicle( g_vehicleData[ playerid ] [ vID ] [ E_MODEL ], g_vehicleData[ playerid ] [ vID ] [ E_X ], g_vehicleData[ playerid ] [ vID ] [ E_Y ], g_vehicleData[ playerid ] [ vID ] [ E_Z ], g_vehicleData[ playerid ] [ vID ] [ E_ANGLE ], g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 0 ], g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 1 ], 999 );
		    g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] = iVehicle;

			if ( iVehicle != INVALID_VEHICLE_ID ) {
				if ( g_vehicleData[ playerid ] [ vID ] [ E_GARAGE ] != -1 ) {
					LinkVehicleToInterior( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ], GetGarageInteriorID( g_vehicleData[ playerid ] [ vID ] [ E_GARAGE ] ) );
					SetVehicleVirtualWorld( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ], GetGarageVirtualWorld( g_vehicleData[ playerid ] [ vID ] [ E_GARAGE ] ) );
				}

				SetVehicleNumberPlate( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ], g_vehicleData[ playerid ] [ vID ] [ E_PLATE ] );
				ChangeVehiclePaintjob( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ], g_vehicleData[ playerid ] [ vID ] [ E_PAINTJOB ] );
				for( new x = 0; x < MAX_CAR_MODS; x++ )
				{
					if ( g_vehicleModifications[ playerid ] [ vID ] [ x ] >= 1000 && g_vehicleModifications[ playerid ] [ vID ] [ x ] < 1193 )
					{
					    if ( CarMod_IsLegalCarMod( GetVehicleModel( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] ), g_vehicleModifications[ playerid ] [ vID ] [ x ] ) )
					        AddVehicleComponent( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ], g_vehicleModifications[ playerid ] [ vID ] [ x ] );
						else
						    g_vehicleModifications[ playerid ] [ vID ] [ x ] = 0;
					}
				}
				g_adminSpawnedCar{ g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] } = false;
				g_buyableVehicle{ g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] } = true;
			}

		    g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] = true;

			// Load vehicle components
			format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `COMPONENTS` WHERE `VEHICLE_ID`=%d", g_vehicleData[ playerid ] [ vID ] [ E_SQL_ID ] );
			mysql_function_query( dbHandle, szNormalString, true, "OnVehicleComponentsLoad", "dd", playerid, vID );
		}

		p_OwnedVehicles[ playerid ] = rows;
	}
	return 1;
}

thread OnPlayerCreateBuyableVehicle( playerid, slot )
{
	g_vehicleData[ playerid ] [ slot ] [ E_SQL_ID ] = cache_insert_id( );
	return 1;
}

/* ** Functions ** */
stock CreateBuyableVehicle( playerid, Model, Color1, Color2, Float: X, Float: Y, Float: Z, Float: Angle, Cost )
{
	new
		vID,
	    szString[ 300 ],
	    iCar = INVALID_VEHICLE_ID
	;

	if ( playerid != INVALID_PLAYER_ID && !IsPlayerConnected( playerid ) )
	    return INVALID_PLAYER_ID;

	for( vID = 0; vID < MAX_BUYABLE_VEHICLES; vID++ )
		if ( !g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] ) break;

	if ( vID >= MAX_BUYABLE_VEHICLES )
		return -1;

	if ( g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] )
	    return -1;

	if ( vID != -1 )
	{
		strcpy( g_vehicleData[ playerid ] [ vID ] [ E_PLATE ], "SF-CNR" );
		g_vehicleData[ playerid ] [ vID ] [ E_LOCKED ] = false;
		g_vehicleData[ playerid ] [ vID ] [ E_X ] = X;
		g_vehicleData[ playerid ] [ vID ] [ E_Y ] = Y;
		g_vehicleData[ playerid ] [ vID ] [ E_Z ] = Z;
		g_vehicleData[ playerid ] [ vID ] [ E_ANGLE ] = Angle;
		g_vehicleData[ playerid ] [ vID ] [ E_PRICE ] = Cost;
		g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 0 ] = Color1;
		g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 1 ] = Color2;
		g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] = true;
		g_vehicleData[ playerid ] [ vID ] [ E_PRICE ] = Cost;
		g_vehicleData[ playerid ] [ vID ] [ E_MODEL ] = Model;
		g_vehicleData[ playerid ] [ vID ] [ E_PAINTJOB ] = 3;
		g_vehicleData[ playerid ] [ vID ] [ E_GARAGE ] = -1;
		g_vehicleData[ playerid ] [ vID ] [ E_OWNER_ID ] = p_AccountID[ playerid ];
		ResetBuyableVehicleMods( playerid, vID );
		iCar = CreateVehicle( Model, X, Y, Z, Angle, Color1, Color2, 999999999 );
		g_adminSpawnedCar{ iCar } = false;
		//GetVehicleParamsEx( iCar, engine, lights, alarm, doors, bonnet, boot, objective );
		//SetVehicleParamsEx( iCar, VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective );
		SetVehicleNumberPlate( iCar, "SF-CNR" );
		g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] = iCar;
		g_buyableVehicle{ iCar } = true;
		format( szString, sizeof( szString ), "INSERT INTO `VEHICLES` (`MODEL`,`LOCKED`,`X`,`Y`,`Z`,`ANGLE`,`COLOR1`,`COLOR2`,`PRICE`,`OWNER`,`PLATE`,`PAINTJOB`,`MODS`) VALUES (%d,0,%f,%f,%f,%f,%d,%d,%d,%d,'SF-CNR',3,'0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.')", Model, X, Y, Z, Angle, Color1, Color2, Cost, g_vehicleData[ playerid ] [ vID ] [ E_OWNER_ID ] );
		mysql_function_query( dbHandle, szString, true, "OnPlayerCreateBuyableVehicle", "dd", playerid, vID );

		p_OwnedVehicles[ playerid ] ++; // Append value
	}
	return vID;
}

stock ResetBuyableVehicleMods( playerid, id, fordestroy=1 )
{
	if ( id < 0 || id > MAX_BUYABLE_VEHICLES )
	    return;

	if ( !g_vehicleData[ playerid ] [ id ] [ E_CREATED ] )
	    return;

	for( new i = 0; i < MAX_CAR_MODS; i++ )
	{
		if ( !fordestroy && IsValidVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ) ) {
	        if ( CarMod_IsLegalCarMod( GetVehicleModel( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ), g_vehicleModifications[ playerid ] [ id ] [ i ] ) )
	            RemoveVehicleComponent( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], g_vehicleModifications[ playerid ] [ id ] [ i ] );
		}
		g_vehicleModifications[ playerid ] [ id ] [ i ] = 0;
	}

	format( szNormalString, sizeof( szNormalString ), "UPDATE `VEHICLES` SET `MODS`='0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.' WHERE `ID`=%d", g_vehicleData[ playerid ] [ id ] [ E_SQL_ID ] );
	mysql_single_query( szNormalString );
}

stock DestroyBuyableVehicle( playerid, vID, bool: db_remove = true )
{
	if ( vID < 0 || vID > MAX_BUYABLE_VEHICLES )
	    return 0;

	if ( playerid == INVALID_PLAYER_ID )
		return INVALID_PLAYER_ID;

	if ( !g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] )
	    return 0;

	new
	    query[ 40 ]
	;

	if ( db_remove )
	{
	    SendClientMessage( playerid, -1, ""COL_PINK"[VEHICLE]"COL_WHITE" One of your vehicles has been destroyed.");
		p_OwnedVehicles[ playerid ] --;

		format( query, sizeof( query ), "DELETE FROM `VEHICLES` WHERE `ID`=%d", g_vehicleData[ playerid ] [ vID ] [ E_SQL_ID ] );
		mysql_single_query( query );

    	ResetBuyableVehicleMods( playerid, vID );
	}

	// Reset vehicle component data (hook into module)
	DestroyVehicleCustomComponents( playerid, vID, db_remove );

	// Reset vehicle data
	g_vehicleData[ playerid ] [ vID ] [ E_OWNER_ID ] = 0;
	g_vehicleData[ playerid ] [ vID ] [ E_LOCKED ] = false;
	g_vehicleData[ playerid ] [ vID ] [ E_CREATED ] = false;
	g_buyableVehicle{ g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] } = false;
	DestroyVehicle( g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] );
    g_vehicleData[ playerid ] [ vID ] [ E_VEHICLE_ID ] = INVALID_VEHICLE_ID;
	return 1;
}

stock RespawnBuyableVehicle( samp_veh_id, occupantid = INVALID_PLAYER_ID )
{
	new playerid, id;
	new gravy = getVehicleSlotFromID( samp_veh_id, playerid, id );

	if ( gravy == -1 )
		return INVALID_VEHICLE_ID;

	if ( id == -1 && !g_vehicleData[ playerid ] [ id ] [ E_CREATED ] )
	    return INVALID_VEHICLE_ID;

	if ( !IsValidVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ) )
	    return INVALID_VEHICLE_ID; // If it aint working.

	new
		Float: beforeAngle,
		Float: Health,
		newVeh = INVALID_VEHICLE_ID
	;

	GetVehicleZAngle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], beforeAngle );
	GetVehicleDamageStatus( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], panels, doors, lights, tires ); // Can't do this to restore health.
	GetVehicleHealth( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], Health );

	if ( ( newVeh = CreateVehicle( g_vehicleData[ playerid ] [ id ] [ E_MODEL ], g_vehicleData[ playerid ] [ id ] [ E_X ], g_vehicleData[ playerid ] [ id ] [ E_Y ], g_vehicleData[ playerid ] [ id ] [ E_Z ], g_vehicleData[ playerid ] [ id ] [ E_ANGLE ], g_vehicleData[ playerid ] [ id ] [ E_COLOR ] [ 0 ], g_vehicleData[ playerid ] [ id ] [ E_COLOR ] [ 1 ], 999999999 ) ) == INVALID_VEHICLE_ID ) {
	    printf( "[ERROR] CreateVehicle(%d, %f, %f, %f, %f, %d, %d, %d);", g_vehicleData[ playerid ] [ id ] [ E_MODEL ], g_vehicleData[ playerid ] [ id ] [ E_X ], g_vehicleData[ playerid ] [ id ] [ E_Y ], g_vehicleData[ playerid ] [ id ] [ E_Z ], g_vehicleData[ playerid ] [ id ] [ E_ANGLE ], g_vehicleData[ playerid ] [ id ] [ E_COLOR ] [ 0 ], g_vehicleData[ playerid ] [ id ] [ E_COLOR ] [ 1 ], 999999999 );
		return SendError( playerid, "Couldn't update vehicle due to a unknown error." );
	}

	// Reset special data
    ResetVehicleMethlabData( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], true );

    // Destroy vehicle
	DestroyVehicle( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] );
	g_buyableVehicle{ g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] } = false;
	g_buyableVehicle{ newVeh } = true;
 	g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] = newVeh;

	// Restore old data
	SetVehicleNumberPlate( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], g_vehicleData[ playerid ] [ id ] [ E_PLATE ] );
	ChangeVehiclePaintjob( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], g_vehicleData[ playerid ] [ id ] [ E_PAINTJOB ] );
	for( new i = 0; i < MAX_CAR_MODS; i++ ) {
	    if ( g_vehicleModifications[ playerid ] [ id ] [ i ] >= 1000 && g_vehicleModifications[ playerid ] [ id ] [ i ] < 1193 )
	    {
	        if ( CarMod_IsLegalCarMod( GetVehicleModel( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ] ), g_vehicleModifications[ playerid ] [ id ] [ i ] ) )
	            AddVehicleComponent( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], g_vehicleModifications[ playerid ] [ id ] [ i ] );
			else
			    g_vehicleModifications[ playerid ] [ id ] [ i ] = 0;
	    }
	}

	UpdateVehicleDamageStatus( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], panels, doors, lights, tires );
	SetVehicleHealth( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], Health );

	if ( g_vehicleData[ playerid ] [ id ] [ E_GARAGE ] != -1 ) {
		LinkVehicleToInterior( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], GetGarageInteriorID( g_vehicleData[ playerid ] [ id ] [ E_GARAGE ] ) );
		SetVehicleVirtualWorld( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], GetGarageVirtualWorld( g_vehicleData[ playerid ] [ id ] [ E_GARAGE ] ) );
	}

	if ( occupantid != INVALID_PLAYER_ID ) // So nothing bugs with /v color
	{
	    new Float: X, Float: Y, Float: Z;
	    SyncSpectation( playerid ); // Bug?
	    GetPlayerPos( occupantid, X, Y, Z );
	    SetVehiclePos( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], X, Y, Z + 1 );
	    LinkVehicleToInterior( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], GetPlayerInterior( playerid ) );
	    SetVehicleVirtualWorld( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], GetPlayerVirtualWorld( playerid ) );
	    SetTimerEx( "timedUpdates_RBV", 50, false, "ddf", occupantid, g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], beforeAngle );
	}

	// Replace components (hook into module)
	ReplaceVehicleCustomComponents( playerid, id );

	if ( !g_vehicleData[ playerid ] [ id ] [ E_OWNER_ID ] ) {
		GetVehicleParamsEx( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], engine, lights, alarm, doors, bonnet, boot, objective );
		SetVehicleParamsEx( g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ], VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective );
	}

	return g_vehicleData[ playerid ] [ id ] [ E_VEHICLE_ID ];
}

stock SaveVehicleData( playerid, vID )
{
	if ( vID == -1 )
	    return 0;

	new
		szPlate[ 32 ];

	// Plate System
	if ( isnull( g_vehicleData[ playerid ] [ vID ] [ E_PLATE ] ) )
		szPlate = "SF-CNR";
	else
		strcat( szPlate, g_vehicleData[ playerid ] [ vID ] [ E_PLATE ] );

	// Begin Saving
	format( szLargeString, sizeof( szLargeString ), "UPDATE `VEHICLES` SET `MODEL`=%d,`LOCKED`=%d,`X`=%f,`Y`=%f,`Z`=%f,`ANGLE`=%f,`COLOR1`=%d,`COLOR2`=%d,`PRICE`=%d,`PAINTJOB`=%d,`OWNER`=%d,`PLATE`='%s',`GARAGE`=%d WHERE `ID`=%d",
	    g_vehicleData[ playerid ] [ vID ] [ E_MODEL ], g_vehicleData[ playerid ] [ vID ] [ E_LOCKED ], g_vehicleData[ playerid ] [ vID ] [ E_X ], g_vehicleData[ playerid ] [ vID ] [ E_Y ], g_vehicleData[ playerid ] [ vID ] [ E_Z ],
	    g_vehicleData[ playerid ] [ vID ] [ E_ANGLE ], g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 0 ], g_vehicleData[ playerid ] [ vID ] [ E_COLOR ] [ 1 ], g_vehicleData[ playerid ] [ vID ] [ E_PRICE ], g_vehicleData[ playerid ] [ vID ] [ E_PAINTJOB ],
		g_vehicleData[ playerid ] [ vID ] [ E_OWNER_ID ], mysql_escape( szPlate ), g_vehicleData[ playerid ] [ vID ] [ E_GARAGE ],
		g_vehicleData[ playerid ] [ vID ] [ E_SQL_ID ] );

	mysql_single_query( szLargeString );
	return 1;
}

stock dischargeVehicles( playerid )
{
	if ( p_OwnedVehicles[ playerid ] )
	{
		for( new v; v < MAX_BUYABLE_VEHICLES; v++ )
	 		DestroyBuyableVehicle( playerid, v, .db_remove = false );
	}
	return 1;
}

function timedUpdates_RBV( playerid, vehicleid, Float: angle ) {
	if ( vehicleid != INVALID_VEHICLE_ID )
		SetVehicleZAngle( vehicleid, angle );
}

stock UpdateBuyableVehicleMods( playerid, v )
{
	if ( v < 0 || v > MAX_BUYABLE_VEHICLES ) return 0;
	if ( !g_vehicleData[ playerid ] [ v ] [ E_CREATED ] ) return 0;
	new vehicleid = g_vehicleData[ playerid ] [ v ] [ E_VEHICLE_ID ];
	if ( !IsValidVehicle( vehicleid ) ) return 0;

	for( new i; i < MAX_CAR_MODS; i++ )
    	if ( ( g_vehicleModifications[ playerid ] [ v ] [ i ] = GetVehicleComponentInSlot( vehicleid, i ) ) < 1000 ) g_vehicleModifications[ playerid ] [ v ] [ i ] = 0;

	return 1;
}

stock getVehicleSlotFromID( vID, &playerid=0, &slot=0 )
{
	foreach(new i : Player)
	{
		for( new x; x < MAX_BUYABLE_VEHICLES; x++ ) if ( g_vehicleData[ i ] [ x ] [ E_CREATED ] )
		{
	    	if ( g_vehicleData[ i ] [ x ] [ E_VEHICLE_ID ] == vID )
	    	{
	    		playerid = i;
	    		slot = x;
	    		return x;
	    	}
		}
	}
	return -1;
}

stock SetPlayerVehicleInteriorData( iOwner, iSlot, iInterior, iWorld, Float: fX, Float: fY, Float: fZ, Float: fAngle, iGarage = -1 )
{
	new
		iVehicle = g_vehicleData[ iOwner ] [ iSlot ] [ E_VEHICLE_ID ];

	SetVehiclePos( iVehicle, fX, fY, fZ );
	SetVehicleZAngle( iVehicle, fAngle );

	LinkVehicleToInterior( iVehicle, iInterior );
	SetVehicleVirtualWorld( iVehicle, iWorld );

	ReplaceVehicleCustomComponents( iOwner, iSlot ); // Change virtual worlds

	// Update for passengers etc
	foreach ( new i : Player )
	{
		if ( GetPlayerVehicleID( i ) == iVehicle || GetPlayerSurfingVehicleID( i ) == iVehicle )
		{
			p_InGarage[ i ] = iGarage;
			SetPlayerInterior( i, iInterior );
			SetPlayerVirtualWorld( i, iWorld );
		}
	}
}
