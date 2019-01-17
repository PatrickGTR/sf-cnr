/*
 * Irresistible Gaming (c) 2018
 * Developed by Kova
 * Module: cnr\features\minijobs\fishing.pwn
 * Purpose: fishing mini-job system
 */

/* **Includes** */
#include                                 < YSI\y_hooks >

/* **Definitions** */// -Time(ms), chance(%), distance(units)
#define FISHING_OBJECTS_ATTACH_INDEX           9
#define MIN_FISH_TIME                      60000
#define MAX_FISH_TIME                     180000
#define MIN_BITE_DURATION                   4000
#define MAX_BITE_DURATION                   6000
#define CHANCE_OF_SERVER_ITEM                 33
#define MAX_FISHED_ITEMS                       5
#define HARPOON_THROW_DISTANCE              60.0

/* Item system declarations/definitions */
enum E_FISHING_SHOP_COMPONENTS {
    BAITS,
    HARPOONS,
    ROD_UPGRADES,
    BAIT_UPGRADES,
    RADAR_UPGRADES,
    STORAGE_UPGRADES,
    SHARKS,
    FISH_KGS
}

enum E_FISHING_SHOP_DATA {
    NAME[12],
    PURPOSE[32],
    LIMIT, // This is limit without storage upgrade
    PRICE
}

new p_fishingItems [ MAX_PLAYERS ] [ E_FISHING_SHOP_COMPONENTS ];

new g_fishingShopData[ E_FISHING_SHOP_COMPONENTS ] [ E_FISHING_SHOP_DATA ] = {
    { "Bait", "Used for regular fish", 24, 1500 },
    { "Harpoon", "Used for sharks", 12, 3000 },
    { "Rod", "Gets bigger fish", 2, 250000 },
    { "Bait", "Gets fish faster", 2, 250000 },
    { "Radar", "Finds shark faster", 2, 500000 },
    { "Storage", "Stores more fish/shark", 2, 1000000 },
    { "Shark", "", 15, 10000 },
    { "Fish", "", 100, 1000 }
};

/* Boolean declarations */
new bool: p_IsFishOnRod[ MAX_PLAYERS char ],
    bool: p_IsPlayerFishing[ MAX_PLAYERS char ],
    bool: p_IsLootFish[ MAX_PLAYERS char ],
    bool: p_IsLootShark[ MAX_PLAYERS char ],
    bool: p_IsSharkDead[ MAX_PLAYERS char ],
    bool: p_DidPlayerAimAtShark[ MAX_PLAYERS char ],
    bool: p_IsHarpoonInUse[ MAX_PLAYERS char ],
    bool: p_IsSharkInRange[ MAX_PLAYERS char ];

/* Checkpoint declarations */
static stock g_fishingShopCP = -1;

/* Object declarations */
new p_FishingWaterObjects[ MAX_PLAYERS ][ 2 ],
    p_sharkObject[ MAX_PLAYERS ],
    p_1stSharkCollisionWall[ MAX_PLAYERS ],
    p_2ndSharkCollisionWall[ MAX_PLAYERS ],
    p_harpoonObject[ MAX_PLAYERS ];

/* Pull progress declaration */
new PlayerBar: p_fisherPullProgress[ MAX_PLAYERS ];

/* Timer/Interval declarations */
new p_sharkMovementTimer[ MAX_PLAYERS ],
    p_fishBiteRodTimer[ MAX_PLAYERS ],
    p_fishReleaseRodTimer[ MAX_PLAYERS ],
    p_fishingProgressInterval[ MAX_PLAYERS ],
    p_sharkTDInterval[ MAX_PLAYERS ],
    p_posMoveTimer[ MAX_PLAYERS ];

/* Textdraw declaration */
new PlayerText: p_sharkLocTD[ MAX_PLAYERS ];

/* Function-needed value declarations */
new p_closestVehID[ MAX_PLAYERS ],
    p_fishWeight[ MAX_PLAYERS ];


/* Commands */

CMD:fishing ( playerid, params[ ] ) return cmd_fish( playerid, params );

CMD:fish ( playerid, params[ ] ){

    if ( !strcmp ( params, "start", true ) ) {

        if ( p_IsPlayerFishing { playerid } )                                           return SendError( playerid, "You are already fishing." );
        if ( /*IsPlayerNearPier ( playerid ) ||*/ IsPlayerOnBoat ( playerid ) )         return SendError( playerid, "You are not on a boat." );
        if ( !IsPlayerSpawned( playerid ) )                                             return SendError( playerid, "You must be spawned to fish." );
	    if ( IsPlayerTazed( playerid ) )                                                return SendError( playerid, "You can't fish if you're tazed." );
	    if ( IsPlayerCuffed( playerid ) )                                               return SendError( playerid, "You can't fish if you're cuffed." );
	    if ( IsPlayerTied( playerid ) )                                                 return SendError( playerid, "You can't start fishing while tied." );
	    if ( IsPlayerKidnapped( playerid ) )                                            return SendError( playerid, "You can't start fishing as you're kidnapped." );
	    if ( IsPlayerGettingBlowed( playerid ) )                                        return SendError( playerid, "You can't start fishing while getting blowed." );
	    if ( IsPlayerBlowingCock( playerid ) )                                          return SendError( playerid, "You can't start fishing while being given an oral sex." );
	    if ( IsPlayerInWater( playerid ) )                                              return SendError( playerid, "You can't start fishing while you're in a water." );
	    if ( IsPlayingAnimation( playerid, "GANGS", "smkcig_prtl" ) )                   return SendError( playerid, "You can't start fishing while smoking." );
	    if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER )          return SendError( playerid, "You can't start fishing while entering a vehicle." );
        if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE )                  return SendError( playerid, "You can't start fishing while exiting a vehicle." );

        if (! strmatch( GetPlayerArea( playerid ), "San Andreas" ) ){

            if ( IsPlayerInAnyVehicle ( playerid ) )                                    return SendError( playerid, "You must be on foot." );
            if ( IsPlayerOnBoat ( playerid ) )                                          return SendError( playerid, "You must be on a boat." ); 
            if (! IsBoatMoving ( playerid ) )                                           return SendError( playerid, "Vehicle is moving, you are not stable enough.");
            if ( p_fishingItems[ playerid ][ BAITS ] == 0 )                             return SendError( playerid, "You don't have any baits" );

            if ( p_fishingItems[ playerid ][ FISH_KGS ] >= ( p_fishingItems[ playerid ][ STORAGE_UPGRADES ] + 1 ) * g_fishingShopData[ FISH_KGS ][ LIMIT ] ) 
            return ShowPlayerDialog( playerid, DIALOG_FISHING_STORAGE_CAUTION, DIALOG_STYLE_MSGBOX, "Caution", "You have no more space for fish in your inventory.\nMake some by selling your fish in fishing shop", "Close", "" );

            return StartNormalFishing( playerid );

        } else {

            if( p_fishingItems[ playerid ][ HARPOONS ] == 0 ){
                SendError( playerid, "You don't have any harpoons." );
                if ( p_fishingItems[ playerid ][ BAITS ] == 0 ){
                    return SendError( playerid, "You don't have any baits neither." );
                } else {
                    SendError( playerid, "You don't have any harpoons." );

                    if ( IsPlayerInAnyVehicle ( playerid ) )                                    return SendError( playerid, "You must be on foot to start normal fishing." );
                    if (! IsBoatMoving ( playerid ) )                                           return SendError( playerid, "Vehicle is moving, you are not stable enough.");

                    if ( p_fishingItems[ playerid ][ FISH_KGS ] >= ( p_fishingItems[ playerid ][ STORAGE_UPGRADES ] + 1 ) * g_fishingShopData[ FISH_KGS ][ LIMIT ] ) 
                    return ShowPlayerDialog( playerid, DIALOG_FISHING_STORAGE_CAUTION, DIALOG_STYLE_MSGBOX, "Caution", "You have no more space for fish in your inventory.\nMake some by selling your fish in fishing shop", "Close", "" );

                    return StartNormalFishing( playerid );
                }
            }

            if ( p_fishingItems[ playerid ][ SHARKS ] >= ( p_fishingItems[ playerid ][ STORAGE_UPGRADES ] + 1 ) * g_fishingShopData[ SHARKS ][ LIMIT ] ) 
            return ShowPlayerDialog( playerid, DIALOG_FISHING_STORAGE_CAUTION, DIALOG_STYLE_MSGBOX, "Caution", "You have no more space for shark meat in your inventory.\nMake some by selling your shark meat in fishing shop", "Close", "" );

            return StartSharkFishing( playerid );

        }

    } else if ( !strcmp ( params, "stop", true ) ) {

        if ( p_IsPlayerFishing { playerid } ) return StopFishing( playerid );

        return SendError( playerid, "You are not fishing." );

    } else if ( !strcmp ( params, "help", true ) ) {

        szLargeString[ 0 ] = '\0';
	    strcat( szLargeString, ""COL_WHITE"There are "COL_ORANGE"two"COL_WHITE" types of fishing! \n\nYou can choose between regular fishing (with baits) or shark fishing on an open sea.\n Both are interesting and pay is nearly the same" );
		strcat( szLargeString, "\n\nTo be able to fish, you need to be on a boat.\nYou need a harpoon for shark fishing (open sea) and baits for regular fishing.\n Open sea is area under a name San Andreas." );
		return ShowPlayerDialog( playerid, DIALOG_FISHING_HELP, DIALOG_STYLE_MSGBOX, "{FFFFFF}Fishing", szLargeString, "Got it", "" );

    }
    else return SendUsage( playerid, "/fish [START/STOP/HELP]" );
}


