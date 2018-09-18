/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\vehicles\garages.pwn
 * Purpose: garage system to allow players to store their personal vehicles
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define UpdateBusinessTitle(%0) \
	 mysql_function_query(dbHandle,sprintf("SELECT f.`NAME` FROM `USERS` f LEFT JOIN `BUSINESSES` m ON m.`OWNER_ID`=f.`ID` WHERE m.`ID`=%d",%0),true,"OnUpdateBusinessTitle","i",%0)

#define UpdateGarageTitle(%0) \
	mysql_function_query(dbHandle,sprintf("SELECT f.`NAME` FROM `USERS` f LEFT JOIN `GARAGES` m ON m.`OWNER`=f.`ID` WHERE m.`ID`=%d",(%0)),true,"OnUpdateGarageTitle","i",(%0))

#define UpdateGarageData(%0) \
	mysql_function_query(dbHandle,sprintf("UPDATE `GARAGES` SET OWNER=%d,PRICE=%d,INTERIOR=%d WHERE ID=%d",g_garageData[(%0)][E_OWNER_ID],g_garageData[(%0)][E_PRICE],g_garageData[(%0)][E_INTERIOR_ID],(%0)),true,"","")

/* ** Definitions ** */
#define MAX_GARAGES 					( 200 )

/* ** Variables ** */
enum E_GARAGE_DATA
{
	E_OWNER_ID,					E_PRICE,					E_INTERIOR_ID,
	Float: E_X,         		Float: E_Y,             	Float: E_Z,
	Float: E_ANGLE,    			E_SQL_ID,					E_CHECKPOINT,
	Text3D: E_LABEL, 			E_WORLD
};

enum E_GARAGE_INT_DATA
{
	E_NAME[ 17 ],				E_INTERIOR,
	E_VEHICLE_CAPACITY,			E_PRICE,					Float: E_ANGLE,
	Float: E_X,					Float: E_Y, 				Float: E_Z,
	Float: E_PREVIEW_POS[ 3 ],	Float: E_PREVIEW_LOOKAT[ 3 ]
};

new
	g_garageInteriorData 			[ ] [ E_GARAGE_INT_DATA ] =
	{
		{ "Default Interior",	11, 3, 	0, 		 0.0, 		405.0301, 2508.6348, 16.7825, { 419.2017, 2517.6489, 17.9550 }, { 401.4677, 2506.3042, 16.9824 } },
		{ "Medium Interior", 	22, 5, 	1500000, 180.0, 	150.8938, 2497.9995, 16.5999, { 140.8066, 2483.9426, 16.7998 }, { 159.9573, 2501.1057, 16.7998 } },
		{ "Luxury Interior", 	33, 10, 3000000, 270.0, 	380.1852, 2496.8149, 16.4343, { 375.7204, 2486.4741, 16.6344 }, { 427.4626, 2505.8796, 16.6344 } }
	},
	g_garageData 					[ MAX_GARAGES ] [ E_GARAGE_DATA ],
	szg_garageInteriors				[ 174 ],

	// Iterator
	Iterator:garages<MAX_GARAGES>
