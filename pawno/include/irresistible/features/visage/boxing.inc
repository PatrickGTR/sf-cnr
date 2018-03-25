/*
 * Irresistible Gaming (c) 2018
 * Developed by Damen, Lorenc Pekaj
 * Module: boxing.inc
 * Purpose: in-game boxing implementation
 */

/* ** Variables ** */

/* INCLUDES */
#include <a_mysql>
#include <a_samp>
#include <foreach>
#include <sscanf2>
#include <streamer>
#include <zcmd>

/* DIALOG DEFINITIONS */
#define DIALOG_BOXING_SETTINGS 9435
#define DIALOG_BOXING_ROUNDS 9436
#define DIALOG_BOXING_BET_AMOUNT 9437

/* ENUMS */
enum E_BOXER_DATA {
	E_WINS,
	E_LOSSES,
	E_TOTAL_FIGHTS,
	bool:E_FIGHTING,
	E_OPPONENT,
	bool:E_INVITED,
	E_INVITE_TIMER,
	E_ROUNDS_SET,
	E_BET_AMOUNT_SET,
	bool:E_IS_HOST,
	E_SCORE,
	Float:E_PRIOR_HEALTH,
	Float:E_PRIOR_ARMOUR
};

enum E_ARENA_DATA {
	bool: E_OCCUPIED,
	E_CD_TIMER,
	E_CURRENT_ROUNDS,
	E_ROUNDS,
	E_BET
};

new g_boxingMatchData[ MAX_PLAYERS ][ E_BOXER_DATA ];
new g_boxingArenaData[ E_ARENA_DATA ];
new g_boxingArenaObjects[ 9 ];

public OnPlayerConnect( playerid ) {
	g_boxingMatchData[ playerid ][ E_FIGHTING ] = false;
	g_boxingMatchData[ playerid ][ E_OPPONENT ] = -1;
	g_boxingMatchData[ playerid ][ E_INVITED ] = false;
	g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] = 1;
	g_boxingMatchData[ playerid ][ E_BET_AMOUNT_SET ] = 0;
	g_boxingMatchData[ playerid ][ E_IS_HOST ] = false;
	g_boxingMatchData[ playerid ][ E_SCORE ] = 0;
}

public OnPlayerDisconnect( playerid, reason ) {
	g_boxingMatchData[ playerid ][ E_WINS ] = 0;
	g_boxingMatchData[ playerid ][ E_LOSSES ] = 0;
	g_boxingMatchData[ playerid ][ E_TOTAL_FIGHTS ] = 0;
	g_boxingMatchData[ playerid ][ E_FIGHTING ] = false;
	g_boxingMatchData[ playerid ][ E_OPPONENT ] = -1;
	g_boxingMatchData[ playerid ][ E_INVITED ] = false;
	g_boxingMatchData[ playerid ][ E_INVITE_TIMER ] = 0;
	g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] = 1;
	g_boxingMatchData[ playerid ][ E_BET_AMOUNT_SET ] = 0;
	g_boxingMatchData[ playerid ][ E_IS_HOST ] = false;
	g_boxingMatchData[ playerid ][ E_SCORE ] = 0;
}

