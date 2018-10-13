/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr/textdraws.pwn
 * Purpose: encloses all textdraws in the server
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
new Text: g_classTextdrawBox[ sizeof( CLASS_NAMES ) ] = { Text: INVALID_TEXT_DRAW, ... };
new Text: g_classTextdrawDescription[ sizeof( CLASS_NAMES ) ] = { Text: INVALID_TEXT_DRAW, ... };
new Text: g_classTextdrawName[ sizeof( CLASS_NAMES ) ] = { Text: INVALID_TEXT_DRAW, ... };

new
	Text:  g_ClassBoxTD        		= Text: INVALID_TEXT_DRAW,
	Text:  g_ObjectLoadTD         	= Text: INVALID_TEXT_DRAW,
	Text:  g_WebsiteTD        		= Text: INVALID_TEXT_DRAW,
	Text:  g_MotdTD               	= Text: INVALID_TEXT_DRAW,
	Text:  g_MovieModeTD            [ 6 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_WorldDayTD       		= Text: INVALID_TEXT_DRAW,
	Text:  g_AchievementTD          [ 4 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_AdminLogTD         	= Text: INVALID_TEXT_DRAW,
	Text:  g_AdminOnDutyTD          = Text: INVALID_TEXT_DRAW,
	Text:  g_PassiveModeTD 			= Text: INVALID_TEXT_DRAW,
	Text:  g_DoubleXPTD				= Text: INVALID_TEXT_DRAW,
	Text:  g_currentXPTD 			= Text: INVALID_TEXT_DRAW,
	Text:  g_CurrentRankTD 			= Text: INVALID_TEXT_DRAW,
	Text:  g_CurrentCoinsTD 		= Text: INVALID_TEXT_DRAW,
	Text:  g_TopDonorTD				= Text: INVALID_TEXT_DRAW,
	Text:  g_NotManyPlayersTD		= Text: INVALID_TEXT_DRAW,

	// Player Textdraws
	PlayerText: p_LocationTD		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_ExperienceTD   	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_WantedLevelTD		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_CoinsTD        	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_PlayerRankTD 		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_PlayerRankTextTD 	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_RobberyAmountTD 	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_RobberyRiskTD 	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_JailTimeTD     	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: g_ZoneOwnerTD     	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_HelpBoxTD 		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_TruckingTD 		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_TrackPlayerTD     [ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_GPSInformation	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_AchievementTD		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... }
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	g_ClassBoxTD = TextDrawCreate(40.000000, 170.000000, "_");
	TextDrawBackgroundColor(g_ClassBoxTD, 255);
	TextDrawFont(g_ClassBoxTD, 1);
	TextDrawLetterSize(g_ClassBoxTD, 0.500000, 16.000000);
	TextDrawColor(g_ClassBoxTD, -1);
	TextDrawSetOutline(g_ClassBoxTD, 0);
	TextDrawSetProportional(g_ClassBoxTD, 1);
	TextDrawSetShadow(g_ClassBoxTD, 1);
	TextDrawUseBox(g_ClassBoxTD, 1);
	TextDrawBoxColor(g_ClassBoxTD, 144);
	TextDrawTextSize(g_ClassBoxTD, 170.000000, 10.000000);

	for ( new i = 0; i < sizeof( g_classTextdrawBox ); i ++ )
	{
		g_classTextdrawBox[ i ] = TextDrawCreate(40.000000, 138.000000, "_");
		TextDrawBackgroundColor(g_classTextdrawBox[ i ], 255);
		TextDrawFont(g_classTextdrawBox[ i ], 1);
		TextDrawLetterSize(g_classTextdrawBox[ i ], 0.500000, 3.000000);
		TextDrawColor(g_classTextdrawBox[ i ], -1);
		TextDrawSetOutline(g_classTextdrawBox[ i ], 0);
		TextDrawSetProportional(g_classTextdrawBox[ i ], 1);
		TextDrawSetShadow(g_classTextdrawBox[ i ], 1);
		TextDrawUseBox(g_classTextdrawBox[ i ], 1);
		TextDrawBoxColor(g_classTextdrawBox[ i ], CLASS_COLORS[ i ]);
		TextDrawTextSize(g_classTextdrawBox[ i ], 170.000000, 10.000000);

		szLargeString[ 0 ] = '\0';

		switch ( i )
		{
			case 0: {
				strcat( szLargeString,	"- Select different types of jobs~n~" \
										"- Able to rob stores and players~n~" \
										"- Can gang up with players~n~" \
										"~g~~h~- Accessible to everybody" );
			}
			case 1:	{
				strcat( szLargeString,	"- Protect the city from criminals~n~" \
										"- Access to police gun lockers~n~" \
										"- Can arrest/jail people~n~" \
										"~g~~h~- Accessible to everybody" );
			}
			case 2:	{
				strcat( szLargeString,	"- Protect the city from criminals~n~" \
										"- Access to police gun lockers~n~" \
										"- Can arrest/jail people~n~" \
										"- Can set roadblocks on roads~n~" \
										"- Can set spike traps on roads~n~" \
										"~r~~h~- Requires 10,000 XP or more" );
			}
			case 3: {
				strcat( szLargeString,	"- Protect the city from criminals~n~" \
										"- Access to police gun lockers~n~" \
										"- Can arrest/jail people~n~" \
										"- Can set roadblocks on roads~n~" \
										"- Can set spike traps on roads~n~" \
										"- Can use combat vehicles~n~" \
										"~r~~h~- Requires 20,000 XP or more" );
			}
			case 4: {
				strcat( szLargeString,	"- Protect the city from criminals~n~" \
										"- Access to police gun lockers~n~" \
										"- Can arrest/jail people~n~" \
										"- Can set roadblocks on roads~n~" \
										"- Can set spike traps on roads~n~" \
										"- Hidden from radar~n~" \
										"~r~~h~- Requires 15,000 XP or more" );
			}
			case 5: {
				strcat( szLargeString,	"- Can heal and cure players~n~" \
										"- Ambulance passengers pay you~n~"\
										"- Able to rob stores and players~n~" \
										"~r~~h~- Requires 1,000 XP or more" );
			}
			case 6: {
				strcat( szLargeString,	"- Protect the city from fires~n~" \
										"- Firetrucks able to extinguish fires~n~"\
										"- Able to rob stores and players~n~" \
										"~r~~h~- Requires 1,000 XP or more" );
			}
		}

		g_classTextdrawDescription[ i ] = TextDrawCreate(43.000000, 171.000000, szLargeString);
		TextDrawBackgroundColor(g_classTextdrawDescription[ i ], 0);
		TextDrawFont(g_classTextdrawDescription[ i ], 1);
		TextDrawLetterSize(g_classTextdrawDescription[ i ], 0.190000, 1.100000);
		TextDrawColor(g_classTextdrawDescription[ i ], -1);
		TextDrawSetOutline(g_classTextdrawDescription[ i ], 1);
		TextDrawSetProportional(g_classTextdrawDescription[ i ], 1);

		g_classTextdrawName[ i ] = TextDrawCreate(46.000000, 141.000000, CLASS_NAMES[ i ] );
		TextDrawBackgroundColor(g_classTextdrawName[ i ], 0);
		TextDrawFont(g_classTextdrawName[ i ], 3);
		TextDrawLetterSize(g_classTextdrawName[ i ], 0.550000, 2.099999);
		TextDrawColor(g_classTextdrawName[ i ], i == 0 ? 0x000000FF : 0xFFFFFFFF );
		TextDrawSetOutline(g_classTextdrawName[ i ], 1);
		TextDrawSetProportional(g_classTextdrawName[ i ], 1);
		TextDrawSetSelectable(g_classTextdrawName[ i ], 0);
	}

	g_NotManyPlayersTD = TextDrawCreate(322.000000, 12.000000, "Coin generation increased by 5x as there aren't many players online!");
	TextDrawAlignment(g_NotManyPlayersTD, 2);
	TextDrawBackgroundColor(g_NotManyPlayersTD, 0);
	TextDrawFont(g_NotManyPlayersTD, 1);
	TextDrawLetterSize(g_NotManyPlayersTD, 0.149999, 0.799999);
	TextDrawColor(g_NotManyPlayersTD, -16776961);
	TextDrawSetOutline(g_NotManyPlayersTD, 1);
	TextDrawSetProportional(g_NotManyPlayersTD, 1);

	g_TopDonorTD = TextDrawCreate(320.000000, 2.000000, "Top Donor Lorenc - $0.00, ~w~~h~~h~Latest Donor Lorenc - $0.00");
	TextDrawAlignment(g_TopDonorTD, 2);
	TextDrawBackgroundColor(g_TopDonorTD, 0);
	TextDrawFont(g_TopDonorTD, 1);
	TextDrawLetterSize(g_TopDonorTD, 0.139999, 0.799999);
	TextDrawColor(g_TopDonorTD, -2347265);
	TextDrawSetOutline(g_TopDonorTD, 1);
	TextDrawSetProportional(g_TopDonorTD, 1);

	g_currentXPTD = TextDrawCreate(529.000000, 405.000000, "Current XP");
	TextDrawBackgroundColor(g_currentXPTD, 255);
	TextDrawFont(g_currentXPTD, 3);
	TextDrawLetterSize(g_currentXPTD, 0.230000, 1.000000);
	TextDrawColor(g_currentXPTD, -1);
	TextDrawSetOutline(g_currentXPTD, 1);
	TextDrawSetProportional(g_currentXPTD, 1);

	g_CurrentRankTD = TextDrawCreate(529.000000, 375.000000, "Current Rank");
	TextDrawBackgroundColor(g_CurrentRankTD, 255);
	TextDrawFont(g_CurrentRankTD, 3);
	TextDrawLetterSize(g_CurrentRankTD, 0.230000, 1.000000);
	TextDrawColor(g_CurrentRankTD, -1);
	TextDrawSetOutline(g_CurrentRankTD, 1);
	TextDrawSetProportional(g_CurrentRankTD, 1);

	g_CurrentCoinsTD = TextDrawCreate(529.000000, 348.000000, "Total Coins");
	TextDrawBackgroundColor(g_CurrentCoinsTD, 255);
	TextDrawFont(g_CurrentCoinsTD, 3);
	TextDrawLetterSize(g_CurrentCoinsTD, 0.230000, 1.000000);
	TextDrawColor(g_CurrentCoinsTD, -1);
	TextDrawSetOutline(g_CurrentCoinsTD, 1);
	TextDrawSetProportional(g_CurrentCoinsTD, 1);

	g_DoubleXPTD = TextDrawCreate(516.000000, 423.500000, "x2");
	TextDrawBackgroundColor(g_DoubleXPTD, 255);
	TextDrawFont(g_DoubleXPTD, 3);
	TextDrawLetterSize(g_DoubleXPTD, 0.230000, 1.000000);
	TextDrawColor(g_DoubleXPTD, -1);
	TextDrawSetOutline(g_DoubleXPTD, 1);
	TextDrawSetProportional(g_DoubleXPTD, 1);

	g_AdminLogTD = TextDrawCreate(150.000000, 360.000000, "_");
	TextDrawBackgroundColor(g_AdminLogTD, 255);
	TextDrawFont(g_AdminLogTD, 1);
	TextDrawLetterSize(g_AdminLogTD, 0.210000, 1.000000);
	TextDrawColor(g_AdminLogTD, -16289537);
	TextDrawSetOutline(g_AdminLogTD, 1);
	TextDrawSetProportional(g_AdminLogTD, 1);

    g_AchievementTD[ 0 ] = TextDrawCreate(250.000000, 120.000000, "_");
	TextDrawBackgroundColor(g_AchievementTD[ 0 ], 255);
	TextDrawFont(g_AchievementTD[ 0 ], 1);
	TextDrawLetterSize(g_AchievementTD[ 0 ], 0.500000, 6.000001);
	TextDrawColor(g_AchievementTD[ 0 ], -1);
	TextDrawSetOutline(g_AchievementTD[ 0 ], 0);
	TextDrawSetProportional(g_AchievementTD[ 0 ], 1);
	TextDrawSetShadow(g_AchievementTD[ 0 ], 1);
	TextDrawUseBox(g_AchievementTD[ 0 ], 1);
	TextDrawBoxColor(g_AchievementTD[ 0 ], 80);
	TextDrawTextSize(g_AchievementTD[ 0 ], 403.000000, 4.000000);

	g_AchievementTD[ 1 ] = TextDrawCreate(250.000000, 120.000000, "_");
	TextDrawBackgroundColor(g_AchievementTD[ 1 ], 255);
	TextDrawFont(g_AchievementTD[ 1 ], 1);
	TextDrawLetterSize(g_AchievementTD[ 1 ], 0.500000, 1.300000);
	TextDrawColor(g_AchievementTD[ 1 ], -1);
	TextDrawSetOutline(g_AchievementTD[ 1 ], 0);
	TextDrawSetProportional(g_AchievementTD[ 1 ], 1);
	TextDrawSetShadow(g_AchievementTD[ 1 ], 1);
	TextDrawUseBox(g_AchievementTD[ 1 ], 1);
	TextDrawBoxColor(g_AchievementTD[ 1 ], 128);
	TextDrawTextSize(g_AchievementTD[ 1 ], 403.000000, 4.000000);

	g_AchievementTD[ 2 ] = TextDrawCreate(250.000000, 137.000000, "_");
	TextDrawBackgroundColor(g_AchievementTD[ 2 ], 255);
	TextDrawFont(g_AchievementTD[ 2 ], 1);
	TextDrawLetterSize(g_AchievementTD[ 2 ], 0.500000, -0.699999);
	TextDrawColor(g_AchievementTD[ 2 ], -1);
	TextDrawSetOutline(g_AchievementTD[ 2 ], 0);
	TextDrawSetProportional(g_AchievementTD[ 2 ], 1);
	TextDrawSetShadow(g_AchievementTD[ 2 ], 1);
	TextDrawUseBox(g_AchievementTD[ 2 ], 1);
	TextDrawBoxColor(g_AchievementTD[ 2 ], 255);
	TextDrawTextSize(g_AchievementTD[ 2 ], 403.000000, 4.000000);

	g_AchievementTD[ 3 ] = TextDrawCreate(266.000000, 121.000000, "]_ACHIEVEMENT UNLOCKED_]");
	TextDrawBackgroundColor(g_AchievementTD[ 3 ], 255);
	TextDrawFont(g_AchievementTD[ 3 ], 2);
	TextDrawLetterSize(g_AchievementTD[ 3 ], 0.210000, 1.100000);
	TextDrawColor(g_AchievementTD[ 3 ], -65281);
	TextDrawSetOutline(g_AchievementTD[ 3 ], 0);
	TextDrawSetProportional(g_AchievementTD[ 3 ], 1);
	TextDrawSetShadow(g_AchievementTD[ 3 ], 1);

   	g_WorldDayTD = TextDrawCreate(501.000000, 6.000000, "Monday");
	TextDrawBackgroundColor(g_WorldDayTD, 255);
	TextDrawFont(g_WorldDayTD, 3);
	TextDrawLetterSize(g_WorldDayTD, 0.519998, 1.499999);
	TextDrawSetOutline(g_WorldDayTD, 2);
	TextDrawSetProportional(g_WorldDayTD, 1);

	g_MotdTD = TextDrawCreate(320.000000, 426.000000, "_");
	TextDrawAlignment(g_MotdTD, 2);
	TextDrawBackgroundColor(g_MotdTD, 117);
	TextDrawFont(g_MotdTD, 1);//1
	TextDrawLetterSize(g_MotdTD, 0.300000, 1.300000);
	TextDrawColor(g_MotdTD, -1);
	TextDrawSetOutline(g_MotdTD, 1);
	TextDrawSetProportional(g_MotdTD, 1);

	g_ObjectLoadTD = TextDrawCreate(320.000000, 148.000000, "Loading Objects...~n~Please Wait...");
	TextDrawAlignment(g_ObjectLoadTD, 2);
	TextDrawBackgroundColor(g_ObjectLoadTD, 80);
	TextDrawFont(g_ObjectLoadTD, 2);
	TextDrawLetterSize(g_ObjectLoadTD, 0.400000, 2.000000);
	TextDrawColor(g_ObjectLoadTD, -1);
	TextDrawSetOutline(g_ObjectLoadTD, 1);
	TextDrawSetProportional(g_ObjectLoadTD, 1);
	TextDrawUseBox(g_ObjectLoadTD, 1);
	TextDrawBoxColor(g_ObjectLoadTD, 117);
	TextDrawTextSize(g_ObjectLoadTD, 0.000000, 180.000000);

	g_WebsiteTD = TextDrawCreate(84.000000, 429.000000, "www.SFCNR.com");
	TextDrawAlignment(g_WebsiteTD, 2);
	TextDrawBackgroundColor(g_WebsiteTD, 255);
	TextDrawFont(g_WebsiteTD, 1);
	TextDrawLetterSize(g_WebsiteTD, 0.220000, 1.200000);
	TextDrawColor(g_WebsiteTD, 0xfa4d4cff); // 1289224191
	TextDrawSetOutline(g_WebsiteTD, 1);
	TextDrawSetProportional(g_WebsiteTD, 1);

	g_MovieModeTD[ 0 ] = TextDrawCreate(507.000000, 386.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 0 ], 255);
	TextDrawFont(g_MovieModeTD[ 0 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 0 ], 0.500000, 4.799999);
	TextDrawColor(g_MovieModeTD[ 0 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 0 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 0 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 0 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 0 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 0 ], 80);
	TextDrawTextSize(g_MovieModeTD[ 0 ], 620.000000, 0.000000);

	g_MovieModeTD[ 1 ] = TextDrawCreate(516.000000, 398.000000, "San Fierro");
	TextDrawBackgroundColor(g_MovieModeTD[ 1 ], 255);
	TextDrawFont(g_MovieModeTD[ 1 ], 3);
	TextDrawLetterSize(g_MovieModeTD[ 1 ], 0.529999, 2.299999);
	TextDrawColor(g_MovieModeTD[ 1 ], -2347265);
	TextDrawSetOutline(g_MovieModeTD[ 1 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 1 ], 1);

	g_MovieModeTD[ 2 ] = TextDrawCreate(530.000000, 414.000000, "Cops and Robbers");
	TextDrawBackgroundColor(g_MovieModeTD[ 2 ], 255);
	TextDrawFont(g_MovieModeTD[ 2 ], 0);
	TextDrawLetterSize(g_MovieModeTD[ 2 ], 0.310000, 1.100000);
	TextDrawColor(g_MovieModeTD[ 2 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 2 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 2 ], 1);

	g_MovieModeTD[ 3 ] = TextDrawCreate(507.000000, 398.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 3 ], 255);
	TextDrawFont(g_MovieModeTD[ 3 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 3 ], 0.500000, -0.400000);
	TextDrawColor(g_MovieModeTD[ 3 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 3 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 3 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 3 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 3 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 3 ], 255);
	TextDrawTextSize(g_MovieModeTD[ 3 ], 620.000000, 0.000000);

	g_MovieModeTD[ 4 ] = TextDrawCreate(530.000000, 385.000000, "www.SFCNR.com");
	TextDrawBackgroundColor(g_MovieModeTD[ 4 ], 255);
	TextDrawFont(g_MovieModeTD[ 4 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 4 ], 0.200000, 1.000000);
	TextDrawColor(g_MovieModeTD[ 4 ], 0xfa4d4cff);
	TextDrawSetOutline(g_MovieModeTD[ 4 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 4 ], 1);

	g_MovieModeTD[ 5 ] = TextDrawCreate(507.000000, 386.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 5 ], 255);
	TextDrawFont(g_MovieModeTD[ 5 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 5 ], 0.500000, 0.799999);
	TextDrawColor(g_MovieModeTD[ 5 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 5 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 5 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 5 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 5 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 5 ], 128);
	TextDrawTextSize(g_MovieModeTD[ 5 ], 620.000000, 0.000000);

    g_AdminOnDutyTD = TextDrawCreate(552.000000, 66.500000, "ADMIN ON DUTY");
	TextDrawBackgroundColor(g_AdminOnDutyTD, 255);
	TextDrawFont(g_AdminOnDutyTD, 1);
	TextDrawLetterSize(g_AdminOnDutyTD, 0.180000, 0.899999);
	TextDrawColor(g_AdminOnDutyTD, -65281);
	TextDrawSetOutline(g_AdminOnDutyTD, 1);
	TextDrawSetProportional(g_AdminOnDutyTD, 1);

	g_PassiveModeTD = TextDrawCreate(555.000000, 66.500000, "PASSIVE MODE" );
	TextDrawBackgroundColor(g_PassiveModeTD, 255);
	TextDrawFont(g_PassiveModeTD, 1);
	TextDrawLetterSize(g_PassiveModeTD, 0.180000, 0.899999);
	TextDrawColor(g_PassiveModeTD, COLOR_GREEN);
	TextDrawSetOutline(g_PassiveModeTD, 1);
	TextDrawSetProportional(g_PassiveModeTD, 1);
	return Y_HOOKS_CONTINUE_RETURN_1;
}

