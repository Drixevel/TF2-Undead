/*
Hudsync bugs to look into.
*/

/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Undead Zombies"
#define PLUGIN_DESCRIPTION "Undead Zombies is a gamemode which pits players vs AI and player controlled zombies."
#define PLUGIN_VERSION "1.0.5"

#define PHASE_HIBERNATION 0
#define PHASE_STARTING 1
#define PHASE_WAITING 2
#define PHASE_ACTIVE 3
#define PHASE_ENDING 4

#define INTERACTABLE_TYPE_MACHINE 0
#define INTERACTABLE_TYPE_WEAPON 1
#define INTERACTABLE_TYPE_MYSTERYBOX 2
#define INTERACTABLE_TYPE_PLANK 3
#define INTERACTABLE_TYPE_BUILDING 4
#define INTERACTABLE_TYPE_DOORS 5

#define TEAM_ZOMBIES 2
#define TEAM_SURVIVORS 3

#define MAX_DIFFICULTIES 12
#define MAX_MACHINES 32
#define MAX_WEAPONS 128
#define MAX_POWERUPS 32
#define MAX_ZOMBIETYPES 32

#define LOBBY_TIME 60
#define MAX_POINTS 100000

#define PLANK_HEALTH 150
#define PLANK_COOLDOWN 30.0

#define POWERUP_CHANCE 25.0
#define POWERUP_COOLDOWN 16

#define ZOMBIE_DEFAULT "Common"

#define ZOMBIE_WAVE_TIMER_MIN 15.0
#define ZOMBIE_WAVE_TIMER_MAX 25.0

#define ZOMBIE_HIT_DISTANCE 75.0
#define ZOMBIE_FACE_DISTANCE 250.0

#define ZOMBIE_ATTACK_SPEED_MIN 0.4
#define ZOMBIE_ATTACK_SPEED_MAX 0.7

#define ZOMBIE_DAMAGE_MIN 15.0
#define ZOMBIE_DAMAGE_MAX 25.0

#define ZOMBIE_BASE_SPEED 150.0

#define INTERACT_SUCCESS 0
#define INTERACT_INSUFFICIENTFUNDS 1
#define INTERACT_MAXREACHED 2

#define SOUND_LOBBY "ui/quest_haunted_scroll_halloween.mp3"

#define STAT_KILLS "kills"
#define STAT_DEATHS "deaths"
#define STAT_REVIVES "revives"
#define STAT_MACHINES "machines_bought"
#define STAT_WEAPONS "weapons_bought"
#define STAT_MYSTERYBOXES "mysteryboxes_opened"
#define STAT_PLANKS "planks_rebuilt"
#define STAT_BUILDINGS "buildings_rented"
#define STAT_GAINED "points_gained"
#define STAT_SPENT "points_spent"
#define STAT_DAMAGE "damage"
#define STAT_WAVES "waves_won"
#define STAT_SPECIALS "specials_killed"
#define STAT_REVIVED "revived"
#define STAT_POWERUP "powerups_pickedup"
#define STAT_TEAMMATES "total_teammates"
#define STAT_DOORS "doors_opened"

/*****************************/
//Includes
#include <sourcemod>

#include <misc-sm>
#include <misc-tf>
#include <misc-colors>

#include <dhooks>
#include <cbasenpc>
#include <cbasenpc/util>
#include <customkeyvalues>
#include <tf2-items>
#include <tf_econ_data>

/*****************************/
//ConVars

ConVar convar_Ragdolls;
ConVar convar_BloodFx;

/*****************************/
//Globals
bool g_Late;
int g_GlowSprite;

Database g_Database;
int g_GlobalTarget = -1;

ArrayList statistics;
StringMap statisticsnames;

int g_InteractableType[MAX_ENTITY_LIMIT + 1]; //Types of Interactables
int g_WeaponIndex[MAX_ENTITY_LIMIT + 1] = {-1, ...}; //Weapon indexes
float g_RebuildDelay[MAX_ENTITY_LIMIT + 1] = {-1.0, ...}; //Planks
int g_PowerupIndex[MAX_ENTITY_LIMIT + 1] = {-1, ...}; //Powerup Index
int g_RechargeBuilding[MAX_ENTITY_LIMIT + 1] = {-1, ...}; //Buildings
int g_DisableBuilding[MAX_ENTITY_LIMIT + 1] = {-1, ...}; //Buildings

Handle g_BlockDispenserMetal;

StringMap g_PackaPunchUpgrades;

char sModels[10][PLATFORM_MAX_PATH] =
{
	"",
	"models/player/scout.mdl",
	"models/player/sniper.mdl",
	"models/player/soldier.mdl",
	"models/player/demo.mdl",
	"models/player/medic.mdl",
	"models/player/heavy.mdl",
	"models/player/pyro.mdl",
	"models/player/spy.mdl",
	"models/player/engineer.mdl"
};

char sZombieAttachments[10][PLATFORM_MAX_PATH] =
{
	"",
	"models/player/items/scout/scout_zombie.mdl",
	"models/player/items/sniper/sniper_zombie.mdl",
	"models/player/items/soldier/soldier_zombie.mdl",
	"models/player/items/demo/demo_zombie.mdl",
	"models/player/items/medic/medic_zombie.mdl",
	"models/player/items/heavy/heavy_zombie.mdl",
	"models/player/items/pyro/pyro_zombie.mdl",
	"models/player/items/spy/spy_zombie.mdl",
	"models/player/items/engineer/engineer_zombie.mdl"
};

char sRobotModels[10][PLATFORM_MAX_PATH] =
{
	"",
	"models/bots/scout/bot_scout.mdl",
	"models/bots/sniper/bot_sniper.mdl",
	"models/bots/soldier/bot_soldier.mdl",
	"models/bots/demo/bot_demo.mdl",
	"models/bots/medic/bot_medic.mdl",
	"models/bots/heavy/bot_heavy.mdl",
	"models/bots/pyro/bot_pyro.mdl",
	"models/bots/spy/bot_spy.mdl",
	"models/bots/engineer/bot_engineer.mdl",
};

char sBloodParticles[5][64] =
{
	"blood_impact_red_01",
	"blood_impact_red_01_chunk",
	"blood_impact_red_01_droplets",
	"blood_impact_red_01_goop",
	"blood_impact_red_01_smalldroplets",
};

char sHints[17][128] =
{
	"Revive your teammates by standing near their revive markers.",
	"Interact with weapons, machines, buildings and the mystery box by pressing 'MEDIC!' near them.",
	"Powerups sometimes drop when you kill zombies, pick them up to receive perks.",
	"Walk up to planks and press 'MEDIC!' to rebuild planks and gain points.",
	"Gain 10 points by hurting zombies and 100 points by killing zombies.",
	"Interact with a mystery box to gain a random weapon, press 'MEDIC!' once a weapon is chosen to pick it up... or not.",
	"The machine 'Quick Revive' perk allows you to revive players at double the speeds.",
	"The machine 'Speed Cola' perk allows you to reload and deploy your weapons faster.",
	"The machine 'Juggernog' perk allows you to double your health pool.",
	"The machine 'Packapunch' perk allows you to buff one specific weapons damage, fire rate, reload speed and reload speeds.",
	"The machine 'Staminup' perk allows you to buff your movement speed.",
	"The machine 'Deadshot' perk allows you to fire penetrating projectiles.",
	"The machine 'Doubletap' perk allows you to increase the amount of bullets fired in single shots.",
	"The powerup 'Double Points' allows you to gain double the points for 20 seconds.",
	"The powerup 'Instant Kill' allows you to instantly kill all zombies for 20 seconds.",
	"The powerup 'Nuke' allows you to instantly nuke all zombies into oblivion... until they come back.",
	"The powerup 'Max Ammo' allows you to refill all your weapons mags and ammunition.",
};

//Statistics
int g_TotalStatistics;
enum struct Statistics
{
	char name[64];
	char display[128];
	char table[64];

	void CreateStatistic(const char[] name, const char[] display, const char[] table)
	{
		strcopy(this.name, 64, name);
		strcopy(this.display, 128, display);
		strcopy(this.table, 64, table);
		g_TotalStatistics++;
	}
}

Statistics g_Statistics[32];

//Difficulty Data
enum struct Difficulty
{
	char name[64];
	float damage_multiplier;
	float health_multiplier;
	float points_multiplier;
	float revive_multiplier;
	float wavespawn_rate;
	float wavespawn_min;
	float wavespawn_max;
	float movespeed_multipler;
	int max_zombies;
	bool admin_only;
}

Difficulty g_Difficulty[MAX_DIFFICULTIES];
int g_TotalDifficulties;

//Match Data
enum struct Match
{
	int difficulty;
	int roundtime;
	Handle roundtimer;
	int roundphase;
	Hud hud_timer;
	int round;

	bool pausetimer;
	bool pausezombies;

	bool secret_door_unlocked;
	bool bomb_heads;
	bool spawn_robots;

	int powerups_cooldown;
	int coins_machine;

	void Init()
	{
		this.difficulty = GetDifficultyByName("Medium");
		this.roundtime = 0;
		this.roundtimer = null;
		this.roundphase = PHASE_HIBERNATION;
		this.hud_timer = null;
		this.round = 0;
		
		this.pausetimer = false;
		this.pausezombies = false;

		this.secret_door_unlocked = false;
		this.bomb_heads = false;
		this.spawn_robots = false;

		this.powerups_cooldown = -1;
		this.coins_machine = -1;
	}

	void Reset()
	{
		this.difficulty = GetDifficultyByName("Medium");
		this.roundtime = 0;
		StopTimer(this.roundtimer);
		this.roundphase = PHASE_HIBERNATION;
		StopTimer(this.hud_timer);
		this.round = 0;
		
		this.pausetimer = false;
		this.pausezombies = false;

		CloseBonusDoor();
		this.bomb_heads = false;
		this.spawn_robots = false;

		this.powerups_cooldown = -1;
		this.coins_machine = -1;

		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "entity_revive_marker")) != -1)
			AcceptEntityInput(entity, "Kill");

		int secret;

		if ((secret = FindEntityByName("secret_lock", "logic_relay")) != -1)
			AcceptEntityInput(secret, "Trigger");
		
		if ((secret = FindEntityByName("secret2_lock", "logic_relay")) != -1)
			AcceptEntityInput(secret, "Trigger");
		
		if ((secret = FindEntityByName("secret3_lock", "logic_relay")) != -1)
			AcceptEntityInput(secret, "Trigger");
	}

	void PauseZombies()
	{
		this.pausezombies = true;

		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_ZOMBIES)
				TF2_AddCondition(i, TFCond_FreezeInput);
	}

	void UnpauseZombies()
	{
		this.pausezombies = false;
		
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_ZOMBIES)
				TF2_RemoveCondition(i, TFCond_FreezeInput);
	}
}

Match g_Match;

//CustomWeapons
enum struct CustomWeapons
{
	int index;
	int price;
	int unlock;
	float particle;
	int ammocost;
	int ammoupgrade;
	
	void Reset()
	{
		this.index = -1;
		this.price = 0;
		this.unlock = -1;
		this.particle = -1.0;
		this.ammocost = -1;
		this.ammoupgrade = -1;
	}
}

CustomWeapons g_SpawnedWeapons[MAX_ENTITY_LIMIT + 1];

//Player Data
enum struct Player
{
	int client;
	int nearinteractable;

	int points;
	bool playing;
	int zombiekills;

	float sounds;
	int type;
	bool insidemap;
	int plank_target;
	float plank_damage_tick;
	char death_sound[PLATFORM_MAX_PATH];
	int particle;
	int building;

	int revivemarker;
	int glow;
	int wearable;

	int interact;
	float delayhint;

	int doublepoints;
	int instakill;

	int primary;
	int secondary;
	int melee;

	Handle regentimer;
	Handle punchanim;
	Handle revivetimer;

	ArrayList perks;
	StringMap stats;

	int firetotal;
	Handle firetimer;

	int bleedtotal;
	Handle bleedtimer;

	void Init(int client)
	{
		this.client = client;
		this.nearinteractable = -1;

		this.points = 500;
		this.playing = false;
		this.zombiekills = 0;

		this.sounds = -1.0;
		this.type = GetZombieTypeByName(ZOMBIE_DEFAULT);
		this.insidemap = false;
		this.plank_target = -1;
		this.plank_damage_tick = -1.0;
		this.death_sound[0] = '\0';
		this.particle = INVALID_ENT_REFERENCE;
		this.building = -1;

		this.revivemarker = INVALID_ENT_REFERENCE;
		this.glow = INVALID_ENT_REFERENCE;
		this.wearable = INVALID_ENT_REFERENCE;

		this.interact = -1;
		this.delayhint = -1.0;

		this.doublepoints = -1;
		this.instakill = -1;

		this.primary = -1;
		this.secondary = -1;
		this.melee = -1;

		this.firetotal = -1;
		this.bleedtotal = -1;

		StopTimer(this.regentimer);
		StopTimer(this.punchanim);
		StopTimer(this.revivetimer);

		StopTimer(this.firetimer);
		StopTimer(this.bleedtimer);

		delete this.perks;
		this.perks = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));

		delete this.stats;
		this.stats = new StringMap();
	}

	void Reset()
	{
		this.nearinteractable = -1;

		this.points = 500;
		this.playing = false;
		this.zombiekills = 0;

		this.sounds = -1.0;
		this.type = GetZombieTypeByName(ZOMBIE_DEFAULT);
		this.insidemap = false;
		this.plank_target = -1;
		this.plank_damage_tick = -1.0;
		this.death_sound[0] = '\0';

		this.interact = -1;
		this.delayhint = -1.0;

		this.doublepoints = -1;
		this.instakill = -1;

		this.primary = -1;
		this.secondary = -1;
		this.melee = -1;

		this.perks.Clear();
		this.stats.Clear();

		this.Clean(false);
	}

	void Clean(bool handles = true)
	{
		this.KillParticle();
		this.ClearGlow();
		this.KillBuilding();
		this.ClearFire();
		this.ClearBleed();

		StopTimer(this.regentimer);
		StopTimer(this.punchanim);

		if (handles)
		{
			delete this.perks;
			delete this.stats;
		}
	}

	void Clear()
	{
		this.client = -1;
		this.nearinteractable = -1;

		this.points = 500;
		this.playing = false;
		this.zombiekills = 0;

		this.sounds = -1.0;
		this.type = -1;
		this.insidemap = false;
		this.plank_target = -1;
		this.plank_damage_tick = -1.0;
		this.death_sound[0] = '\0';
		this.particle = INVALID_ENT_REFERENCE;
		this.building = -1;

		this.revivemarker = INVALID_ENT_REFERENCE;
		this.glow = INVALID_ENT_REFERENCE;
		this.wearable = INVALID_ENT_REFERENCE;

		this.interact = -1;
		this.delayhint = -1.0;

		this.doublepoints = -1;
		this.instakill = -1;

		this.primary = -1;
		this.secondary = -1;
		this.melee = -1;

		this.regentimer = null;
		this.punchanim = null;
		this.revivetimer = null;

		this.perks = null;
		this.stats = null;

		this.firetotal = 0;
		this.firetimer = null;

		this.bleedtotal = 0;
		this.bleedtimer = null;
	}

	//attached particles
	int AttachParticle(const char[] particle, float time = 0.0, const char[] attachment)
	{
		this.KillParticle();
		this.particle = EntIndexToEntRef(AttachParticle(this.client, particle, time, attachment));
		return this.particle;
	}

	void KillParticle()
	{
		if (this.particle != INVALID_ENT_REFERENCE && IsValidEntity(this.particle))
			AcceptEntityInput(this.particle, "Kill");
		
		this.particle = INVALID_ENT_REFERENCE;
	}

	//glows for zombies
	int CreateGlow()
	{
		this.ClearGlow();

		int entity = TF2_AttachBasicGlow(this.client);
		SDKHook(entity, SDKHook_SetTransmit, OnGlowTransmit);

		this.glow = EntIndexToEntRef(entity);
		return this.glow;
	}

	void ClearGlow()
	{
		if (this.glow != INVALID_ENT_REFERENCE && IsValidEntity(this.glow))
			AcceptEntityInput(this.glow, "Kill");
		
		this.glow = INVALID_ENT_REFERENCE;
	}

	//statistics
	int GetStat(const char[] stat)
	{
		int value;
		this.stats.GetValue(stat, value);
		return value;
	}

	bool SetStat(const char[] stat, int value)
	{
		if (this.stats == null)
			this.stats = new StringMap();
		
		this.stats.SetValue(stat, value);
	}

	bool AddStat(const char[] stat, int value)
	{
		if (this.stats == null)
			this.stats = new StringMap();
		
		int base;
		this.stats.GetValue(stat, base);
		
		this.stats.SetValue(stat, (base + value));
	}

	bool SubStat(const char[] stat, any value)
	{
		if (this.stats == null)
			this.stats = new StringMap();
		
		any base;
		this.stats.GetValue(stat, base);
		
		this.stats.SetValue(stat, (base - value));
	}

	void ResetStats()
	{
		this.stats.Clear();
	}

	//points
	void SetPoints(int value)
	{
		this.points = value;
	}

	void AddPoints(int value, bool update_stat = true)
	{
		int add = RoundFloat(float(value) * g_Difficulty[g_Match.difficulty].points_multiplier);
		this.points += add;

		if (this.points > MAX_POINTS)
			this.points = MAX_POINTS;

		this.AddStat(STAT_GAINED, add);
	}

	bool RemovePoints(int value)
	{
		if (this.points < value)
			return false;
		
		this.points -= value;

		this.AddStat(STAT_SPENT, value);
		return true;
	}
	
	//perks
	void AddPerk(const char[] name)
	{
		this.perks.PushString(name);
		this.ApplyPerk(name);
	}

	bool HasPerk(const char[] name)
	{
		int max = GetMachineMax(name);

		if (max > 0 && this.GetPerkCount(name) >= max)
			return true;
		
		return false;
	}

	int GetPerkCount(const char[] name)
	{
		int count;

		char sName[64];
		for (int i = 0; i < this.perks.Length; i++)
		{
			this.perks.GetString(i, sName, sizeof(sName));

			if (StrEqual(sName, name, false))
				count++;
		}

		return count;
	}

	void ApplyPerks(bool noanims = false)
	{
		if (!IsClientInGame(this.client) || !IsPlayerAlive(this.client))
			return;
		
		char sPerk[MAX_NAME_LENGTH];
		for (int i = 0; i < this.perks.Length; i++)
		{
			this.perks.GetString(i, sPerk, sizeof(sPerk));
			this.ApplyPerk(sPerk, noanims);
		}
	}

	void ApplyPerk(const char[] name, bool noanims = false)
	{
		if (!IsClientInGame(this.client) || !IsPlayerAlive(this.client))
			return;

		if (StrEqual(name, "speedcola", false))
		{
			TF2Attrib_SetByName(this.client, "Reload time decreased", 0.70);
			TF2Attrib_SetByName(this.client, "deploy time decreased", 0.70);
		}
		else if (StrEqual(name, "juggernog", false))
		{
			SetEntityHealth(this.client, 300);
		}
		else if (StrEqual(name, "packapunch", false))
		{
			int weapon = GetActiveWeapon(this.client);

			if (IsValidEntity(weapon))
			{
				char sEntity[64];
				IntToString(weapon, sEntity, sizeof(sEntity));

				int value;
				g_PackaPunchUpgrades.GetValue(sEntity, value);

				if (value < 4)
				{
					value++;
					g_PackaPunchUpgrades.SetValue(sEntity, value);

					Address attr;
					if ((attr = TF2Attrib_GetByName(weapon, "damage bonus")) != Address_Null)
						TF2Attrib_SetByName(weapon, "damage bonus", TF2Attrib_GetValue(attr) + 0.15);
					else
						TF2Attrib_SetByName(weapon, "damage bonus", 1.15);
					
					TF2Attrib_SetFireRateBonus(weapon, 0.07);

					if ((attr = TF2Attrib_GetByName(weapon, "Reload time decreased")) != Address_Null)
						TF2Attrib_SetByName(weapon, "Reload time decreased", TF2Attrib_GetValue(attr) - 0.15);
					else
						TF2Attrib_SetByName(weapon, "Reload time decreased", 0.85);
					
					TF2Attrib_SetByDefIndex(weapon, 134, g_SpawnedWeapons[weapon].particle);

					TF2Items_RefillMag(weapon);
					TF2Items_RefillAmmo(this.client, weapon);

					if (!noanims)
						ActivateAnimation(this.client, "packapunch", weapon);
				}
			}
		}
		else if (StrEqual(name, "staminup", false))
		{
			TF2Attrib_SetByName(this.client, "move speed bonus", 1.70);
			TF2_AddCondition(this.client, TFCond_SpeedBuffAlly, 1.0);
		}
		else if (StrEqual(name, "deadshot", false))
		{
			int weapon = -1;
			for (int x = 0; x < 5; x++)
			{
				if ((weapon = GetPlayerWeaponSlot(this.client, x)) == -1)
					continue;
				
				TF2Attrib_SetByName(weapon, "projectile penetration", 1.0);
				TF2Attrib_SetByName(weapon, "energy weapon penetration", 1.0);
				TF2Attrib_SetByName(weapon, "projectile penetration heavy", 1.0);
			}
		}
		else if (StrEqual(name, "doubletap", false))
		{
			int weapon = -1;
			for (int x = 0; x < 5; x++)
			{
				if ((weapon = GetPlayerWeaponSlot(this.client, x)) == -1)
					continue;
				
				TF2Attrib_SetFireRateBonus(weapon, 0.03);
				TF2Attrib_SetByName(weapon, "bullets per shot bonus", 2.0);
			}
		}
	}

	void ClearPerks()
	{
		this.perks.Clear();
	}

	//regen timer
	void RegenTimer(float time = 4.0)
	{
		StopTimer(this.regentimer);
		this.regentimer = CreateTimer(time, Timer_Regen, this.client, TIMER_FLAG_NO_MAPCHANGE);
	}

	//death sounds
	void AddDeathSound(const char[] sound)
	{
		strcopy(this.death_sound, PLATFORM_MAX_PATH, sound);
	}

	//attached building
	int AttachBuilding(const char[] entity, float origin[3])
	{
		this.KillBuilding();	
		this.building = CreateEntityByName(entity);
		
		if (IsValidEntity(this.building))
		{
			origin[0] -= 20.0;
			//origin[1] -= 150.0;
			origin[2] += 15.0;

			DispatchKeyValueVector(this.building, "origin", origin);
			//DispatchKeyValueVector(this.building, "angles", Angle);
			DispatchKeyValue(this.building, "defaultupgrade", "0");
			DispatchKeyValue(this.building, "spawnflags", "4");
			SetEntProp(this.building, Prop_Send, "m_bBuilding", 1);
			DispatchSpawn(this.building);

			int team = GetClientTeam(this.client);

			SetVariantInt(team);
			AcceptEntityInput(this.building, "SetTeam");
			SetEntProp(this.building, Prop_Send, "m_nSkin", team - 2);
			
			ActivateEntity(this.building);

			SetVariantString("!activator");
			AcceptEntityInput(this.building, "SetParent", this.client);

			SetVariantString("flag");
			AcceptEntityInput(this.building, "SetParentAttachmentMaintainOffset");

			SetEntProp(this.building, Prop_Send, "m_bDisabled", 1);
		}
	}

	void KillBuilding()
	{
		if (IsValidEntity(this.building))
			AcceptEntityInput(this.building, "Kill");
		
		this.building = -1;
	}

	//set on fire
	void SetOnFire(float ticks = 1.0, int total = 6)
	{
		if (!IsPlayerAlive(this.client))
			return;
		
		this.firetotal = total;
		StopTimer(this.firetimer);
		this.firetimer = CreateTimer(ticks, Timer_SetOnFire, this.client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(this.firetimer);
		EmitGameSoundToAll("Fire.Engulf", this.client);
	}

	void ClearFire()
	{
		this.firetotal = -1;
		StopTimer(this.firetimer);
	}

	//bleed target
	void Bleed(float ticks = 1.0, int total = 6)
	{
		if (!IsPlayerAlive(this.client))
			return;
		
		this.bleedtotal = total;
		StopTimer(this.bleedtimer);
		this.bleedtimer = CreateTimer(ticks, Timer_BleedClient, this.client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(this.bleedtimer);
		EmitGameSoundToAll("Weapon_Knife.HitFlesh", this.client);
	}

	void ClearBleed()
	{
		this.bleedtotal = -1;
		StopTimer(this.bleedtimer);
	}
}

Player g_Player[MAXPLAYERS + 1];

public Action Timer_Regen(Handle timer, any data)
{
	int victim = data;
	g_Player[victim].regentimer = null;

	if (IsClientInGame(victim) && IsPlayerAlive(victim))
		SetEntityHealth(victim, g_Player[victim].HasPerk("juggernog") ? 300 : 150);
}

public Action Timer_SetOnFire(Handle timer, any data)
{
	int client = data;

	g_Player[client].firetotal--;

	if (g_Player[client].firetotal <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_SURVIVORS)
	{
		g_Player[client].firetimer = null;
		return Plugin_Stop;
	}

	float origin[3];
	GetClientEyePosition(client, origin);

	AttachParticle(client, "buildingdamage_dispenser_fire1", 1.0, "flag");
	SDKHooks_TakeDamage(client, 0, 0, 15.0, DMG_BURN);
	EmitGameSoundToAll("General.BurningFlesh", client);
	g_Player[client].RegenTimer();

	return Plugin_Continue;
}

public Action Timer_BleedClient(Handle timer, any data)
{
	int client = data;

	g_Player[client].bleedtotal--;

	if (g_Player[client].bleedtotal <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_SURVIVORS)
	{
		g_Player[client].bleedtimer = null;
		return Plugin_Stop;
	}

	float origin[3];
	GetClientEyePosition(client, origin);

	AttachParticle(client, "blood_impact_red_01", 1.0, "flag");
	SDKHooks_TakeDamage(client, 0, 0, 10.0, DMG_SLASH);
	g_Player[client].RegenTimer();

	return Plugin_Continue;
}

//Zombies
enum struct Zombies
{
	int entity;
	int class;
	int type;
	float speed;
	ChasePath pPath;
	float lastattack;
	int target;
	int planktarget;
	float sounds;
	bool insidemap;
	int plank_target;
	float plank_damage_tick;
	char death_sound[PLATFORM_MAX_PATH];

	void Reset()
	{
		this.entity = -1;
		this.class = -1;
		this.type = GetZombieTypeByName(ZOMBIE_DEFAULT);
		this.speed = 0.0;
		this.lastattack = -1.0;
		this.target = -1;
		this.planktarget = -1;
		this.sounds = -1.0;
		this.insidemap = false;
		this.plank_target = -1;
		this.plank_damage_tick = -1.0;
		this.death_sound[0] = '\0';
	}

	void AddDeathSound(const char[] sound)
	{
		strcopy(this.death_sound, PLATFORM_MAX_PATH, sound);
	}

	void PlayStepSound(const char[] sound, float vPosition[3])
	{
		int[] clients = new int[MaxClients];
		int total = 0;
		
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				clients[total++] = i;
		
		if (!total)
			return;
		
		int channel;
		int level;
		float volume;
		int pitch;
		char sample[PLATFORM_MAX_PATH];
		
		if (GetGameSoundParams(sound, channel, level, volume, pitch, sample, sizeof(sample), this.entity))
		{
			PrecacheSound(sample);
			EmitSound(clients, total, sample, this.entity, channel, level, _, volume, pitch, .origin = vPosition);
			
			//PrintToServer("%i PlayStepSound(\"%s\")", this.entity, sound);
		}
		else
		{
			//PrintToServer("%i PlayStepSound(\"%s\") FAILED", this.entity, sound);
		}
	}
}

Zombies g_Zombies[MAX_NPCS];

//Waves Timer
int g_WaveTime;
Handle g_WaveTimer;

Hud g_Sync_NearInteractable;

//MachinesData
enum struct MachinesData
{
	char name[64];
	char display[64];
	char description[128];
	char model[PLATFORM_MAX_PATH];
	float z_offset;
	int max;
}

MachinesData g_MachinesData[MAX_MACHINES];
int g_TotalMachines;

//Machines
enum struct Machines
{
	int entity;
	int index;
	int price;
	int unlock;
	int glow;
	Handle soundtimer;
	
	void Reset()
	{
		this.entity = -1;
		this.index = -1;
		this.price = 0;
		this.unlock = -1;
		this.glow = -1;

		StopTimer(this.soundtimer);
	}

	void StartSound()
	{
		StopTimer(this.soundtimer);
		this.soundtimer = CreateTimer(1.0, Timer_PlaySound, this.entity, TIMER_REPEAT);
	}

	void StopSound()
	{
		StopTimer(this.soundtimer);
	}
}

Machines g_Machines[MAX_ENTITY_LIMIT + 1];

public Action Timer_PlaySound(Handle timer, any data)
{
	int entity = data;
	EmitSoundToAll(g_Machines[entity].index == GetMachine("packapunch") ? "undead/machines/packapunchhum.wav" : "undead/machines/perkmachinehum.wav", entity);
}

//CustomWeaponsData
enum struct CustomWeaponsData
{
	char name[64];
	float offset_angles[3];
	bool mystery_box;
}

CustomWeaponsData g_CustomWeapons[MAX_WEAPONS];
int g_TotalCustomWeapons;

//mysterybox
enum struct MysteryBox
{
	bool status;
	int price;
	bool inuse;
	int glow;
	int unlock;

	void Reset()
	{
		this.status = false;
		this.price = 0;
		this.inuse = false;
		this.glow = -1;
		this.unlock = -1;
	}
}

MysteryBox g_MysteryBox[MAX_ENTITY_LIMIT + 1];

//Powerups
enum struct Powerups
{
	char name[64];
	char description[128];
	char model[PLATFORM_MAX_PATH];
	char sound[PLATFORM_MAX_PATH];
	float timer;
}

Powerups g_Powerups[MAX_POWERUPS];
int g_TotalPowerups;

//Special Zombies
enum struct ZombieTypes
{
	char name[64];
	char description[128];
	int health;
	int class;
	int team;
	float size;
	float speed;
	int color[4];
	char spawn_sound[PLATFORM_MAX_PATH];
	char death_sound[PLATFORM_MAX_PATH];
	char particle[64];
	int unlock_wave;
}

ZombieTypes g_ZombieTypes[MAX_ZOMBIETYPES];
int g_TotalZombieTypes;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Late = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	CSetPrefix("{haunted}[{lawngreen}Undead{haunted}]");
	Database.Connect(OnSQLConnect, "default");

	//ConVars
	convar_Ragdolls = CreateConVar("sm_undead_ragdolls", "1", "Should ragdolls be enabled for ai zombies?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_BloodFx = CreateConVar("sm_undead_bloodfx", "1", "Should ai zombies display blood effects on damaged?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegAdminCmd("sm_testanim", Command_TestAnim, ADMFLAG_ROOT);
	RegAdminCmd("sm_waveinfo", Command_WaveInfo, ADMFLAG_ROOT);
	
	RegConsoleCmd("sm_mainmenu", Command_MainMenu);
	RegConsoleCmd("sm_gamemode", Command_MainMenu);
	RegConsoleCmd("sm_undead", Command_MainMenu);

	RegConsoleCmd("sm_undeadstats", Command_Statistics);

	RegConsoleCmd("sm_difficulty", Command_Difficulty);
	RegConsoleCmd("sm_setdifficulty", Command_Difficulty);
	RegConsoleCmd("sm_votedifficulty", Command_VoteDifficulty);

	RegAdminCmd("sm_round", Command_SetRound, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setround", Command_SetRound, ADMFLAG_GENERIC);
	RegAdminCmd("sm_wave", Command_SetRound, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setwave", Command_SetRound, ADMFLAG_GENERIC);

	RegAdminCmd("sm_zombie", Command_SpawnZombie, ADMFLAG_GENERIC);
	RegAdminCmd("sm_zombies", Command_SpawnZombie, ADMFLAG_GENERIC);
	RegAdminCmd("sm_spawnzombie", Command_SpawnZombie, ADMFLAG_GENERIC);
	RegAdminCmd("sm_spawnzombies", Command_SpawnZombie, ADMFLAG_GENERIC);

	RegAdminCmd("sm_killzombie", Command_KillZombie, ADMFLAG_GENERIC);
	RegAdminCmd("sm_killallzombies", Command_KillAllZombies, ADMFLAG_GENERIC);

	RegAdminCmd("sm_randomzombie", Command_RandomZombie, ADMFLAG_GENERIC);
	RegAdminCmd("sm_spawnwave", Command_SpawnWave, ADMFLAG_GENERIC);
	RegAdminCmd("sm_target", Command_Target, ADMFLAG_GENERIC);

	RegAdminCmd("sm_start", Command_StartMatch, ADMFLAG_GENERIC);
	RegAdminCmd("sm_startmatch", Command_StartMatch, ADMFLAG_GENERIC);
	RegAdminCmd("sm_startgame", Command_StartMatch, ADMFLAG_GENERIC);

	RegAdminCmd("sm_pause", Command_PauseTimer, ADMFLAG_GENERIC);
	RegAdminCmd("sm_pausetimer", Command_PauseTimer, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unpause", Command_UnpauseTimer, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unpausetimer", Command_UnpauseTimer, ADMFLAG_GENERIC);
	RegAdminCmd("sm_resume", Command_UnpauseTimer, ADMFLAG_GENERIC);

	RegAdminCmd("sm_pausezombies", Command_PauseZombies, ADMFLAG_GENERIC);
	RegAdminCmd("sm_freezezombies", Command_PauseZombies, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unpausezombies", Command_UnpauseZombies, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unfreezezombies", Command_UnpauseZombies, ADMFLAG_GENERIC);

	RegAdminCmd("sm_addpoints", Command_AddPoints, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setpoints", Command_SetPoints, ADMFLAG_GENERIC);

	RegAdminCmd("sm_powerup", Command_SpawnPowerup, ADMFLAG_GENERIC);
	RegAdminCmd("sm_powerups", Command_SpawnPowerup, ADMFLAG_GENERIC);
	RegAdminCmd("sm_spawnpowerup", Command_SpawnPowerup, ADMFLAG_GENERIC);

	RegAdminCmd("sm_perks", Command_Machines, ADMFLAG_GENERIC);
	RegAdminCmd("sm_machines", Command_Machines, ADMFLAG_GENERIC);

	RegAdminCmd("sm_setangles", Command_SetAngles, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setanglesnear", Command_SetAnglesNear, ADMFLAG_GENERIC);

	RegAdminCmd("sm_synclobby", Command_SyncLobby, ADMFLAG_GENERIC);

	RegAdminCmd("sm_debugweapons", Command_DebugWeapons, ADMFLAG_ROOT);
	RegAdminCmd("sm_nextweapon", Command_NextWeapons, ADMFLAG_ROOT);
	RegAdminCmd("sm_stopdebugweapons", Command_StopDebugWeapons, ADMFLAG_ROOT);

	RegAdminCmd("sm_setzombietype", Command_SetZombieType, ADMFLAG_ROOT);

	RegAdminCmd("sm_reloadconfigs", Command_ReloadConfigs, ADMFLAG_ROOT);

	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);

	Handle hGameConf = LoadGameConfigFile("undead.gamedata");

	int offset = GameConfGetOffset(hGameConf, "CObjectDispenser::DispenseMetal");

	delete hGameConf;

	g_BlockDispenserMetal = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, DispenseMetal);
	DHookAddParam(g_BlockDispenserMetal, HookParamType_CBaseEntity, _, DHookPass_ByRef);

	g_PackaPunchUpgrades = new StringMap();

	g_Sync_NearInteractable = new Hud();

	statistics = new ArrayList(ByteCountToCells(128));
	statistics.PushString(STAT_KILLS);
	statistics.PushString(STAT_DEATHS);
	statistics.PushString(STAT_REVIVES);
	statistics.PushString(STAT_MACHINES);
	statistics.PushString(STAT_WEAPONS);
	statistics.PushString(STAT_MYSTERYBOXES);
	statistics.PushString(STAT_PLANKS);
	statistics.PushString(STAT_BUILDINGS);
	statistics.PushString(STAT_GAINED);
	statistics.PushString(STAT_SPENT);
	statistics.PushString(STAT_DAMAGE);
	statistics.PushString(STAT_WAVES);
	statistics.PushString(STAT_SPECIALS);
	statistics.PushString(STAT_REVIVED);
	statistics.PushString(STAT_POWERUP);
	statistics.PushString(STAT_TEAMMATES);
	statistics.PushString(STAT_DOORS);

	statisticsnames = new StringMap();
	statisticsnames.SetString(STAT_KILLS, "Total Kills");
	statisticsnames.SetString(STAT_DEATHS, "Total Deaths");
	statisticsnames.SetString(STAT_REVIVES, "Revives Done");
	statisticsnames.SetString(STAT_MACHINES, "Machines Unlocked");
	statisticsnames.SetString(STAT_WEAPONS, "Weapons Picked Up");
	statisticsnames.SetString(STAT_MYSTERYBOXES, "Mystery Box Openings");
	statisticsnames.SetString(STAT_PLANKS, "Planks Rebuilt");
	statisticsnames.SetString(STAT_BUILDINGS, "Buildings Unlocked");
	statisticsnames.SetString(STAT_GAINED, "Points Gained Total");
	statisticsnames.SetString(STAT_SPENT, "Points Spent Total");
	statisticsnames.SetString(STAT_DAMAGE, "Damage Dealt to Enemies");
	statisticsnames.SetString(STAT_WAVES, "Waves Survived");
	statisticsnames.SetString(STAT_SPECIALS, "Special Zombies Killed");
	statisticsnames.SetString(STAT_REVIVED, "Revived By Teammates");
	statisticsnames.SetString(STAT_POWERUP, "Powerups Received");
	statisticsnames.SetString(STAT_TEAMMATES, "Teammates Gained");
	statisticsnames.SetString(STAT_DOORS, "Doors Opened");

	//TODO: Use this instead.
	g_TotalStatistics = 0;
	g_Statistics[g_TotalStatistics].CreateStatistic("Kills", "Total Kills", "kills");
	g_Statistics[g_TotalStatistics].CreateStatistic("Deaths", "Total Deaths", "deaths");
	g_Statistics[g_TotalStatistics].CreateStatistic("Revives", "Revives Done", "revives");
	g_Statistics[g_TotalStatistics].CreateStatistic("Machines Bought", "Machines Unlocked", "machines_bought");
	g_Statistics[g_TotalStatistics].CreateStatistic("Weapons Bought", "Weapons Picked Up", "weapons_bought");
	g_Statistics[g_TotalStatistics].CreateStatistic("Mysteryboxes Bought", "Mystery Box Openings", "mysteryboxes_opened");
	g_Statistics[g_TotalStatistics].CreateStatistic("Planks Rebuilt", "Planks Rebuilt", "planks_rebuilt");
	g_Statistics[g_TotalStatistics].CreateStatistic("Buildings Rented", "Buildings Unlocked", "buildings_rented");
	g_Statistics[g_TotalStatistics].CreateStatistic("Points Gained", "Points Gained Total", "points_gained");
	g_Statistics[g_TotalStatistics].CreateStatistic("Points Spent", "Points Spent Total", "points_spent");
	g_Statistics[g_TotalStatistics].CreateStatistic("Damage", "Damage Dealt to Enemies", "damage");
	g_Statistics[g_TotalStatistics].CreateStatistic("Waves Won", "Waves Survived", "waves_won");
	g_Statistics[g_TotalStatistics].CreateStatistic("Specials Killed", "Special Zombies Killed", "specials_killed");
	g_Statistics[g_TotalStatistics].CreateStatistic("Revived", "Revived By Teammates", "revived");
	g_Statistics[g_TotalStatistics].CreateStatistic("Powerups Pickedup", "Powerups Received", "powerups_pickedup");
	g_Statistics[g_TotalStatistics].CreateStatistic("Total Teammates", "Teammates Gained", "total_teammates");
	g_Statistics[g_TotalStatistics].CreateStatistic("Doors Opened", "Doors Unlocked", "doors_opened");

	for (int i = 0; i < MAX_NPCS; i++)
		g_Zombies[i].pPath = ChasePath(LEAD_SUBJECT, INVALID_FUNCTION, Path_FilterIgnoreActors, Path_FilterOnlyActors);

	ParseDifficulties();
	ParseMachines();
	ParseWeapons();
	ParsePowerups();
	ParseSpecials();

	int entity = -1; char class[64];
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
		if (GetEntityClassname(entity, class, sizeof(class)))
			OnEntityCreated(entity, class);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
			OnClientConnected(i);
		
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}

	AddNormalSoundHook(OnSoundPlay);
	HookEntityOutput("logic_relay", "OnTrigger", OnRelayTrigger);

	g_Match.Init();
	g_Match.hud_timer = new Hud();

	ConVar nb_update_frequency = FindConVar("nb_update_frequency");
	nb_update_frequency.FloatValue = 0.01;
	HookConVarChange(nb_update_frequency, Hook_BlockCvarValue);
	
	CreateTimer(0.6, Timer_ZombieTicks, _, TIMER_REPEAT);
}

void ParseDifficulties()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/undead/difficulties.cfg");

	KeyValues kv = new KeyValues("difficulties");

	if (kv.ImportFromFile(sPath) && kv.GotoFirstSubKey())
	{
		g_TotalDifficulties = 0;

		do
		{
			kv.GetSectionName(g_Difficulty[g_TotalDifficulties].name, 64);
			g_Difficulty[g_TotalDifficulties].damage_multiplier = kv.GetFloat("damage_multiplier");
			g_Difficulty[g_TotalDifficulties].health_multiplier = kv.GetFloat("health_multiplier");
			g_Difficulty[g_TotalDifficulties].points_multiplier = kv.GetFloat("points_multiplier");
			g_Difficulty[g_TotalDifficulties].revive_multiplier = kv.GetFloat("revive_multiplier");
			g_Difficulty[g_TotalDifficulties].wavespawn_rate = kv.GetFloat("wavespawn_rate");
			g_Difficulty[g_TotalDifficulties].wavespawn_min = kv.GetFloat("wavespawn_min");
			g_Difficulty[g_TotalDifficulties].wavespawn_max = kv.GetFloat("wavespawn_max");
			g_Difficulty[g_TotalDifficulties].movespeed_multipler = kv.GetFloat("movespeed_multipler");
			g_Difficulty[g_TotalDifficulties].max_zombies = kv.GetNum("max_zombies");
			g_Difficulty[g_TotalDifficulties].admin_only = view_as<bool>(kv.GetNum("admin_only"));
			g_TotalDifficulties++;
		}
		while (kv.GotoNextKey());
	}

	delete kv;
	LogMessage("Difficulties Loaded: %i", g_TotalDifficulties);
}

public void OnSQLConnect(Database db, const char[] error, any data)
{
	if (db == null)
		ThrowError("Error while connecting to database: %s", error);
	
	if (g_Database != null)
	{
		delete db;
		return;
	}

	g_Database = db;
	LogMessage("Connected to database successfully.");

	g_Database.Query(OnCreateTable, "CREATE TABLE IF NOT EXISTS `undead_statistics` ( `id` INT NOT NULL AUTO_INCREMENT , `steamid` VARCHAR(64) NOT NULL , `server` VARCHAR(64) NOT NULL , `team` INT NOT NULL , `difficulty` VARCHAR(64) NOT NULL , `kills` INT NOT NULL , `deaths` INT NOT NULL , `revives` INT NOT NULL , `machines_bought` INT NOT NULL , `weapons_bought` INT NOT NULL , `mysteryboxes_opened` INT NOT NULL , `planks_rebuilt` INT NOT NULL , `buildings_rented` INT NOT NULL , `points_gained` INT NOT NULL , `points_spent` INT NOT NULL , `damage` INT NOT NULL , `waves_won` INT NOT NULL , `specials_killed` INT NOT NULL , `revived` INT NOT NULL , `powerups_pickedup` INT NOT NULL , `total_teammates` INT NOT NULL , `doors_opened` INT NOT NULL , PRIMARY KEY (`id`)) ENGINE = InnoDB;");
}

public void OnCreateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while creating statistics table: %s", error);
}

