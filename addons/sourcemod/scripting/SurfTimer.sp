/*=========================================================
=                    CS:GO SurfTimer                      =
=       modified version of "SurfTimer" from fluffy       =
= The original version of this timer was by jonitaikaponi =
=  https://forums.alliedmods.net/showthread.php?t=264498  =
=========================================================*/

/*====================================
=              Includes              =
====================================*/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <adminmenu>
#include <cstrike>
#include <geoip>
#include <basecomm>
#include <colorlib>
#include <autoexecconfig>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <dhooks>
#include <mapchooser>
#include <surftimer>

/*===================================
=            Definitions            =
===================================*/

// Require New Syntax & Semicolons
#pragma newdecls required
#pragma semicolon 1

// More dynamic array size
#pragma dynamic 2621440

// Plugin Info
#define VERSION "1.0.dev"

// Database Definitions
#define MYSQL 0
#define SQLITE 1
#define PERCENT 0x25
#define QUOTE 0x22

// Chat Colors
#define WHITE 0x01
#define DARKRED 0x02
#define PURPLE 0x03
#define GREEN 0x04
#define LIGHTGREEN 0x05
#define LIMEGREEN 0x06
#define RED 0x07
#define GRAY 0x08
#define YELLOW 0x09
#define ORANGE 0x10
#define DARKGREY 0x0A
#define BLUE 0x0B
#define DARKBLUE 0x0C
#define LIGHTBLUE 0x0D
#define PINK 0x0E
#define LIGHTRED 0x0F
#define ORCHID 0x1A // not sure if this is orchid color in csgo.

// Paths for folders and files
#define CK_REPLAY_PATH "data/replays/"
#define MULTI_SERVER_MAPCYCLE "configs/surftimer/multi_server_mapcycle.txt"
#define CUSTOM_TITLE_PATH "configs/surftimer/custom_chat_titles.txt"
#define SKILLGROUP_PATH "configs/surftimer/skillgroups.cfg"
#define DEFAULT_TITLES_WHITELIST_PATH "configs/surftimer/default_titles_whitelist.txt"
#define DEFAULT_TITLES_PATH "configs/surftimer/default_titles.txt"
#define HINTS_PATH "configs/surftimer/hints.txt"

// Paths for sounds
#define WR2_FULL_SOUND_PATH "sound/surftimer/wr.mp3"
#define WR2_RELATIVE_SOUND_PATH "*surftimer/wr.mp3"
#define TOP10_FULL_SOUND_PATH "sound/surftimer/top10.mp3"
#define TOP10_RELATIVE_SOUND_PATH "*surftimer/top10.mp3"
#define PR_FULL_SOUND_PATH "sound/surftimer/pr.mp3"
#define PR_RELATIVE_SOUND_PATH "*surftimer/pr.mp3"

#define MAX_STYLES 8

#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

// Checkpoint Definitions
// Maximum amount of checkpoints in a map
#define CPLIMIT 37

// Zone Definitions
#define ZONE_MODEL "models/props/de_train/barrel.mdl"

// Zone Amount
// Types: Start(1), End(2), Stage(3), Checkpoint(4), Speed(5),
// TeleToStart(6), Validator(7), Chekcer(8), Stop(0), AntiJump(9),
// AntiDuck(10), MaxSpeed(11)
#define ZONEAMOUNT 12
// Maximum amount of zonegroups in a map
#define MAXZONEGROUPS 12
// Maximum amount of zones in a map
#define MAXZONES 128

// Part of SMLib
#define MAX_WEAPONS				48	// Max number of weapons availabl

// Ranking Definitions
#define MAX_PR_PLAYERS 1066
#define MAX_SKILLGROUPS 64

// UI Definitions
#define HIDE_RADAR (1 << 12)
#define HIDE_CHAT ( 1<<7 )
#define HIDE_CROSSHAIR 1<<8

// Replay Definitions
#define BM_MAGIC 0xBAADF00D
#define BINARY_FORMAT_VERSION 0x02
#define ADDITIONAL_FIELD_TELEPORTED_ORIGIN (1<<0)
#define ADDITIONAL_FIELD_TELEPORTED_ANGLES (1<<1)
#define ADDITIONAL_FIELD_TELEPORTED_VELOCITY (1<<2)
#define ORIGIN_SNAPSHOT_INTERVAL 500

// Show Triggers
#define EF_NODRAW 32

// New Save Locs
#define MAX_LOCS 128

//CSGO HUD Hint Fix
#define MAX_HINT_SIZE 225

// Maximum size of hints
#define MAX_HINT_MESSAGES_SIZE 256

/*====================================
=            Enumerations            =
====================================*/

// new frame info
enum struct frame_t
{
	float pos[3];
	float ang[2];
	int buttons;
	int flags;
	MoveType mt;
}


// old frame info
enum struct FrameInfo
{
	int PlayerButtons;
	int PlayerImpulse;
	float ActualVelocity[3];
	float PredictedVelocity[3];
	float PredictedAngles[2];
	CSWeaponID NewWeapon;
	int PlayerSubtype;
	int PlayerSeed;
	int AdditionalFields;
	int Pause;
}

enum struct AdditionalTeleport
{
	float AtOrigin[3];
	float AtAngles[3];
	float AtVelocity[3];
	int AtFlags;
}

enum struct FileHeader
{
	int BinaryFormatVersion;
	char Time[32];
	char Playername[MAX_NAME_LENGTH];
	int Checkpoints;
	int TickCount;
	float InitialPosition[3];
	float InitialAngles[3];
	ArrayList Frames;
}

enum struct MapZone
{
	int ZoneId;
	int ZoneType;
	int ZoneTypeId;
	float PointA[3];
	float PointB[3];
	float CenterPoint[3];
	char ZoneName[128];
	char HookName[128];
	char TargetName[128];
	int OneJumpLimit;
	float PreSpeed;
	int ZoneGroup;
	int Vis;
	int Team;
}

enum struct SkillGroup
{
	int PointsBot;
	int PointsTop;
	int PointReq;
	int RankBot;
	int RankTop;
	int RankReq;
	char RankName[128];
	char RankNameColored[128];
	char NameColour[32];
}

enum ResponseType
{
  None,
  PreSpeed,
  ZoneGroup,
  MaxVelocity,
  TargetName,
  ClientEdit,
}

/*===================================
=            Plugin Info            =
===================================*/

public Plugin myinfo =
{
	name = "SurfTimer",
	author = "All contributors",
	description = "a fork from fluffys cksurf fork",
	version = VERSION,
	url = "https://github.com/surftimer/Surftimer-Official"
};

/*===================================
=             Variables             =
===================================*/

// Testing Variables
float g_fTick[MAXPLAYERS + 1][2];
float g_fServerLoading[2];
float g_fClientsLoading[MAXPLAYERS + 1][2];
char g_szLogFile[PLATFORM_MAX_PATH];

// PR Commands
int g_iPrTarget[MAXPLAYERS + 1];
int g_totalStagesPr[MAXPLAYERS + 1];
int g_totalBonusesPr[MAXPLAYERS + 1];

// Speed Gradient
char g_szSpeedColour[MAXPLAYERS + 1];

// Show Zones
bool g_bShowZones[MAXPLAYERS + 1];

/*----------  Stages  ----------*/

// Which stage is the client in
int g_Stage[MAXZONEGROUPS][MAXPLAYERS + 1];
int g_WrcpStage[MAXPLAYERS + 1];

bool g_bhasStages;

/*----------  Spawn Locations  ----------*/
float g_fSpawnLocation[MAXZONEGROUPS][CPLIMIT][2][3];
float g_fSpawnAngle[MAXZONEGROUPS][CPLIMIT][2][3];
float g_fSpawnVelocity[MAXZONEGROUPS][CPLIMIT][2][3];
bool g_bGotSpawnLocation[MAXZONEGROUPS][CPLIMIT][2];

/*----------  Bonus Variables  ----------*/

// Name of the #1 in the current maps bonus
char g_szBonusFastest[MAXZONEGROUPS][MAX_NAME_LENGTH];

// Fastest bonus time in 00:00:00:00 format
char g_szBonusFastestTime[MAXZONEGROUPS][64];

// Clients personal bonus record in the current map
float g_fPersonalRecordBonus[MAXZONEGROUPS][MAXPLAYERS + 1];

// Personal bonus record in 00:00:00 format
char g_szPersonalRecordBonus[MAXZONEGROUPS][MAXPLAYERS + 1][64];

// Fastest bonus time in the current map
float g_fBonusFastest[MAXZONEGROUPS];

// Old record time, for prints + counting
float g_fOldBonusRecordTime[MAXZONEGROUPS];

// Clients personal bonus rank in the current map
int g_MapRankBonus[MAXZONEGROUPS][MAXPLAYERS + 1];

// Old rank in bonus
int g_OldMapRankBonus[MAXZONEGROUPS][MAXPLAYERS + 1];

// Has the client missed his best bonus time
int g_bMissedBonusBest[MAXPLAYERS + 1];

// Used to make sure bonus finished prints are correct
int g_tmpBonusCount[MAXZONEGROUPS];

// Amount of players that have passed the bonus in current map
int g_iBonusCount[MAXZONEGROUPS];

// How many total bonuses there are
int g_totalBonusCount;

// Does map have a bonus?
bool g_bhasBonus;

/*----------  Checkpoint Variables  ----------*/

// Clients best run's times
float g_fCheckpointTimesRecord[MAXZONEGROUPS][MAXPLAYERS + 1][CPLIMIT];

// Clients current run's times
float g_fCheckpointTimesNew[MAXZONEGROUPS][MAXPLAYERS + 1][CPLIMIT];

// Server record checkpoint times
float g_fCheckpointServerRecord[MAXZONEGROUPS][CPLIMIT];

// Last difference to the server record checkpoint
char g_szLastSRDifference[MAXPLAYERS + 1][64];

// Last difference to clients own record checkpoint
char g_szLastPBDifference[MAXPLAYERS + 1][64];

// The time difference was shown, used to show for a few seconds in timer panel
float g_fLastDifferenceTime[MAXPLAYERS + 1];

// Used to calculate time gain / lost
float tmpDiff[MAXPLAYERS + 1];

// Used to track which checkpoint was last reached
int lastCheckpoint[MAXZONEGROUPS][MAXPLAYERS + 1];

// Clients checkpoints have been found?
bool g_bCheckpointsFound[MAXZONEGROUPS][MAXPLAYERS + 1];

// Map record checkpoints found?
bool g_bCheckpointRecordFound[MAXZONEGROUPS];

// The biggest % amount the player has reached in current map
float g_fMaxPercCompleted[MAXPLAYERS + 1];

int g_iCurrentCheckpoint[MAXPLAYERS + 1];

/*----------  Maptier Variables  ----------*/

// The string for each zonegroup
char g_sTierString[512];

// Tier data found?
bool g_bTierEntryFound;

// Tier data found in ZGrp
bool g_bTierFound;

// Tier announce timer
Handle AnnounceTimer[MAXPLAYERS + 1];

/*----------  Zone Variables  ----------*/

// Ignore end zone end touch if teleporting from inside a zone
bool g_bIgnoreZone[MAXPLAYERS + 1];

// Which zone the client is in 0 = ZoneType, 1 = ZoneTypeId, 2 = ZoneGroup, 3 = ZoneID
int g_iClientInZone[MAXPLAYERS + 1][4];

