/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\bribes.pwn
 * Purpose: pickupable bribes that reduce a player's wanted level
 */

/* ** Error checking ** */
#if !defined __cnr__features__bribes
	#define __cnr__features__bribes
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_BRIBES                  ( 200 )
#define MAX_BRIBE_WAIT              ( 300 )

/* ** Variables ** */
enum E_BRIBE_DATA
{
	bool: E_DISABLED, 	E_PICKUP[ 2 ],			Text3D: E_LABEL,
	Float: E_X, 		Float: E_Y, 			Float: E_Z,
	E_TIMESTAMP
};

static stock
	g_bribeData						[ MAX_BRIBES ] [ E_BRIBE_DATA ],
	Iterator: BribeCount 			< MAX_BRIBES >
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	mysql_function_query( dbHandle, "SELECT * FROM `BRIBES`", true, "OnBribeLoad", "" );
	return 1;
}

hook OnServerUpdate( )
{
	foreach ( new bribeid : BribeCount ) if ( GetServerTime( ) > g_bribeData[ bribeid ] [ E_TIMESTAMP ] && g_bribeData[ bribeid ] [ E_DISABLED ] ) // Replenish Bribes
	{
		UpdateDynamic3DTextLabelText( g_bribeData[ bribeid ] [ E_LABEL ], COLOR_GOLD, sprintf( "Bribe(%d)", bribeid ) );
		g_bribeData[ bribeid ] [ E_DISABLED ] = false;
	}
	return 1;
}

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
	if ( GetPlayerClass( playerid ) != CLASS_POLICE )
	{
		foreach ( new bribeid : BribeCount ) if ( g_bribeData[ bribeid ] [ E_PICKUP ] [ 0 ] == pickupid || g_bribeData[ bribeid ] [ E_PICKUP ] [ 1 ] == pickupid )
		{
		    if ( !( g_bribeData[ bribeid ] [ E_DISABLED ] == true || p_WantedLevel[ playerid ] <= 0 || IsPlayerCuffed( playerid ) || GetPlayerState( playerid ) == PLAYER_STATE_SPECTATING ) ) //  || IsPlayerDetained( playerid )
		    {
		    	new
		    		iWanted = 2;

		    	// Play a sound so it matches the vehicle pickup
		    	if ( g_bribeData[ bribeid ] [ E_PICKUP ] [ 0 ] == pickupid )
		    		PlayerPlaySound( playerid, 1138, 0.0, 0.0, 5.0 );

		    	// Expire the bribe
		        g_bribeData[ bribeid ] [ E_TIMESTAMP ] = GetServerTime( ) + MAX_BRIBE_WAIT;
		        g_bribeData[ bribeid ] [ E_DISABLED ] = true;
				UpdateDynamic3DTextLabelText( g_bribeData[ bribeid ] [ E_LABEL ], COLOR_GOLD, sprintf( "Bribe(%d)\n"COL_RED"Currently Expired!", bribeid ) );

				// Remove a custom wanted level
				if ( p_WantedLevel[ playerid ] > 1800 ) iWanted = 128;
				else if ( p_WantedLevel[ playerid ] > 1000 ) iWanted = 64;
				else if ( p_WantedLevel[ playerid ] > 500 )	iWanted = 32;
				else if ( p_WantedLevel[ playerid ] > 250 )	iWanted = 16;
				else if ( p_WantedLevel[ playerid ] > 100 ) iWanted = 8;
				else if ( p_WantedLevel[ playerid ] > 50 ) iWanted = 4;

				return GivePlayerWantedLevel( playerid, p_WantedLevel[ playerid ] <= 1 ? -1 : -iWanted );
		    }
		}
		return 1;
	}
	return 1;
}

/* ** SQL Threads ** */
thread OnBribeLoad( )
{
	new
		rows, fields, i = -1,
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			CreateBribe(
				cache_get_field_content_float( i, "X", dbHandle ),
				cache_get_field_content_float( i, "Y", dbHandle ),
				cache_get_field_content_float( i, "Z", dbHandle ),
				cache_get_field_content_int( i, "ID", dbHandle )
			);
		}
	}
	printf( "[BRIBES]: %d bribes have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

/* ** Functions ** */
stock CreateBribe( Float: fX, Float: fY, Float: fZ, iExistingID = ITER_NONE )
{
	new
		bID = iExistingID != ITER_NONE ? iExistingID : Iter_Free(BribeCount);

	if ( Iter_Contains( BribeCount, iExistingID ) )
		bID = ITER_NONE; // In the unlikelihood...

	if ( bID != -1 )
	{
	    Iter_Add( BribeCount, bID );
	    g_bribeData[ bID ] [ E_X ] = fX;
	    g_bribeData[ bID ] [ E_Y ] = fY;
	    g_bribeData[ bID ] [ E_Z ] = fZ;
	    g_bribeData[ bID ] [ E_PICKUP ] [ 0 ] = CreateDynamicPickup( 1247,  15, fX, fY, fZ );
	    g_bribeData[ bID ] [ E_PICKUP ] [ 1 ] = CreateDynamicPickup( 19300, 14, fX, fY, fZ );
	    g_bribeData[ bID ] [ E_LABEL ] 		  = CreateDynamic3DTextLabel( sprintf( "Bribe(%d)", bID ), COLOR_GOLD, fX, fY, fZ, 15.0 );

	    if ( iExistingID == ITER_NONE ) {
			mysql_single_query( sprintf( "INSERT INTO `BRIBES` VALUES (%d,%f,%f,%f)", bID, fX, fY, fZ ) );
	    }
	}
	return bID;
}

stock DestroyBribe( bID )
{
	if ( bID == -1 || ! Iter_Contains( BribeCount, bID ) ) {
	    return 0;
	}

	Iter_Remove( BribeCount, bID );
	DestroyDynamic3DTextLabel( g_bribeData[ bID ] [ E_LABEL ] );
	DestroyDynamicPickup( g_bribeData[ bID ] [ E_PICKUP ] [ 0 ] );
	DestroyDynamicPickup( g_bribeData[ bID ] [ E_PICKUP ] [ 1 ] );
	mysql_single_query( sprintf( "DELETE FROM `BRIBES` WHERE `ID`=%d", bID ) );
	return 1;
}

stock Bribe_IsValid( bribeid ) {
	return ( 0 <= bribeid < MAX_BRIBES ) && Iter_Contains( BribeCount, bribeid );
}
