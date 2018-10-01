/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: vip.inc
 * Purpose: vip associated information
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define GetPlayerIrresistibleCoins(%0) \
	(p_IrresistibleCoins[%0])

#define GivePlayerIrresistibleCoins(%0,%1) \
	(p_IrresistibleCoins[%0] += %1)

/* ** Definitions ** */
#define VIP_MAX_EXTRA_SLOTS 		5

#define ICM_PAGE_DEFAULT 			( 0 )
#define ICM_PAGE_CASHCARD 			( 1 )
#define ICM_PAGE_ASSETS 			( 2 )
#define ICM_PAGE_UPGRADE 			( 3 )

#define VIP_REGULAR 				( 1 )
#define VIP_BRONZE 					( 2 )
#define VIP_GOLD 					( 3 )
#define VIP_PLATINUM 				( 4 )
#define VIP_DIAMOND 				( 5 )

#define ICM_COKE_BIZ 				( 0 )
#define ICM_METH_BIZ 				( 1 )
#define ICM_WEED_BIZ 				( 2 )
#define ICM_HOUSE 					( 3 )
#define ICM_VEHICLE					( 4 )
#define ICM_GATE					( 5 )
#define ICM_GARAGE					( 6 )
#define ICM_NAME					( 7 )
#define ICM_VEH_SLOT 				( 8 )

#define VIP_ALLOW_OVER_LIMIT 		( true )

/* ** Variables ** */
enum E_IC_MARKET_DATA
{
	E_ID,	E_NAME[ 19 ],	Float: E_PRICE,
	bool: E_MULTI_BUY,
};

new
	g_irresistibleVipItems			[ ] [ E_IC_MARKET_DATA ] =
	{
		{ VIP_GOLD,		"Gold V.I.P",		1800.0 },
		{ VIP_BRONZE,	"Bronze V.I.P", 	1000.0 },
		{ VIP_REGULAR, 	"Regular V.I.P",	500.0 }
	},
	g_irresistibleCashCards 		[ ] [ E_IC_MARKET_DATA ] =
	{
		{ 1250000,		"Tiger Shark",			225.0 },
		{ 2750000,		"Bull Shark",			450.0 },
		{ 6000000,		"Great White Shark",	900.0 },
		{ 10000000,		"Whale Shark",			1350.0 },
		{ 20000000,		"Megalodon Shark",		2250.0 }
	},
	g_irresistibleMarketItems		[ ] [ E_IC_MARKET_DATA ] =
	{
		{ ICM_COKE_BIZ,	"Gang Facility",		4500.0 },
		{ ICM_COKE_BIZ,	"Bunker Business",		3900.0 },
		{ ICM_COKE_BIZ,	"Coke Business",		1500.0 },
		{ ICM_METH_BIZ,	"Meth Business",		700.0 },
		{ ICM_WEED_BIZ,	"Weed Business",		500.0 },
		{ ICM_VEHICLE,	"Select Vehicle",		450.0 },
		{ ICM_HOUSE,	"Select House",			400.0 },
		{ ICM_GATE,		"Custom Gate",			350.0 },
		{ ICM_VEH_SLOT,	"Extra Vehicle Slot", 	350.0 },
		{ ICM_GARAGE,	"Select Garage", 		250.0 },
		{ ICM_NAME,		"Change Your Name", 	50.0 }
	},
	p_CoinMarketPage 				[ MAX_PLAYERS char ],
	p_CoinMarketSelectedItem 		[ MAX_PLAYERS char ],

	Float: p_IrresistibleCoins 		[ MAX_PLAYERS ],
	p_ExtraAssetSlots 				[ MAX_PLAYERS char ]

;

