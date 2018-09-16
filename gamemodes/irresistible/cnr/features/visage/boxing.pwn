/*
 * Irresistible Gaming (c) 2018
 * Developed by Damen, Lorenc
 * Module: Boxing
 * Purpose: Boxing for Visage
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define IsPlayerBoxing(%0) 			(g_boxingPlayerData[ %0 ] [ E_FIGHTING ])
#define SendBoxing(%0,%1) 			(SendClientMessageFormatted( %0, -1, "{B74AFF}[BOXING] {FFFFFF}" # %1))
#define SendBoxingGlobal(%0) 		(SendClientMessageFormatted( INVALID_PLAYER_ID, -1, "{B74AFF}[BOXING] {FFFFFF}" # %0))
#define IsPlayerNearBoxingArena(%0) (GetPlayerDistanceFromPoint( %0, 2654.885986, 1613.157958, 1506.269042 ) < 25.0)

/* ** Variables ** */
enum E_BOXER_DATA {
	bool: E_FIGHTING,
	E_OPPONENT,
	bool: E_INVITED,
	E_INVITE_TIMESTAMP,
	E_ROUNDS_SET,
	E_BET_AMOUNT_SET,
	bool: E_IS_HOST,
	E_SCORE,
	Float: E_PRIOR_HEALTH,
	Float: E_PRIOR_ARMOUR,
	E_PRIOR_WEP[ 12 ],
	E_PRIOR_WEP_AMMO[ 12 ],
	E_PRIOR_SKIN
};

enum E_ARENA_DATA {
	bool: E_OCCUPIED,
	E_CD_TIMER,
	E_CURRENT_ROUNDS,
	E_ROUNDS,
	E_BET
};

new g_boxingPlayerData 				[ MAX_PLAYERS ] [ E_BOXER_DATA ];
new g_boxingArenaData 				[ E_ARENA_DATA ];
new Text3D: arenaLabel 				= Text3D: INVALID_3DTEXT_ID;

/* ** Hooks ** */
hook OnGameModeInit( ) {
	print( "-> Boxing System - By: Damen" );
	arenaLabel = CreateDynamic3DTextLabel( "Boxing Arena\n{FFFFFF}/boxing fight", COLOR_GREY, 2655.3022, 1613.6146, 1507.0977, 15.0 );
	return 1;
}

hook OnPlayerConnect( playerid ) {
	g_boxingPlayerData[ playerid ] [ E_FIGHTING ] = false;
	g_boxingPlayerData[ playerid ] [ E_OPPONENT ] = -1;
	g_boxingPlayerData[ playerid ] [ E_INVITED ] = false;
	g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] = 1;
	g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] = 0;
	g_boxingPlayerData[ playerid ] [ E_IS_HOST ] = false;
	g_boxingPlayerData[ playerid ] [ E_SCORE ] = 0;
	return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
	boxing_ForfeitMatch( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	boxing_ForfeitMatch( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] );
	// printf("BOXING MATCH DEATH BY %s -> RETURN %d", ReturnPlayerName(playerid), );
	return 1;
}

