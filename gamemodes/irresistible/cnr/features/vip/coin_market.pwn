/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\vip\coin_market.pwn
 * Purpose: coin market associated information
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined __cnr__irresistiblecoins
	#define __cnr__irresistiblecoins
#endif

/* ** Settings ** */
#define VIP_ALLOW_OVER_LIMIT 		( true ) // allow player from using house/vehicle/garage cmds if over the limit

#define VIP_MAX_EXTRA_SLOTS 		( 5 ) // max extra slots a person can buy

/* ** Coin Market VIP Levels ** */
#define VIP_REGULAR 				( 1 )
#define VIP_BRONZE 					( 2 )
#define VIP_GOLD 					( 3 )
#define VIP_PLATINUM 				( 4 )
#define VIP_DIAMOND 				( 5 )

/* ** Coin Market Pages ** */
#define ICM_PAGE_DEFAULT 			( 0 )
#define ICM_PAGE_CASHCARD 			( 1 )
#define ICM_PAGE_ASSETS 			( 2 )
//#define ICM_PAGE_UPGRADE 			( 3 )

/* ** Coin Market Items ** */
#define ICM_COKE_BIZ 				( 0 )
#define ICM_METH_BIZ 				( 1 )
#define ICM_WEED_BIZ 				( 2 )
#define ICM_HOUSE 					( 3 )
#define ICM_VEHICLE					( 4 )
#define ICM_GATE					( 5 )
#define ICM_GARAGE					( 6 )
#define ICM_NAME					( 7 )
#define ICM_VEH_SLOT 				( 8 )

/* ** Variables ** */
enum E_IC_MARKET_DATA
{
	E_ID,	E_NAME[ 19 ],	Float: E_PRICE,
	bool: E_MULTI_BUY,
};

static stock
	g_irresistibleVipItems			[ ] [ E_IC_MARKET_DATA ] =
	{
		{ VIP_DIAMOND,	"Diamond V.I.P",	10000.0 },
		{ VIP_PLATINUM,	"Platinum V.I.P",	5000.0 },
		{ VIP_GOLD,		"Gold V.I.P",		2500.0 },
		{ VIP_BRONZE,	"Bronze V.I.P", 	1500.0 },
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
		{ ICM_VEHICLE,	"Select Vehicle",		500.0 },
		{ ICM_HOUSE,	"Select House",			500.0 },
		{ ICM_GATE,		"Custom Gate",			350.0 },
		{ ICM_VEH_SLOT,	"Extra Vehicle Slot", 	350.0 },
		{ ICM_GARAGE,	"Select Garage", 		250.0 },
		{ ICM_NAME,		"Change Your Name", 	50.0 }
	},

	p_CoinMarketPage 				[ MAX_PLAYERS char ],
	p_CoinMarketSelectedItem 		[ MAX_PLAYERS char ]
;

/* ** Global Variables ** */
static stock
	p_ExtraAssetSlots 				[ MAX_PLAYERS char ],
	Float: p_IrresistibleCoins 		[ MAX_PLAYERS ]
;

/* ** Forwards ** */
forward Float: GetPlayerIrresistibleCoins( playerid );

/* ** Hooks ** */
#if defined SERVER_PLS_DONATE_MP3
hook OnServerGameDayEnd( )
{
	foreach ( new p : Player ) if ( ! p_VIPLevel[ p ] && ! IsPlayerUsingRadio( p ) )
	{
		PlayAudioStreamForPlayer( p, SERVER_PLS_DONATE_MP3 );
	}
	return 1;
}
#endif

hook OnPlayerUpdateEx( playerid )
{
	CheckPlayerVipExpiry( playerid );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	p_ExtraAssetSlots{ playerid } = 0;
	p_IrresistibleCoins[ playerid ] = 0.0;
	return 1;
}

hook OnPlayerRegister( playerid )
{
	p_IrresistibleCoins[ playerid ] = 0.0;
	return 1;
}

