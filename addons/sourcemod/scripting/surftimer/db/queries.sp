/////////////////////////
// PREPARED STATEMENTS //
////////////////////////

//MAIN QUERIES
char sql_MainEditQuery[] = "SELECT steamid, name, %s FROM %s where mapname='%s' and style='%i' %sORDER BY %s ASC LIMIT 50";
char sql_MainDeleteQeury[] = "DELETE From %s where mapname='%s' and style='%i' and steamid='%s' %s";

// ck_announcements
char sql_createAnnouncements[] = "CREATE TABLE `ck_announcements` (`id` int(11) NOT NULL AUTO_INCREMENT, `server` varchar(256) NOT NULL DEFAULT 'Beginner', `name` varchar(32) NOT NULL, `mapname` varchar(128) NOT NULL, `mode` int(11) NOT NULL DEFAULT '0', `time` varchar(32) NOT NULL, `group` int(12) NOT NULL DEFAULT '0', PRIMARY KEY (`id`))DEFAULT CHARSET=utf8mb4;";

// ck_bonus
char sql_createBonus[] = "CREATE TABLE IF NOT EXISTS ck_bonus (steamid VARCHAR(32), name VARCHAR(32), mapname VARCHAR(32), runtime FLOAT NOT NULL DEFAULT '-1.0', velStartXY SMALLINT(6) NOT NULL DEFAULT 0, velStartXYZ SMALLINT(6) NOT NULL DEFAULT 0, velStartZ SMALLINT(6) NOT NULL DEFAULT 0, zonegroup INT(12) NOT NULL DEFAULT 1, style INT(11) NOT NULL DEFAULT 0, PRIMARY KEY(steamid, mapname, zonegroup, style)) DEFAULT CHARSET=utf8mb4;";
char sql_createBonusIndex[] = "CREATE INDEX bonusrank ON ck_bonus (mapname,runtime,zonegroup,style);";
char sql_insertBonus[] = "INSERT INTO ck_bonus (steamid, name, mapname, runtime, zonegroup, velStartXY, velStartXYZ, velStartZ) VALUES ('%s', '%s', '%s', '%f', '%i', '%i', '%i', '%i')";
char sql_updateBonus[] = "UPDATE ck_bonus SET runtime = '%f', name = '%s', velStartXY = %i, velStartXYZ = %i, velStartZ = %i WHERE steamid = '%s' AND mapname = '%s' AND zonegroup = %i AND style = 0";
char sql_selectBonusCount[] = "SELECT zonegroup, style, count(1) FROM ck_bonus WHERE mapname = '%s' GROUP BY zonegroup, style;";
char sql_selectPersonalBonusRecords[] = "SELECT runtime, zonegroup, style FROM ck_bonus WHERE steamid = '%s' AND mapname = '%s' AND runtime > '0.0'";
char sql_selectPlayerRankBonus[] = "SELECT name FROM ck_bonus WHERE runtime <= (SELECT runtime FROM ck_bonus WHERE steamid = '%s' AND mapname= '%s' AND runtime > 0.0 AND zonegroup = %i AND style = 0) AND mapname = '%s' AND zonegroup = %i AND style = 0;";
char sql_selectFastestBonus[] = "SELECT t1.name, t1.runtime, t1.zonegroup, t1.style, t1.velStartXY, t1.velStartXYZ, t1.velstartZ from ck_bonus t1 where t1.mapname = '%s' and t1.runtime = (select min(t2.runtime) from ck_bonus t2 where t2.mapname = t1.mapname and t2.zonegroup = t1.zonegroup and t2.style = t1.style);";
char sql_deleteBonus[] = "DELETE FROM ck_bonus WHERE mapname = '%s'";
char sql_selectAllBonusTimesinMap[] = "SELECT zonegroup, runtime from ck_bonus WHERE mapname = '%s';";
char sql_selectTopBonusSurfers[] = "SELECT db2.steamid, db1.name, db2.runtime as overall, db1.steamid, db2.mapname FROM ck_bonus as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.mapname = '%s' AND db2.style = %i AND db1.style = %i AND db2.runtime > -1.0 AND zonegroup = %i ORDER BY overall ASC LIMIT 100;";

// ck_checkpoints
char sql_createCheckpoints[] = "CREATE TABLE IF NOT EXISTS ck_checkpoints (steamid VARCHAR(32), mapname VARCHAR(32), cp INT(11) NOT NULL, time decimal(12,6) NOT NULL DEFAULT '-1.000000', stage_time decimal(12,6) NOT NULL DEFAULT '-1.000000', stage_attempts INT NOT NULL DEFAULT '0', zonegroup INT(12) NOT NULL DEFAULT 0, PRIMARY KEY(steamid, mapname, cp, zonegroup)) DEFAULT CHARSET=utf8mb4;";
char sql_updateCheckpoints[] = "UPDATE ck_checkpoints SET time='%f', speed='%f' WHERE steamid='%s' AND mapname='%s' AND cp ='%i' AND zonegroup='%i';";
char sql_insertCheckpoints[] = "INSERT INTO ck_checkpoints (steamid, mapname, cp, time, speed, zonegroup) VALUES ('%s', '%s', '%i', '%f', '%f', '%i')";
char sql_selectCheckpoints[] = "SELECT zonegroup, cp, time FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s';";
char sql_selectCheckpointsinZoneGroup[] = "SELECT cp, time FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s' AND zonegroup = %i;";

