/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\vehicles\vehicle_modifications.pwn
 * Purpose: custom vehicle components (objects) for player vehicles
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */

/* ** Variables ** */
#define MAX_PIMPS 					( 10 )
#define MAX_COMPONENT_NAME			( 32 )

#define CATEGORY_SPOILERS 			( 0 )
#define CATEGORY_HOOD 				( 1 )
#define CATEGORY_BAGS				( 2 )
#define CATEGORY_LAMPS				( 3 )
#define CATEGORY_WHEELS				( 4 )
#define CATEGORY_BULLBAR			( 5 )
#define CATEGORY_FRONT_BUMPER		( 6 )
#define CATEGORY_REAR_BUMPER		( 7 )
#define CATEGORY_VENTS				( 8 )
#define CATEGORY_NEON				( 9 )
#define CATEGORY_MECHANIC_ITEMS 	( 10 )
#define CATEGORY_MILITARY_ITEMS 	( 11 )
#define CATEGORY_MISCELLANEOUS		( 12 )

#define PREVIEW_MODEL_COMPONENT 	( 10 ) // some random number

enum E_CAR_MODS
{
	E_CATEGORY,						E_LIMIT,						E_MODEL_ID,
	E_NAME[ MAX_COMPONENT_NAME ], 	E_PRICE
};

enum E_PIMP_DATA
{
	bool: E_CREATED[ MAX_PIMPS ],	E_OBJECT[ MAX_PIMPS ],			E_MODEL[ MAX_PIMPS ],
	Float: E_X[ MAX_PIMPS ],		Float: E_Y[ MAX_PIMPS ],		Float: E_Z[ MAX_PIMPS ],
	Float: E_RX[ MAX_PIMPS ],		Float: E_RY[ MAX_PIMPS ],		Float: E_RZ[ MAX_PIMPS ],
	E_SQL_ID[ MAX_PIMPS ],			bool: E_DISABLED[ MAX_PIMPS ]
};

