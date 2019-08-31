#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <nvault>
#include <hamsandwich>

#define MIN_BOOST_DIST 100
#define SURVIVE 3
#define TURBO_USE_PRO 10
#define TURBO_TIME 0.90
#define distance 07
#define mod_speed 2.0
#define catcher_speed 1.0
#define fleer_speed 1.0
#define bonus 1.15
// #define turbo_use 1.15
#define turbo_use 1.3125
#define boost 700
#define VAULT        "Catch_usercfgs"
#define NUM_CVARS    7
#define FREQ 0.1
#define plug_version 3.3
#if cellbits == 32
	#define OFFSET_BZ 235
#else
	#define OFFSET_BZ 268
#endif
#define STEPS 0.3
#define TRAILF 0.1
#define MAXPLAYERS 32
#pragma semicolon 1
// #define DISTANCE 120
#define DISTANCE 400

new welcome_text[] = "On this server is Catch-Mod Silver Edition running. [ Standard Mod ]";
new bool:plrSpeed[33];
new TaskEnt,SyncHud,showspeed,color, maxplayers, r, g, b;
new g_Vault;
new g_szAuthID[33][35];
new g_Retrieved[33];
new g_Requested[33];
new rounds_elapsed;
new chat_message;
new play_sound;
new bool:caughtJump[33];
new bool:doJump[33];
new Float:jumpVeloc[33][3];
new newButton[33];
new numJumps[33];
new wallteam;
new newmod_on;
new welcomed[33];
new const g_CVARS[NUM_CVARS][16] = 
{
	"cl_forwardspeed",
	"cl_backspeed",
	"cl_sidespeed",
	"fps_max",
	"developer",
	"cl_showfps",
	"hud_centerid"
};
new team_ct = 1;
new team_t = 0;
new boostmode = 1;
new bool:enable = false	;
new team[32];
new score[32][4];
new wait = false;
new points[2];
new bool:boost_show[32];
new bool:trueround = true;
new round = 0;
new bool:blockround = false;
new turbo[32][2];
new bool:firstspawn[32];
new statusMsg;
new scoreMsg;
new deathMsg;
new join_msg;
new sound_welcome;
new g_BuyZone;
new g_fire;
new g_sprite;
new g_knife;
new g_size[2] = {5, 1};
new g_offset[MAXPLAYERS+1][2];
new g_standoffset[2] = {33, 30};
new g_duckoffset[2] = {14, 12};
new g_brightness[2] = {160, 255};
new g_data[MAXPLAYERS+1][4];
new g_trailol;
new g_model;
new Float:nextstep[MAXPLAYERS+1];
new Float:N_Trail[MAXPLAYERS+1];
new g_origin[MAXPLAYERS+1][3];
new g_lorigin[MAXPLAYERS+1][3];
new trainingmod;
new training;
new g_iTeam[33];
new bool:g_bSolid[33];
new bool:g_bHasSemiclip[33];
new Float:g_fOrigin[33][3];
new bool:g_bSemiclipEnabled;
new g_iForwardId[3];
new g_iMaxPlayers;
new g_iCvar[3];
new amx_turbo_cvar;
new amx_turbo;

new g_userOrgin[33][3];
new gFrameTime[33];

public plugin_init()
{
	amx_turbo = 30;
  
	register_clcmd("/cp", "checkpointCmd");
	register_clcmd("/tp", "teleportCmd");

	register_plugin("Catch Mod","3.3","One");
	
	register_clcmd( "say /spec", "clcmd_spec");
	
	register_srvcmd("amx_catch 1", "catch_enable");
	register_srvcmd("amx_catch 0","catch_off");
	register_concmd("amx_train", "amx_training_cmd", ADMIN_SLAY, "0|1");
	register_touch("player","player","touch");
	register_event("ResetHUD","resethud","be");
	register_logevent("startround",2,"0=World triggered","1=Round_Start");
	register_logevent("endround",2,"0=World triggered","1=Round_End");
	register_logevent("drawround",2,"0=World triggered","1=Round_Draw");
	register_logevent("gamestart",2,"0=World triggered","1=Game_Commencing");
	register_logevent("restartround",2,"1&Restart_Round_");
	statusMsg = get_user_msgid("StatusText");
	deathMsg = get_user_msgid("DeathMsg");
	scoreMsg = get_user_msgid("ScoreInfo");
	register_clcmd( "say /menu","Settings");
	register_clcmd( "say /help","help_menu");
	register_clcmd( "say_team /menu","Settings");
	register_clcmd( "say_team /help","help_menu");
	register_forward(FM_Think, "Think");
	g_Vault = nvault_open( VAULT );
	if ( g_Vault == INVALID_HANDLE )
	set_fail_state( "Error opening nvault" );
	set_task( 60.0 , "DeleteEntries" , _, _, _, "b" );
	TaskEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	set_pev(TaskEnt, pev_classname, "speedometer_think");
	set_pev(TaskEnt, pev_nextthink, get_gametime() + 1.01);
	showspeed = register_cvar("showspeed", "1");
	color = register_cvar("speed_colors", "255 255 255");
	SyncHud = CreateHudSyncObj();
	maxplayers = get_maxplayers();
	new colors[16], red[4], green[4], blue[4];
	get_pcvar_string(color, colors, sizeof colors - 1);
	parse(colors, red, 3, green, 3, blue, 3);
	r = str_to_num(red);
	g = str_to_num(green);
	b = str_to_num(blue);
	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	// register_logevent("new_round", 2, "1=Round_Start");
	register_event("TextMsg", "restart_round", "a", "2=#Game_will_restart_in");
	play_sound = register_cvar("amx_playsound","1");
	chat_message = register_cvar("amx_chatmessage","1");
	register_cvar("amx_newmod_ref","300.0");
	register_cvar("amx_newmod_num","3");
	register_cvar("amx_newmod_team", "0");
	amx_turbo_cvar = register_cvar("amx_turbo", "0");
	register_touch("player", "worldspawn", "Touch_World");
	register_touch("player", "func_new_mod", "Touch_World");
	register_touch("player", "func_breakable", "Touch_World");
	newmod_on = register_cvar("amx_newmod_on", "1");
	register_menucmd(register_menuid("welcome_menu"),1023,"welcome_menu_handler");
	join_msg = register_cvar("amx_join_msg","1");
	g_trailol = register_cvar("amx_trail", "1");
	g_model = register_cvar("amx_sprite", "fire");
	register_concmd("amx_trail", "toggle_trail", ADMIN_CVAR, "amx_trail - Toggle Speedup-Trail 1/0.");
	register_concmd("amx_sprite", "toggle_sprite", ADMIN_CVAR, "amx_sprite - Toggle Speedup-Sprite between 1/smoke | 1=Fire");
	register_clcmd("fullupdate", "clcmd_fullupdate");
	register_forward(FM_PlayerPreThink, "fm_playerthink", 1);
	trainingmod = register_cvar("amx_training", "0");
	// training = register_cvar("amx_train", "1");
	training = 0;
	g_iCvar[0] = register_cvar( "semiclip_enabled", "1" );
	g_iCvar[1] = register_cvar( "semiclip_teamclip", "1" );		// 1 only m8
	g_iCvar[2] = register_cvar( "semiclip_transparancy", "1" );
	register_forward( FM_ClientCommand, "fwdClientCommand" );
	if( get_pcvar_num( g_iCvar[0] ) )
	{
		g_iForwardId[0] = register_forward( FM_PlayerPreThink, "fwdPlayerPreThink" );
		g_iForwardId[1] = register_forward( FM_PlayerPostThink, "fwdPlayerPostThink" );
		g_iForwardId[2] = register_forward( FM_AddToFullPack, "fwdAddToFullPack_Post", 1 );
		g_bSemiclipEnabled = true;
	}
	else
		g_bSemiclipEnabled = false;
	g_iMaxPlayers = get_maxplayers( );
	
	register_forward(FM_CmdStart, "cmdStart");
	register_concmd("amx_showfps", "amx_showfps_cmd", ADMIN_SLAY, "");
}

