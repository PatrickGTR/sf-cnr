/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard, Oscar "Slice" Broman
 * Module: cnr/features/damage_feed.pwn
 * Purpose: damage feed for dmers
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define IsDamageFeedActive(%0) 		( IsPlayerSettingToggled( %0, SETTING_HITMARKER ) )
#define IsPlayerHit(%0)		 		( p_GotHit{%0} )

/* ** Definitions ** */
#define MAX_FEED_HEIGHT 			( 5 )
#define HIDE_FEED_DELAY 			( 3000 )
#define MAX_UPDATE_RATE 			( 250 )

#define TYPE_GIVEN 					( 1 )
#define TYPE_TAKEN 					( 2 )

#define TEXTDRAW_ADDON 				( 100.0 )

/* ** Forwards ** */
forward OnPlayerFeedUpdate 			( playerid );
forward OnPlayerTakenDamage 		( playerid, issuerid, Float: amount, weaponid, bodypart );

/* ** Variables ** */
enum E_DAMAGE_FEED
{
	E_ISSUER, 				E_NAME[ MAX_PLAYER_NAME ], 			Float: E_AMOUNT,
	E_WEAPON, 				E_TICK
};

enum E_HITMARKER_SOUND
{
	E_NAME[ 10 ], 			E_SOUND_ID
};

new 
	p_HitmarkerSound 				[ MAX_PLAYERS char ]
;

static stock
	g_damageGiven 					[ MAX_PLAYERS ][ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ],
	g_damageTaken 					[ MAX_PLAYERS ][ MAX_FEED_HEIGHT ][ E_DAMAGE_FEED ],

	Text3D: g_BulletLabel			[ MAX_PLAYERS ],
	g_BulletTimer 					[ MAX_PLAYERS ],

	p_PlayerDamageObject 			[ MAX_PLAYERS ],
	bool: p_GotHit 					[ MAX_PLAYERS char ],

	PlayerText: g_damageFeedTakenTD	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: g_damageFeedGivenTD [ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	//PlayerText: p_DamageTD          [ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },

	g_HitmarkerSounds 				[ ][ E_HITMARKER_SOUND ] =
	{
		{ "Bell Ding", 17802 }, 	{ "Soft Beep", 5205 }, 		{ "Low Blip", 1138 }, 	{ "Med Blip", 1137 },
		{ "High Blip", 1139 }, 		{ "Bling", 5201 }
	},

	p_damageFeedTimer 				[ MAX_PLAYERS ] = { -1, ... },
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

	/* ** Textdraws ** */
	/*p_DamageTD[ playerid ] = CreatePlayerTextDraw(playerid, 357.000000, 208.000000, "~r~~h~300.24 DAMAGE");
	PlayerTextDrawBackgroundColor(playerid, p_DamageTD[ playerid ], 255);
	PlayerTextDrawFont(playerid, p_DamageTD[ playerid ], 3);
	PlayerTextDrawLetterSize(playerid, p_DamageTD[ playerid ], 0.400000, 1.000000);
	PlayerTextDrawColor(playerid, p_DamageTD[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_DamageTD[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_DamageTD[ playerid ], 1);*/

	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	p_HitmarkerSound{ playerid } = 0;

	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_MODIFY_HITSOUND && response )
	{
		p_HitmarkerSound{ playerid } = listitem;
		SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your hitmarker sound to "COL_GREY"%s"COL_WHITE".", g_HitmarkerSounds[ listitem ] [ E_NAME ] );
		
		PlayerPlaySound( playerid, g_HitmarkerSounds[ listitem ] [ E_SOUND_ID ], 0.0, 0.0, 0.0 );
		ShowSoundsMenu( playerid );
	}

	return 1;
}

/* ** Functions ** */
function OnHideBulletLabel( playerid )
{
	DestroyDynamic3DTextLabel( g_BulletLabel[ playerid ] );
	KillTimer( g_BulletTimer[ playerid ] ); g_BulletTimer[ playerid ] = -1;
	return 1;
}

