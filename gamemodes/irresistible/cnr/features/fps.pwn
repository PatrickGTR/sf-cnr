/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\fps.pwn
 * Purpose: fps counter in-game
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	Text:  p_FPSCounterTD 			[ MAX_PLAYERS ] = { Text: INVALID_TEXT_DRAW, ... },
	bool: p_FPSCounter 				[ MAX_PLAYERS char ],
	p_FPS_DrunkLevel 				[ MAX_PLAYERS ],
	p_FPS 							[ MAX_PLAYERS ]
;

/* ** Commands ** */
CMD:fps( playerid, params[ ] )
{
	if( ( p_FPSCounter{ playerid } = !p_FPSCounter{ playerid } ) == true )
	{
		TextDrawSetString( p_FPSCounterTD[ playerid ], "_" );
		TextDrawShowForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	    SendClientMessage( playerid, 0x84aa63ff, "-> FPS counter enabled" );
	}
	else
	{
		TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	    SendClientMessage( playerid, 0x84aa63ff, "-> FPS counter disabled" );
	}
	return 1;
}

#if defined _streamer_included
CMD:drawdistance( playerid, params[ ] )
{
	if ( strmatch( params, "low" ) ) {
		Streamer_SetVisibleItems( STREAMER_TYPE_OBJECT, 300, playerid );
	    SendClientMessage( playerid, 0x84aa63ff, "-> Draw distance of objects now set to LOW." );
	} else if ( strmatch( params, "medium" ) ) {
		Streamer_SetVisibleItems( STREAMER_TYPE_OBJECT, 625, playerid );
	    SendClientMessage( playerid, 0x84aa63ff, "-> Draw distance of objects now set to MEDIUM." );
	} else if ( strmatch( params, "high" ) ) {
		Streamer_SetVisibleItems( STREAMER_TYPE_OBJECT, 950, playerid );
	    SendClientMessage( playerid, 0x84aa63ff, "-> Draw distance of objects now set to HIGH." );
	} else if ( strmatch( params, "info" ) ) {
	    SendClientMessage( playerid, 0x84aa63ff, sprintf( "-> You have currently %d objects streamed towards your client.", Streamer_GetVisibleItems( STREAMER_TYPE_OBJECT, playerid ) ) );
	}
	else {
		SendClientMessage( playerid, 0xa9c4e4ff, "-> /drawdistance [LOW/MEDIUM/HIGH/INFO]" );
	}
	return 1;
}
#endif

/* ** Hooks ** */
hook OnScriptInit( )
{
	for ( new playerid; playerid != MAX_PLAYERS; playerid ++ )
	{
		p_FPSCounterTD[ playerid ] = TextDrawCreate(636.000000, 2.000000, "_");
		TextDrawAlignment(p_FPSCounterTD[ playerid ], 3);
		TextDrawBackgroundColor(p_FPSCounterTD[ playerid ], 255);
		TextDrawFont(p_FPSCounterTD[ playerid ], 3);
		TextDrawLetterSize(p_FPSCounterTD[ playerid ], 0.300000, 1.500000);
		TextDrawColor(p_FPSCounterTD[ playerid ], -1);
		TextDrawSetOutline(p_FPSCounterTD[ playerid ], 1);
		TextDrawSetProportional(p_FPSCounterTD[ playerid ], 1);
	}
	return 1;
}

hook OnPlayerConnect( playerid )
{
	p_FPSCounter{ playerid } = false;
	p_FPS_DrunkLevel[ playerid ] = 0;
	p_FPS[ playerid ] = 0;
	return 1;
}

hook OnPlayerLoadTextdraws( playerid ) {
	if ( p_FPSCounter{ playerid } ) {
		TextDrawShowForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	}
	return 1;
}

hook OnPlayerUnloadTextdraws( playerid ) {
	TextDrawHideForPlayer( playerid, p_FPSCounterTD[ playerid ] );
	return 1;
}

hook OnPlayerUpdate( playerid )
{
    new
    	iDrunkLevel = GetPlayerDrunkLevel( playerid );

    // Calculate FPS
    if ( iDrunkLevel < 100 ) SetPlayerDrunkLevel( playerid, 2000 );
   	else
   	{
        if ( p_FPS_DrunkLevel[ playerid ] != iDrunkLevel ) {
            new iFPS = p_FPS_DrunkLevel[ playerid ] - iDrunkLevel;

            if ( ( iFPS > 0 ) && ( iFPS < 200 ) )
                p_FPS[ playerid ] = iFPS;

            p_FPS_DrunkLevel[ playerid ] = iDrunkLevel;
        }
    }

    // format textdraw
    if ( p_FPSCounter{ playerid } )
    {
		static
			szFPS[ 14 ];

		switch( p_FPS[ playerid ] )
		{
			case 32 .. 120: {
				format( szFPS, sizeof( szFPS ), "~g~~h~~h~%d", p_FPS[ playerid ] );
			}

			case 18 .. 31: {
				format( szFPS, sizeof( szFPS ), "~y~~h~%d", p_FPS[ playerid ] );
			}

			case 0 .. 17: {
				format( szFPS, sizeof( szFPS ), "~r~~h~~h~%d", p_FPS[ playerid ] );
			}

			default: {
				format( szFPS, sizeof( szFPS ), "~g~~h~~h~%d", p_FPS[ playerid ] );
			}
		}

		TextDrawSetString( p_FPSCounterTD[ playerid ], szFPS );
    }
	return 1;
}

/* ** Functions ** */
stock GetPlayerFPS( playerid ) {
	return p_FPS[ playerid ];
}
