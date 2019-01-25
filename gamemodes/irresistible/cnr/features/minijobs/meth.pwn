/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\minijobs\meth.pwn
 * Purpose: meth minijob
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define CHEMICAL_CS 				0
#define CHEMICAL_MU					1
#define CHEMICAL_HLC				2

#define PROGRESS_CHEMICAL 			6
#define PROGRESS_GRAB_METH 			7

#define VW_METH 					110

/* ** Variables ** */
enum E_METH_PROCEEDURE
{
	E_CHEMICAL, 		E_NAME[ 98 ]
};

static const
	sz_mu_MethProduction[  ] [ 56 ] =
	{
		{ "This batch looks like it needs some muriatic. Add some." },
		{ "Continue the cooking process by adding some acid." },
		{ "Soda. Actually, acid. Yeah, that's it." },
		{ "It's cooking fine. However, it needs more acid." },
		{ "If you have any muriatic, pour it in." },
		{ "Chloride, or... Acid. Muriatic. Add that."},
		{ "Stone Cleaner, add that in." }
	},

	sz_cs_MethProduction[  ] [ 54 ] =
	{
		{ "It's getting blue, add some soda in though." },
		{ "Got any soda? Drop it in." },
		{ "This batch needs some club soda." },
		{ "Add hydrogen chloride. Actually, add soda!" },
		{ "Continue the process with some caustic soda." },
		{ "Cooking up real fine. Needs some caustic soda though." },
		{ "Get the temperature up by adding caustic soda." },
		{ "Caustic soda... Or muriatic. Actually, add soda." }
	},

	sz_hcl_MethProduction[  ] [ 46 ] =
	{
		{ "Add some of that chloride." },
		{ "It needs some bubbles, hydrogen should be it." },
		{ "This batch needs hydrogen." },
		{ "Continue the process by adding a gas tank." },
		{ "Add soda. Actually, add hydrogen." },
		{ "A gas, what could it be? Hydrogen?" },
		{ "Cooking right away, needs more gas though." }
	}
;

static stock
	p_MuriaticAcid					[ MAX_PLAYERS char ],
	p_CausticSoda 					[ MAX_PLAYERS char ],
	p_HydrogenChloride 				[ MAX_PLAYERS char ],
	p_Methamphetamine				[ MAX_PLAYERS char ]
;

/* ** Forwards ** */
forward OnMethamphetamineCooking( playerid, vehicleid, last_chemical );

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_MuriaticAcid{ playerid } = 0;
	p_CausticSoda{ playerid } = 0;
	p_Methamphetamine{ playerid } = 0;
	p_HydrogenChloride{ playerid } = 0;
	return 1;
}

