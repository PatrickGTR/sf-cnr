/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\race.pwn
 * Purpose: racing system between players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_RACES 					( 32 )

#define RACE_STREET_RACE 			0
#define RACE_OUTRUN 				1
#define OUTRUN_DIST 				6.0

/* ** Variables ** */
enum E_RACE_DATA
{
	E_LOBBY_HOST, 				E_MODE, 						E_ENTRY_FEE,
	E_POOL, 					E_RACE_FINISH_SET, 				Float: E_FINISH_POS[ 3 ],
	E_CD_TIMER,					E_FINISH_MAP_ICON, 				Float: E_POSITION_PRIZE[ 3 ],
	E_START_CHECKPOINT,  		E_FINISH_CHECKPOINT, 			E_FINISHED_COUNT,
	bool: E_STARTED, 			E_OUTRUN_SPHERE, 				E_OUTRUN_OBJECT,
	E_OUTRUN_LEAD, 				E_OUTRUN_TIMER, 				Float: E_OUTRUN_DISTANCE
};

enum E_RACE_DEST_DATA
{
	E_NAME[ 16 ],
	Float: E_X, 				Float: E_Y, 					Float: E_Z
};

static stock
	g_raceFinalDestinations 		[ ] [ E_RACE_DEST_DATA ] =
	{
		{ "LS Airport", 		1487.0245, -2493.751, 13.2720 },
		{ "LS Pier", 			369.61540, -2011.367, 7.39200 },
		{ "LS Grove Street", 	2487.9739, -1666.938, 13.0633 },
		{ "LV Airport", 		1477.6246, 1207.3376, 10.8203 },
		{ "LV Old Strip", 		2350.5371, 2143.6689, 10.6815 },
		{ "El Quebrados",		-885.4323, 1660.3818, 27.0871 },
		{ "SF Airport", 		-1117.212, 375.26310, 14.1484 },
		{ "Mount Chiliad", 		-2324.256, -1624.915, 483.883 },
		{ "SF Gant Bridge", 	-2681.314, 1763.9274, 68.4844 },
		{ "SF Dealership ",		-2422.670, -609.4055, 132.562 }
	},
	g_raceData 						[ MAX_RACES ] [ E_RACE_DATA ],
	Iterator: races 				< MAX_RACES >,

	p_raceLobbyId 					[ MAX_PLAYERS ] = { -1, ... },
	p_raceInvited 					[ MAX_PLAYERS ] [ MAX_RACES ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	for ( new i = 0; i < MAX_RACES; i ++ ) {
		p_raceInvited[ playerid ] [ i ] = false;
	}
	return 1;
}

hook OnPlayerEnterDynArea( playerid, areaid )
{
   	new
   		raceid = p_raceLobbyId[ playerid ];

	if ( Iter_Contains( races, raceid ) && g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] == areaid && g_raceData[ raceid ] [ E_OUTRUN_LEAD ] != playerid )
	{
		new
			vehicleid = GetPlayerVehicleID( playerid );

		// new leader
		g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = playerid;

		// alert
		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
			PlayerPlaySound( i, 1149, 0.0, 0.0, 0.0 );
			GameTextForPlayer( i, sprintf( "~b~~h~%s leading", ReturnPlayerName( playerid ) ), 2000, 3 );
			SendClientMessageFormatted( i, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has taken the lead for the race.", ReturnPlayerName( playerid ), playerid );
		}

		// see if ahead
		AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], vehicleid, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], vehicleid, 0.0, OUTRUN_DIST * 2 );
	}
	return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate )
{
	if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER )
	{
		new
			iRace = p_raceLobbyId[ playerid ];

		if ( Iter_Contains( races, iRace ) )
		{
			SendClientMessageToRace( iRace, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has exited their vehicle and left the race.", ReturnPlayerName( playerid ), playerid );
			RemovePlayerFromRace( playerid );
		}
	}
	return 1;
}

hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	new
		raceid = p_raceLobbyId[ playerid ];

	if ( raceid != -1 && g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] == checkpointid )
	{
		if ( ! g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "The race has not started." );

		new
			position = ++ g_raceData[ raceid ] [ E_FINISHED_COUNT ];

		// give prize and alert
		if ( 1 <= position <= 3 )
			GivePlayerRaceWin( playerid, position, raceid );

		// close race after members finished
		new
			members = GetRaceMemberCount( raceid );

		// printf ("Position : %d, Members : %d", position, members);
		if ( position >= 3 || position >= members ) {
			DestroyRace( raceid );
			// print ("Shut race");
		}
		return 1;
	}
	// printf("Entered Race Checkpoint : {user:%s,veh:%d,biz_veh:%d,valid_biz:%d}", ReturnPlayerName( playerid ), iVehicle, g_isBusinessVehicle[ iVehicle ],Iter_Contains( business, g_isBusinessVehicle[ iVehicle ] ));
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_RACE && response )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		switch ( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_RACE_MODE, DIALOG_STYLE_TABLIST, ""COL_GOLD"Race Configuration - Race Mode", ""COL_GREY"Street Race\t"COL_WHITE"Racers must meet the final destination\n"COL_GREY"Outrun"COL_WHITE"\tRacer must outrun everyone by 100 metres", "Select", "Close" );
			case 1: ShowPlayerDialog( playerid, DIALOG_RACE_FEE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Entry Fee", ""COL_WHITE"Specify the required entry fee for this race (minimum $1,000 - max $10,000,000)", "Specify", "Close" );
			case 2: ShowPlayerDialog( playerid, DIALOG_RACE_POS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Prize Distribution", ""COL_WHITE"1st Position\t"COL_WHITE"2nd Position\t"COL_WHITE"3rd Position\n100%\t0%\t0%\n90%\t5%\t5%\n80%\t10%\t10%\n70%\t15%\t15%\n60%\t20%\t20%\n", "Select", "Close" );
			case 3:
			{
				if ( g_raceData[ raceid ] [ E_MODE ] == RACE_OUTRUN )
					return ShowPlayerDialog( playerid, DIALOG_RACE_DISTANCE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Outrun Distance", ""COL_WHITE"Specify the required outrun distance (minimum 10.0m - max 250.0m)", "Specify", "Close" );

				return ShowPlayerDialog( playerid, DIALOG_RACE_DEST, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Destination", ""COL_WHITE""COL_WHITE"How do you want to set the final destination?\nPreset Destinations\nSelect Using Minimap\nUse Coordinates", "Select", "Back" );
			}
			case 4:
			{
				erase( szLargeString );

				foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid && g_raceData[ raceid ] [ E_LOBBY_HOST ] != i ) {
					format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\n", szLargeString, ReturnPlayerName( i ), i );
				}

				if ( strlen( szLargeString ) ) {
					return ShowPlayerDialog( playerid, DIALOG_RACE_KICK, DIALOG_STYLE_LIST, ""COL_GOLD"Race Configuration - Player Management", szLargeString, "Kick", "Back" );
				} else {
					SendError( playerid, "There are no racers to show." );
					return ShowRaceConfiguration( playerid, raceid );
				}
			}
		}
	}
	else if ( dialogid == DIALOG_RACE_DEST )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowRaceConfiguration( playerid, raceid );

		switch ( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_RACE_PRESELECT, DIALOG_STYLE_LIST, ""COL_GOLD"Race Configuration - Destination", "LS Airport\nLS Pier\nLS Grove Street\nLV Airport\nLV Old Strip\nEl Quebrados\nSF Airport\nMount Chilliad\nTierra Robada SF Bridge\nSF Dealership", "Select", "Back" );
			case 1:
			{
				g_raceData[ raceid ] [ E_RACE_FINISH_SET ] = 2;
				g_raceData[ raceid ] [ E_FINISH_POS ] [ 0 ] = 0.0;
				g_raceData[ raceid ] [ E_FINISH_POS ] [ 1 ] = 0.0;
				g_raceData[ raceid ] [ E_FINISH_POS ] [ 2 ] = 0.0;
				return SendServerMessage( playerid, "You are now setting the race destination. Use the MINIMAP to pick the finish position." );
			}
			case 2: ShowPlayerDialog( playerid, DIALOG_RACE_CUSTOM_DEST, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Custom Destination", ""COL_WHITE"Please specify the final destination coordinates, seperated by white spaces. E.g 0.0 0.0 0.0", "Set", "Back" );
		}
		return 1;
	}
	else if ( dialogid == DIALOG_RACE_CUSTOM_DEST )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowPlayerDialog( playerid, DIALOG_RACE_DEST, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Destination", ""COL_WHITE""COL_WHITE"How do you want to set the final destination?\nPreset Destinations\nSelect Using Minimap\nUse Coordinates", "Select", "Back" );

		new
			Float: X, Float: Y, Float: Z;

		if ( sscanf( inputtext, "fff", X, Y, Z ) ) {
			SendError( playerid, "Make sure coordinates are seperated by white spaces and are numbers (e.g 0.0 0.0 0.0)" );
			return ShowPlayerDialog( playerid, DIALOG_RACE_CUSTOM_DEST, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Custom Destination", ""COL_WHITE"Please specify the final destination coordinates, seperated by white spaces. E.g 0.0 0.0 0.0", "Set", "Back" );
		}

		SetRaceDestination( raceid, X, Y, Z );
		SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has set the race final destination to %0.4f %0.4f %0.4f.", ReturnPlayerName( playerid ), playerid, X, Y, Z );
		return 1;
	}
	else if ( dialogid == DIALOG_RACE_PRESELECT )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowPlayerDialog( playerid, DIALOG_RACE_DEST, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Destination", ""COL_WHITE""COL_WHITE"How do you want to set the final destination?\nPreset Destinations\nSelect Using Minimap\nUse Coordinates", "Select", "Back" );

		SetRaceDestination( raceid, g_raceFinalDestinations[ listitem ] [ E_X ], g_raceFinalDestinations[ listitem ] [ E_Y ], g_raceFinalDestinations[ listitem ] [ E_Z ] );
		SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has set the race final destination to %s.", ReturnPlayerName( playerid ), playerid, g_raceFinalDestinations[ listitem ] [ E_NAME ] );
		return 1;
	}
	else if ( dialogid == DIALOG_RACE_KICK )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		ShowRaceConfiguration( playerid, raceid );

		if ( ! response )
			return 1;

		new
			x = 0;

		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid && g_raceData[ raceid ] [ E_LOBBY_HOST ] != i )
		{
	       	if ( x == listitem )
	      	{
		  		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has been kicked from the race.", ReturnPlayerName( i ), i );
		  		RemovePlayerFromRace( i );
	      		return 1;
			}
	      	x++;
		}
		return SendError( playerid, "There was an error trying to remove this player from the race." );
	}
	else if ( dialogid == DIALOG_RACE_MODE )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( response )
		{
			g_raceData[ raceid ] [ E_MODE ] = listitem;
			SendServerMessage( playerid, "You have set the race mode to "COL_GREY"%s"COL_WHITE".", g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE ? ( "Streetrace" ) : ( "Outrun" ) );
		}
		return ShowRaceConfiguration( playerid, raceid );
	}
	else if ( dialogid == DIALOG_RACE_DISTANCE )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowRaceConfiguration( playerid, raceid );

		new
			Float: distance;

		if ( sscanf( inputtext, "f", distance ) || ! ( 10.0 <= distance <= 300.0 ) ) {
			SendError( playerid, "Please specify a race distance between 10.0m and 300.0m." );
			return ShowPlayerDialog( playerid, DIALOG_RACE_DISTANCE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Outrun Distance", ""COL_WHITE"Specify the required outrun distance (minimum 10.0m - max 250.0m)", "Specify", "Close" );
		}

		g_raceData[ raceid ] [ E_OUTRUN_DISTANCE ] = distance;
		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The outrun distance has been set to %0.1f metres.", distance );
		return ShowRaceConfiguration( playerid, raceid );
	}
	else if ( dialogid == DIALOG_RACE_FEE )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowRaceConfiguration( playerid, raceid );

		new
			fee;

		if ( sscanf( inputtext, "d", fee ) || ! ( 0 <= fee <= 10000000 ) ) {
			SendError( playerid, "Please specify an entry fee between $0 and $10,000,000." );
			return ShowPlayerDialog( playerid, DIALOG_RACE_FEE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Entry Fee", ""COL_WHITE"Specify the required entry fee for this race (minimum $1,000 - max $10,000,000)", "Specify", "Close" );
		}

		g_raceData[ raceid ] [ E_ENTRY_FEE ] = fee;
		SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" The entry fee for the race has been set to %s.", cash_format( fee ) );
		return ShowRaceConfiguration( playerid, raceid );
	}
	else if ( dialogid == DIALOG_RACE_POS )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( response )
		{
			static const
				Float: g_prizePoolDistribution[ ] [ 3 ] =
				{
					{ 1.0, 0.0, 0.0 },
					{ 0.9, 0.05, 0.05 },
					{ 0.8, 0.1, 0.1 },
					{ 0.7, 0.15, 0.15 },
					{ 0.6, 0.2, 0.2 }
				}
			;

			// position prize
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] = g_prizePoolDistribution[ listitem ] [ 0 ];
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ] = g_prizePoolDistribution[ listitem ] [ 1 ];
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ] = g_prizePoolDistribution[ listitem ] [ 2 ];

			// alert
			SendServerMessage( playerid, "The prize pool distribution is now %0.0f%% for 1st, %0.0f%% for 2nd and %0.0f%% for 3rd place.", 100.0 * g_prizePoolDistribution[ listitem ] [ 0 ], 100.0 * g_prizePoolDistribution[ listitem ] [ 1 ], 100.0 * g_prizePoolDistribution[ listitem ] [ 2 ] );
		}
		return ShowRaceConfiguration( playerid, raceid );
	}
	return 1;
}

