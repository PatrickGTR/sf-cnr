/*
 * Irresistible Gaming (c) 2018
 * Developed by Stev, Lorenc
 * Module: cnr/features/pool.pwn
 * Purpose: pool minigame
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >
//#include 							< physics_dynamic >

/* ** Definitions ** */
#define POCKET_RADIUS 				( 0.09 )
#define POOL_TIMER_SPEED 			( 25 )
#define DEFAULT_AIM 				( 0.38 )
#define DEFAULT_POOL_STRING 		"Pool Table\n{FFFFFF}Press ENTER To Play"
#define POOL_FEE_RATE 				( 0.02 )

#define MAX_POOL_TABLES 			( 48 )
#define MAX_POOL_BALLS 				( 16 ) // do not modify

/* ** Macros ** */
#define SendPoolMessage(%0,%1)		SendClientMessageFormatted(%0, -1, "{4B8774}[POOL] {E5861A}" # %1)

/* ** Constants (do not modify) ** */
enum E_POOL_BALL_TYPE {
	E_STRIPED,
	E_SOLID,
	E_CUE,
	E_8BALL
};

enum E_POOL_SKINS {
	POOL_SKIN_DEFAULT,
	POOL_SKIN_WOOD_PURPLE,
	POOL_SKIN_WOOD_GREEN,
	POOL_SKIN_GOLD_GREEN,
	POOL_SKIN_WOOD_BLUE,
	POOL_SKIN_LWOOD_GREEN
};

enum E_POOL_BALL_OFFSET_DATA
{
	E_MODEL_ID, 					E_BALL_NAME[ 9 ],				E_POOL_BALL_TYPE: E_BALL_TYPE,
	Float: E_OFFSET_X, 				Float: E_OFFSET_Y
};

static const
	g_poolBallOffsetData[ MAX_POOL_BALLS ] [ E_POOL_BALL_OFFSET_DATA ] =
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
	E_BALL_PHY_HANDLE[ 16 ],		bool: E_POCKETED[ 16 ]
};

enum E_POOL_TABLE_DATA
{
	Float: E_X,						Float: E_Y, 					Float: E_Z,
	Float: E_ANGLE, 				E_WORLD, 						E_INTERIOR,

	E_TIMER, 						E_BALLS_SCORED, 				E_POOL_BALL_TYPE: E_PLAYER_BALL_TYPE[ MAX_PLAYERS ],
	bool: E_STARTED, 				E_AIMER, 						E_AIMER_OBJECT,
	E_NEXT_SHOOTER,

	E_SHOTS_LEFT,					E_FOULS,						E_PLAYER_8BALL_TARGET[ MAX_PLAYERS ],
	bool: E_EXTRA_SHOT,				bool: E_CUE_POCKETED,

	E_WAGER,						bool: E_READY,					E_CUEBALL_AREA,

	Float: E_POWER,					E_DIRECTION,

	E_TABLE,						Text3D: E_LABEL,
}

new
	g_poolTableData 				[ MAX_POOL_TABLES ] [ E_POOL_TABLE_DATA ],
	g_poolBallData 					[ MAX_POOL_TABLES ] [ E_POOL_BALL_DATA ],

	p_PoolID 						[ MAX_PLAYERS ] = { -1, ... },

	bool: p_isPlayingPool			[ MAX_PLAYERS char ],
	bool: p_PoolChalking			[ MAX_PLAYERS char ],
	bool: p_PoolCameraBirdsEye		[ MAX_PLAYERS char ],
	p_PoolScore 					[ MAX_PLAYERS ],
	p_PoolHoleGuide 				[ MAX_PLAYERS ] = { -1, ... },
	Float: p_PoolAngle 				[ MAX_PLAYERS ] [ 2 ],

	PlayerBar: g_PoolPowerBar 		[ MAX_PLAYERS ],
	Text: g_PoolTextdraw			= Text: INVALID_TEXT_DRAW,

	Iterator: pooltables 			< MAX_POOL_TABLES >,
	Iterator: poolplayers 			< MAX_POOL_TABLES, MAX_PLAYERS >
;

/* ** Forwards ** */
forward deleteBall 					( poolid, ballid );
forward RestoreWeapon 				( playerid );
forward RestoreCamera 				( playerid );
forward OnPoolUpdate 				( poolid );
forward PlayPoolSound 				( poolid, soundid );

