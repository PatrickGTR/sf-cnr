	/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr/commands/admin/admin_five.pwn
 * Purpose: level five administrator commands (cnr)
 */

/* ** Commands ** */
CMD:armorall( playerid, params[ ] )
{
	if ( p_AdminLevel[ playerid ] < 5 )
		return SendError( playerid, ADMIN_COMMAND_REJECT );

	new world = GetPlayerVirtualWorld( playerid );
	AddAdminLogLineFormatted( "%s(%d) has given armor to everybody in their world", ReturnPlayerName( playerid ), playerid );
	foreach ( new i : Player ) {
	    if ( !p_Jailed{ i } && world == GetPlayerVirtualWorld( i ) ) SetPlayerArmour( i, 100.0 );
	}
	SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" Everyone has been given armor by %s(%d) in their world!", ReturnPlayerName( playerid ), playerid );
	return 1;
}

CMD:check( playerid, params[ ] )
{
	new
		pID
	;

    if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/check [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		new
			playerserial[ 45 ];

		gpci( pID, playerserial, sizeof( playerserial ) ); // playerserial

		format( szNormalString, sizeof( szNormalString ), "SELECT `NAME`,`IP`,`COUNTRY` FROM `BANS` WHERE `SERIAL`='%s' LIMIT 32", mysql_escape( playerserial ) );
		mysql_function_query( dbHandle, szNormalString, true, "readgpcibans", "dd", playerid, pID );
	}
	return 1;
}

thread readgpcibans( playerid, searchid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szName[ MAX_PLAYER_NAME ],
    		szIP[ 16 ],
    		szCountry[ 3 ]
    	;

    	szLargeString = ""COL_GREY"Username\t"COL_GREY"IP Address\t"COL_GREY"Country (XX)\n";

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "COUNTRY", szCountry );
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "IP", szIP );

			if ( isnull( szCountry ) )
				szCountry = "-";

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\t%s\n", szLargeString, szName, szIP, szCountry );
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}Serial check on %s(%d)", ReturnPlayerName( searchid ), searchid ), szLargeString, "Okay", "" );
		return 1;
	}
	SendError( playerid, "This user looks clean!" );
	return 1;
}

CMD:c( playerid, params[ ] )
{
	new
	    msg[ 90 ]
	;

    if ( p_AdminLevel[ playerid ] < 5 ) return 0;
    else if ( sscanf( params, "s[90]", msg ) ) return SendUsage( playerid, "/c [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendServerMessage( playerid, "Please do not advertise." );
    else
	{
		foreach(new councilid : Player)
			if ( p_AdminLevel[ councilid ] >= 5 || IsPlayerUnderCover( councilid ) )
				SendClientMessageFormatted( councilid, -1, "{00CCFF}<Council Chat> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, msg );
	}
	return 1;
}

CMD:creategarage( playerid, params[ ] )
{
    new
		cost, iTmp, iVehicle,
		Float: X, Float: Y, Float: Z, Float: Angle
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", cost ) ) return SendUsage( playerid, "/creategarage [COST]" );
	else if ( cost < 100 ) return SendError( playerid, "The price must be located above 100 dollars." );
	else if ( !( iVehicle = GetPlayerVehicleID( playerid ) ) ) return SendError( playerid, "You are not in any vehicle." );
	else
	{
		AddAdminLogLineFormatted( "%s(%d) has created a garage", ReturnPlayerName( playerid ), playerid );

		if ( GetVehiclePos( iVehicle, X, Y, Z ) && GetVehicleZAngle( iVehicle, Angle ) )
		{
		    if ( ( iTmp = CreateGarage( 0, cost, 0, X, Y, Z, Angle ) ) != -1 )
		    {
				SaveToAdminLog( playerid, iTmp, "created garage" );
		    	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[GARAGE]"COL_WHITE" You have created a %s garage taking up garage id %d.", cash_format( cost ), iTmp );
		    }
			else
				SendClientMessage( playerid, -1, ""COL_PINK"[GARAGE]"COL_WHITE" Unable to create a garage due to a unexpected error." );
		}
	}
	return 1;
}

CMD:destroygarage( playerid, params[ ] )
{
	new
	    iGarage
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", iGarage ) ) return SendUsage( playerid, "/destroygarage [GARAGE_ID]" );
	else if ( iGarage < 0 || iGarage >= MAX_GARAGES ) return SendError( playerid, "Invalid Garage ID." );
	else if ( !Iter_Contains( garages, iGarage ) ) return SendError( playerid, "Invalid Garage ID." );
	else
	{
		SaveToAdminLog( playerid, iGarage, "destroy garage" );
		format( szBigString, sizeof( szBigString ), "[DG] [%s] %s | %d | %d\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), g_garageData[ iGarage ] [ E_OWNER_ID ], iGarage );
	    AddFileLogLine( "log_garages.txt", szBigString );
		AddAdminLogLineFormatted( "%s(%d) has deleted a garage", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_PINK"[GARAGE]"COL_WHITE" You have destroyed the garage ID %d.", iGarage );
	    DestroyGarage( iGarage );
	}
	return 1;
}

CMD:connectsong( playerid, params[ ] )
{
	new
		szURL[ 128 ];

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "s[128]", szURL ) ) return SendUsage( playerid, "/connectsong [SONG_URL]" );
	else
	{
		SaveToAdminLogFormatted( playerid, 0, "updated connection song to %s", szURL );
		SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" %s(%d) has set the connection song to: "COL_GREY"%s", ReturnPlayerName( playerid ), playerid, szURL );
		UpdateServerVariable( "connectsong", 0, 0.0, szURL, GLOBAL_VARTYPE_STRING );
	}
	return 1;
}

