/*
 * SA-MP FloodControl Include (c) 2012
 * Developed by RyDeR`, JernejL
 * Module: floodcontrol.inc
 * Purpose: controls server flooding
 */

#if !defined MAX_JOIN_LOGS
	#define MAX_JOIN_LOGS (50)
#endif

enum e_JoinLog {
	e_iIP,
	e_iTimeStamp
};

static stock
	g_eaJoinLog[MAX_JOIN_LOGS][e_JoinLog]
;

public OnPlayerConnect(playerid) {
	static
		s_iJoinSeq
	;
	new
		szIP[16]
	;
	GetPlayerIp(playerid, szIP, sizeof(szIP));

	g_eaJoinLog[s_iJoinSeq][e_iIP] = szIP[0] = IpToInt(szIP);
	g_eaJoinLog[s_iJoinSeq][e_iTimeStamp] = GetTickCount();

	s_iJoinSeq = ++s_iJoinSeq % MAX_JOIN_LOGS;

	szIP[1] = szIP[2] = 0;
	szIP[3] = -1;

	for(new i = 0; i < MAX_JOIN_LOGS; ++i) {
		if(g_eaJoinLog[i][e_iIP] != szIP[0]) {
			continue;
		}
		szIP[1]++;

		if(szIP[3] != -1) {
			szIP[2] += floatround(floatabs(g_eaJoinLog[i][e_iTimeStamp] - g_eaJoinLog[szIP[3]][e_iTimeStamp]));
		}
		szIP[3] = i;
	}
	static
		iHasOPFC = -1,
		iHasOPC = -1
	;
	if(iHasOPFC == -1) {
		iHasOPFC = funcidx("OnPlayerFloodControl");
	}
	if(iHasOPFC != -1) {
		CallRemoteFunction("OnPlayerFloodControl", "iii", playerid, szIP[1], szIP[2]);
	}
	if(iHasOPC == -1) {
		iHasOPC = funcidx("FC_OnPlayerConnect");
	}
	if(iHasOPC != -1) {
		return CallLocalFunction("FC_OnPlayerConnect", "i", playerid);
	}
	return 1;
}

#if defined _ALS_OnPlayerConnect
	#undef OnPlayerConnect
#else
	#define _ALS_OnPlayerConnect
#endif

#define OnPlayerConnect FC_OnPlayerConnect

static stock IpToInt(const szIP[]) {
	new
		aiBytes[1],
		iPos = 0
	;
	aiBytes{0} = strval(szIP[iPos]);
	while(iPos < 15 && szIP[iPos++] != '.') {}
	aiBytes{1} = strval(szIP[iPos]);
	while(iPos < 15 && szIP[iPos++] != '.') {}
	aiBytes{2} = strval(szIP[iPos]);
	while(iPos < 15 && szIP[iPos++] != '.') {}
	aiBytes{3} = strval(szIP[iPos]);

	return aiBytes[0];
}

forward OnPlayerConnect(playerid);
forward OnPlayerFloodControl(playerid, iCount, iTimeSpan);
