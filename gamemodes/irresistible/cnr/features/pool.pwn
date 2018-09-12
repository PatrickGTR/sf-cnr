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

/* ** Marcos ** */
#define IsPlayerPlayingPool(%0) 	(p_isPlayingPool{%0})

/* ** Definitions ** */
#define POCKET_RADIUS 				0.09
#define POOL_TIMER_SPEED 			30
#define DEFAULT_AIM 				0.38
#define DEFAULT_POOL_STRING 		"Pool Table\n{FFFFFF}Press ENTER To Play"

#define MAX_TABLES 					32
#define COL_POOL 					"{C0C0C0}"

/* ** Macros ** */
#define SendPoolMessage(%0,%1) \
	SendClientMessageFormatted(%0, -1, "{4B8774}[POOL] {E5861A}" # %1)


/* ** Constants (do not modify) ** */
enum E_POOL_BALL_TYPE {
	E_STRIPED,
	E_SOLID,
	E_CUE,
	E_8BALL
};

enum E_POOL_BALL_OFFSET_DATA
{
	E_MODEL_ID, 					E_BALL_NAME[ 9 ],				E_POOL_BALL_TYPE: E_BALL_TYPE,
	Float: E_OFFSET_X, 				Float: E_OFFSET_Y
};

static const
	g_poolBallOffsetData[ ] [ E_POOL_BALL_OFFSET_DATA ] =
	{
		{ 3003, "Cueball", 	E_CUE, 		0.5000, 0.0000 },
		{ 3002, "One",		E_SOLID,	-0.300, 0.0000 },
		{ 3100, "Two",		E_SOLID, 	-0.525, -0.040 },
		{ 3101, "Three",	E_SOLID,	-0.375, 0.0440 },
		{ 3102, "Four",		E_SOLID,	-0.600, 0.0790 },
		{ 3103,	"Five",		E_SOLID,	-0.525, 0.1180 },
		{ 3104,	"Six",		E_SOLID,	-0.600, -0.157 },
		{ 3105, "Seven",	E_SOLID,	-0.450, -0.079 },
		{ 3106,	"Eight",	E_8BALL,	-0.450, 0.0000 },
		{ 2995, "Nine",		E_STRIPED,	-0.375, -0.044 },
		{ 2996, "Ten",		E_STRIPED,	-0.450, 0.0790 },
		{ 2997, "Eleven",	E_STRIPED,	-0.525, -0.118 },
		{ 2998, "Twelve",	E_STRIPED,	-0.600, -0.079 },
		{ 2999, "Thirteen",	E_STRIPED,	-0.600, 0.0000 },
		{ 3000, "Fourteen",	E_STRIPED,	-0.600, 0.1570 },
		{ 3001, "Fiftteen",	E_STRIPED,	-0.525, 0.0400 }
	},
	Float: g_poolPotOffsetData[ ] [ ] =
	{
		{ 0.955, 0.510 }, { 0.955, -0.49 },
		{ 0.005, 0.550 }, { 0.007, -0.535 },
		{ -0.945, 0.513 }, { -0.945, -0.490 }
	},
	g_poolHoleOpposite[ sizeof( g_poolPotOffsetData ) ] = { 5, 4, 3, 2, 1, 0 }
;

/* ** Variables ** */
enum E_POOL_BALL_DATA
{
	E_BALL_OBJECT[ 16 ],			bool: E_EXISTS[ 16 ], 			bool: E_MOVING[ 16 ]
};

enum E_POOL_TABLE_DATA
{
	Float: E_X,						Float: E_Y, 					Float: E_Z,
	Float: E_ANGLE, 				E_WORLD, 						E_INTERIOR,

	E_TIMER, 						E_BALLS_SCORED, 				E_POOL_BALL_TYPE: E_PLAYER_BALL_TYPE[ MAX_PLAYERS ],
	bool: E_STARTED, 				E_AIMER, 						E_AIMER_OBJECT,
	E_NEXT_SHOOTER,

	E_SHOTS_LEFT,					E_FOULS,						E_PLAYER_8BALL_TARGET[ MAX_PLAYERS ],

	Float: E_POWER,					E_DIRECTION,

	E_TABLE,						Text3D: E_LABEL,
}

new
	g_poolTableData 				[ MAX_TABLES ] [ E_POOL_TABLE_DATA ],
	g_poolBallData 					[ MAX_TABLES ] [ E_POOL_BALL_DATA ],

	p_PoolID 						[ MAX_PLAYERS ] = { -1, ... },

	bool: p_isPlayingPool			[ MAX_PLAYERS char ],
	bool: p_PoolChalking			[ MAX_PLAYERS char ],
	p_PoolCamera 					[ MAX_PLAYERS ],
	p_PoolScore 					[ MAX_PLAYERS ],
	p_PoolHoleGuide 				[ MAX_PLAYERS ] = { -1, ... },
	Float: p_PoolAngle 				[ MAX_PLAYERS ] [ 2 ],

	PlayerBar: g_PoolPowerBar 		[ MAX_PLAYERS ],
	Text: g_PoolTextdraw			= Text: INVALID_TEXT_DRAW,

	Iterator: pooltables 			< MAX_TABLES >,
	Iterator: poolplayers 			< MAX_TABLES, MAX_PLAYERS >
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
	// textdraws
	g_PoolTextdraw = TextDrawCreate(529.000000, 218.000000, "Power");
	TextDrawBackgroundColor(g_PoolTextdraw, 255);
	TextDrawFont(g_PoolTextdraw, 1);
	TextDrawLetterSize(g_PoolTextdraw, 0.300000, 1.299998);
	TextDrawColor(g_PoolTextdraw, -1);
	TextDrawSetOutline(g_PoolTextdraw, 1);
	TextDrawSetProportional(g_PoolTextdraw, 1);
	TextDrawSetSelectable(g_PoolTextdraw, 0);

	// create static pooltables
	CreatePoolTable( 2048.5801, 1330.8917, 10.6719, 0, 0 );
	//  CreatePoolTable(Float: X, Float: Y, Float: Z, Float: A = 0.0, interior = 0, world = 0)

	printf( "[POOL TABLES]: %d pool tables have been successfully loaded.", Iter_Count( pooltables ) );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	Pool_RemovePlayer( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	Pool_RemovePlayer( playerid );
	return 1;
}

hook OnPlayerConnect( playerid )
{
	g_PoolPowerBar[ playerid ] = CreatePlayerProgressBar( playerid, 530.000000, 233.000000, 61.000000, 6.199999, -1429936641, 100.0000, 0 );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	new Float: pooltable_distance = 99999.99;
	new poolid = GetClosestPoolTable( playerid, pooltable_distance );

	if ( poolid != -1 && pooltable_distance < 2.5 )
	{
		if ( g_poolTableData[ poolid ] [ E_STARTED ] )
		{
			// make pressing key fire annoying
			if ( RELEASED( KEY_FIRE ) && g_poolTableData[ poolid ] [ E_AIMER ] != playerid && ! p_PoolChalking{ playerid } )
			{
				if ( IsPlayerPlayingPool( playerid ) )
				{
					p_PoolChalking{ playerid } = true;

					SetPlayerArmedWeapon( playerid, 0 );
					SetPlayerAttachedObject( playerid, 0, 338, 6, 0, 0.07, -0.85, 0, 0, 0 );
					ApplyAnimation( playerid, "POOL", "POOL_ChalkCue", 3.0, 0, 0, 0, 0, 0, 1 );

					SetTimerEx( "PlayPoolSound", 1400, false, "dd", playerid, 31807 );
					SetTimerEx( "RestoreWeapon", 3500, false, "d", playerid );
				}
				else
				{
					ClearAnimations( playerid );
				}
				return 1;
			}

			// begin gameplay stuff
			if ( IsPlayerPlayingPool( playerid ) && p_PoolID[ playerid ] == poolid )
			{
				if ( RELEASED( KEY_JUMP ) )
				{
					if (g_poolTableData[ poolid ] [ E_AIMER ] == playerid)
					{
						if (p_PoolCamera[ playerid ] < 2) p_PoolCamera[ playerid ] ++;
						else p_PoolCamera[ playerid ] = 0;

						new Float:poolrot = p_PoolAngle[ playerid ] [ 0 ],
							Float:Xa,
							Float:Ya,
							Float:Za,
							Float:x,
							Float:y;

						GetObjectPos(g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ], Xa, Ya, Za);

						switch (p_PoolCamera[ playerid ])
						{
							case 0:
							{
								GetXYBehindObjectInAngle(g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ], poolrot, x, y, 0.675);
								SetPlayerCameraPos(playerid, x, y, g_poolTableData[ poolid ] [ E_Z ] + DEFAULT_AIM);
								SetPlayerCameraLookAt(playerid, Xa, Ya, Za + 0.170);
							}
							case 1 .. 2:
							{
								SetPlayerCameraPos(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0);
								SetPlayerCameraLookAt(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ]);
							}
						}
					}
				}

				if ( RELEASED( KEY_HANDBRAKE ) )
				{
					if ( AreAllBallsStopped( poolid ) )
					{
						if ( g_poolTableData[ poolid ] [ E_AIMER ] != playerid )
						{
							if ( g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] != playerid ) {
								return SendError( playerid, "It is not your turn. Please wait." );
							}

							if ( ! p_PoolChalking{ playerid } && g_poolTableData[ poolid ] [ E_AIMER ] == -1 )
							{
								new Float:poolrot,
									Float:X, Float:Y, Float:Z,
									Float:Xa, Float:Ya, Float:Za,
									Float:x, Float:y;

								GetPlayerPos( playerid, X, Y, Z );
								GetObjectPos( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ], Xa, Ya, Za );

								new Float: distance_to_ball = GetDistanceFromPointToPoint( X, Y, Xa, Ya );

								if ( distance_to_ball < 1.5 && Z < 999.5 )
								{
									printf( "Distance To Ball %f", distance_to_ball );

									TogglePlayerControllable(playerid, false);
									GetAngleToXY(Xa, Ya, X, Y, poolrot);
	                            	SetPlayerFacingAngle(playerid, poolrot);

	                            	p_PoolAngle[ playerid ] [ 0 ] = poolrot;
	                            	p_PoolAngle[ playerid ] [ 1 ] = poolrot;

									SetPlayerArmedWeapon(playerid, 0);
									GetXYInFrontOfPos(Xa, Ya, poolrot + 180, x, y, 0.085);
									g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] = CreateObject(3004, x, y, Za, 7.0, 0, poolrot + 180);

									SetPlayerCameraPos(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0);

									ApplyAnimation(playerid, "POOL", "POOL_Med_Start", 50.0, 0, 0, 0, 1, 1, 1);

									g_poolTableData[ poolid ] [ E_AIMER ] = playerid;
									g_poolTableData[ poolid ] [ E_POWER ] = 1.0;
									g_poolTableData[ poolid ] [ E_DIRECTION ] = 0;

									Pool_UpdateScoreboard( poolid );

									TextDrawShowForPlayer( playerid, g_PoolTextdraw );
									ShowPlayerProgressBar( playerid, g_PoolPowerBar[playerid] );
								}
							}
						}
						else
						{
							TogglePlayerControllable(playerid, true);
							GivePlayerWeapon(playerid, 7, 1);

							ApplyAnimation(playerid, "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0, 1);
	            			SetCameraBehindPlayer(playerid);

	            			g_poolTableData[ poolid ] [ E_AIMER ] = -1;
	            			DestroyObject(g_poolTableData[ poolid ] [ E_AIMER_OBJECT ]);
						}
					}
				}

				if ( RELEASED( KEY_FIRE ) )
				{
					if ( g_poolTableData[ poolid ] [ E_AIMER ] == playerid )
					{
						new
							Float: speed;

						g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] --;

						Pool_UpdateScoreboard( poolid );
						ApplyAnimation( playerid, "POOL", "POOL_Med_Shot", 3.0, 0, 0, 0, 0, 0, 1 );

						speed = 0.4 + (g_poolTableData[ poolid ] [ E_POWER ] * 2.0) / 100.0;
						PHY_SetObjectVelocity(g_poolBallData[poolid] [E_BALL_OBJECT] [0], speed * floatsin(-p_PoolAngle[ playerid ] [ 0 ], degrees), speed * floatcos(-p_PoolAngle[ playerid ] [ 0 ], degrees));

						SetPlayerCameraPos(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0);
						SetPlayerCameraLookAt(playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ]);

						PlayPoolSound(poolid, 31810);
						g_poolTableData[ poolid ] [ E_AIMER ] = -1;
						DestroyObject( g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] );

						GivePlayerWeapon( playerid, 7, 1 );
					}
					else ClearAnimations(playerid);
				}
			}
		}
		else
		{
			if ( PRESSED( KEY_SECONDARY_ATTACK ) )
			{
				if ( IsPlayerPlayingPool( playerid ) ) {
					Pool_SendTableMessage( poolid, COLOR_GREY, "*** %s(%d) has left the table", ReturnPlayerName( playerid ), playerid );
					return Pool_RemovePlayer( playerid );
				}

				new
					pool_player_count = Iter_Count( poolplayers< poolid > );

				if ( pool_player_count >= 2 ) {
					return SendError( playerid, "This pool table is currently full." );
				}

				// ensure this player isn't already joined
				if ( ! IsPlayerPlayingPool( playerid ) && ! Iter_Contains( poolplayers< poolid >, playerid ) )
				{
					Iter_Add( poolplayers< poolid >, playerid );

					// reset variables
					p_isPlayingPool{ playerid } = true;
					p_PoolID[ playerid ] = poolid;

					// start the game if there's two players
					if ( pool_player_count + 1 >= 2 )
					{
					    new
					    	random_cuer = Iter_Random( poolplayers< poolid > );

						Pool_SendTableMessage( poolid, COLOR_GREY, "*** %s(%d) has joined the table (2/2)", ReturnPlayerName( playerid ), playerid );
					    Pool_QueueNextPlayer( poolid, random_cuer );

					    foreach ( new i : poolplayers< poolid > ) {
							p_PoolScore[ i ] = 0;
							PlayerPlaySound( i, 1085, 0.0, 0.0, 0.0 );
							GivePlayerWeapon( i, 7, 1 );
					    }

						g_poolTableData[ poolid ] [ E_STARTED ] = true;
				    	Pool_UpdateScoreboard( poolid );
						RespawnPoolBalls( poolid );
					}
					else
					{
						UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], -1, sprintf( "" # COL_GREY "Pool Table\n{FFFFFF}Press ENTER To Join %s(%d)", ReturnPlayerName( playerid ), playerid ) );
						Pool_SendTableMessage( poolid, COLOR_GREY, "*** %s(%d) has joined the table (1/2)", ReturnPlayerName( playerid ), playerid );
					}
					return 1;
				}
			}
		}
	}
	return 1;
}