CMD:discordurl( playerid, params[ ] )
{
	new
		szURL[ 128 ];

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "s[128]", szURL ) ) return SendUsage( playerid, "/discordurl [DISCORD_URL]" );
	else
	{
		SaveToAdminLogFormatted( playerid, 0, "updated discord url to %s", szURL );
		SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" %s(%d) has set the discord url to: "COL_GREY"%s", ReturnPlayerName( playerid ), playerid, szURL );
		UpdateServerVariable( "discordurl", 0, 0.0, szURL, GLOBAL_VARTYPE_STRING );
	}
	return 1;
}

CMD:creategate( playerid, params[ ] )
{
	new
		pID, password[ 8 ], model, Float: speed, Float: range,
		Float: X, Float: Y, Float: Z
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "udffs[8]", pID, model, speed, range, password ) ) return SendUsage( playerid, "/creategate [PLAYER_ID] [MODEL_ID] [SPEED] [RANGE] [PASSWORD]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( model < 0 || model > 20000 ) return SendError( playerid, "Invalid Object Model." );
	else if ( speed < 1.0 || speed > 100.0 ) return SendError( playerid, "Please specify a speed between 1.0 and 100.0." );
	else if ( range < 2.5 || speed > 500.0 ) return SendError( playerid, "Please specify a range between 2.5 and 500.0." );
	else if ( strlen( password ) > 4 ) return SendError( playerid, "Password length can be only a maximum of four characters." );
	else
	{
		GetXYInFrontOfPlayer( playerid, X, Y, Z, 5.0 );
		new iTmp = CreateGate( pID, password, model, speed, range, X, Y, Z, 0.0, 0.0, 0.0 );
	    if ( iTmp != -1 ) {
			SaveToAdminLog( playerid, iTmp, "created gate" );
	    	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[GATE]"COL_WHITE" You have created a gate taking place of ID: %d", iTmp );
	    }
		else SendClientMessage( playerid, -1, ""COL_PINK"[GATE]"COL_WHITE" Unable to create a gate due to a unexpected error." );
	}
	return 1;
}

CMD:editgate( playerid, params[ ] )
{
	new
		gID;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", gID ) ) return SendUsage( playerid, "/editgate [GATE_ID]" );
	else if ( !Iter_Contains( gates, gID ) ) return SendError( playerid, "Invalid Gate ID" );
	else
	{
		format( szLargeString, sizeof( szLargeString ),
			""COL_RED"Remove This Gate?\t \nOwner ID\t"COL_GREY"%d\nName\t"COL_GREY"%s\nPassword\t"COL_GREY"%s\nModel\t"COL_GREY"%d\nSpeed\t"COL_GREY"%f\nRange\t"COL_GREY"%f\nPause\t"COL_GREY"%d MS\nGang ID\t%d\nChange Closed Positioning\t \nChange Opened Positioning\t ",
			g_gateData[ gID ] [ E_OWNER ], g_gateData[ gID ] [ E_NAME ], g_gateData[ gID ] [ E_PASS ], g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_SPEED ], g_gateData[ gID ] [ E_RANGE ], g_gateData[ gID ] [ E_TIME ], g_gateData[ gID ] [ E_GANG_SQL_ID ]
		);

		SetPVarInt( playerid, "gate_editing", gID );
		SaveToAdminLog( playerid, gID, "editing gate" );
		ShowPlayerDialog( playerid, DIALOG_GATE, DIALOG_STYLE_TABLIST, "{FFFFFF}Edit Gate", szLargeString, "Select", "Cancel" );
	}
	return 1;
}