public Action OnRelayTrigger(const char[] output, int caller, int activator, float delay)
{
	char sName[64];
	GetEntPropString(caller, Prop_Data, "m_iName", sName, sizeof(sName));

	if (StrContains(sName, "secret_unlock", false) != -1)
		g_Match.spawn_robots = true;
	else if (StrContains(sName, "secret_lock", false) != -1)
		g_Match.spawn_robots = false;
	else if (StrContains(sName, "secret2_unlock", false) != -1)
		g_Match.bomb_heads = true;
	else if (StrContains(sName, "secret2_lock", false) != -1)
		g_Match.bomb_heads = false;
	/*else if (StrContains(sName, "secret3_unlock", false) != -1)
		g_Match.bomb_heads = true;
	else if (StrContains(sName, "secret3_lock", false) != -1)
		g_Match.bomb_heads = false;*/
}

public void Hook_BlockCvarValue(ConVar convar, const char[] oldValue, const char[] newValue)
{
	float flnewvalue = StringToFloat(newValue);
	
	if (flnewvalue > 0.01)
		convar.FloatValue = 0.01;
	else
		convar.FloatValue = flnewvalue;
}

public Action Command_SetAngles(int client, int args)
{
	int target = GetClientAimTarget(client, false);

	if (target == -1)
	{
		CPrintToChat(client, "Target not found, please aim your crosshair.");
		return Plugin_Handled;
	}

	float vecAngles[3];
	vecAngles[0] = GetCmdArgFloat(1);
	vecAngles[1] = GetCmdArgFloat(2);
	vecAngles[2] = GetCmdArgFloat(3);

	TeleportEntity(target, NULL_VECTOR, vecAngles, NULL_VECTOR);
	CPrintToChat(client, "Target angles set to: %.2f/%.2f/%.2f", vecAngles[0], vecAngles[1], vecAngles[2]);

	return Plugin_Handled;
}

public Action Command_SetAnglesNear(int client, int args)
{
	int target = GetNearestEntity(client, "prop_*");

	if (target == -1)
	{
		CPrintToChat(client, "Target not found, please aim your crosshair.");
		return Plugin_Handled;
	}

	float vecAngles[3];
	vecAngles[0] = GetCmdArgFloat(1);
	vecAngles[1] = GetCmdArgFloat(2);
	vecAngles[2] = GetCmdArgFloat(3);

	TeleportEntity(target, NULL_VECTOR, vecAngles, NULL_VECTOR);
	CPrintToChat(client, "Target angles set to: %.2f/%.2f/%.2f", vecAngles[0], vecAngles[1], vecAngles[2]);

	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	FindConVar("mp_autoteambalance").IntValue = 0;
	FindConVar("mp_teams_unbalance_limit").IntValue = 0;
	FindConVar("tf_forced_holiday").IntValue = 2;
	FindConVar("tf_bot_reevaluate_class_in_spawnroom").IntValue = 0;
	FindConVar("tf_base_boss_max_turn_rate").IntValue = 10000;
	FindConVar("tf_base_boss_speed").IntValue = 999;

	FindConVar("mp_respawnwavetime").Flags = FindConVar("mp_respawnwavetime").Flags &= ~FCVAR_NOTIFY;
	FindConVar("mp_respawnwavetime").IntValue = 0;
	FindConVar("mp_scrambleteams_auto").IntValue = 0;

	if (g_Late)
	{
		g_Late = false;
		InitLobby();
	}
}

public void OnPluginEnd()
{
	g_Match.hud_timer.ClearAll();
	g_Sync_NearInteractable.ClearAll();

	KillAllZombies();
	DestroyMachines();
	DestroyWeapons();
	DestroyMysteryBoxes();
	DestroyPowerups();

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			g_Player[i].Clear();
	
	LockRelays();
}

public void OnMapStart()
{
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");

	//Lobby Sounds
	PrecacheSound(SOUND_LOBBY);

	//Packapunch Cinematic
	PrecacheSound("misc/doomsday_cap_open.wav");

	//Zombie Crits
	PrecacheSound("player/crit_received1.wav");
	PrecacheSound("player/crit_hit.wav");

	//Blood Particles
	for (int i = 0; i < 5; i++)
		PrecacheParticle(sBloodParticles[i]);
	
	//Robot Models
	for (int i = 0; i < 10; i++)
		if (strlen(sRobotModels[i]) > 0)
			PrecacheModel(sRobotModels[i]);
	
	//Zombie Hits
	PrecacheSound("weapons/fist_hit_world1.wav");
	PrecacheSound("weapons/fist_hit_world2.wav");
	
	//Bombheads Easter Egg
	PrecacheModel("models/props_lakeside_event/bomb_temp.mdl");
	PrecacheSound("weapons/pipe_bomb1.wav");
	PrecacheParticle("skull_island_explosion");

	char sSound[PLATFORM_MAX_PATH];
	
	//Zombie Sounds
	for (int i = 1; i <= 7; i++)
	{
		FormatEx(sSound, sizeof(sSound), "undead/zombies/undead_zombie0%i.wav", i);
		PrecacheSound(sSound);
		Format(sSound, sizeof(sSound), "sound/%s", sSound);
		AddFileToDownloadsTable(sSound);
	}
	
	for (int i = 1; i <= 3; i++)
	{
		FormatEx(sSound, sizeof(sSound), "undead/zombies/undead_giant_zombie0%i.wav", i);
		PrecacheSound(sSound);
		Format(sSound, sizeof(sSound), "sound/%s", sSound);
		AddFileToDownloadsTable(sSound);
	}

	PrecacheSound("undead/zombies/undead_giant_zombie_spawn.wav");
	AddFileToDownloadsTable("sound/undead/zombies/undead_giant_zombie_spawn.wav");
	PrecacheSound("undead/zombies/undead_zombie_death_explode.wav");
	AddFileToDownloadsTable("sound/undead/zombies/undead_zombie_death_explode.wav");

	//Mystery Box
	PrecacheSound("undead/mystery_box.wav");
	AddFileToDownloadsTable("sound/undead/mystery_box.wav");

	//Planks
	PrecacheSound("physics/wood/wood_crate_break4.wav");

	//Rounds
	PrecacheSound("undead/round_start.wav");
	AddFileToDownloadsTable("sound/undead/round_start.wav");

	PrecacheSound("undead/round_end.wav");
	AddFileToDownloadsTable("sound/undead/round_end.wav");
	
	//////////
	//Machines

	//Sounds
	PrecacheSound("undead/machines/deadshot.wav");
	PrecacheSound("undead/machines/doubletap.wav");
	PrecacheSound("undead/machines/juggernog.wav");
	PrecacheSound("undead/machines/packapunch.wav");
	PrecacheSound("undead/machines/quickrevive.wav");
	PrecacheSound("undead/machines/speedcola.wav");
	PrecacheSound("undead/machines/staminup.wav");
	PrecacheSound("undead/machines/packapunchhum.wav");
	PrecacheSound("undead/machines/perkmachinehum.wav");
	
	AddFileToDownloadsTable("sound/undead/machines/deadshot.wav");
	AddFileToDownloadsTable("sound/undead/machines/doubletap.wav");
	AddFileToDownloadsTable("sound/undead/machines/juggernog.wav");
	AddFileToDownloadsTable("sound/undead/machines/packapunch.wav");
	AddFileToDownloadsTable("sound/undead/machines/quickrevive.wav");
	AddFileToDownloadsTable("sound/undead/machines/speedcola.wav");
	AddFileToDownloadsTable("sound/undead/machines/staminup.wav");
	AddFileToDownloadsTable("sound/undead/machines/packapunchhum.wav");
	AddFileToDownloadsTable("sound/undead/machines/perkmachinehum.wav");

	//Deadshot
	PrecacheModel("models/undead/machines/deadshot/deadshot.mdl");
	AddFileToDownloadsTable("models/undead/machines/deadshot/deadshot.mdl");
	AddFileToDownloadsTable("models/undead/machines/deadshot/deadshot.dx80.vtx");
	AddFileToDownloadsTable("models/undead/machines/deadshot/deadshot.dx90.vtx");
	AddFileToDownloadsTable("models/undead/machines/deadshot/deadshot.phy");
	AddFileToDownloadsTable("models/undead/machines/deadshot/deadshot.sw.vtx");
	AddFileToDownloadsTable("models/undead/machines/deadshot/deadshot.vvd");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_c.vmt");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_c.vtf");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_glass.vmt");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_glass.vtf");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_logo_c.vmt");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_logo_c.vtf");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_logo_normal.vtf");
	AddFileToDownloadsTable("materials/models/deadshot/zombie_vending_ads_normal.vtf");

	//Doubletap
	PrecacheModel("models/undead/machines/doubletap/doubletap2.mdl");
	AddFileToDownloadsTable("models/undead/machines/doubletap/doubletap2.mdl");
	AddFileToDownloadsTable("models/undead/machines/doubletap/doubletap2.dx80.vtx");
	AddFileToDownloadsTable("models/undead/machines/doubletap/doubletap2.dx90.vtx");
	AddFileToDownloadsTable("models/undead/machines/doubletap/doubletap2.phy");
	AddFileToDownloadsTable("models/undead/machines/doubletap/doubletap2.sw.vtx");
	AddFileToDownloadsTable("models/undead/machines/doubletap/doubletap2.vvd");
	AddFileToDownloadsTable("materials/models/doubletap2/doubletap2_colour.vmt");
	AddFileToDownloadsTable("materials/models/doubletap2/doubletap2_colour.vtf");
	AddFileToDownloadsTable("materials/models/doubletap2/doubletap2_normal.vtf");
	AddFileToDownloadsTable("materials/models/doubletap2/doubletap2_vent.vmt");
	AddFileToDownloadsTable("materials/models/doubletap2/doubletap2_vent.vtf");

	//Juggernog
	PrecacheModel("models/undead/machines/juggernog/juggernog .mdl");
	AddFileToDownloadsTable("models/undead/machines/juggernog/juggernog .mdl");
	AddFileToDownloadsTable("models/undead/machines/juggernog/juggernog .dx80.vtx");
	AddFileToDownloadsTable("models/undead/machines/juggernog/juggernog .dx90.vtx");
	AddFileToDownloadsTable("models/undead/machines/juggernog/juggernog .phy");
	AddFileToDownloadsTable("models/undead/machines/juggernog/juggernog .sw.vtx");
	AddFileToDownloadsTable("models/undead/machines/juggernog/juggernog .vvd");
	AddFileToDownloadsTable("models/undead/machines/juggernog/juggernog .xbox.vtx");

	//Packapunch
	PrecacheModel("models/undead/machines/packapunch/packapunch.mdl");
	AddFileToDownloadsTable("models/undead/machines/packapunch/packapunch.mdl");
	AddFileToDownloadsTable("models/undead/machines/packapunch/packapunch.dx80.vtx");
	AddFileToDownloadsTable("models/undead/machines/packapunch/packapunch.dx90.vtx");
	AddFileToDownloadsTable("models/undead/machines/packapunch/packapunch.phy");
	AddFileToDownloadsTable("models/undead/machines/packapunch/packapunch.sw.vtx");
	AddFileToDownloadsTable("models/undead/machines/packapunch/packapunch.vvd");

	//Quickrevive
	PrecacheModel("models/undead/machines/quickrevive/quickrevive.mdl");
	AddFileToDownloadsTable("models/undead/machines/quickrevive/quickrevive.mdl");
	AddFileToDownloadsTable("models/undead/machines/quickrevive/quickrevive.dx80.vtx");
	AddFileToDownloadsTable("models/undead/machines/quickrevive/quickrevive.dx90.vtx");
	AddFileToDownloadsTable("models/undead/machines/quickrevive/quickrevive.phy");
	AddFileToDownloadsTable("models/undead/machines/quickrevive/quickrevive.sw.vtx");
	AddFileToDownloadsTable("models/undead/machines/quickrevive/quickrevive.vvd");

	//Speedcola
	PrecacheModel("models/undead/machines/speedcola/speedcola.mdl");
	AddFileToDownloadsTable("models/undead/machines/speedcola/speedcola.mdl");
	AddFileToDownloadsTable("models/undead/machines/speedcola/speedcola.dx80.vtx");
	AddFileToDownloadsTable("models/undead/machines/speedcola/speedcola.dx90.vtx");
	AddFileToDownloadsTable("models/undead/machines/speedcola/speedcola.phy");
	AddFileToDownloadsTable("models/undead/machines/speedcola/speedcola.sw.vtx");
	AddFileToDownloadsTable("models/undead/machines/speedcola/speedcola.vvd");
	AddFileToDownloadsTable("materials/models/perkacola/pack_a_punch_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/pack_a_punch_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/pack_a_punch_moving_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/pack_a_punch_moving_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/pack_a_punch_moving_n.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/pack_a_punch_n.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_perkbottle_jugg_n.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_perkbottle_sleight_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_perkbottle_sleight_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_doubletap_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_doubletap_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_doubletap_n.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_jugg_col.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_jugg_col.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_jugg_norm.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_revive_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_revive_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_revive_n.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_revsign_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_revsign_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_revsign_n.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_sleight_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_sleight_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_sleight_gc.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_sleight_gc.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_sleight_logo_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_sleight_logo_c.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_sleight_n.vtf");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_vent_power_on_c.vmt");
	AddFileToDownloadsTable("materials/models/perkacola/zombie_vending_vent_power_on_c.vtf");

	//Staminup
	PrecacheModel("models/undead/machines/staminup/staminup.mdl");
	AddFileToDownloadsTable("models/undead/machines/staminup/staminup.mdl");
	AddFileToDownloadsTable("models/undead/machines/staminup/staminup.dx80.vtx");
	AddFileToDownloadsTable("models/undead/machines/staminup/staminup.dx90.vtx");
	AddFileToDownloadsTable("models/undead/machines/staminup/staminup.phy");
	AddFileToDownloadsTable("models/undead/machines/staminup/staminup.sw.vtx");
	AddFileToDownloadsTable("models/undead/machines/staminup/staminup.vvd");
	AddFileToDownloadsTable("materials/models/staminup/_-gzombie_vending_marathon_c.vmt");
	AddFileToDownloadsTable("materials/models/staminup/_-gzombie_vending_marathon_c.vtf");
	AddFileToDownloadsTable("materials/models/staminup/zombie_vending_marathon_glass.vmt");
	AddFileToDownloadsTable("materials/models/staminup/zombie_vending_marathon_glass.vtf");
	AddFileToDownloadsTable("materials/models/staminup/zombie_vending_marathon_normal.vtf");

	//////////
	//Weapons

	//////////
	//Powerups
	AddFileToDownloadsTable("materials/models/undead/powerups/powerups.vmt");
	AddFileToDownloadsTable("materials/models/undead/powerups/powerups.vtf");
	AddFileToDownloadsTable("materials/models/undead/powerups/pyro_lightwarp.vtf");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_instant_kill.dx80.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_instant_kill.dx90.vtx");
	PrecacheModel("models/undead/powerups/undead_powerup_instant_kill.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_instant_kill.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_instant_kill.phy");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_instant_kill.sw.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_instant_kill.vvd");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_max_ammo.dx80.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_max_ammo.dx90.vtx");
	PrecacheModel("models/undead/powerups/undead_powerup_max_ammo.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_max_ammo.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_max_ammo.phy");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_max_ammo.sw.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_max_ammo.vvd");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_nuke.dx80.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_nuke.dx90.vtx");
	PrecacheModel("models/undead/powerups/undead_powerup_nuke.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_nuke.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_nuke.phy");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_nuke.sw.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_nuke.vvd");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_x2.dx80.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_x2.dx90.vtx");
	PrecacheModel("models/undead/powerups/undead_powerup_x2.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_x2.mdl");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_x2.phy");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_x2.sw.vtx");
	AddFileToDownloadsTable("models/undead/powerups/undead_powerup_x2.vvd");
	
	PrecacheSound("undead/powerups/powerup_double_points.wav");
	AddFileToDownloadsTable("sound/undead/powerups/powerup_double_points.wav");
	PrecacheSound("undead/powerups/powerup_grab.wav");
	AddFileToDownloadsTable("sound/undead/powerups/powerup_grab.wav");
	PrecacheSound("undead/powerups/powerup_instant_kill.wav");
	AddFileToDownloadsTable("sound/undead/powerups/powerup_instant_kill.wav");
	PrecacheSound("undead/powerups/powerup_loop.wav");
	AddFileToDownloadsTable("sound/undead/powerups/powerup_loop.wav");
	PrecacheSound("undead/powerups/powerup_max_ammo.wav");
	AddFileToDownloadsTable("sound/undead/powerups/powerup_max_ammo.wav");
	PrecacheSound("undead/powerups/powerup_nuke.wav");
	AddFileToDownloadsTable("sound/undead/powerups/powerup_nuke.wav");
	PrecacheSound("undead/powerups/powerup_spawn.wav");
	AddFileToDownloadsTable("sound/undead/powerups/powerup_spawn.wav");

	//////////
	//Mystery Boxes
	PrecacheModel("models/noobis/mystery_box/mystery_box.mdl");
	AddFileToDownloadsTable("models/noobis/mystery_box/mystery_box.mdl");
	AddFileToDownloadsTable("models/noobis/mystery_box/mystery_box.dx80.vtx");
	AddFileToDownloadsTable("models/noobis/mystery_box/mystery_box.dx90.vtx");
	AddFileToDownloadsTable("models/noobis/mystery_box/mystery_box.phy");
	AddFileToDownloadsTable("models/noobis/mystery_box/mystery_box.sw.vtx");
	AddFileToDownloadsTable("models/noobis/mystery_box/mystery_box.vvd");
	AddFileToDownloadsTable("materials/noobis/mystery_box/box.vmt");
	AddFileToDownloadsTable("materials/noobis/mystery_box/box.vtf");
	AddFileToDownloadsTable("materials/noobis/mystery_box/box_n.vtf");
	AddFileToDownloadsTable("materials/noobis/mystery_box/hay.vmt");
	AddFileToDownloadsTable("materials/noobis/mystery_box/hay.vtf");
	AddFileToDownloadsTable("materials/noobis/mystery_box/hay_n.vtf");
	AddFileToDownloadsTable("materials/noobis/mystery_box/y1.vmt");
	AddFileToDownloadsTable("materials/noobis/mystery_box/y1.vtf");
}