char sql_selectRecordCheckpoints[] = "SELECT zonegroup, cp, `time` FROM ck_checkpoints WHERE steamid = '%s' AND mapname='%s' UNION SELECT a.zonegroup, b.cp, b.time FROM ck_bonus a LEFT JOIN ck_checkpoints b ON a.steamid = b.steamid AND a.zonegroup = b.zonegroup WHERE a.mapname = '%s' GROUP BY a.zonegroup;";
char sql_selectRecordCheckpointSpeeds[] = "SELECT zonegroup, cp, speed FROM ck_checkpoints WHERE mapname = '%s' AND steamid = (SELECT steamid FROM ck_playertimes WHERE mapname = '%s' AND style = '0' ORDER BY runtimepro LIMIT 1);";
char sql_selectCheckpointSpeedsinZoneGroup[] = "SELECT cp, speed FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s' AND zonegroup = %i;";

char sql_selectCheckpointsTimesType[] = "SELECT cp, time FROM ck_checkpoints WHERE mapname = '%s' AND steamid = (SELECT steamid FROM ck_playertimes WHERE mapname = '%s' AND style = '0' ORDER BY runtimepro LIMIT %i,1);";
char sql_selectCheckpointsSpeedsType[] = "SELECT cp, speed FROM ck_checkpoints WHERE mapname = '%s' AND steamid = (SELECT steamid FROM ck_playertimes WHERE mapname = '%s' AND style = '0' ORDER BY runtimepro LIMIT %i,1);";

char sql_selectCheckpointsSpeeds[] = "SELECT cp, speed FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s';";
char sql_deleteCheckpoints[] = "DELETE FROM ck_checkpoints WHERE mapname = '%s'";


// ck_latestrecords
char sql_createLatestRecords[] = "CREATE TABLE IF NOT EXISTS ck_latestrecords (steamid VARCHAR(32), name VARCHAR(32), runtime FLOAT NOT NULL DEFAULT '-1.0', map VARCHAR(32), date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(steamid,map,date)) DEFAULT CHARSET=utf8mb4;";
char sql_insertLatestRecords[] = "INSERT INTO ck_latestrecords (steamid, name, runtime, map) VALUES('%s','%s','%f','%s');";
char sql_selectLatestRecords[] = "SELECT name, runtime, map, date FROM ck_latestrecords ORDER BY date DESC LIMIT 50";

// ck_maptier
char sql_createMapTier[] = "CREATE TABLE IF NOT EXISTS ck_maptier (mapname VARCHAR(54) NOT NULL, tier INT(12), maxvelocity FLOAT NOT NULL DEFAULT '3500.0', announcerecord INT(11) NOT NULL DEFAULT '0', gravityfix INT(11) NOT NULL DEFAULT '1', ranked INT(11) NOT NULL DEFAULT '1', PRIMARY KEY(mapname)) DEFAULT CHARSET=utf8mb4;";
char sql_selectMapTier[] = "SELECT tier, ranked FROM ck_maptier WHERE mapname = '%s'";
char sql_insertmaptier[] = "INSERT INTO ck_maptier (mapname, tier) VALUES ('%s', '%i');";
char sql_updatemaptier[] = "UPDATE ck_maptier SET tier = %i WHERE mapname ='%s'";