CMD:acunban( playerid, params[ ] )
{
	new
		address[ 16 ];

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf(params, "s[16]", address ) ) SendUsage( playerid, "/acunban [IP_ADDRESS]" );
	else if ( !textContainsIP( params ) ) return SendError( playerid, "This is not an IP address." );
	else
	{
 		UnBlockIpAddress( address );
		SetServerRule( "unbanip", address );
		SetServerRule( "reloadbans", "" );
		SaveToAdminLogFormatted( playerid, 0, "acunban %s", address );
	 	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[AC UNBAN]{FFFFFF} You've unbanned %s from the anti-cheat.", address );
	 	AddAdminLogLineFormatted( "%s(%d) has un-banned %s", ReturnPlayerName( playerid ), playerid, address );
	}
	return 1;
}

CMD:safeisbugged( playerid, params[ ] )
{
 	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	new
        Float: distance = 99999.99,
		robberyid = getClosestRobberySafe( playerid, distance )
	;

	if ( robberyid != INVALID_OBJECT_ID )
	{
		SendClientMessage( playerid, COLOR_GOLD, "___ SAFE DATA ___");
		SendClientMessageFormatted( playerid, -1, "OPEN : %d | ROBBED : %d | C4 : %d | DRILL : %d | DRILL PLACER : %d | DRILL EFFECT : %d",
			g_robberyData[ robberyid ] [ E_OPEN ], g_robberyData[ robberyid ] [ E_ROBBED ], g_robberyData[ robberyid ] [ E_C4 ],
			g_robberyData[ robberyid ] [ E_DRILL ], g_robberyData[ robberyid ] [ E_DRILL_PLACER ], g_robberyData[ robberyid ] [ E_DRILL_EFFECT ] );

		SendClientMessageFormatted( playerid, -1, "REPLENISH : %d | RAW TIMESTAMP : %d | CURRENT TIME: %d | ID : %d | NAME : %s",
			g_robberyData[ robberyid ] [ E_ROB_TIME ] - g_iTime, g_robberyData[ robberyid ] [ E_ROB_TIME ], g_iTime, robberyid, g_robberyData[ robberyid ] [ E_NAME ] );
	}
	else return SendError( playerid, "You're not near any safe." );
	return 1;
}

CMD:autovehrespawn( playerid, params[ ] )
{
	#if defined _vsync_included
	    #pragma unused rl_AutoVehicleRespawner
		SendError( playerid, "This feature is disabled as protection for car warping is enabled (VehicleSync)." );
	#else
		new tick;
		if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
		else if ( sscanf( params, "d", tick ) ) return SendUsage( playerid, "/autovehrespawn [MILLISECONDS (0 = DISABLE)]" );
		else if ( tick != 0 && tick < 2500 ) return SendError( playerid, "The respawn tick cannot be less than 2500ms." );
		else
		{
	        if ( tick == 0 ) {
				KillTimer( rl_AutoVehicleRespawner );
				rl_AutoVehicleRespawner = 0xFF;
				SendServerMessage( playerid, "Auto vehicle spawner disabled." );
				return 1;
			}

			KillTimer( rl_AutoVehicleRespawner );
			rl_AutoVehicleRespawner = SetTimer( "autoVehicleSpawn", tick, true );

			SaveToAdminLogFormatted( playerid, 0, "autovehrespawn %d", tick );
	        SendClientMessageFormatted( playerid, COLOR_WHITE, ""COL_GREY"[SERVER]"COL_WHITE" The auto vehicle spawner has been set to %dms.", tick );
		}
	#endif
	return 1;
}

