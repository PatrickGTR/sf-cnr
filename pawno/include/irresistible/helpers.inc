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
#define mysql_single_query(%0)              mysql_function_query(dbHandle,(%0),true,"","")

// Defines
#define KEY_AIM                             (128)
#define thread                              function // used to look pretty for mysql

/* ** Variables ** */
stock szSmallString[ 32 ];
stock szNormalString[ 144 ];
stock szBigString[ 256 ];
stock szLargeString[ 1024 ];
stock szHugeString[ 2048 ];
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

// purpose: replace a character
stock strreplacechar(string[], oldchar, newchar)
{
    new matches;
    if (ispacked(string)) {
        if (newchar == '\0') {
            for(new i; string{i} != '\0'; i++) {
                if (string{i} == oldchar) {
                    strdel(string, i, i + 1);
                    matches++;
                }
            }
        } else {
            for(new i; string{i} != '\0'; i++) {
                if (string{i} == oldchar) {
                    string{i} = newchar;
                    matches++;
                }
            }
        }
    } else {
        if (newchar == '\0') {
            for(new i; string[i] != '\0'; i++) {
                if (string[i] == oldchar) {
                    strdel(string, i, i + 1);
                    matches++;
                }
            }
        } else {
            for(new i; string[i] != '\0'; i++) {
                if (string[i] == oldchar) {
                    string[i] = newchar;
                    matches++;
                }
            }
        }
    }
    return matches;
}

// purpose: replaces a phrase in a string with whatever specified
stock strreplace(string[], const search[], const replacement[], bool:ignorecase = false, pos = 0, limit = -1, maxlength = sizeof(string)) {
    // No need to do anything if the limit is 0.
    if (limit == 0)
        return 0;

    new
             sublen = strlen(search),
             replen = strlen(replacement),
        bool:packed = ispacked(string),
             maxlen = maxlength,
             len = strlen(string),
             count = 0
    ;


    // "maxlen" holds the max string length (not to be confused with "maxlength", which holds the max. array size).
    // Since packed strings hold 4 characters per array slot, we multiply "maxlen" by 4.
    if (packed)
        maxlen *= 4;

    // If the length of the substring is 0, we have nothing to look for..
    if (!sublen)
        return 0;

    // In this line we both assign the return value from "strfind" to "pos" then check if it's -1.
    while (-1 != (pos = strfind(string, search, ignorecase, pos))) {
        // Delete the string we found
        strdel(string, pos, pos + sublen);

        len -= sublen;

        // If there's anything to put as replacement, insert it. Make sure there's enough room first.
        if (replen && len + replen < maxlen) {
            strins(string, replacement, pos, maxlength);

            pos += replen;
            len += replen;
        }

        // Is there a limit of number of replacements, if so, did we break it?
        if (limit != -1 && ++count >= limit)
            break;
    }

    return count;
}

// purpose: copy a string from a source to a destination
/*stock strcpy(dest[], const source[], maxlength=sizeof dest) {
    strcat((dest[0] = EOS, dest), source, maxlength);
}*/

// purpose: get unattached player object index
stock Player_GetUnusedAttachIndex( playerid )
{
    for ( new i = 0; i < MAX_PLAYER_ATTACHED_OBJECTS; i ++ )
        if ( ! IsPlayerAttachedObjectSlotUsed( playerid, i ) )
            return i;

    return cellmin;
}

// purpose: convert integer into dollar string
stock ConvertPrice( iValue, iCashSign = 1 )
{
    static
        szNum[ 32 ];

    format( szNum, sizeof( szNum ), "%d", iValue < 0 ? -iValue : iValue );

    for( new i = strlen( szNum ) - 3; i > 0; i -= 3 ) {
        strins( szNum, ",", i, sizeof( szNum ) );
    }

    if ( iCashSign ) strins( szNum, "$", 0 );
    if ( iValue < 0 ) strins( szNum, "-", 0, sizeof( szNum ) );

    return szNum;
}
