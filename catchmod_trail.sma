#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <catchmod>

#define TASKID 1000
//#define DEBUG

enum Sections
{
	SectionNone = 0,
	SectionTypes,
	SectionColors,
	SectionSettings
}

enum _:ColorsData
{
	Name[32],
	Color[3]
}

enum _:TrailTypeData
{
	TypeName[32],
	TypeSprite[128],
	TypeSpriteID,
	TypeSize,
	TypeBrightness
}

enum _:UserSettings
{
	Name[32],
	bool:TrailOn = false,
	TrailColorID,
	TrailColors[3],
	bool:CustomColorOn,
	TrailType,
	LiteType:TrailLite
}

enum _:TrailsSettings
{
	AdminFlags,
	TrailLife,
	CustomColorFlags,
	TrailModeAdd,
	Sprite,
	SpriteSize,
	SpriteBrightness,
	SpriteOffset[2],
	SpriteModel
}
new g_eTeamsColors[Teams][3]

new Float:g_fOldTime[33]
new Float:g_fOldOrigin[33][3]

new Array:g_aColorsArray
new Array:g_aTypesArray
new g_iColorCount
new g_iTypeCount
new g_eTrailsSettings[TrailsSettings]

new g_eUserSettings[33][UserSettings]

new g_iColorsMenu
new g_iTypesMenu

public plugin_init()
{
	register_plugin("Catch Mod: Trails", CATCHMOD_VER, "mi0")
	RegisterHookChain(RG_CBasePlayer_PreThink, "OnPlayerPreThink")
	register_event("ResetHUD", "OnPlayerHudReset", "b")

	register_clcmd("say /trails", "cmd_trails")
	register_clcmd("CT_CUSTOM_COLOR", "cmd_custom_color")
}

public plugin_precache()
{
	g_aTypesArray = ArrayCreate(TrailTypeData)
	g_aColorsArray = ArrayCreate(ColorsData)

	LoadFile()
	MakeColorsMenu()
	MakeTypesMenu()
}

public plugin_end()
{
	ArrayDestroy(g_aColorsArray)
	ArrayDestroy(g_aTypesArray)
}