/* ** Commands ** */
CMD:boxing( playerid, params[ ] ) {

	if ( !IsPlayerNearBoxingArena( playerid ) )
		return SendError( playerid, "You must be within 25 meters of the arena to use this command." );

	if ( g_boxingArenaData[ E_OCCUPIED ] == true )
		return SendError( playerid, "The arena is currently occupied. Please wait for the arena to clear." );

	if ( GetPlayerWantedLevel( playerid ) )
		return SendError( playerid, "You cannot box while you are currently wanted." );

	if ( !strcmp( params, "fight", true, 5 ) ) {

		new targetID, betAmount, rounds;

		if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true )
			return SendError( playerid, "You are currently fighting an opponent. Please finish your fight." );

		if ( sscanf( params[ 6 ], "uD(0)D(3)", targetID, betAmount, rounds ) )
			return SendUsage( playerid, "/boxing fight [PLAYER_ID] [BET_AMOUNT (0)] [ROUNDS (3)]" );

		if ( ! IsPlayerConnected( targetID ) )
			return SendError( playerid, "Player is not connected." );

		if ( targetID == playerid )
			return SendError( playerid, "You cannot invite yourself to a boxing match." );

		if ( !IsPlayerNearBoxingArena( targetID ) )
			return SendError( playerid, "The player you have invited to a boxing match is not near the boxing arena." );

		if ( GetPlayerCash( targetID ) < betAmount )
			return SendError( playerid, "The player you invited does not have enough money to wager that amount." );

		if ( ! ( 0 <= betAmount <= 10000000 ) )
			return SendError( playerid, "Please specify an amount between $0 and $10,000,000." );

		if ( rounds != 1 && rounds != 3 && rounds != 5 && rounds != 9 )
			return SendError( playerid, "Please choose between 1, 3, 5, or 9 rounds." );

		if ( g_boxingPlayerData[ targetID ] [ E_INVITED ] == true )
			return SendError( playerid, "That player has already been invited to a fight." );

		if ( g_boxingPlayerData[ targetID ] [ E_FIGHTING ] == true )
			return SendError( playerid, "That player is currently fighting another opponent. Please wait until after their match to reinvite them." );

		if ( GetPlayerWantedLevel( targetID ) )
			return SendError( playerid, "You cannot box a wanted player." );

		if ( g_boxingPlayerData[ playerid ] [ E_INVITED ] == true ) {
			SendBoxing( playerid, "You have cancelled your invite to %s.", ReturnPlayerName( g_boxingPlayerData[ playerid ] [ E_OPPONENT ] ) );
			SendBoxing( g_boxingPlayerData[ playerid ] [ E_OPPONENT ], "%s has cancelled the match invite.", ReturnPlayerName( playerid ) );
			ResetBoxingPlayerVariables( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] );
		}

		g_boxingPlayerData[ playerid ] [ E_INVITED ] = true;
		g_boxingPlayerData[ playerid ] [ E_OPPONENT ] = targetID;
		g_boxingPlayerData[ playerid ] [ E_IS_HOST ] = true;
		g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] = rounds;
		g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] = betAmount;
		g_boxingPlayerData[ targetID ] [ E_INVITED ] = true;
		g_boxingPlayerData[ targetID ] [ E_OPPONENT ] = playerid;
		g_boxingPlayerData[ targetID ] [ E_INVITE_TIMESTAMP ] = GetServerTime( ) + 30000;

		if ( g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] == 0 ) {

			SendBoxing( playerid, "You have invited %s to a boxing match with no wager through %i round(s).", ReturnPlayerName( targetID ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( playerid, "To cancel your invite, use /boxing [CANCEL]." );

			SendBoxing( targetID, "%s has invited you to a boxing match with no wager through %i round(s).", ReturnPlayerName( playerid ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( targetID, "To accept or decline the invite, use /boxing [ACCEPT/DECLINE]." );

		} else {

			SendBoxing( playerid, "You have invited %s to a boxing match with a %s wager through %i round(s).", ReturnPlayerName( targetID ), cash_format( g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( playerid, "To cancel your invite, use /boxing [CANCEL]." );

			SendBoxing( targetID, "%s has invited you to a boxing match with a %s wager through %i round(s).", ReturnPlayerName( playerid ), cash_format( g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( targetID, "To accept or decline the invite, use /boxing [ACCEPT/DECLINE]." );

		}
		return 1;

	} else if ( !strcmp( params, "cancel", true, 6 ) ) {

		new opponent = g_boxingPlayerData[ playerid ] [ E_OPPONENT ];

		if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true )
			return SendError( playerid, "You're currently in a boxing match. Use /boxing [FORFEIT] if you would like to forfeit the match." );

		if ( g_boxingPlayerData[ playerid ] [ E_IS_HOST ] == false )
			return SendError( playerid, "You have no boxing match invites to cancel." );

		SendBoxing( opponent, "%s has cancelled the boxing match invitation.", ReturnPlayerName( playerid ) );
		SendBoxing( playerid, "You have cancelled the boxing match invitation sent to %s.", ReturnPlayerName( opponent ) );
		ResetBoxingPlayerVariables( playerid, opponent );
		return 1;

	} else if ( !strcmp( params, "accept", true, 6 ) ) {

		new opponent = g_boxingPlayerData[ playerid ] [ E_OPPONENT ];

		if ( GetServerTime( ) > g_boxingPlayerData[ playerid ] [ E_INVITE_TIMESTAMP ] && g_boxingPlayerData[ playerid ] [ E_INVITED ] ) {
			SendServerMessage( opponent, "%s has attempted to accept your boxing invite after it has expired.", ReturnPlayerName( playerid ) );
			ResetBoxingPlayerVariables( playerid, opponent );
			return SendError( playerid, "This invitation has expired." );
		}

		if ( g_boxingPlayerData[ playerid ] [ E_INVITED ] == false )
			return SendError( playerid, "You do not have any boxing match invitations to accept." );

		if ( opponent == -1 )
			return SendError( playerid, "Your opponent is no longer available to fight." );

		if ( !IsPlayerNearBoxingArena( opponent ) ) {

			SendError( playerid, "%s is no longer near the arena. Your invitation has been cancelled.", ReturnPlayerName( opponent ) );
			SendBoxing( opponent, "%s has attempted to accept your invite while you were not near the arena.", ReturnPlayerName( playerid ) );
			return ResetBoxingPlayerVariables( playerid, opponent );

		}

		if ( GetPlayerCash( playerid ) < g_boxingPlayerData[ opponent ] [ E_BET_AMOUNT_SET ] ) {

			SendError( playerid, "You do not have enough money to participate in the match with the bet amount set." );
			SendError( opponent, "%s does not have enough money to participate in the match with the bet amount set.", ReturnPlayerName( playerid ) );
			return ResetBoxingPlayerVariables( playerid, opponent );

		} else if ( GetPlayerCash( opponent ) < g_boxingPlayerData[ opponent ] [ E_BET_AMOUNT_SET ] ) {

			SendError( opponent, "You do not have enough money to participate in the match with the bet amount set." );
			SendError( playerid, "%s does not have enough money to participate in the match with the bet amount set.", ReturnPlayerName( opponent ) );
			return ResetBoxingPlayerVariables( playerid, opponent );

		}

		g_boxingArenaData[ E_OCCUPIED ] = true;

		g_boxingPlayerData[ playerid ] [ E_FIGHTING ] = true;
		g_boxingPlayerData[ playerid ] [ E_INVITED ] = false;

		g_boxingPlayerData[ opponent ] [ E_FIGHTING ] = true;
		g_boxingPlayerData[ opponent ] [ E_INVITED ] = false;
		g_boxingPlayerData[ opponent ] [ E_IS_HOST ] = true;

		return StartMatch( playerid, opponent );

	} else if ( !strcmp( params, "decline", true, 7 ) ) {

		new opponent = g_boxingPlayerData[ playerid ] [ E_OPPONENT ];

		if ( g_boxingPlayerData[ playerid ] [ E_INVITED ] == false )
			return SendError( playerid, "You do not have any boxing match invitations to decline." );

		if ( g_boxingPlayerData[ playerid ] [ E_OPPONENT ] == -1 )
			return SendError( playerid, "Your opponent is no longer available to fight." );

		SendBoxing( opponent, "%s has declined your invitation.", ReturnPlayerName( playerid ) );

		SendBoxing( playerid, "You have declined %s's invitation.", ReturnPlayerName( opponent ) );

		return ResetBoxingPlayerVariables( playerid, opponent );

	} else if ( !strcmp( params, "forfeit", true, 7 ) ) {
		if ( ! boxing_ForfeitMatch( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] ) ) {
			return SendError( playerid, "You're not fighting anyone." );
		}
		return 1;
	}
	return SendUsage( playerid, "/boxing [FIGHT/CANCEL/ACCEPT/DECLINE/FORFEIT]" );
}

/* ** Functions ** */
stock StartMatch( playerid, targetID ) {

	if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] && g_boxingPlayerData[ targetID ] [ E_FIGHTING ] ) {

		new Float:health_P, Float:armour_P, Float:health_T, Float:armour_T;

		ClearAnimations( playerid );
		GetPlayerHealth( playerid, health_P );
		GetPlayerArmour( playerid, armour_P );
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
		g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] = health_P;
		g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] = armour_P;
		g_boxingPlayerData[ playerid ] [ E_PRIOR_SKIN ] = GetPlayerSkin( playerid );
		SetPlayerSkin( playerid, 81 );

		ClearAnimations( targetID );
		GetPlayerHealth( targetID, health_T );
		GetPlayerArmour( targetID, armour_T );
		SetPlayerSpecialAction( targetID, SPECIAL_ACTION_NONE );
		g_boxingPlayerData[ targetID ] [ E_PRIOR_HEALTH ] = health_T;
		g_boxingPlayerData[ targetID ] [ E_PRIOR_ARMOUR ] = armour_T;
		g_boxingPlayerData[ targetID ] [ E_PRIOR_SKIN ] = GetPlayerSkin( targetID );
		SetPlayerSkin( targetID, 80 );

		// save weapons
		for( new iSlot = 0; iSlot != 12; iSlot++ ) {
			GetPlayerWeaponData( playerid, iSlot, g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP ] [ iSlot ], g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP_AMMO ] [ iSlot ] );
			GetPlayerWeaponData( targetID, iSlot, g_boxingPlayerData[ targetID ] [ E_PRIOR_WEP ] [ iSlot ], g_boxingPlayerData[ targetID ] [ E_PRIOR_WEP_AMMO ] [ iSlot ] );
		}

		g_boxingArenaData[ E_ROUNDS ] = g_boxingPlayerData[ targetID ] [ E_ROUNDS_SET ];
		g_boxingArenaData[ E_BET ] = g_boxingPlayerData[ targetID ] [ E_BET_AMOUNT_SET ];

		if ( g_boxingArenaData[ E_BET ] > 0 ) {
			GivePlayerCash( playerid, -g_boxingArenaData[ E_BET ] );
			GivePlayerCash( targetID, -g_boxingArenaData[ E_BET ] );
		}

		SetBoxingPlayerConfig( playerid, targetID );

		KillTimer( g_boxingArenaData[ E_CD_TIMER ] );
		g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", 5 );

		SendBoxing( playerid, "You are fighting %s through the best of %i round(s). Good luck!", ReturnPlayerName( targetID ), g_boxingArenaData[ E_ROUNDS ] );
		SendBoxing( targetID, "You are fighting %s through the best of %i round(s). Good luck!", ReturnPlayerName( playerid ), g_boxingArenaData[ E_ROUNDS ] );

		UpdateArenaScoreLabel( playerid, targetID );
		return true;

	} else {
		return SendError( playerid, "I'm sorry. Something has gone terribly wrong with starting the match. Please try again." );
	}
}