// Zone type count in each zoneGroup
int g_mapZonesTypeCount[MAXZONEGROUPS][ZONEAMOUNT];

// Zone group's name
char g_szZoneGroupName[MAXZONEGROUPS][128];

// Map Zone array
MapZone g_mapZones[MAXZONES];

// The total amount of zones in the map
int g_mapZonesCount;

// Map zone count in zonegroups
int g_mapZoneCountinGroup[MAXZONEGROUPS];

// Zone group cound
int g_mapZoneGroupCount;

// Additional zone corners, can't store multi dimensional arrays in enums..
float g_fZoneCorners[MAXZONES][8][3];

/*----------  AntiJump & AntiDuck Variables  ----------*/
bool g_bInDuck[MAXPLAYERS + 1] = {false, ...};
bool g_bInJump[MAXPLAYERS + 1] = {false, ...};
bool g_bJumpZoneTimer[MAXPLAYERS + 1] = {false, ...};
bool g_bInStartZone[MAXPLAYERS + 1] = {false, ...};
bool g_bInStageZone[MAXPLAYERS + 1];

/*----------  MaxSpeed Variables  ----------*/
bool g_bInMaxSpeed[MAXPLAYERS + 1];

/*----------  VIP Variables  ----------*/
ConVar g_hAutoVipFlag = null;
int g_VipFlag;
bool g_bVip[MAXPLAYERS + 1];
bool g_bCheckCustomTitle[MAXPLAYERS + 1];
bool g_bEnableJoinMsgs;
char g_szCustomJoinMsg[MAXPLAYERS + 1][256];

// 1 = PB Sound, 2 = Top 10 Sound, 3 = WR sound
// char g_szCustomSounds[MAXPLAYERS + 1][3][256];

/*----------  Custom Titles  ----------*/
char g_szCustomTitleColoured[MAXPLAYERS + 1][1024];
char g_szCustomTitle[MAXPLAYERS + 1][1024];
bool g_bDbCustomTitleInUse[MAXPLAYERS + 1] = {false, ...};
bool g_bdbHasCustomTitle[MAXPLAYERS + 1] = {false, ...};

// 0 = name, 1 = text;
int g_iCustomColours[MAXPLAYERS + 1][2];

// int g_idbCustomTextColour[MAXPLAYERS + 1] = {0, ...};
bool g_bHasCustomTextColour[MAXPLAYERS + 1] = {false, ...};
bool g_bCustomTitleAccess[MAXPLAYERS + 1] = {false, ...};
bool g_bUpdatingColours[MAXPLAYERS + 1];
// char g_szsText[MAXPLAYERS + 1];

// to be used with sm_p, stage sr
int g_pr_BonusCount;
int g_totalMapsCompleted[MAXPLAYERS + 1];
int g_mapsCompletedLoop[MAXPLAYERS + 1];
int g_uncMapsCompleted[MAXPLAYERS + 1];
Handle g_CompletedMenu;

/*----------  WRCP Variables  ----------*/
int g_pr_StageCount;

// Clients best WRCP times
float g_fWrcpRecord[MAXPLAYERS + 1][CPLIMIT][MAX_STYLES];

bool g_bWrcpTimeractivated[MAXPLAYERS + 1] = {false, ...};
bool g_bWrcpEndZone[MAXPLAYERS + 1] = {false, ...};
int g_CurrentStage[MAXPLAYERS + 1];
float g_fStartWrcpTime[MAXPLAYERS + 1];
float g_fFinalWrcpTime[MAXPLAYERS + 1];

// Total time the run took in 00:00:00 format
char g_szFinalWrcpTime[MAXPLAYERS + 1][32];
float g_fCurrentWrcpRunTime[MAXPLAYERS + 1];
int g_StageRank[MAXPLAYERS + 1][CPLIMIT];
float g_fStageRecord[CPLIMIT];
char g_szRecordStageTime[CPLIMIT];

int g_TotalStageRecords[CPLIMIT];
int g_TotalStages;
float g_fWrcpMenuLastQuery[MAXPLAYERS + 1] = {1.0, ...};
bool g_bSelectWrcp[MAXPLAYERS + 1];
int g_iWrcpMenuStyleSelect[MAXPLAYERS + 1];
char g_szWrcpMapSelect[MAXPLAYERS + 1][128];
bool g_bStageSRVRecord[MAXPLAYERS + 1][CPLIMIT];
char g_szStageRecordPlayer[CPLIMIT][MAX_NAME_LENGTH];
// bool g_bFirstStageRecord[CPLIMIT];

// PracMode SRCP
float g_fStartPracSrcpTime[MAXPLAYERS + 1];
float g_fCurrentPracSrcpRunTime[MAXPLAYERS + 1];
bool g_bPracSrcpTimerActivated[MAXPLAYERS + 1] = {false, ...};
int g_iPracSrcpStage[MAXPLAYERS + 1];
bool g_bPracSrcpEndZone[MAXPLAYERS + 1] = {false, ...};
float g_fFinalPracSrcpTime[MAXPLAYERS + 1];
char g_szFinalPracSrcpTime[MAXPLAYERS + 1][32];
float g_fSrcpPauseTime[MAXPLAYERS + 1];

// Prestrafe records
int g_iRecordPreStrafe[3][CPLIMIT][MAX_STYLES];
int g_iRecordPreStrafeBonus[3][MAXZONEGROUPS][MAX_STYLES];

/*----------  Map Settings Variables ----------*/
float g_fMaxVelocity;
ConVar g_hMaxVelocity;
float g_fAnnounceRecord;
bool g_bGravityFix;
ConVar g_hGravityFix;

/*----------  Style Variables  ----------*/

// 0 = normal, 1 = SW, 2 = HSW, 3 = BW, 4 = Low-Gravity, 5 = Slow Motion, 6 = Fast Forward, 7 = Freestyle
int g_iCurrentStyle[MAXPLAYERS + 1];
int g_iInitalStyle[MAXPLAYERS + 1];
char g_szInitalStyle[MAXPLAYERS + 1][256];
char g_szStyleHud[MAXPLAYERS + 1][32];
bool g_bRankedStyle[MAXPLAYERS + 1];
bool g_bFunStyle[MAXPLAYERS + 1];
int g_KeyCount[MAXPLAYERS + 1] = {0, ...};

// Map Styles
int g_StyleMapRank[MAX_STYLES][MAXPLAYERS + 1];
int g_OldStyleMapRank[MAX_STYLES][MAXPLAYERS + 1];
float g_fPersonalStyleRecord[MAX_STYLES][MAXPLAYERS + 1];
char g_szPersonalStyleRecord[MAX_STYLES][MAXPLAYERS + 1][256];
float g_fRecordStyleMapTime[MAX_STYLES];
char g_szRecordStyleMapTime[MAX_STYLES][64];
char g_szRecordStylePlayer[MAX_STYLES][MAX_NAME_LENGTH];
char g_szRecordStyleMapSteamID[MAX_STYLES][MAX_NAME_LENGTH];
int g_StyleMapTimesCount[MAX_STYLES];
bool g_bStyleMapFirstRecord[MAX_STYLES][MAXPLAYERS + 1];
bool g_bStyleMapPBRecord[MAX_STYLES][MAXPLAYERS + 1];
bool g_bStyleMapSRVRecord[MAX_STYLES][MAXPLAYERS + 1];

// Bonus Styles
char g_szStyleBonusFastest[MAX_STYLES][MAXZONEGROUPS][MAX_NAME_LENGTH];
char g_szStyleBonusFastestTime[MAX_STYLES][MAXZONEGROUPS][64];
float g_fStylePersonalRecordBonus[MAX_STYLES][MAXZONEGROUPS][MAXPLAYERS + 1];
char g_szStylePersonalRecordBonus[MAX_STYLES][MAXZONEGROUPS][MAXPLAYERS + 1][64];
float g_fStyleBonusFastest[MAX_STYLES][MAXZONEGROUPS];
float g_fStyleOldBonusRecordTime[MAX_STYLES][MAXZONEGROUPS];
int g_StyleMapRankBonus[MAX_STYLES][MAXZONEGROUPS][MAXPLAYERS + 1];
int g_StyleOldMapRankBonus[MAX_STYLES][MAXZONEGROUPS][MAXPLAYERS + 1];
int g_StyletmpBonusCount[MAX_STYLES][MAXZONEGROUPS];
int g_iStyleBonusCount[MAX_STYLES][MAXZONEGROUPS];

// WRCP Styles
float g_fStyleStageRecord[MAX_STYLES][CPLIMIT];
int g_StyleStageRank[MAX_STYLES][MAXPLAYERS + 1][CPLIMIT];
int g_TotalStageStyleRecords[MAX_STYLES][CPLIMIT];
char g_szStyleStageRecordPlayer[MAX_STYLES][MAX_NAME_LENGTH][CPLIMIT];
char g_szStyleRecordStageTime[MAX_STYLES][CPLIMIT];
int g_StyleStageSelect[MAXPLAYERS + 1];

// Style Profiles
int g_ProfileStyleSelect[MAXPLAYERS + 1];
//int g_totalStyleMapTimes[MAXPLAYERS + 1];

/*----------  Player Settings  ----------*/
bool g_bTimerEnabled[MAXPLAYERS + 1];
int g_SpeedGradient[MAXPLAYERS + 1];
int g_SpeedMode[MAXPLAYERS + 1];
bool g_bCenterSpeedDisplay[MAXPLAYERS + 1];
int g_iCenterSpeedEnt[MAXPLAYERS + 1];
int g_iSettingToLoad[MAXPLAYERS + 1];
int g_iPreviousSpeed[MAXPLAYERS + 1];

/*----------  Sounds  ----------*/
bool g_bTop10Time[MAXPLAYERS + 1] = {false, ...};

// Rate Limiting Commands
float g_fCommandLastUsed[MAXPLAYERS + 1];
bool g_bRateLimit[MAXPLAYERS + 1];

// MRank Command
char g_szRuntimepro[MAXPLAYERS + 1][32];
int g_totalPlayerTimes[MAXPLAYERS + 1];

// Rank Command
int g_rankArg[MAXPLAYERS + 1];

/*----------  KSF Style Ranking Distribution  ----------*/
char g_szRankName[MAXPLAYERS + 1][32];
//int g_rankNameChatColour[MAXPLAYERS + 1];
int g_GroupMaps[MAX_PR_PLAYERS + 1][MAX_STYLES];
int g_Top10Maps[MAX_PR_PLAYERS + 1][MAX_STYLES];

// 0 = wr, 1 = wrb, 2 = wrcp
int g_WRs[MAX_PR_PLAYERS + 1][MAX_STYLES][3];

// 0 = Map Points, 1 = Bonus Points, 2 = Group Points, 3 = Map WR Points, 4 = Bonus WR Points, 5 = Top 10 Points, 6 = WRCP Points
int g_Points[MAX_PR_PLAYERS + 1][MAX_STYLES][7];

int g_ClientProfile[MAXPLAYERS + 1];
bool g_bProfileInServer[MAXPLAYERS + 1];
bool g_bInBonus[MAXPLAYERS + 1];
int g_iInBonus[MAXPLAYERS + 1];