public void OnMapEnd()
{
	StopTimer(g_Match.roundtimer);
	StopTimer(g_WaveTimer);

	g_Match.pausetimer = false;
	g_Match.UnpauseZombies = false;

	g_Match.secret_door_unlocked = false;
	g_Match.bomb_heads = false;
	g_Match.spawn_robots = false;
}

public void TF2_OnRoundStart(bool full_reset)
{
	if (g_Match.secret_door_unlocked)
		OpenBonusDoor();

	g_Match.roundphase = PHASE_HIBERNATION;

	if (GetTeamAbsCount(3) > 0)
		InitLobby();
	
	int entity = -1; char class[64];
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
		if (GetEntityClassname(entity, class, sizeof(class)))
			OnEntityCreated(entity, class);
}

void InitLobby()
{
	if (g_Match.roundphase != PHASE_HIBERNATION)
		return;
	
	TF2_RespawnAll();
	FindConVar("mp_disable_respawn_times").IntValue = 0;
	
	g_Match.difficulty = GetDifficultyByName("Medium");
	g_Match.roundtime = LOBBY_TIME;
	g_Match.round = 1;
	g_Match.roundphase = PHASE_STARTING;

	StopTimer(g_Match.roundtimer);
	g_Match.roundtimer = CreateTimer(1.0, Timer_RoundTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	CreateTF2Timer(LOBBY_TIME);

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			g_Player[i].Reset();
	
	TriggerTimer(CreateTimer(36.0, Timer_LobbySound, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE));
}

public Action Timer_LobbySound(Handle timer, any data)
{
	if (g_Match.roundphase == PHASE_ACTIVE)
		return Plugin_Stop;

	EmitSoundToAll(SOUND_LOBBY);
	return Plugin_Continue;
}

public Action Timer_RoundTimer(Handle timer)
{
	if (g_Match.roundtime > 1)
	{
		char sPaused[16];
		if (g_Match.pausetimer)
			strcopy(sPaused, sizeof(sPaused), " (Paused)");
		else if (GetTeamAliveCount(TEAM_SURVIVORS) > 0)
			g_Match.roundtime--;
		
		char sSpec[64];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			
			if (GetClientTeam(i) < 2)
				Format(sSpec, sizeof(sSpec), "\n☰ (Join a team to play)");
			else if (GetClientTeam(i) > 1 && !IsPlayerAlive(i))
				Format(sSpec, sizeof(sSpec), "\n☰ (Respawning next round)");
			else if (g_Match.roundphase == PHASE_ACTIVE)
				Format(sSpec, sizeof(sSpec), " - Kills: %i", g_Player[i].zombiekills);
			
			char sPerk[MAX_NAME_LENGTH]; char sPerks[128]; char sDisplay[MAX_NAME_LENGTH]; char sCount[32];
			for (int x = 0; x < g_Player[i].perks.Length; x++)
			{
				g_Player[i].perks.GetString(x, sPerk, sizeof(sPerk));
				GetMachineDisplay(sPerk, sDisplay, sizeof(sDisplay));

				sCount[0] = '\0';

				if (GetMachineMax(sPerk) > 1)
					FormatEx(sCount, sizeof(sCount), " (%i)", g_Player[i].GetPerkCount(sPerk));

				if (StrContains(sPerks, sDisplay, false) == -1)
					Format(sPerks, sizeof(sPerks), "%s\n [%s%s]", sPerks, sDisplay, sCount);
			}

			char sDifficulty[64];
			if (g_Match.difficulty != -1)
				strcopy(sDifficulty, sizeof(sDifficulty), g_Difficulty[g_Match.difficulty].name);

			g_Match.hud_timer.SetParams(0.0, 0.3, 2.0, 57, 255, 54, 255);

			if (GameRules_GetProp("m_bInWaitingForPlayers") || GetTeamAliveCount(TEAM_SURVIVORS) < 1)
			{
				g_Match.hud_timer.Send(i, "☰ Starting (%s): Waiting for Players", sDifficulty);
				return Plugin_Continue;
			}
			
			if (GetClientTeam(i) == TEAM_ZOMBIES)
			{
				switch (g_Match.roundphase)
				{
					case PHASE_STARTING:
						g_Match.hud_timer.Send(i, "☰ Starting (%s) %s%s", sDifficulty, sPaused, sSpec);
					case PHASE_WAITING:
						g_Match.hud_timer.Send(i, "☰ Wave %i (%s) - Next Wave Incoming %s\n☰ Next Spawns In: %i", g_Match.round, sDifficulty, sPaused, g_WaveTime);
					case PHASE_ACTIVE:
						g_Match.hud_timer.Send(i, "☰ Wave %i (%s) %s\n☰ Next Spawns In: %i", g_Match.round, sDifficulty, sPaused, g_WaveTime);
				}
			}
			else
			{
				int time = GetTime();

				char sPowerup[64];
				if (g_Player[i].doublepoints > time)
					Format(sPowerup, sizeof(sPowerup), "%s\n☰ Double Points: %i", sPowerup, g_Player[i].doublepoints - time);
				if (g_Player[i].instakill > time)
					Format(sPowerup, sizeof(sPowerup), "%s\n☰ Instakill: %i", sPowerup, g_Player[i].instakill - time);
				
				switch (g_Match.roundphase)
				{
					case PHASE_STARTING:
						g_Match.hud_timer.Send(i, "☰ Starting (%s) %s%s", sDifficulty, sPaused, sSpec);
					case PHASE_WAITING:
						g_Match.hud_timer.Send(i, "☰ Wave %i (%s) - Next Wave Incoming %s\n☰ Points: %i%s%s%s", g_Match.round, sDifficulty, sPaused, g_Player[i].points, sSpec, sPowerup, sPerks);
					case PHASE_ACTIVE:
						g_Match.hud_timer.Send(i, "☰ Wave %i (%s) %s\n☰ Points: %i%s%s%s", g_Match.round, sDifficulty, sPaused, g_Player[i].points, sSpec, sPowerup, sPerks);
				}
			}
		}

		return Plugin_Continue;
	}

	switch (g_Match.roundphase)
	{
		case PHASE_STARTING:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
					continue;
				
				if (IsDrixevel(i))
					g_Player[i].points = 9999999;
				
				switch (GetClientTeam(i))
				{
					case TEAM_SURVIVORS:
					{
						if (!IsPlayerAlive(i))
							TF2_RespawnPlayer(i);
						
						StripPlayer(i);
						SpeakResponseConcept(i, "TLK_MVM_WAVE_START");

						SetEntProp(i, Prop_Data, "m_iAmmo", 0, 4, 3);

						if (TF2_GetPlayerClass(i) == TFClass_Engineer)
							TF2Attrib_SetByName(i, "maxammo metal reduced", 0.0);
					}

					case TEAM_ZOMBIES:
					{
						SetEntProp(i, Prop_Send, "m_lifeState", 0);
						ForcePlayerSuicide(i);
					}
				}

				g_Player[i].ResetStats();
			}

			TelePlayersToMap();
			FindConVar("mp_respawnwavetime").IntValue = 99999999;

			SpawnMachines();
			SpawnWeapons();
			SpawnMysteryBoxes();
			SpawnPlanks();
			SetupBuildings();
			SetupDoors();

			CloseBonusDoor();

			g_WaveTime = GetWaveTime();
			g_WaveTimer = CreateTimer(1.0, Timer_SpawnWave, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

			g_Match.roundtime = 120;
			g_Match.roundphase = PHASE_ACTIVE;
			EmitSoundToAll("undead/round_start.wav");

			CreateTF2Timer(g_Match.roundtime);

			g_Match.coins_machine = GetRandomInt(0, g_TotalMachines - 1);

			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					StopSound(i, SNDCHAN_AUTO, SOUND_LOBBY);

			return Plugin_Continue;
		}

		case PHASE_ACTIVE:
		{
			KillAllZombies();

			g_Match.roundtime = 30;
			g_Match.roundphase = PHASE_WAITING;
			EmitSoundToAll("undead/round_end.wav");

			CreateTF2Timer(g_Match.roundtime);

			TelePlayersToMap();
			UnlockRelays();

			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS)
					g_Player[i].AddStat(STAT_WAVES, 1);

			TriggerTimer(CreateTimer(36.0, Timer_LobbySound, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE));
		}

		case PHASE_WAITING:
		{
			g_Match.roundtime = 120;
			g_Match.roundphase = PHASE_ACTIVE;
			EmitSoundToAll("undead/round_start.wav");
			g_Match.round++;

			CreateTF2Timer(g_Match.roundtime);

			if (g_Match.round >= 25)
			{
				g_Match.secret_door_unlocked = true;

				int disabled_sprite = FindEntityByName("secretdoor_sprite_disabled", "env_sprite");

				if (IsValidEntity(disabled_sprite))
					AcceptEntityInput(disabled_sprite, "Disable");
				
				int enabled_sprite = FindEntityByName("secretdoor_sprite_enabled", "env_sprite");

				if (IsValidEntity(enabled_sprite))
					AcceptEntityInput(enabled_sprite, "Enable");
			}

			TelePlayersToMap();

			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					StopSound(i, SNDCHAN_AUTO, SOUND_LOBBY);
		}
	}

	return Plugin_Continue;
}

void UnlockRelays()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "logic_relay")) != -1)
		if (HasName(entity, "unlock_obstacle") && GetWaveUnlockInt(entity) <= (g_Match.round + 1))
			AcceptEntityInput(entity, "Trigger");
	
	RecomputeNavs();
}

void LockRelays()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "logic_relay")) != -1)
		if (HasName(entity, "lock_obstacle"))
			AcceptEntityInput(entity, "Trigger");
	
	RecomputeNavs();
}

int GetWaveUnlockInt(int entity)
{
	if (!IsValidEntity(entity))
		return -1;
	
	char sWave[32];
	if (!GetCustomKeyValue(entity, "udm_unlock_on_wave", sWave, sizeof(sWave)))
		return -1;
	
	int wave = StringToInt(sWave);
	
	if (wave == 0)
		wave = -1;

	return wave;
}

public Action Timer_SpawnWave(Handle timer)
{
	if (g_Match.roundphase != PHASE_ACTIVE || g_Match.pausetimer)
		return Plugin_Continue;
	
	if (g_WaveTime > 0)
	{
		g_WaveTime--;
		return Plugin_Continue;
	}

	int min = 1 + RoundFloat(float((g_Match.round * (GetTeamAbsCount(TEAM_SURVIVORS) / 2))) * g_Difficulty[g_Match.difficulty].wavespawn_min);
	int max = 2 + RoundFloat(float((g_Match.round * (GetTeamAbsCount(TEAM_SURVIVORS) / 2))) * g_Difficulty[g_Match.difficulty].wavespawn_max);

	SpawnWave(GetRandomInt(min, max));
	g_WaveTime = GetWaveTime();

	return Plugin_Continue;
}

int GetWaveTime()
{
	float base = GetRandomFloat(ZOMBIE_WAVE_TIMER_MIN, ZOMBIE_WAVE_TIMER_MAX);
	float round_multi = 0.04 * float(g_Match.round);
	int time = RoundFloat((base - round_multi) * g_Difficulty[g_Match.difficulty].wavespawn_rate);
	//PrintToChatAll("Wave Time: %i", time);
	return time;
}

void TelePlayersToMap()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "trigger_teleport")) != -1)
	{
		char sName[128];
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));

		if (StrEqual(sName, "game_start_teleport"))
		{
			SDKHook(entity, SDKHook_StartTouch, OnTeleTouch);
			AcceptEntityInput(entity, "Enable");
			AcceptEntityInput(entity, "Disable");
			SDKUnhook(entity, SDKHook_StartTouch, OnTeleTouch);
		}
	}
}

public Action OnTeleTouch(int entity, int other)
{
	if (other > 0 && other <= MaxClients && IsPlayerAlive(other))
	{
		PrintHintText(other, "[Hint] %s", sHints[GetRandomInt(0, 16)]);

		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(other))
				g_Player[i].AddStat(STAT_TEAMMATES, 1);
	}
}

public void TF2_OnRoundEnd(int team, int winreason, int flagcaplimit, bool full_round, float round_time, int losing_team_num_caps, bool was_sudden_death)
{
	g_Match.bomb_heads = false;
	g_Match.spawn_robots = false;

	g_Match.roundphase = PHASE_ENDING;

	StopTimer(g_Match.roundtimer);
	StopTimer(g_WaveTimer);

	FindConVar("mp_respawnwavetime").IntValue = 0;

	KillAllZombies();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		if (IsPlayerAlive(i) && team == TEAM_SURVIVORS && GetClientTeam(i) == team)
			SpeakResponseConcept(i, "TLK_GAME_OVER_COMP");
		
		TF2Attrib_RemoveAll(i);

		int weapon;
		for (int x = 0; x < 5; x++)
			if ((weapon = GetPlayerWeaponSlot(i, x)) != -1)
				TF2Attrib_RemoveAll(weapon);
		
		g_Player[i].Clean(false);
		g_Player[i].zombiekills = 0;
	}

	int secret;

	if ((secret = FindEntityByName("secret_lock", "logic_relay")) != -1)
		AcceptEntityInput(secret, "Trigger");
	
	if ((secret = FindEntityByName("secret2_lock", "logic_relay")) != -1)
		AcceptEntityInput(secret, "Trigger");
	
	if ((secret = FindEntityByName("secret3_lock", "logic_relay")) != -1)
		AcceptEntityInput(secret, "Trigger");
	
	SaveStatistics();
}

void SaveStatistics()
{
	if (g_Database == null)
		return;
	
	char sServerIP[64];
	GetServerIP(sServerIP, sizeof(sServerIP), true);
	
	char sQuery[1024]; char sSteamID[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) < 2 || IsFakeClient(i))
			continue;
		
		if (!GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID)))
			continue;

		g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `undead_statistics` (steamid, server, team, difficulty, kills, deaths, revives, machines_bought, weapons_bought, mysteryboxes_opened, planks_rebuilt, buildings_rented, points_gained, points_spent, damage, waves_won, specials_killed, revived, powerups_pickedup, total_teammates, doors_opened) VALUES ('%s', '%s', '%i', '%s', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i');", sSteamID, sServerIP, GetClientTeam(i), g_Difficulty[g_Match.difficulty].name, g_Player[i].GetStat(STAT_KILLS), g_Player[i].GetStat(STAT_DEATHS), g_Player[i].GetStat(STAT_REVIVES), g_Player[i].GetStat(STAT_MACHINES), g_Player[i].GetStat(STAT_WEAPONS), g_Player[i].GetStat(STAT_MYSTERYBOXES), g_Player[i].GetStat(STAT_PLANKS), g_Player[i].GetStat(STAT_BUILDINGS), g_Player[i].GetStat(STAT_GAINED), g_Player[i].GetStat(STAT_SPENT), g_Player[i].GetStat(STAT_DAMAGE), g_Player[i].GetStat(STAT_WAVES), g_Player[i].GetStat(STAT_SPECIALS), g_Player[i].GetStat(STAT_REVIVED), g_Player[i].GetStat(STAT_POWERUP), g_Player[i].GetStat(STAT_TEAMMATES), g_Player[i].GetStat(STAT_DOORS));
		g_Database.Query(OnSaveStats, sQuery);

		g_Player[i].ResetStats();
	}
}

public void OnSaveStats(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while saving statistics: %s", error);
}

public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0  && GetClientTeam(client) == TEAM_ZOMBIES)
	{
		dontBroadcast = true;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void TF2_OnPlayerDeath(int client, int attacker, int assister, int inflictor, int damagebits, int stun_flags, int death_flags, int customkill)
{
	g_Player[client].Clean(false);

	if (g_Match.roundphase == PHASE_WAITING || g_Match.roundphase == PHASE_ACTIVE)
	{
		if (GetTeamAliveCount(TEAM_SURVIVORS) > 0 && GetClientTeam(client) == TEAM_SURVIVORS)
		{
			int entity = CreateEntityByName("entity_revive_marker");

			if (IsValidEntity(entity))
			{
				float vecOrigin[3];
				GetClientAbsOrigin(client, vecOrigin);

				DispatchKeyValueVector(entity, "origin", vecOrigin);

				SetEntPropEnt(entity, Prop_Send, "m_hOwner", client);
				SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
				SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8);
				SetEntProp(entity, Prop_Send, "m_fEffects", 16);
				SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
				SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
				SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 1);
				SetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_nForcedSkin") + 4, entity);
				SetEntProp(entity, Prop_Send, "m_nBody", view_as<int>(TF2_GetPlayerClass(client)) - 1);
				SetEntProp(entity, Prop_Send, "m_nSequence", 1);
				SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 1.0);
				SetEntProp(entity, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));

				DispatchSpawn(entity);

				g_Player[client].revivemarker = EntIndexToEntRef(entity);

				int weapon = -1;

				if ((weapon = GetPlayerWeaponSlot(client, 0)) != -1)
					g_Player[client].primary = g_WeaponIndex[weapon];
				
				if ((weapon = GetPlayerWeaponSlot(client, 1)) != -1)
					g_Player[client].secondary = g_WeaponIndex[weapon];
				
				if ((weapon = GetPlayerWeaponSlot(client, 2)) != -1)
					g_Player[client].melee = g_WeaponIndex[weapon];
				
				TF2_CreateAnnotationToAll(vecOrigin, "Stand Here...", 10.0, "vo/null.wav");

				StopTimer(g_Player[client].revivetimer);

				DataPack pack;
				g_Player[client].revivetimer = CreateDataTimer(60.0, Timer_DeleteMarker, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(client));
				pack.WriteCell(EntIndexToEntRef(entity));

				g_Player[client].perks.Clear();
			}
		}

		if (GetClientTeam(client) == TEAM_ZOMBIES)
		{
			if (IsPlayerIndex(attacker))
			{
				bool doublepoints;
				if (IsPlayerIndex(attacker))
					doublepoints = g_Player[attacker].doublepoints != -1 && g_Player[attacker].doublepoints > GetTime();
				
				int points = doublepoints ? 200 : 100;

				if (GetActiveWeaponSlot(attacker) == 2)
					points = RoundFloat(float(points) * 1.5);
				
				g_Player[attacker].AddPoints(points);

				if (g_Player[client].type == GetZombieTypeByName(ZOMBIE_DEFAULT))
					g_Player[attacker].AddStat(STAT_SPECIALS, 1);
			}

			OnZombieDeath(client, true, true);
			g_Player[attacker].zombiekills++;
		}

		if (IsPlayerIndex(client))
			g_Player[client].AddStat(STAT_DEATHS, 1);
		
		if (IsPlayerIndex(attacker))
			g_Player[attacker].AddStat(STAT_KILLS, 1);

		CreateTimer(0.5, Timer_ParseRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_DeleteMarker(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int entity = EntRefToEntIndex(pack.ReadCell());

	if (IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
	
	if (client > 0)
		g_Player[client].revivetimer = null;
}

void TF2_CreateAnnotationToAll(float origin[3], const char[] text, float lifetime = 10.0, const char[] sound = "vo/null.wav")
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
	
		Event event = CreateEvent("show_annotation");
		
		if (event == null)
			continue;
		
		event.SetFloat("worldPosX", origin[0]);
		event.SetFloat("worldPosY", origin[1]);
		event.SetFloat("worldPosZ", origin[2]);
		//event.SetInt("follow_entindex", i);
		event.SetFloat("lifetime", lifetime);
		//event.SetInt("id", i + 8750);
		event.SetString("text", text);
		event.SetString("play_sound", sound);
		event.SetString("show_effect", "0");
		event.SetString("show_distance", "0");
		event.Fire(false);
	}
}

public Action Timer_ParseRoundEnd(Handle timer)
{
	if (GetTeamAliveCount(TEAM_SURVIVORS) < 1)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "entity_revive_marker")) != -1)
			AcceptEntityInput(entity, "Kill");

		TF2_ForceWin(view_as<TFTeam>(TEAM_ZOMBIES));
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "item_currencypack_custom") || StrEqual(classname, "tf_ammo_pack"))
		SDKHook(entity, SDKHook_Spawn, OnCurrencySpawn);
	
	if (StrEqual(classname, "trigger_teleport_relative", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnTeleportRelativeSpawnPost);

		if (g_Late)
			OnTeleportRelativeSpawnPost(entity);
	}
	
	if (StrEqual(classname, "trigger_multiple"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnTriggerMultipleSpawnPost);

		if (g_Late)
			OnTriggerMultipleSpawnPost(entity);
	}
	
	if (StrEqual(classname, "obj_dispenser"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnDispenserTakeDamage);
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);

		if (g_Late)
			OnSpawnPost(entity);
	}
	
	if (entity > 0)
	{
		g_Machines[entity].Reset();
		g_SpawnedWeapons[entity].Reset();

		if (entity > MaxClients)
		{
			char sEntity[64];
			IntToString(entity, sEntity, sizeof(sEntity));
			g_PackaPunchUpgrades.SetValue(sEntity, 0);
		}
	}
}

public Action OnCurrencySpawn(int entity)
{
	return Plugin_Stop;
}

public void OnTeleportRelativeSpawnPost(int entity)
{
	if (IsName(entity, "survivor_blocker"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnTeleportTouch);
		SDKHook(entity, SDKHook_Touch, OnTeleportTouch);
		SDKHook(entity, SDKHook_EndTouch, OnTeleportTouch);
	}
}

public void OnTriggerMultipleSpawnPost(int entity)
{
	if (IsName(entity, "insidebase"))
		SDKHook(entity, SDKHook_Touch, OnEnablePowerups);
}

public Action OnTeleportTouch(int entity, int other)
{
	if (IsPlayerIndex(other) && GetClientTeam(other) == TEAM_ZOMBIES)
		return Plugin_Stop;

	return Plugin_Continue;
}

