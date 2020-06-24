// Defaults
#include <amxmodx>
#include <amxmisc>

// Modules
#include <hamsandwich>
#include <reapi>
#include <fakemeta>
#include <engine>
#include <fun>

// 3rd part
#include <catch_const>
#include <cromchat>

#define CATCH_SET_USER_FRAGS(%1,%2) set_user_frags(%1, %2)
#define CATCH_GET_USER_FRAGS(%1) get_user_frags(%1)

#define CATCH_SET_USER_DEATHS(%1,%2) set_member(%1, m_iDeaths, %2)
#define CATCH_GET_USER_DEATHS(%1) set_member(%1, m_iDeaths)

// Defines
#define SEMICLIP_DISTANCE 260.0

// mi0 UTILS
#define UTIL_KUR print_chat
#include <mi0_utils>

// Cvars
new g_iCvarSpeed, g_iCvarTurbo, g_iCvarTurboSpeed, g_iCvarTouches
new g_pCvarRoundEnd, g_pCvarRoundRestart, g_pCvarForceRespawn
// Vars
new bool:g_bTrainingOn
new bool:g_bNewRound
new Teams:g_iTeams[5]
new g_iLastWinner
new bool:g_bCanKill
// Player Vars
new bool:g_bCantBeSolid[MAXPLAYERSVAR]
new Teams:g_iPlayerTeams[MAXPLAYERSVAR]
new g_iTurbo[MAXPLAYERSVAR]
new bool:g_bTurboOn[MAXPLAYERSVAR]
new g_iTurboDefault[MAXPLAYERSVAR][4]
new bool:g_bTurboInfinity[MAXPLAYERSVAR]
new Float:g_fPlayerSpeed[MAXPLAYERSVAR]
new Float:g_fVel[MAXPLAYERSVAR][3]
new g_iWallTouches[MAXPLAYERSVAR]
new bool:g_bJump[MAXPLAYERSVAR]
new bool:g_bHasSemiclip[MAXPLAYERSVAR]
new bool:g_bSolid[MAXPLAYERSVAR]
new bool:g_bSpeedOn[MAXPLAYERSVAR]
// Forwards
new g_iFwd_RoundEnd
// Hud
enum _:HudEntities
{
	HudStatusEnt,
	HudSpeedEnt
}

enum _:HudSE
{
	TaskEntity,
	HudSync
}

new g_iHud[HudEntities][HudSE]

public plugin_init()
{
	register_plugin("Catch Mod: Main", CATCHMOD_VER, "mi0")

	// Cvars
	g_iCvarSpeed = register_cvar("catch_speed", "640.0")
	g_iCvarTouches = register_cvar("catch_touches", "3")
	g_iCvarTurboSpeed = register_cvar("catch_turbospeed", "840.0")
	g_iCvarTurbo = register_cvar("catch_turbo", "30")

	new iTempPointer
	iTempPointer = get_cvar_pointer("sv_gravity")
	set_pcvar_num(iTempPointer, 600)
	iTempPointer = get_cvar_pointer("sv_airaccelerate")
	set_pcvar_num(iTempPointer, 100)
	g_pCvarRoundEnd = get_cvar_pointer("mp_round_infinite")
	set_pcvar_num(g_pCvarRoundEnd, 0)
	g_pCvarRoundRestart = get_cvar_pointer("sv_restartround")
	g_pCvarForceRespawn = get_cvar_pointer("mp_forcerespawn")
	set_pcvar_num(g_pCvarForceRespawn, 0)

	// Hooks
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "OnPlayerResetMaxSpeed", 1)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamage")
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", 1)
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPre")
	RegisterHookChain(RG_RoundEnd, "OnRoundEnd", 1)
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnNewRound", 1)
	RegisterHookChain(RG_CBasePlayer_Jump, "OnPlayerJump")
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "OnMenuChooseTeam", 1)
	register_touch("player", "worldspawn", "OnPlayerTouchWorld")
	register_touch("player", "func_breakable", "OnPlayerTouchWorld")
	register_touch("player", "player", "OnPlayerTouchPlayer")
	RegisterHam(Ham_Player_PreThink, "player", "OnPlayerThink")
	RegisterHam(Ham_Player_PostThink, "player", "OnPlayerThinkPost")
	register_forward(FM_AddToFullPack, "FM__AddToFullPack", 1)
	register_forward(FM_AddToFullPack, "FM__AddToFullPack_Pre")
	register_message(get_user_msgid("TextMsg"), "TextMsgHook")
	// register_message(get_user_msgid("ScoreInfo"), "ScoreInfoChanged")
	register_message(get_user_msgid("RoundTime"), "TimerMessageHook")
	register_logevent("OnFirstRound", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("OnFirstRound", 2, "0=World triggered", "1=Game_Commencing")

	// Hud
	for (new i; i < sizeof(g_iHud); i++)
	{
		g_iHud[_:i][HudSync] = CreateHudSyncObj()
		g_iHud[_:i][TaskEntity] = rg_create_entity("info_target")
		set_entvar(g_iHud[_:i][TaskEntity], var_classname, "HudTaskEntity")
		set_entvar(g_iHud[_:i][TaskEntity], var_nextthink, get_gametime() + 1.0)
	}
	SetThink(g_iHud[HudStatusEnt][TaskEntity], "StatusEntityThink")
	SetThink(g_iHud[HudSpeedEnt][TaskEntity], "SpeedEntityThink")

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
	RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "OnItemHasRestrict")

	// Forwards
	g_iFwd_RoundEnd = CreateMultiForward("catchmod_round_end", ET_IGNORE, FP_CELL)

	// Cmds
	register_clcmd("say /speed", "cmd_speed")
	register_concmd("amx_train", "cmd_train", ADMIN_MAP)
	register_clcmd("say /train", "cmd_personaltraining")

	CC_SetPrefix("^4Catch Mod >>")
}

