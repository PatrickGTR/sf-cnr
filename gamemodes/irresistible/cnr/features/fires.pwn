/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\fires.pwn
 * Purpose: extinguishable fire system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_FIRES					( 10 )

/* ** Variables ** */
enum E_FIRE_DATA
{
	bool: E_CREATED,	E_OBJECT,		Float: E_HEALTH,
	E_HOUSE,            Text3D: E_LABEL
};

static stock
	g_fireData                      [ MAX_FIRES ] [ E_FIRE_DATA ],
	p_FireDistanceTimer             [ MAX_PLAYERS ] = { -1, ... },
	bool: fire_toggled              = false
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
    if ( p_Class[ playerid ] == CLASS_FIREMAN && ( iKeys & KEY_FIRE ) || ( iKeys & KEY_WALK ) )
	{
		new
			iVehicle = GetPlayerVehicleID( playerid );

		if ( GetPlayerWeapon( playerid ) == 42 || GetVehicleModel( iVehicle ) == 407 )
		{
			for( new i = 0; i < sizeof( g_fireData ); i ++ ) if ( g_fireData[ i ] [ E_CREATED ] )
		    {
		    	static
					Float: fX, Float: fY, Float: fZ;

		 		if ( GetDynamicObjectPos( g_fireData[ i ] [ E_OBJECT ], fX, fY, fZ ) )
		 		{
					fZ += 2.3;

					if ( IsPlayerInRangeOfPoint( playerid, ( GetVehicleModel( iVehicle ) == 407 ? 25.0 : 10.0 ), fX, fY, fZ ) )
					{
						if ( IsPlayerAimingAt( playerid, fX, fY, fZ, ( GetVehicleModel( iVehicle ) == 407 ? 3.0 : 1.0 ) ) )
						{
						    if ( g_fireData[ i ] [ E_HEALTH ] > 0.0 )
							{
								if ( ( g_fireData[ i ] [ E_HEALTH ] -= GetVehicleModel( iVehicle ) == 407 ? ( 2.85 + fRandomEx( 1.0, 5.0 ) ) : ( 1.25 + fRandomEx( 1.0, 5.0 ) ) ) < 0.0 )
									g_fireData[ i ] [ E_HEALTH ] = 0.0;

				             	UpdateDynamic3DTextLabelText( g_fireData[ i ] [ E_LABEL ], COLOR_YELLOW, sprintf( "%0.1f", g_fireData[ i ] [ E_HEALTH ] ) );
							}
							else
						    {
								ach_HandleExtinguishedFires( playerid );
							    SendClientMessageToFireman( -1, "{A83434}[FIREMAN]{FFFFFF} %s(%d) has extinguished house fire %d.", ReturnPlayerName( playerid ), playerid, i );
								GivePlayerScore( playerid, 2 );
								//GivePlayerExperience( playerid, E_FIREMAN );
								GivePlayerCash( playerid, 5000 );

								g_fireData[ i ] [ E_CREATED ]	= false;
							    g_fireData[ i ] [ E_HOUSE ] = -1;
							    DestroyDynamicObject( g_fireData[ i ] [ E_OBJECT ] );
							    g_fireData[ i ] [ E_OBJECT ] = INVALID_OBJECT_ID;
							    DestroyDynamic3DTextLabel( g_fireData[ i ] [ E_LABEL ] );
							    g_fireData[ i ] [ E_LABEL ] = Text3D: INVALID_3DTEXT_ID;
						        g_fireData[ i ] [ E_HEALTH ] = 0.0;
				             	UpdateDynamic3DTextLabelText( g_fireData[ i ] [ E_LABEL ], COLOR_YELLOW, sprintf( "%0.1f", g_fireData[ i ] [ E_HEALTH ] ) );
						    }
							break;
						}
					}
				}
			}
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:firetracker( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_FIREMAN )
		return SendError( playerid, "You are not a fireman." );

	if ( p_FireDistanceTimer[ playerid ] != -1 )
		return StopPlayerFireTracker( playerid ), SendServerMessage( playerid, "You have turned off your fire tracker." );

	KillTimer( p_FireDistanceTimer[ playerid ] );
	p_FireDistanceTimer[ playerid ] = SetTimerEx( "OnPlayerFireDistanceUpdate", 1000, true, "d", playerid );
	SendServerMessage( playerid, "Find the fires and extinguish them." );
	return 1;
}

stock StopPlayerFireTracker( playerid )
{
	KillTimer( p_FireDistanceTimer[ playerid ] );
	p_FireDistanceTimer[ playerid ] = -1;

	PlayerTextDrawHide( playerid, p_FireDistance1[ playerid ] );
	PlayerTextDrawHide( playerid, p_FireDistance2[ playerid ] );
	return 1;
}

/* ** Functions ** */
stock CreateFire( )
{
	if ( fire_toggled )
	{
	    for ( new i = 0; i < sizeof( g_fireData ); i ++ ) if ( g_fireData[ i ] [ E_CREATED ] == true )
	    {
		    g_fireData[ i ] [ E_CREATED ] = false;
		    g_fireData[ i ] [ E_HOUSE ] = -1;
		    DestroyDynamicObject( g_fireData[ i ] [ E_OBJECT ] );
		    g_fireData[ i ] [ E_OBJECT ] = INVALID_OBJECT_ID;
		    DestroyDynamic3DTextLabel( g_fireData[ i ] [ E_LABEL ] );
		    g_fireData[ i ] [ E_LABEL ] = Text3D: INVALID_3DTEXT_ID;
	    }

	    fire_toggled = false;
	    CreateFire( );
	}
	else
	{
		static
			Float: X, Float: Y, Float: Z;

	    for ( new i = 0; i < sizeof( g_fireData ); i ++ )
	    {
			new
				house = GetRandomCreatedHouse( );

			if ( Iter_Contains( houses, house ) )
			{
				GetHousePos( house, X, Y, Z );
				g_fireData[ i ] [ E_HEALTH ] = 100.0 + fRandomEx( 1, 25 );
				g_fireData[ i ] [ E_HOUSE ] = house;
				g_fireData[ i ] [ E_CREATED ] = true;
				g_fireData[ i ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "%0.1f", g_fireData[ i ] [ E_HEALTH ] ), COLOR_YELLOW, X, Y, Z + 0.5, 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1 );
				g_fireData[ i ] [ E_OBJECT ] = CreateDynamicObject( 18691, X, Y, Z - 2.3, 0.0, 0.0, 0.0 );
			}
		}
	    fire_toggled = true;
	}
	return 1;
}

