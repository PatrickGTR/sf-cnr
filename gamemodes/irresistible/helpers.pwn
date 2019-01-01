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
#define mysql_single_query(%0)              mysql_tquery(dbHandle,(%0),"","")
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

// purpose: generate a random string up to a length
stock randomString( strDest[ ], strLen = 10 ) {
    while ( strLen -- )  {
        strDest[ strLen ] = random( 2 ) ? ( random( 26 ) + ( random( 2 ) ? 'a' : 'A' ) ) : ( random( 10 ) + '0' );
    }
}

// purpose: check if a string contains an IP address
stock textContainsIP(const string[])
{
#if defined _regex_included
    static
        RegEx: rCIP;

    if ( ! rCIP ) {
        rCIP = regex_build( "(.*?)([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})(.*?)" );
    }
    return regex_match_exid( string, rCIP );
#else
    #warning "You are not using a regex plugin for textContainsIP!"
    return 1;
#endif
}

// purpose: get the driver of a vehicle
stock GetVehicleDriver( vehicleid )
{
	foreach(new i : Player)
		if ( IsPlayerInVehicle( i, vehicleid ) && GetPlayerState( i ) == PLAYER_STATE_DRIVER )
			return i;

	return INVALID_PLAYER_ID;
}

// purpose: check if there's an even number of ~ in a string
stock IsSafeGameText(const string[])
{
    new count;
    for(new num, len = strlen(string); num < len; num++)
    {
        if (string[num] == '~')
		{
		    if ((num + 1) < len)
			{
				if (string[(num + 1)] == '~') return false;
			}
			count += 1;
		}
    }
    if ((count % 2) > 0) return false;
    return true;
}

// purpose: censor a string up to n characters
stock CensoreString( query[ ], characters = 5 )
{
	static
		szString[ 256 ];

	format( szString, 256, query );
	strdel( szString, 0, characters );

	for( new i = 0; i < characters; i++ )
		strins( szString, "*", 0 );

	return szString;
}

// purpose: return current date as DD/MM/YYYY
stock getCurrentDate( )
{
	static
		Year, Month, Day,
		szString[ 11 ]
	;

	getdate( Year, Month, Day );
	format( szString, sizeof( szString ), "%02d/%02d/%d", Day, Month, Year );
	return szString;
}

// purpose: return current time as HH:MM:SS
stock getCurrentTime( )
{
	static
		Hour, Minute, Second,
		szString[ 11 ]
	;

	gettime( Hour, Minute, Second );
	format( szString, sizeof( szString ), "%02d:%02d:%02d", Hour, Minute, Second );
	return szString;
}

// purpose: check if a player is in water (credit: SuperViper)
stock IsPlayerInWater(playerid)
{
    new animationIndex = GetPlayerAnimationIndex(playerid);
    return (animationIndex >= 1538 && animationIndex <= 1544 && animationIndex != 1542);
}

// purpose: return a random argument
stock randarg( ... )
	return getarg( random( numargs( ) ) );

// purpose: remove a weapon(s) from a player (credit: ryder`?)
stock RemovePlayerWeapon(playerid, ...)
{
    new iArgs = numargs();
    while(--iArgs)
    {
        SetPlayerAmmo(playerid, getarg(iArgs), 0);
    }
}

// purpose: check if a weapon id is a melee weapon id
stock IsMeleeWeapon(value) {
	static const valid_values[2] = {
		65535, 28928
	};
	if (0 <= value <= 46) {
		return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
	}
	return false;
}

// purpose: check if a specific vehicle is upside down
stock IsVehicleUpsideDown(vehicleid)
{
    new
        Float: q_W,
        Float: q_X,
        Float: q_Y,
        Float: q_Z
    ;
    GetVehicleRotationQuat(vehicleid, q_W, q_X, q_Y, q_Z);
    return (120.0 < atan2(2.0 * ((q_Y * q_Z) + (q_X * q_W)), (-(q_X * q_X) - (q_Y * q_Y) + (q_Z * q_Z) + (q_W * q_W))) > -120.0);
}

// purpose: convert seconds into a human readable string (credit: BlackLite?)
stock secondstotime(seconds, const delimiter[] = ", ", start = 0, end = -1)
{
    static const times[] = {
        1,
        60,
        3600,
        86400,
        604800,
        2419200,
        29030400
    };

    static const names[][] = {
        "second",
        "minute",
        "hour",
        "day",
        "week",
        "month",
        "year"
    };

    static string[128];

    if (!seconds)
    {
    	string = "N/A";
    	return string;
    }

    erase(string);

    for(new i = start != 0 ? start : (sizeof(times) - 1); i != end; i--)
    {
        if (seconds / times[i])
        {
            if (string[0])
            {
                format(string, sizeof(string), "%s%s%d %s%s", string, delimiter, (seconds / times[i]), names[i], ((seconds / times[i]) == 1) ? ("") : ("s"));
            }
            else
            {
                format(string, sizeof(string), "%d %s%s", (seconds / times[i]), names[i], ((seconds / times[i]) == 1) ? ("") : ("s"));
            }
            seconds -= ((seconds / times[i]) * times[i]);
        }
    }
    return string;
}

