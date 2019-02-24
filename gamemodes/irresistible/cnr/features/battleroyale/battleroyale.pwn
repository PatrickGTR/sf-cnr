/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\battleroyale\battleroyale.pwn
 * Purpose: Battle Royale minigame implementation for SA-MP
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >
#include 							< YSI\y_iterate >

/* ** Definitions ** */
#define BR_MAX_LOBBIES              ( 5 )
#define BR_MAX_PLAYERS              ( 33 )

#define BR_MAX_PICKUPS              ( 250 )
#define BR_MAX_VEHICLES             ( 25 )
#define BR_MAX_AIRDROPS             ( 25 )

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
        -2109.6680, -444.1471, 38.7344
    },
    Float: BR_ISLAND_POS[ 3 ] = {
        -4957.9775, 2031.4171, 5.8310
    },
    BR_RUNNING_WEAPONS[ ] = {
        22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34
    },
    BR_WALKING_WEAPONS[ ] = {
        23, 24, 25, 27, 29, 30, 31, 33, 34
    },
    BR_VEHICLE_MODELS[ ] = {
        404, 422, 471, 478, 505, 543, 566, 552, 554
    },
    Float: BR_MIN_HEIGHT = 750.0,
    Float: BR_MIN_CAMERA_HEIGHT = 150.0,
    Float: BR_PLANE_RADIUS_FROM_BORDER = 50.0
;

/* ** Variables ** */
enum E_BR_LOBBY_STATUS
{
    E_STATUS_WAITING,
    E_STATUS_STARTED
};

enum E_BR_LOBBY_DATA
{
	E_NAME[ 24 ],		E_HOST,
	E_LIMIT,			E_AREA_ID,              E_BR_LOBBY_STATUS: E_STATUS,
    E_ENTRY_FEE,        E_PRIZE_POOL,

    Float: E_ARMOUR, 	Float: E_HEALTH,

    bool: E_WALK_WEP,   bool: E_CAC_ONLY,

    E_PLANE,            E_PLANE_TIMER,          Float: E_PLANE_ROTATION,

    E_GAME_TIMER,       E_BORDER_ZONE[ 4 ],     Float: E_B_MIN_X,
    Float: E_B_MIN_Y,   Float: E_B_MAX_X,       Float: E_B_MAX_Y,
    E_BOMB_TICK,

    E_AIR_DROPS[ BR_MAX_AIRDROPS ], E_AIRDROP_TICK,

    E_VEHICLES[ BR_MAX_VEHICLES ],
};

enum E_BR_AIRDROP_DATA
{
    E_MAP_ICON,         E_PICKUP,               E_OBJECT
};

enum E_BR_PICKUP_DATA
{
    E_PICKUP,           E_WEAPON_ID,
};

enum E_BR_AREA_DATA
{
    E_NAME[ 24 ],       Float: E_MIN_X,         Float: E_MIN_Y,
    Float: E_MAX_X,     Float: E_MAX_Y,         E_MAX_PICKUPS,
    E_MAX_VEHICLES,     Float: E_SHRINK_SPEED
};

static const
    // where all the area data is stored
    br_areaData                     [ ] [ E_BR_AREA_DATA ] =
    {
        { "Fort Carson", -465.9, 751.0, 277.0, 1361.0, 50, 5, 2.0 },
        { "Blueberry", -294.5, -451.5, 479.5, 272.5, 50, 5, 2.0 },
        { "Polomino Creek", 2082.5, -326.5, 2952.5, 496.5, 75, 5, 2.0 },
        { "Angel Pine", -2913.5, -2963.0, -1459.5, -1953.0, 100, 10, 3.0 },
        { "Tierra Robada", -2989.5, 2074.5, -1144.5, 2990.5, 150, 10, 4.0 },
        { "Red County", -276.0, -1024.0, 2997.0, 694.0, 150, 20, 4.0 },
        { "Bone County", -1848.0, 565.0, 1061.0, 2956.0, BR_MAX_PICKUPS, BR_MAX_VEHICLES, 6.0 },
        { "Flint County", -2988.0, -2988.5, 170.0, -634.5, BR_MAX_PICKUPS, BR_MAX_VEHICLES, 6.0 }
    }
;

static stock
    // lobby data & info
    br_lobbyData                    [ BR_MAX_LOBBIES ] [ E_BR_LOBBY_DATA ],
    br_lobbyPickupData              [ BR_MAX_LOBBIES ] [ BR_MAX_PICKUPS ] [ E_BR_PICKUP_DATA ],
    br_lobbyAirdropData             [ BR_MAX_LOBBIES ] [ BR_MAX_AIRDROPS ] [ E_BR_AIRDROP_DATA ],
    //br_wallBorderObjectUp           [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    //br_wallBorderObjectDown         [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    //br_wallBorderObjectLeft         [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    //br_wallBorderObjectRight        [ BR_MAX_LOBBIES ] [ 4 ] [ 4 ],
    Iterator: battleroyale          < BR_MAX_LOBBIES >,
    Iterator: battleroyaleplayers   < BR_MAX_LOBBIES, MAX_PLAYERS >,

    // player related
    p_battleRoyaleLobby                     [ MAX_PLAYERS ] = { BR_INVALID_LOBBY, ... },
    E_BR_LOBBY_STATUS: p_battleRoyaleStatus [ MAX_PLAYERS ],
    p_battleRoyaleJetNoiseTick              [ MAX_PLAYERS ],
    bool: p_waitingForRespawn               [ MAX_PLAYERS char ],
    bool: p_battleRoyaleSpawned             [ MAX_PLAYERS char ],

    // global related
    g_battleRoyaleStadiumCP         = -1
;

