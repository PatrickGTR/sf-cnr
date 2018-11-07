/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: blackjack.inc
 * Purpose: a sa-mp blackjack minigame implementation
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
#define MAX_BLACKJACK_TABLES 		( 33 )
#define MAX_BLACKJACK_CARDS 		( 5 )
#define MAX_BLACKJACK_PLAYERS 		( 3 )
#define BLACKJACK_DEALER_WAIT 		( 500 )
#define BLACKJACK_PLAYER_WAIT 		( 10 )

#define BLACKJACK_STATE_NONE 		( 0 )
#define BLACKJACK_STATE_TURN 		( 1 )
#define BLACKJACK_STATE_BUST 		( 2 )
#define BLACKJACK_STATE_STAND 		( 3 )
#define BLACKJACK_STATE_WIN 		( 4 )

/* ** Constants ** */
stock const g_cardTextdrawData[ 52 ] [ ] = {
    "LD_CARD:cd1c", // A Clubs - 0
    "LD_CARD:cd2c", // 2 Clubs - 1
    "LD_CARD:cd3c", // 3 Clubs - 2
    "LD_CARD:cd4c", // 4 Clubs - 3
    "LD_CARD:cd5c", // 5 Clubs - 4
    "LD_CARD:cd6c", // 6 Clubs - 5
    "LD_CARD:cd7c", // 7 Clubs - 6
    "LD_CARD:cd8c", // 8 Clubs - 7
    "LD_CARD:cd9c", // 9 Clubs - 8
    "LD_CARD:cd10c", // 10 Clubs - 9
    "LD_CARD:cd11c", // J Clubs - 10
    "LD_CARD:cd12c", // Q Clubs - 11
    "LD_CARD:cd13c", // K Clubs - 12
    "LD_CARD:cd1d", // A Diamonds - 13
    "LD_CARD:cd2d", // 2 Diamonds - 14
    "LD_CARD:cd3d", // 3 Diamonds - 15
    "LD_CARD:cd4d", // 4 Diamonds - 16
    "LD_CARD:cd5d", // 5 Diamonds - 17
    "LD_CARD:cd6d", // 6 Diamonds - 18
    "LD_CARD:cd7d", // 7 Diamonds - 19
    "LD_CARD:cd8d", // 8 Diamonds - 20
    "LD_CARD:cd9d", // 9 Diamonds - 21
    "LD_CARD:cd10d", // 10 Diamonds - 22
    "LD_CARD:cd11d", // J Diamonds - 23
    "LD_CARD:cd12d", // Q Diamonds - 24
    "LD_CARD:cd13d", // K Diamonds - 25
    "LD_CARD:cd1h", // A Heats - 26
    "LD_CARD:cd2h", // 2 Heats - 27
    "LD_CARD:cd3h", // 3 Heats - 28
    "LD_CARD:cd4h", // 4 Heats - 29
    "LD_CARD:cd5h", // 5 Heats - 30
    "LD_CARD:cd6h", // 6 Heats - 31
    "LD_CARD:cd7h", // 7 Heats - 32
    "LD_CARD:cd8h", // 8 Heats - 33
    "LD_CARD:cd9h", // 9 Heats - 34
    "LD_CARD:cd10h", // 10 Heats - 35
    "LD_CARD:cd11h", // J Heats - 36
    "LD_CARD:cd12h", // Q Heats - 37
    "LD_CARD:cd13h", // K Heats - 38
    "LD_CARD:cd1s", // A Spades - 39
    "LD_CARD:cd2s", // 2 Spades - 40
    "LD_CARD:cd3s", // 3 Spades - 41
    "LD_CARD:cd4s", // 4 Spades - 42
    "LD_CARD:cd5s", // 5 Spades - 43
    "LD_CARD:cd6s", // 6 Spades - 44
    "LD_CARD:cd7s", // 7 Spades - 45
    "LD_CARD:cd8s", // 8 Spades - 46
    "LD_CARD:cd9s", // 9 Spades - 47
    "LD_CARD:cd10s", // 10 Spades - 48
    "LD_CARD:cd11s", // J Spades - 49
    "LD_CARD:cd12s", // Q Spades - 50
    "LD_CARD:cd13s" // K Spades - 51
};

/* ** Variables ** */
enum E_BLACKJACK_DATA
{
    bool: E_GAME_STARTED,   E_CARDS_DRAWN,          E_GAME_TIMER,
    E_PAYOUT,               E_WORLD,                E_RESET_TIMER,
    E_DRAW_CARD_TIMER,

    E_OBJECT,               E_ACTOR,

    Float: E_X,             Float: E_Y,             Float: E_Z,
    Float: E_ROTATION,

    Text3D: E_DEALER_LABEL, Text3D: E_PLAYER_LABEL[ MAX_BLACKJACK_PLAYERS ]
};

new
    g_blackjackData 				[ MAX_BLACKJACK_TABLES ] [ E_BLACKJACK_DATA ],
    Text: g_blackjackTurnTD			[ MAX_BLACKJACK_TABLES ] = { Text: INVALID_TEXT_DRAW, ... },
    Text: g_blackjackPlayerCards	[ MAX_BLACKJACK_TABLES ] [ MAX_BLACKJACK_CARDS ] [ MAX_BLACKJACK_PLAYERS ],
    Text: g_blackjackDealerCards	[ MAX_BLACKJACK_TABLES ] [ MAX_BLACKJACK_CARDS ],
    g_blackjackDealerCardIndex		[ MAX_BLACKJACK_TABLES ] [ MAX_BLACKJACK_CARDS ],
    g_blackjackPlayerCardIndex		[ MAX_BLACKJACK_TABLES ] [ MAX_BLACKJACK_CARDS ] [ MAX_BLACKJACK_PLAYERS ],
    g_blackjackPlayerState			[ MAX_BLACKJACK_TABLES ] [ MAX_BLACKJACK_PLAYERS ],
    g_blackjackSlotData				[ MAX_BLACKJACK_TABLES ] [ MAX_BLACKJACK_PLAYERS ],
    p_blackjackTable				[ MAX_PLAYERS ] = { -1, ... },
    Iterator: blackjacktables 		< MAX_BLACKJACK_TABLES >
