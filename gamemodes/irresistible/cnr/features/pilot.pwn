/*
	* Irresistible Gaming (c) 2018
	* Developed by Stev
	* Module: pilot.pwn
	* Purpose: Pilot mini-job
*/

#include <YSI\y_hooks>

// ** ENUMS

enum taskEnum
{
	taskName[64],
	Float:taskStart[3],
	Float:taskFinish[3],
	taskReward[2],
};

// ** VARIABLES

new bool:playerWorking[MAX_PLAYERS char] = false;
new playerTaskCheckpoint[MAX_PLAYERS];
new playerTaskMapIcon[MAX_PLAYERS];
new playerTaskProgress[MAX_PLAYERS];
new playerTask[MAX_PLAYERS];
new playerTaskDistance[MAX_PLAYERS char];

new playerPilotTasks[MAX_PLAYERS char]; // DATABASE FOR HIGHEST SCORE

new taskInfo[][taskEnum] =
{
	{"Weapons", {324.0082, 2501.9749, 17.2114}, {1773.6418, -2492.8054, 14.2744}, {2250, 6000}},
	{"Weapons", {324.0082, 2501.9749, 17.2114}, {-1452.0604, 40.2788, 14.8709}, {2000, 6000}},
	{"Passengers", {324.0082, 2501.9749, 17.2114}, {1478.1902, 1653.5984, 11.5396}, {2000, 6000}},
	{"Drugs", {1478.1902, 1653.5984, 11.5396}, {-1452.0604, 40.2788, 14.8709}, {2000, 6000}},
	{"Weapons", {1478.1902, 1653.5984, 11.5396}, {1773.6418, -2492.8054, 14.2744}, {2250, 6000}},
	{"Drinks", {1478.1902, 1653.5984, 11.5396}, {324.0082, 2501.9749, 17.2114}, {1500, 6000}},
	{"Passengers", {-1452.0604, 40.2788, 14.8709}, {1773.6418, -2492.8054, 14.2744}, {1500, 6000}},
	{"Passengers", {-1452.0604, 40.2788, 14.8709}, {324.0082, 2501.9749, 17.2114}, {2000, 6000}},
	{"Passengers", {-1452.0604, 40.2788, 14.8709}, {1478.1902, 1653.5984, 11.5396}, {2250, 6000}},
	{"Drugs", {1773.6418, -2492.8054, 14.2744}, {324.0082, 2501.9749, 17.2114}, {2000, 6000}},
	{"Ammo", {1773.6418, -2492.8054, 14.2744}, {-1452.0604, 40.2788, 14.8709}, {2000, 6000}},
	{"Food", {1773.6418, -2492.8054, 14.2744}, {1478.1902, 1653.5984, 11.5396}, {2250, 6000}}
};

// ** HOOKS

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
	if (newstate == PLAYER_STATE_DRIVER && IsPlayerInAnyVehicle(playerid))
	{
		new vehicleid = GetPlayerVehicleID(playerid);
		if (GetVehicleModel(vehicleid) == 519 && !playerWorking{playerid})
		{
			ShowPlayerHelpDialog(playerid, 3000, "You can begin a pilot job by typing ~g~/work");
		}
	}
}

hook OnPlayerExitVehicle(playerid, vehicleid)
{
	if (playerWorking{playerid} && playerTask[playerid] > 0)
	{
		SendServerMessage(playerid, "Your pilot mission has been stopped.");

		playerTask[playerid] = -1;
		playerTaskProgress[playerid] = 0;
		pTaskDistance{playerid} = 0;
		playerWorking{playerid} = false;

		DestroyDynamicRaceCP(playerTaskCheckpoint[playerid]);
		DestroyDynamicMapIcon(playerTaskMapIcon[playerid]);
	}
}

hook OnPlayerUpdate(playerid)
{
	UpdatePilotTask(playerid);
}

