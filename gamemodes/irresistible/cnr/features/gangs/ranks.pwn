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

            format( szLargeString, sizeof( szLargeString ), "%s\t%s\n", rank, amount == 0 ? ( "n/a" ) : ( number_format( amount ) ) );
        }

        return ShowPlayerDialog( playerid, DIALOG_GANG_RANK, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Gang Ranks", szLargeString, "Close", "" ), 1;
    }

    SendError( playerid, "This gang doesn't have any custom ranks." );
    return 1;
}