hook OnPlayerClickMap( playerid, Float: fX, Float: fY, Float: fZ )
{
	new
		raceid = GetPVarInt( playerid, "editing_race" );

	if ( IsRaceHost( playerid, raceid ) )
	{
		if ( g_raceData[ raceid ] [ E_RACE_FINISH_SET ] == 2 )
		{
			new
				Float: nodeX, Float: nodeY, Float: nodeZ,
				nodeid = NearestNodeFromPoint( fX, fY, fZ )
			;

			GetNodePos( nodeid, nodeX, nodeY, nodeZ );

			// set destination
			SetRaceDestination( raceid, nodeX, nodeY, nodeZ + 1.0 );

			// alert
			ShowRaceConfiguration( playerid, raceid );
			SendServerMessage( playerid, "You have selected the final destination for the race, use "COL_GREY"/race start"COL_WHITE" to begin." );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:race( playerid, params[ ] )
{
	if ( ! IsPlayerInAnyVehicle( playerid ) )
		return SendError( playerid, "You must be in a vehicle to use this command" );

	if ( !strcmp( params, "create", false, 6 ) )
	{
		new
			prizePool;

		if ( sscanf( params[ 7 ], "d", prizePool ) )
			return SendUsage( playerid, "/race create [INITIAL PRIZE POOL]" );

		if ( prizePool < 1000 )
			return SendError( playerid, "The minimum initial prize pool must be $1,000." );

		if ( prizePool > GetPlayerCash( playerid ) )
			return SendError( playerid, "You don't have this amount of money." );

		if ( p_raceLobbyId[ playerid ] != -1 )
			return SendError( playerid, "You are currently in a race lobby, use "COL_GREY"/race leave"COL_WHITE" to exit." );

		new
			id = Iter_Free(races);

		if ( id != ITER_NONE )
		{
			// clear race
			DestroyDynamicMapIcon( g_raceData[ id ] [ E_FINISH_MAP_ICON ] );
			DestroyDynamicRaceCP( g_raceData[ id ] [ E_FINISH_CHECKPOINT ] );

			// default race lobby data
			g_raceData[ id ] [ E_LOBBY_HOST ] = playerid;
			g_raceData[ id ] [ E_MODE ] = RACE_STREET_RACE;
			g_raceData[ id ] [ E_ENTRY_FEE ] = 1000;
			g_raceData[ id ] [ E_POOL ] = prizePool;
			g_raceData[ id ] [ E_RACE_FINISH_SET ] = 0;
			g_raceData[ id ] [ E_STARTED ] = false;
			g_raceData[ id ] [ E_OUTRUN_DISTANCE ] = 250.0;
			g_raceData[ id ] [ E_FINISHED_COUNT ] = 0;
			g_raceData[ id ] [ E_POSITION_PRIZE ] [ 0 ] = 1.0, g_raceData[ id ] [ E_POSITION_PRIZE ] [ 1 ] = 0.0, g_raceData[ id ] [ E_POSITION_PRIZE ] [ 2 ] = 0.0;
			g_raceData[ id ] [ E_FINISH_POS ] [ 0 ] = 1.0, g_raceData[ id ] [ E_FINISH_POS ] [ 1 ] = 0.0, g_raceData[ id ] [ E_FINISH_POS ] [ 2 ] = 0.0;

			// reset user cash
			p_raceLobbyId[ playerid ] = id;
			GivePlayerCash( playerid, -prizePool );

			// config
			ShowRaceConfiguration( playerid, id );

			// iter
			Iter_Add( races, id );
		}
		else return SendError( playerid, "Unable to create a race as there are too many currently on-going." );
	}
	else if ( !strcmp( params, "invite", false, 6 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! Iter_Contains( races, raceid ) )
			return SendError( playerid, "You are not in any race." );

		new
			inviteid;

		if ( sscanf( params[ 7 ], "u", inviteid ) )
			return SendUsage( playerid, "/race invite [PLAYER]" );

		if ( ! IsPlayerConnected( inviteid ) || IsPlayerNPC( inviteid ) )
			return SendServerMessage( playerid, "This player is not connected" );

		if ( GetDistanceBetweenPlayers( inviteid, playerid ) > 50.0 )
			return SendError( playerid, "This player must be within 50 meters to you." );

		if ( p_raceLobbyId[ inviteid ] != -1 )
			return SendError( playerid, "This player is currently already in a race lobby." );

		if( g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "You cannot invite players once you start the race." );

		p_raceInvited[ inviteid ] [ raceid ] = true;
		SendClientMessageFormatted( inviteid, COLOR_GREY, "[RACE]{FFFFFF} %s(%d) has invited you to their race for %s, to join type \"/race join %d\"", ReturnPlayerName( playerid ), playerid,  g_raceData[ raceid ] [ E_ENTRY_FEE ] <= 0 ? ( "free" ) : ( cash_format( g_raceData[ raceid ] [ E_ENTRY_FEE ] ) ), raceid );
	    SendClientMessageFormatted( playerid, COLOR_GREY, "[RACE]{FFFFFF} You have invited %s(%d) to join your race.", ReturnPlayerName( inviteid ), inviteid );
		return 1;
	}
	else if ( !strcmp( params, "join", false, 4 ) )
	{
		new
			raceid;

		if ( sscanf( params[ 5 ], "d", raceid ) ) return SendUsage( playerid, "/race join [RACE_ID]" );
		else if ( ! Iter_Contains( races, raceid ) ) return SendError( playerid, "This race lobby does not exist." );
		else if ( ! p_raceInvited[ playerid ] [ raceid ] ) return SendError( playerid, "You have not been invited to this race lobby." );
		else if( GetDistanceBetweenPlayers( playerid, g_raceData[ raceid ] [ E_LOBBY_HOST ] ) > 50.0 ) return SendError( playerid, "This player must be within 50 meters to you." );
		else if ( g_raceData[ raceid ] [ E_STARTED ] ) return SendError( playerid, "The race has already started." );
		else if ( g_raceData[ raceid ] [ E_ENTRY_FEE ] > GetPlayerCash( playerid ) ) return SendError( playerid, "You need at least %s to join the race.", cash_format( g_raceData[ raceid ] [ E_ENTRY_FEE ] - GetPlayerCash( playerid ) ) );
		else
		{
			// enter race lobby
			p_raceLobbyId[ playerid ] = raceid;
			p_raceInvited[ playerid ] [ raceid ] = false;

			// alert race players
			SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]{FFFFFF} %s(%d) has joined the race.", ReturnPlayerName( playerid ), playerid );

			// show checkpoint
			if ( g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE && g_raceData[ raceid ] [ E_RACE_FINISH_SET ] == 1 )
			{
	  			Streamer_AppendArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, playerid );
	  			Streamer_AppendArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, playerid );
		  	}

			// remove entry fee
			GivePlayerCash( playerid, -g_raceData[ raceid ] [ E_ENTRY_FEE ] );
			g_raceData[ raceid ] [ E_POOL ] += g_raceData[ raceid ] [ E_ENTRY_FEE ];
		}
		return 1;
	}
	else if ( strmatch( params, "config" ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You must be a race lobby host in order to use this command." );

		return ShowRaceConfiguration( playerid, raceid );
	}
	else if ( ! strcmp( params, "start", false, 5 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ],
			vehicleid = GetPlayerVehicleID( playerid ),
			Float: X, Float: Y, Float: Z, Float: A,
			countdown, Float: cpsize
		;

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You must be a race lobby host in order to use this command." );

		new
			racers = GetRaceMemberCount( raceid );

		if ( racers < 2 )
			return SendError( playerid, "You need at least 2 racers to start the race." );

		if ( g_raceData[ raceid ] [ E_RACE_FINISH_SET ] != 1 && g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE )
			return SendError( playerid, "You must set a finishing location for the race." );

		if ( g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "The race has already started." );

		if ( g_raceData[ raceid ] [ E_POOL ] < 1000 )
			return SendError( playerid, "The race must have a prize pool of at least $1,000." );

		if ( sscanf( params[ 6 ], "D(15)F(15)", countdown, cpsize ) )
			return SendUsage( playerid, "/race start [COUNT_DOWN_TIME (15)] [CHECKPOINT_SIZE (15.0)]" );

		if ( ! ( 3 <= countdown <= 60 ) )
			return SendError( playerid, "Countdown must be between 3 and 60 seconds." );

		if ( !( 3.0 <= cpsize <= 40.0 ) )
			return SendError( playerid, "The checkpoint size must be between 3.0 and 40.0" );

		GetVehiclePos( vehicleid, X, Y, Z );
		GetVehicleZAngle( vehicleid, A );

		// destroy checkpoint/icon again
		DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_START_CHECKPOINT ] );

		// place checkpoint
		g_raceData[ raceid ] [ E_START_CHECKPOINT ] = CreateDynamicRaceCP( 0, X, Y, Z, X + 20.0 * floatsin( -A, degrees ), Y + 20.0 * floatcos( -A, degrees ), Z, cpsize, -1, -1, 0 );

		// trigger started
		g_raceData[ raceid ] [ E_STARTED ] = true;

	  	// reset players in map icon/cp
	  	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_START_CHECKPOINT ], E_STREAMER_PLAYER_ID, 0 );

	  	// stream to players
		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
  			Streamer_AppendArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_START_CHECKPOINT ], E_STREAMER_PLAYER_ID, i );
  			Streamer_Update( i );
		}

		// see if racers is 2
		if ( racers == 2 && g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] != 1.0 )
		{
			new
				Float: finalIncrease = g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ] / 2.0;

			// reset profit ratio
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] += finalIncrease;
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ] += finalIncrease;
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ] = 0.0;

			// alert
			SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" As this is a two player race, the prize ratio is now %0.1f-%0.1f.", g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] * 100.0, g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ] * 100.0 );
		}

		// tax races
		g_raceData[ raceid ] [ E_POOL ] = floatround( float( g_raceData[ raceid ] [ E_POOL ] ) * 0.95 );

		// restart timer
		KillTimer( g_raceData[ raceid ] [ E_CD_TIMER ] );
		g_raceData[ raceid ] [ E_CD_TIMER ] = SetTimerEx( "OnRaceCountdown", 960, false, "dd", raceid, countdown );
		return 1;
	}
	else if ( strmatch( params, "stop" ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You must be a race lobby host in order to use this command." );

		if ( ! g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "The race must be started." );

		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has ended the race.", ReturnPlayerName( playerid ), playerid );
		return DestroyRace( raceid );
	}
	else if ( strmatch( params, "leave" ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! Iter_Contains( races, raceid ) )
			return SendError( playerid, "You are not in any race." );

		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has left the race.", ReturnPlayerName( playerid ), playerid );
		return RemovePlayerFromRace( playerid );
	}
	else if ( ! strcmp( params, "kick", false, 4 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ], kickid;

		if ( ! IsRaceHost( playerid, raceid ) ) return SendError( playerid, "You are not a lobby host for any race." );
		else if ( sscanf( params[ 5 ], "u", kickid ) ) return SendUsage( playerid, "/race kick [PLAYER]" );
		else if ( ! IsPlayerConnected( kickid ) || IsPlayerNPC( kickid ) ) return SendError( playerid, "This player is not connected." );
		else if ( p_raceLobbyId[ kickid ] != raceid ) return SendError( playerid, "This player is not in your race." );
		else
		{
	  		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has been kicked from the race.", ReturnPlayerName( kickid ), kickid );
	  		RemovePlayerFromRace( kickid );
		}
		return 1;
	}
	else if ( ! strcmp( params, "contribute", false, 10 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ], amount;

		if ( sscanf( params[ 11 ], "d", amount ) ) return SendUsage( playerid, "/race donate [AMOUNT]" );
		else if ( ! Iter_Contains( races, raceid ) ) return SendError( playerid, "You are not in any race." );
		else if ( amount < 100 ) return SendError( playerid, "The minimum contribution amount is $100." );
		else if ( amount > GetPlayerCash( playerid ) ) return SendError( playerid, "You don't have enough money to contribute that amount." );
		else
		{
			GivePlayerCash( playerid, -amount );
			g_raceData[ raceid ] [ E_POOL ] += amount;
			SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has contributed %s to the prize pool (total %s).", ReturnPlayerName( playerid ), playerid, cash_format( amount ), cash_format( g_raceData[ raceid ] [ E_POOL ] ) );
			return 1;
		}
	}
	return SendUsage( playerid, "/race [CREATE/INVITE/JOIN/LEAVE/KICK/CONFIG/START/CONTRIBUTE/STOP]" );
}

