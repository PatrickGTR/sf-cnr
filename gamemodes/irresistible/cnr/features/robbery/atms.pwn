/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\robbery\atms.pwn
 * Purpose: robbable ATM system which can also be used for banking
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#if defined MAX_FACILITIES
	#define MAX_ATMS 				( 49 + MAX_FACILITIES )
#else
	#define MAX_ATMS				( 49 )
#endif

/* ** Variables ** */
enum E_ATM_DATA
{
	E_CHECKPOINT, 		Float: E_HEALTH, 	E_TIMESTAMP,
	E_OBJECT,			Text3D: E_LABEL, 	bool: E_DISABLED,
	E_PICKUP,			E_LOOT,				E_WORLD
};

static stock
	g_atmData						[ MAX_ATMS ] [ E_ATM_DATA ],
	Iterator: atms 					< MAX_ATMS >
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// San Fierro
	CreateATM( -1938.123291, 883.547668, 38.087814, 270.000000 );
	CreateATM( -2408.914794, 720.656738, 34.751876, 180.000000 );
	CreateATM( -1980.711669, 122.112731, 27.267499, 90.000000  );
	CreateATM( -2647.664306, -22.565168, 5.7128110, 180.000000 );
	CreateATM( -1917.654418, 558.118347, 34.743148, 270.000000 );
	CreateATM( -2635.699951, 631.200012, 14.079999, 180.000000 );
	CreateATM( -2636.040000, 208.560000, 3.8800000, 360.000000 );
	CreateATM( -2512.100000, 2340.74000, 4.5799990, 180.000000 );
	CreateATM( -2525.250000, -624.97000, 132.41000, 360.000000 );
	CreateATM( -2151.442138, -405.575164, 34.94596, 224.300000 );

	// Las Venturas
	CreateATM( 2544.055175, 2242.881835, 10.471873, 180.000000 );
	CreateATM( 2110.729736, 2061.529052, 10.500308, 180.000000 );
	CreateATM( 2233.845703, 957.4488520, 10.470303, 90.0000000 );
	CreateATM( 2413.644287, 1114.202758, 10.452508, -90.000000 );
	CreateATM( 1900.780151, 1102.897583, 10.459669, 180.000000 );
	CreateATM( 2349.165283, 1543.896972, 10.469670, 180.000000 );
	CreateATM( 2845.597412, 1286.504272, 11.030617, 0.00000000 );
	CreateATM( 1879.681396, 722.8941040, 10.440302, 180.000000 );
	CreateATM( 997.7407220, 2086.763427, 10.459657, -90.000000 );
	CreateATM( 1480.238769, 2206.801025, 10.663430, -90.000000 );
	CreateATM( 1677.719604, 2756.413330, 10.459667, -90.000000 );
	CreateATM( -16.0785670, 1221.418579, 19.012741, -90.000000 );
	CreateATM( -792.090637, 2744.119140, 45.490905, 180.000000 );
	CreateATM( -1505.61242, 2622.352050, 55.470737, -90.000000 );
	CreateATM( -1952.57629, 2388.553466, 49.139991, 20.0000000 );
	CreateATM( -856.524902, 1528.208496, 22.238605, -90.000000 );

	// Los Santos
	CreateATM( 2234.733398, 51.345561000, 26.134365, 0.000000, 0.0 );
	CreateATM( 1381.069213, 259.56204200, 19.156929, 157.0000, 0.0 );
	CreateATM( 255.4551690, -197.5846250, 1.2381240, -90.0000, 0.0 );
	CreateATM( 661.3598020, -555.1714470, 15.965932, -90.0000, 0.0 );
	CreateATM( -2177.50292, -2435.006591, 30.214990, 52.00000, 0.0 );
	CreateATM( 1367.251464, -1284.611938, 13.156874, -90.6000, 0.0 );
	CreateATM( 1928.592651, -1771.088012, 13.172806, 90.00000, 0.0 );
	CreateATM( 2323.767333, -1644.993896, 14.442724, 0.000000, 0.0 );
	CreateATM( 2043.748779, -1416.704711, 16.810766, -90.0000, 0.0 );
	CreateATM( 2387.751464, -1981.961669, 13.156866, -180.000, 0.0 );
	CreateATM( 1494.450195, -1768.979492, 18.365745, -90.0000, 0.0 );
	CreateATM( 1051.627075, -1026.406616, 31.661567, 0.000000, 0.0 );
	CreateATM( 816.8725580, -1356.521240, 13.156099, -180.000, 0.0 );
	CreateATM( 1808.732177, -1567.267822, 13.063967, 37.00000, 0.0 );
	CreateATM( 2412.541259, -1492.666992, 23.628126, -180.000, 0.0 );
	CreateATM( 2431.131347, -1219.477539, 25.022165, 0.000000, 0.0 );

	// Casinos
	CreateATM( 1985.135253, 1003.277404, 994.097290, 0.000 ); // 4 Drags
	CreateATM( 1986.635253, 1032.391113, 994.097290, 180.0 ); // 4 Drags
	CreateATM( 2230.132324, 1647.986816, 1007.97900, -90.0 ); // Caligs
	CreateATM( 2241.676269, 1649.486816, 1007.97900, 90.00 ); // Caligs
	return 1;
}