/* Hooks */

hook OnScriptInit(){
    g_fishingShopCP = CreateDynamicCP( -1595.1049, 1283.9769, 1207.2159, 1.0, -1, -1, -1, 30.0 ); 
    CreateDynamic3DTextLabel("[SHOP]", COLOR_GOLD, -1595.1049, 1283.9769, 1207.2159, 20.0);
    CreateEntrance( "[FISHING SHOP]", -1607.7175, 1284.5105, 7.1854, -1605.2539, 1284.3455, 1207.2159, 1, 33, false, false, 9 );
    initializeFishingShopObjects();
    return 1;
}

hook OnPlayerConnect( playerid ){

    p_fisherPullProgress[ playerid ] = CreatePlayerProgressBar ( playerid, 252.000000, 221.000000, 142.0, 3.2, 0xFFFACDFF, 100.0, BAR_DIRECTION_RIGHT );

    p_sharkLocTD[ playerid ] = CreatePlayerTextDraw(playerid, 26.000000, 220.000000, "~b~Depth:~w~ 0.0m~n~~b~Distance:~w~ 0.0m");
    PlayerTextDrawBackgroundColor(playerid, p_sharkLocTD[ playerid ], 255);
    PlayerTextDrawFont(playerid, p_sharkLocTD[ playerid ], 2);
    PlayerTextDrawLetterSize(playerid, p_sharkLocTD[ playerid ], 0.210000, 1.100000);
    PlayerTextDrawColor(playerid, p_sharkLocTD[ playerid ], -1);
    PlayerTextDrawSetOutline(playerid, p_sharkLocTD[ playerid ], 1);
    PlayerTextDrawSetProportional(playerid, p_sharkLocTD[ playerid ], 1);

    p_IsFishOnRod{ playerid } = false;
    p_IsPlayerFishing{ playerid } = false;
    p_IsLootFish{ playerid } = false;
    p_IsLootShark{ playerid } = false;
    p_IsSharkDead{ playerid } = false;
    p_IsHarpoonInUse{ playerid } = false;
    p_DidPlayerAimAtShark{ playerid } = false;
    
    return 1;
}

hook OnPlayerLogin( playerid ){

    for( new i = 0; i < 8; i++ ){
        p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS: i ] = 0;
    }

    mysql_tquery( dbHandle, sprintf( "SELECT * FROM `FISHING` WHERE `ID` = %d", GetPlayerAccountID( playerid ) ), "OnFishingLoadForPlayer", "i", playerid );

	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid ){
    if( checkpointid == g_fishingShopCP ) return ShowFishingShopMenu( playerid );
    return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] ) {

    if( dialogid == DIALOG_FISHING_SHOP && response ) {
        switch( listitem ) {
            case 0: ShowFishingBuyingMenu( playerid );
            case 1: ShowFishingUpgradeMenu( playerid );
            case 2: ShowFishingSellMenu( playerid );
        }
        return 1;
    }

    else if( dialogid == DIALOG_FISHING_SHOP_ITEMS ) {
        if( response ){
            SetPVarInt( playerid, "fishing_shop_buy", listitem );
            ShowPlayerDialog( playerid, DIALOG_FISHING_SHOP_ITEMS_AMOUNT, DIALOG_STYLE_LIST, "{FFFFFF}Fishing items - Buy Quantity", "Buy 1\nBuy 5\nBuy Max", "Buy", "Back" );

        } else {
            ShowFishingShopMenu( playerid );
        }
        return 1;
    }

    else if( dialogid == DIALOG_FISHING_SHOP_ITEMS_AMOUNT ){
        if( response ){
            new amount, id = GetPVarInt( playerid, "fishing_shop_buy" ), limit = ( g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:id ][ LIMIT ] * ( p_fishingItems[ playerid ][ STORAGE_UPGRADES ] + 1 ) );

            switch( listitem ) {
                case 0: amount = 1;
                case 1: amount = 5;
                case 2: amount = limit - p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ];
            }
    
            if( p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] + amount > limit )                                                      return SendError( playerid, "You've reached the limit." );
            if( amount * g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:id ][ PRICE ] > GetPlayerMoney( playerid ) )                                 return SendError( playerid, "You don't have enough money to buy this much.");

            GivePlayerCash( playerid, -( g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:id ][ PRICE ] * amount ) );
            p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] = p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] + amount;

            if( id == 0 ) { szSmallString = "BAITS"; }
            else          { szSmallString = "HARPOONS"; }

            mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO `FISHING`(`USER_ID`,`BAITS`,`HARPOONS`,`ROD_UPGRADES`,`BAIT_UPGRADES`,`RADAR_UPGRADES`,`STORAGE_UPGRADES`,`SHARKS`,`FISH_KGS`) VALUES(%d,%d,%d,%d,%d,%d,%d,%d,%d) ON DUPLICATE KEY UPDATE `%s`=%d;",                p_AccountID[ playerid ], p_fishingItems[ playerid ] [ BAITS ], p_fishingItems[ playerid ] [ HARPOONS ], p_fishingItems[ playerid ] [ ROD_UPGRADES ], p_fishingItems[ playerid ] [ BAIT_UPGRADES ], p_fishingItems[ playerid ] [ RADAR_UPGRADES ], p_fishingItems[ playerid ] [ STORAGE_UPGRADES ], p_fishingItems[ playerid ] [ SHARKS ], p_fishingItems[ playerid ] [ FISH_KGS ],
                        szSmallString, p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] );
            mysql_single_query( szBigString );

            ShowFishingBuyingMenu( playerid );
        } else {
            ShowFishingBuyingMenu( playerid );
        }
        return 1;
    }

    else if( dialogid == DIALOG_FISHING_SHOP_UPGRADES ){
        if( response ){
            new id = listitem + 2;
            
            if( p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] >= g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:id ][ LIMIT ] )  return SendError( playerid, "You've reached the upgrade limit." );
            if( g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:id ][ PRICE ] > GetPlayerMoney( playerid ) )                                   return SendError( playerid, "You don't have enough money for this upgrade." );

            if      ( listitem == 0 ) szSmallString = "ROD_UPGRADES"; 
            else if ( listitem == 1 ) szSmallString = "BAIT_UPGRADES";
            else if ( listitem == 2 ) szSmallString = "RADAR_UPGRADES";
            else                      szSmallString = "STORAGE_UPGRADES";

            GivePlayerCash( playerid, -g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:id ][ PRICE ] );
            p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ]++;
        
            mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO `FISHING`(`USER_ID`,`BAITS`,`HARPOONS`,`ROD_UPGRADES`,`BAIT_UPGRADES`,`RADAR_UPGRADES`,`STORAGE_UPGRADES`,`SHARKS`,`FISH_KGS`) VALUES (%d,%d,%d,%d,%d,%d,%d,%d,%d) ON DUPLICATE KEY UPDATE `%s`=%d;", p_AccountID[ playerid ], p_fishingItems[ playerid ] [ BAITS ], p_fishingItems[ playerid ] [ HARPOONS ], p_fishingItems[ playerid ] [ ROD_UPGRADES ], p_fishingItems[ playerid ] [ BAIT_UPGRADES ], p_fishingItems[ playerid ] [ RADAR_UPGRADES ], p_fishingItems[ playerid ] [ STORAGE_UPGRADES ], p_fishingItems[ playerid ] [ SHARKS ], p_fishingItems[ playerid ] [ FISH_KGS ],
                        szSmallString, p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] );
            mysql_single_query( szBigString );

            ShowFishingUpgradeMenu( playerid );
        } else {
            ShowFishingShopMenu( playerid );
        }
        return 1;
    }

    else if( dialogid == DIALOG_FISHING_SHOP_SELL ){
        if( response ){

            if( listitem == 0 ) szSmallString = "SHARKS";
            else                szSmallString = "FISH_KGS";
            new id = listitem + 6;

            GivePlayerCash( playerid, g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:id ][ PRICE ] * p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] );
            p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ] = 0;

            mysql_format( dbHandle, szNormalString, sizeof ( szNormalString ), "UPDATE `FISHING` SET `%s` = %i WHERE `USER_ID` = %d", szSmallString, p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS:id ], p_AccountID[ playerid ] );
            mysql_single_query( szNormalString );

            ShowFishingSellMenu( playerid );
        } else {
            ShowFishingShopMenu( playerid );
        }
    }
    return 0;
}

