/*
 * Irresistible Gaming (c) 2018
 * Developed by Basssiiie, edited by Lorenc
 * Module: fireworks.inc
 * Purpose: implements fireworks into sa-mp
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
// #define DIALOG_FIREWORKS 			29383
// #define DIALOG_FIREWORKS_COLOR 		29385

// The maximum amount of firework instances that players can place, per server. (Default: 20)
#define MAX_FIREWORK 20

// The maximum amount of particle objects that can be spawned per firework instance. (Default: 75)
#define MAX_FWOBJECT 75

// This defines how long the fireworks will stay around before it gets destroyed, after it's finished firing all its rounds.
#define DEF_STAY_TIME 10000

// Firework types
#define FW_UNKNOWN 		0
#define FW_FOUNTAIN 	1
#define FW_ROCKET 		2
#define FW_SPLITTER 	3
#define FW_UMBRELLA 	4
#define FW_CAKE 		5

#define DEF_ANIM_TIME 2500
#define DEF_DELAY_FIRE 250

// Fountain defines
#define FOUNTAIN_LIFE 10000
#define FOUNTAIN_DELAY 200

// Rocket defines
#define ROCKET_DUPLICATES 25
#define ROCKET_DELAY 1000

// Splitter defines
#define SPLITTER_DUPLICATE_1 7
#define SPLITTER_DUPLICATE_2 10
#define SPLITTER_DELAY 1000

// Umbrella defines
#define UMBRELLA_DUPLICATES 30
#define UMBRELLA_DELAY 1000

// Cake defines
#define CAKE_DUPLICATES 10
#define CAKE_DELAY 500
#define CAKE_SINGLE_DELAY 500
#define CAKE_BIG_DELAY 2500

/* ** Variables ** */
enum E_FIREWORK_DATA
{
	E_CREATOR,			E_TYPE,				E_LIFETIME,
	E_STAGE,			E_ATTACHED_VEH,		E_COLORS[ 2 ]
};

new FW_DATA 						[ MAX_FIREWORK ] [ E_FIREWORK_DATA ];
new FW_Object 						[ MAX_FIREWORK ] [ MAX_FWOBJECT ] [ 2 ];
new Iterator: fireworks 			< MAX_FIREWORK >;