/* BOXING COMMANDS */
CMD:boxing( playerid, params[ ] ) {

	if ( !IsPlayerNearArena( playerid ) )
		return SendError( playerid, "You must be within 25 meters of the arena to use this command." );

	if ( g_boxingArenaData[ E_OCCUPIED ] == true )
			return SendError( playerid, "The arena is currently occupied. Please wait for the arena to clear." );

	if ( !strcmp( params, "fight", true, 5 ) ) {

		new targetID;

		if ( g_boxingMatchData[ playerid ][ E_FIGHTING ] == true )
			return SendError( playerid, "You are currently fighting an opponent. Please finish your fight." );

		if ( sscanf( params[ 6 ], "u", targetID ) )
			return SendUsage( playerid, "/boxing fight [OPPONENT ID]" );

		if ( !IsPlayerConnected( targetID ) )
			return SendError( playerid, "Player is not connected." );

		if ( targetID == playerid )
			return SendError( playerid, "You cannot invite yourself to a boxing match." );

		if ( !IsPlayerNearArena( targetID ) )
			return SendError( playerid, "The player you have invited to a boxing match is not near the boxing arena." );

		if ( g_boxingMatchData[ targetID ][ E_INVITED ] == true )
			return SendError( playerid, "That player has already been invited to a fight." );

		if ( g_boxingMatchData[ targetID ][ E_FIGHTING ] == true )
			return SendError( playerid, "That player is currently fighting another opponent. Please wait until after their match to reinvite them." );

		if ( g_boxingMatchData[ playerid ][ E_INVITED ] == true ) {

			format( szNormalString, sizeof( szNormalString ), "You have cancelled your invite to %s.", ReturnPlayerName( g_boxingMatchData[ playerid ][ E_OPPONENT ] ) );
			SendBoxing( playerid, szNormalString );

			format( szNormalString, sizeof( szNormalString ), "%s has cancelled the match invite.", ReturnPlayerName( playerid ) );
			SendBoxing( g_boxingMatchData[ playerid ][ E_OPPONENT ], szNormalString );

			ResetBoxingPlayerVariables( playerid, g_boxingMatchData[ playerid ][ E_OPPONENT ] );

		}

		g_boxingMatchData[ playerid ][ E_INVITED ] = true;
		g_boxingMatchData[ playerid ][ E_OPPONENT ] = targetID;
		g_boxingMatchData[ playerid ][ E_IS_HOST ] = true;

		g_boxingMatchData[ targetID ][ E_INVITED ] = true;
		g_boxingMatchData[ targetID ][ E_OPPONENT ] = playerid;

		KillTimer( g_boxingMatchData[ playerid ][ E_INVITE_TIMER ] );
		g_boxingMatchData[ playerid ][ E_INVITE_TIMER ] = SetTimerEx( "KillInviteTimer", 30000, false, "d", playerid );

		if ( g_boxingMatchData[ playerid ][ E_BET_AMOUNT_SET ] == 0 ) {

			format( szNormalString, sizeof( szNormalString ), "You have invited %s to a boxing match with no wager through %i round(s).", ReturnPlayerName( targetID ), g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] );
			SendBoxing( playerid, szNormalString );
			SendBoxing( playerid, "To cancel your invite, use /boxing [CANCEL]." );

			format( szNormalString, sizeof( szNormalString ), "%s has invited you to a boxing match with no wager through %i round(s).", ReturnPlayerName( playerid ), g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] );
			SendBoxing( targetID, szNormalString );
			SendBoxing( targetID, "To accept or decline the invite, use /boxing [ACCEPT/DECLINE]." );

			return true;

		} else {

			format( szNormalString, sizeof( szNormalString ), "You have invited %s to a boxing match with $%i wager through %i round(s).", ReturnPlayerName( targetID ), g_boxingMatchData[ playerid ][ E_BET_AMOUNT_SET ], g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] );
			SendBoxing( playerid, szNormalString );
			SendBoxing( playerid, "To cancel your invite, use /boxing [CANCEL]." );

			format( szNormalString, sizeof( szNormalString ), "%s has invited you to a boxing match with a $%i wager through %i round(s).", ReturnPlayerName( playerid ), g_boxingMatchData[ playerid ][ E_BET_AMOUNT_SET ], g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] );
			SendBoxing( targetID, szNormalString );
			SendBoxing( targetID, "To accept or decline the invite, use /boxing [ACCEPT/DECLINE]." );

			return true;

		}

	} else if ( !strcmp( params, "cancel", true, 6 ) ) {

		new opponent = g_boxingMatchData[ playerid ][ E_OPPONENT ];

		if ( g_boxingMatchData[ playerid ][ E_FIGHTING ] == true )
			return SendError( playerid, "You're currently in a boxing match. Use /boxing [FORFEIT] if you would like to forfeit the match." );

		if ( g_boxingMatchData[ playerid ][ E_IS_HOST ] == false )
			return SendError( playerid, "You have no boxing match invites to cancel." );

		KillTimer( g_boxingMatchData[ playerid ][ E_INVITE_TIMER ] );

		format( szNormalString, sizeof( szNormalString ), "%s has cancelled the boxing match invitation.", ReturnPlayerName( playerid ) );
		SendBoxing( opponent, szNormalString );

		format( szNormalString, sizeof( szNormalString ), "You have cancelled the boxing match invitation sent to %s.", ReturnPlayerName( opponent ) );
		SendBoxing( playerid, szNormalString );

		ResetBoxingPlayerVariables( playerid, opponent );

		return 1;

	} else if ( !strcmp( params, "accept", true, 6 ) ) {

		new opponent = g_boxingMatchData[ playerid ][ E_OPPONENT ];

		if ( g_boxingMatchData[ playerid ][ E_INVITED ] == false )
			return SendError( playerid, "You do not have any boxing match invitations to accept." );

		if ( opponent == -1 )
			return SendError( playerid, "Your opponent is no longer available to fight." );

		KillTimer( g_boxingMatchData[ opponent ][ E_INVITE_TIMER ] );

		if ( !IsPlayerNearArena( opponent ) ) {

			format( szNormalString, sizeof( szNormalString ), "%s is no longer near the arena. Your invitation has been cancelled.", ReturnPlayerName( opponent ) );
			SendError( playerid, szNormalString );

			format( szNormalString, sizeof( szNormalString ), "%s has attempted to accept your invite while you were not near the arena.", ReturnPlayerName( playerid ) );
			SendBoxing( opponent, szNormalString );

			return ResetBoxingPlayerVariables( playerid, opponent );

		}

		if ( GetPlayerMoney( playerid ) < g_boxingMatchData[ opponent ][ E_BET_AMOUNT_SET ] ) {

			SendError( playerid, "You do not have enough money to participate in the match with the bet amount set." );

			format( szNormalString, sizeof( szNormalString ), "%s does not have enough money to participate in the match with the bet amount set.", ReturnPlayerName( playerid ) );
			SendError( opponent, szNormalString );

			return ResetBoxingPlayerVariables( playerid, opponent );

		} else if ( GetPlayerMoney( opponent ) < g_boxingMatchData[ opponent ][ E_BET_AMOUNT_SET ] ) {

			SendError( opponent, "You do not have enough money to participate in the match with the bet amount set." );

			format( szNormalString, sizeof( szNormalString ), "%s does not have enough money to participate in the match with the bet amount set.", ReturnPlayerName( opponent ) );
			SendError( playerid, szNormalString );

			return ResetBoxingPlayerVariables( playerid, opponent );

		}

		g_boxingMatchData[ playerid ][ E_FIGHTING ] = true;
		g_boxingMatchData[ playerid ][ E_INVITED ] = false;

		g_boxingMatchData[ opponent ][ E_FIGHTING ] = true;
		g_boxingMatchData[ opponent ][ E_INVITED ] = false;
		g_boxingMatchData[ opponent ][ E_IS_HOST ] = true;

		return StartMatch( playerid, opponent );

	} else if ( !strcmp( params, "decline", true, 7 ) ) {

		new opponent = g_boxingMatchData[ playerid ][ E_OPPONENT ];

		if ( g_boxingMatchData[ playerid ][ E_INVITED ] == false )
			return SendError( playerid, "You do not have any boxing match invitations to decline." );

		if ( g_boxingMatchData[ playerid ][ E_OPPONENT ] == -1 )
			return SendError( playerid, "Your opponent is no longer available to fight." );

		KillTimer( g_boxingMatchData[ playerid ][ E_INVITE_TIMER ] );

		format( szNormalString, sizeof( szNormalString ), "%s has declined your invitation.", ReturnPlayerName( playerid ) );
		SendBoxing( opponent, szNormalString );

		format( szNormalString, sizeof( szNormalString ), "You have declined %s's invitation.", ReturnPlayerName( opponent ) );
		SendBoxing( playerid, szNormalString );

		return ResetBoxingPlayerVariables( playerid, opponent );

	} else if ( !strcmp( params, "forfeit", true, 7 ) ) {

		new opponent = g_boxingMatchData[ playerid ][ E_OPPONENT ];

		if ( g_boxingMatchData[ playerid ][ E_FIGHTING ] == false )
			return SendError( playerid, "You're not fighting anyone." );

		return ForfeitMatch( playerid, opponent );

	} else if ( !strcmp( params, "config", true, 8 ) ) {

		if ( g_boxingMatchData[ playerid ][ E_FIGHTING ] == true )
			return SendError( playerid, "You cannot edit the match's settings while in a match." );

		if ( g_boxingMatchData[ playerid ][ E_INVITED ] == true )
			return SendError( playerid, "You cannot edit the match's settings with a pending invite." );

		return ShowBoxingDialog( playerid );

	}

	return SendUsage( playerid, "/boxing [FIGHT/CANCEL/ACCEPT/DECLINE/FORFEIT/CONFIG]" );

}

