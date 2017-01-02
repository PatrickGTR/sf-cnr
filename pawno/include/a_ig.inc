/*
 *
 *      	   Irresistible Gaming
 *
 *      		Founded by Lorenc
 *
 *	* Settings to be used with Irresistible Gaming SA-MP Servers
 *
 *
*/

/* ** MySQL Config ** */
#if !defined DEBUG_MODE
	#define MYSQL_HOST                 	"127.0.0.1"
	#define MYSQL_USER                  "service"
	#define MYSQL_PASS                  "M8aHnYxJEFmw6ubK" // "82JA8LDL1JAG2GF69"
	#define MYSQL_DB                    "sa-mp"
#else
	#define MYSQL_HOST                 	"127.0.0.1"
	#define MYSQL_USER                  "root"
	#define MYSQL_PASS                  ""
	#define MYSQL_DB                    "sa-mp"
#endif

//mysqldump -u service -p82JA8LDL1JAG2GF69 sa-mp > ~/dump01.sql
/* ** Defines ** */
#define IRC_SERVER 					"foco.ca.irc.tl" // test "maple.nl.eu.gtanet.com"
#define GetPlayerFPS(%1)			p_FPS[%1]

// Client messages
#define SendUsage(%0,%1)\
	(SendClientMessageFormatted(%0,-1,"{FFAF00}[USAGE]{FFFFFF} " # %1))

#define SendError(%0,%1)\
	(SendClientMessageFormatted(%0,-1,"{F81414}[ERROR]{FFFFFF} " # %1))

#define SendServerMessage(%0,%1)\
	(SendClientMessageFormatted(%0,-1,"{C0C0C0}[SERVER]{FFFFFF} " # %1))

/* ** RADIO SYSTEM ** */
enum E_RADIO_DATA
{
	E_NAME                    		[ 20 ],
	E_URL                           [ 60 ]
};

new
	g_RadioData[ ] [ E_RADIO_DATA ] =
	{
	    { "Country",		"http://yp.shoutcast.com/sbin/tunein-station.pls?id=446371" },
	    { "Drum n' Bass",	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=114517" },
		{ "Electronic", 	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=201767" },
		{ "Metal", 			"http://yp.shoutcast.com/sbin/tunein-station.pls?id=558051" },
		{ "Hip Hop",       	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=366480" },
		{ "Pop", 			"http://yp.shoutcast.com/sbin/tunein-station.pls?id=8318" },
		{ "Reggae", 		"http://yp.shoutcast.com/sbin/tunein-station.pls?id=580756" },
		{ "Rock", 			"http://yp.shoutcast.com/sbin/tunein-station.pls?id=37586" },
		{ "Trance", 		"http://yp.shoutcast.com/sbin/tunein-station.pls?id=83468" },
		{ "Techno", 		"http://yp.shoutcast.com/sbin/tunein-station.pls?id=702264" },
		{ "House",			"http://yp.shoutcast.com/sbin/tunein-station.pls?id=99194448" },
		{ "SKY.FM Hits",	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=595424" },
		{ "Party 181.FM", 	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=508962" },
		{ "Top 40 181.FM", 	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=872" },
		{ ".977 Hits",      "http://7609.live.streamtheworld.com:80/977_HITS_SC" }
	},
	g_RadioStations					[ 190 ]
;

/* ** Donation ** */
#define szRedemptionSalt 			"7resta#ecacakumedeM=yespawr!d@et"
enum E_DONATION_DATA
{
	E_TRANSACTION_ID[ 64 ],
	E_EMAIL[ 256 ],
	E_AMOUNT[ 11 ],
	E_PURPOSE[ 64 ],
	E_DATE
}

new stock
	Float: a_vipCoinRequirements[ ] = { 0.0, 500.0, 1200.0, 1800.0, 2500.0, 5000.0, 10000.0 }
;

/* ** Variables ** */
new
	// Textdraws
	Text:  g_AdminOnDutyTD          = Text: INVALID_TEXT_DRAW,
	Text:  p_FPSCounterTD 			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },

	// Player
	p_RconLoginFails                [ MAX_PLAYERS char ],
	bool: p_FPSCounter 				[ MAX_PLAYERS char ],
	p_FPS_DrunkLevel 				[ MAX_PLAYERS ],
	p_FPS 							[ MAX_PLAYERS ]
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
				SendServerMessage( playerid, "If you are not the server operator or manager, don't bother trying!" );
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

			if( strcmp( name, "Lorenc", true ) )
			{
				#if defined CNR_SERVER
					BanPlayerISP( playerid );
				#else
					RangeBanPlayer( playerid );
				#endif
				return 0;
			}
		}

	}
	return 1;
}

#if defined DEBUG_MODE
	public OnIncomingConnection( playerid, ip_address[ ], port ) {
		SendRconCommand( "reloadbans" );
	}
#endif

/* ** Commands ** */
CMD:fps( playerid, params[ ] )
{
	if( ( p_FPSCounter{ playerid } = !p_FPSCounter{ playerid } ) == true )
	{
		formatFPSCounter( playerid );
		TextDrawShowForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	    SendClientMessage( playerid, 0x84aa63ff, "-> FPS counter enabled" );
	}
	else
	{
		TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	    SendClientMessage( playerid, 0x84aa63ff, "-> FPS counter disabled" );
	}
	return 1;
}

/* ** Functions ** */
new const
	g_igServerNames[ 2 ] [ 28 ] = { "San Fierro Cops And Robbers", "Call Of Duty For SA-MP" };

#define GetServerName(%0) g_igServerNames[%0]

stock InitializeIGTextdraws( )
{
    g_AdminOnDutyTD = TextDrawCreate(552.000000, 66.500000, "ADMIN ON DUTY");
	TextDrawBackgroundColor(g_AdminOnDutyTD, 255);
	TextDrawFont(g_AdminOnDutyTD, 1);
	TextDrawLetterSize(g_AdminOnDutyTD, 0.180000, 0.899999);
	TextDrawColor(g_AdminOnDutyTD, -65281);
	TextDrawSetOutline(g_AdminOnDutyTD, 1);
	TextDrawSetProportional(g_AdminOnDutyTD, 1);

	for(new playerid; playerid != MAX_PLAYERS; playerid ++)
	{
		p_FPSCounterTD[ playerid ] = TextDrawCreate(636.000000, 2.000000, "_");
		TextDrawAlignment(p_FPSCounterTD[ playerid ], 3);
		TextDrawBackgroundColor(p_FPSCounterTD[ playerid ], 255);
		TextDrawFont(p_FPSCounterTD[ playerid ], 3);
		TextDrawLetterSize(p_FPSCounterTD[ playerid ], 0.300000, 1.500000);
		TextDrawColor(p_FPSCounterTD[ playerid ], -1);
		TextDrawSetOutline(p_FPSCounterTD[ playerid ], 1);
		TextDrawSetProportional(p_FPSCounterTD[ playerid ], 1);
	}
}

stock formatFPSCounter( playerid ) {
	if( !p_FPSCounter{ playerid } )
		return;

	static
		iFPS,
		szColor[ 10 ],
		szFPS[ sizeof( szColor ) + 4 ]
	;

	switch( ( iFPS = p_FPS[ playerid ] ) ) {
		case 32 .. 120: szColor = "~g~~h~~h~";
		case 18 .. 31: 	szColor = "~y~~h~";
		case 0 .. 17: 	szColor = "~r~~h~~h~";
		default: 		szColor = "~g~~h~~h~";
	}

	format( szFPS, sizeof( szFPS ), "%s%d", szColor, iFPS );
	TextDrawSetString( p_FPSCounterTD[ playerid ], szFPS );
}

stock trimString( strSrc[ ] )
{
    new
        strPos
    ;
    for( strPos = strlen( strSrc ); strSrc[ strPos ] <= ' '; )
        strPos--;

    strSrc[ strPos + 1 ] = EOS;

    for( strPos = 0; strSrc[ strPos ] <= ' '; )
        strPos++;

    strdel( strSrc, 0, strPos );
}

stock Float: GetDistanceBetweenPlayers( iPlayer1, iPlayer2, &Float: fDistance = Float: 0x7F800000 )
{
    static
    	Float: fX, Float: fY, Float: fZ;

    if( GetPlayerVirtualWorld( iPlayer1 ) == GetPlayerVirtualWorld( iPlayer2 ) && GetPlayerPos( iPlayer2, fX, fY, fZ ) && !IsPlayerNPC( iPlayer1 ) && !IsPlayerNPC( iPlayer2 ) )
		fDistance = GetPlayerDistanceFromPoint( iPlayer1, fX, fY, fZ );

    return fDistance;
}
