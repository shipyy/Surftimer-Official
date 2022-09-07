/*===================================
=              Natives              =
===================================*/

public int Native_GetTimerStatus(Handle plugin, int numParams)
{
	return g_bTimerRunning[GetNativeCell(1)];
}

public int Native_StopTimer(Handle plugin, int numParams)
{
	Client_Stop(GetNativeCell(1), 0);

	return 0;
}

public any Native_GetCurrentTime(Handle plugin, int numParams)
{	
	int client = GetNativeCell(1);

	if (g_bWrcpTimeractivated[client] && !g_bTimerRunning[client])
		return g_fCurrentWrcpRunTime[client];
	else if (g_bPracticeMode[client] || g_bTimerRunning[client])
		return g_fCurrentRunTime[client];
	else if (!g_bTimerEnabled[client])
		return -1.0;
	else
		return 0.0;
}

public int Native_EmulateStartButtonPress(Handle plugin, int numParams)
{
	CL_OnStartTimerPress(GetNativeCell(1));

	return 0;
}

public int Native_EmulateStopButtonPress(Handle plugin, int numParams)
{
	CL_OnEndTimerPress(GetNativeCell(1));

	return 0;
}

public int Native_SafeTeleport(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (IsValidClient(client))
	{
		float fDestination[3], Angle[3], Vel[3];
		GetNativeArray(2, fDestination, 3);
		GetNativeArray(3, Angle, 3);
		GetNativeArray(4, Vel, 3);

		teleportEntitySafe(client, fDestination, Angle, Vel, GetNativeCell(5));

		return true;
	}
	else
		return false;
}

public int Native_IsClientVip(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (IsValidClient(client) && !IsFakeClient(client))
		return g_bVip[client];
	else
		return false;
}

public int Native_GetPlayerRank(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (IsValidClient(client) && !IsFakeClient(client))
		return g_PlayerRank[client][0];
	else
		return -1;
}

public int Native_GetPlayerPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (IsValidClient(client) && !IsFakeClient(client))
		return g_pr_points[client][0];
	else
		return -1;
}

public int Native_GetPlayerSkillgroup(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char str[256];
	GetNativeString(2, str, 256);
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Format(str, sizeof(str), g_pr_chat_coloredrank[client]);
		SetNativeString(2, str, 256, true);
	}
	else
	{
		Format(str, sizeof(str), "Unranked");
		SetNativeString(2, str, 256, true);
	}

	return 0;
}

public int Native_GetPlayerNameColored(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char str[256];
	GetNativeString(2, str, 256);
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		GetClientName(client, str, sizeof(str));
		Format(str, sizeof(str), "%s%s",  g_pr_namecolour[client], str);
		SetNativeString(2, str, 256, true);
	}
	else
	{
		Format(str, sizeof(str), "invalid");
		SetNativeString(2, str, 256, true);
	}

	return 0;
}

public int Native_GetMapData(Handle plugin, int numParams)
{
	char szname[MAX_NAME_LENGTH], sztime[64];
	GetNativeString(1, szname, MAX_NAME_LENGTH);
	GetNativeString(2, sztime, 64);
	float time = GetNativeCellRef(3);

	Format(szname, sizeof(szname), g_szRecordPlayer);
	Format(sztime, sizeof(sztime), g_szRecordMapTime);
	SetNativeString(1, szname, sizeof(szname), true);
	SetNativeString(2, sztime, sizeof(sztime), true);

	if(g_fRecordMapTime != 9999999.0)
		time = g_fRecordMapTime;
	else
		time = -1.0;
	SetNativeCellRef(3, time);

	return g_MapTimesCount;
}

public int Native_GetBonusData(Handle plugin, int numParams)
{	
	int client = GetNativeCell(1);

	//WR
	char szname[MAX_NAME_LENGTH];
	GetNativeString(2, szname, MAX_NAME_LENGTH);
	float WRtime = GetNativeCellRef(3);
	float PBtime = GetNativeCellRef(4);

	int zonegroup = g_iClientInZone[client][2];

	Format(szname, sizeof(szname), g_szBonusFastest[zonegroup]);
	SetNativeString(2, szname, sizeof(szname), true);

	if(g_fBonusFastest[zonegroup] != 9999999.0)
		WRtime = g_fBonusFastest[zonegroup];
	else
		WRtime = -1.0;
	SetNativeCellRef(3, WRtime);

	if(g_fPersonalRecordBonus[zonegroup][client] > 0)
		PBtime = g_fPersonalRecordBonus[zonegroup][client];
	else
		PBtime = -1.0;
	SetNativeCellRef(4, PBtime);

	return g_iBonusCount[zonegroup];
}