;

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_GARAGE_INTERIORS )
	{
	    if ( response )
	    {
	        if ( p_InGarage[ playerid ] == -1 )
				return SendError( playerid, "You're not inside any garage." );

	        if ( g_garageData[ p_InGarage[ playerid ] ] [ E_OWNER_ID ] != p_AccountID[ playerid ] )
				return SendError( playerid, "You are not the owner of this garage." );

			p_ViewingInterior{ playerid } = listitem;
			ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", "Purchase Garage Interior\nPreview Garage Interior", "Select", "Back" );
		}
	}
	else if ( dialogid == DIALOG_GARAGE_INT_CONFIRM )
	{
		if ( response )
		{
	        if ( p_InGarage[ playerid ] == -1 )
				return SendError( playerid, "You're not inside any garage." );

	        if ( g_garageData[ p_InGarage[ playerid ] ] [ E_OWNER_ID ] != p_AccountID[ playerid ] )
				return SendError( playerid, "You are not the owner of this garage." );

			new
				intid = p_ViewingInterior{ playerid };

			switch( listitem )
			{
				case 0:
				{
					if ( g_garageInteriorData[ intid ] [ E_PRICE ] > GetPlayerCash( playerid ) )
					{
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", "Purchase Garage Interior\nPreview Garage Interior", "Select", "Back" );
						SendError( playerid, "This interior costs "COL_GOLD"%s"COL_WHITE". You don't have this amount.", cash_format( g_garageInteriorData[ intid ] [ E_PRICE ] ) );
					}
					else if ( ArePlayersInGarage( playerid, p_InGarage[ playerid ] ) )
					{
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", "Purchase Garage Interior\nPreview Garage Interior", "Select", "Back" );
						SendError( playerid, "You cannot purchase a garage interior if there are people inside the building." );
					}
					else if ( GetPlayerVehiclesInGarage( playerid, p_InGarage[ playerid ], .strict_mode = true ) )
					{
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", "Purchase Garage Interior\nPreview Garage Interior", "Select", "Back" );
						SendError( playerid, "You cannot purchase a garage interior if there are vehicles inside the building." );
					}
					else
					{
					    new garageid = p_InGarage[ playerid ];
					    GivePlayerCash( playerid, -( g_garageInteriorData[ intid ] [ E_PRICE ] ) );

					    if ( intid != 0 )
							SendServerMessage( playerid, "You have purchased a %s for "COL_GOLD"%s"COL_WHITE" your garage.", g_garageInteriorData[ intid ] [ E_NAME ], cash_format( g_garageInteriorData[ intid ] [ E_PRICE ] ) );
						else
						    SendServerMessage( playerid, "You have successfully reset your interior to the default interior." );

						pauseToLoad( playerid );

						SetPlayerPos( playerid, g_garageInteriorData[ intid ] [ E_X ], g_garageInteriorData[ intid ] [ E_Y ], g_garageInteriorData[ intid ] [ E_Z ] );
						SetPlayerInterior( playerid, g_garageInteriorData[ intid ] [ E_INTERIOR ] );
					  	SetPlayerVirtualWorld( playerid, g_garageData[ garageid ] [ E_WORLD ] );

						mysql_single_query( sprintf( "UPDATE `GARAGES` SET `INTERIOR`=%d WHERE `ID`=%d", ( g_garageData[ garageid ] [ E_INTERIOR_ID ] = intid ), garageid ) );
					}
				}
				case 1:
				{
					if ( p_WantedLevel[ playerid ] ) {
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", "Purchase Garage Interior\nPreview Garage Interior", "Select", "Back" );
						return SendError( playerid, "This feature requires you not to have a wanted level." );
					}
					if ( ArePlayersInGarage( playerid, p_InGarage[ playerid ] ) ) {
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", "Purchase Garage Interior\nPreview Garage Interior", "Select", "Back" );
						return SendError( playerid, "You cannot view a garage interior if there are people inside the building." );
					}

					TogglePlayerControllable( playerid, 0 );

					SetPlayerPos( playerid, g_garageInteriorData[ intid ] [ E_X ], g_garageInteriorData[ intid ] [ E_Y ], g_garageInteriorData[ intid ] [ E_Z ] );
					SetPlayerInterior( playerid, g_garageInteriorData[ intid ] [ E_INTERIOR ] );

					InterpolateCameraPos( playerid, g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], 15000, CAMERA_MOVE );
					InterpolateCameraLookAt( playerid, g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, 15000, CAMERA_MOVE );

					SendServerMessage( playerid, "You are now previewing "COL_GREY"%s "COL_GOLD"%s"COL_WHITE". Press your enter key to stop.", g_garageInteriorData[ intid ] [ E_NAME ], cash_format( g_garageInteriorData[ intid ] [ E_PRICE ] ) );
					SetPVarInt( playerid, "viewing_garageints", 1 );
				}
			}
		}
		else ShowPlayerDialog( playerid, DIALOG_GARAGE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", szg_garageInteriors, "Select", "Back" );
	}
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_SECONDARY_ATTACK ) )
	{
		if ( GetPVarInt( playerid, "viewing_garageints" ) == 1 )
		{
			new
				iInterior = g_garageData[ p_InGarage[ playerid ] ] [ E_INTERIOR_ID ];

			SendServerMessage( playerid, "You've stopped viewing the garage interior." );
			SetPlayerPos( playerid, g_garageInteriorData[ iInterior ] [ E_X ], g_garageInteriorData[ iInterior ] [ E_Y ], g_garageInteriorData[ iInterior ] [ E_Z ] );
			SetPlayerInterior( playerid, g_garageInteriorData[ iInterior ] [ E_INTERIOR ] );
		    DeletePVar( playerid, "viewing_garageints" );
			TogglePlayerControllable( playerid, 1 );
			SetCameraBehindPlayer( playerid );
			return 1;
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:garage( playerid, params[ ] )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	new
		iOwner = INVALID_PLAYER_ID,
		iGarage = p_InGarage[ playerid ],
		iVehicle = GetPlayerVehicleID( playerid ),
		iVehicleSeat = GetPlayerVehicleSeat( playerid )
	;

	if ( strmatch( params, "buy" ) )
	{
		if ( GetPlayerOwnedGarages( playerid ) >= GetPlayerGarageSlots( playerid ) ) return SendError( playerid, "You cannot purchase any more garages, you've reached the limit." );
		if ( GetPlayerScore( playerid ) < 500 ) return SendError( playerid, "You need at least 500 score to buy a garage." );

		foreach(new g : garages)
		{
			if ( IsPlayerInDynamicCP( playerid, g_garageData[ g ] [ E_CHECKPOINT ] ) )
			{
			    if ( !g_garageData[ g ] [ E_OWNER_ID ] )
			    {
			        if ( GetPlayerCash( playerid ) < g_garageData[ g ] [ E_PRICE ] )
						return SendError( playerid, "You don't have enough money to purchase this garage." );

					g_garageData[ g ] [ E_OWNER_ID ] = p_AccountID[ playerid ];
					UpdateGarageData( g );
					UpdateGarageTitle( g );
					GivePlayerCash( playerid, -( g_garageData[ g ] [ E_PRICE ] ) );
					autosaveStart( playerid, true ); // auto-save
					SendClientMessageFormatted( playerid, -1, ""COL_GREY"[GARAGE]"COL_WHITE" You have bought this garage for "COL_GOLD"%s"COL_WHITE".", cash_format( g_garageData[ g ] [ E_PRICE ] ) );
					return 1;
				}
			    else return SendError( playerid, "This garage isn't for sale." );
			}
		}
		SendError( playerid, "You are not near any garage entrances." );
		return 1;
	}
	else if ( strmatch( params, "upgrade" ) )
	{
		if ( iGarage == -1 ) return SendError( playerid, "You are not in any garage." );
		else if ( g_garageData[ iGarage ] [ E_OWNER_ID ] != p_AccountID[ playerid ] ) return SendError( playerid, "You are not the owner of this garage." );
		else
		{
			ShowPlayerDialog( playerid, DIALOG_GARAGE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}Garage Interiors", szg_garageInteriors, "Select", "Back" );
		}
		return 1;
	}
	else if ( strmatch( params, "enter" ) )
	{
		foreach(new g : garages)
		{
			if ( IsPlayerInDynamicCP( playerid, g_garageData[ g ] [ E_CHECKPOINT ] ) )
			{
				new
					iInterior = g_garageData[ g ] [ E_INTERIOR_ID ]
				;

				if ( iVehicle != 0 && iVehicleSeat == 0 )
				{
					if ( !g_garageData[ g ] [ E_OWNER_ID ] )
						return SendServerMessage( playerid, "You cannot enter unowned garages. To buy this, type "COL_GREY"/garage buy"COL_WHITE"." );

					if ( !g_buyableVehicle{ iVehicle } || g_adminSpawnedCar{ iVehicle } )
						return SendError( playerid, "Only vehicles that are sold through the vehicle dealership can be entered through." );

					new iSlot = getVehicleSlotFromID( iVehicle, iOwner );

					if ( p_AccountID[ iOwner ] != g_garageData[ g ] [ E_OWNER_ID ] )
						return SendError( playerid, "You cannot enter with vehicles that are not owned by the owner of this garage." );

					if ( g_vehicleData[ iOwner ] [ iSlot ] [ E_LOCKED ] && playerid != iOwner )
						return SendError( playerid, "This vehicle is locked and thus you cannot enter/exit a garage with it." );

					SetPlayerVehicleInteriorData( iOwner, iSlot, g_garageInteriorData[ iInterior ] [ E_INTERIOR ], g_garageData[ g ] [ E_WORLD ], g_garageInteriorData[ iInterior ] [ E_X ], g_garageInteriorData[ iInterior ] [ E_Y ], g_garageInteriorData[ iInterior ] [ E_Z ] + 2.0, g_garageInteriorData[ iInterior ] [ E_ANGLE ], g );
				}
				else
				{
					pauseToLoad( playerid );
					SetPlayerPos( playerid, g_garageInteriorData[ iInterior ] [ E_X ], g_garageInteriorData[ iInterior ] [ E_Y ], g_garageInteriorData[ iInterior ] [ E_Z ] );
					SetPlayerInterior( playerid, g_garageInteriorData[ iInterior ] [ E_INTERIOR ] );
				  	SetPlayerVirtualWorld( playerid, g_garageData[ g ] [ E_WORLD ] );
				}
				return ( p_InGarage[ playerid ] = g ), 1;
			}
		}
		return SendError( playerid, "You are not near any garage entrance." );
	}
	else if ( strmatch( params, "exit" ) )
	{
		if ( iGarage == -1 ) return SendError( playerid, "You are not in any garage." );
		else
		{
			if ( iVehicle != 0 && iVehicleSeat == 0 )
			{
				new
					iSlot = getVehicleSlotFromID( iVehicle, iOwner );

				if ( g_vehicleData[ iOwner ] [ iSlot ] [ E_LOCKED ] && playerid != iOwner )
					return SendError( playerid, "This vehicle is locked and thus you cannot enter/exit a garage with it." );

				SetPlayerVehicleInteriorData( iOwner, iSlot, 0, 0, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], g_garageData[ iGarage ] [ E_ANGLE ] );
			}
			else
			{
				SetPlayerPosEx( playerid, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], 0 ), SetPlayerVirtualWorld( playerid, 0 );
			}
			return ( p_InGarage[ playerid ] = -1 ), 1;
		}
	}
	else if ( strmatch( params, "sell" ) )
	{
		if ( iGarage == -1 ) return SendError( playerid, "You are not in any garage." );
		else if ( g_garageData[ iGarage ] [ E_OWNER_ID ] != p_AccountID[ playerid ] ) return SendError( playerid, "You are not the owner of this garage." );
		else
		{
			new
				iCashMoney = floatround( ( g_garageData[ iGarage ] [ E_PRICE ] / 2 ) + ( g_garageInteriorData[ g_garageData[ iGarage ] [ E_INTERIOR_ID ] ] [ E_PRICE ] / 2 ) );

			if ( GetPlayerVehiclesInGarage( playerid, iGarage, .strict_mode = true ) )
				return SendError( playerid, "You must ensure all vehicles are removed from the facility before selling it." );

			g_garageData[ iGarage ] [ E_OWNER_ID ] 		= 0;
			g_garageData[ iGarage ] [ E_INTERIOR_ID ] 	= 0;

			// UpdateGarageData( iGarage ); (add on resale)
			// OnUpdateGarageTitle( iGarage ); // No point querying (add on resale)
			GivePlayerCash( playerid, iCashMoney );

			SetPlayerPosEx( playerid, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], 0 ), SetPlayerVirtualWorld( playerid, 0 );
			SendServerMessage( playerid, "You have successfully sold your garage for "COL_GOLD"%s"COL_WHITE".", cash_format( iCashMoney ) );

			// Destroy garage, prevent resale
			DestroyGarage( iGarage );
		}
		return 1;
	}
	else if ( !strcmp( params, "vehicle", false, 7 ) )
	{
	    new
	    	ownerid = INVALID_PLAYER_ID,
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( iGarage == -1 )
			return SendError( playerid, "You are not in any garage." );

		if ( g_garageData[ iGarage ] [ E_OWNER_ID ] != p_AccountID[ playerid ] )
			return SendError( playerid, "You are not the owner of this garage." );

		if ( !IsPlayerInAnyVehicle( playerid ) )
			return SendError( playerid, "You need to be in a vehicle to use this command." );

		if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER )
			return SendError( playerid, "You need to be a driver to use this command." );

		if ( vehicleid == -1 )
			return SendError( playerid, "This vehicle isn't a buyable vehicle." );

		if ( playerid != ownerid )
			return SendError( playerid, "This vehicle does not belong to you." );

		if ( !strlen( params[ 8 ] ) )
			return SendUsage( playerid, "/garage vehicle [PIMP/EDIT]" );

		if ( strmatch( params[ 8 ], "pimp" ) )
		{
			if ( GetVehicleCustomComponents( ownerid, vehicleid ) >= GetPlayerPimpVehicleSlots( ownerid ) )
				return SendError( playerid, "You cannot purchase more than %d vehicle components.", GetPlayerPimpVehicleSlots( ownerid ) );

			return ShowVehicleComponentCategories( playerid );
		}
		else if ( strmatch( params[ 8 ], "edit" ) )
		{
			new
				count = 0;

			szBigString[ 0 ] = '\0';

			for( new i = 0; i < MAX_PIMPS; i++ ) if ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ i ] ) {
				for( new c = 0; c < sizeof( g_vehicleComponentsData ); c++ ) if ( g_vehicleComponentsData[ c ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )  {
					format( szBigString, sizeof( szBigString ), "%s%s\n", szBigString, g_vehicleComponentsData[ c ] [ E_NAME ] );
				}
				count ++;
			}

			if ( !count )
				return SendError( playerid, "This vehicle does not have any components to it." );

			return ShowPlayerDialog( playerid, DIALOG_COMPONENT_MENU, DIALOG_STYLE_LIST, "Vehicle Components", szBigString, "Select", "Cancel" );
		}
		else return SendUsage( playerid, "/garage vehicle [PIMP/EDIT]" );
	}
	return SendUsage( playerid, "/garage [BUY/UPGRADE/VEHICLE/ENTER/EXIT/SELL]" );
}

