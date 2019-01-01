/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr/commands/admin/admin_four.pwn
 * Purpose: level four administrator commands (cnr)
 */

/* ** Commands ** */
CMD:destroyallav( playerid, params[ ] )
{
    if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else
	{
	    for( new i; i < MAX_VEHICLES; i++ )
	    {
			if ( IsValidVehicle( i ) && g_adminSpawnedCar{ i } == true ) {
			    g_adminSpawnedCar{ i } = false;
				DestroyVehicle( i );
			}
	    }
		SendServerMessage( playerid, "You have succesfully destroyed all admin spawned vehicles." );
		AddAdminLogLineFormatted( "%s(%d) has destroyed all spawned vehicles", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

CMD:event( playerid, params[ ] )
{
 	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	AddAdminLogLineFormatted( "%s(%d) has changed his world to 69", ReturnPlayerName( playerid ), playerid );
	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have your world to 69." );
	return SetPlayerVirtualWorld( playerid, 69 );
}

CMD:setworld( playerid, params[ ] )
{
	new pID, worldid;
 	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
 	else if ( sscanf( params, "ud", pID, worldid ) ) return SendUsage( playerid, "/setworld [PLAYER_ID] [WORLD_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
 	else
 	{
 	    SetPlayerVirtualWorld( pID, worldid );

 	    if ( pID != playerid )
		{
	 	    SendClientMessageFormatted( pID, -1, ""COL_PINK"[ADMIN]"COL_WHITE" Your world has been set to %d by %s(%d)!", worldid, ReturnPlayerName( playerid ), playerid );
	 		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have changed %s(%d)'s world to %d!", ReturnPlayerName( pID ), pID, worldid );
	 		AddAdminLogLineFormatted( "%s(%d) has changed %s(%d)'s world to %d", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, worldid );
		}
		else
		{
			SendClientMessageFormatted( pID, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have set your world to %d.", worldid );
	 		AddAdminLogLineFormatted( "%s(%d) has changed their world to %d", ReturnPlayerName( pID ), pID, worldid );
		}
	}
	return 1;
}

CMD:setinterior( playerid, params[ ] )
{
	new pID, worldid;
 	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
 	else if ( sscanf( params, "ud", pID, worldid ) ) return SendUsage( playerid, "/setinterior [PLAYER_ID] [INTERIOR_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
 	else
 	{
 	    SetPlayerInterior( pID, worldid );

 	    if ( pID != playerid )
		{
	 	    SendClientMessageFormatted( pID, -1, ""COL_PINK"[ADMIN]"COL_WHITE" Your interior has been set to %d by %s(%d)!", worldid, ReturnPlayerName( playerid ), playerid );
	 		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have changed %s(%d)'s interior to %d!", ReturnPlayerName( pID ), pID, worldid );
	 		AddAdminLogLineFormatted( "%s(%d) has changed %s(%d)'s interior to %d", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, worldid );
		}
		else
		{
			SendClientMessageFormatted( pID, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have your interior to %d.", worldid );
	 		AddAdminLogLineFormatted( "%s(%d) has changed his interior to %d", ReturnPlayerName( pID ), pID, worldid );
		}
	}
	return 1;
}

CMD:uncopban( playerid, params [ ] )
{
    new
	    pID
	;
	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "u", pID ) ) SendUsage( playerid, "/uncopban [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( p_CopBanned{ pID } == 0 ) return SendError( playerid, "This player is not cop-banned." );
    else
	{
        AddAdminLogLineFormatted( "%s(%d) has un-cop-banned %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	    SendGlobalMessage( -1, ""COL_PINK"[ADMIN]{FFFFFF} %s has un-cop-banned %s(%d).", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), pID );
		p_CopBanned{ pID } = 0;
		format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `COP_BAN`=0 WHERE ID=%d", p_AccountID[ pID ] ), mysql_single_query( szNormalString );
	}
	return 1;
}

CMD:unarmyban( playerid, params [ ] )
{
    new
	    pID
	;
	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "u", pID ) ) SendUsage( playerid, "/unarmyban [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( p_ArmyBanned{ pID } == 0 ) return SendError( playerid, "This player is not army-banned." );
    else
	{
        AddAdminLogLineFormatted( "%s(%d) has un-army-banned %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	    SendGlobalMessage( -1, ""COL_PINK"[ADMIN]{FFFFFF} %s has un-army-banned %s(%d).", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), pID );
		p_ArmyBanned{ pID } = 0;
		format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `ARMY_BAN`=0 WHERE ID=%d", p_AccountID[ pID ] ), mysql_single_query( szNormalString );
	}
	return 1;
}

CMD:motd( playerid, params[ ] )
{
	new
	    string[ 90 ]
	;
	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "s[90]", string ) ) return SendUsage( playerid, "/motd [MESSAGE]" );
	else
	{
		//strreplacechar	( string, '~', ']' );
        AddAdminLogLineFormatted( "%s(%d) has set the motd", ReturnPlayerName( playerid ), playerid );
	    SendServerMessage( playerid, "The MOTD has been changed." );
		TextDrawSetString( g_MotdTD, string );
	}
	return 1;
}

CMD:resetwepall( playerid, params[ ] )
{
	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else
	{
		new
			iWorld = GetPlayerVirtualWorld( playerid );

		foreach(new pID : Player)
		{
		   	if ( !IsPlayerSpawned( pID ) || IsPlayerSettingToggled( pID, SETTING_EVENT_TP ) )
		   		continue;

		   	if ( IsPlayerAFK( playerid ) )
		   		continue;

		   	if ( iWorld != GetPlayerVirtualWorld( pID ) )
		   		continue;

			ResetPlayerWeapons( pID );
		}

		AddAdminLogLineFormatted( "%s(%d) has reset all player weapons", ReturnPlayerName( playerid ), playerid );
		SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" All player weapons have been reset in %s's world.", ReturnPlayerName( playerid ) );
	}
	return 1;
}

CMD:giveweaponall( playerid, params[ ] )
{
    new
		wep,
		ammo,
		gunname[ 32 ]
	;

	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, "dd", wep, ammo ) ) return SendUsage(playerid, "/giveweaponall [WEAPON_ID] [AMMO]");
    else if ( wep > MAX_WEAPONS || wep <= 0 || wep == 47 ) return SendError(playerid, "Invalid weapon id");
    else if ( IsWeaponBanned( wep ) ) return SendError( playerid, "This weapon is a banned weapon, you cannot spawn this." );
    else
	{
		new
			iWorld = GetPlayerVirtualWorld( playerid );

	    foreach(new pID : Player)
	    {
		   	if ( !IsPlayerSpawned( pID ) || IsPlayerJailed( pID ) || IsPlayerSettingToggled( pID, SETTING_EVENT_TP ) )
		   		continue;

		   	if ( IsPlayerAFK( playerid ) )
		   		continue;

		   	if ( iWorld != 0 && iWorld != GetPlayerVirtualWorld( pID ) )
		   		continue;

			GivePlayerWeapon( pID, wep, ammo );
		}

		GetWeaponName( wep, gunname, sizeof( gunname ) );
        AddAdminLogLineFormatted( "%s(%d) has given everyone a %s", ReturnPlayerName( playerid ), playerid, gunname );
		SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" Everyone has been given a %s in %s(%d)'s world.", gunname, ReturnPlayerName( playerid ), playerid );
    }
    return 1;
}

CMD:circleall( playerid, params[ ] )
{
	new seconds = 3, allowcop, noarmour;
	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, "D(3)D(0)D(1)", seconds, allowcop, noarmour ) ) return SendUsage(playerid, "/circleall [SECONDS] [ALLOW_COPS 0|1] [REMOVE ARMOUR 0|1]" );
    else if ( g_circleall_CD ) return SendError( playerid, "There is already a countdown on-going." );
    else if ( seconds > 60 ) return SendError( playerid, "You must specifiy the amount of seconds from 0 to 60." );
    else if ( allowcop < 0 || allowcop > 1 ) return SendError( playerid, "0 or 1 can only be the cop allowance parameter value!" );
    else if ( noarmour < 0 || noarmour > 1 ) return SendError( playerid, "0 or 1 can only be the remove armour parameter value!" );
    else
	{
		g_circleall_CD = true;

		new
		    Float: nX, Float: nY, Float: nZ,
		    Float: Armour, Float: deg// = 360.0 / float(Iter_Count(Player))
		;
		GetPlayerPos( playerid, nX, nY, nZ );
	    foreach(new i : Player)
	    {
	        if ( IsPlayerSpawned( i ) && i != playerid && !IsPlayerJailed( i ) && ! IsPlayerSettingToggled( i, SETTING_EVENT_TP ) )
	        {
	        	if ( !allowcop && p_Class[ i ] == CLASS_POLICE )
	        		continue;

	        	if ( IsPlayerAFK( i ) ) {
	        		SendServerMessage( i, "As you're AFK, you have not been teleported to the event/mass teleportation." );
	        		continue;
	        	}

	        	if ( IsPlayerInPaintBall( i ) || IsPlayerDueling( i ) ) {
	        		SendServerMessage( i, "As you're in paintball, you have not been teleported to the event/mass teleportation." );
	        		continue;
	        	}

	        	if ( noarmour ) {
	        		GetPlayerArmour( i, Armour );
	        		if ( Armour > 0.0 ) SetPlayerArmour( i, 0.0 );
	        	}

	            deg += 3.6;
	            nX += 10 * floatsin( deg, degrees );
	            nY += 10 * floatcos( deg, degrees );
	            SetPlayerPos( i, nX, nY, nZ );
				GetPlayerPos( playerid, nX, nY, nZ );
				SetPlayerInterior( i, GetPlayerInterior( playerid ) );
				SetPlayerVirtualWorld( i, GetPlayerVirtualWorld( playerid ) );
				TogglePlayerControllable( i, 0 );
	        }
	    }
	    SetTimerEx( "circleall_Countdown", 960, false, "dd", seconds, 0 );
		AddAdminLogLineFormatted( "%s(%d) has circled everybody", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

CMD:vc( playerid, params [ ] ) return cmd_vcreate( playerid, params );
CMD:vcreate( playerid, params [ ] )
{
    new
		vName[ 24 ],
		vCar,
	    Float: X,
	    Float: Y,
	    Float: Z,
	    Float: Angle
	;
	GetPlayerPos( playerid, X, Y, Z );
    GetPlayerFacingAngle(playerid, Angle);

	if ( p_AdminLevel[ playerid ] < 3 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "s[24]", vName ) ) SendUsage( playerid, "/(vc)reate [VEHICLE_NAME]" );
	else
	{
		if ( strmatch( vName, "jetpack" ) && p_AdminLevel[ playerid ] >= 4 )
			return SetPlayerSpecialAction( playerid, SPECIAL_ACTION_USEJETPACK );

	    new iCarModel = GetVehicleModelFromName( vName );
	    if ( p_AdminLevel[ playerid ] < 5 )
	    {
		    if ( iCarModel == 435 || iCarModel == 450 || iCarModel == 584 || iCarModel == 591 || iCarModel == 606 || iCarModel == 607 || iCarModel == 608 || iCarModel == 610 || iCarModel == 611 ) return SendError( playerid, "You cannot spawn trailers." );
			if ( iCarModel == 449 || iCarModel == 537 || iCarModel == 538 || iCarModel == 569 || iCarModel == 570 ) return SendError( playerid, "You cannot spawn trains." );
		}

		if ( iCarModel != -1 ) {
			if ( ( vCar = CreateVehicle( iCarModel, X, Y, Z, Angle, -1, -1, 9999999999999999 ) ) ) {
	            g_adminSpawnedCar{ vCar } = true;
				LinkVehicleToInterior( vCar, GetPlayerInterior( playerid ) );
				SetVehicleVirtualWorld( vCar, GetPlayerVirtualWorld( playerid ) );
				PutPlayerInVehicle( playerid, vCar, 0 );
 				SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have spawned an "COL_GREY"%s"COL_WHITE".", GetVehicleName( iCarModel ) );
			}
		}
		else SendError( playerid, "Invalid vehicle name written." );
	}
	return 1;
}

CMD:gotopos( playerid, params[ ] )
{
	new
		Float: X, Float: Y, Float: Z, interior;

 	if ( p_AdminLevel[ playerid ] < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
 	else if ( sscanf( params, "fffD(0)", X, Y, Z, interior ) ) return SendUsage( playerid, "/gotopos [POS_X] [POS_Y] [POS_Z] [INTERIOR (= 0)]" );
 	else
 	{
		SetPlayerPosition( playerid, X, Y, Z, interior );
 		SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have teleported to "COL_GREY"%f, %f, %f"COL_WHITE" Interior: "COL_GREY"%d", X, Y, Z, interior );
 	}
	return 1;
}
