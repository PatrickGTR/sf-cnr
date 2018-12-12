/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\crime_reports.pwn
 * Purpose: whenever a criminal starts a crime, a report is created
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_INFORMED_ROBBERIES		( 25 )

/* ** Variables ** */
enum E_INFORMED_ROBBERY_DATA
{
	E_MAP_ICON,						E_ALPHA
};

static stock
	g_informedRobberies 			[ MAX_INFORMED_ROBBERIES ] [ E_INFORMED_ROBBERY_DATA ],
	Iterator: InformedRobbery 		< MAX_INFORMED_ROBBERIES >
;

/* ** Hooks ** */
hook OnServerUpdate( )
{
	// Update Criminal Report Markers
	foreach ( new ir : InformedRobbery )
	{
		if ( ( g_informedRobberies[ ir ] [ E_ALPHA ] -= 7 ) <= 0 )
		{
			new
				cur = ir;

			DestroyDynamicMapIcon( g_informedRobberies[ ir ] [ E_MAP_ICON ] );
			Iter_SafeRemove(InformedRobbery, cur, ir);
		}
		else Streamer_SetIntData( STREAMER_TYPE_MAP_ICON, g_informedRobberies[ ir ] [ E_MAP_ICON ], E_STREAMER_COLOR, setAlpha( COLOR_WANTED12, g_informedRobberies[ ir ] [ E_ALPHA ] ) );
	}
	return 1;
}

/* ** Functions ** */
stock CreateCrimeReport( playerid )
{
	if ( ! ( 0 <= playerid < MAX_PLAYERS ) )
		return;

	if ( IsPlayerJob( playerid, JOB_BURGLAR ) )
		return;

	new
		iCrimeReport = Iter_Free( InformedRobbery );

	if ( iCrimeReport != ITER_NONE )
	{
		new
			Float: X, Float: Y, Float: Z;

		// Add iterator
	  	Iter_Add( InformedRobbery, iCrimeReport );

	  	// Find user location
	  	GetPlayerOutsidePos( playerid, X, Y, Z );

	  	// Create marker
	  	g_informedRobberies[ iCrimeReport ] [ E_ALPHA ] = 0xAA;
	  	g_informedRobberies[ iCrimeReport ] [ E_MAP_ICON ] = CreateDynamicMapIcon( X, Y, Z, 0, COLOR_WANTED12, -1, -1, 0, 1000.0, MAPICON_GLOBAL );

	  	// Reset Players In Map Icon
	  	Streamer_RemoveArrayData( STREAMER_TYPE_MAP_ICON, g_informedRobberies[ iCrimeReport ] [ E_MAP_ICON ], E_STREAMER_PLAYER_ID, 0 );

	  	// Show For All Cops
	  	foreach (new i : Player) if ( p_Class[ i ] == CLASS_POLICE ) {
	  		Streamer_AppendArrayData( STREAMER_TYPE_MAP_ICON, g_informedRobberies[ iCrimeReport ] [ E_MAP_ICON ], E_STREAMER_PLAYER_ID, i );
	  	}
	}
}