hook OnPlayerUpdate( playerid ){
    if( p_IsHarpoonInUse { playerid }  ){
        if( GetPlayerWeapon( playerid ) != 34 ){
            SetPlayerArmedWeapon( playerid, 34 );
        }
    }
    return 1;
}

hook OnPlayerUpdateEx( playerid ){

    if( p_IsSharkDead{ playerid } ){
        new Float: oX, Float: oY, Float: oZ;
        GetDynamicObjectPos( p_sharkObject[ playerid ], oX, oY, oZ );

        if( IsPlayerInRangeOfPoint ( playerid, 5, oX, oY, oZ ) ){
            DestroyDynamicObject( p_sharkObject[ playerid ] );
            GiveFisherLoot( playerid );
            p_IsLootShark{ playerid } = false;
            StopFishing( playerid );
        }
    } else {
        if( p_IsLootShark{ playerid } ){
            if( IsPlayerInWater( playerid ) ){
                if( p_IsHarpoonInUse{ playerid } ) DisassembleHarpoon( playerid );
                SendError( playerid, "You ended up in water and shark escaped the radar." );
                p_IsLootShark{ playerid } = false;
                StopFishing( playerid );
            }
        }
    }
    return 1;
}

hook OnPlayerShootDynObject( playerid, weaponid, objectid, Float:x, Float:y, Float:z ){
    if( objectid == p_1stSharkCollisionWall[ playerid ] || objectid == p_2ndSharkCollisionWall[ playerid ] ){
        if( p_IsHarpoonInUse{ playerid } ){
            p_DidPlayerAimAtShark{ playerid } = true;
        }
    }
    return 1;
}

hook OnDynamicObjectMoved( objectid ){

    foreach( new playerid : Player ){
        if ( objectid == p_harpoonObject[ playerid ] ){

            p_IsHarpoonInUse{ playerid } = false;

            SetCameraBehindPlayer(playerid);
            DestroyDynamicObject( p_harpoonObject[ playerid ] );

            if(! p_DidPlayerAimAtShark{ playerid } )             return SendServerMessage( playerid, "You missed the shark." );
            if(! p_IsSharkInRange{ playerid } )                  return SendServerMessage( playerid, "Shark was out of range." );

            new Float: oX, Float: oY, Float: oZ;
            SendServerMessage( playerid, "You've hit the shark, jump in water and pick it up!");
            p_IsSharkDead{ playerid } = true;
            KillTimer( p_sharkMovementTimer[ playerid ]);
            KillTimer( p_posMoveTimer[ playerid ]);
            DestroyDynamicObject( p_1stSharkCollisionWall[ playerid ] );
            DestroyDynamicObject( p_2ndSharkCollisionWall[ playerid ] );
            StopDynamicObject( p_sharkObject[ playerid ] );
            GetDynamicObjectPos( p_sharkObject[ playerid ], oX, oY, oZ );
            MoveDynamicObject( p_sharkObject[ playerid ], oX, oY, oZ, 2, 180, 0, 0);
        }
    }

    return 1;
}

hook OnPlayerDeath( playerid, killerid, reason ){

    if ( p_IsPlayerFishing{ playerid } ){

        p_IsFishOnRod{ playerid } = false;
        StopFishing( playerid );
        
    }

    return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys ){

    if( p_IsFishOnRod{ playerid } ){

        new Float: currentProgressValue = GetPlayerProgressBarValue ( playerid, p_fisherPullProgress[ playerid ] );

        if ( currentProgressValue == 100 )
            return FisherSuccess( playerid );
        
        if ( PRESSED ( KEY_SPRINT ) ){
            SetPlayerProgressBarValue( playerid, p_fisherPullProgress[ playerid ], ( currentProgressValue + 5 ) );

            new Float: Angle, Float: posX, Float: posY, Float: posZ;

            GetPlayerFacingAngle( playerid, Angle );
            GetPlayerPos( playerid, posX, posY, posZ );
            posX += ( ( 20 - ( currentProgressValue / 5 ) ) * floatsin ( -Angle, degrees ) );
            posY += ( ( 20 - ( currentProgressValue / 5 ) ) * floatcos ( -Angle, degrees ) );
            posZ = 0;
            MoveDynamicObject( p_FishingWaterObjects[ playerid ] [ 0 ], posX, posY, posZ-1, 5 );
            MoveDynamicObject( p_FishingWaterObjects[ playerid ] [ 1 ], posX, posY, posZ-3, 5 );
        }
    }

    if( p_IsLootShark{ playerid } ){
        if( PRESSED ( KEY_FIRE ) ){
            if( p_IsHarpoonInUse{ playerid } ){
                if( GetPlayerCameraMode( playerid ) == 7 ){
                    if( p_IsSharkDead{ playerid } )                                                 return SendError( playerid, "Shark is already dead.");
                    if( IsPlayerInAnyVehicle( playerid ) )                                          return SendError( playerid, "You must not be in a vehicle to shoot a harpoon.");
                    if ( IsPlayerInWater( playerid ) )                                              return SendError( playerid, "You must be outside of the water to shoot a harpoon." );
                    if ( IsPlayerInAnyVehicle ( playerid ) )                                        return SendError( playerid, "You must be on foot to shoot a harpoon." );
                    if ( !IsPlayerSpawned( playerid ) )                                             return SendError( playerid, "You must be spawned to shoot a harpoon." );
	                if ( IsPlayerTazed( playerid ) )                                                return SendError( playerid, "You can't shoot a harpoon if you're tazed." );
	                if ( IsPlayerCuffed( playerid ) )                                               return SendError( playerid, "You can't shoot a harpoon if you're cuffed." );
	                if ( IsPlayerTied( playerid ) )                                                 return SendError( playerid, "You can't shoot a harpoon tied." );
	                if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER )          return SendError( playerid, "You can't shoot a harpoon while entering a vehicle." );
                    if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE )                  return SendError( playerid, "You can't shoot a harpoon while exiting a vehicle." );

                    shootHarpoon( playerid );
                }
            }
        }
        if( PRESSED ( KEY_YES ) ){
            if( IsPlayerInAnyVehicle( playerid ) )           return SendError( playerid, "You can't assemble/disassemble harpoon while in a vehicle.");
            return (! p_IsHarpoonInUse{ playerid } ) ? AssembleHarpoon( playerid ) : DisassembleHarpoon( playerid );
        }
    }
    return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate ){
    if ( IsPlayerNPC( playerid ) )
		return 1;

    if( p_IsHarpoonInUse{ playerid } ) {
        if( oldstate == PLAYER_STATE_ONFOOT ){
            DisassembleHarpoon( playerid );
        }
    }
    return 1;
}




