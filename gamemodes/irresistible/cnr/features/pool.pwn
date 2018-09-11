/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: cnr/features/pool.pwn
 * Purpose: pool minigame
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >
#include 							< physics >
#include 							< progress2 >

#define POOL_DEBUG

/* ** Marcos ** */
#define IsPlayerPlayingPool(%0) 	(p_isPlayingPool{%0})

/* ** Definitions ** */
#define POCKET_RADIUS 				0.09
#define POOL_TIMER_SPEED 			30
#define DEFAULT_AIM 				0.38
#define DEFAULT_POOL_STRING 		"{FFDC2E}Pool Table\n{FFFFFF}To begin pool use /pool"

#define MAX_TABLES 					100
#define COL_POOL 					"{C0C0C0}"

/* ** Constants ** */
new Float: g_poolPotOffsetData[ ] [ ] = {
	{ 0.955, 0.510 }, { 0.955, -0.49 },
	{ 0.005, 0.550 }, { 0.007, -0.535 },
	{ -0.945, 0.513 }, { -0.945, -0.490 }
};

/* ** Variables ** */
enum E_POOL_BALL_DATA
{
	E_BALL_OBJECT[ 16 ],			bool: E_EXISTS[ 16 ], 			bool: E_MOVING[ 16 ]
};

enum E_POOL_TABLE_DATA
{
	Float: E_X,						Float: E_Y, 					Float: E_Z,
	Float: E_ANGLE, 				E_WORLD, 						E_INTERIOR,

	E_TIMER, 						E_COUNTDOWN,					E_PLAYER[ 2 ],
	bool: E_STARTED, 				E_AIMER, 						E_AIMER_OBJECT,
	E_LAST_SHOOTER, 				E_LAST_SCORE,					Float: E_POWER,
	E_DIRECTION,

	E_TABLE,						Text3D: E_LABEL,
}

new
	g_poolTableData 				[ MAX_TABLES ] [ E_POOL_TABLE_DATA ],
	g_poolBallData 					[ MAX_TABLES ] [ E_POOL_BALL_DATA ],

	p_PoolReciever					[ MAX_PLAYERS ],
	p_PoolSender					[ MAX_PLAYERS ],
	p_PoolID 						[ MAX_PLAYERS ],

	bool: p_isPlayingPool			[ MAX_PLAYERS char],
	bool: p_PoolChalk				[ MAX_PLAYERS ],
	p_PoolCamera 					[ MAX_PLAYERS ],
	p_PoolScore 					[ MAX_PLAYERS ],
	Float: p_PoolAngle 				[ MAX_PLAYERS ] [ 2 ],

	PlayerBar: g_PoolPowerBar 		[ MAX_PLAYERS ],
	PlayerText: g_PoolTextdraw		[ MAX_PLAYERS ],

	Iterator: pooltables 			< MAX_TABLES >
;

/* ** Forwards ** */

forward deleteBall 					( poolid, ballid );
forward RestoreWeapon 				( playerid );
forward RestoreCamera 				( playerid, poolid );
forward OnPoolUpdate 				( poolid );
forward PlayPoolSound 				( poolid, soundid );

/* ** Hooks ** */

hook OnScriptInit( )
{
	//stock CreatePoolTable(Float: X, Float: Y, Float: Z, Float: A = 0.0, interior = 0, world = 0)

	CreatePoolTable(2048.5801, 1330.8917, 10.6719, 0, 0);

	printf( "[POOL TABLES]: %d pool tables have been successfully loaded.", Iter_Count( pooltables ) );
	return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
	if ( IsPlayerPlayingPool(playerid ) )
	{
		gameEnd( p_PoolID[ playerid ] );

		p_PoolSender[ playerid ] 	= INVALID_PLAYER_ID;
		p_PoolReciever[ playerid ] 	= INVALID_PLAYER_ID;
		p_isPlayingPool{ playerid } = false;
		p_PoolID[ playerid ] 		= -1;

		p_PoolScore[ playerid ] 	= 0;
	}
	return 1;
}

