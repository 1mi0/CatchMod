#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>

#define PLUGIN  "SpecInfo"
#define VERSION "1.0"
#define AUTHOR  "mi0"

#define LISTR 45
#define LISTG 89
#define LISTB 116
#define LISTX 0.7
#define LISTY 0.1

#define LISTFREQ 10

// have no fking idea why this shi is here but lets not touch it....
#define BIT_ADD(%1,%2) %1 |= (1 << %2)
#define BIT_CHECK(%1,%2) %1 & (1 << %2)

enum PlayerSettings
{
	Name[32],
	bool:Keys,
	bool:KeysSpec,
	KeysString[192],
	bool:List,
	bool:ListHide,
	SpectatingIndex,
	ListString[256],
	WatchingCount
}

new g_iThinkingEntity, iSyncHudListObj, iSyncHudKeysObj
new g_ePlayerSettings[MAX_PLAYERS + 1][PlayerSettings]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	iSyncHudListObj = CreateHudSyncObj()
	iSyncHudKeysObj = CreateHudSyncObj()

	g_iThinkingEntity = rg_create_entity("info_target")
	set_entvar(g_iThinkingEntity, var_classname, "SpecInfo_Entity")
	set_entvar(g_iThinkingEntity, var_nextthink, get_gametime() + 10.0)
	RegisterHam(Ham_Think, "info_target", "OnEntityThink")
}

public client_connect(id)
{
	get_user_name(id, g_ePlayerSettings[id][Name], charsmax(g_ePlayerSettings[][Name]))
	g_ePlayerSettings[id][List] = true
	g_ePlayerSettings[id][ListHide] = false
	g_ePlayerSettings[id][Keys] = false
	g_ePlayerSettings[id][KeysSpec] = true
	Func_ClearStorages(id)
}

public client_infochanged(id)
{
	get_user_info(id, "name", g_ePlayerSettings[id][Name], charsmax(g_ePlayerSettings[][Name]))
}

public OnEntityThink()
{
	static iListCounter
	if (++iListCounter >= LISTFREQ)
	{
		Func_UpdateList()
		iListCounter = 0
	}

	Func_UpdateKeys()

	set_entvar(g_iThinkingEntity, var_nextthink, get_gametime() + 0.1)
}

Func_UpdateKeys()
{
	new iPlayers[MAX_PLAYERS], iPlayersNum
	get_players_ex(iPlayers, iPlayersNum)
	
	new iTargetIndex
	new bool:bNeeded[33], iSpecIndex[33]
	for (new i = 0; i < iPlayersNum; i++)
	{
		iTargetIndex = iPlayers[i]
		if (is_user_alive(iTargetIndex))
		{
			if (g_ePlayerSettings[iTargetIndex][Keys])
			{
				bNeeded[iTargetIndex] = true
			}
		}
		else
		{
			if (!g_ePlayerSettings[iTargetIndex][KeysSpec] || 
				!is_user_alive((iSpecIndex[iTargetIndex] = get_entvar(iTargetIndex, var_iuser2))) ||
				bNeeded[iSpecIndex[iTargetIndex]])
			{
				continue
			}

			bNeeded[iSpecIndex[iTargetIndex]] = true
		}
	}

	for (new i; i < iPlayersNum; i++)
	{
		iTargetIndex = iPlayers[i]
		if (!bNeeded[iTargetIndex])
		{
			continue
		}

		Func_FormatButtons(iTargetIndex)
	}

	new iObserved
	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		iTargetIndex = iPlayers[iPlayersNum]

		if (is_user_alive(iTargetIndex) && g_ePlayerSettings[iTargetIndex][Keys])
		{
			iObserved = iTargetIndex
		}
		else if (g_ePlayerSettings[iTargetIndex][KeysSpec])
		{
			iObserved = iSpecIndex[iTargetIndex]
		}
		else
		{
			continue
		}

		Func_ShowKeys(iTargetIndex, iObserved)
	}
}

