#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>

enum Teams
{
	FLEER = 0,
	CATCHER,
	TRAINING,
	NONE
}

new g_iCvarSpeed
new bool:g_bTrainingOn
new Teams:g_iTeams[5]
new g_iLastWinner

public plugin_init()
{
	register_plugin("Catch Mod: Main", "4.0", "mi0")

	g_iCvarSpeed = register_cvar("catch_speed", "640.0")

	new iGravityPointer = get_cvar_pointer("sv_gravity")
	set_pcvar_num(iGravityPointer, 600)

	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "OnPlayerResetMaxSpeed", 1)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnTakeDamage")
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", 1)
	RegisterHookChain(RG_RoundEnd, "OnRoundEnd")
	RegisterHam(Ham_Touch, "player", "OnPlayerTouch")
	register_message(get_user_msgid("TextMsg"), "TextMsgHook")


	// SUPERCEDE
	RegisterHam(Ham_Spawn, "hostage_entity", "HamSupercedeHandler")
	RegisterHam(Ham_Spawn, "monster_scientist", "HamSupercedeHandler")
	RegisterHam(Ham_Spawn, "func_hostage_rescue", "HamSupercedeHandler")
	RegisterHam(Ham_Spawn, "info_hostage_rescue", "HamSupercedeHandler")
	RegisterHam(Ham_Spawn, "func_bomb_target", "HamSupercedeHandler")
	RegisterHam(Ham_Spawn, "info_bomb_target", "HamSupercedeHandler")
	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "ReapiSupercedeHandler")
	RegisterHookChain(RG_CSGameRules_GiveC4, "ReapiSupercedeHandler")
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "ReapiSupercedeHandler")
}

public plugin_cfg()
{
	g_iTeams[1] = FLEER
	g_iTeams[2] = CATCHER
	g_iTeams[3] = NONE
}

public plugin_precache()
{
	precache_model("models/v_shoots.mdl")
}


public OnPlayerTouch(iToucher, iTouched)
{
	if (!is_user_connected(iTouched) || g_bTrainingOn)
	{
		return HAM_IGNORED
	}
	
	new iKiller, iVictim
	switch (g_iTeams[get_member(iToucher, m_iTeam)])
	{
		case CATCHER:
		{
			iKiller = iToucher
			iVictim = iTouched
		}
		default:
		{
			iKiller = iTouched
			iVictim = iToucher
		}
	}

	user_silentkill(iVictim)
	make_deathmsg(iKiller, iVictim, 1, "weapon_knife")

	set_entvar(iKiller, var_frags, get_entvar(iKiller, var_frags) + 1.0)
	set_member(iVictim, m_iDeaths, get_member(iVictim, m_iDeaths) + 1)

	return HAM_IGNORED
}

public OnPlayerResetMaxSpeed(id)
{
	if (is_user_alive(id))
	{
		set_entvar(id, var_maxspeed, get_pcvar_float(g_iCvarSpeed))
		set_entvar(id, var_viewmodel, "models/v_shoots.mdl")
	}
}

public ReapiSupercedeHandler()
{
	return HC_SUPERCEDE
}

public HamSupercedeHandler()
{
	return HAM_SUPERCEDE
}

public OnTakeDamage()
{
	SetHookChainArg(4, ATYPE_FLOAT, 0.0)
}

public OnPlayerSpawn(id)
{
	new iTeam = get_member(id, m_iTeam)

	if (1 <= iTeam <= 2)
	{
		rg_give_item(id, "weapon_knife")
	}
}

public TextMsgHook()
{
	static szMsg[32]
	get_msg_arg_string(2, szMsg, charsmax(szMsg))

	if (equal(szMsg, "#Game_Commencing"))
	{
		g_iTeams[1] = FLEER
		g_iTeams[2] = CATCHER

		return PLUGIN_CONTINUE 
	}
	else if ((equal(szMsg, "#Terrorists_Win") || equal(szMsg, "#CTs_Win") || equal(szMsg, "#Target_Saved") || equal(szMsg, "#CTs_Win")) && !g_bTrainingOn)
	{
		new iPlayers[32], iPlayersNum
		new iTemp

		if (g_iTeams[1] == FLEER)
		{
			iTemp = 1
			get_players_ex(iPlayers, iPlayersNum, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST")
		}
		else
		{
			iTemp = 2
			get_players_ex(iPlayers, iPlayersNum, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT")
		}

		if (iPlayersNum)
		{
			g_iLastWinner = iTemp

			for (new i, iTarget; i < iPlayersNum; i++)
			{
				iTarget = iPlayers[i]
				set_entvar(iTarget, var_frags, get_entvar(iTarget, var_frags) + 3.0)
			}

			client_print(0, print_chat, "Fleers won the round")
		}
		else
		{
			g_iLastWinner = iTemp == 1 ? 2 : 1
			client_print(0, print_chat, "Catchers won the round")
		}

		if (g_iTeams[1] == FLEER)
		{
			g_iTeams[1] = CATCHER
			g_iTeams[2] = FLEER
		}
		else
		{
			g_iTeams[1] = FLEER
			g_iTeams[2] = CATCHER
		}
	}

	return PLUGIN_CONTINUE
}

public OnRoundEnd()
{
	if (g_iLastWinner == 1)
	{
		SetHookChainArg(0, ATYPE_INTEGER, WINSTATUS_TERRORISTS)
	}
	else if (g_iLastWinner == 2)
	{
		SetHookChainArg(0, ATYPE_INTEGER, WINSTATUS_CTS)
	}
	else
	{
		SetHookChainArg(0, ATYPE_INTEGER, WINSTATUS_DRAW)
	}

	g_iLastWinner = 0
}