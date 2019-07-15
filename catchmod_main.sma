// Defaults
#include <amxmodx>
#include <amxmisc>

// Modules
#include <hamsandwich>
#include <reapi>
#include <engine>

// 3rd part
#include <catch_const>

// Cvars
new g_iCvarSpeed, g_iCvarTurbo, g_iCvarTurboSpeed, g_iCvarTouches
// Engine Vars
new bool:g_bTrainingOn
new Teams:g_iTeams[5]
new g_iLastWinner
new g_iHudEnt, g_iSyncHud
new bool:g_bCanKill
new bool:g_bGameCommencing
// Player Vars
new Teams:g_iPlayerTeams[33]
new g_iPlayerStats[33][2]
new g_iTurbo[33]
new bool:g_bTurboOn[33]
new Float:g_fPlayerSpeed[33]
new Float:g_fVel[33][3]
new g_iWallTouches[33]
new bool:g_bJump[33]

public plugin_init()
{
	register_plugin("Catch Mod: Main", "4.0", "mi0")

	// Cvars
	g_iCvarSpeed = register_cvar("catch_speed", "640.0")
	g_iCvarTurbo = register_cvar("catch_turbo", "30")
	g_iCvarTurboSpeed = register_cvar("catch_turbo_speed", "840.0")
	g_iCvarTouches = register_cvar("catch_walls_touches", "3")

	new iTempPointer
	iTempPointer = get_cvar_pointer("sv_gravity")
	set_pcvar_num(iTempPointer, 600)
	iTempPointer = get_cvar_pointer("sv_airaccelerate")
	set_pcvar_num(iTempPointer, 100)

	// Hooks
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "OnPlayerResetMaxSpeed", 1)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnTakeDamage")
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", 1)
	RegisterHookChain(RG_RoundEnd, "OnRoundEnd", 1)
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnNewRound", 1)
	RegisterHookChain(RG_CBasePlayer_Jump, "OnPlayerJump")
	register_touch("player", "worldspawn", "OnPlayerTouchWorld")
	register_touch("player", "func_breakable", "OnPlayerTouchWorld")
	register_touch("player", "player", "OnPlayerTouchPlayer")
	RegisterHam(Ham_Player_PreThink, "player", "OnPlayerThink")
	register_message(get_user_msgid("TextMsg"), "TextMsgHook")
	register_message(get_user_msgid("ScoreInfo"), "ScoreInfoChanged")

	// Hud
	g_iSyncHud = CreateHudSyncObj()
	g_iHudEnt = rg_create_entity("info_target")
	set_entvar(g_iHudEnt, var_classname, "HudEnt")
	set_entvar(g_iHudEnt, var_nextthink, get_gametime() + 1.0)
	SetThink(g_iHudEnt, "HudEntThinking")

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

// Teams
public plugin_cfg()
{
	g_iTeams[1] = FLEER
	g_iTeams[2] = CATCHER
	g_iTeams[3] = NONE
}

// Model
public plugin_precache()
{
	precache_model("models/v_shoots.mdl")
}

// Reset Vars, Update Stats
public client_putinserver(id)
{
	g_iPlayerStats[id][0] = 0
	g_iPlayerStats[id][1] = 0
	set_task(0.5, "UpdateStats", id)
}

public OnPlayerThink(id)
{
	// Turbo

	static iButtons, iOldButtons
	iButtons = get_entvar(id, var_button)
	iOldButtons = get_entvar(id, var_oldbuttons)

	if (iButtons & IN_ATTACK2 && ~iOldButtons & IN_ATTACK2)
	{
		TurboOn(id)
	}
	else if (~iButtons & IN_ATTACK2 && iOldButtons & IN_ATTACK2)
	{
		TurboOff(id + 2000)
	}

	// Wall Touch

	if (g_bJump[id])
	{
		g_fVel[id][0] = 0.0 - g_fVel[id][0]
		set_entvar(id, var_velocity, g_fVel[id])
		set_entvar(id, var_gaitsequence, 6)
		set_entvar(id, var_frame, 0.0)

		g_iWallTouches[id]++
		g_bJump[id] = false
	}
}