/* ** Functions ** */

stock SendClientMessageToRace( raceid, colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach(new i : Player)
	{
	    if ( p_raceLobbyId[ i ] == raceid )
			SendClientMessage( i, colour, out );
	}
	return 1;
}

function OnRaceCountdown( raceid, time )
{
	if ( raceid == -1 || ! Iter_Contains( races, raceid ) )
		return;

	foreach (new playerid : Player) if ( p_raceLobbyId[ playerid ] == raceid ) {
		if ( ! IsPlayerInDynamicRaceCP( playerid, g_raceData[ raceid ] [ E_START_CHECKPOINT ] ) ) {
			SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The race cannot be started as %s(%d) is not in the starting checkpoint.", ReturnPlayerName( playerid ), playerid );
			g_raceData[ raceid ] [ E_CD_TIMER ] = SetTimerEx( "OnRaceCountdown", 960, false, "dd", raceid, time );
			return;
		}
	}

	if ( time <= 0 )
	{
    	// destroy starting checkpoint
    	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_START_CHECKPOINT ] );
		g_raceData[ raceid ] [ E_CD_TIMER ] = -1;

    	if ( g_raceData[ raceid ] [ E_MODE ] == RACE_OUTRUN )
    	{
    		new hostid = g_raceData[ raceid ] [ E_LOBBY_HOST ];
    		new vehicleid = GetPlayerVehicleID( hostid );

    		// create sphere obj
    		g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = hostid;
    		g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] = CreateDynamicCircle( 0.0, 0.0, 10.0 );
    		g_raceData[ raceid ] [ E_OUTRUN_OBJECT ] = CreateDynamicObject( 11752, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1, -1, .playerid = 0 );
    		g_raceData[ raceid ] [ E_OUTRUN_TIMER ] = SetTimerEx( "OnRaceOutrun", 250, true, "d", raceid );

    		// attach objects
			Streamer_RemoveArrayData( STREAMER_TYPE_OBJECT, g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], E_STREAMER_PLAYER_ID, 0 );
			AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], vehicleid, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
    		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], vehicleid, 0.0, OUTRUN_DIST * 2 );

		    foreach ( new playerid : Player ) if ( p_raceLobbyId[ playerid ] == raceid )
	   		{
		    	// show checkpoint for player
	  			Streamer_AppendArrayData( STREAMER_TYPE_OBJECT, g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], E_STREAMER_PLAYER_ID, playerid );
	  			Streamer_Update( playerid );

		    	// show gametext
	    		GameTextForPlayer( playerid, "~g~GO!", 2000, 3 );
				PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );
			}
	    }
	}
	else
	{
	    foreach (new playerid : Player) if ( p_raceLobbyId[ playerid ] == raceid )
	    {
    		GameTextForPlayer( playerid, sprintf( "~y~%d", time ), 2000, 3 );
    		PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
	    }
		g_raceData[ raceid ] [ E_CD_TIMER ] = SetTimerEx( "OnRaceCountdown", 960, false, "dd", raceid, time - 1 );
	}
}