/* ** Hooks ** */
hook OnScriptInit( )
{
	// textdraws
	g_PoolTextdraw = TextDrawCreate( 529.000000, 218.000000, "Power" );
	TextDrawBackgroundColor( g_PoolTextdraw, 255 );
	TextDrawFont( g_PoolTextdraw, 1 );
	TextDrawLetterSize( g_PoolTextdraw, 0.300000, 1.299998 );
	TextDrawColor( g_PoolTextdraw, -1 );
	TextDrawSetOutline( g_PoolTextdraw, 1 );
	TextDrawSetProportional( g_PoolTextdraw, 1 );
	TextDrawSetSelectable( g_PoolTextdraw, 0 );

	// create static pooltables
	CreatePoolTableEx( 510.10159, -84.83590, 998.9375, 90.00000, POOL_SKIN_DEFAULT, 11, 7, 54, 55, 56, 50, 52, 51, 15, 10, 21, 58, 48, 17, 36, 41, 22 );
	CreatePoolTableEx( 506.48441, -84.83590, 998.9375, 90.00000, POOL_SKIN_DEFAULT, 11, 7, 54, 55, 56, 50, 52, 51, 15, 10, 21, 58, 48, 17, 36, 41, 22 );

	// custom pool tables
	CreatePoolTable( -1019.264, 1045.7419, 1.763000, 0.000000, POOL_SKIN_WOOD_PURPLE, 0, 0 ); // panther
	CreatePoolTable( 1999.0837, 1888.4924, 84.22465, 0.000000, POOL_SKIN_GOLD_GREEN, VISAGE_APARTMENT_INT, VISAGE_APARTMENT_WORLD[ 1 ] ); // banging7grams
	CreatePoolTable( 2005.2181, 1891.0632, 84.22465, 90.00000, POOL_SKIN_WOOD_GREEN, VISAGE_APARTMENT_INT, VISAGE_APARTMENT_WORLD[ 7 ] ); // nibble
	CreatePoolTable( -2087.757, 845.72698, 76.36699, 90.00000, POOL_SKIN_WOOD_BLUE, 0, 0 ); // Stev
	CreatePoolTable( -2880.332, 56.208999, 8.521999, 0.000000, POOL_SKIN_LWOOD_GREEN, 0, 0 ); // Kova

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
	RemoveBuildingForPlayer( playerid, 2964, 510.1016, -84.8359, 997.9375, 9999.9 );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_POOL_WAGER )
	{
		new
			poolid = p_PoolID[ playerid ];

		if ( poolid == -1 ) {
			return SendError( playerid, "Unable to identify pool table. Please enter the pool table again." );
		}

		new
			wager_amount = strval( inputtext );

		if ( response && wager_amount > 0 )
		{
			if ( wager_amount > GetPlayerCash( playerid ) ) {
				ShowPlayerDialog( playerid, DIALOG_POOL_WAGER, DIALOG_STYLE_INPUT, "{FFFFFF}Pool Wager", "{FFFFFF}Please specify the minimum entry fee for the table:\n\n"COL_RED"You do not have this much money!", "Set", "No" );
			} else {
				GivePlayerCash( playerid, -wager_amount );
				g_poolTableData[ poolid ] [ E_WAGER ] = wager_amount;
				g_poolTableData[ poolid ] [ E_READY ] = true;
				Pool_SendTableMessage( poolid, -1, ""COL_GREY"-- "COL_WHITE" %s(%d) has set the pool wager to %s!", ReturnPlayerName( playerid ), playerid, cash_format( wager_amount ) );
				UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], -1, sprintf( "" # COL_GREY "Pool Table\n"COL_GREEN"Press ENTER To Join %s(%d)\n"COL_RED"%s Entry", ReturnPlayerName( playerid ), playerid, cash_format( wager_amount ) ) );
			}
			return 1;
		}
		else
		{
			g_poolTableData[ poolid ] [ E_WAGER ] = 0;
			g_poolTableData[ poolid ] [ E_READY ] = true;
			Pool_SendTableMessage( poolid, -1, ""COL_GREY"-- "COL_WHITE" %s(%d) has set the pool wager to FREE!", ReturnPlayerName( playerid ), playerid );
			UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], -1, sprintf( "" # COL_GREY "Pool Table\n"COL_GREEN"Press ENTER To Join %s(%d)", ReturnPlayerName( playerid ), playerid ) );
		}
	}
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	new
		poolid = p_PoolID[ playerid ];

	if ( IsPlayerPlayingPool( playerid ) && poolid != -1 )
	{
		new
			Float: distance_to_table = GetPlayerDistanceFromPoint( playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] );

		if ( distance_to_table >= 25.0 )
		{
			Pool_SendTableMessage( poolid, COLOR_GREY, "-- "COL_WHITE" %s(%d) has been kicked from the table [Reason: Out Of Range]", ReturnPlayerName( playerid ), playerid );
			return Pool_RemovePlayer( playerid ), 1;
		}
	}
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	new Float: pooltable_distance = 99999.99;
	new poolid = Pool_GetClosestTable( playerid, pooltable_distance );

	if ( poolid != -1 && pooltable_distance < 2.5 )
	{
		if ( g_poolTableData[ poolid ] [ E_STARTED ] )
		{
			// quit table
			if ( HOLDING( KEY_SECONDARY_ATTACK ) && IsPlayerPlayingPool( playerid ) ) {
				if ( PRESSED( KEY_CROUCH ) ) {
					HidePlayerHelpDialog( playerid );
					Pool_SendTableMessage( poolid, COLOR_GREY, "-- "COL_WHITE" %s(%d) has left the table", ReturnPlayerName( playerid ), playerid );
					return Pool_RemovePlayer( playerid );
				} else {
					return GameTextForPlayer( playerid, "~w~and now...~n~~w~ press ~r~~k~~PED_DUCK~~w~ to exit", 3500, 3 ), 1;
				}
			}

			// make pressing key fire annoying
			if ( RELEASED( KEY_FIRE ) && g_poolTableData[ poolid ] [ E_AIMER ] != playerid && ! p_PoolChalking{ playerid } )
			{
				// reset anims of player
				if ( IsPlayerPlayingPool( playerid ) )
				{
					p_PoolChalking{ playerid } = true;

					SetPlayerArmedWeapon( playerid, 0 );
					SetPlayerAttachedObject( playerid, 0, 338, 6, 0, 0.07, -0.85, 0, 0, 0 );
					ApplyAnimation( playerid, "POOL", "POOL_ChalkCue", 3.0, 0, 1, 1, 1, 0, 1 );

					SetTimerEx( "PlayPoolSound", 1400, false, "dd", playerid, 31807 );
					SetTimerEx( "RestoreWeapon", 3500, false, "d", playerid );
				}
				else
				{
					ClearAnimations( playerid );
				}

				// reset ball positions just in-case they hit it
				if ( Pool_AreBallsStopped( poolid ) ) {
					Pool_ResetBallPositions( poolid );
				}
				return 1;
			}

			// begin gameplay stuff
			if ( IsPlayerPlayingPool( playerid ) && p_PoolID[ playerid ] == poolid )
			{
				if ( RELEASED( KEY_JUMP ) )
				{
					if ( g_poolTableData[ poolid ] [ E_AIMER ] == playerid )
					{
						p_PoolCameraBirdsEye{ playerid } = ! p_PoolCameraBirdsEye{ playerid };
						Pool_UpdatePlayerCamera( playerid, poolid );
					}
				}

				if ( RELEASED( KEY_HANDBRAKE ) )
				{
					if ( Pool_AreBallsStopped( poolid ) )
					{
						if ( g_poolTableData[ poolid ] [ E_AIMER ] != playerid )
						{
							if ( g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] != playerid ) {
								return SendPoolMessage( playerid, "It is not your turn. Please wait." );
							}

							if ( g_poolTableData[ poolid ] [ E_CUE_POCKETED ] ) {
								return SendPoolMessage( playerid, "You can aim the cue as soon as you place the cue ball." );
							}

							if ( ! p_PoolChalking{ playerid } && g_poolTableData[ poolid ] [ E_AIMER ] == -1 )
							{
								new Float:X, Float:Y, Float:Z,
									Float:Xa, Float:Ya, Float:Za,
									Float:x, Float:y;

								GetPlayerPos( playerid, X, Y, Z );

								if ( Z > g_poolTableData[ poolid ] [ E_Z ] + 0.5 ) {
									return SendPoolMessage( playerid, "Lower yourself from the table." );
								}

								new objectid = PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] );
								GetDynamicObjectPos( objectid, Xa, Ya, Za );

								new
									Float: distance_to_ball = GetDistanceFromPointToPoint( X, Y, Xa, Ya );

								if ( distance_to_ball < 2.0 && Z < 999.5 )
								{
									new
										Float: poolrot = atan2( Ya - Y, Xa - X ) - 90.0;

									TogglePlayerControllable( playerid, false );

	                            	p_PoolAngle[ playerid ] [ 0 ] = poolrot;
	                            	p_PoolAngle[ playerid ] [ 1 ] = poolrot;

									SetPlayerArmedWeapon( playerid, 0 );
									Pool_GetXYInFrontOfPos( Xa, Ya, poolrot + 180, x, y, 0.085 );
									g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] = CreateDynamicObject( 3004, x, y, Za, 7.0, 0, poolrot + 180, .worldid = g_poolTableData[ poolid ] [ E_WORLD ] );

									if ( distance_to_ball < 1.20 ) {
										distance_to_ball = 1.20;
									}

					              	Pool_GetXYInFrontOfPos( Xa, Ya, poolrot + 180 - 5.0, X, Y, distance_to_ball ); // offset 5 degrees
					                SetPlayerPos( playerid, X, Y, Z );
	                				SetPlayerFacingAngle( playerid, poolrot );

									if ( distance_to_ball > 1.5 ) {
										ApplyAnimation( playerid, "POOL", "POOL_XLong_Start", 4.1, 0, 1, 1, 1, 1, 1 );
									} else {
										ApplyAnimation( playerid, "POOL", "POOL_Long_Start", 4.1, 0, 1, 1, 1, 1, 1 );
									}

									g_poolTableData[ poolid ] [ E_AIMER ] = playerid;
									g_poolTableData[ poolid ] [ E_POWER ] = 1.0;
									g_poolTableData[ poolid ] [ E_DIRECTION ] = 0;

									Pool_UpdatePlayerCamera( playerid, poolid );
									Pool_UpdateScoreboard( poolid );

									TextDrawShowForPlayer( playerid, g_PoolTextdraw );
									ShowPlayerProgressBar( playerid, g_PoolPowerBar[playerid] );
								}
							}
						}
						else
						{
							TogglePlayerControllable( playerid, true );
							GivePlayerWeapon( playerid, 7, 1 );

							ClearAnimations( playerid );
	            			SetCameraBehindPlayer( playerid );
							ApplyAnimation( playerid, "CARRY", "crry_prtial", 4.0, 0, 1, 1, 0, 0 );

							TextDrawHideForPlayer( playerid, g_PoolTextdraw );
							HidePlayerProgressBar( playerid, g_PoolPowerBar[playerid] );

	            			g_poolTableData[ poolid ] [ E_AIMER ] = -1;
	            			DestroyDynamicObject( g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] );
	            			g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] = -1;
						}
					}
				}

				if ( RELEASED( KEY_FIRE ) )
				{
					if ( g_poolTableData[ poolid ] [ E_AIMER ] == playerid )
					{
						new Float: ball_x, Float: ball_y, Float: ball_z;

						g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] --;

						Pool_UpdateScoreboard( poolid );

						GetDynamicObjectPos( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] ), ball_x, ball_y, ball_z );
						new Float: distance_to_ball = GetPlayerDistanceFromPoint( playerid, ball_x, ball_y, ball_z );

						if ( distance_to_ball > 1.5 ) {
							ApplyAnimation( playerid, "POOL", "POOL_XLong_Shot", 4.1, 0, 1, 1, 0, 0, 1 );
						} else {
							ApplyAnimation( playerid, "POOL", "POOL_Long_Shot", 4.1, 0, 1, 1, 0, 0, 1 );
						}

						new Float: speed = 0.4 + ( g_poolTableData[ poolid ] [ E_POWER ] * 2.0 ) / 100.0;
						PHY_SetHandleVelocity( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ], speed * floatsin( -p_PoolAngle[ playerid ] [ 0 ], degrees ), speed * floatcos( -p_PoolAngle[ playerid ] [ 0 ], degrees ) );

						SetPlayerCameraPos( playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0 );
						SetPlayerCameraLookAt( playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] );

						PlayPoolSound( poolid, 31810 );
						g_poolTableData[ poolid ] [ E_AIMER ] = -1;
						DestroyDynamicObject( g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] );
						g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] = -1;

						GivePlayerWeapon( playerid, 7, 1 );
					}
					else ClearAnimations( playerid );
				}
			}
		}
		else
		{
			if ( PRESSED( KEY_SECONDARY_ATTACK ) )
			{
				if ( IsPlayerPlayingPool( playerid ) && Iter_Contains( poolplayers< poolid >, playerid ) )
				{
					HidePlayerHelpDialog( playerid );
					Pool_SendTableMessage( poolid, COLOR_GREY, "-- "COL_WHITE" %s(%d) has left the table", ReturnPlayerName( playerid ), playerid );
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
					if ( pool_player_count == 1 && ! g_poolTableData[ poolid ] [ E_READY ] ) {
						return SendError( playerid, "This pool table is not ready to play." );
					}

					new
						entry_fee = g_poolTableData[ poolid ] [ E_WAGER ];

					if ( GetPlayerCash( playerid ) < entry_fee && g_poolTableData[ poolid ] [ E_READY ] ) {
						return SendError( playerid, "You need %s to join this pool table.", cash_format( entry_fee ) );
					}

					// add to table
					Iter_Add( poolplayers< poolid >, playerid );

					// reset variables
					p_isPlayingPool{ playerid } = true;
					p_PoolID[ playerid ] = poolid;

					// deduct cash
					if ( g_poolTableData[ poolid ] [ E_READY ] ) {
						GivePlayerCash( playerid, -entry_fee );
					}

					// start the game if there's two players
					if ( pool_player_count + 1 >= 2 )
					{
					    new
					    	random_cuer = Iter_Random( poolplayers< poolid > );

						Pool_SendTableMessage( poolid, COLOR_GREY, "-- "COL_WHITE" %s(%d) has joined the table (2/2)", ReturnPlayerName( playerid ), playerid );
					    Pool_QueueNextPlayer( poolid, random_cuer );

					    foreach ( new i : poolplayers< poolid > ) {
							p_PoolScore[ i ] = 0;
							PlayerPlaySound( i, 1085, 0.0, 0.0, 0.0 );
							GivePlayerWeapon( i, 7, 1 );
					    }

						g_poolTableData[ poolid ] [ E_STARTED ] = true;
				    	Pool_UpdateScoreboard( poolid );
						Pool_RespawnBalls( poolid );
					}
					else
					{
						g_poolTableData[ poolid ] [ E_WAGER ] = 0;
						g_poolTableData[ poolid ] [ E_READY ] = false;
						ShowPlayerDialog( playerid, DIALOG_POOL_WAGER, DIALOG_STYLE_INPUT, "{FFFFFF}Pool Wager", "{FFFFFF}Please specify the minimum entry fee for the table:", "Set", "No Fee" );
						ShowPlayerHelpDialog( playerid, 0, "~y~~h~~k~~PED_LOCK_TARGET~ ~w~- Aim Cue~n~~y~~h~~k~~PED_FIREWEAPON~ ~w~- Shoot Cue~n~~y~~h~~k~~PED_JUMPING~ ~w~- Camera Mode~n~~y~~h~~k~~VEHICLE_ENTER_EXIT~ ~w~- Exit Game~n~~n~~r~~h~Waiting for 1 more player..." );
						UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], -1, sprintf( "" # COL_GREY "Pool Table\n"COL_ORANGE"... Waiting For %s(%d) ...", ReturnPlayerName( playerid ), playerid ) );
						Pool_SendTableMessage( poolid, COLOR_GREY, "-- "COL_WHITE" %s(%d) has joined the table (1/2)", ReturnPlayerName( playerid ), playerid );
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
	RestoreCamera( playerid );
	//HidePlayerHelpDialog( playerid );

	// check if the player is even in the table
	if ( poolid != -1 && Iter_Contains( poolplayers< poolid >, playerid ) )
	{
		// remove them from the table
		Iter_Remove( poolplayers< poolid >, playerid );

		// forfeit player
		if ( g_poolTableData[ poolid ] [ E_STARTED ] )
		{
			// ... if there's only 1 guy in the table might as well declare him winner
			if ( Iter_Count( poolplayers< poolid > ) )
			{
				new
					replacement_winner = Iter_First( poolplayers< poolid > );

				Pool_OnPlayerWin( poolid, replacement_winner );
			}
			return Pool_EndGame( poolid );
		}
		else
		{
			// no players and is a ready table, then refund
			if ( ! Iter_Count( poolplayers< poolid > ) && g_poolTableData[ poolid ] [ E_READY ] )
			{
				GivePlayerCash( playerid, g_poolTableData[ poolid ] [ E_WAGER ] );
				g_poolTableData[ poolid ] [ E_READY ] = false;
				g_poolTableData[ poolid ] [ E_WAGER ] = 0;
			}
			UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], COLOR_GREY, DEFAULT_POOL_STRING );
		}
	}
	return 1;
}

/* ** Functions ** */
stock CreatePoolTableEx( Float: X, Float: Y, Float: Z, Float: A = 0.0, E_POOL_SKINS: skin, interior = 0, ... ) {
	for( new i = 6; i < numargs( ); i++ ) {
		CreatePoolTable( X, Y, Z, A, skin, interior, getarg( i ) );
	}
}

stock CreatePoolTable( Float: X, Float: Y, Float: Z, Float: A = 0.0, E_POOL_SKINS: skin, interior = 0, world = 0 )
{
	if ( A != 0 && A != 90.0 && A != 180.0 && A != 270.0 && A != 360.0 ) {
		return print( "[POOL] [ERROR] Pool tables must be positioned at either 0, 90, 180, 270 and 360 degrees." ), 1;
	}

	new
		poolid = Iter_Free( pooltables );

	if ( poolid != ITER_NONE )
	{
		new
			Float: x_vertex[ 4 ], Float: y_vertex[ 4 ];

		Iter_Add( pooltables, poolid );

		g_poolTableData[ poolid ] [ E_X ] = X;
		g_poolTableData[ poolid ] [ E_Y ] = Y;
		g_poolTableData[ poolid ] [ E_Z ] = Z;
		g_poolTableData[ poolid ] [ E_ANGLE ] = A;

		g_poolTableData[ poolid ] [ E_INTERIOR ] = interior;
		g_poolTableData[ poolid ] [ E_WORLD ] = world;

		g_poolTableData[ poolid ] [ E_TABLE ] = CreateDynamicObject( 2964, X, Y, Z - 1.0, 0.0, 0.0, A, .interiorid = interior, .worldid = world, .priority = 9999 );
		g_poolTableData[ poolid ] [ E_LABEL ] = CreateDynamic3DTextLabel( DEFAULT_POOL_STRING, COLOR_GREY, X, Y, Z, 10.0, .interiorid = interior, .worldid = world, .priority = 9999 );

		Pool_RotateXY( -0.964, -0.51, A, x_vertex[ 0 ], y_vertex[ 0 ] );
		Pool_RotateXY( -0.964, 0.533, A, x_vertex[ 1 ], y_vertex[ 1 ] );
		Pool_RotateXY( 0.976, -0.51, A, x_vertex[ 2 ], y_vertex[ 2 ] );
		Pool_RotateXY( 0.976, 0.533, A, x_vertex[ 3 ], y_vertex[ 3 ] );

		new
			walls[ 4 ];

		walls[ 0 ] = PHY_CreateWall( x_vertex[ 0 ] + X, y_vertex[ 0 ] + Y, x_vertex[ 1 ] + X, y_vertex[ 1 ] + Y );
		walls[ 1 ] = PHY_CreateWall( x_vertex[ 1 ] + X, y_vertex[ 1 ] + Y, x_vertex[ 3 ] + X, y_vertex[ 3 ] + Y );
		walls[ 2 ] = PHY_CreateWall( x_vertex[ 2 ] + X, y_vertex[ 2 ] + Y, x_vertex[ 3 ] + X, y_vertex[ 3 ] + Y );
		walls[ 3 ] = PHY_CreateWall( x_vertex[ 0 ] + X, y_vertex[ 0 ] + Y, x_vertex[ 2 ] + X, y_vertex[ 2 ] + Y );

		// set wall worlds
		for ( new i = 0; i < sizeof( walls ); i ++ ) {
			PHY_SetWallWorld( walls[ i ], world );
		}

		// create boundary for replacing the cueball
		new Float: vertices[ 4 ];

		Pool_RotateXY( 0.94, 0.48, g_poolTableData[ poolid ] [ E_ANGLE ], vertices[ 0 ], vertices[ 1 ] );
		Pool_RotateXY( -0.94, -0.48, g_poolTableData[ poolid ] [ E_ANGLE ], vertices[ 2 ], vertices[ 3 ] );

		vertices[ 0 ] += g_poolTableData[ poolid ] [ E_X ], vertices[ 2 ] += g_poolTableData[ poolid ] [ E_X ];
		vertices[ 1 ] += g_poolTableData[ poolid ] [ E_Y ], vertices[ 3 ] += g_poolTableData[ poolid ] [ E_Y ];

		g_poolTableData[ poolid ] [ E_CUEBALL_AREA ] = CreateDynamicRectangle( vertices[ 2 ], vertices[ 3 ], vertices[ 0 ], vertices[ 1 ], .interiorid = interior, .worldid = world );

		// skins
		if ( skin == POOL_SKIN_WOOD_PURPLE ) // Panther
		{
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 1, 8401, "vgshpground", "dirtywhite", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 2, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 3, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 4, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 0, 10375, "subshops_sfs", "ws_white_wall1", -10072402 );
		}
		else if ( skin == POOL_SKIN_GOLD_GREEN )
		{
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 0, 1273, "icons3", "greengrad32", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 1, 946, "bskball_standext", "drkbrownmetal", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 2, 8463, "vgseland", "tiadbuddhagold", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 3, 8463, "vgseland", "tiadbuddhagold", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 4, 8463, "vgseland", "tiadbuddhagold", 0 );
		}
		else if ( skin == POOL_SKIN_WOOD_GREEN )
		{
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 0, 1273, "icons3", "greengrad32", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 1, 8401, "vgshpground", "dirtywhite", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 2, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 3, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", 0 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 4, 11631, "mp_ranchcut", "mpCJ_WOOD_DARK", 0 );
		}
		else if ( skin == POOL_SKIN_WOOD_BLUE )
		{
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 4, 11100, "bendytunnel_sfse", "blackmetal", -16 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 3, 11100, "bendytunnel_sfse", "blackmetal", -16 );
		}
		else if ( skin == POOL_SKIN_LWOOD_GREEN )
		{
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 0, 10375, "subshops_sfs", "ws_white_wall1", -11731124 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 3, 16150, "ufo_bar", "sa_wood07_128", -16 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 4, 16150, "ufo_bar", "sa_wood07_128", -16 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 1, 9362, "sfn_byofficeint", "CJ_Black_metal", -16 );
			SetDynamicObjectMaterial( g_poolTableData[ poolid ] [ E_TABLE ], 2, 8463, "vgseland", "tiadbuddhagold", -16 );
		}

		// reset pool handles
		for ( new i = 0; i < sizeof( g_poolBallOffsetData ); i ++ ) {
			g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] = ITER_NONE;
		}

	#if defined POOL_DEBUG
		ReloadPotTestLabel( 0, poolid );
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
	return poolid;
}