new
	g_vehicleComponentsCategories[ ] [ MAX_COMPONENT_NAME ] = {
		"Spoilers", "Hood", "Bags", "Lamps", "Wheels", "Bullbar", "Front Bumper", "Rear Bumper", "Vents", "Neon", "Mechanic Items", "Military Items", "Miscellaneous"
	},
	g_vehicleComponentsData[ ] [ E_CAR_MODS ] =
	{
		// Spoilers
		{ CATEGORY_SPOILERS, 0, 1023, "Fury", 8000 },
		{ CATEGORY_SPOILERS, 0, 1001, "Win", 9000 },
		{ CATEGORY_SPOILERS, 0, 1000, "Pro", 10000 },
		{ CATEGORY_SPOILERS, 0, 1016, "Worx", 10000 },
		{ CATEGORY_SPOILERS, 0, 1058, "Alien - Stratum", 10000 },
		{ CATEGORY_SPOILERS, 0, 1014, "Champ", 11000 },
		{ CATEGORY_SPOILERS, 0, 1003, "Alpha", 12000 },
		{ CATEGORY_SPOILERS, 0, 1002, "Drag", 13000 },
		{ CATEGORY_SPOILERS, 0, 1015, "Race", 14000 },
		{ CATEGORY_SPOILERS, 0, 1060, "X-Flow - Stratum", 14000 },
		{ CATEGORY_SPOILERS, 0, 1049, "Alien - Flash", 14000 },
		{ CATEGORY_SPOILERS, 0, 1162, "Alien - Jester", 18000 },
		{ CATEGORY_SPOILERS, 0, 1164, "Alien - Uranus", 19000 },
		{ CATEGORY_SPOILERS, 0, 1147, "Alien - Elegy", 22000 },
		{ CATEGORY_SPOILERS, 0, 1050, "X-Flow - Flash", 23000 },
		{ CATEGORY_SPOILERS, 0, 1138, "Alien - Sultan", 25000 },
		{ CATEGORY_SPOILERS, 0, 1158, "X-Flow - Jester", 27000 },
		{ CATEGORY_SPOILERS, 0, 1163, "X-Flow - Uranus", 28000 },
		{ CATEGORY_SPOILERS, 0, 1146, "X-Flow - Elegy", 30000 },
		{ CATEGORY_SPOILERS, 0, 1139, "X-Flow - Sultan", 35000 },

		// Hood
		{ CATEGORY_HOOD, 0, 1011, "Race Scoop", 13000 },
		{ CATEGORY_HOOD, 0, 1004, "Champ Scoop", 15000 },
		{ CATEGORY_HOOD, 0, 1005, "Fury Scoop", 16000 },
		{ CATEGORY_HOOD, 0, 1012, "Worx Scoop", 23000 },

		// Bags
		{ CATEGORY_BAGS, 0, 11745, "Bag", 15000 },
		{ CATEGORY_BAGS, 0, 1279, "Tent Pack", 17000 },
		{ CATEGORY_BAGS, 0, 1550, "Money Bag", 35000 },
		{ CATEGORY_BAGS, 0, 1210, "Money Case", 25000 },
		{ CATEGORY_BAGS, 0, 1575, "Grey Drug Bag", 15000 },
		{ CATEGORY_BAGS, 0, 1576, "Orange Drug Bag", 15000 },
		{ CATEGORY_BAGS, 0, 1577, "Yellow Drug Bag", 15000 },
		{ CATEGORY_BAGS, 0, 1578, "Green Drug Bag", 15000 },
		{ CATEGORY_BAGS, 0, 1579, "Blue Drug Bag", 15000 },
		{ CATEGORY_BAGS, 0, 1580, "Red Drug Bag", 15000 },

		// Lamps
		{ CATEGORY_LAMPS, 0, 1013, "Round Fog", 15000 },
		{ CATEGORY_LAMPS, 0, 1024, "Square Fog", 25000 },

		// Wheels
		{ CATEGORY_WHEELS, 0, 1025, "Offroad", 25000 },
		{ CATEGORY_WHEELS, 0, 1080, "Switch", 25000 },
		{ CATEGORY_WHEELS, 0, 1077, "Classic", 30000 },
		{ CATEGORY_WHEELS, 0, 1073, "Shadow", 35000 },
		{ CATEGORY_WHEELS, 0, 1079, "Cutter", 35000 },
		{ CATEGORY_WHEELS, 0, 1085, "Atomic", 35000 },
		{ CATEGORY_WHEELS, 0, 1096, "Ahab", 35000 },
		{ CATEGORY_WHEELS, 0, 1078, "Twist", 40000 },
		{ CATEGORY_WHEELS, 0, 1081, "Grove", 40000 },
		{ CATEGORY_WHEELS, 0, 1084, "Trance", 45000 },
		{ CATEGORY_WHEELS, 0, 1075, "Rimshine", 45000 },
		{ CATEGORY_WHEELS, 0, 1074, "Mega", 45000 },
		{ CATEGORY_WHEELS, 0, 1076, "Wires", 50000 },
		{ CATEGORY_WHEELS, 0, 1098, "Access", 55000 },
		{ CATEGORY_WHEELS, 0, 1097, "Virtual", 65000 },
		{ CATEGORY_WHEELS, 0, 1082, "Import", 75000},
		{ CATEGORY_WHEELS, 0, 1327, "Large Wheel", 80000 },
		{ CATEGORY_WHEELS, 0, 1083, "Dollar", 100000 },

		// Bullbar
		{ CATEGORY_BULLBAR, 0, 1123, "Bullbar Chrome Bars", 30000 },
		{ CATEGORY_BULLBAR, 0, 1100, "Chrome Grill", 35000 },
		{ CATEGORY_BULLBAR, 0, 1125, "Bullbar Chrome Lights", 37000 },

		// Front Bumper
		{ CATEGORY_FRONT_BUMPER, 0, 1155, "Alien - Stratum", 15000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1160, "Alien - Jester", 20000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1166, "Alien - Uranus", 20000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1153, "Alien - Flash", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1157, "X-Flow - Stratum", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1171, "Alien - Elegy", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1181, "Slamin - Blade", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1185, "Slamin - Remington", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1190, "Slamin - Tornado", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1165, "X-Flow - Uranus", 30000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1169, "Alien - Sultan", 30000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1173, "X-Flow - Jester", 30000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1152, "X-Flow - Flash", 35000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1172, "X-Flow - Elegy", 35000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1170, "X-Flow - Sultan", 40000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1174, "Chrome - Broadway 1", 45000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1176, "Chrome - Broadway 2", 45000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1117, "Chrome - Slamvan", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1182, "Chrome - Blade", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1188, "Slamin - Savanna", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1189, "Chrome - Savanna",50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1191, "Chrome - Tornado", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1179, "Chrome - Remington", 55000 },

		// Rear Bumper
		{ CATEGORY_REAR_BUMPER, 0, 1154, "Alien - Stratum", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1159, "Alien - Jester", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1168, "Alien - Uranus", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1175, "Slamin - Broadway", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1150, "Alien - Flash", 18000 },
		{ CATEGORY_REAR_BUMPER, 0, 1149, "Alien - Elegy", 19000 },
		{ CATEGORY_REAR_BUMPER, 0, 1140, "X-Flow - Sultan", 20000 },
		{ CATEGORY_REAR_BUMPER, 0, 1178, "Slamin - Remington", 23000 },
		{ CATEGORY_REAR_BUMPER, 0, 1156, "X-Flow Straum", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1161, "X-Flow - Jester", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1183, "Slamin - Blade", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1186, "Slamin - Savanna", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1167, "X-Flow - Uranus", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1193, "Slamin - Tornado", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1151, "X-Flow - Flash", 28000 },
		{ CATEGORY_REAR_BUMPER, 0, 1148, "X-Flow - Elegy", 29000 },
		{ CATEGORY_REAR_BUMPER, 0, 1141, "Alien - Sultan", 30000 },
		{ CATEGORY_REAR_BUMPER, 0, 1177, "Slamin - Broadway", 35000 },
		{ CATEGORY_REAR_BUMPER, 0, 1180, "Chrome - Remington", 50000 },
		{ CATEGORY_REAR_BUMPER, 0, 1184, "Chrome - Blade", 50000 },
		{ CATEGORY_REAR_BUMPER, 0, 1187, "Chrome - Savanna", 50000 },
		{ CATEGORY_REAR_BUMPER, 0, 1192, "Chrome - Tornado", 50000 },

		// Vents
		{ CATEGORY_VENTS, 0, 1142, "Left Oval Vents", 4000 },
		{ CATEGORY_VENTS, 0, 1143, "Right Oval Vents", 4000 },
		{ CATEGORY_VENTS, 0, 1144, "Left Square Vents", 6000 },
		{ CATEGORY_VENTS, 0, 1145, "Right Square Vents", 6000 },
		{ CATEGORY_VENTS, 3, 914, "Large Air Vent", 250000 },

		// Neon
		{ CATEGORY_NEON, 0, 18647, "Red Neon", 200000 },
		{ CATEGORY_NEON, 0, 18648, "Blue Neon", 200000 },
		{ CATEGORY_NEON, 0, 18649, "Green Neon", 200000 },
		{ CATEGORY_NEON, 0, 18650, "Yellow Neon", 200000 },
		{ CATEGORY_NEON, 0, 18651, "Pink Neon", 200000 },
		{ CATEGORY_NEON, 0, 18652, "White Neon", 200000 },

		// Military Items
		{ CATEGORY_MILITARY_ITEMS, 0, 1654, "Dynamite", 8000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 19590, "Sword", 14000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 19832, "Ammo Box", 20000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 2040, "Ammo box closed", 20000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 2041, "Ammo box open", 20000 },
		{ CATEGORY_MILITARY_ITEMS, 1, 964, "Army crate", 40000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 11738, "Medikit", 135000 },

		// Mechanic Items
		{ CATEGORY_MECHANIC_ITEMS, 0, 18644, "Screwdriver", 1500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 18633, "Wrench", 2500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 18635, "Hammer", 2500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 1650, "Gas Can", 5000 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19621, "Oil Can", 7500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19816, "Oxygen Tank", 20000 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19921, "Toolbox", 23000 },
		{ CATEGORY_MECHANIC_ITEMS, 1, 19917, "Engine", 65000 },
		{ CATEGORY_MECHANIC_ITEMS, 1, 920, "Generator", 80000 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19631, "Sledge Hammer", 90000 },

		// Miscellaneous
		{ CATEGORY_MISCELLANEOUS, 0, 19309, "Taxi White", 2000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19310, "Taxi Black", 4000 },
		{ CATEGORY_MISCELLANEOUS, 0, 18632, "Fishing Rod", 8000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19624, "Suitcase", 15000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19314, "Bullhorn", 15000 },
		{ CATEGORY_MISCELLANEOUS, 0, 18646, "Police Light", 25000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19280, "Floodlight", 30000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19419, "Police Light Strip", 45000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19320, "Pumpkin", 45000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19306, "Red Flag", 50000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19307, "Blue Flag", 50000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19086, "Chainsaw Dildo", 69696},
		{ CATEGORY_MISCELLANEOUS, 0, 11704, "Devil Mask", 75000 },
		{ CATEGORY_MISCELLANEOUS, 2, 2985, "Mounted Minigun", 80000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19315, "Deer", 133769 },
		{ CATEGORY_MISCELLANEOUS, 0, 1609, "Turtle", 250000 },
		{ CATEGORY_MISCELLANEOUS, 1, 19601, "Snow Plough", 1500000 }
	},

	g_vehiclePimpData[ MAX_PLAYERS ] [ MAX_BUYABLE_VEHICLES ] [ E_PIMP_DATA ]
