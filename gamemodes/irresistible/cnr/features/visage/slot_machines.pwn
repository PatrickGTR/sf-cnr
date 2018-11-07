/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\visage\slot_machines.pwn
 * Purpose: functional progressive slot machines
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_MACHINES 				54 // Placed top because of textdraws (TEMPORARY / HOTFIX)
#define MAX_SLOT_POOLS				( 3 )
#define POOL_ENTITIES				( 5 )

/* ** Macros ** */
#define IsPlayerOnSlotMachine(%0)	( p_usingSlotMachine[ %0 ] != -1 )

/* ** Constants ** */
enum E_SLOT_ODD_DATA
{
	E_ENTRY_FEE,				E_SAMPLE_SIZE,					Float: E_TAX,
	E_DOUBLE_BRICK,				E_SINGLE_BRICK[ 2 ], 			E_GOLD_BELLS[ 2 ],
	E_CHERRY[ 2 ], 				E_GRAPES[ 2 ], 					E_69[ 2 ],
	E_PAYOUTS[ 5 ]
};

new const
	g_slotOddsPayout[ ] [ E_SLOT_ODD_DATA ] =
	{
		// Entry Fee 	Probability		Tax 	{Double Brick}	{Single Brick}	{Gold Bells}	{Cherry}			{Grapes}				{69}				Payouts (Single brick, gold bells, etc...)
		{ 50000,        50000,          0.2,    48032,          { 1, 400 },     { 401, 1199},   { 1200, 2797 },     { 2798, 10787 },     	{ 10788, 26767 },   { 1000000, 500000, 250000, 50000, 25000 } },
		{ 25000,		100000,			0.2,	98742,			{ 1, 799 },	    { 800, 2397 },	{ 2398, 6392 },	    { 6393, 22372 },		{ 22373, 54332 },	{ 500000, 250000, 100000, 25000, 12500 } },
		{ 10000,		62500,			0.2,	62488,			{ 1, 994 },	    { 995, 2982 },	{ 2983, 6957 },	    { 6958, 16895 },		{ 16896, 36770 },	{ 100000, 50000, 25000, 10000, 5000 } },
		{ 5000, 		40000,			0.25,	27390,			{ 1, 596 },		{ 597, 1788 },	{ 1789, 4768 },		{ 4769, 10728 },		{ 10729, 22648 },	{ 50000, 25000, 10000, 5000, 2500 } }
	}
;

/* ** Variables ** */
enum E_SLOT_MACHINE_DATA
{
	E_SPIN[ 3 ], 				E_ACTIVE,
	Float: E_X, 				Float: E_Y, 					Float: E_Z,
	Float: E_A, 				Float: E_SPIN_ROTATE[ 3 ], 		Float: E_RANDOM_ROTATE[ 3 ],
	E_TIMER, 					bool: E_ROLLING,				E_POOL_ID,
	E_ENTRY_FEE
};

enum E_CASINO_POOL_DATA
{
	E_SQL_ID,					E_TOTAL_WINNINGS,				E_TOTAL_GAMBLED,
	E_POOL,						E_OBJECT[ POOL_ENTITIES ],		Text3D: E_LABEL[ POOL_ENTITIES ]
};

