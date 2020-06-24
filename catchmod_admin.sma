#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <CromChat>
#include <catchmod>

new bool:g_bWait[MAX_PLAYERS + 1]

new g_fwd_AddToFullPack

public plugin_init()
{
	register_plugin("Catch Mod: Admin", CATCHMOD_VER, "mi0")

	register_clcmd("say /wait", "CMD_Wait")
	register_clcmd("+cool", "cmd_cool", ADMIN_RCON)
	register_clcmd("-cool", "cmd_cool", ADMIN_RCON)

	CC_SetPrefix("&x03[&x01GOD&x03]")
}

public cmd_cool(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}

	if (g_bWait[id])
	{
		return PLUGIN_HANDLED
	}

	new szCmd[2]
	read_argv(0, szCmd, charsmax(szCmd))
	catchmod_set_cantbesolid(id, szCmd[0] == '+')

	return PLUGIN_HANDLED
}

public CMD_Wait(id)
{
	if (~get_user_flags(id) & ADMIN_RCON)
	{
		return PLUGIN_CONTINUE
	}

	g_bWait[id] = !g_bWait[id]
	catchmod_set_cantbesolid(id, g_bWait[id])

	set_pev(id, pev_solid, g_bWait[id] ? SOLID_NOT : SOLID_SLIDEBOX)
	CC_SendMessage(id, "Wait mode: &x03%s", g_bWait[id] ? "On" : "Off")

	return PLUGIN_HANDLED
}