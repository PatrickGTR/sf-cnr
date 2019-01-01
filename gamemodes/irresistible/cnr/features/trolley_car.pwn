/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\trolley_car.pwn
 * Purpose: cool feature where there are drivable trolleys at supa-save ... o.g feature since 2012
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined __cnr__trolley_car
    #define __cnr__trolley_car
#endif

/* ** Variables ** */
static stock
	g_TrolleyVehicles               [ 5 ] = { INVALID_VEHICLE_ID, ... };

/* ** Hooks ** */
hook OnScriptInit( )
{
    // create gold cart
	g_TrolleyVehicles[ 0 ] = AddStaticVehicle( 457, -2511.7935, 760.5610, 34.8990, 90.6223, 123, 1 ); // trolley
	g_TrolleyVehicles[ 1 ] = AddStaticVehicle( 457, -2511.5742, 766.5329, 34.8990, 91.5108, 112, 1 ); // trolley
	g_TrolleyVehicles[ 2 ] = AddStaticVehicle( 457, -2511.8782, 763.1669, 34.8990, 89.6839, 116, 1 ); // trolley
	g_TrolleyVehicles[ 3 ] = AddStaticVehicle( 457, -2511.4871, 769.7538, 34.8990, 91.3486, 116, 1 ); // trolley
	g_TrolleyVehicles[ 4 ] = AddStaticVehicle( 457, -2512.2607, 772.9983, 34.9006, 91.2577, 116, 1 ); // trolley

    // set the golf cart to a trolley!
	for ( new i = 0; i < sizeof( g_TrolleyVehicles ); i ++ ) {
		ChangeVehicleModel( g_TrolleyVehicles[ i ], 1349, 270.0 + 180.0 );
    }
    return 1;
}

/* ** Functions ** */
stock IsTrolleyVehicle( vehicleid ) {
	for ( new i = 0; i < sizeof( g_TrolleyVehicles ); i ++ ) if ( g_TrolleyVehicles[ i ] == vehicleid ) {
        return true;
    }
    return false;
}