--REMOVE stagetimes from ck_checkpoints
ALTER TABLE ck_checkpoints DROP COLUMN cp_stagetime_1, DROP COLUMN cp_stagetime_2, DROP COLUMN cp_stagetime_3, DROP COLUMN cp_stagetime_4, DROP COLUMN cp_stagetime_5, DROP COLUMN cp_stagetime_6, DROP COLUMN cp_stagetime_7, DROP COLUMN cp_stagetime_8, DROP COLUMN cp_stagetime_9, DROP COLUMN cp_stagetime_10, DROP COLUMN cp_stagetime_11, DROP COLUMN cp_stagetime_12, DROP COLUMN cp_stagetime_13, DROP COLUMN cp_stagetime_14, DROP COLUMN cp_stagetime_15, DROP COLUMN cp_stagetime_16, DROP COLUMN cp_stagetime_17, DROP COLUMN cp_stagetime_18, DROP COLUMN cp_stagetime_19, DROP COLUMN cp_stagetime_20, DROP COLUMN cp_stagetime_21, DROP COLUMN cp_stagetime_22, DROP COLUMN cp_stagetime_23, DROP COLUMN cp_stagetime_24, DROP COLUMN cp_stagetime_25, DROP COLUMN cp_stagetime_26, DROP COLUMN cp_stagetime_27, DROP COLUMN cp_stagetime_28, DROP COLUMN cp_stagetime_29, DROP COLUMN cp_stagetime_30, DROP COLUMN cp_stagetime_31, DROP COLUMN cp_stagetime_32, DROP COLUMN cp_stagetime_33, DROP COLUMN cp_stagetime_34, DROP COLUMN cp_stagetime_35;

--CREATE NEW TABLE WITH STAGETIMES
CREATE TABLE IF NOT EXISTS ck_stagetimes (steamid VARCHAR(32), name VARCHAR(32), mapname VARCHAR(32), cp_stagetime_1 FLOAT DEFAULT '0.0', cp_stagetime_2 FLOAT DEFAULT '0.0', cp_stagetime_3 FLOAT DEFAULT '0.0', cp_stagetime_4 FLOAT DEFAULT '0.0', cp_stagetime_5 FLOAT DEFAULT '0.0', cp_stagetime_6 FLOAT DEFAULT '0.0', cp_stagetime_7 FLOAT DEFAULT '0.0', cp_stagetime_8 FLOAT DEFAULT '0.0', cp_stagetime_9 FLOAT DEFAULT '0.0', cp_stagetime_10 FLOAT DEFAULT '0.0', cp_stagetime_11 FLOAT DEFAULT '0.0', cp_stagetime_12 FLOAT DEFAULT '0.0', cp_stagetime_13 FLOAT DEFAULT '0.0', cp_stagetime_14 FLOAT DEFAULT '0.0', cp_stagetime_15 FLOAT DEFAULT '0.0', cp_stagetime_16 FLOAT DEFAULT '0.0', cp_stagetime_17  FLOAT DEFAULT '0.0', cp_stagetime_18 FLOAT DEFAULT '0.0', cp_stagetime_19 FLOAT DEFAULT '0.0', cp_stagetime_20  FLOAT DEFAULT '0.0', cp_stagetime_21 FLOAT DEFAULT '0.0', cp_stagetime_22 FLOAT DEFAULT '0.0', cp_stagetime_23 FLOAT DEFAULT '0.0', cp_stagetime_24 FLOAT DEFAULT '0.0', cp_stagetime_25 FLOAT DEFAULT '0.0', cp_stagetime_26 FLOAT DEFAULT '0.0', cp_stagetime_27 FLOAT DEFAULT '0.0', cp_stagetime_28 FLOAT DEFAULT '0.0', cp_stagetime_29 FLOAT DEFAULT '0.0', cp_stagetime_30 FLOAT DEFAULT '0.0', cp_stagetime_31 FLOAT DEFAULT '0.0', cp_stagetime_32  FLOAT DEFAULT '0.0', cp_stagetime_33 FLOAT DEFAULT '0.0', cp_stagetime_34 FLOAT DEFAULT '0.0', cp_stagetime_35 FLOAT DEFAULT '0.0', PRIMARY KEY(steamid, mapname, zonegroup)) DEFAULT CHARSET=utf8mb4;
