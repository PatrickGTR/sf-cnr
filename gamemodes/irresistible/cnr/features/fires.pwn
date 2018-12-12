/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\fires.pwn
 * Purpose: extinguishable fire system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_FIRES					( 10 )

#define FIRE_EXTINGUISH_PAYOUT 		( 4000 )

/* ** Variables ** */
enum E_FIRE_DATA
{
	E_OBJECT,					Float: E_HEALTH,				E_HOUSE,
	Text3D: E_LABEL,			E_MAP_ICON
};

static stock
	g_fireData                      [ MAX_FIRES ] [ E_FIRE_DATA ],
	Iterator: fires 				< MAX_FIRES >,

	p_FireTracker					[ MAX_PLAYERS char ]
;

/* ** Forwards ** */
forward OnPlayerTakeOutFire			( playerid, fireid );

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	StopPlayerFireTracker( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	StopPlayerFireTracker( playerid );
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	new
		iKeys;

	GetPlayerKeys( playerid, iKeys, tmpVariable, tmpVariable );

	// Taking Out Fires
    if ( ( iKeys & KEY_FIRE ) || ( iKeys & KEY_WALK ) )
	{
		new
			using_firetruck = GetVehicleModel( GetPlayerVehicleID( playerid ) ) == 407;

		if ( GetPlayerWeapon( playerid ) == 42 || using_firetruck )
		{
			foreach ( new i : fires )
		    {
		    	static
					Float: fX, Float: fY, Float: fZ;

		 		if ( GetDynamicObjectPos( g_fireData[ i ] [ E_OBJECT ], fX, fY, fZ ) )
		 		{
		 			// add a bit of height cause of the fire
					fZ += 2.3;

					// check if range of point
					if ( IsPlayerInRangeOfPoint( playerid, ( using_firetruck ? 30.0 : 10.0 ), fX, fY, fZ ) )
					{
						if ( IsPlayerAimingAt( playerid, fX, fY, fZ, ( using_firetruck ? 3.5 : 1.0 ) ) )
						{

							new
								Float: removed_health = ( 2.5 + fRandomEx( 1.0, 5.0 ) ) * ( using_firetruck ? 2.5 : 1.0 );

							if ( ( g_fireData[ i ] [ E_HEALTH ] -= removed_health ) < 0.0 ) {
								g_fireData[ i ] [ E_HEALTH ] = 0.0;
							}

				       		UpdateDynamic3DTextLabelText( g_fireData[ i ] [ E_LABEL ], 0xA83434FF, sprintf( "House Fire %0.1f%", g_fireData[ i ] [ E_HEALTH ] ) );

						    if ( g_fireData[ i ] [ E_HEALTH ] <= 0.0 )
						    {
								new
									money_earned = RandomEx( FIRE_EXTINGUISH_PAYOUT / 2, FIRE_EXTINGUISH_PAYOUT );

								ach_HandleExtinguishedFires( playerid );
							    SendClientMessageToAllFormatted( -1, "{A83434}[FIREMAN]"COL_WHITE" %s(%d) has earned "COL_GOLD"%s"COL_WHITE" for extinguishing a house fire.", ReturnPlayerName( playerid ), playerid, cash_format( money_earned ) );
								GivePlayerScore( playerid, 2 );
								//GivePlayerExperience( playerid, E_FIREMAN );
								GivePlayerCash( playerid, money_earned );
								StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, money_earned, 0.15 );
								HouseFire_Remove( i );
						    }
							return 1;
						}
					}
				}
			}
		}
	}
	return 1;
}

hook OnServerUpdate( )
{
	// create fires if there are no fires existing and houses available
	if ( ! Iter_Count( fires ) && Iter_Count( houses ) ) {
		HouseFire_Create( );
	}
	return 1;
}

hook OnServerGameDayEnd( )
{
	HouseFire_Create( );
	return 1;
}

hook OnPlayerDriveVehicle( playerid, vehicleid )
{
	new
		modelid = GetVehicleModel( vehicleid );

	if ( modelid == 407 ) {
		ShowPlayerHelpDialog( playerid, 2500, "You can see where fires are using ~g~/fires" );
	}
	return 1;
}

/* ** Commands ** */
CMD:firetracker( playerid, params[ ] ) cmd_fires( playerid, params );
CMD:fires( playerid, params[ ] )
{
	p_FireTracker{ playerid } = ! p_FireTracker{ playerid };

	if ( p_FireTracker{ playerid } )
	{
		UpdatePlayerFireTracker( playerid );
		return SendServerMessage( playerid, "All house fires are now in your minimap as red markers." );
	}
	else
	{
		StopPlayerFireTracker( playerid );
		return SendServerMessage( playerid, "You have hidden all the fires from your radar." );
	}
}

