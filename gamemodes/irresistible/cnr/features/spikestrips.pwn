/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\spikestrips.pwn
 * Purpose: spike strip system for police
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_SPIKESTRIPS          	( 32 )

/* ** Variables ** */
enum E_SPIKE_STRIP_DATA
{
	E_OBJECT_ID,     				Text3D: E_LABEL,				E_SPHERE,
	E_CREATOR,

	Float: E_X, 					Float: E_Y, 					Float: E_Z
};

static stock
	g_spikestripData                [ MAX_SPIKESTRIPS ] [ E_SPIKE_STRIP_DATA ],
	Iterator: spikestrips 			< MAX_SPIKESTRIPS >
;

/* ** Hooks ** */
hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys ) {
	new
		player_vehicle = GetPlayerVehicleID( playerid );

	if ( PRESSED( KEY_CROUCH ) && player_vehicle && GetPlayerClass( playerid ) == CLASS_POLICE && p_inFBI{ playerid } )
	{
		new
			vehicle_model = GetVehicleModel( player_vehicle );

		if ( ! IsBoatVehicle( vehicle_model ) && ! IsAirVehicle( vehicle_model ) ) {
			return cmd_setspike( playerid, "" ), 1;
		}
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
	ClearPlayerSpikeStrips( playerid, .distance_check = false );
	return 1;
}

hook OnPlayerUpdateEx( playerid ) {
	if ( GetPlayerClass( playerid ) == CLASS_POLICE ) {
		ClearPlayerSpikeStrips( playerid );
	}
	return 1;
}

hook OnPlayerEnterDynArea( playerid, areaid ) {
	new vehicleid = GetPlayerVehicleID( playerid );
	new player_state = GetPlayerState( playerid );

    if ( player_state == PLAYER_STATE_DRIVER && vehicleid != 0 )
    {
		foreach ( new i : spikestrips ) if ( g_spikestripData[ i ] [ E_SPHERE ] == areaid ) {
            GetVehicleDamageStatus( vehicleid, panels, doors, lights, tires );
            UpdateVehicleDamageStatus( vehicleid, panels, doors, lights, ( tires = encode_tires( 1, 1, 1, 1 ) ) );
			destroySpikeStrip( i );
			break;
		}
    }
	return 1;
}

/* ** Commands ** */
CMD:dssall( playerid, params[ ] )
{
	new removed = 0;
	new is_admin = GetPlayerAdminLevel( playerid );

	if ( ! p_inFBI{ playerid } && ! is_admin )
		return SendError( playerid, "You are not in the FBI." );

	foreach ( new handle : spikestrips )
	{
		if ( ! is_admin && g_spikestripData[ handle ] [ E_CREATOR ] != playerid )
			continue;

		new
			cur = handle;

		destroySpikeStrip( handle, .remove_iter = false );
		Iter_SafeRemove( spikestrips, cur, handle );
		removed ++;
	}

	if ( removed ) {
		return SendServerMessage( playerid, "You have removed all your spike strips." );
	} else {
		return SendError( playerid, "There are no spike strips to remove by you." );
	}
}

CMD:dss( playerid, params[ ] )
{
	new
	    rbID
	;

	if ( !p_inFBI{ playerid } ) return SendError( playerid, "You are not in the FBI." );
	else if ( sscanf( params, "d", rbID ) ) return SendUsage( playerid, "/dss [SPIKE_STRIP_ID]" );
	else if ( rbID < 0 || rbID >= MAX_SPIKESTRIPS ) return SendError( playerid, "Invalid Spike Strip ID." );
	else if ( !Iter_Contains( spikestrips, rbID ) ) return SendError( playerid, "Invalid Spike Strip ID." );
	else if ( g_spikestripData[ rbID ] [ E_CREATOR ] != playerid ) return SendError( playerid, "You have not created this spike strip." );
	else
	{
	    destroySpikeStrip( rbID );
	    SendServerMessage( playerid, "You have succesfully destroyed a spike strip." );
	}
	return 1;
}

CMD:spike( playerid, params[ ] ) return cmd_setspike( playerid, params );
CMD:setspike( playerid, params[ ] )
{
	if ( GetPlayerInterior( playerid ) != 0 || GetPlayerVirtualWorld( playerid ) != 0 ) return SendError( playerid, "You cannot place spike strips inside buildings." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You are kidnapped, you cannot do this." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You are jailed, you cannot do this." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You are tied, you cannot do this." );
	else if ( IsPlayerInWater( playerid ) ) return SendError( playerid, "You cannot use this command since you're in water." );
	else if ( !p_inFBI{ playerid } ) return SendError( playerid, "You are not in the FBI." );
	else
	{
	  	new
			Float: X, Float: Y, Float: Z, Float: Angle;

		if ( !IsPlayerInAnyVehicle( playerid ) )
		{
			GetXYInFrontOfPlayer( playerid, X, Y, Z, 2.0 );
			GetPlayerFacingAngle( playerid, Angle );
		}
		else
		{
			new
				iVehicle = GetPlayerVehicleID( playerid ),
				iModel = GetVehicleModel( iVehicle )
			;

			if ( IsBoatVehicle( iModel ) || IsAirVehicle( iModel ) )
				return SendError( playerid, "You cannot place a spike strip in this type of vehicle." );

			GetVehiclePos( iVehicle, X, Y, Z );
			GetVehicleZAngle( iVehicle, Angle );

		 	X -= ( 4.1 * floatsin( -Angle, degrees ) );
			Y -= ( 4.1 * floatcos( -Angle, degrees ) );
		}

		if ( CreateSpikeStrip( playerid, X, Y, Z, Angle ) != -1 )
			SendServerMessage( playerid, "You have succesfully created a spike strip." );
		else
			SendError( playerid, "Failed to place a spike strip due to a unexpected error." );
	}
	return 1;
}

/* ** Functions ** */
stock CreateSpikeStrip( playerid, Float: X, Float: Y, Float: Z, Float: Angle )
{
	new
		bVehicle = IsPlayerInAnyVehicle( playerid ),
		i = Iter_Free( spikestrips )
	;

	if ( i != ITER_NONE )
	{
		DestroyDynamicArea			( g_spikestripData[ i ] [ E_SPHERE ] );
		DestroyDynamicObject		( g_spikestripData[ i ] [ E_OBJECT_ID ] );
		DestroyDynamic3DTextLabel	( g_spikestripData[ i ] [ E_LABEL ] );

		g_spikestripData[ i ] [ E_CREATOR ] = playerid;
		g_spikestripData[ i ] [ E_X ] = X;
		g_spikestripData[ i ] [ E_Y ] = Y;
		g_spikestripData[ i ] [ E_Z ] = Z;

		g_spikestripData[ i ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "Spike Strip(%d)\n"COL_GREY"Placed by %s!", i, ReturnPlayerName( playerid ) ), COLOR_GOLD, X, Y, Z, 20.0 );
	    g_spikestripData[ i ] [ E_OBJECT_ID ] = CreateDynamicObject( 2899, X, Y, Z - ( bVehicle ? 0.6 : 0.9 ), 0, 0, Angle - 90.0);
		g_spikestripData[ i ] [ E_SPHERE ] = CreateDynamicCircle( X, Y, 4.0 );

	   	Streamer_Update( playerid );
	    Iter_Add( spikestrips, i );
	}
  	return i;
}

stock destroySpikeStrip( i, bool: remove_iter = true )
{
	if ( i == -1 )
	    return 0;

	DestroyDynamicArea			( g_spikestripData[ i ] [ E_SPHERE ] );
	DestroyDynamicObject		( g_spikestripData[ i ] [ E_OBJECT_ID ] );
	DestroyDynamic3DTextLabel	( g_spikestripData[ i ] [ E_LABEL ] );

	g_spikestripData[ i ] [ E_SPHERE ]		= 0xFFFF;
	g_spikestripData[ i ] [ E_OBJECT_ID ]	= INVALID_OBJECT_ID;
	g_spikestripData[ i ] [ E_LABEL ]		= Text3D: 0xFFFF;

	if ( remove_iter ) Iter_Remove( spikestrips, i );
	return 1;
}

stock ClearPlayerSpikeStrips( playerid, bool: distance_check = true )
{
	foreach ( new handle : spikestrips ) if ( g_spikestripData[ handle ] [ E_CREATOR ] == playerid )
	{
		if ( distance_check && GetPlayerDistanceFromPoint( playerid, g_spikestripData[ handle ] [ E_X ], g_spikestripData[ handle ] [ E_Y ], g_spikestripData[ handle ] [ E_Z ] ) < 75.0 ) {
			continue;
		}

		new
			cur = handle;

		destroySpikeStrip( handle, .remove_iter = false );
		Iter_SafeRemove( spikestrips, cur, handle );
	}
	return 1;
}

stock encode_tires( tires1, tires2, tires3, tires4 )
	return tires1 | (tires2 << 1) | (tires3 << 2) | (tires4 << 3);