hook OnPlayerConnect(playerid)
{
	g_PoolPowerBar[playerid] = CreatePlayerProgressBar(playerid, 530.000000, 233.000000, 61.000000, 6.199999, -1429936641, 100.0000, 0);

	g_PoolTextdraw[playerid] = CreatePlayerTextDraw(playerid, 529.000000, 218.000000, "Power~n~~n~Score: 0");
	PlayerTextDrawBackgroundColor(playerid, g_PoolTextdraw[playerid], 255);
	PlayerTextDrawFont(playerid, g_PoolTextdraw[playerid], 1);
	PlayerTextDrawLetterSize(playerid, g_PoolTextdraw[playerid], 0.300000, 1.299998);
	PlayerTextDrawColor(playerid, g_PoolTextdraw[playerid], -1);
	PlayerTextDrawSetOutline(playerid, g_PoolTextdraw[playerid], 1);
	PlayerTextDrawSetProportional(playerid, g_PoolTextdraw[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, g_PoolTextdraw[playerid], 0);
	return 1;
}

hook OnPlayerSpawn(playerid)
{
	p_PoolSender[ playerid ] 	= INVALID_PLAYER_ID;
	p_PoolReciever[ playerid ] 	= INVALID_PLAYER_ID;
	p_isPlayingPool{ playerid } = false;
	p_PoolID[ playerid ] 		= -1;
	p_PoolScore[ playerid ] 	= 0;
	return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	new id = -1;

	if ((id = getNearestPoolTable(playerid)) != -1)
	{
		if (g_poolTableData[ id ] [ E_STARTED ] && IsPlayerPlayingPool( playerid ) && p_PoolID[ playerid ] == id)
		{
			if (PRESSED(KEY_FIRE))
			{
				ClearAnimations(playerid);
				return 0;
			}
			else
			{
				// Not the players turn detection (player 1 and/or player 2)
				if (IsKeyJustUp(KEY_SECONDARY_ATTACK, newkeys, oldkeys))
				{
					if (IsPlayerPlayingPool( playerid ) && g_poolTableData[ id ] [ E_AIMER ] != playerid && !p_PoolChalk[ playerid ])
					{
						SetTimerEx("PlayPoolSound", 1400, false, "dd", id, 31807);
						SetPlayerArmedWeapon(playerid, 0);
						SetPlayerAttachedObject(playerid, 0, 338, 6, 0, 0.07, -0.85, 0, 0, 0);
						ApplyAnimation(playerid, "POOL", "POOL_ChalkCue", 3.0, 0, 0, 0, 0, 0, 1);

						p_PoolChalk[ playerid ] = true;

						SetTimerEx("RestoreWeapon", 3500, false, "d", playerid);
					}
				}

				if (IsKeyJustUp(KEY_JUMP, newkeys, oldkeys))
				{
					if (g_poolTableData[ id ] [ E_AIMER ] == playerid)
					{
						if (p_PoolCamera[ playerid ] < 2) p_PoolCamera[ playerid ] ++;
						else p_PoolCamera[ playerid ] = 0;

						new Float:poolrot = p_PoolAngle[ playerid ] [ 0 ],
							Float:Xa,
							Float:Ya,
							Float:Za,
							Float:x,
							Float:y;

						GetObjectPos(g_poolBallData[ id ] [ E_BALL_OBJECT ] [ 0 ], Xa, Ya, Za);

						switch (p_PoolCamera[ playerid ])
						{
							case 0:
							{
								GetXYBehindObjectInAngle(g_poolBallData[ id ] [ E_BALL_OBJECT ] [ 0 ], poolrot, x, y, 0.675);
								SetPlayerCameraPos(playerid, x, y, g_poolTableData[ id ] [ E_Z ] + DEFAULT_AIM);
								SetPlayerCameraLookAt(playerid, Xa, Ya, Za + 0.170);
							}
							case 1..2:
							{
								SetPlayerCameraPos(playerid, g_poolTableData[ id ] [ E_X ], g_poolTableData[ id ] [ E_Y ], g_poolTableData[ id ] [ E_Z ] + 2.0);
								SetPlayerCameraLookAt(playerid, g_poolTableData[ id ] [ E_X ], g_poolTableData[ id ] [ E_Y ], g_poolTableData[ id ] [ E_Z ]);
							}
						}
					}
				}

				if (IsKeyJustUp(KEY_HANDBRAKE, newkeys, oldkeys))
				{
					if (AreAllBallsStopped(id))
					{
						if (g_poolTableData[ id ] [ E_AIMER ] != playerid)
						{
							if (!p_PoolChalk[ playerid ] && g_poolTableData[ id ] [ E_AIMER ] == -1)
							{
								new Float:poolrot,
									Float:X, Float:Y, Float:Z,
									Float:Xa, Float:Ya, Float:Za,
									Float:x, Float:y;

								GetPlayerPos(playerid, X, Y, Z);
								GetObjectPos(g_poolBallData[id] [E_BALL_OBJECT] [0], Xa, Ya, Za);

								if (GetDistanceFromPointToPoint(X, Y, Xa, Ya) < 1.5 && Z < 999.5)
								{
									TogglePlayerControllable(playerid, false);
									GetAngleToXY(Xa, Ya, X, Y, poolrot);
	                            	SetPlayerFacingAngle(playerid, poolrot);

	                            	p_PoolAngle[ playerid ] [ 0 ] = poolrot;
	                            	p_PoolAngle[ playerid ] [ 1 ] = poolrot;

									SetPlayerArmedWeapon(playerid, 0);
									GetXYInFrontOfPos(Xa, Ya, poolrot + 180, x, y, 0.085);
									g_poolTableData[ id ] [ E_AIMER_OBJECT ] = CreateObject(3004, x, y, Za, 7.0, 0, poolrot + 180);

									SetPlayerCameraPos(playerid, g_poolTableData[ id ] [ E_X ], g_poolTableData[ id ] [ E_Y ], g_poolTableData[ id ] [ E_Z ] + 2.0);

									ApplyAnimation(playerid, "POOL", "POOL_Med_Start", 50.0, 0, 0, 0, 1, 1, 1);

									g_poolTableData[ id ] [ E_AIMER ] = playerid;
									g_poolTableData[ id ] [ E_POWER ] = 1.0;
									g_poolTableData[ id ] [ E_DIRECTION ] = 0;

									PlayerTextDrawSetString(playerid, g_PoolTextdraw[playerid], sprintf("Power:~n~~n~Score: %d", p_PoolScore[ playerid ]) );
									PlayerTextDrawShow(playerid, g_PoolTextdraw[playerid]);
									ShowPlayerProgressBar(playerid, g_PoolPowerBar[playerid]);
								}
							}
						}
						else
						{
							TogglePlayerControllable(playerid, true);
							GivePlayerWeapon(playerid, 7, 1);

							ApplyAnimation(playerid, "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0, 1);
	            			SetCameraBehindPlayer(playerid);

	            			g_poolTableData[ id ] [ E_AIMER ] = -1;
	            			DestroyObject(g_poolTableData[ id ] [ E_AIMER_OBJECT ]);

	            			//TextDrawHideForPlayer(playerid, gPoolTD);
	            			//HidePlayerProgressBar(playerid, g_PoolPowerBar[playerid]);
						}
					}
				}

				if (IsKeyJustUp(KEY_FIRE, newkeys, oldkeys))
				{
					if (g_poolTableData[ id ] [ E_AIMER ] == playerid)
					{
						new Float: speed;

						ApplyAnimation(playerid, "POOL", "POOL_Med_Shot", 3.0, 0, 0, 0, 0, 0, 1);

						speed = 0.4 + (g_poolTableData[ id ] [ E_POWER ] * 2.0) / 100.0;
						PHY_SetObjectVelocity(g_poolBallData[id] [E_BALL_OBJECT] [0], speed * floatsin(-p_PoolAngle[ playerid ] [ 0 ], degrees), speed * floatcos(-p_PoolAngle[ playerid ] [ 0 ], degrees));

						SetPlayerCameraPos(playerid, g_poolTableData[ id ] [ E_X ], g_poolTableData[ id ] [ E_Y ], g_poolTableData[ id ] [ E_Z ] + 2.0);
						SetPlayerCameraLookAt(playerid, g_poolTableData[ id ] [ E_X ], g_poolTableData[ id ] [ E_Y ], g_poolTableData[ id ] [ E_Z ]);

						PlayPoolSound(id, 31810);
						g_poolTableData[ id ] [ E_AIMER ] = -1;
						DestroyObject(g_poolTableData[ id ] [ E_AIMER_OBJECT ]);

						GivePlayerWeapon(playerid, 7, 1);

						g_poolTableData[ id ] [ E_LAST_SHOOTER ] = playerid;
						g_poolTableData[ id ] [ E_LAST_SCORE ] = 0;
					}
					else ClearAnimations(playerid);
				}
			}
		}
	}

	return 1;
}

/* ** Functions ** */

stock getNearestPoolTable( playerid )
{
	for ( new i = 0; i != MAX_TABLES; i ++ ) if ( IsPlayerInRangeOfPoint( playerid, 2.5, g_poolTableData[ i] [ E_X ], g_poolTableData[ i] [ E_Y ], g_poolTableData[ i] [ E_Z ]) ) {
		return i;
	}
	return -1;
}

stock CreatePoolTable( Float: X, Float: Y, Float: Z, Float: A = 0.0, interior = 0, world = 0 )
{
	if ( A != 0 && A != 90.0 && A != 180.0 && A != 270.0 && A != 360.0 ) {
		return print( "[POOL] [ERROR] Pool tables must be positioned at either 0, 90, 180, 270 and 360 degrees." ), 1;
	}

	new
		gID = Iter_Free( pooltables );

	if ( gID != ITER_NONE )
	{
		new
			Float: x_vertex[ 4 ], Float: y_vertex[ 4 ];

		Iter_Add( pooltables, gID );

		g_poolTableData[ gID ] [ E_X ] = X;
		g_poolTableData[ gID ] [ E_Y ] = Y;
		g_poolTableData[ gID ] [ E_Z ] = Z;
		g_poolTableData[ gID ] [ E_ANGLE ] = A;

		g_poolTableData[ gID ] [ E_INTERIOR ] = interior;
		g_poolTableData[ gID ] [ E_WORLD ] = world;

		g_poolTableData[ gID] [ E_TABLE ] = CreateDynamicObject( 2964, X, Y, Z - 1.0, 0.0, 0.0, A, world, interior );
		g_poolTableData[ gID] [ E_LABEL ] = CreateDynamic3DTextLabel( DEFAULT_POOL_STRING, COLOR_GOLD, X, Y, (Z - 0.5), 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, world, interior );

		RotateXY( -0.964, -0.51, A, x_vertex[ 0 ], y_vertex[ 0 ] );
		RotateXY( -0.964, 0.533, A, x_vertex[ 1 ], y_vertex[ 1 ] );
		RotateXY( 0.976, -0.51, A, x_vertex[ 2 ], y_vertex[ 2 ] );
		RotateXY( 0.976, 0.533, A, x_vertex[ 3 ], y_vertex[ 3 ] );



		PHY_CreateWall( x_vertex[0] + X, y_vertex[0] + Y, x_vertex[1] + X, y_vertex[1] + Y);
		PHY_CreateWall( x_vertex[1] + X, y_vertex[1] + Y, x_vertex[3] + X, y_vertex[3] + Y);
		PHY_CreateWall( x_vertex[2] + X, y_vertex[2] + Y, x_vertex[3] + X, y_vertex[3] + Y);
		PHY_CreateWall( x_vertex[0] + X, y_vertex[0] + Y, x_vertex[2] + X, y_vertex[2] + Y);


	#if defined POOL_DEBUG
		ReloadPotTestLabel( 0, gID );
		/*new Float: middle_x;
		new Float: middle_y;
		CreateDynamicObject( 18643, x_vertex[0] + X, y_vertex[0] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, x_vertex[1] + X, y_vertex[1] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		middle_x = ((x_vertex[0] + X) + (x_vertex[1] + X)) / (2.0);
		middle_y = ((y_vertex[0] + Y) + (y_vertex[1] + Y)) / (2.0);
		CreateDynamicObject( 18643, middle_x, middle_y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, x_vertex[1] + X, y_vertex[1] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, x_vertex[3] + X, y_vertex[3] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		middle_x = ((x_vertex[1] + X) + (x_vertex[3] + X)) / (2.0);
		middle_y = ((y_vertex[1] + Y) + (y_vertex[3] + Y)) / (2.0);
		CreateDynamicObject( 18643, middle_x, middle_y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, ((x_vertex[1] + X) + middle_x) / 2.0, ((y_vertex[1] + Y) + middle_y) / 2.0, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, x_vertex[2] + X, y_vertex[2] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, x_vertex[3] + X, y_vertex[3] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		middle_x = ((x_vertex[2] + X) + (x_vertex[3] + X)) / (2.0);
		middle_y = ((y_vertex[2] + Y) + (y_vertex[3] + Y)) / (2.0);
		CreateDynamicObject( 18643, middle_x, middle_y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, x_vertex[0] + X, y_vertex[0] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, x_vertex[2] + X, y_vertex[2] + Y, Z - 1.0, 0.0, -90.0, 0.0 );
		middle_x = ((x_vertex[0] + X) + (x_vertex[2] + X)) / (2.0);
		middle_y = ((y_vertex[0] + Y) + (y_vertex[2] + Y)) / (2.0);
		CreateDynamicObject( 18643, middle_x, middle_y, Z - 1.0, 0.0, -90.0, 0.0 );
		CreateDynamicObject( 18643, ((x_vertex[0] + X) + middle_x) / 2.0, ((y_vertex[2] + Y) + middle_y) / 2.0, Z - 1.0, 0.0, -90.0, 0.0 );*/
	#endif
	}
	return gID;
}

stock RespawnPoolBalls(poolid, mode = 0)
{
	for (new i = 0; i < 16; i ++)
	{
		DestroyObject(g_poolBallData[poolid] [E_BALL_OBJECT] [i]);

		if (g_poolBallData[i] [E_EXISTS] [i])
		{
			PHY_DeleteObject(g_poolBallData[poolid] [E_BALL_OBJECT] [i]);
			g_poolBallData[poolid] [E_EXISTS] [i] = false;
		}
	}

	if (g_poolTableData[ poolid ] [ E_AIMER ] != -1)
	{
		TogglePlayerControllable(g_poolTableData[ poolid ] [ E_AIMER ], 1);
		//ClearAnimations(g_poolTableData[ poolid ] [ E_AIMER ]);

		//ApplyAnimation(g_poolTableData[ poolid ] [ E_AIMER ], "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0);
        SetCameraBehindPlayer(g_poolTableData[ poolid ] [ E_AIMER ]);
        DestroyObject(g_poolTableData[ poolid ] [ E_AIMER_OBJECT ]);

        //TextDrawHideForPlayer(g_poolTableData[ poolid ] [ E_AIMER ], gPoolTD);
        //HidePlayerProgressBar(g_poolTableData[ poolid ] [ E_AIMER ], g_PoolPowerBar[g_poolTableData[ poolid ] [ E_AIMER ]]);
		g_poolTableData[ poolid ] [ E_AIMER ] = -1;
	}

	CreateBalls(poolid);

	if (mode)
	{
		KillTimer(g_poolTableData[ poolid ] [ E_TIMER ]);
		g_poolTableData[ poolid ] [ E_TIMER ] = SetTimerEx("OnPoolUpdate", POOL_TIMER_SPEED, true, "d", poolid);

		for (new i = 0; i < 16; i ++)
		{
			InitBalls(poolid, i);
		}
	}
}

stock InitBalls(poolid, ballid)
{
	PHY_InitObject(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 3003, _, _, PHY_MODE_2D);

	PHY_SetObjectFriction(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 0.08);
	//PHY_SetObjectFriction(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 0.10);
	PHY_SetObjectAirResistance(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 0.2);
	PHY_RollObject(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid]);

	g_poolBallData[poolid] [E_EXISTS] [ballid] = true;
}

stock RotateXY( Float: xi, Float: yi, Float: angle, &Float: xf, &Float: yf )
{
    xf = xi * floatcos( angle, degrees ) - yi * floatsin( angle, degrees );
    yf = xi * floatsin( angle, degrees ) + yi * floatcos( angle, degrees );
    return 1;
}

stock CreateBalls( poolid )
{
	enum E_POOL_BALL_OFFSET_DATA {
		E_MODEL_ID, Float: E_OFFSET_X, Float: E_OFFSET_Y
	};

	static const
		g_poolBallOffsetData[ ] [ E_POOL_BALL_OFFSET_DATA ] =
		{
			{ 3003, 0.5, 0.0 }, { 3002, -0.3, 0.0 }, { 3100, -0.525, -0.040 }, { 3101, -0.375, 0.044 },
			{ 3102, -0.600, 0.079 }, { 3103, -0.525, 0.118 }, { 3104, -0.600, -0.157 }, { 3105, -0.450, -0.079 },
			{ 3106, -0.450, 0.0 }, { 2995, -0.375, -0.044 }, { 2996, -0.450, 0.079 }, { 2997, -0.525, -0.118 },
			{ 2998, -0.600, -0.079 }, { 2999, -0.600, 0.0 }, { 3000, -0.600, 0.157 }, { 3001, -0.525, 0.040 }
		}
	;

	new
		Float: offset_x,
		Float: offset_y;

	for ( new i = 0; i < sizeof( g_poolBallOffsetData ); i ++ )
	{
		// get offset according to angle of table
		RotateXY( g_poolBallOffsetData[ i ] [ E_OFFSET_X ], g_poolBallOffsetData[ i ] [ E_OFFSET_Y ], g_poolTableData[ poolid ] [ E_ANGLE ], offset_x, offset_y );

		// create pool balls on table
		g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] = CreateObject(
			g_poolBallOffsetData[ i ] [ E_MODEL_ID ],
			g_poolTableData[ poolid ] [ E_X ] + offset_x,
			g_poolTableData[ poolid ] [ E_Y ] + offset_y,
			g_poolTableData[ poolid ] [ E_Z ] - 0.045,
			0.0, 0.0, 0.0
		);
	}
}