stock Pool_GetClosestTable( playerid, &Float: dis = 99999.99 )
{
	new pooltable = -1;
	new player_world = GetPlayerVirtualWorld( playerid );

	foreach ( new i : pooltables ) if ( g_poolTableData[ i ] [ E_WORLD ] == player_world )
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

stock Pool_RespawnBalls( poolid )
{
	if ( g_poolTableData[ poolid ] [ E_AIMER ] != -1 )
	{
		TogglePlayerControllable(g_poolTableData[ poolid ] [ E_AIMER ], 1);
		//ClearAnimations(g_poolTableData[ poolid ] [ E_AIMER ]);

		//ApplyAnimation(g_poolTableData[ poolid ] [ E_AIMER ], "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0);
        SetCameraBehindPlayer( g_poolTableData[ poolid ] [ E_AIMER ] );
        DestroyDynamicObject( g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] );
        g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] = -1;

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
		Pool_RotateXY( g_poolBallOffsetData[ i ] [ E_OFFSET_X ], g_poolBallOffsetData[ i ] [ E_OFFSET_Y ], g_poolTableData[ poolid ] [ E_ANGLE ], offset_x, offset_y );

		// reset balls
		if ( PHY_IsHandleValid( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] ) ) {
			PHY_DeleteHandle( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] );
			DestroyDynamicObject( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] ) );
			g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] = ITER_NONE;
		}

		// create pool balls on table
		new objectid = CreateDynamicObject(
			g_poolBallOffsetData[ i ] [ E_MODEL_ID ],
			g_poolTableData[ poolid ] [ E_X ] + offset_x,
			g_poolTableData[ poolid ] [ E_Y ] + offset_y,
			g_poolTableData[ poolid ] [ E_Z ] - 0.045,
			0.0, 0.0, 0.0,
			.worldid = g_poolTableData[ poolid ] [ E_WORLD ],
			.priority = 999
		);

		// initialize physics on each ball
		Pool_InitBalls( poolid, objectid, i );
	}

	KillTimer( g_poolTableData[ poolid ] [ E_TIMER ] );
	g_poolTableData[ poolid ] [ E_TIMER ] = SetTimerEx( "OnPoolUpdate", POOL_TIMER_SPEED, true, "d", poolid );
	g_poolTableData[ poolid ] [ E_BALLS_SCORED ] = 0;
}

