#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <catchmod>
#include <cromchat>

#define PLUGIN "CatchMod: WarSystem"
#define AUTHOR "mi0"

#define ADMIN_ACCESS "o"

#define MAX_GAMES 16

enum WarTeams
{
	Team1,
	Team2,
	Spectator
}

enum _:TeamInfo
{
	Players[MAX_PLAYERS],
	PlayersNum,
	TeamName:Team,
	TakenRounds[MAX_GAMES],
	TakenGames,
	Name[32]
}

new g_eTeamInfo[2][TeamInfo]
new bool:g_bWarOn
new bool:g_bScoreCounting
new g_iCurrentGame
new g_szScore[480]
new g_iGamesWinner[MAX_GAMES]
new WarTeams:g_iPlayersTeams[MAXPLAYERSVAR] = { Spectator, ... }
new WarTeams:g_iSelectedTeam[MAXPLAYERSVAR]
new g_iDefaultTurbo = 10
new g_szPlayersNames[MAXPLAYERSVAR][32]
new g_pCvar_RoundRestart
new g_iMsg_Status

public plugin_init()
{
	register_plugin(PLUGIN, CATCHMOD_VER, AUTHOR)

	new iFlag = read_flags(ADMIN_ACCESS)
	register_clcmd("amx_pvp", "CMD_ChooseTeams", iFlag)
	register_clcmd("amx_war", "CMD_WarMenu", iFlag)

	register_clcmd("chooseteam", "OnTeamChange")
	register_clcmd("jointeam",   "OnTeamChange")
	register_clcmd("joinclass",  "OnTeamChange")

	RegisterHookChain(RG_HandleMenu_ChooseTeam, "OnChooseTeam")
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRoundRestrat", 1)
	register_event("ResetHUD", "OnHudReset", "b")

	g_pCvar_RoundRestart = get_cvar_pointer("sv_restart")
	g_iMsg_Status = get_user_msgid("StatusText")

	register_message(g_iMsg_Status, "OnStatusMsg")

	CC_SetPrefix("^4[War System]")
}

public client_connect(id)
{
	get_user_name(id, g_szPlayersNames[id], charsmax(g_szPlayersNames[]))
}

public client_infochanged(id)
{
	get_user_info(id, "name", g_szPlayersNames[id], charsmax(g_szPlayersNames[]))
}

public OnTeamChange(id)
{
	if (g_bWarOn)
	{
		new szArg[8]
		read_argv(1, szArg, charsmax(szArg))
		if (szArg[0] - 48 != 6)
		{
			client_print(id, print_chat, "You CANNOT change your team during war!")
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public CMD_ChooseTeams(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}

	ChooseTeamMenu_Open(id)

	return PLUGIN_HANDLED
}

ChooseTeamMenu_Open(id)
{
	new iMenu = menu_create("\rWar System: \yPvP Menu", "ChooseTeamMenu_Handler")

	new iPlayers[MAX_PLAYERS], iPlayersNum
	get_players(iPlayers, iPlayersNum)
	new iTarget, szLine[48], szIndex[4]
	for (new i; i < iPlayersNum; i++)
	{
		if (i % 6 == 0)
        {
			new szTeam[32]
			Func_GetTeamName(g_iSelectedTeam[id], szTeam, true)
			formatex(szLine, charsmax(szLine), "Transfer to %s", szTeam)
			menu_additem(iMenu, szLine, "team")
        }

		iTarget = iPlayers[i]
		switch (g_iPlayersTeams[iTarget])
		{
			case Team1:
				formatex(szLine, charsmax(szLine), "\r &name& [TT]")
			case Team2:
				formatex(szLine, charsmax(szLine), "\y &name& [CT]")
			case Spectator:
				formatex(szLine, charsmax(szLine), "\d &name& [SPEC]")
		}
		replace(szLine, charsmax(szLine), "&name&", g_szPlayersNames[iTarget])
		num_to_str(iTarget, szIndex, charsmax(szIndex))
		menu_additem(iMenu, szLine, szIndex)
	}

	menu_display(id, iMenu)
}

public ChooseTeamMenu_Handler(id, iMenu, iItem)
{
    if (iItem == MENU_EXIT)
    {
        menu_destroy(iMenu)
        return
    }

    new szInfo[8], iTemp
    menu_item_getinfo(iMenu, iItem, iTemp, szInfo, charsmax(szInfo), _, _, iTemp)

    if (equal(szInfo, "team"))
    {
    	if (++g_iSelectedTeam[id] > Spectator)
    	{
    		g_iSelectedTeam[id] = Team1
    	}
        goto EndOfTeamMenuHandler
    }

    new iPlayer = str_to_num(szInfo)
    g_iPlayersTeams[iPlayer] = g_iSelectedTeam[id]

    EndOfTeamMenuHandler:
    menu_destroy(iMenu)
    ChooseTeamMenu_Open(id)
}

public CMD_WarMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}

	WarMenu_Open(id)

	return PLUGIN_HANDLED
}