public checkpointCmd(id)
{
	if(training == 0)
		return PLUGIN_CONTINUE;

	if(is_user_alive(id))
	{
		get_user_origin(id, g_userOrgin[id], 0);
		g_userOrgin[id][2] += 10;
	}
	
	return PLUGIN_HANDLED;
}

public teleportCmd(id)
{
	if(training == 0)
		return PLUGIN_CONTINUE;
	
	if(is_user_alive(id) && g_userOrgin[id][0])
	{
		set_user_origin(id, g_userOrgin[id]);
		set_user_velocity (id, {0, 0, 0} );
	}

	return PLUGIN_HANDLED;
}

#define DEAD_TASK 6656
public check_dead()
{
	new id;
	new CsTeams:team;
	new args[1];
	
	for( id = 1 ; id <= g_iMaxPlayers ; id++ )
	{
		if( is_user_connected(id) && !is_user_alive(id) )
		{
			team = cs_get_user_team (id);
			if(team == CS_TEAM_T || team == CS_TEAM_CT)
			{
				spawn(id);
				args[0] = id;
				set_task(0.5, "delayed_spawn", 0, args, 1);
			}
		}
	}
}

public delayed_spawn(id[])
{
	spawn(id[0]);
}

public amx_training_cmd(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[32];
	read_argv(1, arg, 31);
	
	if(arg[0] == 49)
	{
		set_cvar_num("sv_restart", 1);
		set_cvar_float("mp_roundtime", 9.0);
		set_cvar_num("semiclip_teamclip", 0);
		set_task(5.0, "check_dead", DEAD_TASK, "", 0, "ab");
		// set_cvar_num("amx_train", 1);
		training = 1;
	}
	else if(arg[0] == 48)
	{
		set_cvar_num("sv_restart", 1);
		set_cvar_float("mp_roundtime", 1.5);
		set_cvar_num("semiclip_teamclip", 1);
		remove_task(DEAD_TASK);
		// set_cvar_num("amx_train", 0);
		training = 0;
	}
	
	return PLUGIN_HANDLED;
}
public plugin_precache()
{
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "weapon_change", 1);
	// RegisterHam(Ham_CS_Item_CanDrop, "weapon_knife", "weapon_drop", 1);
	// RegisterHam(Ham_Spawn, "player", "fw_Spawn_post", 1);
	// RegisterHam(Ham_Killed, "player", "fw_Killed_post", 1);

	sound_welcome = precache_sound("sound/2.wav");
	g_fire = precache_model("sprites/flame.spr");
	g_sprite = precache_model("sprites/xsmoke4.spr");
	
	g_knife = engfunc(EngFunc_AllocString, "models/v_shoots.mdl");
    precache_model("models/v_shoots.mdl");
}
public new_round()
{
	set_task(1.0, "show_rounds_message");
	amx_turbo = get_cvar_num(amx_turbo_cvar);
}

