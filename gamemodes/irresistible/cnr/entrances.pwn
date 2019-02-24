/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\entrances.pwn
 * Purpose: entrance system (entering/exiting shops or interiors)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_ENTERS                  ( 300 )

/* ** Macros ** */
#define IsPlayerInEntrance(%0,%1)	( p_LastEnteredEntrance[ %0 ] == ( %1 ) )

/* ** Variables ** */
enum E_ENTER_DATA
{
	E_WORLD,					E_INTERIOR, 				bool: E_VIP,
	Float: E_EX,    			Float: E_EY, 				Float: E_EZ,
	Float: E_LX,    			Float: E_LY, 				Float: E_LZ,
	E_ENTER,            		E_EXIT,						bool: E_CUSTOM,
	Text3D:  E_ENTER_LABEL,		Text3D: E_EXIT_LABEL,		bool: E_SAVED,
	E_SQL_ID
};

new
	g_entranceData					[ MAX_ENTERS ] [ E_ENTER_DATA ],
	Iterator: entrances 			< MAX_ENTERS >,

	g_SupaSave 						= -1,
	g_VIPLounge[ 3 ] 				= { -1, ... }
;

/* ** Forwards ** */
forward OnPlayerAccessEntrance( playerid, entranceid, worldid, interiorid );