/* ** Forwards ** */
forward Float: GetPlayerUpgradeVIPCost( playerid, Float: days_left = 30.0 );

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_IC_MARKET && response )
	{
		new current_vip = GetPlayerVIPLevel( playerid );
		new Float: days_left = float( GetPlayerVIPDuration( playerid ) ) / 86400.0;

		if ( listitem == sizeof( g_irresistibleVipItems ) )
		{
			new
				Float: upgrade_cost = floatround( GetPlayerUpgradeVIPCost( playerid, days_left ), floatround_ceil );

			if ( current_vip >= VIP_REGULAR && current_vip < VIP_GOLD && days_left >= 7.0 && upgrade_cost )
			{
				p_CoinMarketPage{ playerid } = ICM_PAGE_UPGRADE;
				return ShowPlayerDialog( playerid, DIALOG_YOU_SURE_VIP, DIALOG_STYLE_MSGBOX, ""COL_GOLD"Irresistible Coin -{FFFFFF} Confirmation", sprintf( ""COL_WHITE"Are you sure that you want to spend %s IC?", number_format( upgrade_cost, .decimals = 2 ) ), "Yes", "No" );
			}
			else
			{
				SendError( playerid, "Upgrading your V.I.P is currently unavailable." );
				return ShowPlayerCoinMarketDialog( playerid );
			}
		}
		else if ( listitem == sizeof( g_irresistibleVipItems ) + 1 ) {
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_CASHCARD );
		}
		else if ( listitem == sizeof( g_irresistibleVipItems ) + 2 ) {
			return ShowPlayerHomeListings( playerid );
		}
		else if ( listitem > sizeof( g_irresistibleVipItems ) + 2 ) {
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
		}
		else {
			new Float: iCoinRequirement = g_irresistibleVipItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
			new selected_vip = g_irresistibleVipItems[ listitem ] [ E_ID ];

			if ( current_vip > VIP_GOLD ) {
				current_vip = VIP_GOLD;
			}

			if ( current_vip != 0 && current_vip != selected_vip ) {
				if ( current_vip > selected_vip ) {
					SendError( playerid, "You must wait until your V.I.P is expired in order to downgrade it." );
				} else {
					SendError( playerid, "You must upgrade your current V.I.P level first." );
				}
				return ShowPlayerCoinMarketDialog( playerid );
			}

			p_CoinMarketPage{ playerid } = ICM_PAGE_DEFAULT;
			p_CoinMarketSelectedItem{ playerid } = listitem;
			return ShowPlayerDialog( playerid, DIALOG_YOU_SURE_VIP, DIALOG_STYLE_MSGBOX, ""COL_GOLD"Irresistible Coin -{FFFFFF} Confirmation", sprintf( ""COL_WHITE"Are you sure that you want to spend %s IC?", number_format( iCoinRequirement, .decimals = 2 ) ), "Yes", "No" );
		}
	}
	else if ( dialogid == DIALOG_IC_MARKET_2 || dialogid == DIALOG_IC_MARKET_3 )
	{
		if ( ! response )
			return ShowPlayerCoinMarketDialog( playerid );

		new Float: iCoinRequirement = GetGVarFloat( "vip_discount" );

		// assets
		if ( dialogid == DIALOG_IC_MARKET_2 ) {
			iCoinRequirement *= g_irresistibleMarketItems[ listitem ] [ E_PRICE ];
		}
		// cash cards
		else if ( dialogid == DIALOG_IC_MARKET_3 ) {
			iCoinRequirement *= g_irresistibleCashCards[ listitem ] [ E_PRICE ];
		}

		p_CoinMarketPage{ playerid } = ( dialogid == DIALOG_IC_MARKET_3 ) ? ICM_PAGE_CASHCARD : ICM_PAGE_ASSETS;
		p_CoinMarketSelectedItem{ playerid } = listitem;
		return ShowPlayerDialog( playerid, DIALOG_YOU_SURE_VIP, DIALOG_STYLE_MSGBOX, ""COL_GOLD"Irresistible Coin -{FFFFFF} Confirmation", sprintf( ""COL_WHITE"Are you sure that you want to spend %s IC?", number_format( iCoinRequirement, .decimals = 2 ) ), "Yes", "No" );
	}
	else if ( dialogid == DIALOG_YOU_SURE_VIP )
	{
		if ( !response )
			return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );

		new current_vip = GetPlayerVIPLevel( playerid );
		new Float: player_coins = GetPlayerIrresistibleCoins( playerid );
		new Float: days_left = float( GetPlayerVIPDuration( playerid ) ) / 86400.0;

		// restore listitem of whatever player selected
		listitem = p_CoinMarketSelectedItem{ playerid };

		// upgrade player vip
		if ( p_CoinMarketPage{ playerid } == ICM_PAGE_UPGRADE )
		{
			if ( current_vip >= VIP_REGULAR && current_vip < VIP_GOLD && days_left >= 7.0 )
			{
				new Float: upgrade_cost = floatround( GetPlayerUpgradeVIPCost( playerid, days_left ), floatround_ceil );
				new new_vip_item = ( current_vip == VIP_BRONZE ? 0 : 1 );

				if ( player_coins < upgrade_cost ) {
					SendError( playerid, "You need around %s coins before you can upgrade your V.I.P!", number_format( upgrade_cost - player_coins, .decimals = 2 ) );
					return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );
				}

				// if it's zero then the player is not regular/bronze
				if ( upgrade_cost )
				{
					// set level no interval, deduct and notify
					SetPlayerVipLevel( playerid, g_irresistibleVipItems[ new_vip_item ] [ E_ID ], .interval = 0 );
					GivePlayerIrresistibleCoins( playerid, -upgrade_cost );
					SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP PACKAGE]"COL_WHITE" You have upgraded to %s for %s Irresistible Coins!", g_irresistibleVipItems[ new_vip_item ] [ E_NAME ], number_format( upgrade_cost, .decimals = 0 ) );
				}
				else
				{
					SendError( playerid, "There seemed to be an error while upgrading your V.I.P, please contact Lorenc." );
				}
				return 1;
			}
			else
			{
				SendError( playerid, "Upgrading your V.I.P is currently unavailable." );
				return ShowPlayerCoinMarketDialog( playerid );
			}
		}

		// default page
		else if ( p_CoinMarketPage{ playerid } == ICM_PAGE_DEFAULT )
		{
			new Float: iCoinRequirement = g_irresistibleVipItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
			new selected_vip = g_irresistibleVipItems[ listitem ] [ E_ID ];

			if ( current_vip > VIP_GOLD ) {
				current_vip = VIP_GOLD;
			}

			if ( current_vip != 0 && current_vip != selected_vip ) {
				if ( current_vip > selected_vip ) {
					SendError( playerid, "You must wait until your V.I.P is expired in order to downgrade it." );
				} else {
					SendError( playerid, "You must upgrade your current V.I.P level first." );
				}
				return ShowPlayerCoinMarketDialog( playerid );
			}

			if ( player_coins < iCoinRequirement ) {
				SendError( playerid, "You need around %s coins before you can get this V.I.P!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
				return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );
			}

			// Deduct IC
			GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );

			// Set VIP Level
			SetPlayerVipLevel( playerid, selected_vip );

			// Send message
			SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP PACKAGE]"COL_WHITE" You have redeemed %s V.I.P for %s Irresistible Coins! Congratulations! :D", VIPToString( selected_vip ), number_format( iCoinRequirement, .decimals = 0 ) );

			// Redirect player
			ShowPlayerVipRedeemedDialog( playerid );
			return 1;
		}

		// buy cash cards
		else if ( p_CoinMarketPage{ playerid } == ICM_PAGE_CASHCARD )
		{
			new Float: iCoinRequirement = g_irresistibleCashCards[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );

			if ( player_coins < iCoinRequirement ) {
				SendError( playerid, "You need around %s coins before you can get this!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
				return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );
			}

			new cash_amount = g_irresistibleCashCards[ listitem ] [ E_ID ];

			GivePlayerCash( playerid, cash_amount );
			GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
			SendServerMessage( playerid, "You have ordered a "COL_GREEN"%s Cash Card (%s)"COL_WHITE" for %s Irresistible Coins!", g_irresistibleCashCards[ listitem ] [ E_NAME ], number_format( cash_amount ), number_format( iCoinRequirement, .decimals = 0 ) );
			ShowPlayerHelpDialog( playerid, 10000, "You have bought a ~g~%s~w~ %s Cash Card!", number_format( cash_amount ), g_irresistibleCashCards[ listitem ] [ E_NAME ] );
		}

		// all other market items
		else
		{
			new Float: iCoinRequirement = g_irresistibleMarketItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );

			if ( player_coins < iCoinRequirement ) {
				SendError( playerid, "You need around %s coins before you can get this!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
				return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );
			}

			new selectedItemID = g_irresistibleMarketItems[ listitem ] [ E_ID ];

			// show new name dialog before charging
			if ( selectedItemID == ICM_NAME ) {
				ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "Change your name", ""COL_WHITE"What would you like your new name to be? And also, double check!", "Change", "Back" );
			}
			else if ( selectedItemID == ICM_VEH_SLOT ) {
				if ( p_ExtraAssetSlots{ playerid } >= VIP_MAX_EXTRA_SLOTS ) {
					SendError( playerid, "You have reached the limit of additional slots (limit " #VIP_MAX_EXTRA_SLOTS ")." );
					return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
				}

				p_ExtraAssetSlots{ playerid } ++;
				GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
	    		SendServerMessage( playerid, "You have redeemed an "COL_GOLD"vehicle slot"COL_WHITE" for %s Irresistible Coins!", number_format( iCoinRequirement, .decimals = 0 ) );
    			AddPlayerNote( playerid, -1, sprintf( "Bought veh extra slot, has %d extra", p_ExtraAssetSlots{ playerid } ) );
			}
			else
			{
				GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
    			AddPlayerNote( playerid, -1, sprintf( ""COL_GOLD"%s" #COL_WHITE, g_irresistibleMarketItems[ listitem ] [ E_NAME ] ) );
    			SendClientMessageToAdmins( -1, ""COL_PINK"[DONOR NEEDS HELP]"COL_GREY" %s(%d) needs a %s. (/viewnotes)", ReturnPlayerName( playerid ), playerid, g_irresistibleMarketItems[ listitem ] [ E_NAME ] );
    			SendServerMessage( playerid, "You have ordered a "COL_GOLD"%s"COL_WHITE" for %s Irresistible Coins!", g_irresistibleMarketItems[ listitem ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
    			SendServerMessage( playerid, "Online admins have been notified of your purchase. Use "COL_GREY"/notes"COL_WHITE" to track your orders and to remind online admins." );
    			ShowPlayerHelpDialog( playerid, 10000, "You can use ~y~/notes~w~ to track your orders.~n~~n~Also, admins will be reminded using this command." );
			}

			/*case 8:
			{
				if ( ( iCoinRequirement = 100.0 * GetGVarFloat( "vip_discount" ) ) <= p_IrresistibleCoins[ playerid ] )
				{
			        new
			        	ownerid = INVALID_PLAYER_ID,
			        	vehicleid = GetPlayerVehicleID( playerid ),
			        	buyableid = getVehicleSlotFromID( vehicleid, ownerid ),
			        	modelid = GetVehicleModel( vehicleid )
			        ;

				    if ( !vehicleid ) SendError( playerid, "You need to be in a vehicle to use this command." );
					else if ( buyableid == -1 ) SendError( playerid, "This vehicle isn't a buyable vehicle." );
					else if ( playerid != ownerid ) SendError( playerid, "You are not the owner of this vehicle." );
					else if ( IsBoatVehicle( modelid ) || IsAirVehicle( modelid ) ) SendError( playerid, "You cannot apply gold rims to this type of vehicle." );
					else
					{
     					if ( AddVehicleComponent( vehicleid, 1080 ) )
     					{
					        if ( UpdateBuyableVehicleMods( playerid, buyableid ) )
					        {
					        	new
					        		szMods[ MAX_CAR_MODS * 10 ];

								for( new i; i < MAX_CAR_MODS; i++ )
									format( szMods, sizeof( szMods ), "%s%d.", szMods, g_vehicleModifications[ playerid ] [ buyableid ] [ i ] );

								format( szBigString, sizeof( szBigString ), "UPDATE `VEHICLES` SET `MODS`='%s' WHERE `ID`=%d", szMods, g_vehicleData[ playerid ] [ buyableid ] [ E_SQL_ID ] );
								mysql_single_query( szBigString );
					        }

							p_IrresistibleCoins[ playerid ] -= iCoinRequirement;
		    				SendServerMessage( playerid, "You have redeemed "COL_GOLD"Gold Rims"COL_WHITE" on your vehicle for %s Irresistible Coins!", number_format( iCoinRequirement, .decimals = 0 ) );

		    				// Receipt
	    					AddPlayerNote( playerid, -1, sprintf( "Bought gold rims on vehicle #%d", g_vehicleData[ playerid ] [ buyableid ] [ E_SQL_ID ] ) );
					   	}
					   	else SendError( playerid, "We were unable to place gold rims on this vehicle (0xF92D)." );
		    		}
					return ShowPlayerCoinMarketDialog( playerid, true );
				}
				else
				{
					SendError( playerid, "You need around %s coins before you can get this!", number_format( iCoinRequirement - p_IrresistibleCoins[ playerid ], .decimals = 2 ) );
					return ShowPlayerCoinMarketDialog( playerid, true );
				}
			}*/
		}
	}
	else if ( dialogid == DIALOG_CHANGENAME )
	{
		if ( !response )
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );

		new selected_item = p_CoinMarketSelectedItem{ playerid };

		if ( ! ( 0 <= selected_item < sizeof( g_irresistibleMarketItems ) && g_irresistibleMarketItems[ selected_item ] [ E_ID ] == ICM_NAME ) ) {
			return SendError( playerid, "Invalid option selected, please try again." );
		}

		new Float: iCoinRequirement = g_irresistibleMarketItems[ selected_item ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
		new Float: player_coins = GetPlayerIrresistibleCoins( playerid );

		if ( player_coins < iCoinRequirement ) {
			SendError( playerid, "You need around %s coins before you can get this!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
		}

		new szName[ 20 ];

		if ( sscanf( inputtext, "s[20]", szName ) ) SendError( playerid, "The name you have input is considered invalid." );
		else if ( !isValidPlayerName( szName ) ) SendError( playerid, "This name consists of invalid characters." );
		else {
			return mysql_function_query( dbHandle, sprintf( "SELECT `NAME` FROM `BANS` WHERE `NAME`='%s'", mysql_escape( szName ) ), true, "OnNewNameCheckBanned", "dfs", playerid, iCoinRequirement, szName );
		}
		return ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "Change your name", ""COL_WHITE"What would you like your new name to be? And also, double check!", "Change", "Back" );
	}
	else if ( dialogid == DIALOG_BUY_VIP && response )
	{
		return ShowPlayerCoinMarketDialog( playerid );
	}
	return 1;
}

/* ** Commands ** */
CMD:donate( playerid, params[ ] ) return cmd_vip( playerid, params );
CMD:vip( playerid, params[ ] )
{
	static
		vip_description[ 1300 ];

	if ( vip_description[ 0 ] == '\0' ) {
		vip_description = " \t"COL_WHITE"Regular VIP\t"COL_BRONZE"Bronze VIP\t"COL_GOLD"Gold V.I.P\n";
		strcat( vip_description, ""COL_GREEN"Price (USD)\t"COL_WHITE"$5.00 /mo\t"COL_BRONZE"$10.00 /mo\t"COL_GOLD"$18.00 /mo\n" );
		strcat( vip_description, "Total house slots\t5\t10\tunlimited\n" );
		strcat( vip_description, "Total garage slots*\t5\t10\tunlimited\n" );
		strcat( vip_description, "Total business slots\t5\t10\tunlimited\n" );
		strcat( vip_description, "Total vehicle slots\t5\t10\t20\n" );
		strcat( vip_description, "Weapons on spawn\t1\t2\t3\n" );
		strcat( vip_description, "Armour on spawn\t0%\t100%\t100%\n" );
		strcat( vip_description, "Coin generation increase\t0%\t10%\t25%\n" );
		strcat( vip_description, "Ability to transfer coins P2P\tN\tY\tY\n" );
		strcat( vip_description, "Ability to sell coins on the coin market (/ic sell)\tN\tY\tY\n" );
		strcat( vip_description, "Ability to use two jobs (/vipjob)\tN\tN\tY\n" );
		strcat( vip_description, "Premium home listing fees waived\tN\tN\tY\n" );
		strcat( vip_description, "Tax reduction\t0%\t0%\t50%\n" );
		strcat( vip_description, "Inactive asset protection\t14\t14\t30\n" );
		strcat( vip_description, "Total Vehicle component editing slots\t4\t6\t10\n" );
		strcat( vip_description, "Furniture slots available\t30\t40\t50\n" );
		strcat( vip_description, "V.I.P Lounge Weapon Redeeming Cooldown\t5 min\t1 min\tnone\n" );
		strcat( vip_description, "V.I.P Tag On Forum\tY\tY\tY\n" );
		strcat( vip_description, "Access to V.I.P chat\tY\tY\tY\n" );
		strcat( vip_description, "Access to V.I.P lounge\tY\tY\tY\n" );
		strcat( vip_description, "Can spawn with a specific skin\tY\tY\tY\n" );
		strcat( vip_description, "Access to V.I.P toys\tY\tY\tY\n" );
		strcat( vip_description, "Access to custom gang colors (/gangcolor)\tY\tY\tY\n" );
		strcat( vip_description, "Access to extra house weapon storage slots\tY\tY\tY\n" );
		strcat( vip_description, "Can play custom radio URLs (/radio)\tY\tY\tY\n" );
		strcat( vip_description, "Ability to adjust your label's color (/labelcolor)\tY\tY\tY\n" );
		strcat( vip_description, "Can show a message to people you kill (/deathmsg)\tY\tY\tY\n" );
		strcat( vip_description, "Can adjust the sound of your hitmarker (/hitmarker)\tY\tY\tY" );
	}
	ShowPlayerDialog( playerid, DIALOG_BUY_VIP, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Donate for V.I.P", vip_description, "Buy Now", "Close" );
	return 1;
}

/* ** Functions ** */
stock ShowPlayerCoinMarketDialog( playerid, page = ICM_PAGE_DEFAULT )
{
	// if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
	// 	return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	new Float: discount = GetGVarFloat( "vip_discount" );
	new szMarket[ 512 ] = ""COL_GREY"Item Name\t"COL_GREY"Coins Needed\n";

	if ( page == ICM_PAGE_DEFAULT || page == ICM_PAGE_UPGRADE )
	{
		new current_vip = GetPlayerVIPLevel( playerid );
		new Float: days_left = float( GetPlayerVIPDuration( playerid ) ) / 86400.0;

		if ( current_vip > VIP_GOLD ) {
			current_vip = VIP_GOLD;
		}

		for( new i = 0; i < sizeof( g_irresistibleVipItems ); i++ )
		{
			new Float: iCoinRequirement = g_irresistibleVipItems[ i ] [ E_PRICE ] * discount;

			if ( current_vip != 0 && current_vip != g_irresistibleVipItems[ i ] [ E_ID ] ) {
				format( szMarket, sizeof( szMarket ), "%s{333333}%s\t{333333}%s\n", szMarket, g_irresistibleVipItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
			} else {
				format( szMarket, sizeof( szMarket ), "%s%s\t"COL_GOLD"%s\n", szMarket, g_irresistibleVipItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
			}
		}

		// upgrade vip
		new
			Float: upgrade_cost = floatround( GetPlayerUpgradeVIPCost( playerid, days_left ), floatround_ceil );

		if ( current_vip >= VIP_REGULAR && current_vip < VIP_GOLD && days_left >= 7.0 && upgrade_cost )
		{
			format( szMarket, sizeof( szMarket ), "%sUpgrade V.I.P\t"COL_GOLD"%s\n", szMarket, number_format( upgrade_cost, .decimals = 0 ) );
		}
		else strcat( szMarket, "{333333}Upgrade V.I.P\t{333333}Unavailable\n" );

		// thats it
		strcat( szMarket, ""COL_GREEN"Buy shark cards...\t"COL_GREEN">>>\n" );
		strcat( szMarket, ""COL_PURPLE"Buy premium homes...\t"COL_PURPLE">>>\n" );
		strcat( szMarket, ""COL_GREY"See other items...\t"COL_GREY">>>" );
		return ShowPlayerDialog( playerid, DIALOG_IC_MARKET, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Irresistible Coin -{FFFFFF} Market", szMarket, "Select", "" );
	}
	else if ( page == ICM_PAGE_CASHCARD )
	{
		szMarket = ""COL_GREY"Cash Card\t"COL_GREY"Amount ($)\t"COL_GREY"Coins Needed\n";

		for( new i = 0; i < sizeof( g_irresistibleCashCards ); i++ )
		{
			new iCoinRequirement = floatround( g_irresistibleCashCards[ i ] [ E_PRICE ] * discount );
			format( szMarket, sizeof( szMarket ), "%s%s\t"COL_GREEN"%s\t"COL_GOLD"%s\n", szMarket, g_irresistibleCashCards[ i ] [ E_NAME ], number_format( g_irresistibleCashCards[ i ] [ E_ID ] ), number_format( iCoinRequirement, .decimals = 0 ) );
		}
		return ShowPlayerDialog( playerid, DIALOG_IC_MARKET_3, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Irresistible Coin -{FFFFFF} Cash Cards", szMarket, "Select", "Back" );
	}
	else
	{
		for( new i = 0; i < sizeof( g_irresistibleMarketItems ); i++ )
		{
			new iCoinRequirement = floatround( g_irresistibleMarketItems[ i ] [ E_PRICE ] * discount );
			format( szMarket, sizeof( szMarket ), "%s%s\t"COL_GOLD"%s\n", szMarket, g_irresistibleMarketItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
		}
		return ShowPlayerDialog( playerid, DIALOG_IC_MARKET_2, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Irresistible Coin -{FFFFFF} Asset Market", szMarket, "Select", "Back" );
	}
}

stock GetPlayerHouseSlots( playerid )
{
	new vip_level = GetPlayerVIPLevel( playerid );
	new slots = 3;

	switch( vip_level )
	{
		case VIP_GOLD, VIP_PLATINUM, VIP_DIAMOND:
			slots = 255; // 99 infinite

		case VIP_BRONZE:
			slots = 10;

		case VIP_REGULAR:
			slots = 5;
	}
	return slots; // + p_ExtraAssetSlots{ playerid };
}

stock GetPlayerBusinessSlots( playerid ) return GetPlayerHouseSlots( playerid );
stock GetPlayerGarageSlots( playerid ) return GetPlayerHouseSlots( playerid );

stock GetPlayerVehicleSlots( playerid )
{
	static const
		slots[ 4 ] = { 3, 5, 10, 20 };

	new vip_level = GetPlayerVIPLevel( playerid );

	return slots[ ( vip_level > VIP_GOLD ? VIP_GOLD : vip_level ) ] + p_ExtraAssetSlots{ playerid };
}

stock GetPlayerPimpVehicleSlots( playerid )
{
	static const
		slots[ 4 ] = { 3, 4, 6, 10 };

	new vip_level = GetPlayerVIPLevel( playerid );

	return slots[ ( vip_level > VIP_GOLD ? VIP_GOLD : vip_level ) ];
}

stock VIPToString( viplvl )
{
	static
		string[ 16 ];

	switch( viplvl )
	{
	    case VIP_DIAMOND: string = "Legacy Diamond";
	    case VIP_PLATINUM: string = "Legacy Platinum";
	    case VIP_GOLD: string = "Gold";
		case VIP_BRONZE: string = "Bronze";
		case VIP_REGULAR: string = "Regular";
		default: string = "N/A";
	}
	return string;
}

stock VIPToColor( viplvl )
{
	static
		string[ 16 ];

	switch( viplvl )
	{
	    case VIP_DIAMOND: string = COL_DIAMOND;
	    case VIP_PLATINUM: string = COL_PLATINUM;
	    case VIP_GOLD: string = COL_GOLD;
		case VIP_BRONZE: string = COL_BRONZE;
		case VIP_REGULAR: string = COL_GREY;
		default: string = COL_WHITE;
	}
	return string;
}

stock Float: GetPlayerUpgradeVIPCost( playerid, Float: days_left = 30.0 )
{
	new
		current_vip = GetPlayerVIPLevel( playerid );

	if ( current_vip != VIP_BRONZE && current_vip != VIP_REGULAR )
		return 0.0;

	new
		Float: total_cost = 0.0;

	switch ( current_vip )
	{
		case VIP_BRONZE: total_cost = g_irresistibleVipItems[ 0 ] [ E_PRICE ] - g_irresistibleVipItems[ 1 ] [ E_PRICE ];
		case VIP_REGULAR: total_cost = g_irresistibleVipItems[ 1 ] [ E_PRICE ] - g_irresistibleVipItems[ 2 ] [ E_PRICE ];
	}

	return total_cost * GetGVarFloat( "vip_discount" ) * ( days_left / 30.0 );
}
