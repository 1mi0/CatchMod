// Default Includes
#include <amxmodx>
#include <amxmisc>

// Module Includes
#include <reapi>
#include <hamsandwich>

// 3rd Part Includes
#include <cromchat>

// Catch Mod Includes
#include <catch_const>

enum _:PlayerData
{
	WallTouches,
	float:Velocity[3]
}

new g_ePlayerData[33][PlayerData]

new g_iCvarTouches

public plugin_init()
{
	register_plugin("Catch Mod: Walls", CATCHMOD_VER, "mi0")

	//Cvars
	g_iCvarTouches = register_cvar("catch_walls_touches", "3")

	//Forwards
	RegisterHam(Ham_Touch, "player", "OnPlayerTouch")
	RegisterHookChain(RG_CBasePlayer_Jump, "OnPlayerJump")
}

//Forwards
public OnPlayerTouch(iPlayer, iSurface)
{
	if (g_ePlayerData[iPlayer][WallTouches] >= get_pcvar_num(g_iCvarTouches) || ~get_entvar(iPlayer, var_button) & IN_JUMP)
	{
		return HAM_IGNORED
	}

	new szClassName[32]
	get_entvar(iSurface, var_classname, szClassName, charsmax(szClassName))

	if (!equal(szClassName, "worldspawn") && !equal(szClassName, "func_breakable"))
	{
		return HAM_IGNORED
	}

	g_ePlayerData[iPlayer][Velocity][0] = -g_ePlayerData[iPlayer][Velocity][0]
	set_entvar(iPlayer, var_velocity, g_ePlayerData[iPlayer][Velocity][0])

	g_ePlayerData[iPlayer][WallTouches]++
}

public OnPlayerJump(id)
{
	if (~get_entvar(id, var_flags) & FL_ONGROUND)
	{
		return HAM_IGNORED
	}

	get_entvar(id, var_velocity, g_ePlayerData[id][Velocity])
	g_ePlayerData[id][Velocity][2] = 250
	set_entvar(id, var_velocity, g_ePlayerData[id][Velocity])
	g_ePlayerData[id][Velocity][2] = 300

	if (~get_entvar(id, var_oldbuttons) & IN_JUMP)
	{
		g_ePlayerData[id][WallTouches] = 0
	}
	else
	{
		g_ePlayerData[id][WallTouches] = get_pcvar_num(g_iCvarTouches)
	}
}