/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\battleroyale\battleroyale.pwn
 * Purpose: Battle Royale minigame implementation for SA-MP
 */

/*
    TODO:
        [ ] Make pickups work
        [ ] Messages fix
        [ ] Prize pool deposit
        [ ] Invisible walls
        [ ] Make areas
        [ ] Hide player name tags / checkpoints
*/

/* ** Includes ** */
#include 							< YSI\y_hooks >
#include 							< YSI\y_iterate >

/* ** Definitions ** */
#define BR_MAX_LOBBIES              ( 10 )
#define BR_MAX_PLAYERS              ( 32 )

#define BR_MAX_PICKUPS              ( 100 )
#define BR_MAX_VEHICLES             ( 5 )

#define BR_INVALID_LOBBY            ( -1 )
#define BR_PLANE_UPDATE_RATE        ( 30 )

/* ** Dialogs ** */
#define DIALOG_BR_LOBBY             ( 6373 )
#define DIALOG_BR_LOBBY_EDIT        ( 6374 )
#define DIALOG_BR_LOBBY_EDIT_ENTRY  ( 6375 )
#define DIALOG_BR_SELECT_AREA       ( 6376 )

/* ** Macros ** */
#define BattleRoyale_SendMessage(%0,%1) \
    BattleRoyale_SMF(%0, -1, "{4B8774}[BATTLE ROYALE] {FFFFFF}" # %1)

#define BattleRoyale_SendMessageAll(%1) \
    SendClientMessageToAllFormatted(-1, "{4B8774}[BATTLE ROYALE] {FFFFFF}" # %1)

/* ** Constants ** */
static const
    Float: BR_CHECKPOINT_POS[ 3 ] = {
        -2080.1951, -407.7742, 38.7344
    },
    Float: BR_ISLAND_POS[ 3 ] = {
        -1504.9567, 1373.8749, 3.8165
    },
    BR_RUNNING_WEAPONS[ ] = {
        22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34
    },
    BR_WALKING_WEAPONS[ ] = {
        4, 8, 9, 23, 24, 25, 27, 29, 30, 31, 33, 34
    },
    BR_VEHICLE_MODELS[ ] = {
        404, 422, 471, 478, 505, 543, 566, 552, 554
    },
    Float: BR_MIN_HEIGHT = 750.0,
    Float: BR_MIN_CAMERA_HEIGHT = 50.0,
    Float: BR_PLANE_RADIUS_FROM_BORDER = 50.0,
    Float: BR_UNITS_PER_SECOND_SHRINK = 1.0
;

/* ** Variables ** */
enum E_BR_LOBBY_STATUS
{
    E_STATUS_WAITING,
    E_STATUS_STARTED,
    E_STATUS_ENDED
};

enum E_BR_LOBBY_DATA
{
	E_NAME[ 24 ],		E_HOST, 				E_PASSWORD[ 5 ],
	E_LIMIT,			E_AREA_ID,              E_BR_LOBBY_STATUS: E_STATUS,
    E_ENTRY_FEE,        E_PRIZE_POOL,

    Float: E_ARMOUR, 	Float: E_HEALTH,

    bool: E_WALK_WEP,   bool: E_CAC_ONLY,

    E_PLANE,            E_PLANE_TIMER,          Float: E_PLANE_ROTATION,

    E_GAME_TIMER,       E_BORDER_ZONE[ 4 ],     Float: E_B_MIN_X,
    Float: E_B_MIN_Y,   Float: E_B_MAX_X,       Float: E_B_MAX_Y,
    E_BOMB_TICK,

    E_PICKUPS[ BR_MAX_PICKUPS ],   E_VEHICLES[ BR_MAX_VEHICLES ],
};

enum E_BR_AREA_DATA
{
    E_NAME[ 24 ],       Float: E_MIN_X,         Float: E_MIN_Y,
    Float: E_MAX_X,     Float: E_MAX_Y
};

static const
    // where all the area data is stored
    br_areaData                     [ 2 ] [ E_BR_AREA_DATA ] =
    {
        { "San Fierro", -2799.0, -358.0, -1400.0, 1513.0 },
        { "Fort Carson", -394.0, 956.0, 164.0, 1254.0 }
    }
;

static stock
    // lobby data & info
    br_lobbyData                    [ BR_MAX_LOBBIES ] [ E_BR_LOBBY_DATA ],
    br_wallBorderObjectUp           [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    br_wallBorderObjectDown         [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    br_wallBorderObjectLeft         [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    br_wallBorderObjectRight        [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    Iterator: battleroyale          < BR_MAX_LOBBIES >,
    Iterator: battleroyaleplayers   [ BR_MAX_LOBBIES ] < BR_MAX_PLAYERS >,

    // player related
    p_battleRoyaleLobby                     [ MAX_PLAYERS ] = { BR_INVALID_LOBBY, ... },
    E_BR_LOBBY_STATUS: p_battleRoyaleStatus [ MAX_PLAYERS ],
    p_battleRoyaleJetNoiseTick              [ MAX_PLAYERS ],
    bool: p_waitingForRespawn               [ MAX_PLAYERS char ],

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

hook OnPlayerDisconnect( playerid, reason )
{
    new
        lobbyid = BattleRoyale_RemovePlayer( playerid, false );

    if ( lobbyid != BR_INVALID_LOBBY ) {
        BattleRoyale_SendMessage( lobbyid, "%s(%d) has disconnected from the match!", ReturnPlayerName( playerid ), playerid );
    }
    return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
    new
        lobbyid = BattleRoyale_RemovePlayer( playerid, true );

    if ( lobbyid != BR_INVALID_LOBBY ) {
        if ( IsPlayerConnected( killerid ) ) {
            BattleRoyale_SendMessage( lobbyid, "%s(%d) has been killed by %s(%d)'s %s!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( killerid ), killerid, ReturnWeaponName( reason ) );
        } else {
            BattleRoyale_SendMessage( lobbyid, "%s(%d) has been killed!", ReturnPlayerName( playerid ), playerid );
        }
		SendDeathMessage( killerid, playerid, reason );
        return Y_HOOKS_BREAK_RETURN_1;
    }
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

hook SetPlayerRandomSpawn( playerid )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( BR_IsValidLobby( lobbyid ) )
    {
        if ( p_battleRoyaleStatus[ playerid ] == E_STATUS_STARTED )
        {
            new
                Float: X, Float: Y, Float: Z;

            GetDynamicObjectPos( br_lobbyData[ lobbyid ] [ E_PLANE ], X, Y, Z );

            ResetPlayerWeapons( playerid );
            GivePlayerWeapon( playerid, 46, 1 ); // parachute

            SetPlayerPos( playerid, X, Y, Z - 2.0 );
            SetPlayerVirtualWorld( playerid, BR_GetWorld( lobbyid ) );

            SetPlayerHealth( playerid, br_lobbyData[ lobbyid ] [ E_HEALTH ] );
            SetPlayerArmour( playerid, br_lobbyData[ lobbyid ] [ E_ARMOUR ] );
            return Y_HOOKS_BREAK_RETURN_1;
        }
    }
    else if ( p_waitingForRespawn{ playerid } )
    {
        BattleRoyale_RespawnPlayer( playerid );
        return Y_HOOKS_BREAK_RETURN_1;
    }
    return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( ! BR_IsValidLobby( lobbyid ) ) {
        return 1;
    }

    // jump out of the plane
    if ( PRESSED( KEY_JUMP ) && GetPlayerState( playerid ) == PLAYER_STATE_SPECTATING )
    {
        BattleRoyale_ThrowFromPlane( playerid );
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
                if ( br_lobbyData[ l ] [ E_STATUS ] != E_STATUS_WAITING )
                {
                    return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "You cannot join this lobby at the moment." );
                }

                // check if the count is under the limit
                if ( Iter_Count( battleroyaleplayers[ l ] ) >= br_lobbyData[ l ] [ E_LIMIT ] )
                {
                    return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "This lobby has reached its maximum player count." );
                }

                // check if player has money for the lobby
                if ( GetPlayerCash( playerid ) < br_lobbyData[ l ] [ E_ENTRY_FEE ] )
                {
                    return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "You need %s to join this lobby.", cash_format( br_lobbyData[ l ] [ E_ENTRY_FEE ] ) );
                }

                // add entry fee to the pool
                GivePlayerCash( playerid, -br_lobbyData[ l ] [ E_ENTRY_FEE ] );
                br_lobbyData[ l ] [ E_PRIZE_POOL ] += br_lobbyData[ l ] [ E_ENTRY_FEE ];

                // join the player to the lobby
                return BattleRoyale_JoinLobby( playerid, l ), 1;
            }
        }

        // check if player has money
        if ( GetPlayerCash( playerid ) < 10000 ) {
            return SendError( playerid, "You need $10,000 to create a battle royale lobby." );
        }

        new
            lobbyid = BattleRoyale_CreateLobby( playerid );

        // otherwise assume they are creating a new lobby
        if ( lobbyid == ITER_NONE ) {
            return SendError( playerid, "You cannot create a battle royale lobby at the moment" );
        }

        GivePlayerCash( playerid, -10000 );
        BattleRoyale_JoinLobby( playerid, lobbyid );
        BattleRoyale_SendMessageAll( "%s(%d) has created a Battle Royale lobby!", ReturnPlayerName( playerid ), playerid );

        return BattleRoyale_EditLobby( playerid, lobbyid );
    }
    else if ( dialogid == DIALOG_BR_LOBBY_EDIT )
    {
        if ( ! response ) {
            return SendServerMessage( playerid, "You can edit your battle royale lobby settings with "COL_GREY"/br edit"COL_WHITE"." );
        }

        new lobbyid = p_battleRoyaleLobby[ playerid ];

        if ( ! BR_IsHost( playerid, lobbyid ) ) {
            return SendError( playerid, "You cannot edit this lobby as you are no longer the host." );
        }

        if ( listitem == 3 ) // select an area
        {
            return BattleRoyale_EditArea( playerid );
        }
        else if ( listitem == 7 ) // select walking weapon mode
        {
            br_lobbyData[ lobbyid ] [ E_WALK_WEP ] = ! br_lobbyData[ lobbyid ] [ E_WALK_WEP ];
            BattleRoyale_SendMessage( lobbyid, "%s has set only walking weapons to %s.", ReturnPlayerName( playerid ), bool_to_string( br_lobbyData[ lobbyid ] [ E_WALK_WEP ] ) );
            return BattleRoyale_EditLobby( playerid, lobbyid );
        }
        else if ( listitem == 8 ) // select cac mode
        {
            if ( IsPlayerUsingSampAC( playerid ) ) {
                br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] = ! br_lobbyData[ lobbyid ] [ E_CAC_ONLY ];
                BattleRoyale_SendMessage( lobbyid, "%s has set CAC mode to %s.", ReturnPlayerName( playerid ), bool_to_string( br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] ) );
            } else {
                SendError( playerid, "You must have SA-MP CAC activated in order to enable this option." );
            }
            return BattleRoyale_EditLobby( playerid, lobbyid );
        }
        else
        {
            SetPVarInt( playerid, "editing_field", listitem );
            return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY_EDIT_ENTRY, DIALOG_STYLE_INPUT, ""COL_WHITE"Battle Royale", "Please enter a value for this field:", "Submit", "Back" );
        }
    }
    else if ( dialogid == DIALOG_BR_SELECT_AREA )
    {
        if ( ! response ) {
            return BattleRoyale_EditLobby( playerid, p_battleRoyaleLobby[ playerid ] );
        }

        new
            lobbyid = p_battleRoyaleLobby[ playerid ];

        if ( ! BR_IsHost( playerid, lobbyid ) ) {
            return SendError( playerid, "You cannot edit this lobby as you are no longer the host." );
        }

        br_lobbyData[ lobbyid ] [ E_AREA_ID ] = listitem;
        BattleRoyale_SendMessage( lobbyid, "You have set the area to %s.", ReturnPlayerName( playerid ), br_areaData[ listitem ] [ E_NAME ] );
        return BattleRoyale_EditLobby( playerid, lobbyid );
    }
    else if ( dialogid == DIALOG_BR_LOBBY_EDIT_ENTRY )
    {
        if ( ! response ) {
            return BattleRoyale_EditLobby( playerid, p_battleRoyaleLobby[ playerid ] );
        }

        new lobbyid = p_battleRoyaleLobby[ playerid ];

        if ( ! BR_IsHost( playerid, lobbyid ) ) {
            return SendError( playerid, "You cannot edit this lobby as you are no longer the host." );
        }

        new editing_field = GetPVarInt( playerid, "editing_field" );

        switch ( editing_field )
        {
            // lobby name
            case 0:
            {
                new
                    name[ 24 ];

                if ( sscanf( inputtext, "s[24]", name ) ) SendError( playerid, "You must enter a valid name." );
                else if ( 3 <= strlen( name ) < 24 ) SendError( playerid, "You must enter a name between 3 and 24 characters." );
                else
                {
                    strcpy( br_lobbyData[ lobbyid ] [ E_NAME ], name );
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // lobby pw
            case 1:
            {
                new
                    password[ 5 ];

                if ( sscanf( inputtext, "s[24]", password ) )
                {
                    erase( br_lobbyData[ lobbyid ] [ E_PASSWORD ] );
                    BattleRoyale_SendMessage( lobbyid, "%s has removed the password requirement for the lobby.", ReturnPlayerName( playerid ) );
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
                else if ( strlen( password ) >= 5 ) SendError( playerid, "You must enter a password between 1 and 5 characters." );
                else
                {
                    strcpy( br_lobbyData[ lobbyid ] [ E_PASSWORD ], password );
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // limit
            case 2:
            {
                new
                    limit;

                if ( sscanf( inputtext, "d", limit ) ) SendError( playerid, "You must enter a valid limit." );
                else if ( ! ( 1 <= limit < BR_MAX_PLAYERS ) ) SendError( playerid, "You must enter a limit between 1 and %d", BR_MAX_PLAYERS );
                else
                {
                    br_lobbyData[ lobbyid ] [ E_LIMIT ] = limit;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // entry_fee
            case 4:
            {
                new
                    entry_fee;

                if ( sscanf( inputtext, "d", entry_fee ) ) SendError( playerid, "You must enter a valid entry fee." );
                else if ( entry_fee <= 0 )
                {
                    br_lobbyData[ lobbyid ] [ E_ENTRY_FEE ] = entry_fee;
                    BattleRoyale_SendMessage( lobbyid, "%s has removed the entry fee requirement for the lobby.", ReturnPlayerName( playerid ) );
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
                else if ( ! ( 0 < entry_fee <= 10000000 ) ) SendError( playerid, "You must enter a entry fee between $1 and $10,000,000." );
                else
                {
                    br_lobbyData[ lobbyid ] [ E_ENTRY_FEE ] = entry_fee;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // health
            case 5:
            {
                new
                    Float: health;

                if ( sscanf( inputtext, "f", health ) ) SendError( playerid, "You must enter a valid health value." );
                else if ( ! ( 1.0 <= health <= 100.0 ) ) SendError( playerid, "You must enter a health value between 1 and 100." );
                else
                {
                    br_lobbyData[ lobbyid ] [ E_HEALTH ] = health;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // armour
            case 6:
            {
                new
                    Float: armour;

                if ( sscanf( inputtext, "f", armour ) ) SendError( playerid, "You must enter a valid armour value." );
                else if ( ! ( 1.0 <= armour <= 100.0 ) ) SendError( playerid, "You must enter a armour value between 1 and 100." );
                else
                {
                    br_lobbyData[ lobbyid ] [ E_ARMOUR ] = armour;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }
        }
        return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY_EDIT_ENTRY, DIALOG_STYLE_INPUT, ""COL_WHITE"Battle Royale", "Please enter a value for this field:", "Submit", "Back" );
    }
    return 1;
}

/* ** Comands ** */
CMD:br( playerid, params[ ] ) return cmd_battleroyale( playerid, params );
CMD:battleroyale( playerid, params[ ] )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( ! BR_IsValidLobby( lobbyid ) ) {
        return SendError( playerid, "You are not in any lobby." );
    }

    if ( strmatch( params, "edit" ) )
    {
        return BattleRoyale_EditLobby( playerid, lobbyid ), 1;
    }
    else if ( strmatch( params, "start" ) )
    {
        return BattleRoyale_StartGame( lobbyid );
    }
    else if ( strmatch( params, "stop" ) )
    {
        // if ( br_lobbyData[ lobbyid ] [ E_STATUS ] == E_STATUS_STARTED )
        //     return SendError( playerid, "You cannot end the game when the lobby has started." );

    }
    return SendUsage( playerid, "/battleroyale [EDIT/START/STOP]" );
}

/* ** Functions ** */
static stock BattleRoyale_CreateLobby( playerid )
{
    new
        lobbyid = Iter_Free( battleroyale );

    if ( lobbyid != ITER_NONE )
    {
        strcpy( br_lobbyData[ lobbyid ] [ E_NAME ], "Battle Royale Lobby" );
        erase( br_lobbyData[ lobbyid ] [ E_PASSWORD ] );

        br_lobbyData[ lobbyid ] [ E_LIMIT ] = 6;
        br_lobbyData[ lobbyid ] [ E_AREA_ID ] = 0;
        br_lobbyData[ lobbyid ] [ E_ENTRY_FEE ] = 0;
        br_lobbyData[ lobbyid ] [ E_HOST ] = playerid;
        br_lobbyData[ lobbyid ] [ E_STATUS ] = E_STATUS_WAITING;

        br_lobbyData[ lobbyid ] [ E_PLANE ] = -1;

        br_lobbyData[ lobbyid ] [ E_HEALTH ] = 100.0;
        br_lobbyData[ lobbyid ] [ E_ARMOUR ] = 0.0;

        br_lobbyData[ lobbyid ] [ E_WALK_WEP ] = false;
        br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] = false;

        Iter_Add( battleroyale, lobbyid );
    }
    return lobbyid; // create lobby dialog
}

static stock BattleRoyale_EditLobby( playerid, lobbyid )
{
    if ( ! BR_IsValidLobby( lobbyid ) ) {
        return 0;
    }

    format(
        szLargeString, sizeof( szLargeString ),
        "Lobby Name\t"COL_GREY"%s\n" \
        "Password\t"COL_GREY"%s\n" \
        "Player Limit\t"COL_GREY"%d\n" \
        "Area\t"COL_GREY"%s\n" \
        "Entry Fee\t"COL_GREEN"%s\n" \
        "Health\t"COL_GREY"%0.2f%%\n" \
        "Armour\t"COL_GREY"%0.2f%%\n" \
        "Running Weapons Only\t%s\n" \
        "CAC Only\t%s\n",
        br_lobbyData[ lobbyid ] [ E_NAME ],
        br_lobbyData[ lobbyid ] [ E_PASSWORD ],
        br_lobbyData[ lobbyid ] [ E_LIMIT ],
        br_areaData[ br_lobbyData[ lobbyid ] [ E_AREA_ID ] ] [ E_NAME ],
        cash_format( br_lobbyData[ lobbyid ] [ E_ENTRY_FEE ] ),
        br_lobbyData[ lobbyid ] [ E_HEALTH ],
        br_lobbyData[ lobbyid ] [ E_ARMOUR ],
        br_lobbyData[ lobbyid ] [ E_WALK_WEP ] ? ( COL_GREEN # "YES" ) : ( COL_RED # "NO" ),
        br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] ? ( COL_GREEN # "YES" ) : ( COL_RED # "NO" )
    );
    return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY_EDIT, DIALOG_STYLE_TABLIST, ""COL_WHITE"Battle Royale", szLargeString, "Edit", "Close" );
}

static stock BattleRoyale_EditArea( playerid )
{
    static
        areas[ 512 ];

    if ( areas[ 0 ] == '\0' ) {
        for ( new i = 0; i < sizeof( br_areaData ); i ++ ) {
            format( areas, sizeof( areas ), "%s%s\n", areas, br_areaData[ i ] [ E_NAME ] );
        }
    }
    return ShowPlayerDialog( playerid, DIALOG_BR_SELECT_AREA, DIALOG_STYLE_LIST, ""COL_WHITE"Battle Royale", areas, "Select", "Close" );
}

static stock BattleRoyale_JoinLobby( playerid, lobbyid )
{
    // set lobby id
    p_battleRoyaleLobby[ playerid ] = lobbyid;
    Iter_Add( battleroyaleplayers[ lobbyid ], playerid );

    // set player position in an island
    BattleRoyale_SendMessage( lobbyid, "%s has joined %s "COL_ORANGE"[%d/%d]", ReturnPlayerName( playerid ), br_lobbyData[ lobbyid ] [ E_NAME ], Iter_Count( battleroyaleplayers[ lobbyid ] ), br_lobbyData[ lobbyid ] [ E_LIMIT ] );
    SetPlayerPos( playerid, BR_ISLAND_POS[ 0 ], BR_ISLAND_POS[ 1 ], BR_ISLAND_POS[ 2 ] );
    SetPlayerVirtualWorld( playerid, BR_GetWorld( lobbyid ) );

    // check if lobby is full
    BattleRoyale_CheckPlayers( lobbyid );
    return 1;
}

static stock BattleRoyale_ShowLobbies( playerid )
{
    // set the headers
    szLargeString = ""COL_WHITE"Lobby Name\t"COL_WHITE"Host\t"COL_WHITE"Players\t"COL_WHITE"Entry Fee\n";

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
    format( szLargeString, sizeof( szLargeString ), "%s"COL_PURPLE"Create Lobby\t \t"COL_PURPLE"$10,000\t"COL_PURPLE">>>", szLargeString );
    return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Battle Royale", szLargeString, "Select", "Close" );
}

static stock BattleRoyale_RespawnPlayer( playerid )
{
    // set position to the entrance of game
    SetPlayerPos( playerid, BR_CHECKPOINT_POS[ 0 ], BR_CHECKPOINT_POS[ 1 ], BR_CHECKPOINT_POS[ 2 ] );
    SetPlayerVirtualWorld( playerid, 0 );
    SetPlayerInterior( playerid, 0 );

    // reset the respawn variable
    p_waitingForRespawn{ playerid } = false;
}

static stock BattleRoyale_RemovePlayer( playerid, bool: respawn, bool: remove_from_iterator = true )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( lobbyid != BR_INVALID_LOBBY )
    {
        // unset player variables from the match
        p_battleRoyaleLobby[ playerid ] = BR_INVALID_LOBBY;
        p_waitingForRespawn{ playerid } = respawn;

        // toggle checkpoints etc
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_CP, true );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_RACE_CP, true );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_MAP_ICON, true );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_3D_TEXT_LABEL, true );

        // perform neccessary operations/checks on the lobby
        if ( remove_from_iterator )
        {
            Iter_Remove( battleroyaleplayers[ lobbyid ], playerid );
            BattleRoyale_CheckPlayers( lobbyid );
        }
    }
    return lobbyid;
}

static stock BattleRoyale_EndGame( lobbyid )
{
    new Float: distribution = float( br_lobbyData[ lobbyid ] [ E_LIMIT ] ) / float( Iter_Count( battleroyaleplayers[ lobbyid ] ) );
    new prize = floatround( float( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] ) * ( distribution > 1.0 ? 1.0 : distribution ) );

    foreach ( new playerid : battleroyaleplayers[ lobbyid ] )
    {
        BattleRoyale_SendMessageAll( "%s(%d) has won %s (%0.0f%%) out of the %s prize pool.", ReturnPlayerName( playerid ), playerid, cash_format( prize ), distribution, br_lobbyData[ lobbyid ] [ E_NAME ] );
        BattleRoyale_RemovePlayer( playerid, true, false );
        GivePlayerCash( playerid, prize );
        SpawnPlayer( playerid );
    }
    return BattleRoyale_DestroyLobby( lobbyid );
}

static stock BattleRoyale_CheckPlayers( lobbyid )
{
    if ( ! BR_IsValidLobby( lobbyid ) ) {
        return 0;
    }

    new
        total_players = Iter_Count( battleroyaleplayers[ lobbyid ] );

    // check if there is no more players
    if ( total_players <= 1 && br_lobbyData[ lobbyid ] [ E_STATUS ] == E_STATUS_STARTED )
    {
        return BattleRoyale_EndGame( lobbyid );
    }

    // check if player limit surpassed
    else if ( total_players >= br_lobbyData[ lobbyid ] [ E_LIMIT ] && br_lobbyData[ lobbyid ] [ E_STATUS ] == E_STATUS_WAITING )
    {
        return BattleRoyale_StartGame( lobbyid );
    }

    // if no players, get rid of the lobby
    else if ( total_players <= 0 )
    {
        return BattleRoyale_DestroyLobby( lobbyid );
    }
    return 1;
}

static stock BattleRoyale_StartGame( lobbyid )
{
    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];

    br_lobbyData[ lobbyid ] [ E_STATUS ] = E_STATUS_STARTED;

    // plane movement
    br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] = 0.0;
    br_lobbyData[ lobbyid ] [ E_PLANE ] = CreateDynamicObject( 1681, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = -1, .interiorid = -1 );

    KillTimer( br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] );
    br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] = SetTimerEx( "BattleRoyale_PlaneMove", BR_PLANE_UPDATE_RATE, true, "d", lobbyid );

    // set the area variables
    br_lobbyData[ lobbyid ] [ E_B_MIN_X ] = br_areaData[ areaid ] [ E_MIN_X ];
    br_lobbyData[ lobbyid ] [ E_B_MAX_X ] = br_areaData[ areaid ] [ E_MAX_X ];
    br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] = br_areaData[ areaid ] [ E_MIN_Y ];
    br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] = br_areaData[ areaid ] [ E_MAX_Y ];

    // generate entities randomly
    BattleRoyale_GenerateEntities( lobbyid );

    // destroy border walls
    BattleRoyale_DestroyBorder( lobbyid );

    // create border walls
    BattleRoyale_CreateBorder( lobbyid );

    // game timer
    br_lobbyData[ lobbyid ] [ E_GAME_TIMER ] = SetTimerEx( "BattleRoyale_GameUpdate", 2500, true, "d", lobbyid);

    // load the player into the area
    foreach ( new playerid : battleroyaleplayers[ lobbyid ] )
    {
        p_battleRoyaleStatus[ playerid ] = E_STATUS_WAITING;
        TogglePlayerSpectating( playerid, true );

        // hide default cnr things
        Turf_HideAllGangZones( playerid );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_CP, false );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_RACE_CP, false );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_MAP_ICON, false );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_3D_TEXT_LABEL, false );
        Streamer_Update( playerid );

        // show the battle royal playable zone
        for ( new g = 0; g < 4; g ++ ) {
            GangZoneShowForPlayer( playerid, br_lobbyData[ areaid ] [ E_BORDER_ZONE ] [ g ], 0x000000FF );
        }

        // show controls
        ShowPlayerHelpDialog( playerid, 0, "~y~~h~~k~~PED_JUMPING~~w~ - Jump Out Of Plane" );
    }
    print("Started game");
    return 1;
}

