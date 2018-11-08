/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_GANG_VEHICLES			( 30 )

/* ** Macros ** */
#define IsValidGangVehicle(%0,%1) \
	( 0 <= %0 < MAX_GANG_VEHICLES && Iter_Contains( gangvehicles<%0>, %1 ) )

/* ** Variables ** */
enum E_GANG_VEHICLE_DATA
{
	E_SQL_ID,			E_VEHICLE_ID,

	E_COLOR[ 2 ],		E_MODEL,				E_PAINTJOB
};

new g_gangVehicleData				[ MAX_GANGS ] [ MAX_GANG_VEHICLES ] [ E_GANG_VEHICLE_DATA ];
new g_gangVehicleModifications		[ MAX_GANGS ] [ MAX_GANG_VEHICLES ] [ MAX_CAR_MODS ];
new Iterator: gangvehicles 			< MAX_GANGS, MAX_GANG_VEHICLES >;


/* ** Hooks ** */
hook OnGangLoad( gangid )
{
	return 1;
}

CMD:car( playerid )
{
	new Float: X, Float: Y, Float: Z;
	GetPlayerPos( playerid, X, Y, Z );
	CreateGangVehicle( GetPlayerGang( playerid ), 560, X, Y, Z );
	return 1;
}

/* ** Functions ** */
stock CreateGangVehicle( gangid, modelid, Float: X, Float: Y, Float: Z, color1 = -1, color2 = -1, paintjob = 3 )
{
	new
		slotid = Iter_Free( gangvehicles< gangid > );

	if ( slotid != ITER_NONE )
	{
		g_gangVehicleData[ gangid ] [ slotid ] [ E_COLOR ] [ 0 ] = color1;
		g_gangVehicleData[ gangid ] [ slotid ] [ E_COLOR ] [ 1 ] = color2;
		g_gangVehicleData[ gangid ] [ slotid ] [ E_PAINTJOB ] = paintjob;
		g_gangVehicleData[ gangid ] [ slotid ] [ E_MODEL ] = modelid;

		ResetGangVehicleMods( gangid, slotid );

		new vehicleid = CreateVehicle( modelid, X, Y, Z, 0.0, Color1, Color2, 999999999 );

		g_adminSpawnedCar{ vehicleid } = false;
		SetVehicleNumberPlate( vehicleid, g_gangData[ gangid ] [ E_NAME ] );
		g_gangVehicleData[ gangid ] [ slotid ] [ E_VEHICLE_ID ] = vehicleid;

		//format( szString, sizeof( szString ), "INSERT INTO `VEHICLES` (`MODEL`,`LOCKED`,`X`,`Y`,`Z`,`ANGLE`,`COLOR1`,`COLOR2`,`PRICE`,`OWNER`,`PLATE`,`PAINTJOB`,`MODS`) VALUES (%d,0,%f,%f,%f,%f,%d,%d,%d,%d,'SF-CNR',3,'0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.')", Model, X, Y, Z, Angle, Color1, Color2, Cost, g_vehicleData[ playerid ] [ vID ] [ E_OWNER_ID ] );
		//mysql_function_query( dbHandle, szString, true, "OnPlayerCreateBuyableVehicle", "dd", playerid, vID );
	}
	return slotid;
}

stock ResetGangVehicleMods( gangid, slotid, fordestroy=1 )
{
	if ( IsValidGangVehicle( gangid, slotid ) )
		return;

	for ( new i = 0; i < MAX_CAR_MODS; i++ )
	{
		if ( ! fordestroy && IsValidVehicle( g_gangVehicleData[ gangid ] [ slotid ] [ E_VEHICLE_ID ] ) ) {
	        if ( CarMod_IsLegalCarMod( GetVehicleModel( g_gangVehicleData[ gangid ] [ slotid ] [ E_VEHICLE_ID ] ), g_gangVehicleModifications[ gangid ] [ slotid ] [ i ] ) ) {
	            RemoveVehicleComponent( g_gangVehicleData[ gangid ] [ slotid ] [ E_VEHICLE_ID ], g_gangVehicleModifications[ gangid ] [ slotid ] [ i ] );
	        }
		}
		g_gangVehicleModifications[ gangid ] [ slotid ] [ i ] = 0;
	}

	format( szNormalString, sizeof( szNormalString ), "UPDATE `GANG_VEHICLES` SET `MODS`='0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.' WHERE `ID`=%d", g_gangVehicleData[ gangid ] [ slotid ] [ E_SQL_ID ] );
	mysql_single_query( szNormalString );
}
