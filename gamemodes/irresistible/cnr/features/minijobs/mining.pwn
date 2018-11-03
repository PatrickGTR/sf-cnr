/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\featuyres\minijobs\mining.pwn
 * Purpose: mining minijob for players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_ROCKS 					( 72 )
#define MAX_ORE_STORAGE				( 14 )

/* ** Variables ** */
enum
{
	ORE_BAUXITE,
	ORE_IRON,
	ORE_COAL,
	ORE_GOLD,
	ORE_RUBY,
	ORE_DIAMOND,
	ORE_PLATINUM,
	ORE_EMERALD,
	ORE_SAPHHIRE,
	ORE_AMETHYST,
};

enum E_ROCK_DATA
{
	E_OBJECT,			E_MINING,		Text3D: E_LABEL,
	E_ORES,				E_COLOR,		E_ORE,
	E_MAX_ORES,			E_ARGB
};

static stock
	g_miningData					[ MAX_ROCKS ] [ E_ROCK_DATA ],
	p_MiningOre						[ MAX_PLAYERS char ],
	bool: p_isMining				[ MAX_PLAYERS char ],

	g_orePrices                		[ ] = { 675, 900, 600, 2750, 3000, 3500, 4000, 2200, 2300, 1200 },
	g_oreMiningTime					[ ] = { 2000, 2800, 1600, 6800, 7200, 7600, 8000, 6400, 6560, 4000 },
	g_oreQuanities					[ ] = { 8, 8, 8, 8, 5, 3, 3, 5, 5, 6 },

	// Iterator
	Iterator: miningrock 			< MAX_ROCKS >
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// create shovel pickups
	CreateDynamicPickup( 337, 2, -2744.6367, 1264.8502, 11.77030 ); // Spade @Mining
	CreateDynamicPickup( 337, 2, 589.440800, 869.86900, -42.4973 ); // Spade @Mining
	CreateDynamicPickup( 337, 2, -1998.7056, 1777.7448, 43.73860 ); // Spade @Alcatraz

	// create rocks
	CreateMiningRock( ORE_COAL, 	868, -2751.8393, 1245.06689, 11.4003100, 0.000000, 0.000000, -54.8999 );
	CreateMiningRock( ORE_COAL, 	867, -2746.3259, 1241.43030, 11.1903100, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_COAL, 	867, -2738.7551, 1259.25769, 11.1903100, 0.000000, 0.000000, 147.5000 );
	CreateMiningRock( ORE_COAL, 	868, -2751.0561, 1263.11548, 11.4003100, 0.000000, 0.000000, -115.800 );
	CreateMiningRock( ORE_COAL, 	867, -2758.5654, 1252.22095, 11.1903100, 0.000000, 0.000000, 169.4000 );
	CreateMiningRock( ORE_IRON, 	868, -2745.1460, 1259.26074, 11.1703100, 0.000000, 0.000000, 80.19992 );
	CreateMiningRock( ORE_IRON,		868, -2735.3110, 1245.65906, 11.2103100, 0.000000, 0.000000, -158.099 );
	CreateMiningRock( ORE_IRON,		868, -2736.8037, 1242.34534, 10.8966600, 0.000000, 0.000000, 8.999990 );
	CreateMiningRock( ORE_IRON,		868, -2737.9262, 1245.05554, 11.0432500, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_IRON,		867, -2749.1315, 1260.08789, 11.1903100, 0.000000, 0.000000, -10.6999 );
	CreateMiningRock( ORE_IRON,		868, -2740.4924, 1232.87720, 10.8966600, 0.000000, 0.000000, 14.15999 );
	CreateMiningRock( ORE_GOLD, 	868, -2737.0988, 1235.62610, 11.0432500, 0.000000, 0.000000, 172.3799 );
	CreateMiningRock( ORE_BAUXITE, 	867, -2741.5380, 1236.00732, 11.1903100, 0.000000, 0.000000, 240.8608 );
	CreateMiningRock( ORE_GOLD, 	868, -2744.7741, 1248.38403, 11.4003100, 0.000000, 0.000000, -54.8999 );
	CreateMiningRock( ORE_GOLD, 	868, -2748.1691, 1250.73535, 11.4003100, 0.000000, 0.000000, -88.8000 );
	CreateMiningRock( ORE_BAUXITE, 	867, -2734.9423, 1251.73816, 11.1903100, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_BAUXITE, 	867, -2735.5700, 1255.47192, 11.1903100, 0.000000, 0.000000, -139.019 );
	CreateMiningRock( ORE_BAUXITE, 	867, -2748.3437, 1235.13391, 11.1903100, 0.000000, 0.000000, -99.6000 );
	CreateMiningRock( ORE_BAUXITE, 	867, -2747.8896, 1238.57886, 11.1903100, 0.000000, 0.000000, 174.6602 );
	CreateMiningRock( ORE_PLATINUM, 868, 645.557128, 884.099853, -42.842994, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_PLATINUM, 867, 648.377441, 885.626892, -42.872383, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_EMERALD, 	868, 648.093261, 865.079772, -42.976993, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_EMERALD, 	867, 648.093261, 867.079772, -42.976993, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_PLATINUM, 868, 685.774841, 909.739135, -40.452533, 10.89999, 0.000000, -105.500 );
	CreateMiningRock( ORE_EMERALD, 	868, 679.863281, 925.253662, -41.573390, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_DIAMOND, 	868, 684.565002, 921.632324, -41.270782, 0.400041, 0.000000, 120.0000 );
	CreateMiningRock( ORE_AMETHYST, 867, 527.286315, 842.197082, -43.581855, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_AMETHYST, 867, 569.048278, 840.496887, -42.454177, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_PLATINUM, 868, 570.629943, 841.765747, -42.634399, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_PLATINUM, 868, 598.894470, 847.992004, -43.830204, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_AMETHYST, 867, 604.275024, 848.331298, -43.830204, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_DIAMOND, 	868, 629.993469, 823.527526, -43.400970, 0.000000, 0.000000, 85.90009 );
	CreateMiningRock( ORE_COAL, 	867, 626.069946, 851.749389, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_EMERALD, 	867, 658.767028, 812.288208, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_EMERALD, 	867, 659.874877, 812.647521, -43.610939, 0.000000, 0.000000, 90.00000 );
	CreateMiningRock( ORE_AMETHYST, 868, 657.839660, 837.129272, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_COAL, 	867, 657.596984, 834.139099, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_DIAMOND, 	867, 652.896362, 846.951110, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_DIAMOND, 	867, 660.239624, 841.461730, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_SAPHHIRE, 867, 659.540588, 860.061401, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_IRON, 	867, 638.540527, 830.990112, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_COAL, 	867, 630.540527, 830.990112, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_COAL, 	868, 688.510498, 906.781005, -40.194725, -5.20000, 0.000000, 133.1999 );
	CreateMiningRock( ORE_COAL, 	867, 622.073303, 874.670532, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_SAPHHIRE, 867, 606.893066, 877.988037, -43.610939, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_IRON, 	868, 600.279541, 870.543884, -43.557388, 0.000000, 0.000000, 45.00000 );
	CreateMiningRock( ORE_IRON, 	867, 579.832519, 893.789855, -44.315792, 0.000000, 0.000000, 15.00000 );
	CreateMiningRock( ORE_DIAMOND, 	867, 614.769104, 921.359924, -42.239196, 15.20000, -7.40000, 0.000000 );
	CreateMiningRock( ORE_SAPHHIRE, 867, 609.398437, 914.821777, -43.654232, 12.70000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_BAUXITE, 	867, 635.195068, 919.271728, -42.244331, 17.80000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_BAUXITE, 	867, 654.036071, 926.508178, -40.387538, 14.20000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_SAPHHIRE, 868, 670.923217, 915.094238, -41.392536, 0.000000, 0.000000, 0.000000 );
	CreateMiningRock( ORE_SAPHHIRE, 867, 685.852478, 899.059631, -40.304836, 0.000000, -3.60000, 0.000000 );
	CreateMiningRock( ORE_RUBY, 	867, 691.398437, 903.649169, -39.766517, -5.20000, 0.000000, 133.1990 );
	CreateMiningRock( ORE_RUBY, 	867, 692.537475, 898.189575, -39.629940, -4.79999, -5.69999, 0.000000 );
	CreateMiningRock( ORE_RUBY, 	867, 680.914611, 892.820068, -40.536987, 10.99999, -3.60000, -106.900 );
	CreateMiningRock( ORE_GOLD,	 	867, 692.731994, 894.016052, -39.744705, 7.099992, -2.00000, -106.900 );
	CreateMiningRock( ORE_GOLD, 	867, 691.096679, 888.700439, -39.801738, -0.80000, 1.200000, 173.1999 );
	CreateMiningRock( ORE_GOLD, 	867, 684.758605, 885.710876, -40.225788, 0.000000, 0.000000, 15.00000 );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	p_isMining{ playerid } = false;
	return 1;
}