/* ** Functions ** */
stock HouseFire_Create( )
{
	// create house house fires for random homes
	for ( new fireid = 0; fireid < MAX_FIRES; fireid ++ ) if ( ! Iter_Contains( fires, fireid ) )
	{
		new
			houseid = HouseFire_GetRandomHome( );

		if ( Iter_Contains( houses, houseid ) )
		{
			static
				Float: X, Float: Y, Float: Z;

			GetHousePos( houseid, X, Y, Z );

			g_fireData[ fireid ] [ E_HEALTH ] = 100.0 + fRandomEx( 1, 25 );
			g_fireData[ fireid ] [ E_HOUSE ] = houseid;
			g_fireData[ fireid ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "House Fire %0.1f%", g_fireData[ fireid ] [ E_HEALTH ] ), 0xA83434FF, X, Y, Z + 0.5, 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1 );
			g_fireData[ fireid ] [ E_OBJECT ] = CreateDynamicObject( 18691, X, Y, Z - 2.3, 0.0, 0.0, 0.0 );

			// fire map icons
			g_fireData[ fireid ] [ E_MAP_ICON ] = CreateDynamicMapIcon( X, Y, Z, 0, 0xA83434FF, -1, -1, 0, 6000.0, MAPICON_GLOBAL );
			Streamer_RemoveArrayData( STREAMER_TYPE_MAP_ICON, g_fireData[ fireid ] [ E_MAP_ICON ], E_STREAMER_PLAYER_ID, 0 );

			Iter_Add( fires, fireid );
		}
	}

	// show on radar when it is created
	foreach ( new playerid : Player ) if ( p_FireTracker{ playerid } ) {
		UpdatePlayerFireTracker( playerid );
	}
	return 1;
}

stock HouseFire_Remove( fireid )
{
	DestroyDynamicObject( g_fireData[ fireid ] [ E_OBJECT ] );
	g_fireData[ fireid ] [ E_OBJECT ] = INVALID_OBJECT_ID;
	DestroyDynamic3DTextLabel( g_fireData[ fireid ] [ E_LABEL ] );
	g_fireData[ fireid ] [ E_LABEL ] = Text3D: INVALID_3DTEXT_ID;
	DestroyDynamicMapIcon( g_fireData[ fireid ] [ E_MAP_ICON ] );
	g_fireData[ fireid ] [ E_MAP_ICON ] = -1;
	Iter_Remove( fires, fireid );
	return 1;
}

stock HouseFire_GetRandomHome( )
{
	if ( ! Iter_Count( houses ) ) {
		return -1;
	}

	static szCity[ MAX_ZONE_NAME ];
	new ignoredHomes[ MAX_HOUSES ] = { -1, ... };

	// first find homes to ignore
	for ( new i = 0; i < MAX_HOUSES; i ++ )
	{
		// Avoid Hills / Avoid V.I.P or Clan Homes
		if ( ! Iter_Contains( houses, i ) || g_houseData[ i ] [ E_EZ ] > 300.0 || g_houseData[ i ] [ E_COST ] < 500000 ) {
			ignoredHomes[ i ] = i;
			continue;
		}

		// check for house fire
		if ( IsHouseOnFire( i ) ) {
			ignoredHomes[ i ] = i;
			continue;
		}

		// San Fierro only
		Get2DCity( szCity, g_houseData[ i ] [ E_EX ], g_houseData[ i ] [ E_EY ], g_houseData[ i ] [ E_EZ ] );
		if ( ! strmatch( szCity, "San Fierro" ) )  {
			ignoredHomes[ i ] = i;
			continue;
		}
	}

	new
		random_home = randomExcept( ignoredHomes, sizeof( ignoredHomes ) );

	// apparently 'safer' to return value from variable
	return random_home;
}

stock IsHouseOnFire( houseid )
{
	if ( houseid < 0 || houseid > MAX_HOUSES )
	    return 0;

	if ( ! Iter_Contains( houses, houseid ) )
	    return 0;

	static
		Float: X, Float: Y, Float: Z, Float: HX, Float: HY;

	foreach ( new fireid : fires )
	{
		GetDynamicObjectPos( g_fireData[ fireid ] [ E_OBJECT ], X, Y, Z ); // Z is unused due to the object.
		GetHousePos( houseid, HX, HY, Z );

		if ( HX == X && HY == Y )
		{
			return 1;
		}
	}
	return 0;
}

stock UpdatePlayerFireTracker( playerid )
{
	// add player to map icon list
	foreach ( new fireid : fires ) {
		Streamer_AppendArrayData( STREAMER_TYPE_MAP_ICON, g_fireData[ fireid ] [ E_MAP_ICON ], E_STREAMER_PLAYER_ID, playerid );
	}
	return 1;
}