/* ** Hooks ** */
hook OnPlayerDisconnect(playerid, reason) {
	if (GetPVarInt(playerid, "FireworkPlaced")) {
		foreach (new fw : fireworks) if ( FW_DATA[ fw ] [ E_CREATOR ] == playerid && FW_DATA[ fw ] [ E_STAGE ] ) {
			FW_MainDestroy( fw );
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if (dialogid == DIALOG_FIREWORKS)
	{
		if ( GetPlayerFireworks( playerid ) < 1 ) return SendError( playerid, "You do not have any fireworks." );
		switch ( listitem )
		{
			case 0:
			{
				SetPVarInt(playerid, "FW_ColorsNumber", 2);
				SetPVarInt(playerid, "FW_MenuItem", FW_FOUNTAIN);
				ShowPlayerDialog( playerid, DIALOG_FIREWORKS_COLOR, DIALOG_STYLE_LIST, ""COL_WHITE"Fireworks", "White\nRed\nGreen\nBlue", "Select", "Back" );
			}
			case 1:
			{
				SetPVarInt(playerid, "FW_ColorsNumber", 2);
				SetPVarInt(playerid, "FW_MenuItem", FW_ROCKET);
				ShowPlayerDialog( playerid, DIALOG_FIREWORKS_COLOR, DIALOG_STYLE_LIST, ""COL_WHITE"Fireworks", "White\nRed\nGreen\nBlue", "Select", "Back" );
			}
			case 2:
			{
				SetPVarInt(playerid, "FW_ColorsNumber", 2);
				SetPVarInt(playerid, "FW_MenuItem", FW_SPLITTER);
				ShowPlayerDialog( playerid, DIALOG_FIREWORKS_COLOR, DIALOG_STYLE_LIST, ""COL_WHITE"Fireworks", "White\nRed\nGreen\nBlue", "Select", "Back" );
			}
			case 3:
			{
				SetPVarInt(playerid, "FW_ColorsNumber", 2);
				SetPVarInt(playerid, "FW_MenuItem", FW_UMBRELLA);
				ShowPlayerDialog( playerid, DIALOG_FIREWORKS_COLOR, DIALOG_STYLE_LIST, ""COL_WHITE"Fireworks", "White\nRed\nGreen\nBlue", "Select", "Back" );
			}
			case 4:
			{
				SetPVarInt(playerid, "FW_ColorsNumber", 2);
				SetPVarInt(playerid, "FW_MenuItem", FW_CAKE);
				ShowPlayerDialog( playerid, DIALOG_FIREWORKS_COLOR, DIALOG_STYLE_LIST, ""COL_WHITE"Fireworks", "White\nRed\nGreen\nBlue", "Select", "Back" );
			}
		}
		return 1;
	}
	else if ( dialogid == DIALOG_FIREWORKS_COLOR )
	{
		if ( GetPlayerFireworks( playerid ) < 1 ) return SendError( playerid, "You do not have any fireworks." );

		if ( ! response )
		{
			DeletePVar(playerid, "FW_Color1");
			DeletePVar(playerid, "FW_Color2");
			DeletePVar(playerid, "FW_MenuItem");
			DeletePVar(playerid, "FW_ColorsNumber");
			DeletePVar(playerid, "FW_Big");
			return 1;
		}

		if (!GetPVarInt(playerid, "FW_Color1") && !GetPVarInt(playerid, "FW_Color2"))
		{
			switch (listitem)
			{
				case 0: SetPVarInt(playerid, "FW_Color1", 19295); // Wit
				case 1: SetPVarInt(playerid, "FW_Color1", 19296); // Rood
				case 2: SetPVarInt(playerid, "FW_Color1", 19297); // Groen
				case 3: SetPVarInt(playerid, "FW_Color1", 19298); // Blauw
			}
			if (GetPVarInt(playerid, "FW_ColorsNumber") == 1)
			{
				FW_MainCreate(playerid, GetPVarInt(playerid, "FW_MenuItem"));
				return 1;
			}
			SendServerMessage( playerid, "Please select the primary color for your firework." );
			ShowPlayerDialog( playerid, DIALOG_FIREWORKS_COLOR, DIALOG_STYLE_LIST, ""COL_WHITE"Fireworks", "White\nRed\nGreen\nBlue", "Select", "Back" );
			return 1;
		}
		if (GetPVarInt(playerid, "FW_Color1") > 1 && !GetPVarInt(playerid, "FW_Color2"))
		{
			switch (listitem)
			{
				case 0: SetPVarInt(playerid, "FW_Color2", 19295);
				case 1: SetPVarInt(playerid, "FW_Color2", 19296);
				case 2: SetPVarInt(playerid, "FW_Color2", 19297);
				case 3: SetPVarInt(playerid, "FW_Color2", 19298);
			}
			SendServerMessage( playerid, "Please select the secondary color of your firework." );
			FW_MainCreate(playerid, GetPVarInt(playerid, "FW_MenuItem"));
			DeletePVar(playerid, "FW_MenuItem");
			DeletePVar(playerid, "FW_ColorsNumber");
			return 1;
		}
	}
	return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if (newkeys & KEY_FIRE && !(oldkeys & KEY_FIRE))
	{
		if(GetPlayerWeapon(playerid) == 40 || GetPVarInt(playerid, "Detonator") == 1)
		{
			if (GetPVarInt(playerid, "FireworkPlaced") == 1)
			{
				RemoveWeaponFromSlot(playerid, 12);
				DeletePVar(playerid, "FireworkPlaced");
				SetPVarInt(playerid, "TimerMainFire", SetTimerEx("FW_MainFire", DEF_DELAY_FIRE, true, "i", playerid));
				return 1;
			}
		}
	}
	return 1;
}

hook OnPlayerUpdate(playerid)
{
	if (GetPlayerWeapon(playerid) == 40)
	{
		if (GetPVarInt(playerid, "Detonator") != 1)
		{
			SetPVarInt(playerid, "Detonator", 1);
		}
	}
	else if (GetPVarInt(playerid, "Detonator") == 1)
	{
		DeletePVar(playerid, "Detonator");
	}
	return 1;
}

hook OnDynamicObjectMoved(objectid)
{
	foreach ( new fw : fireworks )
	{
		if (FW_DATA[ fw ] [ E_TYPE ] != FW_UNKNOWN)
		{
			for (new fo; fo != MAX_FWOBJECT; fo++)
			{
				if (FW_Object[fw][fo][0] == objectid)
				{
					switch(FW_DATA[ fw ] [ E_TYPE ])
					{
						case FW_FOUNTAIN:
						{
							switch (FW_Object[fw][fo][1])
							{
								case 1:
								{
									new Float: fwX, Float: fwY, Float: fwZ;
									GetDynamicObjectPos(FW_Object[fw][fo][0], fwX, fwY, fwZ);
									MoveDynamicObject(FW_Object[fw][fo][0], fwX, fwY, fwZ-10.0, 2.0+float(random(3)));
									FW_Object[fw][fo][1] = 2;
								}
								case 2: DestroyDynamicObject(FW_Object[fw][fo][0]), FW_Object[fw][fo][0] = 0, FW_Object[fw][fo][1] = 0;
							}
							return 1;
						}
						case FW_ROCKET:
						{
							switch (FW_Object[fw][fo][1])
							{
								case 1:
								{
									new Float: fwX, Float: fwY, Float: fwZ, stage;
									for (new prt; prt != ROCKET_DUPLICATES; prt++)
									{
										for (new fo2; fo2 != MAX_FWOBJECT; fo2++)
										{
											if (FW_Object[fw][fo2][0] == 0)
											{
												new model;
												switch (stage)
												{
													case 0: {model = FW_DATA[ fw ] [ E_COLORS ][0]; stage = 1;}
													case 1: {model = FW_DATA[ fw ] [ E_COLORS ][1]; stage = 0;}
												}
												GetDynamicObjectPos(objectid, fwX, fwY, fwZ);
												FW_Object[fw][fo2][0] = CreateDynamicObject(model, fwX, fwY, fwZ, 0.0, 0.0, 0.0, -1, 0, -1, 300.0);
												Get3DRandomDistanceAway(fwX, fwY, fwZ, 15, 30);
												MoveDynamicObject(FW_Object[fw][fo2][0], fwX, fwY, fwZ, 10.0+(float(random(20))/10.0));
												FW_Object[fw][fo2][1] = 2;
												break;
											}
										}
									}

									for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
									{
										if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
										{
											PlayerPlaySound(i, 1009, 0, 0, 0);
										}
									}

									DestroyDynamicObject(FW_Object[fw][fo][0]);
									FW_Object[fw][fo][0] = 0;
									FW_Object[fw][fo][1] = 0;
									UpdateStreamerForAll();
									return 1;
								}
								case 2:
								{
									DestroyDynamicObject(FW_Object[fw][fo][0]);
									FW_Object[fw][fo][0] = 0;
									FW_Object[fw][fo][1] = 0;
								}
							}
							return 1;
						}
						case FW_SPLITTER:
						{
							switch (FW_Object[fw][fo][1])
							{
								case 1:
								{
									new Float: fwX, Float: fwY, Float: fwZ;
									for (new prt; prt != SPLITTER_DUPLICATE_1; prt++)
									{
										for (new fo2; fo2 != MAX_FWOBJECT; fo2++)
										{
											if (FW_Object[fw][fo2][0] == 0)
											{
												GetDynamicObjectPos(objectid, fwX, fwY, fwZ);
												FW_Object[fw][fo2][0] = CreateDynamicObject(FW_DATA[ fw ] [ E_COLORS ][0], fwX, fwY, fwZ, 0.0, 0.0, 0.0, -1, 0, -1, 300.0);
												Get3DRandomDistanceAway(fwX, fwY, fwZ, 20, 40);
												MoveDynamicObject(FW_Object[fw][fo2][0], fwX, fwY, fwZ, 10.0+(float(random(20))/10.0));
												FW_Object[fw][fo2][1] = 2;
												break;
											}
										}
									}

									for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
									{
										if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
										{
											PlayerPlaySound(i, 1009, 0, 0, 0);
										}
									}

									DestroyDynamicObject(FW_Object[fw][fo][0]);
									FW_Object[fw][fo][0] = 0;
									FW_Object[fw][fo][1] = 0;
									UpdateStreamerForAll();
									return 1;
								}
								case 2:
								{
									new Float: fwX, Float: fwY, Float: fwZ;
									for (new prt; prt != SPLITTER_DUPLICATE_2; prt++)
									{
										for (new fo2; fo2 != MAX_FWOBJECT; fo2++)
										{
											if (FW_Object[fw][fo2][0] == 0)
											{
												GetDynamicObjectPos(objectid, fwX, fwY, fwZ);
												FW_Object[fw][fo2][0] = CreateDynamicObject(FW_DATA[ fw ] [ E_COLORS ][1], fwX, fwY, fwZ, 0.0, 0.0, 0.0, -1, 0, -1, 300.0);
												Get3DRandomDistanceAway(fwX, fwY, fwZ, 15, 30);
												MoveDynamicObject(FW_Object[fw][fo2][0], (fwX+(float(random(200))/10.0))-10.0, (fwY+(float(random(200))/10.0))-10.0, (fwZ+(float(random(200))/10.0))-10.0, 7.0+(float(random(20))/10.0));
												FW_Object[fw][fo2][1] = 3;
												break;
											}
										}
									}

									for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
									{
										if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
										{
											PlayerPlaySound(i, 1009, 0, 0, 0);
										}
									}

									DestroyDynamicObject(FW_Object[fw][fo][0]);
									FW_Object[fw][fo][0] = 0;
									FW_Object[fw][fo][1] = 0;
									UpdateStreamerForAll();
									return 1;
								}
								case 3: {DestroyDynamicObject(FW_Object[fw][fo][0]); FW_Object[fw][fo][0] = 0; FW_Object[fw][fo][1] = 0;}
							}
							return 1;
						}
						case FW_UMBRELLA:
						{
							switch (FW_Object[fw][fo][1])
							{
								case 1:
								{
									new Float: fwX, Float: fwY, Float: fwZ, stage;
									for (new prt; prt != UMBRELLA_DUPLICATES; prt++)
									{
										for (new fo2; fo2 != MAX_FWOBJECT; fo2++)
										{
											if (FW_Object[fw][fo2][0] == 0)
											{
												new model;
												switch (stage)
												{
													case 0: {model = FW_DATA[ fw ] [ E_COLORS ][0]; stage = 1;}
													case 1: {model = FW_DATA[ fw ] [ E_COLORS ][1]; stage = 0;}
												}

												GetDynamicObjectPos(objectid, fwX, fwY, fwZ);
												FW_Object[fw][fo2][0] = CreateDynamicObject(model, fwX, fwY, fwZ, 0.0, 0.0, 0.0, -1, 0, -1, 300.0);
												Get2DRandomDistanceAway(fwX, fwY, 25, 40);
												MoveDynamicObject(FW_Object[fw][fo2][0], fwX, fwY, fwZ, 8.0+(float(random(20))/10.0));
												FW_Object[fw][fo2][1] = 2;
												break;
											}
										}
									}

									for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
									{
										if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
										{
											PlayerPlaySound(i, 1009, 0, 0, 0);
										}
									}

									DestroyDynamicObject(FW_Object[fw][fo][0]);
									FW_Object[fw][fo][0] = 0;
									FW_Object[fw][fo][1] = 0;
									UpdateStreamerForAll();
									return 1;
								}
								case 2: {DestroyDynamicObject(FW_Object[fw][fo][0]); FW_Object[fw][fo][0] = 0; FW_Object[fw][fo][1] = 0;}
							}
							return 1;
						}
						case FW_CAKE:
						{
							switch (FW_Object[fw][fo][1])
							{
								case 1:
								{
									new Float: fwX, Float: fwY, Float: fwZ;
									for (new prt; prt != CAKE_DUPLICATES; prt++)
									{
										for (new fo2; fo2 != MAX_FWOBJECT; fo2++)
										{
											if (FW_Object[fw][fo2][0] == 0)
											{
												GetDynamicObjectPos(objectid, fwX, fwY, fwZ);
												FW_Object[fw][fo2][0] = CreateDynamicObject(FW_DATA[ fw ] [ E_COLORS ][1], fwX, fwY, fwZ, 0.0, 0.0, 0.0, -1, 0, -1, 300.0);
												Get3DRandomDistanceAway(fwX, fwY, fwZ, 25, 40);
												MoveDynamicObject(FW_Object[fw][fo2][0], fwX, fwY, fwZ, 15.0+(float(random(20))/10.0));
												FW_Object[fw][fo2][1] = 2;
												break;
											}
										}
									}

									for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
									{
										if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
										{
											PlayerPlaySound(i, 1009, 0, 0, 0);
										}
									}

									DestroyDynamicObject(FW_Object[fw][fo][0]);
									FW_Object[fw][fo][0] = 0;
									FW_Object[fw][fo][1] = 0;
									UpdateStreamerForAll();
									return 1;
								}
								case 2: {DestroyDynamicObject(FW_Object[fw][fo][0]); FW_Object[fw][fo][0] = 0; FW_Object[fw][fo][1] = 0;}
							}
							return 1;
						}
					}
					return 0;
				}
			}
		}
	}
	return 1;
}

stock FW_MainCreate(playerid, firework)
{
	if (IsPlayerNPC(playerid) || !IsPlayerConnected(playerid)) return 0;

	if (GetPlayerInterior(playerid) != 0)
	{
		SendError( playerid, "You can't light fireworks inside!" );
		return 0;
	}

	if (GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
	{
		switch(firework)
		{
			case FW_UNKNOWN:
			{
				SendError( playerid, "Fireworks couldn't be created!" );
				return 0;
			}
			case FW_FOUNTAIN, FW_ROCKET, FW_SPLITTER, FW_UMBRELLA, FW_CAKE:
			{
				ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 1.0, 0, 0, 0, 1, 0, 1);
				SetTimerEx("FW_MainCreateEnd", DEF_ANIM_TIME, false, "ii", playerid, firework);
				return 1;
			}
		}
	}
	else {
		SendError( playerid, "You have to be on foot to place fireworks down!" );
	}
	return 0;
}

forward FW_MainCreateEnd(playerid, firework);
public FW_MainCreateEnd(playerid, firework)
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		fw = Iter_Free( fireworks );

	if ( fw != ITER_NONE )
	{
		new
			Float: plX, Float: plY, Float: fwX, Float: fwY, Float: Z;

		// reset some variables
		FW_DATA[ fw ] [ E_CREATOR ] = -1;
		FW_DATA[ fw ] [ E_ATTACHED_VEH ] = -1;

		// add to list
		Iter_Add( fireworks, fw );

		// handle player
		ClearAnimations(playerid);
		GivePlayerWeapon(playerid, 40, 1);
		GetPlayerPos(playerid, plX, plY, Z);
		SetPVarInt(playerid, "FireworkPlaced", 1);
		GetXYInFrontOfPlayer(playerid, fwX, fwY, Z, 1.0);
		new Float: R = atan2( fwY - plY, fwX - fwX ) - 90.0; // GetAngleToPos(plX, plY, fwX, fwY);

		switch( firework )
		{
			case FW_FOUNTAIN: FW_FountainCreate(playerid, fw, fwX, fwY, Z, R, GetPVarInt(playerid, "FW_Color1"), GetPVarInt(playerid, "FW_Color2"));
			case FW_ROCKET: FW_RocketCreate(playerid, fw, fwX, fwY, Z, R, GetPVarInt(playerid, "FW_Color1"), GetPVarInt(playerid, "FW_Color2"));
			case FW_SPLITTER: FW_SplitterCreate(playerid, fw, fwX, fwY, Z, R, GetPVarInt(playerid, "FW_Color1"), GetPVarInt(playerid, "FW_Color2"));
			case FW_UMBRELLA: FW_UmbrelllaCreate(playerid, fw, fwX, fwY, Z, R, GetPVarInt(playerid, "FW_Color1"), GetPVarInt(playerid, "FW_Color2"));
			case FW_CAKE: FW_CakeCreate(playerid, fw, fwX, fwY, Z, R, GetPVarInt(playerid, "FW_Color1"), GetPVarInt(playerid, "FW_Color2"));
			default: return SendError( playerid, "Fireworks couldn't be created!" );
		}

		// reset colors
		DeletePVar(playerid, "FW_Color1");
		DeletePVar(playerid, "FW_Color2");

		// give a less firework
		GivePlayerFireworks( playerid, -1 );
		SendServerMessage( playerid, "You have placed a firework. You now have %d remaining fireworks.", GetPlayerFireworks( playerid ) );
		return 1;
	}
	return SendError( playerid, "Server limit is reached! Light some before you place more." ), 0;
}

function FW_MainFire(playerid)
{
	static
		Float: fwX, Float: fwY, Float: fwZ;

	foreach ( new fw : fireworks )
	{
		if (FW_DATA[ fw ] [ E_CREATOR ] == playerid && FW_DATA[ fw ] [ E_STAGE ] == 1)
		{
			switch (FW_DATA[ fw ] [ E_TYPE ])
			{
				case FW_UNKNOWN:
				{
					FW_DATA[ fw ] [ E_CREATOR ] = -1;
					SendError( playerid, "Fireworks couldn't be lighted!" );
					return 0;
				}
				case FW_FOUNTAIN:
				{
					FW_DATA[ fw ] [ E_LIFETIME ] = FOUNTAIN_LIFE;
					FW_DATA[ fw ] [ E_STAGE ] = 2;
					GetDynamicObjectPos(FW_Object[fw][0][0], fwX, fwY, fwZ);

					for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++) if(IsPlayerInRangeOfPoint(i,50, fwX, fwY, fwZ)) {
						PlayerPlaySound(i, 1134, 0, 0, 0);
					}

					SetTimerEx("FW_FountainFire", FOUNTAIN_DELAY, false, "ii", fw, 0);
					return 1;
				}
				case FW_ROCKET:
				{
					FW_DATA[ fw ] [ E_STAGE ] = 2;
					GetDynamicObjectPos(FW_Object[fw][0][0], fwX, fwY, fwZ);
					FW_Object[fw][3][0] = CreateDynamicObject(18727, fwX, fwY, fwZ, 0.0, 0.0, 0.0, 150);
					SetTimerEx("FW_RocketFire", ROCKET_DELAY, false, "i", fw);
					return 1;
				}
				case FW_SPLITTER:
				{
					FW_DATA[ fw ] [ E_STAGE ] = 2;
					GetDynamicObjectPos(FW_Object[fw][0][0], fwX, fwY, fwZ);
					FW_Object[fw][3][0] = CreateDynamicObject(18727, fwX, fwY, fwZ, 0.0, 0.0, 0.0, 150);
					SetTimerEx("FW_SplitterFire", SPLITTER_DELAY, false, "i", fw);
					return 1;
				}
				case FW_UMBRELLA:
				{
					FW_DATA[ fw ] [ E_STAGE ] = 2;
					GetDynamicObjectPos(FW_Object[fw][0][0], fwX, fwY, fwZ);
					FW_Object[fw][3][0] = CreateDynamicObject(18727, fwX, fwY, fwZ, 0.0, 0.0, 0.0, 150);
					SetTimerEx("FW_UmbrelllaFire", UMBRELLA_DELAY, false, "i", fw);
					return 1;
				}
				case FW_CAKE:
				{
					FW_DATA[ fw ] [ E_STAGE ] = 2;
					SetTimerEx("FW_CakeFire", CAKE_DELAY, false, "ii", fw, 1);
					return 1;
				}
			}
			return 1;
		}
	}
	KillTimer(GetPVarInt(playerid, "TimerMainFire"));
	DeletePVar(playerid, "TimerMainFire");
	return 0;
}