function autoVehicleSpawn( )
{
    for( new i; i < MAX_VEHICLES; i++ ) if ( IsValidVehicle( i ) )
   	{
		if ( IsVehicleOccupied( i, .include_vehicle_interior = true ) == -1 )
		{
			if ( g_buyableVehicle{ i } == true )
				RespawnBuyableVehicle( i );
			else
				SetVehicleToRespawn( i );
    	}
	}
	return 1;
}

/*CMD:megaban( playerid, params [ ] )
{
    new
	    pID,
		reason[ 50 ]
	;
	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "uS(No Reason)[50]", pID, reason ) ) SendUsage( playerid, "/megaban [PLAYER_ID] [REASON]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	//else if ( pID == playerid ) return SendError( playerid, "You cannot ban yourself." );
    //else if ( p_AdminLevel[ playerid ] < p_AdminLevel[ pID ] ) return SendError( playerid, "This player has a higher administration level than you." );
	else
	{
		SaveToAdminLogFormatted( playerid, 0, "megaban %s (reason: %s)", ReturnPlayerName( pID ), reason );
        AddAdminLogLineFormatted( "%s(%d) has mega-banned %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	    SendGlobalMessage( -1, ""COL_PINK"[ADMIN]{FFFFFF} %s has mega-banned %s(%d) "COL_GREEN"[REASON: %s]", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), pID, reason );
		BanPlayerISP( pID );
	}
	return 1;
}*/

CMD:achangename( playerid, params[ ] )
{
	new
	    pID,
	    nName[ 24 ],
	    szQuery[ 100 ]
	;
	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "us[24]", pID, nName ) ) return SendUsage( playerid, "/achangename [PLAYER_ID] [NEW_NAME]" );
	else if ( !IsPlayerConnected( pID ) ) SendError( playerid, "Invalid Player ID." );
	else if ( !isValidPlayerName( nName ) ) return SendError( playerid, "Invalid Name Character." );
	else if ( p_OwnedHouses[ pID ] > 0 || GetPlayerOwnedApartments( pID ) > 0 ) return SendError( playerid, "This player has a house and/or apartment." ), SendError( pID, ""COL_ORANGE"In order to change your name, you must sell your houses and/or apartment.");
	else
	{
	    format( szQuery, sizeof( szQuery ), "SELECT `NAME` FROM `USERS` WHERE `NAME` = '%s'", mysql_escape( nName ) );
	  	mysql_function_query( dbHandle, szQuery, true, "OnAdminChangePlayerName", "dds", playerid, pID, nName );
	}
	return 1;
}

thread OnAdminChangePlayerName( playerid, pID, nName[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );

	if ( !rows )
	{
	 	mysql_single_query( sprintf( "UPDATE `USERS` SET `NAME` = '%s' WHERE `NAME` = '%s'", mysql_escape( nName ), mysql_escape( ReturnPlayerName( pID ) ) ) );
	 	mysql_single_query( sprintf( "INSERT INTO `NAME_CHANGES`(`USER_ID`,`ADMIN_ID`,`NAME`) VALUES (%d,%d,'%s')", p_AccountID[ pID ], p_AccountID[ playerid ], mysql_escape( ReturnPlayerName( pID ) ) ) );

		SaveToAdminLogFormatted( playerid, 0, "changename %s to %s", ReturnPlayerName( pID ), nName );
		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have changed %s(%d)'s name to %s!", ReturnPlayerName( pID ), pID, nName );
		SendClientMessageFormatted( pID, -1, ""COL_PINK"[ADMIN]"COL_WHITE" Your name has been changed to %s by %s(%d)!", nName, ReturnPlayerName( playerid ), playerid );
        AddAdminLogLineFormatted( "%s(%d) has changed %s(%d)'s name to %s", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, nName );

		SetPlayerName( pID, nName );

    	// Update New Things
    	foreach(new g : garages)
    		if ( g_garageData[ g ] [ E_OWNER_ID ] == p_AccountID[ playerid ] )
    			UpdateGarageTitle( g );
	}
	else SendError( playerid, "This name is taken already." );
	return 1;
}