stock Pool_RemovePlayer( playerid )
{
	new
		poolid = p_PoolID[ playerid ];

	// reset player variables
	p_isPlayingPool{ playerid } = false;
	p_PoolScore[ playerid ] = 0;
	p_PoolID[ playerid ] = -1;
	DestroyDynamicObject( p_PoolHoleGuide[ playerid ] );
	p_PoolHoleGuide[ playerid ] = -1;

	// check if the player is even in the table
	if ( poolid != -1 && Iter_Contains( poolplayers< poolid >, playerid ) )
	{
		// remove them from the table
		Iter_Remove( poolplayers< poolid >, playerid );

		// forfeit player
		if ( g_poolTableData[ poolid ] [ E_STARTED ] )
		{
			new
				replacement_winner = Iter_First( poolplayers< poolid > ); // there's only 1 guy in the table

			Pool_OnPlayerWin( poolid, replacement_winner );
			return Pool_EndGame( poolid );
		}
		else
		{
			UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], COLOR_GREY, DEFAULT_POOL_STRING );
		}
	}
	return 1;
}

/* ** Functions ** */
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
		g_poolTableData[ gID] [ E_LABEL ] = CreateDynamic3DTextLabel( DEFAULT_POOL_STRING, COLOR_GREY, X, Y, Z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, world, interior );

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