;

/* ** Hooks ** */
hook OnPlayerEditDynObject( playerid, objectid, response, Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz )
{
	if ( GetPVarType( playerid, "components_editing" ) != 0 )
	{
		new
	    	ownerid = INVALID_PLAYER_ID,
	    	vehicleid = GetPlayerVehicleID( playerid ),
	    	slotid = GetPVarInt( playerid, "components_editing" ),
	    	v = getVehicleSlotFromID( vehicleid, ownerid )
		;

		if ( v == -1 )
			return CancelEdit( playerid ), SendError( playerid, "You need to be in a buyable vehicle." );

		if ( playerid != ownerid )
			return CancelEdit( playerid ), SendError( playerid, "This vehicle does not belong to you." );

		if ( !g_vehiclePimpData[ ownerid ] [ v ] [ E_CREATED ] [ slotid ] )
			return CancelEdit( playerid ), SendError( playerid, "Internal Server Error (0x1C)." );

		if ( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] != objectid )
			return CancelEdit( playerid ), SendError( playerid, "Internal Server Error (0x2D)." );

		static
			Float: X, Float: Y, Float:Z, Float: Angle;

		if ( response == EDIT_RESPONSE_FINAL )
		{
			// Grab positions prior
			GetVehicleZAngle( vehicleid, Angle );
			GetVehiclePos( vehicleid, X, Y, Z );

			// Calculate offsets
			new
				Float: fDistance = VectorSize( x - X, y - Y, 0.0 ),
				Float: fAngle = Angle - atan2( y - Y, x - X ),
				Float: finalX = fDistance * floatcos( fAngle, degrees ),
				Float: finalY = fDistance * floatsin( -fAngle, degrees ),
				Float: finalZ = z - Z
			;

			// Get model size
			GetVehicleModelInfo( GetVehicleModel( vehicleid ), VEHICLE_MODEL_INFO_SIZE, X, Y, Z );

			// Half because we're using pretty much the radius, not circumference (way to look at it)
			X /= 2.0, Y /= 2.0;

			if ( floatabs( finalX ) > X + 0.35 ) {
				SendServerMessage( playerid, "The object breaches the X axis limit for this vehicle (%0.1f). It has been moved.", ( finalX = X + 0.35 ) );
			}

			if ( floatabs( finalY ) > Y + 0.35 ) {
				SendServerMessage( playerid, "The object breaches the Y axis limit for this vehicle (%0.1f). It has been moved.", ( finalY = Y + 0.35 ) );
			}

			if ( floatabs( finalZ ) > Z + 0.35 ) {
				SendServerMessage( playerid, "The object breaches the Z axis limit for this vehicle (%0.1f). It has been moved.", ( finalZ = Z + 0.35 ) );
			}

			// Readjust variables
			g_vehiclePimpData[ ownerid ] [ v ] [ E_X ] [ slotid ] = finalX;
			g_vehiclePimpData[ ownerid ] [ v ] [ E_Y ] [ slotid ] = finalY;
			g_vehiclePimpData[ ownerid ] [ v ] [ E_Z ] [ slotid ] = finalZ;
			g_vehiclePimpData[ ownerid ] [ v ] [ E_RX ] [ slotid ] = rx;
			g_vehiclePimpData[ ownerid ] [ v ] [ E_RY ] [ slotid ] = ry;
			g_vehiclePimpData[ ownerid ] [ v ] [ E_RZ ] [ slotid ] = rz - Angle;

			format( szNormalString, sizeof( szNormalString ), "UPDATE `COMPONENTS` SET `X`=%f,`Y`=%f,`Z`=%f,`RX`=%f,`RY`=%f,`RZ`=%f WHERE `ID`=%d", finalX, finalY, finalZ, rx, ry, rz - Angle, g_vehiclePimpData[ ownerid ] [ v ] [ E_SQL_ID ] [ slotid ] );
			mysql_single_query( szNormalString );

			//DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] );
			//g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] = CreateDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_MODEL ] [ slotid ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
			AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ], vehicleid, finalX, finalY, finalZ, rx, ry, rz - Angle );

			GetVehiclePos( vehicleid, X, Y, Z );
			return SetVehiclePos( vehicleid, X, Y, Z + 0.05 );
		}
		else if ( response == EDIT_RESPONSE_CANCEL )
		{
			//DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] );
			//g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] = CreateDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_MODEL ] [ slotid ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
			AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ], vehicleid,
											g_vehiclePimpData[ ownerid ] [ v ] [ E_X ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_Y ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_Z ] [ slotid ],
											g_vehiclePimpData[ ownerid ] [ v ] [ E_RX ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_RY ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_RZ ] [ slotid ] );

			// Sync new position
			if ( GetVehiclePos( vehicleid, X, Y, Z ) ) {
				SetVehiclePos( vehicleid, X, Y, Z + 0.05 );
			}
		}
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_COMPONENTS_CATEGORY ) && response ) {
		SetPVarInt( playerid, "components_category", listitem );
		return ShowPlayerVehicleComponents( playerid, listitem );
	}
	else if ( dialogid == DIALOG_COMPONENTS )
	{
		SetPVarInt( playerid, "components_item", listitem );
		if ( response )
		{
			ShowPlayerDialog(playerid, DIALOG_COMPONENTS_RESPONSE, DIALOG_STYLE_LIST, ""COL_WHITE"Pimp My Ride", "Purchase Component\nPreview Component", "Select", "Back" );
		}
		else
		{
			return cmd_garage( playerid, "vehicle pimp" );
		}
	}

	else if ( dialogid == DIALOG_COMPONENTS_RESPONSE )
	{
		new
			iItem = GetPVarInt( playerid, "components_item" ),
			iComponent = GetPVarInt( playerid, "components_category" );

		if ( response )
		{
			switch( listitem )
			{
				case 0:
				{
					for( new i = 0, x = 0; i < sizeof( g_vehicleComponentsData ); i++ ) if ( g_vehicleComponentsData[ i ] [ E_CATEGORY ] == iComponent )
					{
						if ( iItem == x++ )
						{
						    if ( !IsPlayerInAnyVehicle( playerid ) )
						    	return SendError( playerid, "You need to be in a vehicle to use this command." );

							if ( GetPlayerCash( playerid ) < g_vehicleComponentsData[ i ] [ E_PRICE ] )
								return SendError( playerid, "You need %s to purchase this vehicle component.", cash_format( g_vehicleComponentsData[ i ] [ E_PRICE ] ) );

						    if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER )
						    	return SendError( playerid, "You need to be a driver to use this command." );

					        new
					        	ownerid = INVALID_PLAYER_ID,
					        	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
							;

							if ( vehicleid == -1 )
								return SendError( playerid, "This vehicle isn't a buyable vehicle." );

							if ( playerid != ownerid )
								return SendError( playerid, "This vehicle does not belong to you." );

							if ( GetVehicleCustomComponents( ownerid, vehicleid ) >= GetPlayerPimpVehicleSlots( ownerid ) )
								return SendError( playerid, "You cannot purchase more than %d vehicle components.", GetPlayerPimpVehicleSlots( ownerid ) );

							new
								slotid = GetVehicleComponentSlot( ownerid, vehicleid );

							if ( slotid == -1 )
								return SendError( playerid, "You cannot add more than %d components to your vehicle.", MAX_PIMPS );

							// make sure the person is above the limit
							if ( g_vehicleComponentsData[ i ] [ E_LIMIT ] != 0 )
							{
								new
									instances = 0;

								for( new p = 0; p < MAX_PIMPS; p++ )
									if ( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ p ] && g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_MODEL ] [ p ] == g_vehicleComponentsData[ i ] [ E_MODEL_ID ] )
										instances ++;

								if ( instances >= g_vehicleComponentsData[ i ] [ E_LIMIT ] )
									return SendError( playerid, "You can place a %s a maximum of %d time(s).", g_vehicleComponentsData[ i ] [ E_NAME ], g_vehicleComponentsData[ i ] [ E_LIMIT ] );
							}

							new
								Float: X, Float: Y, Float: Z;

							GivePlayerCash( playerid, -g_vehicleComponentsData[ i ] [ E_PRICE ] );

							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ slotid ] = true;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ slotid ] = false;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ slotid ] = g_vehicleComponentsData[ i ] [ E_MODEL_ID ];
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_X ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Y ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Z ] [ slotid ] = 1.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RX ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RY ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RZ ] [ slotid ] = 0.0;

							format( szNormalString, sizeof( szNormalString ), "INSERT INTO `COMPONENTS` (`VEHICLE_ID`,`MODEL`,`X`,`Y`,`Z`,`RX`,`RY`,`RZ`) VALUES (%d,%d,0.0,0.0,1.0,0.0,0.0,0.0)", g_vehicleData[ ownerid ] [ vehicleid ] [ E_SQL_ID ], g_vehicleComponentsData[ i ] [ E_MODEL_ID ] );
							mysql_function_query( dbHandle, szNormalString, true, "OnPlayerCreateVehicleComponent", "ddd", playerid, vehicleid, slotid );

							GetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z );
							SetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z + 0.05 );

							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ] = CreateDynamicObject( g_vehicleComponentsData[ i ] [ E_MODEL_ID ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = GetVehicleVirtualWorld( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ]) );
							AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ], g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], 0.0, 0.0, 1.0, 0.0, 0.0, 0.0 );
							return SendServerMessage( playerid, "You have bought a "COL_GREY"%s"COL_WHITE" for "COL_GOLD"%s"COL_WHITE".", g_vehicleComponentsData[ i ] [ E_NAME ], cash_format( g_vehicleComponentsData[ i ] [ E_PRICE ] ) );
						}
					}
				}
				case 1:
				{
					for( new i = 0, x = 0; i < sizeof( g_vehicleComponentsData ); i++ ) if ( g_vehicleComponentsData[ i ] [ E_CATEGORY ] == iComponent )
					{
						if ( iItem == x++ )
						{
							return ShowPlayerModelPreview( playerid, PREVIEW_MODEL_COMPONENT, "Component Preview", g_vehicleComponentsData[ i ] [ E_MODEL_ID ], .bgcolor = 0xFFFFFF70 );
						}
					}

				}
			}
		}
		else
		{
			return cmd_garage( playerid, "vehicle pimp" );
		}
	}
	else if ( ( dialogid == DIALOG_COMPONENT_MENU ) && response )
	{
		new
	    	ownerid = INVALID_PLAYER_ID,
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( vehicleid == -1 )
			return SendError( playerid, "This vehicle isn't a buyable vehicle." );

		if ( playerid != ownerid )
			return SendError( playerid, "This vehicle does not belong to you." );

		for( new i = 0, x = 0; i < MAX_PIMPS; i++ ) if ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ i ] ) {
			if ( listitem == x++ ) {
				return ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i );
			}
		}
	}
	else if ( ( dialogid == DIALOG_COMPONENT_EDIT ) && response )
	{
		new
	    	ownerid = INVALID_PLAYER_ID,
	    	i = GetPVarInt( playerid, "components_editing" ),
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( vehicleid == -1 )
			return SendError( playerid, "This vehicle isn't a buyable vehicle." );

		if ( playerid != ownerid )
			return SendError( playerid, "This vehicle does not belong to you." );

		switch( listitem )
		{
			case 0: // Disable
			{
				if ( ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ] = !g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ] ) == false )
				{
					new
						Float: X, Float: Y, Float: Z;

					// Recreate object
					g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] = CreateDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = GetVehicleVirtualWorld( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ] ) );

					// Attach object to vehicle
					AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ], g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ],
										g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_X ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Y ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Z ] [ i ],
										g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RX ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RY ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RZ ] [ i ] );

					// Reposition vehicle
					GetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z );
					SetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z + 0.05 );

					SendServerMessage( playerid, "You have successfully enabled your vehicle component" );
				}
				else
				{
					DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] );
					g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] = -1;
					SendServerMessage( playerid, "You have successfully disabled your vehicle component" );
				}

				mysql_single_query( sprintf( "UPDATE `COMPONENTS` SET `DISABLED`=%d WHERE `ID`=%d", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_SQL_ID ] [ i ] ) );
				return ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i );
			}
			case 1: // Edit
			{
				new
					Float: X, Float: Y, Float: Z, Float: Angle;

				GetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z );
				GetVehicleZAngle( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], Angle );
				DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] );

				// printf("Destroyed %d", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] );

				X += g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_X ] [ i ];
				Y += g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Y ] [ i ];
				Z += g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Z ] [ i ];

				new
					iObject = CreateDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ], X, Y, Z, g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RX ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RY ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RZ ] [ i ] - Angle, .worldid = GetVehicleVirtualWorld( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ] ) );

				// printf("%d = CreateDynamicObject( %d, %f, %f, %f, %f, %f, %f )", iObject, g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ], X, Y, Z, g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RX ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RY ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RZ ] [ i ] - Angle );

				if ( ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] = iObject ) ) {
					GetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z );
					SetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z + 0.05 );

					EditDynamicObject( playerid, iObject );
 				}
			}
			case 2: // sell
			{
				new
					pimpid;

				for( ; pimpid < sizeof( g_vehicleComponentsData ); pimpid++ )
					if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
						break;

				new
					sellPrice = floatround( g_vehicleComponentsData[ pimpid ] [ E_PRICE ] * 0.5 );

				ShowPlayerDialog( playerid, DIALOG_COMPONENTS_SELL, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Sell Components", sprintf( ""COL_WHITE"Are you sure you want to sell your "COL_GREY"%s "COL_WHITE"for "COL_GOLD"%s?\n", g_vehicleComponentsData[ pimpid ] [ E_NAME ], cash_format( sellPrice ) ), "Sell", "Back" );
			}
		}
	}
	else if ( dialogid == DIALOG_COMPONENTS_SELL )
	{
		new
	    	ownerid = INVALID_PLAYER_ID,
	    	i = GetPVarInt( playerid, "components_editing" ),
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( vehicleid == -1 )
			return SendError( playerid, "This vehicle isn't a buyable vehicle." );

		if ( playerid != ownerid )
			return SendError( playerid, "This vehicle does not belong to you." );

		if ( ! response)
		{
			for( new y = 0, x = 0; y < MAX_PIMPS; y++ ) if ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ y ] ) {
				if ( listitem == x++ ) {
					return ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i );
				}
			}
		}
		else
		{
			new
				pimpid;

			for( ; pimpid < sizeof( g_vehicleComponentsData ); pimpid++ )
				if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
					break;

			if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] != g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
				return SendError( playerid, "You cannot sell this component as it no longer exists." );

			new
				sellPrice = floatround( g_vehicleComponentsData[ pimpid ] [ E_PRICE ] * 0.5 );

			GivePlayerCash( playerid, sellPrice );
			DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] );

			g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] = -1;
			g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ i ] = false;

			mysql_single_query( sprintf( "DELETE FROM `COMPONENTS` WHERE `ID`=%d", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_SQL_ID ] [ i ] ) );
			SendServerMessage( playerid, "You have sold your "COL_GREY"%s"COL_WHITE" for "COL_GOLD"%s"COL_WHITE".", g_vehicleComponentsData[ pimpid ] [ E_NAME ], cash_format( sellPrice ) );
		}
		return 1;
	}
	return 1;
}

