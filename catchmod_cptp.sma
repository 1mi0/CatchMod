#include <amxmodx>
#include <reapi>
#include <cromchat>
#include <catchmod>
#include <fakemeta>

#define CHECKINTRAIN(%1,%2) if (catchmod_get_user_team(%1) != TRAINING || !is_user_alive(%1)) {%2}

new Float:g_fSavedCoords[MAX_PLAYERS + 1][3]
new bool:g_bWasInDuck[MAX_PLAYERS + 1]
new bool:g_bHasSavedCoords[MAX_PLAYERS + 1]
new g_iMenu

new g_iChannel[MAX_PLAYERS + 1]

public plugin_init()
{
	register_plugin("Catch Mod: TP/CP", CATCHMOD_VER, "mi0")
	
	g_iMenu = menu_create("\rTraining: \yTP/CP Menu", "Menu_TPCP_Handler")
	menu_additem(g_iMenu, "Save Coords")
	menu_additem(g_iMenu, "Teleport")
	menu_additem(g_iMenu, "Channel")

	register_clcmd("cp", "Func_SaveCoord")
	register_clcmd("tp", "Func_Teleport")
	register_clcmd("say", "Func_Channel")
	register_clcmd("say /trainmenu", "Func_TrainMenu")

	register_forward(FM_AddToFullPack, "FM__AddToFullPack_Pre")
	
	CC_SetPrefix("&x03[&x01GOD&x03]")
}

public client_disconnected(id)
{
	g_bHasSavedCoords[id] = false
}

public client_connectex(id)
{
	g_iChannel[id] = 1
}

public Func_Channel(id)
{
	if (!is_user_connected(id))
	{
		return PLUGIN_HANDLED
	}

	new szArg[192]
	read_argv(1, szArg, charsmax(szArg))

	if (!replace_all(szArg, charsmax(szArg), "/channel ", ""))
	{
		return PLUGIN_CONTINUE
	}
	trim(szArg)

	new channel = str_to_num(szArg)
	if (1 > channel)
	{
		CC_SendMessage(id, "Invalid number!")
		return PLUGIN_CONTINUE
	}

	if (catchmod_get_user_team(id) != TRAINING)
	{
		CC_SendMessage(id, "You must be in training!")
		return PLUGIN_HANDLED
	}

	if (channel == g_iChannel[id])
	{
		CC_SendMessage(id, "You are already in that channel!")
		return PLUGIN_HANDLED
	}

	channel = clamp(channel, 1, 1337)
	CC_SendMessage(id, "Your new channel is: &x03%i", channel)

	g_iChannel[id] = channel
	rg_add_account(id, channel, AS_SET)

	return PLUGIN_HANDLED
}

public Func_TrainMenu(id)
{
	CHECKINTRAIN(id, return;)
	menu_display(id, g_iMenu)
}

public Menu_TPCP_Handler(id, iMenu, iItem)
{
	CHECKINTRAIN(id, menu_cancel(id);return PLUGIN_HANDLED;)

	if (iItem == MENU_EXIT)
	{
		menu_cancel(id)
		return PLUGIN_HANDLED
	}

	switch (iItem)
	{
		case 1:
		{
			Func_Teleport(id)
		}
		case 0:
		{
			Func_SaveCoord(id)
		}
		case 2:
		{
			client_cmd(id, "messagemode /channel ")
		}
	}

	Func_TrainMenu(id)
	return PLUGIN_HANDLED
}

public Func_Teleport(id)
{
	CHECKINTRAIN(id, return;)

	if (!g_bHasSavedCoords[id])
	{
		CC_SendMessage(id, "You don't have any saved coords...")
		return
	}

	new iFlags = get_entvar(id, var_flags)
	if (g_bWasInDuck[id] && ~iFlags & FL_DUCKING)
	{
		set_entvar(id, var_flags, iFlags | FL_DUCKING)
	}

	set_entvar(id, var_velocity, {0.0, 0.0, 0.0})
	set_entvar(id, var_origin, g_fSavedCoords[id])
}

public Func_SaveCoord(id)
{
	CHECKINTRAIN(id, return;)

	g_bWasInDuck[id] = bool:(get_entvar(id, var_flags) & FL_DUCKING)
	get_entvar(id, var_origin, g_fSavedCoords[id])
	g_bHasSavedCoords[id] = true
}

public FM__AddToFullPack_Pre(iEs, e, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (!iPlayer || !is_user_alive(iEnt))
	{
		return FMRES_IGNORED
	}

	if (g_iChannel[iEnt] != g_iChannel[iHost] && (catchmod_get_user_team(iEnt) == TRAINING || catchmod_get_user_team(iHost) == TRAINING))
	{
		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}