hook OnPlayerEnterVehicle( playerid, vehicleid, ispassenger )
{
	new
		vehicle_model = GetVehicleModel( vehicleid );

	if ( ispassenger && vehicle_model == 508 && GetPlayerVirtualWorld( playerid ) == 0 ) // Journey
	{
        SetPlayerPos( playerid, 2087.2339, 1233.6448, 414.7454 );
        SetPlayerInterior( playerid, VW_METH ); // Li
        SetPlayerVirtualWorld( playerid, vehicleid + VW_METH );
        SetPVarInt( playerid, "inMethLab", 1 );
        pauseToLoad( playerid );
	}
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
    static
    	Float: X, Float: Y, Float: Z, Float: Angle;

	if ( PRESSED( KEY_FIRE ) )
	{
		if ( IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) && IsPlayerInMethlab( playerid ) && p_Class[ playerid ] != CLASS_POLICE )
		{
			new
				vehicleid = GetPlayerMethLabVehicle( playerid ),
				objectid = GetGVarInt( "meth_yield", vehicleid ),
				Float: fAimDistance = 0.4
			;

			if ( IsValidDynamicObject( objectid ) && Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID ) == 1579 )
			{
				if ( GetDynamicObjectPos( objectid, X, Y, Z ) )
				{
					if ( IsPlayerAimingAt( playerid, X, Y, Z, fAimDistance ) )
						ApplyAnimation( playerid, "CARRY", "liftup105", 4.0, 1, 0, 0, 1, 0 ), ShowProgressBar( playerid, "Taking Meth", PROGRESS_GRAB_METH, 3000, 0x87CEEBFF );
				}
			}
			else
			{
				if ( GetGVarType( "meth_chef", vehicleid ) != GLOBAL_VARTYPE_NONE && IsPlayerConnected( GetGVarInt( "meth_chef", vehicleid ) ) && GetGVarType( "meth_cooktimer", vehicleid ) == GLOBAL_VARTYPE_NONE && ! IsPlayerProgressBarStarted( playerid ) )
				{
					if ( IsPlayerAimingAt( playerid, 2083.489990, 1234.743041, 414.821014, fAimDistance ) )
					{
						if ( !p_CausticSoda{ playerid } )
							return SendError( playerid, "You don't have any caustic soda." );

						SetPVarInt( playerid, "pouring_chemical", CHEMICAL_CS );
						ApplyAnimation( playerid, "CARRY", "putdwn105", 4.0, 1, 0, 0, 1, 0 );
						ShowProgressBar( playerid, "Pouring Caustic Soda", PROGRESS_CHEMICAL, 2500, 0x3E7EFFFF );
					}
					else if ( IsPlayerAimingAt( playerid, 2083.282958, 1234.025024, 415.028009, fAimDistance ) )
					{
						if ( !p_HydrogenChloride{ playerid } )
							return SendError( playerid, "You don't have any hydrogen chloride." );

						SetPVarInt( playerid, "pouring_chemical", CHEMICAL_HLC );
						ApplyAnimation( playerid, "CARRY", "putdwn105", 4.0, 1, 0, 0, 1, 0 );
						ShowProgressBar( playerid, "Pouring Hydrogen Chloride", PROGRESS_CHEMICAL, 2500, 0xEE9911FF );
					}
					else if ( IsPlayerAimingAt( playerid, 2083.638916, 1233.254028, 415.020996, fAimDistance ) )
					{
						if ( !p_MuriaticAcid{ playerid } )
							return SendError( playerid, "You don't have any muriatic acid." );

						SetPVarInt( playerid, "pouring_chemical", CHEMICAL_MU );
						ApplyAnimation( playerid, "CARRY", "putdwn105", 4.0, 1, 0, 0, 1, 0 );
						ShowProgressBar( playerid, "Pouring Muriatic Acid", PROGRESS_CHEMICAL, 2500, 0xFF0000FF );
					}
				}
			}
   		}
	}

	else if ( PRESSED( KEY_SECONDARY_ATTACK ) )
	{
	   	if ( IsPlayerInMethlab( playerid ) && CanPlayerExitEntrance( playerid ) )
    	{
    		new vehicleid = GetPlayerVirtualWorld( playerid ) - VW_METH;

    		if ( IsValidVehicle( vehicleid ) && IsPlayerInRangeOfPoint( playerid, 1.5, 2087.2339, 1233.6448, 414.7454 ) )
    		{
		        GetVehiclePos( vehicleid, X, Y, Z );
		        GetVehicleZAngle( vehicleid, Angle );

		        X += ( 2.0 * floatsin( -( Angle - 45.0 ), degrees ) );
		        Y += ( 2.0 * floatcos( -( Angle - 45.0 ), degrees ) );

		        SetPlayerInterior( playerid, 0 );
		        SetPlayerVirtualWorld( playerid, 0 );
		        SetPlayerPos( playerid, X, Y, Z - 0.94 );
		        SetPlayerFacingAngle( playerid, Angle );

		        haltMethamphetamine( playerid, vehicleid );
		        DeletePVar( playerid, "inMethLab" );

		        UpdatePlayerEntranceExitTick( playerid );
		        pauseToLoad( playerid );
    		}
    	}
	}
	return 1;
}

hook OnVehicleSpawn( vehicleid )
{
    ResetVehicleMethlabData( vehicleid, true );
	return 1;
}

hook OnVehicleDeath( vehicleid, killerid )
{
    ResetVehicleMethlabData( vehicleid, true );
	return 1;
}

