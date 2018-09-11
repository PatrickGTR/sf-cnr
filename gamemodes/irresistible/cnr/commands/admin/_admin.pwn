/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr/commands/admin/_admin.pwn
 * Purpose: encloses all admin related commands
 */

/* ** Definitions ** */
#define ADMIN_COMMAND_REJECT        "You don't have an appropriate administration level to use this command."
#define ADMIN_COMMAND_TIME          4

/* ** Commands ** */
CMD:acommands( playerid, params[ ] ) return cmd_acmds( playerid, params );
CMD:acmds( playerid, params[ ] )
{
	if ( p_AdminLevel[ playerid ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
    SendClientMessage( playerid, COLOR_GREY, "|______________________________________| Admin Commands |_____________________________________|" );
    SendClientMessage( playerid, COLOR_WHITE, " " );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 1: /goto, /spec(off), /(un)jail, /asay, /slap, /a, /getstats, /stpfr, /setskin, /frules, /fpc, /ticketlog" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 1: /pinfo, /warn, /aspawn, /ans, /stpfa, /alog, /(un)freeze, /aod, /respawnalluv, /reports, /questions" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 1: /respond, /mutelist, /aka, /arepair, /viewdeathmsg" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 2: /kick, /vdestroy, /(un)mute, /explode, /vrespawn, /arenas, /suspend, /viewnotes, /slay" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 3: /ban, /bring, /clearchat, /(ann)ounce, /giveweapon, /vadminpark, /vcreate, /healall, /getip, /smlog, /iclog" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 3: /vadminstats, /pingimmune, /vbring, /countdown, /forcecoptutorial, /vgoto, /copwarn, /armywarn, /resetwep" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 3: /venter, /geolocate" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 4: /circleall, /giveweaponall, /resetwepall, /motd, /uncopban, /unarmyban, /setworld, /destroyallav, /gotopos" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 4: /addnote, /removenote" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 5: /createhouse, /destroyhouse, /respawnallv, /achangename, /toggleviewpm, /unban(ip)" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 5: /createcar, /destroycar, /stripcarmods, /createbribe, /destroybribe, /doublexp, /(h/v)adminsell" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 5: /autovehrespawn, /megaban, /acunban, /creategate, /editgate, /connectsong, /discordurl" );
    SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 5: /creategarage, /destroygarage, /check, /reconnectchuff" );

    if ( p_AdminLevel[ playerid ] > 5 ) {
		SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 6: /setirc, /seteventhost, /setlevel, /setleveloffline, /svrstats, /playaction, /playanimation" );
		SendClientMessage( playerid, COLOR_WHITE, "    LEVEL 6: /updaterules, /truncate, /broadcast, /setgangleader, /viewgangtalk, /createentrance, /destroyentrance" );
    }

    SendClientMessage( playerid, COLOR_GREY, "|_____________________________________________________________________________________________|" );
	return 1;
}

/* ** Modules ** */
#include "irresistible\cnr\commands\admin\admin_one.pwn"
#include "irresistible\cnr\commands\admin\admin_two.pwn"

