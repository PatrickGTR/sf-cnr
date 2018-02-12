/*
 * Irresistible Gaming 2018
 * Developed by Lorenc Pekaj
 * Module: radio.inc
 * Purpose: radio related feature
 */

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
	g_RadioStations					[ 190 ]
;