function FW_MainDestroy(fw)
{
	Iter_Remove( fireworks, fw );
	FW_DATA[ fw ] [ E_CREATOR ] = -1;
	FW_DATA[ fw ] [ E_TYPE ] = FW_UNKNOWN;
	FW_DATA[ fw ] [ E_ATTACHED_VEH ] = -1;
	FW_DATA[ fw ] [ E_LIFETIME ] = 0;
	FW_DATA[ fw ] [ E_STAGE ] = 0;
	FW_DATA[ fw ] [ E_COLORS ][0] = 0;
	FW_DATA[ fw ] [ E_COLORS ][1] = 0;
	for (new fo; fo != MAX_FWOBJECT; fo++)
	{
		if (FW_Object[fw][fo][0] != 0)
		{
			if (IsValidDynamicObject(FW_Object[fw][fo][0])) {DestroyDynamicObject(FW_Object[fw][fo][0]);}
			FW_Object[fw][fo][0] = 0;
			FW_Object[fw][fo][1] = 0;
		}
	}
	return 1;
}

// FOUNTAIN
stock FW_FountainCreate(playerid, fw, Float: X, Float: Y, Float: Z, Float: R, model1, model2)
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	FW_DATA[ fw ] [ E_CREATOR ] = playerid;
	FW_DATA[ fw ] [ E_STAGE ] = 1;
	FW_DATA[ fw ] [ E_TYPE ] = FW_FOUNTAIN;
	FW_DATA[ fw ] [ E_COLORS ][0] = model1;
	FW_DATA[ fw ] [ E_COLORS ][1] = model2;
	if (FW_DATA[ fw ] [ E_COLORS ][0] == 0) {FW_DATA[ fw ] [ E_COLORS ][0] = 19284;}
	if (FW_DATA[ fw ] [ E_COLORS ][1] == 0) {FW_DATA[ fw ] [ E_COLORS ][1] = 19281;}
	FW_Object[fw][0][0] = CreateDynamicObject(1271, X, Y, Z-0.65, 0.0, 0.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][1][0] = CreateDynamicObject(2203, X, Y, Z-0.4, 0.0, 0.0, R, -1, 0, -1, 100.0);

	new surf = GetPlayerSurfingVehicleID(playerid);
	if (surf != INVALID_VEHICLE_ID)
	{
		FW_DATA[ fw ] [ E_ATTACHED_VEH ] = surf;
		new Float: vehPos[3];
		GetVehiclePos(surf, vehPos[0], vehPos[1], vehPos[2]);
		X -= vehPos[0];
		Y -= vehPos[1];
		Z -= vehPos[2];
		AttachDynamicObjectToVehicle(FW_Object[fw][0][0], surf, X, Y, Z-0.65, 0.0, 0.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][1][0], surf, X, Y, Z-0.4, 0.0, 0.0, R);
	}
	UpdateStreamerForAll();
	return 1;
}