CMD:unbanip( playerid, params[ ] )
{
	new
		address[16],
		Query[70]
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if (sscanf(params, "s[16]", address)) SendUsage(playerid, "/unbanip [IP_ADDRESS]");
	else
	{
		format( Query, sizeof( Query ), "SELECT `IP` FROM `BANS` WHERE `IP` = '%s'", mysql_escape( address ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanIP", "dds", playerid, 0, address );
	}
	return 1;
}

thread OnPlayerUnbanIP( playerid, irc, address[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );
	if ( rows )
	{
    	if ( !irc )
    	{
			SaveToAdminLogFormatted( playerid, 0, "unbanip %s", address );
    		AddAdminLogLineFormatted( "%s(%d) has un-banned IP %s", ReturnPlayerName( playerid ), playerid, address );
	 		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]{FFFFFF} IP %s has been un-banned from the server.", address );
		}
		else
		{
    		DCC_SendChannelMessageFormatted( discordGeneralChan, "**(UNBANNED)** IP %s has been un-banned from the server.", address );
		}
		format( szNormalString, sizeof( szNormalString ), "DELETE FROM `BANS` WHERE `IP` = '%s'", mysql_escape( address ) );
		mysql_single_query( szNormalString );
	}
	else {
		if ( !irc ) SendError(playerid, "This IP Address is not recognised!");
	}
	return 1;
}

CMD:unban( playerid, params[ ] )
{
	new
		player[24],
		Query[70]
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "s[24]", player ) ) SendUsage( playerid, "/unban [NAME]" );
	else
	{
		format( Query, sizeof( Query ), "SELECT `NAME` FROM `BANS` WHERE `NAME` = '%s'", mysql_escape( player ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanPlayer", "dds", playerid, 0, player );
	}
	return 1;
}

thread OnPlayerUnbanPlayer( playerid, irc, player[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );
	if ( rows )
	{
   	 	if ( !irc ) AddAdminLogLineFormatted( "%s(%d) has un-banned %s", ReturnPlayerName( playerid ), playerid, player );
		else
		{
			format(szNormalString, sizeof(szNormalString),"**(UNBANNED)** %s has been un-banned from the server.", player);
    		DCC_SendChannelMessage( discordGeneralChan, szNormalString );
		}
		format(szNormalString, sizeof(szNormalString), "DELETE FROM `BANS` WHERE `NAME` = '%s'", mysql_escape( player ) );
		mysql_single_query( szNormalString );

		SaveToAdminLogFormatted( playerid, 0, "unban %s", player );
	 	SendClientMessageToAllFormatted(-1, ""COL_PINK"[ADMIN]{FFFFFF} \"%s\" has been un-banned from the server.", player);
	}
	else {
		if ( !irc ) SendError(playerid, "This player is not recognised!");
	}
	return 1;
}

CMD:doublexp( playerid, params[ ] )
{
	//g_doubleXP
	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );

	UpdateServerVariable( "doublexp", IsDoubleXP( ) ? 0 : 1, 0.0, "", GLOBAL_VARTYPE_INT );

	if ( IsDoubleXP( ) )
	{
		TextDrawShowForAll( g_DoubleXPTD );
		GameTextForAll( "~w~DOUBLE ~y~~h~XP~g~~h~~h~ ACTIVATED!", 6000, 3 );
	}
	else
	{
		TextDrawHideForAll( g_DoubleXPTD );
		GameTextForAll( "~w~DOUBLE ~y~~h~XP~r~~h~~h~ DEACTIVATED!", 6000, 3 );
	}

	SaveToAdminLogFormatted( playerid, 0, "doublexp %s", IsDoubleXP( ) ? ("toggled") : ("un-toggled") );
    SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have %s double XP!", IsDoubleXP( ) ? ("toggled") : ("un-toggled") );
	AddAdminLogLineFormatted( "%s(%d) has %s double xp", ReturnPlayerName( playerid ), playerid, IsDoubleXP( ) ? ("toggled") : ("un-toggled") );
	return 1;
}

