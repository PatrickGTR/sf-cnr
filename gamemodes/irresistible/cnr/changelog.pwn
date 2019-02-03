/*
 * Irresistible Gaming (c) 2018
 * Developed by Cloudy, Lorenc
 * Module: cnr\commands\cmd_changes.pwn
 * Purpose: /changes to show all changes by a player
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined SERVER_CHANGES_DIRECTORY
    #define GetServerVersion(%0)    ( "UNKNOWN" )
    #endinput
#endif

/* ** Definitions ** */
#define CHANGELOG_INDEX_FILE    ( SERVER_CHANGES_DIRECTORY # "/_changelogs.cfg" )
#define DIALOG_CHANGELOGS       ( 8372 )

/* ** Commands ** */
CMD:changes( playerid, params[ ] ) return cmd_updates( playerid, params );
CMD:updates( playerid, params[ ] )
{
    new
        File: handle = fopen( CHANGELOG_INDEX_FILE, io_read );

    if ( ! handle )
    	return SendError( playerid, "There are no updates to show." );

    new
        changelogs = 0;

    szHugeString = ""COL_WHITE"Version\t \n";

    // read each line in the changelog index file
    while ( fread( handle, szNormalString ) )
    {
        // remove white spaces
        strreplace( szNormalString, "\n", "" ), trimString( szNormalString );

        // format string
        if ( ! changelogs ) {
            format( szHugeString, sizeof( szHugeString ), "%s%s\t"COL_GREEN"LATEST\n", szHugeString, szNormalString );
        } else {
            format( szHugeString, sizeof( szHugeString ), "%s{333333}%s\t \n", szHugeString, szNormalString );
        }
        changelogs ++;
    }

    // list all changelogs
    ShowPlayerDialog( playerid, DIALOG_CHANGELOGS, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Changelogs", szHugeString, "Select", "Close" );
    return 1;
}

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    if ( dialogid == DIALOG_CHANGELOGS && response )
    {
        new File: handle = fopen( CHANGELOG_INDEX_FILE, io_read );

        if ( ! handle )
            return SendError( playerid, "There are no updates to show." );

        new version[ 32 ], x = 0;

        while ( fread( handle, version ) )
        {
            if ( x == listitem )
            {
                // remove white spaces
                strreplace( version, "\n", "" ), trimString( version );

                // open the single changelog
                new File: changelog_handle = fopen( sprintf( SERVER_CHANGES_DIRECTORY # "/%s.txt", version ), io_read );

                if ( ! changelog_handle )
                    return SendError( playerid, "There are no updates to show for this version." );

                erase( szNormalString );
                erase( szHugeString );

                while ( fread( changelog_handle, szNormalString ) )
                {
                    new
                        find = strfind( szNormalString, "(+)" );

                    // additions
                    if( find != -1 )
                    {
                        strins( szNormalString, "{23D96F}added{FFFFFF}\t\t", find + 3 );
                        strdel( szNormalString, find, find + 3);
                    }

                    // removals
                    find = strfind( szNormalString, "(-)" );
                    if( find != -1 )
                    {
                        strins( szNormalString, "{D92323}removed{FFFFFF}\t", find + 3 );
                        strdel( szNormalString, find, find + 3 );
                    }

                    // fixes
                    find = strfind( szNormalString, "(*)" );
                    if ( find != -1 )
                    {
                        strins( szNormalString, "{D9A823}fixed{FFFFFF}\t\t", find + 3 );
                        strdel( szNormalString, find, find + 3 );
                    }

                    // fixes
                    find = strfind( szNormalString, "(/)" );
                    if ( find != -1 )
                    {
                        strins( szNormalString, "{c0c0c0}changed{FFFFFF}\t", find + 3 );
                        strdel( szNormalString, find, find + 3 );
                    }

                    // append
                    strcat( szHugeString, szNormalString );
                }

                fclose( changelog_handle );

                ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, sprintf( "{FFFFFF}Recent Updates - %s", version ), szHugeString, "Okay", "" );
                SendServerMessage( playerid, "You're now viewing the changes to the gamemode (version %s).", version );
            }
            x ++;
        }

        fclose( handle );
    }
    return 1;
}

/* ** Functions ** */
stock GetServerVersion( )
{
    static
        version[ 32 ];

    if ( version[ 0 ] == '\0' )
    {
        new
            File: handle = fopen( CHANGELOG_INDEX_FILE, io_read );

        if ( handle )
        {
            // read the first line of the index file
            fread( handle, version );

            // remove white spaces
            strreplace( version, "\n", "" ), trimString( version );
        }
        else
        {
            version = "UNKNOWN";
        }

        fclose( handle );
    }
    return version;
}