/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
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
	E_COUNTRY[ 45 ],					E_CODE[ 5 ]
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

	format( szQuery, sizeof( szQuery ), "ip-api.com/csv/%s?fields=3", szIP );
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
		// format to length of 96
		format( CountryData, sizeof( CountryData ), "%s", data );

		// search for a quote mark
	    new
	    	long_name = strfind( CountryData[ 1 ], "\"," );

	    if ( long_name != -1 )
	    {
	    	// Incase a country appears "This, Is, A, Country", TIAC
	        strmid( g_lookup_PlayerData[ playerid ] [ E_COUNTRY ], CountryData, 1, long_name + 1 );
	        strmid( g_lookup_PlayerData[ playerid ] [ E_CODE ], CountryData, long_name + 3, sizeof( CountryData ) );
	    }
	    else if ( sscanf( CountryData, "p<,>e<s[45]s[5]>", g_lookup_PlayerData[ playerid ] ) )
	    {
			if( !g_lookup_Retry{ playerid } ) {
				g_lookup_Retry{ playerid } = 1;
				return LookupPlayerIP( playerid );
			} else {
				ResetPlayerIPData( playerid );
			}
	    }

		strreplacechar( g_lookup_PlayerData[ playerid ] [ E_COUNTRY ], '_', ' ' );
		g_lookup_Success{ playerid } = 1;
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