new
	g_slotmachineData				[ MAX_MACHINES ] [ E_SLOT_MACHINE_DATA ],
	g_slotmachineColors				[ ] [ ] = {
		{ "ld_slot:bar2_o" }, { "ld_slot:r_69" }, { "ld_slot:bar1_o" }, { "ld_slot:bell" }, { "ld_slot:cherry" }, { "ld_slot:grapes" }, { "ld_slot:cherry" }, { "ld_slot:grapes" }, { "ld_slot:bell" }, { "ld_slot:r_69" },
		{ "ld_slot:bell" }, { "ld_slot:bar1_o" }, { "ld_slot:cherry" }, { "ld_slot:grapes" }, { "ld_slot:r_69" }, { "ld_slot:grapes" }, { "ld_slot:bell" }, { "ld_slot:cherry" }, { "ld_slot:bar2_o" }
	},
	g_slotmachineTypes				[ sizeof( g_slotmachineColors ) ] = { 0, 5, 1, 2, 3, 4, 3, 4, 2, 5, 2, 1, 3, 4, 5, 4, 2, 3, 0 },
	p_usingSlotMachine				[ MAX_PLAYERS ] = { -1, ... },

	// Casino pools
	g_casinoPoolData 				[ MAX_SLOT_POOLS ] [ E_CASINO_POOL_DATA ],

	// Iterator
	Iterator: SlotMachines 			< MAX_MACHINES >,
	Iterator: CasinoPool 			< MAX_SLOT_POOLS >,

	// Textdraws
	Text:  g_SlotMachineOneTD		[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_SlotMachineTwoTD		[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  p_SlotMachineFigureTD 	[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_SlotMachineThreeTD		[ MAX_MACHINES ] = { Text: INVALID_TEXT_DRAW, ... },
	Text:  g_SlotMachineBoxTD		[ 2 ] = { Text: INVALID_TEXT_DRAW, ... }
;

/* ** Forwards ** */
public OnPlayerUseSlotMachine( playerid, slotid, first_combo, second_combo, third_combo );

/* ** Hooks ** */
hook OnScriptInit( )
{
	// load casino prize pools for slots
	mysql_function_query( dbHandle, "SELECT * FROM `CASINO_POOLS`", true, "OnCasinoPoolsLoad", "" );

	// load textdraws
	for ( new i = 0; i < MAX_MACHINES; i ++ )
	{
		p_SlotMachineFigureTD[ i ] = TextDrawCreate(324.000000, 307.000000, "$20,000");
		TextDrawAlignment(p_SlotMachineFigureTD[ i ], 2);
		TextDrawBackgroundColor(p_SlotMachineFigureTD[ i ], 255);
		TextDrawFont(p_SlotMachineFigureTD[ i ], 3);
		TextDrawLetterSize(p_SlotMachineFigureTD[ i ], 0.250000, 1.100000);
		TextDrawColor(p_SlotMachineFigureTD[ i ], -1);
		TextDrawSetOutline(p_SlotMachineFigureTD[ i ], 1);
		TextDrawSetProportional(p_SlotMachineFigureTD[ i ], 1);

		g_SlotMachineOneTD[ i ] = TextDrawCreate(222.000000, 324.000000, "ld_slot:bar1_o");
		TextDrawBackgroundColor(g_SlotMachineOneTD[ i ], 255);
		TextDrawFont(g_SlotMachineOneTD[ i ], 4);
		TextDrawLetterSize(g_SlotMachineOneTD[ i ], 0.500000, 0.399999);
		TextDrawColor(g_SlotMachineOneTD[ i ], -1);
		TextDrawSetOutline(g_SlotMachineOneTD[ i ], 0);
		TextDrawSetProportional(g_SlotMachineOneTD[ i ], 1);
		TextDrawSetShadow(g_SlotMachineOneTD[ i ], 1);
		TextDrawUseBox(g_SlotMachineOneTD[ i ], 1);
		TextDrawBoxColor(g_SlotMachineOneTD[ i ], 255);
		TextDrawTextSize(g_SlotMachineOneTD[ i ], 66.000000, 77.000000);

		g_SlotMachineTwoTD[ i ] = TextDrawCreate(292.000000, 324.000000, "ld_slot:bar1_o");
		TextDrawBackgroundColor(g_SlotMachineTwoTD[ i ], 255);
		TextDrawFont(g_SlotMachineTwoTD[ i ], 4);
		TextDrawLetterSize(g_SlotMachineTwoTD[ i ], 0.500000, 0.399999);
		TextDrawColor(g_SlotMachineTwoTD[ i ], -1);
		TextDrawSetOutline(g_SlotMachineTwoTD[ i ], 0);
		TextDrawSetProportional(g_SlotMachineTwoTD[ i ], 1);
		TextDrawSetShadow(g_SlotMachineTwoTD[ i ], 1);
		TextDrawUseBox(g_SlotMachineTwoTD[ i ], 1);
		TextDrawBoxColor(g_SlotMachineTwoTD[ i ], 255);
		TextDrawTextSize(g_SlotMachineTwoTD[ i ], 66.000000, 77.000000);

		g_SlotMachineThreeTD[ i ] = TextDrawCreate(362.000000, 324.000000, "ld_slot:bar1_o");
		TextDrawBackgroundColor(g_SlotMachineThreeTD[ i ], 255);
		TextDrawFont(g_SlotMachineThreeTD[ i ], 4);
		TextDrawLetterSize(g_SlotMachineThreeTD[ i ], 0.500000, 0.399999);
		TextDrawColor(g_SlotMachineThreeTD[ i ], -1);
		TextDrawSetOutline(g_SlotMachineThreeTD[ i ], 0);
		TextDrawSetProportional(g_SlotMachineThreeTD[ i ], 1);
		TextDrawSetShadow(g_SlotMachineThreeTD[ i ], 1);
		TextDrawUseBox(g_SlotMachineThreeTD[ i ], 1);
		TextDrawBoxColor(g_SlotMachineThreeTD[ i ], 255);
		TextDrawTextSize(g_SlotMachineThreeTD[ i ], 66.000000, 77.000000);
	}

	g_SlotMachineBoxTD[ 0 ] = TextDrawCreate(220.000000, 322.000000, "_");
	TextDrawBackgroundColor(g_SlotMachineBoxTD[ 0 ], 255);
	TextDrawLetterSize(g_SlotMachineBoxTD[ 0 ], 0.500000, 7.000000);
	TextDrawUseBox(g_SlotMachineBoxTD[ 0 ], 1);
	TextDrawBoxColor(g_SlotMachineBoxTD[ 0 ], 112);
	TextDrawTextSize(g_SlotMachineBoxTD[ 0 ], 430.000000, 3.000000);

	g_SlotMachineBoxTD[ 1 ] = TextDrawCreate(220.000000, 306.000000, "_");
	TextDrawBackgroundColor(g_SlotMachineBoxTD[ 1 ], 255);
	TextDrawLetterSize(g_SlotMachineBoxTD[ 1 ], 0.500000, 1.400000);
	TextDrawUseBox(g_SlotMachineBoxTD[ 1 ], 1);
	TextDrawBoxColor(g_SlotMachineBoxTD[ 1 ], 238);
	TextDrawTextSize(g_SlotMachineBoxTD[ 1 ], 430.000000, -18.000000);
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	new
		machineid = p_usingSlotMachine[ playerid ];

	if ( IsPlayerInCasino( playerid ) )
	{
		// Gambling Slots
		if ( machineid != -1 )
		{
			if ( GetDistanceFromPlayerSquared( playerid, g_slotmachineData[ machineid ] [ E_X ], g_slotmachineData[ machineid ] [ E_Y ], g_slotmachineData[ machineid ] [ E_Z ] ) > 4.0 ) // Squared
				return StopPlayerUsingSlotMachine( playerid );

			if ( PRESSED( KEY_JUMP ) ) {
				if ( ( p_AutoSpin{ playerid } = ! p_AutoSpin{ playerid } ) == true )
					TriggerPlayerSlotMachine( playerid, machineid );

				return SendServerMessage( playerid, "You have %s autospin for this slot machine.", p_AutoSpin{ playerid } ? ( "enabled" ) : ( "disabled" ) );
			}

			if ( PRESSED( KEY_SPRINT ) ) {
				TriggerPlayerSlotMachine( playerid, machineid );
			}

			if ( PRESSED( KEY_SECONDARY_ATTACK ) )
			{
				if ( g_slotmachineData[ machineid ] [ E_ROLLING ] )
					return SendError( playerid, "Please wait for the slot machine to finish spinning." );

				return StopPlayerUsingSlotMachine( playerid );
			}
		}
		else
		{
			if ( PRESSED( KEY_SECONDARY_ATTACK ) )
			{
				new
					id = GetClosestSlotMachine( playerid );

				if ( id != -1 )
				{
					new Float: X = g_slotmachineData[ id ] [ E_X ] + floatcos( g_slotmachineData[ id ] [ E_A ] - 90, degrees );
					new Float: Y = g_slotmachineData[ id ] [ E_Y ] + floatsin( g_slotmachineData[ id ] [ E_A ] - 90, degrees );
					new Float: Z;

					if ( IsPlayerInRangeOfPoint( playerid, 1.0, X, Y, g_slotmachineData[ id ] [ E_Z ] ) && GetPlayerPos( playerid, Z, Z, Z ) )
					{
						if ( GetPlayerCash( playerid ) < 100 )
						{
							PlayerPlaySound( playerid, 1055, 0.0, 0.0, 0.0 );
							return 1;
						}

						p_AutoSpin{ playerid } = false;
						p_usingSlotMachine[ playerid ] = id;

						SetPlayerPos( playerid, X, Y, Z );
						TogglePlayerControllable( playerid, 0 );
						SetPlayerFacingAngle( playerid, g_slotmachineData[ id ] [ E_A ] );

						TextDrawSetString( g_SlotMachineOneTD[ id ], g_slotmachineColors[ floatround( floatfract( g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 0 ] / 360 ) * 18 ) ] );
						TextDrawShowForPlayer( playerid, g_SlotMachineOneTD[ id ] );

						TextDrawSetString( g_SlotMachineTwoTD[ id ], g_slotmachineColors[ floatround( floatfract( g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 1 ] / 360 ) * 18 ) ] );
						TextDrawShowForPlayer( playerid, g_SlotMachineTwoTD[ id ] );

						TextDrawSetString( g_SlotMachineThreeTD[ id ], g_slotmachineColors[ floatround( floatfract( g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 2 ] / 360 ) * 18 ) ] );
						TextDrawShowForPlayer( playerid, g_SlotMachineThreeTD[ id ] );

						TextDrawSetString( p_SlotMachineFigureTD[ id ], sprintf( "~y~~h~%s", cash_format( g_slotmachineData[ id ] [ E_ENTRY_FEE ] ) ) );
						TextDrawShowForPlayer( playerid, p_SlotMachineFigureTD[ id ] );

						TextDrawShowForPlayer( playerid, g_SlotMachineBoxTD[ 0 ] );
						TextDrawShowForPlayer( playerid, g_SlotMachineBoxTD[ 1 ] );

						KillTimer( p_SafeHelperTimer[ playerid ] ), p_SafeHelperTimer[ playerid ] = -1; // Stop safe helper
						return ShowPlayerHelpDialog( playerid, 0, "~y~~h~~k~~PED_SPRINT~~w~ - Spin The Wheels~n~~y~~h~~k~~PED_JUMPING~~w~ - Toggle Autospin~n~~y~~h~~k~~VEHICLE_ENTER_EXIT~~w~ - Exit" );
					}
				}
			}
		}
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	p_usingSlotMachine[ playerid ] = -1;
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
    StopPlayerUsingSlotMachine( playerid );
	return 1;
}

/* ** Callbacks ** */
public OnPlayerUseSlotMachine( playerid, slotid, first_combo, second_combo, third_combo )
{
	new
		poolid = g_slotmachineData[ slotid ] [ E_POOL_ID ];

	if ( ! Iter_Contains( CasinoPool, poolid ) )
		return SendError( playerid, "This machine has an invalid casino pool! (0xFF33)" );

	// autospin
	if ( p_AutoSpin{ playerid } )
		TriggerPlayerSlotMachine( playerid, slotid );

	// check combinations
	// printf("%s (%d, %d, %d)", ReturnPlayerName( playerid ), first_combo, second_combo, third_combo);
	if ( first_combo == second_combo && first_combo == third_combo )
	{
		new
			iNetWin;

		if ( first_combo == 0 ) iNetWin = g_casinoPoolData[ poolid ] [ E_POOL ];
		else
		{
			new oddid = -1;

			for ( new i = 0; i < sizeof( g_slotOddsPayout ); i ++ ) if ( g_slotmachineData[ slotid ] [ E_ENTRY_FEE ] == g_slotOddsPayout[ i ] [ E_ENTRY_FEE ] ) {
				oddid = i;
			}

			if ( oddid == -1 ) oddid = sizeof( g_slotOddsPayout ) - 1;

			iNetWin = g_slotOddsPayout[ oddid ] [ E_PAYOUTS ] [ first_combo - 1 ];
		}

		// readjust casino pool data
		UpdateCasinoPoolData( poolid, .pool_increment = -iNetWin, .total_win = iNetWin );

		// alert user
		if ( iNetWin > g_slotmachineData[ slotid ] [ E_ENTRY_FEE ] ) {
   			SendGlobalMessage( -1, ""COL_GREY"[CASINO]{FFFFFF} %s(%d) has won "COL_GOLD"%s"COL_WHITE" from the %s casino slots!", ReturnPlayerName( playerid ), playerid, cash_format( iNetWin ), g_slotmachineData[ slotid ] [ E_ENTRY_FEE ] == 10000 ? ( "Four Dragons" ) : ( g_slotmachineData[ slotid ] [ E_ENTRY_FEE ] >= 25000 ? ( "Visage" ) : ( "Caligulas" ) ) );
   		} else {
   			SendServerMessage( playerid, "Congratulations, you've won "COL_GOLD"%s"COL_WHITE"!", cash_format( iNetWin ) );
   		}

		// give the cash
		GivePlayerCash( playerid, iNetWin );
      	StockMarket_UpdateEarnings( E_STOCK_CASINO, -iNetWin, 0.05 );
		PlayerPlaySound( playerid, 4201, 0.0, 0.0, 0.0 ); // Coin fall
		GameTextForPlayer( playerid, "~w~~h~winner!", 5000, 6 );
   		return 1;
	}

	return GameTextForPlayer( playerid, "~w~~h~no win!", 2500, 6 );
}

/* ** SQL Threads ** */
thread OnCasinoPoolsLoad( )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

    if ( rows )
    {
    	for( new i = 0; i < rows; i++ )
    	{
	    	new
	    		poolid = cache_get_field_content_int( i, "ID", dbHandle );

	    	if ( 0 <= poolid < MAX_SLOT_POOLS )
	    	{
	    		if ( Iter_Contains( CasinoPool, poolid ) )
	    			break;

	    		// insert data
	    		g_casinoPoolData[ poolid ] [ E_POOL ] 			= cache_get_field_content_int( i, "POOL", dbHandle );
	    		g_casinoPoolData[ poolid ] [ E_TOTAL_WINNINGS ] = cache_get_field_content_int( i, "TOTAL_WINNINGS", dbHandle );
	    		g_casinoPoolData[ poolid ] [ E_TOTAL_GAMBLED ] 	= cache_get_field_content_int( i, "TOTAL_GAMBLED", dbHandle );

	    		// create specific 3d texts and objects
	    		switch ( poolid )
	    		{
	    			// caligs low
	    			case 0:
	    			{
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 0 ] = CreateDynamicObject( 3074, 2216.5166, 1585.5836, 1006.3437, 0.0000, 10.6999, 91.7292 );
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 1 ] = CreateDynamicObject( 3074, 2216.7634, 1620.6029, 1006.5472, 0.0000, 2.5, -90.0 );
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 2 ] = CreateDynamicObject( 3074, 2277.2065, 1606.6026, 1006.1736, 0.0000, -2.3000, 177.1292 );
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 3 ] = CreateDynamicObject( 3074, 2190.8913, 1677.1768, 11.5257, 0.0000, 20.3999, 179.7994 );
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 4 ] = CreateDynamicObject( 3074, 2255.6259, 1620.6029, 1006.5472, 0.0000, 2.5, -90.0 );

						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2218.8115, 1616.7198, 1008.1833, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2218.5430, 1590.5162, 1008.1849, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 2 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2271.5161, 1606.4812, 1008.1797, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 3 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2219.1663, 1603.9136, 1008.1797, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
	    				g_casinoPoolData[ poolid ] [ E_LABEL ] [ 4 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2255.1665, 1613.9871, 1008.1797, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
					}

	    			// dragons low
	    			case 1:
	    			{
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 0 ] = CreateDynamicObject( 3074, 1956.5617, 995.9906, 991.5460, 0.0000, -90.1000, 144.6679 );
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 1 ] = CreateDynamicObject( 3074, 1968.7164, 990.2147, 991.5709, 0.0000, -90.1000, -26.6321 );
	    				g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 2 ] = CreateDynamicObject( 3074, 1956.8721, 1039.3811, 991.4691, 0.0999, -89.899, -147.020 );
	    				g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 3 ] = CreateDynamicObject( 3074, 1968.7106, 1044.6326, 991.4962, 0.0000, -90.1000, 30.9680 );
	    				g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 4 ] = CreateDynamicObject( 3074, 2026.9927, 1008.0256, 9.630300, 0.0000, 0.000000, 1.70270 );

						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 1962.2894, 992.08720, 994.5215, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 1962.1710, 1043.5509, 994.5215, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
	    				g_casinoPoolData[ poolid ] [ E_LABEL ] [ 2 ] = Text3D: INVALID_3DTEXT_ID;
	    				g_casinoPoolData[ poolid ] [ E_LABEL ] [ 3 ] = Text3D: INVALID_3DTEXT_ID;
	    				g_casinoPoolData[ poolid ] [ E_LABEL ] [ 4 ] = Text3D: INVALID_3DTEXT_ID;
	    			}

	    			case 2:
	    			{
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 0 ] = CreateDynamicObject( 3074, 2603.550048, 1623.765014, 1506.531982, 0.000000, 8.699999, -90.0000 );
						g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 1 ] = CreateDynamicObject( 3074, 2603.550048, 1584.136962, 1507.233032, 0.000000, 8.699999, 90.00000 );
	    				g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 2 ] = CreateDynamicObject( 3074, 2603.520019, 1603.123046, 1505.431030, 0.000000, 0.000000, 0.000000 );
	    				g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 3 ] = CreateDynamicObject( 3074, 2591.430908, 1612.844970, 1506.615966, 0.000000, 13.600000, 180.000 );
	    				g_casinoPoolData[ poolid ] [ E_OBJECT ] [ 4 ] = CreateDynamicObject( 3074, 2016.567749, 1916.915039, 13.85102100, 0.000000, 15.600006, 0.00000 );

						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2609.0510, 1591.3191, 1507.1743, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
						g_casinoPoolData[ poolid ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2608.9717, 1615.6409, 1507.1766, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
	    				g_casinoPoolData[ poolid ] [ E_LABEL ] [ 2 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2597.7310, 1615.8630, 1507.1765, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
	    				g_casinoPoolData[ poolid ] [ E_LABEL ] [ 3 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2597.7532, 1591.0193, 1507.1741, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
	    				g_casinoPoolData[ poolid ] [ E_LABEL ] [ 4 ] = CreateDynamic3DTextLabel( "LOADING", COLOR_GREEN, 2587.2305, 1611.8252, 1507.1733, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0 );
	    			}
	    		}

	    		// Update pool labels etc
	    		UpdateCasinoPoolLabels( poolid );

	    		// shove the id into the system
	    		Iter_Add(CasinoPool, poolid);
	    	}
	    	else printf( "[ERROR]: A slot pool id exceeds %d\n", MAX_SLOT_POOLS );
	    }

	    // create slot machines
		mysql_function_query( dbHandle, "SELECT * FROM `SLOT_MACHINES`", true, "OnSlotMachinesLoad", "" );
    }
    return 1;
}

