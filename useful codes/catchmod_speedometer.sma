#include <amxmodx>
#include <reapi>
#include <catchmod>

new g_iTaskEnt
new bool:g_bSpeedOn[33]
new g_iHudID

public plugin_init()
{
	register_plugin("Catch Mod: Speedometer", CATCHMOD_VER, "mi0")

	register_clcmd("say /speed", "cmd_speed")

	g_iHudID = CreateHudSyncObj()

	g_iTaskEnt = rg_create_entity("info_target")
	set_entvar(g_iTaskEnt, var_classname, "SpeedometerEnt")
	set_entvar(g_iTaskEnt, var_nextthink, get_gametime() + 1.0)
	SetThink(g_iTaskEnt, "OnEntThink")
}

public client_connect(id)
{
	g_bSpeedOn[id] = true
}

public cmd_speed(id)
{
	g_bSpeedOn[id] = !g_bSpeedOn[id]
	client_print(id, print_chat, "You successfuly turned your speed %s!", g_bSpeedOn[id] ? "On" : "Off")

	return PLUGIN_HANDLED
}

public OnEntThink()
{
	static i, iTarget
	static Float:fVelocity[3]
	static Float:fSpeed, Float:f2dmSpeed
	
	for (i = 1; i <= 32; i++)
	{
		if (!is_user_connected(i) || !g_bSpeedOn[i])
		{
			continue
		}
		
		iTarget = get_entvar(i, var_iuser1) == 4 ? get_entvar(i, var_iuser1) : i
		get_entvar(iTarget, var_velocity, fVelocity)

		fSpeed = vector_length(fVelocity)
		f2dmSpeed = floatsqroot(fVelocity[0] * fVelocity[0] + fVelocity[1] * fVelocity[1])
		
		set_hudmessage(255, 255, 255, -1.0, 0.7, 0, 0.0, 0.2, 0.01, 0.0)
		ShowSyncHudMsg(i, g_iHudID, "%3.2f units/second^n%3.2f velocity", fSpeed, f2dmSpeed)
	}

	set_entvar(g_iTaskEnt, var_nextthink, get_gametime() + 0.1)
}