stock ResetBoxingPlayerVariables( playerid, targetID ) {

	g_boxingMatchData[ playerid ][ E_INVITED ] = false;
	g_boxingMatchData[ playerid ][ E_OPPONENT ] = -1;
	g_boxingMatchData[ playerid ][ E_IS_HOST ] = false;
	g_boxingMatchData[ playerid ][ E_FIGHTING ] = false;
	g_boxingMatchData[ playerid ][ E_SCORE ] = 0;
	TogglePlayerControllable( playerid, 1 );

	g_boxingMatchData[ targetID ][ E_INVITED ] = false;
	g_boxingMatchData[ targetID ][ E_OPPONENT ] = -1;
	g_boxingMatchData[ targetID ][ E_IS_HOST ] = false;
	g_boxingMatchData[ targetID ][ E_FIGHTING ] = false;
	g_boxingMatchData[ targetID ][ E_SCORE ] = 0;
	TogglePlayerControllable( targetID, 1 );
	return true;

}

stock ResetBoxingArenaVariables() {

	g_boxingArenaData[ E_OCCUPIED ] = false;
	g_boxingArenaData[ E_CURRENT_ROUNDS ] = 0;
	g_boxingArenaData[ E_ROUNDS ] = 0;
	g_boxingArenaData[ E_BET ] = 0;
	return true;

}