CMD:toggleviewpm( playerid, params[ ] )
{
	if ( p_AdminLevel[ playerid ] < 5 && !IsPlayerUnderCover( playerid ) ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    p_ToggledViewPM{ playerid } = !p_ToggledViewPM{ playerid };
    SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have %s viewing peoples private messages.", p_ToggledViewPM{ playerid } == true ? ("toggled") : ("un-toggled") );
    if ( !IsPlayerUnderCover( playerid ) ) {
		AddAdminLogLineFormatted( "%s(%d) has %s viewing pm's", ReturnPlayerName( playerid ), playerid, p_ToggledViewPM{ playerid } == true ? ("toggled") : ("un-toggled") );
    }
 	return 1;
}

CMD:respawnallv( playerid, params[ ] )
{
 	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else
	{
	    for( new i; i < MAX_VEHICLES; i++ ) if ( IsValidVehicle( i ) ) {
	    	#if defined __cnr__chuffsec
	    	if ( g_secureTruckVehicle == i ) continue;
	    	#endif
			SetVehicleToRespawn( i );
		}
		AddAdminLogLineFormatted( "%s(%d) has respawned all vehicles", ReturnPlayerName( playerid ), playerid );
		SendServerMessage( playerid, "You have respawned all vehicles." );
	}
	return 1;
}

#if defined __cnr__chuffsec
CMD:reconnectchuff( playerid, params[ ] )
{
 	if ( p_AdminLevel[ playerid ] < 5 )
 		return SendError( playerid, ADMIN_COMMAND_REJECT );

 	new
 		chuffsecid = GetSecurityDriverPlayer( );

 	if ( chuffsecid != INVALID_PLAYER_ID ) {
 		Kick( chuffsecid );
 	} else {
		ConnectNPC( SECURE_TRUCK_DRIVER_NAME, "secureguard" );
 	}

	AddAdminLogLineFormatted( "%s(%d) has attempted to reconnect %s", ReturnPlayerName( playerid ), playerid, SECURE_TRUCK_DRIVER_NAME );
	SendServerMessage( playerid, "You are now attempting to reconnect %s.", SECURE_TRUCK_DRIVER_NAME );
	return 1;
}
#endif

CMD:createbribe( playerid, params[ ] )
{
    new
		Float: X, Float: Y, Float: Z
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else
	{
		GetPlayerPos( playerid, X, Y, Z );
	    new iTmp = CreateBribe( X, Y, Z );
		AddAdminLogLineFormatted( "%s(%d) has created a bribe", ReturnPlayerName( playerid ), playerid );
	    if ( iTmp != -1 ) {
			SaveToAdminLog( playerid, iTmp, "created bribe" );
	    	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[BRIBE]"COL_WHITE" You have created a bribe taking place of ID: %d.", iTmp );
	    }
		else SendClientMessage( playerid, -1, ""COL_PINK"[BRIBE]"COL_WHITE" Unable to create a bribe due to a unexpected error." );
	}
	return 1;
}

CMD:destroybribe( playerid, params[ ] )
{
	new
	    bID
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", bID ) ) return SendUsage( playerid, "/destroybribe [BRIBE_ID]" );
	else if ( bID < 0 || bID > MAX_BRIBES ) return SendError( playerid, "Invalid Bribe ID." );
	else if ( !Iter_Contains( BribeCount, bID ) ) return SendError( playerid, "Invalid Bribe ID." );
	else
	{
		SaveToAdminLog( playerid, bID, "destroyed bribe" );
		AddAdminLogLineFormatted( "%s(%d) has deleted a bribe", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_PINK"[BRIBE]"COL_WHITE" You have destroyed a bribe pickup which was the ID of %d.", bID);
	    DestroyBribe( bID );
	}
	return 1;
}

CMD:createcar( playerid, params[ ] )
{
    new
		vName[ 24 ], pID,
		Float: X, Float: Y, Float: Z, Float: Angle
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "us[24]", pID, vName ) ) return SendUsage( playerid, "/createcar [PLAYER_ID] [VEHICLE_NAME]" );
	else if ( !IsPlayerConnected( pID ) ) SendError( playerid, "Invalid Player ID." );
	else if ( p_OwnedVehicles[ pID ] >= GetPlayerVehicleSlots( pID ) ) return SendError( playerid, "This player has too many vehicles." );
	else
	{
	    new
	    	iModel, iTmp;

	    if ( ( iModel = GetVehicleModelFromName( vName ) ) != -1 ) {

			AddAdminLogLineFormatted( "%s(%d) has created a vehicle for %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
			GetPlayerPos( playerid, X, Y, Z );
			GetPlayerFacingAngle( playerid, Angle );

		    if ( ( iTmp = CreateBuyableVehicle( pID, iModel, 0, 0, X, Y, Z, Angle, 1337 ) ) != -1 ) {
				SaveToAdminLogFormatted( playerid, iTmp, "created car (model id %d) for %s (acc id %d)", iModel, ReturnPlayerName( pID ), p_AccountID[ pID ] );
		    	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[VEHICLE]"COL_WHITE" You have created a vehicle in the name of %s(%d).", ReturnPlayerName( pID ), pID );
		    	PutPlayerInVehicle( playerid, g_vehicleData[ pID ] [ iTmp ] [ E_VEHICLE_ID ], 0 );
		    }
			else SendClientMessage( playerid, -1, ""COL_PINK"[VEHICLE]"COL_WHITE" Unable to create a vehicle due to a unexpected error." );
	    }
		else SendError( playerid, "Invalid Vehicle Model." );
	}
	return 1;
}

