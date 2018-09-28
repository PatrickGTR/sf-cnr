/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\random_messages.pwn
 * Purpose: make bot (Stephanie) randomly send global messages about the server
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	g_randomMessages 				[ ] [ 137 ] =
	{
		{ "{8ADE47}Stephanie:"COL_WHITE" You can buy ropes at Supa Save or a 24/7 store to tie people up!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Save us on your favourites so you don't miss out on the action!" },
        { "{8ADE47}Stephanie:"COL_WHITE" You can catch updates on our website - "#SERVER_WEBSITE"!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Interested in getting V.I.P? Type "COL_GREY"/vip"COL_WHITE" for more details!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Consider helping the community by donating! You will receive Irresistible Coins to redeem V.I.P!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Just donated? Check your e-mail for a transaction ID and redeem your coins easily with /donated!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Do not share your password with anyone, or even use it in a friends server!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Trouble getting to places? Use "COL_GREY"/gps{FFFFFF} inside a vehicle!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Donors receive a Irresistible Coins in return of their generous donation, used to redeem V.I.P!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Rob stores and earn score, the more XP you have, the more benefits you gain!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Houses are buyable, you can buy one and set your spawning location inside that house!" },
        { "{8ADE47}Stephanie:"COL_WHITE" Remember to check the "COL_GREY"/rules{FFFFFF}! Disobeying the rules can lead to punishment!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Seen a cheater? Use "COL_GREY"/report {FFFFFF}to tell an admin." },
		{ "{8ADE47}Stephanie:"COL_WHITE" To change your class, type "COL_GREY"/changeclass{FFFFFF}." },
		// { "{8ADE47}Stephanie:"COL_WHITE" Detaining a suspect as a cop pays more than arresting by itself, and killing." },
		{ "{8ADE47}Stephanie:"COL_WHITE" Being annoyed by some member via PM? "COL_GREY"/dnd{FFFFFF} to block them!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" See "COL_GREY"/animlist {FFFFFF}for animations." },
		{ "{8ADE47}Stephanie:"COL_WHITE" Type "COL_GREY"/help {FFFFFF}for information on the server!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Need a set of commands to view? Use "COL_GREY"/cmds{FFFFFF}!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" To give money to a player, use "COL_GREY"/sendmoney{FFFFFF} or "COL_GREY"/sm{FFFFFF} for short." },
		{ "{8ADE47}Stephanie:"COL_WHITE" Get V.I.P with Irresistible Coins! Consider donating by visiting our site to get more!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" To explode the bank vault, or the jail cells; plant C4 by the two cells then explode!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Tired of a player? You can place a contract on their head with "COL_GREY"/placehit{FFFFFF}!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Need a label on your head with an informative message? You can use "COL_GREY"/label{FFFFFF}!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" The golden bar at the bottom right of your screen is the amount of XP you have!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Follow us on twitter! "COL_GREY"@IrresistibleDev{FFFFFF}!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Holding "COL_GREY"LEFT ALT{FFFFFF} and "COL_GREY"SPACE{FFFFFF} stops the current radio you're playing." },
		{ "{8ADE47}Stephanie:"COL_WHITE" You can change your current job at the "COL_GREY"City Hall{FFFFFF}!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" You can change your spawning city at the "COL_GREY"City Hall{FFFFFF}!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" You can buy fancy toys at a "COL_GREY"Pawnshop{FFFFFF}!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Never share your password, not even with the server owner!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" You can access our Discord server at {7289da}sfcnr.com/discord" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Locate ChuffSec's security truck with "COL_GREY"/chuffloc{FFFFFF} and rob his security truck for cash!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Buy a "COL_GREY"Money Case{FFFFFF} to increase your robbery loot from Supa Save or a 24/7 store! " },
		{ "{8ADE47}Stephanie:"COL_WHITE" Grab a truck, connect it to a trailer then begin to "COL_GREY"/work{FFFFFF}! It's rewarding!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Looking for something to do? Work on your "COL_GREY"/achievements"COL_WHITE"!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Check your global SF-CNR rank with "COL_GREY"/rank"COL_WHITE"!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Consider mining some ores near Jizzy's or at the Quarry! It's some fine pay!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" See how many Irresistible Coins you generated with "COL_GREY"/irresistiblecoins"COL_WHITE"." },
		{ "{8ADE47}Stephanie:"COL_WHITE" Split your robbing profits with your gang members using "COL_GREY"/gang splitprofit"COL_WHITE"." },
		{ "{8ADE47}Stephanie:"COL_WHITE" Toggle your total coins generated bar with "COL_GREY"/cp"COL_WHITE"." },
		{ "{8ADE47}Stephanie:"COL_WHITE" Be assigned to a rank by playing the game frequently, making use of all features!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" View the current robbing, arresting and killing streak that you are on with "COL_GREY"/streaks"COL_WHITE"!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Check out what your favourite weapon is with "COL_GREY"/weaponstats"COL_WHITE"!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" The secret monthly top donor can claim a prize at the end of the month!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Got any feedback for the server? Use "COL_GREY"/feedback"COL_WHITE"!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Attach an email to your account using "COL_GREY"/email"COL_WHITE" for security features and free 3 days of VIP!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Want to form a criminal enterprise? Create a gang and invite your friends with "COL_GREY"/gang create"COL_WHITE"!" },
		{ "SLOT_MACHINES" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Play roulette at a casino and win up to 35x on the money you place on a single number!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Play blackjack at a casino and double your money very quickly!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Play Poker with your friends at any casino! Beat your way to riches!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Get casino rewards points by gambling at any casino! Use "COL_GREY"/casino rewards"COL_WHITE" to spend them!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Race your friends in a street race or outrun race by using "COL_GREY"/race"COL_WHITE"!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Want 3 days of free V.I.P? Add an "COL_GREY"/email"COL_WHITE" to your account!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Contribute to our feature "COL_GREY"/crowdfunds"COL_WHITE"! Early supporters get benefits!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" Don't want to be interrupted as an innocent player? Enter passive mode with "COL_GREY"/passive"COL_WHITE"!" },
		{ "{8ADE47}Stephanie:"COL_WHITE" You can buy premium player homes using "COL_GREY"/estate"COL_WHITE"!" }
		{ "{8ADE47}Stephanie:"COL_WHITE" You can buy Irresistible Coins from players using "COL_GREY"/ic buy"COL_WHITE"!" }
	},
	g_randomMessageTick 			= 0
;

/* ** Hooks ** */
hook OnServerUpdate( )
{
	if ( GetServerTime( ) > g_randomMessageTick )
	{
		new
			iRandomMessage = random( sizeof( g_randomMessages ) );

		if ( strmatch( g_randomMessages[ iRandomMessage ], "SLOT_MACHINES" ) )
		{
			new
				iRandom = random( 3 );

			if ( iRandom == 2 )
				SendClientMessageToAllFormatted( -1, "{8ADE47}Stephanie:"COL_WHITE" The Visage Casino has a prize pool of "COL_GREY"%s"COL_WHITE", use a slot machine to try win!", cash_format( g_casinoPoolData[ 2 ] [ E_POOL ] ) );
			else if ( iRandom == 1 )
				SendClientMessageToAllFormatted( -1, "{8ADE47}Stephanie:"COL_WHITE" 4 Dragons Casino has a prize pool of "COL_GREY"%s"COL_WHITE", use a slot machine to try win!", cash_format( g_casinoPoolData[ 1 ] [ E_POOL ] ) );
			else
				SendClientMessageToAllFormatted( -1, "{8ADE47}Stephanie:"COL_WHITE" Caligulas Casino has a prize pool of "COL_GREY"%s"COL_WHITE", use a slot machine to try win!", cash_format( g_casinoPoolData[ 0 ] [ E_POOL ] ) );
		}
		else
		{
	 		SendClientMessageToAll( -1, g_randomMessages[ iRandomMessage ] );
		}

		// throttle
		g_randomMessageTick = GetServerTime( ) + 30;
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}
