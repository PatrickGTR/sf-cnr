/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: roulette.inc
 * Purpose: roulette implementation in SA-MP
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error checking ** */
#if !defined __irresistible_servervars
    #error "You need server variables enabled to track betting."
#endif

/*#if !defined _merrandom_included
    #define MRandom random
#endif*/

/* ** Definitions ** */
#define MAX_ROULETTE_TABLES 		29

/* ** Macros ** */
#define IsPlayerOnRoulette(%0)		(p_RouletteTable[%0]!=-1)
#define IsRedRouletteNumber(%0) 	(%0 == 1 || %0 == 3 || %0 == 5 || %0 == 7 || %0 == 9 || %0 == 12 || %0 == 14 || %0 == 16 || %0 == 18 || %0 == 19 || %0 == 21 || %0 == 23 || %0 == 25 || %0 == 27 || %0 == 30 || %0 == 32 || %0 == 34 || %0 == 36)

/* ** Constants ** */
enum E_ROULETTE_OFFSET_DATA
{
	E_VALUE,  					Float: E_OFFSET, 				Float: E_ANGLE
};

static const
	Float: g_rouletteOffsets[ ] [ E_ROULETTE_OFFSET_DATA ] = {

		{ 0, 0.6, 85.0 }, // 0

		// 1, 2, 3
		{ 1, 0.50, 110.0 }, { 2, 0.44, 85.0 }, { 3, 0.55, 55.0 },

		// 4, 5, 6
		{ 4, 0.31, 120.0 }, { 5, 0.3, 75.0 }, { 6, 0.43, 40.0 },

		// 7, 8, 9
		{ 7, 0.20, 147.0 }, { 8, 0.13, 55.0 }, { 9, 0.32, 18.0 },

		// 10, 11, 12
		{ 10, 0.17, 195.0 }, { 11, 0.08, -25.0 }, { 12, 0.32, -10.0 },

		// 13, 14, 15
		{ 13, 0.25, 230.0 }, { 14, 0.22, -70.0 }, { 15, 0.38, -33.0 },

		// 16, 17, 18
		{ 16, 0.39, 244.0 }, { 17, -0.35, 103.0 }, { 18, 0.48, -48.0 },

		// 19, 20, 21
		{ 19, 0.53, 251.0 }, { 20, 0.51, 278.0 }, { 21, 0.6, -58.0 },

		// 22, 23, 24
		{ 22, 0.68, 256.0 }, { 23, 0.66, 276.0 }, { 24, 0.73, 295.0 },

		// 25, 26, 27
		{ 25, 0.82, 259.0 }, { 26, 0.81, 275.0 }, { 27, 0.87, 292.0 },

		// 28, 29, 30
		{ 28, 0.97, 261.0 }, { 29, 0.96, 275.0 }, { 30, 1.01, 289.0 },

		// 31, 32, 33
		{ 31, 1.12, 264.0 }, { 32, 1.12, 274.0 }, { 33, 1.17, 286.0 },

		// 34, 35, 36
		{ 34, 1.28, 264.0 }, { 35, 1.27, 274.0 }, { 36, 1.31, 284.0 },

		// 3to1, 3to1, 3to1
		{ 3211, 1.43, 264.0 }, { 3212, 1.42, 273.0 }, { 3213, 1.45, 283.0 },

		// 1-18, even, 1st to 12
		{ 118, 0.73, 152.0 },{ 222, 0.65, 178.0 }, { 112, 0.46, 153.0 },

		// red, black, 2nd 12
		{ 88, 0.7, 202.0 }, { 44, 0.87, 222.0 }, { 212, 0.59, 227.0 },

		// odd, 19 to 36, 3rd 12
		{ 333, 1.09, 233.0 }, { 1936, 1.35, 241.0 },{ 312, 1.12, 249.0 }
	}
;

/* ** Variables ** */
enum E_ROULETTE_DATA
{
	E_OBJECT, 					E_SPINNER_OBJECT, 				E_SPINNING_TIMER,
	bool: E_NO_MORE_BETS,		E_WORLD,						E_ACTOR,

	E_MAX_BET,

	Float: E_X, 				Float: E_Y, 					Float: E_Z,
	Float: E_ROTATION
};


new
	g_rouletteTableData			[ MAX_ROULETTE_TABLES ] [ E_ROULETTE_DATA ],
	Iterator: roulettetables 	< MAX_ROULETTE_TABLES >,

	Text: g_rouletteNumberBG		[ MAX_ROULETTE_TABLES ],
	Text: g_rouletteNumberTD		[ MAX_ROULETTE_TABLES ],

	g_rouletteChipColor			[ MAX_PLAYERS ],
	g_rouletteChip				[ MAX_PLAYERS ] [ 2 ] [ sizeof( g_rouletteOffsets ) ],
	g_rouletteChipValue			[ MAX_PLAYERS ] [ sizeof( g_rouletteOffsets ) ],
	Text3D: g_rouletteChipLabel	[ MAX_PLAYERS ] [ sizeof( g_rouletteOffsets ) ],
	p_rouletteBetValue			[ MAX_PLAYERS ],

	p_RouletteMarkerTimer 		[ MAX_PLAYERS ] = { -1, ... },
	p_RouletteMarker 			[ MAX_PLAYERS ] = { -1, ... },
	p_RouletteTable 			[ MAX_PLAYERS ] = { -1, ... },
	p_RouletteMarkerColumn 		[ MAX_PLAYERS char ],
	bool: p_rouletteBetLocked 	[ MAX_PLAYERS char ]
;

