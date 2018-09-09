/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr/textrdraws
 * Purpose:
 */

#define MAX_MACHINES 				54 // Placed top because of textdraws (TEMPORARY / HOTFIX)

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
	Text:  g_AnimationTD            = Text: INVALID_TEXT_DRAW,
	Text:  g_AdminLogTD         	= Text: INVALID_TEXT_DRAW,
	Text:  g_ProgressBoxTD        	= Text: INVALID_TEXT_DRAW,
	Text:  g_AdminOnDutyTD          = Text: INVALID_TEXT_DRAW,
	Text:  g_VehiclePreviewBoxTD 	= Text: INVALID_TEXT_DRAW,
	Text:  g_VehiclePreviewTxtTD	= Text: INVALID_TEXT_DRAW,
	Text:  p_VehiclePreviewCloseTD	= Text: INVALID_TEXT_DRAW,
	Text:  g_DoubleXPTD				= Text: INVALID_TEXT_DRAW,
	Text:  g_currentXPTD 			= Text: INVALID_TEXT_DRAW,
	Text:  g_CurrentRankTD 			= Text: INVALID_TEXT_DRAW,
	Text:  g_CurrentCoinsTD 		= Text: INVALID_TEXT_DRAW,
	Text:  g_SlotMachineOneTD		[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_SlotMachineTwoTD		[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_SlotMachineFigureTD 	[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_SlotMachineThreeTD		[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_SlotMachineBoxTD		[ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_TopDonorTD				= Text: INVALID_TEXT_DRAW,
	Text:  g_NotManyPlayersTD		= Text: INVALID_TEXT_DRAW,

	// Server Player Textdraws (Needs Converting)
	Text:  p_TrackPlayerTD     		[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_FireDistance1        	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_FireDistance2         	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_AchievementTD          [ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_GPSInformation        	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_ProgressBoxOutsideTD	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_ProgressBoxTD        	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_ProgressTitleTD      	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_HelpBoxTD 				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_TruckingTD 			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },

	// Player Textdraws
	PlayerText: p_LocationTD		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_ExperienceTD   	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_ExperienceAwardTD	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_WantedLevelTD		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_CoinsTD        	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_PlayerRankTD 		[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_PlayerRankTextTD 	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_RobberyAmountTD 	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_RobberyRiskTD 	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_DamageTD          [ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: p_JailTimeTD     	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },
	PlayerText: g_ZoneOwnerTD     	[ MAX_PLAYERS ] = { PlayerText: INVALID_TEXT_DRAW, ... },

	PlayerText: p_VehiclePreviewTD 	[ 7 ] = { PlayerText: INVALID_TEXT_DRAW, ... }
;