public restart_round()
{
	rounds_elapsed = 0;
}
public show_welcome(id)
{
	if(welcomed[id]) return;
	new menuid, keys;
	get_user_menu(id,menuid,keys);

	if(menuid > 0)
	{
		set_task(3.0,"show_welcome",id);
		return;
	}
	//play_sound(id,sound_welcome);
	//emit_sound(0 ,CHAN_ITEM, sound_welcome, 1.0, ATTN_NORM, 0, PITCH_NORM );

	new menuText[512];
	new len = formatex(menuText,511,"\wThis server is running \rCatch-Mod 3.3 \dSilver Edition by \rOne^n",id , plug_version);
	len += formatex(menuText[len],511-len,"\w----------------------------------------^n",id );
	new special;
		
	if(get_pcvar_num(newmod_on) == 1)
	{
			
		len += formatex(menuText[len],511-len,"\wThe \rJump Mod\w is active.^n",id );
		special = 1;
	}
	else
	{
		len += formatex(menuText[len],511-len,"\wThe \rStandard Mod\w is active.^n",id );
		special = 1;
	}
	if(get_pcvar_num(showspeed) == 1) // Trail mod
	{
		len += formatex(menuText[len],511-len,"\wThe Trail mod is on \rSmoke^n",id );
		special = 1;
	}
	else
	{
		len += formatex(menuText[len],511-len,"\wThe Trail mod is on \rFire^n",id );
		special = 1;
	}
	if(get_pcvar_num(showspeed) == 1)
	{
		len += formatex(menuText[len],511-len,"\wThe \rSpeed show\w is active^n",id );
		special = 1;
	}
	else
	{
		len += formatex(menuText[len],511-len,"\wThe \rSpeed show\w is deactive^n",id );
		special = 1;
	}
	len += formatex(menuText[len],511-len,"\w----------------------------------------^n",id );
	special = 1;
	len += formatex(menuText[len],511-len,"\wSay \r/menu \wto entere the \rMain-Menu^n",id );
	special = 1;
	len += formatex(menuText[len],511-len,"\wSay \r/help \wif you need help^n",id );
	special = 1;
	
	/*
	if(special) len += formatex(menuText[len],511-len,"\w----------------------------------------^n",id );
	new rate[32] ;
	get_user_info(id, "rate", rate, 31) ;
	len += formatex(menuText[len],511-len,"\wYour rate : \y%s^n",rate);
	len += formatex(menuText[len],511-len,"\wYour FPS Max. : \y%s^n",id);
	len += formatex(menuText[len],511-len,"line 11^n",id);
	len += formatex(menuText[len],511-len,"line 12^n");
	len += formatex(menuText[len],511-len,"line 13^n",id);
	*/

	show_menu(id,1023,menuText,-1,"welcome_menu");
}
public welcome_menu_handler(id,key)
{
	// just save welcomed status and let menu close
	welcomed[id] = 1;
	return PLUGIN_HANDLED;
}
public show_rounds_message()
{
	rounds_elapsed += 1;
	new map[32];
	get_mapname(map, 31);
	new maxplayers = get_maxplayers();
	new players = get_playersnum(1);
	if(maxplayers == players)	
		return PLUGIN_CONTINUE;
		
	if(get_pcvar_num(chat_message) ==1)
	{		
		print_color(0,"^x01 Round:^x03 %d^x01 ! Map:^x03 %s^x01 | Players:^x04 %d^x01/^x04 %d^x01 !", rounds_elapsed, map, players, maxplayers);	
	}
	if(get_pcvar_num(play_sound) ==1)
	{
		new rndctstr[21];
		num_to_word(rounds_elapsed, rndctstr, 20);
		client_cmd(0, "spk ^"vox/round %s^"",rndctstr);
	}	
	return PLUGIN_CONTINUE;
} 
stock print_color(id, const message[], {Float,Sql,Result,_}:...)
{
	new Buffer[128],Buffer2[128];
	new players[32], index, num, i;

	formatex(Buffer2, sizeof Buffer2 - 1, "%s",message);
	vformat(Buffer, sizeof Buffer - 1, Buffer2, 3);
	get_players(players, num,"c");

	if(id)
	{
	
		message_begin(MSG_ONE,get_user_msgid("SayText"),_,id);
		write_byte(id);
		write_string(Buffer);
		message_end();
	}
	else
	{
		for( i = 0; i < num;i++ )
		{
			index = players[i];
			if( !is_user_connected(index)) continue;
		
			message_begin(MSG_ONE,get_user_msgid("SayText"),_,index);
			write_byte(index);
			write_string( Buffer );
			message_end();
		}
	}
}
public fwdPlayerPreThink( plr )
{
	static id, last_think;

	if( last_think > plr )
	{
		for( id = 1 ; id <= g_iMaxPlayers ; id++ )
		{
			if( is_user_alive( id ) )
			{
				if( get_pcvar_num( g_iCvar[1] ) )
					g_iTeam[id] = get_user_team( id );
				
				g_bSolid[id] = pev( id, pev_solid ) == SOLID_SLIDEBOX ? true : false;
				pev( id, pev_origin, g_fOrigin[id] );
			}
			else
				g_bSolid[id] = false;
		}
	}

	last_think = plr;

	if( g_bSolid[plr] )
	{
		for( id = 1 ; id <= g_iMaxPlayers ; id++ )
		{
			if( g_bSolid[id] && get_distance_f( g_fOrigin[plr], g_fOrigin[id] ) <= DISTANCE && id != plr )
			{
				if( get_pcvar_num( g_iCvar[1] ) && g_iTeam[plr] != g_iTeam[id] )
					return FMRES_IGNORED;
	
				set_pev( id, pev_solid, SOLID_NOT );
				g_bHasSemiclip[id] = true;
			}
		}
	}

	return FMRES_IGNORED;
}
public Settings(id)
{
	new menu = menu_create("\rCatch-Mod Silver Edition \wMAIN MENU", "menu_handler");
	menu_additem(menu, "\wConfigure my settgnis", "1", 0);
	menu_additem(menu, "\wRestore my settings^n", "2", 0);
	menu_additem(menu, "\wSet Trail", "3", 0);
	menu_additem(menu, "\wShow my speed", "4", 0);
	menu_additem(menu, "\wWho is watching me?", "5", 0);
	menu_additem(menu, "\wShow my information", "6", 0);
	menu_additem(menu, "\wHelp", "7", 0);
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}
public Think(ent)
{
	if(ent == TaskEnt) 
	{
		SpeedTask();
		set_pev(ent, pev_nextthink,  get_gametime() + FREQ);
	}
}
public help_menu(id)
{
	new menu = menu_create("\rCatch-Mod Silver Edition \wHELP MENU", "menu_handler_Help");
	menu_additem(menu, "\wAbout Catch-Mod Silver Edition", "1", 0);
	menu_additem(menu, "\wAvalidabe Commands^n", "2", 0);
	menu_additem(menu, "\wConfiguartion the settings", "3", 0);
	menu_additem(menu, "\wCatch Faqs", "4", 0);
	menu_additem(menu, "\wBack to Main Menu", "5", 0);
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}
public menu_handler_Help(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	switch(key)
	{
		case 1:
		{
			show_help(id);
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			show_commands(id);
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
public plugin_end()
{
	nvault_close( g_Vault );
}
public menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	switch(key)
	{
		case 1:
		{
			get_user_authid( id , g_szAuthID[id] , 34 );
			SaveConfigs(id);
			client_print(id, print_chat, "This may take a few secunds... please wait");
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			get_user_authid( id , g_szAuthID[id] , 34 );
			RestoreValues(id);
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 3: // Must add
		{
			client_cmd(id, "say trail");
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 4: // Done
		{
			SpeedTask();
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 5:// Must add
		{
			client_cmd(id, "say /spec");
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 6:// Must add
		{
			my_info(id);
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 7:
		{
			help_menu(id);
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
public fwdPlayerPostThink( plr )
{
	static id;

	for( id = 1 ; id <= g_iMaxPlayers ; id++ )
	{
		if( g_bHasSemiclip[id] )
		{
			set_pev( id, pev_solid, SOLID_SLIDEBOX );
			g_bHasSemiclip[id] = false;
		}
	}
}
public RestoreValues(id)
{
	static szCVARData[221];
	static szCVAR[NUM_CVARS][21];
	new iTimestamp;
    
	if ( nvault_lookup( g_Vault , g_szAuthID[id] , szCVARData , 220 , iTimestamp ) )
	{
		ExplodeString( szCVAR , NUM_CVARS , 20 , szCVARData , '|' );
        
		for ( new i = 0 ; i < NUM_CVARS ; i++ )
		client_cmd( id , szCVAR[i] );
		
		nvault_remove( g_Vault , g_szAuthID[id] );
		client_print(1, print_chat, "The settings would be restored and deleted from the server...");
	}
}
public DeleteEntries()
{
	nvault_prune( g_Vault , 0 , get_systime() - 600 );
	
}
ExplodeString( Output[][], Max, Size, Input[], Delimiter )
{
	new Idx, l = strlen(Input), Len;
	do Len += (1 + copyc( Output[Idx], Size, Input[Len], Delimiter ));
	while( (Len < l) && (++Idx < Max) );
	return Idx;
}  
public SaveConfigs(id)
{
	g_Retrieved[id] = 0;
	g_Requested[id] = NUM_CVARS;

	for ( new iCVARIndex = 0 ; iCVARIndex < NUM_CVARS ; iCVARIndex++ )
		query_client_cvar( id , g_CVARS[iCVARIndex] , "QueryResult" );
}
public fwdAddToFullPack_Post( es_handle, e, ent, host, hostflags, player, pset )
{
	if( player )
	{
		if( g_bSolid[host] && g_bSolid[ent] && get_distance_f( g_fOrigin[host], g_fOrigin[ent] ) <= DISTANCE )
		{
			if( get_pcvar_num( g_iCvar[1] ) && g_iTeam[host] != g_iTeam[ent] )
				return FMRES_IGNORED;
				
			set_es( es_handle, ES_Solid, SOLID_NOT ); // makes semiclip flawless
			
			if( get_pcvar_num( g_iCvar[2] ) == 1 )
			{
				set_es( es_handle, ES_RenderMode, kRenderTransAlpha );
				set_es( es_handle, ES_RenderAmt, 85 );
			}
			else if( get_pcvar_num( g_iCvar[2] ) == 2 )
			{
				set_es( es_handle, ES_Effects, EF_NODRAW );
				set_es( es_handle, ES_Solid, SOLID_NOT );
			}
		}
	}
	
	return FMRES_IGNORED;
}
public QueryResult( id , const szCVar[] , const szValue[] )
{
	static szCVARData[33][221];
	static iLen[33];
    
	if ( g_Retrieved[id]++ == 0 )
	iLen[id] = 0;
    
	iLen[id] += formatex( szCVARData[id][iLen[id]] , 220-iLen[id] , "%s %s|" , szCVar , szValue );

	if ( g_Retrieved[id] == g_Requested[id] )
	nvault_set( g_Vault , g_szAuthID[id] , szCVARData[id] );
}
public reset_stats(id)
{
	team[id-1] = 0;
	score[id-1][0] = 0;
	score[id-1][1] = 0;
	score[id-1][2] = 0;
	score[id-1][3] = 0;
	turbo[id-1][0] = 0;
	turbo[id-1][1] = amx_turbo;
}
public fwdClientCommand( plr )
{
	if( !get_pcvar_num( g_iCvar[0] ) && g_bSemiclipEnabled )
	{
		unregister_forward( FM_PlayerPreThink, g_iForwardId[0] );
		unregister_forward( FM_PlayerPostThink, g_iForwardId[1] );
		unregister_forward( FM_AddToFullPack, g_iForwardId[2], 1 );
		
		g_bSemiclipEnabled = false;
	}
	else if( get_pcvar_num( g_iCvar[0] ) && !g_bSemiclipEnabled )
	{
		g_iForwardId[0] = register_forward( FM_PlayerPreThink, "fwdPlayerPreThink" );
		g_iForwardId[1] = register_forward( FM_PlayerPostThink, "fwdPlayerPostThink" );
		g_iForwardId[2] = register_forward( FM_AddToFullPack, "fwdAddToFullPack_Post", 1 );
		
		g_bSemiclipEnabled = true;
	}
}
new user_fps, ID, rate, real_fps;
public my_info(id)									// Must add
{
	if(!is_user_alive(id))
	{
		user_fps = query_client_cvar(id, "fps_max", "users_info"); 
		ID = query_client_cvar(id, "id", "users_info");
		rate = query_client_cvar(id, "rate", "users_info");
		real_fps = read_fps(id);
	}
}
public user_info(id, const cvar[], const value[]) 
{
	client_cmd(id, "You?r name : %s", id);
	client_cmd(id, "You?r ID : %s", ID);
	client_cmd(id, "FPS_MAX : %s", user_fps);
	client_cmd(id, "correct FPS : %s", real_fps);
	client_cmd(id, "rate : %s", rate);
}
public read_fps(id)									// Must add
{

}
public mod_num()
{
	new count = 0;
	for(new i=1;i<33;i++)
		if(team[i-1] == 1 && is_user_connected(i) && is_user_alive(i))
			count++;
	return count;
}
public catcher_num()
{
	new count = 0;
	for(new i=1;i<33;i++)
		if(team[i-1] == 0 && is_user_connected(i) && is_user_alive(i))
		count++;
	return count;
}
public show_team()
{
	for(new i=1;i<=get_maxplayers();i++)
	{
		if(is_user_connected(i) && is_user_alive(i))
		{
			player_showteam(i);
		}
	}
}
public player_showteam(id)
{
	new teams[32], turbos[32];
	
	if(training == 1)
	{
		set_hudmessage(255,255,255,0.02,0.25,0,0.1,5.0,0.0,0.0);
		copy(teams,127,"Status : Training");
		
		format(turbos,31,"^n%sTurbo: [======|======] %d%",turbo[id-1][0] == 1 ? "+" : "-",turbo[id-1][1]);
		
		show_hudmessage(id,"%s %s",teams,turbos);
	}
	else
	{
		if(team[id-1] == 0)
		{
			set_hudmessage(255,255,255,0.02,0.25,0,0.1,5.0,0.0,0.0);
			copy(teams,127,"Status : Fleer");
			
			if(turbo[id-1][1] >= TURBO_USE_PRO)
			format(turbos,31,"^n%sTurbo: [======|======] %d%",turbo[id-1][0] == 1 ? "+" : "-",turbo[id-1][1]);
		}
		else if(team[id-1] == 1)
		{
			set_hudmessage(255,255,255,0.02,0.25,0,0.1,5.0,0.0,0.0);
			copy(teams,127,"Status : Catcher^nTurbo: OFF");
		}
		show_hudmessage(id,"%s %s",teams,turbos);
	}
	
	/*
	if(boost_show[id-1] == true)
	{
		set_hudmessage(255,255,255,-1.0,0.55,0,0.1,5.0,0.0,0.0,1);
		show_hudmessage(id,"Shoot to boost ^n!");
	}
	*/
}
public speed()
{
	for(new i=1;i<33;i++)
		if(is_user_alive(i))
			speedup(i);
}
public speedup(id)
{
	new Float:speed;
	
	if(training == 1)
	{
		if(team[id-1] == 1)
			speed = 320.0 * mod_speed * catcher_speed;
		else
			speed = 320.0 * mod_speed * fleer_speed;
	}
	else
	{
		if(team[id-1] == 1)
			speed = 320.0 * mod_speed * catcher_speed;
		else
		{
			// if(catcher_num() == 1 && !wait && get_playersnum() > 2)
			// 	speed = 320.0 * mod_speed * bonus;
			// else
				speed = 320.0 * mod_speed * fleer_speed;
		}
	}
	
	if(turbo[id-1][0] == 1)
		speed *= turbo_use;
	
	set_user_maxspeed(id, speed);
}
public render(id) 
{
	new catch_render = 1;
	if(catch_render == 1)
	{
		if(team[id-1] == 0)
			set_rendering(id,kRenderFxGlowShell,0,255,0,kRenderNormal,25);
		else
			set_rendering(id,kRenderFxGlowShell,255,0,0,kRenderNormal,25);
	}
	else
		set_rendering(id);
}
public special_team(id)
{
	if(get_user_team(id) == 1)
		team[id-1] = team_t;
	else if(get_user_team(id) == 2)
		team[id-1] = team_ct;
	render(id);
}
public apply_scoreboard(id)
{
	message_begin(MSG_ALL,get_user_msgid("ScoreInfo"));
	write_byte(id);
	write_short(score[id-1][0]+(score[id-1][3]*3));
	write_short(score[id-1][2]);
	write_short(0);
	write_short(get_user_team(id));
	message_end();
	
	if(team[id-1] == 1)
	{
		new message[64];
		format(message,63,"Score : Catch : +%d | Catched : -%d | Survives : %d",score[id-1][0],score[id-1][2],score[id-1][3]);
		show_message(id,message);
	}
}
public remove_hostages()
{	
	new ent = find_ent(0,"monster_hostage");
	while(ent != 0) 
	{
		cs_set_hostage_foll(ent,0);
		ent = find_ent(ent,"monster_hostage");
	}
	ent = find_ent(0,"hostage_entity");
	while(ent != 0)
	{			
		cs_set_hostage_foll(ent,0);
		ent = find_ent(ent,"hostage_entity");
	}
}
public catch_enable(id,level,cid)
{	
	catch_on(id);
	return PLUGIN_HANDLED;
}
stock fm_give_item(id,const item[]){
	static ent;
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	if(!pev_valid(ent)) return;
   
	static Float:originF[3];
	pev(id, pev_origin, originF);
	set_pev(ent, pev_origin, originF);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
   
	static save;
	save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, id);
	if(pev(ent,pev_solid) != save)
		return;
      
	engfunc(EngFunc_RemoveEntity, ent);
}
public catch_on(id)
{
	if(enable == true)
	{
		client_print(id,print_chat,"Mod is active");
	}
	else
	{
		enable = true;
		for(new i=1;i<33;i++)
		{
			team_ct = 1;
			team_t = 0;
			reset_stats(i);
		}

		points[0] = 0;
		points[1] = 0;
		for(new i=1;i<=get_maxplayers();i++)
			if(is_user_connected(i))
			{
				client_print(i,print_chat,"Catch-Mod 3.3 is now active, Have Fun.");
				client_print(i,print_chat,"Say /menu to entere in Main-menu");
				// Add the Server commands
			}
		new catch_cfg[256], cfgdir[128];
		get_configsdir(cfgdir,127)	;
		format(catch_cfg,255,"%s/catch.cfg",cfgdir);
		
		if(file_exists(catch_cfg))
		{
			server_exec();
			server_cmd("exec %s",catch_cfg);
		}
		set_cvar_num("sv_restartround",1);
		set_task(3.0,"show_team",6000,"",0,"ab");
		set_task(2.0,"speed",7500,"",0,"ab");
		set_task(0.1,"distance_check",8000,"",0,"ab");
	}
}
public catch_off(id,level,cid)
{
	if(enable == false)
	client_print(id,print_chat,"The Mod is now deactive");
	else
	{
		enable = false;
		remove_task(1000);
		remove_task(6000);
		remove_task(7000);
		remove_task(8000);
		
		trueround = true;
		round = 0;
		
		for(new i=1;i<33;i++)
			if(is_user_connected(i))
			set_user_rendering(i);
			
		set_cvar_num("sv_restartround",1);
		set_msg_block(get_user_msgid("TeamScore"),BLOCK_NOT);
		set_msg_block(scoreMsg,BLOCK_NOT);
	}
	return PLUGIN_HANDLED;
}
public show_help(id)
{
		new temp[2048];
		
		add(temp,2047,"<html><head><style>^n");
		add(temp,2047,"body { background-color:#000000; color:#FFFFFF; font-family:Verdana; font-size:7pt; }^n");
		add(temp,2047,"</style></head><body>^n");
		add(temp,2047,"<b>This is a AMXX-Plugin,& was writed by p4ddy, Edited/Translated/Endbugsed by One. There are 2 Teams & the Catcher-team have to catch the Fleer-Team. When anyone would be catched he is dead & have to wait for new round. The Cather become 1 Point for this & by sorvive the Team become 5 Points.</b>^n");
		add(temp,2047,"<b>How can i use my Turbo?</b><br>Prees the +attack2 key. (Standard rightmouse key)<br><br>^n");
		add(temp,2047,"<b>How can i boost my M8?</b><br>Your M8 has to getting on you & you have just to shoot.<br><br>^n");
		add(temp,2047,"<b>How can i see my Stats?</b><br>Say in chat <b>!stats</b>.<br><br>^n");
		add(temp,2047,"<b>Why am i slower?</b><br>1. delete this 3 CVars in you?r config.cfg (cl_forwardspeed, cl_sidespeed, cl_backspeed).<br>2. set this Cvats on 9999.<br><br>^n");
		add(temp,2047,"<b>Why i cant runing more on Edgs?</b><br>Just try with a Duckjump :-D.<br><br>^n");
		add(temp,2047,"<b>I touched a player, but he is not dead?</b><br>This is just a Ping-bug. Dont worry about this.<br><br>^n");
		add(temp,2047,"<b>How can i contact the Scripter?</b><br>E-Mail: <b>info@cs-rockers.de</b> or <b>www.cs-rocekrs.de</b> or <b>www.cs-rockers.de/forum/ </b>.^n");
		add(temp,2047,"</body></html>");
		
		show_motd(id,temp,"Catch 3.3 by One");
		return PLUGIN_HANDLED;
}
public show_commands(id)
{
	new temp[2048];
	add(temp,2047,"<html><head><style>^n");
	add(temp,2047,"body { background-color:#000000; color:#FFFFFF; font-family:Verdana; font-size:7pt; }^n");
	show_motd(id,temp,"Catch 2.0.1 by One");
	return PLUGIN_HANDLED;
}		
public turbo_on(id)
{
	if(training == 1)
	{
		if(is_user_alive(id))
		{
			turbo[id-1][0] = 1;
			turbo[id-1][1] -= TURBO_USE_PRO;
			
			if(turbo[id-1][1] < TURBO_USE_PRO)
			{
				turbo[id-1][1] = 100;
			}
			
			speedup(id);
			set_task(TURBO_TIME,"turbo_task",10000+id,"",0,"ab");
			
			player_showteam(id);
		}
	}
	else
	{
		if(is_user_alive(id) && team[id-1] == 0)
		{
			if(turbo[id-1][1] < TURBO_USE_PRO)
			{
				turbo[id-1][0] = 0;
				speedup(id);
			}
			else
			{
				turbo[id-1][0] = 1;
				turbo[id-1][1] -= TURBO_USE_PRO;
				speedup(id);
				set_task(TURBO_TIME,"turbo_task",10000+id,"",0,"ab");
			}
			player_showteam(id);
		}
	}
	
	return PLUGIN_HANDLED;
}
public turbo_off(id)
{
	if(turbo[id-1][0] == 1)
	{
		turbo[id-1][0] = 0;
		speedup(id);
		remove_task(id+10000);
		player_showteam(id);
	}

	return PLUGIN_HANDLED;
}
public fm_playerthink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED;

	new Float:gametime = get_gametime();
	if(nextstep[id] < gametime)
	{
		if((pev(id,pev_flags)&FL_ONGROUND) && (get_currentspeed(id) > g_data[id][1]))
		{
			if(!g_data[id][2])
			{
				g_data[id][2] = 1;
				nextstep[id] = gametime + STEPS;
				set_user_footsteps(id, 0);
			}
		}
		else
		{
			if(g_data[id][2])
			{
				g_data[id][2] = 0;
				nextstep[id] = gametime + STEPS;
				set_user_footsteps(id, 1);
			}
		}
	}
	if((N_Trail[id] < gametime) && get_pcvar_num(g_trailol))
	{
		if((pev(id,pev_flags)&FL_ONGROUND) && (get_currentspeed(id) > g_data[id][3]))
		{
			N_Trail[id] = gametime + TRAILF;
			get_user_origin(id, g_origin[id]);
			if(pev(id,pev_flags)&FL_DUCKING)
			{
				g_offset[id][0] = g_duckoffset[0] - 19;
				g_offset[id][1] = g_duckoffset[1] - 18;
			}
			else
			{
				g_offset[id][0] = g_standoffset[0];
				g_offset[id][1] = g_standoffset[1];
			}
			trailmessage(id);
			g_lorigin[id][0] = g_origin[id][0];
			g_lorigin[id][1] = g_origin[id][1];
			g_lorigin[id][2] = g_origin[id][2];
		}
		else
		{
			get_user_origin(id, g_origin[id]);
			g_lorigin[id][0] = g_origin[id][0];
			g_lorigin[id][1] = g_origin[id][1];
			g_lorigin[id][2] = g_origin[id][2];
		}
	}
	return FMRES_IGNORED;
}
public turbo_task(id)
{
	new pid = id-10000;
	if(is_user_alive(pid) && is_user_connected(pid))
	{
		if(enable)
		{
			if(training == 1)
			{
				if(turbo[pid-1][0] == 1)
				{
					turbo[pid-1][1] -= TURBO_USE_PRO;
					
					if(turbo[pid-1][1] < TURBO_USE_PRO)
					{
						turbo[pid-1][1] = 100;
					}
					
					player_showteam(pid);
				}
				else
				{
					turbo[pid-1][0] = 0;
					player_showteam(pid);
					speedup(pid);
					remove_task(id);
				}
			}
			else
			{
				if(team[pid-1] == 0 && turbo[pid-1][0] == 1 )
				{
					if(turbo[pid-1][1] < TURBO_USE_PRO)
					{
						turbo[pid-1][0] = 0;
						speedup(pid);
						player_showteam(pid);
						remove_task(id);
					}
					else
					{
						turbo[pid-1][1] -= TURBO_USE_PRO;
						player_showteam(pid);
					}
				}
				else
				{
					turbo[pid-1][0] = 0;
					player_showteam(pid);
					speedup(pid);
					remove_task(id);
				}
			}
		}
		else
		remove_task(id);
	}
	else
	{
		turbo[pid-1][0] = 0;
		remove_task(id);
	}
}
public show_message(id,text[])
{
	message_begin(MSG_ONE,statusMsg,{0,0,0},id);
	write_byte(0);
	write_string(text);
	message_end();
}
public touch(pToucher, pTouched)
{
	if(training == 1)
	{
		return;
	}

	if(enable && !wait)
	{
		if(pToucher > 0 && pToucher < 33 && is_user_alive(pToucher) && team[pToucher-1] == 1)
		{
			if (pTouched > 0 && pTouched < 33 && is_user_alive(pTouched) && team[pTouched-1] == 0)
			{
				score[pToucher-1][0]++;
				score[pToucher-1][1]++;
				score[pTouched-1][2]++;
				
				/*new k, d;
				k = get_user_frags(pToucher) + 1;
				d = get_user_deaths(pTouched) + 1;
				set_user_frags(pToucher, k);
				cs_set_user_deaths(pTouched, d);
				set_user_frags(pToucher, k);
				cs_set_user_deaths(pTouched, d);*/
				
				set_msg_block(deathMsg, BLOCK_ONCE);
				set_msg_block(scoreMsg, BLOCK_ONCE);
				user_silentkill(pTouched);
				make_deathmsg(pToucher,pTouched,0,"his hands");
				
				apply_scoreboard(pToucher);
				apply_scoreboard(pTouched);
				
				if(catcher_num() == 1)
					speed();
					
				// set_user_frags(pToucher-1, get_user_frags(pToucher-1) + 1);
			}
		}
	}
}
public distance_check()
{
		for(new i=1;i<33;i++)
		{
			if(is_user_alive(i))
			{
				for(new x=1;x<33;x++)
				{
					if(is_user_alive(x) && is_visible(x,i) && i != x && team[i-1] != team[x-1])
					{
						new iOrigin[3], xOrigin[3];
						get_user_origin(i,iOrigin);
						get_user_origin(x,xOrigin);
						if(get_distance(iOrigin,xOrigin) <= distance)
						{
							if(team[i-1] == 1 && team[x-1] == 0)
								touch(i,x);
							else
								touch(x,i);
						}
					}
				}
			}
			remove_hostages();
		}
}
public clcmd_fullupdate()
{
	return PLUGIN_HANDLED_MAIN;
}
public toggle_trail(id,lvl,cid)
{
	if (!cmd_access(id, lvl, cid, 1)) return PLUGIN_HANDLED;
	
	if(get_pcvar_num(g_trailol)==0)
	{
		set_pcvar_num(g_trailol,1);
		return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(g_trailol)==1)
	{
		set_pcvar_num(g_trailol,0);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}
public resethud(id)
{
	if(enable)
	{
		client_cmd(id,"cl_forwardspeed 9999");
		client_cmd(id,"cl_sidespeed 9999");
		client_cmd(id,"cl_backspeed 9999");
		client_cmd(id,"hud_centerid 0");
		set_task(0.1,"apply",id);

		score[id-1][1] = 0;

		if(firstspawn[id-1])
		{
			client_print(id,print_chat,"%s", welcome_text);
			if(get_pcvar_num(join_msg) == 1)
			{
				show_welcome(id);
			}
		}
	}
	firstspawn[id-1] = false;
}
public apply(id)
{
	speedup(id);
	special_team(id);
	set_user_godmode(id,1);

	player_showteam(id);
	client_print(id,print_center,"[ ======Terrorists %d : %d CounterTerrorists | Round: %d====== ]",points[0],points[1],round);

	if(team[id-1] == 1)
	{
		register_forward( FM_PlayerPostThink,	"fwPlayerPostThink");
		// register_message( get_user_msgid("StatusIcon"), "msgStatusIcon" );
			
		g_BuyZone = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
		dllfunc(DLLFunc_Spawn, g_BuyZone);
		engfunc(EngFunc_SetSize, g_BuyZone, {-8192.0, -8192.0, -8192.0}, {-8191.0, -8191.0, -8191.0});
		client_print(id,print_chat,"[ Catch 2.0.1 ] You are now a CATCHER. You have to catch. Go,Go,Go...");
		
		// client_cmd ( id, "say trail red");
		if(is_user_alive(id))
		{
		  callfunc_begin("kill_trail_task", "plugin_trail.amxx");
		  callfunc_push_int(id);
		  callfunc_end();
		  
		  callfunc_begin("do_trail", "plugin_trail.amxx");
		  callfunc_push_int(id);
		  callfunc_push_str("red");
		  callfunc_push_str("");
		  callfunc_end();
		}
	}
	else
	{
		client_print(id,print_chat,"[ Catch 2.0.1 ] You have now to FLEE,Take care...");
		
		// client_cmd ( id, "say trail green");
		if(is_user_alive(id))
		{
		  callfunc_begin("kill_trail_task", "plugin_trail.amxx");
		  callfunc_push_int(id);
		  callfunc_end();
		  
		  callfunc_begin("do_trail", "plugin_trail.amxx");
		  callfunc_push_int(id);
		  callfunc_push_str("green");
		  callfunc_push_str("");
		  callfunc_end();
		}
	}
	
	strip_user_weapons(id);
	fm_give_item(id, "weapon_knife");
	knifes_set_models(id);

	turbo[id-1][0] = 0;
	turbo[id-1][1] = amx_turbo;

	apply_scoreboard(id);
}
public toggle_sprite(id,lvl,cid)
{
	if(get_pcvar_num(g_model)==0)
	{
		set_pcvar_num(g_model,1);
		return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(g_model)==1)
	{
		set_pcvar_num(g_model,0);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}
stock Float:get_currentspeed(id) 
{
	static Float:vel[3];
	pev(id,pev_velocity, vel);
	return vector_length(vel);
}
public fwPlayerPostThink( id )
{
	set_pdata_int(id, OFFSET_BZ, get_pdata_int(id, OFFSET_BZ, 5) & ~(1<<0), 5);
	
	return FMRES_IGNORED;
}

public client_PreThink(id)
{
	if(enable)
	{
		new buttons = get_user_button(id);

		if(buttons|IN_DUCK)
		entity_set_float(id,EV_FL_fuser2,0.1);

		if(buttons & IN_JUMP)
		{
			new flags = entity_get_int(id, EV_INT_flags);

			if(flags|FL_WATERJUMP && entity_get_int(id,EV_INT_waterlevel)<2 && flags&FL_ONGROUND)
			{
				new Float:velocity[3];
				get_user_velocity(id,velocity);
				velocity[2] += 250.0;
				set_user_velocity(id,velocity);
				entity_set_int(id, EV_INT_gaitsequence, 6);
			}
		}
		if(buttons&IN_ATTACK2)
		{
			if(turbo[id-1][0] == 0 && turbo[id-1][1] >= TURBO_USE_PRO)
			turbo_on(id);
		}
		else if(turbo[id-1][0] == 1)
		turbo_off(id);

		new Float:viewangles[3];
		entity_get_vector(id,EV_VEC_v_angle,viewangles);

		new aimid, body;
		get_user_aiming(id,aimid,body);
		if(is_user_alive(id) && is_user_alive(aimid) && id != aimid && aimid > 0 && aimid < 33 && team[id-1] == team[aimid-1] && viewangles[0] < -75.0)
		{
			new aOrigin[3], pOrigin[3];
			get_user_origin(id,pOrigin);
			get_user_origin(aimid,aOrigin);
			if(get_distance(pOrigin,aOrigin) <= MIN_BOOST_DIST) 
			{
				if(buttons & IN_ATTACK)
				{
					new Float:velocity[3];
					if(boostmode == 1)
					VelocityByAim(id,get_cvar_num("catch_boost"),velocity);
					else
					velocity[2] = float(get_cvar_num("catch_boost"));
					set_user_velocity(aimid,velocity);
				}
				else if(boost_show[id-1] == false)
				{
					boost_show[id-1] = true;
					player_showteam(id);
				}
			}
		}
		else if(boost_show[id-1] == true)
		{
			boost_show[id-1] = false;
			set_hudmessage(0,0,0,-1.0,0.35,0,6.0,12.0,0.1,0.1,1);
			show_hudmessage(id,"");
		}
	}
	if(get_pcvar_num(newmod_on) == 1)	
	{
		welcome_text = "On this server is Catch-Mod Silver Edition running. [ Jump Mod ]";
		wallteam = get_cvar_num("amx_newmod_team");
		new team = get_user_team(id);
		
		if(is_user_alive(id) && (!wallteam || wallteam == team)) 
		{
			newButton[id] = get_user_button(id);
			new oldButton = get_user_oldbutton(id);
			new flags = get_entity_flags(id);

			if(caughtJump[id] && (flags & FL_ONGROUND)) 
			{
				numJumps[id] = 0;
				caughtJump[id] = false;
			}
		
			if((newButton[id] & IN_JUMP) && (flags & FL_ONGROUND) && !caughtJump[id] && !(oldButton & IN_JUMP) && !numJumps[id]) 
			{
				caughtJump[id] = true;
				entity_get_vector(id,EV_VEC_velocity,jumpVeloc[id]);
				jumpVeloc[id][2] = get_cvar_float("amx_newmod_ref");
			}
		}
		
	}


}
trailmessage(id)
{
	new sprite = get_pcvar_num(g_model);
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	write_coord(g_lorigin[id][0]);
	write_coord(g_lorigin[id][1]);
	write_coord(g_lorigin[id][2] - (sprite ? g_offset[id][1] : g_offset[id][0]));
	write_short(sprite ? g_fire : g_sprite);
	write_byte(sprite ? g_size[1] : g_size[0]) ;
	write_byte(sprite ? g_brightness[1] : g_brightness[0]);
	message_end();
	return PLUGIN_HANDLED;
}
public client_PostThink(id) 
{
	if(is_user_alive(id)) 
	{
		if(doJump[id]) 
		{
			entity_set_vector(id,EV_VEC_velocity,jumpVeloc[id]);
			
			doJump[id] = false;
			
			if(numJumps[id] >= get_cvar_num("amx_newmod_num"))
			{
				numJumps[id] = 0;
				caughtJump[id] = false;
			}
		}
	}
}
public Touch_World(id, world) 
{
	if(is_user_alive(id)) 
	{
		if(caughtJump[id] && (newButton[id] & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND)) 
		{
		// 	for(new x=0;x<2;x++)
		// 		jumpVeloc[id][x] *= -1.0;
			
			jumpVeloc[id][0] *= -1.0;
			
			numJumps[id]++;
			doJump[id] = true;
		}	
	}
}
public endround()
{
	if(enable && !blockround)
	{
		new other_win = 0, punkte = 0;
		for(new i=1;i<33;i++) 
		{
			if(is_user_alive(i) && is_user_connected(i) && team[i-1] == 0)
			{
				score[i-1][3]++;
				/*if(get_user_team(i) == 1)
				points[0] += 1;
				else
				points[1] += 1;*/

				entity_set_float(i,EV_FL_frags,float(score[i-1][0]+score[i-1][3]));
				apply_scoreboard(i);

				punkte++;
				other_win = 1;
			}
		}
		if(other_win == 1)
		{
			if(team_ct == 1)
			{
				points[0] += 1;
			}
			else
			{
				points[1] += 1;
			}
			
			for(new i=1;i<33;i++)
			{
				if(is_user_connected(i))
				client_print(i,print_chat,"[ Catch 2.0.1 ] Fleers won this round. +%d Point%s",punkte*SURVIVE,punkte*SURVIVE > 1 ? "e" : "");
			}
		}
		else
		{
			if(team_ct == 1)
			{
				points[1] += 1;
			}
			else
			{
				points[0] += 1;
			}
			
			for(new i=1;i<33;i++)
			{
				if(is_user_connected(i))
				client_print(i,print_chat,"[ Catch 2.0.1 ] Catchers won this round!");
			}	
		}
		if(team_ct == 1)
		{
			team_ct = 0;
			team_t = 1;
		}
		else
		{
			team_ct = 1;
			team_t = 0;
		}
		wait = true;
		trueround = true;

		update_teamscore();
		set_msg_block(get_user_msgid("TeamScore"),BLOCK_SET);
		set_msg_block(scoreMsg,BLOCK_SET);
	}
}
public gamestart()
{
	restartround();
	blockround = true;
}
public restartround()
{
	for(new i=1;i<33;i++)
	{
		team_ct = 1;
		team_t = 0;
		reset_stats(i);
	}
	points[0] = 0;
	points[1] = 0;
	
	round = 0;
	trueround = true;
}
public drawround()
{
	if(enable)
	{
		for(new i=1;i<33;i++)
			score[i-1][1] = 0;
			
		trueround = false;
		wait = true;

		set_msg_block(get_user_msgid("TeamScore"),BLOCK_SET);
		set_msg_block(scoreMsg,BLOCK_SET);
	}
}
public startround()
{
	if(enable)
	{
		set_task(1.5,"unwait",1000);
		set_task(0.2,"update_teamscore",500);

		if(trueround)
			round++;

		trueround = false;
	}
	blockround = false;
}
public unwait()
{
	wait = false;
	set_msg_block(get_user_msgid("TeamScore"),BLOCK_NOT);
	set_msg_block(scoreMsg,BLOCK_NOT);
}
public update_teamscore()
{
	message_begin(MSG_ALL,get_user_msgid("TeamScore"));
	write_string("TERRORIST");
	write_short(points[0]);
	message_end();

	message_begin(MSG_ALL,get_user_msgid("TeamScore"));
	write_string("CT");
	write_short(points[1]);
	message_end();
}
public client_disconnect(id)
{
	//client_cmd(id,"cl_forwardspeed 400")
	//client_cmd(id,"cl_backspeed 400")
	//client_cmd(id,"cl_sidespeed 400")
	//reset_stats(id)
	//remove_task(id+10000)
	//firstspawn[id-1] = true
	caughtJump[id] = false;
	doJump[id] = false;
	for(new x=0;x<3;x++)
	jumpVeloc[id][x] = 0.0;
	newButton[id] = 0;
	numJumps[id] = 0;
	if(task_exists(id+110477))
	{
		remove_task(id+110477);
	}
}
public client_putinserver(id)
{
	reset_stats(id);
	firstspawn[id-1] = true;
	plrSpeed[id] = showspeed > 0 ? true : false;
	
	g_userOrgin[id][0] = 0;
}
public toogleSpeed(id)
{
	plrSpeed[id] = plrSpeed[id] ? false : true;
	return PLUGIN_HANDLED;
}
SpeedTask()
{
	static i, target;
	static Float:velocity[3];
	static Float:speed, Float:speedh;
	
	for(i=1; i<=maxplayers; i++)
	{
		if(!is_user_connected(i)) continue;
		if(!plrSpeed[i]) continue;
		
		target = pev(i, pev_iuser1) == 4 ? pev(i, pev_iuser2) : i;
		pev(target, pev_velocity, velocity);

		speed = vector_length(velocity);
		speedh = floatsqroot(floatpower(velocity[0], 2.0) + floatpower(velocity[1], 2.0));
		
		set_hudmessage(r, g, b, -1.0, 0.7, 0, 0.0, FREQ, 0.01, 0.0);
		
		if(training == 1)
		{
			ShowSyncHudMsg(i, SyncHud, "%3.2f", speedh);
		}
		else
		{
			ShowSyncHudMsg(i, SyncHud, "%3.2f units/second^n%3.2f velocity", speed, speedh);
		}
	}
}

stock knifes_set_models(id)
{
	// client_print(id, print_console, "set_models");
	
	// pev_viewmodel pev_weaponmodel2
	set_pev(id, pev_viewmodel, g_knife);
	
	return 1;
}

public weapon_change( iEnt )
{
	if( !pev_valid(iEnt) )
		return HAM_IGNORED;
		
	static id; id = get_pdata_cbase(iEnt, 41, 4);
	knifes_set_models(id);
	
	return HAM_IGNORED;
}

public clcmd_spec(id)
{
	// CS_TEAM_T, CS_TEAM_CT, or CS_TEAM_SPECTATOR
	static CsTeams:team;
	static CsTeams:team2;
	static te, ct;
	static i;
	
	if(!is_user_connected(id)) return;
	
	team = cs_get_user_team(id);

	if(team == 0) return;
	
	if(team == 3)
	{
		te = 0; ct = 0;
		for(i=1; i<=maxplayers; i++)
		{
			if(!is_user_connected(i)) continue;
			
			team2 = cs_get_user_team(id);
			if(team2 == CS_TEAM_T)
			{
				te += 1;
			}
			else if(team2 == CS_TEAM_CT)
			{
				ct += 1;
			}
		}
		
		if(te > ct)
		{
			cs_set_user_team(id, CS_TEAM_CT);
		}
		else
		{
			cs_set_user_team(id, CS_TEAM_T);
		}
	}
	else if(team == 1 || team == 2)
	{
		if(is_user_alive(id))
		{
			user_silentkill(id);
		}
		
		cs_set_user_team(id, CS_TEAM_SPECTATOR);
	}
}

public cmdStart(id, uc_handle, seed)
{
	// gFrameTime[id][1] = gFrameTime[id][0]; //maybe u dont need it
	gFrameTime[id] = get_uc(uc_handle, UC_Msec); // Our cmd.msec

	// server_print("fps (%d): %d", id, gFrameTime[id][0]);
	// gFrameTimeInMsec[id] = gFrameTime[id][0] * 0.001;
}
	
public amx_showfps_cmd(id, level, cid)
{
	static i;
	new name[18];
	
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	
	client_print(id, print_console, "*** FPS ***");
	client_print(id, print_console, "#   Nick   Fps");
	for(i=1; i<=maxplayers; i++)
	{
		if(!is_user_connected(i)) continue;
		
		get_user_name(i, name, 17);
		client_print(id, print_console, "%d %s %d", get_user_userid(i), name, 1000/gFrameTime[i]);
	}
	
	return PLUGIN_HANDLED;
}

