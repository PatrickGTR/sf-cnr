/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc, Stev
 * Module: cnr/features/animation.pwn
 * Purpose: all animation and/or action commands
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define PreloadAnimationLibrary(%0,%1) \
	ApplyAnimation( %0, %1, "null", 0.0, 0, 0, 0, 0, 0 )

/* ** Variables ** */
static stock
	Text:  g_AnimationTD            = Text: INVALID_TEXT_DRAW,
	bool: p_InAnimation        		[ MAX_PLAYERS char ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	g_AnimationTD = TextDrawCreate( 220.000000, 141.000000, "PRESS ~r~~h~~k~~PED_SPRINT~~W~ TO STOP THE ANIMATION" );
	TextDrawBackgroundColor( g_AnimationTD, 80 );
	TextDrawFont( g_AnimationTD, 3 );
	TextDrawLetterSize( g_AnimationTD, 0.310000, 1.200000 );
	TextDrawColor( g_AnimationTD, -1 );
	TextDrawSetOutline( g_AnimationTD, 1 );
	TextDrawSetProportional( g_AnimationTD, 1 );
	TextDrawUseBox( g_AnimationTD, 1 );
	TextDrawBoxColor( g_AnimationTD, 117 );
	TextDrawTextSize( g_AnimationTD, 418.000000, 0.000000 );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	if ( p_InAnimation{ playerid } == true ) {
		TextDrawHideForPlayer( playerid, g_AnimationTD );
		p_InAnimation{ playerid } = false;
	}
	return 1;
}

hook OnPlayerMovieMode( playerid, bool: toggled )
{
	if ( ! toggled && IsPlayerUsingAnimation( playerid ) ) {
		TextDrawShowForPlayer( playerid, g_AnimationTD );
	} else {
		TextDrawHideForPlayer( playerid, g_AnimationTD );
	}
	return 1;
}

