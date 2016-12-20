/*
 *	SF Custom Objects
 *
 *
*/

#include <a_samp>
#include <streamer>
#include <zcmd>

#define SetObjectInvisible(%0) 		SetDynamicObjectMaterialText(%0, 0, " ", 140, "Arial", 64, 1, -32256, 0, 1)
stock tmpVariable;

public OnFilterScriptInit()
{
	// Ignition.Von VIP LOUNGE ROOFTOP
	CreateDynamicObject( 1569, -1855.294067, 862.399230, 34.210491, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 1569, -1852.304077, 862.399230, 34.210491, 0.000000, 0.000000, 180.000000 );
	CreateDynamicObject( 3524, -1853.853149, 862.732971, 34.907802, 6.899999, 0.000000, 0.000000 );
	CreateDynamicObject( 1497, -1858.333862, 865.009277, 34.125236, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 3525, -1851.911132, 862.262207, 35.646312, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 3525, -1855.762329, 862.262207, 35.646312, 0.000000, 0.000000, 0.000000 );
	CreateDynamicObject( 638, -1860.264160, 864.414672, 34.878009, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3850, -1860.221435, 863.861816, 34.721279, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 3852, -1846.471069, 865.205017, 87.694641, 0.000000, 0.000000, 90.000000 );
	CreateDynamicObject( 9241, -1831.487426, 889.527526, 87.865295, 0.000000, 0.000000, 0.000000 );
	return 1;
}

CMD:dammenit(playerid, params[]) {
	RemoveBuildingForPlayer(playerid, 713, -1920.1875, 882.1953, 34.1406, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1990.3359, 866.3281, 45.2422, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1990.3359, 863.8750, 45.2422, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1980.9063, 866.9375, 46.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 673, -1963.9375, 877.9766, 40.7266, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1961.0625, 875.3984, 43.6797, 0.25);
	RemoveBuildingForPlayer(playerid, 715, -1956.3750, 877.7422, 49.0313, 0.25);
	RemoveBuildingForPlayer(playerid, 673, -1950.0547, 876.2578, 37.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1941.1875, 875.3984, 40.0469, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1928.0469, 875.3984, 37.0156, 0.25);
	RemoveBuildingForPlayer(playerid, 673, -1926.3750, 878.5234, 34.1484, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1913.0234, 868.8125, 36.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1913.0234, 864.8672, 36.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1913.0234, 870.9219, 36.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1961.0625, 892.7266, 43.6797, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1990.3359, 902.1250, 45.2422, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1990.3359, 904.5781, 45.2422, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1980.9063, 901.7031, 46.7813, 0.25);
	RemoveBuildingForPlayer(playerid, 673, -1956.5703, 886.2031, 40.7891, 0.25);
	RemoveBuildingForPlayer(playerid, 673, -1950.0547, 887.5234, 37.2500, 0.25);
	RemoveBuildingForPlayer(playerid, 673, -1927.5313, 888.5625, 34.1484, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1928.0469, 892.7266, 37.0156, 0.25);
	RemoveBuildingForPlayer(playerid, 1232, -1941.1875, 892.7266, 40.0469, 0.25);
	RemoveBuildingForPlayer(playerid, 1226, -1906.7188, 893.7422, 38.1484, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1913.0234, 894.1094, 36.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1913.0234, 904.5781, 36.4531, 0.25);
	RemoveBuildingForPlayer(playerid, 649, -1913.0234, 902.4688, 36.4531, 0.25);
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	return 1;
}
