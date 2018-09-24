/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: cnr/features/duel.pwn
 * Purpose: player duling system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define COL_DUEL 					"{B74AFF}"

#define DIALOG_DUEL 				7360
#define DIALOG_DUEL_PLAYER			7361
#define DIALOG_DUEL_LOCATION		7362
#define DIALOG_DUEL_WEAPON			7363
#define DIALOG_DUEL_WAGER			7364
#define DIALOG_DUEL_WEAPON_TWO 		7365
#define DIALOG_DUEL_HEALTH 			7366
#define DIALOG_DUEL_ARMOUR			7367

/* ** Variables ** */
enum E_DUEL_DATA
{
	E_PLAYER,						E_WEAPON[ 2 ],						E_BET,
	Float: E_ARMOUR, 				Float: E_HEALTH, 					E_COUNTDOWN,
	E_TIMER, 						E_LOCATION_ID, 						E_ROUNDS,
};

enum E_DUEL_LOCATION_DATA
{
	E_NAME [ 19 ],					Float: E_POS_ONE[ 3 ], 				Float: E_POS_TWO[ 3 ]
};

new
	Float: g_DuelCoordinates 		[ 3 ] = 							{ -2226.1938, 251.9206, 35.3203 },
	g_WeaponList					[ ] = 								{ 0, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34 },
	g_duelData 						[ MAX_PLAYERS ][ E_DUEL_DATA ],
	g_duelLocationData 				[ ][ E_DUEL_LOCATION_DATA ] =
	{
		{ "Santa Maria Beach",		{ 369.75770, -1831.576, 7.67190 }, { 369.65890, -1871.215, 7.67190 }},
		{ "Greenglass College",		{ 1078.0353, 1084.4989, 10.8359 }, { 1095.4019, 1064.7239, 10.8359 }},
		{ "Baseball Arena",			{ 1393.0995, 2177.4585, 9.75780 }, { 1377.7881, 2195.4214, 9.75780 }},
		//{"The Visage",			{ 1960.4512, 1907.6881, 130.937 }, { 1969.4047, 1923.2622, 130.937 }},
		{ "Mount Chilliad",			{ -2318.471, -1632.880, 483.703 }, { -2329.174, -1604.657, 483.760 }},
		{ "The Farm",				{ -1044.856, -996.8120, 129.218 }, { -1125.599, -996.7523, 129.218 }},
		{ "Tennis Courts",			{ 755.93790, -1280.710, 13.5565 }, { 755.93960, -1238.688, 13.5516 }},
		{ "Underwater World",		{ 520.59600, -2125.663, -28.257 }, { 517.96600, -2093.610, -28.257 }},
		{ "Grove Street",			{ 2476.4580, -1668.631, 13.3249 }, { 2501.1560, -1667.655, 13.3559 }},
		{ "Ocean Docks",			{ 2683.5440, -2485.137, 13.5425 }, { 2683.8470, -2433.726, 13.5553 }}
	},


	bool: p_playerDueling			[ MAX_PLAYERS char ],
	p_duelInvitation           		[ MAX_PLAYERS ][ MAX_PLAYERS ],

	g_DuelCheckpoint				= -1
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	CreateDynamicMapIcon( g_DuelCoordinates[ 0 ], g_DuelCoordinates[ 1 ], g_DuelCoordinates[ 2 ], 23, 0, -1, -1, -1, 750.0 );
	g_DuelCheckpoint = CreateDynamicCP( g_DuelCoordinates[ 0 ], g_DuelCoordinates[ 1 ], g_DuelCoordinates[ 2 ], 1.5, 0, 0, -1 );
	CreateDynamic3DTextLabel( ""COL_GOLD"[DUEL PLAYER]", -1, g_DuelCoordinates[ 0 ], g_DuelCoordinates[ 1 ], g_DuelCoordinates[ 2 ], 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1 );
	
	return 1;
}

