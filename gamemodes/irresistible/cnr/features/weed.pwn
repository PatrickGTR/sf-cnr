/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\weed.pwn
 * Purpose: weed growing system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_WEED                    ( 64 )
#define MAX_WEED_STORAGE 			( 25 )

#define WEED_REQUIRED_GROW_TIME 	( 600 )

/* ** Variables ** */
enum E_WEED_DATA
{
	E_OBJECT,       	Text3D: E_LABEL,		E_GROW_TIME,
	E_USER_ID,			E_MAP_ICON,

	Float: E_X,         Float: E_Y,     		Float: E_Z
};

static stock
	g_weedData                      [ MAX_WEED ] [ E_WEED_DATA ],
	Iterator: weedplants 			< MAX_WEED >
;

/* ** Hooks ** */
hook OnServerUpdate( )
{
	new
		server_time = GetServerTime( );

	foreach ( new weedid : weedplants ) if ( g_weedData[ weedid ] [ E_GROW_TIME ] != 0 )
	{
		if ( g_weedData[ weedid ] [ E_GROW_TIME ] > server_time )
		{
			new
				Float: percentage = 100.0 - ( float( g_weedData[ weedid ] [ E_GROW_TIME ] - server_time ) / float( WEED_REQUIRED_GROW_TIME ) ) * 100.0;

			UpdateDynamic3DTextLabelText( g_weedData[ weedid ] [ E_LABEL ], COLOR_GREEN, sprintf( "%s's Weed Plant\n"COL_WHITE"%0.1f%% Grown", ReturnPlayerName( g_weedData[ weedid ] [ E_USER_ID ] ), percentage ) );
		}
		else
		{
			new
				growerid = g_weedData[ weedid ] [ E_USER_ID ];

			if ( IsPlayerConnected( growerid ) ) {
				SendServerMessage( growerid, "One of your weed plants have completed growing!" );
			}

			UpdateDynamic3DTextLabelText( g_weedData[ weedid ] [ E_LABEL ], COLOR_GREEN, sprintf( "%s's Weed Plant\n"COL_GREY"Press LALT To Grab", ReturnPlayerName( g_weedData[ weedid ] [ E_USER_ID ] ) ) );
			g_weedData[ weedid ] [ E_GROW_TIME ] = 0;
		}
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	Weed_RemovePlayerPlants( playerid );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_WALK ) )
	{
		new
			player_class = GetPlayerClass( playerid );

		foreach ( new weedid : weedplants ) if ( IsPlayerInRangeOfPoint( playerid, 3.0, g_weedData[ weedid ] [ E_X ], g_weedData[ weedid ] [ E_Y ], g_weedData[ weedid ] [ E_Z ] ) )
		{
			if ( ! g_weedData[ weedid ] [ E_GROW_TIME ] )
			{
				if ( player_class != CLASS_POLICE )
				{
					if ( g_weedData[ weedid ] [ E_USER_ID ] != playerid )
					{
						SendServerMessage( g_weedData[ weedid ] [ E_USER_ID ], "%s(%d) has stolen a gram of weed from your plant!", ReturnPlayerName( playerid ), playerid );
					}
					GivePlayerWantedLevel( playerid, 6 ); // give wanted level to police
				}

				p_WeedGrams[ playerid ] ++;
				SendServerMessage( playerid, "You have collected a gram of "COL_GREEN"weed"COL_WHITE"." );

				Weed_RemovePlant( weedid );
			}
			else if ( player_class == CLASS_POLICE )
			{
				new
					weed_seed_cost = GetShopItemCost( SHOP_ITEM_WEED_SEED );

				GivePlayerCash( playerid, weed_seed_cost );
				GivePlayerExperience( playerid, E_POLICE, 0.5 );
				SendServerMessage( playerid, "You have destroyed a "COL_GREEN"weed"COL_WHITE" plant for "COL_GOLD"%s"COL_WHITE".", cash_format( weed_seed_cost ) );

				Weed_RemovePlant( weedid );
			}
			break;
		}
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:weed( playerid, params[ ] )
{
	new
		Float: X, Float: Y, Float: Z
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You are not a civilian." );

	if ( IsPlayerTied( playerid ) || IsPlayerTazed( playerid ) || IsPlayerCuffed( playerid ) || IsPlayerJailed( playerid ) || IsPlayerInMinigame( playerid ) )
		return SendError( playerid, "You cannot use this command at the moment." );

	if ( strmatch( params, "plant" ) )
	{
		if ( ! IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "You are not a drug dealer." );
		//if ( p_WeedGrams[ playerid ] >= MAX_WEED_STORAGE ) return SendError( playerid, "You can only carry %d grams of weed.", MAX_WEED_STORAGE );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You mustn't be inside a vehicle while collecting weed." );
		if ( GetPlayerVirtualWorld( playerid ) != 0 && GetPlayerInterior( playerid ) != 0 ) return SendError( playerid, "You cannot use this inside an interior." );
		if ( ! GetPlayerShopItemAmount( playerid, SHOP_ITEM_WEED_SEED ) ) return SendError( playerid, "You don't have any weed seeds to plant." );

		new planted_weed = Weed_GetPlayerWeedPlants( playerid );
		new planted_weed_limit = Weed_GetPlantLimit( playerid );

		if ( planted_weed >= planted_weed_limit ) {
			return SendError( playerid, "You can only plant %d plants at a time.", planted_weed_limit );
		}

		GetPlayerPos( playerid, X, Y, Z );
		MapAndreas_FindZ_For2DCoord( X, Y, Z );

		foreach ( new weedid : weedplants ) {
			if ( IsPointToPoint( 2.0, g_weedData[ weedid ] [ E_X ], g_weedData[ weedid ] [ E_Y ], g_weedData[ weedid ] [ E_Z ], X, Y, Z ) ) {
				return SendError( playerid, "You cannot plant a weed plant too near to one." );
			}
		}

		if ( Weed_CreatePlant( playerid, X, Y, Z ) != ITER_NONE ) {
			GivePlayerWantedLevel( playerid, 2 );
			GivePlayerShopItem( playerid, SHOP_ITEM_WEED_SEED, -1 );
			return SendServerMessage( playerid, "You have planted weed. It will take %s to grow.", secondstotime( WEED_REQUIRED_GROW_TIME ) );
		} else {
			return SendError( playerid, "You cannot create a weed plant at the moment, try again later." );
		}
	}
	else if ( !strcmp( params, "sell", false, 4 ) )
	{
	    new pID, iAmount, iCost;

		if ( !IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "You are not a drug dealer." );
	    else if ( p_SellingWeedTick[ playerid ] > g_iTime ) return SendError( playerid, "You must wait a minute before selling weed again." );
		else if ( !p_WeedGrams[ playerid ] ) return SendError( playerid, "You don't have any weed with you." );
	    else if ( sscanf( params[ 5 ], "udd", pID, iAmount, iCost ) ) return SendUsage( playerid, "/weed sell [PLAYER_ID] [GRAMS] [PRICE]" );
	    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	    else if ( pID == playerid ) return SendError( playerid, "You cannot sell yourself weed." );
		else if ( p_Class[ pID ] != CLASS_CIVILIAN ) return SendError( playerid, "This person is not a civilian." );
		else if ( iAmount > p_WeedGrams[ playerid ] ) return SendError( playerid, "You only have %d grams of weed on you.", p_WeedGrams[ playerid ] );
		else if ( iAmount < 1 || iAmount > 25 ) return SendError( playerid, "You can only sell between 1 to 25 grams of weed to a player." );
		else if ( iCost < 0 || iCost > 100000 ) return SendError( playerid, "Price must be between 0 and 100000." );
	    else if ( GetDistanceBetweenPlayers( playerid, pID ) < 5.0 )
	    {
			if ( GetPlayerCash( pID ) < iCost ) return SendError( playerid, "This person doesn't have enough money." );

			p_WeedDealer[ pID ] = playerid;
			p_WeedTick[ pID ] = GetServerTime( ) + 120;
			p_WeedSellingGrams[ pID ] = iAmount;
			p_WeedSellingPrice[ pID ] = iCost;
			p_SellingWeedTick[ playerid ] = g_iTime + 60;
			SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} %s(%d) is selling you %d gram(s) of weed for %s. "COL_ORANGE"/weed buy"COL_WHITE" to buy.", ReturnPlayerName( playerid ), playerid, iAmount, cash_format( iCost ) );
			SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} You have sent an offer to %s(%d) to buy a %d gram(s) of weed for "COL_GOLD"%s.", ReturnPlayerName( pID ), pID, iAmount, cash_format( iCost ) );
	 		return 1;
	    }
	    else
	    {
	    	return SendError( playerid, "This player is not nearby." );
	    }
	}
	else if ( strmatch( params, "buy" ) )
	{
	    if ( !IsPlayerConnected( p_WeedDealer[ playerid ] ) ) return SendError( playerid, "Your dealer isn't connected anymore." );
		else if ( GetServerTime( ) > p_WeedTick[ playerid ] ) return p_WeedDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, each deal goes for 2 minutes maximum. You were late." );
		else
		{
		    new
		    	dealerid = p_WeedDealer[ playerid ],
		    	iGrams 	 = p_WeedSellingGrams[ playerid ],
		    	iCost 	 = p_WeedSellingPrice[ playerid ]
		    ;

			if ( GetPlayerCash( playerid ) < iCost ) return SendError( playerid, "You need %s to buy %d grams of weed.", cash_format( iCost ), iGrams );
			else if ( IsPlayerInPaintBall( dealerid ) || IsPlayerDueling( dealerid ) ) return SendError( playerid, "Your dealer cannot deal in an arena." );
			else if ( p_Class[ dealerid ] != CLASS_CIVILIAN ) return p_WeedDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, the dealer is not a civilian." );
			else if ( !IsPlayerJob( dealerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "Your dealer no longer does drugs." );
			else if ( !p_WeedGrams[ dealerid ] ) return p_WeedDealer[ playerid ] = INVALID_PLAYER_ID,  SendError( playerid, "Your dealer doesn't have any more weed." );
			//else if ( ( p_WeedGrams[ playerid ] + iGrams ) > MAX_WEED_STORAGE ) return SendError( playerid, "You can only carry %d grams of weed.", MAX_WEED_STORAGE );
			else
			{
	         	p_WeedGrams[ playerid ] += iGrams;
	         	p_WeedGrams[ dealerid ] -= iGrams;

				GivePlayerCash( playerid, -iCost );
				GivePlayerCash( dealerid, iCost );

				SendClientMessageFormatted( dealerid, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} %s(%d) has bought %d grams of weed off you for %s.", ReturnPlayerName( playerid ), playerid, iGrams, cash_format( iCost ) );
				SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DRUG DEAL]{FFFFFF} You have bought %d grams of weed for %s.", iGrams, cash_format( iCost ) );

				GivePlayerWantedLevel( dealerid, 6 );
				GivePlayerWantedLevel( playerid, 6 );

				Beep( dealerid );
				p_WeedDealer[ playerid ] = INVALID_PLAYER_ID;
			}
		}
		return 1;
	}
	else if ( strmatch( params, "use" ) )
	{
    	if ( GetPVarInt( playerid, "weed_timestamp" ) > g_iTime ) return SendError( playerid, "You must wait at least %d seconds before using this command.", GetPVarInt( playerid, "weed_timestamp" ) - g_iTime );
		if ( p_WeedGrams[ playerid ] < 1 ) return SendError( playerid, "You don't have any weed with you." );
		if ( p_Jailed{ playerid } == true ) return SendError( playerid, "You cannot use this in jail." );
		if ( IsPlayerLoadingObjects( playerid ) ) return SendError( playerid, "You're in a object-loading state, please wait." );
		if ( IsPlayerAttachedObjectSlotUsed( playerid, 0 ) ) return SendError( playerid, "You cannot use this command since you're robbing." );
		// if ( IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "You cannot use your own products, they are for resale only!" );
		if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
		//if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command in a vehicle." );
	    //if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER || GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_PASSENGER ) return SendError( playerid, "You cannot use this command if you're entering a vehicle." );
	    //if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE ) return SendError( playerid, "You cannot use this command if you're exiting a vehicle." );
		//if ( p_InAnimation{ playerid } || GetPlayerSpecialAction( playerid ) != SPECIAL_ACTION_NONE ) return SendError( playerid, "You cannot use this command since you're in animation." );
		SetPVarInt( playerid, "weed_timestamp", g_iTime + 120 );
		p_WeedGrams[ playerid ] --;
		SetPlayerHealth( playerid, 150 );
		SetPlayerDrunkLevel( playerid, 5000 );
		SendServerMessage( playerid, "You have smoked a gram of weed." );
		DestroyDynamic3DTextLabel( p_WeedLabel[ playerid ] );
	    p_WeedLabel[ playerid ] = CreateDynamic3DTextLabel( "Blazed W33D Recently!", COLOR_GREEN, X, Y, Z + 1.0, 15, playerid );
		//ApplyAnimation( playerid, "GANGS", "smkcig_prtl", 4.1, 0, 1, 1, 0, 0, 1 );
		return 1;
	}
	else
	{
		return SendUsage( playerid, "/weed [PLANT/SELL/BUY/USE]" ), 1;
	}
}

