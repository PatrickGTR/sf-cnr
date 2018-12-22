/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: irresistible\cnr\discord\discord.pwn
 * Purpose: discord implementation in-game
 */

 #define DISCORD_DISABLED 			// !!!! DISABLED BY DEFAULT !!!!

/* ** Includes ** */
#include 							< YSI\y_hooks >
//#include                          < discord-connector >

/* ** Definitions ** */
#define DISCORD_GENERAL 			"191078670360641536"
#define DISCORD_ADMINISTRATION 		"191078670360641536"
#define DISCORD_SPAM 				"364725535256870913"

#define DISCORD_ROLE_EXEC 			"191727949404176384"
#define DISCORD_ROLE_HEAD 			"191134988354191360"
#define DISCORD_ROLE_LEAD			"191080382689443841"
#define DISCORD_ROLE_VIP			"191180697547833344"
#define DISCORD_ROLE_VOICE			"364678874681966592"

/* ** Variables ** */
new stock
	DCC_Guild: discordGuild,
	DCC_Channel: discordGeneralChan,
	DCC_Channel: discordAdminChan,
	DCC_Channel: discordSpamChan,

	DCC_Role: discordRoleExecutive,
	DCC_Role: discordRoleHead,
	DCC_Role: discordRoleLead,
	DCC_Role: discordRoleVIP,
	DCC_Role: discordRoleVoice
;

/* ** Error Checking ** */
#if defined DISCORD_DISABLED
	stock DCC_SendChannelMessage( DCC_Channel: channel, const message[ ] ) {
		#pragma unused channel
		#pragma unused message
		return 1;
	}
	stock DCC_SendUserMessage( DCC_User: user, const message[ ] )
	{
		#pragma unused user
		#pragma unused message
		return 1;
	}
	#endinput
#endif

/* ** Hooks ** */
hook OnScriptInit( )
{
    discordGuild = DCC_FindGuildById( DISCORD_GENERAL );
    discordGeneralChan = DCC_FindChannelById( DISCORD_GENERAL );
    discordSpamChan = DCC_FindChannelById( DISCORD_SPAM );

    discordRoleExecutive = DCC_FindRoleById( DISCORD_ROLE_EXEC );
    discordRoleHead = DCC_FindRoleById( DISCORD_ROLE_HEAD );
    discordRoleLead = DCC_FindRoleById( DISCORD_ROLE_LEAD );
    discordRoleVIP = DCC_FindRoleById( DISCORD_ROLE_VIP );
    discordRoleVoice = DCC_FindRoleById( DISCORD_ROLE_VOICE );

    DCC_SendChannelMessage( discordGeneralChan, "**The discord plugin has been initiaized.**" );
    return 1;
}

/* ** Commands ** */
CMD:discordpm( playerid, params[ ] )
{
	new
		msg[ 128 ];

	if ( sscanf( params, "s[100]", msg ) ) SendUsage( playerid, "/discordpm [message]" );
	else
	{
 		Beep( playerid );
 		format( msg, sizeof( msg ), "__[Discord PM]__ **%s(%d):** %s", ReturnPlayerName( playerid ), playerid, msg );
    	DCC_SendChannelMessage( discordGeneralChan, msg );
		SendServerMessage( playerid, "Your typed message has been sent to the Discord #sfcnr channel!" );
	}
	return 1;
}

/* ** Functions ** */
hook DCC_OnChannelMessage( DCC_Channel: channel, DCC_User: author, const message[ ] )
{
	// ignore outside of #sfcnr and #admin
	if ( channel != discordGeneralChan && channel != discordAdminChan )
		return 1;

	// process commands
	if ( message[ 0 ] == '!' )
	{
		new
			functiona[ 32 ], posi = 0;

		while ( message[ ++posi ] > ' ' ) {
			functiona[ posi - 1 ] = tolower( message[ posi ] );
		}

		format( functiona, sizeof( functiona ), "discord_%s", functiona );

		while ( message[ posi ] == ' ' ) {
			posi++;
		}

		if ( ! message[ posi ] ) {
			CallLocalFunction( functiona, "dds", _: channel, _: author, "\1" );
		} else {
			CallLocalFunction( functiona, "dds", _: channel, _: author, message[ posi ] );
		}
	}
	return 1;
}

stock ReturnDiscordName( DCC_User: user ) {
	static
		name[ 32 ];

	DCC_GetUserName( user, name, sizeof( name ) );
	return name;
}

stock discordLevelToString( DCC_User: user )
{
	static
		szRank[ 12 ], bool: hasExecutive, bool: hasHead, bool: hasLead, bool: hasVIP;

	DCC_HasGuildMemberRole( discordGuild, user, discordRoleExecutive, hasExecutive );
	DCC_HasGuildMemberRole( discordGuild, user, discordRoleHead, hasHead );
	DCC_HasGuildMemberRole( discordGuild, user, discordRoleLead, hasLead );
	DCC_HasGuildMemberRole( discordGuild, user, discordRoleVIP, hasVIP );

	if ( hasExecutive ) szRank = "Executive";
	else if ( hasHead ) szRank = "Head Admin";
	else if ( hasLead ) szRank = "Lead Admin";
	else if ( hasVIP ) szRank = "VIP";
	else szRank = "Voice";

    return szRank;
}

stock DCC_SendUserMessage( DCC_User: user, const message[ ] )
{
	static
		user_id[ 64 ];

	DCC_GetUserId( user, user_id, sizeof( user_id ) );
	format( szBigString, sizeof( szBigString ), "<@%s> ... %s", user_id, message );
	return DCC_SendChannelMessage( discordSpamChan, szBigString );
}