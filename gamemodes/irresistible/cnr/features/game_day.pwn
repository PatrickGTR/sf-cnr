/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\game_day.pwn
 * Purpose: adds a game week day after 24:00 elapses
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	Text: g_WorldDayTD       		= Text: INVALID_TEXT_DRAW,
	g_WorldClockSeconds             = 0,
	g_WorldDayCount                 = 0,
	g_WorldWeather                  = 10
;

/* ** Hooks ** */
hook OnScriptInit( )
{
   	g_WorldDayTD = TextDrawCreate(501.000000, 6.000000, "Monday");
	TextDrawBackgroundColor(g_WorldDayTD, 255);
	TextDrawFont(g_WorldDayTD, 3);
	TextDrawLetterSize(g_WorldDayTD, 0.519998, 1.499999);
	TextDrawSetOutline(g_WorldDayTD, 2);
	TextDrawSetProportional(g_WorldDayTD, 1);
    return 1;
}

hook OnPlayerTickSecond( playerid )
{
    SetPlayerWeather( playerid, ( GetPlayerInterior( playerid ) || GetPlayerVirtualWorld( playerid ) ) ? 1 : g_WorldWeather );
    UpdatePlayerTime( playerid );
    return 1;
}

hook OnServerTickSecond( )
{
    // set the world time at the query
	SendRconCommand( sprintf( "worldtime %s, %s", GetDayToString( g_WorldDayCount ), TimeConvert( g_WorldClockSeconds++ ) ) );

 	if ( g_WorldClockSeconds >= 1440 )
 	{
 		// call a function when the server day ends
 		CallLocalFunction( "OnServerGameDayEnd", "" );

        // set weather
 	    g_WorldWeather = randarg( 10, 11, 12 );
 	    g_WorldClockSeconds = 0;
        g_WorldDayCount = ( g_WorldDayCount == 6 ? 0 : g_WorldDayCount + 1 );
		TextDrawSetString( g_WorldDayTD, GetDayToString( g_WorldDayCount ) );
	}
    return 1;
}

hook OnPlayerLoadTextdraws( playerid )
{
	TextDrawShowForPlayer( playerid, g_WorldDayTD );
	return 1;
}

hook OnPlayerUnloadTextdraws( playerid )
{
	TextDrawHideForPlayer( playerid, g_WorldDayTD );
	return 1;
}

/* ** Functions ** */
stock GetDayToString( day )
{
	static
	    string[ 10 ];

	switch( day )
	{
		case 0: string = "Monday";
		case 1: string = "Tuesday";
		case 2: string = "Wednesday";
		case 3: string = "Thursday";
		case 4: string = "Friday";
		case 5: string = "Saturday";
		case 6: string = "Sunday";
		default: string = "Bugged";
	}
	return string;
}

stock UpdatePlayerTime( playerid ) {
    return SetPlayerTime( playerid, floatround( g_WorldClockSeconds / 60 ), g_WorldClockSeconds - floatround( ( g_WorldClockSeconds / 60 ) * 60 ) );
}

stock SetWorldWeather( weatherid ) {
    g_WorldWeather = weatherid;
}

stock SetWorldClock( seconds ) {
    g_WorldClockSeconds = ! ( 0 <= seconds <= 1440 ) ? 0 : seconds;
}