hook OnPlayerConnect( playerid )
{
	p_playerDueling{ playerid } 				= false;
	g_duelData[ playerid ][ E_PLAYER ] 			= INVALID_PLAYER_ID;
	g_duelData[ playerid ][ E_WEAPON ][ 0 ] 	= 0;
	g_duelData[ playerid ][ E_WEAPON ][ 1 ] 	= 0;
	g_duelData[ playerid ][ E_HEALTH ] 			= 100.0;
	g_duelData[ playerid ][ E_ARMOUR ] 			= 100.0;
	g_duelData[ playerid ][ E_BET ] 			= 0;
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	forfeitPlayerDuel( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx(playerid, killerid, reason, Float: damage, bodypart)
#else
hook OnPlayerDeath(playerid, killerid, reason)
#endif
{
	forfeitPlayerDuel( playerid );
	return 1;
}

hook SetPlayerRandomSpawn( playerid )
{
	if ( IsPlayerDueling( playerid ))
	{
		// teleport back to pb
		SetPlayerPos( playerid, g_DuelCoordinates[0], g_DuelCoordinates[1], g_DuelCoordinates[2] );
		SetPlayerInterior( playerid, 0 );
		SetPlayerVirtualWorld( playerid, 0 );

		// reset duel variables
		p_playerDueling{ playerid } 		= false;
		g_duelData[ playerid ][ E_PLAYER ] 	= INVALID_PLAYER_ID;
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( GetPlayerState( playerid ) == PLAYER_STATE_SPECTATING ) {
		return 1;
	}

	if ( checkpointid == g_DuelCheckpoint )
	{
		ShowPlayerDuelMenu( playerid );
		return 1;
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[] )
{
	if ( ( dialogid == DIALOG_DUEL ) && response )
	{
		erase ( szBigString );

		switch ( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_GREY"Note: You can enter partially their names.", "Select", "Back");
			case 1: ShowPlayerDialog( playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Health", ""COL_WHITE"Enter the amount of health you will begin with:\n\n"COL_GREY"Note: The default health is 100.0.", "Select", "Back");
			case 2: ShowPlayerDialog( playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Armour", ""COL_WHITE"Enter the amount of armour you will begin with:\n\n"COL_GREY"Note: The default armour is 100.0.", "Select", "Back");

			case 3:
			{
				new
					iWeapon = g_duelData [ playerid ] [ E_WEAPON ] [ 0 ];

				for ( new i = 0; i < sizeof( g_WeaponList ); i ++) {
					format( szBigString, sizeof( szBigString ), "%s%s%s\n", szBigString, iWeapon == g_WeaponList [ i ] ? ( COL_GREY ) : ( COL_WHITE ), ReturnWeaponName( g_WeaponList[ i ] ) );
				}

				ShowPlayerDialog( playerid, DIALOG_DUEL_WEAPON, DIALOG_STYLE_LIST, ""COL_WHITE"Duel Settings - Change Primary Weapon", szBigString, "Select", "Back");
			}

			case 4:
			{
				new
					iWeapon = g_duelData [ playerid ] [ E_WEAPON ] [ 1 ];

				for ( new i = 0; i < sizeof( g_WeaponList ); i ++ ) {
					format( szBigString, sizeof( szBigString ), "%s%s%s\n", szBigString, iWeapon == g_WeaponList [ i ] ? ( COL_GREY ) : ( COL_WHITE ), ReturnWeaponName( g_WeaponList [ i ]) );
				}

				ShowPlayerDialog( playerid, DIALOG_DUEL_WEAPON_TWO, DIALOG_STYLE_LIST, ""COL_WHITE"Duel Settings - Change Secondary Weapon", szBigString, "Select", "Back");
			}

			case 5:
			{
				new
					iLocationID = g_duelData [ playerid ][ E_LOCATION_ID ];

				for ( new i = 0; i < sizeof( g_duelLocationData ); i ++ ) {
					format( szBigString, sizeof( szBigString ), "%s%s%s\n", szBigString, iLocationID == i ? ( COL_GREY ) : ( COL_WHITE ), g_duelLocationData[ i ][ E_NAME ] );
				}

				ShowPlayerDialog(playerid, DIALOG_DUEL_LOCATION, DIALOG_STYLE_LIST, ""COL_WHITE"Duel Settings - Change Location", szBigString, "Select", "Back");
			}

			case 6: ShowPlayerDialog(playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Set A Wager", ""COL_WHITE"Please enter the wager for this duel:", "Select", "Back");

			case 7:
			{
				new
					pID = g_duelData [ playerid ][ E_PLAYER ];

				if ( !IsPlayerConnected( pID ) )
				{
					SendError( playerid, "You haven't selected anyone to duel!" );
					return ShowPlayerDuelMenu( playerid );
				}

				p_duelInvitation[ playerid ][ pID ] = gettime( ) + 60;
				ShowPlayerHelpDialog( pID, 10000, "%s wants to duel!~n~~n~~y~Location: ~w~%s~n~~y~Weapon: ~w~%s and %s~n~~y~Wager: ~w~%s", ReturnPlayerName( playerid ), g_duelLocationData [ g_duelData[ playerid ][ E_LOCATION_ID ] ][ E_NAME ], ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 0 ] ), ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 1 ] ), cash_format(g_duelData[ playerid ][ E_BET ]));
				SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have sent a duel invitation to %s for "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( pID ), cash_format( g_duelData[ playerid ][ E_BET ] ) );
				SendClientMessageFormatted( pID, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You are invited to duel %s for "COL_GOLD"%s"COL_WHITE", use \"/duel accept %d\".", ReturnPlayerName( playerid ), cash_format( g_duelData[ playerid ][ E_BET ] ), playerid );
			}
		}
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_PLAYER )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			pID
		;

		if ( sscanf( inputtext, "u", pID) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_GREY"Note: You can enter partially their names.", "Select", "Back" );

		if ( pID == playerid )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_RED"You can't invite yourself to duel!", "Select", "Back" );

		if ( pID == INVALID_PLAYER_ID || !IsPlayerConnected( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_RED"Player is not connected!", "Select", "Back" );

		if ( IsPlayerDueling( playerid ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_RED"You are already in a duel!", "Select", "Back" );

		if ( IsPlayerDueling( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_RED"This player is already in a duel!", "Select", "Back" );

		if ( GetPlayerWantedLevel( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_RED"You can't duel this person right now, they are wanted", "Select", "Back" );

		if ( GetDistanceBetweenPlayers( playerid, pID ) > 25.0 )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_RED"The player you wish to duel is not near you.", "Select", "Back" );

		if ( IsPlayerJailed( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Select a Player", ""COL_WHITE"Please type the name of the player you wish to duel:\n\n"COL_RED"You can't duel this person right now, they are currently in jail.", "Select", "Back" );

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have selected {C0C0C0}%s {FFFFFF}as your opponent.", ReturnPlayerName( pID ) );

		g_duelData[ playerid ][ E_PLAYER ] = pID;
		return ShowPlayerDuelMenu( playerid ), 1;
	}

	else if ( dialogid == DIALOG_DUEL_LOCATION )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		if ( g_duelData[ playerid ][ E_LOCATION_ID ] == listitem )
		{
			SendError( playerid, "You have already selected this location!" );
			return ShowPlayerDuelMenu( playerid );
		}

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have changed the duel location to {C0C0C0}%s{FFFFFF}.", g_duelLocationData [ listitem ][ E_NAME ]);

		g_duelData[ playerid ][ E_LOCATION_ID ] = listitem;
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_WEAPON )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		if ( g_duelData[ playerid ][ E_WEAPON ][ 0 ] == g_WeaponList[ listitem ] )
		{
			SendError( playerid, "You have already selected this weapon!");
			return ShowPlayerDuelMenu( playerid );
		}

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have changed Primary Weapon to {C0C0C0}%s{FFFFFF}.", ReturnWeaponName( g_WeaponList[ listitem ]) );
		g_duelData[ playerid ][ E_WEAPON ][ 0 ] = g_WeaponList[ listitem ];
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_WEAPON_TWO )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		if ( g_duelData[ playerid ][ E_WEAPON ][ 1 ] == g_WeaponList[ listitem ] )
		{
			SendError( playerid, "You have already selected this weapon!");
			return ShowPlayerDuelMenu( playerid );
		}

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have changed Secondary Weapon to {C0C0C0}%s{FFFFFF}.", ReturnWeaponName( g_WeaponList[ listitem ]) );
		g_duelData[ playerid ][ E_WEAPON ][ 1 ] = g_WeaponList[ listitem ];
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_HEALTH )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			Float: fHealth;

		if ( sscanf( inputtext, "f", fHealth ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Health", ""COL_WHITE"Enter the amount of health you will begin with:\n\n"COL_GREY"Note: The default health is 100.0.", "Select", "Back" );

		if ( !( 1.0 <= fHealth <= 100.0 ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Health", ""COL_WHITE"Enter the amount of health you will begin with:\n\n"COL_RED"The amount you have entered is a invalid amount, 1 to 100 only!", "Select", "Back" );

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have changed Health to {C0C0C0}%0.2f%%"COL_WHITE".", fHealth);
		g_duelData[ playerid ][ E_HEALTH ] = fHealth;
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_ARMOUR)
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			Float: fArmour;

		if ( sscanf( inputtext, "f", fArmour ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Armour", ""COL_WHITE"Enter the amount of armour you will begin with:\n\n"COL_GREY"Note: The default armour is 100.0.", "Select", "Back" );

		if ( !( 0.0 <= fArmour <= 100.0 ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Armour", ""COL_WHITE"Enter the amount of armour you will begin with:\n\n"COL_RED"The amount you have entered is a invalid amount, 0 to 100 only!", "Select", "Back" );

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have changed Armour to {C0C0C0}%0.2f%%"COL_WHITE".", fArmour );
		g_duelData[ playerid ][ E_ARMOUR ] = fArmour;
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_WAGER)
	{
		if ( IsPlayerDueling( playerid ) ) // prevent spawning money
			return SendError( playerid, "You cannot use this at the moment." );

		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			iBet
		;

		if ( sscanf( inputtext, "d", iBet ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Set A Wager", ""COL_WHITE"Please enter the wager for this duel:", "Select", "Back");

		if ( ! ( 0 <= iBet < 10000000 ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, ""COL_WHITE"Duel Settings - Set A Wager", ""COL_WHITE"Please enter the wager for this duel:\n\n"COL_RED"Wagers must be between $0 and $10,000,000.", "Select", "Back");

		g_duelData[playerid][ E_BET ] = iBet;
		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have changed the wager to %s.", cash_format(g_duelData[playerid][ E_BET ]));
		ShowPlayerDuelMenu( playerid );
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:duel( playerid, params[ ] )
{
	if ( !strcmp(params, "accept", false, 6))
	{
		new
			targetid;

		if ( sscanf( params[7], "u", targetid) )
			return SendUsage( playerid, "/duel accept [PLAYER_ID]");

		if ( !IsPlayerConnected( targetid ))
			return SendError( playerid, "You do not have any duel invitations to accept.");

		if ( gettime() > p_duelInvitation[ targetid ][ playerid ] )
			return SendError( playerid, "You have not been invited by %s to duel or it has expired.");

		if ( IsPlayerDueling( playerid ))
			return SendError( playerid, "You cannot accept this invite as you are currently dueling.");

		if ( GetDistanceBetweenPlayers( playerid, targetid ) > 25.0)
			return SendError( playerid, "You must be within 25.0 meters of your opponent!");

		new
			waged_amount = g_duelData[ targetid ][ E_BET ];

		if (g_duelData[ targetid ][ E_BET ] != 0)
		{
			if ( GetPlayerCash( targetid ) < waged_amount)
			{
				SendClientMessageFormatted( targetid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" %s has accepted but you don't have money to wage (%s).", ReturnPlayerName( playerid ), cash_format( waged_amount ) );
				SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have accepted %s's duel invitation but they don't have money.", ReturnPlayerName( targetid ) );
				return 1;
			}
			else if ( GetPlayerCash( playerid ) < waged_amount)
			{
				SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" %s requires you to wage %s.", ReturnPlayerName( targetid ), cash_format( waged_amount ) );
				SendClientMessageFormatted( targetid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" %s has accepted the duel invitation but they don't have money to wage.", ReturnPlayerName( playerid ) );
				return 1;
			}
			else
			{
				GivePlayerCash( playerid, -waged_amount );
				GivePlayerCash( targetid, -waged_amount );
			}
		}

		SendClientMessageFormatted( targetid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" %s has accepted your duel invitation.", ReturnPlayerName( playerid ) );
		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[DUEL]"COL_WHITE" You have accepted %s's duel invitation.", ReturnPlayerName( targetid ) );

		p_playerDueling{ targetid } = true;
		p_playerDueling{ playerid } = true;

		g_duelData[ targetid ][ E_PLAYER ] = playerid;
		g_duelData[ playerid ][ E_PLAYER ] = targetid;
		g_duelData[ playerid ][ E_BET ] = g_duelData[targetid][ E_BET ];
		g_duelData[ playerid ][ E_ROUNDS ] = 1;
		g_duelData[ targetid ][ E_ROUNDS ] = 1;

		new
			iLocation = g_duelData[ targetid ][ E_LOCATION_ID ];

		ResetPlayerWeapons( targetid );
		RemovePlayerFromVehicle( targetid );
		SetPlayerArmour( targetid, g_duelData[ targetid ][ E_ARMOUR ]);
		SetPlayerHealth( targetid, g_duelData[ targetid ][ E_HEALTH ]);
		SetPlayerVirtualWorld( targetid, targetid + 1 );
		SetPlayerPos( targetid, g_duelLocationData[ iLocation ][ E_POS_TWO ][0], g_duelLocationData[ iLocation ][ E_POS_TWO ][1], g_duelLocationData[ iLocation ][ E_POS_TWO ][2] );

		ResetPlayerWeapons( playerid );
		RemovePlayerFromVehicle( playerid );
		SetPlayerArmour( playerid, g_duelData[ targetid ][ E_ARMOUR ]);
		SetPlayerHealth( playerid, g_duelData[ targetid ][ E_HEALTH ]);
		SetPlayerVirtualWorld( playerid, targetid + 1 );
		SetPlayerPos( playerid, g_duelLocationData[ iLocation ][ E_POS_ONE ][0], g_duelLocationData[ iLocation ][ E_POS_ONE ][1], g_duelLocationData[ iLocation ][ E_POS_ONE ][2] );

		// freeze
		TogglePlayerControllable( playerid, 0 );
		TogglePlayerControllable( targetid, 0 );

		// start countdown
		g_duelData[ targetid ][ E_COUNTDOWN ] = 10;
		g_duelData[ targetid ][ E_TIMER ] = SetTimerEx( "OnDuelTimer", 960, true, "d", targetid );

		// give weapon
		GivePlayerWeapon( playerid, g_duelData[ targetid ][ E_WEAPON ][0], 5000);
		GivePlayerWeapon( targetid, g_duelData[ targetid ][ E_WEAPON ][0], 5000);
		GivePlayerWeapon( playerid, g_duelData[ targetid ][ E_WEAPON ][1], 5000);
		GivePlayerWeapon( targetid, g_duelData[ targetid ][ E_WEAPON ][1], 5000);

		// clear invites for safety
		for (new i = 0; i < MAX_PLAYERS; i ++) {
			p_duelInvitation[ playerid ][ i ] = 0;
			p_duelInvitation[ targetid ][ i ] = 0;
		}
		return 1;
	}
	else if (strmatch(params, "cancel"))
	{
		if ( ClearDuelInvites( playerid ))
		{
			return SendServerMessage( playerid, "You have cancelled every duel offer that you have made." );
		}
		else
		{
			return SendError( playerid, "You have not made any duel offers recently." );
		}
	}
	return SendUsage( playerid, "/duel [ACCEPT/CANCEL]" );
}

/* ** Functions ** */
static stock ClearDuelInvites( playerid )
{
	new current_time = gettime( );
	new count = 0;

	for ( new i = 0; i < MAX_PLAYERS; i ++ )
	{
		if ( p_duelInvitation[ playerid ][ i ] != 0 && current_time > p_duelInvitation[ playerid ][ i ])
		{
			p_duelInvitation[ playerid ][ i ] = 0;
			count ++;
		}
	}
	return count;
}

stock IsPlayerDueling( playerid ) {
	return p_playerDueling{ playerid };
}

stock ShowPlayerDuelMenu(playerid)
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN )
		return SendError( playerid, "You can only use this feature whist being a civilian.");

	if ( p_WantedLevel[ playerid ] > 0 )
		return SendError( playerid, "You cannot duel whilst having a wanted level.");

	format( szBigString, sizeof(szBigString),
		"Player\t"COL_GREY"%s\nHealth\t"COL_GREY"%.2f%%\nArmour\t"COL_GREY"%.2f%%\nPrimary Weapon\t"COL_GREY"%s\nSecondary Weapon\t"COL_GREY"%s\nLocation\t"COL_GREY"%s\nWager\t"COL_GREY"%s\n"COL_GOLD"Send Invite\t"COL_GOLD">>>",
		(!IsPlayerConnected(g_duelData[ playerid ][ E_PLAYER ]) ? (""COL_RED"No-one") : (ReturnPlayerName( g_duelData[ playerid ][ E_PLAYER ] ) ) ),
		g_duelData[ playerid ][ E_HEALTH ],
		g_duelData[ playerid ][ E_ARMOUR ],
		ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 0 ] ),
		ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 1 ] ),
		g_duelLocationData[ g_duelData[ playerid ][ E_LOCATION_ID ] ][ E_NAME ],
		cash_format( g_duelData[ playerid ][ E_BET ] )
	);

	ShowPlayerDialog(playerid, DIALOG_DUEL, DIALOG_STYLE_TABLIST, ""COL_WHITE"Duel Settings", szBigString, "Select", "Cancel");
	return 1;
}

static stock forfeitPlayerDuel(playerid)
{
	if ( !IsPlayerDueling( playerid ))
		return 0;

	ClearDuelInvites( playerid );

	new
		winnerid = g_duelData[ playerid ][ E_PLAYER ];

	if ( ! IsPlayerConnected( winnerid ) || ! IsPlayerDueling( winnerid ))
		return 0;

	// begin wager info
	new
		amount_waged = g_duelData[ playerid ][ E_BET ];

	SpawnPlayer(winnerid);
	ClearDuelInvites(winnerid);

	// decrement rounds
	g_duelData[ playerid ][ E_ROUNDS ] --;
	g_duelData[ winnerid ][ E_ROUNDS ] = g_duelData[ playerid ][ E_ROUNDS ];

	// check if theres a remaining round
	if (g_duelData[ playerid ][ E_ROUNDS ] == 0)
	{
		if ( 0 < amount_waged < 10000000 )
		{
			new
				winning_prize = floatround( float( amount_waged ) * 1.95 ); // We take 2.5% of the total pot
			
			GivePlayerCash( winnerid, winning_prize );
			SendClientMessageToAllFormatted( -1, ""COL_DUEL"[DUEL]"COL_WHITE" %s(%d) has won the duel against %s(%d) for %s!", ReturnPlayerName( winnerid ), winnerid, ReturnPlayerName( playerid ), playerid, cash_format( winning_prize ) );
		}
		else
		{
			SendClientMessageToAllFormatted( -1, ""COL_DUEL"[DUEL]"COL_WHITE" %s(%d) has won the duel against %s(%d)!", ReturnPlayerName( winnerid ), winnerid, ReturnPlayerName( playerid ), playerid );
		}
	}
	return 1;
}

function OnDuelTimer(targetid)
{
	new
		playerid = g_duelData[targetid][ E_PLAYER ];

	g_duelData[ targetid ][ E_COUNTDOWN ] --;

	if ( g_duelData[ targetid ][ E_COUNTDOWN ] <= 0)
	{
		GameTextForPlayer( targetid, "~g~~h~FIGHT!", 1500, 4 );
		GameTextForPlayer( playerid, "~g~~h~FIGHT!", 1500, 4 );

		PlayerPlaySound( targetid, 1057, 0.0, 0.0, 0.0 );
		PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );

		TogglePlayerControllable( playerid, 1 );
		TogglePlayerControllable( targetid, 1 );

		KillTimer( g_duelData[ targetid ][ E_TIMER ] );
	}
	else
	{
		format(szSmallString, sizeof(szSmallString), "~w~%d", g_duelData[ targetid ][ E_COUNTDOWN ]);
		GameTextForPlayer( targetid, szSmallString, 1500, 4 );
		GameTextForPlayer( playerid, szSmallString, 1500, 4 );

		PlayerPlaySound( targetid, 1056, 0.0, 0.0, 0.0 );
		PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
	}
	return 1;
}