hook OnServerGameDayEnd( )
{
	foreach ( new m : miningrock )
	{
		g_miningData[ m ] [ E_ORES ] = g_miningData[ m ] [ E_MAX_ORES ]; // Replenish
		format( szNormalString, 14, "%s\n%d/%d", getOreName( g_miningData[ m ] [ E_ORE ] ), g_miningData[ m ] [ E_ORES ], g_miningData[ m ] [ E_MAX_ORES ] );
		UpdateDynamic3DTextLabelText( g_miningData[ m ] [ E_LABEL ], g_miningData[ m ] [ E_COLOR ], szNormalString );
	}
	return 1;
}

hook OnPlayerProgressUpdate( playerid, progressid, bool: canceled, params )
{
	if ( progressid == PROGRESS_MINING )
	{
		new
			m = p_MiningOre{ playerid };

		if ( !IsPlayerSpawned( playerid ) || ! Mining_IsPlayerNearOre( playerid, m, 3.0 ) || !IsPlayerConnected( playerid ) || IsPlayerInAnyVehicle( playerid ) || canceled )
			return g_miningData[ m ] [ E_MINING ] = INVALID_PLAYER_ID, p_isMining{ playerid } = false, StopProgressBar( playerid ), 1;
	}
	return 1;
}

hook OnProgressCompleted( playerid, progressid, params )
{
	if ( progressid == PROGRESS_MINING )
	{
		new m = p_MiningOre{ playerid };
		new iRandom = random( 101 );

		p_isMining{ playerid } = false;
		g_miningData[ m ] [ E_MINING ] = INVALID_PLAYER_ID;

		if ( ( g_miningData[ m ] [ E_ORE ] == ORE_IRON && iRandom > 80 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_BAUXITE && iRandom > 85 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_GOLD && iRandom > 45 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_COAL && iRandom > 90 ||
			( g_miningData[ m ] [ E_ORE ] == ORE_DIAMOND && iRandom > 30 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_RUBY && iRandom > 35 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_SAPHHIRE && iRandom > 30 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_EMERALD && iRandom > 52 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_PLATINUM && iRandom > 25 ) ||
			( g_miningData[ m ] [ E_ORE ] == ORE_AMETHYST && iRandom > 75 ) )
		)
		{
			SetPlayerMineOre( playerid, m );
			return SendError( playerid, "You did not find any ore. Mining again." );
		}

		if ( GetPVarInt( playerid, "give_ore_score" ) < g_iTime ) GivePlayerScore( playerid, 1 ), SetPVarInt( playerid, "give_ore_score", g_iTime + 15 );
		g_miningData[ m ] [ E_ORES ] --;

		format( szNormalString, 14, "%s\n%d/%d", getOreName( g_miningData[ m ] [ E_ORE ] ), g_miningData[ m ] [ E_ORES ], g_miningData[ m ] [ E_MAX_ORES ] );
		UpdateDynamic3DTextLabelText( g_miningData[ m ] [ E_LABEL ], g_miningData[ m ] [ E_COLOR ], szNormalString );

		if ( IsPlayerJailed( playerid ) ) {
			SendServerMessage( playerid, "Great you've mined an ore, now take it to the "COL_GREY"Rock Crusher"COL_WHITE"." );
		} else {
			SendServerMessage( playerid, "Great you've mined an ore, now store it in a "COL_GREY"Dune"COL_WHITE"." );
		}

		//GivePlayerExperience( playerid, E_MINING );
		SetPVarInt( playerid, "carrying_ore", m );
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_CARRY );
		SetPlayerAttachedObject( playerid, 4, 2936, 5, 0.000000, 0.197999, 0.133999, 113.099983, -153.799987, 57.300003, 0.631000, 0.597000, 0.659999, g_miningData[ m ] [ E_ARGB ], g_miningData[ m ] [ E_ARGB ] );
	}
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( checkpointid == g_Checkpoints[ CP_ALCATRAZ_EXPORT ] )
	{
		if ( IsPlayerAttachedObjectSlotUsed( playerid, 4 ) )
		{
			new ore = GetPVarInt( playerid, "carrying_ore" );

			if ( ! ( 0 <= ore < sizeof( g_miningData ) ) )
				return SendError( playerid, "An error has occured, try again." ), RemoveEquippedOre( playerid );

			new earned_money = floatround( float( g_orePrices[ g_miningData[ ore ] [ E_ORE ] ] ) * 0.5 );

			GivePlayerCash( playerid, earned_money );
			StockMarket_UpdateEarnings( E_STOCK_MINING_COMPANY, earned_money, 0.5 );
			SendServerMessage( playerid, "You have crushed a "COL_GREY"%s"COL_WHITE" Ore and earned "COL_GOLD"%s"COL_WHITE".", getOreName( g_miningData[ ore ] [ E_ORE ] ), cash_format( earned_money ) );
			RemoveEquippedOre( playerid );
		}
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnPlayerEnterDynArea( playerid, areaid )
{
    // mining dunes
	if ( GetGVarType( "mining_dune_area", areaid ) != GLOBAL_VARTYPE_NONE )
	{
		new attached_vehicle = GetGVarInt( "mining_dune_area", areaid );
		new attached_model = GetVehicleModel( attached_vehicle );

		if ( attached_model == 573 )
		{
			if ( IsPlayerAttachedObjectSlotUsed( playerid, 4 ) )
			{
				static szID[ 15 ], szOres[ 15 ];

				format( szOres, sizeof( szOres ), "mine_%d_ores", attached_vehicle );

				if ( GetGVarInt( szOres ) >= MAX_ORE_STORAGE )
					return SendError( playerid, "You can only carry %d ores in this vehicle.", MAX_ORE_STORAGE );

				new ore = GetPVarInt( playerid, "carrying_ore" );

				SetGVarInt( szOres, GetGVarInt( szOres ) + 1 );
				format( szID, sizeof( szID ), "mine_%d_cash", attached_vehicle ), SetGVarInt( szID, GetGVarInt( szID ) + g_orePrices[ g_miningData[ ore ] [ E_ORE ] ] );

				SendServerMessage( playerid, "You have stored a "COL_GREY"%s"COL_WHITE" ore in this Dune. "COL_ORANGE"[%d/%d]", getOreName( g_miningData[ ore ] [ E_ORE ] ), GetGVarInt( szOres ), MAX_ORE_STORAGE );
				RemoveEquippedOre( playerid );
			}
		}
	}
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_FIRE ) )
	{
		// drop the ore if they click
		if ( GetPVarType( playerid, "carrying_ore" ) != PLAYER_VARTYPE_NONE && IsPlayerAttachedObjectSlotUsed( playerid, 4 ) ) {
			return RemoveEquippedOre( playerid ), SendServerMessage( playerid, "You have disposed of your mined ore." ), 1;
		}

		// mine the ore
		if ( GetPlayerWeapon( playerid ) == WEAPON_SHOVEL )
		{
			if ( ! IsPlayerUsingAnimation( playerid ) && ! IsPlayerAttachedObjectSlotUsed( playerid, 4 ) && ! IsPlayerAttachedObjectSlotUsed( playerid, 3 ) && ! IsPlayerMining( playerid ) )
			{
				static
					Float: X, Float: Y, Float: Z;

				foreach ( new m : miningrock )
				{
					if ( Mining_IsPlayerNearOre( playerid, m, 2.5 ) )
					{
						if ( IsPlayerConnected( g_miningData[ m ] [ E_MINING ] ) )
							return SendError( playerid, "Somebody is currently mining this rock." );

						if ( g_miningData[ m ] [ E_ORES ] <= 0 )
							return SendError( playerid, "There are no ores left in this rock." );

						SetPlayerFacePoint( playerid, X, Y, Z );
						SetPlayerMineOre( playerid, m );
						SendServerMessage( playerid, "You're now mining a rock." );
						return 1;
					}
				}
			}
		}
	}
	return 1;
}