stock GetClosestPoolTable( playerid, &Float: dis = 99999.99 )
{
	new
		pooltable = -1;

	foreach ( new i : pooltables )
	{
    	new
    		Float: dis2 = GetPlayerDistanceFromPoint( playerid, g_poolTableData[ i ] [ E_X ], g_poolTableData[ i ] [ E_Y ], g_poolTableData[ i ] [ E_Z ] );

    	if ( dis2 < dis && dis2 != -1.00 )
    	{
    	    dis = dis2;
    	    pooltable = i;
		}
	}
	return pooltable;
}

stock RespawnPoolBalls( poolid )
{
	if ( g_poolTableData[ poolid ] [ E_AIMER ] != -1 )
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

	new
		Float: offset_x,
		Float: offset_y;

	for ( new i = 0; i < sizeof( g_poolBallOffsetData ); i ++ )
	{
		// get offset according to angle of table
		RotateXY( g_poolBallOffsetData[ i ] [ E_OFFSET_X ], g_poolBallOffsetData[ i ] [ E_OFFSET_Y ], g_poolTableData[ poolid ] [ E_ANGLE ], offset_x, offset_y );

		// reset balls
		if ( g_poolBallData[ poolid ] [ E_EXISTS ] [ i ] ) {
			PHY_DeleteObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] );
			g_poolBallData[ poolid ] [ E_EXISTS ] [ i ] = false;
		}
		DestroyObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] );

		// create pool balls on table
		g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] = CreateObject(
			g_poolBallOffsetData[ i ] [ E_MODEL_ID ],
			g_poolTableData[ poolid ] [ E_X ] + offset_x,
			g_poolTableData[ poolid ] [ E_Y ] + offset_y,
			g_poolTableData[ poolid ] [ E_Z ] - 0.045,
			0.0, 0.0, 0.0
		);

		// initialize physics on each ball
		InitBalls( poolid, i );
	}

	KillTimer( g_poolTableData[ poolid ] [ E_TIMER ] );
	g_poolTableData[ poolid ] [ E_TIMER ] = SetTimerEx( "OnPoolUpdate", POOL_TIMER_SPEED, true, "d", poolid );
	g_poolTableData[ poolid ] [ E_BALLS_SCORED ] = 0;
}

