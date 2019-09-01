new TeamName:g_iTeam[MAX_PLAYERS + 1]
new bool:g_bSolid[MAX_PLAYERS + 1]
new bool:g_bHasSemiclip[MAX_PLAYERS + 1]

#define SEMICLIP_DISTANCE 260.0

public plugin_init()
{
	register_forward(FM_PlayerPreThink, "FM__PlayerPreThink")
	register_forward(FM_PlayerPostThink, "FM__PlayerPostThink")
	register_forward(FM_AddToFullPack, "FM__AddToFullPack", 1)
}

FirstThink()
{
	new iPlayers[MAX_PLAYERS], iNum, id
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		id = iPlayers[iNum]
		g_bSolid[id] = pev(id, pev_solid) == SOLID_SLIDEBOX ? true : false
	}
}

public FM__PlayerPreThink(id)
{
	static i, LastThink
	
	if (LastThink > id)
	{
		FirstThink()
	}
	
	LastThink = id

	if (!g_bSolid[id])
	{
		return FMRES_IGNORED
	}
	
	new iPlayers[MAX_PLAYERS], iNum
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		i = iPlayers[iNum]

		if (!g_bSolid[i] || id == i)
		{
			continue
		}

		if (g_iTeam[i] == g_iTeam[id])
		{
			set_pev(i, pev_solid, SOLID_NOT)
			g_bHasSemiclip[i] = true
		}
	}
	
	return FMRES_IGNORED
}

public FM__PlayerPostThink(id)
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

public FM__AddToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if (player)
	{
		#if defined BOOST

		static Float:flDistance
		flDistance = entity_range(host, ent)
		
		if (g_bSolid[host] && g_bSolid[ent] && g_iTeam[host] == g_iTeam[ent] && flDistance < SEMICLIP_DISTANCE)
		{
			set_es(es, ES_Solid, SOLID_NOT)
			set_es(es, ES_RenderMode, kRenderTransAlpha)
			set_es(es, ES_RenderAmt, floatround(flDistance) / 1)
		}
	}
	
	return FMRES_IGNORED
}

public FM__AddToFullPack_Pre(es, e, ent, host, hostflags, player, pSet)
{
	if (player && is_user_alive(host) && g_iTeam[host] == TEAM_SEEKER && g_iTeam[ent] == TEAM_HIDER)
	{
		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}