/* ** Functions ** */
stock Weed_CreatePlant( playerid, Float: X, Float: Y, Float: Z, required_time = WEED_REQUIRED_GROW_TIME )
{
	new
		weedid = Iter_Free( weedplants );

	if ( weedid != ITER_NONE )
	{
		static const Float: WEED_LOWER_OFFSET = 1.50; // put it 1.5m into the ground
		static const Float: WEED_RAISE_OFFSET = 0.35; // then raise it 0.35m to grow

		g_weedData[ weedid ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "%s's Weed Plant\n"COL_WHITE"0.0%% Grown", ReturnPlayerName( playerid ) ), COLOR_GREEN, X, Y, Z + 0.5, 30.0 );
		g_weedData[ weedid ] [ E_OBJECT ] = CreateDynamicObject( 19473, X, Y, Z - WEED_LOWER_OFFSET, 0.0, 0.0, 0.0 );
		g_weedData[ weedid ] [ E_MAP_ICON ] = CreateDynamicMapIcon( X, Y, Z, 0, COLOR_GREEN, -1, -1, -1, 250.0 );
		g_weedData[ weedid ] [ E_GROW_TIME ] = GetServerTime( ) + required_time;
		g_weedData[ weedid ] [ E_USER_ID ] = playerid;
		g_weedData[ weedid ] [ E_X ] = X;
		g_weedData[ weedid ] [ E_Y ] = Y;
		g_weedData[ weedid ] [ E_Z ] = Z;

		Streamer_Update( playerid );
		MoveDynamicObject( g_weedData[ weedid ] [ E_OBJECT ], X, Y, Z + WEED_RAISE_OFFSET, ( WEED_LOWER_OFFSET + WEED_RAISE_OFFSET ) / float( required_time ) );

		Iter_Add( weedplants, weedid );
	}
	return weedid;
}

