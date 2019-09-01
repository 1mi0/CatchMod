// Defaults
#include <amxmodx>
// #include <amxmisc>

// Modules
// #include <cstrike>
// #include <reapi>
// #include <engine>
// #include <fakemeta>
// #include <hamsandwich>
// #include <fun>
// #include <xs>
// #include <sqlx>

// 3rd Part
// Add your code here...

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

#define MAXPLAYERSVAR MAX_PLAYERS + 1

// Enums
enum CfgSections
{
	SectionNone,
	SectionSettings,
	SectionLevels
}

enum _:LevelInfo
{
	LevelName[64],
	LevelColor[64],
	LevelXP,
	LevelInfo[64]
}

// Global Vars
new g_iPlayersXP[MAXPLAYERSVAR], g_iPlayerLevel[MAXPLAYERSVAR]
new g_iLevels, Array:g_aLevels

// Plugin forwards
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Add your code here...
}

public plugin_cfg()
{
	g_aLevels = ArrayCreate(LevelInfo)
	LoadCfg()
}

public plugin_end()
{
	ArrayDestroy(g_aLevels)
}

// Cmds
// Add your code here...

// Ham/Reapi/Fm/Engine Forwards
// Add your code here...

// Custom Functions
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
		new eTempArray[LevelInfo]

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
				case SectionSettings:
				{
					strtok(szLine, szKey, charsmax(szKey), szValue, charsmax(szValue), "=")
					trim(szKey)
					trim(szValue)


				}

				case SectionLevels:
				{
					parse(szLine, eTempArray[LevelName], charsmax(eTempArray[LevelName]), 
						eTempArray[LevelColor], charsmax(eTempArray[LevelColor]), 
						szValue, charsmax(szValue), 
						eTempArray[LevelInfo], charsmax(eTempArray[LevelInfo]))

					eTempArray[LevelXP] = str_to_num(szValue)

					ArrayPushArray(g_aLevels, eTempArray)
					g_iLevels++
				}
			}
		}
	}
}

// Stocks
// Add your code here...

// Natives
// Add your code here...