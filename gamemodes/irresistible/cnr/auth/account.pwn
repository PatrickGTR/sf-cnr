/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\auth\account.pwn
 * Purpose: module associated with account components (login, register)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
new
    bool: p_PlayerLogged    		[ MAX_PLAYERS char ],
    p_AccountID						[ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnPlayerPassedBanCheck( playerid )
{
	// Pursue a registration check
	mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "SELECT `NAME` FROM `USERS` WHERE `NAME` = '%e' LIMIT 0,1", ReturnPlayerName( playerid ) );
 	mysql_tquery( dbHandle, szNormalString, "OnPlayerRegisterCheck", "i", playerid );
    return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
    SavePlayerData( playerid, true );
    return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    static
        szBigQuery[ 764 ];

    if ( dialogid == DIALOG_LOGIN )
    {
        if ( response )
        {
        	if ( p_PlayerLogged{ playerid } )
        	{
        		AdvancedBan( playerid, "Server", "Exploiting", ReturnPlayerIP( playerid ) );
        		return SendError( playerid, "You are already logged in!" );
        	}

			format( szBigQuery, sizeof( szBigQuery ), "SELECT * FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( ReturnPlayerName( playerid ) ) );
       		mysql_function_query( dbHandle, szBigQuery, true, "OnAttemptPlayerLogin", "ds", playerid, inputtext );
        }
        else return ShowPlayerDialog( playerid, DIALOG_LOGIN_QUIT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Account - Authentication", "{FFFFFF}Are you sure you want to leave the server?", "Yes", "No" );
    }
    else if ( dialogid == DIALOG_LOGIN_QUIT ) {
    	if ( response ) {
    		return Kick( playerid );
    	} else {
	        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ) );
	        return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{FFFFFF}Account - Authentication", szBigString, "Login", "Leave");
    	}
    }
    else if ( dialogid == DIALOG_REGISTER )
    {
        if ( response )
        {
        	if ( p_PlayerLogged{ playerid } )
        		return SendError( playerid, "You are already logged in!" );

            if ( strlen( inputtext ) > 24 || strlen( inputtext ) < 3 )
            {
            	format( szBigQuery, 300, "{FFFFFF}Welcome, this account ("COL_RED"%s"COL_WHITE") is not registered.\nPlease enter your desired password for this account.\n\n"COL_RED"Your password length must vary from 3 to 24 characters.\n\n"COL_GREY"Once you are registered, do not share your password with anyone besides yourself!", ReturnPlayerName( playerid ) );
				ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Account - Register", szBigQuery, "Register", "Leave");
            }
            else
            {
                static
                	szHashed[ 129 ],
                	szSalt[ 25 ],
                	szIP[ 16 ]
                ;

             	randomString( szSalt, 24 );
             	pencrypt( szHashed, sizeof( szHashed ), inputtext, szSalt );
				GetPlayerIp( playerid, szIP, sizeof( szIP ) );

				format( szBigQuery, sizeof( szBigQuery ), "INSERT INTO `USERS` (`NAME`,`PASSWORD`,`SALT`,`IP`,`SCORE`,`CASH`,`ADMINLEVEL`,`BANKMONEY`,`OWNEDHOUSES`,`KILLS`,`DEATHS`,`VIP_PACKAGE`,`OWNEDCARS`,`LASTLOGGED`,`VIP_EXPIRE`,`LAST_SKIN`,`COP_BAN`,`UPTIME`,`ARRESTS`,`FIGHTSTYLE`,`VIPWEP1`,`VIPWEP2`,`VIPWEP3`,`MUTE_TIME`,`WANTEDLVL`,`ROBBERIES`,`PING_IMMUNE`,`FIRES`,`CONTRACTS`,`COP_TUTORIAL`,`JOB`,`LAST_IP`,`ONLINE`) " );
				format( szBigQuery, sizeof( szBigQuery ), "%s VALUES('%s','%s','%s','%s',0,0,0,0,0,1,1,0,0,%d,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,'%s',1)", szBigQuery, mysql_escape( ReturnPlayerName( playerid ) ), szHashed, mysql_escape( szSalt ), mysql_escape( szIP ), g_iTime, mysql_escape( szIP ) );
       			mysql_function_query( dbHandle, szBigQuery, true, "Account_SetAccountID", "d", playerid );

                CallLocalFunction( "OnPlayerRegister", "d", playerid );

				p_JobSet{ playerid } = false;
				//p_CitySet{ playerid } = false;
				p_SpawningCity{ playerid } = CITY_SF;

				p_Uptime[ playerid ] = 0;
				ShowAchievement( playerid, "Registering to SF-CnR!", 1 );
                p_PlayerLogged{ playerid } = true;
                SetPlayerCash( playerid, 0 );
                SetPlayerScore( playerid, 0 );
				p_Kills[ playerid ] = 1;
				p_Deaths[ playerid ] = 1;
				//p_XP[ playerid ] = 0;
				//p_CopTutorial{ playerid } = 0;
				p_OwnedHouses[ playerid ] = 0;
				p_OwnedBusinesses[ playerid ] = 0;
				p_OwnedVehicles[ playerid ] = 0;
				p_Burglaries[ playerid ] = 0;
				ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}Account Email", ""COL_WHITE"Would you like to assign an email to your account for security?\n\nWe'll keep you also informed on in-game and community associated events!", "Confirm", "Cancel" );
                SendServerMessage( playerid, "You have "COL_GREEN"successfully{FFFFFF} registered! You have been automatically logged in!" );
            }
        }
        else return ShowPlayerDialog( playerid, DIALOG_REGISTER_QUIT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Account - Authentication", "{FFFFFF}Are you sure you want to leave the server?", "Yes", "No" );
    }
    else if ( dialogid == DIALOG_REGISTER_QUIT ) {
    	if ( response ) {
    		return Kick( playerid );
    	} else {
	        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_RED"%s"COL_WHITE") is not registered.\nPlease enter your desired password for this account.\n\n"COL_GREY"Once you are registered, do not share your password with anyone besides yourself!", ReturnPlayerName( playerid ) );
	        return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Account - Register", szBigString, "Register", "Leave");
    	}
    }
    return 1;
}

