/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_SLOT_POOLS				( 3 )
#define POOL_ENTITIES				( 5 )

/* ** Constants ** */
enum E_SLOT_ODD_DATA
{
	E_ENTRY_FEE,				E_SAMPLE_SIZE,					Float: E_TAX,
	E_DOUBLE_BRICK,				E_SINGLE_BRICK[ 2 ], 			E_GOLD_BELLS[ 2 ],
	E_CHERRY[ 2 ], 				E_GRAPES[ 2 ], 					E_69[ 2 ],
	E_PAYOUTS[ 5 ]
};

new
	g_slotOddsPayout[ ] [ E_SLOT_ODD_DATA ] =
	{
		// Entry Fee 	Probability		Tax 	{Double Brick}	{Single Brick}	{Gold Bells}	{Cherry}			{Grapes}				{69}				Payouts (Single brick, gold bells, etc...)
		{ 50000,        50000,          0.2,    48032,          { 1, 400 },     { 401, 1199},   { 1200, 2797 },     { 2798, 10787 },     	{ 10788, 26767 },   { 1000000, 500000, 250000, 50000, 25000 } },
		{ 25000,		100000,			0.2,	98742,			{ 1, 799 },	    { 800, 2397 },	{ 2398, 6392 },	    { 6393, 22372 },		{ 22373, 54332 },	{ 500000, 250000, 100000, 25000, 12500 } },
		{ 10000,		62500,			0.2,	62488,			{ 1, 994 },	    { 995, 2982 },	{ 2983, 6957 },	    { 6958, 16895 },		{ 16896, 36770 },	{ 100000, 50000, 25000, 10000, 5000 } },
		{ 5000, 		40000,			0.25,	27390,			{ 1, 596 },		{ 597, 1788 },	{ 1789, 4768 },		{ 4769, 10728 },		{ 10729, 22648 },	{ 50000, 25000, 10000, 5000, 2500 } }
	}
;

/* ** Variables ** */
enum E_SLOT_MACHINE_DATA
{
	E_SPIN[ 3 ], 				E_ACTIVE,
	Float: E_X, 				Float: E_Y, 					Float: E_Z,
	Float: E_A, 				Float: E_SPIN_ROTATE[ 3 ], 		Float: E_RANDOM_ROTATE[ 3 ],
	E_TIMER, 					bool: E_ROLLING,				E_POOL_ID,
	E_ENTRY_FEE
};

enum E_CASINO_POOL_DATA
{
	E_SQL_ID,					E_TOTAL_WINNINGS,				E_TOTAL_GAMBLED,
	E_POOL,						E_OBJECT[ POOL_ENTITIES ],		Text3D: E_LABEL[ POOL_ENTITIES ]
};


new
	g_slotmachineData				[ MAX_MACHINES ] [ E_SLOT_MACHINE_DATA ],
	g_slotmachineColors				[ ] [ ] = {
		{ "ld_slot:bar2_o" }, { "ld_slot:r_69" }, { "ld_slot:bar1_o" }, { "ld_slot:bell" }, { "ld_slot:cherry" }, { "ld_slot:grapes" }, { "ld_slot:cherry" }, { "ld_slot:grapes" }, { "ld_slot:bell" }, { "ld_slot:r_69" },
		{ "ld_slot:bell" }, { "ld_slot:bar1_o" }, { "ld_slot:cherry" }, { "ld_slot:grapes" }, { "ld_slot:r_69" }, { "ld_slot:grapes" }, { "ld_slot:bell" }, { "ld_slot:cherry" }, { "ld_slot:bar2_o" }
	},
	g_slotmachineTypes				[ sizeof( g_slotmachineColors ) ] = { 0, 5, 1, 2, 3, 4, 3, 4, 2, 5, 2, 1, 3, 4, 5, 4, 2, 3, 0 },
	p_usingSlotMachine				[ MAX_PLAYERS ] = { -1, ... },

	// Casino pools
	g_casinoPoolData 				[ MAX_SLOT_POOLS ] [ E_CASINO_POOL_DATA ],

	// Iterator
	Iterator:SlotMachines<MAX_MACHINES>,
	Iterator:CasinoPool<MAX_SLOT_POOLS>
;


/* ** Hooks ** */

/* ** Functions ** */
