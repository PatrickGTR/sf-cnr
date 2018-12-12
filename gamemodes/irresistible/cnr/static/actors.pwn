/*
 * Irresistible Gaming 2018
 * Developed by Lorenc
 * Module: cnr\static\actors.inc
 * Purpose: hosts all static actor related data
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
enum E_ACTOR_DATA
{
	E_SKIN, Float: E_X, Float: E_Y, Float: E_Z, Float: E_RZ,
	E_ANIM_LIB[ 32 ], E_ANIM_NAME[ 32 ], E_WORLD
};

new
	g_actorData[ ] [ E_ACTOR_DATA ] =
	{
	// Class selection
		{ 201, 236.283996, 86.777999, 1005.039978, 90.000000, "camera", "picstnd_take", 0 },

	// SF Bank
		// Guards
		{ 71, -1440.9655, 835.5352, 984.7126, 269.2035, "COP_AMBIENT", "Coplook_loop", 23 },
		{ 71, -1440.9685, 826.6669, 984.7126, 265.4997, "COP_AMBIENT", "Coplook_loop", 23 },
		{ 71, -1424.5790, 851.7675, 984.7126, 180.9785, "COP_AMBIENT", "Coplook_loop", 23 },
		{ 71, -1401.6161, 851.1558, 984.7126, 127.2859, "COP_AMBIENT", "Coplook_loop", 23 },
		{ 71, -1416.0955, 809.6740, 984.7126, 354.1741, "COP_AMBIENT", "Coplook_loop", 23 },
		{ 141, -1431.4342, 863.4650, 984.7126, 181.0019, "PED", "null", 23 },
		{ 17,  -1430.0829, 863.4651, 984.7126, 181.3152, "PED", "null", 23 },
		{ 187, -1435.4611, 863.4647, 984.7126, 180.3752, "PED", "null", 23 },
		{ 148, -1436.8112, 863.4647, 984.7126, 180.3752, "PED", "null", 23 },
		{ 150, -1442.2074, 863.4650, 984.7126, 180.0619, "PED", "null", 23 },
		{ 212, -1443.6598, 821.4652, 984.7126, 91.59120, "PED", "phone_talk", 23 },
		{ 223, -1443.6616, 815.0886, 984.7126, 89.08450, "PED", "phone_talk", 23 },
		{ 147, -1428.3524, 801.6654, 985.6592, 305.9136, "BEACH", "bather", 23 },

	// SF-PD
		{ 300, -1701.1313, 688.9130, 24.890, 82.99340, "COP_AMBIENT", "Coplook_loop", 0 },
		{ 301, -1617.1761, 685.5781, 7.1875, 91.40680, "COP_AMBIENT", "Coplook_loop", 0 },
		{ 307, -1572.4314, 657.5108, 7.1875, 269.4698, "COP_AMBIENT", "Coplook_loop", 0 },

	// Supa Save
		{ 211, -2405.9412, 767.1729, 1056.7056, 181.1096, "PED", "null", 1 },
		{ 217, -2401.9216, 767.1737, 1056.7056, 180.4829, "PED", "null", 1 },
		{ 211, -2397.9246, 767.1732, 1056.7056, 179.5429, "PED", "null", 1 },
		{ 217, -2393.9060, 767.1729, 1056.7056, 177.6629, "PED", "null", 1 },
		{ 211, -2389.9084, 767.1729, 1056.7056, 179.2296, "PED", "null", 1 },
		{ 217, -2432.8936, 767.1730, 1056.7056, 179.2296, "PED", "null", 1 },
		{ 211, -2436.9250, 767.1729, 1056.7056, 180.1696, "PED", "null", 1 },
		{ 217, -2440.9246, 767.1728, 1056.7056, 181.1096, "PED", "null", 1 },
		{ 211, -2444.9470, 767.1730, 1056.7056, 179.8563, "PED", "null", 1 },
		{ 217, -2448.9636, 767.1729, 1056.7056, 179.8563, "PED", "null", 1 },

	// Jizzy's
		{ 256, -2654.1667, 1410.6729, 907.3886, 181.1924, "STRIP", "strip_A", 18 },
		{ 257, -2671.1641, 1410.0186, 907.5703, 2.927600, "STRIP", "strip_C", 18 },
		{ 87,  -2675.1821, 1410.0433, 907.5703, 29.1581, "STRIP", "strip_b", 18 },
		{ 244, -2677.6951, 1413.1705, 907.5763, 238.443, "STRIP", "strip_F", 18 },
		{ 246, -2676.9360, 1408.1617, 907.5703, 93.0787, "STRIP", "strip_D", 18 },
		{ 256, -2676.9358, 1404.9027, 907.5703, 84.9319, "STRIP", "strip_E", 18 },
		{ 87,  -2677.1584, 1416.1370, 907.5712, 134.102, "STRIP", "strip_G", 18 },
		{ 244, -2670.4622, 1427.9211, 907.3604, 86.9676, "STRIP", "strip_E", 18 },
		{ 258, -2671.5706, 1413.3748, 906.4609, 193.0993, "RIOT", "RIOT_shout", 18 },
		{ 259, -2668.7529, 1413.0908, 906.4609, 137.5257, "RIOT", "RIOT_shout", 18 },
		{ 296, -2675.0781, 1429.7128, 906.4609, 226.2898, "BLOWJOBZ", "BJ_STAND_LOOP_P", 18 },
		{ 244, -2674.5938, 1429.1975, 906.4609, 48.86200, "BLOWJOBZ", "BJ_STAND_LOOP_W", 18 },
		{ 24,  -2675.8835, 1427.9740, 906.9243, 180.2610, "BEACH", "bather", 18 },
		{ 221, -2656.4712, 1413.2327, 906.2734, 232.1765, "PAULNMAC", "wank_loop", 18 },

	// Hobo
		{ 137, -1519.9003, 678.79800, 7.459900, 14.7968, "BEACH", "ParkSit_M_loop", 0 },

	// LV Brothel
		{ 178, 962.3973, -57.3805, 1001.7495, 126.8999, "STRIP", "strip_F", 42 },
		{ 221, 959.2863, -57.9077, 1001.1246, 281.0614, "PAULNMAC", "wank_loop", 42 },
		{ 249, 964.3915, -50.4273, 1001.1172, 92.1085, "SHOP", "Smoke_RYD", 42 },
		{ 213, 947.4916, -49.7769, 1001.1172, 185.6768, "BLOWJOBZ", "BJ_STAND_LOOP_P", 42 },
		{ 152, 947.5248, -50.1076, 1001.1172, 2.5833, "BLOWJOBZ", "BJ_STAND_LOOP_W", 42 },
		{ 242, 944.5837, -43.5228, 1001.1166, 174.0231, "BLOWJOBZ", "BJ_COUCH_LOOP_P", 42 },
		{ 63,  944.5231, -43.9482, 1001.1166, 356.5298, "BLOWJOBZ", "BJ_COUCH_LOOP_W", 42 },
		{ 87,  960.9799, -61.2946, 1001.5502, 0.3499, "CRACK", "crckidle2", 42 },
		{ 244, 942.2812, -49.9304, 1001.1172, 178.9681, "CRACK", "crckidle3", 42 },
		{ 259, 961.2700, -59.7196, 1001.1172, 333.1782, "STRIP", "PLY_CASH", 42 },
		{ 64,  956.9485, -46.0040, 1001.6714, 266.4611, "STRIP", "STR_B2C", 42 },
		{ 246, 967.1183, -47.9314, 1001.9516, 94.4628, "STRIP", "STR_A2B", 42 }
	}
;

hook OnScriptInit( )
{
	for( new i = 0; i < sizeof( g_actorData ); i++ )
	{
		new
			actorid = CreateDynamicActor( g_actorData[ i ] [ E_SKIN ], g_actorData[ i ] [ E_X ], g_actorData[ i ] [ E_Y ], g_actorData[ i ] [ E_Z ], g_actorData[ i ] [ E_RZ ] );

		SetDynamicActorInvulnerable( actorid, true );
		SetDynamicActorVirtualWorld( actorid, g_actorData[ i ] [ E_WORLD ] );
    	ApplyDynamicActorAnimation( actorid, g_actorData[ i ] [ E_ANIM_LIB ], g_actorData[ i ] [ E_ANIM_NAME ], 4.1, 1, 1, 1, 1, 0 );
    	ApplyDynamicActorAnimation( actorid, g_actorData[ i ] [ E_ANIM_LIB ], g_actorData[ i ] [ E_ANIM_NAME ], 4.1, 1, 1, 1, 1, 0 );
	}
}
