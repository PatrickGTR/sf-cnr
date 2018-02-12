
/*
 * Irresistible Gaming (c) 2018
 * Developed by ThreeKingz, edited by Lorenc Pekaj
 * Module: fireworks.inc
 * Purpose: mathematical fireworks implementation in-game
 */

/* ** Defines ** */
#define MAX_FIREWORKS										 		40
#define FW_MAX_FLARES_PER_LAUNCH									100
#define FW_TICK_RATE 												50 //in milliseconds
#define FW_INVALID_HANDLE											-1
#define FW_VISIBLE_RANGE 											500.0 //Drawdistance for the flare objects.
#define FW_EXPLOSION_TYPE											9
#define FW_EXPLOSION_RANGE											300.0

/*
	Exceeding in ranges, tick rates or number of flares could cause the ackslimit to be broken
	freezing the server.
*/

#define STYLE_AR_SPIRAL 											( 0 )
#define STYLE_FOUNTAIN 												( 1 )
#define STYLE_CIRCLE 												( 2 )

/* ** Variables ** */
enum FW_Stages
{
	FW_S_CREATE_FLARES,
	FW_S_MOVE_FLARES
};

enum FW_subscripts
{
	bool: FW_IS_FLARE_MOVING[ FW_MAX_FLARES_PER_LAUNCH ],
	Float: FW_FLARE_TIME_ELAPSED[ FW_MAX_FLARES_PER_LAUNCH ],
	FW_FLARE_OBJECT_ID[ FW_MAX_FLARES_PER_LAUNCH ],

	Float: FW_ORIGIN_X, 		Float: FW_ORIGIN_Y, 		Float: FW_ORIGIN_Z,
	Float: FW_ELEVATION_ANGLE, 	Float: FW_INITIAL_SPEED,	Float: FW_GLOBAL_TIME_ELAPSED,

	Float: FW_MAX_HEIGHT, 		Float: FW_GRAVITY,  		Float: FW_FL_TIME_DELAY,

	// for spiral only
	Float: FW_INCREMENT, 		Float: FW_CONSTANT_XY, 		Float: FW_CONSTANT_Z,

	FW_STYLE, 			FW_Stages: FW_CURRENT_STAGE,

	FW_OBJECT_DESTROYED_COUNT, 	FW_OBJECT_SPAWNED_COUNT, 	FW_TIMER_ID,
	FW_TOTAL_FLARE_OBJECTS, 	FW_FL_TIME_DELAY_COUNT, 	FW_FL_TIME_DELAY_RESULT
};

new
	FW_Data[MAX_FIREWORKS] [FW_subscripts],
	Iterator:fireworks<MAX_FIREWORKS>
;

/* ** Functions ** */
stock ResetHandleFields(handle)
{
	if(handle >= MAX_FIREWORKS)
		return false;

	if(!Iter_Contains(fireworks, handle))
		return false;

	FW_Data[handle][FW_ORIGIN_X] = 0.0;
	FW_Data[handle][FW_ORIGIN_Y] = 0.0;
	FW_Data[handle][FW_ORIGIN_Z] = 0.0;
	FW_Data[handle][FW_ELEVATION_ANGLE] = 0.0;
	FW_Data[handle][FW_GRAVITY] = 0.0;
	FW_Data[handle][FW_INITIAL_SPEED] = 0.0;
	FW_Data[handle][FW_MAX_HEIGHT] = 0.0;
	FW_Data[handle][FW_FL_TIME_DELAY] = 0.0;
	FW_Data[handle][FW_CONSTANT_Z] = 0.0;
	FW_Data[handle][FW_CONSTANT_XY] = 0.0;
	FW_Data[handle][FW_INCREMENT] = 0.0;
	FW_Data[handle][FW_TOTAL_FLARE_OBJECTS] = 0;
	FW_Data[handle][FW_GLOBAL_TIME_ELAPSED] = 0;

	FW_Data[handle][FW_OBJECT_DESTROYED_COUNT] = 0;
	FW_Data[handle][FW_OBJECT_SPAWNED_COUNT] = 0;
	FW_Data[handle][FW_FL_TIME_DELAY_COUNT] = 0;
	FW_Data[handle][FW_FL_TIME_DELAY_RESULT] = 0;
	FW_Data[handle][FW_CURRENT_STAGE] = FW_S_CREATE_FLARES;
	for(new i = 0; i < FW_MAX_FLARES_PER_LAUNCH; i++)
	{
		FW_Data[handle][FW_IS_FLARE_MOVING][i] = false;
		FW_Data[handle][FW_FLARE_TIME_ELAPSED][i] = 0;
		DestroyDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i]);
		FW_Data[handle][FW_FLARE_OBJECT_ID][i] = INVALID_OBJECT_ID;
	}

	KillTimer(FW_Data[handle][FW_TIMER_ID]);
	FW_Data[handle][FW_TIMER_ID] = 0;
	Iter_Remove(fireworks, handle);
	return 1;
}

