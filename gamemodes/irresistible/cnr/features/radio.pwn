/*
 * Irresistible Gaming 2018
 * Developed by Lorenc
 * Module: radio.inc
 * Purpose: radio related feature
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined VIP_REGULAR
	#error "This module requires a V.I.P system!"
#endif

/* ** Variables ** */
enum E_RADIO_DATA
{
	E_NAME                    		[ 16 ],
	E_URL                           [ 60 ]
};

static stock
	g_RadioData[ ] [ E_RADIO_DATA ] =
	{
	    { "Country",		"http://sc3c-sjc.1.fm:7806" },
		{ "Electronic", 	"http://useless.streams.enation.fm:8000" },
		{ "Metal", 			"http://ice.somafm.com/metal" },
		{ "Hip Hop",       	"http://www.stationzilla.com/stationzilla.m3u" },
		{ "Pop", 			"http://listen.radionomy.com/airradiofreestyleslow" },
		{ "Reggae", 		"http://whatisland.macchiatomedia.org:8118" },
		{ "Rock", 			"http://sorradio.org:5005/live" },
		{ "Jamz 1.FM",		"http://sc1c-sjc.1.fm:8052" },
		{ "XLTRAX FM", 		"http://xltrax.com:8000" },
		{ "Groove Salad", 	"http://ice.somafm.com/groovesalad" },
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

/* ** Functions ** */
stock IsPlayerUsingRadio( playerid ) return p_UsingRadio{ playerid };