hook OnPlayerProgressUpdate( playerid, progressid, bool: canceled, params )
{
	if ( progressid == PROGRESS_CHEMICAL || progressid == PROGRESS_GRAB_METH )
	{
		if ( !IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) || !IsPlayerInMethlab( playerid ) || canceled )
			return DeletePVar( playerid, "pouring_chemical" ), StopProgressBar( playerid ), 1;
	}
	return 1;
}

hook OnProgressCompleted( playerid, progressid, params )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( progressid == PROGRESS_CHEMICAL )
	{
		if ( IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) && IsPlayerInMethlab( playerid ) )
		{
			new
				chemical = GetPVarInt( playerid, "pouring_chemical" ),
				vehicleid = GetPlayerMethLabVehicle( playerid )
			;

			DeletePVar( playerid, "pouring_chemical" );

			switch( chemical )
			{
				case CHEMICAL_MU: 	p_MuriaticAcid{ playerid } --,		SetGVarInt( "meth_acid", 0, vehicleid );
				case CHEMICAL_CS: 	p_CausticSoda{ playerid } --,		SetGVarInt( "meth_soda", 0, vehicleid );
				case CHEMICAL_HLC: 	p_HydrogenChloride{ playerid } --,	SetGVarInt( "meth_chloride", 0, vehicleid );
			}

			if ( GetGVarInt( "meth_ingredient", vehicleid ) != chemical )
			{
				DeleteGVar( "meth_ingredient", vehicleid );
				DeleteGVar( "meth_soda", vehicleid );
				DeleteGVar( "meth_acid", vehicleid );
				DeleteGVar( "meth_chloride", vehicleid );
				DeleteGVar( "meth_chef", vehicleid );
				SendServerMessage( playerid, "You have put the whole chemical. The methlab has exploded." );
				GetPlayerPos( playerid, X, Y, Z );
				CreateExplosionForPlayer( playerid, X, Y, Z - 0.75, 0, 10.0 );
				SetPlayerHealth( playerid, -1 );
			}
			else
			{
				SetGVarInt( "meth_chef", playerid, vehicleid );

				SetGVarInt( "meth_smoke", CreateDynamicObject( 18726, 0.0, 0.0, -1000.0, 0.000000, 0.000000, 0.000000 ), vehicleid );
				AttachDynamicObjectToVehicle( GetGVarInt( "meth_smoke", vehicleid ), vehicleid, -0.524999, -0.974999, -0.375000, 0.000000, 0.000000, 0.000000 );

				ShowPlayerHelpDialog( playerid, 5000, "Okay, okay, everything seems to be cooking fine. Wait till for the next chemical to be added." );
   				if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://files.sfcnr.com/game_sounds/meth_cooking.mp3", 1476.0394, 1464.3358, 1012.1190, 5.0, 1 );
				SetGVarInt( "meth_cooktimer", SetTimerEx( "OnMethamphetamineCooking", 10000, false, "ddd", playerid, vehicleid, chemical ), vehicleid );
			}
		}
	}
	else if ( progressid == PROGRESS_GRAB_METH )
	{
		if ( IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) && IsPlayerInMethlab( playerid ) )
		{
			new
				vehicleid = GetPlayerMethLabVehicle( playerid ),
				objectid = GetGVarInt( "meth_yield", vehicleid )
			;

			if ( !( IsValidDynamicObject( objectid ) && Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID ) == 1579 ) )
				return SendError( playerid, "Someone just took the last batch of the meth!" );

			if ( p_Methamphetamine{ playerid } >= 128 )
				return SendError( playerid, "You can only export a maximum of 128 pounds of meth." );

			p_Methamphetamine{ playerid } ++;

			DestroyDynamicObject( GetGVarInt( "meth_yield", vehicleid ) );

			// Reset meth data
			DeleteGVar( "meth_yield", vehicleid );
			DeleteGVar( "meth_ingredient", vehicleid );
			DeleteGVar( "meth_soda", vehicleid );
			DeleteGVar( "meth_acid", vehicleid );
			DeleteGVar( "meth_chloride", vehicleid );
			DeleteGVar( "meth_chef", vehicleid );

			SendServerMessage( playerid, "You've yielded a pound of meth. Take your bags over to "COL_GREY"Cluckin' Bell"COL_WHITE" for exportation." );
		}
	}
	return 1;
}