public plugin_end()
{
	DestroyForward(g_iFwd_RoundEnd)
}
	
// Cmds
public cmd_speed(id)
{
	g_bSpeedOn[id] = !g_bSpeedOn[id]
	CC_SendMatched(id, id, "You successfuly turned your speed ^3%s^1!", g_bSpeedOn[id] ? "On" : "Off")

	return PLUGIN_HANDLED
}

public cmd_train(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}

	g_bTrainingOn = !g_bTrainingOn

	new szName[32]
	get_user_name(id, szName, charsmax(szName))

	if (g_bTrainingOn)
	{
		set_pcvar_num(g_pCvarForceRespawn, 1)
		set_pcvar_string(g_pCvarRoundEnd, "a")
		CC_SendMatched(0, id, "^3%s ^1pusna ^3Training ^1Mode-a!", szName)
	}
	else
	{
		set_pcvar_num(g_pCvarForceRespawn, 0)
		set_pcvar_num(g_pCvarRoundEnd, 0)
		CC_SendMatched(0, id, "^3%s ^1sprq ^3Training ^1Mode-a!", szName)
	}

	set_pcvar_num(g_pCvarRoundRestart, 1)

	return PLUGIN_HANDLED
}

public cmd_personaltraining(id)
{
	new iTeam = get_member(id, m_iTeam)
	if (is_user_alive(id) && iTeam == 3)
	{
		CC_SendMatched(id, id, "You are already in training mode!")
		CC_SendMatched(id, id, "To turn it off just change your team!")
		return PLUGIN_HANDLED
	}

	if (iTeam != 3)
	{
		rg_set_user_team(id, TEAM_SPECTATOR)
	}

	if (!is_user_alive(id))
	{
		rg_round_respawn(id)
	}
	else
	{
		set_user_footsteps(id, 1)
	}

	g_iPlayerTeams[id] = TRAINING
	g_iTurbo[id] = 100
	g_bTurboInfinity[id] = true
	UpdateHud(id)

	return PLUGIN_HANDLED
}

// Teams
public plugin_cfg()
{
	g_iTeams[1] = FLEER
	g_iTeams[2] = CATCHER
	g_iTeams[3] = TRAINING
}

// Model
public plugin_precache()
{
	precache_model("models/v_shoots.mdl")
}

// Reset Vars, Update Stats
public client_connect(id)
{
	g_iTurboDefault[id][0] = get_pcvar_num(g_iCvarTurbo)
	g_iTurboDefault[id][1] = -1
	g_iTurboDefault[id][2] = 100
	g_bTurboInfinity[id] = false
	g_bSpeedOn[id] = true
}

public client_putinserver(id)
{
	SetDefaultCatchSettings(id)
}

