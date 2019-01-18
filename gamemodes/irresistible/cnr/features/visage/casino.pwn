/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: casino.inc
 * Purpose:	related to implementing the casino of visage
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Constants ** */
stock VISAGE_ENTRANCE = ITER_NONE;
stock const VISAGE_INTERIOR = 15;
stock const VISAGE_WORLD = 79;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	// Initialize Interior
	InitializeCasinoInterior( );

	// Create Entrance
	VISAGE_ENTRANCE = CreateEntrance( "[VISAGE CASINO]", 2017.1334, 1916.4141, 12.3424, 2633.7986, 1714.6560, 1512.4630, VISAGE_INTERIOR, VISAGE_WORLD, true, false, 44 );

	// Create Poker Tables
	CreatePokerTable( 25000000, 250000, 2584.122070, 1593.588012, 1505.522949, 6, VISAGE_WORLD, VISAGE_INTERIOR ); // super high roller
	CreatePokerTable( 10000000, 100000, 2566.893066, 1616.395019, 1505.532958, 4, VISAGE_WORLD, VISAGE_INTERIOR ); // highroller
	CreatePokerTable( 7500000, 75000, 2566.893066, 1609.832031, 1505.532958, 4, VISAGE_WORLD, VISAGE_INTERIOR ); // highroller
	CreatePokerTable( 5000000, 50000, 2572.893066, 1609.832031, 1505.532958, 4, VISAGE_WORLD, VISAGE_INTERIOR ); // highroller
	CreatePokerTable( 2500000, 25000, 2572.893066, 1616.395019, 1505.532958, 4, VISAGE_WORLD, VISAGE_INTERIOR ); // highroller
	CreatePokerTable( 1000000, 10000, 2619.504882, 1591.672973, 1505.548950, 6, VISAGE_WORLD, VISAGE_INTERIOR );
	CreatePokerTable( 500000, 5000, 2619.504882, 1597.672973, 1505.548950, 6, VISAGE_WORLD, VISAGE_INTERIOR );
	CreatePokerTable( 250000, 2500, 2619.504882, 1603.672973, 1505.548950, 6, VISAGE_WORLD, VISAGE_INTERIOR );
	CreatePokerTable( 100000, 1000, 2619.504882, 1609.672973, 1505.548950, 6, VISAGE_WORLD, VISAGE_INTERIOR );
	CreatePokerTable( 50000, 500, 2619.504882, 1615.672973, 1505.548950, 6, VISAGE_WORLD, VISAGE_INTERIOR );

	// Robbery Info
	CreateRobberyNPC( "Visage Cashier", 2500, 2601.9226, 1567.5959, 1508.3521, 0.0, 11, VISAGE_WORLD ); // Mafia
	CreateRobberyNPC( "Visage Cashier",	2500, 2607.0059, 1567.5959, 1508.3521, 0.0, 172, VISAGE_WORLD ); // Mafia
	CreateRobberyCheckpoint( "Visage Casino - Safe 1", 	4000, 2609.208984, 1566.640014, 1507.802001, -90.00000, VISAGE_WORLD );
	CreateRobberyCheckpoint( "Visage Casino - Safe 2", 	4000, 2609.208984, 1565.798950, 1507.802001, -90.00000, VISAGE_WORLD );

	// Create ATM
	CreateATM( 2557.137939, 1576.037963, 1508.003051, -90.000000 );
	CreateATM( 2630.107177, 1647.757324, 1507.968750, -90.000000 );
	CreateATM( 2641.666992, 1649.718994, 1507.968750, 90.0000000 );

	// Create Roulette Tables
	CreateRouletteTable( 2641.445068, 1619.609008, 1506.227050, 90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2641.445068, 1614.555053, 1506.227050, -90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2630.570068, 1619.656005, 1506.227050, 90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2630.570068, 1589.187988, 1506.227050, -90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2630.520996, 1614.555053, 1506.227050, -90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2641.366943, 1589.187988, 1506.227050, -90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2641.366943, 1594.758056, 1506.227050, -90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2630.566894, 1594.758056, 1506.227050, -90.000000, VISAGE_WORLD, .maxbet = 250000 );
	CreateRouletteTable( 2579.751953, 1610.387939, 1506.203002, -90.000000, VISAGE_WORLD, .maxbet = 1000000 ); // high roller
	CreateRouletteTable( 2579.751953, 1615.537963, 1506.203002, -90.000000, VISAGE_WORLD, .maxbet = 1000000 ); // high roller

	// Create Blackjack Tables
	CreateBlackjackTable( 2500000, 2607.080078, 1604.453002, 1506.156005, -90.0000, VISAGE_WORLD );
	CreateBlackjackTable( 1000000, 2608.962890, 1602.750000, 1506.156005, 0.000000, VISAGE_WORLD );
	CreateBlackjackTable( 750000,  2610.774902, 1604.437988, 1506.156005, 90.00000, VISAGE_WORLD );
	CreateBlackjackTable( 500000,  2608.962890, 1606.272949, 1506.156005, 180.0000, VISAGE_WORLD );

	CreateBlackjackTable( 250000, 2632.187988, 1604.437988, 1506.156005, 90.0000, VISAGE_WORLD );
	CreateBlackjackTable( 100000, 2628.491943, 1604.453002, 1506.156005, -90.000, VISAGE_WORLD );
	CreateBlackjackTable( 50000,  2630.375000, 1602.750000, 1506.156005, 0.00000, VISAGE_WORLD );
	CreateBlackjackTable( 25000,  2630.375000, 1606.272949, 1506.156005, 180.000, VISAGE_WORLD );

	CreateBlackjackTable( 25000000, 2569.475097, 1600.437988, 1506.15600, 90.0000, VISAGE_WORLD ); // high roller
	CreateBlackjackTable( 15000000, 2567.663085, 1602.272949, 1506.15600, 180.000, VISAGE_WORLD ); // high roller
	CreateBlackjackTable( 10000000, 2565.780029, 1600.453002, 1506.15600, -90.000, VISAGE_WORLD ); // high roller
	CreateBlackjackTable( 5000000, 2567.663085, 1598.750000, 1506.15600, 0.000000, VISAGE_WORLD ); // high roller
	return 1;
}