/* Fishing Functions */

function StartNormalFishing( playerid ){

    p_IsPlayerFishing{ playerid } = true;

    SetPlayerAttachedObject( playerid, FISHING_OBJECTS_ATTACH_INDEX, 18632, 5, 0.095, 0.03, 0, -15, 0, -30, 1.000000, 1.000000, 1.000000 );
    ApplyAnimation( playerid, "SAMP", "FishingIdle", 3.0, 1, 1, 0, 0, 0 );

    new Float: Angle, Float: posX, Float: posY, Float: posZ;

    GetPlayerFacingAngle( playerid, Angle );
    GetPlayerPos( playerid, posX, posY, posZ );
    posX += ( 20 * floatsin ( -Angle, degrees ) );
    posY += ( 20 * floatcos ( -Angle, degrees ) );
    posZ = -1;
    Angle += 90.0;
    p_FishingWaterObjects[ playerid ] [ 0 ] = CreateDynamicObject( 16332, posX, posY, posZ-3, 0, 0, Angle, 0, 0, -1, 300.0 );
    SetDynamicObjectMaterial( p_FishingWaterObjects[ playerid ] [ 0 ], 0, 16328, "des_quarrycrane", "ws_cranehook", 0xFFFF0000 );
    SetDynamicObjectMaterial( p_FishingWaterObjects[ playerid ] [ 0 ], 1, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    SetDynamicObjectMaterial( p_FishingWaterObjects[ playerid ] [ 0 ], 2, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    MoveDynamicObject( p_FishingWaterObjects[ playerid ] [ 0 ], posX, posY, posZ, 3 );

    p_fishingItems[ playerid ][ BAITS ]--;
    mysql_format( dbHandle, szNormalString, sizeof ( szNormalString ), "UPDATE `FISHING` SET `BAITS` = %i WHERE `USER_ID` = %d", p_fishingItems[ playerid ][ BAITS ], p_AccountID[ playerid ] );
    mysql_single_query( szNormalString );

    if ( RandomEx( 0, 100 ) < ( 100-CHANCE_OF_SERVER_ITEM ) ){
        p_IsLootFish{ playerid } = true;
        p_fishWeight[ playerid ] = RandomEx( 1, 3 );
        p_fishWeight[ playerid ] = p_fishWeight[ playerid ] * ( p_fishingItems[ playerid ][ ROD_UPGRADES ] + 1 );
    }

    new time = RandomEx( MIN_FISH_TIME, MAX_FISH_TIME );
    time = time / ( p_fishingItems[ playerid ][ BAIT_UPGRADES ] + 1 );
    p_fishBiteRodTimer[ playerid ] = SetTimerEx( "FishBite", time, false, "i", playerid );

    return 1;
}

function StartSharkFishing( playerid ){

    SendServerMessage(playerid, "You've set up your radar, roam around to detect a shark.");

    new time = RandomEx( MIN_FISH_TIME, MAX_FISH_TIME );
    time = time / ( p_fishingItems[ playerid ][ RADAR_UPGRADES ] + 1 );
    SetTimerEx( "CreateShark", time, false, "i", playerid );

    p_IsPlayerFishing{ playerid } = true;
    p_IsLootShark{ playerid } = true;
    p_IsHarpoonInUse{ playerid } = false;

    return 1;
}

function StopFishing( playerid ){

    if( p_IsFishOnRod{ playerid } ) return SendError( playerid, "You can't stop now, fish is pulling your rod." );

    if( p_IsLootShark{ playerid } ) SendServerMessage( playerid, "You turned the radar off, shark escaped the area.");

    p_IsPlayerFishing{ playerid } = false;
    p_IsLootFish{ playerid } = false;
    p_IsLootShark{ playerid } = false;
    p_IsSharkDead{ playerid } = false;
    p_DidPlayerAimAtShark{ playerid } = false;

    KillTimer( p_sharkMovementTimer[ playerid] );
    KillTimer( p_fishReleaseRodTimer[ playerid ] );
    KillTimer( p_fishBiteRodTimer[ playerid ] );
    KillTimer( p_fishingProgressInterval[playerid] );

    PlayerTextDrawHide( playerid, p_sharkLocTD[ playerid ] );

    HidePlayerProgressBar( playerid, p_fisherPullProgress[ playerid ] );

    RemovePlayerAttachedObject( playerid, FISHING_OBJECTS_ATTACH_INDEX );

    DestroyDynamicObject( p_FishingWaterObjects[ playerid ] [ 0 ] );
    DestroyDynamicObject( p_FishingWaterObjects[ playerid ] [ 1 ] );
    DestroyDynamicObject( p_sharkObject[ playerid ] );
    DestroyDynamicObject( p_harpoonObject[ playerid ] );
    DestroyDynamicObject( p_1stSharkCollisionWall[ playerid ] );
    DestroyDynamicObject( p_2ndSharkCollisionWall[ playerid ] );

    ClearAnimations( playerid );

    return 1;
}

function CreateShark( playerid ){

    SendServerMessage(playerid, "Radar detected a shark.");

    new Float: posX, Float: posY, Float: posZ;

    GetPlayerPos( playerid, posX, posY, posZ );

    posX = posX + RandomEx(-200, 200);
    posY = posY + RandomEx(-200, 200);
    posZ = RandomEx( 3, 6 );

    p_sharkObject[ playerid ] = CreateDynamicObject( 1608, posX, posY, -posZ, 0, 0, 0, 0, 0, -1, STREAMER_OBJECT_SD, STREAMER_OBJECT_DD, -1, 0 );
    p_1stSharkCollisionWall[ playerid ] = CreateDynamicObject( 19449, posX, posY, -posZ, 0, 0, 0, 0, 0, -1, STREAMER_OBJECT_SD, STREAMER_OBJECT_DD, -1, 0  );
    p_2ndSharkCollisionWall[ playerid ] = CreateDynamicObject( 19449, posX, posY, -posZ, 0, 90.0, 0, 0, 0, -1, STREAMER_OBJECT_SD, STREAMER_OBJECT_DD, -1, 0  );
    SetDynamicObjectMaterial( p_1stSharkCollisionWall[playerid], 0, 18202, "w_towncs_t", "concretebig4256128m", 1 );
    SetDynamicObjectMaterial( p_2ndSharkCollisionWall[playerid], 0, 18202, "w_towncs_t", "concretebig4256128m", 1 );
    p_sharkMovementTimer[ playerid ] = SetTimerEx( "MoveShark", 6500, true, "i", playerid );

    PlayerTextDrawShow( playerid, p_sharkLocTD[ playerid ] );

    p_sharkTDInterval[ playerid ] = SetTimerEx( "TDUpdate", 500, true, "i", playerid );

    return 1;
} 

function MoveShark( playerid ){

    new Float: oX, Float: oY, Float: oZ, Float: Angle = RandomEx( 0, 360 );

    GetDynamicObjectPos( p_sharkObject[ playerid ], oX, oY, oZ );

    /*Rotation*/
    MoveDynamicObject( p_sharkObject[ playerid ], oX, oY, oZ, 15, 0.0, 0.0, Angle );
    MoveDynamicObject( p_1stSharkCollisionWall[ playerid ], oX, oY, oZ, 15, 0.0, 0.0, Angle );
    MoveDynamicObject( p_2ndSharkCollisionWall[ playerid ], oX, oY, oZ, 15, 0.0, 90.0, Angle );

    oX += 30 * floatsin ( -Angle, degrees );
    oY += 30 * floatcos ( -Angle, degrees );
    oZ = RandomEx( 4, 6 );
    
    p_posMoveTimer[ playerid ] = SetTimerEx( "posMove", 1000, false, "iffff", playerid, oX, oY, -oZ, Angle );

    return 1;
}

function posMove( playerid, Float: oX, Float: oY, Float: oZ, Float: Angle ){
    MoveDynamicObject( p_sharkObject[ playerid ], oX, oY, oZ, 8, 0.0, 0.0, Angle );
    MoveDynamicObject( p_1stSharkCollisionWall[ playerid ], oX, oY, oZ, 8, 0.0, 0.0, Angle );
    MoveDynamicObject( p_2ndSharkCollisionWall[ playerid ], oX, oY, oZ, 8, 0.0, 90.0, Angle );
    return 1;
}

function shootHarpoon( playerid ){

    new Float: oX, Float: oY, Float: oZ, 
        Float: camX, Float: camY, Float: camZ, 
        Float: vecX, Float: vecY, Float: vecZ, 
        Float: pX, Float: pY, Float: pZ,
        Float: verAngle, Float: horAngle, 
        Float: distVecToPlayer, Float: distObjToPlayer;

    RemovePlayerAttachedObject( playerid, FISHING_OBJECTS_ATTACH_INDEX );

    GetPlayerPos( playerid, pX, pY, pZ);
    GetPlayerCameraPos( playerid, camX, camY, camZ );
    GetPlayerCameraFrontVector( playerid, vecX, vecY, vecZ );
    GetDynamicObjectPos( p_sharkObject[ playerid ], oX, oY, oZ );

    vecX = camX + floatmul(vecX, HARPOON_THROW_DISTANCE);
    vecY = camY + floatmul(vecY, HARPOON_THROW_DISTANCE);
    vecZ = camZ + floatmul(vecZ, HARPOON_THROW_DISTANCE);
    verAngle = asin(vecZ); //z
    horAngle = atan2(vecX, vecY); //y

    p_harpoonObject[ playerid ] = CreateDynamicObject( 335, pX, pY, pZ, 0.00, horAngle, verAngle, 0, 0, -1, 300.0 );
    MoveDynamicObject( p_harpoonObject[ playerid ], vecX, vecY, vecZ, 40, 0.00, horAngle, verAngle );

    StopDynamicObject( p_sharkObject[ playerid ] );
    StopDynamicObject( p_1stSharkCollisionWall[ playerid ] );
    StopDynamicObject( p_2ndSharkCollisionWall[ playerid ] );

    AttachCameraToDynamicObject( playerid, p_harpoonObject[ playerid ] );

    distVecToPlayer = floatsqroot( ( ( pX - vecX ) * ( pX - vecX ) ) + ( ( pY - vecY ) * ( pY - vecY ) ) + ( ( pZ - vecZ ) * ( pZ - vecZ ) ) );
    distObjToPlayer = floatsqroot( ( ( pX - oX ) * ( pX - oX ) ) + ( ( pY - oY ) * ( pY - oY ) ) + ( ( pZ - oZ ) * ( pZ - oZ ) ) );

    if( distObjToPlayer < distVecToPlayer - 1 ) {
        p_IsSharkInRange{ playerid } = true;
    } else {
        p_IsSharkInRange{ playerid } = false;
    }
    

    return 1;
}

function AssembleHarpoon( playerid ){
    if( p_fishingItems[ playerid ][ HARPOONS ] < 1 ) return SendError( playerid, "You don't have any harpoons." );
    
    p_fishingItems[ playerid ][ HARPOONS ]--;
    mysql_format( dbHandle, szNormalString, sizeof ( szNormalString ), "UPDATE `FISHING` SET `HARPOONS` = %i WHERE `USED_ID` = %d", p_fishingItems[ playerid ][ HARPOONS ], p_AccountID[ playerid ] );
    mysql_single_query( szNormalString );

    ApplyAnimation( playerid, "ROB_BANK", "CAT_Safe_Rob", 4.1, 0, 0, 0, 0, 700, 0 );
    p_IsHarpoonInUse{ playerid } = true;
    GivePlayerWeapon( playerid, 34, 1 );
    SetPlayerArmedWeapon( playerid, 34 );
    SetPlayerAttachedObject( playerid, FISHING_OBJECTS_ATTACH_INDEX, 19583, 6, 0.511999, -0.018, 0.136, 91.6, -6.09999, 94.5, 1, 1, 1, 0xFF000000, 0xFF000000);
    return 1;
}

function DisassembleHarpoon( playerid ){
    p_fishingItems[ playerid ][ HARPOONS ]++;
    mysql_format( dbHandle, szNormalString, sizeof ( szNormalString ), "UPDATE `FISHING` SET `HARPOONS` = %i WHERE `USER_ID` = %d", p_fishingItems[ playerid ][ HARPOONS ], p_AccountID[ playerid ] );
    mysql_single_query( szNormalString );

    ApplyAnimation( playerid, "ROB_BANK", "CAT_Safe_Rob", 4.1, 0, 0, 0, 0, 700, 0 );
    p_IsHarpoonInUse{ playerid } = false;
    GivePlayerWeapon( playerid, 34, -1 );
    RemovePlayerAttachedObject( playerid, FISHING_OBJECTS_ATTACH_INDEX );
    SetPlayerArmedWeapon( playerid, 0 );
    return 1;
}

function FishBite( playerid ){

    ClearAnimations( playerid );
    ApplyAnimation( playerid, "SWORD", "sword_block", 3.0, 1, 1, 0, 0, 0 );

    new Float: oX, Float: oY, Float: oZ;

    GetDynamicObjectPos( p_FishingWaterObjects[ playerid ] [ 0 ], oX, oY, oZ );
    p_FishingWaterObjects[ playerid ][ 1 ] = CreateDynamicObject( 18669, oX, oY, oZ-2, 0, 0, 0, 0, 0, -1, 300.0 );

    p_IsFishOnRod{ playerid } = true;

    new randTime = random( MAX_BITE_DURATION - MIN_BITE_DURATION ) + MIN_BITE_DURATION;

    p_fishReleaseRodTimer[ playerid ] = SetTimerEx( "FisherFail", randTime, false, "i", playerid );

    if ( p_IsLootFish{ playerid } ){
        SetPlayerProgressBarValue( playerid, p_fisherPullProgress[playerid], 50.0 );
        p_fishingProgressInterval[ playerid ] = SetTimerEx( "barUpdate", 250, true, "ii", playerid, p_fishWeight[ playerid ] );
    } else {
        SetPlayerProgressBarValue( playerid, p_fisherPullProgress[ playerid ], 0.0 );
    }

    ShowPlayerProgressBar( playerid, p_fisherPullProgress[ playerid ] );

    return 1;
}

function FisherSuccess( playerid ){

    p_IsFishOnRod{ playerid } = false;
    GiveFisherLoot( playerid );
    StopFishing( playerid );

    return 1;
}

function FisherFail( playerid ){  

    p_IsFishOnRod{ playerid } = false;

    if( p_IsLootFish{ playerid } ){
        SendServerMessage( playerid, "You failed pulling out the fish." );
    } else {
        SendServerMessage( playerid, "You failed pulling out the item." );
    }

    StopFishing( playerid );

    return 1;
}

function GiveFisherLoot( playerid ){

    if( p_IsLootFish{ playerid } ){

        SendClientMessageFormatted( playerid, -1, "{C0C0C0}[SERVER]{FFFFFF} You successfully fished %i kilograms of fish.", p_fishWeight[ playerid ] );
        p_fishingItems[ playerid ][ FISH_KGS ] = p_fishingItems[ playerid ][ FISH_KGS ] + p_fishWeight[ playerid ];
        mysql_format( dbHandle, szNormalString, sizeof ( szNormalString ), "UPDATE `FISHING` SET `FISH_KGS` = %i WHERE `USER_ID` = %d", p_fishingItems[ playerid ][ FISH_KGS ], p_AccountID[ playerid ] );
        mysql_single_query( szNormalString );

    } else if ( p_IsLootShark{ playerid } ){

        SendServerMessage(playerid, "You successfully picked up a shark meat.");
        p_fishingItems[ playerid ][ SHARKS ]++;
        mysql_format( dbHandle, szNormalString, sizeof ( szNormalString ), "UPDATE `FISHING` SET `SHARKS` = %i WHERE `USER_ID` = %d", p_fishingItems[ playerid ][ SHARKS ], p_AccountID[ playerid ] );
        mysql_single_query( szNormalString );

    } else {

        new itemNumber = RandomEx( 0, 5 );
        new itemAmount = RandomEx( 1, MAX_FISHED_ITEMS );
        new items[ 6 ] [ 18 ] = { "siccors", "rope/s", "bobby pin/s", "aluminium foil/s", "thermal drill/s", "metal melter/s" };
        SendClientMessageFormatted( playerid, -1, "{C0C0C0}[SERVER]{FFFFFF} You found %i %s", itemAmount, items[ itemNumber ] );

        switch( itemNumber ){
            case 0: return GivePlayerShopItem( playerid, SHOP_ITEM_SCISSOR, itemAmount );
            case 1: return GivePlayerShopItem( playerid, SHOP_ITEM_ROPES, itemAmount );
            case 2: return GivePlayerShopItem( playerid, SHOP_ITEM_BOBBY_PIN, itemAmount );
            case 3: return GivePlayerShopItem( playerid, SHOP_ITEM_FOIL, itemAmount );
            case 4: return GivePlayerShopItem( playerid, SHOP_ITEM_DRILL, itemAmount );
            case 5: return GivePlayerShopItem( playerid, SHOP_ITEM_METAL_MELTER, itemAmount );
        }

    }

    return 1;
}


/* Update functions */

function barUpdate( playerid, fishkg ){

    new Float:currentProgressValue = GetPlayerProgressBarValue( playerid, p_fisherPullProgress[ playerid ] );

    SetPlayerProgressBarValue( playerid, p_fisherPullProgress[ playerid ], ( currentProgressValue-fishkg ) );

    return 1;
}

function TDUpdate( playerid ){

    new Float: oX, Float: oY, Float: oZ, Float: pX, Float: pY, Float: pZ, xyDistance;

    GetDynamicObjectPos( p_sharkObject[ playerid ], oX, oY, oZ );
    GetPlayerPos( playerid, pX, pY, pZ );
    xyDistance = floatround( floatsqroot( ( ( oX - pX ) * ( oX - pX ) ) + ( ( oY - pY ) * ( oY - pY ) ) ) );

    format( szNormalString, sizeof(szNormalString), "~b~Distance:~w~ %im~n~~b~Depth:~w~ %im", xyDistance, floatround( -oZ ) );
    PlayerTextDrawSetString( playerid, p_sharkLocTD[ playerid ], szNormalString );

    return 1;
}


/* Menu functions */

stock ShowFishingShopMenu( playerid ){
    return ShowPlayerDialog( playerid, DIALOG_FISHING_SHOP, DIALOG_STYLE_LIST, "Fishing", "Buy items\nUpgrade equipment\nSell fish", "Go", "Close" );
}

stock ShowFishingBuyingMenu( playerid ){
    format( szLargeString, sizeof ( szLargeString ), "Name\tPurpose\tPrice");
    for( new i = 0; i < 2; i++ ){
        format( szLargeString, sizeof( szLargeString ), "%s\n\%s\t"COL_ORANGE"%s\t"COL_GOLD"%i$", szLargeString, g_fishingShopData[ E_FISHING_SHOP_COMPONENTS: i ][ NAME ], g_fishingShopData[ E_FISHING_SHOP_COMPONENTS: i ][ PURPOSE ], g_fishingShopData[ E_FISHING_SHOP_COMPONENTS: i ][ PRICE ] );
    }
    return ShowPlayerDialog( playerid, DIALOG_FISHING_SHOP_ITEMS, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Fishing Items", szLargeString, "Buy", "Close" );
}

stock ShowFishingUpgradeMenu( playerid ){
    format( szLargeString, sizeof ( szLargeString ), "Upgrade\tPurpose\tPrice");
    new maxUpgradedID[ 4 ] = { 0, 0, 0, 0 };
    if( p_fishingItems[ playerid ][ ROD_UPGRADES ] == 2 )     maxUpgradedID[ 0 ] = 1;
    if( p_fishingItems[ playerid ][ BAIT_UPGRADES ] == 2 )    maxUpgradedID[ 1 ] = 1;
    if( p_fishingItems[ playerid ][ RADAR_UPGRADES ] == 2 )   maxUpgradedID[ 2 ] = 1;
    if( p_fishingItems[ playerid ][ STORAGE_UPGRADES ] == 2 ) maxUpgradedID[ 3 ] = 1;
    for( new i = 2; i < 6; i++ ){
        if( maxUpgradedID[ i - 2 ] == 1 ){
            format( szLargeString, sizeof( szLargeString ), "%s\n\%s\t"COL_ORANGE"%s\t"COL_GREEN"MAXED", szLargeString, g_fishingShopData[ E_FISHING_SHOP_COMPONENTS: i ][ NAME ], g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:i ][ PURPOSE ] );
        } else {
            format( szLargeString, sizeof( szLargeString ), "%s\n\%s\t"COL_ORANGE"%s\t"COL_GOLD"%i$", szLargeString, g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:i ][ NAME ], g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:i ][ PURPOSE ], g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:i ][ PRICE ] );
        }
    }
    return ShowPlayerDialog( playerid, DIALOG_FISHING_SHOP_UPGRADES, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Fishing Upgrades", szLargeString, "Upgrade", "Close" );
}