// ck_playeroptions2
char sql_createPlayerOptions[] = "CREATE TABLE `ck_playeroptions2` (`steamid` varchar(32) NOT NULL DEFAULT '', `timer` int(11) NOT NULL DEFAULT '1', `hide` int(11) NOT NULL DEFAULT '0', `sounds` int(11) NOT NULL DEFAULT '1', `chat` int(11) NOT NULL DEFAULT '0', `viewmodel` int(11) NOT NULL DEFAULT '1', `autobhop` int(11) NOT NULL DEFAULT '1', `checkpoints` int(11) NOT NULL DEFAULT '1', `gradient` int(11) NOT NULL DEFAULT '3', `speedmode` int(11) NOT NULL DEFAULT '0', `centrespeed` int(11) NOT NULL DEFAULT '0', `centrehud` int(11) NOT NULL DEFAULT '1', teleside int(11) NOT NULL DEFAULT '0', `module1c` int(11) NOT NULL DEFAULT '1', `module2c` int(11) NOT NULL DEFAULT '2', `module3c` int(11) NOT NULL DEFAULT '3', `module4c` int(11) NOT NULL DEFAULT '4', `module5c` int(11) NOT NULL DEFAULT '5', `module6c` int(11) NOT NULL DEFAULT '6', `sidehud` int(11) NOT NULL DEFAULT '1', `module1s` int(11) NOT NULL DEFAULT '5', `module2s` int(11) NOT NULL DEFAULT '0', `module3s` int(11) NOT NULL DEFAULT '0', `module4s` int(11) NOT NULL DEFAULT '0', `module5s` int(11) NOT NULL DEFAULT '0', prestrafe int(11) NOT NULL DEFAULT '0', cpmessages int(11) NOT NULL DEFAULT '1', wrcpmessages int(11) NOT NULL DEFAULT '1', hints int(11) NOT NULL DEFAULT '1', showtime int(11) NOT NULL DEFAULT '1' , csd_update_rate int(11) NOT NULL DEFAULT '1' , csd_pos_x float(11) NOT NULL DEFAULT '0.5' , csd_pos_y float(11) NOT NULL DEFAULT '0.3' , csd_r int(11) NOT NULL DEFAULT '255', csd_g int(11) NOT NULL DEFAULT '255', csd_b int(11) NOT NULL DEFAULT '255', PRIMARY KEY (`steamid`)) DEFAULT CHARSET=utf8mb4;";
char sql_insertPlayerOptions[] = "INSERT INTO ck_playeroptions2 (steamid) VALUES ('%s');";
char sql_selectPlayerOptions[] = "SELECT timer, hide, sounds, chat, viewmodel, autobhop, checkpoints, gradient, speedmode, centrespeed, centrehud, teleside, module1c, module2c, module3c, module4c, module5c, module6c, sidehud, module1s, module2s, module3s, module4s, module5s, prestrafe, prespeedmode, cpmessages, wrcpmessages, hints, showtime, csd_update_rate, csd_pos_x, csd_pos_y, csd_r, csd_g, csd_b, custom_type FROM ck_playeroptions2 where steamid = '%s';";
char sql_updatePlayerOptions[] = "UPDATE ck_playeroptions2 SET timer = %i, hide = %i, sounds = %i, chat = %i, viewmodel = %i, autobhop = %i, checkpoints = %i, gradient = %i, speedmode = %i, centrespeed = %i, centrehud = %i, teleside = %i, module1c = %i, module2c = %i, module3c = %i, module4c = %i, module5c = %i, module6c = %i, sidehud = %i, module1s = %i, module2s = %i, module3s = %i, module4s = %i, module5s = %i, prestrafe = %i, prespeedmode = %i, cpmessages = %i, wrcpmessages = %i, hints = %i, showtime = %i, csd_update_rate = %i, csd_pos_x = %f, csd_pos_y = %f, csd_r= %i, csd_g = %i, csd_b = %i, custom_type = '%i where steamid = '%s'";

// ck_playerrank
char sql_createPlayerRank[] = "CREATE TABLE IF NOT EXISTS `ck_playerrank` (`steamid` varchar(32) NOT NULL DEFAULT '', `steamid64` varchar(64) DEFAULT NULL, `name` varchar(32) DEFAULT NULL, `country` varchar(32) DEFAULT NULL, `points` int(12) DEFAULT '0', `wrpoints` int(12) NOT NULL DEFAULT '0', `wrbpoints` int(12) NOT NULL DEFAULT '0', `wrcppoints` int(11) NOT NULL DEFAULT '0', `top10points` int(12) NOT NULL DEFAULT '0', `groupspoints` int(12) NOT NULL DEFAULT '0', `mappoints` int(11) NOT NULL DEFAULT '0', `bonuspoints` int(12) NOT NULL DEFAULT '0', `finishedmaps` int(12) DEFAULT '0', `finishedmapspro` int(12) DEFAULT '0', `finishedbonuses` int(12) NOT NULL DEFAULT '0', `finishedstages` int(12) NOT NULL DEFAULT '0', `wrs` int(12) NOT NULL DEFAULT '0', `wrbs` int(12) NOT NULL DEFAULT '0', `wrcps` int(12) NOT NULL DEFAULT '0', `top10s` int(12) NOT NULL DEFAULT '0', `groups` int(12) NOT NULL DEFAULT '0', `lastseen` int(64) DEFAULT NULL, `joined` int(64) NOT NULL, `timealive` int(64) NOT NULL DEFAULT '0', `timespec` int(64) NOT NULL DEFAULT '0', `connections` int(64) NOT NULL DEFAULT '1', `readchangelog` int(11) NOT NULL DEFAULT '0', `style` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`steamid`, `style`)) DEFAULT CHARSET=utf8mb4;";
char sql_insertPlayerRank[] = "INSERT INTO ck_playerrank (steamid, steamid64, name, country, joined, style) VALUES('%s', '%s', '%s', '%s', %i, %i)";
char sql_updatePlayerRankPoints[] = "UPDATE ck_playerrank SET name ='%s', points ='%i', wrpoints = %i, wrbpoints = %i, wrcppoints = %i, top10points = %i, groupspoints = %i, mappoints = %i, bonuspoints = %i, finishedmapspro='%i', finishedbonuses = %i, finishedstages = %i, wrs = %i, wrbs = %i, wrcps = %i, top10s = %i, `groups` = %i where steamid='%s' AND style = %i;";
char sql_updatePlayerRankPoints2[] = "UPDATE ck_playerrank SET name ='%s', points ='%i', wrpoints = %i, wrbpoints = %i, wrcppoints = %i, top10points = %i, groupspoints = %i, mappoints = %i, bonuspoints = %i, finishedmapspro='%i', finishedbonuses = %i, finishedstages = %i, wrs = %i, wrbs = %i, wrcps = %i, top10s = %i, `groups` = %i, country = '%s' where steamid='%s' AND style = %i;";
char sql_updatePlayerRank[] = "UPDATE ck_playerrank SET finishedmaps ='%i', finishedmapspro='%i' where steamid='%s' AND style = '%i';";
char sql_selectPlayerName[] = "SELECT name FROM ck_playerrank where steamid = '%s'";
char sql_UpdateLastSeenMySQL[] = "UPDATE ck_playerrank SET lastseen = UNIX_TIMESTAMP() where steamid = '%s';";
char sql_UpdateLastSeenSQLite[] = "UPDATE ck_playerrank SET lastseen = date('now') where steamid = '%s';";
char sql_selectTopPlayers[] = "SELECT name, points, finishedmapspro, steamid FROM ck_playerrank WHERE style = %i ORDER BY points DESC LIMIT 100";
char sql_selectRankedPlayer[] = "SELECT steamid, name, points, finishedmapspro, country, lastseen, timealive, timespec, connections, readchangelog, style from ck_playerrank where steamid='%s';";
char sql_selectRankedPlayersRank[] = "SELECT name FROM ck_playerrank WHERE style = %i AND points >= (SELECT points FROM ck_playerrank WHERE steamid = '%s' AND style = %i) ORDER BY points;";
char sql_selectRankedPlayers[] = "SELECT steamid, name from ck_playerrank where points > 0 AND style = 0 ORDER BY points DESC LIMIT 0, 1067;";
char sql_CountRankedPlayers[] = "SELECT COUNT(steamid) FROM ck_playerrank WHERE style = %i;";
char sql_CountRankedPlayers2[] = "SELECT COUNT(steamid) FROM ck_playerrank where points > 0 AND style = %i;";
char sql_selectPlayerProfile[] = "SELECT steamid, steamid64, name, country, points, wrpoints, wrbpoints, wrcppoints, top10points, groupspoints, mappoints, bonuspoints, finishedmapspro, finishedbonuses, finishedstages, wrs, wrbs, wrcps, top10s, `groups`, lastseen FROM ck_playerrank WHERE steamid = '%s' AND style = '%i';";