hook OnPlayerEnterDynamicRaceCP(playerid, checkpointid)
{
	if (playerWorking{playerid} && playerTask[playerid] > 0)
	{
		new index = playerTask[playerid];
		switch (playerTaskProgress[playerid])
		{
			case 0:
			{
				if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
					return SendError(playerid, "You must be the driver of the vehicle to continue this mission.");

				playerTaskProgress[playerid] ++;

				DestroyDynamicRaceCP(playerTaskCheckpoint[playerid]);
				DestroyDynamicMapIcon(playerTaskMapIcon[playerid]);

				playerTaskCheckpoint[playerid] = CreateDynamicRaceCP(1, taskInfo[index][taskFinish][0], taskInfo[index][taskFinish][2], taskInfo[index][taskFinish][2], 0.0, 0.0, 0.0, 5.0, 0, 0, playerid);
				playerTaskMapIcon[playerid] = CreateDynamicMapIcon(taskInfo[index][taskFinish][0], taskInfo[index][taskFinish][1], taskInfo[index][taskFinish][2], 5, -1, 0, 0, playerid);
			}
			case 1:
			{
				if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
					return SendError(playerid, "You must be the driver of the vehicle to complete this mission.");

				new reward = RandomEx(taskInfo[index][taskReward][0], taskInfo[index][taskReward][1]);

				ShowPlayerHelpDialog(playerid, 5000, "You have earned ~y~$%s ~w~for transporting %s!", taskInfo[index][taskName], number_format(reward));

				GivePlayerMoney(playerid, reward);
				// GIVE THE XP
				// GIVE THE SCORE ASWELL (IF YOU WANT)

				playerTask[playerid] = -1;
				playerTaskProgress[playerid] = 0;
				pTaskDistance{playerid} = 0;
				playerWorking{playerid} = false;

				DestroyDynamicRaceCP(playerTaskCheckpoint[playerid]);
				DestroyDynamicMapIcon(playerTaskMapIcon[playerid]);

				playerPilotTasks{playerid} ++;
			}
		}
	}
}

// ** COMMANDS

CMD:work(playerid, params[])
{
	if (playerWorking{playerid})
		return SendError(playerid, "You are already doing a task.");

	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
		return SendError(playerid, "You must be the driver of the vehicle to start a task.");

	if (GetVehicleModel(GetPlayerVehicleID(playerid)) != 519)
		return SendError(playerid, "There are currently no jobs for this particular vehicle.");

	new index = RandomEx(0, sizeof(taskInfo));

	playerTaskProgress[playerid] = 0;
	pTaskDistance{playerid} = 0;
	playerTask[playerid] = index;
	playerWorking{playerid} = true;

	ShowPlayerHelpDialog(playerid, 5000, "A ~g~air blip~w~ has been shown on your radar. Go to where the air blip is pick up the %s.", taskInfo[index][taskName]);

	playerTaskCheckpoint[playerid] = CreateDynamicRaceCP(1, taskInfo[index][taskStart][0], taskInfo[index][taskStart][1], taskInfo[index][taskStart][2], taskInfo[index][taskFinish][0], taskInfo[index][taskFinish][1], taskInfo[index][taskFinish][2], 5.0, 0, 0, playerid, 100.0);
	playerTaskMapIcon[playerid] = CreateDynamicMapIcon(taskInfo[index][taskStart][0], taskInfo[index][taskStart][1], taskInfo[index][taskStart][2], 5, -1, 0, 0, playerid);
	return 1;
}

// ** FUNCTIONS