/* ** Hooks ** */
hook OnScriptInit( )
{
    // objects
    BattleRoyale_InitLobbyObjects( );

    // checkpoint
    g_battleRoyaleStadiumCP = CreateDynamicCP( BR_CHECKPOINT_POS[ 0 ], BR_CHECKPOINT_POS[ 1 ], BR_CHECKPOINT_POS[ 2 ], 1.0, 0 );
	CreateDynamic3DTextLabel( "[BATTLE ROYALE]", COLOR_GOLD, BR_CHECKPOINT_POS[ 0 ], BR_CHECKPOINT_POS[ 1 ], BR_CHECKPOINT_POS[ 2 ], 20.0 );
	CreateDynamicMapIcon( BR_CHECKPOINT_POS[ 0 ], BR_CHECKPOINT_POS[ 1 ], BR_CHECKPOINT_POS[ 2 ], 33, 0, -1, -1, -1, 750.0 );
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

hook OnDynamicObjectMoved( objectid )
{
    foreach ( new lobbyid : battleroyale )
    {
        for ( new a = 0; a < BR_MAX_AIRDROPS; a ++ )
        {
            if ( br_lobbyAirdropData[ lobbyid ] [ a ] [ E_OBJECT ] == objectid )
            {
                new Float: X, Float: Y, Float: Z;

                // create pickup
                if ( GetDynamicObjectPos( objectid, X, Y, Z ) ) {
                    br_lobbyAirdropData[ lobbyid ] [ a ] [ E_PICKUP ] = CreateDynamicPickup( 19300, 1, X, Y, Z - 7.5, .worldid = BR_GetWorld( lobbyid ) );
                }

                // update for the players in lobby
                foreach ( new playerid : battleroyaleplayers< lobbyid > ) {
                    Streamer_Update( playerid, STREAMER_TYPE_OBJECT );
                }
                return 1;
            }
        }
    }
    return 1;
}

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( BR_IsValidLobby( lobbyid ) )
    {
        for ( new a = 0; a < BR_MAX_AIRDROPS; a ++ )
        {
            if ( br_lobbyAirdropData[ lobbyid ] [ a ] [ E_PICKUP ] == pickupid )
            {
                // set player health and armour
                PlayerPlaySound( playerid, 1150, 0.0, 0.0, 0.0 );
                SetPlayerHealth( playerid, 100.0 );
                SetPlayerArmour( playerid, 100.0 );

                // destroy the entities
                DestroyDynamicMapIcon( br_lobbyAirdropData[ lobbyid ] [ a ] [ E_MAP_ICON ] );
                br_lobbyAirdropData[ lobbyid ] [ a ] [ E_MAP_ICON ] = -1;

                DestroyDynamicPickup( br_lobbyAirdropData[ lobbyid ] [ a ] [ E_PICKUP ] );
                br_lobbyAirdropData[ lobbyid ] [ a ] [ E_PICKUP ] = -1;

                DestroyDynamicObject( br_lobbyAirdropData[ lobbyid ] [ a ] [ E_OBJECT ] );
                br_lobbyAirdropData[ lobbyid ] [ a ] [ E_OBJECT ] = -1;
                return 1;
            }
        }

        // pickup noise
        for ( new i = 0; i < sizeof ( br_lobbyPickupData [ ] ); i ++ ) if ( br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] != -1 )
        {
            if ( br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] == pickupid )
            {
			    PlayerPlaySound( playerid, 1150, 0.0, 0.0, 0.0 );
                GivePlayerWeapon( playerid, br_lobbyPickupData[ lobbyid ] [ i ] [ E_WEAPON_ID ], RandomEx( 20, 100 ) );
                DestroyDynamicPickup( br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] );
                br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] = -1;
                return 1;
            }
        }
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
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( BR_IsValidLobby( lobbyid ) )
    {
        new
            remaining = Iter_Count( battleroyaleplayers< lobbyid > ) - 1;

        // drop player weapons
    #if defined CreateWeaponPickup
        if ( remaining > 1 )
        {
            new Float: X, Float: Y, Float: Z;
            new expire_time = GetServerTime( ) + 180;

            GetPlayerPos( playerid, X, Y, Z );

            for ( new slotid = 0; slotid < 13; slotid++ )
            {
                new
                    weaponid,
                    ammo;

                GetPlayerWeaponData( playerid, slotid, weaponid, ammo );

                // check valid parameters and shit
                if ( weaponid != 0 && 1 < ammo < 5000 && ! IsWeaponBanned( weaponid ) ) {
                    CreateWeaponPickup( weaponid, ammo, slotid, X + fRandomEx( 0.5, 3.0 ), Y + fRandomEx( 0.5, 3.0 ), Z, expire_time, GetPlayerVirtualWorld( playerid ) );
                }
            }
        }
    #endif

        // alert lobby
        if ( IsPlayerConnected( killerid ) ) {
            BattleRoyale_SendMessage( lobbyid, "%s(%d) has been killed by %s(%d)'s %s, %d player%s remaining!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( killerid ), killerid, ReturnWeaponName( reason ), remaining, remaining == 1 ? ( "" ) : ( "s" ) );
        } else {
            BattleRoyale_SendMessage( lobbyid, "%s(%d) has been killed, %d player%s remaining!", ReturnPlayerName( playerid ), playerid, remaining, remaining == 1 ? ( "" ) : ( "s" ) );
        }
		SendDeathMessage( killerid, playerid, reason );
        BattleRoyale_RemovePlayer( playerid, true );
        return Y_HOOKS_BREAK_RETURN_1;
    }
    return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
    if ( checkpointid == g_battleRoyaleStadiumCP )
    {
        if ( GetPlayerClass( playerid ) != CLASS_CIVILIAN ) {
            return SendError( playerid, "You must be a civilian to use this feature." );
        }
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

            if ( GetDynamicObjectPos( br_lobbyData[ lobbyid ] [ E_PLANE ], X, Y, Z ) )
            {
                ResetPlayerWeapons( playerid );
                GivePlayerWeapon( playerid, 46, 1 ); // parachute

                SetPlayerPos( playerid, X, Y, Z - 2.0 );
                SetPlayerVirtualWorld( playerid, BR_GetWorld( lobbyid ) );

                ResetPlayerPassiveMode( playerid, true );
                DisablePlayerSpawnProtection( playerid, .default_health = br_lobbyData[ lobbyid ] [ E_HEALTH ] );

                SetPlayerHealth( playerid, br_lobbyData[ lobbyid ] [ E_HEALTH ] );
                SetPlayerArmour( playerid, br_lobbyData[ lobbyid ] [ E_ARMOUR ] );

                BattleRoyale_ShowGangZone( playerid, lobbyid );

                p_battleRoyaleSpawned{ playerid } = true;
                return Y_HOOKS_BREAK_RETURN_1;
            }
            else
            {
                // remove player from bugged lobby
                BattleRoyale_RemovePlayer( playerid, true );
                BattleRoyale_RespawnPlayer( playerid );
                return Y_HOOKS_BREAK_RETURN_1;
            }
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
        if ( ! listitem )
        {
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

            new
                players = Iter_Count( battleroyaleplayers< lobbyid >, playerid );

            if ( players >= BR_MAX_PLAYERS ) {
                return SendError( playerid, "This lobby is currently full." );
            }

            GivePlayerCash( playerid, -10000 );
            br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] += 10000;

            BattleRoyale_JoinLobby( playerid, lobbyid );
            BattleRoyale_SendMessageAll( "%s(%d) has created a Battle Royale lobby!", ReturnPlayerName( playerid ), playerid );

            return BattleRoyale_EditLobby( playerid, lobbyid );
        }
        else
        {
            new
                x = 0;

            // check if the player selected an existing lobby
            foreach ( new l : battleroyale )
            {
                //printf ( "[BR DEBUG] %d : LINE 305", GetTickCount( ) );
                if ( x == listitem - 1 )
                {
                    // status must be in a waiting state
                    if ( br_lobbyData[ l ] [ E_STATUS ] != E_STATUS_WAITING )
                    {
                        return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "You cannot join this lobby at the moment." );
                    }

                    // check if the count is under the limit
                    if ( Iter_Count( battleroyaleplayers< l > ) >= br_lobbyData[ l ] [ E_LIMIT ] )
                    {
                        return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "This lobby has reached its maximum player count." );
                    }

                    // cannot join without cac
                    if ( br_lobbyData[ l ] [ E_CAC_ONLY ] && ! IsPlayerUsingSampAC( playerid ) )
                    {
                        return BattleRoyale_ShowLobbies( playerid ), SendError( playerid, "This lobby requires you to run an anti-cheat to play." );
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
                x ++;
            }
            return 1;
        }
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

        if ( listitem == 2 ) // select an area
        {
            return BattleRoyale_EditArea( playerid );
        }
        else if ( listitem == 6 ) // select walking weapon mode
        {
            br_lobbyData[ lobbyid ] [ E_WALK_WEP ] = ! br_lobbyData[ lobbyid ] [ E_WALK_WEP ];
            BattleRoyale_SendMessage( lobbyid, "%s has set allow running weapons to %s.", ReturnPlayerName( playerid ), bool_to_string( ! br_lobbyData[ lobbyid ] [ E_WALK_WEP ] ) );
            return BattleRoyale_EditLobby( playerid, lobbyid );
        }
        else if ( listitem == 7 ) // select cac mode
        {
            if ( IsPlayerUsingSampAC( playerid ) ) {
                br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] = ! br_lobbyData[ lobbyid ] [ E_CAC_ONLY ];
                BattleRoyale_SendMessage( lobbyid, "%s has set CAC mode to %s.", ReturnPlayerName( playerid ), bool_to_string( br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] ) );
            } else {
                SendError( playerid, "You must have SA-MP CAC activated in order to enable this option." );
            }
            return BattleRoyale_EditLobby( playerid, lobbyid );
        }
        else if ( listitem == 8 ) // start lobby option
        {
            if ( Iter_Count( battleroyaleplayers< lobbyid > ) < 2 ) {
                SendError( playerid, "You need at least 2 players in your lobby to start this match." );
            } else {
                if ( ! BattleRoyale_StartGame( lobbyid ) ) {
                    SendError( playerid, "This lobby has already started." );
                }
                return 1;
            }
            return BattleRoyale_EditLobby( playerid, lobbyid );
        }
        else
        {
            SetPVarInt( playerid, "editing_field", listitem );
            return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY_EDIT_ENTRY, DIALOG_STYLE_INPUT, ""COL_WHITE"Battle Royale", ""COL_WHITE"Please enter a value for this field:", "Submit", "Back" );
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
        BattleRoyale_SendMessage( lobbyid, "%s has set the area to %s.", ReturnPlayerName( playerid ), br_areaData[ listitem ] [ E_NAME ] );
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
                else if ( ! ( 3 <= strlen( name ) < 24 ) ) SendError( playerid, "You must enter a name between 3 and 24 characters." );
                else
                {
                    BattleRoyale_SendMessage( lobbyid, "%s has set the lobby name to %s.", ReturnPlayerName( playerid ), name );
                    strcpy( br_lobbyData[ lobbyid ] [ E_NAME ], name );
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // limit
            case 1:
            {
                new
                    limit;

                if ( sscanf( inputtext, "d", limit ) ) SendError( playerid, "You must enter a valid limit." );
                else if ( ! ( 2 <= limit < BR_MAX_PLAYERS ) ) SendError( playerid, "You must enter a limit between 2 and %d players.", BR_MAX_PLAYERS );
                else
                {
                    BattleRoyale_SendMessage( lobbyid, "%s has set the lobby player limit to %d.", ReturnPlayerName( playerid ), limit );
                    br_lobbyData[ lobbyid ] [ E_LIMIT ] = limit;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // entry_fee
            case 3:
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
                    BattleRoyale_SendMessage( lobbyid, "%s has set a lobby entry fee to %s.", ReturnPlayerName( playerid ), cash_format( entry_fee ) );
                    br_lobbyData[ lobbyid ] [ E_ENTRY_FEE ] = entry_fee;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // health
            case 4:
            {
                new
                    Float: health;

                if ( sscanf( inputtext, "f", health ) ) SendError( playerid, "You must enter a valid health value." );
                else if ( ! ( 1.0 <= health <= 100.0 ) ) SendError( playerid, "You must enter a health value between 1 and 100." );
                else
                {
                    BattleRoyale_SendMessage( lobbyid, "%s has set a lobby spawn health to %0.2f%%.", ReturnPlayerName( playerid ), health );
                    br_lobbyData[ lobbyid ] [ E_HEALTH ] = health;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }

            // armour
            case 5:
            {
                new
                    Float: armour;

                if ( sscanf( inputtext, "f", armour ) ) SendError( playerid, "You must enter a valid armour value." );
                else if ( ! ( 0.0 <= armour <= 100.0 ) ) SendError( playerid, "You must enter a armour value between 0 and 100." );
                else
                {
                    BattleRoyale_SendMessage( lobbyid, "%s has set a lobby spawn health to %0.2f%%.", ReturnPlayerName( playerid ), armour );
                    br_lobbyData[ lobbyid ] [ E_ARMOUR ] = armour;
                    return BattleRoyale_EditLobby( playerid, lobbyid );
                }
            }
        }
        return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY_EDIT_ENTRY, DIALOG_STYLE_INPUT, ""COL_WHITE"Battle Royale", ""COL_WHITE"Please enter a value for this field:", "Submit", "Back" );
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
        #if !defined DEBUG_MODE
        if ( Iter_Count( battleroyaleplayers< lobbyid > ) < 2 ) {
            return SendError( playerid, "You need at least 2 players in your lobby to start this match." );
        }
        #endif

        if ( ! BR_IsHost( playerid, lobbyid ) ) {
            return SendError( playerid, "You cannot edit this lobby as you are no longer the host." );
        }

        // attempt to start the game
        if ( ! BattleRoyale_StartGame( lobbyid ) ) {
            SendError( playerid, "This lobby has already started." );
        }
        return 1;
    }
    else if ( strmatch ( params, "leave" ) )
    {
        if ( ! p_battleRoyaleSpawned{ playerid } && br_lobbyData[ lobbyid ] [ E_STATUS ] == E_STATUS_STARTED ) {
            return SendError( playerid, "You must be spawned before you can leave the match." );
        }
        BattleRoyale_SendMessage( lobbyid, "%s(%d) has disconnected from the match!", ReturnPlayerName( playerid ), playerid );
        BattleRoyale_RemovePlayer( playerid, true );
        SpawnPlayer( playerid );
        return 1;
    }
	else if ( ! strcmp( params, "donate", false, 6 ) )
    {
        new
            amount;

        if ( sscanf( params[ 7 ], "d", amount ) ) return SendUsage( playerid, "/br donate [AMOUNT]" );
        else if ( amount < 1 ) return SendError( playerid, "You cannot donate less than $1 to this lobby." );
        else if ( amount > GetPlayerCash( playerid ) ) return SendError( playerid, "You do not have this much money." );
        else
        {
            GivePlayerCash( playerid, -amount );
            br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] += amount;

            if ( amount >= 50000 ) {
                BattleRoyale_SendMessageAll( ""COL_GREY"%s(%d) has contributed %s to %s (total %s).", ReturnPlayerName( playerid ), playerid, cash_format( amount ), br_lobbyData[ lobbyid ] [ E_NAME ], cash_format( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] ) );
            } else {
                BattleRoyale_SendMessage( lobbyid, "%s(%d) has contributed %s to the lobby (total %s).", ReturnPlayerName( playerid ), playerid, cash_format( amount ), cash_format( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] ) );
            }
        }
        return 1;
    }
    return SendUsage( playerid, "/battleroyale [DONATE/EDIT/START/LEAVE]" );
}

