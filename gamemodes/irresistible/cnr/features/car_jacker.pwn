/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\car_jacker.pwn
 * Purpose: sell vehicles in select containers as a car jacker
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define CONTAINER_LIMIT 			( 6 )

/* ** Variables ** */
enum E_CONTAINER_DATA
{
	E_OBJECT, 			E_DOOR[ 2 ],				E_CHECKPOINT,
	Text3D: E_LABEL,	Float: E_OPEN_ANGLE[ 2 ], 	Float: E_CLOSE_ANGLE[ 2 ],
	bool: E_CLOSED, 	Float: E_DOOR1_CORDS[ 3 ], 	Float: E_DOOR2_CORDS[ 3 ]
}

static stock
	g_containerData 				[ CONTAINER_LIMIT ] [ E_CONTAINER_DATA ],
	Iterator: containers 			< CONTAINER_LIMIT >,
	g_LastExportModel 				[ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// SF
	CreateCarjackerContainer( -1580.637817, 125.17828, 4.009482, 45.0, 	{ -1579.241090, 121.606070, 3.939500 }, { -1577.006840, 123.784420, 3.939500 }, { -55.0, 	0.0 }, { 45.00, -135.0 } );
	CreateCarjackerContainer( -1559.313354, 134.51689, 4.004680, -45.0, { -1562.892940, 133.132600, 3.939500 }, { -1560.726070, 130.873600, 3.939500 }, { -160.0, -90.0 }, { -45.0, -225.0 } );

	// LV
	CreateCarjackerContainer( 1637.343627, 2317.039062, 11.280317, 270.0, { 1633.789916, 2318.572753, 11.210318 }, { 1633.749877, 2315.451904, 11.210318 }, { 163.0, -152.0 }, { 270.0, 90.0 } );
	CreateCarjackerContainer( 1637.307006, 2326.375000, 11.280316, 270.0, { 1633.789916, 2327.905517, 11.210318 }, { 1633.749877, 2324.812988, 11.210318 }, { 156.0, -150.0 }, { 270.0, 90.0 } );

	// LS
	CreateCarjackerContainer( 2613.762939, -2213.233398, 14.002803, 0.000, { 2612.225830, -2216.737060, 13.936882 }, { 2615.337646, -2216.776367, 13.936882 }, { -105.0, -31.5 }, { 0.0, 180.0 } );
	CreateCarjackerContainer( 2616.617187, -2240.118652, 14.016877, 180.0, { 2618.161132, -2236.586425, 13.956872 }, { 2615.048828, -2236.566406, 13.956872 }, { 50.0, 138.8 }, { 180.0, 360.0 } );
	return 1;
}

hook OnPlayerConnect( playerid )
{
	p_AntiExportCarSpam [ playerid ] = g_iTime + 60;
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	g_LastExportModel[ playerid ] = 0;
	return 1;
}

