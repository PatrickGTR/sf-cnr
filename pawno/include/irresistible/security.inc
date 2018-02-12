/*
 * Irresistible Gaming 2018
 * Developed by Lorenc Pekaj
 * Module: security.inc
 * Purpose: security related functions for ig servers
 */

/* ** Macros ** */
#define GetServerName(%0) g_igServerNames[%0]

/* ** Variables ** */
new
	g_igServerNames[ 2 ] [ 28 ] = { "San Fierro Cops And Robbers", "Call Of Duty For SA-MP" },
	p_RconLoginFails[ MAX_PLAYERS char ]
;

/* ** Callbacks ** */
public OnRconLoginAttempt(ip[], password[], success)
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
		if( IsPlayerConnected( playerid ) )
		{
			new
				name[ 24 ];

			GetPlayerName( playerid, name, sizeof( name ) );

			if( strcmp( name, "Lorenc", true ) && strcmp( name, "Banging7Grams", true ) )
			{
				RangeBanPlayer( playerid );
				return 0;
			}
		}

	}
	return 1;
}

#if defined DEBUG_MODE
	// aims to clear the banned from the server bug
	public OnIncomingConnection( playerid, ip_address[ ], port ) {
		SendRconCommand( "reloadbans" );
	}
#endif

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