/* ** Functions ** */
static stock BattleRoyale_CreateLobby( playerid )
{
    new
        lobbyid = Iter_Free( battleroyale );

    if ( lobbyid != ITER_NONE )
    {
        strcpy( br_lobbyData[ lobbyid ] [ E_NAME ], "Battle Royale Lobby" );

        br_lobbyData[ lobbyid ] [ E_LIMIT ] = 12;
        br_lobbyData[ lobbyid ] [ E_AREA_ID ] = 0;
        br_lobbyData[ lobbyid ] [ E_ENTRY_FEE ] = 10000;
        br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] = 0;
        br_lobbyData[ lobbyid ] [ E_HOST ] = playerid;
        br_lobbyData[ lobbyid ] [ E_STATUS ] = E_STATUS_WAITING;

        br_lobbyData[ lobbyid ] [ E_PLANE ] = -1;
        br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] = -1;
        br_lobbyData[ lobbyid ] [ E_GAME_TIMER ] = -1;

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
        "Player Limit\t"COL_GREY"%d\n" \
        "Area\t"COL_GREY"%s\n" \
        "Entry Fee\t"COL_GREEN"%s\n" \
        "Health\t"COL_GREY"%0.2f%%\n" \
        "Armour\t"COL_GREY"%0.2f%%\n" \
        "Allow Running Weapons\t%s\n" \
        "CAC Only\t%s\n" \
        ""COL_GREEN"Start Match\t"COL_GREEN">>>",
        br_lobbyData[ lobbyid ] [ E_NAME ],
        br_lobbyData[ lobbyid ] [ E_LIMIT ],
        br_areaData[ br_lobbyData[ lobbyid ] [ E_AREA_ID ] ] [ E_NAME ],
        cash_format( br_lobbyData[ lobbyid ] [ E_ENTRY_FEE ] ),
        br_lobbyData[ lobbyid ] [ E_HEALTH ],
        br_lobbyData[ lobbyid ] [ E_ARMOUR ],
        ! br_lobbyData[ lobbyid ] [ E_WALK_WEP ] ? ( COL_GREEN # "YES" ) : ( COL_RED # "NO" ),
        br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] ? ( COL_GREEN # "YES" ) : ( COL_RED # "NO" )
    );
    return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY_EDIT, DIALOG_STYLE_TABLIST, ""COL_WHITE"Battle Royale", szLargeString, "Edit", "Close" );
}