/* ** SQL Threads ** */
thread OnPlayerRegisterCheck( playerid )
{
	if ( GetPVarInt( playerid, "banned_connection" ) == 1 ) return 1; // Stop anything from happening.

	new
	    rows, fields
	;
    cache_get_data( rows, fields );
	if ( rows )
    {
        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ) );
        ShowPlayerDialog( playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{FFFFFF}Account - Authentication", szBigString, "Login", "Leave" );
    }
    else
    {
		mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "SELECT `IP` FROM `USERS` WHERE `IP` = '%e' LIMIT 5", ReturnPlayerIP( playerid ) );
 		mysql_tquery( dbHandle, szNormalString, "OnPlayerDuplicateAccountCheck", "i", playerid );
    }
	return 1;
}

thread OnPlayerDuplicateAccountCheck( playerid )
{
	new
		rows, fields;

	cache_get_data( rows, fields );

	if ( rows > 10 )
	{
		SendError( playerid, "Sorry, this IP has more than 10 users registered to it which is the maximum limit of users per IP." );
		KickPlayerTimed( playerid );
	}
	else
	{
        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_RED"%s"COL_WHITE") is not registered.\nPlease enter your desired password for this account.\n\n"COL_GREY"Once you are registered, do not share your password with anyone besides yourself!", ReturnPlayerName( playerid ) );
        ShowPlayerDialog( playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "{FFFFFF}Account - Register", szBigString, "Register", "Leave" );
	}
	return 1;
}