hook OnPlayerFirstSpawn( playerid )
{
	// Just as good as hooking
	p_InAnimation{ playerid } = false;

    // Preload all animations
    PreloadAnimationLibrary( playerid, "DANCING" );
    PreloadAnimationLibrary( playerid, "PED" );
    PreloadAnimationLibrary( playerid, "PAULNMAC" );
    PreloadAnimationLibrary( playerid, "INT_OFFICE" );
    PreloadAnimationLibrary( playerid, "BEACH" );
    PreloadAnimationLibrary( playerid, "SWEET" );
    PreloadAnimationLibrary( playerid, "SNM" );
    PreloadAnimationLibrary( playerid, "COP_AMBIENT" );
    PreloadAnimationLibrary( playerid, "ON_LOOKERS" );
    PreloadAnimationLibrary( playerid, "SHOP" );
    PreloadAnimationLibrary( playerid, "RAPPING" );
    PreloadAnimationLibrary( playerid, "DEALER" );
    PreloadAnimationLibrary( playerid, "STRIP" );
    PreloadAnimationLibrary( playerid, "RIOT" );
    PreloadAnimationLibrary( playerid, "BLOWJOBZ" );
    PreloadAnimationLibrary( playerid, "CRACK" );
    PreloadAnimationLibrary( playerid, "GYMNASIUM" );
    PreloadAnimationLibrary( playerid, "ROB_BANK" );
    PreloadAnimationLibrary( playerid, "BOMBER" );
    PreloadAnimationLibrary( playerid, "CARRY" );
    PreloadAnimationLibrary( playerid, "VENDING" );
    PreloadAnimationLibrary( playerid, "CASINO" );
    PreloadAnimationLibrary( playerid, "GANGS" );
    PreloadAnimationLibrary( playerid, "INT_HOUSE" );
	PreloadAnimationLibrary( playerid, "MISC" );
	PreloadAnimationLibrary( playerid, "POOL" );
	PreloadAnimationLibrary( playerid, "SMOKING" );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_SPRINT ) )
	{
		if ( p_InAnimation{ playerid } == true )
		{
			if ( IsPlayerTied( playerid ) || IsPlayerCuffed( playerid ) || IsPlayerTazed( playerid ) )
				return SendError( playerid, "You cannot stop your animation at the moment." );

			TextDrawHideForPlayer( playerid, g_AnimationTD );
		    p_InAnimation{ playerid } = false;
		    ClearAnimations( playerid );
		    SetPlayerSpecialAction( playerid, 0 );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:anims( playerid, params[ ] ) return cmd_animlist( playerid, params );
CMD:animlist( playerid, params[ ] )
{
	SendClientMessage( playerid, COLOR_GOLD, ".: Animation List :." );
	SendClientMessage( playerid, -1, "/dance, /piss, /wank, /sit, /groundsit, /lay, /deal, /laugh, /gangsign" );
	SendClientMessage( playerid, -1, "/slapass, /sex, /crossarms, /wave, /lookout, /strip, /aimthreat, /kiss" );
	SendClientMessage( playerid, -1, "/chat, /fuckoff, /shout, /chant, /handsup, /cower, /sleep, /lean, /fiddle" );
	SendClientMessage( playerid, -1, "/smoke" );
	return 1;
}

CMD:dance( playerid, params[ ] )
{
	new id;
	if ( sscanf( params, "d", id ) ) return SendUsage( playerid, "/dance [1-11]" );
	else
	{
	    switch( id )
		{
           	case 1: CreateLoopingAnimation(playerid, "DANCING", "dance_loop", 4.0, 1, 0, 0, 0, 0 );
          	case 2: CreateLoopingAnimation(playerid, "DANCING", "DAN_Down_A", 4.0, 1, 0, 0, 0, 0 );
           	case 3: CreateLoopingAnimation(playerid, "DANCING", "DAN_Left_A", 4.0, 1, 0, 0, 0, 0 );
           	case 4: CreateLoopingAnimation(playerid, "DANCING", "DAN_Loop_A", 4.0, 1, 0, 0, 0, 0 );
          	case 5: CreateLoopingAnimation(playerid, "DANCING", "DAN_Right_A", 4.0, 1, 0, 0, 0, 0 );
          	case 6: CreateLoopingAnimation(playerid, "DANCING", "DAN_Up_A", 4.0, 1, 0, 0, 0, 0 );
          	case 7: CreateLoopingAnimation(playerid, "DANCING", "dnce_M_a", 4.0, 1, 0, 0, 0, 0 );
          	case 8: CreateLoopingAnimation(playerid, "DANCING", "dnce_M_b", 4.0, 1, 0, 0, 0, 0 );
          	case 9: CreateLoopingAnimation(playerid, "DANCING", "dnce_M_c", 4.0, 1, 0, 0, 0, 0 );
          	case 10: CreateLoopingAnimation(playerid, "DANCING", "dnce_M_d", 4.0, 1, 0, 0, 0, 0 );
           	case 11: CreateLoopingAnimation(playerid, "DANCING", "dnce_M_e", 4.0, 1, 0, 0, 0, 0 );
         	default: SendError( playerid, "Invalid Dance ID." );
      	}
	}
	return 1;
}

CMD:piss( playerid, params[ ] )
{
    CreateLoopingAnimation( playerid, "PED", "null", 4.0, 1, 0, 0, 0, 0, 68 ); // Sit
	return 1;
}

CMD:wank( playerid, params[ ] )
{
    CreateLoopingAnimation( playerid, "PAULNMAC", "wank_loop", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:sit( playerid, params[ ] )
{
    CreateLoopingAnimation( playerid, "INT_OFFICE", "OFF_Sit_Type_Loop", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:groundsit( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "BEACH", "ParkSit_M_loop", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:lay( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "BEACH", "bather", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:slapass( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "SWEET", "sweet_ass_slap", 4.0, 0, 0, 0, 0, 0 );
	return 1;
}

CMD:sex( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "SNM", "SPANKING_IDLEW", 4.0, 0, 0, 0, 0, 0 );
	return 1;
}

CMD:crossarms( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "COP_AMBIENT", "Coplook_loop", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:wave( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "ON_LOOKERS", "wave_loop", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:lookout( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "SHOP", "ROB_Shifty", 4.0, 0, 0, 0, 0, 0 );
	return 1;
}

CMD:laugh( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "RAPPING", "Laugh_01", 4.0, 0, 0, 0, 0, 0 );
	return 1;
}

CMD:deal( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "DEALER", "DEALER_IDLE", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:strip( playerid, params[ ] )
{
	new id;
	if ( sscanf( params, "d", id ) ) return SendUsage( playerid, "/strip [1-7]" );
	else
	{
	    switch( id )
		{
           	case 1: CreateLoopingAnimation(playerid, "STRIP", "strip_A", 4.0, 1, 0, 0, 0, 0 );
           	case 2: CreateLoopingAnimation(playerid, "STRIP", "strip_B", 4.0, 1, 0, 0, 0, 0 );
           	case 3: CreateLoopingAnimation(playerid, "STRIP", "strip_C", 4.0, 1, 0, 0, 0, 0 );
           	case 4: CreateLoopingAnimation(playerid, "STRIP", "strip_D", 4.0, 1, 0, 0, 0, 0 );
           	case 5: CreateLoopingAnimation(playerid, "STRIP", "strip_E", 4.0, 1, 0, 0, 0, 0 );
           	case 6: CreateLoopingAnimation(playerid, "STRIP", "strip_F", 4.0, 1, 0, 0, 0, 0 );
           	case 7: CreateLoopingAnimation(playerid, "STRIP", "strip_G", 4.0, 1, 0, 0, 0, 0 );
         	default: SendError( playerid, "Invalid Strip ID." );
      	}
	}
	return 1;
}

CMD:aimthreat( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "SHOP", "ROB_Loop_Threat", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:chat( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "PED", "IDLE_CHAT", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:fuckoff( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "PED", "fucku", 4.0, 0, 0, 0, 0, 0 );
	return 1;
}

CMD:shout( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "RIOT", "RIOT_shout", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:chant( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "RIOT", "RIOT_CHANT", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:handsup( playerid, params[ ] )
{
    CreateLoopingAnimation( playerid, "PED", "null", 4.0, 1, 0, 0, 0, 0, SPECIAL_ACTION_HANDSUP );
	return 1;
}

CMD:smoke( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "SMOKING", "M_smk_in", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:cower( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "PED", "COWER", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:kiss( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "KISSING", "Playa_Kiss_02", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:gangsign( playerid, params[ ] )
{
	new id;
	if ( sscanf( params, "d", id ) ) return SendUsage( playerid, "/gangsign [1-7]" );
	else
	{
	    switch( id )
		{
           	case 1: CreateLoopingAnimation(playerid, "GHANDS", "gsign1", 4.0, 1, 0, 0, 0, 0 );
           	case 2: CreateLoopingAnimation(playerid, "GHANDS", "gsign1LH", 4.0, 1, 0, 0, 0, 0 );
           	case 3: CreateLoopingAnimation(playerid, "GHANDS", "gsign2", 4.0, 1, 0, 0, 0, 0 );
           	case 4: CreateLoopingAnimation(playerid, "GHANDS", "gsign2LH", 4.0, 1, 0, 0, 0, 0 );
           	case 5: CreateLoopingAnimation(playerid, "GHANDS", "gsign3", 4.0, 1, 0, 0, 0, 0 );
           	case 6: CreateLoopingAnimation(playerid, "GHANDS", "gsign3LH", 4.0, 1, 0, 0, 0, 0 );
           	case 7: CreateLoopingAnimation(playerid, "GHANDS", "gsign4", 4.0, 1, 0, 0, 0, 0 );
         	default: SendError( playerid, "Invalid Gang Sign ID." );
      	}
	}
	return 1;
}

CMD:lean( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "GANGS", "leanIDLE", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:sleep( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "CRACK", "crckidle2", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

CMD:fiddle( playerid, params[ ] )
{
	CreateLoopingAnimation( playerid, "INT_HOUSE", "wash_up", 4.0, 1, 0, 0, 0, 0 );
	return 1;
}

/* ** Functions ** */
stock CreateLoopingAnimation( playerid, animlib[ ], animname[ ], Float:Speed, looping, lockx, locky, lockz, lp, specialaction=0 )
{
	if ( !IsPlayerConnected( playerid ) ) return 0;
//	else if ( p_InAnimation{ playerid } ) return SendError( playerid, "You cannot use this command since you're playing an animation." );
	else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command inside a vehicle." );
	else if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "You cannot use this command since you're not spawned." );
//	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this command since you're jailed." );
	else if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "You cannot use this command since you're tazed." );
	//else if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
	else if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "You cannot use this command since you're cuffed." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "You cannot use this command since you're tied." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "You cannot use this command since you're kidnapped." );
	else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "You cannot use this command since you're getting blowed." );
	else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "You cannot use this command since you're giving oral sex." );
	else if ( IsPlayerPlayingPoker( playerid ) ) return SendError( playerid, "You cannot use this command since you're playing poker." );
	else if ( IsPlayerPlayingPool( playerid ) ) return SendError( playerid, "You cannot use this command since you're playing pool." );
	else if ( IsPlayerInWater( playerid ) ) return SendError( playerid, "You cannot use this command since you're in water." );
	else if ( IsPlayerMining( playerid ) ) return SendError( playerid, "You cannot use this command since you're mining." );
	else if ( IsPlayerBoxing( playerid ) ) return SendError( playerid, "You cannot use this command since you're boxing." );
	else if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
    else if ( GetPlayerAnimationIndex( playerid ) == 1660 ) return SendError( playerid, "You cannot use this command since you're using a vending machine." );
	else if ( IsPlayerAttachedObjectSlotUsed( playerid, 0 ) ) return SendError( playerid, "You cannot use this command since you're robbing." );
	else if ( IsPlayingAnimation( playerid, "ROB_BANK", "CAT_Safe_Rob" ) ) return SendError( playerid, "You cannot use this command since you're robbing." );
	else if ( IsPlayingAnimation( playerid, "GANGS", "smkcig_prtl" ) ) return SendError( playerid, "You cannot use this command since you're smoking." );
	else if ( IsPlayerAttachedObjectSlotUsed( playerid, 3 ) ) return SendError( playerid, "You cannot use this command since you're holding a stolen good." );
	else if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER || GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_PASSENGER ) return SendError( playerid, "You cannot use this command since you're entering a vehicle." );
    else if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE ) return SendError( playerid, "You cannot use this command since you're exiting a vehicle." );
	else
	{
		SetPlayerSpecialAction( playerid, 0 );
	    if ( specialaction == 0 ) {
			ApplyAnimation( playerid, animlib, "null", 0.0, 0, 0, 0, 0, 0 );
		    ApplyAnimation( playerid, animlib, animname, Speed, looping, lockx, locky, lockz, lp );
		} else {
            SetPlayerSpecialAction( playerid, specialaction );
		}

		if ( looping ) // Animations that must be played once.
		{
	    	p_InAnimation{ playerid } = true;
			if ( !p_inMovieMode{ playerid } ) TextDrawShowForPlayer( playerid, g_AnimationTD );
		}
	}
	return 1;
}

stock IsPlayingAnimation( playerid, library[ ], animation[ ] )
{
	if ( IsPlayerConnected( playerid ) )
	{
	    static
	    	animlib[ 32 ], animname[ 32 ];

	    GetAnimationName( GetPlayerAnimationIndex( playerid ), animlib, 32, animname, 32 );
	    return strmatch( library, animlib ) && strmatch( animation, animname );
	}
	return 0;
}

stock IsPlayerUsingAnimation( playerid ) {
	return p_InAnimation{ playerid };
}