LoadFile()
{
	new szFileDir[128]
	get_configsdir(szFileDir, charsmax(szFileDir))
	add(szFileDir, charsmax(szFileDir), "/TrailsSettings.ini")

	new iFile = fopen(szFileDir, "rt")
	if (iFile)
	{
		new szLine[256], Sections:iSection = SectionNone
		new szKey[32], szValue[32]
		new Teams:iTeam
		new szParsedColor[3][4]
		new eTempColorArray[ColorsData], eTempTypeArray[TrailTypeData]

		while (!feof(iFile))
		{
			fgets(iFile, szLine, charsmax(szLine))
			trim(szLine)

			if (szLine[0] == EOS || szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
			{
				continue
			}

			if (szLine[0] == '[')
			{
				switch (szLine[1])
				{
					case 'T':
					{
						iSection = SectionTypes
					}

					case 'C':
					{
						iSection = SectionColors
					}

					case 'S':
					{
						iSection = SectionSettings
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
				case SectionTypes:
				{
					parse(szLine, eTempTypeArray[Name], charsmax(eTempTypeArray[Name]), eTempTypeArray[TypeSprite], charsmax(eTempTypeArray[TypeSprite]), szKey, charsmax(szKey), szValue, charsmax(szValue))
					eTempTypeArray[TypeSpriteID] = precache_model(eTempTypeArray[TypeSprite])
					eTempTypeArray[TypeSize] = abs(str_to_num(szKey))
					eTempTypeArray[TypeBrightness] = clamp(str_to_num(szValue), 0, 255)

					ArrayPushArray(g_aTypesArray, eTempTypeArray)
					g_iTypeCount++
				}

				case SectionColors:
				{
					parse(szLine, eTempColorArray[Name], charsmax(eTempColorArray[Name]), szKey, charsmax(szKey))
					parse(szKey, szParsedColor[0], charsmax(szParsedColor[]), szParsedColor[1], charsmax(szParsedColor[]), szParsedColor[2], charsmax(szParsedColor[]))
					eTempColorArray[Color][0] = clamp(str_to_num(szParsedColor[0]), 0, 255)
					eTempColorArray[Color][1] = clamp(str_to_num(szParsedColor[1]), 0, 255)
					eTempColorArray[Color][2] = clamp(str_to_num(szParsedColor[2]), 0, 255)

					ArrayPushArray(g_aColorsArray, eTempColorArray)
					g_iColorCount++
				}

				case SectionSettings:
				{
					strtok(szLine, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey)
					trim(szValue)

					if (equali(szKey, "ADMIN_FLAGS"))
					{
						g_eTrailsSettings[AdminFlags] = read_flags(szValue)
					}
					else if (equali(szKey, "TRAIL_LIFE"))
					{
						g_eTrailsSettings[TrailLife] = abs(str_to_num(szValue))
					}
					else if (equali(szKey, "TRAIL_MODE_ADD"))
					{
						g_eTrailsSettings[TrailModeAdd] = abs(str_to_num(szValue))
					}
					else if (equali(szKey, "ADMIN_CUSTOM_COLOR"))
					{
						g_eTrailsSettings[CustomColorFlags] = read_flags(szValue)
					}
					else if (equali(szKey, "FLEER_COLOR") || equali(szKey, "CATCHER_COLOR") || equali(szKey, "TRAINING_COLOR") || equali(szKey, "NONE_COLOR"))
					{
						parse(szValue, szParsedColor[0], charsmax(szParsedColor[]), szParsedColor[1], charsmax(szParsedColor[]), szParsedColor[2], charsmax(szParsedColor[]))

						switch (szKey[0])
						{
							case 'F':
							{
								iTeam = FLEER
							}
							
							case 'C':
							{
								iTeam = CATCHER
							}

							case 'T':
							{
								iTeam = TRAINING
							}
							
							case 'N':
							{
								iTeam = NONE
							}
						}

						g_eTeamsColors[iTeam][0] = str_to_num(szParsedColor[0])
						g_eTeamsColors[iTeam][1] = str_to_num(szParsedColor[1])
						g_eTeamsColors[iTeam][2] = str_to_num(szParsedColor[2])
					}
					else if (equali(szKey, "TRAIL_SPRITE"))
					{
						g_eTrailsSettings[Sprite] = str_to_num(szValue)
						switch (g_eTrailsSettings[Sprite])
						{
							case 0:
							{
								g_eTrailsSettings[SpriteModel] = precache_model("sprites/xsmoke4.spr")
								g_eTrailsSettings[SpriteSize] = 5
								g_eTrailsSettings[SpriteBrightness] = 160
								g_eTrailsSettings[SpriteOffset][0] = -5
								g_eTrailsSettings[SpriteOffset][1] = 33
							}

							case 1:
							{
								g_eTrailsSettings[SpriteModel] = precache_model("sprites/flame.spr")
								g_eTrailsSettings[SpriteSize] = 1
								g_eTrailsSettings[SpriteBrightness] = 255
								g_eTrailsSettings[SpriteOffset][0] = -6
								g_eTrailsSettings[SpriteOffset][1] = 30
							}
						}
					}
				}
			}
		}
	}
}

OpenTrailMenu(id)
{
	new iMenu = menu_create("\yColorful Trails \rMenu", "TrailMenu_Handler")
	new iMenuCallBack = menu_makecallback("TrailMenu_CallBack")

	new eTempTypeArray[TrailTypeData], szTemp[192]
	ArrayGetArray(g_aTypesArray, g_eUserSettings[id][TrailType], eTempTypeArray)
	formatex(szTemp, charsmax(szTemp), "Types \y[%s]", eTempTypeArray[TypeName])
	menu_additem(iMenu, szTemp)

	if (g_eUserSettings[id][CustomColorOn])
	{
		formatex(szTemp, charsmax(szTemp), "Colors \r[Custom]")
	}
	else
	{
		new eTempColorArray[ColorsData]
		ArrayGetArray(g_aColorsArray, g_eUserSettings[id][TrailColorID], eTempColorArray)
		formatex(szTemp, charsmax(szTemp), "Colors \y[%s]", eTempColorArray[Name])
	}
	menu_additem(iMenu, szTemp)

	if (get_user_flags(id) & g_eTrailsSettings[CustomColorFlags])
	{
		if (g_eUserSettings[id][CustomColorOn])
		{
			formatex(szTemp, charsmax(szTemp), "Custom Color \y[%.3i %.3i %.3i]", g_eUserSettings[id][TrailColors][0], g_eUserSettings[id][TrailColors][1], g_eUserSettings[id][TrailColors][2])
		}
		else
		{
			formatex(szTemp, charsmax(szTemp), "Custom Color \y[Off]")
		}
	}
	else
	{
		formatex(szTemp, charsmax(szTemp), "Custom Color \r[Admins Only]")
	}
	menu_additem(iMenu, szTemp, .callback = iMenuCallBack)

	formatex(szTemp, charsmax(szTemp), "Custom Trail - %s", g_eUserSettings[id][TrailOn] ? "\yOn" : "\rOff")
	menu_additem(iMenu, szTemp)

	menu_display(id, iMenu)
}

public TrailMenu_CallBack(id, iMenu, iItem)
{
	return (get_user_flags(id) & g_eTrailsSettings[CustomColorFlags]) ? ITEM_ENABLED : ITEM_DISABLED
}

public TrailMenu_Handler(id, iMenu, iItem)
{
	switch (iItem)
	{
		case 0:
		{
			menu_display(id, g_iTypesMenu)
		}
		case 1:
		{
			menu_display(id, g_iColorsMenu)
		}
		case 2:
		{
			client_cmd(id, "messagemode CT_CUSTOM_COLOR")
		}
		case 3:
		{
			g_eUserSettings[id][TrailOn] = !g_eUserSettings[id][TrailOn]
			checkUserTrail(id)

			menu_destroy(iMenu)
			OpenTrailMenu(id)
			return PLUGIN_HANDLED
		}
	}

	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

MakeColorsMenu()
{
	g_iColorsMenu = menu_create("\rTrails Colors", "ColorsMenu_Handler")

	for (new i, eTempArray[ColorsData]; i < g_iColorCount; i++)
	{
		ArrayGetArray(g_aColorsArray, i, eTempArray)
		menu_additem(g_iColorsMenu, eTempArray[Name])
	}
}

public ColorsMenu_Handler(id, iMenu, iItem)
{
	if (iItem == MENU_EXIT)
	{
		menu_cancel(id)
		OpenTrailMenu(id)

		return PLUGIN_HANDLED
	}

	new eTempArray[ColorsData]
	ArrayGetArray(g_aColorsArray, iItem, eTempArray)

	copy(g_eUserSettings[id][TrailColors], 3, eTempArray[Color])
	g_eUserSettings[id][TrailColorID] = iItem
	g_eUserSettings[id][CustomColorOn] = false
	g_eUserSettings[id][TrailOn] = true

	UpdateUserTrail(id)

	menu_cancel(id)
	OpenTrailMenu(id)
	return PLUGIN_HANDLED
}

MakeTypesMenu()
{
	g_iTypesMenu = menu_create("\rTrails Types", "TypesMenu_Handler")

	for (new i, eTempArray[TrailTypeData]; i < g_iTypeCount; i++)
	{
		ArrayGetArray(g_aTypesArray, i, eTempArray)
		menu_additem(g_iTypesMenu, eTempArray[TypeName])
	}
}

public TypesMenu_Handler(id, iMenu, iItem)
{
	if (iItem == MENU_EXIT)
	{
		menu_cancel(id)
		OpenTrailMenu(id)

		return PLUGIN_HANDLED
	}

	g_eUserSettings[id][TrailType] = iItem
	g_eUserSettings[id][TrailOn] = true

	UpdateUserTrail(id)

	new eTempArray[TrailTypeData]
	ArrayGetArray(g_aTypesArray, iItem, eTempArray)

	menu_cancel(id)
	OpenTrailMenu(id)
	return PLUGIN_HANDLED
}

public OnPlayerHudReset(id)
{
	new iTaskID = id + TASKID
	if (task_exists(iTaskID))
	{
		remove_task(iTaskID)
	}

	set_task_ex(1.0, "task_PreApply", iTaskID)
	return HC_CONTINUE
}

public task_PreApply(iTaskID)
{
	new id = iTaskID - TASKID

	new Teams:iPlayerTeam = catchmod_get_user_team(id)
	new Float:fColors[3]

	fColors[0] = float(g_eTeamsColors[iPlayerTeam][0])
	fColors[1] = float(g_eTeamsColors[iPlayerTeam][1])
	fColors[2] = float(g_eTeamsColors[iPlayerTeam][2])

	set_entvar(id, var_renderfx, kRenderFxGlowShell)
	set_entvar(id, var_rendercolor, fColors)
	set_entvar(id, var_renderamt, 25.0)

	#if defined DEBUG
	client_print_color(id, id, "^x04[DEBUG]^x01 Function - PreApply")
	client_print_color(id, id, "^x04---------------------------")
	client_print_color(id, id, "Teams - %i %i %i", g_eTeamsColors[iPlayerTeam][0], g_eTeamsColors[iPlayerTeam][1], g_eTeamsColors[iPlayerTeam][2])
	#endif

	if (!g_eUserSettings[id][TrailOn])
	{
		g_eUserSettings[id][TrailColors][0] = g_eTeamsColors[iPlayerTeam][0]
		g_eUserSettings[id][TrailColors][1] = g_eTeamsColors[iPlayerTeam][1]
		g_eUserSettings[id][TrailColors][2] = g_eTeamsColors[iPlayerTeam][2]
	#if defined DEBUG

	client_print_color(id, id, "User - %i %i %i", g_eUserSettings[id][TrailColors][0], g_eUserSettings[id][TrailColors][1], g_eUserSettings[id][TrailColors][2])
	}
	else
	{
		client_print_color(id, id, "User - Function Cutted")
	}
	client_print_color(id, id, "Floats - %f %f %f", fColors[0], fColors[1], fColors[2])
	client_print_color(id, id, "^x04---------------------------")
	#else
	}
	#endif

	UpdateUserTrail(id)
	set_task_ex(10.0, "task_Apply", id + TASKID, .flags = SetTask_Repeat)
}

public task_Apply(iTaskID)
{
	new id = iTaskID - TASKID
	UpdateUserTrail(id)

	#if defined DEBUG
	client_print_color(id, id, "^x04[DEBUG]^x01 Function - Apply")
	#endif
}

UpdateUserTrail(id)
{
	KillUserTrail(id)

	new eTempArray[TrailTypeData]
	ArrayGetArray(g_aTypesArray, g_eUserSettings[id][TrailType], eTempArray)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(id)
	write_short(eTempArray[TypeSpriteID])
	write_byte(g_eTrailsSettings[TrailLife] * 10)
	write_byte(eTempArray[TypeSize])
	write_byte(g_eUserSettings[id][TrailColors][0])
	write_byte(g_eUserSettings[id][TrailColors][1])
	write_byte(g_eUserSettings[id][TrailColors][2])
	write_byte(eTempArray[TypeBrightness])
	message_end()
}

KillUserTrail(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(id)
	message_end()
}

checkUserTrail(id)
{
	if (g_eUserSettings[id][TrailOn])
	{
		new eTempArray[ColorsData]
		ArrayGetArray(g_aColorsArray, g_eUserSettings[id][TrailColorID], eTempArray)
		copy(g_eUserSettings[id][TrailColors], 3, eTempArray[Color])
		UpdateUserTrail(id)
	}
	else
	{
		copy(g_eUserSettings[id][TrailColors], 3, g_eTeamsColors[catchmod_get_user_team(id)])
		UpdateUserTrail(id)
	}
}

public OnPlayerPreThink(id)
{
	if (!is_user_alive(id))
	{
		return HC_CONTINUE
	}

	new Float:fGameTime = get_gametime()
	if (fGameTime < g_fOldTime[id])
	{
		return HC_CONTINUE
	}

	new Float:fOrigin[3]
	get_entvar(id, var_origin, fOrigin)
	if (get_distance_f(g_fOldOrigin[id], fOrigin) == 0)
	{
		return HC_CONTINUE
	}

	g_fOldTime[id] = fGameTime + 0.1
	g_fOldOrigin[id][0] = fOrigin[0]
	g_fOldOrigin[id][1] = fOrigin[1]
	g_fOldOrigin[id][2] = fOrigin[2]
	makeSpriteTrails(id)

	return HC_CONTINUE
}

makeSpriteTrails(id)
{
	new iFlags = get_entvar(id, var_flags)
	if (~iFlags & FL_ONGROUND)
	{
		return
	}

	new iOrigin[3]
	get_user_origin(id, iOrigin)
	iOrigin[2] -= (iFlags & FL_DUCKING) ? g_eTrailsSettings[SpriteOffset][0] : g_eTrailsSettings[SpriteOffset][1] 

	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_short(g_eTrailsSettings[SpriteModel])
	write_byte(g_eTrailsSettings[SpriteSize])
	write_byte(g_eTrailsSettings[SpriteBrightness])
	message_end()
}

public cmd_trails(id)
{
	if (!is_user_connected(id))
	{
		return PLUGIN_HANDLED
	}

	if (~get_user_flags(id) & g_eTrailsSettings[AdminFlags])
	{
		return PLUGIN_HANDLED
	}

	OpenTrailMenu(id)

	return PLUGIN_HANDLED
}

public cmd_custom_color(id)
{
	if (!is_user_connected(id))
	{
		return PLUGIN_HANDLED
	}

	if (~get_user_flags(id) & g_eTrailsSettings[CustomColorFlags])
	{
		return PLUGIN_HANDLED
	}

	new szArg[16]
	read_argv(1, szArg, charsmax(szArg))

	new szColors[3][4]
	parse(szArg, szColors[0], charsmax(szColors[]), szColors[1], charsmax(szColors[]), szColors[2], charsmax(szColors[]))

	g_eUserSettings[id][TrailColors][0] = clamp(str_to_num(szColors[0]), 0, 255)
	g_eUserSettings[id][TrailColors][1] = clamp(str_to_num(szColors[1]), 0, 255)
	g_eUserSettings[id][TrailColors][2] = clamp(str_to_num(szColors[2]), 0, 255)
	g_eUserSettings[id][CustomColorOn] = true
	g_eUserSettings[id][TrailOn] = true

	UpdateUserTrail(id)
	OpenTrailMenu(id)

	return PLUGIN_HANDLED
}

