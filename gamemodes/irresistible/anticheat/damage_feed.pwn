/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: anticheat/damage_feed.pwn
 * Purpose: damage feed for dmers
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define IsDamageFeedActive(%0) 		(p_FeedActive{%0})

/* ** Definitions ** */
#define MAX_FEED_HEIGHT 			( 5 )
#define HIDE_FEED_DELAY 			( 3000 )
#define MAX_UPDATE_RATE 			( 250 )

#define TYPE_NONE 					( 0 )
#define TYPE_GIVEN 					( 1 )
#define TYPE_TAKEN 					( 2 )

/* ** Forwards ** */
forward OnPlayerFeedUpdate( playerid );

/* ** Variables ** */
enum E_DAMAGE_FEED
{
	E_ISSUER, 				E_NAME[ MAX_PLAYER_NAME ], 			Float: E_AMOUNT,
	E_WEAPON, 				E_TICK,
};

new
	g_damageGiven 					[ MAX_PLAYERS ][ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ],
	g_damageTaken 					[ MAX_PLAYERS ][ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ],

	PlayerText: g_damageFeedTakenTD	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: g_damageFeedGivenTD [ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },

	p_damageFeedTimer 				[ MAX_PLAYERS ],
	bool: p_FeedActive				[ MAX_PLAYERS char ],
	p_lastFeedUpdate 				[ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnPlayerConnect( playerid )
{
	for( new x = 0; x < sizeof( g_damageGiven[ ] ); x ++) {
		g_damageGiven[ playerid ][ x ][ E_TICK ] = 0;
		g_damageTaken[ playerid ][ x ][ E_TICK ] = 0;
	}

	p_lastFeedUpdate[ playerid ] = GetTickCount( );
	return 1;
}


/* ** Functions ** */
public OnPlayerFeedUpdate( playerid )
{
	p_damageFeedTimer[ playerid ] = -1;

	if ( IsPlayerConnected( playerid ) && IsDamageFeedActive( playerid ) ) {
		UpdateDamageFeed( playerid, true );
	}

	return 1;
}

stock UpdateDamageFeed( playerid, bool: modified = false )
{
	if ( !IsDamageFeedActive( playerid ) )
	{
		if ( g_damageFeedGivenTD[ playerid ] != PlayerText: INVALID_TEXT_DRAW ) {
			PlayerTextDrawDestroy( playerid, g_damageFeedGivenTD[ playerid ] );
			g_damageFeedGivenTD[ playerid ] = PlayerText: INVALID_TEXT_DRAW;
		}

		if ( g_damageFeedTakenTD[ playerid ] != PlayerText: INVALID_TEXT_DRAW ) {
			PlayerTextDrawDestroy( playerid, g_damageFeedTakenTD[ playerid ] );
			g_damageFeedTakenTD[ playerid ] = PlayerText: INVALID_TEXT_DRAW;
		}

		return 1;
	}

	/* ** Textdraws ** */
	if ( g_damageFeedGivenTD[ playerid] == PlayerText: INVALID_TEXT_DRAW )
	{
		new PlayerText: handle = CreatePlayerTextDraw( playerid, 200.000000, 340.000000, "_");

		if ( handle == PlayerText: INVALID_TEXT_DRAW )
			return print("[DAMAGE FEED ERROR]: Unable to create TD (given damage)" );

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
		new PlayerText: handle = CreatePlayerTextDraw( playerid, 440.000000, 340.000000, "_");

		if ( handle == PlayerText: INVALID_TEXT_DRAW )
			return print("[DAMAGE FEED ERROR]: Unable to create TD (taken damage)" );

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
	if ( szTick == 0 ) szTick = 1;
	new lowest_tick = szTick + 1;

	for( new givenid = 0; givenid < sizeof( g_damageGiven[ ] ) - 1; givenid ++)
	{
		if ( !g_damageGiven[ playerid ][ givenid ][ E_TICK ] ) {
			break;
		}

		if ( szTick - g_damageGiven[ playerid ][ givenid ][ E_TICK ] >= HIDE_FEED_DELAY )
		{
			modified = true;

			for( new j = givenid; j < sizeof( g_damageGiven[ ] ) - 1; j++ ) {
				g_damageGiven[ playerid ][ j ][ E_TICK ] = 0;
			}

			break;
		}

		if ( g_damageGiven[ playerid ][ givenid ][ E_TICK ] < lowest_tick ) {
			lowest_tick = g_damageGiven[ playerid ][ givenid ][ E_TICK ];
		}
	}

	for( new takenid = 0; takenid < sizeof( g_damageTaken[ ] ) - 1; takenid ++)
	{
		if ( !g_damageTaken[ playerid ][ takenid ][ E_TICK ] ) {
			break;
		}

		if ( szTick - g_damageTaken[ playerid ][ takenid ][ E_TICK ] >= HIDE_FEED_DELAY )
		{
			modified = true;

			for( new j = takenid; j < sizeof( g_damageTaken[ ] ) - 1; j++ ) {
				g_damageTaken[ playerid ][ j ][ E_TICK ] = 0;
			}

			break;
		}

		if ( g_damageTaken[ playerid ][ takenid ][ E_TICK ] < lowest_tick ) {
			lowest_tick = g_damageTaken[ playerid ][ takenid ][ E_TICK ];
		}
	}

	if ( p_damageFeedTimer[ playerid ] != -1 ) {
		KillTimer( p_damageFeedTimer[ playerid ] );
	}

	if ( ( szTick - p_lastFeedUpdate[ playerid ] ) < MAX_UPDATE_RATE && modified )
	{
		p_damageFeedTimer[ playerid ] = SetTimerEx( "OnPlayerFeedUpdate", MAX_UPDATE_RATE - ( szTick - lowest_tick ) + 10, false, "d", playerid );
	}
	else
	{
		if ( lowest_tick == ( szTick + 1 ) )
		{
			p_damageFeedTimer[playerid] = -1;
			modified = true;
		}
		else
		{
			p_damageFeedTimer[playerid] = SetTimerEx( "OnPlayerFeedUpdate", HIDE_FEED_DELAY - ( szTick - lowest_tick ) + 10, false, "i", playerid );
		}

		if (modified)
		{
			UpdateDamageFeedLabel( playerid );

			p_lastFeedUpdate[ playerid ] = szTick;
		}
	}

	return 1;
}

stock UpdateDamageFeedLabel( playerid )
{
	new 
		szLabel[ 64 * MAX_FEED_HEIGHT ] = "";

	for( new givenid = 0; givenid < sizeof( g_damageGiven[ ] ) - 1; givenid ++)
	{
		if ( !g_damageGiven[ playerid ][ givenid ][ E_TICK ] )
			break;

		new szWeapon[ 32 ];

		if ( g_damageGiven[ playerid ][ givenid ][ E_WEAPON ] == -1 ) {
			szWeapon = "Multiple";
		}
		else {
			GetWeaponName( g_damageGiven[ playerid ][ givenid ][ E_WEAPON ], szWeapon, sizeof( szWeapon ) );
		}

		if ( g_damageGiven[ playerid ][ givenid ][ E_ISSUER ] == INVALID_PLAYER_ID )
		{
			format( szLabel, sizeof( szLabel ), "%s%s +%.2f~n~", szLabel, szWeapon, g_damageGiven[ playerid ][ givenid ][ E_AMOUNT ] + 0.009 );
		}
		else
		{
			format( szLabel, sizeof( szLabel ), "%s%s - %s +%.2f~n~", szLabel, szWeapon, g_damageGiven[ playerid ][ givenid ][ E_NAME ], g_damageGiven[ playerid ][ givenid ][ E_AMOUNT ] + 0.009 );
		}
	}

	if ( g_damageFeedGivenTD[ playerid ] == PlayerText: INVALID_TEXT_DRAW ) {
		print( "[DAMAGE FEED ERROR] Doesn't have feed textdraw when needed ( g_damageFeedGivenTD )" );
	}
	else
	{
		if ( szLabel[ 0 ] )
		{
			PlayerTextDrawSetString( playerid, g_damageFeedGivenTD[ playerid ], szLabel );
			PlayerTextDrawShow( playerid, g_damageFeedGivenTD[ playerid ] );
		}
		else
		{
			PlayerTextDrawHide( playerid, g_damageFeedGivenTD[ playerid ] );
		}
	}

	szLabel = "";

	for( new takenid = 0; takenid < sizeof( g_damageTaken[ ] ) - 1; takenid ++)
	{
		if ( !g_damageTaken[ playerid ][ takenid ][ E_TICK ] )
			break;

		new szWeapon[ 32 ];

		if ( g_damageTaken[ playerid ][ takenid ][ E_WEAPON ] == -1 ) {
			szWeapon = "Multiple";
		}
		else {
			GetWeaponName( g_damageTaken[ playerid ][ takenid ][ E_WEAPON ], szWeapon, sizeof( szWeapon ) );
		}

		if ( g_damageTaken[ playerid ][ takenid ][ E_ISSUER ] == INVALID_PLAYER_ID )
		{
			format( szLabel, sizeof( szLabel ), "%s%s -%.2f~n~", szLabel, szWeapon, g_damageTaken[ playerid ][ takenid ][ E_AMOUNT ] + 0.009 );
		}
		else
		{
			format( szLabel, sizeof( szLabel ), "%s%s - %s -%.2f~n~", szLabel, szWeapon, g_damageTaken[ playerid ][ takenid ][ E_NAME ], g_damageTaken[ playerid ][ takenid ][ E_AMOUNT ] + 0.009 );
		}
	}

	if ( g_damageFeedTakenTD[ playerid ] == PlayerText: INVALID_TEXT_DRAW ) {
		print( "[DAMAGE FEED ERROR] Doesn't have feed textdraw when needed ( g_damageFeedTakenTD )" );
	}
	else
	{
		if ( szLabel[ 0 ] )
		{
			PlayerTextDrawSetString( playerid, g_damageFeedTakenTD[ playerid ], szLabel );
			PlayerTextDrawShow( playerid, g_damageFeedTakenTD[ playerid ] );
		}
		else
		{
			PlayerTextDrawHide( playerid, g_damageFeedTakenTD[ playerid ] );
		}
	}
}

stock RemoveDamageHit( array[ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ], index )
{
	for( new i = 0; i < MAX_FEED_HEIGHT; i ++ )
	{
		if ( i >= index ) {
			array[ i ][ E_TICK ] = 0;
		}
	}
}

stock AddDamageHit( array[ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ], playerid, issuerid, Float: amount, weapon )
{
	if ( ! IsDamageFeedActive( playerid ) ) {
		return;
	}

	new szTick = GetTickCount( );
	if ( szTick == 0 ) szTick = 1;
	new wID = -1;

	for( new i = 0; i < sizeof( array ); i ++ )
	{
		if ( ! array[ i ][ E_TICK ] ) {
			break;
		}

		if ( szTick - array[ i ][ E_TICK ] >= HIDE_FEED_DELAY ) {
			RemoveDamageHit( array, i );
			break;
		}

		if ( array[ i ][ E_ISSUER ] == issuerid )
		{
			amount += array[ i ][ E_AMOUNT ];
			wID = i;
			break;
		}
	}

	if ( wID == -1 )
	{
		wID = 0;

		for( new i = sizeof( array ) - 1; i >= 1; i -- )
		{
			array[ i ] = array[ i - 1 ];
		}
	}

	array[ wID ][ E_TICK ] = szTick;
	array[ wID ][ E_AMOUNT ] = amount;
	array[ wID ][ E_ISSUER ] = issuerid;
	array[ wID ][ E_WEAPON ] = weapon;

	GetPlayerName( issuerid, array[ wID ][ E_NAME ] , MAX_PLAYER_NAME );

	UpdateDamageFeed( playerid, true );
}

stock AddDamageFeedHit( playerid, issuerid, Float: amount, weaponid, type )
{
	if ( type == TYPE_GIVEN )
	{
		foreach( new i : Player ) if ( i != playerid) {
			AddDamageHit( g_damageGiven[ i ], i, issuerid, amount, weaponid );
		}

		AddDamageHit( g_damageGiven[ playerid ], playerid, issuerid, amount, weaponid );
	}
	else if ( type == TYPE_TAKEN )
	{
		foreach( new i : Player ) if ( i != playerid) {
			AddDamageHit( g_damageTaken[ i ], i, issuerid, amount, weaponid );
		}

		AddDamageHit( g_damageTaken[ playerid ], playerid, issuerid, amount, weaponid );
	}
}

/* ** Commands ** */
CMD:feed( playerid, params[ ] )
{
	p_FeedActive{ playerid } = !p_FeedActive{ playerid };

	SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have %s the damage feed.", p_FeedActive{ playerid } ? ( "toggled" ) : ( "un-toggled" ) );
	return 1;
}