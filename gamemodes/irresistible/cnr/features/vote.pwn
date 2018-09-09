/*
 * Irresistible Gaming (c) 2018
 * Developed by Cloudy
 * Module: vote.inc
 * Purpose: vote system for individuals
 */


/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define DIALOG_VOTE_CONFIG 			5671
#define DIALOG_VOTE_QUESTION 		5672
#define DIALOG_VOTE_ADDOPTION 		5673
#define DIALOG_VOTE_EDITOPTION 		5674

/* ** Variables ** */
new bool: v_started;
new v_question 						[ 80 ]; //// the vote question content
new v_option 						[ 5 ] [ 50 ]; //// five options max
new v_option_votes 					[ 5 ]; //// Stores the votes of each option.
new v_voted 						[ MAX_PLAYERS ]; //// This will have the accounts ID's of the voters, to prevent voting more than once.

new Text: v_TD_Question;
new Text: v_TD_Option 				[ 5 ];

/* ** Hooks ** */
hook OnGameModeInit( )
{
	ResetVoteAll( );
	LoadVotingTextdraws( );
	return 1;
}

hook OnPlayerText( playerid, text[ ] )
{
	if( !v_started || GetPlayerAccountID( playerid ) <= 0 ) return 1; /// no poll or player isn't logged in.
	new option;
	if( !sscanf( text, "i", option ) ) {
		if( ( 1 <= option <= 5 ) && strcmp( v_option[ option-1 ], "n/a", true ) ) {
		    if( !didPlayerVote( playerid ) ) {
		        new string[ 128 ];
				AddPlayerVote( playerid, option-1 );
				format( string, sizeof( string ), "{C0C0C0}[SERVER]{FFFFFF} Your vote has been added: {C0C0C0}%d", option );
	        	SendClientMessage( playerid, -1, string );
	        	return 0;
	    	}
		}
	}
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	HideVoteTextdrawsForPlayer( playerid );
	return 1;
}

hook OnPlayerSpawn( playerid )
{
    ShowVoteTextdrawsForPlayer( playerid );
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[ ] )
{
	if( dialogid == DIALOG_VOTE_CONFIG && response ) {
	    if( GetPlayerAdminLevel( playerid ) >= 4 ) {
	        if( listitem == 0 )
	            ShowPlayerDialog( playerid, DIALOG_VOTE_QUESTION, DIALOG_STYLE_INPUT, "{FFFFFF}Vote Settings - Set Question", "{FFFFFF}Write the question you want to vote for:", "Set", "Back" );
	        else if( !strcmp( inputtext, "Add a new option", true, 16 ) )
	            ShowPlayerDialog( playerid, DIALOG_VOTE_ADDOPTION, DIALOG_STYLE_INPUT, "{FFFFFF}Vote Settings - Add Option", "{FFFFFF}Write the option you want to add:", "Add", "Back" );
			else {
			    new optionid = strval( inputtext[ 0 ] ) - 1;
				SetPVarInt( playerid, "p_VoteEditOption", optionid );
				ShowPlayerDialog( playerid, DIALOG_VOTE_EDITOPTION, DIALOG_STYLE_INPUT, "{FFFFFF}Vote Settings - Edit Option", "{FFFFFF}Enter the text you want to set the option to:", "Update", "Back" );
			}
		 }
	}

    else if( dialogid == DIALOG_VOTE_QUESTION ) {
	    if( GetPlayerAdminLevel( playerid ) >= 4 )
	    	return SendError( playerid, "You don't have an appropriate administration level to use this feature." );

        if( response ) {
	        if( !strlen( inputtext ) )
	            ShowPlayerDialog( playerid, DIALOG_VOTE_QUESTION, DIALOG_STYLE_INPUT, "{FFFFFF}Vote Settings - Set Question", "{FFFFFF}Write the question you want to vote for:\n\n{FF0000}Invalid question", "Set", "Back" );
			else {
				format( v_question, sizeof( v_question ), inputtext );
 				if( v_started ) updateQuestionTD( );
				ShowVoteConfig( playerid );
			}
		}
	}

    else if( dialogid == DIALOG_VOTE_ADDOPTION ) {
	    if( GetPlayerAdminLevel( playerid ) >= 4 )
	        if( response ) {
	            if( v_started ) {
					SendClientMessage( playerid, -1, "{FF0000}[ERROR]{FFFFFF} You cannot edit options while poll is on." );
					ShowVoteConfig( playerid );
					return 1;
				}
		        if( !strlen( inputtext ) )
		            ShowPlayerDialog( playerid, DIALOG_VOTE_ADDOPTION, DIALOG_STYLE_INPUT, "{FFFFFF}Vote Settings - Add Option", "{FFFFFF}Write the option you want to add:\n\n{FF0000}Invalid text", "Add", "Back" );
				else {
					if( getNextOptionID( ) != -1 ) {
						format( v_option[ getNextOptionID( ) ], 50, inputtext );
						SendClientMessage(playerid, -1, "{C0C0C0}[VOTE]{FFFFFF} You've added a new option." );
					}
					else
					    SendClientMessage(playerid, -1, "{FF0000}[ERROR]{FFFFFF} You can have a maximum of 5 options." );
					ShowVoteConfig( playerid );
				}
			}
			else if( !response )
			    ShowVoteConfig( playerid );
	}

	else if( dialogid == DIALOG_VOTE_EDITOPTION ) {
	    if( GetPlayerAdminLevel( playerid ) >= 4 )
	        if( response ) {
        		if( v_started ) {
					SendClientMessage( playerid, -1, "{FF0000}[ERROR]{FFFFFF} You cannot edit options while poll is on." );
					ShowVoteConfig( playerid );
					return 1;
				}
		        if( !strlen( inputtext ) )
		            ShowPlayerDialog( playerid, DIALOG_VOTE_EDITOPTION, DIALOG_STYLE_INPUT, "{FFFFFF}Vote Settings - Edit Option", "{FFFFFF}Enter the text you want to set the option to:\n\n{FF0000}Invalid text", "Update", "Back" );
				else {
					new optionid = GetPVarInt( playerid, "p_VoteEditOption" );
					format( v_option[ optionid ], 50, inputtext );
					SendClientMessage(playerid, -1, "{C0C0C0}[VOTE]{FFFFFF} You've updated an option." );
					ShowVoteConfig( playerid );
				}
			}
			else if( !response )
			    ShowVoteConfig( playerid );
	}
	return 1;
}

