/*
 *
 *      	San Fierro: Cops and Robbers
 *
 *      		Created all by Lorenc_
 *
 *
 *      Thanks to: y_less/zeex/Frosha/Incognito/SA-MP team
 *
 *  Codes:
 *      8hska7082bmahu -> Money Farming Checks
 *      plugins mysql crashdetect sscanf streamer socket Whirlpool regex gvar FileManager profiler FCNPC
*/

#pragma compat 1
// #pragma option -d3
#pragma dynamic 7200000

#define DEBUG_MODE

#if defined DEBUG_MODE
	#pragma option -d3
#endif

/* ** SA-MP Includes ** */
#include 							< a_samp >
#include                            < a_http >

/* ** YSI ** */
#include 							< YSI\y_iterate >
#include 							< YSI\y_hooks >
#include                            < YSI\y_va >

/* ** Redefinitions ** */
#undef  MAX_PLAYERS
#define MAX_PLAYERS                 128

/* ** Sundry Includes ** */
#include                            < a_mysql >
#include 							< zcmd >
#include 							< sscanf2 >
#include 							< streamer >
#include                            < regex >
#include                            < gvar >
#include 							< RouteConnector >
#include 							< merrandom >
#include 							< MathParser >
#include 							< mapandreas >
#include 							< md-sort >
native WP_Hash						( buffer[ ], len, const str[ ] );
native IsValidVehicle				( vehicleid );
native gpci 						( playerid, serial[ ], len );

new bool: False = false;

/* ** SF-CNR ** */
#include 							"irresistible\_main.pwn"

/* ** Useful macros ** */
#define DQCMD:%1(%2) 				forward discord_%1(%2); public discord_%1(%2)
#define IsPlayerRobbing(%0)			IsPlayerAttachedObjectSlotUsed(%0,0)
#define IsPlayerInShamal(%0)		(GetPlayerInterior(%0)==VW_SHAMAL)
#define hasTickcountPassed(%1,%2)   ((GetTickCount()-%1)>(%2))
#define Ach_Unlock(%0,%1) 			(%0 >= %1 ?("{6EF83C}"):("{FFFFFF}"))
#define UpdatePlayerTime(%0)		SetPlayerTime(%0,floatround(g_WorldClockSeconds/60),g_WorldClockSeconds-floatround((g_WorldClockSeconds/60)*60))
#define GetPlayerTotalCash(%0)  	(p_BankMoney[%0] + GetPlayerCash(%0)) // Bank Money and Money
#define Achievement:: 				ach_
#define IsPlayerInEntrance(%0,%1) 	(p_LastEnteredEntrance[%0]==(%1))
#define IsPlayerInPlayerGang(%0,%1)	(p_Class[%0] == p_Class[%1] && p_Class[%0] == CLASS_CIVILIAN && p_GangID[%0] == p_GangID[%1] && p_GangID[%0] != INVALID_GANG_ID)
#define IsPlayerNpcEx(%0)			(IsPlayerNPC(%0) || strmatch(p_PlayerIP[%0], "127.0.0.1"))

/* Beast Functions */
#define SendClientMessageToVips(%1,%2,%3) \
	do{foreach(new fI : Player){if (p_VIPLevel[fI]>=VIP_REGULAR)format(szNormalString,sizeof(szNormalString),(%2),%3),SendClientMessage(fI,(%1),szNormalString);}}while(False)
#define SendClientMessageToAmbulance(%1,%2,%3) \
	do{foreach(new fI : Player){if (p_Class[fI]==CLASS_MEDIC)format(szNormalString,sizeof(szNormalString),(%2),%3),SendClientMessage(fI,(%1),szNormalString);}}while(False)
#define DCC_SendChannelMessageFormatted(%0,%1,%2) \
	do{format(szNormalString,sizeof(szNormalString),(%1),%2),DCC_SendChannelMessage(%0,szNormalString);}while(False)

#define CreateBillboard(%0,%1,%2,%3,%4) SetDynamicObjectMaterialText(CreateDynamicObject(7246,%1,%2,%3,0,0,%4),0,(%0),120,"Arial",24,0,-1,-16777216,1)

#define MAX_CLASS_BAN_WARNS			3
#define MAX_BURGLARY_SLOTS          8
#define MAX_WANTED_LVL 				2048
#define MAX_TIME_TIED 				180
#define MAX_VEH_ATTACHED_OBJECTS  	2

#define VW_SHAMAL 					220

/* ** Donation System ** */
#define szRedemptionSalt 			"7resta#ecacakumedeM=yespawr!d@et"
enum E_DONATION_DATA
{
	E_TRANSACTION_ID[ 17 ],
	E_NAME[ 24 ],
	E_AMOUNT[ 11 ],
	E_PURPOSE[ 64 ],
	E_DATE
}

/* ** Discord ** */
//#include <discord-connector>
#define ENABLE_DISCORD 				false

#define DISCORD_GENERAL 			"191078670360641536"
#define DISCORD_ADMINISTRATION 		"191078670360641536"
#define DISCORD_SPAM 				"364725535256870913"

#define DISCORD_ROLE_EXEC 			"191727949404176384"
#define DISCORD_ROLE_HEAD 			"191134988354191360"
#define DISCORD_ROLE_LEAD			"191080382689443841"
#define DISCORD_ROLE_VIP			"191180697547833344"
#define DISCORD_ROLE_VOICE			"364678874681966592"

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

/* ** Gate System ** */
#define MAX_GATES 					( 300 )

enum E_GATE_DATA
{
	E_OBJECT,			E_PASS[ 8 ], 			Float: E_SPEED,
	Float: E_RANGE,		E_MODEL, 				bool: E_MOVING,
	E_OWNER,			E_NAME[ 24 ],			E_TIME,
	E_GANG_SQL_ID,

	Float: E_X,			Float: E_Y,				Float: E_Z,
	Float: E_RX,		Float: E_RY,			Float: E_RZ,

	Float: E_MOVE_X,	Float: E_MOVE_Y,		Float: E_MOVE_Z,
	Float: E_MOVE_RX,	Float: E_MOVE_RY,		Float: E_MOVE_RZ,

	E_CLOSE_TIMER
};

new
	g_gateData 					[ MAX_GATES ] [ E_GATE_DATA ],

	// Iterator
	Iterator:gates<MAX_GATES>
;

/* ** Weed System ** */
#define MAX_WEED_STORAGE 			( 10 )
#define MAX_WEED                    ( 42 )
enum E_WEED_DATA
{
	bool: E_CREATED,    E_OBJECT,       bool: E_CUT,
	Float: E_X,         Float: E_Y,     Float: E_Z
};

new
	g_weedData                      [ MAX_WEED ] [ E_WEED_DATA ]
;

/* ** Copten Codes ** */
enum E_TEN_CODES
{
	E_CODE[ 6 ], 		E_SUBJECT[ 50 ]
};

new
	g_coptenCodes[ ] [ E_TEN_CODES ] =
	{
		{ "10-10", "Fight in progress" }, 						{ "10-11", "Robbery" },
		{ "10-12", "Stand by" }, 								{ "10-13", "Weather - road report" },
		{ "10-14", "Prowler report" }, 							{ "10-15", "Traffic check" },
		{ "10-16", "Domestic disturbance" }, 					{ "10-17", "Meet complainant" },
		{ "10-18", "Quickly" },									{ "10-19", "Return to" },
		{ "10-20", "Location" }, 								{ "10-21", "By telephone, call" },
		{ "10-22", "Disregard" }, 								{ "10-23", "Arrived at scene" },
		{ "10-24", "Assignment completed" }, 					{ "10-25", "Report in person" },
		{ "10-26", "Detaining subject, expedite" },				{ "10-27", "Drivers license information" },
		{ "10-28", "Vehicle registration information" },		{ "10-29", "Check for wanted" },
		{ "10-30", "Unnecessary use of radio" }, 				{ "10-31", "Crime in progress" },
		{ "10-32", "Man with gun" }, 							{ "10-33", "Emergency" },
		{ "10-34", "Riot" },									{ "10-35", "Major crime alert" },
		{ "10-36", "Correct time" }, 							{ "10-37", "(Investigate) suspicious vehicle" },
		{ "10-38", "Stopping suspicious vehicle" }, 			{ "10-39", "Urgent - use light, siren" },
		{ "10-40", "Silent run - no light, siren" }, 			{ "10-41", "Beginning tour of duty" },
		{ "10-42", "Ending tour of duty" }, 					{ "10-43", "Information" },
		{ "10-44", "Permission to leave for" }, 				{ "10-45", "Kidnapping" },
		{ "10-46", "Assist motorist" }, 						{ "10-47", "Emergency road repairs at" },
		{ "10-48", "Traffic standard repair at" }, 				{ "10-49", "Traffic light out at" },
		{ "10-50", "Accident" }, 								{ "10-51", "Wrecker needed" },
		{ "10-52", "Ambulance needed" }, 						{ "10-53", "Road blocked at" },
		{ "10-54", "Livestock on highway" }, 					{ "10-55", "Suspected DUI" },
		{ "10-56", "Intoxicated pedestrian" }, 					{ "10-57", "Hit and run" },
		{ "10-58", "Direct traffic" }, 							{ "10-59", "Convoy or escort" },
		{ "10-60", "Squad in vicinity" }, 						{ "10-61", "Isolate self for message" },
		{ "10-62", "Reply to message" }, 						{ "10-63", "Prepare to make written copy" },
		{ "10-64", "Message for local delivery" }, 				{ "10-65", "Net message assignment" },
		{ "10-66", "Message cancellation" }, 					{ "10-67", "Clear for net message" },
		{ "10-68", "Dispatch information" }, 					{ "10-69", "Message received" },
		{ "10-70", "Fire" }, 									{ "10-71", "Advise nature of fire" },
		{ "10-72", "Report progress on fire" }, 				{ "10-73", "Smoke report" },
		{ "10-74", "Negative" }, 								{ "10-75", "In contact with" },
		{ "10-76", "Bribe" }, 									{ "10-77", "ETA" },
		{ "10-78", "Need assistance" }, 						{ "10-79", "Notify coroner" },
		{ "10-80", "Chase in progress" }, 						{ "10-81", "Drug Activity" },
		{ "10-82", "Reserve lodging" }, 						{ "10-83", "Suspect Hidden on Radar" },
		{ "10-84", "If meeting, advise ETA" }, 					{ "10-85", "Delayed due to" },
		{ "10-86", "Officer on duty" }, 						{ "10-87", "Pick up/distribute checks" },
		{ "10-88", "Present telephone number of" }, 			{ "10-89", "Bomb threat" },
		{ "10-90", "Bank alarm at" }, 							{ "10-91", "Pick up prisoner/subject" },
		{ "10-92", "Improperly parked vehicle" }, 				{ "10-93", "Blockade" },
		{ "10-94", "Drag racing" }, 							{ "10-95", "Prisoner/subject in custody" },
		{ "10-96", "Mental subject" }, 							{ "10-97", "Check signal" },
		{ "10-98", "Prison/jail break" }, 						{ "10-99", "Wanted/stolen indicated" },
		// Some bug, so I'll do this.
	    { "10-0", "Caution" }, 									{ "10-1", "Unable to copy" },
		{ "10-2", "Signal good" }, 								{ "10-3", "Stop transmitting" },
		{ "10-4", "Acknowledgment" }, 							{ "10-5", "Relay" },
		{ "10-6", "Busy, stand by unless urgent" },				{ "10-7", "Out of service" },
		{ "10-8", "In service" }, 								{ "10-9", "Repeat" }
	}
;

/* ** C4 Data ** */
#define MAX_C4                      ( 10 )
enum E_C4_DATA
{
	bool: E_SET,		E_OBJECT, 		E_VEHICLE,
	Text3D: E_LABEL, 	E_WORLD, 		E_INTERIOR
};

new
	g_C4Data						[ MAX_PLAYERS ] [ MAX_C4 ] [ E_C4_DATA ],
   	p_C4Amount          			[ MAX_PLAYERS ]
;

/* ** Apartment System ** */
#define MAX_AFLOORS                 ( 20 )

enum E_FLAT_DATA
{
	E_OWNER[ 24 ],    		E_NAME[ 30 ], 		E_LOCKED,
	bool: E_CREATED,		E_FURNITURE
};

new
	g_apartmentData                 [ 19 ] [ E_FLAT_DATA ], // A1 = 19 Floors
	g_apartmentElevator             = INVALID_OBJECT_ID,
	g_apartmentElevatorGate         = INVALID_OBJECT_ID,
    g_apartmentElevatorLevel        = 0,
	g_apartmentElevatorDoor1		[ MAX_AFLOORS ]	= INVALID_OBJECT_ID,
	g_apartmentElevatorDoor2		[ MAX_AFLOORS ] = INVALID_OBJECT_ID
;

/* ** Casino Rewards Points ** */
#define CASINO_REWARDS_PAYOUT_PERCENT	20.0
#define CASINO_REWARDS_DIVISOR 			10.0 	// 1000 points becomes 1 point
#define CASINO_REWARDS_COST_MP 			1.0 	// half of the price (since it costs (1/payout_percent) times more)

enum E_REWARDS_DATA
{
	E_NAME[ 32 ], 		Float: E_POINTS
}

new
	g_casinoRewardsItems[ ] [ E_REWARDS_DATA ] = {
		{ "Fireworks", 2500.0 },
		{ "10 Explosive Bullets", 5000.0 },
		// { "No Tax For 1 Hour", 25000.0 },
		{ "Highroller Access", 200000.0 }
	},
	g_casinoRewardsShopItems[ ] = {
		5, 6, 7, 8, 9, 10, 11
	},
	Float: p_CasinoRewardsPoints 		[ MAX_PLAYERS ],
	bool: p_IsCasinoHighRoller 			[ MAX_PLAYERS char ],
	Text3D: p_RewardsLabel_4Drags		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	Text3D: p_RewardsLabel_Caligs		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	Text3D: p_RewardsLabel_Visage		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	p_HighrollersBarrier 				[ MAX_PLAYERS ] [ 2 ]
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

/* ** Jail System ** */
#define JAIL_SECONDS_MULTIPLIER		( 3 )
#define ALCATRAZ_REQUIRED_TIME		( 150 )

#define ALCATRAZ_TIME_PAUSE 		( 5 )
#define ALCATRAZ_TIME_WANTED 		( 600 )

enum E_JAIL_DATA
{
	E_CITY,				Float: E_EXPLODE1_POS[ 3 ],	Float: E_EXPLODE2_POS[ 3 ],
	Float: E_RADIUS,	E_TIMESTAMP,				bool: E_BOMBED
};

new
	g_jailData						[ MAX_CITIES ] [ E_JAIL_DATA ] =
	{
		{ CITY_SF, { 217.4585, 113.6866, 999.0156 }, { 225.4888, 113.1873, 999.0156 }, 5.0,  0, false },
		{ CITY_LV, { 194.3351, 179.008, 1003.0234 }, { 193.8611, 158.0657, 1003.024 }, 10.0, 0, false },
		{ CITY_LS, { 268.5573, 86.1785, 1001.0391 }, { 268.1720, 78.5381, 1001.0391 }, 5.0,	 0, false }
	},
	p_JailObjectLV					[ MAX_PLAYERS ] [ 3 ],
	p_JailObjectSF					[ MAX_PLAYERS ] [ 4 ],
	p_JailObjectLS					[ MAX_PLAYERS ] [ 3 ],
	p_AlcatrazObject 				[ MAX_PLAYERS ] = { INVALID_OBJECT_ID, ... },
	p_AlcatrazEscapeTS 				[ MAX_PLAYERS ],
	g_alcatrazTimestamp 			= 0
;

/* ** Rank System ** */

/* ** Race System ** */
#define MAX_RACES 				( 32 )

#define RACE_STREET_RACE 		0
#define RACE_OUTRUN 			1
#define OUTRUN_DIST 			6.0

enum E_RACE_DATA
{
	E_LOBBY_HOST, 				E_MODE, 						E_ENTRY_FEE,
	E_POOL, 					E_RACE_FINISH_SET, 				Float: E_FINISH_POS[ 3 ],
	E_CD_TIMER,					E_FINISH_MAP_ICON, 				Float: E_POSITION_PRIZE[ 3 ],
	E_START_CHECKPOINT,  		E_FINISH_CHECKPOINT, 			E_FINISHED_COUNT,
	bool: E_STARTED, 			E_OUTRUN_SPHERE, 				E_OUTRUN_OBJECT,
	E_OUTRUN_LEAD, 				E_OUTRUN_TIMER, 				Float: E_OUTRUN_DISTANCE
};

enum E_RACE_DEST_DATA
{
	E_NAME[ 16 ],
	Float: E_X, 				Float: E_Y, 					Float: E_Z
};

new
	g_raceFinalDestinations[ ] [ E_RACE_DEST_DATA ] =
	{
		{ "LS Airport", 		1487.0245, -2493.751, 13.2720 },
		{ "LS Pier", 			369.61540, -2011.367, 7.39200 },
		{ "LS Grove Street", 	2487.9739, -1666.938, 13.0633 },
		{ "LV Airport", 		1477.6246, 1207.3376, 10.8203 },
		{ "LV Old Strip", 		2350.5371, 2143.6689, 10.6815 },
		{ "El Quebrados",		-885.4323, 1660.3818, 27.0871 },
		{ "SF Airport", 		-1117.212, 375.26310, 14.1484 },
		{ "Mount Chiliad", 		-2324.256, -1624.915, 483.883 },
		{ "SF Gant Bridge", 	-2681.314, 1763.9274, 68.4844 },
		{ "SF Dealership ",		-2422.670, -609.4055, 132.562 }
	},
	g_raceData[ MAX_RACES ] [ E_RACE_DATA ],
	Iterator:races<MAX_RACES>,
	p_raceLobbyId[ MAX_PLAYERS ] = { -1, ... },
	p_raceInvited[ MAX_PLAYERS ] [ MAX_RACES ]
;

/* ** Forwards ** */
public OnPlayerDriveVehicle( playerid, vehicleid );
public OnServerUpdateTimer( );
public OnHelpHTTPResponse( index, response_code, data[ ] );
public OnRulesHTTPResponse( index, response_code, data[ ] );
public OnTwitterHTTPResponse( index, response_code, data[ ] );
public OnDonationRedemptionResponse( index, response_code, data[ ] );
public OnPlayerArrested( playerid, victimid, totalarrests, totalpeople );
public OnPlayerUnjailed( playerid, reasonid );
public OnPlayerAccessEntrance( playerid, entranceid );

main()
{
	print( "\n" #SERVER_NAME "\n" );
}

public OnGameModeInit()
{
	SetGameModeText( "Cops And Robbers / DM / Gangs" );
	SetServerRule( "hostname", SERVER_NAME );
	SetServerRule( "language", "English" );
	SetServerRule( "mapname", "San Fierro" );
	UsePlayerPedAnims( );
	AllowInteriorWeapons( 0 );
	EnableStuntBonusForAll( 0 );
	DisableInteriorEnterExits( );

	#if defined DEBUG_MODE
	mysql_log( LOG_ERROR | LOG_WARNING );
	#endif

	// start map andreas
	MapAndreas_Init( MAP_ANDREAS_MODE_MINIMAL );

	/* ** Intalize Data ** */
	initializeServerObjects( );
	initializeObjects( );
	initializeActors( );

	/* ** Server Variables ** */
	AddServerVariable( "taxtime", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "taxrate", "1.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "taxprofit", "0.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "taxprofit_prev", "0.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "doublexp", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "eventbank", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "eventhost", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "vip_discount", "1.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "vip_bonus", "0.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "hitman_budget", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "connectsong", "http://files.sfcnr.com/game_sounds/Stevie%20Wonder%20-%20Skeletons.mp3", GLOBAL_VARTYPE_STRING );
	AddServerVariable( "discordurl", "http://sfcnr.com/discord", GLOBAL_VARTYPE_STRING );

	/* ** CIVILIAN ** */
	CLASS_CIVILIAN_RANGE[ 0 ] = AddPlayerClass( 119, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 0
	AddPlayerClass( 289, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 1
	AddPlayerClass( 273, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 2
	AddPlayerClass( 271, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 3
	AddPlayerClass( 208, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 4
	AddPlayerClass( 268, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 5
	AddPlayerClass( 292, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 6
	AddPlayerClass( 293, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 7
	AddPlayerClass(  3, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	8
	AddPlayerClass(  4, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	9
	AddPlayerClass(  2, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  10
	AddPlayerClass(  7, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  11
	AddPlayerClass( 12, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  12
	AddPlayerClass( 13, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  13
	AddPlayerClass( 14, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  14
	AddPlayerClass( 15, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  15
	AddPlayerClass( 17, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  16
	AddPlayerClass( 19, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  17
	AddPlayerClass( 20, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  18
	AddPlayerClass( 21, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //  19
	AddPlayerClass( 22, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	20
	AddPlayerClass( 23, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	21
	AddPlayerClass( 24, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	22
	AddPlayerClass( 26, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	23
	AddPlayerClass( 28, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	24
	AddPlayerClass( 29, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	25
	AddPlayerClass( 30, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	26
	AddPlayerClass( 31, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	27
	AddPlayerClass( 32, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	28
	AddPlayerClass( 33, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	29
	AddPlayerClass( 34, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	30
	AddPlayerClass( 35, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	31
	AddPlayerClass( 36, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	32
	AddPlayerClass( 37, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	33
	AddPlayerClass( 38, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	34
	AddPlayerClass( 46, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	35
	AddPlayerClass( 47, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	36
	AddPlayerClass( 48, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	37
	AddPlayerClass( 59, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	38
	AddPlayerClass( 60, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	39
	AddPlayerClass( 63, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	40
	AddPlayerClass( 64, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	41
	AddPlayerClass( 152, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	42
	AddPlayerClass( 237, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	43
	AddPlayerClass( 78, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); //	44
	AddPlayerClass( 79, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 	45
	AddPlayerClass( 134, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 46
	AddPlayerClass( 100, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 47
	AddPlayerClass( 101, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 48
	CLASS_CIVILIAN_RANGE[ 1 ] = AddPlayerClass( 137, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 49

	/* ** FBI ** */
	CLASS_FBI_RANGE[ 0 ] = AddPlayerClass( 286, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 50
	AddPlayerClass( 71, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 );  // 51
	CLASS_FBI_RANGE[ 1 ] = AddPlayerClass( 285, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 52

	/* ** ARMY ** */
	CLASS_ARMY_RANGE = AddPlayerClass( 287, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 53

	/* ** CIA ** */
	CLASS_CIA_RANGE[ 0 ] = AddPlayerClass( 303, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 54
	AddPlayerClass( 304, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 55
	CLASS_CIA_RANGE[ 1 ] = AddPlayerClass( 305, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 56

	/* ** FIRE ** */
	CLASS_FIRE_RANGE[ 0 ] = AddPlayerClass( 277, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 57
	AddPlayerClass( 278, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 58
	CLASS_FIRE_RANGE[ 1 ] = AddPlayerClass( 279, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 59

	/* ** MEDIC ** */
	CLASS_MEDIC_RANGE[ 0 ] = AddPlayerClass( 274, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 60
	AddPlayerClass( 275, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 61
	AddPlayerClass( 276, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 62
	CLASS_MEDIC_RANGE[ 1 ] = AddPlayerClass( 308, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 63

	/* ** POLICE ** */
	CLASS_POLICE_RANGE[ 0 ] = AddPlayerClass( 265, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 66
	AddPlayerClass( 266, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 67
	AddPlayerClass( 267, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 68
	AddPlayerClass( 306, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 69
	AddPlayerClass( 280, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 70
	AddPlayerClass( 281, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 71
	AddPlayerClass( 284, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 72
	CLASS_POLICE_RANGE[ 1 ] = AddPlayerClass( 307, default_X, default_Y, default_Z, default_Angle, 0, 0, 0, 0, 0, 0 ); // 73

 	/* ** Discord configuration ** */
 	#if ENABLE_DISCORD == true
	discordGuild = DCC_FindGuildById( DISCORD_GENERAL );
	discordGeneralChan = DCC_FindChannelById( DISCORD_GENERAL );
	discordSpamChan = DCC_FindChannelById( DISCORD_SPAM );

	discordRoleExecutive = DCC_FindRoleById( DISCORD_ROLE_EXEC );
	discordRoleHead = DCC_FindRoleById( DISCORD_ROLE_HEAD );
	discordRoleLead = DCC_FindRoleById( DISCORD_ROLE_LEAD );
	discordRoleVIP = DCC_FindRoleById( DISCORD_ROLE_VIP );
	discordRoleVoice = DCC_FindRoleById( DISCORD_ROLE_VOICE );

	DCC_SendChannelMessage( discordGeneralChan, "**The discord plugin has been initiaized.**" );
	#endif

	/* ** Map Icons ** */
	CreateDynamicMapIcon( -1547.4066, 123.6555, 3.55470,  9, 0, -1, -1, -1, 750.0 ); // ShipYard
	CreateDynamicMapIcon( -1657.7573, 1210.275, 7.25000, 55, 0, -1, -1, -1, 750.0 ); // Otto's Cars
	CreateDynamicMapIcon( -1923.3926, 303.6380, 41.0469,  8, 0, -1, -1, -1, 750.0 ); // BombShop
	CreateDynamicMapIcon( -1951.9911, 300.2070, 35.4688, 55, 0, -1, -1, -1, 750.0 ); // WangCars
	CreateDynamicMapIcon( -1979.9883, 138.0498, 27.6875, 42, 0, -1, -1, -1, 750.0 ); // TrainStation
	CreateDynamicMapIcon( -2172.2017, 252.1113, 35.3388, 19, 0, -1, -1, -1, 750.0 ); // Paintball
	CreateDynamicMapIcon( -2455.4487, 503.9236, 30.0781, 30, 0, -1, -1, -1, 750.0 ); // CIA-FBI
	CreateDynamicMapIcon( -2489.8660, -16.8687, 25.6172, 58, 0, -1, -1, -1, 750.0 ); // Pawn Store
	CreateDynamicMapIcon( -1840.3867, 1015.350, 45.6626, 46, 0, -1, -1, -1, 750.0 ); // Weed Farm
	CreateDynamicMapIcon( -1935.8773, 243.1236, 36.2211, 27, 0, -1, -1, -1, 750.0 ); // Modshop
	CreateDynamicMapIcon( -2720.6104, 217.7127, 4.31920, 27, 0, -1, -1, -1, 750.0 ); // Modshop
	CreateDynamicMapIcon( -2426.3296, 1021.7617, 50.8859, 63, 0, -1, -1, -1, 750.0 ); // Paint n Spray
	CreateDynamicMapIcon( -1903.7902, 283.97430, 41.7187, 63, 0, -1, -1, -1, 750.0 ); // Paint n Spray
	CreateDynamicMapIcon( -1903.7902, 283.97430, 41.7187, 63, 0, -1, -1, -1, 750.0 ); // Paint n Spray

	// Las Venturas
	CreateDynamicMapIcon( 2597.58000, 2464.270, 10.8200, 46, 0, -1, -1, -1, 750.0 ); // Weed Farm
	CreateDynamicMapIcon( 1973.2057, 2162.2651, 10.6314, 63, 0, -1, -1, -1, 750.0 ); // Paint n Spray - Las Venturas
	CreateDynamicMapIcon( 1607.2659, 1815.2485, 10.8203, 22, 0, -1, -1, -1, 750.0 ); // Hospital - Las Venturas
	CreateDynamicMapIcon( -320.1947, 1048.2355, 20.3403, 22, 0, -1, -1, -1, 750.0 ); // Hospital - Fort Carson
	CreateDynamicMapIcon( -217.8446, 979.07470, 19.5039, 30, 0, -1, -1, -1, 750.0 ); // Police Department - Fort Carson
	CreateDynamicMapIcon( -1514.7529, 2518.9282, 56.070, 22, 0, -1, -1, -1, 750.0 ); // Hospital - El Quebrados
	CreateDynamicMapIcon( -1390.0563, 2639.0264, 55.984, 30, 0, -1, -1, -1, 750.0 ); // Police Department - El Quebrados
	CreateDynamicMapIcon( 1998.7263, 2298.5562, 10.8203,  8, 0, -1, -1, -1, 750.0 ); // BombShop - Las Venturas
	CreateDynamicMapIcon( -431.2023, 2241.0063, 42.9834, 30, 0, -1, -1, -1, 750.0 ); // Police Department - El Castillo del Diablo
	CreateDynamicMapIcon( 1633.7454, 2330.6860, 10.8203,  9, 0, -1, -1, -1, 750.0 ); // ShipYard
	CreateDynamicMapIcon( 2386.8342, 1048.7100, 10.1765, 27, 0, -1, -1, -1, 750.0 ); // Modshop

	// Los Santos
	CreateDynamicMapIcon( 2597.5800,  2464.2700, 10.8200, 46, 0, -1, -1, -1, 750.0 ); // Weed Farm
	CreateDynamicMapIcon( 626.96450, -571.74460, 17.9207, 30, 0, -1, -1, -1, 750.0 ); // Police Department - Dillimore
	CreateDynamicMapIcon( 2031.3892, -1417.7322, 16.9922, 22, 0, -1, -1, -1, 750.0 ); // Hospital - Los Santos
	CreateDynamicMapIcon( 1167.1241, -1335.4282, 28.9784, 22, 0, -1, -1, -1, 750.0 ); // Hospital - Los Santos
	CreateDynamicMapIcon( 487.39340, -1740.4929, 10.6892, 63, 0, -1, -1, -1, 750.0 ); // Paint n Spray - Los Santos
	CreateDynamicMapIcon( 1024.9385, -1025.0437, 31.6611, 63, 0, -1, -1, -1, 750.0 ); // Paint n Spray - Los Santos
	CreateDynamicMapIcon( 2065.3052, -1831.7053, 13.1126, 63, 0, -1, -1, -1, 750.0 ); // Paint n Spray - Los Santos
	CreateDynamicMapIcon( 2644.8589, -2038.8060, 13.5500, 27, 0, -1, -1, -1, 750.0 ); // Modshop
	CreateDynamicMapIcon( 1041.5466, -1023.0604, 31.7067, 27, 0, -1, -1, -1, 750.0 ); // Modshop
	CreateDynamicMapIcon( 2635.2529, -2227.0149, 16.2969,  9, 0, -1, -1, -1, 750.0 ); // ShipYard
	CreateDynamicMapIcon( 2456.1423, -1714.9557, 13.1630, 46, 0, -1, -1, -1, 750.0 ); // Weed Farm
	CreateDynamicMapIcon( 1642.1968, -2335.4983, 13.5469,  5, 0, -1, -1, -1, 750.0 ); // Airport
	CreateDynamicMapIcon( 1519.1024, -1451.9186, 13.6816, 30, 0, -1, -1, -1, 750.0 ); // CIA-FBI
	CreateDynamicMapIcon( 1749.2073, -1948.8389, 13.4137, 42, 0, -1, -1, -1, 750.0 ); // TrainStation
	CreateDynamicMapIcon( 815.69880, -1347.7256, 13.1043, 42, 0, -1, -1, -1, 750.0 ); // TrainStation
	CreateDynamicMapIcon( 1911.2578, -1775.8676, 12.9470,  8, 0, -1, -1, -1, 750.0 ); // BombShop

	/* ** Drug Dealer ** */

	// San Fierro
	CreateWeedPlant( -1840.90, 1034.53, 45.70, 0.00, 0.00, 0.00 );
	CreateWeedPlant( -1846.17, 1027.93, 45.70, 0.00, 0.00, 0.00 );
	CreateWeedPlant( -1835.89, 1030.38, 45.70, 0.00, 0.00, 0.00 );
	CreateWeedPlant( -1846.73, 1016.40, 45.72, 11.5, 1.86, 0.00 );
	CreateWeedPlant( -1840.48, 1022.97, 46.12, 11.5, 1.86, 0.00 );
	CreateWeedPlant( -1835.85, 1017.52, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1842.32, 1011.92, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1836.99, 1008.02, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1838.05, 997.580, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1847.71, 1005.00, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1842.39, 1001.95, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1838.40, 990.090, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1832.22, 1012.22, 45.82, 6.72, 0.84, 0.00 );
	CreateWeedPlant( -1831.87, 1025.52, 45.82, 6.72, 0.84, 0.00 );

	#if ENABLE_CITY_LV == true
	// Las Venturas
	CreateWeedPlant( 2567.580, 2463.27, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2572.580, 2462.69, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2577.580, 2464.02, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2582.580, 2465.27, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2587.580, 2462.27, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2592.580, 2464.77, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2597.580, 2464.27, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2568.991, 2468.19, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2573.991, 2469.39, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2578.991, 2470.19, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2583.991, 2469.19, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2588.991, 2467.19, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2593.991, 2468.19, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2598.991, 2470.19, 10.82, 0.00, 0.00, 0.00 );
	CreateWeedPlant( 2603.093, 2466.90, 10.82, 0.00, 0.00, 0.00 );
	#endif

	#if ENABLE_CITY_LS == true
	CreateWeedPlant( 2447.354, -1711.075, 13.5094, 0.0, 0.0, 0.0000 );
	CreateWeedPlant( 2450.854, -1711.075, 13.5094, 0.0, 0.0, -13.59 );
	CreateWeedPlant( 2446.565, -1715.559, 13.5094, 0.0, 0.0, 39.599 );
	CreateWeedPlant( 2451.853, -1716.996, 13.5094, 0.0, 0.0, 0.0000 );
	CreateWeedPlant( 2455.603, -1711.075, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2455.434, -1714.954, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2460.162, -1713.718, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2462.092, -1710.387, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2465.872, -1712.579, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2463.214, -1717.164, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2468.758, -1715.719, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2470.875, -1712.068, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2467.420, -1718.029, 13.5094, 0.0, 0.0, 59.900 );
	CreateWeedPlant( 2459.837, -1717.633, 13.5094, 0.0, 0.0, 9.0000 );
	CreateWeedPlant( 2454.947, -1718.407, 13.5094, 0.0, 0.0, -21.49 );
	#endif

	/* ** Custom Vehicles ** */
	g_TrolleyVehicles[ 0 ] = AddStaticVehicle( 457, -2511.7935, 760.5610, 34.8990, 90.6223, 123, 1 ); // trolley
	g_TrolleyVehicles[ 1 ] = AddStaticVehicle( 457, -2511.5742, 766.5329, 34.8990, 91.5108, 112, 1 ); // trolley
	g_TrolleyVehicles[ 2 ] = AddStaticVehicle( 457, -2511.8782, 763.1669, 34.8990, 89.6839, 116, 1 ); // trolley
	g_TrolleyVehicles[ 3 ] = AddStaticVehicle( 457, -2511.4871, 769.7538, 34.8990, 91.3486, 116, 1 ); // trolley
	g_TrolleyVehicles[ 4 ] = AddStaticVehicle( 457, -2512.2607, 772.9983, 34.9006, 91.2577, 116, 1 ); // trolley

	for( new i; i < sizeof( g_TrolleyVehicles ); i++ )
		ChangeVehicleModel( g_TrolleyVehicles[ i ], 1349, 270.0 + 180.0 );

	/* ** Objects ** */
	// Billboards
	CreateBillboard( "Want V.I.P? Consider Donating!\n"COL_GREY"donate.sfcnr.com", -2016.22, 326.580, 37.950, 48.9000 );
	CreateBillboard( "Save us on your favourites!\n"#SERVER_IP"", -1809.64, -590.29, 19.360, -147.30 );
	CreateBillboard( "You can catch updates on our website!\n"COL_GREY""#SERVER_WEBSITE"", -1571.11, 939.860, 10.030, 45.9600 );
	CreateBillboard( "Remember to check the "COL_GREY"/rules"COL_WHITE"!\nDisobeying the rules can lead to punishment!", -1911.05, 858.870, 36.290, 44.5200 );
	CreateBillboard( "Want to view the commands?\n Use "COL_GREY"/commands{FFFFFF}!", -2423.40, -621.18, 135.46, -195.90 );
	CreateBillboard( "Need help with something?\nUse "COL_GREY"/ask"COL_WHITE" to contact an admin!", -2659.78, 1277.70, 9.8600, 125.100 );
	CreateBillboard( "Saw a cheater? Report him by typing "COL_GREY"/report{FFFFFF}!", -2443.63, 719.970, 37.900, 0.00000 );
	CreateBillboard( "You can use "COL_GREY"/vipcmds"COL_WHITE" to view your\nV.I.P commands!", -1958.975830, 841.130798, 1208.881469, -43.700046 );

	// Signs - User friendly addition
	SetDynamicObjectMaterialText( CreateDynamicObject( 7301, -2418.657714, 743.686523, 1058.593750, 0.000000, 0.000000, -44.899974 ), 0, "Use /shop!", 120, "impact", 100, 0, -65536, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19353, -1496.6134, 920.0287, 6.0990, 0.0, -90.0, -180 ), 0, "BANK", 100, "Times New Roman", 100, 0, -9170, 0, 1 );

	// Apartments
	CreateDynamicObject( 4587, -1971.51, 1356.26, 65.32,   0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 28.26,   0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 55.54,   0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 82.77,   0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 109.89,  0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 4605, -1992.10, 1353.31, 1.11,    0.00, 0.00, -180.00, .priority = 1 );

	g_apartmentElevator = CreateDynamicObject( 18755, -1955.09, 1365.51, 8.36, 0.00, 0.00, 90.00 );

	for( new level, Float: Z; level < MAX_AFLOORS; level++ )
	{
		switch( level )
		{
		    case 0:     Z = 8.36;
		    case 1:     Z = 17.03;
		    default:    Z = 17.03 + ( ( level - 1 ) * 5.447 );
		}
		g_apartmentElevatorDoor1[ level ] = CreateDynamicObject( 18756, -1955.05, 1361.64, Z, 0.00, 0.00, -90.00 );
		g_apartmentElevatorDoor2[ level ] = CreateDynamicObject( 18757, -1955.05, 1361.64, Z, 0.00, 0.00, -90.00 );
	}

	// Bank
	g_bankvaultData[ CITY_SF ] [ E_OBJECT ] = CreateDynamicObject( 18766, -1412.565063, 859.274536, 983.132873, 0.000000, 90.000000, 90.000000 );
	g_bankvaultData[ CITY_LV ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ CITY_LV ] [ E_WORLD ] );
	g_bankvaultData[ CITY_LS ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ CITY_LS ] [ E_WORLD ] );
	SetDynamicObjectMaterial( g_bankvaultData[ CITY_SF ] [ E_OBJECT ], 0, 18268, "mtbtrackcs_t", "mp_carter_cage", -1 );

	// Boat Hiest
	g_bankvaultData[ VAULT_BOAT ] [ E_OBJECT ] = CreateDynamicObject( 19435, -2371.416992, 1552.027709, 1.907187, 0.000000, 0.000000, 28.0000, g_bankvaultData[ VAULT_BOAT ] [ E_WORLD ] );
	SetDynamicObjectMaterial( g_bankvaultData[ VAULT_BOAT ] [ E_OBJECT ], 0, 18268, "mtbtrackcs_t", "mp_carter_cage", -1 );

	// Wall of Donors
	SetDynamicObjectMaterialText( CreateDynamicObject( 3074, -1574.3559, 885.1296, 28.4690, 0.0000, 0.0000, -0.0156 ), 0, "Thx Monthly Donors", 130, "Times New Roman", 64, 1, -65536, 0, 1 );

	g_TopDonorWall = CreateDynamicObject( 3074, -1574.3559, 885.1296, 14.0153, 0.0000, 0.0000, -0.0156 );
	SetDynamicObjectMaterialText( g_TopDonorWall, 0, "Nobody donated :(", 130, "Arial", 48, 0, -65536, 0, 1 );

	// Alcatraz
	g_AlcatrazArea = CreateDynamicRectangle( -1921.6816, 1661.7448, -2172.4653, 1876.0469 );

	/* ** Pickups ** */
	CreateDynamicPickup( 371, 2, 1318.92200, 2002.7311, 1200.250 ); // Parachute @Shamal
	CreateDynamicPickup( 371, 2, -1745.2754, 59.301500, 866.4556 ); // Parachute @Veloxity

	/* ** Set everyone offline ** */
	mysql_single_query( "UPDATE `USERS` SET `ONLINE` = 0" );

	/* ** Update Donation TD ** */
	UpdateGlobalDonated( );

	/* ** Auto Inactive Deletion ** */
#if !defined DEBUG_MODE

	// Delete accounts older than 4 months
	erase( szLargeString );
	strcat( szLargeString, "DELETE a1, a2, a3, a4, a5, a6, a7, a8, a9 FROM `USERS` AS a1 " );
	strcat( szLargeString, "LEFT JOIN `HOUSES` AS a2 ON a2.`OWNER` = a1.`NAME` " );
	strcat( szLargeString, "LEFT JOIN `VEHICLES` AS a3 ON a3.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `FURNITURE` as a4 ON a4.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `APARTMENTS` as a5 ON a5.`OWNER` = a1.`NAME` " );
	strcat( szLargeString, "LEFT JOIN `GATES` as a6 ON a6.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `TOY_UNLOCKS` as a7 ON a7.`USER_ID` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `SETTINGS` as a8 ON a8.`USER_ID` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `TOYS` as a9 ON a9.`USER_ID` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `GARAGES` as a10 ON a10.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `BUSINESSES` as a11 ON a11.`OWNER_ID` = a1.`ID` " );
	strcat( szLargeString, "WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > 15552000" );
	mysql_function_query( dbHandle, szLargeString, true, "onRemoveInactiveRows", "d", 0 );

	// Reset VIPs
	mysql_function_query( dbHandle, "UPDATE USERS SET VIP_PACKAGE=0, VIP_EXPIRE=0 WHERE UNIX_TIMESTAMP() > VIP_EXPIRE AND VIP_EXPIRE != 0", true, "onRemoveInactiveRows", "d", 1 );

	// Truncate accounts older than 2 months
	mysql_function_query( dbHandle, "UPDATE USERS SET CASH=0,BANKMONEY=0,COINS=0.0,XP=0 WHERE UNIX_TIMESTAMP()-`LASTLOGGED`>5259487", true, "onRemoveInactiveRows", "d", 2 );

	// Remove inactive homes older than 2 weeks
	mysql_function_query( dbHandle, "DELETE a2,a3 FROM `USERS` a1 " \
									"LEFT JOIN `FURNITURE` a2 on a1.`ID` = a2.`OWNER` "\
									"LEFT JOIN `APARTMENTS` a3 on a1.`NAME` = a3.`OWNER` "\
									"WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > IF(a1.`VIP_PACKAGE` >= 3, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 3 );

	mysql_function_query( dbHandle, "UPDATE `USERS` a1 JOIN `HOUSES` a2 ON a1.`NAME` = a2.`OWNER` "\
									"SET a2.`NAME`='Home', a2.`OWNER`='No-one', a2.`TX`=" #H_DEFAULT_X ", a2.`TY`=" #H_DEFAULT_Y ", a2.`TZ`=" #H_DEFAULT_Z ", a2.`INTERIOR`=2, a2.`PASSWORD`='N/A', a2.`WEAPONS`='0.0.0.0.0.0.0.', a2.`AMMO`='-1.-1.-1.-1.-1.-1.-1.' "\
									"WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > IF(a1.`VIP_PACKAGE` >= 3, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 4 );

	// Truncate banned players after 2 weeks
	mysql_function_query( dbHandle, "UPDATE `USERS` a1 JOIN `BANS` a2 ON a1.`NAME` = a2.`NAME` "\
									"SET a1.`BANKMONEY`=0, a1.`CASH`=0 "\
									"WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > IF(a1.`VIP_PACKAGE` >= 3, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 5 );

	// Update vehicles with inactive garages.
	mysql_function_query( dbHandle, "UPDATE `VEHICLES` v JOIN `GARAGES` g ON g.`ID` = v.`GARAGE` JOIN `USERS` u ON u.`ID` = v.`OWNER` "\
									"SET v.`X`=g.`X`, v.`Y`=g.`Y`, v.`Z`=g.`Z`, v.`GARAGE`=-1 "\
									"WHERE v.`GARAGE` != -1 AND UNIX_TIMESTAMP()-u.`LASTLOGGED` > IF(u.`VIP_PACKAGE` >= 3, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 6 );

	// mysql_function_query( dbHandle, "UPDATE `GARAGES` g JOIN `USERS` u ON u.`ID` = g.`OWNER` SET g.`OWNER`=0, g.`INTERIOR`=0 WHERE UNIX_TIMESTAMP()-u.`LASTLOGGED` > 1209600;", true, "onRemoveInactiveRows", "d", 6 );
	mysql_function_query( dbHandle, "DELETE g FROM `GARAGES` g JOIN `USERS` u ON u.`ID` = g.`OWNER` WHERE UNIX_TIMESTAMP()-u.`LASTLOGGED` > IF(u.`VIP_PACKAGE` >= 3, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 7 );

	// Remove 25% of wealth off 2 weeks inactive players.
	// mysql_function_query( dbHandle, "UPDATE `USERS` SET `CASH`=`CASH`*0.75,`BANKMONEY`=`BANKMONEY`*0.75 WHERE UNIX_TIMESTAMP()-`LASTLOGGED`>1209600", true, "onRemoveInactiveRows", "d", 8 );
#endif

	// mysql_function_query( dbHandle, "SELECT * FROM `HOUSES`", true, "OnHouseLoad", "" );
	// mysql_function_query( dbHandle, "SELECT * FROM `BRIBES`", true, "OnBribeLoad", "" );
	mysql_function_query( dbHandle, "SELECT * FROM `APARTMENTS`", true, "OnApartmentLoad", "" );
	// mysql_function_query( dbHandle, "SELECT * FROM `FURNITURE`", true, "OnFurnitureLoad", "" );
	mysql_function_query( dbHandle, "SELECT * FROM `GATES`", true, "OnGatesLoad", "" );
	//mysql_function_query( dbHandle, "SELECT * FROM `ENTRANCES`", true, "OnEntrancesLoad", "" );
	//mysql_function_query( dbHandle, "SELECT * FROM `CASINO_POOLS`", true, "OnCasinoPoolsLoad", "" );
	//mysql_function_query( dbHandle, "SELECT * FROM `BUSINESSES`", true, "OnBusinessLoad", "" );

	/* ** Timers ** */
	rl_ServerUpdate = SetTimer( "OnServerUpdateTimer", 960, true );
	rl_ZoneUpdate = SetTimer( "ZoneTimer", 980, true );

	HTTP( 0, HTTP_GET, "files.sfcnr.com/en_rules.txt", "", "OnRulesHTTPResponse" );

	printf( "[SF-CNR] SF-CnR has been successfully initialized. (Build: "#FILE_BUILD" | Time: %d | Tickcount: %d)", ( g_ServerUptime = gettime( ) ), GetTickCount( ) );
	return 1;
}

public OnDonationRedemptionResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 )
    {
		if ( strmatch( data, "{FFFFFF}Unable to identify transaction." ) ) ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", data, "Okay", "" );
		else
		{
			static aDonation[ E_DONATION_DATA ];
			sscanf( data, "p<|>e<s[17]s[24]s[11]s[64]d>", aDonation );

			// printf("donation {id:%s, name:%s, amount:%s, purpose:%s, date:%d}", aDonation[ E_TRANSACTION_ID ],aDonation[ E_NAME ],aDonation[ E_AMOUNT ],aDonation[ E_PURPOSE ],aDonation[ E_DATE ]);
			if ( strfind( aDonation[ E_PURPOSE ], "San Fierro: Cops And Robbers" ) == -1 )
			{
				ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"This donation is not specifically for this server thus you are unable to retrieve anything.", "Okay", "" );
				return 0;
			}

			// SELECT * FROM `REDEEMED` WHERE `ID` = MD5('%s7resta#ecacakumedeM=yespawr!d@et') LIMIT 0,1
			format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `REDEEMED` WHERE `ID` = MD5('%s%s') LIMIT 0,1", mysql_escape( aDonation[ E_TRANSACTION_ID ] ), szRedemptionSalt );
	 		mysql_function_query( dbHandle, szNormalString, true, "OnCheckForRedeemedVIP", "is", index, data );
		}
	}
 	else ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"Unable to connect to the donation database. Please try again later.", "Okay", "" );
	return 1;
}

thread OnCheckForRedeemedVIP( playerid, data[ ] )
{
	static
		aDonation[ E_DONATION_DATA ],
	    rows, fields
	;
    cache_get_data( rows, fields );

	if ( rows )
	{
		static
			szName[ MAX_PLAYER_NAME ];

		cache_get_field_content( 0, "REDEEMER", szName );
		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", sprintf( ""COL_WHITE"Sorry this transaction ID has already been redeemed by %s.", szName ), "Okay", "" );
	}
	else
	{
		g_redeemVipWait = g_iTime + 10;

		sscanf( data, "p<|>e<s[17]s[24]s[11]s[64]d>", aDonation );

		format( szNormalString, sizeof( szNormalString ), "INSERT INTO `REDEEMED`(`ID`, `REDEEMER`) VALUES (MD5('%s%s'), '%s')", mysql_escape( aDonation[ E_TRANSACTION_ID ] ), szRedemptionSalt, ReturnPlayerName( playerid ) );
		mysql_single_query( szNormalString );

		//printf( "%s\n%s | %s | %f | %s | %d", data, aDonation[ E_TRANSACTION_ID ], aDonation[ E_EMAIL ], floatstr( aDonation[ E_AMOUNT ] ), aDonation[ E_PURPOSE ], aDonation[ E_DATE ]);

		new
			Float: fAmount = floatstr( aDonation[ E_AMOUNT ] ),
			Float: iCoins = fAmount * ( 1 + GetGVarFloat( "vip_bonus" ) ) * 100.0
		;

		if ( p_Uptime[ playerid ] > 604800 )
		{
			if ( fAmount < 1.99999 )
				return SendError( playerid, "Thanks for donating! As this donation was under $2.00 USD, no coin has been issued." );
		}
		else
		{
			if ( fAmount < 4.99999 )
				return SendError( playerid, "Thanks for donating! As this donation was under $5.00 USD, no coins have been issued." );
		}

		p_IrresistibleCoins[ playerid ] += iCoins;
		SetPVarFloat( playerid, "just_donated", fAmount );

		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP PACKAGE]"COL_WHITE" You have received %0.0f Irresistible Coins! Thanks for donating %s!!! :D", iCoins, ReturnPlayerName( playerid ) );

		format( szBigString, 256, ""COL_GREY"Transaction ID:\t"COL_WHITE"%s\n"COL_GREY"Donor Name:\t"COL_WHITE"%s\n"COL_GREY"Amount:\t"COL_WHITE"$%0.2f\n"COL_GREY"Total Coins:\t"COL_WHITE"%0.0f\n"COL_GREY"Time Ago:\t"COL_WHITE"%s",
				aDonation[ E_TRANSACTION_ID ], aDonation[ E_NAME ], floatstr( aDonation[ E_AMOUNT ] ), iCoins, secondstotime( g_iTime - aDonation[ E_DATE ] ) );

		ShowPlayerDialog( playerid, DIALOG_DONATED, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", szBigString, "Continue", "" );
	}
	return 1;
}

thread onRemoveInactiveRows( type )
{
	new
		iRemoved = cache_affected_rows( );

	if ( iRemoved )
	{
		switch( type )
		{
			case 0: format( szNormalString, 96, "[%s %s] Removed approximately %d inactive rows.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		case 1: format( szNormalString, 96, "[%s %s] Reset around %d elapsed VIP accounts.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		case 2: format( szNormalString, 96, "[%s %s] Flushed around %d accounts.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		case 3: format( szNormalString, 96, "[%s %s] Flushed %d inactive owners' furniture.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		case 4: format( szNormalString, 96, "[%s %s] Auctioned %d inactive homes. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		case 5: format( szNormalString, 96, "[%s %s] Flushed around %d banned accounts. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		case 6: format( szNormalString, 96, "[%s %s] Repositioned approximately %d vehicles from inactive garages. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		case 7: format( szNormalString, 96, "[%s %s] Flushed around %d garages. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   		// case 8: format( szNormalString, 96, "[%s %s] 25 percent of %d accounts wealth wiped. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   	}
	    AddFileLogLine( "inactive_rows.txt", szNormalString );

		strreplace( szNormalString, "\r\n", "" );
	    printf( "[INACTIVITY] %s", szNormalString );
	}
	return 1;
}

public OnDynamicObjectMoved( objectid )
{
	if ( objectid == g_apartmentElevator )
	{
		DestroyDynamicObject( g_apartmentElevatorGate ), g_apartmentElevatorGate = INVALID_OBJECT_ID;

		new Float: Y, Float: Z, i = g_apartmentElevatorLevel;
		GetDynamicObjectPos( g_apartmentElevatorDoor1[ i ], Y, Y, Z );
		MoveDynamicObject( g_apartmentElevatorDoor1[ i ], -1956.8068, Y, Z, 5.0 );

		GetDynamicObjectPos( g_apartmentElevatorDoor2[ i ], Y, Y, Z );
		MoveDynamicObject( g_apartmentElevatorDoor2[ i ], -1953.3468, Y, Z, 5.0 );
		return 1;
	}
	return 1;
}

public OnPlayerSelectObject(playerid, type, objectid, modelid, Float:fX, Float:fY, Float:fZ)
{
	CallRemoteFunction( "mapEditor_OnPlayerSelectObject", "ddddfff", playerid, type, objectid, modelid, fX, fY, fZ );
	return 1;
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ)
{
	CallRemoteFunction( "mapEditor_OnPlayerEditObject", "ddddffffff", playerid, playerobject, objectid, response, fX, fY, fZ, fRotX, fRotY, fRotZ );
	return 1;
}

public OnPlayerEditDynamicObject( playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz )
{
	new gateItem = GetPVarInt( playerid, "gate_edititem" );

	if ( gateItem > 6 )
	{
		if ( response == EDIT_RESPONSE_FINAL )
		{
			new
				gID = GetPVarInt( playerid, "gate_editing" );

			switch( gateItem )
			{
				case 9:
				{
					g_gateData[ gID ] [ E_X ] = x;
					g_gateData[ gID ] [ E_Y ] = y;
					g_gateData[ gID ] [ E_Z ] = z;
					g_gateData[ gID ] [ E_RX ] = float( floatround( rx ) );
					g_gateData[ gID ] [ E_RY ] = float( floatround( ry ) );
					g_gateData[ gID ] [ E_RZ ] = float( floatround( rz ) );
					SendClientMessageFormatted( playerid, -1, ""COL_PINK"[GATE]"COL_WHITE" Gate Open Position: "COL_GREY" %f, %f, %f, %f, %f, %f", g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );
				}
				case 10:
				{
					g_gateData[ gID ] [ E_MOVE_X ] = x;
					g_gateData[ gID ] [ E_MOVE_Y ] = y;
					g_gateData[ gID ] [ E_MOVE_Z ] = z;
					g_gateData[ gID ] [ E_MOVE_RX ] = float( floatround( rx ) );
					g_gateData[ gID ] [ E_MOVE_RY ] = float( floatround( ry ) );
					g_gateData[ gID ] [ E_MOVE_RZ ] = float( floatround( rz ) );
					SendClientMessageFormatted( playerid, -1, ""COL_PINK"[GATE]"COL_WHITE" Gate Open Position: "COL_GREY" %f, %f, %f, %f, %f, %f", g_gateData[ gID ] [ E_MOVE_X ], g_gateData[ gID ] [ E_MOVE_Y ], g_gateData[ gID ] [ E_MOVE_Z ], g_gateData[ gID ] [ E_MOVE_RX ], g_gateData[ gID ] [ E_MOVE_RY ], g_gateData[ gID ] [ E_MOVE_RZ ] );
				}
			}
			UpdateGateData( gID );
			cmd_editgate( playerid, sprintf( "%d", gID ) );
			Streamer_Update( playerid ); // SyncObject( playerid );
		}
		return 1;
	}

 	new editing_house = GetPVarInt( playerid, "furniture_house" );
 	new editing_furniture = GetPVarInt( playerid, "furniture_id" );

	new houseid = p_InHouse[ playerid ];

    if ( houseid == -1 )
   		return SendError( playerid, "You're not inside any house." );

    if ( houseid != editing_house )
   		return SendError( playerid, "There was an issue editing the furniture of this home, try again." );

   	if ( ! IsPlayerHomeOwner( playerid, houseid ) )
   	 	return SendError( playerid, "You are not the owner of this house." );

	static Float: lastX, Float: lastY, Float: lastZ;
	static Float: lastRX, Float: lastRY, Float: lastRZ;
	GetDynamicObjectPos( objectid, lastX, lastY, lastZ );
	GetDynamicObjectRot( objectid, lastRX, lastRY, lastRZ );

	switch( response )
	{
	    case EDIT_RESPONSE_FINAL:
	    {
			SetDynamicObjectPos( objectid, x, y, z );
			SetDynamicObjectRot( objectid, rx, ry, rz );

			format( szBigString, sizeof( szBigString ), "UPDATE `FURNITURE` SET `X`=%f,`Y`=%f,`Z`=%f,`RX`=%f,`RY`=%f,`RZ`=%f WHERE `ID`=%d AND `HOUSE_ID`=%d", x, y, z, rx, ry, rz, editing_furniture, editing_house );
			mysql_single_query( szBigString );

			SendServerMessage( playerid, "Furniture has been successfully updated." );
        	ShowPlayerDialog( playerid, DIALOG_FURNITURE, DIALOG_STYLE_LIST, "{FFFFFF}Furniture", "Purchase Furniture\nSelect Furniture Easily\nSelect Furniture Manually\nSelect Furniture Nearest\n"COL_RED"Remove All Furniture", "Confirm", "Back" );
		}
		case EDIT_RESPONSE_CANCEL:
		{
			SetDynamicObjectPos( objectid, lastX, lastY, lastZ );
			SetDynamicObjectRot( objectid, lastRX, lastRY, lastRZ );
			SendServerMessage( playerid, "You have canceled editing the piece of furniture selected." );
        	ShowPlayerDialog( playerid, DIALOG_FURNITURE, DIALOG_STYLE_LIST, "{FFFFFF}Furniture", "Purchase Furniture\nSelect Furniture Easily\nSelect Furniture Manually\nSelect Furniture Nearest\n"COL_RED"Remove All Furniture", "Confirm", "Back" );
		}
	}


	return 1;
}

public OnGameModeExit( )
{
	KillTimer( rl_ServerUpdate );
	KillTimer( rl_ZoneUpdate );
    for( new t; t != MAX_TEXT_DRAWS; t++ ) TextDrawDestroy( Text: t );
	//SendRconCommand( "exit" );
	return 1;
}

public OnServerUpdateTimer( )
{
	static
		iState, iVehicle, iWeapon, iAmmo,
		Float: fLastRate
	;

	// for hooks
	CallLocalFunction( "OnServerUpdate", "" );

	// better to store in a variable as we are getting the timestamp from hardware
	g_iTime = gettime( );

	// Time For Tax?
	if ( g_iTime >= GetGVarInt( "taxtime" ) ) {
		UpdateServerVariable( "taxtime", g_iTime + 86400, 0.0, "", GLOBAL_VARTYPE_INT );
		BeginEconomyTax( );
	}

 	// Happy Hour
 	new
 		playersOnline = Iter_Count(Player);

	if ( ( g_HappyHour = playersOnline <= 20 ) == true ) {
		// Maximum of 25% decrease
		g_HappyHourRate = 0.25 - ( playersOnline / 80.0 );

		// Only update colors if neccessary
		if ( fLastRate != g_HappyHourRate )
		{
			TextDrawSetString( g_NotManyPlayersTD, sprintf( "Coin generation increased by %0.1f%% as there aren't many players online!", g_HappyHourRate * 100.0 ) );
			TextDrawColor( g_NotManyPlayersTD, setAlpha( COLOR_RED, floatround( 200.0 - 10.0 * float( playersOnline ) ) ) );
			TextDrawShowForAllSpawned( g_NotManyPlayersTD );
		}

		// Update last rate
		fLastRate = g_HappyHourRate;
	} else {
		 // Disable Color
		g_HappyHourRate = 0.0;
		TextDrawColor( g_NotManyPlayersTD, 0 );
		TextDrawHideForAll( g_NotManyPlayersTD );
	}

	// Begin iterating all players
	foreach ( new playerid : Player )
	{
		// For modules that wish to update data appropriately
		CallLocalFunction( "OnPlayerUpdateEx", "d", playerid );

		if ( IsPlayerSpawned( playerid ) && p_PlayerLogged{ playerid } )
		{
			iVehicle 	= GetPlayerVehicleID( playerid );
			iWeapon 	= GetPlayerWeapon( playerid );
			iState 		= GetPlayerState( playerid );

		    // Generally Updated textdraws
			PlayerTextDrawSetString( playerid, p_LocationTD[ playerid ], GetPlayerArea( playerid ) );

			// Update casino labels
			UpdateDynamic3DTextLabelText( p_RewardsLabel_Caligs[ playerid ], COLOR_GOLD, sprintf( "[CASINO REWARDS]\n\n"COL_WHITE"You have %s rewards points!", points_format( p_CasinoRewardsPoints[ playerid ] ) ) );
			UpdateDynamic3DTextLabelText( p_RewardsLabel_4Drags[ playerid ], COLOR_GOLD, sprintf( "[CASINO REWARDS]\n\n"COL_WHITE"You have %s rewards points!", points_format( p_CasinoRewardsPoints[ playerid ] ) ) );
			UpdateDynamic3DTextLabelText( p_RewardsLabel_Visage[ playerid ], COLOR_GOLD, sprintf( "[CASINO REWARDS]\n\n"COL_WHITE"You have %s rewards points!", points_format( p_CasinoRewardsPoints[ playerid ] ) ) );

			// Toggle total coin bar
			if ( ! IsPlayerSettingToggled( playerid, SETTING_COINS_BAR ) )
				PlayerTextDrawSetString( playerid, p_CoinsTD[ playerid ], sprintf( "%05.3f", p_IrresistibleCoins[ playerid ] ) );

			// Decrementing Weed Opacity Label
		    if ( p_WeedLabel[ playerid ] != Text3D: INVALID_3DTEXT_ID )
				UpdateDynamic3DTextLabelText( p_WeedLabel[ playerid ], setAlpha( COLOR_GREEN, floatround( ( float( GetPlayerDrunkLevel( playerid ) ) / 5000.0 ) * 255.0 ) ), "Blazed W33D Recently!" );

			// Not near kidnapper then untie
			if ( IsPlayerTied( playerid ) && isNotNearPlayer( playerid, p_TiedBy[ playerid ] ) && ( g_iTime - p_TiedAtTimestamp[ playerid ] ) >= 8 )
				UntiePlayer( playerid );

			// Check if player is near a poker table
			if ( PlayerData[ playerid ] [ E_PLAYER_CURRENT_HANDLE ] != ITER_NONE && ! IsPlayerInRangeOfTable( playerid, PlayerData[ playerid ] [ E_PLAYER_CURRENT_HANDLE ], 3.0 ) )
				Player_CheckPokerGame( playerid, "Out Of Range" ); // KickPlayerFromTable( playerid );

			// Not near detained player then uncuff
			//if ( IsPlayerDetained( playerid ) && isNotNearPlayer( playerid, p_DetainedBy[ playerid ] ) && ( g_iTime - p_TiedAtTimestamp[ playerid ] ) >= 8 )
			//	Uncuff( playerid );

		 	// Remove invalid visage highrollers
		 	if ( ! p_IsCasinoHighRoller{ playerid } && IsPlayerInHighRoller( playerid ) ) {
		 		SetPlayerPos( playerid, 2597.8943, 1603.1852, 1506.1733 );
		 		SendError( playerid, "You need to be a Highroller to access this area. Get access through Casino Rewards." );
		 	}

		 	// Surfing a criminal vehicle
		 	if ( p_WantedLevel[ playerid ] < 6 && p_Class[ playerid ] != CLASS_POLICE )
		 	{
		 		new
		 			surfing_vehicle = GetPlayerSurfingVehicleID( playerid );

		 		if ( surfing_vehicle != INVALID_VEHICLE_ID )
		 		{
		 			new
		 				driverid = GetVehicleDriver( surfing_vehicle );

		 			if ( IsPlayerConnected( driverid ) && p_WantedLevel[ driverid ] > 2 && p_Class[ driverid ] != CLASS_POLICE ) {
		 				GivePlayerWantedLevel( playerid, 6 - p_WantedLevel[ playerid ] );
		 			}
		 		}
		 	}

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

			new
				aiming_player = GetPlayerTargetPlayer( playerid );

			if ( ! p_WantedLevel[ playerid ] && p_Class[ playerid ] != CLASS_POLICE && g_iTime > p_AimedAtPolice[ playerid ] && IsPlayerConnected( aiming_player ) && ! IsPlayerNPC( aiming_player ) && p_Class[ aiming_player ] == CLASS_POLICE ) {
				GivePlayerWantedLevel( playerid, 6 );
				p_AimedAtPolice[ playerid ] = g_iTime + 10;
				ShowPlayerHelpDialog( playerid, 6000, "You have aimed your weapon at a law enforcement officer! ~n~~n~~r~~h~You are now wanted." );
			}

			// AFK Players
			if ( ( GetTickCount( ) - p_AFKTime[ playerid ] ) >= 45000 )
			{
				// AFK Jail
				if ( p_WantedLevel[ playerid ] >= 6 && p_InHouse[ playerid ] == -1 && !IsPlayerAdminOnDuty( playerid ) && !IsPlayerInEntrance( playerid, g_VIPLounge[ CITY_SF ] ) && !IsPlayerInEntrance( playerid, g_VIPLounge[ CITY_LV ] ) && !IsPlayerInEntrance( playerid, g_VIPLounge[ CITY_LS ] ) && !IsPlayerTied( playerid ) && !IsPlayerKidnapped( playerid ) && !IsPlayerCuffed( playerid ) && !IsPlayerTazed( playerid ) && IsPlayerSpawned( playerid ) ) { // && !IsPlayerDetained( playerid )
			    	JailPlayer( playerid, 60, 1 );
		        	SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been sent to jail for 60 seconds by the server "COL_LRED"[AFK Wanted]", ReturnPlayerName( playerid ), playerid );
				}

				// AFK Admins
				if ( IsPlayerAdminOnDuty( playerid ) )
					cmd_aod( playerid, "" );
			}

			// Anti Camping In Vault
			if ( IsPlayerInBank( playerid ) )
			{
			 	if ( IsPlayerInArea( playerid, -1412.215209, -1400.443237, 853.086669, 865.716735 ) && !g_bankvaultData[ CITY_SF ] [ E_DISABLED ] )
				{
					SendServerMessage( playerid, "You've been moved as you've entered the vault whilst it's closed." );
					SetPlayerPos( playerid, -1416.3499, 859.2744, 984.7126 );
				}

				if ( IsPlayerInArea( playerid, 2102.2590, 2113.5295, 1229.8595, 1246.2588 ) )
				{
					new
						world = GetPlayerVirtualWorld( playerid );

					if ( ( world == g_bankvaultData[ CITY_LV ] [ E_WORLD ] && !g_bankvaultData[ CITY_LV ] [ E_DISABLED ] ) || ( world == g_bankvaultData[ CITY_LS ] [ E_WORLD ] && !g_bankvaultData[ CITY_LS ] [ E_DISABLED ] ) )
					{
						SendServerMessage( playerid, "You've been moved as you've entered the vault whilst it's closed." );
						SetPlayerPos( playerid, 2121.7827, 1233.3225, 1017.1369 );
					}
				}
			}

			// Decrementing Wanted Level
			/*if ( p_WantedLevel[ playerid ] > 2 && !IsPlayerAdminOnDuty( playerid ) )
			{
				new
					Float: fDistance = FLOAT_INFINITY, iWanted;

				GetClosestPlayerEx( playerid, CLASS_POLICE, fDistance );

				if ( fDistance >= 500.0 ) {
					if ( GetPVarInt( playerid, "LoseWantedCD" ) < g_iTime ) {
						if ( p_WantedLevel[ playerid ] > 1800 ) 		iWanted = 24;
						else if ( p_WantedLevel[ playerid ] > 1000 ) iWanted = 12;
						else if ( p_WantedLevel[ playerid ] > 500 )	iWanted = 6;
						else if ( p_WantedLevel[ playerid ] > 250 )	iWanted = 4;
						else if ( p_WantedLevel[ playerid ] > 12 ) 	iWanted = 2;
						GivePlayerWantedLevel( playerid, -iWanted );
						SetPVarInt( playerid, "LoseWantedCD", g_iTime + 30 );
					}
				}
			}*/

			// Tied probably?
			if ( IsPlayerTied( playerid ) && g_iTime - p_TimeTiedAt[ playerid ] > MAX_TIME_TIED )
			{
				TogglePlayerControllable( playerid, 1 );
				p_Tied{ playerid } = false;
				Delete3DTextLabel( p_TiedLabel[ playerid ] );
				p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
				p_TimeTiedAt[ playerid ] = 0;
				p_Kidnapped{ playerid } = false;
				ShowPlayerHelpDialog( playerid, 1200, "You have been tied for %s.~n~~n~Your tie is loose.", secondstotime( g_iTime - p_TimeTiedAt[ playerid ] ) );
			}

			// Alcatraz Escape Mechanism
			if ( g_iTime > p_AlcatrazEscapeTS[ playerid ] && iState != PLAYER_STATE_SPECTATING )
			{
				if ( IsPlayerAFK( playerid ) )
					p_AlcatrazEscapeTS[ playerid ] = g_iTime + ALCATRAZ_TIME_PAUSE; // Money farmers?

				if ( IsPlayerInDynamicArea( playerid, g_AlcatrazArea ) )
				{
					if ( !IsPlayerJailed( playerid ) && p_Class[ playerid ] != CLASS_POLICE ) // && !IsPlayerDetained( playerid )
					{
						if ( GetPVarInt( playerid, "AlcatrazWantedCD" ) < g_iTime )
						{
							SetPVarInt( playerid, "AlcatrazWantedCD", g_iTime + ALCATRAZ_TIME_WANTED );
							GivePlayerWantedLevel( playerid, 24 );
							ShowPlayerHelpDialog( playerid, 6000, "Warning! You are now wanted for accessing a ~r~~h~prohibited area!" );
						}
					}
				}
				else
				{
					if ( IsPlayerJailed( playerid ) && IsPlayerSpawned( playerid ) && !IsPlayerAdminOnDuty( playerid ) )
					{
						if ( p_inAlcatraz{ playerid } )
						{
							if ( p_Class[ playerid ] != CLASS_POLICE && !IsPlayerAdminJailed( playerid ) && !IsPlayerAFK( playerid ) )
							{
								SetPVarInt( playerid, "AlcatrazWantedCD", g_iTime + ALCATRAZ_TIME_WANTED );
							    PlainUnjailPlayer 		( playerid );
								SetPlayerColorToTeam	( playerid );
								SetPlayerHealth 		( playerid, 100.0 );
								p_inAlcatraz 			{ playerid } = false;

							    if ( GetPVarInt( playerid, "AlcatrazGiveWantedCD" ) < g_iTime ) {
							    	GivePlayerWantedLevel( playerid, 64 );
									SendGlobalMessage( -1, ""COL_GOLD"[JAIL ESCAPE]{FFFFFF} %s(%d) has escaped from Alcatraz, 64 wanted goes to him!", ReturnPlayerName( playerid ), playerid );
									SetPVarInt( playerid, "AlcatrazGiveWantedCD", g_iTime + 60 );
							    }
							    else SendGlobalMessage( -1, ""COL_GOLD"[JAIL ESCAPE]{FFFFFF} %s(%d) has escaped from Alcatraz!", ReturnPlayerName( playerid ), playerid );
							}
							else
							{
								SendError( playerid, "You cannot leave the prison. It's prohibited." );
								SetPlayerPosToPrison( playerid );
							}
						}
					}
				}
			}

			// Check if the player's VIP has expired
			CheckPlayerVipExpiry( playerid );

			// Anti Money Hack
			if ( GetPlayerCash( playerid ) != GetPlayerMoney( playerid ) ) {
	            ResetPlayerMoney( playerid );
	         	GivePlayerMoney( playerid, GetPlayerCash( playerid ) );
			}

			if ( IsPlayerInAnyVehicle( playerid ) )
			{
			    if ( iState == PLAYER_STATE_PASSENGER )
			    {
			    	if ( GetVehicleModel( iVehicle ) == 416 )
			    	{
			    		new
			    			iDriver = GetVehicleDriver( iVehicle );

			    		if ( IsPlayerConnected( iDriver ) )
			    		{
			    			if ( p_Class[ iDriver ] == CLASS_MEDIC )
			    			{
			    				new
			    					Float: fHealth;

			    				if ( GetPlayerHealth( playerid, fHealth ) && fHealth < 100.0 )
			    			 		SetPlayerHealth( playerid, fHealth + 2.0 ), GivePlayerCash( iDriver, 10 );
			    			}
			    		}
			    	}
			    }
			}

			if ( p_AdminLevel[ playerid ] < 1 )
			{
			    /* ANTICHEAT */
				if ( g_PingLimit > 500 && GetPlayerPing( playerid ) > g_PingLimit && !p_PingImmunity{ playerid } )
				{
					SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been kicked for excessive ping [%d/%d].", ReturnPlayerName( playerid ), playerid, GetPlayerPing( playerid ), g_PingLimit );
				    KickPlayerTimed( playerid );
				}
				if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_USEJETPACK )
				{
					SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for spawning a jetpack.", ReturnPlayerName( playerid ), playerid );
					AdvancedBan( playerid, "Server", "Jetpack", ReturnPlayerIP( playerid ) );
				}
				if ( IsWeaponBanned( iWeapon ) ) {
					SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for spawning an illegal weapon.", ReturnPlayerName( playerid ), playerid );
					AdvancedBan( playerid, "Server", "Illegal Weapon", ReturnPlayerIP( playerid ) );
				}
				GetPlayerWeaponData( playerid, 0, iAmmo, iAmmo );
				if ( iAmmo == 1000 ) {
					SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for aimbot.", ReturnPlayerName( playerid ), playerid );
					AdvancedBan( playerid, "Server", "Aimbot", ReturnPlayerIP( playerid ) );
				}
			}

			// samp ac force
			if ( p_forcedAnticheat[ playerid ] > 0 && ! IsPlayerUsingSampAC( playerid ) ) {
				SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been kicked for disabling SAMP-AC. "COL_YELLOW"("AC_WEBSITE")", ReturnPlayerName( playerid ), playerid );
				KickPlayerTimed( playerid );
			}
		}
	}


	// Soft delete gang
	foreach (new gangid : gangs) if ( g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] != 0 && g_iTime > g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] )
	{
		new
			members = GetOnlineGangMembers( gangid );

		if ( members <= 0 )
		{
			new
				cur = gangid;

			printf("Removed Gang From Cache Gang Id %d Since No Ppl", g_gangData[ gangid ] [ E_SQL_ID ] );
			DestroyGang( gangid, true, .iter_remove = false );
			Iter_SafeRemove( gangs, cur, gangid );
		}
		else g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] = 0;
	}

	// Restore and Replenish Stuff
    if ( g_iTime > g_RestoreRobberiesBribes )
    {
    #if defined WEAPON_DROP_ENABLED
    	// Replenish Weapon Drops
    	ClearInactiveWeaponDrops( g_iTime );
    #endif

    	// Replenish Vaults
		for( new i = 0; i < sizeof( g_bankvaultData ); i++ ) if ( g_bankvaultData[ i ] [ E_DISABLED ] && g_iTime > g_bankvaultData[ i ] [ E_TIMESTAMP_CLOSE ] )
		{
			StopDynamicObject	( g_bankvaultData[ i ] [ E_OBJECT ] );
			DestroyDynamicObject( g_bankvaultData[ i ] [ E_OBJECT ] );

			g_bankvaultData[ i ] [ E_TIMESTAMP_CLOSE ] = 0;
			g_bankvaultData[ i ] [ E_DISABLED ] = false;

			switch( i )
			{
				case CITY_SF: SetDynamicObjectMaterial( ( g_bankvaultData[ i ] [ E_OBJECT ] = CreateDynamicObject( 18766, -1412.565063, 859.274536, 983.132873, 0.000000, 90.000000, 90.000000 ) ), 0, 18268, "mtbtrackcs_t", "mp_carter_cage", -1 );
				case CITY_LV: g_bankvaultData[ i ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ i ] [ E_WORLD ] );
				case CITY_LS: g_bankvaultData[ i ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ i ] [ E_WORLD ] );
				case VAULT_BOAT: SetDynamicObjectMaterial( ( g_bankvaultData[ VAULT_BOAT ] [ E_OBJECT ] = CreateDynamicObject( 19435, -2371.416992, 1552.027709, 1.907187, 0.000000, 0.000000, 28.0000, g_bankvaultData[ VAULT_BOAT ] [ E_WORLD ] ) ), 0, 18268, "mtbtrackcs_t", "mp_carter_cage", -1 );
			}
		}

		g_RestoreRobberiesBribes = g_iTime + 10;
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}

stock GetGangCapturedTurfs( gangid )
{
	new
		z,
		c;

	foreach ( z : turfs ) if ( g_gangTurfData[ z ] [ E_OWNER ] != INVALID_GANG_ID && g_gangTurfData[ z ] [ E_OWNER ] == gangid ) {
		c++;
	}
	return c;
}

public ZoneTimer( )
{
    new
    	iKeys, iUpDownKeys, iLeftRightKeys;

	SendRconCommand( sprintf( "worldtime %s, %s", GetDayToString( g_WorldDayCount ), TimeConvert( g_WorldClockSeconds++ ) ) );

 	if ( g_WorldClockSeconds >= 1440 )
 	{
 		// call a function when the server day ends
 		CallLocalFunction( "OnServerGameDayEnd", "" );

 	    g_WorldWeather = randarg( 10, 11, 12 );
 	    g_WorldClockSeconds = 0;
        g_WorldDayCount = ( g_WorldDayCount == 6 ? 0 : g_WorldDayCount + 1 );
		TextDrawSetString( g_WorldDayTD, GetDayToString( g_WorldDayCount ) );

		RenewWeed( );
		PlayerPlaceRandomHits( );

		foreach(new p : Player) {
			if ( !p_VIPLevel[ p ] && !IsPlayerUsingRadio( p ) ) {
				PlayAudioStreamForPlayer( p, "http://files.sfcnr.com/game_sounds/pls_donate.mp3" );
			}
		}

		foreach(new g : gangs)
		{
			new
				afk_members, online_members = GetOnlineGangMembers( g, .afk_members = afk_members );

			if ( online_members >= TAKEOVER_NEEDED_PEOPLE )
			{
				new
					profit = 0;

				foreach( new zoneid : turfs ) if ( g_gangTurfData[ zoneid ] [ E_OWNER ] != INVALID_GANG_ID && g_gangTurfData[ zoneid ] [ E_OWNER ] == g )
				{
					// facilities will not pay out respect
					if ( g_gangTurfData[ zoneid ] [ E_FACILITY_GANG ] == INVALID_GANG_ID ) {
						g_gangData[ g ] [ E_RESPECT ] ++;
					}

					// accumulate profit
					profit += Turf_GetProfitability( zoneid, online_members - afk_members );
				}

				g_gangData[ g ] [ E_BANK ] += profit;

		    	if ( profit > 0 ) {
		    		SaveGangData( g );
		    		SendClientMessageToGang( g, g_gangData[ g ] [ E_COLOR ], "[GANG] "COL_GOLD"%s"COL_WHITE" has been earned from territories and deposited in the gang bank account.", cash_format( profit ) );
		    	}
    		}
    	}
	}


	new
		oCount = 0;

    foreach( new z : turfs )
	{
	    if ( g_gangzoneAttacker[ z ] != INVALID_GANG_ID )
	    {
	    	new
	    		attacker_member_count = GetPlayersInGangZone( z, g_gangzoneAttacker[ z ] );

	        if ( attacker_member_count >= TAKEOVER_NEEDED_PEOPLE )
	        {
	          	if ( g_gangTurfData[ z ] [ E_OWNER ] != INVALID_GANG_ID )
			      	oCount = GetPlayersInGangZone( z, g_gangTurfData[ z ] [ E_OWNER ] );

				new
					attacker_time_required = -10 * ( attacker_member_count - TAKEOVER_NEEDED_PEOPLE ) + ( g_gangTurfData[ z ] [ E_FACILITY_GANG ] == INVALID_GANG_ID ? 60 : 120 );

			   	// minimum of 20 seconds
				if ( attacker_time_required < 20 )
					attacker_time_required = 20;

	            if ( g_gangzoneAttackCount[ z ] < attacker_time_required && oCount == 0 )
	            {
	            	foreach ( new i : Player ) if ( p_Class[ i ] != CLASS_POLICE && p_GangID[ i ] == g_gangzoneAttacker[ z ] && IsPlayerInDynamicArea( i, g_gangTurfData[ z ] [ E_AREA ] ) ) {
						if ( p_WantedLevel[ i ] < 2 ) GivePlayerWantedLevel( i, 2 - p_WantedLevel[ i ] );
	            		ShowPlayerHelpDialog( i, 1500, "~r~Control~w~ the area for %d seconds!", attacker_time_required - g_gangzoneAttackCount[ z ] );
	            	}
	            	g_gangzoneAttackCount[ z ] ++;
                 	g_gangzoneAttackTimeout[ z ] = 0;
					continue;
				}
	            else if ( g_gangzoneAttackCount[ z ] >= attacker_time_required )
	            {
	            	static szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

                 	new earned_money = 0;
                 	new owner_gang = g_gangTurfData[ z ] [ E_OWNER ];
                 	new attacker_gang = g_gangzoneAttacker[ z ];

					new Float: min_x, Float: min_y;
					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ z ] [ E_AREA ], E_STREAMER_MIN_X, min_x );
					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ z ] [ E_AREA ], E_STREAMER_MIN_Y, min_y );

				    Get2DCity 				( szCity, min_x, min_y );
				    GetZoneFromCoordinates 	( szLocation, min_x, min_y );

	                GangZoneStopFlashForAll	( g_gangTurfData[ z ] [ E_ID ] );
					GangZoneShowForAll 		( g_gangTurfData[ z ] [ E_ID ], setAlpha( g_gangData[ g_gangzoneAttacker[ z ] ] [ E_COLOR ], 0x80 ) );

					g_gangTurfData[ z ] [ E_COLOR ] = setAlpha( g_gangData[ g_gangzoneAttacker[ z ] ] [ E_COLOR ], 0x80 );
	                g_gangTurfData[ z ] [ E_OWNER ] = g_gangzoneAttacker[ z ];

                 	g_gangzoneAttacker 		[ z ] = INVALID_GANG_ID;
	                g_gangzoneAttackCount	[ z ] = 0;
                 	g_gangzoneAttackTimeout	[ z ] = 0;

                 	// Money Grub
                 	if ( Iter_Contains( gangs, owner_gang ) )
					{
						new afk_opmembers, online_opmembers = GetOnlineGangMembers( owner_gang, .afk_members = afk_opmembers );
						new zone_money = Turf_GetProfitability( z, online_opmembers - afk_opmembers );

						if ( g_gangData[ owner_gang ] [ E_BANK ] > zone_money )
						{
							// deduct from gang bank and give to op, take 10% as fee
				            g_gangData[ owner_gang ] [ E_BANK ] -= zone_money;
				            SaveGangData( owner_gang );

				           	earned_money = floatround( float( zone_money ) * 0.9 );
				            g_gangData[ attacker_gang ] [ E_BANK ] += earned_money;
				       	}

				      	// credit respect
						g_gangData[ attacker_gang ] [ E_RESPECT ] ++;
						SaveGangData( attacker_gang );
					}

					// Alert gang
					if ( earned_money ) {
						SendClientMessageToGang	( attacker_gang, g_gangData[ attacker_gang ] [ E_COLOR ], "[GANG]{FFFFFF} We have captured a turf near %s in %s and earned "COL_GOLD"%s"COL_WHITE"!", szLocation, szCity, cash_format( earned_money ) );
					} else {
						SendClientMessageToGang	( attacker_gang, g_gangData[ attacker_gang ] [ E_COLOR ], "[GANG]{FFFFFF} We have captured a turf near %s in %s!", szLocation, szCity );
					}

                 	// Give Gangmembers XP & Wanted
					foreach(new d : Player)
					{
						new in_area = IsPlayerInDynamicArea( d, g_gangTurfData[ z ] [ E_AREA ] );

						if ( in_area )
							PlayerTextDrawSetString( d, g_ZoneOwnerTD[ d ], sprintf( "~r~~h~(%s)~n~~w~~h~%s", g_gangTurfData[ z ] [ E_FACILITY_GANG ] != INVALID_GANG_ID ? ( "FACILITY" ) : ( "TERRITORY" ), ReturnGangName( attacker_gang ) ) );

						if ( IsPlayerSpawned( d ) && ! IsPlayerAFK( d ) && p_Class[ d ] == CLASS_CIVILIAN && p_GangID[ d ] == attacker_gang && ! IsPlayerInPaintBall( d ) ) {
							if ( in_area ) {
								GivePlayerScore( d, 2 );
								GivePlayerWantedLevel( d, 6 );
							}
							PlayerPlaySound( d, 36205, 0.0, 0.0, 0.0 );
						}
					}
				}
				else if ( g_gangTurfData[ z ] [ E_OWNER ] != INVALID_GANG_ID && oCount > 0 ) {
	            	foreach ( new i : Player ) if ( p_GangID[ i ] != INVALID_GANG_ID && IsPlayerInDynamicArea( i, g_gangTurfData[ z ] [ E_AREA ] ) ) {
	            		// message the attacker that they gotta attack
	            		if ( p_GangID[ i ] == g_gangzoneAttacker[ z ] ) {
		            		ShowPlayerHelpDialog( i, 1500, "~r~Kill~w~ the %d gang member%s in the area!", oCount, oCount == 1 ? ( "" ) : ( "s" ) );
		            	}
		            	// message the defender
		            	else if ( p_GangID[ i ] == g_gangTurfData[ z ] [ E_OWNER ] ) {
		            		ShowPlayerHelpDialog( i, 1500, "~b~Defend~w~ the area from the %d enemy gang member%s!", attacker_member_count, attacker_member_count == 1 ? ( "" ) : ( "s" ) );
		            	}
		            }
				}
	        }
	        else
	        {
	        	if ( ! g_gangzoneAttackTimeout[ z ] ) {
	        		g_gangzoneAttackTimeout[ z ] = g_iTime + 10;
                    SendClientMessageToGang( g_gangzoneAttacker[ z ], g_gangData[ g_gangzoneAttacker[ z ] ] [ E_COLOR ], "[GANG]{FFFFFF} You have 10 seconds to get back in the area until the turf war is stopped!" );
	        	}
	        	else if ( g_iTime >= g_gangzoneAttackTimeout[ z ] )
				{
		         	g_gangzoneAttackCount[ z ] = 0;
		         	g_gangzoneAttackTimeout[ z ] = 0;
		     		GangZoneStopFlashForAll( g_gangTurfData[ z ] [ E_ID ] );
		            g_gangzoneAttacker[ z ] = INVALID_GANG_ID;
				}
	        }
		}
	}

	// Looping every 1000 MS
	foreach(new playerid : Player)
	{
		if ( ! p_PlayerLogged{ playerid } )
			continue;

		SetPlayerWeather( playerid, ( GetPlayerInterior( playerid ) || GetPlayerVirtualWorld( playerid ) ) ? 1 : g_WorldWeather );
		UpdatePlayerTime( playerid );

		// Remove Anti-Spawn Kill
		if ( p_AntiSpawnKillEnabled{ playerid } && g_iTime > p_AntiSpawnKill[ playerid ] ) {
			DisablePlayerSpawnProtection( playerid );
		}

		// Increment Variables Whilst Not AFK
		if ( !IsPlayerAFK( playerid ) ) // New addition
		{
			// Increase Time Online
			switch( ++ p_Uptime[ playerid ] )
			{
			    //case 300: 	ShowAchievement( playerid, "You have been online for ~r~5~w~~h~ minutes!", 1 );
			    case 1200: 	ShowAchievement( playerid, "You have been online for ~r~20~w~~h~ minutes!", 2 );
			    case 3600: 	ShowAchievement( playerid, "You have been online for ~r~1~w~~h~ hour!", 4 );
			    case 18000: ShowAchievement( playerid, "You have been online for ~r~5~w~~h~ hours!", 6 );
			    case 36000: ShowAchievement( playerid, "You have been online for ~r~10~w~~h~ hours!", 8 );
			    case 54000: ShowAchievement( playerid, "You have been online for ~r~15~w~~h~ hours!", 10 );
			    case 72000: ShowAchievement( playerid, "You have been online for ~r~20~w~~h~ hours!", 12 );
			    case 86400: ShowAchievement( playerid, "You have been online for ~r~1~w~~h~ day!", 15 );
			}

			// Increase Irresistible Coins (1/20 = cred/min)
			if ( GetPlayerKeys( playerid, iKeys, iUpDownKeys, iLeftRightKeys ) && ! IsPlayerOnRoulette( playerid ) && ! IsPlayerOnSlotMachine( playerid ) && GetPlayerVehicleSeat( playerid ) <= 0 )
			{
				if ( iKeys != 0 || iUpDownKeys != 0 || iLeftRightKeys != 0 ) { // GetPlayerScore( playerid ) > 10 &&

					new
						Float: iCoinGenRate = 35.0;

					// VIP check
					if ( p_VIPLevel[ playerid ] >= VIP_GOLD )
						iCoinGenRate *= 0.75; // Reduce by 25% if Diamond

					else if ( p_VIPLevel[ playerid ] == VIP_BRONZE )
						iCoinGenRate *= 0.90; // Reduce by 10% if Diamond

					// Happy Hour
					if ( g_HappyHour && ( 0.0 <= g_HappyHourRate <= 0.25 ) )
						iCoinGenRate *= 1.0 - g_HappyHourRate;

					p_IrresistibleCoins[ playerid ] += ( 1.0 / iCoinGenRate ) / 60.0; // Prev 25.92
				}
			}
		}

		// CIA Visible On Radar after firing a shot
		if ( p_VisibleOnRadar[ playerid ] != 0 && p_VisibleOnRadar[ playerid ] < g_iTime )
			SetPlayerColorToTeam( playerid ), p_VisibleOnRadar[ playerid ] = 0;
	}
	return 1;
}

public OnPlayerUpdateGangZone( playerid, zoneid )
{
	if ( ! p_inMovieMode{ playerid } )
	{
		if ( zoneid == INVALID_GANG_TURF )
			return PlayerTextDrawSetString( playerid, g_ZoneOwnerTD[ playerid ], "_" );

		// if ( p_GangID[ playerid ] != INVALID_GANG_ID && g_gangTurfData[ zoneid ] [ E_OWNER ] == INVALID_GANG_ID ) ShowPlayerHelpDialog( playerid, 2000, "You can take over this turf by typing ~g~/takeover" );
		PlayerTextDrawSetString( playerid, g_ZoneOwnerTD[ playerid ], sprintf( "~r~~h~(%s)~n~~w~~h~%s", g_gangTurfData[ zoneid ] [ E_FACILITY_GANG ] != INVALID_GANG_ID ? ( "FACILITY" ) : ( "TERRITORY" ), ReturnGangName( g_gangTurfData[ zoneid ] [ E_OWNER ] ) ) );
	}
	return 1;
}

public OnRulesHTTPResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 )
    {
    	printf( "[RULES] Rules have been updated! Character Size: %d", strlen( data ) );
    	strcpy( szRules, data );
    }
	return 1;
}

public OnTwitterHTTPResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 ) //Did the request succeed?
 		ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{00CCFF}@IrresistibleDev"COL_WHITE" - Twitter", data, "Okay", "" );
	else
		ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{00CCFF}@IrresistibleDev"COL_WHITE" - Twitter", ""COL_WHITE"An error has occurred, try again later.", "Okay", "" );
	return 1;
}

public OnPlayerRequestClass( playerid, classid )
{
	TextDrawHideForPlayer( playerid, g_AdminLogTD );
    TextDrawShowForPlayer( playerid, g_ClassBoxTD );
	TextDrawHideForPlayer( playerid, g_WebsiteTD );
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_MotdTD );
	PlayerTextDrawHide( playerid, g_ZoneOwnerTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_NotManyPlayersTD );
	TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	TextDrawHideForPlayer( playerid, g_WorldDayTD );
	PlayerTextDrawHide( playerid, p_LocationTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_PlayerRankTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_PlayerRankTextTD[ playerid ] );
	KillTimer( p_TrackingTimer[ playerid ] );
	p_TrackingTimer[ playerid ] = -1;
	PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_ExperienceTD[ playerid ] );
	HidePlayerTogglableTextdraws( playerid );
	TextDrawHideForPlayer( playerid, g_CurrentRankTD );
	TextDrawHideForPlayer( playerid, g_currentXPTD );
	TextDrawHideForPlayer( playerid, g_DoubleXPTD );
	p_MoneyBag{ playerid } = false;
	RemovePlayerAttachedObject( playerid, 1 );

	// SetPlayerPos( playerid, 	-1971.1536, 129.4870, 27.6875 );
	// SetPlayerFacingAngle( playerid,	90.0 );
	SetPlayerPos( playerid, 229.613998, 87.164001, 1605.039978 );
	SetPlayerFacingAngle( playerid, -90.000000 );
	SetPlayerInterior( playerid, 0 );
	SetPlayerVirtualWorld( playerid, 0 );
	//SetPlayerCameraPos(		playerid, 	-1974.1431, 133.3700, 29.7107 );
	//SetPlayerCameraLookAt(	playerid, 	-1970.6431, 129.3700, 28.2107 );

	if ( p_ClassSelection{ playerid } == false )
	{
		static const Float: START_POS[ 3 ] = { 243.5, 87.23, 1605.9 };
		static const Float: FINAL_POS[ 3 ] = { 231.9, 87.23, 1605.9 };

		InterpolateCameraPos( playerid, START_POS[ 0 ], START_POS[ 1 ], START_POS[ 2 ], FINAL_POS[ 0 ], FINAL_POS[ 1 ], FINAL_POS[ 2 ], 17500, CAMERA_MOVE );
		InterpolateCameraLookAt( playerid, FINAL_POS[ 0 ], FINAL_POS[ 1 ], FINAL_POS[ 2 ], FINAL_POS[ 0 ] - 0.4, FINAL_POS[ 1 ], FINAL_POS[ 2 ] - 0.05, 15000, CAMERA_MOVE );

		// InterpolateCameraPos( playerid, -1976.4252, 119.9899, 30.0, -1974.0302, 133.0427, 27.6940, 10000, CAMERA_MOVE );
		// InterpolateCameraLookAt( playerid, -1974.0302,133.0427,27.6940, -1971.1536,129.4870,27.6875, 10000, CAMERA_MOVE );

		p_ClassSelection{ playerid } = true;
	}

	SetPlayerAttachedObject( playerid, 1, 19560, 6, 0.084999, 0.060998, -0.164999, 3.8, 81.6001, -19.3, .materialcolor1 = 0xFF000000 );
	Streamer_Update( playerid, STREAMER_TYPE_OBJECT );

	// ApplyAnimation( playerid, "MISC", "SEAT_TALK_02", 2.0, 1, 0, 0, 0, 0 );
	if ( GetPlayerSpecialAction( playerid ) != SPECIAL_ACTION_CARRY ) {
		TogglePlayerControllable( playerid, 0 );
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_CARRY );
	}

	p_Spawned				{ playerid } = false;
	p_InfectedHIV			{ playerid } = false;

	if ( CLASS_CIVILIAN_RANGE[ 0 ] <= classid <= CLASS_CIVILIAN_RANGE[ 1 ] )
    {
		p_Class[ playerid ] = ( CLASS_CIVILIAN );
		//SetPlayerTeam( playerid, NO_TEAM );
		SetPlayerColorToTeam( playerid );
		p_inFBI{ playerid } = false;
		p_inArmy{ playerid } = false;
		p_inCIA{ playerid } = false;
		ShowPlayerClassTextdraw( playerid, 0 );
    }
	else if ( CLASS_POLICE_RANGE[ 0 ] <= classid <= CLASS_POLICE_RANGE[ 1 ] )
    {
		p_Class[ playerid ] = ( CLASS_POLICE );
		SetPlayerColor( playerid, COLOR_POLICE );
		//SetPlayerTeam( playerid, CLASS_POLICE );
		p_inFBI{ playerid } = false;
		p_inArmy{ playerid } = false;
		p_inCIA{ playerid } = false;

		ShowPlayerClassTextdraw( playerid, 1 );
    }
    else if ( CLASS_FBI_RANGE[ 0 ] <= classid <=  CLASS_FBI_RANGE[ 1 ] )
    {
		p_Class[ playerid ] = ( CLASS_POLICE );
		//SetPlayerTeam( playerid, CLASS_POLICE );
		SetPlayerColor( playerid, COLOR_FBI );
		p_inFBI{ playerid } = true;
		p_inArmy{ playerid } = false;
		p_inCIA{ playerid } = false;
		ShowPlayerClassTextdraw( playerid, 2 );
    }
    else if ( classid == CLASS_ARMY_RANGE )
    {
		p_Class[ playerid ] = ( CLASS_POLICE );
		SetPlayerColor( playerid, COLOR_ARMY );
		//SetPlayerTeam( playerid, CLASS_POLICE );
		p_inFBI{ playerid } = true;
		p_inArmy{ playerid } = true;
		p_inCIA{ playerid } = true;
		ShowPlayerClassTextdraw( playerid, 3 );
    }
    else if ( CLASS_CIA_RANGE[ 0 ] <= classid <= CLASS_CIA_RANGE[ 1 ] )
    {
		p_Class[ playerid ] = ( CLASS_POLICE );
		SetPlayerColor( playerid, COLOR_CIA );
		//SetPlayerTeam( playerid, CLASS_POLICE );
		p_inFBI{ playerid } = true;
		p_inArmy{ playerid } = false;
		p_inCIA{ playerid } = true;
		ShowPlayerClassTextdraw( playerid, 4 );
    }
    else if ( CLASS_FIRE_RANGE[ 0 ] <= classid <= CLASS_FIRE_RANGE[ 1 ] )
	{
		p_Class[ playerid ] = ( CLASS_FIREMAN );
		SetPlayerColor( playerid, COLOR_FIREMAN );
		//SetPlayerTeam( playerid, NO_TEAM );
		p_inFBI{ playerid } = false;
		p_inArmy{ playerid } = false;
		p_inCIA{ playerid } = false;
		ShowPlayerClassTextdraw( playerid, 6 );
	}
    else if ( CLASS_MEDIC_RANGE[ 0 ] <= classid <= CLASS_MEDIC_RANGE[ 1 ] )
	{
		p_Class[ playerid ] = ( CLASS_MEDIC );
		SetPlayerColor( playerid, COLOR_MEDIC );
		//SetPlayerTeam( playerid, NO_TEAM );
		p_inFBI{ playerid } = false;
		p_inArmy{ playerid } = false;
		p_inCIA{ playerid } = false;
		ShowPlayerClassTextdraw( playerid, 5 );
	}
	return 1;
}

stock ShowPlayerClassTextdraw( playerid, classid ) {
	for ( new i = 0; i < sizeof( CLASS_COLORS ); i ++ ) if ( i != classid ) {
		TextDrawHideForPlayer( playerid, g_classTextdrawBox[ i ] );
		TextDrawHideForPlayer( playerid, g_classTextdrawDescription[ i ] );
		TextDrawHideForPlayer( playerid, g_classTextdrawName[ i ] );
	}

	TextDrawShowForPlayer( playerid, g_classTextdrawBox[ classid ] );
	TextDrawShowForPlayer( playerid, g_classTextdrawDescription[ classid ] );
	TextDrawShowForPlayer( playerid, g_classTextdrawName[ classid ] );
}

public OnPlayerFloodControl( playerid, iCount, iTimeSpan ) {
	static
		szIP[ 16 ];

    GetPlayerIp( playerid, szIP, sizeof( szIP ) );

    if ( iCount > 2 && iTimeSpan < 10000 ) {
    	if ( !IsPlayerNpcEx( playerid ) ) {
        	BanEx( playerid, "BOT-SPAM" );
    	}
    }
}

thread OnPlayerRegisterCheck( playerid )
{
	if ( GetPVarInt( playerid, "banned_connection" ) == 1 ) return 1; // Stop anything from happening.

	new
	    rows, fields
	;
    cache_get_data( rows, fields );
	if ( rows )
    {
        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ) );
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{FFFFFF}Account - Authentication", szBigString, "Login", "Leave");
    }
    else
    {
		format( szNormalString, sizeof( szNormalString ), "SELECT `IP` FROM `USERS` WHERE `IP` = '%s' LIMIT 5", mysql_escape( ReturnPlayerIP( playerid ) ) );
 		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerDuplicateAccountCheck", "i", playerid );
    }
	return 1;
}

thread OnPlayerDuplicateAccountCheck( playerid )
{
	new
		rows, fields;

	cache_get_data( rows, fields );
	if ( rows > 3 )
	{
		SendError( playerid, "Sorry, this IP has more than 3 users registered to it which is the maximum limit of users per IP." );
		KickPlayerTimed( playerid );
	}
	else
	{
        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_RED"%s"COL_WHITE") is not registered.\nPlease enter your desired password for this account.\n\n"COL_GREY"Once you are registered, do not share your password with anyone besides yourself!", ReturnPlayerName( playerid ) );
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Account - Register", szBigString, "Register", "Leave");
	}
	return 1;
}

public OnNpcConnect( npcid )
{
	return Kick( npcid ), 1;
}

public OnPlayerConnect( playerid )
{
    static
        Query[ 200 ];

	if ( strmatch( ReturnPlayerName( playerid ), "No-one" ) )
		return Kick( playerid ), 1;

	if ( textContainsIP( ReturnPlayerName( playerid ) ) )
	    return Kick( playerid ), 1;

	// Ultra fast queries...
	format( Query, sizeof( Query ), "SELECT * FROM `BANS` WHERE (`NAME`='%s' OR `IP`='%s') AND `SERVER`=0 LIMIT 0,1", mysql_escape( ReturnPlayerName( playerid ) ), mysql_escape( ReturnPlayerIP( playerid ) ) );
	mysql_function_query( dbHandle, Query, true, "OnPlayerBanCheck", "i", playerid );

	TogglePlayerClock( playerid, 1 );
    ClearPlayerWantedLevel( playerid );
	SetPlayerColor( playerid, COLOR_GREY );
	ResetPlayerCash( playerid );

	// Create player textdraws and remove buildings
	removeExcessiveBuildings( playerid );

	// Create casino label
	DestroyDynamic3DTextLabel( p_RewardsLabel_Caligs[ playerid ] );
	DestroyDynamic3DTextLabel( p_RewardsLabel_4Drags[ playerid ] );
	DestroyDynamic3DTextLabel( p_RewardsLabel_Visage[ playerid ] );
	p_RewardsLabel_Caligs[ playerid ] = CreateDynamic3DTextLabel( "[CASINO REWARDS]", COLOR_GOLD, 2157.6294, 1599.4355, 1006.1797, 20.0, .playerid = playerid );
	p_RewardsLabel_4Drags[ playerid ] = CreateDynamic3DTextLabel( "[CASINO REWARDS]", COLOR_GOLD, 1951.7191, 997.55550, 992.85940, 20.0, .playerid = playerid );
	p_RewardsLabel_Visage[ playerid ] = CreateDynamic3DTextLabel( "[CASINO REWARDS]", COLOR_GOLD, 2604.1323, 1570.1182, 1508.3530, 20.0, .playerid = playerid );

	// Create highroller objects
	p_HighrollersBarrier[ playerid ] [ 0 ] = CreateDynamicObject( 19545, 2592.604980, 1610.016967, 1499.139038, 90.000000, 90.000000, 0.000000, .worldid = VISAGE_WORLD, .playerid = playerid );
	p_HighrollersBarrier[ playerid ] [ 1 ] = CreateDynamicObject( 19545, 2592.604003, 1595.026000, 1499.140991, 90.000000, 90.000000, 0.000000, .worldid = VISAGE_WORLD, .playerid = playerid );
	SetDynamicObjectMaterial( p_HighrollersBarrier[ playerid ] [ 0 ], 0, 11751, "enexmarkers", "enex", -9170 );
	SetDynamicObjectMaterial( p_HighrollersBarrier[ playerid ] [ 1 ], 0, 11751, "enexmarkers", "enex", -9170 );

	// Reset some variables
	p_Spawned 			{ playerid } = false;
    p_GangID 			[ playerid ] = INVALID_GANG_ID;
	justConnected		{ playerid } = true;
	p_ClassSelection	{ playerid } = false;
	p_FPS_DrunkLevel	[ playerid ] = 0;
	p_FPS 				[ playerid ] = 0;
	p_UsingRobberySafe	[ playerid ] = -1;

	// reset jails
	jailDoors( playerid, false, false );

	SendClientMessage( playerid, 0xa9c4e4ff, "{FF0000}[WARNING]{a9c4e4} The concept in this server and GTA in general may be considered explicit material." );
	SendClientMessage( playerid, 0xa9c4e4ff, "{FF0000}[INFO]{a9c4e4} The server is currently operating on version " # FILE_BUILD "." );

	if ( GetGVarType( "connectsong" ) != GLOBAL_VARTYPE_NONE )
	{
		GetGVarString( "connectsong", szNormalString );
		PlayAudioStreamForPlayer( playerid, szNormalString );
	}

	//PreloadAnimationLibrary( playerid, "MISC" );
	return 1;
}

public OnLookupComplete( playerid, success )
{
	/*if ( IsProxyUser( playerid ) )
	{
		if ( IsProxiesBanned( ) )
		{
			for( new i = 0; i < sizeof( g_ispUnbans ); i++ )
			{
				if ( strfind( GetPlayerISP( playerid ), g_ispUnbans[ i ] ) == -1 )
				{
					return KickPlayer( playerid );
					//return BanEx( playerid, "Proxy Detected!" );
				}
			}
		}
	}

	format( szLargeString, sizeof( szLargeString ), "SELECT * FROM `MEGABAN` WHERE `ISP`='%s' LIMIT 0,1", mysql_escape( GetPlayerISP( playerid ) ) );
	mysql_function_query( dbHandle, szLargeString, true, "OnPlayerMegaBanCheck", "i", playerid );*/

	SendDeathMessage( INVALID_PLAYER_ID, playerid, 200 );

	if ( IsProxyEnabledForPlayer( playerid ) ) {
		format( szNormalString, sizeof( szNormalString ), "%s(%d) has connected to the server! (%s)", ReturnPlayerName( playerid ), playerid, GetPlayerCountryName( playerid ) );
	} else {
		format( szNormalString, sizeof( szNormalString ), "%s(%d) has connected to the server!", ReturnPlayerName( playerid ), playerid );
	}

	foreach ( new i : Player ) if ( IsPlayerSettingToggled( i, SETTING_CONNECTION_LOG ) ) {
		SendClientMessage( i, COLOR_CONNECT, szNormalString );
	}

	format( szNormalString, sizeof( szNormalString ), "*%s*", szNormalString );
	DCC_SendChannelMessage( discordGeneralChan, szNormalString );
	return 1;
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
			//bannedSerial[ 41 ],
			bannedExpire = 0,
			server = 1,
			serial = 0
		;

		server  	 = cache_get_field_content_int( 0, "SERVER", dbHandle );
		bannedExpire = cache_get_field_content_int( 0, "EXPIRE", dbHandle );

		cache_get_field_content( 0, "BANBY", bannedbyUser );
		cache_get_field_content( 0, "REASON", bannedReason );
		//cache_get_field_content( 0, "SERIAL", bannedSerial );
		cache_get_field_content( 0, "NAME", bannedUser );
		cache_get_field_content( 0, "IP", bannedIP );

		/*gpci( playerid, szNormalString, 41 );
		if ( strmatch( bannedSerial, szNormalString ) )
		{
			serial = 1;
			format( szBigString, sizeof( szBigString ), "[%s %s] %s => {%s, %s, %s, %s, %s}\n\r", getCurrentDate( ), getCurrentTime( ), ReturnPlayerName( playerid ), bannedbyUser, bannedReason, bannedSerial, bannedUser, bannedIP );
			AddFileLogLine( "gpcid.txt", szBigString );
		}*/

		// CNR BANS ONLY
		if ( !server )
		{
			if ( !bannedExpire )
			{
				// "COL_ORANGE"Ban evading will be fatal to your account. Do not do it.
				format( szLargeString, 600, "{FFFFFF}You are banned from this server.\n{FFFFFF}If you feel wrongfully banned, please appeal at "COL_BLUE""#SERVER_WEBSITE"{FFFFFF}\n\n"COL_RED"Username:{FFFFFF} %s\n"COL_RED"IP Address:{FFFFFF} %s\n", bannedUser, bannedIP );
				format( szLargeString, 600, "%s"COL_RED"Reason:{FFFFFF} %s\n"COL_RED"Server:{FFFFFF} %s\n"COL_RED"Banned by:{FFFFFF} %s%s", szLargeString, bannedReason, GetServerName( server ), bannedbyUser, strmatch( ReturnPlayerName( playerid ), bannedUser ) ? ("") : ( serial ? ("\n\n"COL_RED"Our ban evasion system picked you up! If this is in error then please visit our forums.") : ("\n\n"COL_RED"Your IP Address is banned, if this is a problem then visit our forums.") ) );
		      	ShowPlayerDialog( playerid, DIALOG_BANNED, DIALOG_STYLE_MSGBOX, "{FFFFFF}Ban Information", szLargeString, "Okay", "" );
		      	KickPlayerTimed( playerid );
		  		return 1;
			}
			else
			{
				if ( g_iTime > bannedExpire )
				{
					format( szNormalString, 100, "DELETE FROM `BANS` WHERE `NAME`= '%s' OR `IP` = '%s'", mysql_escape( ReturnPlayerName( playerid ) ), mysql_escape( ReturnPlayerIP( playerid ) ) ), mysql_single_query( szNormalString );
					SendServerMessage( playerid, "The suspension of this account has expired as of now, this account is available for playing." );
				}
				else
				{
					// "COL_ORANGE"Ban evading will be fatal to your account. Do not do it.
					format( szLargeString, 700, "{FFFFFF}You are suspended from this server.\n{FFFFFF}If you feel wrongfully suspended, please appeal at "COL_BLUE""#SERVER_WEBSITE"{FFFFFF}\n\n"COL_RED"Username:{FFFFFF} %s\n"COL_RED"IP Address:{FFFFFF} %s\n", bannedUser, bannedIP );
					format( szLargeString, 700, "%s"COL_RED"Reason:{FFFFFF} %s\n"COL_RED"Server:{FFFFFF} %s\n"COL_RED"Suspended by:{FFFFFF} %s\n"COL_RED"Expire Time:{FFFFFF} %s%s", szLargeString, bannedReason, GetServerName( server ), bannedbyUser, secondstotime( bannedExpire - g_iTime ), strmatch( ReturnPlayerName( playerid ), bannedUser ) ? (" ") : ("\n\n"COL_RED"Your IP Address is suspended, if this is a problem, visit our forums.") );
			      	ShowPlayerDialog( playerid, DIALOG_BANNED, DIALOG_STYLE_MSGBOX, "{FFFFFF}Suspension Information", szLargeString, "Okay", "" );
		      		KickPlayerTimed( playerid );
			  		return 1;
			  	}
			}
		}
		else SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s(%d) has been identified as banned under %s.", ReturnPlayerName( playerid ), playerid, bannedbyUser );
	}

	// Pursue a registration check
	format( szNormalString, sizeof( szNormalString ), "SELECT `NAME` FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( ReturnPlayerName( playerid ) ) );
 	mysql_function_query( dbHandle, szNormalString, true, "OnPlayerRegisterCheck", "i", playerid );
	return 1;
}

/*thread OnPlayerMegaBanCheck( playerid )
{
	new
		rows, fields;

    cache_get_data( rows, fields );
	if ( rows )
	{
		new
			playerserial[ 45 ];

		gpci( playerid, playerserial, sizeof( playerserial ) );
	 	if ( g_Debugging ) {
	 		SendClientMessageToRCON( COLOR_YELLOW, "MEGABAN: %s blocked! GPCI: %s | ISP: %s", ReturnPlayerName( playerid ), playerserial, GetPlayerISP( playerid ) );
	 		printf("[DEBUG] [MEGABAN] %s blocked! GPCI: %s | ISP: %s", ReturnPlayerName( playerid ), playerserial, GetPlayerISP( playerid ) );
	 	}

		// IP Blocked
		//BlockIpAddress( ReturnPlayerIP( playerid ), 0 );
		//BanEx( playerid, "MEGABAN" );
		SendServerMessage( playerid, "You are banned from this server. (0xAF)" );
		KickPlayer( playerid );
	}
	else
	{
		if ( strmatch( GetPlayerISP( playerid ), "AS812 Rogers Cable Communications Inc." ) || strmatch( GetPlayerISP( playerid ), "AS6799 OTEnet S.A." ) )
			return 1;

		SendDeathMessage( INVALID_PLAYER_ID, playerid, 200 );

		if ( IsProxyEnabledForPlayer( playerid ) ) {
			format( szNormalString, sizeof( szNormalString ), "%s(%d) has connected to the server! (%s)", ReturnPlayerName( playerid ), playerid, GetPlayerCountryName( playerid ) );
		} else {
			format( szNormalString, sizeof( szNormalString ), "%s(%d) has connected to the server!", ReturnPlayerName( playerid ), playerid );
		}

		foreach(new i : Player)
		{
			if ( p_PlayerSettings[ i ] { SETTING_CONNECTION_LOG } )
				SendClientMessage( i, COLOR_CONNECT, szNormalString );
		}

		format( szNormalString, sizeof( szNormalString ), "*%s*", szNormalString );
		DCC_SendChannelMessage( discordGeneralChan, szNormalString );
	}
	return 1;
}*/
public OnNpcDisconnect( npcid, reason )
{
	return 1;
}

public OnPlayerDisconnect( playerid, reason )
{
	static
		string[ 64 ], color;

	// Reset player variables
    SavePlayerData( playerid, true );
	DisconnectFromGang( playerid );
	dischargeVehicles( playerid );
	CutSpectation( playerid );
	LeavePlayerPaintball( playerid );
    RemovePlayerFromRace( playerid );
	ResetPlayerPassiveMode( playerid );
	//p_Detained		{ playerid } = false;
	p_Tied			{ playerid } = false;
	p_Kidnapped		{ playerid } = false;
	p_Wood          [ playerid ] = 0;
	p_inAlcatraz 	{ playerid } = false;
	p_FPSCounter 	{ playerid } = false;
	p_Ropes			[ playerid ] = 0;
	p_Scissors      [ playerid ] = 0;
	p_Fires         [ playerid ] = 0;
	p_PingImmunity  { playerid } = 0;
	p_Robberies     [ playerid ] = 0;
	p_HitsComplete  [ playerid ] = 0;
	//p_CopTutorial   { playerid } = 0;
	p_Class			[ playerid ] = 0;
	p_drillStrength [ playerid ] = 0;
	p_RansomAmount	[ playerid ] = 0;
	p_RansomPlacer	[ playerid ] = INVALID_PLAYER_ID;
	p_LabelColor 	[ playerid ] = COLOR_GREY;
	p_Uptime        [ playerid ] = 0;
	p_Muted 		{ playerid } = false;
	p_AdminLog		{ playerid } = false;
	p_AdminLevel	[ playerid ] = 0;
 	p_Warns			[ playerid ] = 0;
	p_CopBanned		{ playerid } = 0;
	p_SpawningCity 	{ playerid } = CITY_SF;
	p_ArmyBanned    { playerid } = 0;
    p_PlayerLogged	{ playerid } = false;
    p_JobSet		{ playerid } = false;
    // p_CitySet 		{ playerid } = false;
	p_MoneyBag		{ playerid } = false;
    p_inPaintBall	{ playerid } = false;
	p_LeftPaintball { playerid } = false;
    p_Job			{ playerid } = 0;
    p_VIPJob 		{ playerid } = 0;
    p_CantUseReport { playerid } = false;
    p_BobbyPins     [ playerid ] = 0;
	p_Spawned		{ playerid } = false;
	p_AdminOnDuty   { playerid } = false;
	p_WantedLevel	[ playerid ] = 0;
	p_Tazed			{ playerid } = false;
	p_Jailed		{ playerid } = false;
	p_AntiEMP       [ playerid ] = 0;
	p_LastVehicle	[ playerid ] = INVALID_VEHICLE_ID;
	p_Cuffed		{ playerid } = false;
	justConnected	{ playerid } = true;
 	p_Muted			{ playerid } = false;
	p_MetalMelter	[ playerid ] = 0;
	p_LeftCuffed 	{ playerid } = false;
	p_BailOfferer   [ playerid ] = INVALID_PLAYER_ID;
	p_PmResponder	[ playerid ] = INVALID_PLAYER_ID;
	p_ViewingStats  [ playerid ] = INVALID_PLAYER_ID;
	p_HealDealer    [ playerid ] = INVALID_PLAYER_ID;
	p_Spectating    { playerid } = false;
	p_TicketIssuer	[ playerid ] = INVALID_PLAYER_ID;
	//p_DetainedBy	[ playerid ] = INVALID_PLAYER_ID;
    p_GangID		[ playerid ] = INVALID_GANG_ID;
	p_InfectedHIV	{ playerid } = false;
	p_OwnedHouses	[ playerid ] = 0;
	p_OwnedVehicles [ playerid ] = 0;
	p_ToggledViewPM	{ playerid } = false;
	p_VIPExpiretime [ playerid ] = 0;
 	p_BankMoney		[ playerid ] = 0;
 	p_Kills			[ playerid ] = 0;
	p_Deaths		[ playerid ] = 0;
 	p_VIPLevel		[ playerid ] = 0;
//	p_XP			[ playerid ] = 0;
	p_InHouse		[ playerid ] = -1;
	p_InGarage 		[ playerid ] = -1;
	p_inMovieMode	{ playerid } = false;
	p_CantUseAsk    { playerid } = false;
	p_LastSkin      [ playerid ] = 0;
	p_SecureWallet	{ playerid } = false;
	p_WeedGrams		[ playerid ] = 0;
	p_Arrests		[ playerid ] = 0;
	p_AidsVaccine	{ playerid } = false;
	p_VIPWep1		{ playerid } = 0;
	p_VIPWep2		{ playerid } = 0;
	p_VIPWep3		{ playerid } = 0;
	p_WeaponDealing	{ playerid } = false;
	p_WeaponDealer	[ playerid ] = INVALID_PLAYER_ID;
	p_WeedDealer	[ playerid ] = INVALID_PLAYER_ID;
	p_JailTime		[ playerid ] = 0;
	p_Muted			{ playerid } = false;
	p_Burglaries	[ playerid ] = 0;
	p_MuriaticAcid	{ playerid } = 0;
	p_CausticSoda	{ playerid } = 0;
	p_MethYielded 	[ playerid ] = 0;
	p_CarsJacked 	[ playerid ] = 0;
	p_BankBlown		[ playerid ] = 0;
	p_JailsBlown	[ playerid ] = 0;
	p_AccountID		[ playerid ] = 0;
	p_DeathMessage	[ playerid ] [ 0 ] = '\0';
	p_Fireworks 	[ playerid ] = 0;
	p_AddedEmail 	{ playerid } = false;
	p_TicketTimestamp[ playerid ] = 0;
	p_ExtraAssetSlots{ playerid } = 0;
	p_CasinoRewardsPoints[ playerid ] = 0.0;
	p_OwnedBusinesses[ playerid ] = 0;
	p_ExplosiveBullets[ playerid ] = 0;
	p_GangSplitProfits[ playerid ] = 0;
	p_IrresistibleCoins[ playerid ] = 0.0;
	p_QuitToAvoidTimestamp[ playerid ] = 0;
	p_AntiExportCarSpam[ playerid ] = 0;
	p_TruckedCargo[ playerid ] = 0;
	p_PilotMissions[ playerid ] = 0;
	p_TrainMissions[ playerid ] = 0;
	p_HydrogenChloride{ playerid } = 0;
	p_Methamphetamine{ playerid } = 0;
	p_IsCasinoHighRoller{ playerid } = false;
	p_PawnStoreExport[ playerid ] = 0xFFFF;
	p_LastEnteredEntrance[ playerid ] = -1;
	p_ViewingGangTalk[ playerid ] = -1;
	p_forcedAnticheat[ playerid ] = 0;
	p_PlayerAltBind[ playerid ] = -1;
	p_RconLoginFails{ playerid } = 0;
	p_SpawningKey[ playerid ] [ 0 ] = '\0';
	p_SpawningIndex[ playerid ] = 0;
	p_IncorrectLogins{ playerid } = 0;
	p_VehicleBringCooldown[ playerid ] = 0;
	p_DamageSpamCount{ playerid } = 0;
	p_AntiTextSpamCount{ playerid } = 0;
	Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
	p_SpawnKillLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
    Delete3DTextLabel( p_AdminLabel[ playerid ] );
    p_AdminLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	//Delete3DTextLabel( p_DetainedLabel[ playerid ] );
	//p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	Delete3DTextLabel( p_TiedLabel[ playerid ] );
	p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	DestroyDynamic3DTextLabel( p_WeedLabel[ playerid ] );
	p_WeedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_AntiSpawnKillEnabled{ playerid } = false;
	//p_CopTutorialProgress{ playerid } = 0;
	DestroyDynamicRaceCP( p_MiningExport[ playerid ] );
	p_MiningExport[ playerid ] = 0xFFFF;
	p_ContractedAmount[ playerid ] = 0;
	ClearPlayerWantedLevel( playerid );
	Delete3DTextLabel( p_InfoLabel[ playerid ] );
	p_InfoLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_LabelColor[ playerid ] = COLOR_GREY;
    unpause_Player( playerid );
    DestroyAllPlayerC4s( playerid, true );
	KillTimer( p_JailTimer[ playerid ] );
	KillTimer( p_CuffAbuseTimer[ playerid ] );
	ResetPlayerCash( playerid );
	if ( !GetPVarInt( playerid, "banned_connection" ) ) SendDeathMessage( INVALID_PLAYER_ID, playerid, 201 );
	DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
	p_PawnStoreMapIcon[ playerid ] = 0xFFFF;
	jailDoors( playerid, .remove = true, .set_closed = false );
	DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 0 ] ), p_HighrollersBarrier[ playerid ] [ 0 ] = -1;
	DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 1 ] ), p_HighrollersBarrier[ playerid ] [ 1 ] = -1;

	switch( reason )
	{
	    case 0: color = COLOR_TIMEOUT, 		format( string, sizeof( string ), "%s(%d) has timed out from the server!", ReturnPlayerName( playerid ), playerid );
	    case 1: color = COLOR_DISCONNECT, 	format( string, sizeof( string ), "%s(%d) has left the server!", ReturnPlayerName( playerid ), playerid );
	    case 2: color = COLOR_KICK, 		format( string, sizeof( string ), "%s(%d) has been kicked from the server!", ReturnPlayerName( playerid ), playerid );
	}


	for( new i; i < MAX_PLAYERS; i++ )
	{
		if ( IsPlayerConnected( i ) && IsPlayerSettingToggled( i, SETTING_CONNECTION_LOG ) )
		{
			SendClientMessage( i, color, string ); // Send a message to people
		}

		if ( i < MAX_GANGS ) 	p_gangInvited[ playerid ] [ i ] = false;
		if ( i < MAX_RACES )	p_raceInvited[ playerid ] [ i ] = false;

		p_BlockedPM[ playerid ] [ i ] = false;
	}

	format( string, sizeof( string ), "*%s*", string );
	DCC_SendChannelMessage( discordGeneralChan, string );
	return 1;
}

public OnPlayerSpawn( playerid )
{
	new
		iTick = GetTickCount( );

	UpdatePlayerTime( playerid );
	DeletePVar( playerid, "attached_mugshot" );

	PlayerPlaySound( playerid, 0, 0.0, 0.0, 0.0 );
	PlayerTextDrawHide( playerid, p_ExperienceTD[ playerid ] );
	HidePlayerTogglableTextdraws( playerid );
	TextDrawHideForPlayer( playerid, g_CurrentRankTD );
	TextDrawHideForPlayer( playerid, g_currentXPTD );

	if ( p_inMovieMode{ playerid } == false )
	{
		ShowPlayerTogglableTextdraws( playerid );
		ShowPlayerIrresistibleRank( playerid );
		TextDrawShowForPlayer( playerid, g_CurrentRankTD );
		TextDrawShowForPlayer( playerid, g_currentXPTD );
		PlayerTextDrawShow( playerid, p_LocationTD[ playerid ] );
		PlayerTextDrawShow( playerid, p_ExperienceTD[ playerid ] );
		TextDrawShowForPlayer( playerid, g_WebsiteTD );
		TextDrawShowForPlayer( playerid, g_MotdTD );
		PlayerTextDrawShow( playerid, g_ZoneOwnerTD[ playerid ] );
		if ( g_HappyHour ) TextDrawShowForPlayer( playerid, g_NotManyPlayersTD );
		TextDrawShowForPlayer( playerid, g_WorldDayTD );
		if ( p_AdminOnDuty{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminOnDutyTD );
		if ( p_AdminLog{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminLogTD );
		if ( p_FPSCounter{ playerid } ) TextDrawShowForPlayer( playerid, p_FPSCounterTD[ playerid ] );
		if ( IsDoubleXP( ) ) TextDrawShowForPlayer( playerid, g_DoubleXPTD );
	}

	p_Spawned{ playerid } = true;
	p_InfectedHIV{ playerid } = false;
	p_Kidnapped{ playerid } = false;
	p_ClassSelection{ playerid } = false;
	p_LastEnteredEntrance[ playerid ] = -1;
   	p_Tied{ playerid } = false;
	p_InHouse[ playerid ] = -1;
	p_InGarage[ playerid ] = -1;
	StopSound( playerid );
	CancelEdit( playerid );

	// Approved spawn?
	if ( !approveClassSpawned( playerid ) ) {
		SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL SPAWN]"COL_GREY" %s(%d) - %d skin - %d ping - %s IP", ReturnPlayerName( playerid ), playerid, GetPlayerSkin( playerid ), GetPlayerPing( playerid ), ReturnPlayerIP( playerid ) );
	    return KickPlayerTimed( playerid ), 1;
	}

	// Money Bags
	if ( p_MoneyBag{ playerid } && p_Class[ playerid ] != CLASS_POLICE ) // SetPlayerAttachedObject( playerid, 1, 1550, 1, 0.131999, -0.140999, 0.053999, 11.299997, 65.599906, 173.900054, 0.652000, 0.573000, 0.594000 );
		RemovePlayerAttachedObject( playerid, 1 ), SetPlayerAttachedObject( playerid, 1, 1210, 7, 0.302650, -0.002469, -0.193321, 296.124053, 270.396881, 8.941717, 1.000000, 1.000000, 1.000000 );

	// Gang Zones
	foreach( new zoneid : turfs )
	{
    	// resume flashing if gang war
    	if ( g_gangzoneAttacker[ zoneid ] != INVALID_GANG_ID && Iter_Contains( gangs, g_gangzoneAttacker[ zoneid ] ) ) {
    		GangZoneFlashForPlayer( playerid, g_gangTurfData[ zoneid ] [ E_ID ], setAlpha( g_gangData[ g_gangzoneAttacker[ zoneid ] ] [ E_COLOR ], 0x80 ) );
    	} else {
	        GangZoneShowForPlayer( playerid, g_gangTurfData[ zoneid ] [ E_ID ], g_gangTurfData[ zoneid ] [ E_COLOR ] );
    	}
	}

	// VIP Skin
	if ( IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) && p_VIPLevel[ playerid ] )
		SetPlayerSkin( playerid, p_LastSkin[ playerid ] );

	if ( justConnected{ playerid } == true )
	{
	    justConnected{ playerid } = false;
	    StopAudioStreamForPlayer( playerid );

	    // Callback
	    CallLocalFunction( "OnPlayerFirstSpawn", "d", playerid );

		// Jail people that left jailed
	    if ( p_JailTime[ playerid ] ) // We load this when the player logs in.
	    {
	    	JailPlayer( playerid, p_JailTime[ playerid ], p_AdminJailed{ playerid } );
        	SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been sent to jail "COL_LRED"[Left as a jailed person]", ReturnPlayerName( playerid ), playerid );
        	return 1;
	    }

	    // Jail quit to avoiders
	    if ( p_LeftCuffed{ playerid } )
	    {
	    	new
	    		szServing = 100 + GetPlayerScore( playerid );

	    	if ( szServing > 1000 ) szServing = 1000;

	    	p_LeftCuffed{ playerid } = false;
	    	JailPlayer( playerid, szServing, 1 );
        	SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been sent to jail for %d seconds by the server "COL_LRED"[Quit To Avoid]", ReturnPlayerName( playerid ), playerid, szServing );
        	return 1;
	    }

	    // Show wanted level
	    if ( p_WantedLevel[ playerid ] )
	    {
			format( szSmallString, sizeof( szSmallString ), "] %d ]", p_WantedLevel[ playerid ] );
			PlayerTextDrawSetString( playerid, p_WantedLevelTD[ playerid ], szSmallString );
			PlayerTextDrawShow( playerid, p_WantedLevelTD[ playerid ] );
	    }

	    // Show welcome messsage
	   	ShowPlayerHelpDialog( playerid, 10000, "Welcome %s!~n~~n~If you have any questions, ~g~/ask!~w~~h~~n~~n~If you see anyone being unfair, report them with ~r~/report!~w~~n~~n~Have fun playing and don't forget to invite your friends! :)", ReturnPlayerName( playerid ) );
	}
	else
	{
		// Reset wanted level when a player spawns
		if ( p_LastPlayerState{ playerid } != PLAYER_STATE_SPECTATING )
			ClearPlayerWantedLevel( playerid );
	}

	if ( p_Jailed{ playerid } ) // Because some people can still exit the jail and play...
		return SetPlayerHealth( playerid, INVALID_PLAYER_ID ), SetPlayerPosToPrison( playerid );

	if ( IsPlayerInPaintBall( playerid ) )
	{
	    if ( p_Class[ playerid ] != CLASS_CIVILIAN )
	    {
			SendError( playerid, "You must be a civilian to join paintball." );
			LeavePlayerPaintball( playerid );
		    SpawnPlayer( playerid );
			return 1;
		}

		SpawnToPaintball( playerid, p_PaintBallArena{ playerid } );
		return 1;
	}

	/* ** Anti-Spawn Kill ** */
	DisableRemoteVehicleCollisions( playerid, p_AdminOnDuty{ playerid } );
	SetPlayerHealth( playerid, INVALID_PLAYER_ID );
	Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
	p_SpawnKillLabel[ playerid ] = Create3DTextLabel( "Spawn Protected!", COLOR_GOLD, 0.0, 0.0, 0.0, 15.0, 0 );
	p_AntiSpawnKill[ playerid ] = g_iTime + 15;
    Attach3DTextLabelToPlayer( p_SpawnKillLabel[ playerid ], playerid, 0.0, 0.0, 0.3 );
    p_AntiSpawnKillEnabled{ playerid } = true;
	/* ** Anti-Spawn Kill ** */

    // passive mode
	SetPlayerPassiveMode( playerid );

	if ( p_Class[ playerid ] == CLASS_CIVILIAN )
	{
		if ( !p_JobSet{ playerid } )
		{
		    TogglePlayerControllable( playerid, 0 );
			ShowPlayerDialog( playerid, DIALOG_JOB, DIALOG_STYLE_LIST, "{FFFFFF}Job Selection", "Rapist\nKidnapper\nTerrorist\nHitman\nProstitute\nWeapon Dealer\nDrug Dealer\nDirty Mechanic\nBurglar", "Select", "" );
		}
		else
		{
			if ( p_LastPlayerState{ playerid } != PLAYER_STATE_SPECTATING )
			{
			    switch( p_Job{ playerid } )
				{
			        case JOB_RAPIST:
			        {
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_KIDNAPPER:
			        {
			            GivePlayerWeapon( playerid, 29, 220 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_TERRORIST:
			        {
			            GivePlayerWeapon( playerid, 33, 50 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_HITMAN:
			        {
			            GivePlayerWeapon( playerid, 4, 1 );
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 34, 30 );
			        }
			        case JOB_PROSTITUTE:
			        {
			            GivePlayerWeapon( playerid, 10, 1 );
			            GivePlayerWeapon( playerid, 25, 50 );
			            GivePlayerWeapon( playerid, 30, 300 );
			        }
			        case JOB_WEAPON_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 31, 300 );
			        }
			        case JOB_DRUG_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 25, 50 );
			        }
			        case JOB_DIRTY_MECHANIC:
			        {
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 27, 90 );
					}
			        case JOB_BURGLAR:
			        {
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 31, 300 );
					}
			    }
			}
		}
	}

    new
    	bSpectated = ( IsPlayerAdmin( playerid ) && p_LastPlayerState{ playerid } == PLAYER_STATE_SPECTATING );

	if ( !bSpectated )
	{
		switch( p_Class[ playerid ] )
		{
			case CLASS_POLICE: GivePlayerLeoWeapons( playerid );

			case CLASS_FIREMAN:
			{
				GivePlayerWeapon( playerid, 22, 250 );
				GivePlayerWeapon( playerid, 25, 50 );
				GivePlayerWeapon( playerid, 9, 1 );
				GivePlayerWeapon( playerid, 42, 0xFFFF );
			}

			case CLASS_MEDIC:
			{
			    GivePlayerWeapon( playerid, 23, 250 );
			    GivePlayerWeapon( playerid, 25, 50 );
				GivePlayerWeapon( playerid, 41, 200 );
			}
		}
	}

	SetPlayerColorToTeam( playerid );
	SetPlayerVirtualWorld( playerid, 0 );
	CallLocalFunction( "SetPlayerRandomSpawn", "d", playerid );

	if ( p_VIPLevel[ playerid ] >= VIP_REGULAR && p_VIPWep1{ playerid } != 0 ) GivePlayerWeapon( playerid, p_VIPWep1{ playerid }, 200 );
	if ( p_VIPLevel[ playerid ] >= VIP_BRONZE && p_VIPWep2{ playerid } != 0 ) GivePlayerWeapon( playerid, p_VIPWep2{ playerid }, 200 );
	if ( p_VIPLevel[ playerid ] >= VIP_GOLD && p_VIPWep3{ playerid } != 0 ) GivePlayerWeapon( playerid, p_VIPWep3{ playerid }, 200 );

	if ( p_VIPLevel[ playerid ] >= VIP_BRONZE ) SetPlayerArmour( playerid, 100.0 ); // Free armour on spawn.

	SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[SPAWN INFO]"COL_WHITE" It has taken you %d milliseconds to spawn!", ( GetTickCount( ) - iTick ) );
	return 1;
}

public OnPlayerWeaponShot( playerid, weaponid, hittype, hitid, Float: fX, Float: fY, Float: fZ )
{
	if ( p_AdminLevel[ playerid ] < 1 && IsWeaponBanned( weaponid ) ) {
		return 0;
	}

	if ( IsPlayerAFK( playerid ) ) {
		return 0;
	}

	static
		Float: X, Float: Y, Float: Z;

	if ( hittype == BULLET_HIT_TYPE_PLAYER )
	{
		if ( IsPlayerNPC( hitid ) )
			return 1; // fcnpc

		// Cop shoots innocent, they /q - so jail
		if ( p_Class[ playerid ] == CLASS_POLICE && p_WantedLevel[ hitid ] > 2 )
			p_QuitToAvoidTimestamp[ hitid ] = g_iTime + 3;

		if ( p_Class[ playerid ] == CLASS_POLICE && p_Class[ hitid ] != CLASS_POLICE && !p_WantedLevel[ hitid ] && GetPlayerState( hitid ) != PLAYER_STATE_WASTED && ! IsPlayerInEvent( playerid ) )
		 	return ShowPlayerHelpDialog( playerid, 2000, "You cannot hurt innocent civilians, you're a ~b~cop~w~~h~!" ), 0;

		// CIA Exposure when weapon is shot
		if ( p_Class[ playerid ] == CLASS_POLICE && p_inFBI{ playerid } && p_inCIA{ playerid } && !p_inArmy{ playerid } )
			SetPlayerColor( playerid, setAlpha( COLOR_CIA, 0xFF ) ), p_VisibleOnRadar[ playerid ] = g_iTime + 2;

		if ( IsPlayerConnected( hitid ) && p_BulletInvulnerbility[ hitid ] > g_iTime )
		 	return ShowPlayerHelpDialog( playerid, 2000, "This player is immune from bullets!" ), 0;

		if ( IsPlayerAdminOnDuty( playerid ) )
			return 0;

		if ( IsPlayerConnected( hitid ) && ( IsPlayerTazed( hitid ) || IsPlayerCuffed( hitid ) || IsPlayerKidnapped( hitid ) || IsPlayerTied( hitid ) || IsPlayerLoadingObjects( hitid ) || IsPlayerAdminOnDuty( hitid ) || p_AntiSpawnKillEnabled{ hitid } ) )
			return 0;

		if ( p_AntiSpawnKill[ playerid ] > g_iTime && p_AntiSpawnKillEnabled{ playerid } ) {
		 	return DisablePlayerSpawnProtection( playerid ), SendServerMessage( playerid, "Your spawn protection is no longer active!" ), 0;
		}
	}

	else if ( hittype == BULLET_HIT_TYPE_VEHICLE )
	{
		new
			Float: Health,
			iModel = GetVehicleModel( hitid )
		;

		g_VehicleLastAttacker[ hitid ] = playerid;
		g_VehicleLastAttacked[ hitid ] = g_iTime;

		// BMX, Bike, Mountain Bike, Train, Train Cargo, Train Passenger, Tram, Freight Box
		if ( iModel != 481 && iModel != 509 && iModel != 510 && iModel != 537 && iModel != 569 && iModel != 570 && iModel != 538 && iModel != 449 && iModel != 590 )
		{
			GetPlayerPos( playerid, X, Y, Z );
			GetVehicleHealth( hitid, Health );

			new
				Float: Damage = GetWeaponDamageFromDistance( weaponid, GetVehicleDistanceFromPoint( hitid, X, Y, Z ) ),
				iDriver = GetVehicleDriver( hitid )
			;

			if ( iDriver == INVALID_PLAYER_ID )
			{
				if ( weaponid == 38 ) Damage *= 20.0;

				switch( GetVehicleModel( hitid ) )
				{
					case 573: Damage /= 6.0; // Dune
					case 508: Damage /= 4.0; // Journey
					case 498: Damage /= 2.0; // Boxville
					case 432: Damage /= 15.0; // Rhino
					case 433, 427: Damage /= 4.0; // barracks/enforcer
					case 601, 428: Damage /= 5.0; // swat tank, securicar
					case 407, 544, 406: Damage /= 2.0; // firetruck a, firetruck b, dumper
				}

				if ( Health >= 250.0 ) {
					SetVehicleHealth( hitid, Health - Damage );
				}
				else
				{
					if ( GetGVarType( "respawning_veh", hitid ) == GLOBAL_VARTYPE_NONE )
				 		SetGVarInt( "respawning_veh", SetTimerEx( "RespawnaVehicle", 9000, false, "d", hitid ), hitid );
				}
			}
			else
			{
				// Disable team vehicle damage
				if ( p_Class[ iDriver ] == CLASS_POLICE && p_Class[ playerid ] == CLASS_POLICE )
					return 0;

				// Can't damage admin on duty vehicles
				if ( IsPlayerAdminOnDuty( iDriver ) )
					return 0;

				// Anti Random Deathmatch
				if ( IsRandomDeathmatch( playerid, iDriver ) && ! IsPlayerInPaintBall( playerid ) && ! IsPlayerInEvent( playerid ) && ! IsPlayerDueling( playerid ) )
					return 0;

				if ( p_WantedLevel[ playerid ] <= 2 && p_Class[ playerid ] != CLASS_POLICE && p_Class[ iDriver ] == CLASS_POLICE && GetPVarInt( playerid, "ShotCopWantedCD" ) < g_iTime )
					SendServerMessage( playerid, "You have physically touched an officer, thus you have been wanted." ), GivePlayerWantedLevel( playerid, 6 ), SetPVarInt( playerid, "ShotCopWantedCD", g_iTime + 120 );
			}
		}
	}

	// Explosive Bullets
	if ( hittype != BULLET_HIT_TYPE_OBJECT ) {
		CreateExplosiveBullet( playerid, hittype, hitid );
	}
    return 1;
}

stock CreateExplosiveBullet( playerid, hittype = BULLET_HIT_TYPE_OBJECT, hitid = INVALID_OBJECT_ID ) {

	if ( IsPlayerInCasino( playerid ) || IsPlayerInPaintBall( playerid ) || IsPlayerInEvent( playerid ) || IsPlayerInMinigame( playerid ) )
		return;

	if ( GetPVarInt( playerid, "explosive_rounds" ) == 1 && p_ExplosiveBullets[ playerid ] > 0 )
	{
		static Float: fromX, Float: fromY, Float: fromZ;
		static Float: toX, Float: toY, Float: toZ;

		if ( GetPlayerLastShotVectors( playerid, fromX, fromY, fromZ, toX, toY, toZ ) )
		{
			// create explosion at the core of the vehicle
			if ( hittype == BULLET_HIT_TYPE_VEHICLE ) {
				GetVehiclePos( hitid, toX, toY, toZ );
			}

			// Cool effect
			new objectid = CreateDynamicObject( 19296, fromX, fromY, fromZ, 0.0, 0.0, 0.0 );
			new milliseconds = MoveDynamicObject( objectid, toX, toY, toZ, 500.0 );
			SetTimerEx( "Timer_DestroyObject", milliseconds + 200, false, "d", objectid );
			Streamer_Update( playerid, STREAMER_TYPE_OBJECT );

			// deduct
			p_ExplosiveBullets[ playerid ] --;
			CreateExplosion( toX, toY, toZ, 12, 10.0 );
			ShowPlayerHelpDialog( playerid, 1500, "You have only %d explosive bullets remaining.", p_ExplosiveBullets[ playerid ] );
		}
	}
}

public OnPlayerShootDynamicObject( playerid, weaponid, objectid, Float:x, Float:y, Float:z )
{
	new
		modelid = Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID );

	// Explosive Bullets
	CreateExplosiveBullet( playerid );

	switch( modelid )
	{
		// C4
		case 19602:
		{
			foreach(new p : Player)
			{
				for( new i = 0; i < MAX_C4; i++ )
				{
					if ( objectid == g_C4Data[ p ] [ i ] [ E_OBJECT ] )
					{
						ExplodePlayerC4s( p, i, i + 1 );
						break;
					}
				}
			}
		}
	}
	return 1;
}

function RespawnaVehicle( vehicleid ) {
	new	Float: health;
	DeleteGVar( "respawning_veh", vehicleid );
	GetVehicleHealth( vehicleid, health );
	if ( health < 250.0 ) SetVehicleToRespawn( vehicleid );
}

#if defined AC_INCLUDED
public OnPlayerTakePlayerDamage( playerid, issuerid, &Float: amount, weaponid, bodypart )
{
	if ( !IsPlayerStreamedIn( issuerid, playerid ) || IsPlayerAFK( issuerid ) )
		return 0;

	// Boxing immunity
	if ( IsPlayerBoxing( playerid ) && ! IsPlayerBoxing( issuerid ) )
		 return ShowPlayerHelpDialog( issuerid, 2000, "You cannot damage a boxing player!" ), 0;

	if ( IsPlayerJailed( playerid ) || IsPlayerJailed( issuerid ) )
		return 0;

	// damaged player
	if ( p_Class[ playerid ] == CLASS_POLICE && p_inFBI{ playerid } && p_inCIA{ playerid } && !p_inArmy{ playerid } )
		SetPlayerColor( playerid, setAlpha( COLOR_CIA, 0xFF ) ), p_VisibleOnRadar[ playerid ] = g_iTime + 2;

	// shooter
	if ( p_Class[ issuerid ] == CLASS_POLICE && p_inFBI{ issuerid } && p_inCIA{ issuerid } && !p_inArmy{ issuerid } )
		SetPlayerColor( issuerid, setAlpha( COLOR_CIA, 0xFF ) ), p_VisibleOnRadar[ issuerid ] = g_iTime + 2;

	// alert admins
	new
		attack_difference = GetTickCount( ) - p_PlayerAltBindTick[ playerid ];

	if ( attack_difference < 1000 )
	{
		foreach ( new i : Player ) if ( p_Spectating{ i } && p_PlayerAltBind[ i ] == playerid && p_whomSpectating[ i ] == issuerid ) {
			SendClientMessageFormatted( i, COLOR_RED, "%s damaged %s within %d ms of moving", ReturnPlayerName( issuerid ), ReturnPlayerName( playerid ), attack_difference );
		}
	}

	// RDM with Knife
	if ( weaponid == WEAPON_KNIFE && amount > 256.0 && IsRandomDeathmatch( issuerid, playerid ) )
	{
		new
			iSeconds;

		if ( ( iSeconds = 60 + GetPlayerScore( issuerid ) ) > 500 )
			iSeconds = 500;

		JailPlayer( issuerid, iSeconds, 1 );
		SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been sent to jail for %d seconds by the server "COL_GREEN"[REASON: Random Deathmatch]", ReturnPlayerName( issuerid ), issuerid, iSeconds );
		return 1; // Need damage to pass through
	}

	/*if ( p_Class[ issuerid ] == CLASS_POLICE && p_Class[ playerid ] != CLASS_POLICE && !p_WantedLevel[ playerid ] && GetPlayerState( playerid ) != PLAYER_STATE_WASTED ) {
		ShowPlayerHelpDialog( issuerid, 2000, "You should not hurt innocent civilians, you're a ~b~cop~w~~h~!" );
	}*/
	if ( p_Class[ issuerid ] == CLASS_POLICE && p_Class[ playerid ] != CLASS_POLICE && !p_WantedLevel[ playerid ] && GetPlayerState( playerid ) != PLAYER_STATE_WASTED && ! IsPlayerInEvent( issuerid ) )
	 	return ShowPlayerHelpDialog( issuerid, 2000, "You cannot hurt innocent civilians, you're a ~b~cop~w~~h~!" ), 0;

	// Heal player (paramedic)
	if ( p_Class[ issuerid ] == CLASS_MEDIC && weaponid == WEAPON_SPRAYCAN )
	{
		new
			Float: fHealth = AC_GetPlayerHealth( playerid );

		if ( fHealth < 100.0 )
	 		AC_AddPlayerHealth( playerid, amount );

	 	return 0;
	}

	if ( p_Class[ playerid ] == p_Class[ issuerid ] && p_Class[ playerid ] != CLASS_CIVILIAN  )
		return 0;

	if ( p_BulletInvulnerbility[ playerid ] > g_iTime )
	 	return ShowPlayerHelpDialog( issuerid, 2000, "This player is immune from damage!" ), 0;

	if ( p_BulletInvulnerbility[ issuerid ] > g_iTime )
	 	return ShowPlayerHelpDialog( issuerid, 2000, "You cannot damage players as you're immune!" ), 0;

	if ( ( IsPlayerOnSlotMachine( playerid ) || IsPlayerMining( playerid ) ) && ! p_WantedLevel[ playerid ] )
	 	return ShowPlayerHelpDialog( issuerid, 2000, "This player cannot be killed as they are doing something!" ), 0;

	if ( IsPlayerTazed( playerid ) || IsPlayerCuffed( playerid ) || IsPlayerKidnapped( playerid ) || IsPlayerTied( playerid ) || IsPlayerLoadingObjects( playerid ) || IsPlayerAdminOnDuty( playerid ) || p_AntiSpawnKillEnabled{ playerid } )
		return 0;

	// Rhino damage invulnerable
	if ( p_Class[ playerid ] == CLASS_POLICE && IsPlayerInAnyVehicle( playerid ) && GetVehicleModel( GetPlayerVehicleID( playerid ) ) == 432 )
		return 0;

	// Anti RDM and gang member damage
	if ( ! IsPlayerInEvent( playerid ) && ! IsPlayerInPaintBall( playerid ) && ! IsPlayerBoxing( playerid ) && ! IsPlayerDueling( playerid ) )
	{
		if ( IsPlayerInPlayerGang( issuerid, playerid ) ) {
		 	return ShowPlayerHelpDialog( issuerid, 2000, "You cannot damage your homies!" ), 0;
		}

		// Passive mode enabled for player?
		if ( IsPlayerPassive( issuerid ) ) {
			/*if ( p_PassiveModeExpireTimer[ issuerid ] == -1 ) {
				p_PassiveModeExpireTimer[ issuerid ] = PassiveMode_Reset( issuerid, 4 ); // it will just set it to anything but -1 for now
			}*/
 			return ShowPlayerHelpDialog( issuerid, 2000, "~r~You cannot deathmatch with /passive enabled." ), 0;
		}

		// Passive mode enabled for damaged id?
		if ( IsPlayerPassive( playerid ) ) {
 			return ShowPlayerHelpDialog( issuerid, 2000, "This player has passive mode ~g~enabled." ), 0;
		}

		// Anti Random Deathmatch
		if ( IsRandomDeathmatch( issuerid, playerid ) ) {
			return ShowPlayerHelpDialog( issuerid, 2000, "This player cannot be ~r~random deathmatched." ), 0;
		}
	}

	// No passenger, no bullets
	if ( GetPlayerState( issuerid ) == PLAYER_STATE_PASSENGER )
	{
		new
			iVehicle = GetPlayerVehicleID( issuerid );

		if ( GetVehicleDriver( iVehicle ) == INVALID_PLAYER_ID )
	 		return ShowPlayerHelpDialog( issuerid, 2000, "You cannot drive-by without a driver!" ), 0;
	}

	// Wanted on shoot!
	if ( p_WantedLevel[ issuerid ] <= 2 && p_Class[ issuerid ] != CLASS_POLICE && p_Class[ playerid ] == CLASS_POLICE && GetPVarInt( issuerid, "ShotCopWantedCD" ) < g_iTime ) {
		GivePlayerWantedLevel( issuerid, 6 ), SetPVarInt( issuerid, "ShotCopWantedCD", g_iTime + 120 );
	}

	// Headshots
	if ( ( weaponid == WEAPON_SNIPER || weaponid == WEAPON_RIFLE ) && bodypart == 9 )
		amount *= 1.5;

	// Paintball Headshot
	if ( issuerid != INVALID_PLAYER_ID && p_inPaintBall{ playerid } == true )
	{
		new
			lobby_id = p_PaintBallArena{ playerid };

		if ( g_paintballData[ lobby_id ] [ E_HEADSHOT ] && (weaponid == WEAPON_SNIPER || weaponid == WEAPON_RIFLE ) && bodypart == 9 )
		{
			amount *= 3.333;
		}
	}

	// Increasing weapon damages
	switch( weaponid )
	{
		// Melee
		case WEAPON_BRASSKNUCKLE:
			amount *= 8.0;

		case WEAPON_GOLFCLUB:
			amount *= 4.0;

		case WEAPON_NITESTICK:
			amount *= 5.0;

		case WEAPON_KNIFE:
			amount *= 7.0;

		case WEAPON_BAT:
			amount *= 4.0;

		case WEAPON_SHOVEL:
			amount *= 3.0;

		case WEAPON_POOLSTICK:
			amount *= 3.0;

		case WEAPON_KATANA:
			amount *= 15.0;

		case WEAPON_DILDO .. WEAPON_VIBRATOR2:
			amount *= 3.0;

		case WEAPON_CANE:
			amount *= 4.0;

		// Guns with increased damage
		case WEAPON_RIFLE:
			amount *= 1.666;

		case WEAPON_SILENCED:
			amount *= 1.5;
	}

	CallLocalFunction( "OnPlayerTakenDamage", "ddfdd", playerid, issuerid, amount, weaponid, bodypart );
	return 1;
}
#endif

stock BeginEconomyTax( starting = 1 ) {
	mysql_function_query( dbHandle, "SELECT USER_CASH, BIZ_CASH, GANG_CASH FROM (SELECT (SUM(BANKMONEY)+SUM(CASH)) USER_CASH FROM USERS) A CROSS JOIN (SELECT SUM(BANK) BIZ_CASH FROM BUSINESSES) B CROSS JOIN (SELECT SUM(BANK) GANG_CASH FROM GANGS) C", true, "OnTaxEconomy", "i", starting );
}

thread OnTaxEconomy( starting )
{
	new rows;
    cache_get_data( rows, tmpVariable );
    if ( ! rows ) return 1;

	new user_cash = cache_get_field_content_int( 0, "USER_CASH", dbHandle );
	new biz_cash = cache_get_field_content_int( 0, "BIZ_CASH", dbHandle );
	new gang_cash = cache_get_field_content_int( 0, "GANG_CASH", dbHandle );

	// total_thousands
	new Float: total_thousands = float( user_cash + biz_cash + gang_cash ) / 1000000.0;

	// step
	if ( starting == 1 )
	{
		new Float: tax_rate = GetGVarFloat( "taxrate" ) / 100.0; // 1%

		// players
		foreach ( new playerid : Player ) {
			new Float: tax_discount = p_VIPLevel[ playerid ] >= VIP_GOLD ? 0.5 : 1.0;
			new player_tax = floatround( float( GetPlayerTotalCash( playerid ) ) * tax_rate * tax_discount );

			if ( player_tax > 0 ) {
				ShowPlayerHelpDialog( playerid, 5000, sprintf( "~w~You have paid ~r~%s~w~ in tax", cash_format( player_tax ) ) );
				GivePlayerCash( playerid, -player_tax );
			}
		}

		// businesses
		foreach ( new businessid : business ) {
			new business_tax = floatround( float( g_businessData[ businessid ] [ E_BANK ] ) * tax_rate );
			if ( business_tax > 0 ) g_businessData[ businessid ] [ E_BANK ] -= business_tax;
		}

		// gangs
		foreach ( new gangid : gangs ) {
			new gang_tax = floatround( float( g_gangData[ gangid ] [ E_BANK ] ) * tax_rate );
			if ( gang_tax > 0 ) g_gangData[ gangid ] [ E_BANK ] -= gang_tax;
		}

		// queries
		mysql_single_query( sprintf( "UPDATE `USERS` SET `CASH`=`CASH`*IF(`VIP_PACKAGE`>=3,%f,%f),`BANKMONEY`=`BANKMONEY`*IF(`VIP_PACKAGE`>=3,%f,%f) WHERE `ONLINE`=0 AND (`BANKMONEY`+`CASH`)>0", 1.0 - tax_rate / 2.0, 1.0 - tax_rate, 1.0 - tax_rate / 2.0, 1.0 - tax_rate ) );
		mysql_single_query( sprintf( "UPDATE `BUSINESSES` SET `BANK`=`BANK`*%f WHERE `BANK`>0", 1.0 - tax_rate ) );
		mysql_single_query( sprintf( "UPDATE `GANGS` SET `BANK`=`BANK`*%f WHERE `BANK`>0", 1.0 - tax_rate ) );

		// set current economy money
		SetGVarFloat( "before_tax", total_thousands );
		printf("[SERVER ECONOMY TAX] $%0.3fM before tax.", total_thousands );
		BeginEconomyTax( .starting = 0 );
	}
	else
	{
		new Float: profit = GetGVarFloat( "before_tax" ) - total_thousands; // millions

		// eventbank donate
		new eventbank = floatround( profit * 100000.0 ); // 10%
		UpdateServerVariable( "eventbank", GetGVarInt( "eventbank" ) + eventbank, 0.0, "", GLOBAL_VARTYPE_INT );

		// hitman budget
		new hitman_budget = floatround( profit * 100000.0 ); // 10%
		UpdateServerVariable( "hitman_budget", GetGVarInt( "hitman_budget" ) + hitman_budget, 0.0, "", GLOBAL_VARTYPE_INT );

		// add to server vars
		UpdateServerVariable( "taxprofit_prev", 0, GetGVarFloat( "taxprofit" ), "", GLOBAL_VARTYPE_FLOAT );
		UpdateServerVariable( "taxprofit", 0, GetGVarFloat( "taxprofit" ) + profit, "", GLOBAL_VARTYPE_FLOAT );
		printf( "[SERVER ECONOMY TAX] The server economy has been successfully taxed for a profit of $%0.3fM.", profit );
	}
	return 1;
}

#if defined AC_INCLUDED
public OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
public OnPlayerDeath( playerid, killerid, reason )
#endif
{
	if ( !p_PlayerLogged{ playerid } ) {
	    return SendServerMessage( playerid, "Possible Fake-kill detected - 0x0A" ), KickPlayerTimed( playerid );
	}

	// Robbery system
	if ( IsPlayerNPC( killerid ) )
	{
		new
			clerkid = GetRobberyNpcFromPlayer( killerid );

		if ( clerkid != -1 ) {
			ReplenishRobberyNpc( clerkid, .fullreplenish = false );
		}
	}

	// Reset player variables
    p_Spawned{ playerid } = false;
    p_QuitToAvoidTimestamp[ playerid ] = 0;
    CutSpectation( playerid );
    StopPlayerNpcRobbery( playerid );
    RemovePlayerFromRace( playerid );
    RemovePlayerStolensFromHands( playerid );
    RemoveEquippedOre( playerid );
    KillTimer( p_CuffAbuseTimer[ playerid ] );
    ResetPlayerPassiveMode( playerid );
    PlayerTextDrawHide( playerid, p_LocationTD[ playerid ] );
	p_Tazed{ playerid } = false;
	p_WeaponDealing{ playerid } = false;
	p_WeaponDealer[ playerid ] = INVALID_PLAYER_ID;
	p_Cuffed{ playerid } = false;
	//p_DetainedBy[ playerid ] = INVALID_PLAYER_ID;
	p_LastVehicle[ playerid ] = INVALID_VEHICLE_ID;
	//Delete3DTextLabel( p_DetainedLabel[ playerid ] );
	//p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	Delete3DTextLabel( p_TiedLabel[ playerid ] );
	p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	DestroyDynamic3DTextLabel( p_WeedLabel[ playerid ] );
	p_WeedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_Tied{ playerid } = false;
	p_TicketTimestamp[ playerid ] = 0;
	p_Kidnapped{ playerid } = false;
    //p_Detained{ playerid } = false;
	p_ClassSelection{ playerid } = false;
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
	KillTimer( p_TrackingTimer[ playerid ] );
	p_TrackingTimer[ playerid ] = -1;
	DeletePVar( playerid, "AlcatrazWantedCD" );
	DeletePVar( playerid, "ShotCopWantedCD" );
	PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_ExperienceTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_WebsiteTD );
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_MotdTD );
	PlayerTextDrawHide( playerid, g_ZoneOwnerTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_NotManyPlayersTD );
	TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	TextDrawHideForPlayer( playerid, g_WorldDayTD );
	TextDrawHideForPlayer( playerid, g_AdminLogTD );
	TextDrawHideForPlayer( playerid, g_DoubleXPTD );
	PlayerTextDrawHide( playerid, p_PlayerRankTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_PlayerRankTextTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_CurrentRankTD );
	TextDrawHideForPlayer( playerid, g_currentXPTD );
	HidePlayerTogglableTextdraws( playerid );

	/* ** Tax And Medical Fees **
	if ( GetPlayerTotalCash( playerid ) > 0 && ! ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || IsPlayerInEvent( playerid ) ) )  {
		ShowPlayerHelpDialog( playerid, 5000, sprintf( "~w~You have paid ~r~$100~w~ in medical fees" ) );
		GivePlayerCash( playerid, -100 );
	} */

	new
		playerGangId = p_GangID[ playerid ];

    if ( ! IsPlayerNPC( killerid ) && IsPlayerConnected( killerid ) && GetPVarInt( playerid, "used_cmd_kill" ) != 1 )
    {
		if ( ! IsPlayerStreamedIn( killerid, playerid ) && ! IsPlayerUsingOrbitalCannon( killerid ) ) {
			printf( "[DEBUG] %s was killed for possible fake kill. (0x1B)", ReturnPlayerName( playerid ) );
	    	return SendServerMessage( playerid, "Possible Fake-kill detected - 0x1B" ), KickPlayerTimed( playerid );
		}

		/*if ( GetPVarInt( killerid, "last_shot" ) != playerid ) {
			printf( "[DEBUG] %s was killed for possible fake kill (last shot %d). (0x0C)", ReturnPlayerName( playerid ), GetPVarInt( killerid, "last_shot" ) );
	    	return SendServerMessage( playerid, "Possible Fake-kill detected - 0x0C" ), KickPlayerTimed( playerid );
		}
		DeletePVar( killerid, "last_shot" );*/

		SendDeathMessage( killerid, playerid, reason );

		DCC_SendChannelMessageFormatted( discordGeneralChan, "*%s(%d) has killed %s(%d) - %s!*", ReturnPlayerName( killerid ), killerid,  ReturnPlayerName( playerid ), playerid, ReturnWeaponName( reason ) );

		if ( !IsPlayerAdminOnDuty( killerid ) )
		{
			new
				killerGangId = p_GangID[ killerid ];

			if ( killerGangId != INVALID_GANG_ID ) {
				g_gangData[ killerGangId ] [ E_KILLS ] ++;
				if ( killerGangId != p_GangID[ playerid ] ) g_gangData[ killerGangId ] [ E_RESPECT ] ++;
				SaveGangData( killerGangId );
			}

			switch( p_Kills[ killerid ]++ )
			{
				case 5:    	ShowAchievement( killerid, "Noob Killer - 5 Kills!", 3 );
				case 20:    ShowAchievement( killerid, "Rookie Killer - 20 Kills!", 6 );
				case 50:    ShowAchievement( killerid, "Novice Killer - 50 Kills!", 9 );
				case 100:   ShowAchievement( killerid, "Corporal Killer - 100 Kills!", 12 );
				case 200:   ShowAchievement( killerid, "Monster Killer - 200 Kills!", 15 );
				case 500:   ShowAchievement( killerid, "General Killer - 500 Kills!", 18 );
				case 1000:  ShowAchievement( killerid, "Master Killer - 1000 Kills!", 25 );
			}

			WeaponStats_IncrementKill( killerid, reason );
			Streak_IncrementPlayerStreak( killerid, STREAK_KILL );

			if ( p_VIPLevel[ killerid ] && !isnull( p_DeathMessage[ killerid ] ) ) {
    			GameTextForPlayer( playerid, p_DeathMessage[ killerid ], 4000, 6 );
			}
		}

		if ( p_Class[ killerid ] == CLASS_POLICE )
	    {
	        if ( p_Class[ killerid ] == p_Class[ playerid ] )
	        {
	            // SendClientMessageToAdmins( -1, ""COL_PINK"[FAKE-KILL]{FFFFFF} Traces of fake-kill have came from %s: "COL_GREY"%s", ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ) );
	            // KickPlayerTimed( playerid );
	            SendClientMessageFormatted( killerid, -1, ""COL_BLUE"[INNOCENT KILL]{FFFFFF} You have killed a team mate %s, you have lost 2 score and "COL_GOLD"$10,000{FFFFFF}.", ReturnPlayerName( playerid ) );
				GivePlayerCash( killerid, -10000 );
				GivePlayerScore( killerid, -2 );
				JailPlayer( killerid, 200, 1 );
				cmd_rules( killerid, "" );
				WarnPlayerClass( killerid, p_inArmy{ killerid } );
				SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been sent to jail for 200 seconds by the server "COL_GREEN"[REASON: Killing Teammate(s)]", ReturnPlayerName( killerid ), killerid );
				return 1;
			}
			else
			{
				if ( !IsPlayerInEvent( killerid ) ) // Allow in event
				{
				    if ( p_WantedLevel[ playerid ] > 5 )
					{
						static const killedWords[ ] [ ] = { { "murked" }, { "killed" }, { "ended" }, { "slain" }, { "massacred" }, { "destroyed" }, { "screwed" } };
				        new cashEarned = ( p_WantedLevel[ playerid ] < MAX_WANTED_LVL ? p_WantedLevel[ playerid ] : MAX_WANTED_LVL ) * ( reason == 38 ? 170 : 270 );
				        GivePlayerCash( killerid, cashEarned );
				        GivePlayerScore( killerid, 2 );
						GivePlayerExperience( killerid, E_POLICE, 0.5 );
				        if ( cashEarned > 20000 ) printf("[police kill] %s -> %s - %s", ReturnPlayerName( killerid ), ReturnPlayerName( playerid ), cash_format( cashEarned ) ); // 8hska7082bmahu
				       	if ( p_WantedLevel[ playerid ] > 64 ) SendGlobalMessage( -1, ""COL_GOLD"[POLICE KILL]{FFFFFF} %s(%d) has %s %s(%d) who had a wanted level of %d!", ReturnPlayerName( killerid ), killerid, killedWords[ random( sizeof( killedWords ) ) ], ReturnPlayerName( playerid ), playerid, p_WantedLevel[ playerid ] );
				    	SendClientMessageFormatted( killerid, -1, ""COL_GOLD"[ACHIEVE]{FFFFFF} You have killed %s(%d) with a wanted level of %d; earning you "COL_GOLD"%s{FFFFFF} and 2 score!", ReturnPlayerName( playerid ), playerid, p_WantedLevel[ playerid ], cash_format( cashEarned ) );
				    }
				    else
				    {
				        if ( p_WantedLevel[ playerid ] <= 0 ) {
							SendClientMessageFormatted( killerid, -1, ""COL_BLUE"[INNOCENT KILL]{FFFFFF} You have killed innocent %s, you have lost 2 score and "COL_GOLD"$10,000{FFFFFF}.", ReturnPlayerName( playerid ) );
							GivePlayerCash( killerid, -10000 );
							GivePlayerScore( killerid, -2 );
							JailPlayer( killerid, 200, 1 );
							cmd_rules( killerid, "" );
							WarnPlayerClass( killerid, p_inArmy{ killerid } );
							SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been sent to jail for 200 seconds by the server "COL_GREEN"[REASON: Killing Innocent(s)]", ReturnPlayerName( killerid ), killerid );
						}
						else if ( p_WantedLevel[ playerid ] <= 5 ) {
							SendClientMessageFormatted( killerid, -1, ""COL_BLUE"[INNOCENT KILL]{FFFFFF} You have killed low suspect %s, you have lost 2 score and "COL_GOLD"$5,000{FFFFFF}.", ReturnPlayerName( playerid ) );
	                        GivePlayerCash( killerid, -5000 );
							GivePlayerScore( killerid, -2 );
						}
				    }
				}
			}
	    }

		if ( p_Class[ playerid ] == CLASS_POLICE && p_Class[ killerid ] == CLASS_CIVILIAN )
		{
		    new
				szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

			if ( GetPlayerLocation( killerid, szCity, szLocation ) )
				SendClientMessageToCops( -1, ""COL_BLUE"[POLICE RADIO]"COL_WHITE" %s has murdered %s near %s in %s.", ReturnPlayerName( killerid ), ReturnPlayerName( playerid ), szLocation, szCity );
			else
				SendClientMessageToCops( -1, ""COL_BLUE"[POLICE RADIO]"COL_WHITE" %s has murdered %s.", ReturnPlayerName( killerid ), ReturnPlayerName( playerid ) );

			CreateCrimeReport( killerid );
		}

        if ( p_Class[ killerid ] == CLASS_CIVILIAN && IsPlayerJob( killerid, JOB_HITMAN ) )
		{
			new
				iContractAmount = p_ContractedAmount[ playerid ];

			if ( iContractAmount >= 50000 && GetPlayerScore( killerid ) < 50 )
			{
				SendServerMessage( playerid, "Your contract is incomplete as you have been killed by a player with lower than 50 score." );
				SendError( killerid, "You need at least 50 score to complete contracts above $50,000." );
			}
			else if ( iContractAmount >= 1000 )
			{
			    SendGlobalMessage( -1, ""COL_ORANGE"[CONTRACT]"COL_WHITE" %s(%d) has completed the contract on %s(%d), he has earned "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( killerid ), killerid, ReturnPlayerName( playerid ), playerid, cash_format( iContractAmount ) );
				GivePlayerCash( killerid, iContractAmount );
				p_ContractedAmount[ playerid ] = 0;
			   	switch( ++p_HitsComplete[ killerid ] )
			   	{
			   	    case 5:     ShowAchievement( killerid, "Completed ~r~5~w~~h~~h~ contracts!", 3 );
			   	    case 20:    ShowAchievement( killerid, "Completed ~r~20~w~~h~~h~ contracts!", 6 );
			   	    case 50:    ShowAchievement( killerid, "Completed ~r~50~w~~h~~h~ contracts!", 9 );
			   	    case 100:   ShowAchievement( killerid, "Completed ~r~100~w~~h~~h~ contracts!", 12 );
			   	    case 200:   ShowAchievement( killerid, "Completed ~r~200~w~~h~~h~ contracts!", 15 );
			   	    case 500:   ShowAchievement( killerid, "Completed ~r~500~w~~h~~h~ contracts!", 18 );
			   	    case 1000:  ShowAchievement( killerid, "Completed ~r~1000~w~~h~~h~ contracts!", 25 );
				}
			}
		}

		if ( p_Class[ killerid ] != CLASS_POLICE )
		{
			GivePlayerWantedLevel( killerid, 12 );
			GivePlayerScore( killerid, 1 );

			new
				Float: default_experience = 1.0;

			switch ( reason ) {
				case 24: default_experience = 1.5;
				case 25, 23: default_experience = 1.25;
				case 26: default_experience = 0.8;
				case 34, 33: default_experience = 2.0;
			}
			GivePlayerExperience( killerid, E_DEATHMATCH, default_experience );
		}
	}
	else if ( IsPlayerNPC( killerid ) ) SendDeathMessage( killerid, playerid, reason );
	else
	{
		DCC_SendChannelMessageFormatted( discordGeneralChan, "*%s(%d) has committed suicide!*", ReturnPlayerName( playerid ), playerid );
	    SendDeathMessage( INVALID_PLAYER_ID, playerid, 53 );
	    DeletePVar( playerid, "used_cmd_kill" );
	}

	if ( ! IsPlayerInPaintBall( playerid ) && !p_LeftPaintball{ playerid } && !IsPlayerAdminOnDuty( playerid ) )
	{
		if ( playerGangId != INVALID_GANG_ID )
			SaveGangData( playerGangId ), g_gangData[ playerGangId ] [ E_DEATHS ]++;

		p_Deaths[ playerid ] ++; // Usually other events do nothing
		GivePlayerSeasonalXP( playerid, -10.0 ); // Deduct points, it's meant to be hard!!!
	}

    ClearPlayerWantedLevel( playerid );
	return 1;
}

public OnVehicleSpawn( vehicleid )
{
	KillEveryoneInShamal( vehicleid );
    ResetVehicleBurglaryData( vehicleid );

	if ( g_buyableVehicle{ vehicleid } == true ) {
		RespawnBuyableVehicle( vehicleid );
	}
	return 1;
}

public OnVehicleDeath( vehicleid, killerid )
{
    ResetVehicleBurglaryData( vehicleid );
    KillEveryoneInShamal( vehicleid );
	return 1;
}

public OnVehicleCreated( vehicleid, model_id )
{
	new
		attached_objects[ MAX_VEH_ATTACHED_OBJECTS ] = { -1, ... };

	switch ( model_id )
	{
		// journey help text
		case 508:
		{
			attached_objects[ 0 ] = CreateDynamicObject( 19861, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
			attached_objects[ 1 ] = CreateDynamicObject( 19861, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
			SetDynamicObjectMaterialText( attached_objects[ 0 ], 0, "Meth Van\n{ffffff}Press G", 140, "Impact", 40, 0, -65536, 0, 1 );
			SetDynamicObjectMaterialText( attached_objects[ 1 ], 0, "Meth Van\n{ffffff}Press G", 140, "Impact", 40, 0, -65536, 0, 1 );
			AttachDynamicObjectToVehicle( attached_objects[ 0 ], vehicleid, 1.350000, -2.200000, 1.799999, 0.000000, 0.000000, 90.00000 );
			AttachDynamicObjectToVehicle( attached_objects[ 1 ], vehicleid, -1.35000, -2.200000, 1.799999, 0.000000, 0.000000, -90.0000 );
			SetGVarInt( "vehicle_objects_0", attached_objects[ 0 ], vehicleid );
			SetGVarInt( "vehicle_objects_1", attached_objects[ 1 ], vehicleid );
		}
	}
	return 1;
}

public OnVehicleDestroyed( vehicleid )
{
	if ( GetGVarType( "vehicle_objects_0", vehicleid ) != GLOBAL_VARTYPE_NONE )
	{
		// remove all objects
		for ( new i = 0; i < MAX_VEH_ATTACHED_OBJECTS; i ++ )
		{
			new object_id = GetGVarInt( sprintf( "vehicle_objects_%d", i ), vehicleid );

			if ( object_id ) {
				DestroyDynamicObject( object_id );
				DeleteGVar( sprintf( "vehicle_objects_%d", i ), vehicleid );
			}
		}
	}
	return 1;
}

public OnPlayerUnjailed( playerid, reasonid )
{
	switch( reasonid )
	{
		case 0: SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been released from jail "COL_GREEN"[Served his time]", ReturnPlayerName( playerid ), playerid );
		case 1: SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been released from jail "COL_BLUE"[Paid his bail]", ReturnPlayerName( playerid ), playerid );
		case 2: SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been released from jail "COL_GREEN"[Melted the metal and escaped!]", ReturnPlayerName( playerid ), playerid );
		//case 4: SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been released from jail "COL_GREY"[Busted Out!]", ReturnPlayerName( playerid ), playerid );
	}

    if ( reasonid != 5 )
    {
    	SetPlayerVirtualWorld( playerid, 30 );
		TogglePlayerControllable( playerid, 0 );
		SetTimerEx( "ope_Unfreeze", 3000, false, "d", playerid );
    }

    if ( reasonid < 4 )
   	{
   		SetPlayerHealth( playerid, 100.0 );
   		if ( p_inAlcatraz{ playerid } )
   		{
   			SetPlayerPosEx( playerid, -2052.0059, 1324.6919, 7.1615, 0 );
   			SetPVarInt( playerid, "AlcatrazWantedCD", g_iTime + ALCATRAZ_TIME_WANTED );
   			SetPlayerVirtualWorld( playerid, 0 );
   		}
   		else
   		{
	   		switch( GetPlayerInterior( playerid ) )
	   		{
	   			case 3:	 SetPlayerPosEx( playerid, 202.2303, 168.4880, 1003.0234, 3 );
	   			case 6:  SetPlayerPosEx( playerid, 266.5086, 90.97350, 1001.0391, 6 );
	   			default: SetPlayerPosEx( playerid, 216.7583, 120.1729, 999.0156, 10 );
	   		}
   		}
	}

    PlainUnjailPlayer 		( playerid );
	SetPlayerColorToTeam	( playerid );
    ClearPlayerWantedLevel	( playerid );
	SetPlayerPassiveMode 	( playerid );
	return 1;
}

public OnPlayerText( playerid, text[ ] )
{
	new
		time = g_iTime;

	if ( GetPlayerScore( playerid ) < 10 )
		return SendServerMessage( playerid, "You need at least 10 score to talk. "COL_GREY"Use /ask or /report to talk to an admin in the meanwhile." ), 0;

	if ( !p_PlayerLogged{ playerid } )
		return SendError( playerid, "You must be logged in to talk." ), 0;

#if !defined DEBUG_MODE
	GetServerVarAsString( "rcon_password", szNormalString, sizeof( szNormalString ) ); // Anti-rcon spam poop
	if ( strfind( text, szNormalString, true ) != -1 )
	    return SendError( playerid, "An error occured, please try again." ), 0;
#endif

	if ( textContainsIP( text ) )
		return SendServerMessage( playerid, "Please do not advertise." ), 0;

	if ( !hasTickcountPassed( p_AntiTextSpam[ playerid ], 750 ) )
	{
		p_AntiTextSpam[ playerid ] = GetTickCount( );
	    p_AntiTextSpamCount{ playerid } ++;
	 	SendError( playerid, "You must wait 0.75 seconds before posting again. "COL_GREY"[%d/3]", p_AntiTextSpamCount{ playerid } );

	 	if ( p_AntiTextSpamCount{ playerid } >= 3 ) {
			SendServerMessage( playerid, "You have been kicked for chat flooding. Please refrain from flooding the chat." );
			KickPlayerTimed( playerid );
		}
		return 0;
	}

	if ( GetPVarString( playerid, "last_message", szNormalString, sizeof( szNormalString ) ) && strmatch( szNormalString, text ) )
		return SendError( playerid, "You cannot repeat the same phrase." ), 0;

	SetPVarString( playerid, "last_message", text );

	p_AntiTextSpamCount{ playerid } = 0;
	p_AntiTextSpam[ playerid ] = GetTickCount( );

	if ( p_Muted{ playerid } )
	{
	 	if ( time > p_MutedTime[ playerid ] ) p_Muted{ playerid } = false;
		else
		{
		    SendError( playerid, "You cannot speak as you are muted for %s.", secondstotime( p_MutedTime[ playerid ] - time ) );
			return 0;
		}
	}

	if ( ! IsPlayerSettingToggled( playerid, SETTING_CHAT_PREFIXES ) )
	{
		switch( text[ 0 ] )
		{
		    case '!':
			{
			    if ( p_Class[ playerid ] == CLASS_POLICE )
				{
				    format( szBigString, 144, "%s", text );
				    for( new i; i < sizeof( g_coptenCodes ); i++ ) {
			        	if ( strfind( szBigString, g_coptenCodes[ i ] [ E_CODE ] ) != -1 ) {
							strreplace( szBigString, g_coptenCodes[ i ] [ E_CODE ], g_coptenCodes[ i ] [ E_SUBJECT ] );
						}
					}
				    SendClientMessageToCops( -1, ""COL_BLUE"<Police Radio> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, szBigString[ 1 ] );

				    foreach(new i : Player)
					{
					    if ( ( p_AdminLevel[ i ] >= 5 || IsPlayerUnderCover( i ) ) && p_ToggleCopChat{ i } == true )
					    {
					    	SendClientMessageFormatted( i, -1, ""COL_BLUE"<Police Radio> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, szBigString[ 1 ] );
					    }
					}
				    return 0;
				}

				else if ( p_Class[ playerid ] == CLASS_FIREMAN )
				{
				    SendClientMessageToFireman( -1, "{A83434}<Fireman Radio> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
				    return 0;
				}

				else if ( p_Class[ playerid ] == CLASS_MEDIC )
				{
				    SendClientMessageToAmbulance( -1, "{00CC00}<Paramedic Radio> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
				    return 0;
				}

				else if ( p_Class[ playerid ] == CLASS_CIVILIAN && p_GangID[ playerid ] != INVALID_GANG_ID )
				{
			        SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "<Gang Chat> %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
					return 0;
				}
			}
			case '@':
			{
				if ( p_AdminLevel[ playerid ] > 0 )
				{
					SendClientMessageToAdmins( -1, ""COL_PINK"<Admin Chat> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
				    return 0;
				}
			}
			case '#':
			{
			    if ( p_VIPLevel[ playerid ] > 0 )
			    {
					DCC_SendChannelMessageFormatted( discordGeneralChan, "__**(VIP) %s(%d):**__ %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
					SendClientMessageToAllFormatted( 0x3eff3eff, "[VIP] %s(%d):{9ec34f} %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
			        return 0;
			    }
			}
			case '$':
			{
			    if ( p_VIPLevel[ playerid ] > 0 )
			    {
					SendClientMessageToVips( -1, ""COL_GOLD"<VIP Chat> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
				    return 0;
			    }
			}
		}
	}
	DCC_SendChannelMessageFormatted( discordGeneralChan, "**%s(%d):** %s", ReturnPlayerName( playerid ), playerid, text ); // p_Class[ playerid ] == CLASS_POLICE ? 12 : 4
	return 1;
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

function RapeDamage( playerid )
{
	if ( !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) || p_InfectedHIV{ playerid } == false || p_Jailed{ playerid } == true )
		return 0;

	new Float: Health;

	if ( !IsPlayerTied( playerid ) || !IsPlayerTazed( playerid ) || !p_pausedToLoad{ playerid } )
	{
	    GetPlayerHealth( playerid, Health );
	  	SetPlayerHealth( playerid, ( Health - 5.0 ) );
	}

	return SetTimerEx( "RapeDamage", 5000, false, "d", playerid );
}

function circleall_Countdown( time, countdown_cmd )
{
	static string[ 6 ];
	if ( time <= 0 )
	{
	    GameTextForAll( "~g~GO!", 2000, 3 );
	    g_circleall_CD = false;
	    foreach(new i : Player) {
			PlayerPlaySound( i, 1057, 0.0, 0.0, 0.0 );
			if ( !countdown_cmd ) TogglePlayerControllable( i, 1 );
		}
	}
	else
	{
	    format( string, sizeof( string ), "~y~%d", time );
		GameTextForAll( string, 2000, 3 );
	    foreach(new i : Player) { PlayerPlaySound( i, 1056, 0.0, 0.0, 0.0 ); }
		SetTimerEx( "circleall_Countdown", 960, false, "dd", time - 1, countdown_cmd );
	}
}

function BlowJob( playerid, pID, step )
{
	switch( step )
	{
	    case 0:
	    {
			ApplyAnimation( pID, "BLOWJOBZ", "BJ_STAND_LOOP_P", 2.0, 1, 1, 1, 0, 0, 1 );
			ApplyAnimation( playerid, "BLOWJOBZ", "BJ_STAND_LOOP_W", 2.0, 1, 1, 1, 0, 0, 1 );
            SetTimerEx( "BlowJob", 10000, false, "ddd", playerid, pID, 1 );
	    }
	    case 1:
	    {
			ApplyAnimation( pID, "BLOWJOBZ", "BJ_STAND_END_P", 2.0, 0, 1, 1, 0, 0, 1 );
			ApplyAnimation( playerid, "BLOWJOBZ", "BJ_STAND_END_W", 2.0, 1, 1, 1, 0, 0, 1 );
            SetTimerEx( "BlowJob", 2500, false, "ddd", playerid, pID, 2 );
	    }
	    case 2:
	    {
			TogglePlayerControllable( playerid, 1 );
			TogglePlayerControllable( pID, 1 );
	        ClearAnimations( playerid ), SetCameraBehindPlayer( playerid );
	        ClearAnimations( pID ), SetCameraBehindPlayer( pID );
			p_GivingBlowjob{ playerid } = false;
			p_GivingBlowjob{ pID } = false;
			p_GettingBlowjob{ pID } = false;
			p_GettingBlowjob{ playerid } = false;
	    }
	}
}

stock UntiePlayer( playerid )
{
	if ( !IsPlayerConnected( playerid ) || ( !p_Tied{ playerid } && !p_Kidnapped{ playerid } ) )
	    return;

	TogglePlayerControllable( playerid, 1 );
	p_Tied{ playerid } = false;
	p_Kidnapped{ playerid } = false;
	Delete3DTextLabel( p_TiedLabel[ playerid ] );
	p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_BulletInvulnerbility[ playerid ] = g_iTime + 5;
	SendGlobalMessage( -1, ""COL_GREY"[SERVER]{FFFFFF} %s(%d) has been untied by the anti-abuse system.", ReturnPlayerName( playerid ), playerid );
}

function emp_deactivate( vehicleid )
{
	if ( !IsValidVehicle( vehicleid ) ) return 0;
	GetVehicleParamsEx( vehicleid, engine, lights, alarm, doors, bonnet, boot, objective );
	SetVehicleParamsEx( vehicleid, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective );
	return 1;
}

public OnPlayerLeaveGang( playerid, gangid, reason )
{
	switch( reason )
	{
	    case GANG_LEAVE_KICK:
	    	SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang (KICKED)", ReturnPlayerName( playerid ), playerid );

	    case GANG_LEAVE_QUIT:
	    	SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang (LEFT)", ReturnPlayerName( playerid ), playerid );

	    case GANG_LEAVE_UNKNOWN:
	    	SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang (UNKNOWN)", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

public OnPlayerProgressUpdate( playerid, progressid, bool: canceled, params )
{
	if ( progressid == PROGRESS_CRACKING || progressid == PROGRESS_BRUTEFORCE ) {
        if ( !IsPlayerSpawned( playerid ) || !IsPlayerInDynamicCP( playerid, g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CHECKPOINT ] [ 0 ] ) || !IsPlayerConnected( playerid ) || IsPlayerInAnyVehicle( playerid ) || canceled )
        	return g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_BEING_CRACKED ] = false, StopProgressBar( playerid ), 1;
	}
	else if ( progressid == PROGRESS_CRACKING_BIZ )
	{
		new
			businessid = GetPVarInt( playerid, "crackpw_biz" );

		if ( ! IsPlayerSpawned( playerid ) || ! IsPlayerInDynamicCP( playerid, g_businessData[ businessid ] [ E_ENTER_CP ] ) || !IsPlayerConnected( playerid ) || IsPlayerInAnyVehicle( playerid ) || canceled ) {
			g_businessData[ businessid ] [ E_BEING_CRACKED ] = false;
			return StopProgressBar( playerid ), 1;
		}
	}
	else if ( progressid == PROGRESS_ROBBING || progressid == PROGRESS_SAFEPICK )
	{
		new
			Float: distance = distanceFromSafe( playerid, params );

		new abort = ( !IsPlayerSpawned( playerid ) || !IsPlayerConnected( playerid ) || IsPlayerTied( playerid ) || IsPlayerInAnyVehicle( playerid ) || GetPlayerState( playerid ) == PLAYER_STATE_WASTED || IsPlayerAFK( playerid ) || params == -1 || distance > 1.5 || distance < 0.0 || canceled );

		if ( g_Debugging )
		{
			//SendClientMessageFormatted( playerid, COLOR_YELLOW, "distance: %f, params: %d, player: %d, jacked: %d", distance, params, p_UsingRobberySafe	[ playerid ], g_robberyData[ params ] [ E_STATE ] );
			new robberyid = params; printf("[DEBUG] [ROBBERY] [%d] Robbing/Picking [progress : %d, distance : %f, abort : %d] { open : %d, robbed : %d, c4: %d, drill : %d, dplacer : %d, deffect : %d, replenish : %d, raw ts : %d, current ts : %d, name : %s, state : %d }",
				robberyid, progressid, distance, abort,
				g_robberyData[ robberyid ] [ E_OPEN ], g_robberyData[ robberyid ] [ E_ROBBED ], g_robberyData[ robberyid ] [ E_C4 ],
				g_robberyData[ robberyid ] [ E_DRILL ], g_robberyData[ robberyid ] [ E_DRILL_PLACER ], g_robberyData[ robberyid ] [ E_DRILL_EFFECT ], g_robberyData[ robberyid ] [ E_ROB_TIME ] - g_iTime,
				g_robberyData[ robberyid ] [ E_ROB_TIME ], g_iTime, g_robberyData[ robberyid ] [ E_NAME ], g_robberyData[ robberyid ] [ E_STATE ] );
		}

		if ( abort )
		{
			RemovePlayerAttachedObject( playerid, 0 );
			g_robberyData 		[ params ] [ E_STATE ] = STATE_NONE;
			p_UsingRobberySafe	[ playerid ] = -1;
			return StopProgressBar( playerid ), 1;
		}

		// force angle
		SetPlayerFacingAngle( playerid, g_robberyData[ params ] [ E_DOOR_ROT ] );
	}
	else if ( progressid == PROGRESS_CHEMICAL || progressid == PROGRESS_GRAB_METH )
	{
		if ( !IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) || !IsPlayerInMethlab( playerid ) || canceled )
			return DeletePVar( playerid, "pouring_chemical" ), StopProgressBar( playerid ), 1;
	}
	return 1;
}

public OnProgressCompleted( playerid, progressid, params )
{
	static
	    iRandom, Float: X, Float: Y, Float: Z;

	switch( progressid )
	{
		case PROGRESS_BRUTEFORCE:
		{
		   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_BEING_CRACKED ] = false;
			g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_WAIT ] = g_iTime + 30;
	        iRandom = random( 101 );
	        if ( iRandom < 75  )
	        {
				g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED ] = true;
			   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_TS ] = g_iTime + 60;
				SendServerMessage( playerid, "You have successfully brute forced this houses' password. This lasts for one minute." );
	        }
	        else SendServerMessage( playerid, "You have failed to brute force this houses' password." );
		}
		case PROGRESS_CRACKING_BIZ:
		{
			new szLocation[ MAX_ZONE_NAME ];
			new businessid = GetPVarInt( playerid, "crackpw_biz" );
			g_businessData[ businessid ] [ E_BEING_CRACKED ] = false;
			g_businessData[ businessid ] [ E_CRACKED_WAIT ] = g_iTime + 120; // g_businessSecurityData[ g_businessData[ businessid ] [ E_SECURITY_LEVEL ] ] [ E_BREAKIN_COOLDOWN ];

			if ( random( 100 ) < 75 )
			{
				foreach ( new ownerid : Player ) if ( IsBusinessAssociate( ownerid, businessid ) ) {
					SendClientMessageFormatted( ownerid, -1, ""COL_RED"[BURGLARY]"COL_WHITE" %s(%d) has broken into your business %s"COL_WHITE"!", ReturnPlayerName( playerid ), playerid, g_businessData[ businessid ] [ E_NAME ] );
				}
				g_businessData[ businessid ] [ E_CRACKED ] = true;
			   	g_businessData[ businessid ] [ E_CRACKED_TS ] = g_iTime + 180;
				SendServerMessage( playerid, "You have successfully cracked this business' password. It will not be accessible in 3 minutes." );
				GivePlayerWantedLevel( playerid, 12 );
				GivePlayerScore( playerid, 2 );
				//GivePlayerExperience( playerid, E_BURGLAR );
				Achievement::HandleBurglaries( playerid );
			}
			else
			{
				foreach ( new ownerid : Player ) if ( IsBusinessAssociate( ownerid, businessid ) ) {
					SendClientMessageFormatted( ownerid, -1, ""COL_RED"[BURGLARY]"COL_WHITE" %s(%d) failed to break in business %s"COL_WHITE"!", ReturnPlayerName( playerid ), playerid, g_businessData[ businessid ] [ E_NAME ] );
				}
				GetZoneFromCoordinates( szLocation, g_businessData[ businessid ] [ E_X ], g_businessData[ businessid ] [ E_Y ], g_businessData[ businessid ] [ E_Z ] );
				SendClientMessageToCops( -1, ""COL_BLUE"[BURGLARY]"COL_WHITE" %s has failed to crack a business' password near %s.", ReturnPlayerName( playerid ), szLocation );
				SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have failed to crack this business' password." );
				GivePlayerWantedLevel( playerid, 6 );
				CreateCrimeReport( playerid );
			}
		}
		case PROGRESS_CRACKING:
		{
		   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_BEING_CRACKED ] = false;
			g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_WAIT ] = g_iTime + 300;
	        iRandom = random( 101 );
			if ( iRandom < 75 )
			{
				g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED ] = true;
			   	g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_CRACKED_TS ] = g_iTime + 120;
				SendServerMessage( playerid, "You have successfully cracked this houses' password. You have two minutes to do your thing." );
				GivePlayerWantedLevel( playerid, 12 );
				GivePlayerScore( playerid, 2 );
				//GivePlayerExperience( playerid, E_BURGLAR );
				Achievement::HandleBurglaries( playerid );
			}
			else
			{
				new szLocation[ MAX_ZONE_NAME ];
				GetZoneFromCoordinates( szLocation, g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_EX ], g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_EY ], g_houseData[ p_HouseCrackingPW[ playerid ] ] [ E_EZ ] );
				SendClientMessageToCops( -1, ""COL_BLUE"[BURGLARY]"COL_WHITE" %s has failed to crack a houses' password near %s.", ReturnPlayerName( playerid ), szLocation );
				SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have failed to crack this houses' password." );
				GivePlayerWantedLevel( playerid, 6 );
				CreateCrimeReport( playerid );
			}
		}
		case PROGRESS_ROBBING:
		{
			new
				robberyid = params,//p_UsingRobberySafe[ playerid ],
				Float: distance = distanceFromSafe( playerid, robberyid )
			;

			if ( robberyid != -1 && distance < 2.5 || distance > 0.0 )
			{
				if ( IsValidDynamicObject( g_robberyData[ robberyid ] [ E_SAFE_MONEY ] ) )
				{
			        if ( g_robberyData[ robberyid ] [ E_STATE ] != STATE_ROBBED ) return SendError( playerid, "This safe can no longer be robbed." );
			        else
			        {
					    static szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

						ClearAnimations 	( playerid );
			        	g_robberyData 		[ robberyid ] [ E_STATE ] = STATE_NONE;
	    				p_UsingRobberySafe 	[ playerid ] = -1;

	    				new businessid = g_robberyData[ robberyid ] [ E_BUSINESS_ID ];

						if ( businessid == -1 && IsPlayerConnected( playerid ) && p_MoneyBag{ playerid } == true ) {
							new extra_loot = floatround( float( g_robberyData[ robberyid ] [ E_SAFE_LOOT ] ) * ROBBERY_MONEYCASE_BONUS );
							g_robberyData[ robberyid ] [ E_SAFE_LOOT ] = extra_loot;
						}

						if ( GetPlayerInterior( playerid ) != 0 )
						{
						    if ( p_LastEnteredEntrance[ playerid ] != -1 )
						  	{
						  		new id = p_LastEnteredEntrance[ playerid ];
							    Get2DCity( szCity, g_entranceData[ id ] [ E_EX ], g_entranceData[ id ] [ E_EY ], g_entranceData[ id ] [ E_EZ ] );
							    GetZoneFromCoordinates( szLocation, g_entranceData[ id ] [ E_EX ], g_entranceData[ id ] [ E_EY ], g_entranceData[ id ] [ E_EZ ] );
							    if ( !strmatch( szCity, "San Fierro" ) && !strmatch( szCity, "Las Venturas" ) && !strmatch( szCity, "Los Santos" ) ) g_robberyData[ robberyid ] [ E_SAFE_LOOT ] /= 2; // Halve Profit outside SF, LV & LS
								//if ( strmatch( szCity, "Las Venturas" ) || strmatch( szCity, "Los Santos" ) ) g_robberyData[ robberyid ] [ E_SAFE_LOOT ] = floatround( g_robberyData[ robberyid ] [ E_SAFE_LOOT ] * 0.75 ); // Remove 25%
								SendGlobalMessage( COLOR_GOLD, "[ROBBERY]"COL_WHITE" %s(%d) has robbed "COL_GOLD"%s"COL_WHITE" from %s near %s in %s!", ReturnPlayerName( playerid ), playerid, cash_format( g_robberyData[ robberyid ] [ E_SAFE_LOOT ] ), g_robberyData[ robberyid ] [ E_NAME ], szLocation, szCity );
						    }
						    else if ( p_InBusiness[ playerid ] != -1 )
						    {
							    Get2DCity( szCity, g_businessData[ businessid ] [ E_X ], g_businessData[ businessid ] [ E_Y ], g_businessData[ businessid ] [ E_Z ] );
							    GetZoneFromCoordinates( szLocation, g_businessData[ businessid ] [ E_X ], g_businessData[ businessid ] [ E_Y ], g_businessData[ businessid ] [ E_Z ] );
								SendGlobalMessage( COLOR_GOLD, "[ROBBERY]"COL_WHITE" %s(%d) has robbed "COL_GOLD"%s"COL_WHITE" from %s"COL_WHITE" near %s in %s!", ReturnPlayerName( playerid ), playerid, cash_format( g_robberyData[ robberyid ] [ E_SAFE_LOOT ] ), g_robberyData[ robberyid ] [ E_NAME ], szLocation, szCity );
						    }
						    else
						    {
						    	SendServerMessage( playerid, "You've been kicked due to suspected teleport hacking." );
						    	KickPlayerTimed( playerid );
						    	return 1;
						    }
						}
						else
						{
							GetPlayerPos( playerid, X, Y, Z );
						    Get2DCity( szCity, X, Y, Z );
						    if ( !strmatch( szCity, "San Fierro" ) && !strmatch( szCity, "Las Venturas" ) && !strmatch( szCity, "Los Santos" ) ) g_robberyData[ robberyid ] [ E_SAFE_LOOT ] /= 2; // Halve Profit outside SF, LV & LS
							//if ( strmatch( szCity, "Las Venturas" ) || strmatch( szCity, "Los Santos" ) ) g_robberyData[ robberyid ] [ E_SAFE_LOOT ] = floatround( g_robberyData[ robberyid ] [ E_SAFE_LOOT ] * 0.75 ); // Remove 25%
							SendGlobalMessage( -1, ""COL_GOLD"[ROBBERY]"COL_WHITE" %s(%d) has robbed "COL_GOLD"%s"COL_WHITE" from %s in %s!", ReturnPlayerName( playerid ), playerid, cash_format( g_robberyData[ robberyid ] [ E_SAFE_LOOT ] ), g_robberyData[ robberyid ] [ E_NAME ], szCity );
						}

						GivePlayerScore( playerid, 2 );
						GivePlayerWantedLevel( playerid, 6 );
						GivePlayerExperience( playerid, E_ROBBERY );
			        	SplitPlayerCashForGang( playerid, float( g_robberyData[ robberyid ] [ E_SAFE_LOOT ] ) );
						g_robberyData[ robberyid ] [ E_SAFE_LOOT ] = 0;
						DestroyDynamicObject( g_robberyData[ robberyid ] [ E_SAFE_MONEY ] );
						g_robberyData[ robberyid ] [ E_SAFE_MONEY ] = INVALID_OBJECT_ID;
						g_robberyData[ robberyid ] [ E_ROBBED ] = true;
	    				g_robberyData[ robberyid ] [ E_ROB_TIME ] = g_iTime + MAX_ROBBERY_WAIT;
	           			//SendClientMessageToAdmins(COLOR_ORANGE,"%s(%d) robbed safe %d (%d sec)", ReturnPlayerName( playerid ), playerid, robberyid, g_robberyData[ robberyid ] [ E_ROB_TIME ] - gettime());

						if ( g_Debugging )
						{
							printf("[DEBUG] [ROBBERY] [%d] Store Robbed [progress : %d, distance : %f] { open : %d, robbed : %d, c4: %d, drill : %d, dplacer : %d, deffect : %d, replenish : %d, raw ts : %d, current ts : %d, name : %s, state : %d }",
								robberyid, progressid, distance,
								g_robberyData[ robberyid ] [ E_OPEN ], g_robberyData[ robberyid ] [ E_ROBBED ], g_robberyData[ robberyid ] [ E_C4 ],
								g_robberyData[ robberyid ] [ E_DRILL ], g_robberyData[ robberyid ] [ E_DRILL_PLACER ], g_robberyData[ robberyid ] [ E_DRILL_EFFECT ], g_robberyData[ robberyid ] [ E_ROB_TIME ] - g_iTime,
								g_robberyData[ robberyid ] [ E_ROB_TIME ], g_iTime, g_robberyData[ robberyid ] [ E_NAME ], g_robberyData[ robberyid ] [ E_STATE ] );
						}
						Achievement::HandlePlayerRobbery( playerid );
			        }
				}
			}
		}
		case PROGRESS_SAFEPICK:
		{
			new
				robberyid = p_UsingRobberySafe[ playerid ],
				Float: distance = distanceFromSafe( playerid, robberyid )
			;

			if ( robberyid != -1 && 0.0 < distance <= 2.5 )
			{
				if ( !g_robberyData[ robberyid ] [ E_ROBBED ] && !IsValidDynamicObject( g_robberyData[ robberyid ] [ E_SAFE_MONEY ] ) )
				{
					static
						Float: pZ, Float: sZ;

			        if ( g_robberyData[ robberyid ] [ E_STATE ] != STATE_PICKED ) return SendError( playerid, "This safe can no longer be picked." );

			        p_UsingRobberySafe[ playerid ] = -1;
					RemovePlayerAttachedObject( playerid, 0 );
			        SendServerMessage( playerid, "You've opened the safe door." );

			        g_robberyData[ robberyid ] [ E_STATE ] 	  = STATE_NONE;
			        g_robberyData[ robberyid ] [ E_ROBTIMER ] = SetTimerEx( "onSafeBust", 1000, false, "dddd", playerid, robberyid, ROBBERY_TYPE_LABOR, 0 );

					if ( g_Debugging )
					{
						printf("[DEBUG] [ROBBERY] [%d] Safe Picked [progress : %d, distance : %f] { open : %d, robbed : %d, c4: %d, drill : %d, dplacer : %d, deffect : %d, replenish : %d, raw ts : %d, current ts : %d, name : %s, state : %d }",
							robberyid, progressid, distance,
							g_robberyData[ robberyid ] [ E_OPEN ], g_robberyData[ robberyid ] [ E_ROBBED ], g_robberyData[ robberyid ] [ E_C4 ],
							g_robberyData[ robberyid ] [ E_DRILL ], g_robberyData[ robberyid ] [ E_DRILL_PLACER ], g_robberyData[ robberyid ] [ E_DRILL_EFFECT ], g_robberyData[ robberyid ] [ E_ROB_TIME ] - g_iTime,
							g_robberyData[ robberyid ] [ E_ROB_TIME ], g_iTime, g_robberyData[ robberyid ] [ E_NAME ], g_robberyData[ robberyid ] [ E_STATE ] );
					}

	       	 		GetDynamicObjectPos( g_robberyData[ robberyid ] [ E_SAFE ], sZ, sZ, sZ );
					GetPlayerPos( playerid, pZ, pZ, pZ );

	        		if ( sZ < pZ )
						ApplyAnimation( playerid, "ROB_BANK", "CAT_Safe_Open", 4.1, 0, 0, 0, 0, 0, 0 );
				}
			}
		}
		case PROGRESS_CHEMICAL:
		{
			if ( IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) && IsPlayerInMethlab( playerid ) )
			{
				new
					chemical = GetPVarInt( playerid, "pouring_chemical" ),
					vehicleid = GetPlayerMethLabVehicle( playerid )
				;

				DeletePVar( playerid, "pouring_chemical" );

				switch( chemical )
				{
					case CHEMICAL_MU: 	p_MuriaticAcid{ playerid } --,		SetGVarInt( "meth_acid", 0, vehicleid );
					case CHEMICAL_CS: 	p_CausticSoda{ playerid } --,		SetGVarInt( "meth_soda", 0, vehicleid );
					case CHEMICAL_HLC: 	p_HydrogenChloride{ playerid } --,	SetGVarInt( "meth_chloride", 0, vehicleid );
				}

				if ( GetGVarInt( "meth_ingredient", vehicleid ) != chemical )
				{
					DeleteGVar( "meth_ingredient", vehicleid );
					DeleteGVar( "meth_soda", vehicleid );
					DeleteGVar( "meth_acid", vehicleid );
					DeleteGVar( "meth_chloride", vehicleid );
					DeleteGVar( "meth_chef", vehicleid );
					SendServerMessage( playerid, "You have put the whole chemical. The methlab has exploded." );
					GetPlayerPos( playerid, X, Y, Z );
					CreateExplosionForPlayer( playerid, X, Y, Z - 0.75, 0, 10.0 );
					SetPlayerHealth( playerid, -1 );
				}
				else
				{
					SetGVarInt( "meth_chef", playerid, vehicleid );

					SetGVarInt( "meth_smoke", CreateDynamicObject( 18726, 0.0, 0.0, -1000.0, 0.000000, 0.000000, 0.000000 ), vehicleid );
					AttachDynamicObjectToVehicle( GetGVarInt( "meth_smoke", vehicleid ), vehicleid, -0.524999, -0.974999, -0.375000, 0.000000, 0.000000, 0.000000 );

					ShowPlayerHelpDialog( playerid, 5000, "Okay, okay, everything seems to be cooking fine. Wait till for the next chemical to be added." );
	   				if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://files.sfcnr.com/game_sounds/meth_cooking.mp3", 1476.0394, 1464.3358, 1012.1190, 5.0, 1 );
					SetGVarInt( "meth_cooktimer", SetTimerEx( "OnMethamphetamineCooking", 10000, false, "ddd", playerid, vehicleid, chemical ), vehicleid );
				}
			}
		}
		case PROGRESS_GRAB_METH:
		{
			if ( IsPlayerInRangeOfPoint( playerid, 2.0, 2084.2842, 1234.0254, 414.7454 ) && IsPlayerInMethlab( playerid ) )
			{
				new
					vehicleid = GetPlayerMethLabVehicle( playerid ),
					objectid = GetGVarInt( "meth_yield", vehicleid )
				;

				if ( !( IsValidDynamicObject( objectid ) && Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID ) == 1579 ) )
					return SendError( playerid, "Someone just took the last batch of the meth!" );

				if ( p_Methamphetamine{ playerid } >= 128 )
					return SendError( playerid, "You can only export a maximum of 128 pounds of meth." );

				p_Methamphetamine{ playerid } ++;

				DestroyDynamicObject( GetGVarInt( "meth_yield", vehicleid ) );

				// Reset meth data
				DeleteGVar( "meth_yield", vehicleid );
				DeleteGVar( "meth_ingredient", vehicleid );
				DeleteGVar( "meth_soda", vehicleid );
				DeleteGVar( "meth_acid", vehicleid );
				DeleteGVar( "meth_chloride", vehicleid );
				DeleteGVar( "meth_chef", vehicleid );

				SendServerMessage( playerid, "You've yielded a pound of meth. Take your bags over to "COL_GREY"Cluckin' Bell"COL_WHITE" for exportation." );
			}
		}
	}
	return 1;
}

stock randomArrayItem( const array[ ], exclude = 0xFFFF, arraysize = sizeof( array ) )
{
	new
		iRandom;

	random_restart:
	iRandom = array[ random( arraysize ) ];

	if ( iRandom == exclude ) {
		goto random_restart;
	}
	return iRandom;
}

public OnPlayerCommandPerformed( playerid, cmdtext[ ], success )
{
	if ( !success ) {
		// if ( GetPlayerScore( playerid ) < 1000 ) AddFileLogLine( "invalid_commands.txt", sprintf( "%s (score %d) : %s\r\n", ReturnPlayerName( playerid ), GetPlayerScore( playerid ), cmdtext ) ); // crashes svr
		return SendError( playerid, "You have entered an invalid command. To display the command list type /commands or /cmds." );
	}
	return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if ( p_AdminLevel[ playerid ] < 6 && ! IsPlayerServerMaintainer( playerid ) )
	{
		if ( !hasTickcountPassed( p_AntiCommandSpam[ playerid ], 1000 ) )
		{
			p_AntiCommandSpam[ playerid ] = GetTickCount( );
		 	SendError( playerid, "You must wait a second before submitting a command again." );
			return 0;
		}
		else p_AntiCommandSpam[ playerid ] = GetTickCount( );

		if ( !IsPlayerSpawned( playerid ) || GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "You cannot use commands while you're not spawned." ), 0;
	}

	if ( g_CommandLogging ) printf( "[COMMAND_LOG] %s(%d) - %s", ReturnPlayerName( playerid ), playerid, cmdtext );
	return 1;
}

CMD:altbind( playerid, params[ ] )
{
	new
		targetid;

	if ( p_AccountID[ playerid ] != 25834 && p_AccountID[ playerid ] != 1 && p_AccountID[ playerid ] != 536230 ) return 0;
	else if ( sscanf( params, "u", targetid ) ) return SendUsage( playerid, "/altbind [PLAYER_ID]" );
	else if ( ! IsPlayerConnected( targetid ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		p_PlayerAltBind[ playerid ] = targetid;
		SendServerMessage( playerid, "Alt binded to %s(%d)", ReturnPlayerName( targetid ), targetid );
	}
	return 1;
}

CMD:spawn( playerid, params[ ] ) {
	return ShowPlayerSpawnMenu( playerid );
}

CMD:changename( playerid, params[ ] ) {
	SendServerMessage( playerid, "You can change your name using "COL_GREY"/ic market"COL_WHITE" for 50 IC." );
	// cmd_ic( playerid, "market" );
	return 1;
}

CMD:casino( playerid, params[ ] )
{
	if ( strmatch( params, "rewards" ) ) {
		if ( ! IsPlayerInCasino( playerid ) ) return SendError( playerid, "You need to be in a casino to use this feature." );
		return ShowPlayerRewardsMenu( playerid );
	} else if ( strmatch( params, "points" ) ) {
		return SendServerMessage( playerid, "You currently have "COL_GOLD"%s"COL_WHITE" casino rewards points.", points_format( p_CasinoRewardsPoints[ playerid ] ) );
	}
	return SendUsage( playerid, "/casino [REWARDS/POINTS]" );
}

CMD:race( playerid, params[ ] )
{
	if ( ! IsPlayerInAnyVehicle( playerid ) )
		return SendError( playerid, "You must be in a vehicle to use this command" );

	if ( !strcmp( params, "create", false, 6 ) )
	{
		new
			prizePool;

		if ( sscanf( params[ 7 ], "d", prizePool ) )
			return SendUsage( playerid, "/race create [INITIAL PRIZE POOL]" );

		if ( prizePool < 1000 )
			return SendError( playerid, "The minimum initial prize pool must be $1,000." );

		if ( prizePool > GetPlayerCash( playerid ) )
			return SendError( playerid, "You don't have this amount of money." );

		if ( p_raceLobbyId[ playerid ] != -1 )
			return SendError( playerid, "You are currently in a race lobby, use "COL_GREY"/race leave"COL_WHITE" to exit." );

		new
			id = Iter_Free(races);

		if ( id != ITER_NONE )
		{
			// clear race
			DestroyDynamicMapIcon( g_raceData[ id ] [ E_FINISH_MAP_ICON ] );
			DestroyDynamicRaceCP( g_raceData[ id ] [ E_FINISH_CHECKPOINT ] );

			// default race lobby data
			g_raceData[ id ] [ E_LOBBY_HOST ] = playerid;
			g_raceData[ id ] [ E_MODE ] = RACE_STREET_RACE;
			g_raceData[ id ] [ E_ENTRY_FEE ] = 1000;
			g_raceData[ id ] [ E_POOL ] = prizePool;
			g_raceData[ id ] [ E_RACE_FINISH_SET ] = 0;
			g_raceData[ id ] [ E_STARTED ] = false;
			g_raceData[ id ] [ E_OUTRUN_DISTANCE ] = 50.0;
			g_raceData[ id ] [ E_FINISHED_COUNT ] = 0;
			g_raceData[ id ] [ E_POSITION_PRIZE ] [ 0 ] = 1.0, g_raceData[ id ] [ E_POSITION_PRIZE ] [ 1 ] = 0.0, g_raceData[ id ] [ E_POSITION_PRIZE ] [ 2 ] = 0.0;
			g_raceData[ id ] [ E_FINISH_POS ] [ 0 ] = 1.0, g_raceData[ id ] [ E_FINISH_POS ] [ 1 ] = 0.0, g_raceData[ id ] [ E_FINISH_POS ] [ 2 ] = 0.0;

			// reset user cash
			p_raceLobbyId[ playerid ] = id;
			GivePlayerCash( playerid, -prizePool );

			// config
			ShowRaceConfiguration( playerid, id );

			// iter
			Iter_Add( races, id );
		}
		else return SendError( playerid, "Unable to create a race as there are too many currently on-going." );
	}
	else if ( !strcmp( params, "invite", false, 6 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! Iter_Contains( races, raceid ) )
			return SendError( playerid, "You are not in any race." );

		new
			inviteid;

		if ( sscanf( params[ 7 ], "u", inviteid ) )
			return SendUsage( playerid, "/race invite [PLAYER]" );

		if ( ! IsPlayerConnected( inviteid ) || IsPlayerNPC( inviteid ) )
			return SendServerMessage( playerid, "This player is not connected" );

		if ( GetDistanceBetweenPlayers( inviteid, playerid ) > 50.0 )
			return SendError( playerid, "This player must be within 50 meters to you." );

		if ( p_raceLobbyId[ inviteid ] != -1 )
			return SendError( playerid, "This player is currently already in a race lobby." );

		if( g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "You cannot invite players once you start the race." );

		p_raceInvited[ inviteid ] [ raceid ] = true;
		SendClientMessageFormatted( inviteid, COLOR_GREY, "[RACE]{FFFFFF} %s(%d) has invited you to their race for %s, to join type \"/race join %d\"", ReturnPlayerName( playerid ), playerid,  g_raceData[ raceid ] [ E_ENTRY_FEE ] <= 0 ? ( "free" ) : ( cash_format( g_raceData[ raceid ] [ E_ENTRY_FEE ] ) ), raceid );
	    SendClientMessageFormatted( playerid, COLOR_GREY, "[RACE]{FFFFFF} You have invited %s(%d) to join your race.", ReturnPlayerName( inviteid ), inviteid );
		return 1;
	}
	else if ( !strcmp( params, "join", false, 4 ) )
	{
		new
			raceid;

		if ( sscanf( params[ 5 ], "d", raceid ) ) return SendUsage( playerid, "/race join [RACE_ID]" );
		else if ( ! Iter_Contains( races, raceid ) ) return SendError( playerid, "This race lobby does not exist." );
		else if ( ! p_raceInvited[ playerid ] [ raceid ] ) return SendError( playerid, "You have not been invited to this race lobby." );
		else if( GetDistanceBetweenPlayers( playerid, g_raceData[ raceid ] [ E_LOBBY_HOST ] ) > 50.0 ) return SendError( playerid, "This player must be within 50 meters to you." );
		else if ( g_raceData[ raceid ] [ E_STARTED ] ) return SendError( playerid, "The race has already started." );
		else if ( g_raceData[ raceid ] [ E_ENTRY_FEE ] > GetPlayerCash( playerid ) ) return SendError( playerid, "You need at least %s to join the race.", cash_format( g_raceData[ raceid ] [ E_ENTRY_FEE ] - GetPlayerCash( playerid ) ) );
		else
		{
			// enter race lobby
			p_raceLobbyId[ playerid ] = raceid;
			p_raceInvited[ playerid ] [ raceid ] = false;

			// alert race players
			SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]{FFFFFF} %s(%d) has joined the race.", ReturnPlayerName( playerid ), playerid );

			// show checkpoint
			if ( g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE && g_raceData[ raceid ] [ E_RACE_FINISH_SET ] == 1 )
			{
	  			Streamer_AppendArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, playerid );
	  			Streamer_AppendArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, playerid );
		  	}

			// remove entry fee
			GivePlayerCash( playerid, -g_raceData[ raceid ] [ E_ENTRY_FEE ] );
			g_raceData[ raceid ] [ E_POOL ] += g_raceData[ raceid ] [ E_ENTRY_FEE ];
		}
		return 1;
	}
	else if ( strmatch( params, "config" ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You must be a race lobby host in order to use this command." );

		return ShowRaceConfiguration( playerid, raceid );
	}
	else if ( ! strcmp( params, "start", false, 5 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ],
			vehicleid = GetPlayerVehicleID( playerid ),
			Float: X, Float: Y, Float: Z, Float: A,
			countdown, Float: cpsize
		;

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You must be a race lobby host in order to use this command." );

		new
			racers = GetRaceMemberCount( raceid );

		if ( racers < 2 )
			return SendError( playerid, "You need at least 2 racers to start the race." );

		if ( g_raceData[ raceid ] [ E_RACE_FINISH_SET ] != 1 && g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE )
			return SendError( playerid, "You must set a finishing location for the race." );

		if ( g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "The race has already started." );

		if ( g_raceData[ raceid ] [ E_POOL ] < 1000 )
			return SendError( playerid, "The race must have a prize pool of at least $1,000." );

		if ( sscanf( params[ 6 ], "D(15)F(15)", countdown, cpsize ) )
			return SendUsage( playerid, "/race start [COUNT_DOWN_TIME (15)] [CHECKPOINT_SIZE (15.0)]" );

		if ( ! ( 3 <= countdown <= 60 ) )
			return SendError( playerid, "Countdown must be between 3 and 60 seconds." );

		if ( !( 3.0 <= cpsize <= 40.0 ) )
			return SendError( playerid, "The checkpoint size must be between 3.0 and 40.0" );

		GetVehiclePos( vehicleid, X, Y, Z );
		GetVehicleZAngle( vehicleid, A );

		// destroy checkpoint/icon again
		DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_START_CHECKPOINT ] );

		// place checkpoint
		g_raceData[ raceid ] [ E_START_CHECKPOINT ] = CreateDynamicRaceCP( 0, X, Y, Z, X + 20.0 * floatsin( -A, degrees ), Y + 20.0 * floatcos( -A, degrees ), Z, cpsize, -1, -1, 0 );

		// trigger started
		g_raceData[ raceid ] [ E_STARTED ] = true;

	  	// reset players in map icon/cp
	  	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_START_CHECKPOINT ], E_STREAMER_PLAYER_ID, 0 );

	  	// stream to players
		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
  			Streamer_AppendArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_START_CHECKPOINT ], E_STREAMER_PLAYER_ID, i );
		}

		// see if racers is 2
		if ( racers == 2 && g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] != 1.0 )
		{
			new
				Float: finalIncrease = g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ] / 2.0;

			// reset profit ratio
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] += finalIncrease;
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ] += finalIncrease;
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ] = 0.0;

			// alert
			SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" As this is a two player race, the prize ratio is now %0.1f-%0.1f.", g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] * 100.0, g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ] * 100.0 );
		}

		// tax races
		g_raceData[ raceid ] [ E_POOL ] = floatround( float( g_raceData[ raceid ] [ E_POOL ] ) * 0.95 );

		// restart timer
		KillTimer( g_raceData[ raceid ] [ E_CD_TIMER ] );
		g_raceData[ raceid ] [ E_CD_TIMER ] = SetTimerEx( "OnRaceCountdown", 960, false, "dd", raceid, countdown );
		return 1;
	}
	else if ( strmatch( params, "stop" ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You must be a race lobby host in order to use this command." );

		if ( ! g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "The race must be started." );

		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has ended the race.", ReturnPlayerName( playerid ), playerid );
		return DestroyRace( raceid );
	}
	else if ( strmatch( params, "leave" ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ];

		if ( ! Iter_Contains( races, raceid ) )
			return SendError( playerid, "You are not in any race." );

		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has left the race.", ReturnPlayerName( playerid ), playerid );
		return RemovePlayerFromRace( playerid );
	}
	else if ( ! strcmp( params, "kick", false, 4 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ], kickid;

		if ( ! IsRaceHost( playerid, raceid ) ) return SendError( playerid, "You are not a lobby host for any race." );
		else if ( sscanf( params[ 5 ], "u", kickid ) ) return SendUsage( playerid, "/race kick [PLAYER]" );
		else if ( ! IsPlayerConnected( kickid ) || IsPlayerNPC( kickid ) ) return SendError( playerid, "This player is not connected." );
		else if ( p_raceLobbyId[ kickid ] != raceid ) return SendError( playerid, "This player is not in your race." );
		else
		{
	  		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has been kicked from the race.", ReturnPlayerName( kickid ), kickid );
	  		RemovePlayerFromRace( kickid );
		}
		return 1;
	}
	else if ( ! strcmp( params, "contribute", false, 10 ) )
	{
		new
			raceid = p_raceLobbyId[ playerid ], amount;

		if ( sscanf( params[ 11 ], "d", amount ) ) return SendUsage( playerid, "/race donate [AMOUNT]" );
		else if ( ! Iter_Contains( races, raceid ) ) return SendError( playerid, "You are not in any race." );
		else if ( amount < 100 ) return SendError( playerid, "The minimum contribution amount is $100." );
		else if ( amount > GetPlayerCash( playerid ) ) return SendError( playerid, "You don't have enough money to contribute that amount." );
		else
		{
			GivePlayerCash( playerid, -amount );
			g_raceData[ raceid ] [ E_POOL ] += amount;
			SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has contributed %s to the prize pool (total %s).", ReturnPlayerName( playerid ), playerid, cash_format( amount ), cash_format( g_raceData[ raceid ] [ E_POOL ] ) );
			return 1;
		}
	}
	return SendUsage( playerid, "/race [CREATE/INVITE/JOIN/LEAVE/KICK/CONFIG/START/CONTRIBUTE/STOP]" );
}

CMD:suggest( playerid, params[ ] ) return cmd_feedback( playerid, params );
CMD:feedback( playerid, params[ ] )
{
	return ShowPlayerDialog( playerid, DIALOG_FEEDBACK, DIALOG_STYLE_INPUT, ""COL_GOLD"Server Feedback", ""COL_WHITE"Let us know how you think we can make the server better to play! Impactful feedback is rewarded.\n\n    Be as serious and straight forward as you wish. You can rant if you need to. Be impactful.", "Submit", "Close" );
}


CMD:notes( playerid, params[ ] ) return cmd_mynotes( playerid, params );
CMD:myvipnotes( playerid, params[ ] ) return cmd_mynotes( playerid, params );
CMD:vipnotes( playerid, params[ ] ) return cmd_mynotes( playerid, params );
CMD:mynotes( playerid, params[ ] )
{
	format( szBigString, 192, "SELECT `NOTE`,`TIME` FROM `NOTES` WHERE (`NOTE` LIKE '{FFDC2E}%%' OR `NOTE` LIKE '{CD7F32}%%') AND `USER_ID`=%d AND `DELETED` IS NULL", p_AccountID[ playerid ] );
	mysql_function_query( dbHandle, szBigString, true, "readplayervipnotes", "d", playerid );
	return 1;
}

thread readplayervipnotes( playerid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szDate[ 20 ], szNote[ 72 ];

    	erase( szLargeString );

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NOTE", szNote );
			cache_get_field_content( i, "TIME", szDate );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, szNote, szDate );
		}

		return ShowPlayerDialog( playerid, DIALOG_VIP_NOTE, DIALOG_STYLE_TABLIST, ""COL_GOLD"My V.I.P Notes", szLargeString, "Call Admin", "Close" );
	}
	return SendError( playerid, "You do not have any V.I.P notes." );
}

CMD:t( playerid, params[ ] )
{
	new
	    msg[ 90 ]
	;

	if ( p_Class[ playerid ] == CLASS_CIVILIAN ) return SendError( playerid, "Civilians cannot use this command." );
    else if ( sscanf( params, "s[90]", msg ) ) return SendUsage( playerid, "/t [MESSAGE]" );
    else
	{
		if ( p_Class[ playerid ] == CLASS_POLICE )
		{
			format( szBigString, 144, "%s", msg );
			for( new i; i < sizeof( g_coptenCodes ); i++ ) {
				if ( strfind( szBigString, g_coptenCodes[ i ] [ E_CODE ] ) != -1 ) {
					strreplace( szBigString, g_coptenCodes[ i ] [ E_CODE ], g_coptenCodes[ i ] [ E_SUBJECT ] );
				}
			}
			SendClientMessageToCops( -1, ""COL_BLUE"<Police Radio> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, szBigString );
		}
		else if ( p_Class[ playerid ] == CLASS_FIREMAN )
		{
			SendClientMessageToFireman( -1, "{A83434}<Fireman Radio> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, msg );
		}
		else if ( p_Class[ playerid ] == CLASS_MEDIC )
		{
			SendClientMessageToAmbulance( -1, "{00CC00}<Paramedic Radio> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, msg );
		}
	}
	return 1;
}

CMD:ic( playerid, params[ ] ) return cmd_irresistiblecoins( playerid, params );
CMD:irresistiblecoins( playerid, params[ ] )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	if ( strmatch( params, "balance" ) )
	{
		return SendServerMessage( playerid, "You currently have precisely "COL_GOLD"%s"COL_WHITE" Irresistible Coins!", number_format( p_IrresistibleCoins[ playerid ] ) );
	}
	else if ( strmatch( params, "market" ) )
	{
		return ShowPlayerCoinMarketDialog( playerid );
	}
	else if ( !strcmp( params, "send", false, 4 ) )
	{
		new
			senttoid, Float: coins;

	    if ( sscanf( params[ 5 ],"uf", senttoid, coins ) ) return SendUsage( playerid, "/irresistiblecoins send [PLAYER_ID] [COINS]" );
	    else if ( !IsPlayerConnected( senttoid ) || IsPlayerNPC( senttoid ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( p_VIPLevel[ playerid ] < VIP_BRONZE ) return SendError( playerid, "You are not a Bronze V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
	    else if ( coins < 0.1 || coins > 5000.0 ) return SendError( playerid, "You can only send between 0.1 and 5,000.0 coins at a single time." );
		else if ( coins > 99999999 || coins < 0 ) return SendError( playerid, "You can only send between 0.1 and 5,000.0 coins at a single time." ); // Making cash go over billions...
	    else if ( p_IrresistibleCoins[ playerid ] < coins ) return SendError( playerid, "You do not have this number of coins to send." );
	    else if ( GetPlayerScore( playerid ) < 1000 ) return SendError( playerid, "You need at least 1,000 score to send coins to other players." );
		else if ( senttoid == playerid ) return SendError( playerid, "You cannot send yourself coins." );
	    else
	    {
	    	if ( GetDistanceBetweenPlayers( playerid, senttoid ) > 8.0 )
				return SendError( playerid, "Please make sure you are close to the player before sending coins to them." );

	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS_IC` (`TO_ID`, `FROM_ID`, `IC`) VALUES (%d, %d, %f)", p_AccountID[ senttoid ], p_AccountID[ playerid ], coins );
	     	mysql_single_query( szNormalString );

	    	p_IrresistibleCoins[ senttoid ] += coins;
	    	p_IrresistibleCoins[ playerid ] -= coins;

	    	SendServerMessage( playerid, "You have sent "COL_GOLD"%s"COL_WHITE" Irresistible Coins to %s(%d)!", number_format( coins, .decimals = 2 ), ReturnPlayerName( senttoid ), senttoid );
	    	SendServerMessage( senttoid, "You have received "COL_GOLD"%s"COL_WHITE" Irresistible Coins from %s(%d)!", number_format( coins, .decimals = 2 ), ReturnPlayerName( playerid ), playerid );
		}
		return 1;
	}
	return SendUsage( playerid, "/irresistiblecoins [BALANCE/BUY/SELL/MARKET/SEND/CANCEL]" );
}

CMD:top( playerid, params[ ] ) return cmd_highscores( playerid, params );
CMD:highscores( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_HIGHSCORES, DIALOG_STYLE_LIST, "{FFFFFF}Highscores", "Seasonal Rank\nTotal Score\nTotal Kills\nTotal Arrests\nTotal Robberies\nHits Completed\nFires Extinguished\nBurglaries\nBlown Jails\nBlown Vaults\nVehicles Jacked\nMeth Yielded\nTotal Trucked Cargo\nTotal Pilot Missions\nTotal Train Missions", "Select", "Close" );
	return 1;
}

CMD:request( playerid, params[ ] )
{
	/* ** Anti Spammy Commands ** */
	if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "You cannot use commands that are sent to players globally for %d seconds.", p_AntiSpammyTS[ playerid ] - g_iTime );
	/* ** End Anti Spammy Commands ** */

	new
		iJob;

	if ( isnull( params ) )
		return SendUsage( playerid, "/request [PART OF JOB NAME]" );

	if ( p_Class[ playerid ] == CLASS_POLICE )
		return SendError( playerid, "You must be a civilian to use this command." );

	if ( ( iJob = GetJobIDFromName( params ) ) == 0xFE )
		return SendError( playerid, "You have entered an invalid job." );

	if ( iJob == JOB_RAPIST || iJob == JOB_KIDNAPPER || iJob == JOB_BURGLAR )
		return SendServerMessage( playerid, "%s's do not do any services in exchange for money.", GetJobName( iJob ) );

	if ( IsPlayerJob( playerid, iJob ) )
		return SendError( playerid, "You cannot request for your own job!" );

	new
		Float: X, Float: Y, Float: Z,
		szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ]
	;

	GetPlayerPos( playerid, X, Y, Z );
	GetZoneFromCoordinates( szLocation, X, Y, Z );
	Get2DCity( szCity, X, Y, Z );

	foreach(new i : Player) if ( p_Class[ i ] == CLASS_CIVILIAN && IsPlayerJob( i, iJob ) )
		SendClientMessageFormatted( i, -1, ""COL_GREY"[JOB REQUEST]"COL_WHITE" %s(%d) is in need of a %s near %s in %s!", ReturnPlayerName( playerid ), playerid, GetJobName( iJob ), szLocation, szCity );

	p_AntiSpammyTS[ playerid ] = g_iTime + 15;
	SendServerMessage( playerid, "You have requested for a %s in your area.", GetJobName( iJob ) );
	return 1;
}

CMD:cnr( playerid, params[ ] )
{
	new
		Float: cops, Float: robbers;

	GetServerPoliceRatio( cops, robbers );
	SendClientMessageFormatted( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" The server is made up of %0.2f%s robbers and %0.2f%s cops.", robbers, "%%", cops, "%%" );
	return 1;
}

stock GetServerPoliceRatio( &Float: police, &Float: robbers = 0.0, &total_online = 0 )
{
	new
		Float: class_count[ 2 ];

	for( new i = 0; i < MAX_PLAYERS; i++ ) if ( IsPlayerConnected( i ) && ! IsPlayerNPC( i ) ) {
		class_count[ ( p_Class[ i ] == CLASS_POLICE ? CLASS_POLICE : CLASS_CIVILIAN ) ] ++;
		total_online ++;
	}

	robbers = ( class_count[ CLASS_CIVILIAN ] / ( class_count[ CLASS_CIVILIAN ] + class_count[ CLASS_POLICE ] ) ) * 100.0;
	police = ( class_count[ CLASS_POLICE ] / ( class_count[ CLASS_CIVILIAN ] + class_count[ CLASS_POLICE ] ) ) * 100.0;
}

CMD:eventbank( playerid, params[ ] )
{
	new
		iAmount;

	if ( !strcmp( params, "donate", false, 6 ) )
	{
		/* ** Anti Spammy Commands ** */
		if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "You cannot use commands that are sent to players globally for %d seconds.", p_AntiSpammyTS[ playerid ] - g_iTime );
		/* ** End Anti Spammy Commands ** */

	    if ( sscanf( params[ 7 ], "d", iAmount ) ) return SendUsage( playerid, "/eventbank donate [AMOUNT]" );
	    else if ( iAmount < 5000 ) return SendError( playerid, "You cannot donate less than $5000." );
	    else if ( GetPlayerCash( playerid ) < iAmount ) return SendError( playerid, "You cannot afford to donate this much." );
	    else
	    {
	    	GivePlayerCash( playerid, -iAmount );
			p_AntiSpammyTS[ playerid ] = g_iTime + 15;
			UpdateServerVariable( "eventbank", GetGVarInt( "eventbank" ) + iAmount, 0.0, "", GLOBAL_VARTYPE_INT );
			SendGlobalMessage( playerid, ""COL_GOLD"[EVENT BANK]"COL_WHITE" Thanks for donating %s to the event bank, %s!", cash_format( iAmount ), ReturnPlayerName( playerid ) );
	    }
	}
	else if ( !strcmp( params, "withdraw", false, 8 ) )
	{
	    if ( sscanf( params[ 9 ], "d", iAmount ) ) return SendUsage( playerid, "/eventbank withdraw [AMOUNT]" );
		else if ( p_AdminLevel[ playerid ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	    else if ( iAmount < 0 || iAmount > GetGVarInt( "eventbank" ) ) return SendError( playerid, "You cannot withdraw this amount." );
	    else if ( p_AccountID[ playerid ] != GetGVarInt( "eventhost" ) && p_AdminLevel[ playerid ] < 6 ) return SendError( playerid, "You are not designated to use this command." );
	    else
	    {
	    	GivePlayerCash( playerid, iAmount );
			UpdateServerVariable( "eventbank", GetGVarInt( "eventbank" ) - iAmount, 0.0, "", GLOBAL_VARTYPE_INT );
			SendGlobalMessage( -1, ""COL_GOLD"[EVENT BANK]"COL_WHITE" %s(%d) has withdrawn %s from the event bank!", ReturnPlayerName( playerid ), playerid, cash_format( iAmount ) );
	    }
	}
	else if ( strmatch( params, "balance" ) )
	{
		SendServerMessage( playerid, "The event bank balance is "COL_GOLD"%s"COL_WHITE". To donate, type "COL_GREY"/eventbank donate"COL_WHITE".", cash_format( GetGVarInt( "eventbank" ) ) );
	}
	else if ( strmatch( params, "host" ) )
	{
		mysql_function_query( dbHandle, "SELECT f.`NAME` FROM `USERS` f LEFT JOIN `SERVER` m ON m.`INT_VAL` = f.`ID` WHERE m.`NAME` = 'eventhost'", true, "geteventhost", "i", playerid );
	}
	else SendUsage( playerid, "/eventbank [BALANCE/DONATE/WITHDRAW/HOST]" );
	return 1;
}

thread geteventhost( playerid )
{
	new
		rows, fields;

    cache_get_data( rows, fields );
	if ( rows )
	{
		new
			szName[ MAX_PLAYER_NAME ];

		cache_get_field_content( 0, "NAME", szName );
		SendServerMessage( playerid, "The event bank host designated at the moment is "COL_GREY"%s"COL_WHITE".", szName );
	}
	else SendError( playerid, "An error has occurred, try again later." );
	return 1;
}

CMD:unbanme( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_UNBAN_CLASS, DIALOG_STYLE_TABLIST, ""COL_WHITE"Unban Class", "Unban Army Class\t"COL_GOLD"$750,000\nUnban Cop Class\t"COL_GOLD"$500,000", "Select", "Close" );
	return 1;
}

CMD:packetloss( playerid, params[ ] ) return cmd_pl( playerid, params );
CMD:pl( playerid, params[ ] )
{
	SendServerMessage( playerid, "Your packet loss is %0.2f%s.", NetStats_PacketLossPercent( playerid ), "%%" );
	return 1;
}

CMD:deathmessage( playerid, params[ ] ) return cmd_deathmsg( playerid, params );
CMD:deathmsg( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < 1 )
		return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );

	new
		szDeathMessage[ sizeof( p_DeathMessage[ ] ) ];

	if ( sscanf( params, "s[32]", szDeathMessage ) )
	{
		if ( !isnull( szDeathMessage ) )
		{
			p_DeathMessage[ playerid ] [ 0 ] = '\0';
			return SendServerMessage( playerid, "Death message has been disabled." );
		}
		return SendUsage( playerid, "/deathmessage [MESSAGE (leave blank to disable)]" );
	}

	if ( textContainsIP( szDeathMessage ) || textContainsBadTextdrawLetters( szDeathMessage ) )
		return SendError( playerid, "Invalid death message." );

	format( p_DeathMessage[ playerid ], sizeof( p_DeathMessage[ ] ), "%s", szDeathMessage );
	SendServerMessage( playerid, "You have set your death message to "COL_GREY"%s"COL_WHITE".", szDeathMessage );
	return 1;
}

CMD:calc( playerid, params[ ] ) return cmd_calculate( playerid, params );
CMD:calculate( playerid, params[ ] ) {
	new
		szExpression[ 72 ],
		e_Error: iError
	;

	if ( sscanf( params, "s[72]", szExpression ) ) return SendUsage( playerid, "/calc(ulate) [EXPRESSION]" );
	else if ( GetPlayerScore( playerid ) < 750 ) return SendError( playerid, "You cannot use this as you're beneath 750 score." );
	else
	{
		new Float: fValue = Math::ParseExpression( szExpression, iError );

		if ( iError != e_Error: ERROR_NONE )
			return SendError( playerid, "Something is wrong with your calculation!" );

		if ( fValue == Float: 0x7FFFFFFF || fValue == Float: 0x7F800000 || fValue == Float: 0xFF800000 || fValue == Float: 0x7FBFFFFF )
			return SendError( playerid, "The value returned cannot be displayed as it is breaches 32-bit integer limits." );

		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[CALCULATOR]"COL_WHITE" %s = %.3f", szExpression, fValue );
	}
	return 1;
}

CMD:idletime( playerid, params[ ] )
{
	new
		iPlayer;

	if ( sscanf( params, "u", iPlayer ) ) return SendUsage( playerid, "/idletime [PLAYER_ID]" );
	if ( !IsPlayerConnected( iPlayer ) || IsPlayerNPC( iPlayer ) ) return SendError( playerid, "This player isn't connected." );

	new
		Float: iTime = float( GetTickCount( ) - p_AFKTime[ iPlayer ] );

	if ( iTime > 1000.0 )
	{
		iTime /= 1000.0;
		SendServerMessage( playerid, "%s(%d)'s idle time is "COL_GREY"%0.2f seconds (s)", ReturnPlayerName( iPlayer ), iPlayer, iTime );
	}
	else
	{
		SendServerMessage( playerid, "%s(%d)'s idle time is "COL_GREY"%0.0f milliseconds (ms)", ReturnPlayerName( iPlayer ), iPlayer, iTime );
	}
	return 1;
}

CMD:redeemvip( playerid, params[ ] ) return cmd_donated( playerid, params );
CMD:donated( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_VIP, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"Enter the transaction ID of your donation below.\n\n"COL_GREY"See http://forum.sfcnr.com/showthread.php?10125 for details.", "Redeem", "Close" );
	return 1;
}

CMD:gate( playerid, params[ ] )
{
	new
        Float: distance = 99999.99,
		gID = getClosestGate( playerid, distance )
	;

	if ( gID == INVALID_OBJECT_ID )
		return SendError( playerid, "You're not near any gates." );

	if ( strmatch( params, "edit" ) )
	{
		if ( g_gateData[ gID ] [ E_OWNER ] != p_AccountID[ playerid ] )
			return SendError( playerid, "You need to be the owner of this gate to edit it." );

		format( szNormalString, sizeof( szNormalString ), ""COL_WHITE"Gate Label\t"COL_GREY"%s\n"COL_WHITE"Gate Password\t"COL_GREY"%s\n"COL_WHITE"Gate Gang ID\t"COL_GREY"%d", g_gateData[ gID ] [ E_NAME ], g_gateData[ gID ] [ E_PASS ], g_gateData[ gID ] [ E_GANG_SQL_ID ] );
		ShowPlayerDialog( playerid, DIALOG_GATE_OWNER, DIALOG_STYLE_TABLIST, "{FFFFFF}Edit Gate", szNormalString, "Select", "Cancel" );

		SetPVarInt( playerid, "gate_o_editing", gID );
		SendClientMessageFormatted( playerid, -1, ""COL_GREY"[GATE]"COL_WHITE" You're now editing "COL_GREY"%s"COL_WHITE".", g_gateData[ gID ] [ E_NAME ] );
	}
	else if ( !strcmp( params, "open", true, 4 ) )
	{
		new
			szPassword[ 8 ];

		strreplacechar( params, '\\', '/' );

		if ( sscanf( params[ 5 ], "s[8]", szPassword ) )
			return SendUsage( playerid, "/gate open [PASSWORD]" );

		new
			gates = 0;

		foreach(new g : gates)
		{
			if ( ( distance = GetPlayerDistanceFromPoint( playerid, g_gateData[ g ] [ E_X ], g_gateData[ g ] [ E_Y ], g_gateData[ g ] [ E_Z ] ) ) > g_gateData[ g ] [ E_RANGE ] )
				continue; // return SendError( playerid, "You're not within the gates' operation range." );

			if ( strcmp( szPassword, g_gateData[ g ] [ E_PASS ], false ) )
				continue; // return SendError( playerid, "Incorrect password. Please try again." );

			if ( OpenPlayerGate( playerid, g ) ) {
				gates ++;
			}
		}
		return !gates ? SendError( playerid, "Either a gate is in operation, not in range or simply incorrect password." ) : 1;
	}
	else if ( strmatch( params, "closest" ) && p_AdminLevel[ playerid ] > 1 )
	{
		SendServerMessage( playerid, "The closest gate to you is "COL_GREY"%s"COL_WHITE". (id: %d, distance: %f)", g_gateData[ gID ] [ E_NAME ], gID, distance );
	}
	else SendUsage( playerid, "/gate [OPEN/EDIT]" );
	return 1;
}

CMD:robitems( playerid, params[ ] )
{
	/* ** ANTI ROB SPAM ** */
    if ( GetPVarInt( playerid, "robitems_timestamp" ) > g_iTime ) return SendError( playerid, "You must wait at least a minute before swindling another person." );
    /* ** END OF ANTI SPAM ** */

  	new victimid = GetClosestPlayer( playerid );
   	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
   	else if ( !IsPlayerJob( playerid, JOB_PROSTITUTE ) ) return SendError( playerid, "You must be a prostitute to use this command." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "It's impossible to rob someone inside a car." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
  		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle." );
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
		if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "You cannot use this command since you're in a minigame." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command inside a vehicle." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "You cannot use this command on admins that are on duty." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );

		SetPVarInt( playerid, "robitems_timestamp", g_iTime + 60 );
		GivePlayerWantedLevel( playerid, 4 );
		GivePlayerScore( playerid, 1 );
		GivePlayerExperience( playerid, E_ROBBERY );

		new
			available_items[ 3 ] = { -1, -1, -1 },
			iRandomItem = -1
		;

		if ( p_BobbyPins[ victimid ] > 0 && p_BobbyPins[ playerid ] < GetShopItemLimit( SHOP_ITEM_BOBBY_PIN ) ) available_items[ 0 ] = 0;
		if ( p_Scissors[ victimid ] > 0 && p_Scissors[ playerid ] < GetShopItemLimit( SHOP_ITEM_SCISSOR ) ) available_items[ 1 ] = 1;
		if ( p_Ropes[ victimid ] > 0 && p_Ropes[ playerid ] < GetShopItemLimit( SHOP_ITEM_ROPES ) ) available_items[ 2 ] = 2;

		if ( available_items[ 0 ] == -1 || available_items[ 1 ] == -1 || available_items[ 2 ] == -1 ) {
			SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[ROB FAIL]{FFFFFF} %s(%d) has failed to rob items off you.", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_RED"[ROB FAIL]{FFFFFF} You find nothing in %s(%d)'s pocket and he noticed you after thoroughly checking.", ReturnPlayerName( victimid ), victimid );
		    return 1;
		}

		iRandomItem = randomArrayItem( available_items, -1 );

		switch( iRandomItem )
		{
			case 0: // Pins
			{
				p_BobbyPins[ victimid ] --, p_BobbyPins[ playerid ] ++;
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[ROBBED]{FFFFFF} %s(%d) has pinched a bobby pin off you!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ROBBED]{FFFFFF} You have pinched a bobby pin off %s(%d)!", ReturnPlayerName( victimid ), victimid );
			}
			case 1: // Scissors
			{
				p_Scissors[ victimid ] --, p_Scissors[ playerid ] ++;
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[ROBBED]{FFFFFF} %s(%d) has pinched a pair of scissors off you!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ROBBED]{FFFFFF} You have pinched a pair of scissors off %s(%d)!", ReturnPlayerName( victimid ), victimid );
			}
			case 2: // Ropes
			{
				p_Ropes[ victimid ] --, p_Ropes[ playerid ] ++;
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[ROBBED]{FFFFFF} %s(%d) has pinched a rope off you!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ROBBED]{FFFFFF} You have pinched a rope off %s(%d)!", ReturnPlayerName( victimid ), victimid );
			}
		}
 	}
 	else SendError( playerid, "There are no players around to rob." );
	return 1;
}


CMD:pdjail( playerid, params[ ] )
{
	erase( szBigString );

	new
		time = g_iTime;

	for( new i = 0; i < sizeof( g_jailData ); i++ ) {
		if ( g_jailData[ i ] [ E_TIMESTAMP ] < time )
			format( szBigString, sizeof( szBigString ), "%s"COL_GREY"%s"COL_WHITE"\t"COL_GREEN"Available To Raid!\n", szBigString, returnCityName( g_jailData[ i ] [ E_CITY ] ) );
		else
			format( szBigString, sizeof( szBigString ), "%s"COL_GREY"%s"COL_WHITE"\t%s\n", szBigString, returnCityName( g_jailData[ i ] [ E_CITY ] ), secondstotime( g_jailData[ i ] [ E_TIMESTAMP ] - time ) );
	}

	if ( g_alcatrazTimestamp < time )
		strcat( szBigString, ""COL_GREY"Alcatraz"COL_WHITE"\t"COL_GREEN"Available To Raid!" );
	else
		format( szBigString, sizeof( szBigString ), "%s"COL_GREY"Alcatraz"COL_WHITE"\t%s\n", szBigString, secondstotime( g_alcatrazTimestamp - time ) );

	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Police Jails", szBigString, "Okay", "" );
	return 1;
}

CMD:banks( playerid, params[ ] )
{
	erase( szBigString );

	for( new i = 0, time = g_iTime; i < sizeof( g_bankvaultData ); i++ ) {
		if ( g_bankvaultData[ i ] [ E_TIMESTAMP ] < time )
			format( szBigString, sizeof( szBigString ), "%s"COL_GREY"%s"COL_WHITE"\t"COL_GREEN"Available To Rob!\n", szBigString, g_bankvaultData[ i ] [ E_NAME ] );
		else
			format( szBigString, sizeof( szBigString ), "%s"COL_GREY"%s"COL_WHITE"\t%s\n", szBigString, g_bankvaultData[ i ] [ E_NAME ], secondstotime( g_bankvaultData[ i ] [ E_TIMESTAMP ] - time ) );
	}
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, "{FFFFFF}Banks", szBigString, "Okay", "" );
	return 1;
}

CMD:burglar( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You are not a civilian." );
	if ( !IsPlayerJob( playerid, JOB_BURGLAR ) ) return SendError( playerid, "You are not a burglar." );

	if ( isnull( params ) ) return SendUsage( playerid, "/burglar [CRACKPW/STEAL/STORE]" );
	else if ( strmatch( params, "crackpw" ) )
	{
		if ( GetPVarInt( playerid, "crackpw_cool" ) > g_iTime ) return SendError( playerid, "You must wait 40 seconds before using this command again." );

		// businesses
		foreach ( new handle : business )
		{
			if ( IsPlayerInDynamicCP( playerid, g_businessData[ handle ] [ E_ENTER_CP ] ) )
			{
				if ( g_iTime > g_businessData[ handle ] [ E_CRACKED_TS ] && g_businessData[ handle ] [ E_CRACKED ] ) g_businessData[ handle ] [ E_CRACKED ] = false; // The Virus Is Disabled.

				if ( IsBusinessAssociate( playerid, handle ) )
					return SendError( playerid, "You are an associate of this business, you cannot crack it." );

				if ( g_businessData[ handle ] [ E_CRACKED_WAIT ] > g_iTime )
				    return SendError( playerid, "This house had its password recently had a cracker run through. Come back later." );

				if ( g_businessData[ handle ] [ E_CRACKED ] || g_businessData[ handle ] [ E_BEING_CRACKED ] )
				    return SendError( playerid, "This house is currently being cracked or is already cracked." );

				// alert
				foreach ( new ownerid : Player ) if ( IsBusinessAssociate( ownerid, handle ) ) {
					SendClientMessageFormatted( ownerid, -1, ""COL_RED"[BURGLARY]"COL_WHITE" %s(%d) is attempting to break into your business %s"COL_WHITE"!", ReturnPlayerName( playerid ), playerid, g_businessData[ handle ] [ E_NAME ] );
				}

				// crack pw
                g_businessData[ handle ] [ E_BEING_CRACKED ] = true;
                SetPVarInt( playerid, "crackpw_biz", handle );
                SetPVarInt( playerid, "crackpw_cool", g_iTime + 40 );
				ShowProgressBar( playerid, "Cracking Password", PROGRESS_CRACKING_BIZ, 7500, COLOR_WHITE );
	            return 1;
			}
		}

		// houses
		foreach ( new i : houses )
		{
			if ( IsPlayerInDynamicCP( playerid, g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] ) && !strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
				if ( g_iTime > g_houseData[ i ] [ E_CRACKED_TS ] && g_houseData[ i ] [ E_CRACKED ] ) g_houseData[ i ] [ E_CRACKED ] = false; // The Virus Is Disabled.

				if ( g_houseData[ i ] [ E_CRACKED_WAIT ] > g_iTime )
				    return SendError( playerid, "This house had its password recently had a cracker run through. Come back later." );

				if ( strmatch( g_houseData[ i ] [ E_PASSWORD ], "N/A" ) )
				    return SendError( playerid, "This house does not require cracking as it doesn't have a password." );

				if ( g_houseData[ i ] [ E_CRACKED ] || g_houseData[ i ] [ E_BEING_CRACKED ] )
				    return SendError( playerid, "This house is currently being cracked or is already cracked." );

		        if ( IsHouseOnFire( i ) )
			       	return SendError( playerid, "This house is on fire, you cannot crack it!" ), 1;

                g_houseData[ i ] [ E_BEING_CRACKED ] = true;
                p_HouseCrackingPW[ playerid ] = i;
                SetPVarInt( playerid, "crackpw_cool", g_iTime + 40 );
				ShowProgressBar( playerid, "Cracking Password", PROGRESS_CRACKING, 7500, COLOR_WHITE );
	            return 1;
			}
		}

		// businesses
		SendError( playerid, "You are not standing in any house or business checkpoint." );
	}
	else if ( strmatch( params, "steal" ) )
	{
		new houseid = p_InHouse[ playerid ];

	    if ( houseid == -1 )
	    	return SendError( playerid, "You're not inside any house." );

    	if ( IsPlayerHomeOwner( playerid, houseid ) )
    		return SendError( playerid, "You can't steal a piece of furniture from your house!" );

	    new Float: distance = 99999.99, furniture_slot = ITER_NONE;
		new objectid = GetClosestFurniture( houseid, playerid, distance, furniture_slot );
		new modelid = Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID );
		new furniture_id = getFurnitureID( modelid );

    	if ( objectid == INVALID_OBJECT_ID || furniture_slot == ITER_NONE )
    		return SendError( playerid, "No furniture is in this house." );

		if ( distance > 3.0 )
			return SendError( playerid, "You are not close to any furniture." );

		if ( g_houseFurniture[ furniture_id ] [ E_CATEGORY ] != FC_ELECTRONIC && g_houseFurniture[ furniture_id ] [ E_CATEGORY ] != FC_WEAPONS )
			return SendError( playerid, "The furniture you're near is not an electronic." );

		if ( IsPlayerAttachedObjectSlotUsed( playerid, 3 ) )
			return SendError( playerid, "Your hands are busy at the moment." );

		if ( IsPointToPoint( 150.0, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ], g_houseData[ houseid ] [ E_EZ ], -2480.1426, 5.5302, 25.6172 ) )
			return SendError( playerid, "This house is prohibited from burglarly features as it is too close to the Pawn Store." );

		new Float: playerZ, Float: furnitureZ;
		GetPlayerPos( playerid, playerZ, playerZ, playerZ );
		GetDynamicObjectPos( objectid, furnitureZ, furnitureZ, furnitureZ );

		// apply animation
    	if ( playerZ - furnitureZ <= 0.0 ) ApplyAnimation( playerid, "CARRY", "liftup105", 4.0, 0, 0, 0, 0, 0 );
    	else if ( playerZ - furnitureZ <= 0.45 ) ApplyAnimation( playerid, "CARRY", "liftup05", 4.0, 0, 0, 0, 0, 0 );
    	else ApplyAnimation( playerid, "CARRY", "liftup", 4.0, 0, 0, 0, 0, 0 );

		// Alert
		SendServerMessage( playerid, "You have stolen a "COL_GREY"%s"COL_WHITE". Store it in a Boxville to transport the item.", g_houseFurniture[ furniture_id ] [ E_NAME ] );
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_CARRY );
		SetPVarInt( playerid, "stolen_fid", furniture_id );
		SetPlayerAttachedObject( playerid, 3, 1220, 5, 0.043999, 0.222999, 0.207000, 14.400002, 15.799994, 0.000000, 0.572999, 0.662000, 0.665000 );
	}
	else if ( strmatch( params, "store" ) )
	{
		new vehicleid = GetClosestVehicle( playerid ), Float: X, Float: Y, Float: Z, Float: Angle, szID[ 18 ];
		if ( !IsValidVehicle( vehicleid ) ) return SendError( playerid, "You're not near any vehicles." );
		if ( GetVehicleModel( vehicleid ) != 498 ) return SendError( playerid, "The vehicle you're near is not a Boxville." );
		if ( !IsPlayerAttachedObjectSlotUsed( playerid, 3 ) ) return SendError( playerid, "You aren't holding anything!" );
	    GetVehiclePos( vehicleid, X, Y, Z );
	    GetVehicleZAngle( vehicleid, Angle );
	    X += ( 4.5 * floatsin( -Angle + 180, degrees ) );
	    Y += ( 4.5 * floatcos( -Angle + 180, degrees ) );
	    if ( !IsPlayerInRangeOfPoint( playerid, 1.0, X, Y, Z ) ) return SendError( playerid, "Make sure you're behind the vehicle!" );
		format( szSmallString, sizeof( szSmallString ), "vburg_%d_items", vehicleid );
		if ( GetGVarInt( szSmallString ) >= MAX_BURGLARY_SLOTS ) return SendError( playerid, "You can only carry "#MAX_BURGLARY_SLOTS" items in this vehicle." );
		SetGVarInt( szSmallString, GetGVarInt( szSmallString ) + 1 );
		format( szID, sizeof( szID ), "vburg_%d_%d", vehicleid, GetGVarInt( szSmallString ) );
		SetGVarInt( szID, GetPVarInt( playerid, "stolen_fid" ) );
		RemovePlayerAttachedObject( playerid, 3 );
		ClearAnimations( playerid );
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
		SetPlayerFacingAngle( playerid, Angle );
		SendServerMessage( playerid, "You have placed a "COL_GREY"%s"COL_WHITE" in this Boxville. "COL_ORANGE"[%d/"#MAX_BURGLARY_SLOTS"]", g_houseFurniture[ GetPVarInt( playerid, "stolen_fid" ) ] [ E_NAME ], GetGVarInt( szSmallString ) );
		DeletePVar( playerid, "stolen_fid" );
		ApplyAnimation( playerid, "CARRY", "putdwn105", 4.0, 0, 0, 0, 0, 0 );
	}
	else SendUsage( playerid, "/burglar [CRACKPW/STEAL/STORE]" );
	return 1;
}

CMD:playerjobs( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_ONLINE_JOB, DIALOG_STYLE_LIST, "{FFFFFF}Player Jobs", "Rapist\nKidnapper\nTerrorist\nHitman\nProstitute\nWeapon Dealer\nDrug Dealer\nDirty Mechanic\nBurglar", "Select", "Cancel" );
	return 1;
}

CMD:gettaxrate( playerid, params[ ] ) return cmd_tax( playerid, params );
CMD:getmytax( playerid, params[ ] ) return cmd_tax( playerid, params );
CMD:tax( playerid, params[ ] )
{
	new Float: tax_discount = p_VIPLevel[ playerid ] >= VIP_GOLD ? 0.5 : 1.0;
	new Float: tax_rate = GetGVarFloat( "taxrate" ) * tax_discount;
	new player_tax = floatround( float( GetPlayerTotalCash( playerid ) ) * ( tax_rate / 100.0 ) );
	if ( player_tax < 0 ) player_tax = 0;
	if ( tax_discount != 1.0 ) {
		SendServerMessage( playerid, "Your tax is "COL_GOLD"%s"COL_WHITE" at %0.2f%s in %s. "COL_GOLD"(50%s Reduced)", cash_format( player_tax ), tax_rate, "%%", secondstotime( GetGVarInt( "taxtime" ) - g_iTime ), "%%" );
	} else {
		SendServerMessage( playerid, "Your tax is "COL_GOLD"%s"COL_WHITE" at %0.2f%s in %s.", cash_format( player_tax ), tax_rate, "%%", secondstotime( GetGVarInt( "taxtime" ) - g_iTime ) );
	}
	return 1;
}

CMD:gettotalcash( playerid, params[ ] )
{
	mysql_function_query( dbHandle, "SELECT USER_CASH, BIZ_CASH, GANG_CASH FROM (SELECT (SUM(BANKMONEY)+SUM(CASH)) USER_CASH FROM USERS) A CROSS JOIN (SELECT SUM(BANK) BIZ_CASH FROM BUSINESSES) B CROSS JOIN (SELECT SUM(BANK) GANG_CASH FROM GANGS) C", true, "gettotalcash", "i", playerid );
	return 1;
}

thread gettotalcash( playerid )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );
	if ( rows )
	{
		new tax_profit = floatround( ( GetGVarFloat( "taxprofit" ) - GetGVarFloat( "taxprofit_prev" ) ) * 1000000.0 );
		new user_cash = cache_get_field_content_int( 0, "USER_CASH", dbHandle );
		new biz_cash = cache_get_field_content_int( 0, "BIZ_CASH", dbHandle );
		new gang_cash = cache_get_field_content_int( 0, "GANG_CASH", dbHandle );
		new total_cash = user_cash + biz_cash + gang_cash;

		format( szLargeString, 512, "Total User Cash\t"COL_GREY"%s\nTotal Gang Cash\t"COL_GREY"%s\nTotal Business Cash\t"COL_GREY"%s\nTotal Server Cash\t"COL_GOLD"%s\nTotal Tax Profit (Day)\t"COL_GOLD"%s",
				cash_format( user_cash ), cash_format( gang_cash ), cash_format( biz_cash ), cash_format( total_cash ), cash_format( tax_profit ) );

		// SendServerMessage( playerid, "Total: "COL_GOLD"%s"COL_WHITE", Tax Rate: "COL_GOLD"%s"COL_WHITE" per 24 mins.", cash_format( total_cash ), cash_format( tax_rate ) );
  		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, "{FFFFFF}SF-CNR Economy", szLargeString, "Close", "" );
	}
	else SendError( playerid, "An error has occurred, try again later." );
	return 1;
}

/*CMD:policetutorial( playerid, params[ ] )
{
	if ( p_CopTutorial{ playerid } == 0 ) return SendError( playerid, "You have already enabled the law enforcement officer tutorial." );
  	ShowPlayerDialog( playerid, DIALOG_VIEW_LEO_TUT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Law Enforcement Officer Tutorial", "{FFFFFF}Are you sure you would like to view the law enforcement officer tutorial again?", "Yes", "No" );
	return 1;
}*/

CMD:ransompay( playerid, params[ ] )
{
	if ( !IsPlayerConnected( p_RansomPlacer[ playerid ] ) ) return SendError( playerid, "Your ransom offerer is not connected anymore." );
	else if ( !IsPlayerTied( playerid ) ) return p_RansomPlacer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "Only tied players can use this command." );
	else if ( GetPlayerCash( playerid ) < p_RansomAmount[ playerid ] ) return SendError( playerid, "You do not have enough money for your ransom." );
	else if ( IsPlayerSettingToggled( playerid, SETTING_RANSOMS ) ) return SendError( playerid, "This feature is unavailable as you have disabled ransom offers." );
	else
	{
		TogglePlayerControllable( playerid, 1 );
		p_Tied{ playerid } = false;
	   	if ( IsPlayerKidnapped( playerid ) ) {
	     	p_Kidnapped{ playerid } = false;
	 	}
		Delete3DTextLabel( p_TiedLabel[ playerid ] );
		p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
		GivePlayerCash( playerid, -p_RansomAmount[ playerid ] );
		GivePlayerCash( p_RansomPlacer[ playerid ], p_RansomAmount[ playerid ] );
		SendClientMessageFormatted( p_RansomPlacer[ playerid ], -1, ""COL_GREEN"[RANSOM PAY]{FFFFFF} %s(%d) has paid his ransom ("COL_GOLD"%s"COL_WHITE").", ReturnPlayerName( playerid ), playerid, cash_format( p_RansomAmount[ playerid ] ) );
		SendClientMessageFormatted( playerid, -1, ""COL_RED"[RANSOM PAY]{FFFFFF} You have paid your ransom ("COL_GOLD"%s"COL_WHITE"), you are now released.", cash_format( p_RansomAmount[ playerid ] ) );
		Beep( p_RansomPlacer[ playerid ] );
		GivePlayerWantedLevel( p_RansomPlacer[ playerid ], 6 );
		p_RansomAmount[ playerid ] = 0;
		p_RansomPlacer[ playerid ] = INVALID_PLAYER_ID;
		p_KidnapImmunity[ playerid ] = g_iTime + 180;
	}
	return 1;
}

CMD:rans( playerid, params[ ] ) return cmd_ransom( playerid, params );
CMD:ransom( playerid, params[ ] )
{
	new victimid, amount;

	if ( sscanf( params, "ud", victimid, amount ) ) return SendUsage( playerid, "/ransom [PLAYER_ID] [AMOUNT]" );
	else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "This player is not connected." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
	else if ( !IsPlayerJob( playerid, JOB_KIDNAPPER ) ) return SendError( playerid, "You must be a kidnapper to use this command." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( victimid == playerid ) return SendError( playerid, "You cannot create a ransom on yourself." );
	else if ( IsPlayerSettingToggled( victimid, SETTING_RANSOMS ) ) return SendError( playerid, "This player has disabled ransom offers." );
	else if ( amount < 50 || amount > 20000 ) return SendError( playerid, "You may place a ransom from $50 to $20,000." );
	else if ( amount > 99999999 || amount < 0 ) return SendError( playerid, "You may place a ransom from $50 to $20,000."); // Making cash go over billions...
	else if ( amount > GetPlayerCash( victimid ) ) return SendError( playerid, "This person doesn't have enough money to pay this amount." );
	else if ( p_RansomTimestamp[ victimid ] > g_iTime ) return SendError( playerid, "You must wait %d seconds before offering a ransom to this person.", p_RansomTimestamp[ victimid ] - g_iTime );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
		if ( !IsPlayerTied( victimid ) ) return SendError( playerid, "This player must be tied in order to create a ransom." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command while you're cuffed." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command while you're tazed." );
		if ( IsPlayerInPaintBall( playerid ) ) return SendError( playerid, "You cannot use this command since you're inside an arena." );

		SendClientMessageFormatted( victimid, -1, ""COL_RED"[RANSOM]{FFFFFF} You have been offered a ransom of "COL_GOLD"%s"COL_WHITE" for your release. Use /ransompay to pay the ransom.", cash_format( amount ) );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[RANSOM]{FFFFFF} You have offered a ransom to %s(%d) of "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( victimid ), victimid, cash_format( amount ) );
		p_RansomAmount[ victimid ] = amount;
		p_RansomPlacer[ victimid ] = playerid;
		p_RansomTimestamp[ victimid ] = g_iTime + 15;
	}
	else return SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:flat( playerid, params[ ] )
{
	new count = 0;
	szBigString[ 0 ] = '\0';
	for( new i; i < sizeof( g_apartmentData ); i++ ) if ( g_apartmentData[ i ] [ E_CREATED ] )
	{
		if ( strmatch( g_apartmentData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
		{
		    count++;
		    format( szBigString, sizeof( szBigString ), "%s%s\n", szBigString, g_apartmentData[ i ] [ E_NAME ] );
		}
	}
	if ( count == 0 ) return SendError( playerid, "You don't own any apartments." );

	ShowPlayerDialog( playerid, DIALOG_FLAT_CONFIG, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", szBigString, "Select", "Cancel" );
	return 1;
}

CMD:cw( playerid, params[ ] ) return cmd_carwhisper( playerid, params );
CMD:carwhisper( playerid, params[ ] )
{
	new msg[ 100 ];
	if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You must be inside a vehicle to use this command." );
	else if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/carwhisper [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendError( playerid, "Advertising is forbidden." );
	else
	{
		foreach(new i : Player)
		{
		    if ( GetPlayerVehicleID( i ) == GetPlayerVehicleID( playerid ) ) {
		        SendClientMessageFormatted( i, -1, ""COL_ORANGE"<Car Whisper> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, msg );
		    }
		}
	}
	return 1;
}

CMD:w( playerid, params[ ] ) return cmd_whisper( playerid, params );
CMD:whisper( playerid, params[ ] )
{
	new msg[ 100 ];
	if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/whisper [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendError( playerid, "Advertising is forbidden." );
	else
	{
		new Float: X, Float: Y, Float: Z;
		GetPlayerPos( playerid, X, Y, Z );
		foreach(new i : Player)
		{
		    if ( IsPlayerInRangeOfPoint( i, 5.0, X, Y, Z ) && GetPlayerVirtualWorld( i ) == GetPlayerVirtualWorld( playerid ) ) {
		        SendClientMessageFormatted( i, -1, ""COL_ORANGE"<Whisper> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, msg );
		    }
		}
	}
	return 1;
}

CMD:nametags( playerid, params[ ] )
{
	if ( strmatch( params, "off" ) ) {
		foreach(new i : Player) { ShowPlayerNameTagForPlayer( playerid, i, 0 ); }
	    SendClientMessage( playerid, 0x84aa63ff, "-> Name tags disabled" );
	} else if ( strmatch( params, "on" ) ) {
		foreach(new i : Player) { ShowPlayerNameTagForPlayer( playerid, i, 1 ); }
	    SendClientMessage( playerid, 0x84aa63ff, "-> Name tags enabled" );
	}
	else SendClientMessage( playerid, 0xa9c4e4ff, "-> /nametags [ON/OFF]" );
	return 1;
}

new p_LastCuredTS[ MAX_PLAYERS ];
new p_LastHealedTS[ MAX_PLAYERS ];

CMD:cure( playerid, params[ ] )
{
  	new
  		pID,
  		time = g_iTime
  	;

   	if ( p_Class[ playerid ] != CLASS_MEDIC ) return SendError( playerid, "This is restricted to medics only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/cure [PLAYER_ID]" );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not connected." );
	else if ( playerid == pID ) return SendError( playerid, "You cannot offer to cure yourself." );
	else if ( GetPlayerCash( pID ) < 4875 ) return SendError( playerid, "This player doesn't have enough money to get a cure." );
 	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 4.0 )
 	{
		if ( IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "This player is in a vehicle " );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( p_LastCuredTS[ playerid ] > time ) return SendError( playerid, "You must wait another %d seconds before curing somebody.", p_LastCuredTS[ playerid ] - time );
 		SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} %s(%d) wishes to cure you for $4,875. "COL_ORANGE"/acceptcure{FFFFFF} to accept the deal.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} You have offered %s(%d) a cure for $4875.", ReturnPlayerName( pID ), pID );
   		p_CureDealer[ pID ] = playerid;
		p_CureTick[ pID ] = time + 120;
	}
	else SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:ac( playerid, params[ ] ) return cmd_acceptcure( playerid, params );
CMD:acceptcure( playerid, params[ ] )
{
	new
		time = g_iTime;

	if ( !IsPlayerConnected( p_CureDealer[ playerid ] ) ) return SendError( playerid, "Your dealer isn't connected anymore." );
	else if ( time > p_CureTick[ playerid ]  ) return p_CureDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, each deal goes for 2 minutes maximum. You were late." );
	else if ( GetPlayerCash( playerid ) < 4875 ) return SendError( playerid, "You do not have enough money to get a cure." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "You cannot buy cures while you're in jail." );
   	else if ( p_Class[ p_CureDealer[ playerid ] ] != CLASS_MEDIC ) return SendError( playerid, "The paramedic that offered you is no longer a paramedic." );
	else
	{
	    Beep( p_CureDealer[ playerid ] );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} You have been cured from all diseases by %s(%d) for $4,875. ", ReturnPlayerName( p_CureDealer[ playerid ] ), p_CureDealer[ playerid ] );
		SendClientMessageFormatted( p_CureDealer[ playerid ], -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} %s(%d) has paid and got himself cured.", ReturnPlayerName( playerid ), playerid );		p_InfectedHIV{ playerid } = false;
		GivePlayerCash( playerid, -4875 );
		GivePlayerCash( p_CureDealer[ playerid ], 4875 );
		GivePlayerScore( p_CureDealer[ playerid ], 2 );
		//GivePlayerExperience( p_CureDealer[ playerid ], E_PARAMEDIC );
		p_LastCuredTS[ p_CureDealer[ playerid ] ] = time + 15;
		p_CureDealer[ playerid ] = INVALID_PLAYER_ID;
	}
	return 1;
}

CMD:heal( playerid, params[ ] )
{
  	new
  		pID;

   	if ( p_Class[ playerid ] != CLASS_MEDIC ) return SendError( playerid, "This is restricted to medics only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/heal [PLAYER_ID]" );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not connected." );
	else if ( playerid == pID ) return SendError( playerid, "You cannot offer to heal yourself." );
	else if ( GetPlayerCash( pID ) < 750 ) return SendError( playerid, "This player doesn't have enough money to get a health refill." );
 	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 4.0 )
 	{
		if ( IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "This player is in a vehicle " );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( p_LastHealedTS[ playerid ] > g_iTime ) return SendError( playerid, "You must wait another %d seconds before curing somebody.", p_LastHealedTS[ playerid ] - g_iTime );
 		SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} %s(%d) wishes to heal you for $1,200. "COL_ORANGE"/acceptheal{FFFFFF} to accept the deal.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} You have offered %s(%d) a health refill for $1,200.", ReturnPlayerName( pID ), pID );
   		p_HealDealer[ pID ] = playerid;
		p_HealTick[ pID ] = g_iTime + 120;
	}
	else SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:ah( playerid, params[ ] ) return cmd_acceptheal( playerid, params );
CMD:acceptheal( playerid, params[ ] )
{
	new
		Float: fHealth;

	if ( !IsPlayerConnected( p_HealDealer[ playerid ] ) ) return SendError( playerid, "Your dealer isn't connected anymore." );
	else if ( g_iTime > p_HealTick[ playerid ]  ) return p_HealDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, each deal goes for 2 minutes maximum. You were late." );
	else if ( GetPlayerCash( playerid ) < 750 ) return SendError( playerid, "You do not have enough money to get a health refill." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "You cannot buy heals while you're in jail." );
   	else if ( p_Class[ p_HealDealer[ playerid ] ] != CLASS_MEDIC ) return SendError( playerid, "The paramedic that offered you is no longer a paramedic." );
	else if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
	else if ( GetPlayerHealth( playerid, fHealth ) && fHealth >= 90.0 ) return SendError( playerid, "You need to have less than 90 percent of your health to be healed." );
	else
	{
	    Beep( p_HealDealer[ playerid ] );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} You have patched up and healed by %s(%d) for $1,200. ", ReturnPlayerName( p_HealDealer[ playerid ] ), p_HealDealer[ playerid ] );
		SendClientMessageFormatted( p_HealDealer[ playerid ], -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} %s(%d) has paid and got his health refilled.", ReturnPlayerName( playerid ), playerid );
		SetPlayerHealth( playerid, 120.0 );
		GivePlayerCash( playerid, -1200 );
		GivePlayerCash( p_HealDealer[ playerid ], 1200 );
		GivePlayerScore( p_HealDealer[ playerid ], 2 );
		//GivePlayerExperience( p_HealDealer[ playerid ], E_PARAMEDIC );
		p_LastHealedTS[ p_HealDealer[ playerid ] ] = g_iTime + 15;
		p_HealDealer[ playerid ] = INVALID_PLAYER_ID;
	}
	return 1;
}

CMD:admins( playerid, params[ ] )
{
	if ( GetPlayerScore( playerid ) < 500 && !IsPlayerUnderCover( playerid ) && p_AdminLevel[ playerid ] < 1 )
	    return SendError( playerid, "You need at least 500 score to view the online adminstrators." );

	new g_adminList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player ) {
		g_adminList[ player ] [ 0 ] = player;
		g_adminList[ player ] [ 1 ] = p_AdminLevel[ player ];
	}

	// sort
	SortDeepArray( g_adminList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"Player\t"COL_WHITE"Admin Level\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_adminList[ i ] [ 0 ] ) && g_adminList[ i ] [ 1 ] > 0 ) {
	   	format( szLargeString, sizeof( szLargeString ), "%s%s%s(%d)\tLevel %d\n", szLargeString, IsPlayerAdminOnDuty( g_adminList[ i ] [ 0 ] ) ? ( COL_PINK ) : ( COL_GREY ), ReturnPlayerName( g_adminList[ i ] [ 0 ] ), g_adminList[ i ] [ 0 ], g_adminList[ i ] [ 1 ] );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "There are no administrators online." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Online Admins", szLargeString, "Close", "" ), 1;
	}
}

CMD:vsay( playerid, params[ ] )
{
    new
    	msg[ 100 ],
    	time = g_iTime
    ;

    if ( p_VIPLevel[ playerid ] < 1 ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
    else if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/vsay [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendServerMessage( playerid, "Please do not advertise." );
    else
    {
     	if ( p_Muted{ playerid } )
		{
		 	if ( time > p_MutedTime[ playerid ] )
			 	p_Muted{ playerid } = false;
			else
		   		return SendError( playerid, "You cannot speak as you are muted for %s.", secondstotime( p_MutedTime[ playerid ] - time ) );
		}

		DCC_SendChannelMessageFormatted( discordGeneralChan, "__**(VIP) %s(%d):**__ %s", ReturnPlayerName( playerid ), playerid, msg );
		SendClientMessageToAllFormatted( 0x3eff3eff, "[VIP] %s(%d):{9ec34f} %s", ReturnPlayerName( playerid ), playerid, msg );
	}
	return 1;
}


CMD:aclist( playerid, params[ ] )
{
	new
		count = 0;

	szLargeString = ""COL_WHITE"Orange players are forced to use SA-MP AC\n";

	foreach(new i : Player) if ( IsPlayerUsingSampAC( i ) ) {
		format( szLargeString, sizeof( szLargeString ), "%s%s%s(%d)\n", szLargeString, p_forcedAnticheat[ i ] > 0 ? ( COL_ORANGE ) : ( "" ), ReturnPlayerName( i ), i );
	    count++;
	}
    if ( count == 0 ) return SendError( playerid, "There are no SA-MP AC users online." );
    if ( strlen( szLargeString ) == sizeof( szLargeString ) - 1 ) return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Online SA-MP AC Users", sprintf( ""COL_WHITE"There are %d SA-MP AC users online.", count ), "Okay", "" );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Online SA-MP AC Users", szLargeString, "Okay", "" );
	return 1;
}

CMD:viplist( playerid, params[ ] )
{
	new
		count = 0;

	szLargeString = ""COL_WHITE"Player\t"COL_WHITE"V.I.P Package\n";

	foreach(new i : Player) if ( p_VIPLevel[ i ] > 0 )
	{
	    format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t%s%s\n", szLargeString, ReturnPlayerName( i ), i, VIPToColor( p_VIPLevel[ i ] ), VIPToString( p_VIPLevel[ i ] ) );
	    count++;
	}
    if ( count == 0 ) return SendError( playerid, "There are no V.I.P's online." );
    if ( strlen( szLargeString ) == sizeof( szLargeString ) - 1 ) return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Online V.I.P's", sprintf( ""COL_WHITE"There are %d V.I.P players online.", count ), "Okay", "" );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Online V.I.P's", szLargeString, "Okay", "" );
	return 1;
}

CMD:vipcmds( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < 1 ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );

	erase( szLargeString );
	strcat( szLargeString,	""COL_GREY"/vipspawnwep\tConfigure your spawning weapons\n"\
							""COL_GREY"/vipskin\tConfigure your spawning skin\n"\
							""COL_GREY"/vipgun\tRedeem weapons or an armour vest from the gun locker\n"\
							""COL_GREY"/vsay\tGlobal V.I.P Chat\n" );
	strcat( szLargeString,	""COL_GREY"/vipjob\tSet your secondary VIP job\n"\
							""COL_GREY"/vippackage\tCustomize your VIP package name\n"\
							""COL_GREY"/mynotes\tAccess your VIP notes and material\n"\
							""COL_GREY"/mycustomizations\tAccess your house customization taxes" );

	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, "{FFFFFF}V.I.P Commands", szLargeString, "Okay", "" );
	return 1;
}

CMD:vipspawnwep( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
	format( szNormalString, sizeof( szNormalString ), "%s\n"COL_BRONZE"%s\n"COL_GOLD"%s", p_VIPWep1{ playerid } ? ReturnWeaponName( p_VIPWep1{ playerid } ) : ( "Nothing" ), p_VIPWep2{ playerid } ? ReturnWeaponName( p_VIPWep2{ playerid } ) : ( "Nothing" ), p_VIPWep3{ playerid } ? ReturnWeaponName( p_VIPWep3{ playerid } ) : ( "Nothing" ) );
    ShowPlayerDialog( playerid, DIALOG_VIP_WEP, DIALOG_STYLE_LIST, "{FFFFFF}Spawn Weapons", szNormalString, "Select", "" );
	return 1;
}

CMD:vipgun( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
	    return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );

	if ( !IsPlayerInRangeOfPoint( playerid, 5.0, -1966.1591, 852.7100, 1214.2678 ) && !IsPlayerInRangeOfPoint( playerid, 5.0, -1944.1324, 830.0725, 1214.2678 ) && !IsPlayerInRangeOfPoint( playerid, 5.0, 60.3115, 121.5226, 1017.4534 ) )
		return SendError( playerid, "You must be near a gun vending machine inside the V.I.P lounge to use this." );

    ShowPlayerDialog( playerid, DIALOG_VIP_LOCKER, DIALOG_STYLE_LIST, "{FFFFFF}V.I.P Guns", ""COL_GOLD"[GOLD VIP]"COL_GREY" Armour\n9mm Pistol\nSilenced Pistol\nDesert Eagle\nShotgun\nSawn-off Shotgun\nSpas 12\nMac 10\nMP5\nAK-47\nM4\nTec 9\nRifle\nSniper\nKnuckle Duster\nGolf Club\nBaton\nKnife\nBaseball Bat\nSpade\nPool Cue\nKatana\nChainsaw\nDildo\nFlowers\nCane", "Select", "Cancel");
	return 1;
}

CMD:vipskin( playerid, params[ ] )
{
	new
	    skin
	;
	if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
	else if ( GetPlayerAnimationIndex( playerid ) == 1660 ) return SendError( playerid, "You cannot use this command since you're using a vending machine." );
	else if ( IsPlayerRobbing( playerid ) ) return SendError( playerid, "You cannot use this command since you're robbing a store." );
	/*else if ( strmatch( params, "toggle" ) )
	{
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this in a vehicle. Exit it, and try again." );
	    if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER || GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_PASSENGER ) return SendError( playerid, "You cannot set your skin if you're entering a vehicle." );
	    if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE ) return SendError( playerid, "You cannot set your skin if you're exiting a vehicle." );
		p_SkinToggled{ playerid } = true;
		Streamer_Update( playerid ); // SyncObject( playerid );
		ClearAnimations( playerid );
		SetPlayerSkin( playerid, p_LastSkin[ playerid ] );
		SendServerMessage( playerid, "You have toggled your V.I.P skin!" );
		return 1;
	}
	else if ( strmatch( params, "remove" ) )
	{
		p_SkinToggled{ playerid } = false;
		SendServerMessage( playerid, "Your V.I.P skin has been removed, changes will take place after your next spawn." );
		return 1;
	}*/
	else if ( sscanf( params, "d", skin ) ) return SendUsage( playerid, "/vipskin [SKIN_ID]" );
	else if ( !IsValidSkin( skin ) ) return SendError( playerid, "Invalid Skin ID." );
	else
	{
	    p_LastSkin[ playerid ] = skin;
	    if ( IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) ) SetPlayerSkin( playerid, skin );
	    SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP]"COL_WHITE" You have changed your V.I.P skin id to %d!", skin );
	}
	return 1;
}

CMD:vipjob( playerid, params[ ] )
{
	new
	    iJob;

	if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
		return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );

	if ( p_VIPLevel[ playerid ] < VIP_GOLD )
		return SendError( playerid, "This command requires you to be Gold V.I.P." );

	if ( isnull( params ) )
		return SendUsage( playerid, "/vipjob [PART OF JOB NAME]" );

	if ( ( iJob = GetJobIDFromName( params ) ) == 0xFE )
		return SendError( playerid, "You have entered an invalid job." );

	if ( iJob != p_Job{ playerid } ) {
		if ( GetPlayerCash( playerid ) < 5000 )
			return SendError( playerid, "You do not have enough money to set your V.I.P job." );

		GivePlayerCash( playerid, -5000 );
    	SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP]"COL_WHITE" You have changed your V.I.P job to %s! To disable, set your vip job to your original job.", GetJobName( iJob ) );
	}
	else SendClientMessage( playerid, -1, ""COL_GOLD"[VIP]"COL_WHITE" You have disabled your VIP job." );

    p_VIPJob{ playerid } = iJob;
	return 1;
}

CMD:changes( playerid, params[ ] ) return cmd_updates( playerid, params ); // Command by Cloudy & Sponyy
CMD:updates( playerid, params[ ] )
{
    new
    	File: handle = fopen( "updates.txt", io_read );

    if ( ! handle )
    	return SendError( playerid, "There are no updates to show." );

    erase( szNormalString );
    erase( szHugeString );

    while ( fread( handle, szNormalString ) )
    {
        new
        	find = strfind( szNormalString, "(+)" );

        // additions
        if( find != -1 )
        {
            strins( szNormalString, "{23D96F}added{FFFFFF}\t\t", find + 3 );
            strdel( szNormalString, find, find + 3);
        }

        // removals
        find = strfind( szNormalString, "(-)" );
        if( find != -1 )
        {
            strins( szNormalString, "{D92323}removed{FFFFFF}\t", find + 3 );
            strdel( szNormalString, find, find + 3 );
        }

        // fixes
        find = strfind( szNormalString, "(*)" );
        if ( find != -1 )
        {
            strins( szNormalString, "{D9A823}fixed{FFFFFF}\t\t", find + 3 );
            strdel( szNormalString, find, find + 3 );
        }

        // fixes
        find = strfind( szNormalString, "(/)" );
        if ( find != -1 )
        {
            strins( szNormalString, "{c0c0c0}changed{FFFFFF}\t", find + 3 );
            strdel( szNormalString, find, find + 3 );
        }

        // append
        strcat( szHugeString, szNormalString );
    }

    fclose( handle );
    ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Recent Updates - " #FILE_BUILD, szHugeString, "Okay", "" );
    SendServerMessage( playerid, "You're now viewing the latest changes to the gamemode (version "#FILE_BUILD")." );
	return 1;
}

CMD:tweets( playerid, params[ ] ) return cmd_twitter( playerid, params );
CMD:twitter( playerid, params[ ] )
{
    SendServerMessage( playerid, "Reading latest tweets from {00CCFF}www.twitter.com/IrresistibleDev{FFFFFF}, please wait!" );
	HTTP( playerid, HTTP_GET, "files.sfcnr.com/cnr_twitter.php", "", "OnTwitterHTTPResponse" );
	return 1;
}

CMD:mechanic( playerid, params[ ] ) return cmd_mech( playerid, params );
CMD:mech( playerid, params[ ] )
{
	new
		Float: vZ,
		iVehicle = GetPlayerVehicleID( playerid )
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You must be a civilian to use this command." );
	if ( !IsPlayerJob( playerid, JOB_DIRTY_MECHANIC ) ) return SendError( playerid, "You are not a dirty mechanic." );
	if ( isnull( params ) ) return SendUsage( playerid, "/(mech)anic [FIX/NOS/REMP/FLIP/FLIX/PRICE/NEARBY]" );
	else if ( strmatch( params, "fix" ) )
	{
	    if ( p_AntiMechFixSpam[ playerid ] > g_iTime )
	    	return SendError( playerid, "You must wait %d seconds before using this feature again.", p_AntiMechFixSpam[ playerid ] - g_iTime );

   		if ( !IsPlayerInAnyVehicle( playerid ) )
   			return SendError( playerid, "You are not in any vehicle." );

		new
			cost = 250;

		if ( g_isBusinessVehicle[ iVehicle ] != -1 && Iter_Contains( business, g_isBusinessVehicle[ iVehicle ] ) ) {
			cost = IsBusinessAerialVehicle( g_isBusinessVehicle[ iVehicle ], GetVehicleModel( iVehicle ) ) ? 5000 : 2500;
		}

   		if ( GetPlayerCash( playerid ) < cost ) {
   			return SendError( playerid, "You need %s to fix this vehicle.", cash_format( cost ) );
   		}

		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
		p_DamageSpamCount{ playerid } = 0;
	 	RepairVehicle( iVehicle );
	 	SendServerMessage( playerid, "You have repaired this vehicle." );
	 	p_AntiMechFixSpam[ playerid ] = g_iTime + 10;
	 	GivePlayerCash( playerid, -cost );
	}
	else if ( strmatch( params, "nos" ) )
	{
	    if ( ( GetTickCount( ) - p_AntiMechNosSpam[ playerid ] ) < 10000 ) return SendError( playerid, "You must wait 10 seconds before using this feature." );
   		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You are not in any vehicle." );
   		if ( GetPlayerCash( playerid ) < 500 ) return SendError( playerid, "You need $500 to add nitrous to this vehicle." );
		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
	  	AddVehicleComponent( iVehicle, 1010 );
	 	SendServerMessage( playerid, "You have added nitrous to this vehicle." );
	 	p_AntiMechNosSpam[ playerid ] = GetTickCount( );
	 	GivePlayerCash( playerid, -500 );
	}
	else if ( strmatch( params, "remp" ) )
	{
	    if ( ( GetTickCount( ) - p_AntiMechEmpSpam[ playerid ] ) < 10000 ) return SendError( playerid, "You must wait 10 seconds before using this feature." );
   		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You are not in any vehicle." );
		if ( GetPlayerCash( playerid ) < 750 ) return SendError( playerid, "You need $750 to remove EMP off this vehicle." );
		GetVehicleParamsEx( iVehicle, engine, lights, alarm, doors, bonnet, boot, objective );
		if ( engine != VEHICLE_PARAMS_OFF ) return SendError( playerid, "This has not been affected by any EMP attacks." );
		GivePlayerCash( playerid, -750 );
		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
		SetVehicleParamsEx( iVehicle, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective );
	 	SendServerMessage( playerid, "You have successfully re-initialized the vehicle." );
	 	p_AntiMechEmpSpam[ playerid ] = GetTickCount( );
	}
	else if ( strmatch( params, "flip" ) )
	{
	    if ( p_AntiMechFlipSpam[ playerid ] > g_iTime ) return SendError( playerid, "You must wait %d seconds before using this feature.", p_AntiMechFlipSpam[ playerid ] - g_iTime );
   		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You are not in any vehicle." );
		if ( GetPlayerCash( playerid ) < 200 ) return SendError( playerid, "You need $200 to flip this vehicle." );
		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
		GetVehicleZAngle( iVehicle, vZ ), SetVehicleZAngle( iVehicle, vZ );
		GivePlayerCash( playerid, -200 );
	 	SendServerMessage( playerid, "You have successfully flipped this vehicle." );
	 	p_AntiMechFlipSpam[ playerid ] = g_iTime + 5;
	}
	else if ( strmatch( params, "flix" ) )
	{
	    if ( p_AntiMechFixSpam[ playerid ] > g_iTime ) return SendError( playerid, "You must wait %d seconds before using this feature again.", p_AntiMechFixSpam[ playerid ] - g_iTime );
	    if ( p_AntiMechFlipSpam[ playerid ] > g_iTime ) return SendError( playerid, "You must wait %d seconds before using this feature.", p_AntiMechFlipSpam[ playerid ] - g_iTime );
   		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You are not in any vehicle." );
   		if ( GetPlayerCash( playerid ) < 500 ) return SendError( playerid, "You need $500 to flip and fix this vehicle." );

		new
			cost = 500;

		if ( g_isBusinessVehicle[ iVehicle ] != -1 && Iter_Contains( business, g_isBusinessVehicle[ iVehicle ] ) ) {
			cost = IsBusinessAerialVehicle( g_isBusinessVehicle[ iVehicle ], GetVehicleModel( iVehicle ) ) ? 6000 : 3500;
		}

   		if ( GetPlayerCash( playerid ) < cost ) {
   			return SendError( playerid, "You need %s to fix this vehicle.", cash_format( cost ) );
   		}

		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
		p_DamageSpamCount{ playerid } = 0;
	 	RepairVehicle( iVehicle );
		GetVehicleZAngle( iVehicle, vZ ), SetVehicleZAngle( iVehicle, vZ );
	 	SendServerMessage( playerid, "You have flipped and fixed this vehicle." );
	 	p_AntiMechFixSpam[ playerid ] = g_iTime + 10;
	 	p_AntiMechFlipSpam[ playerid ] =  g_iTime + 5;
	 	GivePlayerCash( playerid, -cost );
	}
	else if ( strmatch( params, "price" ) )
	{
   		if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You are not in any vehicle." );

   		new
   			iPrice;

   		if ( ( iPrice = calculateVehicleSellPrice( iVehicle ) ) )
			ShowPlayerHelpDialog( playerid, 3000, "You can export this vehicle at the docks for around ~g~%s~w~~h~.~n~~n~~r~Damaging the vehicle will further decrease the value.", cash_format( iPrice ) );
   		else
			ShowPlayerHelpDialog( playerid, 3000, "~r~This vehicle cannot be sold." );
	}
	else if ( strmatch( params, "nearby" ) )
	{
		new
			Float: fDistance = Float: 0x7F800000,
			iClosest = GetClosestVehicle( playerid, INVALID_VEHICLE_ID, fDistance )
		;

		SendServerMessage( playerid, "The closest vehicle to you is a "COL_GREY"%s"COL_WHITE", which is %0.2fm away.", GetVehicleName( GetVehicleModel( iClosest ) ), fDistance );
	}
	else return SendUsage( playerid, "/(mech)anic [FIX/NOS/REMP/FLIP/FLIX/PRICE/NEARBY]" );
	return 1;
}

CMD:savestats( playerid, params[ ] )
{
	if ( ( GetTickCount( ) - p_AntiSaveStatsSpam[ playerid ] ) < 15000 ) return SendError( playerid, "You must wait 15 seconds before saving your statistics again." );
    SavePlayerData( playerid );
    p_AntiSaveStatsSpam[ playerid ] = GetTickCount( );
    SendServerMessage( playerid, "Your statistics have been saved." );
	return 1;
}

CMD:email( playerid, params[ ] ) {
	return ShowPlayerAccountGuard( playerid );
}

CMD:ask( playerid, params[ ] )
{
    new szMessage[ 96 ];
    if ( sscanf( params, "s[96]", szMessage ) ) return SendUsage( playerid, "/ask [QUESTION]" );
    else if ( p_CantUseAsk{ playerid } == true ) return SendError( playerid, "You have been blocked to use this command by an admin." );
    else
	{
		for( new iPos; iPos < sizeof( szQuestionsLog ) - 1; iPos++ )
			memcpy( szQuestionsLog[ iPos ], szQuestionsLog[ iPos + 1 ], 0, sizeof( szQuestionsLog[ ] ) * 4 );

		format( szNormalString, sizeof( szNormalString ), "%s\t%s(%d)\t%s\n", getCurrentTime( ), ReturnPlayerName( playerid ), playerid, szMessage );
		strcpy( szQuestionsLog[ 7 ], szNormalString );

		Beep( playerid );
        SendClientMessageToAdmins( -1, "{FE5700}[QUESTION] %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, szMessage );
		SendClientMessageFormatted( playerid, -1, "{FE5700}[QUESTION]"COL_WHITE" You've asked \"%s\".", szMessage );
	}
	return 1;
}

CMD:weed( playerid, params[ ] )
{
	new
		Float: X, Float: Y, Float: Z
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You are not a civilian." );

	if ( IsPlayerTied( playerid ) || IsPlayerTazed( playerid ) || IsPlayerCuffed( playerid ) || IsPlayerJailed( playerid ) || IsPlayerInMinigame( playerid ) )
		return SendError( playerid, "You cannot use this command at the moment." );

	if ( isnull( params ) ) return SendUsage( playerid, "/weed [COLLECT/SELL/BUY/USE]" );
	else if ( strmatch( params, "collect" ) )
	{
		if ( !IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "You are not a drug dealer." );
		if ( p_WeedGrams[ playerid ] >= MAX_WEED_STORAGE ) return SendError( playerid, "You can only carry %d grams of weed.", MAX_WEED_STORAGE );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You mustn't be inside a vehicle while collecting weed." );

		new count = 0;
	    for( new i; i < MAX_WEED; i++ )
	    {
			if ( g_weedData[ i ] [ E_CREATED ] == false || g_weedData[ i ] [ E_CUT ] == true ) continue;
			GetDynamicObjectPos( g_weedData[ i ] [ E_OBJECT ], X, Y, Z );

			if ( IsPlayerInRangeOfPoint( playerid, 4.0, X, Y, Z ) && g_weedData[ i ] [ E_CUT ] == false )
			{
			    count++;
                p_WeedGrams[ playerid ]++;
                g_weedData[ i ] [ E_CUT ] = true;
                MoveDynamicObject( g_weedData[ i ] [ E_OBJECT ], X, Y, Z - 5.0, 0.50 );
                SendServerMessage( playerid, "You have collected a gram of "COL_GREEN"weed{FFFFFF}." );
			  	break;
		  	}
	    }
		if ( !count ) SendError( playerid, "You are not next to any weed plant." );
	}
	else if ( !strcmp( params, "sell", false, 4 ) )
	{
	    new pID, iAmount;

		if ( !IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "You are not a drug dealer." );
	    else if ( p_SellingWeedTick[ playerid ] > g_iTime ) return SendError( playerid, "You must wait a minute before selling weed again." );
		else if ( !p_WeedGrams[ playerid ] ) return SendError( playerid, "You don't have any weed with you." );
	    else if ( sscanf( params[ 5 ],"uD(1)", pID, iAmount ) ) return SendUsage( playerid, "/weed sell [PLAYER_ID] [GRAMS]" );
	    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	    else if ( pID == playerid ) return SendError( playerid, "You cannot sell yourself weed." );
		else if ( p_Class[ pID ] != CLASS_CIVILIAN ) return SendError( playerid, "This person is not a civilian." );
		else if ( iAmount > p_WeedGrams[ playerid ] ) return SendError( playerid, "You only have %d grams of weed on you.", p_WeedGrams[ playerid ] );
	    else if ( iAmount < 1 || iAmount > MAX_WEED_STORAGE ) return SendError( playerid, "You can only sell between 1 to %d grams of weed to a player.", MAX_WEED_STORAGE );
	    else if ( GetDistanceBetweenPlayers( playerid, pID ) < 5.0 )
	    {
	    	new
	    		iCost  = iAmount * 5000,
	    		iTaxed = floatround( iCost * 0.8 )
	    	;

			if ( GetPlayerCash( pID ) < iCost ) return SendError( playerid, "This person doesn't have enough money." );

			p_WeedDealer[ pID ] = playerid;
			p_WeedTick[ pID ] = GetTickCount( );
			p_WeedSellingGrams[ pID ] = iAmount;
			p_SellingWeedTick[ playerid ] = g_iTime + 60;
			SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} %s(%d) is selling you %d gram(s) of weed for %s. "COL_ORANGE"/weed buy"COL_WHITE" to buy.", ReturnPlayerName( playerid ), playerid, iAmount, cash_format( iCost ) );
			SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} You have sent an offer to %s(%d) to buy a %d gram(s) of weed for "COL_GOLD"%s.", ReturnPlayerName( pID ), pID, iAmount, cash_format( iTaxed ) );
	    }
	    else SendError( playerid, "This player is not nearby." );
	}
	else if ( strmatch( params, "buy" ) )
	{
	    if ( !IsPlayerConnected( p_WeedDealer[ playerid ] ) ) return SendError( playerid, "Your dealer isn't connected anymore." );
		else if ( hasTickcountPassed( p_WeedTick[ playerid ], 120000 ) ) return p_WeedDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, each deal goes for 2 minutes maximum. You were late." );
		else
		{
		    new
		    	dealerid = p_WeedDealer[ playerid ],
		    	iGrams 	 = p_WeedSellingGrams[ playerid ],
		    	iCost 	 = iGrams * 5000,
		    	iTaxed 	 = floatround( iCost * 0.8 )
		    ;

			if ( GetPlayerCash( playerid ) < iCost ) return SendError( playerid, "You need %s to buy %d grams of weed.", cash_format( iCost ), iGrams );
			else if ( IsPlayerInPaintBall( dealerid ) || IsPlayerDueling( dealerid ) ) return SendError( playerid, "Your dealer cannot deal in an arena." );
			else if ( p_Class[ dealerid ] != CLASS_CIVILIAN ) return p_WeedDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, the dealer is not a civilian." );
			else if ( !IsPlayerJob( dealerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "Your dealer no longer does drugs." );
			else if ( !p_WeedGrams[ dealerid ] ) return p_WeedDealer[ playerid ] = INVALID_PLAYER_ID,  SendError( playerid, "Your dealer doesn't have any more weed." );
			else if ( ( p_WeedGrams[ playerid ] + iGrams ) > MAX_WEED_STORAGE ) return SendError( playerid, "You can only carry %d grams of weed.", MAX_WEED_STORAGE );
			else
			{
	         	p_WeedGrams[ playerid ] += iGrams;
	         	p_WeedGrams[ dealerid ] -= iGrams;

				GivePlayerCash( playerid, -iCost );
				GivePlayerCash( dealerid, iTaxed );

				SendClientMessageFormatted( dealerid, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} %s(%d) has bought %d grams of weed off you for %s.", ReturnPlayerName( playerid ), playerid, iGrams, cash_format( iTaxed ) );
				SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} You have bought %d grams of weed for %s.", iGrams, cash_format( iCost ) );

				GivePlayerWantedLevel( dealerid, 6 );
				GivePlayerWantedLevel( playerid, 6 );

				Beep( dealerid );
				p_WeedDealer[ playerid ] = INVALID_PLAYER_ID;
			}
		}
	}
	else if ( strmatch( params, "use" ) )
	{
    	if ( GetPVarInt( playerid, "weed_timestamp" ) > g_iTime ) return SendError( playerid, "You must wait at least %d seconds before using this command.", GetPVarInt( playerid, "weed_timestamp" ) - g_iTime );
		if ( p_WeedGrams[ playerid ] < 1 ) return SendError( playerid, "You don't have any weed with you." );
		if ( p_Jailed{ playerid } == true ) return SendError( playerid, "You cannot use this in jail." );
		if ( IsPlayerLoadingObjects( playerid ) ) return SendError( playerid, "You're in a object-loading state, please wait." );
		if ( IsPlayerAttachedObjectSlotUsed( playerid, 0 ) ) return SendError( playerid, "You cannot use this command since you're robbing." );
		// if ( IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "You cannot use your own products, they are for resale only!" );
		if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
		//if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command in a vehicle." );
	    //if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER || GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_PASSENGER ) return SendError( playerid, "You cannot use this command if you're entering a vehicle." );
	    //if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE ) return SendError( playerid, "You cannot use this command if you're exiting a vehicle." );
		//if ( p_InAnimation{ playerid } || GetPlayerSpecialAction( playerid ) != SPECIAL_ACTION_NONE ) return SendError( playerid, "You cannot use this command since you're in animation." );
		SetPVarInt( playerid, "weed_timestamp", g_iTime + 120 );
		p_WeedGrams[ playerid ]--;
		SetPlayerHealth( playerid, 150 );
		SetPlayerDrunkLevel( playerid, 5000 );
		SendServerMessage( playerid, "You have smoked a gram of weed." );
		DestroyDynamic3DTextLabel( p_WeedLabel[ playerid ] );
	    p_WeedLabel[ playerid ] = CreateDynamic3DTextLabel( "Blazed W33D Recently!", COLOR_GREEN, X, Y, Z + 1.0, 15, playerid );
		//ApplyAnimation( playerid, "GANGS", "smkcig_prtl", 4.1, 0, 1, 1, 0, 0, 1 );
	}
	else return SendUsage( playerid, "/weed [COLLECT/SELL/BUY/USE]" );
	return 1;
}

CMD:ach( playerid, params[ ] ) return cmd_achievements( playerid, params );
CMD:achievements( playerid, params[ ] )
{
	displayAchievements( playerid );
	return 1;
}

CMD:idof( playerid, params[ ] )
{
	new pID;
	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/idof [PART_OF_NAME]" );
	if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player isn't connected." );
	SendServerMessage( playerid, "%s: "COL_GREY"%d", ReturnPlayerName( pID ), pID );
	return 1;
}

CMD:playercolor( playerid, params[ ] ) return cmd_pc( playerid, params );
CMD:pc( playerid, params[ ] )
{
    ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}Player Colors", "Innocent\n{FFEC41}Low Suspect\n"COL_ORANGE"Wanted\n{F83245}Most Wanted\n{3E7EFF}Police\n{0035FF}F.B.I\n{191970}C.I.A\n{954BFF}Army\n{A83434}Fireman\n{00CC00}Paramedic\n"COL_PINK"Admin On Duty\n"COL_GREY"Other Colors Are Gang Colors", "Okay", "" );
	return 1;
}

CMD:robstore( playerid, params[ ] )
{
	SendServerMessage( playerid, "This command binds your walking key, so you must be in a robbery checkpoint to get a response!" );
	CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_WALK, KEY_SPRINT );
	return 1;
}

CMD:myaccid( playerid, params[ ] )
{
    SendServerMessage( playerid, "Your account ID is "COL_GOLD"%d"COL_WHITE".", p_AccountID[ playerid ] );
	return 1;
}

CMD:job( playerid, params[ ] )
{
    if ( p_VIPLevel[ playerid ] >= VIP_GOLD && p_VIPJob{ playerid } != p_Job{ playerid } )
    	return SendServerMessage( playerid, "Your jobs are "COL_GOLD"%s"COL_WHITE" and "COL_GOLD"%s"COL_WHITE".", GetJobName( p_Job{ playerid } ), GetJobName( p_VIPJob{ playerid } ) );

    if ( p_VIPLevel[ playerid ] >= VIP_GOLD && p_VIPJob{ playerid } == p_Job{ playerid } )
    	return SendServerMessage( playerid, "Your jobs are "COL_GOLD"%s"COL_WHITE" and your VIP job is disabled.", GetJobName( p_Job{ playerid } ) );

   	SendServerMessage( playerid, "Your job is a "COL_GOLD"%s"COL_WHITE".", GetJobName( p_Job{ playerid } ) );
	return 1;
}

CMD:jaillist( playerid, params[ ] )
{
	szBigString[ 0 ] = '\0';

    foreach( new i : Player ) if ( IsPlayerJailed( i ) ) {
        format( szBigString, sizeof( szBigString ), "%s%s%s(%d)\t%d seconds", szBigString, p_AdminJailed{ i } ? ( COL_RED ) : ( COL_WHITE ), ReturnPlayerName( i ), i, p_JailTime[ i ] );
    }

    if ( szBigString[ 0 ] == '\0' )   {
        return SendError( playerid, "There are no players in jail." );
    } else {
        return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, ""COL_WHITE"Jail List", szBigString, "Close", "" );
    }
}

CMD:lastlogged( playerid, params[ ] )
{
	static
	    player[ MAX_PLAYER_NAME ]
	;

	if ( sscanf( params, "s[24]", player ) ) return SendUsage( playerid, "/lastlogged [PLAYER_NAME]" );
	else
	{
		format( szNormalString, sizeof( szNormalString ), "SELECT `LASTLOGGED` FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
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
		cache_get_field_content( 0, "LASTLOGGED", Field );

		time = g_iTime - strval( Field );
		if ( time > 86400 )
		{
		    time /= 86400;
		    format( Field, sizeof( Field ), "%d day(s) ago.", time );
		}
		else if ( time > 3600 )
		{
		    time /= 3600;
		    format( Field, sizeof( Field ), "%d hour(s) ago.", time );
		}
		else
		{
		    time /= 60;
		    format( Field, sizeof( Field ), "%d minute(s) ago.", time );
		}

		if ( !irc ) SendClientMessageFormatted( playerid, COLOR_GREY, "[SERVER]"COL_RED" %s:"COL_WHITE" Last Logged: %s", player, Field );
		else {
			format( szNormalString, sizeof( szNormalString ),"7LAST LOGGED OF '%s': %s", player, Field );
			DCC_SendChannelMessage( discordGeneralChan, szNormalString );
		}
	}
	else {
		if ( !irc ) SendError( playerid, "Player not found." );
	}
	return 1;
}

CMD:weeklytime( playerid, params[ ] )
{
	static
	    player[ MAX_PLAYER_NAME ]
	;

	if ( sscanf( params, "s[24]", player ) ) return SendUsage( playerid, "/weeklytime [PLAYER_NAME]" );
	else
	{
		format( szNormalString, sizeof( szNormalString ), "SELECT `UPTIME`,`WEEKEND_UPTIME` FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
  		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerWeeklyTime", "iis", playerid, 0, player );
	}
	return 1;
}

thread OnPlayerWeeklyTime( playerid, irc, player[ ] )
{
	new
	    rows, fields,
	    iCurrentUptime, iLastUptime
	;
    cache_get_data( rows, fields );
	if ( rows )
	{
		iCurrentUptime 	= cache_get_field_content_int( 0, "UPTIME", dbHandle );
		iLastUptime 	= cache_get_field_content_int( 0, "WEEKEND_UPTIME", dbHandle );

		if ( !irc ) SendClientMessageFormatted( playerid, COLOR_GREY, "[SERVER]"COL_GREY" %s:"COL_WHITE" %s", player, secondstotime( iCurrentUptime - iLastUptime ) );
		else
		{
			format( szNormalString, sizeof( szNormalString ),"7WEEKLY TIME OF '%s': %s", player, secondstotime( iCurrentUptime - iLastUptime ) );
			DCC_SendChannelMessage( discordGeneralChan, szNormalString );
		}
	}
	else
	{
		if ( !irc )
			SendError( playerid, "Player not found." );
	}
	return 1;
}

CMD:emp( playerid, params[ ] )
{
	new
		pID
	;
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to Police only." );
	else if ( p_inCIA{ playerid } == false || p_inArmy{ playerid } == true ) return SendError( playerid, "This is restricted to CIA only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/emp [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot do this to yourself." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You are kidnapped, you cannot do this." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You are tied, you cannot do this." );
	else if ( IsPlayerAdminOnDuty( pID ) ) return SendError( playerid, "This person is an admin on duty!" );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "This person is a apart of the Police Force." );
	else if ( !p_WantedLevel[ pID ] ) return SendError( playerid, "This person is innocent!" );
	else if ( !IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "This player isn't inside any vehicle." );
	else if ( GetPlayerState( pID ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "This player is not a driver of any vehicle." );
	//else if ( g_buyableVehicle{ GetPlayerVehicleID( pID ) } == true ) return SendError( playerid, "Failed to place a Electromagnetic Pulse on this player's vehicle." );
    else if ( GetDistanceBetweenPlayers( playerid, pID ) < 30.0 )
	{
	    /* ** ANTI EMP SPAM ** */
	    if ( p_AntiEmpSpam[ pID ] > g_iTime )
	    	return SendError( playerid, "You cannot EMP this person for %s.", secondstotime( p_AntiEmpSpam[ pID ] - g_iTime ) );
	    /* ** END OF ANTI SPAM ** */

	    new
	    	iVehicle = GetPlayerVehicleID( pID );

		if ( g_buyableVehicle{ iVehicle } )
			return SendError( playerid, "Failed to place a Electromagnetic Pulse on this player's vehicle." );

		p_AntiEmpSpam[ pID ] = g_iTime + 60;

	    if ( p_AntiEMP[ pID ] > 0 )
	    {
		    p_AntiEMP[ pID ] --;

		    new
		    	iRandom = random( 101 );

		    //if ( g_buyableVehicle{ iVehicle } )
		    	//iRandom -= 50;

	    	if ( iRandom < 90 )
	    	{
		        SendClientMessage( playerid, -1, ""COL_RED"[EMP]{FFFFFF} An Electromagnetic Pulse attempt has been repelled by an aluminum foil!" );
				SendClientMessage( pID, -1, ""COL_GREEN"[EMP]{FFFFFF} Electromagnetic Pulse had been repelled by aluminum foil set on vehicle." );
	    		return 1;
	    	}
	    }

 		SendClientMessageFormatted( pID, -1, ""COL_RED"[EMP]{FFFFFF} %s(%d) has sent an electromagnetic pulse on your vehicle causing it to crash for 30 seconds.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[EMP]{FFFFFF} You have activated a electromagnetic pulse on %s(%d)'s vehicle!", ReturnPlayerName( pID ), pID );
		SetTimerEx( "emp_deactivate", 30000, false, "d", GetPlayerVehicleID( pID ) );
		GetVehicleParamsEx( iVehicle, engine, lights, alarm, doors, bonnet, boot, objective );
		SetVehicleParamsEx( iVehicle, VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective );
	}
	else SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:moviemode( playerid, params[ ] )
{
	switch( p_inMovieMode{ playerid } )
	{
		case true:
		{
			ShowPlayerTogglableTextdraws( playerid );
		    PlayerTextDrawShow( playerid, p_LocationTD[ playerid ] );
			if ( IsDoubleXP( ) ) TextDrawShowForPlayer( playerid, g_DoubleXPTD );
			TextDrawShowForPlayer( playerid, g_WebsiteTD );
			if ( p_WantedLevel[ playerid ] ) PlayerTextDrawShow( playerid, p_WantedLevelTD[ playerid ] );
			TextDrawShowForPlayer( playerid, g_MotdTD );
			if ( g_HappyHour ) TextDrawShowForPlayer( playerid, g_NotManyPlayersTD );
			if ( p_FPSCounter{ playerid } ) TextDrawShowForPlayer( playerid, p_FPSCounterTD[ playerid ] );
			if ( p_AdminOnDuty{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminOnDutyTD );
			TextDrawShowForPlayer( playerid, g_WorldDayTD );
			PlayerTextDrawShow( playerid, g_ZoneOwnerTD[ playerid ] );
			for( new i; i < sizeof( g_MovieModeTD ); i ++ ) TextDrawHideForPlayer( playerid, g_MovieModeTD[ i ] );
		    p_inMovieMode{ playerid } = false;
		    SendServerMessage( playerid, "Movie mode has been un-toggled." );
		}
		case false:
		{
			PlayerTextDrawHide( playerid, g_ZoneOwnerTD[ playerid ] );
			HidePlayerTogglableTextdraws( playerid );
			PlayerTextDrawHide( playerid, p_LocationTD[ playerid ] );
			PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
			TextDrawHideForPlayer( playerid, g_WebsiteTD );
			TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
			TextDrawHideForPlayer( playerid, g_DoubleXPTD );
			TextDrawHideForPlayer( playerid, g_MotdTD );
			TextDrawHideForPlayer( playerid, g_NotManyPlayersTD );
			TextDrawHideForPlayer( playerid, g_WorldDayTD );
			TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );
			for( new i; i < sizeof( g_MovieModeTD ); i ++ ) TextDrawShowForPlayer( playerid, g_MovieModeTD[ i ] );
		    p_inMovieMode{ playerid } = true;
		    SendServerMessage( playerid, "Movie mode has been toggled." );
		}
	}
	CallLocalFunction( "OnPlayerMovieMode", "dd", playerid, p_inMovieMode{ playerid } );
	return 1;
}

CMD:hidelabel( playerid, params[ ] ) return cmd_rlabel( playerid, params );
CMD:rlabel( playerid, params[ ] )
{
	if ( p_InfoLabel[ playerid ] == Text3D: INVALID_3DTEXT_ID )
		return SendError( playerid, "You do not have any label on your head to remove." );

	p_LabelColor[ playerid ] = COLOR_GREY;
	Delete3DTextLabel( p_InfoLabel[ playerid ] );
	p_InfoLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	SendServerMessage( playerid, "You have removed your label from your head." );
	return 1;
}

CMD:labelinfo( playerid, params[ ] )
{
    if ( p_InfoLabel[ playerid ] != Text3D: INVALID_3DTEXT_ID )
    {
        SendServerMessage( playerid, "{%06x}%s", p_LabelColor[ playerid ] >>> 8, p_InfoLabelString[ playerid ] );
    }
    else SendError( playerid, "You don't have a label attached on you." );
	return 1;
}

CMD:label( playerid, params[ ] )
{
	new
		szLabel[ 32 ]
	;

	if ( GetPlayerScore( playerid ) < 500 ) return SendError( playerid, "You need 500 score to use this command." );
	else if ( sscanf( params, "s[32]", szLabel ) ) return SendUsage( playerid, "/label [MESSAGE]" );
	else
	{
	    Delete3DTextLabel( p_InfoLabel[ playerid ] );
	    format( p_InfoLabelString[ playerid ], sizeof( p_InfoLabelString[ ] ), "%s", szLabel );
		p_InfoLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	    p_InfoLabel[ playerid ] = Create3DTextLabel( szLabel, p_LabelColor[ playerid ], 0.0, 0.0, 0.0, 15.0, 0 );
	    Attach3DTextLabelToPlayer( p_InfoLabel[ playerid ], playerid, 0.0, 0.0, 0.4 );
	    SendServerMessage( playerid, "You placed a label above your head containing the text above." );
	}
	return 1;
}

CMD:labelcolor( playerid, params[ ] )
{
	new
		szLabel[ 7 ];

	if ( sscanf( params, "s[7]", szLabel ) ) return SendUsage( playerid, "/labelcolor [HEX CODE (= normal)]" );
	else if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
	else if ( strmatch( szLabel, "normal" ) )
	{
		p_LabelColor[ playerid ] = COLOR_GREY;
		Update3DTextLabelText( p_InfoLabel[ playerid ], COLOR_GREY, p_InfoLabelString[ playerid ] );
		return SendServerMessage( playerid, "You've successfully reset your label's color." );
	}
	else if ( strlen( szLabel ) != 6 ) return SendError( playerid, "Your hex code must be equal to six characters. "COL_ORANGE"Format: RRGGBB" );
	else if ( p_InfoLabel[ playerid ] == Text3D: INVALID_3DTEXT_ID ) return SendError( playerid, "You don't have a label attached on you." );
	else if ( strmatch( szLabel, "FF0770" ) ) return SendError( playerid, "This colour is strictly prohibited and can result in ban." );
	else if ( !isHex( szLabel ) ) return SendError( playerid, "Invalid Hex Code." );
	else
	{
		SendServerMessage( playerid, "You have changed your {%s}label's color to this{FFFFFF}. To reset: "COL_GREY"/labelcolor normal"COL_WHITE".", szLabel );
		format( szNormalString, 11, "0x%sFF", szLabel );
		p_LabelColor[ playerid ] = HexToInt( szNormalString );
		Update3DTextLabelText( p_InfoLabel[ playerid ], p_LabelColor[ playerid ], p_InfoLabelString[ playerid ] );
	}
	return 1;
}

CMD:changepassword( playerid, params[ ] ) return cmd_changepw( playerid, params );
CMD:changepass( playerid, params[ ] ) return cmd_changepw( playerid, params );
CMD:changepw( playerid, params[ ] )
{
	static
		szHashed[ 129 ], szSalt[ 25 ];

	if ( !p_PlayerLogged{ playerid } ) return SendError( playerid, "You are not logged in." );
	if ( isnull( params ) ) return SendUsage( playerid, "/change(pw/pass/password) [PASSWORD]" );
	if ( strlen( params ) > 24 || strlen( params ) < 3 ) return SendError( playerid, "Your password must be indexed within 3 and 24 characters." );

 	randomString( szSalt, 24 );
 	pencrypt( szHashed, sizeof( szHashed ), params, szSalt );

	format( szBigString, sizeof( szBigString ), "UPDATE `USERS` SET `PASSWORD`='%s', `SALT`='%s' WHERE `ID`=%d", szHashed, mysql_escape( szSalt ), p_AccountID[ playerid ] );
	mysql_single_query( szBigString );

	GameTextForPlayer( playerid, "~r~Password changed!", 5000, 3 );
	SendClientMessageFormatted( playerid, COLOR_GOLD, "[PASSWORD CHANGED]"COL_WHITE" You have successfully changed your password to \""COL_GREY"%s"COL_WHITE"\", make sure you remember!", params );
	return 1;
}

CMD:richlist( playerid, params[ ] )
{
	new g_richList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player ) {
		g_richList[ player ] [ 0 ] = player;
		g_richList[ player ] [ 1 ] = GetPlayerTotalCash( player );
	}

	// sort
	SortDeepArray( g_richList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"Player\t"COL_WHITE"Holding Money\t"COL_WHITE"Bank Money\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_richList[ i ] [ 0 ] ) && g_richList[ i ] [ 1 ] > 50000 )
	{
		new
			rich_player = g_richList[ i ] [ 0 ];

 		format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t"COL_GOLD"%s\t{666666}%s\n", szLargeString, ReturnPlayerName( rich_player ), rich_player, cash_format( GetPlayerCash( rich_player ) ), cash_format( p_BankMoney[ rich_player ] ) );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "There are no rich players to show." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Rich Players Online", szLargeString, "Close", "" ), 1;
	}
}

CMD:getwanted( playerid, params[ ] ) return cmd_mostwanted( playerid, params );
CMD:mostwanted( playerid, params[ ] )
{
	new g_wantedList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player ) {
		g_wantedList[ player ] [ 0 ] = player;
		g_wantedList[ player ] [ 1 ] = p_WantedLevel[ player ];
	}

	// sort
	SortDeepArray( g_wantedList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"Player\t"COL_WHITE"Wanted Level\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_wantedList[ i ] [ 0 ] ) && g_wantedList[ i ] [ 1 ] > 0 ) {
 		format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t"COL_GOLD"%d\n", szLargeString, ReturnPlayerName( g_wantedList[ i ] [ 0 ] ), g_wantedList[ i ] [ 0 ], g_wantedList[ i ] [ 1 ] );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "There are no wanted players to show." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Wanted Players Online", szLargeString, "Close", "" ), 1;
	}
}

CMD:contracts( playerid, params[ ] ) return cmd_hitlist( playerid, params );
CMD:hitlist( playerid, params[ ] )
{
	// if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );

	new g_contractList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player )
	{
		g_contractList[ player ] [ 0 ] = player;
		g_contractList[ player ] [ 1 ] = p_ContractedAmount[ player ];
	}

	// sort
	SortDeepArray( g_contractList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"Player\t"COL_WHITE"Total Contract\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_contractList[ i ] [ 0 ] ) && g_contractList[ i ] [ 1 ] >= 1000 ) {
 		format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t"COL_GOLD"%s\n", szLargeString, ReturnPlayerName( g_contractList[ i ] [ 0 ] ), g_contractList[ i ] [ 0 ], cash_format( g_contractList[ i ] [ 1 ] ) );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "There are no contracted players to show." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Contracted Players Online", szLargeString, "Close", "" ), 1;
	}
}

CMD:rules( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Rules", szRules, "Okay", "" );
	return 1;
}

#if ENABLE_DISCORD == true
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
#endif

CMD:viewguns( playerid, params[ ] )
{
	/* ** COOL DOWN ** */
    if ( GetPVarInt( playerid, "weapon_buy_cool" ) > g_iTime ) return SendError( playerid, "You must wait 40 seconds before buying a weapon from someone again." );
    /* ** END OF COOL DOWN ** */

	if ( !IsPlayerConnected( p_WeaponDealer[ playerid ] ) ) return p_WeaponDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "Your weapon dealer isn't available." );
	else if ( g_iTime > p_WeaponDealTick[ playerid ] ) return SendError( playerid, "Your last weapon deal has expired." );
	else if ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) ) return SendError( playerid, "You can't buy weapons in an arena." );
	else
	{
	    p_WeaponDealing{ playerid } = true;
		ShowAmmunationMenu( playerid, "{FFFFFF}Weapon Deal - Purchase Weapons", DIALOG_WEAPON_DEAL );
		SendClientMessageFormatted( p_WeaponDealer[ playerid ], -1, ""COL_GREY"[SERVER]"COL_WHITE" %s(%d) is now viewing your weapon selection.", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

CMD:sellgun( playerid, params[ ] )
{
	new
	    pID
	;

	if ( !IsPlayerJob( playerid, JOB_WEAPON_DEALER ) ) return SendError( playerid, "You aren't a weapon dealer." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "Only civilians can use this command." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/sellgun [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot sell yourself a weapon." );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "You cannot sell weapons to law enforcement officers." );
	else if ( p_WeaponDealing{ pID } == true ) return SendError( playerid, "This player is currently busy." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "You cannot sell weapons while you're in jail." );
	else if ( p_Jailed{ pID } ) return SendError( playerid, "This player is jailed, you cannot sell weapons to him." );
	else if ( IsPlayerInPaintBall( pID ) || IsPlayerDueling( pID ) ) return SendError( playerid, "You can't sell weapons in an arena." );
	else if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 5.0 )
	{
		SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[WEAPON DEAL]{FFFFFF} %s(%d) wishes to sell you weapons. "COL_ORANGE"/viewguns{FFFFFF} to view the available weapons.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[WEAPON DEAL]{FFFFFF} You have sent an offer to %s(%d) to buy guns.", ReturnPlayerName( pID ), pID );
		p_WeaponDealer[ pID ] = playerid;
		p_WeaponDealTick[ pID ] = g_iTime + 60;
	}
	else SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:ej( playerid, params[ ] ) return cmd_eject( playerid, params );
CMD:eject( playerid, params[ ] )
{
	new
	    pID
	;

	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/eject [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You're not in any vehicle." );
	else if ( !IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "This player isn't in any vehicle" );
	else if ( pID == playerid ) return SendError( playerid, "This command is created for ejecting passengers only." );
	else if ( GetPlayerVehicleID( pID ) != GetPlayerVehicleID( playerid ) ) return SendError( playerid, "This player isn't inside your vehicle" );
	else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You are not the driver of this vehicle." );
	//else if ( p_Detained{ pID } ) return SendError( playerid, "This player has his cuffs locked onto his seat. You can't eject him." );
	else
	{
	    if ( p_Kidnapped{ pID } == true ) p_Kidnapped{ pID } = false;
	    //if ( p_Detained{ pID } == true ) p_Detained{ pID } = false;
	    RemovePlayerFromVehicle( pID );
		SyncObject( pID, 0.0, 2.0, 2.0 );
    	GameTextForPlayer( pID, "~r~EJECTED~w~!", 3500, 3 );
    	SendServerMessage( playerid, "Player has been ejected from your vehicle." );
	}
	return 1;
}

CMD:ejectall( playerid, params[ ] )
{
	new
	    iEjectCounter = 0,
		iPlayerSeat = GetPlayerVehicleSeat( playerid ),
		iPlayerVehicle = GetPlayerVehicleID( playerid )
	;

	if ( !IsPlayerInAnyVehicle( playerid ) ) {
		return SendError( playerid, "You're not in a vehicle." );
	}

	if ( iPlayerSeat != 0 ) {
		return SendError( playerid, "You're not the driver of this vehicle." );
	}

	foreach(new i : Player)
	{
		new
			iTargetVehicle = GetPlayerVehicleID( i ),
			iTargetSeat = GetPlayerVehicleSeat( i )
		;

		if ( iTargetVehicle == iPlayerVehicle && iTargetSeat >= 1 && iTargetSeat <= 3 ) {
			// change variables
		    if ( p_Kidnapped{ i } == true ) p_Kidnapped{ i } = false;
		    //if ( p_Detained{ i } == true ) p_Detained{ i } = false;

		    // remove from vehicle
			RemovePlayerFromVehicle( i );
			SyncObject( i, 0.0, 2.0, 2.0 );
			GameTextForPlayer( i, "~r~EJECTED~w~!", 3500, 3 );

			// increment players ejected
			iEjectCounter++;
		}
	}

	if ( ! iEjectCounter )
		return SendError( playerid, "You do not have any passengers to eject." );

	return SendServerMessage( playerid, "You have ejected %d player%s from your vehicle.", iEjectCounter, iEjectCounter > 1 ? ( "s" ) : ( "" ) );
}

CMD:bail( playerid, params[ ] )
{
	new
	    pID,
	    equa
	;

	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/bail [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot bail yourself." );
	else if ( !IsPlayerJailed( pID ) ) return SendError( playerid, "This player isn't jailed." );
	else if ( IsPlayerAdminJailed( pID ) ) return SendError( playerid, "This player has been admin jailed." );
	else if ( IsPlayerSettingToggled( pID, SETTING_BAILOFFERS ) ) return SendError( playerid, "This player has disabled bail notifications." );
	else if ( GetPVarInt( pID, "bail_antispam" ) > g_iTime ) return SendError( playerid, "You must wait 10 seconds before offering a bail to this player." );
	else
	{
	    equa = 50 * p_JailTime[ pID ];
	    if ( p_JailTime[ pID ] >= ALCATRAZ_TIME_WANTED ) equa *= 2;
	    p_BailOfferer[ pID ] = playerid;
	    p_BailTimestamp[ pID ] = g_iTime + 120;
	    SetPVarInt( pID, "bail_antispam", g_iTime + 1 );
	    SendServerMessage( playerid, "You have offered %s(%d) bail for "COL_GOLD"%s", ReturnPlayerName( pID ), pID, cash_format( equa ) );
	    SendClientMessageFormatted( pID, -1, ""COL_GREY"[SERVER]"COL_WHITE" %s(%d) has offered to bail you out for "COL_GOLD"%s"COL_WHITE". "COL_ORANGE"/acceptbail"COL_WHITE" to accept the bail.", ReturnPlayerName( playerid ), playerid, cash_format( equa ) );
	}
	return 1;
}

CMD:acceptbail( playerid, params[ ] )
{
	new
	    equa = 50 * p_JailTime[ playerid ];

	if ( p_JailTime[ playerid ] >= ALCATRAZ_TIME_WANTED )
		equa *= 2;

	if ( GetPlayerCash( playerid ) < equa ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "You don't have enough to be bailed." );
	else if ( IsPlayerAdminJailed( playerid ) ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "You have been admin jailed, therefore disallowing this." );
	else if ( !IsPlayerJailed( playerid ) ) return SendError( playerid, "You're not jailed!" );
	else if ( !IsPlayerConnected( p_BailOfferer[ playerid ] ) ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "The person who offered you bail is not connected." );
	else if ( p_BailTimestamp[ playerid ] < g_iTime ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This offer has expired a minute ago." );
	else
	{
		new
			cashEarned = floatround( equa * 0.75 );

	    GivePlayerCash( playerid, -equa );
		GivePlayerCash( p_BailOfferer[ playerid ], cashEarned );
		SendClientMessageFormatted( p_BailOfferer[ playerid ], -1, ""COL_GREEN"[BAIL]"COL_WHITE" %s(%d) has paid bail. You have earned "COL_GOLD"%s"COL_WHITE" from his bail.", ReturnPlayerName( playerid ), playerid, cash_format( cashEarned ) );
    	p_BailOfferer[ playerid ] = INVALID_PLAYER_ID;
        SendServerMessage( playerid, "You have paid for your bail. You are now free!" );
	   	CallLocalFunction( "OnPlayerUnjailed", "dd", playerid, 1 );
	}
	return 1;
}

CMD:acceptbj( playerid, params[ ] )
{
	if ( !IsPlayerConnected( p_BlowjobOfferer[ playerid ] ) ) return p_BlowjobOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "Your blowjob offerer isn't available." );
	else if ( g_iTime > p_BlowjobDealTick[ playerid ] ) return SendError( playerid, "Your blowjob offer has expired." );
	else if ( !IsPlayerJob( p_BlowjobOfferer[ playerid ], JOB_PROSTITUTE ) ) return SendError( playerid, "Your blowjob offerer no longer offers blowjobs." );
	else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot get a blowjob inside a car." );
	else if ( IsPlayerInAnyVehicle( p_BlowjobOfferer[ playerid ] ) ) return SendError( playerid, "This player is inside a car." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot accept blowjobs in jail." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot accept blowjobs while tied." );
	else if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot accept blowjobs while tazed." );
	else if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot accept blowjobs while cuffed." );
	else if ( IsPlayerRobbing( playerid ) ) return SendError( playerid, "You cannot accept blowjobs while robbing a store." );
	else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
	else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
	else if ( GetPlayerCash( playerid ) < p_BlowjobPrice[ playerid ] ) return SendError( playerid, "You cannot afford this blowjob." );
	else if ( IsPlayerAttachedObjectSlotUsed( playerid, 4 ) || IsPlayerAttachedObjectSlotUsed( playerid, 3 ) ) return SendError( playerid, "Your hands are busy at the moment." );
	else if ( GetDistanceBetweenPlayers( playerid, p_BlowjobOfferer[ playerid ] ) < 4.0 )
	{
		new
		    Float: X, Float: Y, Float: Z, Float: Angle,
		    iPrice = p_BlowjobPrice[ playerid ],
		    iEarned = floatround( iPrice * 0.90 )
		;

		SendClientMessageFormatted( p_BlowjobOfferer[ playerid ], -1, ""COL_ORANGE"[BLOWJOB]{FFFFFF} %s(%d) has accepted your blowjob offer for "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( playerid ), playerid, cash_format( iPrice ) );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[BLOWJOB]{FFFFFF} You are now recieving a blowjob." );
		TogglePlayerControllable( p_BlowjobOfferer[ playerid ], 0 );
		TogglePlayerControllable( playerid, 0 );
		GetPlayerFacingAngle( p_BlowjobOfferer[ playerid ], Angle );
		SetPlayerFacingAngle( playerid, Angle - 180 );
		GetXYInFrontOfPlayer( p_BlowjobOfferer[ playerid ], X, Y, Z, 1 );
		SetPlayerPos( playerid, X, Y, Z );
		ApplyAnimation( playerid, "BLOWJOBZ", "BJ_STAND_START_P", 1.0, 1, 1, 1, 0, 0, 1 );
		ApplyAnimation( p_BlowjobOfferer[ playerid ], "BLOWJOBZ", "BJ_STAND_START_W", 1.0, 1, 1, 1, 0, 0, 1 );
		SetTimerEx( "BlowJob", 1500, false, "ddd", p_BlowjobOfferer[ playerid ], playerid, 0 );
		p_GettingBlowjob{ playerid } = true;
 		p_GivingBlowjob{ p_BlowjobOfferer[ playerid ] } = true;
		GivePlayerCash( playerid, -iPrice );
		GivePlayerCash( p_BlowjobOfferer[ playerid ], iEarned );
		p_BlowjobOfferer[ playerid ] = INVALID_PLAYER_ID;
	}
	else SendError( playerid, "This prostitute is not nearby." );
	return 1;
}

CMD:blowjob( playerid, params[ ] ) return cmd_bj( playerid, params );
CMD:bj( playerid, params[ ] )
{
	new
	    pID, price
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
	else if ( !IsPlayerJob( playerid, JOB_PROSTITUTE ) ) return SendError( playerid, "You must be a prostitute to use this command." );
	else if ( ( GetTickCount( ) - p_AntiBlowJobSpam[ playerid ] ) < 30000 ) return SendError( playerid, "You must wait 30 seconds before using this command again." );
	else if ( sscanf( params, "ud", pID, price ) ) return SendUsage( playerid, "/(bj)blowjob [PLAYER_ID] [PRICE]" );
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player isn't connected." );
	else if ( price < 20 || price > 3000 ) return SendError( playerid, "Please specify a price between $20 and $3,000." );
	else if ( playerid == pID ) return SendError( playerid, "You cannot give a blowjob to yourself." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot offer blowjobs in jail." );
	else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
	else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
	else if ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || IsPlayerPlayingPool( playerid ) ) return SendError( playerid, "You cannot use this command in a minigame." );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 4.0 )
	{
		if ( IsPlayerJailed( pID ) ) return SendError( playerid, "This player is jailed. He may be paused." );
	  	SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[BLOWJOB]{FFFFFF} %s(%d) wishes to give you a blowjob for "COL_GOLD"%s"COL_WHITE". "COL_ORANGE"/acceptbj{FFFFFF} to accept.", ReturnPlayerName( playerid ), playerid, cash_format( price ) );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[BLOWJOB]{FFFFFF} You have offered a blowjob to %s(%d) for "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( pID ), pID, cash_format( price ) );
		p_BlowjobOfferer[ pID ] = playerid;
	    p_BlowjobDealTick[ pID ] = g_iTime + 60;
	    p_BlowjobPrice[ pID ] = price;
 		p_AntiBlowJobSpam[ playerid ] = GetTickCount( );
	}
	else SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:report( playerid, params[ ] )
{
	new
		iPlayer,
		szMessage[ 64 ]
	;

    if ( sscanf( params, "us[64]", iPlayer, szMessage ) ) return SendUsage( playerid, "/report [PLAYER_ID] [REASON]" );
    else if ( !IsPlayerConnected( iPlayer ) || IsPlayerNPC( iPlayer ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( p_CantUseReport{ playerid } == true ) return SendError( playerid, "You have been blocked to use this command by an admin." );
	else if ( GetPVarInt( iPlayer, "report_antispam" ) > g_iTime ) return SendError( playerid, "You must wait 10 seconds before reporting this player." );
    else
	{
		for( new iPos; iPos < sizeof( szReportsLog ) - 1; iPos++ )
			memcpy( szReportsLog[ iPos ], szReportsLog[ iPos + 1 ], 0, sizeof( szReportsLog[ ] ) * 4 );

		format( szNormalString, sizeof( szNormalString ), "%s\t%s(%d)\t%s(%d)\t%s\n", getCurrentTime( ), ReturnPlayerName( playerid ), playerid, ReturnPlayerName( iPlayer ), iPlayer, szMessage );
		strcpy( szReportsLog[ 7 ], szNormalString );

		Beep( playerid );
		SetPVarInt( iPlayer, "report_antispam", g_iTime + 10 );

        SendClientMessageToAdmins( -1, ""COL_RED"[REPORT] %s(%d) reported %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( iPlayer ), iPlayer, szMessage );
		SendClientMessageFormatted( playerid, -1, ""COL_RED"[REPORT]"COL_WHITE" You have reported %s(%d) for \"%s\".", ReturnPlayerName( iPlayer ), iPlayer, szMessage );
	}
	return 1;
}

CMD:bu( playerid, params[ ] ) return cmd_backup( playerid, params );
CMD:backup( playerid, params[ ] )
{
    if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "The police are authorized to use this only." );
    SendClientMessageToCops( -1, ""COL_BLUE"[POLICE RADIO]"COL_WHITE" %s is requesting back up at %s.", ReturnPlayerName( playerid ), GetPlayerArea( playerid ) );
	return 1;
}

CMD:sm( playerid, params[ ] ) return cmd_sendmoney( playerid, params );
CMD:sendmoney( playerid, params[ ] )
{
    new
		pID,
		amount,
		szPayment[ 96 ],
		iTime = g_iTime
	;

	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	/* ** Anti Tie Spam ** */
	if ( GetPVarInt( playerid, "sm_antispam" ) > iTime ) return SendError( playerid, "You must wait 10 seconds before sending payments again." );
	/* ** End of Anti Tie Spam ** */

	if ( sscanf( params, "ud", pID, amount ) ) return SendUsage( playerid, "/sendmoney [PLAYER_ID] [AMOUNT]" );
	else if ( amount > GetPlayerCash( playerid ) ) return SendError( playerid, "You don't have this amount of money." );
	else if ( amount < 1 ) return SendError( playerid, "Invalid amount of money." );
    else if ( pID == playerid ) return SendError( playerid, "You cannot send money to yourself." );
    else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not connected." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "This player is not logged in." );
	else if ( IsPlayerAFK( pID ) ) return SendError( playerid, "You cannot send money to a person who is AFK." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot send anybody money while you are kidnapped." );
    else
    {
    	format( szPayment, sizeof( szPayment ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`) VALUES (%d, %d, %d)", p_AccountID[ pID ], p_AccountID[ playerid ], amount );
     	mysql_single_query( szPayment );

        if ( amount > 25000 )
        	printf("[sendmoney] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), cash_format( amount ) ); // 8hska7082bmahu

		if ( amount > 90000000 ) {
	   		printf("ISP banned %s for making a 75M transaction", ReturnPlayerName( playerid ));
			AdvancedBan( playerid, "Server", "Suspicious Transaction", ReturnPlayerIP( playerid ) );
	   		return 1;
        }

        GivePlayerCash( pID, amount );
        GivePlayerCash( playerid, -( amount ) );
    	SetPVarInt( playerid, "sm_antispam", iTime + 10 );
		SendClientMessageFormatted( pID, -1, ""COL_GREEN"[PAYMENT]"COL_WHITE" You have recieved %s from %s(%d).", cash_format( amount ), ReturnPlayerName( playerid ), playerid );
        SendClientMessageFormatted( playerid, -1, ""COL_RED"[PAYMENT]"COL_WHITE" You have sent %s to %s(%d).", cash_format( amount ), ReturnPlayerName(pID), pID );
        Beep( pID ), Beep( playerid );
    }
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
	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/dnd [PLAYER_ID]" );
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

		if ( IsPlayerServerMaintainer( pID ) && g_VipPrivateMsging && p_VIPLevel[ playerid ] < VIP_REGULAR ) {
			return SendError( playerid, "You need to be V.I.P to PM this person, to become one visit "COL_GREY"donate.sfcnr.com" );
		}

		if ( p_BlockedPM[ playerid ] [ pID ] == true ) {
			SendServerMessage( playerid, "The message you have sent was to a person you blocked so they have been unblocked." );
			p_BlockedPM[ playerid ] [ pID ] = false;
		}

		if ( IsPlayerAFK( pID ) ) {
			SendServerMessage( playerid, "You have sent a message to a person who is currently AFK. Be aware!" );
		}

		GameTextForPlayer( pID, "~n~~n~~n~~n~~n~~n~~n~~w~... ~y~New Message!~w~ ...", 4000, 3 );
		SendClientMessageFormatted( pID, -1, ""COL_YELLOW"[MESSAGE]{CCCCCC} From %s(%d): %s", ReturnPlayerName( playerid ), playerid, msg );
        SendClientMessageFormatted( playerid, -1, ""COL_YELLOW"[MESSAGE]{A3A3A3} To %s(%d): %s", ReturnPlayerName(pID), pID, msg );
		foreach(new i : Player)
		{
		    if ( ( p_AdminLevel[ i ] >= 5 || IsPlayerUnderCover( i ) ) && p_ToggledViewPM{ i } == true )
		    {
		        SendClientMessageFormatted( i, -1, ""COL_PINK"[PM VIEW]"COL_YELLOW" (%s >> %s):"COL_WHITE" %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), msg );
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

	if ( sscanf( params, "us[100]", pID, msg ) ) return SendUsage( playerid, "/pm [PLAYER_ID] [MESSAGE]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
    else if ( pID == playerid ) return SendError( playerid, "You cannot pm yourself." );
    else if ( p_BlockedPM[ pID ] [ playerid ] == true ) return SendError( playerid, "This person has blocked pm's coming from you." );
	else if ( textContainsIP( msg ) ) return SendError( playerid, "Advertising via PM is forbidden." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "This player is not logged in." );
	else
	{
		if ( IsPlayerServerMaintainer( pID ) && g_VipPrivateMsging && p_VIPLevel[ playerid ] < VIP_REGULAR ) {
			return SendError( playerid, "You need to be V.I.P to PM this person, to become one visit "COL_GREY"donate.sfcnr.com" );
		}

		if ( p_BlockedPM[ playerid ] [ pID ] == true ) {
			SendServerMessage( playerid, "The message you have sent was to a person you blocked so they have been unblocked." );
			p_BlockedPM[ playerid ] [ pID ] = false;
		}

		if ( IsPlayerAFK( pID ) ) {
			SendServerMessage( playerid, "You have sent a message to a person who is currently AFK. Be aware!" );
		}

		GameTextForPlayer( pID, "~n~~n~~n~~n~~n~~n~~n~~w~... ~y~New Message!~w~ ...", 4000, 3 );
		SendClientMessageFormatted( pID, -1, ""COL_YELLOW"[MESSAGE]{CCCCCC} From %s(%d): %s", ReturnPlayerName( playerid ), playerid, msg );
        SendClientMessageFormatted( playerid, -1, ""COL_YELLOW"[MESSAGE]{A3A3A3} To %s(%d): %s", ReturnPlayerName(pID), pID, msg );
		foreach(new i : Player)
		{
		    if ( ( p_AdminLevel[ i ] >= 5 || IsPlayerUnderCover( i ) ) && p_ToggledViewPM{ i } == true )
		    {
		        SendClientMessageFormatted( i, -1, ""COL_PINK"[PM VIEW]"COL_YELLOW" (%s >> %s):"COL_WHITE" %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), msg );
		    }
		}
		p_PmResponder[ playerid ] = pID;
        Beep( pID ), Beep( playerid );
	}
	return 1;
}

CMD:statistics( playerid, params[ ] ) return cmd_stats( playerid, params );
CMD:stats( playerid, params[ ] )
{
	if ( !p_PlayerLogged{ playerid } )
		return SendError( playerid, "You are not logged in meaning you cannot access this command." );

	p_ViewingStats[ playerid ] = playerid;
	ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, "{FFFFFF}Statistics", "General Statistics\nGame Statistics\nItem Statistics\nStreak Statistics\nWeapon Statistics\nAchievements", "Okay", "Cancel" );
	return 1;
}

CMD:help( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_HELP, DIALOG_STYLE_LIST, "{FFFFFF}Help", "Server Information\nFeatures\nHelp\nF.A.Q.\nGuides\nTips n' Tricks", "Okay", "" );
	return 1;
}

CMD:features( playerid, params[ ] )
{
	SetPVarInt( playerid, "help_category", 1 );
    mysql_function_query( dbHandle, "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=1 ORDER BY `SUBJECT` ASC", true, "OnFetchCategoryResponse", "dd", playerid, 1 );
   	return 1;
}

CMD:faq( playerid, params[ ] )
{
	SetPVarInt( playerid, "help_category", 3 );
    mysql_function_query( dbHandle, "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=3 ORDER BY `SUBJECT` ASC", true, "OnFetchCategoryResponse", "dd", playerid, 3 );
   	return 1;
}

CMD:tips( playerid, params[ ] )
{
	SetPVarInt( playerid, "help_category", 5 );
    mysql_function_query( dbHandle, "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=5 ORDER BY `SUBJECT` ASC", true, "OnFetchCategoryResponse", "dd", playerid, 5 );
   	return 1;
}

CMD:commands( playerid, params[ ] ) return cmd_cmds( playerid, params );
CMD:cmds( playerid, params[ ] )
{
    ShowPlayerDialog( playerid, DIALOG_CMDS, DIALOG_STYLE_LIST, "{FFFFFF}Commands", "Basic Commands\nMain Commands\nCivilian Commands\nShop/Item Commands\nPolice Commands\nFireman Commands\nParamedic Commands\nVehicle Commands\nHouse Commands\nMiscellaneous Commands\n"COL_GOLD"V.I.P Commands", "Okay", "" );
	return 1;
}

CMD:breakout( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
	if ( !IsPlayerJailed( playerid ) ) return SendError( playerid, "You can only use this while you're in jail!" );
	if ( IsPlayerAdminJailed( playerid ) ) return SendError( playerid, "You have been admin jailed, disallowing this." );
	if ( p_inAlcatraz{ playerid } ) return SendError( playerid, "You are unable to break out of Alcatraz. Ask a friend to blow you out." );
	if ( p_MetalMelter[ playerid ] > 0 )
	{
	    new
			iRandom = random( 101 );

		if ( p_MetalMelter[ playerid ]-- <= 3 )
			ShowPlayerHelpDialog( playerid, 2500, "You only have %d metal melters left!", p_MetalMelter[ playerid ] );

	    if ( iRandom < 80 ) {
		  	CallLocalFunction( "OnPlayerUnjailed", "dd", playerid, 2 );
		  	GivePlayerWantedLevel( playerid, 24 );
	    }
		else SendServerMessage( playerid, "You have failed to break out." );
	}
	else SendError( playerid, "You have no more Metal Melters available.");
	return 1;
}

CMD:shop( playerid, params[ ] )
{
    if ( ( !IsPlayerInEntrance( playerid, g_SupaSave ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_247_MENU ] ) ) || !GetPlayerInterior( playerid ) ) return SendError( playerid, "You must be within Supa Save or 24/7 to purchase items." );
	if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this since you're tazed." );
	//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this since you're detained." );
	if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this since you're cuffed." );
	if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this since you're tied." );
	if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this since you're kidnapped." );

	ShowPlayerShopMenu( playerid );
	return 1;
}

CMD:placehit( playerid, params[ ] )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	/* ** Anti Spammy Commands ** */
	if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "You cannot use commands that are sent to players globally for %d seconds.", p_AntiSpammyTS[ playerid ] - g_iTime );
	/* ** End Anti Spammy Commands ** */

	new
	    pID,
	    cash
	;
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
	else if ( IsPlayerJob( playerid, JOB_HITMAN ) ) return SendError( playerid, "As a hitman you're not allowed to use this command." );
	else if ( sscanf( params, "ud", pID, cash ) ) return SendUsage( playerid, "/placehit [PLAYER_ID] [AMOUNT]" );
	else if ( cash > GetPlayerCash( playerid ) ) return SendError( playerid, "You don't have enough money to place this much." );
	else if ( cash < 1000 ) return SendError( playerid, "The minimal hit you can place is $1,000." );
	else if ( pID == playerid ) return SendError( playerid, "You cannot place a hit on your self.");
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player isn't connected!" );
	{
		// transaction
    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'contract')", p_AccountID[ pID ], p_AccountID[ playerid ], cash );
     	mysql_single_query( szNormalString );

     	// place hit
		p_ContractedAmount[ pID ] += cash;
		GivePlayerCash( playerid, -cash );
		p_AntiSpammyTS[ playerid  ] = g_iTime + 10;

		// message
		printf("[placehit] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), cash_format( cash ) ); // 8hska7082bmahu
		SendGlobalMessage( -1, ""COL_ORANGE"[CONTRACT]"COL_WHITE" %s(%d) has put a contract on %s(%d), their bounty is now "COL_GOLD"%s{FFFFFF}.", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, cash_format( p_ContractedAmount[ pID ] ) );
	}
	return 1;
}

CMD:me( playerid, params[ ] )
{
	new action[70];
	if ( p_Muted{ playerid } == true && g_iTime < p_MutedTime[ playerid ] ) return SendError( playerid, "You cannot use this feature as you are muted." );
	else if ( GetPlayerScore( playerid ) < 25 ) return SendError( playerid, "You need at least 25 score to use this feature (spamming purposes)." );
	else if ( sscanf( params, "s[70]", action ) ) return SendUsage( playerid, "/me [ACTION]" );
	else
	{
    	DCC_SendChannelMessageFormatted( discordGeneralChan, "** * * * %s(%d) %s **", ReturnPlayerName( playerid ), playerid, action );
		SendClientMessageToAllFormatted( GetPlayerColor( playerid ), "*** %s(%d) %s", ReturnPlayerName( playerid ), playerid, action );
	}
	return 1;
}

CMD:hidetracker( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
	if ( !IsPlayerJob( playerid, JOB_HITMAN ) ) return SendError( playerid, "You have to be a hitman to use this command." );
	if ( p_TrackingTimer[ playerid ] == -1 ) return SendError( playerid, "Your tracker is already deactivated." );
	SendServerMessage(playerid, "You have de-activated the tracker.");
	KillTimer( p_TrackingTimer[ playerid ] );
	p_TrackingTimer[ playerid ] = -1;
	PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	return 1;
}

CMD:track( playerid, params[ ] )
{
	new
	    pID
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
	else if ( !IsPlayerJob( playerid, JOB_HITMAN ) ) return SendError( playerid, "You have to be a hitman to use this command." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/track [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "This player isn't connected!" );
	else if ( pID == playerid ) return SendError( playerid, "You cannot apply this to yourself." );
	else if ( !IsPlayerSpawned( pID ) ) return SendError( playerid, "The player selected isn't spawned." );
	else if ( p_AdminOnDuty{ pID } == true || GetPlayerState( pID ) == PLAYER_STATE_SPECTATING ) return SendError( playerid, "This is an admin on duty! You cannot track their proximity." );
	else
	{
	    KillTimer( p_TrackingTimer[ playerid ] );
	    p_TrackingTimer[ playerid ] = SetTimerEx( "TrackPlayer_timer", 1000, true, "dd", playerid, pID );
	    PlayerTextDrawShow( playerid, p_TrackPlayerTD[ playerid ] );
	    SendServerMessage( playerid, "You have activated the tracker, you can hide it with /hidetracker." );
	}
	return 1;
}

function TrackPlayer_timer( playerid, victimid )
{
	if ( !IsPlayerConnected( victimid ) || p_AdminOnDuty{ victimid } == true || GetPlayerState( victimid ) == PLAYER_STATE_SPECTATING || !IsPlayerJob( playerid, JOB_HITMAN ) || p_Class[ playerid ] != CLASS_CIVILIAN )
	{
		KillTimer( p_TrackingTimer[ playerid ] ), p_TrackingTimer[ playerid ] = -1;
		PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	}
	else
	{
		new
			Float: fDistance;

		if ( GetPlayerInterior( playerid ) != GetPlayerInterior( victimid ) )
		{
			new
				iEntrance = p_LastEnteredEntrance[ victimid ],
				iHouse = p_InHouse[ victimid ],
				iGarage = p_InGarage[ victimid ]
			;

		    if ( iEntrance != -1 )
		  		fDistance = GetPlayerDistanceFromPoint( playerid, g_entranceData[ iEntrance ] [ E_EX ], g_entranceData[ iEntrance ] [ E_EY ], g_entranceData[ iEntrance ] [ E_EZ ] );

		  	else if ( iGarage != -1 )
		  		fDistance = GetPlayerDistanceFromPoint( playerid, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ] );

		  	else if ( iHouse != -1 )
		  		fDistance = GetPlayerDistanceFromPoint( playerid, g_houseData[ iHouse ] [ E_EX ], g_houseData[ iHouse ] [ E_EY ], g_houseData[ iHouse ] [ E_EZ ] );

		  	else fDistance = 9999.9; // Truly unknown lol
		}
		else fDistance = GetDistanceBetweenPlayers( playerid, victimid );

		if ( !fDistance || fDistance > 9999.9 )
			fDistance = 9999.9;

		PlayerTextDrawSetString( playerid, p_TrackPlayerTD[ playerid ], fDistance != 9999.0 ? sprintf( "%s~n~~w~%0.1fm", ReturnPlayerName( victimid ), fDistance ) : sprintf( "%s~n~~w~unknown", ReturnPlayerName( victimid ) ) );
	}
}

CMD:stoprob( playerid, params[ ] )
{
	SendServerMessage( playerid, "This command binds your crouch key, so you must be robbing a store to get a response!" );
	CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_CROUCH, KEY_SPRINT );
	return 1;
}

CMD:exit( playerid, params[ ] ) return cmd_enter( playerid, params );
CMD:enter( playerid, params[ ] )
{
	GameTextForPlayer(playerid, "~n~~n~~r~~k~~VEHICLE_ENTER_EXIT~~n~~w~press this key in a enterable checkpoint.", 5000, 3);
	return 1;
}

CMD:kill( playerid, params[ ] )
{
	if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You cannot use this command since you're not spawned." );
	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
	//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
	if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
	if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
	if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
	if ( p_WantedLevel[ playerid ] > 0 ) return SendError( playerid, "You cannot commit suicide if you have a wanted level on you." );
	if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
	if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
	if ( p_Spectating{ playerid } == true ) return SendError( playerid, "You cannot use this command since you're spectating." );
	if ( p_AntiSpawnKillEnabled{ playerid } ) return SendError( playerid, "You cannot use this command while anti-spawn kill is activated." );
	SetPVarInt( playerid, "used_cmd_kill", 1 );
	SetPlayerHealth( playerid, -1 );
	return 1;
}

CMD:changeclass( playerid, params[ ] )
{
	if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You cannot use this command since you're not spawned." );
	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
	//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
	if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
	if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
	if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
	if ( p_WantedLevel[ playerid ] > 0 ) return SendError( playerid, "You cannot commit suicide if you have a wanted level on you." );
	if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
	if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
	if ( p_Spectating{ playerid } == true ) return SendError( playerid, "You cannot use this command since you're spectating." );
	if ( p_AntiSpawnKillEnabled{ playerid } ) return SendError( playerid, "You cannot use this command while anti-spawn kill is activated." );
	SetPVarInt( playerid, "used_cmd_kill", 1 );
	ForceClassSelection( playerid );
	SetPlayerHealth( playerid, -1 );
	return 1;
}

CMD:911( playerid, params[ ] )
{
	/* ** Anti Spammy Commands ** */
	if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "You cannot use commands that are sent to players globally for %d seconds.", p_AntiSpammyTS[ playerid ] - g_iTime );
	/* ** End Anti Spammy Commands ** */

	if ( p_Class[ playerid ] == CLASS_POLICE ) return SendError( playerid, "You cannot use this command as you are a law enforcement officer." );
	else if ( GetPlayerInterior( playerid ) != 0 ) return SendError( playerid, "You cannot use this command in an interior." );
	else
	{
		new
			Float: X, Float: Y, Float: Z,
			szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ]
		;
		GetPlayerPos( playerid, X, Y, Z );
		GetZoneFromCoordinates( szLocation, X, Y, Z );
		Get2DCity( szCity, X, Y, Z );

		if ( strmatch( params, "LEO" ) )
	    {
	    	p_AntiSpammyTS[ playerid ] = g_iTime + 15;
	        SendClientMessageToCops( -1, ""COL_BLUE"[911]"COL_GREY" %s(%d) is asking for a law enforcement officer near %s in %s!", ReturnPlayerName( playerid ), playerid, szLocation, szCity );
			SendServerMessage( playerid, "You have asked for a leo enforcement officer at your current location." );
		}
		else if ( strmatch( params, "EFB" ) )
	    {
	    	p_AntiSpammyTS[ playerid ] = g_iTime + 15;
	        SendClientMessageToFireman( -1, "{A83434}[911]"COL_GREY" %s(%d) is asking for a fire brigade near %s in %s!", ReturnPlayerName( playerid ), playerid, szLocation, szCity );
			SendServerMessage( playerid, "You have asked for a fire brigade at your current location." );
		}
		else if ( strmatch( params, "EMS" ) )
	    {
	    	p_AntiSpammyTS[ playerid ] = g_iTime + 15;
	        SendClientMessageToAmbulance( -1, ""COL_GREEN"[911]"COL_GREY" %s(%d) is asking for a paramedic near %s in %s!", ReturnPlayerName( playerid ), playerid, szLocation, szCity );
			SendServerMessage( playerid, "You have asked for a paramedic at your current location." );
		}
		else SendUsage( playerid, "/911 [LEO/EFB/EMS]" );
	}
	return 1;
}


CMD:kidnap( playerid, params[ ] )
{
	/* ** ANTI KIDNAP SPAM ** */
    if ( p_AntiKidnapSpam[ playerid ] > g_iTime ) return SendError( playerid, "You must wait 30 seconds before kidnapping someone again." );
    /* ** END OF ANTI SPAM **/

  	new victimid = GetClosestPlayer( playerid );
   	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
   	else if ( !IsPlayerJob( playerid, JOB_KIDNAPPER ) ) return SendError( playerid, "Kidnappers are only permitted to use this command." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
  		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle." );
		if ( !IsPlayerTied( victimid ) ) return SendError( playerid, "This player isn't tied!" );
		if ( IsPlayerKidnapped( victimid ) ) return SendError( playerid, "This player is already kidnapped!" );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
		if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "You cannot use this command at the moment." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( p_KidnapImmunity[ victimid ] > g_iTime ) return SendError( playerid, "This player cannot be kidnapped for another %s.", secondstotime( p_KidnapImmunity[ victimid ] - g_iTime ) );
		if ( PutPlayerInEmptyVehicleSeat( p_LastVehicle[ playerid ], victimid ) == -1 ) return SendError( playerid, "Failed to place the player inside a full of player vehicle." );
		SendClientMessageFormatted( victimid, -1, ""COL_RED"[KIDNAPPED]{FFFFFF} You have been kidnapped by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[KIDNAPPED]{FFFFFF} You have kidnapped %s(%d), he has been thrown in your previous entered vehicle!", ReturnPlayerName( victimid ), victimid );
		TogglePlayerControllable( victimid, 0 );
		p_Kidnapped{ victimid } = true;
		GivePlayerWantedLevel( playerid, 12 );
     	p_AntiKidnapSpam[ playerid ] = g_iTime + 30;
		//PutPlayerInVehicle( victimid, p_LastVehicle[ playerid ], 1 );
	}
	else return SendError( playerid, "There are no players around to kidnap." );
	return 1;
}

CMD:untie( playerid, params[ ] )
{
  	new victimid = GetClosestPlayer( playerid );
   	if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
  		//if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle." );
		if ( !IsPlayerTied( victimid ) ) return SendError( playerid, "This player isn't tied!" );
		SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[UN-TIED]{FFFFFF} You have been un-tied by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_RED"[UN-TIED]{FFFFFF} You have un-tied %s(%d)!", ReturnPlayerName( victimid ), victimid );
		TogglePlayerControllable( victimid, 1 );
		p_Tied{ victimid } = false;
		Delete3DTextLabel( p_TiedLabel[ victimid ] );
		p_TiedLabel[ victimid ] = Text3D: INVALID_3DTEXT_ID;
		p_TimeTiedAt[ victimid ] = 0;
		p_Kidnapped{ victimid } = false;
	}
	else return SendError( playerid, "There are no players around to un-tie." );
	return 1;
}

CMD:tie( playerid, params[ ] )
{
	/* ** Anti Tie Spam ** */
	if ( p_AntiTieSpam[ playerid ] > g_iTime ) return SendError( playerid, "You must wait %d seconds before tieing someone again.", p_AntiTieSpam[ playerid ] - g_iTime );
	/* ** End of Anti Tie Spam ** */

	new victimid = GetClosestPlayer( playerid );
	//if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/tie [PLAYER_ID]" );
	//else if ( victimid == playerid ) return SendError( playerid, "You cannot tie yourself." );
	//else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "This player is not connected." );
	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( p_Ropes[ playerid ] < 1 ) return SendError( playerid, "You don't have any ropes." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
  		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle." );
		if ( IsPlayerTied( victimid ) ) return SendError( playerid, "This player is already tied!" );
  		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot tie inside a vehicle." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot tie while you're cuffed." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot tie while you're tazed." );
		if ( IsPlayerTazed( victimid ) ) return SendError( playerid, "The person you're trying to tie is tazed." );
		if ( IsPlayerOnSlotMachine( victimid ) ) return SendError( playerid, "The person you're trying to tie is using a slot machine." );
		if ( IsPlayerOnRoulette( victimid ) ) return SendError( playerid, "The person you're trying to tie is using roulette." );
		if ( IsPlayerCuffed( victimid ) ) return SendError( playerid, "The person you're trying to tie is cuffed." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
		if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "You cannot use this command at an arena." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "You cannot use this command on admins that are on duty." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "This player is in a object-loading state." );
		if ( GetPlayerState( victimid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "You cannot tie wasted players." );
		if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
		if ( IsPlayerInPlayerGang( playerid, victimid ) ) return SendError( playerid, "You cannot use this command on your homies!" );
		if ( p_AntiSpawnKillEnabled{ victimid } ) return SendError( playerid, "You cannot use this command on spawn protected players." );
		if ( IsPlayerPassive( victimid ) ) return SendError( playerid, "You cannot use this command on passive mode players." );
		if ( IsPlayerInCasino( victimid ) && ! p_WantedLevel[ victimid ] ) return SendError( playerid, "The innocent person you're trying to tie is in a casino." );

		// remove rope after attempt
		if ( p_Ropes[ playerid ] -- > 0 ) {
			ShowPlayerHelpDialog( playerid, 4500, "You only have %d ropes left!", p_Ropes[ playerid ] );
		} else {
			ShowPlayerHelpDialog( playerid, 4500, "You can buy ropes at Supa Save or a 24/7 store." );
		}

		p_AntiTieSpam[ playerid ] = g_iTime + 30;
		GivePlayerWantedLevel( playerid, 6 );

		// check if tie is successful
		if ( random( 101 ) < 90 )
		{
			new bool: scissor_success = false;
			new attempts = 0;

			for ( attempts = 1; attempts < p_Scissors[ victimid ]; attempts ++ )
			{
				if ( random( 101 ) > 20 ) {
					scissor_success = true;
					break;
				}
			}

			if ( ( p_Scissors[ victimid ] -= attempts ) > 0 ) {
				ShowPlayerHelpDialog( victimid, 4500, "You only have %d scissors left!", p_Scissors[ victimid ] );
			} else {
				ShowPlayerHelpDialog( victimid, 4500, "You can buy sissors at Supa Save or a 24/7 store." );
			}

			if ( scissor_success )
			{
				SendClientMessageFormatted( playerid, -1, ""COL_RED"[TIE]{FFFFFF} %s(%d) has cut the tie you placed!", ReturnPlayerName( victimid ), victimid );
			    SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[TIE]{FFFFFF} You have cut off %s(%d)'s tie after %d attempt(s)!", ReturnPlayerName( playerid ), playerid, attempts );
			}
			else
			{
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[TIED]{FFFFFF} You have been tied by %s(%d)!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[TIED]{FFFFFF} You have tied %s(%d)!", ReturnPlayerName( victimid ), victimid );
				TogglePlayerControllable( victimid, 0 );
				p_Tied{ victimid } = true;
	     		p_TimeTiedAt[ victimid ] = g_iTime;
				p_TiedBy[ victimid ] = playerid;
			    Delete3DTextLabel( p_TiedLabel[ victimid ] );
			    format( szNormalString, 48, "Tied by %s!", ReturnPlayerName( playerid ) );
			    p_TiedLabel[ victimid ] = Create3DTextLabel( szNormalString, 0xDAB583FF, 0.0, 0.0, 0.0, 15.0, 0 );
			    Attach3DTextLabelToPlayer( p_TiedLabel[ victimid ], victimid, 0.0, 0.0, 0.6 );
			    p_TiedAtTimestamp[ victimid ] = g_iTime;
			}
			return 1;
		}
		else
		{
			p_AntiTieSpam[ playerid ] = g_iTime + 6; // makecopgreatagain
			SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[FAIL TIE]{FFFFFF} %s(%d) has failed to tie you!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_RED"[FAIL TIE]{FFFFFF} You have failed to tie %s(%d)!", ReturnPlayerName( victimid ), victimid );
		}
		return 1;
	}
	else return SendError( playerid, "There are no players around to tie." );
}

CMD:pu( playerid, params[ ] ) return cmd_pullover(playerid, params);
CMD:pullover( playerid, params[ ] )
{
   	new victimid = GetClosestPlayerEx( playerid, CLASS_CIVILIAN );
   	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 20.0 && IsPlayerConnected( victimid ) )
 	{
 	    if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "This player you're close to is in your team." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "This player is innocent!" );
		if ( GetPlayerState( victimid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "This player is not in any vehicle!" );
		SendClientMessageFormatted( victimid, -1, ""COL_RED"[PULL OVER]{FFFFFF} You have been asked to pull over by %s(%d)!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[PULL OVER]{FFFFFF} You have asked %s(%d) to pull over!", ReturnPlayerName( victimid ), victimid );
	}
 	else return SendError( playerid, "There are no players around to ask to pull over!" );
	return 1;
}

CMD:loc( playerid, params[ ] ) return cmd_location( playerid, params );
CMD:locate( playerid, params[ ] ) return cmd_location( playerid, params );
CMD:location( playerid, params[ ] )
{
   	new
   	    pID
	;

	if ( p_Class[ playerid ] == CLASS_CIVILIAN ) return SendError( playerid, "This is not accessible by civilians." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/loc(ation) [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "This player isn't connected!" );
	else if ( !IsPlayerSpawned( pID ) ) return SendError( playerid, "The player selected isn't spawned." );
	//else if ( GetPlayerInterior( playerid ) != GetPlayerInterior( pID ) ) return SendError( playerid, "This player is inside a interior, the location is not viewable." );
	else if ( p_AdminOnDuty{ pID } == true ) return SendError( playerid, "This is an admin on duty! You cannot track their proximity." );
	else
	{
	    new
			szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

		if ( !GetPlayerLocation( pID, szCity, szLocation ) )
			return SendError( playerid, "This player has gone completely under the radar." );

		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[LOCATION]"COL_WHITE" %s(%d) is located near %s in %s!", ReturnPlayerName( pID ), pID, szLocation, szCity );
	}
	return 1;
}

CMD:sh( playerid, params[ ] ) return cmd_search( playerid, params );
CMD:search( playerid, params[ ] )
{
	/* ** ANTI SPAM ** */
    if ( p_SearchedCountTick[ playerid ] > g_iTime ) return SendError( playerid, "You must wait 2 minutes before using this command again." );
    /* ** END OF ANTI SPAM ** */

   	new
   	    pID
	;
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "This is restricted to police only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/search [PLAYER_ID]" );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) > 10.0 || !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not around." );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "This player is in your team!" );
	else if ( !IsPlayerCuffed( pID ) ) return SendError( playerid, "This player must be cuffed." );
	else if ( IsPlayerJailed( pID ) ) return SendError( playerid, "You cannot " );
	else
	{
	    new
	    	wantedlvl = p_WeedGrams[ pID ] * 6;

		p_SearchedCountTick[ playerid ] = g_iTime + 120;

		if ( wantedlvl <= 0 )
		{
			SendClientMessageFormatted( pID, -1, ""COL_RED"[SEARCHED]{FFFFFF} You have been searched by %s(%d), luckily no drugs were found!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[SEARCHED]{FFFFFF} You have searched %s(%d) and found no drugs!", ReturnPlayerName( pID ), pID, p_WeedGrams[ pID ] );
	    	return 1;
		}

		SendClientMessageFormatted( pID, -1, ""COL_RED"[SEARCHED]{FFFFFF} You have searched by %s(%d) and have had your drugs removed!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[SEARCHED]{FFFFFF} You have searched %s(%d) and found %d gram(s) of "COL_GREEN"weed{FFFFFF}!", ReturnPlayerName( pID ), pID, p_WeedGrams[ pID ] );

	  	p_WeedGrams[ pID ] = 0;
		GivePlayerWantedLevel( pID, wantedlvl );
	}
	return 1;
}

CMD:tk( playerid, params[ ] ) return cmd_ticket( playerid, params );
CMD:ticket( playerid, params[ ] )
{
   	new
   		pID = GetClosestPlayer( playerid );

	TicketPlayer( pID, playerid );
	SendServerMessage( playerid, "You can use your middle mouse button to easily ticket individuals that are near to you." );
	return 1;
}

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

CMD:taze( playerid, params[ ] )
{
   	new
   		pID = GetClosestPlayer( playerid );

 	return TazePlayer( pID, playerid );
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

CMD:rob( playerid, params[ ] )
{
	/* ** ANTI ROB SPAM ** */
    if ( ( GetTickCount( ) - p_AntiRobSpam[ playerid ] ) < 90000 ) return SendError( playerid, "You're too tired from the last time you've robbed someone..." );
    /* ** END OF ANTI SPAM ** */

  	new victimid = GetClosestPlayer( playerid );
   	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	//else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "It's impossible to rob someone inside a car." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{

  		//if ( IsPlayerInAnyVehicle( victimid ) && !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "This player is in a vehicle and you're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && !IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "You cannot rob someone while you're a vehicle and they're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && IsPlayerInAnyVehicle( victimid ) && !IsPlayerKidnapped( victimid ) ) return SendError( playerid, "The person in your vehicle must be kidnapped to rob them." );
  		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command inside a vehicle." );
		if ( GetPlayerCash( victimid ) < 10 ) return SendError( playerid, "This player cannot be robbed since he has a low amount of money." );
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
		if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "You cannot use this command since you're in a minigame." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "You cannot use this command on admins that are on duty." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( IsPlayerInCasino( victimid ) && ! p_WantedLevel[ victimid ] ) return SendError( playerid, "The innocent person you're trying to rob is in a casino." );
		if ( p_ClassSelection{ victimid } ) return SendError( playerid, "This player is currently in class selection." );
		if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
		if ( IsPlayerInPlayerGang( playerid, victimid ) ) return SendError( playerid, "You cannot use this command on your homies!" );
		new iRandom = random( 101 );
		if ( p_SecureWallet{ victimid } == true ) iRandom -= 90;
		if ( iRandom < 75 || IsPlayerTied( victimid ) || IsPlayerKidnapped( victimid ) )
		{
		    new
				iMoney,
				cashRobbed,
		    	iLimit = 2500
			;

			if ( IsPlayerKidnapped( victimid ) )
				iLimit += 3500;

			iMoney = GetPlayerCash( victimid ) > iLimit ? iLimit : GetPlayerCash( victimid );

			cashRobbed = random( iMoney ) + 10;

			SendClientMessageFormatted( victimid, -1, ""COL_RED"[ROBBED]{FFFFFF} You have been robbed "COL_GOLD"%s{FFFFFF} by %s(%d)!", cash_format( cashRobbed ), ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ROBBED]{FFFFFF} You have robbed "COL_GOLD"%s{FFFFFF} off %s(%d)!", cash_format( cashRobbed ), ReturnPlayerName( victimid ), victimid );

			SplitPlayerCashForGang( playerid, float( cashRobbed ) );
			GivePlayerWantedLevel( playerid, 4 );
			GivePlayerCash( victimid, -( cashRobbed ) );
			GivePlayerScore( playerid, 1 );
			GivePlayerExperience( playerid, E_ROBBERY );
		}
		else
		{
			SendClientMessageFormatted( playerid, -1, ""COL_RED"[ROB FAIL]{FFFFFF} You have failed to rob %s(%d)!", ReturnPlayerName( victimid ), victimid );
		  	SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[ROB FAIL]{FFFFFF} %s(%d) has failed to rob you!", ReturnPlayerName( playerid ), playerid );
			GivePlayerWantedLevel( playerid, 6 );
		}
		p_AntiRobSpam[ playerid ] = GetTickCount( );
 	}
 	else return SendError( playerid, "There are no players around to rob." );
	return 1;
}

CMD:rape( playerid, params[ ] )
{
	/* ** ANTI ROB SPAM ** */
    if ( p_AntiRapeSpam[ playerid ] > g_iTime ) return SendError( playerid, "Your cock hurts from the last time you raped somebody..." );
    /* ** END OF ANTI SPAM ** */

  	new victimid = GetClosestPlayer( playerid ), Float: Health;
   	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
   	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	//else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "It's impossible to rape someone inside a car." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
  		//if ( IsPlayerInAnyVehicle( victimid ) && !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "This player is in a vehicle and you're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && !IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "You cannot rape someone while you're a vehicle and they're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && IsPlayerInAnyVehicle( victimid ) && !IsPlayerKidnapped( victimid ) ) return SendError( playerid, "The person in your vehicle must be kidnapped to rape them." );
  		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command inside a vehicle." );
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
		if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "You cannot use this command since you're in a minigame." );
		if ( p_Jailed{ playerid } == true ) return SendError( playerid, "You cannot rape in jail." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "You cannot use this command on admins that are on duty." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "This player is jailed. He may be paused." );
		if ( IsPlayerInCasino( victimid ) && ! p_WantedLevel[ victimid ] ) return SendError( playerid, "The innocent person you're trying to rape is in a casino." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "This player is in a object-loading state." );
		if ( p_AntiSpawnKillEnabled{ victimid } ) return SendError( playerid, "This player is in a anti-spawn-kill state." );
		if ( IsPlayerPassive( victimid ) ) return SendError( playerid, "You cannot use this command on passive mode players." );
		if ( p_ClassSelection{ victimid } ) return SendError( playerid, "This player is currently in class selection." );
		if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
		if ( IsPlayerAFK( victimid ) && GetPlayerState( playerid ) != PLAYER_STATE_WASTED ) return SendError( playerid, "This player is in an AFK state." );
		if ( IsPlayerInPlayerGang( playerid, victimid ) ) return SendError( playerid, "You cannot use this command on your homies!" );

  		new iRandom = random( 101 );
        if ( IsPlayerJob( playerid, JOB_RAPIST ) ) { iRandom += 10; } // Adds more success to rapists.
  		if ( iRandom < 75 || IsPlayerTied( victimid ) )
  		{
			if ( p_InfectedHIV{ playerid } || ( IsPlayerJob( playerid, JOB_RAPIST ) && p_AidsVaccine{ victimid } == false && !IsPlayerJob( victimid, JOB_PROSTITUTE ) ) )
			{
			    SendClientMessageFormatted( victimid, -1, ""COL_RED"[RAPED]{FFFFFF} You have been raped and infected with "COL_RED"HIV{FFFFFF} by %s(%d)!", ReturnPlayerName( playerid ), playerid );
		    	SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[RAPED]{FFFFFF} You have raped %s(%d) and infected them with "COL_RED"HIV{FFFFFF}!", ReturnPlayerName( victimid ), victimid );
			    GivePlayerScore( playerid, 2 );
			    GivePlayerWantedLevel( playerid, 5 );
				//GivePlayerExperience( playerid, E_PARAMEDIC );
			    GetPlayerHealth( victimid, Health );
			  	SetPlayerHealth( victimid,  ( Health - 25.0 ) );

			    p_InfectedHIV{ victimid } = true;
				SetTimerEx( "RapeDamage", 5000, false, "d", victimid );
			}
			else
			{
			    SendClientMessageFormatted( victimid, -1, ""COL_RED"[RAPED]{FFFFFF} You have been raped by %s(%d)!", ReturnPlayerName( playerid ), playerid );
		    	SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[RAPED]{FFFFFF} You have raped %s(%d)!", ReturnPlayerName( victimid ), victimid );
			    GivePlayerScore( playerid, 1 );
				//GivePlayerExperience( playerid, E_PARAMEDIC, 0.5 );
			    GivePlayerWantedLevel( playerid, 4 );
			    GetPlayerHealth( victimid, Health );
			  	SetPlayerHealth( victimid,  ( Health - 25.0 ) );
			}
		}
		else
		{
			SendClientMessageFormatted( playerid, -1, ""COL_RED"[RAPE FAIL]{FFFFFF} You have failed to rape %s(%d)!", ReturnPlayerName( victimid ), victimid );
		  	SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[RAPE FAIL]{FFFFFF} %s(%d) has failed to rape you!", ReturnPlayerName( playerid ), playerid );
	    	GivePlayerWantedLevel( playerid, 6 );
		}
		p_AntiRapeSpam[ playerid ] = g_iTime + 60;
 	}
 	else return SendError( playerid, "There are no players around to rape." );
	return 1;
}

CMD:c4( playerid, params[ ] )
{
	if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );

	if ( !strcmp( params, "plant", true, 5 ) )
	{
		new
		    ID = -1
		;

		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
		if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
		if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
		if ( !IsPlayerJob( playerid, JOB_TERRORIST ) ) return SendError( playerid, "This is restricted to terrorists." );
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
		if ( IsPlayerInCasino( playerid ) ) return SendError( playerid, "You cannot use this command since you're in a casino." );
		if ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an arena." );
		if ( IsPlayerPassive( playerid ) ) return SendError( playerid, "You cannot use this command as an innocent player in passive mode." );
		if ( p_C4Amount[ playerid ] < 1 ) return SendError( playerid, "You don't have any C4's" );

		#if defined __cnr__chuffsec
			if ( IsPlayerInVehicle( playerid, g_secureTruckVehicle ) ) return SendError( playerid, "You cannot be in this vehicle while planting C4." );
		#endif

		for( new i; i < MAX_C4; i++ ) {
		    if ( !g_C4Data[ playerid ] [ i ] [ E_SET ] ) {
		        ID = i;
		        break;
			}
		}

		if ( ID != -1 )
		{
			new
		        Float: distance = 99999.99,
				robberyid = getClosestRobberySafe( playerid, distance )
			;

			if ( robberyid != INVALID_OBJECT_ID && distance < 1.50 && !g_robberyData[ robberyid ] [ E_STATE ] && AttachToRobberySafe( robberyid, playerid, ROBBERY_TYPE_C4 ) )
			{
				SendServerMessage( playerid, "You have planted a C4 on this "COL_ORANGE"safe"COL_WHITE", detonation is automatic." );

				if ( g_Debugging )
				{
					printf("[DEBUG] [ROBBERY] [%d] Planted C4 { open : %d, robbed : %d, c4: %d, drill : %d, dplacer : %d, deffect : %d, replenish : %d, raw ts : %d, current ts : %d, name : %s, state : %d }",
								robberyid,
								g_robberyData[ robberyid ] [ E_OPEN ], g_robberyData[ robberyid ] [ E_ROBBED ], g_robberyData[ robberyid ] [ E_C4 ],
								g_robberyData[ robberyid ] [ E_DRILL ], g_robberyData[ robberyid ] [ E_DRILL_PLACER ], g_robberyData[ robberyid ] [ E_DRILL_EFFECT ], g_robberyData[ robberyid ] [ E_ROB_TIME ] - g_iTime,
								g_robberyData[ robberyid ] [ E_ROB_TIME ], g_iTime, g_robberyData[ robberyid ] [ E_NAME ], g_robberyData[ robberyid ] [ E_STATE ] );
				}
			}
			else
			{
				new
				    Float: X, Float: Y, Float: Z,
					iVehicle = GetPlayerVehicleID( playerid )
				;

				GetPlayerPos( playerid, X, Y, Z );

				format( szNormalString, 64, "C4 %d\nPlanted By %s!", ID, ReturnPlayerName( playerid ) );
				g_C4Data[ playerid ] [ ID ] [ E_LABEL ] = Create3DTextLabel( szNormalString, setAlpha( COLOR_GREY, 0x50 ), X, Y, Z - 1.0, 15.0, GetPlayerVirtualWorld( playerid ) );
				g_C4Data[ playerid ] [ ID ] [ E_OBJECT ] = CreateDynamicObject( 19602, X, Y, Z - 0.92, 0, 0, 0, GetPlayerVirtualWorld( playerid ), GetPlayerInterior( playerid ), -1, 50.0 ); // 363 prev, Rx -90.0
				g_C4Data[ playerid ] [ ID ] [ E_WORLD ] = GetPlayerVirtualWorld( playerid );
				g_C4Data[ playerid ] [ ID ] [ E_INTERIOR ] = GetPlayerInterior( playerid );
				g_C4Data[ playerid ] [ ID ] [ E_SET ] = true;

				if ( ! iVehicle ) {
					iVehicle = GetPlayerSurfingVehicleID( playerid );
				}

			#if defined __cnr__chuffsec
				if ( iVehicle == g_secureTruckVehicle ) {
					iVehicle = INVALID_VEHICLE_ID;
				}
			#endif

				if ( IsValidVehicle( iVehicle ) )
				{
					GetVehiclePos( iVehicle, X, Y, Z );

		            g_C4Data[ playerid ] [ ID ] [ E_VEHICLE ] = iVehicle + 100; // Plus 100 just for verification

					//if ( GetOffsetFromPosition( iVehicle, X, Y, Z, vX, vY, vZ ) )
			   		//	g_C4Data[ playerid ] [ ID ] [ E_X ] = X + vX, g_C4Data[ playerid ] [ ID ] [ E_Y ] = Y + vY, g_C4Data[ playerid ] [ ID ] [ E_Z ] = Z + vY - vOffset;

					SendServerMessage( playerid, "You have planted a C4 on a "COL_GREY"vehicle"COL_WHITE", you can detonate it by pressing your "COL_GREY"Y key"COL_WHITE"." );
				    AttachDynamicObjectToVehicle( g_C4Data[ playerid ] [ ID ] [ E_OBJECT ], iVehicle, 0.0, 0.0, 6000.0, 0.0, 0.0, 0.0 );
				    Attach3DTextLabelToVehicle( g_C4Data[ playerid ] [ ID ] [ E_LABEL ], iVehicle, 0.0, 0.0, 0.0 );
				}
				else SendServerMessage( playerid, "You have planted a C4, you can detonate it by pressing your "COL_GREY"Y key"COL_WHITE"." );
			}
		}
		else return SendError( playerid, "You have planted the maximum C4 limit." );

		p_C4Amount[ playerid ] --;
    	PlayerPlaySound( playerid, 25800, 0.0, 0.0, 0.0 );
		return 1;
	}
	else if ( !strcmp( params, "detonate", true, 8 ) )
	{
		new cID;

		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
		else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );
		else if ( !IsPlayerJob( playerid, JOB_TERRORIST ) ) return SendError( playerid, "This is restricted to terrorists." );
		else if ( sscanf( params[ 9 ], "d", cID ) ) return SendUsage( playerid, "/c4 detonate [C4_ID] "COL_GREY"- Use detonator to blow all." );
		else if ( cID < 0 || cID >= MAX_C4 ) return SendError( playerid, "Invalid C4 ID specified." );
		else if ( g_C4Data[ playerid ] [ cID ] [ E_SET ] == false ) return SendError( playerid, "This C4 ID is not planted." );
		else
		{
			if ( ExplodePlayerC4s( playerid, cID, cID + 1 ) )
				SendServerMessage( playerid, "You have successfully detonated C4 ID %d.", cID );
			else
				SendError( playerid, "You cannot plant C4 at the moment, please try again later." );
		}
		return 1;
	}
	return SendUsage( playerid, "/c4 [PLANT/DETONATE]" );
}

/* ** Gang Commands ** */
CMD:takeover( playerid, params[ ] )
{
	if ( p_GangID[ playerid ] == INVALID_GANG_ID )
		return SendError( playerid, "You are not in any gang." );

	if ( p_Class[ playerid ] != CLASS_CIVILIAN )
		return SendError( playerid, "This is restricted to civilians only." );

	if ( GetPlayerInterior( playerid ) != 0 && GetPlayerVirtualWorld( playerid ) != 0 )
	    return SendError( playerid, "You cannot do this inside interiors." );

	if ( IsPlayerJailed( playerid ) || IsPlayerUsingOrbitalCannon( playerid ) )
		return SendError( playerid, "You cannot do this at the moment." );

	new
		g_isAFK = 0,
		g_inAir = 0
	;

    foreach ( new z : Reverse(turfs) )
	{
		if ( IsPlayerInDynamicArea( playerid, g_gangTurfData[ z ] [ E_AREA ] ) )
     	{
	    	new gangid = p_GangID[ playerid ];

	        if ( g_gangTurfData[ z ] [ E_OWNER ] == gangid ) return SendError( playerid, "This turf is already captured by your gang." );
			if ( g_gangzoneAttacker[ z ] != INVALID_GANG_ID ) return SendError( playerid, "This turf is currently being attacked." );

			new opposing_count = GetPlayersInGangZone( z, g_gangTurfData[ z ] [ E_OWNER ] ); // Opposing check
			// existing gang members
			if ( g_gangTurfData[ z ] [ E_OWNER ] != INVALID_GANG_ID && opposing_count ) {
				return SendError( playerid, "There are gang members within this turf, kill them!" );
	        }

	        new attacking_count = GetPlayersInGangZone( z, gangid, g_isAFK, g_inAir );

	        if ( attacking_count < TAKEOVER_NEEDED_PEOPLE && ( attacking_count + g_isAFK + g_inAir ) >= TAKEOVER_NEEDED_PEOPLE )
		   		return SendError( playerid, "You cannot start a turf war if gang members are AFK or extremely high above ground." );

	        //if ( g_gangTurfData[ z ] [ E_OWNER ] != INVALID_GANG_ID && dCount < TAKEOVER_NEEDED_PEOPLE + 1 && ( dCount + g_isAFK + g_inAir ) >= TAKEOVER_NEEDED_PEOPLE + 1 )
		   	//	return SendError( playerid, "You need at least %d gang members to start a gang war with another gang.", TAKEOVER_NEEDED_PEOPLE + 1 );

		   	// Facility check
		   	if ( g_gangTurfData[ z ] [ E_FACILITY_GANG ] != INVALID_GANG_ID && Iter_Contains( gangs, g_gangTurfData[ z ] [ E_FACILITY_GANG ] ) )
		   	{
		   		new facility_gang = g_gangTurfData[ z ] [ E_FACILITY_GANG ];
		   		new facility_members = GetOnlineGangMembers( facility_gang );

		   		if ( g_gangTurfData[ z ] [ E_OWNER ] == facility_gang ) {
			   		if ( facility_members < 3 ) {
			   			return SendError( playerid, "This facility requires at least %d of its gang members online for a takeover.", 3 - facility_members );
			   		}
			   		else if ( attacking_count < 3 ) {
		   				return SendError( playerid, "You need at least %d gang members to take over this facility.", 3 - attacking_count );
			   		}
		   		}
		   	}

		   	// Begin takeover
			if ( attacking_count >= TAKEOVER_NEEDED_PEOPLE && ! opposing_count )
	        {
				g_gangzoneAttacker[ z ] = gangid;
	            g_gangzoneAttackCount[ z ] = 0;
              	GangZoneFlashForAll( g_gangTurfData[ z ] [ E_ID ], setAlpha( g_gangData[ gangid ] [ E_COLOR ], 0x80 ) );
              	SendClientMessage( playerid, g_gangData[ gangid ] [ E_COLOR ], "[TURF]{FFFFFF} You are now beginning to take over the turf. Stay inside the area with your gang for 60 seconds. Don't die." );

	            if ( g_gangTurfData[ z ] [ E_OWNER ] != INVALID_GANG_ID )
	            {
	            	new
						szLocation[ MAX_ZONE_NAME ], Float: min_x, Float: min_y;

					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ z ] [ E_AREA ], E_STREAMER_MIN_X, min_x );
					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ z ] [ E_AREA ], E_STREAMER_MIN_Y, min_y );

					GetZoneFromCoordinates( szLocation, min_x, min_y );

	            	SendClientMessageToGang( g_gangTurfData[ z ] [ E_OWNER ], g_gangData[ g_gangTurfData[ z ] [ E_OWNER ] ] [ E_COLOR ], "[GANG]"COL_WHITE" Our territory is being attacked by "COL_GREY"%s"COL_WHITE" in %s, defend it!", g_gangData[ g_gangzoneAttacker[ z ] ] [ E_NAME ], szLocation );
	            }
	        }
	        else
	        {
	        	SendError( playerid, "You need at least %d member(s) to take over this turf.", TAKEOVER_NEEDED_PEOPLE );
	        }
	        return 1;
	    }
	}
	return SendError( playerid, "You are not in any gangzone." );
}

CMD:clans( playerid, params[ ] )
{
	mysql_function_query( dbHandle, "SELECT * FROM `GANGS` WHERE `CLAN_TAG` IS NOT NULL ORDER BY `SCORE` DESC", true, "readclans", "d", playerid );
	return 1;
}

thread readclans( playerid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTag[ 8 ],
    		szName[ 30 ],
    		iScore, iColor
    	;

    	szLargeString = ""COL_WHITE"Tag\t"COL_WHITE"Name\t"COL_WHITE"Score\n";

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "CLAN_TAG", szTag );
			cache_get_field_content( i, "NAME", szName );
			iScore = cache_get_field_content_int( i, "SCORE", dbHandle );
			iColor = cache_get_field_content_int( i, "COLOR", dbHandle );

			format( szLargeString, sizeof( szLargeString ), "%s[%s]\t{%06x}%s\t%d\n", szLargeString, szTag, iColor >>> 8, szName, iScore );
		}

		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "Clan List", szLargeString, "Close", "" ), 1;
	}
	SendError( playerid, "There are no clans to show." );
	return 1;
}

CMD:gangs( playerid, params[ ] )
{
	if ( !Iter_Count(gangs) )
		return SendError( playerid, "There are no gangs to list." );

	// store current sort into gangs & sort by respect
	g_sortedGangData = g_gangData;
	SortDeepArray( g_sortedGangData, E_RESPECT, .order = SORT_DESC );

	// create dialog
	szHugeString = ""COL_WHITE"Gang\t"COL_WHITE"Respect\n";

	for ( new g = 0; g < sizeof( g_sortedGangData ); g ++ ) if ( g_sortedGangData[ g ] [ E_SQL_ID ] != 0 ) {
		format( szHugeString, sizeof( szHugeString ), "%s{%06x}%s\t%d\n", szHugeString, g_sortedGangData[ g ] [ E_COLOR ] >>> 8, g_sortedGangData[ g ] [ E_NAME ], g_sortedGangData[ g ] [ E_RESPECT ] );
	}
	return ShowPlayerDialog( playerid, DIALOG_GANG_LIST, DIALOG_STYLE_TABLIST_HEADERS, "Gangs List", szHugeString, "Select", "Cancel" );
}

CMD:getgang( playerid, params[ ] )
{
	new
		pID
	;

	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/getgang [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "This player is not logged in." );
	else
	{
		if (p_GangID[ pID ] == INVALID_GANG_ID) {
			SendServerMessage( playerid, ""COL_GREY"%s(%d) is not in a gang.", ReturnPlayerName( pID ), pID );
		}
		else {
			SendServerMessage( playerid, ""COL_GREY"%s(%d) is in {%06x}%s", ReturnPlayerName( pID ), pID, g_gangData[ p_GangID[ pID ] ] [ E_COLOR ] >>> 8, g_gangData[ p_GangID[ pID ] ][ E_NAME ] );
		}
	}

	return 1;
}

CMD:gang( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );

	if ( !strcmp( params, "turfs", false, 5 ) )
	{
		if ( !Iter_Count( turfs ) )
			return SendError( playerid, "There is currently no trufs on the server." );

		szHugeString[ 0 ] = '\0';

		foreach( new turfid : turfs )
		{
			new
				szLocation[ MAX_ZONE_NAME ], Float: min_x, Float: min_y;

			Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ turfid ] [ E_AREA ], E_STREAMER_MIN_X, min_x );
			Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ turfid ] [ E_AREA ], E_STREAMER_MIN_Y, min_y );

			GetZoneFromCoordinates( szLocation, min_x, min_y );

		    if ( g_gangTurfData[ turfid ][ E_OWNER ] == INVALID_GANG_ID ) {
		    	format( szHugeString, sizeof( szHugeString ), "%s%s\t"COL_GREY"Unoccupied\n", szHugeString, szLocation );
		    }
		    else {
		    	format( szHugeString, sizeof( szHugeString ), "%s%s\t{%06x}%s\n", szHugeString, szLocation, g_gangTurfData[ turfid ][ E_COLOR ] >>> 8 , ReturnGangName( g_gangTurfData[ turfid ][ E_OWNER ] ) );
		    }
		}

		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, ""COL_WHITE"Gang Turfs", szHugeString, "Close", "" );
	}
	else if ( !strcmp( params, "leader", false, 6 ) )
	{
		new
		    pID
		;
	    if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ], .only_leader = 1 ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 7 ], "u", pID ) ) return SendUsage( playerid, "/gang leader [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( pID == playerid ) return SendError( playerid, "You cannot apply this action to yourself." );
		else if ( p_GangID[ pID ] != p_GangID[ playerid ] ) return SendError( playerid, "This player isn't in your gang." );
		else
		{
	        g_gangData[ p_GangID[ playerid ] ] [ E_LEADER ] = p_AccountID[ pID ];
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) is the new gang leader.", ReturnPlayerName( pID ), pID );
            SaveGangData( p_GangID[ playerid ] );
		}
		return 1;
	}
	else if ( !strcmp( params, "coleader", false, 8 ) )
	{
		new
			gangid = p_GangID[ playerid ], pID;

	    if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ], .only_leader = 1 ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 9 ], "u", pID ) ) return SendUsage( playerid, "/gang coleader [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( pID == playerid ) return SendError( playerid, "You cannot apply this action to yourself." );
		else if ( p_GangID[ pID ] != p_GangID[ playerid ] ) return SendError( playerid, "This player isn't in your gang." );
		else
		{
			new
				slotid = -1;

			for ( new i = 0; i < MAX_COLEADERS; i ++ )
			{
				// check for dupes
				if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] == p_AccountID[ pID ] )
					return SendError( playerid, "This player is already a coleader of your gang." );

				// find slot
				if ( ! g_gangData[ gangid ] [ E_COLEADER ] [ i ] ) {
					slotid = i;
					break;
				}
			}

			if ( slotid != -1 )
			{
		        g_gangData[ gangid ] [ E_COLEADER ] [ slotid ] = p_AccountID[ pID ];
				SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) is the #%d co-leader.", ReturnPlayerName( pID ), pID, slotid + 1 );
				mysql_single_query( sprintf( "INSERT INTO `GANG_COLEADERS` (`GANG_ID`,`USER_ID`) VALUES (%d, %d)", g_gangData[ gangid ] [ E_SQL_ID ], p_AccountID[ pID ] ) );
			}
			else SendError( playerid, "There can only be a maximum of %d gang co-leaders. Kick one of them first.", MAX_COLEADERS );
		}
		return 1;
	}
	else if ( !strcmp( params, "kick", false, 4 ) )
	{
		new
		    pID
		;

		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 5 ], "u", pID ) ) return SendUsage( playerid, "/gang kick [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( p_GangID[ pID ] != p_GangID[ playerid ] ) return SendError( playerid, "This player isn't in your gang." );
		else if ( IsPlayerGangLeader( pID, p_GangID[ playerid ], .only_leader = 1 ) ) return SendError( playerid, "This person is the gang leader." );
		else
		{
			RemovePlayerFromGang( pID, GANG_LEAVE_KICK, playerid );
		}
		return 1;
	}
	else if ( !strcmp( params, "name", false, 4 ) )
	{
		new
		    szName[ 30 ]
		;

		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 5 ], "s[30]", szName ) ) return SendUsage( playerid, "/gang name [GANG_NAME]" );
		else if ( textContainsIP( szName ) || textContainsBadTextdrawLetters( szName ) ) return SendError( playerid, "Invalid Gang Name." );
		else if ( gangNameExists( szName ) ) return SendError( playerid, "This gang already exists, try another name." );
		else
		{
			trimString( szName );
			format( g_gangData[ p_GangID[ playerid ] ] [ E_NAME ], 30, "%s", szName );
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has changed the gang's name to {%06x}%s"COL_WHITE".", ReturnPlayerName( playerid ), playerid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ] >>> 8, szName );
            SaveGangData( p_GangID[ playerid ] );
		}
		return 1;
	}
	else if ( !strcmp( params, "color", false, 5 ) )
	{
		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) ) return SendError( playerid, "You are not the gang leader." );

		return ShowPlayerDialog( playerid, DIALOG_GANG_COLOR, DIALOG_STYLE_LIST, "Gang Colors", ""COL_GREY"Custom Hex Code "COL_GOLD"[V.I.P]\n{99FF00}Yellow Green\n{00CC00}Green\n{009999}Blue Green\n{0033CC}Blue\n{330099}Blue Violet\n{660099}Violet\n{CC0099}Red Violet", "Select", "Cancel" );
	}
	else if ( !strcmp( params, "create", false, 5 ) )
	{
		new
		    szName[ 30 ]
		;

		if ( sscanf( params[ 6 ], "s[30]", szName ) ) return SendUsage( playerid, "/gang create [GANG_NAME]" );
		else if ( p_GangID[ playerid ] != INVALID_GANG_ID ) return SendError( playerid, "To make a gang, you must leave your current gang with /gang leave" );
		else if ( textContainsIP( szName ) || textContainsBadTextdrawLetters( szName ) ) return SendError( playerid, "Invalid Gang Name." );
		else if ( gangNameExists( szName ) ) return SendError( playerid, "This gang already exists, try another name." );
		else
		{
			new
				handle = CreateGang( .gang_name = szName, .leader = p_AccountID[ playerid ], .gang_color = g_gangColors[ random( sizeof( g_gangColors ) ) ] );

			if ( handle != INVALID_GANG_ID )
			{
			    p_GangID[ playerid ] = handle; // set it anyway here just incase of cache taking a bit

			    if ( p_WantedLevel[ playerid ] == 0 && p_AdminOnDuty{ playerid } == false )
			    	SetPlayerColor( playerid, g_gangData[ handle ] [ E_COLOR ] );

				mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=%d WHERE `ID`=%d", g_gangData[ handle ] [ E_SQL_ID ], p_AccountID[ playerid ] ) );
			    SendClientMessageToGang( handle, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} You have created the gang: %s (%d)", szName, g_gangData[ handle ] [ E_SQL_ID ] );
			}
			else SendError( playerid, "There are no available slots to create a gang." );
		}
		return 1;
	}
	else if ( !strcmp( params, "joinmsg", false, 7 ) )
	{
		new
			gangid = p_GangID[ playerid ];

		if ( gangid == INVALID_GANG_ID ) return SendError( playerid, "You are not inside any gang." );
		if ( !IsPlayerGangLeader( playerid, gangid ) ) return SendError( playerid, "You are not the gang leader." );

		if ( sscanf( params[ 8 ], "s[96]", g_gangData[ gangid ] [ E_JOIN_MSG ] ) )
		{
			mysql_single_query( sprintf( "UPDATE `GANGS` SET `JOIN_MSG`=NULL WHERE `ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) removed the gang's join message.", ReturnPlayerName( playerid ), playerid );
		}
		else
		{
			format( szBigString, sizeof( szBigString ), "UPDATE `GANGS` SET `JOIN_MSG`='%s' WHERE `ID`=%d", mysql_escape( g_gangData[ gangid ] [ E_JOIN_MSG ] ), g_gangData[ gangid ] [ E_SQL_ID ] );
			mysql_single_query( szBigString );

			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) set the gang's join message:", ReturnPlayerName( playerid ), playerid );
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s", g_gangData[ gangid ] [ E_JOIN_MSG ] );
		}
		return 1;
	}
	else if ( !strcmp( params, "join", false, 4 ) )
	{
		new
		    gID
		;
		if ( sscanf( params[ 5 ], "d", gID ) ) return SendUsage( playerid, "/gang join [GANG_ID]" );
		else if ( gID < 0 || gID >= MAX_GANGS ) return SendError( playerid, "Invalid Gang ID." );
		else if ( !Iter_Contains( gangs, gID ) ) return SendError( playerid, "Invalid Gang ID." );
		else if ( p_gangInvited[ playerid ] [ gID ] == false ) return SendError( playerid, "You haven't been invited to this gang." );
		else if ( g_iTime > p_gangInviteTick[ playerid ] ) return p_gangInvited[ playerid ] [ gID ] = false, SendError( playerid, "This invite has expired, each invite only lasts for 2 minutes." );
		else if ( p_GangID[ playerid ] != INVALID_GANG_ID ) return SendError( playerid, "You are already inside a gang." );
		else
		{
		    p_gangInvited[ playerid ] [ gID ] = false;
		    SetPlayerGang( playerid, gID );
		}
		return 1;
	}
	else if ( !strcmp( params, "invite", false, 6 ) )
	{
		new
		    pID
		;

		if ( sscanf( params[ 7 ], "u", pID ) ) return SendUsage( playerid, "/gang invite [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not connected." );
		else if ( p_Class[ pID ] != CLASS_CIVILIAN ) return SendError( playerid, "You cannot invite people from non-civilian classes." );
		else if ( IsPlayerSettingToggled( pID, SETTING_GANG_INVITES ) ) return SendError( playerid, "This player has disabled gang invites." );
		else if ( pID == playerid ) return SendError( playerid, "You cannot use this on yourself." );
		else if ( p_GangID[ pID ] != INVALID_GANG_ID ) return SendError( playerid, "This player is already inside a gang." );
		else if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside any gang." );
		else if ( p_GangID[ pID ] == p_GangID[ playerid ] ) return SendError( playerid, "This player is in your gang." );
		else
		{
			if ( g_gangData[ p_GangID[ playerid ] ] [ E_INVITE_ONLY ] && !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) )
				return SendError( playerid, "You are not the gang leader." );

		    p_gangInvited[ pID ] [ p_GangID[ playerid ] ] = true;
		    p_gangInviteTick[ pID ] = g_iTime + 120;
			GameTextForPlayer( pID, sprintf( "~n~~y~~h~/gang join %d", p_GangID[ playerid ] ), 2000, 4 );
		    format( szNormalString, sizeof( szNormalString ), "[GANG]{FFFFFF} %s(%d) has invited you to join %s, to join type \"/gang join %d\"", ReturnPlayerName( playerid ), playerid, g_gangData[ p_GangID[ playerid ] ] [ E_NAME ], p_GangID[ playerid ] );
			SendClientMessage( pID, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], szNormalString );
			format( szNormalString, sizeof( szNormalString ), "[GANG]{FFFFFF} You have invited %s(%d) to join your gang.", ReturnPlayerName( pID ), pID );
			SendClientMessage( playerid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], szNormalString );
		}
		return 1;
	}
	else if ( !strcmp( params, "leave", false, 5 ) )
	{
		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not in any gang." );
		RemovePlayerFromGang( playerid, GANG_LEAVE_QUIT );
		return SendServerMessage( playerid, "You have left your previous gang." );
	}
	else if ( !strcmp( params, "splitprofit", false, 11 ) )
	{
		new
			fProfitSplit;

		if ( sscanf( params[ 12 ], "d", fProfitSplit ) ) SendUsage( playerid, "/gang splitprofit [PERCENTAGE]" );
		else if ( p_GangID[ playerid ] == INVALID_GANG_ID ) SendError( playerid, "You are not inside any gang." );
		else if ( fProfitSplit == 0 && p_GangSplitProfits[ playerid ] == 0 ) SendError( playerid, "You are already not splitting any profit among your gang bank." );
		else if ( fProfitSplit == 0 )
		{
			p_GangSplitProfits[ playerid ] = 0;
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has decided to no longer split his profits to the gang.", ReturnPlayerName( playerid ), playerid );
		}
		else if ( fProfitSplit == p_GangSplitProfits[ playerid ] && fProfitSplit != 0 ) SendError( playerid, "Your current profit split is the same as the percentage you specified." );
		else if ( 0 < fProfitSplit > 100 ) SendError( playerid, "Choose a percentage between 0 and 100." );
		else if ( fProfitSplit > 99999999 || fProfitSplit < 0 ) SendError( playerid, "Choose a percentage between 0 and 100." ); // Going over billions
		else
		{
			p_GangSplitProfits[ playerid ] = fProfitSplit;
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has decided to split %d%s of his profit into the gang bank.", ReturnPlayerName( playerid ), playerid, fProfitSplit, "%%" );
		}
		return 1;
	}
	else if ( !strcmp( params, "private", false, 6 ) )
	{
		new
			gangid = p_GangID[ playerid ];

		if ( gangid == INVALID_GANG_ID ) return SendError( playerid, "You are not inside any gang." );
		else if ( ! IsPlayerGangLeader( playerid, gangid ) ) return SendError( playerid, "You are not a gang leader." );
		else
		{
			// Reset all gang invites
			for( new i = 0; i < MAX_PLAYERS; i++ ) {
				p_gangInvited[ i ] [ gangid ] = false;
			}

			// Update private status
			mysql_single_query( sprintf( "UPDATE `GANGS` SET `INVITE_ONLY`=%d WHERE `ID`=%d", ( g_gangData[ gangid ] [ E_INVITE_ONLY ] = !g_gangData[ gangid ] [ E_INVITE_ONLY ] ), g_gangData[ gangid ] [ E_SQL_ID ] ) );
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) %s made the gang private.", ReturnPlayerName( playerid ), playerid, g_gangData[ gangid ] [ E_INVITE_ONLY ] ? ( "has" ) : ( "has not" ) );
		}
		return 1;
	}
	return SendUsage( playerid, "/gang [CREATE/LEAVE/INVITE/JOIN/KICK/NAME/LEADER/COLEADER/COLOR/SPLITPROFIT/PRIVATE/JOINMSG]" );
}

CMD:g( playerid, params[ ] )
{
	new
	    msg[ 90 ]
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "Civilians can use this command only." );
	else if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not in any gang." );
    else if ( sscanf( params, "s[90]", msg ) ) return SendUsage( playerid, "/g [MESSAGE]" );
    else
	{
		SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "<Gang Chat> %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, msg );
	}
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

#include "irresistible\cnr\commands\admin\admin_three.pwn" // move to irresistible\cnr\commands\admin\_admin.pwn
#include "irresistible\cnr\commands\admin\admin_four.pwn" // move to irresistible\cnr\commands\admin\_admin.pwn
#include "irresistible\cnr\commands\admin\admin_five.pwn" // move to irresistible\cnr\commands\admin\_admin.pwn
#include "irresistible\cnr\commands\admin\admin_six.pwn" // move to irresistible\cnr\commands\admin\_admin.pwn
#include "irresistible\cnr\commands\admin\admin_rcon.pwn" // move to irresistible\cnr\commands\admin\_admin.pwn

/* End of admin commands */
#if ENABLE_DISCORD == true
/* ** IRC ** */
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
#endif
/* ** End of Commands ** */


public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	new
		iModel = GetVehicleModel( vehicleid ),
    	driverid = GetVehicleDriver( vehicleid )
    ;


	if ( !ispassenger )
	{
		new
			iObject = GetGVarInt( "heli_gunner", vehicleid );

		if ( !iObject && ( iModel == 487 || iModel == 497 ) ) { // Chopper gunner!
			SetGVarInt( "heli_gunner", CreateDynamicObject( 19464, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ), vehicleid );
			SetObjectInvisible( GetGVarInt( "heli_gunner", vehicleid ) );
			AttachDynamicObjectToVehicle( GetGVarInt( "heli_gunner", vehicleid ), vehicleid, 0.0, 0.3, -1.75, 0.0, 90.0, 0.0 );
		}

		else if ( iObject && !( iModel == 487 || iModel == 497 ) ) { // An issue, not a maverick but has maverick thing.
			DestroyDynamicObject( iObject );
			DeleteGVar( "heli_gunner", vehicleid );
		}

    	// Stop player team jacking
    	/*if ( driverid != INVALID_PLAYER_ID && p_Class[ playerid ] != CLASS_CIVILIAN && p_Class[ playerid ] == p_Class[ driverid ] )
    		SyncObject( playerid ), GameTextForPlayer( playerid, "~r~Don't jack your teammates~w~!", 2000, 4 );*/

		p_LastVehicle[ playerid ] = vehicleid;
	}
	else
    {
    	switch( iModel )
    	{
		   	case 519: // Shamal
		   	{
		     	SetPlayerPos( playerid, 1322.6577, 1992.5508, 1200.2574 );
		     	SetPlayerVirtualWorld( playerid, vehicleid + VW_SHAMAL );
		   		SetPlayerInterior( playerid, VW_SHAMAL );
		     	pauseToLoad( playerid );
		   	}
    	}

		// Enter a wanted players vehicle?
    	if ( driverid != INVALID_PLAYER_ID && !p_WantedLevel[ playerid ] && p_Class[ playerid ] != CLASS_POLICE )
    	{
    		if ( p_WantedLevel[ driverid ] > 1 )
    			GivePlayerWantedLevel( playerid, 2 );

    		else if ( p_WantedLevel[ driverid ] > 5 )
    			GivePlayerWantedLevel( playerid, 6 );

    		else if ( p_WantedLevel[ driverid ] > 11 )
    			GivePlayerWantedLevel( playerid, 12 );
    	}
    }

	if ( IsPlayerAttachedObjectSlotUsed( playerid, 0 ) ) // [PRO_LIZZY] Once you enter a vehicle, and cancel entering, no animation is applied.
	    CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_CROUCH, KEY_SPRINT );

	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	new
		iRace = p_raceLobbyId[ playerid ],
		iModel = GetVehicleModel( vehicleid ),
		iObject = GetGVarInt( "heli_gunner", vehicleid )
	;

	if ( GetPlayerState( playerid ) == PLAYER_STATE_DRIVER )
	{
		if ( iObject && ( iModel == 487 || iModel == 497 ) )
		{
			DestroyDynamicObject( iObject );
			DeleteGVar( "heli_gunner", vehicleid );
		}

		p_LastAttachedVehicle[ playerid ] = INVALID_VEHICLE_ID;
	}

	if ( Iter_Contains( races, iRace ) )
	{
		SendClientMessageToRace( iRace, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has exited their vehicle and left the race.", ReturnPlayerName( playerid ), playerid );
		RemovePlayerFromRace( playerid );
	}
	return 1;
}

public OnVehicleDamageStatusUpdate( vehicleid, playerid )
{
    GetVehicleDamageStatus( vehicleid, panels, doors, lights, tires );
	if ( GetPlayerState( playerid ) == PLAYER_STATE_DRIVER )
	{
	    if ( lights || tires )
	        return 1;

		new time = GetTickCount( );
		switch( time - p_DamageSpamTime[ playerid ] )
		{
			case 0 .. 500:
			{
				p_DamageSpamCount{ playerid } ++;
				if ( p_DamageSpamCount{ playerid } >= 10 )
				{
					SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been kicked for car particle spam.", ReturnPlayerName( playerid ), playerid );
					Kick( playerid );
					return 1;
				}
			}
			default: p_DamageSpamCount{ playerid } = 0;
		}
		p_DamageSpamTime[ playerid ] = time;
 	}
	return 1;
}

public OnPlayerDriveVehicle( playerid, vehicleid )
{
	new
	    model = GetVehicleModel( vehicleid ),
	    time = g_iTime
	;

	if ( IsPlayerUsingAnimation( playerid ) ) // cancel animations
   		CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_SPRINT, KEY_SECONDARY_ATTACK );

	if ( p_Cuffed{ playerid } ) {
        RemovePlayerFromVehicle( playerid );
        return 1;
	}

	if ( ! g_Driveby ) {
		SetPlayerArmedWeapon( playerid, 0 );
	}

	if ( IsPlayerInPoliceCar( playerid ) && p_Class[ playerid ] != CLASS_POLICE && p_LastDrovenPoliceVeh[ playerid ] != vehicleid && GetPVarInt( playerid, "entercopcar_ts" ) < time && !g_buyableVehicle{ vehicleid } ) {
		if ( ! IsWeaponInAnySlot( playerid, 26 ) && ! IsWeaponInAnySlot( playerid, 27 ) ) GivePlayerWeapon( playerid, 25, 25 ); // free shotgun
		SetPVarInt( playerid, "entercopcar_ts", time + 30 );
		GivePlayerWantedLevel( playerid, 2 );
	}

	if ( model == 498 && p_Class[ playerid ] != CLASS_POLICE )
	{
		format( szSmallString, sizeof( szSmallString ), "vburg_%d_items", vehicleid );
		if ( GetGVarInt( szSmallString ) > 0 )
		{
			new
				Float: X, Float: Y, Float: Z,
				Float: pX, Float: pY, Float: pZ;

			GetPlayerPos( playerid, pX, pY, pZ );

			Beep( playerid );
			GameTextForPlayer( playerid, "Go to the truck blip on your radar for money!", 3000, 1 );
			SendServerMessage( playerid, "Note! You have %d stolen goods that you can export for money!", GetGVarInt( szSmallString ) );

			static
				szCity[ MAX_ZONE_NAME ],
				aPlayer[ 1 ];

			aPlayer[ 0 ] = playerid;
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );

			Get2DCity( szCity, pX, pY, pZ );

			if ( strmatch( szCity, "Los Santos" ) )
			{
				X = 2522.1677;
				Y = -1717.4137;
				Z = 13.6086;
			}
			else if ( strmatch( szCity, "Las Venturas" ) )
			{
				X = 2481.6812;
				Y = 1315.8477;
				Z = 10.6797;
			}
			else // default SF if not LV and LS
			{
				X = -2480.2461;
				Y = 6.0720;
				Z = 25.6172;
			}

			p_PawnStoreMapIcon[ playerid ] = CreateDynamicMapIconEx( X, Y, Z, 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
			p_PawnStoreExport[ playerid ] = CreateDynamicRaceCP( 1, X, Y, Z, 0.0, 0.0, 0.0, 4.0, -1, -1, playerid );
		}
	}

	if ( model == 525 ) {
		ShowPlayerHelpDialog( playerid, 2500, "You can tow vehicles by pressing ~k~~VEHICLE_FIREWEAPON_ALT~!" );
	}


	p_LastDrovenPoliceVeh[ playerid ] = vehicleid;

	if ( p_AdminLevel[ playerid ] < 3 )
	{
		if ( p_inArmy{ playerid } == false )
		{
		    if ( model == 520 || model == 425 || model == 432 )
		    {
				SyncObject( playerid, 1 );
			    //RemovePlayerFromVehicle( playerid );
			    SendError( playerid, "The army are only authorized to use this." );
			    return 1;
			}
		}
		if ( p_Class[ playerid ] != CLASS_FIREMAN )
		{
			if ( model == 407 || model == 544 )
			{
				SyncObject( playerid, 1 );
				//RemovePlayerFromVehicle( playerid );
				SendError( playerid, "Firemen are only authorized to use this." );
				return 1;
			}
		}
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if ( IsPlayerNPC( playerid ) )
		return 1; // fcnpc

	new
		vID = GetPlayerVehicleID( playerid );

	p_LastPlayerState{ playerid } = oldstate;


    if ( oldstate == PLAYER_STATE_SPECTATING )
    {
    	ResetPlayerWeapons( playerid );
        for( new i; i < sizeof( p_SpectateWeapons[ ] ); i++ )
        {
        	GivePlayerWeapon( playerid, p_SpectateWeapons[ playerid ] [ i ] [ 0 ], p_SpectateWeapons[ playerid ] [ i ] [ 1 ] );
        	p_SpectateWeapons[ playerid ] [ i ] [ 0 ] = 0, p_SpectateWeapons[ playerid ] [ i ] [ 1 ] = 0;
        }
    }

    if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER ) // Driver has a new state?
    {
		if ( p_PawnStoreExport[ playerid ] != 0xFFFF )
		{
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = 0xFFFF;
			DestroyDynamicRaceCP( p_PawnStoreExport[ playerid ] );
			p_PawnStoreExport[ playerid ] = 0xFFFF;
		}
    }

	if ( newstate == PLAYER_STATE_DRIVER ) {
		CallLocalFunction( "OnPlayerDriveVehicle", "dd", playerid, vID );
	}

	//if ( newstate == PLAYER_STATE_ONFOOT && p_Detained{ playerid } == true && IsPlayerConnected( p_DetainedBy[ playerid ] ) )
	//    return PutPlayerInEmptyVehicleSeat( p_LastVehicle[ p_DetainedBy[ playerid ] ], playerid );

	if ( newstate == PLAYER_STATE_PASSENGER )
	{
		if ( hasBadDrivebyWeapon( playerid ) ) // Some weapons are abusable.
			SetPlayerArmedWeapon( playerid, 0 );
	}
	return SyncSpectation( playerid, newstate );
}

public OnPlayerLeaveDynamicCP( playerid, checkpointid )
{
	return 1;
}

public OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	static
		aPlayer[ 1 ];

	aPlayer[ 0 ] = playerid;


	if ( IsPlayerJailed( playerid ) ) // || && !bDropoff
	    return SendError( playerid, "You're jailed, and you accessed a checkpoint. I smell a cheater." ), KickPlayerTimed( playerid ), 1;

	/* ** Continue ** */
	if ( checkpointid == g_Checkpoints[ CP_BOMB_SHOP ] || checkpointid == g_Checkpoints[ CP_BOMB_SHOP_LV ] || checkpointid == g_Checkpoints[ CP_BOMB_SHOP_LS ] )
	{
		if ( !IsPlayerJob( playerid, JOB_TERRORIST ) )
			ShowPlayerHelpDialog( playerid, 4000, "You are not a ~r~terrorist~w~~h~ so you won't be able to use the C4 bought!" );
			//return ShowPlayerHelpDialog( playerid, 4000, "You need to be a ~r~terrorist~w~~h~ to buy C4!" );

		return ShowPlayerDialog( playerid, DIALOG_BOMB_SHOP, DIALOG_STYLE_TABLIST, "{FFFFFF}C4 Shop", "1 C4\t"COL_GOLD"$500\n5 C4\t"COL_GOLD"$2450\nSell C4\t"COL_GREEN"$250", "Select", "Cancel" ), 1;
	}

	// Refill ammunition
	if ( checkpointid == g_Checkpoints[ CP_REFILL_AMMO ] || checkpointid == g_Checkpoints[ CP_REFILL_AMMO_LS ] || checkpointid == g_Checkpoints[ CP_REFILL_AMMO_LV ] ) {
		if ( p_Class[ playerid ] == CLASS_POLICE ) {
			if ( g_iTime < p_CopRefillTimestamp[ playerid ] ) {
				return SendError( playerid, "You must wait %s before refilling your weapons again.", secondstotime( p_CopRefillTimestamp[ playerid ] - g_iTime ) );
			} else {
				GivePlayerLeoWeapons( playerid );
				p_CopRefillTimestamp[ playerid ] = g_iTime + 300;
				return SendServerMessage( playerid, "You have refilled your ammunition." );
			}
		} else {
			return SendError( playerid, "Only law enforcement officers can use this feature." );
		}
	}

	if ( checkpointid == g_Checkpoints[ CP_REWARDS_4DRAG ] || checkpointid == g_Checkpoints[ CP_REWARDS_CALIG ] || checkpointid == g_Checkpoints[ CP_REWARDS_VISAGE ] )
		return ShowPlayerRewardsMenu( playerid );

	if ( checkpointid == g_Checkpoints[ CP_BANK_MENU ] || checkpointid == g_Checkpoints[ CP_COUNTRY_BANK_MENU ] || checkpointid == g_Checkpoints[ CP_BANK_MENU_LS ] )
 		return ShowPlayerBankMenuDialog( playerid ), 1;

 	if ( checkpointid == g_Checkpoints[ CP_CASINO_BAR ] )
 		return ShowPlayerDialog( playerid, DIALOG_CASINO_BAR, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Casino Bar", ""COL_WHITE"Bar Item\t"COL_WHITE"Casino Rewards Points\nBeer\t"COL_GOLD"20.0 Points\nCigar\t"COL_GOLD"20.0 Points\nWine\t"COL_GOLD"20.0 Points", "Buy", "Close" ), 1;

	if ( checkpointid == g_Checkpoints[ CP_CHANGE_JOB ] )
 		return ShowPlayerDialog( playerid, DIALOG_CITY_HALL, DIALOG_STYLE_LIST, "{FFFFFF}City Hall", ""COL_GOLD"$5,000"COL_WHITE"\t\tChange Job\n"COL_GOLD"free"COL_WHITE"\t\tChange City", "Select", "Close" ), 1;

	if ( checkpointid == g_Checkpoints[ CP_HOSPITAL ] || checkpointid == g_Checkpoints[ CP_HOSPITAL_LV ] || checkpointid == g_Checkpoints[ CP_HOSPITAL1_LS ] || checkpointid == g_Checkpoints[ CP_HOSPITAL2_LS ] || checkpointid == g_Checkpoints[ CP_HOSPITAL_FC ] )
		return ShowPlayerDialog( playerid, DIALOG_HOSPITAL, DIALOG_STYLE_LIST, "{FFFFFF}Medical Center", ""COL_GOLD"$2,000"COL_WHITE"\t\tHeal Yourself\n"COL_GOLD"$4,000"COL_WHITE"\t\tCure Yourself\n"COL_GOLD"$6,000"COL_WHITE"\t\tCure And Heal", "Select", "Close" ), 1;

	if ( checkpointid == g_Checkpoints[ CP_AIRPORT_LV ] || checkpointid == g_Checkpoints[ CP_AIRPORT_SF ] || checkpointid == g_Checkpoints[ CP_AIRPORT_LS ] )
		return ShowPlayerAirportMenu( playerid );

	if ( checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_COKE ] || checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_METH ] || checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_WEED ] || checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_WEAP ] )
		return ShowBusinessTerminal( playerid );

	if ( checkpointid == g_Checkpoints[ CP_247_MENU ] )
		return cmd_shop( playerid, "" );

	new
		houseid = p_InHouse[ playerid ];

	if ( houseid != -1 && GetPlayerInterior( playerid ) == g_houseData[ houseid ] [ E_INTERIOR_ID ] && checkpointid != g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] ) {
		return SetPlayerPos( playerid, g_houseData[ houseid ] [ E_TX ], g_houseData[ houseid ] [ E_TY ], g_houseData[ houseid ] [ E_TZ ] );
	}

	// Detain Mechanism
	/*if ( bDropoff )
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
	}*/

	if ( checkpointid == g_Checkpoints[ CP_FIGHTSTYLE ] || checkpointid == g_Checkpoints[ CP_FIGHTSTYLE_LV ] || checkpointid == g_Checkpoints[ CP_FIGHTSTYLE_LS ] )
	{
	    ShowPlayerDialog( playerid, DIALOG_FIGHTSTYLE, DIALOG_STYLE_LIST, "{FFFFFF}Fightstyle", ""COL_GOLD"$1000{FFFFFF} \tDefence\n"COL_GOLD"$4000{FFFFFF} \tBoxing\n"COL_GOLD"$9000{FFFFFF} \tKungfu", "Purchase", "Cancel" );
	    return 1;
	}

	if ( checkpointid == g_Checkpoints[ CP_AMMUNATION_0 ] || checkpointid == g_Checkpoints[ CP_AMMUNATION_1 ] || checkpointid == g_Checkpoints[ CP_AMMUNATION_2 ] )
    	return ShowAmmunationMenu( playerid );

	if ( checkpointid == g_Checkpoints[ CP_PAINTBALL ] )
		return listPaintBallLobbies( playerid );

	if ( CanPlayerExitEntrance( playerid ) )
	{
		if ( ! IsPlayerInAnyVehicle( playerid ) )
		{
			// Enter Business
			foreach ( new b : business )
			{
				if ( checkpointid == g_businessData[ b ] [ E_ENTER_CP ] )
				{
					if ( p_Class[ playerid ] != CLASS_CIVILIAN )
						return SendError( playerid, "You must be a civilian to access this business." );

					if ( g_iTime > g_businessData[ b ] [ E_CRACKED_TS ] && g_businessData[ b ] [ E_CRACKED ] )
						g_businessData[ b ] [ E_CRACKED ] = false; // The Virus Is Disabled.

					if ( ! g_businessData[ b ] [ E_CRACKED ] && ! IsBusinessAssociate( playerid, b ) )
						return SendError( playerid, "You cannot access this business as you are not an associate of it." );

					new
						bType = g_businessData[ b ] [ E_INTERIOR_TYPE ];

		        	pauseToLoad( playerid );
					p_InBusiness[ playerid ] = b;
				    UpdatePlayerEntranceExitTick( playerid );
					SetPlayerPos( playerid, g_businessInteriorData[ bType ] [ E_X ], g_businessInteriorData[ bType ] [ E_Y ], g_businessInteriorData[ bType ] [ E_Z ] );
				  	SetPlayerVirtualWorld( playerid, g_businessData[ b ] [ E_WORLD ] );
					SetPlayerInterior( playerid, g_businessData[ b ] [ E_INTERIOR_TYPE ] + 20 );
					return 1;
				}
				else if ( checkpointid == g_businessData[ b ] [ E_EXIT_CP ] )
				{
					p_InBusiness[ playerid ] = -1;
					TogglePlayerControllable( playerid, 0 );
				    UpdatePlayerEntranceExitTick( playerid );
					SetTimerEx( "ope_Unfreeze", 1250, false, "d", playerid );
					SetPlayerPosEx( playerid, g_businessData[ b ] [ E_X ], g_businessData[ b ] [ E_Y ], g_businessData[ b ] [ E_Z ], 0 ), SetPlayerVirtualWorld( playerid, 0 );
				}
			}

			// Enter Houses
			foreach ( new i : houses )
			{
			    if ( checkpointid == g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] )
			    {
					ClearAnimations( playerid ); // clear-fix

			        if ( IsHouseOnFire( i ) ) {
			            return SendError( playerid, "This house is on fire, you cannot enter it!" ), 1;
			        }

					if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_CUFFED ) {
						return SendError( playerid, "You can't do anything as you are cuffed." ), 1;
					}

					if ( g_iTime > g_houseData[ i ] [ E_CRACKED_TS ] && g_houseData[ i ] [ E_CRACKED ] )
						g_houseData[ i ] [ E_CRACKED ] = false; // The Virus Is Disabled.

					new is_owner = strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) );

			        if ( !g_houseData[ i ] [ E_CRACKED ] && !strmatch( g_houseData[ i ] [ E_PASSWORD ], "N/A" ) && ! is_owner )
					{
					    p_PasswordedHouse[ playerid ] = i;
					    ShowPlayerDialog( playerid, DIALOG_HOUSE_PW, DIALOG_STYLE_PASSWORD, "{FFFFFF}House Authentication", ""COL_GREEN"This house is password locked!\n"COL_WHITE"You may only enter this house if you enter the correct password.", "Enter", "Cancel" );
						return 1;
					}

					// alert burglar of any furniture
					if ( ! is_owner && p_Job{ playerid } == JOB_BURGLAR && p_Class[ playerid ] == CLASS_CIVILIAN ) {
						if ( Iter_Count( housefurniture[ i ] ) ) {
							ShowPlayerHelpDialog( playerid, 4000, "This house has furniture to rob.~n~~n~Type ~g~~h~/burglar steal~w~ near the furniture you want to steal." );
						} else {
							ShowPlayerHelpDialog( playerid, 4000, "~r~This house has no furniture to rob." );
						}
					}

					p_InHouse[ playerid ] = i;
				    UpdatePlayerEntranceExitTick( playerid );
				  	SetPlayerVirtualWorld( playerid, g_houseData[ i ] [ E_WORLD ] );
					SetPlayerInterior( playerid, g_houseData[ i ] [ E_INTERIOR_ID ] );
					SetPlayerPos( playerid, g_houseData[ i ] [ E_TX ], g_houseData[ i ] [ E_TY ], g_houseData[ i ] [ E_TZ ] );
					return 1;
				}
				else if ( checkpointid == g_houseData[ i ] [ E_CHECKPOINT ] [ 1 ] )
				{
					p_InHouse[ playerid ] = -1;
					CancelEdit( playerid );
					TogglePlayerControllable( playerid, 0 );
				    UpdatePlayerEntranceExitTick( playerid );
					SetTimerEx( "ope_Unfreeze", 1250, false, "d", playerid );
					SetPlayerPosEx( playerid, g_houseData[ i ] [ E_EX ], g_houseData[ i ] [ E_EY ], g_houseData[ i ] [ E_EZ ], 0 ), SetPlayerVirtualWorld( playerid, 0 );
					return 1;
				}
			}

			foreach ( new i : entrances )
			{
		        if ( checkpointid == g_entranceData[ i ] [ E_ENTER ] )
				{
				    if ( ! CallLocalFunction( "OnPlayerAccessEntrance", "dd", playerid, i ) ) break;
					p_LastEnteredEntrance[ playerid ] = i;
				    SetPlayerInterior( playerid, g_entranceData[ i ] [ E_INTERIOR ] );
				    SetPlayerVirtualWorld( playerid, g_entranceData[ i ] [ E_WORLD ] );
				    SetPlayerPos( playerid, g_entranceData[ i ] [ E_LX ], g_entranceData[ i ] [ E_LY ], g_entranceData[ i ] [ E_LZ ] );
				    UpdatePlayerEntranceExitTick( playerid );
				    if ( g_entranceData[ i ] [ E_CUSTOM ] )
				    {
				    	pauseToLoad( playerid );
				 		p_BulletInvulnerbility[ playerid ] = g_iTime + 6; // Additional 3 because of pausetoload
				    }
				    else
				    {
						TogglePlayerControllable( playerid, 0 );
						SetTimerEx( "ope_Unfreeze", 1250, false, "d", playerid );
				 		p_BulletInvulnerbility[ playerid ] = g_iTime + 3;
					}
					SyncSpectation( playerid );
				   	return 1;
				}
				else if ( checkpointid == g_entranceData[ i ] [ E_EXIT ] )
				{
					p_BulletInvulnerbility[ playerid ] = 0;
					p_LastEnteredEntrance[ playerid ] = -1;
				    SetPlayerPos( playerid, g_entranceData[ i ] [ E_EX ], g_entranceData[ i ] [ E_EY ], g_entranceData[ i ] [ E_EZ ] );
				    SetPlayerInterior( playerid, 0 );
					TogglePlayerControllable( playerid, 0 );
					SetTimerEx( "ope_Unfreeze", 1250, false, "d", playerid );
				    SetPlayerVirtualWorld( playerid, 0 );
				    UpdatePlayerEntranceExitTick( playerid );
					SyncSpectation( playerid );
				   	return 1;
				}
		    }
		}
	}
	return 1;
}

public OnPlayerAccessEntrance( playerid, entranceid )
{
    if ( g_entranceData[ entranceid ] [ E_VIP ] && p_VIPLevel[ playerid ] < VIP_REGULAR ) {
        return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" ), 0;
    }
    return 1;
}

public OnPlayerEnterDynamicArea( playerid, areaid )
{
	new vehicleid = GetPlayerVehicleID( playerid );

    // races
   	new
   		raceid = p_raceLobbyId[ playerid ];

	if ( Iter_Contains( races, raceid ) && g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] == areaid && g_raceData[ raceid ] [ E_OUTRUN_LEAD ] != playerid )
	{
		// new leader
		g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = playerid;

		// alert
		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
			PlayerPlaySound( i, 1149, 0.0, 0.0, 0.0 );
			GameTextForPlayer( i, sprintf( "~b~~h~%s leading", ReturnPlayerName( playerid ) ), 2000, 3 );
			SendClientMessageFormatted( i, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has taken the lead for the race.", ReturnPlayerName( playerid ), playerid );
		}

		// see if ahead
		AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], vehicleid, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], vehicleid, 0.0, -OUTRUN_DIST - 5.0 );
	}
    return 1;
}

public OnPlayerEnterDynamicRaceCP( playerid, checkpointid )
{
	new raceid = p_raceLobbyId[ playerid ];

	static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;

	if ( checkpointid == p_PawnStoreExport[ playerid ] )
	{
	    new vehicleid = GetPlayerVehicleID( playerid );
	    if ( GetVehicleModel( vehicleid ) == 498 )
	    {
		    new
				szItems[ 18 ],
				cashEarned,
				items, score
			;
			format( szItems, sizeof( szItems ), "vburg_%d_items", vehicleid );
			for( new i; i < GetGVarInt( szItems ) + 1; i++ )
			{
				format( szSmallString, sizeof( szSmallString ), "vburg_%d_%d", vehicleid, i );
				if ( GetGVarInt( szSmallString ) != 0 )
				{
				    cashEarned += floatround( float( g_houseFurniture[ GetGVarInt( szSmallString ) ] [ E_COST ] ) * 0.5 );
				    DeleteGVar( szSmallString );
				}
			}
			items = GetGVarInt( szItems );
			score = floatround( items / 2 );
			GivePlayerScore( playerid, score == 0 ? 1 : score );
			//GivePlayerExperience( playerid, E_BURGLAR, float( items ) * 0.2 );
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = 0xFFFF;
			DestroyDynamicRaceCP( p_PawnStoreExport[ playerid ] );
			p_PawnStoreExport[ playerid ] = 0xFFFF;
			GivePlayerCash( playerid, cashEarned );
			GivePlayerWantedLevel( playerid, items * 2 );
			SendServerMessage( playerid, "You have sold %d furniture item(s) to the Pawn Store, earning you "COL_GOLD"%s"COL_WHITE".", GetGVarInt( szItems ), cash_format( cashEarned ) );
			DeleteGVar( szItems );
		}
		return 1;
	}

	else if( raceid != -1 && g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] == checkpointid )
	{
		if ( ! g_raceData[ raceid ] [ E_STARTED ] )
			return SendError( playerid, "The race has not started." );

		new
			position = ++ g_raceData[ raceid ] [ E_FINISHED_COUNT ];

		// give prize and alert
		if ( 1 <= position <= 3 )
			GivePlayerRaceWin( playerid, position, raceid );

		// close race after members finished
		new
			members = GetRaceMemberCount( raceid );

		// printf ("Position : %d, Members : %d", position, members);
		if ( position >= 3 || position >= members ) {
			DestroyRace( raceid );
			// print ("Shut race");
		}
		return 1;
	}
	// printf("Entered Race Checkpoint : {user:%s,veh:%d,biz_veh:%d,valid_biz:%d}", ReturnPlayerName( playerid ), iVehicle, g_isBusinessVehicle[ iVehicle ],Iter_Contains( business, g_isBusinessVehicle[ iVehicle ] ));
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn( playerid )
{
	// army limit
	/*if ( IsPlayerArmy( playerid ) )
	{
		static const ARMY_LIMIT = 15;

		new players = Iter_Count( Player );
		new army_limit = floatround( float( players ) / ARMY_LIMIT );
		new army_players = 0;

		// count army players
		foreach ( new armyid : Player ) if ( p_inArmy{ armyid } && armyid != playerid )
			army_players ++;

		if ( army_players >= army_limit ) {
			SendError( playerid, "Army is currently restricted to %d personnel. Need %d more players online for an additional slot.", army_limit, ( ( army_limit + 1 ) * ARMY_LIMIT ) - players );
			return 0;
		}
	}*/

	return approveClassSpawned( playerid );
}

stock approveClassSpawned( playerid ) {

	// is logged in
	if ( !p_PlayerLogged{ playerid } )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You must be authenticated to play the game." ), 0;

	// is verified
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You must be verified to play the game." ), 0;

	// is cop/army banned
	if ( p_CopBanned{ playerid } == MAX_CLASS_BAN_WARNS && ( IsPlayerPolice( playerid ) || IsPlayerFBI( playerid ) || IsPlayerCIA( playerid ) ) )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You are banned from using the police class(es). Use "COL_GREY"/unbanme"COL_WHITE" to pay for an unban." ), 0;

	if ( p_ArmyBanned{ playerid } == MAX_CLASS_BAN_WARNS && IsPlayerArmy( playerid ) )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You are banned from using the army class. Use "COL_GREY"/unbanme"COL_WHITE" to pay for an unban." ), 0;

	// wanted level an issue?
	if ( p_WantedLevel[ playerid ] > 0 && ( IsPlayerPolice( playerid ) || IsPlayerFBI( playerid ) || IsPlayerCIA( playerid ) || GetPlayerSkin( playerid ) == 287 ) )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You must not have a wanted level to use this class." ), 0;

	// get player total experience
	new Float: total_experience = GetPlayerTotalExperience( playerid );

	// bought xp
	if ( IsPlayerFBI( playerid ) && total_experience < 10000.0 )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You need 10,000 Total XP to use this class." ), 0;

	if ( IsPlayerArmy( playerid ) && total_experience < 20000.0 )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You need 20,000 Total XP to use this class." ), 0;

	if ( IsPlayerCIA( playerid ) && total_experience < 15000.0 )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You need 15,000 Total XP to use this class." ), 0;

	if ( IsPlayerFireman( playerid ) && total_experience < 1000.0 )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You need 1,000 Total XP to use this class." ), 0;

	if ( IsPlayerMedic( playerid ) && total_experience < 2000.0 )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You need 2,000 Total XP to use this class." ), 0;

	// job not set
	if ( !p_JobSet{ playerid } ) // || !p_CitySet{ playerid } )
		return SendClientMessage( playerid, -1, ""COL_RED"[ERROR]"COL_WHITE" You must ensure your job have been properly set." ), 0; // and city

	// hide textdraws
	for ( new i = 0; i < sizeof( CLASS_COLORS ); i ++ ) {
		TextDrawHideForPlayer( playerid, g_classTextdrawBox[ i ] );
		TextDrawHideForPlayer( playerid, g_classTextdrawDescription[ i ] );
		TextDrawHideForPlayer( playerid, g_classTextdrawName[ i ] );
	}
	TextDrawHideForPlayer( playerid, g_ClassBoxTD );
	RemovePlayerAttachedObject( playerid, 1 );
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text: clickedid)
{
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText: playertextid)
{
    return 1;
}

public OnPlayerPickUpDynamicPickup( playerid, pickupid )
{
	if ( pickupid != PreviousPickupID[ playerid ] )
	{
		new
			iTimestamp = g_iTime; // Call it once, because swag

		if ( LastPickupTimestamp[ playerid ] > iTimestamp )
		{
			new
				Float: distance = GetPlayerDistanceFromPoint( playerid, p_LastPickupPos[ playerid ] [ 0 ], p_LastPickupPos[ playerid ] [ 1 ], p_LastPickupPos[ playerid ] [ 2 ] );

			//if ( distance < 50.0 ) printf( "[AC WARN] Player ID %d has entered a pickup near him really fast. (distance: %0.2fm, time: %ds)", playerid, distance, LastPickupTimestamp[ playerid ] - iTimestamp );
			if ( distance > 50.0 )
			{
	        	SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for rapid pickup spam.", ReturnPlayerName( playerid ), playerid );
				BanEx( playerid, "Pickup Spam" );
				return 0;
			}
		}
		LastPickupTimestamp[ playerid ] = iTimestamp + 1;
		PreviousPickupID[ playerid ] = pickupid;
	}
	GetPlayerPos( playerid, p_LastPickupPos[ playerid ] [ 0 ], p_LastPickupPos[ playerid ] [ 1 ], p_LastPickupPos[ playerid ] [ 2 ] );
	return 1;
}

public OnVehicleMod( playerid, vehicleid, componentid )
{
	return 1;
}

public OnEnterExitModShop( playerid, enterexit, interiorid )
{
	return 1;
}

public OnVehiclePaintjob( playerid, vehicleid, paintjobid )
{
	// GivePlayerCash( playerid, -500 );
	return 1;
}

public OnVehicleRespray( playerid, vehicleid, color1, color2 )
{
	return 1;
}

public OnPlayerSelectedMenuRow( playerid, row )
{
	return 1;
}

public OnPlayerExitedMenu( playerid )
{
	return 1;
}

public OnPlayerInteriorChange( playerid, newinteriorid, oldinteriorid )
{
	if ( p_InHouse[ playerid ] == -1 && p_LastEnteredEntrance[ playerid ] != -1 && newinteriorid != 0 && oldinteriorid == 0 && p_Class[ playerid ] != CLASS_POLICE ) {

		if ( !IsPlayerInBank( playerid ) ) p_SafeHelperTimer[ playerid ] = SetTimerEx( "OnSafeHelperUpdate", 500, false, "dd", playerid, -1 );
		else
		{
			new
				iCity,
				iWorld = GetPlayerVirtualWorld( playerid )
			;

			for( iCity = 0; iCity < sizeof( g_bankvaultData ); iCity++ )
				if ( iWorld != 0 && iWorld == g_bankvaultData[ iCity ] [ E_WORLD ] )
					break;

			if ( g_bankvaultData[ iCity ] [ E_TIMESTAMP ] < g_iTime && !g_bankvaultData[ iCity ] [ E_DISABLED ] )
				ShowPlayerHelpDialog( playerid, 5000, "This ~g~~h~bank~w~~h~ is available for a heist." );
			else
				ShowPlayerHelpDialog( playerid, 5000, "This bank is ~r~~h~unavailable for a heist." );
		}
	}

	SyncSpectation( playerid );
	return 1;
}

function OnSafeHelperUpdate( playerid, robberyid )
{
	if ( robberyid == -1 )
	{
		p_SafeHelperTimer[ playerid ] = SetTimerEx( "OnSafeHelperUpdate", 500, false, "dd", playerid, getClosestRobberySafe( playerid ) );
		return 1;
	}

	new
		Float: distance = distanceFromSafe( playerid, robberyid )
	;

	if ( robberyid == INVALID_OBJECT_ID || distance > 100.0 || ! IsPlayerConnected( playerid ) || ! IsPlayerSpawned( playerid ) || IsPlayerInCasino( playerid ) || IsPlayerPlayingPool( playerid ) )
	{
		p_SafeHelperTimer[ playerid ] = -1;
		HidePlayerHelpDialog( playerid );
		return 0;
	}

	if ( g_robberyData[ robberyid ] [ E_ROBBED ] )
	{
		p_SafeHelperTimer[ playerid ] = -1;
		ShowPlayerHelpDialog( playerid, 5000, "This store currently is ~r~~h~unavailable for robbing.~w~~h~~n~~n~Come back later." );
		return 0;
	}

	if ( distance < 2.0 )
	{
		p_SafeHelperTimer[ playerid ] = -1;
		ShowPlayerHelpDialog( playerid, 7500, "Great, you've ~g~~h~found the safe.~w~~h~~n~~n~To rob the safe, hit ~r~~h~Left Alt~w~~h~ key." );
		return 1;
	}

	ShowPlayerHelpDialog( playerid, 0, "To rob the store, find the safe first.~n~~n~You're ~g~~h~%0.2fm~w~~h~ from the safe here.", distance );
	return ( p_SafeHelperTimer[ playerid ] = SetTimerEx( "OnSafeHelperUpdate", 500, false, "dd", playerid, robberyid ) );
}

public OnPlayerArrested( playerid, victimid, totalarrests, totalpeople )
{
	new
		iBefore = p_Arrests[ playerid ],
		iAfter 	= ( p_Arrests[ playerid ] += totalpeople )
	;

	Streak_IncrementPlayerStreak( playerid, STREAK_ARREST );

	if ( iBefore < 1000 && iAfter >= 1000 )	   ShowAchievement( playerid, "Arrested ~r~1000~w~~h~~h~ criminals!", 25 );
	else if ( iBefore < 500 && iAfter >= 500 ) ShowAchievement( playerid, "Arrested ~r~500~w~~h~~h~ criminals!", 18 );
	else if ( iBefore < 200 && iAfter >= 200 ) ShowAchievement( playerid, "Arrested ~r~200~w~~h~~h~ criminals!", 15 );
	else if ( iBefore < 100 && iAfter >= 100 ) ShowAchievement( playerid, "Arrested ~r~100~w~~h~~h~ criminals!", 12 );
	else if ( iBefore < 50  && iAfter >= 50 )  ShowAchievement( playerid, "Arrested ~r~50~w~~h~~h~ criminals!", 9 );
	else if ( iBefore < 20  && iAfter >= 20 )  ShowAchievement( playerid, "Arrested ~r~20~w~~h~~h~ criminals!", 6 );
	else if ( iBefore < 5   && iAfter >= 5 )   ShowAchievement( playerid, "Arrested ~r~5~w~~h~~h~ criminals!", 3 );
	return 1;
}

public OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	static
		Float: X, Float: Y, Float: Z, Float: Angle;

	new
 		iVehicle = GetPlayerVehicleID( playerid ),
		iWeapon = GetPlayerWeapon( playerid )
	;

	if ( HOLDING( KEY_SPRINT ) && HOLDING( KEY_WALK ) && IsPlayerUsingRadio( playerid ) )
		StopAudioStreamForPlayer( playerid );

    if ( PRESSED( KEY_JUMP ) && GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_CUFFED )
 		ApplyAnimation( playerid, "GYMNASIUM", "gym_jog_falloff", 4.1, 0, 1, 1, 0, 0 );

 	// Spectation
	if ( p_Spectating{ playerid } == true )
	{
		if ( PRESSED( KEY_WALK ) )
		{
			new spectatingid = p_whomSpectating[ playerid ];
			new targetid = p_PlayerAltBind[ playerid ];

			if ( targetid != -1 )
			{
				static
					Float: sX, Float: sY, Float: sZ;

				GetPlayerPos( spectatingid, sX, sY, sZ );
				GetPlayerPos( targetid, X, Y, Z );

				Angle = atan2( sY - Y, sX - X ) - 90.0;

				if ( Angle == -90.0 ) {
					SendError( playerid, "You have not set the aiming alt-binded player properly." );
				} else {
					SendServerMessage( playerid, "Played moved %0.2f degrees from fighting positions.", Angle );
				}

			    X += 4.0 * floatsin( Angle + 90.0, degrees );
			    Y += 4.0 * -floatcos( Angle + 90.0, degrees );

				SetPlayerPos( targetid, X, Y, Z );
				p_PlayerAltBindTick[ targetid ] = GetTickCount( );
			}
		}

	    if ( PRESSED( KEY_FIRE ) )
	    {
			for( new i = p_whomSpectating[ playerid ] + 1; i < MAX_PLAYERS; i++ )
			{
				if ( IsPlayerConnected( i ) && IsPlayerSpawned( i ) && !p_Spectating{ i } && i != playerid )
				{
					ForceSpectateOnPlayer( playerid, i );
					break;
				}
			}
	    }
	    else if ( PRESSED( KEY_AIM ) )
	    {
			for( new i = p_whomSpectating[ playerid ] - 1; i > -1; i-- )
			{
				if ( IsPlayerConnected( i ) && IsPlayerSpawned( i ) && !p_Spectating{ i } && i != playerid )
				{
					ForceSpectateOnPlayer( playerid, i );
					break;
				}
			}
	    }
	    return 1;
	}

 	// Explosive Bullets
 	if ( p_ExplosiveBullets[ playerid ] > 0 && PRESSED( KEY_NO ) ) {
 		if ( GetPVarInt( playerid, "explosive_rounds" ) == 1 ) {
 			DeletePVar( playerid, "explosive_rounds" );
 			ShowPlayerHelpDialog( playerid, 2000, "Explosive rounds ~r~disabled." );
 		} else {
 			SetPVarInt( playerid, "explosive_rounds", 1 );
 			ShowPlayerHelpDialog( playerid, 2000, "Explosive rounds ~r~enabled." );
 		}
 	}

	// Hunter Kill Detection
	if ( iVehicle && IsValidVehicle( iVehicle ) )
	{
		new
			modelid = GetVehicleModel( iVehicle );

		if ( ( modelid == 425 && ( HOLDING( KEY_ACTION ) || PRESSED( KEY_FIRE ) ) ) || ( ( modelid == 520 || modelid == 447 || modelid == 476 ) && HOLDING( KEY_ACTION ) ) )
		{
			new
				closest_vehicle = GetClosestVehicle( playerid, iVehicle );

			if ( closest_vehicle != INVALID_VEHICLE_ID )
			{
				static
					Float: tX, Float: tY, Float: tZ;

				GetVehiclePos( iVehicle, X, Y, Z );
				GetVehiclePos( closest_vehicle, tX, tY, tZ );

				if ( VectorSize( tX - X, tY - Y, tZ - Z ) < 80.0 )
				{
					new
						Float: facingAngle,
						Float: angle = atan2( tY - Y, tX - X ) - 90.0
					;

					// addresses a small bug
					if ( angle < 0.0 )
						angle += 360.0;

					GetVehicleZAngle( iVehicle, facingAngle );

					// check if player is facing vehicle
					if ( floatabs( facingAngle - angle ) < 17.5 ) { // 15m radius

						g_VehicleLastAttacker[ closest_vehicle ] = playerid;
						g_VehicleLastAttacked[ closest_vehicle ] = g_iTime;

						// anticipate a kill in the vehicle too
						foreach (new i : Player) if ( GetPlayerVehicleID( i ) == closest_vehicle )
						{
							// give wanted to attacking people (attackers of leo)
							if ( p_Class[ playerid ] != CLASS_POLICE && p_WantedLevel[ playerid ] < 6 && p_Class[ i ] == CLASS_POLICE ) {
								GivePlayerWantedLevel( playerid, 6 - p_WantedLevel[ playerid ] );
							}

							#if defined AC_INCLUDED
								// prevent team kills
								if ( p_Class[ playerid ] != CLASS_POLICE && p_Class[ i ] != CLASS_POLICE ) {
									AC_UpdateDamageInformation( i, playerid, PRESSED( KEY_FIRE ) ? 51 : 38 );
								}
							#endif
						}

						// debug
						// printf("Player is shooting vehicle ... %d (%s)", iVehicle, PRESSED( KEY_FIRE ) ? ("rocket") : ("lmg"));
					}
				}
			}
		}
	}

	// Various keys
	if ( PRESSED( KEY_FIRE ) )
	{
		if ( IsPlayerAttachedObjectSlotUsed( playerid, 3 ) ) return RemovePlayerStolensFromHands( playerid ), SendServerMessage( playerid, "You dropped your stolen good and broke it." ), 1;
   	}

   	else if ( PRESSED( KEY_YES ) )
   	{
	    if ( p_Class[ playerid ] == CLASS_CIVILIAN && IsPlayerJob( playerid, JOB_TERRORIST ) && !IsPlayerJailed( playerid ) )
	   		ExplodePlayerC4s( playerid );
   	}

 	else if ( PRESSED( KEY_NO ) )
 	{
 		// Press N to deatach trailer from vehicle
 		if ( iVehicle && IsTrailerAttachedToVehicle( iVehicle ) )
 			DetachTrailerFromVehicle( iVehicle );
 	}

	else if ( PRESSED( KEY_ACTION ) )
	{
		if ( IsPlayerInAnyVehicle( playerid ) && GetPlayerState( playerid ) == PLAYER_STATE_DRIVER && GetVehicleModel( iVehicle ) == 525 ) {
			new
				Float: pX, Float: pY, Float: pZ, Float: pAngle
			;

			GetVehiclePos( iVehicle, pX, pY, pZ );
			GetVehicleZAngle( iVehicle, pAngle );

			pX += 2.0 * floatsin( pAngle, degrees );
			pY += 2.0 * floatcos( pAngle, degrees );

			if ( !IsTrailerAttachedToVehicle( iVehicle ) ) {
				for( new i = 0; i < MAX_VEHICLES; i++ ) if ( IsValidVehicle( i ) && i != iVehicle ) {
					if ( GetVehicleDistanceFromPoint( i, pX, pY, pZ ) < 7.0 ) {
						AttachTrailerToVehicle( i, iVehicle );
						break;
					}
				}
			} else {
				DetachTrailerFromVehicle( iVehicle );
			}
		}
	}

	else if ( PRESSED( KEY_SECONDARY_ATTACK ) )
	{
		if ( GetPVarInt( playerid, "viewing_houseints" ) == 1 )
		{
			new id = p_InHouse[ playerid ];
			SendServerMessage( playerid, "You've stopped viewing the house interior." );
			SetPlayerPos( playerid, g_houseData[ id ] [ E_TX ], g_houseData[ id ] [ E_TY ], g_houseData[ id ] [ E_TZ ] );
			SetPlayerInterior( playerid, g_houseData[ id ] [ E_INTERIOR_ID ] );
		    DeletePVar( playerid, "viewing_houseints" );
			TogglePlayerControllable( playerid, 1 );
			SetCameraBehindPlayer( playerid );
			return 1;
		}

		if ( g_iTime > p_CheckpointEnterTick[ playerid ] && !p_pausedToLoad{ playerid } && !IsPlayerTied( playerid ) )
		{
		  	p_CheckpointEnterTick[ playerid ] = g_iTime + 2;

	    	// Enter Shamal Interior
	    	if ( IsPlayerInShamal( playerid ) )
	    	{
	    		if ( IsPlayerInRangeOfPoint( playerid, 10.0, 1322.6577, 1992.5508, 1200.2574 ) )
	    		{
	    			new
	    				vehicleid = GetPlayerVirtualWorld( playerid ) - VW_SHAMAL
	    			;

	    			if ( IsValidVehicle( vehicleid ) )
	    			{
		                GetVehiclePos( vehicleid, X, Y, Z );
		                GetVehicleZAngle( vehicleid, Angle );

		                X += ( 3.2 * floatsin( -( Angle - 45.0 ), degrees ) );
		                Y += ( 3.2 * floatcos( -( Angle - 45.0 ), degrees ) );

		                SetPlayerInterior( playerid, 0 );
		                SetPlayerVirtualWorld( playerid, 0 );
		                SetPlayerFacingAngle( playerid, Angle );
		                SetPlayerPos( playerid, X, Y, Z - 1 );

			        	pauseToLoad( playerid );
	    			}
	    		}
	    	}

	    	// Call Elevator Down
		    if ( ! iVehicle )
		    {
				if ( IsPlayerInArea( playerid, -2005.859375, -1917.968750, 1339.843750, 1396.484375 ) && GetPlayerInterior( playerid ) == 0 )
				{
					GetDynamicObjectPos( g_apartmentElevator, X, Y, Z );
					if ( IsPlayerInRangeOfPoint( playerid, 2.0, X, Y, Z ) )
					{
						ClearAnimations( playerid ); // clear-fix

					    if ( IsDynamicObjectMoving( g_apartmentElevator ) )
					        return SendError( playerid, "You must wait for the elevator to stop operating to select a floor again." );

		                szLargeString[ 0 ] = '\0';
		                strins( szLargeString, "Ground Floor\n", 0 );
		                for( new i; i < sizeof( g_apartmentData ); i++ ) // First floor
		                {
		                    if ( g_apartmentData[ i ] [ E_CREATED ] )
		                    	format( szLargeString, sizeof( szLargeString ), "%s%s - %s\n", szLargeString, g_apartmentData[ i ] [ E_OWNER ], g_apartmentData[ i ] [ E_NAME ] );
							else
							    strcat( szLargeString, "$5,000,000 - Available For Purchase!\n" );
						}

						ShowPlayerDialog( playerid, DIALOG_APARTMENTS, DIALOG_STYLE_LIST, "{FFFFFF}Apartments", szLargeString, "Select", "Cancel" );
						return 1;
					}

					for( new floors; floors < MAX_AFLOORS; floors++ )
					{
						GetDynamicObjectPos( g_apartmentElevatorDoor1[ floors ], X, Y, Z );
	                	if ( IsPlayerInRangeOfPoint( playerid, 4.0, X, Y, Z ) )
	                	{
							ClearAnimations( playerid ); // clear-fix
						    if ( IsDynamicObjectMoving( g_apartmentElevator ) ) {
			       				SendError( playerid, "The elevator is operating, please wait." );
			       				break;
							}

		    				PlayerPlaySound( playerid, 1085, 0.0, 0.0, 0.0 );
							apartment_CallElevator( floors ); // First floor
							break;
	                	}
					}
					return 1;
				}

			}
		}
	}

	else if ( HOLDING( KEY_AIM ) )
	{
	  	if ( IsPlayerAttachedObjectSlotUsed( playerid, 1 ) && iWeapon == WEAPON_SNIPER )
	 		RemovePlayerAttachedObject( playerid, 1 );
	}

	// taze mechanism
	else if ( PRESSED( KEY_LOOK_BEHIND ) )
	{
		if ( p_Class[ playerid ] == CLASS_POLICE && !p_AntiSpawnKillEnabled{ playerid } )
		{
			new
				closestid = GetClosestPlayer( playerid );

			if ( closestid != INVALID_PLAYER_ID && p_Class[ closestid ] != CLASS_POLICE && ! ( GetDistanceBetweenPlayers( playerid, closestid ) > 10.0 || !IsPlayerConnected( closestid ) ) ) {
				if ( p_WantedLevel[ closestid ] > 5 ) {
					if ( IsPlayerCuffed( closestid ) ) ArrestPlayer( closestid, playerid );
					else if ( IsPlayerTazed( closestid ) ) CuffPlayer( closestid, playerid );
					else TazePlayer( closestid, playerid );
				} else {
					TicketPlayer( closestid, playerid );
				}
			}
		}


		// MMB to open gate
		new
			Float: gate_distance = 99999.9,
			gate_id = getClosestGate( playerid, gate_distance )
		;

		if ( gate_id != INVALID_OBJECT_ID && gate_distance < g_gateData[ gate_id ] [ E_RANGE ] )
		{
			new
				gangId = p_GangID[ playerid ];

			if ( p_AdminLevel[ playerid ] >= 5 || g_gateData[ gate_id ] [ E_OWNER ] == p_AccountID[ playerid ] || ( Iter_Contains( gangs, gangId ) && g_gateData[ gate_id ] [ E_GANG_SQL_ID ] == g_gangData[ gangId ] [ E_SQL_ID ] ) ) {
				OpenPlayerGate( playerid, gate_id );
			}
		}
	}
	return 1;
}

stock pauseToLoad( playerid )
{
	p_pausedToLoad{ playerid } = true;
	KillTimer( p_pausedToLoadTimer[ playerid ] );
	TogglePlayerControllable( playerid, 0 );
	TextDrawShowForPlayer(playerid, g_ObjectLoadTD);

	p_pausedToLoadTimer[ playerid ] = SetTimerEx( "unpause_Player", 3000, false, "d", playerid );
	return 1;
}

function unpause_Player( playerid )
{
	p_pausedToLoad{ playerid } = false;
	if ( !IsPlayerTied( playerid ) || !IsPlayerTazed( playerid ) ) TogglePlayerControllable( playerid, 1 );
	TextDrawHideForPlayer(playerid, g_ObjectLoadTD);
	return KillTimer( p_pausedToLoadTimer[ playerid ] ), 1;
}

#if defined AC_INCLUDED
	public OnPlayerCheatDetected( playerid, detection, params )
	{
		if ( detection == CHEAT_TYPE_REMOTE_JACK )
		{
	        if ( GetPlayerScore( playerid ) < 200 )
	        {
				SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been kicked for abnormally jacking vehicles.", ReturnPlayerName( playerid ), playerid );
				SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL JACKING]"COL_GREY" %s(%d) - %d score - %d ping - %s IP", ReturnPlayerName( playerid ), playerid, GetPlayerScore( playerid ), GetPlayerPing( playerid ), ReturnPlayerIP( playerid ) );
	        	return Kick( playerid ), 1;
			}
			SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL JACKING]"COL_GREY" %s(%d) is a suspect of jacking vehicles abnormally.", ReturnPlayerName( playerid ), playerid );
		}
		else if ( detection == CHEAT_TYPE_RAPIDFIRE )
		{
			SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been kicked for rapid-firing.", ReturnPlayerName( playerid ), playerid );
		 	Kick( playerid );
		}
		else if ( detection == CHEAT_TYPE_FAKEKILL )
		{
			SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for fake-killing.", ReturnPlayerName( playerid ), playerid );
			BanEx( playerid, "Fake-kill" );
		}
		else if ( detection == CHEAT_TYPE_CARWARP )
		{
			if ( ! GetPlayerAdminLevel( playerid ) )
			{
	        	SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for car warping.", ReturnPlayerName( playerid ), playerid );
				BanEx( playerid, "Car Warp" );
			}
		}
		else if ( detection == CHEAT_TYPE_AIRBRAKE )
		{
			//SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for airbraking.", ReturnPlayerName( playerid ), playerid );
			//AdvancedBan( playerid, "Server", "Airbrake", ReturnPlayerIP( playerid ) );
			SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL MOVEMENT]"COL_GREY" %s(%d) has been detected for airbrake.", ReturnPlayerName( playerid ), playerid );
		}
		else if ( detection == CHEAT_TYPE_FLYHACKS )
		{
			SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL MOVEMENT]"COL_GREY" %s(%d) has been detected for fly hacks.", ReturnPlayerName( playerid ), playerid );
			// SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for fly hacks.", ReturnPlayerName( playerid ), playerid );
			// AdvancedBan( playerid, "Server", "Fly Hacks", ReturnPlayerIP( playerid ) );
		}
		else if ( detection == CHEAT_TYPE_WEAPON )
		{
			SendClientMessageToAdmins( -1, ""COL_PINK"[ANTI-CHEAT]"COL_GREY" %s(%d) has been detected for weapon hack (%s).", ReturnPlayerName( playerid ), playerid, ReturnWeaponName( params ) );
		}
		else
		{
			SendClientMessageToAdmins( -1, ""COL_PINK"[ANTI-CHEAT]"COL_GREY" %s(%d) has been detected for %s.", ReturnPlayerName( playerid ), playerid, AC_DetectedCheatToString( detection ) );
		}
		return 1;
	}
#endif

public OnPlayerUpdate( playerid )
{
	if ( !p_PlayerLogged{ playerid } )
		return 0;

	static
		Float: X, 	Float: Y, 	Float: Z,
		Float: vX, 	Float: vY, 	Float: vZ,

		iKeys, iLeftRight, iState
	;

	if ( g_iTime < p_DesyncTime[ playerid ] )
		return 0; // Desync Feature

	GetPlayerKeys( playerid, iKeys, tmpVariable, iLeftRight );
	p_AFKTime[ playerid ] = GetTickCount( );

	// Disable Driveby
	if ( !g_Driveby )
	{
		iState = GetPlayerState( playerid );
		if ( iState == PLAYER_STATE_DRIVER ) {
			SetPlayerArmedWeapon( playerid, 0 );
		}
	}

	// Duffel Bug And Sniper Bug
	if ( !( iKeys & KEY_AIM ) && !IsPlayerAttachedObjectSlotUsed( playerid, 1 ) && p_MoneyBag{ playerid } ) {
		//SetPlayerAttachedObject( playerid, 1, 1550, 1, 0.131999, -0.140999, 0.053999, 11.299997, 65.599906, 173.900054, 0.652000, 0.573000, 0.594000 );
		SetPlayerAttachedObject( playerid, 1, 1210, 7, 0.302650, -0.002469, -0.193321, 296.124053, 270.396881, 8.941717, 1.000000, 1.000000, 1.000000 );
	}

    // Fugga.cs
	GetPlayerVelocity( playerid, vX, vY, vZ );
	if ( ( ( vX < -10.0 || vX > 10.0 ) && ( vZ > 1.0 || vZ < -1.0 ) ) || ( ( vX < -3.0 || vX > 3.0 ) && ( vY < -3.0 || vY > 3.0 ) && ( vZ > 3.0 || vZ < -3.0 ) ) )
	{
    	//SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for player swinging.", ReturnPlayerName( playerid ), playerid );
		//BanEx( playerid, "Player Swing" );
		p_DesyncTime[ playerid ] = g_iTime + 3;
		return 0;
	}

    // PlayerBugger.cs
	GetPlayerPos( playerid, X, Y, Z );
	if ( X >= 99999.0 || Y >= 99999.0 || Z >= 99999.0 || X <= -99999.0 || Y <= -99999.0 || Z <= -99999.0 ) {
	  	SendClientMessage( playerid, 0xa9c4e4ff, "Warning: Excessive X, Y, Z has been breached thus last location set." );
		SetPlayerPos( playerid, p_PlayerBuggerX[ playerid ], p_PlayerBuggerY[ playerid ], p_PlayerBuggerZ[ playerid ] );
	}
	else
	{
	    p_PlayerBuggerX[ playerid ] = X;
	    p_PlayerBuggerY[ playerid ] = Y;
	    p_PlayerBuggerZ[ playerid ] = Z;
	}

	if ( IsPlayerInAnyVehicle( playerid ) && GetPlayerState( playerid ) == PLAYER_STATE_DRIVER )
	{
		GetPlayerPos( playerid, X, Y, Z );
  		GetVehicleVelocity( GetPlayerVehicleID( playerid ), vX, vY, vZ );
		if ( ( vX > 3.0 || vY > 3.0 || vZ > 3.0 || vX < -3.0 || vY < -3.0 || vZ < -3.0 ) && ( vX != X && vY != Y && vZ != Z ) )
		{
        	//SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for car swinging.", ReturnPlayerName( playerid ), playerid );
			//BanEx( playerid, "Car Swing" );
			p_DesyncTime[ playerid ] = g_iTime + 3;
			return 0;
		}
	}
	return fix_NightThermalVisionHack( playerid );
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

/*public AC_OnImgFileModifed( playerid, filename[ ], md5[ ] ) {
	format( szNormalString, sizeof( szNormalString ), "[ANTI-CHEAT]{FFFFFF} %s(%d) modified an img file: "COL_GREY"%s", ReturnPlayerName( playerid ), playerid, filename );
	SendClientMessageToAdmins( COLOR_PINK, szNormalString );
	return 1;
}

public AC_OnFileCalculated( playerid, filename[ ], md5[ ], bool: isCheat )
{
	if ( isCheat ) {
		format( szNormalString, sizeof( szNormalString ), "[ANTI-CHEAT]{FFFFFF} %s(%d) executed a blacklisted file: "COL_GREY"%s", ReturnPlayerName( playerid ), playerid, filename );
		SendClientMessageToAdmins( COLOR_PINK, szNormalString );
	}
	return 1;
}*/

thread OnAttemptPlayerLogin( playerid, password[ ] )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szHashed[ 129 ],
    		szPassword[ 129 ],
    		szSalt[ 25 ],
    		bool: isSalted = false
    	;

		cache_get_field_content( 0,  "SALT", szSalt );
		cache_get_field_content( 0,  "PASSWORD", szPassword );

		if ( !strcmp( szSalt, "NULL", false ) ) // User doesn't have a salt
		{
			WP_Hash( szHashed, sizeof( szHashed ), password );
			isSalted = false;
		}
		else
		{
			pencrypt( szHashed, sizeof( szHashed ), password, szSalt );
			isSalted = true;
		}

		if ( ! strcmp( szHashed, szPassword, false ) )
    	{
    		if ( !isSalted ) // Converting from insecure to secure
    		{
             	randomString( szSalt, 24 );
             	pencrypt( szHashed, sizeof( szHashed ), password, szSalt );

    			format( szBigString, sizeof( szBigString ), "UPDATE USERS SET `PASSWORD`='%s', `SALT`='%s' WHERE `NAME`='%s'", szHashed, mysql_escape( szSalt ), ReturnPlayerName( playerid ) );
    			mysql_single_query( szBigString );
    		}

    		p_AccountID[ playerid ] = cache_get_field_content_int( 0, "ID", dbHandle );

			new iScore 		= cache_get_field_content_int( 0, "SCORE", dbHandle );
			new iCash 		= cache_get_field_content_int( 0, "CASH", dbHandle );
			new iFightStyle = cache_get_field_content_int( 0, "FIGHTSTYLE", dbHandle );
			new iWanted 	= cache_get_field_content_int( 0, "WANTEDLVL", dbHandle );

			SetPlayerCash			( playerid, iCash );
			SetPlayerScore			( playerid, iScore );
			SetPlayerFightingStyle	( playerid, iFightStyle );
			GivePlayerWantedLevel	( playerid, iWanted, true );

			p_AdminLevel[ playerid ] 		= cache_get_field_content_int( 0, "ADMINLEVEL", dbHandle );
			p_BankMoney[ playerid ] 		= cache_get_field_content_int( 0, "BANKMONEY", dbHandle );
			p_Kills[ playerid ] 			= cache_get_field_content_int( 0, "KILLS", dbHandle );
			p_Deaths[ playerid ] 			= cache_get_field_content_int( 0, "DEATHS", dbHandle );
			p_VIPLevel[ playerid ] 			= cache_get_field_content_int( 0, "VIP_PACKAGE", dbHandle );
			//p_XP[ playerid ] 				= cache_get_field_content_int( 0, "XP", dbHandle );
			p_VIPExpiretime[ playerid ] 	= cache_get_field_content_int( 0, "VIP_EXPIRE", dbHandle );
			p_LastSkin[ playerid ] 			= cache_get_field_content_int( 0, "LAST_SKIN", dbHandle );
			p_Burglaries[ playerid ] 		= cache_get_field_content_int( 0, "BURGLARIES", dbHandle );
			p_CopBanned{ playerid } 		= cache_get_field_content_int( 0, "COP_BAN", dbHandle );
			p_ArmyBanned{ playerid } 		= cache_get_field_content_int( 0, "ARMY_BAN", dbHandle );
			p_Uptime[ playerid ] 			= cache_get_field_content_int( 0, "UPTIME", dbHandle );
			p_Arrests[ playerid ] 			= cache_get_field_content_int( 0, "ARRESTS", dbHandle );
			p_VIPWep1{ playerid } 			= cache_get_field_content_int( 0, "VIPWEP1", dbHandle );
			p_VIPWep2{ playerid } 			= cache_get_field_content_int( 0, "VIPWEP2", dbHandle );
			p_VIPWep3{ playerid } 			= cache_get_field_content_int( 0, "VIPWEP3", dbHandle );
			p_MutedTime[ playerid ] 		= cache_get_field_content_int( 0, "MUTE_TIME", dbHandle );
			p_Robberies[ playerid ] 		= cache_get_field_content_int( 0, "ROBBERIES", dbHandle );
			p_Fires[ playerid ] 			= cache_get_field_content_int( 0, "FIRES", dbHandle );
			p_PingImmunity{ playerid } 		= cache_get_field_content_int( 0, "PING_IMMUNE", dbHandle );
			p_HitsComplete[ playerid ] 		= cache_get_field_content_int( 0, "CONTRACTS", dbHandle );
			p_TruckedCargo[ playerid ] 		= cache_get_field_content_int( 0, "TRUCKED", dbHandle );
			p_PilotMissions[ playerid ] 	= cache_get_field_content_int( 0, "PILOT", dbHandle );
			p_TrainMissions[ playerid ] 	= cache_get_field_content_int( 0, "TRAIN", dbHandle );
			//p_CopTutorial{ playerid } 		= cache_get_field_content_int( 0, "COP_TUTORIAL", dbHandle );
			p_Job{ playerid } 				= cache_get_field_content_int( 0, "JOB", dbHandle );
			p_VIPJob{ playerid } 			= cache_get_field_content_int( 0, "VIP_JOB", dbHandle );
			p_AdminJailed{ playerid } 		= cache_get_field_content_int( 0, "JAIL_ADMIN", dbHandle );
			p_JailTime[ playerid ] 			= cache_get_field_content_int( 0, "JAIL_TIME", dbHandle );
			p_Ropes[ playerid ] 			= cache_get_field_content_int( 0, "ROPES", dbHandle );
			p_C4Amount[ playerid ] 			= cache_get_field_content_int( 0, "C4", dbHandle );
			p_MetalMelter[ playerid ] 		= cache_get_field_content_int( 0, "MELTERS", dbHandle );
			p_Scissors[ playerid ] 			= cache_get_field_content_int( 0, "SCISSORS", dbHandle );
			p_AntiEMP[ playerid ] 			= cache_get_field_content_int( 0, "FOILS", dbHandle );
			p_BobbyPins[ playerid ] 		= cache_get_field_content_int( 0, "PINS", dbHandle );
			p_ContractedAmount[ playerid ] 	= cache_get_field_content_int( 0, "BOUNTY", dbHandle );
			p_WeedGrams[ playerid ] 		= cache_get_field_content_int( 0, "WEED", dbHandle );
			p_SpawningCity{ playerid } 		= cache_get_field_content_int( 0, "CITY", dbHandle );
			p_Methamphetamine{ playerid }	= cache_get_field_content_int( 0, "METH", dbHandle );
			p_CausticSoda{ playerid } 		= cache_get_field_content_int( 0, "SODA", dbHandle );
			p_MuriaticAcid{ playerid } 		= cache_get_field_content_int( 0, "ACID", dbHandle );
			p_HydrogenChloride{ playerid } 	= cache_get_field_content_int( 0, "GAS", dbHandle );
			p_LeftCuffed{ playerid } 		= !!cache_get_field_content_int( 0, "IS_CUFFED", dbHandle );
			p_JailsBlown[ playerid ] 		= cache_get_field_content_int( 0, "BLEW_JAILS", dbHandle );
			p_BankBlown[ playerid ] 		= cache_get_field_content_int( 0, "BLEW_VAULT", dbHandle );
			p_CarsJacked[ playerid ] 		= cache_get_field_content_int( 0, "VEHICLES_JACKED", dbHandle );
			p_MethYielded[ playerid ] 		= cache_get_field_content_int( 0, "METH_YIELDED", dbHandle );
			p_drillStrength[ playerid ] 	= cache_get_field_content_int( 0, "DRILL", dbHandle );
			p_IrresistibleCoins[ playerid ] = cache_get_field_content_float( 0, "COINS", dbHandle );
			p_ExtraAssetSlots{ playerid }	= cache_get_field_content_int( 0, "EXTRA_SLOTS", dbHandle );
			p_forcedAnticheat[ playerid ] 	= cache_get_field_content_int( 0, "FORCE_AC", dbHandle );

			p_CasinoRewardsPoints[ playerid ] = cache_get_field_content_float( 0, "CASINO_REWARDS", dbHandle );
			p_IsCasinoHighRoller{ playerid } = !!cache_get_field_content_int( 0, "VISAGE_HIGHROLLER", dbHandle );
			p_Fireworks[ playerid ] = cache_get_field_content_int( 0, "FIREWORKS", dbHandle );
			p_ExplosiveBullets[ playerid ] = cache_get_field_content_int( 0, "EXPLOSIVE_BULLETS", dbHandle );
			p_AddedEmail{ playerid } = !!cache_get_field_content_int( 0, "USED_EMAIL", dbHandle );
			// p_TaxTime[ playerid ] = cache_get_field_content_int( 0, "TAX_TIME", dbHandle );

			// seasonal xp
			SetPlayerSeasonalXP( playerid, cache_get_field_content_float( 0, "RANK", dbHandle ) );

			// spawn location
			new
				spawn_location[ 10 ];

			cache_get_field_content( 0, "SPAWN", spawn_location, dbHandle, sizeof( spawn_location ) );

			if ( ismysqlnull( spawn_location ) || sscanf( spawn_location, "s[4]d", p_SpawningKey[ playerid ], p_SpawningIndex[ playerid ] ) ) {
				p_SpawningKey[ playerid ] [ 0 ] = '\0', p_SpawningIndex[ playerid ] = 0;
			}

			// anti-cheat
			if ( p_forcedAnticheat[ playerid ] > 0 && ! IsPlayerUsingSampAC( playerid ) ) {
				SendError( playerid, "You must install an anticheat to play the server. Visit "COL_GREY""AC_WEBSITE""COL_WHITE" to install the anticheat." );
				KickPlayerTimed( playerid );
				return 1;
			}

			// highroller object
			if ( p_IsCasinoHighRoller{ playerid } ) {
				DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 0 ] ), p_HighrollersBarrier[ playerid ] [ 0 ] = -1;
				DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 1 ] ), p_HighrollersBarrier[ playerid ] [ 1 ] = -1;
			}

			// Load some other variables too
		   	p_OwnedHouses 		[ playerid ] = GetPlayerOwnedHouses( playerid );
		   	p_OwnedBusinesses 	[ playerid ] = GetPlayerOwnedBusinesses( playerid );

		    p_PlayerLogged	{ playerid } = true;
			p_JobSet 		{ playerid } = true;
			// p_CitySet 	{ playerid } = true;
			p_Muted 		{ playerid } = p_MutedTime[ playerid ] > 0 ? true : false; // Save muting :X

			// Check if vip expired
			CheckPlayerVipExpiry( playerid );

			// Load other player related variables
			CallLocalFunction( "OnPlayerLogin", "d", playerid );

			// Load some more linking tables
			format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `EMAILS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
			mysql_function_query( dbHandle, szNormalString, true, "OnEmailLoad", "d", playerid );

			format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `VEHICLES` WHERE `OWNER`=%d", p_AccountID[ playerid ] );
			mysql_function_query( dbHandle, szNormalString, true, "OnVehicleLoad", "d", playerid );

			if ( p_VIPLevel[ playerid ] ) {
				format( szBigString, 192, "SELECT `ID` FROM `NOTES` WHERE (`NOTE` LIKE '{FFDC2E}%%' OR `NOTE` LIKE '{CD7F32}%%') AND `USER_ID`=%d AND `DELETED` IS NULL", p_AccountID[ playerid ] );
				mysql_function_query( dbHandle, szBigString, true, "checkforvipnotes", "d", playerid );
			}

			// Player is online
			mysql_single_query( sprintf( "UPDATE `USERS` SET `ONLINE`=1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );

			// Log in player
		  	SendServerMessage( playerid, "You have " COL_GREEN "successfully" COL_WHITE " logged in!" );

		  	// UNDERCOVER USERS
			/*if ( IsPlayerUnderCover( playerid ) ) {
		  		// all undercover are american ips
				format( p_PlayerIP[ playerid ], 16, "187.237.240.%d", random( 255 ) );
		  	}*/

		  	// Search for valid gang
			new gang_sql = cache_get_field_content_int( 0, "GANG_ID", dbHandle );
		  	new bool: foundGang = false;

		  	// Reset gang id just incase
		  	p_GangID[ playerid ] = INVALID_GANG_ID;

		  	// Search all gangs for the SQL
			printf("[%s] Reading gang id %d", ReturnPlayerName( playerid ), gang_sql );
		  	if ( gang_sql ) {
				foreach (new g : gangs) if( gang_sql == g_gangData[ g ] [ E_SQL_ID ] ) {
					p_GangID[ playerid ] = g, foundGang = true;
					break;
				}
			}

			printf("[%s] Found gang ? %s , id %d, gangid %d", ReturnPlayerName( playerid ), foundGang ? ("YES") : ("NO"), p_GangID[ playerid ], gang_sql );

			if ( ! foundGang ) {
				format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `GANGS` WHERE `LEADER`=%d OR `ID`=%d LIMIT 0,1", p_AccountID[ playerid ], gang_sql );
				mysql_function_query( dbHandle, szNormalString, true, "OnPlayerGangLoaded", "d", playerid );
			}

		  	// Send gang join message
		  	if ( p_GangID[ playerid ] != INVALID_GANG_ID && strlen( g_gangData[ p_GangID[ playerid ] ] [ E_JOIN_MSG ] ) ) {
		  		SendClientMessageFormatted( playerid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]"COL_GREY" %s", g_gangData[ p_GangID[ playerid ] ] [ E_JOIN_MSG ] );
		  	}
		}
	    else
	    {
	        p_IncorrectLogins{ playerid } ++;
	        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_RED"Wrong password! Try again! [%d/3]\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ), p_IncorrectLogins{ playerid } );
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
    	Kick( playerid );
    	printf( "User::Error - User Not Created Attempting Login" );
    }
	return 1;
}

thread OnPlayerRegister( playerid )
{
	p_AccountID[ playerid ]		= cache_insert_id( );
	return 1;
}

stock pencrypt( szLeFinale[ ], iSize = sizeof( szLeFinale ), szPassword[ ], szSalt[ 25 ], iPepper = 24713018, szCost[ 3 ] = "2y" )
{
	static
    	szHash[ 256 ];

    WP_Hash( szHash, sizeof( szHash ), szPassword );

    format( szHash, sizeof( szHash ), "%s%d%s$%s$", szSalt, iPepper, szHash, szCost );
    WP_Hash( szLeFinale, iSize, szHash );
}

stock randomString(strDest[], strLen = 10)
{
    while(strLen--)
        strDest[strLen] = random(2) ? (random(26) + (random(2) ? 'a' : 'A')) : (random(10) + '0');
}

public OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    new
        Query[ 256 ],
        szBigQuery[ 764 ]
    ;

	if ( g_DialogLogging ) printf( "[DIALOG_LOG] %s(%d) - %d, %d, %d, %s", ReturnPlayerName( playerid ), playerid, dialogid, response, listitem, inputtext );

    if ( dialogid == DIALOG_LOGIN )
    {
        if ( response )
        {
        	if ( p_PlayerLogged{ playerid } )
        	{
        		AdvancedBan( playerid, "Server", "Exploiting", ReturnPlayerIP( playerid ) );
        		return SendError( playerid, "You are already logged in!" );
        	}

			format( szBigQuery, sizeof( szBigQuery ), "SELECT * FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( ReturnPlayerName( playerid ) ) );
       		mysql_function_query( dbHandle, szBigQuery, true, "OnAttemptPlayerLogin", "ds", playerid, inputtext );
        }
        else return ShowPlayerDialog( playerid, DIALOG_LOGIN_QUIT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Account - Authentication", "{FFFFFF}Are you sure you want to leave the server?", "Yes", "No" );
    }
    if ( dialogid == DIALOG_LOGIN_QUIT ) {
    	if ( response ) {
    		return Kick( playerid );
    	} else {
	        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ) );
	        return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{FFFFFF}Account - Authentication", szBigString, "Login", "Leave");
    	}
    }
    if ( dialogid == DIALOG_REGISTER )
    {
        if ( response )
        {
        	if ( p_PlayerLogged{ playerid } )
        		return SendError( playerid, "You are already logged in!" );

            if ( strlen( inputtext ) > 24 || strlen( inputtext ) < 3 )
            {
            	format( szBigQuery, 300, "{FFFFFF}Welcome, this account ("COL_RED"%s"COL_WHITE") is not registered.\nPlease enter your desired password for this account.\n\n"COL_RED"Your password length must vary from 3 to 24 characters.\n\n"COL_GREY"Once you are registered, do not share your password with anyone besides yourself!", ReturnPlayerName( playerid ) );
				ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Account - Register", szBigQuery, "Register", "Leave");
            }
            else
            {
                static
                	szHashed[ 129 ],
                	szSalt[ 25 ],
                	szIP[ 16 ]
                ;

             	randomString( szSalt, 24 );
             	pencrypt( szHashed, sizeof( szHashed ), inputtext, szSalt );
				GetPlayerIp( playerid, szIP, sizeof( szIP ) );
				format( szBigQuery, sizeof( szBigQuery ), "INSERT INTO `USERS` (`NAME`,`PASSWORD`,`SALT`,`IP`,`SCORE`,`CASH`,`ADMINLEVEL`,`BANKMONEY`,`OWNEDHOUSES`,`KILLS`,`DEATHS`,`VIP_PACKAGE`,`OWNEDCARS`,`LASTLOGGED`,`VIP_EXPIRE`,`LAST_SKIN`,`COP_BAN`,`UPTIME`,`ARRESTS`,`FIGHTSTYLE`,`VIPWEP1`,`VIPWEP2`,`VIPWEP3`,`MUTE_TIME`,`WANTEDLVL`,`ROBBERIES`,`PING_IMMUNE`,`FIRES`,`CONTRACTS`,`COP_TUTORIAL`,`JOB`,`LAST_IP`,`ONLINE`) " );
				format( szBigQuery, sizeof( szBigQuery ), "%s VALUES('%s','%s','%s','%s',0,0,0,0,0,1,1,0,0,%d,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,'%s',1)", szBigQuery, mysql_escape( ReturnPlayerName( playerid ) ), szHashed, mysql_escape( szSalt ), mysql_escape( szIP ), g_iTime, mysql_escape( szIP ) );
       			mysql_function_query( dbHandle, szBigQuery, true, "OnPlayerRegister", "d", playerid );
				p_JobSet{ playerid } = false;
				//p_CitySet{ playerid } = false;
				p_SpawningCity{ playerid } = CITY_SF;
				p_Uptime[ playerid ] = 0;
				ShowAchievement( playerid, "Registering to SF-CnR!", 1 );
                p_PlayerLogged{ playerid } = true;
                SetPlayerCash( playerid, 0 );
                SetPlayerScore( playerid, 0 );
				p_Kills[ playerid ] = 1;
				p_Deaths[ playerid ] = 1;
				//p_XP[ playerid ] = 0;
				//p_CopTutorial{ playerid } = 0;
				p_drillStrength[ playerid ] = MAX_DRILL_STRENGTH;
				p_OwnedHouses[ playerid ] = 0;
				p_OwnedBusinesses[ playerid ] = 0;
				p_OwnedVehicles[ playerid ] = 0;
				p_IrresistibleCoins[ playerid ] = 0;
				p_Burglaries[ playerid ] = 0;
				ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}Account Email", ""COL_WHITE"Would you like to assign an email to your account for security?\n\nWe'll keep you also informed on in-game and community associated events!", "Confirm", "Cancel" );
                SendServerMessage( playerid, "You have "COL_GREEN"successfully{FFFFFF} registered! You have been automatically logged in!" );
            }
        }
        else return ShowPlayerDialog( playerid, DIALOG_REGISTER_QUIT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Account - Authentication", "{FFFFFF}Are you sure you want to leave the server?", "Yes", "No" );
    }
    if ( dialogid == DIALOG_REGISTER_QUIT ) {
    	if ( response ) {
    		return Kick( playerid );
    	} else {
	        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_RED"%s"COL_WHITE") is not registered.\nPlease enter your desired password for this account.\n\n"COL_GREY"Once you are registered, do not share your password with anyone besides yourself!", ReturnPlayerName( playerid ) );
	        return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Account - Register", szBigString, "Register", "Leave");
    	}
    }
    if ( dialogid == DIALOG_JOB )
    {
        if (response)
        {
          	p_Job{ playerid } = listitem;

          	if ( !IsPlayerJailed( playerid ) && IsPlayerSpawned( playerid ) )
          	{
            	ResetPlayerWeapons( playerid );
	     		switch( listitem )
				{
			        case JOB_RAPIST:
			        {
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_KIDNAPPER:
			        {
			            GivePlayerWeapon( playerid, 29, 220 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_TERRORIST:
			        {
			            GivePlayerWeapon( playerid, 33, 50 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_HITMAN:
			        {
			            GivePlayerWeapon( playerid, 4, 1 );
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 34, 30 );
			        }
			        case JOB_PROSTITUTE:
			        {
			            GivePlayerWeapon( playerid, 10, 1 );
			            GivePlayerWeapon( playerid, 25, 30 );
			            GivePlayerWeapon( playerid, 30, 300 );
			        }
			        case JOB_WEAPON_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 31, 300 );
			        }
			        case JOB_DRUG_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 25, 30 );
			        }
			        case JOB_DIRTY_MECHANIC:
			        {
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 27, 90 );
					}
			        case JOB_BURGLAR:
			        {
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 31, 300 );
					}
			    }
			}

            TogglePlayerControllable( playerid, 1 );

			if ( ! p_JobSet{ playerid } ) {
				ShowPlayerDialog( playerid, DIALOG_PASSIVE_MODE, DIALOG_STYLE_LIST, "{FFFFFF}What is your type of style?", "{555555}Choose Below Below:\nI Like Roleplaying\nI Like Deathmatching", "Select", "" );
			}

            p_JobSet{ playerid } = true;

            //if ( !p_CitySet{ playerid } )
            //	ShowPlayerDialog( playerid, DIALOG_SPAWN_CITY, DIALOG_STYLE_LIST, "{FFFFFF}Select Spawning City", "San Fierro\nLas Venturas\nLos Santos\nRandom City", "Select", "" );

           	SendServerMessage( playerid, "Your job has been set to %s. you can change it at the City Hall for "COL_GOLD"$5,000"COL_WHITE".", GetJobName( p_Job{ playerid } ) );
		}
        else
        {
         	TogglePlayerControllable( playerid, 0 );
			ShowPlayerDialog( playerid, DIALOG_JOB, DIALOG_STYLE_LIST, "{FFFFFF}Job Selection", "Rapist\nKidnapper\nTerrorist\nHitman\nProstitute\nWeapon Dealer\nDrug Dealer\nDirty Mechanic\nBurglar", "Select", "" );
        }
    }


	if ( dialogid == DIALOG_PASSIVE_MODE )
	{
		if ( ! response || ! listitem ) {
			ShowPlayerDialog( playerid, DIALOG_PASSIVE_MODE, DIALOG_STYLE_LIST, "{FFFFFF}What is your type of style?", "{555555}Choose Below Below:\nI Like Roleplaying\nI Like Deathmatching", "Select", "" );
		}

		if ( listitem == 1 ) {
			SendServerMessage( playerid, "Since you like roleplay, passive mode has been automatically enabled for you!" );
		} else if ( listitem == 2 ) {
			CallLocalFunction( "OnDialogResponse", "dddds", playerid, DIALOG_CP_MENU, 1, SETTING_PASSIVE_MODE + 1, "ignore" ); // cunning way
			SendServerMessage( playerid, "Since you like deathmatch, passive mode has been automatically enabled for you!" );
		}
	}
	if ( dialogid == DIALOG_BOMB_SHOP )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );
		if ( response )
		{
			if ( listitem == ( 0 ) )
			{
			    if ( GetPlayerCash( playerid ) < 500 )
			        return SendError( playerid, "You don't have enough money for this item" );

				if ( p_C4Amount[ playerid ] >= MAX_C4 )
					return SendError( playerid, "You've reached the maximum C4 limit" );

			    GivePlayerCash( playerid, -500 );
				p_C4Amount[ playerid ] ++;
				SendServerMessage( playerid, "You have purchased 1 C4 for "COL_GOLD"$500"COL_WHITE"." );
			}
			else if ( listitem == ( 1 ) )
			{
			    if ( GetPlayerCash( playerid ) < 2450 )
			        return SendError( playerid, "You don't have enough money for this item" );

				if ( p_C4Amount[ playerid ] >= MAX_C4 )
					return SendError( playerid, "You've reached the maximum C4 limit" );

				if ( p_C4Amount[ playerid ] + 5 > MAX_C4 )
				{
				    new amount = MAX_C4 - p_C4Amount[ playerid ];
					SendServerMessage( playerid, "You have bought %d C4(s) for "COL_GOLD"%s"COL_WHITE" as adding five would exceed the C4 limit.", MAX_C4 - p_C4Amount[ playerid ], cash_format( amount * 495 ) );
					p_C4Amount[ playerid ] += amount;
				    GivePlayerCash( playerid, -( amount * 495 ) );
				    return 1;
				}
				else
				{
				    SendServerMessage( playerid, "You have purchased 5 C4 for "COL_GOLD"$2450"COL_WHITE"." );
				    p_C4Amount[ playerid ] += 5;
				    GivePlayerCash( playerid, -2450 );
				}
			}
			else if ( listitem == ( 2 ) )
			{
			    if ( p_C4Amount[ playerid ] < 1 )
			        return SendError( playerid, "You don't have any C4's" );

                GivePlayerCash( playerid, 250 );
                p_C4Amount[ playerid ] --;

				SendServerMessage( playerid, "You have sold 1 C4 for "COL_GOLD"$250"COL_WHITE"." );
			}
			return ShowPlayerDialog( playerid, DIALOG_BOMB_SHOP, DIALOG_STYLE_TABLIST, "{FFFFFF}C4 Shop", "1 C4\t"COL_GOLD"$500\n5 C4\t"COL_GOLD"$2450\nSell C4\t"COL_GREEN"$250", "Select", "Cancel" ), 1;
		}
	}
    if ( ( dialogid == DIALOG_BANK_MENU ) && response )
	{
		new
			gangid = p_GangID[ playerid ];

	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

		if ( gangid == INVALID_GANG_ID && listitem > 2 )
	    	return SendError( playerid, "You are not in any gang!" );

        switch( listitem )
		{
            case 0:
            {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Withdraw", "Back");
            }
            case 1:
            {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Deposit", "Back");
            }
            case 2:
            {
                format( Query, sizeof( Query ), ""COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( p_BankMoney[ playerid ] ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Personal Account", Query, "Ok", "Back");
            }
            case 3:
            {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
                ShowPlayerDialog(playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Withdraw", "Back");
            }
           	case 4:
            {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
                ShowPlayerDialog(playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Deposit", "Back");
            }
            case 5:
            {
                format( Query, sizeof( Query ), ""COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog(playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Account", Query, "Ok", "Back");
            }
        }
    }
    if (dialogid == DIALOG_BANK_WITHDRAW)
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );
        if (response)
		{
        	if ( strmatch( inputtext, "MAX" ) || strmatch( inputtext, "ALL" ) ) format( inputtext, 16, "%d", p_BankMoney[ playerid ] );
            if (!strlen(inputtext))
			{
			    format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Withdraw", "Back");
            }
            else if (!IsNumeric(inputtext)) {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Withdraw", "Back");
            }
            else if ( strval( inputtext ) > 99999999 || strval( inputtext ) < 0 )
            {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Withdraw", "Back");
            }
            else if (strval(inputtext) > p_BankMoney[ playerid ]) {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Insufficient balance, therefore withdrawal failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Withdraw", "Back");
            }
            else {
            	new iWithdraw = strval( inputtext );
                p_BankMoney[ playerid ] -= iWithdraw;
                GivePlayerCash( playerid, iWithdraw );
                format( Query, sizeof( Query ), ""COL_GREY"Amount Withdrawn:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iWithdraw ), cash_format( p_BankMoney[ playerid ] ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Personal Account", Query, "Ok", "Back" );
            }
        }
        else ShowPlayerBankMenuDialog( playerid );
    }
    if ( dialogid == DIALOG_BANK_DEPOSIT )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );
        if (response) {
        	if ( strmatch( inputtext, "MAX" ) || strmatch( inputtext, "ALL" ) ) format( inputtext, 16, "%d", GetPlayerCash( playerid ) );
            if (!strlen(inputtext)) {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Deposit", "Back");
            }
            else if (!IsNumeric(inputtext)) {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Deposit", "Back");
            }
            else if (strval(inputtext) > GetPlayerCash( playerid )) {
                format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Insufficient balance, therefore deposition failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Deposit", "Back");
            }
            else if ( strval( inputtext ) > 99999999 || strval( inputtext ) < 0 )
            {
            	format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( p_BankMoney[ playerid ] ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", Query, "Deposit", "Back" );
            }
            else {
            	new iDeposit = strval( inputtext );
                p_BankMoney[ playerid ] += iDeposit;
                GivePlayerCash( playerid, -iDeposit );
                format( Query, sizeof( Query ), ""COL_GREY"Amount Deposited:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iDeposit ), cash_format( p_BankMoney[ playerid ] ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Personal Account", Query, "Ok", "Back" );
            }
        }
        else ShowPlayerBankMenuDialog( playerid );
    }
    if ( ( dialogid == DIALOG_BANK_INFO || dialogid == DIALOG_GANG_BANK_INFO ) && !response )
    {
	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

  		return ShowPlayerBankMenuDialog( playerid );
    }
	if ( dialogid == DIALOG_GANG_BANK_WITHDRAW )
	{
		if ( !response )
			return ShowPlayerBankMenuDialog( playerid );

		new
			iWithdraw,
			gangid = p_GangID[ playerid ]
		;

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "You must be in a gang to use this feature." );

	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

	    if ( !IsPlayerGangLeader( playerid, gangid ) )
	    	return ShowPlayerBankMenuDialog( playerid ), SendError( playerid, "You must be the gang leader to use this feature." );

	    if ( sscanf( inputtext, "d", iWithdraw ) )
	    {
		    format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog(playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Withdraw", "Back");
	    }
        else if ( iWithdraw > 99999999 || iWithdraw < 0 )
        {
            format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog(playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Withdraw", "Back");
        }
        else if ( iWithdraw > g_gangData[ gangid ] [ E_BANK ] )
        {
            format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_RED"Insufficient balance, therefore withdrawal failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog(playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Withdraw", "Back");
        }
        else
        {
            g_gangData[ gangid ] [ E_BANK ] -= iWithdraw;
            GivePlayerCash( playerid, iWithdraw );
            SaveGangData( gangid );

			// transaction
	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'gang withdraw')", p_AccountID[ playerid ], g_gangData[ gangid ] [ E_SQL_ID ], iWithdraw );
	     	mysql_single_query( szNormalString );

	     	// withdraw
            SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s(%d) has withdrawn %s from the gang bank account.", ReturnPlayerName( playerid ), playerid, cash_format( iWithdraw ), "%%" );
            format( Query, sizeof( Query ), ""COL_GREY"Amount Withdrawn:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iWithdraw ), cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Account", Query, "Ok", "Back" );
        }
        return 1;
    }
	if ( dialogid == DIALOG_GANG_BANK_DEPOSIT )
	{
		if ( !response )
			return ShowPlayerBankMenuDialog( playerid );

		if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
			return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

		new
			iDeposit,
			gangid = p_GangID[ playerid ]
		;

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "You must be in a gang to use this feature." );

	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

        if ( sscanf( inputtext, "d", iDeposit ) )
        {
            format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog(playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Deposit", "Back");
        }
        else if ( iDeposit > 99999999 || iDeposit < 1 )
        {
        	format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Deposit", "Back" );
        }
        else if ( iDeposit > GetPlayerCash( playerid ) )
        {
            format( Query, sizeof( Query ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_RED"Insufficient balance, therefore deposition failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog(playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", Query, "Deposit", "Back");
        }
        else
        {
            g_gangData[ gangid ] [ E_BANK ] += iDeposit;
            GivePlayerCash( playerid, -iDeposit );
            SaveGangData( gangid );

			// transaction
	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'gang deposit')", p_AccountID[ playerid ], g_gangData[ gangid ] [ E_SQL_ID ], iDeposit );
	     	mysql_single_query( szNormalString );

	     	// deposit
            SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s(%d) has deposited %s into the gang bank account.", ReturnPlayerName( playerid ), playerid, cash_format( iDeposit ) );
            format( Query, sizeof( Query ), ""COL_GREY"Amount Deposited:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iDeposit ), cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Account", Query, "Ok", "Back" );
        }
        return 1;
    }
	if ( dialogid == DIALOG_HOUSES )
	{
		if ( ! response )
			return ShowPlayerSpawnMenu( playerid );

	#if VIP_ALLOW_OVER_LIMIT == false
		if ( ! p_VIPLevel[ playerid ] && p_OwnedHouses[ playerid ] > GetPlayerHouseSlots( playerid ) ) {
			ResetSpawnLocation( playerid );
			return SendError( playerid, "Please renew your V.I.P or sell this home to match your house allocated limit (/h sell)." );
		}
	#endif

    	new x = 0;

	    foreach ( new i : houses ) if ( IsPlayerHomeOwner( playerid, i ) )
		{
	       	if ( x == listitem )
	      	{
        		if ( IsHouseOnFire( i ) )
        		{
        			ShowPlayerSpawnMenu( playerid );
        			SendError( playerid, "This house is on fire. You cannot spawn there at the moment." );
        		}
        		else
        		{
	        		SetPlayerSpawnLocation( playerid, "HSE", i );
				 	SendServerMessage( playerid, "House spawning has been set at "COL_GREY"%s"COL_WHITE".", g_houseData[ i ] [ E_HOUSE_NAME ] );
        		}
			 	return 1;
      		}
	      	x ++;
		}
		return 1;
	}
	if ( ( dialogid == DIALOG_CITY_HALL ) && response )
	{
		switch( listitem )
		{
		    case 0:
		    {
		    	if ( p_Class[ playerid ] != CLASS_CIVILIAN )
		    		return SendError( playerid, "You must be a civilian to change your current job." );

		        if ( GetPlayerCash( playerid ) < 5000 )
		       		return SendError( playerid, "You need "COL_GOLD"$5,000"COL_WHITE" to change your job." );

	            TogglePlayerControllable( playerid, 0 );
				ShowPlayerDialog( playerid, DIALOG_JOB, DIALOG_STYLE_LIST, "{FFFFFF}Job Selection", "Rapist\nKidnapper\nTerrorist\nHitman\nProstitute\nWeapon Dealer\nDrug Dealer\nDirty Mechanic\nBurglar", "Select", "" );
				GivePlayerCash( playerid, -( 5000 ) );
				SendServerMessage( playerid, "You have been directed to the job selection, refer to your new job." );
		    }
		    case 1:
		    {
				SendServerMessage( playerid, "You have been directed to the city selection, refer to your new spawning city." );
				ShowPlayerDialog( playerid, DIALOG_SPAWN_CITY, DIALOG_STYLE_LIST, "{FFFFFF}Change Spawning City", "San Fierro\nLas Venturas\nLos Santos\n"COL_GREY"Random City", "Select", "Back" );
		    }
		}
	}
	if ( dialogid == DIALOG_SPAWN_CITY )
	{
		if ( !response )
		{
			//if ( !p_CitySet{ playerid } )
            // 	return ShowPlayerDialog( playerid, DIALOG_SPAWN_CITY, DIALOG_STYLE_LIST, "{FFFFFF}Select Spawning City", "San Fierro\nLas Venturas\nLos Santos\nRandom City", "Select", "" ), 1;

       		return ShowPlayerDialog( playerid, DIALOG_CITY_HALL, DIALOG_STYLE_LIST, "{FFFFFF}City Hall", ""COL_GOLD"$5,000"COL_WHITE"\t\tChange Job\n"COL_GOLD"free"COL_WHITE"\t\tChange City", "Select", "Close" ), 1;
		}

 		//p_CitySet{ playerid } = true;
		p_SpawningCity{ playerid } = listitem;
		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[CITY]"COL_WHITE" You have set your spawning city to "COL_GREY"%s"COL_WHITE".", returnCityName( listitem ) );
	}
	if ( ( dialogid == DIALOG_HOSPITAL ) && response )
	{
		#if ENABLE_CITY_LV == true
	    if ( !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL_LV ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL1_LS ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL2_LS ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL_FC ] ) )
			return SendError( playerid, "You must be in the hospital's checkpoint to use this." );
	    #else
	    if ( !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL ] ) ) return SendError( playerid, "You must be in the hospital's checkpoint to use this." );
	    #endif

		switch( listitem )
		{
			case 0:
			{
				if ( GetPlayerCash( playerid ) >= 2000 ) GivePlayerCash( playerid, -(2000) ), SetPlayerHealth( playerid, 100.0 ), SendServerMessage( playerid, "You have healed your self for $2,000.");
				else return SendError( playerid, "You cannot afford this item." );
			}
			case 1:
			{
				if ( GetPlayerCash( playerid ) >= 4000 ) GivePlayerCash( playerid, -(4000) ), p_InfectedHIV{ playerid } = false, SendServerMessage( playerid, "You cured all your infections for $4,000.");
                else return SendError( playerid, "You cannot afford this item." );
			}
			case 2:
			{
				if ( GetPlayerCash( playerid ) >= 6000 ) GivePlayerCash( playerid, -(6000) ), p_InfectedHIV{ playerid } = false, SetPlayerHealth( playerid, 100.0 ), SendServerMessage( playerid, "You cured all your infections and healed yourself for $6,000." );
                else return SendError( playerid, "You cannot afford this item." );
			}
		}
	}
	if ( ( dialogid == DIALOG_ARENAS ) && response )
	{
	    switch( listitem )
	    {
			case 0:
			{
			    SetPlayerPosition( playerid, 1412.639892, -1.787510, 1000.924377, 1, 69 );
			    SendServerMessage( playerid, "You have been teleported to Warehouse 1." );
			}
			case 1:
			{
			    SetPlayerPosition( playerid, 1302.519897, -1.787510, 1001.028259, 18, 69 );
			    SendServerMessage( playerid, "You have been teleported to Warehouse 2." );
			}
			case 2:
			{
			    SetPlayerPosition( playerid, -1398.103515, 937.631164, 1036.479125, 15, 69 );
			    SendServerMessage( playerid, "You have been teleported to Bloodbowl." );
			}
			case 3:
			{
			    SetPlayerPosition( playerid, -1398.065307, -217.028900, 1051.115844, 7, 69 );
			    SendServerMessage( playerid, "You have been teleported to 8-Track." );
			}
			case 4:
			{
			    SetPlayerPosition( playerid, -975.975708,1060.983032,1345.671875, 10, 69 );
			    SendServerMessage( playerid, "You have been teleported to RC Battlefield." );
			}
			case 5:
			{
			    SetPlayerPosition( playerid, 501.980987,-69.150199,998.757812, 11, 69 );
			    SendServerMessage( playerid, "You have been teleported to Bar." );
			}
			case 6:
			{
			    SetPlayerPosition( playerid, 2543.462646,-1308.379882,1026.728393, 2, 69 );
			    SendServerMessage( playerid, "You have been teleported to Crack Factory." );
			}

			case 7:
			{
			    SetPlayerPosition( playerid, -794.806396,497.738037,1376.195312, 1, 69 );
			    SendServerMessage( playerid, "You have been teleported to Liberty City Inside." );
			}
			case 8:
			{
			    SetPlayerPosition( playerid, 1059.895996,2081.685791,10.820312, 0, 69 );
			    SendServerMessage( playerid, "You have been teleported to LV Warehouse." );
			}
			case 9:
			{
			    SetPlayerPosition( playerid, -1465.268676,1557.868286,1052.531250, 14, 69 );
			    SendServerMessage( playerid, "You have been teleported to Kickstart." );
			}
			case 10:
			{
			    SetPlayerPosition( playerid, -1444.645507,-664.526000,1053.572998, 4, 69 );
			    SendServerMessage( playerid, "You have been teleported to Dirt Track." );
			}
			case 11:
			{
			    SetPlayerPosition( playerid, 1453.1576,-1066.7552,213.3828, 0, 69 );
			    SendServerMessage( playerid, "You have been teleported to Dodge the Plane." );
			}
	    }
	}
	if ( ( dialogid == DIALOG_GANG_COLOR ) && response )
	{
	    if ( listitem != 0 )
	    {
	        listitem -= 1; // So it starts from 0...
			g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ] = g_gangColors[ listitem ];
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has changed the gang color to %s", ReturnPlayerName( playerid ), playerid, ReturnGangNameColor( listitem ) );
	      	SetGangColorsToGang( p_GangID[ playerid ] );
		}
		else {
			if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
			ShowPlayerDialog( playerid, DIALOG_GANG_COLOR_INPUT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Colors", "{FFFFFF}Write a hexidecimal color within the textbox", "Submit", "Cancel" );
		}
	}
	if ( ( dialogid == DIALOG_GANG_COLOR_INPUT ) && response )
	{
		if ( !strlen( inputtext ) || !isHex( inputtext ) )
		    return ShowPlayerDialog( playerid, DIALOG_GANG_COLOR_INPUT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Colors", "{FFFFFF}Write a hexidecimal color within the textbox\n\n{ff0000}Invalid HEX color.", "Submit", "Cancel" );

		new gangid = p_GangID[ playerid ];
		new hex_to_int = HexToInt( inputtext );

		g_gangData[ gangid ] [ E_COLOR ] = setAlpha( hex_to_int, 0xFF );

		SendClientMessageToGang( gangid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has changed the gang color to %06x", ReturnPlayerName( playerid ), playerid, hex_to_int >>> 8 );
	 	SetGangColorsToGang( gangid );
	}
	if ( ( dialogid == DIALOG_GANG_LIST ) && response )
	{
		new
			x = 0;

		for ( new g = 0; g < sizeof( g_sortedGangData ); g ++ ) if ( g_sortedGangData[ g ] [ E_SQL_ID ] != 0 )
		{
	       	if ( x == listitem )
	      	{
	      		new curr_gang = p_GangID[ playerid ];
	      		new curr_gang_sql = 0;

	      		if ( Iter_Contains( gangs, curr_gang ) )
	      			curr_gang_sql = g_gangData[ curr_gang ] [ E_SQL_ID ];

	      		SetPVarInt( playerid, "viewing_gang_sql", g_sortedGangData[ g ] [ E_SQL_ID ] );
	      		ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", curr_gang_sql != g_sortedGangData[ g ] [ E_SQL_ID ] && ! g_sortedGangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );
				break;
	   		}
	      	x ++;
		}
	}
	if ( dialogid == DIALOG_GANG_LIST_OPTIONS )
	{
		if ( !response )
			return cmd_gangs( playerid, "" );

		new gang_sql = GetPVarInt( playerid, "viewing_gang_sql" );
		new g;

		// search sql, just incase someone searchs the gangs and doesnt find what they want
		foreach (g : gangs) if ( g_gangData[ g ] [ E_SQL_ID ] == gang_sql ) {
			break;
		}

		if ( ! ( 0 <= g < MAX_GANGS ) || ! Iter_Contains( gangs, g ) )
			return SendError( playerid, "Unable to discover gang information as it no longer is loaded, please try again. (0x7D)" );

		switch( listitem )
		{
			case 0: // Join gang
			{
				if ( p_Class[ playerid ] != CLASS_CIVILIAN ) {
					SendError( playerid, "You must be a civilian to switch gangs." );
				} else if ( p_GangID[ playerid ] == g ) {
					SendError( playerid, "You are already in this gang." );
				} else if ( IsGangPrivate( g ) ) {
					SendError( playerid, "You can no longer join this gang as it is private." );
				} else if ( ! SetPlayerGang( playerid, g ) ) {
					SendError( playerid, "You can no longer join this gang." );
				}
				ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", p_GangID[ playerid ] != g && ! g_gangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );
			}

			case 1: // View statistics
			{
				new iPlayers = GetOnlineGangMembers( g );
				SetPVarInt( playerid, "gang_members_id", g );
				format( szLargeString, 350, ""COL_GREY"Gang ID:"COL_WHITE" %d\n"COL_GREY"Online Members:"COL_WHITE" %d\n"COL_GREY"Score:"COL_WHITE" %d\n"COL_GREY"Kills:"COL_WHITE" %d\n"COL_GREY"Deaths:"COL_WHITE" %d\n"COL_GREY"K/D Ratio:"COL_WHITE" %0.2f\n", g_gangData[ g ] [ E_SQL_ID ], iPlayers, g_gangData[ g ] [ E_SCORE ], g_gangData[ g ] [ E_KILLS ], g_gangData[ g ] [ E_DEATHS ], floatdiv( g_gangData[ g ] [ E_KILLS ], g_gangData[ g ] [ E_DEATHS ] ) );
				format( szLargeString, 350, "%s"COL_GREY"Bank:"COL_WHITE" %s\n"COL_GREY"Zones Captured:"COL_WHITE" %d", szLargeString, cash_format( g_gangData[ g ] [ E_BANK ] ), GetGangCapturedTurfs( g ) );
				ShowPlayerDialog( playerid, DIALOG_GANG_LIST_RESPONSE, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Statistics", szLargeString, "Close", "Back" );
			}

			case 2:
			{
				// View gang members
				mysql_tquery( dbHandle,
					sprintf( "SELECT `NAME`,`ONLINE` FROM `USERS` WHERE `GANG_ID`=%d ORDER BY `ONLINE` DESC LIMIT 20 OFFSET 0", g_gangData[ g ] [ E_SQL_ID ] ),
					"OnListGangMembers", "ddd", playerid, g, 0
				);
			}
		}
		return 1;
	}
	if ( dialogid == DIALOG_GANG_LIST_RESPONSE ) {
		new g = GetPVarInt( playerid, "gang_members_id" );

		if ( ! Iter_Contains( gangs, g ) )
			return SendError( playerid, "Could not find gang. Try again." );

		return ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", p_GangID[ playerid ] != g && ! g_gangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );
	}
	if ( dialogid == DIALOG_GANG_LIST_MEMBERS )
	{
		new g = GetPVarInt( playerid, "gang_members_id" );
		new members_shown = GetPVarInt( playerid, "gang_members_results" );
		new page = GetPVarInt( playerid, "gang_members_page" );

		if ( ! Iter_Contains( gangs, g ) )
			return SendError( playerid, "Could not find gang. Try again." );

		if ( ! response && page == 0 )
			return ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", p_GangID[ playerid ] != g && ! g_gangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );

		if ( members_shown < 20 && response )
			return 1;

		// if response, add a page, otherwise previous
		page += response ? 1 : -1;

		// find page result
		mysql_tquery( dbHandle,
			sprintf( "SELECT `NAME`,`ONLINE` FROM `USERS` WHERE `GANG_ID`=%d ORDER BY `ONLINE` DESC LIMIT 20 OFFSET %d", g_gangData[ g ] [ E_SQL_ID ], page * 20 ),
			"OnListGangMembers", "ddd", playerid, g, page
		);
		return 1;
	}
	if ( dialogid == DIALOG_CASINO_REWARDS && response )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );

		new
	    	x = 0;

	    if ( listitem >= sizeof( g_casinoRewardsShopItems ) )
	    {
	    	// printf("Listitem %d, sizeof %d\n", listitem, sizeof( g_casinoRewardsShopItems) );
	    	new rewards_item = listitem - sizeof( g_casinoRewardsShopItems );
	    	new Float: rewards_points = g_casinoRewardsItems[ rewards_item ] [ E_POINTS ];

    		if ( p_CasinoRewardsPoints[ playerid ] < rewards_points )
    			return SendError( playerid, "You need %s rewards points for this item.", points_format( rewards_points ) );

    		switch ( rewards_item )
    		{
    			case 0: GivePlayerFireworks( playerid, 1 ); // fireworks
    			case 1:
    			{
    				p_ExplosiveBullets[ playerid ] += 10;
    				ShowPlayerHelpDialog( playerid, 3000, "Press ~r~~k~~CONVERSATION_YES~~w~ to activate explosive bullets." );
    			}
    			/*case 2: // taxes
    			{
					p_TaxTime[ playerid ] = ( p_TaxTime[ playerid ] > p_Uptime[ playerid ] ? p_TaxTime[ playerid ] : p_Uptime[ playerid ] ) + 3600;
					mysql_single_query( sprintf( "UPDATE `USERS` SET `TAX_TIME`=%d WHERE `ID`=%d", p_TaxTime[ playerid ], p_AccountID[ playerid ] ) );
    			}*/
    			case 2: // highroller
    			{
    				if ( p_IsCasinoHighRoller{ playerid } ) return SendError( playerid, "You are already considered a casino highroller." );
					mysql_single_query( sprintf( "UPDATE `USERS` SET `VISAGE_HIGHROLLER`=1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );
					DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 0 ] ), p_HighrollersBarrier[ playerid ] [ 0 ] = -1;
					DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 1 ] ), p_HighrollersBarrier[ playerid ] [ 1 ] = -1;
    				p_IsCasinoHighRoller{ playerid } = true;
    			}
    		}

    		p_CasinoRewardsPoints[ playerid ] -= rewards_points;
			mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS` = %f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
			SendServerMessage( playerid, "You have bought "COL_GREY"%s"COL_WHITE" for "COL_GOLD"%s"COL_WHITE" rewards points.", g_casinoRewardsItems[ rewards_item ] [ E_NAME ], points_format( rewards_points ) );
    		return ShowPlayerRewardsMenu( playerid );
	    }
	    else
	    {
		    for ( new i = 0; i < sizeof ( g_shopItemData ); i ++ ) if ( IsCasinoRewardsShopItem( i ) )
		    {
		    	if ( x == listitem )
		    	{
		    		new Float: rewards_cost = ( float( g_shopItemData[ i ] [ E_PRICE ] ) * CASINO_REWARDS_COST_MP ) / CASINO_REWARDS_DIVISOR;

		    		if ( p_CasinoRewardsPoints[ playerid ] < rewards_cost )
		    			return SendError( playerid, "You need %s rewards points for this item.", points_format( rewards_cost ) );

		    		// shop limits
		    		if ( g_shopItemData[ i ] [ E_LIMIT ] == 1 )
		    		{
		    			if ( g_shopItemData[ i ] [ E_ID ] == SHOP_ITEM_DRILL ) {
		        			if ( p_drillStrength[ playerid ] == MAX_DRILL_STRENGTH ) return SendError( playerid, "You have already purchased this item." );
		        			p_drillStrength[ playerid ] = MAX_DRILL_STRENGTH;
		    			} else if ( g_shopItemData[ i ] [ E_ID ] == SHOP_ITEM_MONEY_CASE ) {
		        			if ( p_MoneyBag{ playerid } == true ) return SendError( playerid, "You have already purchased this item." );
							if ( p_Class[ playerid ] != CLASS_POLICE ) SetPlayerAttachedObject( playerid, 1, 1210, 7, 0.302650, -0.002469, -0.193321, 296.124053, 270.396881, 8.941717, 1.000000, 1.000000, 1.000000 );
		        			p_MoneyBag{ playerid } = true;
	        			}
		    		}
		    		else
		    		{
		    			new iCurrentQuantity = GetShopItemVariable( playerid, i );
			    		new iLimit = g_shopItemData[ i ] [ E_LIMIT ] + ( 2 * p_VIPLevel[ playerid ] );

			    		if ( iCurrentQuantity >= iLimit )
			    			return SendError( playerid, "You cannot buy more of this item with your rewards points." );

		    			SetShopItemVariable( playerid, i, iCurrentQuantity + 1 );
		    		}

		    		// deduct points
					p_CasinoRewardsPoints[ playerid ] -= rewards_cost;
					mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS` = %f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
					SendServerMessage( playerid, "You have bought 1x "COL_GREY"%s"COL_WHITE" for "COL_GOLD"%s"COL_WHITE" rewards points.", g_shopItemData[ i ] [ E_NAME ], points_format( rewards_cost ) );
		    		return ShowPlayerRewardsMenu( playerid );
		    	}
		    	x ++;
		    }
	    }
	    return 1;
	}
	if ( dialogid == DIALOG_CASINO_BAR && response )
	{
		if ( p_CasinoRewardsPoints[ playerid ] < 20.0 ) return SendError( playerid, "You need 20.0 casino rewards points to buy an item from the casino's bar." );

		// what did they buy
		switch ( listitem )
		{
			case 0: SetPlayerSpecialAction( playerid, 20 ), SendServerMessage( playerid, "You have bought a beer for "COL_GOLD"20.0 casino rewards points"COL_WHITE"." );
			case 1: SetPlayerSpecialAction( playerid, 21 ), SendServerMessage( playerid, "You have bought a cigar for "COL_GOLD"20.0 casino rewards points"COL_WHITE"." );
			case 2: SetPlayerSpecialAction( playerid, 22 ), SendServerMessage( playerid, "You have bought wine for "COL_GOLD"20.0 casino rewards points"COL_WHITE"." );
		}

		// update account
		p_CasinoRewardsPoints[ playerid ] -= 20.0;
		mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS` = %f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
		return 1;
	}
	if ( ( dialogid == DIALOG_VIP_LOCKER ) && response )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );
	    if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this while you're in an event." );
		if ( listitem == 0 )
		{
		 	if ( p_VIPLevel[ playerid ] < VIP_BRONZE )
		     	return SendError( playerid, "You must be a Bronze V.I.P to acquire this." );

			if ( !IsPlayerInRangeOfPoint( playerid, 5.0, -1966.1591, 852.7100, 1214.2678 ) && !IsPlayerInRangeOfPoint( playerid, 5.0, -1944.1324, 830.0725, 1214.2678 ) && !IsPlayerInRangeOfPoint( playerid, 5.0, 60.3115, 121.5226, 1017.4534 ) )
				return SendError( playerid, "You must be near a gun vending machine inside the V.I.P lounge to use this." );

            if ( p_VIPArmourRedeem[ playerid ] > g_iTime && p_VIPLevel[ playerid ] < VIP_GOLD )
 				return SendError( playerid, "You must wait %d seconds to redeem another armour set again.", p_VIPArmourRedeem[ playerid ] - g_iTime );

			SetPlayerArmour( playerid, 100.0 );
			p_VIPArmourRedeem[ playerid ] = g_iTime + ( p_VIPLevel[ playerid ] == VIP_BRONZE ? 60 : 300 );
			SendServerMessage( playerid, "You have redeemed an armour set." );
		}
		else
		{
		    if ( p_VIPWeaponRedeem[ playerid ] > g_iTime && p_VIPLevel[ playerid ] < VIP_GOLD )
		        return SendError( playerid, "You must wait %d seconds to redeem another weapon again.", p_VIPWeaponRedeem[ playerid ] - g_iTime );

		    new weaponid;
		    switch( listitem )
		    {
		    	case 1 .. 13: weaponid = 21 + listitem;
		    	case 14 .. 23: weaponid = listitem - 13;
		    	case 24 .. 25: weaponid = listitem - 10;
		    }
		    GivePlayerWeapon( playerid, weaponid, 0xFFFF );
		    SendServerMessage( playerid, "You have redeemed a %s.", ReturnWeaponName( weaponid ) );
			p_VIPWeaponRedeem[ playerid ] = g_iTime + ( p_VIPLevel[ playerid ] == VIP_BRONZE ? 60 : 300 );
		}
	}
	if ( ( dialogid == DIALOG_FIGHTSTYLE ) && response )
	{
		switch( listitem )
		{
			case 0:
			{
			    if ( GetPlayerFightingStyle( playerid ) == FIGHT_STYLE_KNEEHEAD )
			    {
			        SendError( playerid, "You already have this fighting style activated." );
			        return 1;
			    }
			    if ( GetPlayerCash( playerid ) < 1000 )
			    {
			        SendError( playerid, "You don't have enough money to learn this fighting style." );
			        return 1;
			    }
			    SetPlayerFightingStyle( playerid, FIGHT_STYLE_KNEEHEAD );
				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `FIGHTSTYLE`=%d WHERE `NAME` = '%s'", GetPlayerFightingStyle( playerid ), mysql_escape( ReturnPlayerName( playerid ) ) );
				mysql_single_query( szNormalString );
				GivePlayerCash( playerid, -1000 );
				SendServerMessage( playerid, "You have paid $1,000 and learnt "COL_ORANGE"Defending{FFFFFF}." );
			}
			case 1:
			{
			    if ( GetPlayerFightingStyle( playerid ) == FIGHT_STYLE_BOXING )
			    {
			        SendError( playerid, "You already have this fighting style activated." );
			        return 1;
			    }
			    if ( GetPlayerCash( playerid ) < 4000 )
			    {
			        SendError( playerid, "You don't have enough money to learn this fighting style." );
			        return 1;
			    }
			    SetPlayerFightingStyle( playerid, FIGHT_STYLE_BOXING );
				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `FIGHTSTYLE`=%d WHERE `NAME` = '%s'", GetPlayerFightingStyle( playerid ), mysql_escape( ReturnPlayerName( playerid ) ) );
				mysql_single_query( szNormalString );
				GivePlayerCash( playerid, -4000 );
				SendServerMessage( playerid, "You have paid $4,000 and learnt "COL_ORANGE"Boxing{FFFFFF}." );
			}
			case 2:
			{
			    if ( GetPlayerFightingStyle( playerid ) == FIGHT_STYLE_KUNGFU )
			    {
			        SendError( playerid, "You already have this fighting style activated." );
			        return 1;
			    }
			    if ( GetPlayerCash( playerid ) < 9000 )
			    {
			        SendError( playerid, "You don't have enough money to learn this fighting style." );
			        return 1;
			    }
			    SetPlayerFightingStyle( playerid, FIGHT_STYLE_KUNGFU );
				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `FIGHTSTYLE`=%d WHERE `NAME` = '%s'", GetPlayerFightingStyle( playerid ), mysql_escape( ReturnPlayerName( playerid ) ) );
				mysql_single_query( szNormalString );
				GivePlayerCash( playerid, -9000 );
				SendServerMessage( playerid, "You have paid $9,000 and learnt "COL_ORANGE"Kungfu{FFFFFF}." );
			}
		}
	}
	if ( ( dialogid == DIALOG_VIP_WEP ) && response )
	{
	    if ( listitem == 1 && p_VIPLevel[ playerid ] < VIP_BRONZE ) return SendError( playerid, "You can only use this slot if you are a "COL_BRONZE"Bronze V.I.P{FFFFFF} or higher." );
	    if ( listitem == 2 && p_VIPLevel[ playerid ] < VIP_GOLD ) return SendError( playerid, "You can only use this slot if you are a "COL_GOLD"Gold V.I.P{FFFFFF} or higher." );
	    ShowPlayerDialog( playerid, DIALOG_VIP_WEP_SELECT, DIALOG_STYLE_LIST, "{FFFFFF}Weapon Select", ""COL_RED"Remove Weapon On This Slot\n9mm Pistol\nSilenced Pistol\nDesert Eagle\nShotgun\nSawn-off Shotgun\nSpas 12\nMac 10\nMP5\nAK-47\nM4\nTec 9\nRifle\nSniper", "Select", "Cancel");
		p_VIPWep_Modify{ playerid } = listitem;
	}
	if ( dialogid == DIALOG_VIP_WEP_SELECT )
	{
	    if ( response )
	    {
	        if ( listitem == 0 )
	        {
	            switch( p_VIPWep_Modify{ playerid } )
				{
				    case 0: p_VIPWep1{ playerid } = 0, SendClientMessage( playerid, COLOR_GREY, "[SERVER]{FFFFFF} You have "COL_RED"removed"COL_WHITE" the weapon in the first slot." );
				    case 1: p_VIPWep2{ playerid } = 0, SendClientMessage( playerid, COLOR_GREY, "[SERVER]{FFFFFF} You have "COL_RED"removed"COL_WHITE" the weapon in the second slot." );
				    case 2: p_VIPWep3{ playerid } = 0, SendClientMessage( playerid, COLOR_GREY, "[SERVER]{FFFFFF} You have "COL_RED"removed"COL_WHITE" the weapon in the third slot." );
				}
				return 1;
	    	}
			new wep = 21 + listitem;
			switch( p_VIPWep_Modify{ playerid } )
			{
			    case 0: p_VIPWep1{ playerid } = wep;
			    case 1: p_VIPWep2{ playerid } = wep;
			    case 2: p_VIPWep3{ playerid } = wep;
			}
		    SendServerMessage( playerid, "You have selected a "COL_GREY"%s"COL_WHITE" for your %s slot.", ReturnWeaponName( wep ), p_VIPWep_Modify{ playerid } == 0 ? ("first") : ( p_VIPWep_Modify{ playerid } == 1 ? ("second") : ("third") )  );
	    }
	    else cmd_vipspawnwep( playerid, "" );
	}
	if ( ( dialogid == DIALOG_CMDS ) && response )
	{
	    static szCMDS[ 1920 ];
	    switch( listitem )
	    {
	        case 0:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/help{FFFFFF} - Displays the general help information of the server.\n"\
								""COL_GREY"/rules{FFFFFF} - Displays the server rules.\n"\
								""COL_GREY"/commands{FFFFFF} - Displays a list of all the server commands.\n"\
								""COL_GREY"/report{FFFFFF} - Sends a report to the in-game administrators.\n"\
								""COL_GREY"/ask{FFFFFF} - Sends a question (must be game/server-related) to the in-game admins.\n" );
				strcat( szCMDS, ""COL_GREY"/admins{FFFFFF} - Displays the current online administrators.\n"\
								""COL_GREY"/vip{FFFFFF} - View the list of VIP packages for this server.\n"\
								""COL_GREY"/donated{FFFFFF} - Redeem VIP after donating with a transaction id.\n"\
								""COL_GREY"/gettaxrate{FFFFFF} - See what your tax rate is currently set to.\n"\
								""COL_GREY"/gettotalcash{FFFFFF} - View the total sum of money in the server.\n" );
				strcat( szCMDS, ""COL_GREY"/calc(ulator){FFFFFF} - Calculate mathematical expressions in-game.\n"\
								""COL_GREY"/eventbank{FFFFFF} - Help fund events by donating to the event bank.\n"\
								""COL_GREY"/cnr{FFFFFF} - Shows the cops and robbers balance in the server.\n"\
								""COL_GREY"/playerjobs{FFFFFF} - Display the players using a particular job/skill.\n" );
				strcat( szCMDS, ""COL_GREY"/policetutorial{FFFFFF} - Allows you to retake the law enforcement tutorial.\n"\
								""COL_GREY"/idletime{FFFFFF} - Shows the time of the last sent update by a player.\n"\
								""COL_GREY"/rank{FFFFFF} - View your or someone's current global rank in the server." );

				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Basic Commands", szCMDS, "Okay", "Back" );
	        }
	        case 1:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS,	""COL_GOLD"General Commands\n\n"\
								""COL_GREY"/sendmoney{FFFFFF} - Sends money to another in-game player.\n"\
								""COL_GREY"/gps{FFFFFF} - Toggles GPS to locate important locations inside the server.\n"\
								""COL_GREY"/controlpanel{FFFFFF} - Displays your control panel.\n"\
								""COL_GREY"/request{FFFFFF} - Request for a specific-job person.\n"\
								""COL_GREY"/fps{FFFFFF} - Displays your frame rate.\n" );
	            strcat( szCMDS, ""COL_GREY"/getmytax{FFFFFF} - See how much tax you may need to pay.\n"\
								""COL_GREY"/packetloss{FFFFFF} - View your packet loss to the server.\n"\
								""COL_GREY"/unbanme{FFFFFF} - Pay your way out of a class ban.\n"\
								""COL_GREY"/chuffloc{FFFFFF} - Display the location of the ChuffSec security van.\n"\
								""COL_GREY"/richlist{FFFFFF} - Displays the three most richest players in-game.\n\n" );
                strcat( szCMDS,	""COL_GOLD"Account Commands\n\n"\
								""COL_GREY"/stats{FFFFFF} - Displays your statistics.\n"\
								""COL_GREY"/savestats{FFFFFF} - Saves your current statistics.\n"\
								""COL_GREY"/achievements{FFFFFF} - Displays achievements you can unlock.\n"\
								""COL_GREY"/myaccid{FFFFFF} - Shows your account ID.\n"\
								""COL_GREY"/changepassword{FFFFFF} - Changes your current password to a new one.\n"\
								""COL_GREY"/xpmarket{FFFFFF} - Allows you to trade some XP to in-game money.\n\n" );
                strcat( szCMDS,	""COL_GOLD"Information Commands\n\n"\
								""COL_GREY"/idof{FFFFFF} - Displays the specified player's ID and their username.\n"\
								""COL_GREY"/lastlogged{FFFFFF} - Shows the last played time of a user.\n"\
								""COL_GREY"/animlist{FFFFFF} - Shows the animation list.\n"\
								""COL_GREY"/jaillist{FFFFFF} - Shows the jailed player list.\n"\
								""COL_GREY"/twitter{FFFFFF} - Shows the latest tweets from @IrresistibleDev\n" );
                strcat( szCMDS, ""COL_GREY"/weeklytime{FFFFFF} - Shows the weekly time of a player.\n\n" );
                strcat( szCMDS, ""COL_GOLD"Communication Commands\n\n"\
								""COL_GREY"/me{FFFFFF} - Sends a message based action with yourself.\n"\
								""COL_GREY"/pm{FFFFFF} - Sends a private message to a specified player.\n"\
								""COL_GREY"/r{FFFFFF} - Responds to the latest person you messaged.\n"\
								""COL_GREY"/dnd(all){FFFFFF} - Toggles access of receiving PM's from a specified/or all player(s).\n"\
								""COL_GREY"/ircpm{FFFFFF} - Sends a message to the IRC channel.\n" );
                strcat( szCMDS, ""COL_GREY"/(w)hisper{FFFFFF} - Whisper to nearby players." );

				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Main Commands", szCMDS, "Okay", "Back" );
	        }
	        case 2:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GOLD"General Civilian Commands\n\n"\
								""COL_GREY"/rob{FFFFFF} - Robs the closest player.\n"\
								""COL_GREY"/rape{FFFFFF} - Rapes the closest player.\n"\
								""COL_GREY"/robstore{FFFFFF} - Displays the key to press in-order to rob a store.\n"\
								""COL_GREY"/pdjail{FFFFFF} - Displays the time until jail cells are available for raiding.\n"\
								""COL_GREY"/banks{FFFFFF} - Displays the time until certain banks are available for robbing.\n" );
				strcat( szCMDS, ""COL_GREY"/stoprob{FFFFFF} - Stops your current robbery.\n"\
								""COL_GREY"/job{FFFFFF} - Shows your job.\n"\
								""COL_GREY"/911{FFFFFF} - Calls the emergency services.\n"\
								""COL_GREY"/placehit{FFFFFF} - Places a hit on a specified player.\n"\
								""COL_GREY"/viewguns{FFFFFF} - Displays weapons that can be purchased from a weapon dealer.\n" );
				strcat( szCMDS, ""COL_GREY"/payticket{FFFFFF} - Pays the issued ticket by a Law Enforcement Officer.\n"\
								""COL_GREY"/takeover{FFFFFF} - Take over a gangzone with your gang.\n" );
                strcat( szCMDS, ""COL_GREY"/gang{FFFFFF} - Displays gang commands.\n\n"\
								""COL_GOLD"Job Commands\n\n"\
								""COL_ORANGE"Rapist{FFFFFF} - /rape\n"\
								""COL_ORANGE"Kidnapper{FFFFFF} - /(un)tie, /kidnap, /ransom(pay)\n"\
								""COL_ORANGE"Terrorist{FFFFFF} - /c4\n" );
				strcat( szCMDS, ""COL_ORANGE"Hitman{FFFFFF} - /(hide)tracker, /hitlist\n"\
								""COL_ORANGE"Prostitute{FFFFFF} - /blowjob, /robitems\n"\
								""COL_ORANGE"Weapon Dealer{FFFFFF} - /sellgun\n"\
								""COL_ORANGE"Drug Dealer{FFFFFF} - /weed\n" );
				strcat( szCMDS, ""COL_ORANGE"Dirty Mechanic{FFFFFF} - /mech\n"\
								""COL_ORANGE"Burglar{FFFFFF} - /burglar\n"\
								""COL_PINK"Lumberjack Minijob{FFFFFF} - /wood\n"\
								""COL_PINK"Meth Production Minijob{FFFFFF} - /meth\n"\
								""COL_PINK"Mining Minijob{FFFFFF} - /ore\n" );
				strcat( szCMDS, ""COL_PINK"Trucking Minijob{FFFFFF} - /work" );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Civilian Commands", szCMDS, "Okay", "Back" );
	        }
	        case 3:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/shop{FFFFFF} - Displays the shop menu whilst in Supa Save.\n"\
								""COL_GREY"/tie{FFFFFF} - Ties the closest player with your rope(s).\n"\
								""COL_GREY"/untie{FFFFFF} - Unties the closest player.\n" );
				strcat( szCMDS, ""COL_GREY"/breakout{FFFFFF} - Breaks out the jail by melting the cell bars using a Metal Melter." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Shop/Item Commands", szCMDS, "Okay", "Back" );
	        }
	        case 4:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GOLD"General LEO Commands\n\n"\
								""COL_GREY"/arrest{FFFFFF} - Arrests a specificed player.\n"\
								""COL_GREY"/(un)cuff{FFFFFF} - (un)cuffs a specified player.\n"\
								""COL_GREY"/taze{FFFFFF} - Tazes a specified player.\n"\
								""COL_GREY"/ticket{FFFFFF} - Tickets a specified player.\n" );
				strcat( szCMDS, ""COL_GREY"/issuewarrant{FFFFFF} - Warrants a specified player.\n"\
								""COL_GREY"/location{FFFFFF} - Displays the located of a specified player.\n"\
								""COL_GREY"/backup{FFFFFF} - Calls your team for backup.\n"\
								""COL_GREY"/pullover{FFFFFF} - Asks a specified player to pull over.\n"\
								""COL_GREY"/detain{FFFFFF} - Detains the closest cuffed player.\n" );
                strcat( szCMDS, ""COL_GREY"/search{FFFFFF} - Searches a player for any drugs and issues a warrant on them.\n"\
								""COL_GREY"/bail{FFFFFF} - Bails a person for money out of jail.\n"\
								""COL_GREY"/getwanted{FFFFFF} - Obtain a suspect's wanted level.\n\n"\
								""COL_GOLD"Special LEO Commands\n\n"\
								""COL_GREY"/crb{FFFFFF} - Creates a roadblock.\n" );
                strcat( szCMDS, ""COL_GREY"/drb{FFFFFF} - Destroys a specified roadblock id.\n"\
								""COL_GREY"/drball{FFFFFF} - Removes all roadblocks.\n"\
								""COL_GREY"/spike{FFFFFF} - Sets a spike set.\n"\
								""COL_GREY"/dss{FFFFFF} - Destroys a specified spike set id.\n"\
								""COL_GREY"/dssall{FFFFFF} - Removes all spike sets.\n"\
								""COL_GREY"/emp{FFFFFF} - Shuts down the engine of a driver's vehicle.\n"\
								""COL_GREY"/bruteforce{FFFFFF} - Brute forces a houses' password." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Police Commands", szCMDS, "Okay", "Back" );
	        }
	        case 5: {
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Fireman Commands", ""COL_GREY"/firetracker"COL_WHITE" - Displays a tracker of active fires in a list.\n"COL_GREY"/rfiretracker"COL_WHITE" - Hides the fire tracker.", "Okay", "Back" );
	        }
	        case 6: {
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Paramedic Commands", ""COL_GREY"/heal"COL_WHITE" - Offers a specified player a health refill for $750.\n"COL_GREY"/cure"COL_WHITE" - Offers a specified player a cure for $4875.", "Okay", "Back" );
	        }
	        case 7:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GOLD"General Vehicle Commands\n\n"\
								""COL_GREY"/eject{FFFFFF} - Ejects a specified player.\n"\
								""COL_GOLD"Owned Vehicle Commands\n\n" );
				strcat( szCMDS, ""COL_GREY"/v{FFFFFF} - Shows the commands for buyable vehicles.\n"\
								""COL_GREY"/v reset{FFFFFF} - Resets a vehicles modification data.\n"\
								""COL_GREY"/v park{FFFFFF} - Parks the vehicle at your marked position.\n"\
								""COL_GREY"/v respawn{FFFFFF} - Respawns the vehicle to the location where he parked it.\n" );
				strcat( szCMDS, ""COL_GREY"/v locate{FFFFFF} - Enables the tracker in the map to locate the player's owned vehicle.\n"\
								""COL_GREY"/v color{FFFFFF} - Modifies the color of the vehicle.\n"\
								""COL_GREY"/v paintjob{FFFFFF} - Applies a paintjob to the vehicle.\n"\
								""COL_GREY"/v sell{FFFFFF} - Sells the vehicle to 50% of its original price (requires the player to be inside it)." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Vehicle Commands", szCMDS, "Okay", "Back" );
	        }
     		case 8:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/h{FFFFFF} - Shows the commands for buyable houses.\n"\
								""COL_GREY"/h buy{FFFFFF} - Purchases a buyable house (must be in the house entrance checkpoint).\n"\
								""COL_GREY"/h config{FFFFFF} - Configures some house settings. (Requires the player to be inside the house).\n" );
				strcat( szCMDS, ""COL_GREY"/h spawn{FFFFFF} - Spawns you at your house after each death.\n"\
								""COL_GREY"/h sell{FFFFFF} - Sells the house to 50% of its original price (requires the player to be inside the house)." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}House Commands", szCMDS, "Okay", "Back" );
	        }
	        case 9:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/perks{FFFFFF} - A menu where you can benefit your gameplay and waste some XP.\n"\
								""COL_GREY"/toys{FFFFFF} - Adds attachable objects to the player (requires 500 score).\n"\
								""COL_GREY"/label{FFFFFF} - Places a message above your head (must have over 3,500 XP).\n"\
								""COL_GREY"/labelcolor{FFFFFF} - Change your label's color.\n"\
								""COL_GREY"/rlabel{FFFFFF} - Removes the label on your head.\n" );
				strcat( szCMDS, ""COL_GREY"/labelinfo{FFFFFF} - Displays your label text with the 32 character limit.\n"\
								""COL_GREY"/radio{FFFFFF} - Shows the list of radio stations you can listen to.\n"\
								""COL_GREY"/stopradio{FFFFFF} - Stops the radio from playing.\n"\
								""COL_GREY"/moviemode{FFFFFF} - Toggles movie mode so you can record without all the text on the screen." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Miscellaneous Commands", szCMDS, "Okay", "Back" );
	        }
	        case 10:
	        {
				if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
				cmd_vipcmds( playerid, "" );
	        }
	    }
	    return 1;
	}
	if ( ( dialogid == DIALOG_CMDS_REDIRECT ) && !response ) { cmd_cmds( playerid, "" ); }
	if ( ( dialogid == DIALOG_STATS ) && response )
	{
	    new pID = p_ViewingStats[ playerid ], gangid = p_GangID[ pID ];
		switch( listitem )
		{
			case 0:
			{
				new
					vipSeconds = p_VIPExpiretime[ pID ] - g_iTime;

			    format( szLargeString, 750, ""COL_GREY"Name:{FFFFFF} %s(%d)\n"\
											""COL_GREY"Account ID:{FFFFFF} %d\n"\
											""COL_GREY"Admin Level:{FFFFFF} %d\n"\
											""COL_GREY"Time Online:{FFFFFF} %s\n"\
											""COL_GREY"Irresistible Rank:{FFFFFF} %s\n"\
											""COL_GREY"Irresistible Coins:{FFFFFF} %f\n", ReturnPlayerName( pID ), pID, p_AccountID[ pID ], p_AdminLevel[ pID ], secondstotime( p_Uptime[ pID ] ), GetSeasonalRankName( GetPlayerRank( pID ) ), p_IrresistibleCoins[ pID ] );

				format( szLargeString, 750, "%s"COL_GREY"V.I.P Level:{FFFFFF} %s\n"\
											""COL_GREY"V.I.P Expiry:{FFFFFF} %s\n"\
											""COL_GREY"Cop Warns:{FFFFFF} %d/" #MAX_CLASS_BAN_WARNS "\n"\
											""COL_GREY"Army Warns:{FFFFFF} %d/" #MAX_CLASS_BAN_WARNS "\n"\
											""COL_GREY"V.I.P Job:{FFFFFF} %s\n"\
											""COL_GREY"Current Job:{FFFFFF} %s",
											szLargeString, VIPToString( p_VIPLevel[ pID ] ), vipSeconds > 0 ? secondstotime( vipSeconds ) : ( "N/A" ), p_CopBanned{ pID }, p_ArmyBanned{ pID }, p_VIPLevel[ pID ] < VIP_GOLD ? ( "N/A" ) : GetJobName( p_VIPJob{ pID } ), GetJobName( p_Job{ pID } ) );

				if ( gangid != -1 ) {
					format( szLargeString, 750, "%s\n"COL_GREY"Gang:"COL_WHITE" %s(%d)", szLargeString, g_gangData[ gangid ] [ E_NAME ], gangid );
				}

				ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}General Statistics", szLargeString, "Okay", "Back" );
			}
			case 1:
			{
				format( szLargeString, 720,	""COL_GREY"Score:{FFFFFF} %d\n"\
											""COL_GREY"XP:{FFFFFF} %s\n"\
											""COL_GREY"Money:{FFFFFF} %s\n"\
											""COL_GREY"Bank Money:{FFFFFF} %s\n"\
											""COL_GREY"Kills:{FFFFFF} %d\n"\
											""COL_GREY"Deaths:{FFFFFF} %d\n"\
											""COL_GREY"Ratio (K/D):{FFFFFF} %0.2f\n",
											GetPlayerScore( pID ), number_format( GetPlayerTotalExperience( pID ), .decimals = 0 ), cash_format( GetPlayerCash( pID ) ), cash_format( p_BankMoney[ pID ] ), p_Kills[ pID ], p_Deaths[ pID ], floatdiv( p_Kills[ pID ], p_Deaths[ pID ] ) );

				format( szLargeString, 720,	"%s"COL_GREY"Owned Houses:{FFFFFF} %d (Limit %d)\n"\
				                          	""COL_GREY"Owned Vehicles:{FFFFFF} %d (Limit %d)\n"\
				                          	""COL_GREY"Total Arrests:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Robberies:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Extinguished Fires:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Completed Hits:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Burglaries:{FFFFFF} %d\n",
											szLargeString, p_OwnedHouses[ pID ], GetPlayerHouseSlots( pID ), p_OwnedVehicles[ pID ], GetPlayerVehicleSlots( pID ), p_Arrests[ pID ], p_Robberies[ pID ], p_Fires[ pID ], p_HitsComplete[ pID ], p_Burglaries[ pID ] );

				format( szLargeString, 750,	"%s"COL_GREY"Total Jail Raids:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Bank Raids:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Cars Jacked:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Trucked Cargo:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Meth Yielded:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Pilot Missions:{FFFFFF} %d\n"\
				                          	""COL_GREY"Total Train Missions:{FFFFFF} %d",
											szLargeString, p_JailsBlown[ pID ], p_BankBlown[ pID ], p_CarsJacked[ pID ], p_TruckedCargo[ pID ], p_MethYielded[ pID ], p_PilotMissions[ pID ], p_TrainMissions[ playerid ] );

				ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Main Statistics", szLargeString, "Okay", "Back" );
			}
			case 2:
			{
				new
					Float: fDrill = float( p_drillStrength[ playerid ] ) / float( MAX_DRILL_STRENGTH ) * 100.0;

				format( szLargeString, 700, ""COL_GREY"Thermal Drill:{FFFFFF} %0.0f%%\n"\
											""COL_GREY"Ropes:{FFFFFF} %d\n"\
											""COL_GREY"Metal Melters:{FFFFFF} %d\n"\
											""COL_GREY"Scissors:{FFFFFF} %d\n"\
											""COL_GREY"Weed:{FFFFFF} %d gram(s)\n"\
											""COL_GREY"Meth:{FFFFFF} %d pounds\n"\
											""COL_GREY"Money Case:{FFFFFF} %s\n",
											fDrill, p_Ropes[ pID ], p_MetalMelter[ pID ], p_Scissors[ pID ], p_WeedGrams[ pID ], p_Methamphetamine{ pID }, p_MoneyBag{ pID } == true ? ( "Yes" ) : ( "No" ) );

				format( szLargeString, 700, "%s"COL_GREY"Aluminium Foil:{FFFFFF} %d\n"\
											""COL_GREY"Secure Wallet:{FFFFFF} %s\n"\
											""COL_GREY"Bobby Pins:{FFFFFF} %d\n"\
											""COL_GREY"C4:{FFFFFF} %d\n"\
											""COL_GREY"Chastity Belt:{FFFFFF} %s\n"\
											""COL_GREY"Caustic Soda:{FFFFFF} %d\n"\
											""COL_GREY"Muriatic Acid:{FFFFFF} %d\n"\
											""COL_GREY"Hydrogen Chloride:{FFFFFF} %d\n",
											szLargeString, p_AntiEMP[ pID ], p_SecureWallet{ pID } == true ? ( "Yes" ) : ( "No" ), p_BobbyPins[ pID ], p_C4Amount[ pID ], p_AidsVaccine{ pID } == true ? ("Yes") : ("No"),
											p_CausticSoda{ pID }, p_MuriaticAcid{ pID }, p_HydrogenChloride{ pID } );

				format( szLargeString, 700, "%s"COL_GREY"Fireworks:{FFFFFF} %d\n"COL_GREY"Explosive Bullets:{FFFFFF} %d\n", szLargeString, p_Fireworks[ pID ], p_ExplosiveBullets[ pID ] );
				ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Item Statistics", szLargeString, "Okay", "Back" );
			}
			case 3: Streak_ShowPlayer( pID, DIALOG_STATS_REDIRECT, "Back", playerid );
			case 4: WeaponStats_ShowPlayer( pID, DIALOG_STATS_REDIRECT, true, playerid );
			case 5: displayAchievements( pID, DIALOG_STATS_REDIRECT, "Back", playerid );
		}
	}
	if ( ( dialogid == DIALOG_STATS_REDIRECT ) && !response ) {
		ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, "{FFFFFF}Statistics", "General Statistics\nGame Statistics\nItem Statistics\nStreak Statistics\nWeapon Statistics\nAchievements", "Okay", "Cancel" );
	}
	if ( dialogid == DIALOG_ACC_EMAIL ) {

		if ( ! response ) {
			ShowPlayerDialog( playerid, DIALOG_JOB, DIALOG_STYLE_LIST, "{FFFFFF}Job Selection", "Rapist\nKidnapper\nTerrorist\nHitman\nProstitute\nWeapon Dealer\nDrug Dealer\nDirty Mechanic\nBurglar", "Select", "" );
			SendServerMessage( playerid, "If you ever wish to assign an email to your account in the future, use "COL_GREY"/email"COL_WHITE"." );
			return 1;
		}

		new
			email[ 64 ];

		if ( sscanf( inputtext, "s[64]", email ) )  {
			ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}Account Email", ""COL_WHITE"Would you like to assign an email to your account for security?\n\nWe'll keep you also informed on in-game and community associated events!\n\n"COL_RED"Your email must be between 4 and 64 characters long.", "Confirm", "Cancel" );
			return SendError( playerid, "Your email must be between 4 and 64 characters long." );
		}

		if ( ! ( 3 < strlen( email ) < 64 ) ) {
			ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}Account Email", ""COL_WHITE"Would you like to assign an email to your account for security?\n\nWe'll keep you also informed on in-game and community associated events!\n\n"COL_RED"Your email must be between 4 and 64 characters long.", "Confirm", "Cancel" );
			return SendError( playerid, "Your email must be between 4 and 64 characters long." );
		}

		if ( ! regex_match( email, "[a-zA-Z0-9_\\.]+@([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,4}" ) ) {
			ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}Account Email", ""COL_WHITE"Would you like to assign an email to your account for security?\n\nWe'll keep you also informed on in-game and community associated events!\n\n"COL_RED"Your email must be valid (foo@example.com).", "Confirm", "Cancel" );
			return SendError( playerid, "Your email must be valid (foo@example.com)." );
		}

	    format( szBigString, sizeof( szBigString ), "INSERT INTO `EMAIL_VERIFY`(`USER_ID`, `EMAIL`) VALUES (%d, '%s') ON DUPLICATE KEY UPDATE `EMAIL`='%s',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], mysql_escape( email ), mysql_escape( email ) );
	    mysql_function_query( dbHandle, szBigString, true, "OnQueueEmailVerification", "ds", playerid, email );
		ShowPlayerDialog( playerid, DIALOG_JOB, DIALOG_STYLE_LIST, "{FFFFFF}Job Selection", "Rapist\nKidnapper\nTerrorist\nHitman\nProstitute\nWeapon Dealer\nDrug Dealer\nDirty Mechanic\nBurglar", "Select", "" );
	   	return 1;
	}
	if ( dialogid == DIALOG_ACC_GUARD_EMAIL && response )
	{
		new
			email[ 64 ];

		if ( sscanf( inputtext, "s[64]", email ) )
			return SendError( playerid, "Your email must be between 4 and 64 characters long." );

		if ( ! ( 3 < strlen( email ) < 64 ) )
			return SendError( playerid, "Your email must be between 4 and 64 characters long." );

		if ( ! regex_match( email, "[a-zA-Z0-9_\\.]+@([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,4}" ) )
			return SendError( playerid, "Your email must be valid (foo@example.com)." );

	    format( szBigString, sizeof( szBigString ), "INSERT INTO `EMAIL_VERIFY`(`USER_ID`, `EMAIL`) VALUES (%d, '%s') ON DUPLICATE KEY UPDATE `EMAIL`='%s',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], mysql_escape( email ), mysql_escape( email ) );
	    mysql_function_query( dbHandle, szBigString, true, "OnQueueEmailVerification", "ds", playerid, email );
		return 1;
	}
	if ( dialogid == DIALOG_WEAPON_DEAL )
	{
	    if ( !response )
 		{
 			new
 				iDealer = p_WeaponDealer[ playerid ];

		  	if ( IsPlayerConnected( iDealer ) )
		  	{
		  		if ( GetPVarInt( iDealer, "weapon_sell_cd" ) < g_iTime )
		  			GivePlayerWantedLevel( iDealer, 6 ), SetPVarInt( iDealer, "weapon_sell_cd", g_iTime + 60 );

			  	SendClientMessageFormatted( iDealer, -1, ""COL_ORANGE"[WEAPON DEAL]{FFFFFF} %s(%d) has closed the deal.", ReturnPlayerName ( playerid ), playerid );
		  	}

			new purchased = GetPVarInt( playerid, "purchased_weapon" );
			if ( purchased ) {
				SetPVarInt( playerid, "weapon_buy_cool", g_iTime + 40 );
				GivePlayerWantedLevel( playerid, ( purchased * 2 ) > 6 ? 6 : purchased );
				DeletePVar( playerid, "purchased_weapon" );
			}

			SetPlayerArmedWeapon( playerid, 0 );
			p_WeaponDealing{ playerid } = false;
 			p_WeaponDealer[ playerid ] = INVALID_PLAYER_ID;
		  	return 1;
		}

		if ( p_VIPLevel[ playerid ] < VIP_GOLD && listitem == MENU_ARMOR ) {
			SendError( playerid, "You are not Gold V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
			return ShowAmmunationMenu( playerid, "{FFFFFF}Weapon Deal - Purchase Weapons", DIALOG_WEAPON_DEAL );
		}

	    p_WeaponDealMenu{ playerid } = listitem;
      	RedirectAmmunation( playerid, listitem, "{FFFFFF}Weapon Deal - Purchase Weapons", DIALOG_WEAPON_DEAL_BUY, 0.75, 5 );
	}
	if ( dialogid == DIALOG_WEAPON_DEAL_BUY )
	{
	    // The discount is %50 - You can change it above!
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot buy weapons in jail." );
	    if ( GetPlayerVirtualWorld( playerid ) == 69 ) return SendError( playerid, "You cannot buy weapons in an event." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED || !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You are unable to purchase any weapons at this time." );

		new
			weapondealerid = p_WeaponDealer[ playerid ];

		if ( !IsPlayerConnected( weapondealerid ) ) return SendError( playerid, "You are unable to purchase any weapons at this time." );
		if ( GetDistanceBetweenPlayers( playerid, weapondealerid ) > 33.0 ) return SendError( playerid, "You are unable to purchase any weapons at this time." );

		if ( response )
		{
		    for( new i, x = 0; i < sizeof( g_AmmunationWeapons ); i++ )
		    {
		        if ( g_AmmunationWeapons[ i ] [ E_MENU ] == p_WeaponDealMenu{ playerid } )
		        {
		            if ( x == listitem )
		            {
		                new price = floatround( g_AmmunationWeapons[ i ] [ E_PRICE ] * 0.75 ); // Change the discount here!!
					 	if ( price > GetPlayerCash( playerid ) )
						{
						    SendError( playerid, "You don't have enough money for this." );
      						RedirectAmmunation( playerid, p_WeaponDealMenu{ playerid }, "{FFFFFF}Weapon Deal - Purchase Weapons", DIALOG_WEAPON_DEAL_BUY, 0.75, 5 );
							return 1;
						}
						GivePlayerCash( weapondealerid, floatround( price * 0.75 ) );
		                SendClientMessageFormatted( weapondealerid, -1, ""COL_ORANGE"[WEAPON DEAL]{FFFFFF} %s(%d) has purchased a %s for "COL_GOLD"%s"COL_WHITE" (tax applied).", ReturnPlayerName( playerid ), playerid, g_AmmunationWeapons[ i ] [ E_NAME ], cash_format( price ) );
						SetPVarInt( playerid, "purchased_weapon", GetPVarInt( playerid, "purchased_weapon" ) + 1 );
						SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[WEAPON DEAL]{FFFFFF} You have purchased %s for "COL_GOLD"%s"COL_WHITE".", g_AmmunationWeapons[ i ] [ E_NAME ], cash_format( price ) );
						if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 101 ) SetPlayerArmour( playerid, 100.0 );
						else GivePlayerWeapon( playerid, g_AmmunationWeapons[ i ] [ E_WEPID ], g_AmmunationWeapons[ i ] [ E_AMMO ] * ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 35 ? 1 : 5 ) );
						SetPlayerArmedWeapon( playerid, 0 );
						GivePlayerCash( playerid, -( price ) );
						RedirectAmmunation( playerid, p_WeaponDealMenu{ playerid }, "{FFFFFF}Weapon Deal - Purchase Weapons", DIALOG_WEAPON_DEAL_BUY, 0.75, 5 );
						break;
		            }
		            x ++;
		        }
		    }
		}
		else ShowAmmunationMenu( playerid, "{FFFFFF}Weapon Deal - Purchase Weapons", DIALOG_WEAPON_DEAL );
	}
	if ( ( dialogid == DIALOG_AMMU ) && response )
	{
    	p_AmmunationMenu{ playerid } = listitem;
        return RedirectAmmunation( playerid, listitem );
	}
	if ( dialogid == DIALOG_AMMU_BUY )
	{
		if ( !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AMMUNATION_0 ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AMMUNATION_1 ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AMMUNATION_2 ] ) ) return SendError( playerid, "You must be in the Ammu-Nation purchasing checkpoint to use this." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED || !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You are unable to purchase any weapons at this time." );
		if ( response )
		{
		    for( new i, x = 0; i < sizeof( g_AmmunationWeapons ); i++ )
		    {
		        if ( g_AmmunationWeapons[ i ] [ E_MENU ] == p_AmmunationMenu{ playerid } )
		        {
		            if ( x == listitem )
		            {
					 	if ( g_AmmunationWeapons[ i ] [ E_PRICE ] > GetPlayerCash( playerid ) )
						{
						    SendError( playerid, "You don't have enough money for this." );
						    RedirectAmmunation( playerid, p_AmmunationMenu{ playerid } );
							return 1;
						}

						new
							bDealer = IsPlayerJob( playerid, JOB_WEAPON_DEALER ),
							iCostPrice = g_AmmunationWeapons[ i ] [ E_PRICE ]
						;

						if ( bDealer )
							iCostPrice = floatround( iCostPrice * 0.75 );

						GivePlayerCash( playerid, -iCostPrice );

						RedirectAmmunation( playerid, p_AmmunationMenu{ playerid } );

						if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 101 ) SetPlayerArmour( playerid, float( g_AmmunationWeapons[ i ] [ E_AMMO ] ) );
						else GivePlayerWeapon( playerid, g_AmmunationWeapons[ i ] [ E_WEPID ], g_AmmunationWeapons[ i ] [ E_AMMO ] );

						SendServerMessage( playerid, "You have purchased %s(%d) for "COL_GOLD"%s"COL_WHITE"%s.", g_AmmunationWeapons[ i ] [ E_NAME ], g_AmmunationWeapons[ i ] [ E_AMMO ], cash_format( iCostPrice ), bDealer ? ( " (inc. discount)" ) : ( "" ) );
		                break;
		            }
		            x ++;
		        }
		    }
		}
		else ShowAmmunationMenu( playerid );
	}
	if ( ( dialogid == DIALOG_APARTMENTS ) && response )
	{
		new Float: X, Float: Y, Float: Z;
		GetDynamicObjectPos( g_apartmentElevator, X, Y, Z );
		if ( !IsPlayerInRangeOfPoint( playerid, 2.0, X, Y, Z ) )
			return SendError( playerid, "You must be near the elevator to use this!" );

	    if ( listitem == 0 ) apartment_CallElevator( 0 );
	    else
	    {
			new id = listitem - 1;
			p_ApartmentEnter{ playerid } = id;
			if ( strmatch( g_apartmentData[ id ] [ E_OWNER ], "No-one" ) || isnull( g_apartmentData[ id ] [ E_OWNER ] ) || !g_apartmentData[ id ] [ E_CREATED ] )
			{
			 	ShowPlayerDialog( playerid, DIALOG_APARTMENTS_BUY, DIALOG_STYLE_MSGBOX, "{FFFFFF}Are you interested?", "{FFFFFF}This apartment is available for sale. The price is $5,000,000.\nIf you wish to buy it, please click 'Purchase'.", "Purchase", "Deny" );
			}
			else if ( !strmatch( g_apartmentData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
			    if ( g_apartmentData[ id ] [ E_LOCKED ] ) {
					return SendError( playerid, "This apartment has been locked by its owner." );
				}
			}
	    	apartment_CallElevator( id + 1 );
		}
	}
	if ( ( dialogid == DIALOG_APARTMENTS_BUY ) && response )
	{
	    if ( GetPlayerOwnedApartments( playerid ) > 0 )
	        return SendError( playerid, "You can only own one apartment." );

	    if ( GetPlayerCash( playerid ) < 5000000 )
	        return SendError( playerid, "You don't have enough money for this ($5,000,000)." );

		GivePlayerCash( playerid, -5000000 );
		autosaveStart( playerid, true ); // auto-save

		new aID = p_ApartmentEnter{ playerid };
		g_apartmentData[ aID ] [ E_CREATED ] = true;
		format( g_apartmentData[ aID ] [ E_OWNER ], 24, "%s", ReturnPlayerName( playerid ) );
		format( g_apartmentData[ aID ] [ E_NAME ], 30, "Apartment %d", aID );
		g_apartmentData[ aID ] [ E_LOCKED ] = 0;

		format( szNormalString, 100, "INSERT INTO `APARTMENTS` VALUES (%d,'%s','Apartment %d',0)", aID, mysql_escape( ReturnPlayerName( playerid ) ), aID );
	    mysql_single_query( szNormalString );

		SendServerMessage( playerid, "You have purchased an apartment for "COL_GOLD"$5,000,000"COL_WHITE"." );
	}
	if ( ( dialogid == DIALOG_FLAT_CONFIG ) && response )
	{
		for( new id, x = 0; id < sizeof( g_apartmentData ); id ++ )
		{
			if ( g_apartmentData[ id ] [ E_CREATED ] && strmatch( g_apartmentData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
		       	if ( x == listitem )
		      	{
					SetPVarInt( playerid, "flat_editing", id );
		      	    SendServerMessage( playerid, "You are now controlling the settings over "COL_GREY"%s", g_apartmentData[ id ] [ E_NAME ] );
		      		ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
		      		break;
				}
		      	x++;
			}
		}
	}
	if ( dialogid == DIALOG_FLAT_CONTROL )
	{
	    if ( !response )
	        return cmd_flat( playerid, "config" );

		switch( listitem )
		{
		    case 0:
		    {
		    	SetPlayerSpawnLocation( playerid, "APT", GetPVarInt( playerid, "flat_editing" ) );
				SendServerMessage( playerid, "You have set your spawning location to the specified apartment. To stop this you can use \"/flat stopspawn\"." );
				ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
			}
			case 1:
			{
		        new id = GetPVarInt( playerid, "flat_editing" );
             	g_apartmentData[ id ] [ E_LOCKED ] = ( g_apartmentData[ id ] [ E_LOCKED ] == 1 ? 0 : 1 );
				format( Query, 100, "UPDATE `APARTMENTS` SET `LOCKED`=%d WHERE `ID`=%d", g_apartmentData[ id ] [ E_LOCKED ], id );
				mysql_single_query( Query );
				SendServerMessage( playerid, "You have %s the specified apartment.", g_apartmentData[ id ] [ E_LOCKED ] == 1 ? ( "locked" ) : ( "unlocked" ) );
				ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
			}
		    case 2:
		    {
		   		ShowPlayerDialog( playerid, DIALOG_FLAT_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Owned Apartments", ""COL_WHITE"Input the apartment title you want to change with:", "Submit", "Back" );
			}
		    case 3: ShowPlayerDialog( playerid, DIALOG_YOU_SURE_APART, DIALOG_STYLE_MSGBOX, "{FFFFFF}Owned Apartments", ""COL_WHITE"Are you sure that you want to sell your apartment?", "Yes", "No" );
		}
	}
	if ( dialogid == DIALOG_YOU_SURE_APART )
	{
		if ( !response )
   			return ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );

		new id = GetPVarInt( playerid, "flat_editing" );

		g_apartmentData[ id ] [ E_CREATED ] = false;
		strcpy( g_apartmentData[ id ] [ E_OWNER ], "No-one" );
		// format( g_apartmentData[ id ] [ E_OWNER ], MAX_PLAYER_NAME, "%s", "No-one" );
		format( g_apartmentData[ id ] [ E_NAME ], 30, "Apartment %d", id );
		g_apartmentData[ id ] [ E_LOCKED ] = 0;

		format( szNormalString, 40, "DELETE FROM `APARTMENTS` WHERE `ID`=%d", id );
	    mysql_single_query( szNormalString );

        GivePlayerCash( playerid, 3000000 );

   		return SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have successfully sold your apartment for "COL_GOLD"$3,000,000"COL_WHITE".");
	}
	if ( ( dialogid == DIALOG_FLAT_TITLE ) )
	{
	    if ( !response )
	        return ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );

		if ( !strlen( inputtext ) )
			return ShowPlayerDialog( playerid, DIALOG_FLAT_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Owned Apartments", ""COL_WHITE"Input the apartment title you want to change with:\n\n"COL_RED"Must be more than 0 characters.", "Submit", "Back" );

		new id = GetPVarInt( playerid, "flat_editing" );
		mysql_single_query( sprintf( "UPDATE `APARTMENTS` SET `NAME`='%s' WHERE `ID`=%d", mysql_escape( inputtext ), id ) );
		format( g_apartmentData[ id ] [ E_NAME ], 30, "%s", inputtext );
 		SendServerMessage( playerid, "You have successfully changed the name of your apartment." );
  		ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
	}
	if ( ( dialogid == DIALOG_ONLINE_JOB ) && response )
	{
	 	new
		 	count = 0;

		erase( szLargeString );
		foreach(new pID : Player)
		{
		    if ( IsPlayerJob( pID, listitem ) && p_Class[ pID ] == CLASS_CIVILIAN )
		    {
		        format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\n", szLargeString, ReturnPlayerName( pID ), pID );
		        count++;
		    }
		}
		if ( !count ) szLargeString = ""COL_RED"N/A";

		format( szNormalString, 32, "{FFFFFF}Online %ss", GetJobName( listitem ) );
		ShowPlayerDialog( playerid, DIALOG_ONLINE_JOB_R, DIALOG_STYLE_LIST, szNormalString, szLargeString, "Okay", "Back" );
	}
	if ( ( dialogid == DIALOG_ONLINE_JOB_R ) && !response )  { cmd_playerjobs( playerid, "" ); }
	if ( ( dialogid == DIALOG_HELP ) && response )
	{
		SetPVarInt( playerid, "help_category", listitem );
	    mysql_function_query( dbHandle, sprintf( "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=%d ORDER BY `SUBJECT` ASC", listitem ), true, "OnFetchCategoryResponse", "dd", playerid, listitem );
	}
	if ( dialogid == DIALOG_HELP_CATEGORY )
	{
		if ( !response )
			return cmd_help( playerid, "" );

		if ( listitem >= 64 )
			return SendError( playerid, "Unable to process request, contact Lorenc in regards to this." );

		new
			digits[ 64 ];

		GetPVarString( playerid, "help_ids", szBigString, sizeof( szBigString ) );
		sscanf( szBigString, "a<i>[64]", digits );

	    //format( szNormalString, 96, "SELECT * FROM `HELP` WHERE `CATEGORY`=%d AND `ID`=%d", GetPVarInt( playerid, "help_category" ), digits[ listitem ] );
	    //mysql_function_query( dbHandle, szNormalString, true, "OnFetchThreadData", "ddd", playerid, GetPVarInt( playerid, "help_category" ), digits[ listitem ] );

		HTTP( playerid, HTTP_GET, sprintf( "sfcnr.com/api/player/help/%d", digits[ listitem ] ), "", "OnHelpHTTPResponse" );
	}
	if ( ( dialogid == DIALOG_HELP_THREAD ) && !response ) {
	    mysql_function_query( dbHandle, sprintf( "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=%d ORDER BY `SUBJECT` ASC", GetPVarInt( playerid, "help_category" ) ), true, "OnFetchCategoryResponse", "dd", playerid, GetPVarInt( playerid, "help_category" ) );
	}
	if ( ( dialogid == DIALOG_HELP_BACK ) && !response ) return cmd_help( playerid, "" );
	if ( ( dialogid == DIALOG_GATE ) && response )
	{
		new
			objectid = GetPVarInt( playerid, "gate_editing" );

		SetPVarInt( playerid, "gate_edititem", listitem );

		if ( listitem == 0 )
		{
			Iter_Remove( gates, objectid );
			DestroyDynamicObject( g_gateData[ objectid ] [ E_OBJECT ] );
			g_gateData[ objectid ] [ E_OBJECT ] = INVALID_OBJECT_ID;
			DeletePVar( playerid, "gate_editing" );
			DeletePVar( playerid, "gate_edititem" );

			SaveToAdminLog( playerid, objectid, "destroyed gate" );
			format( szNormalString, sizeof( szNormalString ), "DELETE FROM `GATES` WHERE ID=%d", objectid );
			mysql_single_query( szNormalString );

			SendClientMessageFormatted( playerid, -1, ""COL_PINK"[GATE]"COL_WHITE" You have removed a gate: "COL_GREY"%s"COL_WHITE".", g_gateData[ objectid ] [ E_NAME ] );
		}
		else if ( listitem < 9 ) ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
		else
		{
			SendServerMessage( playerid, "Hit the save icon to update the position of the gate." );
			EditDynamicObject( playerid, g_gateData[ objectid ] [ E_OBJECT ] );
		}
	}
	if ( ( dialogid == DIALOG_GATE_OWNER ) && response )
	{
		SetPVarInt( playerid, "gate_o_edititem", listitem );
		ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"What would you like to change this to?", "Commit", "Back" );
	}
	if ( dialogid == DIALOG_GATE_OWNER_EDIT )
	{
		new
			gID = GetPVarInt( playerid, "gate_o_editing" );

		if ( ! Iter_Contains( gates, gID ) )
			return SendError( playerid, "Invalid gate detected, please try again." );

		if ( g_gateData[ gID ] [ E_OWNER ] != p_AccountID[ playerid ] )
			return SendError( playerid, "You need to be the owner of this gate to edit it." );

		if ( response )
		{
			switch( GetPVarInt( playerid, "gate_o_edititem" ) )
			{
				case 0:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 24 )
						return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"What would you like to change this to?\n\n"COL_RED"The name must range between 3 and 24 characters.", "Commit", "Back" );

					format( g_gateData[ gID ] [ E_NAME ], 24, "%s", inputtext );
					SendServerMessage( playerid, "Your gate name has been set to \"%s\".", g_gateData[ gID ] [ E_NAME ] );
					UpdateGateData( gID, .recreate_obj = false );
				}
				case 1:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 8 )
				 		return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"What would you like to change this to?\n\n"COL_RED"The password must range between 3 and 8 characters.", "Commit", "Back" );

					format( g_gateData[ gID ] [ E_PASS ], 8, "%s", inputtext );
					SendServerMessage( playerid, "Your gate password has been set to \"%s\".", g_gateData[ gID ] [ E_PASS ] );
					UpdateGateData( gID, .recreate_obj = false );
				}
				case 2:
				{
					new
						sql_id;

					if ( sscanf( inputtext, "D(0)", sql_id ) ) {
						return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"What would you like to change this to?\n\n"COL_RED"The Gang ID must be an integer.", "Commit", "Back" );
					}

					// check if valid gang lol
					if ( sql_id != 0 )
					{
						new
							gangId = -1;

						foreach ( new g : gangs ) if ( sql_id == g_gangData[ g ] [ E_SQL_ID ] ) {
							gangId = g;
						}

						if ( gangId == -1 ) {
							return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"What would you like to change this to?\n\n"COL_RED"This gang is invalid or not currently online.", "Commit", "Back" );
						} else {
							SendServerMessage( playerid, "Your gate will be openable by members of \"%s\".", g_gangData[ gangId ] [ E_NAME ] );
						}
					} else {
						SendServerMessage( playerid, "You have unassigned a gang from your gate." );
					}

					g_gateData[ gID ] [ E_GANG_SQL_ID ] = sql_id;
					mysql_single_query( sprintf( "UPDATE `GATES` SET `GANG_ID`=%d WHERE `ID`=%d", sql_id, gID ) );
				}
			}
		}

		// redirect
		format( szNormalString, sizeof( szNormalString ), ""COL_WHITE"Gate Label\t"COL_GREY"%s\n"COL_WHITE"Gate Password\t"COL_GREY"%s\n"COL_WHITE"Gate Gang ID\t"COL_GREY"%d", g_gateData[ gID ] [ E_NAME ], g_gateData[ gID ] [ E_PASS ], g_gateData[ gID ] [ E_GANG_SQL_ID ] );
		ShowPlayerDialog( playerid, DIALOG_GATE_OWNER, DIALOG_STYLE_TABLIST, "{FFFFFF}Edit Gate", szNormalString, "Select", "Cancel" );
		return 1;
	}
	if ( dialogid == DIALOG_GATE_EDIT )
	{
		new
			gID = GetPVarInt( playerid, "gate_editing" );

		if ( response )
		{
			switch( GetPVarInt( playerid, "gate_edititem" ) )
			{
				case 1:
				{
					new
						pID;

					if ( sscanf( inputtext, "u", pID ) )
					{
						SendError( playerid, "This value must be numerical." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					else if ( !IsPlayerConnected( pID ) )
					{
						SendError( playerid, "Invalid Player ID." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					g_gateData[ gID ] [ E_OWNER ] = p_AccountID[ pID ];
				}
				case 2:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 24 )
					{
						SendError( playerid, "The name must range between 3 and 24 characters." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					format( g_gateData[ gID ] [ E_NAME ], 24, "%s", inputtext );
				}
				case 3:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 8 )
					{
						SendError( playerid, "The password must range between 3 and 8 characters." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					format( g_gateData[ gID ] [ E_PASS ], 8, "%s", inputtext );
				}
				case 4:
				{
					new
						model;

					if ( sscanf( inputtext, "d", model ) )
					{
						SendError( playerid, "This value must be numerical." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					g_gateData[ gID ] [ E_MODEL ] = model;
				}
				case 5:
				{
					new
						Float: speed;

					if ( sscanf( inputtext, "f", speed ) )
					{
						SendError( playerid, "This value must be numerical." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					g_gateData[ gID ] [ E_SPEED ] = speed;
				}
				case 6:
				{
					new
						Float: range;

					if ( sscanf( inputtext, "f", range ) )
					{
						SendError( playerid, "This value must be numerical." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					else if ( ! ( 1.0 <= range <= 100.0 ) )
					{
						SendError( playerid, "Please specify a range between 1.0 and 100.0 metres." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					g_gateData[ gID ] [ E_RANGE ] = range;
				}
				case 7:
				{
					new
						time;

					if ( sscanf( inputtext, "d", time ) )
					{
						SendError( playerid, "This value must be numerical." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					else if ( time < 100 || time > 60000 )
					{
						SendError( playerid, "This value must be between 100 and 60000 miliseconds." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					g_gateData[ gID ] [ E_TIME ] = time;
				}
				case 8:
				{
					new
						sql_id;

					if ( sscanf( inputtext, "d", sql_id ) )
					{
						SendError( playerid, "This value must be numerical." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					else if ( ! ( 0 <= sql_id < 1000000 ) )
					{
						SendError( playerid, "Invalid Gang ID specified." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gate - Edit", ""COL_WHITE"Value to replace with:", "Commit", "Back" );
					}
					g_gateData[ gID ] [ E_GANG_SQL_ID ] = sql_id;
					mysql_single_query( sprintf( "UPDATE `GATES` SET `GANG_ID`=%d WHERE `ID`=%d", sql_id, gID ) );
				}
			}
			UpdateGateData( gID );
			Streamer_Update( playerid );
			cmd_editgate( playerid, sprintf( "%d", gID ) );
			SendServerMessage( playerid, "You have successfully updated this gate." );
		}
		else cmd_editgate( playerid, sprintf( "%d", gID ) );
	}
	if ( ( dialogid == DIALOG_VIP ) && response )
	{
		if ( strlen( inputtext ) != 16 )
		{
			cmd_donated( playerid, "" );
			return SendError( playerid, "The transaction ID you entered is invalid." );
		}

		if ( g_redeemVipWait > g_iTime )
		{
			cmd_donated( playerid, "" );
			return SendServerMessage( playerid, "Our anti-exploit system requires you to wait another %d seconds before redeeming.", g_redeemVipWait - g_iTime );
		}

		HTTP( playerid, HTTP_GET, sprintf( "donate.sfcnr.com/validate_code/%s", inputtext ), "", "OnDonationRedemptionResponse" );
		SendServerMessage( playerid, "We're now looking up this transaction. Please wait." );
	}
	if ( dialogid == DIALOG_DONATED )
	{
		szLargeString[ 0 ] = '\0';
		strcat( szLargeString,	""COL_WHITE"Thank you a lot for donating! :D In return for your dignity, you have received Irresistible Coins.\n\n"\
								""COL_GREY" * What do I do with Irresistible Coins?"COL_WHITE" You can claim the V.I.P of your choice via "COL_GREY"/irresistiblecoins market"COL_WHITE".\n" );
		strcat( szLargeString,	""COL_GREY" * How many do I have?"COL_WHITE" You can see how many Irresistible Coins you have via "COL_GREY"/irresistiblecoins"COL_WHITE".\n" \
								""COL_GREY" * I'm unsure, help?"COL_WHITE" If you have any questions, please /ask otherwise enquire Lorenc via the forums!\n\nThank you once again for your contribution to our community! :P"  );
		return ShowPlayerDialog( playerid, DIALOG_FINISHED_DONATING, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", szLargeString, "Got it!", "" );
	}
	if ( dialogid == DIALOG_FINISHED_DONATING ) {
		return ShowPlayerDialog( playerid, DIALOG_LATEST_DONOR, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"Would you like to be shown as the latest donor?", "Yes", "No" );
	}
	if ( dialogid == DIALOG_LATEST_DONOR ) {
		if ( GetPVarType( playerid, "just_donated" ) != PLAYER_VARTYPE_FLOAT )
			return SendError( playerid, "Seems to be an issue where we couldn't find how much you donated. Report to Lorenc." );

		new
			Float: fAmount = GetPVarFloat( playerid, "just_donated" );

		DeletePVar( playerid, "just_donated" );
		return UpdateGlobalDonated( playerid, fAmount, !response );
	}
	/*if ( dialogid == DIALOG_DONATED_PLATBRONZE )
	{
		if ( response )
		{
			new
				pID;

			if ( sscanf( inputtext, "u", pID ) )
			{
				SendError( playerid, "Please enter a player's ID or name." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Platinum V.I.P, you have the option of gifting Bronze VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else if ( !IsPlayerConnected( pID ) )
			{
				SendError( playerid, "This player is not connected." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Platinum V.I.P, you have the option of gifting Bronze VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[V.I.P]"COL_WHITE" You have gifted Bronze V.I.P to %s(%d)!", ReturnPlayerName( pID ), pID );
				SetPlayerVipLevel( pID, VIP_BRONZE );
				ShowPlayerVipRedeemedDialog( playerid );
			}
		}
		else
		{
	 		AddPlayerNote( playerid, -1, "{CD7F32}Bronze V.I.P" #COL_WHITE );
			SendServerMessage( playerid, "Okay. This has been noted down for your account and will be given to you at a stage that you want, do contact Lorenc though." );
			ShowPlayerVipRedeemedDialog( playerid );
		}
	}*/
	/*if ( dialogid == DIALOG_DONATED_DIAGOLD )
	{
		if ( response )
		{
			new
				pID;

			if ( sscanf( inputtext, "u", pID ) )
			{
				SendError( playerid, "Please enter a player's ID or name." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Diamond V.I.P, you have the option of gifting Gold VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else if ( !IsPlayerConnected( pID ) )
			{
				SendError( playerid, "This player is not connected." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Diamond V.I.P, you have the option of gifting Gold VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[V.I.P]"COL_WHITE" You have gifted Gold V.I.P to %s(%d)!", ReturnPlayerName( pID ), pID );
				SetPlayerVipLevel( pID, VIP_GOLD );
				ShowPlayerVipRedeemedDialog( playerid );
			}
		}
		else
		{
	 		AddPlayerNote( playerid, -1, ""COL_GOLD"Gold V.I.P" #COL_WHITE );
			SendServerMessage( playerid, "Okay. This has been noted down for your account and will be given to you at a stage that you want, do contact Lorenc though." );
			ShowPlayerVipRedeemedDialog( playerid );
		}
	}*/
	if ( ( dialogid == DIALOG_UNBAN_CLASS ) && response )
	{
		cmd_unbanme( playerid, "" );
		switch( listitem )
		{
			case 0:
			{
				if ( !( p_ArmyBanned{ playerid } >= MAX_CLASS_BAN_WARNS ) )
					return SendError( playerid, "You have nothing to pay as you are not army-banned." );

				if ( GetPlayerCash( playerid ) < 750000 )
					return SendError( playerid, "You are insufficient of funds to cover the unban ($750,000)." );

				p_ArmyBanned{ playerid } = 0;
				GivePlayerCash( playerid, -750000 );
				UpdateServerVariable( "eventbank", GetGVarInt( "eventbank" ) + 250000, 0.0, "", GLOBAL_VARTYPE_INT );

				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `ARMY_BAN`=0 WHERE ID=%d", p_AccountID[ playerid ] );
				mysql_single_query( szNormalString );

			    SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s(%d) has paid his un-army-ban.", ReturnPlayerName( playerid ), playerid );
			}
			case 1:
			{
				if ( !( p_CopBanned{ playerid } >= MAX_CLASS_BAN_WARNS ) )
					return SendError( playerid, "You have nothing to pay as you are not cop-banned." );

				if ( GetPlayerCash( playerid ) < 500000 )
					return SendError( playerid, "You are insufficient of funds to cover the unban ($500,000)." );

				p_CopBanned{ playerid } = 0;
				GivePlayerCash( playerid, -500000 );
				UpdateServerVariable( "eventbank", GetGVarInt( "eventbank" ) + 170000, 0.0, "", GLOBAL_VARTYPE_INT );

				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `COP_BAN`=0 WHERE ID=%d", p_AccountID[ playerid ] );
				mysql_single_query( szNormalString );

			    SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s(%d) has paid his un-cop-ban.", ReturnPlayerName( playerid ), playerid );
			}
		}
	}
	if ( dialogid == DIALOG_VIP_NOTE && response )
	{
		SendClientMessageToAdmins( -1, ""COL_PINK"[DONOR NEEDS HELP]"COL_GREY" %s(%d) is requesting help with their VIP asset(s). (/viewnotes)", ReturnPlayerName( playerid ), playerid );
		SendServerMessage( playerid, "All admins online have been informed of your request." );
	}
	if ( ( dialogid == DIALOG_FEEDBACK ) && response )
	{
		if ( ! ( 10 < strlen( inputtext ) <= 512 ) )
		{
			SendError( playerid, "Your feedback must be between 10 and 512 characters long." );
			return ShowPlayerDialog( playerid, DIALOG_FEEDBACK, DIALOG_STYLE_INPUT, ""COL_GOLD"Server Feedback", ""COL_WHITE"Let us know how you think we can make the server better to play! Impactful feedback is rewarded.\n\n    Be as serious and straight forward as you wish. You can rant if you need to. Be impactful.\n\n"COL_RED"Your feedback must be between 10 and 512 characters long.", "Submit", "Close" );
		}

		new
			szFeedback[ 512 ];

		// escape feedback
		mysql_real_escape_string( inputtext, szFeedback );

		// insert into database
		format( szLargeString, sizeof( szLargeString ), "INSERT INTO `FEEDBACK` (`USER_ID`, `FEEDBACK`) VALUES (%d, '%s')", p_AccountID[ playerid ], szFeedback );
		mysql_single_query( szLargeString );

		format( szLargeString, sizeof( szLargeString ), ""COL_GOLD"Thank you for your feedback!"COL_WHITE" If it can make a positive impact on the server then you will be rewarded.\n\nYou can speak as freely as you want. Be vulgar, serious if you need to. It's okay as long as it's constructive.\n\nHere is what you have submitted!\n\n"COL_GREY"%s", szFeedback );
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"Server Feedback", szLargeString, "Close", "" );
	}
	if ( ( dialogid == DIALOG_RACE ) && response )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		switch ( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_RACE_MODE, DIALOG_STYLE_TABLIST, ""COL_GOLD"Race Configuration - Race Mode", ""COL_GREY"Street Race\t"COL_WHITE"Racers must meet the final destination\n"COL_GREY"Outrun"COL_WHITE"\tRacer must outrun everyone by 100 metres", "Select", "Close" );
			case 1: ShowPlayerDialog( playerid, DIALOG_RACE_FEE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Entry Fee", ""COL_WHITE"Specify the required entry fee for this race (minimum $1,000 - max $10,000,000)", "Specify", "Close" );
			case 2: ShowPlayerDialog( playerid, DIALOG_RACE_POS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Prize Distribution", ""COL_WHITE"1st Position\t"COL_WHITE"2nd Position\t"COL_WHITE"3rd Position\n100%\t0%\t0%\n90%\t5%\t5%\n80%\t10%\t10%\n70%\t15%\t15%\n60%\t20%\t20%\n", "Select", "Close" );
			case 3:
			{
				if ( g_raceData[ raceid ] [ E_MODE ] == RACE_OUTRUN )
					return ShowPlayerDialog( playerid, DIALOG_RACE_DISTANCE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Outrun Distance", ""COL_WHITE"Specify the required outrun distance (minimum 10.0m - max 250.0m)", "Specify", "Close" );

				return ShowPlayerDialog( playerid, DIALOG_RACE_DEST, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Destination", ""COL_WHITE""COL_WHITE"How do you want to set the final destination?\nPreset Destinations\nSelect Using Minimap\nUse Coordinates", "Select", "Back" );
			}
			case 4:
			{
				erase( szLargeString );

				foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid && g_raceData[ raceid ] [ E_LOBBY_HOST ] != i ) {
					format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\n", szLargeString, ReturnPlayerName( i ), i );
				}

				if ( strlen( szLargeString ) ) {
					return ShowPlayerDialog( playerid, DIALOG_RACE_KICK, DIALOG_STYLE_LIST, ""COL_GOLD"Race Configuration - Player Management", szLargeString, "Kick", "Back" );
				} else {
					SendError( playerid, "There are no racers to show." );
					return ShowRaceConfiguration( playerid, raceid );
				}
			}
		}
	}
	if ( dialogid == DIALOG_RACE_DEST )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowRaceConfiguration( playerid, raceid );

		switch ( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_RACE_PRESELECT, DIALOG_STYLE_LIST, ""COL_GOLD"Race Configuration - Destination", "LS Airport\nLS Pier\nLS Grove Street\nLV Airport\nLV Old Strip\nEl Quebrados\nSF Airport\nMount Chilliad\nTierra Robada SF Bridge\nSF Dealership", "Select", "Back" );
			case 1:
			{
				g_raceData[ raceid ] [ E_RACE_FINISH_SET ] = 2;
				g_raceData[ raceid ] [ E_FINISH_POS ] [ 0 ] = 0.0;
				g_raceData[ raceid ] [ E_FINISH_POS ] [ 1 ] = 0.0;
				g_raceData[ raceid ] [ E_FINISH_POS ] [ 2 ] = 0.0;
				return SendServerMessage( playerid, "You are now setting the race destination. Use the MINIMAP to pick the finish position." );
			}
			case 2: ShowPlayerDialog( playerid, DIALOG_RACE_CUSTOM_DEST, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Custom Destination", ""COL_WHITE"Please specify the final destination coordinates, seperated by white spaces. E.g 0.0 0.0 0.0", "Set", "Back" );
		}
		return 1;
	}
	if ( dialogid == DIALOG_RACE_CUSTOM_DEST )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowPlayerDialog( playerid, DIALOG_RACE_DEST, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Destination", ""COL_WHITE""COL_WHITE"How do you want to set the final destination?\nPreset Destinations\nSelect Using Minimap\nUse Coordinates", "Select", "Back" );

		new
			Float: X, Float: Y, Float: Z;

		if ( sscanf( inputtext, "fff", X, Y, Z ) ) {
			SendError( playerid, "Make sure coordinates are seperated by white spaces and are numbers (e.g 0.0 0.0 0.0)" );
			return ShowPlayerDialog( playerid, DIALOG_RACE_CUSTOM_DEST, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Custom Destination", ""COL_WHITE"Please specify the final destination coordinates, seperated by white spaces. E.g 0.0 0.0 0.0", "Set", "Back" );
		}

		SetRaceDestination( raceid, X, Y, Z );
		SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has set the race final destination to %0.4f %0.4f %0.4f.", ReturnPlayerName( playerid ), playerid, X, Y, Z );
		return 1;
	}
	if ( dialogid == DIALOG_RACE_PRESELECT )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowPlayerDialog( playerid, DIALOG_RACE_DEST, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration - Destination", ""COL_WHITE""COL_WHITE"How do you want to set the final destination?\nPreset Destinations\nSelect Using Minimap\nUse Coordinates", "Select", "Back" );

		SetRaceDestination( raceid, g_raceFinalDestinations[ listitem ] [ E_X ], g_raceFinalDestinations[ listitem ] [ E_Y ], g_raceFinalDestinations[ listitem ] [ E_Z ] );
		SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has set the race final destination to %s.", ReturnPlayerName( playerid ), playerid, g_raceFinalDestinations[ listitem ] [ E_NAME ] );
		return 1;
	}
	if ( dialogid == DIALOG_RACE_KICK )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		ShowRaceConfiguration( playerid, raceid );

		if ( ! response )
			return 1;

		new
			x = 0;

		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid && g_raceData[ raceid ] [ E_LOBBY_HOST ] != i )
		{
	       	if ( x == listitem )
	      	{
		  		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has been kicked from the race.", ReturnPlayerName( i ), i );
		  		RemovePlayerFromRace( i );
	      		return 1;
			}
	      	x++;
		}
		return SendError( playerid, "There was an error trying to remove this player from the race." );
	}
	if ( dialogid == DIALOG_RACE_MODE )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( response )
		{
			g_raceData[ raceid ] [ E_MODE ] = listitem;
			SendServerMessage( playerid, "You have set the race mode to "COL_GREY"%s"COL_WHITE".", g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE ? ( "Streetrace" ) : ( "Outrun" ) );
		}
		return ShowRaceConfiguration( playerid, raceid );
	}
	if ( dialogid == DIALOG_RACE_DISTANCE )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowRaceConfiguration( playerid, raceid );

		new
			Float: distance;

		if ( sscanf( inputtext, "f", distance ) || ! ( 10.0 <= distance <= 300.0 ) ) {
			SendError( playerid, "Please specify a race distance between 10.0m and 300.0m." );
			return ShowPlayerDialog( playerid, DIALOG_RACE_DISTANCE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Outrun Distance", ""COL_WHITE"Specify the required outrun distance (minimum 10.0m - max 250.0m)", "Specify", "Close" );
		}

		g_raceData[ raceid ] [ E_OUTRUN_DISTANCE ] = distance;
		SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The outrun distance has been set to %0.1f metres.", distance );
		return ShowRaceConfiguration( playerid, raceid );
	}
	if ( dialogid == DIALOG_RACE_FEE )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( ! response )
			return ShowRaceConfiguration( playerid, raceid );

		new
			fee;

		if ( sscanf( inputtext, "d", fee ) || ! ( 0 <= fee <= 10000000 ) ) {
			SendError( playerid, "Please specify an entry fee between $0 and $10,000,000." );
			return ShowPlayerDialog( playerid, DIALOG_RACE_FEE, DIALOG_STYLE_INPUT, ""COL_GOLD"Race Configuration - Entry Fee", ""COL_WHITE"Specify the required entry fee for this race (minimum $1,000 - max $10,000,000)", "Specify", "Close" );
		}

		g_raceData[ raceid ] [ E_ENTRY_FEE ] = fee;
		SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" The entry fee for the race has been set to %s.", cash_format( fee ) );
		return ShowRaceConfiguration( playerid, raceid );
	}
	if ( dialogid == DIALOG_RACE_POS )
	{
		new
			raceid = GetPVarInt( playerid, "editing_race" );

		if ( ! IsRaceHost( playerid, raceid ) )
			return SendError( playerid, "You are not the host of this lobby." );

		if ( response )
		{
			static const
				Float: g_prizePoolDistribution[ ] [ 3 ] =
				{
					{ 1.0, 0.0, 0.0 },
					{ 0.9, 0.05, 0.05 },
					{ 0.8, 0.1, 0.1 },
					{ 0.7, 0.15, 0.15 },
					{ 0.6, 0.2, 0.2 }
				}
			;

			// position prize
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] = g_prizePoolDistribution[ listitem ] [ 0 ];
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ] = g_prizePoolDistribution[ listitem ] [ 1 ];
			g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ] = g_prizePoolDistribution[ listitem ] [ 2 ];

			// alert
			SendServerMessage( playerid, "The prize pool distribution is now %0.0f%% for 1st, %0.0f%% for 2nd and %0.0f%% for 3rd place.", 100.0 * g_prizePoolDistribution[ listitem ] [ 0 ], 100.0 * g_prizePoolDistribution[ listitem ] [ 1 ], 100.0 * g_prizePoolDistribution[ listitem ] [ 2 ] );
		}
		return ShowRaceConfiguration( playerid, raceid );
	}
	if ( dialogid == DIALOG_AIRPORT && response )
	{
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot travel while you're in jail." );
		if ( p_WantedLevel[ playerid ] ) return SendError( playerid, "You cannot travel while you are wanted." );
		if ( GetPlayerCash( playerid ) < 2000 ) return SendError( playerid, "You need $2,000 to travel between cities." );

		new bool: using_rewards = p_CasinoRewardsPoints[ playerid ] > 5.0;

		// set position
		switch ( listitem )
		{
			case 0: {
				if ( IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AIRPORT_SF ] ) ) return SendError( playerid, "You're already in San Fierro." );
				SendServerMessage( playerid, "It has cost you "COL_GOLD"%s"COL_WHITE" to travel. Welcome to San Fierro!", using_rewards ? ( "5 casino reward points" ) : ( "$2,000" ) );
				SetPlayerPos( playerid, -1422.4063, -286.5081, 14.1484 );
			}
			case 1: {
				if ( IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AIRPORT_LV ] ) ) return SendError( playerid, "You're already in Las Venturas." );
				SendServerMessage( playerid, "It has cost you "COL_GOLD"%s"COL_WHITE" to travel. Welcome to Las Venturas!", using_rewards ? ( "5 casino reward points" ) : ( "$2,000" ) );
				SetPlayerPos( playerid, 1672.5364, 1447.8616, 10.7881 );
			}
			case 2: {
				if ( IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AIRPORT_LS ] ) ) return SendError( playerid, "You're already in Los Santos." );
				SendServerMessage( playerid, "It has cost you "COL_GOLD"%s"COL_WHITE" to travel. Welcome to Los Santos!", using_rewards ? ( "5 casino reward points" ) : ( "$2,000" ) );
				SetPlayerPos( playerid, 1642.2274, -2335.4978, 13.5469 );
			}
		}

		// check for rewards
		if ( using_rewards ) {
			p_CasinoRewardsPoints[ playerid ] -= 5.0;
			mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS`=%f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
		}
		else GivePlayerCash( playerid, -2000 );

		// set interior/world
		SetPlayerVirtualWorld( playerid, 0 );
		SetPlayerInterior( playerid, 0 );
		PlayerPlaySound( playerid, 0, 0.0, 0.0, 0.0 );
	}
	if ( dialogid == DIALOG_SPAWN && response )
	{
		new bool: has = false;

		// erase large string for ease
		erase( szLargeString );

		// show items
		switch ( listitem )
		{
			// reset spawn
			case 0:
			{
				ResetSpawnLocation( playerid );
				return SendServerMessage( playerid, "You have reset your spawning location to default." );
			}

			// houses
			case 1:
			{
				foreach ( new i : houses ) if ( strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) {
					format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, g_houseData[ i ] [ E_HOUSE_NAME ] ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "You do not own any home." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_HOUSES, DIALOG_STYLE_LIST, "{FFFFFF}Set Spawn Location", szLargeString, "Select", "Back" );
			}

			// businesses
			case 2:
			{
				foreach ( new b : business ) if ( IsBusinessAssociate( playerid, b ) ) {
					format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, g_businessData[ b ] [ E_NAME ] ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "You do not own any business." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_BUSINESSES, DIALOG_STYLE_LIST, "{FFFFFF}Business Spawn Location", szLargeString, "Select", "Back" );
			}

			// gang facility
			case 3:
			{
				new gangid = p_GangID[ playerid ];

				if ( gangid == INVALID_GANG_ID )
					return SendError( playerid, "You are not in any gang." ), ShowPlayerSpawnMenu( playerid );

				static city[ MAX_ZONE_NAME ], location[ MAX_ZONE_NAME ];

				szLargeString = ""COL_WHITE"City\t"COL_WHITE"Zone\n";

				foreach ( new handle : gangfacilities ) if ( g_gangData[ gangid ] [ E_SQL_ID ] == g_gangFacilities[ handle ] [ E_GANG_SQL_ID ] )
				{
					new Float: min_x, Float: min_y;
					new zoneid = g_gangFacilities[ handle ] [ E_TURF_ID ];

					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_X, min_x );
					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_Y, min_y );

				    Get2DCity( city, min_x, min_y );
				    GetZoneFromCoordinates( location, min_x, min_y );

					format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, city, location ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "Your gang does not own a gang facility." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_FACILITY_SPAWN, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Gang Facility Spawn Location", szLargeString, "Select", "Back" );
			}

			// visage apartment
			case 4:
			{
				foreach ( new handle : visageapartments ) if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] == p_AccountID[ playerid ] ) {
					format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, g_VisageApartmentData[ handle ] [ E_TITLE ] ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "You do not own any visage apartment." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_VISAGE_SPAWN, DIALOG_STYLE_LIST, "{FFFFFF}Visage Spawn Location", szLargeString, "Select", "Back" );
			}
		}
	}
	if ( dialogid == DIALOG_FACILITY_SPAWN )
	{
		if ( ! response )
			return ShowPlayerSpawnMenu( playerid );

		new gangid = p_GangID[ playerid ];

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "You are not in any gang." ), ShowPlayerSpawnMenu( playerid );

		static city[ MAX_ZONE_NAME ], location[ MAX_ZONE_NAME ];

		szLargeString = ""COL_WHITE"City\t"COL_WHITE"Location\n";

		new x = 0;

		foreach ( new handle : gangfacilities ) if ( g_gangData[ gangid ] [ E_SQL_ID ] == g_gangFacilities[ handle ] [ E_GANG_SQL_ID ] )
		{
			if ( x == listitem )
			{
				new Float: min_x, Float: min_y;
				new zoneid = g_gangFacilities[ handle ] [ E_TURF_ID ];

				Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_X, min_x );
				Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_Y, min_y );

			    Get2DCity( city, min_x, min_y );
			    GetZoneFromCoordinates( location, min_x, min_y );

        		SetPlayerSpawnLocation( playerid, "GNG", handle );
			 	SendServerMessage( playerid, "Spawning has been set the gang facility located in "COL_GREY"%s, %s"COL_WHITE".", location, city );
			 	break;
			}
			x ++;
		}
		return 1;
	}
	if ( dialogid == DIALOG_HIGHSCORES && response )
	{
		switch ( listitem )
		{
			// seasonal
			case 0: mysql_function_query( dbHandle, "SELECT `NAME`, `RANK` as `SCORE_VAL` FROM `USERS` ORDER BY `RANK` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 0 );

			// total score
			case 1: mysql_function_query( dbHandle, "SELECT `NAME`, `SCORE` as `SCORE_VAL` FROM `USERS` ORDER BY `SCORE` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 1 );

			// total kills
			case 2: mysql_function_query( dbHandle, "SELECT `NAME`, `KILLS` as `SCORE_VAL` FROM `USERS` ORDER BY `KILLS` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 2 );

			// total arrests
			case 3: mysql_function_query( dbHandle, "SELECT `NAME`, `ARRESTS` as `SCORE_VAL` FROM `USERS` ORDER BY `ARRESTS` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 3 );

			// total robberies
			case 4: mysql_function_query( dbHandle, "SELECT `NAME`, `ROBBERIES` as `SCORE_VAL` FROM `USERS` ORDER BY `ROBBERIES` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 4 );

			// hits completed
			case 5: mysql_function_query( dbHandle, "SELECT `NAME`, `CONTRACTS` as `SCORE_VAL` FROM `USERS` ORDER BY `CONTRACTS` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 5 );

			// fires
			case 6: mysql_function_query( dbHandle, "SELECT `NAME`, `FIRES` as `SCORE_VAL` FROM `USERS` ORDER BY `FIRES` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 6 );

			// burglaries
			case 7: mysql_function_query( dbHandle, "SELECT `NAME`, `BURGLARIES` as `SCORE_VAL` FROM `USERS` ORDER BY `BURGLARIES` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 7 );

			// blown jails
			case 8: mysql_function_query( dbHandle, "SELECT `NAME`, `BLEW_JAILS` as `SCORE_VAL` FROM `USERS` ORDER BY `BLEW_JAILS` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 8 );

			// blown vaults
			case 9: mysql_function_query( dbHandle, "SELECT `NAME`, `BLEW_VAULT` as `SCORE_VAL` FROM `USERS` ORDER BY `BLEW_VAULT` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 9 );

			// vehicles jacked
			case 10: mysql_function_query( dbHandle, "SELECT `NAME`, `VEHICLES_JACKED` as `SCORE_VAL` FROM `USERS` ORDER BY `VEHICLES_JACKED` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 10 );

			// meth yielded
			case 11: mysql_function_query( dbHandle, "SELECT `NAME`, `METH_YIELDED` as `SCORE_VAL` FROM `USERS` ORDER BY `METH_YIELDED` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 11 );

			// total trucked cargo
			case 12: mysql_function_query( dbHandle, "SELECT `NAME`, `TRUCKED` as `SCORE_VAL` FROM `USERS` ORDER BY `TRUCKED` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 12 );

			// pilot missons
			case 13: mysql_function_query( dbHandle, "SELECT `NAME`, `PILOT` as `SCORE_VAL` FROM `USERS` ORDER BY `PILOT` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 13 );

			// train missions
			case 14: mysql_function_query( dbHandle, "SELECT `NAME`, `TRAIN` as `SCORE_VAL` FROM `USERS` ORDER BY `TRAIN` DESC LIMIT 25", true, "OnHighScoreCheck", "ii", playerid, 14 );
		}
	}
	if ( dialogid == DIALOG_HIGHSCORES_BACK && ! response ) {
		return ShowPlayerDialog( playerid, DIALOG_HIGHSCORES, DIALOG_STYLE_LIST, "{FFFFFF}Highscores", "Seasonal Rank\nTotal Score\nTotal Kills\nTotal Arrests\nTotal Robberies\nHits Completed\nFires Extinguished\nBurglaries\nBlown Jails\nBlown Vaults\nVehicles Jacked\nMeth Yielded\nTotal Trucked Cargo\nTotal Pilot Missions\nTotal Train Missions", "Select", "Close" );
	}
	return 1;
}

thread OnHighScoreCheck( playerid, highscore_item )
{
	new
		rows;

	cache_get_data( rows, tmpVariable );

	if ( ! rows ) {
		return SendError( playerid, "There is no information to show. Try again later." );
	}

	new
		name[ MAX_PLAYER_NAME ];

	switch ( highscore_item )
	{
		case 0:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Seasonal Rank\n", szSmallString = "Top 25 Seasonal";
		case 1:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Score\n", szSmallString = "Top 25 Score";
		case 2:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Kills\n", szSmallString = "Top 25 Kills";
		case 3:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Arrests\n", szSmallString = "Top 25 Arrests";
		case 4:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Robberies\n", szSmallString = "Top 25 Robberies";
		case 5:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Contracts\n", szSmallString = "Top 25 Hits Completed";
		case 6:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Fires\n", szSmallString = "Top 25 Fires Extinguished";
		case 7:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Burglaries\n", szSmallString = "Top 25 Burglaries";
		case 8:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Jailes\n", szSmallString = "Top 25 Blown Jails";
		case 9:  szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Vaults\n", szSmallString = "Top 25 Blown Vaults";
		case 10: szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Vehicles\n", szSmallString = "Top 25 Vehicles Jacked";
		case 11: szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Meth\n", szSmallString = "Top 25 Meth Yielded";
		case 12: szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Trucked\n", szSmallString = "Top 25 Total Trucked Cargo";
		case 13: szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Missions\n", szSmallString = "Top 25 Total Pilot Missions";
		case 14: szLargeString = ""COL_GOLD"Player\t"COL_GOLD"Missions\n", szSmallString = "Top 25 Total Train Missions";
	}

	for ( new row = 0; row < rows; row ++ )
	{
		// get name
		cache_get_field_content( row, "NAME", name );

		// format item appropriately
		switch ( highscore_item )
		{
			case 0:
			{
				new Float: score_value = cache_get_field_content_float( row, "SCORE_VAL", dbHandle );
				new rank = GetRankFromXP( score_value );

				format( szLargeString, sizeof( szLargeString ), "%s%s%s\t{%06x}%s\n", szLargeString, strmatch( name, ReturnPlayerName( playerid ) ) ? COL_GREEN : COL_WHITE, name, GetSeasonalRankColour( rank ) >>> 8, GetSeasonalRankName( rank ) );
			}
			default:
			{
				new
					score_value = cache_get_field_content_int( row, "SCORE_VAL", dbHandle );

				format( szLargeString, sizeof( szLargeString ), "%s%s%s\t%d\n", szLargeString, strmatch( name, ReturnPlayerName( playerid ) ) ? COL_GREEN : COL_WHITE, name, score_value );
			}
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_HIGHSCORES_BACK, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}Highscores - %s", szSmallString ), szLargeString, "Close", "Back" ), 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	new
		raceid = GetPVarInt( playerid, "editing_race" );

	if ( IsRaceHost( playerid, raceid ) )
	{
		if ( g_raceData[ raceid ] [ E_RACE_FINISH_SET ] == 2 )
		{
			new
				Float: nodeX, Float: nodeY, Float: nodeZ,
				nodeid = NearestNodeFromPoint( fX, fY, fZ )
			;

			GetNodePos( nodeid, nodeX, nodeY, nodeZ );

			// set destination
			SetRaceDestination( raceid, nodeX, nodeY, nodeZ + 1.0 );

			// alert
			ShowRaceConfiguration( playerid, raceid );
			SendServerMessage( playerid, "You have selected the final destination for the race, use "COL_GREY"/race start"COL_WHITE" to begin." );
		}
	}
	else if ( IsPlayerAdminOnDuty( playerid ) )
	{
    	SetPlayerPosFindZ( playerid, fX, fY, fZ );
		printf( "Admin %s Teleported To %f, %f, %f", ReturnPlayerName( playerid ), fX, fY, fZ );
	}
	return 1;
}

stock ShowPlayerVipRedeemedDialog( playerid )
{
	szLargeString[ 0 ] = '\0';
	strcat( szLargeString,	""COL_WHITE"You've just blew quite a bit of Irresistible Coins for your V.I.P, so congratulations! :D\n\n"\
							""COL_GREY" * What are the commands?"COL_WHITE" Use /vipcmds to view a detailed list of VIP commands.\n"\
							""COL_GREY" * What did I receive?"COL_WHITE" Check through your V.I.P package contents via our site (forum -> announcements board).\n" );
	strcat( szLargeString,	""COL_GREY" * How to redeem my houses/vehicles?"COL_WHITE" You will be announced to the admins and noted down for assistance, so please wait!\n"\
							""COL_GREY" * I'm unsure, help?"COL_WHITE" If you have any questions, please /ask otherwise enquire Lorenc via the forums!\n\nThanks for choosing to spend your Irresistible Coins, enjoy what you've got! :P"  );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", szLargeString, "Got it!", "" );
}

thread OnFetchCategoryResponse( playerid, category )
{
	new
		rows, fields, i = 0;

	cache_get_data( rows, fields );
	if ( rows )
	{
		new
			szCategory[ 64 ];

		erase( szLargeString );
		erase( szBigString );

		while( i < rows )
		{
			cache_get_field_content( i, "SUBJECT", szCategory );
			format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, szCategory );

			cache_get_field_content( i, "ID", szCategory );
			format( szBigString, sizeof( szBigString ), "%s %d", szBigString, strval( szCategory ) );

			i++;
		}

		SetPVarString( playerid, "help_ids", szBigString );
		ShowPlayerDialog( playerid, DIALOG_HELP_CATEGORY, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", szLargeString, "Select", "Back" );
	}
	else ShowPlayerDialog( playerid, DIALOG_HELP_BACK, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", "{FF0000}There are no threads available.", "Close", "Back" );
	return 1;
}

/*public OnFetchThreadData( playerid, category, thread );
public OnFetchThreadData( playerid, category, thread )
{
	new
		rows, fields;

	cache_get_data( rows, fields );
	if ( rows )
	{
		static
	        RegEx: rCIP,
			szSubject[ 64 ],
			szContent[ 2048 ]
		;

		cache_get_field_content( 0, "CONTENT", szContent, dbHandle, sizeof( szContent ) );
		cache_get_field_content( 0, "SUBJECT", szSubject );

		strins( szSubject, "{FFFFFF}", 0 );
		strins( szContent, "{FFFFFF}", 0 );


	    if ( !rCIP )
	  		rCIP = regex_build( "(?i)<[^>]*>" );

		regex_replace_exid( szContent, rCIP, "&nbsp;", szContent, sizeof( szContent ) );
		strreplace( szContent, "&nbsp;", "" );
		strreplace( szContent, "&amp;", "" );
		strreplace( szContent, "&#39;", "" );

		ShowPlayerDialog( playerid, DIALOG_HELP_THREAD, DIALOG_STYLE_MSGBOX, szSubject, szContent, "Close", "Back" );
	}
	else ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", "{FFFFFF}An error has occurred. Try again later.", "Okay", "" );
	return 1;
}*/

public OnHelpHTTPResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 ) //Did the request succeed?
		ShowPlayerDialog( index, DIALOG_HELP_THREAD, DIALOG_STYLE_MSGBOX, "{FFFFFF}Help Topics", data, "Close", "Back" );
	else
		ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", "{FFFFFF}An error has occurred. Try again later.", "Okay", "" );
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

/////////////////////////
//      Functions      //
/////////////////////////

stock SetServerRule( rule[ ], value[ ] )
{
	new string[ 80 ];
	format( string, sizeof( string ), "%s %s", rule, value );
	SendRconCommand( string );
}

/*stock ReturnPlayerName( playerid )
{
	GetPlayerName( playerid, szSmallString, MAX_PLAYER_NAME );
	if ( !IsPlayerConnected( playerid ) ) szSmallString = "No-one";
	return szSmallString;
}*/

stock SetPlayerPosToPrison( playerid )
{
	static const
		Float: sf_JailSpawnPoints[ ][ 3 ] =
		{
			{ 215.5644, 110.7332, 999.0156 },
			{ 219.4913, 110.9124, 999.0156 },
			{ 223.4386, 111.0879, 999.0156 },
			{ 227.4427, 111.2414, 999.0156 }
		},

		Float: lv_JailSpawnPoints[ ] [ 3 ] =
		{
			{ 198.6733, 162.2922, 1003.0300 },
			{ 197.4023, 174.4845, 1003.0234 },
			{ 193.2059, 174.6152, 1003.0234 }
		},

		Float: ls_JailSpawnPoints[ ] [ 3 ] =
		{
			{ 264.3201, 86.4325, 1001.0391 },
			{ 264.3130, 81.8108, 1001.0391 },
			{ 264.5371, 77.7982, 1001.0391 }
		},

		Float: alctrazSpawnPoints[ ] [ 3 ] =
		{
			{ -2005.1923, 1748.1976, 43.7386 },
			{ -2013.7557, 1783.2218, 43.7386 },
			{ -2049.5774, 1734.1851, 43.7386 }
		},

		Float: loadingHeight = 0.50
	;

	new
		iRandom;

	jailDoors				( playerid, false, true );
    SetPlayerFacingAngle 	( playerid, 0.0 );
	TogglePlayerControllable( playerid, 0 );
 	SetPlayerVirtualWorld 	( playerid, 30 );
	SetTimerEx 				( "ope_Unfreeze", 5000, false, "d", playerid );
	p_inAlcatraz 			{ playerid } = false;

	if ( p_JailTime[ playerid ] >= ALCATRAZ_REQUIRED_TIME )
	{
	    iRandom = random( sizeof( alctrazSpawnPoints ) );
	    SetPlayerPos 			( playerid, alctrazSpawnPoints[ iRandom ][ 0 ], alctrazSpawnPoints[ iRandom ][ 1 ], alctrazSpawnPoints[ iRandom ][ 2 ] + loadingHeight );
	 	SetPlayerInterior		( playerid, 0 );
	 	SetPlayerVirtualWorld 	( playerid, 0 );
		p_AlcatrazEscapeTS 		[ playerid ] = g_iTime + ALCATRAZ_TIME_PAUSE;
		p_inAlcatraz 			{ playerid } = true;
		return 1;
	}

	switch( getClosestPoliceStation( playerid ) )
	{
		case CITY_LV:
		{
		    iRandom = random( sizeof( lv_JailSpawnPoints ) );
		    SetPlayerPos( playerid, lv_JailSpawnPoints[ iRandom ][ 0 ], lv_JailSpawnPoints[ iRandom ][ 1 ], lv_JailSpawnPoints[ iRandom ][ 2 ] + loadingHeight );
		 	SetPlayerInterior( playerid, 3 );
		}
		case CITY_LS:
		{
		    iRandom = random( sizeof( ls_JailSpawnPoints ) );
		    SetPlayerPos( playerid, ls_JailSpawnPoints[ iRandom ][ 0 ], ls_JailSpawnPoints[ iRandom ][ 1 ], ls_JailSpawnPoints[ iRandom ][ 2 ] + loadingHeight );
		 	SetPlayerInterior( playerid, 6 );
		}
		default:
		{
		    iRandom = random( sizeof( sf_JailSpawnPoints ) );
		    SetPlayerPos( playerid, sf_JailSpawnPoints[ iRandom ][ 0 ], sf_JailSpawnPoints[ iRandom ][ 1 ], sf_JailSpawnPoints[ iRandom ][ 2 ] + loadingHeight );
		 	SetPlayerInterior( playerid, 10 );
		}
	}
    return 1;
}

stock JailPlayer( playerid, seconds, admin = 0 )
{
	if ( playerid == INVALID_PLAYER_ID )
		return 0;

	static
	    Query[ 72 ], Float: armour
	;

	// Neccessary Checks
	if ( IsPlayerInMethlab( playerid ) )
		haltMethamphetamine( playerid, GetPlayerMethLabVehicle( playerid ) );

	// Neccessary Functions
	KillTimer 				( p_JailTimer[ playerid ] );
	KillTimer 				( p_CuffAbuseTimer[ playerid ] );
   	PlayerTextDrawSetString	( playerid, p_JailTimeTD[ playerid ], "_" );
	PlayerTextDrawShow		( playerid, p_JailTimeTD[ playerid ] );

	// External Variables to Jail (resetting)
	p_TicketIssuer		[ playerid ] = INVALID_PLAYER_ID; // Reset Tickets
	p_TicketTimestamp	[ playerid ] = 0; // Reset Tickets
	p_Cuffed			{ playerid } = false;
	//p_Detained 			{ playerid } = false;
	p_InfectedHIV 		{ playerid } = false;
	//Delete3DTextLabel	( p_DetainedLabel[ playerid ] );
	//p_DetainedLabel		[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	//p_DetainedBy		[ playerid ] = INVALID_PLAYER_ID;

	// Primary Jail Variables
	p_Jailed			{ playerid } = true;
	p_JailTime			[ playerid ] = seconds;
	p_AdminJailed		{ playerid } = admin;
	p_JailTimer			[ playerid ] = SetTimerEx( "Unjail", 950, true, "d", playerid );

	CancelEdit 					( playerid );
	RemovePlayerStolensFromHands( playerid );
	StopPlayerUsingSlotMachine 	( playerid );
	RemoveEquippedOre			( playerid );
	ClearPlayerWantedLevel 		( playerid );
    ResetPlayerWeapons			( playerid );
	UntiePlayer					( playerid );
	jailDoors 					( playerid, false, true );
	SetPlayerPosToPrison 		( playerid );
	Player_CheckPokerGame 		( playerid, "Jailed" );

	// External Functions
	SetPlayerSpecialAction		( playerid, SPECIAL_ACTION_NONE );
	ClearAnimations 			( playerid );
	RemovePlayerAttachedObject	( playerid, 2 );
    SetPlayerHealth				( playerid, INVALID_PLAYER_ID );

    if ( !IsPlayerAdminJailed( playerid ) )
    {
		if ( p_MetalMelter[ playerid ] )
			ShowPlayerHelpDialog( playerid, 4000, "You can break yourself out of prison with ~p~/breakout." );
		else
			ShowPlayerHelpDialog( playerid, 4000, "You can buy metal melters at Supa Save or a 24/7 store." );
    }

	format( Query, sizeof( Query ), "UPDATE `USERS` SET JAIL_TIME=%d,JAIL_ADMIN=%d WHERE `ID`=%d", seconds, admin, p_AccountID[ playerid ] );
	mysql_single_query( Query );

    if ( GetPlayerArmour( playerid, armour ) && armour )
    	SetPlayerArmour( playerid, 0.0 );
	return 1;
}

function Unjail( playerid )
{
    static
	    Query[ 64 ];

	if ( !IsPlayerConnected( playerid ) ) return KillTimer( p_JailTimer[ playerid ] ), 0;

    p_JailTime[ playerid ] --;

    format( Query, sizeof( Query ), "Time Remaining:~n~%d seconds", p_JailTime[ playerid ] );
	PlayerTextDrawSetString( playerid, p_JailTimeTD[ playerid ], Query );

    if ( p_JailTime[ playerid ] < 1 )
	   	CallLocalFunction( "OnPlayerUnjailed", "dd", playerid, 0 );

    return 1;
}

stock SavePlayerData( playerid, bool: logout = false )
{
    static
		Query[ 950 ];

	if ( IsPlayerNPC( playerid ) )
		return 0;

    if ( p_PlayerLogged{ playerid } )
    {
    	new
    		bool: bQuitToAvoid = false;

		if ( IsPlayerCuffed( playerid ) || IsPlayerTazed( playerid ) || IsPlayerTied( playerid ) || p_LeftCuffed{ playerid } || p_QuitToAvoidTimestamp[ playerid ] > g_iTime )
			bQuitToAvoid = true;

        format( Query, sizeof( Query ), "UPDATE `USERS` SET `SCORE`=%d,`CASH`=%d,`ADMINLEVEL`=%d,`BANKMONEY`=%d,`OWNEDHOUSES`=%d,`KILLS`=%d,`DEATHS`=%d,`VIP_PACKAGE`=%d,`OWNEDCARS`=%d,`LASTLOGGED`=%d,`VIP_EXPIRE`=%d,`LAST_SKIN`=%d,`BURGLARIES`=%d,`UPTIME`=%d,`ARRESTS`=%d,`CITY`=%d,`METH`=%d,`SODA`=%d,`ACID`=%d,`GAS`=%d,",
                                       	GetPlayerScore( playerid ), 	GetPlayerCash( playerid ),		p_AdminLevel[ playerid ],
                                       	p_BankMoney[ playerid ], 		p_OwnedHouses[ playerid ], 		p_Kills[ playerid ],
										p_Deaths[ playerid ], 			p_VIPLevel[ playerid ],
										p_OwnedVehicles[ playerid ], 	g_iTime, 						p_VIPExpiretime[ playerid ],
										p_LastSkin[ playerid ], 		p_Burglaries[ playerid ], 		p_Uptime[ playerid ],
									 	p_Arrests[ playerid ],			p_SpawningCity{ playerid },		p_Methamphetamine{ playerid },
									 	p_CausticSoda{ playerid },		p_MuriaticAcid{ playerid }, 	p_HydrogenChloride{ playerid } );

		format( Query, sizeof( Query ), "%s`VIPWEP1`=%d,`VIPWEP2`=%d,`VIPWEP3`=%d,`MUTE_TIME`=%d,`WANTEDLVL`=%d,`ROBBERIES`=%d,`PING_IMMUNE`=%d,`FIRES`=%d,`CONTRACTS`=%d,`JOB`=%d,`JAIL_TIME`=%d,`ROPES`=%d,`C4`=%d,`MELTERS`=%d,`SCISSORS`=%d,`FOILS`=%d,`PINS`=%d,`BOUNTY`=%d,`WEED`=%d,`IS_CUFFED`=%d,`DRILL`=%d,",
										Query,                          p_VIPWep1{ playerid },          p_VIPWep2{ playerid },
										p_VIPWep3{ playerid },          p_MutedTime[ playerid ],        p_WantedLevel[ playerid ],
										p_Robberies[ playerid ],        p_PingImmunity{ playerid },     p_Fires[ playerid ],
										p_HitsComplete[ playerid ],     p_Job{ playerid },              p_JailTime[ playerid ],
										p_Ropes[ playerid ],			p_C4Amount[ playerid ], 		p_MetalMelter[ playerid ],
										p_Scissors[ playerid ], 		p_AntiEMP[ playerid ], 			p_BobbyPins[ playerid ],
										p_ContractedAmount[ playerid ],	p_WeedGrams[ playerid ],		logout ? ( bQuitToAvoid ? 1 : 0 ) : 0,
										p_drillStrength[ playerid ] );

		format( Query, sizeof( Query ), "%s`BLEW_JAILS`=%d,`BLEW_VAULT`=%d,`VEHICLES_JACKED`=%d,`METH_YIELDED`=%d,`LAST_IP`='%s',`VIP_JOB`=%d,`TRUCKED`=%d,`COINS`=%f,`EXPLOSIVE_BULLETS`=%d,`ONLINE`=%d,`HIT_SOUND`=%d,`EXTRA_SLOTS`=%d,`PILOT`=%d,`TRAIN`=%d WHERE `ID`=%d",
										Query,
										p_JailsBlown[ playerid ], 		p_BankBlown[ playerid ], 			p_CarsJacked[ playerid ],
										p_MethYielded[ playerid ],		mysql_escape( ReturnPlayerIP( playerid ) ),
										p_VIPJob{ playerid },			p_TruckedCargo[ playerid ],			p_IrresistibleCoins[ playerid ],
										p_ExplosiveBullets[ playerid ],
										!logout,						p_HitmarkerSound{ playerid },		p_ExtraAssetSlots{ playerid },
										p_PilotMissions[ playerid ],	p_TrainMissions[ playerid ],
										p_AccountID[ playerid ] );

		mysql_single_query( Query );

        if ( logout )
			 p_PlayerLogged{ playerid } = false;
    }
    return 1;
}

stock SendClientMessageToGang( gangid, colour, format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach(new i : Player)
	{
	    if ( ( p_GangID[ i ] == gangid || p_ViewingGangTalk[ i ] == gangid ) && p_Class[ i ] == CLASS_CIVILIAN )
			SendClientMessage( i, colour, out );
	}
	return 1;
}

stock SendGlobalMessage( colour, format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );
	SendClientMessageToAll( colour, out );

	strreplace( out, #COL_LRED, 	"**" );
	strreplace( out, #COL_ORANGE,	"**" );
	strreplace( out, #COL_GOLD, 	"**" );
	strreplace( out, #COL_GREEN, 	"" );
	strreplace( out, #COL_BLUE, 	"**" );
	strreplace( out, #COL_PINK, 	"**" );
	strreplace( out, #COL_GREY,		"**" );
	strreplace( out, #COL_WHITE, 	"**" );
	DCC_SendChannelMessage( discordGeneralChan, out );
	return 1;
}

function SetPlayerRandomSpawn( playerid )
{
	if ( p_LeftPaintball{ playerid } == true )
	{
		SetPlayerArmour( playerid, 0.0 );
	    SetPlayerPos( playerid, -2172.2017, 252.1113, 35.3388 );
	    p_LeftPaintball{ playerid } = false;
	    return 1;
	}

	if ( p_SpawningKey[ playerid ] [ 0 ] != '\0' )
	{
		new index = p_SpawningIndex[ playerid ];
		new gangid = p_GangID[ playerid ];

		// house spawning
		if ( strmatch( p_SpawningKey[ playerid ], "HSE" ) )
		{
			if ( Iter_Contains( houses, index ) && IsPlayerHomeOwner( playerid, index ) )
			{
			    if ( ! IsHouseOnFire( index ) )
			    {
					pauseToLoad( playerid );
					UpdatePlayerEntranceExitTick( playerid );
					p_InHouse[ playerid ] = -1, p_InBusiness[ playerid ] = -1;
				    SetPlayerInterior( playerid, 0 );
				    SetPlayerPos( playerid, g_houseData[ index ] [ E_EX ], g_houseData[ index ] [ E_EY ], g_houseData[ index ] [ E_EZ ] );
					return 1;
				}
				else SendServerMessage( playerid, "The house you were to be spawned at is on fire therefore normal spawning has been applied." );
			}
			else ResetSpawnLocation( playerid );
		}

		// business spawning
		else if ( strmatch( p_SpawningKey[ playerid ], "BIZ" ) )
		{
			if ( Iter_Contains( business, index ) && IsBusinessAssociate( playerid, index ) )
			{
				//new type = g_businessData[ index ] [ E_INTERIOR_TYPE ];
				pauseToLoad( playerid );
				UpdatePlayerEntranceExitTick( playerid );
				p_InHouse[ playerid ] = -1, p_InBusiness[ playerid ] = -1;
			    SetPlayerInterior( playerid, 0 );
			    SetPlayerPos( playerid, g_businessData[ index ] [ E_X ], g_businessData[ index ] [ E_Y ], g_businessData[ index ] [ E_Z ] );
				/*p_InHouse[ playerid ] = -1, p_InBusiness[ playerid ] = index;
			  	SetPlayerVirtualWorld( playerid, g_businessData[ index ] [ E_WORLD ] );
				SetPlayerInterior( playerid, g_businessData[ index ] [ E_INTERIOR_TYPE ] + 20 );
				SetPlayerPos( playerid, g_businessInteriorData[ type ] [ E_X ], g_businessInteriorData[ type ] [ E_Y ], g_businessInteriorData[ type ] [ E_Z ] );*/
				return 1;
			}
			else ResetSpawnLocation( playerid );
		}

		// gang facilities
		else if ( strmatch( p_SpawningKey[ playerid ], "GNG" ) )
		{
			if ( Iter_Contains( gangs, gangid ) && Iter_Contains( gangfacilities, index ) && g_gangData[ gangid ] [ E_SQL_ID ] == g_gangFacilities[ index ] [ E_GANG_SQL_ID ] ) {
				if ( SetPlayerToGangFacility( playerid, gangid, index ) ) {
					return 1;
				} else {
					SendServerMessage( playerid, "You are unable to spawn at your gang's facility as the gang has no money in its account." );
				}
			}
			else ResetSpawnLocation( playerid );
		}

		// visage apartment
		else if ( strmatch( p_SpawningKey[ playerid ], "VIZ" ) )
		{
			if ( Iter_Contains( visageapartments, index ) && g_VisageApartmentData[ index ] [ E_OWNER_ID ] == p_AccountID[ playerid ] ) {
				SetPlayerToVisageApartment( playerid, index );
				return 1;
			}
			else ResetSpawnLocation( playerid );
		}

		// standard apartment
		else if ( strmatch( p_SpawningKey[ playerid ], "APT" ) )
		{
			if ( g_apartmentData[ index ] [ E_CREATED ] && strmatch( g_apartmentData[ index ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
				pauseToLoad( playerid );
			    SetPlayerInterior( playerid, 0 );
			    SetPlayerFacingAngle( playerid, 180.0 );
			    SetPlayerPos( playerid, -1955.0114, 1360.8344, 17.03 + ( index * 5.447 ) );
			    return 1;
			}
			else ResetSpawnLocation( playerid );
		}
	}


	new
		city = p_SpawningCity{ playerid } >= MAX_CITIES ? random( MAX_CITIES ) : p_SpawningCity{ playerid };

	if ( p_Class[ playerid ] == CLASS_FIREMAN )
		return SetPlayerPos( playerid, g_FiremanSpawns[ city ] [ RANDOM_SPAWN_X ], g_FiremanSpawns[ city ] [ RANDOM_SPAWN_Y ], g_FiremanSpawns[ city ] [ RANDOM_SPAWN_Z ] ), 	SetPlayerInterior( playerid, g_FiremanSpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),	SetPlayerVirtualWorld( playerid, g_FiremanSpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_FiremanSpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_Class[ playerid ] == CLASS_MEDIC )
		return SetPlayerPos( playerid, g_MedicSpawns[ city ] [ RANDOM_SPAWN_X ], g_MedicSpawns[ city ] [ RANDOM_SPAWN_Y ], g_MedicSpawns[ city ] [ RANDOM_SPAWN_Z ] ), 			SetPlayerInterior( playerid, g_MedicSpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),		SetPlayerVirtualWorld( playerid, g_MedicSpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_MedicSpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_inArmy{ playerid } == true )
		return SetPlayerPos( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_X ], g_ArmySpawns[ city ] [ RANDOM_SPAWN_Y ], g_ArmySpawns[ city ] [ RANDOM_SPAWN_Z ] ), 			SetPlayerInterior( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),		SetPlayerVirtualWorld( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_inCIA{ playerid } == true || p_inFBI{ playerid } == true )
		return SetPlayerPos( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_X ], g_CIASpawns[ city ] [ RANDOM_SPAWN_Y ], g_CIASpawns[ city ] [ RANDOM_SPAWN_Z ] ), 				SetPlayerInterior( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),		SetPlayerVirtualWorld( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_Class[ playerid ] == CLASS_POLICE )
		return SetPlayerPos( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_X ], g_PoliceSpawns[ city ] [ RANDOM_SPAWN_Y ], g_PoliceSpawns[ city ] [ RANDOM_SPAWN_Z ] ), 		SetPlayerInterior( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),	SetPlayerVirtualWorld( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_Class[ playerid ] == CLASS_CIVILIAN )
	{
		new
			r;

		switch( city )
		{
			case CITY_SF:
			{
				r = random( sizeof( g_SanFierroSpawns ) );
				SetPlayerFacingAngle( playerid, g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_A ] );
				SetPlayerInterior	( playerid, g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_INTERIOR ] );
				SetPlayerPos		( playerid, g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_X ], g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_Y ], g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_Z ] );
			}
			case CITY_LV:
			{
				r = random( sizeof( g_LasVenturasSpawns ) );
				SetPlayerFacingAngle( playerid, g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_A ] );
				SetPlayerInterior	( playerid, g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_INTERIOR ] );
				SetPlayerPos		( playerid, g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_X ], g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_Y ], g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_Z ] );
			}
			case CITY_LS:
			{
				r = random( sizeof( g_LosSantosSpawns ) );
				SetPlayerFacingAngle( playerid, g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_A ] );
				SetPlayerInterior	( playerid, g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_INTERIOR ] );
				SetPlayerPos		( playerid, g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_X ], g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_Y ], g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_Z ] );
			}
		}
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}

stock DestroyAllPlayerC4s( playerid, bool: resetc4 = false )
{
	for( new i; i < MAX_C4; i++ )
	{
	    if ( g_C4Data[ playerid ] [ i ] [ E_SET ] == true )
	    {
	    	Delete3DTextLabel( g_C4Data[ playerid ] [ i ] [ E_LABEL ] );
	        DestroyDynamicObject( g_C4Data[ playerid ] [ i ] [ E_OBJECT ] );
	        g_C4Data[ playerid ] [ i ] [ E_VEHICLE ] = -100;
	  		g_C4Data[ playerid ] [ i ] [ E_WORLD ] = 0;
			g_C4Data[ playerid ] [ i ] [ E_INTERIOR ] = 0;
			g_C4Data[ playerid ] [ i ] [ E_SET ] = false;
	    }
	}
	if ( resetc4 ) p_C4Amount[ playerid ] = 0;
}

stock ExplodePlayerC4s( playerid, start=0, end=MAX_C4 )
{
	if ( IsPlayerInEvent( playerid ) || IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || p_Class[ playerid ] == CLASS_POLICE )
		return 0;

	new
		Float: X, Float: Y, Float: Z, Float: Angle;

	for( new i = start; i < end; i++ )
	{
	    if ( g_C4Data[ playerid ] [ i ] [ E_SET ] == false ) continue;
		g_C4Data[ playerid ] [ i ] [ E_SET ] = false;

		new
			vehicleid = g_C4Data[ playerid ] [ i ] [ E_VEHICLE ] - 100;

		if ( IsValidVehicle( vehicleid ) )
		{
			// Physics
            SetVehicleAngularVelocity( vehicleid, ( random( 20 ) - 10 ) * 0.05, ( random( 20 ) - 10 ) * 0.05, ( random( 20 ) - 10 ) * 0.008 );
            GetVehicleVelocity( vehicleid, X, Y, Z );
            SetVehicleVelocity( vehicleid, X, Y, Z + ( random( 15 ) * 0.0008 ) );
        	SetVehicleHealth( vehicleid, 0.0 );
        	GetVehiclePos( vehicleid, X, Y, Z );
        	GetVehicleZAngle( vehicleid, Angle );
		    X += ( 2.0 * floatsin( -Angle, degrees ) );
		    Y += ( 2.0 * floatcos( -Angle, degrees ) );
		}
		else GetDynamicObjectPos( g_C4Data[ playerid ] [ i ] [ E_OBJECT ], X, Y, Z );

		// blow up alcatraz rock
		if ( IsPointToPoint( 10.0, X, Y, Z, -2016.7365, 1826.2612, 43.1458 ) )
		{
			if ( g_iTime > g_alcatrazTimestamp )
			{
				g_alcatrazTimestamp = g_iTime + 300;

				//GivePlayerExperience( playerid, E_TERRORIST );
				GivePlayerScore( playerid, 3 );
				GivePlayerWantedLevel( playerid, 24 );
				Achievement::HandleJailBlown( playerid );

				SendGlobalMessage( -1, ""COL_GREY"[SERVER]"COL_WHITE" %s(%d) has destroyed the "COL_GREY"Alcatraz Rock{FFFFFF}!", ReturnPlayerName( playerid ), playerid );
				massUnjailPlayers( CITY_SF, .alcatraz = true );
			}
		}

		// blow up various vaults
		for( new j = 0; j < sizeof( g_bankvaultData ); j++ )
		{
			// Blow Bank Vault
			if ( IsPointToPoint( 5.0, X, Y, Z, g_bankvaultData[ j ] [ E_EXPLODE_POS ] [ 0 ], g_bankvaultData[ j ] [ E_EXPLODE_POS ] [ 1 ], g_bankvaultData[ j ] [ E_EXPLODE_POS ] [ 2 ] ) && !g_bankvaultData[ j ] [ E_DISABLED ] && g_C4Data[ playerid ] [ i ] [ E_WORLD ] == g_bankvaultData[ j ] [ E_WORLD ] )
			{
				if ( g_iTime > g_bankvaultData[ j ] [ E_TIMESTAMP ] )
				{
					g_bankvaultData[ j ] [ E_TIMESTAMP_CLOSE ]	= g_iTime + 240; // time to close
			    	g_bankvaultData[ j ] [ E_TIMESTAMP ] 		= g_iTime + 600; // time to restore
			    	g_bankvaultData[ j ] [ E_DISABLED ] 		= true;

					MoveDynamicObject( g_bankvaultData[ j ] [ E_OBJECT ], g_bankvaultData[ j ] [ E_OPEN_POS ] [ 0 ], g_bankvaultData[ j ] [ E_OPEN_POS ] [ 1 ], g_bankvaultData[ j ] [ E_OPEN_POS ] [ 2 ], 2.0, g_bankvaultData[ j ] [ E_OPEN_ROT ] [ 0 ], g_bankvaultData[ j ] [ E_OPEN_ROT ] [ 1 ], g_bankvaultData[ j ] [ E_OPEN_ROT ] [ 2 ] );

					//GivePlayerExperience( playerid, E_TERRORIST );
					GivePlayerScore( playerid, 3 );
					GivePlayerWantedLevel( playerid, 24 );
					Achievement::HandleBankBlown( playerid );

					if ( j == VAULT_BOAT ) {
						TriggerClosestCivilians( playerid, GetClosestRobberyNPC( getClosestRobberySafe( playerid ) ) );
					}

					SendGlobalMessage( -1, ""COL_GREY"[SERVER]"COL_WHITE" %s(%d) has destroyed the "COL_GREY"%s Vault{FFFFFF}!", ReturnPlayerName( playerid ), playerid, g_bankvaultData[ j ] [ E_NAME ] );
					break;
				}
			}

			// Blow Jails
			if ( j < sizeof( g_jailData ) )
			{
				if ( IsPointToPoint( g_jailData[ j ] [ E_RADIUS ], X, Y, Z, g_jailData[ j ] [ E_EXPLODE1_POS ] [ 0 ], g_jailData[ j ] [ E_EXPLODE1_POS ] [ 1 ], g_jailData[ j ] [ E_EXPLODE1_POS ] [ 2 ] ) || IsPointToPoint( g_jailData[ j ] [ E_RADIUS ], X, Y, Z, g_jailData[ j ] [ E_EXPLODE2_POS ] [ 0 ], g_jailData[ j ] [ E_EXPLODE2_POS ] [ 1 ], g_jailData[ j ] [ E_EXPLODE2_POS ] [ 2 ] ) && !g_jailData[ j ] [ E_BOMBED ] )
				{
					if ( g_iTime > g_jailData[ j ] [ E_TIMESTAMP ] )
					{
				    	g_jailData[ j ] [ E_BOMBED ] = true;
				    	g_jailData[ j ] [ E_TIMESTAMP ] = g_iTime + 300;

						//GivePlayerExperience( playerid, E_TERRORIST );
						GivePlayerScore( playerid, 3 );
					    GivePlayerWantedLevel( playerid, 24 );
					    Achievement::HandleJailBlown( playerid );

						SendGlobalMessage( -1, ""COL_GREY"[SERVER]"COL_WHITE" %s(%d) has exploded the "COL_GREY"%s Jail{FFFFFF} and has freed its prisoners.", ReturnPlayerName( playerid ), playerid, returnCityName( g_jailData[ j ] [ E_CITY ] ) );
					    massUnjailPlayers( g_jailData[ j ] [ E_CITY ] );
					    break;
					}
				}
			}
		}

		// prevent spamming wanted for farming
		if ( GetPVarInt( playerid, "C4WantedCD" ) < g_iTime && p_Class[ playerid ] != CLASS_POLICE ) {
			GivePlayerWantedLevel( playerid, 6 );
			SetPVarInt( playerid, "C4WantedCD", g_iTime + 30 );
		}

		CreateExplosionEx( X, Y, Z, 0, 10.0, g_C4Data[ playerid ] [ i ] [ E_WORLD ], g_C4Data[ playerid ] [ i ] [ E_INTERIOR ], playerid );
	    g_C4Data[ playerid ] [ i ] [ E_VEHICLE ] = -100;
	  	Delete3DTextLabel( g_C4Data[ playerid ] [ i ] [ E_LABEL ] );
		DestroyDynamicObject( g_C4Data[ playerid ] [ i ] [ E_OBJECT ] );
	}
	return 1;
}

stock hasC4Planted( playerid )
{
	for( new iC4 = 0; iC4 < MAX_C4; iC4++ )
	    if ( g_C4Data[ playerid ] [ iC4 ] [ E_SET ] )
		    return true;

	return false;
}

function RestoreHealthAfterBrokenOut( playerid ) return SetPlayerHealth( playerid, 100.0 );

stock IsPlayerInPoliceCar( playerid )
{
	new model = GetVehicleModel( GetPlayerVehicleID( playerid ) );
	if ( model == 425 || model == 520|| model == 497 || model == 470 || model == 432 || model == 428 || model == 523 || model == 427 || model == 490 || model >= 596 && model <= 599 || model == 601 ) return true;
	return false;
}

stock GivePlayerWantedLevel( playerid, wantedlevel, bool:loadingstats = false )
{
	static
		szWanted[ 12 ];

	if ( ! IsPlayerConnected( playerid ) || IsPlayerNPC( playerid ) )
	    return 0;

	if ( IsPlayerJailed( playerid ) )
	{
		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[WANTED LEVEL]{FFFFFF} As you're jailed, wanted levels will not append.", wantedlevel, p_WantedLevel[ playerid ] );
		return 1;
	}

	if ( wantedlevel == 0 )
		return 0;

    if ( ( p_WantedLevel[ playerid ] += wantedlevel ) < 0 )
    	p_WantedLevel[ playerid ] = 0; // Negative wanted level?

    if ( ( wantedlevel < 0 && p_WantedLevel[ playerid ] < 6 ) || wantedlevel > 0 )
		SetPlayerWantedLevel( playerid, p_WantedLevel[ playerid ] );

	if ( p_WantedLevel[ playerid ] > 0 )
	{
		if ( IsPlayerSpawned( playerid ) )
		{
			format( szWanted, sizeof( szWanted ), "] %d ]", p_WantedLevel[ playerid ] );
			PlayerTextDrawSetString( playerid, p_WantedLevelTD[ playerid ], szWanted );
			if ( ! p_inMovieMode{ playerid } ) PlayerTextDrawShow( playerid, p_WantedLevelTD[ playerid ] );
			ResetPlayerPassiveMode( playerid, .passive_disabled = true ); // remove passive mode if the player is wanted
		}
	}
	else
	{
		PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
		Uncuff( playerid );
	}

	// regulate player color
	SetPlayerColorToTeam( playerid );

	/*if ( p_WantedLevel[ playerid ] > 2000 ) // 8hska7082bmahu
	{
		p_WantedLevel[ playerid ] = 2000;
		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[WANTED LEVEL]{FFFFFF} Your wanted level has reached its maximum. Further wanted levels will not append.", wantedlevel, p_WantedLevel[ playerid ] );

		format( szBigString, 256, "[0xA1] %s(%d) :: %d :: %d\r\n", ReturnPlayerName( playerid ), playerid, p_WantedLevel[ playerid ], g_iTime );
	    AddFileLogLine( "security.txt", szBigString );
		return 1;
	}*/

	if ( !loadingstats ) SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[CRIME]{FFFFFF} Your wanted level has been modified by %d! Wanted level: %d", wantedlevel, p_WantedLevel[ playerid ] );
	else SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[RESUME]{FFFFFF} Your wanted level has been set to %d as you are resuming your life.", p_WantedLevel[ playerid ] );
	return 1;
}

stock ClearPlayerWantedLevel( playerid )
{
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
    p_WantedLevel[ playerid ] = 0;
	SetPlayerWantedLevel( playerid, 0 );
	SetPlayerColorToTeam( playerid );
}

stock IsWeaponBanned( weaponid ) {
	return 0 <= weaponid < MAX_WEAPONS && ( weaponid == 36 || weaponid == 37 || weaponid == 38 || weaponid == 39 || weaponid == 44 || weaponid == 45 );
}

stock GivePlayerScore( playerid, score )
{
	if ( IsPlayerAdminOnDuty( playerid ) )
		return 0;

	new
		gangid = p_GangID[ playerid ];

	if ( gangid != INVALID_GANG_ID ) {
		SaveGangData( gangid ), g_gangData[ gangid ] [ E_SCORE ] += score;
	}
	return SetPlayerScore( playerid, GetPlayerScore( playerid ) + score );
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

	gpci( playerid, szSerial, sizeof( szSerial ) );
	GetPlayerName( playerid, szPlayerNameBanned, MAX_PLAYER_NAME );
	cache_get_data( rows, fields );

	if ( rows )
	{
		SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" Edited ban entry for %s to "#SERVER_NAME".", szPlayerNameBanned );
		format( szBigString, 72, "UPDATE `BANS` SET `SERVER`=0 WHERE `NAME`='%s'", mysql_escape( szPlayerNameBanned ) );
		mysql_single_query( szBigString );
	}
	else
	{
		new
			enabled = IsProxyEnabledForPlayer( playerid );

		if ( !enabled )
		{
			format( szLargeString, sizeof( szLargeString ), "INSERT INTO `BANS`(`NAME`,`IP`,`REASON`,`BANBY`,`DATE`,`EXPIRE`,`SERVER`,`SERIAL`) VALUES ('%s','%s','%s','%s',%d,%d,0,'%s')", mysql_escape( szPlayerNameBanned ), mysql_escape( szIP ), mysql_escape( szReason ), mysql_escape( szBannedBy ), g_iTime, lol_time, mysql_escape( szSerial ) );
		}
		else
		{
			// include country why not
			format( szLargeString, sizeof( szLargeString ), "INSERT INTO `BANS`(`NAME`,`IP`,`REASON`,`BANBY`,`DATE`,`EXPIRE`,`SERVER`,`SERIAL`,`COUNTRY`) VALUES ('%s','%s','%s','%s',%d,%d,0,'%s','%s')", mysql_escape( szPlayerNameBanned ), mysql_escape( szIP ), mysql_escape( szReason ), mysql_escape( szBannedBy ), g_iTime, lol_time, mysql_escape( szSerial ), mysql_escape( GetPlayerCountryCode( playerid ) ) );
		}

		mysql_single_query( szLargeString );
	}
	return KickPlayerTimed( playerid ), 1;
}

stock IsNumeric(const str[ ])
{
    new len = strlen(str);

    if (!len) return false;
    for(new i; i < len; i++)
    {
        if (!('0' <= str[i] <= '9')) return false;
    }
    return true;
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

new svApartments = -1;

stock loadApartmentsFromDatabase( )
{
	new
	    szQuery[ 45 ],
	    loadingTick = GetTickCount( )
	;

	for( new i; i < sizeof( g_apartmentData ); i++ )
	{
	    format( szQuery, sizeof( szQuery ), "SELECT * FROM `APARTMENTS` WHERE `ID`=%d LIMIT 0,1", i );
	    mysql_function_query( dbHandle, szQuery, true, "OnApartmentLoad", "i", i );
	}
	printf( "[FLATS]: %d apartments have been loaded. (Tick: %dms)", svApartments, GetTickCount( ) - loadingTick );
}

thread OnApartmentLoad( )
{
	new
		rows, fields, i = -1, aID,
		Field[ 5 ],
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			cache_get_field_content( i, "ID", Field ),			aID = strval( Field );
			cache_get_field_content( i, "OWNER", g_apartmentData[ aID ] [ E_OWNER ], dbHandle, 24 );
			cache_get_field_content( i, "NAME", g_apartmentData[ aID ] [ E_NAME ], dbHandle, 30 );
			cache_get_field_content( i, "LOCKED", Field ), g_apartmentData[ aID ] [ E_LOCKED ] = strval( Field );
			g_apartmentData[ aID ] [ E_CREATED ] = true;
		}
	}
	printf( "[FLATS]: %d apartments have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

stock GetPlayerOwnedApartments( playerid )
{
	for( new i; i < sizeof( g_apartmentData ); i++ ) if ( g_apartmentData[ i ] [ E_CREATED ] )
	{
		if ( strmatch( g_apartmentData[ i ][ E_OWNER ], ReturnPlayerName( playerid ) ) )
		    return 1;
	}
	return 0;
}

stock GetPlayerIDFromName( pName[ ] )
{
    foreach(new i : Player)
    {
        if ( strmatch( pName, ReturnPlayerName( i ) ) )
			return i;
    }
    return INVALID_PLAYER_ID;
}

stock GetPlayerIDFromAccountID( iAccountID )
{
    foreach(new i : Player)
    {
        if ( p_AccountID[ i ] == iAccountID )
			return i;
    }
    return INVALID_PLAYER_ID;
}

stock SetPlayerColorToTeam( playerid )
{
#if defined __cnr__chuffsec
	if ( IsPlayerSecurityDriver( playerid ) ) return SetPlayerColor( playerid, COLOR_SECURITY );
#endif

	if ( p_AdminOnDuty{ playerid } ) return SetPlayerColor( playerid, COLOR_PINK );

	switch( p_Class[ playerid ] )
	{
	    case CLASS_POLICE:
	    {
	    	SetPlayerColor( playerid, COLOR_POLICE );
			if ( p_inFBI{ playerid } ) SetPlayerColor( playerid, COLOR_FBI );
			if ( p_inCIA{ playerid } ) SetPlayerColor( playerid, COLOR_CIA );
			if ( p_inArmy{ playerid } ) SetPlayerColor( playerid, COLOR_ARMY );
	    }
	    case CLASS_FIREMAN: SetPlayerColor( playerid, COLOR_FIREMAN );
	    case CLASS_MEDIC: SetPlayerColor( playerid, COLOR_MEDIC );
	    default:
	    {
	    	new
	    		default_color = COLOR_DEFAULT;

	    	// set color according to wanted level
			if ( p_WantedLevel[ playerid ] >= 12 ) default_color = COLOR_WANTED12;
			else if ( p_WantedLevel[ playerid ] >= 6 ) default_color = COLOR_WANTED6;
			else if ( p_WantedLevel[ playerid ] >= 1 ) default_color = COLOR_WANTED2;
		    else if ( p_GangID[ playerid ] != INVALID_GANG_ID ) default_color = g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ];

		    // set alpha for invisible players to 0
	    	if ( IsPlayerHiddenFromRadar( playerid ) ) {
	    		default_color = setAlpha( default_color, 0x00 );
	    	}

	    	// force the color on the player
	    	return SetPlayerColor( playerid, default_color );
		}
	}
	return 1;
}

/*stock GivePlayerXP_Legacy( playerid, amount )
{
	if ( p_PlayerLogged{ playerid } == true )
	{
	    new string[ 20 ];
	    if ( amount < 0 ) format( string, sizeof( string ), "~r~%d XP", amount );
		else {
	    	if ( IsDoubleXP( ) ) amount *= 2;
			format( string, sizeof( string ), "+%d XP", amount );
		}
		p_XP[ playerid ] += amount;
	    PlayerTextDrawSetString( playerid, p_ExperienceAwardTD[ playerid ], string );
	    PlayerTextDrawShow( playerid, p_ExperienceAwardTD[ playerid ] );
		SetTimerEx( "Experience_HideIncrementTD", 3500, false, "d", playerid );
		if ( p_XP[ playerid ] > 99999999 ) p_XP[ playerid ] = 99999999;
		autosaveStart( playerid ); // auto-save
		return 1;
	}
	return 0;
}*/

stock IsPlayerFBI( playerid )
{
	new
		skinid = GetPlayerSkin( playerid );

	switch( skinid ) {
	    case 286, 71, 285: {
			if ( IsPlayerSpawned( playerid ) && IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) && p_VIPLevel[ playerid ] && p_LastSkin[ playerid ] == skinid ) {
				return false;
			}
	    	return true;
	    }
	}
	return false;
}

stock IsPlayerCIA( playerid )
{
	new
		skinid = GetPlayerSkin( playerid );

	switch( skinid ) {
	    case 303 .. 305: {
			if ( IsPlayerSpawned( playerid ) && IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) && p_VIPLevel[ playerid ] && p_LastSkin[ playerid ] == skinid ) {
				return false;
			}
	    	return true;
	    }
	}
	return false;
}

stock IsPlayerArmy( playerid ) {
	return GetPlayerSkin( playerid ) == 287;
}

stock IsPlayerPolice( playerid )
{
	new
		skinid = GetPlayerSkin( playerid );

	switch( skinid ) {
   	    case 265, 266, 267, 306, 307, 280, 281, 284: {
			if ( IsPlayerSpawned( playerid ) && IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) && p_VIPLevel[ playerid ] && p_LastSkin[ playerid ] == skinid ) {
				return false;
			}
	    	return true;
	    }
   	}
	return false;
}

stock IsPlayerMedic( playerid )
{
	new
		skinid = GetPlayerSkin( playerid );

	switch( skinid ) {
	    case 274 .. 276, 308: {
			if ( IsPlayerSpawned( playerid ) && IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) && p_VIPLevel[ playerid ] && p_LastSkin[ playerid ] == skinid ) {
				return false;
			}
	    	return true;
	    }
	}
	return false;
}

stock IsPlayerFireman( playerid )
{
	new
		skinid = GetPlayerSkin( playerid );

	switch( skinid ) {
	    case 277, 278, 279: {
			if ( IsPlayerSpawned( playerid ) && IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) && p_VIPLevel[ playerid ] && p_LastSkin[ playerid ] == skinid ) {
				return false;
			}
	    	return true;
	    }
	}
	return false;
}

stock PutPlayerInEmptyVehicleSeat( vehicleid, playerid )
{
	new
		vModel = GetVehicleModel( vehicleid ),
	    bool: bNonAvailable[ 16 char ],
	    seats = 0xF
	;

	if ( !IsValidVehicle( vehicleid ) )
	    return -1;

	if ( vModel == 425 || vModel == 481 || vModel == 520 || vModel == 519 || vModel == 509 || vModel == 510 || vModel == 476 )
		return -1;

	foreach(new iPlayer : Player)
	{
		if ( IsPlayerInVehicle( iPlayer, vehicleid ) )
		{
			new iVehicle = GetPlayerVehicleSeat( iPlayer );
			seats = GetVehicleSeatCount( GetVehicleModel( iVehicle ) );

   			if ( seats == 0xF )
	   			return -1; // Just so the player aint bugged.

			if ( iVehicle >= 0 && iVehicle <= seats ) bNonAvailable{ iVehicle } = true;
		}
	}
	for( new i = 1; i < sizeof( bNonAvailable ); i++ )
	{
	    if ( !bNonAvailable{ i } ) {
			SetPlayerVirtualWorld( playerid, GetVehicleVirtualWorld( vehicleid ) );
			SetPlayerInterior( playerid, 0 ); // All vehicles are in interior ID 0, unless a stupid did this :|
			PutPlayerInVehicle( playerid, vehicleid, i );
			break;
		}
	}
	return seats;
}

stock GetVehicleSeatCount(iModel)
{
    if (400 <= iModel <= 611)
    {
        static
            s_MaxPassengers[] =
            {
                271782163, 288428337, 288559891, -2146225407, 327282960, 271651075, 268443408, 286339857, 319894289, 823136512, 805311233,
                285414161, 286331697, 268513553, 18026752, 286331152, 286261297, 286458129, 856765201, 286331137, 856690995, 269484528,
                51589393, -15658689, 322109713, -15527663, 65343
            }
        ;
        return ((s_MaxPassengers[(iModel -= 400) >>> 3] >>> ((iModel & 7) << 2)) & 0xF);
    }
    return 0xF;
}


stock IsPointToPoint(Float: fRadius, Float: fX1, Float: fY1, Float: fZ1, Float: fX2, Float: fY2, Float: fZ2)
    return ((-fRadius < floatabs(fX2 - fX1) < fRadius) && (-fRadius < floatabs(fY2 - fY1) < fRadius) && (-fRadius < floatabs(fZ2 - fZ1) < fRadius));

stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, &Float:z, Float:distance)
{
	new Float: a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    if (GetPlayerVehicleID( playerid ))
    {
    	GetVehicleZAngle(GetPlayerVehicleID( playerid ), a);
 	}
 	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

stock ChangeVehicleModel( vehicleid, objectid, Float: offset = 0.0 )
{
	new
		iObject
	;
	iObject = CreateDynamicObject( objectid, 0.0, 0.0, 0.0, 0, 0, 0 );
	AttachDynamicObjectToVehicle( iObject, vehicleid, 0, 0, 0, 0, 0, 0 + offset );
	LinkVehicleToInterior( vehicleid, 12 );
}

stock SetObjectFacePoint(iObjectID, Float: fX, Float: fY, Float: fOffset, bool: bDynamic = false )
{
    new
        Float: fOX,
        Float: fOY,
        Float: fRZ
    ;
    if ( bDynamic )
    {
	    if (GetDynamicObjectPos(iObjectID, fOX, fOY, fRZ))
	    {
	        fRZ = atan2(fY - fOY, fX - fOX) - 90.0;

	        GetDynamicObjectRot(iObjectID, fX, fY, fOX);
	        SetDynamicObjectRot(iObjectID, fX, fY, fRZ + fOffset);
	    }
	}
	else
	{
	    if (GetObjectPos(iObjectID, fOX, fOY, fRZ))
	    {
	        fRZ = atan2(fY - fOY, fX - fOX) - 90.0;

	        GetObjectRot(iObjectID, fX, fY, fOX);
	        SetObjectRot(iObjectID, fX, fY, fRZ + fOffset);
	    }
	}
}

stock TimeConvert( seconds )
{
	static
	    szTime[ 32 ]
	;
 	format( szTime, sizeof( szTime ), "%02d:%02d", floatround( seconds / 60 ), seconds - floatround( ( seconds / 60 ) * 60 ) );
	return szTime;
}

stock SetPlayerFacePoint(playerid, Float: fX, Float: fY, Float: offset = 0.0)
{
    static
        Float: X,
        Float: Y,
        Float: Z,
        Float: face
    ;
    if (GetPlayerPos(playerid, X, Y, Z))
    {
        face = atan2(fY - Y, fX - X) - 90.0;
        SetPlayerFacingAngle(playerid, face + offset);
    }
}

stock GetClosestPlayer( playerid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = INVALID_PLAYER_ID,
        Float: fX, Float: fY,  Float: fZ, Float: fTmp,
        world = GetPlayerVirtualWorld( playerid )
    ;

    if ( GetPlayerPos( playerid, fX, fY, fZ ) )
    {
		foreach(new i : Player)
		{
			if ( i != playerid )
			{
		        if ( GetPlayerState( i ) != PLAYER_STATE_SPECTATING && GetPlayerVirtualWorld( i ) == world )
		        {
		            if ( 0.0 < ( fTmp = GetDistanceFromPlayerSquared( i, fX, fY, fZ ) ) < distance ) // Y_Less mentioned there's no need to sqroot
		            {
		                distance = fTmp;
		                iCurrent = i;
		            }
		        }
			}
	    }
    }
    return iCurrent;
}

stock GetClosestPlayerEx( playerid, classid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = INVALID_PLAYER_ID,
        Float: fX, Float: fY,  Float: fZ, Float: fTmp,
        world = GetPlayerVirtualWorld( playerid )
    ;

    if ( GetPlayerPos( playerid, fX, fY, fZ ) )
    {
		foreach(new i : Player)
		{
			if ( i != playerid )
			{
		        if ( GetPlayerState( i ) != PLAYER_STATE_SPECTATING && GetPlayerVirtualWorld( i ) == world && p_Class[ i ] == classid )
		        {
		            if ( 0.0 < ( fTmp = GetPlayerDistanceFromPoint( i, fX, fY, fZ ) ) < distance )
		            {
		                distance = fTmp;
		                iCurrent = i;
		            }
		        }
			}
	    }
    }
    return iCurrent;
}

stock GetClosestVehicle(playerid, except = INVALID_VEHICLE_ID, &Float: distance = Float: 0x7F800000) {
    new
    	i,
        Float: X,
        Float: Y,
        Float: Z
    ;
    if (GetPlayerPos(playerid, X, Y, Z)) {
        new
            Float: dis,
            closest = INVALID_VEHICLE_ID
        ;
        while(i != MAX_VEHICLES) {
            if (0.0 < (dis = GetVehicleDistanceFromPoint(++i, X, Y, Z)) < distance && i != except) {
                distance = dis;
                closest = i;
            }
        }
        return closest;
    }
    return INVALID_VEHICLE_ID;
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

stock textContainsURL(const string[])
{
    static
        RegEx:rCIP
    ;

    if ( !rCIP )
    {
        rCIP = regex_build("([\\w-]*://)?([\\w-]+\\.)+([\\w-]+)(/[^\\s]*)*");
    }

    return regex_match_exid(string, rCIP);
}

stock isValidPlayerName( szName[ ] )
{
	strreplacechar( szName, '\\', '-' );
	//strreplacechar( szName, '.', '-' );
	strreplacechar( szName, '/', '-' );

#if defined __cnr__chuffsec
	if ( strmatch( szName, SECURE_TRUCK_DRIVER_NAME ) )
		return false;
#endif

	if( !( 2 < strlen( szName ) < MAX_PLAYER_NAME ) )
		return false;

	return regex_match( szName, "^[a-zA-Z0-9@=_\\[\\]\\.\\(\\)\\$]+$" );
}

stock ReturnWeaponName(weaponid, bool:vipgun=false)
{
	static wname[24];
	switch(weaponid) {
	    case 0: wname = "Fist";
		case 18: wname = "Molotovs";
		case 40: wname = "Detonator";
		case 44: wname = "Nightvision Goggles";
		case 45: wname = "Thermal Goggles";
		case 51: wname = "Explosion";
		case 53: wname = "Drowned";
		case 54: wname = "Collision";
		default: GetWeaponName(weaponid, wname, sizeof(wname));
	}
	if ( weaponid == 0 && vipgun == true ) wname = "Nothing";
	return wname;
}

stock ReturnGangName( i )
{
	static
		szGang[ 30 ];
	if ( i == INVALID_GANG_ID || !Iter_Contains( gangs, i ) ) szGang = "Unoccupied";
	else format( szGang, sizeof( szGang ), "%s", g_gangData[ i ] [ E_NAME ] );
	return szGang;
}

stock IsPlayerInArea( playerid, Float: minx, Float: maxx, Float: miny, Float: maxy )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( GetPlayerPos( playerid, X, Y, Z ) )
		return ( X > minx && X < maxx && Y > miny && Y < maxy );

	return 0;
}

stock IsPlayerInArea3D( playerid, Float: minx, Float: maxx, Float: miny, Float: maxy, Float: minz, Float: maxz )
{
	static Float: X, Float: Y, Float: Z;
	GetPlayerPos( playerid, X, Y, Z );
	return ( X > minx && X < maxx && Y > miny && Y < maxy && Z > minz && Z < maxz );
}

stock IsPointInArea( Float: X, Float: Y, Float: Z, Float: minx, Float: maxx, Float: miny, Float: maxy, Float: minz, Float: maxz )
 	return ( X > minx && X < maxx && Y > miny && Y < maxy && Z > minz && Z < maxz );

stock GetPlayersInGangZone( z, g, &is_afk = 0, &in_air = 0 )
{
	if ( g == INVALID_GANG_ID )
		return 0;

	new count = 0;
	new Float: Z;

	foreach ( new i : Player ) if ( p_Class[ i ] == CLASS_CIVILIAN && p_GangID[ i ] == g && IsPlayerInDynamicArea( i, g_gangTurfData[ z ] [ E_AREA ] ) )
	{
		if ( ! p_AntiSpawnKillEnabled{ i } && ! IsPlayerPassive( i ) && GetPlayerState( i ) != PLAYER_STATE_SPECTATING )
		{
            if ( IsPlayerAFK( i ) )
            {
            	is_afk++;
            	continue;
            }
            if ( GetPlayerPos( i, Z, Z, Z ) && Z >= 300.0 )
            {
            	in_air++;
            	continue;
            }
            count++;
		}
	}
	return count;
}

thread OnGangAdded( gangid )
{
	g_gangData[ gangid ] [ E_SQL_ID ] = cache_insert_id( );
	return 1;
}

thread OnPlayerGangLoaded( playerid )
{
	new rows, fields;

	cache_get_data( rows, fields );

	if ( rows )
	{
		new gang_name[ 30 ], join_msg[ 96 ];
		new gang_sql_id = cache_get_field_content_int( 0, "ID" );

		// Check again if the gang exists
		foreach (new g : gangs) if ( gang_sql_id == g_gangData[ g ] [ E_SQL_ID ] ) {
			p_GangID[ playerid ] = g;
			printf( "[gang debug] found duplicate gang for gang id %d (User : %s)", g, ReturnPlayerName( playerid ) );
			return 1;
		}

		// reset name and join message appropriately
		cache_get_field_content( 0, "NAME", gang_name, dbHandle, sizeof( gang_name ) );
		cache_get_field_content( 0, "JOIN_MSG", join_msg, dbHandle, sizeof( join_msg ) );

		// create gang
		new handle = CreateGang( gang_name,
			cache_get_field_content_int( 0, "LEADER", dbHandle ),
			cache_get_field_content_int( 0, "COLOR", dbHandle ),
			cache_get_field_content_int( 0, "KILLS", dbHandle ),
			cache_get_field_content_int( 0, "DEATHS", dbHandle ),
			cache_get_field_content_int( 0, "BANK", dbHandle ),
			cache_get_field_content_int( 0, "SCORE", dbHandle ),
			cache_get_field_content_int( 0, "RESPECT", dbHandle ),
			!! cache_get_field_content_int( 0, "INVITE_ONLY", dbHandle ),
			join_msg, false, gang_sql_id
		);

		// message player
		if ( handle != ITER_NONE )
		{
			p_GangID[ playerid ] = handle;
			InformGangConnectMessage( playerid, handle );
			printf("[%s] Added gangid %d as gang slot %d", ReturnPlayerName( playerid ), gang_sql_id, handle );
		}
		else
		{
			p_GangID[ playerid ] = -1;
			SendServerMessage( playerid, "Had an issue loading your gang. Contact Lorenc (0x92F)." );
			printf("[GANG] [ERROR] Had an issue loading a gang row id %d", gang_sql_id );
		}
	}
	else
	{
		p_GangID[ playerid ] = -1;
	}
	return 1;
}

stock CreateGang( const gang_name[ 30 ], leader, gang_color, kills = 1, deaths = 1, bank = 0, score = 0, respect = 0, bool: invite_only = false, const join_message[ 96 ] = "NULL", bool: has_facility = false, sql_id = 0 )
{
	new handle = Iter_Free( gangs );

	if ( handle != ITER_NONE )
	{
		// Insert into iterator
	    Iter_Add( gangs, handle );

		// insert gang into database, if no sql found
		if ( ! sql_id )
		{
			// insert gang and fetch sql id
			mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO `GANGS`(`NAME`,`LEADER`,`COLOR`) VALUES ('%e', %d, %d)", gang_name, leader, gang_color );
			mysql_function_query( dbHandle, szBigString, true, "OnGangAdded", "d", handle );

			// reset coleaders in this case
			for ( new i = 0; i < MAX_COLEADERS; i ++ ) {
				g_gangData[ handle ] [ E_COLEADER ] [ i ] = 0;
			}
		}
		else
		{
			// set gang sql id
			g_gangData[ handle ] [ E_SQL_ID ] = sql_id;

			// load coleaders
			format( szNormalString, sizeof( szNormalString ), "SELECT `USER_ID` FROM `GANG_COLEADERS` WHERE `GANG_ID`=%d LIMIT 0,%d", g_gangData[ handle ] [ E_SQL_ID ], MAX_COLEADERS );
			mysql_function_query( dbHandle, szNormalString, true, "OnGangColeaderLoad", "d", handle );
		}

		// Check for null join message
		if ( ismysqlnull( join_message ) ) g_gangData[ handle ] [ E_JOIN_MSG ] [ 0 ] = '\0';
		else format( g_gangData[ handle ] [ E_JOIN_MSG ], 96, "%s", join_message );

		// format name
		format( g_gangData[ handle ] [ E_NAME ], 30, "%s", gang_name );
		trimString( g_gangData[ handle ] [ E_NAME ] );

		// default variables
	    g_gangData[ handle ] [ E_LEADER ] 			= leader;
	    g_gangData[ handle ] [ E_KILLS ] 			= kills;
	    g_gangData[ handle ] [ E_DEATHS ] 			= deaths;
	    g_gangData[ handle ] [ E_SCORE ] 			= score;
	    g_gangData[ handle ] [ E_BANK ] 			= bank;
	    g_gangData[ handle ] [ E_COLOR ]        	= gang_color;
	    g_gangData[ handle ] [ E_RESPECT ] 			= respect;
		g_gangData[ handle ] [ E_INVITE_ONLY ] 		= invite_only;
		g_gangData[ handle ] [ E_HAS_FACILITY ] 	= has_facility;
	}
	return handle;
}

thread OnGangColeaderLoad( gangid ) {

	new
		rows, fields;

	cache_get_data( rows, fields );

	if ( rows ) {
		for( new i = 0; i < rows; i ++ ) {
			if ( i >= MAX_COLEADERS ) break;
			g_gangData[ gangid ] [ E_COLEADER ] [ i ] = cache_get_field_content_int( i, "USER_ID", dbHandle );
		}
	}
}

stock InformGangConnectMessage( playerid, gangid )
{
	if ( ! strlen( g_gangData[ gangid ] [ E_JOIN_MSG ] ) ) {
  		SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s has been loaded into the server.", g_gangData[ gangid ] [ E_NAME ] );
	} else {
  		SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s", g_gangData[ gangid ] [ E_JOIN_MSG ] );
	}
	return 1;
}

stock DestroyGang( gangid, bool: soft_delete, bool: iter_remove = true )
{
	if ( !Iter_Contains( gangs, gangid ) )
		return;

	if ( ! soft_delete )
	{
	 	// Do SQL operations
	 	mysql_single_query( sprintf( "DELETE FROM `GANGS` WHERE `ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
	 	mysql_single_query( sprintf( "DELETE FROM `GANG_COLEADERS` WHERE `GANG_ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
	 	mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=-1 WHERE `GANG_ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
	}

 	// Disconnect current users
 	foreach(new i : Player) if ( p_GangID[ i ] == gangid ) {
 		p_GangID[ i ] = INVALID_GANG_ID;
 	}

	// Reset gang data
	g_gangData[ gangid ] [ E_SQL_ID ] 			= 0;
    g_gangData[ gangid ] [ E_LEADER ] 			= 0;
	g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] 	= 0;
 	g_gangData[ gangid ] [ E_COLOR ]       	 	= COLOR_GANGZONE;
 	g_gangData[ gangid ] [ E_NAME ] [ 0 ]   	= '\0';
 	g_gangData[ gangid ] [ E_BANK ] 			= 0;
 	g_gangData[ gangid ] [ E_RESPECT ] 			= 0;
	g_gangData[ gangid ] [ E_INVITE_ONLY ] 		= false;
	g_gangData[ gangid ] [ E_JOIN_MSG ] [ 0 ] 	= '\0';

	// Reset coleaders
	for ( new i = 0; i < MAX_COLEADERS; i ++ )
		g_gangData[ gangid ] [ E_COLEADER ] [ i ] = 0;

 	// Free iterator id
 	if ( iter_remove ) {
 		Iter_Remove( gangs, gangid );
 	}

 	// Empty out the turfs
 	foreach ( new z : turfs )
 	{
 		if ( g_gangTurfData[ z ] [ E_OWNER ] == gangid )
 		{
			new
				facility_gang = g_gangTurfData[ z ] [ E_FACILITY_GANG ];

		   	if ( g_gangTurfData[ z ] [ E_FACILITY_GANG ] != INVALID_GANG_ID && Iter_Contains( gangs, g_gangTurfData[ z ] [ E_FACILITY_GANG ] ) )
		   	{
	    		g_gangTurfData[ z ] [ E_COLOR ] = setAlpha( g_gangData[ facility_gang ] [ E_COLOR ], 0x80 );
	 			g_gangTurfData[ z ] [ E_OWNER ] = facility_gang;
				GangZoneShowForAll( g_gangTurfData[ z ] [ E_ID ], g_gangTurfData[ z ] [ E_COLOR ] );
		   	}
		   	else
		   	{
	 			g_gangTurfData[ z ] [ E_COLOR ] = COLOR_GANGZONE;
	 			g_gangTurfData[ z ] [ E_OWNER ] = INVALID_GANG_ID;
				GangZoneShowForAll( g_gangTurfData[ z ] [ E_ID ], COLOR_GANGZONE );
		   	}
 		}
 	}
}

stock SaveGangData( gangid )
{
	if ( gangid == INVALID_GANG_ID )
		return;

	mysql_format( dbHandle, szLargeString, sizeof( szLargeString ), "UPDATE `GANGS` SET `NAME`='%e',`LEADER`=%d,`COLOR`=%d,`KILLS`=%d,`DEATHS`=%d,`SCORE`=%d,`BANK`=%d,`RESPECT`=%d WHERE `ID`=%d",
		g_gangData[ gangid ] [ E_NAME ], g_gangData[ gangid ] [ E_LEADER ], g_gangData[ gangid ] [ E_COLOR ], g_gangData[ gangid ] [ E_KILLS ], g_gangData[ gangid ] [ E_DEATHS ], g_gangData[ gangid ] [ E_SCORE ], g_gangData[ gangid ] [ E_BANK ], g_gangData[ gangid ] [ E_RESPECT ], g_gangData[ gangid ] [ E_SQL_ID ] );

	mysql_single_query( szLargeString );
}

stock IsPlayerGangLeader( playerid, gangid, only_leader = 0 ) {

	if ( g_gangData[ gangid ] [ E_LEADER ] == p_AccountID[ playerid ] )
		return true;

	// Reset coleaders
	if ( only_leader == 0 ) {
		for ( new i = 0; i < MAX_COLEADERS; i ++ ) {
			if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] == p_AccountID[ playerid ] )
				return true;
		}
	}
	return false;
}

stock DisconnectFromGang( playerid )
{
	new
		gangid = p_GangID[ playerid ];

	if ( gangid == INVALID_GANG_ID )
		return 0;

	p_GangID[ playerid ] = INVALID_GANG_ID;

	if ( ! Iter_Contains( gangs, gangid ) )
		return 0;

	if ( g_gangData[ gangid ] [ E_HAS_FACILITY ] ) // we will not soft delete gangs with facilities
		return 1;

	new
		members = GetOnlineGangMembers( gangid );

	printf("Gang id %d has currently %d members online", g_gangData[ gangid ] [ E_SQL_ID ], members );
	if ( members <= 0 ) {
		g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] = g_iTime + 60;
		printf("[GANG DEBUG] Begin soft delete Id %d Since No Ppl", g_gangData[ gangid ] [ E_SQL_ID ] );
	}
	return 1;
}

stock RemovePlayerFromGang( playerid, E_GANG_LEAVE_REASON: reason = GANG_LEAVE_UNKNOWN, otherid = INVALID_PLAYER_ID )
{
	new
		gangid = p_GangID[ playerid ];

 	p_GangID[ playerid ] = INVALID_GANG_ID;

	if ( !Iter_Contains( gangs, gangid ) )
		return 0;

	SetPlayerColorToTeam( playerid );

 	if ( g_gangData[ gangid ] [ E_LEADER ] == p_AccountID[ playerid ] )
 	{
 		new
 			selected_coleader = -1;

 		for ( new i = 0; i < MAX_COLEADERS; i ++ ) if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] ) {
 			selected_coleader = i;
 			break;
 		}

 		// Coleader exists?
 		if ( selected_coleader != -1 )
 		{
	 		g_gangData[ gangid ] [ E_LEADER ] = g_gangData[ gangid ] [ E_COLEADER ] [ selected_coleader ];
	 		g_gangData[ gangid ] [ E_COLEADER ] [ selected_coleader ] = 0;
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} The co-leader of the gang has been selected as the gang leader (acc id %d).", selected_coleader );
 		}
 		else
 		{
			// Set invalid player to allow for check
	 		g_gangData[ gangid ] [ E_LEADER ] = -1;

	 		// Look for leader substitute
		 	foreach(new memberid : Player)
		 	{
				if ( p_GangID[ memberid ] == gangid )
				{
					// Update color gang
					SetGangColorsToGang( gangid );
				    g_gangData[ gangid ] [ E_LEADER ] = p_AccountID[ memberid ];
					SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has been selected as the gang leader.", ReturnPlayerName( memberid ), memberid );
					break;
				}
		 	}

		 	// Cannot find any leader, so destroy
		 	if ( g_gangData[ gangid ] [ E_LEADER ] == -1 )
		 	{
		 		// Warn gang owner about gang
		 	    SendClientMessage( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} There was nobody online that could be a leader for this gang therefore it has been deleted from the server." );

		 		// Destroy gang internally
		 		DestroyGang( gangid, false );
		 		return 1;
		 	}
 		}
	}

	// reset the coleader
	for ( new i = 0; i < MAX_COLEADERS; i++ ) if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] == p_AccountID[ playerid ] ) {
 		g_gangData[ gangid ] [ E_COLEADER ] [ i ] = 0;
 	}

 	// wouldn't make sense to keep the coleader in any gang
 	mysql_single_query( sprintf( "DELETE FROM `GANG_COLEADERS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
 	mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=-1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );

 	printf("[%s] Gang ID after leaving is %d", ReturnPlayerName( playerid ), p_GangID[ playerid ] );

	// Alter the gang & players
	if ( Iter_Contains( gangs, gangid ) )
	{
		SaveGangData( gangid );
		CallLocalFunction( "OnPlayerLeaveGang", "ddd", playerid, gangid, _: reason );

		switch( reason )
		{
		    case GANG_LEAVE_KICK:
		    	SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has been kicked from the gang by %s(%d)!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( otherid ), otherid );

		    case GANG_LEAVE_UNKNOWN, GANG_LEAVE_QUIT:
		    	SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang!", ReturnPlayerName( playerid ), playerid );
		}
	}
	return 1;
}

stock HexToInt(string[]) // By DracoBlue
{
	if ( isnull( string ) )
		return 0;

  	new
  		cur = 1,
  		res = 0
  	;

	for( new i; string[ i ] != EOS; ++i )
	{
		string[ i ] = ( 'a' <= string[ i ] <= 'z' ) ? ( string[ i ] += 'A' - 'a' ) : ( string[ i ] );
	}

  	for( new i = strlen( string ); i > 0; i-- )
  	{
  	  	res += string[ i - 1 ] < 58 ? ( cur * ( string[ i - 1 ] - 48 ) ) : ( cur * ( string[ i - 1 ] - 65 + 10 ) );
    	cur *= 16;
  	}
  	return res;
}

stock ReturnGangNameColor( g )
{
	static
	    szColor[ 14 ];

	switch( g )
	{
		case 0:  szColor = "Yellow Green";
		case 1:  szColor = "Green";
		case 2:  szColor = "Blue Green";
		case 3:  szColor = "Blue";
		case 4:  szColor = "Blue Violet";
		case 5: szColor = "Violet";
		case 6: szColor = "Red Violet";
		default: szColor = "-??-";
	}
	return szColor;
}

stock gangNameExists( szName[ ] )
{
	foreach(new i : gangs)
	{
	    if ( strmatch( g_gangData[ i ] [ E_NAME ], szName ) ) return true;
	}
	return false;
}

stock SetGangColorsToGang( gangid )
{
	foreach ( new i : Player )
	{
	    foreach ( new x : turfs )
	    {
	    	// set the new color to the turfs
	    	if ( g_gangTurfData[ x ] [ E_OWNER ] == gangid ) {
	    		g_gangTurfData[ x ] [ E_COLOR ] = setAlpha( g_gangData[ gangid ] [ E_COLOR ], 0x80 );
	    	}

	    	// resume flashing if gang war
	    	if ( g_gangzoneAttacker[ x ] == gangid ) {
	    		GangZoneStopFlashForPlayer( i, g_gangTurfData[ x ] [ E_ID ] );
	    		GangZoneFlashForPlayer( i, g_gangTurfData[ x ] [ E_ID ], setAlpha( g_gangData[ gangid ] [ E_COLOR ], 0x80 ) );
	    	} else {
		        GangZoneHideForPlayer( i, g_gangTurfData[ x ] [ E_ID ] );
		        GangZoneShowForPlayer( i, g_gangTurfData[ x ] [ E_ID ], g_gangTurfData[ x ] [ E_COLOR ] );
	    	}
	    }

	    if ( p_GangID[ i ] == gangid && p_WantedLevel[ i ] <= 0 && p_Class[ i ] == CLASS_CIVILIAN ) {
	        SetPlayerColor( i, g_gangData[ gangid ] [ E_COLOR ] );
	    }
	}
}

stock isHex(str[])
{
    new
        i,
        cur;
    if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) i = 2;
    while (str[i])
    {
        cur = str[i++];
        if (!(('0' <= cur <= '9') || ('A' <= cur <= 'F') || ('a' <= cur <= 'f'))) return 0;
    }
    return 1;
}

stock IsWeaponInAnySlot( playerid, weaponid )
{
    new
        szWeapon, szAmmo;

    GetPlayerWeaponData( playerid, GetWeaponSlot( weaponid ), szWeapon, szAmmo );
    return ( szWeapon == weaponid && szAmmo > 0 );
}

#if !defined __WEAPONDAMAGEINC__
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

stock textContainsBadTextdrawLetters( const string[ ] )
{
	for( new i, j = strlen( string ); i < j; i++ )
	{
	    if ( string[ i ] == '.' || string[ i ] == '*' || string[ i ] == '^' || string[ i ] == '~' )
	        return true;
	}
	return false;
}

/*stock BanPlayerISP( playerid ) {
	if ( !IsPlayerConnected( playerid ) )
	    return;

	format( szLargeString, sizeof( szLargeString ), "INSERT INTO `MEGABAN`(`ISP`) VALUES ('%s')", mysql_escape( GetPlayerISP( playerid ) ) );
	mysql_single_query( szLargeString );

	if ( IsPlayerConnected( playerid ) )
		Kick( playerid );
}*/

stock IsValidSkin( skinid )
{
	if ( skinid == 74 || skinid > 311 || skinid < 0 )
	    return 0;

	return 1;
}

stock IsPlayerInCar( playerid )
{
    static
		g_CarVehicles[ 93 ] =
		{
			400,401,402,404,405,410,411,412,415,418,419,420,421,422,424,426,429,434,436,
			438,439,442,445,451,458,466,467,470,474,475,477,478,480,480,480,480,489,490,
			491,492,494,496,500,501,502,503,504,505,506,507,516,517,518,526,527,529,533,
			534,535,536,540,541,542,543,545,546,547,549,550,551,555,558,559,560,561,562,
			565,566,567,575,576,580,585,587,589,596,597,598,600,602,603,604,605
		}
	;
	for( new i; i < sizeof( g_CarVehicles ); i++ )
	{
	    if ( GetVehicleModel( GetPlayerVehicleID( playerid ) ) == g_CarVehicles[ i ] )
	        return 1;
	}
	return 0;
}

stock mysql_escape( string[ ] )
{
	static
	    szEscaped[ 256 ];

	if ( strlen( string ) >= 256 ) {
		printf("BUFFER OVERFLOW: %s", string);
	}

	mysql_real_escape_string( string, szEscaped );
	return szEscaped;
}

stock GetDayToString( day )
{
	static
	    string[ 10 ];

	switch( day )
	{
		case 0: string = "Monday";
		case 1: string = "Tuesday";
		case 2: string = "Wednesday";
		case 3: string = "Thursday";
		case 4: string = "Friday";
		case 5: string = "Saturday";
		case 6: string = "Sunday";
		default: string = "Bugged";
	}
	return string;
}


stock ShowAchievement( playerid, achievement[ ], score = -1 )
{
	if ( score != -1 ) {
		GivePlayerScore( playerid, score );
	}
	KillTimer( p_AchievementTimer[ playerid ] );
	p_AchievementTimer[ playerid ] = 0xFF;
	PlayerTextDrawSetString( playerid, p_AchievementTD[ playerid ], achievement );
	PlayerTextDrawShow( playerid, p_AchievementTD[ playerid ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 0 ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 1 ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 2 ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 3 ] );
	PlayerPlaySound( playerid, 1183, 0, 0, 0 );
	p_AchievementTimer[ playerid ] = SetTimerEx( "Achievement_Hide", 10000, false, "d", playerid );
}

function Achievement_Hide( playerid ) {
	PlayerTextDrawHide( playerid, p_AchievementTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 0 ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 1 ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 2 ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 3 ] );
    p_AchievementTimer[ playerid ] = 0xFF;
	StopSound( playerid );
    return 1;
}

stock SyncObject( playerid, Float: offsetX = 0.005, Float: offsetY = 0.005, Float: offsetZ = 0.005 )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( GetPlayerPos( playerid, X, Y, Z ) )
		SetPlayerPos( playerid, X + offsetX, Y + offsetY, Z + offsetZ );
}

CreateWeedPlant( Float: X, Float: Y, Float: Z, Float: rX, Float: rY, Float: rZ )
{
	new ID = -1;
	for( new i; i < MAX_WEED; i++ )
	{
	    if ( !g_weedData[ i ] [ E_CREATED ] ) {
			ID = i;
			break;
		}
	}
	if ( ID != -1 )
	{
		g_weedData[ ID ] [ E_CREATED ] = true;
		g_weedData[ ID ] [ E_OBJECT ] = CreateDynamicObject( 822, X, Y, Z, rX, rY, rZ );
		g_weedData[ ID ] [ E_CUT ] = false;
		g_weedData[ ID ] [ E_X ] = X;
		g_weedData[ ID ] [ E_Y ] = Y;
		g_weedData[ ID ] [ E_Z ] = Z;
	}
	return ID;
}

stock RenewWeed( )
{
    for( new i; i < MAX_WEED; i++ )
	{
	    if ( g_weedData[ i ] [ E_CREATED ] == true && g_weedData[ i ] [ E_CUT ] == true )
	    {
	        StopDynamicObject( g_weedData[ i ] [ E_OBJECT ] );
           	MoveDynamicObject( g_weedData[ i ] [ E_OBJECT ], g_weedData[ i ] [ E_X ], g_weedData[ i ] [ E_Y ], g_weedData[ i ] [ E_Z ], 0.75 );
			g_weedData[ i ] [ E_CREATED ] = true;
		    g_weedData[ i ] [ E_CUT ] = false;
			//DestroyDynamicObject( g_weedData[ i ] [ E_OBJECT ] );
			//g_treeData[ i ] [ E_OBJECT ] = CreateDynamicObject( 822, g_weedData[ i ] [ E_X ], g_weedData[ i ] [ E_Y ], g_weedData[ i ] [ E_Z ], g_weedData[ i ] [ E_RX ], g_weedData[ i ] [ E_RY ], 0.0 );
		}
	}
}

stock AddAdminLogLineFormatted( format[ ], va_args<> )
{
    static
		out[ sizeof( log__Text[ ] ) ];

    va_format( out, sizeof( out ), format, va_start<1> );
    return AddAdminLogLine( out );
}

stock AddAdminLogLine( szMessage[ sizeof( log__Text[ ] ) ] )
{
	for( new iPos = 0; iPos < sizeof( log__Text ) - 1; iPos++ )
		memcpy( log__Text[ iPos ], log__Text[ iPos + 1 ], 0, sizeof( log__Text[ ] ) * 4 );

	strcpy( log__Text[ 4 ], szMessage );
	DCC_SendChannelMessage( discordAdminChan, szMessage );

	format( szLargeString, 500,	"%s~n~%s~n~%s~n~%s~n~%s", log__Text[ 0 ], log__Text[ 1 ], log__Text[ 2 ], log__Text[ 3 ], log__Text[ 4 ] );
	return TextDrawSetString( g_AdminLogTD, szLargeString );
}

stock SaveToAdminLogFormatted( playerid, id, format[ ], va_args<> )
{
    static
		out[ sizeof( log__Text[ ] ) ];

    va_format( out, sizeof( out ), format, va_start<3> );
    return SaveToAdminLog( playerid, id, out );
}

stock SaveToAdminLog( playerid, id, message[ ] )
{
	if ( id ) {
		format( szBigString, sizeof( szBigString ),"INSERT INTO `ADMIN_LOG` (`USER_ID`, `ACTION`, `ACTION_ID`) VALUES (%d, '%s', %d)", p_AccountID[ playerid ], mysql_escape( message ), id );
	} else {
		format( szBigString, sizeof( szBigString ),"INSERT INTO `ADMIN_LOG` (`USER_ID`, `ACTION`) VALUES (%d, '%s')", p_AccountID[ playerid ], mysql_escape( message ) );
	}
	mysql_single_query( szBigString );
	return 1;
}


stock SyncSpectation( playerid, playerstate = -1 )
{
	if ( playerstate == -1 )
		playerstate = GetPlayerState( playerid );

	if ( IsPlayerConnected( playerid ) )
	{
	    if ( p_beingSpectated[ playerid ] )
	    {
	        if ( playerstate == PLAYER_STATE_DRIVER || playerstate == PLAYER_STATE_PASSENGER )
	        {
                foreach(new i : Player) {
	                if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid ) {
						SetPlayerInterior( i, GetPlayerInterior( playerid ) );
						SetPlayerVirtualWorld( i, GetPlayerVirtualWorld( playerid ) );
						PlayerSpectateVehicle( i, GetPlayerVehicleID( playerid ) );
	                }
				}
	        }
	        else
			{
                foreach(new i : Player) {
	                if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid ) {
						SetPlayerInterior( i, GetPlayerInterior( playerid ) );
						SetPlayerVirtualWorld( i, GetPlayerVirtualWorld( playerid ) );
						PlayerSpectatePlayer( i, playerid );
	                }
				}
			}
	    }
	}
	return 1;
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

stock secondstotime(seconds, const delimiter[] = ", ", start = 0, end = -1)
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

    static string[128];

    if (!seconds)
    {
    	string = "N/A";
    	return string;
    }

    erase(string);

    for(new i = start != 0 ? start : (sizeof(times) - 1); i != end; i--)
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

stock IsVehicleOccupied( vehicleid, bool: include_vehicle_interior = false )
{
	if ( ! IsValidVehicle( vehicleid ) )
		return -1;

	new
		iModel = GetVehicleModel( vehicleid );

	foreach ( new i : Player ) {
	    if ( GetPlayerVehicleID( i ) == vehicleid )
	    	return i;

		if ( include_vehicle_interior && IsPlayerSpawned( i ) && ( GetPlayerMethLabVehicle( i ) == vehicleid && iModel == 508 ) || ( ( GetPlayerVirtualWorld( i ) - VW_SHAMAL ) == vehicleid && iModel == 519 ) )
			return i;
	}
	return -1;
}

stock apartment_CallElevator( level )
{
	new Float: Z, Float: LastZ;

	if ( level >= MAX_AFLOORS )
	    return -1; // Invalid Floor

	switch( level ) {
	    case 0:     Z = 8.36;
	    case 1:     Z = 17.03;
	    default:    Z = 17.03 + ( ( level - 1 ) * 5.447 );
	}

	GetDynamicObjectPos( g_apartmentElevatorDoor1[ g_apartmentElevatorLevel ], LastZ, LastZ, LastZ );
	MoveDynamicObject( g_apartmentElevatorDoor1[ g_apartmentElevatorLevel ], -1955.05, 1361.64, LastZ, 5.0 );
	MoveDynamicObject( g_apartmentElevatorDoor2[ g_apartmentElevatorLevel ], -1955.05, 1361.64, LastZ, 5.0 );

	DestroyDynamicObject( g_apartmentElevatorGate ), g_apartmentElevatorGate = INVALID_OBJECT_ID;
	g_apartmentElevatorGate = CreateDynamicObject( 19304, -1955.08, 1363.74, LastZ, 0.00, 0.00, 0.00 );
 	SetObjectInvisible( g_apartmentElevatorGate ); // Just looks ugly...
	MoveDynamicObject( g_apartmentElevatorGate, -1955.08, 1363.74, Z, 7.0 );

	MoveDynamicObject( g_apartmentElevator, -1955.09, 1365.51, Z, 7.0 );

	g_apartmentElevatorLevel = level; // For the last level.
	return 1;
}

stock randarg( ... )
	return getarg( random( numargs( ) ) );

stock RemovePlayerWeapon(playerid, ...)
{
    new iArgs = numargs();
    while(--iArgs)
    {
        SetPlayerAmmo(playerid, getarg(iArgs), 0);
    }
}

stock IsMeleeWeapon(value) {
	static const valid_values[2] = {
		65535, 28928
	};
	if (0 <= value <= 46) {
		return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
	}
	return false;
}

stock IsPaintJobVehicle(value) {
    static const valid_values[3] = {
        1, 3670016, 806680576
    };
    if (483 <= value <= 576) {
        value -= 483;
        return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
    }
    return false;
}

stock IsVehicleUpsideDown(vehicleid)
{
    new
        Float: q_W,
        Float: q_X,
        Float: q_Y,
        Float: q_Z
    ;
    GetVehicleRotationQuat(vehicleid, q_W, q_X, q_Y, q_Z);
    return (120.0 < atan2(2.0 * ((q_Y * q_Z) + (q_X * q_W)), (-(q_X * q_X) - (q_Y * q_Y) + (q_Z * q_Z) + (q_W * q_W))) > -120.0);
}

stock ResetVehicleBurglaryData( vehicleid )
{
    if ( GetVehicleModel( vehicleid ) != 498 )
        return 0;

	new szString[ 18 ];
	for( new i; i < MAX_BURGLARY_SLOTS; i++ )
		format( szString, sizeof( szString ), "vburg_%d_%d", vehicleid, i ), DeleteGVar( szString );

    format( szString, sizeof( szString ), "vburg_%d_items", vehicleid );
    DeleteGVar( szString );
	return 1;
}

stock RemovePlayerStolensFromHands( playerid )
{
	DeletePVar( playerid, "stolen_fid" );
	RemovePlayerAttachedObject( playerid, 3 );
	SetPlayerSpecialAction( playerid, 0 );
	return 1;
}


stock IsPlayerInWater(playerid) // SuperViper
{
    new animationIndex = GetPlayerAnimationIndex(playerid);
    return (animationIndex >= 1538 && animationIndex <= 1544 && animationIndex != 1542);
}

stock ForceSpectateOnPlayer( playerid, pID )
{
	if ( IsPlayerConnected( p_whomSpectating[ playerid ] ) ) {
    	p_beingSpectated[ p_whomSpectating[ playerid ] ] = false;
    	p_whomSpectating[ playerid ] = INVALID_PLAYER_ID;
	}
    p_whomSpectating[ playerid ] = pID;
    p_beingSpectated[ pID ] = true;
	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You are now spectating %s(%d).", ReturnPlayerName( pID ), pID );
	SetPlayerVirtualWorld( playerid, GetPlayerVirtualWorld( pID ) );
	SetPlayerInterior( playerid, GetPlayerInterior( pID ) );
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

stock KickPlayerTimed( playerid )
	return SetTimerEx( "KickPlayer", 500, false, "d", playerid );

function KickPlayer( playerid )
	return SetPVarInt( playerid, "banned_connection", 1 ), Kick( playerid );

stock returnCityName( city )
{
	static
		string[ 13 ];

	switch( city )
	{
		case CITY_SF: string = "San Fierro";
		case CITY_LV: string = "Las Venturas";
		case CITY_LS: string = "Los Santos";
		default: string = "Random City";
	}
	return string;
}

stock jailMoveGate( playerid, city, bool: close = false, bool: alcatraz = false )
{
	static const
		Float: speed = 2.0;

	if ( !close && IsPlayerAdminJailed( playerid ) )
		return;

	if ( alcatraz )
	{
		if ( close ) MoveDynamicObject( p_AlcatrazObject[ playerid ], -2013.164184, 1827.123168, 41.506713, speed );
		else MoveDynamicObject( p_AlcatrazObject[ playerid ], -2013.164184, 1827.123168, 41.506713 - 10.0, speed );
	 	return;
	}

	switch( city )
	{
		case CITY_LV:
		{
			if ( close )
			{
				MoveDynamicObject( p_JailObjectLV[ playerid ] [ 0 ], 198.94980, 160.26476, 1003.26135, speed );
				MoveDynamicObject( p_JailObjectLV[ playerid ] [ 1 ], 192.95604, 177.08791, 1003.26215, speed );
				MoveDynamicObject( p_JailObjectLV[ playerid ] [ 2 ], 197.19141, 177.08476, 1003.26215, speed );
			}
			else
			{
				MoveDynamicObject( p_JailObjectLV[ playerid ] [ 0 ], 197.18980, 160.26480, 1003.26141, speed );
				MoveDynamicObject( p_JailObjectLV[ playerid ] [ 1 ], 194.69600, 177.08791, 1003.26208, speed );
				MoveDynamicObject( p_JailObjectLV[ playerid ] [ 2 ], 198.95140, 177.08479, 1003.26208, speed );
			}
		}
		case CITY_SF:
		{
			if ( close )
			{
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 0 ], 214.68274, 112.62182, 999.29553, speed );
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 1 ], 218.61810, 112.62180, 999.29547, speed );
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 2 ], 222.62241, 112.62180, 999.29547, speed );
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 3 ], 226.51570, 112.62180, 999.29547, speed );
			}
			else
			{
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 0 ], 216.44754, 112.61965, 999.29547, speed );
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 1 ], 220.40450, 112.62180, 999.29547, speed );
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 2 ], 224.40781, 112.62180, 999.29547, speed );
				MoveDynamicObject( p_JailObjectSF[ playerid ] [ 3 ], 228.27820, 112.62180, 999.29547, speed );
			}
		}
		case CITY_LS:
		{
			if ( close )
			{
				MoveDynamicObject( p_JailObjectLS[ playerid ] [ 0 ], 266.36481, 85.710700, 1001.27979, speed );
				MoveDynamicObject( p_JailObjectLS[ playerid ] [ 1 ], 266.36481, 81.211600, 1001.27979, speed );
				MoveDynamicObject( p_JailObjectLS[ playerid ] [ 2 ], 266.36481, 76.709470, 1001.27985, speed );
			}
			else
			{
				MoveDynamicObject( p_JailObjectLS[ playerid ] [ 0 ], 266.36481, 87.45710, 1001.27979, speed );
				MoveDynamicObject( p_JailObjectLS[ playerid ] [ 1 ], 266.36481, 82.95660, 1001.27979, speed );
				MoveDynamicObject( p_JailObjectLS[ playerid ] [ 2 ], 266.36481, 78.44830, 1001.27979, speed );
			}
		}
	}
}

stock jailDoors( playerid, remove = false, set_closed = true )
{
	if ( set_closed )
	{
		if ( IsValidDynamicObject( p_JailObjectLV[ playerid ] [ 0 ] ) || IsValidDynamicObject( p_JailObjectSF[ playerid ] [ 0 ] ) || IsValidDynamicObject( p_JailObjectLS[ playerid ] [ 0 ] ) )
		{
			SetDynamicObjectPos( p_JailObjectLV[ playerid ] [ 0 ], 198.94980, 160.26476, 1003.26135 );
			SetDynamicObjectPos( p_JailObjectLV[ playerid ] [ 1 ], 192.95604, 177.08791, 1003.26215 );
			SetDynamicObjectPos( p_JailObjectLV[ playerid ] [ 2 ], 197.19141, 177.08476, 1003.26215 );

			SetDynamicObjectPos( p_JailObjectSF[ playerid ] [ 0 ], 214.68274, 112.62182, 999.29553 );
			SetDynamicObjectPos( p_JailObjectSF[ playerid ] [ 1 ], 218.61810, 112.62180, 999.29547 );
			SetDynamicObjectPos( p_JailObjectSF[ playerid ] [ 2 ], 222.62241, 112.62180, 999.29547 );
			SetDynamicObjectPos( p_JailObjectSF[ playerid ] [ 3 ], 226.51570, 112.62180, 999.29547 );

			SetDynamicObjectPos( p_JailObjectLS[ playerid ] [ 0 ], 266.36481, 85.710700, 1001.27979 );
			SetDynamicObjectPos( p_JailObjectLS[ playerid ] [ 1 ], 266.36481, 81.211600, 1001.27979 );
			SetDynamicObjectPos( p_JailObjectLS[ playerid ] [ 2 ], 266.36481, 76.709470, 1001.27985 );

			SetDynamicObjectPos( p_AlcatrazObject[ playerid ], -2013.164184, 1827.123168, 41.506713 );
			return;
		}
	}

	if ( !remove )
	{
		if ( IsValidDynamicObject( p_JailObjectLV[ playerid ] [ 0 ] ) || IsValidDynamicObject( p_JailObjectSF[ playerid ] [ 0 ] ) || IsValidDynamicObject( p_JailObjectLS[ playerid ] [ 0 ] ) )
		{
			DestroyDynamicObject( p_JailObjectLV[ playerid ] [ 0 ] ), p_JailObjectLV[ playerid ] [ 0 ] = INVALID_OBJECT_ID;
			DestroyDynamicObject( p_JailObjectLV[ playerid ] [ 1 ] ), p_JailObjectLV[ playerid ] [ 1 ] = INVALID_OBJECT_ID;
			DestroyDynamicObject( p_JailObjectLV[ playerid ] [ 2 ] ), p_JailObjectLV[ playerid ] [ 2 ] = INVALID_OBJECT_ID;

			DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 0 ] ), p_JailObjectSF[ playerid ] [ 0 ] = INVALID_OBJECT_ID;
			DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 1 ] ), p_JailObjectSF[ playerid ] [ 1 ] = INVALID_OBJECT_ID;
			DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 2 ] ), p_JailObjectSF[ playerid ] [ 2 ] = INVALID_OBJECT_ID;
			DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 3 ] ), p_JailObjectSF[ playerid ] [ 3 ] = INVALID_OBJECT_ID;

			DestroyDynamicObject( p_JailObjectLS[ playerid ] [ 0 ] ), p_JailObjectLS[ playerid ] [ 0 ] = INVALID_OBJECT_ID;
			DestroyDynamicObject( p_JailObjectLS[ playerid ] [ 1 ] ), p_JailObjectLS[ playerid ] [ 1 ] = INVALID_OBJECT_ID;
			DestroyDynamicObject( p_JailObjectLS[ playerid ] [ 2 ] ), p_JailObjectLS[ playerid ] [ 2 ] = INVALID_OBJECT_ID;

			DestroyDynamicObject( p_AlcatrazObject[ playerid ] ), p_AlcatrazObject[ playerid ] = INVALID_OBJECT_ID;
		}

		p_JailObjectLV[ playerid ] [ 0 ] = CreateDynamicObject( 19303, 198.94980, 160.26476, 1003.26135, 0.00000, 0.00000, 0.00000, -1, -1, playerid );
		p_JailObjectLV[ playerid ] [ 1 ] = CreateDynamicObject( 19302, 192.95604, 177.08791, 1003.26215, 0.00000, 0.00000, 0.00000, -1, -1, playerid );
		p_JailObjectLV[ playerid ] [ 2 ] = CreateDynamicObject( 19302, 197.19141, 177.08476, 1003.26215, 0.00000, 0.00000, 0.00000, -1, -1, playerid );

		p_JailObjectSF[ playerid ] [ 0 ] = CreateDynamicObject( 19302, 214.68274, 112.62182, 999.295530, 0.00000, 0.00000, 0.00000, -1, -1, playerid );
		p_JailObjectSF[ playerid ] [ 1 ] = CreateDynamicObject( 19302, 218.61810, 112.62180, 999.295470, 0.00000, 0.00000, 0.00000, -1, -1, playerid );
		p_JailObjectSF[ playerid ] [ 2 ] = CreateDynamicObject( 19302, 222.62241, 112.62180, 999.295470, 0.00000, 0.00000, 0.00000, -1, -1, playerid );
		p_JailObjectSF[ playerid ] [ 3 ] = CreateDynamicObject( 19302, 226.51570, 112.62180, 999.295470, 0.00000, 0.00000, 0.00000, -1, -1, playerid );

		p_JailObjectLS[ playerid ] [ 0 ] = CreateDynamicObject( 19302, 266.36481, 85.710700, 1001.27979, 0.00000, 0.00000, 90.0000, -1, -1, playerid );
		p_JailObjectLS[ playerid ] [ 1 ] = CreateDynamicObject( 19302, 266.36481, 81.211600, 1001.27979, 0.00000, 0.00000, 90.0000, -1, -1, playerid );
		p_JailObjectLS[ playerid ] [ 2 ] = CreateDynamicObject( 19302, 266.36481, 76.709470, 1001.27985, 0.00000, 0.00000, 90.0000, -1, -1, playerid );

		p_AlcatrazObject[ playerid ] = CreateDynamicObject( 749, -2013.164184, 1827.123168, 41.506713, 11.800004, 0.000000, 0.000000, -1, -1, playerid );
		SetDynamicObjectMaterial( p_AlcatrazObject[ playerid ], 2, 9135, "vgseseabed", "vgs_rockmid1a", -47 );
		SetDynamicObjectMaterial( p_AlcatrazObject[ playerid ], 1, 0, "none", "none", 0 );
	}
	else
	{
		DestroyDynamicObject( p_JailObjectLV[ playerid ] [ 0 ] ), p_JailObjectLV[ playerid ] [ 0 ] = INVALID_OBJECT_ID;
		DestroyDynamicObject( p_JailObjectLV[ playerid ] [ 1 ] ), p_JailObjectLV[ playerid ] [ 1 ] = INVALID_OBJECT_ID;
		DestroyDynamicObject( p_JailObjectLV[ playerid ] [ 2 ] ), p_JailObjectLV[ playerid ] [ 2 ] = INVALID_OBJECT_ID;

		DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 0 ] ), p_JailObjectSF[ playerid ] [ 0 ] = INVALID_OBJECT_ID;
		DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 1 ] ), p_JailObjectSF[ playerid ] [ 1 ] = INVALID_OBJECT_ID;
		DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 2 ] ), p_JailObjectSF[ playerid ] [ 2 ] = INVALID_OBJECT_ID;
		DestroyDynamicObject( p_JailObjectSF[ playerid ] [ 3 ] ), p_JailObjectSF[ playerid ] [ 3 ] = INVALID_OBJECT_ID;

		DestroyDynamicObject( p_JailObjectLS[ playerid ] [ 0 ] ), p_JailObjectLS[ playerid ] [ 0 ] = INVALID_OBJECT_ID;
		DestroyDynamicObject( p_JailObjectLS[ playerid ] [ 1 ] ), p_JailObjectLS[ playerid ] [ 1 ] = INVALID_OBJECT_ID;
		DestroyDynamicObject( p_JailObjectLS[ playerid ] [ 2 ] ), p_JailObjectLS[ playerid ] [ 2 ] = INVALID_OBJECT_ID;

		DestroyDynamicObject( p_AlcatrazObject[ playerid ] ), p_AlcatrazObject[ playerid ] = INVALID_OBJECT_ID;
	}
}

stock autosaveStart( playerid, bool: force_save = false )
{
	new
		iTime = g_iTime;

    if ( IsPlayerSettingToggled( playerid, SETTING_AUTOSAVE ) && force_save == false )
		return;

    if ( GetPVarInt( playerid, "last_transaction" ) > iTime && force_save == false )
    	return;

	SavePlayerData( playerid );
	SetPVarInt( playerid, "last_transaction", iTime + 15 );
	SendClientMessage( playerid, -1, IsPlayerSettingToggled( playerid, SETTING_AUTOSAVE ) ? ( ""COL_LRED"[AUTO-SAVE]"COL_WHITE" Your statistics have been saved." ) :  (""COL_LRED"[AUTO-SAVE]"COL_WHITE" Your statistics have been saved, "COL_GREY"you can disable this over /cp"COL_WHITE"." ) );
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

new
	p_HideHelpDialogTimer[ MAX_PLAYERS ] = { -1, ... };

stock ShowPlayerHelpDialog( playerid, timeout, format[ ], va_args<> )
{
    static
		out[ 255 ]
	;

	if ( !IsPlayerConnected( playerid ) )
		return 0;

    va_format( out, sizeof( out ), format, va_start<3> );

    PlayerTextDrawSetString( playerid, p_HelpBoxTD[ playerid ], out );
    PlayerTextDrawShow( playerid, p_HelpBoxTD[ playerid ] );

    KillTimer( p_HideHelpDialogTimer[ playerid ] );
    p_HideHelpDialogTimer[ playerid ] = -1;

   	if ( timeout != 0 ) {
   		p_HideHelpDialogTimer[ playerid ] = SetTimerEx( "HidePlayerHelpDialog", timeout, false, "d", playerid );
   	}
	return 1;
}

function HidePlayerHelpDialog( playerid )
{
	if ( p_HideHelpDialogTimer[ playerid ] != -1 )
	{
		p_HideHelpDialogTimer[ playerid ] = -1;
		PlayerTextDrawHide( playerid, p_HelpBoxTD[ playerid ] );
	}
}

stock fix_NightThermalVisionHack( playerid ) // Created by wups
{
    static
    	weapon;

    weapon = GetPlayerWeapon( playerid );
    if ( weapon == 44 || weapon == 45 )
    {
        static
            HoldingFire[ MAX_PLAYERS ],
            IsHoldingFire[ MAX_PLAYERS char ],
            CanHoldAgain[ MAX_PLAYERS char ],
            keys, lr, tick
      	;

        GetPlayerKeys( playerid, keys, lr, lr);
        tick = GetTickCount( );

        if ( keys & KEY_FIRE )
        {
            if ( !IsHoldingFire{ playerid } && CanHoldAgain{ playerid } )
            {
                IsHoldingFire{ playerid } = 1;
                HoldingFire[ playerid ] = tick;
                CanHoldAgain{ playerid } = 0;
            }
        }
        else if ( !CanHoldAgain{ playerid } ) CanHoldAgain{ playerid } = 1;

        if ( IsHoldingFire{ playerid } )
        {
            if ( tick - 1500 <= HoldingFire[ playerid ] )
            {
                return 0;
            }
            else
            {
                IsHoldingFire{ playerid } = 0;
                return 1;
            }
        }
    }
    return 1;
}

thread OnGatesLoad( )
{
	new
		rows, fields, i = -1, gID,
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			gID = cache_get_field_content_int( i, "ID", dbHandle );

			cache_get_field_content( i, "PASSWORD", 			g_gateData[ gID ] [ E_PASS ], dbHandle, 8 );
			cache_get_field_content( i, "NAME", 				g_gateData[ gID ] [ E_NAME ], dbHandle, 24 );

			g_gateData[ gID ] [ E_OWNER ] = cache_get_field_content_int( i, "OWNER", dbHandle );
			g_gateData[ gID ] [ E_MODEL ] = cache_get_field_content_int( i, "MODEL", dbHandle );
			g_gateData[ gID ] [ E_TIME ] = cache_get_field_content_int( i, "TIME", dbHandle );
			g_gateData[ gID ] [ E_SPEED ] = cache_get_field_content_float( i, "SPEED", dbHandle );
			g_gateData[ gID ] [ E_RANGE ] = cache_get_field_content_float( i, "RANGE", dbHandle );
			g_gateData[ gID ] [ E_X ] = cache_get_field_content_float( i, "X", dbHandle );
			g_gateData[ gID ] [ E_Y ] = cache_get_field_content_float( i, "Y", dbHandle );
			g_gateData[ gID ] [ E_Z ] = cache_get_field_content_float( i, "Z", dbHandle );
			g_gateData[ gID ] [ E_RX ] = cache_get_field_content_float( i, "RX", dbHandle );
			g_gateData[ gID ] [ E_RY ] = cache_get_field_content_float( i, "RY", dbHandle );
			g_gateData[ gID ] [ E_RZ ] = cache_get_field_content_float( i, "RZ", dbHandle );
			g_gateData[ gID ] [ E_MOVE_X ] = cache_get_field_content_float( i, "MOVE_X", dbHandle );
			g_gateData[ gID ] [ E_MOVE_Y ] = cache_get_field_content_float( i, "MOVE_Y", dbHandle );
			g_gateData[ gID ] [ E_MOVE_Z ] = cache_get_field_content_float( i, "MOVE_Z", dbHandle );
			g_gateData[ gID ] [ E_MOVE_RX ] = cache_get_field_content_float( i, "MOVE_RX", dbHandle );
			g_gateData[ gID ] [ E_MOVE_RY ] = cache_get_field_content_float( i, "MOVE_RY", dbHandle );
			g_gateData[ gID ] [ E_MOVE_RZ ] = cache_get_field_content_float( i, "MOVE_RZ", dbHandle );
			g_gateData[ gID ] [ E_GANG_SQL_ID ] = cache_get_field_content_int( i, "GANG_ID", dbHandle );

			g_gateData[ gID ] [ E_CLOSE_TIMER ] = -1;
			g_gateData[ gID ] [ E_OBJECT ] = CreateDynamicObject( g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );

	    	Iter_Add(gates, gID);
		}
	}
	printf( "[GATES]: %d gates have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

stock CreateGate( playerid, password[ 8 ], model, Float: speed, Float: range, Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz )
{
	new gID = Iter_Free(gates);

	if ( gID != ITER_NONE )
	{
		erase( g_gateData[ gID ] [ E_NAME ] );

		format( g_gateData[ gID ] [ E_PASS ], 8, "%s", password );
		format( g_gateData[ gID ] [ E_NAME ], 24, "Gate" );
		g_gateData[ gID ] [ E_OWNER ] = p_AccountID[ playerid ];
		g_gateData[ gID ] [ E_MODEL ] = model;
		g_gateData[ gID ] [ E_SPEED ] = speed;
		g_gateData[ gID ] [ E_TIME ] = 2000;
		g_gateData[ gID ] [ E_CLOSE_TIMER ] = -1;
		g_gateData[ gID ] [ E_RANGE ] = range;
		g_gateData[ gID ] [ E_X ] = x;
		g_gateData[ gID ] [ E_Y ] = y;
		g_gateData[ gID ] [ E_Z ] = z;
		g_gateData[ gID ] [ E_RX ] = rx;
		g_gateData[ gID ] [ E_RY ] = ry;
		g_gateData[ gID ] [ E_RZ ] = rz;
		g_gateData[ gID ] [ E_MOVE_X ] = x;
		g_gateData[ gID ] [ E_MOVE_Y ] = y;
		g_gateData[ gID ] [ E_MOVE_Z ] = z;
		g_gateData[ gID ] [ E_MOVE_RX ] = rx;
		g_gateData[ gID ] [ E_MOVE_RY ] = ry;
		g_gateData[ gID ] [ E_MOVE_RZ ] = rz;
		g_gateData[ gID ] [ E_GANG_SQL_ID ] = 0;

		format( szBigString, sizeof( szBigString ), "INSERT INTO `GATES` VALUES(%d,%d,'%s','Gate',%d,2000,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,0)", gID, playerid, mysql_escape( password ), model, speed, range, x, y, z, rx, ry, rz, x, y, z, rx, ry, rz );
		mysql_single_query( szBigString );

		g_gateData[ gID ] [ E_OBJECT ] = CreateDynamicObject( g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );
		Iter_Add(gates, gID);
	}
	return gID;
}

stock getClosestGate( playerid, &Float: dis = 99999.99 )
{
	new
		Float: dis2,
		object = INVALID_OBJECT_ID
	;
	foreach(new i : gates)
	{
    	dis2 = GetPlayerDistanceFromPoint( playerid, g_gateData[ i ] [ E_X ], g_gateData[ i ] [ E_Y ], g_gateData[ i ] [ E_Z ] );
    	if ( dis2 < dis && dis2 != -1.00 ) {
    	    dis = dis2;
    	    object = i;
		}
	}
	return object;
}

stock UpdateGateData( gID, bool: recreate_obj = true )
{
	if ( Iter_Contains( gates, gID ) )
	{
		format( szLargeString, sizeof( szLargeString ),
			"UPDATE `GATES` SET `OWNER`=%d,`NAME`='%s',`PASSWORD`='%s',`MODEL`=%d,`TIME`=%d,`SPEED`=%f,`RANGE`=%f,`X`=%f,`Y`=%f,`Z`=%f,`RX`=%f,`RY`=%f,`RZ`=%f,`MOVE_X`=%f,`MOVE_Y`=%f,`MOVE_Z`=%f,`MOVE_RX`=%f,`MOVE_RY`=%f,`MOVE_RZ`=%f WHERE `ID`=%d",
			g_gateData[ gID ] [ E_OWNER ], mysql_escape( g_gateData[ gID ] [ E_NAME ] ), mysql_escape( g_gateData[ gID ] [ E_PASS ] ), g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_TIME ], g_gateData[ gID ] [ E_SPEED ], g_gateData[ gID ] [ E_RANGE ],
			g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ],
			g_gateData[ gID ] [ E_MOVE_X ], g_gateData[ gID ] [ E_MOVE_Y ], g_gateData[ gID ] [ E_MOVE_Z ], g_gateData[ gID ] [ E_MOVE_RX ], g_gateData[ gID ] [ E_MOVE_RY ], g_gateData[ gID ] [ E_MOVE_RZ ], gID );

		mysql_single_query( szLargeString );

		if ( recreate_obj ) {
			DestroyDynamicObject( g_gateData[ gID ] [ E_OBJECT ] );
			g_gateData[ gID ] [ E_OBJECT ] = CreateDynamicObject( g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );
		}
	}
}

stock OpenPlayerGate( forplayerid, g )
{
	if ( g_gateData[ g ] [ E_CLOSE_TIMER ] != -1 ) {
		return 0;
	}

	if ( forplayerid != INVALID_PLAYER_ID && !strmatch( g_gateData[ g ] [ E_NAME ], "N/A" ) ) {
		SendClientMessageFormatted( forplayerid, -1, ""COL_GREY"[GATE]"COL_WHITE" You've opened "COL_GREY"%s"COL_WHITE".", g_gateData[ g ] [ E_NAME ] );
	}

	new
		travelInterval = MoveDynamicObject( g_gateData[ g ] [ E_OBJECT ], g_gateData[ g ] [ E_MOVE_X ], g_gateData[ g ] [ E_MOVE_Y ], g_gateData[ g ] [ E_MOVE_Z ], g_gateData[ g ] [ E_SPEED ], g_gateData[ g ] [ E_MOVE_RX ], g_gateData[ g ] [ E_MOVE_RY ], g_gateData[ g ] [ E_MOVE_RZ ] );

	g_gateData[ g ] [ E_CLOSE_TIMER ] = SetTimerEx( "StartGateClose", travelInterval + g_gateData[ g ] [ E_TIME ], false, "d", g );
	return 1;
}


function StartGateClose( gID ) {
	g_gateData[ gID ] [ E_CLOSE_TIMER ] = -1;
	return MoveDynamicObject( g_gateData[ gID ] [ E_OBJECT ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_SPEED ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] ), 1;
}

stock hasBadDrivebyWeapon( playerid )
{
	for( new i; i < sizeof g_BannedDrivebyWeapons; i++ )
		if ( g_BannedDrivebyWeapons[ i ] == GetPlayerWeapon( playerid ) )
			return true;

	return false;
}

stock SetPlayerVipLevel( pID, level, interval = 2592000 )
{
	if ( IsPlayerConnected( pID ) )
	{
		// force upgrade
		if ( p_VIPLevel[ pID ] < level ) {
			p_VIPLevel[ pID ] = level;
		}

		if ( level ) {
		    if ( p_VIPExpiretime[ pID ] > g_iTime ) p_VIPExpiretime[ pID ] += interval;
		    else p_VIPExpiretime[ pID ] += ( g_iTime + interval );
		}

		// expire the players vip if level 0
		else {
			p_VIPExpiretime[ pID ] = 0;
		}
	}
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

stock KillEveryoneInShamal( vehicleid )
{
	static
		Float: X, Float: Y, Float: Z;

	foreach(new i : Player) {
		if ( IsPlayerInShamal( i ) && ( GetPlayerVirtualWorld( i ) - VW_SHAMAL ) == vehicleid ) {
			if ( IsValidVehicle( vehicleid ) ) {
				GetPlayerPos( i, X, Y, Z );
				CreateExplosionForPlayer( i, X, Y, Z - 0.75, 0, 10.0 );
				SetPlayerHealth( i, -1 );
			}
		}
	}
}

stock adhereBanCodes( string[ ], maxlength = sizeof( string ) ) {
    for( new i; i < sizeof( g_banCodes ); i++ ) {
    	if ( strfind( string, g_banCodes[ i ] [ E_CODE ], false ) != -1 ) {
			strreplace( string, g_banCodes[ i ] [ E_CODE ], g_banCodes[ i ] [ E_DATA ], false, 0, -1, maxlength );
		}
	}
	return 1;
}

stock CreateExplosionEx( Float: X, Float: Y, Float: Z, type, Float: radius, world, interior, issuerid = INVALID_PLAYER_ID )
{
	foreach(new i : Player) {
		if ( IsPlayerLoadingObjects( i ) ) continue;
		if ( p_BulletInvulnerbility[ i ] > g_iTime ) continue;
		if ( interior != -1 && GetPlayerInterior( i ) != interior ) continue;
		if ( world != -1 && GetPlayerVirtualWorld( i ) != world ) continue;
		//if ( IsDeathmatchProtectedZone( i ) && !p_WantedLevel[ i ] ) continue;
		if ( IsRandomDeathmatch( issuerid, i ) && issuerid != i ) continue;
		CreateExplosionForPlayer( i, X, Y, Z, type, radius );
	}
}

stock massUnjailPlayers( city, bool: alcatraz = false )
{
	foreach(new p : Player)
    {
		if ( IsPlayerAdminJailed( p ) )
			continue;

		if ( !IsPlayerInJails( p, city ) && !alcatraz )
			continue;

		//if ( IsPlayerAFK( p ) )
		//	continue;

		jailMoveGate( p, city, false, alcatraz ); // Show everyone
		if ( p_Jailed{ p } == true )
		{
			CallLocalFunction( "OnPlayerUnjailed", "dd", p, alcatraz ? 5 : 4 );
			SetPlayerHealth( p, INVALID_PLAYER_ID ); // Just ensuring.
	        SetTimerEx( "RestoreHealthAfterBrokenOut", 5000, false, "d", p );
		}
	}
}

stock IsPlayerInJails( playerid, city )
{
	static const
		g_jailIntData[ MAX_CITIES ] = { 10, 3, 6 } // Ordered SF, LV, LS
	;

	return ( GetPlayerInterior( playerid ) == g_jailIntData[ city ] );
}

stock GetPlayerBankCity( playerid )
{
	static const
		g_bankIntData[ MAX_CITIES ] [ 2 ] = { 23, 52, 56 }
	;

	for( new i = 0; i < sizeof( g_bankIntData ); i++ )
	{
		if ( GetPlayerVirtualWorld( playerid ) == g_bankIntData[ i ] && GetPlayerInterior( playerid ) == i )
			return i;
	}
	return -1;
}

stock getClosestPoliceStation( playerid )
{
	static const
		Float: g_policeStationCoords[ ] [ 3 ] =
		{
		 	{ -1605.330, 711.6586, 13.8672 }, // SF
			{ 2337.0854, 2459.313, 14.9742 }, // LV
			{ 1555.5012, -1675.63, 16.1953 }  // LS
		}
	;

    static
    	Float: X, Float: Y, Float: Z,
    	iCity, iEntrance
    ;

    if ( !GetPlayerInterior( playerid ) ) GetPlayerPos( playerid, X, Y, Z );
	else
   	{
		if ( ( iEntrance = p_LastEnteredEntrance[ playerid ] ) == -1 ) GetPlayerPos( playerid, X, Y, Z );
		else
		{
			GetEntrancePos( iEntrance, X, Y, Z );
		}
   	}

    for( new i = 0, Float: fLast = -1.0, Float: fDistance = 99999.0; i < sizeof( g_policeStationCoords ); i++ )
	{
	    fLast = GetDistanceBetweenPoints( X, Y, Z, g_policeStationCoords[ i ] [ 0 ], g_policeStationCoords[ i ] [ 1 ], g_policeStationCoords[ i ] [ 2 ] );
	    if ( fLast < fDistance && fLast ) {
	        fDistance = fLast;
	        iCity = i;
	    }
	}
    return iCity;
}

stock Achievement::HandleBurglaries( playerid )
{
   	switch( ++ p_Burglaries[ playerid ] )
   	{
   	    case 5:     ShowAchievement( playerid, "Commited ~r~5~w~~h~~h~ burglaries!", 3 );
   	    case 20:    ShowAchievement( playerid, "Commited ~r~20~w~~h~~h~ burglaries!", 6 );
   	    case 50:    ShowAchievement( playerid, "Commited ~r~50~w~~h~~h~ burglaries!", 9 );
   	    case 100:   ShowAchievement( playerid, "Commited ~r~100~w~~h~~h~ burglaries!", 12 );
   	    case 200:   ShowAchievement( playerid, "Commited ~r~200~w~~h~~h~ burglaries!", 15 );
   	    case 500:   ShowAchievement( playerid, "Commited ~r~500~w~~h~~h~ burglaries!", 18 );
   	    case 1000:  ShowAchievement( playerid, "Commited ~r~1000~w~~h~~h~ burglaries!", 25 );
	}
}

stock Achievement::HandleBankBlown( playerid )
{
	switch( ++p_BankBlown[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "Blown Bank Vault ~r~5~w~~h~~h~ Times!", 3 );
	    case 20:  	ShowAchievement( playerid, "Blown Bank Vault ~r~20~w~~h~~h~ Times!", 6 );
	    case 50:   	ShowAchievement( playerid, "Blown Bank Vault ~r~50~w~~h~~h~ Times!", 9 );
	    case 100:  	ShowAchievement( playerid, "Blown Bank Vault ~r~100~w~~h~~h~ Times!", 12 );
	    case 200:  	ShowAchievement( playerid, "Blown Bank Vault ~r~200~w~~h~~h~ Times!", 15 );
	    case 500:  	ShowAchievement( playerid, "Blown Bank Vault ~r~500~w~~h~~h~ Times!", 18 );
	    case 1000: 	ShowAchievement( playerid, "Blown Bank Vault ~r~1000~w~~h~~h~ Times!", 25 );
	}
}

stock Achievement::HandleCarJacked( playerid )
{
	switch( ++p_CarsJacked[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "Jacked ~r~5~w~~h~~h~ Cars!" , 3 );
	    case 20:  	ShowAchievement( playerid, "Jacked ~r~20~w~~h~~h~ Cars!", 6 );
	    case 50:   	ShowAchievement( playerid, "Jacked ~r~50~w~~h~~h~ Cars!", 9 );
	    case 100:  	ShowAchievement( playerid, "Jacked ~r~100~w~~h~~h~ Cars!", 12 );
	    case 200:  	ShowAchievement( playerid, "Jacked ~r~200~w~~h~~h~ Cars!", 15 );
	    case 500:  	ShowAchievement( playerid, "Jacked ~r~500~w~~h~~h~ Cars!", 18 );
	    case 1000: 	ShowAchievement( playerid, "Jacked ~r~1000~w~~h~~h~ Cars!", 25 );
	}
}

stock Achievement::HandleJailBlown( playerid )
{
	switch( ++p_JailsBlown[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "Blown Jail ~r~5~w~~h~~h~ Times!", 3 );
	    case 20:  	ShowAchievement( playerid, "Blown Jail ~r~20~w~~h~~h~ Times!", 6 );
	    case 50:   	ShowAchievement( playerid, "Blown Jail ~r~50~w~~h~~h~ Times!", 9 );
	    case 100:  	ShowAchievement( playerid, "Blown Jail ~r~100~w~~h~~h~ Times!", 12 );
	    case 200:  	ShowAchievement( playerid, "Blown Jail ~r~200~w~~h~~h~ Times!", 15 );
	    case 500:  	ShowAchievement( playerid, "Blown Jail ~r~500~w~~h~~h~ Times!", 18 );
	    case 1000: 	ShowAchievement( playerid, "Blown Jail ~r~1000~w~~h~~h~ Times!", 25 );
	}
}

stock Achievement::HandleExtinguishedFires( playerid )
{
    switch( ++p_Fires[ playerid ] )
   	{
   	    case 5:     ShowAchievement( playerid, "Extinguished ~r~5~w~~h~~h~ fires!", 3 );
   	    case 20:    ShowAchievement( playerid, "Extinguished ~r~20~w~~h~~h~ fires!", 6 );
   	    case 50:    ShowAchievement( playerid, "Extinguished ~r~50~w~~h~~h~ fires!", 9 );
   	    case 100:   ShowAchievement( playerid, "Extinguished ~r~100~w~~h~~h~ fires!", 12 );
   	    case 200:   ShowAchievement( playerid, "Extinguished ~r~200~w~~h~~h~ fires!", 15 );
   	    case 500:   ShowAchievement( playerid, "Extinguished ~r~500~w~~h~~h~ fires!", 18 );
   	    case 1000:  ShowAchievement( playerid, "Extinguished ~r~1000~w~~h~~h~ fires!", 25 );
	}
}

stock Achievement::HandleMethYielded( playerid )
{
	switch( ++p_MethYielded[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "Yielded ~r~5~w~~h~~h~ Meth Bags!", 3 );
	    case 20:  	ShowAchievement( playerid, "Yielded ~r~20~w~~h~~h~ Meth Bags!", 6 );
	    case 50:   	ShowAchievement( playerid, "Yielded ~r~50~w~~h~~h~ Meth Bags!", 9 );
	    case 100:  	ShowAchievement( playerid, "Yielded ~r~100~w~~h~~h~ Meth Bags!", 12 );
	    case 200:  	ShowAchievement( playerid, "Yielded ~r~200~w~~h~~h~ Meth Bags!", 15 );
	    case 500:  	ShowAchievement( playerid, "Yielded ~r~500~w~~h~~h~ Meth Bags!", 18 );
	    case 1000: 	ShowAchievement( playerid, "Yielded ~r~1000~w~~h~~h~ Meth Bags!", 25 );
	}
}

stock Achievement::HandlePlayerRobbery( playerid )
{
	Streak_IncrementPlayerStreak( playerid, STREAK_ROBBERY );

	switch( ++p_Robberies[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "Robbed ~r~5~w~~h~~h~ stores!", 3 );
	    case 20:    ShowAchievement( playerid, "Robbed ~r~20~w~~h~~h~ stores!", 6 );
	    case 50:    ShowAchievement( playerid, "Robbed ~r~50~w~~h~~h~ stores!", 9 );
	    case 100:   ShowAchievement( playerid, "Robbed ~r~100~w~~h~~h~ stores!", 12 );
	    case 200:   ShowAchievement( playerid, "Robbed ~r~200~w~~h~~h~ stores!", 15 );
	    case 500:   ShowAchievement( playerid, "Robbed ~r~500~w~~h~~h~ stores!", 18 );
	    case 1000:  ShowAchievement( playerid, "Robbed ~r~1000~w~~h~~h~ stores!", 25 );
	}
}

stock Achievement::HandleTruckingCouriers( playerid )
{
	switch( ++p_TruckedCargo[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "Trucked ~r~5~w~~h~~h~ cargo!", 3 );
	    case 20:    ShowAchievement( playerid, "Trucked ~r~20~w~~h~~h~ cargo!", 6 );
	    case 50:    ShowAchievement( playerid, "Trucked ~r~50~w~~h~~h~ cargo!", 9 );
	    case 100:   ShowAchievement( playerid, "Trucked ~r~100~w~~h~~h~ cargo!", 12 );
	    case 200:   ShowAchievement( playerid, "Trucked ~r~200~w~~h~~h~ cargo!", 15 );
	    case 500:   ShowAchievement( playerid, "Trucked ~r~500~w~~h~~h~ cargo!", 18 );
	    case 1000:  ShowAchievement( playerid, "Trucked ~r~1000~w~~h~~h~ cargo!", 25 );
	}
}

stock Achievement::HandlePilotMissions( playerid )
{
	switch( ++p_PilotMissions[ playerid ])
	{
		case 5:     ShowAchievement( playerid, "Completed ~r~5~w~~h~~h~ pilot missions!", 3 );
	    case 20:    ShowAchievement( playerid, "Completed ~r~20~w~~h~~h~ pilot missions!", 6 );
	    case 50:    ShowAchievement( playerid, "Completed ~r~50~w~~h~~h~ pilot missions!", 9 );
	    case 100:   ShowAchievement( playerid, "Completed ~r~100~w~~h~~h~ pilot missions!", 12 );
	    case 200:   ShowAchievement( playerid, "Completed ~r~200~w~~h~~h~ pilot missions!", 15 );
	    case 500:   ShowAchievement( playerid, "Completed ~r~500~w~~h~~h~ pilot missions!", 18 );
	    case 1000:  ShowAchievement( playerid, "Completed ~r~1000~w~~h~~h~ pilot missions!", 25 );
	}
}

stock Achievement::HandleTrainMissions( playerid )
{
	switch( ++p_TrainMissions[ playerid ])
	{
		case 5:     ShowAchievement( playerid, "Completed ~r~5~w~~h~~h~ train missions!", 3 );
	    case 20:    ShowAchievement( playerid, "Completed ~r~20~w~~h~~h~ train missions!", 6 );
	    case 50:    ShowAchievement( playerid, "Completed ~r~50~w~~h~~h~ train missions!", 9 );
	    case 100:   ShowAchievement( playerid, "Completed ~r~100~w~~h~~h~ train missions!", 12 );
	    case 200:   ShowAchievement( playerid, "Completed ~r~200~w~~h~~h~ train missions!", 15 );
	    case 500:   ShowAchievement( playerid, "Completed ~r~500~w~~h~~h~ train missions!", 18 );
	    case 1000:  ShowAchievement( playerid, "Completed ~r~1000~w~~h~~h~ train missions!", 25 );
	}
}

thread readplayernotes( playerid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		ID,
    		i = 0,
    		Field[ 30 ],
    		szNote[ 72 ]
    	;

    	szHugeString = ""COL_GREY"ID\tTime\t\t\tNote\n" #COL_WHITE;

		while( i < rows )
		{
			cache_get_field_content( i, "ID", Field ), 		 ID = strval( Field );
			cache_get_field_content( i, "NOTE", szNote );
			cache_get_field_content( i, "TIME", Field );

			format( szHugeString, sizeof( szHugeString ), "%s%05d\t%s\t%s\n", szHugeString, ID, Field, szNote );
			i++;
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Player Notes", szHugeString, "Okay", "" );
		return 1;
	}
	SendError( playerid, "This user does not have any notes." );
	return 1;
}

thread readnamechanges( playerid, searchid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTime[ 20 ],
    		szName[ MAX_PLAYER_NAME ]
    	;

    	szLargeString = ""COL_GREY"Time\t\t\tName\n" #COL_WHITE;

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "TIME", szTime );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, szTime, szName );
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, sprintf( "{FFFFFF}Name changes of %s(%d)", ReturnPlayerName( searchid ), searchid ), szLargeString, "Okay", "" );
		return 1;
	}
	SendError( playerid, "This user has not recently changed their name." );
	return 1;
}

thread readmoneylog( playerid, searchid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTime[ 20 ],
    		szName[ MAX_PLAYER_NAME ],
    		iCashMoney
    	;

    	szLargeString = COL_WHITE # "Sent to\t" #COL_WHITE "Amount\t" #COL_WHITE "Time\n";

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "DATE", szTime );
			iCashMoney = cache_get_field_content_int( i, "CASH", dbHandle );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\t%s\n", szLargeString, szName, cash_format( iCashMoney ), szTime );
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}Transactions sent by %s(%d)", ReturnPlayerName( searchid ), searchid ), szLargeString, "Okay", "" );
		return 1;
	}
	SendError( playerid, "This user has not recently made any transactions." );
	return 1;
}

thread readiclog( playerid, searchid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTime[ 20 ],
    		szName[ MAX_PLAYER_NAME ],
    		Float: fCoins
    	;

    	szLargeString = COL_WHITE # "Time\t" #COL_WHITE "Sent to\t" #COL_WHITE "Amount\n";

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "DATE", szTime );
			fCoins = cache_get_field_content_float( i, "IC", dbHandle );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\t%f\n", szLargeString, szTime, szName, fCoins );
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}IC Transactions sent by %s(%d)", ReturnPlayerName( searchid ), searchid ), szLargeString, "Okay", "" );
		return 1;
	}
	SendError( playerid, "This user has not recently made any IC transactions." );
	return 1;
}

thread deleteplayernote( playerid, noteid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

	if ( rows ) {
		SaveToAdminLog( playerid, noteid, "removed note" );
 		format( szNormalString, 64, "UPDATE `NOTES` SET `DELETED`=%d WHERE `ID`=%d", p_AccountID[ playerid ], noteid ), mysql_single_query( szNormalString );
 		SendServerMessage( playerid, "You have removed note id %d. If there are any problems, contact Lorenc/Council.", noteid );
		AddAdminLogLineFormatted( "%s(%d) has deleted note id %d", ReturnPlayerName( playerid ), playerid, noteid );
 		return 1;
	}

 	SendError( playerid, "Couldn't remove note id %d due to it being already deleted or invalid permissions.", noteid );
	return 1;
}

stock AddPlayerNote( playerid, authorid, note[ ] ) {
	format( szBigString, sizeof( szBigString ), "INSERT INTO `NOTES`(`USER_ID`, `ADDED_BY`, `NOTE`) VALUES (%d,%d,'%s')", p_AccountID[ playerid ], IsPlayerConnected( authorid ) ? p_AccountID[ authorid ] : 1, mysql_escape( note ) );
	mysql_single_query( szBigString );
}

stock IsPlayerInBank( playerid )
{
	static const
		valid_values[ 2 ] = { 536870913, 2 }
	;

	if ( GetPlayerInterior( playerid ) > 3 )
		return false;

	new
		value = GetPlayerVirtualWorld( playerid );

	if ( 23 <= value <= 56 ) {
		value -= 23;
		return ( valid_values[ value >>> 5 ] & ( 1 << ( value & 31 ) ) ) || false;
	}
	return false;
}

stock displayAchievements( playerid, dialogid = DIALOG_NULL, szSecondButton[ ] = "", forid = INVALID_PLAYER_ID )
{
	static
		szAchievements[ 1500 ];

	format( szAchievements, sizeof( szAchievements ),
		""COL_GREY"Played For\t\t\t%s10m\t%s1h\t%s5h\t%s10h\t%s15h\t%s20h\t%s1d\n",
		Ach_Unlock( p_Uptime[ playerid ], 1200 ), 		Ach_Unlock( p_Uptime[ playerid ], 3600 ), 		Ach_Unlock( p_Uptime[ playerid ], 18000 ),
		Ach_Unlock( p_Uptime[ playerid ], 36000 ), 		Ach_Unlock( p_Uptime[ playerid ], 54000 ), 		Ach_Unlock( p_Uptime[ playerid ], 72000 ),
		Ach_Unlock( p_Uptime[ playerid ], 86400 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Kills Achieved\t\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Kills[ playerid ], 5 ), 			Ach_Unlock( p_Kills[ playerid ], 20 ),     		Ach_Unlock( p_Kills[ playerid ], 50 ),
		Ach_Unlock( p_Kills[ playerid ], 100 ), 		Ach_Unlock( p_Kills[ playerid ], 200 ),    		Ach_Unlock( p_Kills[ playerid ], 500 ),
		Ach_Unlock( p_Kills[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Arrested Criminals\t\t%s5\t%s20\t50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Arrests[ playerid ], 5 ),     	Ach_Unlock( p_Arrests[ playerid ], 20 ),    	Ach_Unlock( p_Arrests[ playerid ], 50 ),
		Ach_Unlock( p_Arrests[ playerid ], 100 ),   	Ach_Unlock( p_Arrests[ playerid ], 200 ),   	Ach_Unlock( p_Arrests[ playerid ], 500 ),
		Ach_Unlock( p_Arrests[ playerid ], 1000 )
	);

	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Total Robberies\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Robberies[ playerid ], 5 ),		Ach_Unlock( p_Robberies[ playerid ], 20 ),		Ach_Unlock( p_Robberies[ playerid ], 50 ),
		Ach_Unlock( p_Robberies[ playerid ], 100 ),		Ach_Unlock( p_Robberies[ playerid ], 200 ),		Ach_Unlock( p_Robberies[ playerid ], 500 ),
		Ach_Unlock( p_Robberies[ playerid ], 1000 )
	);

	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Extinguished Fires\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Fires[ playerid ], 5 ),     		Ach_Unlock( p_Fires[ playerid ], 20 ),    		Ach_Unlock( p_Fires[ playerid ], 50 ),
		Ach_Unlock( p_Fires[ playerid ], 100 ),   		Ach_Unlock( p_Fires[ playerid ], 200 ),   		Ach_Unlock( p_Fires[ playerid ], 500 ),
		Ach_Unlock( p_Fires[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Completed Contracts\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_HitsComplete[ playerid ], 5 ),     Ach_Unlock( p_HitsComplete[ playerid ], 20 ), 	Ach_Unlock( p_HitsComplete[ playerid ], 50 ),
		Ach_Unlock( p_HitsComplete[ playerid ], 100 ),   Ach_Unlock( p_HitsComplete[ playerid ], 200 ), Ach_Unlock( p_HitsComplete[ playerid ], 500 ),
		Ach_Unlock( p_HitsComplete[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Commited Burglaries\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Burglaries[ playerid ], 5 ),     	Ach_Unlock( p_Burglaries[ playerid ], 20 ),    	Ach_Unlock( p_Burglaries[ playerid ], 50 ),
		Ach_Unlock( p_Burglaries[ playerid ], 100 ),   	Ach_Unlock( p_Burglaries[ playerid ], 200 ),   	Ach_Unlock( p_Burglaries[ playerid ], 500 ),
		Ach_Unlock( p_Burglaries[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Yielded Meth Bags\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_MethYielded[ playerid ], 5 ),     Ach_Unlock( p_MethYielded[ playerid ], 20 ),    Ach_Unlock( p_MethYielded[ playerid ], 50 ),
		Ach_Unlock( p_MethYielded[ playerid ], 100 ),   Ach_Unlock( p_MethYielded[ playerid ], 200 ),   Ach_Unlock( p_MethYielded[ playerid ], 500 ),
		Ach_Unlock( p_MethYielded[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Cars Jacked\t\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_CarsJacked[ playerid ], 5 ),     	Ach_Unlock( p_CarsJacked[ playerid ], 20 ),    	Ach_Unlock( p_CarsJacked[ playerid ], 50 ),
		Ach_Unlock( p_CarsJacked[ playerid ], 100 ),   	Ach_Unlock( p_CarsJacked[ playerid ], 200 ),   	Ach_Unlock( p_CarsJacked[ playerid ], 500 ),
		Ach_Unlock( p_CarsJacked[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Blew Bank Vault\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_BankBlown[ playerid ], 5 ),     	Ach_Unlock( p_BankBlown[ playerid ], 20 ),    	Ach_Unlock( p_BankBlown[ playerid ], 50 ),
		Ach_Unlock( p_BankBlown[ playerid ], 100 ),   	Ach_Unlock( p_BankBlown[ playerid ], 200 ),   	Ach_Unlock( p_BankBlown[ playerid ], 500 ),
		Ach_Unlock( p_BankBlown[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Blew Jail Cells\t\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_JailsBlown[ playerid ], 5 ),     	Ach_Unlock( p_JailsBlown[ playerid ], 20 ),    	Ach_Unlock( p_JailsBlown[ playerid ], 50 ),
		Ach_Unlock( p_JailsBlown[ playerid ], 100 ),   	Ach_Unlock( p_JailsBlown[ playerid ], 200 ),   	Ach_Unlock( p_JailsBlown[ playerid ], 500 ),
		Ach_Unlock( p_JailsBlown[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Total Trucked Cargo\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_TruckedCargo[ playerid ], 5 ),     Ach_Unlock( p_TruckedCargo[ playerid ], 20 ),    	Ach_Unlock( p_TruckedCargo[ playerid ], 50 ),
		Ach_Unlock( p_TruckedCargo[ playerid ], 100 ),   Ach_Unlock( p_TruckedCargo[ playerid ], 200 ),   	Ach_Unlock( p_TruckedCargo[ playerid ], 500 ),
		Ach_Unlock( p_TruckedCargo[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Total Pilot Missions\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_PilotMissions[ playerid ], 5 ),     Ach_Unlock( p_PilotMissions[ playerid ], 20 ),    	Ach_Unlock( p_PilotMissions[ playerid ], 50 ),
		Ach_Unlock( p_PilotMissions[ playerid ], 100 ),   Ach_Unlock( p_PilotMissions[ playerid ], 200 ),   	Ach_Unlock( p_PilotMissions[ playerid ], 500 ),
		Ach_Unlock( p_PilotMissions[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"Total Train Missions\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_TrainMissions[ playerid ], 5 ),     Ach_Unlock( p_TrainMissions[ playerid ], 20 ),    	Ach_Unlock( p_TrainMissions[ playerid ], 50 ),
		Ach_Unlock( p_TrainMissions[ playerid ], 100 ),   Ach_Unlock( p_TrainMissions[ playerid ], 200 ),   	Ach_Unlock( p_TrainMissions[ playerid ], 500 ),
		Ach_Unlock( p_TrainMissions[ playerid ], 1000 )
	);

	if ( !IsPlayerConnected( forid ) ) forid = playerid;
	ShowPlayerDialog( forid, dialogid, DIALOG_STYLE_MSGBOX, "{FFFFFF}Achievements", szAchievements, "Okay", szSecondButton );
}

stock PlainUnjailPlayer( playerid )
{
	p_inAlcatraz{ playerid } = false;
    p_Jailed 	{ playerid } = false;
    p_JailTime 	[ playerid ] = 0;

	format( szNormalString, sizeof( szNormalString ), "UPDATE USERS SET JAIL_TIME=0,JAIL_ADMIN=0 WHERE ID=%d", p_AccountID[ playerid ] );
	mysql_single_query( szNormalString );

    KillTimer( p_JailTimer[ playerid ] );
	PlayerTextDrawHide( playerid, p_JailTimeTD[ playerid ] );
}

stock isNotNearPlayer( playerid, nearid, Float: distance = 200.0 )
{
	if ( ! IsPlayerNPC( playerid ) && ( GetTickCount( ) - p_AFKTime[ playerid ] ) >= 500 )
		return 0;

	if ( ! IsPlayerConnected( nearid ) )
		return 1;

	if ( IsPlayerAFK( nearid ) )
		return 1;

	new
		Float: X, Float: Y, Float: Z;

	if ( GetPlayerInterior( playerid ) == GetPlayerInterior( nearid ) && GetPlayerVirtualWorld( playerid ) == GetPlayerVirtualWorld( nearid ) ) {
		GetPlayerPos( nearid, X, Y, Z );
	} else {
		GetPlayerOutsidePos( nearid, X, Y, Z );
	}
	return GetPlayerDistanceFromPoint( playerid, X, Y, Z ) > distance ? 1 : 0;
}

stock GetVehicleDriver( vehicleid )
{
	foreach(new i : Player)
		if ( IsPlayerInVehicle( i, vehicleid ) && GetPlayerState( i ) == PLAYER_STATE_DRIVER )
			return i;

	return INVALID_PLAYER_ID;
}

/*stock CreateNoDeathmatchZone( const Float: fRadius, const Float: fX, const Float: fY, const fSize = 15 ) // Warning: do not change size!
{
	new
		iZone = Iter_Free(rdmzone);

	if ( iZone != ITER_NONE )
	{
	    new
	        Float: fIncrement = 90.0 / fSize,
	        Float: fDegrees = fIncrement,
	        Float: fCos,
	        Float: fSin,
	        iGangZone = -1
	    ;

	    while( fDegrees < 90.0 )
	    {
	        fCos = floatcos( fDegrees, degrees ) * fRadius;
	        fSin = floatsin( fDegrees, degrees ) * fRadius;

	        g_antiDeathmatchZoneData[ iZone ] [ E_GANGZONES ] [ ++iGangZone ] = GangZoneCreate( fX - fCos, fY - fSin, fX + fCos, fY + fSin );
	        g_antiDeathmatchZoneData[ iZone ] [ E_CIRCLE ] = CreateDynamicCircle( fX, fY, fRadius );

	        fDegrees += fIncrement;
	    }

	    Iter_Add(rdmzone, iZone);
	}
}

stock IsDeathmatchProtectedZone( playerid ) {

	if ( IsPlayerInPaintBall( playerid ) )
		return false;

	if ( IsPlayerInEntrance( playerid, g_Ammunation ) || IsPlayerInEntrance( playerid, g_PoliceDepartment ) || IsPlayerInEntrance( playerid, g_Hospital ) )
		return true;

	if ( IsPlayerInBank( playerid ) )
		return true;

	foreach(new r : rdmzone)
		if ( IsPlayerInDynamicArea( playerid, g_antiDeathmatchZoneData[ r ] [ E_CIRCLE ] ) )
			return true;

	return false;
}*/

stock GetPlayerLocation( iPlayer, szCity[ ], szLocation[ ] )
{
	static
		Float: X, Float: Y, Float: Z;

	GetPlayerOutsidePos( iPlayer, X, Y, Z );

	Get2DCity( szCity, X, Y, Z );
	GetZoneFromCoordinates( szLocation, X, Y, Z );
	return true;
}

stock WarnPlayerClass( playerid, bool: bArmy = false, iPoints = 1 )
{
	new
		iWarns = bArmy ? ( p_ArmyBanned{ playerid } += iPoints ) : ( p_CopBanned{ playerid } += iPoints );

	if ( iWarns > MAX_CLASS_BAN_WARNS )
		iWarns = bArmy ? ( p_ArmyBanned{ playerid } = MAX_CLASS_BAN_WARNS ) : ( p_CopBanned{ playerid } = MAX_CLASS_BAN_WARNS );

	if ( p_Class[ playerid ] != CLASS_CIVILIAN && iWarns >= MAX_CLASS_BAN_WARNS )
		SetPlayerHealth( playerid, -1 ), ForceClassSelection( playerid );

	if ( iWarns >= MAX_CLASS_BAN_WARNS )
		SendServerMessage( playerid, "You have been %s-banned due to many offenses, use "COL_GREY"/unbanme"COL_WHITE" to unban yourself.", bArmy ? ( "army" ) : ( "cop" ) );

	mysql_single_query( sprintf( "UPDATE `USERS` SET `%s`=%d WHERE ID=%d", bArmy ? ( "ARMY_BAN" ) : ( "COP_BAN" ), iWarns, p_AccountID[ playerid ] ) );

	return iWarns;
}

stock IsRandomDeathmatch( issuerid, damagedid )
{
	if ( issuerid != INVALID_PLAYER_ID && damagedid != INVALID_PLAYER_ID )
	{
		new
			iW = p_WantedLevel[ issuerid ], 	iC = p_Class[ issuerid ],
			dW = p_WantedLevel[ damagedid ], 	dC = p_Class[ damagedid ]
		;

		if ( IsPlayerInMinigame( damagedid ) || IsPlayerInMinigame( issuerid ) )
			return true;

		if ( IsPlayerBoxing( issuerid ) )
			return false;

		if ( IsPlayerPassive( damagedid ) )
			return true;

		if ( ! IsPlayerInCasino( issuerid ) || ! IsPlayerInCasino( damagedid ) )
			return false;

		return ( !iW && iC != CLASS_POLICE && !dW && dC != CLASS_POLICE ) || ( iW && iC != CLASS_POLICE && !dW && dC != CLASS_POLICE ) || ( !iW && iC != CLASS_POLICE && dW && dC != CLASS_POLICE ) || ( !iW && iC != CLASS_POLICE && dC == CLASS_POLICE );
	}
	return false;
}

stock IsPlayerInCasino( playerid ) {
	new world = GetPlayerVirtualWorld( playerid );
	if ( GetPlayerState( playerid ) != PLAYER_STATE_ONFOOT ) return 0;
	if ( GetPlayerInterior( playerid ) == VISAGE_INTERIOR && world == VISAGE_WORLD ) return 1; // visage itself
	if ( IsPlayerInRangeOfPoint( playerid, 100.0, 1993.0846, 1904.5693, 84.2848 ) && world != 0 ) return 1; // visage apartments
	if ( IsPlayerInRangeOfPoint( playerid, 10.0, -792.8680, 661.2518, 19.3380 ) && world == 0 ) return 1; // roycegate mansion
	return ( GetPlayerInterior( playerid ) == 10 && GetPlayerVirtualWorld( playerid ) == 23 ) || ( GetPlayerInterior( playerid ) == 1 && GetPlayerVirtualWorld( playerid ) == 82 );
}

stock ShowPlayerBankMenuDialog( playerid )
{
	new
		gangid = p_GangID[ playerid ];

	if ( gangid != -1 && Iter_Contains( gangs, gangid ) ) {
		format( szBigString, sizeof( szBigString ), "Withdraw\nDeposit\nAccount Information\n{%06x}Gang Bank Withdraw\n{%06x}Gang Bank Deposit\n{%06x}Gang Bank Balance", g_gangData[ gangid ] [ E_COLOR ] >>> 8, g_gangData[ gangid ] [ E_COLOR ] >>> 8, g_gangData[ gangid ] [ E_COLOR ] >>> 8 );
		return ShowPlayerDialog( playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "{FFFFFF}Account", szBigString, "Select", "Cancel" );
	}

	return ShowPlayerDialog( playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "{FFFFFF}Account", "Withdraw\nDeposit\nAccount Information", "Select", "Cancel" );
}

stock SetPlayerPosition( playerid, Float: x, Float: y, Float: z, interiorid = 0, worldid = 0 )
{
	new
		vehicleid = GetPlayerVehicleID( playerid );

    SetPlayerInterior( playerid, interiorid );
    SetPlayerVirtualWorld( playerid, worldid );

	if ( 0 < vehicleid < MAX_VEHICLES )
	{
		SetVehicleVirtualWorld( vehicleid, worldid );
		LinkVehicleToInterior( vehicleid, interiorid );
		return SetVehiclePos( vehicleid, x, y, z );
	}

	return SetPlayerPos( playerid, x, y, z );
}

stock GetOnlineGangMembers( gangid, &afk_members = 0 )
{
	if ( gangid == INVALID_GANG_ID )
		return 0;

	new
		iPlayers = 0;

	foreach ( new playerid : Player ) if ( p_GangID[ playerid ] == gangid ) {
		if ( IsPlayerAFK( playerid ) ) afk_members ++;
		iPlayers ++;
	}
	return iPlayers;
}

stock SplitPlayerCashForGang( playerid, Float: cashRobbed )
{
	new
		bGangProfitSplit = ( p_GangID[ playerid ] != INVALID_GANG_ID && p_GangSplitProfits[ playerid ] ), Float: cashBanked = 0;

	if ( bGangProfitSplit )
	{
		new
			Float: keepOnHand = cashRobbed;

		cashRobbed = ( keepOnHand * float( 100 - p_GangSplitProfits[ playerid ] ) ) / 100.0;
		cashBanked = ( keepOnHand * float( p_GangSplitProfits[ playerid ] ) ) / 100.0;

		new
			iRoundedBanked = floatround( cashBanked, floatround_floor );

		SendServerMessage( playerid, "You've split %s (%d%s) towards your gang's bank balance.", cash_format( iRoundedBanked ), p_GangSplitProfits[ playerid ], "%%" );

		/*if ( -1 < iRoundedBanked > 50000 )
		{
			printf( "[EXPLOIT] [0xC1] %s has tried to store %s to gang %d", ReturnPlayerName( playerid ), cash_format( iRoundedBanked ), p_GangID[ playerid ] );
			return SendError( playerid, "An exploit (0xC2) had occured, therefore this robbery was denied. Please report this to Lorenc!" );
		}*/

		g_gangData[ p_GangID[ playerid ] ] [ E_BANK ] += iRoundedBanked;
	}

	new
		iRoundedRobbed = floatround( cashRobbed, floatround_floor );

	if ( iRoundedRobbed != 0 )
	{
		/*if ( -1 < iRoundedRobbed > 50000 )
		{
			printf( "[EXPLOIT] [0xC1] %s has robbed %s", ReturnPlayerName( playerid ), cash_format( iRoundedRobbed ) );
			return SendError( playerid, "An exploit (0xC1) had occured, therefore this robbery was denied. Please report this to Lorenc!" );
		}*/

		GivePlayerCash( playerid, iRoundedRobbed );
	}
	return 1;
}

stock ShowPlayerTogglableTextdraws( playerid, bool: force = false )
{
	// Current Coins
	if ( ! IsPlayerSettingToggled( playerid, SETTING_COINS_BAR ) || force ) {
		TextDrawShowForPlayer( playerid, g_CurrentCoinsTD );
		PlayerTextDrawShow( playerid, p_CoinsTD[ playerid ] );
	}

	// Top donor
	if ( ! IsPlayerSettingToggled( playerid, SETTING_TOP_DONOR ) || force ) {
		TextDrawShowForPlayer( playerid, g_TopDonorTD );
	}
}

stock HidePlayerTogglableTextdraws( playerid, bool: force = true )
{
	// Current Coins
	if ( IsPlayerSettingToggled( playerid, SETTING_COINS_BAR ) || force ) {
		TextDrawHideForPlayer( playerid, g_CurrentCoinsTD );
		PlayerTextDrawHide( playerid, p_CoinsTD[ playerid ] );
	}

	// Top donor
	if ( IsPlayerSettingToggled( playerid, SETTING_TOP_DONOR ) || force ) {
		TextDrawHideForPlayer( playerid, g_TopDonorTD );
	}
}

stock CheckPlayerVipExpiry( playerid )
{
    if ( p_VIPLevel[ playerid ] > 0 && g_iTime > p_VIPExpiretime[ playerid ] )
    {
		SetPlayerArmour( playerid, 0.0 );
        p_VIPExpiretime[ playerid ] = 0;
        SendClientMessage( playerid, -1, ""COL_GREY"[NOTIFICATION]"COL_WHITE" Your V.I.P has expired, consider another donation to have your V.I.P restored again for another period." );
        p_VIPLevel[ playerid ] = 0;
        p_VIPWep1{ playerid } = 0;
        p_VIPWep2{ playerid } = 0;
        p_VIPWep3{ playerid } = 0;
	}
}

thread OnNewNameCheckBanned( playerid, Float: iCoinRequirement, newName[ ] )
{
	new
	    rows;

	cache_get_data( rows, tmpVariable );

	if ( !rows )
	{
	  	return mysql_function_query( dbHandle, sprintf( "SELECT `NAME` FROM `USERS` WHERE `NAME` = '%s'", mysql_escape( newName ) ), true, "OnPlayerChangeName", "dfs", playerid, iCoinRequirement, newName ), 1;
	}
	else
	{
		SendError( playerid, "This name is currently banned. Please choose another name." );
		return ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "Change your name", ""COL_WHITE"What would you like your new name to be? And also, double check!", "Change", "Back" ), 1;
	}
}

thread OnPlayerChangeName( playerid, Float: iCoinRequirement, newName[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );

	if ( !rows )
	{
	 	mysql_single_query( sprintf( "UPDATE `USERS` SET `NAME` = '%s' WHERE `NAME` = '%s'", mysql_escape( newName ), mysql_escape( ReturnPlayerName( playerid ) ) ) );
	 	mysql_single_query( sprintf( "INSERT INTO `NAME_CHANGES`(`USER_ID`,`ADMIN_ID`,`NAME`) VALUES (%d,0,'%s')", p_AccountID[ playerid ], mysql_escape( ReturnPlayerName( playerid ) ) ) );

	 	// double check if valid coin requirement
	 	if ( iCoinRequirement ) {
			GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
			SendServerMessage( playerid, "You have changed your name to for %s Irresistible Coins!", number_format( iCoinRequirement, .decimals = 0 ) );
	 	}

    	// Update houses (furniture also?)
	 	mysql_single_query( sprintf( "UPDATE `HOUSES` SET `OWNER` = '%s' WHERE `OWNER` = '%s'", mysql_escape( newName ), mysql_escape( ReturnPlayerName( playerid ) ) ) );

    	foreach ( new i : houses ) if ( IsPlayerHomeOwner( playerid, i ) ) {
			format( g_houseData[ i ] [ E_OWNER ], 24, "%s", newName );
			format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" %s(%d)\n"COL_GOLD"Owner:"COL_WHITE" %s\n"COL_GOLD"Price:"COL_WHITE" %s", g_houseData[ i ] [ E_HOUSE_NAME ], i, g_houseData[ i ] [ E_OWNER ], cash_format( g_houseData[ i ] [ E_COST ] ) );
			UpdateDynamic3DTextLabelText( g_houseData[ i ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );
    	}

    	// Update apartments
	 	mysql_single_query( sprintf( "UPDATE `APARTMENTS` SET `OWNER` = '%s' WHERE `OWNER` = '%s'", mysql_escape( newName ), mysql_escape( ReturnPlayerName( playerid ) ) ) );

    	for( new i = 0; i < sizeof( g_apartmentData ); i++ )
    		if ( strmatch( g_apartmentData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
				format( g_apartmentData[ i ] [ E_OWNER ], 24, "%s", newName );

    	// Update username
		SetPlayerName( playerid, newName );

    	// Update garages
    	UpdatePlayerGarageTitles( playerid );
	}
	else
	{
		SendError( playerid, "This name is taken already." );
		ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "Change your name", ""COL_WHITE"What would you like your new name to be? And also, double check!", "Change", "Back" );
	}
	return 1;
}

thread OnListGangMembers( playerid, gangid, page )
{
	new
	    rows, i;

	cache_get_data( rows, tmpVariable );

	if ( rows )
	{
		static
			userName[ MAX_PLAYER_NAME ];

		for( i = 0, szLargeString[ 0 ] = '\0'; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", userName );
			format( szLargeString, sizeof( szLargeString ), "%s%s%s\n", szLargeString, cache_get_field_content_int( i, "ONLINE", dbHandle ) ? ( #COL_GREEN ) : ( #COL_WHITE ), userName );
		}

		SetPVarInt( playerid, "gang_members_id", gangid );
		SetPVarInt( playerid, "gang_members_results", rows );
		SetPVarInt( playerid, "gang_members_page", page );
		ShowPlayerDialog( playerid, DIALOG_GANG_LIST_MEMBERS, DIALOG_STYLE_LIST, sprintf( ""COL_WHITE"Gang Members - Page %d", page + 1 ), szLargeString, rows >= 20 ? ( "Next" ) : ( "Close" ), "Back" );
	}
	else
	{
		// Notify user
		SendError( playerid, "This gang no longer has any members." );
	}
	return 1;
}

stock GivePlayerLeoWeapons( playerid ) {
	GivePlayerWeapon( playerid, 3, 1 );
	GivePlayerWeapon( playerid, 22, 250 );
	GivePlayerWeapon( playerid, 31, 250 );
	//GivePlayerWeapon( playerid, 41, 0xFFFF );

	if ( p_inFBI{ playerid } == true )
	{
		GivePlayerWeapon( playerid, 29, 250 );
		GivePlayerWeapon( playerid, 34, 100 );
		GivePlayerWeapon( playerid, 27, 250 );
	}

	if ( p_inCIA{ playerid } == true )
		GivePlayerWeapon( playerid, 29, 200 );

	if ( p_inArmy{ playerid } == true )
	{
	    GivePlayerWeapon( playerid, 4, 1 );
	    GivePlayerWeapon( playerid, 24, 200 );
	    GivePlayerWeapon( playerid, 29, 200 );
	    GivePlayerWeapon( playerid, 31, 200 );
		GivePlayerWeapon( playerid, 27, 200 );
	    GivePlayerWeapon( playerid, 16, 5 );
		//GivePlayerWeapon( playerid, 34, 100 );
	}
}

stock UpdateGlobalDonated( playerid = INVALID_PLAYER_ID, Float: amount = 0.0, hidden = 0 )
{
	if ( playerid != INVALID_PLAYER_ID && amount > 0.0 ) {
		format( szBigString, sizeof( szBigString ), "INSERT INTO `TOP_DONOR` (`USER_ID`,`AMOUNT`,`LAST_AMOUNT`,`TIME`,`HIDE`) VALUES(%d,%f,%f,%d,%d) ON DUPLICATE KEY UPDATE `AMOUNT`=`AMOUNT`+%f,`LAST_AMOUNT`=%f,`TIME`=%d,`HIDE`=%d;", p_AccountID[ playerid ], amount, amount, g_iTime, hidden, amount, amount, g_iTime, hidden );
		mysql_single_query( szBigString );
	}

	// top donor
	if ( ! hidden ) {
		mysql_function_query( dbHandle, "SELECT `NAME`,`LAST_AMOUNT` FROM `TOP_DONOR` INNER JOIN `USERS` ON `TOP_DONOR`.`USER_ID`=`USERS`.`ID` WHERE `LAST_AMOUNT` > 0 AND `HIDE` < 1 ORDER BY `TIME` DESC LIMIT 1", true, "OnGrabLatestDonor", "" );
	}

	// wall of donors
	mysql_function_query( dbHandle, "SELECT `USERS`.`NAME` FROM `TOP_DONOR` INNER JOIN `USERS` ON `TOP_DONOR`.`USER_ID`=`USERS`.`ID` WHERE `HIDE` < 1 ORDER BY `AMOUNT` DESC, `TIME` DESC", true, "OnUpdateWallOfDonors", "" );
	return 1;
}

thread OnGrabLatestDonor( hidden )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );

	if ( rows )
	{
		static
			szName[ MAX_PLAYER_NAME ],
			Float: fAmount;


		cache_get_field_content( 0, "NAME", szName );
		fAmount = cache_get_field_content_float( 0, "LAST_AMOUNT", dbHandle );

		// Play song!
		GameTextForAll( sprintf( "~y~~h~~h~New Donor!~n~~w~%s", szName ), 6000, 3 );

		// Play sound
		foreach(new p : Player) if ( !IsPlayerUsingRadio( p ) ) {
			PlayAudioStreamForPlayer( p, "http://files.sfcnr.com/game_sounds/donated.mp3" );
		}

		TextDrawSetString( g_TopDonorTD, sprintf( "Le Latest Donor %s - $%0.2f", szName, fAmount ) );
	}
	else
	{
		TextDrawSetString( g_TopDonorTD, "Nobody Donated :(" );
	}
	return 1;
}

thread OnUpdateWallOfDonors( )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );

	if( rows )
	{
		new
			szString[ 600 ],
			iLine = 1,
			iPosition = 0;

		for( new row = 0; row < rows; row++ )
		{
			new
				szName[ MAX_PLAYER_NAME ];

			cache_get_field_content( row, "NAME", szName );

			new
				iOldLength = strlen( szString ) + 4; // 4 is an offset

			if( iOldLength - iPosition > 24 ) {
				iPosition = iOldLength;
				strcat( szString, "\n" ), iLine ++;
			}

			// The wall of donors
			format( szString, sizeof( szString ), "%s%s, ", szString, szName );
		}

		// The wall of donors formatting
		new
			iLength = strlen( szString );

		strdel( szString, iLength - 2, iLength );

		// Develop a size and format
		SetDynamicObjectMaterialText( g_TopDonorWall, 0, szString, 130, "Arial", floatround( 48.0 * floatpower( 0.925, iLine - 1 ), floatround_ceil ), 0, -65536, 0, 1 );
	}
	else
	{
		SetDynamicObjectMaterialText( g_TopDonorWall, 0, "Nobody Donated :(", 130, "Arial", 48, 0, -65536, 0, 1 );
	}
	return 1;
}

stock IsSafeGameText(string[])
{
    new count;
    for(new num, len = strlen(string); num < len; num++)
    {
        if (string[num] == '~')
		{
		    if ((num + 1) < len)
			{
				if (string[(num + 1)] == '~') return false;
			}
			count += 1;
		}
    }
    if ((count % 2) > 0) return false;
    return true;
}

thread checkforvipnotes( playerid )
{
	new
	    rows;

    cache_get_data( rows, tmpVariable );

	if ( rows ) {
		SendServerMessage( playerid, "You have currently %d V.I.P note(s) that you can redeem. Use "COL_GREY"/mynotes"COL_WHITE".", rows );
		SendClientMessageToAdmins( -1, ""COL_PINK"[VIP HAS NOTES]"COL_GREY" %s(%d) has logged in with %d pending VIP notes. (/viewnotes)", ReturnPlayerName( playerid ), playerid, rows );
	}
	return 1;
}

function ope_Unfreeze( a )
{
	if ( IsPlayerTied( a ) || IsPlayerTazed( a ) )
		return;

	TogglePlayerControllable( a, 1 );
}

stock SendClientMessageToAdmins( colour, format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

	foreach(new i : Player)
	{
	    if ( p_AdminLevel[ i ] > 0 || IsPlayerUnderCover( i ) )
			SendClientMessage( i, colour, out );
	}
	return 1;
}

stock TextDrawShowForAllSpawned( Text: textdrawid ) {
	foreach(new i : Player) if ( IsPlayerSpawned( i ) ) {
		TextDrawShowForPlayer( i, textdrawid );
	}
}

stock SecurityModeToString( modeid )
{
	static
		szMode[ 9 ];

	switch ( modeid )
	{
		case 0: szMode = "Mild";
		case 1: szMode = "Paranoid";
		case 2: szMode = "Disabled";
		default: szMode = "n/a";
	}
	return szMode;
}

stock ShowPlayerAccountGuard( playerid )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] != 0 ) {
		if ( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] && p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] < g_iTime ) {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"Your account email is "COL_GREEN"confirmed\t \nConfirm Email\t"COL_GREEN"%s\nSecurity Mode\t%s\n"COL_RED"Remove Irresistible Guard\t"COL_GREEN"Ready", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ) );
		} else if ( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] ) {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"Your account email is "COL_GREEN"confirmed\t \nConfirm Email\t"COL_GREEN"%s\nSecurity Mode\t%s\n"COL_ORANGE"Stop Pending Removal\t"COL_ORANGE"%s", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ), secondstotime( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] - g_iTime ) );
		} else {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"Your account email is "COL_GREEN"confirmed\t \nConfirm Email\t"COL_GREEN"%s\nSecurity Mode\t%s\n"COL_RED"Remove Irresistible Guard\t"COL_RED"approx. 24h", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ) );
		}

		// award user for adding their email
		if ( p_AddedEmail{ playerid } == false ) {
			strcat( szBigString, "\n"COL_GOLD"Claim Free 3 Days Of Regular VIP!\t"COL_GOLD">>>" );
		}
	} else {
		szBigString = ""COL_WHITE"Your account email is "COL_RED"unconfirmed\t \nConfirm Email\t"COL_GREY">>>";
	}
	return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Irresistible Guard", szBigString, "Select", "Close" );
}

thread OnQueueEmailVerification( playerid, email[ ] )
{
	new
		verification_id = cache_insert_id( );

	// alert
	SendServerMessage( playerid, "An email has been sent to "COL_GREY"%s"COL_WHITE" with instructions to confirm your account.", email );

	// sending an email
	format( szLargeString, sizeof( szLargeString ), "<p>Hello %s, you are receiving this email because you want to add Irresistible Guard to your account.</p><p><a href='http://" # MAILING_URL "/email/verify/%d/%d'>Click here to verify your email</a></p>", ReturnPlayerName( playerid ), p_AccountID[ playerid ], verification_id );
	SendMail( email, ReturnPlayerName( playerid ), sprintf( "Verify your account, %s", ReturnPlayerName( playerid ) ), szLargeString );
	return 1;
}

CMD:verify( playerid, params[ ] )
{
	if ( ! p_accountSecurityData[ playerid ] [ E_ID ] )
		return SendError( playerid, "You do not have an email assigned to your account." );

	if ( p_accountSecurityData[ playerid ] [ E_VERIFIED ] )
		return SendError( playerid, "You are already verified." );

	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_DISABLED )
		return SendError( playerid, "Your security mode is set to disabled." );

	format( szBigString, 196, "SELECT `CONFIRMED`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%s'", p_AccountID[ playerid ], mysql_escape( ReturnPlayerIP( playerid ) ) );
	mysql_function_query( dbHandle, szBigString, true, "OnAccountEmailVerify", "dd", playerid, 0 );
	return 1;
}

thread OnAccountGuardVerify( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

	if ( rows )
	{
		new
			userConfirmedIpId = cache_get_field_content_int( 0, "ID", dbHandle );

		p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;
		mysql_single_query( sprintf( "UPDATE `USER_CONFIRMED_IPS` SET `CONFIRMED`=1 WHERE `ID`=%d", userConfirmedIpId ) );

		// alert
		SendServerMessage( playerid, "You have confirmed your IP address. Thank you!" );
	}
	else
	{
		SendError( playerid, "Incorrect verification code has been specified. Please try again." );
		ShowPlayerAccountVerification( playerid );
	}
	return 1;
}

thread OnAccountEmailVerify( playerid, login_force )
{
	new
	    rows, fields, timestamp;

    cache_get_data( rows, fields );

	if ( rows )
	{
		new
			confirmed = cache_get_field_content_int( 0, "CONFIRMED", dbHandle );

		if ( confirmed )
		{
			// verify
	    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;

			// alert
			return SendServerMessage( playerid, "This account is protected by Irresistible Guard. "COL_GREEN"The IP you are playing with has been already verified." ), 1;
		}

		// assign last time
		timestamp = cache_get_field_content_int( 0, "DATE", dbHandle );
	}

	// No point making a disabled user validate
	if ( login_force && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_DISABLED )
		return 1;

	// No point forcing a mild mode user to validate
	if ( login_force && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_MILD )
		return SendError( playerid, "This account is protected by Irresistible Guard. "COL_RED"Please verify your IP through your email to transact in-game." );

	if ( g_iTime - timestamp >= 300 )
	{
		new
			iRandom = RandomEx( 10000000, 99999999 );

		// insert into database
		format( szBigString, sizeof( szBigString ), "INSERT INTO `USER_CONFIRMED_IPS`(`USER_ID`,`IP`,`TOKEN`,`CONFIRMED`) VALUES (%d,'%s','%d',0) ON DUPLICATE KEY UPDATE `TOKEN`='%d',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], ReturnPlayerIP( playerid ), iRandom, iRandom );
		mysql_single_query( szBigString );

		// email
		format( szLargeString, sizeof( szLargeString ), "<p>Hey %s, you are receiving this email because an unauthorized IP is accessing your account.</p>"\
														"<p>IP: %s<br>Country: %s (may be inaccurate)</p>"\
														"<p>Your verification token is <strong>%d</strong> - keep this only to yourself!</p>"\
														"<p style='color: red'>If you did not authorize this, change your password in-game or contact an administrator!</p>",
														ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ), iRandom );

		SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "Someones accessing your account, %s", ReturnPlayerName( playerid ) ), szLargeString );
	}
	else
	{
		SendServerMessage( playerid, "Please check your email for another token. A new code can be generated in %s.", secondstotime( 300 - ( g_iTime - timestamp ) ) );
	}

	// force verification
	ShowPlayerAccountVerification( playerid );

	// alert
	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID ) {
		SendError( playerid, "This account is protected by Irresistible Guard. "COL_RED"Please verify your IP through your email to play." );
	} else if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_MILD ) {
		SendError( playerid, "This account is protected by Irresistible Guard. "COL_RED"Please verify your IP through your email to transact in-game." );
	}
	return 1;
}

stock ShowPlayerAccountVerification( playerid )
{
	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == 1 ) {
		return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_CONFIRM, DIALOG_STYLE_INPUT, "{FFFFFF}Irresistible Guard", ""COL_WHITE"Please type the verification token that has been emailed to you.", "Confirm", "Quit" ), 1;
	} else {
		return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_CONFIRM, DIALOG_STYLE_INPUT, "{FFFFFF}Irresistible Guard", ""COL_WHITE"Please type the verification token that has been emailed to you.", "Confirm", "Close" ), 1;
	}
}

thread OnEmailLoad( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

    if ( rows )
    {
    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
    	p_accountSecurityData[ playerid ] [ E_ID ] = cache_get_field_content_int( 0, "ID", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_MODE ] = cache_get_field_content_int( 0, "MODE", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = cache_get_field_content_int( 0, "LAST_DISABLED", dbHandle );
    	cache_get_field_content( 0, "EMAIL", p_accountSecurityData[ playerid ] [ E_EMAIL ], dbHandle, 64 );

    	// IP Check
		format( szBigString, 196, "SELECT `CONFIRMED`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%s'", p_AccountID[ playerid ], mysql_escape( ReturnPlayerIP( playerid ) ) );
		mysql_function_query( dbHandle, szBigString, true, "OnAccountEmailVerify", "dd", playerid, 1 );
    }
}

thread OnEmailConfirm( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

    if ( rows )
    {
    	// fill data
    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;
    	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;
    	p_accountSecurityData[ playerid ] [ E_ID ] = cache_get_field_content_int( 0, "ID", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_MODE ] = cache_get_field_content_int( 0, "MODE", dbHandle );
    	cache_get_field_content( 0, "EMAIL", p_accountSecurityData[ playerid ] [ E_EMAIL ], dbHandle, 64 );

    	// log ip and alert
    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `USER_CONFIRMED_IPS`(`USER_ID`,`IP`,`CONFIRMED`) VALUES (%d,'%s',1)", p_AccountID[ playerid ], ReturnPlayerIP( playerid ) );
    	mysql_single_query( szNormalString );

    	// alert
    	SendServerMessage( playerid, "Your email has been confirmed, %s.", ReturnPlayerName( playerid ) );
    }
    else
    {
		format( szNormalString, sizeof( szNormalString ), "SELECT `EMAIL`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `EMAIL_VERIFY` WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
		mysql_function_query( dbHandle, szNormalString, true, "OnEmailVerifying", "d", playerid );
    }
	return 1;
}

thread OnEmailVerifying( playerid )
{
	new
		rows, fields, email[ 64 ];

	cache_get_data( rows, fields );

	if ( rows )
	{
		new
			timestamp = cache_get_field_content_int( 0, "DATE", dbHandle );

		if ( g_iTime - timestamp < 300 )
		{
			cache_get_field_content( 0, "EMAIL", email );
			return SendError( playerid, "An email has been sent to "COL_GREY"%s"COL_WHITE", please verify it within %s.", email, secondstotime( 300 - ( g_iTime - timestamp ) ) ), 1;
		}
	}

	return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}Irresistible Guard", ""COL_WHITE"Please type your email below. Your email may be used also to promote in-game and/or community associated events.\n\n"COL_ORANGE"This feature can only be used once every 5 minutes.", "Select", "Cancel" ), 1;
}

thread OnAccountGuardDelete( playerid )
{

	new
		rows, fields;

	cache_get_data( rows, fields );

	if ( !rows ) SendError( playerid, "It appears there is no email associated to your account." );
	else
	{
		new
			id = cache_get_field_content_int( 0, "ID", dbHandle ),
			last_disabled = cache_get_field_content_int( 0, "LAST_DISABLED", dbHandle ),
			last_changed = cache_get_field_content_int( 0, "LAST_CHANGED", dbHandle )
		;

		if ( id != p_accountSecurityData[ playerid ] [ E_ID ] )
			return SendError( playerid, "Something is wrong with your email. Talk to Lorenc." ), 1;

		if ( g_iTime - last_changed < 300 ) {
			return SendError( playerid, "You can use this feature in %s.", secondstotime( 300 - ( g_iTime - last_changed ) ) );
		}

		if ( ! last_disabled )
		{
			// first time disabling
			SendServerMessage( playerid, "You are now beginning to remove the email from your account. This will take 24 hours." );
			mysql_single_query( sprintf( "UPDATE `EMAILS` SET `LAST_DISABLED`=%d WHERE `ID`=%d", g_iTime + 86400, id ) );

			// email
			format( szLargeString, sizeof( szLargeString ), "<p>Hey %s, you are receiving this email because you are removing your Irresistible Guard.</p>"\
															"<p>IP: %s<br>Country: %s</p>"\
															"<p style='color: red'>If you did not authorize this, change your password in-game or contact an administrator!</p>",
															ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ) );

			SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "You are removing Irresistible Guard, %s", ReturnPlayerName( playerid ) ), szLargeString );

			// update variables
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = g_iTime + 86400;
		}
		else if ( g_iTime > last_disabled )
		{
			// under process of disabling
			mysql_single_query( sprintf( "DELETE FROM `EMAILS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
			mysql_single_query( sprintf( "DELETE FROM `EMAIL_VERIFY` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
			mysql_single_query( sprintf( "DELETE FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );

			// email
			format( szLargeString, sizeof( szLargeString ), "<p>Hey %s, you are receiving this email because Irresistible Guard is removed from your account.</p>"\
															"<p>IP: %s<br>Country: %s</p>"\
															"<p style='color: red'>If you did not authorize this, change your password in-game or contact an administrator!</p>",
															ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ) );

			SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "Irresistible Guard is removed, %s", ReturnPlayerName( playerid ) ), szLargeString );

			// reset variables
			p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
			p_accountSecurityData[ playerid ] [ E_ID ] = 0;
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;

			// alert
			SendServerMessage( playerid, "You have successfully removed Irresistible Guard from your account." );
		}
		else
		{
			// update last disabled anyway
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = last_disabled;

			// show dialog
			format( szNormalString, sizeof( szNormalString ), ""COL_WHITE"You must wait another %s until you can remove your email.\n\nDo you wish to stop this process?", secondstotime( last_disabled - g_iTime ) );
			ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_DEL_CANCEL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Irresistible Guard - Stop Deletion", szNormalString, "Yes", "No" );
		}
	}
	return 1;
}

/**
 * Read all incoming UDP data from discord users that fire commands
 * @return true
 */

#if ENABLE_DISCORD == true
public DCC_OnChannelMessage( DCC_Channel: channel, DCC_User: author, const message[ ] )
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

/**
 * Sends a message to a channel
 * @return true
*/

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
#endif


stock SendClientMessageToRace( raceid, colour, format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach(new i : Player)
	{
	    if ( p_raceLobbyId[ i ] == raceid )
			SendClientMessage( i, colour, out );
	}
	return 1;
}

function OnRaceCountdown( raceid, time )
{
	if ( raceid == -1 || ! Iter_Contains( races, raceid ) )
		return;

	foreach (new playerid : Player) if ( p_raceLobbyId[ playerid ] == raceid ) {
		if ( ! IsPlayerInDynamicRaceCP( playerid, g_raceData[ raceid ] [ E_START_CHECKPOINT ] ) ) {
			SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The race cannot be started as %s(%d) is not in the starting checkpoint.", ReturnPlayerName( playerid ), playerid );
			g_raceData[ raceid ] [ E_CD_TIMER ] = SetTimerEx( "OnRaceCountdown", 960, false, "dd", raceid, time );
			return;
		}
	}

	if ( time <= 0 )
	{
	    foreach (new playerid : Player) if ( p_raceLobbyId[ playerid ] == raceid )
	    {
	    	if ( g_raceData[ raceid ] [ E_MODE ] == RACE_OUTRUN )
	    	{
		    	// create sphere ahead of leader
		    	if ( g_raceData[ raceid ] [ E_LOBBY_HOST ] == playerid )
		    	{
		    		new
		    			vehicleid = GetPlayerVehicleID( playerid ), Float: A;

		    		GetVehicleZAngle( vehicleid, A );

		    		// create sphere obj
		    		g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = playerid;
		    		g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] = CreateDynamicCircle( 0.0, 0.0, 10.0 );
		    		g_raceData[ raceid ] [ E_OUTRUN_OBJECT ] = CreateDynamicObject( 11752, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1, -1, 0 );
		    		g_raceData[ raceid ] [ E_OUTRUN_TIMER ] = SetTimerEx( "OnRaceOutrun", 250, true, "d", raceid );

		    		// attach objects
					Streamer_RemoveArrayData( STREAMER_TYPE_OBJECT, g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], E_STREAMER_PLAYER_ID, 0 );
					AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], vehicleid, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
		    		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], vehicleid, 0.0, -OUTRUN_DIST - 4.0 );
		    	}

		    	// show checkpoint for player
	  			Streamer_AppendArrayData( STREAMER_TYPE_OBJECT, g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], E_STREAMER_PLAYER_ID, playerid );
		    }

	    	// destroy starting checkpoint
	    	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_START_CHECKPOINT ] );

	    	// show gametext
    		GameTextForPlayer( playerid, "~g~GO!", 2000, 3 );
			PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );
		}
		g_raceData[ raceid ] [ E_CD_TIMER ] = -1;
	}
	else
	{
	    foreach (new playerid : Player) if ( p_raceLobbyId[ playerid ] == raceid )
	    {
    		GameTextForPlayer( playerid, sprintf( "~y~%d", time ), 2000, 3 );
    		PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
	    }
		g_raceData[ raceid ] [ E_CD_TIMER ] = SetTimerEx( "OnRaceCountdown", 960, false, "dd", raceid, time - 1 );
	}
}

stock ShowRaceConfiguration( playerid, raceid )
{

	format( szLargeString, sizeof( szLargeString ), ""COL_WHITE"The current prize pool is %s\t \n"COL_GREY"Race Mode\t%s\n"COL_GREY"Entry Fee\t%s\n"COL_GREY"Prize Distribution\t%0.0f-%0.0f-%0.0f\n",

								cash_format( g_raceData[ raceid ] [ E_POOL ] ), g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE ? ( "Streetrace" ) : ( "Outrun" ), cash_format( g_raceData[ raceid ] [ E_ENTRY_FEE ] ),

								100.0 * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ], 100.0 * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 1 ], 100.0 * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 2 ]
							);

	if ( g_raceData[ raceid ] [ E_MODE ] == RACE_STREET_RACE ) {
		format( szLargeString, sizeof( szLargeString ), "%s"COL_GREY"Finish Destination\t%s\n", szLargeString, g_raceData[ raceid ] [ E_RACE_FINISH_SET ] == 1 ? ( ""COL_GREEN"ACTIVE" ) : ( ""COL_ORANGE"NOT SET" ) );
	} else {
		format( szLargeString, sizeof( szLargeString ), "%s"COL_GREY"Outrun Distance\t%0.1f meters\n", szLargeString, g_raceData[ raceid ] [ E_OUTRUN_DISTANCE ] );
	}

	strcat( szLargeString, ""COL_GREY"View Racers\t " );

	SetPVarInt( playerid, "editing_race", raceid );
	ShowPlayerDialog( playerid, DIALOG_RACE, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Race Configuration", szLargeString, "Select", "Close" );
	return 1;
}

function OnRaceOutrun( raceid )
{
	new
		racers = 0, ahead_count = 0, lead = g_raceData[ raceid ] [ E_OUTRUN_LEAD ];

	foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid && lead != i )
	{
		// increment racers
		racers ++;

		// check if racer is ahead
		if ( GetDistanceBetweenPlayers( lead, i ) > g_raceData[ raceid ] [ E_OUTRUN_DISTANCE ] )
			ahead_count ++;
	}

	// player is ahead of all players
	if ( ahead_count == racers )
	{
		new
			position = ++ g_raceData[ raceid ] [ E_FINISHED_COUNT ];

		// give prize and alert
		if ( 1 <= position <= 3 )
			GivePlayerRaceWin( lead, position, raceid );

		// end race if position over 3 or whatever the race count is or only 1 prize
		printf ("position : %d, Racers : %d", position, racers);
		if ( position >= 3 || position >= racers ||  g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] == 1.0 )
		{
			// incase there is a final player and a remaining prize pool
			if ( g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ 0 ] != 1.0 )
			{
				new
					closestRacer = GetClosestRacer( lead, raceid, .exceptid = lead );

				printf( "Yes we have a pool of %d, closest %d", g_raceData[ raceid ] [ E_POOL ], closestRacer );
				if ( IsPlayerConnected( closestRacer ) )
				{
					new
						finalPosition = ++ g_raceData[ raceid ] [ E_FINISHED_COUNT ];

					printf( "position %d", finalPosition );
					if ( 1 <= finalPosition <= 3 )
						GivePlayerRaceWin( closestRacer, finalPosition, raceid );
				}
			}
			else
			{
				SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The race has ended as there can only be one winner." );
			}

			// destroy race
			print ("Shut race");
			return DestroyRace( raceid );
		}

		// transfer leader
		else
		{
			new
				closestRacer = GetClosestRacer( lead, raceid, .exceptid = lead );

		    if ( IsPlayerConnected( closestRacer ) )
		    {
			    new
			    	iVehicle = GetPlayerVehicleID( closestRacer );

				// new leader
				g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = closestRacer;
				SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has taken the lead for the race.", ReturnPlayerName( closestRacer ), closestRacer );

				// see if ahead
				AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], iVehicle, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
	    		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], iVehicle, 0.0, -OUTRUN_DIST - 4.0 );
			}
		}
	}
	return 1;
}

stock GetClosestRacer( playerid, raceid, exceptid = INVALID_PLAYER_ID, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = INVALID_PLAYER_ID,
        Float: fX, Float: fY,  Float: fZ, Float: fTmp
    ;

    if ( GetPlayerPos( playerid, fX, fY, fZ ) )
    {
		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid && exceptid != i && GetPlayerVehicleSeat( playerid ) == 0 )
		{
            if ( 0.0 < ( fTmp = GetPlayerDistanceFromPoint( i, fX, fY, fZ ) ) < distance )
            {
                distance = fTmp;
                iCurrent = i;
            }
	    }
    }
    return iCurrent;
}

stock GivePlayerRaceWin( playerid, position, raceid )
{
	new
		prizeMoney = floatround( float( g_raceData[ raceid ] [ E_POOL ] ) * g_raceData[ raceid ] [ E_POSITION_PRIZE ] [ ( position - 1 ) ] );

	// give cash & reduce prize pool
	GivePlayerCash( playerid, prizeMoney );

	// announcement
	foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
		PlayerPlaySound( i, 1149, 0.0, 0.0, 0.0 );
		GameTextForPlayer( i, sprintf( "~y~~h~%d%s~w~ %s", position, positionToString( position ), ReturnPlayerName( playerid ) ), 2000, 3 );
		SendClientMessageFormatted( i, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) has finished the race in %d%s position (prize %s).", ReturnPlayerName( playerid ), playerid, position, positionToString( position ), cash_format( prizeMoney ) );
	}

	// remove from race
	RemovePlayerFromRace( playerid );
}


stock DestroyRace( raceid )
{
	// remove players from race
	foreach (new playerid : Player) {
		if ( p_raceLobbyId[ playerid ] == raceid ) {
			p_raceLobbyId[ playerid ] = -1;
		}
	}

	// remove race vars
	Iter_Remove( races, raceid );
	g_raceData[ raceid ] [ E_STARTED ] = false;

	// destroy race cps
	DestroyDynamicObject( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ] ), g_raceData[ raceid ] [ E_OUTRUN_OBJECT ] = -1;
	DestroyDynamicArea( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] ), g_raceData[ raceid ] [ E_OUTRUN_SPHERE ] = -1;
	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_START_CHECKPOINT ] ), g_raceData[ raceid ] [ E_START_CHECKPOINT ] = -1;
	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] ), g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] = -1;
	DestroyDynamicMapIcon( g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] ), g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] = -1;
	KillTimer( g_raceData[ raceid ] [ E_OUTRUN_TIMER ] ), g_raceData[ raceid ] [ E_OUTRUN_TIMER ] = -1;
	return 1;
}

stock RemovePlayerFromRace( playerid )
{
	new
		newLeader = INVALID_PLAYER_ID,
		raceid = p_raceLobbyId[ playerid ]
	;

	if ( ! Iter_Contains( races, raceid ) )
		return 0;

	// hide checkpoints
	Streamer_RemoveArrayData( STREAMER_TYPE_OBJECT, g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], E_STREAMER_PLAYER_ID, playerid );
	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_START_CHECKPOINT ], E_STREAMER_PLAYER_ID, playerid );
	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, playerid );
	Streamer_RemoveArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, playerid );

	// kick player out
	p_raceLobbyId[ playerid ] = -1;

	// assign new leader if possible
	if ( g_raceData[ raceid ] [ E_LOBBY_HOST ] == playerid )
	{
		foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
			newLeader = i;
			break;
		}

		if ( IsPlayerConnected( newLeader ) )
		{
			g_raceData[ raceid ] [ E_LOBBY_HOST ] = newLeader;
			// SendClientMessageToRace( raceid, COLOR_GREY, "[RACE]"COL_WHITE" %s(%d) is the new lobby host.", ReturnPlayerName( newLeader ), newLeader );
		}
		else
		{
			printf("Destroyed empty race lobby %d", raceid);
			DestroyRace( raceid );
		}
	}

	// maybe the outrun lead left
	else if ( g_raceData[ raceid ] [ E_MODE ] == RACE_OUTRUN && g_raceData[ raceid ] [ E_OUTRUN_LEAD ] == playerid )
	{
		new
			closestRacer = GetClosestRacer( playerid, raceid, .exceptid = playerid );

	    if ( IsPlayerConnected( closestRacer ) )
	    {
		    new
		    	iVehicle = GetPlayerVehicleID( closestRacer );

			// new leader
			g_raceData[ raceid ] [ E_OUTRUN_LEAD ] = closestRacer;
			SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" %s(%d) has taken the lead for the race.", ReturnPlayerName( closestRacer ), closestRacer );

			// see if ahead
			AttachDynamicObjectToVehicle( g_raceData[ raceid ] [ E_OUTRUN_OBJECT ], iVehicle, 0.0, OUTRUN_DIST, -15.0, 0.0, 0.0, 0.0 );
    		AttachDynamicAreaToVehicle( g_raceData[ raceid ] [ E_OUTRUN_SPHERE ], iVehicle, 0.0, -OUTRUN_DIST - 4.0 );
		}
		else
		{
			SendClientMessageToRace( raceid, -1, ""COL_GREY"[RACE]"COL_WHITE" The race has ended as a new leader couldn't be set." );
			DestroyRace( raceid );
		}
	}
	return 1;
}

stock GetRaceMemberCount( raceid ) {
	new
		count = 0;

	foreach (new playerid : Player) if ( p_raceLobbyId[ playerid ] == raceid ) {
		count ++;
	}
	return count;
}

stock SetRaceDestination( raceid, Float: fX, Float: fY, Float: fZ)
{
	// set race position
	g_raceData[ raceid ] [ E_FINISH_POS ] [ 0 ] = fX;
	g_raceData[ raceid ] [ E_FINISH_POS ] [ 1 ] = fY;
	g_raceData[ raceid ] [ E_FINISH_POS ] [ 2 ] = fZ;
	g_raceData[ raceid ] [ E_RACE_FINISH_SET ] = 1;

	// destroy checkpoint/icon again
	DestroyDynamicMapIcon( g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] );
	DestroyDynamicRaceCP( g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] );

	// place checkpoint
	g_raceData[ raceid ] [ E_FINISH_MAP_ICON ] = CreateDynamicMapIcon( fX, fY, fZ, 53, -1, -1, -1, 0, 6000.0, MAPICON_GLOBAL );
	g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ] = CreateDynamicRaceCP( 1, g_raceData[ raceid ] [ E_FINISH_POS ] [ 0 ], g_raceData[ raceid ] [ E_FINISH_POS ] [ 1 ], g_raceData[ raceid ] [ E_FINISH_POS ] [ 2 ], 0, 0, 0, 5.0, -1, -1, 0 );

  	// reset players in map icon/cp
  	Streamer_RemoveArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, 0 );
  	Streamer_RemoveArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, 0 );

  	// stream to players
	foreach (new i : Player) if ( p_raceLobbyId[ i ] == raceid ) {
		Streamer_AppendArrayData( STREAMER_TYPE_MAP_ICON, g_raceData[ raceid ] [ E_FINISH_MAP_ICON ], E_STREAMER_PLAYER_ID, i );
		Streamer_AppendArrayData( STREAMER_TYPE_RACE_CP, g_raceData[ raceid ] [ E_FINISH_CHECKPOINT ], E_STREAMER_PLAYER_ID, i );
	}
}

stock IsRaceHost( playerid, raceid ) {
	if ( raceid == -1 || ! Iter_Contains( races, raceid ) )
		return false;

	return g_raceData[ raceid ] [ E_LOBBY_HOST ] == playerid;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleSirenStateChange(playerid, vehicleid, newstate)
{
    if(newstate) GameTextForPlayer(playerid, "~W~Siren ~G~on", 1000, 3);
    else GameTextForPlayer(playerid, "~W~Siren ~r~off", 1000, 3);
    return 1;
}

#if ENABLE_DISCORD == false
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
#else
stock DCC_SendUserMessage( DCC_User: user, const message[ ] )
{
	static
		user_id[ 64 ];

	DCC_GetUserId( user, user_id, sizeof( user_id ) );
	format( szBigString, sizeof( szBigString ), "<@%s> ... %s", user_id, message );
	return DCC_SendChannelMessage( discordSpamChan, szBigString );
}
#endif


stock GivePlayerCasinoRewardsPoints( playerid, bet_amount, Float: house_edge ) {
	if ( bet_amount < 0 ) bet_amount *= -1; // profit or loss, does not matter
	// printf("(%f * ((%f * 100.0) * (%f / 100.0))) / %f\n",bet_amount, house_edge,  CASINO_REWARDS_PAYOUT_PERCENT, CASINO_REWARDS_DIVISOR);
	new Float: final_points = ( bet_amount * ( ( house_edge / 100.0 ) * ( CASINO_REWARDS_PAYOUT_PERCENT / 100.0 ) ) ) / CASINO_REWARDS_DIVISOR;
	p_CasinoRewardsPoints[ playerid ] += final_points;
	mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS`=%f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
	return 1;
}

stock ShowPlayerRewardsMenu( playerid )
{
	static szString[ 800 ];

	if ( szString[ 0 ] == '\0' )
	{
		strcat( szString, ""COL_WHITE"Item\t"COL_WHITE"Purpose\t"COL_WHITE"Rewards Points\n" );
		for( new i; i < sizeof( g_shopItemData ); i++ ) if ( IsCasinoRewardsShopItem( i ) ) {
			new Float: rewards_cost = ( float( g_shopItemData[ i ] [ E_PRICE ] ) * CASINO_REWARDS_COST_MP ) / CASINO_REWARDS_DIVISOR;
	 		format( szString, sizeof( szString ), "%s%s\t"COL_GREY"%s\t"COL_GOLD"%s points\n", szString, g_shopItemData[ i ] [ E_NAME ], g_shopItemData[ i ] [ E_USAGE ], points_format( rewards_cost ) );
		}
		for ( new i = 0; i < sizeof( g_casinoRewardsItems ); i ++ ) {
	 		format( szString, sizeof( szString ), "%s%s\t \t"COL_GOLD"%s points\n", szString, g_casinoRewardsItems[ i ] [ E_NAME ], points_format( g_casinoRewardsItems[ i ] [ E_POINTS ] ) );
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_CASINO_REWARDS, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Casino Rewards Items", szString, "Buy", "Cancel" );
}

stock IsCasinoRewardsShopItem( itemid ) {
	for ( new i = 0; i < sizeof( g_casinoRewardsShopItems ); i ++ ) if ( itemid == g_casinoRewardsShopItems[ i ] ) {
		return true;
	}
	return false;
}

stock ShowPlayerAirportMenu( playerid )
{
	if ( p_CasinoRewardsPoints[ playerid ] >= 5.0 ) {
		return ShowPlayerDialog( playerid, DIALOG_AIRPORT, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Airport", ""COL_WHITE"City\t"COL_WHITE"Casino Rewards Points\nSan Fierro\t"COL_GOLD"5.00 points\nLas Venturas\t"COL_GOLD"5.00 points\nLos Santos\t"COL_GOLD"5.00 points", "Travel", "Cancel" );
	}
	return ShowPlayerDialog( playerid, DIALOG_AIRPORT, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Airport", ""COL_WHITE"City\t"COL_WHITE"Cost\nSan Fierro\t"COL_GOLD"$2,000\nLas Venturas\t"COL_GOLD"$2,000\nLos Santos\t"COL_GOLD"$2,000", "Travel", "Cancel" );
}

stock GetPlayerFireworks( playerid ) return p_Fireworks[ playerid ];
stock GivePlayerFireworks( playerid, fireworks ) {
	p_Fireworks[ playerid ] += fireworks;
	mysql_single_query( sprintf( "UPDATE `USERS` SET `FIREWORKS`=%d WHERE `ID`=%d", p_Fireworks[ playerid ], p_AccountID[ playerid ] ) );
}

stock IsPlayerUnderCover( playerid ) { // StefiTV852, Shepard23, JamesComey
	return ( p_AccountID[ playerid ] == 577142 || p_AccountID[ playerid ] == 536230 || p_AccountID[ playerid ] == 668504 ) && p_PlayerLogged{ playerid };
}

stock ShowPlayerSpawnMenu( playerid ) {
	return ShowPlayerDialog( playerid, DIALOG_SPAWN, DIALOG_STYLE_LIST, "{FFFFFF}Spawn Location", ""COL_GREY"Reset Back To Default\nHouse\nBusiness\nGang Facility\nVisage Casino", "Select", "Cancel" );
}

stock PlayerPlaceRandomHits( )
{
	new hitman_budget = GetGVarInt( "hitman_budget" );

	if ( hitman_budget > 0 )
	{
		new hourly_budget = floatround( float( hitman_budget ) / 60.0 );
		new ignored_players[ MAX_PLAYERS ] = { -1, ... };

		new available_count = 0;

		for ( new playerid = 0; playerid < sizeof( ignored_players ); playerid ++ )
		{
			// remove unconnected / npcs / aod / low score
			if ( ! IsPlayerConnected( playerid ) || IsPlayerNPC( playerid ) || IsPlayerAdminOnDuty( playerid ) || GetPlayerScore( playerid ) < 25 || IsPlayerAFK( playerid ) )
			{
				ignored_players[ playerid ] = playerid;
				continue;
			}

			// count available
			available_count ++;
		}

		new random_hit[ 5 ]; // change 5 to number of hits to place per 24 mins

		new hits_placed_amount = 0;
		new hits_to_iterate = available_count > sizeof( random_hit ) ? sizeof( random_hit ) : available_count;

		for ( new hitid = 0; hitid < hits_to_iterate; hitid ++ )
		{
			random_hit[ hitid ] = randomExcept( ignored_players, sizeof( ignored_players ) );

			// looks cleaner
			new playerid = random_hit[ hitid ];

			// ignore selected player
			ignored_players[ playerid ] = playerid; // ignore this too

			// contract shit
			if ( IsPlayerConnected( playerid ) )
			{
				new contract_amount = random( hourly_budget );

				// set a min/max hit otherwise bugs (billion dollar fix)
				if ( contract_amount < 1000 || contract_amount > hourly_budget ) {
					contract_amount = 1000;
				}

				hits_placed_amount += contract_amount;
				p_ContractedAmount[ playerid ] += contract_amount;
				ShowPlayerHelpDialog( playerid, 4000, "Somebody has placed a hit on you!~n~~n~~r~Your bounty is now %s!", cash_format( p_ContractedAmount[ playerid ] ) );
			}
		}

		// update budget
		UpdateServerVariable( "hitman_budget", hitman_budget - hits_placed_amount, 0.0, "", GLOBAL_VARTYPE_INT );

		// print anyway
		printf("[AUTO HITMAN] Placed %s worth of hits (hourly rate %s, budget %s)!", cash_format( hits_to_iterate * hourly_budget ), cash_format( hourly_budget ), cash_format( GetGVarInt( "hitman_budget" ) ) );
	}
}

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
		if ( totalCash > 20000 ) printf("[police arrest] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( victimid ), cash_format( totalCash ) ); // 8hska7082bmahu
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[ACHIEVE]{FFFFFF} You have earned "COL_GOLD"%s{FFFFFF} dollars and 2 score for arresting %s(%d)!", cash_format( totalCash ), ReturnPlayerName( victimid ), victimid );
		GameTextForPlayer( victimid, "~r~Busted!", 4000, 0 );
		CallLocalFunction( "OnPlayerArrested", "dddd", playerid, victimid, p_Arrests[ playerid ], 1 );
		Untaze( victimid, 6 );
		GivePlayerSeasonalXP( victimid, -20.0 );
		SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has sent %s(%d) to jail for %d seconds!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( victimid ), victimid, totalSeconds );
		JailPlayer( victimid, totalSeconds );
		return 1;
 	}
 	else return SendError( playerid, "There are no players around to arrest." );
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

      	new
      		break_attempts = 0;

		if ( ! BreakPlayerCuffs( victimid, break_attempts ) )
		{
			GameTextForPlayer( victimid, "~n~~r~CUFFED!", 2000, 4 );
			//GameTextForPlayer( playerid, sprintf( "~n~~y~~h~/arrest %d", victimid ), 2000, 4 );
			GameTextForPlayer( playerid, "~n~~y~~h~/arrest", 2000, 4 );
			SendClientMessageFormatted( victimid, -1, ""COL_RED"[CUFFED]{FFFFFF} You have been cuffed by %s(%d)!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[CUFFED]{FFFFFF} You have cuffed %s(%d)!", ReturnPlayerName( victimid ), victimid );
			KillTimer( p_CuffAbuseTimer[ victimid ] );
	   		p_CuffAbuseTimer[ victimid ] = SetTimerEx( "Uncuff", ( 60 * 1000 ), false, "d", victimid );
			//ApplyAnimation( victimid, "ped", "cower", 5.0, 1, 1, 1, 0, 0 );
			//TogglePlayerControllable( victimid, 0 );
			p_Cuffed{ victimid } = true;
			p_QuitToAvoidTimestamp[ victimid ] = g_iTime + 3;
			SetPlayerAttachedObject( victimid, 2, 19418, 6, -0.011000, 0.028000, -0.022000, -15.600012, -33.699977, -81.700035, 0.891999, 1.000000, 1.168000 );
	      	SetPlayerSpecialAction( victimid, SPECIAL_ACTION_CUFFED );
			ShowPlayerHelpDialog( victimid, 4000, "You can buy bobby pins at Supa Save or a 24/7 store to break cuffs." );
		}
		else
		{
			if ( break_attempts )
			{
				new
					money_dropped = RandomEx( 200, 400 ) * break_attempts;

	    		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[CUFFED]{FFFFFF} %s(%d) just broke their cuffs off, and dropped %s!", ReturnPlayerName( victimid ), victimid, cash_format( money_dropped ) );
	    		GivePlayerCash( playerid, money_dropped );
			}
			else
			{
	    		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[CUFFED]{FFFFFF} %s(%d) just broke their cuffs off!", ReturnPlayerName( victimid ), victimid );
			}
		}
		return 1;
 	}
 	else return SendError( playerid, "There are no players around to cuff." );
}

stock BreakPlayerCuffs( playerid, &attempts = 0 )
{
	if ( p_BobbyPins[ playerid ] < 1 )
	    return 0;

	new Float: police_percentage;
	new bool: success = false;

	// get current police percentage
	GetServerPoliceRatio( police_percentage );

	// probability based off some factors
	new probability = 15 + floatround( police_percentage, floatround_floor );

	// attempt to uncuff
	for ( attempts = 1; attempts < p_BobbyPins[ playerid ]; attempts ++ )
	{
		if ( random( 101 ) <= probability ) { // 35% success rate RIP!
			success = true;
			break;
		}
	}

	if ( ( p_BobbyPins[ playerid ] -= attempts ) > 0 ) {
		ShowPlayerHelpDialog( playerid, 5000, "You only have %d bobby pins left!", p_BobbyPins[ playerid ] );
	}

	if ( success ) {
		/*TogglePlayerControllable( playerid, 1 );
	 	RemovePlayerAttachedObject( playerid, 2 );
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
		if ( !IsPlayerInAnyVehicle( playerid ) ) {
			ClearAnimations( playerid );
		}
		p_Cuffed{ playerid } = false;
		p_Tazed{ playerid } = false;
		//p_Detained{ playerid } = false;
		//Delete3DTextLabel( p_DetainedLabel[ playerid ] );
		//p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
		//p_DetainedBy[ playerid ] = INVALID_PLAYER_ID;*/
		Untaze( playerid, 10 );
		SendServerMessage( playerid, "You have used %d bobby pins to successfully break your cuffs.", attempts );
	    GivePlayerWantedLevel( playerid, 6 );
	} else {
		SendError( playerid, "You snapped %d bobby pin(s) and failed to break out of your cuffs.", attempts );
	}
	return 1;
}

stock IsPlayerEmailVerified( playerid ) return p_accountSecurityData[ playerid ] [ E_ID ];

stock IsPlayerAFK( playerid ) return ( ( GetTickCount( ) - p_AFKTime[ playerid ] ) >= 2595 );

stock GetPlayerVIPDuration( playerid ) return p_VIPExpiretime[ playerid ] - g_iTime;

stock IsPlayerInEvent( playerid ) return ( GetPlayerVirtualWorld( playerid ) == 69 );

stock UpdatePlayerEntranceExitTick( playerid, seconds = 2 ) {
	p_EntranceTimestamp[ playerid ] = g_iTime + seconds;
}

stock CanPlayerExitEntrance( playerid ) return g_iTime > p_EntranceTimestamp[ playerid ] && ! p_pausedToLoad{ playerid };

stock IsBuyableVehicle( vehicleid ) return g_buyableVehicle{ vehicleid };

stock IsPlayerInMinigame( playerid ) {
	return IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || IsPlayerPlayingPool( playerid ) || IsPlayerPlayingPoker( playerid );
}

stock DisablePlayerSpawnProtection( playerid )
{
	DisableRemoteVehicleCollisions( playerid, p_AdminOnDuty{ playerid } );
	SetPlayerHealth( playerid, p_AdminOnDuty{ playerid } ? float( INVALID_PLAYER_ID ) : 100.0 );
	Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
	p_SpawnKillLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_AntiSpawnKillEnabled{ playerid } = false;
	return 1;
}

stock SetPlayerPassiveMode( playerid )
{
	if ( IsPlayerSettingToggled( playerid, SETTING_PASSIVE_MODE ) )
	{
		ResetPlayerPassiveMode( playerid, .passive_disabled = true );
		return 0;
	}

	// reset any labels etc
	ResetPlayerPassiveMode( playerid );

	// place label
	if ( ! p_WantedLevel[ playerid ] && ! IsPlayerInPaintBall( playerid ) && GetPlayerClass( playerid ) != CLASS_POLICE ) {
		p_PassiveModeLabel[ playerid ] = CreateDynamic3DTextLabel( "Passive Mode", COLOR_GREEN, 0.0, 0.0, -0.6, 15.0, .attachedplayer = playerid );
		TextDrawShowForPlayer( playerid, g_PassiveModeTD );
	}
	return 1;
}

stock IsPlayerPassive( playerid )
{
	return ! p_WantedLevel[ playerid ] && p_Class[ playerid ] != CLASS_POLICE && ! p_PassiveModeDisabled{ playerid };
}

stock ResetPlayerPassiveMode( playerid, bool: passive_disabled = false )
{
	DestroyDynamic3DTextLabel( p_PassiveModeLabel[ playerid ] );
	//KillTimer( p_PassiveModeExpireTimer[ playerid ] );
	p_PassiveModeLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	//p_PassiveModeExpireTimer[ playerid ] = -1;
	p_PassiveModeDisabled{ playerid } = passive_disabled;
	TextDrawHideForPlayer( playerid, g_PassiveModeTD );
	return 1;
}

/*function PassiveMode_Reset( playerid, time_left )
{
	// if you happen to die then have a shot synced ... just reset normally
	if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) {
		return ResetPlayerPassiveMode( playerid );
	}

	if ( p_WantedLevel[ playerid ] > 0 || p_Class[ playerid ] != CLASS_CIVILIAN || -- time_left <= 0 )
	{
		ResetPlayerPassiveMode( playerid, .passive_disabled = true );
		ShowPlayerHelpDialog( playerid, 2000, "Passive mode is ~r~disabled." );
	}
	else
	{
    	UpdateDynamic3DTextLabelText( p_PassiveModeLabel[ playerid ], COLOR_RED, sprintf( "Passive Mode Disabled In %d Seconds", time_left ) );
		p_PassiveModeExpireTimer[ playerid ] = SetTimerEx( "PassiveMode_Reset", 980, false, "dd", playerid, time_left );
 		ShowPlayerHelpDialog( playerid, 1500, "Passive mode disabled in ~r~%d seconds.", time_left );
	}
	return 1;
}*/

stock SendClientMessageToCops( colour, format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

	foreach ( new i : Player ) if ( p_Class[ i ] == CLASS_POLICE ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock SendClientMessageToFireman( colour, format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

	foreach ( new i : Player ) if ( p_Class[ i ] == CLASS_FIREMAN ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock GetPlayerOutsidePos( playerid, &Float: X, &Float: Y, &Float: Z ) // gets the player position, if interior then the last checkpoint position
{
	new
		entranceid = p_LastEnteredEntrance[ playerid ],
		houseid = p_InHouse[ playerid ],
		garageid = p_InGarage[ playerid ]
	;

	if ( GetPlayerInterior( playerid ) != 0 || IsPlayerInBank( playerid ) )
	{
	    if ( entranceid != -1 )
	    	GetEntrancePos( entranceid, X, Y, Z );

	  	else if ( garageid != -1 )
	    	GetGaragePos( garageid, X, Y, Z );

	  	else if ( houseid != -1 )
	    	GetHousePos( houseid, X, Y, Z );

  		else GetPlayerPos( playerid, X, Y, Z );
	}
  	else
  	{
  		GetPlayerPos( playerid, X, Y, Z );
  	}
  	return 1;
}