function BattleRoyale_GameUpdate( lobbyid )
{
    // prevent zone shrinking and bombing while the plane is rotating
    if ( br_lobbyData[ lobbyid ] [ E_PLANE ] != -1 ) {
        return 1;
    }

    // decrease zone size
    new Float: radius_x = ( VectorSize( br_lobbyData[ lobbyid ] [ E_B_MIN_X ] - br_lobbyData[ lobbyid ] [ E_B_MAX_X ], 0.0, 0.0 ) ) / 2.0;
    new Float: radius_y = ( VectorSize( 0.0, br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] - br_lobbyData[ lobbyid ] [ E_B_MAX_Y ], 0.0 ) ) / 2.0;

    if ( radius_x > radius_y )
    {
        new Float: rate_of_change = 1.0 / ( radius_y / radius_x );

        br_lobbyData[ lobbyid ] [ E_B_MIN_X ] += rate_of_change * BR_UNITS_PER_SECOND_SHRINK;
        br_lobbyData[ lobbyid ] [ E_B_MAX_X ] -= rate_of_change * BR_UNITS_PER_SECOND_SHRINK;

        br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] += BR_UNITS_PER_SECOND_SHRINK;
        br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] -= BR_UNITS_PER_SECOND_SHRINK;

        BattleRoyale_RedrawBorder( lobbyid, rate_of_change * BR_UNITS_PER_SECOND_SHRINK, BR_UNITS_PER_SECOND_SHRINK );
    }
    else
    {
        new Float: rate_of_change = 1.0 / ( radius_x / radius_y );

        br_lobbyData[ lobbyid ] [ E_B_MIN_X ] += BR_UNITS_PER_SECOND_SHRINK;
        br_lobbyData[ lobbyid ] [ E_B_MAX_X ] -= BR_UNITS_PER_SECOND_SHRINK;

        br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] += rate_of_change * BR_UNITS_PER_SECOND_SHRINK;
        br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] -= rate_of_change * BR_UNITS_PER_SECOND_SHRINK;

        BattleRoyale_RedrawBorder( lobbyid, BR_UNITS_PER_SECOND_SHRINK, rate_of_change * BR_UNITS_PER_SECOND_SHRINK );
    }

    // ensure a minimum zone area
    if ( br_lobbyData[ lobbyid ] [ E_B_MAX_X ] - br_lobbyData[ lobbyid ] [ E_B_MIN_X ] < 5.0 || br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] - br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] < 5.0 ) {
        return BattleRoyale_EndGame( lobbyid );
    }

    // hurt players outside the zone
    foreach ( new playerid : battleroyaleplayers[ lobbyid ] )
    {
        if ( ! IsPlayerInArea( playerid, br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ], br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] ) )
        {
            new
                Float: health;

            GetPlayerHealth( playerid, health );
            GameTextForPlayer( playerid, "~r~STAY IN THE AREA!", 3500, 3 );
            SetPlayerHealth( playerid, health - 5.0 );
        }
    }

    // rocket
    new
        tick_count = GetServerTime( );

    if ( br_lobbyData[ lobbyid ] [ E_BOMB_TICK ] < tick_count )
    {
        new Float: X = fRandomEx( br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ] );
        new Float: Y = fRandomEx( br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] );
        new Float: Z;

        MapAndreas_FindZ_For2DCoord( X, Y, Z );

        new rocket = CreateDynamicObject( 3786, X, Y, Z + 250.0, 5.0, -90.0, 0.0 );
        new flare = CreateDynamicObject( 18728, X, Y, Z, 0.0, 0.0, 0.0 );
        new move_speed = MoveDynamicObject( rocket, X, Y, Z, 25.0 );

        foreach ( new playerid : battleroyaleplayers[ lobbyid ] ) {
            PlayerPlaySound( playerid, 14800, X, Y, Z );
            Streamer_Update( playerid, STREAMER_TYPE_OBJECT );
        }

        br_lobbyData[ lobbyid ] [ E_BOMB_TICK ] = tick_count + 10;
        SetTimerEx( "BattleRoyale_ExplodeBomb", move_speed, false, "dddfff", lobbyid, rocket, flare, X, Y, Z );
    }
    return 1;
}