thread OnSlotMachinesLoad( )
{
	new
	    rows, fields, loadingTick = GetTickCount( );

    cache_get_data( rows, fields );

    if ( rows )
    {
    	for( new i = 0; i < rows; i++ )
    	{
			new
				id = Iter_Free(SlotMachines);

			if ( id != ITER_NONE )
			{
				new
					Float: X = cache_get_field_content_float( i, "X", dbHandle ),
					Float: Y = cache_get_field_content_float( i, "Y", dbHandle ),
					Float: Z = cache_get_field_content_float( i, "Z", dbHandle ),
					Float: rZ = cache_get_field_content_float( i, "ROTATION", dbHandle ),
					Float: fOffsetX,
					Float: fOffsetY
				;

				// Update positions
				g_slotmachineData[ id ] [ E_X ] = X;
				g_slotmachineData[ id ] [ E_Y ] = Y;
				g_slotmachineData[ id ] [ E_Z ] = Z;
				g_slotmachineData[ id ] [ E_A ] = rZ;

				// Load variables
				g_slotmachineData[ id ] [ E_ENTRY_FEE ] = cache_get_field_content_int( i, "ENTRY_FEE", dbHandle );
				g_slotmachineData[ id ] [ E_POOL_ID ] = cache_get_field_content_int( i, "POOL_ID", dbHandle );

				// 3d Text
				fOffsetX = 1.0 * floatsin( -rZ, degrees );
				fOffsetY = 1.0 * floatcos( -rZ, degrees );
				CreateDynamic3DTextLabel( sprintf( "Press ENTER To Play\n"COL_WHITE"%s Minimum", cash_format( g_slotmachineData[ id ] [ E_ENTRY_FEE ] ) ), COLOR_GREY, X + fOffsetX, Y + fOffsetY, Z - 0.1, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 1 );

				// Misc variables
				g_slotmachineData[ id ] [ E_TIMER ] = -1;

				// Create machines
				CreateDynamicObject( 2325, X, Y, Z, 0.00000, 0.00000, rZ, .priority = 9999 );

				// Third slot
				fOffsetX = 0.096 * floatsin( rZ + 96.0, degrees );
				fOffsetY = 0.096 * floatcos( rZ + 96.0, degrees );

				g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 0 ] = 20.0 * random( 18 );
				g_slotmachineData[ id ] [ E_SPIN ] [ 0 ] = CreateDynamicObject( 2347, X - fOffsetX, Y + fOffsetY, Z + 0.0024, g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 0 ], 0.00000, rZ, .priority = 9999 );

				// Second slot
				fOffsetX = 0.025 * floatsin( rZ + 66.4, degrees );
				fOffsetY = 0.025 * floatcos( rZ + 66.4, degrees );

				g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 1 ] = 20.0 * random( 18 );
				g_slotmachineData[ id ] [ E_SPIN ] [ 1 ] = CreateDynamicObject( 2347, X + fOffsetX, Y - fOffsetY, Z + 0.0024, g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 1 ], 0.00000, rZ, .priority = 9999 );

				// First slot
				fOffsetX = 0.140 * floatsin( rZ + 85.9, degrees );
				fOffsetY = 0.140 * floatcos( rZ + 85.9, degrees );

				g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 2 ] = 20.0 * random( 18 );
				g_slotmachineData[ id ] [ E_SPIN ] [ 2 ] = CreateDynamicObject( 2347, X + fOffsetX, Y - fOffsetY, Z + 0.0024, g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 2 ], 0.00000, rZ, .priority = 9999 );

				// Add to iteration
				Iter_Add(SlotMachines, id);
			}
	    	else
	    	{
		        static overflow;
		        printf("[SLOT_MACHINE ERROR] Reached limit of %d slots machines, increase to %d to fix.", MAX_MACHINES, MAX_MACHINES + ( ++ overflow ) );
	    	}
    	}
    }
	printf( "[SLOT MACHINES]: %d slot machines have been loaded. (Tick: %dms)", rows, GetTickCount( ) - loadingTick );
    return 1;
}