forward FW_FountainFire(fw, stage);
public FW_FountainFire(fw, stage)
{
	for (new fo; fo != MAX_FWOBJECT; fo++)
	{
		if (FW_Object[fw][fo][0] == 0)
		{
			new Float: fwX, Float: fwY, Float: fwZ, model;
			if (FW_DATA[ fw ] [ E_ATTACHED_VEH ] == -1) {GetDynamicObjectPos(FW_Object[fw][0][0], fwX, fwY, fwZ);}
			else
			{
				GetVehiclePos(FW_DATA[ fw ] [ E_ATTACHED_VEH ], fwX, fwY, fwZ);
				new Float: AttachOffset[3];
				Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_X, AttachOffset[0]);
				Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Y, AttachOffset[1]);
				Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Z, AttachOffset[2]);
				fwX += AttachOffset[0];
				fwY += AttachOffset[1];
				fwZ += AttachOffset[2];
			}
			switch(stage)
			{
				case 0: {model = FW_DATA[ fw ] [ E_COLORS ][0]; stage = 1;}
				case 1: {model = FW_DATA[ fw ] [ E_COLORS ][1]; stage = 0;}
			}
			FW_Object[fw][fo][0] = CreateDynamicObject(model, (fwX+(float(random(5))/10.0))-0.25, (fwY+(float(random(5))/10.0))-0.25, fwZ, 0.0, 0.0, 0.0, -1, 0, -1, 300.0);
			MoveDynamicObject(FW_Object[fw][fo][0], (fwX+(float(random(80))/10.0))-4.0, (fwY+(float(random(80))/10.0))-4.0, fwZ+(20.0+float(random(15))), 15.0+(float(random(20))/10.0));
			FW_Object[fw][fo][1] = 1;
			UpdateStreamerForAll();
			break;
		}
		if (fo == (MAX_FWOBJECT-1))
		{
			print( "[FIREWORKS ERROR] ENTITIES LIMIT REACHED! 1" );
			return 0;
		}
	}
	FW_DATA[ fw ] [ E_LIFETIME ] -= FOUNTAIN_DELAY;
	if (FW_DATA[ fw ] [ E_LIFETIME ] > 0) {SetTimerEx("FW_FountainFire", FOUNTAIN_DELAY, false, "ii", fw, stage); return 1;}
	FW_DATA[ fw ] [ E_STAGE ] = 3;
	SetTimerEx("FW_MainDestroy", DEF_STAY_TIME, false, "i", fw);
	return 0;
}