function KillInviteTimer( playerid ) {

	new opponent = g_boxingMatchData[ playerid ][ E_OPPONENT ];

	ResetBoxingPlayerVariables( playerid, opponent );

	format( szNormalString, sizeof( szNormalString ), "The boxing match invite sent by %s has expired.", ReturnPlayerName( playerid ) );
	SendBoxing( opponent, szNormalString );

	format( szNormalString, sizeof( szNormalString ), "The boxing match invite you sent to %s has expired.", ReturnPlayerName( opponent ) );
	SendBoxing( playerid, szNormalString );

	return true;

}

/* ** Functions ** */
function StartMatch( playerid, targetID ) {

	if ( g_boxingMatchData[ playerid ][ E_FIGHTING ] == true && g_boxingMatchData[ playerid ][ E_FIGHTING ] ) {

		new Float:health_P, Float:armour_P, Float:health_T, Float:armour_T;

		GetPlayerHealth( playerid, health_P );
		g_boxingMatchData[ playerid ][ E_PRIOR_HEALTH ] = health_P;

		GetPlayerArmour( playerid, armour_P );
		g_boxingMatchData[ playerid ][ E_PRIOR_ARMOUR ] = armour_P;

		GetPlayerHealth( targetID, health_T );
		g_boxingMatchData[ targetID ][ E_PRIOR_HEALTH ] = health_T;

		GetPlayerArmour( targetID, armour_T );
		g_boxingMatchData[ targetID ][ E_PRIOR_ARMOUR ] = armour_T;

		g_boxingArenaData[ E_ROUNDS ] = g_boxingMatchData[ targetID ][ E_ROUNDS_SET ];
		g_boxingArenaData[ E_BET ] = g_boxingMatchData[ targetID ][ E_BET_AMOUNT_SET ];

		SetBoxingPlayerConfig( playerid, targetID );

		KillTimer( g_boxingArenaData[ E_CD_TIMER ] );
		g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", 8 );

		format( szNormalString, sizeof( szNormalString ), "You are fighting %s through the best of %i round(s). Good luck!", ReturnPlayerName( targetID ), g_boxingArenaData[ E_ROUNDS ] );
		SendBoxing( playerid, szNormalString );

		format( szNormalString, sizeof( szNormalString ), "You are fighting %s through the best of %i round(s). Good luck!", ReturnPlayerName( playerid ), g_boxingArenaData[ E_ROUNDS ] );
		SendBoxing( targetID, szNormalString );

		return true;

	} else {

		return SendError( playerid, "I'm sorry. Something has gone terribly wrong with starting the match. Please try again." );

	}

}

