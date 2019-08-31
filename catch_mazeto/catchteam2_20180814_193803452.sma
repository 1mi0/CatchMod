#include <amxmodx>
#include <amxmisc>
#include <cstrike> 
#include <engine>
#include <fakemeta>

#pragma semicolon 1

#define PLUGNAME		"CatchTeam"
#define VERSION			"0.1"
#define AUTHOR			"Thunder_trLr"

#define ACCESS_PVP		ADMIN_LEVEL_C

new statusMsg;

new g_menuPosition[33];
new g_menuPlayers[33][32];
new g_menuPlayersNum[33];
new g_menuOption[33];

new g_playerTeam[33];

new g_team[2][32];
new g_teamsize[2];

new g_coloredMenus = 1;

new g_warEnabled = 0;
new g_maxPlayers = 32;
new g_amxTurbo = 10;

#define MAX_GAMES	16
new g_game = 1;
// new g_round = 0;
new g_swapped = 0;
new g_notswapped = 1;
new g_fleerswapped = 0;
new g_fleerswappedtemp = 0;
new g_score[MAX_GAMES][2];
new g_teamName[2][33];
new g_win[MAX_GAMES];
new Float:g_points[2];
new Float:g_pointsCurrent[2];
new Float:g_roundStartTime;
// new g_distance

new Float:g_roundTime;

new hudScore[479];
new textScore[479];

new gmsgSayText;
new gmsgTeamInfo;

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

new g_TeamNames[4][] = {
	"None",
	"Team1",
	"Team2",
	"Spec"
};

new g_TeamNums[][] = {
	"",
	"1",
	"2",
	"6"
};

/*
  * White - \w
  * Yellow - \y
  * Red - \r
  * Grey/Disabled - \d
*/
new g_TeamColors[4][] = {
	"",
	"\r",
	"\y",
	"\d"
};

new oldAutoteamBalance;
new oldLimitTeams;
new oldAmxTurbo;

// Old Style Menus
stock const FIRST_JOIN_MSG[] =			"#Team_Select";
stock const FIRST_JOIN_MSG_SPEC[] =		"#Team_Select_Spect";
stock const INGAME_JOIN_MSG[] =			"#IG_Team_Select";
stock const INGAME_JOIN_MSG_SPEC[] =	"#IG_Team_Select_Spect";
stock const JOIN_T_MSG[]  =			"#Terrorist_Select";
stock const JOIN_CT_MSG[] =			"#CT_Select";

const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC);

#define POINTS_TASK_TIME	0.1
#define POINTS_TASK			38271

// New VGUI Menus
stock const VGUI_JOIN_TEAM_NUM =		2;

public plugin_init()
{
	register_plugin(PLUGNAME, VERSION, AUTHOR);
	
	register_clcmd("amx_res", "pointsReset", ACCESS_PVP, "- displays pvp menu");
	
	register_clcmd("amx_pvp", "cmdPVPMenu", ACCESS_PVP, "- displays pvp menu");
	register_clcmd("amx_war", "cmdMatchMenu", ACCESS_PVP, "- displays match menu");
	
	register_menucmd(register_menuid("PVP Menu"), 1023, "actionPVPMenu");
	register_menucmd(register_menuid("Match Menu"), 1023, "actionMatchMenu");
	
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "message_VGUIMenu");
	
	register_clcmd( "chooseteam" , "BlockTeamChange" );
	register_clcmd( "jointeam"   , "BlockTeamChange" );
	register_clcmd( "joinclass"  , "BlockTeamChange" );
	
	register_clcmd( "t"   , "jt" );
	register_clcmd( "c"   , "jct" );
	register_clcmd( "s"   , "jspec" );
	
	register_event( "TextMsg", "restartEvent", "a", "2&#Game_C" );
	register_event( "TextMsg", "restartEvent", "a", "2=#Game_will_restart_in");
	
	// register_event( "HLTV", "roundStart", "a", "1=0", "2=0" );
	register_logevent( "roundStart", 2, "0=World triggered", "1=Round_Start" );
	register_logevent( "roundEnd", 2, "0=World triggered", "1=Round_End" );
	
	register_event( "DeathMsg" , "EvDeathMsg" , "a" , "1>0" );
	// register_logevent("Team_Win", 6, "0=Team");
	
	g_maxPlayers = get_maxplayers();
	statusMsg = get_user_msgid("StatusText");
	gmsgSayText = get_user_msgid("SayText");
	gmsgTeamInfo = get_user_msgid("TeamInfo");
	
	oldAmxTurbo = get_cvar_num("amx_turbo");
	oldAutoteamBalance = get_cvar_num("mp_autoteambalance");
	oldLimitTeams = get_cvar_num("mp_limitteams");
	
	// set_task(POINTS_TASK_TIME, "pointTask", POINTS_TASK, "", 0, "b");
	
	g_roundStartTime = get_gametime();
}

