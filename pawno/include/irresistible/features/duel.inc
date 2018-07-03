/*
	* Irresistible Gaming (c) 2018
	* Developed by Stev
	* Module: duel.pwn
	* Purpose: player dueling system
*/

/* ** Debug ** */

// Added class detection for civilains - ShowPlayerDuelMenu(playerid)


// #define GivePlayerCash			GivePlayerMoney
// #define GetPlayerCash			GetPlayerMoney

/* ** Definitions ** */
#define COL_DUEL 					"{B74AFF}"
#define DIALOG_DUEL 				7360
#define DIALOG_DUEL_PLAYER			7361
#define DIALOG_DUEL_LOCATION		7362
#define DIALOG_DUEL_WEAPON			7363
#define DIALOG_DUEL_WAGER			7364
#define DIALOG_DUEL_WEAPON_TWO 		7365
#define DIALOG_DUEL_HEALTH 			7366
#define DIALOG_DUEL_ARMOUR			7367

/* ** Variables ** */
enum duelData
{
	duelPlayer,
	duelWeapon[2],
	duelBet,
	Float: duelArmour,
	Float: duelHealth,
	duelCountdown,
	duelTimer,
	duelLocation,
	duelRemainingRounds
};

enum locationData
{
	locationName[19],
	Float:locationPosOne[3],
	Float:locationPosTwo[3],
};

static const Float: duel_coordinates[3] = {-2226.1938, 251.9206, 35.3203};

new
	weaponList 						[] = {0, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34},
	LocationInfo					[][locationData] =
	{
        {"Santa Maria Beach",		{369.75770, -1831.576, 7.67190}, {369.65890, -1871.215, 7.67190}},
        {"Greenglass College",		{1078.0353, 1084.4989, 10.8359}, {1095.4019, 1064.7239, 10.8359}},
        {"Baseball Arena",			{1393.0995, 2177.4585, 9.75780}, {1377.7881, 2195.4214, 9.75780}},
        {"The Visage",				{1960.4512, 1907.6881, 130.937}, {1969.4047, 1923.2622, 130.937}},
        {" Mount Chilliad",			{-2318.471, -1632.880, 483.703}, {-2329.174, -1604.657, 483.760}},
        {"The Farm",				{-1044.856, -996.8120, 129.218}, {-1125.599, -996.7523, 129.218}},
        {"Tennis Courts",			{755.93790, -1280.710, 13.5565}, {755.93960, -1238.688, 13.5516}},
        {"Underwater World",		{520.59600, -2125.663, -28.257}, {517.96600, -2093.610, -28.257}},
        {"Grove Street",			{2476.4580, -1668.631, 13.3249}, {2501.1560, -1667.655, 13.3559}},
        {"Ocean Docks",				{2683.5440, -2485.137, 13.5425}, {2683.8470, -2433.726, 13.5553}}
	},
	duelInfo 						[MAX_PLAYERS][duelData],

	bool: p_playerDueling			[MAX_PLAYERS char],
	p_duelInvitation           		[MAX_PLAYERS][MAX_PLAYERS],

	g_DuelCheckpoint				= -1
;

/* ** Hooks ** */
hook OnGameModeInit()
{
	CreateDynamicMapIcon(duel_coordinates[0], duel_coordinates[1], duel_coordinates[2], 23, 0, -1, -1, -1, 750.0);
	g_DuelCheckpoint = CreateDynamicCP(duel_coordinates[0], duel_coordinates[1], duel_coordinates[2], 1.5, 0, 0, -1);
	CreateDynamic3DTextLabel(""COL_GOLD"[DUEL PLAYER]", -1, duel_coordinates[0], duel_coordinates[1], duel_coordinates[2], 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1);
	return 1;
}