ShowAirportLocation(Float:fX, Float:fY, Float:fZ)
{
	enum e_ZoneData
	{
     	e_ZoneName[32 char],
     	Float:e_ZoneArea[6]
	};
	new const g_arrZoneData[][e_ZoneData] =
	{
		{!"SF Airport",         {-1499.80, -50.00, -0.00, -1242.90, 249.90, 200.00}},
		{!"SF Airport",         {-1794.90, -730.10, -3.00, -1213.90, -50.00, 200.00}},
		{!"SF Airport",         {-1213.90, -730.10, 0.00, -1132.80, -50.00, 200.00}},
		{!"SF Airport",         {-1242.90, -50.00, 0.00, -1213.90, 578.30, 200.00}},
		{!"SF Airport",         {-1213.90, -50.00, -4.50, -947.90, 578.30, 200.00}},
		{!"SF Airport",         {-1315.40, -405.30, 15.40, -1264.40, -209.50, 25.40}},
		{!"SF Airport",         {-1354.30, -287.30, 15.40, -1315.40, -209.50, 25.40}},
		{!"SF Airport",         {-1490.30, -209.50, 15.40, -1264.40, -148.30, 25.40}},
		{!"LV Airport",         {1236.60, 1203.20, -89.00, 1457.30, 1883.10, 110.90}},
		{!"LV Airport",         {1457.30, 1203.20, -89.00, 1777.30, 1883.10, 110.90}},
		{!"LV Airport",         {1457.30, 1143.20, -89.00, 1777.40, 1203.20, 110.90}},
		{!"LV Airport",         {1515.80, 1586.40, -12.50, 1729.90, 1714.50, 87.50}},
		{!"LS Airport",     	{1249.60, -2394.30, -89.00, 1852.00, -2179.20, 110.90}},
		{!"LS Airport",     	{1852.00, -2394.30, -89.00, 2089.00, -2179.20, 110.90}},
		{!"LS Airport",     	{1382.70, -2730.80, -89.00, 2201.80, -2394.30, 110.90}},
		{!"LS Airport",     	{1974.60, -2394.30, -39.00, 2089.00, -2256.50, 60.90}},
		{!"LS Airport",     	{1400.90, -2669.20, -39.00, 2189.80, -2597.20, 60.90}},
		{!"LS Airport",     	{2051.60, -2597.20, -39.00, 2152.40, -2394.30, 60.90}},
		{!"Verdant Meadows",    {37.00, 2337.10, -3.00, 435.90, 2677.90, 200.00}}
	};
	new
	    szName[32] = "No-where";

	for (new i = 0; i != sizeof(g_arrZoneData); i ++) if ((fX >= g_arrZoneData[i][e_ZoneArea][0] && fX <= g_arrZoneData[i][e_ZoneArea][3]) && (fY >= g_arrZoneData[i][e_ZoneArea][1] && fY <= g_arrZoneData[i][e_ZoneArea][4]) && (fZ >= g_arrZoneData[i][e_ZoneArea][2] && fZ <= g_arrZoneData[i][e_ZoneArea][5])) {
		strunpack(szName, g_arrZoneData[i][e_ZoneName]);

		break;
	}

	return szName;
}

UpdatePilotTask(playerid)
{
	new index = playerTask[playerid];

	switch (playerTaskProgress[playerid])
	{
		case 0: pTaskDistance{playerid} = floatround(GetPlayerDistanceFromPoint(playerid, taskInfo[index][taskStart][0], taskInfo[index][taskStart][1], taskInfo[index][taskStart][2]));
		case 1: pTaskDistance{playerid} = floatround(GetPlayerDistanceFromPoint(playerid, taskInfo[index][taskFinish][0], taskInfo[index][taskFinish][1], taskInfo[index][taskFinish][2]));
	}

	format(szNormalString, sizeof(szNormalString), "~b~Location:~w~ %s~n~~b~Distance:~w~ %dm", (playerTaskProgress[playerid] == 1 ? (ShowAirportLocation(taskInfo[index][taskFinish][0], taskInfo[index][taskFinish][1], taskInfo[index][taskFinish][2])) : (ShowAirportLocation(taskInfo[index][taskStart][0], taskInfo[index][taskStart][1], taskInfo[index][taskStart][2]))), pTaskDistance{playerid});
	TextDrawSetString(p_TruckingTD[playerid], szNormalString);

	return 1;
}