// purpose: check if a string is bad for textdraws / crashy
stock textContainsBadTextdrawLetters( const string[ ] )
{
	for( new i, j = strlen( string ); i < j; i++ )
	{
	    if ( string[ i ] == '.' || string[ i ] == '*' || string[ i ] == '^' || string[ i ] == '~' )
	        return true;
	}
	return false;
}

// purpose: check if a valid skin id was selected
stock IsValidSkin( skinid ) {
	return ! ( skinid == 74 || skinid > 311 || skinid < 0 );
}

// purpose: check if a string is hexidecimal (credit: dracoblue)
stock isHex(str[])
{
    new
        i,
        cur;
    if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) i = 2;
    while (str[i])
    {
        cur = str[i++];
        if (!(('0' <= cur <= '9') || ('A' <= cur <= 'F') || ('a' <= cur <= 'f'))) return 0;
    }
    return 1;
}

// purpose: check if a player has a weapon on them
stock IsWeaponInAnySlot( playerid, weaponid )
{
    new
        szWeapon, szAmmo;

    GetPlayerWeaponData( playerid, GetWeaponSlot( weaponid ), szWeapon, szAmmo );
    return ( szWeapon == weaponid && szAmmo > 0 );
}

// purpose: check if a player is within an area (min, max)
stock IsPlayerInArea( playerid, Float: minx, Float: maxx, Float: miny, Float: maxy )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( GetPlayerPos( playerid, X, Y, Z ) )
		return ( X > minx && X < maxx && Y > miny && Y < maxy );

	return 0;
}

// purpose (deprecated): moves the player a smige so that objects can load
stock SyncObject( playerid, Float: offsetX = 0.005, Float: offsetY = 0.005, Float: offsetZ = 0.005 )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( GetPlayerPos( playerid, X, Y, Z ) )
		SetPlayerPos( playerid, X + offsetX, Y + offsetY, Z + offsetZ );
}

// purpose: check if a point is within an area
stock IsPointInArea( Float: X, Float: Y, Float: Z, Float: minx, Float: maxx, Float: miny, Float: maxy, Float: minz, Float: maxz )
 	return ( X > minx && X < maxx && Y > miny && Y < maxy && Z > minz && Z < maxz );

// purpose: convert a string into hexidecimal number (credit: DracoBlue)
stock HexToInt( string[ ] )
{
	if ( isnull( string ) )
		return 0;

  	new
  		cur = 1,
  		res = 0
  	;

	for( new i; string[ i ] != EOS; ++i )
	{
		string[ i ] = ( 'a' <= string[ i ] <= 'z' ) ? ( string[ i ] += 'A' - 'a' ) : ( string[ i ] );
	}

  	for( new i = strlen( string ); i > 0; i-- )
  	{
  	  	res += string[ i - 1 ] < 58 ? ( cur * ( string[ i - 1 ] - 48 ) ) : ( cur * ( string[ i - 1 ] - 65 + 10 ) );
    	cur *= 16;
  	}
  	return res;
}

// purpose: get the closest vehicle id to the player
stock GetClosestVehicle(playerid, except = INVALID_VEHICLE_ID, &Float: distance = Float: 0x7F800000) {
    new
    	i,
        Float: X,
        Float: Y,
        Float: Z
    ;
    if (GetPlayerPos(playerid, X, Y, Z)) {
        new
            Float: dis,
            closest = INVALID_VEHICLE_ID
        ;
        while(i != MAX_VEHICLES) {
            if (0.0 < (dis = GetVehicleDistanceFromPoint(++i, X, Y, Z)) < distance && i != except) {
                distance = dis;
                closest = i;
            }
        }
        return closest;
    }
    return INVALID_VEHICLE_ID;
}

// purpose: check if a point is near to another point
stock IsPointToPoint(Float: fRadius, Float: fX1, Float: fY1, Float: fZ1, Float: fX2, Float: fY2, Float: fZ2)
    return ((-fRadius < floatabs(fX2 - fX1) < fRadius) && (-fRadius < floatabs(fY2 - fY1) < fRadius) && (-fRadius < floatabs(fZ2 - fZ1) < fRadius));