hook OnPlayerDriveVehicle( playerid, vehicleid )
{
	new
		iVehiclePrice = calculateVehicleSellPrice( vehicleid );

	if ( IsPlayerJob( playerid, JOB_DIRTY_MECHANIC ) && p_Class[ playerid ] == CLASS_CIVILIAN && iVehiclePrice )
	{
		if ( g_LastExportModel[ playerid ] == GetVehicleModel( vehicleid ) )
		{
			ShowPlayerHelpDialog( playerid, 4000, "You have already exported this vehicle recently and cannot export it again at the docks." );
		}
		else
		{
			ShowPlayerHelpDialog( playerid, 6000, "You can export this vehicle at the docks for around ~g~%s~w~~h~.~n~~n~~r~Damaging the vehicle will further decrease the value.", cash_format( iVehiclePrice ) );
		}
	}
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( IsPlayerInAnyVehicle( playerid ) )
	{
		new
			iVehicle = GetPlayerVehicleID( playerid ),
			vModel = GetVehicleModel( iVehicle ),
			iCash = calculateVehicleSellPrice( iVehicle ),
			Float: X, Float: Y, Float: Z, Float: Angle
		;

		if ( GetPlayerClass( playerid ) == CLASS_CIVILIAN && vModel )
		{
			foreach ( new i : containers )
			{
				if ( checkpointid == g_containerData[ i ] [ E_CHECKPOINT ] && ! g_containerData[ i ] [ E_CLOSED ] )
				{
					if ( ! IsPlayerJob( playerid, JOB_DIRTY_MECHANIC ) ) {
						ShowPlayerHelpDialog( playerid, 4000, "You need to be a ~r~dirty mechanic~w~~h~ to export stolen vehicles!" );
						break;
					}

					if ( g_LastExportModel[ playerid ] == vModel ) {
						ShowPlayerHelpDialog( playerid, 4000, "You cannot export the same type of vehicle, ~y~find a different vehicle." );
						break;
					}

					if ( !iCash ) {
						ShowPlayerHelpDialog( playerid, 4000, "~r~You cannot export this vehicle." );
						break;
					}

					if ( p_AntiExportCarSpam[ playerid ] > g_iTime ) {
						ShowPlayerHelpDialog( playerid, 4000, "You can export your next vehicle in %s.", secondstotime( p_AntiExportCarSpam[ playerid ] - g_iTime ) );
						break;
					}

					GetDynamicObjectPos( g_containerData[ i ] [ E_OBJECT ], X, Y, Z );
					GetDynamicObjectRot( g_containerData[ i ] [ E_OBJECT ], Angle, Angle, Angle );

					X += 6 * -floatsin( -Angle, degrees );
					Y += 6 * -floatcos( -Angle, degrees );

					SetPlayerPos( playerid, X, Y, Z + 0.6 );

					g_containerData		[ i ] [ E_CLOSED ] = true;
					g_LastExportModel	[ playerid ] = vModel;
					p_AntiExportCarSpam [ playerid ] = g_iTime + 60;

					MoveDynamicObject( g_containerData[ i ] [ E_DOOR ] [ 0 ], g_containerData[ i ] [ E_DOOR1_CORDS ] [ 0 ] + 0.05, g_containerData[ i ] [ E_DOOR1_CORDS ] [ 1 ] + 0.05, g_containerData[ i ] [ E_DOOR1_CORDS ] [ 2 ], ( 0.1 ), 0.0, 0.0, g_containerData[ i ] [ E_CLOSE_ANGLE ] [ 0 ] );
					MoveDynamicObject( g_containerData[ i ] [ E_DOOR ] [ 1 ], g_containerData[ i ] [ E_DOOR2_CORDS ] [ 0 ] + 0.05, g_containerData[ i ] [ E_DOOR2_CORDS ] [ 1 ] + 0.05, g_containerData[ i ] [ E_DOOR2_CORDS ] [ 2 ], ( 0.1 ), 0.0, 0.0, g_containerData[ i ] [ E_CLOSE_ANGLE ] [ 1 ] );

					GivePlayerWantedLevel( playerid, 6 );
					GivePlayerCash( playerid, iCash );
					StockMarket_UpdateEarnings( E_STOCK_VEHICLE_DEALERSHIP, iCash, 0.25 );
					GivePlayerScore( playerid, 2 );
					//GivePlayerExperience( playerid, E_CAR_JACKER );
					ach_HandleCarJacked( playerid );
					SetTimerEx( "ExportVehicle", 3000, false, "dd", iVehicle, i );
					SendServerMessage( playerid, "You have exported your "COL_GREY"%s"COL_WHITE" for "COL_GOLD"%s"COL_WHITE".", GetVehicleName( GetVehicleModel( iVehicle ) ), cash_format( iCash ) );
					break;
				}
			}
		}
	}
	return 1;
}