public OnPlayerJump(id)
{
	if (get_entvar(id, var_flags) & FL_ONGROUND)
	{
		// Bhop - imitaing jump
		get_entvar(id, var_velocity, g_fVel[id]) // Getting The velocity
		g_fVel[id][2] = 250.0 // Adding 250.0 to the 3rd dim - Up
		set_entvar(id, var_velocity, g_fVel[id]) // Setting the new velocity
		set_entvar(id, var_gaitsequence, 6) // Some animations
		set_entvar(id, var_frame, 0.0) // Some animations
		g_fVel[id][2] = 300.0 // Setting 300.0 to the 3rd dim for the wall jump
	
		// Reset
		if (~get_entvar(id, var_oldbuttons) & IN_JUMP) // if he is in bhop
		{
			g_iWallTouches[id] = 0 // no wall jumps
		}
		else
		{
			g_iWallTouches[id] = get_pcvar_num(g_iCvarTouches) // wall jump, cuz he is not in bhop
		}
	}
}

public OnPlayerTouchWorld(iPlayer)
{
	// Wall Touch

	if (g_iWallTouches[iPlayer] >= get_pcvar_num(g_iCvarTouches) || ~get_entvar(iPlayer, var_button) & IN_JUMP || get_entvar(iPlayer, var_flags) & FL_ONGROUND)
	{
		return // if he cant wall jump return
	}

	g_bJump[iPlayer] = true // setting true, so the next frame he'll wall jump
}

public OnPlayerTouchPlayer(iToucher, iTouched)
{
	// Kill

	if (!is_user_alive(iTouched) || !is_user_alive(iToucher) || g_bTrainingOn || !g_bCanKill || get_member(iToucher, m_iTeam) == get_member(iTouched, m_iTeam))
	{
		return // if they cant kill each other
	}
	
	// Who's the killer
	new iKiller, iVictim
	switch (g_iPlayerTeams[iToucher])
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

	user_silentkill(iVictim) // Silent killing the victim
	make_deathmsg(iKiller, iVictim, 1, "weapon_knife") // Making new death msg

	g_iPlayerStats[iKiller][0]++ // adding kills to the killer
	g_iPlayerStats[iVictim][1]++ // adding deaths to the victim
	UpdateStats(iKiller) // updating killer's stats
	UpdateStats(iVictim) // updating victim's stats
}

// Eound end & game commencing
public TextMsgHook(iMsgID, iMsgDest, id)
{
	static szMsg[32]
	get_msg_arg_string(2, szMsg, charsmax(szMsg)) // getting the msg

	if (equal(szMsg, "#Game_Commencing")) // if the game is commencing
	{
		if (g_bTrainingOn) // if training on
		{
			return PLUGIN_CONTINUE // return
		}

		// setting the default teams
		if (g_iTeam[1] == FLEER && g_iTeams[2] == CATCHER)
		{
			g_iTeams[1] = CATCHER
			g_iTeams[2] = FLEER
		}

		// reseting kills & deaths
		g_iPlayerStats[id][0] = 0
		g_iPlayerStats[id][1] = 0

		UpdateHud(id) // updating hud
		UpdateStats(id) // updating stats

		if (!g_bGameCommencing)
		{
			g_bGameCommencing = true
		} 
	}

	return PLUGIN_HANDLED
}

public OnRoundEnd()
{
	if (g_bGameCommencing && !g_bTrainingOn)
	{
		g_iTeams[1] = CATCHER
		g_iTeams[2] = FLEER

		g_bGameCommencing = false
		return
	}

	if (g_bTrainingOn)
	{
		return
	}

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
			g_iPlayerStats[iTarget][0] += 3
			UpdateStats(iTarget)
		}

		client_print(0, print_center, "Fleers won the round!")
	}
	else
	{
		g_iLastWinner = iTemp == 1 ? 2 : 1
		client_print(0, print_center, "Catchers won the round!")
	}

	g_bCanKill = false

	if (g_iLastWinner == 1)
	{
		SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_TERRORISTS)
	}
	else if (g_iLastWinner == 2)
	{
		SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_CTS)
	}
	else
	{
		SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_DRAW)
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

	g_iLastWinner = 0
}

// New Round
public OnNewRound()
{
	g_bCanKill = true
}

//Hud
public HudEntThinking()
{
	new iPlayers[32], iPlayersNum
	get_players_ex(iPlayers, iPlayersNum)

	for (new i; i < iPlayersNum; i++)
	{
		UpdateHud(iPlayers[i])
	}

	set_entvar(g_iHudEnt, var_nextthink, get_gametime() + 5.0)
}

