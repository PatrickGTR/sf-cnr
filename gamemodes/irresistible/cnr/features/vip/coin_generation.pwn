/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\vip\happy_hour.pwn
 * Purpose: coin generation ("proof of playing") mechanism
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined __cnr__irresistiblecoins
	#endinput
#endif

/* ** Variables ** */
static stock
 	bool: g_HappyHour				= false,
 	Float: g_HappyHourRate			= 0.0
;

/* ** Hooks ** */
hook OnServerUpdate( )
{
    new Float: fLastRate;
 	new playersOnline = Iter_Count(Player);

 	// Happy Hour
	if ( ( g_HappyHour = playersOnline <= 20 ) == true ) {
		// Maximum of 25% decrease
		g_HappyHourRate = 0.25 - ( playersOnline / 80.0 );

		// Only update colors if neccessary
		if ( fLastRate != g_HappyHourRate )
		{
			TextDrawSetString( g_NotManyPlayersTD, sprintf( "Coin generation increased by %0.1f%% as there aren't many players online!", g_HappyHourRate * 100.0 ) );
			TextDrawColor( g_NotManyPlayersTD, setAlpha( COLOR_RED, floatround( 200.0 - 10.0 * float( playersOnline ) ) ) );
			TextDrawShowForAllSpawned( g_NotManyPlayersTD );
		}

		// Update last rate
		fLastRate = g_HappyHourRate;
	} else {
		 // Disable Color
		g_HappyHourRate = 0.0;
		TextDrawColor( g_NotManyPlayersTD, 0 );
		TextDrawHideForAll( g_NotManyPlayersTD );
	}
	return 1;
}

hook OnPlayerTickSecond( playerid )
{
    static
    	iKeys, iUpDownKeys, iLeftRightKeys;

	// Increase Irresistible Coins (1/20 = cred/min)
	if ( ! IsPlayerAFK( playerid ) && GetPlayerKeys( playerid, iKeys, iUpDownKeys, iLeftRightKeys ) && ! IsPlayerOnRoulette( playerid ) && ! IsPlayerOnSlotMachine( playerid ) && GetPlayerVehicleSeat( playerid ) <= 0 )
	{
		if ( iKeys != 0 || iUpDownKeys != 0 || iLeftRightKeys != 0 ) { // GetPlayerScore( playerid ) > 10 &&

			new
				Float: iCoinGenRate = 35.0;

			// VIP check
			if ( p_VIPLevel[ playerid ] >= VIP_DIAMOND )
				iCoinGenRate *= 0.75; // Reduce by 25% if Diamond

			else if ( p_VIPLevel[ playerid ] == VIP_PLATINUM )
				iCoinGenRate *= 0.90; // Reduce by 10% if Diamond

			// Happy Hour
			if ( g_HappyHour && ( 0.0 <= g_HappyHourRate <= 0.25 ) )
				iCoinGenRate *= 1.0 - g_HappyHourRate;

			GivePlayerIrresistibleCoins( playerid, ( 1.0 / iCoinGenRate ) / 60.0 ); // Prev 25.92
		}
	}
	return 1;
}

hook OnPlayerLoadTextdraws( playerid ) {
	if ( g_HappyHour ) {
        TextDrawShowForPlayer( playerid, g_NotManyPlayersTD );
    }
    return 1;
}

hook OnPlayerUnloadTextdraws( playerid ) {
	TextDrawHideForPlayer( playerid, g_NotManyPlayersTD );
    return 1;
}

/* ** Functions ** */
