/*
 * Irresistible Gaming 2018
 * Developed by Lorenc
 * Module: helpers.inc
 * Purpose: functions that help scripting
 */

/* ** Includes ** */
#include                                    < YSI\y_va >

/* ** Macros ** */
#define function%1(%2)                      forward%1(%2); public%1(%2)
#define RandomEx(%0,%1)                     (random((%1) - (%0)) + (%0))
#define HOLDING(%0)                         ((newkeys & (%0)) == (%0))
#define PRESSED(%0)                         (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define RELEASED(%0)                        (((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
#define SendUsage(%0,%1)                    (SendClientMessageFormatted(%0,-1,"{FFAF00}[USAGE]{FFFFFF} " # %1))
#define SendError(%0,%1) 			        (SendClientMessageFormatted(%0,-1,"{F81414}[ERROR]{FFFFFF} " # %1))
#define SendServerMessage(%0,%1)            (SendClientMessageFormatted(%0,-1,"{C0C0C0}[SERVER]{FFFFFF} " # %1))
#define SendClientMessageToAllFormatted(%0) (SendClientMessageFormatted(INVALID_PLAYER_ID, %0))
#define sprintf(%1)                         (format(g_szSprintfBuffer, sizeof(g_szSprintfBuffer), %1), g_szSprintfBuffer)
#define SetObjectInvisible(%0)              (SetDynamicObjectMaterialText(%0, 0, " ", 140, "Arial", 64, 1, -32256, 0, 1))
#define fRandomEx(%1,%2)                    (floatrandom(%2-%1)+%1)
#define strmatch(%1,%2)                     (!strcmp(%1,%2,true))
#define Beep(%1)                            PlayerPlaySound(%1, 1137, 0.0, 0.0, 0.0)
#define StopSound(%1)                       PlayerPlaySound(%1,1186,0.0,0.0,0.0)
#define erase(%0)                           (%0[0]='\0')
#define positionToString(%0)                (%0==1?("st"):(%0==2?("nd"):(%0==3?("rd"):("th"))))
#define SetPlayerPosEx(%0,%1,%2,%3,%4)      SetPlayerPos(%0,%1,%2,%3),SetPlayerInterior(%0,%4)
#define mysql_single_query(%0)              mysql_function_query(dbHandle,(%0),true,"","")
#define points_format(%0)                   (number_format(%0, .prefix = '\0', .decimals = 2))

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

/* ** Function Hooks ** */
stock __svrticks__GetTickCount( )
{
    static
        offset = 0; // store the static value here

    new
        curr_tickcount = GetTickCount( );

    if ( curr_tickcount < 0 && offset == 0 )
    {
        offset = curr_tickcount * -1;
        print( "\n\n*** NEGATIVE TICK COUNT DETECTED... FIXING GetTickCount( )" );
    }
    return curr_tickcount + offset;
}

#if defined _ALS_GetTickCount
    #undef GetTickCount
#else
    #define _ALS_GetTickCount
#endif

#define GetTickCount __svrticks__GetTickCount

/* ** Functions ** */
stock SendClientMessageFormatted( playerid, colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	if ( playerid == INVALID_PLAYER_ID ) {
		return SendClientMessageToAll( colour, out );
	} else {
        return SendClientMessage( playerid, colour, out );
    }
}

// purpose: send client message to all rcon admins
stock SendClientMessageToRCON( colour, const format[ ], va_args<> )
{
    static
        out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

    foreach ( new i : Player ) if ( IsPlayerAdmin( i ) ) {
        SendClientMessage( i, colour, out );
    }
    return 1;
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

// purpose: clear chat for player
stock Player_Clearchat( playerid )
{
    for ( new j = 0; j < 30; j ++ ) {
        SendClientMessage( playerid, -1, " " );
    }
    return 1;
}

// purpose: get distance between players
stock Float: GetDistanceBetweenPlayers( iPlayer1, iPlayer2, &Float: fDistance = Float: 0x7F800000, bool: bAllowNpc = false )
{
    static
    	Float: fX, Float: fY, Float: fZ;

    if ( ! bAllowNpc && ( IsPlayerNPC( iPlayer1 ) || IsPlayerNPC( iPlayer2 ) ) ) // since this command is designed for players
        return fDistance;

    if( GetPlayerVirtualWorld( iPlayer1 ) == GetPlayerVirtualWorld( iPlayer2 ) && GetPlayerPos( iPlayer2, fX, fY, fZ ) )
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

// purpose: replaces a phrase in a string with whatever specified (credit Slice)
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

// purpose: convert integer into dollar string (large credit to Slice - i just added a prefix parameter)
stock number_format( { _, Float, Text3D, Menu, Text, DB, DBResult, bool, File }: variable, prefix = '\0', decimals = -1, thousand_seperator = ',', decimal_point = '.', tag = tagof( variable ) )
{
    static
        s_szReturn[ 32 ],
        s_szThousandSeparator[ 2 ] = { ' ', EOS },
        s_iDecimalPos,
        s_iChar,
        s_iSepPos
    ;

    if ( tag == tagof( bool: ) )
    {
        if ( variable )
            memcpy( s_szReturn, "true", 0, 5 * ( cellbits / 8 ) );
        else
            memcpy( s_szReturn, "false", 0, 6 * ( cellbits / 8 ) );

        return s_szReturn;
    }
    else if ( tag == tagof( Float: ) )
    {
        if ( decimals == -1 )
            decimals = 8;

        format( s_szReturn, sizeof( s_szReturn ), "%.*f", decimals, variable );
    }
    else
    {
        format( s_szReturn, sizeof( s_szReturn ), "%d", variable );

        if ( decimals > 0 )
        {
            strcat( s_szReturn, "." );

            while ( decimals-- )
                strcat( s_szReturn, "0" );
        }
    }

    s_iDecimalPos = strfind( s_szReturn, "." );

    if ( s_iDecimalPos == -1 )
        s_iDecimalPos = strlen( s_szReturn );
    else
        s_szReturn[ s_iDecimalPos ] = decimal_point;

    if ( s_iDecimalPos >= 4 && thousand_seperator )
    {
        s_szThousandSeparator[ 0 ] = thousand_seperator;

        s_iChar = s_iDecimalPos;
        s_iSepPos = 0;

        while ( --s_iChar > 0 )
        {
            if ( ++s_iSepPos == 3 && s_szReturn[ s_iChar - 1 ] != '-' )
            {
                strins( s_szReturn, s_szThousandSeparator, s_iChar );

                s_iSepPos = 0;
            }
        }
    }

    if ( prefix != '\0' )
    {
        static
            prefix_string[ 2 ];

        prefix_string[ 0 ] = prefix;
        strins( s_szReturn, prefix_string, s_szReturn[ 0 ] == '-' ); // no point finding -
    }
    return s_szReturn;
}

#define cash_format(%0) \
    (number_format(%0, .prefix = '$'))

// purpose: find a random element in sample space, excluding [a, b, c, ...]
stock randomExcept( except[ ], len = sizeof( except ), available_element_value = -1 ) {

    new bool: any_available_elements = false;

    // we will check if there are any elements that are not in except[]
    for ( new x = 0; x < len; x ++ ) if ( except[ x ] == available_element_value ) {
        any_available_elements = true;
        break;
    }

    // if all elements are included in except[], prevent continuing otherwise it will infinite loop
    if ( ! any_available_elements ) {
        return -1;
    }

    new random_number = random( len );

    // use recursion to find another element
    for ( new x = 0; x < len; x ++ ) {
        if ( random_number == except[ x ] ) {
            return randomExcept( except, len );
        }
    }
    return random_number;
}