WarMenu_Open(id)
{
	new iMenu = menu_create("\rWar System: \yWar Menu", "WarMenu_Handler")

	new szLine[32]
	formatex(szLine, charsmax(szLine), "War %s", g_bWarOn ? "\y[ON]" : "\d[OFF]")
	menu_additem(iMenu, szLine)

	formatex(szLine, charsmax(szLine), "Restart Game")
	menu_additem(iMenu, szLine)

	formatex(szLine, charsmax(szLine), "Restart Match")
	menu_additem(iMenu, szLine)

	formatex(szLine, charsmax(szLine), "Swap Teams")
	menu_additem(iMenu, szLine)

	formatex(szLine, charsmax(szLine), "Turbo: \r%i%", g_iDefaultTurbo)
	menu_additem(iMenu, szLine)

	menu_display(id, iMenu)
}

public WarMenu_Handler(id, iMenu, iItem)
{
    if (iItem == MENU_EXIT)
    {
        menu_destroy(iMenu)
        return
    }

    switch (iItem)
    {
    	case 0:
    	Func_WarState()
    	case 1:
    	Func_RestartWar(id, true)
    	case 2:
    	Func_RestartWar(id)
    	case 3:
    	Func_SwapTeams(id)
    	case 4:
    	{
	    	if ((g_iDefaultTurbo += 10) > 100)
	    	{
	    		g_iDefaultTurbo = 0
	    	}
	    	Func_Turbo()
	    }
    }

    menu_destroy(iMenu)
    WarMenu_Open(id)
}

public catchmod_round_end(iTeam)
{
	if (!g_bWarOn || !g_bScoreCounting)
	{
		return
	}

	for (new i; i < 2; i++)
	{
		if (_:g_eTeamInfo[i][Team] == iTeam)
		{
			g_eTeamInfo[i][TakenRounds][g_iCurrentGame]++
			break
		}
	}

	Func_CheckScore()
	Func_DisplayScore()
}

public OnChooseTeam(id, MenuChooseTeam:iTeam)
{
	if (g_bWarOn)
	{
		SetHookChainArg(2, ATYPE_INTEGER, _:MenuChoose_Spec)
	}
}

public OnRoundRestrat()
{
	if (!g_bWarOn)
	{
		return
	}

	if (!g_bScoreCounting)
	{
		g_bScoreCounting = true
	}
}

public OnHudReset(id)
{
	if (g_bWarOn)
	{
		set_task(1.0, "Func_ShowScore", id)
	}
}

public OnStatusMsg()
{
	if (g_bWarOn)
	{
		set_msg_arg_string(2, g_szScore)
	}
}

Func_WarState()
{
	g_bWarOn = !g_bWarOn
	g_bScoreCounting = false

	if (g_bWarOn)
	{
		Func_ClearWar()
		Func_PlaceInTeams()
		new iTeam = Func_CheckPlayersCount()
		if (iTeam)
		{
			CC_SendMatched(0, 0, "Nqma kak da byde ^4pusnat ^3War^1! ^3Team%i ^4nqma ^1dostatychno ^4hora^1!", iTeam + 1)
			return
		}
		Func_Turbo()
		Func_FormatTeamName()
		Func_RestartRound()
		Func_DisplayScore()
	}
	else
	{
		Func_Turbo()
	}
}