stock Pool_InitBalls( poolid, objectid, ballid )
{
	new handleid = PHY_InitObject( objectid, 3003, _, _, PHY_MODE_2D );

	PHY_SetHandleWorld( handleid, g_poolTableData[ poolid ] [ E_WORLD ] );
	PHY_SetHandleFriction( handleid, 0.08 ); // 0.10
	PHY_SetHandleAirResistance( handleid, 0.2 );
	PHY_RollObject( handleid );

	g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ ballid ] = handleid;
	g_poolBallData[ poolid ] [ E_POCKETED ] [ ballid ] = false;
}

stock Pool_RotateXY( Float: xi, Float: yi, Float: angle, &Float: xf, &Float: yf )
{
    xf = xi * floatcos( angle, degrees ) - yi * floatsin( angle, degrees );
    yf = xi * floatsin( angle, degrees ) + yi * floatcos( angle, degrees );
    return 1;
}

stock Pool_AreBallsStopped( poolid )
{
	new
		balls_not_moving = 0;

	for ( new i = 0; i < 16; i ++ )
	{
		new
			ball_handle = g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ];

		if ( ! PHY_IsHandleValid( ball_handle ) || g_poolBallData[ poolid ] [ E_POCKETED ] [ i ] || ! PHY_IsHandleMoving( ball_handle ) ) {
			balls_not_moving ++;
		}
	}
	return balls_not_moving >= 16;
}

