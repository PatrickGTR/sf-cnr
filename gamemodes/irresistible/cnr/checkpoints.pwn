/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: checkpoints.pwn
 * Purpose: encloses all server related checkpoints, particularly static ones
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define ALL_CHECKPOINTS             ( 38 )

#define CP_BANK_MENU                ( 1 )
#define CP_247_MENU                	( 2 )
#define CP_CHANGE_JOB               ( 3 )
#define CP_HOSPITAL                 ( 4 )
#define CP_BANK_MENU_LS          	( 5 )
#define CP_PAINTBALL                ( 6 )
#define CP_AMMUNATION_0            	( 7 )
//#define CP_LUMBERJACK				( 8 )
#define CP_FIGHTSTYLE               ( 9 )
#define CP_AMMUNATION_1       		( 10 )
#define CP_AMMUNATION_2       		( 11 )
#define CP_COUNTRY_BANK_MENU 		( 12 )
#define CP_HOSPITAL_LV 				( 14 )
#define CP_FIGHTSTYLE_LV 			( 15 )
#define CP_HOSPITAL1_LS 			( 17 )
#define CP_HOSPITAL2_LS 			( 18 )
#define CP_FIGHTSTYLE_LS 			( 19 )
#define CP_PAWNSHOP 				( 20 )
#define CP_HOSPITAL_FC 				( 21 )
#define CP_REFILL_AMMO				( 22 )
#define CP_REFILL_AMMO_LS			( 23 )
#define CP_REFILL_AMMO_LV			( 24 )
/*#define CP_DROP_OFF_COP           	( 28 )
#define CP_DROP_OFF_FC				( 29 )
#define CP_DROP_OFF_DILLIMORE		( 30 )
#define CP_DROP_OFF_DIABLO			( 31 )
#define CP_DROP_OFF_QUBRADOS		( 32 )
#define CP_DROP_OFF_COP_LS 			( 33 )
#define CP_DROP_OFF_FBI_LS 			( 34 )
#define CP_DROP_OFF_FBI_LV 			( 35 )
#define CP_DROP_OFF_COP_LV 			( 36 )
#define CP_DROP_OFF_FBI             ( 37 )
#define CP_DROP_OFF_HELI         	( 38 )*/
#define CP_BIZ_TERMINAL_COKE		( 25 )
#define CP_BIZ_TERMINAL_METH 		( 26 )
#define CP_BIZ_TERMINAL_WEED 		( 27 )
#define CP_BIZ_TERMINAL_WEAP 		( 28 )
#define CP_REWARDS_4DRAG 	 		( 29 )
#define CP_REWARDS_CALIG 	 		( 30 )
#define CP_REWARDS_VISAGE 			( 31 )
#define CP_AIRPORT_SF 				( 32 )
#define CP_AIRPORT_LS 				( 33 )
#define CP_AIRPORT_LV 				( 34 )
#define CP_CASINO_BAR 				( 35 )
#define CP_ALCATRAZ_EXPORT			( 36 )
#define CP_FISHING_SHOP             ( 37 )

new g_Checkpoints           		[ ALL_CHECKPOINTS ] = { -1, ... };