public pointsReset(id, level, cid)
{
	g_points[0] = 0.0;
	g_points[1] = 0.0;
	g_pointsCurrent[0] = 0.0;
	g_pointsCurrent[1] = 0.0;
	
	return PLUGIN_HANDLED;
}

public pointTask()
{
	new p1 = 0, p2 = 0;
	
	new scoreMessage[256];
	format(scoreMessage, 256, "Points[0]: %.0f/%.0f      Points[1]: %.0f/%.0f",
		g_pointsCurrent[0], g_points[0], g_pointsCurrent[1], g_points[1]);
	
	set_hudmessage ( 255, 255, 255, 0.01, 0.15, 0, 0.0, 1000.0, 0.1, 0.2, 1 );
	for(new i = 1; i <= g_maxPlayers; i++)
	{
		if(is_user_connected(i))
		{
			if(is_user_alive(i))
			{
				show_message( i, scoreMessage );
				if(p1 == 0)
				{
					p1 = i;
				}
				else if(p2 == 0)
				{
					p2 = i;
				}
			}
		}
	}
	
	if(p1 != 0 && p2 != 0)
	{
		new Float:o1[3], Float:o2[3];
		pev(p1, pev_origin, o1);
		pev(p2, pev_origin, o2);
		
		new Float:d = get_distance_f( o1, o2 );
		
		if(g_fleerswappedtemp == 0)
		{
			g_pointsCurrent[0] += floatdiv(1000.0, d);
		}
		else
		{
			g_pointsCurrent[1] += floatdiv(1000.0, d);
		}
	}
}

public client_putinserver(id)
{
	g_playerTeam[id] = 3;
	
	if(g_warEnabled)
	{
		handle_join(id, 3);
	}
}

public client_disconnect(id)
{
	g_playerTeam[id] = 3;
	rebuildTeamNames();
}

