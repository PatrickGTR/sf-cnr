/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\random_hits.pwn
 * Purpose: a system to place random hits on players by the server
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnScriptInit( )
{
	AddServerVariable( "hitman_budget", "0", GLOBAL_VARTYPE_INT );
    return 1;
}

hook OnServerGameDayEnd( )
{
	new
        hitman_budget = GetGVarInt( "hitman_budget" );

	if ( hitman_budget > 0 )
	{
		new hourly_budget = floatround( float( hitman_budget ) / 60.0 );
		new ignored_players[ MAX_PLAYERS ] = { -1, ... };

		new available_count = 0;

		for ( new playerid = 0; playerid < sizeof( ignored_players ); playerid ++ )
		{
			// remove unconnected / npcs / aod / low score
			if ( ! IsPlayerConnected( playerid ) || IsPlayerNPC( playerid ) || IsPlayerAdminOnDuty( playerid ) || GetPlayerScore( playerid ) < 25 || IsPlayerAFK( playerid ) )
			{
				ignored_players[ playerid ] = playerid;
				continue;
			}

			// count available
			available_count ++;
		}

		new random_hit[ 5 ]; // change 5 to number of hits to place per 24 mins

		new hits_placed_amount = 0;
		new hits_to_iterate = available_count > sizeof( random_hit ) ? sizeof( random_hit ) : available_count;

		for ( new hitid = 0; hitid < hits_to_iterate; hitid ++ )
		{
			random_hit[ hitid ] = randomExcept( ignored_players, sizeof( ignored_players ) );

			// looks cleaner
			new playerid = random_hit[ hitid ];

			// ignore selected player
			ignored_players[ playerid ] = playerid; // ignore this too

			// contract shit
			if ( IsPlayerConnected( playerid ) )
			{
				new contract_amount = random( hourly_budget );

				// set a min/max hit otherwise bugs (billion dollar fix)
				if ( contract_amount < 1000 || contract_amount > hourly_budget ) {
					contract_amount = 1000;
				}

				hits_placed_amount += contract_amount;
				p_ContractedAmount[ playerid ] += contract_amount;
				ShowPlayerHelpDialog( playerid, 4000, "Somebody has placed a hit on you!~n~~n~~r~Your bounty is now %s!", cash_format( p_ContractedAmount[ playerid ] ) );
			}
		}

		// update budget
		UpdateServerVariable( "hitman_budget", hitman_budget - hits_placed_amount, 0.0, "", GLOBAL_VARTYPE_INT );

		// print anyway
		// printf("[AUTO HITMAN] Placed %s worth of hits (hourly rate %s, budget %s)!", cash_format( hits_to_iterate * hourly_budget ), cash_format( hourly_budget ), cash_format( GetGVarInt( "hitman_budget" ) ) );
	}
    return 1;
}

/* ** Functions ** */
stock RandomHits_IncreaseHitPool( amount ) {
	UpdateServerVariable( "hitman_budget", GetGVarInt( "hitman_budget" ) + amount, 0.0, "", GLOBAL_VARTYPE_INT );
    return 1;
}