stock IsKeyJustUp(key, newkeys, oldkeys) {
    return !(newkeys & key) && (oldkeys & key);
}

stock GetXYBehindObjectInAngle(objectid, Float:a, &Float:x2, &Float:y2, Float:distance)
{
    new Float:z;
    GetObjectPos(objectid, x2, y2, z);

    x2 += (distance * floatsin(-a+180, degrees));
    y2 += (distance * floatcos(-a+180, degrees));
}

stock AreAllBallsStopped(poolid)
{
	new
		Float: x,
		Float: y,
		Float: z;

	for (new i = 0; i < 16; i ++)
	{
		if (g_poolBallData[poolid] [E_EXISTS] [i])
		{
			PHY_GetObjectVelocity(g_poolBallData[poolid] [E_BALL_OBJECT] [i], x, y, z);

			if (x != 0.0 || y != 0.0)
				return 0;
		}
	}
	return 1;
}

stock GetAngleToXY(Float:X, Float:Y, Float:CurrX, Float:CurrY, &Float:angle)
{
    angle = atan2(Y-CurrY, X-CurrX);
    angle = floatsub(angle, 90.0);
    if(angle < 0.0) angle = floatadd(angle, 360.0);
}

stock GetXYInFrontOfPos(Float:xx,Float:yy,Float:a, &Float:x2, &Float:y2, Float:distance)
{
    if (a > 360) {
        a = a - 360;
    }

    xx += (distance * floatsin(-a, degrees));
    yy += (distance * floatcos(-a, degrees));
    x2 = xx;
    y2 = yy;
}