thread OnAttemptPlayerLogin( playerid, password[ ] )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szHashed[ 129 ],
    		szPassword[ 129 ],
    		szSalt[ 25 ],
    		bool: isSalted = false
    	;

		cache_get_field_content( 0,  "SALT", szSalt );
		cache_get_field_content( 0,  "PASSWORD", szPassword );

		if ( !strcmp( szSalt, "NULL", false ) ) // User doesn't have a salt
		{
			WP_Hash( szHashed, sizeof( szHashed ), password );
			isSalted = false;
		}
		else
		{
			pencrypt( szHashed, sizeof( szHashed ), password, szSalt );
			isSalted = true;
		}

		if ( ! strcmp( szHashed, szPassword, false ) )
    	{
    		if ( !isSalted ) // Converting from insecure to secure
    		{
             	randomString( szSalt, 24 );
             	pencrypt( szHashed, sizeof( szHashed ), password, szSalt );

    			format( szBigString, sizeof( szBigString ), "UPDATE USERS SET `PASSWORD`='%s', `SALT`='%s' WHERE `NAME`='%s'", szHashed, mysql_escape( szSalt ), ReturnPlayerName( playerid ) );
    			mysql_single_query( szBigString );
    		}

    		p_AccountID[ playerid ] = cache_get_field_content_int( 0, "ID", dbHandle );

			new iScore 		= cache_get_field_content_int( 0, "SCORE", dbHandle );
			new iCash 		= cache_get_field_content_int( 0, "CASH", dbHandle );
			new iFightStyle = cache_get_field_content_int( 0, "FIGHTSTYLE", dbHandle );
			new iWanted 	= cache_get_field_content_int( 0, "WANTEDLVL", dbHandle );

			SetPlayerCash			( playerid, iCash );
			SetPlayerScore			( playerid, iScore );
			SetPlayerFightingStyle	( playerid, iFightStyle );

			if ( iWanted ) {
				SetPlayerWantedLevel( playerid, iWanted );
				SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[RESUME]{FFFFFF} Your wanted level has been set to %d as you are resuming your life.", GetPlayerWantedLevel( playerid ) );
			}

			p_AdminLevel[ playerid ] 		= cache_get_field_content_int( 0, "ADMINLEVEL", dbHandle );
			SetPlayerBankMoney( playerid, cache_get_field_content_int( 0, "BANKMONEY", dbHandle ) );
			p_Kills[ playerid ] 			= cache_get_field_content_int( 0, "KILLS", dbHandle );
			p_Deaths[ playerid ] 			= cache_get_field_content_int( 0, "DEATHS", dbHandle );
			p_VIPLevel[ playerid ] 			= cache_get_field_content_int( 0, "VIP_PACKAGE", dbHandle );
			//p_XP[ playerid ] 				= cache_get_field_content_int( 0, "XP", dbHandle );
			p_VIPExpiretime[ playerid ] 	= cache_get_field_content_int( 0, "VIP_EXPIRE", dbHandle );
			p_LastSkin[ playerid ] 			= cache_get_field_content_int( 0, "LAST_SKIN", dbHandle );
			p_Burglaries[ playerid ] 		= cache_get_field_content_int( 0, "BURGLARIES", dbHandle );
			p_CopBanned{ playerid } 		= cache_get_field_content_int( 0, "COP_BAN", dbHandle );
			p_ArmyBanned{ playerid } 		= cache_get_field_content_int( 0, "ARMY_BAN", dbHandle );
			p_Uptime[ playerid ] 			= cache_get_field_content_int( 0, "UPTIME", dbHandle );
			p_Arrests[ playerid ] 			= cache_get_field_content_int( 0, "ARRESTS", dbHandle );
			p_VIPWep1{ playerid } 			= cache_get_field_content_int( 0, "VIPWEP1", dbHandle );
			p_VIPWep2{ playerid } 			= cache_get_field_content_int( 0, "VIPWEP2", dbHandle );
			p_VIPWep3{ playerid } 			= cache_get_field_content_int( 0, "VIPWEP3", dbHandle );
			p_MutedTime[ playerid ] 		= cache_get_field_content_int( 0, "MUTE_TIME", dbHandle );
			p_Robberies[ playerid ] 		= cache_get_field_content_int( 0, "ROBBERIES", dbHandle );
			p_Fires[ playerid ] 			= cache_get_field_content_int( 0, "FIRES", dbHandle );
			p_PingImmunity{ playerid } 		= cache_get_field_content_int( 0, "PING_IMMUNE", dbHandle );
			p_HitsComplete[ playerid ] 		= cache_get_field_content_int( 0, "CONTRACTS", dbHandle );
			p_TruckedCargo[ playerid ] 		= cache_get_field_content_int( 0, "TRUCKED", dbHandle );
			p_PilotMissions[ playerid ] 	= cache_get_field_content_int( 0, "PILOT", dbHandle );
			//p_TrainMissions[ playerid ] 	= cache_get_field_content_int( 0, "TRAIN", dbHandle );
			//p_CopTutorial{ playerid } 		= cache_get_field_content_int( 0, "COP_TUTORIAL", dbHandle );
			p_Job{ playerid } 				= cache_get_field_content_int( 0, "JOB", dbHandle );
			p_VIPJob{ playerid } 			= cache_get_field_content_int( 0, "VIP_JOB", dbHandle );
			p_AdminJailed{ playerid } 		= cache_get_field_content_int( 0, "JAIL_ADMIN", dbHandle );
			p_JailTime[ playerid ] 			= cache_get_field_content_int( 0, "JAIL_TIME", dbHandle );
			p_Ropes[ playerid ] 			= cache_get_field_content_int( 0, "ROPES", dbHandle );
			p_MetalMelter[ playerid ] 		= cache_get_field_content_int( 0, "MELTERS", dbHandle );
			p_Scissors[ playerid ] 			= cache_get_field_content_int( 0, "SCISSORS", dbHandle );
			p_AntiEMP[ playerid ] 			= cache_get_field_content_int( 0, "FOILS", dbHandle );
			p_BobbyPins[ playerid ] 		= cache_get_field_content_int( 0, "PINS", dbHandle );
			p_ContractedAmount[ playerid ] 	= cache_get_field_content_int( 0, "BOUNTY", dbHandle );
			p_WeedGrams[ playerid ] 		= cache_get_field_content_int( 0, "WEED", dbHandle );
			p_SpawningCity{ playerid } 		= cache_get_field_content_int( 0, "CITY", dbHandle );
			SetPlayerMeth( playerid, cache_get_field_content_int( 0, "METH", dbHandle ) );
			SetPlayerCausticSoda( playerid, cache_get_field_content_int( 0, "SODA", dbHandle ) );
			SetPlayerMuriaticAcid( playerid, cache_get_field_content_int( 0, "ACID", dbHandle ) );
			SetPlayerHydrogenChloride( playerid, cache_get_field_content_int( 0, "GAS", dbHandle ) );
			p_LeftCuffed{ playerid } 		= !!cache_get_field_content_int( 0, "IS_CUFFED", dbHandle );
			p_JailsBlown[ playerid ] 		= cache_get_field_content_int( 0, "BLEW_JAILS", dbHandle );
			p_BankBlown[ playerid ] 		= cache_get_field_content_int( 0, "BLEW_VAULT", dbHandle );
			p_CarsJacked[ playerid ] 		= cache_get_field_content_int( 0, "VEHICLES_JACKED", dbHandle );
			p_MethYielded[ playerid ] 		= cache_get_field_content_int( 0, "METH_YIELDED", dbHandle );
			SetPlayerDrillStrength( playerid, cache_get_field_content_int( 0, "DRILL", dbHandle ) );
			SetPlayerIrresistibleCoins( playerid, cache_get_field_content_float( 0, "COINS", dbHandle ) );
			SetPlayerExtraSlots( playerid, cache_get_field_content_int( 0, "EXTRA_SLOTS", dbHandle ) );
			p_forcedAnticheat[ playerid ] 	= cache_get_field_content_int( 0, "FORCE_AC", dbHandle );
			SetPlayerCasinoRewardsPoints( playerid, cache_get_field_content_float( 0, "CASINO_REWARDS", dbHandle ) );
			SetPlayerCasinoHighroller( playerid, !!cache_get_field_content_int( 0, "VISAGE_HIGHROLLER", dbHandle ) );
			p_Fireworks[ playerid ] = cache_get_field_content_int( 0, "FIREWORKS", dbHandle );
			p_ExplosiveBullets[ playerid ] = cache_get_field_content_int( 0, "EXPLOSIVE_BULLETS", dbHandle );
			p_AddedEmail{ playerid } = !!cache_get_field_content_int( 0, "USED_EMAIL", dbHandle );
			// p_TaxTime[ playerid ] = cache_get_field_content_int( 0, "TAX_TIME", dbHandle );

			SetPlayerC4Amount( playerid, cache_get_field_content_int( 0, "C4", dbHandle ) );
			SetPlayerSeasonalXP( playerid, cache_get_field_content_float( 0, "RANK", dbHandle ) );
            SetPlayerFindOrCreateGang( playerid, cache_get_field_content_int( 0, "GANG_ID", dbHandle ) );

			// spawn location
			new
				spawn_location[ 10 ];

			cache_get_field_content( 0, "SPAWN", spawn_location, dbHandle, sizeof( spawn_location ) );

			if ( ismysqlnull( spawn_location ) || sscanf( spawn_location, "s[4]d", p_SpawningKey[ playerid ], p_SpawningIndex[ playerid ] ) ) {
				p_SpawningKey[ playerid ] [ 0 ] = '\0', p_SpawningIndex[ playerid ] = 0;
			}

			// anti-cheat
			if ( p_forcedAnticheat[ playerid ] > 0 && ! IsPlayerUsingSampAC( playerid ) ) {
				SendError( playerid, "You must install an anticheat to play the server. Visit "COL_GREY""AC_WEBSITE""COL_WHITE" to install the anticheat." );
				KickPlayerTimed( playerid );
				return 1;
			}

			// Load some other variables too
		   	p_OwnedHouses 		[ playerid ] = GetPlayerOwnedHouses( playerid );
		   	p_OwnedBusinesses 	[ playerid ] = GetPlayerOwnedBusinesses( playerid );

		    p_PlayerLogged	{ playerid } = true;
			p_JobSet 		{ playerid } = true;
			// p_CitySet 	{ playerid } = true;
			p_Muted 		{ playerid } = p_MutedTime[ playerid ] > 0 ? true : false; // Save muting :X

			// Load other player related variables
			CallLocalFunction( "OnPlayerLogin", "d", playerid );

			// Player is online
			mysql_single_query( sprintf( "UPDATE `USERS` SET `ONLINE`=1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );

			// Log in player
		  	SendServerMessage( playerid, "You have " COL_GREEN "successfully" COL_WHITE " logged in!" );
		}
	    else
	    {
	        p_IncorrectLogins{ playerid } ++;
	        format( szBigString, sizeof( szBigString ), "{FFFFFF}Welcome, this account ("COL_GREEN"%s"COL_WHITE") is registered.\nPlease enter the password to login.\n\n"COL_RED"Wrong password! Try again! [%d/3]\n\n"COL_GREY"If you are not the owner of this account, leave and rejoin with a different nickname.", ReturnPlayerName( playerid ), p_IncorrectLogins{ playerid } );
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{FFFFFF}Account - Login", szBigString, "Login", "Leave");
			if ( p_IncorrectLogins{ playerid } >= 3 ) {
			    p_IncorrectLogins{ playerid } = 0;
				SendServerMessage( playerid, "You have been kicked for too many incorrect login attempts." );
				KickPlayerTimed( playerid );
			}
	    }
    }
    else
    {
    	Kick( playerid );
    	printf( "User::Error - User Not Created Attempting Login" );
    }
	return 1;
}