/* ** SQL Threads ** */
hook OnVehicleComponentsLoad( playerid, vid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	if ( !g_vehicleData[ playerid ] [ vid ] [ E_CREATED ] )
		return 0;

	new
		rows, fields, i = -1, cid
	;

	cache_get_data( rows, fields );

	if ( rows )
	{
		while( ++i < rows )
		{
			for( cid = 0; cid < MAX_PIMPS; cid++ )
				if ( !g_vehiclePimpData[ playerid ] [ vid ] [ E_CREATED ] [ cid ] ) break;

			if ( cid >= MAX_PIMPS )
				continue;

			if ( g_vehiclePimpData[ playerid ] [ vid ] [ E_CREATED ] [ cid ] )
			    continue;

			g_vehiclePimpData[ playerid ] [ vid ] [ E_CREATED ] [ cid ] = true;
			g_vehiclePimpData[ playerid ] [ vid ] [ E_SQL_ID ] [ cid ] = cache_get_field_content_int( i, "ID", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_MODEL ] [ cid ] = cache_get_field_content_int( i, "MODEL", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_X ] [ cid ] = cache_get_field_content_float( i, "X", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_Y ] [ cid ] = cache_get_field_content_float( i, "Y", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_Z ] [ cid ] = cache_get_field_content_float( i, "Z", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_RX ] [ cid ] = cache_get_field_content_float( i, "RX", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_RY ] [ cid ] = cache_get_field_content_float( i, "RY", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_RZ ] [ cid ] = cache_get_field_content_float( i, "RZ", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_DISABLED ] [ cid ] = !!cache_get_field_content_int( i, "DISABLED", dbHandle );

			DestroyDynamicObject( g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ] );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ] = -1;

			if ( g_vehiclePimpData[ playerid ] [ vid ] [ E_DISABLED ] [ cid ] == false )
			{
				g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ] = CreateDynamicObject( g_vehiclePimpData[ playerid ] [ vid ] [ E_MODEL ] [ cid ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = GetVehicleVirtualWorld( g_vehicleData[ playerid ] [ vid ] [ E_VEHICLE_ID ] ) );
				AttachDynamicObjectToVehicle( g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ], g_vehicleData[ playerid ] [ vid ] [ E_VEHICLE_ID ],
											g_vehiclePimpData[ playerid ] [ vid ] [ E_X ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_Y ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_Z ] [ cid ],
											g_vehiclePimpData[ playerid ] [ vid ] [ E_RX ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_RY ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_RZ ] [ cid ] );
			}
		}
	}
	return 1;
}