// ck_playertemp
char sql_createPlayertmp[] = "CREATE TABLE IF NOT EXISTS ck_playertemp (steamid VARCHAR(32), mapname VARCHAR(32), cords1 FLOAT NOT NULL DEFAULT '-1.0', cords2 FLOAT NOT NULL DEFAULT '-1.0', cords3 FLOAT NOT NULL DEFAULT '-1.0', angle1 FLOAT NOT NULL DEFAULT '-1.0',angle2 FLOAT NOT NULL DEFAULT '-1.0',angle3 FLOAT NOT NULL DEFAULT '-1.0', EncTickrate INT(12) DEFAULT '-1.0', runtimeTmp FLOAT NOT NULL DEFAULT '-1.0', Stage INT, zonegroup INT NOT NULL DEFAULT 0, PRIMARY KEY(steamid,mapname)) DEFAULT CHARSET=utf8mb4;";
char sql_insertPlayerTmp[] = "INSERT INTO ck_playertemp (cords1, cords2, cords3, angle1,angle2,angle3,runtimeTmp,steamid,mapname,EncTickrate,Stage,zonegroup) VALUES ('%f','%f','%f','%f','%f','%f','%f','%s', '%s', '%i', %i, %i);";
char sql_updatePlayerTmp[] = "UPDATE ck_playertemp SET cords1 = '%f', cords2 = '%f', cords3 = '%f', angle1 = '%f', angle2 = '%f', angle3 = '%f', runtimeTmp = '%f', mapname ='%s', EncTickrate='%i', Stage = %i, zonegroup = %i WHERE steamid = '%s';";
char sql_deletePlayerTmp[] = "DELETE FROM ck_playertemp where steamid = '%s';";
char sql_selectPlayerTmp[] = "SELECT cords1,cords2,cords3, angle1, angle2, angle3,runtimeTmp, EncTickrate, Stage, zonegroup FROM ck_playertemp WHERE steamid = '%s' AND mapname = '%s';";