function NextRound( playerid, targetID ) {

	SetBoxingPlayerConfig( playerid, targetID );

	KillTimer( g_boxingArenaData[ E_CD_TIMER ] );
	g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", 8 );
	return true;
}

function EndMatch( playerid, targetID ) {

	if ( g_boxingArenaData[ E_BET ] == 0 ) {

		format( szNormalString, sizeof( szNormalString ), "%s has won a boxing match against %s with a final score of: [ %s: %i - %s: %i ]", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ), ReturnPlayerName( playerid ), g_boxingMatchData[ playerid ][ E_SCORE ], ReturnPlayerName( targetID ), g_boxingMatchData[ targetID ][ E_SCORE ] );

	} else if ( g_boxingArenaData[ E_BET ] > 0 ) {

		if ( g_boxingMatchData[ playerid ][ E_SCORE ] > g_boxingMatchData[ targetID ][ E_SCORE ] ) {

			GivePlayerMoney( playerid, g_boxingArenaData[ E_BET ] );
			GivePlayerMoney( targetID, -g_boxingArenaData[ E_BET ] );

		} else if ( g_boxingMatchData[ targetID ][ E_SCORE ] > g_boxingMatchData[ playerid ][ E_SCORE ] ) {

			GivePlayerMoney( targetID, g_boxingArenaData[ E_BET ] );
			GivePlayerMoney( playerid, -g_boxingArenaData[ E_BET ] );

		}

		format( szNormalString, sizeof( szNormalString ), "%s has won a boxing match against %s for $%i with a final score of: [ %s: %i - %s: %i ]", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ), g_boxingArenaData[ E_BET ], ReturnPlayerName( playerid ), g_boxingMatchData[ playerid ][ E_SCORE ], ReturnPlayerName( targetID ), g_boxingMatchData[ targetID ][ E_SCORE ] );

	}

	SetPlayerHealth( playerid, g_boxingMatchData[ playerid ][ E_PRIOR_HEALTH ] );
	SetPlayerArmour( playerid, g_boxingMatchData[ playerid ][ E_PRIOR_ARMOUR ] );

	SetPlayerHealth( targetID, g_boxingMatchData[ targetID ][ E_PRIOR_HEALTH ] );
	SetPlayerArmour( targetID, g_boxingMatchData[ targetID ][ E_PRIOR_ARMOUR ] );

	SetPlayerPos( playerid, 113.0, -110.0, 2 );
	SetPlayerPos( targetID, 113.0, -104.0, 2 );

	SendBoxingGlobal( szNormalString );

	ResetBoxingArenaVariables();
	ResetBoxingPlayerVariables( playerid, targetID );

	return true;

}

function ForfeitMatch( playerid, targetID ) {

	if ( g_boxingArenaData[ E_BET ] == 0 ) {

		format( szNormalString, sizeof( szNormalString ), "%s has won a boxing match by forfeit against %s.", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ) );

	} else if ( g_boxingArenaData[ E_BET ] > 0 ) {

		GivePlayerMoney( targetID, g_boxingArenaData[ E_BET ] );

		format( szNormalString, sizeof( szNormalString ), "%s has won a boxing match by forfeit against %s for $%i.", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ), g_boxingArenaData[ E_BET ] );

	}

	SetPlayerHealth( playerid, g_boxingMatchData[ playerid ][ E_PRIOR_HEALTH ] );
	SetPlayerArmour( playerid, g_boxingMatchData[ playerid ][ E_PRIOR_ARMOUR ] );

	SetPlayerHealth( targetID, g_boxingMatchData[ targetID ][ E_PRIOR_HEALTH ] );
	SetPlayerArmour( targetID, g_boxingMatchData[ targetID ][ E_PRIOR_ARMOUR ] );

	SetPlayerPos( playerid, 113.0, -110.0, 2 );
	SetPlayerPos( targetID, 113.0, -104.0, 2 );

	SendBoxingGlobal( szNormalString );

	ResetBoxingArenaVariables();
	ResetBoxingPlayerVariables( playerid, targetID );

	return true;

}

