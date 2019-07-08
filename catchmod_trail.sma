#include <amxmodx>
#include <amxmisc>
#include <cromchat>
#include <catch_const>

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
	TrailType
}

enum _:TrailsSettings
{
	AdminFlags,
	TrailLife,
	CustomColorFlags
}

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

	register_clcmd("say /trails", "cmd_trails")
	register_clcmd("CT_CUSTOM_COLOR", "cmd_custom_color")

	register_message(99, "OnBeamKill")
}

public plugin_cfg()
{
	g_aColorsArray = ArrayCreate(ColorsData)
	LoadSettings()
	LoadColors()
	MakeColorsMenu()
}

public plugin_precache()
{
	g_aTypesArray = ArrayCreate(TrailTypeData)
	LoadTypes()
	MakeTypesMenu()
}

public plugin_end()
{
	ArrayDestroy(g_aColorsArray)
	ArrayDestroy(g_aTypesArray)
}

LoadSettings()
{
	new szFileDir[128]
	get_configsdir(szFileDir, charsmax(szFileDir))
	add(szFileDir, charsmax(szFileDir), "/TrailsSettings.ini")

	new iFile = fopen(szFileDir, "rt")
	if (iFile)
	{
		new szLine[256], szKey[32], szValue[32]

		while (!feof(iFile))
		{
			fgets(iFile, szLine, charsmax(szLine))

			if (szLine[0] == EOS || szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
			{
				continue
			}

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
			else if (equali(szKey, "ADMIN_CUSTOM_COLOR"))
			{
				g_eTrailsSettings[CustomColorFlags] = read_flags(szValue)
			}
			else if (equali((szKey), "CHAT_PREFIX"))
			{
				if (szValue[0] != EOS)
				{
					CC_SetPrefix(szValue)
				}
			}
		}
	}
}

LoadColors()
{
	new szFileDir[128]
	get_configsdir(szFileDir, charsmax(szFileDir))
	add(szFileDir, charsmax(szFileDir), "/TrailsColors.ini")

	new iFile = fopen(szFileDir, "rt")
	if (iFile)
	{
		new szLine[256], szFullColor[16], szParsedColor[3][4], eTempArray[ColorsData]

		while (!feof(iFile))
		{
			fgets(iFile, szLine, charsmax(szLine))

			if (szLine[0] == EOS || szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
			{
				continue
			}
			else
			{
				parse(szLine, eTempArray[Name], charsmax(eTempArray[Name]), szFullColor, charsmax(szFullColor))
				parse(szFullColor, szParsedColor[0], charsmax(szParsedColor[]), szParsedColor[1], charsmax(szParsedColor[]), szParsedColor[2], charsmax(szParsedColor[]))
				eTempArray[Color][0] = clamp(str_to_num(szParsedColor[0]), 0, 255)
				eTempArray[Color][1] = clamp(str_to_num(szParsedColor[1]), 0, 255)
				eTempArray[Color][2] = clamp(str_to_num(szParsedColor[2]), 0, 255)

				ArrayPushArray(g_aColorsArray, eTempArray)
				g_iColorCount++
			}
		}
	}

	server_print("[Colorful Trails] Loaded colors: %i", g_iColorCount)
}

LoadTypes()
{
	new szFileDir[128]
	get_configsdir(szFileDir, charsmax(szFileDir))
	add(szFileDir, charsmax(szFileDir), "/TrailsTypes.ini")

	new iFile = fopen(szFileDir, "rt")
	if (iFile)
	{
		new szLine[256], szSize[8], szBrightness[8], eTempArray[TrailTypeData]

		while (!feof(iFile))
		{
			fgets(iFile, szLine, charsmax(szLine))

			if (szLine[0] == EOS || szLine[0] == '#' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
			{
				continue
			}
			else
			{
				parse(szLine, eTempArray[Name], charsmax(eTempArray[Name]), eTempArray[TypeSprite], charsmax(eTempArray[TypeSprite]), szSize, charsmax(szSize), szBrightness, charsmax(szBrightness))
				eTempArray[TypeSpriteID] = precache_model(eTempArray[TypeSprite])
				eTempArray[TypeSize] = abs(str_to_num(szSize))
				eTempArray[TypeBrightness] = clamp(str_to_num(szBrightness), 0, 255)

				ArrayPushArray(g_aTypesArray, eTempArray)
				g_iTypeCount++
			}
		}
	}

	server_print("[Colorful Trails] Loaded types: %i", g_iTypeCount)
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

	formatex(szTemp, charsmax(szTemp), "Trail - %s", g_eUserSettings[id][TrailOn] ? "\yOn" : "\rOff")
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
			if (g_eUserSettings[id][TrailOn])
			{
				StopUserTrail(id)
			}
			else
			{
				StartUserTrail(id)
			}
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

	g_eUserSettings[id][TrailColors][0] = eTempArray[Color][0]
	g_eUserSettings[id][TrailColors][1] = eTempArray[Color][1]
	g_eUserSettings[id][TrailColors][2] = eTempArray[Color][2]
	g_eUserSettings[id][TrailColorID] = iItem
	g_eUserSettings[id][CustomColorOn] = false

	if (g_eUserSettings[id][TrailOn])
	{
		UpdateUserTrail(id)
	}
	else
	{
		StartUserTrail(id)
	}

	client_print_color(id, id, "You successfuly set your color to ^x03%s", eTempArray[Name])

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

	if (g_eUserSettings[id][TrailOn])
	{
		UpdateUserTrail(id)
	}
	else
	{
		StartUserTrail(id)
	}

	new eTempArray[TrailTypeData]
	ArrayGetArray(g_aTypesArray, iItem, eTempArray)
	client_print_color(id, id, "You successfuly set your type to ^x03%s", eTempArray[Name])

	menu_cancel(id)
	OpenTrailMenu(id)
	return PLUGIN_HANDLED
}

StartUserTrail(id)
{
	UpdateUserTrail(id)
	set_task_ex(10.0, "UpdateUserTrail", id, .flags = SetTask_Repeat)
	g_eUserSettings[id][TrailOn] = true
}

StopUserTrail(id)
{
	KillUserTrail(id)
	if (task_exists(id))
	{
		remove_task(id)
	}
	g_eUserSettings[id][TrailOn] = false
}

public UpdateUserTrail(id)
{
	KillUserTrail(id)

	new eTempArray[TrailTypeData]
	ArrayGetArray(g_aTypesArray, g_eUserSettings[id][TrailType], eTempArray)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(22)
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
	write_byte(99)
	write_short(id)
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
		CC_SendMatched(id, id, "You must be ^x04Vip ^x01 to use the ^x03Colorful Trails")
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

	if (g_eUserSettings[id][TrailOn])
	{
		UpdateUserTrail(id)
	}
	else
	{
		StartUserTrail(id)
	}

	client_print_color(id, id, "You successfuly set custom color - ^"%i %i %i^"", g_eUserSettings[id][TrailColors][0], g_eUserSettings[id][TrailColors][1], g_eUserSettings[id][TrailColors][2])

	OpenTrailMenu(id)

	return PLUGIN_HANDLED
}

public OnBeamKill(iMsg, iDest, id)
{
	if (g_eUserSettings[id][TrailOn])
	{
		UpdateUserTrail(id)
	}
}