stock NextRound( playerid, targetID )
{
	UpdateArenaScoreLabel( playerid, targetID );
	SetBoxingPlayerConfig( playerid, targetID );
	KillTimer( g_boxingArenaData[ E_CD_TIMER ] );
	g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", 5 );
	return 1;
}

stock EndMatch( playerid, targetID ) {

	new winnerid = g_boxingPlayerData[ targetID ] [ E_SCORE ] > g_boxingPlayerData[ playerid ] [ E_SCORE ] ? targetID : playerid;
	new loserid = winnerid == playerid ? targetID : playerid;

	if ( g_boxingArenaData[ E_BET ] <= 0 ) {
		SendBoxingGlobal( "%s has won a boxing match against %s with a final score of %i!", ReturnPlayerName( winnerid ), ReturnPlayerName( loserid ), g_boxingPlayerData[ winnerid ] [ E_SCORE ] );
	} else {
		new winning_prize = floatround( float( g_boxingArenaData[ E_BET ] ) * 1.9 ); // We take 5% of the total pot
		GivePlayerCash( winnerid, winning_prize );
		SendBoxingGlobal( "%s has won a boxing match against %s for %s with a final score of %i!", ReturnPlayerName( winnerid ), ReturnPlayerName( loserid ), cash_format( g_boxingArenaData[ E_BET ] ), g_boxingPlayerData[ winnerid ] [ E_SCORE ] );
	}

	boxing_RestorePlayer( playerid );
	boxing_RestorePlayer( targetID );

	SetPlayerPos( playerid, 2658.3181, 1607.2100, 1507.1793 );
	SetPlayerPos( targetID, 2652.0947, 1607.2100, 1507.1793 );

	ResetBoxingArenaVariables();
	ResetBoxingPlayerVariables( playerid, targetID );
	UpdateDynamic3DTextLabelText( arenaLabel, COLOR_GREY, "Boxing Arena\n"COL_WHITE"/boxing fight" );
	return 1;
}

