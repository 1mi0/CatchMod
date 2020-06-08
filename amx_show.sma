#include <amxmodx>
#include <amxmisc>
#pragma defclasslib sqlx sqlite
#include <sqlx>
#include <reapi>

// PLUGIN INFO
#define PLUGIN 	"ShowPlayerName"
#define VERSION	"1.0"
#define AUTHOR	"mi0"

// DATABASE INFO
#define BASE 	"amxshow"
#define TABLE 	"users"

enum _:PlayerInfo
{
	Name[33],
	IP[33],
	Steam[64]
}

new Handle:g_iSQLTuple
new g_szUserName[MAX_PLAYERS + 1][33]
new Array:g_aTempPlayerArray

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_concmd("amx_show", "OnCmdShow", ADMIN_BAN, " - Used to check if the player has any other nicknames")
	SQL_SetAffinity("sqlite")
}

public plugin_cfg()
{
	g_aTempPlayerArray = ArrayCreate(PlayerInfo)
	SQL_Init()
}

public plugin_end()
{
	SQL_FreeHandle(g_iSQLTuple)
}

SQL_Init()
{
	// Create DataBase Tuple used to connect to the SQL Server
	g_iSQLTuple = SQL_MakeDbTuple("", "", "", BASE)
	if (g_iSQLTuple == Empty_Handle)
	{
		set_fail_state("[%s] Failed to create tuple [%s]", PLUGIN, BASE)
	}

	// Format the query and launch a thread worker to wait for its execution
	// (The thread worker is not that necessary since the players still havent connected so they wont experience any lag)
	new szQuery[256]
	formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s`\
		(`id` INTEGER PRIMARY KEY AUTOINCREMENT,\
		`username` VARCHAR(32) NOT NULL,\
		`useraddress` VARCHAR(32) NOT NULL,\
		`usersteam` VARCHAR(64) NOT NULL);", TABLE)
	SQL_ThreadQuery(g_iSQLTuple, "QueryEmptyHandle", szQuery)
}

public client_connect(id)
{
	// Get user name
	get_user_name(id, g_szUserName[id], charsmax(g_szUserName[]))
}

public client_authorized(id)
{
	// Save user name
	Func_SavePlayerName(id)
}

public client_infochanged(id)
{
	// Check if the player have changed their name 
	new szNewName[33]
	get_user_info(id, "name", szNewName, charsmax(szNewName))
	if (equal(szNewName, g_szUserName[id]))
	{
		return
	}

	// Copy the name to the global name holder and save it to the data base
	copy(g_szUserName[id], charsmax(g_szUserName[]), szNewName)
	Func_SavePlayerName(id)
}

public OnCmdShow(id, iLevel, iCID)
{
	if (!cmd_access(id, iLevel, iCID, 2))
	{
		return PLUGIN_HANDLED
	}

	// Get client's arguments
	new szArg[33]
	read_argv(1, szArg, charsmax(szArg))

	// Target the player by the arguments
	new iTargetPlayer = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF)
	if (!iTargetPlayer)
	{
		return PLUGIN_HANDLED
	}

	// Inform the player some bullshit
	console_print(id, "[%s] A request has been sent!", PLUGIN)
	console_print(id, "[%s] Note that the plugin is using external storage and the request might take some time!", PLUGIN)
	console_print(id, "[%s] Also note that we are using ^"identifiers^" that can be changed and the information might not be 100% accurate", PLUGIN)
	
	// Request player names
	Func_RequestPlayer(id, iTargetPlayer)

	return PLUGIN_HANDLED
}

Func_RequestPlayer(id, iTargetPlayer)
{
	// Get addtional user information to track him by 
	new szUserIP[33], szUserAuthID[33]
	get_user_ip(id, szUserIP, charsmax(szUserIP), 1)
	get_user_authid(id, szUserAuthID, charsmax(szUserAuthID))

	// Format the query and launch a thread worker to wait for its execution
	new szQuery[128], szID[2]
	szID[0] = id; szID[1] = iTargetPlayer
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `%s` WHERE `useraddress` = '%s' OR `usersteam` = '%s';", TABLE, szUserIP, szUserAuthID)
	SQL_ThreadQuery(g_iSQLTuple, "OnCommandSelectExecuted", szQuery, szID, sizeof(szID))
}

public OnCommandSelectExecuted(iFailState, Handle:iQuery, szError[], iErrorNum, szData[])
{
	if (iFailState != TQUERY_SUCCESS)
	{
		log_amx("[%s] Failed to select", PLUGIN)
		log_amx("[%s] %s", PLUGIN, szError)
		return
	}


	new id = szData[0], iTargetPlayer = szData[1]
	// Get addtional user information to track him by 
	new szUserIP[33], szUserAuthID[33], bool:bPlayerSteam = is_user_steam(iTargetPlayer)
	get_user_ip(iTargetPlayer, szUserIP, charsmax(szUserIP), 1)
	get_user_authid(id, szUserAuthID, charsmax(szUserAuthID))

	new eTempArray[PlayerInfo]
	new iRowCount = SQL_NumResults(iQuery)
	if (!iRowCount)
	{
		client_print(id, print_console, "[%s] We could not find any players matching the players information", PLUGIN)
		return
	}

	if (SQL_MoreResults(iQuery))
	{
		for (new i = 0; i < iRowCount; i++)
		{
			SQL_ReadResult(iQuery, 1, eTempArray[Name], charsmax(eTempArray[Name]))
			SQL_ReadResult(iQuery, 2, eTempArray[IP], charsmax(eTempArray[IP]))
			SQL_ReadResult(iQuery, 3, eTempArray[Steam], charsmax(eTempArray[Steam]))
			ArrayPushArray(g_aTempPlayerArray, eTempArray)
			SQL_NextRow(iQuery)
		}
	}
	// Format the frame and print target player addtional information

	console_print(id, "*************************************************")
	console_print(id, "Player Successfuly Requested")
	console_print(id, "*************************************************")
	console_print(id, "Information =>")
	console_print(id, "Player IP: %s", szUserIP)
	console_print(id, "Player SteamID: %s", szUserAuthID)
	console_print(id, "Is Player Steam: %s", bPlayerSteam ? "Yes" : "Not")
	console_print(id, "Results Found: %i", iRowCount)

	console_print(id, "*************************************************")
	console_print(id, "Nicknames with same IP(%s) =>", szUserIP)
	for (new i = 0; i < iRowCount; i++)
	{
		ArrayGetArray(g_aTempPlayerArray, i, eTempArray)
		if (equal(eTempArray[IP], szUserIP))
		{
			console_print(id, "Player Name: %s; Player SteamID: %s;", eTempArray[Name], eTempArray[Steam])
		}
	}
	console_print(id, "*************************************************")

	if (equal("HLTV", szUserAuthID) || equal("STEAM_ID_LAN", szUserAuthID) || equali("VALVE_ID_LAN", szUserAuthID))
	{
		console_print(id, "The Player has the standard cracked SteamID and cannot be tracked trough it!", szUserAuthID)
	}
	else
	{
		console_print(id, "Nicknames with same SteamID(%s) =>", szUserAuthID)

		if (!bPlayerSteam)
		{
			console_print(id, "This information can be inaccurate!!!")
		}

		for (new i = 0; i < iRowCount; i++)
		{
			ArrayGetArray(g_aTempPlayerArray, i, eTempArray)
			if (equal(eTempArray[Steam], szUserAuthID))
			{
				console_print(id, "Player Name: %s; Player IP: %s;", eTempArray[Name], eTempArray[IP])
			}
		}
	}
	console_print(id, "*************************************************")

}

Func_SavePlayerName(id)
{
	// Get addtional user information to track him by 
	new szUserIP[33], szUserAuthID[33]
	get_user_ip(id, szUserIP, charsmax(szUserIP), 1)
	get_user_authid(id, szUserAuthID, charsmax(szUserAuthID))

	// Format the query and launch a thread worker to wait for its execution
	new szQuery[128], szID[1]
	szID[0] = id
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `%s` WHERE `username` = '%s' AND `useraddress` = '%s' AND `usersteam` = '%s';", TABLE, g_szUserName[id], szUserIP, szUserAuthID)
	SQL_ThreadQuery(g_iSQLTuple, "OnSelectExecuted", szQuery, szID, 1)
}

public OnSelectExecuted(iFailState, Handle:iQuery, szError[], iErrorCode, szData[1])
{
	if (iFailState != TQUERY_SUCCESS)
	{
		log_amx("[%s] Failed to select", PLUGIN)
		log_amx("[%s] %s", PLUGIN, szError)
		return
	}

	// Check if anything is selected
	if (SQL_NumResults(iQuery) > 0)
	{
		return
	}

	new id = szData[0]
	log_amx("[%s] Saving user %s", PLUGIN, g_szUserName[id])
	server_print("[%s] Saving user %s", PLUGIN, g_szUserName[id])
	// Get addtional user information to track him by 
	new szUserIP[33], szUserAuthID[33]
	get_user_ip(id, szUserIP, charsmax(szUserIP), 1)
	get_user_authid(id, szUserAuthID, charsmax(szUserAuthID))

	// Format the query and launch a thread worker to wait for its execution
	new szQuery[128]
	formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s` (`username`, `useraddress`, `usersteam`) VALUES ('%s', '%s', '%s');", TABLE, g_szUserName[id], szUserIP, szUserAuthID)
	SQL_ThreadQuery(g_iSQLTuple, "QueryEmptyHandle", szQuery)
}

public QueryEmptyHandle(iFailState, Handle:iQuery, szError[])
{
	if (iFailState != TQUERY_SUCCESS)
	{
		log_amx(szError)
	}
}