stock GetMaxPoolScore(poolid)
{
	new score = -1;

	foreach (new i : Player)
	{
		if ( IsPlayerPlayingPool( i ) && p_PoolID[ i ] == poolid)
		{
			if (p_PoolScore[ i ] > score)
			{
				score = p_PoolScore[ i ];
			}
		}
	}
	return score;
}

stock GetPoolBallsCount(poolid)
{
	new
		ball_count = 0;

	for ( new i = 0; i < 16; i ++ ) if ( g_poolBallData[ poolid ] [ E_EXISTS ] [ i ] || i == 0 ) {
		ball_count ++;
	}
	return ball_count;
}

stock IsBallInHole( poolid, objectid )
{
	new
		Float: hole_x, Float: hole_y;

	for ( new i = 0; i < sizeof( g_poolPotOffsetData ); i ++ )
	{
		// rotate offsets according to table
		RotateXY( g_poolPotOffsetData[ i ] [ 0 ], g_poolPotOffsetData[ i ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );

		// check if it is at the pocket
		if ( IsBallAtPos( objectid, g_poolTableData[ poolid ] [ E_X ] + hole_x , g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ], POCKET_RADIUS ) ) {
			return i;
		}
	}
    return -1;
}

stock respawnCueBall(poolid)
{
    if (!g_poolBallData[poolid] [E_EXISTS] [0])
	{
        DestroyObject(g_poolBallData[poolid] [E_BALL_OBJECT] [0]);

        new Float: x,
			Float: y,
			Float: pos[3],
			Float: angle;

		pos[0] = g_poolTableData[ poolid ] [ E_X ];
		pos[1] = g_poolTableData[ poolid ] [ E_Y ];
		pos[2] = g_poolTableData[ poolid ] [ E_Z ];
		angle = g_poolTableData[ poolid ] [ E_ANGLE ];

		RotateXY(0.5, 0.0, angle, x, y);
		g_poolBallData[poolid] [E_BALL_OBJECT] [0] = CreateObject(3003, x + pos[0], y + pos[1], (pos[2]), 0, 0, 0);

        InitBalls(poolid, 0);
	}
	return 1;
}

stock removePlayerWeapon(playerid, weaponid)
{
	SetPlayerArmedWeapon(playerid, weaponid);

	if (GetPlayerWeapon(playerid) != 0)
		GivePlayerWeapon(playerid, weaponid, 0);

	return 1;
}

stock gameEnd(poolid)
{
	foreach (new i : Player)
	{
		if (p_PoolID[ i ] == poolid)
		{
			p_isPlayingPool{ i } 	= false;
			p_PoolScore[ i ]   		= -1;
			p_PoolID[ i ]      		= -1;

			removePlayerWeapon(i, 7);
		}
	}

	g_poolTableData[ poolid ] [ E_STARTED ] = false;

	KillTimer(g_poolTableData[ poolid ] [ E_TIMER ]);
	for (new i = 0; i < 16; i ++)
	{
		DestroyObject(g_poolBallData[poolid] [E_BALL_OBJECT] [i]);

		if (g_poolBallData[poolid] [E_EXISTS] [i])
		{
			PHY_DeleteObject(g_poolBallData[poolid] [E_BALL_OBJECT] [i]);
			g_poolBallData[poolid] [E_EXISTS] [i] = false;
		}
	}

	UpdateDynamic3DTextLabelText(g_poolTableData[ poolid ] [ E_LABEL ], -1, DEFAULT_POOL_STRING);

	return 1;
}