/* ** Functions ** */
stock TriggerPlayerSlotMachine( playerid, machineid )
{
	if ( p_usingSlotMachine[ playerid ] != machineid )
		return 1;

	if ( GetDistanceFromPlayerSquared( playerid, g_slotmachineData[ machineid ] [ E_X ], g_slotmachineData[ machineid ] [ E_Y ], g_slotmachineData[ machineid ] [ E_Z ] ) > 4.0 ) // Squared
		return StopPlayerUsingSlotMachine( playerid );

	if ( !g_slotmachineData[ machineid ] [ E_ROLLING ] )
	{
		new oddid = -1;

		for ( new i = 0; i < sizeof( g_slotOddsPayout ); i ++ ) if ( g_slotmachineData[ machineid ] [ E_ENTRY_FEE ] == g_slotOddsPayout[ i ] [ E_ENTRY_FEE ] ) {
			oddid = i;
		}

		if ( oddid == -1 ) oddid = sizeof( g_slotOddsPayout ) - 1;

		new entryFee = g_slotmachineData[ machineid ] [ E_ENTRY_FEE ];
		new poolContribute = floatround( float( entryFee ) * ( 1.0 - g_slotOddsPayout[ oddid ] [ E_TAX ] ) );

		if ( GetPlayerCash( playerid ) < entryFee )
			return SendError( playerid, "You must have at least %s to use this slot machine.", cash_format( entryFee ) ), ( p_AutoSpin{ playerid } = false ), 1;

		// Update casino pool
		GivePlayerCasinoRewardsPoints( playerid, g_slotmachineData[ machineid ] [ E_ENTRY_FEE ], .house_edge = g_slotOddsPayout[ oddid ] [ E_TAX ] * 100.0 );
		UpdateCasinoPoolData( g_slotmachineData[ machineid ] [ E_POOL_ID ], .pool_increment = poolContribute, .total_win = 0, .total_gambled = entryFee );

		// Charge the player
		RollSlotMachine( playerid, machineid );
		PlayerPlaySound( playerid, 4202, 0.0, 0.0, 0.0 );
		ApplyAnimation( playerid, "CASINO", "slot_plyr", 2.0, 0, 1, 1, 0, 0 );
		GivePlayerCash( playerid, -entryFee );
      	StockMarket_UpdateEarnings( E_STOCK_CASINO, entryFee, 0.05 );
		return 1;
	}
	return 1;
}

