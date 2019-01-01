/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\new_years_eve.pwn
 * Purpose: new years countdown in-game
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define NEW_YEAR_TIMESTAMP          ( 1546300800 )  // the exact timestamp for the new year, e.g 1/1/2020 00:00:00
#define NEW_YEAR                    ( 2019 )        // the new year

/* ** Variables ** */
static stock Text: g_NewYearCDTD    [ 3 ] = { Text: INVALID_TEXT_DRAW, ... };

/* ** Hooks ** */
hook OnScriptInit( )
{
    NewYears_InitializeTextdraws( );
    return 1;
}

hook OnServerUpdate( )
{
	new iCompare = NEW_YEAR_TIMESTAMP - GetServerTime( );

	static bool: bNewYear;

	if ( ! bNewYear ) {
		if ( iCompare <= 0 ) {
			TextDrawSetString( g_NewYearCDTD[ 0 ], "Happy New Year!" ), bNewYear = true;
        } else {
			TextDrawSetString( g_NewYearCDTD[ 0 ], sprintf( "~w~%s~n~~w~ till %d", secstonewyear( iCompare ), NEW_YEAR ) );
        }
	}
    return 1;
}

hook OnPlayerLoadTextdraws( playerid ) {
    for ( new i = 0; i < sizeof ( g_NewYearCDTD ); i ++ ) {
	    TextDrawShowForPlayer( playerid, g_NewYearCDTD[ i ] );
    }
    return 1;
}

hook OnPlayerUnloadTextdraws( playerid ) {
    for ( new i = 0; i < sizeof ( g_NewYearCDTD ); i ++ ) {
	    TextDrawHideForPlayer( playerid, g_NewYearCDTD[ i ] );
    }
    return 1;
}

/* ** Functions ** */
static stock secstonewyear(seconds, const delimiter[] = " ")
{
    static const times[] = {
        1,
        60,
        3600
    };

    static const names[][] = {
        "S",
        "M",
        "H"
    };

    new string[128];

    for(new i = sizeof(times) - 1;  i != -1; i--)
    {
        if(seconds / times[i])
        {
            if(string[0])
            {
                format(string, sizeof(string), "%s%s%d%s", string, delimiter, (seconds / times[i]), names[i]);
            }
            else
            {
                format(string, sizeof(string), "%d%s", (seconds / times[i]), names[i]);
            }
            seconds -= ((seconds / times[i]) * times[i]);
        }
    }
    return string;
}

static stock NewYears_InitializeTextdraws( )
{
    g_NewYearCDTD[ 0 ] = TextDrawCreate(586.000000, 321.000000, "__");
    TextDrawAlignment(g_NewYearCDTD[ 0 ], 2);
    TextDrawBackgroundColor(g_NewYearCDTD[ 0 ], 255);
    TextDrawFont(g_NewYearCDTD[ 0 ], 3);
    TextDrawLetterSize(g_NewYearCDTD[ 0 ], 0.230000, 1.100000);
    TextDrawColor(g_NewYearCDTD[ 0 ], COLOR_GOLD);
    TextDrawSetOutline(g_NewYearCDTD[ 0 ], 1);
    TextDrawSetProportional(g_NewYearCDTD[ 0 ], 1);

    g_NewYearCDTD[ 1 ] = TextDrawCreate(515.000000, 308.000000, "obj");
    TextDrawBackgroundColor(g_NewYearCDTD[ 1 ], 0);
    TextDrawFont(g_NewYearCDTD[ 1 ], 5);
    TextDrawLetterSize(g_NewYearCDTD[ 1 ], 0.500000, 1.000000);
    TextDrawColor(g_NewYearCDTD[ 1 ], -1);
    TextDrawSetOutline(g_NewYearCDTD[ 1 ], 0);
    TextDrawSetProportional(g_NewYearCDTD[ 1 ], 1);
    TextDrawSetShadow(g_NewYearCDTD[ 1 ], 1);
    TextDrawUseBox(g_NewYearCDTD[ 1 ], 1);
    TextDrawBoxColor(g_NewYearCDTD[ 1 ], 0);
    TextDrawTextSize(g_NewYearCDTD[ 1 ], 34.000000, 40.000000);
    TextDrawSetPreviewModel(g_NewYearCDTD[ 1 ], 19822);
    TextDrawSetPreviewRot(g_NewYearCDTD[ 1 ], 0.000000, 0.000000, 0.000000, 1.000000);

    g_NewYearCDTD[ 2 ] = TextDrawCreate(526.000000, 318.000000, "obj");
    TextDrawBackgroundColor(g_NewYearCDTD[ 2 ], 0);
    TextDrawFont(g_NewYearCDTD[ 2 ], 5);
    TextDrawLetterSize(g_NewYearCDTD[ 2 ], 0.500000, 1.000000);
    TextDrawColor(g_NewYearCDTD[ 2 ], -1);
    TextDrawSetOutline(g_NewYearCDTD[ 2 ], 0);
    TextDrawSetProportional(g_NewYearCDTD[ 2 ], 1);
    TextDrawSetShadow(g_NewYearCDTD[ 2 ], 1);
    TextDrawUseBox(g_NewYearCDTD[ 2 ], 1);
    TextDrawBoxColor(g_NewYearCDTD[ 2 ], 0);
    TextDrawTextSize(g_NewYearCDTD[ 2 ], 30.000000, 30.000000);
    TextDrawSetPreviewModel(g_NewYearCDTD[ 2 ], 19818);
    TextDrawSetPreviewRot(g_NewYearCDTD[ 2 ], 0.000000, 0.000000, 0.000000, 1.000000);
    return 1;
}