static stock BattleRoyale_EditArea( playerid )
{
    static
        areas[ 512 ];

    if ( areas[ 0 ] == '\0' ) {
        areas = ""COL_WHITE"Area\t"COL_WHITE"Pickups\t"COL_WHITE"Vehicles\n";
        for ( new i = 0; i < sizeof( br_areaData ); i ++ ) {
            format( areas, sizeof( areas ), "%s%s\t%d\t%d\n", areas, br_areaData[ i ] [ E_NAME ], br_areaData[ i ] [ E_MAX_PICKUPS ], br_areaData[ i ] [ E_MAX_VEHICLES ] );
        }
    }
    return ShowPlayerDialog( playerid, DIALOG_BR_SELECT_AREA, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Battle Royale", areas, "Select", "Back" );
}

static stock BattleRoyale_JoinLobby( playerid, lobbyid )
{
    // set lobby id
    p_battleRoyaleLobby[ playerid ] = lobbyid;
    Iter_Add( battleroyaleplayers< lobbyid >, playerid );

    // alert
    BattleRoyale_SendMessage( lobbyid, "%s has joined %s "COL_ORANGE"[%d/%d]"COL_GREEN" (%s POOL)", ReturnPlayerName( playerid ), br_lobbyData[ lobbyid ] [ E_NAME ], Iter_Count( battleroyaleplayers< lobbyid > ), br_lobbyData[ lobbyid ] [ E_LIMIT ], cash_format( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] ) );

    // set player position in an island
    SetPlayerPos( playerid, BR_ISLAND_POS[ 0 ], BR_ISLAND_POS[ 1 ], BR_ISLAND_POS[ 2 ] + 1.0 );
    SetPlayerVirtualWorld( playerid, BR_GetWorld( lobbyid ) );
    pauseToLoad( playerid );

    // make player invincible
    ResetPlayerWeapons( playerid );
    SetPlayerHealth( playerid, 99999.00 );

    // check if lobby is full
    BattleRoyale_CheckPlayers( lobbyid );
    return 1;
}

static stock BattleRoyale_ShowLobbies( playerid )
{
    // set the headers
    szLargeString = ""COL_WHITE"Lobby Name\t"COL_WHITE"Host\t"COL_WHITE"Players\t"COL_WHITE"Entry Fee\n";

    // make final option to create lobby
    format( szLargeString, sizeof( szLargeString ), "%s"COL_PURPLE"Create Lobby\t \t"COL_PURPLE"$10,000\t"COL_PURPLE">>>\n", szLargeString );

    // format dialog
    foreach ( new l : battleroyale )
    {
        //printf ( "[BR DEBUG] %d : LINE 686", GetTickCount( ) );
        format(
            szLargeString, sizeof( szLargeString ),
            "%s%s%s\t%s%s\t%s%d / %d\t%s%s\n",
            szLargeString,
            br_lobbyData[ l ] [ E_STATUS ] == E_STATUS_STARTED ? ( COL_RED ) : ( COL_WHITE ),
            br_lobbyData[ l ] [ E_NAME ],
            br_lobbyData[ l ] [ E_STATUS ] == E_STATUS_STARTED ? ( COL_RED ) : ( COL_WHITE ),
            IsPlayerConnected( br_lobbyData[ l ] [ E_HOST ] ) ? ( ReturnPlayerName( br_lobbyData[ l ] [ E_HOST ] ) ) : ( "N/A" ),
            br_lobbyData[ l ] [ E_STATUS ] == E_STATUS_STARTED ? ( COL_RED ) : ( COL_WHITE ),
            Iter_Count( battleroyaleplayers< l > ),
            br_lobbyData[ l ] [ E_LIMIT ],
            br_lobbyData[ l ] [ E_STATUS ] == E_STATUS_STARTED ? ( COL_RED ) : ( COL_WHITE ),
            cash_format( br_lobbyData[ l ] [ E_ENTRY_FEE ] )
        );
    }

    return ShowPlayerDialog( playerid, DIALOG_BR_LOBBY, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Battle Royale", szLargeString, "Select", "Close" );
}

static stock BattleRoyale_RespawnPlayer( playerid )
{
    // set position to the entrance of game
    SetPlayerPos( playerid, BR_CHECKPOINT_POS[ 0 ], BR_CHECKPOINT_POS[ 1 ], BR_CHECKPOINT_POS[ 2 ] );
    SetPlayerVirtualWorld( playerid, 0 );
    SetPlayerInterior( playerid, 0 );
    SetPlayerPassiveMode( playerid );

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
        p_battleRoyaleSpawned{ playerid } = false;

        // toggle checkpoints etc if connected
        if ( IsPlayerConnected( playerid ) ) {
            Streamer_ToggleAllItems( playerid, STREAMER_TYPE_CP, true );
            Streamer_ToggleAllItems( playerid, STREAMER_TYPE_MAP_ICON, true );
            Streamer_ToggleAllItems( playerid, STREAMER_TYPE_3D_TEXT_LABEL, true );
            BattleRoyale_PlayerTags( playerid, lobbyid, true );
        }

        // perform neccessary operations/checks on the lobby
        if ( remove_from_iterator )
        {
            Iter_SafeRemove( battleroyaleplayers< lobbyid >, playerid, playerid );
            BattleRoyale_CheckPlayers( lobbyid );
        }
    }
    return lobbyid;
}

hook OnPlayerStreamIn( playerid, forplayerid )
{
    new
        lobbyid = p_battleRoyaleLobby[ playerid ];

    if ( lobbyid != BR_INVALID_LOBBY && forplayerid != INVALID_PLAYER_ID )
    {
        ShowPlayerNameTagForPlayer( playerid, forplayerid, false );
        SetPlayerMarkerForPlayer( playerid, forplayerid, setAlpha( GetPlayerColor( forplayerid ), 0x00 ) );
    }
    return 1;
}

