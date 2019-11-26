#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\killstreaks_shared;
#using scripts\shared\math_shared;
#using scripts\shared\rank_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\weapons_shared;
#using scripts\shared\weapons\_weapons;

#using scripts\shared\bots\_bot;
#using scripts\shared\bots\_bot_combat;
#using scripts\shared\bots\bot_traversals;
#using scripts\shared\bots\bot_buttons;
#using scripts\mp\bots\_bot_combat;
#using scripts\mp\bots\_bot_dom;
#using scripts\mp\bots\_bot_koth;
#using scripts\mp\bots\_bot_loadout;
#using scripts\mp\bots\_bot_sd;
#using scripts\mp\bots\_bot_ctf;
#using scripts\mp\killstreaks\_killstreakrules;
#using scripts\mp\killstreaks\_killstreaks;
#using scripts\mp\killstreaks\_uav;
#using scripts\mp\killstreaks\_satellite;
#using scripts\mp\killstreaks\_emp;
#using scripts\mp\teams\_teams;
#using scripts\mp\_util;

#insert scripts\shared\shared.gsh;
#insert scripts\mp\bots\_bot.gsh;

#define MAX_LOCAL_PLAYERS	10
#define MAX_ONLINE_PLAYERS	18
#define MAX_ONLINE_PLAYERS_PER_TEAM	6

#define RESPAWN_DELAY	0.1
#define RESPAWN_INTERVAL 0.1

#namespace bot;

REGISTER_SYSTEM( "bot_mp", &__init__, undefined )

function __init__()
{
	callback::on_start_gametype( &init );

	level.getBotSettings = &get_bot_settings;

	level.onBotConnect = &on_bot_connect;
	level.onBotSpawned = &on_bot_spawned;
	level.onBotKilled = &on_bot_killed;

	level.botIdle = &bot_idle;

	level.botThreatLost = &bot_combat::chase_threat;

	level.botPreCombat = &bot_combat::mp_pre_combat;
	level.botCombat = &bot_combat::combat_think;
	level.botPostCombat = &bot_combat::mp_post_combat;

	level.botIgnoreThreat = &bot_combat::bot_ignore_threat;

	level.enemyEmpActive = &emp::EnemyEmpActive;
}

function init()
{
	level endon( "game_ended" );

	level.botSoak = is_bot_soak();

	if ( ( level.rankedMatch && !level.botSoak ) || !init_bot_gametype() )
	{
		return;
	}

	wait_for_host();

	level thread populate_bots();
}

// Init Utils
//========================================

function is_bot_soak()
{
	return IsDedicated() && GetDvarInt( "sv_botsoak", 0 );
}

function wait_for_host()
{
	level endon( "game_ended" );

	if ( level.botSoak )
	{
		return;
	}

	host = util::getHostPlayerForBots();

	while ( !isdefined( host ) )
	{
		wait( 0.25 );
		host = util::getHostPlayerForBots();
	}
}

function get_host_team()
{
	host = util::getHostPlayerForBots();

	if ( !isdefined( host ) || host.team == "spectator" )
	{
		return "allies";
	}

	return host.team;
}

function is_bot_comp_stomp()
{
	return false;
}


// Bot Events
//========================================

function on_bot_connect()
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( IS_TRUE( level.disableClassSelection ) )
	{
		self set_rank();

		// Doesn't work if we don't do it in this order
		self bot_loadout::pick_hero_gadget();
		self bot_loadout::pick_killstreaks();

		return;
	}

	if ( !IS_TRUE( self.pers["bot_loadout"] ) )
	{
		self set_rank();

		// Doesn't work if we don't do it in this order
		self bot_loadout::build_classes();
		self bot_loadout::pick_hero_gadget();
		self bot_loadout::pick_killstreaks();

		self.pers["bot_loadout"] = true;
	}

	self bot_loadout::pick_classes();
	self choose_class();
}

function on_bot_spawned()
{
	self.bot.goalTag = undefined;
}

