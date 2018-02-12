/*
 * Irresistible Gaming 2018
 * Developed by Lorenc Pekaj
 * Module: settings.inc
 * Purpose: defines general server settings
 */

// mysqldump -u service -p82JA8LDL1JAG2GF69 sa-mp > ~/dump01.sql
// MySQL settings
#if !defined DEBUG_MODE
	#define MYSQL_HOST                 	"127.0.0.1"
	#define MYSQL_USER                  "service"
	#define MYSQL_PASS                  "M8aHnYxJEFmw6ubK" // "82JA8LDL1JAG2GF69"
	#define MYSQL_DATABASE        		"sa-mp"
#else
	#define MYSQL_HOST                 	"127.0.0.1"
	#define MYSQL_USER                  "root"
	#define MYSQL_PASS                  ""
	#define MYSQL_DATABASE             	"sa-mp"
#endif