thread OnPlayerCreateVehicleComponent( playerid, vehicleid, slotid )
{
	g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_SQL_ID ] [ slotid ] = cache_insert_id( );
	return 1;
}

/* ** Functions ** */
stock GetVehicleComponentSlot( playerid, vehicleid ) {

	for( new id = 0; id < MAX_PIMPS; id++ ) {
		if ( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ id ] == false ) {
			return id;
		}
	}
	return -1;
}

stock ShowPlayerVehicleComponents( playerid, categoryid ) {

	erase( szLargeString );

	for( new i = 0; i < sizeof( g_vehicleComponentsData ); i++ ) if ( g_vehicleComponentsData[ i ] [ E_CATEGORY ] == categoryid ) {
		format( szLargeString, sizeof( szLargeString ), "%s%s\t"COL_GOLD"%s\n", szLargeString, g_vehicleComponentsData[ i ] [ E_NAME ], cash_format( g_vehicleComponentsData[ i ] [ E_PRICE ] ) );
	}
	return ShowPlayerDialog( playerid, DIALOG_COMPONENTS, DIALOG_STYLE_TABLIST, sprintf( "Pimp My Ride - %s", g_vehicleComponentsCategories[ categoryid ] ), szLargeString, "Purchase", "Back" );
}

stock DestroyVehicleCustomComponents( playerid, vehicleid, bool: destroy_db = false )
{
	for( new slotid = 0; slotid < MAX_PIMPS; slotid++ ) {
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ slotid ] = false;
		DestroyDynamicObject( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ] );
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ] = -1;
	}

	if ( destroy_db ) {
		mysql_single_query( sprintf( "DELETE FROM `COMPONENTS` WHERE `VEHICLE_ID`=%d", g_vehicleData[ playerid ] [ vehicleid ] [ E_SQL_ID ] ) );
	}
}