hook OnPlayerConnect(playerid)
{
	p_playerDueling{playerid} = false;
	duelInfo[playerid][duelPlayer] = INVALID_PLAYER_ID;
	duelInfo[playerid][duelWeapon][0] = 0;
	duelInfo[playerid][duelWeapon][1] = 0;
	duelInfo[playerid][duelHealth] = 100.0;
	duelInfo[playerid][duelArmour] = 100.0;
	duelInfo[playerid][duelBet] = 0;
	return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
	forfeitPlayerDuel(playerid);
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx(playerid, killerid, reason, Float: damage, bodypart)
#else
hook OnPlayerDeath(playerid, killerid, reason)
#endif
{
	forfeitPlayerDuel(playerid);
	return 1;
}

hook SetPlayerRandomSpawn(playerid)
{
	if (IsPlayerDueling(playerid))
	{
		// teleport back to pb
		SetPlayerPos(playerid, duel_coordinates[0], duel_coordinates[1], duel_coordinates[2]);
		SetPlayerInterior(playerid, 0);
		SetPlayerVirtualWorld(playerid, 0);

		// reset duel variables
		p_playerDueling{playerid} = false;
		duelInfo[playerid][duelPlayer] = INVALID_PLAYER_ID;
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnPlayerEnterDynamicCP(playerid, checkpointid)
{
	if (checkpointid == g_DuelCheckpoint)
	{
		ShowPlayerDuelMenu(playerid);
		return 1;
	}
	return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if (dialogid == DIALOG_DUEL && response)
	{
		switch (listitem)
		{
			case 0: ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{C0C0C0}Note: You can enter partially their names.", "Select", "Back");

			case 1: ShowPlayerDialog(playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Health", "{FFFFFF}Enter the amount of health you will begin with:\n\n{C0C0C0}Note: The default health is 100.0.", "Select", "Back");

			case 2: ShowPlayerDialog(playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Armour", "{FFFFFF}Enter the amount of armour you will begin with:\n\n{C0C0C0}Note: The default armour is 100.0.", "Select", "Back");

			case 3:
			{
				new weaponid = duelInfo[playerid][duelWeapon][0];

				erase(szBigString);

				for (new i = 0; i < sizeof(weaponList); i ++) {
					format(szBigString, sizeof(szBigString), "%s%s%s\n", szBigString, (weaponid == weaponList[i] ? (COL_GREY) : (COL_WHITE)), ReturnWeaponName(weaponList[i]));
				}

				ShowPlayerDialog(playerid, DIALOG_DUEL_WEAPON, DIALOG_STYLE_LIST, "{FFFFFF}Duel Settings - Change Primary Weapon", szBigString, "Select", "Back");
			}

			case 4:
			{
				new weaponid = duelInfo[playerid][duelWeapon][1];

				erase(szBigString);

				for (new i = 0; i < sizeof(weaponList); i ++) {
					format(szBigString, sizeof(szBigString), "%s%s%s\n", szBigString, (weaponid == weaponList[i] ? (COL_GREY) : (COL_WHITE)), ReturnWeaponName(weaponList[i]));
				}

				ShowPlayerDialog(playerid, DIALOG_DUEL_WEAPON_TWO, DIALOG_STYLE_LIST, "{FFFFFF}Duel Settings - Change Secondary Weapon", szBigString, "Select", "Back");
			}

			case 5:
			{
				new index = duelInfo[playerid][duelLocation];

				erase(szBigString);

				for (new i = 0; i < sizeof(LocationInfo); i ++) {
					format(szBigString, sizeof(szBigString), "%s%s%s\n", szBigString, (index == i ? (COL_GREY) : (COL_WHITE)), LocationInfo[i][locationName]);
				}

				ShowPlayerDialog(playerid, DIALOG_DUEL_LOCATION, DIALOG_STYLE_LIST, "{FFFFFF}Duel Settings - Change Location", szBigString, "Select", "Back");
			}

			case 6: ShowPlayerDialog(playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Set A Wager", "{FFFFFF}Please enter the wager for this duel:", "Select", "Back");

			case 7:
			{
				new targetid = duelInfo[playerid][duelPlayer];

				if (!IsPlayerConnected(targetid)) {
					SendError(playerid, "You haven't selected anyone to duel!");
					return ShowPlayerDuelMenu(playerid);
				}

				p_duelInvitation[playerid][targetid] = gettime() + 60;
				ShowPlayerHelpDialog(targetid, 10000, "%s wants to duel!~n~~n~~y~Location: ~w~%s~n~~y~Weapon: ~w~%s and %s~n~~y~Wager: ~w~%s", ReturnPlayerName(playerid), LocationInfo[duelInfo[playerid][duelLocation]][locationName], ReturnWeaponName(duelInfo[playerid][duelWeapon][0]), ReturnWeaponName(duelInfo[playerid][duelWeapon][1]), number_format(duelInfo[playerid][duelBet]));
				SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have sent a duel invitation to %s for "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName(targetid), number_format(duelInfo[playerid][duelBet]));
				SendClientMessageFormatted(targetid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You are invited to duel %s for "COL_GOLD"%s"COL_WHITE", use \"/duel accept %d\".", ReturnPlayerName(playerid), number_format(duelInfo[playerid][duelBet]), playerid);
			}
		}
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_PLAYER)
	{
		if (!response)
			return ShowPlayerDuelMenu(playerid);

		new targetid;

		if (sscanf(inputtext, "u", targetid))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{C0C0C0}Note: You can enter partially their names.", "Select", "Back");

		if (targetid == playerid)
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{FF0000}You can't invite yourself to duel!", "Select", "Back");

		if (targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{FF0000}Player is not connected!", "Select", "Back");

		if (IsPlayerDueling(playerid))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{FF0000}You are already in a duel!", "Select", "Back");

		if (IsPlayerDueling(targetid))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{FF0000}This player is already in a duel!", "Select", "Back");

		if (GetPlayerWantedLevel(targetid))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{FF0000}You can't duel this person right now, they are wanted", "Select", "Back");

		if (GetDistanceBetweenPlayers(playerid, targetid) > 25.0)
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{FF0000}The player you wish to duel is not near you.", "Select", "Back");

		if (IsPlayerJailed(targetid))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Select a player", "{FFFFFF}Please type the name of the player you wish to duel:\n\n{FF0000}You can't duel this person right now, they are currently in jail.", "Select", "Back");

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have selected {C0C0C0}%s {FFFFFF}as your opponent.", ReturnPlayerName(targetid));

		duelInfo[playerid][duelPlayer] = targetid;
		ShowPlayerDuelMenu(playerid);
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_LOCATION)
	{
		if (!response)
			return ShowPlayerDuelMenu(playerid);

		if (duelInfo[playerid][duelLocation] == listitem)
		{
			SendError(playerid, "You have already selected this location!");
			return ShowPlayerDuelMenu(playerid);
		}

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have changed the duel location to {C0C0C0}%s{FFFFFF}.", LocationInfo[listitem][locationName]);

		duelInfo[playerid][duelLocation] = listitem;
		ShowPlayerDuelMenu(playerid);
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_WEAPON)
	{
		if (!response)
			return ShowPlayerDuelMenu(playerid);

		if (duelInfo[playerid][duelWeapon][0] == weaponList[listitem])
		{
			SendError(playerid, "You have already selected this weapon!");
			return ShowPlayerDuelMenu(playerid);
		}

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have changed Primary Weapon to {C0C0C0}%s{FFFFFF}.", ReturnWeaponName(weaponList[listitem]));
		duelInfo[playerid][duelWeapon][0] = weaponList[listitem];
		ShowPlayerDuelMenu(playerid);
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_WEAPON_TWO)
	{
		if (!response)
			return ShowPlayerDuelMenu(playerid);

		if (duelInfo[playerid][duelWeapon][1] == weaponList[listitem])
		{
			SendError(playerid, "You have already selected this weapon!");
			return ShowPlayerDuelMenu(playerid);
		}

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have changed Secondary Weapon to {C0C0C0}%s{FFFFFF}.", ReturnWeaponName(weaponList[listitem]));
		duelInfo[playerid][duelWeapon][1] = weaponList[listitem];
		ShowPlayerDuelMenu(playerid);
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_HEALTH)
	{
		if (!response)
			return ShowPlayerDuelMenu(playerid);

		new Float:health;

		if (sscanf(inputtext, "f", health))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Health", "{FFFFFF}Enter the amount of health you will begin with:\n\n{C0C0C0}Note: The default health is 100.0.", "Select", "Back");

		if (!(1.0 <= health <= 100.0))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Health", "{FFFFFF}Enter the amount of health you will begin with:\n\n{FF0000}The amount you have entered is a invalid amount, 1 to 100 only!", "Select", "Back");

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have changed Health to {C0C0C0}%0.2f%%{FFFFFF}.", health);
		duelInfo[playerid][duelHealth] = health;
		ShowPlayerDuelMenu(playerid);
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_ARMOUR)
	{
		if (!response)
			return ShowPlayerDuelMenu(playerid);

		new Float:armour;

		if (sscanf(inputtext, "f", armour))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Armour", "{FFFFFF}Enter the amount of armour you will begin with:\n\n{C0C0C0}Note: The default armour is 100.0.", "Select", "Back");

		if (!(0.0 <= armour <= 100.0))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Armour", "{FFFFFF}Enter the amount of armour you will begin with:\n\n{FF0000}The amount you have entered is a invalid amount, 0 to 100 only!", "Select", "Back");

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have changed Armour to {C0C0C0}%0.2f%%{FFFFFF}.", armour);
		duelInfo[playerid][duelArmour] = armour;
		ShowPlayerDuelMenu(playerid);
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_WAGER)
	{
		if (IsPlayerDueling(playerid)) // prevent spawning money
			return SendError(playerid, "You cannot use this at the moment.");

		if (!response)
			return ShowPlayerDuelMenu(playerid);

		new amount;

		if (sscanf(inputtext, "d", amount))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Set A Wager", "{FFFFFF}Please enter the wager for this duel:", "Select", "Back");

		if (!(0 <= amount < 10000000))
			return ShowPlayerDialog(playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, "{FFFFFF}Duel Settings - Set A Wager", "{FFFFFF}Please enter the wager for this duel:\n\n{FF0000}Wagers must be between $0 and $10,000,000.", "Select", "Back");

		duelInfo[playerid][duelBet] = amount;
		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have changed the wager to %s.", number_format(duelInfo[playerid][duelBet]));
		ShowPlayerDuelMenu(playerid);
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:duel(playerid, params[])
{
	if (!strcmp(params, "accept", false, 6))
	{
		new
			targetid;

		if (sscanf(params[7], "u", targetid))
			return SendUsage(playerid, "/duel accept [PLAYER_ID]");

		if (!IsPlayerConnected(targetid))
			return SendError(playerid, "You do not have any duel invitations to accept.");

		if (gettime() > p_duelInvitation[targetid][playerid])
			return SendError(playerid, "You have not been invited by %s to duel or it has expired.");

		if (IsPlayerDueling(playerid))
			return SendError(playerid, "You cannot accept this invite as you are currently dueling.");

		if (GetDistanceBetweenPlayers(playerid, targetid) > 25.0)
			return SendError(playerid, "You must be within 25.0 meters of your opponent!");

		new waged_amount = duelInfo[targetid][duelBet];

		if (duelInfo[targetid][duelBet] != 0)
		{
			if (GetPlayerCash(targetid) < waged_amount)
			{
				SendClientMessageFormatted(targetid, -1, ""COL_DUEL"[DUEL]{FFFFFF} %s has accepted but you don't have money to wage (%s).", ReturnPlayerName(playerid), number_format(waged_amount));
				SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have accepted %s's duel invitation but they don't have money.", ReturnPlayerName(targetid));
				return 1;
			}
			else if (GetPlayerCash(playerid) < waged_amount)
			{
				SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} %s requires you to wage %s.", ReturnPlayerName(targetid), number_format(waged_amount));
				SendClientMessageFormatted(targetid, -1, ""COL_DUEL"[DUEL]{FFFFFF} %s has accepted the duel invitation but they don't have money to wage.", ReturnPlayerName(playerid));
				return 1;
			}
			else
			{
				GivePlayerCash(playerid, -waged_amount);
				GivePlayerCash(targetid, -waged_amount);
			}
		}

		SendClientMessageFormatted(targetid, -1, ""COL_DUEL"[DUEL]{FFFFFF} %s has accepted your duel invitation.", ReturnPlayerName(playerid));
		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[DUEL]{FFFFFF} You have accepted %s's duel invitation.", ReturnPlayerName(targetid));

		p_playerDueling{targetid} = true;
		p_playerDueling{playerid} = true;

		duelInfo[targetid][duelPlayer] = playerid;
		duelInfo[playerid][duelPlayer] = targetid;
		duelInfo[playerid][duelBet] = duelInfo[targetid][duelBet];
		duelInfo[playerid][duelRemainingRounds] = 1;
		duelInfo[targetid][duelRemainingRounds] = 1;

		new id = duelInfo[targetid][duelLocation];

		ResetPlayerWeapons(targetid);
		RemovePlayerFromVehicle(targetid);
		SetPlayerArmour(targetid, duelInfo[targetid][duelArmour]);
		SetPlayerHealth(targetid, duelInfo[targetid][duelHealth]);
		SetPlayerVirtualWorld(targetid, targetid + 1);
		SetPlayerPos(targetid, LocationInfo[id][locationPosTwo][0], LocationInfo[id][locationPosTwo][1], LocationInfo[id][locationPosTwo][2]);

		ResetPlayerWeapons(playerid);
		RemovePlayerFromVehicle(playerid);
		SetPlayerArmour(playerid, duelInfo[targetid][duelArmour]);
		SetPlayerHealth(playerid, duelInfo[targetid][duelHealth]);
		SetPlayerVirtualWorld(playerid, targetid + 1);
		SetPlayerPos(playerid, LocationInfo[id][locationPosOne][0], LocationInfo[id][locationPosOne][1], LocationInfo[id][locationPosOne][2]);

		// freeze
		TogglePlayerControllable(playerid, 0);
		TogglePlayerControllable(targetid, 0);

		// start countdown
		duelInfo[targetid][duelCountdown] = 10;
		duelInfo[targetid][duelTimer] = SetTimerEx("DuelTimer", 960, true, "d", targetid);

		// give weapon
		GivePlayerWeapon(playerid, duelInfo[targetid][duelWeapon][0], 5000);
		GivePlayerWeapon(targetid, duelInfo[targetid][duelWeapon][0], 5000);
		GivePlayerWeapon(playerid, duelInfo[targetid][duelWeapon][1], 5000);
		GivePlayerWeapon(targetid, duelInfo[targetid][duelWeapon][1], 5000);

		// clear invites for safety
		for (new i = 0; i < MAX_PLAYERS; i ++) {
			p_duelInvitation[playerid][i] = 0;
			p_duelInvitation[targetid][i] = 0;
		}
		return 1;
	}
	else if (strmatch(params, "cancel"))
	{
		if (ClearDuelInvites(playerid))
		{
			return SendServerMessage(playerid, "You have cancelled every duel offer that you have made.");
		}
		else
		{
			return SendError(playerid, "You have not made any duel offers recently.");
		}
	}
	return SendUsage(playerid, "/duel [ACCEPT/CANCEL]");
}

/* ** Functions ** */
static stock ClearDuelInvites(playerid)
{
	new current_time = gettime();
	new count = 0;

	for (new i = 0; i < MAX_PLAYERS; i ++)
	{
		if (p_duelInvitation[playerid][i] != 0 && current_time > p_duelInvitation[playerid][i])
		{
			p_duelInvitation[playerid][i] = 0;
			count ++;
		}
	}
	return count;
}

stock IsPlayerDueling(playerid) {
	return p_playerDueling{playerid};
}

stock ShowPlayerDuelMenu(playerid)
{
	if (GetPlayerClass(playerid) != CLASS_CIVILIAN)
		return SendError(playerid, "You can only use this feature whist being a civilian.");

	if (GetPlayerWantedLevel(playerid))
		return SendError(playerid, "You cannot duel whilst having a wanted level.");

	format(szBigString, sizeof(szBigString),
		"Player\t{C0C0C0}%s\nHealth\t{C0C0C0}%.2f%%\nArmour\t{C0C0C0}%.2f%%\nPrimary Weapon\t{C0C0C0}%s\nSecondary Weapon\t{C0C0C0}%s\nLocation\t{C0C0C0}%s\nWager\t{C0C0C0}%s\n"COL_GOLD"Send Invite\t"COL_GOLD">>>",
		(!IsPlayerConnected(duelInfo[playerid][duelPlayer]) ? (""COL_RED"N/A") : (ReturnPlayerName(duelInfo[playerid][duelPlayer]))),
		duelInfo[playerid][duelHealth],
		duelInfo[playerid][duelArmour],
		ReturnWeaponName(duelInfo[playerid][duelWeapon][0]),
		ReturnWeaponName(duelInfo[playerid][duelWeapon][1]),
		LocationInfo[duelInfo[playerid][duelLocation]][locationName],
		number_format(duelInfo[playerid][duelBet])
	);
	ShowPlayerDialog(playerid, DIALOG_DUEL, DIALOG_STYLE_TABLIST, "{FFFFFF}Duel Settings", szBigString, "Select", "Cancel");
	return 1;
}

static stock forfeitPlayerDuel(playerid)
{
	if (!IsPlayerDueling(playerid))
		return 0;

	ClearDuelInvites(playerid);

	new
		winnerid = duelInfo[playerid][duelPlayer];

	if (!IsPlayerConnected(winnerid) || !IsPlayerDueling(winnerid))
		return 0;

	// begin wager info
	new
		amount_waged = duelInfo[playerid][duelBet];

	SpawnPlayer(winnerid);
	ClearDuelInvites(winnerid);

	// decrement rounds
	duelInfo[playerid][duelRemainingRounds] --;
	duelInfo[winnerid][duelRemainingRounds] = duelInfo[playerid][duelRemainingRounds];

	// check if theres a remaining round
	if (duelInfo[playerid][duelRemainingRounds] == 0) {
		if (0 < amount_waged < 10000000) {
			new winning_prize = floatround(float(amount_waged) * 1.95); // We take 2.5% of the total pot
			GivePlayerCash(winnerid, winning_prize);
			SendClientMessageToAllFormatted( -1, ""COL_DUEL"[DUEL]{FFFFFF} %s(%d) has won the duel against %s(%d) for %s!", ReturnPlayerName(winnerid), winnerid, ReturnPlayerName(playerid), playerid, number_format(winning_prize));
		} else {
			SendClientMessageToAllFormatted( -1, ""COL_DUEL"[DUEL]{FFFFFF} %s(%d) has won the duel against %s(%d)!", ReturnPlayerName(winnerid), winnerid, ReturnPlayerName(playerid), playerid);
		}
	}
	return 1;
}

function DuelTimer(targetid)
{
	new
		playerid = duelInfo[targetid][duelPlayer];

	duelInfo[targetid][duelCountdown] --;

	if (duelInfo[targetid][duelCountdown] <= 0)
	{
		GameTextForPlayer(targetid, "~g~~h~FIGHT!", 1500, 4);
		GameTextForPlayer(playerid, "~g~~h~FIGHT!", 1500, 4);

		PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

		TogglePlayerControllable(playerid, 1);
		TogglePlayerControllable(targetid, 1);

		KillTimer(duelInfo[targetid][duelTimer]);
	}
	else
	{
		format(szSmallString, sizeof(szSmallString), "~w~%d", duelInfo[targetid][duelCountdown]);
		GameTextForPlayer(targetid, szSmallString, 1500, 4);
		GameTextForPlayer(playerid, szSmallString, 1500, 4);

		PlayerPlaySound(targetid, 1056, 0.0, 0.0, 0.0);
		PlayerPlaySound(playerid, 1056, 0.0, 0.0, 0.0);
	}
	return 1;
}
