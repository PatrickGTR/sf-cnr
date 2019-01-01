/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\commands\cmd_nametags.pwn
 * Purpose: command that hides player name tags
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock bool: p_HiddenNameTags [ MAX_PLAYERS char ];

/* ** Commands ** */
CMD:nametags( playerid, params[ ] )
{
	if ( strmatch( params, "off" ) ) {
		foreach( new i : Player ) { ShowPlayerNameTagForPlayer( playerid, i, 0 ); }
		p_HiddenNameTags{ playerid } = true;
	    SendClientMessage( playerid, 0x84aa63ff, "-> Name tags disabled" );
	} else if ( strmatch( params, "on" ) ) {
		foreach( new i : Player ) { ShowPlayerNameTagForPlayer( playerid, i, 1 ); }
		p_HiddenNameTags{ playerid } = false;
	    SendClientMessage( playerid, 0x84aa63ff, "-> Name tags enabled" );
	}
	else SendClientMessage( playerid, 0xa9c4e4ff, "-> /nametags [ON/OFF]" );
	return 1;
}

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason ) {
	p_HiddenNameTags{ playerid } = false;
    return 1;
}

hook OnPlayerSpawn( playerid ) {
	// Hide name tags if enabled option
	foreach( new pID : Player ) if ( p_HiddenNameTags{ pID } ) {
		ShowPlayerNameTagForPlayer( pID, playerid, 0 );
	}
    return 1;
}