stock CreateFireworks(total_flares, style, Float:origin_x, Float:origin_y, Float:origin_z, Float:angle, Float:speed, Float:gravity, Float:time_delay, Float:max_height = 50.0, Float:increment = 12.0, Float:constant_xy = 10.0, Float:constant_z = 2.0)
{
	new handle = Iter_Free(fireworks);
	if(handle == FW_INVALID_HANDLE)
	{
		printf("[Fireworks] Max number of concurrent 'firework' handles has been reached. Increase MAX_FIREWORKS.");
		return FW_INVALID_HANDLE;
	}
	if(total_flares >= FW_MAX_FLARES_PER_LAUNCH)
	{
		printf("[Fireworks] The total number of flares is greater than the allowed limit. Current limit is: "#FW_MAX_FLARES_PER_LAUNCH"");
		return FW_INVALID_HANDLE;
	}
	//Resetting:
	FW_Data[handle][FW_TOTAL_FLARE_OBJECTS] = 0;
	FW_Data[handle][FW_GLOBAL_TIME_ELAPSED] = 0;
	FW_Data[handle][FW_OBJECT_DESTROYED_COUNT] = 0;
	FW_Data[handle][FW_OBJECT_SPAWNED_COUNT] = 0;
	FW_Data[handle][FW_FL_TIME_DELAY_COUNT] = 0;

	FW_Data[handle][FW_CURRENT_STAGE] = FW_S_CREATE_FLARES;
	for(new i = 0; i < FW_MAX_FLARES_PER_LAUNCH; i++)
	{
		FW_Data[handle][FW_IS_FLARE_MOVING][i] = false;
		FW_Data[handle][FW_FLARE_TIME_ELAPSED][i] = 0;
		FW_Data[handle][FW_FLARE_OBJECT_ID][i] = INVALID_OBJECT_ID;
	}

	FW_Data[handle][FW_ORIGIN_X] = origin_x;
	FW_Data[handle][FW_ORIGIN_Y] = origin_y;
	FW_Data[handle][FW_ORIGIN_Z] = origin_z;

	FW_Data[handle][FW_CONSTANT_Z] = constant_z;
	FW_Data[handle][FW_CONSTANT_XY] = constant_xy;
	FW_Data[handle][FW_INCREMENT] = increment;

	FW_Data[handle][FW_ELEVATION_ANGLE] = angle;
	FW_Data[handle][FW_GRAVITY] = gravity;
	FW_Data[handle][FW_INITIAL_SPEED] = speed;
	FW_Data[handle][FW_MAX_HEIGHT] = max_height;
	FW_Data[handle][FW_FL_TIME_DELAY] = time_delay;
	FW_Data[handle][FW_FL_TIME_DELAY_RESULT] = floatround(floatdiv(time_delay, 0.001 * FW_TICK_RATE));
	FW_Data[handle][FW_STYLE] = style;
	FW_Data[handle][FW_TOTAL_FLARE_OBJECTS] = total_flares;
	Iter_Add(fireworks, handle);
	return handle;
}

stock LaunchFireworks(handle)
{
	if(handle >= MAX_FIREWORKS)
	{
		printf("[Fireworks] An incorrect value was passed as a handle. (%d). (LaunchFireworks).", _:handle);
		return 0;
	}
	if(!Iter_Contains(fireworks, handle))
	{
		print("[Fireworks] An incorrect value was passed as a handle. CreateFirework must be used first.");
		return 0;
	}
	FW_Data[handle][FW_CURRENT_STAGE] = FW_S_CREATE_FLARES;
	FW_Data[handle][FW_TIMER_ID] = SetTimerEx("FW_UpdateTick", FW_TICK_RATE, true, "i", _:handle);
	return 1;
}

forward FW_UpdateTick(handle); public FW_UpdateTick(handle)
{
	switch(FW_Data[handle][FW_STYLE])
	{
		case STYLE_AR_SPIRAL:
		{
			switch(FW_Data[handle][FW_CURRENT_STAGE])
			{
				case FW_S_CREATE_FLARES:
				{
					new object_model = 0;
					new const total = FW_Data[handle][FW_TOTAL_FLARE_OBJECTS];
					for(new i = 0; i < total; i++)
					{
						switch(i & 3) //Same as i % 4 but faster.
						{
							case 0: object_model = 19297;
							case 1: object_model = 19298;
							case 2: object_model = 19296;
							case 3: object_model = 19295;
						}
						FW_Data[handle][FW_FLARE_OBJECT_ID][i] = CreateDynamicObject(object_model, FW_Data[handle][FW_ORIGIN_X], FW_Data[handle][FW_ORIGIN_Y], FW_Data[handle][FW_ORIGIN_Z], 0.0, 0.0, 0.0, -1, -1, -1, FW_VISIBLE_RANGE);
						FW_Data[handle][FW_FLARE_TIME_ELAPSED][i] = 0;
						FW_Data[handle][FW_IS_FLARE_MOVING][i] = false;
					}
					FW_Data[handle][FW_CURRENT_STAGE] = FW_S_MOVE_FLARES;
				}
				case FW_S_MOVE_FLARES:
				{
					new index = 0;
					new Float:p_constant_xy = FW_Data[handle][FW_CONSTANT_XY];
					new const Float:p_constant_z = FW_Data[handle][FW_CONSTANT_Z];
					new const Float:increment = FW_Data[handle][FW_INCREMENT];

					new const Float:test_expression_value = float(FW_Data[handle][FW_TOTAL_FLARE_OBJECTS]) * increment;
					if(FW_Data[handle][FW_OBJECT_SPAWNED_COUNT] != FW_Data[handle][FW_TOTAL_FLARE_OBJECTS])
					{
						if(FW_Data[handle][FW_FL_TIME_DELAY_COUNT] == FW_Data[handle][FW_FL_TIME_DELAY_RESULT])
						{
							new i = FW_Data[handle][FW_OBJECT_SPAWNED_COUNT];
							FW_Data[handle][FW_IS_FLARE_MOVING][i] = true;
							FW_Data[handle][FW_FL_TIME_DELAY_COUNT] = 0;
							FW_Data[handle][FW_OBJECT_SPAWNED_COUNT]++;
						}
					}
					for(new Float:i = 0; i < test_expression_value; i+=increment)
					{
						if(!IsValidDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][index])) continue;
						if(!FW_Data[handle][FW_IS_FLARE_MOVING][index]) continue;
						new Float:xpos = p_constant_xy * (i/180.0) * floatcos(floatdiv(i, 30.0)) - 30.0 + FW_Data[handle][FW_ORIGIN_X];
						new Float:ypos = p_constant_xy * (i/180.0) * floatsin(floatdiv(i, 30.0)) - 30.0 + FW_Data[handle][FW_ORIGIN_Y];
						new Float:zpos = p_constant_z * (i / 180.0) + FW_Data[handle][FW_MAX_HEIGHT];
						MoveDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][index], xpos, ypos, zpos, FW_Data[handle][FW_INITIAL_SPEED], 0.0, 0.0, 0.0);
						index++;
					}
					new Float:ct = (FW_Data[handle][FW_FL_TIME_DELAY] * FW_Data[handle][FW_TOTAL_FLARE_OBJECTS]);//An approximate
					if(FW_Data[handle][FW_GLOBAL_TIME_ELAPSED] >= ct)
					{
						new cur = 1;
						new total = FW_Data[handle][FW_TOTAL_FLARE_OBJECTS];
						for(new i = 0; i < total; i++)
						{
							new Float:Pos[3];
							GetDynamicObjectPos(FW_Data[handle][FW_FLARE_OBJECT_ID][i], Pos[0], Pos[1], Pos[2]);
							if(total % cur == 0)
							{
								CreateExplosion(Pos[0], Pos[1], Pos[2], FW_EXPLOSION_TYPE, FW_EXPLOSION_RANGE);
							}
							DestroyDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i]);
							cur++;
						}
						ResetHandleFields(handle);
					}
				}
			}
		}

		case STYLE_FOUNTAIN:
		{
			switch(FW_Data[handle][FW_CURRENT_STAGE])
			{
				case FW_S_CREATE_FLARES:
				{
					new object_model = 0;
					FW_Data[handle][FW_ORIGIN_Z] -= 3.0;
					for(new i = 0; i < FW_Data[handle][FW_TOTAL_FLARE_OBJECTS]; i++)
					{
						switch(i % 4)
						{
							case 0: object_model = 19297;
							case 1: object_model = 19298;
							case 2: object_model = 19296;
							case 3: object_model = 19295;
						}
						FW_Data[handle][FW_FLARE_OBJECT_ID][i] = CreateDynamicObject(object_model, FW_Data[handle][FW_ORIGIN_X], FW_Data[handle][FW_ORIGIN_Y], FW_Data[handle][FW_ORIGIN_Z], 0.0, 0.0, 0.0, -1, -1, -1, FW_VISIBLE_RANGE);
						FW_Data[handle][FW_FLARE_TIME_ELAPSED][i] = 0;
						FW_Data[handle][FW_IS_FLARE_MOVING][i] = false;
					}
					FW_Data[handle][FW_CURRENT_STAGE] = FW_S_MOVE_FLARES;
					new const Float:vi_z = FW_Data[handle][FW_INITIAL_SPEED] * floatsin(FW_Data[handle][FW_ELEVATION_ANGLE], degrees);
					FW_Data[handle][FW_MAX_HEIGHT] = floatdiv((vi_z*vi_z), 2.0 * FW_Data[handle][FW_GRAVITY]) + FW_Data[handle][FW_ORIGIN_Z];
				}
				case FW_S_MOVE_FLARES:
				{
					if(FW_Data[handle][FW_OBJECT_DESTROYED_COUNT] >= FW_Data[handle][FW_TOTAL_FLARE_OBJECTS])
					{
						ResetHandleFields(handle);
						return 0;
					}

					new const Float:elevation_angle = FW_Data[handle][FW_ELEVATION_ANGLE];
					new const Float:vi_z = FW_Data[handle][FW_INITIAL_SPEED] * floatsin(FW_Data[handle][FW_ELEVATION_ANGLE], degrees);
					new const Float:gravity = FW_Data[handle][FW_GRAVITY];
					new const total_flares = FW_Data[handle][FW_TOTAL_FLARE_OBJECTS];

					if(FW_Data[handle][FW_OBJECT_SPAWNED_COUNT] != total_flares)
					{
						if(FW_Data[handle][FW_FL_TIME_DELAY_COUNT] == FW_Data[handle][FW_FL_TIME_DELAY_RESULT])
						{
							new i = FW_Data[handle][FW_OBJECT_SPAWNED_COUNT];
							FW_Data[handle][FW_IS_FLARE_MOVING][i] = true;
							FW_Data[handle][FW_FL_TIME_DELAY_COUNT] = 0;
							FW_Data[handle][FW_OBJECT_SPAWNED_COUNT]++;
						}
					}
					new Float:angle_step = floatdiv(360.0, float(total_flares));
					for(new i = 0; i < total_flares; i++)
					{
						if(!IsValidDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i])) continue;
						if(!FW_Data[handle][FW_IS_FLARE_MOVING][i]) continue;


						new const Float:time = FW_Data[handle][FW_FLARE_TIME_ELAPSED][i];
						new const Float:vx = (FW_Data[handle][FW_INITIAL_SPEED] * floatcos(360.0 * floatsin(i * elevation_angle, degrees) * angle_step, degrees)) + floatdiv(float(i), float(total_flares));
						new const Float:vy = (FW_Data[handle][FW_INITIAL_SPEED] * floatsin(360.0 * floatcos(-i * elevation_angle, degrees) * angle_step, degrees)) + floatdiv(float(i), float(total_flares));
						new const Float:xpos = vx * time * floatsin(FW_Data[handle][FW_FLARE_TIME_ELAPSED][i], degrees) + FW_Data[handle][FW_ORIGIN_X];
						new const Float:ypos = vy * time * floatsin(FW_Data[handle][FW_FLARE_TIME_ELAPSED][i], degrees)  + FW_Data[handle][FW_ORIGIN_Y];
						new const Float:zpos = vi_z * time - (0.5) * gravity * (time*time) + FW_Data[handle][FW_ORIGIN_Z];
						new const Float:vf_z = vi_z - gravity * time;

						if((vf_z < 0.0 ) && zpos < (FW_Data[handle][FW_MAX_HEIGHT] - fRandomEx(6.0, 10.0)))
						{
							CreateExplosion(xpos, ypos, zpos, FW_EXPLOSION_TYPE, FW_EXPLOSION_RANGE);
							DestroyDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i]);
							FW_Data[handle][FW_FLARE_TIME_ELAPSED][i] = 0;
							FW_Data[handle][FW_OBJECT_DESTROYED_COUNT]++;
						}
						new const Float:v = VectorSize(vx, vy, vf_z);
						MoveDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i], xpos, ypos, zpos, v/2, 0.0, 0.0, 0.0);
						FW_Data[handle][FW_FLARE_TIME_ELAPSED][i] += FW_TICK_RATE * 0.001; //Adjusting
						angle_step += 0.0001;
					}
					FW_Data[handle][FW_INITIAL_SPEED]+= 0.001;
				}
			}
		}

		case STYLE_CIRCLE:
		{
			switch(FW_Data[handle][FW_CURRENT_STAGE])
			{
				case FW_S_CREATE_FLARES:
				{
					new object_model = 0;
					for(new i = 0; i < FW_Data[handle][FW_TOTAL_FLARE_OBJECTS]; i++)
					{
						switch(i % 4)
						{
							case 0: object_model = 19297;
							case 1: object_model = 19298;
							case 2: object_model = 19296;
							case 3: object_model = 19295;
						}
						FW_Data[handle][FW_FLARE_OBJECT_ID][i] = CreateDynamicObject(object_model, FW_Data[handle][FW_ORIGIN_X], FW_Data[handle][FW_ORIGIN_Y], FW_Data[handle][FW_ORIGIN_Z], 0.0, 0.0, 0.0, -1, -1, -1, FW_VISIBLE_RANGE);
					}
					FW_Data[handle][FW_CURRENT_STAGE] = FW_S_MOVE_FLARES;
					new const Float:vi_z = FW_Data[handle][FW_INITIAL_SPEED] * floatsin(FW_Data[handle][FW_ELEVATION_ANGLE], degrees);
					FW_Data[handle][FW_MAX_HEIGHT] = floatdiv((vi_z*vi_z), 2.0 * FW_Data[handle][FW_GRAVITY]) + FW_Data[handle][FW_ORIGIN_Z];
				}
				case FW_S_MOVE_FLARES:
				{
					if(FW_Data[handle][FW_OBJECT_DESTROYED_COUNT] >= FW_Data[handle][FW_TOTAL_FLARE_OBJECTS])
					{
						ResetHandleFields(handle);
						return 0;
					}
					new const Float:angle_step = floatdiv(360.0, float(FW_Data[handle][FW_TOTAL_FLARE_OBJECTS])); //XY angle step in degrees
					new const Float:vi_z = FW_Data[handle][FW_INITIAL_SPEED] * floatsin(FW_Data[handle][FW_ELEVATION_ANGLE], degrees);
					new const Float:time = FW_Data[handle][FW_GLOBAL_TIME_ELAPSED];

					new const Float:gravity = FW_Data[handle][FW_GRAVITY];
					for(new i = 0; i < FW_Data[handle][FW_TOTAL_FLARE_OBJECTS]; i++)
					{
						if(!IsValidDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i])) continue;
						new const Float:vx = (FW_Data[handle][FW_INITIAL_SPEED] * floatcos(FW_Data[handle][FW_ELEVATION_ANGLE], degrees)) * floatcos(float(i)*angle_step, degrees);
						new const Float:vy = (FW_Data[handle][FW_INITIAL_SPEED] * floatcos(FW_Data[handle][FW_ELEVATION_ANGLE], degrees)) * floatsin(float(i)*angle_step, degrees);
						new const Float:xpos = vx * time + FW_Data[handle][FW_ORIGIN_X];
						new const Float:ypos = vy * time + FW_Data[handle][FW_ORIGIN_Y];
						new const Float:zpos = vi_z * time - (0.5) * gravity * (time*time) + FW_Data[handle][FW_ORIGIN_Z];
						new const Float:vf_z = vi_z - gravity * time;
						if((vf_z < 0.0 ) && zpos < (FW_Data[handle][FW_MAX_HEIGHT] - fRandomEx(6.0, 10.0)))
						{
							CreateExplosion(xpos, ypos, zpos, FW_EXPLOSION_TYPE, FW_EXPLOSION_RANGE);
							DestroyDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i]);
							FW_Data[handle][FW_OBJECT_DESTROYED_COUNT]++;
						}
						new const Float:v = VectorSize(vx, vy, vf_z);
						MoveDynamicObject(FW_Data[handle][FW_FLARE_OBJECT_ID][i], xpos, ypos, zpos, v, 0.0, 0.0, 0.0);
					}
				}
			}
		}
	}
	FW_Data[handle][FW_GLOBAL_TIME_ELAPSED] += FW_TICK_RATE * 0.001;
	FW_Data[handle][FW_FL_TIME_DELAY_COUNT]++;
	return 1;
}
