/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\robbery\robbery_init.pwn
 * Purpose: create all robbery instances on server initialize (cnr)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnScriptInit( )
{
	static const ROBBERY_BOT_PAY = 2250; // max pay from robbing bots
	static const ROBBERY_SAFE_PAY = 5000; // max pay from robbing safes

	CreateMultipleRobberies( "Bank of San Fierro - Safe 1", floatround( float( ROBBERY_SAFE_PAY ) * 1.85 ), -1400.941772, 862.858947, 984.17200, -90.00000, g_bankvaultData[ CITY_SF ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of San Fierro - Safe 2", floatround( float( ROBBERY_SAFE_PAY ) * 1.85 ), -1400.941772, 861.179321, 985.07251, -90.00000, g_bankvaultData[ CITY_SF ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of San Fierro - Safe 3", floatround( float( ROBBERY_SAFE_PAY ) * 1.85 ), -1400.941772, 856.086791, 985.07251, -90.00000, g_bankvaultData[ CITY_SF ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of San Fierro - Safe 4", floatround( float( ROBBERY_SAFE_PAY ) * 1.85 ), -1400.941772, 858.614074, 984.17200, -90.00000, g_bankvaultData[ CITY_SF ] [ E_WORLD ] );

	CreateMultipleRobberies( "Desperado Cafe", 		floatround( float( ROBBERY_SAFE_PAY ) * 0.5 ), 2113.085693, -1784.66638, 12.95044, 180.00000, -1 );
	CreateMultipleRobberies( "Ahmyy's Cafe", 		floatround( float( ROBBERY_SAFE_PAY ) * 0.5 ), 2540.658691, 2013.840209, 10.289649, 90.000000, -1 );
	CreateMultipleRobberies( "Nibble Cafe", 		floatround( float( ROBBERY_SAFE_PAY ) * 0.5 ), 1978.945312, 2066.297607, 10.285301, 90.000000, -1 );
	CreateMultipleRobberies( "Le Flawless Cafe", 	floatround( float( ROBBERY_SAFE_PAY ) * 0.5 ), -1968.052612, 107.914459, 27.092870, 0.0000000, -1 );

	CreateMultipleRobberies( "Hospital", 			floatround( float( ROBBERY_SAFE_PAY ) * 1.25 ), -2638.146484, 662.669677, 969.852905, -90.0000, -1 );

	CreateMultipleRobberies( "Sex Shop", 			ROBBERY_SAFE_PAY, -108.273361, -8.523513, 1000.188232, 90.000000, 16, 32, 51, 64 );
	CreateRobberyNPC( "Sex Shop Clerk",				ROBBERY_BOT_PAY, -104.7642, -8.9156, 1000.7188, 181.2191, 126, 16, 32, 51, 64 );

	CreateMultipleRobberies( "Off Track Betting", 	ROBBERY_SAFE_PAY, 822.206787, 8.124695, 1004.423278, 169.80003, -1 );
	CreateRobberyNPC( "Betting Clerk",				ROBBERY_BOT_PAY, 820.1871, 2.4114, 1004.1797, 270.8091, 147, -1 );

	CreateMultipleRobberies( "Zero's RC Shop", 		ROBBERY_SAFE_PAY, -2221.724365, 132.967208, 1035.223022, 180.00000, 6 );
	CreateRobberyNPC( "Zero",						ROBBERY_BOT_PAY, -2238.1279, 128.5869, 1035.4141, 357.9158, 11, 6 );

	CreateMultipleRobberies( "Prolaps", 			ROBBERY_SAFE_PAY, 204.282577, -126.326202, 1002.937255, 0.0000000, 39, 36 );
	CreateRobberyNPC( "Prolaps Clerk",				ROBBERY_BOT_PAY, 206.3402, -127.8070, 1003.5078, 182.5186, 211, 39, 36 );

	CreateMultipleRobberies( "Disco", 				ROBBERY_SAFE_PAY, 503.633575, -24.120403, 1000.119323, 270.00000, 17, 71 );
	CreateRobberyNPC( "Disco Bartender",			ROBBERY_BOT_PAY, 501.6992,-20.5021,1000.6797,89.2442, 46, 17, 71 );

	CreateMultipleRobberies( "Restaurant", 			ROBBERY_SAFE_PAY, -221.279922, 1407.674072, 27.22343200, 0.0000000, 53, 54 );
	CreateRobberyNPC( "Restaurant Owner",			ROBBERY_BOT_PAY, -223.3083,1403.9852,27.7734,91.9926, 168, 53, 54 );

	CreateMultipleRobberies( "Brothel", 			ROBBERY_SAFE_PAY, 971.980346, -44.324848, 1001.677368, 270.00000, 42 );
	CreateRobberyNPC( "Brothel Manager",			ROBBERY_BOT_PAY, 970.8360, -44.8730, 1001.1172, 92.0651, 113, 42 );

	CreateMultipleRobberies( "Ammu-Nation", 		ROBBERY_SAFE_PAY, 299.776275, -41.373123, 1000.945068, -137.0001, 15 );
	CreateRobberyNPC( "Gunsdealer",					ROBBERY_BOT_PAY, 296.4001,-40.2152,1001.5156,0.9079, 179, 15 );

	CreateMultipleRobberies( "Ammu-Nation", 		ROBBERY_SAFE_PAY, 293.567565, -83.653007, 1000.905151, 90.000000, 41, 74 );
	CreateRobberyNPC( "Gunsdealer",					ROBBERY_BOT_PAY, 295.4592,-82.5274,1001.5156,359.9681, 179, 41, 74 );

	CreateMultipleRobberies( "Ammu-Nation", 		ROBBERY_SAFE_PAY, 313.717559, -168.976150, 999.0332640, -90.00000, 42, 45, 47, 5, 75, 32, 23, 27 );
	CreateRobberyNPC( "Gunsdealer",					ROBBERY_BOT_PAY, 312.8466,-167.7639,999.5938,359.6548, 179, 42, 45, 47, 5, 75, 32, 23, 27 );

	CreateMultipleRobberies( "ZIP", 				ROBBERY_SAFE_PAY, 163.303283, -79.763473, 1001.274536, -90.00000, 3, 45, 59, 27 );
	CreateRobberyNPC( "ZIP Clerk",					ROBBERY_BOT_PAY, 162.7249, -81.1920,1001.8047, 182.6196, 217, 3, 45, 59, 27 );

	CreateMultipleRobberies( "Binco", 				ROBBERY_SAFE_PAY, 207.486953, -96.336982, 1004.707275, 0.0000000, 12, 47, 48, 53 );
	CreateRobberyNPC( "Binco Clerk",				ROBBERY_BOT_PAY, 208.8378,-98.7054,1005.2578,183.2461, 217, 12, 47, 48, 53 );

	CreateMultipleRobberies( "Victim", 				ROBBERY_SAFE_PAY, 200.075378, -5.995379, 1000.650390, 180.00000, 1, 21, 49 );
	CreateRobberyNPC( "Victim Clerk",				ROBBERY_BOT_PAY, 204.6066, -9.2214, 1001.2109, 268.2160, 211, 1, 21, 49 );

	CreateMultipleRobberies( "Suburban", 			ROBBERY_SAFE_PAY, 204.337600, -42.450820, 1001.254699, 180.00000, 21, 41, 39 );
	CreateRobberyNPC( "Suburban Clerk",				ROBBERY_BOT_PAY, 203.2509,-41.6712, 1001.8047, 178.8591, 211, 21, 41, 39 );

	CreateMultipleRobberies( "Bar", 				ROBBERY_SAFE_PAY, 498.197845, -80.120513, 999.3255610, 180.00000, 7, 54, 55, 56, 50, 52, 51, 15, 10, 21, 58, 48, 17, 36, 41, 22 );
	CreateRobberyNPC( "Bartender",					ROBBERY_BOT_PAY, 497.0969,-77.5612,998.7651,1.5118, 124, 7, 54, 55, 56, 50, 52, 51, 15, 10, 21, 58, 48, 17, 36, 41, 22 );

	CreateMultipleRobberies( "Burger Shot", 		ROBBERY_SAFE_PAY, 381.988861, -56.370349, 1000.957275, 0.0000000, 4, 9, 13, 32, 33, 34, 35, 25, 71, 82 );
	CreateRobberyNPC( "Burger Worker",				ROBBERY_BOT_PAY, 376.5223,-65.8494,1001.5078,182.3066, 205, 4, 9, 13, 32, 33, 34, 35, 25, 71, 82 );

	CreateMultipleRobberies( "Cluckin' Bell", 		ROBBERY_SAFE_PAY, 371.999816, -2.711749, 1002.278808, 0.0000000, 5, 14, 35, 36, 62, 60, 23, 39, 13, 16, 12, 70 );
	CreateRobberyNPC( "Chicken Worker",				ROBBERY_BOT_PAY, 368.1003,-4.4928,1001.8516,182.3297, 168, 5, 14, 35, 36, 62, 60, 23, 39, 13, 16, 12, 70 );

	CreateMultipleRobberies( "Well Stacked Pizza", 	ROBBERY_SAFE_PAY, 380.231140, -116.337081, 1000.951721, -90.00000, 2, 20, 43, 44, 46, 12, 31, 75, 66, 14 );
	CreateRobberyNPC( "Pizza Worker",				ROBBERY_BOT_PAY, 374.6979,-117.2789,1001.4922,182.6662, 155, 2, 20, 43, 44, 46, 12, 31, 75, 66, 14 );

	CreateMultipleRobberies( "24/7",      			ROBBERY_SAFE_PAY, -8.180466, -180.865447, 1002.996337, 180.00000, 37, 38, 39, 40, 41, 42, 43, 44, 47, 49 ,51, 48, 11 );
	CreateRobberyNPC( "24/7 Worker",				ROBBERY_BOT_PAY, -27.9842,-186.8359,1003.5469,359.3645, 170, 37, 38, 39, 40, 41, 42, 43, 44, 47, 49 ,51, 48, 11 );

	CreateMultipleRobberies( "Barber", 				ROBBERY_SAFE_PAY, 408.697540, -56.145412, 1001.337951, 180.00000, 23, 24, 48, 21, 18, 22, 20 );
	CreateRobberyNPC( "Barber",						ROBBERY_BOT_PAY, 408.9915,-53.8337,1001.8984,270.7148, 176, 23, 24, 48, 21, 18, 22, 20 );

	CreateMultipleRobberies( "Donut Shop", 			ROBBERY_SAFE_PAY, 382.413513, -186.959243, 1001.132995, -90.00000, 19, 20, 10 );
	CreateRobberyNPC( "Donut Worker",				ROBBERY_BOT_PAY, 380.7286,-189.1152,1000.6328,182.3538, 8, 19, 20, 10 );

	CreateMultipleRobberies( "Strip Club", 			ROBBERY_SAFE_PAY, 1211.948974, -16.412891, 1001.421752, 180.00000, 3, 22 );
	CreateRobberyNPC( "Stripper",					ROBBERY_BOT_PAY, 1214.2621,-15.2605,1000.9219,359.1004, 246, 3, 22 );

	CreateMultipleRobberies( "Otto's cars", 		ROBBERY_SAFE_PAY, -1657.916870, 1206.418701, 6.709994000, 180.00000, 0 );
	CreateRobberyNPC( "Otto",						ROBBERY_BOT_PAY, -1656.4574,1207.9980,7.2500,329.9846, 113, 0 );

	CreateMultipleRobberies( "Wang Cars", 			ROBBERY_SAFE_PAY, -1950.600952, 302.176483, 34.91876200, -90.00000, 0 );
	CreateRobberyNPC( "Salesman",					ROBBERY_BOT_PAY, -1955.2711,302.1761,35.4688,89.4329, 17, 0 );

	CreateMultipleRobberies( "Jizzy's", 			ROBBERY_SAFE_PAY, -2664.599853, 1425.926391, 906.3808590, -90.00000, 18 );
	CreateRobberyNPC( "Jizzy",						ROBBERY_BOT_PAY, -2655.5063,1407.4214,906.2734,268.8851, 296, 18 );

	CreateMultipleRobberies( "Didier Sachs", 		ROBBERY_SAFE_PAY, 206.808502, -154.612808, 999.953369, 0.0000000, 14 );
	CreateRobberyNPC( "Didier Sach Clerk",			ROBBERY_BOT_PAY, 203.2169,-157.8303,1000.5234,180.5475, 211, 14 );

	CreateMultipleRobberies( "Steakhouse", 			ROBBERY_SAFE_PAY, 441.640106, -81.971298, 999.0115, 90.00000, 53, 54, 23, 27, 22 );
	CreateRobberyNPC( "Steakhouse Owner",			ROBBERY_BOT_PAY, 449.4273, -82.2324, 999.5547, 179.9200, 168, 53, 54, 23, 27, 22 );

	CreateMultipleRobberies( "Church", 				ROBBERY_SAFE_PAY, 1964.069335, -349.456512, 1096.640380, 0.0000000, 1 );
	CreateRobberyNPC( "Priest",						ROBBERY_BOT_PAY, 1964.0864,-371.6995,1093.7289,358.7696, 68, 1 );

	CreateMultipleRobberies( "Church", 				ROBBERY_SAFE_PAY, 2390.926757, 3195.784179, 1016.920837, -90.00000, 39, 40, 41, 62, 24 );
	CreateRobberyNPC( "Priest",						ROBBERY_BOT_PAY, 2383.1968,3193.2842,1017.7320,1.0113, 68, 39, 40, 41, 62, 24 );

	CreateMultipleRobberies( "Hotel de Solanum", 	ROBBERY_SAFE_PAY, -1967.766357, 1367.773925, 6.879500000, 86.700000, 0 );
	CreateRobberyNPC( "Hotel Bartender",			ROBBERY_BOT_PAY, -1944.5562,1362.2947,7.3546,86.4801, 126, 0 );

	CreateMultipleRobberies( "Vehicle Dealership",	ROBBERY_SAFE_PAY, -1862.799682, -652.836608, 1001.578125, -89.80000, 0 );
	CreateRobberyNPC( "Vehicle Dealer",				ROBBERY_BOT_PAY, -1864.9419,-648.5046,1002.1284,357.5644, 186, 0 );

	CreateMultipleRobberies( "Vehicle Dealership",	ROBBERY_SAFE_PAY, -125.972930, 122.111770, 1004.083740, 0.000000, 31, 32 );
	CreateRobberyNPC( "Vehicle Dealer",				ROBBERY_BOT_PAY, -125.2779,121.3010,1004.7233,345.3443, 186, 31, 32 );

	CreateMultipleRobberies( "Bank",				ROBBERY_SAFE_PAY, 2165.008544, 1649.773925, 1041.061889, 90.000000, 45, 24, 25, 78 );
	CreateRobberyNPC( "Banker",						ROBBERY_BOT_PAY, 2157.9255,1647.9972,1041.6124,270.1911, 17, 45, 24, 25, 78 );

	CreateMultipleRobberies( "Pawnshop", 			ROBBERY_SAFE_PAY, 1331.349731, -1079.761108, 967.495605, -90.00000, 11, 22, 33 );
	CreateRobberyNPC( "Pawnbroker",					ROBBERY_BOT_PAY, 1330.7424,-1081.0117,968.0360,270.1916, 261, 11, 22, 33 );

	CreateMultipleRobberies( "Gas Station",      	ROBBERY_SAFE_PAY, -20.583150, -58.166736, 1002.99329, 180.00000, 28, 29, 49, 32, 33, 34, 20, 52, 56, 73, 92, 68, 74, 77 );
	CreateRobberyNPC( "Gas Cashier",				ROBBERY_BOT_PAY, -22.2767,-57.6385,1003.5469,354.5035, 7, 28, 29, 49, 32, 33, 34, 20, 52, 56, 73, 92, 68, 74, 77 );

	CreateMultipleRobberies( "Drug House", 			floatround( float( ROBBERY_SAFE_PAY ) * 1.5 ), 2201.009521, -1212.770874, 1048.462890, 0.0000000, 11, 26, 27, 94, 31, 44, 10, 15 );
	CreateRobberyNPC( "Triad Boss",					floatround( float( ROBBERY_BOT_PAY ) * 1.5 ), 2200.4556,-1218.9237,1049.0234,30.6198, 120, 11, 44, 27, 94 ); // TRIADS
	CreateRobberyNPC( "Mafia Boss",					floatround( float( ROBBERY_BOT_PAY ) * 1.5 ), 2200.4556,-1218.9237,1049.0234,30.6198, 272, 31, 26, 10, 15 ); // Mafia

	CreateRobberyNPC( "Militia Boss",					floatround( float( ROBBERY_BOT_PAY ) * 2.5 ), -2376.437011, 1554.111572, 2.117187, 180.000000, 127, -1 ); // Mafia
	CreateMultipleRobberies( "Militia Ship - Safe 1", 	floatround( float( ROBBERY_SAFE_PAY ) * 2.0 ), -2367.723388, 1554.588500, 1.567188, -60.8000000, -1 );
	CreateMultipleRobberies( "Militia Ship - Safe 2", 	floatround( float( ROBBERY_SAFE_PAY ) * 2.0 ), -2367.303466, 1553.833862, 2.517187, -60.8000000, -1 );

	CreateMultipleRobberies( "Film Studio", 		ROBBERY_SAFE_PAY, 2327.151123, 914.138305, 1056.10510, -90.00000, -1 ); // custom obj
	CreateMultipleRobberies( "Grotti Cars", 		ROBBERY_SAFE_PAY, 542.361816, -1303.610351, 16.725925, 180.00000, -1 );
	CreateMultipleRobberies( "Supa Save", 			ROBBERY_SAFE_PAY, -2396.877929, 769.194396, 1056.135864, 0.00000, -1 );
	CreateMultipleRobberies( "Driving School", 		ROBBERY_SAFE_PAY, -2036.206176, -116.898040, 1034.611328, 90.000000, -1 ); // needs mapping
	CreateMultipleRobberies( "Tattoo Parlour", 		ROBBERY_SAFE_PAY, -200.169479, -22.932298, 1001.712890, -90.00000, 22, 46, 42 ); // needs mapping
	CreateMultipleRobberies( "Gym", 				ROBBERY_SAFE_PAY, 755.036743, -18.894632, 1000.045532, 90.000000, 8 ); // needs mapping

	// LV
	CreateMultipleRobberies( "Bank of Las Venturas - Safe 1", 	ROBBERY_SAFE_PAY, 2105.442138, 1246.264648, 1016.50110, 0.00000, g_bankvaultData[ CITY_LV ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of Las Venturas - Safe 2", 	ROBBERY_SAFE_PAY, 2110.461425, 1246.264648, 1016.50110, 0.00000, g_bankvaultData[ CITY_LV ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of Las Venturas - Safe 3", 	ROBBERY_SAFE_PAY, 2108.793701, 1246.264648, 1017.41492, 0.00000, g_bankvaultData[ CITY_LV ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of Las Venturas - Safe 4", 	ROBBERY_SAFE_PAY, 2107.122802, 1246.264648, 1017.41492, 0.00000, g_bankvaultData[ CITY_LV ] [ E_WORLD ] );
	CreateMultipleRobberies( "Caligulas Casino - Safe 1", 	  	ROBBERY_SAFE_PAY, 2143.757568, 1642.740478, 993.93701, 0.0, -1 );
	CreateMultipleRobberies( "Caligulas Casino - Safe 2", 	  	ROBBERY_SAFE_PAY, 2145.476562, 1642.832275, 993.02612, 0.0, -1 );
	CreateMultipleRobberies( "4 Dragons Casino", 				ROBBERY_SAFE_PAY * 2, 1953.887329, 1018.131591, 991.9517800, -90.00000, -1 );
	CreateMultipleRobberies( "Gym", 							ROBBERY_SAFE_PAY, 760.740173, -78.840095, 1000.094909, 180.00000, 9 );

	CreateMultipleRobberies( "Bank of Los Santos - Safe 1", ROBBERY_SAFE_PAY, 2105.442138, 1246.264648, 1016.50110, 0.00000, g_bankvaultData[ CITY_LS ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of Los Santos - Safe 2", ROBBERY_SAFE_PAY, 2110.461425, 1246.264648, 1016.50110, 0.00000, g_bankvaultData[ CITY_LS ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of Los Santos - Safe 3", ROBBERY_SAFE_PAY, 2108.793701, 1246.264648, 1017.41492, 0.00000, g_bankvaultData[ CITY_LS ] [ E_WORLD ] );
	CreateMultipleRobberies( "Bank of Los Santos - Safe 4", ROBBERY_SAFE_PAY, 2107.122802, 1246.264648, 1017.41492, 0.00000, g_bankvaultData[ CITY_LS ] [ E_WORLD ] );
	CreateMultipleRobberies( "Gym", 						ROBBERY_SAFE_PAY, 755.438659, 7.457976, 1000.139587, 90.00000, 10 );

	printf( "[ROBBERIES]: %d safe robberies have been successfully loaded.", Iter_Count( RobberyCount ) );
	return 1;
}
