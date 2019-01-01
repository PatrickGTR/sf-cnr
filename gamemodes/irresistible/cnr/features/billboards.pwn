/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\billboards.pwn
 * Purpose: specially placed billboards to help user experience in the cities
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define CreateBillboard(%0,%1,%2,%3,%4) \
    SetDynamicObjectMaterialText( CreateDynamicObject( 7246, %1, %2, %3, 0, 0, %4 ), 0, (%0), 120, "Arial", 24, 0, -1, -16777216, 1 )

/* ** Hooks ** */
hook OnScriptInit( )
{
	CreateBillboard( "Want V.I.P? Consider Donating!\n"COL_GREY"donate.sfcnr.com", -2016.22, 326.580, 37.950, 48.9000 );
	CreateBillboard( "Save us on your favourites!\n"#SERVER_IP"", -1809.64, -590.29, 19.360, -147.30 );
	CreateBillboard( "You can catch updates on our website!\n"COL_GREY""#SERVER_WEBSITE"", -1571.11, 939.860, 10.030, 45.9600 );
	CreateBillboard( "Remember to check the "COL_GREY"/rules"COL_WHITE"!\nDisobeying the rules can lead to punishment!", -1911.05, 858.870, 36.290, 44.5200 );
	CreateBillboard( "Want to view the commands?\n Use "COL_GREY"/commands{FFFFFF}!", -2423.40, -621.18, 135.46, -195.90 );
	CreateBillboard( "Need help with something?\nUse "COL_GREY"/ask"COL_WHITE" to contact an admin!", -2659.78, 1277.70, 9.8600, 125.100 );
	CreateBillboard( "Saw a cheater? Report him by typing "COL_GREY"/report{FFFFFF}!", -2443.63, 719.970, 37.900, 0.00000 );
	CreateBillboard( "You can use "COL_GREY"/vipcmds"COL_WHITE" to view your\nV.I.P commands!", -1958.975830, 841.130798, 1208.881469, -43.700046 );
    return 1;
}