/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cannon.inc
 * Purpose: orbital cannon implementation for gang facilities
 */

#if !defined MAX_FACILITIES
	#error "This module requires facility module!"
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define ORBITAL_CANNON_TICK 		( 100 )

/* ** Variables ** */
enum E_ORBITAL_CANNON_DATA
{
	Float: E_POS[ 3 ], 				Float: E_ZOOM, 				E_TIMER,
	E_FIRE_TICK, 					E_COOL_DOWN
};

new
	g_orbitalCannonData 			[ MAX_FACILITIES ] [ E_ORBITAL_CANNON_DATA ],
	p_usingOrbitalCannon 			[ MAX_PLAYERS ] = { -1, ... },
	Text: g_orbitalAimTD 			= Text: INVALID_TEXT_DRAW,
	Text3D: g_orbitalPlayerLabels 	[ MAX_FACILITIES ] [ MAX_PLAYERS ],

	p_Weapons 						[ MAX_PLAYERS ][ 13 ],
	p_Ammo 							[ MAX_PLAYERS ][ 13 ],
	Float: p_Health 				[ MAX_PLAYERS ],
	Float: p_Armour 				[ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// textdraw
	g_orbitalAimTD = TextDrawCreate( 305.000000, 205.000000, "+" );
	TextDrawBackgroundColor( g_orbitalAimTD, 0 );
	TextDrawFont( g_orbitalAimTD, 2 );
	TextDrawLetterSize( g_orbitalAimTD, 1.000000, 4.000000 );
	TextDrawColor( g_orbitalAimTD, -16777152 );
	TextDrawSetOutline( g_orbitalAimTD, 1 );
	TextDrawSetProportional( g_orbitalAimTD, 1 );

	// starting data
	for ( new facilityid = 0; facilityid < sizeof( g_orbitalCannonData ); facilityid ++ ) {
		g_orbitalCannonData[ facilityid ] [ E_TIMER ] = -1;
		for ( new i = 0; i < sizeof( g_orbitalPlayerLabels[ ] ); i ++ ) {
			g_orbitalPlayerLabels[ facilityid ] [ i ] = Text3D: INVALID_3DTEXT_ID;
		}
	}
	return 1;
}