static stock BattleRoyale_EndGame( lobbyid )
{
    new fees_incurred = floatround( float( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] ) * 0.2 );

    new prize = floatround( float( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] - fees_incurred ) / float( Iter_Count( battleroyaleplayers< lobbyid > ) ), floatround_ceil );

    new Float: distribution = floatround( float( prize ) / float( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] - fees_incurred ) * 100.0 );

    StockMarket_UpdateEarnings( E_STOCK_BATTLE_ROYAL_CENTER, fees_incurred, 0.5 );

    foreach ( new playerid : battleroyaleplayers< lobbyid > )
    {
        //printf ( "[BR DEBUG] %d : LINE 772", GetTickCount( ) );
        BattleRoyale_SendMessageAll( "%s(%d) has won %s (%0.0f%s) out of the %s prize pool.", ReturnPlayerName( playerid ), playerid, cash_format( prize ), distribution, "%%", br_lobbyData[ lobbyid ] [ E_NAME ] );
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
        total_players = Iter_Count( battleroyaleplayers< lobbyid > );

    // check if there is no more players
    if ( total_players <= 1 && br_lobbyData[ lobbyid ] [ E_STATUS ] == E_STATUS_STARTED )
    {
        print("Too few players, stopping game.");
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
    if ( br_lobbyData[ lobbyid ] [ E_STATUS ] == E_STATUS_STARTED ) {
        return 0;
    }

    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];

    br_lobbyData[ lobbyid ] [ E_STATUS ] = E_STATUS_STARTED;

    // plane movement
    br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] = 0.0;

    DestroyDynamicObject( br_lobbyData[ lobbyid ] [ E_PLANE ] );
    br_lobbyData[ lobbyid ] [ E_PLANE ] = CreateDynamicObject( 14553, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = -1, .interiorid = -1 );

    KillTimer( br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] );
    br_lobbyData[ lobbyid ] [ E_PLANE_TIMER ] = SetTimerEx( "BattleRoyale_PlaneMove", BR_PLANE_UPDATE_RATE, true, "d", lobbyid );

    // set the area variables
    br_lobbyData[ lobbyid ] [ E_B_MIN_X ] = br_areaData[ areaid ] [ E_MIN_X ];
    br_lobbyData[ lobbyid ] [ E_B_MAX_X ] = br_areaData[ areaid ] [ E_MAX_X ];
    br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] = br_areaData[ areaid ] [ E_MIN_Y ];
    br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] = br_areaData[ areaid ] [ E_MAX_Y ];

    // generate entities randomly
    BattleRoyale_GenerateEntities( lobbyid, br_areaData[ areaid ] [ E_MAX_PICKUPS ], br_areaData[ areaid ] [ E_MAX_VEHICLES ] );

    // destroy border walls
    BattleRoyale_DestroyBorder( lobbyid );
    BattleRoyale_DestroyAirdrops( lobbyid );

    // create border walls
    BattleRoyale_CreateBorder( lobbyid );

    // game timer
    KillTimer( br_lobbyData[ lobbyid ] [ E_GAME_TIMER ] );
    br_lobbyData[ lobbyid ] [ E_GAME_TIMER ] = SetTimerEx( "BattleRoyale_GameUpdate", 2500, true, "d", lobbyid);

    // load the player into the area
    foreach ( new playerid : battleroyaleplayers< lobbyid > )
    {
        // remove non-cac players in a cac lobby
        if ( br_lobbyData[ lobbyid ] [ E_CAC_ONLY ] && ! IsPlayerUsingSampAC( playerid ) )
        {
            SetPlayerHealth( playerid, -1 );
            SendServerMessage( playerid, "You have been removed from the match for disabling SA-MP AC." );
            continue;
        }

        // respawn player
        p_battleRoyaleSpawned{ playerid } = false;
        p_battleRoyaleStatus[ playerid ] = E_STATUS_WAITING;
        TogglePlayerSpectating( playerid, true );

        // hide default cnr things
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_CP, false );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_MAP_ICON, false );
        Streamer_ToggleAllItems( playerid, STREAMER_TYPE_3D_TEXT_LABEL, false );
        BattleRoyale_PlayerTags( playerid, lobbyid, false );
        Streamer_Update( playerid );

        // show the battle royal playable zone
        BattleRoyale_ShowGangZone( playerid, lobbyid );

        // show controls
        ShowPlayerHelpDialog( playerid, 0, "~y~~h~~k~~PED_JUMPING~~w~ - Jump Out Of Plane" );
    }

    // alert lobby
    BattleRoyale_SendMessage( lobbyid, "The match has been started. Winner takes %s!", cash_format( floatround( float( br_lobbyData[ lobbyid ] [ E_PRIZE_POOL ] ) * 0.8 ) ) );
    return 1;
}

function BattleRoyale_GameUpdate( lobbyid )
{
    foreach ( new x : battleroyaleplayers< lobbyid > )
    {
        // printf ( "[BR DEBUG] %d : LINE 878", GetTickCount( ) );

        // hide markers / etc
        foreach ( new y : battleroyaleplayers< lobbyid > )
        {
            //printf ( "[BR DEBUG] %d : LINE 872", GetTickCount( ) );
            ShowPlayerNameTagForPlayer( x, y, false );
            SetPlayerMarkerForPlayer( x, y, setAlpha( GetPlayerColor( y ), 0x00 ) );
        }

        // hurt players outside the zone
        if ( p_battleRoyaleSpawned{ x } && ! IsPlayerInArea( x, br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ], br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] ) )
        {
            // force kill afk player out of zone
            if ( IsPlayerAFK( x ) )
            {
                SetPlayerHealth( x, -1 );
            }
            else
            {
                new
                    Float: health;

                GetPlayerHealth( x, health );

                GameTextForPlayer( x, "~r~STAY IN THE AREA!", 5000, 3 );
                SetPlayerHealth( x, health - 10.0 );
            }
        }
    }

    // prevent zone shrinking and bombing while the plane is rotating
    if ( br_lobbyData[ lobbyid ] [ E_PLANE ] != -1 && br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] <= 180.0 )
    {
        return 1;
    }

    // decrease zone size
    new Float: radius_x = ( VectorSize( br_lobbyData[ lobbyid ] [ E_B_MIN_X ] - br_lobbyData[ lobbyid ] [ E_B_MAX_X ], 0.0, 0.0 ) ) / 2.0;
    new Float: radius_y = ( VectorSize( 0.0, br_lobbyData[ lobbyid ] [ E_B_MIN_Y ] - br_lobbyData[ lobbyid ] [ E_B_MAX_Y ], 0.0 ) ) / 2.0;

    new Float: BR_UNITS_PER_SECOND_SHRINK = br_areaData[ br_lobbyData[ lobbyid ] [ E_AREA_ID ] ] [ E_SHRINK_SPEED ];

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
        print( "Area too small, ending game." );
        return BattleRoyale_EndGame( lobbyid );
    }

    new
        tick_count = GetServerTime( );

    // rocket
    if ( br_lobbyData[ lobbyid ] [ E_BOMB_TICK ] < tick_count )
    {
        new Float: X = fRandomEx( br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ] );
        new Float: Y = fRandomEx( br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] );
        new Float: Z;

        MapAndreas_FindZ_For2DCoord( X, Y, Z );

        new rocket = CreateDynamicObject( 3786, X, Y, Z + 250.0, 5.0, -90.0, 0.0 );
        new flare = CreateDynamicObject( 18728, X, Y, Z - 1.0, 0.0, 0.0, 0.0 );
        new move_speed = MoveDynamicObject( rocket, X, Y, Z, 25.0 );

        foreach ( new playerid : battleroyaleplayers< lobbyid > ) {
            //printf ( "[BR DEBUG] %d : LINE 951", GetTickCount( ) );
            PlayerPlaySound( playerid, 14800, X, Y, Z );
            Streamer_Update( playerid, STREAMER_TYPE_OBJECT );
        }

        br_lobbyData[ lobbyid ] [ E_BOMB_TICK ] = tick_count + 10;
        SetTimerEx( "BattleRoyale_ExplodeBomb", move_speed, false, "dddfff", lobbyid, rocket, flare, X, Y, Z );
    }

    // airdrop
    if ( br_lobbyData[ lobbyid ] [ E_AIRDROP_TICK ] < tick_count )
    {
        BattleRoyale_CreateAirdrop( lobbyid );
        br_lobbyData[ lobbyid ] [ E_AIRDROP_TICK ] = tick_count + 60;
    }
    return 1;
}