/* ** Hooks ** */
hook OnScriptInit( )
{
	// Custom Interiors
	mysql_function_query( dbHandle, "SELECT * FROM `ENTRANCES`", true, "OnEntrancesLoad", "" );

	// San Fierro
	CreateEntrance( "[BANK]", 				-1493.1296, 920.1409, 7.1875, -1444.2537, 831.0490, 985.7027, 			0,  GetBankVaultWorld( CITY_SF ), true, false, 52 );
	CreateEntrance( "[VICTIM]", 			-1694.4019, 951.0486, 24.8906, 227.3678, -8.3722, 1002.2109, 			5,   1, false, false, 45 );
	CreateEntrance( "[PIZZA]", 				-1808.6377, 945.8018, 24.8906, 372.2738, -133.5248, 1001.4922, 			5,   2, false, false, 29 );
	CreateEntrance( "[ZIP]", 				-1882.4294, 866.1778, 35.1719, 161.2982, -97.1033, 1001.8047, 			18,  3, false, false, 45 );
	CreateEntrance( "[BURGER SHOT]", 		-1912.2883, 828.0681, 35.2204, 362.8823, -75.1634, 1001.5078, 			10,  4, false, false, 10 );
	CreateEntrance( "[CLUCKING BELL]", 		-1816.5820, 618.0572, 35.1719, 364.9896, -11.8441, 1001.8516, 			9,   5, false, false, 14 );
	CreateEntrance( "[ZERO'S RC SHOP]", 	-2241.9248, 128.5363, 35.3203, -2240.7827,137.2215,1035.4141, 			6,   6, false, false, 47 );
	CreateEntrance( "[MISTY'S]", 			-2242.1438, -88.0866, 35.3203, 501.9013, -67.5635, 998.7578, 			11,  7, false, false, 49 );
	CreateEntrance( "[GYM]", 				-2270.6448, -155.983, 35.3203, 774.1244, -50.4720, 1000.5859, 			6,   8, false, false, 54 );
	CreateEntrance( "[BURGER SHOT]", 		-2336.8657, -166.889, 35.5547, 362.8823, -75.1634, 1001.5078, 			10,  9, false, false, 10 );
	CreateEntrance( "[DRIVING SCHOOL]",		-2026.6505, -102.0638, 35.1641, -2026.8767, -103.6028, 1035.1831, 		3,  10, false, false, 36 );
	CreateEntrance( "[DRUG HOUSE]", 		-2203.2300, 1043.400, 80.0131, 2196.8398, -1204.4272, 1049.0234, 		6,  11, false, false, 24 );
	CreateEntrance( "[BINCO]", 				-2373.8457, 910.1376, 45.4453, 207.6674,-111.2659,1005.1328, 			15, 12, false, false, 45 );
	CreateEntrance( "[BURGER SHOT]", 		-2355.8369, 1008.2708, 50.8984, 362.8823, -75.1634, 1001.5078, 			10, 13, false, false, 10 );
	CreateEntrance( "[CLUCKING BELL]", 		-2672.2297, 258.2861, 4.6328, 364.9896, -11.8441, 1001.8516, 			9,  14, false, false, 14 );
	CreateEntrance( "[BARBER]", 			-2571.3015, 246.8040, 10.4512, 411.8917,-54.4434,1001.8984, 			12, 23, false, false,  7 );
	CreateEntrance( "[DISCO]", 				-2551.0127, 194.3636, 6.2266, 493.4810, -24.9531, 1000.6719, 			17, 17, false, false, 48 );
	CreateEntrance( "[JIZZY'S]", 			-2625.4006, 1412.331, 7.0938, -2636.7698, 1402.4551, 906.4609, 			3,  18, false, false, 49 );
	CreateEntrance( "[RUSTY BROWN DONUT]", -2767.8628, 788.7215, 52.7813, 377.1306, -193.3048, 1000.6328, 			17, 19, false, false, 17 );
	CreateEntrance( "[PIZZA]", 				-1720.9558, 1359.7795, 7.1853, 372.2738, -133.5248, 1001.4922, 			5,  20, false, false, 29 );
	CreateEntrance( "[SUBURBAN]", 			-2489.9392, -29.0578, 25.6172, 203.8414, -50.6566, 1001.8047, 			1,  21, false, false, 45 );
	CreateEntrance( "[TATTOO]", 			-2490.9966, -38.7627, 25.6172, -204.4172,-27.3470,1002.2734, 			16, 22, false, false, 39 );
	CreateEntrance( "[CHURCH]", 			-1989.7933, 1117.9083, 54.4688, 1964.0679, -349.6309, 1092.9454, 		1,   1, true , false, -1 );
	CreateEntrance( "[CITY HALL]", 			-2766.4087, 375.5447, 6.3347, 390.7462, 173.7627, 1008.3828, 			3,   1, false, false, -1 );
	CreateEntrance( "[DRUG HOUSE]", 		-2027.8260, -40.6628, 38.8047, 2196.8398, -1204.4272, 1049.0234, 		6,  26, false, false, 24 );
	CreateEntrance( "[DRUG HOUSE]", 		-2552.3325,55.2304,16.4219, 2196.8398, -1204.4272, 1049.0234, 			6,  27, false, false, 24 );
	CreateEntrance( "[GAS STATION]", 		-2420.1538, 969.8716, 45.2969, -27.2923, -58.0535, 1003.5469, 			6,  28, false, false, 55 );
	CreateEntrance( "[GAS STATION]", 		-1676.1494, 432.2187, 7.1797, -27.2923, -58.0535, 1003.5469, 			6,  29, false, false, 55 );
	CreateEntrance( "[REVELATION CHURCH]",  -2482.0703, 2406.6750, 17.1094, 2013.3900, 1589.8300, 977.0594, 		1,   1, false, false, -1 );
	CreateEntrance( "[VEHICLE DEALERSHIP]", -2521.1895, -624.9482, 132.7838, -1868.0262, -617.5386, 1002.1284, 		9,  32, true , false, 55 );
	CreateEntrance( "[SOCCER STADIUM]",		-2080.1951, -407.7742, 38.7344, -1807.8997, 435.8948, 1039.4382, 		9,  32, true , false, -1 );
	CreateEntrance( "[BOXING STADIUM]",		-2051.5239, -407.7723, 38.7344, -281.8263, 10.5794, 2217.3096, 			9,  32, true , false, -1 );
	CreateEntrance( "[FILM STUDIO]",		-2591.4668, 170.4937, 4.7348, 2330.5608, 897.3838, 1054.8489, 			1,  21, true , false, 38 );
	CreateEntrance( "[FREEFALL]", 			-1749.2736, 871.2025, 25.0859, -1753.7821, 883.8984, 295.6010, 			0,   0, false, false, -1 );
	CreateEntrance( "[PAWNSHOP]", 			-2490.2256, -16.9206, 25.6172, 1329.7720, -1084.7529, 968.0360, 		2,  11, true , false, 25 );
	CreateEntrance( "[AMMU-NATION]", 		-2626.6299, 208.2514, 4.8125, 285.4629, -41.7990, 1001.5156, 			1,  15, false, false,  6 );
	CreateEntrance( "[POLICE DEPT.]", 		-1605.3304, 711.6586, 13.8672, 246.3872, 107.3055, 1003.2188, 			10, 30, true , false, 30 ); // The jail world (30) needs to be changed otherwise gg.
	CreateEntrance( "[HOSPITAL]",			-2655.0923, 640.1625, 14.4545, -2656.3079, 640.9360, 970.4332, 			1,  22, true , false, 22 );

	// Hardcoded
	g_SupaSave = 			CreateEntrance( "[SUPA SAVE]",			-2442.5710, 754.6293, 35.1719, -2418.3743, 772.8492, 1056.7056, 		1,   1, true , false, 62 );

	// VIP Lounge
	g_VIPLounge[ CITY_SF ] = CreateEntrance( "[V.I.P Lounge]", 		-1880.7598, 822.3964, 35.1778, -1971.5508, 825.5823, 1209.4420, 		18, 25, true , true , 33 ); // SF
	g_VIPLounge[ CITY_LS ] = CreateEntrance( "[V.I.P Lounge]", 		1797.444091, -1578.955810, 14.085495, 39.7270, 105.4883, 1015.2939, 	18, 92, true , true , 33 ); // LS
	g_VIPLounge[ CITY_LV ] = CreateEntrance( "[V.I.P Lounge]", 		1965.0455, 1623.2230, 12.8620, 39.7270, 105.4883, 1015.2939, 			18, 25, true , true , 33 ); // LV

	#if ENABLE_CITY_LV == true
	// Las Venturas
	CreateEntrance( "[BANK]", 				2447.6885, 2376.2515, 12.1635, 2162.4661, 1226.5592, 1017.1369, 		1,  GetBankVaultWorld( CITY_LV ), true ,false, 52 );
	CreateEntrance( "[BURGER SHOT]", 		2367.0581, 2071.0891, 10.8203, 362.8823, -75.1634, 1001.5078, 			10, 32, false, false, 10 );
	CreateEntrance( "[BURGER SHOT]", 		2472.8640, 2034.1476, 11.0625, 362.8823, -75.1634, 1001.5078, 			10, 33, false, false, 10 );
	CreateEntrance( "[BURGER SHOT]", 		1139.5267, 2080.2134, 11.0547, 362.8823, -75.1634, 1001.5078, 			10, 34, false, false, 10 );
	CreateEntrance( "[BURGER SHOT]", 		2169.4082, 2795.8718, 10.8203, 362.8823, -75.1634, 1001.5078, 			10, 25, false, false, 10 );
	CreateEntrance( "[BURGER SHOT]", 		1872.2546, 2071.8691, 11.0625, 362.8823, -75.1634, 1001.5078, 			10, 82, false, false, 10 );
	CreateEntrance( "[CLUCKING BELL]", 		2393.2661, 2041.5591, 10.8203, 364.9896, -11.8441, 1001.8516, 			9,  35, false, false, 14 );
	CreateEntrance( "[CLUCKING BELL]", 		2101.8945, 2228.8604, 11.0234, 364.9896, -11.8441, 1001.8516, 			9,  36, false, false, 14 );
	CreateEntrance( "[CLUCKING BELL]", 		2638.5894, 1671.8162, 11.0234, 364.9896, -11.8441, 1001.8516, 			9,  70, false, false, 14 );
	CreateEntrance( "[24/7]", 				2452.4753, 2065.1895, 10.8203, -25.9472, -188.2597, 1003.5469, 			17, 37, false, false, 61 );
	CreateEntrance( "[24/7]", 				2097.6931, 2224.7014, 11.0234, -25.9472, -188.2597, 1003.5469, 			17, 38, false, false, 61 );
	CreateEntrance( "[24/7]", 				2247.6357, 2396.1694, 10.8203, -25.9472, -188.2597, 1003.5469, 			17, 39, false, false, 61 );
	CreateEntrance( "[24/7]", 				1937.8262, 2307.2012, 10.8203, -25.9472, -188.2597, 1003.5469, 			17, 40, false, false, 61 );
	CreateEntrance( "[24/7]", 				2194.9402, 1991.0054, 12.2969, -25.9472, -188.2597, 1003.5469, 			17, 41, false, false, 61 );
	CreateEntrance( "[24/7]", 				2546.5657, 1972.6659, 10.8203, -25.9472, -188.2597, 1003.5469, 			17, 49, false, false, 61 );
	CreateEntrance( "[CHURCH]", 			2519.4944, 2033.3417, 11.1719, 2383.1277, 3204.1130, 1017.516, 			2,  39, true , false, -1 );
	CreateEntrance( "[CHURCH]", 			2225.0847, 2522.8762, 11.2222, 2383.1277, 3204.1130, 1017.516, 			2,  40, true , false, -1 );
	CreateEntrance( "[AMMU-NATION]", 		2159.5447, 943.24390, 10.8203, 285.8562, -86.7820, 1001.5229, 			4,  41, false, false,  6 );
	CreateEntrance( "[AMMU-NATION]", 		2539.5420, 2084.0510, 10.8203, 316.3490, -170.2974, 999.5938, 			6,  42, false, false,  6 );
	CreateEntrance( "[PIZZA]", 				2083.3840, 2224.6987, 11.0234, 372.2738, -133.5248, 1001.4922, 			5,  43, false, false, 29 );
	CreateEntrance( "[PIZZA]", 				2351.7537, 2533.6287, 10.8203, 372.2738, -133.5248, 1001.4922, 			5,  44, false, false, 29 );
	CreateEntrance( "[PIZZA]", 				2638.7852, 1849.8058, 11.0234, 372.2738, -133.5248, 1001.4922, 			5,  14, false, false, 29 );
	CreateEntrance( "[ZIP]", 				2090.5588, 2224.7007, 11.0234, 161.2982, -97.1033, 1001.8047, 			18, 45, false, false, 45 );
	CreateEntrance( "[ZIP]", 				2572.0657, 1904.9449, 11.0234, 161.2982, -97.1033, 1001.8047, 			18, 59, false, false, 45 );
	CreateEntrance( "[TATTOO]", 			2094.7612, 2122.8645, 10.8203, -204.417, -27.3470, 1002.2734, 			16, 46, false, false, 39 );
	CreateEntrance( "[BINCO]", 				1657.0360, 1733.3674, 10.8281, 207.6674, -111.2659, 1005.1328, 			15, 47, false, false, 45 );
	CreateEntrance( "[BINCO]", 				2101.8931, 2257.4358, 11.0234, 207.6674, -111.2659, 1005.1328, 			15, 48, false, false, 45 );
	CreateEntrance( "[BINCO]", 				2101.8931, 2257.4358, 11.0234, 207.6674, -111.2659, 1005.1328, 			15, 48, false, false, 45 );
	CreateEntrance( "[GAS STATION]", 		2117.4756, 896.77590, 11.1797, -27.2923, -58.0535, 1003.5469, 			6,  49, false, false, 55 );
	CreateEntrance( "[GAS STATION]", 		2150.7961, 2733.8657, 11.1763, -27.2923, -58.0535, 1003.5469, 			6,  20, false, false, 55 );
	CreateEntrance( "[GAS STATION]", 		2187.7136, 2469.6372, 11.2422, -27.2923, -58.0535, 1003.5469, 			6,  56, false, false, 55 );
	CreateEntrance( "[GAS STATION]", 		1598.9939, 2221.7271, 11.0625, -27.2923, -58.0535, 1003.5469, 			6,  73, false, false, 55 );
	CreateEntrance( "[POLICE DEPT.]", 		2337.0854, 2459.3132, 14.9742, 288.8254, 166.9291, 1007.1719, 			3,  30, false, false, 30 );
	CreateEntrance( "[POLICE DEPT.]", 		2287.0601, 2432.3679, 10.8203, 238.7245, 138.6265, 1003.0234, 			3,  30, false, false, -1 );
	CreateEntrance( "[SEX SHOP]", 			2085.1206, 2074.0837, 11.0547, -100.3562, -25.0387, 1000.7188, 			3,  51, false, false, 21 );
	CreateEntrance( "[CALIGULAS CASINO]",	2196.9648, 1677.1042, 12.3672, 2233.9617, 1714.6832, 1012.3828, 		1,  82, false, false, 25 );
	CreateEntrance( "[STEAKHOUSE]", 		2369.2261, 1984.2435, 10.8203, 460.5569, -88.6348, 999.5547, 			4,  53, false, false, 50 );
	CreateEntrance( "[STEAKHOUSE]", 		1694.1072, 2208.9211, 11.0692, 460.5569, -88.6348, 999.5547, 			4,  23, false, false, 50 );
	CreateEntrance( "[THE CRAW BAR]", 		2441.1377, 2065.4844, 10.8203, 501.9013, -67.5635, 998.7578, 			11, 54, false, false, 49 );
	CreateEntrance( "[4 DRAGONS CASINO]",	2019.3126, 1007.6581, 10.8203, 2019.0719, 1017.8998, 996.8750, 			10, 23, false, false, 43 );
	CreateEntrance( "[CITY HALL]", 			2412.5024, 1123.8776, 10.8203, 390.7462, 173.7627, 1008.3828, 			3,   2, false, false, -1 );
	CreateEntrance( "[BARBER]", 			2080.3018, 2122.8655, 10.8203, 411.8917,-54.4434, 1001.8984, 			12, 20, false, false,  7 );
	CreateEntrance( "[PD ROOFTOP]",			2282.1907, 2423.1160, 3.4766, 2279.8276, 2458.7380, 38.6875, 			0,   0, false, false, -1 );
	CreateEntrance( "[GYM]", 				1968.7761, 2295.8728, 16.4559, 773.9163, -78.8474, 1000.6628, 			7,   9, false, false, 54 );
	CreateEntrance( "[VEHICLE DEALERSHIP]", 1948.6849, 2068.6914, 11.0610, -126.9255, 98.1966, 1004.7233, 			10, 31, true , false, 55 );
	CreateEntrance( "[PAWNSHOP]", 			2482.4395, 1326.4077, 10.8203, 1329.7720, -1084.7529, 968.0360, 		2,  22, true , false, 25 );

	// Creek
	CreateEntrance( "[CLUCKING BELL]", 		2838.3081, 2407.5620, 11.0690, 364.9896, -11.8441, 1001.8516, 			9,  23, false, false, 14 );
	CreateEntrance( "[24/7]", 				2884.5488, 2454.0413, 11.0690, -25.9472, -188.2597, 1003.5469, 			17, 47, false, false, 61 );
	CreateEntrance( "[VICTIM]", 			2802.8586, 2430.7910, 11.0625, 227.3678, -8.3722, 1002.2109, 			5,  21, false, false, 45 );
	CreateEntrance( "[SUBURBAN]", 			2779.7080, 2453.9395, 11.0625, 203.8414, -50.6566, 1001.8047, 			1,  41, false, false, 45 );
	CreateEntrance( "[PIZZA]", 				2756.7673, 2477.3511, 11.0625, 372.2738, -133.5248, 1001.4922, 			5,  46, false, false, 29 );
	CreateEntrance( "[PROLAPS]", 			2826.0977, 2407.5505, 11.0625, 207.0255, -140.3765, 1003.5078, 			3,  36, false, false, 45 );
	#endif

	#if ENABLE_CITY_LS == true
	// Los Santos
	CreateEntrance( "[BANK]", 				595.380371, -1250.299194, 18.278293, 2162.4661, 1226.5592, 1017.1369, 			2,  GetBankVaultWorld( CITY_LS ), true , false, 52 );
	CreateEntrance( "[GYM]", 				2229.9028, -1721.258, 13.5612, 772.3065, -5.51570, 1000.7285, 			 		5,  10, false, false, 54 );
	CreateEntrance( "[TEN GREEN BOTTLES]",	2309.987548, -1643.436279, 14.827047, 501.9013, -67.5635, 998.7578, 			11, 58, false, false, 49 );
	CreateEntrance( "[CLUCKING BELL]", 		2397.816650, -1899.185058, 13.546875, 364.9896, -11.8441, 1001.8516, 			9,  39, false, false, 14 );
	CreateEntrance( "[CLUCKING BELL]", 		928.915588, -1353.043823, 13.343750, 364.9896, -11.8441, 1001.8516, 			9,  13, false, false, 14 );
	CreateEntrance( "[CLUCKING BELL]", 		2419.702636, -1509.045654, 24.000000, 364.9896, -11.8441, 1001.8516, 			9,  16, false, false, 14 );
	CreateEntrance( "[BINCO]", 				2244.381347, -1665.566650, 15.476562, 207.6674, -111.2659, 1005.1328, 			15, 53, false, false, 45 );
	CreateEntrance( "[AMMU-NATION]", 		2400.493408, -1981.995605, 13.546875, 285.8562, -86.7820, 1001.5229, 			4,  74, false, false,  6 );
	CreateEntrance( "[AMMU-NATION]", 		1369.000122, -1279.712646, 13.546875, 316.3490, -170.2974, 999.5938, 			6,  75, false, false,  6 );
	CreateEntrance( "[SEX SHOP]", 			1940.006225, -2115.978027, 13.695312, -100.3562, -25.0387, 1000.7188, 			3,  64, false, false, 21 );
	CreateEntrance( "[SEX SHOP]", 			1087.683471, -922.481994, 43.390625, -100.3562, -25.0387, 1000.7188, 			3,  32, false, false, 21 );
	CreateEntrance( "[GAS STATION]", 		1928.580932, -1776.264892, 13.546875, -27.2923, -58.0535, 1003.5469, 			6,  68, false, false, 55 );
	CreateEntrance( "[GAS STATION]", 		-78.360862, -1169.870605, 2.135507, -27.2923, -58.0535, 1003.5469, 				6,  92, false, false, 55 );
	CreateEntrance( "[BURGER SHOT]", 		810.484741, -1616.128906, 13.546875, 362.8823, -75.1634, 1001.5078, 			10, 35, false, false, 10 );
	CreateEntrance( "[BURGER SHOT]", 		1199.256347, -918.142150, 43.123218, 362.8823, -75.1634, 1001.5078, 			10, 71, false, false, 10 );
	CreateEntrance( "[BARBER]", 			824.059570, -1588.316894, 13.543567, 411.8917,-54.4434,1001.8984, 				12, 21, false, false,  7 );
	CreateEntrance( "[BARBER]", 			2070.632568, -1793.837036, 13.546875, 411.8917,-54.4434,1001.8984, 				12, 22, false, false,  7 );
	CreateEntrance( "[POLICE DEPT.]", 		1555.501220, -1675.639038, 16.195312, 246.8373,62.3343,1003.6406, 				6,  30, false, false, 30 );
	CreateEntrance( "[PIZZA]", 				2105.488281, -1806.570434, 13.554687, 372.2738, -133.5248, 1001.4922, 			5,  12, false, false, 29 );
	CreateEntrance( "[STRIP CLUB]", 		2421.597900, -1219.242675, 25.561447, 1204.7625,-13.8523,1000.9219, 			2,  22, false, false, -1 );
	CreateEntrance( "[DISCO]", 				1837.038696, -1682.395996, 13.322851, 493.4810, -24.9531, 1000.6719, 			17, 71, false, false, 48 );
	CreateEntrance( "[24/7]", 				1833.777343, -1842.623657, 13.578125, -25.9472, -188.2597, 1003.5469, 			17, 51, false, false, 61 );
	CreateEntrance( "[24/7]", 				1000.593017, -919.916809, 42.328125, -25.9472, -188.2597, 1003.5469, 			17, 48, false, false, 61 );
	CreateEntrance( "[TATTOO]", 			2068.582763, -1779.853881, 13.559624, -204.417, -27.3470, 1002.2734, 			16, 42, false, false, 39 );
	//CreateEntrance( "[VEHICLE DEALERSHIP]", 542.2485000, -1293.922200, 17.242000, -126.9255, 98.1966, 1004.7233, 			11, 32, true , false, 55 );
	CreateEntrance( "[SUBURBAN]", 			2112.8643, -1211.4548, 23.9629, 203.8414, -50.6566, 1001.8047, 					1,  39, false, false, 45 );
	CreateEntrance( "[VICTIM]", 			461.707031, -1500.845092, 31.044902, 227.3678, -8.3722, 1002.2109, 				5,  49, false, false, 45 );
	CreateEntrance( "[DRUG HOUSE]", 		1449.219360, -1849.375000, 13.973744, 2196.8398, -1204.4272, 1049.0234, 		6,  94, false, false, 24 );
	CreateEntrance( "[DRUG HOUSE]", 		2290.139404, -1796.005371, 13.546875, 2196.8398, -1204.4272, 1049.0234, 		6,  31, false, false, 24 );
	CreateEntrance( "[DRUG HOUSE]", 		2165.931152, -1671.195190, 15.073156, 2196.8398, -1204.4272, 1049.0234, 		6,  44, false, false, 24 );
	CreateEntrance( "[DRUG HOUSE]", 		2486.490722, -1644.531616, 14.077178, 2196.8398, -1204.4272, 1049.0234, 		6,  10, false, false, 24 );
	CreateEntrance( "[DRUG HOUSE]", 		2351.937255, -1170.664672, 28.074649, 2196.8398, -1204.4272, 1049.0234, 		6,  15, false, false, 24 );
	CreateEntrance( "[JIM'S STICKY DONUTS]",1038.096191, -1340.726074, 13.745031, 377.1306, -193.3048, 1000.6328, 			17, 10, false, false, 17 );
	CreateEntrance( "[CITY HALL]", 			1481.037719, -1772.312622, 18.795755, 390.7462, 173.7627, 1008.3828, 			3,   5, false, false, -1 );
	CreateEntrance( "[JEFFERSON MOTEL]", 	2233.292968, -1159.849243, 25.890625, 2214.3845, -1150.4780, 1025.7969, 		15, 21, false, false, -1 );
	CreateEntrance( "[PROLAPS]", 			499.5353000, -1360.6348, 16.3690, 207.0255, -140.3765, 1003.5078, 				3,  39, false, false, 45 );
	CreateEntrance( "[ZIP]", 				1457.0670, -1137.1027, 23.9441, 161.2982, -97.1033, 1001.8047, 					18, 27, false, false, 45 );
	CreateEntrance( "[PAWNSHOP]", 			2507.3076, -1724.6044, 13.5469, 1329.7720, -1084.7529, 968.0360, 				2,  33, true , false, 25 );
	CreateEntrance( "[DIDIER SACHS]",		454.2061, -1477.9880, 30.8142, 204.3547, -168.8608, 1000.5234, 					14, 14, true , false, 22 );

	// Angel Pine
	CreateEntrance( "[AMMU-NATION]", 		-2093.670898, -2464.938964, 30.625000, 316.3490, -170.2974, 999.5938, 			6,  32, false, false,  6 );
	CreateEntrance( "[CLUCKING BELL]", 		-2155.283447, -2460.122070, 30.851562, 364.9896, -11.8441, 1001.8516, 			9,  12, false, false, 14 );
	CreateEntrance( "[GAS STATION]", 		-2231.472900, -2558.297119, 31.921875, -27.2923, -58.0535, 1003.5469, 			6,  74, false, false, 55 );
	CreateEntrance( "[STEAKHOUSE]", 		-2103.568603, -2342.283203, 30.625000, 460.5569, -88.6348, 999.5547, 			4,  27, false, false, 50 );

	// Blueberry
	CreateEntrance( "[STEAKHOUSE]", 		293.340881, -195.475814, 1.778619, 460.5569, -88.6348, 999.5547, 				4,  22, false, false, 50 );
	CreateEntrance( "[AMMU-NATION]", 		243.294967, -178.334701, 1.582162, 316.3490, -170.2974, 999.5938, 				6,  23, false, false,  6 );
	CreateEntrance( "[PIZZA]", 				203.481597, -201.936798, 1.578125, 372.2738, -133.5248, 1001.4922, 				5,  31, false, false, 29 );

	// Dillimore
	CreateEntrance( "[BAR]", 				681.612243, -473.346771, 16.536296, 501.9013, -67.5635, 998.7578, 				11, 17, false, false, 49 );
	CreateEntrance( "[BARBER]", 			672.088317, -496.847564, 16.335937, 411.8917,-54.4434,1001.8984, 				12, 18, false, false,  7 );
	CreateEntrance( "[24/7]", 				694.930969, -500.131072, 16.335937, -25.9472, -188.2597, 1003.5469, 			17, 11, false, false, 61 );

	// Montgomery
	CreateEntrance( "[PIZZA]", 				1367.548950, 248.235580, 19.566932, 372.2738, -133.5248, 1001.4922, 			5,  75, false, false, 29 );
	CreateEntrance( "[GAS STATION]", 		1383.270507, 465.549926, 20.191875, -27.2923, -58.0535, 1003.5469, 				6,  77, false, false, 55 );
	CreateEntrance( "[BAR]", 				1359.643920, 205.083831, 19.755516, 501.9013, -67.5635, 998.7578, 				11, 36, false, false, 49 );
	CreateEntrance( "[BAR]", 				1244.703735, 205.342956, 19.645431, 501.9013, -67.5635, 998.7578, 				11, 41, false, false, 49 );

	// Palomino Creek
	CreateEntrance( "[PIZZA]", 				2331.810058, 75.064132, 26.620975, 372.2738, -133.5248, 1001.4922, 				5,  66, false, false, 29 );
	CreateEntrance( "[AMMU-NATION]", 		2333.088867, 61.584743, 26.705789, 316.3490, -170.2974, 999.5938, 				6,  27, false, false,  6 );
	CreateEntrance( "[BANK]", 				2303.827880, -16.152278, 26.484375, 2155.0652,1651.0916,1041.6198, 				69, 78, true , false, 52 );
	CreateEntrance( "[SEX SHOP]", 			2304.576416, 14.248206, 26.484375, -100.3562, -25.0387, 1000.7188, 				3,  16, false, false, 21 );
	CreateEntrance( "[BAR]", 				2332.996337, -17.302047, 26.484375, 501.9013, -67.5635, 998.7578, 				11, 22, false, false, 49 );
	CreateEntrance( "[CHURCH]", 			2256.691406, -44.642879, 26.883434, 2383.1277, 3204.1130, 1017.516, 			2,  41, true , false, -1 );
	#endif

	// Fort Carson
	CreateEntrance( "[RESTAURANT]", 		-53.82020, 1188.7482, 19.3594, -229.2946, 1401.1322, 27.7656, 			18, 53, false, false, 50 );
	CreateEntrance( "[LIL' PROBE INN]", 	-89.61480, 1378.2664, 10.4698, -229.2946, 1401.1322, 27.7656, 			18, 54, false, false, 50 );
	CreateEntrance( "[BANK]", 				-179.1860, 1133.1830, 19.7422, 2155.0652,1651.0916,1041.6198, 			69, 45, true , false, 52 );
	CreateEntrance( "[CHURCH]", 			-207.8720, 1119.1965, 20.4297, 2383.1277, 3204.1130, 1017.516, 			2,  24, true , false, -1 );
	CreateEntrance( "[CACTUS BAR]", 		-179.6980, 1087.5027, 19.7422, 501.9013, -67.5635, 998.7578, 			11, 56, false, false, 49 );
	CreateEntrance( "[24/7]", 				-180.7307, 1034.8035, 19.7422, -25.9472, -188.2597, 1003.5469, 			17, 42, false, false, 61 );
	CreateEntrance( "[KING RING DONUTS]", 	-144.0186, 1225.2097, 19.8992, 377.1306, -193.3048, 1000.6328, 			17, 20, false, false, 17 );
	CreateEntrance( "[BARBER]", 			-206.1856, 1062.1968, 19.7422, 411.8917,-54.4434,1001.8984, 			12, 48, false, false,  7 );
	CreateEntrance( "[AMMU-NATION]", 		-316.1613, 829.79550, 14.2422, 316.3490, -170.2974, 999.5938, 			6,   5, false, false,  6 );

	// El Casillo del Diablo
	CreateEntrance( "[CHURCH]", 			-361.7441, 2222.3257, 43.0078, 2383.1277, 3204.1130, 1017.516, 			1,  62, true , false, -1 );
	CreateEntrance( "[BAR]", 				-384.8090, 2206.1194, 42.4235, 501.9013, -67.5635, 998.7578, 			11, 10, false, false, 49 );

	// Bone Country
	CreateEntrance( "[AMMU-NATION]", 		776.72050, 1871.4076, 4.90660, 316.3490, -170.2974, 999.5938, 			6,  45, false, false,  6 );
	CreateEntrance( "[BROTHEL]", 			693.69150, 1967.6844, 5.53910, 968.1353, -53.2577, 1001.1246, 			3,  42, false, false, 49 );
	CreateEntrance( "[GAS STATION]", 		663.14670, 1716.3582, 7.18750, -27.2923, -58.0535, 1003.5469, 			6,  32, false, false, 55 );
	CreateEntrance( "[CLUCKING BELL]", 		172.98640, 1177.1807, 14.7578, 364.9896, -11.8441, 1001.8516, 			9,  62, false, false, 14 );

	// Tierra Robada
	CreateEntrance( "[CLUCKING BELL]", 		-1213.7229, 1830.2632, 41.9297, 364.9896, -11.8441, 1001.8516, 			9,  60, false, false, 14 );
	CreateEntrance( "[GAS STATION]", 		-1320.5590, 2698.6082, 50.2663, -27.2923, -58.0535, 1003.5469, 			6,  33, false, false, 55 );
	CreateEntrance( "[GAS STATION]", 		-1465.8094, 1873.4160, 32.6328, -27.2923, -58.0535, 1003.5469, 			6,  34, false, false, 55 );
	CreateEntrance( "[TIERRA BAR]", 		-1271.3542, 2713.3086, 50.2663, 501.9013, -67.5635, 998.7578, 			11, 55, false, false, 49 );
	CreateEntrance( "[JAY'S BAR]", 			-1942.1311, 2379.4358, 49.7031, 501.9013, -67.5635, 998.7578, 			11, 15, false, false, 49 );

	// Las Barrancas
	CreateEntrance( "[STEAKHOUSE]", 		-857.9400, 1535.3420, 22.5870, 460.5569, -88.6348, 999.5547, 			4,  54, false, false, 50 );
	CreateEntrance( "[BANK]", 				-828.1797, 1504.5967, 19.8528, 2155.0652,1651.0916,1041.6198, 			69, 24, true , false, 52 );
	CreateEntrance( "[24/7]", 				-780.3192, 1501.4674, 23.7957, -25.9472, -188.2597, 1003.5469, 			17, 43, false, false, 61 );

	// El Quebrados
	CreateEntrance( "[AMMU-NATION]", 		-1508.8550, 2610.7004, 55.8359, 316.3490, -170.2974, 999.5938, 			6,  47, false, false,  6 );
	CreateEntrance( "[BAR]", 				-1519.1434, 2610.3274, 55.8359, 501.9013, -67.5635, 998.7578, 			11, 50, false, false, 49 );
	CreateEntrance( "[BARBER]", 			-1449.8353, 2591.9045, 55.8359, 411.8917,-54.4434,1001.8984, 			12, 24, false, false,  7 );
	CreateEntrance( "[24/7]", 				-1480.8905, 2591.6638, 55.8359, -25.3519, -188.1018, 1003.5469, 		17,  44, false, false, 61 );

	// Las Payasadas
	CreateEntrance( "[BANK]", 				-288.8788, 2689.7905, 62.8125, 2155.0652,1651.0916,1041.6198, 			69, 25, true , false, 52 );
	CreateEntrance( "[BAR]", 				-255.1494, 2603.2395, 62.8582, 501.9013, -67.5635, 998.7578, 			11, 52, false, false, 49 );

	// Unknown
	CreateEntrance( "[BAR]", 				-314.0455, 1774.7166, 43.6406, 501.9013, -67.5635, 998.7578, 			11, 21, false, false, 49 );
	CreateEntrance( "[GAS STATION]", 		-736.2042, 2747.8445, 47.2266, -27.2923, -58.0535, 1003.5469, 			6,  52, false, false, 55 );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( CanPlayerExitEntrance( playerid ) && ! IsPlayerInAnyVehicle( playerid ) )
	{
		foreach ( new i : entrances )
		{
			if ( checkpointid == g_entranceData[ i ] [ E_ENTER ] )
			{
				if ( ! CallLocalFunction( "OnPlayerAccessEntrance", "dddd", playerid, i, g_entranceData[ i ] [ E_WORLD ], g_entranceData[ i ] [ E_INTERIOR ] ) ) break;
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
	return 1;
}

/* ** SQL Threads ** */
thread OnEntrancesLoad( )
{
	new
		rows, fields, i = -1, label[ 32 ],
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			// Save label
			cache_get_field_content( i, "LABEL", label );

			// Create entrance
			CreateEntrance( label,
				cache_get_field_content_float( i, "X", dbHandle ),
				cache_get_field_content_float( i, "Y", dbHandle ),
				cache_get_field_content_float( i, "Z", dbHandle ),
				cache_get_field_content_float( i, "EX", dbHandle ),
				cache_get_field_content_float( i, "EY", dbHandle ),
				cache_get_field_content_float( i, "EZ", dbHandle ),
				cache_get_field_content_int( i, "INTERIOR", dbHandle ),
				cache_get_field_content_int( i, "WORLD", dbHandle ),
				!!cache_get_field_content_int( i, "CUSTOM", dbHandle ),
				!!cache_get_field_content_int( i, "VIP_ONLY", dbHandle ),
				cache_get_field_content_int( i, "MAP_ICON", dbHandle ),
				.savedId = cache_get_field_content_int( i, "ID", dbHandle )
			);
		}
	}
	printf( "[ENTRANCES]: %d entrances have been loaded. (Tick: %dms)", Iter_Count( entrances ), GetTickCount( ) - loadingTick );
	return 1;
}

/* ** Functions ** */
stock CreateEntrance( const name[ ], Float: X, Float: Y, Float: Z, Float: lX, Float: lY, Float: lZ, interior, world, bool: custom = false, bool: viponly = false, mapicon = -1, savedId = 0 )
{
	new
		ID = Iter_Free(entrances);

	if ( ID != ITER_NONE )
	{
		Iter_Add(entrances, ID);
	    g_entranceData[ ID ] [ E_WORLD ] = world;
	    g_entranceData[ ID ] [ E_INTERIOR ] = interior;
	    g_entranceData[ ID ] [ E_EX ] = X;
	    g_entranceData[ ID ] [ E_EY ] = Y;
	    g_entranceData[ ID ] [ E_EZ ] = Z;
	    g_entranceData[ ID ] [ E_LX ] = lX;
	    g_entranceData[ ID ] [ E_LY ] = lY;
	    g_entranceData[ ID ] [ E_LZ ] = lZ;
	    g_entranceData[ ID ] [ E_SQL_ID ] = savedId;
	    g_entranceData[ ID ] [ E_CUSTOM ] = custom;
	    g_entranceData[ ID ] [ E_VIP ] = viponly;
	    g_entranceData[ ID ] [ E_SAVED ] = savedId != 0;
	    g_entranceData[ ID ] [ E_ENTER ] = CreateDynamicCP( X, Y, Z, 1.5 );
	    g_entranceData[ ID ] [ E_EXIT ] = CreateDynamicCP( lX, lY, lZ, 1.0, world, interior );
		g_entranceData[ ID ] [ E_ENTER_LABEL ] = CreateDynamic3DTextLabel( name, COLOR_GOLD, X, Y, Z, 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1 );
		g_entranceData[ ID ] [ E_EXIT_LABEL ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, lX, lY, lZ, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, world, interior );
	   	if ( mapicon != -1 ) CreateDynamicMapIcon( X, Y, Z, mapicon, 0, -1, -1, -1, 750.0 );
	}
	return ID;
}

stock DestroyEntrance( entranceid )
{
	if ( !Iter_Contains( entrances, entranceid ) )
		return;

	Iter_Remove( entrances, entranceid );
	DestroyDynamicCP( g_entranceData[ entranceid ] [ E_ENTER ] );
	DestroyDynamicCP( g_entranceData[ entranceid ] [ E_EXIT ] );
	DestroyDynamic3DTextLabel( g_entranceData[ entranceid ] [ E_ENTER_LABEL ] );
	DestroyDynamic3DTextLabel( g_entranceData[ entranceid ] [ E_EXIT_LABEL ] );
	mysql_single_query( sprintf( "DELETE FROM `ENTRANCES` WHERE `ID`=%d", g_entranceData[ entranceid ] [ E_SQL_ID ] ) );
}

stock GetClosestEntrance( playerid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = -1, Float: fTmp;

	foreach ( new id : entrances )
	{
        if ( 0.0 < ( fTmp = GetDistanceFromPlayerSquared( playerid, g_entranceData[ id ] [ E_EX ], g_entranceData[ id ] [ E_EY ], g_entranceData[ id ] [ E_EZ ] ) ) < distance ) // Y_Less mentioned there's no need to sqroot
        {
            distance = fTmp;
            iCurrent = id;
        }
    }
    return iCurrent;
}

stock GetEntrancePos( entranceid, &Float: X, &Float: Y, &Float: Z ) {
	X = g_entranceData[ entranceid ] [ E_EX ];
	Y = g_entranceData[ entranceid ] [ E_EY ];
	Z = g_entranceData[ entranceid ] [ E_EZ ];
}

stock GetEntranceInsidePos( entranceid, &Float: X, &Float: Y, &Float: Z ) {
	X = g_entranceData[ entranceid ] [ E_LX ];
	Y = g_entranceData[ entranceid ] [ E_LY ];
	Z = g_entranceData[ entranceid ] [ E_LZ ];
	return 1;
}

stock GetEntranceWorld( entranceid ) {
	return g_entranceData[ entranceid ] [ E_WORLD ];
}

stock GetEntranceInterior( entranceid ) {
	return g_entranceData[ entranceid ] [ E_INTERIOR ];
}
