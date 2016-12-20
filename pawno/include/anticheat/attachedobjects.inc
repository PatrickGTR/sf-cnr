/*
 *	
 *
 */

#include 							< a_samp >

enum E_ATTACHED_OBJECTS
{
	E_ENABLED,		E_MODEL,		E_BONE,
	Float: E_X, 	Float: E_Y, 	Float: E_Z,
	Float: E_RX, 	Float: E_RY, 	Float: E_RZ,
	Float: E_SX, 	Float: E_SY, 	Float: E_SZ,
	E_COLOR_1,		E_COLOR_2
};

new
	g_aofix_AttachedPlayerData[ MAX_PLAYERS ] [ 10 ] [ E_ATTACHED_OBJECTS ]
;

// Function Hook (GivePlayerWeapon)
stock AOFX_SetPlayerAttachedObject( playerid, index, modelid, bone, Float: fOffsetX = 0.0, Float: fOffsetY = 0.0, Float: fOffsetZ = 0.0, Float: fRotX = 0.0, Float: fRotY = 0.0, Float: fRotZ = 0.0, Float: fScaleX = 1.0, Float: fScaleY = 1.0, Float: fScaleZ = 1.0, materialcolor1 = 0, materialcolor2 = 0 )
{
	if( 0 < index < 9 )
	{
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_ENABLED ] = true;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_MODEL ] = modelid;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_BONE ] = bone;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_COLOR_1 ] = materialcolor1;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_COLOR_2 ] = materialcolor2;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_X ] = fOffsetX;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_Y ] = fOffsetY;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_Z ] = fOffsetZ;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_RX ] = fRotX;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_RY ] = fRotY;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_RZ ] = fRotZ;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_SX ] = fScaleX;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_SY ] = fScaleY;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_SZ ] = fScaleZ;
	}
	return SetPlayerAttachedObject( playerid, index, modelid, bone, Float: fOffsetX = 0.0, Float: fOffsetY = 0.0, Float: fOffsetZ = 0.0, Float: fRotX = 0.0, Float: fRotY = 0.0, Float: fRotZ = 0.0, Float: fScaleX = 1.0, Float: fScaleY = 1.0, Float: fScaleZ = 1.0, materialcolor1 = 0, materialcolor2 = 0 );
}

#if defined _ALS_SetPlayerAttachedObject
    #undef SetPlayerAttachedObject
#else
    #define _ALS_SetPlayerAttachedObject
#endif
#define SetPlayerAttachedObject AOFX_SetPlayerAttachedObject

// Function Hook (ResetPlayerWeapons)

stock AC_IsPlayerAttachedObjectSlotUsed( playerid, index )
{
	if( 0 < index < 9 && g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_MODEL ] != INVALID_OBJECT_ID )
		return true;
	
    return RemovePlayerAttachedObject( playerid, index );
}

#if defined _ALS_IsPlayerAttachedObjectSlotUsed
    #undef IsPlayerAttachedObjectSlotUsed
#else
    #define _ALS_IsPlayerAttachedObjectSlotUsed
#endif
#define IsPlayerAttachedObjectSlotUsed AC_IsPlayerAttachedObjectSlotUsed

// Function Hook (ResetPlayerWeapons)

stock AC_RemovePlayerAttachedObject( playerid, index )
{
	if( 0 < index < 9 )
 		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_MODEL ] = INVALID_OBJECT_ID;

    return RemovePlayerAttachedObject( playerid, index );
}

#if defined _ALS_RemovePlayerAttachedObject
    #undef RemovePlayerAttachedObject
#else
    #define _ALS_RemovePlayerAttachedObject
#endif
#define RemovePlayerAttachedObject AC_RemovePlayerAttachedObject

// Callback Hook (OnPlayerEditAttachedObject)

