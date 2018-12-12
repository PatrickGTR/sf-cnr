/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\weapon_locker.pwn
 * Purpose: basically ammunations in police stations called weapon lockers
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_WEAPON_LOCKERS			( 7 )

/* ** Variables ** */
static stock
	g_weaponLockerCheckpoint 		[ MAX_WEAPON_LOCKERS ],
	Iterator: WeaponLockers 		< MAX_WEAPON_LOCKERS >,
	p_WeaponLockerMenu				[ MAX_PLAYERS char ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	CreateAmmunationLocker( -1614.41992, 672.565246, -4.90625, 180.0000 );
	CreateAmmunationLocker( 2245.062988, 2434.94458, 10.82031, -90.0000 );
	CreateAmmunationLocker( 1525.003051, -1669.4093, 6.228725, 90.00000 );
	CreateAmmunationLocker( 1527.936645, -1462.0344, 9.500000, -90.0000 );
	CreateAmmunationLocker( 937.0916130, 1733.15197, 8.851562, 90.00000 );
	CreateAmmunationLocker( -2458.59399, 501.431365, 30.02399, 0.000000 );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( GetPlayerClass( playerid ) == CLASS_POLICE )
	{
		foreach ( new lockerid : WeaponLockers ) if ( checkpointid == g_weaponLockerCheckpoint[ lockerid ] )
		{
			return ShowAmmunationMenu( playerid, "{FFFFFF}Weapon Locker - Purchase Weapons", DIALOG_WEAPON_LOCKER );
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_WEAPON_LOCKER ) && response )
	{
    	p_WeaponLockerMenu{ playerid } = listitem;
      	return RedirectAmmunation( playerid, listitem, "{FFFFFF}Weapon Locker - Purchase Weapons", DIALOG_WEAPON_LOCKER_BUY, 1.25 );
	}
	else if ( dialogid == DIALOG_WEAPON_LOCKER_BUY )
	{
	   	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "You must be a law enforcement officer to use this feature." );
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot buy weapons in jail." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED || !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You are unable to purchase any weapons at this time." );

		// Check if user is in the locker checkpoint
		foreach (new lockerid : WeaponLockers)
		{
			if ( IsPlayerInDynamicCP( playerid, g_weaponLockerCheckpoint[ lockerid ] ) )
			{
				if ( response )
				{
				    for( new i, x = 0; i < sizeof( g_AmmunationWeapons ); i++ )
				    {
				        if ( g_AmmunationWeapons[ i ] [ E_MENU ] == p_WeaponLockerMenu{ playerid } )
				        {
				            if ( x == listitem )
				            {
								new
									iCostPrice = floatround( float( g_AmmunationWeapons[ i ] [ E_PRICE ] ) * 1.25 );

							 	if ( iCostPrice > GetPlayerCash( playerid ) )
								{
								    SendError( playerid, "You don't have enough money for this." );
								    RedirectAmmunation( playerid, p_WeaponLockerMenu{ playerid }, "{FFFFFF}Weapon Locker - Purchase Weapons", DIALOG_WEAPON_LOCKER_BUY, 1.25 );
									return 1;
								}

								GivePlayerCash( playerid, -iCostPrice );

								if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 101 ) SetPlayerArmour( playerid, float( g_AmmunationWeapons[ i ] [ E_AMMO ] ) );
								else GivePlayerWeapon( playerid, g_AmmunationWeapons[ i ] [ E_WEPID ], g_AmmunationWeapons[ i ] [ E_AMMO ] );

								RedirectAmmunation( playerid, p_WeaponLockerMenu{ playerid }, "{FFFFFF}Weapon Locker - Purchase Weapons", DIALOG_WEAPON_LOCKER_BUY, 1.25 );
								SendServerMessage( playerid, "You have purchased %s(%d) for "COL_GOLD"%s"COL_WHITE"%s (inc. fees).", g_AmmunationWeapons[ i ] [ E_NAME ], g_AmmunationWeapons[ i ] [ E_AMMO ], cash_format( iCostPrice ) );
								break;
				            }
				            x ++;
				        }
				    }
				}
				else
				{
					ShowAmmunationMenu( playerid, "{FFFFFF}Weapon Locker - Purchase Weapons", DIALOG_WEAPON_LOCKER );
				}
				return 1;
			}
		}
		return SendError( playerid, "You are not inside any gun locker checkpoint." );
	}
	return 1;
}

/* ** Functions ** */
stock CreateAmmunationLocker( Float: X, Float: Y, Float: Z, Float: rX )
{
	new
		lockerid = Iter_Free(WeaponLockers);

	if ( lockerid !=ITER_NONE )
	{
		Iter_Add( WeaponLockers, lockerid );

		new
			Float: nX = X + 1.5 * -floatsin( -rX, degrees ),
			Float: nY = Y + 1.5 * -floatcos( -rX, degrees )
		;

		g_weaponLockerCheckpoint[ lockerid ] = CreateDynamicCP( nX, nY, Z, 2.0 , -1, -1, -1, 100.0 );
		CreateDynamicObject( 14782, X, Y, Z, 0.0, 0.0, rX, -1, -1, -1, 100.0 );
		CreateDynamic3DTextLabel( "[WEAPON LOCKER]", COLOR_GOLD, nX, nY, Z, 20.0 );
	}
	return lockerid;
}