function BattleRoyale_ExplodeBomb( lobbyid, rocketid, flareid, Float: X, Float: Y, Float: Z )
{
	// destroy the rocket after it is moved
	DestroyDynamicObject( rocketid );
	DestroyDynamicObject( flareid );

    // create explosion
    foreach ( new playerid : battleroyaleplayers[ lobbyid ] )
    {
        CreateExplosionForPlayer( playerid, X, Y, Z, 6, 10.0 );
    }
    return 1;
}

function BattleRoyale_PlaneMove( lobbyid )
{
    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];

    new Float: middle_x = ( br_areaData[ areaid ] [ E_MIN_X ] + br_areaData[ areaid ] [ E_MAX_X ] ) / 2.0;
    new Float: middle_y = ( br_areaData[ areaid ] [ E_MIN_Y ] + br_areaData[ areaid ] [ E_MAX_Y ] ) / 2.0;

    new Float: radius_x = ( VectorSize( br_areaData[ areaid ] [ E_MIN_X ] - br_areaData[ areaid ] [ E_MAX_X ], 0.0, 0.0 ) ) / 2.0 - BR_PLANE_RADIUS_FROM_BORDER;
    new Float: radius_y = ( VectorSize( 0.0, br_areaData[ areaid ] [ E_MIN_Y ] - br_areaData[ areaid ] [ E_MAX_Y ], 0.0 ) ) / 2.0 - BR_PLANE_RADIUS_FROM_BORDER;

    // if the plane completes a full rotation, throw everyone out
    if ( ( br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] += 0.006 * float( BR_PLANE_UPDATE_RATE ) ) >= 360.0 )  // 360.00 / 60000.0 * rate
    {
        new
            unready_players = 0;

        foreach ( new playerid : battleroyaleplayers[ lobbyid ] ) if ( p_battleRoyaleStatus[ playerid ] != E_STATUS_STARTED )
        {
            unready_players ++;
            BattleRoyale_ThrowFromPlane( playerid );
            SendServerMessage( playerid, "You have been thrown out of your plane due to a lack of decision." );
        }

        // ensures that the plane object is kept while players are thrown out
        if ( ! unready_players )
        {
            KillTimer( br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] );
            br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] = -1;

            DestroyDynamicObject( br_lobbyData[ lobbyid ] [ E_PLANE ] );
            br_lobbyData[ lobbyid ] [ E_PLANE ] = -1;
        }
        return;
    }

    new Float: plane_x = middle_x + radius_x * floatsin( br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ], degrees );
    new Float: plane_y = middle_y + radius_y * floatcos( br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ], degrees );

    SetDynamicObjectPos( br_lobbyData[ lobbyid ] [ E_PLANE ], plane_x, plane_y, BR_MIN_HEIGHT );

    new Float: plane_ahead_x = middle_x + radius_x * floatsin( br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] + 0.006 * float( BR_PLANE_UPDATE_RATE ), degrees );
    new Float: plane_ahead_y = middle_y + radius_y * floatcos( br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] + 0.006 * float( BR_PLANE_UPDATE_RATE ), degrees );

    new Float: rotation = atan2( plane_ahead_y - plane_y, plane_ahead_x - plane_x ) - 90.0;

    SetDynamicObjectRot( br_lobbyData[ lobbyid ] [ E_PLANE ], 0.0, 0.0, rotation );

    foreach ( new playerid : battleroyaleplayers[ lobbyid ] ) if ( p_battleRoyaleStatus[ playerid ] == E_STATUS_WAITING )
    {
        SetPlayerCameraPos( playerid, plane_x, plane_y, BR_MIN_HEIGHT + BR_MIN_CAMERA_HEIGHT );
        SetPlayerCameraLookAt( playerid, plane_x, plane_y, BR_MIN_HEIGHT );

        new
            tick_count = GetTickCount( );

        if ( tick_count > p_battleRoyaleJetNoiseTick[ playerid ] ) {
            PlayerPlaySound( playerid, 14400, plane_x, plane_y, BR_MIN_HEIGHT + BR_MIN_CAMERA_HEIGHT * 0.70 );
            p_battleRoyaleJetNoiseTick[ playerid ] = tick_count + 250;
        }
    }
}

