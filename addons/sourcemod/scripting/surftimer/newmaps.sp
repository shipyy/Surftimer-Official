void CreateCommandsNewMap()
{
	RegConsoleCmd("sm_newmap", Client_NewMap, "[surftimer] shows new maps");
	RegConsoleCmd("sm_nm", Client_NewMap, "[surftimer] shows new maps");
	RegConsoleCmd("sm_addnewmap", Client_AddNewMap, "[surftimer] add a new map");
	RegConsoleCmd("sm_anm", Client_AddNewMap, "[surftimer] add a new map");
	RegConsoleCmd("sm_pop_newmaps", Populate_NewMaps, "[surftimer] populate ck_newmaps (usefull if the server is using new version of webstats)");

	db_present();
}

public Action Client_NewMap(int client, int args)
{
	db_ViewNewestMaps(client);
	return Plugin_Handled;
}

public Action Client_AddNewMap(int client, int args)
{
	if (IsPlayerZoner(client))
		db_InsertNewestMaps();
	return Plugin_Handled;
}

public Action Populate_NewMaps(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (IsPlayerZoner(client))
		db_Populate_NewMaps();

	return Plugin_Handled;

}

public int NewMapMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{	

	//ALLOW NOMINATING A MAP FROM NEWMAPS
	if(action == MenuAction_Select){

		char map[PLATFORM_MAX_PATH], name[MAX_NAME_LENGTH], displayName[PLATFORM_MAX_PATH];
		menu.GetItem(param2, map, sizeof(map), _, displayName, sizeof(displayName));
		
		GetClientName(param1, name, sizeof(name));

		NominateResult result = NominateMap(map, false, param1);
		
		/* Don't need to check for InvalidMap because the menu did that already */
		if (result == Nominate_AlreadyInVote)
		{
			CPrintToChat(param1, "%t", "Map Already Nominated", g_szChatPrefix);
			return 0;
		}
		else if (result == Nominate_VoteFull)
		{
			CPrintToChat(param1, "%t", "Max Nominations", g_szChatPrefix);
			return 0;
		}

		if (result == Nominate_Replaced)
		{
			CPrintToChatAll("%t", "Map Nomination Changed", g_szChatPrefix, name, displayName);
			return 0;	
		}
		
		CPrintToChatAll("%t", "Map Nominated", g_szChatPrefix, name, displayName);

	}

	if (action == MenuAction_End)
		delete menu;

	return 0;
}


public void db_ViewNewestMaps(int client)
{
	char sql_selectNewestMaps[] = "SELECT mapname, date FROM ck_newmaps ORDER BY date DESC LIMIT 50";
	SQL_TQuery(g_hDb, sql_selectNewestMapsCallback, sql_selectNewestMaps, client, DBPrio_Low);
}

public void sql_selectNewestMapsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surftimer] SQL Error (sql_selectNewestMapsCallback): %s", error);
		return;
	}

	char szMapName[64];
	char szDate[64];
	if (SQL_HasResultSet(hndl))
	{
		Menu menu = CreateMenu(NewMapMenuHandler);
		SetMenuTitle(menu, "New Maps: ");

		int i = 1;
		char szItem[128];
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szMapName, 64);
			SQL_FetchString(hndl, 1, szDate, 64);
			Format(szItem, sizeof(szItem), "%s since %s", szMapName, szDate);
			AddMenuItem(menu, "", szItem, ITEMDRAW_DEFAULT);
			i++;
		}
		if (i == 1)
		{
			delete menu;
		}
		else
		{
			SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
			DisplayMenu(menu, data, MENU_TIME_FOREVER);
		}
	}
}

public void db_InsertNewestMaps()
{
	char sql_insertNewestMaps[] = "INSERT INTO ck_newmaps (mapname) VALUES('%s');";
	char szQuery[512];
	Format(szQuery, sizeof(szQuery), sql_insertNewestMaps, g_szMapName);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, _, DBPrio_Low);
}

public void db_Populate_NewMaps()
{
	PrintToServer("\n----------POPULATING NEWMAPS----------\n");

	char szMapName[128];
	for (int i = 0; i < GetArraySize(g_MapList); i++)
	{
		GetArrayString(g_MapList, i, szMapName, sizeof(szMapName));

		db_MapTierExists(szMapName);
	}
}

public void db_MapTierExists(char szMapName[128])
{
	char szQuery[512];
	Format(szQuery, sizeof(szQuery), "SELECT mapname FROM ck_maptier WHERE mapname = '%s' LIMIT 1;", szMapName);
	
	SQL_TQuery(g_hDb, SQL_MapTierExistsCallback, szQuery, _, DBPrio_Low);
}

public void SQL_MapTierExistsCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[SurfTimer] SQL Error (SQL_MapTierExistsCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		char map[128];
		SQL_FetchString(hndl, 0, map, sizeof(map));

		PrintToServer("-----ADDING %s-----", map);

		char szQuery[512];
		Format(szQuery, sizeof(szQuery), "INSERT INTO ck_newmaps (mapname) VALUES('%s');", map);
		SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, _, DBPrio_Low);
	}
}

//update Database just incase
public void db_present()
{
	// Check for db upgrades
	if (!SQL_FastQuery(g_hDb, "SELECT mapname FROM ck_newmaps LIMIT 1"))
	{
		db_upgradeDbNewMap();
		return;
	}
}


public void db_upgradeDbNewMap()
{
	char sql_createNewestMaps[] = "CREATE TABLE IF NOT EXISTS ck_newmaps (mapname VARCHAR(32), date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(mapname)) DEFAULT CHARSET=utf8mb4;";

	Transaction createTableTnx = SQL_CreateTransaction();

	SQL_AddQuery(createTableTnx, sql_createNewestMaps);

	SQL_ExecuteTransaction(g_hDb, createTableTnx, SQLTxn_CreateDatabaseSuccess, SQLTxn_CreateDatabaseFailed);
}