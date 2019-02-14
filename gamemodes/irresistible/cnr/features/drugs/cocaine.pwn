/*
 * Irresistible Gaming (c) 2018
 * Developed by Owen
 * Module: cnr\features\cocaine.pwn
 * Purpose: cocaine system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define COCAINE_PER_PRICE 			( 4000 )

/* ** Variables ** */
static stock 
	Text3D: p_CocaineLabel 			[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	p_CokeTimer                     [ MAX_PLAYERS ],
	p_CokeGrams                     [ MAX_PLAYERS ],
	p_CokeCountdown                 [ MAX_PLAYERS ],

	g_CocaineCheckpoint             = -1
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	g_CocaineCheckpoint = CreateDynamicCP( 2186.1523, -1203.6077, 1049.0308, 1.0, 0, 6 );
	CreateDynamic3DTextLabel( "[BUY COCAINE]", COLOR_GOLD, 2186.1523, -1203.6077, 1049.0308, 20.0 );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	p_CokeGrams[ playerid ] = 0;
	DestroyDynamic3DTextLabel( p_CocaineLabel[ playerid ] );
	p_CocaineLabel[ playerid ] = Text: INVALID_3DTEXT_ID;
	return 1;
}

#if defined AC_INCLUDED
public OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
public OnPlayerDeath( playerid, killerid, reason )
#endif
{
	DestroyDynamic3DTextLabel( p_CocaineLabel[ playerid ] );
	p_CocaineLabel[ playerid ] = Text: INVALID_3DTEXT_ID;
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( checkpointid == g_CocaineCheckpoint )
		return ShowPlayerDialog( playerid, DIALOG_COKE, DIALOG_STYLE_INPUT, ""COL_WHITE"Purchase Cocaine", ""COL_WHITE"How many grams do you want to buy?", "Select", "Cancel" ), 1;
	
	return 1;
}

public OnPlayerTakenDamage( playerid, issuerid, Float: amount, weaponid, bodypart )
{
	new 
		iVehicle = GetPlayerVehicleID( issuerid );
	
	if ( IsPlayerOnCocaine( playerid ) && IsPlayerArmy( issuerid ) && iVehicle == 425 || iVehicle == 520 || iVehicle == 432 )
		return ShowPlayerHelpDialog( playerid, 2000, "You are immune from army vehicles since you're using cocaine" ), 0;

	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_COKE )
	{
		if ( ! response ) {
			return SendServerMessage( playerid, "Come back when you're done fucking around." );
		}

		new 
			iAmount;
		
		if ( sscanf( inputtext, "d", iAmount ) ) return ShowPlayerDialog( playerid, DIALOG_COKE, DIALOG_STYLE_INPUT, ""COL_WHITE"Purchase Cocaine", ""COL_WHITE"How many grams do you want to buy?\n\n"COL_RED"You must use a valid value.", "Select", "Cancel" );
		else if ( iAmount < 1 ) return ShowPlayerDialog( playerid, DIALOG_COKE, DIALOG_STYLE_INPUT, ""COL_WHITE"Purchase Cocaine", ""COL_WHITE"How many grams do you want to buy?\n\n"COL_RED"The minimum number of grams you can buy is 1.", "Select", "Cancel" );
		else if ( ( iAmount * COCAINE_PER_PRICE ) > GetPlayerCash( playerid ) ) return ShowPlayerDialog( playerid, DIALOG_COKE, DIALOG_STYLE_INPUT, ""COL_WHITE"Purchase Cocaine", ""COL_WHITE"How many grams do you want to buy?\n\n"COL_RED"You don't have enough money!", "Select", "Cancel" );
		else
		{
			new
				iPrice = ( iAmount * COCAINE_PER_PRICE );

			SendServerMessage( playerid, "You have purchased %d gram(s) of Cocaine for "COL_GOLD"%s"COL_WHITE".", iAmount, cash_format( iPrice ) );

			GivePlayerCash( playerid, - iPrice );
			return GivePlayerCocaine( playerid, iAmount );
		}

		return 1;
	}

	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( p_CocaineLabel[ playerid ] != Text3D: INVALID_3DTEXT_ID )
		UpdateDynamic3DTextLabelText( p_CocaineLabel[ playerid ], setAlpha( COLOR_WHITE, floatround( ( float( GetPlayerDrunkLevel( playerid ) ) / 5000.0 ) * 255.0 ) ), "Sniffed Coke Recently!" );

	return 1;
}

/* ** Functions ** */
stock IsPlayerOnCocaine( playerid ) 
	return ( p_CocaineLabel[ playerid ] != Text3D: INVALID_3DTEXT_ID );

stock GivePlayerCocaine( playerid, value ) {
	p_CokeGrams[ playerid ] += value;
}

/* ** Commands ** */
CMD:coke( playerid, params[ ] )
{
	new 
		Float: X, Float: Y, Float: Z;
    
	if ( p_Class[ playerid ] != CLASS_CIVILIAN )
		return SendError( playerid, "You are not a civilian." );

	if ( IsPlayerTied( playerid ) || IsPlayerTazed( playerid ) || IsPlayerCuffed( playerid ) || IsPlayerJailed( playerid ) || IsPlayerInMinigame( playerid ) )
		return SendError( playerid, "You cannot use this command at the moment." );

	if ( strmatch( params, "use" ) )
	{
    	if ( GetPVarInt( playerid, "coke_timestamp" ) > g_iTime ) return SendError( playerid, "You must wait at least %d seconds before using this command.", GetPVarInt( playerid, "coke_timestamp" ) - g_iTime );
		if ( p_CokeGrams[ playerid ] < 1 ) return SendError( playerid, "You don't have any coke with you." );
		if ( p_Jailed{ playerid } == true ) return SendError( playerid, "You cannot use this in jail." );
		if ( IsPlayerLoadingObjects( playerid ) ) return SendError( playerid, "You're in a object-loading state, please wait." );
		if ( IsPlayerAttachedObjectSlotUsed( playerid, 0 ) ) return SendError( playerid, "You cannot use this command since you're robbing." );
		if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
		SetPVarInt( playerid, "coke_timestamp", g_iTime + 120 );
		p_CokeGrams[ playerid ] --;
		SetPlayerHealth( playerid, 150 );
		SendServerMessage( playerid, "You have snorted a gram of coke." );
		SendServerMessage( playerid, "You are invincible against Army Vehicles for 15 seconds!" );
		DestroyDynamic3DTextLabel( p_CocaineLabel[ playerid ] );
		p_CocaineLabel[ playerid ] = CreateDynamic3DTextLabel( "Sniffed Coke Recently!", COLOR_WHITE, X, Y, Z + 1.0, 15, playerid );
		return 1;
	}
	else
	{
		return SendUsage( playerid, "/coke [USE]" ), 1;
	}
	return 1;
}

/*

		
*/