stock InitBalls(poolid, ballid)
{
	PHY_InitObject(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 3003, _, _, PHY_MODE_2D);

	PHY_SetObjectFriction(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 0.08);
	//PHY_SetObjectFriction(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 0.10);
	PHY_SetObjectAirResistance(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid], 0.2);
	PHY_RollObject(g_poolBallData[poolid] [E_BALL_OBJECT] [ballid]);

	g_poolBallData[ poolid ] [ E_EXISTS ] [ ballid ] = true;
}

stock RotateXY( Float: xi, Float: yi, Float: angle, &Float: xf, &Float: yf )
{
    xf = xi * floatcos( angle, degrees ) - yi * floatsin( angle, degrees );
    yf = xi * floatsin( angle, degrees ) + yi * floatcos( angle, degrees );
    return 1;
}

stock GetXYBehindObjectInAngle(objectid, Float:a, &Float:x2, &Float:y2, Float:distance)
{
    new Float:z;
    GetObjectPos(objectid, x2, y2, z);

    x2 += (distance * floatsin(-a+180, degrees));
    y2 += (distance * floatcos(-a+180, degrees));
}

stock AreAllBallsStopped( poolid )
{
	new
		Float: x, Float: y, Float: z;

	for ( new i = 0; i < 16; i ++ ) if ( g_poolBallData[ poolid ] [ E_EXISTS ] [ i ] )
	{
		PHY_GetObjectVelocity( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ], x, y, z );

		if ( x != 0.0 || y != 0.0 )
			return 0;
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

stock removePlayerWeapon(playerid, weaponid)
{
	SetPlayerArmedWeapon(playerid, weaponid);

	if (GetPlayerWeapon(playerid) != 0)
		GivePlayerWeapon(playerid, weaponid, 0);

	return 1;
}

stock Pool_UpdateScoreboard( poolid, close = 0 )
{
	new first_player = Iter_First( poolplayers< poolid > );
	new second_player = Iter_Last( poolplayers< poolid > );

	foreach ( new playerid : poolplayers< poolid > )
	{
		new
			is_playing = playerid == first_player ? first_player : ( playerid == second_player ? second_player : -1 );

		if ( g_poolTableData[ poolid ] [ E_BALLS_SCORED ] && is_playing != -1 ) {
			format(
				szBigString, sizeof( szBigString ), "You are %s. ",
				g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ is_playing ] == E_STRIPED ? ( "striped" ) : ( "solid" )
			);
		} else {
			szBigString = "";
		}

		format( szBigString, sizeof( szBigString ),
			"%sIt's %s's turn.~n~~n~~r~~h~~h~%s Score:~w~ %d~n~~b~~h~~h~%s Score:~w~ %d",
			szBigString, ReturnPlayerName( g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] ),
			ReturnPlayerName( first_player ), p_PoolScore[ first_player ],
			ReturnPlayerName( second_player ), p_PoolScore[ second_player ]
		);

		ShowPlayerHelpDialog( playerid, close, szBigString );
	}

	UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], -1, "" );
}

