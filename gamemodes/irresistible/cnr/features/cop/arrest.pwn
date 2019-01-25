/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\arrest.pwn
 * Purpose: taze, cuff and arresting system for police
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	bool: p_AwaitingBCAttempt		[ MAX_PLAYERS char ],
	p_AwaitingBCAttemptTimer		[ MAX_PLAYERS ] = { -1, ... }
;

/* ** Forwards ** */
forward OnPlayerArrested( playerid, victimid, totalarrests, totalpeople );

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_AwaitingBCAttempt{ playerid } = false;
	KillTimer( p_AwaitingBCAttemptTimer[ playerid ] );
	p_AwaitingBCAttemptTimer[ playerid ] = -1;

	// Quit to Avoid - Award Handling
	AwardNearestLEO( playerid, 0 );
	return 1;
}

hook OnPlayerSpawn( playerid )
{
	p_AwaitingBCAttempt{ playerid } = false;
	KillTimer( p_AwaitingBCAttemptTimer[ playerid ] );
	p_AwaitingBCAttemptTimer[ playerid ] = -1;
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	KillTimer( p_AwaitingBCAttemptTimer[ playerid ] );
	p_AwaitingBCAttemptTimer[ playerid ] = -1;
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_LOOK_BEHIND ) ) // MMB to taze/cuff/ar
	{
		if ( p_Class[ playerid ] == CLASS_POLICE && ! IsPlayerSpawnProtected( playerid ) )
		{
			new
				closestid = GetClosestPlayer( playerid );

			if ( closestid != INVALID_PLAYER_ID && p_Class[ closestid ] != CLASS_POLICE && ! ( GetDistanceBetweenPlayers( playerid, closestid ) > 10.0 || !IsPlayerConnected( closestid ) ) ) {
				if ( GetPlayerWantedLevel( closestid ) > 5 ) {
					if ( IsPlayerCuffed( closestid ) ) ArrestPlayer( closestid, playerid );
					else if ( IsPlayerTazed( closestid ) ) CuffPlayer( closestid, playerid );
					else TazePlayer( closestid, playerid );
				} else {
					TicketPlayer( closestid, playerid );
				}
			}
		}
	}
	return 1;
}

/*hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	// Detain Mechanism
	if ( bDropoff )
	{
	    if ( p_Class[ playerid ] != CLASS_POLICE )
	    	return 1;

	    new
	    	iState = GetPlayerState( playerid ),
	    	iVehicle = GetPlayerVehicleID( playerid )
	    ;

	    if ( iState == PLAYER_STATE_DRIVER && iVehicle != 0 )
	    {
	    	new
	    		iDetained = 0, iCashEarned = 0;

	    	foreach(new victimid : Player)
	    	{
	    		if ( victimid != playerid && p_WantedLevel[ victimid ] && p_Class[ victimid ] != CLASS_POLICE )
	    		{
	    			if ( IsPlayerInVehicle( victimid, iVehicle ) && IsPlayerDetained( victimid ) )
	    			{
						new
							totalSeconds = p_WantedLevel[ victimid ] * ( JAIL_SECONDS_MULTIPLIER );

						iDetained++;
						iCashEarned += ( p_WantedLevel[ victimid ] < MAX_WANTED_LVL ? p_WantedLevel[ victimid ] : MAX_WANTED_LVL ) * ( 350 );
						KillTimer( p_CuffAbuseTimer[ victimid ] );
						SetPlayerSpecialAction( victimid, SPECIAL_ACTION_NONE );
			        	RemovePlayerAttachedObject( victimid, 2 );
						TogglePlayerControllable( victimid, 1 );
						p_Cuffed{ victimid } = false;
						GameTextForPlayer( victimid, "~r~Busted!", 4000, 0 );
						ClearAnimations( victimid );
						JailPlayer( victimid, totalSeconds );
						GivePlayerSeasonalXP( victimid, -2 );
						SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has sent %s(%d) to jail for %d seconds!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( victimid ), victimid, totalSeconds );
	    			}
	    		}
	    	}

	    	if ( iDetained )
	    	{
				if ( iCashEarned > 30000 )
					printf("[police dropoff] %s -> %d people - %s", ReturnPlayerName( playerid ), iDetained, cash_format( iCashEarned ) ); // 8hska7082bmahu

				GivePlayerCash( playerid, iCashEarned );
				GivePlayerScore( playerid, iDetained * 2 );
				CallLocalFunction( "OnPlayerArrested", "dddd", playerid, INVALID_PLAYER_ID, p_Arrests[ playerid ], iDetained );
	    		return SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ACHIEVE]{FFFFFF} You have earned "COL_GOLD"%s{FFFFFF} and %d score for dropping off %d criminal(s) to prison.", cash_format( iCashEarned ), iDetained * 2, iDetained );
	    	}
	    	else return SendError( playerid, "There are no detained criminals in your vehicle that can be jailed." );
	    }
	    else return SendError( playerid, "You need a driver of a vehicle with detained criminals to use this." );
	}
	return 1;
}*/

