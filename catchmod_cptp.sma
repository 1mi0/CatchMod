#include <amxmodx>
#include <reapi>
#include <cromchat>
#include <catchmod>

#define CHECKINTRAIN(%1,%2) if (catchmod_get_user_team(%1) != TRAINING || !is_user_alive(%1)) {%2}

new Float:g_fSavedCoords[MAX_PLAYERS + 1][3]
new bool:g_bWasInDuck[MAX_PLAYERS + 1]
new bool:g_bHasSavedCoords[MAX_PLAYERS + 1]
new g_iMenu

public plugin_init()
{
	register_plugin("Catch Mod: TP/CP", CATCHMOD_VER, "mi0")
	
	g_iMenu = menu_create("\rTraining: \yTP/CP Menu", "Menu_TPCP_Handler")
	menu_additem(g_iMenu, "Save Coords")
	menu_additem(g_iMenu, "Teleport")

	register_clcmd("cp", "Func_SaveCoord")
	register_clcmd("tp", "Func_Teleport")
	register_clcmd("say /trainmenu", "Func_TrainMenu")
	
	CC_SetPrefix("&x03[&x01GOD&x03]")
}

public client_disconnected(id)
{
	g_bHasSavedCoords[id] = false
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