public Action OnEnablePowerups(int entity, int other)
{
	if (other > MaxClients && IsClassname(other, "base_boss"))
	{
		CBaseNPC npc = TheNPCs.FindNPCByEntIndex(other);
		g_Zombies[npc.Index].insidemap = true;
	}
}

public Action OnDispenserTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	damage = 0.0;
	return Plugin_Changed;
}

public void OnSpawnPost(int entity)
{
	DHookEntity(g_BlockDispenserMetal, false, entity);
}

public void OnEntityDestroyed(int entity)
{
	if (entity > MaxClients)
	{
		g_WeaponIndex[entity] = -1;

		if (g_PowerupIndex[entity] != -1)
			StopSound(entity, SNDCHAN_USER_BASE + 14, "undead/powerups/powerup_loop.wav");
		
		g_PowerupIndex[entity] = -1;

		char sEntity[64];
		IntToString(entity, sEntity, sizeof(sEntity));
		g_PackaPunchUpgrades.SetValue(sEntity, 0);
	}
}

public Action Command_RandomZombie(int client, int args)
{
	SpawnRandomZombie();
	CPrintToChat(client, "A random zombie has been spawned.");
	return Plugin_Handled;
}

public Action Command_SpawnWave(int client, int args)
{
	int count = 5;

	if (args > 0)
		count = GetCmdArgInt(1);
	
	SpawnWave(count);
	CPrintToChat(client, "You have spawned a wave of {haunted}%i {default}zombies.", count);

	return Plugin_Handled;
}

void SpawnWave(int amount)
{
	int total = amount;
	int special = GetZombieTypeByName(ZOMBIE_DEFAULT);

	float origin[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ZOMBIES || total <= 0)
			continue;
		
		TF2_RespawnPlayer(i);
		GetRandomSpawn(origin);
		TeleportEntity(i, origin, NULL_VECTOR, NULL_VECTOR);
		g_Player[i].sounds = GetZombieSoundDuration(i);

		special = GetZombieType();
		ApplySpecialUpdates(i, special, origin);

		total--;
	}

	for (int i = 0; i < total; i++)
	{
		special = GetZombieType();
		SpawnRandomZombie(special);
	}
}

int GetZombieType()
{
	if (GetRandomFloat(0.0, 1000.0) < 950.0)
		return GetZombieTypeByName(ZOMBIE_DEFAULT);
	
	int specials[32];
	int total;

	for (int i = 1; i < g_TotalZombieTypes; i++)
	{
		if (g_ZombieTypes[i].unlock_wave != -1 && g_ZombieTypes[i].unlock_wave > g_Match.round)
			continue;
		
		specials[total++] = i;
	}

	return (total == 0) ? GetZombieTypeByName(ZOMBIE_DEFAULT) : specials[GetRandomInt(0, total - 1)];
}

bool GetRandomSpawn(float origin[3])
{
	int entities[MAX_ENTITY_LIMIT + 1];
	int count;

	int entity = -1; int unlock; char required_door[64]; int required_door_ent;
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		if (!HasName(entity, "udm_zombie"))
			continue;
		
		unlock = GetWaveUnlockInt(entity);
		
		if (unlock != -1 && unlock > g_Match.round)
			continue;
		
		if (GetCustomKeyValue(entity, "udm_required_open", required_door, sizeof(required_door)) && strlen(required_door) > 0)
		{
			if ((required_door_ent = FindEntityByName(required_door)) != -1 && HasEntProp(required_door_ent, Prop_Data, "m_eDoorState") && GetEntProp(required_door_ent, Prop_Data, "m_eDoorState") != 2)
				continue;
			
			if ((required_door_ent = FindEntityByName(required_door)) != -1 && HasEntProp(required_door_ent, Prop_Data, "m_toggle_state") && GetEntProp(required_door_ent, Prop_Data, "m_toggle_state") != 1)
				continue;
		}
		
		entities[count++] = entity;
	}

	if (count < 1)
		return false;
	
	int chosen = entities[GetRandomInt(0, count - 1)];
	GetEntityOrigin(chosen, origin);

	GetGroundCoordinates(origin, origin);
	origin[2] += 10.0;

	return true;
}

public Action Command_SpawnZombie(int client, int args)
{
	if (args == 0)
	{
		OpenZombiesMenu(client);
		return Plugin_Handled;
	}

	char sType[64];
	GetCmdArgString(sType, sizeof(sType));

	int special = GetZombieTypeByName(sType);

	if (special == -1)
	{
		CPrintToChat(client, "Zombie type {haunted}%s {default}not found, please try again.");
		return Plugin_Handled;
	}

	float origin[3];
	GetClientLookOrigin(client, origin);

	SpawnZombie(origin, special);
	CPrintToChat(client, "You have spawned a {haunted}%s {normal}zombie.", sType);

	return Plugin_Handled;
}

void OpenZombiesMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Zombies);
	menu.SetTitle("Spawn a Zombie:");

	char sID[16];
	for (int i = 0; i < g_TotalZombieTypes; i++)
	{
		IntToString(i, sID, sizeof(sID));
		menu.AddItem(sID, g_ZombieTypes[i].name);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Zombies(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sID[16];
			menu.GetItem(param2, sID, sizeof(sID));

			float look[3];
			GetClientLookOrigin(param1, look);
			SpawnZombie(look, StringToInt(sID));

			OpenZombiesMenu(param1);
		}

		case MenuAction_End:
			delete menu;
	}
}

CBaseNPC SpawnRandomZombie(int special = -1)
{
	float origin[3];
	GetRandomSpawn(origin);

	GetGroundCoordinates(origin, origin);
	CBaseNPC npc = SpawnZombie(origin, special);

	return npc;
}

void ApplySpecialUpdates(int client, int special, float origin[3])
{
	if (special == -1)
		special = GetZombieTypeByName(ZOMBIE_DEFAULT);
	
	g_Player[client].type = special;
	g_Player[client].sounds = GetZombieSoundDuration(client);
	g_Player[client].insidemap = false;
	
	int class = g_ZombieTypes[special].class;

	if (class == -1)
		class = GetRandomInt(1, 9);
	else if (class < 1)
		class = 1;
	else if (class > 9)
		class = 9;
	
	TF2_SetPlayerClass(client, view_as<TFClassType>(class), false, false);

	if (special == GetZombieTypeByName(ZOMBIE_DEFAULT))
	{
		float size = GetRandomFloat(1.0, 1.0);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", size);
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * size);

		int color[3];
		color[0] = GetRandomInt(255, 255);
		color[1] = GetRandomInt(255, 255);
		color[2] = GetRandomInt(255, 255);

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, color[0], color[1], color[2], 255);

		int wearable = -1;
		while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
		{
			if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") != client)
				continue;
			
			SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
			SetEntityRenderColor(wearable, color[0], color[1], color[2], 255);
		}
	}
	else
	{
		if (g_ZombieTypes[special].size != -1.0)
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_ZombieTypes[special].size);
			SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * g_ZombieTypes[special].size);
		}

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, g_ZombieTypes[special].color[0], g_ZombieTypes[special].color[1], g_ZombieTypes[special].color[2], g_ZombieTypes[special].color[3]);

		int wearable = -1;
		while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
		{
			if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") != client)
				continue;
			
			SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
			SetEntityRenderColor(wearable, g_ZombieTypes[special].color[0], g_ZombieTypes[special].color[1], g_ZombieTypes[special].color[2], g_ZombieTypes[special].color[3]);
		}
	}

	float speed = g_ZombieTypes[special].speed;

	if (speed == -1.0)
		speed = 150.0;
	
	speed *= (1.0 + (g_Match.round * 0.05)) * g_Difficulty[g_Match.difficulty].movespeed_multipler;

	TF2Attrib_SetByName(client, "move speed bonus", speed);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);

	SetEntityHealth(client, CalculateHealth(client));

	if (strlen(g_ZombieTypes[special].spawn_sound) > 0 && IsSoundPrecached(g_ZombieTypes[special].spawn_sound))
		EmitSoundToAll(g_ZombieTypes[special].spawn_sound);
	
	if (strlen(g_ZombieTypes[special].death_sound) > 0 && IsSoundPrecached(g_ZombieTypes[special].death_sound))
		g_Player[client].AddDeathSound(g_ZombieTypes[special].death_sound);
	
	if (strlen(g_ZombieTypes[special].particle) > 0)
		g_Player[client].AttachParticle(g_ZombieTypes[special].particle, 0.0, "flag");

	if (special == GetZombieTypeByName("Strapped Engis"))
		g_Player[client].AttachBuilding("obj_dispenser", origin);
}

CBaseNPC SpawnZombie(float origin[3], int special = -1)
{
	int count = GetEntityCountEx("base_boss");
	
	if (count >= g_Difficulty[g_Match.difficulty].max_zombies)
	{
		PrintToServer("Failed to spawn zombie: Max Reached [%i/%i]", count, g_Difficulty[g_Match.difficulty].max_zombies);
		return INVALID_NPC;
	}

	if (special == -1)
		special = GetZombieTypeByName(ZOMBIE_DEFAULT);
	
	origin[2] += 10.0;

	int class = g_ZombieTypes[special].class;

	if (class == -1)
		class = GetRandomInt(1, 9);
	else if (class < 1)
		class = 1;
	else if (class > 9)
		class = 9;
	
	CBaseNPC npc = new CBaseNPC();
	npc.Teleport(origin);
	g_Zombies[npc.Index].type = special;

	if (g_Match.spawn_robots)
		npc.SetModel(sRobotModels[class]);
	else
		npc.SetModel(sModels[class]);

	npc.Spawn();
	npc.SetThinkFunction(OnZombieThink);
	npc.SetOnTraceAttackFunction(OnZombiesTraceAttack);
	npc.SetOnTakeDamageAliveFunction(OnZombieDamaged);
	npc.SetOnTakeDamageAlivePostFunction(OnZombieDamagedPost);
	
	int item = -1;
	if (!g_Match.spawn_robots && (item = npc.EquipItem("head", sZombieAttachments[class])) != -1)
	{
		SetEntityRenderMode(item, RENDER_TRANSCOLOR);
		SetEntityRenderColor(item, g_ZombieTypes[special].color[0], g_ZombieTypes[special].color[1], g_ZombieTypes[special].color[2], g_ZombieTypes[special].color[3]);
	}
	
	int entity = npc.GetEntity();
	//CBaseNPC_HookEventKilled(entity);

	if (g_Match.bomb_heads)
	{
		int bomb = -1;
		if ((bomb = TF2_AttachProp(entity, "models/props_lakeside_event/bomb_temp.mdl")) != -1)
		{
			SetEntityRenderMode(bomb, RENDER_TRANSCOLOR);
			SetEntityRenderColor(bomb, g_ZombieTypes[special].color[0], g_ZombieTypes[special].color[1], g_ZombieTypes[special].color[2], g_ZombieTypes[special].color[3]);
		}
	}
	
	int team = g_ZombieTypes[special].team;

	if (team == -1)
		team = TEAM_ZOMBIES;
	
	npc.nSkin = (class == 8) ? 22 : 4;
	npc.iTeamNum = team;
	npc.flGravity = 800.0;
	npc.flAcceleration = 4000.0;
	npc.flJumpHeight = 150.0;
	npc.flDeathDropHeight = 2000.0;

	npc.nSize = g_ZombieTypes[special].size != -1.0 ? g_ZombieTypes[special].size : 1.0;
	npc.flStepSize = 18.0 * ((npc.nSize != -1.0) ? npc.nSize : 1.0);
	FixZombieCollisions(npc);

	CBaseAnimating anim = CBaseAnimating(entity);
	anim.Hook_HandleAnimEvent(OnZombieAnimation);

	float speed = CalculateSpeed(special);
	npc.flWalkSpeed = speed;
	npc.flRunSpeed = speed;

	int health = CalculateHealth(entity);
	npc.iMaxHealth = health;
	npc.iHealth = health;
	
	npc.Run();

	CBaseAnimatingOverlay animationEntity = CBaseAnimatingOverlay(entity);
	animationEntity.PlayAnimation("Stand_MELEE");

	g_Zombies[npc.Index].entity = entity;
	g_Zombies[npc.Index].class = class;
	g_Zombies[npc.Index].speed = speed;
	g_Zombies[npc.Index].lastattack = 0.0;
	g_Zombies[npc.Index].target = -1;
	g_Zombies[npc.Index].planktarget = -1;
	g_Zombies[npc.Index].sounds = GetZombieSoundDuration(entity);
	g_Zombies[npc.Index].insidemap = false;

	SetEntityCollisionGroup(entity, COLLISION_GROUP_PUSHAWAY);
	
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, g_ZombieTypes[special].color[0], g_ZombieTypes[special].color[1], g_ZombieTypes[special].color[2], g_ZombieTypes[special].color[3]);

	if (strlen(g_ZombieTypes[special].spawn_sound) > 0 && IsSoundPrecached(g_ZombieTypes[special].spawn_sound))
		EmitSoundToAll(g_ZombieTypes[special].spawn_sound);
	
	if (strlen(g_ZombieTypes[special].death_sound) > 0 && IsSoundPrecached(g_ZombieTypes[special].death_sound))
		g_Zombies[npc.Index].AddDeathSound(g_ZombieTypes[special].death_sound);
	
	if (strlen(g_ZombieTypes[special].particle) > 0)
		AttachParticle(entity, g_ZombieTypes[special].particle, 0.0, "flag");
	
	if (special == GetZombieTypeByName(ZOMBIE_DEFAULT))
	{
		npc.nSize = GetRandomFloat(1.0, 1.0);
		npc.flStepSize = 18.0 * ((npc.nSize != -1.0) ? npc.nSize : 1.0);
		FixZombieCollisions(npc);

		int color[3];
		color[0] = GetRandomInt(255, 255);
		color[1] = GetRandomInt(255, 255);
		color[1] = GetRandomInt(255, 255);

		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, color[0], color[1], color[2], 255);

		if (IsValidEntity(item))
		{
			SetEntityRenderMode(item, RENDER_TRANSCOLOR);
			SetEntityRenderColor(item, color[0], color[1], color[2], 255);
		}
	}
	else if (special == GetZombieTypeByName("Strapped Engis"))
	{
		int dispenser = CreateEntityByName("obj_dispenser");
		
		if (IsValidEntity(dispenser))
		{
			origin[0] -= 20.0;
			//origin[1] -= 150.0;
			origin[2] += 15.0;

			DispatchKeyValueVector(dispenser, "origin", origin);
			//DispatchKeyValueVector(dispenser, "angles", Angle);
			DispatchKeyValue(dispenser, "defaultupgrade", "0");
			DispatchKeyValue(dispenser, "spawnflags", "4");
			SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
			DispatchSpawn(dispenser);

			SetVariantInt(TEAM_ZOMBIES);
			AcceptEntityInput(dispenser, "SetTeam");
			SetEntProp(dispenser, Prop_Send, "m_nSkin", TEAM_ZOMBIES - 2);
			
			ActivateEntity(dispenser);

			SetVariantString("!activator");
			AcceptEntityInput(dispenser, "SetParent", entity);

			SetVariantString("flag");
			AcceptEntityInput(dispenser, "SetParentAttachmentMaintainOffset");

			SetEntProp(dispenser, Prop_Send, "m_bDisabled", 1);
		}
	}

	return npc;
}

void FixZombieCollisions(CBaseNPC npc)
{
	if (npc != INVALID_NPC && npc.nSize != -1.0)
	{
		int entity = npc.GetEntity();

		float vecMins[3];
		GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMins);

		float vecMaxs[3];
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMaxs);
		
		vecMins[0] /= npc.nSize;
		vecMins[1] /= npc.nSize;
		vecMins[2] /= npc.nSize;

		vecMaxs[0] *= npc.nSize;
		vecMaxs[1] *= npc.nSize;
		vecMaxs[2] *= npc.nSize;

		npc.SetCollisionBounds(vecMins, vecMaxs);
	}
}

int GetZombieTypeByName(const char[] name)
{
	for (int i = 0; i < g_TotalZombieTypes; i++)
		if (StrEqual(g_ZombieTypes[i].name, name, false))
			return i;
	
	return -1;
}

int TF2_AttachProp(int iClient, const char[] model)
{
	int iLink = CreateEntityByName("tf_taunt_prop");

	if (!IsValidEntity(iLink))
		return -1;
	
	DispatchSpawn(iLink); 
	
	SetEntityModel(iLink, model);
	SetEntProp(iLink, Prop_Send, "m_fEffects", 16 | 64);
	
	SetVariantString("!activator"); 
	AcceptEntityInput(iLink, "SetParent", iClient); 
	
	SetVariantString("head");
	AcceptEntityInput(iLink, "SetParentAttachment", iClient);
	
	return iLink;
}

public Action Timer_ZombieTicks(Handle timer)
{
	if (g_Match.pausezombies)
		return Plugin_Continue;
	
	int entity; CBaseNPC npc;
	for (int i = 0; i < MAX_NPCS; i++)
	{
		entity = g_Zombies[i].entity;
		npc = TheNPCs.FindNPCByEntIndex(entity);
		
		if (npc == INVALID_NPC)
			continue;
		
		if (g_Zombies[npc.Index].type == GetZombieTypeByName("Strapped Engis"))
			OnEngiZombieTick(entity);
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ZOMBIES)
			continue;
	
		if (g_Player[i].type == GetZombieTypeByName("Strapped Engis"))
			OnEngiZombieTick(i);
	}

	return Plugin_Continue;
}

void OnEngiZombieTick(int entity)
{
	float origin[3];
	if (entity > MaxClients)
		GetEntityOrigin(entity, origin);
	else
		GetClientAbsOrigin(entity, origin);

	float targetorigin[3]; CBaseNPC npc;
	for (int i = 0; i < MAX_NPCS; i++)
	{
		int entity2 = g_Zombies[i].entity;

		if ((npc = TheNPCs.FindNPCByEntIndex(entity2)) == INVALID_NPC)
			continue;
		
		GetEntityOrigin(entity2, targetorigin);

		if (GetVectorDistance(origin, targetorigin) >= 500.0 || npc.iMaxHealth < npc.iHealth)
			continue;
		
		npc.iHealth += 2;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ZOMBIES)
			continue;
		
		GetClientAbsOrigin(i, targetorigin);
		
		if (GetVectorDistance(origin, targetorigin) >= 500.0)
			continue;

		TF2_AddPlayerHealth(i, 2, 1.0, true, true, -1);
	}
}

public void OnZombieThink(int entity)
{
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(entity);

	if (npc == INVALID_NPC)
		return;

	INextBot bot = npc.GetBot();
	NextBotGroundLocomotion loco = npc.GetLocomotion();
	
	float vecNPCPos[3];
	bot.GetPosition(vecNPCPos);

	float vecNPCAng[3];
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vecNPCAng);
	
	float time = GetGameTime();
	if (!g_Match.pausezombies && g_Zombies[npc].sounds != -1.0 && g_Zombies[npc.Index].sounds <= time && npc.iHealth > 0)
	{
		PlayZombieSound(entity);
		g_Zombies[npc.Index].sounds = GetZombieSoundDuration(entity);
	}

	CBaseAnimatingOverlay animationEntity = CBaseAnimatingOverlay(entity);

	int target = g_Zombies[npc.Index].target;

	if (target == -1 || !IsClientConnected(target) || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) < 2 || GetClientTeam(target) == npc.iTeamNum)
		g_Zombies[npc.Index].target = GetZombieTarget();
	
	target = g_Zombies[npc.Index].target;

	if (g_GlobalTarget != -1)
		target = g_GlobalTarget;
	
	if (target < 1 || g_Match.pausezombies)
	{
		animationEntity.PlayAnimation("Stand_MELEE");
		return;
	}
	
	float vecTargetPos[3];
	GetClientAbsOrigin(target, vecTargetPos);

	int ground = -1; bool isonmachine;
	if ((ground = GetEntPropEnt(target, Prop_Send, "m_hGroundEntity")) > MaxClients && g_Machines[ground].index != -1)
		isonmachine = true;
	
	if ((ground = GetEntPropEnt(target, Prop_Send, "m_hGroundEntity")) > MaxClients && g_InteractableType[ground] == INTERACTABLE_TYPE_BUILDING)
		isonmachine = true;
	
	if (GetVectorDistance(vecNPCPos, vecTargetPos) > (ZOMBIE_HIT_DISTANCE * (isonmachine ? 2.0 : 1.0)))
		g_Zombies[npc.Index].pPath.Update(bot, target, PredictSubjectPosition(npc, target));
	else if (g_Zombies[npc.Index].lastattack <= GetGameTime())
	{
		g_Zombies[npc.Index].lastattack = GetGameTime() + GetRandomFloat(ZOMBIE_ATTACK_SPEED_MIN, ZOMBIE_ATTACK_SPEED_MAX);
		animationEntity.AddGestureSequence(animationEntity.LookupSequence("throw_fire"));
		
		float damage = CalculateDamage();
		SDKHooks_TakeDamage(target, entity, entity, damage, DMG_SLASH);
		
		SpeakResponseConcept(target, "TLK_PLAYER_PAIN");
		EmitSoundToAll(GetRandomInt(0, 1) == 0 ? "weapons/fist_hit_world1.wav" : "weapons/fist_hit_world2.wav", target);

		int type = g_Zombies[npc.Index].type;

		if (type == GetZombieTypeByName("Ignition Pyro"))
			g_Player[target].SetOnFire();
		else if (type == GetZombieTypeByName("Spikey Bois"))
			g_Player[target].Bleed();

		g_Player[target].RegenTimer();
	}

	loco.FaceTowards(vecTargetPos);
	loco.Run();
	
	int iSequence = GetEntProp(entity, Prop_Send, "m_nSequence");
	
	int sequence_idle = animationEntity.LookupSequence("Stand_MELEE");
	int sequence_air_walk = animationEntity.LookupSequence("Airwalk_MELEE");
	int sequence_run = animationEntity.LookupSequence("run_MELEE");
	Address pModelptr = animationEntity.GetModelPtr();
	
	int iPitch = animationEntity.LookupPoseParameter(pModelptr, "body_pitch");
	int iYaw = animationEntity.LookupPoseParameter(pModelptr, "body_yaw");

	float vecNPCCenter[3];	
	animationEntity.WorldSpaceCenter(vecNPCCenter);
	
	float vecPlayerCenter[3];
	CBaseAnimating(target).WorldSpaceCenter(vecPlayerCenter);
	
	float vecDir[3];
	SubtractVectors(vecNPCCenter, vecPlayerCenter, vecDir); 
	
	NormalizeVector(vecDir, vecDir);

	float vecAng[3];
	GetVectorAngles(vecDir, vecAng);
	
	float flPitch = animationEntity.GetPoseParameter(iPitch);
	float flYaw = animationEntity.GetPoseParameter(iYaw);
	
	vecAng[0] = UTIL_Clamp(UTIL_AngleNormalize(vecAng[0]), -44.0, 89.0);
	animationEntity.SetPoseParameter(pModelptr, iPitch, UTIL_ApproachAngle(vecAng[0], flPitch, 1.0));
	
	vecAng[1] = UTIL_Clamp(-UTIL_AngleNormalize(UTIL_AngleDiff(UTIL_AngleNormalize(vecAng[1]), UTIL_AngleNormalize(vecNPCAng[1] + 180.0))), -44.0,  44.0);
	animationEntity.SetPoseParameter(pModelptr, iYaw, UTIL_ApproachAngle(vecAng[1], flYaw, 1.0));
	
	int iMoveX = animationEntity.LookupPoseParameter(pModelptr, "move_x");
	int iMoveY = animationEntity.LookupPoseParameter(pModelptr, "move_y");
	
	if (iMoveX < 0 || iMoveY < 0)
		return;
	
	float flGroundSpeed = loco.GetGroundSpeed();

	if (flGroundSpeed != 0.0)
	{
		if (!(GetEntityFlags(entity) & FL_ONGROUND))
		{
			if (iSequence != sequence_air_walk)
				animationEntity.ResetSequence(sequence_air_walk);
		}
		else
		{			
			if (iSequence != sequence_run)
				animationEntity.ResetSequence(sequence_run);
		}

		float vecForward[3]; float vecRight[3]; float vecUp[3];
		npc.GetVectors(vecForward, vecRight, vecUp);

		float vecMotion[3];
		loco.GetGroundMotionVector(vecMotion);

		float newMoveX = (vecForward[1] * vecMotion[1]) + (vecForward[0] * vecMotion[0]) +  (vecForward[2] * vecMotion[2]);
		float newMoveY = (vecRight[1] * vecMotion[1]) + (vecRight[0] * vecMotion[0]) + (vecRight[2] * vecMotion[2]);
		
		animationEntity.SetPoseParameter(pModelptr, iMoveX, newMoveX);
		animationEntity.SetPoseParameter(pModelptr, iMoveY, newMoveY);

		//PrintToChatAll("step");
		//EmitGameSoundToAll("Default.StepLeft", entity);
	}
	else
	{
		if (iSequence != sequence_idle)
			animationEntity.ResetSequence(sequence_idle);
	}
}

int GetZombieTarget()
{
	int[] clients = new int[MaxClients];
	int amount;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;
		
		clients[amount++] = i;
	}

	return (amount == 0) ? -1 : clients[GetRandomInt(0, amount - 1)];
}