;

/* ** Hooks ** */
hook OnScriptInit( )
{
    // for tracking bets
    AddServerVariable( "blackjack_bets", "0.0", GLOBAL_VARTYPE_FLOAT );
    AddServerVariable( "blackjack_wins", "0.0", GLOBAL_VARTYPE_FLOAT );

	// Create blackjack tables
	CreateBlackjackTable( 2500, 2230.37500, 1602.75000, 1006.15631, 0.00000, 82 );
	CreateBlackjackTable( 5000, 2232.18750, 1604.43750, 1006.15631, 90.0000, 82 );
	CreateBlackjackTable( 10000, 2228.49219, 1604.45313, 1006.15631, -90.000, 82 );
	CreateBlackjackTable( 25000, 2230.37500, 1606.27344, 1006.15631, 180.000, 82 );
	CreateBlackjackTable( 50000, 2241.31250, 1602.75000, 1006.15631, 0.00000, 82 );
	CreateBlackjackTable( 75000, 2243.12500, 1604.43750, 1006.15631, 90.0000, 82 );
	CreateBlackjackTable( 100000, 2239.42969, 1604.45313, 1006.15631, -90.000, 82 );
	CreateBlackjackTable( 125000, 2241.31250, 1606.27344, 1006.15631, 180.000, 82 );

    // 4 dragons
    CreateBlackjackTable( 25000, 1960.36719, 1015.66412, 992.46881, -90.0000, 23 );
    CreateBlackjackTable( 50000, 1962.34375, 1015.66412, 992.46881, 90.00000, 23 );
    CreateBlackjackTable( 100000, 1962.34375, 1020.17969, 992.46881, 90.00000, 23 );
    CreateBlackjackTable( 250000, 1960.36719, 1020.17188, 992.46881, -90.00000, 23 );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	RemovePlayerFromBlackjack( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	RemovePlayerFromBlackjack( playerid );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( IsPlayerInCasino( playerid ) )
	{
        new
            blackjack_table = p_blackjackTable[ playerid ];

       	// Blackjack
        if ( blackjack_table != -1 )
        {
            new
                player_index = GetBlackjackPlayerIndex( blackjack_table, playerid );

            if ( player_index == -1 )
                return SendError( playerid, "You don't seem to be playing any blackjack table." );

		    if ( PRESSED( KEY_SPRINT ) ) {

	            if ( ! g_blackjackData[ blackjack_table ] [ E_CARDS_DRAWN ] && g_blackjackData[ blackjack_table ] [ E_GAME_TIMER ] == -1 )
	                return ( g_blackjackData[ blackjack_table ] [ E_GAME_TIMER ] = SetTimerEx( "BeginBlackJackTurn", BLACKJACK_DEALER_WAIT, false, "d", blackjack_table ) ), 1;

	            if ( g_blackjackPlayerState[ blackjack_table ] [ player_index ] == BLACKJACK_STATE_TURN ) {
	                g_blackjackPlayerState[ blackjack_table ] [ player_index ] = BLACKJACK_STATE_STAND;
	                SendClientMessageToBlackjack( blackjack_table, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has decided to stand.", ReturnPlayerName( playerid ), playerid );
	                return 1;
	            }
		        return 1;
		    }

		    if ( PRESSED( KEY_CTRL_BACK ) )
		    {
	            if ( g_blackjackPlayerState[ blackjack_table ] [ player_index ] != BLACKJACK_STATE_TURN )
	                return SendError( playerid, "It's not your turn to hit. Please wait!" );

	            DrawPlayerBlackjackCard( blackjack_table, player_index );
	            CheckForBlackjack( blackjack_table );
	            return 1;
		    }
        }

		if ( PRESSED( KEY_SECONDARY_ATTACK ) )
		{
			if ( p_blackjackTable[ playerid ] != -1 ) {
                if ( g_blackjackData[ blackjack_table ] [ E_CARDS_DRAWN ] ) return SendError( playerid, "You cannot exit while you are playing your blackjack hand." );
				return RemovePlayerFromBlackjack( playerid, .reset_cam = 1 );
            }

			foreach(new id : blackjacktables) if ( GetPlayerVirtualWorld( playerid ) == g_blackjackData[ id ] [ E_WORLD ] )
	        {
	            if ( IsPlayerInRangeOfPoint( playerid, 3.0, g_blackjackData[ id ] [ E_X ], g_blackjackData[ id ] [ E_Y ], g_blackjackData[ id ] [ E_Z ] ) ) {

	                new
	                    player_index;

	                for ( ; player_index < MAX_BLACKJACK_PLAYERS; player_index ++ )
	                    if ( g_blackjackSlotData[ id ] [ player_index ] == -1 )
	                        break;

	                if ( player_index >= MAX_BLACKJACK_PLAYERS || g_blackjackSlotData[ id ] [ player_index ] != -1 )
	                    return SendError( playerid, "There are no more vacant slots for this table." );

	                if ( GetPlayerCash( playerid ) < g_blackjackData[ id ] [ E_PAYOUT ] )
	                    return SendError( playerid, "You don't have any money to wager." );

	                new
	                    Float: lookatX, Float: lookatY, Float: lookatZ,
	                    Float: tmpX, Float: tmpY, Float: tmpZ
	                ;

	                GetPlayerCameraPos( playerid, X, Y, Z );
	                GetPlayerCameraFrontVector( playerid, lookatX, lookatY, lookatZ );

	                tmpX = g_blackjackData[ id ] [ E_X ] - 1.3 * floatcos( g_blackjackData[ id ] [ E_ROTATION ] + 90.0, degrees );
	                tmpY = g_blackjackData[ id ] [ E_Y ] - 1.3 * floatsin( g_blackjackData[ id ] [ E_ROTATION ] + 90.0, degrees );
	                tmpZ = g_blackjackData[ id ] [ E_Z ] + 1.7;

	                InterpolateCameraPos( playerid, X, Y, Z, tmpX, tmpY, tmpZ, 1000, CAMERA_MOVE );

	                X += floatmul( lookatX, 20.0 );
	                Y += floatmul( lookatY, 20.0 );
	                Z += floatmul( lookatZ, 20.0 );

	                InterpolateCameraLookAt( playerid, X, Y, Z, g_blackjackData[ id ] [ E_X ], g_blackjackData[ id ] [ E_Y ], g_blackjackData[ id ] [ E_Z ] - 1.0, 1000, CAMERA_MOVE );

	                p_blackjackTable[ playerid ] = id;
	                g_blackjackSlotData[ id ] [ player_index ] = playerid;

	                // reset player cards
	                for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ )
	                    g_blackjackPlayerCardIndex[ id ] [ c ] [ player_index ] = -1;

                    // set player card values
                    SetBlackjackPlayerLabelValue( id, player_index, 0 );

	                // show cards to players
	                for ( new player = 0; player < MAX_BLACKJACK_PLAYERS; player ++ )
	                {
	                    new
	                        gamerid = g_blackjackSlotData[ id ] [ player ];

	                    // deal only first two cards
	                    for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ )
	                    {
	                        TextDrawShowForPlayer( gamerid, g_blackjackDealerCards[ id ] [ c ] );

	                        // show two player cards only
	                        if ( c >= 2 )
	                            continue;

	                        for ( new p = 0; p < GetBlackjackPlayers( id ); p ++ ) {
	                            TextDrawShowForPlayer( gamerid, g_blackjackPlayerCards[ id ] [ c ] [ p ] );
	                        }
	                    }
	                }

					szBigString = "~y~~k~~PED_SPRINT~~w~ - Begin game/Stand~n~~y~~k~~GROUP_CONTROL_BWD~~w~ - Hit~n~~y~~k~~VEHICLE_ENTER_EXIT~~w~ - Exit";
					ShowPlayerHelpDialog( playerid, 0, szBigString );

	                SendServerMessage( playerid, "You have entered the %s hand blackjack table.", cash_format( g_blackjackData[ id ] [ E_PAYOUT ] ) );
	                ApplyAnimation( playerid, "DEALER", "DEALER_IDLE", 4.1, 1, 1, 1, 1, 0, 1 );
	                return 1;
	            }
	        }
		}
	}
	return 1;
}