static stock BattleRoyale_ThrowFromPlane( playerid )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( BR_IsValidLobby( lobbyid ) && p_battleRoyaleStatus[ playerid ] == E_STATUS_WAITING )
    {
        p_battleRoyaleStatus[ playerid ] = E_STATUS_STARTED;
        TogglePlayerSpectating( playerid, false );
        HidePlayerHelpDialog( playerid );
    }
    return 1;
}

static stock BattleRoyale_DestroyLobby( lobbyid )
{
    Iter_Remove( battleroyale, lobbyid );
    Iter_Clear( battleroyaleplayers[ lobbyid ] );

    BattleRoyale_DestroyBorder( lobbyid );
    BattleRoyale_DestroyEntities( lobbyid );

    KillTimer( br_lobbyData[ lobbyid ] [ E_GAME_TIMER ] );
    br_lobbyData[ lobbyid ] [ E_GAME_TIMER ] = -1;

    KillTimer( br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] );
    br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] = -1;

    DestroyDynamicObject( br_lobbyData[ lobbyid ] [ E_PLANE ] );
    br_lobbyData[ lobbyid ] [ E_PLANE ] = -1;
    return 1;
}

static stock BattleRoyale_RedrawBorder( lobbyid, Float: sides_rate = 1.0, Float: top_rate = 1.0 )
{
    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];
    new temporary_gangzone[ 4 ];

    // redraw gangzones
    temporary_gangzone[ 0 ] = GangZoneCreate( br_lobbyData[ lobbyid ] [ E_B_MAX_X ],-3000, 3000, 3000 );
    temporary_gangzone[ 1 ] = GangZoneCreate( -3000, -3000, br_lobbyData[ lobbyid ] [ E_B_MIN_X ], 3000 );
    temporary_gangzone[ 2 ] = GangZoneCreate( br_lobbyData[ lobbyid ] [ E_B_MIN_X ], -3000, br_lobbyData[ lobbyid ] [ E_B_MAX_X ], br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] );
    temporary_gangzone[ 3 ] = GangZoneCreate( br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ], 3000 );

    // show the new gangzone
    foreach ( new playerid : battleroyaleplayers[ areaid ] ) {
        for ( new g = 0; g < 4; g ++ ) {
            GangZoneShowForPlayer( playerid, temporary_gangzone[ g ], 0x000000FF );
        }
    }

    // delete old gangzone, set the new
    for ( new g = 0; g < 4; g ++ ) {
        GangZoneDestroy( br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ g ] );
        br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ g ] = temporary_gangzone[ g ];
    }

    // move objects
    for ( new i = 0; i < sizeof( br_wallBorderObjectUp[ ] ); i ++ )
    {
        for ( new z = 0; z < sizeof( br_wallBorderObjectUp[ ] [ ] ); z ++ )
        {
            MoveDynamicObject( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ] + 240.0 * float( i ), br_lobbyData[ lobbyid ] [ E_B_MAX_Y ], 240.0 * float( z ), top_rate );
            MoveDynamicObject( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ] + 240.0 * float( i ), br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], 240.0 * float( z ), top_rate );
            MoveDynamicObject( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), sides_rate );
            MoveDynamicObject( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), sides_rate );
        }
    }
}