/* ** SQL Threads ** */
thread OnGaragesLoad( )
{
	new
		rows, fields, i = -1,
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			CreateGarage(
				cache_get_field_content_int( i, "OWNER", dbHandle ),
				cache_get_field_content_int( i, "PRICE", dbHandle ),
				cache_get_field_content_int( i, "INTERIOR", dbHandle ),
				cache_get_field_content_float( i, "X", dbHandle ),
				cache_get_field_content_float( i, "Y", dbHandle ),
				cache_get_field_content_float( i, "Z", dbHandle ),
				cache_get_field_content_float( i, "ANGLE", dbHandle ),
				cache_get_field_content_int( i, "ID", dbHandle )
			);
		}
	}
	printf( "[GARAGES]: %d garages have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

thread OnUpdateGarageTitle( slot )
{
	new
		rows, szOwner[ MAX_PLAYER_NAME ] = "No-one";

	cache_get_data( rows, tmpVariable );

	if ( rows )
		cache_get_field_content( 0, "NAME", szOwner );

	UpdateDynamic3DTextLabelText( g_garageData[ slot ] [ E_LABEL ], COLOR_GOLD, sprintf( "Garage(%d)\nOwner:"COL_WHITE" %s\n"COL_GOLD"Price:"COL_WHITE" %s", slot, szOwner, cash_format( g_garageData[ slot ] [ E_PRICE ] ) ) );
	return 1;
}

/* ** Functions ** */
stock CreateGarage( iAccountID, iPrice, iInterior, Float: fX, Float: fY, Float: fZ, Float: fAngle, iExistingID = ITER_NONE )
{
	new
		iGarage = iExistingID != ITER_NONE ? iExistingID : Iter_Free(garages);

	if ( Iter_Contains( garages, iExistingID ) )
		iGarage = ITER_NONE; // In the unlikelihood...

	if ( iGarage != ITER_NONE )
	{
		g_garageData[ iGarage ] [ E_OWNER_ID ] 		= iAccountID;
		g_garageData[ iGarage ] [ E_PRICE ] 		= iPrice;
		g_garageData[ iGarage ] [ E_INTERIOR_ID ] 	= iInterior;
		g_garageData[ iGarage ] [ E_WORLD ] 		= iGarage + ( MAX_GARAGES * 32 ); // Random

		g_garageData[ iGarage ] [ E_X ] 	= fX;
		g_garageData[ iGarage ] [ E_Y ] 	= fY;
		g_garageData[ iGarage ] [ E_Z ] 	= fZ;
		g_garageData[ iGarage ] [ E_ANGLE ] = fAngle;

		g_garageData[ iGarage ] [ E_CHECKPOINT ] = CreateDynamicCP( fX, fY, fZ, 3.0, -1, 0, -1, 100.0 );
	    g_garageData[ iGarage ] [ E_LABEL ] 	 = CreateDynamic3DTextLabel( sprintf( "Garage(%d)\nOwner:"COL_WHITE" No-one\n"COL_GOLD"Price:"COL_WHITE" %s", iGarage, cash_format( g_garageData[ iGarage ] [ E_PRICE ] ) ), COLOR_GOLD, fX, fY, fZ, 20.0 );

		if ( iExistingID != ITER_NONE && iAccountID ) UpdateGarageTitle( iGarage );
		else if ( iExistingID == ITER_NONE )
		{
			format( szBigString, 162, "INSERT INTO `GARAGES`(`ID`,`OWNER`,`PRICE`,`INTERIOR`,`X`,`Y`,`Z`,`ANGLE`) VALUES (%d,%d,%d,%d,%f,%f,%f,%f)", iGarage, iAccountID, iPrice, iInterior, fX, fY, fZ, fAngle );
			mysql_single_query( szBigString );
		}

		Iter_Add(garages, iGarage);
	}
	return iGarage;
}

stock DestroyGarage( iGarage )
{
	if ( iGarage < 0 || iGarage >= MAX_GARAGES )
		return 0;

	if ( !Iter_Contains( garages, iGarage ) )
	    return 0;

	new
		playerid = GetPlayerIDFromAccountID( g_garageData[ iGarage ] [ E_OWNER_ID ] );

	if ( IsPlayerConnected( playerid ) )
	{
		for( new i = 0; i < MAX_BUYABLE_VEHICLES; i++ )
			if ( g_vehicleData[ playerid ] [ i ] [ E_CREATED ] && g_vehicleData[ playerid ] [ i ] [ E_GARAGE ] == iGarage )
				SetVehiclePos( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ], g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ] ), LinkVehicleToInterior( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ], 0 ), SetVehicleVirtualWorld( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ], 0 );

	    SendClientMessage( playerid, -1, ""COL_PINK"[GARAGE]"COL_WHITE" One of your garages has been destroyed.");
	}

	mysql_single_query( sprintf( "UPDATE `VEHICLES` SET `X`=%f,`Y`=%f,`Z`=%f,`GARAGE`=-1 WHERE `GARAGE`=%d", g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], iGarage ) );
	mysql_single_query( sprintf( "DELETE FROM `GARAGES` WHERE `ID`=%d", iGarage ) );

	Iter_Remove(garages, iGarage);
	g_garageData[ iGarage ] [ E_OWNER_ID ] = 0;
	DestroyDynamicCP( g_garageData[ iGarage ] [ E_CHECKPOINT ] );
	DestroyDynamic3DTextLabel( g_garageData[ iGarage ] [ E_LABEL ] );
	return 1;
}