CMD:destroycar( playerid, params[ ] )
{
	new
	   	ownerid, slotid
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You must be in a vehicle to use this command." );
	else
	{
		new v = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid, slotid );

		if ( v == -1 ) return SendError( playerid, "This vehicle doesn't look like it can be destroyed. (0xAA)" );
		if ( g_vehicleData[ ownerid ] [ slotid ] [ E_CREATED ] == false ) return SendError( playerid, "This vehicle doesn't look like it can be destroyed. (0xAF)" );

		SaveToAdminLogFormatted( playerid, slotid, "destroycar (model id %d) for %s (acc id %d)", g_vehicleData[ slotid ] [ slotid ] [ E_MODEL ], ReturnPlayerName( ownerid ), p_AccountID[ ownerid ] );
		AddAdminLogLineFormatted( "%s(%d) has deleted a car", ReturnPlayerName( playerid ), playerid );
		format( szBigString, sizeof( szBigString ), "[DC] [%s] %s | %s | %s\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), ReturnPlayerName( ownerid ), GetVehicleName( GetVehicleModel( g_vehicleData[ ownerid ] [ slotid ] [ E_VEHICLE_ID ] ) ) );
        AddFileLogLine( "log_destroycar.txt", szBigString );

		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[VEHICLE]"COL_WHITE" You have destroyed a "COL_GREY"%s"COL_WHITE" owned by "COL_GREY"%s"COL_WHITE".", GetVehicleName( GetVehicleModel( g_vehicleData[ ownerid ] [ slotid ] [ E_VEHICLE_ID ] ) ), ReturnPlayerName( ownerid ) );
	   	DestroyBuyableVehicle( ownerid, slotid );
	}
	return 1;
}

CMD:stripcarmods( playerid, params[ ] )
{
	new
	   	ownerid, slotid
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You must be in a vehicle to use this command." );
	else
	{
		new v = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid, slotid );

		if ( v == -1 ) return SendError( playerid, "This vehicle doesn't look like it can be stripped of its components. (0xAA)" );
		if ( g_vehicleData[ ownerid ] [ slotid ] [ E_CREATED ] == false ) return SendError( playerid, "This vehicle doesn't look like it can be destroyed. (0xAF)" );

		SaveToAdminLogFormatted( playerid, slotid, "stripcarmods on %s (acc id %d, model id %d)", ReturnPlayerName( ownerid ), p_AccountID[ ownerid ], g_vehicleData[ ownerid ] [ slotid ] [ E_MODEL ] );
		AddAdminLogLineFormatted( "%s(%d) has deleted a car's mods", ReturnPlayerName( playerid ), playerid );
		format( szBigString, sizeof( szBigString ), "[DC_MODS] [%s] %s | %s | %s\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), ReturnPlayerName( ownerid ), GetVehicleName( GetVehicleModel( g_vehicleData[ ownerid ] [ slotid ] [ E_VEHICLE_ID ] ) ) );
        AddFileLogLine( "log_destroycar.txt", szBigString );

		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[VEHICLE]"COL_WHITE" You have removed the mods of %s's "COL_GREY"%s"COL_WHITE".", ReturnPlayerName( ownerid ), GetVehicleName( GetVehicleModel( g_vehicleData[ ownerid ] [ slotid ] [ E_VEHICLE_ID ] ) ) );
		DestroyVehicleCustomComponents( ownerid, slotid, .destroy_db = true );
	}
	return 1;
}

