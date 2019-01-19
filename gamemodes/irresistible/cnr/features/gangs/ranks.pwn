/*
 * Irresistible Gaming (c) 2018
 * Developed by Stev
 * Module: cnr/features/gangs/rank.pwn
 * Purpose: custom ranks
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define DIALOG_GANG_RANK            ( 1205 )

/* ** Variables ** */

/* ** Hooks ** */

/* ** Functions ** */
thread OnGangCreateRank( playerid, requirement, gangid, rank[ ] )
{
    new 
        static_rank[ 32 ],
        rows = cache_get_row_count( );

    if ( rows )
    {
        cache_get_field_content( 0, "RANK_NAME", static_rank );

        if ( strmatch( static_rank, rank ) ) {
            return SendError( playerid, "There is already a rank called this, try another name." );
        }

        format( szLargeString, sizeof( szLargeString ), "INSERT INTO `GANG_RANKS` (`GANG_ID`,`RANK_NAME`,`REQUIRE`) VALUE (%d,'%s',%d)", g_gangData[ gangid ][ E_SQL_ID ], mysql_escape( rank ), requirement );
	    mysql_query( dbHandle, szLargeString );

	    SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has created a new rank \"%s\" with %d requirement", ReturnPlayerName( playerid ), playerid, rank, requirement );
    }

    return 1;
}

thread OnDisplayCustomGangRanks( playerid )
{
    new
		rows = cache_get_row_count( );

	if ( rows )
    {
        szLargeString = ""COL_WHITE"Rank\t"COL_WHITE"Respect Level\n";
        
        new 
            rank[ 32 ], amount;

        for ( new row = 0; row < rows; row ++ )
        {
            amount = cache_get_field_content_int( row, "REQUIREMENT" );
            cache_get_field_content( row, "RANK_NAME", rank );

            format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, rank, amount == 0 ? ( "n/a" ) : ( number_format( amount ) ) );
        }

        return ShowPlayerDialog( playerid, DIALOG_GANG_RANK, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Gang Ranks", szLargeString, "Close", "" ), 1;
    }

    SendError( playerid, "This gang doesn't have any custom ranks." );
    return 1;
}