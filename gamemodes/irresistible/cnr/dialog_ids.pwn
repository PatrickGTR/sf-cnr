/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: dialog_ids.inc
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define DIALOG_REGISTER             		1000
#define DIALOG_LOGIN	            		1001
#define DIALOG_JOB	            			1002
#define DIALOG_BOMB_SHOP            		1003
#define DIALOG_NULL                 		1004
#define DIALOG_BANNED               		1005
#define DIALOG_BANK_MENU            		1006
#define DIALOG_BANK_WITHDRAW        		1007
#define DIALOG_BANK_DEPOSIT         		1008
#define DIALOG_BANK_INFO            		1009
#define DIALOG_SHOP_MENU            		1010
#define DIALOG_HOUSES               		1011
#define DIALOG_CITY_HALL 	       			1012
#define DIALOG_HOSPITAL             		1013
#define DIALOG_HOUSE_CONFIG         		1014
#define DIALOG_HOUSE_TITLE          		1015
#define DIALOG_HOUSE_INTERIORS      		1016
#define DIALOG_IC_MARKET            		1017
#define DIALOG_VEHICLE_SPAWN        		1018
#define DIALOG_ARENAS               		1019
#define DIALOG_BOUGHT_VEH        			1020
#define DIALOG_PERKS                		1021
#define DIALOG_PERKS_P              		1022
#define DIALOG_VIP              			1023
#define DIALOG_PERKS_V              		1024
#define DIALOG_DONATED           			1025
#define DIALOG_VEHICLE_LOCATE       		1026
#define DIALOG_GANG_COLOR           		1027
#define DIALOG_GANG_COLOR_INPUT     		1028
#define DIALOG_RADIO                		1029
#define DIALOG_XPMARKET             		1030
#define DIALOG_PAINTBALL            		1031
#define DIALOG_GPS                  		1032
#define DIALOG_VIP_LOCKER           		1033
#define DIALOG_AMMU                 		1034
#define DIALOG_GARAGE_INTERIORS     		1035
#define DIALOG_GARAGE_INT_CONFIRM			1036
#define DIALOG_GANG_LIST         			1037
#define DIALOG_LUMBERJACK           		1038
#define DIALOG_FIGHTSTYLE           		1039
#define DIALOG_TOYS_MAIN            		1040
#define DIALOG_TOYS     					1041
#define DIALOG_TOYS_BONE 					1042
#define DIALOG_VIP_WEP              		1043
#define DIALOG_VIP_WEP_SELECT       		1044
#define DIALOG_GANG_LIST_RESPONSE 			1045
#define DIALOG_CMDS                 		1046
#define DIALOG_CMDS_REDIRECT        		1047
#define DIALOG_STATS                		1048
#define DIALOG_STATS_REDIRECT       		1049
#define DIALOG_VEHDEALER            		1050
#define DIALOG_CP_MENU            			1051
#define DIALOG_AMMU_BUY             		1052
#define DIALOG_APARTMENTS         			1053
#define DIALOG_APARTMENTS_BUY     			1054
#define DIALOG_FLAT_CONFIG          		1055
#define DIALOG_FLAT_CONTROL         		1056
#define DIALOG_FLAT_TITLE	        		1057
#define DIALOG_BUSINESS_TERMINAL			1058
#define DIALOG_WEAPON_DEAL          		1059
#define DIALOG_WEAPON_DEAL_BUY      		1060
#define DIALOG_HOUSE_PW             		1061
#define DIALOG_HOUSE_SET_PW         		1062
#define DIALOG_HOUSE_WEAPONS        		1063
#define DIALOG_HOUSE_WEAPONS_ADD    		1064
#define DIALOG_BUSINESS_BUY         		1065
#define DIALOG_FURNITURE            		1066
#define DIALOG_FURNITURE_LIST 				1067
#define DIALOG_FURNITURE_OPTION     		1068
#define DIALOG_FURNITURE_ROTATION   		1069
#define DIALOG_FURNITURE_MAN_SEL    		1070
#define DIALOG_ONLINE_JOB           		1071
#define DIALOG_ONLINE_JOB_R         		1072
#define DIALOG_FURNITURE_CATEGORY   		1073
#define DIALOG_SPAWN 						1074
#define DIALOG_TRUNCATE_FURNITURE			1075
#define DIALOG_VEHDEALER_BUY				1076
#define DIALOG_VEHDEALER_OPTIONS			1077
#define DIALOG_HELP 						1078
#define DIALOG_HELP_CATEGORY				1079
#define DIALOG_HELP_THREAD					1080
#define DIALOG_HELP_BACK					1081
#define DIALOG_RADIO_CUSTOM					1082
#define DIALOG_GPS_CITY 					1083
#define DIALOG_SPAWN_CITY					1084
#define DIALOG_GATE							1085
#define DIALOG_GATE_EDIT 					1086
#define DIALOG_GATE_OWNER 					1087
#define DIALOG_GATE_OWNER_EDIT				1088
#define DIALOG_PAINTBALL_EDIT 				1089
#define DIALOG_PAINTBALL_EDIT_VAL 			1090
#define DIALOG_PAINTBALL_ARENAS 			1091
#define DIALOG_PAINTBALL_WEP 				1092
#define DIALOG_PAINTBALL_PW 				1093
#define DIALOG_DONATED_PLATBRONZE 			1094
#define DIALOG_SHOP_AMOUNT 					1095
#define DIALOG_PAINTBALL_REFILL 			1096
#define DIALOG_HOUSE_INT_CONFIRM			1098
#define DIALOG_TOYS_ITEMS					1099
#define DIALOG_TOYS_EDIT 					1100
#define DIALOG_TOYS_BONE_EDIT 				1101
#define DIALOG_TOYS_BUY 					1102
#define DIALOG_TOYS_ITEMS_BUY 				1103
#define DIALOG_UNBAN_CLASS 					1104
#define DIALOG_GANG_BANK_WITHDRAW   		1105
#define DIALOG_GANG_BANK_DEPOSIT    		1106
#define DIALOG_GANG_BANK_INFO       		1107
#define DIALOG_YOU_SURE_APART  				1108
#define DIALOG_YOU_SURE_VIP 				1109
#define DIALOG_CHANGENAME					1110
#define DIALOG_GANG_LIST_OPTIONS			1111
#define DIALOG_GANG_LIST_MEMBERS 			1112
#define DIALOG_COMPONENTS_CATEGORY 			1113
#define DIALOG_COMPONENTS					1114
#define DIALOG_COMPONENT_EDIT 				1115
#define DIALOG_COMPONENT_EDIT_MENU			1116
#define DIALOG_COMPONENT_MENU				1117
#define DIALOG_DONATED_DIAGOLD 				1118
#define DIALOG_LATEST_DONOR					1119
#define DIALOG_FINISHED_DONATING			1120
#define DIALOG_MODIFY_HITSOUND 				1121
#define DIALOG_VIP_NOTE						1122
#define DIALOG_REGISTER_QUIT 				1123
#define DIALOG_LOGIN_QUIT					1124
#define DIALOG_WEAPON_LOCKER				1125
#define DIALOG_WEAPON_LOCKER_BUY			1126
#define DIALOG_FEEDBACK						1127
#define DIALOG_IC_MARKET_2 					1128
#define DIALOG_BUSINESS_CAR					1129
#define DIALOG_BUSINESS_HELI				1130
#define DIALOG_ACC_GUARD 					1131
#define DIALOG_ACC_GUARD_EMAIL				1132
#define DIALOG_ACC_GUARD_MODE 				1133
#define DIALOG_ACC_GUARD_CONFIRM			1134
#define DIALOG_ACC_GUARD_DEL_CANCEL			1135
#define DIALOG_RACE 						1136
#define DIALOG_RACE_MODE 					1137
#define DIALOG_RACE_FEE 					1138
#define DIALOG_RACE_POS 					1139
#define DIALOG_RACE_DISTANCE 				1140
#define DIALOG_RACE_KICK 					1141
#define DIALOG_RACE_DEST 					1142
#define DIALOG_RACE_PRESELECT 				1143
#define DIALOG_RACE_CUSTOM_DEST 			1144
#define DIALOG_BUSINESS_SELL				1145
#define DIALOG_BUSINESS_NAME 				1146
#define DIALOG_BUSINESS_ADD_MEMBER			1147
#define DIALOG_BUSINESS_MEMBERS				1148
#define DIALOG_BUSINESS_WITHDRAW			1149
#define DIALOG_BUSINESS_UPGRADES			1150
#define DIALOG_BUSINESSES 					1151
#define DIALOG_CASINO_REWARDS 				1152
#define DIALOG_AIRPORT 						1153
#define DIALOG_CASINO_BAR 					1154
#define DIALOG_ACC_EMAIL 					1155
#define DIALOG_BUSINESS_SECURITY 			1156
#define DIALOG_FACILITY_SPAWN				1157
#define DIALOG_IC_MARKET_3 					1158
#define DIALOG_BUY_VIP 						1159
#define DIALOG_TOYS_COLOR 					1160
#define DIALOG_HIGHSCORES 					1161
#define DIALOG_HIGHSCORES_BACK 				1162
#define DIALOG_CROWDFUNDS			 		1163
#define DIALOG_CROWDFUND_OPTIONS	 		1164
#define DIALOG_CROWDFUND_INFO 		 		1165
#define DIALOG_CROWDFUND_DONATE 	 		1166

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	// make a confirmation/cancellation sound between dialogs
    if ( response ) PlayerPlaySound( playerid, 1083, 0.0, 0.0, 0.0 ); // Confirmation sound
    else PlayerPlaySound( playerid, 1084, 0.0, 0.0, 0.0 ); // Cancellation sound

    // replace % with # in dialogs
	if ( strlen( inputtext ) ) strreplacechar( inputtext, '%', '#' ); // The percentage injection crasher (critical)
    return 1;
}