stock Pool_EndGame( poolid )
{
	// hide scoreboard in 5 seconds
	Pool_UpdateScoreboard( poolid, 5000 );

	// unset pool variables
	foreach ( new i : poolplayers< poolid > )
	{
		DestroyDynamicObject( p_PoolHoleGuide[ i ] );
		p_PoolHoleGuide[ i ] = -1;
		p_isPlayingPool{ i } = false;
		p_PoolScore[ i ] = -1;
		p_PoolID[ i ] = -1;
		removePlayerWeapon( i, 7 );
	}

	Iter_Clear( poolplayers< poolid > );

	g_poolTableData[ poolid ] [ E_STARTED ] = false;
	g_poolTableData[ poolid ] [ E_AIMER ]   = -1;
	g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 0;
	g_poolTableData[ poolid ] [ E_FOULS ] = 0;

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

	UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], COLOR_GREY, DEFAULT_POOL_STRING );
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

public PlayPoolSound( poolid, soundid ) {
	foreach ( new playerid : poolplayers< poolid > ) {
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
				GetObjectPos(g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ], Xa, Ya, Za);
				newrot = p_PoolAngle[ playerid ] [ 0 ] + (lr > 0 ? 0.9 : -0.9);
				dist = GetDistanceBetweenPoints( X, Y, 0.0, Xa, Ya, 0.0 );

				if (AngleInRangeOfAngle(p_PoolAngle[ playerid ] [ 1 ], newrot, 30.0))
	            {
	                p_PoolAngle[ playerid ] [ 0 ] = newrot;
					switch (p_PoolCamera[ playerid ])
					{
						case 0:
						{
							GetXYBehindObjectInAngle(g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ], newrot, x, y, 0.675);

							SetPlayerCameraPos(playerid, x, y, g_poolTableData[ poolid ] [ E_Z ] + DEFAULT_AIM);
							SetPlayerCameraLookAt(playerid, Xa, Ya, Za + 0.170);
						}
						case 1, 2:
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
			    g_poolTableData[ poolid ] [ E_POWER ] = 100.0;
			}

			// TextDrawTextSize(g_PoolTextdraw[2], 501.0 + ((67.0 * g_poolTableData[ poolid ] [ E_POWER ])/100.0), 0.0);
			// TextDrawShowForPlayer(playerid, g_PoolTextdraw[2]);

			// ShowPlayerPoolTextdraw(playerid);

			SetPlayerProgressBarMaxValue(playerid, g_PoolPowerBar[playerid], 67.0);
			SetPlayerProgressBarValue(playerid, g_PoolPowerBar[playerid], ((67.0 * g_poolTableData[ poolid ] [ E_POWER ])/100.0));
			ShowPlayerProgressBar(playerid, g_PoolPowerBar[playerid]);

			TextDrawShowForPlayer(playerid, g_PoolTextdraw);
		}
	}

	new
		current_player = g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ];

	if ( ! g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] && AreAllBallsStopped( poolid ) )
	{
		Pool_ResetBallPositions( poolid );
		Pool_QueueNextPlayer( poolid, current_player );
    	SetTimerEx( "RestoreCamera", 800, 0, "dd", current_player, poolid );
	}
	return 1;
}