Func_FormatButtons(id)
{
	new iButtons = get_entvar(id, var_button)

	// definately didnt steal that HUH
	formatex(g_ePlayerSettings[id][KeysString], charsmax(g_ePlayerSettings[][KeysString]), "^n^t^t%s^t^t^t%s^n^t%s %s %s^t^t%s",
			iButtons & IN_FORWARD ? "W" : " .",
			iButtons & IN_JUMP ? "Jump" : "  -",
			iButtons & IN_MOVELEFT ? "A" : ".",
			iButtons & IN_BACK ? "S" : ".",
			iButtons & IN_MOVERIGHT ? "D" : ".",
			iButtons & IN_DUCK ? "Duck" : "  -"
		)
}

Func_ShowKeys(iObs, iObsed)
{
	set_hudmessage(0, 30, 200, 0.48, 0.40, 0, 0.0, 0.1, 0.1, 0.0)
	ShowSyncHudMsg(iObs, iSyncHudKeysObj, g_ePlayerSettings[iObsed][KeysString])
}

Func_UpdateList()
{
	new iPlayers[MAX_PLAYERS], iPlayersNum, iPlayersDead[MAX_PLAYERS], iPlayersDeadNum
	new iTargetIndex, iSpectatingIndex

	get_players_ex(iPlayers, iPlayersNum, GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV)
	for (new i; i < iPlayersNum; i++)
	{
		Func_ClearStorages(iPlayers[i])
	}

	get_players_ex(iPlayersDead, iPlayersDeadNum, GetPlayers_ExcludeAlive | GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV)
	for (new i; i < iPlayersDeadNum; i++)
	{
		iTargetIndex = iPlayersDead[i]
		if ((iSpectatingIndex = get_entvar(iTargetIndex, var_iuser2)) && iSpectatingIndex != iTargetIndex)
		{
			if (!g_ePlayerSettings[iTargetIndex][ListHide])
			{
				format(g_ePlayerSettings[iSpectatingIndex][ListString], charsmax(g_ePlayerSettings[][ListString]), 
					"%s^n^t%s", g_ePlayerSettings[iSpectatingIndex][ListString], g_ePlayerSettings[iTargetIndex][Name])
			}
			g_ePlayerSettings[iSpectatingIndex][WatchingCount]++
			g_ePlayerSettings[iTargetIndex][SpectatingIndex] = iSpectatingIndex
		}
	}

	for (new i; i < iPlayersNum; i++)
	{
		iTargetIndex = iPlayers[i]
		
		if (is_user_alive(iTargetIndex))
		{
			Func_FormatList(iTargetIndex)
		}
	}

	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		iTargetIndex = iPlayers[iPlayersNum]

		if (g_ePlayerSettings[iTargetIndex][List] && g_ePlayerSettings[is_user_alive(iTargetIndex) ? iTargetIndex : g_ePlayerSettings[iTargetIndex][SpectatingIndex]][WatchingCount])
		{
			Func_ShowList(iTargetIndex, is_user_alive(iTargetIndex) ? iTargetIndex : g_ePlayerSettings[iTargetIndex][SpectatingIndex])
		}
	}
}

Func_FormatList(id)
{
	format(g_ePlayerSettings[id][ListString], charsmax(g_ePlayerSettings[][ListString]), "Watching %s [%i]:%s", 
		g_ePlayerSettings[id][Name], g_ePlayerSettings[id][WatchingCount], g_ePlayerSettings[id][ListString])
}

Func_ShowList(id, iListOwner)
{
	set_hudmessage(LISTR, LISTG, LISTB, LISTX, LISTY, 0, 0.0, 1.0)
	ShowSyncHudMsg(id, iSyncHudListObj, g_ePlayerSettings[iListOwner][ListString])
}

Func_ClearStorages(id)
{
	g_ePlayerSettings[id][SpectatingIndex] = 0
	g_ePlayerSettings[id][WatchingCount] = 0
	copy(g_ePlayerSettings[id][ListString], charsmax(g_ePlayerSettings[][ListString]), "")
}
