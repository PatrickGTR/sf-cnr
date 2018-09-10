/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: anticheat\money.pwn
 * Purpose: server-sided money
 */

/* ** Variables ** */
static stock
 	p_Cash              			[ MAX_PLAYERS ];

/* ** Functions ** */
stock GivePlayerCash( playerid, money )
{
    p_Cash[ playerid ] += money;
    ResetPlayerMoney( playerid );
    GivePlayerMoney( playerid, p_Cash[ playerid ] );
}

stock SetPlayerCash( playerid, money )
{
    p_Cash[ playerid ] = money;
    ResetPlayerMoney( playerid );
    GivePlayerMoney( playerid, p_Cash[ playerid ] );
}

stock ResetPlayerCash( playerid )
{
    p_Cash[ playerid ] = 0;
    ResetPlayerMoney( playerid );
    GivePlayerMoney( playerid, p_Cash[ playerid ] );
}

stock GetPlayerCash( playerid )
{
	return p_Cash[ playerid ];
}
