public void PreCacheSounds()
{
	char sPath[PLATFORM_MAX_PATH];
	char line[PLATFORM_MAX_PATH];
	char downloadPath[PLATFORM_MAX_PATH];
	char soundPath[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", SOUNDS_CONFIG_PATH);
	PrintToServer("[Surftimer] Cached Sounds:");
	Handle fileHandle = OpenFile(sPath, "r");

	if (fileHandle != null)
	{
		g_Sounds.Clear();

		//ADD NO SOUND OPTIONS
		g_Sounds.PushString("None.mp3");

		//ADD SOME DEFAULT ENGINE SOUNDS
		PrecacheSound("buttons/button18.wav", true);
		g_Sounds.PushString("button18.wav");

		PrecacheSound("buttons/button3.wav", true);
		g_Sounds.PushString("button3.wav");

		PrecacheSound("buttons/button10.wav", true);
		g_Sounds.PushString("button10.wav");

		PrecacheSound("physics/glass/glass_bottle_break2.wav", true);
		g_Sounds.PushString("glass_bottle_break2.wav");

		while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
		{
			TrimString(line);
			if (StrContains(line, "//", false) == 0 || IsNullString(line) || strlen(line) == 0)
				continue;
			else {
				Format(downloadPath, sizeof downloadPath, "sound/surftimer/%s", line);
				AddFileToDownloadsTable(downloadPath);

				Format(soundPath, sizeof soundPath, "surftimer/%s", line);
				PrecacheSound(soundPath, true);

				g_Sounds.PushString(line);
			}
		}

		char sztemp[32];
		for(int i = 0; i < g_Sounds.Length; i++)
		{
			g_Sounds.GetString(i, sztemp, sizeof sztemp);
			PrintToServer("%s", sztemp);
		}
		PrintToServer("===============");
	}
	else {
		SetFailState("[surftimer] %s is empty or does not exist.", SOUNDS_CONFIG_PATH);
	}
}

void PlaySound(int client, int type, bool playforall = false)
{
	//GET PATH FROM TYPE
	// 0 - map wr
	// 1 - map pb
	// 2 - map top10
	// 3 - bonus wr
	// 4 - bonus pb
	// 5 - bonus top10
	// 6 - stage wr
	// 7 - timer start | buttons/button18.wav
	// 8 - missed pb
	// 9 - error sound

	if (IsFakeClient(client)) {
		return;
	}

	if ( playforall ) {
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i) && g_bEnableQuakeSounds[i])
			{
				char szSoundToPlayPath[PLATFORM_MAX_PATH];
				g_Sounds.GetString(g_iClientSounds[i][type], szSoundToPlayPath, sizeof szSoundToPlayPath);

				//IF NONE IS SELECTED JUST SKIP TO NEXT
				if ( StrContains(szSoundToPlayPath, "none", false) != -1 ) {
					continue;
				}

				//IF SOUND BEING USED IS A DEFAULT SOUND
				if ( StrContains(szSoundToPlayPath, "wav", false) != -1 ) {
					if ( StrContains(szSoundToPlayPath, "button", false) != -1 )
						Format(szSoundToPlayPath, sizeof szSoundToPlayPath, "buttons/%s", szSoundToPlayPath);
					else
						Format(szSoundToPlayPath, sizeof szSoundToPlayPath, "physics/glass/%s", szSoundToPlayPath);
				}
				//IF SOUND BEING USED IS A CUSTOM SOUND
				else {
					Format(szSoundToPlayPath, sizeof szSoundToPlayPath, "surftimer/%s", szSoundToPlayPath);
				}

				EmitSoundToClient(i, szSoundToPlayPath, i);
			}
		}
	}
	else {
		if ( g_bEnableQuakeSounds[client] ) {
			char szSoundToPlayPath[PLATFORM_MAX_PATH];
			g_Sounds.GetString(g_iClientSounds[client][type], szSoundToPlayPath, sizeof szSoundToPlayPath);

			//IF NONE IS SELECTED JUST SKIP TO NEXT
			if ( StrContains(szSoundToPlayPath, "none", false) != -1 ) {
				return;
			}

			//IF SOUND BEING USED IS A DEFAULT SOUND
			if ( StrContains(szSoundToPlayPath, "wav", false) != -1 ) {
				if ( StrContains(szSoundToPlayPath, "button", false) != -1 )
					Format(szSoundToPlayPath, sizeof szSoundToPlayPath, "buttons/%s", szSoundToPlayPath);
				else
					Format(szSoundToPlayPath, sizeof szSoundToPlayPath, "physics/glass/%s", szSoundToPlayPath);
			}
			//IF SOUND BEING USED IS A CUSTOM SOUND
			else {
				Format(szSoundToPlayPath, sizeof szSoundToPlayPath, "surftimer/%s", szSoundToPlayPath);
			}

			EmitSoundToClient(client, szSoundToPlayPath, client);
		}
	}
}

public Action Client_Sounds(int client, int args)
{
	QuakeSounds(client);
	if (g_bEnableQuakeSounds[client])
		CPrintToChat(client, "%t", "QuakeSounds1", g_szChatPrefix);
	else
		CPrintToChat(client, "%t", "QuakeSounds2", g_szChatPrefix);
	return Plugin_Handled;
}

void QuakeSounds(int client, bool menu = false)
{
	g_bEnableQuakeSounds[client] = !g_bEnableQuakeSounds[client];
	if (menu)
		SoundOptions(client);
}

/////
//MENU
/////
public void SoundOptions(int client)
{
	Menu menu = CreateMenu(SoundOptionsHandler);
	SetMenuTitle(menu, "Options Menu - Sound\n \n");

	// Timer Sounds
	if (g_bEnableQuakeSounds[client])
		AddMenuItem(menu, "", "[ON] Timer Sounds\n \n");
	else
		AddMenuItem(menu, "", "[OFF] Timer Sounds");

	AddMenuItem(menu, "", "Custom Sounds");

	SetMenuPagination(menu, 5);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int SoundOptionsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0: QuakeSounds(param1, true);
			case 1: CustomSoundsOptions(param1);
		}
	}
	else if (action == MenuAction_Cancel)
		OptionMenu(param1);
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}


/////
//CUSTOM SOUNDS MENU
/////
public void CustomSoundsOptions(int client)
{
	Menu menu = CreateMenu(CustomSoundsOptionsHandler);
	SetMenuTitle(menu, "Sounds Menu - Custom Sounds\n \n");

	char szItem[32];
	char szItem_Split[32];
	for (int i = 0; i < SOUND_EVENTS; i++)
	{
		g_Sounds.GetString(g_iClientSounds[client][i], szItem, sizeof szItem);
		SplitString(szItem, ".", szItem_Split, sizeof szItem_Split);
		Format(szItem, sizeof szItem, "%s : %s ", g_szCustomSoundsNames[i], szItem_Split);
		AddMenuItem(menu, "", szItem);
	}

	SetMenuPagination(menu, 5);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int CustomSoundsOptionsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		NextSound(param1, param2);
		CustomSoundsOptions(param1);
	}
	else if (action == MenuAction_Cancel)
		SoundOptions(param1);
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

public void NextSound(int client, int sound_index)
{
	if ( g_iClientSounds[client][sound_index] < SOUNDS_COUNT -1 )
		g_iClientSounds[client][sound_index]++;
	else
		g_iClientSounds[client][sound_index] = 0;
}