/* ** Forwards ** */
public OnRouletteWheelStop( rouletteid, winner );
public OnSpinRouletteTable( rouletteid, elapsed, steps );
public OnRouletteMarkerUpdate( playerid );

/* ** Hooks ** */
hook OnGameModeInit( )
{
	// server variables
	AddServerVariable( "roulette_bets", "0.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "roulette_wins", "0.0", GLOBAL_VARTYPE_FLOAT );

	// create roulette tables
	CreateRouletteTable( 2242.36719, 1589.18750, 1006.22662, -90.0000, 82 );
	CreateRouletteTable( 2242.36719, 1594.75781, 1006.22662, 90.00000, 82 );
	CreateRouletteTable( 2230.57031, 1589.18750, 1006.22662, -90.0000, 82 );
	CreateRouletteTable( 2230.57031, 1594.75781, 1006.22662, 90.00000, 82 );
	CreateRouletteTable( 2230.57031, 1614.59375, 1006.22662, -90.0000, 82 );
	CreateRouletteTable( 2230.57031, 1619.65625, 1006.22662, 90.00000, 82 );
	CreateRouletteTable( 2241.44531, 1614.55469, 1006.22662, -90.0000, 82 );
	CreateRouletteTable( 2241.44531, 1619.60938, 1006.22662, 90.00000, 82 );
	CreateRouletteTable( 1963.71094, 1025.69531, 992.507810, 0.000000, 23 );
	CreateRouletteTable( 1959.39844, 1025.69531, 992.507810, 0.000000, 23 );
	CreateRouletteTable( 1963.71094, 1010.11719, 992.507810, 0.000000, 23 );
	CreateRouletteTable( 1959.39844, 1010.11719, 992.507810, 0.000000, 23 );
	return 1;
}

hook OnPlayerConnect( playerid )
{
	for ( new i = 0; i < sizeof( g_rouletteOffsets ); i ++ ) {
		g_rouletteChip[ playerid ] [ 0 ] [ i ] = -1;
		g_rouletteChip[ playerid ] [ 1 ] [ i ] = -1;
		g_rouletteChipLabel[ playerid ] [ i ] = Text3D: INVALID_3DTEXT_ID;
		g_rouletteChipValue[ playerid ] [ i ] = 0;
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	RemovePlayerFromRoulette( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
    RemovePlayerFromRoulette( playerid );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	static
		Float: X, Float: Y, Float: Z, Float: Angle;

	if ( IsPlayerInCasino( playerid ) )
	{
		// Roulette
		if ( p_RouletteMarkerTimer[ playerid ] != -1 )
		{
			new
				rouletteid = p_RouletteTable[ playerid ];

			if ( ! Iter_Contains( roulettetables, rouletteid ) )
				return SendServerMessage( playerid, "Invalid Roulette Table." );

			if ( GetDistanceFromPlayerSquared( playerid, g_rouletteTableData[ rouletteid ] [ E_X ], g_rouletteTableData[ rouletteid ] [ E_Y ], g_rouletteTableData[ rouletteid ] [ E_Z ] ) > 16.0 ) // Squared
				return RemovePlayerFromRoulette( playerid );

			// confirm bet
			if ( PRESSED( KEY_SPRINT ) )
			{
				if ( g_rouletteTableData[ rouletteid ] [ E_NO_MORE_BETS ] )
					return SendError( playerid, "This roulette table must finish its spin before you can bet again." );

				if ( p_rouletteBetLocked{ playerid } )
					return SendError( playerid, "You have already locked in your bet. Wait for the spin to finish." );

				new
					totalBet = GetPlayerTotalRouletteBet( playerid );

				if ( totalBet <= 0 )
					return SendError( playerid, "You cannot spin the roulette without having placed any bets." );

				if ( totalBet > GetPlayerCash( playerid ) )
					return SendError( playerid, "You do not have enough money to make this bet." );

				// deduct money
				GivePlayerCash( playerid, -totalBet );

				// lock the player in
				p_rouletteBetLocked{ playerid } = true;

				if ( g_rouletteTableData[ rouletteid ] [ E_SPINNING_TIMER ] == -1 )
				{
					// randomize string
					GenerateRandomRouletteNumber( rouletteid );

					foreach (new i : Player) if ( p_RouletteTable[ i ] == rouletteid )
					{
						PlayerPlaySound( i, 33400, 0.0, 0.0, 0.0 );
						TextDrawShowForPlayer( i, g_rouletteNumberBG[ rouletteid ] );
						TextDrawShowForPlayer( i, g_rouletteNumberTD[ rouletteid ] );

						if ( ! p_rouletteBetLocked{ i } ) {
							SendServerMessage( i, "%s(%d) has waged %s with this spin, press SPACE to join the spin!", ReturnPlayerName( playerid ), playerid, ConvertPrice( totalBet ) );
						}
					}

					// animation
				    ApplyDynamicActorAnimation( g_rouletteTableData[ rouletteid ] [ E_ACTOR ], "CASINO", "roulette_bet", 4.1, 0, 0, 0, 0, 0 );
				    ApplyDynamicActorAnimation( g_rouletteTableData[ rouletteid ] [ E_ACTOR ], "CASINO", "roulette_bet", 4.1, 0, 0, 0, 0, 0 );

					// allow bets
					g_rouletteTableData[ rouletteid ] [ E_NO_MORE_BETS ] = false;

					// fire the spin table
					g_rouletteTableData[ rouletteid ] [ E_SPINNING_TIMER ] = SetTimerEx( "OnSpinRouletteTable", 25, false, "ddd", rouletteid, 0, 1 );

					// inform other players
					SendServerMessage( playerid, "You have begun the spin with a wager of %s. Good luck!", ConvertPrice( totalBet ) );
				}
				else SendServerMessage( playerid, "You have joined the spin. Good luck!" );
			}
			// decrease bet
			if ( PRESSED( KEY_WALK ) )
			{
				if ( ( p_rouletteBetValue[ playerid ] /= 2 ) < 1000 )
					p_rouletteBetValue[ playerid ] = 1000;

				SendServerMessage( playerid, "You are now betting %s, gamble responsibly!", ConvertPrice( p_rouletteBetValue[ playerid ] ) );
			}

			// increase bet
			if ( PRESSED( KEY_JUMP  ) )
			{
				if ( ( p_rouletteBetValue[ playerid ] *= 2 ) > g_rouletteTableData[ rouletteid ] [ E_MAX_BET ] )
					p_rouletteBetValue[ playerid ] = g_rouletteTableData[ rouletteid ] [ E_MAX_BET ];

				SendServerMessage( playerid, "You are now betting %s, gamble responsibly!", ConvertPrice( p_rouletteBetValue[ playerid ] ) );
			}

			// Cancel Bets
			if ( PRESSED( KEY_CROUCH ) )
			{
				if ( p_rouletteBetLocked{ playerid } )
					return SendError( playerid, "You cannot cancel your bet once you have entered a spin." );

				for ( new column = 0; column < sizeof( g_rouletteOffsets ); column ++ )
				{
					g_rouletteChipValue[ playerid ] [ column ] = 0;
					DestroyDynamicObject( g_rouletteChip[ playerid ] [ 0 ] [ column ] ), g_rouletteChip[ playerid ] [ 0 ] [ column ] = -1;
					DestroyDynamicObject( g_rouletteChip[ playerid ] [ 1 ] [ column ] ), g_rouletteChip[ playerid ] [ 1 ] [ column ] = -1;
					DestroyDynamic3DTextLabel( g_rouletteChipLabel[ playerid ] [ column ] ), g_rouletteChipLabel[ playerid ] [ column ] = Text3D: INVALID_3DTEXT_ID;
				}
			}

			// Place bet
			if ( PRESSED( KEY_FIRE ) || PRESSED( KEY_AIM ) )
			{
				if ( p_rouletteBetLocked{ playerid } )
					return SendError( playerid, "You cannot change your bet once you have entered a spin." );

				new
					column = p_RouletteMarkerColumn{ playerid };

				new Float: offsetX = g_rouletteTableData[ rouletteid ] [ E_X ] + g_rouletteOffsets[ column ] [ E_OFFSET ] * floatcos( g_rouletteTableData[ rouletteid ] [ E_ROTATION ] + g_rouletteOffsets[ column ] [ E_ANGLE ], degrees );
				new Float: offsetY = g_rouletteTableData[ rouletteid ] [ E_Y ] + g_rouletteOffsets[ column ] [ E_OFFSET ] * floatsin( g_rouletteTableData[ rouletteid ] [ E_ROTATION ] + g_rouletteOffsets[ column ] [ E_ANGLE ], degrees );

				if ( PRESSED( KEY_FIRE ) )
				{
					new
						totalBet = GetPlayerTotalRouletteBet( playerid );

					// Check if the player has even money
					if ( totalBet > GetPlayerCash( playerid ) ) {
						return SendError( playerid, "You cannot afford to wager any more money!" );
					}

					// Exceeded The Maximum
					if ( totalBet + p_rouletteBetValue[ playerid ] > g_rouletteTableData[ rouletteid ] [ E_MAX_BET ] ) {
						return SendError( playerid, "You are only allowed to bet a total of %s per spin on this table.", ConvertPrice( g_rouletteTableData[ rouletteid ] [ E_MAX_BET ] ) );
					}

					PlayerPlaySound( playerid, 1083, 0.0, 0.0, 5.0 );
					g_rouletteChipValue[ playerid ] [ column ] += p_rouletteBetValue[ playerid ];
				}
				else
				{
					PlayerPlaySound( playerid, 1084, 0.0, 0.0, 5.0 );
					g_rouletteChipValue[ playerid ] [ column ] -= p_rouletteBetValue[ playerid ];
				}

				//printf("COLUMN : %d", column);
				if ( g_rouletteChipValue[ playerid ] [ column ] <= 0 )
				{
					DestroyDynamic3DTextLabel( g_rouletteChipLabel[ playerid ] [ column ] ), g_rouletteChipLabel[ playerid ] [ column ] = Text3D: -1;
					DestroyDynamicObject( g_rouletteChip[ playerid ] [ 0 ] [ column ] ), g_rouletteChip[ playerid ] [ 0 ] [ column ] = -1;
					DestroyDynamicObject( g_rouletteChip[ playerid ] [ 1 ] [ column ] ), g_rouletteChip[ playerid ] [ 1 ] [ column ] = -1;
					g_rouletteChipValue[ playerid ] [ column ] = 0;
					//printf("removed");
				}
				else
				{
					// Calculate chip height
					new Float: height = 0.295 - float( g_rouletteChipValue[ playerid ] [ column ] / 1000 ) * 0.005;

					// readjust max height
					if ( height < 0.18 ) height = 0.18;

					// store color
					new color = ( g_rouletteChipColor[ playerid ] >> 8 ) | 0x99000000;

					//printf("g_rouletteChip[%s][%d] = %d", ReturnPlayerName( playerid ), column, g_rouletteChip[ playerid ] [ column ] );
					if ( g_rouletteChip[ playerid ] [ 0 ] [ column ] == -1 )
					{
						g_rouletteChip[ playerid ] [ 0 ] [ column ] = CreateDynamicObject( 1902, offsetX, offsetY, g_rouletteTableData[ rouletteid ] [ E_Z ] - height, 0.0, 0.0, 0.0, .worldid = g_rouletteTableData[ rouletteid ] [ E_WORLD ], .priority = 9999 );
						SetDynamicObjectMaterialText( g_rouletteChip[ playerid ] [ 0 ] [ column ], 0, " ", .backcolor = color );
						g_rouletteChip[ playerid ] [ 1 ] [ column ] = CreateDynamicObject(1905, offsetX, offsetY, g_rouletteTableData[ rouletteid ] [ E_Z ] - height + 0.125, 0.0, 0.0, 0.0, .worldid = g_rouletteTableData[ rouletteid ] [ E_WORLD ], .priority = 9999);
						SetDynamicObjectMaterialText( g_rouletteChip[ playerid ] [ 1 ] [ column ], 0, ConvertRouletteChipValue( g_rouletteChipValue[ playerid ] [ column ] ), 50, "Arial", 44, 1, color, -1, 1 );
						g_rouletteChipLabel[ playerid ] [ column ] = CreateDynamic3DTextLabel( sprintf( "%s", ConvertPrice( g_rouletteChipValue[ playerid ] [ column ] ) ), g_rouletteChipColor[ playerid ], offsetX, offsetY, g_rouletteTableData[ rouletteid ] [ E_Z ] - 0.15 + ( float( playerid ) / 100 ), 5.0 ); //INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, playerid );
						//printf("(%s) CREATED CHIP %d:%d", ReturnPlayerName( playerid ), g_rouletteChip[ playerid ] [ column ], _: g_rouletteChipLabel[ playerid ] [ column ] );
					}
					else
					{
						SetDynamicObjectMaterialText( g_rouletteChip[ playerid ] [ 1 ] [ column ], 0, ConvertRouletteChipValue( g_rouletteChipValue[ playerid ] [ column ] ), 50, "Arial", 44, 1, color, -1, 1 );
						SetDynamicObjectPos( g_rouletteChip[ playerid ] [ 0 ] [ column ], offsetX, offsetY, g_rouletteTableData[ rouletteid ] [ E_Z ] - height );
						SetDynamicObjectPos( g_rouletteChip[ playerid ] [ 1 ] [ column ], offsetX, offsetY, g_rouletteTableData[ rouletteid ] [ E_Z ] - height + 0.125 );
						UpdateDynamic3DTextLabelText( g_rouletteChipLabel[ playerid ] [ column ], g_rouletteChipColor[ playerid ], sprintf( "%s", ConvertPrice( g_rouletteChipValue[ playerid ] [ column ] ) ) );
						//printf("(%s) UPDATED CHIP %d:%d", ReturnPlayerName( playerid ), g_rouletteChip[ playerid ] [ column ], _: g_rouletteChipLabel[ playerid ] [ column ] );
					}
				}

				// sometimes it doesnt show up
				// SyncObject( playerid, 0.005, 0.005, 0.005 );
				Streamer_Update( playerid );
				ApplyAnimation( playerid, "DEALER", "DEALER_IDLE", 4.1, 1, 1, 1, 1, 0, 1 );
			}
		}

		if ( PRESSED( KEY_SECONDARY_ATTACK ) )
		{
			if ( p_rouletteBetLocked{ playerid } )
				return SendError( playerid, "Please wait until the spin is completed before leaving the table." );

			if ( p_RouletteTable[ playerid ] != -1 )
				return RemovePlayerFromRoulette( playerid );

			foreach(new id : roulettetables) if ( GetPlayerVirtualWorld( playerid ) == g_rouletteTableData[ id ] [ E_WORLD ] )
			{
				if ( IsPlayerInRangeOfPoint( playerid, 3.1, g_rouletteTableData[ id ] [ E_X ], g_rouletteTableData[ id ] [ E_Y ], g_rouletteTableData[ id ] [ E_Z ] ) ) {

					static
						Float: lookatX, Float: lookatY, Float: lookatZ,
						Float: tmpX, Float: tmpY, Float: tmpZ
					;

					GetPlayerCameraPos( playerid, X, Y, Z );
					GetPlayerCameraFrontVector( playerid, lookatX, lookatY, lookatZ );

					tmpX = g_rouletteTableData[ id ] [ E_X ] + -1.8 * floatcos( g_rouletteTableData[ id ] [ E_ROTATION ] + 74.0, degrees );
					tmpY = g_rouletteTableData[ id ] [ E_Y ] + -1.8 * floatsin( g_rouletteTableData[ id ] [ E_ROTATION ] + 74.0, degrees );
					tmpZ = g_rouletteTableData[ id ] [ E_Z ] + 1.7;

					InterpolateCameraPos( playerid, X, Y, Z, tmpX, tmpY, tmpZ, 1000, CAMERA_MOVE );

					X += floatmul( lookatX, 20.0 );
					Y += floatmul( lookatY, 20.0 );
					Z += floatmul( lookatZ, 20.0 );

					InterpolateCameraLookAt( playerid, X, Y, Z, g_rouletteTableData[ id ] [ E_X ], g_rouletteTableData[ id ] [ E_Y ], g_rouletteTableData[ id ] [ E_Z ] - 1.0, 1000, CAMERA_MOVE );

					p_RouletteTable[ playerid ] = id;
					p_RouletteMarkerColumn{ playerid } = 0;

					new Float: offsetX = g_rouletteOffsets[ 0 ] [ E_OFFSET ] * floatcos( Angle + g_rouletteOffsets[ 0 ] [ E_ANGLE ], degrees );
					new Float: offsetY = g_rouletteOffsets[ 0 ] [ E_OFFSET ] * floatsin( Angle + g_rouletteOffsets[ 0 ] [ E_ANGLE ], degrees );
					DestroyDynamicObject( p_RouletteMarker[ playerid ] );
					p_RouletteMarker[ playerid ] = CreateDynamicObject( 2992, X + offsetX, Y + offsetY, Z - 0.17, 0.00000, 0.00000, 0.0, .worldid = g_rouletteTableData[ id ] [ E_WORLD ], .playerid = playerid, .priority = 9999, .drawdistance = 10.0, .streamdistance = 12.0 );

					// starting bet
					p_rouletteBetValue[ playerid ] = 1000;
					g_rouletteChipColor[ playerid ] = makeColor( RandomEx( 128, 255 ), RandomEx( 128, 255 ), RandomEx( 128, 255 ), 0xFF );
					SendServerMessage( playerid, "Your starting bet is $1,000 for this table. {%06x}This is your chip color.", g_rouletteChipColor[ playerid ] >>> 8 );

					ApplyAnimation( playerid, "DEALER", "DEALER_IDLE", 4.1, 1, 1, 1, 1, 0, 1 );

					szBigString = "~y~~k~~PED_SPRINT~~w~ - Spin Wheel~n~~y~~k~~PED_FIREWEAPON~/~k~~PED_LOCK_TARGET~~w~ - Place/Remove Bet~n~~y~~k~~PED_JUMPING~/~k~~SNEAK_ABOUT~~w~ - Increase/Decrease Bet~n~~y~~k~~PED_DUCK~~w~ - Cancel Bets~n~~y~~k~~VEHICLE_ENTER_EXIT~~w~ - Exit";
					ShowPlayerHelpDialog( playerid, 0, szBigString );

					// printf("(%s) BEFORE TIMER %d", ReturnPlayerName( playerid ), p_RouletteMarkerTimer[ playerid ] );
					KillTimer( p_RouletteMarkerTimer[ playerid ] );
					p_RouletteMarkerTimer[ playerid ] = SetTimerEx( "OnRouletteMarkerUpdate", 100, true, "d", playerid );
					return 1;
				}
			}
		}
	}
	return 1;
}

hook InitializeTextDraws( )
{
	for ( new handle = 0; handle < MAX_ROULETTE_TABLES; handle ++ )
	{
		g_rouletteNumberBG[ handle ] = TextDrawCreate(285.000000, 23.000000, "ld_roul:roulbla");
		TextDrawBackgroundColor(g_rouletteNumberBG[ handle ], 255);
		TextDrawFont(g_rouletteNumberBG[ handle ], 4);
		TextDrawLetterSize(g_rouletteNumberBG[ handle ], 0.500000, 1.000000);
		TextDrawColor(g_rouletteNumberBG[ handle ], -1);
		TextDrawSetOutline(g_rouletteNumberBG[ handle ], 0);
		TextDrawSetProportional(g_rouletteNumberBG[ handle ], 1);
		TextDrawSetShadow(g_rouletteNumberBG[ handle ], 1);
		TextDrawUseBox(g_rouletteNumberBG[ handle ], 1);
		TextDrawBoxColor(g_rouletteNumberBG[ handle ], 255);
		TextDrawTextSize(g_rouletteNumberBG[ handle ], 60.000000, 60.000000);

		g_rouletteNumberTD[ handle ] = TextDrawCreate(314.000000, 25.000000, "35");
		TextDrawAlignment(g_rouletteNumberTD[ handle ], 2);
		TextDrawBackgroundColor(g_rouletteNumberTD[ handle ], 255);
		TextDrawFont(g_rouletteNumberTD[ handle ], 1);
		TextDrawLetterSize(g_rouletteNumberTD[ handle ], 0.800000, 4.000000);
		TextDrawColor(g_rouletteNumberTD[ handle ], -1);
		TextDrawSetOutline(g_rouletteNumberTD[ handle ], 0);
		TextDrawSetProportional(g_rouletteNumberTD[ handle ], 1);
		TextDrawSetShadow(g_rouletteNumberTD[ handle ], 1);
	}
	return 1;
}

/* ** Functions ** */
stock CreateRouletteTable( Float: X, Float: Y, Float: Z, Float: Angle, world, maxbet = 100000 )
{
	new
		id = Iter_Free(roulettetables);

	if ( id != ITER_NONE )
	{
		g_rouletteTableData[ id ] [ E_X ] = X;
		g_rouletteTableData[ id ] [ E_Y ] = Y;
		g_rouletteTableData[ id ] [ E_Z ] = Z;
		g_rouletteTableData[ id ] [ E_ROTATION ] = Angle;
		g_rouletteTableData[ id ] [ E_WORLD ] = world;
		g_rouletteTableData[ id ] [ E_MAX_BET ] = maxbet;

		g_rouletteTableData[ id ] [ E_SPINNING_TIMER ] = -1;

		g_rouletteTableData[ id ] [ E_OBJECT ] = CreateDynamicObject( 1978, X, Y, Z, 0.00000, 0.00000, Angle, .worldid = world, .priority = 9999 );

		X += 1.365 * floatcos( Angle + 98.0, degrees );
		Y += 1.365 * floatsin( Angle + 98.0, degrees );

		CreateDynamic3DTextLabel( sprintf( "Press ENTER To Play Roulette\n"COL_WHITE"%s Maximum", ConvertPrice( maxbet ) ), COLOR_GREY, X, Y, Z + 0.02, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .worldid = world, .testlos = 0 );

		new Float: a_x = g_rouletteTableData[ id ] [ E_X ] + 1.4 * floatcos( Angle + 29.0, degrees );
		new Float: a_y = g_rouletteTableData[ id ] [ E_Y ] + 1.4 * floatsin( Angle + 29.0, degrees );

 		g_rouletteTableData[ id ] [ E_ACTOR ] = CreateDynamicActor( randarg( 11, 172, 171 ), a_x, a_y, Z, Angle + 90.0 );
		SetDynamicActorInvulnerable( g_rouletteTableData[ id ] [ E_ACTOR ], true );
		SetDynamicActorVirtualWorld( g_rouletteTableData[ id ] [ E_ACTOR ], world );

		g_rouletteTableData[ id ] [ E_SPINNER_OBJECT ] = CreateDynamicObject( 1979, X, Y, Z - 0.02, 0.00000, 0.00000, 0.0, .worldid = world, .priority = 9999 );
		Iter_Add( roulettetables, id );
	}
    else
    {
        static overflow;
        printf("[ROULETTE ERROR] Reached limit of %d roulette tables, increase to %d to fix.", MAX_ROULETTE_TABLES, MAX_ROULETTE_TABLES + ( ++ overflow ) );
    }
	return 1;
}

stock GenerateRandomRouletteNumber( rouletteid ) {

	new
		iRandom = MRandom( 37 );

	if ( iRandom == 0 )
		TextDrawSetString( g_rouletteNumberBG[ rouletteid ], "ld_roul:roulgre" );

	else if ( ! IsRedRouletteNumber( iRandom ) )
		TextDrawSetString( g_rouletteNumberBG[ rouletteid ], "ld_roul:roulbla" );

	else
		TextDrawSetString( g_rouletteNumberBG[ rouletteid ], "ld_roul:roulred" );

	TextDrawSetString( g_rouletteNumberTD[ rouletteid ], sprintf( "%d", iRandom ) );
	return iRandom;
}

public OnSpinRouletteTable( rouletteid, elapsed, steps )
{
	new
		Float: fElapsed = float( ( elapsed += 25 ) ),
		Float: rotation = -0.0001 * ( fElapsed * fElapsed ) + 0.8162 * fElapsed
	;

	// update it every 50 ms
	if ( elapsed % 50 == 0 && elapsed != 4000 )
		GenerateRandomRouletteNumber( rouletteid );

	SetDynamicObjectRot( g_rouletteTableData[ rouletteid ] [ E_SPINNER_OBJECT ], 0.0, 0.0, rotation );

	if ( elapsed >= 3250 )
		g_rouletteTableData[ rouletteid ] [ E_NO_MORE_BETS ] = true;

	if ( elapsed >= 4000 )
	{
		new
			iWinning = GenerateRandomRouletteNumber( rouletteid );

		// play noise
		foreach (new i : Player) if ( p_RouletteTable[ i ] == rouletteid ) {
			PlayerPlaySound( i, randarg( 33401, 33402, 33403 ), 0.0, 0.0, 0.0 );
		}

		// Kill the timer just incase
		KillTimer( g_rouletteTableData[ rouletteid ] [ E_SPINNING_TIMER ] );
		g_rouletteTableData[ rouletteid ] [ E_SPINNING_TIMER ] = -1;
	 	g_rouletteTableData[ rouletteid ] [ E_NO_MORE_BETS ] = false;

		// Call a win
		CallLocalFunction( "OnRouletteWheelStop", "dd", rouletteid, iWinning );
		return 1;
	}

	return ( g_rouletteTableData[ rouletteid ] [ E_SPINNING_TIMER ] = SetTimerEx( "OnSpinRouletteTable", 25, false, "ddd", rouletteid, elapsed, steps ) );
}

stock GetPlayerTotalRouletteBet( playerid ) {
	new
		bet = 0;

	for ( new chipid = 0; chipid < sizeof( g_rouletteChipValue[ ] ); chipid ++ ) if ( g_rouletteChipValue[ playerid ] [ chipid ] >= 100 ) {
		bet += g_rouletteChipValue[ playerid ] [ chipid ];
	}
	return bet;
}

public OnRouletteWheelStop( rouletteid, winner )
{
	new
		globalWaged = 0, globalWon = 0;

	// printf ( "OnRouletteWheelStop( %d, %d )", rouletteid, winner );
	foreach(new playerid : Player) if ( p_RouletteTable[ playerid ] == rouletteid && p_rouletteBetLocked{ playerid } )
	{
		new
			waged = 0, won = 0;

		for( new chipid = 0; chipid < sizeof( g_rouletteOffsets ); chipid ++ ) if ( g_rouletteChipValue[ playerid ] [ chipid ] > 0 )
		{
			// store chip value here
			new
				beforeWin = won,
				winValue = g_rouletteChipValue[ playerid ] [ chipid ];

			// increment the amount waged
			waged += g_rouletteChipValue[ playerid ] [ chipid ];

			// calculate wins
			switch ( g_rouletteOffsets[ chipid ] [ E_VALUE ] )
			{
				// 1st 3to1
				case 3211: {
					if ( winner == 1 || winner == 4 || winner == 7 || winner == 10 || winner == 13 || winner == 16 || winner == 19 || winner == 22 || winner == 25 || winner == 28 || winner == 31 || winner == 34 )
						won += winValue * 3;
				}

				// 2nd 3to1
				case 3212: {
					if ( winner == 2 || winner == 5 || winner == 8 || winner == 11 || winner == 14 || winner == 17 || winner == 20 || winner == 23 || winner == 26 || winner == 29 || winner == 32 || winner == 35 )
						won += winValue * 3;
				}

				// 2nd 3to1
				case 3213: {
					if ( winner == 3 || winner == 6 || winner == 9 || winner == 12 || winner == 15 || winner == 18 || winner == 21 || winner == 24 || winner == 27 || winner == 30 || winner == 33 || winner == 36 )
						won += winValue * 3;
				}

				// 1st 18
				case 118: {
					if ( 1 <= winner <= 18 )
						won += winValue * 2;
				}

				// even
				case 222: {
					if ( winner % 2 == 0 )
						won += winValue * 2;
				}

				// 1st to 12
				case 112: {
					if ( 1 <= winner <= 12 )
						won += winValue * 3;
				}

				// black
				case 44: {
					if ( ! IsRedRouletteNumber( winner ) && winner != 0 )
						won += winValue * 2;
				}

				// red
				case 88: {
					if ( IsRedRouletteNumber( winner ) )
						won += winValue * 2;
				}

				// 2nd 12
				case 212: {
					if ( 13 <= winner <= 24 )
						won += winValue * 3;
				}

				// odd
				case 333: {
					if ( winner % 2 == 1 && winner != 0 )
						won += winValue * 2;
				}

				// 19-36
				case 1936: {
					if ( 19 <= winner <= 36 )
						won += winValue * 2;
				}

				// 3rd 12
				case 312: {
					if ( 25 <= winner <= 36 )
						won += winValue * 3;
				}

				// check if its a single
				default:
				{
					if ( winner == g_rouletteOffsets[ chipid ] [ E_VALUE ] )
						won += winValue * 36;
				}
			}

			if ( beforeWin >= won ) {
				g_rouletteChipValue[ playerid ] [ chipid ] = 0;
				DestroyDynamicObject( g_rouletteChip[ playerid ] [ 0 ] [ chipid ] ), g_rouletteChip[ playerid ] [ 0 ] [ chipid ] = -1;
				DestroyDynamicObject( g_rouletteChip[ playerid ] [ 1 ] [ chipid ] ), g_rouletteChip[ playerid ] [ 1 ] [ chipid ] = -1;
				DestroyDynamic3DTextLabel( g_rouletteChipLabel[ playerid ] [ chipid ] ), g_rouletteChipLabel[ playerid ] [ chipid ] = Text3D: -1;
			}

			// track
			globalWaged += waged;
			globalWon += won;
		}

		// bet unlocked and paid
		GivePlayerCash( playerid, won );
		p_rouletteBetLocked{ playerid } = false;

		new
			profit = won - waged;

		// inform users
		if ( profit >= 10000 ) {
			SendGlobalMessage( -1, ""COL_GREY"[CASINO]{FFFFFF} %s(%d) has won "COL_GOLD"%s"COL_WHITE" from roulette!", ReturnPlayerName( playerid ), playerid, ConvertPrice( profit ) );
		}

		// give user points
   		GivePlayerCasinoRewardsPoints( playerid, waged, .house_edge = 2.7 );

		// gametext
		if ( profit > 0 )  {
		 	GameTextForPlayer( playerid, sprintf( "~n~~n~~g~%s won!", ConvertPrice( profit ) ), 4000, 3 );
			SendClientMessageFormatted( playerid, -1, ""COL_GREY"[ROULETTE]"COL_WHITE" You have bet a total of %s and profited %s! (winning no %d)", ConvertPrice( waged ), ConvertPrice( profit ), winner );
		} else {
			profit *= -1; // to improve the client message
		 	GameTextForPlayer( playerid, "~n~~n~~r~No win!", 4000, 3 );
			SendClientMessageFormatted( playerid, -1, ""COL_GREY"[ROULETTE]"COL_WHITE" You have bet a total of %s and lost %s! (winning no %d)", ConvertPrice( waged ), ConvertPrice( profit ), winner );
		}
	}

	// log wins/losses
	UpdateServerVariable( "roulette_bets", 0, GetGVarFloat( "roulette_bets" ) + ( float( globalWaged ) / 1000000.0 ), "", GLOBAL_VARTYPE_FLOAT );
	UpdateServerVariable( "roulette_wins", 0, GetGVarFloat( "roulette_wins" ) + ( float( globalWon ) / 1000000.0 ), "", GLOBAL_VARTYPE_FLOAT );
	return 1;
}

public OnRouletteMarkerUpdate( playerid )
{
	new
		rouletteid = p_RouletteTable[ playerid ], column = p_RouletteMarkerColumn{ playerid };

	if ( rouletteid == -1 || ! Iter_Contains( roulettetables, rouletteid ) )
		return RemovePlayerFromRoulette( playerid );

	if ( IsValidDynamicObject( p_RouletteMarker[ playerid ] ) )
	{
	    new ud, lr;
	    GetPlayerKeys( playerid, ud, ud, lr );

	    if ( ud == KEY_UP )
	    {
	    	// up on 0
	    	if ( column == 0 )
	    		column = 38;

	    	// up on 1,2,3
	    	else if ( 1 <= column <= 3 )
	    		column = 0;

	    	// up 1st 12
	    	else if ( column == 42 )
	    		column = 48;

	    	// up 3rd 12
	    	else if ( column == 48 )
	    		column = 45;

	    	// up 2nd 12
	    	else if ( column == 45 )
	    		column = 42;

	    	// up 1-to-18
	    	else if ( column == 40 )
	    		column = 47;

	    	else if ( column == 41 || column == 44 || column == 47 )
	    		column --;

	    	else if ( column == 43 || column == 46 )
	    		column -= 2;

	    	else
	    		column -= 3;
	    }
	    else if ( ud == KEY_DOWN )
	    {
	    	// pressed down on 3to1s
	    	if ( 36 < column < 40 )
	    		column = 0;

	    	// down on 1st 12
	    	else if ( column == 42 )
	    		column = 45;

	    	// down on 2nd 12
	    	else if ( column == 45 )
	    		column = 48;

	    	// down 19-to-36
	    	else if ( column == 47 )
	    		column = 40;

	    	// down on 3rd 12
	    	else if ( column == 48 )
	    		column = 42;

	    	// if pressed down on zero, go to previous
	    	else if ( column == 0 )
	    		column = 2;

	    	else if ( column == 40 || column == 43 || column == 46 )
	    		column ++;

	    	else if ( column == 41 || column == 44 )
	    		column += 2;

	    	else
	    		column += 3;
	    }
	    else if ( lr == KEY_LEFT )
	    {
	    	// right on 0
	    	if ( column == 0 )
	    		column = 0;

	    	else if ( column == 1 || column == 4 || column == 7 || column == 10 )
	    		column = 42;

	    	else if ( column == 13 || column == 16 || column == 19 || column == 22 )
	    		column = 45;

	    	else if ( column == 25 || column == 28 || column == 31 || column == 34 )
	    		column = 48;

	    	// left 1 to 18
	    	else if ( column == 40 )
	    		column = 0;

	    	else
	    		column --;

	    }
	    else if ( lr == KEY_RIGHT )
	    {
	    	// left on 0
	    	if ( column == 0 )
	    		column = 0;

	    	// right 39
	    	if ( column == 39 )
	    		column = 0;

	    	// right red black
	    	else if ( 43 <= column <= 44 )
	    		column = 45;

	    	// right 1-18,even
	    	else if ( 40 <= column <= 41 )
	    		column = 42;

	    	// right odd,19-36
	    	else if ( 46 <= column <= 47 )
	    		column = 48;

	    	// right on 3rd 12
	    	else if ( column == 48 )
	    		column = 25;

	   		// right on 2nd 12
	    	else if ( column == 45 )
	    		column = 13;

	    	// right on 1st 12
	    	else if ( column == 42 )
	    		column = 1;

	    	else
	    		column ++;
	    }

	    // update object pos
		new Float: offsetX = g_rouletteTableData[ rouletteid ] [ E_X ] + g_rouletteOffsets[ column ] [ E_OFFSET ] * floatcos( g_rouletteTableData[ rouletteid ] [ E_ROTATION ] + g_rouletteOffsets[ column ] [ E_ANGLE ], degrees );
		new Float: offsetY = g_rouletteTableData[ rouletteid ] [ E_Y ] + g_rouletteOffsets[ column ] [ E_OFFSET ] * floatsin( g_rouletteTableData[ rouletteid ] [ E_ROTATION ] + g_rouletteOffsets[ column ] [ E_ANGLE ], degrees );
		SetDynamicObjectPos( p_RouletteMarker[ playerid ], offsetX, offsetY, g_rouletteTableData[ rouletteid ] [ E_Z ] - 0.17 );

		// update player column
	    p_RouletteMarkerColumn{ playerid } = column;
	}
	return 1;
}

stock RemovePlayerFromRoulette( playerid )
{
	if ( ! ( 0 <= playerid < MAX_PLAYERS ) )
		return 0;

	// remove chips
	for ( new i = 0; i < sizeof( g_rouletteOffsets ); i ++ ) {
		DestroyDynamicObject( g_rouletteChip[ playerid ] [ 0 ] [ i ] ), g_rouletteChip[ playerid ] [ 0 ] [ i ] = -1;
		DestroyDynamicObject( g_rouletteChip[ playerid ] [ 1 ] [ i ] ), g_rouletteChip[ playerid ] [ 1 ] [ i ] = -1;
		DestroyDynamic3DTextLabel( g_rouletteChipLabel[ playerid ] [ i ] ), g_rouletteChipLabel[ playerid ] [ i ] = Text3D: INVALID_3DTEXT_ID;
		g_rouletteChipValue[ playerid ] [ i ] = 0;
	}

	// hide textdraws
	if ( p_RouletteTable[ playerid ] != -1 ) {
		TextDrawHideForPlayer( playerid, g_rouletteNumberBG[ p_RouletteTable[ playerid ] ] );
		TextDrawHideForPlayer( playerid, g_rouletteNumberTD[ p_RouletteTable[ playerid ] ] );
	}

	// reset sound
	PlayerPlaySound( playerid, 33404, 0.0, 0.0, 0.0 );

	// reset user variables
	HidePlayerHelpDialog( playerid );
	p_RouletteTable[ playerid ] = -1;
	p_RouletteMarkerColumn{ playerid } = 0;
	p_rouletteBetLocked{ playerid } = false;

	// close timers
	KillTimer( p_RouletteMarkerTimer[ playerid ] ), p_RouletteMarkerTimer[ playerid ] = -1;
	DestroyDynamicObject( p_RouletteMarker[ playerid ] ), p_RouletteMarker[ playerid ] = -1;

	// clear animations if spawned
	if ( IsPlayerSpawned( playerid ) ) {
		SetCameraBehindPlayer( playerid );
		ClearAnimations( playerid );
	}
	return 1;
}

stock ConvertRouletteChipValue( value ) {

	new
		Float: float_value = float( value ), string[ 16 ]; // $1000K

	if ( float_value >= 1000000.0 ) {
		float_value /= 1000000.0;
		format( string, sizeof( string ), "$%0.1fM", float_value );
	} else if ( float_value >= 1000.0 ) {
		float_value /= 1000.0;
		format( string, sizeof( string ), "$%0.0fK", float_value );
	} else {
		format( string, sizeof( string ), "$%0.0f", float_value );
	}
	return string;
}