public Action OnZombiesTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	if (hitbox == 0 && hitgroup == 1)
	{
		damage *= 1.10;
		damagetype |= DMG_CRIT;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action OnZombieDamaged(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(victim);

	if (npc == INVALID_NPC || IsPlayerIndex(attacker) && GetClientTeam(attacker) == npc.iTeamNum)
		return Plugin_Continue;
	
	if (g_Match.pausezombies)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	bool changed;
	if (IsPlayerIndex(attacker) && g_Player[attacker].instakill != -1 && g_Player[attacker].instakill > GetTime())
	{
		damage = 999999.0;
		changed = true;
	}

	if ((damagetype & DMG_CRIT) == DMG_CRIT)
	{
		EmitSoundToClient(attacker, "player/crit_received1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, 95);
		if (attacker > 0 && attacker != victim)
		{
			TE_Particle("crit_text", damagePosition);
			EmitSoundToClient(attacker, "player/crit_hit.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, 85);
		}
	}
	
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnZombieDamagedPost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], float damagePosition[3], int damagecustom)
{
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(victim);

	if (npc == INVALID_NPC)
		return;

	if (convar_BloodFx.BoolValue && GetRandomFloat(0.0, 100.0) >= 50.0)
		TE_Particle(sBloodParticles[GetRandomInt(0, 4)], damagePosition, victim);
	
	if (!g_Match.pausezombies && GetRandomFloat(0.0, 100.0) >= 75.0)
		PlayZombieSound(victim);

	if (IsPlayerIndex(attacker) && GetClientTeam(attacker) == npc.iTeamNum)
		return;
	
	bool doublepoints;
	if (IsPlayerIndex(attacker))
		doublepoints = g_Player[attacker].doublepoints != -1 && g_Player[attacker].doublepoints > GetTime();
	
	if (RoundFloat(damage) >= npc.iHealth)
	{
		if (IsPlayerIndex(attacker))
		{
			int points = doublepoints ? 200 : 100;

			if (GetActiveWeaponSlot(attacker) == 2)
				points = RoundFloat(float(points) * 1.5);
			
			g_Player[attacker].AddPoints(points);
		}

		OnZombieDeath(victim, true, true, attacker);
		g_Player[attacker].zombiekills++;
	}
	else if (IsPlayerIndex(attacker))
	{
		int points = doublepoints ? 20 : 10;

		if (GetActiveWeaponSlot(attacker) == 2)
			points = RoundFloat(float(points) * 1.5);
		
		g_Player[attacker].AddPoints(doublepoints ? 20 : 10);
		g_Player[attacker].AddStat(STAT_DAMAGE, RoundFloat(damage));
	}
}

public MRESReturn OnZombieAnimation(int pThis, Handle hParams)
{	
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(pThis);

	if (npc == INVALID_NPC)
		return;
	
	CBaseAnimating anim = CBaseAnimating(pThis);

	int iEvent = DHookGetParamObjectPtrVar(hParams, 1, 0, ObjectValueType_Int);
	//PrintToServer("OnZombieAnimation(%i, %i)", pThis, iEvent);
	
	if (iEvent == 54)
	{
		//PrintToServer("InfectedAttack::OnPunch");
		//npc.OnPunch();
	}
	
	char strSound[64];
	
	float vSoundPos[3], vFootAngles[3];
	if (iEvent == 53)
		anim.GetAttachment(anim.FindAttachment("lfoot"), vSoundPos, vFootAngles);
	else if (iEvent == 52)
		anim.GetAttachment(anim.FindAttachment("rfoot"), vSoundPos, vFootAngles);
	
	TR_TraceRayFilter(vSoundPos, view_as<float>( { 90.0, 90.0, 90.0 } ), MASK_NPCSOLID|MASK_PLAYERSOLID, RayType_Infinite, FilterBaseActorsAndData, pThis);
	char material[PLATFORM_MAX_PATH]; TR_GetSurfaceName(null, material, PLATFORM_MAX_PATH);
	
	Format(strSound, sizeof(strSound), "%s.%s", GetStepSoundForMaterial(material) , iEvent == 53 ? "StepLeft" : "StepRight");
	
	//PrintToServer("Step on %s", material);
	
	g_Zombies[npc.Index].PlayStepSound(strSound, vSoundPos);

	if (g_Zombies[npc.Index].type == GetZombieTypeByName("Tank Heavy"))
	{
		float origin[3];
		GetEntityOrigin(pThis, origin);
		ScreenShakeAll(SHAKE_START, 15.0, 15.0, 1.0, 1000.0, origin);
	}
}

public bool FilterBaseActorsAndData(int entity, int contentsMask, any data)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	
	if (StrEqual(class, "base_boss"))return false;
	if (StrEqual(class, "player"))return false;
	
	return !(entity == data);
}

char[] GetStepSoundForMaterial(const char[] material)
{
	char sound[32]; sound = "Default";
	
	if (StrContains(material, "wood", false) != -1)sound = "Wood";
	else if (StrContains(material, "Metal", false) != -1)sound = "SolidMetal";
	else if (StrContains(material, "Tile", false) != -1)sound = "Tile";
	else if (StrContains(material, "Concrete", false) != -1)sound = "Concrete";
	else if (StrContains(material, "Gravel", false) != -1)sound = "Gravel";
	else if (StrContains(material, "ChainLink", false) != -1)sound = "ChainLink";
	else if (StrContains(material, "Flesh", false) != -1)sound = "Flesh";
	
	return sound;
}

bool PushPlayersFromPoint(float point[3], float magnitude = 50.0, float radius = 0.0, int team = 0, int attacker = 0)
{
	if (magnitude <= 0.0)
		return false;

	float vecOrigin[3]; float vector[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (team > 0 && team != GetClientTeam(i)) || (attacker > 0 && i == attacker))
			continue;

		GetClientAbsOrigin(i, vecOrigin);

		if (radius > 0.0 && GetVectorDistance(point, vecOrigin) > radius)
			continue;

		MakeVectorFromPoints(point, vecOrigin, vector);

		NormalizeVector(vector, vector);
		ScaleVector(vector, magnitude);

		if (GetEntityFlags(i) & FL_ONGROUND && vector[2] < 251.0)
			vector[2] = 251.0;

		TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vector);
	}

	return true;
}

public Action Command_StartMatch(int client, int args)
{
	if (g_Match.roundphase != PHASE_STARTING)
	{
		CPrintToChat(client, "Must be during the lobby phase to use this command.");
		return Plugin_Handled;
	}

	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		ServerCommand("mp_waitingforplayers_cancel 1");

	g_Match.roundtime = 5;
	g_Match.pausetimer = false;
	g_Match.UnpauseZombies();

	CPrintToChatAll("{haunted}%N {default}has started the match.", client);

	CreateTF2Timer(g_Match.roundtime);

	return Plugin_Handled;
}

public void TF2_OnPlayerSpawn(int client, int team, int class)
{
	CreateTimer(0.2, Timer_DelaySpawn, GetClientUserId(client));
}

public Action Timer_DelaySpawn(Handle timer, any data)
{
	int client = GetClientOfUserId(data);

	if (!IsPlayerIndex(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	g_Player[client].Clean(false);
	StopTimer(g_Player[client].revivetimer);

	TF2Attrib_RemoveMoveSpeedBonus(client);
	TF2Attrib_RemoveMoveSpeedPenalty(client);

	if (GetClientTeam(client) == TEAM_ZOMBIES)
	{
		TF2_RemoveAllWearables(client);
		
		int index;
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: index = 5617;
			case TFClass_Soldier: index = 5618;
			case TFClass_Pyro: index = 5624;
			case TFClass_DemoMan: index = 5620;
			case TFClass_Heavy: index = 5619;
			case TFClass_Engineer: index = 5621;
			case TFClass_Medic: index = 5622;
			case TFClass_Sniper: index = 5625;
			case TFClass_Spy: index = 5623;
		}

		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2_RegeneratePlayer(client);
		TF2_RemoveAllWearables(client);

		int wearable = -1;
		if ((wearable = TF2Items_EquipWearable(client, "tf_wearable", index, 0, 10)) != -1)
		{
			g_Player[client].wearable = EntIndexToEntRef(wearable);
			TF2Attrib_SetByName(wearable, "player skin override", 1.0);
		}

		OverlayCommand(client, "effects/combine_binocoverlay");
		StripPlayer(client, true);

		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:
				TF2Attrib_ApplyMoveSpeedPenalty(client, 0.5);
			case TFClass_Heavy:
				TF2Attrib_ApplyMoveSpeedPenalty(client, 0.13);
			case TFClass_Engineer:
				TF2Attrib_ApplyMoveSpeedPenalty(client, 0.34);
			case TFClass_Sniper:
				TF2Attrib_ApplyMoveSpeedPenalty(client, 0.34);
		}

		g_Player[client].type = GetZombieTypeByName(ZOMBIE_DEFAULT);

		if (g_Match.pausezombies)
			TF2_AddCondition(client, TFCond_FreezeInput);
	}
	else
	{
		TF2Attrib_RemoveByName(client, "player skin override");
		
		TFClassType class = TF2_GetPlayerClass(client);

		if (class != TFClass_Scout && class != TFClass_Heavy && class != TFClass_Engineer && class != TFClass_Sniper)
			TF2_SetPlayerClass(client, TFClass_Scout);
		
		TF2_RemoveAllWearables(client);
		TF2_RegeneratePlayer(client);

		OverlayCommand(client, "\"\"");
		StripPlayer(client, false);

		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:
				TF2Attrib_ApplyMoveSpeedPenalty(client, 0.3);
			case TFClass_Heavy:
				TF2Attrib_ApplyMoveSpeedBonus(client, 0.2);
			case TFClass_Engineer:
				TF2Attrib_ApplyMoveSpeedPenalty(client, 0.1);
			case TFClass_Sniper:
				TF2Attrib_ApplyMoveSpeedPenalty(client, 0.1);
		}

		if (g_Match.roundphase == PHASE_WAITING || g_Match.roundphase == PHASE_ACTIVE)
		{
			if (g_Player[client].primary != -1)
				GiveCustomWeapon(client, g_Player[client].primary);
			
			if (g_Player[client].secondary != -1)
				GiveCustomWeapon(client, g_Player[client].secondary);
			
			if (g_Player[client].melee != -1)
				GiveCustomWeapon(client, g_Player[client].melee);
			
			g_Player[client].primary = -1;
			g_Player[client].secondary = -1;
			g_Player[client].melee = -1;

			//g_Player[client].ApplyPerks(true);
		}

		//g_Player[client].CreateGlow();
	}
	
	if (g_Match.roundphase == PHASE_HIBERNATION)
		InitLobby();

	return Plugin_Stop;
}

int TF2_AttachBasicGlow(int entity)
{
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, PLATFORM_MAX_PATH);
	
	if (strlen(model) == 0)
		return -1;
	
	int prop = CreateEntityByName("tf_taunt_prop");
	
	if (IsValidEntity(prop))
	{
		DispatchSpawn(prop);
		SetEntityModel(prop, model);

		SetEntPropEnt(prop, Prop_Data, "m_hEffectEntity", entity);
		SetEntProp(prop, Prop_Send, "m_bGlowEnabled", 1);		
		SetEntProp(prop, Prop_Send, "m_fEffects", GetEntProp(prop, Prop_Send, "m_fEffects") | EF_BONEMERGE | EF_NOSHADOW | EF_NOINTERP);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", entity);
		
		SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
		SetEntityRenderColor(prop, 255, 0, 0, 0);
	}

	return prop;
}

public Action OnGlowTransmit(int entity, int client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_ZOMBIES)
		return Plugin_Continue;
	
	return Plugin_Stop;
}

void OverlayCommand(int client, char[] overlay) 
{    
	if (IsClientInGame(client)) 
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		ClientCommand(client, "r_screenoverlay %s", overlay);
	}
}

public void TF2_OnClassChangePost(int client, TFClassType class)
{
	CreateTimer(0.2, Timer_ClassChange, GetClientUserId(client));
}

public Action Timer_ClassChange(Handle timer, any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) > 0)
	{
		StripPlayer(client);

		TF2Attrib_RemoveMoveSpeedBonus(client);
		TF2Attrib_RemoveMoveSpeedPenalty(client);
	}
}

public Action Command_PauseTimer(int client, int args)
{
	if (g_Match.pausetimer)
	{
		CPrintToChat(client, "Round is currently paused already.");
		return Plugin_Handled;
	}

	g_Match.pausetimer = true;
	g_Match.PauseZombies();
	CPrintToChatAll("%N has {haunted}%spaused {default}the round timer.", client, g_Match.pausetimer ? "" : "un");

	PauseTF2Timer();

	return Plugin_Handled;
}

public Action Command_UnpauseTimer(int client, int args)
{
	if (!g_Match.pausetimer)
	{
		CPrintToChat(client, "Round is currently not paused.");
		return Plugin_Handled;
	}

	g_Match.pausetimer = false;
	g_Match.UnpauseZombies();
	CPrintToChatAll("%N has {haunted}%spaused {default}the round timer.", client, g_Match.pausetimer ? "" : "un");

	UnpauseTF2Timer();

	return Plugin_Handled;
}

public Action Command_PauseZombies(int client, int args)
{
	if (g_Match.pausezombies)
	{
		CPrintToChat(client, "Zombies are currently paused already.");
		return Plugin_Handled;
	}

	g_Match.PauseZombies();
	CPrintToChatAll("%N has {haunted}%sfrozen {default}the zombies.", client, g_Match.pausezombies ? "" : "un");

	return Plugin_Handled;
}

public Action Command_UnpauseZombies(int client, int args)
{
	if (!g_Match.pausezombies)
	{
		CPrintToChat(client, "Zombies are currently not paused.");
		return Plugin_Handled;
	}

	g_Match.UnpauseZombies();
	CPrintToChatAll("%N has {haunted}%sfrozen {default}the zombies.", client, g_Match.pausezombies ? "" : "un");

	return Plugin_Handled;
}

public void OnClientConnected(int client)
{
	g_Player[client].Init(client);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public Action OnGetMaxHealth(int client, int &MaxHealth)
{
	if (IsPlayerIndex(client) && IsClientInGame(client))
	{
		MaxHealth = CalculateHealth(client);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	char class[32];
	if (attacker > 0)
		GetEntityClassname(attacker, class, sizeof(class));

	if (g_Match.roundphase == PHASE_STARTING || StrEqual(class, "base_boss", false))
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	bool changed;
	if (GetClientTeam(victim) == TEAM_ZOMBIES)
	{
		if (IsPlayerIndex(attacker) && g_Player[attacker].instakill != -1 && g_Player[attacker].instakill > GetTime())
		{
			damage = 999999.0;
			changed = true;
		}

		if ((damagetype & DMG_CRIT) == DMG_CRIT)
		{
			EmitSoundToClient(attacker, "player/crit_received1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, 95);
			if (attacker > 0 && attacker != victim)
			{
				TE_Particle("crit_text", damagePosition);
				EmitSoundToClient(attacker, "player/crit_hit.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, 85);
			}
		}
	}
	
	if (attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == TEAM_ZOMBIES)
	{
		damage = CalculateDamage();
		changed = true;
		
		SpeakResponseConcept(victim, "TLK_PLAYER_PAIN");

		int type = g_Player[attacker].type;

		if (type == GetZombieTypeByName("Ignition Pyro"))
			g_Player[victim].SetOnFire();
		else if (type == GetZombieTypeByName("Spikey Bois"))
			g_Player[victim].Bleed();
		
		EmitSoundToAll(GetRandomInt(0, 1) == 0 ? "weapons/fist_hit_world1.wav" : "weapons/fist_hit_world2.wav", victim);
		g_Player[victim].RegenTimer();
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsPlayerIndex(attacker))
		g_Player[attacker].AddStat(STAT_DAMAGE, RoundFloat(damage));

	if (GetClientTeam(victim) != TEAM_ZOMBIES)
		return;
	
	if (convar_BloodFx.BoolValue && GetRandomFloat(0.0, 100.0) >= 50.0)
		TE_Particle(sBloodParticles[GetRandomInt(0, 4)], damagePosition, victim);
	
	if (!g_Match.pausezombies && GetRandomFloat(0.0, 100.0) >= 75.0 && IsPlayerAlive(victim))
		PlayZombieSound(victim);

	if (IsPlayerIndex(attacker) && GetClientTeam(attacker) == GetClientTeam(victim))
		return;
	
	bool doublepoints;
	if (IsPlayerIndex(attacker))
		doublepoints = g_Player[attacker].doublepoints != -1 && g_Player[attacker].doublepoints > GetTime();
	
	int points = doublepoints ? 20 : 10;

	if (IsPlayerIndex(attacker) && GetActiveWeaponSlot(attacker) == 2)
		points = RoundFloat(float(points) * 1.5);
	
	if (IsPlayerIndex(attacker))
		g_Player[attacker].AddPoints(doublepoints ? 20 : 10);
}

public void OnClientPostAdminCheck(int client)
{
	QueryClientConVar(client, "cl_downloadfilter", OnCheckDownloadsFilter);
}

public void OnCheckDownloadsFilter(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (strcmp(cvarValue, "all", false) == 0 || strcmp(cvarValue, "nosounds", false) == 0)
		return;
	
	KickClient(client, "Your setting for cl_downloadfilter is wrong, please set it to \"all\".");
} 

public void OnClientDisconnect(int client)
{
	g_Player[client].Clean();
	CreateTimer(0.5, Timer_ParseRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);

	if (IsValidEntity(g_Player[client].revivemarker))
		AcceptEntityInput(g_Player[client].revivemarker, "Kill");

	if (GetClientAbsCount() < 1)
		g_Match.Reset();
}

public void OnClientDisconnect_Post(int client)
{
	g_Player[client].Clear();
	StopTimer(g_Player[client].revivetimer);
}

public Action OnClientCommand(int client, int args)
{
	char sCommand[32];
	GetCmdArg(0, sCommand, sizeof(sCommand));

	char sArguments[32];
	GetCmdArgString(sArguments, sizeof(sArguments));

	//PrintToDrixevel("%s %s", sCommand, sArguments);

	if (StrEqual(sCommand, "jointeam", false))
	{
		int team;
		if (StrEqual(sArguments, "auto", false))
			team = -1;
		else if (StrEqual(sArguments, "red", false) || StrEqual(sArguments, "2", false))
			team = TEAM_ZOMBIES;
		else if (StrEqual(sArguments, "blue", false) || StrEqual(sArguments, "3", false))
			team = TEAM_SURVIVORS;
		
		if (team == -1)
		{
			TF2_ChangeClientTeam(client, view_as<TFTeam>(TEAM_SURVIVORS));
			ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
			return Plugin_Stop;
		}
		
		if (team != TEAM_ZOMBIES && team != TEAM_SURVIVORS)
			return Plugin_Continue;

		if (!IsDrixevel(client) && team == TEAM_ZOMBIES && g_Match.roundphase != PHASE_STARTING)
		{
			ShowVGUIPanel(client, "team");
			PrintErrorMessage(client, "Match must be starting to become a Zombie.");
			return Plugin_Stop;
		}

		if (!IsDrixevel(client) && team == TEAM_ZOMBIES && GetTeamAbsCount(TEAM_SURVIVORS) < 1)
		{
			ShowVGUIPanel(client, "team");
			PrintErrorMessage(client, "Match must consist of 1 Survivor already in order to become a Zombie. (besides yourself)");
			return Plugin_Stop;
		}

		return Plugin_Continue;
	}
	else if (StrEqual(sCommand, "joinclass", false) && GetClientTeam(client) != TEAM_ZOMBIES)
	{
		//Scout, Heavy, Engineer, and Sniper
		if (StrContains(sArguments, "scout", false) == -1 && StrContains(sArguments, "heavy", false) == -1 && StrContains(sArguments, "engineer", false) == -1 && StrContains(sArguments, "sniper", false) == -1)
		{
			ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
			PrintErrorMessage(client, "You must be either a Scout, Heavy, Engineer or Sniper.");
			return Plugin_Stop;
		}
	}
	else if (StrEqual(sCommand, "eureka_teleport", false))
	{
		PrintErrorMessage(client, "You are not allowed to use the Eureka Effect.");
		return Plugin_Stop;
	}
	else if ((StrEqual(sCommand, "voicemenu", false) || StrContains(sCommand, "taunt", false) != -1) && GetClientTeam(client) == TEAM_ZOMBIES)
	{
		if (g_Match.pausezombies)
			return Plugin_Stop;
		
		float time = GetGameTime();

		if (!IsPlayerAlive(client))
			PrintErrorMessage(client, "You must be alive... but dead? to spam zombie noises like degenerate.");
		else
		{
			if (g_Player[client].sounds == -1.0 || g_Player[client].sounds != -1.0 && g_Player[client].sounds <= time)
			{
				PlayZombieSound(client);
				g_Player[client].sounds = GetZombieSoundDuration(client);
			}
			else
				PrintErrorMessage(client, "Please wait %i seconds to BRAAAAAAAAAAAAAAAAAINS again.", RoundFloat(g_Player[client].sounds - time));
		}

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void OnGameFrame()
{
	if (g_Match.pausetimer)
		return;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if (g_Machines[entity].index != -1)
			OnMachineTick(entity);
		else if (g_SpawnedWeapons[entity].index != -1)
			OnWeaponTick(entity);
		else if (g_MysteryBox[entity].status)
			OnMysteryBoxTick(entity);
	}

	entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_brush")) != -1)
		if (HasName(entity, "plank_"))
			OnPlankTick(entity);

	entity = -1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != -1)
		if (g_InteractableType[entity] == INTERACTABLE_TYPE_BUILDING)
			OnBuildingTick(entity);
	
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_door")) != -1)
		if (g_InteractableType[entity] == INTERACTABLE_TYPE_DOORS)
			OnDoorTick(entity);
	
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_door*")) != -1)
		if (g_InteractableType[entity] == INTERACTABLE_TYPE_DOORS)
			OnDoorTick(entity);
	
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_halloween_pickup")) != -1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS || GetEntitiesDistance(i, entity) > 100.0)
				continue;
			
			OnPowerupPickup(i, entity);
		}
	}
}

public Action TF2_OnCallMedic(int client)
{
	if (g_Match.pausetimer || GetClientTeam(client) == TEAM_ZOMBIES)
		return Plugin_Stop;
	
	g_Player[client].interact = GetTime() + 2;
	int near = g_Player[client].nearinteractable;

	if (near != -1 && g_InteractableType[near] == INTERACTABLE_TYPE_MACHINE)
	{
		int entity = near;
		int index = g_Machines[entity].index;

		bool doublepoints = g_Player[client].doublepoints != -1 && g_Player[client].doublepoints > GetTime();

		int active = GetActiveWeapon(client);

		char sEntity[64];
		IntToString(active, sEntity, sizeof(sEntity));

		int value;
		g_PackaPunchUpgrades.GetValue(sEntity, value);

		if (g_Machines[entity].index == g_Match.coins_machine && GetEntityFlags(client) & FL_DUCKING)
		{
			g_Player[client].AddPoints(doublepoints ? 100 : 50);
			EmitGameSoundToAll("MVM.MoneyPickup", client);
			g_Match.coins_machine = -1;
		}
		else if (StrEqual(g_MachinesData[index].name, "packapunch", false) && value >= 4)
		{
			SpeakResponseConcept(client, "TLK_PLAYER_JEERS");
			PrintErrorMessage(client, "This weapon is max level for packapunch.");
		}
		else if (!g_Player[client].RemovePoints(g_Machines[entity].price))
		{
			SpeakResponseConcept(client, "TLK_PLAYER_JEERS");
			PrintErrorMessage(client, "You must have {haunted}%i {default}points to unlock this perk.", g_Machines[entity].price);
		}
		else if (g_Player[client].HasPerk(g_MachinesData[index].name))
		{
			SpeakResponseConcept(client, "TLK_PLAYER_JEERS");

			if (GetMachineMax(g_MachinesData[index].name) == 1)
				PrintErrorMessage(client, "You have already purchased this perk.");
			else
				PrintErrorMessage(client, "You have maxed out the amount of perks for this machine.");
		}
		else
		{
			SpeakResponseConcept(client, "TLK_PLAYER_CHEERS");
			EmitGameSoundToClient(client, "MVM.PlayerUpgraded");

			char sSound[PLATFORM_MAX_PATH];
			FormatEx(sSound, sizeof(sSound), "undead/machines/%s.wav", g_MachinesData[index].name);
			EmitSoundToAll(sSound, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, entity, NULL_VECTOR, NULL_VECTOR, true, 0.0);

			g_Player[client].AddPerk(g_MachinesData[index].name);
			CPrintToChat(client, "You have purchased the Machine perk: {haunted}%s", g_MachinesData[index].display);

			if (IsPlayerIndex(client))
				g_Player[client].AddStat(STAT_MACHINES, 1);

			g_Player[client].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(client);
		}
	}

	if (near != -1 && g_InteractableType[near] == INTERACTABLE_TYPE_WEAPON)
	{
		int entity = near;
		int index = g_SpawnedWeapons[entity].index;

		char sClasses[2048];
		TF2Items_GetItemKeyString(g_CustomWeapons[index].name, "classes", sClasses, sizeof(sClasses));

		char sClass[32];
		TF2_GetClientClassName(client, sClass, sizeof(sClass));

		int price = g_SpawnedWeapons[entity].price;
		int slot = TF2Items_GetItemKeyInt(g_CustomWeapons[index].name, "slot");

		int weapon = GetPlayerWeaponSlot(client, slot);
		if (IsValidEntity(weapon) && g_WeaponIndex[weapon] == index)
			price /= 2;

		if (StrContains(sClasses, sClass, false) == -1 || !g_Player[client].RemovePoints(price))
		{
			SpeakResponseConcept(client, "TLK_PLAYER_JEERS");
			EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
		}
		else
		{
			SpeakResponseConcept(client, "TLK_PLAYER_CHEERS");
			EmitGameSoundToClient(client, "MVM.PlayerUpgraded");

			GiveWallWeapon(client, index, slot);

			if (IsValidEntity(weapon) && g_WeaponIndex[weapon] == index)
				CPrintToChat(client, "You have purchased ammo for your weapon: {haunted}%s", g_CustomWeapons[index].name);
			else
				CPrintToChat(client, "You have purchased the Weapon: {haunted}%s", g_CustomWeapons[index].name);

			if (IsPlayerIndex(client))
				g_Player[client].AddStat(STAT_WEAPONS, 1);

			g_Player[client].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(client);
		}
	}

	if (near != -1 && g_InteractableType[near] == INTERACTABLE_TYPE_MYSTERYBOX)
	{
		int entity = near;

		if (g_MysteryBox[entity].inuse || !g_Player[client].RemovePoints(g_MysteryBox[entity].price))
		{
			SpeakResponseConcept(client, "TLK_PLAYER_JEERS");
			EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
		}
		else
		{
			OpenMysteryBox(client, entity);
			EmitGameSoundToClient(client, "MVM.PlayerUpgraded");
			CPrintToChat(client, "You have opened the {haunted}Mystery Box{default}.");

			if (IsPlayerIndex(client))
				g_Player[client].AddStat(STAT_MYSTERYBOXES, 1);

			g_Player[client].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(client);
		}
	}

	if (near != -1 && g_InteractableType[near] == INTERACTABLE_TYPE_PLANK)
	{
		int entity = near;

		if (!GetEntProp(entity, Prop_Data, "m_iDisabled") || (g_RebuildDelay[entity] != -1.0 && g_RebuildDelay[entity] > GetGameTime()))
			EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
		else
		{
			g_Player[client].AddPoints(75);
			EmitGameSoundToClient(client, "MVM.PlayerUpgraded");

			ResetPlank(entity);
			CPrintToChat(client, "You have rebuilt a {haunted}plank{default}.");

			if (IsPlayerIndex(client))
				g_Player[client].AddStat(STAT_PLANKS, 1);

			g_Player[client].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(client);
		}
	}
	
	if (near != -1 && g_InteractableType[near] == INTERACTABLE_TYPE_BUILDING)
	{
		int entity = near;
	
		char sCost[64];
		GetCustomKeyValue(entity, "udm_cost", sCost, sizeof(sCost));
	
		char sDuration[64];
		GetCustomKeyValue(entity, "udm_duration", sDuration, sizeof(sDuration));
		
		if (GetEntProp(entity, Prop_Send, "m_bDisabled") == 0 || g_RechargeBuilding[entity] != -1 && g_RechargeBuilding[entity] > GetTime() || !g_Player[client].RemovePoints(StringToInt(sCost)))
		{
			EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
		}
		else
		{
			EmitGameSoundToClient(client, "MVM.PlayerUpgraded");

			char sBuilding[64];
			switch (TF2_GetObjectType(entity))
			{
				case TFObject_Dispenser:
					strcopy(sBuilding, sizeof(sBuilding), "Dispenser");
				case TFObject_Teleporter:
				{
					switch (TF2_GetObjectMode(entity))
					{
						case TFObjectMode_Entrance:
							strcopy(sBuilding, sizeof(sBuilding), "Teleporter Entrance");
						case TFObjectMode_Exit:
							strcopy(sBuilding, sizeof(sBuilding), "Teleporter Exit");
					}
				}
				case TFObject_Sentry:
					strcopy(sBuilding, sizeof(sBuilding), "Sentry");
				case TFObject_Sapper:
					strcopy(sBuilding, sizeof(sBuilding), "Sapper");
			}

			SetEntProp(entity, Prop_Send, "m_bDisabled", 0);
			g_DisableBuilding[entity] = GetTime() + StringToInt(sDuration);
			CPrintToChat(client, "You have rented this {haunted}%s{default}.", sBuilding);

			float origin[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

			char sAnno[64];
			FormatEx(sAnno, sizeof(sAnno), "%s Active", sBuilding);
			TF2_CreateAnnotationToAll(origin, sAnno, StringToFloat(sDuration), "vo/null.wav");

			if (IsPlayerIndex(client))
				g_Player[client].AddStat(STAT_BUILDINGS, 1);
			
			g_Player[client].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(client);
		}
	}

	if (near != -1 && g_InteractableType[near] == INTERACTABLE_TYPE_DOORS)
	{
		int entity = near;
	
		char sCost[64];
		GetCustomKeyValue(entity, "udm_cost", sCost, sizeof(sCost));
		
		if (!g_Player[client].RemovePoints(StringToInt(sCost)))
		{
			EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
		}
		else
		{
			EmitGameSoundToClient(client, "MVM.PlayerUpgraded");

			AcceptEntityInput(entity, "Open");
			CPrintToChat(client, "You have opened this {haunted}door{default}.");

			float origin[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

			char sAnno[64];
			FormatEx(sAnno, sizeof(sAnno), "Door Opened");
			TF2_CreateAnnotationToAll(origin, sAnno, 5.0, "vo/null.wav");

			if (IsPlayerIndex(client))
				g_Player[client].AddStat(STAT_DOORS, 1);
			
			g_Player[client].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(client);
		}
	}

	return Plugin_Stop;
}

/****************************************/
//Machines
/****************************************/

void ParseMachines()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/undead/machines.cfg");

	KeyValues kv = new KeyValues("machines");

	if (kv.ImportFromFile(sPath) && kv.GotoFirstSubKey())
	{
		g_TotalMachines = 0;

		do
		{
			kv.GetSectionName(g_MachinesData[g_TotalMachines].name, 64);
			kv.GetString("display", g_MachinesData[g_TotalMachines].display, 128);
			kv.GetString("description", g_MachinesData[g_TotalMachines].description, 128);
			kv.GetString("model", g_MachinesData[g_TotalMachines].model, PLATFORM_MAX_PATH);
			g_MachinesData[g_TotalMachines].z_offset = kv.GetFloat("z_offset");
			g_MachinesData[g_TotalMachines].max = kv.GetNum("max");
			g_TotalMachines++;
		}
		while (kv.GotoNextKey());
	}

	delete kv;
	LogMessage("Machines Loaded: %i", g_TotalMachines);
}

void SpawnMachines()
{
	int entity = -1; int unlock;
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		if (!HasName(entity, "onMachineSpawn"))
			continue;
		
		unlock = GetWaveUnlockInt(entity);
		
		char sMachine[64];
		GetCustomKeyValue(entity, "udm_machine", sMachine, sizeof(sMachine));

		char sCost[64];
		GetCustomKeyValue(entity, "udm_cost", sCost, sizeof(sCost));

		float origin[3];
		GetEntityOrigin(entity, origin);

		float angles[3];
		GetEntityAngles(entity, angles);

		int index = GetMachine(sMachine);

		if (index == -1 || !IsModelPrecached(g_MachinesData[index].model))
			continue;
		
		origin[2] += g_MachinesData[index].z_offset;

		int machine = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(machine, "model", g_MachinesData[index].model);
		DispatchKeyValueVector(machine, "origin", origin);
		DispatchKeyValueVector(machine, "angles", angles);
		DispatchSpawn(machine);

		SetEntitySolidType(machine, SOLID_TYPE_VPHYSICS);
		SetEntityCollisionGroup(machine, COLLISION_GROUP_INTERACTIVE);

		int glow = TF2_CreateGlow("machine_color", machine, view_as<int>({200, 200, 255, 150}));

		g_Machines[machine].entity = machine;
		g_Machines[machine].index = index;
		g_Machines[machine].price = StringToInt(sCost);
		g_Machines[machine].unlock = unlock;
		g_Machines[machine].glow = glow;
		g_Machines[machine].StartSound();
		g_InteractableType[machine] = INTERACTABLE_TYPE_MACHINE;

		SDKHook(machine, SDKHook_OnTakeDamagePost, OnMachineDamage);
	}
}

public void OnMachineDamage(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if (attacker == 0)
		return;
	
	int entity = CreateEntityByName("env_spark");
	DispatchKeyValueVector(entity, "origin", damagePosition);
	DispatchKeyValue(entity, "Magnitude", "4");
	DispatchKeyValue(entity, "MaxDelay", "3");
	DispatchKeyValue(entity, "TrailLength", "2");
	DispatchSpawn(entity);
	
	AcceptEntityInput(entity, "StartSpark");
	
	SetVariantString("OnUser1 !self:kill::0.3:1");
	AcceptEntityInput(entity, "AddOutput");
	
	AcceptEntityInput(entity, "FireUser1");
}

void OnMachineTick(int entity)
{
	int unlock = g_Machines[entity].unlock;
	int index = g_Machines[entity].index;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;
		
		if (IsVisibleTo(i, entity, 100.0, false, 80.0))
		{
			if (unlock <= g_Match.round + 1)
			{
				g_Player[i].nearinteractable = entity;

				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "Press 'MEDIC!' to purchase %s for %i points.\n - %s", g_MachinesData[index].display, g_Machines[entity].price, g_MachinesData[index].description);
			}
			else
			{
				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "[%s locked until round %i]", g_MachinesData[index].display, unlock);
			}
		}
		else if (g_Player[i].nearinteractable == entity)
		{
			g_Player[i].nearinteractable = - 1;
			g_Sync_NearInteractable.Clear(i);
		}
	}
}