// ROCKET
stock FW_RocketCreate(playerid, fw, Float: X, Float: Y, Float: Z, Float: R, model1, model2)
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	FW_DATA[ fw ] [ E_CREATOR ] = playerid;
	FW_DATA[ fw ] [ E_STAGE ] = 1;
	FW_DATA[ fw ] [ E_TYPE ] = FW_ROCKET;
	FW_DATA[ fw ] [ E_COLORS ][0] = model1;
	FW_DATA[ fw ] [ E_COLORS ][1] = model2;
	if (FW_DATA[ fw ] [ E_COLORS ][0] == 0) {FW_DATA[ fw ] [ E_COLORS ][0] = 19282;}
	if (FW_DATA[ fw ] [ E_COLORS ][1] == 0) {FW_DATA[ fw ] [ E_COLORS ][1] = 19281;}
	FW_Object[fw][0][0] = CreateDynamicObject(1271, X, Y, Z-0.65, 0.0, 0.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][1][0] = CreateDynamicObject(3790, X, Y, Z+0.95, 0.0, 90.0, R, -1, 0, -1, 100.0);

	new surf = GetPlayerSurfingVehicleID(playerid);
	if (surf != INVALID_VEHICLE_ID)
	{
		FW_DATA[ fw ] [ E_ATTACHED_VEH ] = surf;
		new Float: vehPos[3];
		GetVehiclePos(surf, vehPos[0], vehPos[1], vehPos[2]);
		X -= vehPos[0];
		Y -= vehPos[1];
		Z -= vehPos[2];
		AttachDynamicObjectToVehicle(FW_Object[fw][0][0], surf, X, Y, Z-0.65, 0.0, 0.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][1][0], surf, X, Y, Z+0.95, 0.0, 90.0, R);
	}

	UpdateStreamerForAll();
	return 1;
}

