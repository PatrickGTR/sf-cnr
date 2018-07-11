/*
 *
 *
 *	SECURITYGUARD01 - 04 = SF
 *  SECURITYGUARD05 - 07 = LV
 *	SECURITYGUARD08 - 10 = LS
 *
*/

#include 							< a_npc >

#define IDLE_RECORDING 				( "SECURITYGUARD_IDLE" )

#undef  MAX_PLAYERS
#define MAX_PLAYERS 				( 126 )

#define strmatch(%1,%2) 			(!strcmp(%1,%2,true))

/* ** Variables ** */
new t_NPCUpdate 		= 0xFFFF;
new bool: b_Paused 		= false;
new bool: b_Provoked 	= false;
new bool: b_Disabled 	= false;
new bool: b_Idle 		= false;
new bool: b_Robbed 		= false;
new iRecentTrack 		= -1;

new iIdleTS 			= 0;
new iRestartTS 			= 0;

/* ** Messages ** */
new
	g_LeavingMessages[ ] [ ] =
	{
		{ "We've secured the security truck without any conflict." },
		{ "Time for our team to take a coffee break." },
		{ "Schedules have been met without conflict." },
		{ "Our team is now going off-duty." }
	},

	g_JoiningMessages[ ] [ ] =
	{
		{ "We are now sending a security truck to deliver cash." },
		{ "Our team has came back from their coffee break." },
		{ "A new schedule to deliver cash to ATMs has been made." },
		{ "Our team is now on duty and making deliveries." }
	},

	g_RobbedMessages[ ] [ ] =
	{
		{ "Our systems detect that our convoy have been intruded." },
		{ "We have lost connection with our scheduled security truck." },
		{ "Our security truck has went missing and failed its schedules." },
		{ "We have had our security truck towed away due to a robbery." }
	}
;

/* ** Events ** */
public OnSecurityGuardUpdate( );

main( ) { }

public OnNPCModeInit( )
{
	t_NPCUpdate = SetTimer( "OnSecurityGuardUpdate", 500, true );
	return 1;
}

public OnNPCModeExit( )
{
	KillTimer( t_NPCUpdate );
	return 1;
}

public OnNPCDisconnect( reason[ ] )
{
	resetNPCData( );
	return 1;
}

public OnRecordingPlaybackEnd( )
{
	if( b_Idle ) {
		// Constant idle at 2K, 2K, 2K
		StartRecordingPlayback( PLAYER_RECORDING_TYPE_DRIVER, IDLE_RECORDING );
		return 1;
	}

	SetMeIdleForRestart( );
	return 1;
}

public OnNPCSpawn( )
{
	GenerateNewPlayback( );
	return 1;
}

public OnPlayerText( playerid, text[ ] )
{
    return 1;
}

public OnClientMessage( color, text[ ] )
{
	if( !strcmp( text, "[0x00][NPC] TRUCK DISABLED." ) && color == 0x112233FF )
	{
		if( !b_Disabled ) {
			b_Disabled = true;
			PauseRecordingPlayback( );
			//SendChat( "I can't move my truck? What the hell..." );
		}
		return 1;
	}
	if( !strcmp( text, "[0x01][NPC] PROVOKED." ) && color == 0x112233FF )
	{
		if( !b_Provoked ) {
			if( b_Paused ) {
				b_Paused = false;
				ResumeRecordingPlayback( );
			}
			b_Provoked = true;
			//SendChat( "What...? Gunfire? Oh. Shit!" );
		}
		return 1;
	}
	if( !strcmp( text, "[0x02] RESTART." ) && color == 0x112233FF )
	{
		b_Robbed = true;
		iIdleTS = gettime( ) + 10;
		return 1;
	}
	if( !strcmp( text, "[0x03] 300 SECOND START." ) && color == 0x112233FF )
	{
		iRestartTS = gettime( ) + 300;
		return 1;
	}
	return 1;
}

public OnSecurityGuardUpdate( )
{
	new
		time = gettime( );

	if( !( b_Disabled || b_Provoked || b_Idle ) ) {
		new
			hasAnyPlayersInfront = IsAnyPlayerInfrontOfMe( )
		;

		if( hasAnyPlayersInfront )
		{
			if( b_Paused == false ) {
				PauseRecordingPlayback( );
				b_Paused = true;
			}
		}
		else
		{
			if( b_Paused == true ) {
				ResumeRecordingPlayback( );
				b_Paused = false;
			}
		}
	}
	else
	{
		if( time > iRestartTS && iRestartTS != 0 && b_Idle == true ) {
			GenerateNewPlayback( );
			return 1;
		}

		if( time > iIdleTS && iIdleTS != 0 ) {
			SetMeIdleForRestart( );
			return 1;
		}
	}
	return 1;
}

public OnNPCEnterVehicle( vehicleid, seatid )
{
    return 1;
}

public OnNPCExitVehicle()
{
    return 1;
}

// Functions
stock SetMeIdleForRestart( ) {
	if( b_Idle )
		return;

	b_Idle = true;
	iIdleTS = 0;
	SendChat( "End Security Guard" );

	if( !b_Robbed )
		SendChat( g_LeavingMessages[ random( sizeof( g_LeavingMessages ) ) ] );
	else
		SendChat( g_RobbedMessages[ random( sizeof( g_RobbedMessages ) ) ] );

	StopRecordingPlayback( );
	StartRecordingPlayback( PLAYER_RECORDING_TYPE_DRIVER, IDLE_RECORDING );
}

stock resetNPCData( ) {
	b_Paused 	= false;
	b_Provoked 	= false;
	b_Disabled 	= false;
	b_Idle 		= false;
	b_Robbed 	= false;
	iRestartTS 	= 0;
	iIdleTS 	= 0;
	iRecentTrack= -1;
}

stock GenerateNewPlayback( ) {
	new
		szLocation[ 16 ], iRandom;

	find_track:
	if( ( iRandom = random( 4 ) ) == iRecentTrack ) {
		goto find_track;
	}

	SendChat( g_JoiningMessages[ random( sizeof( g_JoiningMessages ) ) ] );
	format( szLocation, sizeof( szLocation ), "SECURITYGUARD%02d", iRandom );
	StopRecordingPlayback( );
	StartRecordingPlayback( PLAYER_RECORDING_TYPE_DRIVER, szLocation );

	resetNPCData( ); // Reset data last, because bugs can incur.
	iRecentTrack = iRandom; // So unique plays each time.
}

stock IsAnyPlayerInfrontOfMe( )
{
	new Float: X, Float: Y, Float: Z;

	for ( new i = 0; i < MAX_PLAYERS; i++ )
	{
	    if ( !IsPlayerConnected( i ) || !IsPlayerStreamedIn( i ) )
	        continue;

	    new
	    	iState = GetPlayerState( i );

	   	if( iState == PLAYER_STATE_ONFOOT || iState == PLAYER_STATE_DRIVER ) {
	   		GetXYInfrontOfMe( 10.0, X, Y, Z );
	   		return IsPlayerInRangeOfPoint( i, 10.0, X, Y, Z );
	   	}

	}
	return 0;
}

stock GetXYInfrontOfMe( Float:distance, &Float: x, &Float: y, &Float: z )
{
    static
   		Float: angle;

    GetMyPos( x, y, z );
    GetMyFacingAngle( angle );
    x += ( distance * floatsin( -angle, degrees ) );
    y += ( distance * floatcos( -angle, degrees ) );
}