stock UpdateCasinoPoolLabels( poolid )
{
	for( new i = 0; i < POOL_ENTITIES; i ++ )
	{
		if ( IsValidDynamicObject( g_casinoPoolData[ poolid ] [ E_OBJECT ] [ i ] ) )
			SetDynamicObjectMaterialText( g_casinoPoolData[ poolid ] [ E_OBJECT ] [ i ], 0, sprintf( "%s PRIZE", cash_format( g_casinoPoolData[ poolid ] [ E_POOL ] ) ), 130, "Arial", 20, 1, 0xFF00FF00, 0, 1 );

		if ( IsValidDynamic3DTextLabel( g_casinoPoolData[ poolid ] [ E_LABEL ] [ i ] ) )
			UpdateDynamic3DTextLabelText( g_casinoPoolData[ poolid ] [ E_LABEL ] [ i ], 0x00FF00FF, sprintf( "%s Prize Pool", cash_format( g_casinoPoolData[ poolid ] [ E_POOL ] ) ) );
	}
	return 1;
}

stock UpdateCasinoPoolData( poolid, pool_increment = 0, total_win = 0, total_gambled = 0 )
{
	if ( ! Iter_Contains( CasinoPool, poolid ) )
		return;

	static
		iUpdateCooldown;

	// update vars
	g_casinoPoolData[ poolid ] [ E_POOL ] += pool_increment;
	g_casinoPoolData[ poolid ] [ E_TOTAL_WINNINGS ] += total_win;
	g_casinoPoolData[ poolid ] [ E_TOTAL_GAMBLED ] 	+= total_gambled;

	// update labels
	UpdateCasinoPoolLabels( poolid );

	// update the database
	if ( g_iTime > iUpdateCooldown )
	{
		// update the database
		format( szNormalString, sizeof( szNormalString ), "UPDATE `CASINO_POOLS` SET `POOL`=%d,`TOTAL_WINNINGS`=%d,`TOTAL_GAMBLED`=%d WHERE `ID`=%d", g_casinoPoolData[ poolid ] [ E_POOL ], g_casinoPoolData[ poolid ] [ E_TOTAL_WINNINGS ], g_casinoPoolData[ poolid ] [ E_TOTAL_GAMBLED ], poolid );
		mysql_single_query( szNormalString );

		// cooldown
		iUpdateCooldown = g_iTime + 20;
	}
}