stock PlayerBreachedGarageLimit( playerid, vID, bool: admin_place = false )
{
	new
		iOwner = playerid;

	if ( admin_place ) /// Admin Mode
 		getVehicleSlotFromID( GetPlayerVehicleID( playerid ), iOwner );

	// Garage System
	if ( ( g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ] = p_InGarage[ playerid ] ) != -1 )
	{
		new
			iGarage = g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ],
			iVehiclesOccupying = GetPlayerVehiclesInGarage( iOwner, iGarage )
		;

		if ( g_vehicleData[ iOwner ] [ vID ] [ E_OWNER_ID ] != g_garageData[ iGarage ] [ E_OWNER_ID ] )
			return g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ] = -1, -1;

		if ( iVehiclesOccupying > g_garageInteriorData[ g_garageData[ iGarage ] [ E_INTERIOR_ID ] ] [ E_VEHICLE_CAPACITY ] )
			return g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ] = -1, -2;
	}
	return 1;
}

stock GetPlayerOwnedGarages( playerid ) {
	new
		count = 0;

	foreach ( new garageid : garages ) if ( g_garageData[ garageid ] [ E_OWNER_ID ] == p_AccountID[ playerid ] ) {
		count ++;
	}
	return count;
}

stock GetPlayerVehiclesInGarage( playerid, slot, strict_mode=0 )
{
	new
		count = 0;

	if ( Iter_Contains( garages, slot ) )
	{
		for( new i = 0; i < MAX_BUYABLE_VEHICLES; i++ ) if ( g_vehicleData[ playerid ] [ i ] [ E_CREATED ] ) {
			if ( g_vehicleData[ playerid ] [ i ] [ E_GARAGE ] == slot || ( strict_mode && GetVehicleVirtualWorld( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ] ) == g_garageData[ slot ] [ E_WORLD ] ) )
				count++;
		}
	}
	return count;
}

stock ArePlayersInGarage( playerid, slot )
{
	foreach ( new i : Player ) {
		if ( p_InGarage[ i ] == slot && i != playerid ) {
			return true;
		}
	}
	return false;
}

stock UpdatePlayerGarageTitles( playerid )
{
    foreach ( new g : garages ) if ( g_garageData[ g ] [ E_OWNER_ID ] == GetPlayerAccountID( playerid ) ) {
		UpdateGarageTitle( g );
    }
	return 1;
}

stock GetGarageVehicleCapacity( garageid ) {
	return g_garageInteriorData[ g_garageData[ garageid ] [ E_INTERIOR_ID ] ] [ E_VEHICLE_CAPACITY ];
}

stock GetGarageInteriorID( garageid ) {
	return g_garageInteriorData[ g_garageData[ garageid ] [ E_INTERIOR_ID ] ] [ E_INTERIOR ];
}

stock GetGarageVirtualWorld( garageid ) {
	return g_garageData[ garageid ] [ E_WORLD ];
}
