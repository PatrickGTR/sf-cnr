/*
 *
 *      	    Call of Duty For SA-MP
 *
 *      		Created all by Lorenc_
 *
 *
 *      Thanks to: y_less/zeex/Frosha/Incognito/SA-MP team
 *
 *
 *

 * 	<object model="{model}" posX="{x}" posY="{y}" posZ="{z}" rotX="{rx}" rotY="{ry}" rotZ="{rz}"/>
*/


/* ** Includes ** */
#include 							< a_samp >
#include 							< a_http >
#include 							< a_mysql >

#include 							< streamer >
#include 							< sscanf2 >
#include 							< zcmd >
#include 							< foreach >
#include 							< mapandreas >
#include 							< gvar >
#include 							< regex >
#include 							< YSI\y_va >
#include                            < md-sort >
#include 							< progress >
#include                            < lookupffs >
// #include                            < irc >
#include 							< FloodControl >
#include 							< filemanager >
#include 							< FCNPC >
native WP_Hash						( buffer[ ], len, const str[ ] );
native gpci 						( playerid, serial[ ], len );

/* ** IG CONFIG ** */
// #define DEBUG_MODE
#include 							< a_ig >

#if !defined AC_INCLUDED
	#include 						< anticheat\global >
	#include 						< anticheat\player >

	#include 						< anticheat\weapon >
	//#include 						< anticheat\spectate >
	#include 						< anticheat\airbrake >
	#include 						< anticheat\proaim >
	#include 						< anticheat\autocbug >
	#include 						< anticheat\flying >
	#include 						< anticheat\remotejack > // Works fine

	#include 						< anticheat\hooks >

	#include 						< anticheat\hitpoints >  // Good

	#define AC_INCLUDED
#endif

/* ** Useful macros ** */
#define RandomEx(%1,%2)				(random(%2-%1)+%1)
#define fRandomEx(%1,%2)			(floatrandom(%2-%1)+%1)
#define class%1(%2)                 forward%1(%2);public%1(%2)
#define HOLDING(%0)             	((newkeys & (%0)) == (%0))
#define IsPlayerLorenc(%0) 			(g_userData[%0][E_ID]==1)
#define PRESSED(%0)					(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define IsPlayerSpawned(%1)     	(p_Spawned{%1})
#define strmatch(%1,%2) 			(!strcmp(%1,%2,true))
#define IsPlayerInMatch(%1)         (p_Team[%1] != NO_TEAM)
#define KEY_AIM                     (128)
#define isodd(%0)					(%0 % 2)
#define NaN 						(0x7FFFFFFF)
#define KillstreakToString(%0) 		(g_killstreakData[(%0)][E_NAME])
#define thread               		class
#define Beep(%1)              		PlayerPlaySound(%1, 1137, 0.0, 0.0, 5.0)
#define TimeStampPassed(%1,%2)   	((GetTickCount()-%1)>(%2))
#define IsPlayerSpectating(%0)		(GetPlayerState(%0) == PLAYER_STATE_SPECTATING)
#define IsPlayerInMultiplayer(%0)	Iter_Contains(mp_players,%0)
#define IsPlayerUsingRadio(%0)		p_UsingRadio{%0}
#define IsPlayerInZombies(%0)		Iter_Contains(zm_players,%0)
#define IsPlayerAFK(%0)				((GetTickCount()-p_AFKTimestamp[%0])>=2595)
#define IsPlayerAFKFor(%0,%1) 		((GetTickCount()-p_AFKTimestamp[%0])>=%1)
#define IsPlayerScreenFading(%0)    (p_BoxFading{%0})
#define IsValidPlayerID(%0) 		(%0 >= 0 && %0 < MAX_PLAYERS)
#define IsPlayerAdminOnDuty(%0)     p_AdminOnDuty{%0}
#define GetPlayerCash(%1)           g_userData[%1][E_CASH]
#define SelectionHelp:: 			sh_

/* Beast Functions */
new bool: False = false, szNormalString[ 144 ];
#define SendClientMessageToAllFormatted(%1,%2,%3)\
	do{format(szNormalString,sizeof(szNormalString),(%2),%3),SendClientMessageToAll((%1),szNormalString);}while(False)
#define SendClientMessageToModeFormatted(%0,%1,%2,%3)\
	do{format(szNormalString,sizeof(szNormalString),(%2),%3),SendClientMessageToMode(%0,(%1),szNormalString);}while(False)
#define SendClientMessageToAdmins(%1,%2,%3)\
	do{foreach(new fI : Player){if (g_userData[fI][E_ADMIN]>0)format(szNormalString,sizeof(szNormalString),(%2),%3),SendClientMessage(fI,(%1),szNormalString);}}while(False)
#define SendClientMessageToTeam(%0,%1,%2,%3)\
	do{foreach(new fI : Player){if (p_Team[fI]==%0)format(szNormalString,sizeof(szNormalString),(%2),%3),SendClientMessage(fI,(%1),szNormalString);}}while(False)
#define AddAdminLogLineFormatted(%0,%1)\
	do{format(szNormalString,90,(%0),%1),AddAdminLogLine(szNormalString);}while(False)

#define mysql_single_query(%0) 		mysql_function_query(dbHandle,(%0),true,"","")

/* ** Configuration ** */
#define FILE_BUILD                	"2.0.0"
#define SERVER_NAME                 "Call Of Duty For SA-MP"
#define SERVER_WEBSITE 				"www.irresistiblegaming.com"

#define ADMIN_COMMAND_REJECT        "You don't have a appropriate administration level to use this command."
#define sscanf_u					"u"

#define MATCH_TIME                  ( 600 ) // Default 600 (seconds)
#define COUNTDOWN_TIME				( 15 ) // Default 15 (seconds)

#undef  MAX_PLAYERS
#define MAX_ZOMBIES 				( 59 )
#define MAX_PLAYERS                 ( 73 )
//#define MAX_WEAPONS					( 54 )

#define MAX_CLAYMORES               ( 30 )
#define THROWINGKNIFE_SPEED 		( 15.0 )
#define MAX_C4                      ( 2 )

#define TEAM_TROPAS                 1
#define TEAM_OP40                   2
#define MAX_TEAMS                   3
#define TEAM_SURVIVORS 				777 // Exclude from count as MAX_TEAMS is only for MP

#define MP_MAPS_DIRECTORY 			"COD/mp/"
#define ZM_MAPS_DIRECTORY 			"COD/zm/"

#define CUSTOM_SHOOTING 			false // untoggle if fixed internally

#if CUSTOM_SHOOTING == true
	#undef MAX_WEAPONS

	#include <a_weapondata>
	#include <a_angles>
#endif

enum
{
	// Modes
	MODE_MULTIPLAYER,
	MODE_ZOMBIES,
	MODE_NONE
};

/* ** Colours ** */
#define COL_GREEN               	"{6EF83C}"
#define COL_RED                 	"{F81414}"
#define COL_BLUE		           	"{00C0FF}"
#define COL_GOLD                	"{FFDC2E}"
#define COL_GREY                    "{C0C0C0}"
#define COL_WHITE                 	"{FFFFFF}"
#define COL_ORANGE                  "{EE9911}"
#define COL_YELLOW                  "{FFFF00}"
#define COL_AC                      "{FF7500}"
#define COL_ADMIN                 	"{6DFF05}"
#define COLOR_ADMIN 				0x6DFF05FF
#define COLOR_PINK                  0xFF0770FF
#define COLOR_WHITE					0xFFFFFFFF
#define COLOR_GREEN             	0x00CC00FF
#define COLOR_RED               	0xFF0000FF
#define COLOR_YELLOW            	0xFFFF00FF
#define COLOR_ORANGE            	0xEE9911FF
#define COLOR_GREY                  0xC0C0C0FF
#define COLOR_GOLD                  0xFFDC2EFF

#define COLOR_TROPAS	       		0x00A8FFE8
#define COLOR_OP40          		0xF31B1DE8

#define COLOR_ZOMBIE 				0xFF1A1AFF // 0x1A1A1AFF
#define COLOR_BOOMER 				0xFF8C1AFF
#define COLOR_TANK 					0xFFFF1AFF

/* ** Dialogs ** */
#define DIALOG_TITLE            	"{FFFFFF}"#SERVER_NAME""
#define DIALOG_NULL                	0                   +1000
#define DIALOG_LOGIN                1                   +1000
#define DIALOG_REGISTER         	2                   +1000
#define DIALOG_MAIN_MENU            3                   +1000
#define DIALOG_CREATE_CLASS         4                   +1000
#define DIALOG_TEAM_MENU            5                   +1000
#define DIALOG_MODIFY_ACCOUNT       6                   +1000
#define DIALOG_MODIFY_PASSWORD      7                   +1000
#define DIALOG_MODIFY_DEL_STATS   	8                   +1000
#define DIALOG_MODIFY_PRESTIGE    	9                   +1000
#define DIALOG_RENAME         		10                  +1000
#define DIALOG_MODIFY_HITMARKER 	11                  +1000
#define DIALOG_MODIFY_HM_SOUND   	12                  +1000
#define DIALOG_STATS       			13                  +1000
#define DIALOG_STATS_REDIRECT       14                  +1000
#define DIALOG_SHOP_WEAPONS       	15                  +1000
#define DIALOG_ZPRESTIGE_ZONE       16                  +1000
#define DIALOG_RADIO      			17                  +1000
#define DIALOG_ZOMBIE_MENU  		18                  +1000
#define DIALOG_CHOOSE_CLASS         19                  +1000
#define DIALOG_CHOOSE_KS			20                  +1000
#define DIALOG_BANNED				21                  +1000
#define DIALOG_RADIO_CUSTOM 		22 					+1000
#define DIALOG_CREATE_CLASS_VIP		23 					+1000
#define DIALOG_CAC_VIP_WEP			24 					+1000
#define DIALOG_CAC_VIP_SKIN 		25 					+1000
#define DIALOG_CHOOSE_VIPSKIN 		26 					+1000
#define DIALOG_VIP 					27 					+1000
#define DIALOG_DONATED				28 					+1000
#define DIALOG_MODIFY_ZMSKIN 		29 					+1000
#define DIALOG_MODIFY_ZMPRESTIGE 	30 					+1000
#define DIALOG_MP_NEXTMAP 			31					+1000
#define DIALOG_ZM_NEXTMAP			32					+1000

/* ** MENUS ** */
#define MENU_PRIMARY 				0
#define MENU_SECONDARY 				1
#define MENU_PERKS 					2
#define MENU_KILLSTREAKS 			3
#define MENU_SPECIAL 				4
#define MENU_SKINS 					5

/* ** PROGRESS ID ** */
#define PROGRESS_HEALING 			0

/* ** MODES ** */
#define MAX_MODES                   (3)

#define MODE_TDM                    (0)
#define MODE_CTF                    (1)
#define MODE_KC                     (2)

/* ** Perks ** */
#define PERK_STOPPING_POWER         0   // Increases more bullet damage     +
#define PERK_BANDOLIER         		1   // More mags on spawn               +
#define PERK_SCAVENGER              2   // Scavenge dead bodies             +
#define PERK_ASSASSIN               3   // Hide from radar                  +
#define PERK_RPG	            	4   // 1x RPG                           +

#define PERK_STEADY_AIM             0   // Steady aiming                    +
#define PERK_QUICKFIX               1   // Increases speed of healing       +
#define PERK_HARDLINE               2   // 1 kill less for a killstreak     +
#define PERK_BLAST_SHIELD           3   // Extra ammo on spawn.             +
#define PERK_SONIC_BOOM	           	4   // Increases explosive damage       +

/* ** Equipment ** */
#define EQUIPMENT_GRENADE         	0 // +
#define EQUIPMENT_SMOKE             1 // +
#define EQUIPMENT_CLAYMORE         	2 // +
#define EQUIPMENT_C4                3 // +
#define EQUIPMENT_INSERTION       	4 // +
#define EQUIPMENT_SCRAMBLER         5 // +
#define EQUIPMENT_TOMAHAWK       	6 // +

/* ** Killstreaks ** */
#define MAX_KILLSTREAKS             (sizeof(g_killstreakData))

#define MAX_CAREPACKAGES 			( 10 )

#define KS_RCXD                    	0 // +
#define KS_UAV                      1 // +
#define KS_COUNTER_UAV              2 // +
#define KS_CARE_PACKAGE             3 // +
#define KS_MORTAR_TEAM              4 // +
#define KS_AGR            			5 // +
#define KS_LIGHTNING_STRIKE         6 // +
#define KS_VTOL_WARSHIP           	7 // +
#define KS_NUKE                     8 // +

enum E_KILLSTREAK_DATA
{
	E_ID,                           E_NAME[ 24 ],                   E_KILLS
};

enum E_WARSHIP_DATA
{
	Float: E_DEGREE,            	Float: E_X,         			Float: E_Y,
	Float: E_Z,                     E_TIMER,                        bool: E_OCCUPIED,
	E_MISSILE,						E_PLAYER_ID
};

enum E_CAREPACKAGE_DATA
{
	E_PACKAGE,						E_FLARE,						bool: E_CAPTURING
};

new
	g_killstreakData[ ] [ E_KILLSTREAK_DATA ] =
	{
	    { KS_RCXD,          		"RC-XD",            			3 },
	    { KS_UAV,           		"UAV",              			4 },
	    { KS_COUNTER_UAV,   		"Counter-UAV",      			5 },
	    { KS_CARE_PACKAGE,  		"Care Package",     			6 },
	    { KS_MORTAR_TEAM,   		"Mortar Team",      			9 },
	    { KS_AGR,      				"AGR",           				10 },
	    { KS_LIGHTNING_STRIKE,    	"Lightning Strike",             13 },
	    { KS_VTOL_WARSHIP,          "VTOL Warship",                	16 },
	    { KS_NUKE,          		"Tactical Nuke",                25 }
	},
	g_warshipData					[ E_WARSHIP_DATA ],
	g_carePackageData				[ MAX_CAREPACKAGES ] [ E_CAREPACKAGE_DATA ],
	g_LightningStrikeTimer			= 0xFFFF,
	g_LightningStrikeUser 			= INVALID_PLAYER_ID,
	g_LightningStrikeObject 		= INVALID_OBJECT_ID,
	bool: g_TacticalNuke 			= false,
	g_TacticalNukeTime   			= 15,

	// Iterators
	Iterator:carepackages< MAX_CAREPACKAGES >
;

/* ** Menu Data ** */
enum E_HITMARKER_SOUND
{
	E_NAME[ 10 ],					E_SOUND_ID
};

new const
	g_MenuType[ ] [ ] =
	{
		{ 29, 25, 30, 31, 27, 26, 33, 34, 28, 32 },
		{ 23, 22, 24 },
		{ 0, 1, 2, 3, 4, 0, 1, 2, 3, 4 },
		{ 0, 1, 2, 3, 4, 5, 6, 7, 8 },
		{ 0, 1, 2, 3, 4, 5, 6, 7 }
	},

	g_MenuMaximumIterations[ ] =
	{
		10, 3, 10, 9, 8
	},

	g_HitmarkerSounds[ ] [ E_HITMARKER_SOUND ] =
	{
		{ "Bell Ding", 17802 },
		{ "Blunt Hit", 1131 },
		{ "Reg. Hit", 1135 },
		{ "Loud Hit", 1095 },
		{ "Punch A", 1130 },
		{ "Dent", 1009 },
		{ "Clunk", 1095 },
		{ "Slap", 1190 }
	}
;

/* ** Textdraw Data ** */
new
	Text: g_RoundStartNote          = Text: INVALID_TEXT_DRAW,
	Text: g_RoundStartTimeTD		= Text: INVALID_TEXT_DRAW,
	Text: g_RoundTimeTD             = Text: INVALID_TEXT_DRAW,
	Text: g_RoundBoxWhereTeam       = Text: INVALID_TEXT_DRAW,
	Text: p_RoundPlayerTeam			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_tropasRoundBox          = Text: INVALID_TEXT_DRAW,
	Text: g_tropasScoreText         = Text: INVALID_TEXT_DRAW,
	Text: g_op40RoundBox            = Text: INVALID_TEXT_DRAW,
	Text: g_op40ScoreText           = Text: INVALID_TEXT_DRAW,
	Text: g_RoundGamemodeTD         = Text: INVALID_TEXT_DRAW,
	Text: g_ShortPlayerNoticeTD		= Text: INVALID_TEXT_DRAW,
	Text: g_Scoreboard              [ 18 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ScoreboardNames      	[ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ScoreboardKills      	[ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ScoreboardDeaths    	[ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ScoreboardScores    	[ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ScoreboardTeamScore    	[ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_CameraVectorAim         [ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_KillstreakInstructions	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_KillstreakAnnTD			= Text: INVALID_TEXT_DRAW,
	Text: g_TacticalNukeMissileTD 	= Text: INVALID_TEXT_DRAW,
	Text: g_TacticalNukeTimeTD		= Text: INVALID_TEXT_DRAW,
	Text: g_AdminLogTD				= Text: INVALID_TEXT_DRAW,
	Text: p_XPGivenTD				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ClassName				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ClassPrimary			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ClassSecondary			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ClassMenu				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ClassCustom				[ 7 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ClassConfig				[ 6 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_ClassKSSlots			[ 3 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ExperienceTD        	[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_RankDataTD				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_WebsiteTD        		[ 2 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_PromotedTD				= Text: INVALID_TEXT_DRAW,
	Text: g_HideCashBoxTD			= Text: INVALID_TEXT_DRAW,
	Text: p_NewRankTD				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_DamageTD 				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ClassSetupTD			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_KillstreakSetupTD		[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_GameMenuTD 				[ 5 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_MovieModeTD            	[ 8 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_MotdTD               	= Text: INVALID_TEXT_DRAW,
	Text: p_SelectionHelpTD 		[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },

	// Zombies
	Text: g_EvacuationTD 			= Text: INVALID_TEXT_DRAW,
	Text: p_FadeBoxTD               [ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ProgressCircleTD 		[ 60 ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_ProgressTextTD 			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_RankBoxTD 				= Text: INVALID_TEXT_DRAW,
	Text: g_RankTD 					= Text: INVALID_TEXT_DRAW,
	Text: g_SpectateBoxTD        	= Text: INVALID_TEXT_DRAW,
	Text: g_SpectateTD				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_XPAmountTD				[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: p_RankTD					[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	Text: g_BittenBoxTD             = Text: INVALID_TEXT_DRAW,

	// Player Text
	PlayerText: p_ClassOptions		[ 20 ] = { PlayerText: INVALID_TEXT_DRAW, ... }
;

/* ** [MP] Map System ** */
#define MAX_MP_MAPS                    ( 30 )
enum E_MP_MAP_DATA
{
	E_NAME[ 32 ],           E_AUTHOR[ 24 ], 			E_INTERIOR,
	E_WEATHER, 				E_WORLD,					bool: E_GROUND_Z,

	E_SKIN_1, 				E_SKIN_2,

	// COD SPAWNS
	Float: E_MINX1, 		Float: E_MAXX1,				Float: E_MINY1,
	Float: E_MAXY1, 		Float: E_MINX2,				Float: E_MAXX2,
	Float: E_MINY2, 		Float: E_MAXY2,				Float: E_MAPZ1,
	Float: E_MAPZ2,
};

new
	g_mp_mapData						[ MAX_MP_MAPS ] [ E_MP_MAP_DATA ],
	Iterator:maps< MAX_MP_MAPS >
;


/* ** Map System ** */
#define MAX_ZM_MAPS                    ( 10 )
enum E_ZM_MAP_DATA
{
	E_NAME[ 32 ],       	E_AUTHOR[ 24 ],     		Float: E_HELI_X,
	Float: E_HELI_Y, 		Float: E_HELI_Z,  			E_ZSPAWNS,
	E_HSPAWNS, 				E_WORLD
};

new
 	g_zm_mapData                	[ MAX_ZM_MAPS ] [ E_ZM_MAP_DATA ],
	Float: g_mapHumanSpawnData   	[ MAX_ZM_MAPS ] [ 3 ] [ 3 ],
	Float: g_mapZombieSpawnData   	[ MAX_ZM_MAPS ] [ 3 ] [ 3 ],

	Iterator:zm_maps<MAX_ZM_MAPS>
;

/* ** Zombie Data ** */
#define SKIN_ZOMBIE                 ( 162 )
#define SKIN_BOOMER                 ( 264 )
#define SKIN_TANK                   ( 149 )

enum E_ZOMBIE_DATA
{
	E_NPCID,    		E_SKINID,   		Float: E_SPAWN_HEALTH,
	bool: E_RESPAWN,	bool: E_PERMITTED, 	Float: E_DAMAGE,
 	Float: E_HEALTH,	Float: E_SPEED,
};

new
	g_zombieData                    [ MAX_ZOMBIES ] [ E_ZOMBIE_DATA ],
	g_ZombieClosest					[ MAX_ZOMBIES ] = { INVALID_PLAYER_ID, ... },
	Float: g_ZombieClosestDistance	[ MAX_ZOMBIES ] = { 99999.0, ... },

	// Iterator
	Iterator:zombies< MAX_ZOMBIES >
;
/* ** Pickup system ** */
#define MAX_DROPPABLE_PICKUPS               ( 40 )

#define PICKUP_TYPE_MONEY 					( 0 )
#define PICKUP_TYPE_WEAPON 					( 1 )
#define PICKUP_TYPE_AMMO 					( 2 )
#define PICKUP_TYPE_HEALTH 					( 3 )

enum E_PICKUP_DATA
{
	bool: E_CREATED,  	bool: E_TANK,   E_PICKUP_ID,
	E_TIMESTAMP,		E_TYPE,			E_AMMO,
	E_WEAPON
};

new
	g_pickupData                    [ MAX_DROPPABLE_PICKUPS ] [ E_PICKUP_DATA ]
;

/* ** DOG TAG SYSTEM ** */
#define TEXT_DOGTAG \
	"___________\n\\_________/\n	'__'\n	'___'\n /'''_____'''\\\n|________|\n|________|\n|________|\n:________:"

enum E_DOGTAG_DATA
{
	E_TEAM_ID,                      E_DIER_ID, 			Float: E_X,
	Float: E_Y, 					Float: E_Z
};

new
	g_dogtagData					[ MAX_PLAYERS ] [ E_DOGTAG_DATA ],
	Text3D: g_dogtagLabel        	[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },

	// Iterators
	Iterator:dogtags<MAX_PLAYERS>
;

/* ** Random Messages ** */
stock const
	g_randomMessages[ ] [ 144 char ] =
	{
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" If you're stuck in water, you can always "COL_GREY"/kill"COL_WHITE" to suicide." },
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" To visit the main menu again, type "COL_GREY"/mainmenu"COL_WHITE"." },
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" If you want to implement hitmarker noises when you shot someone, check your Account Settings." },
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" Using the same class can be boring, but you can always change it with "COL_GREY"/changeclass"COL_WHITE"." },
        { !"{B579E7}Soap Mactavish:"COL_WHITE" Remember to check the "COL_GREY"/rules{FFFFFF}! Disobeying the rules can lead to punishment!" },
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" Seen a cheater? Use "COL_GREY"/report {FFFFFF}to tell an admin." },
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" Have a question? Use "COL_GREY"/ask {FFFFFF}to ask an admin." },
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" Never share your password, not even with the server owner!" },
        { !"{B579E7}Soap Mactavish:"COL_WHITE" Consider helping the community by donating! "COL_GREY"donate.irresistiblegaming.com" },
		{ !"{B579E7}Soap Mactavish:"COL_WHITE" Save us on your favourites so you don't miss out on the action!" },
        { !"{B579E7}Soap Mactavish:"COL_WHITE" Donors receive a V.I.P package in return of their generous donation." },
        { !"{B579E7}Soap Mactavish:"COL_WHITE" Can't be bothered waiting for the next zombies round? Play multiplayer!" },
        { !"{B579E7}Soap Mactavish:"COL_WHITE" Wave still starting and you need weapons? Use "COL_GREY"/shop"COL_WHITE"!" },
        { !"{B579E7}Soap Mactavish:"COL_WHITE" You can catch updates on our website - "#SERVER_WEBSITE"!" }
	}
;

/* ** Admin Ban Codes ** */
enum E_BAN_CODE
{
	E_CODE[ 4 ], 		E_DATA[ 21 ]
};

new
	g_banCodes[ ] [ E_BAN_CODE ] =
	{
		{ "AH",  "Armor Hacking" },
		{ "HH",  "Health Hacking" },
		{ "VHH", "Vehicle Health Hacks" },
		{ "NR",  "No Reload" },
		{ "IA",  "Infinite Ammo" },
		{ "FH",  "Fly Hacks" },
		{ "BE",  "Ban Evasion" },
		{ "AB",  "Air Brake" },
		{ "TP",  "Teleport Hacks" },
		{ "WH",  "Weapon Hack" },
		{ "SH",  "Speed Hacks" },
		{ "UA",  "Unlimited Ammo" },
		{ "RF",  "Rapid Fire" },
		{ "AIM", "Aimbot" },
		{ "ADV", "Advertising" }
	}
;

/* ** Player Data ** */
enum E_USER_DATA
{
	E_ID,							E_KILLS,  			 			E_DEATHS,
	E_ADMIN, 						E_XP, 							E_RANK,
	E_PRESTIGE,      				E_PRIMARY1, 					E_PRIMARY2,
	E_PRIMARY3,      				E_SECONDARY1, 					E_SECONDARY2,
	E_SECONDARY3,     				E_PERK_ONE[ 3 ],				E_PERK_TWO[ 3 ],
	E_SPECIAL[ 3 ],       			E_KILLSTREAK1, 					E_KILLSTREAK2,
	E_KILLSTREAK3,					E_MUTE_TIME,					E_CLASS1[ 32 ],
	E_CLASS2[ 32 ],					E_CLASS3[ 32 ],					E_HITMARKER,
	E_HIT_SOUND, 					E_UPTIME,						E_CASH,
	E_VICTORIES, 					E_LOSSES,						E_ZM_RANK,
	E_ZM_XP,						E_ZM_KILLS,						E_ZM_DEATHS,
	E_LAST_LOGGED,					E_VIP_LEVEL,					E_VIP_EXPIRE,
	E_DOUBLE_XP,					E_LIVES, 						E_MEDKIT,
	E_WEAPONS[ 2 ],					E_SKIN,							E_ZM_PRESTIGE,
	E_ZM_SKIN
};

enum e_match_progress
{
	M_ID,							M_SCORE
};

new
	dbHandle,
	g_userData                      [ MAX_PLAYERS ] [ E_USER_DATA ],
	g_usermatchDataT1              	[ MAX_PLAYERS ] [ e_match_progress ],
	g_usermatchDataT2              	[ MAX_PLAYERS ] [ e_match_progress ],
	bool: p_PlayerLogged            [ MAX_PLAYERS char ],
	p_cac_SelectedClass           	[ MAX_PLAYERS ],
	p_cac_SelectedKillStreak      	[ MAX_PLAYERS ],
	p_SelectedGameClass          	[ MAX_PLAYERS ],
	bool: p_goingtoMenu             [ MAX_PLAYERS ],
	p_Team                          [ MAX_PLAYERS ] = { NO_TEAM, ... },
	p_Spawned                       [ MAX_PLAYERS char ],
	bool: p_StolenFlag              [ MAX_PLAYERS ] [ MAX_TEAMS ],
	bool: p_Aiming                  [ MAX_PLAYERS char ],
	p_AntiSpawnKill                 [ MAX_PLAYERS ],
	bool: p_AntiSpawnKillEnabled    [ MAX_PLAYERS char ],
	bool: p_GotScrambled            [ MAX_PLAYERS char ],
	Float: 	p_InsertionX 			[ MAX_PLAYERS ],
    Float: 	p_InsertionY 			[ MAX_PLAYERS ],
    Float: 	p_InsertionZ 			[ MAX_PLAYERS ],
 	p_InsertionFlare 		        [ MAX_PLAYERS ] = { INVALID_OBJECT_ID, ... },
    Text3D: p_InsertionLabel 		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
   	p_ThrowingkObject        		[ MAX_PLAYERS ] = { INVALID_OBJECT_ID, ... },
   	p_ThrowingkTimer                [ MAX_PLAYERS ] = { 0xFF, ... },
   	p_ThrowingkStep                 [ MAX_PLAYERS ],
    Float: p_Throwing_pX            [ MAX_PLAYERS ],
    Float: p_Throwing_pY          	[ MAX_PLAYERS ],
    Float: p_Throwing_pZ           	[ MAX_PLAYERS ],
    p_ThrowingkPickup 				[ MAX_PLAYERS ] = { INVALID_OBJECT_ID, ... },
	p_C4Amount                      [ MAX_PLAYERS char ],
	p_C4Object                   	[ MAX_PLAYERS ] [ MAX_C4 ],
	bool: justConnected             [ MAX_PLAYERS char ],
	p_EquippedWeapon                [ MAX_PLAYERS char ],
	g_playerKillstreakAmount     	[ MAX_PLAYERS ] [ MAX_KILLSTREAKS ],
	bool: p_Busy                    [ MAX_PLAYERS char ],
    p_AGRVehicle					[ MAX_PLAYERS ] = { INVALID_VEHICLE_ID, ... },
    p_AGRTimer						[ MAX_PLAYERS ] = { 0xFFFF, ... },
    p_RCXDVehicle					[ MAX_PLAYERS ] = { INVALID_VEHICLE_ID, ... },
    p_ConstantVehicleRepair			[ MAX_PLAYERS ] = { 0xFFFF, ... },
    p_Killstreak                    [ MAX_PLAYERS ],
	Float: p_LightningDegree		[ MAX_PLAYERS ],
	p_LightningMode					[ MAX_PLAYERS ],
	p_IncorrectLogins				[ MAX_PLAYERS char ],
	bool: p_AdminLog				[ MAX_PLAYERS char ],
	bool: p_CantUseAsk              [ MAX_PLAYERS char ],
	bool: p_CantUseReport           [ MAX_PLAYERS char ],
	p_Warns							[ MAX_PLAYERS ],
	bool: p_Spectating            	[ MAX_PLAYERS char ],
	bool: p_beingSpectated			[ MAX_PLAYERS ],
	p_whomSpectating				[ MAX_PLAYERS ],
	bool: p_Muted                   [ MAX_PLAYERS char ],
    p_PmResponder                  	[ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... },
  	bool: p_ToggledViewPM        	[ MAX_PLAYERS char ],
	bool: p_BlockedPM            	[ MAX_PLAYERS ] [ MAX_PLAYERS ],
	p_SelectedOption				[ MAX_PLAYERS char ],
	Text3D: p_SpawnKillLabel		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	LastDeath						[ MAX_PLAYERS ],
	DeathSpam						[ MAX_PLAYERS char ],
	p_AntiTextSpamCount				[ MAX_PLAYERS char ],
	p_AntiTextSpam 					[ MAX_PLAYERS ],
	p_AntiCommandSpam				[ MAX_PLAYERS ],
	p_MatchKills					[ MAX_PLAYERS ],
	p_MatchDeaths					[ MAX_PLAYERS ],
	p_DamageTDTimer					[ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... },
	p_TakenDamage					[ MAX_PLAYERS ],
	p_ViewingStats 					[ MAX_PLAYERS ],
	p_AFKTimestamp                  [ MAX_PLAYERS ],
	p_BittenTimestamp 				[ MAX_PLAYERS ],
	p_BoxOcapacity					[ MAX_PLAYERS ],
	p_BoxFadeTimer					[ MAX_PLAYERS ] = { 0xFFFF, ... },
	bool: p_BoxFading				[ MAX_PLAYERS char ],
	p_BittenTimer                   [ MAX_PLAYERS ] = { 0xFFFF, ... },
	bool: p_SpectateMode            [ MAX_PLAYERS char ],
	p_SpectatingPlayer        		[ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... },
	p_LastAnimIndex					[ MAX_PLAYERS ],
	bool: p_ProgressStarted			[ MAX_PLAYERS char ],
	p_ProgressStatus         		[ MAX_PLAYERS char ],
	p_ProgressType                  [ MAX_PLAYERS char ],
	p_WasInMainMenu					[ MAX_PLAYERS char ],
	bool: p_inMovieMode 			[ MAX_PLAYERS char ],
 	p_LastSpawnTime					[ MAX_PLAYERS ],
 	bool: p_UsingRadio 				[ MAX_PLAYERS char ],
 	bool: p_CustomSkin 				[ MAX_PLAYERS char ],
 	bool: p_AdminOnDuty 			[ MAX_PLAYERS char ],
	Text3D: p_AdminLabel         	[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	p_SelectionHelpTimer 			[ MAX_PLAYERS ],
	Float: p_SurfingTomahawkX 		[ MAX_PLAYERS ],
	Float: p_SurfingTomahawkY 		[ MAX_PLAYERS ],
	Float: p_SurfingTomahawkZ 		[ MAX_PLAYERS ]
;

/* ** Essential Includes ** */
#include 							< a_explosion >

/* ** [MP] Server Data ** */
enum E_MP_GAME_SETTINGS
{
	bool: E_STARTED,	 			E_GAMEMODE,             	E_MAP,
	bool: E_STARTING,				E_COUNTDOWN,                E_TIME,
	bool: E_FINISHED,				E_KILLS, 					E_NEXT_MAP
};

new
	g_mp_gameData           		[ E_MP_GAME_SETTINGS ],
    sz_Name                    		[ MAX_PLAYER_NAME ],
    sz_IP                     	  	[ 16 ],
    szBigString                 	[ 256 ],
    szLargeString                   [ 1024 ],
    szHugeString 					[ 2048 ],
	szRules							[ 2048 ],
	log__Text						[ 6 ][ 90 ],
    bool: g_BannedWeapons     		[ MAX_WEAPONS char ],

    Iterator:mp_players<MAX_PLAYERS>,
    Iterator:zm_players<MAX_PLAYERS>,

    g_Blackzone                     = 0xFFFF,
    bool: g_ScopedWeapons       	[ 54 char ],
    bool: g_doubleXP				= false,
    g_PingLimit						= 1600,
    g_AutoBalanceTime 				= 0,

    g_CTFFlag                       [ MAX_TEAMS ] = { 0xFFFF, ... },
    g_CTFFlagPickup                 [ MAX_TEAMS ] = { 0xFFFF, ... },
    g_CTFFlagIcon 					[ MAX_TEAMS ] = { 0xFFFF, ... },
	Text3D: g_CTFLabel              [ MAX_TEAMS ] = { Text3D: 0xFFFF, ... },
	bool: g_CTFFlagStolen           [ MAX_TEAMS char ],
	bool: g_UAVOnline               [ MAX_TEAMS char ],
	bool: g_CounterUAVOnline        [ MAX_TEAMS char ],
	g_UAVTimestamp                  [ MAX_TEAMS ],

    g_TropasMembers                 = 0,
    g_OP40Members                   = 0,
    g_TropasScore                   = 0,
    g_OP40Score                     = 0,
	Float: g_tropasRoundBoxSize 	= Float: 569.000000,
    Float: g_op40RoundBoxSize		= Float: 569.000000,
	Float: g_CountDownX				= Float: 0.0,
	Float: g_CountDownY				= Float: 0.0,
	g_CountDownGrowTimer 			= 0xFFFF,
	g_ServerLocked 					= false,
	g_randomMessageTick 			= 0,

	g_claymoreOwner					[ MAX_CLAYMORES ] = { INVALID_PLAYER_ID, ... },
	g_claymoreObject				[ MAX_CLAYMORES ] = { INVALID_OBJECT_ID, ... },
	bool: p_claymoreDisabled 		[ MAX_PLAYERS char ] = { false, ... },
	Iterator:claymore<MAX_CLAYMORES>,

    g_redeemVipWait					= 0,

    rl_StartRoundTimer              = 0xFF,
    rl_MatchTimer                   = 0xFF,
    rl_ResetMode                    = 0xFF
;

/* ** [ZM] Server Data ** */
#define PREP_TIME					( 30 ) // (30) Preparation Time
#define ROUND_TIME					( 600 ) // (700)
#define STARTING_ZOMBIES 			( 20 ) // Start with 10 zombies?

enum E_SHOP_DATA
{
	E_NAME[ 32 ],   	E_WEPID, 			E_AMMO,
	E_PRICE,            E_RANK
};

enum E_ZM_GAME_SETTINGS
{
	bool: E_EVAC_STARTED, 			E_GAME_ENDED, 				E_MAP,
	bool: E_GAME_STARTED, 			E_NEXT_MAP
};

new
	g_zm_gameData					[ E_ZM_GAME_SETTINGS ],

	g_shopData[ ] [ E_SHOP_DATA ] =
	{
	    { "Armour",             -1,     1,      500,    0 },
	    { "Medikit",        	-1,     1,     	100,	0 },
		{ "Knife", 				4,		1, 		10,		0 },
		{ "Katana", 			8,		1, 		25,		1 },
		{ "Dual Five-Seven",	22,		2, 		150,	1 },
		{ "USP (Silenced)", 	23,		100, 	125,	2 },
		{ "Shotgun", 			25,		300, 	375,	3 },
		{ "Uzi", 				28,		200,	340,	4 },
		{ "Chainsaw", 			9,		1, 		50,		5 },
		{ "Sawn-off Shotgun", 	26,		300,	500,	5 },
		{ "MP5", 				29,		200,	300,	6 },
		{ "FMG9", 				32,		200,	275,	7 },

		{ "AK47", 				30,		350,	300,	8 },
		{ "Combat Shotgun", 	27,		300,	550,	9 },
		{ "M4", 				31,		350,	350,	10 },
		{ "M14", 				33,		150, 	340,	11 },
		{ "Desert Eagle", 		24,		100, 	350,	12 }
	},


	p_PreorderWeapons				[ MAX_PLAYERS ] [ 13 ] [ 2 ],
	bool: p_BoughtDualPistols 		[ MAX_PLAYERS char ],
	bool: p_BoughtArmour 			[ MAX_PLAYERS char ],

	g_EvacuationTime            	= ROUND_TIME,
	g_WaveStarting                  = PREP_TIME, // In seconds - Preparation of zombies.
	g_HelicopterNPC                 = 0xFFFF,
	g_HelicopterVehicle             = INVALID_VEHICLE_ID,
	g_EvacuateCP                    = 0xFFFF,
    g_LastFinishedRound             = -1, // Will be initalized on ongamemodeinit

    // 0 ZOMBIE
    // 1 BOOMER
    // 2 TANK
    g_DeathLogNPC 					[ 3 ] = { INVALID_PLAYER_ID, ... }
;

/* ** Declarations ** */
public OnTwitterHTTPResponse( index, response_code, data[ ] );
public OnDonationRedemptionResponse( index, response_code, data[ ] );
public OnRulesHTTPResponse( index, response_code, data[ ] );
public OnPlayerProgressUpdate( playerid, progressid );
public OnPlayerProgressComplete( playerid, progressid );

main()
{
	print( "Call Of Duty For SA-MP" );
}

public OnGameModeInit( )
{
	/* ** General ** */
	SetGameModeText( "COD4SAMP TDM | ZOMBIES" );
	SetServerRule( "hostname", "Call of Duty For SA-MP (0.3.7) #RESURRECTED" );
	SetServerRule( "language", "All (English)" );
	ShowNameTags( 1 );
	ShowPlayerMarkers( 1 );
	SetNameTagDrawDistance( 25.0 );
	DisableInteriorEnterExits( );
	UsePlayerPedAnims( );
	MapAndreas_Init( MAP_ANDREAS_MODE_FULL );

	/* ** Loading Default Values ** */
	// -> Radio System
	strins( g_RadioStations, ""COL_GREY"Custom URL "COL_GOLD"[V.I.P]"COL_WHITE"\n", 0 );
    for( new i; i < sizeof( g_RadioData ); i++ )
	    format( g_RadioStations, sizeof( g_RadioStations ), "%s%s\n", g_RadioStations, g_RadioData[ i ] [ E_NAME ] );

	// -> Select Map System
	g_mp_gameData[ E_NEXT_MAP ] = -1;
	g_zm_gameData[ E_NEXT_MAP ] = -1;

	/* ** Game Configuration ** */
	cod_LoadMaps( );
	cod_TextDraws( );
	InitializeIGTextdraws( );
	l4d_LoadMaps( );
	l4d_LoadNPC( );

	AddPlayerClass( 164, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0 );
	SetScopedWeapons( 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32 );
	SetBannedWeapons( 36, 37, 38, 39, 44, 45, 43, 42, 41 );

	g_Blackzone = GangZoneCreate( -2977.858, -2966.18, 3012.892, 2989.536 );

	/* ** Database Configuration ** */
	mysql_log( LOG_ERROR );

	dbHandle = mysql_connect( MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS );

	if ( mysql_errno( dbHandle )  )
		print( "[MYSQL]: Couldn't connect to MySQL database." ), g_ServerLocked = true;
	else
		print( "[MYSQL]: Connection to database is successful." );


	/* ** Timer Initiation ** */
	SetTimer( "OnServerUpdate", 500, true ); // Dogtags, anything like a pickup
	SetTimer( "OnOneSecondUpdate", 990, true ); // Interval to update stuff

	// Typically zombies.
	SetTimer( "Movement", 750, true );
	SetTimer( "Round", 980, true );

    g_LastFinishedRound = gettime( ); // So players can only spawn once per match.

    /* ** Loading Screen ** */
    CreateDynamicObject( 1369, -2555.217041, 41.580684, 1022.043090, 0.000000, 0.000000, 190.000000 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, -2554.516357, 47.644672, 1017.543090, 0.000000, 0.000000, 0.000000 ), 0, 14588, "ab_abbatoir01", "ab_tiles", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, -2560.010253, 47.637702, 1022.533020, 0.000000, 0.000000, 90.000000 ), 0, 14588, "ab_abbatoir01", "ab_tileWall", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, -2549.110351, 47.637702, 1022.533020, 0.000000, 0.000000, 90.000000 ), 0, 14588, "ab_abbatoir01", "ab_tileWall", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, -2554.520263, 42.237701, 1026.532958, 0.000000, 0.000000, 0.000000 ), 0, 14588, "ab_abbatoir01", "ab_tileWall", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, -2558.520263, 42.237701, 1019.533020, 0.000000, 0.000000, 0.000000 ), 0, 14588, "ab_abbatoir01", "ab_tileWall", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, -2554.516357, 47.644672, 1027.443115, 0.000000, 0.000000, 0.000000 ), 0, 14588, "ab_abbatoir01", "ab_ceiling1", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, -2548.520263, 42.237701, 1021.533020, 0.000000, 0.000000, 0.000000 ), 0, 14588, "ab_abbatoir01", "ab_tileWall", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, -2548.516357, 37.644672, 1022.543090, 0.000000, 0.000000, 0.000000 ), 0, 8390, "vegasemulticar", "Bow_sub_walltiles", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, -2564.516357, 37.644672, 1022.543090, 0.000000, 0.000000, 0.000000 ), 0, 8390, "vegasemulticar", "Bow_sub_walltiles", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, -2564.510742, 42.237701, 1022.533020, 0.000000, 0.000000, 0.000000 ), 0, 14588, "ab_abbatoir01", "ab_tileWall", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, -2554.516357, 32.644672, 1022.543090, 0.000000, 0.000000, 0.000000 ), 0, 8390, "vegasemulticar", "Bow_sub_walltiles", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18765, -2554.516357, 42.644672, 1027.543090, 0.000000, 0.000000, 0.000000 ), 0, 8390, "vegasemulticar", "Bow_sub_walltiles", 0 );
	CreateDynamicObject( 19325, -2556.546875, 42.240333, 1023.043090, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 1499, -2553.045166, 42.719619, 1020.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1499, -2550.044189, 42.719619, 1020.043090, 0.000000, 0.000000, 180.000000 );
	CreateDynamicObject( 1749, -2556.295410, 47.310279, 1020.193115, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1786, -2556.709960, 46.888534, 1020.743041, 0.000000, 0.000000, 175.000000 );
	CreateDynamicObject( 1791, -2557.110351, 46.888534, 1021.393066, 0.000000, 0.000000, 175.000000 );
	CreateDynamicObject( 1749, -2556.871582, 47.310279, 1020.193115, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 16377, -2555.540283, 48.702793, 1020.604064, 0.000000, 0.000000, 40.000000 );
	CreateDynamicObject( 1716, -2556.015869, 48.463806, 1020.091613, 0.000000, 0.000000, 0.000000 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2110, -2558.130371, 48.754005, 1020.036376, 0.000000, 0.000000, 0.000000 ), 0, 988, "ws_apgatex", "cj_sheetmetal", -1 );
	CreateDynamicObject( 18635, -2557.033935, 48.709743, 1020.843139, 90.000000, -90.000000, 145.000000 );
	CreateDynamicObject( 1893, -2552.191650, 44.314052, 1025.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1893, -2552.191650, 47.314052, 1025.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1893, -2555.191650, 47.314052, 1025.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1893, -2555.191650, 44.314052, 1025.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1893, -2558.191650, 44.314052, 1025.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1893, -2558.191650, 47.314052, 1025.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 18652, -2556.903320, 38.545413, 1026.043090, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1437, -2553.613769, 43.065505, 1019.793212, 0.000000, 90.000000, 115.000000 );
	CreateDynamicObject( 1437, -2553.439453, 43.065505, 1019.793212, 0.000000, 90.000000, 115.000000 );
	CreateDynamicObject( 1437, -2553.228759, 42.482097, 1021.043090, 10.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 1437, -2553.378173, 42.482097, 1021.043090, 10.000000, 0.000000, 90.000000 );

    // Inactive account delete.
	mysql_function_query( dbHandle, "DELETE FROM `COD` WHERE UNIX_TIMESTAMP()-`COD`.`LAST_LOGGED` > 7889220", true, "onRemoveInactiveRows", "" );

	HTTP( INVALID_PLAYER_ID, HTTP_GET, "irresistiblegaming.com/cod-rules.txt", "", "OnRulesHTTPResponse" );
	print( "[CODSAMP] Call of Duty For SA-MP has been successfully initiaized. (Build: "#FILE_BUILD")" );

	// Classy shit
	format( szNormalString, 96, "mapname %s / %s", g_mp_mapData[ g_mp_gameData[ E_MAP ] ][ E_NAME ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ][ E_NAME ] );
	SendRconCommand( szNormalString );
	return 1;
}

public OnGameModeExit()
{
	for( new i; i < MAX_TEXT_DRAWS; i++ ) {
	    TextDrawDestroy( Text: i );
	    KillTimer( i );
	}
	mysql_close( );
	return 1;
}

thread onRemoveInactiveRows( )
{
	new
		iRemoved = cache_affected_rows( );

	if ( iRemoved ) {
		format( szNormalString, 96, "[%s %s] Removed approximately %d inactive rows.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	    AddFileLogLine( "inactive_rows.txt", szNormalString );
	}
}

// FIX
class Round( )
{
	static
	    string[ 37 ],
		Float: X, Float: Y, Float: Z
	;

	if ( g_zm_gameData[ E_GAME_ENDED ] )
	    return 1;

	if ( Iter_Count(zm_players) == 0 )
		return 1;

	if ( g_EvacuationTime >= 0 )
	{
		if ( g_WaveStarting >= 0 && !g_zm_gameData[ E_GAME_STARTED ] )
		{
		    if ( g_WaveStarting == 0 )
		    {
				for( new i; i < STARTING_ZOMBIES; i++ )
				    SpawnAvailableZombie( SKIN_ZOMBIE );

				#if !defined DEBUG_MODE
				foreach(new playerid : zm_players)
					if ( !IsPlayerUsingRadio( playerid ) && IsPlayerSpawned( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://irresistiblegaming.com/game_sounds/transmission.wav" );
				#endif

				SendClientMessageToMode( MODE_ZOMBIES, -1, ""COL_RED"[GAME]"COL_GREY" Zombies are now attacking. Brace yourselfs." );
				g_WaveStarting = 0;
				g_zm_gameData[ E_GAME_STARTED ] = true;
				return 1;
		    }

		    format( string, sizeof( string ), "~r~Wave will start in %d", g_WaveStarting );
		    TextDrawSetString( g_EvacuationTD, string );
		    g_WaveStarting--;
		    return 1;
		}
   	 	format( string, sizeof( string ), "~g~~h~Time Till Evacuation:~w~ %s", TimeConvert( g_EvacuationTime-- ) );
	    TextDrawSetString( g_EvacuationTD, string );

	    new
	    	zm_AFK = 0
	    ;

	    foreach(new i : zm_players)
	    {
			if ( IsPlayerSpawned( i ) && GetPlayerState( i ) != PLAYER_STATE_SPECTATING && IsPlayerAFK( i ) ) {
				zm_AFK++;
			}

	    	if ( p_SpectateMode{ i } )
	    	{
	    		if ( !IsPlayerSpawned( p_SpectatingPlayer[ i ] ) )
	    		{
	    			foreach(new x : zm_players)
	    			{
	    				if ( IsPlayerSpawned( x ) )
	    				{
						    if ( IsPlayerInAnyVehicle( x ) ) PlayerSpectateVehicle( i, GetPlayerVehicleID( x ) );
							else PlayerSpectatePlayer( i, x );
							p_SpectatingPlayer[ i ] = x;
							SendServerMessage( i, "The person you were spectating seemed to have died or disconnected so you're now spectating someone different." );
							break;
	    				}
	    			}
	    		}
			    format( szNormalString, sizeof( szNormalString ), "~g~%s(%d)~w~~n~Left Click = Next Player and Right Click = Previous Player~n~~n~Evacuation: %s", ReturnPlayerName( p_SpectatingPlayer[ i ] ), p_SpectatingPlayer[ i ], g_EvacuationTime > 0 ? TimeConvert( g_EvacuationTime ) : ("Started") );
				TextDrawSetString( g_SpectateTD[ i ], szNormalString );
	    	}
		}

		if ( getAliveSurvivors( ) == zm_AFK ) {
			zm_EndCurrentGame( false, ""COL_GREY"[SERVER]"COL_WHITE" Remaining survivor(s) have went AFK. New round is loading." );
		}

	    // ROUND_TIME / 30 = 600 seconds / 30 seconds = 20
	    static const iTimeInterval = 30;
	    for( new i = 1; i < ( ROUND_TIME / iTimeInterval ); i++ )
		{
	        if ( g_EvacuationTime == ( ROUND_TIME - ( iTimeInterval * i ) ) )
	        {
	            if ( g_EvacuationTime == ( ROUND_TIME / 2 ) ) // Half time = TANK or last!
	            {
	                create_Tank:

	                #if !defined DEBUG_MODE
	                foreach(new playerid : zm_players)
						if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://irresistiblegaming.com/game_sounds/Tank.wav" );
					#endif

					SendClientMessageToMode( MODE_ZOMBIES, -1, ""COL_RED"[GAME]"COL_GREY" The "COL_ORANGE"TANK"COL_GREY" has been spawned, be warned!" );
                    SpawnAvailableZombie( SKIN_TANK );
	            }
	            else
	            {
	            	// MAX_ZOMBIES ( 600 / 15 )
	            	SpawnAvailableZombie( SKIN_ZOMBIE );
	            	SpawnAvailableZombie( SKIN_ZOMBIE );
	            	if ( !SpawnAvailableZombie( SKIN_BOOMER ) ) SpawnAvailableZombie( SKIN_ZOMBIE );
				}
	            break;
	        }
	    }
	}
	else
	{
	    if ( g_zm_gameData[ E_EVAC_STARTED ] == false )
		{
			g_zm_gameData[ E_EVAC_STARTED ] = true;

			SetPlayerVirtualWorld( g_HelicopterNPC, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] ); // Else, where will he fly mauauha.

	        new
				hid = g_HelicopterNPC, // Movement slot: hid + 100
				veh = CreateVehicle( 548, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_X ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Y ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Z ] + 100.0, 0.0, -1, -1, 0)
			;
			g_HelicopterVehicle = veh;

			SetVehicleVirtualWorld( veh, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] );
			SendClientMessageToMode( MODE_ZOMBIES, -1, ""COL_RED"[GAME]"COL_GREY" The cargobob (Helicopter) is on its way. Estimated arrival time, 40 seconds." );
			TextDrawSetString( g_EvacuationTD, "~y~Cargobob is landing!" );

			FCNPC_PutInVehicle( hid, veh, 0 );

			FCNPC_GoTo( hid, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_X ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Y ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Z ] + 1, MOVE_TYPE_DRIVE, 0.3 );

			goto create_Tank;
	    }

	    FCNPC_GetPosition( g_HelicopterNPC, X, Y, Z );
	    if ( IsPointToPoint( 2.0, X, Y, Z, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_X ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Y ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Z ] + 1 ) && !IsValidDynamicCP( g_EvacuateCP ) )
	    {
			TextDrawSetString( g_EvacuationTD, "~g~Go to the Cargobob!" );
			SendClientMessageToMode( MODE_ZOMBIES, -1, ""COL_RED"[GAME]"COL_GREY" The cargobob (Helicopter) has landed. Quickly evacuate!" );
			g_EvacuateCP = CreateDynamicCP( g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_X ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Y ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_HELI_Z ], 10.0 );
	    }

	}
	return 1;
}


class Movement( )
{
	if ( g_zm_gameData[ E_GAME_ENDED ] )
	    return 1;

	if ( Iter_Count(zm_players) == 0 )
	    return 1;

	foreach(new zID : zombies)
	{
		new playerid = g_zombieData[ zID ] [ E_NPCID ];

	    if ( FCNPC_IsDead( playerid ) )
	    	continue; // We don't want the dead!

	    if ( g_ZombieClosest[ zID ] != ( g_ZombieClosest[ zID ] = GetZombieClosestPlayer( zID, g_ZombieClosestDistance[ zID ] ) ) )
	  		FCNPC_Stop( g_zombieData[ zID ] [ E_NPCID ] );

  		if ( IsPlayerConnected( g_ZombieClosest[ zID ] ) && !IsPlayerNPC( g_ZombieClosest[ zID ] ) && g_ZombieClosestDistance[ zID ] < 200 )
		{
		    if ( !IsPlayerAFK( g_ZombieClosest[ zID ] ) ) // Don't want all zombies just chasing one person.
		    {
				static
					Float: zX, Float: zY, Float: zZ,
					Float: pX, Float: pY, Float: pZ,
					Float: Angle
				;
				GetPlayerPos( g_ZombieClosest[ zID ], pX, pY, pZ );
				FCNPC_GetPosition( playerid, zX, zY, zZ );

				Angle = ( ( 360 / 10 ) * zID ) + 180.0; // 9 = Max Horde.
				pX += ( 1.25 * floatsin( -Angle, degrees ) );
				pY += ( 1.25 * floatcos( -Angle, degrees ) );

				FCNPC_Stop( playerid );
				FCNPC_GoTo( playerid, pX, pY, pZ, MOVE_TYPE_AUTO, g_ZombieClosestDistance[ zID ] < 25.0 ? g_zombieData[ zID ] [ E_SPEED ] : MOVE_SPEED_SPRINT, g_ZombieClosestDistance[ zID ] < 10.0 ? false : true );

				if ( 0.0 < g_ZombieClosestDistance[ zID ] < 1.40 ) {
					DamagePlayer( g_ZombieClosest[ zID ], g_zombieData[ zID ] [ E_DAMAGE ] );

					// Hit player code
					GetPlayerPos( g_ZombieClosest[ zID ], pX, pY, pZ );
					FCNPC_AimAt( playerid, pX, pY, pZ, false );
					FCNPC_MeleeAttack( playerid, 100 );

					//ApplyAnimation( playerid, "KISSING", "Playa_Kiss_01", 4.1, 0, 0, 0, 0, 0 );

					GameTextForPlayer( g_ZombieClosest[ zID ], "~r~YOU ARE BEING BITTEN!", 1000, 3 );

					TextDrawShowForPlayer( g_ZombieClosest[ zID ], g_BittenBoxTD );
					if ( p_BittenTimer[ g_ZombieClosest[ zID ] ] == 0xFFFF )
						p_BittenTimer[ g_ZombieClosest[ zID ] ] = SetTimerEx( "BittenTD_Hide", 1000, false, "d", g_ZombieClosest[ zID ] );

					if ( ( GetTickCount( ) - p_BittenTimestamp[ g_ZombieClosest[ zID ] ] ) > 1250 && !IsPlayerAFK( g_ZombieClosest[ zID ] ) )
						ApplyAnimation( g_ZombieClosest[ zID ], "PED", "HIT_behind", 4.0, 0, 0, 0, 0, 0, 0 ), p_BittenTimestamp[ g_ZombieClosest[ zID ] ] = GetTickCount( );

					if ( FCNPC_GetSkin( playerid ) == SKIN_BOOMER ) // boomer code!
					{
						SetPVarInt( playerid, "killerid", g_ZombieClosest[ zID ] );
						SetPVarInt( playerid, "weaponid", 666 );
						FCNPC_Kill( playerid );
		    			PlayerPlaySound( g_ZombieClosest[ zID ], 1159, zX, zY, zZ );

						if ( GetPlayerFPS( g_ZombieClosest[ zID ] ) > 45 && !IsPlayerAFK( g_ZombieClosest[ zID ] ) )
							SetTimerEx( "destroyBoomerBlood", 1000, false, "d", CreateDynamicObject( 18668, zX, zY, zZ - 2.25, 0.0, 0.0, 0.0 ) );

				    	continue;
					}
				}
			}
			else
			{
				g_ZombieClosest[ zID ] = INVALID_PLAYER_ID;
				FCNPC_StopAttack( playerid );
			}
		}
 	}
	return 1;
}

class BittenTD_Hide( playerid )
	return TextDrawHideForPlayer( playerid, g_BittenBoxTD ), p_BittenTimer[ playerid ] = 0xFFFF;

class destroyBoomerBlood( objectid )
	return DestroyDynamicObject( objectid );

stock GetZombieClosestPlayer( zID, &Float: getDistance = 0.0 )
{
	new
		Float: fDistance,
		Float: fHighest = 99999.0,
		iPlayer = INVALID_PLAYER_ID,
		Float: X, Float: Y, Float: Z
	;

	if ( !FCNPC_GetPosition( g_zombieData[ zID ] [ E_NPCID ], X, Y, Z ) )
	    return -1; // INVALID_NPC

	foreach(new playerid : zm_players)
	{
		if ( IsPlayerSpawned( playerid ) && !IsPlayerAFK( playerid ) && !p_SpectateMode{ playerid } && !IsPlayerAdminOnDuty( playerid ) )
		{
			fDistance = GetPlayerDistanceFromPoint( playerid, X, Y, Z );
			if ( fDistance < fHighest ) fHighest = fDistance, iPlayer = playerid;
		}
	}
	getDistance = fHighest;
	return iPlayer;
}

stock Float: GetDistanceFromPointToPoint( Float: fX, Float: fY, Float: fX1, Float: fY1 )
	return Float: floatsqroot( floatpower( fX - fX1, 2 ) + floatpower( fY - fY1, 2 ) );

class OnOneSecondUpdate( )
{
	static
		Float: Health, iAmmo;

	new svTickCount = GetTickCount( ); // Just stopping the iterations.

	foreach(new playerid : Player)
	{
	    if ( p_Team[ playerid ] != NO_TEAM )
	    {
	        if ( IsPlayerSpawned( playerid ) )
	        {
	        	g_userData[ playerid ] [ E_UPTIME ] ++;

				/* ANTICHEAT */
				if ( g_userData[ playerid ] [ E_ADMIN ] < 1 )
				{
					if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_USEJETPACK )
					{
						SendClientMessageToAllFormatted( -1, ""COL_AC"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for spawning a jetpack.", ReturnPlayerName( playerid ), playerid );
						AdvancedBan( playerid, "Server", "Jetpack", ReturnPlayerIP( playerid ) );
					}
					if ( GetPlayerWeapon( playerid ) < MAX_WEAPONS && GetPlayerWeapon( playerid ) >= 0 )
					{
						if ( g_BannedWeapons{ GetPlayerWeapon( playerid ) } == true && TimeStampPassed( p_LastSpawnTime[ playerid ], 1000 ) )
						{
							SendClientMessageToAllFormatted( -1, ""COL_AC"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for spawning a illegal weapon.", ReturnPlayerName( playerid ), playerid );
							AdvancedBan( playerid, "Server", "Illegal Weapon", ReturnPlayerIP( playerid ) );
						}
					}
					if ( GetPlayerPing( playerid ) > g_PingLimit )
					{
						SendClientMessageToAllFormatted( -1, ""COL_AC"[ANTI-CHEAT]{FFFFFF} %s(%d) has been kicked for excessive ping [%d/%d].", ReturnPlayerName( playerid ), playerid, GetPlayerPing( playerid ), g_PingLimit );
					    KickPlayerTimed( playerid );
					}

					GetPlayerWeaponData( playerid, 0, iAmmo, iAmmo );
					if ( iAmmo == 1000 ) {
						SendClientMessageToAllFormatted( -1, ""COL_AC"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for aimbot.", ReturnPlayerName( playerid ), playerid );
					    KickPlayerTimed( playerid );
					}
				}

				if ( gettime( ) > p_AntiSpawnKill[ playerid ] && p_AntiSpawnKillEnabled{ playerid } )
				{
					SetPlayerHealth( playerid, p_AdminOnDuty{ playerid } == true ? float( INVALID_PLAYER_ID ) : 100.0 );
					Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
					p_SpawnKillLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
					p_AntiSpawnKillEnabled{ playerid } = false;
				}

			    if ( g_userData[ playerid ] [ E_VIP_LEVEL ] > 0 && gettime( ) > g_userData[ playerid ] [ E_VIP_EXPIRE ] )
			    {
			        SendClientMessage( playerid, -1, ""COL_GREY"[NOTIFICATION]"COL_WHITE" Your V.I.P has expired, consider another donation to have your V.I.P restored again for another period." );
					g_userData[ playerid ] [ E_VIP_LEVEL ] = 0;
					g_userData[ playerid ] [ E_VIP_EXPIRE ] = 0;
					g_userData[ playerid ] [ E_WEAPONS ] [ 0 ] = 0;
					g_userData[ playerid ] [ E_WEAPONS ] [ 1 ] = 0;
				}

			    if ( gettime( ) > g_userData[ playerid ] [ E_DOUBLE_XP ] && g_userData[ playerid ] [ E_DOUBLE_XP ] != 0 )
			    {
			        SendClientMessage( playerid, -1, ""COL_GREY"[NOTIFICATION]"COL_WHITE" Double XP has been deactivated as it has expired for you." );
					g_userData[ playerid ] [ E_DOUBLE_XP ] = 0;
				}

	        	if ( IsPlayerInMultiplayer( playerid ) )
	        	{
					if ( !p_AntiSpawnKillEnabled{ playerid } && !p_AdminOnDuty{ playerid } && p_TakenDamage[ playerid ] < svTickCount )
					{
						GetPlayerHealth( playerid, Health );
						if ( Health < 75.0 ) SetPlayerHealth( playerid, Health + ( getPlayerFirstPerk( playerid ) == PERK_QUICKFIX ? 2.5 : 1.0 ) );
						if ( Health > 100.0 ) SetPlayerHealth( playerid, 100.0 );
					}

					if ( getPlayerEquipment( playerid ) == EQUIPMENT_SCRAMBLER )
					{
					    new victimid = GetClosestPlayer( playerid );
					    if ( IsPlayerConnected( victimid ) && !p_GotScrambled{ playerid } )
					    {
					        if ( p_Team[ victimid ] != p_Team[ playerid ] && GetDistanceBetweenPlayers( playerid, victimid ) < 5.0 )
							{
							    p_GotScrambled{ playerid } = true;
							    SetTimerEx( "RemovePlayerScrambled", 7000, false, "d", victimid );
								GangZoneShowForPlayer( victimid, g_Blackzone, 0x000000FF );
							}
						}
					}
				}

	     	}
	    }
	}
}

class OnServerUpdate( )
{
	static
	    Float: X, Float: Y, Float: Z, worldtime[ 64 ];

	new svTimeStamp = gettime( );

	if ( svTimeStamp > g_randomMessageTick ) {
		if ( strunpack( szNormalString, g_randomMessages[ random( sizeof( g_randomMessages ) ) ] ) > 26 )
	 		SendClientMessageToAll( -1, szNormalString );

		g_randomMessageTick = svTimeStamp + 30;
	}


	if ( Iter_Count(zm_players) )
	    format( worldtime, sizeof( worldtime ), "%s / %s", TimeConvert( g_mp_gameData[ E_TIME ] ), g_EvacuationTime > 0 ? TimeConvert( g_EvacuationTime ) : ( "Evacuation" ) );
	else
		format( worldtime, sizeof( worldtime ), "%s / Paused", TimeConvert( g_mp_gameData[ E_TIME ] ) );

	SetServerRule( "worldtime", worldtime );

	if ( g_mp_gameData[ E_STARTED ] == false && g_mp_gameData[ E_STARTING ] == false )
	{
	    if ( g_TropasMembers != 0 && g_OP40Members != 0 )
	    {
	        g_mp_gameData[ E_STARTING ] = true;
	        g_mp_gameData[ E_COUNTDOWN ] = COUNTDOWN_TIME;
			rl_StartRoundTimer = SetTimer( "RoundStart", 980, true );

			SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" To understand the objective thoroughly, type /objective." );

			foreach(new playerid : mp_players)
			{
			    if ( p_Team[ playerid ] != NO_TEAM )
			    {
			        TextDrawShowForPlayer( playerid, g_RoundStartNote );

					if ( !IsPlayerUsingRadio( playerid ) )
					{
	  					if ( p_Team[ playerid ] == TEAM_TROPAS ) PlayAudioStreamForPlayer( playerid, "http://www.irresistiblegaming.com/game_sounds/tropas_spawn.mp3" );
	  					else if ( p_Team[ playerid ] == TEAM_OP40 ) PlayAudioStreamForPlayer( playerid, "http://www.irresistiblegaming.com/game_sounds/op40_spawn.mp3" );
					}

					if ( IsPlayerSpawned( playerid ) )
						SpawnPlayerToBase( playerid, 1 );
				}
			}
			TextDrawHideForAll( g_ShortPlayerNoticeTD );
		}
	}

	foreach(new playerid : mp_players)
	{
	    if ( p_Team[ playerid ] != NO_TEAM )
	    {
	        if ( IsPlayerSpawned( playerid ) )
	        {
	        	if ( IsPlayerAFKFor( playerid, 10000 ) ) {
	        		// Strip Player Flag...
	        		StripPlayerFlag( playerid );
	        	}

	            // UAV System <-
				for( new teamid = 1; teamid < MAX_TEAMS; teamid++ )
				{
				    if ( gettime( ) > g_UAVTimestamp{ teamid } && g_UAVOnline{ teamid } == true )
				    {
						foreach(new x : mp_players)
					    {
					        if ( !IsPlayerSpawned( x ) ) continue;
							if ( p_Team[ playerid ] == p_Team[ x ] )
							{
					       	 	SetPlayerMarkerForPlayer( playerid, x, ( GetPlayerColor( x ) & ReturnPlayerTeamColor( x ) ) );
					        	SetPlayerMarkerForPlayer( x, playerid, ( GetPlayerColor( playerid ) & ReturnPlayerTeamColor( playerid ) ) );
							}
							else
							{
					       	 	SetPlayerMarkerForPlayer( playerid, x, ( GetPlayerColor( x ) & 0xFFFFFF00 ) );
					        	SetPlayerMarkerForPlayer( x, playerid, ( GetPlayerColor( playerid ) & 0xFFFFFF00 ) );
							}
						}
						g_UAVOnline{ teamid } = false;
				    }
				}

	            // Kill Confirmed System <-
	            foreach(new dogid : dogtags)
	            {
	                if ( IsPlayerInRangeOfPoint( playerid, 2.0, g_dogtagData[ dogid ] [ E_X ], g_dogtagData[ dogid ] [ E_Y ], g_dogtagData[ dogid ] [ E_Z ] ) && GetPlayerState( playerid ) != PLAYER_STATE_SPECTATING )
	                {
	                    if ( g_dogtagData[ dogid ] [ E_TEAM_ID ] == p_Team[ playerid ] )
	                    {
	        				SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" %s(%d) has confirmed a kill.", ReturnPlayerName( playerid ), playerid );
							DestroyDogTag( dogid );
							GivePlayerXP( playerid, 50 );
							GiveTeamScore( p_Team[ playerid ], 1, playerid );
	                    }
	                    else
	                    {
	        				SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" %s(%d) has denied a kill.", ReturnPlayerName( playerid ), playerid );
							DestroyDogTag( dogid );
							GivePlayerXP( playerid, 50 );
	                    }
	                    break;
	                }
	            }

	            // Claymore System <-
				foreach(new c_ID : claymore)
				{
					GetDynamicObjectPos( g_claymoreObject[ c_ID ], X, Y, Z );
					if ( IsPlayerInRangeOfPoint( playerid, 2.0, X, Y, Z ) && g_claymoreOwner[ c_ID ] != playerid )
					{
					    if ( p_Team[ g_claymoreOwner[ c_ID ] ] != p_Team[ playerid ] )
					    {
    						CreateExplosionEx( g_claymoreOwner[ c_ID ], X, Y, Z, 4.0, EXPLOSION_TYPE_SMALL, WEAPON_GRENADE );
						    DestroyClaymore( c_ID );
						    break;
					    }
					}
				}
			}
	    }
	}
	return 1;
}

class RemovePlayerScrambled( playerid )
{
	p_GotScrambled{ playerid } = false;
    GangZoneHideForPlayer( playerid, g_Blackzone );
}

class RoundStart( )
{
	static
	    string[3]
	;
	if ( g_mp_gameData[ E_COUNTDOWN ] <= 0 )
	{
		g_mp_gameData[ E_STARTED ] = true;
		g_mp_gameData[ E_STARTING ] = false;
		g_mp_gameData[ E_COUNTDOWN ] = COUNTDOWN_TIME;
		g_mp_gameData[ E_TIME ] = MATCH_TIME;
		g_mp_gameData[ E_KILLS ] = 0;
		KillTimer( rl_MatchTimer );
        rl_MatchTimer = SetTimer( "MatchTime", 970, true );
        foreach(new playerid : mp_players)
		{
			TogglePlayerControllable( playerid, true );
	  		TextDrawHideForPlayer( playerid, g_RoundStartNote );
			if ( !p_inMovieMode{ playerid } )
			{
		    	TextDrawShowForPlayer( playerid, g_RoundTimeTD );
		    	TextDrawShowForPlayer( playerid, g_RoundBoxWhereTeam );
	      		TextDrawShowForPlayer( playerid, p_RoundPlayerTeam[ playerid ] );
	      		TextDrawShowForPlayer( playerid, g_tropasRoundBox );
	      		TextDrawShowForPlayer( playerid, g_tropasScoreText );
	      		TextDrawShowForPlayer( playerid, g_op40RoundBox );
	      		TextDrawShowForPlayer( playerid, g_op40ScoreText );
	    		TextDrawShowForPlayer( playerid, g_RoundGamemodeTD );
			}
		}
		TextDrawHideForAll( g_RoundStartTimeTD );
	    return KillTimer( rl_StartRoundTimer ), 1;
	}

	foreach(new playerid : mp_players) { if ( IsPlayerSpawned( playerid ) ) { TogglePlayerControllable( playerid, 0 ); } }
	g_mp_gameData[ E_COUNTDOWN ] --;

	format( string, sizeof( string ), "%d", g_mp_gameData[ E_COUNTDOWN ] );
    g_CountDownX = 0.0, g_CountDownY = 0.0;
	TextDrawSetString( g_RoundStartTimeTD, string );

	g_CountDownGrowTimer = SetTimerEx( "RoundStartTimeGrowTD", 1, true, "ddff", 30, 875, 1.200000, 5.000000 );
	return 1;
}

class RoundStartTimeGrowTD( anim_speed, duration, Float:max_x, Float:max_y )
{
	if ( g_CountDownX < max_x ) g_CountDownX += max_x / anim_speed;
	if ( g_CountDownY < max_y ) g_CountDownY += max_y / anim_speed;

	TextDrawLetterSize( g_RoundStartTimeTD, g_CountDownX, g_CountDownY );
	TextDrawShowForAllInMode( MODE_MULTIPLAYER, g_RoundStartTimeTD );
	TextDrawShowForAllInMode( MODE_MULTIPLAYER, g_RoundStartNote );

	if ( g_CountDownX >= max_x && g_CountDownY >= max_y )
		KillTimer( g_CountDownGrowTimer ), g_CountDownGrowTimer = 0xFFFF;

	return 1;
}


class MatchTime( )
{
	g_mp_gameData[ E_TIME ] --;
    TextDrawSetString( g_RoundTimeTD, TimeConvert( g_mp_gameData[ E_TIME ] ) );

	if ( g_mp_gameData[ E_TIME ] <= 0 )
	{
		new
		 	iWinner = -1;

		if ( g_OP40Score > g_TropasScore )      	SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" Team OP40 has won the game. Well done!" ), iWinner = TEAM_OP40;
		else if ( g_OP40Score < g_TropasScore )  SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" Team Tropas has won the game. Well done!" ), iWinner = TEAM_TROPAS;
		else if ( g_OP40Score == g_TropasScore )	SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" The game is a draw, try harder next time!" ), iWinner = -1;

		KillTimer( rl_MatchTimer );
		rl_MatchTimer = 0xFF;
		KillTimer( rl_ResetMode );
		rl_ResetMode = 0xFF;

		g_mp_gameData[ E_FINISHED ] = true;

		DestroyCTFlags( );

		new
		    szNames[ 2 ] [ 232 ],
		    szScore[ 2 ] [ 96 ],
		    szKills[ 2 ] [ 72 ],
			szDeaths[ 2 ] [ 72 ]
		;

	  	SortDeepArray( g_usermatchDataT1, e_match_progress: M_SCORE, .order = SORT_DESC );
	  	SortDeepArray( g_usermatchDataT2, e_match_progress: M_SCORE, .order = SORT_DESC );

	  	for( new i = 0, a_count, b_count; i < sizeof( g_usermatchDataT1 ); i++ ) // 8 Rows
		{
		    if ( IsPlayerConnected( g_usermatchDataT1[ i ] [ M_ID ] ) )
		    {
		        if ( ++a_count < 9 )
		        {
		        	new pID = g_usermatchDataT1[ i ] [ M_ID ];
			    	format( szNames[ 0 ], sizeof( szNames[ ] ), "%s%s~n~", szNames[ 0 ], ReturnPlayerName( pID ) );
		    		format( szScore[ 0 ], sizeof( szScore[ ] ), "%s%d~n~", szScore[ 0 ], g_usermatchDataT1[ i ] [ M_SCORE ] );
			    	format( szKills[ 0 ], sizeof( szKills[ ] ), "%s%d~n~", szKills[ 0 ], p_MatchKills[ pID ] );
			    	format( szDeaths[ 0 ], sizeof( szDeaths[ ] ), "%s%d~n~", szDeaths[ 0 ], p_MatchDeaths[ pID ] );
				}
			}
			if ( IsPlayerConnected( g_usermatchDataT2[ i ] [ M_ID ] ) )
			{
		        if ( ++b_count < 9 )
		        {
		        	new pID = g_usermatchDataT2[ i ] [ M_ID ];
			    	format( szNames[ 1 ], sizeof( szNames[ ] ), "%s%s~n~", szNames[ 1 ], ReturnPlayerName( pID ) );
			    	format( szScore[ 1 ], sizeof( szScore[ ] ), "%s%d~n~", szScore[ 1 ], g_usermatchDataT2[ i ] [ M_SCORE ] );
			    	format( szKills[ 1 ], sizeof( szKills[ ] ), "%s%d~n~", szKills[ 1 ], p_MatchKills[ pID ] );
			    	format( szDeaths[ 1 ], sizeof( szDeaths[ ] ), "%s%d~n~", szDeaths[ 1 ], p_MatchDeaths[ pID ] );
			   	}
			}
		}

		TextDrawSetString( g_Scoreboard[ 7 ], ModeToString( g_mp_gameData[ E_GAMEMODE ] ) );
		TextDrawSetString( g_ScoreboardNames[ 0 ], szNames[ 0 ] );
		TextDrawSetString( g_ScoreboardNames[ 1 ], szNames[ 1 ] );
		TextDrawSetString( g_ScoreboardKills[ 0 ], szKills[ 0 ] );
		TextDrawSetString( g_ScoreboardKills[ 1 ], szKills[ 1 ] );
		TextDrawSetString( g_ScoreboardDeaths[ 0 ], szDeaths[ 0 ] );
		TextDrawSetString( g_ScoreboardDeaths[ 1 ], szDeaths[ 1 ] );
		TextDrawSetString( g_ScoreboardScores[ 0 ], szScore[ 0 ] );
		TextDrawSetString( g_ScoreboardScores[ 1 ], szScore[ 1 ] );
		format( szScore[ 0 ], sizeof( szScore[ ] ), "Score:~w~~h~ %d", g_TropasScore );
	    TextDrawSetString( g_ScoreboardTeamScore[ 0 ], szScore[ 0 ] );
		format( szScore[ 0 ], sizeof( szScore[ ] ), "Score:~w~~h~ %d", g_OP40Score );
	    TextDrawSetString( g_ScoreboardTeamScore[ 1 ], szScore[ 0 ] );

	    for( new i; i < MAX_PLAYERS; i++ )
	    {
			ResetMatchData( i );

	    	if ( IsPlayerInMultiplayer( i ) )
	    	{
	    		if ( !IsPlayerAFK( i ) && p_Team[ i ] != NO_TEAM )
	    		{
		    		if ( iWinner == -1 )
		    			GivePlayerXP( i, 125 );
		    		else if ( iWinner == p_Team[ i ] )
		    			GivePlayerXP( i, 250 );
	    		}

		    	if ( g_mp_gameData[ E_GAMEMODE ] == MODE_CTF ) StripPlayerFlag( i, true );
			    if ( p_Team[ i ] != NO_TEAM )
			    {
					SetMatchData( i, M_ID, i );
			    	TogglePlayerControllable( i, 0 );
					showScoreBoard( i );
				}
	    	}
	    }

		rl_ResetMode = SetTimer( "ResetMode", 15000, false );
	}
	else
	{
		new
			szTimeStamp = gettime( );

		if ( szTimeStamp > g_AutoBalanceTime && g_TropasMembers != g_OP40Members && !isodd( Iter_Count(mp_players) ) )
		{
			if ( BalanceTeams( ) ) SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" Teams have been auto-balanced." );
			g_AutoBalanceTime = szTimeStamp + 60;
		}
	}
	return 1;
}

class ResetMode( )
{
	new
	    szString[ 32 ],
		iMap;

	if ( g_mp_gameData[ E_NEXT_MAP ] == -1 )
	{
	    refind_map:
		iMap = Iter_Random(maps);
		if ( iMap == g_mp_gameData[ E_MAP ] && Iter_Count(maps) > 1 ) goto refind_map;

	    g_mp_gameData[ E_MAP ] = iMap;
	}
	else
	{
		g_mp_gameData[ E_MAP ] = g_mp_gameData[ E_NEXT_MAP ];
		g_mp_gameData[ E_NEXT_MAP ] = -1;
	}

	g_mp_gameData[ E_GAMEMODE ] = random( MAX_MODES );

	if ( g_mp_gameData[ E_GAMEMODE ] == MODE_CTF ) SetCTFlags( );

	SendRconCommand( szString );
	TextDrawSetString( g_RoundGamemodeTD, ModeToString( g_mp_gameData[ E_GAMEMODE ] ) );
    SendClientMessageToMode( MODE_MULTIPLAYER, 0x8EE044FF, "________________________________________________________");
    SendClientMessageToMode( MODE_MULTIPLAYER, 0x8EE044FF, " ");
	format( szNormalString, sizeof( szNormalString ), "Map has been changed to \"%s\" by %s", g_mp_mapData[ g_mp_gameData[ E_MAP ] ][ E_NAME ], g_mp_mapData[ g_mp_gameData[ E_MAP ] ][ E_AUTHOR ] );
	SendClientMessageToMode( MODE_MULTIPLAYER, -1, szNormalString );
	SendClientMessageToMode( MODE_MULTIPLAYER, 0x8EE044FF, "________________________________________________________" );
    SendClientMessageToMode( MODE_MULTIPLAYER, 0x8EE044FF, " " );

	KillTimer( rl_ResetMode ), rl_ResetMode = 0xFF;

	RemoveAllCarePackages( );

	foreach(new playerid : mp_players)
	{
	    if ( !IsPlayerInMatch( playerid ) && !IsPlayerSpawned( playerid ) ) continue;
    	p_SelectedGameClass[ playerid ] = 0;
	    SpawnPlayer( playerid );
	    SetCameraBehindPlayer( playerid );
		TogglePlayerControllable( playerid, 0 );
		StripPlayerFlag( playerid, true );
		DestroyDogTag( GetPlayerDogTag( playerid ) );
		TruncatePlayerClaymores( playerid );
		DestroyTacticalInsertion( playerid );
    	endRCXD( playerid );
    	endAGR( playerid );
    	endLightningStrike( playerid );
	}
	//TextDrawHideForAll( g_RoundScoreBoard[ 0 ] );

	g_TropasScore 	= 0;
	g_OP40Score 	= 0;

	TextDrawSetString( g_RoundStartTimeTD, "15" );
	TextDrawSetString( g_op40ScoreText, "0" );
	TextDrawSetString( g_tropasScoreText, "0" );

	g_op40RoundBoxSize 		= 569.000000;
	g_tropasRoundBoxSize 	= 569.000000;

	TextDrawTextSize( g_tropasRoundBox, g_tropasRoundBoxSize, 	0.000000 );
    TextDrawTextSize( g_op40RoundBox, 	g_op40RoundBoxSize, 	0.000000 );

    hideScoreBoard( );

    g_mp_gameData[ E_STARTED ] = false;
    g_mp_gameData[ E_STARTING ] = false;
	g_mp_gameData[ E_FINISHED ] = false;
	g_mp_gameData[ E_KILLS ] = 0;

	format( szNormalString, 64, "COD4SAMP %s | ZOMBIES", ModeToStringSmall( g_mp_gameData[ E_GAMEMODE ] ) );
	SetGameModeText( szNormalString );

	format( szNormalString, 96, "mapname %s / %s", g_mp_mapData[ g_mp_gameData[ E_MAP ] ][ E_NAME ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ][ E_NAME ] );
	SendRconCommand( szNormalString );
	return 1;
}

public OnRulesHTTPResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 )
    {
    	if ( !strlen( data ) )
    	{
    		if ( IsPlayerConnected( index ) ) SendError( index, "An error occurred, we're trying again now." );
    		print( "[RULES] Problems with updating rules, restarting process." );
    		HTTP( INVALID_PLAYER_ID, HTTP_GET, "irresistiblegaming.com/cod-rules.txt", "", "OnRulesHTTPResponse" );
    		return 1;
    	}

    	printf( "[RULES] Rules have been updated! Character Size: %d", strlen( data ) );
    	format( szRules, sizeof( szRules ), "%s", data );
		if ( IsPlayerConnected( index ) ) SendServerMessage( index, "The rules have now been updated." );
    }
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	TogglePlayerSpectating( playerid, 1 );
	//SetPlayerWeather( playerid, 9 );
	SetPlayerTime( playerid, 0, 0 );

	//SetPlayerCameraPos( playerid, -129.49, 917.10, 21.27 );
	//SetPlayerCameraLookAt( playerid, -8.510, 967.67, 20.82 );

	new Float: cameraLook[ 3 ] = { -2556.770263, 49.858856, 1021.210998 };
	new Float: cameraLookAt[ 3 ] = { 0.430683, -0.901934, 0.032025 };

	InterpolateCameraPos( playerid, cameraLook[ 0 ], cameraLook[ 1 ], cameraLook[ 2 ], cameraLook[ 0 ] + 0.01, cameraLook[ 1 ] + 0.01, cameraLook[ 2 ] + 0.01, 1200000, CAMERA_MOVE );
	InterpolateCameraLookAt( playerid, cameraLook[ 0 ] + cameraLookAt[ 0 ], cameraLook[ 1 ] + cameraLookAt[ 1 ], cameraLook[ 2 ] + cameraLookAt[ 2 ], cameraLook[ 0 ] + cameraLookAt[ 0 ] + 0.01, cameraLook[ 1 ] + cameraLookAt[ 1 ] + 0.01, cameraLook[ 2 ] + cameraLookAt[ 2 ] + 0.01, 1200000, CAMERA_MOVE );

	/*switch( random( 2 ) )
	{
		case 0:
		{
			mapid = g_zm_gameData[ E_MAP ];

			SetPlayerVirtualWorld( playerid, g_zm_mapData[ mapid ] [ E_WORLD ] );
			SetPlayerInterior( playerid, 0 );

			InterpolateCameraPos( playerid, g_mapHumanSpawnData[ mapid ] [ 2 ] [ 0 ], g_mapHumanSpawnData[ mapid ] [ 2 ] [ 1 ], g_mapHumanSpawnData[ mapid ] [ 2 ] [ 2 ] + 20, g_mapZombieSpawnData[ mapid ] [ 2 ] [ 0 ], g_mapZombieSpawnData[ mapid ] [ 2 ] [ 1 ], g_mapZombieSpawnData[ mapid ] [ 2 ] [ 2 ] + 20, 60000, CAMERA_MOVE );
			InterpolateCameraLookAt( playerid, g_mapZombieSpawnData[ mapid ] [ 2 ] [ 0 ], g_mapZombieSpawnData[ mapid ] [ 2 ] [ 1 ], g_mapZombieSpawnData[ mapid ] [ 2 ] [ 2 ], g_mapHumanSpawnData[ mapid ] [ 2 ] [ 0 ], g_mapHumanSpawnData[ mapid ] [ 2 ] [ 1 ], g_mapHumanSpawnData[ mapid ] [ 2 ] [ 2 ], 60000, CAMERA_MOVE );
		}
		case 0, 1:
		{
			mapid = g_mp_gameData[ E_MAP ];

			SetPlayerVirtualWorld( playerid, g_mp_mapData[ mapid ] [ E_WORLD ] ); // Anti lag
			SetPlayerInterior( playerid, g_mp_mapData[ mapid ] [ E_INTERIOR ] );

			InterpolateCameraPos( playerid, g_mp_mapData[ mapid ] [ E_MAXX1 ], g_mp_mapData[ mapid ] [ E_MAXY1 ], g_mp_mapData[ mapid ] [ E_MAPZ1 ] + 20, g_mp_mapData[ mapid ] [ E_MAXX2 ], g_mp_mapData[ mapid ] [ E_MAXY2 ], g_mp_mapData[ mapid ] [ E_MAPZ2 ] + 20, 60000, CAMERA_MOVE );
			InterpolateCameraLookAt( playerid, g_mp_mapData[ mapid ] [ E_MAXX2 ], g_mp_mapData[ mapid ] [ E_MAXY2 ], g_mp_mapData[ mapid ] [ E_MAPZ2 ], g_mp_mapData[ mapid ] [ E_MAXX1 ], g_mp_mapData[ mapid ] [ E_MAXY1 ], g_mp_mapData[ mapid ] [ E_MAPZ1 ], 60000, CAMERA_MOVE );
		}
	}*/

	TextDrawHideForPlayer( playerid, g_ShortPlayerNoticeTD );
	TextDrawHideForPlayer( playerid, p_ExperienceTD[ playerid ] );
	TextDrawHideForPlayer( playerid, p_RankDataTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_HideCashBoxTD );
	TextDrawHideForPlayer( playerid, g_WebsiteTD[ 0 ] );
	TextDrawHideForPlayer( playerid, g_WebsiteTD[ 1 ] );
	TextDrawHideForPlayer( playerid, g_MotdTD );
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );

	p_Spawned{ playerid } = false;

	if ( p_goingtoMenu[ playerid ] == true ) {
		p_goingtoMenu[ playerid ] = false;
		ShowMainMenu( playerid );
		return 1;
	}

	if ( p_Team[ playerid ] != NO_TEAM )
	{
		if ( GetPVarInt( playerid, "classsel_respawn" ) != 1 )
		{
			SendServerMessage( playerid, "You will now respawn in 5 seconds as you've most probably entered class selection mistakenly." );
			SetPVarInt( playerid, "classsel_respawn", 1 );
			SetTimerEx( "class_selection_respawn", 5000, false, "d", playerid );
		}
	}
	return 1;
}

class class_selection_respawn( playerid )
{
	TogglePlayerSpectating( playerid, 0 );
	SpawnPlayer( playerid );
	SetCameraBehindPlayer( playerid );
	DeletePVar( playerid, "classsel_respawn" );
}

thread OnPlayerBanCheck( playerid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );
	if ( rows )
	{
	    new
			bannedUser[ 24 ],
			bannedIP[ 16 ],
			bannedbyUser[ 24 ],
			bannedReason[ 50 ],
			bannedExpire = 0,
			server = 1
		;

		server  	 = cache_get_field_content_int( 0, "SERVER", dbHandle );
		bannedExpire = cache_get_field_content_int( 0, "EXPIRE", dbHandle );

		cache_get_field_content( 0, "BANBY", bannedbyUser );
		cache_get_field_content( 0, "REASON", bannedReason );
		cache_get_field_content( 0, "NAME", bannedUser );
		cache_get_field_content( 0, "IP", bannedIP );

		// CNR BANS ONLY
		if ( bannedExpire == 0 )
		{
			format( szLargeString, 600, "{FFFFFF}You are banned from this server. "COL_ORANGE"Ban evading will be fatal to your account. Do not do it.\n{FFFFFF}If you feel wrongfully banned, please appeal at "COL_BLUE""#SERVER_WEBSITE"{FFFFFF}\n\n"COL_RED"Username:{FFFFFF} %s\n"COL_RED"IP Address:{FFFFFF} %s\n", bannedUser, bannedIP );
			format( szLargeString, 600, "%s"COL_RED"Reason:{FFFFFF} %s\n"COL_RED"Server:{FFFFFF} %s\n"COL_RED"Banned by:{FFFFFF} %s%s", szLargeString, bannedReason, GetServerName( server ), bannedbyUser, strmatch( ReturnPlayerName( playerid ), bannedUser ) ? ("") : ("\n\n"COL_RED"Your IP Address is banned, if this is a problem then visit our forums.") );
	      	ShowPlayerDialog( playerid, DIALOG_BANNED, DIALOG_STYLE_MSGBOX, "{FFFFFF}Ban Information", szLargeString, "Okay", "" );
	      	KickPlayerTimed( playerid );
	  		return 1;
		}
		else
		{
			if ( gettime( ) > bannedExpire )
			{
				format( szNormalString, 100, "DELETE FROM `BANS` WHERE `NAME`= '%s' OR `IP` = '%s'", mysql_escape( ReturnPlayerName( playerid ) ), mysql_escape( ReturnPlayerIP( playerid ) ) ), mysql_single_query( szNormalString );
				SendServerMessage( playerid, "The suspension of this account has expired as of now, this account is available for playing." );
			}
			else
			{
				format( szLargeString, 700, "{FFFFFF}You are suspended from this server. "COL_ORANGE"Ban evading will be fatal to your account. Do not do it.\n{FFFFFF}If you feel wrongfully suspended, please appeal at "COL_BLUE""#SERVER_WEBSITE"{FFFFFF}\n\n"COL_RED"Username:{FFFFFF} %s\n"COL_RED"IP Address:{FFFFFF} %s\n", bannedUser, bannedIP );
				format( szLargeString, 700, "%s"COL_RED"Reason:{FFFFFF} %s\n"COL_RED"Server:{FFFFFF} %s\n"COL_RED"Suspended by:{FFFFFF} %s\n"COL_RED"Expire Time:{FFFFFF} %s%s", szLargeString, bannedReason, GetServerName( server ), bannedbyUser, secondstotime( bannedExpire - gettime( ) ), strmatch( ReturnPlayerName( playerid ), bannedUser ) ? (" ") : ("\n\n"COL_RED"Your IP Address is suspended, if this is a problem, visit our forums.") );
		      	ShowPlayerDialog( playerid, DIALOG_BANNED, DIALOG_STYLE_MSGBOX, "{FFFFFF}Suspension Information", szLargeString, "Okay", "" );
	      		KickPlayerTimed( playerid );
		  		return 1;
		  	}
		}
	}

	format( szNormalString, sizeof( szNormalString ), "SELECT `NAME` FROM `COD` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( ReturnPlayerName( playerid ) ) );
 	mysql_function_query( dbHandle, szNormalString, true, "OnPlayerRegisterCheck", "i", playerid );
	return 1;
}

thread OnPlayerMegaBanCheck( playerid )
{
	new
		rows, fields;

    cache_get_data( rows, fields );
	if ( rows )
	{
		new
			playerserial[ 41 ];

		gpci( playerid, playerserial, sizeof( playerserial ) );
		SendServerMessage( playerid, "You are banned from this server. (0xAF)" );
		KickPlayer( playerid );
	}
	else
	{
		SendDeathMessage( INVALID_PLAYER_ID, playerid, 200 );

		if ( IsProxyEnabledForPlayer( playerid ) ) {
			format( szNormalString, sizeof( szNormalString ), "%s(%d) has connected to the server! (%s)", ReturnPlayerName( playerid ), playerid, GetPlayerCountryName( playerid ) );
		} else {
			format( szNormalString, sizeof( szNormalString ), "%s(%d) has connected to the server!", ReturnPlayerName( playerid ), playerid );
		}

		// IRC_GroupSay( gGroupID, IRC_CHANNEL, szNormalString );
	}
	return 1;
}

thread OnPlayerRegisterCheck( playerid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );
	if ( rows )
    {
        format( szBigString, sizeof(szBigString), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ) );
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{FFFFFF}Account - Authentication", szBigString, "Login", "Leave");
    }
    else
    {
        format( szBigString, sizeof(szBigString), "{FFFFFF}Welcome, this account ("COL_RED"%s"COL_WHITE") is not registered.\nPlease enter your desired password for this account.\n\n"COL_GREY"Once you are registered, do not share your password with anyone besides yourself!", ReturnPlayerName( playerid ) );
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Account - Register", szBigString, "Register", "Leave");
    }
	return 1;
}

public OnPlayerFloodControl( playerid, iCount, iTimeSpan ) {
    if ( iCount > 2 && iTimeSpan < 10000 ) {
    	if ( !IsLegitimateNPC( playerid ) ) {
        	BanEx( playerid, "BOT-SPAM" );
    	}
    }
}

public OnPlayerConnect( playerid )
{
    new
        Query[ 128 ];

	if ( strlen( ReturnPlayerName( playerid ) ) <= 2 )
		return Kick( playerid ), 1;

	if ( IsPlayerNPC( playerid ) && !IsLegitimateNPC( playerid ) )
		return BanEx( playerid, "Illegit NPC" ), 1;

	if ( strmatch( ReturnPlayerName( playerid ), "No-one" ) )
		return Kick( playerid ), 1;

	if ( textContainsIP( ReturnPlayerName( playerid ) ) )
	    return Kick( playerid ), 1;

	if ( g_ServerLocked )
	    return SendError( playerid, "The server is locked due to false server configuration. Please wait for the operator." ), KickPlayerTimed( playerid ), 1;

	if ( !IsPlayerNPC( playerid ) )
	{
		if ( !( 0 <= playerid < MAX_PLAYERS ) )
	    	return Kick( playerid ), 1;

		// Ultra fast queries...
		format( Query, sizeof( Query ), "SELECT * FROM `BANS` WHERE (`NAME`='%s' OR `IP`='%s') LIMIT 0,1", mysql_escape( ReturnPlayerName( playerid ) ), mysql_escape( ReturnPlayerIP( playerid ) ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerBanCheck", "i", playerid );

	    // Remove Building Code
		cod_removeBuildings( playerid );
		l4d_removeBuildings( playerid );

		p_Team 				[ playerid ] = NO_TEAM;
		justConnected		{ playerid } = true;
		p_IncorrectLogins	{ playerid } = 0; // LEGIT BRAH.
		p_FPS_DrunkLevel	[ playerid ] = 0;
		p_FPS 				[ playerid ] = 0;
		SetPlayerColor( playerid, COLOR_GREY );
		ResetPlayerCash( playerid );

	  	PlayAudioStreamForPlayer( playerid, "http://www.irresistiblegaming.com/game_sounds/mainmenu.mp3" );

	  	SendClientMessage( playerid, -1, ""COL_ORANGE"[UPDATES]"COL_GREY" You can check updates on our twitter @IrresistibleDev - Have fun playing!" );
	}
	return 1;
}

public OnLookupComplete( playerid )
{
	format( szLargeString, sizeof( szLargeString ), "SELECT * FROM `MEGABAN` WHERE `ISP`='%s' LIMIT 0,1", mysql_escape( GetPlayerISP( playerid ) ) );
	mysql_function_query( dbHandle, szLargeString, true, "OnPlayerMegaBanCheck", "i", playerid );
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if ( !IsPlayerNPC( playerid ) )
	{
		switch( p_Team[ playerid ] ) {
		    case TEAM_TROPAS: 	g_TropasMembers --;
		    case TEAM_OP40: 	g_OP40Members --;
		}
		SavePlayerData( playerid );

	    /* ** End game check ** */
	    if ( IsPlayerInZombies( playerid ) )
	    {
	    	if ( !g_zm_gameData[ E_GAME_ENDED ] )
		    {
				if ( !getAliveSurvivors( ) )
				{
				    zm_EndCurrentGame( false, ""COL_GREY"[SERVER]"COL_WHITE" All survivors have died, a new round is now loading." );
				    return 1;
				}
			}
		}
	    /* ** End of End game check ** */

		CutSpectation( playerid );
		AlterModePlayers( playerid, MODE_NONE );
		g_userData[ playerid ] [ E_KILLS ] 		= 0;
		g_userData[ playerid ] [ E_DEATHS ] 	= 0;
		g_userData[ playerid ] [ E_ADMIN ] 		= 0;
		g_userData[ playerid ] [ E_XP ] 		= 0;
		g_userData[ playerid ] [ E_RANK ] 		= 0;
		g_userData[ playerid ] [ E_PRESTIGE ] 	= 0;
		g_userData[ playerid ] [ E_PRIMARY1 ] 	= 29;
		g_userData[ playerid ] [ E_PRIMARY2 ] 	= 29;
		g_userData[ playerid ] [ E_PRIMARY3 ] 	= 29;
		g_userData[ playerid ] [ E_SECONDARY1 ] = 23;
		g_userData[ playerid ] [ E_SECONDARY2 ] = 23;
		g_userData[ playerid ] [ E_SECONDARY3 ] = 23;
		g_userData[ playerid ] [ E_PERK_ONE ] [ 0 ]= 0;
		g_userData[ playerid ] [ E_PERK_ONE ] [ 1 ]= 0;
		g_userData[ playerid ] [ E_PERK_ONE ] [ 2 ]= 0;
		g_userData[ playerid ] [ E_PERK_TWO ] [ 0 ]= 0;
		g_userData[ playerid ] [ E_PERK_TWO ] [ 1 ]= 0;
		g_userData[ playerid ] [ E_PERK_TWO ] [ 2 ]= 0;
		g_userData[ playerid ] [ E_SPECIAL ] [ 0 ] = 0;
		g_userData[ playerid ] [ E_SPECIAL ] [ 1 ] = 0;
		g_userData[ playerid ] [ E_SPECIAL ] [ 2 ] = 0;
		g_userData[ playerid ] [ E_KILLSTREAK1 ]= 0;
		g_userData[ playerid ] [ E_KILLSTREAK2 ]= 1;
		g_userData[ playerid ] [ E_KILLSTREAK3 ]= 3;
		g_userData[ playerid ] [ E_HITMARKER ]	= 0;
		g_userData[ playerid ] [ E_HIT_SOUND ] 	= 0;
		g_userData[ playerid ] [ E_CASH ] 		= 0;
		g_userData[ playerid ] [ E_VICTORIES ] 	= 0;
		g_userData[ playerid ] [ E_LOSSES ] 	= 0;
		g_userData[ playerid ] [ E_ZM_RANK ] 	= 0;
		g_userData[ playerid ] [ E_ZM_XP ] 		= 0;
		g_userData[ playerid ] [ E_ZM_KILLS ] 	= 0;
		g_userData[ playerid ] [ E_ZM_DEATHS ] 	= 0;
		g_userData[ playerid ] [ E_ZM_PRESTIGE ]= 0;
		g_userData[ playerid ] [ E_ZM_SKIN ] 	= -1;
		g_userData[ playerid ] [ E_VIP_LEVEL ] 	= 0;
		g_userData[ playerid ] [ E_VIP_EXPIRE ] = 0;
		g_userData[ playerid ] [ E_DOUBLE_XP ] 	= 0;
		g_userData[ playerid ] [ E_LIVES ] 		= 0;
		g_userData[ playerid ] [ E_MEDKIT ] 	= 0;
		g_userData[ playerid ] [ E_SKIN ] 		= 0;
		g_userData[ playerid ] [ E_WEAPONS ] [ 0 ] = 0;
		g_userData[ playerid ] [ E_WEAPONS ] [ 1 ] = 0;
		p_CustomSkin{ playerid } 				= false;
		p_GotScrambled{ playerid }              = false;
		p_SpectateMode{ playerid } 				= false;
	    p_SpectatingPlayer[ playerid ] 			= INVALID_PLAYER_ID;
	    p_Spawned{ playerid }                   = false;
	    p_claymoreDisabled{ playerid } 			= false;
	    p_SelectedGameClass[ playerid ]         = 0;
	    p_Team[ playerid ]                      = 0;
	    p_UsingRadio{ playerid } 				= false;
	    p_goingtoMenu[ playerid ]               = false;
	    p_Aiming{ playerid }                    = false;
	    p_MatchDeaths[ playerid ] 				= 0;
	    p_MatchKills[ playerid ]				= 0;
		DeathSpam{ playerid } 					= 0;
		p_AdminLog{ playerid } 					= false;
		p_CantUseAsk{ playerid } 				= false;
	    p_CantUseReport{ playerid }				= false;
		p_Warns[ playerid ]						= 0;
		p_RconLoginFails{ playerid } 			= 0;
		p_Muted{ playerid } 					= false;
		p_ToggledViewPM{ playerid } 			= false;
		p_PlayerLogged{ playerid }				= false;
		p_PmResponder[ playerid ] 				= INVALID_PLAYER_ID;
		p_Team[ playerid ]						= NO_TEAM;
		p_BittenTimer[ playerid ]				= 0xFFFF;
		p_BoughtArmour{ playerid } 				= false;
		p_BoughtDualPistols{ playerid } 		= false;
		p_Killstreak[ playerid ] 				= 0;
		Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
		p_SpawnKillLabel[ playerid ] 			= Text3D: INVALID_3DTEXT_ID;
		p_AntiSpawnKillEnabled{ playerid } 		= false;
		p_inMovieMode{ playerid } 				= false;
		p_AdminOnDuty{ playerid }				= false;
		p_FPSCounter{ playerid } 				= false;
		DestroyDynamicPickup( p_ThrowingkPickup[ playerid ] );
		p_ThrowingkPickup[ playerid ] 			= INVALID_OBJECT_ID;
	    ResetMatchData( playerid );
		StripPlayerFlag( playerid );
	    DestroyPlayerC4( playerid );
		DestroyDogTag( GetPlayerDogTag( playerid ) );
		TruncatePlayerClaymores( playerid );
		DestroyTacticalInsertion( playerid );
		ResetPlayerCash( playerid );
		endAGR( playerid );
		endLightningStrike( playerid );
	    endRCXD( playerid );
	    StopProgressBar( playerid );

	    Delete3DTextLabel( p_AdminLabel[ playerid ] );
	    p_AdminLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;

		for( new i; i < MAX_PLAYERS; i++ )
		{
			if ( i < MAX_KILLSTREAKS ) g_playerKillstreakAmount[ playerid ] [ i ] = 0;
			if ( i < 13 ) p_PreorderWeapons[ playerid ] [ i ] [ 0 ] = 0, p_PreorderWeapons[ playerid ] [ i ] [ 1 ] = 0;
			p_BlockedPM[ playerid ] [ i ] = false;
		}

		switch( reason )
		{
		    case 0:	format( szNormalString, 64, "%s(%d) has timed out from the server!", ReturnPlayerName( playerid ), playerid );
		    case 1: format( szNormalString, 64, "%s(%d) has left the server!", ReturnPlayerName( playerid ), playerid );
		    case 2: format( szNormalString, 64, "%s(%d) has been kicked from the server!", ReturnPlayerName( playerid ), playerid );
		}
		//IRC_GroupSay( gGroupID, IRC_CHANNEL, szNormalString );

		if ( !GetPVarInt( playerid, "banned_connection" ) ) SendDeathMessage( INVALID_PLAYER_ID, playerid, 201 );
	}
	return 1;
}

public OnPlayerSpawn( playerid )
{
	ResetPlayerWeapons( playerid ); // Players get two grenades, if not more...
	SetPlayerTeam( playerid, 1337 ); // Immunity
	p_LastSpawnTime[ playerid ] = GetTickCount( );

	if ( p_goingtoMenu[ playerid ] == true )
		return 1;

	if ( p_WasInMainMenu{ playerid } ) // Stops double spawn.
	{
		StopAudioStreamForPlayer( playerid );
		TogglePlayerSpectating( playerid, 0 ); // Stop player spectating bug (he flys and shit)
		p_WasInMainMenu{ playerid } = false;
		return 1;
	}

	p_Spawned{ playerid } = true;
	if ( justConnected{ playerid } == true )
	{
	    justConnected{ playerid } = false;
	    PreloadAnimationLibrary( playerid, "BOMBER" );
	    PreloadAnimationLibrary( playerid, "CARRY" );
	}

	UpdateRankExpData( playerid );
	RemovePlayerAttachedObject( playerid, 2 );

	if ( !p_inMovieMode{ playerid } )
	{
		if ( p_AdminOnDuty{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminOnDutyTD );
		if ( p_FPSCounter{ playerid } ) TextDrawShowForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	}

	if ( IsPlayerInZombies( playerid ) )
	{
		if ( GetPVarInt( playerid, "resurrection" ) != 1 && g_zm_gameData[ E_GAME_STARTED ] )
		{
			if ( g_userData[ playerid ] [ E_LAST_LOGGED ] >= g_LastFinishedRound && !p_SpectateMode{ playerid } && getAliveSurvivors( ) > 1 ) {
		        TogglePlayerDeadMode( playerid );
		        SendServerMessage( playerid, "You must wait the next round to play." );
		        return 1;
			}
		}
		else DeletePVar( playerid, "resurrection" );

		if ( p_SpectateMode{ playerid } ) // Resume Spectating - May be a cheater.
		{
		    TogglePlayerSpectating( playerid, 1 );

		    if ( IsPlayerInAnyVehicle( p_SpectatingPlayer[ playerid ] ) ) PlayerSpectateVehicle( playerid, GetPlayerVehicleID( p_SpectatingPlayer[ playerid ] ) );
			else PlayerSpectatePlayer( playerid, p_SpectatingPlayer[ playerid ] );
			return 1;
		}

		SetPlayerHealth( playerid, p_AdminOnDuty{ playerid } == true ? float( INVALID_PLAYER_ID ) : 100.0 );

		if ( g_userData[ playerid ] [ E_ZM_SKIN ] != -1 && g_userData[ playerid ] [ E_ZM_PRESTIGE ] ) SetPlayerSkin( playerid, g_userData[ playerid ] [ E_ZM_SKIN ] );
		else SetPlayerSkin( playerid, randarg( 190, 73, 247, 17, 5, 295, 69, 202 ) );

		cmd_shop( playerid, "" ); // Default show shop
		GivePlayerWeapon( playerid, 22, 0xFFFF );
		SetPlayerSkillLevel( playerid, WEAPONSKILL_PISTOL, p_BoughtDualPistols{ playerid } ? 1000 : 0 );
		if ( p_BoughtArmour{ playerid } ) SetPlayerArmour( playerid, 100.0 );

	   	if ( !p_inMovieMode{ playerid } )
	   	{
			TextDrawShowForPlayer( playerid, g_RankBoxTD );
			TextDrawShowForPlayer( playerid, g_RankTD );
			TextDrawShowForPlayer( playerid, g_EvacuationTD );
			TextDrawShowForPlayer( playerid, p_XPAmountTD[ playerid ] );
			TextDrawShowForPlayer( playerid, p_RankTD[ playerid ] );
			TextDrawShowForPlayer( playerid, g_WebsiteTD[ 1 ] );
			TextDrawShowForPlayer( playerid, g_MotdTD );
		}
		TextDrawHideForPlayer( playerid, g_SpectateBoxTD );
		TextDrawHideForPlayer( playerid, g_SpectateTD[ playerid ] );

		for( new i = 0; i < sizeof( p_PreorderWeapons[ ] ); i++ )
		{
			if ( p_PreorderWeapons[ playerid ] [ i ] [ 0 ] != 0 && p_PreorderWeapons[ playerid ] [ i ] [ 1 ] != 0 )
			{
				GivePlayerWeapon( playerid, p_PreorderWeapons[ playerid ] [ i ] [ 0 ], p_PreorderWeapons[ playerid ] [ i ] [ 1 ] );
			}
		}

		/* ** Load Objects ** */
		TogglePlayerControllable( playerid, 0 );
		SetTimerEx( "unpause_Player", 3000, false, "d", playerid );
		/* ** Load Objects ** */

		SpawnPlayerToBase( playerid, 0, 1.0, .zombie = 1 );
	}
	else
	{
		if ( p_SelectedGameClass[ playerid ] == 0 )
		{
		    format( szLargeString, 512, ""COL_GREY"[DEFAULT]{FFFFFF} AK-47, USP (Silenced)\n"COL_GREY"[DEFAULT]{FFFFFF} Combat Shotgun, USP (Silenced)\n"COL_GREY"[CLASS]{FFFFFF} %s\n"COL_GREY"[CLASS]{FFFFFF} %s\n"COL_GREY"[CLASS]{FFFFFF} %s", g_userData[ playerid ] [ E_CLASS1 ], g_userData[ playerid ] [ E_CLASS2 ], g_userData[ playerid ] [ E_CLASS3 ] );
			ShowPlayerDialog( playerid, DIALOG_CHOOSE_CLASS, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Choose Class", szLargeString, "Select", "" );
		}
		else
		{
		    switch( p_SelectedGameClass[ playerid ] )
		    {
				case 1:
				{
			     	GivePlayerWeapon( playerid, 23, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, 30, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 2:
				{
			     	GivePlayerWeapon( playerid, 23, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, 27, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 3:
				{
			     	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_SECONDARY1 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_PRIMARY1 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 4:
				{
			     	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_SECONDARY2 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_PRIMARY2 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 5:
				{
			     	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_SECONDARY3 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_PRIMARY3 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
		    }

		    handlePlayerSpawnEquipment( playerid );
	   	}


		/* ** Anti-Spawn Kill ** */
		SetPlayerHealth( playerid, INVALID_PLAYER_ID );
		Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
		p_SpawnKillLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	    p_SpawnKillLabel[ playerid ] = Create3DTextLabel( "Spawn Protected!", COLOR_GOLD, 0.0, 0.0, 0.0, 15.0, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ] );
	    Attach3DTextLabelToPlayer( p_SpawnKillLabel[ playerid ], playerid, 0.0, 0.0, 0.3 );
	    p_AntiSpawnKillEnabled{ playerid } = true;
		p_AntiSpawnKill[ playerid ] = gettime( ) + 4;
		/* ** Anti-Spawn Kill ** */

		/* ** Disable Killstreaks If /Spawn'd ** */
		endAGR( playerid );
		endRCXD( playerid );
		endLightningStrike( playerid );

		/* ** Load Objects ** */
		TogglePlayerControllable( playerid, 0 );
		SetTimerEx( "unpause_Player", 3000, false, "d", playerid );
		/* ** Load Objects ** */

		if ( g_userData[ playerid ] [ E_VIP_LEVEL ] == 3 )
			SetPlayerSkillLevel( playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 1000 );
		else
			SetPlayerSkillLevel( playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 1 );

		if ( !p_CustomSkin{ playerid } ) SetPlayerSkin( playerid, p_Team[ playerid ] == TEAM_TROPAS ? g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_SKIN_1 ] : g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_SKIN_2 ] );
		else SetPlayerSkin( playerid, g_userData[ playerid ] [ E_SKIN ] );

		if ( p_AdminLog{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminLogTD );

		if ( g_mp_gameData[ E_STARTED ] == false && g_mp_gameData[ E_STARTING ] == false ) TextDrawShowForPlayer( playerid, g_ShortPlayerNoticeTD );

		RemovePlayerAttachedObject( playerid, 2 ); // Throwing knife
	    p_claymoreDisabled{ playerid } = false;

		if ( IsPlayerInMatch( playerid ) ) SetTimerEx( "UAV_DATA", 1500, false, "d", playerid ); // Weird Bug.

	   	if ( !p_inMovieMode{ playerid } )
	   	{
			TextDrawShowForPlayer( playerid, p_ExperienceTD[ playerid ] );
			TextDrawShowForPlayer( playerid, p_RankDataTD[ playerid ] );
			TextDrawShowForPlayer( playerid, g_HideCashBoxTD );
			TextDrawShowForPlayer( playerid, g_WebsiteTD[ 0 ] );
			TextDrawShowForPlayer( playerid, g_MotdTD );

			if ( g_mp_gameData[ E_STARTED ] == true )
			{
				TextDrawHideForPlayer( playerid, g_RoundStartNote );
		    	TextDrawShowForPlayer( playerid, g_RoundTimeTD );
		    	TextDrawShowForPlayer( playerid, g_RoundBoxWhereTeam );
		  		TextDrawShowForPlayer( playerid, p_RoundPlayerTeam[ playerid ] );
		  		TextDrawShowForPlayer( playerid, g_tropasRoundBox );
		  		TextDrawShowForPlayer( playerid, g_tropasScoreText );
		  		TextDrawShowForPlayer( playerid, g_op40RoundBox );
		  		TextDrawShowForPlayer( playerid, g_op40ScoreText );
				TextDrawShowForPlayer( playerid, g_RoundGamemodeTD );
		    }
	   	}

	    SpawnPlayerToBase( playerid );
	}
	return 1;
}

stock hideMatchTextDraws( playerid )
{
	// mp
	TextDrawHideForPlayer( playerid, p_ExperienceTD[ playerid ] );
	TextDrawHideForPlayer( playerid, p_RankDataTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_HideCashBoxTD );
	TextDrawHideForPlayer( playerid, g_RoundStartNote );
	TextDrawHideForPlayer( playerid, g_RoundTimeTD );
	TextDrawHideForPlayer( playerid, g_RoundBoxWhereTeam );
	TextDrawHideForPlayer( playerid, p_RoundPlayerTeam[ playerid ] );
	TextDrawHideForPlayer( playerid, g_tropasRoundBox );
	TextDrawHideForPlayer( playerid, g_tropasScoreText );
	TextDrawHideForPlayer( playerid, g_op40RoundBox );
	TextDrawHideForPlayer( playerid, g_op40ScoreText );
	TextDrawHideForPlayer( playerid, g_RoundGamemodeTD );
	TextDrawHideForPlayer( playerid, g_WebsiteTD[ 0 ] );

	// zm
	TextDrawHideForPlayer( playerid, g_EvacuationTD );
	TextDrawHideForPlayer( playerid, g_RankBoxTD );
	TextDrawHideForPlayer( playerid, g_RankTD );
	TextDrawHideForPlayer( playerid, g_WebsiteTD[ 1 ] );
	TextDrawHideForPlayer( playerid, g_EvacuationTD );
	TextDrawHideForPlayer( playerid, p_XPAmountTD[ playerid ] );
	TextDrawHideForPlayer( playerid, p_RankTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_SpectateBoxTD );
	TextDrawHideForPlayer( playerid, g_SpectateTD[ playerid ] );

	// etc
	TextDrawHideForPlayer( playerid, g_MotdTD );
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	HidePlayerInfoDialog( playerid );
}

public FCNPC_OnSpawn( npcid )
{
	new name[ 24 ];
	GetPlayerName( npcid, name, sizeof( name ) );

	SetPlayerVirtualWorld( npcid, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] );


	if ( npcid == g_DeathLogNPC[ 0 ] ) 	return SetPlayerColor( npcid, COLOR_ZOMBIE );
	if ( npcid == g_DeathLogNPC[ 1 ] ) 	return SetPlayerColor( npcid, COLOR_BOOMER );
	if ( npcid == g_DeathLogNPC[ 2 ] ) 	return SetPlayerColor( npcid, COLOR_TANK );

	// Zombie
	if ( strfind( name, "Zombie_", true ) != -1 ) // Name-check because of helicopter
	{
		FCNPC_SetHealth( npcid, 0xFFFF ); // Hacker may kill em all
		FCNPC_SetPosition( npcid, 3000.0, 3000.0, 2000.0 );
	}

	// Helicopter
	if ( !strcmp( name, "Helicopter", false ) )
	{
		SetPlayerVirtualWorld( npcid, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] );
		g_HelicopterNPC = npcid;
		FCNPC_SetPosition( npcid, 3000.0, 3000.0, 2000.0 );
		FCNPC_SetHealth( npcid, 0xFFFF );
		FCNPC_SetArmour( npcid, 0xFFFF );
		FCNPC_SetSkin( npcid, 287 );
	}
	return 1;
}

public FCNPC_OnRespawn( npcid )
{
	new zID = GetZombieIDFromNPC( npcid );
	if ( g_zombieData[ zID ] [ E_PERMITTED ] )
	{
  		FCNPC_SetHealth( npcid, g_zombieData[ zID ] [ E_SPAWN_HEALTH ] );
		g_zombieData[ zID ] [ E_HEALTH ] = g_zombieData[ zID ] [ E_SPAWN_HEALTH ];

		SpawnPlayerToBase( npcid, 0, 1.0, 1 );

  		SetPlayerColor( npcid, COLOR_ZOMBIE );
	}
	else
	{
		FCNPC_SetHealth( npcid, 0xFFFF ); // Hacker may kill em all
		FCNPC_SetPosition( npcid, 3000.0, 3000.0, 2000.0 );
	}
	return 1;
}

public FCNPC_OnDeath( npcid, killerid, weaponid )
{
	new
		zombieid = GetZombieIDFromNPC( npcid ),
	    Float: X, Float: Y, Float: Z
	;

	weaponid = GetPVarInt( npcid, "weaponid" );
	killerid = GetPVarInt( npcid, "killerid" );
	DeletePVar( npcid, "killerid" );
	DeletePVar( npcid, "weaponid" );

	FCNPC_Stop( npcid );
	FCNPC_GetPosition( npcid, X, Y, Z );

	if ( weaponid == 666 )
		SendDeathMessageToMode( MODE_ZOMBIES, g_DeathLogNPC[ GetZombieType( zombieid ) ], killerid, 51 );
 	else
		SendDeathMessageToMode( MODE_ZOMBIES, killerid, g_DeathLogNPC[ GetZombieType( zombieid ) ], weaponid );

	if ( IsPlayerConnected( killerid ) && !IsPlayerNPC( killerid ) )
	{
		GivePlayerXP( killerid, 10 );
		g_userData[ killerid ] [ E_ZM_KILLS ] ++;
	}

    SetTimerEx( "onZombieSetForRespawn", 5000, false, "dfff", zombieid, X, Y, Z );
	return 1;
}

stock SendDeathMessageToMode( mode, killer, killee, weapon )
{
	switch( mode )
	{
		case MODE_MULTIPLAYER:
		{
			foreach(new i : mp_players)
    			SendDeathMessageToPlayer( i, killer, killee, weapon );
		}
		case MODE_ZOMBIES:
		{
			foreach(new i : zm_players)
    			SendDeathMessageToPlayer( i, killer, killee, weapon );
		}
	}
}

class onZombieSetForRespawn( zombieid, Float: X, Float: Y, Float: Z )
{
	CreateDroppablePickup( X, Y, Z, g_zombieData[ zombieid ] [ E_SKINID ] == SKIN_TANK ? true : false );

	g_zombieData[ zombieid ] [ E_PERMITTED ] = false;
	SetPlayerColor( g_zombieData[ zombieid ] [ E_NPCID ], COLOR_YELLOW );
    SpawnAvailableZombie( g_zombieData[ zombieid ] [ E_SKINID ] );
	return 1;
}

stock UpdateRankExpData( playerid )
{
	static const
		mp_rank_divisor = 3200,
		zm_rank_divisor = 2250
	;

	new current_rank, szRank[ 3 ];

	if ( IsPlayerInZombies( playerid ) )
	{
		current_rank = ( g_userData[ playerid ] [ E_ZM_XP ] / zm_rank_divisor );

		if ( current_rank < 1 ) 	current_rank = 0;
		else if ( current_rank > 30 ) current_rank = 30;

		format( szRank, sizeof szRank, "%d", current_rank );

		if ( g_userData[ playerid ] [ E_ZM_RANK ] < current_rank )
			CallLocalFunction( "OnPlayerAdvanceRank", "ddd", playerid, g_userData[ playerid ] [ E_RANK ], current_rank );

		g_userData[ playerid ] [ E_ZM_RANK ] = current_rank;
		SetPlayerScore( playerid, g_userData[ playerid ] [ E_ZM_RANK ] );

		if ( current_rank != 30 ) format( szNormalString, 64, "%d / %d", g_userData[ playerid ] [ E_ZM_XP ], ( ( g_userData[ playerid ] [ E_ZM_RANK ] + 1 ) * zm_rank_divisor ) );
		else szNormalString = "~p~~r~Prestige Ready!";

		TextDrawSetString( p_XPAmountTD[ playerid ], szNormalString );
		TextDrawSetString( p_RankTD[ playerid ], szRank );
	}
	else
	{
		current_rank = ( g_userData[ playerid ] [ E_XP ] / mp_rank_divisor );

		if ( current_rank < 1 ) current_rank = 0;
		else if ( current_rank > 50 ) current_rank = 50;

		if ( g_userData[ playerid ] [ E_RANK ] < current_rank )
			CallLocalFunction( "OnPlayerAdvanceRank", "ddd", playerid, g_userData[ playerid ] [ E_RANK ], current_rank );

		g_userData[ playerid ] [ E_RANK ] = current_rank;
		SetPlayerScore( playerid, g_userData[ playerid ] [ E_RANK ] );

		format( sz_Name, 11, "%09d", g_userData[ playerid ] [ E_XP ] );
		TextDrawSetString( p_ExperienceTD[ playerid ], sz_Name );

		new exp_till_next = ( ( g_userData[ playerid ] [ E_RANK ] + 1 ) * mp_rank_divisor ) - g_userData[ playerid ] [ E_XP ];

		if ( current_rank != 50 ) format( szNormalString, 64, "Rank %d~n~~w~~h~%d XP Till Rank %d", current_rank, exp_till_next, g_userData[ playerid ] [ E_RANK ] + 1 );
		else szNormalString = "Rank 50~n~~w~~h~Ready For Prestige!";

		TextDrawSetString( p_RankDataTD[ playerid ], szNormalString );
	}
	return 1;
}

class OnPlayerAdvanceRank( playerid, old_rank, new_rank )
{
	static
		szString[ 21 ];

	format( szString, sizeof( szString ) , "You are now rank %d!", new_rank );
	TextDrawSetString( p_NewRankTD[ playerid ], szString );
	TextDrawShowForPlayer( playerid, g_PromotedTD );
	TextDrawShowForPlayer( playerid, p_NewRankTD[ playerid ] );
	SetTimerEx( "HideNewRankForPlayer", 5000, false, "d", playerid );
	if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://www.irresistiblegaming.com/game_sounds/levelup.mp3" );
}

class HideNewRankForPlayer(playerid)
{
	TextDrawHideForPlayer( playerid, g_PromotedTD );
	TextDrawHideForPlayer( playerid, p_NewRankTD[ playerid ] );
}

class UAV_DATA( playerid )
{
	foreach(new x : mp_players)
    {
        if ( !IsPlayerSpawned( x ) ) continue;
		if ( p_Team[ playerid ] == NO_TEAM ) continue;

		if ( p_Team[ playerid ] == p_Team[ x ] )
		{
	       	SetPlayerMarkerForPlayer( playerid, x, ( GetPlayerColor( x ) & ReturnPlayerTeamColor( x ) ) );
        	SetPlayerMarkerForPlayer( x, playerid, ( GetPlayerColor( playerid ) & ReturnPlayerTeamColor( playerid ) ) );
		}
		else
		{
		    if ( g_UAVOnline{ p_Team[ playerid ] } == false )
		    {
      	     	SetPlayerMarkerForPlayer( playerid, x, ( GetPlayerColor( x ) & 0xFFFFFF00 ) );
	        	SetPlayerMarkerForPlayer( x, playerid, ( GetPlayerColor( playerid ) & 0xFFFFFF00 ) );
			}
		}
	}
}

stock rewardKillstreaks( playerid, killstreak )
{
	for( new i, neededkills; i < MAX_KILLSTREAKS; i++ )
	{
	    neededkills = ( getPlayerSecondPerk( playerid ) == PERK_HARDLINE ? ( g_killstreakData[ i ] [ E_KILLS ] - 1 ) : ( g_killstreakData[ i ] [ E_KILLS ] ) );

	    if ( g_killstreakData[ i ] [ E_ID ] == g_userData[ playerid ] [ E_KILLSTREAK1 ] && neededkills == killstreak ) {
	        GivePlayerKillstreak( playerid, g_userData[ playerid ] [ E_KILLSTREAK1 ] );
	        break;
		}
	    if ( g_killstreakData[ i ] [ E_ID ] == g_userData[ playerid ] [ E_KILLSTREAK2 ] && neededkills == killstreak ) {
	        GivePlayerKillstreak( playerid, g_userData[ playerid ] [ E_KILLSTREAK2 ] );
	        break;
		}
	    if ( g_killstreakData[ i ] [ E_ID ] == g_userData[ playerid ] [ E_KILLSTREAK3 ] && neededkills == killstreak ) {
	        GivePlayerKillstreak( playerid, g_userData[ playerid ] [ E_KILLSTREAK3 ] );
	        break;
		}
	}
}

public OnPlayerExplosion( killerid, playerid, reason )
{
	if ( p_AntiSpawnKillEnabled{ playerid } == true )
		return 0;

	ForcePlayerKill( playerid, killerid, reason );
	return 1;
}

public OnPlayerCheatDetected( playerid, detection )
{
	SendClientMessageToAdmins( -1, ""COL_AC"[ANTI-CHEAT]"COL_GREY" %s(%d) has been detected for %s.", ReturnPlayerName( playerid ), playerid, detectionToString( detection ) );
	printf("[CHEATER] [%s] %s(%d) -> state = %d, idletime = %d, zombies = %d, camera mode = %d, camera zoom = %f, aindex = %d", detectionToString( detection ), ReturnPlayerName( playerid ), playerid, GetPlayerState( playerid ), GetTickCount( ) - p_AFKTimestamp[ playerid ], IsPlayerInZombies( playerid ), GetPlayerCameraMode(playerid), GetPlayerCameraZoom(playerid), GetPlayerAnimationIndex(playerid)  );
	return 1;
}

public OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
{
	if ( IsPlayerNPC( playerid ) )
		return 1; // They have their own callback

	new
	    Float: X, Float: Y, Float: Z,
	    animlib[ 32 ], animname[ 32 ]
	;

	new time = gettime( );
	switch( time - LastDeath[ playerid ] )
	{
		case 0 .. 3:
		{
			DeathSpam{ playerid }++;
			if ( DeathSpam{ playerid } == 3 )
			{
				SendClientMessageToAllFormatted( -1, ""COL_AC"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for fake-killing.", ReturnPlayerName( playerid ), playerid );
				BanEx( playerid, "Fake-kill" );
				return 1;
			}
		}
		default: DeathSpam{ playerid } = 0;
	}

	LastDeath[ playerid ] = time;
    p_Spawned{ playerid } = false;
    p_claymoreDisabled{ playerid } = false;
    CutSpectation( playerid );
	StripPlayerFlag( playerid );
	endAGR( playerid );
	endRCXD( playerid );
	endLightningStrike( playerid );
	TruncatePlayerClaymores( playerid );

	DestroyDynamicPickup( p_ThrowingkPickup[ playerid ] );
	p_ThrowingkPickup[ playerid ] = INVALID_OBJECT_ID;

    GetAnimationName( p_LastAnimIndex[ playerid ], animlib, 32, animname, 32 );
    if ( strcmp( animlib, "PED", true ) != 0 ) ClearAnimations( playerid );

	p_MatchDeaths[ playerid ] ++;
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );

	if ( IsPlayerInZombies( playerid ) ) g_userData[ playerid ] [ E_ZM_DEATHS ] ++;
	else g_userData[ playerid ] [ E_DEATHS ] ++;

	if ( IsPlayerConnected( killerid ) )
	{
		if ( IsPlayerInZombies( playerid ) || IsPlayerInZombies( killerid ) )
		{
			if ( IsPlayerNPC( killerid ) )
			{
				SendDeathMessageToMode( MODE_ZOMBIES, g_DeathLogNPC[ 0 ], playerid, 53 );
				TogglePlayerDeadMode( playerid );
			}
		}
		else
		{
			if ( p_Team[ killerid ] == p_Team[ playerid ] )
				return SendServerMessage( playerid, "Fake-kill detected 0xA2." );

			g_userData[ killerid ] [ E_KILLS ] ++;
		    p_MatchKills[ killerid ] ++;
			rewardKillstreaks( killerid, p_Killstreak[ killerid ]++ );
			GivePlayerXP( killerid, 25 );

			SendDeathMessageToMode( MODE_MULTIPLAYER, killerid, playerid, reason );

			g_mp_gameData[ E_KILLS ] ++;
			if ( g_mp_gameData[ E_KILLS ] == 1 ) {
				SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_WHITE" %s(%d) - "COL_RED" First Blood!", ReturnPlayerName( killerid ), killerid );
				GivePlayerXP( killerid, 50 );
			}

			if ( p_Killstreak[ playerid ] > 3 ) {
				SendClientMessageFormatted( killerid, -1, ""COL_ORANGE"[GAME]"COL_RED" Buzz Kill! "COL_WHITE"You've killed %s(%d) with a killstreak over 3!", ReturnPlayerName( playerid ), playerid );
				GivePlayerXP( killerid, 25 );
			}

			GetPlayerPos( playerid, X, Y, Z );
	        switch( g_mp_gameData[ E_GAMEMODE ] )
	        {
				case MODE_TDM: GiveTeamScore( p_Team[ killerid ], 100, killerid ), GivePlayerXP( killerid, 50 );
				case MODE_KC:  CreateDogTag( playerid, killerid, X, Y, Z );
	        }

	        /* ** SCAVENGER ** */
			if ( getPlayerFirstPerk( playerid ) == PERK_SCAVENGER )
			{
				new weapon;

			 	switch( p_SelectedGameClass[ killerid ] )
		 		{
				    case 1:
				    {
				    	if ( IsWeaponSlotOccupied( playerid, GetWeaponSlot( g_userData[ killerid ] [ E_SECONDARY1 ] ), weapon ) )
				    		GivePlayerWeapon( playerid, weapon, RandomEx( 10, 30 ) );
				    	else
				     		GivePlayerWeapon( killerid, g_userData[ killerid ] [ E_SECONDARY1 ], RandomEx( 10, 30 ) );

				    	if ( IsWeaponSlotOccupied( playerid, GetWeaponSlot( g_userData[ killerid ] [ E_PRIMARY1 ] ), weapon ) )
				    		GivePlayerWeapon( playerid, weapon, RandomEx( 10, 30 ) );
				    	else
				       		GivePlayerWeapon( killerid, g_userData[ killerid ] [ E_PRIMARY1 ], RandomEx( 25, 75 ) );
				    }
				    case 2:
					{
				    	if ( IsWeaponSlotOccupied( playerid, GetWeaponSlot( g_userData[ killerid ] [ E_SECONDARY2 ] ), weapon ) )
				    		GivePlayerWeapon( playerid, weapon, RandomEx( 10, 30 ) );
				    	else
				     		GivePlayerWeapon( killerid, g_userData[ killerid ] [ E_SECONDARY2 ], RandomEx( 10, 30 ) );

				    	if ( IsWeaponSlotOccupied( playerid, GetWeaponSlot( g_userData[ killerid ] [ E_PRIMARY2 ] ), weapon ) )
				    		GivePlayerWeapon( playerid, weapon, RandomEx( 10, 30 ) );
				    	else
				       		GivePlayerWeapon( killerid, g_userData[ killerid ] [ E_PRIMARY2 ], RandomEx( 25, 75 ) );
				    }
				    case 3:
					{
				    	if ( IsWeaponSlotOccupied( playerid, GetWeaponSlot( g_userData[ killerid ] [ E_SECONDARY3 ] ), weapon ) )
				    		GivePlayerWeapon( playerid, weapon, RandomEx( 10, 30 ) );
				    	else
				     		GivePlayerWeapon( killerid, g_userData[ killerid ] [ E_SECONDARY3 ], RandomEx( 10, 30 ) );

				    	if ( IsWeaponSlotOccupied( playerid, GetWeaponSlot( g_userData[ killerid ] [ E_PRIMARY3 ] ), weapon ) )
				    		GivePlayerWeapon( playerid, weapon, RandomEx( 10, 30 ) );
				    	else
				       		GivePlayerWeapon( killerid, g_userData[ killerid ] [ E_PRIMARY3 ], RandomEx( 25, 75 ) );
				    }
				}
			}
		}
    }
	else
	{
		if ( IsPlayerInZombies( playerid ) )
		{
			SendDeathMessageToMode( MODE_ZOMBIES, g_DeathLogNPC[ 0 ], playerid, 53 );
			TogglePlayerDeadMode( playerid );
		}
		else SendDeathMessageToMode( MODE_MULTIPLAYER, INVALID_PLAYER_ID, playerid, 53 );
	}

	// Some times just need to be called later...
	p_Killstreak[ playerid ] = 0;
	return 1;
}

stock CreateCarePackage( playerid )
{
	new ID = Iter_Free(carepackages);

	if ( ID == -1 )
		return SendError( playerid, "There are many packages lying/being called. Please wait." );

	new Float: X, Float: Y, Float: Z;
	GetPlayerPos( playerid, X, Y, Z );

	g_carePackageData[ ID ] [ E_PACKAGE ] = CreateObject( 18849, X, Y, Z + 40, 0, 0, 0 );
	g_carePackageData[ ID ] [ E_FLARE ] = CreateObject( 18728, X, Y, Z - 2.5, 0, 0, 0 );

	Iter_Add(carepackages, ID);
	MoveObject( g_carePackageData[ ID ] [ E_PACKAGE ], X, Y, Z + 6.4, 5.0 );
	return ID;
}

class OnPlayerUseKillstreak( playerid, killstreak_id )
{
	RemovePlayerAttachedObject( playerid, 0 );
	SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
    if ( p_Busy{ playerid } ) return SendError( playerid, "You are currently busy." );
	if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You cannot use a killstreak if you're not spawned." );
	if ( g_TacticalNuke == true ) return SendError( playerid, "No killstreaks can be used while a tactical nuke is inbound." );
	if ( g_mp_gameData[ E_STARTED ] == false ) return SendError( playerid, "You cannot use this while the round hasn't started!" );

	switch( killstreak_id )
	{
	    case KS_RCXD: CreateRCXD( playerid );
	    case KS_UAV: CreateUAV( playerid );
	    case KS_COUNTER_UAV: CreateCounterUAV( playerid );
	    case KS_CARE_PACKAGE:
	    {
		    if ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_INTERIOR ] != 0 )
		    	return SendError( playerid, "This killstreak is unavailable on this map." );

	    	CreateCarePackage( playerid );
	    }
	    case KS_MORTAR_TEAM:
		{
			new teamid = p_Team[ playerid ] == TEAM_TROPAS ? TEAM_OP40 : TEAM_TROPAS;
			SetTimerEx( "mortarTeam_Deploy", 750, false, "ddd", playerid, teamid, 0 );
	    }
    	case KS_LIGHTNING_STRIKE:
    	{
    		if ( g_LightningStrikeUser != INVALID_PLAYER_ID )
		        return SendError( playerid, "Please try again later." );

		    if ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_INTERIOR ] != 0 )
		    	return SendError( playerid, "This killstreak is unavailable on this map." );

    		StartLightingStrike( playerid );
	    }
	    case KS_AGR: StartAGR( playerid );
	    case KS_VTOL_WARSHIP:
		{
		    if ( g_warshipData[ E_OCCUPIED ] == true )
		        return SendError( playerid, "Please try again later." );

		    if ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_INTERIOR ] != 0 )
		    	return SendError( playerid, "This killstreak is unavailable on this map." );

			GetMapMiddlePos( g_warshipData[ E_X ], g_warshipData[ E_Y ], g_warshipData[ E_Z ] );
			TextDrawShowForPlayer( playerid, g_CameraVectorAim[ 0 ] );
			TextDrawShowForPlayer( playerid, g_CameraVectorAim[ 1 ] );
			g_warshipData[ E_DEGREE ] = 0.0;
			g_warshipData[ E_Z ] += 30.0;
			new choppergunner = CreateObject( 1681, g_warshipData[ E_X ], g_warshipData[ E_Y ], g_warshipData[ E_Z ], 0.0, 0.0, 0.0 );
			new cameraobject = CreateObject( 19300, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
            AttachObjectToObject( cameraobject, choppergunner, 0.0, 0.0, -2.5, 0.0, 0.0, 0.0 );
            AttachCameraToObject( playerid, cameraobject );

            TextDrawSetString( p_KillstreakInstructions[ playerid ], "Fire Key - Shoot" );
            TextDrawShowForPlayer( playerid, p_KillstreakInstructions[ playerid ] );

            g_warshipData[ E_PLAYER_ID ] = playerid;
            IdlePlayer( playerid );

			g_warshipData[ E_TIMER ] = SetTimerEx( "VTOLWarship_Mechanism", 25, true, "ddf", playerid, choppergunner, cameraobject, g_warshipData[ E_Z ] );
			p_Busy{ playerid } = true;
			g_warshipData[ E_OCCUPIED ] = true;
		}
	    case KS_NUKE:
	    {
	    	if ( g_mp_gameData[ E_TIME ] < 20 )
	    		return SendError( playerid, "There isn't enough time for a nuke." );

	    	g_TacticalNuke = true;
	    	g_TacticalNukeTime = 15;
	    	TextDrawShowForAllInMode( MODE_MULTIPLAYER, g_TacticalNukeMissileTD );
	    	TextDrawSetString( g_TacticalNukeTimeTD, "Nuke in 15" );
	    	TextDrawShowForAllInMode( MODE_MULTIPLAYER, g_TacticalNukeTimeTD );

	    	SetTimerEx( "tacticalNuke_Countdown", 980, false, "dd", playerid, 0 );
	    }
	    default: return SendError( playerid, "An error has occured." );
	}

	format( szNormalString, 128, "%s(%d)~n~~w~%s Inbound!", ReturnPlayerName( playerid ), playerid, KillstreakToString( killstreak_id ) );
	TextDrawSetString( g_KillstreakAnnTD, szNormalString );
	TextDrawShowForAllInMode( MODE_MULTIPLAYER, g_KillstreakAnnTD ), SetTimerEx( "TextDrawTimedHide", 3000, false, "dd", _: g_KillstreakAnnTD, INVALID_PLAYER_ID );
	SetPlayerArmedWeapon( playerid, 0 );
	g_playerKillstreakAmount[ playerid ] [ killstreak_id ] --;
	return 1;
}

class tacticalNuke_Countdown( playerid, step )
{
	static
		szString[ 32 ], Float: X, Float: Y, Float: Z;

	if ( step < 15 )
	{
		format( szString, 32, "Nuke in %02d", g_TacticalNukeTime-- );
		TextDrawSetString( g_TacticalNukeTimeTD, szString );

		foreach(new i : mp_players)
		{
			if ( !IsPlayerInMatch( i ) )
				continue;

        	PlayerPlaySound( i, 1133, 0.0, 0.0, 5.0 );
		}

	 	SetTimerEx( "tacticalNuke_Countdown", 980, false, "dd", playerid, step + 1 );
	}
	else
	{
		TextDrawHideForAll( g_TacticalNukeTimeTD );
		TextDrawHideForAll( g_TacticalNukeMissileTD );

		foreach(new i : mp_players)
		{
			if ( !IsPlayerInMatch( i ) )
				continue;

			GetPlayerPos( i, X, Y, Z );

			ForcePlayerKill( i, p_Team[ i ] != p_Team[ playerid ] ? playerid : INVALID_PLAYER_ID, 51 );
			CreateExplosion( X, Y, Z, 6, 0.0 );
		}

		if ( IsPlayerConnected( playerid ) )
			GivePlayerXP( playerid, 500 );

		g_TacticalNuke = false;
	}
}

class TextDrawTimedHide( Text: textlol, playerid )
	return playerid == INVALID_PLAYER_ID ? TextDrawHideForAll( textlol ) : TextDrawHideForPlayer( playerid, textlol );

public OnVehicleSpawn( vehicleid )
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if ( !p_PlayerLogged{ playerid } )
		return SendError( playerid, "You must be logged in to talk." ), 0;

	if ( IsPlayerNPC( playerid ) )
		return 0; // Can incur bugs where the zombies talk ^.^

	GetServerVarAsString( "rcon_password", szNormalString, sizeof( szNormalString ) ); // Anti-rcon spam poop
	if ( strfind( text, szNormalString, true ) != -1 )
	    return SendError( playerid, "An error occured, please try again." ), 0;

	if ( textContainsIP( text ) )
		return SendServerMessage( playerid, "Please do not advertise." ), 0;

	if ( !TimeStampPassed( p_AntiTextSpam[ playerid ], 750 ) )
	{
		p_AntiTextSpam[ playerid ] = GetTickCount( );
	    p_AntiTextSpamCount{ playerid } ++;
	 	SendClientMessageFormatted( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You must wait 0.75 seconds before posting again. "COL_GREY"[%d/3]", p_AntiTextSpamCount{ playerid } );

	 	if ( p_AntiTextSpamCount{ playerid } >= 3 ) {
			SendServerMessage( playerid, "You have been kicked for chat flooding. Please refrain from flooding the chat." );
			KickPlayerTimed( playerid );
		}
		return 0;
	}

	p_AntiTextSpamCount{ playerid } = 0;
	p_AntiTextSpam[ playerid ] = GetTickCount( );

	if ( p_Muted{ playerid } )
	{
	 	if ( gettime( ) > g_userData[ playerid ] [ E_MUTE_TIME ] ) p_Muted{ playerid } = false;
		else
		{
		    SendError( playerid, "You are muted, you cannot speak." );
			return 0;
		}
	}

	switch( text[ 0 ] )
	{
	    case '!':
		{
			SendClientMessageToTeam( p_Team[ playerid ], ReturnPlayerTeamColor( playerid ), "<Team Chat> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
			return 0;
		}
		case '@':
		{
			if ( g_userData[ playerid ] [ E_ADMIN ] > 0 )
			{
				SendClientMessageToAdmins( -1, ""COL_ADMIN"<Admin Chat> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
			    return 0;
			}
		}
		case '#':
		{
			if ( g_userData[ playerid ] [ E_VIP_LEVEL ] > 0 )
		    {
				//IRC_GroupSayFormatted( gGroupID, IRC_CHANNEL, "5(VIP) %s(%d):7 %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
				SendClientMessageToAllFormatted( 0xFF9E3DFF, "[VIP] %s(%d):{C37550} %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
		        return 0;
		    }
		}
	}

	//IRC_GroupSayFormatted( gGroupID, IRC_CHANNEL, "%d%s(%d): %s", p_Team[ playerid ] == TEAM_SURVIVORS ? 3 : ( p_Team[ playerid ] == TEAM_TROPAS ? 12 : 4 ), ReturnPlayerName( playerid ), playerid, text );
	return 1;
}

public OnPlayerProgressUpdate( playerid, progressid )
{
	switch( progressid )
	{
	    case PROGRESS_HEALING:
	    {
	    	if ( !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) )
		    	return StopProgressBar( playerid );
	    }
	}
	return 1;
}

public OnPlayerProgressComplete( playerid, progressid )
{
	switch( progressid )
	{
	    case 0:
	    {
		    g_userData[ playerid ] [ E_MEDKIT ] --;
	    	SetPlayerHealth( playerid, 100.0 );
			SendServerMessage( playerid, "You have successfully healed yourself." );
	    }
	}
	return 1;
}

/* ** Commands ** */

public OnPlayerCommandPerformed( playerid, cmdtext[ ], success )
{
	if ( !success ) return SendError( playerid, "You have entered an invalid command. To display the command list type /commands or /cmds." );
	return ( 1 );
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if ( g_userData[ playerid ] [ E_ADMIN ] < 5 )
	{
		if ( TimeStampPassed( p_AntiCommandSpam[ playerid ], 1000 ) ) p_AntiCommandSpam[ playerid ] = GetTickCount( );
		else return SendError( playerid, "Please wait 1 second before submitting a command again." ), 0;

		if ( !IsPlayerSpawned( playerid ) && !strmatch( cmdtext, "/finish" ) && !p_SpectateMode{ playerid } ) return SendError( playerid, "You cannot use commands while you're not spawned." ), 0;
	}
	return 1;
}

CMD:changepassword( playerid, params[ ] ) return cmd_changepw( playerid, params );
CMD:changepass( playerid, params[ ] ) return cmd_changepw( playerid, params );
CMD:changepw( playerid, params[ ] ) return SendServerMessage( playerid, "Access account settings in the main menu to change your password." );

CMD:idof( playerid, params[ ] )
{
	new pID;
	if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/idof [PART_OF_NAME]" );
	if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "This player isn't connected." );
	SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" %s: "COL_GREY"%d", ReturnPlayerName( pID ), pID );
	return 1;
}

CMD:idletime( playerid, params[ ] ) {
	new pID;
	if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/idletime [PLAYER_ID]" );
	if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "This player isn't connected." );
	SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" %s(%d)'s idle time is "COL_GREY"%d milliseconds (ms)", ReturnPlayerName( pID ), pID, GetTickCount( ) - p_AFKTimestamp[ pID ] );
	return 1;
}

CMD:vipcmds( playerid, params[ ] )
{
	if ( !g_userData[ playerid ] [ E_VIP_LEVEL ] ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.irresistiblegaming.com" );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}V.I.P Commands", ""COL_GREY"/vipskinoff -"COL_WHITE" Disable VIP skin in multiplayer.\n"COL_GREY"/resurrect -"COL_WHITE" Resurrect with your life tokens in zombies.\n"COL_GREY"/vsay -"COL_WHITE" Global V.I.P Chat.", "Okay", "" );
	return 1;
}

CMD:shop( playerid, params[ ] )
{
	if ( g_zm_gameData[ E_GAME_STARTED ] ) return SendError( playerid, "You cannot buy weapons if the round has started." );
	if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You must be spawned to use this feature." );
	if ( !IsPlayerInZombies( playerid ) ) return SendError( playerid, "This command is only available in the zombies mode." );
	ShowPlayerShopMenu( playerid );
	return 1;
}

CMD:server( playerid, params[ ] )
{
	new
		spawned = 0;

	foreach(new z : zombies) if ( g_zombieData[ z ] [ E_PERMITTED ] ) spawned ++;

	format( szLargeString, sizeof( szLargeString ), ""COL_GREY"General Data"COL_WHITE"\n\nVersion: "#FILE_BUILD"\nTotal Players: %d / %d\nTotal MP Maps: %d\nTotal ZM Maps: %d\nTotal Maps: %d\n\n", Iter_Count(Player), GetMaxPlayers( ), Iter_Count(maps), Iter_Count(zm_maps), ( Iter_Count(maps) + Iter_Count(zm_maps) ) );
	format( szLargeString, sizeof( szLargeString ), "%s"COL_GREY"Multiplayer Data"COL_WHITE"\n\nTotal Players: %d\nTropas: %d\nOP40: %d\nMap Name: %s\nMap Author: %s\nTime Left: %s\n\n", szLargeString, Iter_Count(mp_players), g_TropasMembers, g_OP40Members, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_NAME ], g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_AUTHOR ], g_mp_gameData[ E_TIME ] > 0 ? TimeConvert( g_mp_gameData[ E_TIME ] ) : ( "00:00" ) );
	format( szLargeString, sizeof( szLargeString ), "%s"COL_GREY"Zombie Data"COL_WHITE"\n\nTotal Players: %d\nZombies Spawned: %d\nMap Name: %s\nMap Author: %s\nWave Start Time: %d\nTime Left: %s", szLargeString, Iter_Count(zm_players), spawned, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_NAME ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_AUTHOR ], g_WaveStarting, g_EvacuationTime > 0 ? TimeConvert( g_EvacuationTime ) : ( "Evacuation Started" ) );

	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, #SERVER_NAME, szLargeString, "Close", "" );
	return 1;
}

CMD:redeemvip( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_VIP, DIALOG_STYLE_INPUT, ""COL_GOLD"VIP Delivery Service", ""COL_WHITE"Enter the transaction ID of your donation below.\n\n"COL_GREY"See http://forum.irresistiblegaming.com/showthread.php?10125 for details.", "Redeem", "Close" );
	return 1;
}

CMD:resurrect( playerid, params[ ] )
{
	if ( !IsPlayerInZombies( playerid ) ) return SendError( playerid, "This command can only be used in the zombies mode." );
	if ( !g_userData[ playerid ] [ E_LIVES ] ) return SendError( playerid, "Unfortunately, you don't have any resurrection lives." );
	SendClientMessageToModeFormatted( MODE_ZOMBIES, -1, ""COL_RED"[GAME]"COL_GREY" %s(%d) has resurrected back into the game!", ReturnPlayerName( playerid ), playerid );
	g_userData[ playerid ] [ E_LIVES ] --;
	SetPVarInt( playerid, "resurrection", 1 );
    p_SpectatingPlayer[ playerid ] = INVALID_PLAYER_ID;
	p_SpectateMode{ playerid } = false;
	TextDrawHideForPlayer( playerid, g_SpectateBoxTD );
	TextDrawHideForPlayer( playerid, g_SpectateTD[ playerid ] );
	TogglePlayerSpectating( playerid, 0 );
	return 1;
}

CMD:vipskinoff( playerid, params[ ] )
{
    if ( g_userData[ playerid ] [ E_VIP_LEVEL ] < 1 ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.irresistiblegaming.com" );
    if ( p_CustomSkin{ playerid } == false ) return SendError( playerid, "Your VIP skin is already disabled." );
	p_CustomSkin{ playerid } = false;
	SendServerMessage( playerid, "You have disabled your vip skin." );
	return 1;
}

CMD:vsay( playerid, params[ ] )
{
    new msg[ 100 ];
    if ( g_userData[ playerid ] [ E_VIP_LEVEL ] < 1 ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.irresistiblegaming.com" );
    else if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/(v)ip [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendServerMessage( playerid, "Please do not advertise." );
    else
    {
     	if ( p_Muted{ playerid } )
		{
		 	if ( gettime( ) > g_userData[ playerid ] [ E_MUTE_TIME ] )
			 	p_Muted{ playerid } = false;
			else
				return SendError( playerid, "You are muted, you cannot speak." ), 1;
		}

		//IRC_GroupSayFormatted( gGroupID, IRC_CHANNEL, "5(VIP) %s(%d):7 %s", ReturnPlayerName( playerid ), playerid, msg );
		SendClientMessageToAllFormatted( 0xFF9E3DFF, "[VIP] %s(%d):{C37550} %s", ReturnPlayerName( playerid ), playerid, msg );
	}
	return 1;
}

CMD:lastlogged( playerid, params[ ] )
{
	static
	    player[ MAX_PLAYER_NAME ]
	;

	if ( sscanf( params, "s[24]", player ) ) return SendUsage( playerid, "/lastlogged [PLAYER_NAME]" );
	else
	{
		format( szNormalString, sizeof( szNormalString ), "SELECT `LAST_LOGGED` FROM `COD` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
  		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerLastLogged", "iis", playerid, 0, player );
	}
	return 1;
}

thread OnPlayerLastLogged( playerid, irc, player[ ] )
{
	new
	    rows, fields, time, Field[ 50 ]
	;
    cache_get_data( rows, fields );
	if ( rows )
	{
		cache_get_field_content( 0, "LAST_LOGGED", Field );

		time = gettime( ) - strval( Field );
		if ( time > 86400 )
		{
		    time /= 86400;
		    format( Field, sizeof( Field ), "%d days ago.", time );
		}
		else if ( time > 3600 )
		{
		    time /= 3600;
		    format( Field, sizeof( Field ), "%d hours ago.", time );
		}
		else
		{
		    time /= 60;
		    format( Field, sizeof( Field ), "%d minutes ago.", time );
		}

		if ( !irc ) SendClientMessageFormatted( playerid, COLOR_GREY, "[SERVER]"COL_RED" %s:"COL_WHITE" Last Logged: %s", player, Field );
		else {
			format( szNormalString, sizeof( szNormalString ),"7LAST LOGGED OF '%s': %s", player, Field );
			//IRC_GroupSay( gGroupID, IRC_CHANNEL, szNormalString );
		}
	}
	else {
		if ( !irc ) SendError( playerid, "Player not found." );
	}
	return 1;
}

CMD:stopradio( playerid, params[ ] )
{
	if ( IsPlayerUsingRadio( playerid ) ) p_UsingRadio{ playerid } = false;
    StopAudioStreamForPlayer( playerid );
	return 1;
}

CMD:radio( playerid, params[ ] )
{
    ShowPlayerDialog(playerid, DIALOG_RADIO, DIALOG_STYLE_LIST, "{FFFFFF}Radio Stations - List", g_RadioStations, "Select", "Close");
	return 1;
}

CMD:moviemode( playerid, params[ ] )
{
	switch( p_inMovieMode{ playerid } )
	{
		case true:
		{
			if ( IsPlayerInZombies( playerid ) )
			{
				if ( p_SpectateMode{ playerid } )
				{
					TextDrawShowForPlayer( playerid, g_SpectateBoxTD );
					TextDrawShowForPlayer( playerid, g_SpectateTD[ playerid ] );
				}
				else
				{
					TextDrawShowForPlayer( playerid, g_RankBoxTD );
					TextDrawShowForPlayer( playerid, g_RankTD );
					TextDrawShowForPlayer( playerid, g_EvacuationTD );
					TextDrawShowForPlayer( playerid, p_XPAmountTD[ playerid ] );
					TextDrawShowForPlayer( playerid, p_RankTD[ playerid ] );
					TextDrawShowForPlayer( playerid, g_WebsiteTD[ 1 ] );
					TextDrawShowForPlayer( playerid, g_MotdTD );
				}
			}
			else
			{
				TextDrawShowForPlayer( playerid, p_ExperienceTD[ playerid ] );
				TextDrawShowForPlayer( playerid, p_RankDataTD[ playerid ] );
				TextDrawShowForPlayer( playerid, g_HideCashBoxTD );
				TextDrawShowForPlayer( playerid, g_WebsiteTD[ 0 ] );
				TextDrawShowForPlayer( playerid, g_MotdTD );

				if ( g_mp_gameData[ E_STARTED ] == true )
				{
			    	TextDrawShowForPlayer( playerid, g_RoundTimeTD );
			    	TextDrawShowForPlayer( playerid, g_RoundBoxWhereTeam );
			  		TextDrawShowForPlayer( playerid, p_RoundPlayerTeam[ playerid ] );
			  		TextDrawShowForPlayer( playerid, g_tropasRoundBox );
			  		TextDrawShowForPlayer( playerid, g_tropasScoreText );
			  		TextDrawShowForPlayer( playerid, g_op40RoundBox );
			  		TextDrawShowForPlayer( playerid, g_op40ScoreText );
					TextDrawShowForPlayer( playerid, g_RoundGamemodeTD );
			    }
			}

			if ( p_AdminOnDuty{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminOnDutyTD );
			if ( p_FPSCounter{ playerid } ) TextDrawShowForPlayer( playerid, p_FPSCounterTD[ playerid ] );
			for( new i; i < sizeof( g_MovieModeTD ); i ++ ) TextDrawHideForPlayer( playerid, g_MovieModeTD[ i ] );
		    p_inMovieMode{ playerid } = false;
		    SendServerMessage( playerid, "Movie mode has been disabled." );
		}
		case false:
		{
			hideMatchTextDraws( playerid );
			for( new i; i < sizeof( g_MovieModeTD ); i ++ ) TextDrawShowForPlayer( playerid, g_MovieModeTD[ i ] );
		    p_inMovieMode{ playerid } = true;
		    SendServerMessage( playerid, "Movie mode has been enabled." );
		}
	}
	return 1;
}

CMD:myaccid( playerid, params[ ] )
{
    SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" Your account ID is "COL_GOLD"%d"COL_WHITE".", g_userData[ playerid ] [ E_ID ] );
	return 1;
}

CMD:obj( playerid, params[ ] ) return cmd_objective( playerid, params );
CMD:objective( playerid, params[ ] )
{
	switch( g_mp_gameData[ E_GAMEMODE ] )
	{
	    case MODE_TDM:
	    {
    		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, DIALOG_TITLE, ""COL_ORANGE"Team Deathmatch{FFFFFF}\n\n"\
													"The main objective in Team Deathmatch is to eliminate all enemies.\nYou're put in to teams and cannot team kill.\nEach kill you get will give you XP and points for your team.", "Okay", "" );
	    }
	    case MODE_CTF:
	    {
    		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, DIALOG_TITLE, ""COL_ORANGE"Capture the Flag{FFFFFF}\n\n"\
													"The main objective in Capture the Flag is to get the enemies flag.\nYou're put in to teams and cannot team kill.\nYou must bring the enemies flag to your base before they do.\nEach time you capture a flag you'll earn XP and points for your team.", "Okay", "" );
	    }
	    case MODE_KC:
	    {
    		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, DIALOG_TITLE, ""COL_ORANGE"Kill Confirmed{FFFFFF}\n\n"\
													"The main objective in Kill Confirmed is to get the enemy's dogtags.\nYou're put in to teams and cannot team kill.\nYou must take the dogtags after you kill a person.\nRunning over your team mates dog tag will deny a kill for them.\nEach time you confirm a kill, you'll earn XP and points for your team. Denying just gives XP.", "Okay", "" );
	    }
	    default: return 0;
	}
	return 1;
}

CMD:statistics( playerid, params[ ] ) return cmd_stats( playerid, params );
CMD:stats( playerid, params[ ] )
{
	if ( !p_PlayerLogged{ playerid } )
		return SendError( playerid, "You are not logged in meaning you cannot access this command." );

	p_ViewingStats[ playerid ] = playerid;
	ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Statistics", "General Statistics\nMultiplayer Statistics\nZombie Statistics", "Select", "Cancel" );
	return 1;
}

CMD:twitter( playerid, params[ ] ) return cmd_updates( playerid, params );
CMD:updates( playerid, params[ ] )
{
    SendServerMessage( playerid, "Reading latest tweets from {00CCFF}www.twitter.com/#!/IrresistibleDev{FFFFFF}, please wait!" );
	HTTP( playerid, HTTP_GET, "irresistiblegaming.com/cnr_twitter.php", "", "OnTwitterHTTPResponse" );
	return 1;
}

CMD:savestats( playerid, params[ ] )
{
	new
		iTime = gettime( );

	if ( iTime < GetPVarInt( playerid, "antispam_savestats" ) )
		return SendError( playerid, "You must wait 30 seconds before saving your statistics again." );

    SavePlayerData( playerid );
    SetPVarInt( playerid, "antispam_savestats", iTime + 30 );
    SendServerMessage( playerid, "Your statistics have been saved." );
	return 1;
}

CMD:finish( playerid, params[ ] )
{
	if ( IsPlayerInMatch( playerid ) )
		return SendError( playerid, "You must be in combat configuration to use this." );

	if ( GetPVarInt( playerid, "editing_class" ) != 1 )
		return SendError( playerid, "You're not customizing any class." );

	StopPlayerEditingCreateClass( playerid );
	return 1;
}

CMD:kill( playerid, params[ ] )
{
	if ( !IsPlayerInWater( playerid ) ) return SendError( playerid, "This command can only be used once you're in water." );
	ForcePlayerKill( playerid, INVALID_PLAYER_ID, 47 );
	return 1;
}

CMD:controls( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}"#SERVER_NAME" - Commands", "SPACE - Redeem Carepackage\nFIRE - Throw Tomahawk/Detonate C4\nKEY 'N' - Show Available Killstreaks\nKEY 'Y' - Use Special (Insertion, C4 and Claymore)", "Okay", "" );
	return 1;
}

CMD:rules( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Rules", szRules, "Okay", "" );
	return 1;
}

CMD:admins( playerid, params[ ] )
{
	if ( IsPlayerInMultiplayer( playerid ) )
	{
		if ( g_userData[ playerid ] [ E_RANK ] < 2 && !g_userData[ playerid ] [ E_PRESTIGE ] )
		    return SendError( playerid, "You need to be at least rank 2 to see the online admins." );
	}
	else
	{
		if ( g_userData[ playerid ] [ E_ZM_RANK ] < 5 && !g_userData[ playerid ] [ E_ZM_PRESTIGE ] )
		    return SendError( playerid, "You need to be at least rank 5 to see the online admins." );
	}
	new count = 0;
	szLargeString[ 0 ] = '\0';
	foreach(new i : Player)
	{
	    if ( g_userData[ i ] [ E_ADMIN ] ) {
	        count++;
	        format( szLargeString, sizeof( szLargeString ), "%s%sLevel %d - {FFFFFF}%s(%d)\n", szLargeString, IsPlayerAdminOnDuty( i ) ? ( COL_ADMIN ) : ( COL_GREY ), g_userData[ i ] [ E_ADMIN ], ReturnPlayerName( i ), i );
	    }
	}
    if ( count == 0 ) return SendServerMessage( playerid, "There are no administrators online." );
    ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Online Admins", szLargeString, "Okay", "" );
	return 1;
}

CMD:serveradmins( playerid, params[ ] )
{
	if ( IsPlayerInMultiplayer( playerid ) )
	{
		if ( g_userData[ playerid ] [ E_RANK ] < 2 && !g_userData[ playerid ] [ E_PRESTIGE ] )
		    return SendError( playerid, "You need to be at least rank 2 to see the online admins." );
	}
	else
	{
		if ( g_userData[ playerid ] [ E_ZM_RANK ] < 5 && !g_userData[ playerid ] [ E_ZM_PRESTIGE ] )
		    return SendError( playerid, "You need to be at least rank 5 to see the online admins." );
	}

	mysql_function_query( dbHandle, "SELECT `NAME`, `ADMIN` FROM `COD` WHERE `ADMIN` > 0 ORDER BY `ADMIN` DESC", true, "OnShowServerAdmins", "d", playerid );
	return 1;
}

thread OnShowServerAdmins( playerid )
{
	new
		rows, fields, i = -1,
		szName[ MAX_PLAYER_NAME ], iAdminLevel
	;

	cache_get_data( rows, fields );

	if ( rows )
	{
		szLargeString[ 0 ] = '\0';

		while( ++i < rows )
		{
			cache_get_field_content( i, "NAME", szName, dbHandle, sizeof( szName ) );
			iAdminLevel = cache_get_field_content_int( i, "ADMIN", dbHandle );
	        format( szLargeString, sizeof( szLargeString ), "%s"COL_GREY"Level %d - "COL_WHITE"%s\n", szLargeString, iAdminLevel, szName );
	    }

    	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Server Admins", szLargeString, "Okay", "" );
	}
	else SendError( playerid, "There are no administrators for this server." );
}

CMD:help( playerid, params[ ] )
{
	format( szLargeString, 550, "{FFFFFF}Welcome to Call of Duty for SA-MP. A game-based server typically of Call of Duty.\n"\
								"The gamemode consists of many objectives, most renowned by Team Deathmatch, Capture the Flag\n"\
                                "and Kill Confirmed\n\n" );
    format( szLargeString, 550,	"%sCurrently, we're on the public beta stage of the server. We accept any feedback that can\n"\
                                "improve gameplay. One of the sole purposes of the server is to feature sophisticated trigonometrical\n"\
                                "features, especially for killstreaks. We do hope you enjoy the server!\n\nTo view the commands list: /commands\nTo display the controls: /controls", szLargeString );

	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}"#SERVER_NAME" - Help", szLargeString, "Okay", "" );
	return 1;
}

CMD:commands( playerid, params[ ] ) return cmd_cmds( playerid, params );
CMD:cmds( playerid, params[ ] )
{
	szHugeString[ 0 ] = '\0';

	strcat( szHugeString, 	"{C0C0C0}/(obj)ective -{FFFFFF} Explains the objective of the current game\n"\
							"{C0C0C0}/statistics -{FFFFFF} Shows your statistics\n"\
							"{C0C0C0}/irc(pm) -{FFFFFF} Sends a message to the IRC\n"\
							"{C0C0C0}/updates -{FFFFFF} Binded to /twitter - Shows latest tweets\n"\
							"{C0C0C0}/savestats -{FFFFFF} Save statistics manually\n"\
							"{C0C0C0}/kill -{FFFFFF} Commit Suicide (works only if in water)\n"\
							"{C0C0C0}/controls -{FFFFFF} Displays Controls\n" );

	strcat( szHugeString, 	"{C0C0C0}/rules -{FFFFFF} Displays Rules\n"\
							"{C0C0C0}/help -{FFFFFF} Displays Brief Help\n"\
							"{C0C0C0}/fps -{FFFFFF} Displays FPS\n"\
							"{C0C0C0}/admins -{FFFFFF} Displays Online Admins\n"\
							"{C0C0C0}/serveradmins -{FFFFFF} Displays Server Admins\n"\
							"{C0C0C0}/server -{FFFFFF} Displays Server Data\n"\
							"{C0C0C0}/myaccid -{FFFFFF} Displays Account ID" );

	strcat( szHugeString, 	"{C0C0C0}/pm -{FFFFFF} Private Message Somebody\n"\
							"{C0C0C0}/dnd -{FFFFFF} (Un)Block a person from PMing you\n"\
							"{C0C0C0}/undndall -{FFFFFF} Unblock everyone from PMing you\n"\
							"{C0C0C0}/ask -{FFFFFF} Ask a question\n"\
							"{C0C0C0}/report -{FFFFFF} Report something/someone to online admins\n"\
							"{C0C0C0}/changeclass -{FFFFFF} Change your class on next spawn\n"\
							"{C0C0C0}/mainmenu -{FFFFFF} Go to the main menu" );

	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}"#SERVER_NAME" - Commands", szHugeString, "Okay", "" );
	return 1;
}

CMD:dndall( playerid, params[ ] )
{
	foreach(new i : Player)
	{
	    if ( i == playerid ) continue;
	    p_BlockedPM[ playerid ] [ i ] = true;
	}
	SendClientMessage( playerid, -1, ""COL_GOLD"[DO NOT DISTURB]"COL_WHITE" You have un-toggled everyone to send PMs to you." );
	return 1;
}

CMD:undndall( playerid, params[ ] )
{
	foreach(new i : Player)
	{
	    if ( i == playerid ) continue;
	    p_BlockedPM[ playerid ] [ i ] = false;
	}
	SendClientMessage( playerid, -1, ""COL_GOLD"[DO NOT DISTURB]"COL_WHITE" You have toggled everyone to send PMs to you." );
	return 1;
}

CMD:dnd( playerid, params[ ] )
{
	new
	    pID
	;
	if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/dnd [PLAYER_ID]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cannot block yourself." );
	else
	{
	    p_BlockedPM[ playerid ] [ pID ] = ( p_BlockedPM[ playerid ] [ pID ] == true ? ( false ) : ( true ) );
		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[DO NOT DISTURB]"COL_WHITE" You have %s %s to send pm's to you.", p_BlockedPM[ playerid ] [ pID ] == false ? ("toggled") : ("un-toggled"), ReturnPlayerName( pID ) );
	}
	return 1;
}

CMD:r( playerid, params[ ] )
{
	new msg[ 100 ];

	if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/r [MESSAGE]" );
	else if ( !IsPlayerConnected( p_PmResponder[ playerid ] ) ) return SendError( playerid, "This player is not connected." );
    else if ( p_BlockedPM[ p_PmResponder[ playerid ] ] [ playerid ] == true ) return SendError( playerid, "This person has blocked pm's coming from you." );
    else if ( textContainsIP( msg ) ) return SendError( playerid, "Advertising via PM is forbidden." );
	else if ( p_PlayerLogged{ p_PmResponder[ playerid ] } == false ) return SendError( playerid, "This player is not logged in." );
	else
	{
	    new pID = p_PmResponder[ playerid ];
		GameTextForPlayer( pID, "~n~~n~~n~~n~~n~~n~~n~~w~... ~y~New Message!~w~ ...", 4000, 3 );
		SendClientMessageFormatted( pID, -1, ""COL_YELLOW"[MESSAGE]{CCCCCC} From %s(%d): %s", ReturnPlayerName( playerid ), playerid, msg );
        SendClientMessageFormatted( playerid, -1, ""COL_YELLOW"[MESSAGE]{A3A3A3} To %s(%d): %s", ReturnPlayerName(pID), pID, msg );
		foreach(new i : Player)
		{
		    if ( g_userData[ i ] [ E_ADMIN ] == 5 && p_ToggledViewPM{ i } == true )
		    {
		        SendClientMessageFormatted( i, -1, ""COL_ADMIN"[PM VIEW]"COL_WHITE" (%s >> %s): %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), msg );
		    }
		}
		p_PmResponder[ playerid ] = pID;
        Beep( pID ), Beep( playerid );
	}
	return 1;
}

CMD:pm( playerid, params[ ] )
{
	new
		pID, msg[100]
	;

	if ( sscanf( params, ""#sscanf_u"s[100]", pID, msg ) ) return SendUsage( playerid, "/pm [PLAYER_ID] [MESSAGE]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cannot pm yourself." );
    else if ( p_BlockedPM[ pID ] [ playerid ] == true ) return SendError( playerid, "This person has blocked pm's coming from you." );
	else if ( textContainsIP( msg ) ) return SendError( playerid, "Advertising via PM is forbidden." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "This player is not logged in." );
	else
	{
		GameTextForPlayer( pID, "~n~~n~~n~~n~~n~~n~~n~~w~... ~y~New Message!~w~ ...", 4000, 3 );
		SendClientMessageFormatted( pID, -1, ""COL_YELLOW"[MESSAGE]{CCCCCC} From %s(%d): %s", ReturnPlayerName( playerid ), playerid, msg );
        SendClientMessageFormatted( playerid, -1, ""COL_YELLOW"[MESSAGE]{A3A3A3} To %s(%d): %s", ReturnPlayerName(pID), pID, msg );
		foreach(new i : Player)
		{
		    if ( g_userData[ i ] [ E_ADMIN ] == 5 && p_ToggledViewPM{ i } == true )
		    {
		        SendClientMessageFormatted( i, -1, ""COL_ADMIN"[PM VIEW]"COL_WHITE" (%s >> %s): %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), msg );
		    }
		}
		p_PmResponder[ playerid ] = pID;
        Beep( pID ), Beep( playerid );
	}
	return 1;
}

CMD:ask( playerid, params[ ] )
{
    new msg[ 100 ];
    if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/ask [QUESTION]" );
    else if ( p_CantUseAsk{ playerid } == true ) return SendError( playerid, "You have been blocked to use this command by a admin." );
    else
	{
		Beep( playerid );
        SendClientMessageToAdmins( -1, "{FE5700}[QUESTION] %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, msg );
		SendClientMessage( playerid, -1, "{FE5700}[QUESTION]"COL_WHITE" You have successfully sent a question to the online administrators." );
	}
	return 1;
}

CMD:report( playerid, params[ ] )
{
    new msg[ 64 ];
    if ( sscanf( params, "s[64]", msg ) ) return SendUsage( playerid, "/report [msg]" );
    else if ( p_CantUseReport{ playerid } == true ) return SendError( playerid, "You have been blocked to use this command by a admin." );
    else
	{
		Beep( playerid );
        SendClientMessageToAdmins( -1, ""COL_RED"[REPORT] %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, msg );
		SendClientMessage( playerid, -1, ""COL_GOLD"[REPORT]"COL_WHITE" You have successfully sent a report to the online administrators." );
	}
	return 1;
}

CMD:changeclass( playerid, params[ ] )
{
	p_SelectedGameClass[ playerid ] = 0;
	SendServerMessage( playerid, "Your class selection will be displayed the next time you spawn." );
	return 1;
}

CMD:mainmenu( playerid, params[ ] )
{
	if ( p_goingtoMenu[ playerid ] == true )
	    return SendError( playerid, "Please wait... You are still being redirected to the main menu." );

	if ( p_Team[ playerid ] == NO_TEAM )
		return SendError( playerid, "This command requires you to be in a team." );

	if ( p_AntiSpawnKillEnabled{ playerid } )
		return SendError( playerid, "This command requires you to not be in spawn-kill protection." );

	if ( p_SpectateMode{ playerid } )
		TogglePlayerSpectating( playerid, 0 );

	switch( p_Team[ playerid ] ) {
	    case TEAM_TROPAS: 	g_TropasMembers --;
	    case TEAM_OP40: 	g_OP40Members --;
	}
	p_Team[ playerid ] = NO_TEAM;
	ForcePlayerKill( playerid, INVALID_PLAYER_ID, 54 );
	//SetPlayerTeam( playerid, NO_TEAM );
	SetPlayerColor( playerid, ReturnPlayerTeamColor( playerid ) );
	ForceClassSelection( playerid );
	p_goingtoMenu[ playerid ] = true;
	p_SpectateMode{ playerid } = false;
	p_SpectatingPlayer[ playerid ] = INVALID_PLAYER_ID;
	g_userData[ playerid ] [ E_LAST_LOGGED ] = gettime( );
	if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://www.irresistiblegaming.com/game_sounds/mainmenu.mp3" );
	return 1;
}


/*                                 ________    ___      ___   ________      ___________
	/--------------\             /         \  |   \    /   | |   ___  \    /           |
	|    ______    |             |   ______/  |    \  /    | |  |   |  \   |    _______|
	|   |      |   |             |   |        |     \/     | |  |   |  |   |    \_______
	|   |______|   |   ________  |   |        |            | |  |   |  |   \_______     |
	|    ______    |  |________| |   |        |   |\__/|   | |  |   |  |           /    |
	|   |      |   |             |   |______  |   |    |   | |  |   |  |   _______/    /
	|   |      |   |             |          \     |    |   | |  |___|  /  |           /
	\___/      \___/             \__________/ |___|    |___| |________/   |__________/
*/

/* Level 1 */
CMD:acommands( playerid, params[ ] ) return cmd_acmds( playerid, params );
CMD:acmds( playerid, params[ ] )
{
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    SendClientMessage( playerid, COLOR_GREY, "|______________________________________| Admin Commands |_____________________________________|" );
    SendClientMessage( playerid, COLOR_WHITE, " " );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 1: /goto, /spec(off), /asay, /slap, /a, /getstats, /stpfr, /frules, /warn, /spawn" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 1: /ans, /stpfa, /slay, /alog, /(un)freeze, /awep, /aod" );

    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 2: /kick, /(un)mute, /explode, /suspend, /balance, /pinfo" );

    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 3: /ban, /bring, /clearchat, /(ann)ounce, /giveweapon, /healall, /getip, /setworld" );

    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 4: /giveweaponall, /resetwep, /motd" );

    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 5: /changename, /toggleviewpm, /unban(ip), /doublexp, /rangeban, /giveks, /ping" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 5: /endround, /gotopos" );
    SendClientMessage( playerid, COLOR_GREY, "|_____________________________________________________________________________________________|" );
	return 1;
}

CMD:aod( playerid, params[ ] )
{
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
 	if ( !p_AdminOnDuty{ playerid } )
	{
		if ( !p_inMovieMode{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminOnDutyTD );
	    Delete3DTextLabel( p_AdminLabel[ playerid ] );
	    p_AdminLabel[ playerid ] = Create3DTextLabel( "Admin on Duty!", COLOR_ADMIN, 0.0, 0.0, 0.0, 15.0, 0 );
	    Attach3DTextLabelToPlayer( p_AdminLabel[ playerid ], playerid, 0.0, 0.0, 0.5 );
	    SetPlayerHealth( playerid, INVALID_PLAYER_ID );
	    SetPlayerColor( playerid, COLOR_ADMIN );
	    p_AdminOnDuty{ playerid } = true;
	    SendClientMessage( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have enabled administration mode." );
	}
	else
	{
		TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	    Delete3DTextLabel( p_AdminLabel[ playerid ] );
	    p_AdminLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	    p_AdminOnDuty{ playerid } = false;
	    SetPlayerColor( playerid, ReturnPlayerTeamColor( playerid ) );
	    SetPlayerHealth( playerid, 100 );
	    SendClientMessage( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have disabled administration mode." );
	}
	return 1;
}


CMD:spec( playerid, params[ ] )
{
	new
		pID
	;

	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, ""#sscanf_u"", pID ) ) SendUsage( playerid, "/spec [PLAYER_ID]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cannot spectate yourself." );
   	else if ( IsPlayerNPC( pID ) ) return SendError( playerid, "You cannot spectate NPCs." );
    else
    {
        if ( p_Spectating{ playerid } == true )
        {
			if ( IsPlayerConnected( p_beingSpectated[ p_whomSpectating[ playerid ] ] ) ) {
            	p_beingSpectated[ p_whomSpectating[ playerid ] ] = false;
            	p_whomSpectating[ playerid ] = INVALID_PLAYER_ID;
			}
        }

        // So it works zombie spec
    	TextDrawHideForPlayer( playerid, g_SpectateBoxTD );
		TextDrawHideForPlayer( playerid, g_SpectateTD[ playerid ] );

        SetPlayerInterior( playerid, GetPlayerInterior( pID ) );
        SetPlayerVirtualWorld( playerid, GetPlayerVirtualWorld( pID ) );
		AddAdminLogLineFormatted( "%s(%d) is spectating %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        p_Spectating{ playerid } = true;
        p_whomSpectating[ playerid ] = pID;
        p_beingSpectated[ pID ] = true;
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You are now spectating %s(%d).", ReturnPlayerName( pID ), pID );
		if ( IsPlayerInAnyVehicle( pID ) )
		{
			TogglePlayerSpectating(playerid, 1),
			PlayerSpectateVehicle(playerid, GetPlayerVehicleID( pID ) );
		}
		else
		{
			TogglePlayerSpectating( playerid, 1 ),
			PlayerSpectatePlayer( playerid, pID );
		}
    }
    return 1;
}

CMD:specoff( playerid, params[ ] )
{
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    if ( p_Spectating{ playerid } == true )
	{
		TogglePlayerSpectating( playerid, 0 );
		if ( IsPlayerConnected( p_beingSpectated[ p_whomSpectating[ playerid ] ] ) ) {
       		p_beingSpectated[ p_whomSpectating[ playerid ] ] = false;
           	p_whomSpectating[ playerid ] = INVALID_PLAYER_ID;
		}
		p_Spectating{ playerid } = false;
		SendServerMessage( playerid, "Spectation has been closed." );
	}
	else SendError(playerid, "You're not spectating!");
	return 1;
}


CMD:goto( playerid, params[ ] )
{
    new
		pID,
		Float: X,
		Float: Y,
		Float: Z
	;

	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/goto [playerid]" );
    else if ( !IsPlayerConnected(pID) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError(playerid, "You cannot go to yourself.");
    else {
        GetPlayerPos( pID, X, Y, Z );
        SetPlayerPos( playerid, X, Y + 2, Z );
        SetPlayerInterior( playerid, GetPlayerInterior( pID ) );
        SetPlayerVirtualWorld( playerid, GetPlayerVirtualWorld( pID ) );
        AddAdminLogLineFormatted( "%s(%d) has teleported to %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
    }
    return 1;
}


CMD:slap( playerid, params[ ] )
{
    new
		pID,
		Float: offset,
		Float: X,
		Float: Y,
		Float: Z
	;

	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, ""#sscanf_u"F(10.0)", pID, offset ) ) return SendUsage(playerid, "/slap [PLAYER_ID] [OFFSET (= 10.0)]");
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError(playerid, "Invalid Player ID.");
    else if ( g_userData[ pID ] [ E_ADMIN ] > g_userData[ playerid ] [ E_ADMIN ] ) return SendError(playerid, "You cannot use this command on admins higher than your level.");
    else
	{
        AddAdminLogLineFormatted( "%s(%d) has slapped %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have slapped %s(%d)", ReturnPlayerName( pID ), pID );
        GetPlayerPos( pID, X, Y, Z );
        SetPlayerPos( pID, X, Y, Z + offset );
    }
    return 1;
}

CMD:getstats( playerid, params[ ] )
{
    new
		pID
	;

	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if ( sscanf( params, ""#sscanf_u"", pID ) ) SendUsage(playerid, "/getstats [PLAYER_ID]");
    else if ( !IsPlayerConnected(pID) ) return SendError(playerid, "Invalid Player ID.");
	else if ( !p_PlayerLogged{ pID } ) return SendError( playerid, "This player is not logged in." );
	else
	{
	    p_ViewingStats[ playerid ] = pID;
		ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Statistics", "General Statistics\nMultiplayer Statistics\nZombie Statistics", "Select", "Cancel" );
	}
   	return 1;
}

CMD:a( playerid, params[ ] )
{
	new
	    msg[ 90 ]
	;

    if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return 0;
    else if ( sscanf( params, "s[90]", msg ) ) return SendUsage( playerid, "/a [MESSAGE]" );
    else
	{
		SendClientMessageToAdmins( -1, ""COL_ADMIN"<Admin Chat> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, msg );
	}
	return 1;
}

CMD:stpfr( playerid, params[ ] )
{
    new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if ( sscanf( params, ""#sscanf_u"", pID ) ) SendUsage(playerid, "/stpfr [PLAYER_ID]");
    else if ( !IsPlayerConnected(pID) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError( playerid, "You cannot apply this to yourself." );
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
    else
    {
		p_CantUseReport{ pID } = ( p_CantUseReport{ pID } == true ? false : true );
        AddAdminLogLineFormatted( "%s(%d) has been %s from using /report by %s(%d)", ReturnPlayerName( pID ), pID, p_CantUseReport{ pID } == true ? ( "blocked" ) : ( "unblocked" ), ReturnPlayerName( playerid ), playerid );
        SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have %s %s(%d) from using the report command.", p_CantUseReport{ pID } == true ? ( "blocked" ) : ( "unblocked" ), ReturnPlayerName( pID ), pID );
	}
    return 1;
}

CMD:warn( playerid, params[ ] )
{
	new
	    pID,
	    reason[ 32 ]
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"S(No Reason)[32]", pID, reason ) ) return SendUsage( playerid, "/warn [PLAYER_ID] [REASON]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You can't warn your self." );
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
	else
	{
	    p_Warns[ pID ] ++;
	    AddAdminLogLineFormatted( "%s(%d) has warned %s(%d) [%d/3]", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, p_Warns[ pID ] );
        SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d) has been warned by %s(%d) "COL_GREEN"[REASON: %s]", ReturnPlayerName( pID ), pID, ReturnPlayerName( playerid ), playerid, reason );
		if ( p_Warns[ pID ] >= 3 )
	    {
	        p_Warns[ pID ] = 0;
	        SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d) has been kicked from the server. "COL_GREEN"[REASON: Excessive Warns]", ReturnPlayerName( pID ), pID );
	        KickPlayerTimed( pID );
	        return 1;
	    }
 	}
	return 1;
}

CMD:spawn( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/spawn [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		SpawnPlayer( pID );
		AddAdminLogLineFormatted( "%s(%d) has spawned %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have spawned %s(%d)!", ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have been spawned by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

CMD:ans( playerid, params[ ] )
{
	new
		pID, msg[90]
	;

	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if ( sscanf( params, ""#sscanf_u"s[90]", pID, msg ) ) return SendUsage( playerid, "/ans [PLAYER_ID] [ANSWER]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cannot answer yourself." );
	else
	{
		SendClientMessageToAdmins( -1, ""COL_ADMIN"[ANSWER]"COL_GREY" (%s >> %s):"COL_WHITE" %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), msg );
		AddAdminLogLineFormatted( "%s(%d) has answered %s(%d)'s question", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendClientMessageFormatted( pID, -1, "{FE5700}[ANSWER] From %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, msg );
        Beep( pID ), Beep( playerid );
	}
	return 1;
}

CMD:stpfa( playerid, params[ ] )
{
    new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if ( sscanf( params, ""#sscanf_u"", pID ) ) SendUsage(playerid, "/stpfa [PLAYER_ID]");
    else if ( !IsPlayerConnected(pID) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError( playerid, "You cannot apply this to yourself." );
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
    else
    {
        p_CantUseAsk{ pID } = ( p_CantUseAsk{ pID } == true ? false : true );
		AddAdminLogLineFormatted( "%s(%d) has been %s from using /ask by %s(%d)", ReturnPlayerName( pID ), pID, p_CantUseAsk{ pID } == true ? ( "blocked" ) : ( "unblocked" ), ReturnPlayerName( playerid ), playerid );
        SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have %s %s(%d) from using the ask command.", p_CantUseAsk{ pID } == true ? ( "blocked" ) : ( "unblocked" ), ReturnPlayerName( pID ), pID );
    }
    return 1;
}

CMD:slay( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/slay [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		ForcePlayerKill( pID, INVALID_PLAYER_ID, 47 );
		AddAdminLogLineFormatted( "%s(%d) has slayed %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have slayed %s(%d)!", ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have been slayed by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

CMD:asay( playerid, params[ ] )
{
	new
	    string[ 100 ]
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "s[100]", string ) ) return SendUsage( playerid, "/asay [MESSAGE]" );
	else
	{
		AddAdminLogLineFormatted( "%s(%d) has used /asay", ReturnPlayerName( playerid ), playerid );
        SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s", string );
	}
	return 1;
}

CMD:frules( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/frules [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( !IsPlayerSpawned( pID ) ) return SendError( playerid, "This player isn't spawned." );
	else
	{
		cmd_rules( pID, "" );
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have showed %s(%d) the /rules", ReturnPlayerName( pID ), pID );
		AddAdminLogLineFormatted( "%s(%d) has shown the rules to %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	}
	return 1;
}

CMD:freeze( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/freeze [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( !IsPlayerSpawned( pID ) ) return SendError( playerid, "This player isn't spawned." );
	else
	{
	    AddAdminLogLineFormatted( "%s(%d) has frozen %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have been frozen by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	   	SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have frozen %s(%d)!", ReturnPlayerName( pID ), pID );
	   	TogglePlayerControllable( pID, 0 );
	}
	return 1;
}

CMD:unfreeze( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/unfreeze [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( !IsPlayerSpawned( pID ) ) return SendError( playerid, "This player isn't spawned." );
	else
	{
	    AddAdminLogLineFormatted( "%s(%d) has unfrozen %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have been unfrozen by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	   	SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have unfrozen %s(%d)!", ReturnPlayerName( pID ), pID );
	   	TogglePlayerControllable( pID, 1 );
	}
	return 1;
}

CMD:awep( playerid, params[ ] )
{
	static
		wname[24],
		iAmmo,
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/awep [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( !IsPlayerSpawned( pID ) ) return SendError( playerid, "This player isn't spawned." );
	else
	{
        szLargeString[ 0 ] = '\0';
        SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You are now viewing "COL_GREY"%s(%d){FFFFFF}'s weapons.", ReturnPlayerName( pID ), pID );
		for(new i; i < MAX_WEAPONS; i++)
		{
		    if ( IsWeaponInAnySlot( pID, i ) )
		    {
				GetPlayerWeaponData( pID, GetWeaponSlot( i ), iAmmo, iAmmo );
				if ( iAmmo > 0xFFFF || iAmmo < -100 ) iAmmo = 0xFFFF;
				if ( iAmmo == 0 || i == 0 ) continue;
		        switch( i )
		        {
				    case 0:  wname = "Fist";
					case 18: wname = "Molotovs";
					case 40: wname = "Detonator";
					case 44: wname = "Nightvision Goggles";
					case 45: wname = "Thermal Goggles";
					default: GetWeaponName( i, wname, sizeof( wname ) );
		        }
		        format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\n", szLargeString, wname, iAmmo );
		        ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}Weapon Data", szLargeString, "Okay", "" );
		    }
		}
	}
	return 1;
}

CMD:alog( playerid, params[ ] )
{
	if ( g_userData[ playerid ] [ E_ADMIN ] < 1 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else
	{
        if ( p_AdminLog{ playerid } )
        {
            p_AdminLog{ playerid } = false;
	    	TextDrawHideForPlayer( playerid, g_AdminLogTD );
	    	SendServerMessage( playerid, "You have un-toggled the administration log." );
		}
		else
		{
            p_AdminLog{ playerid } = true;
	    	TextDrawShowForPlayer( playerid, g_AdminLogTD );
	    	SendServerMessage( playerid, "You have toggled the administration log." );
		}
	}
	return 1;
}

/* Level 2 */
CMD:pinfo( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ][ E_ADMIN ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/pinfo [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d): "COL_GREY"%0.2f packetloss, %d FPS, %d ping", ReturnPlayerName( pID ), pID, NetStats_PacketLossPercent( pID ), GetPlayerFPS( pID ), GetPlayerPing( pID ) );
	}
	return 1;
}

CMD:balance( playerid, params[ ] )
{
	if ( g_userData[ playerid ][ E_ADMIN ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( g_mp_gameData[ E_STARTED ] == false ) return SendError( playerid, "The round hasn't started." );
	else
	{
	   	if ( !BalanceTeams( ) ) return SendError( playerid, "Not enough people for balancing." );
		SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d) has balanced the teams.", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

stock BalanceTeams( )
{
	new totalGamers = 0;

	foreach(new i : mp_players)
	{
		if ( IsPlayerSpawned( i ) && GetPlayerTeam( i ) != NO_TEAM && p_Team[ i ] != NO_TEAM )
		    totalGamers ++;
	}

	if ( totalGamers < 2 )
	    return -1;

	new Divisor = floatround( totalGamers / 2 ), divisorCount = 0;
	new bool: teamBalanced = false;

	foreach(new i : mp_players)
	{
		if ( IsPlayerSpawned( i ) && GetPlayerTeam( i ) != NO_TEAM && p_Team[ i ] != NO_TEAM )
		{
			StripPlayerFlag( i );

		    if ( !teamBalanced )
		    {
		        SetPlayerTeamEx( i, TEAM_TROPAS );

		        divisorCount ++;
		        if ( divisorCount >= Divisor ) teamBalanced = true;
		    }
		 	else SetPlayerTeamEx( i, TEAM_OP40 );
		}
	}
	return 1;
}

stock SetPlayerTeamEx( playerid, teamid )
{
	if ( p_Team[ playerid ] != teamid )
	{
		switch( p_Team[ playerid ] ) {
		    case TEAM_TROPAS: 	g_TropasMembers --;
		    case TEAM_OP40: 	g_OP40Members --;
		}

		p_Team[ playerid ] = teamid;

		switch( p_Team[ playerid ] )
		{
		    case TEAM_TROPAS:
		    {
	        	TextDrawSetString( p_RoundPlayerTeam[ playerid ], "ld_otb2:ric1" );
				g_usermatchDataT1[ playerid ] [ M_ID ] = playerid;
				g_usermatchDataT2[ playerid ] [ M_ID ] = INVALID_PLAYER_ID;
				g_usermatchDataT1[ playerid ] [ M_SCORE ] 	= g_usermatchDataT2[ playerid ] [ M_SCORE ];
				g_usermatchDataT2[ playerid ] [ M_SCORE ] 	= 0;
				GameTextForPlayer( playerid, "~w~Your team has been set to ~b~~h~tropas~w~!", 3000, 4 );
		    	g_TropasMembers ++;
		    }
		    case TEAM_OP40:
		    {
	        	TextDrawSetString( p_RoundPlayerTeam[ playerid ], "ld_otb2:ric2" );
				g_usermatchDataT1[ playerid ] [ M_ID ] = INVALID_PLAYER_ID;
				g_usermatchDataT2[ playerid ] [ M_ID ] = playerid;
				g_usermatchDataT2[ playerid ] [ M_SCORE ] 	= g_usermatchDataT1[ playerid ] [ M_SCORE ];
				g_usermatchDataT1[ playerid ] [ M_SCORE ] 	= 0;
				GameTextForPlayer( playerid, "~w~Your team has been set to ~r~~h~op40~w~!", 3000, 4 );
		    	g_OP40Members ++;
		    }
		}

		//SetPlayerTeam( playerid, p_Team[ playerid ] );
		SetPlayerColor( playerid, ReturnPlayerTeamColor( playerid ) );

		if ( !p_CustomSkin{ playerid } ) SetPlayerSkin( playerid, p_Team[ playerid ] == TEAM_TROPAS ? g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_SKIN_1 ] : g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_SKIN_2 ] );
		else SetPlayerSkin( playerid, g_userData[ playerid ] [ E_SKIN ] );

		TogglePlayerControllable( playerid, true );
	}
	return 1;
}

CMD:mute( playerid, params[ ] )
{
    new pID, seconds, reason[ 32 ];

	if ( g_userData[ playerid ][ E_ADMIN ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, ""#sscanf_u"dS(No Reason)[32]", pID, seconds, reason ) ) return SendUsage(playerid, "/mute [PLAYER_ID] [SECONDS] [REASON]");
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError(playerid, "You cannot mute yourself.");
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
    else if ( seconds < 0 || seconds > 10000000 ) return SendError( playerid, "Specify the amount of seconds from 1 - 10000000." );
    else
	{
		AddAdminLogLineFormatted( "%s(%d) has muted %s(%d) for %d seconds", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, seconds );
        SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s has been muted by %s for %d seconds "COL_GREEN"[REASON: %s]", ReturnPlayerName( pID ), ReturnPlayerName( playerid ), seconds, reason );
		GameTextForPlayer( pID, "~r~Muted!", 4000, 4 );
        p_Muted{ pID } = true;
        g_userData[ pID ] [ E_MUTE_TIME ] = gettime( ) + seconds;
    }
    return 1;
}

CMD:unmute( playerid, params[ ] )
{
    new pID;

	if ( g_userData[ playerid ][ E_ADMIN ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, ""#sscanf_u"", pID )) SendUsage(playerid, "/mute [PLAYER_ID]");
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError( playerid, "You cannot un-mute yourself." );
    else if ( !p_Muted{ pID } ) return SendError( playerid, "This player isn't muted" );
    else
	{
		AddAdminLogLineFormatted( "%s(%d) has un-muted %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s has been un-muted by %s.", ReturnPlayerName(pID), ReturnPlayerName( playerid ));
		GameTextForPlayer( pID, "~g~Un-Muted!", 4000, 4 );
        p_Muted{ pID } = false;
        g_userData[ pID ] [ E_MUTE_TIME ] = 0;
    }
    return 1;
}

CMD:kick( playerid, params[ ] )
{
    new
        pID,
        reason[ 70 ]
	;

	if ( g_userData[ playerid ][ E_ADMIN ] < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, ""#sscanf_u"S(No reason)[70]", pID, reason ) ) SendUsage( playerid, "/kick [PLAYER_ID] [REASON]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cant kick yourself." );
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
    else
	{
		adhereBanCodes( reason );
		AddAdminLogLineFormatted( "%s(%d) has kicked %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s has been kicked by %s. "COL_GREEN"[REASON: %s]", ReturnPlayerName(pID), ReturnPlayerName( playerid ), reason);
        KickPlayerTimed( pID );
    }
    return 1;
}

CMD:explode( playerid, params[ ] )
{
    new pID;
	if ( g_userData[ playerid ][ E_ADMIN ] < 2 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if (sscanf( params, ""#sscanf_u"", pID)) SendUsage(playerid, "/explode [PLAYER_ID]");
    else if ( !IsPlayerConnected(pID) ) return SendError(playerid, "Invalid Player ID.");
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
    else {
        new Float: X, Float: Y, Float: Z;
        GetPlayerPos( pID, X, Y, Z );
		AddAdminLogLineFormatted( "%s(%d) has exploded %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
        SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have exploded %s(%d)", ReturnPlayerName( pID ), pID );
        CreateExplosion( X, Y, Z, 12, 10.0 );
    }
    return 1;
}

CMD:suspend( playerid, params [ ] )
{
    new
	    pID,
		ip[ 16 ],
		reason[ 50 ],
		hours, days
	;
	if ( g_userData[ playerid ][ E_ADMIN ]  < 2 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"ddS(No Reason)[50]", pID, hours, days, reason ) ) SendUsage( playerid, "/suspend [PLAYER_ID] [HOURS] [DAYS] [REASON]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid playerid." );
	else if ( hours < 0 || hours > 24 ) return SendError( playerid, "Please specify an hour between 0 and 24." );
	else if ( days < 0 || days > 60 ) return SendError( playerid, "Please specifiy the amount of days between 0 and 60." );
	else if ( days == 0 && hours == 0 ) return SendError( playerid, "Invalid time specified." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot suspend yourself." );
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
	else
	{
		adhereBanCodes( reason );
        AddAdminLogLineFormatted( "%s(%d) has suspended %s(%d) for %d h %d d", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, hours, days );
	    SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s has suspended %s(%d) for %d hour(s) and %d day(s) "COL_GREEN"[REASON: %s]", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), pID, hours, days, reason );
		GetPlayerIp( pID, ip, sizeof( ip ) );
		new time = gettime( ) + ( hours * 3600 ) + ( days * 86400 );
		AdvancedBan( pID, ReturnPlayerName( playerid ), reason, ip, time );
	}
	return 1;
}

/* Level 3 */
CMD:getip( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 3 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/getip [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( g_userData[ pID ] [ E_ADMIN ] >= 5 || strmatch( ReturnPlayerName( pID ), "Lorenc" ) ) return SendError( playerid, "I love this person so much that I wont give you his IP :)");
	else
	{
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d): "COL_GREY"%s", ReturnPlayerName( pID ), pID, ReturnPlayerIP( pID ) );
	}
	return 1;
}

CMD:giveweapon( playerid, params[ ] )
{
    new
		pID,
		wep,
		ammo,
		gunname[ 32 ]
	;

	if ( g_userData[ playerid ][ E_ADMIN ] < 3 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if ( sscanf( params, ""#sscanf_u"dd", pID, wep, ammo ) ) return SendUsage(playerid, "/giveweapon [PLAYER_ID] [WEAPON_ID] [AMMO]");
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( wep > MAX_WEAPONS || wep <= 0 || wep == 47 ) return SendError(playerid, "Invalid weapon id");
    else if ( g_BannedWeapons{ wep } == true && g_userData[ pID ][ E_ADMIN ] < 5 ) return SendError( playerid, "This weapon is a banned weapon, you cannot spawn this." );
    else
	{
        GetWeaponName( wep, gunname, sizeof( gunname ) );
        AddAdminLogLineFormatted( "%s(%d) has given %s(%d) a %s", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, gunname );
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have given %s(%d) a %s(%d)", ReturnPlayerName( pID ), pID, gunname, wep );
        SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have been given a %s from %s(%d)", gunname, ReturnPlayerName( playerid ), playerid );
        GivePlayerWeapon( pID, wep, ammo );
    }
    return 1;
}

CMD:healall( playerid, params[ ] )
{
	if ( g_userData[ playerid ][ E_ADMIN ] < 3 )
		return SendError( playerid, ADMIN_COMMAND_REJECT );

	AddAdminLogLineFormatted( "%s(%d) has healed everybody", ReturnPlayerName( playerid ), playerid );
	foreach(new i : Player) {
	  	SetPlayerHealth( i, 100.0 );
	}
	SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" Everyone has been healed by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	return 1;
}

CMD:ann( playerid, params[ ] ) return cmd_announce( playerid, params );
CMD:announce( playerid, params[ ] )
{
    new Message[70];
	if ( g_userData[ playerid ][ E_ADMIN ] < 3 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if ( sscanf( params, "s[60]", Message ) ) SendUsage(playerid, "/announce [MESSAGE]");
    else
	{
		strreplacechar	( Message, '~', ']' );
        AddAdminLogLineFormatted( "%s(%d) has announced \"%s\"", ReturnPlayerName( playerid ), playerid, Message );
        format( Message, sizeof( Message ), "~w~%s", Message );
        GameTextForAll( Message, 6000, 3 );
    }
    return 1;
}

CMD:cc( playerid, params[ ] ) return cmd_clearchat( playerid, params );
CMD:clearchat( playerid, params[ ] )
{
	if ( g_userData[ playerid ][ E_ADMIN ] < 3 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	for( new i; i < 50; i++ )
	{
	    SendClientMessageToAll( -1, " " );
	}
    SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s cleared the chat.", ReturnPlayerName( playerid ) );
	AddAdminLogLineFormatted( "%s(%d) has cleared the chat", ReturnPlayerName( playerid ), playerid );
	return 1;
}

CMD:bring( playerid, params[ ] )
{
    new
		pID,
		Float: X,
		Float: Y,
		Float: Z
	;

	if ( g_userData[ playerid ][ E_ADMIN ] < 3 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/bring [PLAYER_ID]" );
    else if ( !IsPlayerConnected(pID) ) return SendError(playerid, "Invalid Player ID.");
    else if ( pID == playerid ) return SendError(playerid, "You cannot bring your self.");
    else
	{
        GetPlayerPos( playerid, X, Y, Z );
        SetPlayerPos( pID, X, Y + 2, Z );
        SetPlayerInterior( pID, GetPlayerInterior( playerid ) );
        SetPlayerVirtualWorld( pID, GetPlayerVirtualWorld( playerid ) );
        AddAdminLogLineFormatted( "%s(%d) has brang %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
    }
    return 1;
}

CMD:ban( playerid, params [ ] )
{
    new
	    pID,
		ip[ 16 ],
		reason[ 50 ]
	;
	if ( g_userData[ playerid ][ E_ADMIN ] < 3 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"S(No Reason)[50]", pID, reason ) ) SendUsage( playerid, "/ban [PLAYER_ID] [REASON]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid playerid." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot ban yourself." );
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
	else
	{
		adhereBanCodes( reason );
        AddAdminLogLineFormatted( "%s(%d) has banned %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	    SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s has banned %s(%d) "COL_GREEN"[REASON: %s]", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), pID, reason );
		GetPlayerIp( pID, ip, sizeof( ip ) );
		AdvancedBan( pID, ReturnPlayerName( playerid ), reason, ip );
	}
	return 1;
}

CMD:setworld( playerid, params[ ] )
{
	new pID, worldid;
 	if ( g_userData[ playerid ][ E_ADMIN ] < 3 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
 	else if ( sscanf( params, ""#sscanf_u"d", pID, worldid ) ) return SendUsage( playerid, "/setworld [PLAYER_ID] [WORLD_ID]" );
 	else
 	{
 	    SetPlayerVirtualWorld( pID, worldid );

 	    if ( pID != playerid )
		{
	 	    SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" Your world has been set to %d by %s(%d)!", worldid, ReturnPlayerName( playerid ), playerid );
	 		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have changed %s(%d)'s world to %d!", ReturnPlayerName( pID ), pID, worldid );
	 		AddAdminLogLineFormatted( "%s(%d) has changed %s(%d)'s world to %d", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, worldid );
		}
		else
		{
			SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have your world to %d.", worldid );
	 		AddAdminLogLineFormatted( "%s(%d) has changed his world to %d", ReturnPlayerName( pID ), pID, worldid );
		}
	}
	return 1;
}

/* Level 4 */
CMD:setnextmap( playerid, params[ ] )
{
	new
		szMaps[ 32 * MAX_MP_MAPS ];

 	if ( g_userData[ playerid ][ E_ADMIN ] < 4 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
 	if ( strmatch( params, "mp" ) )
 	{
		foreach(new i : maps)
			format( szMaps, sizeof( szMaps ), "%s%s\n", szMaps, g_mp_mapData[ i ] [ E_NAME ] );

 		ShowPlayerDialog( playerid, DIALOG_MP_NEXTMAP, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Select Map", szMaps, "Select", "Cancel" );
 	}
 	else if ( strmatch( params, "zm" ) )
 	{
		foreach(new i : zm_maps)
			format( szMaps, 32 * MAX_ZM_MAPS, "%s%s\n", szMaps, g_zm_mapData[ i ] [ E_NAME ] );

 		ShowPlayerDialog( playerid, DIALOG_ZM_NEXTMAP, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Select Map", szMaps, "Select", "Cancel" );
 	}
 	else SendUsage( playerid, "/setnextmap [MP/ZM]" );
	return 1;
}

CMD:motd( playerid, params[ ] )
{
	new
	    string[ 90 ]
	;
 	if ( g_userData[ playerid ][ E_ADMIN ] < 4 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
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

CMD:resetwep( playerid, params[ ] )
{
	new
		pID
	;
	if ( g_userData[ playerid ][ E_ADMIN ] < 4 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"", pID ) ) return SendUsage( playerid, "/resetwep [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		ResetPlayerWeapons( pID );
        AddAdminLogLineFormatted( "%s(%d) has reset %s(%d)'s weapons", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have reset %s(%d)'s weapons.", ReturnPlayerName( pID ), pID );
		SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" Your weapons have been reset by %s(%d).", ReturnPlayerName( playerid ), playerid );
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

	if ( g_userData[ playerid ][ E_ADMIN ] < 4 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    else if ( sscanf( params, "dd", wep, ammo ) ) return SendUsage(playerid, "/giveweaponall [WEAPON_ID] [AMMO]");
    else if ( wep > MAX_WEAPONS || wep <= 0 || wep == 47 ) return SendError(playerid, "Invalid weapon id");
    else if ( g_BannedWeapons{ wep } == true ) return SendError( playerid, "This weapon is a banned weapon, you cannot spawn this." );
    else
	{
	    foreach(new pID : Player)
	    {
	        if ( IsPlayerSpawned( pID ) )
	        {
				GivePlayerWeapon( pID, wep, ammo );
			}
		}
		GetWeaponName( wep, gunname, sizeof( gunname ) );
        AddAdminLogLineFormatted( "%s(%d) has given everyone a %s", ReturnPlayerName( playerid ), playerid, gunname );
		SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" Everyone has been given a %s from %s(%d).", gunname, ReturnPlayerName( playerid ), playerid );
    }
    return 1;
}

/* Level 5 */
CMD:gotopos( playerid, params[ ] )
{
	new
		Float: X, Float: Y, Float: Z, interior;

 	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
 	else if ( sscanf( params, "fffD(0)", X, Y, Z, interior ) ) return SendUsage( playerid, "/gotopos [POS_X] [POS_Y] [POS_Z] [INTERIOR (= 0)]" );
 	else
 	{
 		SetPlayerPos( playerid, X, Y, Z );
 		SetPlayerInterior( playerid, interior );
 		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have teleported to "COL_GREY"%f, %f, %f"COL_WHITE" Interior: "COL_GREY"%d", X, Y, Z, interior );
 	}
	return 1;
}

CMD:ping( playerid, params[ ] )
{
	new ping;

 	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, "d", ping ) ) return SendUsage( playerid, "/ping [PING]" );
	else if ( ping < 250 ) return SendError( playerid, "The ping cannot be under 250." );
	else
	{
	    g_PingLimit = ping;
		AddAdminLogLineFormatted( "%s(%d) set the ping limit to %d", ReturnPlayerName( playerid ), playerid, ping );
		SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d) set the ping limit to %d", ReturnPlayerName( playerid ), playerid, ping );
	}
	return 1;
}

CMD:endround( playerid, params[ ] )
{
 	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
 	if ( strmatch( params, "mp" ) )
 	{
		if ( g_mp_gameData[ E_STARTED ] == false ) return SendError( playerid, "The round hasn't started!" );
		g_mp_gameData[ E_TIME ] = 1;
		SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d) has ended the round.", ReturnPlayerName( playerid ), playerid );
 	}
 	else if ( strmatch( params, "zm" ) )
 	{
		if ( g_zm_gameData[ E_GAME_ENDED ] ) return SendError( playerid, "The round has already ended!" );
		zm_EndCurrentGame( false, ""COL_ADMIN"[ADMIN]"COL_WHITE" Admin has ended the round, a new round is now loading." );
 	}
 	else SendUsage( playerid, "/endround [MP/ZM]" );
	return 1;
}

CMD:giveks( playerid, params[ ] )
{

    new
	    pID,
		ks_id
	;
	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"d", pID, ks_id ) ) SendUsage( playerid, "/giveks [PLAYER_ID] [KILLSTREAK_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		new response = GivePlayerKillstreak( pID, ks_id );
		if ( response == 0x1B ) return SendError( playerid, "Invalid Killstreak ID." );
 	    SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You've been given a "COL_GREY"%s"COL_WHITE" by %s(%d)!", KillstreakToString( ks_id ), ReturnPlayerName( playerid ), playerid );
 		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have given %s(%d)'s a "COL_GREY"%s"COL_WHITE"!", ReturnPlayerName( pID ), pID, KillstreakToString( ks_id ) );
        AddAdminLogLineFormatted( "%s(%d) has given %s(%d) a %s", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, KillstreakToString( ks_id ) );
	}
	return 1;
}

CMD:rangeban( playerid, params [ ] )
{
    new
	    pID,
		reason[ 50 ]
	;
	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"S(No Reason)[50]", pID, reason ) ) SendUsage( playerid, "/rangeban [PLAYER_ID] [REASON]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid playerid." );
    else if ( g_userData[ pID ][ E_ADMIN ] > g_userData[ playerid ][ E_ADMIN ] ) return SendError( playerid, "This player has a higher administration level than you." );
	else
	{
        AddAdminLogLineFormatted( "%s(%d) has range-banned %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	    SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s has range-banned %s(%d) "COL_GREEN"[REASON: %s]", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), pID, reason );
		RangeBanPlayer( pID );
	}
	return 1;
}

CMD:doublexp( playerid, params[ ] )
{
	//g_doubleXP
	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    g_doubleXP = ( g_doubleXP == true ? (false) : (true) );
    SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have %s double XP!", g_doubleXP == true ? ("toggled") : ("un-toggled") );
	if ( g_doubleXP ) GameTextForAll( "~w~DOUBLE ~y~~h~XP~g~~h~~h~ ACTIVATED!", 6000, 3 );
	AddAdminLogLineFormatted( "%s(%d) has %s double xp", ReturnPlayerName( playerid ), playerid, g_doubleXP == true ? ("toggled") : ("un-toggled") );
	return 1;
}

CMD:unbanip( playerid, params[ ] )
{
	new
		address[16],
		Query[70]
	;

	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if (sscanf(params, "s[16]", address)) SendUsage(playerid, "/unbanip [IP_ADDRESS]");
	else
	{
		format( Query, sizeof( Query ), "SELECT `IP`,`SERVER` FROM `BANS` WHERE `IP` = '%s'", mysql_escape( address ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanIP", "dds", playerid, 0, address );
	}
	return 1;
}

thread OnPlayerUnbanIP( playerid, irc, address[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );
	if ( rows )
	{
		new szServer[ 2 ];
		cache_get_field_content( 0,  "SERVER", szServer );
		if ( strval( szServer ) != 1 ) return !irc ? SendError( playerid, "This IP is not from the Call of Duty For SA-MP server." ) : 1;

    	if ( !irc ) AddAdminLogLineFormatted( "%s(%d) has un-banned IP %s", ReturnPlayerName( playerid ), playerid, address );
		else
		{
			format(szNormalString, sizeof(szNormalString),"(UNBANNED) IP %s has been un-banned from the server.", address);
			//IRC_GroupSay(gGroupID, IRC_CHANNEL, szNormalString);
		}
		format( szNormalString, sizeof( szNormalString ), "DELETE FROM `BANS` WHERE `IP` = '%s'", mysql_escape( address ) );
		mysql_single_query( szNormalString );
	 	SendClientMessageToAllFormatted(COLOR_YELLOW, ""COL_ADMIN"[ADMIN]{FFFFFF} IP %s has been un-banned from the server.", address );
	}
	else {
		if ( !irc ) SendError(playerid, "This IP Address is not recognised!");
	}
	return 1;
}

CMD:unban( playerid, params[ ] )
{
	new
		player[24],
		Query[70]
	;

	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if (sscanf(params, "s[24]", player)) SendUsage(playerid, "/unban [NAME]");
	else
	{
		format( Query, sizeof( Query ), "SELECT `NAME`,`SERVER` FROM `BANS` WHERE `NAME` = '%s'", mysql_escape( player ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanPlayer", "dds", playerid, 0, player );
	}
	return 1;
}

thread OnPlayerUnbanPlayer( playerid, irc, player[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );
	if ( rows )
	{
		new szServer[ 2 ];
		cache_get_field_content( 0,  "SERVER", szServer );
		if ( strval( szServer ) != 1 ) return !irc ? SendError( playerid, "This user is not from the Call of Duty For SA-MP server." ) : 1;

   	 	if ( !irc ) AddAdminLogLineFormatted( "%s(%d) has un-banned %s", ReturnPlayerName( playerid ), playerid, player );
		else
		{
			format(szNormalString, sizeof(szNormalString),"(UNBANNED) %s has been un-banned from the server.", player);
			//IRC_GroupSay(gGroupID, IRC_CHANNEL, szNormalString);
		}
		format(szNormalString, sizeof(szNormalString), "DELETE FROM `BANS` WHERE `NAME` = '%s'", mysql_escape( player ) );
		mysql_single_query( szNormalString );
	 	SendClientMessageToAllFormatted(COLOR_YELLOW, ""COL_ADMIN"[ADMIN]{FFFFFF} \"%s\" has been un-banned from the server.", player);
	}
	else {
		if ( !irc ) SendError(playerid, "This player is not recognised!");
	}
	return 1;
}

CMD:toggleviewpm( playerid, params[ ] )
{
	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
    p_ToggledViewPM{ playerid } = ( p_ToggledViewPM{ playerid } == true ? (false) : (true) );
    SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have %s viewing peoples private messages.", p_ToggledViewPM{ playerid } == true ? ("toggled") : ("un-toggled") );
	AddAdminLogLineFormatted( "%s(%d) has %s viewing pm's", ReturnPlayerName( playerid ), playerid, p_ToggledViewPM{ playerid } == true ? ("toggled") : ("un-toggled") );
 	return 1;
}

CMD:changename( playerid, params[ ] )
{
	new
	    pID,
	    nName[ 24 ],
	    szQuery[ 128 ]
	;
	if ( g_userData[ playerid ][ E_ADMIN ] < 5 ) return SendError(playerid, ADMIN_COMMAND_REJECT);
	else if ( sscanf( params, ""#sscanf_u"s[24]", pID, nName ) ) return SendUsage( playerid, "/changename [PLAYER_ID] [NEW_NAME]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) SendError( playerid, "Invalid playerid." );
	else if ( !regex_match( nName, "^[a-zA-Z0-9@=_\\[\\]\\.\\(\\)\\$]+$" ) ) return SendError( playerid, "Invalid Name Character." );
	else
	{
        AddAdminLogLineFormatted( "%s(%d) has changed %s(%d)'s name to %s", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, nName );
	    format( szQuery, 100, "SELECT `NAME` FROM `COD` WHERE `NAME` = '%s'", mysql_escape( nName ) );
	  	mysql_function_query( dbHandle, szQuery, true, "OnPlayerChangeName", "dds", playerid, pID, nName );
	}
	return 1;
}

thread OnPlayerChangeName( playerid, pID, nName[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );
	if ( !rows )
	{
		format( szNormalString, sizeof( szNormalString ), "UPDATE `COD` SET `NAME` = '%s' WHERE `ID`=%d", mysql_escape( nName ), g_userData[ pID ] [ E_ID ] );
	 	mysql_single_query( szNormalString );
		SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have changed %s(%d)'s name to %s!", ReturnPlayerName( pID ), pID, nName );
		SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" Your name has been changed to %s by %s(%d)!", nName, ReturnPlayerName( playerid ), playerid );
		SetPlayerName( pID, nName );
	}
	else SendError( playerid, "This name is taken already." );
}

/* RCON */
CMD:givecash( playerid, params [ ] )
{
	new
	    pID,
	    cash
	;
	if ( !IsPlayerAdmin( playerid ) ) return 0;
	else if ( sscanf( params, ""#sscanf_u"d", pID, cash ) ) SendUsage( playerid, "/givecash [PLAYER_ID] [CASH]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) SendError( playerid, "Invalid playerid." );
	else
	{
	    GivePlayerCash( pID, cash );
		AddAdminLogLineFormatted( "%s(%d) has given %s(%d) %d dollars", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, cash );
	    SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s(%d) has given you "COL_GOLD"%s", ReturnPlayerName( playerid ), playerid, ConvertPrice( cash ) );
	    SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]{FFFFFF} You've given %s(%d) "COL_GOLD"%s", ReturnPlayerName( pID ), pID, ConvertPrice( cash ) );
	}
	return 1;
}

CMD:setviplevel( playerid, params[ ] )
{
	new
	    pID,
	    level
	;

	if ( !IsPlayerAdmin( playerid ) ) return 0;
    else if ( sscanf( params, ""#sscanf_u"d", pID, level ) ) return SendUsage( playerid, "/setviplevel [PLAYER_ID] [VIP_LEVEL]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) SendError( playerid, "Invalid playerid." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "This player is not logged in." );
	else if ( level > 3 || level < 0 ) return SendError( playerid, "Specify a level between 0 - 3 please!" );
    else
    {
	    SetPlayerVipLevel( pID, level );
        SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP LEVEL]"COL_WHITE" You have set %s(%d)'s VIP package to %s.", ReturnPlayerName( pID ), pID, VIPLevelToString( level ) );
		SendClientMessageFormatted( pID, -1, ""COL_GOLD"[VIP LEVEL]"COL_WHITE" Your VIP package has been set to %s by %s(%d)", VIPLevelToString( level ), ReturnPlayerName( playerid ), playerid );
    }
	return 1;
}

CMD:updaterules( playerid, params[ ] )
{
	if ( !IsPlayerAdmin( playerid ) ) return 0;
	HTTP( playerid, HTTP_GET, "irresistiblegaming.com/cod-rules.txt", "", "OnRulesHTTPResponse" );
	SendServerMessage( playerid, "Updating Server Rules... Please wait!" );
	return 1;
}

CMD:setscore( playerid, params[ ] )
{
	new
	    pID, score
	;
	if ( !IsPlayerAdmin( playerid ) ) return 0;
	else if ( sscanf( params, ""#sscanf_u"d", pID, score ) ) SendUsage( playerid, "/setscore [PLAYER_ID] [SCORE]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) SendError( playerid, "Invalid playerid." );
	else
	{
        AddAdminLogLineFormatted( "%s(%d) has set %s(%d)'s score to %d", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, score );
	    SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have given %s(%d) %d score.", ReturnPlayerName( pID ), pID, score );
        SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" You have been given %d score from %s(%d)", score, ReturnPlayerName( playerid ), playerid );
		SetPlayerScore( pID, score );
	}
	return 1;
}

CMD:givexp( playerid, params [ ] )
{
	new
	    pID,
	    xp
	;
	if ( !IsPlayerAdmin( playerid ) ) return 0;
	else if ( sscanf( params, ""#sscanf_u"d", pID, xp ) ) SendUsage( playerid, "/givexp [PLAYER_ID] [XP_AMOUNT]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) SendError( playerid, "Invalid playerid." );
	else
	{
	    GivePlayerXP( pID, xp );
        AddAdminLogLineFormatted( "%s(%d) has given %s(%d) %d XP", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, xp );
	    SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s(%d) has given you %d XP.", ReturnPlayerName( playerid ), playerid, xp );
	    SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]{FFFFFF} You've given %s(%d) %d XP.", ReturnPlayerName( pID ), pID, xp );
	}
	return 1;
}

CMD:kickall( playerid, params[ ] )
{
	if ( !IsPlayerAdmin( playerid ) ) return 0;

	SendClientMessageToAll( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" Everyone has been kicked from the server due to a server update." );
	for( new i, g = GetMaxPlayers( ); i < g; i++ )
	{
	    if ( IsPlayerConnected( i ) )
	    {
	        Kick( i );
	    }
	}
	return 1;
}

CMD:setlevel( playerid, params[ ] )
{
	new
	    pID,
	    level
	;
	if ( g_userData[ playerid ] [ E_ADMIN ] < 6 ) return 0;
	else if ( sscanf( params, ""#sscanf_u"d", pID, level ) ) SendUsage( playerid, "/setlevel [PLAYER_ID] [LEVEL]");
	else if ( level < 0 || level > 6 ) return SendError( playerid, "Please specify an administration level between 0 and 6." );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		if ( !IsPlayerLorenc( playerid ) && g_userData[ playerid ] [ E_ADMIN ] >= 6 && level > 5 )
			return SendError( playerid, "You maximum level you are able to promote a person to is 5." );

		g_userData[ pID ][ E_ADMIN ] = level;
		AddAdminLogLineFormatted( "%s(%d) has set %s(%d)'s admin level to %d", ReturnPlayerName( playerid ), playerid,  ReturnPlayerName( pID ), pID, level );
		SendClientMessageFormatted( pID, -1, ""COL_ADMIN"[ADMIN]{FFFFFF} %s(%d) has set your admin level to %d!", ReturnPlayerName( playerid ), playerid, level );
	    SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]{FFFFFF} You've set %s(%d)'s admin level to %d!", ReturnPlayerName( pID ), pID, level );
	}
	return 1;
}

CMD:setleveloffline( playerid, params[ ] )
{
	new
		iLevel, szName[ 24 ];

	if ( g_userData[ playerid ] [ E_ADMIN ] < 6 ) return 0;
	else if ( sscanf( params, "ds[24]", iLevel, szName ) ) SendUsage( playerid, "/setleveloffline [LEVEL] [PLAYER_NAME]");
	else if ( iLevel < 0 || iLevel > 5 ) return SendError( playerid, "Please specify an administration level between 0 and 5." );
	else
	{
		format( szNormalString, sizeof( szNormalString ), "UPDATE `COD` SET `ADMIN`=%d WHERE `NAME`='%s'", iLevel, mysql_escape( szName ) );
		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerUpdateAdminLevel", "iis", playerid, iLevel, szName );
	}
	return 1;
}

thread OnPlayerUpdateAdminLevel( playerid, level, name[ ] )
{
	if ( cache_affected_rows( ) ) {
		AddAdminLogLineFormatted( "%s(%d) has set %s's admin level to %d", ReturnPlayerName( playerid ), playerid, name, level );
	    return SendClientMessageFormatted( playerid, -1, ""COL_ADMIN"[ADMIN]{FFFFFF} You've set %s's admin level to %d!", name, level );
	}

	return SendError( playerid, "This user does not exist." );
}

/* End of admin commands */

/* ** IRC **
IRCCMD:lastlogged(botid, channel[], user[], host[], params[])
{
	if (IRC_IsVoice(botid, channel, user))
	{
		static
		    player[ MAX_PLAYER_NAME ]
		;

		if ( sscanf( params, "s[24]", player ) ) return 0;
		else
		{
			format( szNormalString, sizeof( szNormalString ), "SELECT `LAST_LOGGED` FROM `COD` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
	  		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerLastLogged", "iis", botid, 1, player );
		}
	}
	else IRC_Notice( gGroupID, user, "4COMMAND ERROR:1 This command requires voice (+v)." );
	return 1;
}

IRCCMD:idof(botid, channel[], user[], host[], params[])
{
	if (IRC_IsVoice(botid, channel, user))
	{
		new pID;
		if ( sscanf( params, ""#sscanf_u"", pID ) ) return 0;
		if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return 0;
		format( szNormalString, sizeof( szNormalString ),"3ID OF '%s': %d", ReturnPlayerName( pID ), pID );
		IRC_GroupSay( gGroupID, IRC_CHANNEL, szNormalString );
	}
	else IRC_Notice( gGroupID, user, "4COMMAND ERROR:1 This command requires voice (+v)." );
	return 1;
}

IRCCMD:say(botid, channel[], user[], host[], params[])
{
	if (IRC_IsVoice(botid, channel, user))
	{
		new
			szAntispam[ 64 ],
			szMode[ 2 ]
		;
		IRC_GetUserChannelMode( botid, channel, user, szMode );

		if ( !isnull( params ) && !textContainsIP( params ) )
		{
			format( szAntispam, 64, "!say_%s", user );
			if ( GetGVarInt( szAntispam ) < gettime( ) )
			{
				if ( !IRC_IsOp( botid, channel, user ) ) SetGVarInt( szAntispam, gettime( ) + 2 );
				SendClientMessageToAllFormatted(-1, "{E14DFF}(IRC) {F2B3FF}%s{E14DFF}%s:{FFFFFF} %s", szMode, user, params );
				IRC_GroupSayFormatted( gGroupID, IRC_CHANNEL, "(IRC) %s%s: %s", szMode, user, params );
			}
			else IRC_GroupSay( gGroupID, user,"You must wait 2 seconds before speaking again." );
		}
	}
	else IRC_Notice( gGroupID, user, "4COMMAND ERROR:1 This command requires voice (+v)." );
	return 1;
}

IRCCMD:players(botid, channel[], user[], host[], params[])
{
	if (IRC_IsVoice(botid, channel, user))
	{
		szLargeString[ 0 ] = '\0';
		if ( Iter_Count(Player) <= 25 )
		{
			foreach(new i : Player) {
			    if ( IsPlayerConnected( i ) ) {
			        format( szLargeString, sizeof( szLargeString ), "%s%s(%d), ", szLargeString, ReturnPlayerName( i ), i );
			    }
			}
		}
		format( szLargeString, sizeof( szLargeString ), "%sThere are %d player(s) online.", szLargeString, Iter_Count(Player) );
		IRC_GroupSay( gGroupID, IRC_CHANNEL, szLargeString );
	}
	else IRC_Notice( gGroupID, user, "4COMMAND ERROR:1 This command requires voice (+v)." );
	return 1;
}

IRCCMD:admins(botid, channel[], user[], host[], params[])
{
	if (IRC_IsVoice(botid, channel, user))
	{
		new count = 0;
		szBigString[ 0 ] = '\0';

		foreach(new i : Player) {
		    if ( IsPlayerConnected( i ) && g_userData[ i ] [ E_ADMIN ] > 0 ) {
		        format( szBigString, sizeof( szBigString ), "%s%s(%d), ", szBigString, ReturnPlayerName( i ), i );
		        count++;
		    }
		}

		format( szBigString, sizeof( szBigString ), "%sThere are %d admin(s) online.", szBigString, count );
		IRC_GroupSay( gGroupID, IRC_CHANNEL, szBigString );
	}
	else IRC_Notice( gGroupID, user, "4COMMAND ERROR:1 This command requires voice (+v)." );
	return 1;
}*/

/* HALF OP
IRCCMD:acmds(botid, channel[], user[], host[], params[])
{
	if (IRC_IsHalfop(botid, channel, user))
	{
 		IRC_Notice( gGroupID, user,"HALF-OP: !akick, !aban, !asuspend, !awarn, !agetip" );
 		IRC_Notice( gGroupID, user,"OP: !aunban, !aunbanip, !arangeban" );
	}
	return 1;
}

IRCCMD:akick(botid, channel[], user[], host[], params[])
{
	if (IRC_IsHalfop(botid, channel, user))
	{
		new pID, reason[64];
		if (sscanf( params, ""#sscanf_u"S(No reason)[64]", pID, reason)) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !akick [PLAYER_ID] [REASON]" );
		if (IsPlayerConnected(pID))
		{
			IRC_NoticeFormatted( gGroupID, user, "3COMMAND SUCCESS1 %s(%d) has been kicked.", ReturnPlayerName( pID ), pID );
		    SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[IRC ADMIN]{FFFFFF} %s(%d) has been kicked by %s "COL_GREEN"[REASON: %s]", ReturnPlayerName(pID), pID, user, reason);
			KickPlayerTimed(pID);
		}
		else IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Player is not connected!" );
	}
	return 1;
}

IRCCMD:aban(botid, channel[], user[], host[], params[])
{
	if ( IRC_IsHalfop( botid, channel, user ) )
	{
		new pID, reason[64];
		if (sscanf( params, ""#sscanf_u"S(No reason)[64]", pID, reason)) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !aban [PLAYER_ID] [REASON]" );
		if (IsPlayerConnected(pID))
		{
			IRC_NoticeFormatted( gGroupID, user, "3COMMAND SUCCESS1 %s(%d) has been banned.", ReturnPlayerName( pID ), pID );
		    SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[IRC ADMIN]{FFFFFF} %s has banned %s(%d) "COL_GREEN"[REASON: %s]", user, ReturnPlayerName( pID ), pID, reason );
			AdvancedBan( pID, "IRC Administrator", reason, ReturnPlayerIP( pID ) );
		}
		else IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Player is not connected!" );
	}
	return 1;
}

IRCCMD:asuspend(botid, channel[], user[], host[], params[])
{
	if ( IRC_IsHalfop( botid, channel, user ) )
	{
		new pID, reason[50], hours, days;
		if ( sscanf( params, ""#sscanf_u"ddS(No Reason)[50]", pID, hours, days, reason ) ) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !asuspend [PLAYER_ID] [HOURS] [DAYS] [REASON]" );
		if ( hours < 0 || hours > 24 ) return IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Please specify an hour between 0 and 24." );
		if ( days < 0 || days > 60 ) return IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Please specifiy the amount of days between 0 and 60." );
		if ( days == 0 && hours == 0 ) return IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Invalid time specified." );
		if ( IsPlayerConnected( pID ) )
		{
			IRC_NoticeFormatted( gGroupID, user, "3COMMAND SUCCESS1 %s(%d) has been suspended for %d hour(s) and %d day(s).", ReturnPlayerName( pID ), pID, hours, days );
			SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[IRC ADMIN]{FFFFFF} %s has suspended %s(%d) for %d hour(s) and %d day(s) "COL_GREEN"[REASON: %s]", user, ReturnPlayerName( pID ), pID, hours, days, reason );
			new time = gettime( ) + ( hours * 3600 ) + ( days * 86400 );
			AdvancedBan( pID, "IRC Administrator", reason, ReturnPlayerIP( pID ), time );
		}
		else IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Player is not connected!" );
	}
	return 1;
}

IRCCMD:awarn(botid, channel[], user[], host[], params[])
{
	if ( IRC_IsHalfop( botid, channel, user ) )
	{
		new pID, reason[50];
		if ( sscanf( params, ""#sscanf_u"S(No Reason)[32]", pID, reason ) ) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !awarn [PLAYER_ID] [REASON]" );
		if ( IsPlayerConnected( pID ) )
		{
	    	p_Warns[ pID ] ++;
			IRC_NoticeFormatted( gGroupID, user, "3COMMAND SUCCESS1 %s(%d) has been warned [%d/3].", ReturnPlayerName( pID ), pID, p_Warns[ pID ] );
        	SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d) has been warned by %s "COL_GREEN"[REASON: %s]", ReturnPlayerName( pID ), pID, user, reason );

			if ( p_Warns[ pID ] >= 3 )
		    {
		        p_Warns[ pID ] = 0;
		        SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" %s(%d) has been kicked from the server. "COL_GREEN"[REASON: Excessive Warns]", ReturnPlayerName( pID ), pID );
		        KickPlayerTimed( pID );
		        return 1;
		    }
		}
		else IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Player is not connected!" );
	}
	return 1;
}

IRCCMD:agetip(botid, channel[], user[], host[], params[])
{
	if ( IRC_IsHalfop( botid, channel, user ) )
	{
		new pID;
		if ( sscanf( params, ""#sscanf_u"", pID ) ) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !awarn [PLAYER_ID] [REASON]" );
		if ( IsPlayerConnected( pID ) )
		{
			if ( g_userData[ pID ] [ E_ADMIN ] > 4 ) return IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 No sexy head admin targetting!");
			IRC_NoticeFormatted( gGroupID, user, "3COMMAND SUCCESS1 %s(%d)'s IP is 14%s", ReturnPlayerName( pID ), pID, ReturnPlayerIP( pID ) );
		}
		else IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Player is not connected!" );
	}
	return 1;
}*/

/* OP
IRCCMD:akickall(botid, channel[], user[], host[], params[])
{
	if (IRC_IsOwner(botid, channel, user))
	{
		SendClientMessageToAll( -1, ""COL_ADMIN"[ADMIN]"COL_WHITE" Everyone has been kicked from the server due to a server update." );
		for( new i, g = GetMaxPlayers( ); i < g; i++ )
		{
		    if ( IsPlayerConnected( i ) )
		    {
		        Kick( i );
		    }
		}
		IRC_Notice( gGroupID, user,"3COMMAND SUCCESS1 All users have been kicked from the server." );
	}
	return 1;
}

IRCCMD:arangeban(botid, channel[], user[], host[], params[])
{
    new
	    pID,
		reason[ 50 ]
	;
	if (!IRC_IsOp(botid, channel, user)) return 0;
	else if ( sscanf( params, ""#sscanf_u"S(No Reason)[50]", pID, reason ) ) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !arangeban [PLAYER_ID] [REASON]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) IRC_Notice( gGroupID, user,"4COMMAND ERROR:1 Player is not connected!" );
	else
	{
	    SendClientMessageToAllFormatted( -1, ""COL_ADMIN"[IRC ADMIN]{FFFFFF} %s has range-banned %s(%d) "COL_GREEN"[REASON: %s]", user, ReturnPlayerName( pID ), pID, reason );
		RangeBanPlayer( pID );
	}
	return 1;
}

IRCCMD:aunban(botid, channel[], user[], host[], params[])
{
	new
		player[24],
		Query[70]
	;

	if (!IRC_IsOp(botid, channel, user)) return 0;
	else if (sscanf(params, "s[24]", player)) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !aunban [PLAYER]" );
	else
	{
		format( Query, sizeof( Query ), "SELECT `NAME` FROM `BANS` WHERE `NAME` = '%s'", mysql_escape( player ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanPlayer", "dds", botid, 1, player );
	}
	return 1;
}

IRCCMD:aunbanip(botid, channel[], user[], host[], params[])
{
	new
		address[16],
		Query[70]
	;

	if (!IRC_IsOp(botid, channel, user)) return 0;
	else if (sscanf(params, "s[16]", address)) return IRC_Notice( gGroupID, user,"7COMMAND USAGE:1 !aunbanip [IP]" );
	else
	{
		format( Query, sizeof( Query ), "SELECT `IP` FROM `BANS` WHERE `IP` = '%s'", mysql_escape( address ) );
		mysql_function_query( dbHandle, Query, true, "OnPlayerUnbanIP", "dds", botid, 0, address );
	}
	return 1;
}

IRCCMD:rcon(botid, channel[], user[], host[], params[])
{
	if (IRC_IsOwner(botid, channel, user))
	{
		if (!isnull(params))
		{
			if (strcmp(params, "exit", true) != 0)
			{
				new msg[128];
				format(msg, sizeof(msg), "RCON command %s has been executed.", params);
				IRC_Notice(gGroupID, channel, msg);
				SendRconCommand(params);
			}
		}
	}
	return 1;
}*/

/* ** End of Commands ** */


public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if ( IsPlayerInZombies( playerid ) ) StopPlayer( playerid );
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if ( IsPlayerInZombies( playerid ) && newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER ) StopPlayer( playerid );
	return 1;
}

stock zm_EndCurrentGame( bool: won, msg[ ] = "" )
{
	if ( g_zm_gameData[ E_GAME_ENDED ] )
		return; // It's already ended, so wait mate.

	g_zm_gameData[ E_GAME_STARTED ] = false;
	g_zm_gameData[ E_GAME_ENDED ] = true;

	if ( strlen( msg ) > 3 )
		SendClientMessageToMode( MODE_ZOMBIES, -1, msg );

	new
	    m;

	if ( g_zm_gameData[ E_NEXT_MAP ] == -1 )
	{
	    redo_random_map:
		{
			m = Iter_Random(zm_maps);
			if ( m == g_zm_gameData[ E_MAP ] ) goto redo_random_map;
		}
	}
	else
	{
		m = g_zm_gameData[ E_NEXT_MAP ];
		g_zm_gameData[ E_NEXT_MAP ] = -1;
	}

	SendClientMessageToModeFormatted( MODE_ZOMBIES, -1, ""COL_RED"[NEXT MAP] "COL_GREY"%s"COL_WHITE" by "COL_GREY"%s"COL_WHITE".", g_zm_mapData[ m ] [ E_NAME ], g_zm_mapData[ m ] [ E_AUTHOR ] );
	SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_RED"[ZOMBIES]"COL_GREY" A new round for zombies is now loading. "COL_RED"[%d/24]", Iter_Count(zm_players) );

    foreach(new playerid : zm_players)
	{
 		//FadePlayerScreen( playerid );
        if ( won )
        {
            g_userData[ playerid ] [ E_VICTORIES ] ++;

	  		#if !defined DEBUG_MODE
            if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://irresistiblegaming.com/game_sounds/TheMonstersWithout.wav" );
            #endif

            GameTextForPlayer( playerid, "~g~You've evacuated!", 9000, 3 );
        }
        else
        {
            g_userData[ playerid ] [ E_LOSSES ] ++;

	     	#if !defined DEBUG_MODE
            if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://irresistiblegaming.com/game_sounds/snowballinhell.wav" );
            #endif

            GameTextForPlayer( playerid, "~r~You've been defeated!", 9000, 3 );
        }
        TogglePlayerControllable( playerid, 0 );
	}

	SetTimerEx( "zm_LoadNewMap", 7650, false, "d", m );
}

class zm_LoadNewMap( mapid )
{
    g_LastFinishedRound = gettime( );
	g_zm_gameData[ E_MAP ] = mapid;

	foreach(new zombieid : zombies)
	{
	 	g_zombieData[ zombieid ] [ E_PERMITTED ] = false;
	 	FCNPC_Respawn( g_zombieData[ zombieid ] [ E_NPCID ] );
	}

	foreach(new playerid : zm_players)
	{
		if ( p_SpectateMode{ playerid } ) TogglePlayerSpectating( playerid, 0 ), p_SpectateMode{ playerid } = false, p_SpectatingPlayer[ playerid ] = INVALID_PLAYER_ID;
	    else SpawnPlayer( playerid );
	}

	FCNPC_RemoveFromVehicle( g_HelicopterNPC );
	FCNPC_Respawn( g_HelicopterNPC );

	g_WaveStarting = PREP_TIME;
	DestroyVehicle( g_HelicopterVehicle );
	g_HelicopterVehicle = INVALID_VEHICLE_ID;
	g_EvacuationTime = ROUND_TIME;
 	DestroyDynamicCP( g_EvacuateCP );
 	g_EvacuateCP = 0xFFFF;
	g_zm_gameData[ E_EVAC_STARTED ] = false;
	g_zm_gameData[ E_GAME_ENDED ] = false;

	format( szNormalString, 96, "mapname %s / %s", g_mp_mapData[ g_mp_gameData[ E_MAP ] ][ E_NAME ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ][ E_NAME ] );
	SendRconCommand( szNormalString );
	return 1;
}

public OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( IsPlayerInZombies( playerid ) )
	{
		if ( !IsPlayerNPC( playerid ) )
		{
	 		if ( checkpointid == g_EvacuateCP )
	 		{
	 		    new
	 		        totalEntered = 0,
			 		totalSpawned = 0;

				foreach(new everyone : zm_players)
				{
				    if ( IsPlayerSpawned( everyone ) && !p_SpectateMode{ everyone } )
				    {
				        totalSpawned++;
						if ( IsPlayerInDynamicCP( everyone, g_EvacuateCP ) ) totalEntered++;
					}
				}

				if ( totalEntered == totalSpawned )
				{
					zm_EndCurrentGame( true );
				}
	 		}
		}
		return 1;
	}
	else
	{
		if ( g_mp_gameData[ E_STARTED ] == true && g_mp_gameData[ E_GAMEMODE ] == MODE_CTF )
		{
			if ( Iter_Count(mp_players) < 4 )
				return SendError( playerid, "Unfortunately, checkpoints are disabled until there are at least four players." );

			if ( GetPlayerState( playerid ) == PLAYER_STATE_SPECTATING || IsPlayerInAnyVehicle( playerid ) || IsPlayerAdminOnDuty( playerid ) )
				return 0; // Some additional checks

			if ( p_AntiSpawnKillEnabled{ playerid } )
				return SendError( playerid, "Checkpoints are disabled if you're in spawn protection mode." );

			if ( p_Team[ playerid ] == TEAM_TROPAS && checkpointid == g_CTFFlag[ TEAM_OP40 ] )
			{
			    if (g_CTFFlagStolen{ TEAM_OP40 } == false)
			    {
			        g_CTFFlagStolen{ TEAM_OP40 } = true;
				    SetPlayerAttachedObject( playerid, 1, 2993, 5, 0.034539, 0.009715, 0.013957, 183.756347, 27.235815, 85.721145, 1.000000, 1.000000, 1.000000 ); // kmb_goflag - BETTER ONE USE!
		            p_StolenFlag[ playerid ] [ TEAM_OP40 ] = true;
		            SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" %s(%d) has stolen the OP40 flag!", ReturnPlayerName( playerid ), playerid );
				}
				else SendError( playerid, "Team OP40 has already been captured." );
			}
			if ( p_Team[ playerid ] == TEAM_OP40 && checkpointid == g_CTFFlag[ TEAM_TROPAS ] )
			{
			    if ( g_CTFFlagStolen{ TEAM_TROPAS } == false )
			    {
			  		g_CTFFlagStolen{ TEAM_TROPAS } = true;
				    SetPlayerAttachedObject( playerid, 1, 2993, 5, 0.034539, 0.009715, 0.013957, 183.756347, 27.235815, 85.721145, 1.000000, 1.000000, 1.000000 ); // kmb_goflag - BETTER ONE USE!
		            p_StolenFlag[ playerid ] [ TEAM_TROPAS ] = true;
		            SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" %s(%d) has stolen the Tropas flag!", ReturnPlayerName( playerid ), playerid );
				}
				else SendError( playerid, "Team Tropas has already been captured." );
			}
			if ( p_Team[ playerid ] == TEAM_OP40 && checkpointid == g_CTFFlag[ TEAM_OP40 ] )
			{
			    if ( g_CTFFlagStolen{ TEAM_TROPAS } == true && p_StolenFlag[ playerid ] [ TEAM_TROPAS ] == true )
			    {
					if ( g_CTFFlagStolen{ TEAM_OP40 } == true)
						return SendError( playerid, "You cannot return the flag if OP40's flag is taken!" );

					RemovePlayerAttachedObject( playerid, 1 );
					g_CTFFlagStolen{ TEAM_TROPAS } = false;
					p_StolenFlag[ playerid ] [ TEAM_TROPAS ] = false;
		            SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" Tropas' flag has been captured! Team OP40 has earned 150 score!" );
					GivePlayerXP( playerid, 150 );
		        	GiveTeamScore( TEAM_OP40, 150, playerid );
			    }
			}
			if ( p_Team[ playerid ] == TEAM_TROPAS && checkpointid == g_CTFFlag[ TEAM_TROPAS ] )
			{
			    if ( g_CTFFlagStolen{ TEAM_OP40 } == true && p_StolenFlag[ playerid ] [ TEAM_OP40 ] == true )
			    {
			        if ( g_CTFFlagStolen{ TEAM_TROPAS } == true )
						return SendError( playerid, "You cannot return the flag if Tropas' flag is taken!" );

	           		RemovePlayerAttachedObject(playerid, 1);
					g_CTFFlagStolen{ TEAM_TROPAS } = false;
					p_StolenFlag[ playerid ] [ TEAM_TROPAS ] = false;
		            SendClientMessageToMode( MODE_MULTIPLAYER,-1, ""COL_ORANGE"[GAME]"COL_GREY" OP40's flag has been captured! Team Tropas has earned 150 score!" );
	                g_CTFFlagStolen{ TEAM_OP40 } = false;
					StripPlayerFlag( playerid );
					GivePlayerXP( playerid, 150 );
					GiveTeamScore( TEAM_TROPAS, 150, playerid );
			    }
			}
		}
	}
	return 1;
}
public OnPlayerEnterRaceCheckpoint( playerid )
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint( playerid )
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn( playerid )
{
	if ( p_Team[ playerid ] == NO_TEAM )
	    return 0;

	return 1;
}


public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpDynamicPickup( playerid, pickupid )
{
	if ( pickupid == INVALID_OBJECT_ID )
		return 0;

	if ( pickupid == p_ThrowingkPickup[ playerid ] && getPlayerEquipment( playerid ) == EQUIPMENT_TOMAHAWK && g_userData[ playerid ] [ E_VIP_LEVEL ] == 3 )
	{
		GivePlayerWeapon( playerid, WEAPON_KNIFE, 1 );
		DestroyDynamicPickup( p_ThrowingkPickup[ playerid ] );
		p_ThrowingkPickup[ playerid ] = INVALID_OBJECT_ID;
		return 1;
	}

	for( new i; i < MAX_DROPPABLE_PICKUPS; i++ ) if ( g_pickupData[ i ] [ E_CREATED ] )
	{
	    if ( g_pickupData[ i ] [ E_PICKUP_ID ] == pickupid )
	    {
			new
				keys, weaponid;
			GetPlayerKeys( playerid, keys, weaponid, weaponid );

			switch( g_pickupData[ i ] [ E_TYPE ] )
			{
				case PICKUP_TYPE_MONEY: 	GivePlayerCash( playerid, g_pickupData[ i ] [ E_TANK ] == true ? 300 : 10 );
				case PICKUP_TYPE_AMMO: 		GivePlayerWeapon( playerid, GetPlayerWeapon( playerid ), g_pickupData[ i ] [ E_AMMO ] );
				case PICKUP_TYPE_WEAPON:
				{
					if ( IsWeaponSlotOccupied( playerid, GetWeaponSlot( g_pickupData[ i ] [ E_WEAPON ] ), weaponid ) && !( keys & KEY_SPRINT ) ) {
						GameTextForPlayer( playerid, "~w~Pick this weapon up by ~g~~h~sprinting~w~ over it!", 2500, 4 );
						break;
					}
					GivePlayerWeapon( playerid, g_pickupData[ i ] [ E_WEAPON ], g_pickupData[ i ] [ E_AMMO ] );
				}
				case PICKUP_TYPE_HEALTH: 	SetPlayerHealth( playerid, 100.0 );
			}

			PlayerPlaySound( playerid, 1150, 0.0, 0.0, 0.0 );
			DestroyDroppablePickup( i );
	        break;
	    }
	}
	return 1;
}

stock IsWeaponSlotOccupied( playerid, slot, &weapon )
{
	new weapons[ 2 ];

 	GetPlayerWeaponData(playerid, slot, weapons[ 0 ], weapons[ 1 ]);
 	weapon = weapons[ 0 ];

 	return weapons[ 1 ] != 0;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu( playerid )
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

stock RemoveAllCarePackages( )
{
	for( new i = 0; i < MAX_CAREPACKAGES; i++ )
	{
		Iter_Remove(carepackages, i);
		DestroyObject( g_carePackageData[ i ] [ E_PACKAGE ] ), g_carePackageData[ i ] [ E_PACKAGE ] = INVALID_OBJECT_ID;
		DestroyObject( g_carePackageData[ i ] [ E_FLARE ] ), g_carePackageData[ i ] [ E_FLARE ] = INVALID_OBJECT_ID;
		g_carePackageData[ i ] [ E_CAPTURING ] = false;
	}
	return 1;
}

class carepackage_Progress( playerid, Bar: progress, care_id, Float: X, Float: Y, Float: Z, percentage )
{
	if ( !IsPlayerConnected( playerid ) || !IsPlayerInRangeOfPoint( playerid, 3.0, X, Y, Z ) || !IsPlayerSpawned( playerid ) )
		return DestroyProgressBar( progress ), g_carePackageData[ care_id ] [ E_CAPTURING ] = false, 0;

	if ( percentage < 100 )
	{
		percentage += 25;
		SetProgressBarValue( progress, float( percentage ) );
		UpdateProgressBar( progress, playerid );
		SetTimerEx( "carepackage_Progress", 500, false, "dddfffd", playerid, _:progress, care_id, X, Y, Z, percentage );
		return 1;
	}
	else
	{
		new
			iRandom;

		redo_random: {
			iRandom = random( MAX_KILLSTREAKS );
			if ( iRandom == KS_NUKE || iRandom == KS_CARE_PACKAGE ) goto redo_random;
		}

		GivePlayerKillstreak( playerid, iRandom );

		Iter_Remove(carepackages, care_id);
		DestroyObject( g_carePackageData[ care_id ] [ E_PACKAGE ] ), g_carePackageData[ care_id ] [ E_PACKAGE ] = INVALID_OBJECT_ID;
		DestroyObject( g_carePackageData[ care_id ] [ E_FLARE ] ), g_carePackageData[ care_id ] [ E_FLARE ] = INVALID_OBJECT_ID;
		g_carePackageData[ care_id ] [ E_CAPTURING ] = false;

        DestroyProgressBar( progress );
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	static
		Float: X, Float: Y, Float: Z, Float: A
	;

	if ( HOLDING( KEY_SPRINT ) && HOLDING( KEY_WALK ) && IsPlayerUsingRadio( playerid ) ) StopAudioStreamForPlayer( playerid );

	if ( IsPlayerInMultiplayer( playerid ) )
	{
		if ( HOLDING( KEY_AIM ) )
		{
		  	if ( getPlayerSecondPerk( playerid ) != PERK_STEADY_AIM && g_ScopedWeapons{ GetPlayerWeapon( playerid ) } == true )
			{
				if ( !p_Aiming{ playerid } )
		  		{
			        p_Aiming{ playerid } = true;
					SetPlayerDrunkLevel( playerid, 3000 );
				}
			}
		}
		if ( PRESSED( KEY_SPRINT ) )
		{
			if ( p_Busy{ playerid } == false )
			{
				foreach(new i : carepackages)
				{
					GetObjectPos( g_carePackageData[ i ] [ E_PACKAGE ], X, Y, Z );
					Z -= 6.4;

					if ( IsPlayerInRangeOfPoint( playerid, 3.0, X, Y, Z ) && !g_carePackageData[ i ] [ E_CAPTURING ] )
					{
						new Bar: progress = CreateProgressBar( 251.00, 278.00, 140.50, 9.19, COLOR_ORANGE, 100.0 );
						ShowProgressBarForPlayer( playerid, progress );
						g_carePackageData[ i ] [ E_CAPTURING ] = true;
						SetTimerEx( "carepackage_Progress", 500, false, "dddfffd", playerid, _:progress, i, X, Y, Z + 2.5, 0 );
						break;
					}
				}
			}
			if ( p_Busy{ playerid } == true && g_LightningStrikeUser == playerid )
		    {
			    new Float: np_rX, Float: np_rY, Float: np_rZ;
				GetObjectRot( g_LightningStrikeObject, np_rX, np_rY, np_rZ );

				p_LightningMode[ playerid ] = ( p_LightningMode[ playerid ] == 0 ? 1 : 0 );
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You are now %s the plane.", !p_LightningMode[ playerid ] ? ("rotating") : ("moving") );

				if ( !p_LightningMode[ playerid ] )
					SetObjectRot( g_LightningStrikeObject, np_rX, np_rY, p_LightningDegree[ playerid ] );
			}
		}
		if ( PRESSED( KEY_FIRE ) )
		{
		    if ( IsPlayerInAnyVehicle( playerid )  )
			{
				new vehicleid = GetPlayerVehicleID( playerid );
				if ( GetVehicleModel( vehicleid ) == 564 )
				{
					GetVehiclePos( vehicleid, X, Y, Z );
					GetVehicleZAngle( vehicleid, A );

					X += 5 * floatsin( -A, degrees );
					Y += 5 * floatcos( -A, degrees );

	    			CreateExplosionEx( playerid, X, Y, Z, 2.5, EXPLOSION_TYPE_TINY, 51 );

					GetVehicleVelocity( vehicleid, X, Y, Z );
					SetVehicleVelocity( vehicleid, -0.05 * floatsin( -A, degrees ), -0.05 * floatcos( -A, degrees ), 0.0 );
				}
				if ( GetVehicleModel( vehicleid ) == 441 )
				{
			        GetVehiclePos( p_RCXDVehicle[ playerid ], X, Y, Z );

	    			CreateExplosionEx( playerid, X, Y, Z, 4.0, EXPLOSION_TYPE_MOLOTOV, 51 );
					endRCXD( playerid );
				}
			}
		    if ( getPlayerEquipment( playerid ) == EQUIPMENT_TOMAHAWK && GetPlayerWeapon( playerid ) == WEAPON_KNIFE && p_ThrowingkTimer[ playerid ] == 0xFF  )
		    {
				new
					Float:angle, Float: pvX, Float: pvY, Float: pvZ;

				GetPlayerPos( playerid, X, Y, Z );
				GetPlayerFacingAngle( playerid, A );

				p_Throwing_pX[ playerid ] = X - floatsin( A, degrees );
				p_Throwing_pY[ playerid ] = Y + floatcos( A, degrees );
				p_Throwing_pZ[ playerid ] = Z - 0.7;

				DestroyDynamicPickup( p_ThrowingkPickup[ playerid ] );
				p_ThrowingkPickup[ playerid ] = INVALID_OBJECT_ID;

				DestroyObject( p_ThrowingkObject[ playerid ] );
				p_ThrowingkObject[ playerid ] = CreateObject(335, p_Throwing_pX[ playerid ], p_Throwing_pY[ playerid ], p_Throwing_pZ[ playerid ] + 0.25, 0.0, 0.0, A, -1 );

				GetPlayerCameraFrontVector( playerid, pvX, pvY, pvZ );
				angle = atan2( -pvX, pvY );

				SetPlayerFacingAngle( playerid, angle );

				pvX = -floatsin(angle, degrees) * THROWINGKNIFE_SPEED * 0.05;
				pvY = floatcos(angle, degrees) * THROWINGKNIFE_SPEED * 0.05;
				pvZ = (pvZ + 0.10) * 1.5 * 0.05 * THROWINGKNIFE_SPEED;

				if ( pvZ < 0 ) pvZ = 0;

				KillTimer( p_ThrowingkTimer[ playerid ] );
				p_ThrowingkStep[ playerid ] = 0;
				RemovePlayerMeleeWeapon( playerid, 4 );

	    		ApplyAnimation( playerid, "GRENADE", "WEAPON_throw", 4.0, 0, 1, 1, 0, 500, 1 );
				p_ThrowingkTimer[ playerid ] = SetTimerEx("Physics_DropKnife", 50, true, "dffff", playerid, A, pvX, pvY, pvZ );
			}

			if ( getPlayerEquipment( playerid ) == EQUIPMENT_C4 && p_EquippedWeapon{ playerid } == WEAPON_BOMB )
			{
			    for( new i = 0; i < MAX_C4; i++ )
			    {
					if ( p_C4Object[ playerid ] [ i ] != INVALID_OBJECT_ID )
					{
			            GetDynamicObjectPos( p_C4Object[ playerid ] [ i ], X, Y, Z );
	    				CreateExplosionEx( playerid, X, Y, Z, 4.0, EXPLOSION_TYPE_MOLOTOV, 39 );
			            DestroyDynamicObject( p_C4Object[ playerid ] [ i ] );
			            p_C4Object[ playerid ] [ i ] = INVALID_OBJECT_ID;
					}
			    }
	    		RemovePlayerWeapon( playerid, 40 );
	    		SetPlayerArmedWeapon( playerid, 0 );
			}
		}
		if ( PRESSED( KEY_NO ) ) return ShowPlayerKillstreaks( playerid );
		if ( PRESSED( KEY_YES ) )
		{
		    switch( getPlayerEquipment( playerid ) )
		    {
		        case EQUIPMENT_CLAYMORE: CreateClaymore( playerid );
		        case EQUIPMENT_C4:
		        {
					if ( p_C4Amount{ playerid } > 0 )
					{
					    for( new i = 0; i < MAX_C4; i++ )
					    {
							if ( p_C4Object[ playerid ] [ i ] == INVALID_OBJECT_ID )
							{
							    GetPlayerPos( playerid, X, Y, Z );
		        				ApplyAnimation( playerid, "BOMBER", "BOM_Plant", 5.0, 0, 1, 1, 0, 0 );
							    p_C4Object[ playerid ] [ i ] = CreateDynamicObject( 363, X, Y, Z - 1.0, -90.0, 0, 0 );
	   							SendServerMessage( playerid, "You have placed a "COL_GREY"C4"COL_WHITE" at this location." );
	   							GivePlayerWeapon( playerid, WEAPON_BOMB, 1 );
	   							p_C4Amount{ playerid }--;
								break;
							}
						}
		            }
		        }
		        case EQUIPMENT_INSERTION:
		        {
		            if ( p_InsertionFlare[ playerid ] != INVALID_OBJECT_ID )
		            {
						if ( IsPlayerInRangeOfPoint( playerid, 3.0, p_InsertionX[ playerid ], p_InsertionY[ playerid ], p_InsertionZ[ playerid ] ) )
						{
						    DestroyTacticalInsertion( playerid );
						    SendServerMessage( playerid, "You have destroyed your "COL_GREY"tactical insertion"COL_WHITE"." );
						}
	     	      	}
		            else
					{
					    GetPlayerPos( playerid, X, Y, Z );
					    format( szNormalString, sizeof( szNormalString ), ""COL_GREEN"Tactical Insertion{FFFFFF}\nSet by "COL_ORANGE"%s(%d){FFFFFF}", ReturnPlayerName( playerid ), playerid );
					    p_InsertionLabel[ playerid ] = Create3DTextLabel( szNormalString, 0xFFFFFFFF, X, Y, Z, 10.0, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ] );
					    p_InsertionFlare[ playerid ] = CreateDynamicObject( 18728, X, Y, Z - 2.5, 0, 0, 0 );
						p_InsertionX[ playerid ] = X;
						p_InsertionY[ playerid ] = Y;
						p_InsertionZ[ playerid ] = Z;
					    SendServerMessage( playerid, "You have placed your "COL_GREY"tactical Insertion"COL_WHITE"." );
					}
		        }
		    }
		}
	}
	else
	{
		if ( p_SpectateMode{ playerid } == true && p_Spectating{ playerid } == false )
		{
		    if ( PRESSED( KEY_FIRE ) )
		    {
				for( new i = p_SpectatingPlayer[ playerid ] + 1; i < MAX_PLAYERS; i++ )
				{
					if ( IsPlayerConnected( i ) && IsPlayerInZombies( i ) && !IsPlayerNPC( i ) && IsPlayerSpawned( i ) && GetPlayerState( i ) != PLAYER_STATE_SPECTATING )
					{
					    p_SpectatingPlayer[ playerid ] = i;
					    if ( IsPlayerInAnyVehicle( i ) ) PlayerSpectateVehicle( playerid, GetPlayerVehicleID( i ) );
						else PlayerSpectatePlayer( playerid, i );
					    format( szNormalString, sizeof( szNormalString ), "~g~%s(%d)~w~~n~Left Click = Next Player and Right Click = Previous Player~n~~n~Evacuation: %s", ReturnPlayerName( i ), i, g_EvacuationTime > 0 ? TimeConvert( g_EvacuationTime ) : ("Started") );
						TextDrawSetString( g_SpectateTD[ playerid ], szNormalString );
						break;
					}
				}
		    }
		    if ( PRESSED( KEY_AIM ) )
		    {
				for( new i = p_SpectatingPlayer[ playerid ] - 1; i > -1; i-- )
				{
					if ( IsPlayerConnected( i ) && IsPlayerInZombies( i ) && !IsPlayerNPC( i ) && IsPlayerSpawned( i ) && GetPlayerState( i ) != PLAYER_STATE_SPECTATING )
					{
					    p_SpectatingPlayer[ playerid ] = i;
					    if ( IsPlayerInAnyVehicle( i ) ) PlayerSpectateVehicle( playerid, GetPlayerVehicleID( i ) );
						else PlayerSpectatePlayer( playerid, i );
					    format( szNormalString, sizeof( szNormalString ), "~g~%s(%d)~w~~n~Left Click = Next Player and Right Click = Previous Player~n~~n~Evacuation: %s", ReturnPlayerName( i ), i, g_EvacuationTime > 0 ? TimeConvert( g_EvacuationTime ) : ("Started") );
						TextDrawSetString( g_SpectateTD[ playerid ], szNormalString );
						break;
					}
				}
		    }
		    return 1;
		}

		if ( PRESSED( KEY_YES ) )
		{
			if ( g_userData[ playerid ] [ E_MEDKIT ] > 1 && !p_ProgressStarted{ playerid } )
			{
	    		SendServerMessage( playerid, "You are now currently healing yourself." );
				ShowCircularProgress( playerid, "Healing", PROGRESS_HEALING, 5000 );
			}
		}
	}
	return 1;
}

class Physics_DropKnife( playerid, Float: Angle, Float: pvX, Float: pvY, Float: pvZ )
{
	static
     	Float: X, Float: Y, Float: Z,
	    Float: aZ,	Float: gZ
	;

    foreach(new i : mp_players)
 	{
	    if ( i == playerid ) continue;
     	if ( p_Team[ i ] == p_Team[ playerid ] ) continue;
     	if ( !IsPlayerSpawned( i ) ) continue;
     	if ( p_AntiSpawnKillEnabled{ i } ) continue;
     	if ( p_Spectating{ i } ) continue;

      	if ( IsPlayerNearObject( i, p_ThrowingkObject[ playerid ], 2.0 ) )
      	{
      		GetPlayerPos( i, X, Y, Z );
			if ( g_userData[ playerid ] [ E_VIP_LEVEL ] == 3 ) p_ThrowingkPickup[ playerid ] = CreateDynamicPickup( 335, 1, X, Y, Z, GetPlayerVirtualWorld( playerid ), GetPlayerInterior( playerid ), playerid );

     		SetPlayerAttachedObject( i, 2, 335, 2, 0.258999, 0.169999, 0.043000, 92.699996, -23.299999, -178.300003, 1.000000, 1.000000, 1.000000 );
			// heart -> SetPlayerAttachedObject( i, 2, 335, 1, 0.197999, 0.291000, 0.145999, 96.400016, 7.599998, 177.600051, 1.000000, 1.000000, 1.000000 );
			ForcePlayerKill( i, playerid, 4 );
			KillTimer( p_ThrowingkTimer[ playerid ] );
			p_ThrowingkTimer[ playerid ] = 0xFF;
			DestroyObject( p_ThrowingkObject[ playerid ] );
			p_ThrowingkObject[ playerid ] = INVALID_OBJECT_ID;
			return 1;
		}
	}

    p_ThrowingkStep[ playerid ]++;
	p_Throwing_pX[ playerid ] += pvX;
	p_Throwing_pY[ playerid ] += pvY;

	aZ = p_Throwing_pZ[ playerid ] + p_ThrowingkStep[ playerid ] * ( pvZ - 10.0 * 0.5 * 0.05 * 0.05 * p_ThrowingkStep[ playerid ] );
	MoveObject( p_ThrowingkObject[ playerid ], p_Throwing_pX[ playerid ], p_Throwing_pY[ playerid ], aZ, THROWINGKNIFE_SPEED );
	SetObjectRot( p_ThrowingkObject[ playerid ], 0.0, p_ThrowingkStep[ playerid ] * 15, Angle + 90.0 );

	/*
		new Float: X, Float: Y, Float: Z;
		GetObjectPos( p_ThrowingkObject[ playerid ], X, Y, Z );
		SetPlayerCameraPos( playerid, X + -floatsin(-Angle,degrees), Y + -floatcos(-Angle,degrees), Z - 1 );
		SetPlayerCameraLookAt( playerid, p_Throwing_pX[ playerid ], p_Throwing_pY[ playerid ], aZ );
	*/

	if ( !g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_GROUND_Z ] ) MapAndreas_FindZ_For2DCoord( p_Throwing_pX[ playerid ], p_Throwing_pY[ playerid ], gZ );
	else gZ = 0.0;

	if ( aZ < gZ )
	{
		if ( g_userData[ playerid ] [ E_VIP_LEVEL ] == 3 )
		{
			GetObjectPos( p_ThrowingkObject[ playerid ], X, Y, Z );
			p_ThrowingkPickup[ playerid ] = CreateDynamicPickup( 335, 1, X, Y, gZ + 1.0, GetPlayerVirtualWorld( playerid ), GetPlayerInterior( playerid ), playerid );
		}
		KillTimer( p_ThrowingkTimer[ playerid ] );
		p_ThrowingkTimer[ playerid ] = 0xFF;
		DestroyObject( p_ThrowingkObject[ playerid ] );
		p_ThrowingkObject[ playerid ] = INVALID_OBJECT_ID;
		return 1;
	}
	return 1;
}

stock IdlePlayer( playerid )
	return ApplyAnimation( playerid, "PED", "IDLE_stance", 4.0, 1, 0, 0, 0, 0, 0 );

class VTOLWarship_Mechanism( playerid, chopper_object, camera_object, Float: height )
{
	static
		Float: sX, Float: sY, keys, unused_vars
	;

	if ( g_warshipData[ E_DEGREE ] >= 360 || !IsPlayerSpawned( playerid ) || !IsPlayerConnected( playerid ) || g_mp_gameData[ E_FINISHED ] )
	{
     	g_warshipData[ E_PLAYER_ID ] = INVALID_PLAYER_ID;
		ClearAnimations( playerid );
		DestroyObject( g_warshipData[ E_MISSILE ] ), g_warshipData[ E_MISSILE ] = INVALID_OBJECT_ID;
	    DestroyObject( chopper_object );
	    DestroyObject( camera_object );
		TextDrawHideForPlayer( playerid, g_CameraVectorAim[ 0 ] );
		TextDrawHideForPlayer( playerid, g_CameraVectorAim[ 1 ] );
	    KillTimer( g_warshipData[ E_TIMER ] );
		p_Busy{ playerid } = false;
		g_warshipData[ E_OCCUPIED ] = false;
	    SetCameraBehindPlayer( playerid );
	    TextDrawHideForPlayer( playerid, p_KillstreakInstructions[ playerid ] );
	    return 1;
	}

	g_warshipData[ E_DEGREE ] += 0.25;

	sX = g_warshipData[ E_X ] + 20.0 * floatcos( g_warshipData[ E_DEGREE ], degrees );
	sY = g_warshipData[ E_Y ] + 20.0 * floatsin( g_warshipData[ E_DEGREE ], degrees );

	SetObjectRot( chopper_object, 0.0, 0.0, g_warshipData[ E_DEGREE ] );
	SetObjectPos( chopper_object, sX, sY, g_warshipData[ E_Z ] );

	GetPlayerKeys( playerid, keys, unused_vars, unused_vars );

	if ( ( keys & KEY_FIRE ) == ( KEY_FIRE ) )
	{
		static Float: vX, Float: vY, Float: vZ, Float: averageZ;
		static Float: cX, Float: cY, Float: cZ;

		static const distance = 60;

		if ( !IsValidObject( g_warshipData[ E_MISSILE ] ) )
		{
	    	GetPlayerCameraPos( playerid, cX, cY, cZ );
	   		GetPlayerCameraFrontVector( playerid, vX, vY, vZ );

	   		g_warshipData[ E_MISSILE ] = CreateObject( 3786, cX, cY, cZ - 1.0, 0, 0, 0 );

	   		for( new i; i < distance; i++ )
	   		{
		   		cX += i * vX;
		   		cY += i * vY;
		   		cZ += i * vZ;

				if ( !g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_GROUND_Z ] ) MapAndreas_FindZ_For2DCoord( cX, cY, averageZ );
				else getAverageZ( averageZ );

		   		if ( cZ < averageZ ) break;
		   	}

			SetObjectFaceCoords3D( g_warshipData[ E_MISSILE ], cX, cY, averageZ, 0, 90, 0 );
			MoveObject( g_warshipData[ E_MISSILE ], cX, cY, averageZ, 50.0 );
		}
	}
	return 1;
}

public OnObjectMoved(objectid)
{
	static
		Float: X, Float: Y, Float: Z;

	if ( g_warshipData[ E_MISSILE ] == objectid )
	{
		GetObjectPos( objectid, X, Y, Z );
    	CreateExplosionEx( g_warshipData[ E_PLAYER_ID ], X, Y, Z, 4.0, EXPLOSION_TYPE_MOLOTOV, 51 );
		DestroyObject( g_warshipData[ E_MISSILE ] );
		g_warshipData[ E_MISSILE ] = INVALID_OBJECT_ID;
		return 1;
	}

	foreach(new i : carepackages)
	{
		if ( g_carePackageData[ i ] [ E_PACKAGE ] == objectid )
		{
			DestroyObject( g_carePackageData[ i ] [ E_FLARE ] );
			g_carePackageData[ i ] [ E_FLARE ] = INVALID_OBJECT_ID;
			break;
		}
	}
	return 1;
}

stock SetObjectFaceCoords3D(iObject, Float: fX, Float: fY, Float: fZ, Float: fRollOffset = 0.0, Float: fPitchOffset = 0.0, Float: fYawOffset = 90.0) {
    new
        Float: fOX,
        Float: fOY,
        Float: fOZ,
        Float: fPitch
    ;
    GetObjectPos(iObject, fOX, fOY, fOZ);

    fPitch = floatsqroot(floatpower(fX - fOX, 2.0) + floatpower(fY - fOY, 2.0));
    fPitch = floatabs(atan2(fPitch, fZ - fOZ));

    fZ = atan2(fY - fOY, fX - fOX);

    SetObjectRot(iObject, fRollOffset, fPitch + fPitchOffset, fZ + fYawOffset);
}

public OnPlayerUpdate( playerid )
{
	static
		Float: X, 	Float: Y, 	Float: Z,
	    keys, ud, lr, iDrunkLevel, iSurfing
	;
	GetPlayerKeys( playerid, keys, ud, lr );

    p_LastAnimIndex[ playerid ] = GetPlayerAnimationIndex( playerid );

	#pragma unused ud
	#pragma unused lr

	p_AFKTimestamp[ playerid ] = GetTickCount( );

	if ( IsPlayerInMultiplayer( playerid ) )
	{
		if ( p_EquippedWeapon{ playerid } != GetPlayerWeapon( playerid ) ) p_EquippedWeapon{ playerid } = GetPlayerWeapon( playerid );

		if ( !( keys & KEY_AIM ) && p_Aiming{ playerid } )
		{
			p_Aiming{ playerid } = false;
	 		SetPlayerDrunkLevel( playerid, 0 );
		}
	}

    // PlayerBugger.cs
	iSurfing = GetPlayerSurfingObjectID( playerid );
	if ( iSurfing == p_ThrowingkObject[ playerid ] && iSurfing != INVALID_OBJECT_ID ) {
		SendServerMessage( playerid, "You're flying with a tomahawk, let me put you back!" );
		SetPlayerPos( playerid, p_SurfingTomahawkX[ playerid ], p_SurfingTomahawkY[ playerid ], p_SurfingTomahawkZ[ playerid ] );
	} else {
		GetPlayerPos( playerid, X, Y, Z );
	    p_SurfingTomahawkX[ playerid ] = X;
	    p_SurfingTomahawkY[ playerid ] = Y;
	    p_SurfingTomahawkZ[ playerid ] = Z;
	}

	#if CUSTOM_SHOOTING == true
	if ( IsPlayerInZombies( playerid ) )
	{
		if ( !g_zm_gameData[ E_GAME_ENDED ] && Iter_Count(zm_players) != 0 && IsPlayerSpawned( playerid ) )
		{
		    static
				target, zID;

			if ( ( target = GetPlayerTargetPlayer( playerid ) ) != INVALID_PLAYER_ID )
			{
			    if ( IsPlayerNPC( target ) && IsPlayerConnected( target ) )
			    {
					GetPlayerKeys( playerid, keys, ud, lr );

					if ( !( keys & KEY_SPRINT ) && ( keys & KEY_FIRE ) && GetPlayerWeaponState( playerid ) != WEAPONSTATE_RELOADING && GetPlayerWeaponState( playerid ) != WEAPONSTATE_NO_BULLETS )
					{
						zID = GetZombieIDFromNPC( target );
				        if ( !FCNPC_IsDead( target ) && IsPlayerFacingPlayer( playerid, target, 135.0 ) )
				        {
				        	new weaponid = GetPlayerWeapon( playerid );
				        	new Float: damage = GetWeaponDamageFromDistance( weaponid, GetDistanceBetweenPlayers( target, playerid ) );

	 						updatePlayerHitmarker( target, playerid, damage );

							g_zombieData[ zID ] [ E_HEALTH ] -= damage;
							if ( g_zombieData[ zID ] [ E_HEALTH ] < 1.0 ) {
								SetPVarInt( target, "killerid", playerid );
								SetPVarInt( target, "weaponid", weaponid );
								FCNPC_Kill( target );
							}
						}
					}
				}
			}
		}
	}
	#endif

    // FPS Counter
    iDrunkLevel = GetPlayerDrunkLevel( playerid );
    if ( iDrunkLevel < 100 ) SetPlayerDrunkLevel( playerid, 2000 );
   	else
   	{
        if ( p_FPS_DrunkLevel[ playerid ] != iDrunkLevel ) {
            new iFPS = p_FPS_DrunkLevel[ playerid ] - iDrunkLevel;

            if ( ( iFPS > 0 ) && ( iFPS < 200 ) )
                p_FPS[ playerid ] = iFPS;

            p_FPS_DrunkLevel[ playerid ] = iDrunkLevel;
        }
    }

    formatFPSCounter( playerid );
    return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	new
		keys, ud, lr;
	GetPlayerKeys( playerid, keys, ud, lr );

	// Simple. But effective. Anti-Shooting Hacks.
	if ( !( keys & KEY_FIRE )  ) {
		return 0;
	}

	if ( hittype == BULLET_HIT_TYPE_PLAYER && ( ( fX >= 10.0 || fX <= -10.0 ) || ( fY >= 10.0 || fY <= -10.0 ) || ( fZ >= 10.0 || fZ <= -10.0 ) ) ) {
		return 0;
	}

	// Invulnerbility at its finest
	if ( hittype == BULLET_HIT_TYPE_PLAYER ) {
		if ( IsPlayerConnected( hitid ) && !IsPlayerNPC( hitid ) ) {
			if ( p_Team[ hitid ] == p_Team[ playerid ] )
				return GameTextForPlayer( playerid, "~r~Don't attack your teammates!", 1000, 4 ), 0;

			if ( p_AntiSpawnKillEnabled{ hitid } || IsPlayerAdminOnDuty( hitid ) || IsPlayerAdminOnDuty( playerid ) )
				return 0;

			if ( IsPlayerInMultiplayer( playerid ) && IsPlayerInZombies( hitid ) || IsPlayerInMultiplayer( hitid ) && IsPlayerInZombies( playerid ) )
				return 0;
		}
 	}
	return 1;
}

public FCNPC_OnTakeDamage( npcid, damagerid, weaponid, bodypart, Float: health_loss )
{
	#if CUSTOM_SHOOTING == false
	if ( IsPlayerInZombies( damagerid ) )
	{
		if ( !g_zm_gameData[ E_GAME_ENDED ] && IsPlayerSpawned( damagerid ) )
		{
		    if ( IsPlayerConnected( npcid ) )
		    {
		        if ( !FCNPC_IsDead( npcid ) )
		        {
					new
						zID = GetZombieIDFromNPC( npcid );

					health_loss *= 2; // Multiply that damage son.

					if ( bodypart == 9 ) health_loss *= 2;

					updatePlayerHitmarker( npcid, damagerid, health_loss );
					if ( ( g_zombieData[ zID ] [ E_HEALTH ] -= health_loss ) < 1.0 ) {
						SetPVarInt( npcid, "killerid", damagerid );
						SetPVarInt( npcid, "weaponid", weaponid );
						FCNPC_Kill( npcid );
					}
				}
			}
		}
	}
	#endif
	return 1;
}

public OnPlayerTakePlayerDamage( playerid, issuerid, &Float: amount, weaponid, bodypart )
{
	if ( weaponid != 54 && weaponid != 53 && !p_AntiSpawnKillEnabled{ playerid } && !p_AdminOnDuty{ playerid } )
	{
		p_TakenDamage[ playerid ] = GetTickCount( ) + 1250; // Fake-kill detect

		if ( p_Team[ playerid ] != p_Team[ issuerid ] && !p_AntiSpawnKillEnabled{ playerid } && !IsPlayerAdminOnDuty( playerid ) && !IsPlayerAdminOnDuty( issuerid ) )
		{
	    	if ( getPlayerFirstPerk( playerid ) == PERK_STOPPING_POWER )
	    		amount *= 1.125;

	 		if ( getPlayerSecondPerk( playerid ) == PERK_SONIC_BOOM && weaponid == 36 || weaponid == 16 )
	 			amount *= 2;

	 		if ( weaponid == WEAPON_SNIPER && bodypart == 9 )
	 			amount *= 3;

	 		updatePlayerHitmarker( playerid, issuerid, amount );
		 	return 1;
		}
	}
	return 0;
}

stock updatePlayerHitmarker( playerid, issuerid, Float: amount )
{
	if ( g_userData[ issuerid ] [ E_HITMARKER ] )
	{
		static
			string[ 65 ];

		if ( IsPlayerNPC( playerid ) )
		{
			if ( strmatch( ReturnPlayerName( playerid ), "Helicopter" ) ) return;
			format( string, sizeof( string ), "~r~Damage: %0.2f HP~n~~w~Player: %s(%d)", amount, GetZombieName( GetZombieIDFromNPC( playerid ) ), playerid );
		}
		else format( string, sizeof( string ), "~r~Damage: %0.2f HP~n~~w~Player: %s(%d)", amount, ReturnPlayerName( playerid ), playerid );

	    KillTimer( p_DamageTDTimer[ issuerid ] );
	    p_DamageTDTimer[ issuerid ] = 0xFFFF;
		PlayerPlaySound( issuerid, g_userData[ issuerid ] [ E_HIT_SOUND ], 0.0, 0.0, 0.0 );
		TextDrawSetString( p_DamageTD[ issuerid ], string );
		TextDrawShowForPlayer( issuerid, p_DamageTD[ issuerid ] );
		p_DamageTDTimer[ issuerid ] = SetTimerEx( "hidedamagetd_Timer", 3000, false, "d", issuerid );
	}
}

class hidedamagetd_Timer( playerid )
	return TextDrawHideForPlayer( playerid, p_DamageTD[ playerid ] );

public OnTwitterHTTPResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 ) //Did the request succeed?
 		ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{00CCFF}@IrresistibleDev"COL_WHITE" - Twitter", data, "Okay", "" );
	else
		ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{00CCFF}@IrresistibleDev"COL_WHITE" - Twitter", ""COL_WHITE"An error has occurred, try again later.", "Okay", "" );
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

thread OnPlayerRegister( playerid )
{
	g_userData[ playerid ] [ E_ID ]         = cache_insert_id( );
	return 1;
}

thread OnPlayerLogin( playerid, password[ ] )
{
	new
	    rows, fields, Field[ 30 ],
	    szSalt[ 17 ],
	    szPassword[ 129 ],
	    szHashed[ 129 ]
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
		cache_get_field_content( 0,  "SALT", szSalt );
		cache_get_field_content( 0,  "PASSWORD", szPassword );

		cencrypt( szHashed, sizeof( szHashed ), password, szSalt );

		if ( strmatch( szHashed, szPassword ) )
		{
			cache_get_field_content( 0,  "ID", Field );
			g_userData[ playerid ] [ E_ID ] = strval( Field );

			cache_get_field_content( 0,  "SCORE", Field );
			SetPlayerScore( playerid, strval( Field ) );

			cache_get_field_content( 0,  "KILLS", Field );
			g_userData[ playerid ] [ E_KILLS ] = strval( Field );

			cache_get_field_content( 0,  "DEATHS", Field );
			g_userData[ playerid ] [ E_DEATHS ] = strval( Field );

			cache_get_field_content( 0,  "ADMIN", Field );
			g_userData[ playerid ] [ E_ADMIN ] = strval( Field );

			cache_get_field_content( 0,  "XP", Field );
			g_userData[ playerid ] [ E_XP ] = strval( Field );

			cache_get_field_content( 0,  "RANK", Field );
			g_userData[ playerid ] [ E_RANK ] = strval( Field );

			cache_get_field_content( 0,  "PRESTIGE", Field );
			g_userData[ playerid ] [ E_PRESTIGE ] = strval( Field );

			cache_get_field_content( 0,  "PRIMARY1", Field );
			g_userData[ playerid ] [ E_PRIMARY1 ] = strval( Field );

			cache_get_field_content( 0,  "PRIMARY2", Field );
			g_userData[ playerid ] [ E_PRIMARY2 ] = strval( Field );

			cache_get_field_content( 0,  "PRIMARY3", Field );
			g_userData[ playerid ] [ E_PRIMARY3 ] = strval( Field );

			cache_get_field_content( 0,  "SECONDARY1", Field );
			g_userData[ playerid ] [ E_SECONDARY1 ] = strval( Field );

			cache_get_field_content( 0,  "SECONDARY2", Field );
			g_userData[ playerid ] [ E_SECONDARY2 ] = strval( Field );

			cache_get_field_content( 0,  "SECONDARY3", Field );
			g_userData[ playerid ] [ E_SECONDARY3 ] = strval( Field );

			cache_get_field_content( 0,  "PERK_ONE1", Field );
			g_userData[ playerid ] [ E_PERK_ONE ] [ 0 ] = strval( Field );

			cache_get_field_content( 0,  "PERK_ONE2", Field );
			g_userData[ playerid ] [ E_PERK_ONE ] [ 1 ] = strval( Field );

			cache_get_field_content( 0,  "PERK_ONE3", Field );
			g_userData[ playerid ] [ E_PERK_ONE ] [ 2 ] = strval( Field );

			cache_get_field_content( 0,  "PERK_TWO1", Field );
			g_userData[ playerid ] [ E_PERK_TWO ] [ 0 ] = strval( Field );

			cache_get_field_content( 0,  "PERK_TWO2", Field );
			g_userData[ playerid ] [ E_PERK_TWO ] [ 1 ] = strval( Field );

			cache_get_field_content( 0,  "PERK_TWO3", Field );
			g_userData[ playerid ] [ E_PERK_TWO ] [ 2 ] = strval( Field );

			cache_get_field_content( 0,  "SPECIAL1", Field );
			g_userData[ playerid ] [ E_SPECIAL ] [ 0 ] = strval( Field );

			cache_get_field_content( 0,  "SPECIAL2", Field );
			g_userData[ playerid ] [ E_SPECIAL ] [ 1 ] = strval( Field );

			cache_get_field_content( 0,  "SPECIAL3", Field );
			g_userData[ playerid ] [ E_SPECIAL ] [ 2 ] = strval( Field );

			cache_get_field_content( 0,  "KILLSTREAK1", Field );
			g_userData[ playerid ] [ E_KILLSTREAK1 ] = strval( Field );

			cache_get_field_content( 0,  "KILLSTREAK2", Field );
			g_userData[ playerid ] [ E_KILLSTREAK2 ] = strval( Field );

			cache_get_field_content( 0,  "KILLSTREAK3", Field );
			g_userData[ playerid ] [ E_KILLSTREAK3 ] = strval( Field );

			cache_get_field_content( 0,  "MUTE_TIME", Field );
			g_userData[ playerid ] [ E_MUTE_TIME ] = strval( Field );

			cache_get_field_content( 0,  "HITMARKER", Field );
			g_userData[ playerid ] [ E_HITMARKER ] = strval( Field );

			cache_get_field_content( 0,  "HIT_SOUND", Field );
			g_userData[ playerid ] [ E_HIT_SOUND ] = strval( Field );

			cache_get_field_content( 0,  "UPTIME", Field );
			g_userData[ playerid ] [ E_UPTIME ] = strval( Field );

			cache_get_field_content( 0,  "CASH", Field );
			SetPlayerCash( playerid, strval( Field ) );

			cache_get_field_content( 0,  "WINS", Field );
			g_userData[ playerid ] [ E_VICTORIES ] = strval( Field );

			cache_get_field_content( 0,  "LOSES", Field );
			g_userData[ playerid ] [ E_LOSSES ] = strval( Field );

			cache_get_field_content( 0,  "ZM_RANK", Field );
			g_userData[ playerid ] [ E_ZM_RANK ] = strval( Field );

			cache_get_field_content( 0,  "ZM_XP", Field );
			g_userData[ playerid ] [ E_ZM_XP ] = strval( Field );

			cache_get_field_content( 0,  "ZM_KILLS", Field );
			g_userData[ playerid ] [ E_ZM_KILLS ] = strval( Field );

			cache_get_field_content( 0,  "ZM_DEATHS", Field );
			g_userData[ playerid ] [ E_ZM_DEATHS ] = strval( Field );

			cache_get_field_content( 0,  "VIP", Field );
			g_userData[ playerid ] [ E_VIP_LEVEL ] = strval( Field );

			cache_get_field_content( 0,  "VIP_EXPIRE", Field );
			g_userData[ playerid ] [ E_VIP_EXPIRE ] = strval( Field );

			cache_get_field_content( 0,  "DOUBLE_XP", Field );
			g_userData[ playerid ] [ E_DOUBLE_XP ] = strval( Field );

			cache_get_field_content( 0,  "LIVES", Field );
			g_userData[ playerid ] [ E_LIVES ] = strval( Field );

			cache_get_field_content( 0,  "MEDKITS", Field );
			g_userData[ playerid ] [ E_MEDKIT ] = strval( Field );

			cache_get_field_content( 0,  "SKIN", Field );
			g_userData[ playerid ] [ E_SKIN ] = strval( Field );

			cache_get_field_content( 0,  "WEAPONS", Field );
			sscanf( Field, "p<|>e<dd>", g_userData[ playerid ] [ E_WEAPONS ] );

			cache_get_field_content( 0,  "ZM_PRESTIGE", Field );
			g_userData[ playerid ] [ E_ZM_PRESTIGE ] = strval( Field );

			cache_get_field_content( 0,  "ZM_SKIN", Field );
			g_userData[ playerid ] [ E_ZM_SKIN ] = strval( Field );

			cache_get_field_content( 0, "CLASSNAME1", g_userData[ playerid ] [ E_CLASS1 ], dbHandle, 32 );
			cache_get_field_content( 0, "CLASSNAME2", g_userData[ playerid ] [ E_CLASS2 ], dbHandle, 32 );
			cache_get_field_content( 0, "CLASSNAME3", g_userData[ playerid ] [ E_CLASS3 ], dbHandle, 32 );

	        p_PlayerLogged{ playerid } = true;
			g_userData[ playerid ] [ E_LAST_LOGGED ] = gettime( );
	        ShowGameMenu( playerid );

	    	if ( g_userData[ playerid ] [ E_MUTE_TIME ] > 0 ) p_Muted{ playerid } = true; // Save muting :X

	      	SendServerMessage( playerid, "You have "COL_GREEN"successfully{FFFFFF} logged in!" );
		}
	    else
	    {
	        p_IncorrectLogins{ playerid } ++;
	        format( szBigString, sizeof(szBigString), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_RED"Wrong password! Try again! [%d/3]\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ), p_IncorrectLogins{ playerid } );
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{FFFFFF}Account - Login", szBigString, "Login", "Leave");
			if ( p_IncorrectLogins{ playerid } >= 3 ) {
			    p_IncorrectLogins{ playerid } = 0;
				SendServerMessage( playerid, "You have been kicked for too many incorrect login attempts." );
				KickPlayerTimed( playerid );
			}
	    }
    }
    else
	{
		printf( "[Error]: Account Bugged (%s)", ReturnPlayerName( playerid ) );
		Kick( playerid );
		return 1;
	}
	return 1;
}


public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	static buffer[ 129 ], szBigQuery[ 500 ];

    if ( response == 1 ) PlayerPlaySound( playerid, 1083, 0.0, 0.0, 0.0 ); // Confirmation sound
    else 				PlayerPlaySound( playerid, 1084, 0.0, 0.0, 0.0 ); // Cancellation sound

	if ( dialogid == DIALOG_LOGIN )
	{
        if (response)
        {
			format( szBigQuery, sizeof( szBigQuery ), "SELECT * FROM `COD` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( ReturnPlayerName( playerid ) ) );
       		mysql_function_query( dbHandle, szBigQuery, true, "OnPlayerLogin", "ds", playerid, inputtext );
        }
        else return Kick( playerid );
    }
	if ( dialogid == DIALOG_REGISTER )
	{
	    if ( response )
	    {
			if ( strlen( inputtext ) > 24 || strlen( inputtext ) < 3 )
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome "COL_BLUE"%s(%d){FFFFFF} to the server, you're "COL_RED"not{FFFFFF} registered\n\nPlease log in by inputting your password.\n\n"COL_RED"Wrong{FFFFFF} password, try again!\n\nYour password length must be from "COL_BLUE"3 - 24{FFFFFF} characters!", ReturnPlayerName( playerid ), playerid );
                ShowPlayerDialog( playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Register System", szBigString, "Register", "Leave" );
            }
            else
            {
            	new
            		szSalt[ 17 ];

            	randomString( szSalt, 16 );
				cencrypt( buffer, sizeof( buffer ), inputtext, szSalt );

                strmid( szBigQuery, "INSERT INTO `COD`(NAME,PASSWORD,SALT,PRIMARY1,PRIMARY2,PRIMARY3,SECONDARY1,SECONDARY2,SECONDARY3,KILLSTREAK1,KILLSTREAK2,KILLSTREAK3,LAST_LOGGED)", 0, cellmax );
                format( szBigQuery, sizeof( szBigQuery ), "%s VALUES ('%s','%s','%s',29,29,29,23,23,23,0,1,3,%d)", szBigQuery, mysql_escape( ReturnPlayerName( playerid ) ), buffer, mysql_escape( szSalt ), gettime( ) );
				mysql_function_query( dbHandle, szBigQuery, true, "OnPlayerRegister", "d", playerid );

                p_PlayerLogged{ playerid } = true;
				g_userData[ playerid ] [ E_KILLS ] 		= 1;
				g_userData[ playerid ] [ E_DEATHS ] 	= 1;
				g_userData[ playerid ] [ E_ADMIN ] 		= 0;
				g_userData[ playerid ] [ E_XP ] 		= 0;
				g_userData[ playerid ] [ E_RANK ] 		= 0;
				g_userData[ playerid ] [ E_PRESTIGE ] 	= 0;
				g_userData[ playerid ] [ E_PRIMARY1 ] 	= 29;
				g_userData[ playerid ] [ E_PRIMARY2 ] 	= 29;
				g_userData[ playerid ] [ E_PRIMARY3 ] 	= 29;
				g_userData[ playerid ] [ E_SECONDARY1 ] = 23;
				g_userData[ playerid ] [ E_SECONDARY2 ] = 23;
				g_userData[ playerid ] [ E_SECONDARY3 ] = 23;
				g_userData[ playerid ] [ E_PERK_ONE ] [ 0 ] = 0;
				g_userData[ playerid ] [ E_PERK_ONE ] [ 1 ] = 0;
				g_userData[ playerid ] [ E_PERK_ONE ] [ 2 ] = 0;
				g_userData[ playerid ] [ E_PERK_TWO ] [ 0 ] = 0;
				g_userData[ playerid ] [ E_PERK_TWO ] [ 1 ] = 0;
				g_userData[ playerid ] [ E_PERK_TWO ] [ 2 ] = 0;
				g_userData[ playerid ] [ E_SPECIAL ] [ 0 ] = 0;
				g_userData[ playerid ] [ E_SPECIAL ] [ 1 ] = 0;
				g_userData[ playerid ] [ E_SPECIAL ] [ 2 ] = 0;
				g_userData[ playerid ] [ E_KILLSTREAK1 ]= 0;
				g_userData[ playerid ] [ E_KILLSTREAK2 ]= 1;
				g_userData[ playerid ] [ E_KILLSTREAK3 ]= 3;

				format( g_userData[ playerid ] [ E_CLASS1 ], 32, "Custom Class 1" );
				format( g_userData[ playerid ] [ E_CLASS2 ], 32, "Custom Class 2" );
				format( g_userData[ playerid ] [ E_CLASS3 ], 32, "Custom Class 3" );
                ShowGameMenu( playerid );
                SendClientMessage( playerid, -1, "You have "COL_GREEN"successfully{FFFFFF} registered! You have been automatically logged in!" );
            }
		}
        else return Kick( playerid );
	}
	if ( dialogid == DIALOG_MAIN_MENU )
	{
	    if (response)
		{
	    	switch (listitem)
			{
	            case 0:	ShowPlayerDialog( playerid, DIALOG_TEAM_MENU, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Select Team", "{00A8FF}Tropas\n{F31B1D}OP40\n{FFFFFF}Auto Assign", "Select", "Back" );
				case 1: ShowCreateaClassMenu( playerid );
				case 2:
				{
					if ( g_userData[ playerid ] [ E_RANK ] < 50 )
						return SendError( playerid, "You must be rank 50 to enter prestige mode." ), ShowMainMenu( playerid ), 1;

					ShowPlayerDialog( playerid, DIALOG_MODIFY_PRESTIGE, DIALOG_STYLE_MSGBOX, ""#DIALOG_TITLE" - Prestige Mode", "{FFFFFF}Are you sure you want to prestige?\n\nPrestiging will result in a rank and XP loss, as well as all classes being reset.\nHowever, a prestige point is added which can be used to redeem and unlock class slots.", "Commit", "Back" );
				}
	        }
	    }
	    else ShowGameMenu( playerid );
	}
	if ( dialogid == DIALOG_ZOMBIE_MENU )
	{
		if ( response )
		{
			switch( listitem )
			{
				case 0:
				{
		            p_Team[ playerid ] = TEAM_SURVIVORS;
					SetPlayerColor( playerid, ReturnPlayerTeamColor( playerid ) );
					//SetPlayerTeam( playerid, TEAM_SURVIVORS );
		      		SpawnPlayer( playerid );
				}
				case 1: ShowPlayerShopMenu( playerid );
				case 2: ShowPlayerDialog( playerid, DIALOG_ZPRESTIGE_ZONE, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Main Menu", "Change Spawning Skin", "Select", "Back" );
				case 3:
				{
					if ( g_userData[ playerid ] [ E_ZM_RANK ] < 30 )
						return SendError( playerid, "You must be rank 30 to enter prestige mode." ), ShowMainMenu( playerid ), 1;

					ShowPlayerDialog( playerid, DIALOG_MODIFY_ZMPRESTIGE, DIALOG_STYLE_MSGBOX, ""#DIALOG_TITLE" - Prestige Mode", "{FFFFFF}Are you sure you want to prestige?\n\nPrestiging will result in a rank and XP loss.\nHowever, a prestige point is added which can be used to unlock additional features.", "Commit", "Back" );
				}
			}
		}
		else ShowGameMenu( playerid );
	}
	if ( dialogid == DIALOG_MODIFY_ZMPRESTIGE )
	{
		if ( response )
		{
			g_userData[ playerid ] [ E_ZM_RANK ] = 0;
			g_userData[ playerid ] [ E_ZM_XP ] = 0;
			g_userData[ playerid ] [ E_ZM_PRESTIGE ] ++;
			SendServerMessage( playerid, "You have earned a prestige point. Congratulations." );
			ShowMainMenu( playerid );
		}
		else ShowMainMenu( playerid );
	}
	if ( dialogid == DIALOG_ZPRESTIGE_ZONE )
	{
		if ( response )
		{
			switch( listitem )
			{
				case 0:
				{
					if ( g_userData[ playerid ] [ E_ZM_PRESTIGE ] < 1 )
						return SendError( playerid, "You must be at least prestige 1 to use this feature." ), ShowPlayerDialog( playerid, DIALOG_ZPRESTIGE_ZONE, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Main Menu", "Change Spawning Skin", "Select", "Back" ), 1;

					ShowPlayerDialog( playerid, DIALOG_MODIFY_ZMSKIN, DIALOG_STYLE_INPUT, ""#DIALOG_TITLE" - Prestige Mode", "{FFFFFF}What skin ID would you like to use for your zombie spawning skin? "COL_GREY"Type disable to disable.", "Set", "Back" );
				}
			}
		}
		else ShowMainMenu( playerid );
	}
	if ( dialogid == DIALOG_MODIFY_ZMSKIN )
	{
		if ( response )
		{
			new
				skin;

			if ( strmatch( inputtext, "disable" ) )
			{
				SendServerMessage( playerid, "You have disabled the custom skin feature for the zombies mode." );
				g_userData[ playerid ] [ E_ZM_SKIN ] = -1;
			}
			else if ( sscanf( inputtext, "d", skin ) ) return SendError( playerid, "You must enter an integer." ), ShowPlayerDialog( playerid, DIALOG_MODIFY_ZMSKIN, DIALOG_STYLE_MSGBOX, ""#DIALOG_TITLE" - Prestige Mode", "{FFFFFF}What skin ID would you like to use for your zombie spawning skin? "COL_GREY"Type disable to disable.", "Set", "Back" );
			else if ( !IsValidSkin( skin ) ) return SendError( playerid, "This is an invalid skin ID." ), ShowPlayerDialog( playerid, DIALOG_MODIFY_ZMSKIN, DIALOG_STYLE_MSGBOX, ""#DIALOG_TITLE" - Prestige Mode", "{FFFFFF}What skin ID would you like to use for your zombie spawning skin? "COL_GREY"Type disable to disable.", "Set", "Back" );
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have your skin id to %d for the zombies mode.", skin );
				g_userData[ playerid ] [ E_ZM_SKIN ] = skin;
			}
		}
		ShowPlayerDialog( playerid, DIALOG_ZPRESTIGE_ZONE, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Main Menu", "Change Spawning Skin", "Select", "Back" );
	}
    if ( dialogid == DIALOG_SHOP_WEAPONS )
    {
    	if ( !response )
    	{
    		if ( !IsPlayerSpawned( playerid ) ) ShowMainMenu( playerid );
    		return 1;
    	}

    	new Float: discountedPrice = float( g_shopData[ listitem ] [ E_PRICE ] );

    	switch( g_userData[ playerid ] [ E_VIP_LEVEL ] )
    	{
    		case 3: discountedPrice *= 0.50;
    		case 2: discountedPrice *= 0.75;
    		case 1: discountedPrice *= 0.90;
    	}

    	new price = floatround( discountedPrice );

        if ( GetPlayerCash( playerid ) < price )
        {
            SendClientMessageFormatted( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You don't have enough money for this item (%s).", ConvertPrice( price ) );
            return ShowPlayerShopMenu( playerid );
        }

        if ( g_userData[ playerid ] [ E_ZM_RANK ] < g_shopData[ listitem ] [ E_RANK ] )
        {
            SendClientMessageFormatted( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You must have at least rank %d to purchase this weapon.", g_shopData[ listitem ] [ E_RANK ] );
            return ShowPlayerShopMenu( playerid );
        }

        GivePlayerCash( playerid, -( price ) );

        if ( !strcmp( g_shopData[ listitem ] [ E_NAME ], "Armour" ) )
        {
        	SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have purchased an armour vest." );
        	p_BoughtArmour{ playerid } = true;
        	SetPlayerArmour( playerid, 100.0 );
        	ShowPlayerShopMenu( playerid );
            return 1;
        }
        if ( !strcmp( g_shopData[ listitem ] [ E_NAME ], "Dual Five-Seven" ) ) // Just skill level.
        {
        	if ( p_BoughtDualPistols{ playerid } ) SendError( playerid, "You already have this purchased." );
        	else
        	{
		        SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have upgraded your 9mm Pistols into a dual wield." );
		        p_BoughtDualPistols{ playerid } = true;
		        SetPlayerSkillLevel( playerid, WEAPONSKILL_PISTOL, 999 );
        	}
        	ShowPlayerShopMenu( playerid );
        	return 1;
        }
        if ( !strcmp( g_shopData[ listitem ] [ E_NAME ], "Medikit" ) )
        {
        	if ( g_userData[ playerid ] [ E_MEDKIT ] ) SendError( playerid, "You can only buy a maximum of 5 medkits." );
        	else {
	        	SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have purchased a medikit." );
				g_userData[ playerid ] [ E_MEDKIT ] ++;
	        	ShowPlayerShopMenu( playerid );
        	}
            return 1;
        }

        new slot = GetWeaponSlot( g_shopData[ listitem ] [ E_WEPID ] );
        p_PreorderWeapons[ playerid ] [ slot ] [ 0 ]  = g_shopData[ listitem ] [ E_WEPID ];
        p_PreorderWeapons[ playerid ] [ slot ] [ 1 ] += g_shopData[ listitem ] [ E_AMMO ];

        GivePlayerWeapon( playerid, g_shopData[ listitem ] [ E_WEPID ], g_shopData[ listitem ] [ E_AMMO ] );

        SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have purchased a %s(%d) for "COL_GOLD"%s"COL_WHITE".", g_shopData[ listitem ] [ E_NAME ], g_shopData[ listitem ] [ E_AMMO ], ConvertPrice( price ) );
        ShowPlayerShopMenu( playerid );
    }
	if ( dialogid == DIALOG_MODIFY_ACCOUNT )
	{
		if ( response )
		{
		    switch( listitem )
		    {
		    	case 0:
		    	{
					p_ViewingStats[ playerid ] = playerid;
					ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Statistics", "General Statistics\nMultiplayer Statistics\nZombie Statistics", "Select", "Back" );
		    	}
				case 1: ShowPlayerDialog( playerid, DIALOG_MODIFY_PASSWORD, DIALOG_STYLE_INPUT, ""#DIALOG_TITLE" - Change password", "{FFFFFF}Type below what you would like to change\nyour password to, statistics will not reset after this.", "Change", "Back" );
				case 2: ShowPlayerDialog( playerid, DIALOG_MODIFY_DEL_STATS, DIALOG_STYLE_MSGBOX, ""#DIALOG_TITLE" - Reset Statistics", "{FFFFFF}Are you sure you want to reset your statistics?\n\nThis change can not be reverted. Please consider deeply.", "Reset", "Back" );
				case 3: ShowSoundsMenu( playerid );
			}
		}
		else ShowGameMenu( playerid );
	}
	if ( dialogid == DIALOG_MODIFY_HITMARKER )
	{
		if ( response )
		{
			switch( listitem )
			{
				case 0:
				{
					g_userData[ playerid ] [ E_HIT_SOUND ] = g_HitmarkerSounds[ 0 ] [ E_SOUND_ID ];
					g_userData[ playerid ] [ E_HITMARKER ] = g_userData[ playerid ] [ E_HITMARKER ] == 1 ? 0 : 1;
					SendServerMessage( playerid, "You have changed your Hitmarker status." );
					ShowSoundsMenu( playerid );
				}
				case 1: ShowSoundsList( playerid );
			}
		}
		else ShowPlayerDialog( playerid, DIALOG_MODIFY_ACCOUNT, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Account Settings", "View Statistics\n{F2F2F2}Change Password\n{E5E5E5}Reset Statistics\n{C0C0C0}Hitmarker Options", "Select", "Back" );
	}
	if ( dialogid == DIALOG_MODIFY_HM_SOUND )
	{
		if ( response )
		{
			g_userData[ playerid ] [ E_HIT_SOUND ] = g_HitmarkerSounds[ listitem ] [ E_SOUND_ID ];
			SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your hitmarker sound to "COL_GREY"%s"COL_WHITE".", g_HitmarkerSounds[ listitem ] [ E_NAME ] );
			ShowSoundsMenu( playerid );
		}
		else ShowSoundsMenu( playerid );
	}
	if ( dialogid == DIALOG_MODIFY_PASSWORD )
	{
	    if ( response )
	    {
	        if ( !strlen( inputtext ) ) return ShowPlayerDialog( playerid, DIALOG_MODIFY_PASSWORD, DIALOG_STYLE_INPUT, ""#DIALOG_TITLE" - Change password", "{FFFFFF}Type below what you would like to change\nyour password to, Statistics will not reset after this..\n\n"COL_RED"Please enter a valid password.", "Change", "Back" );
            else if ( strlen( inputtext ) < 3 || strlen( inputtext ) > 20 ) return ShowPlayerDialog( playerid, DIALOG_MODIFY_PASSWORD, DIALOG_STYLE_INPUT, ""#DIALOG_TITLE" - Change password", "{FFFFFF}Type below what you would like to change\nyour password to, Statistics will not reset after this..\n\n"COL_RED"Password lengths must be from 3 to 20 characters.", "Change", "Back" );
            else
			{
          		ChangePassword( playerid, inputtext );
				SendServerMessage( playerid, "Your account password has been changed and saved." );
	         	ShowPlayerDialog( playerid, DIALOG_MODIFY_ACCOUNT, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Account Settings", "View Statistics\n{F2F2F2}Change Password\n{E5E5E5}Reset Statistics\n{C0C0C0}Hitmarker Options", "Select", "Back" );
			}
	    }
		else ShowPlayerDialog( playerid, DIALOG_MODIFY_ACCOUNT, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Account Settings", "View Statistics\n{F2F2F2}Change Password\n{E5E5E5}Reset Statistics\n{C0C0C0}Hitmarker Options", "Select", "Back" );
	}
	if ( dialogid == DIALOG_MODIFY_PRESTIGE )
	{
		if ( response )
		{
			g_userData[ playerid ] [ E_PRESTIGE ] 	++;
			g_userData[ playerid ] [ E_XP ] 		= 0;
			g_userData[ playerid ] [ E_RANK ] 		= 0;
			g_userData[ playerid ] [ E_PRIMARY1 ] 	= 29;
			g_userData[ playerid ] [ E_PRIMARY2 ] 	= 29;
			g_userData[ playerid ] [ E_PRIMARY3 ] 	= 29;
			g_userData[ playerid ] [ E_SECONDARY1 ] = 23;
			g_userData[ playerid ] [ E_SECONDARY2 ] = 23;
			g_userData[ playerid ] [ E_SECONDARY3 ] = 23;
			g_userData[ playerid ] [ E_PERK_ONE ] [ 0 ] = 0;
			g_userData[ playerid ] [ E_PERK_ONE ] [ 1 ] = 0;
			g_userData[ playerid ] [ E_PERK_ONE ] [ 2 ] = 0;
			g_userData[ playerid ] [ E_PERK_TWO ] [ 0 ] = 0;
			g_userData[ playerid ] [ E_PERK_TWO ] [ 1 ] = 0;
			g_userData[ playerid ] [ E_PERK_TWO ] [ 2 ] = 0;
			g_userData[ playerid ] [ E_SPECIAL ] [ 0 ] = 0;
			g_userData[ playerid ] [ E_SPECIAL ] [ 1 ] = 0;
			g_userData[ playerid ] [ E_SPECIAL ] [ 2 ] = 0;
			g_userData[ playerid ] [ E_KILLSTREAK1 ]= 0;
			g_userData[ playerid ] [ E_KILLSTREAK2 ]= 1;
			g_userData[ playerid ] [ E_KILLSTREAK3 ]= 3;
			SendServerMessage( playerid, "You have earned a prestige point. Congratulations." );
			ShowMainMenu( playerid );
		}
		else ShowMainMenu( playerid );
	}
	if ( dialogid == DIALOG_MODIFY_DEL_STATS )
	{
	    if ( response )
		{
		    SetPlayerScore( playerid, 0 );
			g_userData[ playerid ] [ E_KILLS ] 		= 0;
			g_userData[ playerid ] [ E_DEATHS ] 	= 0;
			g_userData[ playerid ] [ E_ADMIN ] 		= 0;
			g_userData[ playerid ] [ E_XP ] 		= 0;
			g_userData[ playerid ] [ E_RANK ] 		= 0;
			g_userData[ playerid ] [ E_PRESTIGE ] 	= 0;
			g_userData[ playerid ] [ E_PRIMARY1 ] 	= 29;
			g_userData[ playerid ] [ E_PRIMARY2 ] 	= 29;
			g_userData[ playerid ] [ E_PRIMARY3 ] 	= 29;
			g_userData[ playerid ] [ E_SECONDARY1 ] = 23;
			g_userData[ playerid ] [ E_SECONDARY2 ] = 23;
			g_userData[ playerid ] [ E_SECONDARY3 ] = 23;
			g_userData[ playerid ] [ E_PERK_ONE ] [ 0 ] = 0;
			g_userData[ playerid ] [ E_PERK_ONE ] [ 1 ] = 0;
			g_userData[ playerid ] [ E_PERK_ONE ] [ 2 ] = 0;
			g_userData[ playerid ] [ E_PERK_TWO ] [ 0 ] = 0;
			g_userData[ playerid ] [ E_PERK_TWO ] [ 1 ] = 0;
			g_userData[ playerid ] [ E_PERK_TWO ] [ 2 ] = 0;
			g_userData[ playerid ] [ E_SPECIAL ] [ 0 ] = 0;
			g_userData[ playerid ] [ E_SPECIAL ] [ 1 ] = 0;
			g_userData[ playerid ] [ E_SPECIAL ] [ 2 ] = 0;
			g_userData[ playerid ] [ E_KILLSTREAK1 ]= 0;
			g_userData[ playerid ] [ E_KILLSTREAK2 ]= 1;
			g_userData[ playerid ] [ E_KILLSTREAK3 ]= 3;
			g_userData[ playerid ] [ E_VICTORIES ] 	= 0;
			g_userData[ playerid ] [ E_LOSSES ] 	= 0;
			g_userData[ playerid ] [ E_ZM_RANK ] 	= 0;
			g_userData[ playerid ] [ E_ZM_XP ] 		= 0;
			g_userData[ playerid ] [ E_ZM_KILLS ] 	= 0;
			g_userData[ playerid ] [ E_ZM_DEATHS ] 	= 0;
			g_userData[ playerid ] [ E_ZM_PRESTIGE ]= 0;
			g_userData[ playerid ] [ E_ZM_SKIN ] 	= -1;
			SendServerMessage( playerid, "Your account has been reset." );
			ShowPlayerDialog( playerid, DIALOG_MODIFY_ACCOUNT, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Account Settings", "View Statistics\n{F2F2F2}Change Password\n{E5E5E5}Reset Statistics\n{C0C0C0}Hitmarker Options", "Select", "Back" );
		}
		else ShowPlayerDialog( playerid, DIALOG_MODIFY_ACCOUNT, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Account Settings", "View Statistics\n{F2F2F2}Change Password\n{E5E5E5}Reset Statistics\n{C0C0C0}Hitmarker Options", "Select", "Back" );
	}
 	if ( dialogid == DIALOG_TEAM_MENU )
 	{
		if ( response )
		{
			switch( listitem )
			{
			    case 0:
			    {
			        if ( g_TropasMembers > g_OP40Members )
			        {
			            ShowPlayerDialog( playerid, DIALOG_TEAM_MENU, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Select Team", "{00A8FF}Tropas\n{F31B1D}OP40\n{FFFFFF}Auto Assign", "Select", "Back" );
						SendError(playerid, "The teams are not balanced, select a different team.");
					}
			        else
			        {
			            g_TropasMembers ++;
			            p_Team[ playerid ] = TEAM_TROPAS;
			            SpawnPlayer( playerid );
	    				SetPlayerColor( playerid, ReturnPlayerTeamColor( playerid ) );
						//SetPlayerTeam( playerid, TEAM_TROPAS );
			            //SetPlayerColor( playerid, COLOR_TROPAS );
			            SendServerMessage( playerid, "You have been assigned to team {00A8FF}Tropas{FFFFFF}." );
	    				ResetMatchData( playerid );
						SetMatchData( playerid, M_ID, playerid );
			        }
			    }
			    case 1:
			    {
			        if ( g_TropasMembers < g_OP40Members )
			        {
			            ShowPlayerDialog( playerid, DIALOG_TEAM_MENU, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Select Team", "{00A8FF}Tropas\n{F31B1D}OP40\n{FFFFFF}Auto Assign", "Select", "Back" );
						SendError(playerid, "The teams are not balanced, select a different team.");
					}
			        else
			        {
			            g_OP40Members ++;
			            p_Team[ playerid ] = TEAM_OP40;
			            SpawnPlayer( playerid );
	    				SetPlayerColor( playerid, ReturnPlayerTeamColor( playerid ) );
						//SetPlayerTeam( playerid, TEAM_OP40 );
                        //SetPlayerColor( playerid, COLOR_OP40 );
	    				ResetMatchData( playerid );
			            SendServerMessage( playerid, "You have been assigned to team {F31B1D}OP40{FFFFFF}." );
						SetMatchData( playerid, M_ID, playerid );
			        }
			    }
			    case 2:
			    {
			        if ( g_TropasMembers > g_OP40Members )
			        {
           				g_OP40Members ++;
			            p_Team[ playerid ] = TEAM_OP40;
						//SetPlayerTeam( playerid, TEAM_OP40 );
                        //SetPlayerColor( playerid, COLOR_OP40 );
			            SendServerMessage( playerid, "You have been assigned to team {F31B1D}OP40{FFFFFF}." );
						SetMatchData( playerid, M_ID, playerid );
			        }
			        else if ( g_OP40Members > g_TropasMembers )
			        {
           				g_TropasMembers ++;
			            p_Team[ playerid ] = TEAM_TROPAS;
						//SetPlayerTeam( playerid, TEAM_TROPAS );
			            //SetPlayerColor( playerid, COLOR_TROPAS );
			            SendServerMessage( playerid, "You have been assigned to team {00A8FF}Tropas{FFFFFF}." );
						SetMatchData( playerid, M_ID, playerid );
			        }
			        else
			        {
			            switch( random( 2 ) )
			            {
			                case 0:
			                {
		           				g_OP40Members ++;
					            p_Team[ playerid ] = TEAM_OP40;
								//SetPlayerTeam( playerid, TEAM_OP40 );
			            		//SetPlayerColor( playerid, COLOR_OP40 );
					            SendServerMessage( playerid, "You have been assigned to team {F31B1D}OP40{FFFFFF}." );
			                }
			                case 1:
			                {
		           				g_TropasMembers ++;
					            p_Team[ playerid ] = TEAM_TROPAS;
								//SetPlayerTeam( playerid, TEAM_TROPAS );
			            		//SetPlayerColor( playerid, COLOR_TROPAS );
					            SendServerMessage( playerid, "You have been assigned to team {00A8FF}Tropas{FFFFFF}." );
			                }
			            }
			        }
					SpawnPlayer( playerid );
	    			ResetMatchData( playerid );
	    			SetPlayerColor( playerid, ReturnPlayerTeamColor( playerid ) );
					SetMatchData( playerid, M_ID, playerid );
			    }
			}
		}
		else ShowMainMenu( playerid );
	}
	if ( dialogid == DIALOG_CREATE_CLASS )
	{
        if ( response )
		{
			if ( listitem == 1 && g_userData[ playerid ] [ E_PRESTIGE ] < 1 ) {
				SendError( playerid, "This custom class slot is locked until you get Prestige 1." ), ShowCreateaClassMenu( playerid );
				return 1;
			}
			if ( listitem == 2 && g_userData[ playerid ] [ E_PRESTIGE ] < 3 ) {
				SendError( playerid, "This custom class slot is locked until you get Prestige 3." ), ShowCreateaClassMenu( playerid );
				return 1;
			}
			if ( listitem == 3 ) {
				format( szNormalString, sizeof( szNormalString ), "VIP Weapon Slot 1 (%s)\nVIP Weapon Slot 2 (%s)\nVIP Skin", ReturnWeaponName( g_userData[ playerid ] [ E_WEAPONS ] [ 0 ] ), ReturnWeaponName( g_userData[ playerid ] [ E_WEAPONS ] [ 1 ] ) );
				ShowPlayerDialog( playerid, DIALOG_CREATE_CLASS_VIP, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Create-a-Class", szNormalString, "Select", "Back" );
				return 1;
			}

			SetCustomizeClass( playerid, listitem );
            p_cac_SelectedClass[ playerid ] = listitem;
        }
        else ShowMainMenu( playerid );
    }
    if ( dialogid == DIALOG_CREATE_CLASS_VIP )
    {
    	if ( response )
    	{
    		if ( listitem == 1 && g_userData[ playerid ] [ E_VIP_LEVEL ] < 3 )
    		{
    			SendError( playerid, "You must have the Elite VIP package to use this feature." );
    			ShowCreateaClassMenu( playerid );
    			return 1;
    		}

    		switch( listitem )
    		{
    			case 0 .. 1: ShowPlayerDialog( playerid, DIALOG_CAC_VIP_WEP, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Create-a-Class", ""COL_RED"Remove Weapon On This Slot\nFive-Seven\nUSP (Silenced)\nDesert Eagle\nShotgun\nSawn-Off shotgun\nCombat Shotgun\nUzi\nMP5\nAK-47\nM14\nFMG9\nCountry Rifle\nL118A (Sniper)", "Select", "Cancel");
    			case 2:		 ShowPlayerDialog( playerid, DIALOG_CAC_VIP_SKIN, DIALOG_STYLE_INPUT, ""#DIALOG_TITLE" - Create-a-Class", ""COL_WHITE"What is the skin ID that you want to use?", "Set", "Back" );
    		}
    		SetPVarInt( playerid, "vip_class_feature", listitem );
    	}
    	else ShowCreateaClassMenu( playerid );
    }
	if ( dialogid == DIALOG_CAC_VIP_WEP )
	{
		if ( response )
		{
			if ( !listitem )
				g_userData[ playerid ] [ E_WEAPONS ] [ GetPVarInt( playerid, "vip_class_feature" ) ] = 0;
			else
				g_userData[ playerid ] [ E_WEAPONS ] [ GetPVarInt( playerid, "vip_class_feature" ) ] = 21 + listitem;

			SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have set the %s VIP weapon to %s.", GetPVarInt( playerid, "vip_class_feature" ) == 0 ? ("first") : ("second"), ReturnWeaponName( 21 + listitem ) );
		}
		format( szNormalString, sizeof( szNormalString ), "VIP Weapon Slot 1 (%s)\nVIP Weapon Slot 2 (%s)\nVIP Skin", ReturnWeaponName( g_userData[ playerid ] [ E_WEAPONS ] [ 0 ] ), ReturnWeaponName( g_userData[ playerid ] [ E_WEAPONS ] [ 1 ] ) );
		ShowPlayerDialog( playerid, DIALOG_CREATE_CLASS_VIP, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Create-a-Class", szNormalString, "Select", "Back" );
	}
	if ( dialogid == DIALOG_CAC_VIP_SKIN )
	{
		if ( response )
		{
			new
				skin;

			if ( sscanf( inputtext, "d", skin ) ) return SendError( playerid, "You must enter an integer." ), ShowPlayerDialog( playerid, DIALOG_CAC_VIP_SKIN, DIALOG_STYLE_INPUT, ""#DIALOG_TITLE" - Create-a-Class", ""COL_WHITE"What is the skin ID that you want to use?", "Set", "Back" );
			else if ( !IsValidSkin( skin ) ) return SendError( playerid, "This is an invalid skin ID." ), ShowPlayerDialog( playerid, DIALOG_CAC_VIP_SKIN, DIALOG_STYLE_INPUT, ""#DIALOG_TITLE" - Create-a-Class", ""COL_WHITE"What is the skin ID that you want to use?", "Set", "Back" );
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have set the your VIP skin id to %d.", skin );
				g_userData[ playerid ] [ E_SKIN ] = skin;
			}
		}
		format( szNormalString, sizeof( szNormalString ), "VIP Weapon Slot 1 (%s)\nVIP Weapon Slot 2 (%s)\nVIP Skin", ReturnWeaponName( g_userData[ playerid ] [ E_WEAPONS ] [ 0 ] ), ReturnWeaponName( g_userData[ playerid ] [ E_WEAPONS ] [ 1 ] ) );
		ShowPlayerDialog( playerid, DIALOG_CREATE_CLASS_VIP, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Create-a-Class", szNormalString, "Select", "Back" );
	}
    if ( dialogid == DIALOG_RENAME )
	{
        if ( response )
		{
   			if ( strlen( inputtext ) >= 32 || strlen( inputtext ) < 3 || textContainsBadTextdrawLetters( inputtext ) )
   			{
   				ShowPlayerDialog( playerid, DIALOG_RENAME, DIALOG_STYLE_INPUT, "{FFFFFF}Rename Class", ""COL_WHITE"What would you like to rename this class as?\n\n"COL_RED"The name must be within 3-24 characters and no funky symbols!", "Rename", "Cancel" );
   				return 1;
   			}

   			switch( p_cac_SelectedClass[ playerid ] )
   			{
   				case 0: format( g_userData[ playerid ] [ E_CLASS1 ], 32, "%s", inputtext );
   				case 1: format( g_userData[ playerid ] [ E_CLASS2 ], 32, "%s", inputtext );
   				case 2: format( g_userData[ playerid ] [ E_CLASS3 ], 32, "%s", inputtext );
   			}

   			TextDrawSetString( p_ClassName[ playerid ], inputtext );
        }
    }
	if ( dialogid == DIALOG_CHOOSE_CLASS )
	{
		if ( response )
		{
			ResetPlayerWeapons( playerid );
		    switch( listitem )
		    {
				case 0:
				{
				    p_SelectedGameClass[ playerid ] = 1;
			     	GivePlayerWeapon( playerid, 23, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, 30, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 1:
				{
				    p_SelectedGameClass[ playerid ] = 2;
			     	GivePlayerWeapon( playerid, 23, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, 27, getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 2:
				{
				    p_SelectedGameClass[ playerid ] = 3;
			     	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_SECONDARY1 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_PRIMARY1 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 3:
				{
				    p_SelectedGameClass[ playerid ] = 4;
			     	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_SECONDARY2 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_PRIMARY2 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
				case 4:
				{
				    p_SelectedGameClass[ playerid ] = 5;
			     	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_SECONDARY3 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 150 : 50 );
			       	GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_PRIMARY3 ], getPlayerFirstPerk( playerid ) == PERK_BANDOLIER ? 350 : 180 );
				}
		    }

			if ( p_CustomSkin{ playerid } == false && g_userData[ playerid ] [ E_VIP_LEVEL ] > 1 )
				ShowPlayerDialog( playerid, DIALOG_CHOOSE_VIPSKIN, DIALOG_STYLE_MSGBOX, ""#DIALOG_TITLE" - Use VIP Skin", ""COL_WHITE"Do you want to use your VIP skin? "COL_GREY"Use /vipskinoff to disable it.", "Yes", "No" );

			handlePlayerSpawnEquipment( playerid );
		}
		else
		{
		    format( szLargeString, 512, ""COL_GREY"[DEFAULT]{FFFFFF} AK-47, USP (Silenced)\n"COL_GREY"[DEFAULT]{FFFFFF} Combat Shotgun, USP (Silenced)\n"COL_GREY"[CLASS]{FFFFFF} %s\n"COL_GREY"[CLASS]{FFFFFF} %s\n"COL_GREY"[CLASS]{FFFFFF} %s", g_userData[ playerid ] [ E_CLASS1 ], g_userData[ playerid ] [ E_CLASS2 ], g_userData[ playerid ] [ E_CLASS3 ] );
			ShowPlayerDialog( playerid, DIALOG_CHOOSE_CLASS, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Choose Class", szLargeString, "Select", "" );
		}
	}
	if ( ( dialogid == DIALOG_CHOOSE_KS ) && response )
	{
	    if ( listitem == 0 )
	        return  ShowPlayerKillstreaks( playerid );

	    for( new i, x = 1; i < MAX_KILLSTREAKS; i ++ )
		{
	    	if ( g_playerKillstreakAmount[ playerid ] [ i ] > 0 )
		 	{
		       	if ( x == listitem )
		      	{
			        if ( p_Busy{ playerid } ) return SendError( playerid, "You are currently busy." );
					if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_USECELLPHONE ) return SendError( playerid, "You're currently busy." );
					if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You cannot use a killstreak if you're not spawned." );
					if ( g_mp_gameData[ E_STARTED ] == false ) return SendError( playerid, "You cannot use this while the round hasn't started!" );
					SetPlayerSpecialAction( playerid, SPECIAL_ACTION_USECELLPHONE );
					SetPlayerAttachedObject( playerid, 0, 330, 6 );

					SetTimerEx( "OnPlayerUseKillstreak", 3000, false, "dd", playerid, i ); // i+1 because of some retarded glitch
				 	break;
	      		}
		      	x ++;
			}
		}
	}
	if ( dialogid == DIALOG_STATS )
	{
		if ( !response && GetPlayerTeam( playerid ) == NO_TEAM )
	 		return ShowPlayerDialog( playerid, DIALOG_MODIFY_ACCOUNT, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Account Settings", "View Statistics\n{F2F2F2}Change Password\n{E5E5E5}Reset Statistics\n{C0C0C0}Hitmarker Options", "Select", "Back" );

		if ( response )
		{
		    new pID = p_ViewingStats[ playerid ];
			switch( listitem )
			{
				case 0:
				{
				    format( szLargeString, 512, ""COL_GREY"Name:{FFFFFF} %s(%d)\n"\
				                                ""COL_GREY"IP Address:{FFFFFF} %s\n"\
												""COL_GREY"Admin Level:{FFFFFF} %d\n"\
												""COL_GREY"Time Online:{FFFFFF} %s\n"\
												""COL_GREY"VIP Level:{FFFFFF} %s Package\n"\
												""COL_GREY"VIP Expiry:{FFFFFF} %s\n"\
												""COL_GREY"Double XP Expiry:{FFFFFF} %s\n",
												ReturnPlayerName( pID ), pID, g_userData[ pID ] [ E_ADMIN ] > 0 && pID != playerid ? ("Private") : ReturnPlayerIP( pID ), g_userData[ pID ] [ E_ADMIN ], secondstotime( g_userData[ pID ] [ E_UPTIME ] ), VIPLevelToString( g_userData[ pID ] [ E_VIP_LEVEL ] ), getVIPExpire( pID ), getDoubleXPExpire( pID ) );
					ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}General Statistics", szLargeString, "Okay", "Back" );
				}
				case 1:
				{
					format( szLargeString, 256,	""COL_GREY"Rank:{FFFFFF} %d\n"\
												""COL_GREY"XP:{FFFFFF} %d\n"\
												""COL_GREY"Prestige:{FFFFFF} %d\n"\
												""COL_GREY"Kills:{FFFFFF} %d\n"\
												""COL_GREY"Deaths:{FFFFFF} %d\n"\
												""COL_GREY"Ratio (K/D):{FFFFFF} %0.2f",
												g_userData[ pID ] [ E_RANK ], g_userData[ pID ] [ E_XP ], g_userData[ pID ] [ E_PRESTIGE ], g_userData[ pID ] [ E_KILLS ], g_userData[ pID ] [ E_DEATHS ], floatdiv( g_userData[ pID ] [ E_KILLS ], g_userData[ pID ] [ E_DEATHS ] ) );

					ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Main Statistics", szLargeString, "Okay", "Back" );
				}
				case 2:
				{
					format( szLargeString, 450,	""COL_GREY"Rank:{FFFFFF} %d\n"\
												""COL_GREY"XP:{FFFFFF} %d\n"\
												""COL_GREY"Prestige:{FFFFFF} %d\n"\
												""COL_GREY"Kills:{FFFFFF} %d\n"\
												""COL_GREY"Deaths:{FFFFFF} %d\n"\
												""COL_GREY"Ratio (K/D):{FFFFFF} %0.2f\n", //zm_prest
												g_userData[ pID ] [ E_ZM_RANK ], g_userData[ pID ] [ E_ZM_XP ], g_userData[ pID ] [ E_ZM_PRESTIGE ], g_userData[ pID ] [ E_ZM_KILLS ], g_userData[ pID ] [ E_ZM_DEATHS ], floatdiv( g_userData[ pID ] [ E_ZM_KILLS ], g_userData[ pID ] [ E_ZM_DEATHS ] ) );


					format( szLargeString, 450, "%s"COL_GREY"Victories:{FFFFFF} %d\n"\
												""COL_GREY"Loses:{FFFFFF} %d\n"\
												""COL_GREY"Medkits:{FFFFFF} %d\n"\
												""COL_GREY"Resurrection Lives:{FFFFFF} %d\n"\
												""COL_GREY"Money:{FFFFFF} %s",
												szLargeString, g_userData[ pID ] [ E_VICTORIES ], g_userData[ pID ] [ E_LOSSES ], g_userData[ pID ] [ E_MEDKIT ], g_userData[ pID ] [ E_LIVES ], ConvertPrice( GetPlayerCash( pID ) ) );

					ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Main Statistics", szLargeString, "Okay", "Back" );
				}
			}
		}
	}
	if ( ( dialogid == DIALOG_STATS_REDIRECT ) && !response ) {
		ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Statistics", "General Statistics\nMultiplayer Statistics\nZombie Statistics", "Select", GetPlayerTeam( playerid ) == NO_TEAM ? ("Back") : ("Cancel") );
	}
	if ( ( dialogid == DIALOG_RADIO ) && response )
	{
		if ( listitem == 0 )
		{
			if ( g_userData[ playerid ] [ E_VIP_LEVEL ] < 1 )
				return SendError( playerid, "You must be a V.I.P to use this, to become one visit "COL_GREY"donate.irresistiblegaming.com" ), 1;

		 	ShowPlayerDialog(playerid, DIALOG_RADIO_CUSTOM, DIALOG_STYLE_INPUT, "{FFFFFF}Custom Radio", ""COL_WHITE"Enter the URL below, and streaming will begin.\n\n"COL_ORANGE"Please note, if there isn't a response. It's likely to be an invalid URL.", "Stream", "Back");
			return 1;
		}
	   	p_UsingRadio{ playerid } = true;
	   	StopAudioStreamForPlayer( playerid );
	   	PlayAudioStreamForPlayer( playerid, g_RadioData[ listitem - 1 ] [ E_URL ] );
	    SendServerMessage( playerid, "If the radio doesn't respond then it must be offline. Use "COL_GREY"/stopradio"COL_WHITE" to stop the radio." );
	}
	if ( dialogid == DIALOG_RADIO_CUSTOM )
	{
		if ( !response ) return cmd_radio( playerid, "" );
	   	p_UsingRadio{ playerid } = true;
	   	StopAudioStreamForPlayer( playerid );
	   	PlayAudioStreamForPlayer( playerid, inputtext );
	    SendServerMessage( playerid, "If the radio doesn't respond then it must be offline. Use "COL_GREY"/stopradio"COL_WHITE" to stop the radio." );
	}
	if ( ( dialogid == DIALOG_CHOOSE_VIPSKIN ) && response )
	{
		SetPlayerSkin( playerid, g_userData[ playerid ] [ E_SKIN ] );
		p_CustomSkin{ playerid } = true;
	}
	if ( ( dialogid == DIALOG_VIP ) && response )
	{
		if ( strlen( inputtext ) != 17 )
		{
			cmd_redeemvip( playerid, "" );
			return SendError( playerid, "The transaction ID you entered is invalid." );
		}

		if ( g_redeemVipWait > gettime( ) )
		{
			cmd_redeemvip( playerid, "" );
			return SendClientMessageFormatted( playerid, -1, "Our anti-exploit system requires you to wait another %d seconds before redeeming.", gettime( ) - g_redeemVipWait );
		}

		format( szBigString, sizeof( szBigString ), "donate.irresistiblegaming.com/igcheck_code.php?transaction_id=%s", inputtext );
		HTTP( playerid, HTTP_GET, szBigString, "", "OnDonationRedemptionResponse" );
		SendServerMessage( playerid, "We're now looking up this transaction. Please wait." );
	}
	if ( dialogid == DIALOG_DONATED )
	{
		szLargeString[ 0 ] = '\0';
		strcat( szLargeString,	""COL_WHITE"Thank you a lot for donating! :D In return, you have received VIP for your dignity.\n\n"\
								""COL_GREY" *"COL_WHITE" You can view VIP commands with /vipcmds. It also features descriptions.\n" );
		strcat( szLargeString,	""COL_GREY" *"COL_WHITE" Ensure you run through your VIP package contents to know what you can access and what you have been given.\n"\
								""COL_GREY" *"COL_WHITE" If you have any questions, please do /ask. Admins will attend you as soon as possible.\n\nThank you once again for your contribution to the community."  );
		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP Delivery Service", szLargeString, "Got it!", "" );
	}
	if ( ( dialogid == DIALOG_MP_NEXTMAP ) && response )
	{
		g_mp_gameData[ E_NEXT_MAP ] = listitem;
		SendServerMessage( playerid, "You have set the next map for the multiplayer mode." );
		SendClientMessageToModeFormatted( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" %s(%d) set the next map to %s.", ReturnPlayerName( playerid ), playerid, g_mp_mapData[ listitem ] [ E_NAME ] );
	}
	if ( ( dialogid == DIALOG_ZM_NEXTMAP ) && response )
	{
		g_zm_gameData[ E_NEXT_MAP ] = listitem;
		SendServerMessage( playerid, "You have set the next map for the zombie mode." );
		SendClientMessageToModeFormatted( MODE_ZOMBIES, -1, ""COL_RED"[GAME]"COL_GREY" %s(%d) set the next map to %s.", ReturnPlayerName( playerid ), playerid, g_zm_mapData[ listitem ] [ E_NAME ] );
	}
	return 1;
}

public OnDonationRedemptionResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 )
    {
		if ( strmatch( data, "{FFFFFF}Unable to identify transaction." ) ) ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP Delivery Service", data, "Okay", "" );
		else
		{
			static aDonation[ E_DONATION_DATA ];
			sscanf( data, "p<|>e<s[64]s[256]s[11]s[64]d>", aDonation );

			if ( strfind( aDonation[ E_PURPOSE ], "Call Of Duty For SA-MP", false ) == -1 )
			{
				ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP Delivery Service", ""COL_WHITE"This donation is not specifically for this server thus you are unable to retrieve anything.", "Okay", "" );
				return 0;
			}

			format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `REDEEMED` WHERE `ID` = MD5('%s%s') LIMIT 0,1", mysql_escape( aDonation[ E_TRANSACTION_ID ] ), szRedemptionSalt );
	 		mysql_function_query( dbHandle, szNormalString, true, "OnCheckForRedeemedVIP", "is", index, data );
		}
	}
 	else ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP Delivery Service", ""COL_WHITE"Unable to connect to the donation database. Please try again later.", "Okay", "" );
	return 1;
}

thread OnCheckForRedeemedVIP( playerid, data[ ] )
{
	static
		aDonation[ E_DONATION_DATA ], iLevel,
	    rows, fields
	;
    cache_get_data( rows, fields );

	if ( rows ) ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP Delivery Service", ""COL_WHITE"Sorry this transaction ID has already been redeemed by someone else.", "Okay", "" );
	else
	{
		g_redeemVipWait = gettime( ) + 10;
		sscanf( data, "p<|>e<s[64]s[256]s[11]s[64]d>", aDonation );

		format( szNormalString, sizeof( szNormalString ), "INSERT INTO `REDEEMED`(`ID`, `REDEEMER`) VALUES (MD5('%s%s'), '%s')", mysql_escape( aDonation[ E_TRANSACTION_ID ] ), szRedemptionSalt, ReturnPlayerName( playerid ) );
		mysql_single_query( szNormalString );

		if ( floatstr( aDonation[ E_AMOUNT ] ) <  5.0  ) return SendError( playerid, "Unfortunately, nothing can be redeemed with donations under $5.00 USD." );
		if ( floatstr( aDonation[ E_AMOUNT ] ) >= 5.0  ) iLevel = 1;
		if ( floatstr( aDonation[ E_AMOUNT ] ) >= 10.0 ) iLevel = 2;
		if ( floatstr( aDonation[ E_AMOUNT ] ) >= 20.0 ) iLevel = 3;

		SetPlayerVipLevel( playerid, iLevel );

		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP PACKAGE]"COL_WHITE" You have received %s V.I.P! Thank you so much for donating! :P", VIPLevelToString( iLevel ) );

		format( szBigString, 256, ""COL_GREY"Transaction ID:\t"COL_WHITE"%s\n"COL_GREY"E-mail:\t\t"COL_WHITE"%s\n"COL_GREY"Amount:\t"COL_WHITE"$%0.2f\n"COL_GREY"Package:\t"COL_WHITE"%s\n"COL_GREY"Time Ago:\t"COL_WHITE"%s",
				aDonation[ E_TRANSACTION_ID ], CensoreString( aDonation[ E_EMAIL ] ), floatstr( aDonation[ E_AMOUNT ] ), VIPLevelToString( iLevel ), secondstotime( gettime( ) - aDonation[ E_DATE ] ) );

		ShowPlayerDialog( playerid, DIALOG_DONATED, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP Delivery Service", szBigString, "Continue", "" );
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

/////////////////////////
//      Functions      //
/////////////////////////

stock ReturnPlayerName( playerid )
{
	GetPlayerName( playerid, sz_Name, MAX_PLAYER_NAME );
	return sz_Name;
}

stock ReturnPlayerIP( playerid )
{
	GetPlayerIp( playerid, sz_IP, 16 );
	return sz_IP;
}

stock mysql_escape( string[ ] )
{
	mysql_real_escape_string( string, szBigString );
	return szBigString;
}

stock ShowMainMenu( playerid )
{
	p_WasInMainMenu{ playerid } = true;
	hideMatchTextDraws( playerid ); // Ugly.

	if ( IsPlayerInZombies( playerid ) )
		return ShowPlayerDialog( playerid, DIALOG_ZOMBIE_MENU, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Main Menu", "{FFB3B3}Join Game\n{FF8080}Pre-Game Store\n{FF4D4D}Prestige Specials\n{FF1A1A}Prestige Account", "Select", "Back" );

	return ShowPlayerDialog( playerid, DIALOG_MAIN_MENU, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Main Menu", "Join Game\n{E5E5E5}Combat Configuration\n{C0C0C0}Prestige Account", "Select", "Back" );
}

stock ShowSoundsMenu( playerid )
{
	new
		szString[ 64 ];

	format( szString, sizeof( szString ), "Hitmarker\t\t%s\nHitmarker Noise\t%s", g_userData[ playerid ] [ E_HITMARKER ] == 1 ? (""COL_GREEN"ENABLED") : (""COL_RED"DISABLED"), g_userData[ playerid ] [ E_HITMARKER ] == 1 ? HitmarkerSoundToString( g_userData[ playerid ] [ E_HIT_SOUND ] ) : (""COL_GREY"None") );
	ShowPlayerDialog( playerid, DIALOG_MODIFY_HITMARKER, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Hitmarker", szString, "Select", "Back" );
}

stock ShowGameMenu( playerid )
{
	for( new i; i < sizeof g_GameMenuTD; i++ )
		TextDrawShowForPlayer( playerid, g_GameMenuTD[ i ] );

	SelectTextDraw( playerid, 0x999999FF );

	AlterModePlayers( playerid, MODE_NONE );

	format( szNormalString, 12, "%d / 48", Iter_Count(mp_players) );
	TextDrawSetString( g_GameMenuTD[ 3 ], szNormalString );

	format( szNormalString, 12, "%d / 24", Iter_Count(zm_players) );
	TextDrawSetString( g_GameMenuTD[ 4 ], szNormalString );

	SetPVarInt( playerid, "inGameMenu", 1 );
}

stock CloseGameMenu( playerid )
{
	for( new i; i < sizeof g_GameMenuTD; i++ )
		TextDrawHideForPlayer( playerid, g_GameMenuTD[ i ] );

	DeletePVar( playerid, "inGameMenu" );
	CancelSelectTextDraw( playerid );
}

stock ShowSoundsList( playerid )
{
	static
		szSounds[ 11 * sizeof( g_HitmarkerSounds ) ];

	if ( szSounds[ 0 ] == '\0' )
	{
		for( new i = 0; i < sizeof( g_HitmarkerSounds ); i++ )
			format( szSounds, sizeof( szSounds ), "%s%s\n", szSounds, g_HitmarkerSounds[ i ] [ E_NAME ] );
	}
	ShowPlayerDialog( playerid, DIALOG_MODIFY_HM_SOUND, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Hitmarker", szSounds, "Select", "Back" );
}

stock HitmarkerSoundToString( soundid )
{
	new
		szReturn[ 10 ] = "N/A";

	for( new i; i < sizeof( g_HitmarkerSounds ); i++ ) {
		if ( g_HitmarkerSounds[ i ] [ E_SOUND_ID ] == soundid ) {
			format( szReturn, 10, "%s", g_HitmarkerSounds[ i ] [ E_NAME ] );
			break;
		}
	}

	return szReturn;
}

stock ShowCreateaClassMenu( playerid )
{
	new
		szString[ 32 * 5 ];

	static const
		locked[ 24 ] 	= "{FF0000}[CLASS]{FF9999}",
		unlocked[ 24 ] 	= ""COL_GREY"[CLASS]{FFFFFF}"
	;

	format( szString, sizeof( szString ), ""COL_GREY"[CLASS]{FFFFFF} %s\n%s %s\n%s %s\n%s", g_userData[ playerid ] [ E_CLASS1 ], g_userData[ playerid ] [ E_PRESTIGE ] >= 1 ? ( unlocked ) : ( locked ), g_userData[ playerid ] [ E_CLASS2 ], g_userData[ playerid ] [ E_PRESTIGE ] >= 3 ? ( unlocked ) : ( locked ), g_userData[ playerid ] [ E_CLASS3 ], g_userData[ playerid ] [ E_VIP_LEVEL ] > 1 ? (""COL_GOLD"[VIP] Additional Features") : ("") );
	ShowPlayerDialog( playerid, DIALOG_CREATE_CLASS, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Create-a-Class", szString, "Select", "Back" );
}

stock ChangePassword( playerid, password[ ] )
{
	if ( !IsPlayerConnected( playerid ) || !strlen( password ) )
	    return 0;

	new buffer[ 129 ];
	new szSalt[ 17 ];

	randomString( szSalt, 16 );
	cencrypt( buffer, sizeof( buffer ), password, szSalt );

	format( szBigString, sizeof( szBigString ), "UPDATE `COD` SET PASSWORD = '%s', SALT = '%s' WHERE ID = %d", buffer, mysql_escape( szSalt ), g_userData[ playerid ] [ E_ID ] );
	mysql_single_query( szBigString );
	return 1;
}

stock SpecialToString( spec )
{
	new string[ 21 ];
	switch( spec )
	{
	    case 0: string = "Grenade";
	    case 1: string = "Smoke";
	    case 2: string = "Claymore";
	    case 3: string = "C4";
	    case 4: string = "Tactical Insertion";
	    case 5: string = "Scrambler";
	    case 6: string = "Tomahawk";
	}
	return string;
}

stock PerkToString( perk, bool: first )
{
	new string[ 15 ];
	if ( first )
	{
		switch( perk )
		{
		    case 0: string = "Stopping Power";
		    case 1: string = "Banolier";
		    case 2: string = "Scavenger";
		    case 3: string = "Assassin";
		    case 4: string = "RPG x1";
		    default: string = "Invalid Perk";
		}
	}
	else
	{
		switch( perk )
		{
		    case 0: string = "Steady Aim";
		    case 1: string = "Quickfix";
		    case 2: string = "Hardline";
		    case 3: string = "Blast Shield";
		    case 4: string = "Sonic Boom";
		    default: string = "Invalid Perk";
		}
	}
	return string;
}

stock SelectionHelp::Equipment( playerid, equipment )
{
	static const
		timeout = 7500;

	switch( equipment )
	{
	    case 0: ShowPlayerInfoDialog( playerid, timeout, "You will be given a grenade on spawn." );
	    case 1: ShowPlayerInfoDialog( playerid, timeout, "You will be given a smoke grenade on spawn." );
	    case 2: ShowPlayerInfoDialog( playerid, timeout, "You will be given a claymore on spawn." );
	    case 3: ShowPlayerInfoDialog( playerid, timeout, "You will be given a pack of C4 on spawn." );
	    case 4: ShowPlayerInfoDialog( playerid, timeout, "You can set your spawning location on maps with the tactical insertion." );
	    case 5: ShowPlayerInfoDialog( playerid, timeout, "Enemies who are close to you will have their radars jammed." );
	    case 6: ShowPlayerInfoDialog( playerid, timeout, "You will be given a knife that can be thrown in the air. Extremely deadly." );
	}
}

stock SelectionHelp::Perks( playerid, perk, bool: first )
{
	static const
		timeout = 7500;

	if ( first )
	{
		switch( perk )
		{
		    case 0: ShowPlayerInfoDialog( playerid, timeout, "Your damage to enemies will be further increased." );
		    case 1: ShowPlayerInfoDialog( playerid, timeout, "As you spawn, you will receive extra mags on your weapons." );
		    case 2: ShowPlayerInfoDialog( playerid, timeout, "Upon killing an enemy, you will receive additional ammunition." );
		    case 3: ShowPlayerInfoDialog( playerid, timeout, "You will be undiscovered on enemy radar with this perk." );
		    case 4: ShowPlayerInfoDialog( playerid, timeout, "You will be given a 1x RPG when you spawn." );
		}
	}
	else
	{
		switch( perk )
		{
		    case 0: ShowPlayerInfoDialog( playerid, timeout, "Your aim will be stabilized with weapons." );
		    case 1: ShowPlayerInfoDialog( playerid, timeout, "As you're wounded, you will regenerate health at a quicker rate." );
		    case 2: ShowPlayerInfoDialog( playerid, timeout, "Each killstreak will require one less kill to be obtained." );
		    case 3: ShowPlayerInfoDialog( playerid, timeout, "Additional armour will be given on spawn." );
		    case 4: ShowPlayerInfoDialog( playerid, timeout, "Your explosive damage will vastly increase." );
		}
	}
}

stock SelectionHelp::Killstreaks( playerid, ks )
{
	static const
		timeout = 10000;

	switch( ks )
	{
	    case KS_RCXD: 				ShowPlayerInfoDialog( playerid, timeout, "You are able to drive an RC car attached with a C4 block." );
	    case KS_UAV: 				ShowPlayerInfoDialog( playerid, timeout, "Your team now can view enemies on the radar." );
	    case KS_COUNTER_UAV: 		ShowPlayerInfoDialog( playerid, timeout, "You can jam your enemy radar, disallowing them to see your teams' precise whereabouts." );
	    case KS_CARE_PACKAGE: 		ShowPlayerInfoDialog( playerid, timeout, "Care packages are deployed at specific locations to give random killstreaks." );
	    case KS_MORTAR_TEAM: 		ShowPlayerInfoDialog( playerid, timeout, "The enemy spawn will be bombarded with massive explosions." );
	    case KS_AGR: 				ShowPlayerInfoDialog( playerid, timeout, "You are able to drive an RC tank that can be fatal to enemies with a single shot." );
	    case KS_LIGHTNING_STRIKE: 	ShowPlayerInfoDialog( playerid, timeout, "You call in an air strike to a specific location in a particular direction." );
	    case KS_VTOL_WARSHIP: 		ShowPlayerInfoDialog( playerid, timeout, "You can navigate a large warship that will circle the map and shoot enemies." );
	    case KS_NUKE: 				ShowPlayerInfoDialog( playerid, timeout, "You now can... Hopefully... Kill everyone off the map." );
	}
}

stock ReturnWeaponName( weaponid )
{
	new wname[24];
	switch( weaponid ) {
	    case 0: wname = "Fist";
		case 18: wname = "Molotovs";
		case 40: wname = "Detonator";
		case 44: wname = "Nightvision Goggles";
		case 45: wname = "Thermal Goggles";
		case 22: wname = "Five-Seven";
		case 23: wname = "USP (Silenced)";
		case 33: wname = "M14";
		case 34: wname = "L118A (Sniper)";
		case 28: wname = "Uzi";
		case 32: wname = "FMG9";
		case 51: wname = "Explosion";
		case 53: wname = "Drowned";
		case 54: wname = "Collision";
		case 666: wname = "Boomed";
		default: GetWeaponName(weaponid, wname, sizeof(wname));
	}
	return wname;
}

stock SendClientMessageFormatted( playerid, colour, format[ ], va_args<> )
{
    static
		out[ 144 ]
	;
    va_format( out, sizeof( out ), format, va_start<3> );

	if ( !IsPlayerConnected( playerid ) ) {
		SendClientMessageToAll( colour, out );
		return 0;
	}
 	return SendClientMessage( playerid, colour, out );
}

stock Float: floatrandom( Float:max ) return floatmul( floatdiv( float( random( cellmax ) ), float( cellmax - 1 ) ), max );

stock Random3DCoord( Float: minx, Float: miny,Float: maxx, Float: maxy, &Float: randx, &Float: randy )
{
	randx = fRandomEx( minx, maxx );
	randy = fRandomEx( miny, maxy );
	return 1;
}

stock getAverageZ( &Float: Z ) {
	Z = floatdiv( floatadd( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAPZ1 ], g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAPZ1 ] ), 2.0 );
}

stock l4d_LoadMaps( )
{
	new
		nextMap[ 64 ],
		type,
		model, Float: X, Float: Y, Float: Z, Float: rX, Float: rY, Float: rZ
	;

	new dir: dHandle = dir_open( "scriptfiles/"#ZM_MAPS_DIRECTORY );

	while( dir_list( dHandle, nextMap, type ) )
	{
		if ( type == FM_FILE )
		{
			new
				m = Iter_Free(zm_maps);

			if ( m != -1 )
			{
				Iter_Add(zm_maps, m);

				format( nextMap, sizeof nextMap, ""#ZM_MAPS_DIRECTORY"%s", nextMap );
			    trimString( nextMap ); // Double check so no server freezing

			    g_zm_mapData[ m ] [ E_WORLD ] = RandomEx( 666, 999 ); // never past the devil

				new File: fMap = fopen( nextMap, io_read );
				while( fread( fMap, szBigString ) )
				{
					sscanf( szBigString, "p<\">'map''name='s[32] ", g_zm_mapData[ m ] [ E_NAME ] );
					sscanf( szBigString, "p<\">'map''author='s[24] ", g_zm_mapData[ m ] [ E_AUTHOR ] );

					if ( !sscanf( szBigString, "p<\">'map''helicopter='s[32] ", nextMap ) )
						sscanf( nextMap, "p<,>fff", g_zm_mapData[ m ] [ E_HELI_X ], g_zm_mapData[ m ] [ E_HELI_Y ], g_zm_mapData[ m ] [ E_HELI_Z ] );

					if ( !sscanf( szBigString, "p<\">'map''human_spawn='s[64] ", nextMap ) )
					{
					    if ( g_zm_mapData[ m ] [ E_HSPAWNS ]++ < sizeof( g_mapHumanSpawnData[ ] ) - 1 )
							sscanf( nextMap, "p<,>fff", g_mapHumanSpawnData[ m ] [ g_zm_mapData[ m ] [ E_HSPAWNS ] ] [ 0 ], g_mapHumanSpawnData[ m ] [ g_zm_mapData[ m ] [ E_HSPAWNS ] ] [ 1 ], g_mapHumanSpawnData[ m ][ g_zm_mapData[ m ] [ E_HSPAWNS ] ] [ 2 ] );
					}

					if ( !sscanf( szBigString, "p<\">'map''zombie_spawn='s[64] ", nextMap ) )
					{
					    if ( g_zm_mapData[ m ] [ E_ZSPAWNS ]++ < sizeof( g_mapZombieSpawnData[ ] ) - 1 )
							sscanf( nextMap, "p<,>fff", g_mapZombieSpawnData[ m ] [ g_zm_mapData[ m ] [ E_ZSPAWNS ] ] [ 0 ], g_mapZombieSpawnData[ m ] [ g_zm_mapData[ m ] [ E_ZSPAWNS ] ] [ 1 ], g_mapZombieSpawnData[ m ] [ g_zm_mapData[ m ] [ E_ZSPAWNS ] ] [ 2 ] );
					}

					if ( !sscanf( szBigString, "p<\">'object''model='d'posX='f'posY='f'posZ='f'rotX='f'rotY='f'rotZ='f", model, X, Y, Z, rX, rY, rZ ) )
						CreateDynamicObject( model, X, Y, Z, rX, rY, rZ, g_zm_mapData[ m ] [ E_WORLD ], -1, -1, 600.0 );
				}
			}
			else printf( "[ERROR]: Cannot add any more ZM maps because of the limit (%d).", MAX_ZM_MAPS );
		}
	}

	if ( Iter_Count(zm_maps) > 0 )
	{
		g_zm_gameData[ E_MAP ] = Iter_Random(zm_maps);

		printf("[ZM]: Total %d | Selected %s by %s!", Iter_Count(zm_maps), g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_NAME ], g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_AUTHOR ] );
		dir_close(dHandle);
	}
	else printf( "MAP FAILURE - cod_LoadMaps" );
}

stock cod_LoadMaps( )
{
	new
		nextMap[ 64 ],
		bool: customskin[ 2 char ],
		type,
		model, Float: X, Float: Y, Float: Z, Float: rX, Float: rY, Float: rZ
	;

	new dir: dHandle = dir_open( "scriptfiles/"#MP_MAPS_DIRECTORY );

	while( dir_list( dHandle, nextMap, type ) )
	{
		if ( type == FM_FILE )
		{
			new
				m = Iter_Free(maps);

			if ( m != -1 )
			{
				Iter_Add(maps, m);

				format( nextMap, sizeof nextMap, ""#MP_MAPS_DIRECTORY"%s", nextMap );
			    trimString( nextMap ); // Double check so no server freezing

			    g_mp_mapData[ m ] [ E_WORLD ] = RandomEx( 0, 665 ); // never past the devil

				new File: fMap = fopen( nextMap, io_read );
				while( fread( fMap, szBigString ) )
				{
					sscanf( szBigString, "p<\">'map''name='s[32] ", g_mp_mapData[ m ] [ E_NAME ] );
					sscanf( szBigString, "p<\">'map''author='s[24] ", g_mp_mapData[ m ] [ E_AUTHOR ] );
					sscanf( szBigString, "p<\">'map''weather='d ", g_mp_mapData[ m ] [ E_WEATHER ] );
					sscanf( szBigString, "p<\">'map''interior='d ", g_mp_mapData[ m ] [ E_INTERIOR ] );
					sscanf( szBigString, "p<\">'map''t1_z='f ", g_mp_mapData[ m ] [ E_MAPZ1 ] );
					sscanf( szBigString, "p<\">'map''t2_z='f ", g_mp_mapData[ m ] [ E_MAPZ2 ] );
					if ( !sscanf( szBigString, "p<\">'map''t1_skin='d ", g_mp_mapData[ m ] [ E_SKIN_1 ] ) && !customskin{ 0 } ) customskin{ 0 } = true;
					if ( !sscanf( szBigString, "p<\">'map''t2_skin='d ", g_mp_mapData[ m ] [ E_SKIN_2 ] ) && !customskin{ 1 } ) customskin{ 1 } = true;

					if ( strfind( szBigString, "ground_z" ) != -1 ) g_mp_mapData[ m ] [ E_GROUND_Z ] = true, printf("Ground Z toggled for %s", g_mp_mapData[ m ] [ E_NAME ] );
					if ( !sscanf( szBigString, "p<\">'map''t1_max_xy='s[32] ", nextMap ) ) sscanf( nextMap, "p<,>ff", g_mp_mapData[ m ] [ E_MAXX1 ], g_mp_mapData[ m ] [ E_MAXY1 ] );
					if ( !sscanf( szBigString, "p<\">'map''t1_min_xy='s[32] ", nextMap ) ) sscanf( nextMap, "p<,>ff", g_mp_mapData[ m ] [ E_MINX1 ], g_mp_mapData[ m ] [ E_MINY1 ] );
					if ( !sscanf( szBigString, "p<\">'map''t2_max_xy='s[32] ", nextMap ) ) sscanf( nextMap, "p<,>ff", g_mp_mapData[ m ] [ E_MAXX2 ], g_mp_mapData[ m ] [ E_MAXY2 ] );
					if ( !sscanf( szBigString, "p<\">'map''t2_min_xy='s[32] ", nextMap ) ) sscanf( nextMap, "p<,>ff", g_mp_mapData[ m ] [ E_MINX2 ], g_mp_mapData[ m ] [ E_MINY2 ] );

					if ( !sscanf( szBigString, "p<\">'object''model='d'posX='f'posY='f'posZ='f'rotX='f'rotY='f'rotZ='f", model, X, Y, Z, rX, rY, rZ ) )
						CreateDynamicObject( model, X, Y, Z, rX, rY, rZ, g_mp_mapData[ m ] [ E_WORLD ], g_mp_mapData[ m ] [ E_INTERIOR ] );
				}

				if ( !customskin{ 0 } ) g_mp_mapData[ m ] [ E_SKIN_1 ] = 163;
				if ( !customskin{ 1 } ) g_mp_mapData[ m ] [ E_SKIN_2 ] = 117;
				customskin{ 0 } = false, customskin{ 1 } = false;
			}
			else printf( "[ERROR]: Cannot add any more MP maps because of the limit (%d).", MAX_ZM_MAPS );
		}
	}

	if ( Iter_Count(maps) > 0 )
	{
		g_mp_gameData[ E_MAP ] = Iter_Random(maps);

		printf("[MP]: Total %d | Selected %s by %s!", Iter_Count(maps), g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_NAME ], g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_AUTHOR ] );
		dir_close(dHandle);
	}
	else printf( "MAP FAILURE - cod_LoadMaps" );
}

stock SpawnPlayerToBase( playerid, lock = 0, Float: offset = 1.0, zombie = 0 )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

	if ( !zombie )
	{
		new
			mapid = g_mp_gameData[ E_MAP ],
			Float: X, Float: Y
		;

		SetPlayerWeather( playerid, g_mp_mapData[ mapid ] [ E_WEATHER ] );
		SetPlayerInterior( playerid, g_mp_mapData[ mapid ] [ E_INTERIOR ] );
		SetPlayerVirtualWorld( playerid, g_mp_mapData[ mapid ] [ E_WORLD ] );
		SetPlayerTime( playerid, 12, 12 );

		if ( p_InsertionFlare[ playerid ] != INVALID_OBJECT_ID && getPlayerEquipment( playerid ) == EQUIPMENT_INSERTION )
		 	return SetPlayerPos( playerid, p_InsertionX[ playerid ], p_InsertionY[ playerid ], p_InsertionZ[ playerid ] ), DestroyTacticalInsertion( playerid ), 1;

		switch( p_Team[ playerid ] )
		{
			case TEAM_TROPAS:
			{
	        	TextDrawSetString( p_RoundPlayerTeam[ playerid ], "ld_otb2:ric1" );
				Random3DCoord( g_mp_mapData[ mapid ] [ E_MINX1 ], g_mp_mapData[ mapid ] [ E_MINY1 ], g_mp_mapData[ mapid ] [ E_MAXX1 ], g_mp_mapData[ mapid ] [ E_MAXY1 ], X, Y );
				SetPlayerPos( playerid, X, Y, g_mp_mapData[ mapid ] [ E_MAPZ1 ] + offset );
				if ( lock ) TogglePlayerControllable( playerid, 0 );
			}
			case TEAM_OP40:
			{
	        	TextDrawSetString( p_RoundPlayerTeam[ playerid ], "ld_otb2:ric2" );
				Random3DCoord( g_mp_mapData[ mapid ] [ E_MINX2 ], g_mp_mapData[ mapid ] [ E_MINY2 ], g_mp_mapData[ mapid ] [ E_MAXX2 ], g_mp_mapData[ mapid ] [ E_MAXY2 ], X, Y );
				SetPlayerPos( playerid, X, Y, g_mp_mapData[ mapid ] [ E_MAPZ2 ] + offset );
				if ( lock ) TogglePlayerControllable( playerid, 0 );
			}
			default: return 0;
		}
	}
	else
	{
		new
			iSpawn = -1,
			mapid = g_zm_gameData[ E_MAP ]
		;

		SetPlayerWeather( playerid, 9 );
		SetPlayerTime( playerid, 12, 12 );
		SetPlayerVirtualWorld( playerid, g_zm_mapData[ mapid ] [ E_WORLD ] );
		SetPlayerInterior( playerid, 0 );

		if ( IsPlayerNPC( playerid ) )
		{
		    rndspawn_zombie:
				iSpawn = random( sizeof( g_mapZombieSpawnData[ ] [ ] ) );
				if ( g_mapZombieSpawnData[ mapid ] [ iSpawn ] [ 0 ] == 0.0 && g_mapZombieSpawnData[ mapid ] [ iSpawn ] [ 0 ] == 0.0 ) goto rndspawn_zombie;
				FCNPC_SetPosition( playerid, g_mapZombieSpawnData[ mapid ] [ iSpawn ] [ 0 ], g_mapZombieSpawnData[ mapid ] [ iSpawn ] [ 1 ], g_mapZombieSpawnData[ mapid ] [ iSpawn ] [ 2 ] );
		}
		else
		{
		    rndspawn_human:
				iSpawn = random( sizeof( g_mapHumanSpawnData[ ] [ ] ) );
				if ( g_mapHumanSpawnData[ mapid ] [ iSpawn ] [ 0 ] == 0.0 && g_mapHumanSpawnData[ mapid ] [ iSpawn ] [ 0 ] == 0.0 ) goto rndspawn_human;
				SetPlayerPos( playerid, g_mapHumanSpawnData[ mapid ] [ iSpawn ] [ 0 ], g_mapHumanSpawnData[ mapid ] [ iSpawn ] [ 1 ], g_mapHumanSpawnData[ mapid ] [ iSpawn ] [ 2 ] );
		}
	}
	return 1;
}

class unpause_Player( playerid )
	return TogglePlayerControllable( playerid, 1 );

stock randarg( ... )
	return getarg( random( numargs( ) ) );

stock TimeConvert( seconds )
{
    new tmp[10], minutes = floatround(seconds/60);
    seconds -= minutes*60;
    format(tmp, sizeof(tmp), "%02d:%02d", minutes, seconds);
    return tmp;
}

stock ModeToStringSmall( id )
{
	new mode[ 4 ];
	switch( id )
	{
	    case MODE_TDM: 	mode = "TDM";
	    case MODE_CTF: 	mode = "CTF";
	    case MODE_KC: 	mode = "KC";
		default: mode = "NM";
	}
	return mode;
}

stock ModeToString( id )
{
	new mode[ 17 ];
	switch( id )
	{
	    case MODE_TDM: 	mode = "Team Deathmatch";
	    case MODE_CTF: 	mode = "Capture the Flag";
	    case MODE_KC: 	mode = "Kill Confirmed";
		default: 		mode = "No Mode";
	}
	return mode;
}

stock GiveTeamScore( teamid, score, playerid = INVALID_PLAYER_ID )
{
	new
	    Text: tmpText = Text: INVALID_TEXT_DRAW,
	    string[20]
	;

	switch( teamid )
	{
		case TEAM_TROPAS: 	g_TropasScore += score, g_tropasRoundBoxSize -= 0.6809919993591, TextDrawTextSize( g_tropasRoundBox, g_tropasRoundBoxSize, 0.000000 ), 	tmpText = g_tropasScoreText;
		case TEAM_OP40:   	g_OP40Score += score, 	g_op40RoundBoxSize -= 0.6809919993591,   TextDrawTextSize( g_op40RoundBox, g_op40RoundBoxSize, 0.000000 ), 		tmpText = g_op40ScoreText;
		default: return tmpText = Text: INVALID_TEXT_DRAW, 1;
	}

	format( string, sizeof( string ), "%d", Text: tmpText == Text: g_tropasScoreText ? g_TropasScore : g_OP40Score );
	TextDrawSetString( tmpText, string );

	if ( IsPlayerConnected( playerid ) )
		SetMatchData( playerid, M_SCORE, GetMatchData( playerid, M_SCORE ) + score );

	if ( g_mp_gameData[ E_STARTED ] == true && g_mp_gameData[ E_FINISHED ] == false )
	{
		foreach(new i: mp_players)
		{
			if ( p_inMovieMode{ i } ) continue;

		    switch( p_Team[ i ] )
		    {
	            case TEAM_TROPAS:  	TextDrawHideForPlayer( i, g_tropasRoundBox ), TextDrawShowForPlayer( i, g_tropasRoundBox );
	            case TEAM_OP40: 	TextDrawHideForPlayer( i, g_op40RoundBox ), TextDrawShowForPlayer( i, g_op40RoundBox );
			}
		}
	}
	return tmpText = Text: INVALID_TEXT_DRAW, 1;
}

stock GetTeamSpawnMiddlePoint( teamid, &Float: x, &Float: y, &Float: z=0.0 )
{
	switch( teamid )
	{
	    case TEAM_OP40:
		    x = ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAXX2 ] + g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MINX2 ] ) / 2,
		    y = ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAXY2 ] + g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MINY2 ] ) / 2,
			z = ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAPZ2 ] );

	    case TEAM_TROPAS:
		    x = ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAXX1 ] + g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MINX1 ] ) / 2,
		    y = ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAXY1 ] + g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MINY1 ] ) / 2,
			z = ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAPZ1 ] );
	}
	return 1;
}

stock GetMapMiddlePos( &Float: x, &Float: y, &Float: z=0.0 )
{
	new Float: X, Float: Y, Float: XX, Float: YY;
	GetTeamSpawnMiddlePoint( TEAM_OP40, X, Y );
	GetTeamSpawnMiddlePoint( TEAM_TROPAS, XX, YY );
	x = ( X + XX ) / 2;
	y = ( Y + YY ) / 2;
	z = ( g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAPZ1 ] + g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_MAPZ1 ] ) / 2;
}

stock GivePlayerXP( playerid, amount )
{
	if ( p_PlayerLogged{ playerid } == true )
	{
	    new string[ 20 ];

		if ( amount < 0 ) format( string, 20, "~r~%d XP", amount );
		else
		{
			new bool: vipdoublexp = g_userData[ playerid ] [ E_DOUBLE_XP ] > gettime( ) ? true : false;
			if ( vipdoublexp == true && g_doubleXP == true ) amount *= 3;
			else if ( vipdoublexp == true ) amount *= 2;
    		else if ( g_doubleXP == true ) amount *= 2;
			format( string, 20, "+%d XP", amount );
		}

		if ( IsPlayerInZombies( playerid ) )  g_userData[ playerid ] [ E_ZM_XP ] += amount;
		else
		{
			g_userData[ playerid ] [ E_XP ] += amount;

			if ( !p_inMovieMode{ playerid } )
			{
				TextDrawSetString( p_XPGivenTD[ playerid ], string );
				TextDrawShowForPlayer( playerid, p_XPGivenTD[ playerid ] );
				SetTimerEx( "TextDrawTimedHide", 3000, false, "dd", _: p_XPGivenTD[ playerid ], playerid );
			}
		}

		UpdateRankExpData( playerid );

		Beep( playerid );
		return 1;
	}
	return 0;
}

stock DestroyCTFlags( )
{
	for( new i = 1; i < MAX_TEAMS; i++ )
	{
	    DestroyDynamicCP( g_CTFFlag[ i ] );
	    g_CTFFlag[ i ] = 0xFFFF;
		Delete3DTextLabel( g_CTFLabel[ i ] );
	    g_CTFLabel[ i ] = Text3D: 0xFFFF;
		DestroyDynamicPickup( g_CTFFlagPickup[ i ] );
		g_CTFFlagPickup[ i ] = 0xFFFF;
		DestroyDynamicMapIcon( g_CTFFlagIcon[ i ] );
		g_CTFFlagIcon[ i ] = 0xFFFF;
	}
}

stock SetCTFlags( )
{
	new
		Float: X, Float: Y, Float: Z;

	for( new i = 1; i < MAX_TEAMS; i++ )
	{
	    DestroyDynamicCP( g_CTFFlag[ i ] );
		Delete3DTextLabel( g_CTFLabel[ i ] );
		DestroyDynamicPickup( g_CTFFlagPickup[ i ] );

		GetTeamSpawnMiddlePoint( i, X, Y, Z );

		g_CTFFlag[ i ] 	= CreateDynamicCP( X, Y, Z, 1, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ] );
		g_CTFFlagPickup[ i ] = CreateDynamicPickup( 2993, 1, X, Y, Z, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ] );
		g_CTFFlagIcon[ i ] = CreateDynamicMapIcon( X, Y, Z, 19, 0, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ], g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_INTERIOR ], -1, 666.0 );

		if ( i == TEAM_OP40 ) g_CTFLabel[ i ] = Create3DTextLabel( "{F31B1D}OP40's{FFFFFF} Flag\nDefend this flag, don't let the enemies take it!", 0xFFFFFFFF, X, Y, Z, 15.0, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ] );
		else g_CTFLabel[ i ] = Create3DTextLabel( "{00A8FF}Tropas'{FFFFFF} Flag\nDefend this flag, don't let the enemies take it!", 0xFFFFFFFF, X, Y, Z, 15.0, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ] );
	}
}

stock StripPlayerFlag( playerid, bool: reset = false )
{
	if ( p_StolenFlag[ playerid ] [ TEAM_TROPAS ] )
	{
	    if ( !reset ) SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" Tropas' flag has been returned!" );
	    p_StolenFlag[ playerid ] [ TEAM_TROPAS ] = false;
     	g_CTFFlagStolen{ TEAM_TROPAS } = false;
     	RemovePlayerAttachedObject( playerid, 1 );
	}
	if ( p_StolenFlag[ playerid ] [ TEAM_OP40 ] )
	{
	    if ( !reset ) SendClientMessageToMode( MODE_MULTIPLAYER, -1, ""COL_ORANGE"[GAME]"COL_GREY" OP40's flag has been returned!" );
	    p_StolenFlag[ playerid ] [ TEAM_OP40 ] = false;
     	g_CTFFlagStolen{ TEAM_OP40 } = false;
     	RemovePlayerAttachedObject( playerid, 1 );
	}
	return 1;
}

stock CreateDogTag( playerid, killerid, Float: X, Float: Y, Float: Z )
{
	new
	    id = Iter_Free(dogtags);

	if ( id != -1 )
	{
	    g_dogtagData[ id ] [ E_TEAM_ID ] = p_Team[ killerid ];
	    g_dogtagData[ id ] [ E_X ] = X;
	    g_dogtagData[ id ] [ E_Y ] = Y;
	    g_dogtagData[ id ] [ E_Z ] = Z;
	    g_dogtagData[ id ] [ E_DIER_ID ] = playerid;
	    g_dogtagLabel[ id ] = Create3DTextLabel( TEXT_DOGTAG, setAlpha( ReturnPlayerTeamColor( playerid ), 0xFF ), X, Y, Z, 25.0, g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_WORLD ] );
	    Iter_Add(dogtags, id);
	}
}

stock DestroyDogTag( id )
{
	if ( id == -1 )
	    return 0;

	Delete3DTextLabel( g_dogtagLabel[ id ] );
	g_dogtagData[ id ] [ E_TEAM_ID ] = -1;
	g_dogtagData[ id ] [ E_DIER_ID ] = INVALID_PLAYER_ID;
	Iter_Remove(dogtags, id);
	return 1;
}

stock GetPlayerDogTag( playerid )
{
	foreach(dogtags, i)
	{
		if ( g_dogtagData[ i ] [ E_DIER_ID ] == playerid )
			return i;
	}
	return -1;
}

stock SetScopedWeapons( ... )
{
    for( new count, lol = numargs( ); count < lol; count++ )
		g_ScopedWeapons{ getarg( count ) } = true;
}

stock CreateUAV( playerid )
{
    foreach(new i : mp_players)
    {
        if ( p_Team[ i ] != p_Team[ playerid ] )
       	{
       	    foreach(new e : mp_players)
    		{
    		    if ( p_Team[ e ] == p_Team[ playerid ] )
   		    	{
        			if ( getPlayerFirstPerk( i ) != PERK_ASSASSIN )
        			{
	   		    		SetPlayerMarkerForPlayer( e, i, ( GetPlayerColor( i ) & ReturnPlayerTeamColor( i ) ) );
					}
				}
    		}
       	}
    }
    g_UAVOnline{ p_Team[ playerid ] } = true;
    g_UAVTimestamp{ p_Team[ playerid ] } = gettime( ) + 60;
}

stock ReturnPlayerTeamColor( playerid )
{
	if ( p_AdminOnDuty{ playerid } )
		return COLOR_ADMIN;

	switch( p_Team[ playerid ] ) {
		case TEAM_SURVIVORS: return 0x00CC00FF;
		case TEAM_TROPAS:	 return COLOR_TROPAS;
		case TEAM_OP40: 	 return COLOR_OP40;
	}
	return COLOR_GREY;
}

GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
    GetPlayerPos(playerid, x, y, a);
    GetPlayerFacingAngle(playerid, a);
    if (GetPlayerVehicleID(playerid))
    {
    	GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
 	}
 	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

stock TruncatePlayerClaymores( playerid )
{
	foreach(new i : claymore)
	{
		if ( g_claymoreOwner[ i ] == playerid )
		{
		    new
		        next;

		    Iter_SafeRemove(claymore, i, next);

		    DestroyDynamicObject( g_claymoreObject[ i ] );
		    g_claymoreObject[ i ] = INVALID_OBJECT_ID;
			g_claymoreOwner[ i ] = INVALID_PLAYER_ID;

		    i = next;
		}
	}
}

stock GetTotalPlayerClaymores( playerid )
{
	new
	    count = 0;

	foreach(new i : claymore)
	{
	    if ( g_claymoreOwner[ i ] == playerid && IsValidDynamicObject( g_claymoreObject[ i ] ) )
	       	count++;
	}
	return count;
}

stock DestroyClaymore( c_id )
{
	if ( c_id == -1 || c_id == 0xFF ) return;
    DestroyDynamicObject( g_claymoreObject[ c_id ] );
    g_claymoreObject[ c_id ] = INVALID_OBJECT_ID;
	g_claymoreOwner[ c_id ] = INVALID_PLAYER_ID;
    Iter_Remove(claymore, c_id);
}

stock CreateClaymore( playerid )
{
	if ( p_claymoreDisabled{ playerid } == true )
		return 0;

    if ( GetTotalPlayerClaymores( playerid ) > 1 )
        return 0;

	new
	    Float: pX, Float: pY, Float: pZ,
	    id = Iter_Free(claymore)
	;

	if ( id != -1 )
	{
		GetPlayerPos( playerid, pZ, pZ, pZ );
		GetXYInFrontOfPlayer( playerid, pX, pY, 2.0 );
		p_claymoreDisabled{ playerid } = true;
		Iter_Add(claymore, id);
		g_claymoreOwner[ id ] = playerid;
	    g_claymoreObject[ id ] = CreateDynamicObject( 1213, pX, pY, pZ - 0.8, 0.0, 0.0, 0.0, -1, -1, -1, 50.0 );
		ApplyAnimation( playerid, "CARRY", "putdwn105", 4.0, 0, 0, 0, 0, 1 );
		SendServerMessage( playerid, "You have placed your "COL_GREY"claymore"COL_WHITE"." );
	}
    return 1;
}

stock DestroyTacticalInsertion( playerid )
{
	Delete3DTextLabel( p_InsertionLabel[ playerid ] );
    p_InsertionLabel[ playerid ] = Text3D: 0xFFFF;
	DestroyDynamicObject( p_InsertionFlare[ playerid ] );
	p_InsertionFlare[ playerid ] = INVALID_OBJECT_ID;
	p_InsertionX[ playerid ] = 0.0, p_InsertionX[ playerid ] = 0.0, p_InsertionX[ playerid ] = 0.0;
	return 1;
}

stock GetClosestPlayer(p1)
{
    new Float:dis,Float:dis2,player;
    player = -1;
    dis = 99999.99;
	foreach(new x : Player) {
        if (IsPlayerConnected(x)) {
            if (x != p1) {
                dis2 = GetDistanceBetweenPlayers(x,p1);
                if (dis2 < dis && dis2 != -1.00) {
                    dis = dis2;
                    player = x;
                }
            }
        }
    }
    return player;
}

stock IsPlayerNearObject( playerid, objectid, Float:range )
{
    static
		Float: X, Float: Y, Float: Z;

    GetObjectPos( objectid, X, Y, Z );
    return IsPlayerInRangeOfPoint( playerid, range, X, Y, Z );
}

stock ResetMatchData( i )
{
	g_usermatchDataT1[ i ] [ M_ID ] = INVALID_PLAYER_ID;
	g_usermatchDataT2[ i ] [ M_ID ] = INVALID_PLAYER_ID;
	g_usermatchDataT1[ i ] [ M_SCORE ] 	= 0;
	g_usermatchDataT2[ i ] [ M_SCORE ] 	= 0;
	p_MatchKills[ i ] 	= 0;
	p_MatchDeaths[ i ] 	= 0;
}

stock SetMatchData( playerid, e_match_progress: a, score )
{
	switch( p_Team[ playerid ] )
	{
	    case TEAM_TROPAS: g_usermatchDataT1[ playerid ] [ a ] = score;
	    case TEAM_OP40: g_usermatchDataT2[ playerid ] [ a ] = score;
	}
}

stock GetMatchData( playerid, e_match_progress: a )
	return p_Team[ playerid ] == TEAM_TROPAS ? g_usermatchDataT1[ playerid ] [ a ] : g_usermatchDataT2[ playerid ] [ a ];

stock showScoreBoard( playerid )
{
	for( new i; i < sizeof( g_Scoreboard ); i++ )
	{
	    if ( i < sizeof( g_ScoreboardNames ) )
	    {
			TextDrawShowForPlayer( playerid, g_ScoreboardNames[ i ] );
			TextDrawShowForPlayer( playerid, g_ScoreboardKills[ i ] );
			TextDrawShowForPlayer( playerid, g_ScoreboardDeaths[ i ] );
			TextDrawShowForPlayer( playerid, g_ScoreboardScores[ i ] );
			TextDrawShowForPlayer( playerid, g_ScoreboardTeamScore[ i ] );
	    }
		TextDrawShowForPlayer( playerid, g_Scoreboard[ i ] );
	}
}

stock hideScoreBoard( )
{
	for( new i; i < sizeof( g_Scoreboard ); i++ )
	{
	    if ( i < sizeof( g_ScoreboardNames ) )
	    {
			TextDrawHideForAll( g_ScoreboardNames[ i ] );
			TextDrawHideForAll( g_ScoreboardKills[ i ] );
			TextDrawHideForAll( g_ScoreboardDeaths[ i ] );
			TextDrawHideForAll( g_ScoreboardScores[ i ] );
			TextDrawHideForAll( g_ScoreboardTeamScore[ i ] );
	    }
		TextDrawHideForAll( g_Scoreboard[ i ] );
	}
}

stock DestroyPlayerC4( playerid, reset_c4 = 0 )
{
    for( new i = 0; i < MAX_C4; i++ )
    {
        DestroyDynamicObject( p_C4Object[ playerid ] [ i ] );
        p_C4Object[ playerid ] [ i ] = INVALID_OBJECT_ID;
    }
    if ( reset_c4 ) p_C4Amount{ playerid } = reset_c4;
}

stock RemovePlayerWeapon(playerid, ...)
{
    new
        iArgs = numargs()
    ;
    while(--iArgs) {
        SetPlayerAmmo(playerid, getarg(iArgs), 0);
    }
}

stock PreloadAnimationLibrary( playerid, animlib[ ] )
	return ApplyAnimation( playerid, animlib, "null", 0.0, 0, 0, 0, 0, 0 );

#if CUSTOM_SHOOTING == false
	stock GetWeaponSlot(weaponid)
	{
	    switch(weaponid)
	    {
	        case WEAPON_BRASSKNUCKLE:
	            return 0;
	        case WEAPON_GOLFCLUB .. WEAPON_CHAINSAW:
	            return 1;
	        case WEAPON_COLT45 .. WEAPON_DEAGLE:
	            return 2;
	        case WEAPON_SHOTGUN .. WEAPON_SHOTGSPA:
	            return 3;
	        case WEAPON_UZI, WEAPON_MP5, WEAPON_TEC9:
	            return 4;
	        case WEAPON_AK47, WEAPON_M4:
	            return 5;
	        case WEAPON_RIFLE, WEAPON_SNIPER:
	            return 6;
	        case WEAPON_ROCKETLAUNCHER .. WEAPON_MINIGUN:
	            return 7;
	        case WEAPON_GRENADE .. WEAPON_MOLTOV, WEAPON_SATCHEL:
	            return 8;
	        case WEAPON_SPRAYCAN .. WEAPON_CAMERA:
	            return 9;
	        case WEAPON_DILDO .. WEAPON_FLOWER:
	            return 10;
	        case 44, 45, WEAPON_PARACHUTE:
	            return 11;
	        case WEAPON_BOMB:
	            return 12;
	    }
	    return -1;
	}
#endif

stock GivePlayerKillstreak( playerid, killstreak_id, amount = 1 )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0x0A;

	if ( killstreak_id < 0 || killstreak_id >= MAX_KILLSTREAKS )
	    return 0x1B;

    g_playerKillstreakAmount[ playerid ] [ killstreak_id ] += amount;
	GameTextForPlayer( playerid, "~n~~w~Press ~y~~h~~k~~CONVERSATION_NO~~w~ to use killstreaks!", 2000, 4 );
    SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have been given a "COL_GREY"%s(%d)"COL_WHITE". To view your killstreaks, press"COL_ORANGE" N", KillstreakToString( killstreak_id ), amount );
	return 1;
}

stock ShowPlayerKillstreaks( playerid )
{
	new
	    string[ 512 ],
	    count = 0
	;

	strmid( string, ""COL_GREY"AMOUNT\tKILLSTREAK\n", 0, cellmax );
	for( new i; i < MAX_KILLSTREAKS; i++ )
	{
	    if ( g_playerKillstreakAmount[ playerid ] [ i ] > 0 )
	   		count++, format( string, sizeof( string ), "%s%d\t\t%s\n", string, g_playerKillstreakAmount[ playerid ] [ i ], KillstreakToString( i ) );
	}
	if ( !count ) return 0;
	ShowPlayerDialog( playerid, DIALOG_CHOOSE_KS, DIALOG_STYLE_LIST, "Killstreak Inventory", string, "Select", "Cancel" );
	return 1;
}

stock IsPointToPoint(Float: fRadius, Float: fX1, Float: fY1, Float: fZ1, Float: fX2, Float: fY2, Float: fZ2)
    return ((-fRadius < floatabs(fX2 - fX1) < fRadius) && (-fRadius < floatabs(fY2 - fY1) < fRadius) && (-fRadius < floatabs(fZ2 - fZ1) < fRadius));

stock StartAGR( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

	new
		Float: X, Float: Y, Float: Z,
		drone = 0xFFFF
	;
	GetPlayerPos( playerid, X, Y, Z );

    TextDrawSetString( p_KillstreakInstructions[ playerid ], "Fire Key - Shoot" );
    TextDrawShowForPlayer( playerid, p_KillstreakInstructions[ playerid ] );
	drone = CreateVehicle( 564, X, Y, Z, 0.0, 0, 0, 999999 );
    SetVehicleVirtualWorld( drone, GetPlayerVirtualWorld( playerid ) );
    LinkVehicleToInterior( drone, GetPlayerInterior( playerid ) );
    SetVehicleHealth( drone, 1000.0 );
    PutPlayerInVehicle( playerid, drone, 0 );
    p_AGRVehicle[ playerid ] = drone;
    p_Busy{ playerid } = true;
	p_AGRTimer[ playerid ] = SetTimerEx( "endAGR", 40000, false, "d", playerid );
	return 1;
}

class endAGR( playerid )
{
	DestroyVehicle( p_AGRVehicle[ playerid ] );
	p_AGRVehicle[ playerid ] = INVALID_VEHICLE_ID;
	KillTimer( p_AGRTimer[ playerid ] );
	p_AGRTimer[ playerid ] = 0xFFFF;
	p_Busy{ playerid } = false;
	TextDrawHideForPlayer( playerid, p_KillstreakInstructions[ playerid ] );
	return 1;
}

stock CreateRCXD(playerid)
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

	new
	    Float: X, Float: Y, Float: Z
	;

    TextDrawSetString( p_KillstreakInstructions[ playerid ], "Fire Key - Detonate" );
    TextDrawShowForPlayer( playerid, p_KillstreakInstructions[ playerid ] );
	KillTimer( p_ConstantVehicleRepair[ playerid ] );
	DestroyVehicle( p_RCXDVehicle[ playerid ] );
	GetPlayerPos( playerid, X, Y, Z );
	p_RCXDVehicle[ playerid ] = CreateVehicle( 441, X, Y, Z, 0.0, 0, 0, -1 );
    SetVehicleVirtualWorld( p_RCXDVehicle[ playerid ], GetPlayerVirtualWorld( playerid ) );
    LinkVehicleToInterior( p_RCXDVehicle[ playerid ], GetPlayerInterior( playerid ) );
    SetVehicleHealth( p_RCXDVehicle[ playerid ], 1000.0 );
    PutPlayerInVehicle( playerid, p_RCXDVehicle[ playerid ], 0 );
    p_Busy{ playerid } = true;
    p_ConstantVehicleRepair[ playerid ] = SetTimerEx( "const_RepairVehicle", 1000, true, "d", playerid );
    return 1;
}

class endRCXD( playerid )
{
	KillTimer( p_ConstantVehicleRepair[ playerid ] );
	p_ConstantVehicleRepair[ playerid ] = 0xFFFF;
	DestroyVehicle( p_RCXDVehicle[ playerid ] );
	p_RCXDVehicle[ playerid ] = INVALID_VEHICLE_ID;
    p_Busy{ playerid } = false;
	TextDrawHideForPlayer( playerid, p_KillstreakInstructions[ playerid ] );
}

class const_RepairVehicle( playerid )
	return IsPlayerInAnyVehicle( playerid ) ? RepairVehicle( GetPlayerVehicleID( playerid ) ) : 0;

stock CreateCounterUAV( playerid )
{
	foreach(new i : mp_players)
	{
		if ( p_Team[ i ] != p_Team[ playerid ]  && IsPlayerInMatch( i ) )
		{
    		if ( g_CounterUAVOnline{ p_Team[ i ] } == false )
			{
				g_CounterUAVOnline{ p_Team[ i ] } = true;
				SetTimerEx( "endCounterUAV", 60 * 1000, false, "d", p_Team[ i ] );
			}
		    GangZoneShowForPlayer( i, g_Blackzone, 0x000000FF );
		}
	}
	return 1;
}

class endCounterUAV( teamid )
{
    g_CounterUAVOnline{ teamid } = false;
    foreach(new i : mp_players)
	{
		if ( p_Team[ i ] == teamid )
			GangZoneHideForPlayer( i, g_Blackzone );
	}
	return 1;
}

stock RemovePlayerMeleeWeapon(playerid, weaponid)
{
	new plyWeapons[12];
	new plyAmmo[12];
	for(new slot = 0; slot != 12; slot++)
	{
		new wep, ammo;
		GetPlayerWeaponData(playerid, slot, wep, ammo);
		if (wep != weaponid)
		{
		  	GetPlayerWeaponData(playerid, slot, plyWeapons[slot], plyAmmo[slot]);
		}
	}
	ResetPlayerWeapons(playerid);
	for(new slot = 0; slot != 12; slot++)
	{
		GivePlayerWeapon(playerid, plyWeapons[slot], plyAmmo[slot]);
	}
}

stock StartLightingStrike( playerid )
{
    new Float: X, Float: Y, Float: Z;
	GetPlayerPos( playerid, X, Y, Z );

	SetPlayerCameraPos( playerid, X, Y, Z + 125 );
	SetPlayerCameraLookAt( playerid, X, Y, Z );
	TogglePlayerControllable( playerid, 0 );
	g_LightningStrikeUser = playerid;
	p_Busy{ playerid } = true;
	p_LightningMode[ playerid ] = 0;

    TextDrawSetString( p_KillstreakInstructions[ playerid ], "Space - Control Rotation/Position~n~Fire - Launch the strike~n~W A S D - Position Axis/Degree" );
    TextDrawShowForPlayer( playerid, p_KillstreakInstructions[ playerid ] );

	g_LightningStrikeObject = CreateObject( 1683, X, Y, Z + 75, 0, 0, 0 );
	g_LightningStrikeTimer = SetTimerEx( "LightningStrike_Move", 75, true, "d", playerid );
    return 1;
}

class LightningStrike_Move( playerid )
{
	new
	    keys,
	    ud,
	    lr,
		Float: np_rX,
		Float: np_rY,
		Float: np_rZ,
		Float: np_X,
		Float: np_Y,
		Float: np_Z
	;
	GetPlayerKeys( playerid, keys, ud, lr );
	GetObjectRot( g_LightningStrikeObject, np_rX, np_rY, np_rZ );
	GetObjectPos( g_LightningStrikeObject, np_X, np_Y, np_Z );

	if ( lr > 0 || lr < 0 || ud > 0 || ud < 0 )
	{
		if ( !p_LightningMode[ playerid ] )
		{
			if ( lr > 0 ) p_LightningDegree[ playerid ] -= 7.5;
   			if ( lr < 0 ) p_LightningDegree[ playerid ] += 7.5;

   			if (p_LightningDegree[ playerid ] > 360) p_LightningDegree[ playerid ] = 0;
			SetObjectRot( g_LightningStrikeObject, np_rX, np_rY, p_LightningDegree[ playerid ] );
		}
		else
		{
			if ( ud < 0 ) SetObjectPos( g_LightningStrikeObject, np_X + 1, np_Y + 1, np_Z );
			if ( ud > 0 ) SetObjectPos( g_LightningStrikeObject, np_X - 1, np_Y - 1, np_Z );
			if ( lr < 0 ) SetObjectPos( g_LightningStrikeObject, np_X - 1, np_Y + 1,	np_Z );
			if ( lr > 0 ) SetObjectPos( g_LightningStrikeObject, np_X + 1, np_Y - 1, np_Z );

			SetPlayerCameraPos( playerid, 		np_X, 	np_Y, 	np_Z  + 50 );
   			SetPlayerCameraLookAt( playerid, 	np_X, 	np_Y, 	np_Z );
		}
	}
	if ( ( keys & KEY_FIRE ) == ( KEY_FIRE ) )
	{
		new
            Float: aX,
            Float: aY
		;

		aX = floatcos( p_LightningDegree[ playerid ], degrees ) * 260 + np_X;
		aY = floatsin( p_LightningDegree[ playerid ], degrees ) * 260 + np_Y;
		MoveObject( g_LightningStrikeObject, aX, aY, np_Z, 15.0 );

     	aX = floatcos( p_LightningDegree[ playerid ], degrees ) * 25 + np_X;
		aY = floatsin( p_LightningDegree[ playerid ], degrees ) * 25 + np_Y;
		SetTimerEx( "deloyExplosive_LS", 5000, false, "dffffd", playerid, aX, aY, np_Z, p_LightningDegree[ playerid ], 0 );

		KillTimer( g_LightningStrikeTimer );
		g_LightningStrikeTimer = 0xFFFF;
		g_LightningStrikeUser = INVALID_PLAYER_ID;

		endLightningStrike( playerid, 0 );
		return 1;
    }
    return 1;
}

class deloyExplosive_LS( playerid, Float: X, Float: Y, Float: Z, Float: degree, step )
{
	if ( step < 10 ) {
	    X = X + ( step * 5 ) * floatcos( degree, degrees ), Y = Y + ( step * 5 ) * floatsin( degree, degrees );

		if ( !g_mp_mapData[ g_mp_gameData[ E_MAP ] ] [ E_GROUND_Z ] ) MapAndreas_FindZ_For2DCoord( X, Y, Z );
		else getAverageZ( Z );

	    getAverageZ( Z );
    	CreateExplosionEx( playerid, X, Y, Z, 5.0, EXPLOSION_TYPE_MOLOTOV, 51 );
		SetTimerEx( "deloyExplosive_LS", 150, false, "dffffd", playerid, X, Y, Z, degree, step + 1 );
	}
	else
	{
		DestroyObject( g_LightningStrikeObject );
		g_LightningStrikeObject = INVALID_OBJECT_ID;
	}
	return 1;
}

stock endLightningStrike( playerid, reset=1 )
{
	p_Busy{ playerid } = false;
	p_LightningDegree[ playerid ] = 0.0;
	p_LightningMode[ playerid ] = 0;

	if ( IsPlayerSpawned( playerid ) )
	{
		TogglePlayerControllable( playerid, 1 );
		SetCameraBehindPlayer( playerid );
	}

   	TextDrawHideForPlayer( playerid, p_KillstreakInstructions[ playerid ] );

	if ( reset && g_LightningStrikeUser == playerid )
	{
		g_LightningStrikeUser = INVALID_PLAYER_ID;
		DestroyObject( g_LightningStrikeObject );
		g_LightningStrikeObject = INVALID_OBJECT_ID;
		KillTimer( g_LightningStrikeTimer );
		g_LightningStrikeTimer = 0xFFFF;
	}
}

class mortarTeam_Deploy( playerid, teamid, step )
{
	new
		Float: X, Float: Y, Float: Z,
		mapid = g_mp_gameData[ E_MAP ];

	if ( step < 10 )
	{
		if ( teamid == TEAM_TROPAS )
			Random3DCoord( g_mp_mapData[ mapid ] [ E_MINX1 ], g_mp_mapData[ mapid ] [ E_MINY1 ], g_mp_mapData[ mapid ] [ E_MAXX1 ], g_mp_mapData[ mapid ] [ E_MAXY1 ], X, Y ), Z = g_mp_mapData[ mapid ] [ E_MAPZ1 ];
		else
			Random3DCoord( g_mp_mapData[ mapid ] [ E_MINX2 ], g_mp_mapData[ mapid ] [ E_MINY2 ], g_mp_mapData[ mapid ] [ E_MAXX2 ], g_mp_mapData[ mapid ] [ E_MAXY2 ], X, Y ), Z = g_mp_mapData[ mapid ] [ E_MAPZ2 ];

    	CreateExplosionEx( playerid, X, Y, Z, 5.0, EXPLOSION_TYPE_MOLOTOV, 51 );
		SetTimerEx( "mortarTeam_Deploy", 750, false, "ddd", playerid, teamid, step + 1 );
	}
}

stock ChangeSecondaryOnSelectedSlot( playerid, weaponid )
{
	switch( p_cac_SelectedClass[ playerid ] )
	{
		case 0: g_userData[ playerid ] [ E_SECONDARY1 ] = weaponid;
		case 1: g_userData[ playerid ] [ E_SECONDARY2 ] = weaponid;
		case 2: g_userData[ playerid ] [ E_SECONDARY3 ] = weaponid;
	}
	TextDrawSetPreviewModel( p_ClassSecondary[ playerid ], GetWeaponModel( weaponid ) );
	TextDrawSetPreviewRot( p_ClassSecondary[ playerid ], -16.000000, 0.000000, 180.000000, 1.500000 );
	TextDrawShowForPlayer( playerid, p_ClassSecondary[ playerid ] );
	UpdateClassSetupTD( playerid );
}

stock ChangePrimaryOnSelectedSlot( playerid, weaponid )
{
	switch( p_cac_SelectedClass[ playerid ] )
	{
		case 0: g_userData[ playerid ] [ E_PRIMARY1 ] = weaponid;
		case 1: g_userData[ playerid ] [ E_PRIMARY2 ] = weaponid;
		case 2: g_userData[ playerid ] [ E_PRIMARY3 ] = weaponid;
	}
	TextDrawSetPreviewModel( p_ClassPrimary[ playerid ], GetWeaponModel( weaponid ) );
	TextDrawSetPreviewRot( p_ClassPrimary[ playerid ], -16.000000, 0.000000, 180.000000, 4.000000 );
	TextDrawShowForPlayer( playerid, p_ClassPrimary[ playerid ] );
	UpdateClassSetupTD( playerid );
}


stock UpdateClassSetupTD( playerid )
{
	static
	 	primary, secondary, classid,
	 	szString[ 256 ];

	classid = p_cac_SelectedClass[ playerid ];

	switch( classid )
	{
		case 0: primary = g_userData[ playerid ] [ E_PRIMARY1 ], secondary = g_userData[ playerid ] [ E_SECONDARY1 ];
		case 1: primary = g_userData[ playerid ] [ E_PRIMARY2 ], secondary = g_userData[ playerid ] [ E_SECONDARY2 ];
		case 2: primary = g_userData[ playerid ] [ E_PRIMARY3 ], secondary = g_userData[ playerid ] [ E_SECONDARY3 ];
	}

	format( szString, sizeof( szString ), "~g~PRIMARY:~w~ %s~n~~g~SECONDARY:~w~ %s~n~~g~PERK 1:~w~ %s~n~~g~PERK 2:~w~ %s~n~~g~EQUIPMENT:~w~ %s", ReturnWeaponName( primary ), ReturnWeaponName( secondary ), PerkToString( g_userData[ playerid ] [ E_PERK_ONE ] [ classid ], true ), PerkToString( g_userData[ playerid ] [ E_PERK_TWO ] [ classid ], false ), SpecialToString( g_userData[ playerid ] [ E_SPECIAL ] [ classid ] ) );
	TextDrawSetString( p_ClassSetupTD[ playerid ], szString );

	format( szString, sizeof( szString ), "~r~KS 1:~w~  %s~n~~r~KS 2:~w~ %s~n~~r~KS 3:~w~ %s", KillstreakToString( g_userData[ playerid ] [ E_KILLSTREAK1 ] ), KillstreakToString( g_userData[ playerid ] [ E_KILLSTREAK2 ] ), KillstreakToString( g_userData[ playerid ] [ E_KILLSTREAK3 ] ) );
	TextDrawSetString( p_KillstreakSetupTD[ playerid ], szString );
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	if ( _:playertextid == INVALID_TEXT_DRAW || playerid == INVALID_PLAYER_ID )
		return 0;

	new type = p_SelectedOption{ playerid };

	if ( type == MENU_PRIMARY )
	{
		switch( _:playertextid )
		{
         	case 0:
			{
             	ChangePrimaryOnSelectedSlot( playerid, WEAPON_MP5 );
             	SendServerMessage(playerid, "You have changed the primary of this class to an MP5");
			}
			case 1:
            {
            	if ( g_userData[ playerid ] [ E_RANK ] > 9 )
				{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_SHOTGUN );
                 	SendServerMessage( playerid, "You have changed the primary of this class to a Shotgun" );
             	}
             	else SendError( playerid, "You have to be at least rank 10 to use this" );
			}
          	case 2:
         	{
             	if ( g_userData[ playerid ] [ E_RANK ] > 14 )
		 		{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_AK47 );
                   	SendServerMessage(playerid, "You have changed the primary of this class to an AK-47");
              	}
              	else SendError(playerid, "You have to be at least rank 15 to use this");
       		}
           	case 3:
          	{
             	if ( g_userData[ playerid ] [ E_RANK ] > 19 )
		 		{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_M4 );
                   	SendServerMessage(playerid, "You have changed the primary of this class to an M4");
				}
               	else SendError(playerid, "You have to be at least rank 20 to use this");
       		}
          	case 4:
       		{
             	if ( g_userData[ playerid ] [ E_RANK ] > 22 )
		 		{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_SHOTGSPA );
                 	SendServerMessage(playerid, "You have changed the primary of this class to a Spas-12");
       			}
              	else SendError(playerid, "You have to be at least rank 23 to use this");
           	}
           	case 5:
           	{
           		if ( g_userData[ playerid ] [ E_RANK ] > 24 )
				{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_SAWEDOFF );
               		SendServerMessage(playerid, "You have changed the primary of this class to a Sawn-off shotgun");
               	}
               	else SendError(playerid, "You have to be at least rank 25 to use this");
          	}
         	case 6:
       		{
           		if ( g_userData[ playerid ] [ E_RANK ] > 27 )
				{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_RIFLE );
                  	SendServerMessage(playerid, "You have changed the primary of this class to a M14");
            	}
          		else SendError(playerid, "You have to be at least rank 28 to use this");
        	}
         	case 7:
      		{
          		if ( g_userData[ playerid ] [ E_RANK ] > 29 )
				{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_SNIPER );
                  	SendServerMessage(playerid, "You have changed the primary of this class to a L118A (Sniper)");
               	}
             	else SendError(playerid, "You have to be at least rank 30 to use this");
          	}
        	case 8:
        	{
           		if ( g_userData[ playerid ] [ E_RANK ] > 34 )
				{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_UZI );
                  	SendServerMessage(playerid, "You have changed the primary of this class to an Uzi");
             	}
             	else SendError(playerid, "You have to be at least rank 35 to use this");
          	}
           	case 9:
        	{
               	if ( g_userData[ playerid ] [ E_RANK ] > 40 )
				{
             		ChangePrimaryOnSelectedSlot( playerid, WEAPON_TEC9 );
               		SendServerMessage(playerid, "You have changed the primary of this class to an FMG9");
              	}
             	else SendError(playerid, "You have to be at least rank 41 to use this");
          	}
        }
	}
	else if ( type == MENU_SECONDARY )
	{
		switch( _:playertextid )
		{
			case 0:
			{
			 	ChangeSecondaryOnSelectedSlot( playerid, WEAPON_SILENCED );
			 	SendServerMessage(playerid, "You have changed the secondary of this class to a USP (Silenced)");
			}
			case 1:
			{
			  	if ( g_userData[ playerid ] [ E_RANK ] > 9 )
				{
			 		ChangeSecondaryOnSelectedSlot( playerid, WEAPON_COLT45 );
					SendServerMessage(playerid, "You have changed the secondary of this class to a Five-Seven");
				}
				else SendError(playerid, "You have to be at least rank 10 to use this");
			}
			case 2:
			{
			  	if ( g_userData[ playerid ] [ E_RANK ] > 24 )
				{
			 		ChangeSecondaryOnSelectedSlot( playerid, WEAPON_DEAGLE );
			       	SendServerMessage( playerid, "You have changed the secondary of this class to a Desert Eagle." );
				}
				else SendError( playerid, "You have to be at least rank 25 to use this" );
			}
		}
	}
	else if ( type == MENU_PERKS )
	{
		new test = _:playertextid;
		new listitem = test >= 5 ? test - 5 : test;

        if ( g_userData[ playerid ] [ E_RANK ] >= ( listitem * 5 ) )
        {
        	if ( _:playertextid >= 5 )
        	{
				g_userData[ playerid ] [ E_PERK_TWO ] [ p_cac_SelectedClass[ playerid ] ] = listitem;
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your second perk to %s", PerkToString( listitem, false ) );
				SelectionHelp::Perks( playerid, listitem, false );
        	}
			else
			{
				g_userData[ playerid ] [ E_PERK_ONE ] [ p_cac_SelectedClass[ playerid ] ] = listitem;
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your first perk to %s", PerkToString( listitem, true ) );
				SelectionHelp::Perks( playerid, listitem, true );
			}
        	UpdateClassSetupTD( playerid );
		}
		else SendClientMessageFormatted( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You have to be at least rank %d to use this.", listitem * 5 );
	}
	else if ( type == MENU_KILLSTREAKS )
	{
        switch( p_cac_SelectedKillStreak[ playerid ] )
        {
            case 0:
			{
				if ( g_userData[ playerid ] [ E_KILLSTREAK2 ] == _:playertextid || g_userData[ playerid ] [ E_KILLSTREAK3 ] == _:playertextid )
					return SendError( playerid, "This killstreak is used on another killstreak slot." );

				g_userData[ playerid ] [ E_KILLSTREAK1 ] = _:playertextid;
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your first killstreak slot to %s", KillstreakToString( _:playertextid ) );
				SelectionHelp::Killstreaks( playerid, _:playertextid );
        		UpdateClassSetupTD( playerid );
			}
			case 1:
			{
				if ( g_userData[ playerid ] [ E_KILLSTREAK1 ] == _:playertextid || g_userData[ playerid ] [ E_KILLSTREAK3 ] == _:playertextid )
			 		return SendError( playerid, "This killstreak is used on another killstreak slot." );

				g_userData[ playerid ] [ E_KILLSTREAK2 ] = _:playertextid;
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your second killstreak slot to %s", KillstreakToString( _:playertextid ) );
				SelectionHelp::Killstreaks( playerid, _:playertextid );
        		UpdateClassSetupTD( playerid );
			}
			case 2:
			{
				if ( g_userData[ playerid ] [ E_KILLSTREAK1 ] == _:playertextid || g_userData[ playerid ] [ E_KILLSTREAK2 ] == _:playertextid )
				 	return SendError( playerid, "This killstreak is used on another killstreak slot." );

				g_userData[ playerid ] [ E_KILLSTREAK3 ] = _:playertextid;
				SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your third killstreak slot to %s", KillstreakToString( _:playertextid ) );
				SelectionHelp::Killstreaks( playerid, _:playertextid );
        		UpdateClassSetupTD( playerid );
			}
        }

	}
	else if ( type == MENU_SPECIAL )
	{
    	if ( g_userData[ playerid ] [ E_RANK ] >= ( _:playertextid * 4 ) )
    	{
			g_userData[ playerid ] [ E_SPECIAL ] [ p_cac_SelectedClass[ playerid ] ] = _:playertextid;
			SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have changed your equipment to %s", SpecialToString( _:playertextid ) );
			SelectionHelp::Equipment( playerid, _:playertextid );
        	UpdateClassSetupTD( playerid );
		}
		else SendClientMessageFormatted( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You have to be at least rank %d to use this", _:playertextid * 4 );
	}
    return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if ( _:clickedid == INVALID_TEXT_DRAW || playerid == INVALID_PLAYER_ID )
	{
		if ( GetPVarInt( playerid, "inGameMenu" ) )
		{
			SelectTextDraw( playerid, 0x999999FF );
		}
		return 0;
	}

	if ( clickedid == p_ClassPrimary[ playerid ] ) 	if ( p_SelectedOption{ playerid } != MENU_PRIMARY ) CreateDetailedMenu( playerid, MENU_PRIMARY );
	if ( clickedid == p_ClassSecondary[ playerid ] ) if ( p_SelectedOption{ playerid } != MENU_SECONDARY ) CreateDetailedMenu( playerid, MENU_SECONDARY );
	if ( clickedid == g_ClassConfig[ 0 ] )			if ( p_SelectedOption{ playerid } != MENU_PERKS ) CreateDetailedMenu( playerid, MENU_PERKS );
	if ( clickedid == g_ClassConfig[ 1 ] )			if ( p_SelectedOption{ playerid } != MENU_KILLSTREAKS ) CreateDetailedMenu( playerid, MENU_KILLSTREAKS ), p_cac_SelectedKillStreak[ playerid ] = 0, SendServerMessage( playerid, "You are now editing killstreak slot 1." );
	if ( clickedid == g_ClassConfig[ 2 ] ) 			if ( p_SelectedOption{ playerid } != MENU_SPECIAL ) CreateDetailedMenu( playerid, MENU_SPECIAL );
	if ( clickedid == g_ClassConfig[ 4 ] )			ShowPlayerDialog( playerid, DIALOG_RENAME, DIALOG_STYLE_INPUT, "{FFFFFF}Rename Class", ""COL_WHITE"What would you like to rename this class as?", "Rename", "Cancel" );
	if ( clickedid == g_ClassConfig[ 5 ] )			StopPlayerEditingCreateClass( playerid );

	if ( clickedid == g_ClassKSSlots[ 0 ] )			p_cac_SelectedKillStreak[ playerid ] = 0, SendServerMessage( playerid, "You are now editing killstreak slot 1." );
	if ( clickedid == g_ClassKSSlots[ 1 ] )			p_cac_SelectedKillStreak[ playerid ] = 1, SendServerMessage( playerid, "You are now editing killstreak slot 2." );
	if ( clickedid == g_ClassKSSlots[ 2 ] )			p_cac_SelectedKillStreak[ playerid ] = 2, SendServerMessage( playerid, "You are now editing killstreak slot 3." );

	if ( clickedid == g_GameMenuTD[ 0 ] )
	{
		if ( Iter_Count(mp_players) > 48 )
			return SendError( playerid, "This gamemode is completely full. Play another?" );

		CloseGameMenu( playerid );
		AlterModePlayers( playerid, MODE_MULTIPLAYER );
		ShowMainMenu( playerid );
	}
	if ( clickedid == g_GameMenuTD[ 1 ] )
	{

		if ( Iter_Count(zm_players) > 24 )
			return SendError( playerid, "This gamemode is completely full. Play another?" );

		CloseGameMenu( playerid );
		AlterModePlayers( playerid, MODE_ZOMBIES );
		ShowMainMenu( playerid );
	}
	if ( clickedid == g_GameMenuTD[ 2 ] ) 			CloseGameMenu( playerid ), ShowPlayerDialog( playerid, DIALOG_MODIFY_ACCOUNT, DIALOG_STYLE_LIST, ""#DIALOG_TITLE" - Account Settings", "View Statistics\n{F2F2F2}Change Password\n{E5E5E5}Reset Statistics\n{C0C0C0}Hitmarker Options", "Select", "Back" );
    return 1;
}

stock AlterModePlayers( playerid, new_mode )
{
	switch( new_mode )
	{
		case MODE_MULTIPLAYER:
		{
			if (Iter_Contains(zm_players, playerid))
				Iter_Remove(zm_players, playerid);

			Iter_Add(mp_players, playerid);
		}
		case MODE_ZOMBIES:
		{
			if (Iter_Contains(mp_players, playerid))
				Iter_Remove(mp_players, playerid);

			Iter_Add(zm_players, playerid);
		}
		default:
		{
			Iter_Remove(mp_players, playerid);
			Iter_Remove(zm_players, playerid);
		}
	}
}

stock SetCustomizeClass( playerid, classid )
{
	new
		primary, secondary;

	switch( classid )
	{
		case 0:
		{
			primary = g_userData[ playerid ] [ E_PRIMARY1 ];
			secondary = g_userData[ playerid ] [ E_SECONDARY1 ];
			TextDrawSetString( p_ClassName[ playerid ], g_userData[ playerid ] [ E_CLASS1 ] );
		}
		case 1:
		{
			primary = g_userData[ playerid ] [ E_PRIMARY2 ];
			secondary = g_userData[ playerid ] [ E_SECONDARY2 ];
			TextDrawSetString( p_ClassName[ playerid ], g_userData[ playerid ] [ E_CLASS2 ] );
		}
		case 2:
		{
			primary = g_userData[ playerid ] [ E_PRIMARY3 ];
			secondary = g_userData[ playerid ] [ E_SECONDARY3 ];
			TextDrawSetString( p_ClassName[ playerid ], g_userData[ playerid ] [ E_CLASS3 ] );
		}
	}

	SetPVarInt( playerid, "editing_class", 1 );
	SelectTextDraw( playerid, 0xFFFFFFFF );
	p_SelectedOption{ playerid } = -1;

	TextDrawSetPreviewModel( p_ClassPrimary[ playerid ], GetWeaponModel( primary ) );
	TextDrawSetPreviewRot( p_ClassPrimary[ playerid ], -16.000000, 0.000000, 180.000000, 4.000000 );

	TextDrawSetPreviewModel( p_ClassSecondary[ playerid ], GetWeaponModel( secondary ) );
	TextDrawSetPreviewRot( p_ClassSecondary[ playerid ], -16.000000, 0.000000, 180.000000, 1.500000 );

	TextDrawShowForPlayer( playerid, p_ClassName[ playerid ] );
	TextDrawShowForPlayer( playerid, p_ClassPrimary[ playerid ] );
	TextDrawShowForPlayer( playerid, p_ClassSecondary[ playerid ] );
	TextDrawShowForPlayer( playerid, g_ClassConfig[ 0 ] );
	TextDrawShowForPlayer( playerid, g_ClassConfig[ 1 ] );
	TextDrawShowForPlayer( playerid, g_ClassConfig[ 2 ] );
	TextDrawHideForPlayer( playerid, g_ClassConfig[ 3 ] );
	TextDrawShowForPlayer( playerid, g_ClassConfig[ 4 ] );
	TextDrawShowForPlayer( playerid, g_ClassConfig[ 5 ] );
	TextDrawShowForPlayer( playerid, g_ClassCustom[ 0 ] );
	TextDrawShowForPlayer( playerid, g_ClassCustom[ 1 ] );
	TextDrawShowForPlayer( playerid, g_ClassCustom[ 2 ] );
	TextDrawShowForPlayer( playerid, g_ClassCustom[ 3 ] );
	TextDrawShowForPlayer( playerid, g_ClassCustom[ 4 ] );
	TextDrawShowForPlayer( playerid, g_ClassCustom[ 5 ] );
	TextDrawShowForPlayer( playerid, g_ClassCustom[ 6 ] );

	UpdateClassSetupTD( playerid );
	TextDrawShowForPlayer( playerid, p_ClassSetupTD[ playerid ] );
	TextDrawShowForPlayer( playerid, p_KillstreakSetupTD[ playerid ] );
}

stock CreateDetailedMenu( playerid, type )
{
	if ( _: p_ClassOptions[ 0 ] != INVALID_TEXT_DRAW )
	{
		for( new x; x < sizeof( p_ClassOptions ); x++ )
			PlayerTextDrawDestroy( playerid, p_ClassOptions[ x ] );
	}
	p_SelectedOption{ playerid } = type;

	TextDrawHideForPlayer( playerid, g_ClassConfig[ 3 ] );
	TextDrawHideForPlayer( playerid, g_ClassKSSlots[ 0 ] );
	TextDrawHideForPlayer( playerid, g_ClassKSSlots[ 1 ] );
	TextDrawHideForPlayer( playerid, g_ClassKSSlots[ 2 ] );

	if ( type == MENU_PERKS ) 			TextDrawShowForPlayer( playerid, g_ClassConfig[ 3 ] );
	else if ( type == MENU_KILLSTREAKS ) TextDrawShowForPlayer( playerid, g_ClassKSSlots[ 0 ] ), TextDrawShowForPlayer( playerid, g_ClassKSSlots[ 1 ] ), TextDrawShowForPlayer( playerid, g_ClassKSSlots[ 2 ] );

	for( new i = 0, Float: Height = 130, szString[ 32 ]; i < g_MenuMaximumIterations[ type ]; i++ )
	{
		Height += 14;

		switch( type )
		{
			case MENU_PRIMARY, MENU_SECONDARY: format( szString, sizeof( szString ), "%s", ReturnWeaponName( g_MenuType[ type ] [ i ] ) );
			case MENU_PERKS: format( szString, sizeof( szString ), "%s%s", i >= 5 ? ("~r~") : ("~g~"), PerkToString( g_MenuType[ type ] [ i ], i >= 5 ? false : true ) );
			case MENU_KILLSTREAKS: format( szString, sizeof( szString ), "%s", KillstreakToString( g_MenuType[ type ] [ i ] ) );
			case MENU_SPECIAL: format( szString, sizeof( szString ), "%s", SpecialToString( g_MenuType[ type ] [ i ] ) );
		}

		p_ClassOptions[ i ] = CreatePlayerTextDraw(playerid, 183.000000, Height, szString );
		PlayerTextDrawBackgroundColor(playerid, p_ClassOptions[ i ], 255);
		PlayerTextDrawFont(playerid, p_ClassOptions[ i ], 2);
		PlayerTextDrawLetterSize(playerid, p_ClassOptions[ i ], 0.189999, 1.099998);
		PlayerTextDrawColor(playerid, p_ClassOptions[ i ], -1);
		PlayerTextDrawSetOutline(playerid, p_ClassOptions[ i ], 1);
		PlayerTextDrawSetProportional(playerid, p_ClassOptions[ i ], 1);
		PlayerTextDrawUseBox(playerid, p_ClassOptions[ i ], 1);
		PlayerTextDrawBoxColor(playerid, p_ClassOptions[ i ], 96);
		PlayerTextDrawTextSize(playerid, p_ClassOptions[ i ], 300.000000, 110.000000);
		PlayerTextDrawSetSelectable(playerid, p_ClassOptions[ i ], 1);
		PlayerTextDrawShow(playerid, p_ClassOptions[ i ]);
	}

}

stock cod_TextDraws( )
{
	g_MotdTD = TextDrawCreate(634.000000, 432.000000, "_");
	TextDrawAlignment(g_MotdTD, 3);
	TextDrawBackgroundColor(g_MotdTD, 255);
	TextDrawFont(g_MotdTD, 2);
	TextDrawLetterSize(g_MotdTD, 0.209999, 1.200000);
	TextDrawColor(g_MotdTD, -1);
	TextDrawSetOutline(g_MotdTD, 1);
	TextDrawSetProportional(g_MotdTD, 1);
	TextDrawSetSelectable(g_MotdTD, 0);

	g_BittenBoxTD = TextDrawCreate(760.000000, -130.000000, "_");
	TextDrawBackgroundColor(g_BittenBoxTD, 255);
	TextDrawLetterSize(g_BittenBoxTD, 1000.000000, 1000.000000);
	TextDrawUseBox(g_BittenBoxTD, 1);
	TextDrawBoxColor(g_BittenBoxTD, -16777136);
	TextDrawTextSize(g_BittenBoxTD, -40.000000, 30.000000);

	g_SpectateBoxTD = TextDrawCreate(-50.000000, 340.000000, "_");
	TextDrawBackgroundColor(g_SpectateBoxTD, 255);
	TextDrawFont(g_SpectateBoxTD, 1);
	TextDrawLetterSize(g_SpectateBoxTD, 0.500000, 14.000000);
	TextDrawColor(g_SpectateBoxTD, -1);
	TextDrawSetOutline(g_SpectateBoxTD, 0);
	TextDrawSetProportional(g_SpectateBoxTD, 1);
	TextDrawSetShadow(g_SpectateBoxTD, 1);
	TextDrawUseBox(g_SpectateBoxTD, 1);
	TextDrawBoxColor(g_SpectateBoxTD, 80);
	TextDrawTextSize(g_SpectateBoxTD, 710.000000, 0.000000);

    g_RankBoxTD = TextDrawCreate(494.000000, 384.000000, "_");
	TextDrawBackgroundColor(g_RankBoxTD, 255);
	TextDrawFont(g_RankBoxTD, 1);
	TextDrawLetterSize(g_RankBoxTD, 0.500000, 4.000000);
	TextDrawColor(g_RankBoxTD, -1);
	TextDrawSetOutline(g_RankBoxTD, 0);
	TextDrawSetProportional(g_RankBoxTD, 1);
	TextDrawSetShadow(g_RankBoxTD, 1);
	TextDrawUseBox(g_RankBoxTD, 1);
	TextDrawBoxColor(g_RankBoxTD, 117);
	TextDrawTextSize(g_RankBoxTD, 630.000000, 0.000000);

	g_RankTD = TextDrawCreate(470.000000, 371.000000, "ld_drv:goboat");
	TextDrawBackgroundColor(g_RankTD, 255);
	TextDrawFont(g_RankTD, 4);
	TextDrawLetterSize(g_RankTD, 0.500000, 1.000000);
	TextDrawColor(g_RankTD, -65281);
	TextDrawSetOutline(g_RankTD, 0);
	TextDrawSetProportional(g_RankTD, 1);
	TextDrawSetShadow(g_RankTD, 1);
	TextDrawUseBox(g_RankTD, 1);
	TextDrawBoxColor(g_RankTD, -65281);
	TextDrawTextSize(g_RankTD, 50.000000, 60.000000);

	g_EvacuationTD = TextDrawCreate(515.000000, 368.000000, "~g~~h~Time Till Evacuation:~w~ 99:99");
	TextDrawBackgroundColor(g_EvacuationTD, 255);
	TextDrawFont(g_EvacuationTD, 1);
	TextDrawLetterSize(g_EvacuationTD, 0.240000, 1.300000);
	TextDrawColor(g_EvacuationTD, -1);
	TextDrawSetOutline(g_EvacuationTD, 1);
	TextDrawSetProportional(g_EvacuationTD, 1);

	g_GameMenuTD[ 0 ] = TextDrawCreate(137.000000, 162.000000, "MULTIPLAYER");
	TextDrawAlignment(g_GameMenuTD[ 0 ], 2);
	TextDrawBackgroundColor(g_GameMenuTD[ 0 ], 255);
	TextDrawFont(g_GameMenuTD[ 0 ], 1);
	TextDrawLetterSize(g_GameMenuTD[ 0 ], 0.500000, 2.000000);
	TextDrawColor(g_GameMenuTD[ 0 ], -1);
	TextDrawSetOutline(g_GameMenuTD[ 0 ], 0);
	TextDrawSetProportional(g_GameMenuTD[ 0 ], 1);
	TextDrawSetShadow(g_GameMenuTD[ 0 ], 0);
	TextDrawUseBox(g_GameMenuTD[ 0 ], 1);
	TextDrawBoxColor(g_GameMenuTD[ 0 ], 117);
	TextDrawTextSize(g_GameMenuTD[ 0 ], 16.000000, 180.000000);
	TextDrawSetSelectable(g_GameMenuTD[ 0 ], 1);

	g_GameMenuTD[ 1 ] = TextDrawCreate(137.000000, 192.000000, "ZOMBIES");
	TextDrawAlignment(g_GameMenuTD[ 1 ], 2);
	TextDrawBackgroundColor(g_GameMenuTD[ 1 ], 255);
	TextDrawFont(g_GameMenuTD[ 1 ], 1);
	TextDrawLetterSize(g_GameMenuTD[ 1 ], 0.500000, 2.000000);
	TextDrawColor(g_GameMenuTD[ 1 ], -1);
	TextDrawSetOutline(g_GameMenuTD[ 1 ], 0);
	TextDrawSetProportional(g_GameMenuTD[ 1 ], 1);
	TextDrawSetShadow(g_GameMenuTD[ 1 ], 0);
	TextDrawUseBox(g_GameMenuTD[ 1 ], 1);
	TextDrawBoxColor(g_GameMenuTD[ 1 ], 117);
	TextDrawTextSize(g_GameMenuTD[ 1 ], 16.000000, 180.000000);
	TextDrawSetSelectable(g_GameMenuTD[ 1 ], 1);

	g_GameMenuTD[ 2 ] = TextDrawCreate(137.000000, 222.000000, "SETTINGS");
	TextDrawAlignment(g_GameMenuTD[ 2 ], 2);
	TextDrawBackgroundColor(g_GameMenuTD[ 2 ], 255);
	TextDrawFont(g_GameMenuTD[ 2 ], 1);
	TextDrawLetterSize(g_GameMenuTD[ 2 ], 0.500000, 2.000000);
	TextDrawColor(g_GameMenuTD[ 2 ], -1);
	TextDrawSetOutline(g_GameMenuTD[ 2 ], 0);
	TextDrawSetProportional(g_GameMenuTD[ 2 ], 1);
	TextDrawSetShadow(g_GameMenuTD[ 2 ], 0);
	TextDrawUseBox(g_GameMenuTD[ 2 ], 1);
	TextDrawBoxColor(g_GameMenuTD[ 2 ], 117);
	TextDrawTextSize(g_GameMenuTD[ 2 ], 16.000000, 180.000000);
	TextDrawSetSelectable(g_GameMenuTD[ 2 ], 1);

	g_GameMenuTD[ 3 ] = TextDrawCreate(212.000000, 171.000000, "24 / 24");
	TextDrawAlignment(g_GameMenuTD[ 3 ], 2);
	TextDrawBackgroundColor(g_GameMenuTD[ 3 ], 255);
	TextDrawFont(g_GameMenuTD[ 3 ], 1);
	TextDrawLetterSize(g_GameMenuTD[ 3 ], 0.170000, 0.799999);
	TextDrawColor(g_GameMenuTD[ 3 ], -1);
	TextDrawSetProportional(g_GameMenuTD[ 3 ], 1);
	TextDrawSetShadow(g_GameMenuTD[ 3 ], 0);
	TextDrawSetSelectable(g_GameMenuTD[ 3 ], 0);

	g_GameMenuTD[ 4 ] = TextDrawCreate(212.000000, 201.000000, "24 / 24");
	TextDrawAlignment(g_GameMenuTD[ 4 ], 2);
	TextDrawBackgroundColor(g_GameMenuTD[ 4 ], 255);
	TextDrawFont(g_GameMenuTD[ 4 ], 1);
	TextDrawLetterSize(g_GameMenuTD[ 4 ], 0.170000, 0.799999);
	TextDrawColor(g_GameMenuTD[ 4 ], -1);
	TextDrawSetProportional(g_GameMenuTD[ 4 ], 1);
	TextDrawSetShadow(g_GameMenuTD[ 4 ], 0);
	TextDrawSetSelectable(g_GameMenuTD[ 4 ], 0);

	g_HideCashBoxTD = TextDrawCreate(500.000000, 81.000000, "_~n~_");
	TextDrawBackgroundColor(g_HideCashBoxTD, 255);
	TextDrawFont(g_HideCashBoxTD, 1);
	TextDrawLetterSize(g_HideCashBoxTD, 0.479999, 0.899999);
	TextDrawColor(g_HideCashBoxTD, -1);
	TextDrawSetOutline(g_HideCashBoxTD, 0);
	TextDrawSetProportional(g_HideCashBoxTD, 1);
	TextDrawSetShadow(g_HideCashBoxTD, 1);
	TextDrawUseBox(g_HideCashBoxTD, 1);
	TextDrawBoxColor(g_HideCashBoxTD, 255);
	TextDrawTextSize(g_HideCashBoxTD, 605.000000, 0.000000);
	TextDrawSetSelectable(g_HideCashBoxTD, 0);

    g_PromotedTD = TextDrawCreate(261.000000, 136.000000, "Promoted!");
	TextDrawBackgroundColor(g_PromotedTD, 255);
	TextDrawFont(g_PromotedTD, 2);
	TextDrawLetterSize(g_PromotedTD, 0.539999, 2.399998);
	TextDrawColor(g_PromotedTD, -1);
	TextDrawSetOutline(g_PromotedTD, 0);
	TextDrawSetProportional(g_PromotedTD, 1);
	TextDrawSetShadow(g_PromotedTD, 1);
	TextDrawUseBox(g_PromotedTD, 0 );

	g_WebsiteTD[ 0 ] = TextDrawCreate(33.000000, 427.000000, "www.IrresistibleGaming.com");
	TextDrawBackgroundColor(g_WebsiteTD[ 0 ], 255);
	TextDrawFont(g_WebsiteTD[ 0 ], 1);
	TextDrawLetterSize(g_WebsiteTD[ 0 ], 0.220000, 1.200000);
	TextDrawColor(g_WebsiteTD[ 0 ], 1289224191);
	TextDrawSetOutline(g_WebsiteTD[ 0 ], 1);
	TextDrawSetProportional(g_WebsiteTD[ 0 ], 1);

	g_WebsiteTD[ 1 ] = TextDrawCreate(524.000000, 408.000000, "www.IrresistibleGaming.com");
	TextDrawBackgroundColor(g_WebsiteTD[ 1 ], 255);
	TextDrawFont(g_WebsiteTD[ 1 ], 1);
	TextDrawLetterSize(g_WebsiteTD[ 1 ], 0.210000, 1.100000);
	TextDrawColor(g_WebsiteTD[ 1 ], 11206655);
	TextDrawSetOutline(g_WebsiteTD[ 1 ], 1);
	TextDrawSetProportional(g_WebsiteTD[ 1 ], 1);

	g_ClassCustom[ 0 ] = TextDrawCreate(20.000000, 144.000000, "_");
	TextDrawBackgroundColor(g_ClassCustom[ 0 ], 255);
	TextDrawFont(g_ClassCustom[ 0 ], 1);
	TextDrawLetterSize(g_ClassCustom[ 0 ], 0.500000, 10.899999);
	TextDrawColor(g_ClassCustom[ 0 ], -1);
	TextDrawSetOutline(g_ClassCustom[ 0 ], 0);
	TextDrawSetProportional(g_ClassCustom[ 0 ], 1);
	TextDrawSetShadow(g_ClassCustom[ 0 ], 1);
	TextDrawUseBox(g_ClassCustom[ 0 ], 1);
	TextDrawBoxColor(g_ClassCustom[ 0 ], 96);
	TextDrawTextSize(g_ClassCustom[ 0 ], 170.000000, 110.000000);
	TextDrawSetSelectable(g_ClassCustom[ 0 ], 0);

	g_ClassCustom[ 1 ] = TextDrawCreate(24.000000, 149.000000, "Primary~n~~n~~n~~n~Secondary");
	TextDrawBackgroundColor(g_ClassCustom[ 1 ], 255);
	TextDrawFont(g_ClassCustom[ 1 ], 2);
	TextDrawLetterSize(g_ClassCustom[ 1 ], 0.220000, 1.100000);
	TextDrawColor(g_ClassCustom[ 1 ], -1);
	TextDrawSetOutline(g_ClassCustom[ 1 ], 1);
	TextDrawSetProportional(g_ClassCustom[ 1 ], 1);
	TextDrawSetSelectable(g_ClassCustom[ 1 ], 0);

	g_ClassCustom[ 2 ] = TextDrawCreate(20.000000, 265.000000, "_");
	TextDrawBackgroundColor(g_ClassCustom[ 2 ], 255);
	TextDrawFont(g_ClassCustom[ 2 ], 1);
	TextDrawLetterSize(g_ClassCustom[ 2 ], 0.500000, 5.899999);
	TextDrawColor(g_ClassCustom[ 2 ], -1);
	TextDrawSetOutline(g_ClassCustom[ 2 ], 0);
	TextDrawSetProportional(g_ClassCustom[ 2 ], 1);
	TextDrawSetShadow(g_ClassCustom[ 2 ], 1);
	TextDrawUseBox(g_ClassCustom[ 2 ], 1);
	TextDrawBoxColor(g_ClassCustom[ 2 ], 96);
	TextDrawTextSize(g_ClassCustom[ 2 ], 170.000000, 110.000000);
	TextDrawSetSelectable(g_ClassCustom[ 2 ], 0);

	g_ClassCustom[ 3 ] = TextDrawCreate(15.000000, 254.000000, "Perks - Strike Package - Equipment");
	TextDrawBackgroundColor(g_ClassCustom[ 3 ], 255);
	TextDrawFont(g_ClassCustom[ 3 ], 0);
	TextDrawLetterSize(g_ClassCustom[ 3 ], 0.339999, 1.300000);
	TextDrawColor(g_ClassCustom[ 3 ], -1);
	TextDrawSetOutline(g_ClassCustom[ 3 ], 1);
	TextDrawSetProportional(g_ClassCustom[ 3 ], 1);
	TextDrawSetSelectable(g_ClassCustom[ 3 ], 0);

	g_ClassCustom[ 4 ] = TextDrawCreate(621.000000, 301.000000, "_");
	TextDrawBackgroundColor(g_ClassCustom[ 4 ], 255);
	TextDrawFont(g_ClassCustom[ 4 ], 1);
	TextDrawLetterSize(g_ClassCustom[ 4 ], 0.800000, 4.200001);
	TextDrawColor(g_ClassCustom[ 4 ], -1);
	TextDrawSetOutline(g_ClassCustom[ 4 ], 0);
	TextDrawSetProportional(g_ClassCustom[ 4 ], 1);
	TextDrawSetShadow(g_ClassCustom[ 4 ], 1);
	TextDrawUseBox(g_ClassCustom[ 4 ], 1);
	TextDrawBoxColor(g_ClassCustom[ 4 ], 96);
	TextDrawTextSize(g_ClassCustom[ 4 ], 452.000000, 11.000000);
	TextDrawSetSelectable(g_ClassCustom[ 4 ], 0);

	g_ClassCustom[ 5 ] = TextDrawCreate(621.000000, 227.000000, "_");
	TextDrawBackgroundColor(g_ClassCustom[ 5 ], 255);
	TextDrawFont(g_ClassCustom[ 5 ], 1);
	TextDrawLetterSize(g_ClassCustom[ 5 ], 0.800000, 7.099999);
	TextDrawColor(g_ClassCustom[ 5 ], -1);
	TextDrawSetOutline(g_ClassCustom[ 5 ], 0);
	TextDrawSetProportional(g_ClassCustom[ 5 ], 1);
	TextDrawSetShadow(g_ClassCustom[ 5 ], 1);
	TextDrawUseBox(g_ClassCustom[ 5 ], 1);
	TextDrawBoxColor(g_ClassCustom[ 5 ], 96);
	TextDrawTextSize(g_ClassCustom[ 5 ], 452.000000, 11.000000);
	TextDrawSetSelectable(g_ClassCustom[ 5 ], 0);

	g_ClassCustom[ 6 ] = TextDrawCreate(450.000000, 217.000000, "What's active?");
	TextDrawBackgroundColor(g_ClassCustom[ 6 ], 255);
	TextDrawFont(g_ClassCustom[ 6 ], 0);
	TextDrawLetterSize(g_ClassCustom[ 6 ], 0.460000, 1.399999);
	TextDrawColor(g_ClassCustom[ 6 ], -1965144065);
	TextDrawSetOutline(g_ClassCustom[ 6 ], 1);
	TextDrawSetProportional(g_ClassCustom[ 6 ], 1);
	TextDrawSetSelectable(g_ClassCustom[ 6 ], 0);

	g_ClassConfig[ 0 ] = TextDrawCreate(28.000000, 277.000000, "hud:radar_mafiacasino");
	TextDrawBackgroundColor(g_ClassConfig[ 0 ], 255);
	TextDrawFont(g_ClassConfig[ 0 ], 4);
	TextDrawLetterSize(g_ClassConfig[ 0 ], 1.100000, 4.000000);
	TextDrawColor(g_ClassConfig[ 0 ], -1);
	TextDrawSetOutline(g_ClassConfig[ 0 ], 0);
	TextDrawSetProportional(g_ClassConfig[ 0 ], 1);
	TextDrawSetShadow(g_ClassConfig[ 0 ], 1);
	TextDrawUseBox(g_ClassConfig[ 0 ], 1);
	TextDrawBoxColor(g_ClassConfig[ 0 ], 255);
	TextDrawTextSize(g_ClassConfig[ 0 ], 30.000000, 30.000000);
	TextDrawSetSelectable(g_ClassConfig[ 0 ], 1);

	g_ClassConfig[ 1 ] = TextDrawCreate(78.000000, 277.000000, "hud:radar_locosyndicate");
	TextDrawBackgroundColor(g_ClassConfig[ 1 ], 255);
	TextDrawFont(g_ClassConfig[ 1 ], 4);
	TextDrawLetterSize(g_ClassConfig[ 1 ], 1.100000, 4.000000);
	TextDrawColor(g_ClassConfig[ 1 ], -1);
	TextDrawSetOutline(g_ClassConfig[ 1 ], 0);
	TextDrawSetProportional(g_ClassConfig[ 1 ], 1);
	TextDrawSetShadow(g_ClassConfig[ 1 ], 1);
	TextDrawUseBox(g_ClassConfig[ 1 ], 1);
	TextDrawBoxColor(g_ClassConfig[ 1 ], 255);
	TextDrawTextSize(g_ClassConfig[ 1 ], 30.000000, 30.000000);
	TextDrawSetSelectable(g_ClassConfig[ 1 ], 1);

	g_ClassConfig[ 2 ] = TextDrawCreate(129.000000, 277.000000, "hud:radar_emmetgun");
	TextDrawBackgroundColor(g_ClassConfig[ 2 ], 255);
	TextDrawFont(g_ClassConfig[ 2 ], 4);
	TextDrawLetterSize(g_ClassConfig[ 2 ], 1.100000, 4.000000);
	TextDrawColor(g_ClassConfig[ 2 ], -1);
	TextDrawSetOutline(g_ClassConfig[ 2 ], 0);
	TextDrawSetProportional(g_ClassConfig[ 2 ], 1);
	TextDrawSetShadow(g_ClassConfig[ 2 ], 1);
	TextDrawUseBox(g_ClassConfig[ 2 ], 1);
	TextDrawBoxColor(g_ClassConfig[ 2 ], 255);
	TextDrawTextSize(g_ClassConfig[ 2 ], 30.000000, 30.000000);
	TextDrawSetSelectable(g_ClassConfig[ 2 ], 1);

	g_ClassConfig[ 3 ] = TextDrawCreate(238.000000, 288.000000, "Each Colour Is A Different Slot");
	TextDrawAlignment(g_ClassConfig[ 3 ], 2);
	TextDrawBackgroundColor(g_ClassConfig[ 3 ], 255);
	TextDrawFont(g_ClassConfig[ 3 ], 2);
	TextDrawLetterSize(g_ClassConfig[ 3 ], 0.189998, 1.099997);
	TextDrawColor(g_ClassConfig[ 3 ], -291958273);
	TextDrawSetOutline(g_ClassConfig[ 3 ], 1);
	TextDrawSetProportional(g_ClassConfig[ 3 ], 1);
	TextDrawUseBox(g_ClassConfig[ 3 ], 1);
	TextDrawBoxColor(g_ClassConfig[ 3 ], -16777136);
	TextDrawTextSize(g_ClassConfig[ 3 ], 350.000000, 110.000000);
	TextDrawSetSelectable(g_ClassConfig[ 3 ], 0);

	g_ClassConfig[ 4 ] = TextDrawCreate(20.000000, 327.000000, "___________________Rename Class");
	TextDrawBackgroundColor(g_ClassConfig[ 4 ], 255);
	TextDrawFont(g_ClassConfig[ 4 ], 2);
	TextDrawLetterSize(g_ClassConfig[ 4 ], 0.189999, 1.100000);
	TextDrawColor(g_ClassConfig[ 4 ], -1);
	TextDrawSetOutline(g_ClassConfig[ 4 ], 1);
	TextDrawSetProportional(g_ClassConfig[ 4 ], 1);
	TextDrawUseBox(g_ClassConfig[ 4 ], 1);
	TextDrawBoxColor(g_ClassConfig[ 4 ], 96);
	TextDrawTextSize(g_ClassConfig[ 4 ], 170.000000, 110.000000);
	TextDrawSetSelectable(g_ClassConfig[ 4 ], 1);

	g_ClassConfig[ 5 ] = TextDrawCreate(217.000000, 373.000000, "Once you're finished, type /finish or click this!");
	TextDrawBackgroundColor(g_ClassConfig[ 5 ], 255);
	TextDrawFont(g_ClassConfig[ 5 ], 2);
	TextDrawLetterSize(g_ClassConfig[ 5 ], 0.189999, 1.100000);
	TextDrawColor(g_ClassConfig[ 5 ], -1);
	TextDrawSetOutline(g_ClassConfig[ 5 ], 1);
	TextDrawSetProportional(g_ClassConfig[ 5 ], 1);
	TextDrawUseBox(g_ClassConfig[ 5 ], 1);
	TextDrawBoxColor(g_ClassConfig[ 5 ], 144);
	TextDrawTextSize(g_ClassConfig[ 5 ], 430.000000, 155.000000);
	TextDrawSetSelectable(g_ClassConfig[ 5 ], 1);

	g_ClassKSSlots[ 0 ] = TextDrawCreate(306.000000, 144.000000, "Slot 1");
	TextDrawBackgroundColor(g_ClassKSSlots[ 0 ], 255);
	TextDrawFont(g_ClassKSSlots[ 0 ], 2);
	TextDrawLetterSize(g_ClassKSSlots[ 0 ], 0.189998, 1.099997);
	TextDrawColor(g_ClassKSSlots[ 0 ], -1);
	TextDrawSetOutline(g_ClassKSSlots[ 0 ], 1);
	TextDrawSetProportional(g_ClassKSSlots[ 0 ], 1);
	TextDrawUseBox(g_ClassKSSlots[ 0 ], 1);
	TextDrawBoxColor(g_ClassKSSlots[ 0 ], 96);
	TextDrawTextSize(g_ClassKSSlots[ 0 ], 350.000000, 110.000000);
	TextDrawSetSelectable(g_ClassKSSlots[ 0 ], 1);

	g_ClassKSSlots[ 1 ] = TextDrawCreate(306.000000, 158.000000, "Slot 2");
	TextDrawBackgroundColor(g_ClassKSSlots[ 1 ], 255);
	TextDrawFont(g_ClassKSSlots[ 1 ], 2);
	TextDrawLetterSize(g_ClassKSSlots[ 1 ], 0.189998, 1.099997);
	TextDrawColor(g_ClassKSSlots[ 1 ], -1);
	TextDrawSetOutline(g_ClassKSSlots[ 1 ], 1);
	TextDrawSetProportional(g_ClassKSSlots[ 1 ], 1);
	TextDrawUseBox(g_ClassKSSlots[ 1 ], 1);
	TextDrawBoxColor(g_ClassKSSlots[ 1 ], 96);
	TextDrawTextSize(g_ClassKSSlots[ 1 ], 350.000000, 110.000000);
	TextDrawSetSelectable(g_ClassKSSlots[ 1 ], 1);

	g_ClassKSSlots[ 2 ] = TextDrawCreate(306.000000, 172.000000, "Slot 3");
	TextDrawBackgroundColor(g_ClassKSSlots[ 2 ], 255);
	TextDrawFont(g_ClassKSSlots[ 2 ], 2);
	TextDrawLetterSize(g_ClassKSSlots[ 2 ], 0.189998, 1.099997);
	TextDrawColor(g_ClassKSSlots[ 2 ], -1);
	TextDrawSetOutline(g_ClassKSSlots[ 2 ], 1);
	TextDrawSetProportional(g_ClassKSSlots[ 2 ], 1);
	TextDrawUseBox(g_ClassKSSlots[ 2 ], 1);
	TextDrawBoxColor(g_ClassKSSlots[ 2 ], 96);
	TextDrawTextSize(g_ClassKSSlots[ 2 ], 350.000000, 110.000000);
	TextDrawSetSelectable(g_ClassKSSlots[ 2 ], 1);

	g_AdminLogTD = TextDrawCreate(150.000000, 360.000000, "_");
	TextDrawBackgroundColor(g_AdminLogTD, 255);
	TextDrawFont(g_AdminLogTD, 1);
	TextDrawLetterSize(g_AdminLogTD, 0.210000, 1.000000);
	TextDrawColor(g_AdminLogTD, COLOR_ADMIN);
	TextDrawSetOutline(g_AdminLogTD, 1);
	TextDrawSetProportional(g_AdminLogTD, 1);

	g_TacticalNukeMissileTD = TextDrawCreate(7.000000, 142.000000, "New Textdraw");
	TextDrawBackgroundColor(g_TacticalNukeMissileTD, 0);
	TextDrawFont(g_TacticalNukeMissileTD, 5);
	TextDrawLetterSize(g_TacticalNukeMissileTD, 0.500000, 1.000000);
	TextDrawColor(g_TacticalNukeMissileTD, -1);
	TextDrawSetOutline(g_TacticalNukeMissileTD, 0);
	TextDrawSetProportional(g_TacticalNukeMissileTD, 1);
	TextDrawSetShadow(g_TacticalNukeMissileTD, 1);
	TextDrawUseBox(g_TacticalNukeMissileTD, 1);
	TextDrawBoxColor(g_TacticalNukeMissileTD, 0);
	TextDrawTextSize(g_TacticalNukeMissileTD, 110.000000, 90.000000);
	TextDrawSetPreviewModel(g_TacticalNukeMissileTD, 3786);
	TextDrawSetPreviewRot(g_TacticalNukeMissileTD, 34.000000, 0.000000, 0.000000, 1.000000);
	TextDrawSetSelectable(g_TacticalNukeMissileTD, 0);

	g_TacticalNukeTimeTD = TextDrawCreate(39.000000, 182.000000, "Nuke in 05");
	TextDrawBackgroundColor(g_TacticalNukeTimeTD, 0);
	TextDrawFont(g_TacticalNukeTimeTD, 2);
	TextDrawLetterSize(g_TacticalNukeTimeTD, 0.190000, 0.899999);
	TextDrawColor(g_TacticalNukeTimeTD, -16776961);
	TextDrawSetOutline(g_TacticalNukeTimeTD, 1);
	TextDrawSetProportional(g_TacticalNukeTimeTD, 1);
	TextDrawSetSelectable(g_TacticalNukeTimeTD, 0);

	g_ShortPlayerNoticeTD = TextDrawCreate(170.000000, 389.000000, "The match will start as soon as there is an even number of players");
	TextDrawBackgroundColor(g_ShortPlayerNoticeTD, 255);
	TextDrawFont(g_ShortPlayerNoticeTD, 2);
	TextDrawLetterSize(g_ShortPlayerNoticeTD, 0.200000, 1.000000);
	TextDrawColor(g_ShortPlayerNoticeTD, -291958273);
	TextDrawSetOutline(g_ShortPlayerNoticeTD, 1);
	TextDrawSetProportional(g_ShortPlayerNoticeTD, 1);
	TextDrawUseBox(g_ShortPlayerNoticeTD, 1);
	TextDrawBoxColor(g_ShortPlayerNoticeTD, -16777136);
	TextDrawTextSize(g_ShortPlayerNoticeTD, 492.000000, 1.000000);
	TextDrawSetSelectable(g_ShortPlayerNoticeTD, 0);

	g_KillstreakAnnTD = TextDrawCreate(17.000000, 134.000000, "Lozza69 LOrenc~n~~w~Tactical Fucking Fart Inbound!");
	TextDrawBackgroundColor(g_KillstreakAnnTD, 255);
	TextDrawFont(g_KillstreakAnnTD, 2);
	TextDrawLetterSize(g_KillstreakAnnTD, 0.219999, 1.299999);
	TextDrawColor(g_KillstreakAnnTD, -291958273);
	TextDrawSetOutline(g_KillstreakAnnTD, 1);
	TextDrawSetProportional(g_KillstreakAnnTD, 1);
	TextDrawSetSelectable(g_KillstreakAnnTD, 0);

	g_CameraVectorAim[ 0 ] = TextDrawCreate(307.000000, 215.000000, "_");
	TextDrawBackgroundColor(g_CameraVectorAim[ 0 ], 255);
	TextDrawFont(g_CameraVectorAim[ 0 ], 1);
	TextDrawLetterSize(g_CameraVectorAim[ 0 ], 1.879999, 0.000000);
	TextDrawColor(g_CameraVectorAim[ 0 ], -1);
	TextDrawSetOutline(g_CameraVectorAim[ 0 ], 0);
	TextDrawSetProportional(g_CameraVectorAim[ 0 ], 1);
	TextDrawSetShadow(g_CameraVectorAim[ 0 ], 0);
	TextDrawUseBox(g_CameraVectorAim[ 0 ], 1);
	TextDrawBoxColor(g_CameraVectorAim[ 0 ], -291958448);
	TextDrawTextSize(g_CameraVectorAim[ 0 ], 343.000000, 0.000000);

	g_CameraVectorAim[ 1 ] = TextDrawCreate(325.000000, 203.000000, "_");
	TextDrawBackgroundColor(g_CameraVectorAim[ 1 ], 255);
	TextDrawFont(g_CameraVectorAim[ 1 ], 2);
	TextDrawLetterSize(g_CameraVectorAim[ 1 ], 1.899999, 2.799998);
	TextDrawColor(g_CameraVectorAim[ 1 ], -1);
	TextDrawSetOutline(g_CameraVectorAim[ 1 ], 0);
	TextDrawSetProportional(g_CameraVectorAim[ 1 ], 1);
	TextDrawSetShadow(g_CameraVectorAim[ 1 ], 0);
	TextDrawUseBox(g_CameraVectorAim[ 1 ], 1);
	TextDrawBoxColor(g_CameraVectorAim[ 1 ], -291958448);
	TextDrawTextSize(g_CameraVectorAim[ 1 ], 325.000000, 0.000000);

	g_Scoreboard[ 0 ] = TextDrawCreate(170.000000, 100.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 0 ], 255);
	TextDrawFont(g_Scoreboard[ 0 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 0 ], 0.500000, 10.400001);
	TextDrawColor(g_Scoreboard[ 0 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 0 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 0 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 0 ], 1);
	TextDrawUseBox(g_Scoreboard[ 0 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 0 ], 117);
	TextDrawTextSize(g_Scoreboard[ 0 ], 470.000000, 0.000000);

	g_Scoreboard[ 1 ] = TextDrawCreate(170.000000, 210.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 1 ], 255);
	TextDrawFont(g_Scoreboard[ 1 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 1 ], 0.500000, 10.399997);
	TextDrawColor(g_Scoreboard[ 1 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 1 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 1 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 1 ], 1);
	TextDrawUseBox(g_Scoreboard[ 1 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 1 ], 117);
	TextDrawTextSize(g_Scoreboard[ 1 ], 470.000000, 0.000000);

	g_Scoreboard[ 2 ] = TextDrawCreate(240.000000, 100.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 2 ], 255);
	TextDrawFont(g_Scoreboard[ 2 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 2 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 2 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 2 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 2 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 2 ], 1);
	TextDrawUseBox(g_Scoreboard[ 2 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 2 ], 117);
	TextDrawTextSize(g_Scoreboard[ 2 ], 470.000000, 0.000000);

	g_Scoreboard[ 3 ] = TextDrawCreate(240.000000, 172.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 3 ], 255);
	TextDrawFont(g_Scoreboard[ 3 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 3 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 3 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 3 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 3 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 3 ], 1);
	TextDrawUseBox(g_Scoreboard[ 3 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 3 ], 117);
	TextDrawTextSize(g_Scoreboard[ 3 ], 470.000000, 0.000000);

	g_Scoreboard[ 4 ] = TextDrawCreate(240.000000, 124.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 4 ], 255);
	TextDrawFont(g_Scoreboard[ 4 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 4 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 4 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 4 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 4 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 4 ], 1);
	TextDrawUseBox(g_Scoreboard[ 4 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 4 ], 117);
	TextDrawTextSize(g_Scoreboard[ 4 ], 470.000000, 0.000000);

	g_Scoreboard[ 5 ] = TextDrawCreate(240.000000, 148.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 5 ], 255);
	TextDrawFont(g_Scoreboard[ 5 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 5 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 5 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 5 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 5 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 5 ], 1);
	TextDrawUseBox(g_Scoreboard[ 5 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 5 ], 117);
	TextDrawTextSize(g_Scoreboard[ 5 ], 470.000000, 0.000000);

	g_Scoreboard[ 6 ] = TextDrawCreate(239.000000, 210.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 6 ], 255);
	TextDrawFont(g_Scoreboard[ 6 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 6 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 6 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 6 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 6 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 6 ], 1);
	TextDrawUseBox(g_Scoreboard[ 6 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 6 ], 117);
	TextDrawTextSize(g_Scoreboard[ 6 ], 470.000000, 0.000000);

	g_Scoreboard[ 7 ] = TextDrawCreate(170.000000, 83.000000, "Capture the Flag");
	TextDrawBackgroundColor(g_Scoreboard[ 7 ], 0);
	TextDrawFont(g_Scoreboard[ 7 ], 2);
	TextDrawLetterSize(g_Scoreboard[ 7 ], 0.220000, 1.099997);
	TextDrawColor(g_Scoreboard[ 7 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 7 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 7 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 7 ], 1);
	TextDrawUseBox(g_Scoreboard[ 7 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 7 ], 117);
	TextDrawTextSize(g_Scoreboard[ 7 ], 470.000000, 0.000000);

	g_Scoreboard[ 8 ] = TextDrawCreate(239.000000, 234.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 8 ], 255);
	TextDrawFont(g_Scoreboard[ 8 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 8 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 8 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 8 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 8 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 8 ], 1);
	TextDrawUseBox(g_Scoreboard[ 8 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 8 ], 117);
	TextDrawTextSize(g_Scoreboard[ 8 ], 470.000000, 0.000000);

	g_Scoreboard[ 9 ] = TextDrawCreate(239.000000, 258.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 9 ], 255);
	TextDrawFont(g_Scoreboard[ 9 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 9 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 9 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 9 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 9 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 9 ], 1);
	TextDrawUseBox(g_Scoreboard[ 9 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 9 ], 117);
	TextDrawTextSize(g_Scoreboard[ 9 ], 470.000000, 0.000000);

	g_Scoreboard[ 10 ] = TextDrawCreate(239.000000, 282.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 10 ], 255);
	TextDrawFont(g_Scoreboard[ 10 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 10 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 10 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 10 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 10 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 10 ], 1);
	TextDrawUseBox(g_Scoreboard[ 10 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 10 ], 117);
	TextDrawTextSize(g_Scoreboard[ 10 ], 470.000000, 0.000000);

	g_Scoreboard[ 11 ] = TextDrawCreate(431.000000, 100.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 11 ], 255);
	TextDrawFont(g_Scoreboard[ 11 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 11 ], 0.500000, 10.400001);
	TextDrawColor(g_Scoreboard[ 11 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 11 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 11 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 11 ], 1);
	TextDrawUseBox(g_Scoreboard[ 11 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 11 ], 11075365);
	TextDrawTextSize(g_Scoreboard[ 11 ], 470.000000, 30.000000);

	g_Scoreboard[ 12 ] = TextDrawCreate(352.000000, 100.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 12 ], 255);
	TextDrawFont(g_Scoreboard[ 12 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 12 ], 0.500000, 10.400001);
	TextDrawColor(g_Scoreboard[ 12 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 12 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 12 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 12 ], 1);
	TextDrawUseBox(g_Scoreboard[ 12 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 12 ], 11075365);
	TextDrawTextSize(g_Scoreboard[ 12 ], 390.000000, 30.000000);

	g_Scoreboard[ 13 ] = TextDrawCreate(355.000000, 83.000000, "SCORE_____KILLS____DEATHS");
	TextDrawBackgroundColor(g_Scoreboard[ 13 ], 0);
	TextDrawFont(g_Scoreboard[ 13 ], 2);
	TextDrawLetterSize(g_Scoreboard[ 13 ], 0.220000, 1.099997);
	TextDrawColor(g_Scoreboard[ 13 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 13 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 13 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 13 ], 1);

	g_Scoreboard[ 14 ] = TextDrawCreate(431.000000, 210.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 14 ], 255);
	TextDrawFont(g_Scoreboard[ 14 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 14 ], 0.500000, 10.400001);
	TextDrawColor(g_Scoreboard[ 14 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 14 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 14 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 14 ], 1);
	TextDrawUseBox(g_Scoreboard[ 14 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 14 ], -216326875);
	TextDrawTextSize(g_Scoreboard[ 14 ], 470.000000, 30.000000);

	g_Scoreboard[ 15 ] = TextDrawCreate(352.000000, 210.000000, "_");
	TextDrawBackgroundColor(g_Scoreboard[ 15 ], 255);
	TextDrawFont(g_Scoreboard[ 15 ], 1);
	TextDrawLetterSize(g_Scoreboard[ 15 ], 0.500000, 10.400001);
	TextDrawColor(g_Scoreboard[ 15 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 15 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 15 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 15 ], 1);
	TextDrawUseBox(g_Scoreboard[ 15 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 15 ], -216326875);
	TextDrawTextSize(g_Scoreboard[ 15 ], 390.000000, 30.000000);

	g_Scoreboard[ 16 ] = TextDrawCreate(180.000000, 108.000000, "ld_otb2:ric1");
	TextDrawBackgroundColor(g_Scoreboard[ 16 ], 255);
	TextDrawFont(g_Scoreboard[ 16 ], 4);
	TextDrawLetterSize(g_Scoreboard[ 16 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 16 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 16 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 16 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 16 ], 1);
	TextDrawUseBox(g_Scoreboard[ 16 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 16 ], 255);
	TextDrawTextSize(g_Scoreboard[ 16 ], 50.000000, 70.000000);

	g_Scoreboard[ 17 ] = TextDrawCreate(180.000000, 218.000000, "ld_otb2:ric2");
	TextDrawBackgroundColor(g_Scoreboard[ 17 ], 255);
	TextDrawFont(g_Scoreboard[ 17 ], 4);
	TextDrawLetterSize(g_Scoreboard[ 17 ], 0.500000, 1.000000);
	TextDrawColor(g_Scoreboard[ 17 ], -1);
	TextDrawSetOutline(g_Scoreboard[ 17 ], 0);
	TextDrawSetProportional(g_Scoreboard[ 17 ], 1);
	TextDrawSetShadow(g_Scoreboard[ 17 ], 1);
	TextDrawUseBox(g_Scoreboard[ 17 ], 1);
	TextDrawBoxColor(g_Scoreboard[ 17 ], 255);
	TextDrawTextSize(g_Scoreboard[ 17 ], 50.000000, 70.000000);

	g_ScoreboardNames[ 0 ] = TextDrawCreate(240.000000, 98.000000, "Lorenc~n~Emran~n~Balls~n~[HiC]TheKiller~n~XFlawless~n~Norbert~n~Vodafone~n~Poop");
	TextDrawBackgroundColor(g_ScoreboardNames[ 0 ], 0);
	TextDrawFont(g_ScoreboardNames[ 0 ], 2);
	TextDrawLetterSize(g_ScoreboardNames[ 0 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardNames[ 0 ], -1);
	TextDrawSetOutline(g_ScoreboardNames[ 0 ], 0);
	TextDrawSetProportional(g_ScoreboardNames[ 0 ], 1);
	TextDrawSetShadow(g_ScoreboardNames[ 0 ], 1);

	g_ScoreboardNames[ 1 ] = TextDrawCreate(240.000000, 208.000000, "Lorenc~n~Emran~n~Balls~n~[HiC]TheKiller~n~XFlawless~n~Norbert~n~Vodafone~n~Poop");
	TextDrawBackgroundColor(g_ScoreboardNames[ 1 ], 0);
	TextDrawFont(g_ScoreboardNames[ 1 ], 2);
	TextDrawLetterSize(g_ScoreboardNames[ 1 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardNames[ 1 ], -1);
	TextDrawSetOutline(g_ScoreboardNames[ 1 ], 0);
	TextDrawSetProportional(g_ScoreboardNames[ 1 ], 1);
	TextDrawSetShadow(g_ScoreboardNames[ 1 ], 1);

	g_ScoreboardScores[ 0 ] = TextDrawCreate(352.000000, 98.000000, "1337~n~978~n~675~n~9877~n~675~n~76555~n~64~n~5");
	TextDrawBackgroundColor(g_ScoreboardScores[ 0 ], 0);
	TextDrawFont(g_ScoreboardScores[ 0 ], 2);
	TextDrawLetterSize(g_ScoreboardScores[ 0 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardScores[ 0 ], -1);
	TextDrawSetOutline(g_ScoreboardScores[ 0 ], 0);
	TextDrawSetProportional(g_ScoreboardScores[ 0 ], 1);
	TextDrawSetShadow(g_ScoreboardScores[ 0 ], 1);

	g_ScoreboardScores[ 1 ] = TextDrawCreate(352.000000, 208.000000, "1337~n~978~n~675~n~9877~n~675~n~76555~n~64~n~5");
	TextDrawBackgroundColor(g_ScoreboardScores[ 1 ], 0);
	TextDrawFont(g_ScoreboardScores[ 1 ], 2);
	TextDrawLetterSize(g_ScoreboardScores[ 1 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardScores[ 1 ], -1);
	TextDrawSetOutline(g_ScoreboardScores[ 1 ], 0);
	TextDrawSetProportional(g_ScoreboardScores[ 1 ], 1);
	TextDrawSetShadow(g_ScoreboardScores[ 1 ], 1);

	g_ScoreboardKills[ 0 ] = TextDrawCreate(393.000000, 98.000000, "21323~n~12321~n~7868~n~87667~n~67676~n~76767~n~76~n~6");
	TextDrawBackgroundColor(g_ScoreboardKills[ 0 ], 0);
	TextDrawFont(g_ScoreboardKills[ 0 ], 2);
	TextDrawLetterSize(g_ScoreboardKills[ 0 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardKills[ 0 ], -1);
	TextDrawSetOutline(g_ScoreboardKills[ 0 ], 0);
	TextDrawSetProportional(g_ScoreboardKills[ 0 ], 1);
	TextDrawSetShadow(g_ScoreboardKills[ 0 ], 1);

	g_ScoreboardKills[ 1 ] = TextDrawCreate(393.000000, 208.000000, "21323~n~12321~n~7868~n~87667~n~67676~n~76767~n~76~n~6");
	TextDrawBackgroundColor(g_ScoreboardKills[1 ], 0);
	TextDrawFont(g_ScoreboardKills[ 1 ], 2);
	TextDrawLetterSize(g_ScoreboardKills[ 1 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardKills[ 1 ], -1);
	TextDrawSetOutline(g_ScoreboardKills[ 1 ], 0);
	TextDrawSetProportional(g_ScoreboardKills[ 1 ], 1);
	TextDrawSetShadow(g_ScoreboardKills[ 1], 1);

	g_ScoreboardDeaths[ 0 ] = TextDrawCreate(433.000000, 98.000000, "1~n~1~n~1~n~1~n~1~n~1~n~1~n~1~n~");
	TextDrawBackgroundColor(g_ScoreboardDeaths[ 0 ], 0);
	TextDrawFont(g_ScoreboardDeaths[ 0 ], 2);
	TextDrawLetterSize(g_ScoreboardDeaths[ 0 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardDeaths[ 0 ], -1);
	TextDrawSetOutline(g_ScoreboardDeaths[ 0 ], 0);
	TextDrawSetProportional(g_ScoreboardDeaths[ 0 ], 1);
	TextDrawSetShadow(g_ScoreboardDeaths[ 0 ], 1);

	g_ScoreboardDeaths[ 1 ] = TextDrawCreate(433.000000, 208.000000, "1~n~1~n~1~n~1~n~1~n~1~n~1~n~1~n~");
	TextDrawBackgroundColor(g_ScoreboardDeaths[ 1 ], 0);
	TextDrawFont(g_ScoreboardDeaths[ 1 ], 2);
	TextDrawLetterSize(g_ScoreboardDeaths[ 1 ], 0.200000, 1.334000);
	TextDrawColor(g_ScoreboardDeaths[ 1 ], -1);
	TextDrawSetOutline(g_ScoreboardDeaths[ 1 ], 0);
	TextDrawSetProportional(g_ScoreboardDeaths[ 1 ], 1);
	TextDrawSetShadow(g_ScoreboardDeaths[ 1 ], 1);

	g_ScoreboardTeamScore[ 0 ] = TextDrawCreate(170.000000, 183.000000, "Score:~w~~h~ 60000");
	TextDrawBackgroundColor(g_ScoreboardTeamScore[ 0 ], 0);
	TextDrawFont(g_ScoreboardTeamScore[ 0 ], 2);
	TextDrawLetterSize(g_ScoreboardTeamScore[ 0 ], 0.200000, 1.100000);
	TextDrawColor(g_ScoreboardTeamScore[ 0 ], 11075560);
	TextDrawSetOutline(g_ScoreboardTeamScore[ 0 ], 0);
	TextDrawSetProportional(g_ScoreboardTeamScore[ 0 ], 1);
	TextDrawSetShadow(g_ScoreboardTeamScore[ 0 ], 1);

	g_ScoreboardTeamScore[ 1 ] = TextDrawCreate(170.000000, 293.000000, "Score:~w~~h~ 60000");
	TextDrawBackgroundColor(g_ScoreboardTeamScore[ 1 ], 0);
	TextDrawFont(g_ScoreboardTeamScore[ 1 ], 2);
	TextDrawLetterSize(g_ScoreboardTeamScore[ 1 ], 0.200000, 1.100000);
	TextDrawColor(g_ScoreboardTeamScore[ 1 ], -216326680);
	TextDrawSetOutline(g_ScoreboardTeamScore[ 1 ], 0);
	TextDrawSetProportional(g_ScoreboardTeamScore[ 1 ], 1);
	TextDrawSetShadow(g_ScoreboardTeamScore[ 1 ], 1);

	g_RoundGamemodeTD = TextDrawCreate(569.000000, 364.000000, "Team Deathmatch");
	TextDrawAlignment(g_RoundGamemodeTD, 3);
	TextDrawBackgroundColor(g_RoundGamemodeTD, 80);
	TextDrawFont(g_RoundGamemodeTD, 2);
	TextDrawLetterSize(g_RoundGamemodeTD, 0.300000, 1.299999);
	TextDrawColor(g_RoundGamemodeTD, -1);
	TextDrawSetOutline(g_RoundGamemodeTD, 1);
	TextDrawSetProportional(g_RoundGamemodeTD, 1);

	g_RoundStartNote = TextDrawCreate(268.000000, 174.000000, "Match begins in");
	TextDrawBackgroundColor(g_RoundStartNote, 112);
	TextDrawFont(g_RoundStartNote, 2);
	TextDrawLetterSize(g_RoundStartNote, 0.300000, 1.400000);
	TextDrawColor(g_RoundStartNote, -1);
	TextDrawSetOutline(g_RoundStartNote, 0);
	TextDrawSetProportional(g_RoundStartNote, 1);
	TextDrawSetShadow(g_RoundStartNote, 1);

    g_RoundStartTimeTD = TextDrawCreate(322.000000, 181.000000, "15");
    TextDrawAlignment(g_RoundStartTimeTD, 2);
    TextDrawBackgroundColor(g_RoundStartTimeTD, 51);
    TextDrawFont(g_RoundStartTimeTD, 2);
    TextDrawLetterSize(g_RoundStartTimeTD, 1.200000, 5.000000);
    TextDrawColor(g_RoundStartTimeTD, -65281);
    TextDrawSetOutline(g_RoundStartTimeTD, 0);
    TextDrawSetProportional(g_RoundStartTimeTD, 1);
    TextDrawSetShadow(g_RoundStartTimeTD, 2);

	g_tropasRoundBox = TextDrawCreate(583.000000, 380.000000, "_");
    TextDrawBackgroundColor(g_tropasRoundBox, 255);
    TextDrawFont(g_tropasRoundBox, 1);
    TextDrawLetterSize(g_tropasRoundBox, 0.500000, 1.000000);
    TextDrawColor(g_tropasRoundBox, -1);
    TextDrawSetOutline(g_tropasRoundBox, 0);
    TextDrawSetProportional(g_tropasRoundBox, 1);
    TextDrawSetShadow(g_tropasRoundBox, 1);
    TextDrawUseBox(g_tropasRoundBox, 1);
    TextDrawBoxColor(g_tropasRoundBox, 11075408);
    TextDrawTextSize(g_tropasRoundBox, g_tropasRoundBoxSize, 0.000000);

    g_tropasScoreText = TextDrawCreate(571.000000, 376.000000, "0");
    TextDrawAlignment(g_tropasScoreText, 3);
    TextDrawBackgroundColor(g_tropasScoreText, 11075376);
    TextDrawFont(g_tropasScoreText, 2);
    TextDrawLetterSize(g_tropasScoreText, 0.369998, 1.599998);
    TextDrawColor(g_tropasScoreText, -1);
    TextDrawSetOutline(g_tropasScoreText, 1);
    TextDrawSetProportional(g_tropasScoreText, 1);

    g_op40RoundBox = TextDrawCreate(583.000000, 393.000000, "__");
    TextDrawBackgroundColor(g_op40RoundBox, 255);
    TextDrawFont(g_op40RoundBox, 1);
    TextDrawLetterSize(g_op40RoundBox, 0.800000, 1.000000);
    TextDrawColor(g_op40RoundBox, -1);
    TextDrawSetOutline(g_op40RoundBox, 0);
    TextDrawSetProportional(g_op40RoundBox, 1);
    TextDrawSetShadow(g_op40RoundBox, 1);
    TextDrawUseBox(g_op40RoundBox, 1);
    TextDrawBoxColor(g_op40RoundBox, -216326832);
    TextDrawTextSize(g_op40RoundBox, g_op40RoundBoxSize, 0.000000);

    g_op40ScoreText = TextDrawCreate(571.000000, 390.000000, "0");
    TextDrawAlignment(g_op40ScoreText, 3);
    TextDrawBackgroundColor(g_op40ScoreText, -216326864);
    TextDrawFont(g_op40ScoreText, 2);
    TextDrawLetterSize(g_op40ScoreText, 0.369998, 1.599998);
    TextDrawColor(g_op40ScoreText, -1);
    TextDrawSetOutline(g_op40ScoreText, 1);
    TextDrawSetProportional(g_op40ScoreText, 1);

	g_RoundBoxWhereTeam = TextDrawCreate(575.000000, 369.000000, "ld_dual:dark");
    TextDrawBackgroundColor(g_RoundBoxWhereTeam, 255);
    TextDrawFont(g_RoundBoxWhereTeam, 4);
    TextDrawLetterSize(g_RoundBoxWhereTeam, 0.800000, 4.000000);
    TextDrawColor(g_RoundBoxWhereTeam, 255);
    TextDrawSetOutline(g_RoundBoxWhereTeam, 0);
    TextDrawSetProportional(g_RoundBoxWhereTeam, 1);
    TextDrawSetShadow(g_RoundBoxWhereTeam, 1);
    TextDrawUseBox(g_RoundBoxWhereTeam, 1);
    TextDrawBoxColor(g_RoundBoxWhereTeam, 255);
    TextDrawTextSize(g_RoundBoxWhereTeam, 46.000000, 47.000000);

    g_RoundTimeTD = TextDrawCreate(579.000000, 359.000000, "10:00");
    TextDrawBackgroundColor(g_RoundTimeTD, 80);
    TextDrawFont(g_RoundTimeTD, 2);
    TextDrawLetterSize(g_RoundTimeTD, 0.360000, 1.499999);
    TextDrawColor(g_RoundTimeTD, -1);
    TextDrawSetOutline(g_RoundTimeTD, 1);
    TextDrawSetProportional(g_RoundTimeTD, 1);

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

	g_MovieModeTD[ 1 ] = TextDrawCreate(535.000000, 400.000000, "ALL___DUT");
	TextDrawBackgroundColor(g_MovieModeTD[ 1 ], 255);
	TextDrawFont(g_MovieModeTD[ 1 ], 2);
	TextDrawLetterSize(g_MovieModeTD[ 1 ], 0.280000, 1.500000);
	TextDrawColor(g_MovieModeTD[ 1 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 1 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 1 ], 1);
	TextDrawSetSelectable(g_MovieModeTD[ 1 ], 0);

	g_MovieModeTD[ 2 ] = TextDrawCreate(525.000000, 398.000000, "C___________Y");
	TextDrawBackgroundColor(g_MovieModeTD[ 2 ], 255);
	TextDrawFont(g_MovieModeTD[ 2 ], 2);
	TextDrawLetterSize(g_MovieModeTD[ 2 ], 0.400000, 2.000000);
	TextDrawColor(g_MovieModeTD[ 2 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 2 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 2 ], 1);
	TextDrawSetSelectable(g_MovieModeTD[ 2 ], 0);

	g_MovieModeTD[ 3 ] = TextDrawCreate(559.000000, 404.000000, "OF");
	TextDrawBackgroundColor(g_MovieModeTD[ 3 ], 255);
	TextDrawFont(g_MovieModeTD[ 3 ], 2);
	TextDrawLetterSize(g_MovieModeTD[ 3 ], 0.129999, 0.699998);
	TextDrawColor(g_MovieModeTD[ 3 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 3 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 3 ], 1);
	TextDrawSetSelectable(g_MovieModeTD[ 3 ], 0);

	g_MovieModeTD[ 4 ] = TextDrawCreate(539.000000, 412.000000, "FOR SA-MP");
	TextDrawBackgroundColor(g_MovieModeTD[ 4 ], 255);
	TextDrawFont(g_MovieModeTD[ 4 ], 2);
	TextDrawLetterSize(g_MovieModeTD[ 4 ], 0.219999, 1.099998);
	TextDrawColor(g_MovieModeTD[ 4 ], -291958273);
	TextDrawSetOutline(g_MovieModeTD[ 4 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 4 ], 1);
	TextDrawSetSelectable(g_MovieModeTD[ 4 ], 0);

	g_MovieModeTD[ 5 ] = TextDrawCreate(507.000000, 398.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 3 ], 255);
	TextDrawFont(g_MovieModeTD[ 5 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 5 ], 0.500000, -0.400000);
	TextDrawColor(g_MovieModeTD[ 5 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 5 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 5 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 5 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 5 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 5 ], 255);
	TextDrawTextSize(g_MovieModeTD[ 5 ], 620.000000, 0.000000);

	g_MovieModeTD[ 6 ] = TextDrawCreate(515.000000, 385.000000, "www.IrresistibleGaming.com");
	TextDrawBackgroundColor(g_MovieModeTD[ 6 ], 255);
	TextDrawFont(g_MovieModeTD[ 6 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 6 ], 0.200000, 1.000000);
	TextDrawColor(g_MovieModeTD[ 6 ], 13434879);
	TextDrawSetOutline(g_MovieModeTD[ 6 ], 1);
	TextDrawSetProportional(g_MovieModeTD[ 6 ], 1);

	g_MovieModeTD[ 7 ] = TextDrawCreate(507.000000, 386.000000, "_");
	TextDrawBackgroundColor(g_MovieModeTD[ 7 ], 255);
	TextDrawFont(g_MovieModeTD[ 7 ], 1);
	TextDrawLetterSize(g_MovieModeTD[ 7 ], 0.500000, 0.799999);
	TextDrawColor(g_MovieModeTD[ 7 ], -1);
	TextDrawSetOutline(g_MovieModeTD[ 7 ], 0);
	TextDrawSetProportional(g_MovieModeTD[ 7 ], 1);
	TextDrawSetShadow(g_MovieModeTD[ 7 ], 1);
	TextDrawUseBox(g_MovieModeTD[ 7 ], 1);
	TextDrawBoxColor(g_MovieModeTD[ 7 ], 128);
	TextDrawTextSize(g_MovieModeTD[ 7 ], 620.000000, 0.000000);

	for( new i, id = -1; i < 360; i += 6 )
	{
		id++;

		new Float: x = 318.000000 + ( 16 * floatsin( i, degrees ) );
		new Float: y = 190.000000 + ( 16 * floatcos( i, degrees ) );

		p_ProgressCircleTD[ id ] = TextDrawCreate(x,y, ".");
		TextDrawBackgroundColor(p_ProgressCircleTD[ id ], 255);
		TextDrawFont(p_ProgressCircleTD[ id ], 1);
		TextDrawLetterSize(p_ProgressCircleTD[ id ], 0.500000, 2.000000);
		TextDrawColor(p_ProgressCircleTD[ id ], COLOR_ORANGE);
		TextDrawSetOutline(p_ProgressCircleTD[ id ], 0);
		TextDrawSetProportional(p_ProgressCircleTD[ id ], 1);
		TextDrawSetShadow(p_ProgressCircleTD[ id ], 0);
	}

	for( new i; i != MAX_PLAYERS; i++ )
	{
	    /* ** INITIALIZERS ** */
		g_usermatchDataT1[ i ] [ M_ID ] = 0xFFFF;
		g_usermatchDataT2[ i ] [ M_ID ] = 0xFFFF;
	    /* ** END INITIALIZERS ** */

	    p_SelectionHelpTD[ i ] = TextDrawCreate(400.000000, 11.000000, "_");
		TextDrawBackgroundColor(p_SelectionHelpTD[ i ], 255);
		TextDrawFont(p_SelectionHelpTD[ i ], 2);
		TextDrawLetterSize(p_SelectionHelpTD[ i ], 0.189999, 1.100000);
		TextDrawColor(p_SelectionHelpTD[ i ], -1);
		TextDrawSetOutline(p_SelectionHelpTD[ i ], 1);
		TextDrawSetProportional(p_SelectionHelpTD[ i ], 1);
		TextDrawUseBox(p_SelectionHelpTD[ i ], 1);
		TextDrawBoxColor(p_SelectionHelpTD[ i ], 80);
		TextDrawTextSize(p_SelectionHelpTD[ i ], 630.000000, 0.000000);

		p_ProgressTextTD[ i ] = TextDrawCreate(318.000000, 195.000000, "_");
		TextDrawAlignment(p_ProgressTextTD[ i ], 2);
		TextDrawBackgroundColor(p_ProgressTextTD[ i ], 255);
		TextDrawFont(p_ProgressTextTD[ i ], 0);
		TextDrawLetterSize(p_ProgressTextTD[ i ], 0.509998, 1.799998);
		TextDrawColor(p_ProgressTextTD[ i ], COLOR_GREY);
		TextDrawSetOutline(p_ProgressTextTD[ i ], 0);
		TextDrawSetProportional(p_ProgressTextTD[ i ], 1);
		TextDrawSetShadow(p_ProgressTextTD[ i ], 0);
		TextDrawSetSelectable(p_ProgressTextTD[ i ], 0);

		p_FadeBoxTD[ i ] = TextDrawCreate(660.000000, -51.000000, "_");
		TextDrawBackgroundColor(p_FadeBoxTD[ i ], 255);
		TextDrawFont(p_FadeBoxTD[ i ], 1);
		TextDrawLetterSize(p_FadeBoxTD[ i ], 99999.000000, 9999999.000000);
		TextDrawColor(p_FadeBoxTD[ i ], -1);
		TextDrawUseBox(p_FadeBoxTD[ i ], 1);
		TextDrawBoxColor(p_FadeBoxTD[ i ], 0);
		TextDrawTextSize(p_FadeBoxTD[ i ], -9.000000, 80.000000);

		p_RankTD[ i ] = TextDrawCreate(496.000000, 380.000000, "25");
		TextDrawAlignment(p_RankTD[ i ], 2);
		TextDrawBackgroundColor(p_RankTD[ i ], 255);
		TextDrawFont(p_RankTD[ i ], 2);
		TextDrawLetterSize(p_RankTD[ i ], 0.700000, 4.000000);
		TextDrawColor(p_RankTD[ i ], -1);
		TextDrawSetProportional(p_RankTD[ i ], 1);
		TextDrawSetShadow(p_RankTD[ i ], 1);

		p_XPAmountTD[ i ] = TextDrawCreate(575.000000, 387.000000, "100000 / 100000");
		TextDrawAlignment(p_XPAmountTD[ i ], 2);
		TextDrawBackgroundColor(p_XPAmountTD[ i ], 255);
		TextDrawFont(p_XPAmountTD[ i ], 2);
		TextDrawLetterSize(p_XPAmountTD[ i ], 0.290000, 1.600000);
		TextDrawColor(p_XPAmountTD[ i ], -1);
		TextDrawSetOutline(p_XPAmountTD[ i ], 1);
		TextDrawSetProportional(p_XPAmountTD[ i ], 1);

		g_SpectateTD[ i ] = TextDrawCreate(320.000000, 350.000000, "__");
		TextDrawAlignment(g_SpectateTD[ i ], 2);
		TextDrawBackgroundColor(g_SpectateTD[ i ], 255);
		TextDrawFont(g_SpectateTD[ i ], 1);
		TextDrawLetterSize(g_SpectateTD[ i ], 0.250000, 1.400000);
		TextDrawColor(g_SpectateTD[ i ], -1);
		TextDrawSetOutline(g_SpectateTD[ i ], 1);
		TextDrawSetProportional(g_SpectateTD[ i ], 1);

	    p_NewRankTD[ i ] = TextDrawCreate(248.000000, 157.000000, "You are now rank 50!");
		TextDrawBackgroundColor(p_NewRankTD[ i ], 255);
		TextDrawFont(p_NewRankTD[ i ], 2);
		TextDrawLetterSize(p_NewRankTD[ i ], 0.319999, 1.399999);
		TextDrawColor(p_NewRankTD[ i ], -1);
		TextDrawSetOutline(p_NewRankTD[ i ], 0);
		TextDrawSetProportional(p_NewRankTD[ i ], 1);
		TextDrawSetShadow(p_NewRankTD[ i ], 1);

	    p_RankDataTD[ i ] = TextDrawCreate(84.000000, 314.000000, "_");
		TextDrawAlignment(p_RankDataTD[ i ], 2);
		TextDrawBackgroundColor(p_RankDataTD[ i ], 255);
		TextDrawFont(p_RankDataTD[ i ], 1);
		TextDrawLetterSize(p_RankDataTD[ i ], 0.210000, 1.200000);
		TextDrawColor(p_RankDataTD[ i ], -291958273);
		TextDrawSetOutline(p_RankDataTD[ i ], 1);
		TextDrawSetProportional(p_RankDataTD[ i ], 1);
		TextDrawSetSelectable(p_RankDataTD[ i ], 0);

	    p_ExperienceTD[ i ] = TextDrawCreate(499.000000, 75.000000, "000000000");
		TextDrawBackgroundColor(p_ExperienceTD[ i ], 255);
		TextDrawFont(p_ExperienceTD[ i ], 3);
		TextDrawLetterSize(p_ExperienceTD[ i ], 0.559999, 2.599997);
		TextDrawColor(p_ExperienceTD[ i ], -2347265);
		TextDrawSetOutline(p_ExperienceTD[ i ], 2);
		TextDrawSetProportional(p_ExperienceTD[ i ], 1);
		TextDrawSetSelectable(p_ExperienceTD[ i ], 0);

		p_ClassName[ i ] = TextDrawCreate(14.000000, 133.000000, "_");
		TextDrawBackgroundColor(p_ClassName[ i ], 255);
		TextDrawFont(p_ClassName[ i ], 0);
		TextDrawLetterSize(p_ClassName[ i ], 0.450000, 1.400000);
		TextDrawColor(p_ClassName[ i ], -1);
		TextDrawSetOutline(p_ClassName[ i ], 1);
		TextDrawSetProportional(p_ClassName[ i ], 1);
		TextDrawSetSelectable(p_ClassName[ i ], 0);

		p_ClassPrimary[ i ] = TextDrawCreate(23.000000, 114.000000, "350");
		TextDrawBackgroundColor(p_ClassPrimary[ i ], 0);
		TextDrawFont(p_ClassPrimary[ i ], 5);
		TextDrawLetterSize(p_ClassPrimary[ i ], 0.500000, -0.399999);
		TextDrawColor(p_ClassPrimary[ i ], -1);
		TextDrawSetOutline(p_ClassPrimary[ i ], 1);
		TextDrawSetProportional(p_ClassPrimary[ i ], 1);
		TextDrawUseBox(p_ClassPrimary[ i ], 1);
		TextDrawBoxColor(p_ClassPrimary[ i ], 0);
		TextDrawTextSize(p_ClassPrimary[ i ], 111.000000, 131.000000);
		TextDrawSetSelectable(p_ClassPrimary[ i ], 1);

		p_ClassSecondary[ i ] = TextDrawCreate(43.000000, 181.000000, "350");
		TextDrawBackgroundColor(p_ClassSecondary[ i ], 0);
		TextDrawFont(p_ClassSecondary[ i ], 5);
		TextDrawLetterSize(p_ClassSecondary[ i ], 0.500000, -0.399999);
		TextDrawColor(p_ClassSecondary[ i ], -1);
		TextDrawSetOutline(p_ClassSecondary[ i ], 1);
		TextDrawSetProportional(p_ClassSecondary[ i ], 1);
		TextDrawUseBox(p_ClassSecondary[ i ], 1);
		TextDrawBoxColor(p_ClassSecondary[ i ], 0);
		TextDrawTextSize(p_ClassSecondary[ i ], 71.000000, 88.000000);
		TextDrawSetSelectable(p_ClassSecondary[ i ], 1);

		p_ClassMenu[ i ] = TextDrawCreate(183.000000, 144.000000, "Silenced Pistol~n~Colt-45~n~Desert Eagle");
		TextDrawBackgroundColor(p_ClassMenu[ i ], 255);
		TextDrawFont(p_ClassMenu[ i ], 2);
		TextDrawLetterSize(p_ClassMenu[ i ], 0.190000, 1.099999);
		TextDrawColor(p_ClassMenu[ i ], -1);
		TextDrawSetOutline(p_ClassMenu[ i ], 1);
		TextDrawSetProportional(p_ClassMenu[ i ], 1);
		TextDrawUseBox(p_ClassMenu[ i ], 1);
		TextDrawBoxColor(p_ClassMenu[ i ], 96);
		TextDrawTextSize(p_ClassMenu[ i ], 300.000000, 110.000000);
		TextDrawSetSelectable(p_ClassMenu[ i ], 0);

		p_KillstreakInstructions[ i ] = TextDrawCreate(18.000000, 220.000000, "Space - Control Rotation/Position~n~Fire - Launch the strike");
		TextDrawBackgroundColor(p_KillstreakInstructions[ i ], 0);
		TextDrawFont(p_KillstreakInstructions[ i ], 2);
		TextDrawLetterSize(p_KillstreakInstructions[ i ], 0.180000, 1.100000);
		TextDrawColor(p_KillstreakInstructions[ i ], 255);
		TextDrawSetOutline(p_KillstreakInstructions[ i ], 1);
		TextDrawSetProportional(p_KillstreakInstructions[ i ], 1);
		TextDrawUseBox(p_KillstreakInstructions[ i ], 1);
		TextDrawBoxColor(p_KillstreakInstructions[ i ], -291958448);
		TextDrawTextSize(p_KillstreakInstructions[ i ], 191.000000, 0.000000);
		TextDrawSetSelectable(p_KillstreakInstructions[ i ], 0);

	    p_RoundPlayerTeam[ i ] = TextDrawCreate(576.000000, 367.000000, "ld_otb2:ric1");
		TextDrawBackgroundColor(p_RoundPlayerTeam[ i ], 255);
		TextDrawFont(p_RoundPlayerTeam[ i ], 4);
		TextDrawLetterSize(p_RoundPlayerTeam[ i ], 0.800000, 4.000000);
		TextDrawColor(p_RoundPlayerTeam[ i ], -1);
		TextDrawSetOutline(p_RoundPlayerTeam[ i ], 0);
		TextDrawSetProportional(p_RoundPlayerTeam[ i ], 1);
		TextDrawSetShadow(p_RoundPlayerTeam[ i ], 1);
		TextDrawUseBox(p_RoundPlayerTeam[ i ], 1);
		TextDrawBoxColor(p_RoundPlayerTeam[ i ], 255);
		TextDrawTextSize(p_RoundPlayerTeam[ i ], 46.000000, 49.000000);

		p_XPGivenTD[ i ] = TextDrawCreate(555.000000, 100.000000, "+10 XP");
		TextDrawAlignment(p_XPGivenTD[ i ], 2);
		TextDrawBackgroundColor(p_XPGivenTD[ i ], 255);
		TextDrawFont(p_XPGivenTD[ i ], 3);
		TextDrawLetterSize(p_XPGivenTD[ i ], 0.349999, 1.599997);
		TextDrawColor(p_XPGivenTD[ i ], -2347265);
		TextDrawSetOutline(p_XPGivenTD[ i ], 1);
		TextDrawSetProportional(p_XPGivenTD[ i ], 1);
		TextDrawSetSelectable(p_XPGivenTD[ i ], 0);

		p_DamageTD[ i ] = TextDrawCreate(328.000000, 335.000000, "~r~Damage: 5434.00 HP~n~~w~Player: Lorencs_Camel(23)");
		TextDrawAlignment(p_DamageTD[ i ], 2);
		TextDrawBackgroundColor(p_DamageTD[ i ], 255);
		TextDrawFont(p_DamageTD[ i ], 3);
		TextDrawLetterSize(p_DamageTD[ i ], 0.249999, 1.199997);
		TextDrawColor(p_DamageTD[ i ], -2347265);
		TextDrawSetOutline(p_DamageTD[ i ], 1);
		TextDrawSetProportional(p_DamageTD[ i ], 1);
		TextDrawSetSelectable(p_DamageTD[ i ], 0);

		p_KillstreakSetupTD[ i ] = TextDrawCreate(459.000000, 302.000000, "~r~ks 1:~w~  Predator Missile~n~~r~ks 2:~w~ Tactical Nuke~n~~r~ks 3:~w~ Predator missile");
		TextDrawBackgroundColor(p_KillstreakSetupTD[ i ], 255);
		TextDrawFont(p_KillstreakSetupTD[ i ], 2);
		TextDrawLetterSize(p_KillstreakSetupTD[ i ], 0.190000, 1.200000);
		TextDrawColor(p_KillstreakSetupTD[ i ], -1);
		TextDrawSetOutline(p_KillstreakSetupTD[ i ], 1);
		TextDrawSetProportional(p_KillstreakSetupTD[ i ], 1);
		TextDrawSetSelectable(p_KillstreakSetupTD[ i ], 0);

		p_ClassSetupTD[ i ] = TextDrawCreate(459.000000, 233.000000, "PRIMARY: MP5~n~SECONDARY: SILENCED PISTOL~n~PERK 1: STOPPING POWER~n~PERK 2: STEADY AIM~n~EQUIPMENT: Grenade Launcher");
		TextDrawBackgroundColor(p_ClassSetupTD[ i ], 255);
		TextDrawFont(p_ClassSetupTD[ i ], 2);
		TextDrawLetterSize(p_ClassSetupTD[ i ], 0.190000, 1.200000);
		TextDrawColor(p_ClassSetupTD[ i ], -1);
		TextDrawSetOutline(p_ClassSetupTD[ i ], 1);
		TextDrawSetProportional(p_ClassSetupTD[ i ], 1);
		TextDrawSetSelectable(p_ClassSetupTD[ i ], 0);
	}
}

stock SavePlayerData( playerid )
{
	static
		szQuery[ 720 ];

	if ( p_PlayerLogged{ playerid } == true )
	{
		format( szQuery, sizeof( szQuery ),
				"UPDATE `COD` SET SCORE=%d,KILLS=%d,DEATHS=%d,ADMIN=%d,XP=%d,RANK=%d,PRESTIGE=%d,PRIMARY1=%d,PRIMARY2=%d,PRIMARY3=%d,SECONDARY1=%d,SECONDARY2=%d,SECONDARY3=%d,PERK_ONE1=%d,PERK_ONE2=%d,PERK_ONE3=%d,PERK_TWO1=%d,PERK_TWO2=%d,PERK_TWO3=%d,SPECIAL1=%d,SPECIAL2=%d,SPECIAL3=%d,KILLSTREAK1=%d,KILLSTREAK2=%d,KILLSTREAK3=%d,MUTE_TIME=%d,CLASSNAME1='%s',CLASSNAME2='%s',CLASSNAME3='%s',HITMARKER=%d,HIT_SOUND=%d,LAST_LOGGED=%d,UPTIME=%d,",
				GetPlayerScore( playerid ), g_userData[ playerid ] [ E_KILLS ], g_userData[ playerid ] [ E_DEATHS ], g_userData[ playerid ] [ E_ADMIN ], g_userData[ playerid ] [ E_XP ], g_userData[ playerid ] [ E_RANK ],
				g_userData[ playerid ] [ E_PRESTIGE ], g_userData[ playerid ] [ E_PRIMARY1 ], g_userData[ playerid ] [ E_PRIMARY2 ], g_userData[ playerid ] [ E_PRIMARY3 ], g_userData[ playerid ] [ E_SECONDARY1 ],
				g_userData[ playerid ] [ E_SECONDARY2 ], g_userData[ playerid ] [ E_SECONDARY3 ], g_userData[ playerid ] [ E_PERK_ONE ] [ 0 ], g_userData[ playerid ] [ E_PERK_ONE ] [ 1 ], g_userData[ playerid ] [ E_PERK_ONE ] [ 2 ],
				g_userData[ playerid ] [ E_PERK_TWO ] [ 0 ], g_userData[ playerid ] [ E_PERK_TWO ] [ 1 ], g_userData[ playerid ] [ E_PERK_TWO ] [ 2 ], g_userData[ playerid ] [ E_SPECIAL ] [ 0 ], g_userData[ playerid ] [ E_SPECIAL ] [ 1 ],
				g_userData[ playerid ] [ E_SPECIAL ] [ 2 ], g_userData[ playerid ] [ E_KILLSTREAK1 ], g_userData[ playerid ] [ E_KILLSTREAK2 ], g_userData[ playerid ] [ E_KILLSTREAK3 ], g_userData[ playerid ] [ E_MUTE_TIME ],
				mysql_escape( g_userData[ playerid ] [ E_CLASS1 ] ), mysql_escape( g_userData[ playerid ] [ E_CLASS2 ] ), mysql_escape( g_userData[ playerid ] [ E_CLASS3 ] ),
				g_userData[ playerid ] [ E_HITMARKER ], g_userData[ playerid ] [ E_HIT_SOUND ], gettime( ), g_userData[ playerid ] [ E_UPTIME ] );

		format( szQuery, sizeof( szQuery ), "%sCASH=%d,WINS=%d,LOSES=%d,ZM_RANK=%d,ZM_XP=%d,ZM_KILLS=%d,ZM_DEATHS=%d,VIP=%d,VIP_EXPIRE=%d,DOUBLE_XP=%d,LIVES=%d,MEDKITS=%d,WEAPONS='%d|%d',SKIN=%d,ZM_SKIN=%d,ZM_PRESTIGE=%d WHERE ID=%d",
				szQuery, GetPlayerCash( playerid ), g_userData[ playerid ] [ E_VICTORIES ], g_userData[ playerid ] [ E_LOSSES ], g_userData[ playerid ] [ E_ZM_RANK ], g_userData[ playerid ] [ E_ZM_XP ], g_userData[ playerid ] [ E_ZM_KILLS ],
				g_userData[ playerid ] [ E_ZM_DEATHS ], g_userData[ playerid ] [ E_VIP_LEVEL ], g_userData[ playerid ] [ E_VIP_EXPIRE ], g_userData[ playerid ] [ E_DOUBLE_XP ], g_userData[ playerid ] [ E_LIVES ], g_userData[ playerid ] [ E_MEDKIT ],
				g_userData[ playerid ] [ E_WEAPONS ] [ 0 ], g_userData[ playerid ] [ E_WEAPONS ] [ 1 ], g_userData[ playerid ] [ E_SKIN ], g_userData[ playerid ] [ E_ZM_SKIN ], g_userData[ playerid ] [ E_ZM_PRESTIGE ], g_userData[ playerid ] [ E_ID ] );

		mysql_single_query( szQuery );
	}
	return 1;
}

stock AddAdminLogLine( szMessage[ ] )
{
	for( new iPos; iPos < sizeof( log__Text ) - 1; iPos++ )
		memcpy( log__Text[ iPos ], log__Text[ iPos + 1 ], 0, sizeof( log__Text[ ] ) * 4, sizeof( log__Text[ ] ) );

	strmid( log__Text[ 4 ], szMessage, 0, cellmax );

	format( szLargeString, 500,	"%s~n~%s~n~%s~n~%s~n~%s", log__Text[ 0 ], log__Text[ 1 ], log__Text[ 2 ], log__Text[ 3 ], log__Text[ 4 ] );
	TextDrawSetString( g_AdminLogTD, szLargeString );
}

stock IsWeaponInAnySlot(playerid, weaponid)
{
    new
        szWeapon, szAmmo
    ;
    GetPlayerWeaponData(playerid, GetWeaponSlot(weaponid), szWeapon, szAmmo);
    #pragma unused szAmmo
	if (szWeapon == weaponid) return true;
    return false;
}

stock CutSpectation( playerid )
{
	if ( playerid < 0 || playerid > MAX_PLAYERS ) return 0;
	foreach(new i : Player) {
		if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid ) {
			p_whomSpectating[ i ] = INVALID_PLAYER_ID;
			TogglePlayerSpectating( i, 0 );
			p_Spectating{ i } = false;
			SendServerMessage( i, "Spectation has been closed." );
	  	}
	}
	p_beingSpectated[ playerid ] = false;
	return 1;
}

stock AdvancedBan( playerid, szBannedBy[ ], szReason[ ], szIP[ ], lol_time=0 )
{
	static
		szPlayerNameBanned[ MAX_PLAYER_NAME ]
	;
	GetPlayerName( playerid, szPlayerNameBanned, MAX_PLAYER_NAME );

	format( szNormalString, sizeof( szNormalString ), "SELECT `NAME` FROM `BANS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( szPlayerNameBanned ) );
	mysql_function_query( dbHandle, szNormalString, true, "OnAdvanceBanCheck", "isssi", playerid, szBannedBy, szReason, szIP, lol_time );
}

thread OnAdvanceBanCheck( playerid, szBannedBy[ ], szReason[ ], szIP[ ], lol_time )
{
	static
	    szPlayerNameBanned[ MAX_PLAYER_NAME ], szSerial[ 41 ],
		fields, rows
	;

	GetPlayerName( playerid, szPlayerNameBanned, MAX_PLAYER_NAME );
	cache_get_data( rows, fields );

	if ( rows ) SendClientMessageToAdmins( -1, ""COL_ADMIN"[ADMIN]"COL_GREY" %s looked already banned thus no new entries were made.", szPlayerNameBanned );
	else
	{
		gpci( playerid, szSerial, sizeof( szSerial ) );
		format( szLargeString, sizeof( szLargeString ), "INSERT INTO `BANS`(`NAME`,`IP`,`REASON`,`BANBY`,`DATE`,`EXPIRE`,`SERVER`,`SERIAL`,`COUNTRY`,`ISP`) VALUES ('%s','%s','%s','%s',%d,%d,1,'%s','%s','%s')", mysql_escape( szPlayerNameBanned ), mysql_escape( szIP ), mysql_escape( szReason ), mysql_escape( szBannedBy ), gettime( ), lol_time, mysql_escape( szSerial ), mysql_escape( GetPlayerCountryCode( playerid ) ), mysql_escape( GetPlayerISP( playerid ) ) );
		mysql_single_query( szLargeString );
	}
	return KickPlayerTimed( playerid ), 1;
}

stock secondstotime(seconds, const delimiter[] = ", ")
{
    static const times[] = {
        1,
        60,
        3600,
        86400,
        604800,
        2419200,
        29030400
    };

    static const names[][] = {
        "second",
        "minute",
        "hour",
        "day",
        "week",
        "month",
        "year"
    };

    new string[128];

    for(new i = sizeof(times) - 1;  i != -1; i--)
    {
        if (seconds / times[i])
        {
            if (string[0])
            {
                format(string, sizeof(string), "%s%s%d %s%s", string, delimiter, (seconds / times[i]), names[i], ((seconds / times[i]) == 1) ? ("") : ("s"));
            }
            else
            {
                format(string, sizeof(string), "%d %s%s", (seconds / times[i]), names[i], ((seconds / times[i]) == 1) ? ("") : ("s"));
            }
            seconds -= ((seconds / times[i]) * times[i]);
        }
    }
    return string;
}

stock strreplacechar(string[], oldchar, newchar)
{
	new matches;
	if (ispacked(string)) {
		if (newchar == '\0') {
			for(new i; string{i} != '\0'; i++) {
				if (string{i} == oldchar) {
					strdel(string, i, i + 1);
					matches++;
				}
			}
		} else {
			for(new i; string{i} != '\0'; i++) {
				if (string{i} == oldchar) {
					string{i} = newchar;
					matches++;
				}
			}
		}
	} else {
		if (newchar == '\0') {
			for(new i; string[i] != '\0'; i++) {
				if (string[i] == oldchar) {
					strdel(string, i, i + 1);
					matches++;
				}
			}
		} else {
			for(new i; string[i] != '\0'; i++) {
				if (string[i] == oldchar) {
					string[i] = newchar;
					matches++;
				}
			}
		}
	}
	return matches;
}

stock SetBannedWeapons( ... )
{
	for( new i; i < sizeof( g_BannedWeapons ); i++ ) g_BannedWeapons{ i } = false;
	for( new count; count < numargs( ); count++ )
    {
        g_BannedWeapons{ getarg( count ) } = true;
   	}
}

stock textContainsIP(const string[])
{
    static
        RegEx:rCIP
    ;

    if ( !rCIP )
    {
        rCIP = regex_build("(.*?)([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})(.*?)");
    }

    return regex_match_exid(string, rCIP);
}

stock RangeBanPlayer( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

	new
	    szBan[ 24 ],
	    szIP[ 16 ]
	;
	GetPlayerIp( playerid, szIP, sizeof( szIP ) );
    GetRangeIP( szIP, sizeof( szIP ) );

	format( szBan, sizeof( szBan ), "banip %s", szIP );
	SendRconCommand( szBan );

	KickPlayerTimed( playerid );

	return 1;
}

stock GetRangeIP( szIP[ ], iSize = sizeof( szIP ) )
{
	new
		iCount = 0
	;
	for( new i; szIP[ i ] != '\0'; i ++ )
	{
	    if ( szIP[ i ] == '.' && ( iCount ++ ) == 1 )
	    {
	        strdel( szIP, i, strlen( szIP ) );
	        break;
	    }
	}
	format( szIP, iSize, "%s.*.*", szIP );
	return szIP;
}

stock textContainsBadTextdrawLetters( const string[ ] )
{
	for( new i, j = strlen( string ); i < j; i++ )
	{
	    if ( string[ i ] == '.' || string[ i ] == '*' || string[ i ] == '^' || string[ i ] == '~' || string[ i ] == '_' )
	        return true;
	}
	return false;
}

#if CUSTOM_SHOOTING == false
	stock GetWeaponModel(weaponid)
	{
	    switch(weaponid)
	    {
	        case 1:
	        	return 331;

	        case 2..8:
	            return weaponid+331;

			case 9:
	            return 341;

	        case 10..15:
	                return weaponid+311;

	        case 16..18:
	            return weaponid+326;

	        case 22..29:
	            return weaponid+324;

	        case 30,31:
	            return weaponid+325;

	        case 32:
	            return 372;

	        case 33..45:
	            return weaponid+324;

	        case 46:
	            return 371;
	    }
	    return 0;
	}
#endif

stock StopPlayerEditingCreateClass( playerid )
{
	for( new x; x < sizeof( p_ClassOptions ); x++ )
		PlayerTextDrawDestroy( playerid, p_ClassOptions[ x ] );

	p_SelectedOption{ playerid } = -1;
	DeletePVar( playerid, "editing_class" );
	TextDrawHideForPlayer( playerid, p_ClassName[ playerid ] );
	TextDrawHideForPlayer( playerid, p_ClassPrimary[ playerid ] );
	TextDrawHideForPlayer( playerid, p_ClassSecondary[ playerid ] );
	TextDrawHideForPlayer( playerid, g_ClassConfig[ 0 ] );
	TextDrawHideForPlayer( playerid, g_ClassConfig[ 1 ] );
	TextDrawHideForPlayer( playerid, g_ClassConfig[ 2 ] );
	TextDrawHideForPlayer( playerid, g_ClassConfig[ 3 ] );
	TextDrawHideForPlayer( playerid, g_ClassConfig[ 4 ] );
	TextDrawHideForPlayer( playerid, g_ClassConfig[ 5 ] );
	TextDrawHideForPlayer( playerid, g_ClassCustom[ 0 ] );
	TextDrawHideForPlayer( playerid, g_ClassCustom[ 1 ] );
	TextDrawHideForPlayer( playerid, g_ClassCustom[ 2 ] );
	TextDrawHideForPlayer( playerid, g_ClassCustom[ 3 ] );
	TextDrawHideForPlayer( playerid, g_ClassCustom[ 4 ] );
	TextDrawHideForPlayer( playerid, g_ClassCustom[ 5 ] );
	TextDrawHideForPlayer( playerid, g_ClassCustom[ 6 ] );
	TextDrawHideForPlayer( playerid, g_ClassKSSlots[ 0 ] );
	TextDrawHideForPlayer( playerid, g_ClassKSSlots[ 1 ] );
	TextDrawHideForPlayer( playerid, g_ClassKSSlots[ 2 ] );
	TextDrawHideForPlayer( playerid, p_ClassSetupTD[ playerid ] );
	TextDrawHideForPlayer( playerid, p_KillstreakSetupTD[ playerid ] );
	HidePlayerInfoDialog( playerid );
	ShowCreateaClassMenu( playerid );
	CancelSelectTextDraw( playerid );
	SendServerMessage( playerid, "You have finished editing your class." );
	return 1;
}

stock SetServerRule( rule[ ], value[ ] )
{
	new string[ 80 ];
	format( string, sizeof( string ), "%s %s", rule, value );
	SendRconCommand( string );
}

stock cencrypt( szLeFinale[ ], iSize = sizeof( szLeFinale ), szPassword[ ], szSalt[ 17 ], iPepper = 982963501 )
{
	new
    	szHash[ 256 ];

    WP_Hash( szHash, sizeof( szHash ), szPassword );

    format( szHash, sizeof( szHash ), "%d%s%s", iPepper, szHash, szSalt );
    WP_Hash( szLeFinale, iSize, szHash );
}

stock randomString(strDest[], strLen = 10)
{
    while(strLen--)
        strDest[strLen] = random(2) ? (random(26) + (random(2) ? 'a' : 'A')) : (random(10) + '0');
}

stock IsPlayerInWater(playerid)
{
    new animlib[32],tmp[32];
    GetAnimationName(GetPlayerAnimationIndex(playerid),animlib,32,tmp,32);
    if ( !strcmp(animlib, "SWIM") && !IsPlayerInAnyVehicle(playerid) ) return true;
    return false;
}

stock getPlayerFirstPerk( playerid )
{
	new
		selectedClass = p_SelectedGameClass[ playerid ];

	if ( selectedClass <= 0 )
		return -1;

	if ( selectedClass == 1 || selectedClass == 2 )
		return PERK_STOPPING_POWER;

	return g_userData[ playerid ] [ E_PERK_ONE ] [ selectedClass - 3 ];
}

stock getPlayerSecondPerk( playerid )
{
	new
		selectedClass = p_SelectedGameClass[ playerid ];

	if ( selectedClass <= 0 )
		return -1;

	if ( selectedClass == 1 || selectedClass == 2 )
		return PERK_STEADY_AIM;

	return g_userData[ playerid ] [ E_PERK_TWO ] [ selectedClass - 3 ];
}

stock getPlayerEquipment( playerid )
{
	new
		selectedClass = p_SelectedGameClass[ playerid ];

	if ( selectedClass <= 0 )
		return -1;

	if ( selectedClass == 1 || selectedClass == 2 )
		return EQUIPMENT_GRENADE;

	return g_userData[ playerid ] [ E_SPECIAL ] [ selectedClass - 3 ];
}

stock setAlpha( color, alpha )
{
	if ( alpha > 0xFF )
	    alpha	= 0xFF;
	else if ( alpha < 0x00 )
	    alpha	= 0x00;

	return ( color & 0xFFFFFF00 ) | alpha;
}

stock l4d_LoadNPC( )
{
	// Heli
	g_HelicopterNPC = FCNPC_Create( "Helicopter" );
	FCNPC_Spawn( g_HelicopterNPC, 0, 3000.0, 3000.0, 2000.0 );

	FCNPC_Spawn( ( g_DeathLogNPC[ 0 ] = FCNPC_Create( "Zombie" ) ), 0, 3000.0, 3000.0, 2000.0 );
	FCNPC_Spawn( ( g_DeathLogNPC[ 1 ] = FCNPC_Create( "Boomer" ) ), 0, 3000.0, 3000.0, 2000.0 );
	FCNPC_Spawn( ( g_DeathLogNPC[ 2 ] = FCNPC_Create( "Tank" ) ), 	0, 3000.0, 3000.0, 2000.0 );

  	CreateZombie( SKIN_TANK, 1000, 20.00, false );
  	CreateZombie( SKIN_TANK, 1000, 20.00, false );

	for( new i; i < MAX_ZOMBIES - 2; i++ ) // 10 * 2 (npcs) = 20 * 3 (timer)
	{
		if ( i < 5 )
			CreateZombie( SKIN_BOOMER, 50, 30.0 ); // Boomer
		else
    		CreateZombie( SKIN_ZOMBIE );
	}
}

stock CreateZombie( skinid, Float: health = 100.0, Float: damage = 5.0, bool: respawn = true, bool: permitted = false )
{
	new
		id = Iter_Free(zombies),
		string[ 12 ]
	;
	if ( id != -1 )
	{
    	Iter_Add( zombies, id );
		format( string, sizeof( string ), "Zombie_%03d", id );
		g_zombieData[ id ] [ E_NPCID ] = FCNPC_Create( string ); // Cannot assign a value on ongamemodeinit (bug)
		g_zombieData[ id ] [ E_DAMAGE ] = damage;
		g_zombieData[ id ] [ E_SKINID ] = skinid;
		g_zombieData[ id ] [ E_SPAWN_HEALTH ] = health; // Because the above gets changed.
		g_zombieData[ id ] [ E_RESPAWN ] = respawn;
		g_zombieData[ id ] [ E_PERMITTED ] = permitted;
		FCNPC_Spawn( g_zombieData[ id ] [ E_NPCID ], skinid, 3000.0, 3000.0, 2000.0 );
 		g_zombieData[ id ] [ E_HEALTH ] = health;
 		g_zombieData[ id ] [ E_SPEED ] = fRandomEx( 0.35, 0.9 );
	}
	return id;
}

cod_removeBuildings( playerid )
{
	RemoveBuildingForPlayer(playerid, 3294, -1420.5469, 2591.1563, 57.7422, 0.25); // VILLAGE
    RemoveBuildingForPlayer(playerid, 16295, 330.7500, 888.3828, 20.2813, 0.25); // War Outpost
	RemoveBuildingForPlayer(playerid, 16304, 353.5078, 832.4063, 21.7109, 0.25);
	RemoveBuildingForPlayer(playerid, 16302, 375.4453, 850.7500, 23.4297, 0.25);
	RemoveBuildingForPlayer(playerid, 16298, 382.7500, 806.5859, 13.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 16305, 390.5703, 875.8281, 24.0469, 0.25);
	RemoveBuildingForPlayer(playerid, 16481, 389.0391, 839.5000, 26.8906, 0.25);
	RemoveBuildingForPlayer(playerid, 16301, 419.0703, 814.7422, 18.4766, 0.25);
	RemoveBuildingForPlayer(playerid, 16318, 435.6719, 888.9141, -1.7656, 0.25);
	RemoveBuildingForPlayer(playerid, 16319, 444.3438, 899.5781, -8.1875, 0.25);
	RemoveBuildingForPlayer(playerid, 16316, 479.6094, 932.8203, -15.0703, 0.25);
	RemoveBuildingForPlayer(playerid, 16314, 485.0703, 809.4766, -2.7656, 0.25);
	RemoveBuildingForPlayer(playerid, 16081, 522.1563, 815.9453, 11.6797, 0.25);
	RemoveBuildingForPlayer(playerid, 16084, 526.5234, 885.4219, -44.3594, 0.25);
	RemoveBuildingForPlayer(playerid, 16297, 539.2266, 733.1875, 8.5078, 0.25);
	RemoveBuildingForPlayer(playerid, 16446, 537.7344, 839.3984, -37.9844, 0.25);
	RemoveBuildingForPlayer(playerid, 16299, 462.5781, 1005.1094, 28.9922, 0.25);
	RemoveBuildingForPlayer(playerid, 16082, 569.3281, 825.7969, -26.7734, 0.25);
	RemoveBuildingForPlayer(playerid, 16313, 569.0938, 825.2031, -31.0781, 0.25);
	RemoveBuildingForPlayer(playerid, 3398, 568.5391, 837.8906, -29.5156, 0.25);
	RemoveBuildingForPlayer(playerid, 16312, 589.5156, 828.7891, -32.8672, 0.25);
	RemoveBuildingForPlayer(playerid, 16315, 581.3047, 834.1250, -33.3984, 0.25);
	RemoveBuildingForPlayer(playerid, 3398, 601.4219, 814.6484, -30.4375, 0.25);
	RemoveBuildingForPlayer(playerid, 3398, 634.5234, 806.5625, -30.0547, 0.25);
	RemoveBuildingForPlayer(playerid, 16078, 662.8125, 833.6875, -39.3672, 0.25);
	RemoveBuildingForPlayer(playerid, 16080, 600.6328, 829.3594, -35.7344, 0.25);
	RemoveBuildingForPlayer(playerid, 16083, 602.2578, 829.7188, -41.8281, 0.25);
	RemoveBuildingForPlayer(playerid, 16079, 625.9141, 838.4141, -35.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 16085, 627.8672, 850.2734, -42.7734, 0.25);
	RemoveBuildingForPlayer(playerid, 16071, 674.7734, 854.5156, -39.3672, 0.25);
	RemoveBuildingForPlayer(playerid, 3214, 676.5859, 827.3281, -35.3672, 0.25);
	RemoveBuildingForPlayer(playerid, 3398, 668.3672, 815.2422, -30.1172, 0.25);
	RemoveBuildingForPlayer(playerid, 3214, 687.6250, 847.1094, -35.3828, 0.25);
	RemoveBuildingForPlayer(playerid, 3398, 684.2031, 835.6563, -30.8984, 0.25);
	RemoveBuildingForPlayer(playerid, 16300, 706.9609, 730.9375, 20.6641, 0.25);
	RemoveBuildingForPlayer(playerid, 16321, 787.7500, 790.8359, 17.8906, 0.25);
	RemoveBuildingForPlayer(playerid, 16359, 821.4063, 862.0781, 11.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 16075, 568.5234, 916.3438, -35.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 16309, 566.6484, 874.4844, -39.5313, 0.25);
	RemoveBuildingForPlayer(playerid, 3398, 576.1563, 934.9219, -30.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 16310, 581.3750, 875.6094, -43.9609, 0.25);
	RemoveBuildingForPlayer(playerid, 16311, 585.8438, 869.6328, -39.3672, 0.25);
	RemoveBuildingForPlayer(playerid, 16325, 590.2969, 870.2734, -44.2656, 0.25);
	RemoveBuildingForPlayer(playerid, 16073, 610.1641, 908.4766, -39.3672, 0.25);
	RemoveBuildingForPlayer(playerid, 16074, 605.0859, 902.1563, -39.3672, 0.25);
	RemoveBuildingForPlayer(playerid, 16077, 594.9297, 926.4141, -41.1953, 0.25);
	RemoveBuildingForPlayer(playerid, 16076, 623.3047, 893.7734, -39.7656, 0.25);
	RemoveBuildingForPlayer(playerid, 3398, 620.8359, 884.2422, -29.5156, 0.25);
	RemoveBuildingForPlayer(playerid, 16072, 640.3125, 874.7891, -35.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 16334, 709.4453, 915.9297, 34.6172, 0.25);
	RemoveBuildingForPlayer(playerid, 16337, 713.8047, 906.8125, -19.9141, 0.25);
	RemoveBuildingForPlayer(playerid, 16320, 777.1250, 938.4453, 21.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 16296, 638.4219, 1029.4609, 26.7422, 0.25); // End of War Outpost
	RemoveBuildingForPlayer(playerid, 11010, -2113.3203, -186.7969, 40.2813, 0.25); // Meltdown
	RemoveBuildingForPlayer(playerid, 11048, -2113.3203, -186.7969, 40.2813, 0.25);
	RemoveBuildingForPlayer(playerid, 11091, -2133.5547, -132.7031, 36.1328, 0.25);
	RemoveBuildingForPlayer(playerid, 11271, -2127.5469, -269.9609, 41.0000, 0.25);
	RemoveBuildingForPlayer(playerid, 11376, -2144.3516, -132.9609, 38.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -2126.0859, -279.8203, 48.3516, 0.25);
	RemoveBuildingForPlayer(playerid, 11081, -2127.5469, -269.9609, 41.0000, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -2097.6797, -178.2344, 48.3516, 0.25);
	RemoveBuildingForPlayer(playerid, 11011, -2144.3516, -132.9609, 38.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 11009, -2128.5391, -142.8438, 39.1406, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -2137.6172, -110.9375, 48.3516, 0.25); // End of Meltdown
	RemoveBuildingForPlayer(playerid, 5637, 2043.8984, -1138.3906, 31.0078, 0.25); // Injustice
	RemoveBuildingForPlayer(playerid, 1283, 2066.2578, -1249.8047, 26.0313, 0.25);
	RemoveBuildingForPlayer(playerid, 1297, 2062.1250, -1229.1797, 26.1016, 0.25);
	RemoveBuildingForPlayer(playerid, 1297, 2062.2500, -1194.5781, 26.1875, 0.25);
	RemoveBuildingForPlayer(playerid, 1283, 2066.1406, -1210.5625, 26.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 1308, 2057.0078, -1176.7422, 23.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 1297, 2062.2344, -1162.7109, 26.0859, 0.25);
	RemoveBuildingForPlayer(playerid, 1283, 2055.3516, -1136.6875, 26.1250, 0.25); // End of Injustice
	RemoveBuildingForPlayer(playerid, 3777, 868.1328, -1191.1406, 25.0391, 0.25); // Studio
	RemoveBuildingForPlayer(playerid, 5926, 816.3359, -1217.1484, 26.4453, 0.25);
	RemoveBuildingForPlayer(playerid, 3777, 902.3359, -1191.1406, 25.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 6005, 895.2578, -1256.9297, 31.2344, 0.25);
	RemoveBuildingForPlayer(playerid, 5836, 816.3359, -1217.1484, 26.4453, 0.25);
	RemoveBuildingForPlayer(playerid, 3776, 868.1328, -1191.1406, 25.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 5838, 895.2578, -1256.9297, 31.2344, 0.25);
	RemoveBuildingForPlayer(playerid, 3776, 902.3359, -1191.1406, 25.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 5837, 913.3906, -1235.1719, 17.6406, 0.25);
	RemoveBuildingForPlayer(playerid, 717, 875.6094, -1155.3750, 23.0000, 0.25);
	RemoveBuildingForPlayer(playerid, 717, 875.6094, -1134.6797, 23.0000, 0.25); // End of Studio
	RemoveBuildingForPlayer(playerid, 17349, -542.0078, -522.8438, 29.5938, 0.25); // Workfare
	RemoveBuildingForPlayer(playerid, 17019, -606.0313, -528.8203, 30.5234, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -573.0547, -559.6953, 38.5234, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -533.5391, -559.6953, 38.5469, 0.25);
	RemoveBuildingForPlayer(playerid, 1415, -541.4297, -561.2266, 24.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 17012, -542.0078, -522.8438, 29.5938, 0.25);
	RemoveBuildingForPlayer(playerid, 1415, -513.7578, -561.0078, 24.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 1441, -503.6172, -540.5313, 25.2266, 0.25);
	RemoveBuildingForPlayer(playerid, 1415, -502.6094, -528.6484, 24.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 1440, -502.1172, -521.0313, 25.0234, 0.25);
	RemoveBuildingForPlayer(playerid, 1441, -502.4063, -513.0156, 25.2266, 0.25);
	RemoveBuildingForPlayer(playerid, 1415, -620.4141, -490.5078, 24.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 1415, -619.6250, -473.4531, 24.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -573.0547, -479.9219, 38.5781, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -552.7656, -479.9219, 38.6250, 0.25);
	RemoveBuildingForPlayer(playerid, 1440, -553.6875, -481.6328, 25.0234, 0.25);
	RemoveBuildingForPlayer(playerid, 1441, -554.4531, -496.1797, 25.1641, 0.25);
	RemoveBuildingForPlayer(playerid, 1441, -537.0391, -469.1172, 25.2266, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -532.4688, -479.9219, 38.6484, 0.25);
	RemoveBuildingForPlayer(playerid, 1440, -516.9453, -496.6484, 25.0234, 0.25);
	RemoveBuildingForPlayer(playerid, 1440, -503.1250, -509.0000, 25.0234, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -512.1641, -479.9219, 38.5938, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -491.8594, -479.9219, 38.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 17020, -475.9766, -544.8516, 28.1172, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -471.5547, -479.9219, 38.6250, 0.25); // End of Workfare
	RemoveBuildingForPlayer(playerid, 3295, 1099.1172, -358.4766, 77.6172, 0.25);
	RemoveBuildingForPlayer(playerid, 3347, 1114.2969, -353.8203, 72.7969, 0.25); // Farmville
	RemoveBuildingForPlayer(playerid, 3347, 1107.5938, -358.5156, 72.7969, 0.25);
	RemoveBuildingForPlayer(playerid, 3376, 1070.4766, -355.1641, 77.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 785, 1150.3516, -343.1094, 58.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 785, 1091.6094, -250.0078, 71.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1012.2891, -282.5391, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1023.4219, -279.9063, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 1503, 1019.3203, -282.7891, 73.2031, 0.25);
	RemoveBuildingForPlayer(playerid, 694, 1045.8438, -270.9453, 75.4219, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1047.3125, -280.3359, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1059.2266, -281.2656, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1082.9922, -283.6797, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 791, 1091.6094, -250.0078, 71.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 694, 1130.1719, -278.6172, 70.7031, 0.25);
	RemoveBuildingForPlayer(playerid, 694, 1137.7031, -313.9141, 68.9531, 0.25);
	RemoveBuildingForPlayer(playerid, 13451, 1146.1406, -369.1328, 49.3281, 0.25);
	RemoveBuildingForPlayer(playerid, 791, 1150.3516, -343.1094, 58.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 3425, 1015.0938, -361.1016, 84.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1007.6719, -361.6250, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1007.6250, -349.8984, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1007.5234, -326.4453, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1007.4766, -314.7188, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1007.4297, -302.9922, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1007.3828, -291.2578, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 696, 1075.1641, -391.5078, 74.8281, 0.25);
	RemoveBuildingForPlayer(playerid, 698, 1053.2891, -378.6719, 74.4297, 0.25);
	RemoveBuildingForPlayer(playerid, 698, 1092.4688, -383.6172, 74.8906, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1083.6641, -368.5313, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1071.9375, -368.5156, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1060.2109, -368.4922, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3375, 1070.4766, -355.1641, 77.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 1308, 1094.4141, -367.9688, 72.8984, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1092.7109, -327.0625, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1095.3984, -329.8203, 73.5078, 0.25);
	RemoveBuildingForPlayer(playerid, 700, 1095.3828, -327.4766, 73.1797, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1092.7969, -321.4844, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1092.9063, -315.9688, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1093.1953, -299.2969, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 13206, 1072.9531, -289.1797, 72.7344, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1093.3047, -293.7813, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1096.1563, -291.2656, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 656, 1096.6250, -294.4141, 72.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 3286, 1099.1172, -358.4766, 77.6172, 0.25);
	RemoveBuildingForPlayer(playerid, 3175, 1107.5938, -358.5156, 72.7969, 0.25);
	RemoveBuildingForPlayer(playerid, 3276, 1107.1172, -368.5703, 73.8438, 0.25);
	RemoveBuildingForPlayer(playerid, 3253, 1106.6406, -319.8750, 73.7422, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1106.4922, -330.0234, 73.5078, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1100.9141, -329.9297, 73.5078, 0.25);
	RemoveBuildingForPlayer(playerid, 700, 1106.5469, -328.1641, 73.1797, 0.25);
	RemoveBuildingForPlayer(playerid, 1308, 1101.2891, -329.5313, 72.8984, 0.25);
	RemoveBuildingForPlayer(playerid, 3250, 1110.2422, -298.9453, 73.0391, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1101.6719, -291.3750, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1107.2656, -291.4609, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 672, 1097.4688, -314.2109, 73.6641, 0.25);
	RemoveBuildingForPlayer(playerid, 3175, 1114.2969, -353.8203, 72.7969, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1117.5781, -330.2109, 73.5078, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1112.0000, -330.1250, 73.5078, 0.25);
	RemoveBuildingForPlayer(playerid, 656, 1116.4453, -326.7578, 72.9375, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1112.7813, -291.5703, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1118.3750, -291.6641, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1120.4297, -327.7656, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1121.0234, -294.5234, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1120.6250, -316.7344, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1120.9297, -300.1172, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1120.8203, -305.6328, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1120.7344, -311.2188, 73.5703, 0.25);
	RemoveBuildingForPlayer(playerid, 1408, 1120.5391, -322.2500, 73.5703, 0.25); // End of Farmville
	RemoveBuildingForPlayer(playerid, 3647, 2470.8203, -1640.8203, 15.0234, 0.25); // GSF
	RemoveBuildingForPlayer(playerid, 3706, 2520.1875, -1694.8516, 14.8828, 0.25);
	RemoveBuildingForPlayer(playerid, 3646, 2520.1875, -1694.8516, 14.8828, 0.25);
	RemoveBuildingForPlayer(playerid, 1468, 2464.5000, -1648.8438, 13.8125, 0.25);
	RemoveBuildingForPlayer(playerid, 3648, 2470.8203, -1640.8203, 15.0234, 0.25); // End of GSF
	RemoveBuildingForPlayer(playerid, 691, 1144.0781, -2076.3750, 68.1016, 0.25); // Parliment
	RemoveBuildingForPlayer(playerid, 661, 1159.9766, -2075.1563, 67.1484, 0.25);
	RemoveBuildingForPlayer(playerid, 618, 1155.3672, -2072.5547, 67.8594, 0.25);
	RemoveBuildingForPlayer(playerid, 691, 1175.6094, -2079.4688, 67.7969, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1137.5078, -2070.0313, 71.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1174.7500, -2070.0313, 71.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 762, 1189.7734, -2078.3672, 70.7422, 0.25);
	RemoveBuildingForPlayer(playerid, 661, 1197.8516, -2074.6172, 67.5313, 0.25);
	RemoveBuildingForPlayer(playerid, 691, 1207.6094, -2079.0781, 66.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1205.3438, -2070.0313, 71.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1208.7109, -2059.3203, 75.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1208.4297, -2045.2422, 75.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1208.9141, -2025.9297, 75.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1138.4375, -2003.9141, 71.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 618, 1139.1797, -1997.7656, 67.5547, 0.25);
	RemoveBuildingForPlayer(playerid, 618, 1146.1328, -1998.4688, 67.5547, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1175.1797, -2003.9141, 71.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 712, 1208.9141, -2012.8516, 75.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, 1205.4141, -2003.9141, 71.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 691, 1208.6484, -2000.0703, 67.3906, 0.25); // End of Parliment
	RemoveBuildingForPlayer(playerid, 16135, -326.2891, 1851.4141, 41.7344, 0.25); // VillageV2
	RemoveBuildingForPlayer(playerid, 16051, -386.4297, 2208.4063, 44.5625, 0.25);
	RemoveBuildingForPlayer(playerid, 16637, -389.5938, 2227.9141, 42.9219, 0.25);
	RemoveBuildingForPlayer(playerid, 16054, -427.7734, 2238.2578, 44.7969, 0.25);
	RemoveBuildingForPlayer(playerid, 16636, -340.1250, 2228.1250, 42.0078, 0.25);
	RemoveBuildingForPlayer(playerid, 16690, -358.9375, 2217.6953, 46.0000, 0.25);
	RemoveBuildingForPlayer(playerid, 16631, -335.5234, 2229.6094, 42.0078, 0.25);
	RemoveBuildingForPlayer(playerid, 16053, -400.4453, 2242.2344, 45.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 16689, -367.8281, 2248.8750, 44.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 16294, 15.1797, 1719.3906, 21.6172, 0.25);
	RemoveBuildingForPlayer(playerid, 3267, 15.6172, 1719.1641, 22.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 3277, 15.6016, 1719.1719, 22.3750, 0.25);
	RemoveBuildingForPlayer(playerid, 3279, 113.3828, 1814.4531, 16.8203, 0.25);
	RemoveBuildingForPlayer(playerid, 16094, 191.1406, 1870.0391, 21.4766, 0.25);
	RemoveBuildingForPlayer(playerid, 3279, 103.8906, 1901.1016, 16.8203, 0.25); // End of VillageV2
	RemoveBuildingForPlayer(playerid, 3682, 247.9297, 1461.8594, 33.4141, 0.25); // Silo
	RemoveBuildingForPlayer(playerid, 3682, 192.2734, 1456.1250, 33.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 3682, 199.7578, 1397.8828, 33.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 3683, 133.7422, 1356.9922, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3683, 166.7891, 1356.9922, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3683, 166.7891, 1392.1563, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3683, 133.7422, 1392.1563, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3683, 166.7891, 1426.9141, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3683, 133.7422, 1426.9141, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3288, 221.5703, 1374.9688, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3289, 212.0781, 1426.0313, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3290, 218.2578, 1467.5391, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3291, 246.5625, 1435.1953, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3291, 246.5625, 1410.5391, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3291, 246.5625, 1385.8906, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3291, 246.5625, 1361.2422, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3290, 190.9141, 1371.7734, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3289, 183.7422, 1444.8672, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3289, 222.5078, 1444.6953, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3289, 221.1797, 1390.2969, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3288, 223.1797, 1421.1875, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3683, 133.7422, 1459.6406, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3289, 207.5391, 1371.2422, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3424, 220.6484, 1355.1875, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3424, 221.7031, 1404.5078, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3424, 210.4141, 1444.8438, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3424, 262.5078, 1465.2031, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3259, 220.6484, 1355.1875, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3636, 133.7422, 1356.9922, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3636, 166.7891, 1356.9922, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3256, 190.9141, 1371.7734, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3636, 166.7891, 1392.1563, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3636, 133.7422, 1392.1563, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3258, 207.5391, 1371.2422, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 205.6484, 1394.1328, 10.1172, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 205.6484, 1392.1563, 16.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 205.6484, 1394.1328, 23.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 207.3594, 1390.5703, 19.1484, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 206.5078, 1387.8516, 27.4922, 0.25);
	RemoveBuildingForPlayer(playerid, 3673, 199.7578, 1397.8828, 33.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 3257, 221.5703, 1374.9688, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3258, 221.1797, 1390.2969, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 203.9531, 1409.9141, 16.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3674, 199.3828, 1407.1172, 35.8984, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 204.6406, 1409.8516, 11.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 206.5078, 1404.2344, 18.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 206.5078, 1400.6563, 22.4688, 0.25);
	RemoveBuildingForPlayer(playerid, 3259, 221.7031, 1404.5078, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 207.3594, 1409.0000, 19.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 3257, 223.1797, 1421.1875, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3258, 212.0781, 1426.0313, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3636, 166.7891, 1426.9141, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3636, 133.7422, 1426.9141, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3255, 246.5625, 1361.2422, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3255, 246.5625, 1385.8906, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3255, 246.5625, 1410.5391, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3258, 183.7422, 1444.8672, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3259, 210.4141, 1444.8438, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3258, 222.5078, 1444.6953, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 16086, 232.2891, 1434.4844, 13.5000, 0.25);
	RemoveBuildingForPlayer(playerid, 3673, 192.2734, 1456.1250, 33.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 3674, 183.0391, 1455.7500, 35.8984, 0.25);
	RemoveBuildingForPlayer(playerid, 3636, 133.7422, 1459.6406, 17.0938, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 196.0234, 1462.0156, 10.1172, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 198.0000, 1462.0156, 16.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 196.0234, 1462.0156, 23.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 180.2422, 1460.3203, 16.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 180.3047, 1461.0078, 11.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 3256, 218.2578, 1467.5391, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 199.5859, 1463.7266, 19.1484, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 181.1563, 1463.7266, 19.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 185.9219, 1462.8750, 18.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 202.3047, 1462.8750, 27.4922, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 189.5000, 1462.8750, 22.4688, 0.25);
	RemoveBuildingForPlayer(playerid, 3255, 246.5625, 1435.1953, 9.6875, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 254.6797, 1451.8281, 27.4922, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 253.8203, 1458.1094, 23.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 255.5313, 1454.5469, 19.1484, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 253.8203, 1456.1328, 16.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 253.8203, 1458.1094, 10.1172, 0.25);
	RemoveBuildingForPlayer(playerid, 3259, 262.5078, 1465.2031, 9.5859, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 254.6797, 1468.2109, 18.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 3673, 247.9297, 1461.8594, 33.4141, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 254.6797, 1464.6328, 22.4688, 0.25);
	RemoveBuildingForPlayer(playerid, 3674, 247.5547, 1471.0938, 35.8984, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 255.5313, 1472.9766, 19.7578, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 252.8125, 1473.8281, 11.4063, 0.25);
	RemoveBuildingForPlayer(playerid, 3675, 252.1250, 1473.8906, 16.2969, 0.25);
	RemoveBuildingForPlayer(playerid, 16087, 358.6797, 1430.4531, 11.6172, 0.25); // End of Silo
	RemoveBuildingForPlayer(playerid, 1345, 2321.1172, 14.3359, 26.1953, 0.25); // Street Wars
	RemoveBuildingForPlayer(playerid, 12821, 2327.7578, 11.4688, 26.4297, 0.25);
	RemoveBuildingForPlayer(playerid, 12955, 2316.2266, 55.4453, 27.9844, 0.25); // End of Street Wars
}

l4d_removeBuildings( playerid )
{
	// -- Fort Carson Madness
	RemoveBuildingForPlayer(playerid, 3297, -130.3750, 972.1172, 20.6406, 0.25);
	RemoveBuildingForPlayer(playerid, 16737, -94.6172, 923.2891, 26.1797, 0.25);
	RemoveBuildingForPlayer(playerid, 3242, -130.3750, 972.1172, 20.6406, 0.25);
	RemoveBuildingForPlayer(playerid, 16736, 11.0156, 959.8828, 24.7031, 0.25);

	// -- Mall of the Dead
	RemoveBuildingForPlayer(playerid, 4229, 1597.9063, -1699.7500, 30.2109, 0.25);
	RemoveBuildingForPlayer(playerid, 4230, 1597.9063, -1699.7500, 30.2109, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1461.6563, -1707.6875, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1461.1250, -1687.5625, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1496.9766, -1686.8516, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 620, 1503.1875, -1621.1250, 11.8359, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1477.9375, -1652.7266, 15.6328, 0.25);
	RemoveBuildingForPlayer(playerid, 1231, 1466.4688, -1637.9609, 15.6328, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, 1465.8906, -1629.9766, 15.5313, 0.25);
}

stock IsLegitimateNPC( playerid )
	return ( IsPlayerNPC( playerid ) && strmatch( ReturnPlayerIP( playerid ), "127.0.0.1" ) );

stock SpawnAvailableZombie( skinid )
{
	new
	    id;

	for( id = 0; id < MAX_ZOMBIES; ++id )
	    if ( !g_zombieData[ id ] [ E_PERMITTED ] && g_zombieData[ id ] [ E_SKINID ] == skinid ) break;

	if ( id < 0 || id >= MAX_ZOMBIES )
	    return 0;

	if ( g_zombieData[ id ] [ E_PERMITTED ] == true || !IsPlayerConnected( g_zombieData[ id ] [ E_NPCID ] ) || g_zombieData[ id ] [ E_SKINID ] != skinid )
	    return 0;

	g_zombieData[ id ] [ E_PERMITTED ] = true;

	FCNPC_Respawn( g_zombieData[ id ] [ E_NPCID ] );
	return 1;
}

stock GetZombieIDFromNPC( playerid )
{
	static
		name[ 11 ]; // Zombie_999 = 10 characters

	GetPlayerName( playerid, name, sizeof( name ) );
	return strval( name[ 7 ] );
}

stock GetZombieType( zombieid ) {
	switch( g_zombieData[ zombieid ] [ E_SKINID ] ) {
		case SKIN_ZOMBIE: 	return 0;
		case SKIN_BOOMER: 	return 1;
		case SKIN_TANK: 	return 2;
	}
	return 0;
}

stock CreateDroppablePickup( Float: X, Float: Y, Float: Z, bool: Tank )
{
	new pickupid;

	for( pickupid = 0; pickupid < MAX_DROPPABLE_PICKUPS; ++pickupid )
	    if ( !g_pickupData[ pickupid ] [ E_CREATED ] ) break;

	if ( pickupid >= MAX_DROPPABLE_PICKUPS || g_pickupData[ pickupid ] [ E_CREATED ] )
	{
	    new
			bool: success = false;

		for( pickupid = 0; pickupid < MAX_DROPPABLE_PICKUPS; ++pickupid ) {
	    	if ( g_pickupData[ pickupid ] [ E_CREATED ] && ( gettime( ) - g_pickupData[ pickupid ] [ E_TIMESTAMP ] ) > 10 ) {
	    	    success = true;
				break;
			}
		}

		if ( !success )
		    return -1; // Still cannot find any...? Then fuck it.

		DestroyDroppablePickup( pickupid ); // We're continuing on this ID.
	}

	g_pickupData[ pickupid ] [ E_CREATED ] = true;
	g_pickupData[ pickupid ] [ E_TIMESTAMP ] = gettime( );

	new iRandom = random( 101 );

	switch( iRandom )
	{
		case 0 .. 50:
		{
		    g_pickupData[ pickupid ] [ E_TYPE ] = PICKUP_TYPE_MONEY;
		    g_pickupData[ pickupid ] [ E_TANK ] = Tank;
			g_pickupData[ pickupid ] [ E_PICKUP_ID ] = Tank == false ? CreateDynamicPickup( 1212, 1, X, Y, Z - 0.5, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] ) : CreateDynamicPickup( 1550, 1, X, Y, Z, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] );
		}
		case 51 .. 75: {
			g_pickupData[ pickupid ] [ E_TYPE ] = PICKUP_TYPE_AMMO;
		    g_pickupData[ pickupid ] [ E_AMMO ] = RandomEx( 100, 200 );
			g_pickupData[ pickupid ] [ E_PICKUP_ID ] = CreateDynamicPickup( 2043, 1, X, Y, Z, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] );
		}
		case 76:
		{
			g_pickupData[ pickupid ] [ E_TYPE ] = PICKUP_TYPE_HEALTH;
			g_pickupData[ pickupid ] [ E_PICKUP_ID ] = CreateDynamicPickup( 1240, 1, X, Y, Z, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] );
		}
		case 77 .. 100: {
			g_pickupData[ pickupid ] [ E_TYPE ] 	 = PICKUP_TYPE_WEAPON;
			g_pickupData[ pickupid ] [ E_WEAPON ]	 = randarg( 8, 9, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33 );
		    g_pickupData[ pickupid ] [ E_AMMO ] 	 = RandomEx( 50, 100 );
			g_pickupData[ pickupid ] [ E_PICKUP_ID ] = CreateDynamicPickup( GetWeaponModel( g_pickupData[ pickupid ] [ E_WEAPON ] ), 1, X, Y, Z, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] );
		}
	}
	return pickupid;
}

class DestroyDroppablePickup( pickupid )
{
	if ( pickupid >= MAX_DROPPABLE_PICKUPS || pickupid < 0 )
	    return 0;

	if ( !g_pickupData[ pickupid ] [ E_CREATED ] )
	    return 0;

	g_pickupData[ pickupid ] [ E_CREATED ] = false;
	DestroyDynamicPickup( g_pickupData[ pickupid ] [ E_PICKUP_ID ] );
	g_pickupData[ pickupid ] [ E_TANK ] = false;
	return 1;
}

stock GivePlayerCash( playerid, money )
{
    g_userData[ playerid ] [ E_CASH ] += money;
    ResetPlayerMoney( playerid );
    GivePlayerMoney( playerid, g_userData[ playerid ] [ E_CASH ] );
}

stock SetPlayerCash( playerid, money )
{
    g_userData[ playerid ] [ E_CASH ] = money;
    ResetPlayerMoney( playerid );
    GivePlayerMoney( playerid, g_userData[ playerid ] [ E_CASH ] );
}

stock ResetPlayerCash( playerid )
{
    g_userData[ playerid ] [ E_CASH ] = 0;
    ResetPlayerMoney( playerid );
    GivePlayerMoney( playerid, g_userData[ playerid ] [ E_CASH ] );
}

stock StopPlayerFade( playerid )
{
	if ( !IsValidPlayerID( playerid ) )
	    return 1;

	TextDrawHideForPlayer( playerid, p_FadeBoxTD[ playerid ] );
	KillTimer( p_BoxFadeTimer[ playerid ] );
	p_BoxFadeTimer[ playerid ] = 0xFFFF;
	p_BoxFading{ playerid } = false;
	return 0;
}

stock FadePlayerScreen( playerid )
{
	if ( !IsPlayerConnected( playerid ) && !IsPlayerNPC( playerid ) )
	    return 0;

    StopPlayerFade( playerid );
	p_BoxOcapacity[ playerid ] = 1;
	p_BoxFading{ playerid } = true;
	p_BoxFadeTimer[ playerid ] = SetTimerEx( "FadeScreen", 150, true, "dd", playerid, 0 );
	return 1;
}

class FadeScreen( playerid, mode )
{
	if ( !IsPlayerConnected( playerid ) )
		return StopPlayerFade( playerid );

	if ( mode == 0 )
	{
		if ( p_BoxOcapacity[ playerid ] >= 250 )
		{
		    p_BoxOcapacity[ playerid ] = 255;
			TextDrawBoxColor( Text: p_FadeBoxTD[ playerid ], 255 );
			TextDrawShowForPlayer( playerid, p_FadeBoxTD[ playerid ] );
			KillTimer( p_BoxFadeTimer[ playerid ] );
			p_BoxFadeTimer[ playerid ] = 0xFFFF;
			p_BoxFading{ playerid } = false;
			p_BoxFadeTimer[ playerid ] = SetTimerEx( "FadeScreen", 75, true, "dd", playerid, 1 );
			return 1;
		}
		p_BoxOcapacity[ playerid ] += 5;
		TextDrawBoxColor( Text: p_FadeBoxTD[ playerid ], p_BoxOcapacity[ playerid ] );
		TextDrawShowForPlayer( playerid, p_FadeBoxTD[ playerid ] );
	}
	else
	{
		if ( p_BoxOcapacity[ playerid ] <= 5 )
		{
			p_BoxOcapacity[ playerid ] = 255;
			TextDrawBoxColor( Text: p_FadeBoxTD[ playerid ], p_BoxOcapacity[ playerid ] );
			StopPlayerFade( playerid );
			return 1;
		}
		p_BoxOcapacity[ playerid ] -= 2;
		TextDrawBoxColor( Text: p_FadeBoxTD[ playerid ], p_BoxOcapacity[ playerid ] );
		TextDrawShowForPlayer( playerid, p_FadeBoxTD[ playerid ] );
	}
	return 1;
}

stock GetZombieName( zombieid )
{
	static
		szName[ 7 ];

	switch( GetPlayerSkin( g_zombieData[ zombieid ] [ E_NPCID ] ) )
	{
		case SKIN_ZOMBIE: szName = "Zombie";
		case SKIN_TANK: szName = "Tank";
		case SKIN_BOOMER: szName = "Boomer";
	}
	return szName;
}

stock ShowPlayerShopMenu( playerid )
{
	static
	    szString[ 800 ];

	if ( szString[ 0 ] == '\0' )
	{
	    for( new i; i < sizeof( g_shopData ); i++ )
	    {
	        format( szString, sizeof( szString ), "%s{FF4D4D}%s\t\t"COL_WHITE"%s(%d)\n", szString, ConvertPrice( g_shopData[ i ] [ E_PRICE ] ), g_shopData[ i ] [ E_NAME ], g_shopData[ i ] [ E_AMMO ] );
	    }
	}
	return ShowPlayerDialog( playerid, DIALOG_SHOP_WEAPONS, DIALOG_STYLE_LIST, ""COL_WHITE"Pre-Game Shop", szString, "Purchase", IsPlayerSpawned( playerid ) ? ("Back") : ("Cancel") );
}

stock ConvertPrice( iValue, iCashSign = 1 )
{
	static
		szNum[ 32 ]
	;
	format( szNum, sizeof( szNum ), "%d", iValue < 0 ? -iValue : iValue );

    for( new i = strlen( szNum ) - 3; i > 0; i -= 3 ) {
        strins( szNum, ",", i, sizeof( szNum ) );
    }

	if ( iCashSign )	 strins( szNum, "$", 0 );
    if ( iValue < 0 ) strins( szNum, "-", 0, sizeof( szNum ) );

    return szNum;
}

stock TextDrawShowForAllInMode( mode, Text: text )
{
	switch( mode )
	{
		case MODE_MULTIPLAYER:
		{
			foreach(new i : mp_players) if ( IsPlayerSpawned( i ) )
				TextDrawShowForPlayer( i, text );
		}
		case MODE_ZOMBIES:
		{
			foreach(new i : zm_players) if ( IsPlayerSpawned( i ) )
				TextDrawShowForPlayer( i, text );
		}
	}
}

stock AddFileLogLine( file[ ], input[ ] )
{
    new
		File: fHandle
	;
    fHandle = fopen(file, io_append);
    fwrite(fHandle, input);
    fclose(fHandle);
    return 1;
}

stock getCurrentDate( )
{
	static
		Year, Month, Day,
		szString[ 11 ]
	;

	getdate( Year, Month, Day );
	format( szString, sizeof( szString ), "%02d/%02d/%d", Day, Month, Year );
	return szString;
}

stock getCurrentTime( )
{
	static
		Hour, Minute, Second,
		szString[ 11 ]
	;

	gettime( Hour, Minute, Second );
	format( szString, sizeof( szString ), "%02d:%02d:%02d", Hour, Minute, Second );
	return szString;
}

stock SendClientMessageToMode( mode, color, const text[] )
{
	switch( mode )
	{
		case MODE_MULTIPLAYER:
		{
			foreach(new i : mp_players)
				SendClientMessage( i, color, text );
		}
		case MODE_ZOMBIES:
		{
			foreach(new i : zm_players)
				SendClientMessage( i, color, text );
		}
	}
}

stock TogglePlayerDeadMode( playerid )
{
	if ( IsPlayerConnected( playerid ) && !IsPlayerNPC( playerid ) && IsPlayerInZombies( playerid ) )
	{
		if ( p_goingtoMenu[ playerid ] ) return 0;

		p_Spawned{ playerid } = false;
		TextDrawHideForPlayer( playerid, g_RankBoxTD );
		TextDrawHideForPlayer( playerid, g_RankTD );
		TextDrawHideForPlayer( playerid, g_WebsiteTD[ 1 ] );
		TextDrawHideForPlayer( playerid, g_EvacuationTD );
		TextDrawHideForPlayer( playerid, g_MotdTD );
		TextDrawHideForPlayer( playerid, p_XPAmountTD[ playerid ] );
		TextDrawHideForPlayer( playerid, p_RankTD[ playerid ] );

		SetPlayerVirtualWorld( playerid, g_zm_mapData[ g_zm_gameData[ E_MAP ] ] [ E_WORLD ] ), SetPlayerInterior( playerid, 0 ); // BECAUSE DERP WHEN U MAINMENU

		p_SpectateMode{ playerid } = false; // Any bugs ^.^

		new iPlayers = getAliveSurvivors( );

		if ( !iPlayers )
		{
		    zm_EndCurrentGame( false, ""COL_GREY"[SERVER]"COL_WHITE" All survivors have died, a new round is now loading." );
		    return 1;
		}
		else
		{
			foreach(new i : zm_players)
			{
			    if ( !p_SpectateMode{ i } && i != playerid )
			    {
				    TogglePlayerSpectating( playerid, 1 );
				    if ( IsPlayerInAnyVehicle( i ) ) PlayerSpectateVehicle( playerid, GetPlayerVehicleID( i ) );
					else PlayerSpectatePlayer( playerid, i );
				    p_SpectatingPlayer[ playerid ] = i;
					p_SpectateMode{ playerid } = true;
					if ( g_userData[ playerid ] [ E_LIVES ] ) SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You %d lives left. To resurrect back into the game, type "COL_GREY"/resurrect"COL_WHITE".", g_userData[ playerid ] [ E_LIVES ] );
					g_userData[ playerid ] [ E_LAST_LOGGED ] = gettime( );
					break;
			    }
			}
		}

		format( szNormalString, sizeof( szNormalString ), "~g~%s(%d)~w~~n~Left Click = Next Player and Right Click = Previous Player~n~~n~Evacuation: %s", ReturnPlayerName( p_SpectatingPlayer[ playerid ] ), p_SpectatingPlayer[ playerid ], g_EvacuationTime > 0 ? TimeConvert( g_EvacuationTime ) : ("Started") );
		TextDrawSetString( g_SpectateTD[ playerid ], szNormalString );
		TextDrawShowForPlayer( playerid, g_SpectateBoxTD );
		TextDrawShowForPlayer( playerid, g_SpectateTD[ playerid ] );
	}
	return 1;
}

stock getAliveSurvivors( )
{
	if ( Iter_Count(zm_players) )
	{
		new
			iPlayers = 0;

		foreach(new i : zm_players)
		{
			if ( IsPlayerSpawned( i ) && GetPlayerState( i ) != PLAYER_STATE_SPECTATING )
			{
				iPlayers++;
			}
		}

		return iPlayers;
	}
	return 0;
}

stock ShowCircularProgress( playerid, title[ ], pID, time )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

	if ( p_ProgressStarted{ playerid } )
		return 0xA1;

	for( new i; i < sizeof( p_ProgressCircleTD ); i++ )
		TextDrawHideForPlayer( playerid, p_ProgressCircleTD[ i ] );

	TextDrawSetString( p_ProgressTextTD[ playerid ], title );
	TextDrawShowForPlayer( playerid, p_ProgressTextTD[ playerid ] );

    p_ProgressStatus{ playerid } = 0;
	p_ProgressType{ playerid } = pID;
	p_ProgressStarted{ playerid } = true;

    new rate = floatround( time / 60 );

	SetTimerEx( "CirclularBarUpdate", rate, false, "ddd", playerid, pID, rate );
	return 1;
}

class CirclularBarUpdate( playerid, progressid, tickrate )
{
	if ( !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) || p_ProgressStarted{ playerid } == false )
	{
    	StopProgressBar( playerid );
		CallLocalFunction( "OnPlayerProgressUpdate", "dd", playerid, progressid ); // Just to unset any variables
	    return 0;
	}

	if ( ++p_ProgressStatus{ playerid } < 60 )
    	TextDrawShowForPlayer( playerid, p_ProgressCircleTD[ p_ProgressStatus{ playerid } ] );

	CallLocalFunction( "OnPlayerProgressUpdate", "dd", playerid, progressid );

	if ( p_ProgressStatus{ playerid } >= 60 )
	{
    	StopProgressBar( playerid );
    	CallLocalFunction( "OnPlayerProgressComplete", "dd", playerid, progressid );
    	return 1;
 	}
	return SetTimerEx( "CirclularBarUpdate", tickrate, false, "ddd", playerid, progressid, tickrate );
}

stock StopProgressBar( playerid )
{
	for( new i; i < sizeof( p_ProgressCircleTD ); i++ )
		TextDrawHideForPlayer( playerid, p_ProgressCircleTD[ i ] );
	TextDrawHideForPlayer( playerid, p_ProgressTextTD[ playerid ] );
	p_ProgressStarted{ playerid } = false;
    p_ProgressStatus{ playerid } = 0;
	return 1;
}

stock StopPlayer( playerid )
{
	static
		Float: X, Float: Y, Float: Z;

	GetPlayerPos( playerid, X, Y, Z );
	return SetPlayerPos( playerid, X, Y, Z );
}

stock SetPlayerVipLevel( pID, level )
{
	if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return;

	new
		giveDays = 0,
		double_xp = 0
	;

	switch( level )
	{
	    case 1:
	    {
	    	g_userData[ pID ] [ E_LIVES ] += 5;
	    	g_userData[ pID ] [ E_MEDKIT ] += 5;
	    	giveDays = 2592000;
	    	double_xp = 604800;
	    	GivePlayerCash( pID, 15000 );
	    }
	    case 2:
	    {
	    	g_userData[ pID ] [ E_LIVES ] += 20;
	    	g_userData[ pID ] [ E_MEDKIT ] += 20;
	    	giveDays = 5184000;
	    	double_xp = 1814400;
	    	GivePlayerCash( pID, 50000 );
	    }
	    case 3:
	    {
	    	g_userData[ pID ] [ E_LIVES ] += 50;
	    	g_userData[ pID ] [ E_MEDKIT ] += 50;
	    	giveDays = 10368000;
	    	double_xp = 5184000;
	    	GivePlayerCash( pID, 100000 );
		}
	}

	if ( g_userData[ pID ] [ E_VIP_LEVEL ] < level ) g_userData[ pID ] [ E_VIP_LEVEL ] = level;

    if ( g_userData[ pID ] [ E_VIP_EXPIRE ] > gettime( ) ) g_userData[ pID ] [ E_VIP_EXPIRE ] += giveDays;
    else g_userData[ pID ] [ E_VIP_EXPIRE ] += ( gettime( ) + giveDays );

    if ( g_userData[ pID ] [ E_DOUBLE_XP ] > gettime( ) ) g_userData[ pID ] [ E_DOUBLE_XP ] += double_xp;
    else g_userData[ pID ] [ E_DOUBLE_XP ] += ( gettime( ) + double_xp );
}

stock VIPLevelToString( level )
{
	new
	    szLevel[ 9 ]
	;
	switch( level )
	{
	    case 0: szLevel = "N/A";
	    case 1: szLevel = "Premium";
	    case 2: szLevel = "Hardened";
	    case 3: szLevel = "Elite";
	}
	return szLevel;
}

stock IsValidSkin( skinid )
{
	if ( skinid == 74 || skinid > 299 || skinid < 0 )
		return 0;

	return 1;
}

stock CensoreString( query[ ], characters = 5 )
{
	static
		szString[ 256 ];

	format( szString, 256, query );
	strdel( szString, 0, characters );

	for( new i = 0; i < characters; i++ )
		strins( szString, "*", 0 );

	return szString;
}

stock getVIPExpire( playerid )
{
	static
	    szString[ 10 ],
	    days
	;
	szString = "N/A";
	if ( g_userData[ playerid ] [ E_VIP_EXPIRE ] == 0 ) return szString;
	days = ( g_userData[ playerid ] [ E_VIP_EXPIRE ] - gettime( ) ) / 86400;
	format( szString, sizeof( szString ), "%d days", days );
	return szString;
}

stock getDoubleXPExpire( playerid )
{
	static
	    szString[ 10 ],
	    days
	;
	szString = "N/A";
	if ( g_userData[ playerid ] [ E_DOUBLE_XP ] == 0 ) return szString;
	days = ( g_userData[ playerid ] [ E_DOUBLE_XP ] - gettime( ) ) / 86400;
	format( szString, sizeof( szString ), "%d days", days );
	return szString;
}

stock handlePlayerSpawnEquipment( playerid )
{
	new
		Float: fArmour = 0.0;

	if ( g_userData[ playerid ] [ E_VIP_LEVEL ] > 1 )
	{
	    for( new i; i < MAX_WEAPONS; i++ )
		{
		    if ( IsWeaponInAnySlot( playerid, i ) )
		    {
		    	if ( i == 0 || i == 47 || i == WEAPON_ROCKETLAUNCHER || i == WEAPON_GRENADE || i == WEAPON_TEARGAS ) continue;
		        GivePlayerWeapon( playerid, i, g_userData[ playerid ] [ E_VIP_LEVEL ] == 3 ? 15000 : 500 );
		    }
		}
	}

	if ( g_userData[ playerid ] [ E_WEAPONS ] [ 0 ] != 0 && g_userData[ playerid ] [ E_VIP_LEVEL ] >= 2 ) GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_WEAPONS ] [ 0 ], 500 );
	if ( g_userData[ playerid ] [ E_WEAPONS ] [ 1 ] != 0 && g_userData[ playerid ] [ E_VIP_LEVEL ] >= 3 ) GivePlayerWeapon( playerid, g_userData[ playerid ] [ E_WEAPONS ] [ 1 ], 500 );

	if ( getPlayerFirstPerk( playerid ) == PERK_RPG ) GivePlayerWeapon( playerid, 35, g_userData[ playerid ] [ E_VIP_LEVEL ] > 2 ? 2 : 1 );

	switch( getPlayerEquipment( playerid ) )
	{
	    case EQUIPMENT_GRENADE: 	GivePlayerWeapon( playerid, WEAPON_GRENADE, 1 );
	    case EQUIPMENT_SMOKE: 		GivePlayerWeapon( playerid, WEAPON_TEARGAS, 1 );
	    case EQUIPMENT_TOMAHAWK: 	GivePlayerWeapon( playerid, WEAPON_KNIFE, 1 );
	    case EQUIPMENT_C4: 			DestroyPlayerC4( playerid, MAX_C4 );
	}

	/* ** Armour/Blast Shield ** */
	if ( g_userData[ playerid ] [ E_VIP_LEVEL ] == 3 ) 			fArmour += 50.0;
	else if ( g_userData[ playerid ] [ E_VIP_LEVEL ] == 2 ) 		fArmour += 20.0;
	if ( getPlayerSecondPerk( playerid ) == PERK_BLAST_SHIELD ) 	fArmour += 25.0;

	if ( fArmour ) SetPlayerArmour( playerid, fArmour );
}

stock ShowPlayerInfoDialog( playerid, timeout, msg[ ] )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

    TextDrawSetString( p_SelectionHelpTD[ playerid ], msg );
    TextDrawShowForPlayer( playerid, p_SelectionHelpTD[ playerid ] );

    KillTimer( p_SelectionHelpTimer[ playerid ] );

   	if ( timeout != 0 )
   		p_SelectionHelpTimer[ playerid ] = SetTimerEx( "HidePlayerInfoDialog", timeout, false, "d", playerid );

	return 1;
}

class HidePlayerInfoDialog( playerid )
{
	p_SelectionHelpTimer[ playerid ] = 0xFFFF;
	TextDrawHideForPlayer( playerid, p_SelectionHelpTD[ playerid ] );
}

stock DamagePlayer( playerid, Float:damage )
{
	new
		Float:pHealth,
		Float:pArmour,
		Float:pDif
	;
	GetPlayerHealth( playerid, pHealth );
	GetPlayerArmour( playerid, pArmour );

	if ( pArmour <= 0 ) SetPlayerHealth( playerid, pHealth - damage );
	else
	{
		pDif = damage - pArmour;
		if ( pDif <= 0 ) SetPlayerArmour( playerid, pArmour - damage );
		else
		{
			SetPlayerArmour( playerid, 0.0 );
			SetPlayerHealth( playerid, pHealth - pDif );
		}
	}
	return 1;
}

stock KickPlayerTimed( playerid )
	return SetTimerEx( "KickPlayer", 500, false, "d", playerid );

class KickPlayer( playerid )
	return SetPVarInt( playerid, "banned_connection", 1 ), Kick( playerid );

stock adhereBanCodes( string[ ], maxlength = sizeof( string ) ) {
    for( new i; i < sizeof( g_banCodes ); i++ ) {
    	if ( strfind( string, g_banCodes[ i ] [ E_CODE ], false ) != -1 ) {
			strreplace( string, g_banCodes[ i ] [ E_CODE ], g_banCodes[ i ] [ E_DATA ], false, 0, -1, maxlength );
		}
	}
	return 1;
}

stock strreplace(string[], const search[], const replacement[], bool:ignorecase = false, pos = 0, limit = -1, maxlength = sizeof(string)) {
    // No need to do anything if the limit is 0.
    if (limit == 0)
        return 0;

    new
             sublen = strlen(search),
             replen = strlen(replacement),
        bool:packed = ispacked(string),
             maxlen = maxlength,
             len = strlen(string),
             count = 0
    ;


    // "maxlen" holds the max string length (not to be confused with "maxlength", which holds the max. array size).
    // Since packed strings hold 4 characters per array slot, we multiply "maxlen" by 4.
    if (packed)
        maxlen *= 4;

    // If the length of the substring is 0, we have nothing to look for..
    if (!sublen)
        return 0;

    // In this line we both assign the return value from "strfind" to "pos" then check if it's -1.
    while (-1 != (pos = strfind(string, search, ignorecase, pos))) {
        // Delete the string we found
        strdel(string, pos, pos + sublen);

        len -= sublen;

        // If there's anything to put as replacement, insert it. Make sure there's enough room first.
        if (replen && len + replen < maxlen) {
            strins(string, replacement, pos, maxlength);

            pos += replen;
            len += replen;
        }

        // Is there a limit of number of replacements, if so, did we break it?
        if (limit != -1 && ++count >= limit)
            break;
    }

    return count;
}
