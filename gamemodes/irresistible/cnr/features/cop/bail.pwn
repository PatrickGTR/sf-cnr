/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\bail.pwn
 * Purpose: bail system for criminals
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define BAIL_DOLLARS_PER_SECOND     ( 50 )

/* ** Variables ** */
static stock p_BailOfferer          [ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... };

/* ** Commands ** */
CMD:bail( playerid, params[ ] )
{
	new
	    pID,
	    equa
	;

	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/bail [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot bail yourself." );
	else if ( !IsPlayerJailed( pID ) ) return SendError( playerid, "This player isn't jailed." );
	else if ( IsPlayerAdminJailed( pID ) ) return SendError( playerid, "This player has been admin jailed." );
	else if ( IsPlayerSettingToggled( pID, SETTING_BAILOFFERS ) ) return SendError( playerid, "This player has disabled bail notifications." );
	else if ( GetPVarInt( pID, "bail_antispam" ) > g_iTime ) return SendError( playerid, "You must wait 10 seconds before offering a bail to this player." );
	else
	{
	    equa = BAIL_DOLLARS_PER_SECOND * p_JailTime[ pID ];
	    if ( p_JailTime[ pID ] >= ALCATRAZ_TIME_WANTED ) equa *= 2;
	    p_BailOfferer[ pID ] = playerid;
	    p_BailTimestamp[ pID ] = g_iTime + 120;
	    SetPVarInt( pID, "bail_antispam", g_iTime + 1 );
	    SendServerMessage( playerid, "You have offered %s(%d) bail for "COL_GOLD"%s", ReturnPlayerName( pID ), pID, cash_format( equa ) );
	    SendClientMessageFormatted( pID, -1, ""COL_GREY"[SERVER]"COL_WHITE" %s(%d) has offered to bail you out for "COL_GOLD"%s"COL_WHITE". "COL_ORANGE"/acceptbail"COL_WHITE" to accept the bail.", ReturnPlayerName( playerid ), playerid, cash_format( equa ) );
	}
	return 1;
}

CMD:acceptbail( playerid, params[ ] )
{
	new
	    equa = BAIL_DOLLARS_PER_SECOND * p_JailTime[ playerid ];

	if ( p_JailTime[ playerid ] >= ALCATRAZ_TIME_WANTED )
		equa *= 2;

	if ( GetPlayerCash( playerid ) < equa ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "You don't have enough to be bailed." );
	else if ( IsPlayerAdminJailed( playerid ) ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "You have been admin jailed, therefore disallowing this." );
	else if ( !IsPlayerJailed( playerid ) ) return SendError( playerid, "You're not jailed!" );
	else if ( !IsPlayerConnected( p_BailOfferer[ playerid ] ) ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "The person who offered you bail is not connected." );
	else if ( p_BailTimestamp[ playerid ] < g_iTime ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This offer has expired a minute ago." );
	else
	{
		new
			cashEarned = floatround( equa * 0.70 );

	    GivePlayerCash( playerid, -equa );
		GivePlayerCash( p_BailOfferer[ playerid ], cashEarned );
		StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, cashEarned, 0.1 );
		SendClientMessageFormatted( p_BailOfferer[ playerid ], -1, ""COL_GREEN"[BAIL]"COL_WHITE" %s(%d) has paid bail. You have earned "COL_GOLD"%s"COL_WHITE" from his bail.", ReturnPlayerName( playerid ), playerid, cash_format( cashEarned ) );
    	p_BailOfferer[ playerid ] = INVALID_PLAYER_ID;
        SendServerMessage( playerid, "You have paid for your bail. You are now free!" );
	   	CallLocalFunction( "OnPlayerUnjailed", "dd", playerid, 1 );
	}
	return 1;
}

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_BailOfferer[ playerid ] = INVALID_PLAYER_ID;
    return 1;
}