stock ShowRaceConfiguration( playerid, raceid )
{

	format( szLargeString, sizeof( szLargeString ), ""COL_WHITE"The current prize pool is %s\t \n"COL_GREY"Race Mode\t%s\n"COL_GREY"Entry Fee\t%s\n"COL_GREY"Prize Distribution\t%0.0f-%0.0f-%0.0f\n",

								cash_format( g_raceData[ raceid ] [ E_POOL ] ), g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE ? ( "Streetrace" ) : ( "Outrun" ), cash_format( g_raceData[ raceid ] [ E_ENTRY_FEE ] ),

								100.0 * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ], 100.0 * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ], 100.0 * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ]
							);

	if ( g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE ) {
		format( szLargeString, sizeof( szLargeString ), "%s"COL_GREY"Finish Destination\t%s\n", szLargeString, g_raceData[ raceid ] [ E_RACE_FINISH_SET ] == 1 ? ( ""COL_GREEN"ACTIVE" ) : ( ""COL_ORANGE"NOT SET" ) );
	} else {
		format( szLargeString, sizeof( szLargeString ), "%s"COL_GREY"Outrun Distance\t%0.1f meters\n", szLargeString, g_raceData[ raceid ] [ E_OUTRUN_DISTANCE ] );
	}

	strcat( szLargeString, ""COL_GREY"View Racers\t " );

	SetPVarInt( playerid, "editing_race", raceid );
	ShowPlayerDialog( playerid, DIALOG_RACE, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration", szLargeString, "Select", "Close" );
	return 1;
}

