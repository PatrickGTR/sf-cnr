/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\movie_mode.pwn
 * Purpose: movie mode feature that hides textdraws for the purpose of a movie
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock Text: g_MovieModeTD	[ 6 ] = { Text: INVALID_TEXT_DRAW, ... };
static stock bool: p_inMovieMode	[ MAX_PLAYERS char ];

/* ** Hooks ** */
hook OnScriptInit( )
{
	g_MovieModeTD[ 0 ] = TextDrawCreate(507.000000, 386.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 0 ], 255);
	TextDrawFont(g_MovieModeTD[ 0 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 0 ], 0.500000, 4.799999);
	TextDrawColor(g_MovieModeTD[ 0 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 0 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 0 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 0 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 0 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 0 ], 80);
	TextDrawTextSize(g_MovieModeTD[ 0 ], 620.000000, 0.000000);

	g_MovieModeTD[ 1 ] = TextDrawCreate(516.000000, 398.000000, "San Fierro");
	TextDrawBackgroundColor(g_MovieModeTD[ 1 ], 255);
	TextDrawFont(g_MovieModeTD[ 1 ], 3);
	TextDrawLetterSize(g_MovieModeTD[ 1 ], 0.529999, 2.299999);
	TextDrawColor(g_MovieModeTD[ 1 ], -2347265);
	TextDrawSetOutline(g_MovieModeTD[ 1 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 1 ], 1);

	g_MovieModeTD[ 2 ] = TextDrawCreate(530.000000, 414.000000, "Cops and Robbers");
	TextDrawBackgroundColor(g_MovieModeTD[ 2 ], 255);
	TextDrawFont(g_MovieModeTD[ 2 ], 0);
	TextDrawLetterSize(g_MovieModeTD[ 2 ], 0.310000, 1.100000);
	TextDrawColor(g_MovieModeTD[ 2 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 2 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 2 ], 1);

	g_MovieModeTD[ 3 ] = TextDrawCreate(507.000000, 398.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 3 ], 255);
	TextDrawFont(g_MovieModeTD[ 3 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 3 ], 0.500000, -0.400000);
	TextDrawColor(g_MovieModeTD[ 3 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 3 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 3 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 3 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 3 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 3 ], 255);
	TextDrawTextSize(g_MovieModeTD[ 3 ], 620.000000, 0.000000);

	g_MovieModeTD[ 4 ] = TextDrawCreate(530.000000, 385.000000, "www.SFCNR.com");
	TextDrawBackgroundColor(g_MovieModeTD[ 4 ], 255);
	TextDrawFont(g_MovieModeTD[ 4 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 4 ], 0.200000, 1.000000);
	TextDrawColor(g_MovieModeTD[ 4 ], 0xfa4d4cff);
	TextDrawSetOutline(g_MovieModeTD[ 4 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 4 ], 1);

	g_MovieModeTD[ 5 ] = TextDrawCreate(507.000000, 386.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 5 ], 255);
	TextDrawFont(g_MovieModeTD[ 5 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 5 ], 0.500000, 0.799999);
	TextDrawColor(g_MovieModeTD[ 5 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 5 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 5 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 5 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 5 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 5 ], 128);
	TextDrawTextSize(g_MovieModeTD[ 5 ], 620.000000, 0.000000);
	return 1;
}
hook OnPlayerDisconnect( playerid, reason ) {
	p_inMovieMode{ playerid } = false;
    return 1;
}

/* ** Commands ** */
CMD:moviemode( playerid, params[ ] )
{
	switch ( p_inMovieMode{ playerid } )
	{
		case true:
		{
		    p_inMovieMode{ playerid } = false;
		    SendServerMessage( playerid, "Movie mode has been un-toggled." );
			CallLocalFunction( "OnPlayerLoadTextdraws", "d", playerid );
	        for ( new i = 0; i < sizeof( g_MovieModeTD ); i ++ ) TextDrawHideForPlayer( playerid, g_MovieModeTD[ i ] );
		}
		case false:
		{
		    p_inMovieMode{ playerid } = true;
		    SendServerMessage( playerid, "Movie mode has been toggled." );
			CallLocalFunction( "OnPlayerUnloadTextdraws", "d", playerid );
	        for ( new i = 0; i < sizeof( g_MovieModeTD ); i ++ ) TextDrawShowForPlayer( playerid, g_MovieModeTD[ i ] );
		}
	}
	CallLocalFunction( "OnPlayerMovieMode", "dd", playerid, p_inMovieMode{ playerid } );
	return 1;
}

/* ** Functions ** */
stock IsPlayerMovieMode( playerid ) {
    return p_inMovieMode{ playerid };
}