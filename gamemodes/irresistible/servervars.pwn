/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: servervars.inc
 * Purpose: savable server variables
 */

#if !defined __irresistible_servervars
	#define __irresistible_servervars
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define GetServerVariableInt		GetGVarInt
#define GetServerVariableFloat		GetGVarFloat

#define UpdateServerVariableString(%0,%1) \
	(UpdateServerVariable(%0, 0, 0, %1, GLOBAL_VARTYPE_STRING))

#define UpdateServerVariableInt(%0,%1) \
	(UpdateServerVariable(%0, %1, 0, "", GLOBAL_VARTYPE_INT))

#define UpdateServerVariableFloat(%0,%1) \
	(UpdateServerVariable(%0, 0, %1, "", GLOBAL_VARTYPE_FLOAT))

/* ** Hooks ** */
hook OnGameModeInit( )
{
	mysql_function_query( dbHandle, "SELECT * FROM `SERVER`", true, "OnLoadServerVariables", "" );
	return 1;
}

/* ** Functions ** */
thread OnLoadServerVariables( )
{
	new
		rows, fields, i = -1,
		Field[ 30 ],
		szName[ 64 ],
		iValue,
		Float: fValue,
		iType
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "STRING_VAL", szBigString );
			cache_get_field_content( i, "INT_VAL", Field ),		iValue = strval( Field );
			cache_get_field_content( i, "FLOAT_VAL", Field ),	fValue = floatstr( Field );
			cache_get_field_content( i, "TYPE", Field ),		iType = strval( Field );

			switch( iType )
			{
				case GLOBAL_VARTYPE_INT: SetGVarInt( szName, iValue );
				case GLOBAL_VARTYPE_STRING: SetGVarString( szName, szBigString );
				case GLOBAL_VARTYPE_FLOAT: SetGVarFloat( szName, fValue );
			}
		}
	}
	printf( "[SERVER] %d server variables have been loaded.", rows );
	return 1;
}

stock UpdateServerVariable( szName[ 64 ], intVal, Float: floatVal, stringVal[ 128 ], type )
{
	static
		szString[ 256 ];

	switch( type )
	{
		case GLOBAL_VARTYPE_INT:	format( szString, 128, "UPDATE `SERVER` SET `INT_VAL`=%d WHERE `NAME`='%s'", intVal, mysql_escape( szName ) ),							SetGVarInt( szName, intVal );
		case GLOBAL_VARTYPE_STRING:	format( szString, 256, "UPDATE `SERVER` SET `STRING_VAL`='%s' WHERE `NAME`='%s'", mysql_escape( stringVal ), mysql_escape( szName ) ), 	SetGVarString( szName, stringVal );
		case GLOBAL_VARTYPE_FLOAT:	format( szString, 128, "UPDATE `SERVER` SET `FLOAT_VAL`=%f WHERE `NAME`='%s'", floatVal, mysql_escape( szName ) ),						SetGVarFloat( szName, floatVal );
		default: return;
	}

	mysql_single_query( szString );
}

stock AddServerVariable( szName[ 64 ], szValue[ 128 ], type )
{
	switch( type )
	{
		case GLOBAL_VARTYPE_INT:	format( szLargeString, 164, "INSERT IGNORE INTO `SERVER`(`NAME`,`INT_VAL`,`TYPE`) VALUES ('%s',%d,%d)", mysql_escape( szName ), strval( szValue ), type );
		case GLOBAL_VARTYPE_STRING:	format( szLargeString, 296, "INSERT IGNORE INTO `SERVER`(`NAME`,`STRING_VAL`,`TYPE`) VALUES ('%s','%s',%d)", mysql_escape( szName ), mysql_escape( szValue ), type );
		case GLOBAL_VARTYPE_FLOAT:	format( szLargeString, 164, "INSERT IGNORE INTO `SERVER`(`NAME`,`FLOAT_VAL`,`TYPE`) VALUES ('%s',%f,%d)", mysql_escape( szName ), floatstr( szValue ), type );
		default: return;
	}

	mysql_single_query( szLargeString );
}