public int Native_GetStageData(Handle plugin, int numParams)
{	
	int client = GetNativeCell(1);

	char szname[MAX_NAME_LENGTH];
	GetNativeString(2, szname, MAX_NAME_LENGTH);
	float WRtime = GetNativeCellRef(3);
	float PBtime = GetNativeCellRef(4);

	int stage = g_Stage[0][client];

	Format(szname, sizeof(szname), g_szStageRecordPlayer[stage]);
	SetNativeString(2, szname, sizeof(szname), true);

	if(g_fStageRecord[stage] > 0)
		WRtime = g_fStageRecord[stage];
	else
		WRtime = -1.0;
	SetNativeCellRef(3, WRtime);

	if(g_fWrcpRecord[client][stage][g_iCurrentStyle[client]] > 0)
		PBtime = g_fWrcpRecord[client][stage][g_iCurrentStyle[client]];
	else
		PBtime = -1.0;
	SetNativeCellRef(4, PBtime);

	return g_TotalStageRecords[stage];
}

public int Native_GetPlayerData(Handle plugin, int numParams)
{
	int client = GetNativeCellRef(1);
	int zonegroup = GetNativeCellRef(2);
	int rank = 99999;
	float time;
	char szCountry[16];
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		zonegroup = g_iClientInZone[client][2];

		if (zonegroup == 0) {
			time = GetNativeCellRef(3);
			rank = GetNativeCellRef(4);
			GetNativeString(5, szCountry, 16);

			if (g_fPersonalRecord[client] > 0.0)
				time = g_fPersonalRecord[client];
			else
				time = -1.0;

			rank = g_MapTimesCount;

			Format(szCountry, sizeof(szCountry), g_szCountryCode[client]);

			SetNativeCellRef(3, time);
			SetNativeCellRef(4, rank);
			SetNativeString(5, szCountry, sizeof(szCountry), true);
		}
		else {
			time = GetNativeCellRef(3);
			rank = GetNativeCellRef(4);
			GetNativeString(5, szCountry, 16);

			if (g_fPersonalRecordBonus[zonegroup][client] > 0.0)
				time = g_fPersonalRecordBonus[zonegroup][client];
			else
				time = -1.0;

			rank = g_iBonusCount[zonegroup];

			Format(szCountry, sizeof(szCountry), g_szCountryCode[client]);

			SetNativeCellRef(3, time);
			SetNativeCellRef(4, rank);
			SetNativeString(5, szCountry, sizeof(szCountry), true);
		}
	}

	return rank;
}

public int Native_GetPlayerInfo(Handle plugin, int numParams)
{
	int client = GetNativeCellRef(1);
	int iStage = 9999;
	if (IsValidClient(client))
	{
		iStage = g_Stage[0][client];
		SetNativeCellRef(2, g_bWrcpTimeractivated[client]);
		SetNativeCellRef(3, g_bPracticeMode[client]);

		if (!IsFakeClient(client) ) {
			SetNativeCellRef(4, iStage);
			SetNativeCellRef(5, g_iInBonus[client]);
		}
		else {
			SetNativeCellRef(4, g_iCurrentlyPlayingStage);
			SetNativeCellRef(5, g_iCurrentlyPlayingBonus);
		}
	}

	return iStage;
}

public int Native_GetClientStyle(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int style;
	if (IsValidClient(client))
	{
		if(!IsFakeClient(client)) {
			style = g_iCurrentStyle[client];
		}
		else{
			if (client == g_RecordBot)
				style = g_iSelectedReplayStyle;
			else if (client == g_BonusBot)
				style = g_iSelectedBonusReplayStyle;
		}
	}

	return style;
}

public int Native_GetMapTier(Handle plugin, int numParams)
{
	return g_iMapTier;
}

public int Native_GetMapStages(Handle plugin, int numParams)
{
	int stages = 0;
	if (g_bhasStages)
		stages = g_mapZonesTypeCount[0][3] + 1;
	return stages;
}

public any Native_GetClientSync(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return GetStrafeSync(client, true);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("surftimer");
	CreateNative("surftimer_GetTimerStatus", Native_GetTimerStatus);
	CreateNative("surftimer_StopTimer", Native_StopTimer);
	CreateNative("surftimer_EmulateStartButtonPress", Native_EmulateStartButtonPress);
	CreateNative("surftimer_EmulateStopButtonPress", Native_EmulateStopButtonPress);
	CreateNative("surftimer_GetCurrentTime", Native_GetCurrentTime);
	CreateNative("surftimer_GetPlayerRank", Native_GetPlayerRank);
	CreateNative("surftimer_GetPlayerPoints", Native_GetPlayerPoints);
	CreateNative("surftimer_GetPlayerSkillgroup", Native_GetPlayerSkillgroup);
	CreateNative("surftimer_GetPlayerNameColored", Native_GetPlayerNameColored);
	CreateNative("surftimer_GetMapData", Native_GetMapData);
	CreateNative("surftimer_GetBonusData", Native_GetBonusData);
	CreateNative("surftimer_GetStageData", Native_GetStageData);
	CreateNative("surftimer_GetPlayerData", Native_GetPlayerData);
	CreateNative("surftimer_GetPlayerInfo", Native_GetPlayerInfo);
	CreateNative("surftimer_GetClientStyle", Native_GetClientStyle);
	CreateNative("surftimer_GetMapTier", Native_GetMapTier);
	CreateNative("surftimer_GetMapStages", Native_GetMapStages);
	CreateNative("surftimer_SafeTeleport", Native_SafeTeleport);
	CreateNative("surftimer_IsClientVip", Native_IsClientVip);
	CreateNative("surftimer_GetClientSync", Native_GetClientSync);
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
	g_bLateLoaded = late;
	return APLRes_Success;
}