/* ** Commands ** */
CMD:taze( playerid, params[ ] )
{
   	new
   		pID = GetClosestPlayer( playerid );

 	return TazePlayer( pID, playerid );
}

CMD:ar( playerid, params[ ] ) return cmd_arrest(playerid, params);
CMD:arrest( playerid, params[ ] )
{
   	new
   		victimid = GetClosestPlayer( playerid );

	return ArrestPlayer( victimid, playerid );
}

CMD:cuff( playerid, params[ ] )
{
	new
		victimid = GetClosestPlayer( playerid );

	return CuffPlayer( victimid, playerid );
}

CMD:uncuff( playerid, params[ ] )
{
   	new victimid = GetClosestPlayer( playerid );
   	//if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
   	if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
 	    //if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "This player you're close to is in your team." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "This player is innocent!" );
		if ( !IsPlayerCuffed( victimid ) ) return SendError( playerid, "This player is not cuffed." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "This player is in a object-loading state." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		SendClientMessageFormatted( victimid, -1, ""COL_RED"[UNCUFFED]{FFFFFF} You have been uncuffed by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[UNCUFFED]{FFFFFF} You have uncuffed %s(%d)!", ReturnPlayerName( victimid ), victimid );
        ClearAnimations( victimid );
		TogglePlayerControllable( victimid, 1 );
		p_Cuffed{ victimid } = false;
		//p_Detained{ victimid } = false;
		//Delete3DTextLabel( p_DetainedLabel[ victimid ] );
		//p_DetainedLabel[ victimid ] = Text3D: INVALID_3DTEXT_ID;
		//p_DetainedBy[ victimid ] = INVALID_PLAYER_ID;
		KillTimer( p_CuffAbuseTimer[ victimid ] );
        SetPlayerSpecialAction( victimid, SPECIAL_ACTION_NONE );
        RemovePlayerAttachedObject( victimid, 2 );
 	}
 	else return SendError( playerid, "There are no players around to uncuff." );
	return 1;
}