stock Pool_GetXYInFrontOfPos( Float: xx, Float: yy, Float: a, &Float: x2, &Float: y2, Float: distance )
{
    x2 = xx + ( distance * floatsin( -a, degrees ) );
    y2 = yy + ( distance * floatcos( -a, degrees ) );
}

stock Pool_IsBallInHole( poolid, objectid )
{
	new
		Float: hole_x, Float: hole_y;

	for ( new i = 0; i < sizeof( g_poolPotOffsetData ); i ++ )
	{
		// rotate offsets according to table
		Pool_RotateXY( g_poolPotOffsetData[ i ] [ 0 ], g_poolPotOffsetData[ i ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );

		// check if it is at the pocket
		if ( Pool_IsObjectAtPos( objectid, g_poolTableData[ poolid ] [ E_X ] + hole_x , g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ], POCKET_RADIUS ) ) {
			return i;
		}
	}
    return -1;
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
		RestoreCamera( i );
	}

	Iter_Clear( poolplayers< poolid > );

	g_poolTableData[ poolid ] [ E_STARTED ] = false;
	g_poolTableData[ poolid ] [ E_AIMER ] = -1;
	g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 0;
	g_poolTableData[ poolid ] [ E_FOULS ] = 0;
	g_poolTableData[ poolid ] [ E_EXTRA_SHOT ] = false;
	g_poolTableData[ poolid ] [ E_READY ] = false;
	g_poolTableData[ poolid ] [ E_WAGER ] = 0;
	g_poolTableData[ poolid ] [ E_CUE_POCKETED ] = false;

	KillTimer( g_poolTableData[ poolid ] [ E_TIMER ] );
    DestroyDynamicObject( g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] );
    g_poolTableData[ poolid ] [ E_AIMER_OBJECT ] = -1;

	for ( new i = 0; i < 16; i ++ ) if ( PHY_IsHandleValid( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] ) ) {
		PHY_DeleteHandle( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] );
		DestroyDynamicObject( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] ) );
		g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] = ITER_NONE;
	}

	UpdateDynamic3DTextLabelText( g_poolTableData[ poolid ] [ E_LABEL ], COLOR_GREY, DEFAULT_POOL_STRING );
	return 1;
}

stock AngleInRangeOfAngle(Float:a1, Float:a2, Float:range) {
	a1 -= a2;
	return (a1 < range) && (a1 > -range);
}

stock Pool_IsObjectAtPos( objectid, Float: x, Float: y, Float: z, Float: radius )
{
    new
    	Float: object_x, Float: object_y, Float: object_z;

    GetDynamicObjectPos( objectid, object_x, object_y, object_z );

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

public OnPoolUpdate( poolid )
{
	if ( ! g_poolTableData[ poolid ] [ E_STARTED ] ) {
		return 1;
	}

	if ( ! Iter_Count( poolplayers< poolid > ) ) {
		Pool_EndGame( poolid );
		return 1;
	}

	new Float: Xa, Float: Ya, Float: Za;
	new Float: X, Float: Y, Float: Z;
	new keys, ud, lr;

	if ( g_poolTableData[ poolid ] [ E_CUE_POCKETED ] )
	{
		new playerid = g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ];
		new cueball_handle = g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ];

		if ( PHY_IsHandleValid( cueball_handle ) )
		{
			new cueball_object = PHY_GetHandleObject( cueball_handle );

			GetPlayerKeys( playerid, keys, ud, lr );
			GetDynamicObjectPos( cueball_object, X, Y, Z );

			if ( ud == KEY_UP ) Y += 0.01;
			else if ( ud == KEY_DOWN ) Y -= 0.01;

			if ( lr == KEY_LEFT ) X -= 0.01;
			else if ( lr == KEY_RIGHT ) X += 0.01;

			// set position only if it is within boundaries
			if ( IsPointInDynamicArea( g_poolTableData[ poolid ] [ E_CUEBALL_AREA ], X, Y, 0.0 ) ) {
				SetDynamicObjectPos( cueball_object, X, Y, Z );
			}

			// click to set
			if ( keys & KEY_FIRE )
			{
				// check if we are placing the pool ball near another pool ball
				for ( new i = 1; i < MAX_POOL_BALLS; i ++ ) if ( PHY_IsHandleValid( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] ) ) {
					GetDynamicObjectPos( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] ), Xa, Ya, Za );
					if ( GetDistanceFromPointToPoint( X, Y, Xa, Ya ) < 0.085 ) {
						return GameTextForPlayer( playerid, "~n~~n~~n~~r~~h~Ball too close to other!", 500, 3 );
					}
				}

				// check if ball is close to hole
				new
					Float: hole_x, Float: hole_y;

				for ( new i = 0; i < sizeof( g_poolPotOffsetData ); i ++ )
				{
					// rotate offsets according to table
					Pool_RotateXY( g_poolPotOffsetData[ i ] [ 0 ], g_poolPotOffsetData[ i ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );

					// check if it is at the pocket
					if ( Pool_IsObjectAtPos( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] ), g_poolTableData[ poolid ] [ E_X ] + hole_x , g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ], POCKET_RADIUS ) ) {
						return GameTextForPlayer( playerid, "~n~~n~~n~~r~~h~Ball too close to hole!", 500, 3 );
					}
				}

				// reset state
				SetCameraBehindPlayer( playerid );
				TogglePlayerControllable( playerid, true );
				g_poolTableData[ poolid ] [ E_CUE_POCKETED ] = false;
				ApplyAnimation( playerid, "CARRY", "crry_prtial", 4.0, 0, 1, 1, 0, 0 );
				Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d) has placed the cueball!", ReturnPlayerName( playerid ), playerid );
			}
		}
	}
	else if ( g_poolTableData[ poolid ] [ E_AIMER ] != -1 )
	{
		new
			playerid = g_poolTableData[ poolid ] [ E_AIMER ];

		GetPlayerKeys( playerid, keys, ud, lr );

		if ( ! ( keys & KEY_FIRE ) )
		{
			if ( lr )
			{
				new Float: x, Float: y, Float: newrot, Float: dist;

				GetPlayerPos(playerid, X, Y ,Z);
				GetDynamicObjectPos( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] ), Xa, Ya, Za);
				newrot = p_PoolAngle[ playerid ] [ 0 ] + ( lr > 0 ? 0.9 : -0.9 );
				dist = GetDistanceBetweenPoints( X, Y, 0.0, Xa, Ya, 0.0 );

				// keep the head out of the point of view
				if ( dist < 1.20 ) {
					dist = 1.20;
				}

				if ( AngleInRangeOfAngle( p_PoolAngle[ playerid ] [ 1 ], newrot, 30.0 ) )
	            {
	                p_PoolAngle[ playerid ] [ 0 ] = newrot;
	                Pool_UpdatePlayerCamera( playerid, poolid );

	                Pool_GetXYInFrontOfPos( Xa, Ya, newrot + 180, x, y, 0.085 );
	                SetDynamicObjectPos( g_poolTableData[ poolid ] [ E_AIMER_OBJECT ], x, y, Za );
	              	SetDynamicObjectRot( g_poolTableData[ poolid ] [ E_AIMER_OBJECT ], 7.0, 0, p_PoolAngle[ playerid ] [ 0 ] + 180 );
	              	Pool_GetXYInFrontOfPos( Xa, Ya, newrot + 180 - 5.0, x, y, dist ); // offset 5 degrees
	                SetPlayerPos( playerid, x, y, Z );
	                SetPlayerFacingAngle( playerid, newrot );
	            }
			}
		}
		else
		{
		    if ( g_poolTableData[ poolid ] [ E_DIRECTION ] ) {
		        g_poolTableData[ poolid ] [ E_POWER ] -= 2.0;
		    } else {
			    g_poolTableData[ poolid ] [ E_POWER ] += 2.0;
			}

			if ( g_poolTableData[ poolid ] [ E_POWER ] <= 0 ) {
			    g_poolTableData[ poolid ] [ E_DIRECTION ] = 0;
			    g_poolTableData[ poolid ] [ E_POWER ] = 2.0;
			}
			else if ( g_poolTableData[ poolid ] [ E_POWER ] > 100.0 ) {
			    g_poolTableData[ poolid ] [ E_DIRECTION ] = 1;
			    g_poolTableData[ poolid ] [ E_POWER ] = 99.0;
			}

			SetPlayerProgressBarMaxValue( playerid, g_PoolPowerBar[ playerid ], 67.0 );
			SetPlayerProgressBarValue( playerid, g_PoolPowerBar[ playerid ], ( ( 67.0 * g_poolTableData[ poolid ] [ E_POWER ] ) / 100.0 ) );
			ShowPlayerProgressBar( playerid, g_PoolPowerBar[ playerid ] );
			TextDrawShowForPlayer( playerid, g_PoolTextdraw );
		}
	}

	new
		current_player = g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ];

	if ( ( ! g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] || g_poolTableData[ poolid ] [ E_FOULS ] || g_poolTableData[ poolid ] [ E_EXTRA_SHOT ] ) && Pool_AreBallsStopped( poolid ) ) {
		Pool_QueueNextPlayer( poolid, current_player );
		SetTimerEx( "RestoreCamera", 800, 0, "d", current_player );
	}
	return 1;
}