stock AngleInRangeOfAngle(Float:a1, Float:a2, Float:range) {
	a1 -= a2;
	return (a1 < range) && (a1 > -range);
}

stock IsBallAtPos( objectid, Float: x, Float: y, Float: z, Float: radius )
{
    new
    	Float: object_x, Float: object_y, Float: object_z;

    GetObjectPos( objectid, object_x, object_y, object_z );

    new
    	Float: distance = GetDistanceBetweenPoints( object_x, object_y, object_z, x, y, z );

    return distance < radius;
}

/*stock IsBallNearSide(poolid, objectid)
{
	new Float: x_vertex[4],
		Float: y_vertex[4];

	RotateXY(-0.96, -0.515, 0.0, x_vertex[0], y_vertex[0]);
    RotateXY(-0.96, 0.515, 0.0, x_vertex[1], y_vertex[1]);
    RotateXY(0.96, -0.515, 0.0, x_vertex[2], y_vertex[2]);
    RotateXY(0.96, 0.515, 0.0, x_vertex[3], y_vertex[3]);

	if (IsBallAtPos(objectid, x_vertex[0] + g_poolTableData[ poolid ] [ E_X ], y_vertex[0] + g_poolTableData[ poolid ] [ E_Y ], x_vertex[1] + g_poolTableData[ poolid ] [ E_X ], y_vertex[1] + g_poolTableData[ poolid ] [ E_Y ])) return 1;
	if (IsBallAtPos(objectid, x_vertex[1] + g_poolTableData[ poolid ] [ E_X ], y_vertex[1] + g_poolTableData[ poolid ] [ E_Y ], x_vertex[3] + g_poolTableData[ poolid ] [ E_X ], y_vertex[3] + g_poolTableData[ poolid ] [ E_Y ])) return 1;
	if (IsBallAtPos(objectid, x_vertex[2] + g_poolTableData[ poolid ] [ E_X ], y_vertex[2] + g_poolTableData[ poolid ] [ E_Y ], x_vertex[3] + g_poolTableData[ poolid ] [ E_X ], y_vertex[3] + g_poolTableData[ poolid ] [ E_Y ])) return 1;
	if (IsBallAtPos(objectid, x_vertex[0] + g_poolTableData[ poolid ] [ E_X ], y_vertex[0] + g_poolTableData[ poolid ] [ E_Y ], x_vertex[2] + g_poolTableData[ poolid ] [ E_X ], y_vertex[2] + g_poolTableData[ poolid ] [ E_Y ])) return 1;
	return 0;
}*/

public PlayPoolSound( poolid, soundid ) {
	foreach ( new playerid : Player ) if ( p_PoolID[ playerid ] == poolid ) {
		PlayerPlaySound( playerid, soundid, 0.0, 0.0, 0.0 );
	}
	return 1;
}

public OnPoolUpdate(poolid)
{
	if (!g_poolTableData[ poolid ] [ E_STARTED ])
		return 0;

	if (g_poolTableData[ poolid ] [ E_AIMER ] != -1)
	{
		new playerid = g_poolTableData[ poolid ] [ E_AIMER ], keys, ud, lr;

		GetPlayerKeys(playerid, keys, ud, lr);

		if (!(keys & KEY_FIRE))
		{
			if (lr)
			{
				new Float: X, Float: Y, Float: Z, Float: Xa, Float: Ya, Float: Za, Float: x, Float: y, Float: newrot, Float: dist;

				GetPlayerPos(playerid, X, Y ,Z);
				GetObjectPos(g_poolBallData[poolid] [E_BALL_OBJECT] [0], Xa, Ya, Za);
				newrot = p_PoolAngle[ playerid ] [ 0 ] + (lr > 0 ? 0.9 : -0.9);
				dist = GetDistanceBetweenPoints( X, Y, 0.0, Xa, Ya, 0.0 );

				if (AngleInRangeOfAngle(p_PoolAngle[ playerid ] [ 1 ], newrot, 30.0))
	            {
	                p_PoolAngle[ playerid ] [ 0 ] = newrot;
					switch (p_PoolCamera[ playerid ])
					{
						case 0:
						{
							GetXYBehindObjectInAngle(g_poolBallData[poolid] [E_BALL_OBJECT] [0], newrot, x, y, 0.675);

							SetPlayerCameraPos(playerid, x, y, g_poolTableData[ poolid ] [ E_Z ] + DEFAULT_AIM);
							SetPlayerCameraLookAt(playerid, Xa, Ya, Za + 0.170);
						}
						case 1:
						{
							SetPlayerCameraPos(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0);
							SetPlayerCameraLookAt(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ]);
						}
						case 2:
						{
							SetPlayerCameraPos(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0);
							SetPlayerCameraLookAt(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ]);
						}
					}

	                GetXYInFrontOfPos(Xa, Ya, newrot + 180, x, y, 0.085);
	                SetObjectPos(g_poolTableData[ poolid ] [ E_AIMER_OBJECT ], x, y, Za);
	              	SetObjectRot(g_poolTableData[ poolid ] [ E_AIMER_OBJECT ], 7.0, 0, p_PoolAngle[ playerid ] [ 0 ] + 180);
	              	GetXYInFrontOfPos(Xa, Ya, newrot + 180, X, Y, dist);
	                SetPlayerPos(playerid, X, Y, Z);
	                SetPlayerFacingAngle(playerid, newrot);
	            }
			}
		}
		else
		{
		    if (g_poolTableData[ poolid ] [ E_DIRECTION ])
		    {
		        g_poolTableData[ poolid ] [ E_POWER ] -= 2.0;
		    }
			else
			{
			    g_poolTableData[ poolid ] [ E_POWER ] += 2.0;
			}

			if (g_poolTableData[ poolid ] [ E_POWER ] <= 0)
			{
			    g_poolTableData[ poolid ] [ E_DIRECTION ] = 0;
			    g_poolTableData[ poolid ] [ E_POWER ] = 2.0;
			}
			else if (g_poolTableData[ poolid ] [ E_POWER ] > 100.0)
			{
			    g_poolTableData[ poolid ] [ E_DIRECTION ] = 1;
			    g_poolTableData[ poolid ] [ E_POWER ] = 98.0;
			}

			// TextDrawTextSize(g_PoolTextdraw[2], 501.0 + ((67.0 * g_poolTableData[ poolid ] [ E_POWER ])/100.0), 0.0);
			// TextDrawShowForPlayer(playerid, g_PoolTextdraw[2]);

			// ShowPlayerPoolTextdraw(playerid);

			SetPlayerProgressBarMaxValue(playerid, g_PoolPowerBar[playerid], 67.0);
			SetPlayerProgressBarValue(playerid, g_PoolPowerBar[playerid], ((67.0 * g_poolTableData[ poolid ] [ E_POWER ])/100.0));
			ShowPlayerProgressBar(playerid, g_PoolPowerBar[playerid]);

			PlayerTextDrawShow(playerid, g_PoolTextdraw[playerid]);
		}
	}

	if (g_poolTableData[ poolid ] [ E_LAST_SHOOTER ] != -1 && AreAllBallsStopped(poolid))
	{
    	SetTimerEx("RestoreCamera", 800, 0, "dd", g_poolTableData[ poolid ] [ E_LAST_SHOOTER ], poolid);
    	g_poolTableData[ poolid ] [ E_LAST_SHOOTER ] = -1;
	}

	return 1;
}