stock ReplaceVehicleCustomComponents( ownerid, v, bool: recreate_obj = false ) {

	for( new slotid; slotid < MAX_PIMPS; slotid++ ) if ( g_vehiclePimpData[ ownerid ] [ v ] [ E_CREATED ] [ slotid ] && !g_vehiclePimpData[ ownerid ] [ v ] [ E_DISABLED ] ) {
		// Recreate object
		if ( recreate_obj ) {
			DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] );
			g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] = CreateDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_MODEL ] [ slotid ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
		}

		// Attach object to vehicle
		AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ], g_vehicleData[ ownerid ] [ v ] [ E_VEHICLE_ID ],
							g_vehiclePimpData[ ownerid ] [ v ] [ E_X ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_Y ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_Z ] [ slotid ],
							g_vehiclePimpData[ ownerid ] [ v ] [ E_RX ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_RY ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_RZ ] [ slotid ] );

		// Update virtual world
		Streamer_SetIntData( STREAMER_TYPE_OBJECT, g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ], E_STREAMER_WORLD_ID, GetVehicleVirtualWorld( g_vehicleData[ ownerid ] [ v ] [ E_VEHICLE_ID ] ) );
	}
}

stock GetVehicleCustomComponents( playerid, vehicleid ) {
	new
		count = 0;

	for( new i = 0; i < MAX_PIMPS; i++ )
		if ( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ i ] )
			count ++;

	return count;
}