forward FW_RocketFire(fw);
public FW_RocketFire(fw)
{
	DestroyDynamicObject(FW_Object[fw][3][0]);
	new Float: fwX, Float: fwY, Float: fwZ, Float: R;
	if (FW_DATA[ fw ] [ E_ATTACHED_VEH ] == -1) {GetDynamicObjectPos(FW_Object[fw][1][0], fwX, fwY, fwZ);}
	else
	{
		GetVehiclePos(FW_DATA[ fw ] [ E_ATTACHED_VEH ], fwX, fwY, fwZ);
		new Float: AttachOffset[3];
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_X, AttachOffset[0]);
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Y, AttachOffset[1]);
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Z, AttachOffset[2]);
		fwX += AttachOffset[0];
		fwY += AttachOffset[1];
		fwZ += AttachOffset[2];
	}

	for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
	{
		if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
		{
			PlayerPlaySound(i, 1095, 0, 0, 0);
		}
	}
	DestroyDynamicObject(FW_Object[fw][1][0]);
	Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_R_Z, R);
	FW_Object[fw][1][0] = CreateDynamicObject(3790, fwX, fwY, fwZ+0.95, 0.0, 90.0, R, -1, 0, -1, 300.0);
	FW_Object[fw][2][0] = CreateDynamicObject(345, fwX, fwY, fwZ-1.2, 90.0, 0.0, 0.0, -1, 0, -1, 300.0);
	fwX += (float(random(30))/10);
	fwY += (float(random(30))/10);
	fwZ = fwZ + 40 + float(random(5));
	MoveDynamicObject(FW_Object[fw][1][0], fwX, fwY, fwZ, 18.0);
	MoveDynamicObject(FW_Object[fw][2][0], fwX, fwY, fwZ-1.2, 18.0);
	FW_Object[fw][1][1] = 1;
	FW_Object[fw][2][1] = 2;
	UpdateStreamerForAll();
	SetTimerEx("FW_MainDestroy", DEF_STAY_TIME, false, "i", fw);
	return 0;
}

// SPLITTER
stock FW_SplitterCreate(playerid, fw, Float: X, Float: Y, Float: Z, Float: R, model1, model2)
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	FW_DATA[ fw ] [ E_CREATOR ] = playerid;
	FW_DATA[ fw ] [ E_STAGE ] = 1;
	FW_DATA[ fw ] [ E_TYPE ] = FW_SPLITTER;
	FW_DATA[ fw ] [ E_COLORS ][0] = model1;
	FW_DATA[ fw ] [ E_COLORS ][1] = model2;
	if (FW_DATA[ fw ] [ E_COLORS ][0] == 0) {FW_DATA[ fw ] [ E_COLORS ][0] = 19282;}
	FW_Object[fw][0][0] = CreateDynamicObject(1271, X, Y, Z-0.65, 0.0, 0.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][1][0] = CreateDynamicObject(3786, X, Y, Z+0.95, 0.0, 90.0, R, -1, 0, -1, 100.0);

	new surf = GetPlayerSurfingVehicleID(playerid);
	if (surf != INVALID_VEHICLE_ID)
	{
		FW_DATA[ fw ] [ E_ATTACHED_VEH ] = surf;
		new Float: vehPos[3];
		GetVehiclePos(surf, vehPos[0], vehPos[1], vehPos[2]);
		X -= vehPos[0];
		Y -= vehPos[1];
		Z -= vehPos[2];
		AttachDynamicObjectToVehicle(FW_Object[fw][0][0], surf, X, Y, Z-0.65, 0.0, 0.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][1][0], surf, X, Y, Z+0.95, 0.0, 90.0, R);
	}

	UpdateStreamerForAll();
	return 1;
}

forward FW_SplitterFire(fw);
public FW_SplitterFire(fw)
{
	DestroyDynamicObject(FW_Object[fw][3][0]);
	new Float: fwX, Float: fwY, Float: fwZ, Float: R;
	if (FW_DATA[ fw ] [ E_ATTACHED_VEH ] == -1) {GetDynamicObjectPos(FW_Object[fw][1][0], fwX, fwY, fwZ);}
	else
	{
		GetVehiclePos(FW_DATA[ fw ] [ E_ATTACHED_VEH ], fwX, fwY, fwZ);
		new Float: AttachOffset[3];
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_X, AttachOffset[0]);
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Y, AttachOffset[1]);
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Z, AttachOffset[2]);
		fwX += AttachOffset[0];
		fwY += AttachOffset[1];
		fwZ += AttachOffset[2];
	}

	for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
	{
		if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
		{
			PlayerPlaySound(i, 1095, 0, 0, 0);
		}
	}

	DestroyDynamicObject(FW_Object[fw][1][0]);
	Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_R_Z, R);

	FW_Object[fw][1][0] = CreateDynamicObject(3786, fwX, fwY, fwZ+0.95, 0.0, 90.0, R, -1, 0, -1, 300.0);
	FW_Object[fw][2][0] = CreateDynamicObject(345, fwX, fwY, fwZ-1.2, 90.0, 0.0, 0.0, -1, 0, -1, 300.0);
	fwX += (float(random(30))/10);
	fwY += (float(random(30))/10);
	fwZ = fwZ + 40.0 + float(random(5));
	MoveDynamicObject(FW_Object[fw][1][0], fwX, fwY, fwZ, 18.0);
	MoveDynamicObject(FW_Object[fw][2][0], fwX, fwY, fwZ-1.2, 18.0);
	FW_Object[fw][1][1] = 1;
	FW_Object[fw][2][1] = 3;
	UpdateStreamerForAll();
	SetTimerEx("FW_MainDestroy", DEF_STAY_TIME, false, "i", fw);
	return 0;
}

