/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: sampac.inc
 * Purpose: 3rd party anticheat implementation (sampcac.xyz)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >
#include 							< sampcac >

/* ** Definitions ** */
#define AC_WEBSITE 					"www.sampcac.xyz"
#define IsPlayerUsingSampAC 		CAC_GetStatus

/* ** Variables ** */
new const
	g_szCheatNames         		  [ ] [ ] =
	{
		"Aimbot (1)", "Aimbot (2)", "Triggerbot (1)", "Triggerbot (2)", "Nametag wallhack (1)", "ESP (1)", "Macro keybind (1)",
		"Fake ping (1)", "Weapon info (1)", "No recoil (1)", "No recoil (2)", "Aimbot (3)", "Aimbot (4)", "CLEO", "Aimbot (5)", "Aimbot (6)",
		"No recoil (3)", "Untrusted (1)", "Untrusted (2)", "Untrusted (3)", "Untrusted (4)"
	}
;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	CAC_SetGameOptionStatus( CAC_GAMEOPTION__SPRINT, CAC_GAMEOPTION_STATUS__SPRINT_ALLSURFACES );
	// CAC_SetGameOptionStatus( CAC_GAMEOPTION__INFINITESPRINT, 1 );
	return 1;
}

/* ** Callbacks ** */
function OnPlayerCheat( player_id, cheat_id )
{
	new
		playerName[MAX_PLAYER_NAME] = "*not connected*";

    if ( IsPlayerConnected( player_id ) ) {
        GetPlayerName( player_id, playerName, sizeof( playerName ) );
    }

    if ( strmatch( g_szCheatNames[ cheat_id ], "Aimbot (6)" ) ) {
    	return 1; // ignore aimbot (6)
    }

    // AdvancedBan( player_id, "Server", g_szCheatNames[ cheat_id ], ReturnPlayerIP( player_id ) );
	format( szNormalString, sizeof( szNormalString ), "[ANTI-CHEAT]{FFFFFF} %s(%d) has been detected using %s.", playerName, player_id, g_szCheatNames[ cheat_id ] );
	SendClientMessageToAdmins( COLOR_PINK, szNormalString );
    print( szNormalString );
    return 1;
}
