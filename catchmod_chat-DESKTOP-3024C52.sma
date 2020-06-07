// Defaults
#include <amxmodx>
#include <amxmisc>

// Modules
// #include <cstrike>
#include <reapi>
// #include <engine>
// #include <fakemeta>
// #include <hamsandwich>
// #include <fun>
// #include <xs>
// #include <sqlx>
// #include <nvault>

// 3rd Part
#include <catchmod>

// mi0 utils
// #define UTIL_FADEEFFECT
// #define UTIL_HUDMESSAGE
// #define UTIL_CLIENTCMD
// #define UTIL_LICENSE 0
// #define UTIL_KUR print_chat

// #include <mi0_utils>

// Pragmas
// Add your code here...

// Defines
// Main plugin Defines
#define PLUGIN  "Catch Mod: Chat Manager"
#define VERSION CATCHMOD_VER
#define AUTHOR  "mi0"

// Enums
// Add your code here...

// Global Vars
// new bool:g_bAdminPrefix[32]

// Plugin forwards
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// register_clcmd("say /hide", "CMD_Hide")
	register_concmd("say", "CMD_Say")
	register_clcmd("say_team", "CMD_SayTeam")
}

// Cmds
// public CMD_Hide(id)
// {
// 	if (!is_user_admin(id))
// 	{
// 		return PLUGIN_HANDLED
// 	}

// 	g_bAdminPrefix[id] = !g_bAdminPrefix[id]
// 	client_print_color(id, id, "You^x04 %s^x01 your Admin Prefix!!", g_bAdminPrefix[id] ? "Hid" : "Shown")

// 	return PLUGIN_HANDLED
// }

public CMD_Say(id)
{
	new szMsg[192]
	read_args(szMsg, charsmax(szMsg))
	remove_quotes(szMsg)
	trim(szMsg)
	if (!szMsg[0] || !is_user_connected(id))
	{
		return PLUGIN_HANDLED
	}
	func_SendMessage(id, szMsg)

	return PLUGIN_HANDLED
}

public CMD_SayTeam(id)
{
	new szMsg[192]
	read_args(szMsg, charsmax(szMsg))
	remove_quotes(szMsg)
	trim(szMsg)
	if (!szMsg[0] || !is_user_connected(id))
	{
		return PLUGIN_HANDLED
	}
	func_SendMessage(id, szMsg, true)

	return PLUGIN_HANDLED
}

// Menus
// Add your code here...

// Ham/Reapi/Fm/Engine Forwards
// Add your code here...

// Custom Functions
func_SendMessage(id, szMsg[192], bool:bMsgToTeam = false)
{
	new szNewMsg[192], szPrefix[64]
	new iInGameTeam = get_member(id, m_iTeam)
	new Teams:iPlayerTeam = catchmod_get_user_team(id)

	if (id == 0)
	{
		formatex(szNewMsg, charsmax(szNewMsg), "^x05[Server] ^x01%s", szMsg)
		client_print_color(0, 0, szNewMsg)
		return
	}
	else if (iInGameTeam != 4)
	{
		// if (is_user_admin(id) && !g_bAdminPrefix[id])
		// {
		// 	formatex(szPrefix, charsmax(szPrefix), "^x04[Admin]")
		// }

		if (bMsgToTeam)
		{
			new szTeam[64]
			formatex(szTeam, charsmax(szTeam), " ^x04(^x01%s^x04)", g_szTeamsNames[iPlayerTeam])
			add(szPrefix, charsmax(szPrefix), szTeam)
		}
	}
	else 
	{
		return
	}

	new szName[32]
	get_user_name(id, szName, charsmax(szName))

	formatex(szNewMsg, charsmax(szNewMsg), "%s^x03 %s^x01 :  %s", szPrefix, szName, szMsg)

	switch (bMsgToTeam)
	{
		case false:
		{
			client_print_color(0, id, szNewMsg)
		}

		case true:
		{
			new iPlayers[32], iPlayersNum, iTempID
			get_players(iPlayers, iPlayersNum)

			for(--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
			{
				iTempID = iPlayers[iPlayersNum]
				if (is_user_admin(iTempID) || catchmod_get_user_team(iTempID) == iPlayerTeam)
				{
					client_print_color(iPlayers[iPlayersNum], id, szNewMsg)
				}
			}
		}
	}
}

// Stocks
// Add your code here...

// Natives
// Add your code here...