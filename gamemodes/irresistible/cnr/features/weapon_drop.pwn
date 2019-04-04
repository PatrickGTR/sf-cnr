/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: weapon_drop.inc
 * Purpose: weapon drop system for players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Handling ** */
#if !defined __WEAPONDAMAGEINC__
	#error "This module requires weapon data functions"
#endif

/* ** Definitions ** */
#define MAX_WEAPON_DROPS 			( 100 )

#define WEAPON_HEALTH 				( 100 )
#define WEAPON_ARMOUR 				( 101 )
#define WEAPON_MONEY				( 102 )

/* ** Variables ** */
enum E_WEAPONDROP_DATA {
	E_WEAPON_ID,			E_AMMO,				E_PICKUP,
	E_EXPIRE_TIMESTAMP,		E_SLOT_ID
};

static g_weaponDropData 		[ MAX_WEAPON_DROPS ] [ E_WEAPONDROP_DATA ];
static Iterator: weapondrop 	< MAX_WEAPON_DROPS >;
static p_PlayerPickupDelay 		[ MAX_PLAYERS ];

static g_HealthPickup;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	g_HealthPickup = CreateDynamicPickup( 1240, 3, -1980.3679, 884.4898, 45.2031 );
	return 1;
}

hook OnServerUpdate( )
{
	ClearInactiveWeaponDrops( );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	if ( IsPlayerJailed( playerid ) || IsPlayerInPaintBall( playerid ) || IsPlayerInEvent( playerid ) || IsPlayerDueling( playerid ) || IsPlayerLeavingPaintball( playerid ) )
		return 1; // do not break return

	new Float: X, Float: Y, Float: Z;

	new worldid = GetPlayerVirtualWorld( playerid );

	new expire_time = GetServerTime( ) + 180;

	GetPlayerPos( playerid, X, Y, Z );

	if ( IsPlayerConnected( killerid ) && ! IsPlayerNPC( killerid ) )
	{
		for ( new slotid = 0; slotid < 13; slotid++ )
		{
		    new
				weaponid,
				ammo;

			GetPlayerWeaponData( playerid, slotid, weaponid, ammo );

			// third of what player had
			ammo /= 10;

			// check valid parameters and shit
			if ( weaponid != 0 && 1 < ammo < 5000 && ! IsWeaponBanned( weaponid ) ) {
				CreateWeaponPickup( weaponid, ammo, slotid, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, expire_time, worldid );
			}
		}

		new
			killer_dm_level = floatround( GetPlayerLevel( killerid, E_DEATHMATCH ) );

		if ( killer_dm_level > 100 ) {
			killer_dm_level = 100;
		}

		// health drop
		if ( killer_dm_level >= 10 ) {
			CreateWeaponPickup( WEAPON_HEALTH, killer_dm_level, 0, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, expire_time, worldid );
		}

		// random armour drop (1% chance)
		if ( killer_dm_level >= 50 && random( 101 ) == 66 ) {
			CreateWeaponPickup( WEAPON_ARMOUR, killer_dm_level, 0, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, expire_time, worldid );
		}
	}

	// drop player money
	new
		player_money = floatround( float( GetPlayerCash( playerid ) ) * 0.1 );

	// throttle drop amount to 25K
	if ( player_money > 25000 ) {
		player_money = 25000;
	}

	if ( player_money > 0 )
	{
		// half the amount lost through secure wallet
		if ( p_SecureWallet{ playerid } ) {
			player_money = floatround( float( player_money ) * 0.5 );
		}

		// message the player
		ShowPlayerHelpDialog( playerid, 5000, "~w~You have dropped ~r~%s", cash_format( player_money ) );

		// reduce player money
		GivePlayerCash( playerid, -player_money );
		CreateWeaponPickup( WEAPON_MONEY, player_money, 0, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, expire_time, worldid );
	}
	return 1;
}

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
	new keys;
	new existing_weapon;
	new existing_ammo;

	// Health Pickups
	if ( pickupid == g_HealthPickup ) {
		new Float: health;
		if ( GetPlayerHealth( playerid, health ) <= 100 ) return SetPlayerHealth( playerid, 100.0 );
	}

	// ignore if theres a delay
	if ( p_PlayerPickupDelay[ playerid ] > GetServerTime( ) )
		return 1;

	// Player Drops
	foreach ( new dropid : weapondrop )
	{
		if ( g_weaponDropData[ dropid ] [ E_PICKUP ] == pickupid )
		{
			if ( g_weaponDropData[ dropid ] [ E_WEAPON_ID ] == WEAPON_HEALTH )
			{
				new
					Float: health;

				if ( GetPlayerHealth( playerid, health ) )
				{
					// no weed like effects
					if ( ( health += float( g_weaponDropData[ dropid ] [ E_AMMO ] ) ) > 100.0 ) {
						health = 100.0;
					}

					SetPlayerHealth( playerid, health );
				}
			}
			else if ( g_weaponDropData[ dropid ] [ E_WEAPON_ID ] == WEAPON_ARMOUR )
			{
				new
					Float: armour;

				if ( GetPlayerArmour( playerid, armour ) )
				{
					// no weed like effects
					if ( ( armour += float( g_weaponDropData[ dropid ] [ E_AMMO ] ) ) > 100.0 ) {
						armour = 100.0;
					}

					SetPlayerArmour( playerid, armour );
				}
			}
			else if ( g_weaponDropData[ dropid ] [ E_WEAPON_ID ] == WEAPON_MONEY )
			{
				new
					dropped_money = g_weaponDropData[ dropid ] [ E_AMMO ];

				GivePlayerCash( playerid, dropped_money );

				if ( ! g_weaponDropData[ dropid ] [ E_EXPIRE_TIMESTAMP ] && dropped_money )
				{
					new
						szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

					if ( GetPlayerLocation( playerid, szCity, szLocation ) ) {
						SendClientMessageToAllFormatted( -1, ""COL_GREEN"[MONEY BAG]"COL_WHITE" %s(%d) has picked up a %s money bag near %s in %s!", ReturnPlayerName( playerid ), playerid, cash_format( dropped_money ), szLocation, szCity );
					} else {
						SendServerMessage( playerid, "You have found "COL_GOLD"%s"COL_WHITE" on the ground.", cash_format( dropped_money ) );
					}

				} else {
					SendServerMessage( playerid, "You have found "COL_GOLD"%s"COL_WHITE" on the ground.", cash_format( dropped_money ) );
				}
			}
			else
			{
				new
					current_weapon = GetPlayerWeapon( playerid );

				GetPlayerKeys( playerid, keys, existing_weapon, existing_weapon );
				GetPlayerWeaponData( playerid, g_weaponDropData[ dropid ] [ E_SLOT_ID ], existing_weapon, existing_ammo );

				new
					holding_replace_key = ( keys & KEY_ACTION );

				if ( ! holding_replace_key )
				{
					new
						setting_enabled = IsPlayerSettingToggled( playerid, SETTING_WEAPON_PICKUP );

					if ( setting_enabled || ( ! setting_enabled && existing_weapon != g_weaponDropData[ dropid ] [ E_WEAPON_ID ] && existing_ammo ) )
					{
						ShowPlayerHelpDialog( playerid, 2500, "Hold ~r~~k~~PED_ANSWER_PHONE~~w~ To Take %s", ReturnWeaponName( g_weaponDropData[ dropid ] [ E_WEAPON_ID ] ) );
						return 1;
					}
				}

				GivePlayerWeapon( playerid, g_weaponDropData[ dropid ] [ E_WEAPON_ID ], g_weaponDropData[ dropid ] [ E_AMMO ] );

				// don't change player weapon
				if ( ! holding_replace_key ) {
					SetPlayerArmedWeapon( playerid, current_weapon );
				}
			}

			// destroy health pickup
			PlayerPlaySound( playerid, 1150, 0.0, 0.0, 0.0 );
			DestroyWeaponPickup( dropid );
			return 1;
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:moneybag( playerid, params[ ] ) return cmd_dropmoney( playerid, params );
CMD:dm( playerid, params[ ] ) return cmd_dropmoney( playerid, params );
CMD:dropmoney( playerid, params[ ] )
{
	new
		money;

	if ( sscanf( params, "d", money ) ) return SendUsage( playerid, "/dropmoney [AMOUNT]" );
	else if ( money < 25000 ) return SendError( playerid, "The minimum amount you can drop is $25,000." );
	else if ( money > GetPlayerCash( playerid ) ) return SendError( playerid, "You do not have this much money on you." );
	//else if ( GetPlayerVIPLevel( playerid ) < VIP_REGULAR ) return SendError( playerid, "You need to be V.I.P to use this, to become one visit "COL_GREY"donate.sfcnr.com" );
	else if ( p_PlayerPickupDelay[ playerid ] > GetServerTime( ) ) return SendError( playerid, "You must wait %d seconds before using this command again.", p_PlayerPickupDelay[ playerid ] - GetServerTime( ) );
	else if ( GetPlayerVirtualWorld( playerid ) != 0 && GetPlayerInterior( playerid ) != 0 ) return SendError( playerid, "You need to be outside to use this command." );
	else
	{
		new
			Float: X, Float: Y, Float: Z;

		GetPlayerPos( playerid, X, Y, Z );

		if ( CreateWeaponPickup( WEAPON_MONEY, money, 0, X, Y, Z, 0 ) != ITER_NONE )
		{
		    new
				szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

			if ( ! GetPlayerLocation( playerid, szCity, szLocation ) )
				return SendError( playerid, "You cannot place a money bag in this location." );

			SendClientMessageToAllFormatted( -1, ""COL_GREEN"[MONEY BAG]"COL_WHITE" %s(%d) has dropped a %s money bag near %s in %s!", ReturnPlayerName( playerid ), playerid, cash_format( money ), szLocation, szCity );
			p_PlayerPickupDelay[ playerid ] = GetServerTime( ) + 5;
			GivePlayerCash( playerid, -money );
			Streamer_Update( playerid );
		}
		else
		{
			SendError( playerid, "Failed to create a money bag. Try again in a little bit." );
		}
	}
	return 1;
}

CMD:moneybags( playerid, params[ ] )
{
	new Float: X, Float: Y, Float: Z;
	new szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];
	new bool: has_results = false;

	szLargeString = ""COL_WHITE"Amount\t"COL_WHITE"Location\n";

	foreach ( new dropid : weapondrop ) if ( ! g_weaponDropData[ dropid ] [ E_EXPIRE_TIMESTAMP ] && g_weaponDropData[ dropid ] [ E_WEAPON_ID ] == WEAPON_MONEY  ) {

		Streamer_GetFloatData( STREAMER_TYPE_PICKUP, g_weaponDropData[ dropid ] [ E_PICKUP ], E_STREAMER_X, X );
		Streamer_GetFloatData( STREAMER_TYPE_PICKUP, g_weaponDropData[ dropid ] [ E_PICKUP ], E_STREAMER_Y, Y );
		Streamer_GetFloatData( STREAMER_TYPE_PICKUP, g_weaponDropData[ dropid ] [ E_PICKUP ], E_STREAMER_Z, Z );

		Get2DCity( szCity, X, Y, Z );
		GetZoneFromCoordinates( szLocation, X, Y, Z );

		format( szLargeString, sizeof( szLargeString ), "%s"COL_GOLD"%s\t%s, %s\n", szLargeString, cash_format( g_weaponDropData[ dropid ] [ E_AMMO ] ), szLocation, szCity );

		has_results = true;
	}

	if ( has_results ) {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "Money Bag Locations", szLargeString, "Close", "" ), 1;
	} else {
		return SendError( playerid, "There are no more money bags to show." );
	}
}