stock ResetVoteAll( )
{
    v_question = "n/a";
	for( new i = 0; i < 5; i++ ) v_option[ i ] = "n/a";
	ResetVotes( );
	endVote( );
}

stock ResetVotes( )
{
    for( new i = 0; i < MAX_PLAYERS; i++ ) v_voted[ i ] = -1;
    for( new i = 0; i < 5; i++ ) v_option_votes[ i ] = 0;
}

stock startVote( )
{
	v_started = true;
	ResetVotes( );
	updateAllVote( );
	ShowVoteTextdrawsForAll( );
}

stock endVote( )
{
	HideVoteTextdrawsForAll( );
	v_started = false;
	ResetVotes( );
}

stock updateOptionTD( option )
{
	if( strcmp( v_option[ option ], "n/a" ) ) {
		new string[128];
		format(string, sizeof(string), "%i. (%d) %s", option+1, v_option_votes[ option ], v_option[ option ] );
		TextDrawSetString( v_TD_Option[ option ], string );
	}
	else TextDrawSetString( v_TD_Option[ option ], " " );
}

stock updateQuestionTD( )
{
	new question[ 80 ];
	format( question, sizeof( question ), "~y~POLL: ~w~~h~%s", v_question );
	TextDrawSetString( v_TD_Question, question );
}
stock updateAllVote( )
{
	updateQuestionTD( );
	for( new i = 0; i < 5; i++ )
	    updateOptionTD( i );
}

stock ShowVoteConfig( playerid )
{
	reorderOptions( );
	new finalstring[ 600 ];
	format( finalstring, sizeof( finalstring ), "{C0C0C0}QUESTION: {FFFFFF}%s\n", v_question);

	new c_options = 0;
	for( new i = 0; i < 5; i++ ) if( strcmp( v_option[ i ], "n/a", true ) ) {
	    format( finalstring, sizeof( finalstring ), "%s{C0C0C0}%i. {FFFFFF}%s\n", finalstring, i+1, v_option[ i ] );
	    c_options++;
	}
	if(c_options < 5)
	    format( finalstring, sizeof( finalstring ), "%s{FFFFFF}Add a new option..", finalstring );
	ShowPlayerDialog( playerid, DIALOG_VOTE_CONFIG, DIALOG_STYLE_LIST, "{FFFFFF}Vote Settings", finalstring, "Select", "Close" );

}

stock reorderOptions( ) /// This thing, is to re-order options, like if there is option 1, 2 and 3, and I remove option 2, then option 3 will come in place of option 2.
{
	for( new i = 0; i < 5; i++ ) {
	    if( i + 1 < 5 )
			if( !strcmp( v_option[ i ], "n/a" ) && strcmp( v_option[ i+1 ], "n/a" ) ) {
			    v_option[ i ] = v_option[ i+1 ];
			    v_option_votes[ i ] = v_option_votes[ i+1 ];
			    v_option[ i+1 ] = "n/a";
			    v_option_votes[ i+1 ] = 0;
			}
	}
}

stock getNextOptionID( )
{
	for( new i = 0; i < 5; i++ ) if( !strcmp( v_option[ i ], "n/a" ) ) {
		return i;
	}
	return -1;
}

stock didPlayerVote( playerid )
{
	for( new i = 0; i < MAX_PLAYERS; i++ ) if( v_voted[ i ] == GetPlayerAccountID( playerid ) ) {
		return true;
	}
	return false;
}

