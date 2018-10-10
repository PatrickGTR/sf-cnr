/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: anticheat/damage_feed.pwn
 * Purpose: damage feed for dmers
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_FEED_HEIGHT 			( 5 )
#define HIDE_FEED_DELAY 			( 3000 )
#define MAX_UPDATE_RATE 			( 250 )

/* ** Variables ** */
enum E_DAMAGE_FEED
{
	E_ISSUER, 				E_NAME[ MAX_PLAYER_NAME ], 			Float: E_AMOUNT,
	E_WEAPON, 				E_TICK,
};

static stock 
	g_damageGiven 					[ MAX_PLAYERS ][ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ],
	g_damageTaken 					[ MAX_PLAYERS ][ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ],

	PlayerText: g_damageFeedTakenTD	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: g_damageFeedGivenTD	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },

	p_damageFeedTimer 				[ MAX_PLAYERS ],
	p_lastFeedUpdate 				[ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnPlayerConnect( playerid )
{
	for( new i = 0; i < sizeof( g_damageGiven[ ] ); i ++) {
		g_damageGiven[ playerid ][ i ][ E_TICK ] = 0;
		g_damageTaken[ playerid ][ i ][ E_TICK ] = 0;
	}

	p_lastFeedUpdate[ playerid ] = GetTickCount( );
	return 1;
}

/* ** Functions ** */
function OnPlayerFeedUpdate( playerid )
{
	return 1;
}

stock UpdateDamageFeed( playerid, bool: modified = false )
{
/* ** Textdraws ** */
	if ( g_damageFeedGivenTD[ playerid] == PlayerText: INVALID_TEXT_DRAW )
	{
		new PlayerText: handle = CreatePlayerTextDraw( playerid, 200.000000, 340.000000, "_");

		if ( handle == PlayerText: INVALID_TEXT_DRAW )
			return print("[DAMAGE FEED ERROR]: Unable to create TD (given damage)" ), 0;

		PlayerTextDrawAlignment( playerid, handle, 2 );
		PlayerTextDrawBackgroundColor( playerid, handle, 255 );
		PlayerTextDrawFont( playerid, handle, 1 );
		PlayerTextDrawLetterSize( playerid, handle, 0.200000, 0.899999 );
		PlayerTextDrawColor( playerid, handle, -16776961 );
		PlayerTextDrawSetOutline( playerid, handle, 1 );
		PlayerTextDrawSetProportional( playerid, handle, 1 );
		PlayerTextDrawSetSelectable( playerid, handle, 0 );

		g_damageFeedGivenTD[ playerid ] = handle;
	}

	
	if ( g_damageFeedTakenTD[ playerid] == PlayerText: INVALID_TEXT_DRAW )
	{
		new PlayerText: handle = CreatePlayerTextDraw( playerid, 440.000000, 340.000000,, "_");

		if ( handle == PlayerText: INVALID_TEXT_DRAW )
			return print("[DAMAGE FEED ERROR]: Unable to create TD (taken damage)" ), 0;

		PlayerTextDrawBackgroundColor( playerid, handle, 255 );
		PlayerTextDrawFont( playerid, handle, 1 );
		PlayerTextDrawLetterSize( playerid, handle, 0.200000, 0.899999 );
		PlayerTextDrawColor( playerid, handle, 16711935 );
		PlayerTextDrawSetOutline( playerid, handle, 1 );
		PlayerTextDrawSetProportional( playerid, handle, 1 );
		PlayerTextDrawSetSelectable( playerid, handle, 0 );

		g_damageFeedTakenTD[ playerid ] = handle;
	}

/* ** Core ** */

	new szTick = GetTickCount( );
	if ( szTick == 0) szTick = 1;
	new low_tick = ( szTick + 1 );

	for( new i = 0; i < sizeof( g_damageGiven[ ] ) - 1; i ++)
	{
		if ( !g_damageGiven[ playerid ][ i ][ E_TICK ] ) {
			break;
		}

		if ( szTick - g_damageGiven[ playerid ][ i ][ E_TICK ] >= HIDE_FEED_DELAY )
		{
			modified = true;

			for (new j = i; j < sizeof( g_damageGiven[ ] ) - 1; j++) {
				g_damageGiven[ playerid ][ j ][ E_TICK ] = 0;
			}

			break;
		}

		if (g_damageGiven[ playerid ][ i ][ E_TICK ] < low_tick) {
			low_tick = g_damageGiven[ playerid ][ i ][ E_TICK ];
		}
	}

	for( new i = 0; i < sizeof( g_damageTaken[ ] ) - 1; i ++)
	{
		if ( !g_damageTaken[ playerid ][ i ][ E_TICK ] ) {
			break;
		}

		if ( szTick - g_damageTaken[ playerid ][ i ][ E_TICK ] >= HIDE_FEED_DELAY )
		{
			modified = true;

			for (new j = i; j < sizeof( g_damageTaken[ ] ) - 1; j++) {
				g_damageTaken[ playerid ][ j ][ E_TICK ] = 0;
			}

			break;
		}

		if (g_damageTaken[ playerid ][ i ][ E_TICK ] < low_tick) {
			low_tick = g_damageTaken[ playerid ][ i ][ E_TICK ];
		}
	}

	if ( p_damageFeedTimer[ playerid ] != -1 ) {
		KillTimer( p_damageFeedTimer[ playerid ] );
	}

	if ( szTick - p_lastFeedUpdate[ playerid ] < MAX_UPDATE_RATE && modified )
	{
		p_damageFeedTimer[ playerid ] = SetTimerEx( "OnPlayerFeedUpdate", MAX_UPDATE_RATE - ( szTick - low_tick ) + 10, false, "d", playerid );
	}
	else
	{
		if ( lowest_tick == tick + 1 ) {
			p_damageFeedTimer[playerid] = -1;
			modified = true;
		} else {
			p_damageFeedTimer[playerid] = SetTimerEx( "OnPlayerFeedUpdate", HIDE_FEED_DELAY - ( szTick - lowest_tick ) + 10, false, "i", playerid );
		}

		if (modified)
		{
			UpdateDamageFeedLabel( playerid );

			p_lastFeedUpdate[ playerid ] = szTick;
		}
	}
}

stock UpdateDamageFeedLabel( playerid )
{
	new 
		szLabel[ 64 * MAX_FEED_HEIGHT ]
	;

	FOR 
}