public plugin_end()
{
	setWarEnabled(0);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/******************************************************* CHOOSETEAM *******************************************************/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public teamSwapCallback(swap)
{
	if(g_fleerswappedtemp == 0)
	{
		g_points[0] += floatdiv(g_pointsCurrent[0], get_gametime() - g_roundStartTime);
		g_pointsCurrent[0] = 0;
	}
	else
	{
		g_points[1] += floatdiv(g_pointsCurrent[1], get_gametime() - g_roundStartTime);
		g_pointsCurrent[1] = 0;
	}
	
	// server_print("[Catchmod] TIME: %.2f", get_gametime() - g_roundStartTime);
	
	// server_print("[Catchmod] Swap: %d", swap);
	g_fleerswappedtemp = swap;
	g_roundStartTime = get_gametime();
}
/*
public roundEnd()
{
	set_task(0.1, "roundEndDelay");
}
*/
public roundEnd()
{
	if(get_gametime() - g_roundTime < 2.0)
	{
		g_fleerswapped = g_fleerswappedtemp;
		return;
	}
	
	if(!g_warEnabled)
	{
		g_fleerswapped = g_fleerswappedtemp;
		return;
	}
		
	// Who Won
	static teamAlive[2];
	teamAlive[0] = 0;	teamAlive[1] = 0;
	for(new i = 0; i < g_teamsize[0]; i++)
	{
		if(is_user_alive(g_team[0][i]))
		{
			teamAlive[0]++;
		}
	}
	for(new i = 0; i < g_teamsize[1]; i++)
	{
		if(is_user_alive(g_team[1][i]))
		{
			teamAlive[1]++;
		}
	}
	
	if(g_teamsize[0] == 0 || g_teamsize[1] == 0)
	{
		rebuildHudMessages();
		set_task(0.5, "showHudScore");
		checkTeams();
		g_fleerswapped = g_fleerswappedtemp;
		return;
	}
	
	if(g_win[g_game] == 3)
	{
		if(teamAlive[ (g_fleerswapped + g_swapped)%2 ] > 0)
			g_score[g_game][ (g_fleerswapped + g_swapped)%2 ]++;
		else
			g_score[g_game][ (g_fleerswapped + g_notswapped)%2 ]++; // !
	}
	g_fleerswapped = g_fleerswappedtemp;
    
	new win = -1;
	if(g_score[g_game][0] < 5 && g_score[g_game][1] < 5)
	{
		if(g_score[g_game][0] - g_score[g_game][1] >= 3)
		{
			// 3 point difference before 5-th point
			win = 0;
		}
		else if(g_score[g_game][1] - g_score[g_game][0] >= 3)
		{
			win = 1;
		}
	}
	else if(g_score[g_game][0] < 7 && g_score[g_game][1] < 7)
	{
		if(g_score[g_game][0] - g_score[g_game][1] >= 2)
		{
			// 2 point difference before 7-th point
			win = 0;
		}
		else if(g_score[g_game][1] - g_score[g_game][0] >= 2)
		{
			// win = g_notswapped;
			win = 1;
		}
	}
	else
	{
		// Someone has 7 points, if swap == 0, terrorist fleers win, ct catchers don't
		if(g_score[g_game][0] - g_score[g_game][1] >= 2)
		{
			// 2 point difference
			win = 0;
			
		}
		else if(g_score[g_game][1] - g_score[g_game][0] >= 2)
		{
			// 2 point difference
			win = 1;
		}
		else if(g_score[g_game][g_swapped] >= 7)
		{
			// Win
			win = g_swapped;
		}
		else
		{
			// Draw
			win = 2;
		}
	}
	
	if(win > -1 && g_win[g_game] == 3)
	{
		g_win[g_game] = win;
		// showing who wins the game
		if(win == 2)
		{
			ColorChat(0, 0, "^x04[ ====== Game Draw ====== ]");
			client_print(0, print_chat, "[ ====== Game Draw ====== ]");
		}
		else
		{
			ColorChat(0, 0, "^x01[ ====== ^x04%s^x01 Wins Game ^x04%d^x01 ====== ]", g_teamName[win], g_game);
			// client_print(0, print_chat, "[ ====== %s Wins Game %d ====== ]", g_teamName[win], g_game);	
		}
		
		set_task(0.5, "delayedWinner");
		
		new wins[3]; wins[0] = 0; wins[1] = 0; wins[2] = 0;
		for(new i = 1; i <= g_game; i++)
		{
			if(g_win[i] == 0)
			{
				wins[0]++;
			}
			else if(g_win[i] == 1)
			{
				wins[1]++;
			}
			else if(g_win[i] == 2)
			{
				wins[2]++;
			}
				
			if(wins[0] >= 2)
			{
				ColorChat(0, 0, "^x01[ ====== ^x04%s^x01 Wins ^x04Match^x01 ====== ]", g_teamName[0]);
				// ColorChat(0, 0, "^x01[ ====== ^x04%s^x01 Wins ^x04Match^x01 ====== ]", g_teamName[0]);
				// ColorChat(0, 0, "^x01[ ====== ^x04%s^x01 Wins ^x04Match^x01 ====== ]", g_teamName[0]);
				client_print(0, print_chat, "The Match will end in 15 seconds");
				set_task(10.0, "disableWarDelayed");
			}
			else if(wins[1] >= 2)
			{
				ColorChat(0, 0, "^x01[ ====== ^x04%s^x01 Wins ^x04Match^x01 ====== ]", g_teamName[1]);
				// ColorChat(0, 0, "^x01[ ====== ^x04%s^x01 Wins ^x04Match^x01 ====== ]", g_teamName[1]);
				// ColorChat(0, 0, "^x01[ ====== ^x04%s^x01 Wins ^x04Match^x01 ====== ]", g_teamName[1]);
				client_print(0, print_chat, "The Match will end in 15 seconds");
				set_task(10.0, "disableWarDelayed");
			}
			else if(wins[2] >= 2)
			{
				ColorChat(0,0, "[ ====== Match Draw ====== ]");
				client_print(0, print_chat, "The Match will end in 15 seconds");
				set_task(10.0, "disableWarDelayed");
			
				
			}
		}
		
		if(wins[0] < 2 && wins[1] < 2)
		{
			// client_print(0, print_chat, "[ == %s [%d] vs %s [%d] == ]", g_teamName[0], g_score[g_game][0], g_teamName[1], g_score[g_game][1]);
			ColorChat(0, 0, "^x01[ == ^x04 %s^x01  [^x04%d^x01] vs ^x04 %s^x01  [^x04%d^x01] == ]", g_teamName[0], g_score[g_game][0], g_teamName[1], g_score[g_game][1]);
			client_print(0, print_chat, "Next Game will begin in 10 seconds");
			
			set_task(10.0, "nextGame");
		}
	}
	
	rebuildHudMessages();
	set_task(0.5, "showHudScore");
	
	if(g_win[g_game] == 3)
	{
		ColorChat(0, 0, "^x01[ == ^x04 %s^x01  [^x04%d^x01] vs ^x04 %s^x01  [^x04%d^x01] == ]", g_teamName[0], g_score[g_game][0], g_teamName[1], g_score[g_game][1]);
	}
	
	checkTeams();
}

public delayedWinner()
{
	if(g_win[g_game] == 2)
	{
		client_print(0, print_center, "[ ====== Match Draw ====== ]");
	}
	else
	{
		client_print(0, print_center, "[ ====== %s Wins Game %d ====== ]", g_teamName[g_win[g_game]], g_game);	
	}
}

public nextGame()
{
	// Swap teams
	g_notswapped = g_swapped;
	g_swapped = 1 - g_swapped;	
	
	g_game++;
	g_score[g_game][0] = 0;
	g_score[g_game][1] = 0;
	g_score[g_game][2] = 0;
	g_win[g_game] = 3;
	set_cvar_num("sv_restart", 1);
	
	g_fleerswapped = g_fleerswappedtemp;
	g_roundTime = get_gametime();
	checkTeams();
	rebuildHudMessages();
}
/*
public roundStart()
{
	set_task(0.1, "roundStartDelay");
}
*/
public roundStart()
{
	// g_round++;
	g_roundTime = get_gametime();
	
	if(!g_warEnabled)
		return;
		
	checkTeams();
	
	rebuildHudMessages();
	set_task(0.5, "showHudScore");
	
	if(g_score[g_game][0] == 0 && g_score[g_game][1] == 0)
	{
		ColorChat(0, 0, "^x01[ == ^x04 %s^x01  [^x04%d^x01] vs ^x04 %s^x01  [^x04%d^x01] == ]", g_teamName[0], g_score[g_game][0], g_teamName[1], g_score[g_game][1]);
	}
	
	if(g_win[g_game] == 3)
	{
		// print_color(0, "[ == ^x03 %s^x01  [%d] vs ^x03 %s^x01  [%d] == ]", g_teamName[0], g_score[g_game][0], g_teamName[1], g_score[g_game][1]);
		// ColorChat(0, 0, "^x03[ == ^x04 %s^x03  [%d] vs ^x04 %s^x03  [%d] == ]", g_teamName[0], g_score[g_game][0], g_teamName[1], g_score[g_game][1]);
		// ColorChat(0, 0, "^x01[ == ^x04 %s^x01  [^x04%d^x01] vs ^x04 %s^x01  [^x04%d^x01] == ]", g_teamName[0], g_score[g_game][0], g_teamName[1], g_score[g_game][1]);
		// ColorChat(0, 1, "^x01test^x04test");
		// ColorChat(0, 0, "^x03test^x02test^x03test^x04test^x01test");
		// Send_SayText(0, "^x01test^x02test^x03test^x04test^x01test");
	}
	else
	{
		set_task(0.5, "delayedWinner");
	}
		
	// rebuildHudMessages();
}

public restartEvent()
{
	g_roundTime = get_gametime();
	
	if(!g_warEnabled)
		return;
	
	// g_round = 0;
	g_score[g_game][0] = 0;
	g_score[g_game][1] = 0;
	// g_swapped = 0;
	
	g_fleerswapped = g_fleerswappedtemp;
	set_task(0.1, "checkTeams");
	rebuildHudMessages();
}

public EvDeathMsg()
{
    new iKiller = read_data( 1 );
    new iVictim = read_data( 2 );
	
	set_hudmessage ( 255, 255, 255, 0.01, 0.15, 0, 0.0, 1000.0, 0.1, 0.2, 1 );
	show_hudmessage( iVictim, hudScore );
}  

public checkTeams()
{
	if(!g_warEnabled)
		return;
	
	new team, newTeam;
	for(new i = 1; i <= g_maxPlayers; i++)
	{
		if( is_user_connected(i) )
		{
			team = _:cs_get_user_team(i);
			
			newTeam = g_playerTeam[i];
			if(g_swapped)
			{
				if(newTeam == 1)
				{
					newTeam = 2;
				}
				else if(newTeam == 2)
				{
					newTeam = 1;
				}
			}

			if(newTeam != team)
			{
				handle_join(i, newTeam);
			}
		}
	}
}

public rebuildTeamNames()
{
	static name[2][32];
	static len[2];
	
	g_teamsize[0] = 0; g_teamsize[1] = 0;
	for(new i = 1; i <= g_maxPlayers; i++)
	{
		if( is_user_connected(i) )
		{
			if(g_playerTeam[i] == 1)
			{
				g_team[0][g_teamsize[0]] = i;
				g_teamsize[0]++;
			}
			else if(g_playerTeam[i] == 2)
			{
				g_team[1][g_teamsize[1]] = i;
				g_teamsize[1]++;
			}
		}
	}
	
	// client_print(0, print_chat, "DEBUG Team1 (%d) Team 2 (%d)", g_teamsize[0], g_teamsize[1]);
	
	g_teamName[0][0] = 88;		g_teamName[0][1] = 0;
	g_teamName[1][0] = 89;		g_teamName[1][1] = 0;
	
	if(g_teamsize[0] == 1 )
	{
		get_user_name(g_team[0][0], g_teamName[0], 31);
	}
	else if(g_teamsize[0] > 1)
	{
		for(new i = 1; i < g_teamsize[0]; i++)
		{
			get_user_name(g_team[0][i - 1], name[0], 31);
			get_user_name(g_team[0][i + 0], name[1], 31);
			
			len[0] = strlen(name[0]);
			len[1] = strlen(name[1]);
			
			if(len[1] > len[0])
				len[0] = len[1];
			
			for(new p = 0; p < len[0]; p++)
			{
				if(name[0][p] != name[1][p])
				{
					if(p > 2)
					{
						// Found tag name?
						copy(g_teamName[0], p, name[0]);
						g_teamName[0][p] = 0;
						i = g_teamsize[0];
					}
					break;
				}
			}
		}
	}
	
	if(g_teamsize[1] == 1)
	{
		get_user_name(g_team[1][0], g_teamName[1], 31);
	}
	else if(g_teamsize[1] > 1)
	{
		for(new i = 1; i < g_teamsize[1]; i++)
		{
			get_user_name(g_team[1][i - 1], name[0], 31);
			get_user_name(g_team[1][i + 0], name[1], 31);
			
			len[0] = strlen(name[0]);
			len[1] = strlen(name[1]);
			
			if(len[1] > len[0])
				len[0] = len[1];
			
			for(new p = 0; p < len[0]; p++)
			{
				if(name[0][p] != name[1][p])
				{
					if(p > 2)
					{
						// Found tag name?
						copy(g_teamName[1], p, name[0]);
						g_teamName[1][p] = 0;
						i = g_teamsize[1];
					}
					break;
				}
			}
		}
	}
}

public jt(id)
{
	handle_join(id, 1);
}

public jct(id)
{
	handle_join(id, 2);
}

public jspec(id)
{
	handle_join(id, 3);
}

public handle_join(id, iTeam)
{
	if(is_user_alive(id))
		user_silentkill(id);
	
	if(iTeam == 3) // spec
	{
		set_task(0.1, "handle_join_spec_delay", id);
	}
	else
	{
		engclient_cmd(id, "jointeam", g_TeamNums[iTeam]);
		set_task(0.1, "handle_join_delay", id);
	}
}

public handle_join_spec_delay(id)
{
	engclient_cmd(id, "jointeam", "6");
}

public handle_join_delay(id)
{
	engclient_cmd(id, "joinclass", "1");
}

public BlockTeamChange(id)
{
	if(!g_warEnabled)
		return PLUGIN_CONTINUE;
		
	client_print(id, print_chat, "Teamchange Blocked");
	
	return PLUGIN_HANDLED;
}

public message_ShowMenu(iMsgid, iDest, id)
{
	if(!g_warEnabled)
		return PLUGIN_CONTINUE;
	
	static sMenuCode[iMaxLen];
	get_msg_arg_string(4, sMenuCode, sizeof(sMenuCode) - 1);
	
	if(equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC))
	{
		return PLUGIN_HANDLED;
	}
	else if(equal(sMenuCode, INGAME_JOIN_MSG) || equal(sMenuCode, INGAME_JOIN_MSG_SPEC))
	{
		return PLUGIN_HANDLED;
	}
	else if(equal(sMenuCode, JOIN_T_MSG) || equal(sMenuCode, JOIN_CT_MSG))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public message_VGUIMenu(iMsgid, iDest, id)
{
	if(!g_warEnabled || get_msg_arg_int(1) != VGUI_JOIN_TEAM_NUM)
	{
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/******************************************************** WAR MENU ********************************************************/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public actionPVPMenu(id, key)
{
	switch (key)
	{
		case 7:
		{
			g_menuOption[id]++;
			if(g_menuOption[id] > 3)
			  g_menuOption[id] = 1;
			
			displayPVPMenu(id, g_menuPosition[id]);
		}
		case 8: displayPVPMenu(id, ++g_menuPosition[id]);
		case 9: displayPVPMenu(id, --g_menuPosition[id]);
		default:
		{
			new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key];
			new authid[32], authid2[32], name[32], name2[32];

			get_user_name(player, name2, 31);
			get_user_authid(id, authid, 31);
			get_user_authid(player, authid2, 31);
			get_user_name(id, name, 31);
			
			// (g_menuOption[id] + g_swapped)%2
			if(g_playerTeam[player] != g_menuOption[id])
			{
				g_playerTeam[player] = g_menuOption[id];
				// g_swapped = 0; // BIG NO NO
				
				if(g_warEnabled)
				{
					// Change team imidiatelly
					// handle_join(player, g_playerTeam[player]);
					// delayed join, don't fuck up the current game
					
					rebuildTeamNames();
					rebuildHudMessages();
				}
			}
				
			// log_amx("Cmd: ^"%s<%d><%s><>^" transfer ^"%s<%d><%s><>^" (team ^"%s^")", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2, g_menuOption[id] ? "TERRORIST" : "CT");
			// show_activity_key("ADMIN_TRANSF_1", "ADMIN_TRANSF_2", name, name2, g_CSTeamNames[g_menuOption[id] % 3]);

			// This modulo math just aligns the option to the CsTeams-corresponding number
			// Do something

			displayPVPMenu(id, g_menuPosition[id]);
		}
	}
	
	return PLUGIN_HANDLED;
}

displayPVPMenu(id, pos)
{
	if (pos < 0)
		return;

	get_players(g_menuPlayers[id], g_menuPlayersNum[id]);

	new menuBody[512];
	new b = 0;
	new i; // , iteam;
	new name[32], team[4];
	new start = pos * 7;

	if (start >= g_menuPlayersNum[id])
		start = pos = g_menuPosition[id] = 0;

	new len = format(menuBody, 511, g_coloredMenus ? "\yPvP Menu\R%d/%d^n\w^n" : "PvP Menu %d/%d^n^n", pos + 1, (g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0)));
	new end = start + 7;
	new keys = MENU_KEY_0|MENU_KEY_8;

	if (end > g_menuPlayersNum[id])
		end = g_menuPlayersNum[id];

	for (new a = start; a < end; ++a)
	{
		i = g_menuPlayers[id][a];
		get_user_name(i, name, 31);
		
		keys |= (1<<b);
		++b;
		len += format(menuBody[len], 511-len, "%d. %s%s\R%s^n\w", b, g_TeamColors[g_playerTeam[i]], name, team);
	}

	len += format(menuBody[len], 511-len, "^n8. Transfer to %s%s^n\w", g_TeamColors[g_menuOption[id]], g_TeamNames[g_menuOption[id]]);

	if (end != g_menuPlayersNum[id])
	{
		format(menuBody[len], 511-len, "^n9. %L...^n0. %L", id, "MORE", id, pos ? "BACK" : "EXIT");
		keys |= MENU_KEY_9;
	}
	else
		format(menuBody[len], 511-len, "^n0. %L", id, pos ? "BACK" : "EXIT");

	show_menu(id, keys, menuBody, -1, "PVP Menu");
}

public cmdPVPMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	g_menuOption[id] = 1;

	displayPVPMenu(id, g_menuPosition[id] = 0);

	return PLUGIN_HANDLED;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/******************************************************* MATCH MENU *******************************************************/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public disableWarDelayed()
{
	setWarEnabled(0);
}

public setWarEnabled(en)
{
	g_warEnabled = en;
	if(g_warEnabled)
	{
		oldAmxTurbo = get_cvar_num("amx_turbo");
		oldAutoteamBalance = get_cvar_num("mp_autoteambalance");
		oldLimitTeams = get_cvar_num("mp_limitteams");
		
		set_cvar_num("mp_autoteambalance", 0);
		set_cvar_num("mp_limitteams", 0);
		set_cvar_num("amx_turbo", g_amxTurbo);
		
		g_game = 1;
		g_score[g_game][0] = 0;
		g_score[g_game][1] = 0;
		g_win[g_game] = 3;
		g_points[0] = 0;
		g_points[1] = 0;
		
		set_cvar_num("sv_restart", 1);
		g_roundTime = get_gametime();
		
		rebuildTeamNames();
		checkTeams();
		rebuildHudMessages();
	}
	else
	{
		set_cvar_num("amx_turbo", oldAmxTurbo);
		set_cvar_num("mp_autoteambalance", oldAutoteamBalance);
		set_cvar_num("mp_limitteams", oldLimitTeams);
		
		for(new i = 0; i < g_maxPlayers; i++)
		{
			g_playerTeam[i] = 3;
		}
		
		set_cvar_num("sv_restart", 1);
	}
}

public actionMatchMenu(id, key)
{
	switch (key)
	{
		case 0:
		{
			setWarEnabled(1 - g_warEnabled);
		}
		case 1: // RESTART Match
		{
			set_cvar_num("sv_restart", 1);
			g_roundTime = get_gametime();
			
			g_game = 1;
			g_score[g_game][0] = 0;
			g_score[g_game][1] = 0;
			g_win[g_game] = 3;
			g_points[0] = 0;
			g_points[1] = 0;
			// g_swapped = 0;
			
			rebuildHudMessages();
		}
		case 2: // RESTART Game
		{
			set_cvar_num("sv_restart", 1);
			g_roundTime = get_gametime();
			
			g_score[g_game][0] = 0;
			g_score[g_game][1] = 0;
			g_win[g_game] = 3;
			g_points[0] = 0;
			g_points[1] = 0;
			// g_swapped = 0;
			
			rebuildHudMessages();
		}
		case 3: // TURBO
		{
			g_amxTurbo += 10;
			if(g_amxTurbo > 50)
				g_amxTurbo = 0;
			
			if(g_warEnabled)
				set_cvar_num("amx_turbo", g_amxTurbo);
		}
		case 4: // SWAP TEAMS
		{
			g_notswapped = g_swapped;
			g_swapped = 1 - g_swapped;
			
			new temp = g_score[g_game][0];
			g_score[g_game][0] = g_score[g_game][1];
			g_score[g_game][1] = temp;
			
			checkTeams();
			rebuildHudMessages();
		}
		case 5: // CLEAR TEAMS
		{
			for(new i = 0; i < g_maxPlayers; i++)
			{
				g_playerTeam[i] = 3;
			}
			
			rebuildTeamNames();
			rebuildHudMessages();
		}
		case 9: return PLUGIN_HANDLED;
		default:
		{
			
		}
	}
	
	displayMatchMenu(id, g_menuPosition[id]);
	
	return PLUGIN_HANDLED;
}

displayMatchMenu(id, pos)
{
	if (pos < 0)
		return;

	new menuBody[512];
	new b = 0;
	new keys;
	new len;
	
	len = format(menuBody, 511, g_coloredMenus ? "\yMatch Menu^n\w^n" : "Match Menu^n^n");
	keys = MENU_KEY_0|MENU_KEY_8;

	keys |= (1<<b);	++b;
	if(g_warEnabled)
		len += format(menuBody[len], 511-len, "%d. \r%s^n\w", b, "War Enabled");
	else
		len += format(menuBody[len], 511-len, "%d. \d%s^n\w", b, "War Disabled");
	
	keys |= (1<<b);	++b;
	len += format(menuBody[len], 511-len, "%d. Restart Match^n\w", b);
	
	keys |= (1<<b);	++b;
	len += format(menuBody[len], 511-len, "%d. Restart Game^n\w", b);
	
	keys |= (1<<b);	++b;
	len += format(menuBody[len], 511-len, "%d. Turbo: %d^n\w", b, g_amxTurbo);
	
	keys |= (1<<b);	++b;
	len += format(menuBody[len], 511-len, "%d. Swap Teams^n\w", b);
	
	keys |= (1<<b);	++b;
	len += format(menuBody[len], 511-len, "%d. Clear Teams^n\w", b);
	
	keys |= MENU_KEY_0;
	format(menuBody[len], 511-len, "^n0. Exit");

	show_menu(id, keys, menuBody, -1, "Match Menu");
}

public cmdMatchMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	g_menuOption[id] = 1;

	displayMatchMenu(id, g_menuPosition[id] = 0);

	return PLUGIN_HANDLED;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/******************************************************** MESSAGES ********************************************************/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public rebuildHudMessages()
{
	// new len = format(textScore, 479, "");
	new len = 0;
	new beg = g_game - 2;
	if(beg < 1)
		beg = 1;
	
	for(new i = beg; i < g_game; i++)
	{
		if(g_win[i] == 2)
		{
			len += format(textScore[len], 479-len, "Game %d [D%d:D%d]   ", i, g_score[i][0], g_score[i][1] );
		}
		if(g_win[i] == 1)
		{
			len += format(textScore[len], 479-len, "Game %d [%d:W%d]   ", i, g_score[i][0], g_score[i][1] );
		}
		if(g_win[i] == 0)
		{
			len += format(textScore[len], 479-len, "Game %d [W%d:%d]   ", i, g_score[i][0], g_score[i][1] );
		}
	}
	if((g_fleerswapped + g_swapped)%2)
	{
		len += format(textScore[len], 479-len, "Game %d [%d:F%d]   ", g_game, g_score[g_game][0], g_score[g_game][1] );
	}
	else
	{
		len += format(textScore[len], 479-len, "Game %d [F%d:%d]   ", g_game, g_score[g_game][0], g_score[g_game][0] );
	}
	
	// len += format(textScore[len], 479-len, "   Swapped %d", g_swapped);
	
	// format(textScore, 479, "Game: %d    Round: %d    T: %d    CT: %d    Swapped: %d", g_game, g_round, g_score[g_game][0], g_score[g_game][1], g_swapped);
	
	format(hudScore, 479, "%s^n%s VS %s ", textScore, g_teamName[0], g_teamName[1]);
	
	showHudScore();
}

public showHudScore()
{
	// server_print("[DEBUG] ***************************");
	// set_hudmessage ( red=200, green=100, blue=0, Float:x=-1.0, Float:y=0.35, effects=0, Float:fxtime=6.0, Float:holdtime=12.0, Float:fadeintime=0.1, Float:fadeouttime=0.2, channel=4 ) 
	
	set_hudmessage ( 255, 255, 255, 0.01, 0.15, 0, 0.0, 1000.0, 0.1, 0.2, 1 );
	for(new i = 1; i <= g_maxPlayers; i++)
	{
		if(is_user_connected(i))
		{
			// if(g_playerTeam[i] == 3)
			if(is_user_alive(i))
			{
				show_message( i, textScore );
			}
			else
			{
				show_hudmessage( i, hudScore );
			}
		}
	}
}

public show_message(id, text[])
{
	message_begin(MSG_ONE,statusMsg,{0,0,0},id);
	write_byte(0);
	write_string(text);
	message_end();
}

// ********************************************************************************************

enum Color
{
	YELLOW = 1, // Yellow
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

public ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	static message[256];

	switch(type)
	{
		case YELLOW: // Yellow
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	// new team, ColorChange, index, MSG_Type;
	
	/*if(!id)
	{
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	
	} else {
		MSG_Type = MSG_ONE;
		index = id;
	}*/
	
	// team = get_user_team(index);	
	// ColorChange = ColorSelection(index, MSG_Type, type);

	// ShowColorMessage(index, MSG_Type, message);
	ShowColorMessage(FindPlayer(), MSG_ALL, message);
		
	/*if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}*/
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, gmsgSayText, _, id);
	write_byte(id);
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	message_begin(type, gmsgTeamInfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	new i = -1;

	while(i <= g_maxPlayers)
	{
		if(is_user_connected(++i))
		{
			return i;
		}
	}

	return -1;
}
