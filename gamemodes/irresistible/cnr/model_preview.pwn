/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\model_preview.pwn
 * Purpose: handy module to preview object models
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	PlayerText: p_ModelPreviewTD 	[ MAX_PLAYERS ] [ 8 ],
	Text:  g_ModelPreviewBoxTD		= Text: INVALID_TEXT_DRAW,
	Text:  p_ModelPreviewCloseTD	= Text: INVALID_TEXT_DRAW
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// init textdraws
	for ( new i = 0; i < sizeof( p_ModelPreviewTD ); i ++ ) {
		for ( new x = 0; x < sizeof( p_ModelPreviewTD[ ] ); x ++ ) {
			p_ModelPreviewTD[ i ] [ x ] = PlayerText: INVALID_TEXT_DRAW;
		}
	}

	// global ones
	p_ModelPreviewCloseTD = TextDrawCreate( 191.000000, 319.000000, "Press your ESCAPE KEY to close the preview." );
	TextDrawBackgroundColor( p_ModelPreviewCloseTD, 255 );
	TextDrawFont( p_ModelPreviewCloseTD, 2 );
	TextDrawLetterSize( p_ModelPreviewCloseTD, 0.259999, 1.399999 );
	TextDrawColor( p_ModelPreviewCloseTD, -1 );
	TextDrawSetOutline( p_ModelPreviewCloseTD, 1 );
	TextDrawSetProportional( p_ModelPreviewCloseTD, 1 );

	g_ModelPreviewBoxTD = TextDrawCreate( 500.000000, 150.000000, "__" );
	TextDrawBackgroundColor( g_ModelPreviewBoxTD, 255 );
	TextDrawLetterSize( g_ModelPreviewBoxTD, 0.500000, 17.000000 );
	TextDrawColor( g_ModelPreviewBoxTD, -1 );
	TextDrawUseBox( g_ModelPreviewBoxTD, 1 );
	TextDrawBoxColor( g_ModelPreviewBoxTD, 112 );
	TextDrawTextSize( g_ModelPreviewBoxTD, 139.000000, 50.000000 );
	return 1;
}

hook OnPlayerConnect( playerid )
{
	p_ModelPreviewTD[ playerid ] [ 0 ] = CreatePlayerTextDraw( playerid,289.000000, 230.000000, "preview 2" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], 112 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], 5 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], 0.500000, 4.400000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], -1 );
	PlayerTextDrawUseBox( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], 1 );
	PlayerTextDrawBoxColor( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], 0 );
	PlayerTextDrawTextSize( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], 60.000000, 60.000000 );
	PlayerTextDrawSetPreviewRot( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], -16.000000, 0.000000, 0.000000, 1.000000 );
	// PlayerTextDrawSetSelectable( playerid, p_ModelPreviewTD[ playerid ] [ 0 ], 1 );

	p_ModelPreviewTD[ playerid ] [ 1 ] = CreatePlayerTextDraw( playerid,358.000000, 160.000000, "preview 3" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], 112 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], 5 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], 0.500000, 4.400000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], -1 );
	PlayerTextDrawUseBox( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], 1 );
	PlayerTextDrawBoxColor( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], 0 );
	PlayerTextDrawTextSize( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], 60.000000, 60.000000 );
	PlayerTextDrawSetPreviewRot( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], -16.000000, 0.000000, 270.000000, 1.000000 );
	// PlayerTextDrawSetSelectable( playerid, p_ModelPreviewTD[ playerid ] [ 1 ], 1 );

	p_ModelPreviewTD[ playerid ] [ 2 ] = CreatePlayerTextDraw( playerid,358.000000, 230.000000, "preview 4" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], 112 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], 5 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], 0.500000, 4.400000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], -1 );
	PlayerTextDrawUseBox( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], 1 );
	PlayerTextDrawBoxColor( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], 0 );
	PlayerTextDrawTextSize( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], 60.000000, 60.000000 );
	PlayerTextDrawSetPreviewRot( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], -16.000000, 0.000000, 90.000000, 1.000000 );
	// PlayerTextDrawSetSelectable( playerid, p_ModelPreviewTD[ playerid ] [ 2 ], 1 );

	p_ModelPreviewTD[ playerid ] [ 3 ] = CreatePlayerTextDraw( playerid,428.000000, 160.000000, "preview 4" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 112 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 5 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 0.500000, 4.400000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], -1 );
	PlayerTextDrawUseBox( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 1 );
	PlayerTextDrawBoxColor( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 0 );
	PlayerTextDrawTextSize( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 60.000000, 60.000000 );
	PlayerTextDrawSetPreviewRot( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 270.000000, 0.000000, 0.000000, 1.000000 );
	// PlayerTextDrawSetSelectable( playerid, p_ModelPreviewTD[ playerid ] [ 3 ], 1 );

	p_ModelPreviewTD[ playerid ] [ 4 ] = CreatePlayerTextDraw( playerid,428.000000, 230.000000, "preview 5" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 112 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 5 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 0.500000, 4.400000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], -1 );
	PlayerTextDrawUseBox( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 1 );
	PlayerTextDrawBoxColor( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 0 );
	PlayerTextDrawTextSize( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 60.000000, 60.000000 );
	PlayerTextDrawSetPreviewRot( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 90.000000, 0.000000, 0.000000, 1.000000 );
	// PlayerTextDrawSetSelectable( playerid, p_ModelPreviewTD[ playerid ] [ 4 ], 1 );

	p_ModelPreviewTD[ playerid ] [ 5 ] = CreatePlayerTextDraw( playerid,150.000000, 160.000000, "big preview" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], 112 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], 5 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], 0.500000, 1.000000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], -1 );
	PlayerTextDrawUseBox( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], 1 );
	PlayerTextDrawBoxColor( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], 0 );
	PlayerTextDrawTextSize( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], 130.000000, 130.000000 );
	PlayerTextDrawSetPreviewRot( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], -16.000000, 0.000000, 45.000000, 1.000000 );
	// PlayerTextDrawSetSelectable( playerid, p_ModelPreviewTD[ playerid ] [ 5 ], 1 );

	p_ModelPreviewTD[ playerid ] [ 6 ] = CreatePlayerTextDraw( playerid,289.000000, 160.000000, "preview 6" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], 112 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], 5 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], 0.500000, 4.400000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], -1 );
	PlayerTextDrawUseBox( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], 1 );
	PlayerTextDrawBoxColor( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], 0 );
	PlayerTextDrawTextSize( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], 60.000000, 60.000000 );
	PlayerTextDrawSetPreviewRot( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], -16.000000, 0.000000, 180.000000, 1.000000 );
	// PlayerTextDrawSetSelectable( playerid, p_ModelPreviewTD[ playerid ] [ 6 ], 1 );

	p_ModelPreviewTD[ playerid ] [ 7 ] = CreatePlayerTextDraw( playerid, 130.000000, 135.000000, "Vehicle Preview" );
	PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ 7 ], 255 );
	PlayerTextDrawFont( playerid, p_ModelPreviewTD[ playerid ] [ 7 ], 0 );
	PlayerTextDrawLetterSize( playerid, p_ModelPreviewTD[ playerid ] [ 7 ], 0.720000, 2.000000 );
	PlayerTextDrawColor( playerid, p_ModelPreviewTD[ playerid ] [ 7 ], -1 );
	PlayerTextDrawSetOutline( playerid, p_ModelPreviewTD[ playerid ] [ 7 ], 1 );
	PlayerTextDrawSetProportional( playerid, p_ModelPreviewTD[ playerid ] [ 7 ], 1 );
	return 1;
}