public OnPlayerTakenDamage( playerid, issuerid, Float: amount, weaponid, bodypart )
{
	/* ** Label Damage Indicator ** */
	if ( issuerid != INVALID_PLAYER_ID )
	{
		static Float: fromX, Float: fromY, Float: fromZ;
		static Float: toX, Float: toY, Float: toZ;

		if ( IsValidDynamic3DTextLabel( g_BulletLabel[ issuerid ] ) )
		{
			DestroyDynamic3DTextLabel( g_BulletLabel[ issuerid ] );

			KillTimer( g_BulletTimer[ issuerid ] );
			g_BulletTimer[ issuerid ] = -1;
		}

		GetPlayerLastShotVectors( issuerid, fromX, fromY, fromZ, toX, toY, toZ );

		g_BulletLabel[ issuerid ] = CreateDynamic3DTextLabel( sprintf( "%.0f", amount ), 0xC0C0C088, toX, toY, toZ, 100.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, GetPlayerVirtualWorld( playerid ), GetPlayerInterior( playerid ) );
		Streamer_Update( issuerid, STREAMER_TYPE_3D_TEXT_LABEL );

		printf( "[LABEL]: Label for %d, at %f %f %f ", playerid, toX, toY, toZ );
		g_BulletTimer[ issuerid ] = SetTimerEx( "OnHideBulletLabel", 3000, false, "d", issuerid );

		/* ** Armour and Health Object Damage ** */

		if ( !IsPlayerHit( playerid ) )
		{
			static 
				Float: fArmour;

			if ( GetPlayerArmour( playerid, fArmour ) )
			{
				p_PlayerDamageObject[ playerid ] = CreateObject( fArmour == 0 ? ( 1240 ) : ( 1242 ), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100.0 );
				AttachObjectToPlayer( p_PlayerDamageObject[ playerid ], playerid, 0.0, 0.0, 1.5, 0.0, 0.0, 0.0 );
				SetTimerEx( "HideDamageObject", 1000, false, "d", playerid );
			
				Streamer_Update(playerid, STREAMER_TYPE_OBJECT );
				p_GotHit{ playerid } = true;
			}
		}

		/* ** Hitmarker ** */
		DamageFeedAddHitGiven( issuerid, playerid, amount, weaponid );

		// play noise
		if ( IsDamageFeedActive( issuerid ) )
		{
			new
				soundid = p_VIPLevel[ issuerid ] ? p_HitmarkerSound{ issuerid } : 0;

	    	PlayerPlaySound( issuerid, g_HitmarkerSounds[ soundid ] [ E_SOUND_ID ], 0.0, 0.0, 0.0 );
	    }
	}

	DamageFeedAddHitTaken( playerid, issuerid, amount, weaponid );
	return 1;
}

function HideDamageObject( playerid )
{
	DestroyObject( p_PlayerDamageObject[ playerid ] );
	p_GotHit{ playerid } = false;
	return 1;
}

public OnPlayerFeedUpdate( playerid )
{
	p_damageFeedTimer[ playerid ] = -1;

	if ( IsPlayerConnected( playerid ) && IsDamageFeedActive( playerid ) ) {
		UpdateDamageFeed( playerid, true );
	}

	return 1;
}

stock CreateBulletLabel( playerid, weaponid, Float: amount )
{
	if ( IsPlayerInCasino( playerid ) || IsPlayerInPaintBall( playerid ) || IsPlayerInEvent( playerid ) || IsPlayerInMinigame( playerid ) )
		return;

}

stock DamageFeedAddHitGiven( playerid, issuerid, Float: amount, weaponid )
{
	foreach( new i : Player ) if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid && i != playerid ) {
		AddDamageHit( g_damageGiven[ i ], i, issuerid, amount, weaponid );
	}

	AddDamageHit( g_damageGiven[ playerid ], playerid, issuerid, amount, weaponid );
}