function BattleRoyale_ExplodeBomb( lobbyid, rocketid, flareid, Float: X, Float: Y, Float: Z )
{
	// destroy the rocket after it is moved
	DestroyDynamicObject( rocketid );
	DestroyDynamicObject( flareid );

    // create explosion
    foreach ( new playerid : battleroyaleplayers< lobbyid > )
    {
        //printf ( "[BR DEBUG] %d : LINE 971", GetTickCount( ) );
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
    if ( ( br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] += 0.003 * float( BR_PLANE_UPDATE_RATE ) ) >= 360.0 )  // 360.00 / 60000.0 * rate
    {
        new
            unready_players = 0;

        foreach ( new playerid : battleroyaleplayers< lobbyid > )
        {
            // force throw out of plane inactive players
            if ( p_battleRoyaleStatus[ playerid ] != E_STATUS_STARTED )
            {
                BattleRoyale_ThrowFromPlane( playerid );
                SendServerMessage( playerid, "You have been thrown out of your plane due to a lack of decision." );
            }

            // started, but not spawned ... keep the plane going a bit longer
            if ( ! p_battleRoyaleSpawned{ playerid } )
            {
                unready_players ++;
            }
        }

        // ensures that the plane object is kept while players are thrown out (force after 2nd rotation)
        if ( ! unready_players || br_lobbyData[ lobbyid ] [ E_PLANE_ROTATION ] >= 720.0 )
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

    new Float: rotation = atan2( plane_ahead_y - plane_y, plane_ahead_x - plane_x ) + 90.0;

    SetDynamicObjectRot( br_lobbyData[ lobbyid ] [ E_PLANE ], 0.0, 0.0, rotation );

    // new speed = MoveDynamicObject( br_lobbyData[ lobbyid ] [ E_PLANE ], plane_x, plane_y, BR_MIN_HEIGHT, float( BR_PLANE_UPDATE_RATE ) / 1000.0, .rz = rotation );
    // printf("%d", speed);

    foreach ( new playerid : battleroyaleplayers< lobbyid > )
    {
        //printf ( "[BR DEBUG] %d : LINE 1030", GetTickCount( ) );
        if ( p_battleRoyaleStatus[ playerid ] == E_STATUS_WAITING )
        {
            SetPlayerCameraPos( playerid, plane_x, plane_y, BR_MIN_HEIGHT + BR_MIN_CAMERA_HEIGHT );
            SetPlayerCameraLookAt( playerid, plane_x, plane_y, BR_MIN_HEIGHT );

            new
                tick_count = GetTickCount( );

            if ( tick_count > p_battleRoyaleJetNoiseTick[ playerid ] ) {
                PlayerPlaySound( playerid, 14400, plane_x, plane_y, BR_MIN_HEIGHT + BR_MIN_CAMERA_HEIGHT - 20.0 );
                p_battleRoyaleJetNoiseTick[ playerid ] = tick_count + 250;
            }
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
    Iter_Clear( battleroyaleplayers< lobbyid > );

    BattleRoyale_DestroyBorder( lobbyid );
    BattleRoyale_DestroyEntities( lobbyid );
    BattleRoyale_DestroyAirdrops( lobbyid );

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
    #pragma unused sides_rate
    #pragma unused top_rate

    new temporary_gangzone[ 4 ];

    // redraw gangzones
    temporary_gangzone[ 0 ] = GangZoneCreate( br_lobbyData[ lobbyid ] [ E_B_MAX_X ],-3000, 3000, 3000, .bordersize = 0.0, .numbersize = 0.0 );
    temporary_gangzone[ 1 ] = GangZoneCreate( -3000, -3000, br_lobbyData[ lobbyid ] [ E_B_MIN_X ], 3000, .bordersize = 0.0, .numbersize = 0.0 );
    temporary_gangzone[ 2 ] = GangZoneCreate( br_lobbyData[ lobbyid ] [ E_B_MIN_X ], -3000, br_lobbyData[ lobbyid ] [ E_B_MAX_X ], br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], .bordersize = 0.0, .numbersize = 0.0 );
    temporary_gangzone[ 3 ] = GangZoneCreate( br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ], 3000, .bordersize = 0.0, .numbersize = 0.0 );

    // show the new gangzone
    foreach ( new playerid : battleroyaleplayers< lobbyid > ) {
        //printf ( "[BR DEBUG] %d : LINE 1092", GetTickCount( ) );
        for ( new g = 0; g < sizeof( temporary_gangzone ); g ++ ) {
            //printf ( "[BR DEBUG] %d : LINE 1094", GetTickCount( ) );
            GangZoneShowForPlayer( playerid, temporary_gangzone[ g ], 0x000000FF );
        }
    }

    // delete old gangzone, set the new
    for ( new g = 0; g < 4; g ++ ) {
        GangZoneDestroy( br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ g ] );
        br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ g ] = temporary_gangzone[ g ];
    }

    // move objects
    /*for ( new i = 0; i < sizeof( br_wallBorderObjectUp[ ] ); i ++ )
    {
        for ( new z = 0; z < sizeof( br_wallBorderObjectUp[ ] [ ] ); z ++ )
        {
            // move only the bottom walls
            if ( ! z )
            {
                MoveDynamicObject( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ] + 240.0 * float( i ), br_lobbyData[ lobbyid ] [ E_B_MAX_Y ], 240.0 * float( z ), top_rate );
                MoveDynamicObject( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ] + 240.0 * float( i ), br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], 240.0 * float( z ), top_rate );
                MoveDynamicObject( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), sides_rate );
                MoveDynamicObject( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), sides_rate );
            }
            // just force move top walls with set pos to reduce number of acks sent
            else
            {
                SetDynamicObjectPos( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ] + 240.0 * float( i ), br_lobbyData[ lobbyid ] [ E_B_MAX_Y ], 240.0 * float( z ) );
                SetDynamicObjectPos( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ] + 240.0 * float( i ), br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], 240.0 * float( z ) );
                SetDynamicObjectPos( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ) );
                SetDynamicObjectPos( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ) );
            }
        }
    }*/
}

static stock BattleRoyale_CreateBorder( lobbyid )
{
    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];

    // gang zone
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 0 ] = GangZoneCreate( br_areaData[ areaid ] [ E_MAX_X ],-3000, 3000, 3000, .bordersize = 0.0, .numbersize = 0.0 );
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 1 ] = GangZoneCreate( -3000, -3000, br_areaData[ areaid ] [ E_MIN_X ], 3000, .bordersize = 0.0, .numbersize = 0.0 );
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 2 ] = GangZoneCreate( br_areaData[ areaid ] [ E_MIN_X ], -3000, br_areaData[ areaid ] [ E_MAX_X ], br_areaData[ areaid ] [ E_MIN_Y ], .bordersize = 0.0, .numbersize = 0.0 );
    br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ 3 ] = GangZoneCreate( br_areaData[ areaid ] [ E_MIN_X ], br_areaData[ areaid ] [ E_MAX_Y ], br_areaData[ areaid ] [ E_MAX_X ], 3000, .bordersize = 0.0, .numbersize = 0.0 );

    // walls
    /*for ( new i = 0; i < sizeof( br_wallBorderObjectUp[ ] ); i ++ )
    {
        for ( new z = 0; z < sizeof( br_wallBorderObjectUp[ ] [ ] ); z ++ )
        {
            br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MIN_X ] + 240.0 * float( i ), br_areaData[ areaid ] [ E_MAX_Y ], 240.0 * float( z ), 0.0, -90.0, 90.0, .worldid = BR_GetWorld( lobbyid ) );
            SetDynamicObjectMaterialText( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ], 0, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
            SetDynamicObjectMaterialText( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ], 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );

            br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MIN_X ] + 240.0 * float( i ), br_areaData[ areaid ] [ E_MIN_Y ], 240.0 * float( z ), 0.0, -90.0, 90.0, .worldid = BR_GetWorld( lobbyid ) );
            SetDynamicObjectMaterialText( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ], 0, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
            SetDynamicObjectMaterialText( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ], 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );

            br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MIN_X ], br_areaData[ areaid ] [ E_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), 0.0, -90.0, 0.0, .worldid = BR_GetWorld( lobbyid ) );
            SetDynamicObjectMaterialText( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ], 0, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
            SetDynamicObjectMaterialText( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ], 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );

            br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ] = CreateDynamicObject( 18754, br_areaData[ areaid ] [ E_MAX_X ], br_areaData[ areaid ] [ E_MAX_Y ] - 240.0 * float( i ), 240.0 * float( z ), 0.0, -90.0, 0.0, .worldid = BR_GetWorld( lobbyid ) );
            SetDynamicObjectMaterialText( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ], 0, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
            SetDynamicObjectMaterialText( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ], 1, " ", 140, "Arial", 64, 1, -32256, 0, 1 );
        }
    }*/
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
    /*for ( new i = 0; i < sizeof( br_wallBorderObjectUp[ ] ); i ++ )
    {
        for ( new z = 0; z < sizeof( br_wallBorderObjectUp[ ] [ ] ); z ++ )
        {
            DestroyDynamicObject( br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectUp[ lobbyid ] [ i ] [ z ] = -1;
            DestroyDynamicObject( br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectDown[ lobbyid ] [ i ] [ z ] = -1;
            DestroyDynamicObject( br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectLeft[ lobbyid ] [ i ] [ z ] = -1;
            DestroyDynamicObject( br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ] ), br_wallBorderObjectRight[ lobbyid ] [ i ] [ z ] = -1;
        }
    }*/
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

