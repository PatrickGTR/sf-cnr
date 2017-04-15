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
	// Zach Garage
	SetDynamicObjectMaterialText(CreateDynamicObject(17072, -41.19690, -1113.12695, 4.62810, 0.00000, 0.00000, -24.00000), 3, " ", 140, "Arial", 64, 1, -32256, 0, 1);
	return 1;
}

CMD:cakeiscool( playerid, params[] )
{
	RemoveBuildingForPlayer(playerid, 9968, -1683.1406, 786.0938, 38.8203, 0.25);
	RemoveBuildingForPlayer(playerid, 10057, -1669.2188, 723.4688, 57.5469, 0.25);
	RemoveBuildingForPlayer(playerid, 10049, -1683.1406, 786.0938, 38.8203, 0.25);
	return 1;
}

CMD:warehouseshit(playerid, params[])
{
	RemoveBuildingForPlayer(playerid, 17350, -54.9922, -1130.7266, 4.5781, 0.25);
	RemoveBuildingForPlayer(playerid, 17072, -54.9922, -1130.7266, 4.5781, 0.25);
	RemoveBuildingForPlayer(playerid, 17073, -56.1250, -1130.1719, 4.4922, 0.25);
	RemoveBuildingForPlayer(playerid, 1415, -68.3516, -1104.9922, 0.2188, 0.25);
	RemoveBuildingForPlayer(playerid, 1462, -60.3594, -1116.9375, 0.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 1438, -63.6719, -1125.6953, 0.0469, 0.25);
	RemoveBuildingForPlayer(playerid, 1438, -63.4141, -1115.4141, 0.0469, 0.25);
	RemoveBuildingForPlayer(playerid, 1415, -63.8125, -1106.4219, 0.2188, 0.25);
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
