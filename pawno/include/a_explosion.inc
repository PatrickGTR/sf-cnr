/*
	*
	*	Author: Lorenc P.
	*	Uses: Call Deaths with Explosions
	*	Credits: Mauzen, I just edited lol
	*
*/

/* ** Stopping crap from duplicate ** */
#if defined using_lexplode
	#endinput
#endif
#define using_lexplode

/* ** Includes ** */
#tryinclude 						< foreach >

/* ** Some Functions ** */
#define DestroyObjectTimed(%0,%1)					SetTimerEx("lexplode_Destroy",%1,0,"i",%0)

/* ** Includes ** */
#define EXPLOSION_TYPE_FUEL_CAR                 	( 0 )
#define EXPLOSION_TYPE_LARGE                    	( 1 )
#define EXPLOSION_TYPE_MEDIUM                       ( 2 )
#define EXPLOSION_TYPE_MOLOTOV                      ( 3 )
#define EXPLOSION_TYPE_SMALL                        ( 4 )
#define EXPLOSION_TYPE_TINY                         ( 5 )

/* ** Forwards ** */
forward OnPlayerExplosion( killerid, playerid, reason );
forward lexplode_Destroy( objectid ); 

/* ** Script ** */
stock CreateExplosionEx( playerid, Float: x, Float: y, Float: z, Float: radius, type = EXPLOSION_TYPE_MEDIUM, reason )
{
	if( type < 0 || type > 5 ) 
		return;

	new 
		objectid = INVALID_OBJECT_ID;

	objectid = CreateObject( 18681 + type, x, y, z - 1.5, 0.0, 0.0, 0.0, 1000.0 );
	SetTimerEx( "lexplode_Destroy", 5000, 0, "i", objectid );

	if( type == 1 || type == 2 || type == 4 ) CreateExplosion( x, y, z, 13, 0.0 );
	
	foreach(new i : Player)
    {
	 	PlayerPlaySound( i, 1159, x, y, z );
		if( i == playerid ) continue;
		if( p_Team[ i ] == p_Team[ playerid ] ) continue;
		if( !p_Spawned{ i } ) continue;
		if( p_Spectating{ i } ) continue;
		if( !IsPlayerInRangeOfPoint( i, radius, x, y, z ) ) continue;
		OnPlayerExplosion( playerid, i, reason );
    }
}

public lexplode_Destroy( objectid )
	return DestroyObject(objectid);