/* ** Callbacks ** */
public OnMethamphetamineCooking( playerid, vehicleid, last_chemical )
{
	DeleteGVar( "meth_cooktimer", vehicleid ); // Remove it, useless...

	if ( IsValidVehicle( vehicleid ) && IsPlayerConnected( playerid ) && IsPlayerInMethlab( playerid ) )
	{
		DestroyDynamicObject( GetGVarInt( "meth_smoke", vehicleid ) );
		DeleteGVar( "meth_smoke", vehicleid );

		if ( ! GetGVarInt( "meth_acid", vehicleid ) && ! GetGVarInt( "meth_soda", vehicleid ) && ! GetGVarInt( "meth_chloride", vehicleid ) )
		{
			ShowPlayerHelpDialog( playerid, 5000, "The process is done. Bag it up and do another round if you wish." );
			SendServerMessage( playerid, "Process is done. Bag it up, and do another round if you wish. Export it for money." );
			GivePlayerWantedLevel( playerid, 12 );
			GivePlayerScore( playerid, 3 );
			ach_HandleMethYielded( playerid );
			SetGVarInt( "meth_yield", CreateDynamicObject( 1579, 2083.684082, 1233.945922, 414.875244, 0.000000, 0.000000, 90.000000, GetPlayerVirtualWorld( playerid ) ), vehicleid );
			PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );
			Streamer_Update( playerid );
		}
		else
		{
			new
				available_meth[ 3 ] = { -1, ... };

			if ( ! GetGVarInt( "meth_soda", vehicleid ) ) available_meth[ CHEMICAL_CS ] = CHEMICAL_CS;
			if ( ! GetGVarInt( "meth_acid", vehicleid ) ) available_meth[ CHEMICAL_MU ] = CHEMICAL_MU;
			if ( ! GetGVarInt( "meth_chloride", vehicleid ) ) available_meth[ CHEMICAL_HLC ] = CHEMICAL_HLC;

			new
				iMethIngredient = randomExcept( available_meth, sizeof( available_meth ) );

			switch( iMethIngredient )
			{
				case CHEMICAL_HLC: 	ShowPlayerHelpDialog( playerid, 17500, "%s", sz_hcl_MethProduction[ random( sizeof( sz_hcl_MethProduction ) ) ] );
				case CHEMICAL_MU:	ShowPlayerHelpDialog( playerid, 17500, "%s", sz_mu_MethProduction[ random( sizeof( sz_mu_MethProduction ) ) ] );
				case CHEMICAL_CS:	ShowPlayerHelpDialog( playerid, 17500, "%s", sz_cs_MethProduction[ random( sizeof( sz_cs_MethProduction ) ) ] );
			}

			SetGVarInt( "meth_ingredient", iMethIngredient, vehicleid );

			SendServerMessage( playerid, "Okay, let's cook. New chemical to be added." );
			PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
		}
	}
	else
	{
		ResetVehicleMethlabData( vehicleid );
	}
	return 1;
}