function on_bot_killed()
{
	self endon("disconnect");
	level endon( "game_ended" );
	self endon( "spawned" );
	self waittill ( "death_delay_finished" );

	wait RESPAWN_DELAY;

	if ( self choose_class() && level.playerForceRespawn )
	{
		return;
	}

	self thread respawn();
}

function respawn()
{
	self endon( "spawned" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	while( 1 )
	{
		self bot::tap_use_button();

		wait RESPAWN_INTERVAL;
	}
}

function bot_idle()
{
	if ( self do_supplydrop() )
	{
		return;
	}

	// TODO: Look for an enemy radar blip
	// TODO: Get points on navmesh and feed into the spawn system to see if an enemy is likely to spawn there
	self bot::navmesh_wander();
	self bot::sprint_to_goal();
}

// Crate maxs: 23.1482
#define CRATE_GOAL_RADIUS 39
#define CRATE_USE_RADIUS 62	// Wild guess on usable radius

function do_supplydrop( maxRange = 1400 ) // A little under minimap width
{
	crates = GetEntArray( "care_package", "script_noteworthy" );

	maxRangeSq = maxRange * maxRange;

	useRadiusSq = CRATE_USE_RADIUS * CRATE_USE_RADIUS;

	closestCrate = undefined;
	closestCrateDistSq = undefined;

	foreach( crate in crates )
	{
		if ( !crate IsOnGround() )
		{
			continue;
		}

		crateDistSq = Distance2DSquared( self.origin, crate.origin );

		if ( crateDistSq > maxRangeSq )
		{
			continue;
		}

		inUse = isdefined( crate.useEnt ) && IS_TRUE( crate.useEnt.inUse );

		if ( crateDistSq <= useRadiusSq )
		{
			if ( inUse && !self useButtonPressed() )
			{
				continue;
			}

			self bot::press_use_button();
			return true;
		}

		if ( !self has_minimap() && !self BotSightTracePassed( crate ) )
		{
			continue;
		}

		if ( !isdefined( closestCrate ) || crateDistSq < closestCrateDistSq )
		{
			closestCrate = crate;
			closestCrateDistSq = crateDistSq;
		}
	}

	if ( isdefined( closestCrate ) )
	{
		randomAngle = ( 0, RandomInt( 360 ), 0 );
		randomVec = AnglesToForward( randomAngle );

		point = closestCrate.origin + randomVec * CRATE_GOAL_RADIUS;

		if ( self BotSetGoal( point ) )
		{
			self thread watch_crate( closestCrate );
			return true;
		}
	}

	return false;
}

function watch_crate( crate )
{
	self endon( "death" );
	self endon( "bot_goal_reached" );
	level endon( "game_ended" );

	while ( isdefined( crate ) && !self bot_combat::has_threat() )
	{
		wait level.botSettings.thinkInterval;
	}

	self BotSetGoal( self.origin );
}

// Bot Team Population
//========================================

function populate_bots()
{
	level endon( "game_ended" );

	if ( level.teambased )
	{
		maxAllies = GetDvarInt( "bot_maxAllies", 0 );
		maxAxis = GetDvarInt( "bot_maxAxis", 0 );

		level thread monitor_bot_team_population( maxAllies, maxAxis );
	}
	else
	{
		maxFree = GetDvarInt( "bot_maxFree", 0 );

		level thread monitor_bot_population( maxFree );
	}
}

function monitor_bot_team_population( maxAllies, maxAxis )
{
	level endon( "game_ended" );

	if ( !maxAllies && !maxAxis )
	{
		return;
	}

	fill_balanced_teams( maxAllies, maxAxis );

	while ( 1 )
	{
		wait 3;

		// TODO: Get a player count that includes 'CON_CONNECTING' players
		allies = GetPlayers( "allies" );
		axis = GetPlayers( "axis" );

		if ( allies.size > maxAllies &&
		     remove_best_bot( allies ) )
		{
			continue;
		}

		if ( axis.size > maxAxis &&
			 remove_best_bot( axis ) )
		{
			continue;
		}

		if ( allies.size < maxAllies || axis.size < maxAxis )
		{
			add_balanced_bot( allies, maxAllies, axis, maxAxis );
		}
	}
}

function fill_balanced_teams( maxAllies, maxAxis )
{
	allies = GetPlayers( "allies" );
	axis = GetPlayers( "axis" );

	while ( ( allies.size < maxAllies || axis.size < maxAxis ) &&
	        add_balanced_bot( allies, maxAllies, axis, maxAxis ) )
	{
		WAIT_SERVER_FRAME;

		allies = GetPlayers( "allies" );
		axis = GetPlayers( "axis" );
	}
}

function add_balanced_bot( allies, maxAllies, axis, maxAxis )
{
	bot = undefined;

	if ( allies.size < maxAllies &&
	     ( allies.size <= axis.size || axis.size >= maxAxis ) )
    {
		bot = add_bot( "allies" );
    }
	else if ( axis.size < maxAxis )
	{
		bot = add_bot( "axis" );
	}

	return isdefined( bot );
}

function monitor_bot_population( maxFree )
{
	level endon( "game_ended" );

	if ( !maxFree )
	{
		return;
	}

	// Initial Fill
	players = GetPlayers( );
	while ( players.size < maxFree )
	{
		add_bot();
		WAIT_SERVER_FRAME;
		players = GetPlayers( );
	}

	while ( 1 )
	{
		wait 3;

		// TODO: Get a player count that includes 'CON_CONNECTING' players
		players = GetPlayers( );

		if ( players.size < maxFree )
		{
			add_bot();
		}
		else if ( players.size > maxFree )
		{
			remove_best_bot( players );
		}
	}
}

function remove_best_bot( players )
{
	bots = filter_bots( players );

	if ( !bots.size )
	{
		return false;
	}

	// Prefer non-combat bots
	bestBots = [];

	foreach( bot in bots )
	{
		// Don't kick bots in the process of connecting
		if ( bot.sessionstate == "spectator" )
		{
			continue;
		}

		if ( bot.sessionstate == "dead" || !bot bot_combat::has_threat() )
		{
			bestBots[bestBots.size] = bot;
		}
	}

	if ( bestBots.size )
	{
		remove_bot( bestBots[RandomInt( bestBots.size )] );
	}
	else
	{
		remove_bot( bots[RandomInt( bots.size )] );
	}

	return true;
}

// Bot Loadouts
//========================================

function choose_class()
{
	if ( IS_TRUE( level.disableClassSelection ) )
	{
		return false;
	}

	currClass = self bot_loadout::get_current_class();

	if ( !isdefined( currClass ) || RandomInt( 100 ) < VAL( level.botSettings.changeClassWeight, 0 ) )
	{
		classIndex = RandomInt( self.loadoutClasses.size );
		className = self.loadoutClasses[classIndex].name;
	}

	if ( !isdefined(className) || className === currClass )
	{
		return false;
	}

	self notify( "menuresponse", MENU_CHANGE_CLASS, className );

	return true;
}

// Killstreaks
//========================================

function use_killstreak()
{
	if ( !level.loadoutKillstreaksEnabled ||
	    self emp::EnemyEMPActive() )
	{
		return;
	}

	weapons = self GetWeaponsList();
	inventoryWeapon = self GetInventoryWeapon();

	foreach( weapon in weapons )
	{
		killstreak = killstreaks::get_killstreak_for_weapon( weapon );

		if ( !isdefined( killstreak ) )
		{
			continue;
		}

		if ( weapon != inventoryWeapon && !self GetWeaponAmmoClip( weapon )  )
		{
			continue;
		}

		if ( self killstreakrules::isKillstreakAllowed( killstreak, self.team ) )
		{
			useWeapon = weapon;
			break;
		}
	}

	if ( !isdefined( useWeapon ) )
	{
		return;
	}

	killstreak_ref = killstreaks::get_menu_name( killstreak );

	switch( killstreak_ref )
	{
		case "killstreak_uav":
		case "killstreak_counteruav":
		case "killstreak_satellite":
		case "killstreak_helicopter_player_gunner":
		case "killstreak_raps":
		case "killstreak_sentinel":
			self SwitchToWeapon( useWeapon );
		break;
	}
}


function has_radar()
{
	if ( level.teambased )
	{
		return ( uav::HasUAV( self.team ) || satellite::HasSatellite( self.team ) );
	}

	return ( uav::HasUAV( self.entnum ) || satellite::HasSatellite( self.entnum ) );
}

function has_minimap()
{
	if ( self IsEmpJammed() )
	{
		return false;
	}

	if ( IS_TRUE( level.hardcoreMode ) )
	{
		return self has_radar();
	}

	return true;
}

function get_enemies( on_radar )
{
	if ( !isdefined( on_radar ) )
	{
		on_radar = false;
	}

	enemies = self GetEnemies();

	if ( on_radar && !self has_radar() )
	{
		for ( i = 0; i < enemies.size; i++ )
		{
			if ( !isdefined( enemies[i].lastFireTime ) )
			{
				ArrayRemoveIndex( enemies, i );
				i--;
			}
			else if ( GetTime() - enemies[i].lastFireTime > 2000 )
			{
				ArrayRemoveIndex( enemies, i );
				i--;
			}
		}
	}

	return enemies;
}

function set_rank()
{
	players = GetPlayers();

	ranks = [];
	bot_ranks = [];
	human_ranks = [];

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] == self )
			continue;

		if ( isdefined( players[i].pers[ "rank" ] ) )
		{
			if ( players[i] util::is_bot() )
			{
				bot_ranks[ bot_ranks.size ] = players[i].pers[ "rank" ];
			}
			else
			{
				human_ranks[ human_ranks.size ] = players[i].pers[ "rank" ];
			}
		}
	}

	if( !human_ranks.size )
		human_ranks[ human_ranks.size ] = 10;

	human_avg = math::array_average( human_ranks );

	while ( bot_ranks.size + human_ranks.size < 5 )
	{
		// add some random ranks for better random number distribution
		r = human_avg + RandomIntRange( -5, 5 );
		rank = math::clamp( r, 0, level.maxRank );
		human_ranks[ human_ranks.size ] = rank;
	}

	ranks = ArrayCombine( human_ranks, bot_ranks, true, false );

	avg = math::array_average( ranks );
	s = math::array_std_deviation( ranks, avg );

	rank = Int( math::random_normal_distribution( avg, s, 0, level.maxRank ) );

	while ( !isdefined( self.pers["codpoints"] ) )
	{
		wait 0.1;
	}

	self.pers[ "rank" ] = rank;
	self.pers[ "rankxp" ] = rank::getRankInfoMinXP( rank );

	self setRank( rank );
	self rank::syncXPStat();
}