SetDefaultCatchSettings(id)
{
	client_cmd_ex(id, "cl_forwardspeed 9999")
	client_cmd_ex(id, "cl_sidespeed 9999")
	client_cmd_ex(id, "cl_backspeed 9999")
	client_cmd_ex(id, "fps_max 100")
	client_cmd_ex(id, "fps_override 0")
}

// Think
public OnPlayerThink(id)
{
	// Turbo
	new iButtons = get_entvar(id, var_button)
	new iOldButtons = get_entvar(id, var_oldbuttons)

	if (iButtons & IN_ATTACK2 && !task_exists(id + 2000))
	{
		TurboOn(id)
	}
	else if (~iButtons & IN_ATTACK2 && iOldButtons & IN_ATTACK2)
	{
		TurboOff(id + 2000)
	}

	// Wall Touch
	if (get_entvar(id, var_flags) & FL_ONGROUND && g_iWallTouches[id] != get_pcvar_num(g_iCvarTouches))
	{
		g_iWallTouches[id] = get_pcvar_num(g_iCvarTouches)
	}

	if (g_bJump[id])
	{
		g_fVel[id][0] = 0.0 - g_fVel[id][0]
		set_entvar(id, var_velocity, g_fVel[id])
		set_entvar(id, var_gaitsequence, 6)
		set_entvar(id, var_frame, 0.0)

		g_iWallTouches[id]++
		g_bJump[id] = false
	}

	SemiClipPreThink(id)
}

public OnPlayerThinkPost()
{
	SemiClipPostThink()
}

// Jump
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

// Touch Wall
public OnPlayerTouchWorld(iPlayer)
{
	// Wall Touch

	if (g_iWallTouches[iPlayer] >= get_pcvar_num(g_iCvarTouches) || ~get_entvar(iPlayer, var_button) & IN_JUMP || get_entvar(iPlayer, var_flags) & FL_ONGROUND)
	{
		return // if he cant wall jump return
	}

	g_bJump[iPlayer] = true // setting true, so the next frame he'll wall jump
}

// Touch Player
public OnPlayerTouchPlayer(iToucher, iTouched)
{
	// Kill

	if (!is_user_alive(iTouched) || !is_user_alive(iToucher) || g_bTrainingOn || !g_bCanKill || get_member(iToucher, m_iTeam) == get_member(iTouched, m_iTeam))
	{
		return PLUGIN_CONTINUE// if they cant kill each other
	}
	
	// Who's the killer
	new iKiller, iVictim
	if (g_iPlayerTeams[iToucher] == CATCHER && g_iPlayerTeams[iTouched] == FLEER)
	{
		iKiller = iToucher
		iVictim = iTouched
	}
	else if (g_iPlayerTeams[iToucher] == FLEER && g_iPlayerTeams[iTouched] == CATCHER)
	{
		iKiller = iTouched
		iVictim = iToucher
	}

	if (!iKiller)
	{
		return PLUGIN_HANDLED
	}

	Func_Kill(iKiller, iVictim, get_entvar(iKiller, var_groundentity) == iVictim)

	return PLUGIN_HANDLED
}

Func_Kill(iKiller, iVictim, bool:bHeadShot)
{
	set_member(iVictim, m_bHeadshotKilled, bHeadShot)
	ExecuteHamB(Ham_Killed, iVictim, iKiller, 0)
	if (bHeadShot)
	{
		new szKillerName[32], szVictimName[32]
		get_user_name(iKiller, szKillerName, charsmax(szKillerName))
		get_user_name(iVictim, szVictimName, charsmax(szVictimName))
		set_dhudmessage(random(255), random(255), random(255))
		show_dhudmessage(0, "Opss... %s just fell on %s. Ez HeadShot", szKillerName, szVictimName)
	}
}

// Eound end & game commencing
public TextMsgHook(iMsgID, iMsgDest, id)
{
	static szMsg[32]
	get_msg_arg_string(2, szMsg, charsmax(szMsg)) // getting the msg

	if (equal(szMsg, "#Game_Commencing")) // if the game is commencing
	{
		UpdateHud(id) // updating hud
	}

	return PLUGIN_HANDLED
}

public OnFirstRound()
{
	if (g_bTrainingOn) // if training on
	{
		g_iTeams[1] = TRAINING
		g_iTeams[2] = TRAINING
		return PLUGIN_CONTINUE // return
	}

	// setting the default teams
	g_iTeams[1] = FLEER
	g_iTeams[2] = CATCHER

	g_bNewRound = true

	return PLUGIN_CONTINUE // return
}