hook SetPlayerRandomSpawn( playerid )
{
	if ( GetPVarType( playerid, "left_cannon" ) != PLAYER_VARTYPE_NONE )
	{
		new facilityid = GetPVarInt( playerid, "left_cannon" );
		new int_type = g_gangFacilities[ facilityid ] [ E_INTERIOR_TYPE ];

		// place in facility
		pauseToLoad( playerid );
		SetPVarInt( playerid, "in_facility", facilityid );
	    UpdatePlayerEntranceExitTick( playerid );
		SetPlayerPos( playerid, g_gangFacilityInterior[ int_type ] [ E_CANNON_POS ] [ 0 ], g_gangFacilityInterior[ int_type ] [ E_CANNON_POS ] [ 1 ], g_gangFacilityInterior[ int_type ] [ E_CANNON_POS ] [ 2 ] );
	  	SetPlayerVirtualWorld( playerid, g_gangFacilities[ facilityid ] [ E_WORLD ] );
		SetPlayerInterior( playerid, 0 );
		SetPlayerHealth( playerid, p_Health[ playerid ] );
		SetPlayerArmour( playerid, p_Armour[ playerid ] );

		for ( new iWeapon; iWeapon < 13; iWeapon ++ ) {
			GivePlayerWeapon( playerid, p_Weapons[ playerid ][ iWeapon ], p_Ammo[ playerid ][ iWeapon ] );
		}

		// set camera
		DeletePVar( playerid, "left_cannon" );
		SetCameraBehindPlayer( playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	ClosePlayerOrbitalCannon( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath(playerid, killerid, reason)
#endif
{
	ClosePlayerOrbitalCannon( playerid );
	return 1;
}

/* ** Callbacks ** */
function OnPlayerOrbitalCannonUpdate( facilityid, playerid )
{
	new Float: current_pos[ 3 ];
	new Float: move_unit = 10.0;
	new keys, ud, lr;

	GetPlayerKeys( playerid, keys, ud, lr );

	// store local positions
	current_pos[ 0 ] = g_orbitalCannonData[ facilityid ] [ E_POS ] [ 0 ];
	current_pos[ 1 ] = g_orbitalCannonData[ facilityid ] [ E_POS ] [ 1 ];
	MapAndreas_FindZ_For2DCoord( current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ] );

	// close
	if ( ( keys & KEY_CROUCH ) || IsPlayerJailed( playerid ) || IsPlayerAFK( playerid ) || ( GetPlayerCash( playerid ) < 250000 && ! g_orbitalCannonData[ facilityid ] [ E_COOL_DOWN ] ) )
	{
		SetPVarInt( playerid, "left_cannon", facilityid );
		HidePlayerHelpDialog( playerid );
		if ( IsPlayerMovieMode( playerid ) ) cmd_moviemode( playerid, "" );
		ClosePlayerOrbitalCannon( playerid );
		return TogglePlayerSpectating( playerid, 0 );
	}

    // fire ammo
    if ( ( keys & KEY_SPRINT ) && ! g_orbitalCannonData[ facilityid ] [ E_COOL_DOWN ] )
    {
    	// add tick (ms) for countdown
    	g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] += ORBITAL_CANNON_TICK;

    	// just pressed fire? move camera
    	if ( g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] == ORBITAL_CANNON_TICK ) {
		    // smoothly move camera
			InterpolateCameraPos(
				playerid,
				g_orbitalCannonData[ facilityid ] [ E_POS ] [ 0 ], g_orbitalCannonData[ facilityid ] [ E_POS ] [ 1 ],
				current_pos[ 2 ] + g_orbitalCannonData[ facilityid ] [ E_ZOOM ],
				current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ] + g_orbitalCannonData[ facilityid ] [ E_ZOOM ] + 50.0,
				5000
			);

			InterpolateCameraLookAt(
				playerid,
				g_orbitalCannonData[ facilityid ] [ E_POS ] [ 0 ], g_orbitalCannonData[ facilityid ] [ E_POS ] [ 1 ], current_pos[ 2 ],
				current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ],
				5000
			);
    	}

    	// alert
    	if ( g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] % 1000 == 0 )
    	{
			if ( g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] > 3000 )
			{
				g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] = 0;
				g_orbitalCannonData[ facilityid ] [ E_COOL_DOWN ] = ORBITAL_CANNON_TICK * 20;

				new rocket = CreateDynamicObject( 3786, current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ] + g_orbitalCannonData[ facilityid ] [ E_ZOOM ], 5.0, -90.0, 0.0 );
				new move_speed = MoveDynamicObject( rocket, current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ], 100.0 );
				Streamer_Update( playerid, STREAMER_TYPE_OBJECT );

				GivePlayerCash( playerid, -250000 );
				PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );
	 			GameTextForPlayer( playerid, "~g~FIRED!", 2000, 3 );
	 			SendServerMessage( playerid, "You have launched an orbital cannon for "COL_GOLD"$250,000"COL_WHITE", you have %s left.", cash_format( GetPlayerCash( playerid ) ) );
				return SetTimerEx( "OnPlayerFireOrbitalCannon", move_speed, false, "ddfff", playerid, rocket, current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ] );
			}
			else
			{
				g_orbitalCannonData[ facilityid ] [ E_ZOOM ] += 2.0;
		 		GameTextForPlayer( playerid, sprintf( "~r~%d", g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] / 1000 ), 2000, 3 );
				PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
			}
    	}
    }
    else
    {
    	g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] = 0;
    }

    // deduct cooldown
    if ( g_orbitalCannonData[ facilityid ] [ E_COOL_DOWN ] && ( g_orbitalCannonData[ facilityid ] [ E_COOL_DOWN ] -= ORBITAL_CANNON_TICK ) <= 0 )
    	g_orbitalCannonData[ facilityid ] [ E_COOL_DOWN ] = 0;

    // begin movement
	if ( ! g_orbitalCannonData[ facilityid ] [ E_FIRE_TICK ] )
	{
	    // zoom in
	    if ( g_orbitalCannonData[ facilityid ] [ E_ZOOM ] > 75.0 ) move_unit = g_orbitalCannonData[ facilityid ] [ E_ZOOM ] / 7.5;
	    else if ( g_orbitalCannonData[ facilityid ] [ E_ZOOM ] <= 20.0 ) move_unit = 5.0;

	    // move camera
	    if ( ud == KEY_UP ) current_pos[ 1 ] += move_unit;
	    else if ( ud == KEY_DOWN ) current_pos[ 1 ] -= move_unit;

	    if ( lr == KEY_LEFT ) current_pos[ 0 ] -= move_unit;
	    else if ( lr == KEY_RIGHT ) current_pos[ 0 ] += move_unit;

	    // zoom in
	    if ( keys & KEY_FIRE ) {
	    	if ( ( g_orbitalCannonData[ facilityid ] [ E_ZOOM ] -= move_unit ) < 20.0 ) {
	    		g_orbitalCannonData[ facilityid ] [ E_ZOOM ] = 20.0;
	    	}
	    }
	    else if ( keys & KEY_AIM )  {
	    	if ( ( g_orbitalCannonData[ facilityid ] [ E_ZOOM ] += move_unit ) > 300.0 ) {
	    		g_orbitalCannonData[ facilityid ] [ E_ZOOM ] = 300.0;
	    	}
	    }

	    // smoothly move camera
		InterpolateCameraPos(
			playerid,
			g_orbitalCannonData[ facilityid ] [ E_POS ] [ 0 ], g_orbitalCannonData[ facilityid ] [ E_POS ] [ 1 ], g_orbitalCannonData[ facilityid ] [ E_POS ] [ 2 ] + g_orbitalCannonData[ facilityid ] [ E_ZOOM ],
			current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ] + g_orbitalCannonData[ facilityid ] [ E_ZOOM ],
			150
		);

		InterpolateCameraLookAt(
			playerid,
			g_orbitalCannonData[ facilityid ] [ E_POS ] [ 0 ], g_orbitalCannonData[ facilityid ] [ E_POS ] [ 1 ], g_orbitalCannonData[ facilityid ] [ E_POS ] [ 2 ],
			current_pos[ 0 ], current_pos[ 1 ], current_pos[ 2 ],
			150
		);
	}

	// update
	g_orbitalCannonData[ facilityid ] [ E_POS ] = current_pos;
	return 1;
}