/* ** Commands ** */
CMD:meth( playerid, params[ ] )
{
	if ( strmatch( params, "cook" ) )
	{
		if ( !IsPlayerInMethlab( playerid ) )
			return SendError( playerid, "You need to be in a methlab to use this command." );

		new
			vehicleid = GetPlayerMethLabVehicle( playerid ),
			objectid = GetGVarInt( "meth_yield", vehicleid )
		;
		if ( IsValidVehicle( vehicleid ) && GetVehicleModel( vehicleid ) == 508 )
		{
			if ( !IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) )
				return SendError( playerid, "You're not near the lab." );

			if ( GetGVarInt( "meth_soda", vehicleid ) != 0 || GetGVarInt( "meth_acid", vehicleid ) != 0 || GetGVarInt( "meth_chloride", vehicleid ) != 0 )
				return SendError( playerid, "This methlab is already in operation." );

			if ( GetGVarType( "meth_cooktimer", vehicleid ) != GLOBAL_VARTYPE_NONE  )
				return SendError( playerid, "This methlab is already in operation." );

			if ( IsValidDynamicObject( objectid ) && Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID ) == 1579 )
				return SendError( playerid, "You must grab the meth before you continue." );

			if ( !p_CausticSoda{ playerid } && !p_HydrogenChloride{ playerid } && !p_MuriaticAcid{ playerid } )
				return SendError( playerid, "You're light on Caustic Soda, Hydrogen Chloride and Muriatic Acid." );

			if ( p_Class[ playerid ] != CLASS_CIVILIAN )
				return SendError( playerid, "This is restricted to civilians only." );

			new
				iMethIngredient = random( 3 );

			SendServerMessage( playerid, "You're now beginning the methamphetamine production. Follow the dialog to yield a pound of meth." );

			SetGVarInt( "meth_ingredient", iMethIngredient, vehicleid );
			SetGVarInt( "meth_soda", 1, vehicleid );
			SetGVarInt( "meth_acid", 1, vehicleid );
			SetGVarInt( "meth_chloride", 1, vehicleid );
			SetGVarInt( "meth_chef", playerid, vehicleid );

			switch( iMethIngredient )
			{
				case CHEMICAL_HLC: 	ShowPlayerHelpDialog( playerid, 12500, "%s", sz_hcl_MethProduction[ random( sizeof( sz_hcl_MethProduction ) ) ] );
				case CHEMICAL_MU:	ShowPlayerHelpDialog( playerid, 12500, "%s", sz_mu_MethProduction[ random( sizeof( sz_mu_MethProduction ) ) ] );
				case CHEMICAL_CS:	ShowPlayerHelpDialog( playerid, 12500, "%s", sz_cs_MethProduction[ random( sizeof( sz_cs_MethProduction ) ) ] );
			}
		}
		else SendError( playerid, "An unexpected error has occurred, please re-enter your methlab." );
	}
	else if ( strmatch( params, "export" ) )
	{
		if ( GetPlayerInterior( playerid ) != 9 )
			return SendError( playerid, "You must be inside Cluckin' Bell to use this command." );

		if ( ! p_Methamphetamine{ playerid } )
			return SendError( playerid, "You don't have any meth to export." );

		if ( p_Class[ playerid ] != CLASS_CIVILIAN )
			return SendError( playerid, "This is restricted to civilians only." );

		new
			cashEarned = p_Methamphetamine{ playerid } * ( 5000 + random( 1000 ) );

		GivePlayerCash( playerid, cashEarned );
		StockMarket_UpdateEarnings( E_STOCK_CLUCKIN_BELL, cashEarned, .factor = 0.3 );
		SendServerMessage( playerid, "You have exported %d bags of meth, earning you "COL_GOLD"%s"COL_WHITE".", p_Methamphetamine{ playerid }, cash_format( cashEarned ) );
		p_Methamphetamine{ playerid } = 0;
	}
	else SendUsage( playerid, "/meth [COOK/EXPORT]" );
	return 1;
}


/* ** Functions ** */
stock ResetVehicleMethlabData( vehicleid, bool: death = false )
{
	// Attempt to at least remove meth smoke
	DestroyDynamicObject( GetGVarInt( "meth_smoke", vehicleid ) );
	DeleteGVar( "meth_smoke", vehicleid );

	// Validate vehicle model
	if ( GetVehicleModel( vehicleid ) != 508 )
		return;

	static
		Float: X, Float: Y, Float: Z;

	if ( death )
	{
		foreach(new playerid : Player)
		{
			if ( GetPlayerVirtualWorld( playerid ) == ( vehicleid + VW_METH ) && !p_Spectating{ playerid } )
			{
				haltMethamphetamine( playerid, vehicleid );
				GetPlayerPos( playerid, X, Y, Z );
				CreateExplosionForPlayer( playerid, X, Y, Z - 0.75, 0, 10.0 );
				SetPlayerHealth( playerid, -1 );
				GameTextForPlayer( playerid, "~r~The vehicle and the methlab have exploded.", 4000, 0 );
			}
		}
	}

	new timer = GetGVarInt( "meth_cooktimer", vehicleid );
	if ( timer ) KillTimer( timer ); // Could be invalid lol

	DeleteGVar( "meth_ingredient", vehicleid );
	DeleteGVar( "meth_soda", vehicleid );
	DeleteGVar( "meth_acid", vehicleid );
	DeleteGVar( "meth_chloride", vehicleid );
	DeleteGVar( "meth_chef", vehicleid );
	DeleteGVar( "meth_cooktimer", vehicleid );
}