Func_Turbo()
{
	new iPlayers[32], iPlayersNum
	get_players(iPlayers, iPlayersNum)
	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{	
		catchmod_set_user_defaultturbo(iPlayers[iPlayersNum], 0, g_bWarOn ? g_iDefaultTurbo : 30)
	}
}

Func_ClearWar()
{
	g_iCurrentGame = 0
	g_eTeamInfo[0][Team] = TEAM_TERRORIST
	g_eTeamInfo[1][Team] = TEAM_CT

	for (new i; i < MAX_GAMES; i++)
	{
		g_iGamesWinner[i] = 0
	}

	for (new i; i < 2; i++)
	{
		g_eTeamInfo[i][PlayersNum] = 0

		for (new j; j < MAX_GAMES; j++)
		{
			g_eTeamInfo[i][TakenRounds][j] = 0
		}

		g_eTeamInfo[i][TakenGames] = 0
	}
}

Func_CheckScore()
{
	new iWinner = -1
	// 3 - 0 4 - 1 5 - 3 6 - 4 (7 - 6 ako si first fleer)
	if (g_eTeamInfo[0][TakenRounds][g_iCurrentGame] < 5 && g_eTeamInfo[1][TakenRounds][g_iCurrentGame] < 5)
	{
		if (abs(g_eTeamInfo[0][TakenRounds][g_iCurrentGame] - g_eTeamInfo[1][TakenRounds][g_iCurrentGame]) >= 3)
		{
			iWinner = g_eTeamInfo[0][TakenRounds][g_iCurrentGame] > g_eTeamInfo[1][TakenRounds][g_iCurrentGame] ? 0 : 1
		}
	}
	else if (g_eTeamInfo[0][TakenRounds][g_iCurrentGame] < 7 && g_eTeamInfo[1][TakenRounds][g_iCurrentGame] < 7 
		&& abs(g_eTeamInfo[0][TakenRounds][g_iCurrentGame] - g_eTeamInfo[1][TakenRounds][g_iCurrentGame]) >= 2)
	{
		iWinner = g_eTeamInfo[0][TakenRounds][g_iCurrentGame] > g_eTeamInfo[1][TakenRounds][g_iCurrentGame] ? 0 : 1
	}
	else
	{
		new iTeam = _:(g_eTeamInfo[0][Team] == TEAM_CT)
		if (g_eTeamInfo[iTeam][TakenRounds][g_iCurrentGame] == 7 && g_eTeamInfo[1 - iTeam][TakenRounds][g_iCurrentGame] == 6)
		{
			iWinner = iTeam
		}
		else if (g_eTeamInfo[1 - iTeam][TakenRounds][g_iCurrentGame] == 7)
		{
			iWinner = 3
		}
	}

	if (iWinner != -1)
	{
		g_iGamesWinner[g_iCurrentGame] = iWinner
		g_iCurrentGame++
		if (iWinner != 3)
		{
			CC_SendMessage(0, "^4[ ==== ^3%s ^4Won The Game ==== ]", g_eTeamInfo[iWinner][Name])
			g_eTeamInfo[iWinner][TakenGames]++
			Func_CheckWinner(iWinner)
		}
		else
		{
			CC_SendMessage(0, "^4[ ==== Game Is Draw ==== ]")
		}

		Func_SwapTeams()
	}
}

Func_CheckWinner(iWinner)
{
	if (g_eTeamInfo[iWinner][TakenGames] >= 2)
	{
		CC_SendMessage(0, "^4[ ==== ^3%s ^4Won The Match ==== ]", g_eTeamInfo[iWinner][Name])
		g_bWarOn = false
	}
	else if (g_iCurrentGame - (g_eTeamInfo[0][TakenGames] + g_eTeamInfo[1][TakenGames]) >= 2)
	{
		CC_SendMessage(0, "^4[ ==== Match Is Draw ==== ]")
		g_bWarOn = false
	}
	else
	{
		Func_RestartWar(0, true)
	}
}

Func_RestartRound()
{
	g_bScoreCounting = false
	set_pcvar_num(g_pCvar_RoundRestart, 1)
}