/*CMD:detain( playerid, params[ ] )
{
   	new victimid = GetClosestPlayer( playerid );
  	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
	    if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "This player you're close to is in your team." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "This player is innocent!" );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle " );
		if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "This player is already detained." );
		if ( !IsPlayerCuffed( victimid ) ) return SendError( playerid, "This player is not cuffed." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "This player is in a object-loading state." );
		if ( !IsValidVehicle( p_LastVehicle[ playerid ] ) ) return SendError( playerid, "Your last vehicle is either destroyed or not spawned." );
		if ( PutPlayerInEmptyVehicleSeat( p_LastVehicle[ playerid ], victimid ) == -1 ) return SendError( playerid, "Failed to place the player inside a full of player vehicle." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "You cannot use this command since you are dead." );
		SendClientMessageFormatted( victimid, -1, ""COL_RED"[DETAIN]{FFFFFF} You have been detained by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[DETAIN]{FFFFFF} You have detained %s(%d), he's been put in your last vehicle!", ReturnPlayerName( victimid ), victimid );
		KillTimer( p_CuffAbuseTimer[ victimid ] );
		p_CuffAbuseTimer[ victimid ] = SetTimerEx( "Uncuff", ( 300 * 1000 ), false, "d", victimid );
		p_Detained{ victimid } = true;
		p_Tazed{ victimid } = false;
		p_DetainedBy[ victimid ] = playerid;
		p_TiedAtTimestamp[ victimid ] = g_iTime;
	    Delete3DTextLabel( p_DetainedLabel[ victimid ] );
	    p_DetainedLabel[ victimid ] = Create3DTextLabel( "Detained Criminal", COLOR_BLUE, 0.0, 0.0, 0.0, 15.0, 0 );
	    Attach3DTextLabelToPlayer( p_DetainedLabel[ victimid ], victimid, 0.0, 0.0, 0.6 );
		TogglePlayerControllable( victimid, 0 );
 	}
 	else return SendError( playerid, "There are no players around to detain." );
	return 1;
}*/

/* ** Functions ** */
stock TazePlayer( victimid, playerid )
{
   	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	//else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/taze [PLAYER_ID]" );
	//else if ( victimid == playerid ) return SendError( playerid, "You cannot taze yourself." );
	else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "There are no players around to taze." );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 5.0 && IsPlayerConnected( victimid ) )
 	{
 	    if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "This player is in your team." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "This player is innocent!" );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle " );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( IsPlayerTazed( victimid ) ) return SendError( playerid, "This player is already tazed." );
		//if ( IsPlayerCuffed( victimid ) ) return SendError( playerid, "This player is already cuffed." );
		//if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "This player is already detained." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You are kidnapped, you cannot do this." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You are tied, you cannot do this." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "You cannot use this command on admins that are on duty." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command while in jail." );
		if ( IsPlayerTied( victimid ) ) return SendError( playerid, "Tazing a tied player is pretty useless, though you can use /untie for a harder job!" );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "This player is in a object-loading state." );
		if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "You cannot use this command since you are dead." );
		if ( p_TazingImmunity[ victimid ] > g_iTime ) return SendError( playerid, "You must wait %d seconds before tazing this player.", p_TazingImmunity[ victimid ] - g_iTime );
		if ( random( 101 ) < 90 )
		{
			GameTextForPlayer( victimid, "~n~~r~TAZED!", 2000, 4 );
			GameTextForPlayer( playerid, "~n~~y~~h~/cuff", 2000, 4 );
			SendClientMessageFormatted( victimid, -1, ""COL_RED"[TAZED]{FFFFFF} You have been tazed by %s(%d) for 3 seconds!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[TAZED]{FFFFFF} You have tazed %s(%d) for 3 seconds!", ReturnPlayerName( victimid ), victimid );
	        SetTimerEx( "Untaze", 2000, false, "dd", victimid, 6 ); // previous 3000
			TogglePlayerControllable( victimid, 0 );
			ApplyAnimation( victimid, "CRACK", "crckdeth2", 5.0, 1, 1, 1, 0, 0 );
			p_Tazed{ victimid } = true;
		}
		else
		{
			SendClientMessageFormatted( playerid, -1, ""COL_RED"[TAZE FAIL]{FFFFFF} You have failed to taze %s(%d)!", ReturnPlayerName( victimid ), victimid );
		  	SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[TAZE FAIL]{FFFFFF} %s(%d) has failed to taze you!", ReturnPlayerName( playerid ), playerid );
		}
		p_TazingImmunity[ victimid ] = g_iTime + 6;
		return 1;
 	} else {
		return SendError( playerid, "There are no players around to taze." );
	}
}

