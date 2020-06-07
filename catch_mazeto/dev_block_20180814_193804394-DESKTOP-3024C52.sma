#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new g_iFrameTime[33]
new g_iViolations[33]

public plugin_init()
{
	register_plugin("Dev blocker", "1.0", "mi0")
	register_forward(FM_CmdStart, "OnCmdStart")

	set_task(1.0, "CheckForDev", .flags = "ab")
}

public client_putinserver(id)
{
	g_iFrameTime[id] = 10
	g_iViolations[id] = 0
}

public OnCmdStart(id, iUC_Handle)
{
	g_iFrameTime[id] = get_uc(iUC_Handle, UC_Msec)
}

public CheckForDev()
{
	new iPlayers[MAX_PLAYERS], iPlayersNum
	get_players_ex(iPlayers, iPlayersNum, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV | GetPlayers_ExcludeBots)

	new iPlayer
	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		iPlayer = iPlayers[iPlayersNum]
		if (g_iFrameTime[iPlayer] > 10)
		{
			continue
		}

		if (++g_iViolations[iPlayer] < 3)
		{
			continue
		}
		
		server_cmd("kick #%d ^"%s^"", get_user_userid(iPlayer), "Developer 1")
	}
}