// ck_playertimes
char sql_createPlayertimes[] = "CREATE TABLE IF NOT EXISTS ck_playertimes (steamid VARCHAR(32), mapname VARCHAR(32), name VARCHAR(32), runtimepro FLOAT NOT NULL DEFAULT '-1.0', velStartXY SMALLINT(6) NOT NULL DEFAULT 0, velStartXYZ SMALLINT(6) NOT NULL DEFAULT 0, velStartZ SMALLINT(6) NOT NULL DEFAULT 0, style INT(11) NOT NULL DEFAULT '0', PRIMARY KEY(steamid, mapname, style)) DEFAULT CHARSET=utf8mb4;";
char sql_createPlayertimesIndex[] = "CREATE INDEX maprank ON ck_playertimes (mapname, runtimepro, style);";
char sql_insertPlayer[] = "INSERT INTO ck_playertimes (steamid, mapname, name) VALUES('%s', '%s', '%s');";
char sql_insertPlayerTime[] = "INSERT INTO ck_playertimes (steamid, mapname, name, runtimepro, style, velStartXY, velStartXYZ, velStartZ) VALUES('%s', '%s', '%s', '%f', %i, %i, %i, %i);";
char sql_updateRecordPro[] = "UPDATE ck_playertimes SET name = '%s', runtimepro = '%f', velStartXY = '%i', velStartXYZ = '%i', velStartZ = '%i' WHERE steamid = '%s' AND mapname = '%s' AND style = %i;";
char sql_selectPlayer[] = "SELECT steamid FROM ck_playertimes WHERE steamid = '%s' AND mapname = '%s';";
char sql_selectMapRecord[] = "SELECT t1.runtimepro, t1.name, t1.steamid, t1.style, t1.velStartXY, t1.velStartXYZ, t1.velstartZ FROM ck_playertimes t1 JOIN ( SELECT MIN(runtimepro) AS min_runtime, style, mapname FROM ck_playertimes GROUP BY mapname, style ) AS t2 ON t1.runtimepro = t2.min_runtime AND t1.mapname = t2.mapname AND t1.style = t2.style WHERE t1.mapname = '%s'";
char sql_selectPersonalAllRecords[] = "SELECT db1.name, db2.steamid, db2.mapname, db2.runtimepro as overall, db1.steamid, db3.tier FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid INNER JOIN ck_maptier AS db3 ON db2.mapname = db3.mapname WHERE db2.steamid = '%s' AND db2.style = %i AND db1.style = %i AND db2.runtimepro > -1.0 ORDER BY mapname ASC;";
char sql_selectTopSurfers[] = "SELECT db2.steamid, db1.name, db2.runtimepro as overall, db1.steamid, db2.mapname FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.mapname = '%s' AND db1.style = %i AND db2.style = %i AND db2.runtimepro > -1.0 ORDER BY overall ASC LIMIT 50;";
char sql_selectTopSurfers2[] = "SELECT db2.steamid, db1.name, db2.runtimepro as overall, db1.steamid, db2.mapname FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.mapname = '%s' AND db1.style = 0 AND db2.style = 0 AND db2.runtimepro > -1.0 ORDER BY overall ASC LIMIT 100;";
char sql_selectPlayerProCount[] = "SELECT style, count(1) FROM ck_playertimes WHERE mapname = '%s' GROUP BY style;";
char sql_selectPlayerRankProTime[] = "SELECT COUNT(*) FROM ck_playertimes WHERE runtimepro <= (SELECT runtimepro FROM ck_playertimes WHERE steamid = '%s' AND mapname = '%s' AND style = 0 AND runtimepro > -1.0) AND mapname = '%s' AND style = 0 AND runtimepro > -1.0;";
char sql_selectAllMapTimesinMap[] = "SELECT runtimepro from ck_playertimes WHERE mapname = '%s';";

char sql_selectGroupRuntimes[] = "SELECT runtimepro FROM ck_playertimes WHERE mapname = '%s' AND style = 0 AND steamid = (SELECT steamid FROM ck_playertimes WHERE mapname = '%s' AND style = '0' ORDER BY runtimepro LIMIT %i,1);";



char sql_selectMapRankUnknownWithMap[] = "SELECT `steamid`, `name`, `mapname`, `runtimepro` FROM `ck_playertimes` WHERE `mapname` = '%s' AND style = 0 ORDER BY `runtimepro` ASC LIMIT %i, 1;";

// ck_spawnlocations
char sql_createSpawnLocations[] = "CREATE TABLE IF NOT EXISTS ck_spawnlocations (mapname VARCHAR(54) NOT NULL, pos_x FLOAT NOT NULL, pos_y FLOAT NOT NULL, pos_z FLOAT NOT NULL, ang_x FLOAT NOT NULL, ang_y FLOAT NOT NULL, ang_z FLOAT NOT NULL,  `vel_x` float NOT NULL DEFAULT '0', `vel_y` float NOT NULL DEFAULT '0', `vel_z` float NOT NULL DEFAULT '0', zonegroup INT(12) DEFAULT 0, stage INT(12) DEFAULT 0, teleside INT(11) DEFAULT 0, PRIMARY KEY(mapname, zonegroup, stage, teleside)) DEFAULT CHARSET=utf8mb4;";
char sql_insertSpawnLocations[] = "INSERT INTO ck_spawnlocations (mapname, pos_x, pos_y, pos_z, ang_x, ang_y, ang_z, vel_x, vel_y, vel_z, zonegroup, teleside) VALUES ('%s', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', %i, %i);";
char sql_updateSpawnLocations[] = "UPDATE ck_spawnlocations SET pos_x = '%f', pos_y = '%f', pos_z = '%f', ang_x = '%f', ang_y = '%f', ang_z = '%f', vel_x = '%f', vel_y = '%f', vel_z = '%f' WHERE mapname = '%s' AND zonegroup = %i AND teleside = %i;";
char sql_selectSpawnLocations[] = "SELECT mapname, pos_x, pos_y, pos_z, ang_x, ang_y, ang_z, vel_x, vel_y, vel_z, zonegroup, stage, teleside FROM ck_spawnlocations WHERE mapname ='%s';";
char sql_deleteSpawnLocations[] = "DELETE FROM ck_spawnlocations WHERE mapname = '%s' AND zonegroup = %i AND stage = 1 AND teleside = %i;";

