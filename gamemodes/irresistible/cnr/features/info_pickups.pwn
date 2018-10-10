/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\info_pickups.pwn
 * Purpose: informational pickups located between features
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
enum E_INFO_PICKUP_DATA
{
	Float: E_X,					Float: E_Y, 				Float: E_Z,
	E_PICKUP_ID,				E_TEXT[ 128 ]
};

static stock
	g_informationPickupsData 		[ ] [ E_INFO_PICKUP_DATA ] =
	{
		{ -2118.1787, -77.9626, 35.3203, 0xFFFF, "{FFFFFF}Over here, you are able to complete trucking missions by attaching a trailer to your truck then going to /work!" }, 		// Trucking
		{ -2025.9523, -136.965, 35.2906, 0xFFFF, "{FFFFFF}Ever felt like breaking bad? Enter an RV as a passenger and begin to produce meth! Make sure you have the materials!" }, 	// Meth
		{ -1497.1375, 914.6858, 7.18750, 0xFFFF, "{FFFFFF}All civilians should bank their money, for their own protection and to save some money from tax!" }, 						// Bank
		{ -2450.2261, 752.2170, 35.1719, 0xFFFF, "{FFFFFF}Buy materials that can help you complete missions such as meth production, or buy other neccessary items!" }, 			// Supa
		{ -1589.4668, 115.8173, 3.54950, 0xFFFF, "{FFFFFF}Dirty Mechanics can export vehicles and receive money based on the material that can be taken from a vehicle!" },	 		// Car Jacker
		{ -2767.3765, 1257.077, 11.7703, 0xFFFF, "{FFFFFF}You can mine ores and store your ores in dunes for exportation! Grab the spade and hit the ore!" },						// Mining
		{ 1954.71890, 1038.251, 992.859, 0xFFFF, "{FFFFFF}Test out your luck on the slot machines, maybe you might win the mega jackpot!" },										// Slots
		{ 1955.69070, 1005.167, 992.468, 0xFFFF, "{FFFFFF}Roulette can payout up to $3.5M! Single bets return 35x your money whereas outside bets can return 2x to 3x!" },			// Roulette
		{ 2085.5896, 1239.4589, 414.745, 0xFFFF, "{FFFFFF}Buy materials at a co-nvience store and cook meth! Aim and shoot each ingredient to add them as you /meth cook!" } 		// Meth Cook
	}
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	for( new i = 0; i < sizeof( g_informationPickupsData ); i++ )
	{
		g_informationPickupsData[ i ] [ E_PICKUP_ID ] = CreateDynamicPickup( 1239, 2, g_informationPickupsData[ i ] [ E_X ], g_informationPickupsData[ i ] [ E_Y ], g_informationPickupsData[ i ] [ E_Z ] );

		// dont need map icons for interior infos
		if ( g_informationPickupsData[ i ] [ E_Z ] < 800.0 ) {
			CreateDynamicMapIcon( g_informationPickupsData[ i ] [ E_X ], g_informationPickupsData[ i ] [ E_Y ], g_informationPickupsData[ i ] [ E_Z ], 37, 0, -1, -1, -1, 50.0 );
		}
	}
	return 1;
}

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
	for( new i = 0; i < sizeof( g_informationPickupsData ); i++ ) if ( g_informationPickupsData[ i ] [ E_PICKUP_ID ] == pickupid ) {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Area Information", g_informationPickupsData[ i ] [ E_TEXT ], "Okay", "" ), Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}