/* ** Functions ** */
stock CreateBlackjackTable( payout, Float: X, Float: Y, Float: Z, Float: Angle, world )
{
    new
        id = Iter_Free(blackjacktables);

    if ( id != ITER_NONE )
    {
        g_blackjackData[ id ] [ E_X ] = X;
        g_blackjackData[ id ] [ E_Y ] = Y;
        g_blackjackData[ id ] [ E_Z ] = Z;
        g_blackjackData[ id ] [ E_ROTATION ] = Angle;
        g_blackjackData[ id ] [ E_WORLD ] = world;

        g_blackjackData[ id ] [ E_DRAW_CARD_TIMER ] = -1;
        g_blackjackData[ id ] [ E_RESET_TIMER ] = -1;
        g_blackjackData[ id ] [ E_GAME_TIMER ] = -1;
        g_blackjackData[ id ] [ E_PAYOUT ] = payout;
        g_blackjackData[ id ] [ E_OBJECT ] = CreateDynamicObject( 2188, X, Y, Z, 0.00000, 0.00000, Angle, .worldid = world, .priority = 9999 );
        g_blackjackData[ id ] [ E_ACTOR ] = CreateDynamicActor( 171, X - 0.4 * floatcos( Angle - 90.0, degrees ), Y - 0.4 * floatsin( Angle - 90.0, degrees ), Z, Angle + 180.0, .worldid = world );
        g_blackjackData[ id ] [ E_DEALER_LABEL ] = CreateDynamic3DTextLabel( sprintf( "Press ENTER To Play Blackjack\n"COL_WHITE"%s Minimum", cash_format( payout ) ), COLOR_GREY, X, Y, Z + 0.25, 15.0, .testlos = 0, .worldid = world );

        g_blackjackData[ id ] [ E_PLAYER_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( "Player 0", 0, X + 0.7 * floatcos( Angle - 90.0, degrees ), Y + 0.7 * floatsin( Angle - 90.0, degrees ), Z + 0.05, 15.0, .testlos = 0, .worldid = world );
        g_blackjackData[ id ] [ E_PLAYER_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "Player 1", 0, X + 0.7 * floatcos( Angle - 90.0 - 22.5, degrees ), Y + 0.7 * floatsin( Angle - 90.0 - 22.5, degrees ), Z + 0.05, 15.0, .testlos = 0, .worldid = world );
        g_blackjackData[ id ] [ E_PLAYER_LABEL ] [ 2 ] = CreateDynamic3DTextLabel( "Player 2", 0, X + 0.7 * floatcos( Angle - 90.0 + 22.5, degrees ), Y + 0.7 * floatsin( Angle - 90.0 + 22.5, degrees ), Z + 0.05, 15.0, .testlos = 0, .worldid = world );

		SetDynamicActorInvulnerable( g_blackjackData[ id ] [ E_ACTOR ], true );
		SetDynamicActorVirtualWorld( g_blackjackData[ id ] [ E_ACTOR ], world );

        // reset textdraw values
        for ( new x = 0; x < MAX_BLACKJACK_CARDS; x ++ ) {
            g_blackjackDealerCards[ id ] [ x ] = Text: INVALID_TEXT_DRAW;

            for ( new p = 0; p < MAX_BLACKJACK_PLAYERS; p ++ ) {
                g_blackjackPlayerCards[ id ] [ x ] [ p ] = Text: INVALID_TEXT_DRAW;
                g_blackjackSlotData[ id ] [ p ] = -1;
            }
        }

        // create the blackjack textdraws
        InitializeBlackjackTextdraws( id );

        // reset and add to iterator
        ResetBlackjackTable( id );
        Iter_Add( blackjacktables, id );
    }
    else
    {
        static overflow;
        printf("[BLACKJACK ERROR] Reached limit of %d blackjack tables, increase to %d to fix.", MAX_BLACKJACK_TABLES, MAX_BLACKJACK_TABLES + ( ++ overflow ) );
    }
    return 1;
}

function DrawPlayerBlackjackCard( tableid, player_index )
{
    new
        randomCard = MRandom( sizeof( g_blackjackDealerCards ) );

    for ( new cardid = 0; cardid < MAX_BLACKJACK_CARDS; cardid ++ ) if ( g_blackjackPlayerCardIndex[ tableid ] [ cardid ] [ player_index ] == -1 ) {
        TextDrawSetString( g_blackjackPlayerCards[ tableid ] [ cardid ] [ player_index ], g_cardTextdrawData[ randomCard ] );
        foreach (new gamerid : Player) if ( p_blackjackTable[ gamerid ] == tableid ) {
        	TextDrawShowForPlayer( gamerid, g_blackjackPlayerCards[ tableid ] [ cardid ] [ player_index ] );
    		PlayerPlaySound( gamerid, 1145, 0.0, 0.0, 0.0 );
        }
        g_blackjackPlayerCardIndex[ tableid ] [ cardid ] [ player_index ] = randomCard;
        SetBlackjackPlayerLabelValue( tableid, player_index, CalculatePlayerHand( tableid, player_index ) );
        break;
    }
    return randomCard;
}

function BeginBlackJackTurn( tableid )
{
    new
        cardid = g_blackjackData[ tableid ] [ E_CARDS_DRAWN ] ++;

    if ( cardid >= MAX_BLACKJACK_CARDS ) {
        ResetBlackjackTable( tableid );
        return;
    }

    new
        randomCard = MRandom( sizeof( g_blackjackDealerCards ) );

    // dealer cards
    ApplyDynamicActorAnimation( g_blackjackData[ tableid ] [ E_ACTOR ], "CASINO", "dealone", 4.1, 0, 0, 0, 0, 0 );
    ApplyDynamicActorAnimation( g_blackjackData[ tableid ] [ E_ACTOR ], "CASINO", "dealone", 4.1, 0, 0, 0, 0, 0 );
    TextDrawSetString( g_blackjackDealerCards[ tableid ] [ cardid ], g_cardTextdrawData[ randomCard ] );
    g_blackjackDealerCardIndex[ tableid ] [ cardid ] = randomCard;
    SetBlackjackDealerLabelValue( tableid, CalculateDealerHand( tableid ) );

    // noise
    foreach (new gamerid : Player) if ( p_blackjackTable[ gamerid ] != -1 ) {
    	PlayerPlaySound( gamerid, 1145, 0.0, 0.0, 0.0 );
    }

    // deal player first card
    if ( cardid == 0 )
    {
        new blackjack_players = GetBlackjackPlayers( tableid );
    	new bet_amount = 0;

        for ( new player_index = 0; player_index < MAX_BLACKJACK_PLAYERS; player_index ++ ) if ( g_blackjackSlotData[ tableid ] [ player_index ] != -1 )
        {
            new
                gamerid = g_blackjackSlotData[ tableid ] [ player_index ];

            if ( GetPlayerCash( gamerid ) < g_blackjackData[ tableid ] [ E_PAYOUT ] ) {
                SendError( gamerid, "You don't have any money to wager." );
                RemovePlayerFromBlackjack( gamerid, .reset_cam = 1 );
                if ( blackjack_players - 1 <= 0 ) return; // no point having an empty table
                continue;
            }

            bet_amount += g_blackjackData[ tableid ] [ E_PAYOUT ];
            GivePlayerCash( gamerid, -g_blackjackData[ tableid ] [ E_PAYOUT ] );
            StockMarket_UpdateEarnings( E_STOCK_CASINO, g_blackjackData[ tableid ] [ E_PAYOUT ], 0.05 );
            DrawPlayerBlackjackCard( tableid, player_index );
            if ( cardid < 1 ) { // distribute first two cards to players
                g_blackjackData[ tableid ] [ E_DRAW_CARD_TIMER ] = SetTimerEx( "DrawPlayerBlackjackCard", BLACKJACK_DEALER_WAIT, false, "dd", tableid, player_index );
            }
        }

		UpdateServerVariable( "blackjack_bets", 0, GetGVarFloat( "blackjack_bets" ) + ( float( bet_amount ) / 1000000.0 ), "", GLOBAL_VARTYPE_FLOAT );

        // begin turns
        new
            first_player = GetNextAvailableBlackjackPlayer( tableid ),
            first_player_index = GetBlackjackPlayerIndex( tableid, first_player )
        ;

        if ( first_player_index != -1 )
        	g_blackjackPlayerState[ tableid ] [ first_player_index ] = BLACKJACK_STATE_TURN;

        g_blackjackData[ tableid ] [ E_GAME_TIMER ] = SetTimerEx( "BlackjackPlayerTurn", BLACKJACK_DEALER_WAIT + 500, false, "ddd", tableid, first_player, BLACKJACK_PLAYER_WAIT );
    }

    // check for blackjack on players & bot
    new
        dealer_score = CheckForBlackjack( tableid );

    // pull more cards
    if ( cardid >= 1 && dealer_score < 17 )
        g_blackjackData[ tableid ] [ E_GAME_TIMER ] = SetTimerEx( "BeginBlackJackTurn", BLACKJACK_DEALER_WAIT, false, "d", tableid );

    if ( dealer_score >= 17 ) {
        SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" Table will reset in 5 seconds as all hands have been dealt." );
        g_blackjackData[ tableid ] [ E_RESET_TIMER ] =  SetTimerEx( "ResetBlackjackTable", 5000, false, "d", tableid );
    }
}

