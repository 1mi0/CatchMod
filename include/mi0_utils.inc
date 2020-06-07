#if defined _mi0_utils_included // call the file mi0_utils even though uve stolen everything in it xDDD
	#endinput
#endif

#define _mi0_utils_included

#define SECONDS_TO_UNITS(%1) (4096 * %1)

#if defined UTIL_FADEEFFECT // UTIL_FADEEFFECT -- Stalinnn
	stock UTIL_MakeFadeEffect(id, iColors[3], iAlpha, Float:fDuration, iType = 0x0000)
	{
		message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, .player = id)
		write_short(floatround(SECONDS_TO_UNITS(fDuration)))
		write_short(floatround(SECONDS_TO_UNITS(fDuration)))
		write_short(iType)
		write_byte(iColors[0])
		write_byte(iColors[1])
		write_byte(iColors[2])
		write_byte(iAlpha)
		message_end()
	}
#endif // UTIL_FADEEFFECT

#if defined UTIL_HUDMESSAGE // UTIL_HUDMESSAGE -- Stolennn
	stock UTIL_SendHudmessage(id, const szMessage[], R, G, B, Float:X, Float:Y, A=255, effect=0, effect_R=0, effect_G=0, effect_B=0, effect_A=255, Float:holdtime=5.0, Float:fadeintime=0.1, Float:fadeouttime=0.1, channel=-1, Float:effecttime=0.0)
	{
		if (id)
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id)
		else
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_TEXTMESSAGE)
		write_byte(channel)
		write_short(coord_to_hudmsgshort(X))
		write_short(coord_to_hudmsgshort(Y))
		write_byte(effect)
		write_byte(R)
		write_byte(G)
		write_byte(B)
		write_byte(A)
		write_byte(effect_R)
		write_byte(effect_G)
		write_byte(effect_B)
		write_byte(effect_A)
		write_short(seconds_to_hudmsgshort(fadeintime))
		write_short(seconds_to_hudmsgshort(fadeouttime))
		write_short(seconds_to_hudmsgshort(holdtime))
		if (effect == 2)
			write_short(seconds_to_hudmsgshort(effecttime))
		write_string(text)
		message_end()
	}
	
	stock seconds_to_hudmsgshort(Float:sec)
	{
		new output = floatround(sec * 256)
		return output < 0 ? 0 : output > 65535 ? 65535 : output
	}

	stock coord_to_hudmsgshort(Float:coord)
	{
		new output = floatround(coord * 8192)
		return output < -32768 ? -32768 : output > 32767 ? 32767 : output
	}
#endif // UTIL_HUDMESSAGE

#if defined UTIL_CLIENTCMD // UTIL_CLIENTCMD -- Who said dont steal all my code??? Huehue was it u?
	stock UTIL_ClientCMD(id, const szText[], any:...)
	{
		#pragma unused szText
		
		if (id == 0 || is_user_connected(id))
		{
			new szMessage[256]
			format_args(szMessage, charsmax(szMessage), 1)
			
			message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, .player = id)
			write_byte(strlen(szMessage) + 2)
			write_byte(10)
			write_string(szMessage)
			message_end()
		}
	}
#endif // UTIL_CLIENTCMD

#if defined UTIL_LICENSE // UTIL_LICENSE -- Definately not stolen xDDD
	stock UTIL_CheckServerLicense(const szIP[], szFileName[])
	{
		new szServerIP[20]
		get_user_ip(0, szServerIP, charsmax(szServerIP), 0)
		
		if (!equal(szServerIP, szIP))
		{
			#if UTIL_LICENSE 0
				log_amx("[License] ERROR: Checking Failed. Fixing Begins in 5 Seconds!!!")
				set_task(5.0, "FixServer")
			#elseif
				log_amx("[License] ERROR: Checking Failed. Shutting Down!!!")
				server_cmd("exit")
			#endif
		}
		else
		{
			log_amx("[License] License IP: <%s>. Your Server IP is: <%s>. IP Checking verified! DONE.", szIP, szServerIP)
		}
	}

	#if UTIL_LICENSE 0
		public FixServer()
		{
			delete_file(szFileName)
			set_task(1.0, "ResetMap")
		}

		public ResetMap()
		{
			server_cmd("restart")
		}
	#endif
#endif // UTIL_LICENSE

#if defined UTIL_KUR // UTIL_KUR -- The Best Thing in the mod rn
	stock UTIL_Kur(id)
	{
		client_print(id, UTIL_KUR, "Ti poluchavash:")
		client_print(id, UTIL_KUR, "K")
		client_print(id, UTIL_KUR, "U")
		client_print(id, UTIL_KUR, "R")
		client_print(id, UTIL_KUR, "_|_")
	}
#endif // UTIL_KUR

#if defined UTIL_PERCENT // some useless shit
	stock bool:UTIL_Percent(Float:fPercent)
	{
		return random(100) < fPercent
	}
#endif