stock haltMethamphetamine( playerid, vehicleid, canceled=1 )
{
	if ( playerid == INVALID_PLAYER_ID )
		return;

	if ( !IsValidVehicle( vehicleid ) )
		return;

	if ( GetGVarInt( "meth_chef", vehicleid ) == playerid )
	{
		if ( canceled )
			GameTextForPlayer( playerid, "~r~Cooking Operation Canceled!", 4000, 0 );

		new timer = GetGVarInt( "meth_cooktimer", vehicleid );
		if ( timer ) KillTimer( timer ); // Could be invalid lol
		DestroyDynamicObject( GetGVarInt( "meth_smoke", vehicleid ) );

		DeletePVar( playerid, "pouring_chemical" );
		DeleteGVar( "meth_ingredient", vehicleid );
		DeleteGVar( "meth_soda", vehicleid );
		DeleteGVar( "meth_acid", vehicleid );
		DeleteGVar( "meth_chloride", vehicleid );
		DeleteGVar( "meth_chef", vehicleid );
		DeleteGVar( "meth_cooktimer", vehicleid );
		DeleteGVar( "meth_smoke", vehicleid );

		HidePlayerHelpDialog( playerid );
	}
}

stock IsPlayerInMethlab( playerid ) {
	return ( GetPVarInt( playerid, "inMethLab" ) == 1 && GetPlayerInterior( playerid ) == VW_METH );
}

stock GetPlayerMethLabVehicle( playerid ) {
	return ( GetPlayerVirtualWorld( playerid ) - VW_METH );
}

stock GetPlayerMeth( playerid ) return p_Methamphetamine{ playerid };

stock SetPlayerMeth( playerid, amount ) {
	p_Methamphetamine{ playerid } = amount;
}

stock GetPlayerMuriaticAcid( playerid ) return p_MuriaticAcid{ playerid };

stock SetPlayerMuriaticAcid( playerid, amount ) {
	p_MuriaticAcid{ playerid } = amount;
}

stock GetPlayerHydrogenChloride( playerid ) return p_HydrogenChloride{ playerid };

stock SetPlayerHydrogenChloride( playerid, amount ) {
	p_HydrogenChloride{ playerid } = amount;
}

stock GetPlayerCausticSoda( playerid ) return p_CausticSoda{ playerid };

stock SetPlayerCausticSoda( playerid, amount ) {
	p_CausticSoda{ playerid } = amount;
}

stock RemovePlayersFromJourney( vehicleID )
{
	new Float: x, Float: y, Float: z;

	foreach ( new playerid : Player )
	{
		if ( GetPlayerVirtualWorld( playerid ) == ( vehicleID + VW_METH ) && !p_Spectating{ playerid } )
		{
			haltMethamphetamine( playerid, vehicleID );

			GetVehiclePos( vehicleID, x, y, z );
			SetPlayerPos( playerid, x, y, z );
			SetPlayerInterior( playerid, 0 );
			SetPlayerVirtualWorld( playerid, 0 );

			p_MuriaticAcid{ playerid } = 0;
			p_CausticSoda{ playerid } = 0;
			p_Methamphetamine{ playerid } = 0;
			p_HydrogenChloride{ playerid } = 0;
			
			SendServerMessage( playerid, "You have been removed from a player-owned Journey as the player who owned it has left the server." );
		}
	}

	return 1;
}