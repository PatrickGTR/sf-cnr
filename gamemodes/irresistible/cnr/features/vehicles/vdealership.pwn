/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\vehicles\vdealership.pwn
 * Purpose: vehicle dealership for personal vehicles
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define BV_TYPE_AIRPLANES			( 1 )
#define BV_TYPE_HELICOPTERS			( 2 )
#define BV_TYPE_BIKES				( 3 )
#define BV_TYPE_CONVERTIBLES		( 4 )
#define BV_TYPE_INDUSTRIAL 			( 5 )
#define BV_TYPE_LOWRIDERS			( 6 )
#define BV_TYPE_OFF_ROAD 			( 7 )
#define BV_TYPE_PUBLIC_SERVICE		( 8 )
#define BV_TYPE_SALOONS 			( 9 )
#define BV_TYPE_SPORTS				( 10 )
#define BV_TYPE_STATION_WAGONS		( 11 )
#define BV_TYPE_BOATS				( 12 )
#define BV_TYPE_UNIQUE				( 13 )

#define PREVIEW_MODEL_VEHICLE 		( 5 )

/* ** Variables ** */
enum E_BV_DATA
{
	E_TYPE, 	E_MODEL, 	E_VIP, E_PRICE,	E_NAME[ 18 ]
};

new
	g_BVCategories[ ] [ 16 ] =
	{
		{ "Airplanes" },		{ "Helicopters" },		{ "Bikes" },
		{ "Convertibles" },		{ "Industrial" },		{ "Lowriders" },
		{ "Off Road" },			{ "Public Service" },	{ "Saloons" },
		{ "Sport Vehicles" },	{ "Station Wagons" },	{ "Boats" },
		{ "Unique Vehicles" }
	},
	g_BuyableVehicleData 			[ ] [ E_BV_DATA ] =
	{
		// Airplanes
		{ BV_TYPE_AIRPLANES, 		577, 0, 35000000, 	"AT400" },
		{ BV_TYPE_AIRPLANES, 		592, 0, 17500000, 	"Andromada" },
		{ BV_TYPE_AIRPLANES, 		519, 0, 10000000, 	"Shamal" },
		{ BV_TYPE_AIRPLANES, 		513, 0, 4500000, 	"Stuntplane" },
		{ BV_TYPE_AIRPLANES, 		511, 0, 3300000, 	"Beagle" },
		{ BV_TYPE_AIRPLANES, 		553, 1, 3300000, 	"Nevada" },
		{ BV_TYPE_AIRPLANES, 		593, 0, 3000000, 	"Dodo" },
		{ BV_TYPE_AIRPLANES, 		476, 1, 3000000, 	"Rustler" },
		{ BV_TYPE_AIRPLANES, 		460, 1, 2700000, 	"Skimmer" },
		{ BV_TYPE_AIRPLANES, 		512, 0, 2200000, 	"Cropduster" },

		// Helicopters
		{ BV_TYPE_HELICOPTERS, 		487, 0, 7500000, 	"Maverick" },
		{ BV_TYPE_HELICOPTERS, 		417, 0, 6000000, 	"Leviathan" },
		{ BV_TYPE_HELICOPTERS, 		497, 1, 5000000, 	"Police Maverick" },
		{ BV_TYPE_HELICOPTERS, 		488, 1, 3250000, 	"SAN News Maverick" },
		{ BV_TYPE_HELICOPTERS, 		563, 0, 3000000, 	"Raindance" },
		{ BV_TYPE_HELICOPTERS, 		469, 1, 3000000, 	"Sparrow" },
		{ BV_TYPE_HELICOPTERS, 		548, 1, 2700000, 	"Cargobob" },

		// Bikes
		{ BV_TYPE_BIKES, 			522, 0, 2500000, 	"NRG-500" },
		{ BV_TYPE_BIKES, 			510, 0, 2000000, 	"Mountain Bike" },
		{ BV_TYPE_BIKES, 			521, 0, 1500000, 	"FCR-900" },
		{ BV_TYPE_BIKES, 			481, 0, 1500000, 	"BMX" },
		{ BV_TYPE_BIKES,			461, 0, 1000000, 	"PCJ-600" },
		{ BV_TYPE_BIKES, 			509, 0, 800000, 	"Bike" },
		{ BV_TYPE_BIKES, 			581, 0, 750000, 	"BF-400" },
		{ BV_TYPE_BIKES, 			468, 0, 750000, 	"Sanchez" },
		{ BV_TYPE_BIKES, 			471, 0, 500000, 	"Quad" },
		{ BV_TYPE_BIKES, 			463, 0, 550000, 	"Freeway" },
		{ BV_TYPE_BIKES, 			586, 0, 400000, 	"Wayfarer" },
		{ BV_TYPE_BIKES, 			462, 0, 375000, 	"Faggio" },
		{ BV_TYPE_BIKES, 			448, 1, 50000, 		"Pizzaboy" },

		// Convertiblies
		{ BV_TYPE_CONVERTIBLES, 	480, 0, 1700000, 	"Comet" },
		{ BV_TYPE_CONVERTIBLES, 	439, 0, 750000, 	"Stallion" },
		{ BV_TYPE_CONVERTIBLES, 	533, 0, 650000, 	"Feltzer" },
		{ BV_TYPE_CONVERTIBLES, 	555, 0, 620000, 	"Windsor" },

		// Industrial
		{ BV_TYPE_INDUSTRIAL, 		498, 1, 2000000, 	"Boxville" },
		{ BV_TYPE_INDUSTRIAL, 		578, 1, 1250000, 	"DFT-30" },
		{ BV_TYPE_INDUSTRIAL, 		408, 1, 1000000, 	"Trashmaster" },
		{ BV_TYPE_INDUSTRIAL, 		554, 0, 500000, 	"Yosemite" },
		{ BV_TYPE_INDUSTRIAL, 		482, 0, 500000, 	"Burrito" },
		{ BV_TYPE_INDUSTRIAL, 		600, 0, 375000, 	"Picador" },
		{ BV_TYPE_INDUSTRIAL, 		552, 1, 300000, 	"Utility Van" },
		{ BV_TYPE_INDUSTRIAL, 		413, 0, 300000, 	"Pony" },
		{ BV_TYPE_INDUSTRIAL, 		582, 1, 250000, 	"Newsvan" },
		{ BV_TYPE_INDUSTRIAL, 		440, 0, 250000, 	"Rumpo" },
		{ BV_TYPE_INDUSTRIAL, 		422, 0, 220000, 	"Bobcat" },
		{ BV_TYPE_INDUSTRIAL, 		531, 0, 180000, 	"Tractor" },
		{ BV_TYPE_INDUSTRIAL,		414, 0, 180000, 	"Mule" },
		{ BV_TYPE_INDUSTRIAL, 		543, 0, 130000, 	"Sadler" },
		{ BV_TYPE_INDUSTRIAL,		478, 0, 100000, 	"Walton" },
		{ BV_TYPE_INDUSTRIAL, 		499, 0, 80000, 		"Benson" },
		{ BV_TYPE_INDUSTRIAL, 		456, 0, 60000, 		"Yankee" },

		// Lowriders
		{ BV_TYPE_LOWRIDERS, 		535, 0, 1500000, 	"Slamvan" },
		{ BV_TYPE_LOWRIDERS, 		567, 0, 1250000, 	"Savanna" },
		{ BV_TYPE_LOWRIDERS, 		536, 0, 800000, 	"Blade" },
		{ BV_TYPE_LOWRIDERS, 		412, 0, 800000, 	"Voodoo" },
		{ BV_TYPE_LOWRIDERS, 		575, 0, 750000, 	"Broadway" },
		{ BV_TYPE_LOWRIDERS, 		576, 0, 600000, 	"Tornado" },
		{ BV_TYPE_LOWRIDERS, 		534, 0, 430000, 	"Remington" },
		{ BV_TYPE_LOWRIDERS, 		566, 0, 300000, 	"Tahoma" },

		// Off road
		{ BV_TYPE_OFF_ROAD, 		444, 1, 3000000, 	"Monster" },
		{ BV_TYPE_OFF_ROAD, 		556, 1, 2500000, 	"Monster A" },
		{ BV_TYPE_OFF_ROAD, 		557, 1, 2500000, 	"Monster B" },
		{ BV_TYPE_OFF_ROAD, 		573, 1, 1800000, 	"Dune" },
		{ BV_TYPE_OFF_ROAD, 		579, 0, 1750000, 	"Huntley" },
		{ BV_TYPE_OFF_ROAD, 		470, 1, 1500000, 	"Patriot" },
		{ BV_TYPE_OFF_ROAD, 		495, 0, 1500000, 	"Sandking" },
		{ BV_TYPE_OFF_ROAD,			489, 0, 850000, 	"Rancher" },
		{ BV_TYPE_OFF_ROAD, 		400, 0, 710000, 	"Landstalker" },
		{ BV_TYPE_OFF_ROAD, 		568, 1, 650000, 	"Bandito" },
		{ BV_TYPE_OFF_ROAD, 		500, 0, 500000, 	"Mesa" },
		{ BV_TYPE_OFF_ROAD, 		424, 0, 450000, 	"BF Injection" },

		// Public Service
		{ BV_TYPE_PUBLIC_SERVICE,	601, 1, 3000000, 	"S.W.A.T." },
		{ BV_TYPE_PUBLIC_SERVICE, 	596, 1, 2500000, 	"Police Car (LSPD)" },
		{ BV_TYPE_PUBLIC_SERVICE, 	597, 1, 2500000, 	"Police Car (SFPD)" },
		{ BV_TYPE_PUBLIC_SERVICE, 	598, 1, 2500000, 	"Police Car (LVPD)" },
		{ BV_TYPE_PUBLIC_SERVICE, 	416, 1, 2500000, 	"Ambulance" },
		{ BV_TYPE_PUBLIC_SERVICE, 	407, 1, 2500000, 	"Firetruck"},
		{ BV_TYPE_PUBLIC_SERVICE, 	544, 1, 2500000, 	"Firetruck LA" },
		{ BV_TYPE_PUBLIC_SERVICE, 	437, 1, 2000000, 	"Coach" },
		{ BV_TYPE_PUBLIC_SERVICE, 	427, 1, 2000000, 	"Enforcer" },
		{ BV_TYPE_PUBLIC_SERVICE, 	599, 1, 1800000, 	"Police Ranger" },
		{ BV_TYPE_PUBLIC_SERVICE, 	438, 1, 1700000,	"Cabbie" },
		{ BV_TYPE_PUBLIC_SERVICE,	431, 1, 1600000,	"Bus" },
		{ BV_TYPE_PUBLIC_SERVICE,	528, 1, 1300000, 	"FBI Truck" },
		{ BV_TYPE_PUBLIC_SERVICE, 	523, 1, 1100000, 	"HPV1000" },
		{ BV_TYPE_PUBLIC_SERVICE, 	420, 1, 1000000, 	"Taxi" },
		{ BV_TYPE_PUBLIC_SERVICE, 	490, 1, 950000, 	"FBI Rancher" },

		// Saloons
		{ BV_TYPE_SALOONS, 			580, 0, 5000000, 	"Stafford" },
		{ BV_TYPE_SALOONS, 			560, 0, 2500000, 	"Sultan" },
		{ BV_TYPE_SALOONS, 			562, 0, 1800000, 	"Elegy" },
		{ BV_TYPE_SALOONS, 			421, 0, 1750000,	"Washington" },
		{ BV_TYPE_SALOONS, 			426, 0, 1500000, 	"Premier" },
		{ BV_TYPE_SALOONS, 			492, 0, 875000, 	"Greenwood" },
		{ BV_TYPE_SALOONS, 			558, 0, 750000, 	"Uranus" },
		{ BV_TYPE_SALOONS, 			504, 1, 750000, 	"Bloodring Banger" },
		{ BV_TYPE_SALOONS, 			405, 0, 725000, 	"Sentinel" },
		{ BV_TYPE_SALOONS, 			474, 0, 650000, 	"Hermes" },
		{ BV_TYPE_SALOONS, 			507, 0, 650000, 	"Elegant" },
		{ BV_TYPE_SALOONS, 			466, 0, 560000, 	"Glendale" },
		{ BV_TYPE_SALOONS, 			517, 0, 500000, 	"Majestic" },
		{ BV_TYPE_SALOONS, 			467, 0, 480000, 	"Oceanic" },
		{ BV_TYPE_SALOONS, 			585, 0, 480000, 	"Emperor" },
		{ BV_TYPE_SALOONS, 			516, 0, 475000, 	"Nebula" },
		{ BV_TYPE_SALOONS,			419, 0, 425000, 	"Esperanto" },
		{ BV_TYPE_SALOONS, 			550, 0, 420000, 	"Sunrise" },
		{ BV_TYPE_SALOONS, 			518, 0, 400000, 	"Buccaneer" },
		{ BV_TYPE_SALOONS, 			491, 0, 350000, 	"Virgo" },
		{ BV_TYPE_SALOONS, 			549, 0, 310000, 	"Tampa" },
		{ BV_TYPE_SALOONS, 			445, 0, 300000,		"Admiral" },
		{ BV_TYPE_SALOONS, 			401, 0, 250000, 	"Bravura" },
		{ BV_TYPE_SALOONS, 			551, 0, 230000, 	"Merit" },
		{ BV_TYPE_SALOONS, 			529, 0, 210000, 	"Willard" },
		{ BV_TYPE_SALOONS, 			542, 0, 200000, 	"Clover" },
		{ BV_TYPE_SALOONS, 			540, 0, 200000, 	"Vincent" },
		{ BV_TYPE_SALOONS, 			546, 0, 190000, 	"Intruder" },
		{ BV_TYPE_SALOONS, 			547, 0, 160000, 	"Primo" },
		{ BV_TYPE_SALOONS, 			526, 0, 160000, 	"Fortune" },
		{ BV_TYPE_SALOONS, 			410, 0, 150000, 	"Manana" },
		{ BV_TYPE_SALOONS, 			436, 0, 100000, 	"Previon" },
		{ BV_TYPE_SALOONS, 			527, 0, 75000, 		"Cadrona" },

		// Sports
		{ BV_TYPE_SPORTS, 			411, 0, 5000000, 	"Infernus" },
		{ BV_TYPE_SPORTS, 			451, 0, 4000000, 	"Turismo" },
		{ BV_TYPE_SPORTS, 			541, 0, 3250000, 	"Bullet" },
		{ BV_TYPE_SPORTS, 			415, 0, 2600000, 	"Cheetah" },
		{ BV_TYPE_SPORTS, 			494, 1, 2500000, 	"Hotring Racer A" },
		{ BV_TYPE_SPORTS, 			502, 1, 2500000, 	"Hotring Racer B" },
		{ BV_TYPE_SPORTS, 			503, 1, 2500000, 	"Hotring Racer C" },
		{ BV_TYPE_SPORTS, 			402, 0, 2250000, 	"Buffalo" },
		{ BV_TYPE_SPORTS, 			429, 0, 1750000, 	"Banshee" },
		{ BV_TYPE_SPORTS, 			565, 0, 1250000, 	"Flash" },
		{ BV_TYPE_SPORTS, 			477, 0, 1100000, 	"ZR-350" },
		{ BV_TYPE_SPORTS, 			506, 0, 1000000,	"Super GT" },
		{ BV_TYPE_SPORTS, 			559, 0, 1000000, 	"Jester" },
		{ BV_TYPE_SPORTS, 			602, 0, 1000000, 	"Alpha" },
		{ BV_TYPE_SPORTS, 			587, 0, 750000, 	"Euros" },
		{ BV_TYPE_SPORTS, 			475, 0, 675000, 	"Sabre" },
		{ BV_TYPE_SPORTS, 			603, 0, 630000, 	"Phoenix" },
		{ BV_TYPE_SPORTS, 			589, 0, 625000, 	"Club" },
		{ BV_TYPE_SPORTS, 			496, 0, 325000, 	"Blista Compact" },

		// Station Wagons
		{ BV_TYPE_STATION_WAGONS, 	479, 0, 610000, 	"Regina" },
		{ BV_TYPE_STATION_WAGONS, 	458, 0, 600000,		"Solair" },
		{ BV_TYPE_STATION_WAGONS, 	561, 0, 400000, 	"Stratum" },
		{ BV_TYPE_STATION_WAGONS, 	404, 0, 300000, 	"Perenniel" },
		{ BV_TYPE_STATION_WAGONS, 	418, 0, 320000, 	"Moonbeam" },

		// Boats
		{ BV_TYPE_BOATS, 			484, 0, 5000000, 	"Marquis" },
		{ BV_TYPE_BOATS, 			493, 0, 3500000, 	"Jetmax" },
		{ BV_TYPE_BOATS, 			430, 1, 3500000, 	"Predator" },
		{ BV_TYPE_BOATS, 			446, 0, 2500000, 	"Squallo" },
		{ BV_TYPE_BOATS, 			454, 0, 1750000, 	"Tropic" },
		{ BV_TYPE_BOATS, 			595, 1, 1600000, 	"Launch" },
		{ BV_TYPE_BOATS, 			452, 0, 1000000, 	"Speeder" },
		{ BV_TYPE_BOATS, 			472, 1, 900000, 	"Coastguard" },
		{ BV_TYPE_BOATS, 			473, 0, 600000, 	"Dinghy" },
		{ BV_TYPE_BOATS, 			453, 0, 250000, 	"Reefer" },

		// Unique
		{ BV_TYPE_UNIQUE, 			406, 1, 2900000, 	"Dumper" },
		{ BV_TYPE_UNIQUE,			532, 1, 2500000, 	"Combine Harvester" },
		{ BV_TYPE_UNIQUE, 			409, 0, 2000000, 	"Stretch" },
		{ BV_TYPE_UNIQUE, 			539, 1, 2000000, 	"Vortex" },
		{ BV_TYPE_UNIQUE, 			508, 1, 2000000, 	"Journey" },
		{ BV_TYPE_UNIQUE, 			443, 1, 1300000, 	"Packer" },
		{ BV_TYPE_UNIQUE, 			423, 1, 850000, 	"Mr Whoopee" },
		{ BV_TYPE_UNIQUE, 			588, 1, 850000, 	"Hotdog" },
		{ BV_TYPE_UNIQUE, 			428, 1, 800000, 	"Securicar" },
		{ BV_TYPE_UNIQUE, 			434, 0, 780000, 	"Hotknife" },
		{ BV_TYPE_UNIQUE, 			483, 0, 770000, 	"Camper" },
		{ BV_TYPE_UNIQUE, 			525, 1, 500000, 	"Towtruck" },
		{ BV_TYPE_UNIQUE, 			545, 0, 500000, 	"Hustler" },
		{ BV_TYPE_UNIQUE, 			457, 1, 325000, 	"Caddy" },
		{ BV_TYPE_UNIQUE, 			486, 1, 200000, 	"Dozer" },
		{ BV_TYPE_UNIQUE, 			571, 1, 150000, 	"Kart" },
		{ BV_TYPE_UNIQUE, 			442, 0, 140000, 	"Romero" },
		{ BV_TYPE_UNIQUE, 			572, 1, 100000, 	"Mower" }
	},
	g_VehicleDealerCP 				[ 3 ] = { -1, ... }
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// create checkpoints and labels for the dealerships
	g_VehicleDealerCP[ 0 ] = CreateDynamicCP( -1867.9092, -646.3469, 1002.1284, 1.0, -1, -1, -1, 25.0 );
	g_VehicleDealerCP[ 1 ] = CreateDynamicCP( -126.2794, 117.3427, 1004.7233, 1.0, -1, -1, -1, 25.0 );
	g_VehicleDealerCP[ 2 ] = CreateDynamicCP( 540.7507, -1299.1378, 17.2859, 1.0, -1, -1, -1, 25.0 );

	CreateDynamic3DTextLabel( "[PURCHASE VEHICLE]", COLOR_GOLD, -1867.9092, -646.3469, 1002.1284, 20.0 );
	CreateDynamic3DTextLabel( "[PURCHASE VEHICLE]", COLOR_GOLD, -126.2794, 117.3427, 1004.7233, 20.0 );
	CreateDynamic3DTextLabel( "[PURCHASE VEHICLE]", COLOR_GOLD, 540.7507, -1299.1378, 17.2859, 20.0 );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( checkpointid == g_VehicleDealerCP[ 0 ] || checkpointid == g_VehicleDealerCP[ 1 ] || checkpointid == g_VehicleDealerCP[ 2 ] ) {
		return ShowBuyableVehiclesList( playerid ), Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VEHDEALER && response ) {
		ShowBuyableVehiclesTypeDialog( playerid, listitem + 1 );
	}
	else if ( dialogid == DIALOG_VEHDEALER_BUY )
	{
		if ( response )
		{
			new
				x = 0; // Error check

			for( new id; id < sizeof( g_BuyableVehicleData ); id ++ )
			{
				if ( g_BuyableVehicleData[ id ] [ E_TYPE ] == GetPVarInt( playerid, "vehicle_preview" ) )
				{
			       	if ( x == listitem )
			      	{
			      		SetPVarInt( playerid, "buying_vehicle", id );
			      		ShowPlayerDialog( playerid, DIALOG_VEHDEALER_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Vehicle Dealership", "Purchase This Vehicle\nPreview Vehicle", "Select", "Back" );
			      		return 1;
					}
			      	x++;
				}
			}

			ShowBuyableVehiclesList( playerid ), SendError( playerid, "An error has occurred. (0x68F)");
		}
		else ShowBuyableVehiclesList( playerid );
	}
	else if ( dialogid == DIALOG_VEHDEALER_OPTIONS )
	{
		if ( !response )
			return ShowBuyableVehiclesTypeDialog( playerid, GetPVarInt( playerid, "vehicle_preview" ) ), 1;

		switch( listitem )
		{
			case 0:
			{
				new
					data_id = GetPVarInt( playerid, "buying_vehicle" ),
					model = g_BuyableVehicleData[ data_id ] [ E_MODEL ]
				;
			    if ( p_OwnedVehicles[ playerid ] >= GetPlayerVehicleSlots( playerid ) ) return SendError( playerid, "You have reached the limit of purchasing vehicles." );
				if ( GetPlayerScore( playerid ) < 200 ) return SendError( playerid, "You need at least 200 score to buy a vehicle." );
				if ( GetPlayerCash( playerid ) < g_BuyableVehicleData[ data_id ] [ E_PRICE ] ) return SendError( playerid, "You don't have enough money for this vehicle." );

				// VIP Check
				if ( g_BuyableVehicleData[ data_id ] [ E_VIP ] )
				{
					if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
						return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );

					if ( ( ( p_VIPExpiretime[ playerid ] - g_iTime ) / 86400 ) < 3 )
						return SendError( playerid, "You need more than 3 days of V.I.P in order to complete this." );
				}

		        new Float: X, Float: Y, Float: Z, Float: fA;

		        // set teleport vehicle location

		        if ( IsPlayerInDynamicCP( playerid, g_VehicleDealerCP[ 0 ] ) ) // SF
		        {
		        	if ( IsBoatVehicle( model ) ) 		X = -2686.6484, Y = -938.5189, Z = -0.1212, fA = 109.4955;
					else if ( IsAirVehicle( model ) ) 	X = -1666.2905, Y = -173.4397, Z = 15.0692, fA = 314.6289;
			        else               	 				X = -2518.9045, Y = -614.8578, Z = 132.302, fA = 267.8874;
		        }
		        else if ( IsPlayerInDynamicCP( playerid, g_VehicleDealerCP[ 1 ] ) ) // LV
		        {
		        	if ( IsBoatVehicle( model ) ) 		X = 1633.71860, Y = 563.73600, Z = -0.0579, fA = 90.00000;
					else if ( IsAirVehicle( model ) ) 	X = 1477.43920, Y = 1761.4778, Z = 11.2735, fA = 180.9139;
			        else               	 				X = 1986.85240, Y = 2049.2278, Z = 10.8203, fA = 132.5364;
		        }
				else if ( IsPlayerInDynamicCP( playerid, g_VehicleDealerCP[ 2 ] ) ) // LS
		        {
		        	if ( IsBoatVehicle( model ) ) 		X = 728.4574, Y = -1516.2633, Z = 0.3122, fA = 178.5724;
					else if ( IsAirVehicle( model ) ) 	X = 2048.7910, Y = -2493.8928, Z = 14.4686, fA = 90.00000;
			        else  								X = 560.9333, Y = -1267.5469, Z = 16.9957, fA = 17.2539;
		        }

		        SetPlayerInterior( playerid, 0 );
		        SetPlayerVirtualWorld( playerid, 0 );

		        X += fRandomEx( 0, 1 );
		        Z += 3; // Just plane jams or someshit...

			   	new bID = CreateBuyableVehicle( playerid, model, random( 126 ), random( 126 ), X, Y, Z, fA, g_BuyableVehicleData[ data_id ] [ E_PRICE ] );
				if ( bID == -1 ) return SendClientMessage( playerid, -1, ""COL_GREY"[VEHICLE]"COL_WHITE" Unable to create a vehicle due to a unexpected error." );
				GivePlayerCash( playerid, -g_BuyableVehicleData[ data_id ] [ E_PRICE ] );

		        GetVehicleParamsEx( g_vehicleData[ playerid ] [ bID ] [ E_VEHICLE_ID ], engine, lights, alarm, doors, bonnet, boot, objective );
				SetVehicleParamsEx( g_vehicleData[ playerid ] [ bID ] [ E_VEHICLE_ID ], VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective );
				PutPlayerInVehicle( playerid, g_vehicleData[ playerid ] [ bID ] [ E_VEHICLE_ID ], 0 );

				StockMarket_UpdateEarnings( E_STOCK_VEHICLE_DEALERSHIP, g_BuyableVehicleData[ data_id ] [ E_PRICE ], 0.01 );

				SendServerMessage( playerid, "You have bought an "COL_GREY"%s"COL_WHITE" for "COL_GOLD"%s"COL_WHITE"!", g_BuyableVehicleData[ data_id ] [ E_NAME ], cash_format( g_BuyableVehicleData[ data_id ] [ E_PRICE ] )  );

				if ( p_OwnedVehicles[ playerid ] < 3 ) {
					ShowPlayerDialog( playerid, DIALOG_BOUGHT_VEH, DIALOG_STYLE_MSGBOX, "{FFFFFF}You've purchased a vehicle!", "{FFFFFF}Glad to see you've purchased a vehicle. Please ensure you read:\n\n* Vehicles are kept until you sell them or go two months inactive. This is not refundable.\n* Do not mispark your vehicle or it can be removed/impounded.\n* Check out /v for vehicle commands.\n* Find an acceptable place to park your new vehicle such as your house or a parking lot.", "Okay", "" );
					SetPVarInt( playerid, "bought_veh_ts", g_iTime + 30 );
				}
			}
			case 1:
			{
				return ShowPlayerModelPreview( playerid, PREVIEW_MODEL_VEHICLE, "Vehicle Preview", g_BuyableVehicleData[ GetPVarInt( playerid, "buying_vehicle" ) ] [ E_MODEL ] );
			}
		}
	}
	else if ( dialogid == DIALOG_BOUGHT_VEH )
	{
		if ( GetPVarInt( playerid, "bought_veh_ts" ) < g_iTime )
		{
			DeletePVar( playerid, "bought_veh_ts" );
			return 1;
		}
		SendServerMessage( playerid, "Please read this thoroughly so you know what you can be facing. %d seconds left.", GetPVarInt( playerid, "bought_veh_ts" ) - g_iTime );
		ShowPlayerDialog( playerid, DIALOG_BOUGHT_VEH, DIALOG_STYLE_MSGBOX, "{FFFFFF}You've purchased a vehicle!", "{FFFFFF}Glad to see you've purchased a vehicle. Please ensure you read:\n\n* Vehicles are kept until you sell them or go two months inactive. This is not refundable.\n* Do not mispark your vehicle or it can be removed/impounded.\n* Check out /v for vehicle commands.\n* Find an acceptable place to park your new vehicle such as your house or a parking lot.", "Okay", "" );
	}
	return 1;
}

