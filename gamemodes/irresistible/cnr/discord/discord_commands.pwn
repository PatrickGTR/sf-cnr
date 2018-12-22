/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\discord\discord_commands.pwn
 * Purpose: commands that can be used on the discord channel
 */

/* ** Error Checking ** */
#if defined DISCORD_DISABLED
    #endinput
#endif

/* ** Definitions ** */
DQCMD:lastlogged( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleVoice, hasPermission );

	if ( hasPermission )
	{
		static
		    player[ MAX_PLAYER_NAME ];

		if ( sscanf( params, "s[24]", player ) ) return 0;
		else
		{
			format( szNormalString, sizeof( szNormalString ), "SELECT `LASTLOGGED` FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
	  		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerLastLogged", "iis", INVALID_PLAYER_ID, 1, player );
		}
	}
	else DCC_SendUserMessage( user, "**Error:** This command requires voice." );
	return 1;
}

DQCMD:weeklytime( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleVoice, hasPermission );

	if ( hasPermission )
	{
		static
		    player[ MAX_PLAYER_NAME ]
		;

		if ( sscanf( params, "s[24]", player ) ) return 0;
		else
		{
			format( szNormalString, sizeof( szNormalString ), "SELECT `UPTIME`,`WEEKEND_UPTIME` FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
	  		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerWeeklyTime", "iis", INVALID_PLAYER_ID, 1, player );
		}
	}
	else DCC_SendUserMessage( user, "**Error:** This command requires voice." );
	return 1;
}

DQCMD:idof( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleVoice, hasPermission );

	if ( hasPermission )
	{
		new pID;
		if ( sscanf( params, "u", pID ) ) return 0;
		if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return 0;
		format( szNormalString, sizeof( szNormalString ), "**In-game ID of %s:** %d", ReturnPlayerName( pID ), pID );
		DCC_SendChannelMessage( discordGeneralChan, szNormalString );
	}
	else DCC_SendUserMessage( user, "**Error:** This command requires voice." );
	return 1;
}

DQCMD:say( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleVoice, hasPermission );

	if ( hasPermission )
	{
		new
			szAntispam[ 64 ];
		printf("SAY %s", params);
		if ( !isnull( params ) && !textContainsIP( params ) )
		{
			format( szAntispam, 64, "!say_%s", ReturnDiscordName( user ) );
			if ( GetGVarInt( szAntispam ) < g_iTime )
			{
				new
					bool: hasAdmin;

				DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasAdmin );

				if ( hasAdmin )
					SetGVarInt( szAntispam, g_iTime + 2 );

				// send message
				SendClientMessageToAllFormatted( -1, "{4DFF88}(Discord %s) {00CD45}%s:{FFFFFF} %s", discordLevelToString( user ), ReturnDiscordName( user ), params );
				DCC_SendChannelMessageFormatted( discordGeneralChan, "**(Discord %s) %s:** %s", discordLevelToString( user ), ReturnDiscordName( user ), params );
			}
			else DCC_SendUserMessage( user, "You must wait 2 seconds before speaking again." );
		}
	}
	else DCC_SendUserMessage( user, "**Error:** This command requires voice." );
	return 1;
}

DQCMD:players( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleVoice, hasPermission );

	print("Called players");
	if ( hasPermission )
	{
		print("Has permission");
		new
			iPlayers = Iter_Count(Player);

		szLargeString[ 0 ] = '\0';
		if ( iPlayers <= 25 )
		{
			foreach(new i : Player) {
			    if ( IsPlayerConnected( i ) ) {
			        format( szLargeString, sizeof( szLargeString ), "%s%s(%d), ", szLargeString, ReturnPlayerName( i ), i );
			    }
			}
		}
		format( szLargeString, sizeof( szLargeString ), "%sThere are %d player(s) online.", szLargeString, iPlayers );
		DCC_SendChannelMessage( discordGeneralChan, szLargeString );
	}
	else DCC_SendUserMessage( user, "**Error:** This command requires voice." );
	return 1;
}