/*----------  KSF Points System  ----------*/
float g_Group1Pc = 0.03125;
float g_Group2Pc = 0.0625;
float g_Group3Pc = 0.125;
float g_Group4Pc = 0.25;
float g_Group5Pc = 0.5;
char g_szMiMapName[MAXPLAYERS + 1][128];
int g_MiType[MAXPLAYERS + 1];
int g_G1Top;
int g_G2Bot;
int g_G2Top;
int g_G3Bot;
int g_G3Top;
int g_G4Bot;
int g_G4Top;
int g_G5Bot;
int g_G5Top;
bool g_bInsertNewTime = false;

/*----------  fluffys tmf & repeat  ----------*/
bool g_bToggleMapFinish[MAXPLAYERS + 1] = {true, ...};
bool g_bRepeat[MAXPLAYERS + 1] = {false, ...};
bool g_bNotTeleporting[MAXPLAYERS + 1] = {true, ...};

// Client Side Autobhop
Handle g_hAutoBhop = INVALID_HANDLE;
Handle g_hEnableBhop = INVALID_HANDLE;

/*----------  Flag Varibles  ----------*/
// ConVar g_hCustomTitlesFlag = null;
// int g_CustomTitlesFlag;
// bool g_bCustomTitlesFlag;

// UNIX Times
int g_iPlayTimeAlive[MAXPLAYERS + 1];
int g_iPlayTimeSpec[MAXPLAYERS + 1];
int g_iPlayTimeAliveSession[MAXPLAYERS + 1];
int g_iPlayTimeSpecSession[MAXPLAYERS + 1];
int g_iTotalConnections[MAXPLAYERS + 1];

Menu g_mTriggerMultipleMenu = null;

// Editing Zones

// If editing zone type
bool g_bEditZoneType[MAXPLAYERS + 1];

// Selected zone's name
char g_CurrentZoneName[MAXPLAYERS + 1][64];

// Selected zone's position
float g_Positions[MAXPLAYERS + 1][2][3];

// Bonus start zone position
float g_fBonusStartPos[MAXPLAYERS + 1][2][3];

// Bonus end zone positions
float g_fBonusEndPos[MAXPLAYERS + 1][2][3];

// Scaling options
float g_AvaliableScales[5] = { 1.0, 5.0, 10.0, 50.0, 100.0 };

// Currently selected zonegroup
int g_CurrentSelectedZoneGroup[MAXPLAYERS + 1];

// Current zone team TODO: Remove
int g_CurrentZoneTeam[MAXPLAYERS + 1];

// Current zone visibility per team TODO: Remove
int g_CurrentZoneVis[MAXPLAYERS + 1];

// Currenyly selected zone's type
int g_CurrentZoneType[MAXPLAYERS + 1];

// What state of editing is happening eg. editing, creating etc.
int g_Editing[MAXPLAYERS + 1];

// Currently selected zone id
int g_ClientSelectedZone[MAXPLAYERS + 1] = { -1, ... };

// Currently selected scale
int g_ClientSelectedScale[MAXPLAYERS + 1];

// Currently selected point
int g_ClientSelectedPoint[MAXPLAYERS + 1];

// Currently selected zone's type ID
int g_CurrentZoneTypeId[MAXPLAYERS + 1];

// Is client renaming zone?
bool g_ClientRenamingZone[MAXPLAYERS + 1];

// Zone team colors TODO: remove
int beamColorT[] = { 255, 0, 0, 255 };
int beamColorCT[] = { 0, 0, 255, 255 };
int beamColorN[] = { 255, 255, 0, 255 };
int beamColorM[] = { 0, 255, 0, 255 };

// Zone Default Names
char g_szZoneDefaultNames[ZONEAMOUNT][128] = { "Stop", "Start", "End", "Stage", "Checkpoint", "SpeedStart", "TeleToStart", "Validator", "Checker", "AntiJump", "AntiDuck", "MaxSpeed" };

// Zone sprites
int g_BeamSprite;
int g_HaloSprite;

/*----------  Forwards  ----------*/
GlobalForward g_MapFinishForward;
GlobalForward g_MapCheckpointForward;
GlobalForward g_BonusFinishForward;
GlobalForward g_PracticeFinishForward;
GlobalForward g_NewRecordForward;
GlobalForward g_NewWRCPForward;

/*----------  SQL Variables  ----------*/

// SQL driver
Handle g_hDb = null;

// Database type
int g_DbType;

// Used to check if SQL changes are being made
bool g_bInTransactionChain = false;

// Used to track failed transactions when making database changes
int g_failedTransactions[7];

// Used to track if sql tables are being renamed
bool g_bRenaming = false;

// Used to track if a players settings have been loaded
bool g_bSettingsLoaded[MAXPLAYERS + 1];

// Used to track if players settings are being loaded
bool g_bLoadingSettings[MAXPLAYERS + 1];

// Are the servers settings loaded
bool g_bServerDataLoaded;

// SteamdID of #1 player in map, used to fetch checkpoint times
char g_szRecordMapSteamID[MAX_NAME_LENGTH];
//int g_iServerHibernationValue;

/*----------  User Commands  ----------*/

// Throttle !usp command
float g_flastClientUsp[MAXPLAYERS + 1];

// Throttle !back to prevent desync on record bots
float g_fLastCommandBack[MAXPLAYERS + 1];

// Client is noclipping
bool g_bNoClip[MAXPLAYERS + 1];

/*----------  User Options  ----------*/

// bool to ensure the modules have loaded before resetting
bool g_bLoadedModules[MAXPLAYERS + 1];

// Hides chat
bool g_bHideChat[MAXPLAYERS + 1];

// Hides viewmodel
bool g_bViewModel[MAXPLAYERS + 1];

// Command to disable checkpoints
bool g_bCheckpointsEnabled[MAXPLAYERS + 1];

// Did client enable checkpoints? Then start using them again on the next run
bool g_bActivateCheckpointsOnStart[MAXPLAYERS + 1];

// Enable quake sounds?
bool g_bEnableQuakeSounds[MAXPLAYERS + 1];

// Hide other players?
bool g_bHide[MAXPLAYERS + 1];

// Show spectator list?
bool g_bShowSpecs[MAXPLAYERS + 1];

// Client autobhop?
bool g_bAutoBhopClient[MAXPLAYERS + 1];

// centre hud new
bool g_bCentreHud[MAXPLAYERS + 1];
int g_iCentreHudModule[MAXPLAYERS + 1][6];

// side hud new
bool g_bSpecListOnly[MAXPLAYERS + 1];
bool g_bSideHud[MAXPLAYERS + 1];
int g_iSideHudModule[MAXPLAYERS + 1][5];

// Custom tele side
int g_iTeleSide[MAXPLAYERS + 1];

// Prestrafe Message
bool g_iPrespeedText[MAXPLAYERS + 1];

// Silent Spectate
bool g_iSilentSpectate[MAXPLAYERS + 1];

// CP Messages
bool g_iCpMessages[MAXPLAYERS + 1];

// WRCP Messages
bool g_iWrcpMessages[MAXPLAYERS + 1];

// trails chroma stuff
bool g_iHasEnforcedTitle[MAXPLAYERS + 1];

// disable noclip triggers toggle
bool g_iDisableTriggers[MAXPLAYERS + 1];

// auto reset
bool g_iAutoReset[MAXPLAYERS + 1];

/*----------  Run Variables  ----------*/

// Clients personal record in map
float g_fPersonalRecord[MAXPLAYERS + 1];

// Is clients timer running
bool g_bTimerRunning[MAXPLAYERS + 1];

// Used to check if a clients run is valid in validator and checker zones
bool g_bValidRun[MAXPLAYERS + 1];

// First bonus time in map?
bool g_bBonusFirstRecord[MAXPLAYERS + 1];

// Personal best time in bonus
bool g_bBonusPBRecord[MAXPLAYERS + 1];

// New server record in bonus
bool g_bBonusSRVRecord[MAXPLAYERS + 1];

// How many seconds were improved / lost in that run
char g_szBonusTimeDifference[MAXPLAYERS + 1];

// Time when run was started
float g_fStartTime[MAXPLAYERS + 1];

// Time when PracMode run was started
float g_fPracModeStartTime[MAXPLAYERS + 1];

// Total time the run took
float g_fFinalTime[MAXPLAYERS + 1];

// Total time the run took in 00:00:00 format
char g_szFinalTime[MAXPLAYERS + 1][32];

// Time spent in !pause this run
float g_fPauseTime[MAXPLAYERS + 1];

// Time when !pause started
float g_fStartPauseTime[MAXPLAYERS + 1];

// Current runtime
float g_fCurrentRunTime[MAXPLAYERS + 1];

// PracticeMode total time the run took in 00:00:00 format
char g_szPracticeTime[MAXPLAYERS + 1][32];

// Missed personal record time?
bool g_bMissedMapBest[MAXPLAYERS + 1];

// Was players run his first time finishing the map?
bool g_bMapFirstRecord[MAXPLAYERS + 1];

// Was players run his personal best?
bool g_bMapPBRecord[MAXPLAYERS + 1];

// Was players run the new server record?
bool g_bMapSRVRecord[MAXPLAYERS + 1];

// Used to print the client's new times difference to record
char g_szTimeDifference[MAXPLAYERS + 1][32];

// Record map time in seconds
float g_fRecordMapTime;

// Old map record time in seconds
float g_fOldRecordMapTime;

// Record map time in 00:00:00 format
char g_szRecordMapTime[64];

// Client's peronal record in 00:00:00 format
char g_szPersonalRecord[MAXPLAYERS + 1][64];

// Average map time
float g_favg_maptime;

// Average bonus times TODO: Combine with g_favg_maptime
float g_fAvg_BonusTime[MAXZONEGROUPS];

// If timer is started for the first time, print avg times
bool g_bFirstTimerStart[MAXPLAYERS + 1];

// Client has timer paused
bool g_bPause[MAXPLAYERS + 1];

// How many times the map has been beaten
int g_MapTimesCount;

// Clients rank in current map
int g_MapRank[MAXPLAYERS + 1];

// Clients old rank
int g_OldMapRank[MAXPLAYERS + 1];

// Current map's record player's name
char g_szRecordPlayer[MAX_NAME_LENGTH];

// Latest prestrafe speed for linear and stage map
int g_iPreStrafe[3][CPLIMIT][MAX_STYLES][MAXPLAYERS + 1];

// Latest prestrafe speed for bonuses
int g_iPreStrafeBonus[3][MAXZONEGROUPS][MAX_STYLES][MAXPLAYERS + 1];

/*----------  Replay Variables  ----------*/

// Checks if the bot is new, if so, set weapon
bool g_bNewRecordBot;

// Checks if the bot is new, if so, set weapon
bool g_bNewBonusBot;

// Used to track teleportations
Handle g_hTeleport = null;

// Client is being recorded
ArrayList g_aRecording[MAXPLAYERS + 1];

// Fix for trigger_push affecting bots
StringMap g_smLoadedRecordsAdditionalTeleport = null;

// Bot replay frame
ArrayList g_aReplayFrame[MAXPLAYERS + 1] = { null, ... };

// Bot replay version
int g_iReplayVersion[MAXPLAYERS + 1] = { 0x01, ...};

// Timer to refresh bot trails
Handle g_hBotTrail[2] = { null, null };

// Replay start position
float g_fInitialPosition[MAXPLAYERS + 1][3];

// Replay start angle
float g_fInitialAngles[MAXPLAYERS + 1][3];

// Is teleport valid?
bool g_bValidTeleportCall[MAXPLAYERS + 1];

// Don't allow starting a new run if saving a record run
bool g_bNewReplay[MAXPLAYERS + 1];
bool g_bNewBonus[MAXPLAYERS + 1];