hook OnServerUpdate( )
{
	foreach ( new i : atms ) if ( g_atmData[ i ] [ E_DISABLED ] && g_iTime > g_atmData[ i ] [ E_TIMESTAMP ] ) {
		UpdateDynamic3DTextLabelText( g_atmData[ i ] [ E_LABEL ], COLOR_GOLD, "[ATM]\n"COL_GREY"100%" );
		DestroyDynamicPickup( g_atmData[ i ] [ E_PICKUP ] ), g_atmData[ i ] [ E_PICKUP ] = -1;
		g_atmData[ i ] [ E_LOOT ] = 0, g_atmData[ i ] [ E_DISABLED ] = false, g_atmData[ i ] [ E_HEALTH ] = 100.0;
		Streamer_SetIntData( STREAMER_TYPE_OBJECT, g_atmData[ i ] [ E_OBJECT ], E_STREAMER_MODEL_ID, 19324 );
	}
	return 1;
}

hook OnPlayerShootDynObject( playerid, weaponid, objectid, Float: x, Float: y, Float: z )
{
	new
		Float: X, Float: Y, Float: Z, Float: rZ,
		modelid = Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID )
	;

	if ( modelid == 19324 )
	{
		if ( GetPlayerClass( playerid ) == CLASS_POLICE )
			return 1; // Prevent police from damaging atms

		new Float: Damage = GetWeaponDamageFromDistance( weaponid, GetPlayerDistanceFromPoint( playerid, x, y, z ) );
		new player_world = GetPlayerVirtualWorld( playerid );

		foreach ( new i : atms ) {

			if ( g_atmData[ i ] [ E_WORLD ] != -1 && g_atmData[ i ] [ E_WORLD ] != player_world ) continue;

			if ( g_atmData[ i ] [ E_OBJECT ] == objectid && !g_atmData[ i ] [ E_DISABLED ] )
			{
				if ( GetDynamicObjectPos( objectid, X, Y, Z ) && IsPointToPoint( 1.0, X + x, Y + y, Z + z, X, Y, Z ) ) {
					new
						Float: atmDamage = floatdiv( Damage, 4 );

					if ( ( g_atmData[ i ] [ E_HEALTH ] -= atmDamage ) > 0.0 ) {
						format( szNormalString, 24, "[ATM]\n"COL_GREY"%0.0f%%", g_atmData[ i ] [ E_HEALTH ] );
						UpdateDynamic3DTextLabelText( g_atmData[ i ] [ E_LABEL ], COLOR_GOLD, szNormalString );
					} else {
						UpdateDynamic3DTextLabelText( g_atmData[ i ] [ E_LABEL ], COLOR_GOLD, "[ATM]\n"COL_RED"Disabled" );
						Streamer_SetIntData( STREAMER_TYPE_OBJECT, g_atmData[ i ] [ E_OBJECT ], E_STREAMER_MODEL_ID, 2943 );

						g_atmData[ i ] [ E_TIMESTAMP ] = g_iTime + 240;
						g_atmData[ i ] [ E_DISABLED ] = true;

						if ( random( 101 ) <= 20 ) {
							new
								szLocation[ MAX_ZONE_NAME ];

							GetPlayerPos 			( playerid, X, Y, Z );
							GetZoneFromCoordinates	( szLocation, X, Y, Z );

							CreateCrimeReport( playerid );
							SendClientMessageToCops( -1, ""COL_BLUE"[ROBBERY]"COL_WHITE" %s has failed robbing an ATM near %s, suspect is armed and dangerous.", ReturnPlayerName( playerid ), szLocation );
							SendServerMessage( playerid, "There seems to be no money in the ATM that you have breached." );
						} else {
							GetDynamicObjectRot( objectid, rZ, rZ, rZ );
							g_atmData[ i ] [ E_PICKUP ] = CreateDynamicPickup( 1550, 1, X + 1.0 * -floatsin( -rZ, degrees ), Y + 1.0 * -floatcos( -rZ, degrees ), Z + 0.33, .worldid = g_atmData[ i ] [ E_WORLD ] );
							g_atmData[ i ] [ E_LOOT ] = RandomEx( 320, 750 );

							if ( IsPlayerConnected( playerid ) && p_MoneyBag{ playerid } == true ) {
								new extra_loot = floatround( float( g_atmData[ i ] [ E_LOOT ] ) * ROBBERY_MONEYCASE_BONUS );
								g_atmData[ i ] [ E_LOOT ] = extra_loot;
							}

							SendServerMessage( playerid, "You've breached an ATM! Rob the money that has been dispensed for quick pocket change!" );
						}
					}
					break;
				}
			}
		}
	}
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( ! IsPlayerInAnyVehicle( playerid ) )
	{
		foreach ( new i : atms ) if ( checkpointid == g_atmData[ i ] [ E_CHECKPOINT ] ) {
	    	if ( g_atmData[ i ] [ E_DISABLED ] ) {
	    		return SendError( playerid, "This ATM has recently been robbed and cannot be accessed for now." );
	    	} else {
	    		return ShowPlayerBankMenuDialog( playerid );
	    	}
		}
	}
	return 1;
}

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
	static
		Float: X, Float: Y, Float: Z;

	// Money bag from atms
	if ( GetPlayerClass( playerid ) != CLASS_POLICE )
	{
		foreach ( new i : atms ) if ( g_atmData[ i ] [ E_DISABLED ] )
		{
			if ( g_atmData[ i ] [ E_PICKUP ] == pickupid && pickupid != -1 )
			{
				new
					szCity[ MAX_ZONE_NAME ], szLocation[ MAX_ZONE_NAME ], iLoot = g_atmData[ i ] [ E_LOOT ];

				SplitPlayerCashForGang( playerid, iLoot );
				ach_HandlePlayerRobbery( playerid );
				DestroyDynamicPickup( g_atmData[ i ] [ E_PICKUP ] );

				g_atmData[ i ] [ E_PICKUP ] = -1;
				g_atmData[ i ] [ E_LOOT ] = 0;

				GivePlayerWantedLevel( playerid, 4 );
				GivePlayerScore( playerid, 1 );
				GivePlayerExperience( playerid, E_ROBBERY, 0.67 );

				GetPlayerPos 			( playerid, X, Y, Z );
			    Get2DCity				( szCity, X, Y, Z );
			    GetZoneFromCoordinates	( szLocation, X, Y, Z );

				SendClientMessageToCops( -1, ""COL_BLUE"[ROBBERY]"COL_WHITE" %s(%d) has robbed "COL_GOLD"%s"COL_WHITE" from an ATM near %s in %s!", ReturnPlayerName( playerid ), playerid, cash_format( iLoot ), szLocation, szCity );
				return SendServerMessage( playerid, "You have successfully taken "COL_GOLD"%s"COL_WHITE" dispensed from the ATM.", cash_format( iLoot ) );
			}
		}
	}
	return 1;
}