function OnRaceOutrun( raceid )
{
	new
		racers = 0, ahead_count = 0, lead = g_raceData[ raceid ] [ E_OUTRUN_LEAD ];

	foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid && lead != i )
	{
		// increment racers
		racers ++;

		// check if racer is ahead
		if ( GetDistanceBetweenPlayers( lead, i ) > g_raceData[ raceid ] [ E_OUTRUN_DISTANCE ] )
			ahead_count ++;
	}

	// player is ahead of all players
	if ( ahead_count == racers )
	{
		new
			position = ++ g_raceData[ raceid ] [ E_FINISHED_COUNT ];

		// give prize and alert
		if ( 1 <= position <= 3 )
			GivePlayerRaceWin( lead, position, raceid );

		// end race if position over 3 or whatever the race count is or only 1 prize
		printf ("position : %d, Racers : %d", position, racers);
		if ( position >= 3 || position >= racers ||  g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] == 1.0 )
		{
			// incase there is a final player and a remaining prize pool
			if ( g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] != 1.0 )
			{
				new
					closestRacer = GetClosestRacer( lead, raceid, .exceptid = lead );

				printf( "Yes we have a pool of %d, closest %d", g_raceData[ raceid ] [ E_POOL ], closestRacer );
				if ( IsPlayerConnected( closestRacer ) )
				{
					new
						finalPosition = ++ g_raceData[ raceid ] [ E_FINISHED_COUNT ];

					printf( "position %d", finalPosition );
					if ( 1 <= finalPosition <= 3 )
						GivePlayerRaceWin( closestRacer, finalPosition, raceid );
				}
			}
			else
			{
				SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The race has ended as there can only be one winner." );
			}

			// destroy race
			print ("Shut race");
			return DestroyRace( raceid );
		}

		// transfer leader
		else
		{
			new
				closestRacer = GetClosestRacer( lead, raceid, .exceptid = lead );

		    if ( IsPlayerConnected( closestRacer ) )
		    {
			    new
			    	iVehicle = GetPlayerVehicleID( closestRacer );

				// new leader
				g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = closestRacer;
				SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has taken the lead for the race.", ReturnPlayerName( closestRacer ), closestRacer );

				// see if ahead
				AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], iVehicle, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
	    		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], iVehicle, 0.0, OUTRUN_DIST * 2 );
			}
		}
	}
	return 1;
}