/* ** Functions ** */
stock CreateCarjackerContainer( Float: X, Float: Y, Float: Z, Float: Angle, {Float,_}: fDoor1Cords[ 3 ], {Float,_}: fDoor2Cords[ 3 ], {Float,_}: fDoorOpenAngle[ 2 ], {Float,_}: fDoorCloseAngle[ 2 ] )
{
	new
		id = Iter_Free( containers );

	if ( id != ITER_NONE )
	{
		g_containerData[ id ] [ E_OBJECT ] 		= CreateDynamicObject( 19321, X, Y, Z, 0.000000, 0.000000, Angle );
		g_containerData[ id ] [ E_DOOR ] [ 0 ] 	= CreateDynamicObject( 3062, fDoor1Cords[ 0 ], fDoor1Cords[ 1 ], fDoor1Cords[ 2 ], 0.000000, 0.000000, fDoorOpenAngle[ 0 ] );
		g_containerData[ id ] [ E_DOOR ] [ 1 ] 	= CreateDynamicObject( 3062, fDoor2Cords[ 0 ], fDoor2Cords[ 1 ], fDoor2Cords[ 2 ], 0.000000, 0.000000, fDoorOpenAngle[ 1 ] );

		g_containerData[ id ] [ E_OPEN_ANGLE ] [ 0 ] 	= fDoorOpenAngle[ 0 ];
		g_containerData[ id ] [ E_OPEN_ANGLE ] [ 1 ] 	= fDoorOpenAngle[ 1 ];
		g_containerData[ id ] [ E_CLOSE_ANGLE ] [ 0 ] 	= fDoorCloseAngle[ 0 ];
		g_containerData[ id ] [ E_CLOSE_ANGLE ] [ 1 ] 	= fDoorCloseAngle[ 1 ];

		g_containerData[ id ] [ E_DOOR1_CORDS ]	= fDoor1Cords;
		g_containerData[ id ] [ E_DOOR2_CORDS ]	= fDoor2Cords;

		g_containerData[ id ] [ E_CLOSED ] 		= false;
	    g_containerData[ id ] [ E_CHECKPOINT ] 	= CreateDynamicCP( X, Y, Z, 2.0, -1, -1 );
	    g_containerData[ id ] [ E_LABEL ] 		= CreateDynamic3DTextLabel( "[VEHICLE EXPORT]", COLOR_GOLD, X, Y, Z, 15.0 );

	    Iter_Add(containers, id);
	}
}

stock IsCarjackableVehicleModel(value)
{
	/*
		Bikes: 462, 581,522,561,521,463,586,468,471
		Convertibles: 480,533,439,555
		Industrial: 422, 482, 582, 600, 413, 440, 543, 605, 459,531,552,478,554
		Lowriders: 536,575,534,567,535,566,576,412
		Offroad: 568,424,579,400,500,489,505,495
		Saloons: 445, 504, 401, 518, 527, 542, 507, 562, 585, 419, 526, 604, 466, 492, 474, 546, 517, 410, 551, 516, 467, 426, 436, 547, 405, 580, 560, 550, 549, 540, 491, 529, 421
		Sport Vehicles: 602, 429, 496, 402, 541, 415, 589, 587, 565, 494, 502, 503, 411, 559, 603, 475, 506, 451, 558, 477
		Station Wagons: 418, 404, 479, 458, 561

		Generate: http://spelsajten.net/bitarray/
	*/
	static const valid_values[7] = {
		627883063, -871882352, -637145956, -965734447, -840109590, 779715047, 15616
	};

	if (400 <= value <= 605) {
		value -= 400;
		return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
	}
	return false;
}