stock GetNextAvailableBlackjackPlayer( tableid, exclude = INVALID_PLAYER_ID )
{
    new
        playerid = INVALID_PLAYER_ID;

    for ( new player_index = 0; player_index < MAX_BLACKJACK_PLAYERS; player_index ++ ) if ( g_blackjackSlotData[ tableid ] [ player_index ] != -1 && g_blackjackPlayerState[ tableid ] [ player_index ] == BLACKJACK_STATE_NONE && exclude != g_blackjackSlotData[ tableid ] [ player_index ] && g_blackjackPlayerCardIndex[ tableid ] [ 0 ] [ player_index ] != -1 ) {
        playerid = g_blackjackSlotData[ tableid ] [ player_index ];
        break;
    }
    return playerid;
}

function BlackjackPlayerTurn( tableid, playerid, seconds_left )
{
    new
        player_index = GetBlackjackPlayerIndex( tableid, playerid );

    if ( IsPlayerConnected( playerid ) && player_index != -1 && seconds_left >= 0 && g_blackjackPlayerState[ tableid ] [ player_index ] == BLACKJACK_STATE_TURN )
    {
        foreach (new gamerid : Player) if ( p_blackjackTable[ gamerid ] == tableid ) {
            TextDrawSetString( g_blackjackTurnTD[ tableid ], sprintf( "%s has %d seconds left", ReturnPlayerName( playerid ), seconds_left ) );
            TextDrawShowForPlayer( gamerid, g_blackjackTurnTD[ tableid ] );
        }
        g_blackjackData[ tableid ] [ E_GAME_TIMER ] = SetTimerEx( "BlackjackPlayerTurn", 960, false, "ddd", tableid, playerid, seconds_left - 1 );
    }
    else
    {
        new
            next_player = GetNextAvailableBlackjackPlayer( tableid, playerid );

        if ( next_player == INVALID_PLAYER_ID )
        {
            TextDrawHideForAll( g_blackjackTurnTD[ tableid ] );
            g_blackjackData[ tableid ] [ E_GAME_TIMER ] = SetTimerEx( "BeginBlackJackTurn", BLACKJACK_DEALER_WAIT, false, "d", tableid );
        }
        else
        {
            new
                next_player_index  = GetBlackjackPlayerIndex( tableid, next_player );

           	// otherwise winning hands will get reissued prizes
            if ( player_index != -1 && g_blackjackPlayerState[ tableid ] [ player_index ] != BLACKJACK_STATE_WIN && g_blackjackPlayerState[ tableid ] [ player_index ] != BLACKJACK_STATE_BUST )
            	g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_STAND;

            g_blackjackPlayerState[ tableid ] [ next_player_index ] = BLACKJACK_STATE_TURN;
            g_blackjackData[ tableid ] [ E_GAME_TIMER ] = SetTimerEx( "BlackjackPlayerTurn", 960, false, "ddd", tableid, next_player, BLACKJACK_PLAYER_WAIT );
        }
    }
}