// Round End
public OnRoundEnd()
{
	if (g_bNewRound)
	{
		g_bNewRound = false
		goto ReturnStmt
	}
	if (g_bTrainingOn) // if is train
	{
		ReturnStmt:
		SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_DRAW) // Setting draw so no one of the teams wins
		return // return cuz when its training no one wins
	}

	new iPlayers[32], iPlayersNum
	new iTemp = _:(g_iTeams[1] == CATCHER) + 1
	get_players_ex(iPlayers, iPlayersNum, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, g_iTeams[1] == FLEER ? "TERRORIST" : "CT")

	new iIgnored
	if (iPlayersNum)
	{
		g_iLastWinner = iTemp

		new iTarget
		for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
		{
			iTarget = iPlayers[iPlayersNum]
			CATCH_SET_USER_FRAGS(iTarget, CATCH_GET_USER_FRAGS(iTarget) + 3)
		}

		client_print(0, print_center, "Fleers won the round!")
	}
	else
	{
		g_iLastWinner = abs(iTemp - 3)
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

	ExecuteForward(g_iFwd_RoundEnd, iIgnored, g_iLastWinner)

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
	g_bNewRound = false
}

//Hud
public StatusEntityThink()
{
	new iPlayers[32], iPlayersNum
	get_players_ex(iPlayers, iPlayersNum)

	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		UpdateHud(iPlayers[iPlayersNum])
	}

	set_entvar(g_iHud[HudStatusEnt][TaskEntity], var_nextthink, get_gametime() + 5.0)
}

UpdateHud(id)
{
	if (!is_user_alive(id))
	{
		return
	}

	new szTemp[192]
	formatex(szTemp, charsmax(szTemp), "Status : %s", g_szTeamsNames[g_iPlayerTeams[id]])

	if (g_iTurbo[id] >= 10)
	{
		format(szTemp, charsmax(szTemp), "%s^n%sTurbo: [======|======] %i%", szTemp, g_bTurboOn[id] ? "+" : "-", g_iTurbo[id])
	}
	else if (g_iTurbo[id] < 10 && g_iTurbo[id] >= 0)
	{
		format(szTemp, charsmax(szTemp), "%s^nTurbo: stiga s tva turbo bi4e", szTemp)
	}
	else
	{
		format(szTemp, charsmax(szTemp), "%s^nTurbo: Off", szTemp)
	}

	set_hudmessage(255, 255, 255, 0.02, 0.24, 0, 0.0, 5.0, 0.2, 0.0)
	ShowSyncHudMsg(id, g_iHud[HudStatusEnt][HudSync], szTemp)
}

// Turbo
TurboOn(id)
{
	if (g_iTurbo[id] < 10 && !g_bTurboInfinity[id])
	{
		return
	}

	g_fPlayerSpeed[id] = get_pcvar_float(g_iCvarTurboSpeed)
	set_entvar(id, var_maxspeed, g_fPlayerSpeed[id])
	g_iTurbo[id] = (g_iTurbo[id] <= 10 && g_bTurboInfinity[id]) ? 100 : g_iTurbo[id] - 10
	g_bTurboOn[id] = true
	UpdateHud(id)

	set_task(1.0, "TurboOff", id + 2000)
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

// SemiClip

SemiClipFirstThink()
{
	new iPlayers[MAX_PLAYERS], iNum, id
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		id = iPlayers[iNum]
		g_bSolid[id] = pev(id, pev_solid) == SOLID_SLIDEBOX ? true : false
	}
}

SemiClipPreThink(id)
{
	static iLastThink
	
	if (iLastThink > id)
	{
		SemiClipFirstThink()
	}
	
	iLastThink = id

	if (!g_bSolid[id])
	{
		return
	}
	
	new iTarget
	new iPlayers[MAX_PLAYERS], iNum
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		iTarget = iPlayers[iNum]

		if (!g_bSolid[iTarget] || id == iTarget)
		{
			continue
		}

		if (g_iPlayerTeams[iTarget] == g_iPlayerTeams[id] || g_iPlayerTeams[iTarget] == TRAINING || g_iPlayerTeams[id] == TRAINING || g_bCantBeSolid[id] || g_bCantBeSolid[iTarget])
		{
			set_pev(iTarget, pev_solid, SOLID_NOT)
			g_bHasSemiclip[iTarget] = true
		}
	}
}