public RestoreCamera(playerid, poolid)
{
	if (!g_poolBallData[poolid] [E_EXISTS] [0])
	{
        DestroyObject(g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ]);

        new Float: x, Float: y, Float: pos[3], Float: angle;

		pos[0] = g_poolTableData[ poolid ] [ E_X ];
		pos[1] = g_poolTableData[ poolid ] [ E_Y ];
		pos[2] = g_poolTableData[ poolid ] [ E_Z ];
		angle =  g_poolTableData[ poolid ] [ E_ANGLE ];

		RotateXY(0.5, 0.0, angle, x, y);
		g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ] = CreateObject(3003, x + pos[0], y + pos[1], (pos[2] - 0.045), 0, 0, 0);

        InitBalls(poolid, 0);
	}

	if (g_poolTableData[ poolid ] [ E_AIMER ] == playerid)
		return 0;

	TextDrawHideForPlayer(playerid, g_PoolTextdraw);
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

public RestoreWeapon( playerid )
{
	RemovePlayerAttachedObject( playerid, 0 );
	p_PoolChalking{ playerid } = false;
	GivePlayerWeapon( playerid, 7, 1 );
	ClearAnimations( playerid );
	return 1;
}

stock GetPoolBallIndexFromModel( modelid ) {
	for ( new i = 0; i < sizeof( g_poolBallOffsetData ); i ++ ) if ( g_poolBallOffsetData[ i ] [ E_MODEL_ID ] == modelid ) {
		return i;
	}
	return -1;
}

/** * Physics Callbacks * **/
public PHY_OnObjectCollideWithObject(object1, object2)
{
	foreach ( new id : pooltables ) if ( g_poolTableData[ id ] [ E_STARTED ] )
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
	foreach ( new id : pooltables ) if ( g_poolTableData[ id ] [ E_STARTED ] )
	{
		for ( new i = 0; i < 16; i ++ ) if ( objectid == g_poolBallData[ id ] [ E_BALL_OBJECT ] [ i ] )
		{
	        PlayPoolSound(id, 31808);
	        return 1;
		}
	}
	return 1;
}