hook OnPlayerLogin( playerid )
{
	CheckPlayerVipExpiry( playerid );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_IC_MARKET && response )
	{
		//new current_vip = GetPlayerVIPLevel( playerid );

		if ( listitem == sizeof( g_irresistibleVipItems ) ) {
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_CASHCARD );
		}
		else if ( listitem == sizeof( g_irresistibleVipItems ) + 1 ) {
			return ShowPlayerHomeListings( playerid );
		}
		else if ( listitem > sizeof( g_irresistibleVipItems ) + 1 ) {
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
		}
		else {
			new Float: iCoinRequirement = g_irresistibleVipItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
			//new selected_vip = g_irresistibleVipItems[ listitem ] [ E_ID ];

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

		new Float: player_coins = GetPlayerIrresistibleCoins( playerid );

		// restore listitem of whatever player selected
		listitem = p_CoinMarketSelectedItem{ playerid };

		// default page
		if ( p_CoinMarketPage{ playerid } == ICM_PAGE_DEFAULT )
		{
			new Float: iCoinRequirement = g_irresistibleVipItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
			new selected_vip = g_irresistibleVipItems[ listitem ] [ E_ID ];

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
			if ( selected_vip == VIP_DIAMOND )
			{
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Diamond V.I.P, you have the option of gifting Gold VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else if ( selected_vip == VIP_PLATINUM )
			{
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Platinum V.I.P, you have the option of gifting Bronze VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else
			{
				ShowPlayerVipRedeemedDialog( playerid );
			}
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
					SendError( playerid, "You have reached the limit of additional slots (limit %d).", VIP_MAX_EXTRA_SLOTS );
					return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
				}

				p_ExtraAssetSlots{ playerid } ++;
				GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
	    		SendServerMessage( playerid, "You have redeemed an "COL_GOLD"vehicle slot"COL_WHITE" for %s Irresistible Coins!", number_format( iCoinRequirement, .decimals = 0 ) );
				mysql_single_query( sprintf( "UPDATE `USERS` SET `EXTRA_SLOTS` = %d WHERE `ID` = %d", p_ExtraAssetSlots{ playerid }, GetPlayerAccountID( playerid ) ) );
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
				if ( ( iCoinRequirement = 100.0 * GetGVarFloat( "vip_discount" ) ) <= GetPlayerIrresistibleCoins( playerid ) )
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

							GivePlayerIrresistibleCoins( playerid, - iCoinRequirement );
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
					SendError( playerid, "You need around %s coins before you can get this!", number_format( iCoinRequirement - GetPlayerIrresistibleCoins( playerid ), .decimals = 2 ) );
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
	else if ( dialogid == DIALOG_NEXT_PAGE_VIP && response )
	{
		static
			vip_description[ 1350 ];

		if ( vip_description[ 0 ] == '\0' )
		{
			vip_description = " \t"COL_PLATINUM"Platinum VIP\t"COL_DIAMOND"Diamond VIP\n";
			strcat( vip_description, ""COL_GREEN"Price (USD)\t"COL_GREEN"$50.00 USD\t"COL_GREEN"$100.00 USD\n" );
			strcat( vip_description, "Money Provided\t$12,500,000\t$25,000,000\n" );
			strcat( vip_description, "House Provided\tY\tY\n" );
			strcat( vip_description, "Vehicle Provided\tY\tY\n" );
			strcat( vip_description, "Garage Provided\tY\tY\n" );
			strcat( vip_description, "Gate Provided\tN\tY\n" );
			strcat( vip_description, "Weed Business Provided\tN\tY\n" );
			strcat( vip_description, "House Customization\tMedium\tLarge\n" );
			strcat( vip_description, "Total house slots\t10\tunlimited\n" );
			strcat( vip_description, "Total garage slots\t10\tunlimited\n" );
			strcat( vip_description, "Total business slots\t10\tunlimited\n" );
			strcat( vip_description, "Total vehicle slots\t10\t20\n" );
			strcat( vip_description, "Weapons on spawn\t2\t2\n" );
			strcat( vip_description, "Armour on spawn\t100%\t100%\n" );
			strcat( vip_description, "Coin generation increase\t10%\t25%\n" );
			strcat( vip_description, "Ability to transfer coins P2P\tY\tY\n" );
			strcat( vip_description, "Ability to sell coins on the coin market (/ic sell)\tY\tY\n" );
			strcat( vip_description, "Ability to use two jobs (/vipjob)\tY\tY\n" );
			strcat( vip_description, "Premium home listing fees waived\tY\tY\n" );
			strcat( vip_description, "Tax reduction\t0%\t50%\n" );
			strcat( vip_description, "Inactive asset protection\t14 days\t31 days\n" );
			strcat( vip_description, "Total Vehicle component editing slots\t8\t10\n" );
			strcat( vip_description, "Furniture slots available\t45\t50\n" );
			strcat( vip_description, "V.I.P Lounge Weapon Redeeming Cooldown\t1 min\tno limit\n" );
			strcat( vip_description, "V.I.P Tag On Forum\tY\tY\n" );
			strcat( vip_description, "Access to V.I.P chat\tY\tY\n" );
			strcat( vip_description, "Access to V.I.P lounge\tY\tY\n" );
			strcat( vip_description, "Can spawn with a specific skin\tY\tY\n" );
			strcat( vip_description, "Access to V.I.P toys\tY\tY\n" );
			strcat( vip_description, "Access to custom gang colors (/gangcolor)\tY\tY\n" );
			strcat( vip_description, "Access to extra house weapon storage slots\tY\tY\n" );
			strcat( vip_description, "Can play custom radio URLs (/radio)\tY\tY\n" );
			strcat( vip_description, "Ability to adjust your label's color (/labelcolor)\tY\tY\n" );
			strcat( vip_description, "Can show a message to people you kill (/deathmsg)\tY\tY\n" );
			strcat( vip_description, "Can adjust the sound of your hitmarker (/hitmarker)\tY\tY\n" );
		}
		return ShowPlayerDialog( playerid, DIALOG_BUY_VIP, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Donate for V.I.P", vip_description, "Buy VIP", "Close" );
	}
	else if ( dialogid == DIALOG_BUY_VIP && response )
	{
		return ShowPlayerCoinMarketDialog( playerid );
	}
	else if ( dialogid == DIALOG_DONATED_PLATBRONZE )
	{
		if ( response )
		{
			new
				pID;

			if ( sscanf( inputtext, "u", pID ) )
			{
				SendError( playerid, "Please enter a player's ID or name." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Platinum V.I.P, you have the option of gifting Bronze VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else if ( !IsPlayerConnected( pID ) )
			{
				SendError( playerid, "This player is not connected." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Platinum V.I.P, you have the option of gifting Bronze VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[V.I.P]"COL_WHITE" You have gifted Bronze V.I.P to %s(%d)!", ReturnPlayerName( pID ), pID );
				SetPlayerVipLevel( pID, VIP_BRONZE );
				ShowPlayerVipRedeemedDialog( playerid );
			}
		}
		else
		{
	 		AddPlayerNote( playerid, -1, "{CD7F32}Bronze V.I.P" #COL_WHITE );
			SendServerMessage( playerid, "This has been noted down for your account and will be given to you at a stage that you want, contact an executive." );
			ShowPlayerVipRedeemedDialog( playerid );
		}
	}
	else if ( dialogid == DIALOG_DONATED_DIAGOLD )
	{
		if ( response )
		{
			new
				pID;

			if ( sscanf( inputtext, "u", pID ) )
			{
				SendError( playerid, "Please enter a player's ID or name." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Diamond V.I.P, you have the option of gifting Gold VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else if ( !IsPlayerConnected( pID ) )
			{
				SendError( playerid, "This player is not connected." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"As you've redeemed Diamond V.I.P, you have the option of gifting Gold VIP to someone.\n\nIf you would like to gift it to yourself, type your name/id or the person you're gifting it to.\n\n"COL_ORANGE"If you just don't know yet, cancel and PM Lorenc on the forum when you make a decision!", "Gift it!", "I'll Think!" );
			}
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[V.I.P]"COL_WHITE" You have gifted Gold V.I.P to %s(%d)!", ReturnPlayerName( pID ), pID );
				SetPlayerVipLevel( pID, VIP_GOLD );
				ShowPlayerVipRedeemedDialog( playerid );
			}
		}
		else
		{
	 		AddPlayerNote( playerid, -1, ""COL_GOLD"Gold V.I.P" #COL_WHITE );
			SendServerMessage( playerid, "This has been noted down for your account and will be given to you at a stage that you want, contact an executive." );
			ShowPlayerVipRedeemedDialog( playerid );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:ic( playerid, params[ ] ) return cmd_irresistiblecoins( playerid, params );
CMD:irresistiblecoins( playerid, params[ ] )
{
	if ( ! IsPlayerSecurityVerified( playerid ) )
		return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	if ( strmatch( params, "balance" ) )
	{
		return SendServerMessage( playerid, "You currently have precisely "COL_GOLD"%s"COL_WHITE" Irresistible Coins!", number_format( GetPlayerIrresistibleCoins( playerid ) ) );
	}
	else if ( strmatch( params, "market" ) )
	{
		return ShowPlayerCoinMarketDialog( playerid );
	}
	else if ( !strcmp( params, "send", false, 4 ) )
	{
		new
			senttoid, Float: coins;

	    if ( sscanf( params[ 5 ],"uf", senttoid, coins ) ) return SendUsage( playerid, "/irresistiblecoins send [PLAYER_ID] [COINS]" );
	    else if ( !IsPlayerConnected( senttoid ) || IsPlayerNPC( senttoid ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( p_VIPLevel[ playerid ] < VIP_BRONZE ) return SendError( playerid, "You are not a Bronze V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
	    else if ( coins < 0.1 || coins > 10000.0 ) return SendError( playerid, "You can only send between 0.1 and 10,000.0 coins at a single time." );
		else if ( coins > 99999999 || coins < 0 ) return SendError( playerid, "You can only send between 0.1 and 5,000.0 coins at a single time." ); // Making cash go over billions...
	    else if ( GetPlayerIrresistibleCoins( playerid ) < coins ) return SendError( playerid, "You do not have this number of coins to send." );
	    else if ( GetPlayerScore( playerid ) < 1000 ) return SendError( playerid, "You need at least 1,000 score to send coins to other players." );
		else if ( senttoid == playerid ) return SendError( playerid, "You cannot send yourself coins." );
	    else
	    {
	    	if ( GetDistanceBetweenPlayers( playerid, senttoid ) > 8.0 || p_Spectating{ senttoid } )
				return SendError( playerid, "Please make sure you are close to the player before sending coins to them." );

	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS_IC` (`TO_ID`, `FROM_ID`, `IC`) VALUES (%d, %d, %f)", p_AccountID[ senttoid ], p_AccountID[ playerid ], coins );
	     	mysql_single_query( szNormalString );

	    	GivePlayerIrresistibleCoins( senttoid, coins );
	    	GivePlayerIrresistibleCoins( playerid, -coins );

	    	SendServerMessage( playerid, "You have sent "COL_GOLD"%s"COL_WHITE" Irresistible Coins to %s(%d)!", number_format( coins, .decimals = 2 ), ReturnPlayerName( senttoid ), senttoid );
	    	SendServerMessage( senttoid, "You have received "COL_GOLD"%s"COL_WHITE" Irresistible Coins from %s(%d)!", number_format( coins, .decimals = 2 ), ReturnPlayerName( playerid ), playerid );
		}
		return 1;
	}
	return SendUsage( playerid, "/irresistiblecoins [BALANCE/BUY/SELL/MARKET/SEND/CANCEL]" );
}

CMD:donate( playerid, params[ ] ) return cmd_vip( playerid, params );
CMD:vip( playerid, params[ ] )
{
	static
		vip_description[ 1420 ];

	if ( vip_description[ 0 ] == '\0' )
	{
		vip_description = " \t"COL_WHITE"Regular VIP\t"COL_BRONZE"Bronze VIP\t"COL_GOLD"Gold VIP\n";
		strcat( vip_description, ""COL_GREEN"Price (USD)\t"COL_GREEN"$5.00 USD\t"COL_GREEN"$15.00 USD\t"COL_GREEN"$25.00 USD\n" );
		strcat( vip_description, "Money Provided\t$500,000\t$2,500,000\t$5,000,000\n" );
		strcat( vip_description, "House Provided\tN\tY\tY\n" );
		strcat( vip_description, "Vehicle Provided\tN\tN\tY\n" );
		strcat( vip_description, "Garage Provided\tN\tN\tN\n" );
		strcat( vip_description, "Gate Provided\tN\tN\tN\n" );
		strcat( vip_description, "Weed Business Provided\tN\tN\tN\n" );
		strcat( vip_description, "House Customization\tN\tN\tSmall\n" );
		strcat( vip_description, "Total house slots\t5\t6\t8\n" );
		strcat( vip_description, "Total garage slots\t5\t6\t8\n" );
		strcat( vip_description, "Total business slots\t5\t6\t8\n" );
		strcat( vip_description, "Total vehicle slots\t3\t4\t6\n" );
		strcat( vip_description, "Weapons on spawn\t1\t1\t2\n" );
		strcat( vip_description, "Armour on spawn\t0%\t0%\t100%\n" );
		strcat( vip_description, "Coin generation increase\t0%\t0%\t0%\n" );
		strcat( vip_description, "Ability to transfer coins P2P\tN\tY\tY\n" );
		strcat( vip_description, "Ability to sell coins on the coin market (/ic sell)\tN\tY\tY\n" );
		strcat( vip_description, "Ability to use two jobs (/vipjob)\tN\tN\tN\n" );
		strcat( vip_description, "Premium home listing fees waived\tN\tN\tN\n" );
		strcat( vip_description, "Tax reduction\t0%\t0%\t0%\n" );
		strcat( vip_description, "Inactive asset protection\t14 days\t14 days\t14 days\n" );
		strcat( vip_description, "Total Vehicle component editing slots\t3\t4\t6\n" );
		strcat( vip_description, "Furniture slots available\t30\t35\t40\n" );
		strcat( vip_description, "V.I.P Lounge Weapon Redeeming Cooldown\t5 min\t5 min\t5 min\n" );
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
		strcat( vip_description, "Can adjust the sound of your hitmarker (/hitmarker)\tY\tY\tY\n" );
	}
	ShowPlayerDialog( playerid, DIALOG_NEXT_PAGE_VIP, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Donate for V.I.P", vip_description, "See More", "Close" );
	return 1;
}

CMD:vipcmds( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < 1 ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );

	erase( szLargeString );
	strcat( szLargeString,	""COL_GREY"/vipspawnwep\tConfigure your spawning weapons\n"\
							""COL_GREY"/vipskin\tConfigure your spawning skin\n"\
							""COL_GREY"/vipgun\tRedeem weapons or an armour vest from the gun locker\n"\
							""COL_GREY"/vsay\tGlobal V.I.P Chat\n" );
	strcat( szLargeString,	""COL_GREY"/vipjob\tSet your secondary VIP job\n"\
							""COL_GREY"/vippackage\tCustomize your VIP package name\n"\
							""COL_GREY"/mynotes\tAccess your VIP notes and material\n"\
							""COL_GREY"/mycustomizations\tAccess your house customization taxes" );

	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, "{FFFFFF}V.I.P Commands", szLargeString, "Okay", "" );
	return 1;
}

/* ** Functions ** */
stock ShowPlayerCoinMarketDialog( playerid, page = ICM_PAGE_DEFAULT )
{
	// if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
	// 	return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	new Float: discount = GetGVarFloat( "vip_discount" );
	new szMarket[ 512 ] = ""COL_GREY"Item Name\t"COL_GREY"Coins Needed\n";

	if ( page == ICM_PAGE_DEFAULT )
	{
		//new current_vip = GetPlayerVIPLevel( playerid );

		for( new i = 0; i < sizeof( g_irresistibleVipItems ); i++ )
		{
			new Float: iCoinRequirement = g_irresistibleVipItems[ i ] [ E_PRICE ] * discount;

			/*if ( current_vip != 0 && current_vip != g_irresistibleVipItems[ i ] [ E_ID ] ) {
				format( szMarket, sizeof( szMarket ), "%s{333333}%s\t{333333}%s\n", szMarket, g_irresistibleVipItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
			} else { }*/

			format( szMarket, sizeof( szMarket ), "%s%s\t"COL_GOLD"%s\n", szMarket, g_irresistibleVipItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
		}

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
		case VIP_DIAMOND:
			slots = 255; // infinite

		case VIP_PLATINUM:
			slots = 10;

		case VIP_GOLD:
			slots = 8;

		case VIP_BRONZE:
			slots = 6;

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
		slots[ 6 ] = { 3, 4, 6, 8, 10, 20 };

	return slots[ GetPlayerVIPLevel( playerid ) ] + p_ExtraAssetSlots{ playerid };
}

stock GetPlayerPimpVehicleSlots( playerid )
{
	static const
		slots[ 6 ] = { 2, 3, 4, 6, 8, 10 };

	return slots[ GetPlayerVIPLevel( playerid ) ];
}

stock VIPToString( viplvl )
{
	static
		string[ 16 ];

	switch( viplvl )
	{
	    case VIP_DIAMOND: string = "Diamond";
	    case VIP_PLATINUM: string = "Platinum";
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

stock SetPlayerVipLevel( playerid, level, interval = 2592000, bool: credit_assets = true )
{
	if ( ! IsPlayerConnected( playerid ) )
		return;

	// force upgrade
	if ( p_VIPLevel[ playerid ] < level ) {
		p_VIPLevel[ playerid ] = level;
	}

	// check if player already has vip
	if ( level ) {
	    if ( p_VIPExpiretime[ playerid ] > g_iTime ) p_VIPExpiretime[ playerid ] += interval;
	    else p_VIPExpiretime[ playerid ] += ( g_iTime + interval );
	}

	// expire the players vip if level 0
	else {
		p_VIPExpiretime[ playerid ] = 0;
	}

	// give player appropriate notes/items
	if ( credit_assets )
	{
		switch ( level )
		{
			case VIP_REGULAR:
			{
				GivePlayerCash( playerid, 500000 );
			}
			case VIP_BRONZE:
			{
				GivePlayerCash( playerid, 2500000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P House (Bronze)" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
			case VIP_GOLD:
			{
				GivePlayerCash( playerid, 5000000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P House (Gold)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P Vehicle (Gold)" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House and Vehicle. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
			case VIP_PLATINUM:
			{
				GivePlayerCash( playerid, 12500000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P House (Platinum)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P Vehicle (Platinum)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P Garage" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House, Vehicle and Garage. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
			case VIP_DIAMOND:
			{
				GivePlayerCash( playerid, 25000000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P House (Diamond)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P Vehicle (Diamond)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P Garage (Diamond)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P Gate (Diamond)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "V.I.P Weed Business (Diamond)" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House, Vehicle, Garage, Gate and Weed Biz. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
		}
	}
}

static stock CheckPlayerVipExpiry( playerid )
{
    if ( p_VIPLevel[ playerid ] > 0 && g_iTime > p_VIPExpiretime[ playerid ] )
    {
		SetPlayerArmour( playerid, 0.0 );
        p_VIPExpiretime[ playerid ] = 0;
        SendClientMessage( playerid, -1, ""COL_GREY"[NOTIFICATION]"COL_WHITE" Your V.I.P has expired, consider another donation to have your V.I.P restored again for another period." );
        p_VIPLevel[ playerid ] = 0;
        p_VIPWep1{ playerid } = 0;
        p_VIPWep2{ playerid } = 0;
        p_VIPWep3{ playerid } = 0;
	}
}

static stock ShowPlayerVipRedeemedDialog( playerid )
{
	szLargeString[ 0 ] = '\0';
	strcat( szLargeString,	""COL_WHITE"You've just blew quite a bit of Irresistible Coins for your V.I.P, so congratulations! :D\n\n"\
							""COL_GREY" * What are the commands?"COL_WHITE" Use /vipcmds to view a detailed list of VIP commands.\n"\
							""COL_GREY" * What did I receive?"COL_WHITE" Check through your V.I.P package contents via our site (forum -> announcements board).\n" );
	strcat( szLargeString,	""COL_GREY" * How to redeem my houses/vehicles?"COL_WHITE" You will be announced to the admins and noted down for assistance, so please wait!\n"\
							""COL_GREY" * I'm unsure, help?"COL_WHITE" If you have any questions, please /ask otherwise enquire Lorenc via the forums!\n\nThanks for choosing to spend your Irresistible Coins, enjoy what you've got! :P"  );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", szLargeString, "Got it!", "" );
}

stock SendClientMessageToVips( colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

	foreach ( new i : Player ) if ( p_VIPLevel[ i ] >= VIP_REGULAR ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock IsPlayerPlatinumVIP( playerid ) return p_VIPLevel[ playerid ] >= VIP_PLATINUM;

stock Float: GetPlayerIrresistibleCoins( playerid ) {
	return p_IrresistibleCoins[ playerid ];
}

stock GivePlayerIrresistibleCoins( playerid, Float: amount )
{
	// set variable prior, then just save the value of it
	p_IrresistibleCoins[ playerid ] += amount;

	// save player coins on a out/inflow of coins
	mysql_single_query( sprintf( "UPDATE `USERS` SET `COINS` = %f WHERE `ID` = %d", p_IrresistibleCoins[ playerid ], GetPlayerAccountID( playerid ) ) );
}

stock SetPlayerIrresistibleCoins( playerid, Float: amount ) {
	GivePlayerIrresistibleCoins( playerid, - p_IrresistibleCoins[ playerid ] + amount );
}

stock SetPlayerExtraSlots( playerid, slots ) {
	p_ExtraAssetSlots{ playerid } = slots;
}