int GetMachine(const char[] name)
{
	for (int i = 0; i <= g_TotalMachines; i++)
		if (StrEqual(name, g_MachinesData[i].name, false))
			return i;
	
	return -1;
}

void GetMachineDisplay(const char[] name, char[] display, int size)
{
	for (int i = 0; i <= g_TotalMachines; i++)
		if (StrEqual(g_MachinesData[i].name, name, false))
			strcopy(display, size, g_MachinesData[i].display);
}

int GetMachineMax(const char[] name)
{
	for (int i = 0; i <= g_TotalMachines; i++)
		if (StrEqual(name, g_MachinesData[i].name, false))
			return g_MachinesData[i].max;
	
	return 0;
}

void DestroyMachines()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if (g_Machines[entity].index != -1)
			AcceptEntityInput(entity, "Kill");
		
		g_Machines[entity].Reset();
	}	
}

void TF2Attrib_SetFireRateBonus(int weapon, float bonus)
{
	float firerate;
	Address addr = TF2Attrib_GetByName(weapon, "fire rate bonus");

	firerate = addr != Address_Null ? TF2Attrib_GetValue(addr) - bonus : 1.00 - bonus;
	TF2Attrib_SetByName(weapon, "fire rate bonus", firerate);
}

/****************************************/
//Weapons
/****************************************/

void ParseWeapons()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/undead/weapons.cfg");

	KeyValues kv = new KeyValues("weapons");

	if (kv.ImportFromFile(sPath) && kv.GotoFirstSubKey())
	{
		g_TotalCustomWeapons = 0;

		do
		{
			kv.GetSectionName(g_CustomWeapons[g_TotalCustomWeapons].name, 64);
			g_CustomWeapons[g_TotalCustomWeapons].name[0] = CharToUpper(g_CustomWeapons[g_TotalCustomWeapons].name[0]);
			kv.GetVector("offset_angles", g_CustomWeapons[g_TotalCustomWeapons].offset_angles);
			g_CustomWeapons[g_TotalCustomWeapons].mystery_box = view_as<bool>(kv.GetNum("mystery_box"));
			g_TotalCustomWeapons++;
		}
		while (kv.GotoNextKey());
	}

	delete kv;
	LogMessage("Weapons Loaded: %i", g_TotalCustomWeapons);
}

void SpawnWeapons()
{
	int entity = -1; int unlock;
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		if (!HasName(entity, "onWeaponSpawn"))
			continue;
		
		unlock = GetWaveUnlockInt(entity);
		
		char sWeapon[64];
		GetCustomKeyValue(entity, "udm_weapon", sWeapon, sizeof(sWeapon));

		char sParticle[64];
		GetCustomKeyValue(entity, "udm_particleupgrade", sParticle, sizeof(sParticle));

		char sCost[64];
		GetCustomKeyValue(entity, "udm_cost", sCost, sizeof(sCost));

		char sAmmoCost[64];
		GetCustomKeyValue(entity, "udm_ammocost", sAmmoCost, sizeof(sAmmoCost));

		char sAmmoUpgrade[64];
		GetCustomKeyValue(entity, "udm_ammoupgrade", sAmmoUpgrade, sizeof(sAmmoUpgrade));

		float origin[3];
		GetEntityOrigin(entity, origin);

		float angles[3];
		GetEntityAngles(entity, angles);

		int index = GetCustomWeaponIndex(sWeapon);

		if (index == -1)
			continue;
		
		char sWorldmodel[PLATFORM_MAX_PATH];
		if (!TF2Items_GetItemKeyString(sWeapon, "worldmodel", sWorldmodel, sizeof(sWorldmodel)) || !IsModelPrecached(sWorldmodel))
			continue;

		int weapon = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(weapon, "model", sWorldmodel);
		DispatchKeyValueVector(weapon, "origin", origin);
		DispatchKeyValueVector(weapon, "angles", angles);
		DispatchSpawn(weapon);

		TF2_CreateGlow("weapon_color", weapon, view_as<int>({255, 200, 200, 150}));
		//CreatePointGlow(origin, 360.0);

		g_SpawnedWeapons[weapon].index = index;
		g_SpawnedWeapons[weapon].price = StringToInt(sCost);
		g_SpawnedWeapons[weapon].unlock = unlock;
		g_SpawnedWeapons[weapon].particle = StringToFloat(sParticle);
		g_SpawnedWeapons[weapon].ammocost = StringToInt(sAmmoCost);
		g_SpawnedWeapons[weapon].ammoupgrade = StringToInt(sAmmoUpgrade);
		g_InteractableType[weapon] = INTERACTABLE_TYPE_WEAPON;
	}
}

int GetCustomWeaponIndex(const char[] name)
{
	for (int i = 0; i <= g_TotalCustomWeapons; i++)
		if (StrEqual(name, g_CustomWeapons[i].name, false))
			return i;
	
	return -1;
}

void OnWeaponTick(int entity)
{
	int unlock = g_SpawnedWeapons[entity].unlock;
	int index = g_SpawnedWeapons[entity].index;

	char sClasses[2048];
	TF2Items_GetItemKeyString(g_CustomWeapons[index].name, "classes", sClasses, sizeof(sClasses));
	sClasses[0] = CharToUpper(sClasses[0]);

	//float origin[3];
	//GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	//CreatePointGlow(origin);

	char sRepurchase[16];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;
		
		sRepurchase[0] = '\0';

		if (IsVisibleTo(i, entity, 45.0, true))
		{
			if (unlock <= g_Match.round + 1)
			{
				int price = g_SpawnedWeapons[entity].price;
				int slot = TF2Items_GetItemKeyInt(g_CustomWeapons[index].name, "slot");

				int weapon = GetPlayerWeaponSlot(i, slot);
				if (IsValidEntity(weapon) && g_WeaponIndex[weapon] == index)
				{
					strcopy(sRepurchase, sizeof(sRepurchase), "ammo for ");
					price /= 2;
				}

				g_Player[i].nearinteractable = entity;

				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "Press 'MEDIC!' to purchase %s%s for %i points. (%s Only)", sRepurchase, g_CustomWeapons[index].name, price, sClasses);
			}
			else
			{
				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "[%s locked until round %i]", g_CustomWeapons[index].name, unlock);
			}
		}
		else if (g_Player[i].nearinteractable == entity)
		{
			g_Player[i].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(i);
		}
	}
}

void DestroyWeapons()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if (g_SpawnedWeapons[entity].index != -1)
			AcceptEntityInput(entity, "Kill");
		
		g_SpawnedWeapons[entity].Reset();
	}	
}

void GiveWallWeapon(int client, int index, int slot)
{
	int current = GetPlayerWeaponSlot(client, slot);

	if (IsValidEntity(current) && g_WeaponIndex[current] == index)
	{
		TF2Items_RefillMag(current);
		TF2Items_RefillAmmo(client, current);
		return;
	}

	GiveCustomWeapon(client, index);
}

int GiveCustomWeapon(int client, int index)
{
	int weapon = -1;
	if ((weapon = TF2Items_GiveItem(client, g_CustomWeapons[index].name)) != -1)
	{
		g_WeaponIndex[weapon] = index;
		InspectWeapon(client);
	}
}

void InspectWeapon(int client)
{
	KeyValues kv = new KeyValues("inspect_weapon");
	kv.SetSectionName("+inspect_server");
	FakeClientCommandKeyValues(client, kv);
}

/****************************************/
//Powerups
/****************************************/

void ParsePowerups()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/undead/powerups.cfg");

	KeyValues kv = new KeyValues("powerups");

	if (kv.ImportFromFile(sPath) && kv.GotoFirstSubKey())
	{
		g_TotalPowerups = 0;

		do
		{
			kv.GetSectionName(g_Powerups[g_TotalPowerups].name, 64);
			kv.GetString("description", g_Powerups[g_TotalPowerups].description, 128);
			kv.GetString("model", g_Powerups[g_TotalPowerups].model, PLATFORM_MAX_PATH);
			kv.GetString("sound", g_Powerups[g_TotalPowerups].sound, PLATFORM_MAX_PATH);
			g_Powerups[g_TotalPowerups].timer = kv.GetFloat("timer");
			g_TotalPowerups++;
		}
		while (kv.GotoNextKey());
	}

	delete kv;
	LogMessage("Powerups Loaded: %i", g_TotalPowerups);
}

public Action Command_SpawnPowerup(int client, int args)
{
	if (args == 0)
	{
		OpenPowerupsMenu(client);
		return Plugin_Handled;
	}

	int index = GetCmdArgInt(1);

	float origin[3];
	GetClientLookOrigin(client, origin);

	CPrintToChat(client, "Spawning Powerup {haunted}%i{default}: {haunted}%s", index, g_Powerups[index].name);
	SpawnPowerup(origin, index);

	return Plugin_Handled;
}

void OpenPowerupsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SpawnPowerups);
	menu.SetTitle("Pick a Powerup:");

	char sIndex[16];
	for (int i = 0; i < g_TotalPowerups; i++)
	{
		IntToString(i, sIndex, sizeof(sIndex));
		menu.AddItem(sIndex, g_Powerups[i].name);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_SpawnPowerups(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sIndex[16];
			menu.GetItem(param2, sIndex, sizeof(sIndex));
			int index = StringToInt(sIndex);
			
			float origin[3];
			GetClientLookOrigin(param1, origin);
			
			CPrintToChat(param1, "Spawning Powerup {haunted}%i{default}: {haunted}%s", index, g_Powerups[index].name);
			SpawnPowerup(origin, index);

			OpenPowerupsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

void SpawnPowerup(float origin[3], int index = -1, bool cooldown = false)
{
	if (index == -1)
		index = GetRandomInt(0, g_TotalPowerups - 1);
	
	if (cooldown)
	{
		int time = GetTime();

		if (g_Match.powerups_cooldown != -1 && g_Match.powerups_cooldown > time)
			return;
		
		g_Match.powerups_cooldown = time + POWERUP_COOLDOWN;
	}

	int entity = CreateEntityByName("tf_halloween_pickup");

	if (!IsValidEntity(entity))
		return;
	
	DispatchKeyValueVector(entity, "origin", origin);
	DispatchKeyValueVector(entity, "basevelocity", view_as<float>({0.0, 0.0, 200.0}));
	DispatchKeyValueVector(entity, "velocity", view_as<float>({0.0, 0.0, 200.0}));
	//DispatchKeyValue(entity, "pickup_particle", g_Powerups[index].particle);
	//DispatchKeyValue(entity, "pickup_sound", g_Powerups[index].sound);
	DispatchKeyValue(entity, "powerup_model", g_Powerups[index].model);
	DispatchSpawn(entity);

	EmitSoundToAll("undead/powerups/powerup_spawn.wav", entity);

	SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
	SetEntProp(entity, Prop_Data, "m_iEFlags", 35913728);
	SetEntProp(entity, Prop_Data, "m_MoveCollide", 1);

	char sBuffer[128];
	FormatEx(sBuffer, sizeof(sBuffer), "OnUser1 !self:kill::30:1");

	SetVariantString(sBuffer);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	g_PowerupIndex[entity] = index;
	SDKHook(entity, SDKHook_Touch, OnPowerupTouch);

	TriggerTimer(CreateTimer(1.0, Timer_Sound, EntIndexToEntRef(entity), TIMER_REPEAT), true);
}

public Action Timer_Sound(Handle timer, any data)
{
	int entity = EntRefToEntIndex(data);
	
	if (IsValidEntity(entity))
	{
		float position[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		EmitSoundToAll("undead/powerups/powerup_loop.wav", entity, SNDCHAN_USER_BASE + 14, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, entity, position);
		return Plugin_Continue;
	}

	return Plugin_Stop;
}

public Action OnPowerupTouch(int entity, int other)
{
	return OnPowerupPickup(other, entity) ? Plugin_Continue : Plugin_Stop;
}

bool OnPowerupPickup(int client, int entity)
{
	if (!IsPlayerIndex(client) || GetClientTeam(client) != TEAM_SURVIVORS || !IsValidEntity(entity))
		return false;
	
	StopSound(entity, SNDCHAN_USER_BASE + 14, "undead/powerups/powerup_loop.wav");

	int index = g_PowerupIndex[entity];
	g_PowerupIndex[entity] = -1;
	AcceptEntityInput(entity, "Kill");

	switch (index)
	{
		//double points
		case 0:
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVORS)
					g_Player[i].doublepoints = GetTime() + RoundFloat(g_Powerups[index].timer);
		}
		//insta kill
		case 1:
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVORS)
					g_Player[i].instakill = GetTime() + RoundFloat(g_Powerups[index].timer);
		}
		//nuke
		case 2:
		{
			KillAllZombies();
			ScreenFadeAll2();
		}
		//max ammo
		case 3:
		{
			int weapon;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
					continue;
				
				for (int x = 0; x < 2; x++)
				{
					if ((weapon = GetPlayerWeaponSlot(i, x)) == -1)
						continue;
					
					TF2Items_RefillMag(weapon);
					TF2Items_RefillAmmo(i, weapon);
				}
			}
		}
	}
	
	EmitSoundToClient(client, "undead/powerups/powerup_grab.wav");
	EmitSoundToClient(client, g_Powerups[index].sound);

	if (IsPlayerIndex(client))
		g_Player[client].AddStat(STAT_POWERUP, 1);
	
	return true;
}

void ScreenFadeAll2(int duration = 100, int hold_time = 100, int flag = FFADE_IN, int colors[4] = {235, 235, 235, 150}, bool reliable = true)
{
	bool pb = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	Handle userMessage;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		userMessage = StartMessageOne("Fade", i, (reliable ? USERMSG_RELIABLE : 0));

		if (userMessage == null)
			continue;

		if (pb)
		{
			PbSetInt(userMessage, "duration", duration);
			PbSetInt(userMessage, "hold_time", hold_time);
			PbSetInt(userMessage, "flags", flag);
			PbSetColor(userMessage, "clr", colors);
		}
		else
		{
			BfWriteShort(userMessage, duration);
			BfWriteShort(userMessage, hold_time);
			BfWriteShort(userMessage, flag);
			BfWriteByte(userMessage, colors[0]);
			BfWriteByte(userMessage, colors[1]);
			BfWriteByte(userMessage, colors[2]);
			BfWriteByte(userMessage, colors[3]);
		}
		
		EndMessage();
		userMessage = null;
	}
}

void DestroyPowerups()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_halloween_pickup")) != -1)
		AcceptEntityInput(entity, "Kill");
}

/****************************************/
//Mystery Box
/****************************************/

void SpawnMysteryBoxes()
{
	int entity = -1; int unlock;
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		if (!HasName(entity, "onMysteryBoxSpawn"))
			continue;
		
		unlock = GetWaveUnlockInt(entity);

		float origin[3];
		GetEntityOrigin(entity, origin);
		origin[2] -= 8.0;

		float angles[3];
		GetEntityAngles(entity, angles);
		angles[1] = 270.0;

		int mysterybox = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(mysterybox, "model", "models/noobis/mystery_box/mystery_box.mdl");
		DispatchKeyValueVector(mysterybox, "origin", origin);
		DispatchKeyValueVector(mysterybox, "angles", angles);
		DispatchSpawn(mysterybox);
		
		g_MysteryBox[mysterybox].status = true;
		g_MysteryBox[mysterybox].price = 1000;
		g_MysteryBox[mysterybox].inuse = false;
		g_MysteryBox[mysterybox].glow = TF2_CreateGlow("mysterybox_color", mysterybox, view_as<int>({255, 200, 255, 150}));
		g_MysteryBox[mysterybox].unlock = unlock;
		g_InteractableType[mysterybox] = INTERACTABLE_TYPE_MYSTERYBOX;
	}
}

void OnMysteryBoxTick(int entity)
{
	int unlock = g_MysteryBox[entity].unlock;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;
		
		if (IsVisibleTo(i, entity, 120.0, false))
		{
			if (unlock <= g_Match.round + 1)
			{
				g_Player[i].nearinteractable = entity;

				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "Press 'MEDIC!' to open this mystery box for %i points!", g_MysteryBox[entity].price);
			}
			else
			{
				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "[Mystery Box locked until round %i]", unlock);
			}
		}
		else if (g_Player[i].nearinteractable == entity)
		{
			g_Player[i].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(i);
		}
	}
}

void DestroyMysteryBoxes()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if (g_MysteryBox[entity].status)
			AcceptEntityInput(entity, "Kill");
		
		g_MysteryBox[entity].Reset();
	}	
}

void OpenMysteryBox(int client, int mysterybox)
{
	int index = GetRandomMysteryWeapon(client);

	if (index == -1)
		return;

	g_MysteryBox[mysterybox].inuse = true;
	AcceptEntityInput(g_MysteryBox[mysterybox].glow, "Disable");

	AnimateEntity(mysterybox, "opening");
	EmitSoundToAll("undead/mystery_box.wav", mysterybox);

	float origin[3];
	GetEntityOrigin(mysterybox, origin);

	int display = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValueVector(display, "origin", origin);
	DispatchKeyValueVector(display, "angles", g_CustomWeapons[index].offset_angles);

	char sModel[PLATFORM_MAX_PATH];
	TF2Items_GetItemKeyString(g_CustomWeapons[index].name, "worldmodel", sModel, sizeof(sModel));
	//PrintToDrixevel("%s - %s", g_CustomWeapons[index].name, sModel);

	DispatchKeyValue(display, "model", sModel);

	DispatchSpawn(display);
	SetEntitySelfDestruct(display, 15.0);
	TF2_CreateGlow("display_color", display, {255, 255, 255, 200});
	
	DataPack pack;
	CreateDataTimer(0.1, Timer_MysteryBox, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(EntIndexToEntRef(mysterybox));
	pack.WriteCell(EntIndexToEntRef(display));
	pack.WriteCell(index);
	pack.WriteCell(0); //phase
	pack.WriteFloat(0.0); //tick
}

public Action Timer_MysteryBox(Handle timer, DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());
	int mysterybox = EntRefToEntIndex(pack.ReadCell());
	int display = EntRefToEntIndex(pack.ReadCell());
	int index = pack.ReadCell();
	int phase = pack.ReadCell();
	float ticks = pack.ReadFloat();

	ticks += 0.1;

	if (!IsPlayerIndex(client) || !IsValidEntity(mysterybox) || !IsValidEntity(display))
	{
		CloseMysteryBox(display, mysterybox);
		return Plugin_Stop;
	}

	float origin[3];
	GetEntityOrigin(display, origin);

	if (ticks >= 15.0)
	{
		CloseMysteryBox(display, mysterybox);
		return Plugin_Stop;
	}
	else if (ticks >= 5.0)
	{
		if (phase != 1)
			TF2_CreateAnnotationToAll(origin, "Weapon is ready...", 10.0, "vo/null.wav");
		
		phase = 1;
	}
	
	if (phase == 0)
	{
		index = GetRandomMysteryWeapon(client);

		origin[2] += 0.8;
		DispatchKeyValueVector(display, "origin", origin);
		DispatchKeyValueVector(display, "angles", g_CustomWeapons[index].offset_angles);
		
		char sModel[PLATFORM_MAX_PATH];
		TF2Items_GetItemKeyString(g_CustomWeapons[index].name, "worldmodel", sModel, sizeof(sModel));
		//PrintToDrixevel("%s - %s", g_CustomWeapons[index].name, sModel);

		SetEntityModel(display, sModel);
	}
	else if (phase == 1)
	{
		origin[2] -= 0.2;
		DispatchKeyValueVector(display, "origin", origin);

		float time = GetGameTime();
		if (g_Player[client].delayhint == -1.0 || g_Player[client].delayhint != -1.0 && g_Player[client].delayhint <= time)
		{
			PrintSilentHint(client, "Press 'MEDIC!' near the mystery box to pick up the weapon.");
			g_Player[client].delayhint = time + 1.0;
		}

		float playerorigin[3];
		GetClientAbsOrigin(client, playerorigin);

		float boxorigin[3];
		GetEntPropVector(mysterybox, Prop_Send, "m_vecOrigin", boxorigin);

		if (g_Player[client].interact != -1 && g_Player[client].interact > GetTime() && GetVectorDistance(playerorigin, boxorigin) <= 120.0)
		{
			SpeakResponseConcept(client, "TLK_PLAYER_CHEERS");
			GiveCustomWeapon(client, index);
			CloseMysteryBox(display, mysterybox);
		}
	}

	pack.Reset();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(EntIndexToEntRef(mysterybox));
	pack.WriteCell(EntIndexToEntRef(display));
	pack.WriteCell(index);
	pack.WriteCell(phase);
	pack.WriteFloat(ticks);

	return Plugin_Continue;
}

void CloseMysteryBox(int display, int mysterybox)
{
	if (IsValidEntity(display))
		AcceptEntityInput(display, "Kill");
		
	if (IsValidEntity(mysterybox))
	{
		AnimateEntity(mysterybox, "closing");
		AcceptEntityInput(g_MysteryBox[mysterybox].glow, "Enable");
		g_MysteryBox[mysterybox].inuse = false;
	}
}

int GetRandomMysteryWeapon(int client)
{
	char sClass[32];
	TF2_GetClientClassName(client, sClass, sizeof(sClass));

	int[] indexes = new int[g_TotalCustomWeapons];
	int total;

	char sClasses[2048];
	for (int i = 0; i <= g_TotalCustomWeapons; i++)
	{
		if (g_CustomWeapons[i].mystery_box)
		{
			TF2Items_GetItemKeyString(g_CustomWeapons[i].name, "classes", sClasses, sizeof(sClasses));

			if (StrContains(sClasses, sClass, false) != -1)
				indexes[total++] = i;
		}
	}
	
	return (total == 0) ? -1 : indexes[GetRandomInt(0, total - 1)];
}

/****************************************/
//Planks
/****************************************/

void ResetPlank(int entity)
{
	DispatchKeyValue(entity, "solid", "0");
	SetEntProp(entity, Prop_Data, "m_iHealth", PLANK_HEALTH);
	SetEntProp(entity, Prop_Data, "m_iDisabled", 0);

	float fOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);
	TE_Particle("rps_win_sparks", fOrigin);

	AcceptEntityInput(entity, "Enable");
	g_RebuildDelay[entity] = -1.0;

	RecomputeNavs();
	g_InteractableType[entity] = INTERACTABLE_TYPE_PLANK;
}

void SpawnPlanks()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_brush")) != -1)
		if (HasName(entity, "plank_"))
			ResetPlank(entity);
}

void OnPlankTick(int entity)
{
	int health = GetEntProp(entity, Prop_Data, "m_iHealth");
	bool disabled = GetEntProp(entity, Prop_Data, "m_iDisabled") == 1;

	float fOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);

	OnPlankSurvivorTick(entity, disabled);

	if (g_Match.pausezombies)
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ZOMBIES || !IsVisibleTo(i, entity, 125.0, false))
			continue;
				
		if (health <= 0 && disabled)
		{
			g_Player[i].plank_damage_tick = -1.0;
			TF2_RemoveCondition(i, TFCond_FreezeInput);
			continue;
		}

		float time = GetGameTime();
		if (g_Player[i].plank_damage_tick == -1.0 || g_Player[i].plank_damage_tick != -1.0 && g_Player[i].plank_damage_tick <= time)
		{
			DamagePlank(entity, CalculateDamage());
			g_Player[i].plank_damage_tick = time + GetRandomFloat(ZOMBIE_ATTACK_SPEED_MIN, ZOMBIE_ATTACK_SPEED_MAX) * 2.0;
		}
		
		TF2_AddCondition(i, TFCond_FreezeInput);
	}
	
	int zombie = -1;
	while ((zombie = FindEntityByClassname(zombie, "base_boss")) != -1)
	{
		if (!IsEntVisibleTo(zombie, entity, 100.0))
			continue;

		CBaseNPC npc = TheNPCs.FindNPCByEntIndex(zombie);

		if (health <= 0 && disabled || g_Zombies[npc.Index].insidemap)
		{
			g_Zombies[npc.Index].plank_damage_tick = -1.0;
			npc.flRunSpeed = g_Zombies[npc.Index].speed;
			continue;
		}

		float time = GetGameTime();
		if (g_Zombies[npc.Index].plank_damage_tick == -1.0 || g_Zombies[npc.Index].plank_damage_tick != -1.0 && g_Zombies[npc.Index].plank_damage_tick <= time)
		{
			CBaseAnimatingOverlay animationEntity = CBaseAnimatingOverlay(zombie);
			int iSequence = animationEntity.LookupSequence("throw_fire");
			animationEntity.AddGestureSequence(iSequence);

			NextBotGroundLocomotion loco = npc.GetLocomotion();
			loco.FaceTowards(fOrigin);

			DamagePlank(entity, CalculateDamage());
			g_Zombies[npc.Index].plank_damage_tick = time + GetRandomFloat(ZOMBIE_ATTACK_SPEED_MIN, ZOMBIE_ATTACK_SPEED_MAX) * 2.0;
		}

		npc.flRunSpeed = 0.0;
	}
}