stock ArrestPlayer( victimid, playerid )
{
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	//else if ( GetPlayerScore( playerid ) > 200 ) return SendError( playerid, "This feature is no longer available to you. Please use /detain." );
	// else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/ar(rest) [PLAYER_ID]" );
	// else if ( victimid == playerid ) return SendError( playerid, "You cannot arrest yourself." );
	else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "This player is not connected." );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
 	    if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "This player is in your team." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "This player is innocent!" );
		if ( !IsPlayerCuffed( victimid ) ) return SendError( playerid, "This player is not cuffed." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You are kidnapped, you cannot do this." );
		//if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "This player is detained, you cannot arrest them." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You are tied, you cannot do this." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot arrest this person inside a vehicle." );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "You cannot arrest a person that is inside a vehicle." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "You cannot use this command on admins that are on duty." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "You cannot use this command since you are dead." );
		new totalCash = ( p_WantedLevel[ victimid ] < MAX_WANTED_LVL ? p_WantedLevel[ victimid ] : MAX_WANTED_LVL ) * ( 300 );
		new totalSeconds = p_WantedLevel[ victimid ] * ( JAIL_SECONDS_MULTIPLIER );
		GivePlayerScore( playerid, 2 );
		GivePlayerExperience( playerid, E_POLICE );
		GivePlayerCash( playerid, totalCash );
		StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, totalCash, 0.1 );
		if ( totalCash > 20000 ) printf("[police arrest] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( victimid ), cash_format( totalCash ) ); // 8hska7082bmahu
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ACHIEVE]{FFFFFF} You have earned "COL_GOLD"%s{FFFFFF} dollars and 2 score for arresting %s(%d)!", cash_format( totalCash ), ReturnPlayerName( victimid ), victimid );
		GameTextForPlayer( victimid, "~r~Busted!", 4000, 0 );
		CallLocalFunction( "OnPlayerArrested", "dddd", playerid, victimid, p_Arrests[ playerid ], 1 );
		Untaze( victimid, 6 );
		GivePlayerSeasonalXP( victimid, -20.0 );
		SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has sent %s(%d) to jail for %d seconds!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( victimid ), victimid, totalSeconds );
		JailPlayer( victimid, totalSeconds );
		KillTimer( p_AwaitingBCAttemptTimer[ victimid ] );
		return 1;
 	}
 	else return SendError( playerid, "There are no players around to arrest." );
}

stock AwardArrest( victimid, playerid )
{
	p_QuitToAvoidTimestamp[ playerid ] = 0;
	new totalCash = ( p_WantedLevel[ victimid ] < MAX_WANTED_LVL ? p_WantedLevel[ victimid ] : MAX_WANTED_LVL ) * ( 300 );
	new totalSeconds = p_WantedLevel[ victimid ] * ( JAIL_SECONDS_MULTIPLIER );
	GivePlayerScore( playerid, 2 );
	GivePlayerExperience( playerid, E_POLICE );
	GivePlayerCash( playerid, totalCash );
	StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, totalCash, 0.1 );
	if ( totalCash > 20000 ) printf("[police arrest] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( victimid ), cash_format( totalCash ) ); // 8hska7082bmahu
	SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ACHIEVE]{FFFFFF} You have earned "COL_GOLD"%s{FFFFFF} dollars and 2 score for arresting %s(%d)!", cash_format( totalCash ), ReturnPlayerName( victimid ), victimid );
	GameTextForPlayer( victimid, "~r~Busted!", 4000, 0 );
	CallLocalFunction( "OnPlayerArrested", "dddd", playerid, victimid, p_Arrests[ playerid ], 1 );
	GivePlayerSeasonalXP( victimid, -20.0 );
	JailPlayer( victimid, totalSeconds );
	return 1;
}