static stock BattleRoyale_GenerateEntities( lobbyid, max_pickups, max_vehicles )
{
    new areaid = br_lobbyData[ lobbyid ] [ E_AREA_ID ];

    // destroy entities incase they exist
    BattleRoyale_DestroyEntities( lobbyid );

    // generate pickups
    for ( new i = 0; i < BR_MAX_PICKUPS; i ++ )
    {
        if ( i < max_pickups )
        {
            new weaponid = br_lobbyData[ lobbyid ] [ E_WALK_WEP ] ? BR_WALKING_WEAPONS[ random( sizeof( BR_WALKING_WEAPONS ) ) ] : BR_RUNNING_WEAPONS[ random( sizeof( BR_RUNNING_WEAPONS ) ) ];

            new Float: X = fRandomEx( br_areaData[ areaid ] [ E_MIN_X ] + BR_PLANE_RADIUS_FROM_BORDER, br_areaData[ areaid ] [ E_MAX_X ] - BR_PLANE_RADIUS_FROM_BORDER );
            new Float: Y = fRandomEx( br_areaData[ areaid ] [ E_MIN_Y ] + BR_PLANE_RADIUS_FROM_BORDER, br_areaData[ areaid ] [ E_MAX_Y ] - BR_PLANE_RADIUS_FROM_BORDER );
            new Float: Z;

            MapAndreas_FindZ_For2DCoord( X, Y, Z );

            br_lobbyPickupData[ lobbyid ] [ i ] [ E_WEAPON_ID ] = weaponid;
            br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] = CreateDynamicPickup( GetWeaponModel( weaponid ), 1, X, Y, Z + 1.0, .worldid = BR_GetWorld( lobbyid ) );
        }
        else
        {
            br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] = -1;
        }
    }

    // generate random cars
    for ( new c = 0; c < BR_MAX_VEHICLES; c ++ )
    {
        if ( c < max_vehicles )
        {
            new modelid = BR_VEHICLE_MODELS[ random( sizeof( BR_VEHICLE_MODELS ) ) ];

            new Float: X = fRandomEx( br_areaData[ areaid ] [ E_MIN_X ] + BR_PLANE_RADIUS_FROM_BORDER * 5.0, br_areaData[ areaid ] [ E_MAX_X ] - BR_PLANE_RADIUS_FROM_BORDER * 5.0 );
            new Float: Y = fRandomEx( br_areaData[ areaid ] [ E_MIN_Y ] + BR_PLANE_RADIUS_FROM_BORDER * 5.0, br_areaData[ areaid ] [ E_MAX_Y ] - BR_PLANE_RADIUS_FROM_BORDER * 5.0 );
            new Float: Z = 0.0;

            new nodeid = NearestNodeFromPoint( X, Y, Z );
            GetNodePos( nodeid, X, Y, Z );

            br_lobbyData[ lobbyid ] [ E_VEHICLES ] [ c ] = CreateVehicle( modelid, X, Y, Z + 1.5, fRandomEx( 0.0, 360.0 ), -1, -1, 0, 0 );
            SetVehicleVirtualWorld( br_lobbyData[ lobbyid ] [ E_VEHICLES ] [ c ], BR_GetWorld( lobbyid ) );
        }
        else
        {
            br_lobbyData[ lobbyid ] [ E_VEHICLES ] [ c ] = -1;
        }
    }
}