function init_bot_gametype()
{
	switch( level.gameType )
	{
		case "dm":
			return true;
		case "dom":
			bot_dom::init();
			return true;
		case "koth":
			bot_koth::init();
			return true;
		case "sd":
			bot_sd::init();
			return true;
		case "tdm":
			return true;
		default:
			return true;
	}

	return false;
}

function get_bot_settings()
{
	switch ( GetDvarInt( "bot_difficulty", 1 ) )
	{
		case 0:
			bundleName = "bot_mp_easy";
			break;

		case 1:
			bundleName = "bot_mp_normal";
			break;
		case 2:
			bundleName = "bot_mp_hard";
			break;
		case 3:
		default:
			bundleName = "bot_mp_veteran";
			break;
	}

	return struct::get_script_bundle( "botsettings", bundleName );
}

function friend_goal_in_radius( goal_name, origin, radius )
{
	return 0;
}

function friend_in_radius( goal_name, origin, radius )
{
	return false;
}

function get_friends()
{
	return [];
}

function get_closest_enemy( origin, someFlag )
{
	return undefined;
}

function bot_vehicle_weapon_ammo( weaponName )
{
	return false;
}

function navmesh_points_visible( origin, point )
{
	return false;
}

function dive_to_prone( exit_stance )
{

}