public RestoreCamera( playerid )
{
	TextDrawHideForPlayer( playerid, g_PoolTextdraw );
	HidePlayerProgressBar( playerid, g_PoolPowerBar[ playerid ] );
	TogglePlayerControllable( playerid, 1 );
	ApplyAnimation( playerid, "CARRY", "crry_prtial", 4.0, 0, 1, 1, 0, 0 );
	return SetCameraBehindPlayer( playerid );
}

public deleteBall( poolid, ballid )
{
	if ( g_poolBallData[ poolid ] [ E_POCKETED ] [ ballid ] && PHY_IsHandleValid( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ ballid ] ) )
	{
		PHY_DeleteHandle( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ ballid ] );
		DestroyDynamicObject( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ ballid ] ) );
		g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ ballid ] = ITER_NONE;
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
public PHY_OnObjectCollideWithObject( handleid_a, handleid_b )
{
	foreach ( new poolid : pooltables ) if ( g_poolTableData[ poolid ] [ E_STARTED ] )
	{
		for ( new i = 0; i < 16; i ++ )
		{
			new
				table_ball_handle = g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ];

			if ( PHY_IsHandleValid( table_ball_handle ) && PHY_GetHandleObject( handleid_a ) == PHY_GetHandleObject( table_ball_handle ) )
			{
		        PlayPoolSound( poolid, 31800 + random( 3 ) );
		        return 1;
			}
		}
	}
	return 1;
}

public PHY_OnObjectCollideWithWall( handleid, wallid )
{
	foreach ( new poolid : pooltables ) if ( g_poolTableData[ poolid ] [ E_STARTED ] )
	{
		for ( new i = 0; i < 16; i ++ )
		{
			new
				table_ball_handle = g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ];

			if ( PHY_IsHandleValid( table_ball_handle ) && PHY_GetHandleObject( handleid ) == PHY_GetHandleObject( table_ball_handle ) )
			{
		        PlayPoolSound( poolid, 31808 );
		        return 1;
			}
		}
	}
	return 1;
}

