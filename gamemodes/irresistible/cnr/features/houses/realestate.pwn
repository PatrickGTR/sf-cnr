/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\home\realestate.pwn
 * Purpose: home listings for player homes
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */

/* ** Variables ** */

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	return 1;
}

/* ** Commands ** */
CMD:listhome( playerid, params[ ] )
{
	new Float: coins;

	if ( sscanf( params, "df", coins ) )
		return 0;

	new
		houseid = p_InHouse[ playerid ];

	if ( ! Iter_Contains( houses, houseid ) )
		return SendError( playerid, "This home does not exist" );

	if ( ! IsPlayerHomeOwner( playerid, houseid ) )
		return SendError( playerid, "You are not the owner of this home." );

	mysql_single_query( sprintf( "INSERT INTO HOUSE_LISTINGS (HOUSE_ID, USER_ID, ASK) VALUES (%d, %d, %f)", houseid, GetPlayerAccountID( playerid ), coins ) );
	return 1;
}

/* ** Functions ** */

/* ** Migrations ** */
/*
	DROP TABLE HOUSE_LISTINGS;
	CREATE TABLE IF NOT EXISTS HOUSE_LISTINGS (
		ID int(11),
		HOUSE_ID int(11),
		USER_ID int(11),
		ASK float,
		SALE_DATE DATETIME default null,
		PRIMARY KEY (ID),
		UNIQUE KEY (HOUSE_ID),
		FOREIGN KEY (HOUSE_ID) REFERENCES HOUSES (ID) ON DELETE CASCADE
	);
*/
