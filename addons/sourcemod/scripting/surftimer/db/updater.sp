public void CheckDatabaseForUpdates()
{
    // If tables haven't been created yet.
    if (!SQL_FastQuery(g_hDb, "SELECT steamid FROM ck_playerrank LIMIT 1"))
    {
        SQL_UnlockDatabase(g_hDb);
        db_createTables();
        return;
    }
    else
    {
        // Check for db upgrades
        if (!SQL_FastQuery(g_hDb, "SELECT prespeed FROM ck_zones LIMIT 1"))
        {
            db_upgradeDatabase(0);
            return;
        }
        else if(!SQL_FastQuery(g_hDb, "SELECT ranked FROM ck_maptier LIMIT 1") || !SQL_FastQuery(g_hDb, "SELECT style FROM ck_playerrank LIMIT 1;"))
        {
            db_upgradeDatabase(1);
            return;
        }
        else if (!SQL_FastQuery(g_hDb, "SELECT wrcppoints FROM ck_playerrank LIMIT 1"))
        {
            db_upgradeDatabase(2);
            return;
        }
        else if (!SQL_FastQuery(g_hDb, "SELECT teleside FROM ck_playeroptions2 LIMIT 1"))
        {
            db_upgradeDatabase(3);
            return;
        }
        else if (!SQL_FastQuery(g_hDb, "SELECT steamid FROM ck_prinfo  LIMIT 1"))
        {
            db_upgradeDatabase(4);
            return;
        }
        else if (!SQL_FastQuery(g_hDb, "SELECT csd_update_rate FROM ck_playeroptions2 LIMIT 1"))
        {
            db_upgradeDatabase(5);
            return;
        }
        else if(!SQL_FastQuery(g_hDb, "SELECT mapname FROM ck_replays LIMIT 1"))
        {
            db_upgradeDatabase(6);
            return;
        }
        else if(!SQL_FastQuery(g_hDb, "SELECT cp FROM ck_ccp LIMIT 1"))
        {
            db_upgradeDatabase(7);
            return;
        }
        else if(!SQL_FastQuery(g_hDb, "SELECT custom_type FROM ck_playeroptions2 LIMIT 1"))
        {
            db_upgradeDatabase(8);
            return;
        }
        if (!SQL_FastQuery(g_hDb, "SELECT timestamp FROM ck_bonus LIMIT 1"))
        {
            db_upgradeDatabase(9);
            return;
        }
        LogMessage("Version 9 looks good.");
    }
}

public void db_upgradeDatabase(int ver)
{
    if (ver == 0)
    {
        // SurfTimer v2.01 -> SurfTimer v2.1
        char query[128];
        for (int i = 1; i < 11; i++)
        {
            Format(query, sizeof(query), "ALTER TABLE ck_maptier DROP COLUMN btier%i", i);
            SQL_FastQuery(g_hDb, query);
        }

        SQL_FastQuery(g_hDb, "ALTER TABLE ck_maptier ADD COLUMN maxvelocity FLOAT NOT NULL DEFAULT '3500.0';");
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_maptier ADD COLUMN announcerecord INT(11) NOT NULL DEFAULT '0';");
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_maptier ADD COLUMN gravityfix INT(11) NOT NULL DEFAULT '1';");
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_zones ADD COLUMN `prespeed` int(64) NOT NULL DEFAULT '350';");
        SQL_FastQuery(g_hDb, "CREATE INDEX tier ON ck_maptier (mapname, tier);");
        SQL_FastQuery(g_hDb, "CREATE INDEX mapsettings ON ck_maptier (mapname, maxvelocity, announcerecord, gravityfix);");
        SQL_FastQuery(g_hDb, "UPDATE ck_maptier a, ck_mapsettings b SET a.maxvelocity = b.maxvelocity WHERE a.mapname = b.mapname;");
        SQL_FastQuery(g_hDb, "UPDATE ck_maptier a, ck_mapsettings b SET a.announcerecord = b.announcerecord WHERE a.mapname = b.mapname;");
        SQL_FastQuery(g_hDb, "UPDATE ck_maptier a, ck_mapsettings b SET a.gravityfix = b.gravityfix WHERE a.mapname = b.mapname;");
        SQL_FastQuery(g_hDb, "UPDATE ck_zones a, ck_mapsettings b SET a.prespeed = b.startprespeed WHERE a.mapname = b.mapname AND zonetype = 1;");
        SQL_FastQuery(g_hDb, "DROP TABLE ck_mapsettings;");
    }
    else if (ver == 1)
    {
    // SurfTimer v2.1 -> v2.2
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_maptier ADD COLUMN ranked INT(11) NOT NULL DEFAULT '1';");
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_playerrank DROP PRIMARY KEY, ADD COLUMN style INT(11) NOT NULL DEFAULT '0', ADD PRIMARY KEY (steamid, style);");
    }
    else if (ver == 2)
    {
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_playerrank ADD COLUMN wrcppoints INT(11) NOT NULL DEFAULT 0 AFTER `wrbpoints`;");
    }
    else if (ver == 3)
    {
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_playeroptions2 ADD COLUMN teleside INT(11) NOT NULL DEFAULT 0 AFTER centrehud;");
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_spawnlocations DROP PRIMARY KEY, ADD COLUMN teleside INT(11) NOT NULL DEFAULT 0 AFTER stage, ADD PRIMARY KEY (mapname, zonegroup, stage, teleside);");
    }
    else if (ver == 4)
    {
        SQL_FastQuery(g_hDb, sql_CreatePrinfo);
    }
    else if (ver == 5)
    {
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_playeroptions2 ADD csd_update_rate int(11) NOT NULL DEFAULT '1', ADD csd_pos_x float(11) NOT NULL DEFAULT '0.5', ADD csd_pos_y float(11) NOT NULL DEFAULT '0.3', ADD csd_r int(11) NOT NULL DEFAULT '255', ADD csd_g int(11) NOT NULL DEFAULT '255', ADD csd_b int(11) NOT NULL DEFAULT '255';");
    }
    else if (ver == 6)
    {
        SQL_FastQuery(g_hDb, sql_createReplays);
    }
    else if (ver == 7)
    {
        SQL_FastQuery(g_hDb, sql_createCCP);
    }
    else if (ver == 8)
    {
        SQL_FastQuery(g_hDb, "ALTER TABLE ck_playeroptions2 ADD COLUMN custom_type INT(11) NOT NULL DEFAULT '1';");
    }
    else if (ver == 9)
    {
        SQL_FastQuery(g_hDb, "ALTER TABLE `ck_bonus` ADD `timestamp` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;");
        SQL_FastQuery(g_hDb, "ALTER TABLE `ck_playertimes` ADD `timestamp` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;");
        SQL_FastQuery(g_hDb, "ALTER TABLE `ck_wrcps` ADD `timestamp` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;");
    }

    CheckDatabaseForUpdates();
}