static stock BattleRoyale_CreateBorder( lobbyid )
{
    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];

    // gang zone
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 0 ] = GangZoneCreate( br_areaData[ areaid ] [ E_MAX_X ],-3000, 3000, 3000 );
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 1 ] = GangZoneCreate( -3000, -3000, br_areaData[ areaid ] [ E_MIN_X ], 3000 );
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 2 ] = GangZoneCreate( br_areaData[ areaid ] [ E_MIN_X ], -3000, br_areaData[ areaid ] [ E_MAX_X ], br_areaData[ areaid ] [ E_MIN_Y ] );
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 3 ] = GangZoneCreate( br_areaData[ areaid ] [ E_MIN_X ], br_areaData[ areaid ] [ E_MAX_Y ], br_areaData[ areaid ] [ E_MAX_X ], 3000 );

    // walls
    for ( new i = 0; i < sizeof( br_wallBorderObjectUp[ ] ); i ++ )
    {
        for ( new z = 0; z < sizeof( br_wallBorderObjectUp[ ] [ ] ); z ++ )
        {
            br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MIN_X ] + 240.0 * float( i ), br_areaData[ areaid ] [ E_MAX_Y ], 240.0 * float( z ), 0.0, -90.0, 90.0, .worldid = BR_GetWorld( lobbyid ) );
            br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MIN_X ] + 240.0 * float( i ), br_areaData[ areaid ] [ E_MIN_Y ], 240.0 * float( z ), 0.0, -90.0, 90.0, .worldid = BR_GetWorld( lobbyid ) );
            br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MIN_X ], br_areaData[ areaid ] [ E_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), 0.0, -90.0, 0.0, .worldid = BR_GetWorld( lobbyid ) );
            br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MAX_X ], br_areaData[ areaid ] [ E_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), 0.0, -90.0, 0.0, .worldid = BR_GetWorld( lobbyid ) );

            SetDynamicObjectMaterial( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ], 0, 3925, "weemap", "chevron_red_64HVa", -65536 );
            SetDynamicObjectMaterial( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ], 0, 3925, "weemap", "chevron_red_64HVa", -65536 );
            SetDynamicObjectMaterial( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ], 0, 3925, "weemap", "chevron_red_64HVa", -65536 );
            SetDynamicObjectMaterial( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ], 0, 3925, "weemap", "chevron_red_64HVa", -65536 );
        }
    }
}

