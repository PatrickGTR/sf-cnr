/*
 *				Lookupffs.inc
 *			  Edited by Lorenc_
 *
*/

// Macros
#define GetPlayerHost(%1) 				(g_lookup_PlayerData[%1][E_HOST])
#define GetPlayerISP(%1) 				(g_lookup_PlayerData[%1][E_ISP])
#define GetPlayerCountryCode(%1) 		(g_lookup_PlayerData[%1][E_CODE])
#define GetPlayerCountryName(%1) 		(g_lookup_PlayerData[%1][E_COUNTRY])
#define GetPlayerCountryRegion(%1) 		(g_lookup_PlayerData[%1][E_REGION])
#define IsProxyUser(%1) 				(g_lookup_PlayerData[%1][E_PROXY])
#define IsProxyEnabledForPlayer(%1)		(g_lookup_Success{%1})

// Variables
enum E_LOOKUP_DATA
{
	E_HOST[ 60 ],		E_CODE[ 3 ],		E_COUNTRY[ 45 ],
	E_REGION[ 43 ],		E_ISP[ 128 ],		E_PROXY
};

stock
	g_lookup_PlayerData[ MAX_PLAYERS ] [ E_LOOKUP_DATA ],
	g_lookup_Success[ MAX_PLAYERS char ],
	g_lookup_Retry[ MAX_PLAYERS char ]
;

// Forwards
public OnLookupResponse( playerid, response, data[ ] );
public OnLookupComplete( playerid, success );

// Hooks
public OnPlayerConnect( playerid ) {
	if ( ! IsPlayerNPC( playerid ) ) {
		g_lookup_Retry{ playerid } = 0;
		LookupPlayerIP( playerid );
	}
	return CallLocalFunction("Lookup_OnPlayerConnect", "i", playerid);
}

// Functions
stock LookupPlayerIP( playerid ) {

	if( IsPlayerNPC( playerid ) )
		return 0;

	static
		szIP[ 16 ], szQuery[ 50 ];

	GetPlayerIp( playerid, szIP, sizeof( szIP ) );

	format( szQuery, sizeof( szQuery ), "iphub.info/api.php?ip=%s&showtype=2", szIP );
	return HTTP( playerid, HTTP_GET, szQuery, "", "OnLookupResponse" );
}

stock ResetPlayerIPData( playerid ) {
	format( g_lookup_PlayerData[ playerid ] [ E_HOST ], 10, "Unknown" );
	format( g_lookup_PlayerData[ playerid ] [ E_CODE ], 3, "XX" );
	format( g_lookup_PlayerData[ playerid ] [ E_COUNTRY ], 10, "Unknown" );
	format( g_lookup_PlayerData[ playerid ] [ E_REGION ], 10, "Unknown" );
	format( g_lookup_PlayerData[ playerid ] [ E_ISP ], 10, "Unknown" );
	g_lookup_PlayerData[ playerid ] [ E_PROXY ] = 0;
	g_lookup_Success{ playerid } = 0;
}

// Callbacks
public OnLookupResponse( playerid, response, data[ ] ) {

	if( !IsPlayerConnected( playerid ) )
		return 0;

	if( response != 200 ) // Fail
	{
		if( !g_lookup_Retry{ playerid } ) {
			g_lookup_Retry{ playerid } = 1;
			return LookupPlayerIP( playerid );
		} else {
			ResetPlayerIPData( playerid );
		}
	}
	else
	{
		if( sscanf( data, "p< >e<s[60]s[3]s[45]s[43]s[128]d>", g_lookup_PlayerData[ playerid ] ) )
		{
			if( !g_lookup_Retry{ playerid } ) {
				g_lookup_Retry{ playerid } = 1;
				return LookupPlayerIP( playerid );
			} else {
				ResetPlayerIPData( playerid );
			}
		}
		else
		{
			strreplacechar( g_lookup_PlayerData[ playerid ] [ E_COUNTRY ], '_', ' ' );
			strreplacechar( g_lookup_PlayerData[ playerid ] [ E_ISP ], '_', ' ' );
			g_lookup_Success{ playerid } = 1;
		}
	}
	return CallLocalFunction( "OnLookupComplete", "ii", playerid, g_lookup_Success{ playerid } );
}

// Hook
#if defined _ALS_OnPlayerConnect
	#undef OnPlayerConnect
#else
	#define _ALS_OnPlayerConnect
#endif

#define OnPlayerConnect Lookup_OnPlayerConnect
forward Lookup_OnPlayerConnect( playerid );