CMD:disposeweapon( playerid, params[ ] ) return cmd_dropweapon( playerid, params );
CMD:dw( playerid, params[ ] ) return cmd_dropweapon( playerid, params );
CMD:dropweapon( playerid, params[ ] ) {

	if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );

	new
	    iCurrentWeapon = GetPlayerWeapon( playerid )
	;

	if ( iCurrentWeapon != 0 )
	{
		RemoveSpecificPlayerWeapon( playerid, iCurrentWeapon, true );
		return SendServerMessage( playerid, "You have dropped your weapon." );
	} else {
		return SendError( playerid, "You are not holding any weapon." );
	}
}

/* ** Functions ** */
stock CreateWeaponPickup( weaponid, ammo, slotid, Float: X, Float: Y, Float: Z, expire_time, worldid = -1 ) {

	new handle = Iter_Free( weapondrop );

	if ( handle != ITER_NONE )
	{
		new
			modelid;

		switch ( weaponid ) {
			case WEAPON_HEALTH: modelid = 1240;
			case WEAPON_MONEY: {
				if ( ammo >= 1000 ) {
					modelid = 1550;
				} else {
					modelid = 1212;
				}
			}
			case WEAPON_ARMOUR: modelid = 1242;
			default: modelid = GetWeaponModel( weaponid );
		}

		g_weaponDropData[ handle ] [ E_EXPIRE_TIMESTAMP ] = expire_time;
		g_weaponDropData[ handle ] [ E_WEAPON_ID ] = weaponid;
		g_weaponDropData[ handle ] [ E_AMMO ] = ammo;
		g_weaponDropData[ handle ] [ E_SLOT_ID ] = slotid;

		// create pickup, but for specific group
		g_weaponDropData[ handle ] [ E_PICKUP ] = CreateDynamicPickup( modelid, 1, X, Y, Z, .worldid = worldid );

		// add to iterator
		Iter_Add( weapondrop, handle );
	}
	else
	{
		ClearInactiveWeaponDrops( );
	}
	return handle;
}