bool DamagePlank(int entity, float damage = 15.0)
{
	float health = float(GetEntProp(entity, Prop_Data, "m_iHealth"));

	if (health < 0.0)
		return false;
	
	if (health < damage)
		damage -= health;
	
	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	EmitGameSoundToAll("Breakable.Crate", entity);
	TE_Particle("mvm_loot_smoke", origin);
	SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health - damage));

	if (GetEntProp(entity, Prop_Data, "m_iHealth") < 1)
	{
		AcceptEntityInput(entity, "Disable");
		RecomputeNavs();
		g_RebuildDelay[entity] = GetGameTime() + PLANK_COOLDOWN;
		SetEntProp(entity, Prop_Data, "m_iHealth", 0);

		return false;
	}

	return true;
}

void OnPlankSurvivorTick(int entity, bool disabled)
{
	char sCooldown[32]; float diff;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;
		
		if (disabled && IsVisibleTo(i, entity, 100.0, true))
		{
			g_Player[i].nearinteractable = entity;

			diff = (g_RebuildDelay[entity] - GetGameTime());

			if (diff > 0.0)
				FormatEx(sCooldown, sizeof(sCooldown), " (Cooldown: %.2f)", diff);

			g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
			g_Sync_NearInteractable.Send(i, "Press 'MEDIC!' to rebuild this plank for points.%s", sCooldown);
		}
		else if (g_Player[i].nearinteractable == entity)
		{
			g_Player[i].nearinteractable = - 1;
			g_Sync_NearInteractable.Clear(i);
		}
	}
}

/****************************************/
//Buildings
/****************************************/

void SetupBuildings()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != -1)
	{
		g_RechargeBuilding[entity] = -1;
		g_DisableBuilding[entity] = -1;
		SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
		g_InteractableType[entity] = INTERACTABLE_TYPE_BUILDING;
	}
}

void OnBuildingTick(int entity)
{
	char sBuilding[64];
	switch (TF2_GetObjectType(entity))
	{
		case TFObject_Dispenser:
			strcopy(sBuilding, sizeof(sBuilding), "Dispenser");
		case TFObject_Teleporter:
		{
			switch (TF2_GetObjectMode(entity))
			{
				case TFObjectMode_Entrance:
					strcopy(sBuilding, sizeof(sBuilding), "Teleporter Entrance");
				case TFObjectMode_Exit:
					strcopy(sBuilding, sizeof(sBuilding), "Teleporter Exit");
			}
		}
		case TFObject_Sentry:
			strcopy(sBuilding, sizeof(sBuilding), "Sentry");
		case TFObject_Sapper:
			strcopy(sBuilding, sizeof(sBuilding), "Sapper");
	}
	
	char sCost[64];
	GetCustomKeyValue(entity, "udm_cost", sCost, sizeof(sCost));
	
	char sRecharge[64];
	GetCustomKeyValue(entity, "udm_recharge", sRecharge, sizeof(sRecharge));

	int unlock = GetWaveUnlockInt(entity);

	if (g_DisableBuilding[entity] != -1 && g_DisableBuilding[entity] <= GetTime())
	{
		SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
		g_RechargeBuilding[entity] = GetTime() + StringToInt(sRecharge);
		g_DisableBuilding[entity] = -1;
	}

	float fOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;
		
		if (IsVisibleTo(i, entity, 120.0, false))
		{
			if (unlock <= g_Match.round + 1)
			{
				g_Player[i].nearinteractable = entity;

				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "Press 'MEDIC!' to enable this %s for %i points!", sBuilding, StringToInt(sCost));
			}
			else
			{
				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "[%s locked until round %i]", sBuilding, unlock);
			}
		}
		else if (g_Player[i].nearinteractable == entity)
		{
			g_Player[i].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(i);
		}
	}
}

/****************************************/
//Doors
/****************************************/

void SetupDoors()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_door")) != -1)
		if (HasName(entity, "unlock_door_"))
			g_InteractableType[entity] = INTERACTABLE_TYPE_DOORS;
	
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_door*")) != -1)
		if (HasName(entity, "unlock_door_"))
			g_InteractableType[entity] = INTERACTABLE_TYPE_DOORS;
}

void OnDoorTick(int entity)
{
	if (HasEntProp(entity, Prop_Data, "m_eDoorState") && GetEntProp(entity, Prop_Data, "m_eDoorState") != 2)
		return;

	if (HasEntProp(entity, Prop_Data, "m_toggle_state") && GetEntProp(entity, Prop_Data, "m_toggle_state") != 1)
		return;

	char sCost[64];
	GetCustomKeyValue(entity, "udm_cost", sCost, sizeof(sCost));

	int unlock = GetWaveUnlockInt(entity);

	float fOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;
		
		if (IsVisibleTo(i, entity, 120.0, false))
		{
			if (unlock <= g_Match.round + 1)
			{
				g_Player[i].nearinteractable = entity;

				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "Press 'MEDIC!' to open this door for %i points!", StringToInt(sCost));
			}
			else
			{
				g_Sync_NearInteractable.SetParams(-1.0, 0.2, 2.0, 255, 255, 255, 255);
				g_Sync_NearInteractable.Send(i, "[Door locked until round %i]", unlock);
			}
		}
		else if (g_Player[i].nearinteractable == entity)
		{
			g_Player[i].nearinteractable = -1;
			g_Sync_NearInteractable.Clear(i);
		}
	}
}

/****************************************/
//Misc
/****************************************/

void KillAllZombies()
{
	int entity = -1; CBaseNPC npc;
	while ((entity = FindEntityByClassname(entity, "base_boss")) != -1)
		if ((npc = TheNPCs.FindNPCByEntIndex(entity)) != INVALID_NPC && g_Zombies[npc.Index].type == GetZombieTypeByName(ZOMBIE_DEFAULT))
			OnZombieDeath(entity);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ZOMBIES)
			continue;

		g_Player[i].insidemap = false;
		ForcePlayerSuicide(i);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerIndex(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	float fCoordinates[3];
	GetClientAbsOrigin(client, fCoordinates);

	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "entity_revive_marker")) != -1)
	{
		float fOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);

		if (GetVectorDistance(fCoordinates, fOrigin) <= 75.0)
		{
			int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");

			if (GetClientTeam(client) != GetClientTeam(iOwner))
				continue;
			
			int iHealth = GetEntProp(entity, Prop_Send, "m_iHealth");
			int iMaxHealth = RoundFloat(float(175) * g_Difficulty[g_Match.difficulty].revive_multiplier);
			
			float time = GetGameTime();
			if (g_Player[client].delayhint == -1.0 || g_Player[client].delayhint != -1.0 && g_Player[client].delayhint <= time)
			{
				PrintHintText(client, "Reviving %N...", iOwner);
				g_Player[client].delayhint = time + 0.2;
			}

			SetEntProp(entity, Prop_Send, "m_iHealth", iHealth + 1);
			iHealth += g_Player[client].HasPerk("quickrevive") ? 2 : 1;

			if (iHealth >= iMaxHealth && IsClientInGame(iOwner))
			{
				if (client == iOwner)
					continue;

				float vecMarkerPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecMarkerPos);

				EmitGameSoundToAll("MVM.PlayerRevived", entity);

				float flMins[3], flMaxs[3];
				GetEntPropVector(iOwner, Prop_Send, "m_vecMaxs", flMaxs);
				GetEntPropVector(iOwner, Prop_Send, "m_vecMins", flMins);

				Handle TraceRay = TR_TraceHullFilterEx(vecMarkerPos, vecMarkerPos, flMins, flMaxs, MASK_PLAYERSOLID, TraceFilterNotSelf, entity);
					
				if (TR_DidHit(TraceRay))
				{
					float vecReviverPos[3];
					GetClientAbsOrigin(client, vecReviverPos);

					TF2_RespawnPlayer(iOwner);
					SpeakResponseConcept(iOwner, "TLK_RESURRECTED");

					TeleportEntity(iOwner, vecReviverPos, NULL_VECTOR, NULL_VECTOR);
					StripPlayer(iOwner);
				}
				else
				{
					TF2_RespawnPlayer(iOwner);
					SpeakResponseConcept(iOwner, "TLK_RESURRECTED");

					TeleportEntity(iOwner, vecMarkerPos, NULL_VECTOR, NULL_VECTOR);
					StripPlayer(iOwner);
				}
				
				delete TraceRay;

				TFClassType class = view_as<TFClassType>(GetEntProp(entity, Prop_Send, "m_nBody") + 1);
				TF2_SetPlayerClass(iOwner, class, true, true);
				TF2_RegeneratePlayer(iOwner);

				g_Player[iOwner].revivemarker = INVALID_ENT_REFERENCE;

				PrintHintText(client, "%N has been respawned!", iOwner);

				if (IsPlayerIndex(client))
					g_Player[client].AddStat(STAT_REVIVES, 1);
				
				if (IsPlayerIndex(iOwner))
					g_Player[iOwner].AddStat(STAT_REVIVED, 1);
			}
		}
	}

	return Plugin_Continue;
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
	return (entity == 0 && entityhit != entity);
}

public Action Command_AddPoints(int client, int args)
{
	int target = GetCmdArgTarget(client, 1, true, false);

	if (target == -1)
	{
		CPrintToChat(client, "Target not found, please try again.");
		return Plugin_Handled;
	}

	int value = GetCmdArgInt(2);

	g_Player[target].AddPoints(value);

	if (client == target)
		CPrintToChat(client, "You have given yourself %i points.", value);
	else
	{
		CPrintToChat(target, "%N has given you %i points.", client, value);
		CPrintToChat(client, "You have given %N %i points.", target, value);
	}

	return Plugin_Handled;
}

public Action Command_SetPoints(int client, int args)
{
	int target = GetCmdArgTarget(client, 1, true, false);

	if (target == -1)
	{
		CPrintToChat(client, "Target not found, please try again.");
		return Plugin_Handled;
	}

	int value = GetCmdArgInt(2);

	g_Player[target].SetPoints(value);

	if (client == target)
		CPrintToChat(client, "You have set your points to %i.", value);
	else
	{
		CPrintToChat(target, "%N has set you points to %i.", client, value);
		CPrintToChat(client, "You have set %N's points to %i.", target, value);
	}

	return Plugin_Handled;
}

void StripPlayer(int client, bool invisible_melee = false)
{
	int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if (IsValidEntity(melee) && GetWeaponIndex(melee) == 142)
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		melee = TF2_GiveItem(client, "tf_weapon_wrench", 7);
	}

	if (GetClientTeam(client) == TEAM_ZOMBIES)
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		TFClassType class = TF2_GetPlayerClass(client);

		char sEntity[32];
		TF2_GetDefaultWeaponClass(class, TFWeaponSlot_Melee, sEntity, sizeof(sEntity));

		int index = TF2_GetDefaultWeaponID(class, TFWeaponSlot_Melee);
		melee = TF2_GiveItem(client, sEntity, index);
	}

	if (invisible_melee && IsValidEntity(melee))
	{
		SetEntityRenderMode(melee, RENDER_TRANSCOLOR); 
		SetEntityRenderColor(melee, _, _, _, 0);
	}

	EquipWeaponSlot(client, TFWeaponSlot_Melee);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
	SetEntityHealth(client, CalculateHealth(client));
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	result = false;
	return Plugin_Changed;
}

public Action Command_SyncLobby(int client, int args)
{
	TelePlayersToMap();
	CPrintToChatAll("%N has teleported players from the lobby to the game.", client);
	return Plugin_Handled;
}

public void TF2_OnRegeneratePlayerPost(int client)
{
	StripPlayer(client);
}

bool IsVisibleTo(int client, int target, float maxdistance = 0.0, bool FromEyePosition = true, float z_axis = 0.0, float tolerance = 75.0)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(target))
		return false;
	 
	float vOrigin[3];
	FromEyePosition ? GetClientEyePosition(client, vOrigin) : GetClientAbsOrigin(client, vOrigin);
	
	float vEnt[3];
	if (HasEntProp(target, Prop_Send, "m_vecAbsOrigin"))
		GetEntPropVector(target, Prop_Send, "m_vecAbsOrigin", vEnt);
	else
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vEnt);
	
	vEnt[2] += z_axis;

	//CreatePointGlow(vEnt);
	
	if (maxdistance > 0.0 && GetVectorDistance(vOrigin, vEnt) > maxdistance)
		return false;
	
	float vLookAt[3];
	MakeVectorFromPoints(vOrigin, vEnt, vLookAt);
	
	float vAngles[3];
	GetVectorAngles(vLookAt, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter, target);
	
	bool isVisible;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace);
		
		if ((GetVectorDistance(vOrigin, vStart, false) + tolerance) >= GetVectorDistance(vOrigin, vEnt))
			isVisible = true;
	}
	else
		isVisible = true;
	
	delete trace;
	return isVisible;
}

bool IsEntVisibleTo(int entity, int target, float maxdistance = 0.0, float z_axis = 0.0, float tolerance = 75.0)
{
	if (entity <= MaxClients || !IsValidEntity(entity) || !IsValidEntity(target))
		return false;

	// CBaseNPC npc;
	// if ((npc = TheNPCs.FindNPCByEntIndex(entity)) == INVALID_NPC)
	// 	return true;

	CBaseAnimating anim = CBaseAnimating(entity);

	float vOrigin[3];
	anim.WorldSpaceCenter(vOrigin);
	
	float vEnt[3];
	if (HasEntProp(target, Prop_Send, "m_vecAbsOrigin"))
		GetEntPropVector(target, Prop_Send, "m_vecAbsOrigin", vEnt);
	else
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vEnt);
	
	vOrigin[2] += 50.0;
	vEnt[2] += z_axis;
	
	if (maxdistance > 0.0 && GetVectorDistance(vOrigin, vEnt) > maxdistance)
		return false;
	
	float vLookAt[3];
	MakeVectorFromPoints(vOrigin, vEnt, vLookAt);
	
	float vAngles[3];
	GetVectorAngles(vLookAt, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter2, target);
	
	bool isVisible;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace);
		
		if ((GetVectorDistance(vOrigin, vStart, false) + tolerance) >= GetVectorDistance(vOrigin, vEnt))
			isVisible = true;
	}
	else
		isVisible = true;
	
	/*if (isVisible)
	{
		CreatePointGlow(vOrigin);
		CreatePointGlow(vEnt);
	}*/
	
	delete trace;
	return isVisible;
}

public bool TraceFilter(int entity, int contentsMask, any data)
{
	if (entity == 0)
		return true;
	
	if (entity <= MaxClients || !IsValidEntity(entity) || entity == data)
		return false;
	
	return true;
}

public bool TraceFilter2(int entity, int contentsMask, any data)
{
	if (entity == 0)
		return true;
	
	if (entity <= MaxClients || !IsValidEntity(entity) || entity == data)
		return false;
	
	return true;
}

void RecomputeNavs()
{
	int entity = CreateEntityByName("tf_point_nav_interface");

	if (!IsValidEntity(entity))
		return;
	
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "RecomputeBlockers");
	AcceptEntityInput(entity, "Kill");
}

public Action Command_MainMenu(int client, int args)
{
	OpenMainMenu(client);
	return Plugin_Handled;
}

void OpenMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Main);
	menu.SetTitle("[Gamemode] Undead Zombies");

	menu.AddItem("statistics", "Your Undead Statistics");
	menu.AddItem("weapons", "View Custom Weapons Info");
	menu.AddItem("info", "What is this gamemode?");
	menu.AddItem("type", "What are the types of zombies?");
	menu.AddItem("machines", "What do the Machines do?");
	menu.AddItem("powerups", "What do the Powerups do?");
	menu.AddItem("mystery_box", "What does the Mystery Box do?");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			if (StrEqual(sInfo, "statistics", false))
				OpenStatisticsMenu(param1, true);
			else if (StrEqual(sInfo, "weapons", false))
				OpenWeaponsMenu(param1);
			else if (StrEqual(sInfo, "info", false))
				OpenInfoPanel(param1);
			else if (StrEqual(sInfo, "type", false))
				OpenTypesPanel(param1);
			else if (StrEqual(sInfo, "machines", false))
				OpenMachinesPanel(param1);
			else if (StrEqual(sInfo, "powerups", false))
				OpenPowerupsPanel(param1);
			else if (StrEqual(sInfo, "mystery_box", false))
				OpenMysteryBoxPanel(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

void OpenWeaponsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Weapons);
	menu.SetTitle("Pick a weapon:");

	char sID[16];
	for (int i = 0; i < g_TotalCustomWeapons; i++)
	{
		IntToString(i, sID, sizeof(sID));
		menu.AddItem(sID, g_CustomWeapons[i].name);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Weapons(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sID[16];
			menu.GetItem(param2, sID, sizeof(sID));
			TF2Items_OpenInfoPanel(param1, g_CustomWeapons[StringToInt(sID)].name, false);
		}
		case MenuAction_End:
			delete menu;
	}
}

void OpenInfoPanel(int client)
{
	Panel panel = new Panel();
	panel.SetTitle("Gamemode Information");

	panel.DrawText("Undead Zombies is a gamemode recreation of the original Call of Cuty Zombies gamemode from World at War.");
	panel.DrawText("Survive an onslaught of zombies ranging from normal common zombies to special infected zombies.");
	panel.DrawText("Purchase weapons, perks and rent buildings to help you survive for as long as possible.");
	panel.DrawText("Powerups drop on the map as well allowing for temporary upgrades.");
	panel.DrawText("Beat your own times, kill the most zombies, open the mystery box for more upgrades and survive!");

	panel.DrawItem("Back");
	panel.DrawItem("Exit");

	panel.Send(client, MenuHandler_Info, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuHandler_Info(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 1)
				OpenMainMenu(param1);
		}
	}
}

void OpenTypesPanel(int client)
{
	Panel panel = new Panel();
	panel.SetTitle("Types of Zombies");

	char sDisplay[128];
	for (int i = 0; i < g_TotalZombieTypes; i++)
	{
		FormatEx(sDisplay, sizeof(sDisplay), "%s\n - %s", g_ZombieTypes[i].name, g_ZombieTypes[i].description);
		panel.DrawText(sDisplay);
	}

	panel.DrawItem("Back");
	panel.DrawItem("Exit");

	panel.Send(client, MenuHandler_Types, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuHandler_Types(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 1)
				OpenMainMenu(param1);
		}
	}
}

void OpenMachinesPanel(int client)
{
	Panel panel = new Panel();
	panel.SetTitle("Types of Machines\nMachines allow for perks to be unlocked through points.");

	char sDisplay[128];
	for (int i = 0; i < g_TotalMachines; i++)
	{
		FormatEx(sDisplay, sizeof(sDisplay), "%s\n - %s", g_MachinesData[i].name, g_MachinesData[i].description);
		panel.DrawText(sDisplay);
	}

	panel.DrawItem("Back");
	panel.DrawItem("Exit");

	panel.Send(client, MenuHandler_Machines, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuHandler_Machines(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 1)
				OpenMainMenu(param1);
		}
	}
}

void OpenPowerupsPanel(int client)
{
	Panel panel = new Panel();
	panel.SetTitle("Types of Powerups\nPowerups give you perks and upgrades throughout the game as drops.");

	char sDisplay[128];
	for (int i = 0; i < g_TotalPowerups; i++)
	{
		FormatEx(sDisplay, sizeof(sDisplay), "%s\n - %s", g_Powerups[i].name, g_Powerups[i].description);
		panel.DrawText(sDisplay);
	}

	panel.DrawItem("Back");
	panel.DrawItem("Exit");

	panel.Send(client, MenuHandler_Powerups, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuHandler_Powerups(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 1)
				OpenMainMenu(param1);
		}
	}
}

void OpenMysteryBoxPanel(int client)
{
	Panel panel = new Panel();
	panel.SetTitle("Mystery Box");

	panel.DrawText("Open the mystery box to gain a random weapon you can pick up by interacting with it again.");
	panel.DrawItem("Back");
	panel.DrawItem("Exit");

	panel.Send(client, MenuHandler_mysterybox, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuHandler_mysterybox(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 1)
				OpenMainMenu(param1);
		}
	}
}

void OnZombieDeath(int entity, bool powerups = false, bool bomb_heads = false, int attacker = -1)
{
	CBaseNPC npc;
	if (entity > MaxClients && (npc = TheNPCs.FindNPCByEntIndex(entity)) == INVALID_NPC)
		return;

	float vecOrigin[3];
	GetEntityOrigin(entity, vecOrigin);

	float vecAngles[3];
	GetEntityAngles(entity, vecAngles);

	if (strlen(g_Zombies[npc.Index].death_sound) > 0)
		EmitSoundToAll(g_Zombies[npc.Index].death_sound, entity);

	if (bomb_heads && g_Match.bomb_heads)
	{
		TE_Particle("pumpkin_explode", vecOrigin, entity);
		DamageRadius(vecOrigin, 150.0, 50.0, entity, 0, DMG_BLAST);
		PushPlayersFromPoint(vecOrigin, 50.0, 150.0, 0, entity);
		EmitGameSoundToAll("Halloween.PumpkinDrop", entity);
	}

	bool noragdoll;

	if (g_Zombies[npc.Index].type == GetZombieTypeByName("Explosive Demo"))
	{
		TE_Particle("hightower_explosion", vecOrigin, entity);
		DamageRadius(vecOrigin, 250.0, 100.0, entity, 0, DMG_BLAST);
		PushPlayersFromPoint(vecOrigin, 150.0, 350.0, 0, entity);
		EmitGameSoundToAll("BaseExplosionEffect.Sound", entity);
		noragdoll = true;
	}
	
	if (powerups && GetRandomFloat(0.0, 100.0) <= POWERUP_CHANCE && (entity <= MaxClients && g_Player[entity].insidemap || entity > MaxClients && g_Zombies[npc.Index].insidemap))
		SpawnPowerup(vecOrigin, -1, true);

	if (entity > MaxClients)
	{
		npc.SetCollisionBounds(view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}));

		if (!noragdoll)
		{
			char sModel[PLATFORM_MAX_PATH];
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			CreateRagdoll(vecOrigin, vecAngles, sModel, npc.nSkin, npc.iTeamNum, sZombieAttachments[g_Zombies[npc].class]);
		}

		AcceptEntityInput(entity, "Kill");

		if (IsPlayerIndex(attacker))
		{
			g_Player[attacker].AddStat(STAT_KILLS, 1);

			if (g_Zombies[npc.Index].type != GetZombieTypeByName(ZOMBIE_DEFAULT))
				g_Player[attacker].AddStat(STAT_SPECIALS, 1);
		}
	}
}

void CreateRagdoll(float origin[3], float angles[3], const char[] model, int skin, int team, const char[] attachment, float lifetime = 5.0)
{
	if (!convar_Ragdolls.BoolValue || g_Match.spawn_robots)
		return;
	
	int ragdoll = CreateEntityByName("prop_ragdoll");

	if (IsValidEntity(ragdoll))
	{
		DispatchKeyValueVector(ragdoll, "origin", origin);
		DispatchKeyValueVector(ragdoll, "angles", angles);
		DispatchKeyValue(ragdoll, "model", model);
		DispatchKeyValue(ragdoll, "spawnflags", "4");

		char sSkin[16];
		IntToString(skin, sSkin, sizeof(sSkin));
		DispatchKeyValue(ragdoll, "skin", sSkin);

		char sTeam[32];
		IntToString(team, sTeam, sizeof(sTeam));
		DispatchKeyValue(ragdoll, "TeamNum", sTeam);

		DispatchSpawn(ragdoll);

		if (strlen(attachment) > 0)
		{
			int attach = CreateEntityByName("prop_dynamic");

			if (IsValidEntity(attach))
			{
				DispatchKeyValue(attach, "model", attachment);
				DispatchKeyValue(attach, "TeamNum", sTeam);
				DispatchKeyValue(attach, "solid", "0");
				DispatchSpawn(attach);

				SetEntProp(attach, Prop_Send, "m_nSkin", skin);
				SetEntProp(attach, Prop_Send, "m_fEffects", EF_BONEMERGE | EF_PARENT_ANIMATES);

				SetVariantString("!activator");
				AcceptEntityInput(attach, "SetParent", ragdoll);

				SetVariantString("head");
				AcceptEntityInput(attach, "SetParentAttachmentMaintainOffset");
			}
		}

		if (lifetime > 0.0)
			CreateTimer(lifetime, Timer_Delete, EntIndexToEntRef(ragdoll));
	}
}

public Action Timer_Delete(Handle timer, any data)
{
	int entity = -1;
	if ((entity = EntRefToEntIndex(data)) != -1)
		AcceptEntityInput(entity, "Kill");
}

public Action Command_Difficulty(int client, int args)
{
	if (g_Match.roundphase != PHASE_STARTING)
	{
		CPrintToChat(client, "You aren't allowed to switch the difficulty during the match.");
		return Plugin_Handled;
	}

	bool isadmin = CheckCommandAccess(client, "", ADMFLAG_GENERIC, true);

	if (!isadmin && GetTeamAliveCount(TEAM_SURVIVORS) > 1)
	{
		CPrintToChat(client, "You are only allowed to use this command if you're an admin or you're the only person on the server.");
		return Plugin_Handled;
	}

	if (args == 0)
	{
		OpenDifficultyMenu(client, isadmin);
		return Plugin_Handled;
	}

	char sDifficulty[64];
	GetCmdArgString(sDifficulty, sizeof(sDifficulty));

	int difficulty = GetDifficultyByName(sDifficulty);

	if (difficulty == -1)
	{
		CPrintToChat(client, "Difficulty {haunted}%s {default}not found.", sDifficulty);
		return Plugin_Handled;
	}

	if (!isadmin && g_Difficulty[difficulty].admin_only)
	{
		CPrintToChat(client, "Difficulty {haunted}%s {default}is for admins only.", sDifficulty);
		return Plugin_Handled;
	}

	UpdateDifficulty(difficulty, client);

	return Plugin_Handled;
}