stock StopPlayerFireTracker( playerid )
{
	// remove player from map icon list
	foreach ( new fireid : fires ) if ( Streamer_IsInArrayData( STREAMER_TYPE_MAP_ICON, g_fireData[ fireid ] [ E_MAP_ICON ], E_STREAMER_PLAYER_ID, playerid ) ) {
		Streamer_RemoveArrayData( STREAMER_TYPE_MAP_ICON, g_fireData[ fireid ] [ E_MAP_ICON ], E_STREAMER_PLAYER_ID, playerid );
	}

	// reset firetracker
	p_FireTracker{ playerid } = false;
	return 1;
}

stock Float: GetPointAngleToPoint( Float: x2, Float: y2, Float: X, Float: Y )
{
	new Float: DX, Float: DY;
	new Float: angle;

	DX = floatabs( floatsub( x2, X ) );
	DY = floatabs( floatsub( y2, Y ) );

	if ( DY == 0.0 || DX == 0.0 )
	{
		if ( DY == 0 && DX > 0 ) angle = 0.0;
		else if ( DY == 0 && DX < 0 ) angle = 180.0;
		else if ( DY > 0 && DX == 0 ) angle = 90.0;
		else if ( DY < 0 && DX == 0 ) angle = 270.0;
		else if ( DY == 0 && DX == 0 ) angle = 0.0;
	}
	else
	{
		angle = atan( DX / DY );
		if ( X > x2 && Y <= y2 ) angle += 90.0;
		else if ( X <= x2 && Y < y2 ) angle = floatsub( 90.0, angle );
		else if ( X < x2 && Y >= y2 ) angle -= 90.0;
		else if ( X >= x2 && Y > y2 ) angle = floatsub( 270.0, angle );
	}
	return floatadd( angle, 90.0 );
}

stock Float: DistanceCameraTargetToLocation(Float:CamX, Float:CamY, Float:CamZ, Float:ObjX, Float:ObjY, Float:ObjZ, Float:FrX, Float:FrY, Float:FrZ) {

    new Float: TGTDistance;

    TGTDistance = floatsqroot( ( CamX - ObjX) * ( CamX - ObjX ) + ( CamY - ObjY ) * ( CamY - ObjY ) + ( CamZ - ObjZ ) * ( CamZ - ObjZ ) );

    new Float: tmpX, Float: tmpY, Float: tmpZ;

    tmpX = FrX * TGTDistance + CamX;
    tmpY = FrY * TGTDistance + CamY;
    tmpZ = FrZ * TGTDistance + CamZ;

    return floatsqroot( ( tmpX - ObjX ) * ( tmpX - ObjX ) + ( tmpY - ObjY ) * ( tmpY - ObjY ) + ( tmpZ - ObjZ ) * ( tmpZ - ObjZ ) );
}

stock IsPlayerAimingAt( playerid, Float: x, Float: y, Float: z, Float: radius ) // forgot who made this
{
    new Float: camera_x, Float: camera_y, Float: camera_z;
    new Float: vector_x, Float: vector_y, Float: vector_z;

    GetPlayerCameraPos( playerid, camera_x, camera_y, camera_z );
    GetPlayerCameraFrontVector( playerid, vector_x, vector_y, vector_z );

    new Float: vertical, Float: horizontal;

    switch ( GetPlayerWeapon( playerid ) )
    {
        case 34, 35, 36: return DistanceCameraTargetToLocation( camera_x, camera_y, camera_z, x, y, z, vector_x, vector_y, vector_z ) < radius;
        case 30, 31: vertical = 4.0, horizontal = -1.6;
        case 33: vertical = 2.7, horizontal = -1.0;
        default: vertical = 6.0, horizontal = -2.2;
    }

    new Float: angle = GetPointAngleToPoint( 0, 0, floatsqroot( vector_x * vector_x + vector_y * vector_y ), vector_z ) - 270.0;
    new Float: resize_x, Float: resize_y, Float: resize_z = floatsin( angle + vertical, degrees );

    GetXYInFrontOfPoint( resize_x, resize_y, GetPointAngleToPoint( 0, 0, vector_x, vector_y ) + horizontal, floatcos( angle + vertical, degrees ) );
    return DistanceCameraTargetToLocation(camera_x, camera_y, camera_z, x, y, z, resize_x, resize_y, resize_z) < radius;
}

stock GetXYInFrontOfPoint( &Float: x, &Float: y, Float: angle, Float: distance ) {
    x += ( distance * floatsin( -angle, degrees ) );
    y += ( distance * floatcos( -angle, degrees ) );
}
