#include <amxmodx>
#include <reapi>

new g_iCvarSpeed

public plugin_init()
{
	register_plugin("Catch Mod: Main", "4.0", "mi0")

	g_iCvarSpeed = register_cvar("catch_walls_speed", "640.0")

	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "OnPlayerResetMaxSpeed")
}

public OnPlayerResetMaxSpeed(id)
{
	if (is_user_alive(id))
	{
		set_entvar(id, var_maxspeed, get_pcvar_float(g_iCvarSpeed))
	}
}