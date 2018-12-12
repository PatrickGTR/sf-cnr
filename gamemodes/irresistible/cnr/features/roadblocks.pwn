/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\roadblocks.pwn
 * Purpose: roadblocks system for police
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_ROADBLOCKS              ( 32 )

/* ** Variables ** */
enum E_ROADBLOCK_DATA
{
	E_OBJECT_ID,               		Text3D: E_LABEL,				E_CREATOR,

	Float: E_X, 					Float: E_Y, 					Float: E_Z
};

enum E_ROADBLOCK_OBJ_DATA
{
	E_NAME[ 17 ],		E_MODEL,					Float: E_OFFSET
};

static stock
	g_roadblockData                 [ MAX_ROADBLOCKS ] [ E_ROADBLOCK_DATA ],
	Iterator: roadblocks 			< MAX_ROADBLOCKS >,

	g_roadblockObjectData 			[ ] [ E_ROADBLOCK_OBJ_DATA ] =
	{
		{ "Small Roadblock",	1459,	0.2 },
		{ "Medium Roadblock",	978,	0.5 },
		{ "Big Roadblock",		981,	0.2 },
		{ "Detour Sign",		1425,	0.6 },
		{ "Will Be Sign",		3265,	0.9 },
		{ "Line Closed Sign",	3091,	0.5 }
	}
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	ClearPlayerRoadblocks( playerid, .distance_check = false );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	ClearPlayerRoadblocks( playerid, .distance_check = false );
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( IsPlayerSpawned( playerid ) && GetPlayerClass( playerid ) == CLASS_POLICE ) {
		ClearPlayerRoadblocks( playerid );
	}
	return 1;
}

/* ** Commands ** */
CMD:drball( playerid, params[ ] )
{
	if ( ! p_inFBI{ playerid } && ! p_AdminLevel[ playerid ] )
		return SendError( playerid, "You are not in the FBI." );

	new
		removed = 0;

	foreach ( new handle : roadblocks )
	{
		if ( ! p_AdminLevel[ playerid ] && g_roadblockData[ handle ] [ E_CREATOR ] != playerid )
			continue;

		new
			cur = handle;

		destroyRoadBlockStrip( handle, .remove_iter = false );
		Iter_SafeRemove( roadblocks, cur, handle );
		removed ++;
	}

	if ( removed ) {
		return SendServerMessage( playerid, "You have removed all your roadblocks." );
	} else {
		return SendError( playerid, "There are no roadblocks to remove by you." );
	}
}

CMD:drb( playerid, params[ ] )
{
	new
	    rbID
	;

	if ( !p_inFBI{ playerid } ) return SendError( playerid, "You are not in the FBI." );
	else if ( GetPlayerScore( playerid ) < 250 ) return SendError( playerid, "You need at least 250 score to use this feature." );
	else if ( sscanf( params, "d", rbID ) ) return SendUsage( playerid, "/drb [ROADBLOCK_ID]" );
	else if ( rbID < 0 || rbID > MAX_ROADBLOCKS ) return SendError( playerid, "Invalid road block ID." );
	else if ( Iter_Contains( roadblocks, rbID ) ) return SendError( playerid, "Invalid road block ID." );
	else if ( g_roadblockData[ rbID ] [ E_CREATOR ] != playerid ) return SendError( playerid, "You have not created this spike strip." );
	else
	{
	    destroyRoadBlockStrip( rbID, .remove_iter = true );
	    SendServerMessage( playerid, "You have succesfully destroyed a road block." );
	}
	return 1;
}