// purpose: get the X, Y in front of a player at N distance
stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, &Float:z, Float:distance)
{
	new Float: a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    if (GetPlayerVehicleID( playerid ))
    {
    	GetVehicleZAngle(GetPlayerVehicleID( playerid ), a);
 	}
 	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

// purpose: change a vehicle's model with an object id ... doozy function
stock ChangeVehicleModel( vehicleid, objectid, Float: offset = 0.0 )
{
	new
		iObject
	;
	iObject = CreateDynamicObject( objectid, 0.0, 0.0, 0.0, 0, 0, 0 );
	AttachDynamicObjectToVehicle( iObject, vehicleid, 0, 0, 0, 0, 0, 0 + offset );
	LinkVehicleToInterior( vehicleid, 12 );
}

// purpose: make an object face a specific point
stock SetObjectFacePoint(iObjectID, Float: fX, Float: fY, Float: fOffset, bool: bDynamic = false )
{
    new
        Float: fOX,
        Float: fOY,
        Float: fRZ
    ;
    if ( bDynamic )
    {
	    if (GetDynamicObjectPos(iObjectID, fOX, fOY, fRZ))
	    {
	        fRZ = atan2(fY - fOY, fX - fOX) - 90.0;

	        GetDynamicObjectRot(iObjectID, fX, fY, fOX);
	        SetDynamicObjectRot(iObjectID, fX, fY, fRZ + fOffset);
	    }
	}
	else
	{
	    if (GetObjectPos(iObjectID, fOX, fOY, fRZ))
	    {
	        fRZ = atan2(fY - fOY, fX - fOX) - 90.0;

	        GetObjectRot(iObjectID, fX, fY, fOX);
	        SetObjectRot(iObjectID, fX, fY, fRZ + fOffset);
	    }
	}
}

// purpose: convert seconds into a MM:SS format e.g 10:00 ... good for racing
stock TimeConvert( seconds )
{
	static
	    szTime[ 32 ]
	;
 	format( szTime, sizeof( szTime ), "%02d:%02d", floatround( seconds / 60 ), seconds - floatround( ( seconds / 60 ) * 60 ) );
	return szTime;
}

// purpose: make the player face a specific point
stock SetPlayerFacePoint(playerid, Float: fX, Float: fY, Float: offset = 0.0)
{
    static
        Float: X,
        Float: Y,
        Float: Z,
        Float: face
    ;
    if (GetPlayerPos(playerid, X, Y, Z))
    {
        face = atan2(fY - Y, fX - X) - 90.0;
        SetPlayerFacingAngle(playerid, face + offset);
    }
}

// purpose: get the closest player to the player
stock GetClosestPlayer( playerid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = INVALID_PLAYER_ID,
        Float: fX, Float: fY,  Float: fZ, Float: fTmp,
        world = GetPlayerVirtualWorld( playerid )
    ;

    if ( GetPlayerPos( playerid, fX, fY, fZ ) )
    {
		foreach(new i : Player)
		{
			if ( i != playerid )
			{
		        if ( GetPlayerState( i ) != PLAYER_STATE_SPECTATING && GetPlayerVirtualWorld( i ) == world )
		        {
		            if ( 0.0 < ( fTmp = GetDistanceFromPlayerSquared( i, fX, fY, fZ ) ) < distance ) // Y_Less mentioned there's no need to sqroot
		            {
		                distance = fTmp;
		                iCurrent = i;
		            }
		        }
			}
	    }
    }
    return iCurrent;
}

// purpose: place a player in a vehicle with an available seat
stock PutPlayerInEmptyVehicleSeat( vehicleid, playerid )
{
	new
		vModel = GetVehicleModel( vehicleid ),
	    bool: bNonAvailable[ 16 char ],
	    seats = 0xF
	;

	if ( !IsValidVehicle( vehicleid ) )
	    return -1;

	if ( vModel == 425 || vModel == 481 || vModel == 520 || vModel == 519 || vModel == 509 || vModel == 510 || vModel == 476 )
		return -1;

	foreach(new iPlayer : Player)
	{
		if ( IsPlayerInVehicle( iPlayer, vehicleid ) )
		{
			new iVehicle = GetPlayerVehicleSeat( iPlayer );
			seats = GetVehicleSeatCount( GetVehicleModel( iVehicle ) );

   			if ( seats == 0xF )
	   			return -1; // Just so the player aint bugged.

			if ( iVehicle >= 0 && iVehicle <= seats ) bNonAvailable{ iVehicle } = true;
		}
	}
	for( new i = 1; i < sizeof( bNonAvailable ); i++ )
	{
	    if ( !bNonAvailable{ i } ) {
			SetPlayerVirtualWorld( playerid, GetVehicleVirtualWorld( vehicleid ) );
			SetPlayerInterior( playerid, 0 ); // All vehicles are in interior ID 0, unless a stupid did this :|
			PutPlayerInVehicle( playerid, vehicleid, i );
			break;
		}
	}
	return seats;
}

// purpose: get the player id from a name
stock GetPlayerIDFromName( const pName[ ] )
{
    foreach(new i : Player)
    {
        if ( strmatch( pName, ReturnPlayerName( i ) ) )
			return i;
    }
    return INVALID_PLAYER_ID;
}

// purpose (deprecated): quickly write/append a line to a file
stock AddFileLogLine( const file[ ], input[ ] )
{
    new
		File: fHandle;

    fHandle = fopen(file, io_append);
    fwrite(fHandle, input);
    fclose(fHandle);
    return 1;
}

// purpose: check if a string is numeric
stock IsNumeric(const str[ ])
{
    new len = strlen(str);

    if (!len) return false;
    for(new i; i < len; i++)
    {
        if (!('0' <= str[i] <= '9')) return false;
    }
    return true;
}

// purpose: set a server rule
stock SetServerRule( const rule[ ], const value[ ] ) {
	return SendRconCommand( sprintf( "%s %s", rule, value ) );
}