SemiClipPostThink()
{
	new iPlayers[MAX_PLAYERS], iNum, iPlayer
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		iPlayer = iPlayers[iNum]

		if (g_bHasSemiclip[iPlayer])
		{
			set_pev(iPlayer, pev_solid, SOLID_SLIDEBOX)
			g_bHasSemiclip[iPlayer] = false
		}
	}
}

public FM__AddToFullPack(iEs, e, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (iPlayer && is_user_alive(iHost))
	{
		new Float:flDistance = entity_range(iHost, iEnt)
		
		if (g_bSolid[iHost] && g_bSolid[iEnt] && (g_iPlayerTeams[iHost] == g_iPlayerTeams[iEnt] || g_iPlayerTeams[iHost] == TRAINING || g_iPlayerTeams[iEnt] == TRAINING || g_bCantBeSolid[iEnt] || g_bCantBeSolid[iHost]) && flDistance < SEMICLIP_DISTANCE && is_user_alive(iHost))
		{
			set_es(iEs, ES_Solid, SOLID_NOT)
			set_es(iEs, ES_RenderMode, kRenderTransAlpha)
			set_es(iEs, ES_RenderAmt, floatround(flDistance))
		}
		
		if (g_iPlayerTeams[iEnt] == TRAINING && g_iPlayerTeams[iHost] != TRAINING)
		{
			set_es(iEs, ES_Effects, EF_NODRAW)
		}
	}
	
	return FMRES_IGNORED
}

/*
public FM__AddToFullPack_Pre(iEs, e, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (iPlayer && is_user_alive(iHost) && g_iPlayerTeams[iHost] == CATCHER && g_iTeam[iEnt] == FLEER)
	{
		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}
*/

// Speedometer
public SpeedEntityThink()
{
	new iPlayers[32], iPlayersNum, iTarget, iPlayer
	new Float:fVelocity[3]
	new Float:fSpeed, Float:f2dmSpeed
	get_players(iPlayers, iPlayersNum)
	
	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		iPlayer = iPlayers[iPlayersNum]
		if (!g_bSpeedOn[iPlayer])
		{
			continue
		}
		
		iTarget = get_entvar(iPlayer, var_iuser1) == 4 ? get_entvar(iPlayer, var_iuser2) : iPlayer
		get_entvar(iTarget, var_velocity, fVelocity)

		fSpeed = vector_length(fVelocity)
		f2dmSpeed = floatsqroot(fVelocity[0] * fVelocity[0] + fVelocity[1] * fVelocity[1])
		
		set_hudmessage(255, 0, 0, -1.0, 0.7, 0, 0.0, 0.2, 0.01, 0.0)
		ShowSyncHudMsg(iPlayer, g_iHud[HudSpeedEnt][HudSync], "%3.2f units/second^n%3.2f velocity", fSpeed, f2dmSpeed)
	}

	set_entvar(g_iHud[HudSpeedEnt][TaskEntity], var_nextthink, get_gametime() + 0.1)
}

// Restrictions, models and physics
public OnMenuChooseTeam(id, MenuChooseTeam:iSlot)
{
	new iTeam = get_member(id, m_iTeam)
	g_iPlayerTeams[id] = g_iTeams[iTeam]
}

public OnPlayerResetMaxSpeed(id)
{
	if (is_user_alive(id))
	{
		set_entvar(id, var_maxspeed, get_pcvar_float(g_iCvarSpeed))
		set_entvar(id, var_viewmodel, "models/v_shoots.mdl")
	}
}

public OnPlayerTakeDamage()
{
	SetHookChainArg(4, ATYPE_FLOAT, 0.0)
}

public OnPlayerSpawnPre(id)
{
	g_iPlayerTeams[id] = g_iTeams[get_member(id, m_iTeam)]
}

public OnPlayerSpawn(id)
{
	new iTeam = get_member(id, m_iTeam)

	if (1 <= iTeam <= 3)
	{
		rg_give_item(id, "weapon_knife")
	}

	g_iTurbo[id] = g_iTurboDefault[id][_:g_iPlayerTeams[id]]
	g_bTurboInfinity[id] = g_iPlayerTeams[id] == TRAINING
	g_fPlayerSpeed[id] = get_pcvar_float(g_iCvarSpeed)
	set_entvar(g_iHud[HudStatusEnt][TaskEntity], var_nextthink, get_gametime() + 0.5)

	if (get_user_team(id) == 3)
	{
		set_user_footsteps(id, 0)
	}
}

