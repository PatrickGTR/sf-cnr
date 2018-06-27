/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define CLASS_CIVILIAN              ( 0 )
#define CLASS_POLICE              	( 1 )
#define CLASS_FIREMAN               ( 2 )
#define CLASS_MEDIC              	( 3 )

/* ** Variables ** */
stock const CLASS_NAMES 			[ ] [ ] = { "Civilian", "Police", "FBI", "Army", "CIA", "Paramedic", "Fireman" };
stock const CLASS_COLORS 			[ ] = { 0xC0C0C0FF, 0x3E7EFFFF, 0x0035FFFF, 0x954BFFFF, 0x191970FF, 0x4DFF4DFF, 0xA83434FF };

stock CLASS_CIVILIAN_RANGE			[ 2 ];
stock CLASS_POLICE_RANGE			[ 2 ];
stock CLASS_FBI_RANGE				[ 2 ];
stock CLASS_CIA_RANGE 				[ 2 ];
stock CLASS_FIRE_RANGE 				[ 2 ];
stock CLASS_MEDIC_RANGE 			[ 2 ];
stock CLASS_ARMY_RANGE;

/* ** Hooks ** */

/* ** Functions ** */
