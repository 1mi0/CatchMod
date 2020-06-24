#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN  "Catch Mod: Rank System"
#define VERSION CATCHMOD_VER
#define AUTHOR  "mi0"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_cfg()
{
	SQL_SetAffinity("sqlx")
}

