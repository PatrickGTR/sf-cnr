/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: server.pwn
 * Purpose: server related definitions
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define SERVER_NAME					"San Fierro Cops And Robbers (0.3.7)"
#define SERVER_MODE_TEXT 			"Cops And Robbers / DM / Gangs"
#define SERVER_MAP 					"San Fierro"
#define SERVER_LANGUAGE				"English"
#define SERVER_WEBSITE				"www.sfcnr.com"
#define SERVER_IP					"54.36.127.43:7777"
#define SERVER_TWITTER 				"IrresistibleDev"

/* ** Comment line to disable feature ** */
#define SERVER_RULES_URL            "files.sfcnr.com/en_rules.txt"							// used for /rules (cnr\features\server_rules.pwn)
#define SERVER_TWITTER_FEED_URL 	"files.sfcnr.com/cnr_twitter.php"						// used for /twitter (cnr\commands\cmd_twitter.pwn)
#define SERVER_HELP_API_URL			"sfcnr.com/api/player/help"								// used for /help (cnr\commands\cmd_help.pwn)
#define SERVER_CHANGES_DIRECTORY 	"changelogs/cnr"										// used for /changes (cnr\changelog.pwn)
#define SERVER_PLS_DONATE_MP3		"http://files.sfcnr.com/game_sounds/pls_donate.mp3"		// used for advertising vip (cnr\features\vip\coin_market.pwn)
#define SERVER_MIGRATIONS_FOLDER  	"./gamemodes/irresistible/config/migrations/cnr/"		// used for migrations checking (config\migrations\_migrations.pwn)

/* ** Hooks ** */
hook OnScriptInit( )
{
	// set server query information
	SetGameModeText( SERVER_MODE_TEXT );
	SetServerRule( "hostname", SERVER_NAME );
	SetServerRule( "language", SERVER_LANGUAGE );
	SetServerRule( "mapname", SERVER_MAP );

	// simple gameplay rules
	UsePlayerPedAnims( );
	AllowInteriorWeapons( 0 );
	EnableStuntBonusForAll( 0 );
	DisableInteriorEnterExits( );

	// enable mysql debugging on debug mode
	#if defined DEBUG_MODE
	mysql_log( LOG_ERROR | LOG_WARNING );
	#endif

	// start map andreas (if enabled)
	#if defined MAP_ANDREAS_MODE_MINIMAL
	MapAndreas_Init( MAP_ANDREAS_MODE_MINIMAL );
	#endif
	return 1;
}

/* ** Functions ** */
stock IsPlayerLeadMaintainer( playerid ) // Limits money, coin, xp spawning to this user id
{
	return GetPlayerAccountID( playerid ) == 1;
}

stock IsPlayerServerMaintainer( playerid ) // Same as lead maintainer, just cant spawn money/xp/coins
{
	if ( IsPlayerLeadMaintainer( playerid ) )
		return true;

	// new account_id = GetPlayerAccountID( playerid );
	// return account_id == -1;
	return false;
}

stock IsPlayerUnderCover( playerid ) // Undercover accounts allow admin commands on a specific id unnoticed
{
	if ( ! IsPlayerLoggedIn( playerid ) )
		return false;

	// new account_id = GetPlayerAccountID( playerid );
	// return account_id == 1;
	return false;
}
