/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: irresistible\config\migrations\_migrations.pwn
 * Purpose: checks (and executes if you want) migration files for a server
 */

/* ** Disable Checker If Disabled By Operator / Production Mode ** */
#if !defined SERVER_MIGRATIONS_FOLDER || !defined DEBUG_MODE
    #endinput
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >
#tryinclude 						< filemanager >

/* ** Further Error Checking ** */
#if !defined FM_DIR
    #warning "Migration checker is disabled (Install FileManager Plugin)"
    #endinput
#endif

/* ** Definitions ** */
#define ATTEMPT_MIGRATION           ( false ) // currently buggy ... but its there anyway

/* ** Variables ** */
static stock
    g_mirationsFileBuffer           [ 256 ],
    g_migrationsBuffer              [ 2048 ];

/* ** Forwards ** */
forward Migrations_PerformMigration( migration_name[ ] );
forward Migrations_CheckMissing( );

/* ** Hooks ** */
hook OnScriptInit( )
{
    // check if there's a migrations folder
    if ( dir_exists( SERVER_MIGRATIONS_FOLDER ) ) {
        mysql_pquery( dbHandle, "SELECT * FROM `DB_MIGRATIONS`", "Migrations_CheckMissing", "" );
    } else {
        printf( "[MIGRATIONS] Migration directory not found (%s).", SERVER_MIGRATIONS_FOLDER );
    }
    return 1;
}

public Migrations_CheckMissing( )
{
	new
        executed_migrations = cache_get_row_count( );

    // check if the migrations folder exists to begin with
    if ( dir_exists( SERVER_MIGRATIONS_FOLDER ) )
    {
        new
            num_migrations = Migrations_GetCount( );

        if ( executed_migrations != num_migrations )
        {
            new
                dir: migrations_directory = dir_open( SERVER_MIGRATIONS_FOLDER ),
                migration_executed[ 64 ],
                file_name[ 64 ],
                file_type;

            // alert operator
            #if ATTEMPT_MIGRATION == false
            printf( "\n** %d/%d Migrations not executed! Please execute them in order of earliest to latest:", executed_migrations, num_migrations );
            #else
            printf ( "\n** %d/%d migrations have been executed ... auto-executing missing migrations.", executed_migrations, num_migrations );
            #endif

            // check if the migration is in the database
            for ( new m = -1; m < executed_migrations; )
            {
                skip_migration: m ++;

                // the goto statement might avoid this check
                if ( m > executed_migrations ) {
                    break;
                }

                cache_get_field_content( m, "MIGRATION", migration_executed, sizeof ( migration_executed ) );

                while ( dir_list ( migrations_directory, file_name, file_type ) ) if ( file_type == FM_FILE )
                {
                    new
                        file_prefix = strfind( file_name, ".sql", true );

                    // only focus on .sql files
                    if ( file_prefix != -1 )
                    {
                        // remove .sql from file name
                        strmid( file_name, file_name, 0, file_prefix );

                        // ignore existing migrations executed in the database
                        if ( ! strcmp( file_name, migration_executed, true ) ) {
                            goto skip_migration;
                        }

                        // get the full file length
                        mysql_format( dbHandle, g_mirationsFileBuffer, sizeof ( g_mirationsFileBuffer ), SERVER_MIGRATIONS_FOLDER # "%s.sql", file_name );

                        // auto migration is disabled by default
                        #if ATTEMPT_MIGRATION == false
                            printf( "** Missing Migration: %s", g_mirationsFileBuffer );
                        #else
                            // reset the buffer just in-case
                            g_migrationsBuffer[ 0 ] = '\0';
                            // now let's read the .sql file completely
                            file_read( g_mirationsFileBuffer, g_migrationsBuffer, sizeof ( g_migrationsBuffer ) );

                            // and let's query this sql file all at once
                            mysql_pquery( dbHandle, g_migrationsBuffer, "Migrations_PerformMigration", "s", file_name );
                            printf( "\n** %s.sql has not been executed! Performing execution...", file_name );
                        #endif
                    }
                }
            }

            dir_close( migrations_directory );

            // Freeze Server if attempt migration feature is off
            #if ATTEMPT_MIGRATION == false
            print( "\n** Server has been forcefully frozen. Execute the missing migrations and restart.\n\n" );
            new bool: True = true;
            while ( True ) {
                True = true;
            }
            #endif
        }
        else
        {
            print( "[MIGRATIONS] All migrations are up to date!\n" );
        }
    }
    return 1;
}

#if ATTEMPT_MIGRATION == true
public Migrations_PerformMigration( migration_name[ ] )
{
    // alert server operator
    printf(
        "** %s.sql has been automatically run (%d rows, %d fields, %d affected rows, %d warnings)\n",
        migration_name,
        cache_get_row_count( ),
        cache_get_field_count( ),
        cache_affected_rows( ),
        cache_warning_count( )
    );

    // add migration to the database
    mysql_format( dbHandle, g_migrationsBuffer, sizeof ( g_migrationsBuffer ), "INSERT INTO `DB_MIGRATIONS` (`MIGRATION`) VALUES ('%e')", migration_name );
    mysql_pquery( dbHandle, g_migrationsBuffer, "", "" );
    return 1;
}
#endif

/* ** Functions ** */
static stock Migrations_GetCount( )
{
    new
        count = 0;

    if ( dir_exists( SERVER_MIGRATIONS_FOLDER ) )
    {
        new
            dir: migrations_directory = dir_open( SERVER_MIGRATIONS_FOLDER ),
            file_name[ 64 ],
            file_type;

        while ( dir_list ( migrations_directory, file_name, file_type ) ) if ( file_type == FM_FILE ) {
            count ++;
        }

        dir_close( migrations_directory );
    }
    return count;
}