stock calculateVehicleSellPrice( vehicleid )
{
	static const
		g_aVehicleSellingPrice[ 212 ] =
		{
			3500, 3000, 7000, 4500, 2700, 3200, 7500, 6000, 3500, 5000, 2500, 12500, 4500, 2300, 2700, 6500, 5500, 10000, 3000, 4700, 3500, 4700, 2900, 3300, 5000, 17000, 3500, 4200, 6000, 6500, 9000, 4900, 8000, 5500, 5400, 3000,
			3200, 5000, 3300, 6500, 3900, 3000, 2900, 4650, 8500, 2600, 9800, 14000, 2300, 4000, 3500, 11000, 5600, 2900, 4400, 3300, 3400, 1500, 4700, 3900, 7500, 5100, 2700, 5500, 5000, 5000, 4000, 4500, 5700, 7600, 4500, 4600,
			3200, 2900, 4200, 4300, 13500, 5500, 1500, 2400, 6800, 3200, 3600, 3800, 5700, 2000, 4200, 14000, 12500, 3400, 3900, 3500, 3900, 7600, 7400, 8200, 4600, 13500, 2300, 2000, 3900, 5000, 7800, 7600, 5600, 2700, 6000, 3200,
			3700, 2300, 4200, 7800, 6900, 9000, 4000, 5700, 4300, 2700, 3000, 14000, 14500, 6500, 8000, 7500, 4200, 4000, 5400, 4700, 6000, 5000, 2200, 1900, 4900, 6400, 3900, 4800, 6900, 7500, 6400, 6500, 5200, 9000, 2000, 1200,
			4300, 3200, 4900, 4200, 9000, 2700, 5600, 4200, 2700, 7500, 5500, 5200, 8000, 7000, 6500, 6300, 7500, 3400, 7900, 8000, 5000, 3800, 3000, 5800, 5700, 3200, 3200, 2500, 2500, 4800, 1200, 4800, 2000, 20000, 3200, 6800,
			4000, 6100, 3800, 2300, 3000, 3900, 4500, 5100, 3500, 3900, 3000, 3200, 9000, 6000, 5000, 4500, 4700, 4700, 4700, 5000, 2300, 5300, 6400, 4200, 800, 700, 1000, 1200, 600, 2300, 1000, 2300
		}
	;

	if ( !IsValidVehicle( vehicleid ) )
		return 0;

	new
		Float: fHealth,
		iModel = GetVehicleModel( vehicleid )
	;

	if ( !GetVehicleHealth( vehicleid, fHealth ) || !IsCarjackableVehicleModel( iModel ) || g_adminSpawnedCar{ vehicleid } || g_buyableVehicle{ vehicleid } || g_gangVehicle{ vehicleid } || Iter_Contains( business, g_isBusinessVehicle[ vehicleid ] ) )
		return 0;

	if ( fHealth > 1000.0 )
		fHealth = 1000.0;

	if ( fHealth < 0.0 )
		fHealth = 0.0;

	return floatround( float( g_aVehicleSellingPrice[ iModel - 400 ] ) * ( fHealth / 1000.0 ) * 0.75 );
}

function ExportVehicle( vehicleid, container )
{
	MoveDynamicObject( g_containerData[ container ] [ E_DOOR ] [ 0 ], g_containerData[ container ] [ E_DOOR1_CORDS ] [ 0 ], g_containerData[ container ] [ E_DOOR1_CORDS ] [ 1 ], g_containerData[ container ] [ E_DOOR1_CORDS ] [ 2 ], ( 0.1 ), 0.0, 0.0, g_containerData[ container ] [ E_OPEN_ANGLE ] [ 0 ] );
	MoveDynamicObject( g_containerData[ container ] [ E_DOOR ] [ 1 ], g_containerData[ container ] [ E_DOOR2_CORDS ] [ 0 ], g_containerData[ container ] [ E_DOOR2_CORDS ] [ 1 ], g_containerData[ container ] [ E_DOOR2_CORDS ] [ 2 ], ( 0.1 ), 0.0, 0.0, g_containerData[ container ] [ E_OPEN_ANGLE ] [ 1 ] );

	g_containerData[ container ] [ E_CLOSED ] = false;

	SetVehicleToRespawn( vehicleid );
}
