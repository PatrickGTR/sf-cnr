/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: cnr/features/animation.pwn
 * Purpose: all animation and/or action commands
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnPlayerConnect( playerid )
{
	PreloadAnimationLibrary( playerid, "MISC" );
	return 1;
}

hook OnPlayerSpawn( playerid )
{
	if ( justConnected{ playerid } == true )
	{
	    justConnected{ playerid } = false;
	    StopAudioStreamForPlayer( playerid );

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
	}

	return Y_HOOKS_CONTINUE_RETURN_1;
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

/* ** Functions ** */
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

stock PreloadAnimationLibrary( playerid, animlib[ ] )
	return ApplyAnimation( playerid, animlib, "null", 0.0, 0, 0, 0, 0, 0 );

/* ** Commands ** */
CMD:anims( playerid, params[ ] ) return cmd_animlist( playerid, params );
CMD:animlist( playerid, params[ ] )
{
	SendClientMessage( playerid, COLOR_GOLD, ".: Animation List :." );
	SendClientMessage( playerid, -1, "/dance, /piss, /wank, /sit, /groundsit, /lay, /deal, /laugh, /gangsign" );
	SendClientMessage( playerid, -1, "/slapass, /sex, /crossarms, /wave, /lookout, /strip, /aimthreat, /kiss" );
	SendClientMessage( playerid, -1, "/chat, /fuckoff, /shout, /chant, /handsup, /cower, /sleep, /lean, /fiddle" );
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