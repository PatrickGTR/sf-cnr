/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\robbery\vaults.pwn
 * Purpose: vault opening system (corrolated to robberies)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define VAULT_BOAT 					( 3 )

/* ** Variables ** */
enum E_BANKDOOR_DATA
{
	E_NAME[ 18 ],
	E_OBJECT,					bool: E_DISABLED,
	E_TIMESTAMP,				E_TIMESTAMP_CLOSE,			E_WORLD,
	Float: E_EXPLODE_POS[ 3 ],	Float: E_OPEN_POS[ 3 ],		Float: E_OPEN_ROT[ 3 ]
}

new
	g_bankvaultData					[ ] [ E_BANKDOOR_DATA ] =
	{
		{ "San Fierro Bank", 	INVALID_OBJECT_ID, false, 0, 0, 23, { -1413.956, 859.16560, 984.71260 }, { -1412.56506, 859.2745360, 978.6328730 }, { -1000.000, -1000.00, -1000.0000 } },
		{ "Las Venturas Bank", 	INVALID_OBJECT_ID, false, 0, 0, 52, { 2116.3513, 1233.0250, 1017.1369 }, { 2113.391357, 1233.155273, 1016.122619 }, { 90.000000, 0.000000, -90.000000 } },
		{ "Los Santos Bank", 	INVALID_OBJECT_ID, false, 0, 0, 56, { 2116.3513, 1233.0250, 1017.1369 }, { 2113.391357, 1233.155273, 1016.122619 }, { 90.000000, 0.000000, -90.000000 } },
		{ "Militia Ship", 		INVALID_OBJECT_ID, false, 0, 0, 0, { -2372.6223, 1551.3984, 2.1172000 }, { -2371.41699, 1552.027709, -0.75281000 }, { 0.0000000, 0.000000, 28.0000000 } }
	}
;

/* ** Hooks ** */

/* ** Functions ** */
stock GetBankVaultWorld( city ) {
	return g_bankvaultData[ city ] [ E_WORLD ];
}