function OnPlayerFireOrbitalCannon( playerid, rocketid, Float: X, Float: Y, Float: Z )
{
	new Float: player_X, Float: player_Y, Float: player_Z;

	// destroy the rocket after it is moved
	DestroyDynamicObject( rocketid );

	// kill everyone in that area
	foreach ( new i : Player ) if ( GetPlayerGang( i ) != GetPlayerGang( playerid ) && GetPlayerVirtualWorld( i ) == 0 && GetPlayerInterior( i ) == 0 && ! IsPlayerJailed( i ) && ! IsPlayerAdminOnDuty( i ) && ! IsPlayerSpawnProtected( i ) )
	{
		new
			player_state = GetPlayerState( i );

		if ( GetPlayerPos( i, player_X, player_Y, player_Z ) && player_Z >= ( Z - 20.0 ) && player_state != PLAYER_STATE_WASTED && player_state != PLAYER_STATE_SPECTATING )
		{
			new
				Float: distance_squared = VectorSize( player_X - X, player_Y - Y, 0.0 );

			if ( distance_squared < 30.0 )
			{
				// slay user
				#if defined AC_INCLUDED
					ForcePlayerKill( i, playerid, 51 );
				#else
					SetPlayerHealth( i, -1 );
				#endif

				// explode player
				SendClientMessageToAllFormatted( -1, ""COL_ORANGE"[ORBITAL CANNON]"COL_WHITE" %s(%d) got rekt by %s(%d)'s orbital cannon.", ReturnPlayerName( i ), i, ReturnPlayerName( playerid ), playerid );
				CreateExplosion( player_X, player_Y, player_Z, 0, 10.0 );
				continue;
			}
		}
	}

	// create explosion
	CreateExplosion( X, Y, Z, 6, 10.0 );
	return 1;
}