public PHY_OnObjectUpdate( objectid )
{
	foreach ( new poolid : pooltables ) if ( g_poolTableData[ poolid ] [ E_STARTED ] )
	{
		for ( new j = 0; j < 16; j ++ ) if ( objectid == g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ j ] && ! g_poolBallData[ poolid ] [ E_MOVING ] [ j ] && PHY_IsObjectMoving( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ j ] ) )
		{
			new
				holeid = IsBallInHole( poolid, objectid );

			if ( holeid != -1 )
			{
				new first_player = Iter_First( poolplayers< poolid > );
				new second_player = Iter_Last( poolplayers< poolid > );
				new current_player = g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ];
				new poolball_index = GetPoolBallIndexFromModel( GetObjectModel( objectid ) );

				// printf ("first_player %d, second_player %d, current_player = %d", first_player, second_player, current_player);

				// check if first ball was pocketed to figure winner
				if ( g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_STRIPED || g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_SOLID )
				{
					if ( ++ g_poolTableData[ poolid ] [ E_BALLS_SCORED ] == 1 )
					{
						// assign first player a type after first one is hit
						g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ current_player ] = g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ];

						// assign second player
						if ( current_player == first_player ) {
							g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ second_player ] = g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ first_player ] == E_STRIPED ? E_SOLID : E_STRIPED;
						} else if ( current_player == second_player ) {
							g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ first_player ] = g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ second_player ] == E_STRIPED ? E_SOLID : E_STRIPED;
						}

						// alert players in table
						foreach ( new playerid : poolplayers< poolid > ) {
							Player_Clearchat( playerid );
	    					SendClientMessageFormatted( playerid, COLOR_YELLOW, "* %s(%d) is now playing as %s", ReturnPlayerName( first_player ), first_player, g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ first_player ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ) );
	    					SendClientMessageFormatted( playerid, COLOR_YELLOW, "* %s(%d) is playing as %s", ReturnPlayerName( second_player ), second_player, g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ second_player ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ) );
	    				}
	    			}
				}

				new Float: hole_x, Float: hole_y;

				// check what was pocketed
				if ( g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_CUE )
				{
					GameTextForPlayer( current_player, "~n~~n~~n~~r~~h~You have pocketed the cue ball!", 10000, 4 );

					// respawn the cue ball
				    if ( ! g_poolBallData[ poolid ] [ E_EXISTS ] [ 0 ] )
					{

				        new
				        	Float: x, Float: y;

						RotateXY( 0.5, 0.0, g_poolTableData[ poolid ] [ E_ANGLE ], x, y );

				        DestroyObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ] );
						g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ 0 ] = CreateObject( 3003, g_poolTableData[ poolid ] [ E_X ] + x, g_poolTableData[ poolid ] [ E_Y ] + y, g_poolTableData[ poolid ] [ E_Z ], 0.0, 0.0, 0.0 );

				        InitBalls( poolid, 0 );
					}

					// penalty for that
					g_poolTableData[ poolid ] [ E_FOULS ] ++;
					g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 0;
				}
				else if ( g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_8BALL )
				{
					new
						opposite_player = current_player != first_player ? first_player : second_player;

					g_poolTableData[ poolid ] [ E_BALLS_SCORED ] ++;

					// restore player camera
					RestoreCamera( current_player, poolid );

					// check if valid shot
					if ( p_PoolScore[ current_player ] < 7 )
					{
						Pool_SendTableMessage( poolid, COLOR_YELLOW, "%s(%d) has accidentally pocketed the 8-Ball ... %s(%d) wins!", ReturnPlayerName( current_player ), current_player, ReturnPlayerName( opposite_player ), opposite_player );
					}
					else if ( g_poolTableData[ poolid ] [ E_PLAYER_8BALL_TARGET ] [ current_player ] != holeid )
					{
						Pool_SendTableMessage( poolid, COLOR_YELLOW, "%s(%d) has put the 8-Ball in the wrong pocket ... %s(%d) wins!", ReturnPlayerName( current_player ), current_player, ReturnPlayerName( opposite_player ), opposite_player );
					}
					else
					{
						p_PoolScore[ current_player ] ++; // shows on the end result if we do it anyway here
						Pool_OnPlayerWin( poolid, current_player );
					}
					return Pool_EndGame( poolid );
				}
				else
				{
					// check if player pocketed their own ball type or btfo
					if ( g_poolTableData[ poolid ] [ E_BALLS_SCORED ] > 1 && g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ current_player ] != g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] )
					{
						new
							opposite_player = current_player == first_player ? second_player : first_player;

	    				p_PoolScore[ opposite_player ] += 1;
	    				GameTextForPlayer( current_player, "~n~~n~~n~~r~wrong ball", 3000, 4);

	    				foreach ( new playerid : poolplayers< poolid > ) {
	    					SendClientMessageFormatted( playerid, COLOR_RED, "* %s(%d) has wrongly pocketed %s, instead of %s!", ReturnPlayerName( current_player ), current_player, g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ), g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ current_player ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ) );
	    				}

						// penalty for that
						g_poolTableData[ poolid ] [ E_FOULS ] ++;
						g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 0;
					}
					else
					{
	    				p_PoolScore[ current_player ] ++;
	    				GameTextForPlayer( current_player, "~n~~n~~n~~w~Score: +1", 3000, 4);

	    				foreach ( new playerid : poolplayers< poolid > ) {
	    					SendClientMessageFormatted( playerid, COLOR_YELLOW, "%s(%d) has pocketed a %s %s!", ReturnPlayerName( current_player ), current_player, g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ), g_poolBallOffsetData[ poolball_index ] [ E_BALL_NAME ] );
	    				}

						// extra shot for scoring one's own
						if ( ! g_poolTableData[ poolid ] [ E_FOULS ] ) {
							g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 1;
						}
					}

					// mark final target hole
					if ( p_PoolScore[ first_player ] == 7 || p_PoolScore[ second_player ] == 7 )
					{
						new
							player_being_marked = p_PoolScore[ first_player ] == 7 ? first_player : second_player;

						if ( ! IsValidDynamicObject( p_PoolHoleGuide[ player_being_marked ] ) )
						{
							new
								opposite_holeid = g_poolHoleOpposite[ holeid ];

							RotateXY( g_poolPotOffsetData[ opposite_holeid ] [ 0 ], g_poolPotOffsetData[ opposite_holeid ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );
							p_PoolHoleGuide[ player_being_marked ] = CreateDynamicObject( 18643, g_poolTableData[ poolid ] [ E_X ] + hole_x, g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ] - 0.5, 0.0, -90.0, 0.0, .playerid = player_being_marked );
							g_poolTableData[ poolid ] [ E_PLAYER_8BALL_TARGET ] [ player_being_marked ] = opposite_holeid;
							SendPoolMessage( player_being_marked, "You are now required to put the 8-Ball in the designated pocket." );
						}
					}
				}

				// rotate hole offsets according to table
				RotateXY( g_poolPotOffsetData[ holeid ] [ 0 ], g_poolPotOffsetData[ holeid ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );

				// move object into the pocket
				MoveObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ j ], g_poolTableData[ poolid ] [ E_X ] + hole_x, g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ] - 0.5, 1.0);

				g_poolBallData[ poolid ] [ E_MOVING ] [ j ] = true;

				SetTimerEx( "deleteBall", 500, false, "dd", poolid, j );

				PlayerPlaySound( current_player, 31803, 0.0, 0.0, 0.0 );

				// update scoreboard
				Pool_UpdateScoreboard( poolid );

				// reset cam
				Pool_QueueNextPlayer( poolid, current_player );
		    	SetTimerEx( "RestoreCamera", 800, 0, "dd", current_player, poolid );
			}
			return 1;
		}
	}
	return 1;
}