function ResetBlackjackTable( tableid )
{
	if ( tableid == -1 )
		return;

    // variables
    SetBlackjackDealerLabelValue( tableid, -1 );
    KillTimer( g_blackjackData[ tableid ] [ E_RESET_TIMER ] ), g_blackjackData[ tableid ] [ E_RESET_TIMER ] = -1;
    KillTimer( g_blackjackData[ tableid ] [ E_GAME_TIMER ] ), g_blackjackData[ tableid ] [ E_GAME_TIMER ] = -1;
    KillTimer( g_blackjackData[ tableid ] [ E_DRAW_CARD_TIMER ] ), g_blackjackData[ tableid ] [ E_DRAW_CARD_TIMER ] = -1;
    g_blackjackData[ tableid ] [ E_CARDS_DRAWN ] = 0;

    // card data
    for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ ) {
        g_blackjackDealerCardIndex[ tableid ] [ c ] = -1;
        TextDrawSetString( g_blackjackDealerCards[ tableid ] [ c ], "ld_card:cdback" );

        for ( new p = 0; p < MAX_BLACKJACK_PLAYERS; p ++ ) {
            g_blackjackPlayerState[ tableid ] [ p ] = BLACKJACK_STATE_NONE;
            g_blackjackPlayerCardIndex[ tableid ] [ c ] [ p ] = -1;
            TextDrawSetString( g_blackjackPlayerCards[ tableid ] [ c ] [ p ], "ld_card:cdback" );
            if ( c > 1 ) TextDrawHideForAll( g_blackjackPlayerCards[ tableid ] [ c ] [ p ] );
        }
    }

    // reshow textdraws to players
    for ( new player_index = 0; player_index < MAX_BLACKJACK_PLAYERS; player_index ++ )
    {
        if ( g_blackjackSlotData[ tableid ] [ player_index ] != -1 )
        {
            new
                gamerid = g_blackjackSlotData[ tableid ] [ player_index ];

            // reset label
            SetBlackjackPlayerLabelValue( tableid, player_index, 0 );

            // deal only first two cards
            for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ )
            {
                TextDrawShowForPlayer( gamerid, g_blackjackDealerCards[ tableid ] [ c ] );

                // show two player cards only
                if ( c >= 2 )
                    continue;

                for ( new p = 0; p < GetBlackjackPlayers( tableid ); p ++ ) {
                    TextDrawShowForPlayer( gamerid, g_blackjackPlayerCards[ tableid ] [ c ] [ p ] );
                }
            }
        }
        else SetBlackjackPlayerLabelValue( tableid, player_index, -1 );
    }
}