CMD:crb( playerid, params[ ] )
{
	new
		iRoadBlock;

	if ( GetPlayerInterior( playerid ) != 0 || GetPlayerVirtualWorld( playerid ) != 0 ) return SendError( playerid, "You cannot use this command inside buildings." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You are kidnapped, you cannot do this." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You are tied, you cannot do this." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You are jailed, you cannot do this." );
	else if ( !p_inFBI{ playerid } ) return SendError( playerid, "You are not in the FBI." );
	else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command while in a vehicle." );
	else if ( IsPlayerInWater( playerid ) ) return SendError( playerid, "You cannot use this command since you're in water." );
	else if ( isnull( params ) ) return SendUsage( playerid, "/crb [SMALL/MEDIUM/BIG/CONE/DETOUR/WILL BE SIGN/LINE CLOSED]" );
	else
	{
		for( iRoadBlock = 0; iRoadBlock < sizeof( g_roadblockObjectData ); iRoadBlock++ )
			if ( strfind( g_roadblockObjectData[ iRoadBlock ] [ E_NAME ], params, true ) != -1 )
				break;

		if ( iRoadBlock >= sizeof( g_roadblockObjectData ) )
			return SendError( playerid, "You have typed in an invalid roadblock." );

		new
			iTmp = createRoadBlockStrip( playerid, iRoadBlock );

		if ( iTmp != -1 )
			SendServerMessage( playerid, "You have succesfully placed a "COL_GREY"%s"COL_WHITE".", g_roadblockObjectData[ iRoadBlock ] [ E_NAME ] );
		else
			SendError( playerid, "Failed to place a road block due to a unexpected error." );
	}
	return 1;
}

/* ** Functions ** */
stock destroyRoadBlockStrip( rbid, bool: remove_iter = false )
{
	if ( ! Iter_Contains( roadblocks, rbid ) )
	    return 0;

	DestroyDynamicObject( g_roadblockData[ rbid ] [ E_OBJECT_ID ] );
	DestroyDynamic3DTextLabel( g_roadblockData[ rbid ] [ E_LABEL ] );

	g_roadblockData[ rbid ] [ E_LABEL ] = Text3D: INVALID_3DTEXT_ID;
	g_roadblockData[ rbid ] [ E_OBJECT_ID ] = INVALID_OBJECT_ID;

	if ( remove_iter ) Iter_Remove( roadblocks, rbid );
	return 1;
}

stock createRoadBlockStrip( playerid, type )
{
	new
 		ID = Iter_Free( roadblocks ),
		Float: X, Float: Y, Float: Z, Float: Degree
	;

	if ( ID != ITER_NONE )
	{
	    GetXYInFrontOfPlayer( playerid, X, Y, Z, 2.0 );
		GetPlayerFacingAngle( playerid, Degree );

		g_roadblockData[ ID ] [ E_CREATOR ] = playerid;
		g_roadblockData[ ID ] [ E_X ] = X;
		g_roadblockData[ ID ] [ E_Y ] = Y;
		g_roadblockData[ ID ] [ E_Z ] = Z;

		DestroyDynamicObject( g_roadblockData[ ID ] [ E_OBJECT_ID ] );
		DestroyDynamic3DTextLabel( g_roadblockData[ ID ] [ E_LABEL ] );

		g_roadblockData[ ID ] [ E_OBJECT_ID ] = CreateDynamicObject( g_roadblockObjectData[ type ] [ E_MODEL ], X, Y, Z - g_roadblockObjectData[ type ] [ E_OFFSET ], 0, 0, Degree + 180.0 );
		g_roadblockData[ ID ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "%s(%d)\n"COL_GREY"Placed by %s!", g_roadblockObjectData[ type ] [ E_NAME ], ID, ReturnPlayerName( playerid ) ), COLOR_GOLD, X, Y, Z, 20.0 );

		Streamer_Update( playerid );
		Iter_Add( roadblocks, ID );
	}
	return ID;
}

stock ClearPlayerRoadblocks( playerid, bool: distance_check = true )
{
	// remove roadblocks
	foreach ( new handle : roadblocks ) if ( g_roadblockData[ handle ] [ E_CREATOR ] == playerid )
	{
		if ( distance_check && GetPlayerDistanceFromPoint( playerid, g_roadblockData[ handle ] [ E_X ], g_roadblockData[ handle ] [ E_Y ], g_roadblockData[ handle ] [ E_Z ] ) < 100.0 ) {
			continue;
		}

		new
			cur = handle;

		destroyRoadBlockStrip( handle, .remove_iter = false );
		Iter_SafeRemove( roadblocks, cur, handle );
	}
	return 1;
}