stock boxing_RestorePlayer( playerid )
{
	// user reported 0xff health, maybe spawn protection
	if ( g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] > 100.0 ) g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] = 100.0;
	if ( g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] > 100.0 ) g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] = 100.0;

	// set prior health
	SetPlayerHealth( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] );
	SetPlayerArmour( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] );
	SetPlayerSkin( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_SKIN ] );
	ResetPlayerWeapons( playerid );

	for ( new iSlot = 0; iSlot != 12; iSlot++ ) {
	    GivePlayerWeapon( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP ] [ iSlot ], g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP_AMMO ] [ iSlot ] );
	}
}

stock boxing_ForfeitMatch( playerid, targetID ) {
	if ( ! g_boxingPlayerData[ playerid ] [ E_FIGHTING ] ) return 0;

	if ( g_boxingArenaData[ E_BET ] == 0 ) {
		SendBoxingGlobal( "%s has won a boxing match by forfeit against %s.", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ) );
	} else if ( g_boxingArenaData[ E_BET ] > 0 ) {
		GivePlayerCash( targetID, g_boxingArenaData[ E_BET ] );
		SendBoxingGlobal( "%s has won a boxing match by forfeit against %s for %s.", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ), cash_format( g_boxingArenaData[ E_BET ] ) );
	}

	boxing_RestorePlayer( playerid );
	SetPlayerPos( playerid, 2658.3181, 1607.2100, 1507.1793 );

	if ( 0 <= targetID < MAX_PLAYERS ) {
		boxing_RestorePlayer( targetID );
		SetPlayerPos( targetID, 2652.0947, 1607.2100, 1507.1793 );
	}

	ResetBoxingArenaVariables();
	ResetBoxingPlayerVariables( playerid, targetID );
	UpdateDynamic3DTextLabelText( arenaLabel, COLOR_GREY, "Boxing Arena\n"COL_WHITE"/boxing fight" );
	return 1;
}