stock GetClosestRacer( playerid, raceid, exceptid = INVALID_PLAYER_ID, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = INVALID_PLAYER_ID,
        Float: fX, Float: fY,  Float: fZ, Float: fTmp
    ;

    if ( GetPlayerPos( playerid, fX, fY, fZ ) )
    {
		foreach ( new i : Player ) if ( p_raceLobbyId[ i ] == raceid && exceptid != i && GetPlayerVehicleSeat( i ) == 0 )
		{
            if ( 0.0 < ( fTmp = GetPlayerDistanceFromPoint( i, fX, fY, fZ ) ) < distance )
            {
                distance = fTmp;
                iCurrent = i;
            }
	    }
    }
    return iCurrent;
}

stock GivePlayerRaceWin( playerid, position, raceid )
{
	new
		prizeMoney = floatround( float( g_raceData[ raceid ] [ E_POOL ] ) * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ ( position - 1 ) ] );

	// give cash & reduce prize pool
	GivePlayerCash( playerid, prizeMoney );

	// announcement
	foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
		PlayerPlaySound( i, 1149, 0.0, 0.0, 0.0 );
		GameTextForPlayer( i, sprintf( "~y~~h~%d%s~w~ %s", position, positionToString( position ), ReturnPlayerName( playerid ) ), 2000, 3 );
		SendClientMessageFormatted( i, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has finished the race in %d%s position (prize %s).", ReturnPlayerName( playerid ), playerid, position, positionToString( position ), cash_format( prizeMoney ) );
	}

	// remove from race
	RemovePlayerFromRace( playerid );
}