stock CheckForBlackjack( tableid )
{
    new
        dealer_score = CalculateDealerHand( tableid );

    //if ( g_blackjackData[ tableid ] [ E_CARDS_DRAWN ] <= 1 )
    //    return dealer_score;

    //printf("The Dealer score is %d", dealer_score );
    SetBlackjackDealerLabelValue( tableid, dealer_score );

    // calculate player score
    for ( new player_index = 0; player_index < MAX_BLACKJACK_PLAYERS; player_index ++ ) if ( g_blackjackSlotData[ tableid ] [ player_index ] != -1 && g_blackjackPlayerCardIndex[ tableid ] [ 0 ] [ player_index ] != -1 )
    {
        new playerid = g_blackjackSlotData[ tableid ] [ player_index ];
        new player_score = CalculatePlayerHand( tableid, player_index );

        SetBlackjackPlayerLabelValue( tableid, player_index, player_score );

        if ( g_blackjackPlayerState[ tableid ] [ player_index ] != BLACKJACK_STATE_BUST && g_blackjackPlayerState[ tableid ] [ player_index ] != BLACKJACK_STATE_WIN  )
        {
            new
                payout = floatround( float( g_blackjackData[ tableid ] [ E_PAYOUT ] ) * 2.0 );

            // check for win
       		if ( dealer_score == player_score && dealer_score >= 17 ) {
       			payout = g_blackjackData[ tableid ] [ E_PAYOUT ];
                g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_WIN;
                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has been returned %s due to a push.", ReturnPlayerName( playerid ), playerid, cash_format( payout ) );
		 		GameTextForPlayer( playerid, sprintf( "~n~~n~~y~%s returned!", cash_format( payout ) ), 4000, 3 );
                GivePlayerCasinoRewardsPoints( playerid, g_blackjackData[ tableid ] [ E_PAYOUT ], .house_edge = 1.5 );
                GivePlayerCash( playerid, payout );
                StockMarket_UpdateEarnings( E_STOCK_CASINO, -payout, 0.05 );
            }
            else if ( player_score == 21 ) {
                g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_WIN;
                if ( IsPlayerHandBlackjack( tableid, player_index, player_score ) ) {
	                payout = floatround( float( g_blackjackData[ tableid ] [ E_PAYOUT ] ) * 2.5 );
	                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" Blackjack! %s(%d) has won %s!", ReturnPlayerName( playerid ), playerid, cash_format( payout ) );
                } else {
	                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has won %s due to a card count of 21!", ReturnPlayerName( playerid ), playerid, cash_format( payout ) );
                }
		 		GameTextForPlayer( playerid, sprintf( "~n~~n~~g~%s won!", cash_format( payout ) ), 4000, 3 );
                GivePlayerCasinoRewardsPoints( playerid, g_blackjackData[ tableid ] [ E_PAYOUT ], .house_edge = 1.5 );
                GivePlayerCash( playerid, payout );
                StockMarket_UpdateEarnings( E_STOCK_CASINO, -payout, 0.05 );
            }
            else if ( dealer_score == 21 ) {
                GivePlayerCasinoRewardsPoints( playerid, g_blackjackData[ tableid ] [ E_PAYOUT ], .house_edge = 1.5 );
                g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_BUST;
                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has lost %s due to a dealer %s.", ReturnPlayerName( playerid ), playerid, cash_format( g_blackjackData[ tableid ] [ E_PAYOUT ] ), IsDealerHandBlackjack( tableid, dealer_score ) ? ( "blackjack" ) : ( "21" ) );
		 		GameTextForPlayer( playerid, "~n~~n~~r~No win!", 4000, 3 );
            }
            else if ( player_score > 21 ) {
                GivePlayerCasinoRewardsPoints( playerid, g_blackjackData[ tableid ] [ E_PAYOUT ], .house_edge = 1.5 );
                g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_BUST;
                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has lost %s due to a bust.", ReturnPlayerName( playerid ), playerid, cash_format( g_blackjackData[ tableid ] [ E_PAYOUT ] ) );
		 		GameTextForPlayer( playerid, "~n~~n~~r~No win!", 4000, 3 );
            }
            else if ( dealer_score > 21 ) {
                g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_WIN;
                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has won %s due to a dealer bust.", ReturnPlayerName( playerid ), playerid, cash_format( payout ) );
		 		GameTextForPlayer( playerid, sprintf( "~n~~n~~g~%s won!", cash_format( payout ) ), 4000, 3 );
                GivePlayerCasinoRewardsPoints( playerid, g_blackjackData[ tableid ] [ E_PAYOUT ], .house_edge = 1.5 );
                GivePlayerCash( playerid, payout );
                StockMarket_UpdateEarnings( E_STOCK_CASINO, -payout, 0.05 );
            }
            else if ( player_score < dealer_score && dealer_score >= 17 ) {
                GivePlayerCasinoRewardsPoints( playerid, g_blackjackData[ tableid ] [ E_PAYOUT ], .house_edge = 1.5 );
                g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_BUST;
                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has lost %s due to a bust.", ReturnPlayerName( playerid ), playerid, cash_format( g_blackjackData[ tableid ] [ E_PAYOUT ] ) );
		 		GameTextForPlayer( playerid, "~n~~n~~r~No win!", 4000, 3 );
            }
            else if ( player_score > dealer_score && dealer_score >= 17 ) {
                g_blackjackPlayerState[ tableid ] [ player_index ] = BLACKJACK_STATE_WIN;
                SendClientMessageToBlackjack( tableid, COLOR_GREY, "[BLACKJACK]"COL_WHITE" %s(%d) has won %s due to a dealer bust.", ReturnPlayerName( playerid ), playerid, cash_format( g_blackjackData[ tableid ] [ E_PAYOUT ] ) );
		 		GameTextForPlayer( playerid, sprintf( "~n~~n~~g~%s won!", cash_format( payout ) ), 4000, 3 );
                GivePlayerCasinoRewardsPoints( playerid, g_blackjackData[ tableid ] [ E_PAYOUT ], .house_edge = 1.5 );
                GivePlayerCash( playerid, payout );
                StockMarket_UpdateEarnings( E_STOCK_CASINO, -payout, 0.05 );
            }

            // alert world
			if ( g_blackjackPlayerState[ tableid ] [ player_index ] == BLACKJACK_STATE_WIN && payout > g_blackjackData[ tableid ] [ E_PAYOUT ] && payout >= 10000 ) {
				UpdateServerVariable( "blackjack_wins", 0, GetGVarFloat( "blackjack_wins" ) + ( float( payout ) / 1000000.0 ), "", GLOBAL_VARTYPE_FLOAT );
				SendGlobalMessage( -1, ""COL_GREY"[CASINO]{FFFFFF} %s(%d) has won "COL_GOLD"%s"COL_WHITE" from blackjack!", ReturnPlayerName( playerid ), playerid, cash_format( payout ) );
			}
        }
    }
    return dealer_score;
}

