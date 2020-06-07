// Defaults
#include <amxmodx>
#include <amxmisc>

// Modules
// #include <cstrike>
#include <reapi>
// #include <engine>
// #include <fakemeta>
// #include <hamsandwich>
// #include <fun>
// #include <xs>
// #include <sqlx>
#include <nvault>

// 3rd Part
#include <catch_const>

// mi0 utils
// #define UTIL_FADEEFFECT
// #define UTIL_HUDMESSAGE
// #define UTIL_CLIENTCMD
// #define UTIL_LICENSE 0
// #define UTIL_KUR print_chat

// #include <mi0_utils>

// Defines
// Main plugin Defines
#define PLUGIN  "Catch Mod: Rank System"
#define VERSION CATCHMOD_VER
#define AUTHOR  "mi0"

#define MAXPLAYERSVAR MAX_PLAYERS+1

#define VAULT_NAME "CatchMod_RankVault"

// Enums
enum CfgSections
{
	SectionNone,
	SectionSettings,
	SectionLevels
}

enum _:LevelData
{
	LevelName[64],
	LevelXP,
}

// Global Vars
new g_iPlayersXP[MAXPLAYERSVAR], g_iPlayersLevels[MAXPLAYERSVAR]
new g_iLevels, Array:g_aLevels
new g_iVaultHandle

// Plugin forwards
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_cfg()
{
	g_iVaultHandle = nvault_open(VAULT_NAME)
	if (g_iVaultHandle == INVALID_HANDLE)
	{
		set_fail_state("Cannot open vault(%s)", VAULT_NAME)
	}

	g_aLevels = ArrayCreate(LevelData)
	LoadCfg()
}

public plugin_end()
{
	ArrayDestroy(g_aLevels)
	nvault_close(g_iVaultHandle)
}

public client_connectex(id)
{
	if ((g_iPlayersXP[id] = NVault_ParsePlayer(id)))
	{
		Player_CheckLevel(id)
	}
}

public client_disconnected(id)
{
	if (g_iPlayersLevels[id] > 0)
	{
		NVault_ParsePlayer(id, true)
	}
	g_iPlayersLevels[id] = 0
	g_iPlayersXP[id] = 0
}

// Cmds
// Add your code here...

// Ham/Reapi/Fm/Engine Forwards
// Add your code here...

// Custom Functions
bool:Player_UpdateXP(id, iAmount, bool:bDecreasing = false)
{
	if (!is_user_connected(id) || iAmount == 0)
	{
		return false
	}

	new iNewXP
	switch(bDecreasing)
	{
		case true:
		{
			iNewXP = g_iPlayersXP[id] - iAmount
		}

		case false:
		{
			iNewXP = g_iPlayersXP[id] + iAmount
		}
	}

	g_iPlayersXP[id] = iNewXP < 0 ? 0 : iNewXP

	Player_UpdateLevel(id, bDecreasing) 
	return true
}

bool:Player_UpdateLevel(id, bool:bDecreasing = false)
{
	new bool:bRetVal
	new iLevel = g_iPlayersLevels[id]
	new iXP = g_iPlayersXP[id]
	new eTempArray[LevelData]
	ArrayGetArray(g_aLevels, iLevel, eTempArray)

	switch(bDecreasing)
	{
		case true:
		{
			while (iXP < eTempArray[LevelXP])
			{
				ArrayGetArray(g_aLevels, --iLevel, eTempArray)
			}
			bRetVal = (iLevel < g_iPlayersLevels[id])
		}

		case false:
		{
			while (iXP > eTempArray[LevelXP])
			{
				ArrayGetArray(g_aLevels, ++iLevel, eTempArray)
			}
			bRetVal = (iLevel > g_iPlayersLevels[id])
		}
	}

	g_iPlayersLevels[id] = iLevel
	return bRetVal
}

Player_CheckLevel(id)
{
	new iLevel
	new iXP = g_iPlayersXP[id]
	new eTempArray[LevelData]
	ArrayGetArray(g_aLevels, iLevel, eTempArray)

	while (iXP > eTempArray[LevelXP])
	{
		ArrayGetArray(g_aLevels, ++iLevel, eTempArray)
	}
	g_iPlayersLevels[id] = iLevel
}

NVault_ParsePlayer(id, bool:bSave = false)
{
	new szKey[32]
	switch (is_user_steam(id))
	{
		case true:
		{
			get_user_authid(id, szKey, charsmax(szKey))
		}

		case false:
		{
			get_user_name(id, szKey, charsmax(szKey))
		}
	}

	switch(bSave)
	{
		case true:
		{
			new szInfo[32]
			formatex(szInfo, charsmax(szInfo), "%i", g_iPlayersXP[id])
			nvault_set(g_iVaultHandle, szKey, szInfo)
		}

		case false:
		{
			return nvault_get(g_iVaultHandle, szKey)
		}
	}

	return 0
}

LoadCfg()
{
	new szFileDir[128]
	get_configsdir(szFileDir, charsmax(szFileDir))
	add(szFileDir, charsmax(szFileDir), "/RankConfig.ini")

	new iFile = fopen(szFileDir, "rt")
	if (iFile)
	{
		new szLine[256], CfgSections:iSection
		new szKey[32], szValue[32]
		new eTempArray[LevelData], iParsed, iBadLoaded

		while (!feof(iFile))
		{
			fgets(iFile, szLine, charsmax(szLine))
			trim(szLine)

			if (szLine[0] == EOS || szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
			{
				continue
			}
			else if (szLine[0] == '[')
			{
				switch (szLine[1])
				{
					case 'S':
					{
						iSection = SectionSettings
					}

					case 'L':
					{
						iSection = SectionLevels
					}

					default:
					{
						iSection = SectionNone
					}
				}
				continue
			}

			switch (iSection)
			{
				/*
				case SectionSettings:
				{
					strtok2(szLine, szKey, charsmax(szKey), szValue, charsmax(szValue), '=', 1)


				}
				*/

				case SectionLevels:
				{
					iParsed = parse(szLine, eTempArray[LevelName], charsmax(eTempArray[LevelName]), szValue, charsmax(szValue))

					if (iParsed < 4)
					{
						iBadLoaded++
						continue
					}

					eTempArray[LevelXP] = str_to_num(szValue)

					ArrayPushArray(g_aLevels, eTempArray)
					g_iLevels++
				}
			}
		}

		server_print("Catch Mod >> Loaded %i ranks %i Successful %i Bad!", g_iLevels + iBadLoaded, g_iLevels, iBadLoaded)
	}
}

// Stocks
// Add your code here...

// Natives
public plugin_natives()
{
	register_native("cranksys_get_player_xp", "_native_get_player_xp")
	register_native("cranksys_set_player_xp", "_native_set_player_xp")
	
	register_native("cranksys_get_player_level", "_native_get_player_level")
	register_native("cranksys_set_player_level", "_native_set_player_level")
}

public _native_get_player_xp()
{
	return g_iPlayersXP[get_param(0)]
}

public _native_set_player_xp()
{
	new iXP = get_param(1), id = get_param(0)
	Player_UpdateXP(id, iXP, iXP < g_iPlayersXP[id] ? true : false)
}

public _native_get_player_level()
{
	return g_iPlayersLevels[get_param(0)]
}

public _native_set_player_level()
{
	new id = get_param(0), eTempArray[LevelData]
	ArrayGetArray(g_aLevels, get_param(1), eTempArray)
	Player_UpdateXP(id, eTempArray[LevelXP], eTempArray[LevelXP] < g_iPlayersXP[id] ? true : false)
}