public TimerMessageHook()
{
	if (g_bTrainingOn)
	{
		set_msg_arg_int(1, ARG_SHORT, get_timeleft())
	}
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

public OnItemHasRestrict(const id, const ItemID:item, const ItemRestType:type)
{
	if (type != ITEM_TYPE_BUYING)
	{
		return HC_CONTINUE
	}

	UTIL_Kur(id)
	SetHookChainReturn(ATYPE_BOOL, true)
	return HC_SUPERCEDE
}

// Stocks
stock client_cmd_ex(id, const szText[], any:...)
{
	#pragma unused szText
	
	if (id == 0 || is_user_connected(id))
	{
		new szMessage[256]
		
		format_args(szMessage, charsmax(szMessage), 1)
		
		message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
		write_byte(strlen(szMessage) + 2)
		write_byte(10)
		write_string(szMessage)
		message_end()
	}
}

// Natives
public plugin_natives()
{
	register_native("catchmod_get_cantbesolid", "_native_get_cantbesolid")
	register_native("catchmod_set_cantbesolid", "_native_set_cantbesolid")

	register_native("catchmod_get_fleers", "_native_get_fleers")
	register_native("catchmod_get_catchers", "_native_get_catchers")

	register_native("catchmod_get_user_team", "_native_get_user_team")
	register_native("catchmod_set_user_team", "_native_set_user_team")

	register_native("catchmod_get_user_turbo", "_native_get_user_turbo")
	register_native("catchmod_set_user_turbo", "_native_set_user_turbo")

	register_native("catchmod_get_user_defaultturbo", "_native_get_user_defaultturbo")
	register_native("catchmod_set_user_defaultturbo", "_native_set_user_defaultturbo")

	register_native("catchmod_get_user_infiniteturbo", "_native_get_user_infiniteturbo")
	register_native("catchmod_set_user_infiniteturbo", "_native_set_user_infiniteturbo")
}

public bool:_native_get_cantbesolid()
{
	new id = get_param(1)
	if (!is_user_connected(id))
	{
		return false
	}

	return g_bCantBeSolid[id]
}

public _native_set_cantbesolid()
{
	new id = get_param(1)
	if (!is_user_connected(id))
	{
		return -1
	}

	new bool:solid = bool:get_param(2)
	g_bCantBeSolid[id] = solid
	return 0
}

public _native_get_fleers()
{
	if (g_iTeams[1] == FLEER)
	{
		return 1
	}
	else if (g_iTeams[2] == FLEER)
	{
		return 2
	}
	else
	{
		return -1
	}
}

public _native_get_catchers()
{
	if (g_iTeams[1] == CATCHER)
	{
		return 1
	}
	else if (g_iTeams[2] == CATCHER)
	{
		return 2
	}
	else
	{
		return -1
	}
}

public Teams:_native_get_user_team()
{
	return g_iPlayerTeams[get_param(1)]
}

public _native_set_user_team()
{
	g_iPlayerTeams[get_param(1)] = Teams:get_param(2)
}

public _native_get_user_turbo()
{
	return g_iTurbo[get_param(1)]
}

public _native_set_user_turbo()
{
	g_iTurbo[get_param(1)] = get_param(2)
}

public _native_get_user_defaultturbo()
{
	return g_iTurboDefault[get_param(1)][get_param(2)]
}

public _native_set_user_defaultturbo()
{
	g_iTurboDefault[get_param(1)][get_param(2)] = get_param(3)
}

public bool:_native_get_user_infiniteturbo()
{
	return g_bTurboInfinity[get_param(1)]
}

public _native_set_user_infiniteturbo()
{
	g_bTurboInfinity[get_param(1)] = bool:get_param(2)
}

// DEBUG_SCORE(id, szUniqueID[64])
// {
// 	new szName[32]
// 	get_user_name(id, szName, charsmax(szName))
// 	client_print(id, print_chat, "szUniqueID => %s", szUniqueID)
// 	client_print(id, print_chat, "szName => %s", szName)
// 	client_print(id, print_chat, "fKills => %.f", get_entvar(id, var_frags))
// 	client_print(id, print_chat, "iDeaths => %i", get_member(id, m_iDeaths))
// }