hook OnVehicleCreated( vehicleid, model_id )
{
	if ( model_id == 573 )
	{
		new
			attachable_area = CreateDynamicSphere( 0.0, 0.0, 0.0, 2.5 );

		AttachDynamicAreaToVehicle( attachable_area, vehicleid, 0.0, -4.0, 0.0 );
		SetGVarInt( "mining_dune_area", vehicleid, attachable_area );
		SetGVarInt( "mining_dune_veh", attachable_area, vehicleid );
	}
	return 1;
}

hook OnVehicleDestroyed( vehicleid )
{
	if ( GetGVarType( "mining_dune_veh", vehicleid ) != GLOBAL_VARTYPE_NONE ) // destroy mining area
	{
		new
			areaid = GetGVarInt( "mining_dune_veh", vehicleid );

		DestroyDynamicArea( areaid );
		DeleteGVar( "mining_dune_veh", vehicleid );
		DeleteGVar( "mining_dune_area", vehicleid );
	}
	return 1;
}

hook OnPlayerDriveVehicle( playerid, vehicleid )
{
	if ( GetVehicleModel( vehicleid ) == 573 )
	{
		new num_ores = GetGVarInt( sprintf( "mine_%d_ores", vehicleid ) );

		// printf( "Ores stored %d for %d", num_ores, sprintf( "mine_%d_ores", vehicleid ) ) ;

		if ( num_ores > 0 )
		{
			new cash_value = GetGVarInt( sprintf( "mine_%d_cash", vehicleid ) );

			Beep( playerid );
			GameTextForPlayer( playerid, "Go to the truck blip on your radar for money!", 3000, 1 );
			SendServerMessage( playerid, "You have %d ores that you can export for "COL_GOLD"%s"COL_WHITE"!", num_ores, cash_format( cash_value ) );

			static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = CreateDynamicMapIconEx( -1945.6794, -1086.8906, 31.4261, 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );

			p_MiningExport[ playerid ] = CreateDynamicRaceCP( 1, -1945.6794, -1086.8906, 31.4261, 0.0, 0.0, 0.0, 4.0, -1, -1, playerid );
		}
	}
	return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER ) // Driver has a new state?
    {
		if ( p_MiningExport[ playerid ] != 0xFFFF )
		{
			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = 0xFFFF;
			DestroyDynamicRaceCP( p_MiningExport[ playerid ] );
			p_MiningExport[ playerid ] = 0xFFFF;
		}
    }
	return 1;
}

hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	if ( p_MiningExport[ playerid ] == checkpointid )
	{
		new vehicleid = GetPlayerVehicleID( playerid );
	    if ( GetVehicleModel( vehicleid ) == 573 )
	    {
		    new
				szContent[ 15 ],
				cashEarned, oresExported
			;
			format( szContent, sizeof( szContent ), "mine_%d_ores", vehicleid );
			oresExported = GetGVarInt( szContent ), DeleteGVar( szContent );

			format( szContent, sizeof( szContent ), "mine_%d_cash", vehicleid );
			cashEarned = GetGVarInt( szContent ), DeleteGVar( szContent );

			DestroyDynamicMapIcon( p_PawnStoreMapIcon[ playerid ] );
			p_PawnStoreMapIcon[ playerid ] = 0xFFFF;
			DestroyDynamicRaceCP( p_MiningExport[ playerid ] );
			p_MiningExport[ playerid ] = 0xFFFF;
			GivePlayerCash( playerid, cashEarned );
			StockMarket_UpdateEarnings( E_STOCK_MINING_COMPANY, cashEarned, 0.5 );
			GivePlayerScore( playerid, floatround( oresExported / 2 ) ); // 16 score is a bit too much for ore... so half that = 8
			//GivePlayerExperience( playerid, E_MINING, float( oresExported ) * 0.2 );
			SendServerMessage( playerid, "You have exported %d rock ore(s) to an industry, earning you "COL_GOLD"%s"COL_WHITE".", oresExported, cash_format( cashEarned ) );
		}
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

/* ** Functions ** */
stock CreateMiningRock( ore_type, model, Float: X, Float: Y, Float: Z, Float: rX = 0.0, Float: rY = 0.0, Float: rZ = 0.0 )
{
	new
		ID = Iter_Free(miningrock),
		szOre[ 14 ],
		iOreColour
	;

	if ( ID != ITER_NONE )
	{
		Iter_Add(miningrock, ID);

		g_miningData[ ID ] [ E_OBJECT ] 		= CreateDynamicObject( model, X, Y, Z, rX, rY, rZ );
		g_miningData[ ID ] [ E_MINING ] 		= INVALID_PLAYER_ID;
		g_miningData[ ID ] [ E_ORES ] 			= g_oreQuanities[ ore_type ]; // To replenish
		g_miningData[ ID ] [ E_MAX_ORES ]		= g_oreQuanities[ ore_type ];
		g_miningData[ ID ] [ E_ORE ] 			= ore_type;

		switch( ore_type )
		{
			case ORE_BAUXITE:
			{
				iOreColour = 0xC24000FF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0,  2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFFC24000 ) );
			}
			case ORE_COAL:
			{
				iOreColour = 0x5B5E28FF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFF5B5E28 ) );
			}
			case ORE_IRON:
			{
				iOreColour = 0x3D3837FF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFF3D3837 ) );
			}
			case ORE_GOLD:
			{
				iOreColour = 0xE6A615FF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFFE6A615 ) );
			}
			case ORE_RUBY:
			{
				iOreColour = 0xE0115FFF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFFE0115F ) );
			}
			case ORE_EMERALD:
			{
				iOreColour = 0x50C878FF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFF50C878 ) );
			}
			case ORE_SAPHHIRE:
			{
				iOreColour = 0x0F52BAFF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFF0F52BA ) );
			}
			case ORE_PLATINUM:
			{
				iOreColour = 0xE5E5E5FF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFFE5E5E5 ) );
			}
			case ORE_DIAMOND:
			{
				iOreColour = 0x232323FF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFF232323 ) );
			}
			case ORE_AMETHYST:
			{
				iOreColour = 0x9966CCFF;
			 	SetDynamicObjectMaterial( g_miningData[ ID ] [ E_OBJECT ], 0, 2936, "kmb_rckx", "larock256", ( g_miningData[ ID ] [ E_ARGB ] =  0xFF9966CC ) );
			}
		}
		format( szOre, sizeof( szOre ), "%s\n%d/%d", getOreName( ore_type ), g_miningData[ ID ] [ E_ORES ], g_miningData[ ID ] [ E_MAX_ORES ] );
		g_miningData[ ID ] [ E_COLOR ] = iOreColour;
		g_miningData[ ID ] [ E_LABEL ] = CreateDynamic3DTextLabel( szOre, iOreColour, X, Y, Z + 1, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1 );
	}
	return ID;
}