stock Weed_RemovePlant( weedid )
{
	DestroyDynamicObject( g_weedData[ weedid ] [ E_OBJECT ] );
	g_weedData[ weedid ] [ E_OBJECT ] = INVALID_OBJECT_ID;

	DestroyDynamic3DTextLabel( g_weedData[ weedid ] [ E_LABEL ] );
	g_weedData[ weedid ] [ E_LABEL ] = Text3D: INVALID_3DTEXT_ID;

	DestroyDynamicMapIcon( g_weedData[ weedid ] [ E_MAP_ICON ] );
	g_weedData[ weedid ] [ E_MAP_ICON ] = -1;

	Iter_Remove( weedplants, weedid );
	return 1;
}

stock Weed_RemovePlayerPlants( playerid ) {
	for ( new weedid = 0; weedid < sizeof( g_weedData ); weedid ++ ) if ( g_weedData[ weedid ] [ E_USER_ID ] == playerid ) {
		Weed_RemovePlant( weedid );
	}
}

stock Weed_GetPlayerWeedPlants( playerid )
{
	new
		count = 0;

	foreach ( new weedid : weedplants ) if ( g_weedData[ weedid ] [ E_USER_ID ] == playerid ) {
		count ++;
	}
	return count;
}

stock Weed_GetPlantLimit( playerid )
{
	new
		vip_level = GetPlayerVIPLevel( playerid );

	if ( vip_level >= VIP_GOLD ) {
		return 15;
	}
	else if ( vip_level >= VIP_BRONZE ) {
		return 10;
	}
	else {
		return 5;
	}
}