stock ShowFishingSellMenu( playerid ){
    format( szLargeString, sizeof ( szLargeString ), "Name\tAmount\tEach\tFinal");
    for( new i = 6; i < 8; i++ ){
        new final = g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:i ][ PRICE ] * p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS: i ];
        format( szLargeString, sizeof( szLargeString ), "%s\n\%s\t%i\t%i$\t"COL_GREEN"%i$", szLargeString, g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:i ][ NAME ], p_fishingItems[ playerid ][ E_FISHING_SHOP_COMPONENTS: i ], g_fishingShopData[ E_FISHING_SHOP_COMPONENTS:i ][ PRICE ], final );
    }
    return ShowPlayerDialog( playerid, DIALOG_FISHING_SHOP_SELL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Fishing Products", szLargeString, "Sell", "Close" );
}


/* Threads */

thread OnFishingLoadForPlayer( playerid ){
    new rows, fields;
    
    cache_get_data( rows, fields );

    if( rows ){
        p_fishingItems[ playerid ] [ BAITS ]            =   cache_get_field_content_int( 0, "BAITS",           dbHandle );
        p_fishingItems[ playerid ] [ HARPOONS ]         =   cache_get_field_content_int( 0, "HARPOONS",        dbHandle );
        p_fishingItems[ playerid ] [ ROD_UPGRADES ]     =   cache_get_field_content_int( 0, "ROD_UPGRADES",     dbHandle );
        p_fishingItems[ playerid ] [ BAIT_UPGRADES ]    =   cache_get_field_content_int( 0, "BAIT_UPGRADES",    dbHandle );
        p_fishingItems[ playerid ] [ RADAR_UPGRADES ]   =   cache_get_field_content_int( 0, "RADAR_UPGRADES",   dbHandle );
        p_fishingItems[ playerid ] [ STORAGE_UPGRADES ] =   cache_get_field_content_int( 0, "STORAGE_UPGRADES", dbHandle );
        p_fishingItems[ playerid ] [ SHARKS ]           =   cache_get_field_content_int( 0, "SHARKS",           dbHandle );
        p_fishingItems[ playerid ] [ FISH_KGS ]         =   cache_get_field_content_int( 0, "FISH_KGS",         dbHandle );
    }

    return 1;
}