CMD:fakescore( playerid, params [ ]) {
	p_PoolScore[ playerid ] = 6;
	Pool_UpdateScoreboard(GetClosestPoolTable(playerid ));
	return 1;
}

stock Pool_OnPlayerWin( poolid, winning_player )
{
	// restore camera
	RestoreCamera( winning_player, poolid );

	// winning player
	foreach ( new playerid : poolplayers< poolid > ) {
		SendClientMessageFormatted( playerid, COLOR_RED, "**** %s(%d) has won %s", ReturnPlayerName( winning_player ), winning_player );
	}
	return 1;
}

stock Pool_QueueNextPlayer( poolid, current_player )
{
	if ( g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] > 0 && g_poolTableData[ poolid ] [ E_FOULS ] < 1 )
	{
		Pool_SendTableMessage( poolid, COLOR_RED, "%s(%d) has %d shots remaining!", ReturnPlayerName( current_player ), current_player, g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] );
	}
	else
	{
		new first_player = Iter_First( poolplayers< poolid > );
		new second_player = Iter_Last( poolplayers< poolid > );

		g_poolTableData[ poolid ] [ E_FOULS ] = 0;
		g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 1;
	    g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] = current_player == first_player ? second_player : first_player;

		// reset ball positions just incase
		Pool_SendTableMessage( poolid, COLOR_RED, "%s(%d)'s turn to play!", ReturnPlayerName( g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] ), g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] );
	}

	// update turn
	Pool_UpdateScoreboard( poolid );
}

stock Pool_SendTableMessage( poolid, colour, format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach ( new i : poolplayers< poolid > ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock Pool_ResetBallPositions( poolid )
{
	static Float: last_x, Float: last_y, Float: last_z;
	static Float: last_rx, Float: last_ry, Float: last_rz;

	for ( new i = 0; i < sizeof( g_poolBallOffsetData ); i ++ ) if ( g_poolBallData[ poolid ] [ E_EXISTS ] [ i ] )
	{
		if ( ! IsValidObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] ) ) {
			continue;
		}

		new
			modelid = GetObjectModel( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] );

		// get current position
		GetObjectPos( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ], last_x, last_y, last_z );
		GetObjectRot( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ], last_rx, last_ry, last_rz );

		// destroy object
		PHY_DeleteObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] );
		DestroyObject( g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] );

		// create pool balls on table
		g_poolBallData[ poolid ] [ E_BALL_OBJECT ] [ i ] = CreateObject( modelid, last_x, last_y, last_z, last_rx, last_ry, last_rz );

		// initialize physics on each ball
		InitBalls( poolid, i );
	}
}

/*hook OnPlayerWeaponShot( playerid, weaponid, hittype, hitid, Float: fX, Float: fY, Float: fZ )
{
	if ( hittype == BULLET_HIT_TYPE_OBJECT )
	{

	}
    return 1;
}*/

/* ** Commands ** */
CMD:endgame(playerid)
{
	if ( ! IsPlayerAdmin( playerid ) )
		return 0;

	new iPool = GetClosestPoolTable( playerid );

	if ( iPool == -1 )
		return SendError( playerid, "You must be near a pool table to use this command." );

	Pool_EndGame( iPool );

	SendClientMessage(playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have force ended the pool game!");
	return 1;
}

CMD:play(playerid)
{
	new
		iPool = GetClosestPoolTable( playerid );

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

			Iter_Clear( poolplayers< iPool > );
			Iter_Add( poolplayers< iPool >, playerid );
			Iter_Add( poolplayers< iPool >, playerid );

			UpdateDynamic3DTextLabelText(g_poolTableData[ iPool ] [ E_LABEL ], -1, sprintf( "{FFDC2E}%s is currently playing a test game.", ReturnPlayerName( playerid )) );

			RespawnPoolBalls( iPool );
		}
	}
	else
	{
		Pool_EndGame( iPool );
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
			iPool = GetClosestPoolTable( playerid );

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
		new iPool = GetClosestPoolTable( playerid );
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