Func_RestartWar(id = 0, bGameOnly = false)
{
	if (!g_bWarOn)
	{
		CC_SendMatched(id, id, "No valid ^3War^1!", g_szPlayersNames[id], g_bWarOn ? "Pusna" : "Sprq")
		return
	}

	if (bGameOnly)
	{
		for (new i; i < 2; i++)
		{
			g_eTeamInfo[i][TakenRounds][g_iCurrentGame] = 0
		}
		Func_RestartRound()
	}
	else
	{
		Func_ClearWar()
		Func_RestartRound()
	}


	if (id)
	{
		CC_SendMatched(0, id, "^3%s ^4restarted the ^3%s^1!", g_szPlayersNames[id], bGameOnly ? "Game" : "Match")
	}

	Func_DisplayScore(true)
}

Func_SwapTeams(id = 0)
{
	if (!g_bWarOn && id)
	{
		CC_SendMatched(id, id, "No valid ^3War^1!", g_szPlayersNames[id], g_bWarOn ? "Pusna" : "Sprq")
		return
	}

	for (new i; i < 2; i++)
	{
		g_eTeamInfo[i][Team] = TeamName:abs(_:g_eTeamInfo[i][Team] - 3)
	}

	Func_MovePlayersToTeams()

	if (id)
	{
		CC_SendMatched(0, id, "^3%s ^4swapped the ^3teams^1!", g_szPlayersNames[id])
	}
}

Func_PlaceInTeams()
{
	new iPlayers[MAX_PLAYERS], iPlayersNum
	new iTarget
	get_players(iPlayers, iPlayersNum)
	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		iTarget = iPlayers[iPlayersNum]
		rg_set_user_team(iTarget, _:g_iPlayersTeams[iTarget] + 1)
		if (g_iPlayersTeams[iTarget] != Spectator)
		{
			g_eTeamInfo[_:g_iPlayersTeams[iTarget]][Players][g_eTeamInfo[_:g_iPlayersTeams[iTarget]][PlayersNum]++] = iTarget
			rg_round_respawn(iTarget)
		}
		else if (is_user_alive(iTarget))
		{
			set_entvar(iTarget, var_deadflag, DEAD_DEAD)
		}
	}
}

Func_MovePlayersToTeams()
{
	new iPlayers[MAX_PLAYERS], iPlayersNum
	new iTarget
	get_players(iPlayers, iPlayersNum)
	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		iTarget = iPlayers[iPlayersNum]
		if (g_iPlayersTeams[iTarget] != Spectator)
		{
			rg_set_user_team(iTarget, g_eTeamInfo[_:g_iPlayersTeams[iTarget]][Team])
			// rg_round_respawn(iTarget)
		}
	}
}

Func_DisplayScore(bGame = false)
{
	if (!g_bWarOn)
	{
		return
	}

	// CC_SendMessage(0, "^4Current Game ^3[%i] ^4[ == ^3%s [%i] ^4vs ^3%s [%i] ^4== ]", g_iCurrentGame + 1, 
	// 		g_eTeamInfo[0][Name], g_eTeamInfo[0][TakenRounds][g_iCurrentGame], g_eTeamInfo[1][Name], g_eTeamInfo[1][TakenRounds][g_iCurrentGame])
	if (bGame)
	{
		CC_SendMessage(0, "^4Score: Games || ^3%s [%i] ^4vs ^3%s [%i] ^4|| Draws ^3[%i]", 
			g_eTeamInfo[0][Name], g_eTeamInfo[0][TakenGames], g_eTeamInfo[1][Name], g_eTeamInfo[1][TakenGames],
			g_iCurrentGame - (g_eTeamInfo[0][TakenGames] + g_eTeamInfo[1][TakenGames]))
	}
	else
	{
		CC_SendMessage(0, "^4Current Game ^3[%i] ^4[ == ^3%s [%i] ^4vs ^3%s [%i] ^4== ]", g_iCurrentGame + 1, 
			g_eTeamInfo[0][Name], g_eTeamInfo[0][TakenRounds][g_iCurrentGame], g_eTeamInfo[1][Name], g_eTeamInfo[1][TakenRounds][g_iCurrentGame])
	}

	Func_ShowHudScore()
}