stock getOreName( id )
{
	static
		szOre[ 9 ];

	switch( id )
	{
		case ORE_GOLD: szOre = "Gold";
		case ORE_IRON: szOre = "Iron";
		case ORE_COAL: szOre = "Coal";
		case ORE_BAUXITE: szOre = "Bauxite";
		case ORE_AMETHYST: szOre = "Amethyst";
		case ORE_EMERALD: szOre = "Emerald";
		case ORE_SAPHHIRE: szOre = "Saphhire";
		case ORE_PLATINUM: szOre = "Platinum";
		case ORE_DIAMOND: szOre = "Diamond";
		case ORE_RUBY: szOre = "Ruby";
		default: szOre = "n/a";
	}
	return szOre;
}

stock RemoveEquippedOre( playerid )
{
	RemovePlayerAttachedObject( playerid, 4 );
	SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
	ClearAnimations( playerid );
	DeletePVar( playerid, "carrying_ore" );
	return 1;
}

stock SetPlayerMineOre( playerid, m )
{
	SetPlayerArmedWeapon( playerid, WEAPON_SHOVEL );
	ApplyAnimation( playerid, "BASEBALL", "Bat_4", 2.0, 1, 0, 0, 0, 0 );
	p_isMining{ playerid } = true;
	g_miningData[ m ] [ E_MINING ] = playerid;
	p_MiningOre{ playerid } = m;
	ShowProgressBar( playerid, "Mining Rock", PROGRESS_MINING, g_oreMiningTime[ g_miningData[ m ] [ E_ORE ] ], g_miningData[ m ] [ E_COLOR ] );
}

stock Mining_IsPlayerNearOre( playerid, oreid, Float: distance )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( GetDynamicObjectPos( g_miningData[ oreid ] [ E_OBJECT ], X, Y, Z ) ) {
		return IsPlayerInRangeOfPoint( playerid, distance, X, Y, Z );
	} else {
		return 0;
	}
}

stock IsPlayerMining( playerid ) {
	return p_isMining{ playerid };
}