// Old replay teleport destination
int g_CurrentAdditionalTeleportIndex[MAXPLAYERS + 1];

// Player's frame
int g_iRecordedTicks[MAXPLAYERS + 1];

// Amount of Player's frame
int g_iRecordedTicksCount[MAXPLAYERS + 1];

// Replay bot's frame
int g_iReplayTick[MAXPLAYERS + 1];

// Stage replays stuff
int g_iStageStartFrame[MAXPLAYERS+1];
bool g_bSavingWrcpReplay[MAXPLAYERS + 1];
int g_StageReplayCurrentStage;
int g_StageReplaysLoop;
bool g_bStageReplay[CPLIMIT];
bool g_bFirstStageReplay;
float g_fStageReplayTimes[CPLIMIT];

// Record bot client ID
int g_RecordBot = -1;

// Bonus bot client ID
int g_BonusBot = -1;

// Info bot client ID
int g_InfoBot = -1;

// WRCP bot client ID
int g_WrcpBot = -1;

// Replay is at the end
bool g_bReplayAtEnd[MAXPLAYERS + 1];

// Make replay stand still for long enough for trail to die
float g_fReplayRestarted[MAXPLAYERS + 1];

// Replay bot name
char g_szReplayName[128];

// Replay bot time
char g_szReplayTime[128];

// Replay bot name
char g_szBonusName[128];

// Replay bot time
char g_szBonusTime[128];

char g_szWrcpReplayName[CPLIMIT][128];
char g_szWrcpReplayTime[CPLIMIT][128];
int g_BonusBotCount;
int g_iCurrentBonusReplayIndex;
int g_iBonusToReplay[MAXZONEGROUPS + 1];
float g_fReplayTimes[MAXZONEGROUPS][MAX_STYLES];
int g_iManualBonusToReplay;
int g_iCurrentlyPlayingStage;

/*----------  Misc  ----------*/

// Used to load all the hints
ArrayList g_aHints;

// Last hint number
int g_iLastHintNumber = -1;

// Allow hints
bool g_bAllowHints[MAXPLAYERS + 1];

// Used to load the mapcycle
Handle g_MapList = null;

// Used to check if a player just joined the server
float g_fMapStartTime;

// Array that holds SkillGroup objects in it
Handle g_hSkillGroups = null;

// Used to limit error message spam too often
float g_fErrorMessage[MAXPLAYERS + 1];

// Used to track the time the player took to write the second !r, if too long, reset the boolean
float g_fClientRestarting[MAXPLAYERS + 1];

// Client wanted to restart run
bool g_bClientRestarting[MAXPLAYERS + 1];

// Last time the client used noclip
float g_fLastTimeNoClipUsed[MAXPLAYERS + 1];

// Does client have a respawn location in memory?
bool g_bRespawnPosition[MAXPLAYERS + 1];

// Client's last speed, used in panels
float g_fLastSpeed[MAXPLAYERS + 1];

// Was plugin loaded late?
bool g_bLateLoaded = false;

// Known mapchooser loaded? Used to update info bot
bool g_bMapChooser;

// If call admin, ignore chat message
bool g_bClientOwnReason[MAXPLAYERS + 1];

// Has client used noclip to gain current speed
bool g_bNoClipUsed[MAXPLAYERS + 1];

// Map finished overlay
bool g_bOverlay[MAXPLAYERS + 1];

// Is client spectating
bool g_bSpectate[MAXPLAYERS + 1];

// First time client joined game, show start messages & start timers
bool g_bFirstTeamJoin[MAXPLAYERS + 1];

// First time client spawned
bool g_bFirstSpawn[MAXPLAYERS + 1];
bool g_bSelectProfile[MAXPLAYERS + 1];

// Is client teleporting from spectate?
bool g_specToStage[MAXPLAYERS + 1];

// Location where client is spawned from spectate
float g_fTeleLocation[MAXPLAYERS + 1][3];

// Server tickrate
int g_iTickrate;
float g_fTickrate;

// Who the client is spectating?
int g_SpecTarget[MAXPLAYERS + 1];

// Buttons the client is using, used to show them when specating
int g_LastButton[MAXPLAYERS + 1];

// The amount of MVP's a client has  TODO: make sure this is used everywhere
int g_MVPStars[MAXPLAYERS + 1];

// What color is client's name in chat (based on rank)
int g_PlayerChatRank[MAXPLAYERS + 1];

// Clients rank, colored, used in chat
char g_pr_chat_coloredrank[MAXPLAYERS + 1][256];
char g_pr_chat_coloredrank_style[MAXPLAYERS + 1][256];

// Client's rank, non-colored, used in clantag
char g_pr_rankname_style[MAXPLAYERS + 1][32];
char g_pr_rankname[MAXPLAYERS + 1][32];
char g_pr_namecolour[MAXPLAYERS + 1][32];

// Map's prefix, used to execute prefix cfg's
char g_szMapPrefix[2][32];

// Current map's name
char g_szMapName[128];

// Info panel text when spectating
char g_szPlayerPanelText[MAXPLAYERS + 1][512];

// Country codes
char g_szCountry[MAXPLAYERS + 1][100];
char g_szCountryCode[MAXPLAYERS + 1][16];

// Client's steamID
char g_szSteamID[MAXPLAYERS + 1][32];

// Blocked chat commands
char g_BlockedChatText[256][256];

// Last time an overlay was displayed
float g_fLastOverlay[MAXPLAYERS + 1];

// Is client trying to teleport inside a trigger_multiple
//bool g_TeleInTriggerMultiple[MAXPLAYERS + 1];
bool g_bTeleByCommand[MAXPLAYERS + 1];

/*----------  Player location restoring  ----------*/

// Clients location was restored this run
bool g_bPositionRestored[MAXPLAYERS + 1];

// Show client restore message?
bool g_bRestorePositionMsg[MAXPLAYERS + 1];

// Clients position is being restored
bool g_bRestorePosition[MAXPLAYERS + 1];

// Client's last location, used on recovering run and coming back from spectate
float g_fPlayerCordsLastPosition[MAXPLAYERS + 1][3];

// Client's last time, used on recovering run and coming back from spec
float g_fPlayerLastTime[MAXPLAYERS + 1];

// Client's last angles, used on recovering run and coming back from spec
float g_fPlayerAnglesLastPosition[MAXPLAYERS + 1][3];

// Used in restoring players location
float g_fPlayerCordsRestore[MAXPLAYERS + 1][3];

// Used in restoring players angle
float g_fPlayerAnglesRestore[MAXPLAYERS + 1][3];

// Last time profile was queried by player, spam protection
float g_fProfileMenuLastQuery[MAXPLAYERS + 1];

// Tracking menu level
int g_MenuLevel[MAXPLAYERS + 1];

// Client's rank string displayed in !profile
char g_pr_szrank[MAXPLAYERS + 1][512];

// !Profile name
char g_szProfileName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_szProfileSteamId[MAXPLAYERS + 1][32];

// Admin flag required for !ckadmin
int g_AdminMenuFlag;
ConVar g_hAdminMenuFlag = null;

// Add !ckadmin to !admin
Handle g_hAdminMenu = null;

// Weird admin menu trickery TODO: wtf
int g_AdminMenuLastPage[MAXPLAYERS + 1];

/*----------  Player Points  ----------*/

// % of maps the client has finished
float g_pr_finishedmaps_perc[MAX_PR_PLAYERS + 1][MAX_STYLES];

// Is point recalculation in progress?
bool g_pr_RankingRecalc_InProgress;

// Clients points are being calculated
bool g_pr_Calculating[MAXPLAYERS + 1];

// Has this profile been recalculated?
bool g_bProfileRecalc[MAX_PR_PLAYERS + 1];

// Point recalculation type
bool g_bManualRecalc;

// Print the amount of gained points to chat?
bool g_pr_showmsg[MAXPLAYERS + 1];

// Is clients points being recalculated?
bool g_bRecalcRankInProgess[MAXPLAYERS + 1];

// Client ID being recalculated
int g_pr_Recalc_ClientID = 0;

// ClientID that started the recalculation
int g_pr_Recalc_AdminID = -1;

// Ranked player count on server
int g_pr_AllPlayers[MAX_STYLES];

// Player count with points
int g_pr_RankedPlayers[MAX_STYLES];

// Total map count in mapcycle
int g_pr_MapCount[9];

// The amount of clients that get recalculated in a full recalculation
int g_pr_TableRowCount;

// Clients points
int g_pr_points[MAX_PR_PLAYERS + 1][MAX_STYLES];

// Clients points before recalculation
int g_pr_oldpoints[MAX_PR_PLAYERS + 1][MAX_STYLES];

// How many maps a client has finished
int g_pr_finishedmaps[MAX_PR_PLAYERS + 1][MAX_STYLES];

// How many bonuses a client has finished
int g_pr_finishedbonuses[MAX_PR_PLAYERS + 1][MAX_STYLES];

// How many stages a client has finished
int g_pr_finishedstages[MAX_PR_PLAYERS + 1][MAX_STYLES];

// Players server rank
int g_PlayerRank[MAXPLAYERS + 1][MAX_STYLES];

// Used to update client's name in database
char g_pr_szName[MAX_PR_PLAYERS + 1][64];

// steamid of client being recalculated
char g_pr_szSteamID[MAX_PR_PLAYERS + 1][32];

/*----------  Practice Mode  ----------*/

// Client has created atleast one checkpoint
bool g_bCreatedTeleport[MAXPLAYERS + 1];

// Client is in the practice mode
bool g_bPracticeMode[MAXPLAYERS + 1];

/*----------  Reports  ----------*/
bool g_bReportSuccess[MAXPLAYERS + 1];

// old challenge variables might need just incase
float g_fSpawnPosition[MAXPLAYERS + 1][3];

// Chat Colors in String Format
char szWHITE[12], szDARKRED[12], szPURPLE[12], szGREEN[12], szLIGHTGREEN[12], szLIMEGREEN[12], szRED[12], szGRAY[12], szYELLOW[12], szDARKGREY[12], szBLUE[12], szDARKBLUE[12], szLIGHTBLUE[12], szPINK[12], szLIGHTRED[12], szORANGE[12];

// hook zones
Handle g_hTriggerMultiple;
int g_iTeleportingZoneId[MAXPLAYERS + 1];
int g_iZonegroupHook[MAXPLAYERS + 1];
int g_iSelectedTrigger[MAXPLAYERS + 1];

// Store
int g_iMapTier;
bool g_bRankedMap;

// Late Load Linux fix
Handle g_cvar_sv_hibernate_when_empty = INVALID_HANDLE;

// Fix prehopping in zones
bool g_bJumpedInZone[MAXPLAYERS + 1];
float g_fJumpedInZoneTime[MAXPLAYERS + 1];
bool g_bResetOneJump[MAXPLAYERS + 1];

// Server Announcements
int g_iServerID;
int g_iLastID;
bool g_bHasLatestID;

// Show Triggers https://forums.alliedmods.net/showthread.php?t=290356
int g_iTriggerTransmitCount;
bool g_bShowTriggers[MAXPLAYERS + 1];
int g_Offset_m_fEffects = -1;

/*----------  !startpos Goose  ----------*/
float g_fStartposLocation[MAXPLAYERS + 1][MAXZONEGROUPS][3];
float g_fStartposAngle[MAXPLAYERS + 1][MAXZONEGROUPS][3];
bool g_bStartposUsed[MAXPLAYERS + 1][MAXZONEGROUPS];