CMD:createhouse( playerid, params[ ] )
{
    new
		cost, iTmp,
		Float: X, Float: Y, Float: Z
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", cost ) ) return SendUsage( playerid, "/createhouse [COST]" );
	else if ( cost < 100 ) return SendError( playerid, "The price must be located above 100 dollars." );
	else
	{
		AddAdminLogLineFormatted( "%s(%d) has created a house", ReturnPlayerName( playerid ), playerid );
		if ( GetPlayerPos( playerid, X, Y, Z ) )
		{
		    if ( ( iTmp = CreateHouse( "Home", cost, X, Y, Z ) ) != -1 )
		    {
				SaveToAdminLogFormatted( playerid, iTmp, "created house for %s", cash_format( cost ) );
		    	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[HOUSE]"COL_WHITE" You have created a %s house taking up house id %d.", cash_format( cost ), iTmp );
		    }
			else SendClientMessage( playerid, -1, ""COL_PINK"[HOUSE]"COL_WHITE" Unable to create a house due to a unexpected error." );
		}
	}
	return 1;
}

CMD:destroyhouse( playerid, params[ ] )
{
	new
	    hID
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", hID ) ) return SendUsage( playerid, "/destroyhouse [HOUSE_ID]" );
	else if ( hID < 0 || hID > MAX_HOUSES ) return SendError( playerid, "Invalid house ID." );
	else if ( ! Iter_Contains( houses, hID ) ) return SendError( playerid, "Invalid house ID." );
	else
	{
		SaveToAdminLog( playerid, hID, "destroy house" );
		format( szBigString, sizeof( szBigString ), "[DH] [%s] %s | %s | %d\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), g_houseData[ hID ][ E_OWNER ], hID );
	    AddFileLogLine( "log_houses.txt", szBigString );
		AddAdminLogLineFormatted( "%s(%d) has deleted a house", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_PINK"[HOUSE]"COL_WHITE" You have destroyed \"%s\" which was the ID of %d.", g_houseData[ hID ] [ E_HOUSE_NAME ], hID );
	    DestroyHouse( hID );
	}
	return 1;
}

CMD:hadminsell( playerid, params[ ] )
{
	new
	    hID
	;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", hID ) ) return SendUsage( playerid, "/hadminsell [HOUSE_ID]" );
	else if ( hID < 0 || hID > MAX_HOUSES ) return SendError( playerid, "Invalid house ID." );
	else if ( ! Iter_Contains( houses, hID ) ) return SendError( playerid, "Invalid house ID." );
	else if ( strmatch( g_houseData[ hID ] [ E_OWNER ], "No-one" ) ) return SendError( playerid, "This house is not owned by anyone." );
	else
	{
	    SetHouseForAuction( hID );
		SaveToAdminLog( playerid, hID, "hadminsell" );
		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[HOUSE]"COL_WHITE" You made "COL_GREY"House ID %d"COL_WHITE" go for sale.", hID );
	}
	return 1;
}

CMD:forceac( playerid, params[ ] )
{
    new
        pID;

	if ( p_AdminLevel[ playerid ] < 5 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, "u", pID ) ) SendUsage( playerid, "/forceac [PLAYER_ID]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cant use this command on yourself." );
    else if ( p_AdminLevel[ pID ] > p_AdminLevel[ playerid ] ) return SendError( playerid, "You cannot use this command on admins higher than your level." );
    //else if ( GetPlayerScore( pID ) < 100 ) return SendError( playerid, "This player's score is under 100, please spectate instead." );
    else
	{
		if ( p_forcedAnticheat[ pID ] <= 0 )
		{
			p_forcedAnticheat[ pID ] = p_AccountID[ playerid ];
			mysql_single_query( sprintf( "UPDATE `USERS` SET `FORCE_AC`=%d WHERE `ID`=%d", p_AccountID[ playerid ], p_AccountID[ pID ] ) );
			AddAdminLogLineFormatted( "%s(%d) has forced ac on %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	        SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s is required to use an anticheat to play by %s. "COL_YELLOW"("AC_WEBSITE")", ReturnPlayerName( pID ), ReturnPlayerName( playerid ) );
	        if ( ! IsPlayerUsingSampAC( pID ) ) KickPlayerTimed( pID );
		}
		else
		{
			p_forcedAnticheat[ pID ] = 0;
			mysql_single_query( sprintf( "UPDATE `USERS` SET `FORCE_AC`=0 WHERE `ID`=%d", p_AccountID[ pID ] ) );
			AddAdminLogLineFormatted( "%s(%d) has removed forced ac on %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	        SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s has removed the anticheat requirement on %s.", ReturnPlayerName( playerid ), ReturnPlayerName( pID ) );
		}
    }
    return 1;
}
