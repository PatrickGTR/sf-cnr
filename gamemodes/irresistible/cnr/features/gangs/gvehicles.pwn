/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_GANG_VEHICLES			( 3 )

#define DIALOG_GANG_VEHICLE_MENU 	2399
#define DIALOG_GANG_VEHICLE_SPAWN 	2400
#define DIALOG_GANG_VD_BUY 			2401
#define DIALOG_GANG_VD_OPTIONS		2402
#define DIALOG_GANG_VD_CATEGORY		2403

#define PREVIEW_MODEL_GVEHICLE 		( 6 )

/* ** Macros ** */
#define IsValidGangVehicle(%0,%1) \
	( 0 <= %0 < MAX_GANG_VEHICLES && Iter_Contains( gangvehicles<%0>, %1 ) )

/* ** Constants ** */
static const GANG_VEHICLE_PRICE_FACTOR = 4;

/* ** Variables ** */
enum E_GANG_VEHICLE_DATA
{
	E_SQL_ID,			E_VEHICLE_ID,			E_ACTIVATION_TIME,

	E_COLOR[ 2 ],		E_MODEL,				E_PAINTJOB
};

new g_gangVehicleData				[ MAX_GANGS ] [ MAX_GANG_VEHICLES ] [ E_GANG_VEHICLE_DATA ];
new g_gangVehicleModifications		[ MAX_GANGS ] [ MAX_GANG_VEHICLES ] [ MAX_CAR_MODS ];
new Iterator: gangvehicles 			< MAX_GANGS, MAX_GANG_VEHICLES >;

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	new
		current_time = GetServerTime( );

	if ( dialogid == DIALOG_GANG_VEHICLE_MENU && response )
	{
		new gangid = GetPVarInt( playerid, "gang_vehicle_gang" );

		if ( ! IsValidGangID ( gangid ) ) {
			return SendError( playerid, "There was an error processing gang vehicles, please try again." );
		}

		switch ( listitem )
		{
			// spawn vehicle
			case 0:
			{
				if ( ! Iter_Count( gangvehicles< gangid > ) ) {
					SendError( playerid, "This gang does not have any vehicles purchased." );
					return ShowPlayerGangVehicleMenu( playerid, gangid );
				}

				szBigString = ""COL_WHITE"Vehicle\t"COL_WHITE"Availablity\n";

				foreach ( new slotid : gangvehicles< gangid > )
				{
					format( szBigString, sizeof( szBigString ), "%s%s\t%s\n", szBigString,
						GetVehicleName( g_gangVehicleData[ gangid ] [ slotid ] [ E_MODEL ] ),
						g_gangVehicleData[ gangid ] [ slotid ] [ E_ACTIVATION_TIME ] > current_time ? ( secondstotime( g_gangVehicleData[ gangid ] [ slotid ] [ E_ACTIVATION_TIME ] - current_time ) ) : ( COL_GREEN # "Available!" )
					);
				}
				return ShowPlayerDialog( playerid, DIALOG_GANG_VEHICLE_SPAWN, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Gang Vehicles - Spawn", szBigString, "Select", "Close" );
			}

			// buy vehicle
			case 1: ShowBuyableVehiclesList( playerid, DIALOG_GANG_VD_CATEGORY, "Back" );
		}
		return 1;
	}
	else if ( dialogid == DIALOG_GANG_VD_BUY )
	{
		if ( response )
		{
			new
				type_id = GetPVarInt( playerid, "vehicle_preview" );

			for ( new id = 0, x = 0; id < sizeof( g_BuyableVehicleData ); id ++ )
			{
				if ( g_BuyableVehicleData[ id ] [ E_TYPE ] == type_id )
				{
			       	if ( x == listitem )
			      	{
			      		SetPVarInt( playerid, "buying_vehicle", id );
			      		ShowPlayerDialog( playerid, DIALOG_GANG_VD_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Vehicles - Purchase", "Purchase This Vehicle\nPreview Vehicle", "Select", "Back" );
			      		return 1;
					}
			      	x++;
				}
			}
		}
		return ShowBuyableVehiclesList( playerid, DIALOG_GANG_VD_CATEGORY, "Back" );
	}
	else if ( dialogid == DIALOG_GANG_VD_OPTIONS )
	{
		if ( ! response ) {
			return GangVehicles_ShowBuyableList( playerid, GetPVarInt( playerid, "vehicle_preview" ) );
		}

		switch ( listitem )
		{
			// bought the vehicle
			case 0:
			{
				// TODO:
			}

			// preview
			case 1:
			{
				return ShowPlayerModelPreview( playerid, PREVIEW_MODEL_GVEHICLE, "Gang Vehicle Preview", g_BuyableVehicleData[ GetPVarInt( playerid, "buying_vehicle" ) ] [ E_MODEL ] );
			}
		}
		return 1;
	}
	else if ( dialogid == DIALOG_GANG_VD_CATEGORY )
	{
		new gangid = GetPVarInt( playerid, "gang_vehicle_gang" );

		if ( ! IsValidGangID ( gangid ) ) {
			return SendError( playerid, "There was an error processing gang vehicles, please try again." );
		}

		if ( ! response ) {
			return ShowPlayerGangVehicleMenu( playerid, gangid );
		}

		return GangVehicles_ShowBuyableList( playerid, listitem + 1 );
	}
	else if ( dialogid == DIALOG_GANG_VEHICLE_SPAWN )
	{
		new gangid = GetPVarInt( playerid, "gang_vehicle_gang" );

		if ( ! IsValidGangID ( gangid ) ) {
			return SendError( playerid, "There was an error processing gang vehicles, please try again." );
		}

		if ( ! response ) {
			return ShowPlayerGangVehicleMenu( playerid, gangid );
		}

		new
			x = 0;

		foreach ( new slotid : gangvehicles< gangid > )
		{
			if ( x == listitem )
			{
				if ( g_gangVehicleData[ gangid ] [ slotid ] [ E_ACTIVATION_TIME ] > current_time ) {
					return SendError( playerid, "This vehicle cannot be spawned for another %s.", secondstotime( g_gangVehicleData[ gangid ] [ slotid ] [ E_ACTIVATION_TIME ] - current_time ) );
				}

				// TODO: spawn vehicle
				SendServerMessage( playerid, "You have spawned slot id %d", slotid );
				break;
			}
			x ++;
		}
		return 1;
	}
	return 1;
}

hook OnGangLoad( gangid )
{
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `GANG_VEHICLES` WHERE `GANG_ID` = %d ", GetGangSqlID( gangid ) ), "GangVehicles_LoadVehicles", "d", gangid );
	return 1;
}

hook OnPlayerEndModelPreview( playerid, handleid )
{
	if ( handleid == PREVIEW_MODEL_GVEHICLE )
	{
		SendServerMessage( playerid, "You have finished looking at the gang vehicle preview." );
		ShowPlayerDialog( playerid, DIALOG_GANG_VD_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Vehicles - Purchase", "Purchase This Vehicle\nPreview Vehicle", "Select", "Back" );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

CMD:car( playerid )
{
	new Float: X, Float: Y, Float: Z;
	GetPlayerPos( playerid, X, Y, Z );
	CreateGangVehicle( GetPlayerGang( playerid ), 560 );
	return 1;
}

/* ** SQL Threads ** */
thread GangVehicles_LoadVehicles( gangid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		static
			paintjob[ 90 ];

		for ( new row = 0; row < rows; row ++ )
		{
			new slotid = CreateGangVehicle(
				gangid,
				cache_get_field_content_int( row, "MODEL_ID" ),
				cache_get_field_content_int( row, "COLOR1" ),
				cache_get_field_content_int( row, "COLOR2" ),
				cache_get_field_content_int( row, "PAINTJOB" )
			);

			// load the paintjobs in
			if ( slotid != ITER_NONE ) {
				cache_get_field_content( row, "MODS", paintjob );
				sscanf( paintjob, "p<.>e<ddddddddddddddd>", g_gangVehicleModifications[ gangid ] [ slotid ] );
			}
		}
	}
	return 1;
}

/* ** Functions ** */
stock CreateGangVehicle( gangid, modelid, color1 = -1, color2 = -1, paintjob = 3 )
{
	new
		slotid = Iter_Free( gangvehicles< gangid > );

	if ( slotid != ITER_NONE )
	{
		g_gangVehicleData[ gangid ] [ slotid ] [ E_ACTIVATION_TIME ] = 0;
		g_gangVehicleData[ gangid ] [ slotid ] [ E_COLOR ] [ 0 ] = color1;
		g_gangVehicleData[ gangid ] [ slotid ] [ E_COLOR ] [ 1 ] = color2;
		g_gangVehicleData[ gangid ] [ slotid ] [ E_PAINTJOB ] = paintjob;
		g_gangVehicleData[ gangid ] [ slotid ] [ E_MODEL ] = modelid;
		ResetGangVehicleMods( gangid, slotid );

		Iter_Add( gangvehicles< gangid >, slotid );
	}
	return slotid;
}

stock ResetGangVehicleMods( gangid, slotid, fordestroy=1 )
{
	if ( ! IsValidGangVehicle( gangid, slotid ) )
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

stock ShowPlayerGangVehicleMenu( playerid, gangid )
{
	SetPVarInt( playerid, "gang_vehicle_gang", gangid );
	ShowPlayerDialog( playerid, DIALOG_GANG_VEHICLE_MENU, DIALOG_STYLE_LIST, ""COL_WHITE"Gang Vehicles", "Spawn Gang Vehicle\nBuy Gang Vehicle", "Select", "Close" );
	return 1;
}

static stock GangVehicles_ShowBuyableList( playerid, type_id )
{
	static
		szBuyableVehicles[ 1400 ];

	if ( szBuyableVehicles[ 0 ] != '\0' ) {
		for ( new i = 0; i < sizeof( g_BuyableVehicleData ); i ++ ) if ( g_BuyableVehicleData[ i ] [ E_TYPE ] == type_id ) {
			format( szBuyableVehicles, sizeof( szBuyableVehicles ), "%s"COL_GOLD"%s%s%s\t%s\n", szBuyableVehicles, cash_format( g_BuyableVehicleData[ i ] [ E_PRICE ] * GANG_VEHICLE_PRICE_FACTOR ), g_BuyableVehicleData[ i ] [ E_VIP ] ? ( "" ) : ( #COL_WHITE ), g_BuyableVehicleData[ i ] [ E_PRICE ] < 100000 ? ( "\t" ) : ( "" ), g_BuyableVehicleData[ i ] [ E_NAME ] );
		}
	}
	SetPVarInt( playerid, "vehicle_preview", type_id );
	return ShowPlayerDialog( playerid, DIALOG_GANG_VD_BUY, DIALOG_STYLE_LIST, "{FFFFFF}Vehicle Dealership", szBuyableVehicles, "Options", "Cancel" );
}

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS `GANG_VEHICLES` (
		`ID` int(11) auto_increment primary key,
		`GANG_ID` int(11),
		`MODEL_ID` int(11),
		`COLOR1` int(4),
		`COLOR2` int(4),
		`PAINTJOB` tinyint(2),
		`MODS` varchar(90)
	);
 */