hook OnPlayerConnect( playerid )
{
	if ( ! ( 0 <= playerid < MAX_PLAYERS ) )
		return Y_HOOKS_CONTINUE_RETURN_1;

	p_AchievementTD[ playerid ] = CreatePlayerTextDraw(playerid, 325.000000, 137.000000, "_");
	PlayerTextDrawAlignment(playerid, p_AchievementTD[ playerid ], 2);
	PlayerTextDrawBackgroundColor(playerid, p_AchievementTD[ playerid ], 80);
	PlayerTextDrawFont(playerid, p_AchievementTD[ playerid ], 1);
	PlayerTextDrawLetterSize(playerid, p_AchievementTD[ playerid ], 0.209999, 1.000000);
	PlayerTextDrawColor(playerid, p_AchievementTD[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_AchievementTD[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_AchievementTD[ playerid ], 1);

	p_GPSInformation[ playerid ] = CreatePlayerTextDraw(playerid, 26.000000, 200.000000, "~g~Location:~w~ No-where~n~~g~Distance:~w~ 0.0m");
	PlayerTextDrawBackgroundColor(playerid, p_GPSInformation[ playerid ], 255);
	PlayerTextDrawFont(playerid, p_GPSInformation[ playerid ], 2);
	PlayerTextDrawLetterSize(playerid, p_GPSInformation[ playerid ], 0.209999, 1.099999);
	PlayerTextDrawColor(playerid, p_GPSInformation[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_GPSInformation[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_GPSInformation[ playerid ], 1);

	p_TrackPlayerTD[ playerid ] = CreatePlayerTextDraw(playerid, 571.000000, 258.000000, "Loading~n~~w~NaN.0m");
	PlayerTextDrawAlignment(playerid, p_TrackPlayerTD[ playerid ], 2);
	PlayerTextDrawBackgroundColor(playerid, p_TrackPlayerTD[ playerid ], 80);
	PlayerTextDrawFont(playerid, p_TrackPlayerTD[ playerid ], 1);
	PlayerTextDrawLetterSize(playerid, p_TrackPlayerTD[ playerid ], 0.260000, 1.100000);
	PlayerTextDrawColor(playerid, p_TrackPlayerTD[ playerid ], COLOR_RED);
	PlayerTextDrawSetOutline(playerid, p_TrackPlayerTD[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_TrackPlayerTD[ playerid ], 1);

	p_TruckingTD[ playerid ] = CreatePlayerTextDraw(playerid, 26.000000, 220.000000, "~b~Location:~w~ No-where~n~~b~Distance:~w~ 0.0m");
	PlayerTextDrawBackgroundColor(playerid, p_TruckingTD[ playerid ], 255);
	PlayerTextDrawFont(playerid, p_TruckingTD[ playerid ], 2);
	PlayerTextDrawLetterSize(playerid, p_TruckingTD[ playerid ], 0.210000, 1.100000);
	PlayerTextDrawColor(playerid, p_TruckingTD[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_TruckingTD[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_TruckingTD[ playerid ], 1);

	p_HelpBoxTD[ playerid ] = CreatePlayerTextDraw(playerid, 30.000000, 161.000000, "... Loading Help ...");
	PlayerTextDrawBackgroundColor(playerid, p_HelpBoxTD[ playerid ], 255);
	PlayerTextDrawFont(playerid, p_HelpBoxTD[ playerid ], 1);
	PlayerTextDrawLetterSize(playerid, p_HelpBoxTD[ playerid ], 0.219999, 1.200000);
	PlayerTextDrawColor(playerid, p_HelpBoxTD[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_HelpBoxTD[ playerid ], 0);
	PlayerTextDrawSetProportional(playerid, p_HelpBoxTD[ playerid ], 1);
	PlayerTextDrawSetShadow(playerid, p_HelpBoxTD[ playerid ], 1);
	PlayerTextDrawUseBox(playerid, p_HelpBoxTD[ playerid ], 1);
	PlayerTextDrawBoxColor(playerid, p_HelpBoxTD[ playerid ], 117);
	PlayerTextDrawTextSize(playerid, p_HelpBoxTD[ playerid ], 170.000000, 0.000000);

  	g_ZoneOwnerTD[ playerid ] = CreatePlayerTextDraw( playerid, 86.000000, 296.000000, "_" );
	PlayerTextDrawAlignment( playerid, g_ZoneOwnerTD[ playerid ], 2 );
	PlayerTextDrawBackgroundColor( playerid, g_ZoneOwnerTD[ playerid ], 255 );
	PlayerTextDrawFont( playerid, g_ZoneOwnerTD[ playerid ], 1 );
	PlayerTextDrawLetterSize( playerid, g_ZoneOwnerTD[ playerid ], 0.250000, 1.200000 );
	PlayerTextDrawColor( playerid, g_ZoneOwnerTD[ playerid ], -1 );
	PlayerTextDrawSetOutline( playerid, g_ZoneOwnerTD[ playerid ], 1 );

	p_JailTimeTD[ playerid ] = CreatePlayerTextDraw(playerid, 328.000000, 24.000000, "Time Remaining:~n~250 seconds");
	PlayerTextDrawAlignment(playerid, p_JailTimeTD[ playerid ], 2);
	PlayerTextDrawBackgroundColor(playerid, p_JailTimeTD[ playerid ], 85);
	PlayerTextDrawFont(playerid, p_JailTimeTD[ playerid ], 1);
	PlayerTextDrawLetterSize(playerid, p_JailTimeTD[ playerid ], 0.329999, 1.500000);
	PlayerTextDrawColor(playerid, p_JailTimeTD[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_JailTimeTD[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_JailTimeTD[ playerid ], 1);

	p_LocationTD[ playerid ] = CreatePlayerTextDraw( playerid, 86.000000, 322.000000, "Loading..." );
	PlayerTextDrawAlignment( playerid, p_LocationTD[ playerid ], 2 );
	PlayerTextDrawBackgroundColor( playerid, p_LocationTD[ playerid ], 255 );
	PlayerTextDrawFont( playerid, p_LocationTD[ playerid ], 1 );
	PlayerTextDrawLetterSize( playerid, p_LocationTD[ playerid ], 0.240000, 1.299999 );
	PlayerTextDrawSetOutline( playerid, p_LocationTD[ playerid ], 1 );
	PlayerTextDrawColor( playerid, p_LocationTD[ playerid ], -1 );
	PlayerTextDrawSetProportional( playerid, p_LocationTD[ playerid ], 1 );

	p_ExperienceTD[ playerid ] = CreatePlayerTextDraw( playerid, 529.000000, 414.000000, "00000000" );
	PlayerTextDrawBackgroundColor( playerid, p_ExperienceTD[ playerid ], 144 );
	PlayerTextDrawFont( playerid, p_ExperienceTD[ playerid ], 3 );
	PlayerTextDrawLetterSize( playerid, p_ExperienceTD[ playerid ], 0.569999, 2.199999 );
	PlayerTextDrawColor( playerid, p_ExperienceTD[ playerid ], COLOR_GOLD );
	PlayerTextDrawSetOutline( playerid, p_ExperienceTD[ playerid ], 1 );
	PlayerTextDrawSetProportional( playerid, p_ExperienceTD[ playerid ], 1 );

	p_WantedLevelTD[ playerid ] = CreatePlayerTextDraw( playerid, 555.000000, 124.000000, "_" );
	PlayerTextDrawAlignment( playerid, p_WantedLevelTD[ playerid ], 2 );
	PlayerTextDrawBackgroundColor( playerid, p_WantedLevelTD[ playerid ], 255 );
	PlayerTextDrawFont( playerid, p_WantedLevelTD[ playerid ], 2 );
	PlayerTextDrawLetterSize( playerid, p_WantedLevelTD[ playerid ], 0.280000, 1.299999 );
	PlayerTextDrawColor( playerid, p_WantedLevelTD[ playerid ], -1872621313 );
	PlayerTextDrawSetOutline( playerid, p_WantedLevelTD[ playerid ], 1 );
	PlayerTextDrawSetProportional( playerid, p_WantedLevelTD[ playerid ], 1 );
	PlayerTextDrawSetSelectable( playerid, p_WantedLevelTD[ playerid ], 0 );

	p_CoinsTD[ playerid ] = CreatePlayerTextDraw( playerid, 529.000000, 360.000000, "000000.0" );
	PlayerTextDrawBackgroundColor( playerid, p_CoinsTD[ playerid ], 255 );
	PlayerTextDrawFont( playerid, p_CoinsTD[ playerid ], 3 );
	PlayerTextDrawLetterSize( playerid, p_CoinsTD[ playerid ], 0.320000, 1.299998 );
	PlayerTextDrawColor( playerid, p_CoinsTD[ playerid ], COLOR_GOLD );
	PlayerTextDrawSetOutline( playerid, p_CoinsTD[ playerid ], 1 );
	PlayerTextDrawSetProportional( playerid, p_CoinsTD[ playerid ], 1 );

	p_PlayerRankTD[ playerid ] = CreatePlayerTextDraw( playerid, 603.000000, 386.000000, "RANK" );
	PlayerTextDrawBackgroundColor( playerid, p_PlayerRankTD[ playerid ], 0 );
	PlayerTextDrawFont( playerid, p_PlayerRankTD[ playerid ], 5 );
	PlayerTextDrawLetterSize( playerid, p_PlayerRankTD[ playerid ], 0.519999, 4.000000 );
	PlayerTextDrawColor( playerid, p_PlayerRankTD[ playerid ], -1027424001 );
	PlayerTextDrawSetOutline( playerid, p_PlayerRankTD[ playerid ], 0 );
	PlayerTextDrawSetProportional( playerid, p_PlayerRankTD[ playerid ], 1 );
	PlayerTextDrawSetShadow( playerid, p_PlayerRankTD[ playerid ], 1 );
	PlayerTextDrawUseBox( playerid, p_PlayerRankTD[ playerid ], 1 );
	PlayerTextDrawBoxColor( playerid, p_PlayerRankTD[ playerid ], 0 );
	PlayerTextDrawTextSize( playerid, p_PlayerRankTD[ playerid ], 19.000000, 19.000000 );
	PlayerTextDrawSetPreviewModel( playerid, p_PlayerRankTD[ playerid ], 19782 );
	PlayerTextDrawSetPreviewRot( playerid, p_PlayerRankTD[ playerid ], 90.000000, 0.000000, 90.000000, 0.600000 );

	p_PlayerRankTextTD[ playerid ] = CreatePlayerTextDraw( playerid, 529.000000, 386.000000, "Silver-1" );
	PlayerTextDrawBackgroundColor( playerid, p_PlayerRankTextTD[ playerid ], 255 );
	PlayerTextDrawFont( playerid, p_PlayerRankTextTD[ playerid ], 3 );
	PlayerTextDrawLetterSize( playerid, p_PlayerRankTextTD[ playerid ], 0.379999, 1.899999 );
	PlayerTextDrawColor( playerid, p_PlayerRankTextTD[ playerid ], -1027424001 );
	PlayerTextDrawSetOutline( playerid, p_PlayerRankTextTD[ playerid ], 1 );
	PlayerTextDrawSetProportional( playerid, p_PlayerRankTextTD[ playerid ], 1 );

	p_RobberyRiskTD[ playerid ] = CreatePlayerTextDraw(playerid, 320.000000, 294.000000, "clerk feels very threatened");
	PlayerTextDrawAlignment(playerid, p_RobberyRiskTD[ playerid ], 2);
	PlayerTextDrawBackgroundColor(playerid, p_RobberyRiskTD[ playerid ], 255);
	PlayerTextDrawFont(playerid, p_RobberyRiskTD[ playerid ], 3);
	PlayerTextDrawLetterSize(playerid, p_RobberyRiskTD[ playerid ], 0.200000, 0.900000);
	PlayerTextDrawColor(playerid, p_RobberyRiskTD[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_RobberyRiskTD[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_RobberyRiskTD[ playerid ], 1);
	PlayerTextDrawSetSelectable(playerid, p_RobberyRiskTD[ playerid ], 0);

	p_RobberyAmountTD[ playerid ] = CreatePlayerTextDraw(playerid, 320.000000, 280.000000, "Robbed ~g~~h~$1,800");
	PlayerTextDrawAlignment(playerid, p_RobberyAmountTD[ playerid ], 2);
	PlayerTextDrawBackgroundColor(playerid, p_RobberyAmountTD[ playerid ], 255);
	PlayerTextDrawFont(playerid, p_RobberyAmountTD[ playerid ], 3);
	PlayerTextDrawLetterSize(playerid, p_RobberyAmountTD[ playerid ], 0.340000, 1.300000);
	PlayerTextDrawColor(playerid, p_RobberyAmountTD[ playerid ], -1);
	PlayerTextDrawSetOutline(playerid, p_RobberyAmountTD[ playerid ], 1);
	PlayerTextDrawSetProportional(playerid, p_RobberyAmountTD[ playerid ], 1);
	PlayerTextDrawSetSelectable(playerid, p_RobberyAmountTD[ playerid ], 0);
	return Y_HOOKS_CONTINUE_RETURN_1;
}


/* ** Hooked Functions ** */
/*stock Text: TD_TextDrawCreate( Float: x, Float: y, text[ ] )
{
	static count;
	printf("%d", ++count);
	return TextDrawCreate( x, y, text );
}

#if defined _ALS_TextDrawCreate
    #undef TextDrawCreate
#else
    #define _ALS_TextDrawCreate
#endif

#define TextDrawCreate TD_TextDrawCreate*/

/*stock PlayerText: TD_CreatePlayerTextDraw( playerid, Float: x, Float: y, text[ ] )
{
	static count;
	printf("%d", ++count);
	return CreatePlayerTextDraw( playerid, x, y, text );
}

#if defined _ALS_CreatePlayerTextDraw
    #undef CreatePlayerTextDraw
#else
    #define _ALS_CreatePlayerTextDraw
#endif

#define CreatePlayerTextDraw TD_CreatePlayerTextDraw*/
