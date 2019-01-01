/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\shamal.pwn
 * Purpose: feature to allow passengers into shamals
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define VW_SHAMAL 					220

/* ** Macros ** */
#define IsPlayerInShamal(%0)        ( GetPlayerInterior( %0 ) == VW_SHAMAL )
#define GetPlayerShamalVehicle(%0)  ( GetPlayerVirtualWorld( %0 ) - VW_SHAMAL )

/* ** Hooks ** */
hook OnScriptInit( )
{
	// Shamal Interior
	CreateDynamicObject( 14404, 1320.00000, 2000.00000, 1201.00000, 0.00000, 0.00000, 0.00000 );
	CreateDynamicObject( 1562, 1321.13000, 2000.05005, 1199.90002, 0.00000, 0.00000, 0.00000 );
	CreateDynamicObject( 1562, 1321.13000, 1997.65002, 1199.90002, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 1562, 1321.13000, 1995.34998, 1199.90002, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 1562, 1318.87000, 1998.94995, 1199.90002, 0.00000, 0.00000, 0.00000 );
	CreateDynamicObject( 1562, 1318.87000, 1996.55005, 1199.90002, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 1562, 1318.87000, 1994.15002, 1199.90002, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 1563, 1321.13000, 2000.39001, 1200.43994, 0.00000, 0.00000, 0.00000 );
	CreateDynamicObject( 1563, 1321.13000, 1997.31006, 1200.43994, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 1563, 1321.13000, 1995.01001, 1200.43994, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 1563, 1318.87000, 1999.29004, 1200.43994, 0.00000, 0.00000, 0.00000 );
	CreateDynamicObject( 1563, 1318.87000, 1996.20996, 1200.43994, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 1563, 1318.87000, 1993.81006, 1200.43994, 0.00000, 0.00000, 180.00000 );
	CreateDynamicObject( 14405, 1320.00000, 1999.69995, 1199.90002, 0.00000, 0.00000, 0.00000 );

    // Parachute Shamal Interior
	CreateDynamicPickup( 371, 2, 1318.92200, 2002.7311, 1200.250 );
    return 1;
}

hook OnVehicleSpawn( vehicleid ) {
	KillEveryoneInShamal( vehicleid );
    return 1;
}

hook OnVehicleDeath( vehicleid, killerid ) {
    KillEveryoneInShamal( vehicleid );
	return 1;
}

hook OnPlayerEnterVehicle( playerid, vehicleid, ispassenger )
{
    if ( ispassenger )
    {
    	if ( GetVehicleModel( vehicleid ) == 519 )
    	{
            SetPlayerPos( playerid, 1322.6577, 1992.5508, 1200.2574 );
            SetPlayerVirtualWorld( playerid, vehicleid + VW_SHAMAL );
            SetPlayerInterior( playerid, VW_SHAMAL );
            pauseToLoad( playerid );
    	}
    }
    return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	static
		Float: X, Float: Y, Float: Z, Float: Angle;

    if ( PRESSED( KEY_SECONDARY_ATTACK ) )
    {
        // Enter Shamal Interior
        if ( ! IsPlayerTied( playerid ) && IsPlayerInShamal( playerid ) )
        {
            if ( IsPlayerInRangeOfPoint( playerid, 10.0, 1322.6577, 1992.5508, 1200.2574 ) )
            {
                new
                    vehicleid = GetPlayerVirtualWorld( playerid ) - VW_SHAMAL;

                if ( IsValidVehicle( vehicleid ) )
                {
                    GetVehiclePos( vehicleid, X, Y, Z );
                    GetVehicleZAngle( vehicleid, Angle );

                    X += ( 3.2 * floatsin( -( Angle - 45.0 ), degrees ) );
                    Y += ( 3.2 * floatcos( -( Angle - 45.0 ), degrees ) );

                    SetPlayerInterior( playerid, 0 );
                    SetPlayerVirtualWorld( playerid, 0 );
                    SetPlayerFacingAngle( playerid, Angle );
                    SetPlayerPos( playerid, X, Y, Z - 1 );

                    pauseToLoad( playerid );
                }
	    	}
		}
    }
    return 1;
}

/* ** Functions ** */
static stock KillEveryoneInShamal( vehicleid )
{
	static
		Float: X, Float: Y, Float: Z;

	foreach(new i : Player) {
		if ( IsPlayerInShamal( i ) && ( GetPlayerVirtualWorld( i ) - VW_SHAMAL ) == vehicleid ) {
			if ( IsValidVehicle( vehicleid ) ) {
				GetPlayerPos( i, X, Y, Z );
				CreateExplosionForPlayer( i, X, Y, Z - 0.75, 0, 10.0 );
				SetPlayerHealth( i, -1 );
			}
		}
	}
}