stock IsHouseOnFire( houseid )
{
	if ( houseid < 0 || houseid > MAX_HOUSES )
	    return 0;

	if ( ! Iter_Contains( houses, houseid ) )
	    return 0;

	for( new i, Float: X, Float: Y, Float: Z; i < sizeof( g_fireData ); i++ )
	{
	    if ( g_fireData[ i ] [ E_CREATED ] )
	    {
		    GetDynamicObjectPos( g_fireData[ i ] [ E_OBJECT ], X, Y, Z ); // Z is unused due to the object.
		    if ( g_houseData[ houseid ] [ E_EX ] == X && g_houseData[ houseid ] [ E_EY ] == Y )
		    {
		        return 1;
		    }
		}
	}
	return 0;
}

function OnPlayerFireDistanceUpdate( playerid )
{
    new
	    Float: X, Float: Y, Float: Z, Float: dis,
		szFire1[ 128 ], szFire2[ 128 ]
	;

	for( new i; i < sizeof( g_fireData ); i++ )
	{
	    GetDynamicObjectPos( g_fireData[ i ] [ E_OBJECT ], X, Y, Z );
	    dis = GetPlayerDistanceFromPoint( playerid, X, Y, Z );
	    if ( i < floatround( sizeof( g_fireData ) / 2 ) )
	    {
		    if ( g_fireData[ i ] [ E_CREATED ] == false ) format( szFire1, sizeof( szFire1 ), "%s~r~FIRE %d:%s ~g~Stopped~n~", szFire1, i,i==1?(" "):("") );
			else format( szFire1, sizeof( szFire1 ), "%s~r~FIRE %d:%s~w~ %0.0f m~n~", szFire1, i,i==1?("_"):(""), dis );
		}
		else
		{
		    if ( g_fireData[ i ] [ E_CREATED ] == false ) format( szFire2, sizeof( szFire2 ), "%s~r~FIRE %d:%s ~g~Stopped~n~", szFire2, i,i==1?(" "):("") );
			else format( szFire2, sizeof( szFire2 ), "%s~r~FIRE %d:%s~w~ %0.0f m~n~", szFire2, i,i==1?("_"):(""), dis );
		}
	}
	PlayerTextDrawSetString( playerid, p_FireDistance1[ playerid ], szFire1 );
	PlayerTextDrawSetString( playerid, p_FireDistance2[ playerid ], szFire2 );
	PlayerTextDrawShow( playerid, p_FireDistance1[ playerid ] );
	PlayerTextDrawShow( playerid, p_FireDistance2[ playerid ] );
	return 1;
}