stock SetBoxingPlayerConfig( playerid, targetID ) {

	SetPlayerPos( playerid, 2657.4133, 1615.7841, 1507.0977 );
	SetPlayerPos( targetID, 2653.1357, 1611.4575, 1507.0977 );

	SetPlayerFacingAngle( playerid, 136 );
	SetPlayerFacingAngle( targetID, 315 );

	SetCameraBehindPlayer( playerid );
	SetCameraBehindPlayer( targetID );

	SetPlayerHealth( playerid, 100.0 );
	SetPlayerHealth( targetID, 100.0 );

	SetPlayerArmour( playerid, 100.0 );
	SetPlayerArmour( targetID, 100.0 );

	ResetPlayerWeapons( playerid );
	ResetPlayerWeapons( targetID );

	TogglePlayerControllable( playerid, 0 );
	TogglePlayerControllable( targetID, 0 );
	return true;

}

function boxingCountDown( time ) {

	if ( !time ) {
		foreach( new playerid : Player ) {
			if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true ) {
				format( szNormalString, sizeof( szNormalString ), "~r~FIGHT!", time );
				GameTextForPlayer( playerid, szNormalString, 2000, 3 );
				PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );
				TogglePlayerControllable( playerid, 1 );
			}
		}
		g_boxingArenaData[ E_CD_TIMER ] = -1;

	} else {
		foreach( new playerid : Player ) {
			if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true ) {
				format( szNormalString, sizeof( szNormalString ), "~y~%d", time );
				GameTextForPlayer( playerid, szNormalString, 2000, 3 );
				PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
			}
		}
		g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", time - 1 );
	}
	return 1;
}

