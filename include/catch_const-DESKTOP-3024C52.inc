#if defined _catch_const_included
	#endinput
#endif
#define _catch_const_included

#define CATCHMOD_VER "1.0.1-ReAPI"
#define MAXPLAYERSVAR MAX_PLAYERS + 1

enum Teams
{
	FLEER,
	CATCHER,
	TRAINING,
	NONE
}

stock g_szTeamsNames[Teams][MAXPLAYERSVAR] =
{
	"Fleer",
	"Catcher",
	"Training",
	"None"
}