static stock BattleRoyale_DestroyEntities( lobbyid )
{
    for ( new i = 0; i < BR_MAX_PICKUPS; i ++ )
    {
        // destroy pickup
        DestroyDynamicPickup( br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] );
        br_lobbyPickupData[ lobbyid ] [ i ] [ E_PICKUP ] = -1;

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

	foreach ( new i : battleroyaleplayers< lobbyid > ) {
        //printf ( "[BR DEBUG] %d : LINE 1277", GetTickCount( ) );
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock IsPlayerInBattleRoyale( playerid ) {
    return BR_IsValidLobby( p_battleRoyaleLobby[ playerid ] );
}

stock BattleRoyale_PlayerTags( playerid, lobbyid, bool: toggle ) {
    foreach ( new x : battleroyaleplayers< lobbyid > ) {
        //printf ( "[BR DEBUG] %d : LINE 1289", GetTickCount( ) );
        ShowPlayerNameTagForPlayer( playerid, x, toggle );
        if ( toggle ) SetPlayerColorToTeam( x );
        SetPlayerMarkerForPlayer( playerid, x, toggle ? GetPlayerColor( x ) : setAlpha( GetPlayerColor( x ), 0x00 ) );
    }
}

static stock BattleRoyale_ShowGangZone( playerid, lobbyid ) {
    Turf_HideAllGangZones( playerid );
    for ( new g = 0; g < 4; g ++ ) {
        GangZoneShowForPlayer( playerid, br_lobbyData[ lobbyid ] [ E_BORDER_ZONE ] [ g ], 0x000000FF );
    }
}

static stock BattleRoyale_InitLobbyObjects( )
{
    tmpVariable = CreateDynamicObject( 16207, -5022.422851, 1993.284057, -38.799999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 8462, "vgsecoast", "desgrassbrn", -16 );
    SetDynamicObjectMaterial( tmpVariable, 1, 8462, "vgsecoast", "desgrassbrn", -16 );
    SetDynamicObjectMaterial( tmpVariable, 2, 8462, "vgsecoast", "desgrassbrn", -16 );
    SetDynamicObjectMaterial( tmpVariable, 3, 8462, "vgsecoast", "desgrassbrn", -16 );
    CreateDynamicObject( 8493, -4961.316894, 2066.529052, 17.107999, 6.500000, 0.000000, 88.099998, -1, -1, -1 );
    CreateDynamicObject( 683, -4953.866210, 2007.400024, 1.439000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18765, -4958.104980, 2031.545043, 1.881000, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18762, -4958.089843, 2033.555053, 8.461000, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18764, -4958.085937, 2031.555053, 2.331000, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18762, -4960.085937, 2031.555053, 8.463000, 0.000000, 90.000000, 90.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18762, -4958.089843, 2029.545043, 8.461000, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18762, -4956.085937, 2031.555053, 8.463000, 0.000000, 90.000000, 90.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18980, -4955.611816, 2034.012939, -3.549000, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18980, -4960.549804, 2034.083007, -3.549000, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18980, -4955.611816, 2029.119995, -3.549000, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18980, -4960.611816, 2029.119995, -3.549000, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 12911, "sw_farm1", "sw_barnwood4", -16 );
    CreateDynamicObject( 14400, -4957.749023, 2030.637939, 8.503000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 14400, -4957.749023, 2032.668945, 8.503000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 3439, -4962.041992, 2035.514038, 3.288000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 3439, -4962.041992, 2027.522949, 3.288000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 3439, -4954.037109, 2027.522949, 3.288000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 3439, -4954.037109, 2035.510986, 3.288000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4960.604003, 2032.762939, 7.584000, 0.000000, -90.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4960.602050, 2030.795043, 7.585999, 0.000000, -90.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4955.691894, 2030.795043, 7.585999, 0.000000, -90.000000, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4955.689941, 2032.649047, 7.587999, 0.000000, -90.000000, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4956.902832, 2029.128051, 7.587999, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4959.079101, 2029.130004, 7.590000, 0.000000, -90.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4959.079101, 2033.989990, 7.590000, 0.000000, -90.000000, -90.000000, -1, -1, -1 );
    CreateDynamicObject( 635, -4957.064941, 2033.991943, 7.592000, 0.000000, -90.000000, -90.000000, -1, -1, -1 );
    CreateDynamicObject( 14387, -4954.657226, 2031.552001, 3.835999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 14387, -4961.520996, 2031.552001, 3.835999, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 14387, -4957.988769, 2034.973999, 3.835999, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 14387, -4957.988769, 2028.152954, 3.835999, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
    CreateDynamicObject( 18271, -4966.595214, 2031.458984, 17.809999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 18271, -4947.519042, 2028.030029, 17.809999, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 698, -4982.479980, 2017.875976, 5.473999, 0.000000, 0.000000, -63.000000, -1, -1, -1 );
    CreateDynamicObject( 706, -4930.003906, 2045.194946, -0.146999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 13369, -4934.434082, 2010.329956, -6.242000, -122.099998, 0.000000, 69.800003, -1, -1, -1 );
    CreateDynamicObject( 790, -4939.732910, 2018.468994, -4.052000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 691, -4969.566894, 2017.631958, 2.188999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 688, -4973.712890, 2047.167968, 4.124000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 840, -4961.145996, 2023.975952, 4.576000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 838, -4962.453125, 2045.576049, 5.610000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 874, -4965.160156, 2001.401000, 2.331000, 0.000000, 0.000000, 51.400001, -1, -1, -1 );
    CreateDynamicObject( 874, -4948.738769, 1995.686035, 2.331000, 0.000000, 0.000000, 87.500000, -1, -1, -1 );
    CreateDynamicObject( 874, -4930.645996, 2032.130004, 1.690999, 0.000000, 0.000000, 87.500000, -1, -1, -1 );
    CreateDynamicObject( 874, -4986.730957, 2034.552978, 4.513000, 0.000000, 17.500000, 170.000000, -1, -1, -1 );
    CreateDynamicObject( 874, -4986.318847, 2050.239990, 3.351999, 0.000000, 17.500000, 170.000000, -1, -1, -1 );
    CreateDynamicObject( 874, -4940.833007, 2050.229980, 4.015999, 0.000000, 0.000000, 47.299999, -1, -1, -1 );
    CreateDynamicObject( 14400, -4953.277832, 2032.182983, 2.296999, 90.000000, 0.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 827, -4939.162109, 2023.479003, 2.898999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 813, -4941.013183, 2036.902954, 3.178999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 700, -4959.982910, 2016.935058, 3.723000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 706, -4942.352050, 2033.354980, 1.282999, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 705, -4968.497070, 2037.600952, 3.555000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 708, -4967.596191, 2050.914062, -3.082000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 708, -4974.344238, 2027.313964, -4.381999, 0.000000, -20.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 708, -4964.664062, 2006.703979, -4.077000, 0.000000, -20.000000, 89.900001, -1, -1, -1 );
    CreateDynamicObject( 708, -4946.081054, 2006.670043, -4.077000, 0.000000, -20.000000, 102.400001, -1, -1, -1 );
    CreateDynamicObject( 708, -4932.398925, 2014.104003, -2.503000, 0.000000, -20.000000, 167.000000, -1, -1, -1 );
    CreateDynamicObject( 708, -4925.544921, 2029.609985, -5.900000, 0.000000, -20.000000, 167.000000, -1, -1, -1 );
    CreateDynamicObject( 708, -4941.545898, 2051.969970, -3.897000, 0.000000, -20.000000, -112.000000, -1, -1, -1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4931.658203, 2043.897949, 4.823999, -1.899999, 1.000000, -59.200000, -1, -1, -1 ), 0, "Banging7Grams", 130, "Arial", 70, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4971.956054, 2023.493041, 6.739999, -1.200000, 0.500000, 104.599998, -1, -1, -1 ), 0, "Nibble", 130, "Arial", 70, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4947.923828, 2046.234985, 4.340000, -0.200000, 0.899999, -71.000000, -1, -1, -1 ), 0, "Dash", 130, "Arial", 80, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4958.229003, 2049.212890, 5.451000, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, "Kova", 130, "Arial", 80, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4940.236816, 2018.578979, 4.479000, 0.300000, -0.200000, -106.599998, -1, -1, -1 ), 0, "Alcoholic", 130, "Arial", 80, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4973.568847, 2027.425048, 7.725999, 0.000000, 0.000000, 79.500000, -1, -1, -1 ), 0, "elijah_who", 130, "Arial", 80, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4941.911132, 2051.261962, 6.762000, 0.000000, 0.000000, -28.399999, -1, -1, -1 ), 0, "iAshley", 130, "Arial", 80, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4966.801757, 2013.499023, 6.711999, 0.000000, 0.000000, 169.000000, -1, -1, -1 ), 0, "XtreamFlaw", 130, "Arial", 80, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4964.613769, 2007.512939, 5.831999, 0.000000, 0.000000, 169.000000, -1, -1, -1 ), 0, "Lyrical", 130, "Arial", 100, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4969.285156, 2017.756958, 6.668000, -1.200000, 0.500000, 115.599998, -1, -1, -1 ), 0, "Brad", 130, "Arial", 90, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4959.574218, 2017.125000, 4.847000, -1.200000, 0.500000, 115.599998, -1, -1, -1 ), 0, "Night", 130, "Arial", 90, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4943.875000, 2034.607055, 4.974999, -1.899999, 1.000000, -132.100006, -1, -1, -1 ), 0, "Chickenwing", 130, "Arial", 80, 1, -65022, 0, 1 );
    SetDynamicObjectMaterialText( CreateDynamicObject( 19327, -4955.777832, 2010.151000, 4.922999, -1.200000, 0.500000, 163.899993, -1, -1, -1 ), 0, "RichxKID", 130, "Arial", 90, 1, -65022, 0, 1 );
	SetDynamicObjectMaterialText( CreateDynamicObject(4731, -2159.6147, -453.5427, 52.6459, 0.0000, 0.0000, 164.6383 ), 0, "Battle Royale Stadium", 120, "Impact", 48, 0, -1, -16777216, 1 );
}

static stock BattleRoyale_DestroyAirdrops( lobbyid )
{
    for ( new i = 0; i < BR_MAX_AIRDROPS; i ++ )
    {
        DestroyDynamicMapIcon( br_lobbyAirdropData[ lobbyid ] [ i ] [ E_MAP_ICON ] );
        br_lobbyAirdropData[ lobbyid ] [ i ] [ E_MAP_ICON ] = -1;

        DestroyDynamicPickup( br_lobbyAirdropData[ lobbyid ] [ i ] [ E_PICKUP ] );
        br_lobbyAirdropData[ lobbyid ] [ i ] [ E_PICKUP ] = -1;

        DestroyDynamicObject( br_lobbyAirdropData[ lobbyid ] [ i ] [ E_OBJECT ] );
        br_lobbyAirdropData[ lobbyid ] [ i ] [ E_OBJECT ] = -1;
    }
}

static stock BattleRoyale_CreateAirdrop( lobbyid )
{
    for ( new i = 0; i < BR_MAX_AIRDROPS; i ++ )
    {
        if ( br_lobbyAirdropData[ lobbyid ] [ i ] [ E_MAP_ICON ] == -1 )
        {
            // store coordinates
            new Float: X = fRandomEx( br_lobbyData[ lobbyid ] [ E_B_MIN_X ], br_lobbyData[ lobbyid ] [ E_B_MAX_X ] );
            new Float: Y = fRandomEx( br_lobbyData[ lobbyid ] [ E_B_MIN_Y ], br_lobbyData[ lobbyid ] [ E_B_MAX_Y ] );
            new Float: Z;

            MapAndreas_FindZ_For2DCoord( X, Y, Z );

            new worldid = BR_GetWorld( lobbyid );

            // move a parachute to the ground
            br_lobbyAirdropData[ lobbyid ] [ i ] [ E_OBJECT ] = CreateDynamicObject( 18849, X, Y, Z + 250.0, 0.0, 0.0, 0.0, .worldid = worldid );
            MoveDynamicObject( br_lobbyAirdropData[ lobbyid ] [ i ] [ E_OBJECT ], X, Y, Z + 7.5, 10.0 );

            // map icon for everyone
			br_lobbyAirdropData[ lobbyid ] [ i ] [ E_MAP_ICON ] = CreateDynamicMapIcon( X, Y, Z, 0, COLOR_GREEN, worldid, -1, 0, 6000.0, MAPICON_GLOBAL );

            // show the map icons for the players
            foreach ( new playerid : battleroyaleplayers< lobbyid > ) {
                Streamer_ToggleItem( playerid, STREAMER_TYPE_MAP_ICON, br_lobbyAirdropData[ lobbyid ] [ i ] [ E_MAP_ICON ], true );
                Streamer_Update( playerid, STREAMER_TYPE_OBJECT );
            }
            return 1;
        }
    }
    return 1;
}