stock DestroyRace( raceid )
{
	// remove players from race
	foreach (new playerid : Player) {
		if ( p_raceLobbyId[ playerid ] == raceid ) {
			p_raceLobbyId[ playerid ] = -1;
		}
	}

	// remove race vars
	Iter_Remove( races, raceid );
	g_raceData[ raceid ] [ E_STARTED ] = false;

	// destroy race cps
	DestroyDynamicObject( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ] ), g_raceData[ raceid ] [ E_OUTRUN_OBJECT ] = -1;
	DestroyDynamicArea( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] ), g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] = -1;
	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_START_CHECKPOINT ] ), g_raceData[ raceid ] [ E_START_CHECKPOINT ] = -1;
	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] ), g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] = -1;
	DestroyDynamicMapIcon( g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] ), g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] = -1;
	KillTimer( g_raceData[ raceid ] [ E_OUTRUN_TIMER ] ), g_raceData[ raceid ] [ E_OUTRUN_TIMER ] = -1;
	return 1;
}

stock RemovePlayerFromRace( playerid )
{
	new
		newLeader = INVALID_PLAYER_ID,
		raceid = p_raceLobbyId[ playerid ]
	;

	if ( ! Iter_Contains( races, raceid ) )
		return 0;

	// hide checkpoints
	Streamer_RemoveArrayData( STREAMER_TYPE_OBJECT, g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], E_STREAMER_PLAYER_ID, playerid );
	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_START_CHECKPOINT ], E_STREAMER_PLAYER_ID, playerid );
	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, playerid );
	Streamer_RemoveArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, playerid );

	// kick player out
	p_raceLobbyId[ playerid ] = -1;

	// assign new leader if possible
	if ( g_raceData[ raceid ] [ E_LOBBY_HOST ] == playerid )
	{
		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
			newLeader = i;
			break;
		}

		if ( IsPlayerConnected( newLeader ) )
		{
			g_raceData[ raceid ] [ E_LOBBY_HOST ] = newLeader;
			// SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) is the new lobby host.", ReturnPlayerName( newLeader ), newLeader );
		}
		else
		{
			printf("Destroyed empty race lobby %d", raceid);
			DestroyRace( raceid );
		}
	}

	// maybe the outrun lead left
	else if ( g_raceData[ raceid ] [ E_MODE ] == RACE_OUTRUN && g_raceData[ raceid ] [ E_OUTRUN_LEAD ] == playerid )
	{
		new
			closestRacer = GetClosestRacer( playerid, raceid, .exceptid = playerid );

	    if ( IsPlayerConnected( closestRacer ) )
	    {
		    new
		    	iVehicle = GetPlayerVehicleID( closestRacer );

			// new leader
			g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = closestRacer;
			SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has taken the lead for the race.", ReturnPlayerName( closestRacer ), closestRacer );

			// see if ahead
			AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], iVehicle, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
    		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], iVehicle, 0.0, OUTRUN_DIST * 2 );
		}
		else
		{
			SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The race has ended as a new leader couldn't be set." );
			DestroyRace( raceid );
		}
	}
	return 1;
}

stock GetRaceMemberCount( raceid ) {
	new
		count = 0;

	foreach (new playerid : Player) if ( p_raceLobbyId[ playerid ] == raceid ) {
		count ++;
	}
	return count;
}

stock SetRaceDestination( raceid, Float: fX, Float: fY, Float: fZ)
{
	// set race position
	g_raceData[ raceid ] [ E_FINISH_POS ] [ 0 ] = fX;
	g_raceData[ raceid ] [ E_FINISH_POS ] [ 1 ] = fY;
	g_raceData[ raceid ] [ E_FINISH_POS ] [ 2 ] = fZ;
	g_raceData[ raceid ] [ E_RACE_FINISH_SET ] = 1;

	// destroy checkpoint/icon again
	DestroyDynamicMapIcon( g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] );
	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] );

	// place checkpoint
	g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] = CreateDynamicMapIcon( fX, fY, fZ, 53, -1, -1, -1, 0, 6000.0, MAPICON_GLOBAL );
	g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] = CreateDynamicRaceCP( 1, g_raceData[ raceid ] [ E_FINISH_POS ] [ 0 ], g_raceData[ raceid ] [ E_FINISH_POS ] [ 1 ], g_raceData[ raceid ] [ E_FINISH_POS ] [ 2 ], 0, 0, 0, 5.0, -1, -1, 0 );

  	// reset players in map icon/cp
  	Streamer_RemoveArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, 0 );
  	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, 0 );

  	// stream to players
	foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
		Streamer_AppendArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, i );
		Streamer_AppendArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, i );
	}
}

stock IsRaceHost( playerid, raceid ) {
	if ( raceid == -1 || ! Iter_Contains( races, raceid ) )
		return false;

	return g_raceData[ raceid ] [ E_LOBBY_HOST ] == playerid;
}