stock CuffPlayer( victimid, playerid )
{
   	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	//else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/cuff [PLAYER_ID]" );
	//else if ( victimid == playerid ) return SendError( playerid, "You cannot cuff yourself." );
	else if ( !IsPlayerConnected( victimid ) || IsPlayerNPC( victimid ) ) return SendError( playerid, "This player is not connected." );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
 	    if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "This player is in your team." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "This player is innocent!" );
		if ( p_WantedLevel[ victimid ] < 6 ) return SendError( playerid, "This person isn't worth cuffing, ticket them." );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle " );
		//if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "This player is already detained." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( IsPlayerCuffed( victimid ) ) return SendError( playerid, "This player is already cuffed." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( !IsPlayerTazed( victimid ) ) return SendError( playerid, "You must taze this player before cuffing them." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You are kidnapped, you cannot do this." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You are tied, you cannot do this." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "You cannot use this command on admins that are on duty." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "This player is in a object-loading state." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "You cannot use this command since you are dead." );
		if ( !IsPlayerSpawned( victimid ) ) return SendError( playerid, "The player must be spawned." );

		if ( !BreakPlayerCuffs( victimid ) )
		{
			GameTextForPlayer( victimid, "~n~~r~CUFFED!", 2000, 4 );
			GameTextForPlayer( playerid, "~n~~y~~h~/arrest", 2000, 4 );

			SendClientMessageFormatted( victimid, -1, ""COL_RED"[CUFFED]{FFFFFF} You have been cuffed by %s(%d)!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[CUFFED]{FFFFFF} You have cuffed %s(%d)!", ReturnPlayerName( victimid ), victimid );

			p_Cuffed{ victimid } = true;
			p_QuitToAvoidTimestamp[ victimid ] = g_iTime + 3;
			SetPlayerAttachedObject( victimid, 2, 19418, 6, -0.011000, 0.028000, -0.022000, -15.600012, -33.699977, -81.700035, 0.891999, 1.000000, 1.168000 );
	      	SetPlayerSpecialAction( victimid, SPECIAL_ACTION_CUFFED );

			KillTimer( p_CuffAbuseTimer[ victimid ] );
	   		p_CuffAbuseTimer[ victimid ] = SetTimerEx( "Uncuff", ( 60 * 1000 ), false, "d", victimid );

			p_AwaitingBCAttempt{ victimid } = true;

			KillTimer( p_AwaitingBCAttemptTimer[ victimid ] );
			p_AwaitingBCAttemptTimer[ victimid ] = SetTimerEx( "BreakPlayerCuffsAttempt", 3000, false, "d", victimid );
		}
		else
		{
			SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[CUFFED]{FFFFFF} %s(%d) just broke their cuffs off!", ReturnPlayerName( victimid ), victimid );
		}
		return 1;
 	}
 	else return SendError( playerid, "There are no players around to cuff." );
}

function Untaze( playerid, taze_immunity_seconds )
{
	if ( !IsPlayerConnected( playerid ) || !p_Tazed{ playerid } ) // || p_Detained{ playerid } == true
	    return 0;

	if ( ! IsPlayerTied( playerid ) )
		TogglePlayerControllable( playerid, 1 );

	if ( GetPlayerSpecialAction( playerid ) != SPECIAL_ACTION_CUFFED )
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );

	ClearAnimations( playerid );
	p_BulletInvulnerbility[ playerid ] = g_iTime + 3;
	p_TazingImmunity[ playerid ] = g_iTime + taze_immunity_seconds;
	p_Tazed{ playerid } = false;
	return 1;
}

function Uncuff( playerid )
{
	if ( !IsPlayerConnected( playerid ) || !IsPlayerCuffed( playerid ) || !IsPlayerAttachedObjectSlotUsed( playerid, 2 ) )
	    return 0;

	TogglePlayerControllable( playerid, 1 );
 	RemovePlayerAttachedObject( playerid, 2 );
	SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
	if ( !IsPlayerInAnyVehicle( playerid ) ) {
		ClearAnimations( playerid );
	}
	p_Cuffed{ playerid } = false;
	//p_Detained{ playerid } = false;
	//Delete3DTextLabel( p_DetainedLabel[ playerid ] );
	//p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	//p_DetainedBy[ playerid ] = INVALID_PLAYER_ID;
	p_BulletInvulnerbility[ playerid ] = g_iTime + 5;

   	SendGlobalMessage( -1, ""COL_GREY"[SERVER]{FFFFFF} %s(%d) has been uncuffed and undetained by the anti-abuse system.", ReturnPlayerName( playerid ), playerid );
	return 1;
}

