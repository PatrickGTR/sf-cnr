/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: analytics.inc
 * Purpose: track player connection analytics
 */

#if !defined ANAL_INCLUDED
	#include 							< a_samp >

	// Variables

	enum E_ANALYTICS
	{
		E_CONNECTS,

		E_DISCONNECTS[ 3 ],

		E_BAN_USES,
		E_KICK_USES,

		E_CUSTOM_BAN_REJECTS,
	};

	new
	    g_Analytics 				[ E_ANALYTICS ]
	;

	// Function Hook (KickPlayer)

	stock SAMPANALYTICS_Kick( playerid )
	{
	 	g_Analytics[ E_KICK_USES ] ++;
	    return Kick( playerid );
	}

	#if defined _ALS_Kick
	    #undef Kick
	#else
	    #define _ALS_Kick
	#endif
	#define Kick SAMPANALYTICS_Kick

	// Function Hook (KickPlayer)

	stock SAMPANALYTICS_Ban( playerid )
	{
	 	g_Analytics[ E_BAN_USES ] ++;
	    return Ban( playerid );
	}

	#if defined _ALS_Ban
	    #undef Ban
	#else
	    #define _ALS_Ban
	#endif
	#define Ban SAMPANALYTICS_Ban

	// Function Hook (KickPlayer)

	stock SAMPANALYTICS_BanEx( playerid, reason[ ] )
	{
	 	g_Analytics[ E_BAN_USES ] ++;
	    return BanEx( playerid, reason );
	}

	#if defined _ALS_BanEx
	    #undef BanEx
	#else
	    #define _ALS_BanEx
	#endif
	#define BanEx SAMPANALYTICS_BanEx

	// Callback Hook (OnPlayerConnect)

	public OnPlayerConnect( playerid )
	{
		g_Analytics[ E_CONNECTS ] ++;

		#if defined SAMPANAL_OnPlayerConnect
			return SAMPANAL_OnPlayerConnect( playerid );
		#else
			return 1;
		#endif
	}

	#if defined SAMPANAL_OnPlayerConnect
		forward SAMPANAL_OnPlayerConnect( playerid );
	#endif
	#if defined _ALS_OnPlayerConnect
		#undef OnPlayerConnect
	#else
		#define _ALS_OnPlayerConnect
	#endif
	#define OnPlayerConnect SAMPANAL_OnPlayerConnect

	// Callback Hook (OnPlayerDisconnect)

	public OnPlayerDisconnect( playerid, reason )
	{
		if( reason < 3 )
			g_Analytics[ E_DISCONNECTS ] [ reason ] ++;

		#if defined SAMPANAL_OnPlayerDisconnect
			return SAMPANAL_OnPlayerDisconnect( playerid, reason );
		#else
			return 1;
		#endif
	}

	#if defined SAMPANAL_OnPlayerDisconnect
		forward SAMPANAL_OnPlayerDisconnect( playerid, reason );
	#endif
	#if defined _ALS_OnPlayerDisconnect
		#undef OnPlayerDisconnect
	#else
		#define _ALS_OnPlayerDisconnect
	#endif
	#define OnPlayerDisconnect SAMPANAL_OnPlayerDisconnect

	// Functions

	stock IncremementAnalyticalValue( E_ANALYTICS: type, value = 1 )
		return ( g_Analytics[ type ] += value );

	stock AnalyticsToHumanReadable( )
	{

		new
			szString[ 256 ],
			iDisconnects = g_Analytics[ E_DISCONNECTS ] [ 0 ] + g_Analytics[ E_DISCONNECTS ] [ 1 ] + g_Analytics[ E_DISCONNECTS ] [ 2 ]
		;

		format( szString, sizeof( szString ),
			"Connections: %d\nDisconnections: %d\n\nPlayer Timeout/Crash: %d\nPlayer Quits: %d\nPlayer Kick/Ban: %d\n\nServer Ban Uses: %d\nServer Kick Uses: %d\n\nCustom Ban Rejects: %d",
			g_Analytics[ E_CONNECTS ], iDisconnects, g_Analytics[ E_DISCONNECTS ] [ 0 ], g_Analytics[ E_DISCONNECTS ] [ 1 ], g_Analytics[ E_DISCONNECTS ] [ 2 ], g_Analytics[ E_BAN_USES ],
			g_Analytics[ E_KICK_USES ], g_Analytics[ E_CUSTOM_BAN_REJECTS ]
		);

		return szString;
	}
#endif