void OpenDifficultyMenu(int client, bool isadmin = false, bool back = false)
{
	Menu menu = new Menu(MenuHandler_Difficulty);
	menu.SetTitle("Choose a difficulty:");

	char sID[16]; char sDisplay[128];
	for (int i = 0; i < g_TotalDifficulties; i++)
	{
		IntToString(i, sID, sizeof(sID));
		FormatEx(sDisplay, sizeof(sDisplay), "%s%s", g_Difficulty[i].name, (i == g_Match.difficulty) ? " (Current)" : "");
		menu.AddItem(sID, sDisplay, (i == g_Match.difficulty || !isadmin && g_Difficulty[i].admin_only) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	PushMenuBool(menu, "isadmin", isadmin);

	menu.ExitBackButton = back;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Difficulty(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsDrixevel(param1) && g_Match.roundphase != PHASE_STARTING)
			{
				CPrintToChat(param1, "You aren't allowed to switch the difficulty during the match.");
				return;
			}

			char sDifficulty[16];
			menu.GetItem(param2, sDifficulty, sizeof(sDifficulty));
			UpdateDifficulty(StringToInt(sDifficulty), param1);
			OpenDifficultyMenu(param1, GetMenuBool(menu, "isadmin"));
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
				OpenMainMenu(param1);
		case MenuAction_End:
			delete menu;
	}
}

void UpdateDifficulty(int difficulty, int admin = -1)
{
	if (admin != -1 && !IsDrixevel(admin) && g_Match.roundphase != PHASE_STARTING)
	{
		CPrintToChat(admin, "You aren't allowed to switch the difficulty during the match.");
		return;
	}

	g_Match.difficulty = difficulty;

	if (admin != -1)
	{
		CPrintToChat(admin, "Difficulty set to: {haunted}%s", g_Difficulty[difficulty].name);
		CPrintToChatAll("{haunted}%N {default}has set the difficulty to {haunted}%s{default}.", admin, g_Difficulty[difficulty].name);
	}
	else
		CPrintToChatAll("Difficulty has been set to {haunted}%s{default}.", g_Difficulty[difficulty].name);
}

int GetDifficultyByName(const char[] name)
{
	for (int i = 0; i < g_TotalDifficulties; i++)
		if (StrEqual(name, g_Difficulty[i].name, false))
			return i;
	
	return -1;
}

public Action Command_KillZombie(int client, int args)
{
	int entity = GetClientAimTarget(client, false);

	if (!IsValidEntity(entity) || TheNPCs.FindNPCByEntIndex(entity) == INVALID_NPC)
	{
		CPrintToChatAll("Please look at a zombie to kill it.");
		return Plugin_Handled;
	}

	OnZombieDeath(entity);
	CPrintToChatAll("Zombie has been killed.");

	return Plugin_Handled;
}

public Action Command_KillAllZombies(int client, int args)
{
	KillAllZombies();
	CPrintToChatAll("{haunted}%N {default}has killed all of the zombies.", client);
	return Plugin_Handled;
}

public Action Command_Machines(int client, int args)
{
	OpenPerksMenu(client);
	return Plugin_Handled;
}

void OpenPerksMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Perks);
	menu.SetTitle("Choose a perk:");

	char sID[16];
	for (int i = 0; i < g_TotalMachines; i++)
	{
		IntToString(i, sID, sizeof(sID));
		menu.AddItem(sID, g_MachinesData[i].display);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Perks(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sID[16];
			menu.GetItem(param2, sID, sizeof(sID));
			int index = StringToInt(sID);

			if (g_Player[param1].HasPerk(g_MachinesData[index].name))
			{
				CPrintToChat(param1, "You already have the perk {haunted}%s{default}.", g_MachinesData[index].display);
				OpenPerksMenu(param1);
				return;
			}

			g_Player[param1].AddPerk(g_MachinesData[index].name);
			CPrintToChat(param1, "You have given yourself the perk {haunted}%s{default}.", g_MachinesData[index].display);
			OpenPerksMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public Action Command_SetRound(int client, int args)
{
	if (g_Match.roundphase != PHASE_WAITING && g_Match.roundphase != PHASE_ACTIVE)
	{
		CPrintToChat(client, "A match must be active set the active round.");
		return Plugin_Handled;
	}

	int round = GetCmdArgInt(1);

	if (round < 1)
		round = 1;
	else if (round >= 1000)
		round = 1000;

	g_Match.round = round;
	CPrintToChat(client, "Round has been set to {haunted}%i{default}.", g_Match.round);
	
	if (g_Match.round >= 25)
		OpenBonusDoor();

	UnlockRelays();

	return Plugin_Handled;
}

/****************************************/
//Specials
/****************************************/

void ParseSpecials()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/undead/specials.cfg");

	KeyValues kv = new KeyValues("specials");

	if (kv.ImportFromFile(sPath) && kv.GotoFirstSubKey())
	{
		g_TotalZombieTypes = 0;

		do
		{
			kv.GetSectionName(g_ZombieTypes[g_TotalZombieTypes].name, 64);
			kv.GetString("description", g_ZombieTypes[g_TotalZombieTypes].description, 128);
			g_ZombieTypes[g_TotalZombieTypes].health = kv.GetNum("health");
			g_ZombieTypes[g_TotalZombieTypes].class = kv.GetNum("class");
			g_ZombieTypes[g_TotalZombieTypes].team = kv.GetNum("team");
			g_ZombieTypes[g_TotalZombieTypes].size = kv.GetFloat("size");
			g_ZombieTypes[g_TotalZombieTypes].speed = kv.GetFloat("speed");
			kv.GetColor4("color", g_ZombieTypes[g_TotalZombieTypes].color);
			kv.GetString("spawn_sound", g_ZombieTypes[g_TotalZombieTypes].spawn_sound, PLATFORM_MAX_PATH);
			kv.GetString("death_sound", g_ZombieTypes[g_TotalZombieTypes].death_sound, PLATFORM_MAX_PATH);
			kv.GetString("particle", g_ZombieTypes[g_TotalZombieTypes].particle, 64);
			g_ZombieTypes[g_TotalZombieTypes].unlock_wave = kv.GetNum("unlock_wave");
			g_TotalZombieTypes++;
		}
		while (kv.GotoNextKey());
	}

	delete kv;
	LogMessage("Zombies Loaded: %i", g_TotalZombieTypes);
}

float[] PredictSubjectPosition(CBaseNPC npc, int subject)
{
	if (!g_Zombies[npc.Index].insidemap)
		return NULL_VECTOR;
	
	float botPos[3];
	GetEntPropVector(npc.GetEntity(), Prop_Data, "m_vecAbsOrigin", botPos);
	
	float subjectPos[3];
	GetEntPropVector(subject, Prop_Data, "m_vecAbsOrigin", subjectPos);
	
	float to[3];
	SubtractVectors(subjectPos, botPos, to);
	to[2] = 0.0;
	
	float flRangeSq = GetVectorLength(to, true);
	
	// don't lead if subject is very far away
	float flLeadRadiusSq = 500.0;
	flLeadRadiusSq *= flLeadRadiusSq;
	if (flRangeSq > flLeadRadiusSq)
		return subjectPos;
	
	// Normalize in place
	float range = SquareRoot(flRangeSq);
	to[0] /= (range + 0.0001); // avoid divide by zero
	to[1] /= (range + 0.0001); // avoid divide by zero
	to[2] /= (range + 0.0001); // avoid divide by zero
	
	// estimate time to reach subject, assuming maximum speed
	float leadTime = 0.5 + (range / (npc.flRunSpeed + 0.0001));
	
	// estimate amount to lead the subject
	float SubjectAbsVelocity[3];
	GetEntPropVector(subject, Prop_Data, "m_vecAbsVelocity", SubjectAbsVelocity);
	float lead[3];
	lead[0] = leadTime * SubjectAbsVelocity[0];
	lead[1] = leadTime * SubjectAbsVelocity[1];
	lead[2] = 0.0;
	
	if (GetVectorDotProduct(to, lead) < 0.0)
	{
		// the subject is moving towards us - only pay attention 
		// to his perpendicular velocity for leading
		float to2D[3]; to2D = to;
		to2D[2] = 0.0;
		NormalizeVector(to2D, to2D);
		
		float perp[2];
		perp[0] = -to2D[1];
		perp[1] = to2D[0];
		
		float enemyGroundSpeed = lead[0] * perp[0] + lead[1] * perp[1];
		
		lead[0] = enemyGroundSpeed * perp[0];
		lead[1] = enemyGroundSpeed * perp[1];
	}
	
	// compute our desired destination
	float pathTarget[3];
	AddVectors(subjectPos, lead, pathTarget);

	// validate this destination
	NextBotGroundLocomotion loco = npc.GetLocomotion();
	
	// don't lead through walls
	if (GetVectorLength(lead, true) > 36.0)
	{
		float fraction;
		if (!loco.IsPotentiallyTraversable(subjectPos, pathTarget, IMMEDIATELY, fraction))
		{
			// tried to lead through an unwalkable area - clip to walkable space
			pathTarget[0] = subjectPos[0] + fraction * (pathTarget[0] - subjectPos[0]);
			pathTarget[1] = subjectPos[1] + fraction * (pathTarget[1] - subjectPos[1]);
			pathTarget[2] = subjectPos[2] + fraction * (pathTarget[2] - subjectPos[2]);
		}
	}
	
	CNavArea leadArea = TheNavMesh.GetNearestNavArea(pathTarget);
	
	if (leadArea == NULL_AREA || leadArea.GetZ(pathTarget[0], pathTarget[1]) < pathTarget[2] - loco.GetMaxJumpHeight())
	{
		// would fall off a cliff
		return subjectPos;
	}
	
	return pathTarget;
}

public Action OnSoundPlay(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
	  int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
	  char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	//PrintToChatAll(sample);
}

int debugweapon = -1;
int debugcurrent;

public Action Command_DebugWeapons(int client, int args)
{
	if (IsValidEntity(debugweapon))
		AcceptEntityInput(debugweapon, "Kill");
		
	debugweapon = CreateEntityByName("prop_dynamic");
	debugcurrent = 0;

	char sModel[PLATFORM_MAX_PATH];
	TF2Items_GetItemKeyString(g_CustomWeapons[debugcurrent].name, "worldmodel", sModel, sizeof(sModel));

	DispatchKeyValueVector(debugweapon, "origin", view_as<float>({1105.0, 71.0, 75.0}));
	DispatchKeyValue(debugweapon, "model", sModel);
	DispatchSpawn(debugweapon);

	PrintToChat(client, "Weapon %i: %s", debugcurrent, g_CustomWeapons[debugcurrent].name);

	return Plugin_Handled;
}

public Action Command_NextWeapons(int client, int args)
{
	debugcurrent++;

	if (debugcurrent > g_TotalCustomWeapons)
		debugcurrent = 0;
	
	char sModel[PLATFORM_MAX_PATH];
	TF2Items_GetItemKeyString(g_CustomWeapons[debugcurrent].name, "worldmodel", sModel, sizeof(sModel));

	SetEntityModel(debugweapon, sModel);

	PrintToChat(client, "Weapon %i: %s", debugcurrent, g_CustomWeapons[debugcurrent].name);

	return Plugin_Handled;
}

public Action Command_StopDebugWeapons(int client, int args)
{
	if (IsValidEntity(debugweapon))
		AcceptEntityInput(debugweapon, "Kill");
	
	return Plugin_Handled;
}

float CalculateSpeed(int special)
{
	float basespeed = g_ZombieTypes[special].speed;

	if (basespeed == -1.0)
		basespeed = ZOMBIE_BASE_SPEED;
		
	return (basespeed + (g_Match.round * 0.05)) * g_Difficulty[g_Match.difficulty].movespeed_multipler;
}

int CalculateHealth(int entity)
{
	if (entity > 0 && entity <= MaxClients && GetClientTeam(entity) != TEAM_ZOMBIES)
		return g_Player[entity].HasPerk("juggernog") ? 300 : 150;

	CBaseNPC npc;
	if (entity > MaxClients)
		npc = TheNPCs.FindNPCByEntIndex(entity);

	int special = (entity > 0 && entity <= MaxClients) ? g_Player[entity].type : g_Zombies[npc.Index].type;

	if (special == -1)
		special = GetZombieTypeByName(ZOMBIE_DEFAULT);
	
	int basehealth = g_ZombieTypes[special].health;

	if (basehealth == -1)
	{
		int class = (entity > 0 && entity <= MaxClients) ? view_as<int>(TF2_GetPlayerClass(entity)) : g_Zombies[npc.Index].class;

		if (class == view_as<int>(TFClass_Heavy))
			basehealth = 250;
		else if (class == view_as<int>(TFClass_Soldier))
			basehealth = 200;
		else
			basehealth = 150;
	}

	basehealth = RoundFloat(float(basehealth) * g_Difficulty[g_Match.difficulty].health_multiplier);
	return (basehealth + (g_Match.round * 2));
}

float CalculateDamage()
{
	float basedamage = GetRandomFloat(ZOMBIE_DAMAGE_MIN, ZOMBIE_DAMAGE_MAX);
	float damage = basedamage * g_Difficulty[g_Match.difficulty].damage_multiplier;

	if (g_Match.round >= 30)
		damage *= 3.0;
	else if (g_Match.round >= 25)
		damage *= 2.5;
	else if (g_Match.round >= 20)
		damage *= 2.0;
	else if (g_Match.round >= 15)
		damage *= 1.5;
	else if (g_Match.round >= 10)
		damage *= 1.3;
	else if (g_Match.round >= 5)
		damage *= 1.2;
	
	return damage;
}

public Action Command_TestAnim(int client, int args)
{
	ActivateAnimation(client, "packapunch", GetActiveWeapon(client));
	return Plugin_Handled;
}

void ActivateAnimation(int client, const char[] animation, int weapon = -1)
{
	if (StrEqual(animation, "packapunch", false) && IsValidEntity(weapon))
	{
		int index = g_WeaponIndex[weapon];

		if (index == -1)
			return;

		int punch = -1; int entity = -1;
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
			if (entity > 0 && g_Machines[entity].index == GetMachine("packapunch"))
				punch = entity;
		
		int propweapon = -1;
		if (IsValidEntity(punch))
		{ 
			float origin[3];
			GetEntityOrigin(punch, origin);
			
			char sModel[PLATFORM_MAX_PATH];
			TF2Items_GetItemKeyString(g_CustomWeapons[index].name, "worldmodel", sModel, sizeof(sModel));
			
			propweapon = CreateEntityByName("prop_dynamic");
			origin[0] += 10.0; origin[1] += -20.0; origin[2] += 85.0;
			DispatchKeyValueVector(propweapon, "origin", origin);
			DispatchKeyValueVector(propweapon, "angles", g_CustomWeapons[index].offset_angles);
			DispatchKeyValue(propweapon, "model", sModel);
			DispatchSpawn(propweapon);

			TF2_CreateGlow("propweaponcolor", propweapon, view_as<int>({255, 200, 200, 150}));

			AcceptEntityInput(g_Machines[punch].glow, "Disable");
		}

		EquipWeaponSlot(client, 2);
		TF2_AddCondition(client, TFCond_FreezeInput);

		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");

		SetClientViewEntity(client, propweapon);
		SetEntityMoveType(client, MOVETYPE_OBSERVER);

		EmitSoundToAll("misc/doomsday_cap_open.wav", client);

		StopTimer(g_Player[client].punchanim);
		DataPack pack;
		g_Player[client].punchanim = CreateDataTimer(5.0, Timer_InitPackaPunch, pack);
		pack.WriteCell(client);
		pack.WriteCell(weapon);
		pack.WriteCell(punch);
		pack.WriteCell(propweapon);
	}
}

public Action Timer_InitPackaPunch(Handle timer, DataPack pack)
{
	pack.Reset();

	int client = pack.ReadCell();
	int weapon = pack.ReadCell();
	int punch = pack.ReadCell();
	int propweapon = pack.ReadCell();

	g_Player[client].punchanim = null;
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		EquipWeapon(client, weapon);
		TF2_RemoveCondition(client, TFCond_FreezeInput);
		InspectWeapon(client);

		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}

	if (IsValidEntity(propweapon))
		AcceptEntityInput(propweapon, "Kill");
	
	AcceptEntityInput(g_Machines[punch].glow, "Enable");

	SetClientViewEntity(client, client);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	
	return Plugin_Stop;
}

float GetZombieSoundDuration(int entity)
{
	float time = GetGameTime();
	float cooldown;

	if (entity > MaxClients)
		cooldown = time + GetRandomFloat(5.0, 30.0);
	else
		cooldown = time + GetRandomFloat(1.0, 3.0);
	
	return cooldown;
}

void PlayZombieSound(int entity)
{
	float size;
	if (entity > MaxClients)
	{
		CBaseNPC npc = TheNPCs.FindNPCByEntIndex(entity);
		size = npc.nSize;
	}
	else
		size = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");

	char sSound[PLATFORM_MAX_PATH];
	if (size > 1.0)
		FormatEx(sSound, sizeof(sSound), "undead/zombies/undead_giant_zombie0%i.wav", GetRandomInt(1, 3));
	else
		FormatEx(sSound, sizeof(sSound), "undead/zombies/undead_zombie0%i.wav", GetRandomInt(1, 7));
	
	EmitSoundToAll(sSound, entity);
}

stock void CreatePointGlow(float origin[3], float time = 0.95, float size = 0.5, int brightness = 50)
{
	TE_SetupGlowSprite(origin, g_GlowSprite, time, size, brightness);
	TE_SendToAll();
}

void PrintErrorMessage(int client, const char[] format, any ...)
{
	char sBuffer[255];
	VFormat(sBuffer, sizeof(sBuffer), format, 3);

	EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
	CPrintToChat(client, sBuffer);
}

void OpenBonusDoor()
{
	g_Match.secret_door_unlocked = true;

	int secret_door = FindEntityByName("bonus_level_door");

	if (IsValidEntity(secret_door))
	{
		AcceptEntityInput(secret_door, "Unlock");
		AcceptEntityInput(secret_door, "Open");
	}
	
	RecomputeNavs();

	int sprite;

	if ((sprite = FindEntityByName("secretdoor_sprite_disabled", "env_sprite")) != -1)
		AcceptEntityInput(sprite, "HideSprite");
	
	if ((sprite = FindEntityByName("secretdoor_sprite_enabled", "env_sprite")) != -1)
		AcceptEntityInput(sprite, "ShowSprite");
}

void CloseBonusDoor()
{
	g_Match.secret_door_unlocked = false;

	int secret_door = FindEntityByName("bonus_level_door");

	if (IsValidEntity(secret_door))
	{
		AcceptEntityInput(secret_door, "Lock");
		AcceptEntityInput(secret_door, "Close");
	}
	
	RecomputeNavs();

	int sprite;

	if ((sprite = FindEntityByName("secretdoor_sprite_disabled", "env_sprite")) != -1)
		AcceptEntityInput(sprite, "ShowSprite");
	
	if ((sprite = FindEntityByName("secretdoor_sprite_enabled", "env_sprite")) != -1)
		AcceptEntityInput(sprite, "HideSprite");
}

public Action Command_Statistics(int client, int args)
{
	OpenStatisticsMenu(client);
	return Plugin_Handled;
}

void OpenStatisticsMenu(int client, bool back = false)
{
	Menu menu = new Menu(MenuHandler_Statistics);
	menu.SetTitle("Undead Statistics");

	menu.AddItem("global", "Global Statistics");
	menu.AddItem("server", "Server Statistics");
	menu.AddItem("session", "Session Statistics");

	menu.ExitBackButton = back;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Statistics(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			if (StrEqual(sInfo, "global"))
				ShowGlobalStatistics(param1);
			else if (StrEqual(sInfo, "server"))
				ShowServerStatistics(param1);
			else if (StrEqual(sInfo, "session"))
				ShowSessionStatistics(param1);
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
				OpenMainMenu(param1);
		case MenuAction_End:
			delete menu;
	}
}

void ShowGlobalStatistics(int client)
{
	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID)))
		return;
	
	char sQuery[512];
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT SUM(kills), SUM(deaths), SUM(revives), SUM(machines_bought), SUM(weapons_bought), SUM(mysteryboxes_opened), SUM(planks_rebuilt), SUM(buildings_rented), SUM(points_gained), SUM(points_spent), SUM(damage), SUM(waves_won), SUM(specials_killed), SUM(revived), SUM(powerups_pickedup), SUM(total_teammates), SUM(doors_opened) FROM `undead_statistics` WHERE steamid = '%s';", sSteamID);
	g_Database.Query(OnParseGlobalStatistics, sQuery, GetClientUserId(client));
}

void ShowServerStatistics(int client)
{
	char sSteamID[64];
	if (!GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID)))
		return;
	
	char sServerIP[64];
	GetServerIP(sServerIP, sizeof(sServerIP), true);
	
	char sQuery[512];
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT SUM(kills), SUM(deaths), SUM(revives), SUM(machines_bought), SUM(weapons_bought), SUM(mysteryboxes_opened), SUM(planks_rebuilt), SUM(buildings_rented), SUM(points_gained), SUM(points_spent), SUM(damage), SUM(waves_won), SUM(specials_killed), SUM(revived), SUM(powerups_pickedup), SUM(total_teammates), SUM(doors_opened) FROM `undead_statistics` WHERE steamid = '%s' ANd server = '%s';", sSteamID, sServerIP);
	g_Database.Query(OnParseServerStatistics, sQuery, GetClientUserId(client));
}

void ShowSessionStatistics(int client)
{
	GenerateStatisticsPanel(client, "Session", g_Player[client].stats);
}

public void OnParseGlobalStatistics(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while parsing statistics: %s", error);
	
	int client;
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	StringMap stats = new StringMap();

	if (results.FetchRow())
	{
		char stat[64];
		for (int i = 0; i < statistics.Length; i++)
		{
			statistics.GetString(i, stat, sizeof(stat));
			stats.SetValue(stat, results.FetchInt(i));
		}
	}

	GenerateStatisticsPanel(client, "Global", stats);
	delete stats;
}

public void OnParseServerStatistics(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
		ThrowError("Error while parsing statistics: %s", error);
	
	int client;
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	StringMap stats = new StringMap();

	if (results.FetchRow())
	{
		char stat[64];
		for (int i = 0; i < statistics.Length; i++)
		{
			statistics.GetString(i, stat, sizeof(stat));
			stats.SetValue(stat, results.FetchInt(i));
		}
	}

	GenerateStatisticsPanel(client, "Server", stats);
	delete stats;
}

void GenerateStatisticsPanel(int client, const char[] title, StringMap stats)
{
	Panel panel = new Panel();

	char description[64];
	if (StrEqual(title, "global", false))
		FormatEx(description, sizeof(description), "These are your global statistics from every server.");
	else if (StrEqual(title, "server", false))
		FormatEx(description, sizeof(description), "These are your statistics for this server.");
	else if (StrEqual(title, "session", false))
		FormatEx(description, sizeof(description), "These are your statistics this round.");

	char sTitle[128];
	FormatEx(sTitle, sizeof(sTitle), "Undead Statistics - %s\n - %s", title, description);
	panel.SetTitle(sTitle);
	
	char statistic[128]; char display[128]; char sText[128];
	for (int i = 0; i < statistics.Length; i++)
	{
		statistics.GetString(i, statistic, sizeof(statistic));

		int value;
		stats.GetValue(statistic, value);

		statisticsnames.GetString(statistic, display, sizeof(display));
		FormatEx(sText, sizeof(sText), "%s - %i", display, value);
		panel.DrawText(sText);
	}

	panel.DrawItem("Back");
	panel.DrawItem("Exit");

	panel.Send(client, MenuAction_Statistics, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuAction_Statistics(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			if (param2 == 1)
				OpenStatisticsMenu(param1);
	}
}

public Action Command_Target(int client, int args)
{
	if (args == 0)
	{
		if (g_GlobalTarget != -1)
			TF2_RemoveCondition(g_GlobalTarget, TFCond_MarkedForDeath);
		
		g_GlobalTarget = -1;
		CPrintToChat(client, "Target has been disabled.");
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArgString(sTarget, sizeof(sTarget));

	int target = FindTarget(client, sTarget, false, false);

	if (target == -1)
	{
		CPrintToChat(client, "Target not found, please try again.");
		return Plugin_Handled;
	}

	g_GlobalTarget = target;
	TF2_AddCondition(g_GlobalTarget, TFCond_MarkedForDeath, TFCondDuration_Infinite);
	CPrintToChatAll("%N is now enemy number 1!", g_GlobalTarget);

	return Plugin_Handled;
}

public Action Command_SetZombieType(int client, int args)
{
	int target = client;

	if (args > 0)
	{
		char sTarget[MAX_TARGET_LENGTH];
		GetCmdArg(1, sTarget, sizeof(sTarget));
		target = FindTarget(client, sTarget, false, false);
	}

	if (target == -1)
	{
		CPrintToChat(client, "Target not found, please try again.");
		return Plugin_Handled;
	}

	char sSpecial[64];
	if (args > 1)
		GetCmdArg(2, sSpecial, sizeof(sSpecial));
	else
		GetCmdArg(1, sSpecial, sizeof(sSpecial));

	int special = GetZombieTypeByName(sSpecial);

	if (special == -1)
	{
		CPrintToChat(client, "Special not found, please be more specific.");
		return Plugin_Handled;
	}

	if (!IsClientInGame(target) || !IsPlayerAlive(target))
	{
		if (client == target)
			CPrintToChat(client, "You're not in-game and/or alive to be set.");
		else
			CPrintToChat(client, "%N is not in-game and/or alive to be set.", target);
		
		return Plugin_Handled;
	}

	if (GetClientTeam(target) != TEAM_SURVIVORS)
	{
		if (client == target)
			CPrintToChat(client, "You must be a zombie to set your special.");
		else
			CPrintToChat(client, "%N must be a zombie to set their special.", target);
		
		return Plugin_Handled;
	}

	float origin[3];
	GetClientAbsOrigin(target, origin);

	ApplySpecialUpdates(target, special, origin);

	if (client == target)
		CPrintToChat(client, "You are now a {haunted}%s{default}.", g_ZombieTypes[special].name);
	else
	{
		CPrintToChat(client, "You have set {haunted}%N {default}to a {haunted}%s{default}.", target, g_ZombieTypes[special].name);
		CPrintToChat(target, "You are now a {haunted}%s{default}. (Set by {haunted}%N{default})", g_ZombieTypes[special].name, client);
	}
	
	return Plugin_Handled;
}

public Action Command_VoteDifficulty(int client, int args)
{

	return Plugin_Handled;
}

public Action Command_WaveInfo(int client, int args)
{
	OpenWaveInfoPanel(client);
	return Plugin_Handled;
}

void OpenWaveInfoPanel(int client)
{
	Panel panel = new Panel();

	char title[64];
	FormatEx(title, sizeof(title), "Wave %i - Difficulty: %s", g_Match.round, g_Difficulty[g_Match.difficulty].name);
	panel.SetTitle(title);

	char text[64];
	for (int i = 0; i < g_TotalZombieTypes; i++)
	{
		FormatEx(text, sizeof(text), "%s: %s (%i)", g_ZombieTypes[i].name, (g_ZombieTypes[i].unlock_wave == -1 || g_ZombieTypes[i].unlock_wave <= g_Match.round) ? "Unlocked" : "Locked", g_ZombieTypes[i].unlock_wave);
		panel.DrawText(text);
	}

	panel.DrawItem("Reload Info");
	panel.DrawItem("Exit Panel");

	panel.Send(client, MenuHandler_WaveInfo, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuHandler_WaveInfo(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
			if (param2 == 1)
				OpenWaveInfoPanel(param1);
	}
}

public MRESReturn DispenseMetal(int thisp, Handle hReturn, Handle hParams)
{
	if (hReturn != null)
	{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

void CreateTF2Timer(int timer)
{
	int entity = FindEntityByClassname(-1, "team_round_timer");

	if (!IsValidEntity(entity))
		entity = CreateEntityByName("team_round_timer");

	char sTime[32];
	IntToString(timer, sTime, sizeof(sTime));
	
	DispatchKeyValue(entity, "reset_time", "1");
	DispatchKeyValue(entity, "auto_countdown", "0");
	DispatchKeyValue(entity, "timer_length", sTime);
	DispatchSpawn(entity);

	AcceptEntityInput(entity, "Resume");

	SetVariantInt(1);
	AcceptEntityInput(entity, "ShowInHUD");
}

void PauseTF2Timer()
{
	int entity = FindEntityByClassname(-1, "team_round_timer");

	if (!IsValidEntity(entity))
		entity = CreateEntityByName("team_round_timer");
	
	AcceptEntityInput(entity, "Pause");
}

void UnpauseTF2Timer()
{
	int entity = FindEntityByClassname(-1, "team_round_timer");

	if (!IsValidEntity(entity))
		entity = CreateEntityByName("team_round_timer");
	
	AcceptEntityInput(entity, "Resume");
}

public Action Command_ReloadConfigs(int client, int ars)
{
	ParseDifficulties();
	ParseMachines();
	ParseWeapons();
	ParsePowerups();
	ParseSpecials();
	CPrintToChat(client, "Undead configurations have been reloaded.");
	return Plugin_Handled;
}