stock RemovePlayerFromBlackjack( playerid, reset_cam = 0 )
{
    if ( ! ( 0 <= playerid < MAX_PLAYERS ) )
        return 0;

    new
        blackjack_table = p_blackjackTable[ playerid ];

    if ( blackjack_table == -1 )
        return 0;

    // hide textdraws & reset
    for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ ) {
        TextDrawHideForPlayer( playerid, g_blackjackDealerCards[ blackjack_table ] [ c ] );

        for ( new p = 0; p < MAX_BLACKJACK_PLAYERS; p ++ ) {
            TextDrawHideForPlayer( playerid, g_blackjackPlayerCards[ blackjack_table ] [ c ] [ p ] );
        }
    }
  	TextDrawHideForPlayer( playerid, g_blackjackTurnTD[ blackjack_table ] );

    // check if it is a player
    new
        player_index = GetBlackjackPlayerIndex( blackjack_table, playerid );

    if ( player_index != -1 )
    {
        foreach (new i : Player) if ( p_blackjackTable[ i ] == blackjack_table ) {
            for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ ) {
                g_blackjackPlayerCardIndex[ blackjack_table ] [ c ] [ player_index ] = -1;
                g_blackjackPlayerState[ blackjack_table ] [ player_index ] = BLACKJACK_STATE_NONE;
                TextDrawSetString( g_blackjackPlayerCards[ blackjack_table ] [ c ] [ player_index ], "ld_card:cdback" );
                TextDrawHideForPlayer( i, g_blackjackPlayerCards[ blackjack_table ] [ c ] [ player_index ] );
            }
        }
        g_blackjackSlotData[ blackjack_table ] [ player_index ] = -1;
        SetBlackjackPlayerLabelValue( blackjack_table, player_index, -1 );
    }

    // reset camera?
    if ( reset_cam ) {
        TogglePlayerControllable( playerid, 1 );
        ClearAnimations( playerid );
        SetCameraBehindPlayer( playerid );
        HidePlayerHelpDialog( playerid );
    }

    // reset variables
    p_blackjackTable[ playerid ] = -1;

    // reset table just incase empty
    if ( GetBlackjackPlayers( blackjack_table ) <= 0 )
		ResetBlackjackTable( blackjack_table );

    return 1;
}

stock SendClientMessageToBlackjack( tableid, colour, format[ ], va_args<> )
{
    static
        out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

    for(new i = 0; i < 10; i++) if ( p_blackjackTable[ i ] == tableid ) {
        SendClientMessage( i, colour, out );
    }
    return 1;
}

stock InitializeBlackjackTextdraws( id )
{
    g_blackjackTurnTD[ id ] = TextDrawCreate(330.000000, 204.000000, "Lorenc has 5 seconds");
    TextDrawAlignment(g_blackjackTurnTD[ id ], 2);
    TextDrawBackgroundColor(g_blackjackTurnTD[ id ], 255);
    TextDrawFont(g_blackjackTurnTD[ id ], 1);
    TextDrawLetterSize(g_blackjackTurnTD[ id ], 0.260000, 1.200000);
    TextDrawColor(g_blackjackTurnTD[ id ], 16711935);
    TextDrawSetOutline(g_blackjackTurnTD[ id ], 1);
    TextDrawSetProportional(g_blackjackTurnTD[ id ], 1);

    for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ )
    {
        g_blackjackDealerCards[ id ] [ c ] = TextDrawCreate(243.000000 + 35.0 * float( c ), 138.000000, "ld_card:cdback");
        TextDrawBackgroundColor( g_blackjackDealerCards[ id ] [ c ], 255);
        TextDrawFont( g_blackjackDealerCards[ id ] [ c ], 4);
        TextDrawLetterSize( g_blackjackDealerCards[ id ] [ c ], 0.500000, 1.000000);
        TextDrawUseBox( g_blackjackDealerCards[ id ] [ c ], 1);
        TextDrawBoxColor( g_blackjackDealerCards[ id ] [ c ], 255);
        TextDrawTextSize( g_blackjackDealerCards[ id ] [ c ], 30.000000, 51.000000);
    }

    new
        Float: g_blackjackPlayerPosition[ MAX_BLACKJACK_PLAYERS ] [ 2 ] = { { 295.0, 334.0 }, { 205.0, 319.0 }, { 390.0, 329.0 } };

    for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ )
    {
        for ( new p = 0; p < MAX_BLACKJACK_PLAYERS; p ++ )
        {
            g_blackjackPlayerCards[ id ] [ c ] [ p ] = TextDrawCreate( g_blackjackPlayerPosition[ p ] [ 0 ] + 10.0 * float( c ), g_blackjackPlayerPosition[ p ] [ 1 ] - 16.0 * float( c ), "ld_card:cdback" );
            TextDrawBackgroundColor( g_blackjackPlayerCards[ id ] [ c ] [ p ], 255 );
            TextDrawFont( g_blackjackPlayerCards[ id ] [ c ] [ p ], 4 );
            TextDrawLetterSize( g_blackjackPlayerCards[ id ] [ c ] [ p ], 0.5, 0.7 );
            TextDrawUseBox( g_blackjackPlayerCards[ id ] [ c ] [ p ], 1 );
            TextDrawBoxColor( g_blackjackPlayerCards[ id ] [ c ] [ p ], 255 );
            TextDrawTextSize( g_blackjackPlayerCards[ id ] [ c ] [ p ], 22.000000, 37.000000 );
        }
    }

}

