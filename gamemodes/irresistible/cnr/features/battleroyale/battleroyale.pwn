/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\battleroyale\battleroyale.pwn
 * Purpose: Battle Royale minigame implementation for SA-MP
 */

 /*

1. Player creates lobby
    - Lobby can be CAC only
    - Player can select area
    - Player can select speed in which the circle shrinks
    - Player can select between running weapons, walking weapons or both (as drops)
    - Player can make an entry fee, this entry fee gets added to a prize pool

2. Players join the lobby, you teleport to an island
    - After the maximum slots are achieved, the game will start
    - Host can start the match forcefully
3. Plane in the middle, you have a parachute, jump out
4. Stay within red zone, if you leave it you get killed
5. Last man standing wins ...

*/

/* ** Includes ** */
#include 							< YSI\y_hooks >
#include 							< YSI\y_iterate >

/* ** Definitions ** */
#define BR_MAX_LOBBIES              ( 10 )
#define BR_MAX_PLAYERS              ( 32 )
#define BR_INVALID_LOBBY            ( -1 )

/* ** Dialogs ** */
#define DIALOG_BR_LOBBY             ( 6373 )

/* ** Constants ** */
static const
    Float: BR_CHECKPOINT_POS[ 3 ] = {
        0.0, 0.0, 0.0
    },
    BR_RUNNING_WEAPONS[ ] = {
        22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34
    },
    BR_WALKING_WEAPONS[ ] = {
        4, 8, 9, 23, 24, 25, 27, 29, 30, 31, 33, 34
    }
;

/* ** Variables ** */
enum E_BR_LOBBY_STATUS
{
    E_SETUP,
    E_WAITING_FOR_PLAYERS,
    E_STARTED
};

enum E_BR_LOBBY_DATA
{
	E_NAME[ 16 ],		E_HOST, 				E_PASSWORD[ 5 ],
	E_LIMIT,			E_AREA_ID,              E_BR_LOBBY_STATUS: E_STATUS,
    E_ENTRY_FEE,

    Float: E_ARMOUR, 	Float: E_HEALTH,

    bool: E_CHAT,       bool: E_WALKING_WEAPONS
};

enum E_BR_AREA_DATA
{
    E_NAME[ 16 ],       E_MIN_X,                E_MAX_X,
    E_MIN_Y,            E_MAX_Y
};

static stock
    // where all the area data is stored
    br_areaData                     [ ] [ E_BR_AREA_DATA ] =
    {
        { "San Fierro", 0.0, 0.0, 0.0, 0.0 }
    },

    // lobby data & info
    br_lobbyData                    [ BR_MAX_LOBBIES ] [ E_BR_LOBBY_DATA ],
    Iterator: battleroyale          < BR_MAX_LOBBIES >,
    Iterator: battleroyaleplayers   [ BR_MAX_LOBBIES ] < BR_MAX_PLAYERS >,

    // player related
    p_battleRoyaleLobby             [ MAX_PLAYERS ] = { BR_INVALID_LOBBY, ... },

    // global related
    g_battleRoyaleStadiumCP         = -1
;

/* ** Hooks ** */
hook OnScriptInit( )
{
    g_battleRoyaleStadiumCP = CreateDynamicCP( BR_CHECKPOINT_POS[ 0 ], BR_CHECKPOINT_POS[ 1 ], BR_CHECKPOINT_POS[ 2 ], 1.0, 0 );
	CreateDynamic3DTextLabel( "[BATTLE ROYALE]", COLOR_GOLD, BR_CHECKPOINT_POS[ 0 ], BR_CHECKPOINT_POS[ 1 ], BR_CHECKPOINT_POS[ 2 ], 20.0 );
    return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
    if ( checkpointid == g_battleRoyaleStadiumCP )
    {
        return BattleRoyale_ShowLobbies( playerid );
    }
    return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    if ( dialogid == DIALOG_BR_LOBBY && response )
    {
        new
            x = 0;

        // check if the player selected an existing lobby
        foreach ( new l : battleroyale )
        {
            if ( x == listitem )
            {
                // status must be in a waiting state
                if ( br_lobbyData[ l ] [ E_STATUS ] != E_WAITING_FOR_PLAYERS )
                {
                    return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "You cannot join this lobby at the moment." );
                }

                // check if the count is under the limit
                if ( Iter_Count( battleroyaleplayers[ l ] ) >= br_lobbyData[ l ] [ E_LIMIT ] )
                {
                    return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "This lobby has reached its maximum player count." );
                }

                return BattleRoyale_ShowLobbyInfo( playerid, l ), 1;
            }
        }

        // otherwise assume they are creating a new lobby
        BattleRoyale_CreateLobby( playerid );
        return 1;
    }
    return 1;
}

/* ** Functions ** */
static stock BattleRoyale_CreateLobby( playerid )
{
    return 1; // create lobby dialog
}

static stock BattleRoyale_ShowLobbyInfo( playerid, lobbyid )
{
    if ( ! BR_IsValidLobby( lobbyid ) ) {
        return 0;
    }

    return 1; // join lobby dialog
}

static stock BattleRoyale_ShowLobbies( playerid )
{
    // set the headers
    szLargeString = ""COL_WHITE"Lobby Name\tHost\tPlayers\tEntry Fee\n";

    // format dialog
    foreach ( new l : battleroyale )
    {
        format(
            szLargeString, sizeof( szLargeString ),
            "%s%s\t%s\t%d / %d\t%s\n",
            szLargeString,
            br_lobbyData[ l ] [ E_NAME ],
            IsPlayerConnected( br_lobbyData[ l ] [ E_HOST ] ) ? ( ReturnPlayerName( br_lobbyData[ l ] [ E_HOST ] ) ) : ( "N/A" ),
            Iter_Count( battleroyaleplayers[ l ] ),
            br_lobbyData[ l ] [ E_LIMIT ],
            cash_format( br_lobbyData[ l ] [ E_ENTRY_FEE ] )
        );
    }

    // make final option to create lobby
    format( szLargeString, sizeof( szLargeString ), COL_PURPLE # "Create Lobby\t"COL_PURPLE">>>\t"COL_PURPLE">>>\t"COL_PURPLE">>>" );
    return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Battle Royale", szLargeString, "Select", "Close" );
}

stock BattleRoyale_RemovePlayer( playerid )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( lobbyid != BR_INVALID_LOBBY )
    {
        // unset player variables from the match
        p_battleRoyaleLobby[ playerid ] = BR_INVALID_LOBBY;

        // perform neccessary operations/checks on the lobby
        Iter_Remove( battleroyaleplayers[ lobbyid ], playerid );
        BattleRoyale_CheckPlayers( lobbyid );
    }
    return 1;
}

static stock BattleRoyale_CheckPlayers( lobbyid )
{
    if ( BR_IsValidLobby( lobbyid ) && Iter_Count( battleroyaleplayers[ lobbyid ] ) <= 0 )
    {
        return BattleRoyale_DestroyLobby( lobbyid );
    }
    return 0;
}

static stock BattleRoyale_DestroyLobby( lobbyid )
{
    // TODO:
    return 1;
}

static stock BR_IsValidLobby( lobbyid ) {
    return 0 <= lobbyid < BR_MAX_LOBBIES && Iter_Contains( battleroyale, lobbyid );
}