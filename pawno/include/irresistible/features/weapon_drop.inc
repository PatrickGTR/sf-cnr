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

/* ** Variables ** */
enum E_WEAPONDROP_DATA {
	E_WEAPON_ID,			E_AMMO,				E_PICKUP,
	E_EXPIRE_TIMESTAMP,		E_SLOT_ID
};

static g_weaponDropData 		[ MAX_WEAPON_DROPS ] [ E_WEAPONDROP_DATA ];
static Iterator: weapondrop 	< MAX_WEAPON_DROPS >;

/* ** Hooks ** */
#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	new
		Float: X, Float: Y, Float: Z;

	if ( GetPlayerPos( playerid, X, Y, Z ) )
	{
		for ( new slotid = 0; slotid < 13; slotid++ )
		{
		    new
				weaponid,
				ammo;

			GetPlayerWeaponData( playerid, slotid, weaponid, ammo );

			if ( weaponid != 0 && 1 < ammo < 5000 && ! IsWeaponBanned( weaponid ) ) {
				CreateWeaponPickup( weaponid, ammo, slotid, X + fRandomEx( 0, 3 ), Y + fRandomEx( 0, 3 ), Z, gettime( ) + 180 );
			}
		}
	}
	return 1;
}

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
	new keys;
	new existing_weapon;
	new existing_ammo;

	foreach ( new dropid : weapondrop )
	{
		if ( g_weaponDropData[ dropid ] [ E_PICKUP ] == pickupid )
		{
			GetPlayerKeys( playerid, keys, existing_weapon, existing_weapon );
			GetPlayerWeaponData( playerid, g_weaponDropData[ dropid ] [ E_SLOT_ID ], existing_weapon, existing_ammo );

			printf("Existing Weapon %d, Dropped Weapon %d, Slot id %d", existing_weapon, g_weaponDropData[ dropid ] [ E_WEAPON_ID ], g_weaponDropData[ dropid ] [ E_SLOT_ID ] );
			if ( existing_weapon > g_weaponDropData[ dropid ] [ E_WEAPON_ID ] && ! ( keys & KEY_ACTION ) && existing_ammo ) {
				GameTextForPlayer( playerid, "~r~PRESS ~k~~PED_ANSWER_PHONE~ TO TAKE WEAPON", 4000, 3 );
				return 1;
			}

		#if defined AC_INCLUDED
			p_PlayerHasWeapon[ playerid ] { g_weaponDropData[ dropid ] [ E_WEAPON_ID ] } = true;
		#endif

			PlayerPlaySound( playerid, 1150, 0.0, 0.0, 0.0 );
			GivePlayerWeapon( playerid, g_weaponDropData[ dropid ] [ E_WEAPON_ID ], g_weaponDropData[ dropid ] [ E_AMMO ] );
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
		Iter_Add( weapondrop, handle );
		g_weaponDropData[ handle ] [ E_PICKUP ] = CreateDynamicPickup( GetWeaponModel( weaponid ), 1, X, Y, Z );
		g_weaponDropData[ handle ] [ E_EXPIRE_TIMESTAMP ] = expire_time;
		g_weaponDropData[ handle ] [ E_WEAPON_ID ] = weaponid;
		g_weaponDropData[ handle ] [ E_AMMO ] = ammo;
		g_weaponDropData[ handle ] [ E_SLOT_ID ] = slotid;
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