DQCMD:admins( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleVoice, hasPermission );

	if ( hasPermission )
	{
		new count = 0;
		szBigString[ 0 ] = '\0';

		foreach(new i : Player) {
		    if ( IsPlayerConnected( i ) && p_AdminLevel[ i ] > 0 ) {
		        format( szBigString, sizeof( szBigString ), "%s%s(%d), ", szBigString, ReturnPlayerName( i ), i );
		        count++;
		    }
		}

		format( szBigString, sizeof( szBigString ), "%sThere are %d admin(s) online.", szBigString, count );
		DCC_SendChannelMessage( discordGeneralChan, szBigString );
	}
	else DCC_SendUserMessage( user, "**Error:** This command requires voice." );
	return 1;
}

/* HALF OP */
DQCMD:acmds( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
 		DCC_SendUserMessage( user, 	"__**Lead Admin:**__ !kick, !ban, !suspend, !warn, !jail, !getip, !(un)mute\n"\
 							 		"__**Admin:**__ !unban, !unbanip" );
	}
	return 1;
}

DQCMD:kick( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
		new pID, reason[64];
		if (sscanf( params, "uS(No reason)[64]", pID, reason)) return DCC_SendUserMessage( user, "**Usage:** !kick [PLAYER_ID] [REASON]" );
		if (IsPlayerConnected(pID))
		{
			DCC_SendChannelMessageFormatted( discordAdminChan, "**Command Success:** %s(%d) has been kicked.", ReturnPlayerName( pID ), pID );
		    SendGlobalMessage( -1, ""COL_PINK"[DISCORD ADMIN]{FFFFFF} %s(%d) has been kicked by %s "COL_GREEN"[REASON: %s]", ReturnPlayerName(pID), pID, ReturnDiscordName( user ), reason);
			KickPlayerTimed( pID );
		}
		else DCC_SendUserMessage( user, "**Command Error:** Player is not connected!" );
	}
	return 1;
}

DQCMD:ban( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
		new pID, reason[64];
		if (sscanf( params, "uS(No reason)[64]", pID, reason)) return DCC_SendUserMessage( user, "**Usage:** !ban [PLAYER_ID] [REASON]" );
		if (IsPlayerConnected(pID))
		{
			DCC_SendChannelMessageFormatted( discordAdminChan, "**Command Success:** %s(%d) has been banned.", ReturnPlayerName( pID ), pID );
		    SendGlobalMessage( -1, ""COL_PINK"[DISCORD ADMIN]{FFFFFF} %s has banned %s(%d) "COL_GREEN"[REASON: %s]", ReturnDiscordName( user ), ReturnPlayerName( pID ), pID, reason );
			AdvancedBan( pID, "Discord Administrator", reason, ReturnPlayerIP( pID ) );
		}
		else DCC_SendUserMessage( user, "**Command Error:** Player is not connected!" );
	}
	return 1;
}

DQCMD:suspend( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
		new pID, reason[50], hours, days;
		if ( sscanf( params, "uddS(No Reason)[50]", pID, hours, days, reason ) ) return DCC_SendUserMessage( user, "**Usage:** !suspend [PLAYER_ID] [HOURS] [DAYS] [REASON]" );
		if ( hours < 0 || hours > 24 ) return DCC_SendUserMessage( user, "**Command Error:** Please specify an hour between 0 and 24." );
		if ( days < 0 || days > 60 ) return DCC_SendUserMessage( user, "**Command Error:** Please specifiy the amount of days between 0 and 60." );
		if ( days == 0 && hours == 0 ) return DCC_SendUserMessage( user, "**Command Error:** Invalid time specified." );
		if ( IsPlayerConnected( pID ) )
		{
			DCC_SendChannelMessageFormatted( discordAdminChan, "**Command Success:** %s(%d) has been suspended for %d hour(s) and %d day(s).", ReturnPlayerName( pID ), pID, hours, days );
			SendGlobalMessage( -1, ""COL_PINK"[DISCORD ADMIN]{FFFFFF} %s has suspended %s(%d) for %d hour(s) and %d day(s) "COL_GREEN"[REASON: %s]", ReturnDiscordName( user ), ReturnPlayerName( pID ), pID, hours, days, reason );
			new time = g_iTime + ( hours * 3600 ) + ( days * 86400 );
			AdvancedBan( pID, "Discord Administrator", reason, ReturnPlayerIP( pID ), time );
		}
		else DCC_SendUserMessage( user, "**Command Error:** Player is not connected!" );
	}
	return 1;
}