public OnPlayerEditAttachedObject( playerid, response, index, modelid, boneid, Float: fOffsetX, Float: fOffsetY, Float: fOffsetZ, Float: fRotX, Float: fRotY, Float: fRotZ, Float: fScaleX, Float: fScaleY, Float: fScaleZ )
{
	// If the attached object was saved, update some variables.
	if( response && ( 0 < index < 9 ) ) {
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_ENABLED ] = true;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_MODEL ] = modelid;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_BONE ] = boneid;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_X ] = fOffsetX;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_Y ] = fOffsetY;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_Z ] = fOffsetZ;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_RX ] = fRotX;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_RY ] = fRotY;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_RZ ] = fRotZ;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_SX ] = fScaleX;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_SY ] = fScaleY;
		g_aofix_AttachedPlayerData[ playerid ] [ index ] [ E_SZ ] = fScaleZ;
	}

	#if defined AOFX_OnPlayerEditAttachedObject
		return AOFX_OnPlayerEditAttachedObject( playerid, response, index, modelid, boneid, Float: fOffsetX, Float: fOffsetY, Float: fOffsetZ, Float: fRotX, Float: fRotY, Float: fRotZ, Float: fScaleX, Float: fScaleY, Float: fScaleZ );
	#else
		return 1;
	#endif
}

#if defined AOFX_OnPlayerEditAttachedObject
	forward AOFX_OnPlayerEditAttachedObject( playerid, response, index, modelid, boneid, Float: fOffsetX, Float: fOffsetY, Float: fOffsetZ, Float: fRotX, Float: fRotY, Float: fRotZ, Float: fScaleX, Float: fScaleY, Float: fScaleZ );
#endif
#if defined _ALS_OnPlayerEditAttachedObject
	#undef OnPlayerEditAttachedObject
#else
	#define _ALS_OnPlayerEditAttachedObject
#endif
#define OnPlayerEditAttachedObject AOFX_OnPlayerEditAttachedObject

// Callback Hook (OnPlayerKeyStateChange)

public OnPlayerKeyStateChange( playerid, newkeys, oldkeys ) {
	new
		weaponid = GetPlayerWeapon( playerid );

	if( weaponid == WEAPON_SNIPER ) {
		// Pressed key
		if( ( newkeys & 0x80 ) == 0x80 ) {
	 		TogglePlayerAttachedObjects( playerid, false );
		}
	 	// Released aim key
		else if( ( ( newkeys & 0x80 ) != 0x80 ) && ( ( oldkeys & 0x80 ) == 0x80 ) ) {
	 		TogglePlayerAttachedObjects( playerid, true );
		}
	}

	#if defined AOFX_OnPlayerKeyStateChange
		return AOFX_OnPlayerKeyStateChange( playerid, newkeys, oldkeys );
	#else
		return 1;
	#endif
}

#if defined AOFX_OnPlayerKeyStateChange
	forward AOFX_OnPlayerKeyStateChange( playerid, newkeys, oldkeys );
#endif
#if defined _ALS_OnPlayerKeyStateChange
	#undef OnPlayerKeyStateChange
#else
	#define _ALS_OnPlayerKeyStateChange
#endif
#define OnPlayerKeyStateChange AOFX_OnPlayerKeyStateChange

// Function (TogglePlayerAttachedObjects)

stock TogglePlayerAttachedObjects( playerid, bool: show = true ) {
	for( new i = 0, modelid; i < sizeof( g_aofix_AttachedPlayerData[ ] ); i++ ) {
		if( show ) {
			if( g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_MODEL ] != INVALID_OBJECT_ID ) {
				SetPlayerAttachedObject( playerid, i, g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_MODEL ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_BONE ],
					g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_X ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_Y ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_Z ],
					g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_RX ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_RY ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_RZ ],
					g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_SX ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_SY ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_SZ ],
					g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_COLOR_1 ], g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_COLOR_2 ]
				);				
			}
		} else {
 			if( ( modelid = g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_MODEL ] ) != INVALID_OBJECT_ID ) {
				RemovePlayerAttachedObject( playerid, i );
				g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_ENABLED ] = false;
				g_aofix_AttachedPlayerData[ playerid ] [ i ] [ E_MODEL ] = modelid; // Gets reset to INVALID_OBJECT_ID otherwise
			}
		}
	}
}