/* ** Functions ** */
stock StartPlayerOrbitalCannon( playerid, facilityid )
{
	if ( g_orbitalCannonData[ facilityid ] [ E_TIMER ] != -1 )
		return 0;

	// player
	for ( new iWeapon; iWeapon < 13; iWeapon ++ )
		GetPlayerWeaponData( playerid, iWeapon, p_Weapons[ playerid ][ iWeapon ], p_Ammo[ playerid ][ iWeapon ] );

	GetPlayerHealth( playerid, p_Health[ playerid ] );
	GetPlayerArmour( playerid, p_Armour[ playerid ] );

	SetPlayerInterior( playerid, 0 );
	SetPlayerVirtualWorld( playerid, 0 );
	TogglePlayerSpectating( playerid, 1 );
	TextDrawShowForPlayer( playerid, g_orbitalAimTD );
	ShowPlayerHelpDialog( playerid, 0, "~y~Arrows~w~ - Move camera~n~~y~~k~~PED_FIREWEAPON~~w~ - Zoom in~n~~y~~k~~PED_LOCK_TARGET~~w~ - Zoom out~n~~y~~k~~PED_SPRINT~~w~ - Fire cannon ~g~($250,000)~n~~y~~k~~PED_DUCK~~w~ - Cancel" );
	p_usingOrbitalCannon[ playerid ] = facilityid;
	if ( ! IsPlayerMovieMode( playerid ) ) cmd_moviemode( playerid, "" );

	// destroy labels (created on stream out/in anyway)
	for ( new i = 0; i < sizeof( g_orbitalPlayerLabels[ ] ); i ++ ) {
		DestroyDynamic3DTextLabel( g_orbitalPlayerLabels[ facilityid ] [ i ] );
		g_orbitalPlayerLabels[ facilityid ] [ i ] = Text3D: INVALID_3DTEXT_ID;
	}

	// set cannon position
	g_orbitalCannonData[ facilityid ] [ E_POS ] [ 0 ] = g_gangFacilities[ facilityid ] [ E_X ];
	g_orbitalCannonData[ facilityid ] [ E_POS ] [ 1 ] = g_gangFacilities[ facilityid ] [ E_Y ];
	g_orbitalCannonData[ facilityid ] [ E_POS ] [ 2 ] = g_gangFacilities[ facilityid ] [ E_Z ];

	// set zoom of camera
	g_orbitalCannonData[ facilityid ] [ E_POS ] [ 2 ] += ( g_orbitalCannonData[ facilityid ] [ E_ZOOM ] += 100.0 );

	g_orbitalCannonData[ facilityid ] [ E_TIMER ] = SetTimerEx( "OnPlayerOrbitalCannonUpdate", ORBITAL_CANNON_TICK, true, "dd", facilityid, playerid );
	return 1;
}

hook OnPlayerStreamIn( playerid, forplayerid )
{
	if ( ! IsPlayerNPC( playerid ) && IsPlayerUsingOrbitalCannon( forplayerid ) )
	{
		new
			facilityid = p_usingOrbitalCannon[ forplayerid ];

		if ( 0 <= facilityid < sizeof( g_orbitalCannonData ) )
		{
			if ( ! IsValidDynamic3DTextLabel( g_orbitalPlayerLabels[ facilityid ] [ playerid ] ) )
			{
				g_orbitalPlayerLabels[ facilityid ] [ playerid ] = CreateDynamic3DTextLabel(
					sprintf( "%s(%d)", ReturnPlayerName( playerid ), playerid ),
					setAlpha( GetPlayerColor( playerid ), 0xFF ),
					0.0, 0.0, 0.0, 300.0,
					.attachedplayer = playerid,
					.testlos = 0,
					.playerid = forplayerid,
					.streamdistance = 300.0
				);
			}
		}
	}
	return 1;
}

hook OnPlayerStreamOut( playerid, forplayerid )
{
	if ( ! IsPlayerNPC( playerid ) && IsPlayerUsingOrbitalCannon( forplayerid ) )
	{
		new
			facilityid = p_usingOrbitalCannon[ forplayerid ];

		if ( 0 <= facilityid < sizeof( g_orbitalCannonData ) )
		{
			if ( IsValidDynamic3DTextLabel( g_orbitalPlayerLabels[ facilityid ] [ playerid ] ) )
			{
				DestroyDynamic3DTextLabel( g_orbitalPlayerLabels[ facilityid ] [ playerid ] );
				g_orbitalPlayerLabels[ facilityid ] [ playerid ] = Text3D: INVALID_3DTEXT_ID;
			}
		}
	}
	return 1;
}

stock ClosePlayerOrbitalCannon( playerid ) {

	new
		facilityid = p_usingOrbitalCannon[ playerid ];

	// remove user
	p_usingOrbitalCannon[ playerid ] = -1;
	TextDrawHideForPlayer( playerid, g_orbitalAimTD );

	// reset facility portion
	if ( 0 <= facilityid < sizeof( g_orbitalCannonData ) )
	{
		// remove label associated
		for ( new i = 0; i < sizeof( g_orbitalPlayerLabels[ ] ); i ++ ) {
			DestroyDynamic3DTextLabel( g_orbitalPlayerLabels[ facilityid ] [ i ] );
			g_orbitalPlayerLabels[ facilityid ] [ i ] = Text3D: INVALID_3DTEXT_ID;
		}

		// kill timer
		KillTimer( g_orbitalCannonData[ facilityid ] [ E_TIMER ] );
		g_orbitalCannonData[ facilityid ] [ E_TIMER ] = -1;
	}
	return 1;
}

stock IsPlayerUsingOrbitalCannon( playerid ) {
	return p_usingOrbitalCannon[ playerid ] != -1;
}