/* ** Functions ** */
stock CreateATM( Float: X, Float: Y, Float: Z, Float: rX, Float: offset = 180.0, world = -1 )
{
	new ID = Iter_Free( atms );

	if ( ID != ITER_NONE )
	{
		rX = rX - offset;

		new
			Float: nX = X + 1.0 * -floatsin( -rX, degrees ),
			Float: nY = Y + 1.0 * -floatcos( -rX, degrees )
		;

		Iter_Add( atms, ID );
		g_atmData[ ID ] [ E_HEALTH ] = 100.0;
		g_atmData[ ID ] [ E_CHECKPOINT ] = CreateDynamicCP( nX, nY, Z, 1.0, .worldid = world );
		g_atmData[ ID ] [ E_OBJECT ] = CreateDynamicObject( 19324, X, Y, Z, 0.0, 0.0, rX, .priority = 2, .worldid = world );
		g_atmData[ ID ] [ E_LABEL ] = CreateDynamic3DTextLabel( "[ATM]\n"COL_GREY"100%", COLOR_GOLD, nX, nY, Z, 20.0, .worldid = world );
		g_atmData[ ID ] [ E_WORLD ] = world;
	}
	return ID;
}

stock GetClosestATM( playerid ){
    new closest = -1, Float: closestDist = 8000.00, Float: distance, Float: pX, Float: pY, Float: pZ, Float: oX, Float: oY, Float: oZ;
	GetPlayerPos( playerid, pX, pY, pZ );
    for( new i = 0; i < MAX_ATMS; i++ ){
        GetATMPos( i, oX, oY, oZ );
        distance = VectorSize( pX-oX, pY-oY, pZ-oZ );
        if( closestDist > distance ){
            closestDist = distance;
            closest = i;
        }
    }
    return closest;
}

stock GetATMPos( atmID, &Float: X, &Float: Y, &Float: Z ) {
	return GetDynamicObjectPos( g_atmData[ atmID ] [ E_OBJECT ], X, Y, Z );
}