public PHY_OnObjectUpdate( handleid )
{
	new objectid = PHY_GetHandleObject( handleid );

	if ( ! IsValidDynamicObject( objectid ) ) {
		return 1;
	}

	new poolball_index = GetPoolBallIndexFromModel( Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID ) );

	if ( poolball_index == -1 ) {
		return 1;
	}

	foreach ( new poolid : pooltables ) if ( g_poolTableData[ poolid ] [ E_STARTED ] )
	{
		new poolball_handle = g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ poolball_index ];

		if ( ! PHY_IsHandleValid( poolball_handle ) ) {
			return 1;
		}

		if ( objectid == PHY_GetHandleObject( poolball_handle ) && ! g_poolBallData[ poolid ] [ E_POCKETED ] [ poolball_index ] && PHY_IsHandleMoving( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ poolball_index ] ) )
		{
			new
				holeid = Pool_IsBallInHole( poolid, objectid );

			if ( holeid != -1 )
			{
				new first_player = Iter_First( poolplayers< poolid > );
				new second_player = Iter_Last( poolplayers< poolid > );
				new current_player = g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ];
				new opposite_player = current_player != first_player ? first_player : second_player;

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
	    					SendClientMessageFormatted( playerid, -1, ""COL_GREY"-- "COL_WHITE" %s(%d) is now playing as %s", ReturnPlayerName( first_player ), first_player, g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ first_player ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ) );
	    					SendClientMessageFormatted( playerid, -1, ""COL_GREY"-- "COL_WHITE" %s(%d) is playing as %s", ReturnPlayerName( second_player ), second_player, g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ second_player ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ) );
	    				}
	    			}
				}

				new Float: hole_x, Float: hole_y;

				// check what was pocketed
				if ( g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_CUE )
				{
	    			GameTextForPlayer( current_player, "~n~~n~~n~~r~wrong ball", 3000, 3);
					Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d) has pocketed the cue ball, %s(%d) will set it!", ReturnPlayerName( current_player ), current_player, ReturnPlayerName( opposite_player ), opposite_player );

					// penalty for that
					g_poolTableData[ poolid ] [ E_FOULS ] ++;
					g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 0;
					g_poolTableData[ poolid ] [ E_EXTRA_SHOT ] = false;
					g_poolTableData[ poolid ] [ E_CUE_POCKETED ] = true;
				}
				else if ( g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_8BALL )
				{
					g_poolTableData[ poolid ] [ E_BALLS_SCORED ] ++;

					// restore player camera
					RestoreCamera( current_player );

					// check if valid shot
					if ( p_PoolScore[ current_player ] < 7 )
					{
						p_PoolScore[ opposite_player ] ++;
						Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d) has accidentally pocketed the 8-Ball ... %s(%d) wins!", ReturnPlayerName( current_player ), current_player, ReturnPlayerName( opposite_player ), opposite_player );
						Pool_OnPlayerWin( poolid, opposite_player );
					}
					else if ( g_poolTableData[ poolid ] [ E_PLAYER_8BALL_TARGET ] [ current_player ] != holeid )
					{
						p_PoolScore[ opposite_player ] ++;
						Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d) has put the 8-Ball in the wrong pocket ... %s(%d) wins!", ReturnPlayerName( current_player ), current_player, ReturnPlayerName( opposite_player ), opposite_player );
						Pool_OnPlayerWin( poolid, opposite_player );
					}
					else
					{
						p_PoolScore[ current_player ] ++;
						Pool_OnPlayerWin( poolid, current_player );
					}
					return Pool_EndGame( poolid );
				}
				else
				{
					// check if player pocketed their own ball type or btfo
					if ( g_poolTableData[ poolid ] [ E_BALLS_SCORED ] > 1 && g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ current_player ] != g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] )
					{
	    				p_PoolScore[ opposite_player ] += 1;
	    				GameTextForPlayer( current_player, "~n~~n~~n~~r~wrong ball", 3000, 3);
	    				Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d) has wrongly pocketed %s %s, instead of %s!", ReturnPlayerName( current_player ), current_player, g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ), g_poolBallOffsetData[ poolball_index ] [ E_BALL_NAME ], g_poolTableData[ poolid ] [ E_PLAYER_BALL_TYPE ] [ current_player ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ) );

						// penalty for that
						g_poolTableData[ poolid ] [ E_FOULS ] ++;
						g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 0;
						g_poolTableData[ poolid ] [ E_EXTRA_SHOT ] = false;
					}
					else
					{
	    				p_PoolScore[ current_player ] ++;
	    				GameTextForPlayer( current_player, "~n~~n~~n~~g~+1 score", 3000, 3);
	    				Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d) has pocketed a %s %s!", ReturnPlayerName( current_player ), current_player, g_poolBallOffsetData[ poolball_index ] [ E_BALL_TYPE ] == E_STRIPED ? ( "Striped" ) : ( "Solid" ), g_poolBallOffsetData[ poolball_index ] [ E_BALL_NAME ] );

						// extra shot for scoring one's own
						g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = g_poolTableData[ poolid ] [ E_FOULS ] > 0 ? 0 : 1;
						g_poolTableData[ poolid ] [ E_EXTRA_SHOT ] = true;
					}

					// mark final target hole
					if ( ( p_PoolScore[ first_player ] == 7 && p_PoolHoleGuide[ first_player ] == -1 ) || ( p_PoolScore[ second_player ] == 7 && p_PoolHoleGuide[ second_player ] == -1 ) )
					{
						foreach ( new player_being_marked : poolplayers< poolid > ) if ( p_PoolScore[ player_being_marked ] == 7 && p_PoolHoleGuide[ player_being_marked ] == -1 )
						{
							new
								opposite_holeid = g_poolHoleOpposite[ holeid ];

							Pool_RotateXY( g_poolPotOffsetData[ opposite_holeid ] [ 0 ], g_poolPotOffsetData[ opposite_holeid ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );
							p_PoolHoleGuide[ player_being_marked ] = CreateDynamicObject( 18643, g_poolTableData[ poolid ] [ E_X ] + hole_x, g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ] - 0.5, 0.0, -90.0, 0.0, .playerid = player_being_marked );
							g_poolTableData[ poolid ] [ E_PLAYER_8BALL_TARGET ] [ player_being_marked ] = opposite_holeid;
							SendPoolMessage( player_being_marked, "You are now required to put the 8-Ball in the designated pocket." );
							Streamer_Update( player_being_marked );
						}
					}
				}

				// rotate hole offsets according to table
				Pool_RotateXY( g_poolPotOffsetData[ holeid ] [ 0 ], g_poolPotOffsetData[ holeid ] [ 1 ], g_poolTableData[ poolid ] [ E_ANGLE ], hole_x, hole_y );

				// move object into the pocket
				new move_speed = MoveDynamicObject( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ poolball_index ] ), g_poolTableData[ poolid ] [ E_X ] + hole_x, g_poolTableData[ poolid ] [ E_Y ] + hole_y, g_poolTableData[ poolid ] [ E_Z ] - 0.5, 1.0);

				// mark ball as pocketed
				g_poolBallData[ poolid ] [ E_POCKETED ] [ poolball_index ] = true;

				// delete it anyway
				SetTimerEx( "deleteBall", move_speed + 100, false, "dd", poolid, poolball_index );

				// update scoreboard
				Pool_UpdateScoreboard( poolid );
				PlayerPlaySound( current_player, 31803, 0.0, 0.0, 0.0 );
			}
			return 1;
		}
	}
	return 1;
}

stock Pool_OnPlayerWin( poolid, winning_player )
{
	if ( ! IsPlayerConnected( winning_player ) && ! IsPlayerNPC( winning_player ) )
		return 0;

	new
		win_amount = floatround( float( g_poolTableData[ poolid ] [ E_WAGER ] ) * ( 1 - POOL_FEE_RATE ) * 2.0 );

	// restore camera
	RestoreCamera( winning_player );
	GivePlayerCash( winning_player, win_amount );

	// winning player
	Pool_SendTableMessage( poolid, -1, "{9FCF30}****************************************************************************************");
	Pool_SendTableMessage( poolid, -1, "{9FCF30}Player {FF8000}%s {9FCF30}has won the game!", ReturnPlayerName( winning_player ) );
	Pool_SendTableMessage( poolid, -1, "{9FCF30}Prize: {377CC8}%s | -%0.0f%s percent fee", cash_format( win_amount ), win_amount > 0 ? POOL_FEE_RATE * 100.0 : 0.0, "%%");
	Pool_SendTableMessage( poolid, -1, "{9FCF30}****************************************************************************************");
	return 1;
}

stock Pool_QueueNextPlayer( poolid, current_player )
{
	if ( g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] && g_poolTableData[ poolid ] [ E_FOULS ] < 1 )
	{
		g_poolTableData[ poolid ] [ E_EXTRA_SHOT ] = false;
		Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d) has an extra shot remaining!", ReturnPlayerName( current_player ), current_player );
	}
	else
	{
		new first_player = Iter_First( poolplayers< poolid > );
		new second_player = Iter_Last( poolplayers< poolid > );

		g_poolTableData[ poolid ] [ E_FOULS ] = 0;
		g_poolTableData[ poolid ] [ E_SHOTS_LEFT ] = 1;
		g_poolTableData[ poolid ] [ E_EXTRA_SHOT ] = false;
	    g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] = current_player == first_player ? second_player : first_player;

		// reset ball positions just incase
		Pool_SendTableMessage( poolid, -1, "{2DD9A9} * * %s(%d)'s turn to play!", ReturnPlayerName( g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] ), g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ] );
	}

	// respawn the cue ball if it has been pocketed
	Pool_RespawnCueBall( poolid );

	// update turn
	Pool_UpdateScoreboard( poolid );
	Pool_ResetBallPositions( poolid );
}

stock Pool_SendTableMessage( poolid, colour, const format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach ( new i : poolplayers< poolid > ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock Pool_RespawnCueBall( poolid )
{
    if ( g_poolBallData[ poolid ] [ E_POCKETED ] [ 0 ] )
	{
		new
			Float: x, Float: y;

		Pool_RotateXY( 0.5, 0.0, g_poolTableData[ poolid ] [ E_ANGLE ], x, y );

		// make sure object dont exist
		if ( PHY_IsHandleValid( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] ) ) {
			PHY_DeleteHandle( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] );
	        DestroyDynamicObject( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] ) );
		}

        // recreate cueball
		new cueball_object = CreateDynamicObject( 3003, g_poolTableData[ poolid ] [ E_X ] + x, g_poolTableData[ poolid ] [ E_Y ] + y, g_poolTableData[ poolid ] [ E_Z ] - 0.045, 0.0, 0.0, 0.0, .worldid = g_poolTableData[ poolid ] [ E_WORLD ], .priority = 999 );
        Pool_InitBalls( poolid, cueball_object, 0 );

		// set next player camera
		new next_shooter = g_poolTableData[ poolid ] [ E_NEXT_SHOOTER ];
		SetPlayerCameraPos( next_shooter, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0 );
		SetPlayerCameraLookAt( next_shooter, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] );
		ApplyAnimation( next_shooter, "POOL", "POOL_Idle_Stance", 3.0, 0, 1, 1, 0, 0, 1 );
		TogglePlayerControllable( next_shooter, false );
	}
}

