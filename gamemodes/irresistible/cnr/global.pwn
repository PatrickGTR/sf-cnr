/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\global.pwn
 * Purpose: all global related variables (cnr)
 */

/* ** Variables ** */
new
	g_redeemVipWait 				= 0,
	g_TrolleyVehicles               [ 5 ],
	engine, lights, doors, bonnet, boot, objective, alarm, panels, tires,
	g_RestoreRobberiesBribes  		= 0,
	g_ServerUptime 					= 0,
	rl_ServerUpdate					= 0xFF,
	rl_ZoneUpdate                   = 0xFF,
	rl_AutoVehicleRespawner         = 0xFF,
	bool: g_adminSpawnedCar     	[ MAX_VEHICLES char ],
	g_WorldClockSeconds             = 0,
	g_WorldDayCount                 = 0,
	g_WorldWeather                  = 10,
	g_PingLimit                     = 1024,
	g_circleall_CD                  = false,
	log__Text						[ 6 ][ 90 ],
	szReportsLog 					[ 8 ][ 128 ],
	szQuestionsLog 					[ 8 ][ 128 ],
	bool: g_CommandLogging			= false,
	bool: g_DialogLogging			= false,
	szRules							[ 3300 ],
 	g_BannedDrivebyWeapons 			[ ] =
 	{
 		24, 26, 27, 34, 33
 	},
 	bool: g_Debugging 				= false,
 	bool: g_Driveby 				= false,
 	bool: g_VipPrivateMsging 		= false,
 	bool: g_HappyHour				= false,
 	Float: g_HappyHourRate			= 0.0,
 	g_iTime 						= 0,
 	g_VehicleLastAttacker 			[ MAX_VEHICLES ] = { INVALID_PLAYER_ID, ... },
 	g_VehicleLastAttacked 			[ MAX_VEHICLES ],
	g_TopDonorWall 					= INVALID_OBJECT_ID,
	g_AlcatrazArea 					= -1
;

/* ** Getters and Setters ** */
stock GetServerTime( ) return g_iTime;