stock RollSlotMachine( playerid, id )
{
	new bool: loss = false;
	new Float: rotation;
	new randomChance;
	new oddid = -1;

	for ( new i = 0; i < sizeof( g_slotOddsPayout ); i ++ ) if ( g_slotmachineData[ id ] [ E_ENTRY_FEE ] == g_slotOddsPayout[ i ] [ E_ENTRY_FEE ] ) {
		oddid = i;
	}

	if ( oddid == -1 ) oddid = sizeof( g_slotOddsPayout ) - 1;

	randomChance = MRandom( g_slotOddsPayout[ oddid ] [ E_SAMPLE_SIZE ] + 1 );
	printf("random chance %d", randomChance );

	if ( randomChance == g_slotOddsPayout[ oddid ] [ E_DOUBLE_BRICK ] ) rotation = 0.0;
	else if ( g_slotOddsPayout[ oddid ] [ E_SINGLE_BRICK ] [ 0 ] <= randomChance <= g_slotOddsPayout[ oddid ] [ E_SINGLE_BRICK ] [ 1 ] ) rotation = 40.0;
	else if ( g_slotOddsPayout[ oddid ] [ E_GOLD_BELLS ] [ 0 ] <= randomChance <= g_slotOddsPayout[ oddid ] [ E_GOLD_BELLS ] [ 1 ] ) rotation = 60.0;
	else if ( g_slotOddsPayout[ oddid ] [ E_CHERRY ] [ 0 ] <= randomChance <= g_slotOddsPayout[ oddid ] [ E_CHERRY ] [ 1 ] ) rotation = 80.0;
	else if ( g_slotOddsPayout[ oddid ] [ E_GRAPES ] [ 0 ] <= randomChance <= g_slotOddsPayout[ oddid ] [ E_GRAPES ] [ 1 ] ) rotation = 100.0;
	else if ( g_slotOddsPayout[ oddid ] [ E_69 ] [ 0 ] <= randomChance <= g_slotOddsPayout[ oddid ] [ E_69 ] [ 1 ] ) rotation = 20.0;
	else loss = true;

	// process loss
	if ( loss )
	{
		if ( random( 2 ) == 0 )
		{
			// assign random rotation (must be <= 16)
			rotation = float( random( 16 ) ) * 20.0;

			// just add 20.0 to each random rotation
			g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 0 ] = rotation;
			g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 1 ] = rotation + 20.0;
			g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 2 ] = rotation + 40.0;
		}
		else
		{
			// assign random rotation (must be <= 16)
			rotation = float( RandomEx( 2, 18 ) ) * 20.0;

			// just add 20.0 to each random rotation
			g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 0 ] = rotation;
			g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 1 ] = rotation - 20.0;
			g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 2 ] = rotation - 40.0;
		}
	}
	else
	{
		g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 0 ] = rotation;
		g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 1 ] = rotation;
		g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 2 ] = rotation;
	}

	// Roll it!
	KillTimer( g_slotmachineData[ id ] [ E_TIMER ] );
	g_slotmachineData[ id ] [ E_ROLLING ] = true;
	g_slotmachineData[ id ] [ E_TIMER ] = SetTimerEx( "rollMachine", 50, false, "ddfd", playerid, id, 0.1, 0 );
	return 1;
}

