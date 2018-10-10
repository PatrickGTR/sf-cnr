/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\jobs.pwn
 * Purpose: job/skill related data and helpers
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_JOB_NAME 				( 16 )

#define JOB_RAPIST                  ( 0 )
#define JOB_KIDNAPPER               ( 1 )
#define JOB_TERRORIST               ( 2 )
#define JOB_HITMAN                  ( 3 )
#define JOB_PROSTITUTE          	( 4 )
#define JOB_WEAPON_DEALER           ( 5 )
#define JOB_DRUG_DEALER           	( 6 )
#define JOB_DIRTY_MECHANIC         	( 7 )
#define JOB_BURGLAR              	( 8 )

/* ** Variables ** */

/* ** Hooks ** */

/* ** Functions ** */
stock IsPlayerJob( playerid, jobid ) {
	return ( p_Job{ playerid } == jobid ) || ( p_VIPLevel[ playerid ] >= VIP_GOLD && p_VIPJob{ playerid } == jobid );
}

stock GetJobIDFromName( szJob[ ] )
{
	static const
		g_jobsData[ ] [ MAX_JOB_NAME char ] =
		{
			{ !"Rapist" }, { !"Kidnapper" }, { !"Terrorist" }, { !"Hitman" }, { !"Prostitute" },
			{ !"Weapon Dealer" }, { !"Drug Dealer" }, { !"Dirty Mechanic" }, { !"Burglar" }
		}
	;

	for( new iJob = 0; iJob < sizeof( g_jobsData ); iJob++ )
		if ( strunpack( szNormalString, g_jobsData[ iJob ], MAX_JOB_NAME ) )
			if ( strfind( szNormalString, szJob, true ) != -1 )
				return iJob;

	return 0xFE;
}

stock GetJobName( iJob )
{
	new
		szJob[ MAX_JOB_NAME ] = "unknown";

	switch( iJob )
	{
		case JOB_RAPIST: 			szJob = "Rapist";
		case JOB_KIDNAPPER:			szJob = "Kidnapper";
		case JOB_TERRORIST: 		szJob = "Terrorist";
		case JOB_HITMAN: 			szJob = "Hitman";
		case JOB_PROSTITUTE: 		szJob = "Prostitute";
		case JOB_WEAPON_DEALER: 	szJob = "Weapon Dealer";
		case JOB_DRUG_DEALER: 		szJob = "Drug Dealer";
		case JOB_DIRTY_MECHANIC: 	szJob = "Dirty Mechanic";
		case JOB_BURGLAR: 			szJob = "Burglar";
	}
	return szJob;
}