// Strafe Sync (Taken from shavit's bhop timer)
int g_iGoodGains[MAXPLAYERS + 1];
int g_iTotalMeasures[MAXPLAYERS + 1];
float g_fAngleCache[MAXPLAYERS + 1];

// Save locs
int g_iSaveLocCount[MAXPLAYERS + 1];
float g_fSaveLocCoords[MAXPLAYERS + 1][MAX_LOCS][3]; // [loc id][coords]
float g_fSaveLocAngle[MAXPLAYERS + 1][MAX_LOCS][3]; // [loc id][angle]
float g_fSaveLocVel[MAXPLAYERS + 1][MAX_LOCS][3]; // [loc id][velocity]
char g_szSaveLocTargetname[MAX_LOCS][128]; // [loc id]
char g_szSaveLocClientName[MAXPLAYERS + 1][MAX_LOCS][MAX_NAME_LENGTH];
int g_iLastSaveLocIdClient[MAXPLAYERS + 1];
float g_fLastCheckpointMade[MAXPLAYERS + 1];
int g_iSaveLocUnix[MAX_LOCS][MAXPLAYERS + 1]; // [loc id]
int g_iMenuPosition[MAXPLAYERS + 1];
int g_iPreviousSaveLocIdClient[MAXPLAYERS + 1]; // The previous saveloc the client used
float g_fPlayerPracTimeSnap[MAXPLAYERS + 1][MAX_LOCS]; // PracticeMode saveloc runtime
int g_iPlayerPracLocationSnap[MAXPLAYERS + 1][MAX_LOCS]; // Stage the player was in when creating saveloc
int g_iPlayerPracLocationSnapIdClient[MAXPLAYERS + 1]; // Stage Index to use when tele to saveloc
bool g_bSaveLocTele[MAXPLAYERS + 1]; // Has the player teleported to saveloc?
int g_iSaveLocInBonus[MAXPLAYERS + 1][MAX_LOCS]; // Bonus number if player created saveloc in bonus
float g_fPlayerPracSrcpTimeSnap[MAXPLAYERS + 1][MAX_LOCS]; // PracticeMode Wrcp saveloc runtime
int g_iAllowCheckpointRecreation; // Int for allowCheckpointRecreation convar

char g_sServerName[256];
ConVar g_hHostName = null;

// Teleport Destinations
Handle g_hDestinations;

