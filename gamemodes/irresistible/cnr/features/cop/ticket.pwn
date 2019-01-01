/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\ticket.pwn
 * Purpose: ticketing system for police
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
  	p_TicketTimestamp  				[ MAX_PLAYERS ],
   	p_TicketIssuer           		[ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... }
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
	p_TicketTimestamp[ playerid ] = 0;
    return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
	p_TicketTimestamp[ playerid ] = 0;
    return 1;
}

hook OnPlayerUpdateEx( playerid )
{
    // Failed to pay ticket
    if ( p_TicketTimestamp[ playerid ] != 0 && g_iTime > p_TicketTimestamp[ playerid ] )
    {
        // inform user
        SendServerMessage( playerid, "You have resisted to pay your ticket and have become a wanted criminal." );
        SendClientMessageToCops( -1, ""COL_BLUE"[CRIME]"COL_WHITE" %s(%d) has resisted to pay his ticket.", ReturnPlayerName( playerid ), playerid );

        // remove ticket
        p_TicketTimestamp[ playerid ] = 0;
        p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
        GivePlayerWantedLevel( playerid, 6 );
    }
    return 1;
}

hook OnPlayerJailed( playerid )
{
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
	p_TicketTimestamp[ playerid ] = 0;
    return 1;
}

/* ** Variables ** */
CMD:tk( playerid, params[ ] ) return cmd_ticket( playerid, params );
CMD:ticket( playerid, params[ ] )
{
   	new
   		pID = GetClosestPlayer( playerid );

	TicketPlayer( pID, playerid );
	SendServerMessage( playerid, "You can use your middle mouse button to easily ticket individuals that are near to you." );
	return 1;
}

CMD:payticket( playerid, params[] )
{
	if ( !p_WantedLevel[ playerid ] )
		return SendError( playerid, "There's no point paying off a ticket when you don't have a wanted level." );

	if ( p_WantedLevel[ playerid ] > 5 )
		return SendError( playerid, "Your wanted level is excessive to pay a ticket." );

	if ( !p_TicketTimestamp[ playerid ] )
		return SendError( playerid, "You have not been ticketed!" );

	if ( GetPlayerCash( playerid ) < 2000 )
		return SendError( playerid, "You don't have money to pay for your ticket." );

	new
		copid = p_TicketIssuer[ playerid ];

	// remove ticket
	p_TicketTimestamp[ playerid ] = 0;
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;

	// remove wanted level
	GivePlayerCash( playerid, -2000 );
	GivePlayerWantedLevel( playerid, -6 );
	SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[TICKET]{FFFFFF} You have paid "COL_GOLD"$2,000{FFFFFF} dollars into paying your ticket." );

	// pay cop
	if ( IsPlayerConnected( copid ) ) {
		GivePlayerScore( copid, 2 );
		GivePlayerCash( copid, 1500 );
		GivePlayerExperience( copid, E_POLICE, 0.5 );
		GameTextForPlayer( copid, "~n~~g~~h~Ticket paid!", 2000, 4 );
		SendClientMessageFormatted( copid, -1, ""COL_GREEN"[TICKET]{FFFFFF} %s(%d) has paid his ticket issues, you have earned "COL_GOLD"$1,500{FFFFFF}!", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

/* ** Functions ** */
stock TicketPlayer( pID, playerid )
{
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) > 10.0 || !IsPlayerConnected( pID ) ) return SendError( playerid, "There are no players around to ticket." );
	else if ( p_TicketIssuer[ pID ] == playerid ) return SendError( playerid, "You've already gave a ticket to this player." );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "This player is in your team!" );
	else if ( p_WantedLevel[ pID ] > 5 ) return SendError( playerid, "Wanted suspects cannot be issued a ticket." );
	else if ( p_WantedLevel[ pID ] < 1 ) return SendError( playerid, "Innocent players cannot be issued a ticket." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "You cannot use this command in jail." );
	//else if ( IsPlayerDetained( pID ) ) return SendError( playerid, "You cannot use this command on a detained player." );
	else if ( g_iTime < p_TicketTimestamp[ pID ] ) return SendError( playerid, "This player has been ticketed recently, he will be fined in %d seconds.", g_iTime - p_TicketTimestamp[ pID ] );
	else
	{
		if ( p_AdminOnDuty{ pID } == true ) return SendError( playerid, "This is an admin on duty!" );
		if ( IsPlayerJailed( pID ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( IsPlayerTied( pID ) ) return SendError( playerid, "This player is tied, you cannot ticket him unless he is untied." );
		if ( GetPlayerState( pID ) == PLAYER_STATE_WASTED ) return SendError( playerid, "You cannot ticket wasted players." );

	    p_TicketTimestamp[ pID ] = g_iTime + 15;
	    p_TicketIssuer[ pID ] = playerid;

		GameTextForPlayer( pID, "~n~~r~Ticketed!~n~~w~/payticket", 2000, 4 );
		SendClientMessageFormatted( pID, -1, ""COL_RED"[TICKET]{FFFFFF} You have been issued a "COL_GOLD"$2,000{FFFFFF} ticket by %s(%d) for your recent criminal activity!", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( pID, -1, ""COL_RED"[TICKET]{FFFFFF} You have 15 seconds to "COL_GREY"/payticket"COL_WHITE" before you are wanted for resisting law enforcement." );
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[TICKET]{FFFFFF} You issued a ticket of "COL_GOLD"$2,000{FFFFFF} to %s(%d)!", ReturnPlayerName( pID ), pID );
	}
	return 1;
}