stock AddPlayerVote( playerid, option )
{
	for( new i = 0; i < MAX_PLAYERS; i++ ) {
	    if( v_voted[ i ] == -1 ) {
	        v_voted[ i ] = GetPlayerAccountID( playerid );
	        v_option_votes[ option ]++;
			updateOptionTD( option );
	        break;
		}
	}
}

stock LoadVotingTextdraws( )
{
    v_TD_Question = TextDrawCreate( 16.000000, 168.000000, "POLL: Who's the best player here?" );
	TextDrawBackgroundColor( v_TD_Question, 255 );
	TextDrawFont( v_TD_Question, 1 );
	TextDrawLetterSize( v_TD_Question, 0.200000, 1.100000 );
	TextDrawColor( v_TD_Question, -1 );
	TextDrawSetOutline( v_TD_Question, 1 );
	TextDrawSetProportional( v_TD_Question, 1 );
	TextDrawSetSelectable( v_TD_Question, 0 );

	new Float: td_y_temp = 182.000000;
	for( new i = 0; i < 5; i++ ) {
		v_TD_Option[ i ] = TextDrawCreate( 16.000000, td_y_temp, "1. (35) Cloudy" );
		TextDrawBackgroundColor( v_TD_Option[ i ], 255 );
		TextDrawFont( v_TD_Option[ i ], 1);
		TextDrawLetterSize( v_TD_Option[ i ], 0.200000, 1.100000 );
		TextDrawColor( v_TD_Option[ i ], -1 );
		TextDrawSetOutline( v_TD_Option[ i ], 1 );
		TextDrawSetProportional( v_TD_Option[ i ], 1 );
		TextDrawSetSelectable( v_TD_Option[ i ], 0 );
		td_y_temp += 11.0;
	}
}

stock ShowVoteTextdrawsForPlayer( playerid )
{
	if( v_started ) {
        TextDrawShowForPlayer( playerid, v_TD_Question );
        for( new i = 0; i < 5; i++ ) {
			if( strcmp( v_option[ i ], "n/a" ) ) TextDrawShowForPlayer( playerid, v_TD_Option[ i ] );
			else TextDrawHideForPlayer( playerid, v_TD_Option[ i ] );
        }
	}
}

stock HideVoteTextdrawsForPlayer( playerid )
{
	if( v_started ) {
        TextDrawHideForPlayer( playerid, v_TD_Question );
        for( new i = 0; i < 5; i++ ) {
			TextDrawHideForPlayer( playerid, v_TD_Option[ i ] );
        }
	}
}

stock ShowVoteTextdrawsForAll( ) {
	if( v_started ) {
        TextDrawShowForAll( v_TD_Question );
        for( new i = 0; i < 5; i++ ) {
			if( strcmp( v_option[ i ], "n/a" ) ) TextDrawShowForAll( v_TD_Option[ i ] );
			else TextDrawHideForAll( v_TD_Option[ i ] );
		}
	}
}

stock HideVoteTextdrawsForAll(  ) {
	if( v_started ) {
        TextDrawHideForAll( v_TD_Question );
        for( new i = 0; i < 5; i++ ) TextDrawHideForAll( v_TD_Option[ i ] );
	}
}

/* ** Commands **/
CMD:vote( playerid, params[ ] )
{
	if( GetPlayerAdminLevel( playerid ) < 4 )
		return SendClientMessage( playerid, -1, "{FF0000}[ERROR]{FFFFFF} You don't have an appropriate administration level to use this command." );

	if( !strcmp( params, "start", true, 5 ) ) {
		if( !strcmp( v_question, "n/a" ) )
		    return SendClientMessage( playerid, -1, "{FF0000}[ERROR]{FFFFFF} You have not set a question for the vote." );

		startVote( );
		new string[ 128 ];
		format( string, sizeof( string ), "{FF0770}[ADMIN]{FFFFFF} %s(%d) has started a new poll.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageToAll( -1, string );
	}
	else if( !strcmp( params, "end", true, 3 ) ) {
		if( !v_started )
		    return SendClientMessage( playerid, -1, "{FF0000}[ERROR]{FFFFFF} There are no poll to end." );

		endVote( );
		new string[ 128 ];
		format( string, sizeof( string ), "{FF0770}[ADMIN]{FFFFFF} %s(%d) has ended the poll.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageToAll( -1, string );
	}
 	else if( !strcmp( params, "reset", true, 5 ) ) {
 	    if( v_started ) SendClientMessageToAll( -1, sprintf( "{FF0770}[ADMIN]{FFFFFF} %s(%d) has ended the poll.", ReturnPlayerName( playerid ), playerid ) );
	    ResetVoteAll();
	    SendClientMessage( playerid, -1, "{C0C0C0}[VOTE]{FFFFFF} You have reset vote parameters." );
	}
	else if( !strcmp( params, "config", true, 6 ) ) {
		ShowVoteConfig( playerid );
	}
	else SendUsage( playerid, "/vote [RESET/START/END/CONFIG]" );
	return 1;
}