DQCMD:warn( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
		new pID, reason[50];
		if ( sscanf( params, "uS(No Reason)[32]", pID, reason ) ) return DCC_SendUserMessage( user, "**Usage:** !warn [PLAYER_ID] [REASON]" );
		if ( IsPlayerConnected( pID ) )
		{
	    	p_Warns[ pID ] ++;
			DCC_SendChannelMessageFormatted( discordAdminChan, "**Command Success:** %s(%d) has been warned [%d/3].", ReturnPlayerName( pID ), pID, p_Warns[ pID ] );
        	SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" %s(%d) has been warned by %s "COL_GREEN"[REASON: %s]", ReturnPlayerName( pID ), pID, ReturnDiscordName( user ), reason );

			if ( p_Warns[ pID ] >= 3 )
		    {
		        p_Warns[ pID ] = 0;
		        SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" %s(%d) has been kicked from the server. "COL_GREEN"[REASON: Excessive Warns]", ReturnPlayerName( pID ), pID );
		        KickPlayerTimed( pID );
		        return 1;
		    }
		}
		else DCC_SendUserMessage( user, "**Command Error:** Player is not connected!" );
	}
	return 1;
}

DQCMD:jail( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
		new pID, reason[50], Seconds;
		if ( sscanf( params, "udS(No Reason)[32]", pID, Seconds, reason ) ) return DCC_SendUserMessage( user, "**Usage:** !jail [PLAYER_ID] [SECONDS] [REASON]" );
		if ( Seconds > 20000 || Seconds < 1 ) return DCC_SendUserMessage( user, "**Command Error:** You're misleading the seconds limit! ( 0 - 20000 )");
		if ( IsPlayerConnected( pID ) )
		{
			DCC_SendChannelMessageFormatted( discordAdminChan, "**Command Success:** %s(%d) has been jailed for %d seconds.", ReturnPlayerName( pID ), pID, Seconds );
	    	SendGlobalMessage( -1, ""COL_GOLD"[DISCORD JAIL]{FFFFFF} %s(%d) has been sent to jail for %d seconds by %s "COL_GREEN"[REASON: %s]", ReturnPlayerName( pID ), pID, Seconds, ReturnDiscordName( user ), reason );
        	JailPlayer( pID, Seconds, 1 );
		}
		else DCC_SendUserMessage( user, "**Command Error:** Player is not connected!" );
	}
	return 1;
}

DQCMD:mute( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
	    new pID, seconds, reason[ 32 ];

		if ( sscanf( params, "udS(No Reason)[32]", pID, seconds, reason ) ) return DCC_SendUserMessage( user, "**Usage:** !amute [PLAYER_ID] [SECONDS] [REASON]");
	    else if ( !IsPlayerConnected( pID ) ) DCC_SendUserMessage( user, "**Command Error:** Invalid Player ID.");
		else if ( p_AdminLevel[ pID ] > 4 ) return DCC_SendUserMessage( user, "**Command Error:** No sexy head admin targetting!");
	    else if ( seconds < 0 || seconds > 10000000 ) return DCC_SendUserMessage( user, "**Command Error:** Specify the amount of seconds from 1 - 10000000." );
	    else
		{
	        SendGlobalMessage( -1, ""COL_PINK"[DISCORD ADMIN]{FFFFFF} %s has been muted by %s for %d seconds "COL_GREEN"[REASON: %s]", ReturnPlayerName( pID ), ReturnDiscordName( user ), seconds, reason );
			GameTextForPlayer( pID, "~r~Muted!", 4000, 4 );
	        p_Muted{ pID } = true;
	        p_MutedTime[ pID ] = g_iTime + seconds;
	    }
	}
	return 1;
}

