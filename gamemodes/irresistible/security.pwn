/*
 * Irresistible Gaming 2018
 * Developed by Lorenc
 * Module: security.inc
 * Purpose: security related functions for ig servers
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define GetServerName(%0) 			( g_igServerNames[ %0 ] )
#define ReturnPlayerIP(%0) 			( p_PlayerIP[ ( %0 ) ] )
#define ReturnPlayerName(%0) 		( p_PlayerName[ ( %0 ) ] )
#define IsPlayerNpcEx(%0)			( IsPlayerNPC( %0 ) || ! strcmp( p_PlayerIP[ %0 ], "127.0.0.1", true ) )

/* ** Constants ** */
stock const
	g_igServerNames 				[ ] [ ] = { SERVER_NAME };

/* ** Variables ** */
new
	p_PlayerName 					[ MAX_PLAYERS ] [ MAX_PLAYER_NAME ],
	p_PlayerIP 						[ MAX_PLAYERS ] [ 16 ],
	p_RconLoginFails 				[ MAX_PLAYERS char ]
;

/* ** Forwards ** */
forward OnNpcConnect( npcid );
forward OnNpcDisconnect( npcid, reason );

/* ** Hooks ** */
hook OnRconLoginAttempt( ip[ ], password[ ], success )
{
	new
		playerid = INVALID_PLAYER_ID,
		szIP[ 16 ]
	;

	foreach(new i : Player)
	{
		if( GetPlayerIp( i, szIP, sizeof( szIP ) ) )
		{
		    if( !strcmp( szIP, ip, true ) )
		    {
		        playerid = i;
		        break;
		    }
		}
	}

	if( !success )
	{
		if( IsPlayerConnected( playerid ) )
		{
		    p_RconLoginFails{ playerid } ++;
		 	SendClientMessageFormatted( playerid, -1, "{FF0000}[ERROR]{FFFFFF} You have entered an invalid rcon password. {C0C0C0}[%d/2]", p_RconLoginFails{ playerid } );

		 	if( p_RconLoginFails{ playerid } >= 2 ) {
				SendClientMessageFormatted( playerid, -1, "{C0C0C0}[SERVER]{FFFFFF} If you are not the server operator or manager, don't bother trying!" );
				Kick( playerid );
			}
		}
	}
	else
	{
		if ( IsPlayerConnected( playerid ) && ! IsPlayerServerMaintainer( playerid ) )
		{
			RangeBanPlayer( playerid );
			return 0;
		}
	}
	return 1;
}

hook OnPlayerConnect( playerid )
{
	static
		szName[ MAX_PLAYER_NAME ], szIP[ 16 ];

    GetPlayerIp( playerid, szIP, sizeof( szIP ) );
    GetPlayerName( playerid, szName, sizeof( szName ) );

	if ( IsPlayerNPC( playerid ) ) {
		CallLocalFunction( "OnNpcConnect", "d", playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}

	strcpy( p_PlayerIP[ playerid ], szIP );
	strcpy( p_PlayerName[ playerid ], szName );

	// get out the bots/invalid player ids
	if ( ! ( 0 <= playerid < MAX_PLAYERS ) ) {
		Kick( playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}

	// check for invalid name
	if ( strlen( ReturnPlayerName( playerid ) ) <= 2 ) {
		Kick( playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}

	// check if player name is "no-one" since it is used for unowned entities
	if ( ! strcmp( ReturnPlayerName( playerid ), "No-one", true ) ) {
	 	Kick( playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}

	// check advertisers
	if ( textContainsIP( ReturnPlayerName( playerid ) ) ) {
	 	Kick( playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}

	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	if ( IsPlayerNPC( playerid ) ) {
		CallLocalFunction( "OnNpcDisconnect", "dd", playerid, reason );
		return Y_HOOKS_BREAK_RETURN_1;
	}

	// Filter out bots
	if ( ! ( 0 <= playerid < MAX_PLAYERS ) ) {
		return Y_HOOKS_BREAK_RETURN_1;
	}

	return 1;
}

hook OnPlayerFloodControl( playerid, iCount, iTimeSpan ) {
	static
		szIP[ 16 ];

    GetPlayerIp( playerid, szIP, sizeof( szIP ) );

    if ( iCount > 2 && iTimeSpan < 10000 && ! IsPlayerNpcEx( playerid ) ) {
   		BanEx( playerid, "BOT-SPAM" );
    }
	return 1;
}

#if !defined DEBUG_MODE
	// prevent player from leaking rcon password
	hook OnPlayerText( playerid, text[ ] )
	{
		static
			rcon_password[ 144 ];

		GetServerVarAsString( "rcon_password", rcon_password, sizeof( rcon_password ) );

		if ( strfind( text, rcon_password, true ) != -1 ) {
			return SendClientMessage( playerid, -1, "{C0C0C0}[SERVER]{FFFFFF} Your message was blocked as it exposed the RCON password." ), 0;
		}
		return 1;
	}
#else
	// aims to clear the banned from the server bug
	hook OnIncomingConnection( playerid, ip_address[ ], port ) {
		SendRconCommand( "reloadbans" );
		return 1;
	}
#endif

/* ** Hooked Functions ** */
stock Security_SetPlayerName( playerid, const name[ ] )
{
	if ( 0 <= playerid < MAX_PLAYERS ) {
		format ( p_PlayerName[ playerid ], sizeof ( p_PlayerName[ ] ), "%s", name );
	}
	return SetPlayerName( playerid, name );
}

#if defined _ALS_SetPlayerName
    #undef SetPlayerName
#else
    #define _ALS_SetPlayerName
#endif

#define SetPlayerName Security_SetPlayerName

/* ** Functions ** */
stock RangeBanPlayer( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

	new
	    szBan[ 24 ],
	    szIP[ 16 ]
	;
	GetPlayerIp( playerid, szIP, sizeof( szIP ) );
    GetRangeIP( szIP, sizeof( szIP ) );

	format( szBan, sizeof( szBan ), "banip %s", szIP );
	SendRconCommand( szBan );

	KickPlayerTimed( playerid );

	return 1;
}

stock GetRangeIP( szIP[ ], iSize = sizeof( szIP ) )
{
	new
		iCount = 0
	;
	for( new i; szIP[ i ] != '\0'; i ++ )
	{
	    if ( szIP[ i ] == '.' && ( iCount ++ ) == 1 )
	    {
	        strdel( szIP, i, strlen( szIP ) );
	        break;
	    }
	}
	format( szIP, iSize, "%s.*.*", szIP );
}
