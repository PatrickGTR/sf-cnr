/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr/commands/admin/admin_two.pwn
 * Purpose: level two administrator commands (cnr)
 */

/* ** Commands ** */
CMD:slay( playerid, params[ ] )
{
	new
		pID
	;
	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/slay [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "This player is not logged in." );
	else
	{
		SetPlayerHealth( pID, -1 );
		AddAdminLogLineFormatted( "%s(%d) has slain %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have slain %s(%d)!", ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( pID, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have been slain by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

CMD:viewnotes( playerid, params[ ] )
{
	new
		pID
	;

	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/viewnotes [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		format( szNormalString, 96, "SELECT `ID`,`TIME`,`NOTE`,`DELETED` FROM `NOTES` WHERE `USER_ID`=%d AND DELETED IS NULL", p_AccountID[ pID ] );
		mysql_function_query( dbHandle, szNormalString, true, "readplayernotes", "d", playerid );
	}
	return 1;
}

CMD:suspend( playerid, params [ ] )
{
    new
	    pID,
		reason[ 50 ],
		hours, days
	;
	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "uddS(No Reason)[50]", pID, hours, days, reason ) ) SendUsage( playerid, "/suspend [PLAYER_ID] [HOURS] [DAYS] [REASON]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( hours < 0 || hours > 24 ) return SendError( playerid, "Please specify an hour between 0 and 24." );
	else if ( days < 0 || days > 60 ) return SendError( playerid, "Please specifiy the amount of days between 0 and 60." );
	else if ( days == 0 && hours == 0 ) return SendError( playerid, "Invalid time specified." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot suspend yourself." );
    else if ( p_AdminLevel[ playerid ] < p_AdminLevel[ pID ] ) return SendError( playerid, "This player has a higher administration level than you." );
	else
	{
		adhereBanCodes( reason );
        AddAdminLogLineFormatted( "%s(%d) has suspended %s(%d) for %d h %d d", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, hours, days );
	    SendGlobalMessage( -1, ""COL_PINK"[ADMIN]{FFFFFF} %s has suspended %s(%d) for %d hour(s) and %d day(s) "COL_GREEN"[REASON: %s]", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), pID, hours, days, reason );
		//GetPlayerIp( pID, ip, sizeof( ip ) );
		new time = g_iTime + ( hours * 3600 ) + ( days * 86400 );
		AdvancedBan( pID, ReturnPlayerName( playerid ), reason, ReturnPlayerIP( pID ), time );
	}
	return 1;
}

CMD:arenas( playerid, params[ ] )
{
	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    ShowPlayerDialog( playerid, DIALOG_ARENAS, DIALOG_STYLE_LIST, "{FFFFFF}Arena Selection", "Warehouse 1\nWarehouse 2\nBloodbowl\n8-Track\nRC Battlefield\nBar\nCrack Factory\nLiberty City Inside\nLV Warehouse\nKickstart\nDirt Track\nDodge The Plane", "Select", "Cancel" );
	return 1;
}

CMD:explode( playerid, params[ ] )
{
    new pID, Float: offset;
	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if (sscanf( params, "uF(0.0)", pID, offset)) SendUsage(playerid, "/explode [PLAYER_ID] [VEHICLE OFFSET (= 0.0)]");
    else if ( !IsPlayerConnected(pID) ) return SendError(playerid, "Invalid Player ID.");
    else if ( p_AdminLevel[ pID ] > p_AdminLevel[ playerid ] ) return SendError(playerid, "You cannot use this command on admins higher than your level.");
    else {
        new Float: X, Float: Y, Float: Z;
        GetPlayerPos( pID, X, Y, Z );
		AddAdminLogLineFormatted( "%s(%d) has exploded %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have exploded %s(%d)", ReturnPlayerName( pID ), pID );

        if ( IsPlayerInAnyVehicle( pID ) )
        {
        	new Float: Angle;
        	GetVehicleZAngle( GetPlayerVehicleID( pID ), Angle );
		    X += ( offset * floatsin( -Angle, degrees ) );
		    Y += ( offset * floatcos( -Angle, degrees ) );
        }

        CreateExplosion( X, Y, Z, 12, 10.0 );
    }
    return 1;
}

CMD:vrespawn( playerid, params[ ] )
{
	new
		vID
	;

	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", vID ) )
	{
		if ( ( vID = GetPlayerVehicleID( playerid ) ) != 0 ) {
			SetVehicleToRespawn( vID );
			return SendServerMessage( playerid, "You have respawned your vehicle." );
		}
		return SendUsage( playerid, "/vrespawn [VEHICLE_ID]" );
	}
	else if ( !IsValidVehicle( vID ) ) return SendError( playerid, "Invalid Vehicle ID" );
#if defined __cnr__chuffsec
	else if ( IsVehicleSecurityVehicle( vID ) ) return SendError( playerid, "This vehicle is prohibited." );
#endif
	else
	{
	    SetVehicleToRespawn( vID );
		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have set the vehicle ID %d to respawn.", vID );
	}
	return 1;
}

CMD:vdestroy( playerid, params[ ] )
{
	new
		vID
	;

	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", vID ) )
	{
		if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_USEJETPACK )
		{
			SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
			return SendServerMessage( playerid, "You have destroyed the jetpack you were using." );
		}

		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You're not in any vehicle." );
		vID = GetPlayerVehicleID( playerid );
		if ( IsBuyableVehicle( vID ) ) return SendError( playerid, "You cannot use this command to destroy buyable vehicles." );
	#if defined __cnr__chuffsec
		if ( IsVehicleSecurityVehicle( vID ) ) return SendError( playerid, "This vehicle is prohibited." );
	#endif
		if ( g_TrolleyVehicles[ 0 ] == vID || g_TrolleyVehicles[ 1 ] == vID || g_TrolleyVehicles[ 2 ] == vID || g_TrolleyVehicles[ 3 ] == vID || g_TrolleyVehicles[ 4 ] == vID ) return SendError( playerid, "This vehicle is prohibited." );
	    DestroyVehicle( vID );
	    if ( g_adminSpawnedCar{ vID } ) g_adminSpawnedCar{ vID } = false;
		SendClientMessage( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have destroyed the vehicle you were using." );
		printf( "[DESTROY VEHICLE] %s has destroyed a %d (id %d) - ADMIN: %s", ReturnPlayerName( playerid ), GetVehicleModel( vID ), vID, g_adminSpawnedCar{ vID } == true ? ( "true" ) : ( "false" ) );
	}
	else if ( !IsValidVehicle( vID ) ) return SendError( playerid, "Invalid Vehicle ID" );
	else if ( IsBuyableVehicle( vID ) ) return SendError( playerid, "You cannot use this command to destroy buyable vehicles." );
#if defined __cnr__chuffsec
	else if ( IsVehicleSecurityVehicle( vID ) ) return SendError( playerid, "This vehicle is prohibited." );
#endif
	else if ( g_TrolleyVehicles[ 0 ] == vID || g_TrolleyVehicles[ 1 ] == vID || g_TrolleyVehicles[ 2 ] == vID || g_TrolleyVehicles[ 3 ] == vID || g_TrolleyVehicles[ 4 ] == vID ) return SendError( playerid, "This vehicle is prohibited." );
	else
	{
		DestroyVehicle( vID );
		if ( g_adminSpawnedCar{ vID } ) g_adminSpawnedCar{ vID } = false;
		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have destroyed the vehicle ID %d.", vID );
	    printf( "[DESTROY VEHICLE] %s has destroyed a %d (id %d) - ADMIN: %s", ReturnPlayerName( playerid ), GetVehicleModel( vID ), vID, g_adminSpawnedCar{ vID } == true ? ( "true" ) : ( "false" ) );
	}
	return 1;
}

CMD:mute( playerid, params[ ] )
{
    new pID, seconds, reason[ 32 ];

	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, "udS(No Reason)[32]", pID, seconds, reason ) ) return SendUsage(playerid, "/mute [PLAYER_ID] [SECONDS] [REASON]");
    else if ( !IsPlayerConnected( pID ) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError(playerid, "You cannot mute yourself.");
   	else if ( p_AdminLevel[ pID ] > p_AdminLevel[ playerid ] ) return SendError(playerid, "You cannot use this command on admins higher than your level.");
    else if ( seconds < 0 || seconds > 10000000 ) return SendError( playerid, "Specify the amount of seconds from 1 - 10000000." );
    else
	{
		if ( p_AdminCommandPause[ pID ] > g_iTime )
			return SendError( playerid, "You must wait %d seconds before using this admin command on the player.", p_AdminCommandPause[ pID ] - g_iTime );

		p_AdminCommandPause[ pID ] = g_iTime + ADMIN_COMMAND_TIME;
		AddAdminLogLineFormatted( "%s(%d) has muted %s(%d) for %d seconds", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, seconds );
        SendGlobalMessage( -1, ""COL_PINK"[ADMIN]{FFFFFF} %s has been muted by %s for %d seconds "COL_GREEN"[REASON: %s]", ReturnPlayerName( pID ), ReturnPlayerName( playerid ), seconds, reason );
		GameTextForPlayer( pID, "~r~Muted!", 4000, 4 );
        p_Muted{ pID } = true;
        p_MutedTime[ pID ] = g_iTime + seconds;
    }
    return 1;
}

CMD:unmute( playerid, params[ ] )
{
    new pID;

	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, "u", pID )) SendUsage(playerid, "/mute [PLAYER_ID]");
    else if ( !IsPlayerConnected( pID ) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError( playerid, "You cannot un-mute yourself." );
    else if ( !p_Muted{ pID } ) return SendError( playerid, "This player isn't muted" );
    else
	{
		AddAdminLogLineFormatted( "%s(%d) has un-muted %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendGlobalMessage( -1, ""COL_PINK"[ADMIN]{FFFFFF} %s has been un-muted by %s.", ReturnPlayerName(pID), ReturnPlayerName( playerid ));
		GameTextForPlayer( pID, "~g~Un-Muted!", 4000, 4 );
        p_Muted{ pID } = false;
        p_MutedTime[ pID ] = 0;
    }
    return 1;
}

CMD:kick( playerid, params[ ] )
{
    new
        pID,
        reason[ 70 ]
	;

	if ( p_AdminLevel[ playerid ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, "uS(No reason)[70]", pID, reason ) ) SendUsage( playerid, "/kick [PLAYER_ID] [REASON]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cant kick yourself." );
    else if ( p_AdminLevel[ pID ] > p_AdminLevel[ playerid ] ) return SendError( playerid, "You cannot use this command on admins higher than your level." );
    else
	{
		adhereBanCodes( reason );
		AddAdminLogLineFormatted( "%s(%d) has kicked %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendGlobalMessage( -1, ""COL_PINK"[ADMIN]{FFFFFF} %s has been kicked by %s. "COL_GREEN"[REASON: %s]", ReturnPlayerName(pID), ReturnPlayerName( playerid ), reason);
        KickPlayerTimed( pID );
    }
    return 1;
}