thread Account_SetAccountID( playerid )
{
	p_AccountID[ playerid ]	= cache_insert_id( );
	return 1;
}

/* ** Functions ** */
stock pencrypt( szLeFinale[ ], iSize = sizeof( szLeFinale ), szPassword[ ], szSalt[ 25 ], iPepper = 24713018, szCost[ 3 ] = "2y" ) // lorenc's hashing algorithm
{
	static
    	szHash[ 256 ];

    WP_Hash( szHash, sizeof( szHash ), szPassword );

    format( szHash, sizeof( szHash ), "%s%d%s$%s$", szSalt, iPepper, szHash, szCost );

    WP_Hash( szLeFinale, iSize, szHash );
}

stock SavePlayerData( playerid, bool: logout = false )
{
    static
		Query[ 950 ];

	if ( IsPlayerNPC( playerid ) )
		return 0;

    if ( p_PlayerLogged{ playerid } )
    {
    	new
    		bool: bQuitToAvoid = false;

		if ( IsPlayerCuffed( playerid ) || IsPlayerTazed( playerid ) || IsPlayerTied( playerid ) || p_LeftCuffed{ playerid } || p_QuitToAvoidTimestamp[ playerid ] > g_iTime )
			bQuitToAvoid = true;

        format( Query, sizeof( Query ), "UPDATE `USERS` SET `SCORE`=%d,`ADMINLEVEL`=%d,`OWNEDHOUSES`=%d,`KILLS`=%d,`DEATHS`=%d,`VIP_PACKAGE`=%d,`OWNEDCARS`=%d,`LASTLOGGED`=%d,`VIP_EXPIRE`=%d,`LAST_SKIN`=%d,`BURGLARIES`=%d,`UPTIME`=%d,`ARRESTS`=%d,`CITY`=%d,`METH`=%d,`SODA`=%d,`ACID`=%d,`GAS`=%d,",
                                       	GetPlayerScore( playerid ), 	p_AdminLevel[ playerid ],
                                    	p_OwnedHouses[ playerid ], 		p_Kills[ playerid ],
										p_Deaths[ playerid ], 			p_VIPLevel[ playerid ],
										p_OwnedVehicles[ playerid ], 	g_iTime, 						p_VIPExpiretime[ playerid ],
										p_LastSkin[ playerid ], 		p_Burglaries[ playerid ], 		p_Uptime[ playerid ],
									 	p_Arrests[ playerid ],			p_SpawningCity{ playerid },		GetPlayerMeth( playerid ),
										GetPlayerCausticSoda( playerid ), GetPlayerMuriaticAcid( playerid ), GetPlayerHydrogenChloride( playerid ) );

		format( Query, sizeof( Query ), "%s`VIPWEP1`=%d,`VIPWEP2`=%d,`VIPWEP3`=%d,`MUTE_TIME`=%d,`WANTEDLVL`=%d,`ROBBERIES`=%d,`PING_IMMUNE`=%d,`FIRES`=%d,`CONTRACTS`=%d,`JOB`=%d,`JAIL_TIME`=%d,`ROPES`=%d,`MELTERS`=%d,`SCISSORS`=%d,`FOILS`=%d,`PINS`=%d,`BOUNTY`=%d,`WEED`=%d,`IS_CUFFED`=%d,`DRILL`=%d,",
										Query,                          p_VIPWep1{ playerid },          p_VIPWep2{ playerid },
										p_VIPWep3{ playerid },          p_MutedTime[ playerid ],        p_WantedLevel[ playerid ],
										p_Robberies[ playerid ],        p_PingImmunity{ playerid },     p_Fires[ playerid ],
										p_HitsComplete[ playerid ],     p_Job{ playerid },              p_JailTime[ playerid ],
										p_Ropes[ playerid ],			p_MetalMelter[ playerid ],
										p_Scissors[ playerid ], 		p_AntiEMP[ playerid ], 			p_BobbyPins[ playerid ],
										p_ContractedAmount[ playerid ],	p_WeedGrams[ playerid ],		logout ? ( bQuitToAvoid ? 1 : 0 ) : 0,
										GetPlayerDrillStrength( playerid ) );

		format( Query, sizeof( Query ), "%s`BLEW_JAILS`=%d,`BLEW_VAULT`=%d,`VEHICLES_JACKED`=%d,`METH_YIELDED`=%d,`LAST_IP`='%s',`VIP_JOB`=%d,`TRUCKED`=%d,`EXPLOSIVE_BULLETS`=%d,`ONLINE`=%d,`PILOT`=%d WHERE `ID`=%d",
										Query,
										p_JailsBlown[ playerid ], 		p_BankBlown[ playerid ], 			p_CarsJacked[ playerid ],
										p_MethYielded[ playerid ],		mysql_escape( ReturnPlayerIP( playerid ) ),
										p_VIPJob{ playerid },			p_TruckedCargo[ playerid ],
										p_ExplosiveBullets[ playerid ],
										!logout,
										p_PilotMissions[ playerid ],
										p_AccountID[ playerid ] );

		mysql_single_query( Query );

        if ( logout )
		    p_PlayerLogged{ playerid } = false;
    }
    return 1;
}

stock GetPlayerAccountID( playerid ) return p_AccountID[ playerid ];

stock IsPlayerLoggedIn( playerid ) return p_PlayerLogged{ playerid };