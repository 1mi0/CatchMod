#include <amxmodx>
#include <fakemeta>

new gFrameTime[33];
new gDevViolations[33];
new cvar_block;

public plugin_init()
{
	register_plugin("Dev blocker", "1.0", "v3x");

	register_forward(FM_CmdStart, "cmdStart");

	cvar_block = register_cvar("amx_blockdev", "0");

	set_task(1.0, "CheckForDev", 6923, "", 0, "ab");
}

public client_putinserver(id)
{
	gFrameTime[id] = 10;
	gDevViolations[id] = 0;
}

public cmdStart(id, uc_handle, seed)
{
	gFrameTime[id] = get_uc(uc_handle, UC_Msec);
}

public CheckForDev()
{
	if(get_pcvar_num(cvar_block) == 0)
		return;

	for(new i = 1; i < 33; i++)
	{
		if(is_user_connected(i))
		{
			if(gFrameTime[i] < 10)
			{
				gDevViolations[i]++;
				if(gDevViolations[i] > 3)
				{
					gDevViolations[i] = 0;
					new name[18];
					get_user_name(i, name, 17);
					//client_print(0, print_chat, "Kicked", name);
					
					new userid = get_user_userid(i);
					server_cmd("kick #%d ^"%s^"", userid, "Kicked");
				}
			}
		}
	}
}