public RestoreCamera(playerid, poolid)
{
	if (!g_poolBallData[poolid] [E_EXISTS] [0])
	{
        DestroyObject(g_poolBallData[poolid] [E_BALL_OBJECT] [0]);

        new Float: x, Float: y, Float: pos[3], Float: angle;

		pos[0] = g_poolTableData[ poolid ] [ E_X ];
		pos[1] = g_poolTableData[ poolid ] [ E_Y ];
		pos[2] = g_poolTableData[ poolid ] [ E_Z ];
		angle =  g_poolTableData[ poolid ] [ E_ANGLE ];

		RotateXY(0.5, 0.0, angle, x, y);
		g_poolBallData[poolid] [E_BALL_OBJECT] [0] = CreateObject(3003, x + pos[0], y + pos[1], (pos[2] - 0.045), 0, 0, 0);

        InitBalls(poolid, 0);
	}

	if (g_poolTableData[ poolid ] [ E_AIMER ] == playerid)
		return 0;

	PlayerTextDrawHide(playerid, g_PoolTextdraw[playerid]);
	HidePlayerProgressBar(playerid, g_PoolPowerBar[playerid]);

	TogglePlayerControllable(playerid, 1);
	return SetCameraBehindPlayer(playerid);
}

public deleteBall(poolid, ballid)
{
	if (g_poolBallData[poolid] [E_MOVING] [ballid])
	{
		g_poolBallData[poolid] [E_EXISTS] [ballid] = false;
		DestroyObject(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid]);
		PHY_DeleteObject(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid]);

		g_poolBallData[poolid] [E_MOVING] [ballid] = false;
	}

	return 1;
}

public RestoreWeapon(playerid)
{
	RemovePlayerAttachedObject(playerid, 0);

	p_PoolChalk[ playerid ] = false;

	GivePlayerWeapon(playerid, 7, 1);

	ApplyAnimation(playerid, "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0, 1);
	return 1;
}

/** * Public Functions * **/

public PHY_OnObjectCollideWithObject(object1, object2)
{
	for (new id = 0; id < MAX_TABLES; id ++) if (g_poolTableData[ id ] [ E_STARTED ])
	{
		for (new i = 0; i < 16; i++)
		{
		    if (object1 == g_poolBallData[id] [E_BALL_OBJECT] [i])
		    {
		        PlayPoolSound(id, 31800 + random(3));
		        return 1;
		    }
		}
	}
	return 1;
}

public PHY_OnObjectCollideWithWall( objectid, wallid )
{
	for ( new id = 0; id < MAX_TABLES; id ++ ) if ( g_poolTableData[ id ] [ E_STARTED ] )
	{
		for ( new i = 0; i < 16; i ++ ) if ( objectid == g_poolBallData[ id ] [ E_BALL_OBJECT ] [ i ] )
		{
	        PlayPoolSound(id, 31808);
	        return 1;
		}
	}
	return 1;
}

public PHY_OnObjectUpdate(objectid)
{
	foreach (new i : Player)
	{
		new
			poolid = getNearestPoolTable( i );

		if ( poolid == -1 )
			return 0;

    	for (new j = 0; j < 16; j ++)
    	{
    		if ( objectid == g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ j ] && PHY_IsObjectMoving( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ j ]) && !g_poolBallData[ poolid ] [ E_MOVING ] [ j ] )
    		{
    			new
    				holeid = IsBallInHole( poolid, objectid );

				if ( holeid != -1 )
				{
	    			new pool_player = g_poolTableData[ poolid ] [ E_LAST_SHOOTER ],
						modelid = GetObjectModel( objectid );

					if (modelid == 3003)
	    			{
	    				GameTextForPlayer(pool_player, "~n~~n~~n~~r~~h~You have pocketed the cue ball!", 10000, 4);

	    				respawnCueBall( poolid );
	    			}
	    			else
	    			{
	    				p_PoolScore[ pool_player ] += 1;
	    				GameTextForPlayer( pool_player, "~n~~n~~n~~w~Score: +1", 3000, 4);

						PlayerTextDrawSetString( pool_player, g_PoolTextdraw[ pool_player ], sprintf("Power:~n~~n~Score: %d", p_PoolScore[ pool_player ]));
						PlayerTextDrawHide( pool_player, g_PoolTextdraw[ pool_player ] );
						PlayerTextDrawShow( pool_player, g_PoolTextdraw[ pool_player ] );

	    				//ShowPlayerHelpDialog( pool_player, 10000, "~w~You have pocketed another ball!~n~~n~Score: %d", p_PoolScore[pool_player]);

						if (pool_player == g_poolTableData[ poolid ] [ E_PLAYER ] [ 0 ])
						{
							format(szNormalString, sizeof(szNormalString), "{FFDC2E}%s [%d] - [%d] %s", ReturnPlayerName(pool_player), p_PoolScore[ pool_player ], p_PoolScore[ g_poolTableData[ poolid ] [ E_PLAYER ] [ 1 ] ], ReturnPlayerName(g_poolTableData[ poolid ] [ E_PLAYER ] [ 1 ]));
						}
						else if (pool_player == g_poolTableData[ poolid ] [ E_PLAYER ] [ 1 ])
						{
							format(szNormalString, sizeof(szNormalString), "{FFDC2E}%s [%d] - [%d] %s", ReturnPlayerName(g_poolTableData[ poolid ] [ E_PLAYER ] [ 0 ]), p_PoolScore[ g_poolTableData[ poolid ] [ E_PLAYER ] [ 0 ] ], p_PoolScore[ pool_player ], ReturnPlayerName(pool_player));
						}

						UpdateDynamic3DTextLabelText(g_poolTableData[ poolid ] [ E_LABEL ], -1, szNormalString);
	    			}

					new Float: hole_x, Float: hole_y;

					// rotate hole offsets according to table
					RotateXY( g_poolPotOffsetData[ holeid ] [ 0 ], g_poolPotOffsetData[ holeid ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );

					// move object into the pocket
	    			MoveObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ j ], g_poolTableData[ poolid ] [ E_X ] + hole_x, g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ] - 0.5, 1.0);

	    			g_poolBallData[ poolid ] [ E_MOVING ] [ j ] = true;

	    			SetTimerEx("deleteBall", 500, false, "dd", poolid, j);

	    			PlayerPlaySound(pool_player, 31803, 0.0, 0.0, 0.0);

	    			if (( GetPoolBallsCount( poolid ) - 1) <= 1)
	    			{
	    				g_poolTableData[ poolid ] [ E_STARTED ] = false;
	    				g_poolTableData[ poolid ] [ E_AIMER ]   = -1;

	    				new
	    					win_score = GetMaxPoolScore( poolid );

	    				RestoreCamera(i, poolid);
	    				g_poolTableData[ poolid ] [ E_LAST_SHOOTER ] = -1;

	    				if ( IsPlayerPlayingPool( i ) && p_PoolScore[ i ] == win_score)
	    				{
	    					SendClientMessageToAllFormatted( -1, ""COL_POOL"[SERVER]"COL_WHITE" The winner is %s(%d) with %d points.", ReturnPlayerName(i), i, win_score);

	    					p_isPlayingPool{ i } 	= false;
	    					p_PoolScore[ i ]   		= -1;
	    					p_PoolID[ i ]      		= -1;
	    				}

	    				gameEnd(poolid);
	    			}
	    			else if (AreAllBallsStopped(poolid))
	    			{
	    				SetTimerEx("RestoreCamera", 800, 0, "dd", g_poolTableData[ poolid ] [ E_LAST_SHOOTER ], poolid);
	    				g_poolTableData[ i] [ E_LAST_SHOOTER ] = -1;
	    			}
	    		}
    		}
    	}
	}

	return 1;
}