hook OnPlayerClickTextDraw( playerid, Text: clickedid)
{
	// Pressed ESC
	if ( clickedid == Text: INVALID_TEXT_DRAW ) {
		if ( GetPVarInt( playerid, "preview_model_delay" ) < GetTickCount( ) && GetPVarInt( playerid, "preview_model_handle" ) ) {
			return HidePlayerModelPreview( playerid, 0 );
		}
	}
	return 1;
}

/* ** Functions ** */
stock ShowPlayerModelPreview( playerid, handleid, title[ ], model, bgcolor = 0x00000070 )
{
   	PlayerTextDrawSetString( playerid, p_ModelPreviewTD[ playerid ] [ 7 ], title );

	TextDrawShowForPlayer( playerid, g_ModelPreviewBoxTD );
	TextDrawShowForPlayer( playerid, p_ModelPreviewCloseTD );

	for ( new i = 0; i < sizeof( p_ModelPreviewTD[ ] ); i ++ ) {
		if ( i != 7 ) {
			PlayerTextDrawBackgroundColor( playerid, p_ModelPreviewTD[ playerid ] [ i ], bgcolor );
			PlayerTextDrawSetPreviewModel( playerid, p_ModelPreviewTD[ playerid ] [ i ], model );
		}
		PlayerTextDrawShow( playerid, p_ModelPreviewTD[ playerid ] [ i ] );
	}

	CallLocalFunction( "OnPlayerUnloadTextdraws", "d", playerid );
	SetPVarInt( playerid, "preview_model_handle", handleid );
	SelectTextDraw( playerid, COLOR_RED );
	return 1;
}

stock HidePlayerModelPreview( playerid, cancel = 1 )
{
	if ( cancel ) {
		CancelSelectTextDraw( playerid );
	}

	TextDrawHideForPlayer( playerid, g_ModelPreviewBoxTD );
	TextDrawHideForPlayer( playerid, p_ModelPreviewCloseTD );

	for( new i; i < sizeof( p_ModelPreviewTD [ ] ); i++ ) {
		PlayerTextDrawHide( playerid, p_ModelPreviewTD[ playerid ] [ i ] );
	}

	CallLocalFunction( "OnPlayerLoadTextdraws", "d", playerid );
	CallLocalFunction( "OnPlayerEndModelPreview", "dd", playerid, GetPVarInt( playerid, "preview_model_handle" ) );

	SetPVarInt( playerid, "preview_model_delay", GetTickCount( ) + 100 );
	DeletePVar( playerid, "preview_model_handle" );
	return 1;
}