stock DamageFeedAddHitTaken( playerid, issuerid, Float: amount, weaponid )
{
	foreach( new i : Player ) if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid && i != playerid ) {
		AddDamageHit( g_damageTaken[ i ], i, issuerid, amount, weaponid );
	}

	AddDamageHit( g_damageTaken[ playerid ], playerid, issuerid, amount, weaponid );
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
		new PlayerText: handle = CreatePlayerTextDraw( playerid, ( 320.0 - TEXTDRAW_ADDON ), 340.0, "_");

		if ( handle == PlayerText: INVALID_TEXT_DRAW )
			return print("[DAMAGE FEED ERROR]: Unable to create TD (given damage)" );

		PlayerTextDrawBackgroundColor(playerid, handle, 117 );
		PlayerTextDrawAlignment( playerid, handle, 2 );
		PlayerTextDrawFont( playerid, handle, 1 );
		PlayerTextDrawLetterSize( playerid, handle, 0.200000, 0.899999 );
		PlayerTextDrawColor( playerid, handle, 0xDD2020FF );
		PlayerTextDrawSetOutline( playerid, handle, 1 );
		PlayerTextDrawSetProportional( playerid, handle, 1 );
		PlayerTextDrawSetSelectable( playerid, handle, 0 );

		g_damageFeedGivenTD[ playerid ] = handle;
	}

	if ( g_damageFeedTakenTD[ playerid] == PlayerText: INVALID_TEXT_DRAW )
	{
		new PlayerText: handle = CreatePlayerTextDraw( playerid, ( TEXTDRAW_ADDON + 320.0 ), 340.0, "_");

		if ( handle == PlayerText: INVALID_TEXT_DRAW )
			return print("[DAMAGE FEED ERROR]: Unable to create TD (taken damage)" );

		PlayerTextDrawBackgroundColor(playerid, handle, 117 );
		PlayerTextDrawAlignment( playerid, handle, 2 );
		PlayerTextDrawFont( playerid, handle, 1 );
		PlayerTextDrawLetterSize( playerid, handle, 0.200000, 0.899999 );
		PlayerTextDrawColor( playerid, handle, 1069804543 );
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
		p_damageFeedTimer[ playerid ] = SetTimerEx( "OnPlayerFeedUpdate", MAX_UPDATE_RATE - ( szTick - p_lastFeedUpdate[ playerid ] ) + 10, false, "d", playerid );
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
			format( szLabel, sizeof( szLabel ), "%s%s ~w~+%.2f~n~", szLabel, szWeapon, g_damageGiven[ playerid ][ givenid ][ E_AMOUNT ] );
		}
		else
		{
			format( szLabel, sizeof( szLabel ), "%s%s - %s ~w~+%.2f~n~", szLabel, szWeapon, g_damageGiven[ playerid ][ givenid ][ E_NAME ], g_damageGiven[ playerid ][ givenid ][ E_AMOUNT ] );
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
			format( szLabel, sizeof( szLabel ), "%s%s ~w~-%.2f~n~", szLabel, szWeapon, g_damageTaken[ playerid ][ takenid ][ E_AMOUNT ] );
		}
		else
		{
			format( szLabel, sizeof( szLabel ), "%s%s - %s ~w~-%.2f~n~", szLabel, szWeapon, g_damageTaken[ playerid ][ takenid ][ E_NAME ], g_damageTaken[ playerid ][ takenid ][ E_AMOUNT ] );
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

stock ShowSoundsMenu( playerid )
{
	static
		szSounds[ 11 * sizeof( g_HitmarkerSounds ) ];

	if ( szSounds[ 0 ] == '\0' )
	{
		for( new i = 0; i < sizeof( g_HitmarkerSounds ); i++ )
			format( szSounds, sizeof( szSounds ), "%s%s\n", szSounds, g_HitmarkerSounds[ i ] [ E_NAME ] );
	}
	ShowPlayerDialog( playerid, DIALOG_MODIFY_HITSOUND, DIALOG_STYLE_LIST, ""COL_WHITE"Hitmarker Sound", szSounds, "Select", "Close" );
}

/* ** Commands ** */
CMD:hitmarker( playerid, params[ ] )
{
	ShowSoundsMenu( playerid );
	return 1;
}