UpdateHud(id)
{
	if (!is_user_alive(id))
	{
		return
	}

	new szTemp[192]
	switch (g_iPlayerTeams[id])
	{
		case FLEER:
		{
			formatex(szTemp, charsmax(szTemp), "Status : Fleer")
		}
		case CATCHER:
		{
			formatex(szTemp, charsmax(szTemp), "Status : Catcher")
		}
		case TRAINING:
		{
			formatex(szTemp, charsmax(szTemp), "Status : Training")
		}
		default:
		{
			formatex(szTemp, charsmax(szTemp), "Status : None")
		}
	}

	if (g_iTurbo[id] >= 10)
	{
		format(szTemp, charsmax(szTemp), "%s^n%sTurbo: [======|======] %i%", szTemp, g_bTurboOn[id] ? "+" : "-", g_iTurbo[id])
	}
	else if (g_iTurbo[id] < 10 && g_iTurbo[id] >= 0)
	{
		format(szTemp, charsmax(szTemp), "%s^nTurbo: Out of fuel", szTemp)
	}
	else
	{
		format(szTemp, charsmax(szTemp), "%s^nTurbo: Off", szTemp)
	}

	set_hudmessage(255, 255, 255, 0.02, 0.24, 0, 0.0, 5.0, 0.2, 0.0)
	ShowSyncHudMsg(id, g_iSyncHud, szTemp)
}

// Stats
public ScoreInfoChanged(iMsgId, iMsgDest, id)
{	
	return PLUGIN_HANDLED
}

public UpdateStats(id)
{
	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(id)
	write_short(g_iPlayerStats[id][0])
	write_short(g_iPlayerStats[id][1])
	write_short(0)
	write_short(get_member(id, m_iTeam))
	message_end()
}

// Turbo
TurboOn(id)
{
	if (g_iTurbo[id] < 10)
	{
		return
	}

	g_fPlayerSpeed[id] = get_pcvar_float(g_iCvarTurboSpeed)
	set_entvar(id, var_maxspeed, g_fPlayerSpeed[id])
	g_iTurbo[id] -= 10
	g_bTurboOn[id] = true
	UpdateHud(id)

	set_task(0.9, "TurboOff", id + 2000)
}

public TurboOff(id)
{
	if (task_exists(id))
	{
		remove_task(id)
	}

	id -= 2000

	g_fPlayerSpeed[id] = get_pcvar_float(g_iCvarSpeed)
	set_entvar(id, var_maxspeed, g_fPlayerSpeed[id])
	g_bTurboOn[id] = false
	UpdateHud(id)
}

// Natives
public plugin_natives()
{
	register_native("catch_get_user_team", "_native_get_user_team")
}

public Teams:_native_get_user_team()
{
	return g_iPlayerTeams[get_param(1)]
}

// Restrictions, models and physics
public OnPlayerResetMaxSpeed(id)
{
	if (is_user_alive(id))
	{
		set_entvar(id, var_maxspeed, get_pcvar_float(g_iCvarSpeed))
		set_entvar(id, var_viewmodel, "models/v_shoots.mdl")
	}
}

public OnTakeDamage()
{
	SetHookChainArg(4, ATYPE_FLOAT, 0.0)
}

public OnPlayerSpawn(id)
{
	new iTeam = get_member(id, m_iTeam)

	g_iPlayerTeams[id] = g_iTeams[iTeam]

	if (1 <= iTeam <= 2)
	{
		rg_give_item(id, "weapon_knife")
	}

	set_entvar(id, var_renderfx, kRenderFxGlowShell)

	if (g_iPlayerTeams[id] == FLEER)
	{
		g_iTurbo[id] = get_pcvar_num(g_iCvarTurbo)

		set_entvar(id, var_rendercolor, {0.0, 255.0, 0.0})
	}
	else if (g_iPlayerTeams[id] == CATCHER)
	{
		g_iTurbo[id] = -1

		set_entvar(id, var_rendercolor, {255.0, 0.0, 0.0})
	}
	else
	{
		set_entvar(id, var_rendercolor, {0.0, 0.0, 255.0})
	}

	set_entvar(id, var_renderamt, 25.0)

	g_fPlayerSpeed[id] = get_pcvar_float(g_iCvarSpeed)

	UpdateHud(id)
}

// Stopping some functions
public ReapiSupercedeHandler()
{
	return HC_SUPERCEDE
}

public HamSupercedeHandler()
{
	return HAM_SUPERCEDE
}