DQCMD:unmute( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
    	new pID;
	    if ( sscanf( params, "u", pID )) return DCC_SendUserMessage( user, "/mute [PLAYER_ID]");
	    else if ( !IsPlayerConnected( pID ) ) return DCC_SendUserMessage( user,  "**Command Error:** Invalid Player ID");
	    else if ( !p_Muted{ pID } ) return DCC_SendUserMessage( user,  "**Command Error:** This player isn't muted" );
	    else
		{
	        SendGlobalMessage( -1, ""COL_PINK"[DISCORD ADMIN]{FFFFFF} %s has been un-muted by %s.", ReturnPlayerName( pID ), ReturnDiscordName( user ) );
			GameTextForPlayer( pID, "~g~Un-Muted!", 4000, 4 );
	        p_Muted{ pID } = false;
	        p_MutedTime[ pID ] = 0;
	    }
	}
    return 1;
}

DQCMD:getip( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasPermission );
	if ( hasPermission )
	{
		new pID;
		if ( sscanf( params, "u", pID ) ) return DCC_SendUserMessage( user, "**Usage:** !warn [PLAYER_ID] [REASON]" );
		if ( IsPlayerConnected( pID ) )
		{
			if ( p_AdminLevel[ pID ] > 4 ) return DCC_SendUserMessage( user, "**Command Error:** No sexy head admin targetting!");
			DCC_SendChannelMessageFormatted( discordAdminChan, "**Command Success:** %s(%d)'s IP is 14%s", ReturnPlayerName( pID ), pID, ReturnPlayerIP( pID ) );
		}
		else DCC_SendUserMessage( user, "**Command Error:** Player is not connected!" );
	}
	return 1;
}

/* OP */
DQCMD:unban( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		player[24],
		Query[70],
		bool: hasPermission
	;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleHead, hasPermission );

	if ( ! hasPermission ) return 0;
	else if ( sscanf( params, "s[24]", player ) ) return DCC_SendUserMessage( user, "**Usage:** !unban [PLAYER]" );
	else
	{
		format( Query, sizeof( Query ), "SELECT `NAME` FROM `BANS` WHERE `NAME` = '%s'", mysql_escape( player ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanPlayer", "dds", INVALID_PLAYER_ID, 1, player );
	}
	return 1;
}

DQCMD:unbanip( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		address[16],
		Query[70],
		bool: hasPermission
	;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleHead, hasPermission );

	if ( ! hasPermission ) return 0;
	else if (sscanf(params, "s[16]", address)) return DCC_SendUserMessage( user, "**Usage:** !unbanip [IP]" );
	else
	{
		format( Query, sizeof( Query ), "SELECT `IP` FROM `BANS` WHERE `IP` = '%s'", mysql_escape( address ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanIP", "dds", INVALID_PLAYER_ID, 0, address );
	}
	return 1;
}

/* Executive */
DQCMD:kickall( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleExecutive, hasPermission );
	if ( hasPermission )
	{
		SendGlobalMessage( -1, ""COL_PINK"[ADMIN]"COL_WHITE" Everyone has been kicked from the server due to a server update." );
		for( new i, g = GetMaxPlayers( ); i < g; i++ )
		{
		    if ( IsPlayerConnected( i ) )
		    {
		        Kick( i );
		    }
		}
		DCC_SendChannelMessage( discordAdminChan, "**Command Success:** All users have been kicked from the server." );
	}
	return 1;
}

DQCMD:rcon( DCC_Channel: channel, DCC_User: user, params[ ] )
{
	new
		bool: hasPermission;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleExecutive, hasPermission );

	if ( hasPermission )
	{
		if ( ! isnull( params ) )
		{
			if ( strcmp( params, "exit", true ) != 0 )
			{
				DCC_SendChannelMessageFormatted( discordAdminChan, "RCON command **%s** has been executed.", params );
				SendRconCommand( params );
			}
		}
	}
	return 1;
}