/* Check functions */

stock IsPlayerOnBoat( playerid ){

    new Float: closest = 100.0, Float: distance, Float: x, Float: y, Float: z;

    GetPlayerPos( playerid, x, y, z );

    if( IsPlayerInAnyVehicle ( playerid ) ){
        new vehicleid = GetPlayerVehicleID( playerid );
        return ( IsVehicleBoat ( vehicleid ) );
    }

    for ( new i = 1; i <= MAX_VEHICLES; i++ ){
        distance = GetVehicleDistanceFromPoint( i, x, y, z );
        if ( distance < closest ) {
            closest = distance;
            p_closestVehID[ playerid ] = i;
        }
    }

    if( closest > 15.0 ) return false;

    return IsVehicleBoat( p_closestVehID[ playerid ] );
}

stock IsBoatMoving( playerid ){

    new Float: vX, Float: vY, Float: vZ, Float: speed;

    GetVehicleVelocity( p_closestVehID[ playerid ], vX, vY, vZ );

    speed = floatmul(floatsqroot(floatadd(floatadd(floatpower(vX, 2), floatpower(vY, 2)),  floatpower(vZ, 2))), 200.0);

    return ( speed < 5.0 ) ? true : false;

}

/*stock IsPlayerNearPier( playerid ){

    static const Float:fishingPoints[ ] [ ] =
	   {{ -1787.4955, 1545.6266, 7.1875 },
	    { -1625.5042, 1425.3771, 7.1813 },
	    { -1494.3604, 1285.3773, 7.1746 }};

    for ( new i = 0; i < sizeof( fishingPoints ); i++ ){
        if ( IsPlayerInRangeOfPoint( playerid, 20.0, fishingPoints[ i ] [ 0 ], fishingPoints [ i ] [ 1 ], fishingPoints [ i ] [ 2 ] ) ) {
     		return true;
        }
    }

    return false;
}*/