static stock BattleRoyale_DestroyBorder( lobbyid )
{
    // gangzone
    for ( new g = 0; g < 4; g ++ )
    {
        GangZoneDestroy( br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ g ] );
        br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ g ] = -1;
    }

    // walls
    for ( new i = 0; i < sizeof( br_wallBorderObjectUp[ ] ); i ++ )
    {
        for ( new z = 0; z < sizeof( br_wallBorderObjectUp[ ] [ ] ); z ++ )
        {
            DestroyDynamicObject( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ] = -1;
            DestroyDynamicObject( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ] = -1;
            DestroyDynamicObject( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ] = -1;
            DestroyDynamicObject( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ] = -1;
        }
    }
}

static stock BR_IsValidLobby( lobbyid ) {
    return 0 <= lobbyid < BR_MAX_LOBBIES && Iter_Contains( battleroyale, lobbyid );
}

static stock BR_IsHost( playerid, lobbyid ) {
    return BR_IsValidLobby( lobbyid ) && br_lobbyData[ lobbyid ] [ E_HOST ] == playerid;
}

static stock BR_GetWorld( lobbyid ) {
    return 639 + lobbyid;
}

static stock BattleRoyale_GenerateEntities( lobbyid )
{
    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];

    // destroy entities incase they exist
    BattleRoyale_DestroyEntities( lobbyid );

    // generate pickups
    for ( new i = 0; i < BR_MAX_PICKUPS; i ++ )
    {
        new weaponid = br_lobbyData[ lobbyid ] [ E_WALK_WEP ] ? BR_WALKING_WEAPONS[ random( sizeof( BR_WALKING_WEAPONS ) ) ] : BR_RUNNING_WEAPONS[ random( sizeof( BR_RUNNING_WEAPONS ) ) ];

        new Float: X = fRandomEx( br_areaData[ areaid ] [ E_MIN_X ] + BR_PLANE_RADIUS_FROM_BORDER, br_areaData[ areaid ] [ E_MAX_X ] - BR_PLANE_RADIUS_FROM_BORDER );
        new Float: Y = fRandomEx( br_areaData[ areaid ] [ E_MIN_Y ] + BR_PLANE_RADIUS_FROM_BORDER, br_areaData[ areaid ] [ E_MAX_Y ] - BR_PLANE_RADIUS_FROM_BORDER );
        new Float: Z;

        MapAndreas_FindZ_For2DCoord( X, Y, Z );

        br_lobbyData[ lobbyid ] [ E_PICKUPS ] [ i ] = CreateDynamicPickup( GetWeaponModel( weaponid ), 1, X, Y, Z + 1.0, .worldid = BR_GetWorld( lobbyid ) );
    }

    // generate random cars
    for ( new c = 0; c < BR_MAX_VEHICLES; c ++ )
    {
        new modelid = BR_VEHICLE_MODELS[ random( sizeof( BR_VEHICLE_MODELS ) ) ];

        new Float: X = fRandomEx( br_areaData[ areaid ] [ E_MIN_X ] + BR_PLANE_RADIUS_FROM_BORDER * 3.0, br_areaData[ areaid ] [ E_MAX_X ] - BR_PLANE_RADIUS_FROM_BORDER * 3.0 );
        new Float: Y = fRandomEx( br_areaData[ areaid ] [ E_MIN_Y ] + BR_PLANE_RADIUS_FROM_BORDER * 3.0, br_areaData[ areaid ] [ E_MAX_Y ] - BR_PLANE_RADIUS_FROM_BORDER * 3.0 );
        new Float: Z = 0.0;

        new nodeid = NearestNodeFromPoint( X, Y, Z );
        GetNodePos( nodeid, X, Y, Z );

        br_lobbyData[ lobbyid ] [ E_VEHICLES ] [ c ] = CreateVehicle( modelid, X, Y, Z + 1.5, fRandomEx( 0.0, 360.0 ), -1, -1, 0, 0 );
        SetVehicleVirtualWorld( br_lobbyData[ lobbyid ] [ E_VEHICLES ] [ c ], BR_GetWorld( lobbyid ) );
    }
}

static stock BattleRoyale_DestroyEntities( lobbyid )
{
    for ( new i = 0; i < BR_MAX_PICKUPS; i ++ )
    {
        // destroy pickup
        DestroyDynamicPickup( br_lobbyData[ lobbyid ] [ E_PICKUPS ] [ i ] );
        br_lobbyData[ lobbyid ] [ E_PICKUPS ] [ i ] = -1;

        // destroy vehicles (do it in the same loop)
        if ( i < BR_MAX_VEHICLES )
        {
            DestroyVehicle( br_lobbyData[ lobbyid ] [ E_VEHICLES ] [ i ] );
            br_lobbyData[ lobbyid ] [ E_VEHICLES ] [ i ] = -1;
        }
    }
    return 1;
}

stock BattleRoyale_SMF( lobbyid, colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach ( new i : battleroyaleplayers[ lobbyid ] ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock IsPlayerInBattleRoyale( playerid ) {
    return BR_IsValidLobby( p_battleRoyaleLobby[ playerid ] );
}