// Umbrella
stock FW_UmbrelllaCreate(playerid, fw, Float: X, Float: Y, Float: Z, Float: R, model1, model2)
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	FW_DATA[ fw ] [ E_CREATOR ] = playerid;
	FW_DATA[ fw ] [ E_STAGE ] = 1;
	FW_DATA[ fw ] [ E_TYPE ] = FW_UMBRELLA;
	FW_DATA[ fw ] [ E_COLORS ][0] = model1;
	FW_DATA[ fw ] [ E_COLORS ][1] = model2;
	if (FW_DATA[ fw ] [ E_COLORS ][0] == 0) {FW_DATA[ fw ] [ E_COLORS ][0] = 19282;}
	if (FW_DATA[ fw ] [ E_COLORS ][1] == 0) {FW_DATA[ fw ] [ E_COLORS ][1] = 19281;}
	FW_Object[fw][0][0] = CreateDynamicObject(1271, X, Y, Z-0.65, 0.0, 0.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][1][0] = CreateDynamicObject(3790, X, Y, Z+0.95, 0.0, 90.0, R, -1, 0, -1, 100.0);

	new surf = GetPlayerSurfingVehicleID(playerid);
	if (surf != INVALID_VEHICLE_ID)
	{
		FW_DATA[ fw ] [ E_ATTACHED_VEH ] = surf;
		new Float: vehPos[3];
		GetVehiclePos(surf, vehPos[0], vehPos[1], vehPos[2]);
		X -= vehPos[0];
		Y -= vehPos[1];
		Z -= vehPos[2];
		AttachDynamicObjectToVehicle(FW_Object[fw][0][0], surf, X, Y, Z-0.65, 0.0, 0.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][1][0], surf, X, Y, Z+0.95, 0.0, 90.0, R);
	}
	UpdateStreamerForAll();
	return 1;
}

function FW_UmbrelllaFire(fw)
{
	DestroyDynamicObject(FW_Object[fw][3][0]);
	new Float: fwX, Float: fwY, Float: fwZ, Float: R;
	if (FW_DATA[ fw ] [ E_ATTACHED_VEH ] == -1) {GetDynamicObjectPos(FW_Object[fw][1][0], fwX, fwY, fwZ);}
	else
	{
		GetVehiclePos(FW_DATA[ fw ] [ E_ATTACHED_VEH ], fwX, fwY, fwZ);
		new Float: AttachOffset[3];
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_X, AttachOffset[0]);
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Y, AttachOffset[1]);
		Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Z, AttachOffset[2]);
		fwX += AttachOffset[0];
		fwY += AttachOffset[1];
		fwZ += AttachOffset[2];
	}

	for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
	{
		if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
		{
			PlayerPlaySound(i, 1095, 0, 0, 0);
		}
	}

	DestroyDynamicObject(FW_Object[fw][1][0]);
	Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_R_Z, R);


	FW_Object[fw][1][0] = CreateDynamicObject(3790, fwX, fwY, fwZ+0.95, 0.0, 90.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][2][0] = CreateDynamicObject(345, fwX, fwY, fwZ-1.2, 90.0, 0.0, 0.0, -1, 0, -1, 300.0);
	fwX += (float(random(30))/10);
	fwY += (float(random(30))/10);
	fwZ = fwZ + 40.0 + float(random(5));
	MoveDynamicObject(FW_Object[fw][1][0], fwX, fwY, fwZ, 18.0);
	MoveDynamicObject(FW_Object[fw][2][0], fwX, fwY, fwZ-1.2, 18.0);
	FW_Object[fw][1][1] = 1;
	FW_Object[fw][2][1] = 2;
	UpdateStreamerForAll();
	SetTimerEx("FW_MainDestroy", DEF_STAY_TIME, false, "i", fw);
	return 0;
}

// CAKE (is a lie! ^_^)
stock FW_CakeCreate(playerid, fw, Float: X, Float: Y, Float: Z, Float: R, model1, model2)
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	FW_DATA[ fw ] [ E_CREATOR ] = playerid;
	FW_DATA[ fw ] [ E_STAGE ] = 1;
	FW_DATA[ fw ] [ E_TYPE ] = FW_CAKE;
	FW_DATA[ fw ] [ E_COLORS ][0] = model1;
	FW_DATA[ fw ] [ E_COLORS ][1] = model2;
	if (FW_DATA[ fw ] [ E_COLORS ][0] == 0) {FW_DATA[ fw ] [ E_COLORS ][0] = 19282;}
	if (FW_DATA[ fw ] [ E_COLORS ][1] == 0) {FW_DATA[ fw ] [ E_COLORS ][1] = 19281;}
	FW_Object[fw][0][0] = CreateDynamicObject(1271, X, Y, Z-0.65, 0.0, 0.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][1][0] = CreateDynamicObject(2902, X, Y, Z-0.55, 0.0, -45.0-90.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][2][0] = CreateDynamicObject(2902, X, Y, Z-0.5, 0.0, -22.5-90.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][3][0] = CreateDynamicObject(2902, X, Y, Z-0.45, 0.0, 0.0-90.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][4][0] = CreateDynamicObject(2902, X, Y, Z-0.5, 0.0, 22.5-90.0, R, -1, 0, -1, 100.0);
	FW_Object[fw][5][0] = CreateDynamicObject(2902, X, Y, Z-0.55, 0.0, 45.0-90.0, R, -1, 0, -1, 100.0);

	new surf = GetPlayerSurfingVehicleID(playerid);
	if (surf != INVALID_VEHICLE_ID)
	{
		FW_DATA[ fw ] [ E_ATTACHED_VEH ] = surf;
		new Float: vehPos[3];
		GetVehiclePos(surf, vehPos[0], vehPos[1], vehPos[2]);
		X -= vehPos[0];
		Y -= vehPos[1];
		Z -= vehPos[2];
		AttachDynamicObjectToVehicle(FW_Object[fw][0][0], surf, X, Y, Z-0.65, 0.0, 0.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][1][0], surf, X, Y, Z-0.55, 0.0, -45.0-90.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][2][0], surf, X, Y, Z-0.5, 0.0, -22.5-90.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][3][0], surf, X, Y, Z-0.45, 0.0, 0.0-90.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][4][0], surf, X, Y, Z-0.5, 0.0, 22.5-90.0, R);
		AttachDynamicObjectToVehicle(FW_Object[fw][5][0], surf, X, Y, Z-0.55, 0.0, 45.0-90.0, R);
	}
	UpdateStreamerForAll();
	return 1;
}