stock DestroyWeaponPickup( handle )
{
	if ( ! Iter_Contains( weapondrop, handle ) ) return 0;
	DestroyDynamicPickup( g_weaponDropData[ handle ] [ E_PICKUP ] );
	g_weaponDropData[ handle ] [ E_EXPIRE_TIMESTAMP ] = 0;
	g_weaponDropData[ handle ] [ E_PICKUP ] = -1;
	Iter_Remove( weapondrop, handle );
	return 1;
}

stock ClearInactiveWeaponDrops( )
{
	new
		global_timestamp = GetServerTime( );

	foreach ( new dropid : weapondrop ) if ( g_weaponDropData[ dropid ] [ E_EXPIRE_TIMESTAMP ] != 0 && global_timestamp > g_weaponDropData[ dropid ] [ E_EXPIRE_TIMESTAMP ] )
	{
		new
			cur = dropid;

		DestroyDynamicPickup( g_weaponDropData[ dropid ] [ E_PICKUP ] );
		g_weaponDropData[ dropid ] [ E_EXPIRE_TIMESTAMP ] = 0;
		g_weaponDropData[ dropid ] [ E_PICKUP ] = -1;
		Iter_SafeRemove( weapondrop, cur, dropid );
	}
	return 1;
}

stock RemoveSpecificPlayerWeapon( playerid, weaponid, bool:createpickup )
{
	new
	    iCurrentWeapon = GetPlayerWeapon( playerid ),
	    iWeaponID[ 13 ],
	    iWeaponAmmo[ 13 ]
	;

	if ( iCurrentWeapon != 0 )
	{
		for( new iSlot = 0; iSlot < sizeof( iWeaponAmmo ); iSlot++ )
		{
		    new
				iWeapon,
				iAmmo;

			GetPlayerWeaponData( playerid, iSlot, iWeapon, iAmmo );

			if ( iWeapon != iCurrentWeapon || iWeapon != weaponid ) {
			    GetPlayerWeaponData( playerid, iSlot, iWeaponID[ iSlot ], iWeaponAmmo[ iSlot ] );
			}
			else if ( createpickup )
			{
				new
					Float: X, Float: Y, Float: Z;

				if ( GetPlayerPos( playerid, X, Y, Z ) && CreateWeaponPickup( iWeapon, iAmmo, iSlot, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, GetServerTime( ) + 120, GetPlayerVirtualWorld( playerid ) ) != ITER_NONE ) {
					p_PlayerPickupDelay[ playerid ] = GetServerTime( ) + 3;
				}
			}
		}

		ResetPlayerWeapons( playerid );

		for( new iSlot = 0; iSlot < sizeof( iWeaponAmmo ); iSlot++ ) {
		    GivePlayerWeapon( playerid, iWeaponID[ iSlot ], 0 <= iWeaponAmmo[ iSlot ] < 16384 ? iWeaponAmmo[ iSlot ] : 16384 );
		}

		SetPlayerArmedWeapon( playerid, 0 ); // prevent driveby
	}
	return 1;
}