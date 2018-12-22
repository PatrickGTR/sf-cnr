/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\eastereggs.pwn
 * Purpose: treasure (easter eggs) hunting system
 */

/* ** Error checking ** */
#if !defined __cnr__eastereggs
	#define __cnr__eastereggs
#else
	#endinput
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define EASTEREGG_LABEL 			"[EASTER EGG]"
#define EASTEREGG_NAME 				"Easter Egg"
#define EASTEREGG_MODEL 			randarg( 19341, 19342, 19343, 19344, 19345 )
#define MAX_EGGS 					( 4 )

/* ** Variables ** */
enum E_EASTEREGG_DATA
{
	Float: E_X,     		Float: E_Y,			Float: E_Z,
	E_PICK_UP, 				Text3D: E_LABEL
};

new
	g_EasterEggs                    [ MAX_EGGS ] [ E_EASTEREGG_DATA ],
	Iterator: eastereggs 			< MAX_EGGS >,
	bool: g_EasterHunt              = false
;

/* ** Hooks ** */
hook OnPlayerUpdateEx( playerid )
{
	// Easter Egg Hunt
	if ( ! GetPlayerAdminLevel( playerid ) )
	{
		if ( g_EasterHunt )
		{
			foreach(new easterid : eastereggs)
			{
				if ( IsPlayerInRangeOfPoint( playerid, 2.0, g_EasterEggs[ easterid ] [ E_X ], g_EasterEggs[ easterid ] [ E_Y ], g_EasterEggs[ easterid ] [ E_Z ] ) )
				{
				    new
				    	iMoney, Float: iCoins, szPrize[ 16 ];

					switch( random( 4 ) )
					{
					    case 0:
					    {
					    	szPrize = "a home";
							AddPlayerNote( playerid, -1, ""COL_GOLD"Treasure Hunt Home" #COL_WHITE );
					    	SendClientMessage( playerid, -1, ""COL_GOLD"[HOUSE]"COL_GREY" You have won a house, contact a level 5 admin to redeem a house at a favourable location." );
					    }
					    case 1:
					    {
					    	szPrize = "a car";
							AddPlayerNote( playerid, -1, ""COL_GOLD"Treasure Hunt Car" #COL_WHITE );
					    	SendClientMessage( playerid, -1, ""COL_GOLD"[CAR]"COL_GREY" You have won a car, contact a level 5 admin to redeem a car of your choice!" );
					    }
					    case 2:
					    {
					    	GivePlayerCash( playerid, ( iMoney = RandomEx( 600000, 1500000 ) ) );
					    	format( szPrize, sizeof( szPrize ), "%s", cash_format( iMoney ) );
					    }
					    case 3:
					    {
					    	p_IrresistibleCoins[ playerid ] += ( iCoins = fRandomEx( 75.0, 250.0 ) );
					    	format( szPrize, sizeof( szPrize ), "%0.2f coins", iCoins );
					    }
					}

		            DestroyEasterEgg( easterid );
		            SendGlobalMessage( -1, ""COL_GOLD""#EASTEREGG_LABEL""COL_WHITE" %s(%d) has found a " #EASTEREGG_NAME " and has won "COL_GOLD"%s{FFFFFF}.", ReturnPlayerName( playerid ), playerid, szPrize );

					if ( !Iter_Count(eastereggs) )
					{
					    g_EasterHunt = false;
						SendClientMessage( playerid, -1, ""COL_PINK"[ADMIN]"COL_GOLD" Treasure Hunt has been de-activated. All " #EASTEREGG_NAME "s were found." );
					}
					break;
				}
			}
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:treasures( playerid, params[ ] )
{
	new
		count = Iter_Count( eastereggs );

	if ( ! g_EasterHunt )
		return SendError( playerid, "Treasure Hunt isn't activated thus this feature is disabled." );

 	if ( !count ) {
 		return SendServerMessage( playerid, "There are no " #EASTEREGG_NAME "s currently planted." ), 1;
 	} else {
 		return SendServerMessage( playerid, "There are %d " #EASTEREGG_NAME "(s) currently planted at the moment.", count ), 1;
 	}
}

CMD:setegg( playerid, params[ ] )
{
	if ( !IsPlayerAdmin( playerid ) )
		return 0;

	if ( g_EasterHunt )
		return SendError( playerid, "The " #EASTEREGG_NAME " hunt has already started." );

	new
	    Float: X, Float: Y, Float: Z;

	GetPlayerPos( playerid, X, Y, Z );

	if ( CreateEasterEgg( X, Y, Z ) != -1 ) {
		AddAdminLogLineFormatted( "%s(%d) has set a " #EASTEREGG_NAME "", ReturnPlayerName( playerid ), playerid );
		return SendServerMessage( playerid, "Planted " #EASTEREGG_NAME " at your current position." ), 1;
	} else {
		return SendError( playerid, "There isn't enough room for another " #EASTEREGG_NAME "." ), 1;
	}
}

CMD:treasurehunt( playerid, params[ ] )
{
	if ( !IsPlayerAdmin( playerid ) )
		return 0;

	if ( Iter_Count( eastereggs ) < 1 )
		return SendError( playerid, "There are not enough " #EASTEREGG_NAME "s planted to start the treasure hunt." );

	// if its false, destroy all egs
	if ( ( g_EasterHunt = ! g_EasterHunt ) == false )
    {
		for ( new i = 0; i < MAX_EGGS; i ++)
			DestroyEasterEgg( i );
    }

    // alert admin log
	AddAdminLogLineFormatted( "%s(%d) has started a treasurehunt", ReturnPlayerName( playerid ), playerid );
    SendClientMessageFormatted( playerid, -1, ""COL_PINK"[ADMIN]"COL_GOLD" Treasure Hunt has been %s", g_EasterHunt == true ? ("activated, look around for " #EASTEREGG_NAME "s and get a free gift.") : ("de-activated.") );
	return 1;
}

/* ** Functions ** */
stock DestroyEasterEgg( id )
{
	if ( !( 0 <= id < MAX_EGGS ) )
		return 0;

	Iter_Remove(eastereggs, id);
    DestroyDynamicPickup( g_EasterEggs[ id ] [ E_PICK_UP ] );
    DestroyDynamic3DTextLabel( g_EasterEggs[ id ] [ E_LABEL ] );
	return 1;
}

stock CreateEasterEgg( Float: X, Float: Y, Float: Z )
{
	new
	    ID = Iter_Free(eastereggs);

	if ( ID != ITER_NONE ) {
		Iter_Add( eastereggs, ID );
	    g_EasterEggs[ ID ] [ E_X ] = X;
	    g_EasterEggs[ ID ] [ E_Y ] = Y;
	    g_EasterEggs[ ID ] [ E_Z ] = Z;
	    g_EasterEggs[ ID ] [ E_PICK_UP ] = CreateDynamicPickup( EASTEREGG_MODEL, 1, X, Y, Z );
	    g_EasterEggs[ ID ] [ E_LABEL ] = CreateDynamic3DTextLabel( EASTEREGG_LABEL, COLOR_GOLD, X, Y, Z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0 );
	}
	return ID;
}