// ck_vipadmins (should rename this table..)
char sql_createVipAdmins[] = "CREATE TABLE `ck_vipadmins` (`steamid` varchar(32) NOT NULL DEFAULT '', `title` varchar(128) DEFAULT '0', `namecolour` int(11) DEFAULT '0', `textcolour` int(11) NOT NULL DEFAULT '0', `joinmsg` varchar(255) DEFAULT 'none', `pbsound` varchar(256) NOT NULL DEFAULT 'none', `topsound` varchar(256) NOT NULL DEFAULT 'none', `wrsound` varchar(256) NOT NULL DEFAULT 'none', `inuse` int(11) DEFAULT '0', `vip` int(11) DEFAULT '0', `admin` int(11) NOT NULL DEFAULT '0', `zoner` int(11) NOT NULL DEFAULT '0', `active` int(11) NOT NULL DEFAULT '1', PRIMARY KEY (`steamid`), KEY `vip` (`steamid`,`vip`,`admin`,`zoner`)) DEFAULT CHARSET=utf8mb4;";

// ck_wrcps
char sql_createWrcps[] = "CREATE TABLE IF NOT EXISTS `ck_wrcps` (`steamid` varchar(32) NOT NULL DEFAULT '', `name` varchar(32) DEFAULT NULL, `mapname` varchar(32) NOT NULL DEFAULT '', `runtimepro` float NOT NULL DEFAULT '-1', `velStartXY` smallint(6) NOT NULL DEFAULT 0, `velStartXYZ` smallint(6) NOT NULL DEFAULT 0, `velStartZ` smallint(6) NOT NULL DEFAULT 0, `stage` int(11) NOT NULL, `style` int(11) NOT NULL DEFAULT '0', PRIMARY KEY (`steamid`,`mapname`,`stage`,`style`), KEY `stagerank` (`mapname`,`runtimepro`,`stage`,`style`)) DEFAULT CHARSET=utf8mb4;";


// ck_zones
char sql_createZones[] = "CREATE TABLE `ck_zones` (`mapname` varchar(54) NOT NULL, `zoneid` int(12) NOT NULL DEFAULT '-1', `zonetype` int(12) DEFAULT '-1', `zonetypeid` int(12) DEFAULT '-1', `pointa_x` float DEFAULT '-1', `pointa_y` float DEFAULT '-1', `pointa_z` float DEFAULT '-1', `pointb_x` float DEFAULT '-1', `pointb_y` float DEFAULT '-1', `pointb_z` float DEFAULT '-1', `vis` int(12) DEFAULT '0', `team` int(12) DEFAULT '0', `zonegroup` int(11) NOT NULL DEFAULT '0', `zonename` varchar(128) DEFAULT NULL, `hookname` varchar(128) DEFAULT 'None', `targetname` varchar(128) DEFAULT 'player', `onejumplimit` int(12) NOT NULL DEFAULT '1', `prespeed` int(64) NOT NULL DEFAULT '250.0', PRIMARY KEY (`mapname`,`zoneid`)) DEFAULT CHARSET=utf8mb4;";
char sql_insertZones[] = "INSERT INTO ck_zones (mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename, hookname, targetname, onejumplimit, prespeed) VALUES ('%s', '%i', '%i', '%i', '%f', '%f', '%f', '%f', '%f', '%f', '%i', '%i', '%i','%s','%s','%s',%i,%f)";
char sql_updateZone[] = "UPDATE ck_zones SET zonetype = '%i', zonetypeid = '%i', pointa_x = '%f', pointa_y ='%f', pointa_z = '%f', pointb_x = '%f', pointb_y = '%f', pointb_z = '%f', vis = '%i', team = '%i', onejumplimit = '%i', prespeed = '%f', hookname = '%s', targetname = '%s', zonegroup = '%i' WHERE zoneid = '%i' AND mapname = '%s'";
char sql_selectzoneTypeIds[] = "SELECT zonetypeid FROM ck_zones WHERE mapname='%s' AND zonetype='%i' AND zonegroup = '%i';";
char sql_selectMapZones[] = "SELECT zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename, hookname, targetname, onejumplimit, prespeed FROM ck_zones WHERE mapname = '%s' ORDER BY zonetypeid ASC";
char sql_selectTotalBonusCount[] = "SELECT mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename FROM ck_zones WHERE zonetype = 3 GROUP BY mapname, zonegroup;";
char sql_selectZoneIds[] = "SELECT mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename, hookname, targetname, onejumplimit, prespeed FROM ck_zones WHERE mapname = '%s' ORDER BY zoneid ASC";
char sql_selectBonusesInMap[] = "SELECT mapname, zonegroup, zonename FROM `ck_zones` WHERE mapname LIKE '%c%s%c' AND zonegroup > 0 GROUP BY zonegroup;";
char sql_deleteMapZones[] = "DELETE FROM ck_zones WHERE mapname = '%s'";
char sql_deleteZone[] = "DELETE FROM ck_zones WHERE mapname = '%s' AND zoneid = '%i'";
char sql_deleteZonesInGroup[] = "DELETE FROM ck_zones WHERE mapname = '%s' AND zonegroup = '%i'";
char sql_setZoneNames[] = "UPDATE ck_zones SET zonename = '%s' WHERE mapname = '%s' AND zonegroup = '%i';";