/* ** Hooks ** */
hook OnScriptInit( )
{
	//g_Checkpoints[ CP_DROP_OFF_COP ] = CreateDynamicCP( -1577.0952, 683.9492, 7.2440, 3.0, 0, -1, -1, 100.0 );
	g_Checkpoints[ CP_BANK_MENU ] = CreateDynamicCP( -1405.0657, 831.0966, 984.7126, 1.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_COUNTRY_BANK_MENU ] = CreateDynamicCP( 2156.1299, 1640.2460, 1041.6124, 1.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_CHANGE_JOB ] = CreateDynamicCP( 361.8525, 173.6031, 1008.3828, 1.0, -1, -1, -1, 50.0 );
	g_Checkpoints[ CP_HOSPITAL ] = CreateDynamicCP( -2647.5007, 659.0084, 970.4332, 2.0, -1, -1, -1, 100.0 );
    g_Checkpoints[ CP_PAINTBALL ] = CreateDynamicCP( -2172.2017, 252.1113, 35.3388, 1.0, -1, -1, -1, 100.0 );
	//g_Checkpoints[ CP_DROP_OFF_FBI ] = CreateDynamicCP( -2446.6785, 522.9684, 30.2548, 3.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_FIGHTSTYLE ] = CreateDynamicCP( 768.2576, -22.8351, 1000.5859, 2.0, -1, -1, -1, 25.0 );
	g_Checkpoints[ CP_247_MENU ] = CreateDynamicCP( -29.0409, -184.7446, 1003.5469, 1.0, -1, -1, -1, 25.0 );
	g_Checkpoints[ CP_AMMUNATION_0 ] = CreateDynamicCP( 296.3782, -38.4512, 1001.5156, 1.0, -1, -1, -1, 20.0 );
	g_Checkpoints[ CP_AMMUNATION_1 ] = CreateDynamicCP( 295.4524, -80.7487, 1001.5156, 1.0, -1, -1, -1, 20.0 );
	g_Checkpoints[ CP_AMMUNATION_2 ] = CreateDynamicCP( 312.8432, -166.1419, 999.6010, 1.0, -1, -1, -1, 20.0 );
	//g_Checkpoints[ CP_DROP_OFF_HELI ] = CreateDynamicCP( -1651.6956, 700.8394, 38.2422, 5.0, -1, -1, -1, 50.0 );
	g_Checkpoints[ CP_PAWNSHOP ] = CreateDynamicCP( 1333.0847, -1080.0726, 968.0430, 1.0, -1, -1, -1, 20.0 );
	g_Checkpoints[ CP_REFILL_AMMO ] = CreateDynamicCP( -1615.2600, 685.5120, 7.1875, 1.0, -1, -1, -1, 20.0 );
	g_Checkpoints[ CP_REFILL_AMMO_LS ] = CreateDynamicCP( -1615.2600, 685.5120, 7.1875, 1.0, -1, -1, -1, 20.0 );
	//g_Checkpoints[ CP_DROP_OFF_FC ] = CreateDynamicCP( -211.6869, 979.3518, 19.3237, 3.0, -1, -1, -1, 100.0 );
	//g_Checkpoints[ CP_DROP_OFF_DILLIMORE ] = CreateDynamicCP( 614.2876, -588.6716, 17.2330, 3.0, -1, -1, -1, 100.0 );
	//g_Checkpoints[ CP_DROP_OFF_DIABLO ] = CreateDynamicCP( -433.3666, 2255.6064, 42.4297, 3.0, -1, -1, -1, 100.0 );
	//g_Checkpoints[ CP_DROP_OFF_QUBRADOS ] = CreateDynamicCP( -1400.0497, 2647.2358, 55.6875, 3.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_BIZ_TERMINAL_COKE ] = CreateDynamicCP( 2563.5728, -1310.5925, 1143.7242, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_BIZ_TERMINAL_METH ] = CreateDynamicCP( 2034.0669, 1001.6073, 1510.2416, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_BIZ_TERMINAL_WEED ] = CreateDynamicCP( -1742.9982, -1377.3049, 5874.1333, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_BIZ_TERMINAL_WEAP ] = CreateDynamicCP( -6942.8770, -247.7294, 837.5850, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_REWARDS_CALIG ] = CreateDynamicCP( 2157.6294, 1599.4355, 1006.1797, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_REWARDS_4DRAG ] = CreateDynamicCP( 1951.7191, 997.5555, 992.8594, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_REWARDS_VISAGE ] = CreateDynamicCP( 2604.1323, 1570.1182, 1508.3530, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_AIRPORT_LV ] = CreateDynamicCP( 1672.53640, 1447.86160, 10.7881, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_AIRPORT_LS ] = CreateDynamicCP( 1642.22740, -2335.4978, 13.5469, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_AIRPORT_SF ] = CreateDynamicCP( -1422.4063, -286.50810, 14.1484, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_CASINO_BAR ] = CreateDynamicCP( 2655.8694, 1591.1545, 1506.1793, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_ALCATRAZ_EXPORT ] = CreateDynamicCP( -1999.9487, 1781.2325, 43.7386, 1.0, -1, -1, -1, 30.0 );
	g_Checkpoints[ CP_FISHING_SHOP ] = CreateDynamicCP( -1595.1049, 1283.9769, 1207.2159, 1.0, -1, -1, -1, 30.0 );

	// Out of SF
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD,  -211.6869, 979.3518, 19.3237, 50.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD,  614.2876, -588.6716, 17.2330, 50.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD,  -433.3666, 2255.6064, 42.4297, 50.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD,  -1400.0497, 2647.2358, 55.6875, 50.0);

	#if ENABLE_CITY_LV == true
	//g_Checkpoints[ CP_DROP_OFF_COP_LV ] = CreateDynamicCP( 2225.6753, 2457.2388, -7.4531, 3.0, 0, -1, -1, 100.0 );
	g_Checkpoints[ CP_HOSPITAL_LV ] = CreateDynamicCP( 1607.2659, 1815.2485, 10.8203, 2.0, -1, -1, -1, 100.0 );
	//g_Checkpoints[ CP_DROP_OFF_FBI_LV ] = CreateDynamicCP( 948.6036, 1811.2720, 8.6484, 3.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_FIGHTSTYLE_LV ] = CreateDynamicCP( 766.8416, -62.1872, 1000.6563, 2.0, -1, -1, -1, 25.0 );
	g_Checkpoints[ CP_REFILL_AMMO_LV ] = CreateDynamicCP( 2251.9438, 2488.7981, 10.9908, 1.0, -1, -1, -1, 20.0 );
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD, 2225.6753, 2457.2388, -7.4531, 20.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD, 948.6036, 1811.2720, 8.6484, 20.0);
	CreateDynamic3DTextLabel("[LEARN FIGHT STYLES]", COLOR_GOLD, 766.8416, -62.1872, 1000.6563, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 9);
	CreateDynamic3DTextLabel("[HOSPITAL]", COLOR_GOLD, 1607.2659, 1815.2485, 10.8203, 20.0);
	CreateDynamic3DTextLabel("[REFILL AMMO]", COLOR_GOLD, 2251.9438, 2488.7981, 10.9908, 20.0);
	#endif

	#if ENABLE_CITY_LS
	g_Checkpoints[ CP_HOSPITAL1_LS ] = CreateDynamicCP( 1172.0767, -1323.3257, 15.4029, 1.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_HOSPITAL2_LS ] = CreateDynamicCP( 2034.0677, -1401.6699, 17.2938, 1.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_HOSPITAL_FC ] = CreateDynamicCP( -320.2127, 1048.2339, 20.3403, 1.0, -1, -1, -1, 100.0 );
	//g_Checkpoints[ CP_DROP_OFF_COP_LS ] = CreateDynamicCP( 1569.0277, -1694.1566, 5.8906, 3.0, 0, -1, -1, 100.0 );
	//g_Checkpoints[ CP_DROP_OFF_FBI_LS ] = CreateDynamicCP( 1516.6716, -1458.9398, 9.5000, 3.0, -1, -1, -1, 100.0 );
	g_Checkpoints[ CP_FIGHTSTYLE_LS ] = CreateDynamicCP( 772.0868, 12.6397, 1000.6996, 1.0, -1, -1, -1, 25.0 );
	g_Checkpoints[ CP_BANK_MENU_LS ] = CreateDynamicCP( 2136.4946, 1226.1787, 1017.1369, 1.0, -1, -1, -1, 25.0 );
	g_Checkpoints[ CP_REFILL_AMMO_LS ] = CreateDynamicCP( 1579.5439, -1635.5166, 13.5609, 1.0, -1, -1, -1, 20.0 );
	CreateDynamic3DTextLabel("[BANK MENU]", COLOR_GOLD, 2136.4946, 1226.1787, 1017.1369, 20.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD, 1569.0277, -1694.1566, 5.8906, 20.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD, 1516.6716, -1458.9398, 9.5000, 20.0);
	CreateDynamic3DTextLabel("[LEARN FIGHT STYLES]", COLOR_GOLD, 772.0868, 12.6397, 1000.6996, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 10);
	CreateDynamic3DTextLabel("[HOSPITAL]", COLOR_GOLD, 1172.0767, -1323.3257, 15.4029, 20.0);
	CreateDynamic3DTextLabel("[HOSPITAL]", COLOR_GOLD, 2034.0677, -1401.6699, 17.2938, 20.0);
	CreateDynamic3DTextLabel("[HOSPITAL]", COLOR_GOLD,  -320.2127, 1048.2339, 20.3403, 20.0);
	CreateDynamic3DTextLabel("[REFILL AMMO]", COLOR_GOLD, 1579.5439, -1635.5166, 13.5609, 20.0);
	#endif

	CreateDynamic3DTextLabel("[ROCK CRUSHER]", COLOR_GOLD,  -1999.9487, 1781.2325, 43.7386, 50.0);
	CreateDynamic3DTextLabel("[CASINO BAR]", COLOR_GOLD,  2655.8694, 1591.1545, 1506.1793, 50.0);
	CreateDynamic3DTextLabel("[AIRPORT]", COLOR_GOLD,  1672.53640, 1447.86160, 10.7881, 50.0);
	CreateDynamic3DTextLabel("[AIRPORT]", COLOR_GOLD,  1642.22740, -2335.4978, 13.5469, 50.0);
	CreateDynamic3DTextLabel("[AIRPORT]", COLOR_GOLD,  -1422.4063, -286.50810, 14.1484, 50.0);
	CreateDynamic3DTextLabel("[REFILL AMMO]", COLOR_GOLD, -1615.2600, 685.5120, 7.1875, 20.0);
	CreateDynamic3DTextLabel("[PAWNSHOP]", COLOR_GOLD, 1333.0847, -1080.0726, 968.0430, 20.0);
	CreateDynamic3DTextLabel("[SHOP]", COLOR_GOLD, -29.0409,-184.7446,1003.5469, 20.0);
	CreateDynamic3DTextLabel("[BANK MENU]", COLOR_GOLD, -1405.0657, 831.0966, 984.7126, 20.0);
	CreateDynamic3DTextLabel("[BANK MENU]", COLOR_GOLD, 2156.1299, 1640.2460, 1041.6124, 20.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD, -1577.0952, 683.9492, 7.2440, 20.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD, -2446.6785, 522.9684, 30.2548, 20.0);
	//CreateDynamic3DTextLabel("[DROP OFF]", COLOR_GOLD,  -1651.6956, 700.8394, 38.2422, 50.0);
	CreateDynamic3DTextLabel("[GUN STORE]", COLOR_GOLD, 296.3782, -38.4512, 1001.5156, 20.0);
	CreateDynamic3DTextLabel("[GUN STORE]", COLOR_GOLD, 295.4524, -80.7487, 1001.5156, 20.0);
	CreateDynamic3DTextLabel("[GUN STORE]", COLOR_GOLD, 312.8432, -166.1419, 999.6010, 20.0);
	CreateDynamic3DTextLabel("[MAIN DESK]", COLOR_GOLD, 361.8525, 173.6031, 1008.3828, 20.0);
	CreateDynamic3DTextLabel("[HOSPITAL]", COLOR_GOLD, -2647.5007, 659.0084, 970.4332, 20.0);
	CreateDynamic3DTextLabel("[PAINTBALL]", COLOR_GOLD, -2172.2017, 252.1113, 35.3388, 20.0);
	CreateDynamic3DTextLabel("[GUN REDEEM]\n"COL_WHITE"/vipgun", COLOR_GOLD, -1945.9280, 830.0893, 1214.2678, 20.0);
	CreateDynamic3DTextLabel("[GUN REDEEM]\n"COL_WHITE"/vipgun", COLOR_GOLD, -1966.1765, 851.0482, 1214.2678, 20.0);
	CreateDynamic3DTextLabel("[LEARN FIGHT STYLES]", COLOR_GOLD, 768.2576, -22.8351, 1000.5859, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 8 );
	CreateDynamic3DTextLabel("[BUSINESS TERMINAL]", COLOR_GOLD, 2563.5728, -1310.5925, 1143.7242, 20.0);
	CreateDynamic3DTextLabel("[BUSINESS TERMINAL]", COLOR_GOLD, 2034.0669, 1001.6073, 1510.2416, 20.0);
	CreateDynamic3DTextLabel("[BUSINESS TERMINAL]", COLOR_GOLD, -1742.9982, -1377.3049, 5874.1333, 20.0);
	CreateDynamic3DTextLabel("[BUSINESS TERMINAL]", COLOR_GOLD, -6942.8770, -247.7294, 837.5850, 20.0);
	CreateDynamic3DTextLabel("[SHOP]", COLOR_GOLD, -1595.1049, 1283.9769, 1207.2159, 20.0);
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	/* ** Checkpoint Denials ** */
	if ( GetPlayerState( playerid ) == PLAYER_STATE_SPECTATING ) {
		return Y_HOOKS_BREAK_RETURN_1;
	}

	if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_CUFFED ) {
		return SendError( playerid, "You can't do anything as you are cuffed." ), Y_HOOKS_BREAK_RETURN_1;
	}

	if ( IsPlayerTied( playerid ) ) {
		return SendError( playerid, "You can't do anything as you are tied." ), Y_HOOKS_BREAK_RETURN_1;
	}

	if ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || IsPlayerInEvent( playerid ) ) {
		return SendError( playerid, "You can't do anything as you are in an event." ), Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}