stock BreakPlayerCuffs( playerid )
{
	if ( !IsPlayerConnected( playerid ) ) return false;

	if ( p_BobbyPins[ playerid ] < 1 )
	{
		ShowPlayerHelpDialog( playerid, 4000, "You can buy bobby pins at Supa Save or a 24/7 store to break cuffs." );
		return false;
	}
	else p_BobbyPins[ playerid ] --;

	if ( p_AwaitingBCAttempt{ playerid } ) p_AwaitingBCAttempt{ playerid } = false;

	new probability = 75; // success rate probability

	if ( random( 101 ) <= probability )
	{
		if ( ! IsPlayerCuffed( playerid ) )
		{
			Untaze( playerid, 10 );
			GivePlayerWantedLevel( playerid, 6 );
		}
		else
		{
			if ( ! IsPlayerAttachedObjectSlotUsed( playerid, 2 ) )
				return false;

			TogglePlayerControllable( playerid, 1 );
			RemovePlayerAttachedObject( playerid, 2 );
			SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );

			if ( ! IsPlayerInAnyVehicle( playerid ) ) {
				ClearAnimations( playerid );
			}

			p_Cuffed{ playerid } = false;
			p_BulletInvulnerbility[ playerid ] = g_iTime + 5;
		}
		SendServerMessage( playerid, "You have successfully broken out of your cuffs!" );
		return true;
	}
	else
	{
		SendServerMessage( playerid, "You have snapped your bobby pin and failed to break out of your cuffs. Re-attempting in 3 seconds." );
		p_AwaitingBCAttempt{ playerid } = true;
		KillTimer( p_AwaitingBCAttemptTimer[ playerid ] );
		p_AwaitingBCAttemptTimer[ playerid ] = SetTimerEx( "BreakPlayerCuffsAttempt", 3000, false, "d", playerid );
		return false;
	}
}

function BreakPlayerCuffsAttempt( playerid ) return BreakPlayerCuffs( playerid ), 1;

stock AwardNearestLEO( playerid, reason )
{
	new
		Float: x, Float: y, Float: z,
		closestLEO = INVALID_PLAYER_ID,
		radius = ( IsPlayerInAnyVehicle( playerid ) ? 150 : 75 ); // If player is in a vehicle, increase radius due to ability to get farther quicker.

	GetPlayerPos( playerid, x, y, z );

	foreach( new pID : Player )
	{
		if ( p_Class[ pID ] != CLASS_POLICE ) continue;

		new Float: distance = GetDistanceBetweenPlayers( playerid, pID );

		if ( distance < radius && distance < closestLEO )
			closestLEO = pID;
	}

	if ( closestLEO != INVALID_PLAYER_ID )
	{
		new reasonText[ 24 ];

		switch ( reason )
		{
			case 0: reasonText = "Q'ing to Avoid";
			case 1: reasonText = "being AFK while wanted";
		}

		AwardArrest( playerid, closestLEO );
		SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been awarded for the arrest on %s(%d) due to them "COL_LRED"%s.", ReturnPlayerName( closestLEO ), closestLEO, ReturnPlayerName( playerid ), playerid, reasonText );
		return true;
	}

	return false;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( !p_InHouse[ playerid ] && GetPlayerWantedLevel( playerid ) > 2 )
	{
		new Float: x, Float: y, Float: z;

		GetEntrancePos( checkpointid, x, y, z );

		foreach ( new pID : Player )
		{
			if ( p_Class[ pID ] != CLASS_POLICE ) continue;

			new Float: distance = GetPlayerDistanceFromPoint( pID, x, y, z );

			if ( distance < 50 )
			{
				p_QuitToAvoidTimestamp[ playerid ] = g_iTime + 30;
				break;
			}
		}
	}
	return 1;
}