stock IsPlayerHandBlackjack( tableid, player_index, card_count )
{
	if ( card_count == 21 && ( g_blackjackPlayerCardIndex[ tableid ] [ 0 ] [ player_index ] == 0 || g_blackjackPlayerCardIndex[ tableid ] [ 0 ] [ player_index ] == 13 || g_blackjackPlayerCardIndex[ tableid ] [ 0 ] [ player_index ] == 26 || g_blackjackPlayerCardIndex[ tableid ] [ 0 ] [ player_index ] == 39 ) )
		return true;

	if ( card_count == 21 && ( g_blackjackPlayerCardIndex[ tableid ] [ 1 ] [ player_index ] == 0 || g_blackjackPlayerCardIndex[ tableid ] [ 1 ] [ player_index ] == 13 || g_blackjackPlayerCardIndex[ tableid ] [ 1 ] [ player_index ] == 26 || g_blackjackPlayerCardIndex[ tableid ] [ 1 ] [ player_index ] == 39 ) )
		return true;

	return false;
}

stock IsDealerHandBlackjack( tableid, card_count )
{
	if ( card_count == 21 && ( g_blackjackDealerCardIndex[ tableid ] [ 0 ] == 0 || g_blackjackDealerCardIndex[ tableid ] [ 0 ] == 13 || g_blackjackDealerCardIndex[ tableid ] [ 0 ] == 26 || g_blackjackDealerCardIndex[ tableid ] [ 0 ] == 39 ) )
		return true;

	if ( card_count == 21 && ( g_blackjackDealerCardIndex[ tableid ] [ 1 ] == 0 || g_blackjackDealerCardIndex[ tableid ] [ 1 ] == 13 || g_blackjackDealerCardIndex[ tableid ] [ 1 ] == 26 || g_blackjackDealerCardIndex[ tableid ] [ 1 ] == 39 ) )
		return true;

	return false;
}

stock GetBlackjackCardValue( card_index )
{
    new
        card_value = 0;

    switch ( card_index )
    {
        case 0, 13, 26, 39: card_value = 1;
        case 1, 14, 27, 40: card_value = 2;
        case 2, 15, 28, 41: card_value = 3;
        case 3, 16, 29, 42: card_value = 4;
        case 4, 17, 30, 43: card_value = 5;
        case 5, 18, 31, 44: card_value = 6;
        case 6, 19, 32, 45: card_value = 7;
        case 7, 20, 33, 46: card_value = 8;
        case 8, 21, 34, 47: card_value = 9;
        case 9, 22, 35, 48, 10, 23, 36, 49, 11, 24, 37, 50, 12, 25, 38, 51: card_value = 10;
    }
    return card_value;
}

stock GetBlackjackPlayerIndex( tableid, playerid )
{
    for ( new player_index = 0; player_index < MAX_BLACKJACK_PLAYERS; player_index ++ ) if ( playerid == g_blackjackSlotData[ tableid ] [ player_index ] ) {
        return player_index;
    }
    return -1;
}

stock GetBlackjackPlayers( tableid ) {
    new
        count = 0;

    for ( new p = 0; p < MAX_BLACKJACK_PLAYERS; p ++ ) if ( g_blackjackSlotData[ tableid ] [ p ] != -1 )
        count ++;

    return count;
}

stock SetBlackjackPlayerLabelValue( tableid, player_index, score ) {
    if ( score != -1 ) {
        new playerid = g_blackjackSlotData[ tableid ] [ player_index ];
        UpdateDynamic3DTextLabelText( g_blackjackData[ tableid ] [ E_PLAYER_LABEL ] [ player_index ], COLOR_GOLD, sprintf( "%s\n"COL_GREY"Score:"COL_WHITE" %d", ReturnPlayerName( playerid ), score ) );
    } else {
        UpdateDynamic3DTextLabelText( g_blackjackData[ tableid ] [ E_PLAYER_LABEL ] [ player_index ], 0, sprintf( "Player %d", player_index ) );
    }
}

stock SetBlackjackDealerLabelValue( tableid, score ) {
    if ( score != -1 ) {
        UpdateDynamic3DTextLabelText( g_blackjackData[ tableid ] [ E_DEALER_LABEL ], COLOR_GREY, sprintf( "Dealer\nScore:"COL_WHITE" %d", score ) );
    } else {
        UpdateDynamic3DTextLabelText( g_blackjackData[ tableid ] [ E_DEALER_LABEL ], COLOR_WHITE, sprintf( "Press ENTER To Play Blackjack\n"COL_WHITE"%s Minimum", cash_format( g_blackjackData[ tableid ] [ E_PAYOUT ] ) ) );
    }
}

stock CalculatePlayerHand( tableid, player_index )
{
    new
        player_score = 0;

    // add player cards
    for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ ) if ( g_blackjackPlayerCardIndex[ tableid ] [ c ] [ player_index ] != -1 ) {
        player_score += GetBlackjackCardValue( g_blackjackPlayerCardIndex[ tableid ] [ c ] [ player_index ] ); // aces will add as 1 anyway
    }

    // double check aces
    for ( new a = 0; a < MAX_BLACKJACK_CARDS; a ++ ) if ( GetBlackjackCardValue( g_blackjackPlayerCardIndex[ tableid ] [ a ] [ player_index ] ) == 1 ) {
        if ( player_score + 10 <= 21 ) player_score += 10; // if there's aces, just use one as an 11. if count stays under 21 of course
        break;
    }
    return player_score;
}

stock CalculateDealerHand( tableid )
{
    new
        dealer_score = 0;

    // add dealer score
    for ( new c = 0; c < MAX_BLACKJACK_CARDS; c ++ ) if ( g_blackjackDealerCardIndex[ tableid ] [ c ] != -1 ) {
        dealer_score += GetBlackjackCardValue( g_blackjackDealerCardIndex[ tableid ] [ c ] ); // aces will add as 1 anyway
    }

    // double check aces
    for ( new a = 0; a < MAX_BLACKJACK_CARDS; a ++ ) if ( GetBlackjackCardValue( g_blackjackDealerCardIndex[ tableid ] [ a ] ) == 1 ) {
        // if there's aces, just use one as an 11. if count stays under 21 of course
        if ( dealer_score + 10 <= 21 ) dealer_score += 10;
        break;
    }
    return dealer_score;
}