stock UpdateArenaScoreLabel( playerid, opponent ) {
	format( szNormalString, sizeof( szNormalString ), "%s [ %i ] - [ %i ] %s", ReturnPlayerName( playerid ), g_boxingPlayerData[ playerid ] [ E_SCORE ], g_boxingPlayerData[ opponent ] [ E_SCORE ], ReturnPlayerName( opponent ) );
	return UpdateDynamic3DTextLabelText( arenaLabel, COLOR_GOLD, szNormalString );
}

stock ResetBoxingPlayerVariables( playerid, targetID ) {

	g_boxingPlayerData[ playerid ] [ E_INVITED ] = false;
	g_boxingPlayerData[ playerid ] [ E_OPPONENT ] = -1;
	g_boxingPlayerData[ playerid ] [ E_IS_HOST ] = false;
	g_boxingPlayerData[ playerid ] [ E_FIGHTING ] = false;
	g_boxingPlayerData[ playerid ] [ E_SCORE ] = 0;
	TogglePlayerControllable( playerid, 1 );

	if ( 0 <= targetID < MAX_PLAYERS )
	{
		g_boxingPlayerData[ targetID ] [ E_INVITED ] = false;
		g_boxingPlayerData[ targetID ] [ E_OPPONENT ] = -1;
		g_boxingPlayerData[ targetID ] [ E_IS_HOST ] = false;
		g_boxingPlayerData[ targetID ] [ E_FIGHTING ] = false;
		g_boxingPlayerData[ targetID ] [ E_SCORE ] = 0;
		TogglePlayerControllable( targetID, 1 );
	}
	return true;
}

stock ResetBoxingArenaVariables() {
	g_boxingArenaData[ E_OCCUPIED ] = false;
	g_boxingArenaData[ E_CURRENT_ROUNDS ] = 0;
	g_boxingArenaData[ E_ROUNDS ] = 0;
	g_boxingArenaData[ E_BET ] = 0;
	return true;

}

/* Hooks */
#if defined AC_INCLUDED
hook OnPlayerDamagePlayer( playerid, damagedid, Float: amount, weaponid, bodypart )
#else
hook OnPlayerGiveDamage( playerid, damagedid, Float: amount, weaponid, bodypart )
#endif
{
	if ( g_boxingPlayerData[ damagedid ] [ E_FIGHTING ] == true ) {

		new Float:currentArmour;

		GetPlayerArmour( damagedid, currentArmour );

		if ( currentArmour <= 0.0 ) {

			new opponent = g_boxingPlayerData[ damagedid ] [ E_OPPONENT ];

			g_boxingPlayerData[ opponent ] [ E_SCORE ] ++;
			g_boxingArenaData[ E_CURRENT_ROUNDS ] ++;

			if ( g_boxingArenaData[ E_CURRENT_ROUNDS ] == g_boxingArenaData[ E_ROUNDS ] ) {
				return EndMatch( damagedid, opponent );
			}

			SendBoxing( damagedid, "You have lost the round. Let the next round begin." );
			SendBoxing( opponent, "You have won the round. Let the next round begin." );

			SendBoxing( damagedid, "Best of %i - [ %s: %i ] - [ %s: %i ]", g_boxingArenaData[ E_ROUNDS ], ReturnPlayerName( damagedid ), g_boxingPlayerData[ damagedid ] [ E_SCORE ], ReturnPlayerName( opponent ), g_boxingPlayerData[ opponent ] [ E_SCORE ]  );
			SendBoxing( opponent, "Best of %i - [ %s: %i ] - [ %s: %i ]", g_boxingArenaData[ E_ROUNDS ], ReturnPlayerName( damagedid ), g_boxingPlayerData[ damagedid ] [ E_SCORE ], ReturnPlayerName( opponent ), g_boxingPlayerData[ opponent ] [ E_SCORE ]  );

			NextRound( damagedid, opponent );
		}
	}
	return Y_HOOKS_CONTINUE_RETURN_1;

}