hook OnPlayerEndModelPreview( playerid, handleid )
{
	if ( handleid == PREVIEW_MODEL_VEHICLE )
	{
		SendServerMessage( playerid, "You have finished looking at the vehicle's preview." );
		ShowPlayerDialog( playerid, DIALOG_VEHDEALER_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Vehicle Dealership", "Purchase This Vehicle\nPreview Vehicle", "Select", "Back" );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

/* ** Functions ** */
stock ShowBuyableVehiclesList( playerid, dialogid = DIALOG_VEHDEALER, secondary_button[ ] = "Cancel" )
{
	static
		szCategory[ 16 * sizeof( g_BVCategories ) ];

	if ( szCategory[ 0 ] == '\0' ) {
		for( new i; i < sizeof( g_BVCategories ); i++ ) {
			format( szCategory, sizeof( szCategory ), "%s%s\n", szCategory, g_BVCategories[ i ] );
		}
	}
	return ShowPlayerDialog( playerid, dialogid, DIALOG_STYLE_LIST, "{FFFFFF}Vehicle Dealership", szCategory, "Select", secondary_button );
}

stock ShowBuyableVehiclesTypeDialog( playerid, type_id )
{
	static
		buyable_vehicles[ 1400 ], i;

	for ( i = 0, buyable_vehicles = ""COL_WHITE"Vehicle\t"COL_WHITE"Price ($)\n"; i < sizeof( g_BuyableVehicleData ); i ++ ) if ( g_BuyableVehicleData[ i ] [ E_TYPE ] == type_id ) {
		format( buyable_vehicles, sizeof( buyable_vehicles ), "%s%s%s\t"COL_GREEN"%s\n", buyable_vehicles, g_BuyableVehicleData[ i ] [ E_VIP ] ? ( COL_GOLD ) : ( COL_WHITE ), g_BuyableVehicleData[ i ] [ E_NAME ], cash_format( g_BuyableVehicleData[ i ] [ E_PRICE ] ) );
	}

	ShowPlayerDialog( playerid, DIALOG_VEHDEALER_BUY, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Vehicle Dealership", buyable_vehicles, "Options", "Cancel" );
	SetPVarInt( playerid, "vehicle_preview", type_id );
	return 1;
}

stock GetBuyableVehiclePrice( modelid ) {
	for ( new i = 0; i < sizeof ( g_BuyableVehicleData ); i ++ ) if ( g_BuyableVehicleData[ i ] [ E_MODEL ] == modelid ) {
		return g_BuyableVehicleData[ i ] [ E_PRICE ];
	}
	return 0;
}

stock GetClosestBoatPort( Float: current_x, Float: current_y, Float: current_z, &Float: dest_x, &Float: dest_y, &Float: dest_z, &Float: distance = FLOAT_INFINITY )
{
	static const
		Float: g_boatSpawnLocations[ ] [ 3 ] =
		{
			{ 2950.59080, -2000.382, -0.4033 }, { 1986.55710, -75.03830, -0.1938 },
			{ 2238.51780, 498.92970, 0.02490 }, { -626.54060, 832.18100, -0.1432 },
			{ -1448.5302, 679.33510, -0.2547 }, { -1710.0466, 241.71960, -0.3029 },
			{ -2181.0417, 2488.8093, -0.3036 }, { -2940.6545, 1238.2001, 0.11180 },
			{ -2974.5994, 543.54410, 0.44440 }, { -1341.1674, -2989.101, -0.1943 }
		}
	;

    new
    	final_port = 0;

    // get the closest port based off coordinates
	for ( new i = 0, Float: fTmp = 0.0; i < sizeof ( g_boatSpawnLocations ); i ++ )
	{
        if ( 0.0 < ( fTmp = GetDistanceBetweenPoints( current_x, current_y, current_z, g_boatSpawnLocations[ i ] [ 0 ], g_boatSpawnLocations[ i ] [ 1 ], g_boatSpawnLocations[ i ] [ 2 ] ) ) < distance )
        {
            distance = fTmp;
            final_port = i;
        }
    }

    // store the destination coordinates
    dest_x = g_boatSpawnLocations[ final_port ] [ 0 ];
    dest_y = g_boatSpawnLocations[ final_port ] [ 1 ];
    dest_z = g_boatSpawnLocations[ final_port ] [ 2 ];
	return 1;
}