stock Pool_ResetBallPositions( poolid, begining_ball = 0, last_ball = MAX_POOL_BALLS )
{
	static Float: last_x, Float: last_y, Float: last_z;
	static Float: last_rx, Float: last_ry, Float: last_rz;

	for ( new i = begining_ball; i < last_ball; i ++ ) if ( ! g_poolBallData[ poolid ] [ E_POCKETED ] [ i ] )
	{
		new
			ball_handle = g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ];

		if ( ! PHY_IsHandleValid( ball_handle ) )
			continue;

		new
			ball_object = PHY_GetHandleObject( ball_handle );

		if ( ! IsValidDynamicObject( ball_object ) )
			continue;

		new
			modelid = Streamer_GetIntData( STREAMER_TYPE_OBJECT, ball_object, E_STREAMER_MODEL_ID );  //FIX

		// get current position
		GetDynamicObjectPos( ball_object, last_x, last_y, last_z );
		GetDynamicObjectRot( ball_object, last_rx, last_ry, last_rz );

		// destroy object
		if ( PHY_IsHandleValid( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] ) ) {
			PHY_DeleteHandle( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ i ] );
			DestroyDynamicObject( ball_object );
		}

		// create pool balls on table
		new object = CreateDynamicObject( modelid, last_x, last_y, last_z, last_rx, last_ry, last_rz, .worldid = g_poolTableData[ poolid ] [ E_WORLD ], .priority = 999 );

		// initialize physics on each ball
		Pool_InitBalls( poolid, object, i );
	}

	// show objects
	foreach ( new playerid : poolplayers< poolid > ) {
		Streamer_Update( playerid, STREAMER_TYPE_OBJECT );
	}
}

hook OnPlayerShootDynObject( playerid, weaponid, objectid, Float: x, Float: y, Float: z )
{
	// check if a player shot a pool ball and restore it
	new
		poolball_index = GetPoolBallIndexFromModel( Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID ) );

	if ( poolball_index != -1 ) {
		foreach ( new poolid : pooltables ) if ( g_poolTableData[ poolid ] [ E_STARTED ] && ( g_poolBallData[ poolid ] [ E_POCKETED ] [ poolball_index ] || ! PHY_IsHandleMoving( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ poolball_index ] ) ) ) {
			Pool_ResetBallPositions( poolid, poolball_index, poolball_index + 1 );
			break;
		}
		return 0; // desync the shot
	}
    return 1;
}

stock Pool_UpdatePlayerCamera( playerid, poolid )
{
	new
		Float: Xa, Float: Ya, Float: Za;

	GetDynamicObjectPos( PHY_GetHandleObject( g_poolBallData[ poolid ] [ E_BALL_PHY_HANDLE ] [ 0 ] ), Xa, Ya, Za );

	if ( ! p_PoolCameraBirdsEye{ playerid } )
	{
	    new
	    	Float: x = Xa, Float: y = Ya;

	    x += ( 0.675 * floatsin( -p_PoolAngle[ playerid ] [ 0 ] + 180.0, degrees ) );
	    y += ( 0.675 * floatcos( -p_PoolAngle[ playerid ] [ 0 ] + 180.0, degrees ) );

		SetPlayerCameraPos( playerid, x, y, g_poolTableData[ poolid ] [ E_Z ] + DEFAULT_AIM );
		SetPlayerCameraLookAt( playerid, Xa, Ya, Za + 0.170 );
	}
	else
	{
		SetPlayerCameraPos( playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] + 2.0 );
		SetPlayerCameraLookAt( playerid, g_poolTableData[ poolid ] [ E_X ], g_poolTableData[ poolid ] [ E_Y ], g_poolTableData[ poolid ] [ E_Z ] );
	}
}

stock IsPlayerPlayingPool( playerid ) {
	return p_isPlayingPool{ playerid };
}

/* ** Commands ** */
CMD:endgame(playerid)
{
	if ( ! IsPlayerAdmin( playerid ) )
		return 0;

	new iPool = Pool_GetClosestTable( playerid );

	if ( iPool == -1 )
		return SendError( playerid, "You must be near a pool table to use this command." );

	Pool_EndGame( iPool );

	SendClientMessage(playerid, -1, ""COL_PINK"[ADMIN]"COL_WHITE" You have force ended the pool game!");
	return 1;
}

CMD:addpool(playerid, params[])
{
	if ( p_AdminLevel[ playerid ] < 6 )
		return SendError( playerid, ADMIN_COMMAND_REJECT );

	new
		Float: x, Float: y, Float: z;

	if ( GetPlayerPos( playerid, x, y, z ) )
	{
		CreatePoolTable( x + 1.0, y + 1.0, z, floatstr(params), POOL_SKIN_DEFAULT, GetPlayerInterior( playerid ), GetPlayerVirtualWorld( playerid ) );
		SendClientMessage(playerid, -1, ""COL_PINK"[ADMIN]{FFFFFF} You have created a pool table.");
	}
	return 1;
}

/* ** Debug Mode ** */
#if defined POOL_DEBUG
	new potlabels_x[MAX_POOL_TABLES][sizeof(g_poolPotOffsetData)];
	new potlabels[MAX_POOL_TABLES][sizeof(g_poolPotOffsetData)][36];

	CMD:camtest( playerid, params[ ] )
	{
		new
			iPool = Pool_GetClosestTable( playerid );

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
		new iPool = Pool_GetClosestTable( playerid );
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
			potlabels_x[ gID ] [ i ] = CreateDynamicObject( 18643, pot_x, pot_y, pot_z - 1.0, 0.0, -90.0, 0.0, .worldid = g_poolTableData[ poolid ] [ E_WORLD ] );

			for ( new Float: angle = 0.0, c = 0; angle < 360.0; angle += 10.0, c ++ )
			{
			    new Float: rad_x = pot_x + ( POCKET_RADIUS * floatsin( -angle, degrees ) );
			    new Float: rad_y = pot_y + ( POCKET_RADIUS * floatcos( -angle, degrees ) );

				//DestroyDynamic3DTextLabel( potlabels[ gID ] [ i ] [ c ] );
				//potlabels[ gID ] [ i ] [ c ] = CreateDynamic3DTextLabel( ".", COLOR_WHITE, rad_x, rad_y, pot_z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0 );
				DestroyDynamicObject( potlabels[ gID ] [ i ] [ c ] );
				potlabels[ gID ] [ i ] [ c ] = CreateDynamicObject( 18643, rad_x, rad_y, pot_z - 1.0, 0.0, -90.0, 0.0, .worldid = g_poolTableData[ poolid ] [ E_WORLD ] );
			}
		}
		return Streamer_Update( playerid ), 1;
	}

	CMD:play(playerid)
	{
		new
			iPool = Pool_GetClosestTable( playerid );

		if ( iPool == -1 )
			return SendError( playerid, "You are not near a pool table." );

		if ( ! IsPlayerPlayingPool( playerid ))
		{
			p_isPlayingPool { playerid } = true;
			p_PoolID[ playerid ]		 = iPool;

			PlayerPlaySound( playerid, 1085, 0.0, 0.0, 0.0 );
			GivePlayerWeapon( playerid, 7, 1 );

			p_PoolScore[ playerid ] = 0;

			if ( ! g_poolTableData[ iPool ] [ E_STARTED ] )
			{
				g_poolTableData[ iPool ] [ E_STARTED ] = true;

				Iter_Clear( poolplayers< iPool > );
				Iter_Add( poolplayers< iPool >, playerid );
				Iter_Add( poolplayers< iPool >, playerid );

				UpdateDynamic3DTextLabelText(g_poolTableData[ iPool ] [ E_LABEL ], -1, sprintf( "{FFDC2E}%s is currently playing a test game.", ReturnPlayerName( playerid )) );

				Pool_RespawnBalls( iPool );
			}
		}
		else
		{
			Pool_EndGame( iPool );
		}
		return 1;
	}
#endif