//ck_prinfo 
char sql_CreatePrinfo[] = "CREATE TABLE IF NOT EXISTS ck_prinfo (steamid VARCHAR(32), name VARCHAR(32), mapname VARCHAR(32), runtime FLOAT NOT NULL DEFAULT '0.0', zonegroup INT(12) NOT NULL DEFAULT '0', PRtimeinzone FLOAT NOT NULL DEFAULT '0.0', PRcomplete FLOAT NOT NULL DEFAULT '0.0', PRattempts FLOAT NOT NULL DEFAULT '0.0', PRstcomplete FLOAT NOT NULL DEFAULT '0.0', PRIMARY KEY(steamid, mapname, zonegroup)) DEFAULT CHARSET=utf8mb4;";

char sql_selectPR[] = "SELECT steamid, name, mapname, zonegroup, PRtimeinzone, PRcomplete, PRattempts, PRstcomplete FROM ck_prinfo WHERE steamid = '%s' AND mapname = '%s' AND zonegroup= '%i';";
char sql_insertPR[] = "INSERT INTO ck_prinfo (steamid, name, mapname, runtime, zonegroup, PRtimeinzone, PRcomplete, PRattempts, PRstcomplete) VALUES('%s', '%s', '%s', '%f', '%i', '%f', '%f', '%f', '%f');";

char sql_selectBonusPR[] = "SELECT steamid, name, mapname, zonegroup, PRtimeinzone, PRcomplete, PRattempts, PRstcomplete FROM ck_prinfo WHERE steamid = '%s' AND mapname = '%s' AND zonegroup = '%i';";

char sql_updatePrinfo[] = "UPDATE ck_prinfo SET PRtimeinzone = '%f', PRcomplete = '%f', PRattempts = '%f', PRstcomplete = '%f' WHERE steamid = '%s' AND mapname = '%s' AND zonegroup = '%i';";
char sql_updatePrinfo_withruntime[] = "UPDATE ck_prinfo SET PRtimeinzone = '%f', PRcomplete = '%f', PRattempts = '%f', PRstcomplete = '%f', runtime = '%f' WHERE steamid = '%s' AND mapname = '%s' AND zonegroup = '%i';";

char sql_clearPRruntime[] = "UPDATE ck_prinfo SET runtime = '0.0' WHERE steamid = '%s' AND mapname = '%s' AND zonegroup = '%i';";


//ck_recentlylost
char sql_InsertTrack[] = "INSERT INTO ck_track (steamid, name, mapname, zonegroup, previous_rank, new_rank ) VALUES('%s', '%s', '%s', '%i', '%i', '%i');";
char sql_InsertTrack_All[] = "UPDATE ck_track SET previous_rank = new_rank, new_rank = 999999 WHERE steamid = '%s';";
char sql_GetPlayersToUpdate[] = "SELECT steamid, name, mapname, zonegroup, previous_rank, new_rank FROM ck_track WHERE mapname = '%s' AND zonegroup = '%i' ORDER BY RegDate DESC;";
char sql_GetPlayerWipedRanks[] = "SELECT mapname, zonegroup, previous_rank FROM ck_track WHERE steamid = '%s' AND new_rank = 999999;";
char sql_RecentlyLost[] = "SELECT mapname, zonegroup, previous_rank, new_rank FROM ck_track WHERE previous_rank < new_rank AND previous_rank <> 0 AND steamid = '%s' ORDER BY RegDate DESC LIMIT 50;";
char sql_Tracking[] = "SELECT mapname, zonegroup, previous_rank, new_rank FROM ck_track WHERE steamid = '%s' ORDER BY RegDate DESC LIMIT 50;";
//char sql_RemovePlayerTrack[] = "DELETE FROM ck_track WHERE steamid = '%s' AND mapname = '%s' AND zonegroup = '%i'";
char sql_UpdatePlayersRanks[] = "UPDATE ck_track SET previous_rank = new_rank, new_rank = new_rank - 1 WHERE mapname = '%s' AND zonegroup = '%i' AND new_rank >= %i";

char sql_Poulate_ck_track[] = "SELECT (ROW_NUMBER() OVER(ORDER BY pt.runtimepro)) AS rank_nr, pt.steamid, pt.name, pt.mapname, COALESCE(tr.previous_rank, -1) as prev_rank, COALESCE(tr.new_rank, -1) as new_rank, COALESCE(tr.RegDate, -1) as Date FROM ck_playertimes pt LEFT JOIN ck_track tr ON pt.mapname = tr.mapname AND pt.steamid = tr.steamid AND tr.zonegroup = 0 WHERE pt.mapname = '%s' AND pt.style = 0 GROUP BY pt.steamid HAVING new_rank <> 999999 ORDER BY pt.runtimepro";
char sql_Poulate_ck_track_bonus[] = "SELECT (ROW_NUMBER() OVER(ORDER BY pt.runtime)) AS rank_nr, pt.steamid, pt.name, pt.mapname, pt.runtime, pt.zonegroup, COALESCE(tr.previous_rank, -1) as prev_rank, COALESCE(tr.new_rank, -1) as new_rank, COALESCE(tr.RegDate, -1) as Date FROM ck_bonus pt LEFT JOIN ck_track tr ON pt.mapname = tr.mapname AND pt.steamid = tr.steamid AND tr.zonegroup = '%i' WHERE pt.mapname = '%s' AND pt.zonegroup = '%i' AND pt.style = 0 GROUP BY pt.steamid HAVING new_rank <> 999999 ORDER BY pt.runtime;";