function rollMachine( playerid, id, Float: velocity, spins )
{
	new
		// Is the player even on...
		bIsConnected = IsPlayerConnected( playerid ),

		// Calculate slot rotations
		Float: fSlotUno = g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 0 ] + velocity,
		Float: fSlotDuo = g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 1 ] + velocity,
		Float: fSlotTre = g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 2 ] + velocity
	;

	if ( velocity >= 360.0 )
	{
		static
			iWinningIndex[ 3 ], bool: beep[ 2 char ];

		velocity = ++spins * 20.0;

		if ( velocity >= ( 360.0 + g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 0 ] ) )
		{
			fSlotUno = 360.0 + g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 0 ];

			if ( ! beep{ 0 } )
				PlayerPlaySound( playerid, 4203, 0.0, 0.0, 0.0 ), beep{ 0 } = true;

			g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 0 ] = fSlotUno;
		}

		if ( velocity >= ( 720.0 + g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 1 ] ) )
		{
			fSlotDuo = 720.0 + g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 1 ];

			if ( ! beep{ 1 } )
				PlayerPlaySound( playerid, 4203, 0.0, 0.0, 0.0 ), beep{ 1 } = true;

			g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 1 ] = fSlotDuo;
		}

		if ( velocity >= ( 1080.0 + g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 2 ] ) ) // 1080 is an offset
		{
			// Reset the beeps
			beep{ 0 } = false, beep{ 1 } = false;

			// Equal interval rotating
			fSlotTre = 1080.0 + g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 2 ];

			PlayerPlaySound( playerid, 4203, 0.0, 0.0, 0.0 );

			// Calculate index of winning shit
			g_slotmachineData[ id ] [ E_SPIN_ROTATE ] [ 2 ] = fSlotTre;

			// Update the position
			SetDynamicObjectRot( g_slotmachineData[ id ] [ E_SPIN ] [ 2 ], fSlotTre, 0.0, g_slotmachineData[ id ] [ E_A ] );

			// Kill a few things
			g_slotmachineData[ id ] [ E_TIMER ] = -1;
			g_slotmachineData[ id ] [ E_ROLLING ] = false;

			// Check if connected
			if ( bIsConnected )
			{
				// Update final
				iWinningIndex[ 0 ] = floatround( g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 0 ] / 20.0 );
				iWinningIndex[ 1 ] = floatround( g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 1 ] / 20.0 );
				iWinningIndex[ 2 ] = floatround( g_slotmachineData[ id ] [ E_RANDOM_ROTATE ] [ 2 ] / 20.0 );
				TextDrawSetString( g_SlotMachineThreeTD[ id ], g_slotmachineColors[ iWinningIndex[ 2 ] ] );
				TextDrawShowForPlayer( playerid, g_SlotMachineThreeTD[ id ] );

				// Call a winner!
				return CallLocalFunction( "OnPlayerUseSlotMachine", "ddddd", playerid, id, g_slotmachineTypes[ iWinningIndex[ 0 ] ], g_slotmachineTypes[ iWinningIndex[ 1 ] ], g_slotmachineTypes[ iWinningIndex[ 2 ] ] );
			}
			return 1;
		}

		iWinningIndex[ 0 ] = floatround( floatfract( fSlotUno / 360 ) * 18 );
		TextDrawSetString( g_SlotMachineOneTD[ id ], g_slotmachineColors[ iWinningIndex[ 0 ] ] );
		TextDrawShowForPlayer( playerid, g_SlotMachineOneTD[ id ] );

		iWinningIndex[ 1 ] = floatround( floatfract( fSlotDuo / 360 ) * 18 );
		TextDrawSetString( g_SlotMachineTwoTD[ id ], g_slotmachineColors[ iWinningIndex[ 1 ] ] );
		TextDrawShowForPlayer( playerid, g_SlotMachineTwoTD[ id ] );

		iWinningIndex[ 2 ] = floatround( floatfract( fSlotTre / 360 ) * 18 );
		TextDrawSetString( g_SlotMachineThreeTD[ id ], g_slotmachineColors[ iWinningIndex[ 2 ] ] );
		TextDrawShowForPlayer( playerid, g_SlotMachineThreeTD[ id ] );
	}
	else velocity *= 1.45;

	SetDynamicObjectRot( g_slotmachineData[ id ] [ E_SPIN ] [ 0 ], fSlotUno, 0.0, g_slotmachineData[ id ] [ E_A ] );
	SetDynamicObjectRot( g_slotmachineData[ id ] [ E_SPIN ] [ 1 ], fSlotDuo, 0.0, g_slotmachineData[ id ] [ E_A ] );
	SetDynamicObjectRot( g_slotmachineData[ id ] [ E_SPIN ] [ 2 ], fSlotTre, 0.0, g_slotmachineData[ id ] [ E_A ] );

	return ( g_slotmachineData[ id ] [ E_TIMER ] = SetTimerEx( "rollMachine", 50, false, "ddfd", playerid, id, velocity, spins ) );
}