/*======  End of Natives  ======*/


/*===================================
=             Forwards              =
===================================*/

void Register_Forwards()
{
	g_MapFinishForward = new GlobalForward("surftimer_OnMapFinished", ET_Event, Param_Cell, Param_Float, Param_String, Param_Float, Param_Float, Param_Cell, Param_Cell, Param_Cell);
	//g_MapCheckpointForward = new GlobalForward("surftimer_OnCheckpoint", ET_Event, Param_Cell, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String);
	//g_MapCheckpointForward = new GlobalForward("surftimer_OnCheckpoint", ET_Event, Param_Cell, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String, Param_String, Param_String);
	
	//MAIN FORWARD TO USE IF SWAPPED
	//g_MapCheckpointForward = new GlobalForward("surftimer_OnCheckpoint", ET_Event, Param_Cell, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String);
	
	//DEFAULT
	g_MapCheckpointForward = new GlobalForward("surftimer_OnCheckpoint", ET_Event, Param_Cell, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String, Param_Cell);
	g_BonusFinishForward = new GlobalForward("surftimer_OnBonusFinished", ET_Event, Param_Cell, Param_Float, Param_String, Param_Float, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_PracticeFinishForward = new GlobalForward("surftimer_OnPracticeFinished", ET_Event, Param_Cell, Param_Float, Param_String);
	g_NewRecordForward = new GlobalForward("surftimer_OnNewRecord", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell);
	g_NewWRCPForward = new GlobalForward("surftimer_OnNewWRCP", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell);
	g_MapStartForward = new GlobalForward("surftimer_OnMapStart", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

/**
 * Sends a map start forward on surftimer_OnMapStart.
 * 
 * @param client               	Index of the client.
 * @param prestrafe             prestrafe
 * @param pre_PBDiff     		pb prestrafe difference
 * @param pre_SRDiff  			sr prestrafe difference
 */
void SendMapStartForward(int client, int prestrafe, int pre_PBDiff, int pre_SRDiff)
{
	Call_StartForward(g_MapStartForward);
	Call_PushCell(client);
	Call_PushCell(prestrafe);
	Call_PushCell(pre_PBDiff);
	Call_PushCell(pre_SRDiff);
	Call_Finish();
}

/**
 * Sends a map finish forward on surftimer_OnMapFinished.
 * 
 * @param client           Index of the client who beat the map.
 * @param count            The number of times the map has been beaten.
 */
void SendMapFinishForward(int client, int count,int style)
{
	/* Start function call */
	Call_StartForward(g_MapFinishForward);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushFloat(g_fFinalTime[client]);
	Call_PushString(g_szFinalTime[client]);
	Call_PushFloat(g_fPBDifference[client][style]);
	Call_PushFloat(g_fWRDifference[client][style]);
	Call_PushCell(g_MapRank[client]);
	Call_PushCell(count);
	Call_PushCell(style);

	/* Finish the call, get the result */
	Call_Finish();
}

/**
 * Sends a map checkpoint forward on surftimer_OnCheckpoint.
 * 
 * @param client               Index of the client.
 * @param zonegroup            ID of the zone group.
 * @param zone                 ID of the zone.
 * @param time                 Time at the zone.
 * @param szTime               Formatted time.
 * @param szDiff_colorless     Colorless time diff.
 * @param sz_srDiff_colorless  Colorless time diff with the record.
 */
void SendMapCheckpointForward(
	int client, 
	int zonegroup, 
	int zone, 
	float time, 
	const char[] szTime, 
	const char[] szDiff_colorless, 
	const char[] sz_srDiff_colorless)
{
	// Checkpoint forward
	Call_StartForward(g_MapCheckpointForward);
	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushFloat(time);
	Call_PushString(szTime);
	Call_PushFloat(g_fCheckpointTimesRecord[zonegroup][client][zone]);
	Call_PushString(szDiff_colorless);
	Call_PushFloat(g_fCheckpointServerRecord[zonegroup][zone]);
	Call_PushString(sz_srDiff_colorless);

	ArrayList CustomCheckpoints = new ArrayList();
	for (int i = 0; i < 8; i++)
		CustomCheckpoints.Push(g_fCustomCheckpointsTimes_Difference[client][i][zone]);
	Call_PushCell(CustomCheckpoints);

	/* Finish the call, get the result */
	Call_Finish();

	delete CustomCheckpoints;
}

//CP SPEEDS CODE
/**
 * Sends a map checkpoint forward on surftimer_OnCheckpoint.
 * 
 * @param client               Index of the client.
 * @param zonegroup            ID of the zone group.
 * @param zone                 ID of the zone.
 * @param time                 Time at the zone.
 * @param szTime               Formatted time.
 * @param szDiff_colorless     Colorless time diff.
 * @param sz_srDiff_colorless  Colorless time diff with the record.
 */

/*
void SendMapCheckpointForward(
	int client, 
	int zonegroup, 
	int zone, 
	float time, 
	const char[] szTime,
	const char[] szDiff_colorless, 
	const char[] sz_srDiff_colorless,
	float speed, 
	const char[] szSpeed,
	const char[] sz_SpeedDiff_colorless,
	const char[] sz_srSpeedDiff_colorless)
{
	// Checkpoint forward
	Call_StartForward(g_MapCheckpointForward);
	// Push parameters one at a time
	Call_PushCell(client);
	Call_PushFloat(time);
	Call_PushString(szTime);
	Call_PushFloat(g_fCheckpointTimesRecord[zonegroup][client][zone]);
	Call_PushString(szDiff_colorless);
	Call_PushFloat(g_fCheckpointServerRecord[zonegroup][zone]);
	Call_PushString(sz_srDiff_colorless);
	Call_PushFloat(speed);
	Call_PushString(szSpeed);
	Call_PushFloat(g_fCheckpointSpeedsRecord[zonegroup][client][zone]);
	Call_PushString(sz_SpeedDiff_colorless);
	Call_PushFloat(g_fCheckpointSpeedServerRecord[zonegroup][zone]);
	Call_PushString(sz_srSpeedDiff_colorless);

	//Finish the call, get the result
	Call_Finish();
}
*/

/**
 * Sends a bonus finish forward on surftimer_OnBonusFinished.
 * 
 * @param client           Index of the client.
 * @param rank             Rank of the client.
 * @param zGroup           Zone group of the bonus.
 */
void SendBonusFinishForward(int client, int rank, int zGroup, int style)
{
	/* Start function call */
	Call_StartForward(g_BonusFinishForward);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushFloat(g_fFinalTime[client]);
	Call_PushString(g_szFinalTime[client]);
	Call_PushFloat(g_fPBDifference_Bonus[client][style][zGroup]);
	Call_PushFloat(g_fWRDifference_Bonus[client][style][zGroup]);
	Call_PushCell(rank);
	Call_PushCell(g_iBonusCount[zGroup]);
	Call_PushCell(zGroup);
	Call_PushCell(style);

	/* Finish the call, get the result */
	Call_Finish();
}

/**
 * Sends a practive finish forward on surftimer_OnPracticeFinished.
 * 
 * @param client           Index of the client.
 */
void SendPracticeFinishForward(int client)
{
	/* Start function call */
	Call_StartForward(g_PracticeFinishForward);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushFloat(g_fFinalTime[client]);
	Call_PushString(g_szFinalTime[client]);

	/* Finish the call, get the result */
	Call_Finish();
}

/**
 * Sends a new record forward on surftimer_OnNewRecord.
 * 
 * @param client           Index of the client.
 * @param szRecordDiff     String containing the formatted difference with the previous record.
 * @param bonusGroup       Number of the bonus. Default = -1.
 */
void SendNewRecordForward(int client, const char[] szRecordDiff, int bonusGroup = -1)
{
	/* Start New record function call */
	Call_StartForward(g_NewRecordForward);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushCell(g_iCurrentStyle[client]);
	Call_PushString(g_szFinalTime[client]);
	Call_PushString(szRecordDiff);
	Call_PushCell(bonusGroup);

	/* Finish the call, get the result */
	Call_Finish();
}

/**
 * Sends a new WRCP forward on surftimer_OnNewWRCP.
 * 
 * @param client           Index of the client.
 * @param stage            ID of the stage.
 * @param szRecordDiff     String containing the formatted difference with the previous record.
 */
void SendNewWRCPForward(int client, int stage, const char[] szRecordDiff)
{
	/* Start New record function call */
	Call_StartForward(g_NewWRCPForward);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushCell(g_iCurrentStyle[client]);
	Call_PushString(g_szFinalWrcpTime[client]);
	Call_PushString(szRecordDiff);
	Call_PushCell(stage);

	/* Finish the call, get the result */
	Call_Finish();
}

/*======  End of Forwards  ======*/