//ck_replays
char sql_createReplays[] = "CREATE TABLE IF NOT EXISTS ck_replays (mapname VARCHAR(32), cp1 int(12) NOT NULL DEFAULT '0', cp2 int(12) NOT NULL DEFAULT '0', cp3 int(12) NOT NULL DEFAULT '0', cp4 int(12) NOT NULL DEFAULT '0', cp5 int(12) NOT NULL DEFAULT '0', cp6 int(12) NOT NULL DEFAULT '0', cp7 int(12) NOT NULL DEFAULT '0', cp8 int(12) NOT NULL DEFAULT '0', cp9 int(12) NOT NULL DEFAULT '0', cp10 int(12) NOT NULL DEFAULT '0', cp11 int(12) NOT NULL DEFAULT '0', cp12 int(12) NOT NULL DEFAULT '0', cp13 int(12) NOT NULL DEFAULT '0', cp14 int(12) NOT NULL DEFAULT '0', cp15 int(12) NOT NULL DEFAULT '0', cp16 int(12) NOT NULL DEFAULT '0', cp17  int(12) NOT NULL DEFAULT '0', cp18 int(12) NOT NULL DEFAULT '0', cp19 int(12) NOT NULL DEFAULT '0', cp20  int(12) NOT NULL DEFAULT '0', cp21 int(12) NOT NULL DEFAULT '0', cp22 int(12) NOT NULL DEFAULT '0', cp23 int(12) NOT NULL DEFAULT '0', cp24 int(12) NOT NULL DEFAULT '0', cp25 int(12) NOT NULL DEFAULT '0', cp26 int(12) NOT NULL DEFAULT '0', cp27 int(12) NOT NULL DEFAULT '0', cp28 int(12) NOT NULL DEFAULT '0', cp29 int(12) NOT NULL DEFAULT '0', cp30 int(12) NOT NULL DEFAULT '0', cp31 int(12) NOT NULL DEFAULT '0', cp32  int(12) NOT NULL DEFAULT '0', cp33 int(12) NOT NULL DEFAULT '0', cp34 int(12) NOT NULL DEFAULT '0', cp35 int(12) NOT NULL DEFAULT '0', style INT(12) NOT NULL DEFAULT 0, PRIMARY KEY(mapname, style)) DEFAULT CHARSET=utf8mb4;";
char sql_selectReplayCPTicksAll[] = "SELECT cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20, cp21, cp22, cp23, cp24, cp25, cp26, cp27, cp28, cp29, cp30, cp31, cp32, cp33, cp34, cp35, style FROM ck_replays WHERE mapname='%s';";
char sql_insertReplayCPTicks[] = "INSERT INTO ck_replays (mapname, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20, cp21, cp22, cp23, cp24, cp25, cp26, cp27, cp28, cp29, cp30, cp31, cp32, cp33, cp34, cp35, style) VALUES ('%s', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i')";
char sql_updateReplayCPTicks[] = "UPDATE ck_replays SET cp1='%i', cp2='%i', cp3='%i', cp4='%i', cp5='%i', cp6='%i', cp7='%i', cp8='%i', cp9='%i', cp10='%i', cp11='%i', cp12='%i', cp13='%i', cp14='%i', cp15='%i', cp16='%i', cp17='%i', cp18='%i', cp19='%i', cp20='%i', cp21='%i', cp22='%i', cp23='%i', cp24='%i', cp25='%i', cp26='%i', cp27='%i', cp28='%i', cp29='%i', cp30='%i', cp31='%i', cp32='%i', cp33='%i', cp34='%i', cp35='%i' WHERE mapname='%s' AND style='%i';";


//ck_ccp
char sql_createCCP[] = "CREATE TABLE IF NOT EXISTS ck_ccp (steamid VARCHAR(32), mapname VARCHAR(32), cp INT NOT NULL DEFAULT '0', stage_time decimal(12, 6) NOT NULL DEFAULT '-1.000000', stage_attempts INT NOT NULL DEFAULT '0', PRIMARY KEY(steamid, mapname, cp)) DEFAULT CHARSET=utf8mb4;";
char sql_updateCCP[] = "UPDATE ck_ccp SET stage_time='%f', stage_attempts='%i' WHERE steamid='%s' AND mapname='%s' AND cp='%i';";
char sql_insertCCP[] = "INSERT INTO ck_ccp (steamid, mapname, cp, stage_time, stage_attempts) VALUES ('%s', '%s', '%i', '%f', '%i')";
char sql_selectStageTimes[] = "SELECT cp, stage_time FROM ck_ccp WHERE mapname = '%s' AND steamid = '%s';";
char sql_selectStageAttempts[] = "SELECT cp, stage_attempts FROM ck_ccp WHERE mapname = '%s' AND steamid = '%s';";