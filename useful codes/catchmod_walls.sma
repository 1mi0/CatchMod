// Default Includes
#include <amxmodx>

// Module Includes
#include <reapi>
#include <hamsandwich>

// Catch Mod Includes
#include <catch_const>

enum _:PlayerData
{
	WallTouches,
	bool:Jump
}

new g_ePlayerData[33][PlayerData]
new Float:g_fVel[33][3]

new g_iCvarTouches

public plugin_init()
{
	register_plugin("Catch Mod: Walls", CATCHMOD_VER, "mi0")

	//Cvars
	g_iCvarTouches = register_cvar("catch_walls_touches", "3")

	//Forwards
	RegisterHam(Ham_Touch, "player", "OnPlayerTouch")
	RegisterHam(Ham_Player_PreThink, "player", "OnPlayerThink")
	RegisterHookChain(RG_CBasePlayer_Jump, "OnPlayerJump")
}

public OnPlayerJump(id)
{
	if (get_entvar(id, var_flags) & FL_ONGROUND)
	{
		get_entvar(id, var_velocity, g_fVel[id])
		g_fVel[id][2] = 250.0
		set_entvar(id, var_velocity, g_fVel[id])
		set_entvar(id, var_gaitsequence, 6)
		set_entvar(id, var_frame, 0.0)
		g_fVel[id][2] = 300.0
	}
}

public OnPlayerThink(id)
{
	static iTouches
	iTouches = get_pcvar_num(g_iCvarTouches)

	if (get_entvar(id, var_flags) & FL_ONGROUND)
	{
		if (~get_entvar(id, var_oldbuttons) & IN_JUMP)
		{
			g_ePlayerData[id][WallTouches] = 0
		}
		else
		{
			g_ePlayerData[id][WallTouches] = iTouches
		}
	}

	if (g_ePlayerData[id][Jump])
	{
		g_fVel[id][0] = 0.0 - g_fVel[id][0]
		set_entvar(id, var_velocity, g_fVel[id])
		set_entvar(id, var_gaitsequence, 6)
		set_entvar(id, var_frame, 0.0)

		g_ePlayerData[id][WallTouches]++
		g_ePlayerData[id][Jump] = false
	}
}

//Forwards
public OnPlayerTouch(iPlayer, iSurface)
{
	if (g_ePlayerData[iPlayer][WallTouches] >= get_pcvar_num(g_iCvarTouches) || ~get_entvar(iPlayer, var_button) & IN_JUMP || get_entvar(iPlayer, var_flags) & FL_ONGROUND)
	{
		return HAM_IGNORED
	}

	static szClassName[33]
	get_entvar(iSurface, var_classname, szClassName, charsmax(szClassName))

	if (!equal(szClassName, "worldspawn") && !equal(szClassName, "func_breakable"))
	{
		return HAM_IGNORED
	}

	g_ePlayerData[iPlayer][Jump] = true

	return HAM_SUPERCEDE + 1
}