stock ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i )
{
	new
		pimpid;

	for( ; pimpid < sizeof( g_vehicleComponentsData ); pimpid++ )
		if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
			break;

	if ( !( 0 <= pimpid < sizeof( g_vehicleComponentsData ) ) || g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] != g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
		return SendError( playerid, "You cannot sell this component as it no longer exists." );

	new
		sellPrice = floatround( g_vehicleComponentsData[ pimpid ] [ E_PRICE ] * 0.5 );

	SetPVarInt( playerid, "components_editing", i );
	return ShowPlayerDialog( playerid, DIALOG_COMPONENT_EDIT, DIALOG_STYLE_TABLIST, "Vehicle Components", sprintf( "%s Component\t\nEdit Component\t\nSell Component\t"COL_GOLD"%s", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ] ? ( "Enable" ) : ( "Disable" ), cash_format( sellPrice ) ), "Select", "Cancel" );
}

stock ShowVehicleComponentCategories( playerid )
{
	static
		szCategory[ sizeof( g_vehicleComponentsCategories ) * 12 ];

	if ( szCategory[ 0 ] == '\0') {
		for( new i = 0; i < sizeof( g_vehicleComponentsCategories ); i++ ) {
			format( szCategory, sizeof( szCategory ), "%s%s\n", szCategory, g_vehicleComponentsCategories[ i ] );
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_COMPONENTS_CATEGORY, DIALOG_STYLE_LIST, "Pimp My Ride - Categories", szCategory, "Select", "Cancel" );
}

hook OnPlayerEndModelPreview( playerid, handleid )
{
	if ( handleid == PREVIEW_MODEL_COMPONENT )
	{
		SendServerMessage( playerid, "You have finished looking at this vehicle modification preview." );
		ShowPlayerDialog(playerid, DIALOG_COMPONENTS_RESPONSE, DIALOG_STYLE_LIST, ""COL_WHITE"Pimp My Ride", "Purchase Component\nPreview Component", "Select", "Back" );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}