function SetBoxingPlayerConfig( playerid, targetID ) {

	SetPlayerPos( playerid, 2238.29, 1679.2426, 1009.188 );
	SetPlayerPos( targetID, 2234.3279, 1675.3125, 1009.188 );

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

		foreach( Player, playerid ) {

			if ( g_boxingMatchData[ playerid ][ E_FIGHTING ] == true ) {

				format( szNormalString, sizeof( szNormalString ), "~r~FIGHT!", time );
				GameTextForPlayer( playerid, szNormalString, 2000, 3 );
				PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );

				TogglePlayerControllable( playerid, 1 );

			}

		}

		g_boxingArenaData[ E_CD_TIMER ] = 0xFFFF;

	} else {

		foreach( Player, playerid ) {

			if ( g_boxingMatchData[ playerid ][E_FIGHTING ] == true ) {

				format( szNormalString, sizeof( szNormalString ), "~y~%d", time );
				GameTextForPlayer( playerid, szNormalString, 2000, 3 );
				PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );

			}

		}

		g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", time - 1 );

	}

	return true;

}

/* ONPLAYER GIVE/TAKE DAMAGE HANDLING */

hook OnPlayerTakeDamage( playerid, issuerid, Float:amount, weaponid, bodypart ) {

	if ( g_boxingMatchData[ playerid ][ E_FIGHTING ] == true ) {

		new Float:currentArmour;

		GetPlayerArmour( playerid, currentArmour );

		if ( currentArmour <= 5.0 ) {

			new opponent = g_boxingMatchData[ playerid ][ E_OPPONENT ];

			g_boxingMatchData[ opponent ][ E_SCORE ] ++;
			g_boxingArenaData[ E_CURRENT_ROUNDS ] ++;

			if ( g_boxingArenaData[ E_CURRENT_ROUNDS ] == g_boxingArenaData[ E_ROUNDS ] ) {

				return EndMatch( playerid, opponent );

			}

			SendBoxing( playerid, "You have lost the round. Let the next round begin." );
			SendBoxing( opponent, "You have won the round. Let the next round begin." );

			new bestOfMSG[ 50 ];

			format( bestOfMSG, sizeof( bestOfMSG ), "Best of %i - [ %s: %i ] - [ %s: %i ]", g_boxingArenaData[ E_ROUNDS ], ReturnPlayerName( playerid ), g_boxingMatchData[ playerid ][ E_SCORE ], ReturnPlayerName( opponent ), g_boxingMatchData[ opponent ][ E_SCORE ] );

			SendBoxing( playerid, bestOfMSG );
			SendBoxing( opponent, bestOfMSG );

			return NextRound( playerid, opponent );

		}

		return true;

	}

	return true;

}

/* DIALOG RELATED */

function ShowBoxingDialog( playerid ) {
	format( szNormalString, sizeof( szNormalString ), "Rounds\t{EBE971}%i\nBet Amount\t{96F073}%i", g_boxingMatchData[ playerid ][ E_ROUNDS_SET ], g_boxingMatchData[ playerid ][ E_BET_AMOUNT_SET ] );
	return ShowPlayerDialog( playerid, DIALOG_BOXING_SETTINGS, DIALOG_STYLE_TABLIST, "Boxing - Match Configuration", szNormalString, "Select", "Close" );
}