/* ** Commands ** */

CMD:pool(playerid, params[])
{
	new selection[32];

	if ( sscanf( params, "s[32] ", selection) )
		return SendUsage(playerid, "/pool [INVITE/ACCEPT/DECLINE]" );

	if ( strmatch( selection, "accept") )
	{
		if ( !IsPlayerConnected(p_PoolSender[ playerid ]) )
			return SendError(playerid, "You do not have any pool game invitations to accept." );

		if ( IsPlayerPlayingPool( playerid ))
			return SendError(playerid, "You are already playing pool." );

		new targetid = p_PoolSender[ playerid ];

		if (GetDistanceBetweenPlayers(playerid, targetid) > 10.0)
		 	return SendError(playerid, "You must be within 10.0 meters of your opponent!");

		new poolid = p_PoolID[ playerid ];

		g_poolTableData[ poolid ] [ E_PLAYER ] [ 0 ] = playerid;
		g_poolTableData[ poolid ] [ E_PLAYER ] [ 1 ] = targetid;

		SendClientMessageFormatted(targetid, -1, ""COL_POOL"[SERVER]"COL_WHITE" %s(%d) has accepted your pool game invitation.", ReturnPlayerName(playerid), playerid);
		SendClientMessageFormatted(playerid, -1, ""COL_POOL"[SERVER]"COL_WHITE" You have accepted %s(%d)'s pool game invitation.", ReturnPlayerName(targetid), targetid);

		SendClientMessageFormatted(playerid, -1, ""COL_POOL"[SERVER]"COL_WHITE" %s(%d) will be breaking!", ReturnPlayerName(playerid), playerid);
		//UpdateDynamicLabel(poolid, 10000, "{C0C0C0}Pool Table\n{FFFFFF}%s(%d) will be breaking!", ReturnPlayerName(g_poolTableData[ poolid ] [poolPlayer] [startid]), g_poolTableData[ poolid ] [poolPlayer] [startid]);

		format(szNormalString, sizeof(szNormalString), "{FFDC2E}%s [0] - [0] %s", ReturnPlayerName(playerid), ReturnPlayerName(targetid));
		UpdateDynamic3DTextLabelText(g_poolTableData[ poolid ] [ E_LABEL ], -1, szNormalString);

		p_isPlayingPool{ playerid } 	= true;
		p_PoolID[ playerid ] 			= poolid;
		p_PoolScore[ playerid ] 		= 0;

		p_isPlayingPool{ targetid } 	= true;
		p_PoolID[ targetid ] 			= poolid;
		p_PoolScore[ targetid ] 		= 0;

		PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
		PlayerPlaySound(targetid, 1085, 0.0, 0.0, 0.0);

		GivePlayerWeapon(targetid, 7, 1);
		GivePlayerWeapon(playerid, 7, 1);

		if (!g_poolTableData[ poolid ] [ E_STARTED ])
		{
			g_poolTableData[ poolid ] [ E_STARTED ] = true;
			RespawnPoolBalls(poolid, 1);
		}
		return 1;
	}
	else if ( strmatch( selection, "decline") )
	{
		if ( !IsPlayerConnected( p_PoolSender[ playerid ]) )
			return SendError( playerid, "You do not have any pool game invitations to decline." );

		new targetid = p_PoolSender[ playerid ];

		SendClientMessageFormatted( targetid, -1, ""COL_POOL"[SERVER]{FFFFFF} %s(%d) has declined your pool game invitation.", ReturnPlayerName(playerid), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_POOL"[SERVER]{FFFFFF} You have declined %s(%d)'s pool game invitation.", ReturnPlayerName(targetid), targetid );

		return 1;
	}
	else if (strmatch(selection, "invite"))
	{
		new id = -1, targetid;

		id = getNearestPoolTable(playerid);

		if (id == -1)
			return SendError(playerid, "You are not close enough to a pool table.");

		if (g_poolTableData[ id ] [ E_STARTED ])
			return SendError(playerid, "You cannot invite anyone to this table, since there is already a game in progress.");

		if (sscanf(params, "s[32] u", selection, targetid))
			return SendUsage(playerid, "/pool invite [PLAYER_ID]");

		if (targetid == playerid)
			return SendError(playerid, "You cannot play pool with yourself!");

		if (targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
			return SendError(playerid, "Invalid Player ID.");

		if ( IsPlayerPlayingPool( targetid ))
			return SendError(playerid, "This player is already playing pool!");

		//if (GetDistanceBetweenPlayers(playerid, targetid) > 10.0)
			//return SendError(playerid, "The player you wish to play pool with is not near you.");

		if (GetPlayerWantedLevel(playerid))
			return SendError(playerid, "You can't play pool with this person right now, they are wanted");

		// if (IsPlayerJailed(targetid))
		// 	return SendError(playerid, "You can't play pool with this person right now, they are currently in jail.");

		p_PoolSender[ targetid ] 	= playerid;
		p_PoolReciever[ playerid ] 	= targetid;
		p_PoolID[ targetid ] 		= id;

		SendClientMessageFormatted(playerid, -1, ""COL_POOL"[SERVER]{FFFFFF} You have sent a pool game invitation to %s(%d)!", ReturnPlayerName(targetid), targetid);

		SendClientMessageFormatted(targetid, -1, ""COL_POOL"[SERVER]{FFFFFF} You have recieved a pool game invitation by %s(%d)!", ReturnPlayerName(playerid), playerid);
		SendClientMessageFormatted(targetid, -1, ""COL_POOL"[SERVER]{FFFFFF} To accept or decline the invite, use /pool [ACCEPT/DECLINE]");
	}
	else
	{
		SendUsage(playerid, "/pool [INVITE/ACCEPT/DECLINE]");
	}

	return 1;
}

CMD:endgame(playerid)
{
	if ( ! IsPlayerAdmin( playerid ) )
		return 0;

	new iPool = getNearestPoolTable( playerid );

	if ( iPool == -1 )
		return SendError( playerid, "You must be near a pool table to use this command." );

	gameEnd( iPool );

	SendClientMessage(playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have force ended the pool game!");
	return 1;
}

CMD:play(playerid)
{
	new
		iPool = getNearestPoolTable( playerid );

	if ( iPool == -1 )
		return SendError( playerid, "You are not near a pool table." );

	if ( ! IsPlayerPlayingPool( playerid ))
	{
		p_isPlayingPool { playerid } = true;
		p_PoolID[ playerid ]		 = iPool;

		PlayerPlaySound( playerid, 1085, 0.0, 0.0, 0.0 );
		GivePlayerWeapon( playerid, 7, 1 );

		p_PoolScore[ playerid ] = 0;

		if (!g_poolTableData[ iPool ] [ E_STARTED ])
		{
			g_poolTableData[ iPool ] [ E_STARTED ] = true;

			UpdateDynamic3DTextLabelText(g_poolTableData[ iPool ] [ E_LABEL ], -1, sprintf( "{FFDC2E}%s is currently playing a test game.", ReturnPlayerName( playerid )) );

			RespawnPoolBalls(iPool, 1);
		}
	}
	else
	{
		gameEnd(iPool);
	}

	return 1;
}

/* ** Commands ** */

CMD:addpool(playerid, params[])
{
	if ( p_AdminLevel[ playerid ] < 6 )
		return SendError( playerid, ADMIN_COMMAND_REJECT );

	new
		Float: x, Float: y, Float: z;

	if ( GetPlayerPos( playerid, x, y, z ) )
	{
		CreatePoolTable( x + 1.0, y + 1.0, z, floatstr(params), GetPlayerInterior( playerid ), GetPlayerVirtualWorld( playerid ) );
		SendClientMessage(playerid, -1, ""COL_PINK"[ADMIN]{FFFFFF} You have created a pool table.");
	}
	return 1;
}

/* ** Debug Mode ** */
#if defined POOL_DEBUG
	new potlabels_x[MAX_TABLES][sizeof(g_poolPotOffsetData)];
	new potlabels[MAX_TABLES][sizeof(g_poolPotOffsetData)][36];

	CMD:camtest( playerid, params[ ] )
	{
		new
			iPool = getNearestPoolTable( playerid );

		if ( iPool == -1 )
			return SendError( playerid, "You are not near a pool table." );

		new
			index = strval( params );

		new Float: pot_x = g_poolTableData[ iPool ] [ E_X ] + g_poolPotOffsetData[ index ] [ 0 ];
		new Float: pot_y = g_poolTableData[ iPool ] [ E_Y ] + g_poolPotOffsetData[ index ] [ 1 ];
		new Float: pot_z = g_poolTableData[ iPool ] [ E_Z ];

		SetPlayerCameraPos(playerid, pot_x, pot_y, pot_z + 2.5);
		SetPlayerCameraLookAt(playerid, pot_x, pot_y, pot_z);
		return 1;
	}

	CMD:setoffset( playerid, params[ ] )
	{
		new iPool = getNearestPoolTable( playerid );
		new offset;
		new Float: x, Float: y;

		if ( ! sscanf( params, "dff", offset, x, y ) )
		{
			g_poolPotOffsetData[ offset ] [ 0 ] = x;
			g_poolPotOffsetData[ offset ] [ 1 ] = y;
			printf("[%d] -> { %f, %f }", offset, x, y);
			ReloadPotTestLabel( playerid, iPool );
		}
		return 1;
	}

	stock ReloadPotTestLabel( playerid, gID )
	{
		for ( new i = 0; i < sizeof( g_poolPotOffsetData ); i ++ )
		{
			new Float: pot_x = g_poolTableData[ gID ] [ E_X ] + g_poolPotOffsetData[ i ] [ 0 ];
			new Float: pot_y = g_poolTableData[ gID ] [ E_Y ] + g_poolPotOffsetData[ i ] [ 1 ];
			new Float: pot_z = g_poolTableData[ gID ] [ E_Z ];

			//DestroyDynamic3DTextLabel( potlabels_x[ gID ] [ i ] );
			//potlabels_x[ gID ] [ i ] = CreateDynamic3DTextLabel( "+", COLOR_GOLD, pot_x, pot_y, pot_z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0 );
			DestroyDynamicObject( potlabels_x[ gID ] [ i ] );
			potlabels_x[ gID ] [ i ] = CreateDynamicObject( 18643, pot_x, pot_y, pot_z - 1.0, 0.0, -90.0, 0.0 );

			for ( new Float: angle = 0.0, c = 0; angle < 360.0; angle += 10.0, c ++ )
			{
			    new Float: rad_x = pot_x + ( POCKET_RADIUS * floatsin( -angle, degrees ) );
			    new Float: rad_y = pot_y + ( POCKET_RADIUS * floatcos( -angle, degrees ) );

				//DestroyDynamic3DTextLabel( potlabels[ gID ] [ i ] [ c ] );
				//potlabels[ gID ] [ i ] [ c ] = CreateDynamic3DTextLabel( ".", COLOR_WHITE, rad_x, rad_y, pot_z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0 );
				DestroyDynamicObject( potlabels[ gID ] [ i ] [ c ] );
				potlabels[ gID ] [ i ] [ c ] = CreateDynamicObject( 18643, rad_x, rad_y, pot_z - 1.0, 0.0, -90.0, 0.0 );
			}
		}
		return Streamer_Update( playerid ), 1;
	}
#endif