// CPR command
float g_fClientCPs[MAXPLAYERS + 1][36];
float g_fTargetTime[MAXPLAYERS + 1];
char g_szTargetCPR[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_szCPRMapName[MAXPLAYERS + 1][128];

// surf_christmas2
bool g_bUsingStageTeleport[MAXPLAYERS + 1];

// Footsteps
ConVar g_hFootsteps = null;

// Enforced Titles
bool g_bEnforceTitle[MAXPLAYERS + 1];
int g_iEnforceTitleType[MAXPLAYERS + 1];
char g_szEnforcedTitle[MAXPLAYERS + 1][256];
Handle g_DefaultTitlesWhitelist = null;

// Prespeed in zones
ResponseType g_iWaitingForResponse[MAXPLAYERS + 1];

// Trigger List so we can store the names of the triggers before we rename them
Handle g_TriggerMultipleList;

// Chat Prefix
char g_szChatPrefix[64];
char g_szMenuPrefix[64];
ConVar g_hChatPrefix = null;

// Play Replay command
bool g_bManualReplayPlayback;
bool g_bManualBonusReplayPlayback;
bool g_bManualStageReplayPlayback;
int g_iManualReplayCount;
int g_iManualBonusReplayCount;
int g_iManualStageReplayCount;
int g_iSelectedReplayType;
int g_iSelectedReplayBonus;
int g_iSelectedReplayStage;
int g_iSelectedReplayStyle;
int g_iSelectedBonusReplayStyle;

/* Admin delete menu */

char g_EditingMap[MAXPLAYERS + 1][256];
int g_SelectedEditOption[MAXPLAYERS + 1];
int g_SelectedStyle[MAXPLAYERS + 1];
int g_SelectedType[MAXPLAYERS + 1];

char g_EditTypes[][] =  { "Main", "Stage", "Bonus" };
char g_EditStyles[][] =  { "Normal", "Sideways", "Half-Sideways", "Backwards", "Low-Gravity", "Slow Motion", "Fast Forward", "Freestyle" };

// Checkpoint/Stage enforcer
int g_iTotalCheckpoints;
int g_iCheckpointsPassed[MAXPLAYERS + 1];
bool g_bIsValidRun[MAXPLAYERS + 1];

// Prestige
bool g_bPrestigeCheck[MAXPLAYERS + 1];
bool g_bPrestigeAvoid[MAXPLAYERS + 1];

// Menus mapname
char g_szMapNameFromDatabase[MAXPLAYERS + 1][128];

// New noclipspeed vars
ConVar sv_noclipspeed;
float g_iDefaultNoclipSpeed;
float g_iNoclipSpeed[MAXPLAYERS + 1];

// New speed limit variables
bool g_bInBhop[MAXPLAYERS + 1];
bool g_bFirstJump[MAXPLAYERS + 1];
float g_iLastJump[MAXPLAYERS + 1];
int g_iTicksOnGround[MAXPLAYERS + 1];
bool g_bNewStage[MAXPLAYERS + 1];
bool g_bLeftZone[MAXPLAYERS + 1];

int g_iClientTick[MAXPLAYERS + 1];

/*===================================
=         Predefined Arrays         =
===================================*/

char g_sz10000mvGradient[][] =
{
	"#FFFFFF",
	"#F4FFF4",
	"#E9FFE9",
	"#DFFFDF",
	"#D4FFD4",
	"#C9FFC9",
	"#BFFFBF",
	"#B4FFB4",
	"#AAFFAA",
	"#9FFF9F",
	"#94FF94",
	"#8AFF8A",
	"#7FFF7F",
	"#74FF74",
	"#74FF74",
	"#5FFF5F",
	"#55FF55",
	"#4AFF4A",
	"#3FFF3F",
	"#35FF35",
	"#2AFF2A",
	"#1FFF1F",
	"#15FF15",
	"#0AFF0A",
	"#00FF00"
};

char g_sz3500mvGradient[][] =
{
	"#FFFFFF",
	"#F7FFF7",
	"#F0FFF0",
	"#E8FFE8",
	"#E1FFE1",
	"#D9FFD9",
	"#D2FFD2",
	"#CAFFCA",
	"#C3FFC3",
	"#BBFFBB",
	"#B4FFB4",
	"#ACFFAC",
	"#A5FFA5",
	"#9DFF9D",
	"#96FF96",
	"#8EFF8E",
	"#87FF87",
	"#7FFF7F",
	"#78FF78",
	"#70FF70",
	"#69FF69",
	"#61FF61",
	"#5AFF5A",
	"#52FF52",
	"#4BFF4B",
	"#43FF43",
	"#3CFF3C",
	"#34FF34",
	"#2DFF2D",
	"#25FF25",
	"#1EFF1E",
	"#16FF16",
	"#0FFF0F",
	"#07FF07",
	"#00FF00"
};

char g_szRainbowGradient[][] =
{
	"#FFFFFF",
	"#FFD4F0",
	"#e2aaff",
	"#e38be6",
	"#7f7fff",
	"#55c6ff",
	"#2affb8",
	"#00ff00"
};

char UnallowedTitles[][] =
{
	"NEWBIE",
	"LEARNING",
	"NOVICE",
	"BEGINNER",
	"ROOKIE",
	"AVERAGE",
	"CASUAL",
	"ADVANCED",
	"SKILLED",
	"EXCEPTIONAL",
	"AMAZING",
	"PRO",
	"VETERAN",
	"EXPERT",
	"ELITE",
	"MASTER",
	"LEGENDARY",
	"GODLY",
	"KING",
	"ADMIN",
	"ADMLN",
	"HEAD ADMIN",
	"HEADADMIN",
	"MODERATOR",
	"M0DERATOR",
	"M0DERAT0R",
	"MODERAT0R",
	"OWNER",
	"0WNER",
	"ZTS",
	"MOD",
	"M0D",
	"CKSURF",
	"STAFF",
	"BIGDICKCLUB",
	"BIG DICK CLUB",
	"BIGDICK CLUB",
	"BIG DICKCLUB",
	"B DC",
	"BD C",
	"B D C",
	"VIP",
	"SUPER VIP"
};

char g_szStyleRecordPrint[][] =
{
	"",
	"* Sideways *",
	"* Half-Sideways *",
	"* Backwards *",
	"* Low-Gravity *",
	"* Slow Motion *",
	"* Fast Forward *",
	"* Freestyle *"
};

char g_szStyleMenuPrint[][] =
{
	"",
	"Sideways",
	"Half-Sideways",
	"Backwards",
	"Low-Gravity",
	"Slow Motion",
	"Fast Forward",
	"Freestyle"
};

char g_szStyleAcronyms[][] =
{
	"n",
	"sw",
	"hsw",
	"bw",
	"lg",
	"sm",
	"ff",
	"fs"
};

char RadioCMDS[][] =  // Disable radio commands
{
	"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog",
	"getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition",
	"reportingin", "getout", "negative", "enemydown", "cheer", "thanks", "nice", "compliment", "go_a",
	"go_b", "sorry", "needrop", "playerradio", "playerchatwheel", "chatwheel_ping", "player_ping"
};

/*======  End of Declarations  ======*/

/*====================================
=              Includes              =
====================================*/

#include "surftimer/api.sp"
#include "surftimer/convars.sp"
#include "surftimer/misc.sp"
#include "surftimer/db/queries.sp"
#include "surftimer/sql.sp"
#include "surftimer/admin.sp"
#include "surftimer/newmaps.sp"
#include "surftimer/commands.sp"
#include "surftimer/hooks.sp"
#include "surftimer/buttonpress.sp"
#include "surftimer/sqltime.sp"
#include "surftimer/timer.sp"
#include "surftimer/replay.sp"
#include "surftimer/surfzones.sp"
#include "surftimer/mapsettings.sp"
#include "surftimer/cvote.sp"
#include "surftimer/vip.sp"

/*====================================
=               Events               =
====================================*/

public void OnLibraryAdded(const char[] name)
{
	Handle tmp = FindPluginByFile("mapchooser_extended.smx");
	if ((StrEqual("mapchooser", name)) || (tmp != null && GetPluginStatus(tmp) == Plugin_Running))
		g_bMapChooser = true;
	if (tmp != null)
		CloseHandle(tmp);

	// botmimic 2
	if (StrEqual(name, "dhooks") && g_hTeleport == null)
	{
		// Optionally setup a hook on CBaseEntity::Teleport to keep track of sudden place changes
		Handle hGameData = LoadGameConfigFile("sdktools.games");
		if (hGameData == null)
			return;
		int iOffset = GameConfGetOffset(hGameData, "Teleport");
		CloseHandle(hGameData);
		if (iOffset == -1)
			return;

		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if (g_hTeleport == null)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		if (GetEngineVersion() == Engine_CSGO)
			DHookAddParam(g_hTeleport, HookParamType_Bool);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("endtouchfix"))
	{
		SetFailState("Plugin \"End-Touch-Fix\" not loaded!");
		return;
	}
}

public void OnPluginEnd()
{
	// remove clan tags
	for (int x = 1; x <= MaxClients; x++)
	{
		if (IsValidClient(x))
		{
			SetEntPropEnt(x, Prop_Send, "m_bSpotted", 1);
			SetEntProp(x, Prop_Send, "m_iHideHUD", 0);
			SetEntProp(x, Prop_Send, "m_iAccount", 1);
			if (g_hOverrideClantag.BoolValue)
				CS_SetClientClanTag(x, "");
			OnClientDisconnect(x);
		}
	}


	// set server convars back to default
	ServerCommand("sm_cvar sv_enablebunnyhopping 0;sv_friction 5.2;sv_accelerate 5.5;sv_airaccelerate 10;sv_maxvelocity 2000;sv_staminajumpcost .08;sv_staminalandcost .050");
	ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0;mp_respawnwavetime_ct 10.0;mp_respawnwavetime_t 10.0;bot_zombie 0;mp_ignore_round_win_conditions 0");
	ServerCommand("sv_infinite_ammo 0;mp_endmatch_votenextmap 1;mp_do_warmup_period 1;mp_warmuptime 60;mp_match_can_clinch 1;mp_match_end_changelevel 0");
	ServerCommand("mp_match_restart_delay 15;mp_endmatch_votenextleveltime 20;mp_endmatch_votenextmap 1;mp_halftime 0;mp_do_warmup_period 1;mp_maxrounds 0;bot_quota 0");
	ServerCommand("mp_startmoney 800; mp_playercashawards 1; mp_teamcashawards 1");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
		g_hAdminMenu = null;
	if (StrEqual(name, "dhooks"))
		g_hTeleport = null;
}

public void OnEntityCreated(int entity, const char[] classname) {
	if( (classname[0] == 't' ||  classname[0] == 'l') ? (StrEqual(classname, "trigger_teleport", false) ) : false)
	{
		SDKHook(entity, SDKHook_Use, ingnoreTriggers);
		SDKHook(entity, SDKHook_StartTouch, ingnoreTriggers);
		SDKHook(entity, SDKHook_Touch, ingnoreTriggers);
		SDKHook(entity, SDKHook_EndTouch, ingnoreTriggers);
	}
}

public void OnMapStart()
{
	CreateTimer(30.0, EnableJoinMsgs, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);

	// Get mapname
	GetCurrentMap(g_szMapName, 128);

	// Create nav file
	CreateNavFile();

	// Workshop fix
	char mapPieces[6][128];
	int lastPiece = ExplodeString(g_szMapName, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[]));
	Format(g_szMapName, sizeof(g_szMapName), "%s", mapPieces[lastPiece - 1]);

	// Debug Logging
	if (!DirExists("addons/sourcemod/logs/surftimer"))
		CreateDirectory("addons/sourcemod/logs/surftimer", 511);
	BuildPath(Path_SM, g_szLogFile, sizeof(g_szLogFile), "logs/surftimer/%s.log", g_szMapName);

	// Get map maxvelocity
	g_hMaxVelocity = FindConVar("sv_maxvelocity");

	// Load spawns
	if (!g_bRenaming && !g_bInTransactionChain)
	checkSpawnPoints();

	db_viewMapSettings();


	/// Start Loading Server Settings
	ConVar cvHibernateWhenEmpty = FindConVar("sv_hibernate_when_empty");

	if (!g_bRenaming && !g_bInTransactionChain && (IsServerProcessing() || !cvHibernateWhenEmpty.BoolValue))
	{
		LogToFileEx(g_szLogFile, "[surftimer] Starting to load server settings");
		g_fServerLoading[0] = GetGameTime();
		db_selectMapZones();
	}

	// Get Map Tag
	ExplodeString(g_szMapName, "_", g_szMapPrefix, 2, 32);

	// sv_pure 1 could lead to problems with the ckSurf models
	ServerCommand("sv_pure 0");

	// reload language files
	LoadTranslations("surftimer.phrases");

	CheatFlag("bot_zombie", false, true);
	g_bTierFound = false;
	for (int i = 0; i < MAXZONEGROUPS; i++)
	{
		g_fBonusFastest[i] = 9999999.0;
		g_bCheckpointRecordFound[i] = false;
	}

	// Precache
	InitPrecache();
	SetCashState();

	// Timers
	CreateTimer(0.1, CKTimer1, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(1.0, CKTimer2, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(60.0, AttackTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(600.0, PlayerRanksTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	g_hZoneTimer = CreateTimer(GetConVarFloat(g_hChecker), BeamBoxAll, _, TIMER_REPEAT);

	// AutoBhop
	if (GetConVarBool(g_hAutoBhopConVar))
		g_bAutoBhop = true;
	else
		g_bAutoBhop = false;

	// main.cfg & replays
	CreateTimer(1.0, DelayedStuff, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(GetConVarFloat(g_replayBotDelay), LoadReplaysTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE); // replay bots

	int iEnt;

	// Trigger Gravity Fix
	iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "trigger_gravity")) != -1)
	{
		SDKHook(iEnt, SDKHook_EndTouch, OnEndTouchGravityTrigger);
	}

	// Hook Zones
	iEnt = -1;
	if (g_hTriggerMultiple != null)
		CloseHandle(g_hTriggerMultiple);

	g_hTriggerMultiple = CreateArray(256);
	while ((iEnt = FindEntityByClassname(iEnt, "trigger_multiple")) != -1)
	{
		SDKHook(iEnt, SDKHook_EndTouch, OnMultipleTrigger1);
		SDKHook(iEnt, SDKHook_StartTouch, OnMultipleTrigger1);
		/* SDKHook(iEnt, SDKHook_StartTouch, OnMultipleTrigger2);
		SDKHook(iEnt, SDKHook_EndTouch, OnMultipleTrigger3); */
		HookSingleEntityOutput(iEnt, "OnEndTouch", OnTriggerOutput);
		PushArrayCell(g_hTriggerMultiple, iEnt);
	}

	g_mTriggerMultipleMenu = CreateMenu(HookZonesMenuHandler);
	SetMenuTitle(g_mTriggerMultipleMenu, "Select a trigger");

	for (int i = 0; i < GetArraySize(g_hTriggerMultiple); i++)
	{
		iEnt = GetArrayCell(g_hTriggerMultiple, i);

		if (IsValidEntity(iEnt))
		{
			char szTriggerName[128];
			GetEntPropString(iEnt, Prop_Send, "m_iName", szTriggerName, 128, 0);
			//PushArrayString(g_TriggerMultipleList, szTriggerName);
			AddMenuItem(g_mTriggerMultipleMenu, szTriggerName, szTriggerName);
		}
	}

	SetMenuOptionFlags(g_mTriggerMultipleMenu, MENUFLAG_BUTTON_EXIT);

	// info_teleport_destinations
	iEnt = -1;
	if (g_hDestinations != null)
		CloseHandle(g_hDestinations);

	g_hDestinations = CreateArray(128);
	while ((iEnt = FindEntityByClassname(iEnt, "info_teleport_destination")) != -1)
		PushArrayCell(g_hDestinations, iEnt);

	// Set default values
	g_fMapStartTime = GetGameTime();
	g_bRoundEnd = false;

	// Playtime
	CreateTimer(1.0, PlayTimeTimer, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	// Server Announcements
	g_iServerID = GetConVarInt(g_hServerID);
	if (GetConVarBool(g_hRecordAnnounce))
		CreateTimer(45.0, AnnouncementTimer, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	// Show Triggers
	g_iTriggerTransmitCount = 0;

	// Save Locs
	ResetSaveLocs();
}

public void OnMapEnd()
{

	// ServerCommand("sm_updater_force");
	g_bEnableJoinMsgs = false;
	g_bServerDataLoaded = false;
	g_bHasLatestID = false;
	for (int i = 0; i < MAXZONEGROUPS; i++)
		Format(g_sTierString[i], 512, "");

	g_RecordBot = -1;
	g_BonusBot = -1;
	g_WrcpBot = -1;
	db_Cleanup();

	if (g_hSkillGroups != null)
		CloseHandle(g_hSkillGroups);
	g_hSkillGroups = null;

	if (g_hBotTrail[0] != null)
		CloseHandle(g_hBotTrail[0]);
	g_hBotTrail[0] = null;

	if (g_hBotTrail[1] != null)
		CloseHandle(g_hBotTrail[1]);
	g_hBotTrail[1] = null;

	Format(g_szMapName, sizeof(g_szMapName), "");

	// wrcps
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		g_fWrcpMenuLastQuery[client] = 0.0;
		g_bWrcpTimeractivated[client] = false;
	}

	// Hook Zones
	if (g_hTriggerMultiple != null)
	{
		ClearArray(g_hTriggerMultiple);
		CloseHandle(g_hTriggerMultiple);
	}

	g_hTriggerMultiple = null;
	delete g_hTriggerMultiple;

	CloseHandle(g_mTriggerMultipleMenu);

	if (g_hDestinations != null)
		CloseHandle(g_hDestinations);

	g_hDestinations = null;
}

public void OnConfigsExecuted()
{
	// Get Chat Prefix
	GetConVarString(g_hChatPrefix, g_szChatPrefix, sizeof(g_szChatPrefix));
	GetConVarString(g_hChatPrefix, g_szMenuPrefix, sizeof(g_szMenuPrefix));
	RemoveColors(g_szMenuPrefix, sizeof(g_szMenuPrefix));

	if (GetConVarBool(g_hDBMapcycle))
		db_selectMapCycle();
	else if (!GetConVarBool(g_hMultiServerMapcycle))
		readMapycycle();
	else
		readMultiServerMapcycle();

	if (GetConVarFloat(g_iHintsInterval) != 0.0)
	{
		readHints();
		if (g_aHints.Length != 0)
			CreateTimer(GetConVarFloat(g_iHintsInterval), ShowHintsTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}

	if (GetConVarBool(g_hEnforceDefaultTitles))
		ReadDefaultTitlesWhitelist();

	// Count the amount of bonuses and then set skillgroups
	if (!g_bRenaming && !g_bInTransactionChain)
		db_selectBonusCount();

	ServerCommand("sv_pure 0");

	if (GetConVarBool(g_hAllowRoundEndCvar))
		ServerCommand("mp_ignore_round_win_conditions 0");
	else
		ServerCommand("mp_ignore_round_win_conditions 1;mp_maxrounds 1");

	if (GetConVarBool(g_hAutoRespawn))
		ServerCommand("mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0");
	else
		ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0");

	ServerCommand("mp_endmatch_votenextmap 0;mp_do_warmup_period 0;mp_warmuptime 0;mp_match_can_clinch 0;mp_match_end_changelevel 1;mp_match_restart_delay 10;mp_endmatch_votenextleveltime 10;mp_endmatch_votenextmap 0;mp_halftime 0;bot_zombie 1;mp_do_warmup_period 0;mp_maxrounds 1");
	ServerCommand("sv_infinite_ammo 2");
	ServerCommand("sv_autobunnyhopping 1");
}

public void OnClientConnected(int client)
{
	g_Stage[g_iClientInZone[client][2]][client] = 1;
	g_WrcpStage[client] = 1;
	g_Stage[0][client] = 1;
	g_bWrcpTimeractivated[client] = false;
	g_CurrentStage[client] = 1;
}

public void OnClientPutInServer(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}

	// Defaults
	SetClientDefaults(client);
	Command_Restart(client, 1);

	//display center speed so doesnt have to be re-enabled in options
	if (g_bCenterSpeedDisplay[client])
	{
		SetHudTextParams(-1.0, 0.30, 1.0, 255, 255, 255, 255, 0, 0.25, 0.0, 0.0);
		CreateTimer(0.1, CenterSpeedDisplayTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}

	// SDKHooks
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnPlayerThink);
	SDKHook(client, SDKHook_PreThinkPost, OnPlayerThink);
	SDKHook(client, SDKHook_Think, OnPlayerThink);
	SDKHook(client, SDKHook_PostThink, OnPlayerThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPlayerThink);

	if (!IsFakeClient(client))
	{
		SendConVarValue(client, g_hFootsteps, "0");
		StopRecording(client); // clear client replay frames
	}

	g_bReportSuccess[client] = false;
	g_bTeleByCommand[client] = false;
	g_fCommandLastUsed[client] = 0.0;

	// fluffys set bools
	g_bToggleMapFinish[client] = true;
	g_bRepeat[client] = false;
	g_bNotTeleporting[client] = false;

	if (IsFakeClient(client))
	{
		CS_SetMVPCount(client, 1);
		return;
	}
	else
		g_MVPStars[client] = 0;

	// Client Country
	GetCountry(client);

	if (LibraryExists("dhooks"))
		DHookEntity(g_hTeleport, false, client);

	// Get SteamID
	GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true);

	// char fix
	FixPlayerName(client);

	// Position Restoring
	if (GetConVarBool(g_hcvarRestore) && !g_bRenaming && !g_bInTransactionChain)
	db_selectLastRun(client);

	if (g_bTierFound)
		AnnounceTimer[client] = CreateTimer(20.0, AnnounceMap, client, TIMER_FLAG_NO_MAPCHANGE);

	if (!g_bRenaming && !g_bInTransactionChain && g_bServerDataLoaded && !g_bSettingsLoaded[client] && !g_bLoadingSettings[client])
	{
		// Start loading client settings
		g_bLoadingSettings[client] = true;
		g_iSettingToLoad[client] = 0;
		LoadClientSetting(client, g_iSettingToLoad[client]);
	}
}

public void OnClientAuthorized(int client)
{
	if (GetConVarBool(g_hConnectMsg) && !IsFakeClient(client))
	{
		char s_Country[32], s_clientName[32], s_address[32];
		GetClientIP(client, s_address, 32);
		GetClientName(client, s_clientName, 32);
		Format(s_Country, 100, "Unknown");
		GeoipCountry(s_address, s_Country, 100);
		if (!strcmp(s_Country, NULL_STRING))
			Format(s_Country, 100, "Unknown", s_Country);
		else
			if (StrContains(s_Country, "United", false) != -1 ||
			StrContains(s_Country, "Republic", false) != -1 ||
			StrContains(s_Country, "Federation", false) != -1 ||
			StrContains(s_Country, "Island", false) != -1 ||
			StrContains(s_Country, "Netherlands", false) != -1 ||
			StrContains(s_Country, "Isle", false) != -1 ||
			StrContains(s_Country, "Bahamas", false) != -1 ||
			StrContains(s_Country, "Maldives", false) != -1 ||
			StrContains(s_Country, "Philippines", false) != -1 ||
			StrContains(s_Country, "Vatican", false) != -1)
		{
			Format(s_Country, 100, "The %s", s_Country);
		}

		if (StrEqual(s_Country, "Unknown", false) || StrEqual(s_Country, "Localhost", false))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && i != client)
				{
					CPrintToChat(i, "%t", "Connected1", s_clientName);
				}
			}
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && i != client)
				{
					CPrintToChat(i, "%t", "Connected2", s_clientName, s_Country);
				}
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	db_savePlayTime(client);

	g_fPlayerLastTime[client] = -1.0;
	if (g_fStartTime[client] != -1.0 && g_bTimerRunning[client])
	{
		if (g_bPause[client])
		{
			g_fPauseTime[client] = GetClientTickTime(client) - g_fStartPauseTime[client];
			g_fPlayerLastTime[client] = GetClientTickTime(client) - g_fStartTime[client] - g_fPauseTime[client];
		}
		else
		{
			g_fPlayerLastTime[client] = g_fCurrentRunTime[client];
		}
	}

	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
	SDKUnhook(client, SDKHook_PreThinkPost, OnPlayerThink);
	SDKUnhook(client, SDKHook_Think, OnPlayerThink);
	SDKUnhook(client, SDKHook_PostThink, OnPlayerThink);
	SDKUnhook(client, SDKHook_PostThinkPost, OnPlayerThink);

	if (client == g_RecordBot)
	{
		StopPlayerMimic(client);
		g_RecordBot = -1;
		return;
	}
	if (client == g_BonusBot)
	{
		StopPlayerMimic(client);
		g_BonusBot = -1;
		return;
	}
	if (client == g_WrcpBot)
	{
		StopPlayerMimic(client);
		g_WrcpBot = -1;
		return;
	}

	// Database
	if (IsValidClient(client) && !g_bRenaming)
	{
		if (!g_bIgnoreZone[client] && !g_bPracticeMode[client])
			db_insertLastPosition(client, g_szMapName, g_Stage[g_iClientInZone[client][2]][client], g_iClientInZone[client][2]);

		db_updatePlayerOptions(client);
	}

	// Stop recording
	if (g_aRecording[client] != null)
		StopRecording(client);

	// Stop Showing Triggers
	if (g_bShowTriggers[client])
	{
		g_bShowTriggers[client] = false;
		--g_iTriggerTransmitCount;
		TransmitTriggers(g_iTriggerTransmitCount > 0);
	}

	// New noclipspeed
	sv_noclipspeed.FloatValue = g_iDefaultNoclipSpeed;
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hChatPrefix)
	{
		GetConVarString(g_hChatPrefix, g_szChatPrefix, sizeof(g_szChatPrefix));
		GetConVarString(g_hChatPrefix, g_szMenuPrefix, sizeof(g_szMenuPrefix));
		RemoveColors(g_szMenuPrefix, sizeof(g_szMenuPrefix));
	}
	if (convar == g_hReplayBot)
	{
		if (GetConVarBool(g_hReplayBot))
			LoadReplays();
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (i == g_RecordBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
					}
					else
					{
						if (!GetConVarBool(g_hBonusBot) && !GetConVarBool(g_hWrcpBot)) // if both bots are off, no need to record
							if (g_aRecording[i] != null)
								StopRecording(i);
					}
				}
			}
			if (GetConVarBool(g_hInfoBot) && GetConVarBool(g_hBonusBot))
				ServerCommand("bot_quota 2");
			else
				if (GetConVarBool(g_hInfoBot) || GetConVarBool(g_hBonusBot))
					ServerCommand("bot_quota 1");
				else
					ServerCommand("bot_quota 0");

			if (g_hBotTrail[0] != null)
				CloseHandle(g_hBotTrail[0]);
			g_hBotTrail[0] = null;
		}
	}
	else if (convar == g_hBonusBot)
	{
		if (GetConVarBool(g_hBonusBot))
			LoadReplays();
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (i == g_BonusBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
					}
					else
					{
						if (!GetConVarBool(g_hReplayBot) && !GetConVarBool(g_hWrcpBot)) // if both bots are off
							if (g_aRecording[i] != null)
								StopRecording(i);
					}
				}
			}
			if (GetConVarBool(g_hInfoBot) && GetConVarBool(g_hReplayBot))
				ServerCommand("bot_quota 2");
			else
				if (GetConVarBool(g_hInfoBot) || GetConVarBool(g_hReplayBot))
					ServerCommand("bot_quota 1");
				else
					ServerCommand("bot_quota 0");

			if (g_hBotTrail[1] != null)
				CloseHandle(g_hBotTrail[1]);
			g_hBotTrail[1] = null;
		}
	}
	else if (convar == g_hWrcpBot)
	{
		if (GetConVarBool(g_hWrcpBot))
		{
			LoadReplays();
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (i == g_WrcpBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
					}
					else
					{
						if (!GetConVarBool(g_hReplayBot) && !GetConVarBool(g_hBonusBot)) // if both bots are off
							if (g_aRecording[i] != null)
								StopRecording(i);
					}
				}
			}
		}
	}
	else if (convar == g_hAutoRespawn)
	{
		if (GetConVarBool(g_hAutoRespawn))
		{
			ServerCommand("mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0");
		}
		else
		{
			ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0");
		}
	}
	else if (convar == g_hPlayerSkinChange)
	{
		if (GetConVarBool(g_hPlayerSkinChange))
		{
			char szBuffer[256];
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					if (i == g_RecordBot || i == g_BonusBot || i == g_WrcpBot)
					{
						// Player Model
						GetConVarString(g_hReplayBotPlayerModel, szBuffer, 256);
						SetEntityModel(i, szBuffer);
						// Arm Model
						GetConVarString(g_hReplayBotArmModel, szBuffer, 256);
						SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
						SetEntityModel(i, szBuffer);
					}
					else
					{
						GetConVarString(g_hArmModel, szBuffer, 256);
						SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);

						GetConVarString(g_hPlayerModel, szBuffer, 256);
						SetEntityModel(i, szBuffer);
					}
				}
		}
	}
	else if (convar == g_hPointSystem)
	{
		if (GetConVarBool(g_hPointSystem))
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
					CreateTimer(0.0, SetClanTag, i, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					Format(g_pr_rankname[i], 128, "");
					CreateTimer(0.0, SetClanTag, i, TIMER_FLAG_NO_MAPCHANGE);
				}
		}
	}
	else if (convar == g_hCvarNoBlock)
	{
		if (GetConVarBool(g_hCvarNoBlock))
		{
			for (int client = 1; client <= MAXPLAYERS; client++)
				if (IsValidEntity(client))
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);

		}
		else
		{
			for (int client = 1; client <= MAXPLAYERS; client++)
				if (IsValidEntity(client))
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 5, 4, true);
		}
	}
	else if (convar == g_hCleanWeapons)
	{
		if (GetConVarBool(g_hCleanWeapons))
		{
			char szclass[32];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i))
				{
					for (int j = 0; j < 4; j++)
					{
						int weapon = GetPlayerWeaponSlot(i, j);
						if (weapon != -1 && j != 2)
						{
							GetEdictClassname(weapon, szclass, sizeof(szclass));
							RemovePlayerItem(i, weapon);
							RemoveEdict(weapon);
							int equipweapon = GetPlayerWeaponSlot(i, 2);
							if (equipweapon != -1)
								EquipPlayerWeapon(i, equipweapon);
						}
					}
				}
			}
		}
	}
	else if (convar == g_hAutoBhopConVar)
	{
		g_bAutoBhop = view_as<bool>(StringToInt(newValue[0]));
	}
	else if (convar == g_hCountry)
	{
		if (GetConVarBool(g_hCountry))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					GetCountry(i);
					if (GetConVarBool(g_hPointSystem))
						CreateTimer(0.5, SetClanTag, i, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		else
		{
			if (GetConVarBool(g_hPointSystem))
				for (int i = 1; i <= MaxClients; i++)
					if (IsValidClient(i))
						CreateTimer(0.5, SetClanTag, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (convar == g_hInfoBot)
	{
		if (GetConVarBool(g_hInfoBot))
		{
			LoadInfoBot();
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i) && IsFakeClient(i))
				{
					if (i == g_InfoBot)
					{
						int count = 0;
						g_InfoBot = -1;
						KickClient(i);
						char szBuffer[64];
						if (g_bMapReplay[0])
							count++;
						if (g_BonusBotCount > 0)
							count++;
						Format(szBuffer, sizeof(szBuffer), "bot_quota %i", count);
						ServerCommand(szBuffer);
					}
				}
		}
	}
	else if (convar == g_hReplayBotPlayerModel)
	{
		char szBuffer[256];
		GetConVarString(g_hReplayBotPlayerModel, szBuffer, 256);
		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (IsValidClient(g_RecordBot))
			SetEntityModel(g_RecordBot, szBuffer);
		if (IsValidClient(g_BonusBot))
			SetEntityModel(g_BonusBot, szBuffer);
		if (IsValidClient(g_WrcpBot))
			SetEntityModel(g_WrcpBot, szBuffer);
	}
	else if (convar == g_hReplayBotArmModel)
	{
		char szBuffer[256];
		GetConVarString(g_hReplayBotArmModel, szBuffer, 256);
		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (IsValidClient(g_RecordBot))
			SetEntPropString(g_RecordBot, Prop_Send, "m_szArmsModel", szBuffer);
		if (IsValidClient(g_BonusBot))
			SetEntPropString(g_RecordBot, Prop_Send, "m_szArmsModel", szBuffer);
		if (IsValidClient(g_WrcpBot))
			SetEntPropString(g_WrcpBot, Prop_Send, "m_szArmsModel", szBuffer);

	}
	else if (convar == g_hPlayerModel)
	{
		char szBuffer[256];
		GetConVarString(g_hPlayerModel, szBuffer, 256);

		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (!GetConVarBool(g_hPlayerSkinChange))
			return;
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_RecordBot)
				SetEntityModel(i, szBuffer);
			else if (IsValidClient(i) && i != g_BonusBot)
				SetEntityModel(i, szBuffer);
			else if (IsValidClient(i) && i != g_WrcpBot)
				SetEntityModel(i, szBuffer);
	}
	else if (convar == g_hArmModel)
	{
		char szBuffer[256];
		GetConVarString(g_hArmModel, szBuffer, 256);

		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (!GetConVarBool(g_hPlayerSkinChange))
			return;
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_RecordBot)
				SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
			else if (IsValidClient(i) && i != g_BonusBot)
				SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
			else if (IsValidClient(i) && i != g_WrcpBot)
				SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
	}
	else if (convar == g_hReplayBotColor)
	{
		char color[256];
		Format(color, 256, "%s", newValue[0]);
		GetRGBColor(0, color);
	}
	else if (convar == g_hBonusBotColor)
	{
		char color[256];
		Format(color, 256, "%s", newValue[0]);
		GetRGBColor(1, color);
	}
	else if (convar == g_hzoneStartColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[1]);
	}
	else if (convar == g_hzoneEndColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[2]);
	}
	else if (convar == g_hzoneCheckerColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[10]);
	}
	else if (convar == g_hzoneBonusStartColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[3]);
	}
	else if (convar == g_hzoneBonusEndColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[4]);
	}
	else if (convar == g_hzoneStageColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[5]);
	}
	else if (convar == g_hzoneCheckpointColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[6]);
	}
	else if (convar == g_hzoneSpeedColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[7]);
	}
	else if (convar == g_hzoneTeleToStartColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[8]);
	}
	else if (convar == g_hzoneValidatorColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[9]);
	}
	else if (convar == g_hzoneStopColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[0]);
	}
	else if (convar == g_hZonerFlag)
	{
		AdminFlag flag;
		bool validFlag;
		validFlag = FindFlagByChar(newValue[0], flag);

		if (!validFlag)
		{
			PrintToServer("SurfTimer | Invalid flag for ck_zoner_flag");
			g_ZonerFlag = ADMFLAG_ROOT;
		}
		else
			g_ZonerFlag = FlagToBit(flag);
	}
	else if (convar == g_hAdminMenuFlag)
	{
		AdminFlag flag;
		bool validFlag;
		validFlag = FindFlagByChar(newValue[0], flag);

		if (!validFlag)
		{
			PrintToServer("SurfTimer | Invalid flag for ck_adminmenu_flag");
			g_AdminMenuFlag = ADMFLAG_ROOT;
		}
		else
			g_AdminMenuFlag = FlagToBit(flag);
	}

	else if (convar == g_hServerID)
		g_iServerID = GetConVarInt(g_hServerID);
	else if (convar == g_hHostName)
	{
		GetConVarString(g_hHostName, g_sServerName, sizeof(g_sServerName));
	}
	else if (convar == g_hEnforceDefaultTitles)
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				if (!GetConVarBool(g_hEnforceDefaultTitles))
					db_viewCustomTitles(i, g_szSteamID[i]);
				else
					LoadDefaultTitle(i);
			}
		}
	}
	else if (convar == g_hAutoVipFlag)
	{
		AdminFlag flag;
		bool validFlag;
		validFlag = FindFlagByChar(newValue[0], flag);

		if (!validFlag)
		{
			LogError("SurfTimer | Invalid flag for ck_vip_flag");
			g_VipFlag = ADMFLAG_RESERVATION;
		}
		else
			g_VipFlag = FlagToBit(flag);
	}
	else if (convar == g_hSoundPathWR)
	{
		GetConVarString(g_hSoundPathWR, g_szSoundPathWR, sizeof(g_szSoundPathWR));
		if (FileExists(g_szSoundPathWR))
		{
			char sBuffer[2][PLATFORM_MAX_PATH];
			ExplodeString(g_szSoundPathWR, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
			Format(g_szRelativeSoundPathWR, sizeof(g_szRelativeSoundPathWR), "*%s", sBuffer[1]);
		}
		else
		{
			Format(g_szSoundPathWR, sizeof(g_szSoundPathWR), WR2_FULL_SOUND_PATH);
			Format(g_szRelativeSoundPathWR, sizeof(g_szRelativeSoundPathWR), WR2_RELATIVE_SOUND_PATH);
		}
	}
	else if (convar == g_hSoundPathTop)
	{
		GetConVarString(g_hSoundPathTop, g_szSoundPathTop, sizeof(g_szSoundPathTop));
		if (FileExists(g_szSoundPathTop))
		{
			char sBuffer[2][PLATFORM_MAX_PATH];
			ExplodeString(g_szSoundPathTop, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
			Format(g_szRelativeSoundPathTop, sizeof(g_szRelativeSoundPathTop), "*%s", sBuffer[1]);
		}
		else
		{
			Format(g_szSoundPathTop, sizeof(g_szSoundPathTop), TOP10_FULL_SOUND_PATH);
			Format(g_szRelativeSoundPathTop, sizeof(g_szRelativeSoundPathTop), TOP10_RELATIVE_SOUND_PATH);
		}
	}
	else if (convar == g_hSoundPathPB)
	{
		GetConVarString(g_hSoundPathPB, g_szSoundPathPB, sizeof(g_szSoundPathPB));
		if (FileExists(g_szSoundPathPB))
		{
			char sBuffer[2][PLATFORM_MAX_PATH];
			ExplodeString(g_szSoundPathPB, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
			Format(g_szRelativeSoundPathPB, sizeof(g_szRelativeSoundPathPB), "*%s", sBuffer[1]);
		}
		else
		{
			Format(g_szSoundPathPB, sizeof(g_szSoundPathPB), PR_FULL_SOUND_PATH);
			Format(g_szRelativeSoundPathPB, sizeof(g_szRelativeSoundPathPB), PR_RELATIVE_SOUND_PATH);
		}
	}
	else if (convar == g_hSoundPathWRCP)
	{
		GetConVarString(g_hSoundPathWRCP, g_szSoundPathWRCP, sizeof(g_szSoundPathWRCP));
		if (FileExists(g_szSoundPathWRCP))
		{
			char sBuffer[2][PLATFORM_MAX_PATH];
			ExplodeString(g_szSoundPathWRCP, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
			Format(g_szRelativeSoundPathWRCP, sizeof(g_szRelativeSoundPathWRCP), "*%s", sBuffer[1]);
		}
		else
		{
			Format(g_szSoundPathWRCP, sizeof(g_szSoundPathWRCP), "sound/physics/glass/glass_bottle_break2.wav");
			Format(g_szRelativeSoundPathWRCP, sizeof(g_szRelativeSoundPathWRCP), "*physics/glass/glass_bottle_break2.wav");
		}
	}
	if (g_hZoneTimer != INVALID_HANDLE)
	{
		KillTimer(g_hZoneTimer);
		g_hZoneTimer = INVALID_HANDLE;
	}

	g_hZoneTimer = CreateTimer(GetConVarFloat(g_hChecker), BeamBoxAll, _, TIMER_REPEAT);
}

public void OnPluginStart()
{
	g_bServerDataLoaded = false;

	// Language File
	LoadTranslations("surftimer.phrases");

	CreateConVars();
	CreateCommands();
	CreateHooks();
	CreateCommandListeners();

	db_setupDatabase();
	CreateCommandsNewMap();

	// mic
	g_ownerOffset = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");

	// add to admin menu
	Handle tpMenu;
	if (LibraryExists("adminmenu") && ((tpMenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(tpMenu);

	// Hints array
	g_aHints = new ArrayList(MAX_HINT_SIZE);

	// mapcycle array
	int arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = CreateArray(arraySize);

	// default titles whitelist array
	g_DefaultTitlesWhitelist = CreateArray();

	// Botmimic 3
	// https://forums.alliedmods.net/showthread.php?t=180114

	CheatFlag("bot_zombie", false, true);
	CheatFlag("bot_mimic", false, true);
	g_smLoadedRecordsAdditionalTeleport = new StringMap();
	Handle hGameData = LoadGameConfigFile("sdktools.games");
	if (hGameData == null)
	{
		SetFailState("GameConfigFile sdkhooks.games was not found.");
		return;
	}
	int iOffset = GameConfGetOffset(hGameData, "Teleport");
	CloseHandle(hGameData);
	if (iOffset == -1)
		return;

	if (LibraryExists("dhooks"))
	{
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if (g_hTeleport == null)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_Bool);
	}

	// Forwards
	Register_Forwards();

	if (g_bLateLoaded)
	{
		CreateTimer(3.0, LoadPlayerSettings, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}

	Format(szWHITE, 12, "%c", WHITE);
	Format(szDARKRED, 12, "%c", DARKRED);
	Format(szPURPLE, 12, "%c", PURPLE);
	Format(szGREEN, 12, "%c", GREEN);
	Format(szLIGHTGREEN, 12, "%c", LIGHTGREEN);
	Format(szLIMEGREEN, 12, "%c", LIMEGREEN);
	Format(szRED, 12, "%c", RED);
	Format(szGRAY, 12, "%c", GRAY);
	Format(szYELLOW, 12, "%c", YELLOW);
	Format(szDARKGREY, 12, "%c", DARKGREY);
	Format(szBLUE, 12, "%c", BLUE);
	Format(szDARKBLUE, 12, "%c", DARKBLUE);
	Format(szLIGHTBLUE, 12, "%c", LIGHTBLUE);
	Format(szPINK, 12, "%c", PINK);
	Format(szLIGHTRED, 12, "%c", LIGHTRED);
	Format(szORANGE, 12, "%c", ORANGE);

	// Server Announcements
	g_bHasLatestID = false;
	g_iLastID = 0;
}

/*======  End of Events  ======*/

public Action ItemFoundMsg(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	return Plugin_Handled;
}