function FW_CakeFire(fw, stage)
{
	new fwTime;
	if (stage != 11)
	{
		for (new fo; fo != MAX_FWOBJECT; fo++)
		{
			if (FW_Object[fw][fo][0] == 0)
			{
				new Float: fwX, Float: fwY, Float: fwZ, Float: fwU, Float: fwR;
				if (FW_DATA[ fw ] [ E_ATTACHED_VEH ] == -1) {GetDynamicObjectPos(FW_Object[fw][1][0], fwX, fwY, fwZ);}
				else
				{
					GetVehiclePos(FW_DATA[ fw ] [ E_ATTACHED_VEH ], fwX, fwY, fwZ);
					new Float: AttachOffset[3];
					Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_X, AttachOffset[0]);
					Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Y, AttachOffset[1]);
					Streamer_GetFloatData(0, FW_Object[fw][0][0], E_STREAMER_ATTACH_OFFSET_Z, AttachOffset[2]);
					fwX += AttachOffset[0];
					fwY += AttachOffset[1];
					fwZ += AttachOffset[2];
				}

				GetDynamicObjectRot(FW_Object[fw][0][0], fwU, fwU, fwR);

				for (new i = 0, mp = GetPlayerPoolSize(); i <= mp; i++)
				{
					if(IsPlayerInRangeOfPoint(i,50,fwX, fwY, fwZ))
					{
						PlayerPlaySound(i, 1095, 0, 0, 0);
					}
				}

				FW_Object[fw][fo][0] = CreateDynamicObject(FW_DATA[ fw ] [ E_COLORS ][0], fwX, fwY, fwZ-0.5, 0.0, 0.0, 0.0, -1, 0, -1, 300.0);
				switch (stage)
				{
					case 1, 10, 12:{GetOffsetPos(fwX, fwY, 30.0, fwR+90); fwZ += 25.0;}
					case 2, 9, 13: {GetOffsetPos(fwX, fwY, 20.0, fwR+90); fwZ += 35.0;}
					case 3, 8, 14: {									  fwZ += 40.0;}
					case 4, 7, 15: {GetOffsetPos(fwX, fwY, 20.0, fwR-90); fwZ += 35.0;}
					case 5, 6, 16: {GetOffsetPos(fwX, fwY, 30.0, fwR-90); fwZ += 25.0;}
				}
				MoveDynamicObject(FW_Object[fw][fo][0], fwX, fwY, fwZ, 25.0);
				FW_Object[fw][fo][1] = 1;
				break;
			}
			if (fo == (MAX_FWOBJECT-1))
			{
				print( "[FIREWORKS ERROR] ENTITIES LIMIT REACHED! 2" );
				return 0;
			}
		}
		if (FW_DATA[ fw ] [ E_STAGE ] != 2) {return 1;}
		switch (stage)
		{
			case 1..4, 6..9: {fwTime = CAKE_SINGLE_DELAY;}
			case 5, 10: {fwTime = CAKE_BIG_DELAY;}
		}
		UpdateStreamerForAll();
		stage++;
		SetTimerEx("FW_CakeFire", fwTime, false, "ii", fw, stage);
		return 1;
	}
	else
	{
		FW_DATA[ fw ] [ E_STAGE ] = 3;
		FW_CakeFire( fw, 12 );
		FW_CakeFire( fw, 13 );
		FW_CakeFire( fw, 14 );
		FW_CakeFire( fw, 15 );
		FW_CakeFire( fw, 16 );
		UpdateStreamerForAll();
		SetTimerEx("FW_MainDestroy", DEF_STAY_TIME, false, "i", fw);
		return 0;
	}
}

// Other things
stock UpdateStreamerForAll()
{
	for (new p = 0, mp = GetPlayerPoolSize(); p <= mp; p++)
	{
		Streamer_Update(p);
	}
	return 1;
}

stock GetOffsetPos(&Float:x, &Float:y, Float:distance, Float: r)
{	// Created by Y_Less
	x += (distance * floatsin(-r, degrees));
	y += (distance * floatcos(-r, degrees));
}

stock Get2DRandomDistanceAway(&Float: fwX, &Float: fwY, min_distance, max_distance = 100)
{
	new Float: tempX = fwX, Float: tempY = fwY;
	new rX = random(max_distance);
	new rY = random(max_distance);
	tempX += float(rX-(max_distance/2));
	tempY += float(rY-(max_distance/2));
	while (GetDistanceBetweenPoints(tempX, tempY, 10.0, fwX, fwY, 10.0) < min_distance/2)
	{
		tempX = fwX;
		tempY = fwY;
		rX = random(max_distance);
		rY = random(max_distance);
		tempX += float(rX-(max_distance/2));
		tempY += float(rY-(max_distance/2));
	}
	fwX = tempX;
	fwY = tempY;
	return 1;
}

stock Get3DRandomDistanceAway(&Float: fwX, &Float: fwY, &Float: fwZ, min_distance, max_distance = 100)
{
	new Float: tempX = fwX, Float: tempY = fwY, Float: tempZ = fwZ;
	new rX = random(max_distance);
	new rY = random(max_distance);
	new rZ = random(max_distance);
	tempX += float(rX-(max_distance/2));
	tempY += float(rY-(max_distance/2));
	tempZ += float(rZ-(max_distance/2));
	while (GetDistanceBetweenPoints(tempX, tempY, tempZ, fwX, fwY, fwZ) < min_distance/2)
	{
		tempX = fwX;
		tempY = fwY;
		tempZ = fwZ;
		rX = random(max_distance);
		rY = random(max_distance);
		rZ = random(max_distance);
		tempX += float(rX-(max_distance/2));
		tempY += float(rY-(max_distance/2));
		tempZ += float(rZ-(max_distance/2));
	}
	fwX = tempX;
	fwY = tempY;
	fwZ = tempZ;
	return 1;
}

stock RemoveWeaponFromSlot(playerid, weaponslot)
{
	new weapons[13][2];
	for(new i = 0; i < 13; i++) {
		GetPlayerWeaponData(playerid, i, weapons[i][0], weapons[i][1]);
	}
	weapons[weaponslot][0] = 0;
	ResetPlayerWeapons(playerid);
	for(new i = 0; i < 13; i++) {
		GivePlayerWeapon(playerid, weapons[i][0], weapons[i][1]);
	}
	return 1;
}

/* ** Commands ** */
CMD:fireworks( playerid, params[] )
{
	if ( GetPlayerFireworks( playerid ) < 1 ) return SendError( playerid, "You do not have any fireworks." );
	ShowPlayerDialog( playerid, DIALOG_FIREWORKS, DIALOG_STYLE_LIST, ""COL_WHITE"Fireworks", "Fountain\nRocket\nSplitter\nUmbrella\nCake", "Select", "Back" );
	return 1;
}