stock GetClosestSlotMachine( playerid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = -1, Float: fTmp
    ;

	foreach(new id : SlotMachines)
	{
        if ( 0.0 < ( fTmp = GetDistanceFromPlayerSquared( playerid, g_slotmachineData[ id ] [ E_X ], g_slotmachineData[ id ] [ E_Y ], g_slotmachineData[ id ] [ E_Z ] ) ) < distance ) // Y_Less mentioned there's no need to sqroot
        {
            distance = fTmp;
            iCurrent = id;
        }
    }
    return iCurrent;
}

stock StopPlayerUsingSlotMachine( playerid )
{
	if ( p_usingSlotMachine[ playerid ] == -1 )
		return 1;

	new
		id = p_usingSlotMachine[ playerid ];

	TextDrawHideForPlayer( playerid, g_SlotMachineOneTD[ id ] );
	TextDrawHideForPlayer( playerid, g_SlotMachineTwoTD[ id ] );
	TextDrawHideForPlayer( playerid, g_SlotMachineThreeTD[ id ] );
	TextDrawHideForPlayer( playerid, p_SlotMachineFigureTD[ id ] );
	TextDrawHideForPlayer( playerid, g_SlotMachineBoxTD[ 0 ] );
	TextDrawHideForPlayer( playerid, g_SlotMachineBoxTD[ 1 ] );

	p_AutoSpin{ playerid } = false;
	p_usingSlotMachine[ playerid ] = -1;

	HidePlayerHelpDialog( playerid );
	TogglePlayerControllable( playerid, 1 );
	return 1;
}