stock IsVehicleBoat( vehicleid ){

    static const Boats[ ] = { 472, 473, 493, 495, 484, 430, 453, 452, 446, 454, 595 };

    for ( new i = 0; i < sizeof ( Boats ); i++ ){
        if ( GetVehicleModel( vehicleid ) == Boats[ i ] ) return true;
    }

    return false;
}

function initializeFishingShopObjects(){
    //Fishing Shop
	SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1594.704956, 1284.060058, 1205.715942, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 5474, "idlewood46_lae", "dock1", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1594.704956, 1291.569946, 1205.715942, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 5474, "idlewood46_lae", "shingles2", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1594.704956, 1277.146972, 1205.715942, 0.000000, 0.000000, 90.000000, -1, -1, -1 ), 0, 5474, "idlewood46_lae", "shingles2", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1594.704956, 1284.060058, 1210.715942, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 5417, "idlewood6_tr", "metpat64", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1606.163940, 1279.578002, 1205.715942, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 5474, "idlewood46_lae", "shingles2", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 18981, -1591.010986, 1279.008056, 1205.715942, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 0, 5474, "idlewood46_lae", "shingles2", -16 );
    CreateDynamicObject( 1497, -1605.678955, 1282.843994, 1206.206054, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 1497, -1605.708984, 1285.855957, 1206.206054, 0.000000, 0.000000, 270.000000, -1, -1, -1 );
    CreateDynamicObject( 2068, -1595.604003, 1287.738037, 1209.735961, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 2068, -1603.755004, 1287.738037, 1209.735961, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 2068, -1595.535034, 1281.045043, 1209.735961, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 2068, -1603.715942, 1281.045043, 1209.735961, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
    CreateDynamicObject( 3761, -1605.217041, 1289.406982, 1207.375976, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
    tmpVariable = CreateDynamicObject( 2626, -1594.319946, 1283.306030, 1206.735961, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 6, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 4, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 2577, -1594.235961, 1285.348999, 1206.916015, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 3, 18202, "w_towncs_t", "plaintarmac1", 1 );
    CreateDynamicObject( 2404, -1601.239013, 1290.970947, 1207.446044, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 2405, -1601.989013, 1290.970947, 1207.446044, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 2406, -1603.301025, 1290.970947, 1207.446044, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 2410, -1602.552001, 1289.725952, 1206.244995, 0.000000, 0.000000, -150.399993, -1, -1, -1 );
    CreateDynamicObject( 2593, -1593.358032, 1279.790039, 1207.086059, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 2593, -1593.498046, 1288.678955, 1207.086059, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 2387, -1603.792968, 1278.947021, 1205.905029, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 10631, "queensammo_sfs", "ammu_camo1", -16 );
    tmpVariable = CreateDynamicObject( 2586, -1600.708984, 1283.928955, 1206.724975, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 5, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 8, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 9, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 10, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 11, 18202, "w_towncs_t", "plaintarmac1", 1 );
    tmpVariable = CreateDynamicObject( 2586, -1598.427978, 1283.928955, 1206.724975, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 8, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 9, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 10, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 11, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 5, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 3, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 4, 18202, "w_towncs_t", "plaintarmac1", 1 );
    tmpVariable = CreateDynamicObject( 2586, -1598.395996, 1284.691040, 1206.727050, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 8, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 9, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 10, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 11, 18202, "w_towncs_t", "plaintarmac1", 1 );
    tmpVariable = CreateDynamicObject( 2586, -1600.685058, 1284.692993, 1206.729003, 0.000000, 0.000000, 180.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 3, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 4, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 5, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 8, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 9, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 10, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 11, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 2387, -1604.340942, 1279.509033, 1205.896972, 0.000000, 0.000000, 0.000000, -1, -1, -1 ), 1, 10631, "queensammo_sfs", "ammu_camo1", -16 );
    tmpVariable = CreateDynamicObject( 2584, -1599.558959, 1287.833007, 1207.026000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 5, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 4, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 3, 18202, "w_towncs_t", "plaintarmac1", 1 );
    tmpVariable = CreateDynamicObject( 2584, -1599.558959, 1280.718994, 1207.026000, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 5, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 4, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( tmpVariable, 3, 18202, "w_towncs_t", "plaintarmac1", 1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19437, -1596.666992, 1291.791015, 1208.217041, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 9818, "ship_brijsfw", "CJ_WOOD1", -16 );
    CreateDynamicObject( 18632, -1598.058959, 1291.048950, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1597.558959, 1291.048950, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1597.058959, 1291.048950, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1596.558959, 1291.048950, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1596.058959, 1291.048950, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1595.558959, 1291.048950, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1595.058959, 1291.048950, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19437, -1596.666992, 1291.791015, 1206.665039, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 9818, "ship_brijsfw", "CJ_WOOD1", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19437, -1596.666992, 1276.925048, 1208.217041, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 9818, "ship_brijsfw", "CJ_WOOD1", -16 );
    CreateDynamicObject( 18632, -1598.058959, 1277.656982, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19437, -1596.666992, 1276.925048, 1206.675048, 0.000000, 90.000000, 0.000000, -1, -1, -1 ), 0, 9818, "ship_brijsfw", "CJ_WOOD1", -16 );
    CreateDynamicObject( 18632, -1597.558959, 1277.656982, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1597.058959, 1277.656982, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1596.558959, 1277.656982, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1596.058959, 1277.656982, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1595.558959, 1277.656982, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 18632, -1595.058959, 1277.656982, 1206.866943, 0.000000, -164.399993, 180.000000, -1, -1, -1 );
    CreateDynamicObject( 2590, -1604.593994, 1281.160034, 1210.557006, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 19468, -1604.392944, 1280.463989, 1206.314941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 19468, -1604.052978, 1280.833984, 1206.314941, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    tmpVariable = CreateDynamicObject( 16332, -1597.694946, 1284.233032, 1207.255981, 0.000000, 90.000000, -111.099998, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 16328, "des_quarrycrane", "ws_cranehook", -65536 );
    SetDynamicObjectMaterial( tmpVariable, 1, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    tmpVariable = CreateDynamicObject( 16332, -1597.937011, 1284.326049, 1207.245971, 0.000000, 90.000000, -111.099998, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 16328, "des_quarrycrane", "ws_cranehook", -65536 );
    SetDynamicObjectMaterial( tmpVariable, 1, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    tmpVariable = CreateDynamicObject( 16332, -1598.228027, 1284.234008, 1207.245971, 0.000000, 90.000000, -111.099998, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 16328, "des_quarrycrane", "ws_cranehook", -65536 );
    SetDynamicObjectMaterial( tmpVariable, 1, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    tmpVariable = CreateDynamicObject( 16332, -1598.487060, 1284.227050, 1207.245971, 0.000000, 90.000000, -111.099998, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 16328, "des_quarrycrane", "ws_cranehook", -65536 );
    SetDynamicObjectMaterial( tmpVariable, 1, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    tmpVariable = CreateDynamicObject( 16332, -1598.926025, 1284.224975, 1207.245971, 0.000000, 90.000000, -111.099998, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 16328, "des_quarrycrane", "ws_cranehook", -65536 );
    SetDynamicObjectMaterial( tmpVariable, 1, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    tmpVariable = CreateDynamicObject( 16332, -1599.165039, 1284.241943, 1207.245971, 0.000000, 90.000000, -111.099998, -1, -1, -1 );
    SetDynamicObjectMaterial( tmpVariable, 0, 16328, "des_quarrycrane", "ws_cranehook", -65536 );
    SetDynamicObjectMaterial( tmpVariable, 1, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    SetDynamicObjectMaterial( tmpVariable, 2, 16328, "des_quarrycrane", "ws_cranehook", 1 );
    CreateDynamicObject( 18641, -1597.744995, 1283.980957, 1207.046020, 0.000000, 90.000000, -126.800003, -1, -1, -1 );
    CreateDynamicObject( 18641, -1598.909057, 1284.662963, 1207.046020, 0.000000, 90.000000, -126.800003, -1, -1, -1 );
    CreateDynamicObject( 18641, -1599.214965, 1283.968994, 1207.046020, 0.000000, 90.000000, 51.000000, -1, -1, -1 );
    CreateDynamicObject( 18641, -1601.293945, 1284.006958, 1207.046020, 0.000000, 90.000000, 113.400001, -1, -1, -1 );
    CreateDynamicObject( 18634, -1600.597045, 1284.592041, 1207.046020, 0.000000, 90.000000, 54.099998, -1, -1, -1 );
    CreateDynamicObject( 18634, -1598.654052, 1283.913940, 1207.046020, 0.000000, 90.000000, -96.000000, -1, -1, -1 );
    CreateDynamicObject( 18945, -1593.641967, 1279.812011, 1207.079956, -91.900001, 0.000000, 173.600006, -1, -1, -1 );
    CreateDynamicObject( 18951, -1593.349975, 1280.133056, 1207.802001, -84.500000, 0.000000, 81.800003, -1, -1, -1 );
    CreateDynamicObject( 18969, -1593.302001, 1279.593994, 1207.826049, 0.000000, -76.300003, 73.800003, -1, -1, -1 );
    CreateDynamicObject( 18967, -1593.744995, 1288.708007, 1207.468017, 0.000000, -83.099998, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 19109, -1593.472045, 1288.697021, 1207.936035, -10.500000, -90.199996, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 18968, -1593.496948, 1288.932006, 1207.110961, 0.000000, -87.599998, -100.900001, -1, -1, -1 );
    CreateDynamicObject( 18946, -1593.458007, 1288.468994, 1206.683959, 91.500000, -0.699999, -90.300003, -1, -1, -1 );
    CreateDynamicObject( 2099, -1591.906982, 1290.767944, 1206.224975, 0.000000, 0.000000, -40.099998, -1, -1, -1 );
    CreateDynamicObject( 19167, -1599.557006, 1287.805053, 1207.395996, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 19815, -1591.527954, 1286.463989, 1208.327026, 0.000000, 0.000000, -90.000000, -1, -1, -1 );
    CreateDynamicObject( 2192, -1591.787963, 1278.423950, 1206.204956, 0.000000, 0.000000, 42.400001, -1, -1, -1 );
    CreateDynamicObject( 16779, -1593.437988, 1284.238037, 1210.288940, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 16779, -1599.369995, 1284.238037, 1210.288940, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 358, -1600.110961, 1284.369018, 1207.215942, 82.900001, -103.699996, -124.000000, -1, -1, -1 );
    CreateDynamicObject( 358, -1600.833007, 1284.093994, 1207.220947, 82.900001, -103.699996, -124.000000, -1, -1, -1 );
    CreateDynamicObject( 358, -1601.332031, 1283.927001, 1207.218994, 82.900001, -103.699996, -124.000000, -1, -1, -1 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19583, -1599.156005, 1284.083007, 1207.225952, 0.000000, 0.000000, -15.899999, -1, -1, -1 ), 0, 1676, "wshxrefpump", "black64", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19583, -1598.911987, 1284.066040, 1207.225952, 0.000000, 0.000000, -15.899999, -1, -1, -1 ), 0, 1676, "wshxrefpump", "black64", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19583, -1598.646972, 1284.042968, 1207.225952, 0.000000, 0.000000, -15.899999, -1, -1, -1 ), 0, 1676, "wshxrefpump", "black64", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19583, -1598.031982, 1284.088012, 1207.225952, 0.000000, 0.000000, -15.899999, -1, -1, -1 ), 0, 1676, "wshxrefpump", "black64", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19583, -1597.639038, 1284.081054, 1207.225952, 0.000000, 0.000000, -15.899999, -1, -1, -1 ), 0, 1676, "wshxrefpump", "black64", -16 );
    SetDynamicObjectMaterial( CreateDynamicObject( 19583, -1597.484008, 1284.037963, 1207.225952, 0.000000, 0.000000, -15.899999, -1, -1, -1 ), 0, 1676, "wshxrefpump", "black64", -16 );
    CreateDynamicObject( 630, -1600.743041, 1277.921997, 1207.225952, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 630, -1605.154052, 1281.812988, 1207.225952, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 630, -1593.703002, 1278.120971, 1207.225952, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 630, -1593.703002, 1290.641967, 1207.225952, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 630, -1599.582031, 1290.641967, 1207.225952, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 2048, -1591.556030, 1282.228027, 1208.487060, 0.000000, 20.299999, -90.000000, -1, -1, -1 );
    CreateDynamicObject( 2855, -1599.458007, 1280.682006, 1207.306030, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 2854, -1599.557983, 1280.753051, 1206.806030, 0.000000, 0.000000, 0.000000, -1, -1, -1 );
    CreateDynamicObject( 2813, -1599.562011, 1287.829956, 1207.046020, 0.000000, 0.000000, -101.599998, -1, -1, -1 );
    CreateDynamicObject( 19618, -1594.232055, 1282.853027, 1206.675048, 0.000000, 0.000000, 90.000000, -1, -1, -1 );
    return 1;
}