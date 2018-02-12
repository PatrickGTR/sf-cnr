/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: lookup.inc
 * Purpose: enables player information to be looked up
 */

// Macros
#define GetPlayerCountryCode(%1) 		(g_lookup_PlayerData[%1][E_CODE])
#define GetPlayerCountryName(%1) 		(g_lookup_PlayerData[%1][E_COUNTRY])
#define IsProxyEnabledForPlayer(%1)		(g_lookup_Success{%1})

// Variables
enum E_LOOKUP_DATA
{
	E_CODE[ 3 ],		E_COUNTRY[ 45 ]
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

	format( szQuery, sizeof( szQuery ), "freegeoip.net/csv/%s", szIP );
	return HTTP( playerid, HTTP_GET, szQuery, "", "OnLookupResponse" );
}

stock ResetPlayerIPData( playerid ) {
	//format( g_lookup_PlayerData[ playerid ] [ E_HOST ], 10, "Unknown" );
	format( g_lookup_PlayerData[ playerid ] [ E_CODE ], 3, "XX" );
	format( g_lookup_PlayerData[ playerid ] [ E_COUNTRY ], 10, "Unknown" );
	//format( g_lookup_PlayerData[ playerid ] [ E_REGION ], 10, "Unknown" );
	//format( g_lookup_PlayerData[ playerid ] [ E_ISP ], 10, "Unknown" );
	//g_lookup_PlayerData[ playerid ] [ E_PROXY ] = 0;
	g_lookup_Success{ playerid } = 0;
}

// Callbacks
public OnLookupResponse( playerid, response, data[ ] ) {

	static
		CountryData[ 96 ];

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
		new
			firstComma = strfind( data, ",", true ),
			secondComma = strfind( data, ",", true, firstComma + 1 ),
			thirdComma = strfind( data, ",", true, secondComma + 1 )
		;

		strmid( CountryData, data, firstComma + 1, thirdComma );
		//printf("Received data:%s",CountryData);

		//210.50.38.234,AU,Australia,VIC,Victoria,Melbourne,3000,Australia/Melbourne,-37.8103,144.9544,0
		if( sscanf( CountryData, "p<,>e<s[3]s[45]>", g_lookup_PlayerData[ playerid ] ) ) // "p< >e<s[60]s[3]s[45]s[43]s[128]d>"
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
			//printf("Information: %s %s \n",g_lookup_PlayerData[ playerid ] [ E_CODE ], g_lookup_PlayerData[ playerid ] [ E_COUNTRY ] );
			strreplacechar( g_lookup_PlayerData[ playerid ] [ E_COUNTRY ], '_', ' ' );
			//strreplacechar( g_lookup_PlayerData[ playerid ] [ E_ISP ], '_', ' ' );
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
