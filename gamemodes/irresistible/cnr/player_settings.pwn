/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_SETTINGS 					( 12 )

#define SETTING_BAILOFFERS 				( 0 )
#define SETTING_EVENT_TP				( 1 )
#define SETTING_GANG_INVITES			( 2 )
#define SETTING_CHAT_PREFIXES			( 3 )
#define SETTING_RANSOMS					( 4 )
#define SETTING_AUTOSAVE				( 5 )
#define SETTING_CONNECTION_LOG 			( 6 )
#define SETTING_HITMARKER 				( 7 )
#define SETTING_VIPSKIN 				( 8 )
#define SETTING_COINS_BAR	 			( 9 )
#define SETTING_TOP_DONOR 				( 10 )
#define SETTING_WEAPON_PICKUP 			( 11 )

/* ** Variables ** */
enum E_SETTING_DATA {
	bool: E_DEFAULT_VAL,		E_NAME[ 20 ]
};

new
	g_PlayerSettings 					[ ] [ E_SETTING_DATA ] = {
		{ false, "Bail Offers" }, { false, "Event Teleports" }, { false, "Gang Invites" }, { false, "Chat Prefixes" }, { false, "Ransom Offers" },
		{ false, "Auto-Save" }, { true, "Connection Log" }, { true, "Hitmarker" }, { true, "V.I.P Skin" }, { false, "Total Coin Bar" }, { false, "Last Donor Text" },
		{ false, "Auto Pickup Weapon" }
	},
	bool: p_PlayerSettings 				[ MAX_PLAYERS ] [ MAX_SETTINGS char ]
;

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_CP_MENU && response )
	{
		if ( IsPlayerInEvent( playerid ) ) {
			return SendError( playerid, "You cannot modify your player settings within an event." );
		}

		if ( listitem == 0 ) {
			return ShowPlayerAccountGuard( playerid );
		}

		new
			settingid = listitem - 1;

		if ( ( p_PlayerSettings[ playerid ] { settingid } = !p_PlayerSettings[ playerid ] { settingid } ) == true )
		{
			if ( settingid == SETTING_VIPSKIN )
			{
				if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
				SyncObject( playerid );
				ClearAnimations( playerid );
				SetPlayerSkin( playerid, p_LastSkin[ playerid ] );
			}

			else if ( settingid == SETTING_COINS_BAR )
			 	ShowPlayerTogglableTextdraws( playerid, .force = false );

			else if ( settingid == SETTING_TOP_DONOR )
 				HidePlayerTogglableTextdraws( playerid, .force = false );

			format( szNormalString, 68, "INSERT INTO `SETTINGS`(`USER_ID`, `SETTING_ID`) VALUES (%d, %d)", p_AccountID[ playerid ], settingid );
		}
		else
		{
			if ( settingid == SETTING_COINS_BAR )
 				HidePlayerTogglableTextdraws( playerid, .force = false );

			else if ( settingid == SETTING_TOP_DONOR )
 				ShowPlayerTogglableTextdraws( playerid, .force = false );

			format( szNormalString, 64, "DELETE FROM `SETTINGS` WHERE USER_ID=%d AND SETTING_ID=%d", p_AccountID[ playerid ], settingid );
		}
		mysql_single_query( szNormalString );
		SendServerMessage( playerid, "You have %s "COL_GREY"%s"COL_WHITE". Changes may take effect after spawning/relogging.", p_PlayerSettings[ playerid ] { settingid } != g_PlayerSettings[ settingid ] [ E_DEFAULT_VAL ] ? ( "disabled" ) : ( "enabled" ), g_PlayerSettings[ settingid ] [ E_NAME ] );
	    cmd_cp( playerid, "" ); // Redirect to control panel again...
	}
	return 1;
}

hook OnPlayerConnect( playerid ) {
	for ( new i = 0; i < MAX_SETTINGS; i ++ ) {
		p_PlayerSettings[ playerid ] { i } = g_PlayerSettings[ i ] [ E_DEFAULT_VAL ];
	}
	return 1;
}

hook OnPlayerLogin( playerid, accountid )
{
	format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `SETTINGS` WHERE `USER_ID`=%d", accountid );
	mysql_function_query( dbHandle, szNormalString, true, "OnSettingsLoad", "d", playerid );
	return 1;
}

/* ** SQL Threads ** */
thread OnSettingsLoad( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new
			i = -1;

		while( ++ i < rows )
		{
			new
				settingid = cache_get_field_content_int( i, "SETTING_ID", dbHandle );

			if ( settingid < MAX_SETTINGS ) // Must be something wrong otherwise...
				p_PlayerSettings[ playerid ] { settingid } = true;
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:cp( playerid, params[ ] ) return cmd_controlpanel( playerid, params );
CMD:controlpanel( playerid, params[ ] )
{
	szLargeString = ""COL_WHITE"Setting\t"COL_WHITE"Status\t"COL_WHITE"Default\n"COL_GREY"Irresistible Guard\t \t"COL_GREY">>>\n";

	for( new i = 0; i < MAX_SETTINGS; i++ ) {
		format( szLargeString, 600, "%s%s\t%s\t"COL_GREY"%s\n", szLargeString, g_PlayerSettings[ i ] [ E_NAME ], p_PlayerSettings[ playerid ] { i } == g_PlayerSettings[ i ] [ E_DEFAULT_VAL ] ? ( ""#COL_GREEN"enabled" ) : ( ""#COL_RED"disabled" ), g_PlayerSettings[ i ] [ E_DEFAULT_VAL ] ? ( "disabled" ) : ( "enabled" ) );
	}

	ShowPlayerDialog( playerid, DIALOG_CP_MENU, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Control Panel", szLargeString, "Select", "Cancel" );
	return 1;
}

/* ** Functions ** */
stock IsPlayerSettingToggled( playerid, settingid ) {
	return p_PlayerSettings[ playerid ] { settingid } == g_PlayerSettings[ settingid ] [ E_DEFAULT_VAL ];
}
