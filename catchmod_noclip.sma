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

// 3rd Part
#include <catchmod>
#include <cromchat>
#pragma unused g_szTeamsNames

// mi0 utils
// #define UTIL_FADEEFFECT
// #define UTIL_HUDMESSAGE
// #define UTIL_CLIENTCMD
// #define UTIL_LICENSE 0
// #define UTIL_KUR print_chat

// #include <mi0_utils>

// Defines
// Main plugin Defines
#define PLUGIN  "Catch Mod: Admin Menu"
#define VERSION CATCHMOD_VER
#define AUTHOR  "mi0"

// Enums
// Add your code here...

// Consts
new const g_iModes[2] = 
{
	MOVETYPE_WALK,
	MOVETYPE_NOCLIP
}

new const g_szMessages[2][] =
{
	"^1sprq",
	"^1pusna"
}

new const g_szStates[2][] =
{
	"- \yON",
	"- \rOFF"
}

// Global Vars
new bool:g_bNoClipMode[MAXPLAYERSVAR], g_szNames[MAXPLAYERSVAR][32]

// Plugin forwards
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("nightvision", "CMD_AdminMenu", ADMIN_BAN)
	register_concmd("amx_noclip", "CMD_NoClip", ADMIN_BAN)
	register_concmd("amx_turbo", "CMD_Turbo", ADMIN_BAN)
	CC_SetPrefix("^4Catch Mod >>")
}

public client_connectex(id)
{
	get_user_name(id, g_szNames[id], charsmax(g_szNames[]))
}

public client_infochanged(id)
{
	new szNewName[32]
	get_user_info(id, "name", szNewName, charsmax(szNewName))

	if (!equal(szNewName, g_szNames[id]))
	{
		copy(g_szNames[id], charsmax(g_szNames[]), szNewName)
	}
}

// Cmds
public CMD_AdminMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}

	AdminMenu_Open(id)

	return PLUGIN_HANDLED
}

public CMD_NoClip(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}

	if (!read_argc())
	{
		NoClipMenu_Open(id)
		return PLUGIN_HANDLED
	}

	new szArgs[32], iTarget
	read_argv(1, szArgs, charsmax(szArgs))

	if (!(iTarget = cmd_target(id, szArgs, CMDTARGET_ALLOW_SELF)))
	{
		return PLUGIN_HANDLED
	}

	NoClip_SwitchUser(iTarget)
	NoClip_SendMessage(id, iTarget)

	return PLUGIN_HANDLED
}

// Ham/Reapi/Fm/Engine Forwards
// Add your code here...

// Menus
//AdminMenu
AdminMenu_Open(id)
{
	new iMenu = menu_create("\rAdmin Menu", "AdminMenu_Handler")
	MakePlayerMenu(iMenu)
	menu_display(id, iMenu)
}

public AdminMenu_Handler(id, iMenu, iItem)
{
	if (iItem == MENU_EXIT)
	{
		goto AdminMenu_Exit
	}

	new iUnused, szInfo[1], szName[1]
	menu_item_getinfo(iMenu, iItem, iUnused, szInfo, 1, szName, 1, iUnused)

	new iTarget = szInfo[0]
	AdministerUserMenu_Open(id, iTarget)

	AdminMenu_Exit:
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

AdministerUserMenu_Open(id, iTarget)
{
	new szTemp[192], iTemp, iMenu
	formatex(szTemp, charsmax(szTemp), "\rAdministring \y%s", g_szNames[iTarget])
	iMenu = menu_create(szTemp, "AdministerUserMenu_Handler")

	if (is_user_alive(iTarget))
	{
		AddAliveAdminister
	}
	else
	{

	}

	menu_display(id, iMenu)
}
//NoClip
NoClipMenu_Open(id)
{
	new iMenu = menu_create("\rNoClip Admin Menu", "NoClipMenu_Handler")
	MakePlayerMenu(iMenu)
	menu_display(id, iMenu)
}

public NoClipMenu_Handler(id, iMenu, iItem)
{
	if (iItem == MENU_EXIT)
	{
		goto NoClipMenu_Exit
	}

	new iUnused, szInfo[1], szName[1]
	menu_item_getinfo(iMenu, iItem, iUnused, szInfo, 1, szName, 1, iUnused)

	new iTarget = szInfo[0]
	if (!is_user_alive(iTarget))
	{
		goto NoClipMenu_Exit
	}

	NoClip_SwitchUser(id)
	NoClip_SendMessage(id, iTarget)

	NoClipMenu_Exit:
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

// Custom Functions
MakePlayerMenu(iMenu)
{
	new iPlayers[32], iPlayersNum, iTarget, szLine[64], szInfo[1]
	get_players(iPlayers, iPlayersNum, "a")

	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		iTarget = iPlayers[iPlayersNum]
		get_user_name(iTarget, szLine, charsmax(szLine))
		szInfo[0] = get_user_userid(iTarget)

		add(szLine, charsmax(szLine), g_szStates[_:g_bNoClipMode[iTarget]])
		menu_additem(iMenu, szLine, szInfo)
	}
}

bool:checkUserNoClip(id)
{
	return (g_bNoClipMode[id] = (get_entvar(id, var_movetype) == MOVETYPE_NOCLIP ? true : false)) 
}

NoClip_SwitchUser(id)
{
	checkUserNoClip(id)
	g_bNoClipMode[id] = !g_bNoClipMode[id]
	set_entvar(id, var_movetype, g_iModes[_:g_bNoClipMode[id]])
}

NoClip_SendMessage(id, iTarget)
{
	CC_SendMatched(0, id, "^3%s %s ^3NoClip ^1Mode-a na ^3%s", g_szNames[id], g_szMessages[_:g_bNoClipMode[iTarget]], g_szNames[iTarget])
}

// Stocks
// Add your code here...

// Natives
// Add your code here...