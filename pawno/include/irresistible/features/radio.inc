/*
 * Irresistible Gaming 2018
 * Developed by Lorenc Pekaj
 * Module: radio.inc
 * Purpose: radio related feature
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined VIP_REGULAR
	#error "This module requires a V.I.P system!"
#endif

/* ** Definitions ** */
#define IsPlayerUsingRadio(%0)		(p_UsingRadio{%0})

/* ** Variables ** */
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
	g_RadioStations					[ 190 ] = ""COL_GREY"Custom URL "COL_GOLD"[V.I.P]"COL_WHITE"\n",
	bool: p_UsingRadio				[ MAX_PLAYERS char ]
;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	// format radio station string
    for( new i = 0; i < sizeof( g_RadioData ); i++ ) {
	    format( g_RadioStations, sizeof( g_RadioStations ), "%s%s\n", g_RadioStations, g_RadioData[ i ] [ E_NAME ] );
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_RADIO ) && response )
	{
		if ( listitem == 0 )
		{
			if ( GetPlayerVIPLevel( playerid ) < VIP_REGULAR )
				return SendError( playerid, "You must be a V.I.P to use this, to become one visit "COL_GREY"donate.irresistiblegaming.com" ), 1;

		 	ShowPlayerDialog(playerid, DIALOG_RADIO_CUSTOM, DIALOG_STYLE_INPUT, "{FFFFFF}Custom Radio", ""COL_WHITE"Enter the URL below, and streaming will begin.\n\n"COL_ORANGE"Please note, if there isn't a response. It's likely to be an invalid URL.", "Stream", "Back");
			return 1;
		}
	   	p_UsingRadio{ playerid } = true;
	   	StopAudioStreamForPlayer( playerid );
	   	PlayAudioStreamForPlayer( playerid, g_RadioData[ listitem - 1 ] [ E_URL ] );
	    SendServerMessage( playerid, "If the radio doesn't respond then it must be offline. Use "COL_GREY"/stopradio"COL_WHITE" to stop the radio." );
	}
	else if ( dialogid == DIALOG_RADIO_CUSTOM )
	{
		if ( !response ) return cmd_radio( playerid, "" );
	   	p_UsingRadio{ playerid } = true;
	   	StopAudioStreamForPlayer( playerid );
	   	PlayAudioStreamForPlayer( playerid, inputtext );
	    SendServerMessage( playerid, "If the radio doesn't respond then it must be offline. Use "COL_GREY"/stopradio"COL_WHITE" to stop the radio." );
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
	p_UsingRadio{ playerid } = false;
	return 1;
}

/* ** Commands ** */
CMD:radio( playerid, params[ ] )
{
    ShowPlayerDialog(playerid, DIALOG_RADIO, DIALOG_STYLE_LIST, "{FFFFFF}Radio Stations - List", g_RadioStations, "Select", "Close");
	return 1;
}

CMD:stopradio( playerid, params[ ] )
{
	if ( IsPlayerUsingRadio( playerid ) ) p_UsingRadio{ playerid } = false;
    StopAudioStreamForPlayer( playerid );
	return 1;
}
