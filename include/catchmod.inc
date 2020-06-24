#if defined _catchmod_included
	#endinput
#endif
#define _catchmod_included

#include <catch_const>

forward catchmod_round_end(iTeam)

native bool:catchmod_get_cantbesolid(id)
native catchmod_set_cantbesolid(id, bool:solid)

native catchmod_get_fleers()
native catchmod_get_catchers()

native Teams:catchmod_get_user_team(id)
native catchmod_set_user_team(id, Teams:iTeam)

native catchmod_get_user_turbo(id)
native catchmod_set_user_turbo(id, iTurbo)

native catchmod_get_user_defaultturbo(id, iTeam)
native catchmod_set_user_defaultturbo(id, iTeam, iTurbo)

native bool:catchmod_get_user_infiniteturbo(id)
native catchmod_set_user_infiniteturbo(id, bool:bOn)