public OnDialogResponse( playerid, dialogid, response, listitem, inputtext[] ) {

	switch ( dialogid ) {

		case DIALOG_BOXING_SETTINGS: {

			if ( response ) {

				switch ( listitem ) {
					// rounds
					case 0: return ShowPlayerDialog( playerid, DIALOG_BOXING_ROUNDS, DIALOG_STYLE_LIST, "Boxing - Rounds", "One Round\nThree Rounds\nFive Rounds", "Set", "Cancel" );

					// wager
					case 1: return ShowPlayerDialog( playerid, DIALOG_BOXING_BET_AMOUNT, DIALOG_STYLE_INPUT, "Boxing - Bet Amount", "How much would you like to wager?", "Set", "Cancel" );
				}
			}
		}

		case DIALOG_BOXING_ROUNDS: {

			if ( response ) {

				switch ( listitem ) {

					case 0: { // 1 ROUND
						g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] = 1;
						return ShowBoxingDialog( playerid );
					}

					case 1: { // 3 ROUNDS
						g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] = 3;
						return ShowBoxingDialog( playerid );
					}

					case 2: { // 5 ROUNDS
						g_boxingMatchData[ playerid ][ E_ROUNDS_SET ] = 5;
						return ShowBoxingDialog( playerid );
					}
				}
			}

		}

		case DIALOG_BOXING_BET_AMOUNT: {

			if ( response ) {

				if ( sscanf( inputtext, "i" ) ) {
					ShowPlayerDialog( playerid, DIALOG_BOXING_BET_AMOUNT, DIALOG_STYLE_INPUT, "Boxing - Bet Amount", "How much would you like to wager?", "Set", "Cancel" );
					return SendError( playerid, "You must choose an amount greater than $0." );
				}

				if ( GetPlayerMoney( playerid ) < strval( inputtext ) ) {
					ShowPlayerDialog( playerid, DIALOG_BOXING_BET_AMOUNT, DIALOG_STYLE_INPUT, "Boxing - Bet Amount", "How much would you like to wager?", "Set", "Cancel" );
					return SendError( playerid, "You do not have that amount of money to bet." );
				}

				g_boxingMatchData[ playerid ][ E_BET_AMOUNT_SET ] = strval( inputtext );
				return ShowBoxingDialog( playerid );
			}
		}

	}

	return true;

}

/* ARENA CREATION */

stock IsPlayerNearArena( playerid ) {
	new
		Float: point = GetPlayerDistanceFromPoint( playerid, 2235.866699, 1676.826293, 1008.359375 );

	return point < 25.0;
}

stock CreateBoxingArena() {

	g_boxingArenaObjects[ 0 ] = CreateDynamicObject( 14781, 2235.866699, 1676.826293, 1008.359375, 0.000000, 0.000000, 0.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 1 ] = CreateDynamicObject( 18766, 2236.955078, 1680.546997, 1010.541503, 0.000000, 90.000000, 0.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 2 ] = CreateDynamicObject( 18766, 2235.683837, 1680.546997, 1010.541503, 0.000000, 90.000000, 0.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 3 ] = CreateDynamicObject( 18766, 2235.683837, 1674.000610, 1010.541503, 0.000000, 90.000000, 0.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 4 ] = CreateDynamicObject( 18766, 2236.955078, 1674.000610, 1010.541503, 0.000000, 90.000000, 0.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 5 ] = CreateDynamicObject( 18766, 2239.607666, 1676.002563, 1010.541503, 0.000000, 90.000000, 90.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 6 ] = CreateDynamicObject( 18766, 2239.607666, 1678.545043, 1010.541503, 0.000000, 90.000000, 90.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 7 ] = CreateDynamicObject( 18766, 2233.031250, 1678.545043, 1010.541503, 0.000000, 90.000000, 90.000000, -1, -1, -1, 300.0 );
	g_boxingArenaObjects[ 8 ] = CreateDynamicObject( 18766, 2233.031250, 1676.003417, 1010.541503, 0.000000, 90.000000, 90.000000, -1, -1, -1, 300.0 );

	for ( new i = 0; i <= 10; i++ ) {
		SetObjectInvisible( g_boxingArenaObjects[ i ] );
	}

}

stock DestroyBoxingArena() {

	for ( new i = 0; i < 10; i++ ) {
		DestroyDynamicObject( g_boxingArenaObjects[ i ] );
	}

}

/* MESSAGE FUNCTIONS */
stock SendBoxingGlobal( string[] ) {

	format( szNormalString, sizeof( szNormalString ), "{B74AFF}[BOXING] {FFFFFF}%s", string );
	return SendClientMessageToAll( -1, szNormalString );

}

stock SendBoxing( playerid, string[] ) {
	format( szNormalString, sizeof( szNormalString ), "{B74AFF}[BOXING] {FFFFFF}%s", string );
	return SendClientMessage( playerid, -1, szNormalString );
}
