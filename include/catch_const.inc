#if defined _catch_const_included
	#endinput
#endif
#define _catch_const_included

#define CATCHMOD_VER "4.0.3-ReAPI"
#define VALID_PLAYER(%1) 1 <= %1 <= 32

enum Teams
{
	FLEER,
	CATCHER,
	TRAINING,
	NONE
}

new g_szTeamsNames[Teams][32] =
{
	"Fleer",
	"Catcher",
	"Training",
	"None"
}