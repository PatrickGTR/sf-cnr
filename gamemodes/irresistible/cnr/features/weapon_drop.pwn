/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc_
 * Module: weapon_drop.inc
 * Purpose: weapon drop system for players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Handling ** */
#if !defined __WEAPONDAMAGEINC__
	#error "This module requires weapon data functions"
#endif

#define WEAPON_DROP_ENABLED

/* ** Definitions ** */
#define MAX_WEAPON_DROPS 			( 50 )

#define WEAPON_HEALTH 				( 100 )
#define WEAPON_ARMOUR 				( 101 )

/* ** Variables ** */
enum E_WEAPONDROP_DATA {
	E_WEAPON_ID,			E_AMMO,				E_PICKUP,
	E_EXPIRE_TIMESTAMP,		E_SLOT_ID
};

static g_weaponDropData 		[ MAX_WEAPON_DROPS ] [ E_WEAPONDROP_DATA ];
static Iterator: weapondrop 	< MAX_WEAPON_DROPS >;

static const g_rankHealthPayout[ ] = { 100, 75, 50, 45, 40, 35, 30, 25, 20, 15, 10 };

static g_HealthPickup;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	g_HealthPickup = CreateDynamicPickup( 1240, 3, -1980.3679, 884.4898, 45.2031 );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	static
		Float: X, Float: Y, Float: Z;

	if ( IsPlayerConnected( killerid ) && ! IsPlayerNPC( killerid ) )
	{
		if ( IsPlayerJailed( playerid ) || IsPlayerInPaintBall( playerid ) || IsPlayerInEvent( playerid ) || IsPlayerDueling( playerid ) )
			return 1;

		GetPlayerPos( playerid, X, Y, Z );


		new
			killer_rank = GetPlayerRank( killerid ),
			expire_time = gettime( ) + 180;

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
				CreateWeaponPickup( weaponid, ammo, slotid, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, expire_time );
			}
		}

		// health drop
		CreateWeaponPickup( WEAPON_HEALTH, g_rankHealthPayout[ killer_rank ], 0, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, expire_time );
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
		SetPlayerHealth( playerid, 100.0 );
		return 1;
	}

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

/* ** Functions ** */
stock CreateWeaponPickup( weaponid, ammo, slotid, Float: X, Float: Y, Float: Z, expire_time ) {

	new handle = Iter_Free( weapondrop );

	if ( handle != ITER_NONE )
	{
		g_weaponDropData[ handle ] [ E_PICKUP ] = CreateDynamicPickup( weaponid == WEAPON_HEALTH ? 1240 : GetWeaponModel( weaponid ), 1, X, Y, Z );
		g_weaponDropData[ handle ] [ E_EXPIRE_TIMESTAMP ] = expire_time;
		g_weaponDropData[ handle ] [ E_WEAPON_ID ] = weaponid;
		g_weaponDropData[ handle ] [ E_AMMO ] = ammo;
		g_weaponDropData[ handle ] [ E_SLOT_ID ] = slotid;
		Iter_Add( weapondrop, handle );
	}
	else
	{
		ClearInactiveWeaponDrops( gettime( ) );
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

stock ClearInactiveWeaponDrops( global_timestamp )
{
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