Func_CheckPlayersCount()
{
	for (new i; i <= 1; i++)
	{
		if (!g_eTeamInfo[i][PlayersNum])
		{
			return i + 1
		}
	}

	return 0
}

Func_FormatTeamName()
{
	new bMatch = true, iCount
	for (new i; i <= 1; i++)
	{
		iCount = 0
		if (g_eTeamInfo[i][PlayersNum] == 1)
		{
			copy(g_eTeamInfo[i][Name], charsmax(g_eTeamInfo[][Name]), g_szPlayersNames[g_eTeamInfo[i][Players][0]])
			continue
		}

		StartOfLoop:
		for (new j = 1; j < g_eTeamInfo[i][PlayersNum]; j++)
		{
			if (g_szPlayersNames[g_eTeamInfo[i][Players][j]][iCount] != g_szPlayersNames[g_eTeamInfo[i][Players][j - 1]][iCount])
			{
				bMatch = false
			}
		}

		if (bMatch)
		{
			g_eTeamInfo[i][Name][iCount] = g_szPlayersNames[g_eTeamInfo[i][Players][0]][iCount]
			iCount++
			goto StartOfLoop
		}

		if (iCount < 2)
		{
			formatex(g_eTeamInfo[i][Name], charsmax(g_eTeamInfo[][Name]), "Team%i", i + 1)
		}
	}
}

public Func_ShowHudScore()
{
	new iLen
	
	copy(g_szScore, charsmax(g_szScore), "")

	for (new i = g_iCurrentGame > 2 ? g_iCurrentGame - 2 : 0; i < g_iCurrentGame; i++)
	{
		switch (g_iGamesWinner[i])
		{
			case 3:
				iLen += format(g_szScore[iLen], charsmax(g_szScore) - iLen, "Game %d [D%d:%dD]   ", i + 1, g_eTeamInfo[0][TakenRounds][i], g_eTeamInfo[1][TakenRounds][i])
			case 1:
				iLen += format(g_szScore[iLen], charsmax(g_szScore) - iLen, "Game %d [%d:%dW]   ", i + 1, g_eTeamInfo[0][TakenRounds][i], g_eTeamInfo[1][TakenRounds][i])
			case 0:
				iLen += format(g_szScore[iLen], charsmax(g_szScore) - iLen, "Game %d [W%d:%d]   ", i + 1, g_eTeamInfo[0][TakenRounds][i], g_eTeamInfo[1][TakenRounds][i])
		}
	}
	iLen += format(g_szScore[iLen], charsmax(g_szScore) - iLen, "Game %d [%d:%d]", g_iCurrentGame + 1, g_eTeamInfo[0][TakenRounds][g_iCurrentGame], g_eTeamInfo[1][TakenRounds][g_iCurrentGame])
	
	new iPlayers[MAX_PLAYERS], iPlayersNum
	get_players(iPlayers, iPlayersNum)
	set_hudmessage(255, 255, 255, 0.01, 0.15, 0, 0.0, 1000.0, 0.1, 0.2, 5)
	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		Func_ShowScore(iPlayers[iPlayersNum])
	}
}

public Func_ShowScore(id)
{
	if (is_user_alive(id))
	{
		message_begin(MSG_ONE, g_iMsg_Status, .player = id)
		write_byte(0)
		write_string(g_szScore)
		message_end()
	}
	show_hudmessage(id, "%s^n%s VS %s ", g_szScore, g_eTeamInfo[0][Name], g_eTeamInfo[1][Name])
}

Func_GetTeamName(WarTeams:iTeam, szArgTeam[32], bool:bColor = false)
{
	switch (iTeam)
	{
		case Team1:
		formatex(szArgTeam, charsmax(szArgTeam), "%sTerrorist", bColor ? "\r" : "")
		case Team2:
		formatex(szArgTeam, charsmax(szArgTeam), "%sCounter-Terrorist", bColor ? "\y" : "")
		case Spectator:
		formatex(szArgTeam, charsmax(szArgTeam), "%sSpectator", bColor ? "\d" : "")
	}
}