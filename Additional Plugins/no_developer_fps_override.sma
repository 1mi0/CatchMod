#include <amxmodx>
#include <fakemeta>
#include <cromchat>

new const PLUGIN_VERSION[] = "1.0"

enum fVars
{
	Float:NO_STEAM_FPS_LIMIT,
	Float:STEAM_FPS_LIMIT,
	MAX_PLAYER_WARNS
}

new g_eCvars[fVars]

enum _:eData
{
	WARN_STEAM,
	WARN_NO_STEAM,
	PLAYER_FPS
}

new g_iPlayerData[MAX_PLAYERS + 1][eData]

public plugin_init() {
	register_plugin("No Developer/FPS Override", PLUGIN_VERSION, "Huehue @ AMXX-BG.INFO")
	register_cvar("No_Developer_FPS_Override", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_PROTECTED)
	
	register_forward(FM_CmdStart, "Player_CmdStart")

	new pCvar

	pCvar = create_cvar("nd_max_fps_nosteam", "100.0", FCVAR_PROTECTED, "Maximum FPS No Steam Users can use")
	bind_pcvar_float(pCvar, g_eCvars[NO_STEAM_FPS_LIMIT])

	pCvar = create_cvar("nd_max_fps_steam", "100.5", FCVAR_PROTECTED, "Maximum FPS Steam Users can use")
	bind_pcvar_float(pCvar, g_eCvars[STEAM_FPS_LIMIT])

	pCvar = create_cvar("nd_max_fps_warnings", "3", FCVAR_NONE, "After X warnings player will be kicked")
	bind_pcvar_num(pCvar, g_eCvars[MAX_PLAYER_WARNS])

	AutoExecConfig(true, "NoDeveloper", "HuehuePlugins_Config")

}

public client_connect(id)
{
	g_iPlayerData[id][WARN_STEAM] = g_iPlayerData[id][WARN_NO_STEAM] = 0
	set_task(10.0, "Delayed_Connect", id)
}

public Delayed_Connect(id)
{
	if (is_user_connected(id))
		set_task(1.0, "Player_PostThink", id, .flags = "b")
}

public Player_CmdStart(id, uc_handle)
{
	if (is_user_alive(id))
	{
		g_iPlayerData[id][PLAYER_FPS] = floatround(1 / (get_uc(uc_handle, UC_Msec) * 0.001))
	}
	return FMRES_IGNORED
}
public Player_PostThink(id)
{
	if (!is_user_alive(id))
		return PLUGIN_HANDLED

	if (is_user_steam(id))
	{
		if (g_iPlayerData[id][PLAYER_FPS] > g_eCvars[STEAM_FPS_LIMIT])
		{
			if (++g_iPlayerData[id][WARN_STEAM] <= g_eCvars[MAX_PLAYER_WARNS])
			{
				CC_LogMessage(id, "NoDeveloper.txt", "&x03[&x01Warn: &x04%i&x03] &x01Your FPS is &x04%i &x01please correct it and set it to &x03%.f &x01or you will be &x04kicked", g_iPlayerData[id][WARN_STEAM], g_iPlayerData[id][PLAYER_FPS], g_eCvars[STEAM_FPS_LIMIT])
			}
			else
			{
				CC_LogMessage(0, "NoDeveloper.txt", "&x04[&x03Player FPS: &x04%i] &x03%n &x01has been kicked due to &x04overriding &x01the &x04FPS Limit&x01. &x03(&x01FPS Override: &x04%i&x03)", g_iPlayerData[id][PLAYER_FPS], id, (g_iPlayerData[id][PLAYER_FPS] - floatround(g_eCvars[STEAM_FPS_LIMIT])))

				server_cmd("kick #%d ^"%d FPS Detected. FPS Override is forbidden (FPS Limit > %.f) (FPS Overrided by %i)^"", get_user_userid(id), g_iPlayerData[id][PLAYER_FPS], g_eCvars[STEAM_FPS_LIMIT], (g_iPlayerData[id][PLAYER_FPS] - floatround(g_eCvars[STEAM_FPS_LIMIT])))
			}
		}
		else
		{
			g_iPlayerData[id][WARN_STEAM] = 0
		}
	}
	else
	{
		if (g_iPlayerData[id][PLAYER_FPS] > g_eCvars[NO_STEAM_FPS_LIMIT])
		{
			if (++g_iPlayerData[id][WARN_NO_STEAM] <= g_eCvars[MAX_PLAYER_WARNS])
			{
				CC_LogMessage(id, "NoDeveloper.txt", "&x03[&x01Warn: &x04%i&x03] &x01Your FPS is &x04%i &x01please correct it and set it to &x03%.f &x01or you will be &x04kicked", g_iPlayerData[id][WARN_NO_STEAM], g_iPlayerData[id][PLAYER_FPS], g_eCvars[NO_STEAM_FPS_LIMIT])
			}
			else
			{
				CC_LogMessage(0, "NoDeveloper.txt", "&x04[&x03Player FPS: &x04%i] &x03%n &x01has been kicked due to &x04overriding &x01the &x04FPS Limit&x01. &x03(&x01FPS Override: &x04%i&x03)", g_iPlayerData[id][PLAYER_FPS], id, (g_iPlayerData[id][PLAYER_FPS] - floatround(g_eCvars[NO_STEAM_FPS_LIMIT])))

				server_cmd("kick #%d ^"%d FPS Detected. Developer is forbidden (FPS Limit > %.f) (FPS Overrided by %i)^"", get_user_userid(id), g_iPlayerData[id][PLAYER_FPS], g_eCvars[NO_STEAM_FPS_LIMIT], (g_iPlayerData[id][PLAYER_FPS] - floatround(g_eCvars[NO_STEAM_FPS_LIMIT])))
			}
		}
		else
		{
				g_iPlayerData[id][WARN_NO_STEAM] = 0
		}
	}
	return PLUGIN_HANDLED
}
stock bool:is_user_steam(id)
{
	static dp_pointer
	
	if (dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", id)
		server_exec()
		return (get_pcvar_num(dp_pointer) == 2) ? true : false
	}
	return false;
}