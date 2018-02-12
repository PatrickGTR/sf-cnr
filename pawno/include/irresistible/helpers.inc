/*
 * Irresistible Gaming 2018
 * Developed by Lorenc Pekaj
 * Module: helpers.inc
 * Purpose: functions that help scripting
 */

/* ** Macros ** */
#define function%1(%2)                      forward%1(%2); public%1(%2)
#define RandomEx(%0,%1)                     (random((%1) - (%0)) + (%0))
#define HOLDING(%0)                         ((newkeys & (%0)) == (%0))
#define PRESSED(%0)                         (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define SendUsage(%0,%1)                    (SendClientMessageFormatted(%0,-1,"{FFAF00}[USAGE]{FFFFFF} " # %1))
#define SendError(%0,%1) 			        (SendClientMessageFormatted(%0,-1,"{F81414}[ERROR]{FFFFFF} " # %1))
#define SendServerMessage(%0,%1)            (SendClientMessageFormatted(%0,-1,"{C0C0C0}[SERVER]{FFFFFF} " # %1))
#define sprintf(%1)                         (format(g_szSprintfBuffer, sizeof(g_szSprintfBuffer), %1), g_szSprintfBuffer)
#define SetObjectInvisible(%0)              (SetDynamicObjectMaterialText(%0, 0, " ", 140, "Arial", 64, 1, -32256, 0, 1))
#define fRandomEx(%1,%2)                    (floatrandom(%2-%1)+%1)
#define strmatch(%1,%2)                     (!strcmp(%1,%2,true))
#define Beep(%1)                            PlayerPlaySound(%1, 1137, 0.0, 0.0, 5.0)
#define StopSound(%1)                       PlayerPlaySound(%1,1186,0.0,0.0,0.0)
#define erase(%0)                           (%0[0]='\0')
#define positionToString(%0)                (%0==1?("st"):(%0==2?("nd"):(%0==3?("rd"):("th"))))
#define SetPlayerPosEx(%0,%1,%2,%3,%4)      SetPlayerPos(%0,%1,%2,%3),SetPlayerInterior(%0,%4)

// Defines
#define KEY_AIM                     (128)
#define thread                      function

/* ** Variables ** */
stock g_szSprintfBuffer[ 1024 ];
stock tmpVariable;

/* ** Functions ** */
stock SendClientMessageFormatted( playerid, colour, format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	if ( !IsPlayerConnected( playerid ) ) {
		SendClientMessageToAll( colour, out );
		return 0;
	}
 	return SendClientMessage( playerid, colour, out );
}

// purpose: trim a string
stock trimString( strSrc[ ] )
{
    new
        strPos
    ;
    for( strPos = strlen( strSrc ); strSrc[ strPos ] <= ' '; )
        strPos--;

    strSrc[ strPos + 1 ] = EOS;

    for( strPos = 0; strSrc[ strPos ] <= ' '; )
        strPos++;

    strdel( strSrc, 0, strPos );
}

// purpose: get distance between players
stock Float: GetDistanceBetweenPlayers( iPlayer1, iPlayer2, &Float: fDistance = Float: 0x7F800000 )
{
    static
    	Float: fX, Float: fY, Float: fZ;

    if( GetPlayerVirtualWorld( iPlayer1 ) == GetPlayerVirtualWorld( iPlayer2 ) && GetPlayerPos( iPlayer2, fX, fY, fZ ) && !IsPlayerNPC( iPlayer1 ) && !IsPlayerNPC( iPlayer2 ) )
		fDistance = GetPlayerDistanceFromPoint( iPlayer1, fX, fY, fZ );

    return fDistance;
}

// purpose: sets float precision (0.2313131 = 0.2300000)
stock Float: SetFloatPrecision( Float: fValue, iPrecision ) {
    new
        Float: fFinal,
        Float: fFraction = floatfract( fValue )
    ;

    fFinal = fFraction * floatpower( 10.0, iPrecision );
    fFinal -= floatfract( fFinal );
    fFinal /= floatpower( 10.0, iPrecision );

    return ( fFinal + fValue - fFraction );
}

// purpose: get distance between 2d points
stock Float: GetDistanceFromPointToPoint( Float: fX, Float: fY, Float: fX1, Float: fY1 )
    return Float: floatsqroot( floatpower( fX - fX1, 2 ) + floatpower( fY - fY1, 2 ) );

// purpose: get distance between 3d points
stock Float: GetDistanceBetweenPoints( Float: x1, Float: y1, Float: z1, Float: x2, Float: y2, Float: z2 )
    return VectorSize( x1 - x2, y1 - y2, z1 - z2 );

// purpose: return raw distance without square root
stock Float: GetDistanceFromPlayerSquared( playerid, Float: x1, Float: y1, Float: z1 ) {
    new
        Float: x2, Float: y2, Float: z2;

    if( !GetPlayerPos( playerid, x2, y2, z2 ) )
        return FLOAT_INFINITY;

    x1 -= x2;
    x1 *= x1;
    y1 -= y2;
    y1 *= y1;
    z1 -= z2;
    z1 *= z1;
    return ( x1 + y1 + z1 );
}

// purpose: random float number support
stock Float: floatrandom( Float:max )
    return floatmul( floatdiv( float( random( cellmax ) ), float( cellmax - 1 ) ), max );