hook OnPlayerConnect( playerid )
{
	// Remove Visage Building
	RemoveBuildingForPlayer( playerid, 7584, 1947.3828, 1916.1953, 78.1953, 0.25 );
	RemoveBuildingForPlayer( playerid, 7716, 1947.3828, 1916.1953, 78.1953, 0.25 );
	return 1;
}

// purpose: creates the interior itself
static stock InitializeCasinoInterior( )
{
	// Remake
	tmpVariable = CreateDynamicObject( 14624, 2585.871093, 1609.286010, 1511.188964, 0.000000, 0.000000, 180.000000, .streamdistance = -1.0, .priority = 9999 );
	SetDynamicObjectMaterial( tmpVariable, 15, 8396, "sphinx01", "luxorwall02_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 9, 11471, "des_wtownmain", "orange2", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 8396, "sphinx01", "luxorceiling01_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 8396, "sphinx01", "luxormural01_256", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 8396, "sphinx01", "luxorceiling01_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 12, 14627, "ab_optilite", "ab_optilite", 0 );
	SetDynamicObjectMaterial( tmpVariable, 10, 8396, "sphinx01", "luxormural01_256", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 8396, "sphinx01", "luxorledge02_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 11, 5392, "eastshops1_lae", "blueshop2_LAe", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 2619.851074, 1570.769042, 1509.729980, 0.000000, 0.000000, -36.799999, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling01_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 2619.667968, 1636.426025, 1509.729980, 0.000000, 0.000000, -36.799999, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling01_128", -16 );
	tmpVariable = CreateDynamicObject( 14623, 2635.883056, 1677.000000, 1512.906005, 0.000000, 0.000000, 0.000000, .streamdistance = -1.0, .priority = 9999 );
	SetDynamicObjectMaterial( tmpVariable, 0, 8396, "sphinx01", "luxormural01_256", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 10412, "hotel1", "gold128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 5392, "eastshops1_lae", "blueshop2_LAe", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 8396, "sphinx01", "luxorceiling01_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 5, 8396, "sphinx01", "luxorwall02_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 8396, "sphinx01", "luxorceiling01_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 7, 8396, "sphinx01", "luxormural01_256", 0 );
	SetDynamicObjectMaterial( tmpVariable, 8, 5392, "eastshops1_lae", "blueshop2_LAe", 0 );
	SetDynamicObjectMaterial( tmpVariable, 9, 11471, "des_wtownmain", "orange2", 0 );
	SetDynamicObjectMaterial( tmpVariable, 10, 8396, "sphinx01", "casinodoor1_128", 0 );
	tmpVariable = CreateDynamicObject( 14624, 2653.422119, 1597.921997, 1511.194946, 0.000000, 0.000000, 0.000000, .streamdistance = -1.0, .priority = 9999 );
	SetDynamicObjectMaterial( tmpVariable, 15, 8396, "sphinx01", "luxorwall02_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 9, 11471, "des_wtownmain", "orange2", 0 );
	SetDynamicObjectMaterial( tmpVariable, 3, 8396, "sphinx01", "luxorceiling01_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 6, 8396, "sphinx01", "luxormural01_256", 0 );
	SetDynamicObjectMaterial( tmpVariable, 4, 8396, "sphinx01", "luxorceiling01_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 12, 14627, "ab_optilite", "ab_optilite", 0 );
	SetDynamicObjectMaterial( tmpVariable, 10, 8396, "sphinx01", "luxormural01_256", 0 );
	SetDynamicObjectMaterial( tmpVariable, 1, 8396, "sphinx01", "luxorledge02_128", 0 );
	SetDynamicObjectMaterial( tmpVariable, 11, 5392, "eastshops1_lae", "blueshop2_LAe", 0 );
	CreateDynamicObject( 19943, 2616.636962, 1632.371948, 1507.371948, 0.000000, 0.000000, -19.899999, -1, -1, -1 );
	CreateDynamicObject( 19943, 2622.750976, 1574.579956, 1507.371948, 0.000000, 0.000000, -19.899999, -1, -1, -1 );

	// Main Visage Object
	CreateDynamicObject( 7584, 1947.38281, 1916.19531, 78.19531, 0.00000, 0.00000, 0.00000, 0, 0, -1, 500.0, .priority = 1 ); // visible to 500m in world & interior 0

	// The Visage Casino
	CreateDynamicObject( 14629, 2608.823974, 1611.375000, 1516.180053, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 14629, 2641.272949, 1611.375000, 1516.180053, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.947021, 1588.024047, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.947021, 1594.024047, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.947021, 1619.036987, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.947021, 1613.036987, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.906982, 1618.505004, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.906982, 1612.501953, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.967041, 1594.543945, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2597.967041, 1588.552978, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1588.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.822998, 1588.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1588.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.822998, 1588.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1594.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.822998, 1594.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.822998, 1594.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1594.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1612.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.792968, 1612.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.822998, 1613.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1613.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.822998, 1619.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2596.792968, 1618.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1618.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2599.084960, 1619.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.907958, 1618.505004, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.947998, 1613.036987, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.907958, 1612.501953, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.968017, 1594.543945, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.947998, 1594.024047, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.968017, 1588.552978, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.947998, 1588.024047, 1506.064941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.823974, 1588.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.823974, 1588.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1588.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1588.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.823974, 1594.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1594.015014, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1594.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.823974, 1594.546020, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.793945, 1612.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1612.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1613.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.823974, 1613.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1618.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.793945, 1618.485961, 1505.949951, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2607.823974, 1619.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2610.085937, 1619.036010, 1505.949951, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2608.936035, 1619.036987, 1506.064941, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 14781, 2654.885986, 1613.157958, 1506.269042, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2178, 2607.093994, 1631.635986, 1514.284057, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2178, 2607.093994, 1641.125976, 1514.284057, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2178, 2589.506103, 1641.125976, 1514.284057, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2178, 2569.264892, 1641.125976, 1514.284057, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2178, 2581.614013, 1629.635986, 1514.284057, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2178, 2562.874023, 1629.635986, 1514.284057, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2592.503906, 1533.038940, 1507.862060, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 17925, "lae2fake_int", "carpet1kb", 1 );
	CreateDynamicObject( 2773, 2592.842041, 1575.723999, 1507.862060, 0.000000, 0.000000, 13.899999, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2592.366943, 1584.285034, 1507.883056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 17925, "lae2fake_int", "carpet1kb", 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19545, 2592.544921, 1651.203002, 1508.353027, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 19545, "none", "none", 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19545, 2592.544921, 1556.972045, 1508.353027, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 19545, "none", "none", 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 2643.944091, 1703.369995, 1507.555053, 0.000000, 73.300003, 90.000000, -1, -1, -1 ), 0, 18981, "none", "none", 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19355, 2637.814941, 1715.092041, 1513.130981, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "casinodoor1_128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19355, 2633.930908, 1715.092041, 1513.130981, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "casinodoor1_128", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 2582.822998, 1592.265014, 1505.086059, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 17946, "carter_mainmap", "mp_carter_carpet", -5085441 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 2582.822998, 1594.847045, 1505.088012, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 17946, "carter_mainmap", "mp_carter_carpet", -5085441 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 2585.344970, 1594.847045, 1505.089965, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 17946, "carter_mainmap", "mp_carter_carpet", -5085441 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2577.787109, 1598.427978, 1505.682983, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2578.768066, 1599.379028, 1505.685058, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2589.430908, 1599.379028, 1505.685058, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2590.368896, 1598.427978, 1505.682983, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2577.787109, 1588.615966, 1505.682983, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2578.768066, 1587.656005, 1505.685058, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2589.430908, 1587.636962, 1505.685058, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2590.368896, 1588.607055, 1505.682983, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2590.368896, 1593.607055, 1505.682983, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2577.787109, 1593.427978, 1505.682983, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2584.268066, 1587.656005, 1505.685058, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	SetDynamicObjectMaterial( CreateDynamicObject( 2773, 2584.268066, 1599.379028, 1505.685058, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 1, 1246, "icons", "bluepink64", -7114533 );
	CreateDynamicObject( 2773, 2592.483886, 1578.048950, 1507.862060, 0.000000, 0.000000, 3.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2659.613037, 1613.500000, 1512.177978, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 14790, "ab_sfgymbits02", "sign_cobra1", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19325, 2650.922119, 1613.500000, 1512.177978, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 14790, "ab_sfgymbits02", "sign_cobra2", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 2628.562988, 1703.369995, 1507.555053, 0.000000, 73.300003, 90.000000, -1, -1, -1 ), 0, 18981, "none", "none", 1 );
	CreateDynamicObject( 2631, 2660.205078, 1613.541015, 1505.204956, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 2632, 2650.537109, 1613.541015, 1505.204956, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19296, 2666.011962, 1611.083984, 1502.369018, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 2610.041992, 1556.404052, 1508.353027, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling01_128", -272 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 2596.769042, 1556.404052, 1508.353027, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling01_128", -272 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 2605.837890, 1556.404052, 1506.852050, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 9583, "bigshap_sfw", "shipfloor_sfw", 0 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 2608.409912, 1564.261962, 1508.353027, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling01_128", -272 );
	SetDynamicObjectMaterial( CreateDynamicObject( 1491, 2597.252929, 1568.845947, 1507.251953, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "sphinxface01_256", -17895696 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, 2611.272949, 1568.446044, 1495.880004, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	CreateDynamicObject( 18981, 2605.837890, 1556.404052, 1511.735961, 0.000000, 90.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 2599.268066, 1568.437011, 1511.864990, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 2604.351074, 1568.437011, 1511.868041, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2594.665039, 1568.430053, 1512.244995, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18766, 2603.559082, 1568.430053, 1513.206054, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 2609.051025, 1568.437011, 1511.868041, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorceiling02_128", -16 );
	CreateDynamicObject( 19325, 2601.820068, 1568.655029, 1512.125000, 90.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19325, 2606.832031, 1568.655029, 1512.125000, 90.000000, 0.000000, 90.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2603.422119, 1570.913940, 1514.991943, 0.000000, 0.000000, 180.000000, -1, -1, -1 ), 0, "CASHIER", 120, "Times new roman", 90, 0, -16777216, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2635.801025, 1596.386962, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2635.801025, 1611.828002, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2625.069091, 1597.338012, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2625.069091, 1610.979980, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2646.562011, 1597.338012, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2646.562011, 1611.020019, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2614.230957, 1609.928955, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2614.230957, 1596.177001, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2603.469970, 1610.910034, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2603.469970, 1595.338012, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2592.728027, 1609.909057, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 3494, 2592.728027, 1596.177001, 1508.508056, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	CreateDynamicObject( 14401, 2650.637939, 1633.600952, 1505.448974, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 14401, 2643.084960, 1633.600952, 1505.448974, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 11745, 2661.160888, 1619.322021, 1505.905029, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 19570, 2660.962890, 1618.885009, 1505.185058, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 11738, 2661.849121, 1618.259033, 1505.208007, 0.000000, 0.000000, -75.400001, -1, -1, -1 );
	CreateDynamicObject( 2146, 2662.477050, 1617.947998, 1504.774047, 0.000000, 0.000000, 9.199999, -1, -1, -1 );
	CreateDynamicObject( 11686, 2651.860107, 1592.458007, 1505.177978, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 11686, 2654.659912, 1590.366943, 1505.180053, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 11686, 2659.459960, 1590.366943, 1505.180053, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 11686, 2666.550048, 1590.366943, 1505.180053, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 11686, 2673.393066, 1590.366943, 1505.180053, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2653.123046, 1593.989990, 1505.538940, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2652.874023, 1591.967041, 1505.538940, 0.000000, 0.000000, -47.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2654.705078, 1591.380004, 1505.538940, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2660.539062, 1591.630004, 1505.538940, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2657.697998, 1591.380004, 1505.538940, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2666.215087, 1591.380004, 1505.538940, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2674.815917, 1591.380004, 1505.538940, 0.000000, 0.000000, -63.000000, -1, -1, -1 );
	CreateDynamicObject( 2350, 2672.812011, 1591.629028, 1505.538940, 0.000000, 0.000000, -97.099998, -1, -1, -1 );
	CreateDynamicObject( 2802, 2656.145019, 1596.262939, 1505.519042, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2802, 2661.053955, 1597.682983, 1505.519042, 0.000000, 0.000000, -53.799999, -1, -1, -1 );
	CreateDynamicObject( 2802, 2667.053955, 1597.682983, 1505.519042, 0.000000, 0.000000, -40.599998, -1, -1, -1 );
	CreateDynamicObject( 2802, 2673.019042, 1599.197998, 1505.519042, 0.000000, 0.000000, -41.000000, -1, -1, -1 );
	CreateDynamicObject( 2802, 2670.091064, 1603.635009, 1505.519042, 0.000000, 0.000000, -41.000000, -1, -1, -1 );
	CreateDynamicObject( 2802, 2673.802001, 1606.734985, 1505.519042, 0.000000, 0.000000, 45.700000, -1, -1, -1 );
	CreateDynamicObject( 2802, 2669.802001, 1610.029052, 1505.519042, 0.000000, 0.000000, -28.299999, -1, -1, -1 );
	CreateDynamicObject( 2802, 2652.606933, 1599.161010, 1505.519042, 0.000000, 0.000000, 95.599998, -1, -1, -1 );
	CreateDynamicObject( 70, 2663.035888, 1604.270019, 1506.186035, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 70, 2666.500976, 1609.708984, 1506.178955, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2587.272949, 1609.031005, 1506.060058, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2586.184082, 1609.041015, 1505.953002, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2587.072998, 1615.592041, 1506.060058, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2587.302978, 1609.562011, 1506.060058, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 2592, 2587.603027, 1615.562011, 1506.060058, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2588.364990, 1609.041015, 1505.953002, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2586.184082, 1609.572021, 1505.953002, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2588.364990, 1609.572021, 1505.953002, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2587.604980, 1614.480957, 1505.953002, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2587.604980, 1616.722045, 1505.953002, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2587.094970, 1616.722045, 1505.953002, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 1835, 2587.094970, 1614.490966, 1505.953002, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
	CreateDynamicObject( 19298, 2583.156005, 1594.552001, 1532.812011, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19377, 2585.344970, 1592.265014, 1505.093994, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 17946, "carter_mainmap", "mp_carter_carpet", -5085441 );
	CreateDynamicObject( 14622, 2635.897949, 1703.796997, 1514.906005, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	CreateDynamicObject( 14609, 2621.529052, 1663.767944, 1509.097045, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2635.923095, 1689.045043, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2642.896972, 1686.762939, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2647.228027, 1680.802978, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2647.228027, 1673.421997, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2642.866943, 1667.463012, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2635.864990, 1665.243041, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2628.851074, 1667.494018, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2624.514892, 1673.480957, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2624.554931, 1680.853027, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 3498, 2628.885009, 1686.802978, 1509.530029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19789, 2609.051025, 1568.437011, 1508.366943, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxormural01_256", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19789, 2604.351074, 1568.437011, 1508.366943, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxormural01_256", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19789, 2599.270996, 1568.437011, 1508.366943, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxormural01_256", -16 );
	CreateDynamicObject( 14781, 2654.887939, 1614.062011, 1508.817993, 180.000000, 0.000000, 0.000000, -1, -1, -1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2639.329101, 1666.673950, 1514.469970, 0.000000, 0.000000, -162.100006, -1, -1, -1 ), 0, "Banging7grams", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2639.329101, 1666.673950, 1513.869995, 0.000000, 0.000000, -162.100006, -1, -1, -1 ), 0, "Shini", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2639.329101, 1666.673950, 1513.270019, 0.000000, 0.000000, -162.100006, -1, -1, -1 ), 0, "Daniel", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2639.329101, 1666.673950, 1512.670043, 0.000000, 0.000000, -162.100006, -1, -1, -1 ), 0, "Bradyy", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2632.508056, 1666.668945, 1514.469970, 0.000000, 0.000000, 162.000000, -1, -1, -1 ), 0, "Brad", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2632.508056, 1666.668945, 1513.869995, 0.000000, 0.000000, 162.000000, -1, -1, -1 ), 0, "RoyceGate", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2632.508056, 1666.668945, 1513.270019, 0.000000, 0.000000, 162.000000, -1, -1, -1 ), 0, "Ashley", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2632.508056, 1666.668945, 1512.670043, 0.000000, 0.000000, 162.000000, -1, -1, -1 ), 0, "[TDK]Future[NG]", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2644.941894, 1670.793945, 1514.469970, 0.000000, 0.000000, -126.099998, -1, -1, -1 ), 0, "Harpreet", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2644.941894, 1670.793945, 1513.869995, 0.000000, 0.000000, -126.099998, -1, -1, -1 ), 0, "Veloxity_", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2644.941894, 1670.793945, 1513.270019, 0.000000, 0.000000, -126.099998, -1, -1, -1 ), 0, "[ZF]ImakeMYownCAKE", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2644.941894, 1670.793945, 1512.670043, 0.000000, 0.000000, -126.099998, -1, -1, -1 ), 0, "Minthy", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2646.933105, 1677.155029, 1514.469970, 0.000000, 0.000000, -89.900001, -1, -1, -1 ), 0, "Hariexy", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2646.933105, 1677.155029, 1513.869995, 0.000000, 0.000000, -89.900001, -1, -1, -1 ), 0, "StevenVerx", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2626.977050, 1670.654052, 1514.469970, 0.000000, 0.000000, 125.699996, -1, -1, -1 ), 0, "MrFreeze", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2626.977050, 1670.654052, 1513.869995, 0.000000, 0.000000, 125.699996, -1, -1, -1 ), 0, "Chickenwing", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2626.977050, 1670.654052, 1513.270019, 0.000000, 0.000000, 125.699996, -1, -1, -1 ), 0, "Nibble", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2626.977050, 1670.654052, 1512.670043, 0.000000, 0.000000, 125.699996, -1, -1, -1 ), 0, "[SS]Usaid", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2624.854980, 1677.182006, 1514.469970, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "NeXuS", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2624.854980, 1677.182006, 1513.869995, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "IM_HULK.", 130, "Times new roman", 50, 0, -9170, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject( 19861, 2592.583007, 1602.630004, 1511.784057, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, "HIGHROLLERS", 120, "Times new roman", 70, 1, -9170, 0, 1 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 2609.367919, 1567.556030, 1505.781982, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 18762, 2609.367919, 1564.864990, 1505.781982, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19940, 2609.099121, 1566.212036, 1508.271972, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	SetDynamicObjectMaterial( CreateDynamicObject( 19940, 2609.529052, 1566.202026, 1508.271972, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 8396, "sphinx01", "luxorwall02_128", -16 );
	CreateDynamicObject( 19324, 2630.107177, 1649.759155, 1507.968750, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
	CreateDynamicObject( 19324, 2641.666992, 1647.757324, 1507.968750, 0.000000, 0.000000, -90.000000, -1, -1, -1 );

	// Actors
	ApplyDynamicActorAnimation( CreateDynamicActor( 120, 2642.641357, 1635.053955, 1508.359985, -135.600051, .worldid =  VISAGE_WORLD ), "GANGS", "prtial_gngtlkA", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 185, 2610.070068, 1618.020019, 1506.199951, 0.000000, .worldid =  VISAGE_WORLD ), "CASINO", "slot_wait", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 222, 2607.510009, 1602.569946, 1506.130004, -105.300003, .worldid =  VISAGE_WORLD ), "CASINO", "cards_loop", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 235, 2629.224609, 1607.058349, 1506.229980, -122.199913, .worldid =  VISAGE_WORLD ), "CASINO", "cards_loop", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 234, 2640.699951, 1618.369995, 1506.089965, -36.900001, .worldid =  VISAGE_WORLD ), "CASINO", "roulette_lose", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 249, 2643.155517, 1634.143554, 1508.359985, -52.700000, .worldid =  VISAGE_WORLD ), "GANGS", "prtial_gngtlkE", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 126, 2596.780029, 1611.949951, 1506.199951, 0.000000, .worldid =  VISAGE_WORLD ), "CASINO", "slot_wait", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 43, 2599.030029, 1613.660034, 1506.180053, 180.000000, .worldid =  VISAGE_WORLD ), "CASINO", "slot_win_out", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 187, 2610.090087, 1593.510253, 1506.170043, 0.000000, .worldid =  VISAGE_WORLD ), "CASINO", "slot_wait", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 164, 2583.010009, 1599.790039, 1506.170043, 10.500000, .worldid =  VISAGE_WORLD ), "COP_AMBIENT", "Coplook_nod", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 163, 2585.560058, 1599.719970, 1506.170043, -23.799999, .worldid =  VISAGE_WORLD ), "COP_AMBIENT", "Coplook_nod", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 81, 2660.712158, 1617.158691, 1506.260131, 13.600008, .worldid =  VISAGE_WORLD ), "CRACK", "crckidle4", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 70, 2660.679931, 1617.500000, 1506.180053, -143.699996, .worldid =  VISAGE_WORLD ), "MEDIC", "CPR", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 172, 2654.689941, 1589.520019, 1506.180053, 0.000000, .worldid =  VISAGE_WORLD ), "bar", "Barserve_bottle", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 20, 2659.939941, 1590.989990, 1506.180053, 61.599998, .worldid =  VISAGE_WORLD ), "GANGS", "leanIDLE", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 295, 2580.530029, 1611.699951, 1506.170043, 180.000000, .worldid =  VISAGE_WORLD ), "GRAVEYARD", "mrnF_Loop", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 296, 2579.639892, 1616.989990, 1506.170043, 180.000000, .worldid =  VISAGE_WORLD ), "KISSING", "GF_StreetArgue_02", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 152, 2579.070068, 1616.910034, 1506.170043, -119.599998, .worldid =  VISAGE_WORLD ), "KISSING", "gift_get", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 237, 2580.229980, 1617.060058, 1506.170043, 114.000114, .worldid =  VISAGE_WORLD ), "KISSING", "gfwave2", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 164, 2593.780029, 1597.280029, 1506.170043, -53.099998, .worldid =  VISAGE_WORLD ), "COP_AMBIENT", "Coplook_nod", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 163, 2593.699951, 1609.119995, 1506.170043, -130.600006, .worldid =  VISAGE_WORLD ), "COP_AMBIENT", "Coplook_nod", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 147, 2607.714111, 1569.374145, 1508.349975, 167.800003, .worldid = VISAGE_WORLD ), "CASINO", "manwind", 4.1, 1, 1, 1, 1, 0 );
	ApplyDynamicActorAnimation( CreateDynamicActor( 40, 2659.269775, 1591.528442, 1506.180053, -122.499618, .worldid =  VISAGE_WORLD ), "GANGS", "invite_NO", 4.1, 1, 1, 1, 1, 0 );
}

stock IsPlayerInHighRoller( playerid )
{
	if ( ! IsPlayerInCasino( playerid ) ) return false;
	return IsPlayerInArea( playerid, 2545.383056, 2592.488037, 1569.796997, 1651.173950 );
}
