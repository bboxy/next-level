
import array
import sys
import os

NOF_FRAMES_TO_ENCODE = 99
all_spr_sort = {}

#"col" is the game_counter colur. if >= 16, then the char is inverted
#y0 is the destination row of the greetingstext,
#x0 is the left free x-pos
#z0 is the right free x-pos
#ccol0 is the destination charcol. 0x10 means inverted
#scol is the sprite colour
games = [
#Must start with Comic Bakery atm:
{"name":'COMBAKER'          ,"col":0x01, "y0": 8,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":16,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#01
{"name":'GAUNTLET'          ,"col":0x01, "y0": 0,"x0": 5,"z0":20,"ccol0":0x07,"scol0": 7,"y1":21,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#02
{"name":'SKRAMBLE6'         ,"col":0x01, "y0":14,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 2,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#03
{"name":'ISOCCR88'          ,"col":0x10, "y0": 7,"x0": 0,"z0":22,"ccol0":0x10,"scol0":13,"y1": 8,"x1":24,"z1":40,"ccol1":0x10,"scol1": 0},#04
{"name":'FRAK'              ,"col":0x00, "y0": 4,"x0": 0,"z0":24,"ccol0":0x00,"scol0": 0,"y1":16,"x1":14,"z1":40,"ccol1":0x00,"scol1": 0},#05
{"name":'SKATE-1'           ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x0d,"scol0":13,"y1": 3,"x1": 2,"z1":40,"ccol1":0x0d,"scol1":13},#06
{"name":'new/BRUCELEE'      ,"col":0x10, "y0":13,"x0": 0,"z0":20,"ccol0":0x07,"scol0": 7,"y1":21,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#07
{"name":'HENRYHOU'          ,"col":0x01, "y0":17,"x0": 1,"z0":11,"ccol0":0x01,"scol0": 1,"y1": 5,"x1": 0,"z1":40,"ccol1":0x01,"scol1": 1},#08
{"name":'IMPMISSN'          ,"col":0x01, "y0":20,"x0": 8,"z0":29,"ccol0":0x07,"scol0": 7,"y1": 8,"x1": 1,"z1":34,"ccol1":0x07,"scol1": 7},#09
{"name":'new/OILSWELL'      ,"col":0x01, "y0": 2,"x0": 0,"z0":16,"ccol0":0x07,"scol0": 7,"y1": 0,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#10
{"name":'new/RAIDMOSC'      ,"col":0x01, "y0":18,"x0": 0,"z0":25,"ccol0":0x07,"scol0": 7,"y1":18,"x1":15,"z1":40,"ccol1":0x07,"scol1": 7},#11
{"name":'TEMPLE'            ,"col":0x01, "y0":18,"x0": 7,"z0":21,"ccol0":0x07,"scol0": 7,"y1":14,"x1": 7,"z1":21,"ccol1":0x07,"scol1": 7},#12
{"name":'new/KRAKOUT'       ,"col":0x01, "y0": 0,"x0": 0,"z0":20,"ccol0":0x07,"scol0": 7,"y1": 0,"x1":20,"z1":38,"ccol1":0x0d,"scol1":13},#13 # Music feels a little off
{"name":'ROLAND'            ,"col":0x10, "y0": 4,"x0": 0,"z0":20,"ccol0":0x07,"scol0": 7,"y1": 5,"x1": 2,"z1":40,"ccol1":0x07,"scol1": 7},#14 # Part of the sfx is missing a channel
# SPRITE MAT #1:
{"name":'URIDIUM_2'         ,"col":0x10, "y0":19,"x0": 0,"z0":40,"ccol0":0x10,"scol0": 0,"y1": 2,"x1": 0,"z1":40,"ccol1":0x10,"scol1": 1},#15 
{"name":'Paperboy'          ,"col":0x01, "y0": 8,"x0": 0,"z0":29,"ccol0":0x07,"scol0": 7,"y1":16,"x1":14,"z1":40,"ccol1":0x07,"scol1": 7},#16 
{"name":'ManiacMansion'     ,"col":0x01, "y0": 3,"x0": 0,"z0":26,"ccol0":0x07,"scol0": 7,"y1": 9,"x1":17,"z1":40,"ccol1":0x07,"scol1": 7},#17 
{"name":'CAVELON'           ,"col":0x01, "y0":12,"x0":16,"z0":24,"ccol0":0x07,"scol0": 7,"y1":13,"x1": 0,"z1":14,"ccol1":0x07,"scol1": 7},#18 
{"name":'new/AZTECCHA'      ,"col":0x01, "y0":18,"x0": 8,"z0":24,"ccol0":0x01,"scol0": 1,"y1": 4,"x1": 3,"z1":37,"ccol1":0x01,"scol1": 1},#19 
{"name":'LOCO'              ,"col":0x01, "y0": 5,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 8,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},#20 
{"name":'new/CAULDRON_2'    ,"col":0x01, "y0": 4,"x0": 0,"z0":40,"ccol0":0x01,"scol0": 1,"y1": 7,"x1": 0,"z1":40,"ccol1":0x01,"scol1": 1},#21 
{"name":'ROBOCOP2'          ,"col":0x01, "y0": 0,"x0": 0,"z0":20,"ccol0":0x07,"scol0": 7,"y1": 0,"x1":18,"z1":38,"ccol1":0x07,"scol1": 7},#22 
{"name":'MASTLAMP'          ,"col":0x01, "y0":21,"x0":13,"z0":19,"ccol0":0x07,"scol0": 7,"y1": 4,"x1":23,"z1":38,"ccol1":0x07,"scol1": 7},#23 
{"name":'new/TBIZARRE'      ,"col":0x01, "y0":15,"x0": 0,"z0":20,"ccol0":0x07,"scol0": 7,"y1":13,"x1":15,"z1":40,"ccol1":0x07,"scol1": 7},#24 
{"name":'MONTEZUM'          ,"col":0x01, "y0": 7,"x0": 5,"z0":35,"ccol0":0x07,"scol0": 7,"y1":18,"x1": 9,"z1":29,"ccol1":0x07,"scol1": 7},#25 
{"name":'TAPPER'            ,"col":0x01, "y0":19,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 6,"y1":21,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#26 
{"name":'LAZARIAN_'         ,"col":0x01, "y0":19,"x0": 0,"z0":28,"ccol0":0x07,"scol0": 7,"y1":20,"x1":16,"z1":40,"ccol1":0x07,"scol1": 7},#27 
{"name":'HEROGOLD'          ,"col":0x1f, "y0": 0,"x0": 7,"z0":17,"ccol0":0x07,"scol0": 7,"y1": 1,"x1":24,"z1":33,"ccol1":0x07,"scol1": 7},#28 
{"name":'PITFALL2'          ,"col":0x01, "y0":14,"x0": 7,"z0":23,"ccol0":0x07,"scol0": 7,"y1":14,"x1":20,"z1":40,"ccol1":0x07,"scol1": 7},#29 
{"name":'SPACETAX'          ,"col":0x01, "y0": 3,"x0": 7,"z0":37,"ccol0":0x07,"scol0": 7,"y1":16,"x1": 6,"z1":32,"ccol1":0x07,"scol1": 7},#30 
{"name":'GBUSTERS'          ,"col":0x01, "y0": 8,"x0": 2,"z0":21,"ccol0":0x07,"scol0": 7,"y1":18,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#31 
{"name":'DRUID2'            ,"col":0x00, "y0":17,"x0": 0,"z0":40,"ccol0":0x10,"scol0":13,"y1":20,"x1": 0,"z1":40,"ccol1":0x10,"scol1":13},#32 
{"name":'MOUNKING'          ,"col":0x01, "y0": 6,"x0": 0,"z0":24,"ccol0":0x07,"scol0": 7,"y1":20,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#33 # MUSIC a little too loud for this part. Swap with a softer game further down.
{"name":'JETPAC'            ,"col":0x01, "y0":14,"x0": 0,"z0":30,"ccol0":0x07,"scol0": 7,"y1": 9,"x1":19,"z1":40,"ccol1":0x07,"scol1": 7},#34 
{"name":'KILLWATT'          ,"col":0x01, "y0":19,"x0":12,"z0":38,"ccol0":0x07,"scol0": 7,"y1": 6,"x1":16,"z1":40,"ccol1":0x07,"scol1": 7},#35 
{"name":'Arkanoid'          ,"col":0x01, "y0":21,"x0": 2,"z0":20,"ccol0":0x07,"scol0": 7,"y1":18,"x1": 2,"z1":26,"ccol1":0x17,"scol1": 0},#36 
{"name":'FORTAPOC'          ,"col":0x01, "y0":12,"x0": 0,"z0":34,"ccol0":0x07,"scol0": 7,"y1": 9,"x1": 0,"z1":37,"ccol1":0x07,"scol1": 7},#37 
{"name":'BLAGGER'           ,"col":0x01, "y0": 1,"x0": 9,"z0":31,"ccol0":0x07,"scol0": 7,"y1": 7,"x1": 1,"z1":24,"ccol1":0x07,"scol1": 7},#38 
{"name":'MMADNESS'          ,"col":0x01, "y0": 1,"x0": 3,"z0":24,"ccol0":0x07,"scol0": 7,"y1": 1,"x1":18,"z1":36,"ccol1":0x07,"scol1": 7},#39 
{"name":'ZENJI'             ,"col":0x01, "y0": 3,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":19,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#40 
{"name":'CAULDRN2_2'        ,"col":0x01, "y0":17,"x0":11,"z0":38,"ccol0":0x04,"scol0": 4,"y1":10,"x1": 0,"z1":19,"ccol1":0x04,"scol1": 4},#41 
{"name":'GROGSREV_3'        ,"col":0x01, "y0":18,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":22,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#42 
# SPRITE MAT #2:
{"name":'RAMBO'             ,"col":0x01, "y0": 7,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":15,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#43
{"name":'FLIPA737_2'        ,"col":0x01, "y0":19,"x0": 0,"z0":40,"ccol0":0x01,"scol0": 1,"y1":20,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#44
{"name":'new/DOTC'          ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},#45
{"name":'PIRATES1'          ,"col":0x00, "y0":17,"x0": 0,"z0":40,"ccol0":0x00,"scol0": 0,"y1":20,"x1": 0,"z1":40,"ccol1":0x00,"scol1": 0},#46
{"name":'WORLDCUP'          ,"col":0x10, "y0":22,"x0": 0,"z0":40,"ccol0":0x00,"scol0":12,"y1":10,"x1":16,"z1":40,"ccol1":0x00,"scol1": 0},#47
{"name":'CKHAFKA'           ,"col":0x01, "y0": 4,"x0": 0,"z0":17,"ccol0":0x07,"scol0": 7,"y1":19,"x1": 2,"z1":22,"ccol1":0x07,"scol1": 7},#48
{"name":'PENGO'             ,"col":0x01, "y0":10,"x0": 5,"z0":17,"ccol0":0x07,"scol0": 7,"y1": 1,"x1":20,"z1":34,"ccol1":0x07,"scol1": 7},#49
{"name":'GILLGOLD'          ,"col":0x01, "y0": 2,"x0":15,"z0":40,"ccol0":0x07,"scol0": 7,"y1":22,"x1":27,"z1":36,"ccol1":0x07,"scol1": 7},#50
{"name":'HIGHNOON'          ,"col":0x16, "y0":22,"x0": 2,"z0":22,"ccol0":0x17,"scol0": 6,"y1":22,"x1":20,"z1":40,"ccol1":0x17,"scol1": 0},#51
{"name":'SHAMUS2_'          ,"col":0x01, "y0": 9,"x0":16,"z0":33,"ccol0":0x07,"scol0": 7,"y1": 0,"x1":18,"z1":38,"ccol1":0x07,"scol1": 7},#52
{"name":'LAZYJONE'          ,"col":0x01, "y0": 0,"x0": 0,"z0":14,"ccol0":0x07,"scol0": 7,"y1": 0,"x1":25,"z1":38,"ccol1":0x07,"scol1": 7},#53
{"name":'THINGONA'          ,"col":0x01, "y0": 2,"x0":10,"z0":38,"ccol0":0x07,"scol0": 7,"y1":10,"x1":12,"z1":38,"ccol1":0x07,"scol1": 7},#54 # THING ON A SPRING uses 138 tracked registers and cannot load a large game after.
{"name":'new/PANIC64'       ,"col":0x01, "y0":12,"x0": 0,"z0":30,"ccol0":0x06,"scol0": 6,"y1":21,"x1": 0,"z1":14,"ccol1":0x06,"scol1": 6},#55 # So Panic64 is there, 3 blocks to load.
{"name":'1942'              ,"col":0x01, "y0": 7,"x0":20,"z0":40,"ccol0":0x07,"scol0": 7,"y1":10,"x1":18,"z1":40,"ccol1":0x07,"scol1": 7},#56
{"name":'AIRWOLF'           ,"col":0x01, "y0":18,"x0": 6,"z0":30,"ccol0":0x07,"scol0": 7,"y1":20,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},#57
{"name":'RASTAN'            ,"col":0x01, "y0": 8,"x0":10,"z0":34,"ccol0":0x07,"scol0": 7,"y1": 1,"x1": 0,"z1":38,"ccol1":0x07,"scol1": 7},#58
{"name":'D64HUMA'           ,"col":0x01, "y0":13,"x0": 2,"z0":14,"ccol0":0x07,"scol0": 7,"y1": 3,"x1": 6,"z1":40,"ccol1":0x07,"scol1": 7},#59
# SPRITE MAT #3:
{"name":'PacMan'            ,"col":0x01, "y0": 0,"x0": 8,"z0":34,"ccol0":0x07,"scol0": 7,"y1": 0,"x1":18,"z1":38,"ccol1":0x07,"scol1": 7},#60
{"name":'CKHAFKA2'          ,"col":0x01, "y0": 4,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":19,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#61
{"name":'GHETTOBL'          ,"col":0x01, "y0": 8,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":11,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#62
{"name":'BoogaBoo'          ,"col":0x01, "y0":14,"x0": 0,"z0":20,"ccol0":0x07,"scol0": 7,"y1":14,"x1":20,"z1":40,"ccol1":0x07,"scol1": 7},#63
{"name":'Flaschbier'        ,"col":0x01, "y0": 4,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":20,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#64
{"name":'CROSSFIR'          ,"col":0x01, "y0": 4,"x0": 0,"z0":38,"ccol0":0x07,"scol0": 7,"y1":16,"x1": 0,"z1":38,"ccol1":0x07,"scol1": 7},#65
{"name":'BOMBJACK'          ,"col":0x01, "y0": 7,"x0":12,"z0":29,"ccol0":0x16,"scol0":14,"y1": 3,"x1": 2,"z1":15,"ccol1":0x16,"scol1": 0},#66
{"name":'HHORACE'           ,"col":0x00, "y0":11,"x0":13,"z0":24,"ccol0":0x00,"scol0": 0,"y1": 7,"x1":11,"z1":33,"ccol1":0x00,"scol1": 0},#67
{"name":'HUNCHBK2'          ,"col":0x01, "y0":18,"x0": 7,"z0":25,"ccol0":0x07,"scol0": 0,"y1": 7,"x1":10,"z1":22,"ccol1":0x07,"scol1": 0},#68
{"name":'Drelbs'            ,"col":0x01, "y0": 2,"x0": 6,"z0":20,"ccol0":0x07,"scol0": 7,"y1":21,"x1":11,"z1":21,"ccol1":0x0f,"scol1": 7},#69
{"name":'SAMFOX'            ,"col":0x10, "y0":16,"x0": 0,"z0":40,"ccol0":0x01,"scol0": 1,"y1":13,"x1": 0,"z1":40,"ccol1":0x01,"scol1": 1},#70
{"name":'BIGGLES'           ,"col":0x01, "y0":20,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":22,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#71
{"name":'CAULDRN2'          ,"col":0x01, "y0": 9,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":18,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#72
{"name":'BBOBBLE'           ,"col":0x01, "y0":21,"x0": 6,"z0":29,"ccol0":0x07,"scol0": 7,"y1": 4,"x1": 3,"z1":29,"ccol1":0x07,"scol1": 7},#73
{"name":'RICKDAN2'          ,"col":0x01, "y0": 7,"x0": 8,"z0":31,"ccol0":0x07,"scol0": 7,"y1":15,"x1": 7,"z1":31,"ccol1":0x07,"scol1": 7},#74
{"name":'BURGRTIM'          ,"col":0x01, "y0": 2,"x0":13,"z0":26,"ccol0":0x07,"scol0": 7,"y1":21,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#75
{"name":'PARADROI'          ,"col":0x01, "y0": 4,"x0": 0,"z0":30,"ccol0":0x07,"scol0": 7,"y1": 6,"x1":10,"z1":40,"ccol1":0x07,"scol1": 7},#76
{"name":'FPATROL2'          ,"col":0x01, "y0": 9,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 1,"x1": 0,"z1":38,"ccol1":0x07,"scol1": 7},#77
{"name":'GGOBLINS'          ,"col":0x01, "y0":19,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#78
{"name":'GIANA'             ,"col":0x01, "y0":12,"x0": 4,"z0":24,"ccol0":0x07,"scol0": 7,"y1": 9,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#79
{"name":'HOVERBOV'          ,"col":0x01, "y0": 1,"x0":12,"z0":21,"ccol0":0x15,"scol0": 0,"y1": 5,"x1": 0,"z1":40,"ccol1":0x15,"scol1": 0},#80
{"name":'SNOKIE'            ,"col":0x01, "y0":10,"x0": 4,"z0":30,"ccol0":0x07,"scol0": 7,"y1":13,"x1":10,"z1":40,"ccol1":0x07,"scol1": 7},#81
# SPRITE MAT #4:
{"name":'NEBULUS'           ,"col":0x01, "y0":19,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 3,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#82
{"name":'WIZARDOW'          ,"col":0x01, "y0": 2,"x0": 0,"z0":30,"ccol0":0x0a,"scol0":10,"y1":19,"x1":10,"z1":40,"ccol1":0x0a,"scol1":10},#83
{"name":'NEVENDST2'         ,"col":0x01, "y0": 7,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":12,"x1":15,"z1":40,"ccol1":0x07,"scol1": 7},#84
{"name":'GORF'              ,"col":0x01, "y0": 3,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":13,"x1":20,"z1":40,"ccol1":0x07,"scol1": 7},#65
{"name":'BLUETHUN'          ,"col":0x10, "y0":13,"x0": 9,"z0":30,"ccol0":0x00,"scol0": 0,"y1":16,"x1": 4,"z1":40,"ccol1":0x00,"scol1": 0},#86
{"name":'SPYHUNT'           ,"col":0x01, "y0":11,"x0":11,"z0":28,"ccol0":0x07,"scol0": 7,"y1":14,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#87
{"name":'MONTYRUN'          ,"col":0x01, "y0":17,"x0":11,"z0":25,"ccol0":0x07,"scol0": 7,"y1": 4,"x1": 0,"z1":30,"ccol1":0x07,"scol1": 7},#88
{"name":'AMC'               ,"col":0x01, "y0":19,"x0": 6,"z0":24,"ccol0":0x07,"scol0": 7,"y1":19,"x1":16,"z1":38,"ccol1":0x07,"scol1": 7},#89
{"name":'TASK3'             ,"col":0x10, "y0":11,"x0": 1,"z0":20,"ccol0":0x10,"scol0":13,"y1": 4,"x1":22,"z1":40,"ccol1":0x10,"scol1":13},#90
{"name":'SPIPLIN'           ,"col":0x01, "y0":15,"x0":19,"z0":28,"ccol0":0x07,"scol0": 7,"y1": 7,"x1": 0,"z1":35,"ccol1":0x07,"scol1": 7},#91
{"name":'KETTLE'            ,"col":0x01, "y0":14,"x0": 0,"z0":40,"ccol0":0x01,"scol0": 1,"y1":20,"x1": 0,"z1":40,"ccol1":0x01,"scol1": 1},#92
{"name":'boulder1'          ,"col":0x01, "y0": 5,"x0": 9,"z0":20,"ccol0":0x07,"scol0": 7,"y1":11,"x1": 9,"z1":29,"ccol1":0x07,"scol1": 7},#93
{"name":'SHAMUS'            ,"col":0x01, "y0": 1,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1": 4,"z1":40,"ccol1":0x07,"scol1": 7},#94
{"name":'URIDIUM'           ,"col":0x01, "y0": 6,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 8,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#95
{"name":'DDDENIS'           ,"col":0x01, "y0": 3,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":10,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#96
{"name":'FBFOREST'          ,"col":0x01, "y0": 9,"x0": 7,"z0":22,"ccol0":0x07,"scol0": 7,"y1": 9,"x1":22,"z1":36,"ccol1":0x07,"scol1": 7},#97
{"name":'YIEAR2'            ,"col":0x01, "y0": 9,"x0": 0,"z0":12,"ccol0":0x07,"scol0": 7,"y1": 2,"x1":23,"z1":40,"ccol1":0x07,"scol1": 7},#98
{"name":'REVENGE'           ,"col":0x01, "y0": 9,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":12,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#99
{"name":'ARCHON'            ,"col":0x01, "y0":11,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":22,"x1":26,"z1":40,"ccol1":0x07,"scol1": 7},#100  # Game does not show any graphics? Sound is OK.
{"name":'YIEAR'             ,"col":0x01, "y0": 3,"x0": 0,"z0":28,"ccol0":0x07,"scol0": 7,"y1":22,"x1":20,"z1":40,"ccol1":0x07,"scol1": 7},#101

# Don't need more than 100:
{"name":'WGAMES'            ,"col":0x00, "y0":14,"x0":16,"z0":40,"ccol0":0x06,"scol0": 6,"y1":20,"x1": 0,"z1":40,"ccol1":0x06,"scol1": 6},#09 SILENT #OK                                                   $37f8-$4c00
{"name":'DieKlapperschlange',"col":0x01, "y0": 6,"x0": 0,"z0":16,"ccol0":0x07,"scol0": 7,"y1": 0,"x1": 0,"z1":22,"ccol1":0x07,"scol1": 7},#36 #OK                                          $7400-$8889
{"name":'new/COMMANDO_7'    ,"col":0x00, "y0":21,"x0": 1,"z0":20,"ccol0":0x01,"scol0": 1,"y1":21,"x1":20,"z1":39,"ccol1":0x01,"scol1": 1},#54 MUSIC WEIRD? #OK                                                   $73c0-$88f7

{"name":'64erTurbo'         ,"col":0x01, "y0":10,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":10,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#102# USE ROM FONT                               ### Under test ###
{"name":'mr_z_-_turbo_250'  ,"col":0x01, "y0":10,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":10,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7} #103# USE ROM FONT


#{"name":'THINGBOU'          ,"col":0x01, "y0":18,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":21,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#71 REDO: SILENT? #OK erase lines at bottom                             $7100-$9538 Large

#{"name":'CHUCKEGG'          ,"col":0x01, "y0": 3,"x0": 6,"z0":40,"ccol0":0x07,"scol0": 7,"y1":10,"x1":24,"z1":40,"ccol1":0x07,"scol1": 7},# REDO: SILENT #OK                                                   $7400-$899f
#{"name":'BLLAMP'            ,"col":0x10, "y0": 3,"x0": 0,"z0":40,"ccol0":0x06,"scol0": 6,"y1": 7,"x1": 0,"z1":40,"ccol1":0x00,"scol1": 0},#23 REDO: STRANGE #OK but clear upper and lower part of screen - walking$7340-$8ea4not there
#{"name":'PANIC64'           ,"col":0x06, "y0": 6,"x0": 8,"z0":40,"ccol0":0x05,"scol0": 5,"y1":22,"x1": 4,"z1":24,"ccol1":0x00,"scol1": 0},# REDO: SILENT #OK, but boring                                       $7400-$887d
#{"name":'DOTC'              ,"col":0x10, "y0": 1,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":22,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},# REDO: SILENT? STRANGE #OK                                                   $7400-$8923

# Sprites are wrong:
#{"name":'new/COMMANDO_2'    ,"col":0x10, "y0":19,"x0": 1,"z0":20,"ccol0":0x10,"scol0":13,"y1":19,"x1":20,"z1":39,"ccol1":0x10,"scol1": 0},#03 #OK                                                   $73c0-$88f7
#{"name":'new/COMMANDO_3'    ,"col":0x10, "y0":19,"x0": 1,"z0":20,"ccol0":0x10,"scol0":13,"y1":19,"x1":20,"z1":39,"ccol1":0x10,"scol1": 0},#03 #OK                                                   $73c0-$88f7
#{"name":'new/COMMANDO_4'    ,"col":0x10, "y0":19,"x0": 1,"z0":20,"ccol0":0x10,"scol0":13,"y1":19,"x1":20,"z1":39,"ccol1":0x10,"scol1": 0},#03 #OK                                                   $73c0-$88f7
#{"name":'new/COMMANDO_5'    ,"col":0x10, "y0":19,"x0": 1,"z0":20,"ccol0":0x10,"scol0":13,"y1":19,"x1":20,"z1":39,"ccol1":0x10,"scol1": 0},#03 #OK                                                   $73c0-$88f7
#{"name":'new/COMMANDO_6'    ,"col":0x10, "y0":19,"x0": 1,"z0":20,"ccol0":0x10,"scol0":13,"y1":19,"x1":20,"z1":39,"ccol1":0x10,"scol1": 0},#03 #OK                                                   $73c0-$88f7

#BAD AUDIO:{"name":'COMMANDO'          ,"col":0x01, "y0": 7,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1":12,"x1": 0,"z1":40,"ccol1":0x07,"scol1": 7},#61 REDO: AUDIO COULD BE BETTER #OK                                                   $7400-$8ab0
#BAD AUDIO:{"name":'FORMULA'           ,"col":0x01, "y0": 8,"x0": 0,"z0": 6,"ccol0":0x07,"scol0": 7,"y1":16,"x1": 0,"z1": 5,"ccol1":0x07,"scol1": 7},#62 REDO: AUDIO IS STRANGE #OK                                                   $3368-$4c00
#MISSING HEADS ON CAPTIVES:{"name":'GREENBRT'          ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},#19 # OK, used to be too large, but men have no heads
#UGLY:{"name":'TRAP'              ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},#20
#WRONG AUDIO:{"name":'new/MULE'          ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},#11
#SILENT:{"name":'KRAKOUT'           ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},#01 REDO: SILENT? #OK                         ### Silent ones ###       $34c6-$4c00
#SILENT:{"name":'ANTIRIAD'          ,"col":0x01, "y0":17,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 1,"x1":22,"z1":37,"ccol1":0x07,"scol1": 7},#04 SILENT #OK - Erase bottom lines                              $7400-$8e77
#SILENT:{"name":'HOTWHEEL'          ,"col":0x11, "y0": 6,"x0":14,"z0":28,"ccol0":0x07,"scol0": 9,"y1":16,"x1": 4,"z1":35,"ccol1":0x07,"scol1": 7},#08 SILENT #OK                                                   $70c0-$8904

#{"name":'RAIDMOSC'             ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},  # SILENT. ALMOST OK - chars at bottom should not be multicol. SET CHAR COLS AT BOTTOM 4 ROWS

#'CAVELON',
#'SPEEDRAC',  #OK, but was too large    CRASHES when LO. Must be HI $7400-$b7c3 Really Large

#{"name":'new/DROPZONE'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7}, # Wrong charset. 5 lowest rows are ok. Remove 5 lowest rows.
#{"name":'new/GATEWAYA'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/GRYZOR'        ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/HERO'          ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},

#'HYPERSPR',  #OK, used to be too large
#'TEMPLE',    # OK - Temple of Apshai
#'GREENBRT',  # OK, used to be too large, but men have no heads
#'Zynaps',         #OK

#'HERO',     # Error in charset?                            ### Not 100% ok, needs manual fix ###
#'RAIDMOSC',  # ALMOST OK - chars at bottom should not be multicol
#'TRAP',
#'MERMAIDM',
#'ROLAND',    # Wrong col on hero sprite? Missing hero sprite?
#'LOCO'      # Wrong chars

#FORGET THESE ONES:
# EVEN WORSE THAN THE ORIGINAL TRY:
#{"name":'new/COMMANDO'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},  # SILENT = BORING
#{"name":'new/DIGDUG'        ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/CAULDRON'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7}, #OK, but CAULDRON_2 is even better
#{"name":'new/CHUCKEGG'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7}, # SILENT = BORING
#{"name":'new/FORMULA'       ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7}, # TOO SLOW?
#{"name":'new/GRIDRUNR'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/JUMPMAN'       ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/JUMPMAN_2'     ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/MISSELEV'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/PITSTOP'       ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/POPEYE'        ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/SAVENEWY'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/UNDERWLD'      ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/ZAK'           ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'HYPERSPR'             ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},  #OK, used to be too large
#{"name":'SPEEDRAC'             ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},  #OK, but was too large    CRASHES when LO. Must be HI $7400-$b7c3 Really Large
#{"name":'HERO'                 ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7}, # WRONG CHARSET AT UPPER 16 ROWS. ERASE EVERYTHING BELOW. Error in charset?
#{"name":'MERMAIDM'             ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7}, # WRONG CHARSET. ERASE UPPER 6 ROWS
#{"name":'Zynaps'               ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7}, #OK but silent
#{"name":'new/BLLAMP'        ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},
#{"name":'new/COBRA'         ,"col":0x01, "y0": 0,"x0": 0,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},


#'Pedro',          # Wrong charset

# More than 255 tracked addresses. RERECORD with fewer addresses:
#'ARCHON',    #OK
#'SKRAMBLE',  #OK

#'MARIOBRS',  # Flickering sprites
#'JUDGEDRD',  # Sprite multiplex
#'SPCPILOT',  # bitmap gfx.
#'SKOOLDAZ', #bitmap gfx

# The ones that cannot be fixed:
#'LNINJA',   # bitmap gfx
#'BREAKDAN', #<--- bitmap gfx
#'BRUBBER',  #<-- too large
#'SPYVSSPY', #<-- bitmap gfx
#'ARCTICSH', #<-- bitmap gfx
#'COBRA',    #<--- bitmap gfx
#'DAMAGIC',  #<-- bitmap gfx
#'APPLECS',   #<-- bitmap gfx
#'AGENTUSA',  # bitmap gfx
#'BOMBO',     # bitmap gfx


#'PARALLAX',  # Too many addresses
#'FRED_2',    # Way too many addresses
#'Gridrunner', # Too many addresses


# Too large at the first try:
#'SPINDIZZ',
#'IMPMISS1',
#'SHORTCIR', # Too large
#'Matrix',    #OK

# Too large, even after recording again:
#'GROGSREV',#<-- too large   RERECORD
#'BOUNCES',  #<-- too large  RERECORD
#'HORACEGS', # sprite multiplexer for everything that is moving when skiing. RERECORD when crossing street.
#'BRUCELEE',  # Writes into sprites. Too large. Re-record

# Given up on these ones:
#'ACTBKER', #<-- too large   RERECORD
#'ONEMAN',  #<-- too large   RERECORD
#'DELTA', #<-- too large      RERECORD
#'IBALL',#<-- too large      RERECORD

#'KIKSTART2',  # too many addresses
#'KIKSTART2_2', # too many
#'KIKSTART', # too many
#'GROGSREV_2',
#'QBERT',  #bitmap gfx
#'Zorro',  #bitmap
#'Barbarian',  #bitmap
#'Karateka',  #bitmap

#'ZAKMCK',  # too many addrs


#'SUMRGAME', # Wrong background
#'BCQUEST',  # raster splits
#'CALGAMES', #needs cropping
#'THRUST',    # Flickering sprites
#
#'POLEPOSI',
#'TURRI2-1',
#'SZAXXON',
#'RICKDAN',
#'GYRUSS',   #<-- wrong charset. Fix by moving capture half a frame down?
#'SOBLAGGR', #<-- too slow

## Not 100% ok, could probably be fixed:
#'updown',
#'FRIDAY13',
#'HOUSEJCK',
#'HARDHATM',
#'JJUNIOR',   #No chars on screen
#'ELITE',    # Wrongs charset
#'KIDGRID',  # No chars on screen
#'MINR2049',  # No chars on screen
#'BCBILL',   # Err chars
#'UNDERWLD',  #bitmap gfx?
#'LODERUNR4', #Bitmap gfx?
## Could be fixed:
#'MANICMIN',  #Wrong charset
#'SPYDEMIS',  # Wrong charset
#'BOUNTYB',   # Wrong charset
#'TROLLIEW',  # OK, but wrong cols on hero sprite
#'SURVIVOR',  #ALMOST OK - hero is missing
#'WIZBALL',   # Not OK, completely  Resync to somewhere else on screen
#'POGOJOE',   # No chars on screen
#'JETSET',    #Wrong at side of screen, wrong charset at bottom. ToDo: Fix by moving capture half a frame down?
#'ORILEYS',   # ALMOST OK - sprites are missing
#'FRED',      #<-- too slow, but probably does not need to be slow?
#'SAMFOX',    #<-- bitmap gfx


# The ones rerecorded, but with trouble in them:
#'DKONG', #<-- bitmap gfx at start with jumping kong. RERECORD Fix by moving capture half a frame down?

#'MRDOCAST',
#'MIKIE',  # Sprite multiplexer
#'GREMLINS',

#'AHDIDUMS',   #bitmap
#'DIGDUG',  #bitmap
#'RAMPAGE',   # more than 255 addr
#'FLINTSTN',  # Sprite multiplexer
#'MOFMAGIC',  # bitmap gfx
#'SEXGAMES',  #bitmap

# Those OK, but with better versions recorded:
#
#'FLIPA737',
##'FPATROL',  #OK But there is a better recording of FPatrol
#'MMADNESS2', #OK. but too simple, there's a MMADNESS that's better now
#'SKRAMBLE2',
#'SKRAMBLE4',
#'GROG',      #OK - Erase bottom lines
#
]

def dump_mem(description, ba, offset, length):
  i = (((offset + 8) >> 3) << 3) - 8
  while i < offset+length:
    s = ""
    s2 = ""
    for j in range(8):
      if ((i + j) >= 0) and ((i + j) < len(ba)):
        byte = ba[i + j]
        char_no = ba[i + j]
        if (char_no < 0x1f):
          char_no += 64
        s += "%02x " % byte
        s2 += "%c" % char_no
      else:
        byte = 0x00
        s += "__ "
        s2 += "_"
      if byte > 255:
        print("ERROR: byte at 0x%04x is %d" % (i + j, byte))
      if byte < 0:
        print("ERROR: byte at 0x%04x is %d" % (i + j, byte))
    print ("%s0x%06x: %s %s" % (description, i, s, s2))
    i = i + 8

def print_sprite(mem, addr):
  for row_no in range(21):
    s = ""
    for byte_no in range(3):
      the_byte = mem[addr + row_no*3 + byte_no]
      for pixel_no in range(8):
        if (the_byte & 0x80) == 0x00:
          s += "."
        else:
          s += "*"
        the_byte = the_byte * 2
    print(s)


def sort_order(addr):
  global screen_addr
  # d000-d02f goes first:
  if (addr >= 0xd000) and (addr <= 0xd02f):
    return addr-0xd000
  # Then, sprite changes:
  if (addr >= 0x3f8) and (addr <= 0x03ff):
    return 0x100 + (addr & 0x07)
  # Then, screen and colour changes:
  if (addr >= 0x0000) and (addr <= 0x03f7):
    return 0x200 + (addr) * 2
  if (addr >= 0x0400) and (addr <= 0x07e7):
    return 0x201 + (addr - 0x0400) * 2
  # SID comes last:
  if (addr >= 0xd400) and (addr <= 0xd41f):
    return 0x20000 + (addr - 0xd400)
  # SID2 comes last:
  if (addr >= 0xd500) and (addr <= 0xd51f):
    return 0x20100 + (addr - 0xd500)
  # Charset and sprite changes:
  return 0x10000 + addr

def spr_sort_order(spr_no):
  global all_spr_sort
  print(all_spr_sort)
  if all_spr_sort[spr_no]['enabled'] != 1:
    return -1
  else:
    return all_spr_sort[spr_no]['ypos']

def expect_equal(a,b):
  ok = True
  if len(a) != len(b):
    print("ERROR: length of bytearray differs")
    ok = False
  if ok:
    for i in range(len(a)):
      if (a[i] != b[i]):
        print("ERROR: not equal at index %d" % i)
        ok = False
  if not ok:
    s = "        a="
    for i in range(len(a)):
      s += "%02x" % a[i]
    print(s)
    s = "should_be="
    for i in range(len(b)):
      s += "%02x" % b[i]
    print(s)
    die

def expect_equal_backwards(a,b):
  ok = True
  if len(a) != len(b):
    print("ERROR: length of bytearray differs")
    ok = False
  if ok:
    for i in range(len(a)):
      if (a[i] != b[len(b)-1-i]):
        print("ERROR: not equal at index %d" % i)
        ok = False
  if not ok:
    s = "        a="
    for i in range(len(a)):
      s += "%02x" % a[i]
    print(s)
    s = "should_be="
    for i in range(len(b)):
      s += "%02x" % b[len(b)-1-i]
    print(s)
    die


def pack_this_list(addr, all_values, values_that_need_writing):
  # Now we know which values that we need to write. Use that to produce "the_list2"
  #display_list_00:
  #  ADDR_LO
  #  ADDR_HI
  #  LIST_LEN = display_list_01 - display_list_00
  #  LIST_POI  (always 0 at start)
  #  LIST_STREAK  (can be != 0 at start)
  #  LIST_WAIT   (can be != 0 at start)
  #  The list:   VALUE
  #              $00 = end, $01-$7f = wait some cycles, $81-$ff = upcoming streak
  nof_bytes_to_encode = len(all_values)
  if (len(values_that_need_writing) != nof_bytes_to_encode):
    print("ERROR: Number of bytes in all_values and values_that_need_writing must be equal")
    die
  the_list2 = bytearray()
  print("The list that will be packed:")
  s = ""
  for i in range(len(all_values)):
    s += "%02x" % all_values[i]
  print(s)
  s = ""
  for i in range(len(values_that_need_writing)):
    s += "%02x" % values_that_need_writing[i]
  print(s)
  # Let's find the first wait (if value is the same many times in the beginning):
  list_wait = 0
  wait_done = False
  current_poi = 1
  while (current_poi < nof_bytes_to_encode) and (not wait_done):
    if values_that_need_writing[current_poi] == 0:
      list_wait += 1
      current_poi += 1
    else:
      wait_done = True
  print("list_wait=%d,cp=%d." % (list_wait, current_poi), end='')

  list_streak = 0
  while current_poi < nof_bytes_to_encode:
    this_streak = 0
    streak_done = False
    streaked_values = bytearray()

    # Check if this is the last value that we need to write, if so, fast forward to the end.
    tmp_poi = current_poi
    end_done = False
    while (tmp_poi < nof_bytes_to_encode) and (not end_done):
      if values_that_need_writing[tmp_poi] == 0:
        tmp_poi += 1
      else:
        end_done = True
    if tmp_poi >= nof_bytes_to_encode:
      print("We're done. Nothing more to encode");
      current_poi = tmp_poi
    else:
      # Find out if this is a streak: (if the value does change all the time)
      # We know that this byte is a write. values_that_need_writing[current_poi] == 1
      while (current_poi < nof_bytes_to_encode) and (not streak_done):
        if (current_poi < nof_bytes_to_encode-1) and (values_that_need_writing[current_poi+1] == 1):
          streaked_values.append(all_values[current_poi])
          this_streak += 1
          current_poi += 1
        else:
          streak_done = True
      if (this_streak >= 1):
  #      print("current_poi = %d" % current_poi)
  #      print("values_that_need_writing[current_poi] = %d" % values_that_need_writing[current_poi])
        if (values_that_need_writing[current_poi] == 1):
          the_list2.append(0x80 + this_streak-1)
          the_list2.extend(streaked_values)
          print("streak=%d,cp=%d." % (this_streak, current_poi), end='')
      else:
        # it's a wait. Lets find out how long:
        # Find out how many times to rest with the next value:
        # We know that this byte is a write. values_that_need_writing[current_poi] == 1
        # We know that next byte is not a write. values_that_need_writing[current_poi+1] == 0
        this_wait = 1
        wait_done = False
        the_value_to_write = all_values[current_poi]
        while (current_poi < nof_bytes_to_encode-1) and (not wait_done):
          if values_that_need_writing[current_poi+1] == 0:
            this_wait += 1
            current_poi += 1
          else:
            wait_done = True
        if (this_wait > 1):
          if (current_poi >= nof_bytes_to_encode-1):
            # This is the last one. Make the cheapest stop there is:
            # Add the wait to the list:
            the_list2.append(0x7f)
            # Add the value that shall be repeated to the list:
            the_list2.append(the_value_to_write)
            current_poi += 1
            print("wait1=%d,cp=%d." % (this_wait, current_poi), end='')
          else:
            # Add the wait to the list:
            the_list2.append(this_wait-1)
            # Add the value that shall be repeated to the list:
            the_list2.append(the_value_to_write)
            current_poi += 1
            print("wait2=%d,cp=%d." % (this_wait, current_poi), end='')
        else:
          # The wait is too short. (would be a 0x00 in the list, ending the list)
          if (current_poi >= nof_bytes_to_encode-1):
            # This is the last one. Make the cheapest stop there is:
            # Add the wait to the list:
            the_list2.append(0x7f)
            # Add the value that shall be repeated to the list:
            the_list2.append(the_value_to_write)
            current_poi += 1
            print("wait3=%d,cp=%d." % (this_wait, current_poi), end='')
          else:
            # make it into a short streak:
            # Add the wait to the list:
            the_list2.append(0x80 + this_wait-1)
            # Add the value that shall be written once to the list:
            the_list2.append(all_values[current_poi])
            print("too_short_wait=%d,cp=%d." % (this_wait, current_poi), end='')
            current_poi += 1



#  while current_poi < nof_bytes_to_encode:
#    # Find out how many times to repeat the next value:
#    this_wait = 1
#    wait_done = False
#    while (current_poi < nof_bytes_to_encode) and (not wait_done):
#      if values_that_need_writing[current_poi+1] == 0:
#        this_wait += 1
#        current_poi += 1
#      else:
#        wait_done = True
#    if (this_wait > 1):
#      # Add the wait to the list:
#      the_list2.append(this_wait-1)
#      # Add the value that shall be repeated to the list:
#      the_list2.append(all_values[current_poi-1])
#      current_poi += 1
#      print("wait=%d,cp=%d." % (this_wait, current_poi), end='')
#    else:
#      print("wait=%d,cp=%d" % (this_wait, current_poi), end='')
#      # This is not a repeated value, so it's a streak
#      # Let's find the streak value:
#      this_streak = 0
#      streak_done = False
#      streaked_values = bytearray()
#      while (current_poi < nof_bytes_to_encode) and (not streak_done):
#        if values_that_need_writing[current_poi] == 1:
#          streaked_values.append(all_values[current_poi])
#          this_streak += 1
#          current_poi += 1
#        else:
#          streak_done = True
#      print("streak=%d,cp=%d." % (this_streak, current_poi), end='')
#      the_list2.append(0x80 + this_streak-1)
#      the_list2.extend(streaked_values)

  list_len = len(the_list2)
  if list_len > 0xff:
    print("FATAL: Individual tracked value list longer than 256 bytes")
    die

  list_to_return = bytearray()
  if len(the_list2) <= 1:
    print("WARNING: List is too short - skipping.")
  else:
    #addr_to_display_list = addr
    #if (addr == 0xd504) or (addr == 0xd50b) or (addr == 0xd512):
    #  addr_to_display_list = addr - 0x0100
    #list_to_return.append(addr_to_display_list & 0xff)
    #list_to_return.append((addr_to_display_list >> 8) & 0xff)
    #list_to_return.append(list_len)
    # LIST_POI:
    #list_to_return.append(6)
    # LIST_STREAK:
    #list_to_return.append(list_streak)
    # LIST_WAIT:
    #list_to_return.append(list_wait)
    # THE_LIST:
    for i in range(len(the_list2)):
      list_to_return.append(the_list2[len(the_list2)-1-i])

  print("Result after packing:")
  s = ""
  for i in range(len(list_to_return)):
    s += "%02x" % list_to_return[i]
  print(s)
  print("list_wait=0x%02x" % list_wait)
  print()
  return [list_wait, list_to_return]


def minimize_game(game_name, game_no, game_addr, info):
  print()
  print("### Doing game #%02d: %s -> %s" % (game_no, game_name, game_addr))
  if game_name == "SPEEDRAC" and game_addr == "LO":
    print("Speedracer not allowed to be LO")
    die

  this_games_max_nof_sprites_on_a_line = 0

  #s0_filename = '../../../../../../../ubuntu/games/%s.s0' % game_name
  #s1_filename = '../../../../../../../ubuntu/games/%s.s1' % game_name
  s0_filename = './games/%s.s0' % game_name
  s1_filename = './games/%s.s1' % game_name
  output_filename = './output/%02d.raw' % game_no
  chars_output_filename = './chars/%02d.raw' % game_no
  #output_filename = './output/%s.bin' % game_name
  # Load the binary files to start with
  with open(s0_filename, "rb") as binaryfile :
      s0 = bytearray(binaryfile.read())
  with open(s1_filename, "rb") as binaryfile :
      s1 = bytearray(binaryfile.read())


  #search_str = "MEMDUMP"
  #search_array = bytearray()
  #search_array.extend(map(ord, search_str))
  search_array = b"MEMDUMP\x00"
  memdump_offset = s0.find(search_array)
  memdump_start_offset = memdump_offset + 22 + 4
  # MEMDUMP contents from c64/c64memsnapshot.c:
  #if (0
  #    || SMW_B(m, pport.data) < 0
  #    || SMW_B(m, pport.dir) < 0
  #    || SMW_B(m, export.exrom) < 0
  #    || SMW_B(m, export.game) < 0
  #    || SMW_BA(m, mem_ram, C64_RAM_SIZE) < 0
  #    || SMW_B(m, pport.data_out) < 0
  #    || SMW_B(m, pport.data_read) < 0
  #    || SMW_B(m, pport.dir_read) < 0
  #    || SMW_DW(m, (uint32_t)pport.data_set_clk_bit6) < 0
  #    || SMW_DW(m, (uint32_t)pport.data_set_clk_bit7) < 0
  #    || SMW_B(m, pport.data_set_bit6) < 0
  #    || SMW_B(m, pport.data_set_bit7) < 0
  #    || SMW_B(m, pport.data_falloff_bit6) < 0
  #    || SMW_B(m, pport.data_falloff_bit7) < 0) {
  #    snapshot_module_close(m);
  #    return -1;
  #}
  initial_mem = s0[memdump_start_offset:memdump_start_offset+65536]


  search_array = b"SID\x00"
  sid_offset = s0.find(search_array)
  sid_start_offset = sid_offset + 22 + 3
  # MEMDUMP contents from c64/c64memsnapshot.c:
  #if (0
  #    || SMW_B(m, pport.data) < 0
  #    || SMW_B(m, pport.dir) < 0
  #    || SMW_B(m, export.exrom) < 0
  #    || SMW_B(m, export.game) < 0
  #    || SMW_BA(m, mem_ram, C64_RAM_SIZE) < 0
  #    || SMW_B(m, pport.data_out) < 0
  #    || SMW_B(m, pport.data_read) < 0
  #    || SMW_B(m, pport.dir_read) < 0
  #    || SMW_DW(m, (uint32_t)pport.data_set_clk_bit6) < 0
  #    || SMW_DW(m, (uint32_t)pport.data_set_clk_bit7) < 0
  #    || SMW_B(m, pport.data_set_bit6) < 0
  #    || SMW_B(m, pport.data_set_bit7) < 0
  #    || SMW_B(m, pport.data_falloff_bit6) < 0
  #    || SMW_B(m, pport.data_falloff_bit7) < 0) {
  #    snapshot_module_close(m);
  #    return -1;
  #}
  initial_sid = s0[sid_start_offset:sid_start_offset+0x20]
  dump_mem("SID ", initial_sid, 0, 32)

  #search_str = "PEXDUMP4"
  #search_array = bytearray()
  #search_array.extend(map(ord, search_str))
  search_array = b"PEXDUMP4\x00"
  pexdump_offset = s1.find(search_array)
  pexdump_length_offset = pexdump_offset + 22 + 8
  pexdump_list_offset = pexdump_offset + 22 + 8 + 4
  pexdump_length = (s1[pexdump_length_offset+3] << 24) + (s1[pexdump_length_offset+2] << 16) + (s1[pexdump_length_offset+1] << 8) + s1[pexdump_length_offset]
  # PEXDUMP4 contents from c64/c64memsnapshot.c:
  #static const char snap_mem_module_name_second[] = "PEXDUMP4";
  #if (0
  #    || SMW_DW(m2, 0xcafedada) < 0
  #    || SMW_DW(m2, 0x1337babe) < 0) {
  #    snapshot_module_close(m2);
  #    return -1;
  #}
  #printf("SAVING pexdump size=%08x", pexdump_size);
  #unsigned int saved_size = pexdump_size;
  #// Write the memory write trace data here:
  #if (SMW_DW(m2, saved_size) < 0) {
  #    snapshot_module_close(m2);
  #    return -1;
  #}
  #if (SMW_BA(m2, pexdump, saved_size) < 0) {
  #    snapshot_module_close(m2);
  #    return -1;
  #}
  #if (0
  #    || SMW_DW(m2, 0xbeefb0de) < 0
  #    || SMW_DW(m2, 0xaffeeda6) < 0) {
  #    snapshot_module_close(m2);
  #    return -1;
  #}
  print ("pexdump_offset=0x%06x, pexdump_length=0x%08x" % (pexdump_offset, pexdump_length))
  dump_mem("pexd", s1, pexdump_list_offset, 64)


  #search_str = "VIC-II"
  #search_array = bytearray()
  #search_array.extend(map(ord, search_str))
  search_array = b"VIC-II\x00"
  vic2_offset = s0.find(search_array)
  vic2_colmem_offset = vic2_offset + 365721 - 364942
  vic2_colmem = s0[vic2_colmem_offset:vic2_colmem_offset+1024]
  vic2_initial_colmem = bytearray(1000)
  for i in range(1000):
    vic2_initial_colmem[i] = s0[vic2_colmem_offset + i]
  vic2_regs_offset = vic2_offset + 364972 - 364942 - 7
  vic2_regs = bytearray()
  vic2_regs[0:64] = s0[vic2_regs_offset:vic2_regs_offset+64]
  vic2_rasterline_offset = vic2_regs_offset - 2
  vic2_rasterline = (s0[vic2_rasterline_offset+1] << 8) + s0[vic2_rasterline_offset]
  vic2_rastercycle_offset = vic2_rasterline_offset - 1
  vic2_rastercycle = s0[vic2_rastercycle_offset]
  #vic2_bank_addr_offset = vic2_rastercycle_offset - 4
  #vic2_bank_addr = (s0[vic2_bank_addr_offset+3] << 24) + (s0[vic2_bank_addr_offset+2] << 16) + (s0[vic2_bank_addr_offset+1] << 8) + s0[vic2_bank_addr_offset]
  # VIC-II contents from c64/vicii-snapshot.c:
  #if (0
  #    /* AllowBadLines */
  #    || SMW_B(m, (uint8_t)vicii.allow_bad_lines) < 0
  #    /* BadLine */
  #    || SMW_B(m, (uint8_t)vicii.bad_line) < 0
  #    /* Blank */
  #    || SMW_B(m, (uint8_t)vicii.raster.blank_enabled) < 0
  #    /* ColorBuf */
  #    || SMW_BA(m, vicii.cbuf, 40) < 0
  #    /* ColorRam */
  #    || SMW_BA(m, color_ram, 1024) < 0
  #    /* IdleState */
  #    || SMW_B(m, (uint8_t)vicii.idle_state) < 0
  #    /* LPTrigger */
  #    || SMW_B(m, (uint8_t)vicii.light_pen.triggered) < 0
  #    /* LPX */
  #    || SMW_B(m, (uint8_t)vicii.light_pen.x) < 0
  #    /* LPY */
  #    || SMW_B(m, (uint8_t)vicii.light_pen.y) < 0
  #    /* MatrixBuf */
  #    || SMW_BA(m, vicii.vbuf, 40) < 0
  #    /* NewSpriteDmaMask */
  #    || SMW_B(m, vicii.raster.sprite_status->new_dma_msk) < 0
  #    /* RamBase */
  #    || SMW_DW(m, (uint32_t)(vicii.ram_base_phi1 - mem_ram)) < 0
  #    /* RasterCycle */
  #    || SMW_B(m, (uint8_t)(VICII_RASTER_CYCLE(maincpu_clk))) < 0
  #    /* RasterLine */
  #    || SMW_W(m, (uint16_t)(VICII_RASTER_Y(maincpu_clk))) < 0) {
  #    goto fail;
  #}
  #for (i = 0; i < 0x40; i++) {
  #    /* Registers */
  #    if (SMW_B(m, vicii.regs[i]) < 0) {
  #        goto fail;
  #    }
  #}
  #if (0
  #    /* SbCollMask */
  #    || SMW_B(m, (uint8_t)vicii.sprite_background_collisions) < 0
  #    /* SpriteDmaMask */
  #    || SMW_B(m, (uint8_t)vicii.raster.sprite_status->dma_msk) < 0
  #    /* SsCollMask */
  #    || SMW_B(m, (uint8_t)vicii.sprite_sprite_collisions) < 0
  #    /* VBank */
  #    || SMW_W(m, (uint16_t)vicii.vbank_phi1) < 0
  #    /* Vc */
  #    || SMW_W(m, (uint16_t)vicii.mem_counter) < 0
  #    /* VcInc */
  #    || SMW_B(m, (uint8_t)vicii.mem_counter_inc) < 0
  #    /* VcBase */
  #    || SMW_W(m, (uint16_t)vicii.memptr) < 0
  #    /* VideoInt */
  #    || SMW_B(m, (uint8_t)vicii.irq_status) < 0) {
  #    goto fail;
  #}
  #for (i = 0; i < 8; i++) {
  #    if (0
  #        /* SpriteXMemPtr */
  #        || SMW_B(m, (uint8_t)vicii.raster.sprite_status->sprites[i].memptr) < 0
  #        /* SpriteXMemPtrInc */
  #        || SMW_B(m, (uint8_t)vicii.raster.sprite_status->sprites[i].memptr_inc) < 0
  #        /* SpriteXExpFlipFlop */
  #        || SMW_B(m, (uint8_t)vicii.raster.sprite_status->sprites[i].exp_flag) < 0) {
  #        goto fail;
  #    }
  #}
  #if (0
  #    /* FetchEventTick */
  #    || SMW_DW(m, vicii.fetch_clk - maincpu_clk) < 0
  #    /* FetchEventType */
  #    || SMW_B(m, (uint8_t)vicii.fetch_idx) < 0) {
  #    goto fail;
  #}
  #if (0
  #    /* RamBase */
  #    || SMW_DW(m, (uint32_t)(vicii.ram_base_phi2 - mem_ram)) < 0
  #    /* VBank */
  #    || SMW_W(m, (uint16_t)vicii.vbank_phi2) < 0) {
  #    goto fail;
  #}
  dump_mem("col ", vic2_colmem, 0x0000, 48)
  #print("vic2_bank_addr=0x%08x" % vic2_bank_addr)
  print("vic2_rastercycle=0x%02x" % vic2_rastercycle)
  print("vic2_rasterline=0x%03x" % vic2_rasterline)
  dump_mem("vic ", vic2_regs, 0, 64)
  print ("memdump_offset=0x%06x, vic2_offset=0x%06x" % (memdump_offset, vic2_offset))

  search_array = b"CIA2\x00"
  cia2_offset = s0.find(search_array)
  cia2_bank_offset = cia2_offset + 22
  cia2_bank = s0[cia2_bank_offset] & 0x03
  cia2_bank_addr = 0xc000 - (cia2_bank << 14)
  # Want to know:
  # c64/c64cia2.c: static int vbank;
  #ciacore_snapshot_write_module
  # From src/core/ciacore.c:
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_PRA]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_PRB]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_DDRA]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_DDRB]));
  #SMW_W(m, ciat_read_timer(cia_context->ta, *(cia_context->clk_ptr)));
  #SMW_W(m, ciat_read_timer(cia_context->tb, *(cia_context->clk_ptr)));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_TOD_TEN]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_TOD_SEC]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_TOD_MIN]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_TOD_HR]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_SDR]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_ICR]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_CRA]));
  #SMW_B(m, (uint8_t)(cia_context->c_cia[CIA_CRB]));
  #SMW_W(m, ciat_read_latch(cia_context->ta, *(cia_context->clk_ptr)));
  #SMW_W(m, ciat_read_latch(cia_context->tb, *(cia_context->clk_ptr)));
  #SMW_B(m, ciacore_peek(cia_context, CIA_ICR));
  #/* Bits 2 & 3 are compatibility to snapshot format v1.0 */
  #SMW_B(m, (uint8_t)((cia_context->tat ? 0x40 : 0)
  #                | (cia_context->tbt ? 0x80 : 0)
  #                | (ciat_is_underflow_clk(cia_context->ta,
  #                                         *(cia_context->clk_ptr)) ? 0x04 : 0)
  #                | (ciat_is_underflow_clk(cia_context->tb, *(cia_context->clk_ptr))
  #                   ? 0x08 : 0)));
  #SMW_B(m, (uint8_t)cia_context->sr_bits);
  #SMW_B(m, cia_context->todalarm[0]);
  #SMW_B(m, cia_context->todalarm[1]);
  #SMW_B(m, cia_context->todalarm[2]);
  #SMW_B(m, cia_context->todalarm[3]);
  print ("cia2_bank=0x%02x -> cia2_bank_addr=0x%04x" % (cia2_bank, cia2_bank_addr))





  # This is the place to "fast forward" to the first clock cycle:
  first_clockcycle = ((s1[pexdump_list_offset] & 0x7f) << 16) + (s1[pexdump_list_offset+1] << 8) + s1[pexdump_list_offset]
  print("first_cc=0x%08x" % first_clockcycle)

  fast_forward_cycles = 0
  if game_name == 'AIRWOLF':
    fast_forward_cycles = (0*313+(313-64)) * 63
  if game_name == 'new/DOTC':
    fast_forward_cycles = (2*313+(313-150)) * 63
  if game_name == 'ARCHON':
    #fast_forward_cycles = (1*313+(313-64)) * 63
    fast_forward_cycles = (1*313+(313-128)) * 63
  elif game_name == 'Arkanoid':
    #fast_forward_cycles = 0  # All sprites gone except for bat
    #fast_forward_cycles = (0*313+(313-128)) * 63  # Enemies there, but ball jumps incoherently
    #fast_forward_cycles = (0*313+(313-64)) * 63 # All sprites gone except for bat
    #fast_forward_cycles = (0*313+(313-192)) * 63  # Enemies there, but ball jumps incoherently
    #fast_forward_cycles = (0*313+(313-256)) * 63  # Enemies there, but ball jumps incoherently
    #fast_forward_cycles = (313 + 40) * 63  # Enemies there, but ball jumps incoherently after a while
    #fast_forward_cycles = (313 + 120) * 63  # Enemies there, but ball jumps incoherently after a while
    #fast_forward_cycles = (313 + 220) * 63  # Enemies there, but ball jumps incoherently after a while
    fast_forward_cycles = (313 + 225) * 63  # Enemies there, but ball jumps incoherently after a while
    #fast_forward_cycles = (313 + 235) * 63  # Enemies there, but ball jumps incoherently after a while
    #fast_forward_cycles = (313 + 250) * 63  # Only "pad border" is visible"
  elif game_name == 'SPYHUNT':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'new/HERO':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'new/DROPZONE':
    fast_forward_cycles = (0*313+(313-200)) * 63
  elif game_name == 'new/COMMANDO_6':
    fast_forward_cycles = (0*313+(313-250)) * 63
  elif game_name == 'new/COMMANDO_7':
    fast_forward_cycles = (0*313+(313-200)) * 63
  elif game_name == 'new/COMMANDO_4':
    fast_forward_cycles = (8*313+(313-100)) * 63
  elif game_name == 'new/COMMANDO_2':
    fast_forward_cycles = (0*313+(313-200)) * 63
  elif game_name == 'new/COMMANDO_3':
    fast_forward_cycles = (0*313+(313-200)) * 63
  elif game_name == 'new/COMMANDO_5':
    fast_forward_cycles = (0*313+(313-200)) * 63
  elif game_name == 'CAULDRN2':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'AMC':
    fast_forward_cycles = (3*313+(313-64)) * 63
  elif game_name == 'new/BRUCELEE':
#    fast_forward_cycles = (4*313+(313-200)) * 63
#NOK    fast_forward_cycles = (4*313+(313-100)) * 63
    fast_forward_cycles = (4*313+(313-250)) * 63
  elif game_name == 'BRUCELEE':
    fast_forward_cycles = (4*313+(313-100)) * 63
  elif game_name == '1942':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'JETSET':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'AGENTUSA':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'BOMBO':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'HORACEGS':
    fast_forward_cycles = (2*313+(313-224)) * 63
  elif game_name == 'BOUNTYB':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'SUMRGAME':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'LOCO':
    fast_forward_cycles = (20*313+(313-64)) * 63
  elif game_name == 'KETTLE':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'GGOBLINS':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'BBOBBLE':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'BCBILL':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'BCQUEST':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'BLLAMP':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'CALGAMES':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'CHUCKEGG':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'MINR2049':
    fast_forward_cycles = (0*313+(313-256)) * 63
  elif game_name == 'UNDERWLD':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'THRUST':
    fast_forward_cycles = (1*313+(313-192)) * 63
  elif game_name == 'JJUNIOR':
    fast_forward_cycles = (1*313+(313-64)) * 63
  elif game_name == 'WGAMES':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'ELITE':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'ISOCCR88':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'POGOJOE':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'PENGO':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'PARADROI':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'KIDGRID':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'LODERUNR4':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'SPCPILOT':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'Matrix':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'BIGGLES':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'FRIDAY13':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'NEVENDST':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'MRDOCAST':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'MIKIE':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'new/KRAKOUT':
    fast_forward_cycles = (10*313+(313-0)) * 63
  elif game_name == 'HOUSEJCK':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'HARDHATM':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'GREMLINS':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'TRAP':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'SKOOLDAZ':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'updown':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'MANICMIN':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'SPYDEMIS':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'BOUNTYB':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'TROLLIEW':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'SURVIVOR':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'ROLAND':
    #fast_forward_cycles = (0*313+(313-192)) * 63  <- sprites and game ok, but SID sound is lacking one channel
    #fast_forward_cycles = (0*313+(313-64)) * 63  #<- all sprites became non-multicolour, but SID is correct!
    #fast_forward_cycles = (1*313+(313-128)) * 63  #<- all sprites became non-multicolour, but SID is correct!
    fast_forward_cycles = (1*313+(313-256)) * 63
  elif game_name == 'WIZBALL':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'MERMAIDM':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'GREENBRT':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'YIEAR':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'FORTAPOC':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'HYPERSPR':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'THINGBOU':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'DRUID2':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'FRAK':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'ROBOCOP2':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'MOUNKING':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'HEROGOLD':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'URIDIUM_2':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'CAULDRN2_2':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'RASTAN':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'MARIOBRS':
    fast_forward_cycles = (0*313+(313-64)) * 63
  elif game_name == 'SKATE-1':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'Pedro':
    fast_forward_cycles = (0*313+(313-192)) * 63
  elif game_name == 'ManiacMansion':
    fast_forward_cycles = (0*313+(313-128)) * 63
  elif game_name == 'CAVELON':
    fast_forward_cycles = (0*313+(313-128)) * 63


  print("fast_forward_cycles=0x%08x" % fast_forward_cycles)

  stop_at = first_clockcycle + fast_forward_cycles
  print("stop_at=0x%08x" % stop_at)

  prev_clockcycle = first_clockcycle
  clockcycle_wrap_counter = 0
  list_offset = pexdump_list_offset
  if fast_forward_cycles > 0:
    print("Special case: %s - doing FAST FORWARDING" % game_name)
    while True:
      if ((list_offset+5)>len(s1)):
        break
      clockcycle = ((s1[list_offset] & 0x7f) << 16) + (s1[list_offset+1] << 8) + s1[list_offset+2]
      if clockcycle < (prev_clockcycle - 0x400000):
        clockcycle_wrap_counter += 0x00800000
      prev_clockcycle = clockcycle
      clockcycle = clockcycle + clockcycle_wrap_counter
      ##print("fast_forwarding_cc=0x%08x" % clockcycle)
      addr = (s1[list_offset+4] << 8) + s1[list_offset+3]
      byte = s1[list_offset+5]
      io_nmem = (s1[list_offset] & 0x80) >> 7
      if (io_nmem == 1) and (addr >= 0xd400) and (addr <= 0xd418):
        initial_sid[addr-0xd400] = byte
        #print("change SID  0x%04x->%02x" % (addr, byte))
      elif (io_nmem == 1) and (addr >= 0xd800) and (addr <= 0xdbe7):
        vic2_colmem[addr-0xd800] = byte
        #print("change COL  0x%04x->%02x" % (addr, byte))
      elif (io_nmem == 1) and (addr >= 0xd000) and (addr <= 0xd02e):
        vic2_regs[addr-0xd000] = byte
        if (addr==0xd018) or (addr==0xd016) or (addr==0xd019) or (addr==0xd012) or (addr==0xd011) or (addr==0xd020) or (addr==0xd021):
          print("%6d change VIC  0x%04x->%02x" % (clockcycle, addr, byte))
      elif ((game_name == 'ROBOCOP2') or (game_name == 'DRUID2')) and (io_nmem == 1) and (addr >= 0xdc00) and (addr <= 0xdcff):
        # Just ignore.
        pass
      elif addr == 0xdd00:
        cia2_bank = byte & 0x03
        cia2_bank_addr = 0xc000 - (cia2_bank << 14)
        print("%6d change CIA2 0x%04x->%02x" % (clockcycle, addr, byte))
      else:
        initial_mem[addr] = byte
        #print("change MEM  0x%04x->%02x" % (addr, byte))
      if clockcycle >= stop_at:
        break
      list_offset += 6

    dump_mem("vic ", vic2_regs, 0, 64)

  if vic2_regs[0x11] & 0x20 == 0x20:
    print("FATAL! %s uses bitmap graphics, and that's not supported." % game_name)
    die

  clockcycle_start = stop_at
  list_offset_start = list_offset
  clocks_per_frame = 19656 #63 * 312
  clockcycle_end = clockcycle_start + (NOF_FRAMES_TO_ENCODE + 2) * clocks_per_frame

  print("clockcycle_start=0x%08x" % clockcycle_start)
  print("clockcycle_end=0x%08x" % clockcycle_end)





  # Time to find out where the screen is today:
  #vic2_d018 cn be found at vic2_regs[0x18]
  #Bits #1-#3: In text mode, pointer to character memory (bits #11-#13), relative to VIC bank, memory address $DD00. Values:
  #%000, 0: $0000-$07FF, 0-2047.
  #%001, 1: $0800-$0FFF, 2048-4095.
  #%010, 2: $1000-$17FF, 4096-6143.
  #%011, 3: $1800-$1FFF, 6144-8191.
  #%100, 4: $2000-$27FF, 8192-10239.
  #%101, 5: $2800-$2FFF, 10240-12287.
  #%110, 6: $3000-$37FF, 12288-14335.
  #%111, 7: $3800-$3FFF, 14336-16383.
  #Values %010 and %011 in VIC bank #0 and #2 select Character ROM instead.In bitmap mode, pointer to bitmap memory (bit #13), relative to VIC bank, memory address $DD00. Values:
  #%0xx, 0: $0000-$1FFF, 0-8191.
  #%1xx, 4: $2000-$3FFF, 8192-16383.
  #Bits #4-#7: Pointer to screen memory (bits #10-#13), relative to VIC bank, memory address $DD00. Values:
  #%0000, 0: $0000-$03FF, 0-1023.
  #%0001, 1: $0400-$07FF, 1024-2047.
  #%0010, 2: $0800-$0BFF, 2048-3071.
  #%0011, 3: $0C00-$0FFF, 3072-4095.
  #%0100, 4: $1000-$13FF, 4096-5119.
  #%0101, 5: $1400-$17FF, 5120-6143.
  #%0110, 6: $1800-$1BFF, 6144-7167.
  #%0111, 7: $1C00-$1FFF, 7168-8191.
  #%1000, 8: $2000-$23FF, 8192-9215.
  #%1001, 9: $2400-$27FF, 9216-10239.
  #%1010, 10: $2800-$2BFF, 10240-11263.
  #%1011, 11: $2C00-$2FFF, 11264-12287.
  #%1100, 12: $3000-$33FF, 12288-13311.
  #%1101, 13: $3400-$37FF, 13312-14335.
  #%1110, 14: $3800-$3BFF, 14336-15359.
  #%1111, 15: $3C00-$3FFF, 15360-16383.
  charset_addr = cia2_bank_addr + (((vic2_regs[0x18] & 0x0e) >> 1) * 0x0800)
  screen_addr = cia2_bank_addr + (((vic2_regs[0x18] & 0xf0) >> 4) * 0x0400)
  initial_screen = bytearray(1000)
  #initial_screen = initial_mem[screen_addr:screen_addr+1000]
  for i in range(1000):
    initial_screen[i] = initial_mem[screen_addr+i]

  print ("charset_addr=0x%04x" % (charset_addr))
  dump_mem("MEM ", initial_mem, charset_addr, 64)
  print ("screen_addr=0x%04x" % (screen_addr))
  dump_mem("MEM ", initial_mem, screen_addr, 64)

  sprite_poi_addr = screen_addr + 0x03f8
  print ("sprite_poi_addr=0x%04x" % (sprite_poi_addr))
  dump_mem("MEM ", initial_mem, sprite_poi_addr, 8)



  # This is the place to erase parts of the screen:
  nof_rows_to_erase_at_top = 0
  nof_rows_to_erase_at_bottom = 0
  erase_col = True
  if game_name == 'BLUETHUN':
    nof_rows_to_erase_at_top = 4
    fillcol = 0
    fillchar = 1
  elif game_name == 'ROBOCOP2':
    nof_rows_to_erase_at_top = 3
    fillchar = 0
    fillcol = 0
  elif game_name == 'GBUSTERS':
    nof_rows_to_erase_at_bottom = 5
    fillchar = 0
    fillcol = 0
  elif game_name == 'LAZYJONE':
    nof_rows_to_erase_at_bottom = 1
    fillchar = 0
    fillcol = 0
  elif game_name == 'ZENJI':
    nof_rows_to_erase_at_top = 1
    fillchar = 0
    fillcol = 0
  elif game_name == 'GILLGOLD':
    nof_rows_to_erase_at_top = 2
    fillchar = 0
    fillcol = 0
  elif game_name == 'YIEAR2':
    nof_rows_to_erase_at_top = 2
    fillchar = 0
    fillcol = 0
  elif game_name == 'GORF':
    nof_rows_to_erase_at_bottom = 1
    fillchar = 0
    fillcol = 0
  elif game_name == 'new/KRAKOUT':
    nof_rows_to_erase_at_top = 2
    fillchar = 0
    fillcol = 0
  elif game_name == 'LOCO':
    nof_rows_to_erase_at_top = 3
    fillchar = 0
    fillcol = 0
  elif game_name == 'new/COMMANDO_7':
    nof_rows_to_erase_at_bottom = 4
    fillchar = 1
    fillcol = 0
  elif game_name == 'new/HERO':
    nof_rows_to_erase_at_bottom = 9
    fillchar = 0
    fillcol = 0
  elif game_name == 'MERMAIDM':
    nof_rows_to_erase_at_top = 6
    fillchar = 0
    fillcol = 0
  elif game_name == 'RAIDMOSC':
    fillcol = 1
    for row in range(5):
      this_row = 24-row
      for char in range(40):
        #initial_mem[screen_addr + this_row*40 + char] = fillchar
        #initial_screen[this_row*40 + char] = fillchar
        vic2_initial_colmem[this_row*40 + char] = fillcol
        vic2_colmem[this_row*40 + char] = fillcol
  elif game_name == 'new/RAIDMOSC':
    fillcol = 1
    for row in range(5):
      this_row = 24-row
      for char in range(40):
        #initial_mem[screen_addr + this_row*40 + char] = fillchar
        #initial_screen[this_row*40 + char] = fillchar
        vic2_initial_colmem[this_row*40 + char] = fillcol
        vic2_colmem[this_row*40 + char] = fillcol
  elif game_name == 'new/BRUCELEE':
    nof_rows_to_erase_at_top = 2
    fillchar = 1
    fillcol = 0
  elif game_name == 'FRAK':
    nof_rows_to_erase_at_top = 4
    fillchar = 0
    fillcol = 0
  elif game_name == 'ManiacMansion':
    nof_rows_to_erase_at_bottom = 7
    fillchar = 0
    fillcol = 0
  elif game_name == 'SPEEDRAC':
    nof_rows_to_erase_at_top = 1
    fillchar = 0
    fillcol = 0
  elif game_name == 'URIDIUM_2':
    nof_rows_to_erase_at_top = 5
    fillchar = 1
    fillcol = 0
  elif game_name == 'new/MULE':
    nof_rows_to_erase_at_bottom = 12
    fillchar = 0
    fillcol = 7
  elif game_name == 'CAULDRN2_2':
    nof_rows_to_erase_at_top = 5
    fillchar = 0
    fillcol = 0
  elif game_name == 'RASTAN':
    nof_rows_to_erase_at_top = 4
    fillchar = 0
    fillcol = 0
  elif game_name == 'DRUID2':
    nof_rows_to_erase_at_bottom = 9
    fillchar = 1
    fillcol = 0
  elif game_name == 'GHETTOBL':
    nof_rows_to_erase_at_top = 14
    fillchar = 1
    fillcol = 0
  elif game_name == 'THINGBOU':
    nof_rows_to_erase_at_bottom = 8
    fillchar = 0
    fillcol = 0
  elif game_name == 'GROG':
    nof_rows_to_erase_at_bottom = 8
    fillchar = 1
    fillcol = 0
  elif game_name == 'GROGSREV_3':
    nof_rows_to_erase_at_bottom = 8
    fillchar = 1
    fillcol = 0
  elif game_name == 'GAUNTLET':
    print("GAUNTLET initial d800")
    print("initial colmem=$%02x" % vic2_initial_colmem[0*40 + 10])
    print("initial sceen=$%02x" % initial_mem[screen_addr + 0*40 + 10])
    #die
    nof_rows_to_erase_at_top = 2
    nof_rows_to_erase_at_bottom = 5
    erase_col = False
    fillchar = 1
    fillcol = 8
  elif game_name == 'SAMFOX':
    nof_rows_to_erase_at_top = 19
    fillchar = 1
    fillcol = 0
  elif game_name == 'ANTIRIAD':
    nof_rows_to_erase_at_bottom = 8
    fillchar = 1
    fillcol = 0
  elif game_name == 'AIRWOLF':
    nof_rows_to_erase_at_bottom = 8
    fillchar = 1
    fillcol = 0
  elif game_name == 'SKRAMBLE6':
    nof_rows_to_erase_at_bottom = 25
    fillchar = 0
    fillcol = 0
  elif game_name == 'PARADROI':
    nof_rows_to_erase_at_top = 8
    fillchar = 0
    fillcol = 0
  elif game_name == 'MASTLAMP':
    nof_rows_to_erase_at_bottom = 1
    fillchar = 0
    fillcol = 0
  elif game_name == 'HIGHNOON':
    nof_rows_to_erase_at_top = 1
    fillchar = 1
    fillcol = 6
  elif game_name == 'new/OILSWELL':
    nof_rows_to_erase_at_top = 3
    fillchar = 0
    fillcol = 0
  elif game_name == 'FORTAPOC':
    nof_rows_to_erase_at_top = 6
    fillchar = 0
    fillcol = 0
  elif game_name == 'BIGGLES':
    nof_rows_to_erase_at_top = 2
    nof_rows_to_erase_at_bottom = 6
    fillchar = 1
    fillcol = 0
  elif game_name == 'SHAMUS2_':
    nof_rows_to_erase_at_bottom = 1
    nof_rows_to_erase_at_top = 3
    fillchar = 1
    fillcol = 0
  elif game_name == 'GGOBLINS':
    nof_rows_to_erase_at_bottom = 7
    fillchar = 1
    fillcol = 0
  elif game_name == 'BLLAMP':
    nof_rows_to_erase_at_bottom = 3
    nof_rows_to_erase_at_top = 2
    fillchar = 1
    fillcol = 0
  elif game_name == '1942':
    nof_rows_to_erase_at_top = 2
    fillchar = 0
    fillcol = 6
  if nof_rows_to_erase_at_top > 0:
    print("Special case for %s, erasing %d lines at top" % (game_name, nof_rows_to_erase_at_top))
    for row in range(nof_rows_to_erase_at_top):
      for char in range(40):
        initial_mem[screen_addr + row*40 + char] = initial_mem[screen_addr + 24*40]
        initial_screen[row*40 + char] = fillchar
        if erase_col == True:
          vic2_initial_colmem[row*40 + char] = fillcol
          vic2_colmem[row*40 + char] = fillcol
  if nof_rows_to_erase_at_bottom > 0:
    print("Special case for %s, erasing %d lines at bottom" % (game_name, nof_rows_to_erase_at_bottom))
    for row in range(nof_rows_to_erase_at_bottom):
      this_row = 24-row
      for char in range(40):
        initial_mem[screen_addr + this_row*40 + char] = fillchar
        initial_screen[this_row*40 + char] = fillchar
        if erase_col == True:
          vic2_initial_colmem[this_row*40 + char] = fillcol
          vic2_colmem[this_row*40 + char] = fillcol

  if game_name == 'TAPPER':
    print("Special case for %s, erasing board in the middle" % (game_name))
    for row in range(2,6):
      for char in range(16,24):
        fillchar = 0
        fillcol = 5
        initial_mem[screen_addr + row*40 + char] = initial_mem[screen_addr + 24*40]
        initial_screen[row*40 + char] = fillchar
        vic2_initial_colmem[row*40 + char] = fillcol
        vic2_colmem[row*40 + char] = fillcol

  # Save space by removing chars with the same col as bg:
  # Don't do this for multicol chars
  if (vic2_regs[0x16] & 0x10 == 0x00) and (game_name != 'ANTIRIAD'):
    bg_col = vic2_regs[0x21]
    blank_char = 0
    # Find a char that is used and is empty
    for char_no in range(1000):
      if (vic2_colmem[char_no]) != bg_col:
        this_is_the_one = True
        this_char = initial_screen[char_no]
        for x in range(8):
          if initial_mem[charset_addr + this_char * 8 + x] != 0:
            this_is_the_one = False
        if this_is_the_one:
          blank_char = this_char
    # Find a chars to blank out
    for char_no in range(1000):
      if (vic2_colmem[char_no]) == bg_col:
        initial_screen[char_no] = blank_char

  # This actually makes packing worse:
  ## Save space by removing bgcols with empty chars in them:
  ## Find a char that is used and is empty
  #if (game_name == 'ARCHON') or (game_name == 'REVENGE'):
  #  pass
  #else:
  #  bg_col = vic2_regs[0x21]
  #  for char_no in range(1000):
  #    this_char = initial_screen[char_no]
  #    this_char_is_empty = True
  #    for x in range(8):
  #      if initial_mem[charset_addr + this_char * 8 + x] != 0:
  #        this_char_is_empty = False
  #    if this_char_is_empty:
  #      vic2_colmem[char_no] = vic2_colmem[char_no-1]


  # Check which chars that are used initially:
  chars_used = [0] * 256
  for screen_offset in range(1000):
    this_char = initial_mem[screen_addr + screen_offset]
    chars_used[this_char] += 1

  # count how many chars used from charset initially:
  nof_chars_used = 0
  for char_no in range(256):
    if (chars_used[char_no] > 0):
      nof_chars_used += 1
  print("nof_chars_used in charset initially=%d" % nof_chars_used)

  sprite_xoffset_due_to_d016 = 0

  # Fix all d016 to make screen 40 chars always:
  if (game_name != 'KILLWATT'):
    sprite_xoffset_due_to_d016 = vic2_regs[0x16] & 0x07
    vic2_regs[0x16] = (vic2_regs[0x16] | 0x08) & 0xf8
  if (game_name == 'URIDIUM_2'):
    vic2_regs[0x16] = 0xd8

  # Fix all d011 to make screen not scrolled:
  sprite_yoffset_due_to_d011 = (vic2_regs[0x11] & 0x07) - 0x03
  vic2_regs[0x11] = (vic2_regs[0x11] & 0xf8) | 0x03


  remove_all_sprites = False
  # Delete all sprite activity in these games:
  if (game_name == 'URIDIUM_2'):
    remove_all_sprites = True
  elif (game_name == 'Paperboy'):
    remove_all_sprites = True
  elif (game_name == 'ManiacMansion'):
    remove_all_sprites = True
  elif (game_name == 'RAMBO'):
    remove_all_sprites = True
  elif (game_name == 'FLIPA737_2'):
    remove_all_sprites = True
  elif (game_name == 'new/DOTC'):
    remove_all_sprites = True
  elif (game_name == 'PIRATES1'):
    remove_all_sprites = True
  elif (game_name == 'PacMan'):
    remove_all_sprites = True
  elif (game_name == 'CKHAFKA2'):
    remove_all_sprites = True
  elif (game_name == 'GHETTOBL'):
    remove_all_sprites = True
  elif (game_name == 'NEBULUS'):
    remove_all_sprites = True
  elif (game_name == 'WIZARDOW'):
    remove_all_sprites = True
  elif (game_name == 'NEVENDST2'):
    remove_all_sprites = True

  if game_name == 'DRUID2':
    # We shall remove sprite #1
    vic2_regs[0x15] = 0xfe

  if remove_all_sprites == True:
    vic2_regs[0x00] = 0
    vic2_regs[0x01] = 0
    vic2_regs[0x02] = 0
    vic2_regs[0x03] = 0
    vic2_regs[0x04] = 0
    vic2_regs[0x05] = 0
    vic2_regs[0x06] = 0
    vic2_regs[0x07] = 0
    vic2_regs[0x08] = 0
    vic2_regs[0x09] = 0
    vic2_regs[0x0a] = 0
    vic2_regs[0x0b] = 0
    vic2_regs[0x0c] = 0
    vic2_regs[0x0d] = 0
    vic2_regs[0x0e] = 0
    vic2_regs[0x0f] = 0
    vic2_regs[0x10] = 0
    vic2_regs[0x15] = 0
    vic2_regs[0x17] = 0
    vic2_regs[0x1b] = 0
    vic2_regs[0x1c] = 0
    vic2_regs[0x1d] = 0
    vic2_regs[0x25] = 0
    vic2_regs[0x26] = 0
    vic2_regs[0x27] = 0
    vic2_regs[0x28] = 0
    vic2_regs[0x29] = 0
    vic2_regs[0x2a] = 0
    vic2_regs[0x2b] = 0
    vic2_regs[0x2c] = 0
    vic2_regs[0x2d] = 0
    vic2_regs[0x2e] = 0


  # Check which sprites that are in use initially:
  sprites_used = [0] * 256
  tmp_d015 = vic2_regs[0x15]
  tmp_d017 = vic2_regs[0x17]
  tmp_d010 = vic2_regs[0x10]
  for sprite_no in range(8):
    this_sprite = initial_mem[screen_addr + 0x03f8 + sprite_no]
    # Check whether this sprite is enabled:
    this_sprite_is_used = True
    if ((tmp_d015 & 0x01) == 0x00):
      this_sprite_is_used = False
    #if (vic2_regs[0x01 + sprite_no*2] >= 0xfa):
    #  this_sprite_is_used = False
    #sprite_end_row = vic2_regs[0x01 + sprite_no*2] + 21
    #if ((tmp_d017 & 0x01) == 0x01):
    #  sprite_end_row += 21
    #if (sprite_end_row < 0x30):
    #  this_sprite_is_used = False
    #spr_xpos = vic2_regs[0x00 + sprite_no*2]
    #if ((tmp_d010 & 0x01) == 0x01):
    #  spr_xpos += 256
    #if (spr_xpos > 0x18 + 320):
    #  this_sprite_is_used = 0
    #if (spr_xpos == 0):
    #  this_sprite_is_used = 0
    if this_sprite_is_used:
      sprites_used[this_sprite] += 1
    tmp_d015 = tmp_d015 >> 1
    tmp_d017 = tmp_d017 >> 1
    tmp_d010 = tmp_d010 >> 1

  # count how many sprites used initially:
  nof_sprites_used = 0
  for spr_no in range(256):
    if (sprites_used[spr_no] > 0):
      nof_sprites_used += 1
  print("nof_sprites_used initially=%d" % nof_sprites_used)





  # Check that no illegal changes to mem are done:
  # $d018 is not allowed to change:
  #orig_d018 = vic2_regs[0x18]
  #orig_dd00 = cia2_bank
  #list_offset = list_offset_start
  #while True:
  #  if ((list_offset+5)>len(s1)):
  #    break
  #  clockcycle = ((s1[list_offset] & 0x7f) << 16) + (s1[list_offset+1] << 8) + s1[list_offset+2]
  #  addr = (s1[list_offset+4] << 8) + s1[list_offset+3]
  #  byte = s1[list_offset+5]
  #  io_nmem = (s1[list_offset] & 0x80) >> 7
  #  if (io_nmem == 1) and (addr == 0xd018):
  #    if byte != orig_d018:
  #      print("ERROR: %s addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (game_name, addr, byte, clockcycle, orig_d018))
  #  if (io_nmem == 1) and (addr == 0xdd00):
  #    if (byte & 0x03) != orig_dd00:
  #      print("ERROR: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, orig_dd00))
  #  list_offset += 6
  #  if clockcycle >= clockcycle_end:
  #    break


  # Make a list of all values that do change during the next 100 frames
  values_to_track = {}
  # This is a shallow copy:
  #current_vic2_regs = vic2_regs
  # This is a deep copy, which is what we wanted:
  current_vic2_regs = vic2_regs[0:0x40]
  # This is a shallow copy:
  #current_mem = initial_mem
  # This is a deep copy, which is what we wanted:
  current_mem = bytearray(65536)
  current_mem[0:65536] = initial_mem[0:65536]

  current_sid = initial_sid[0:0x20]
  current_colour = vic2_colmem[0:1000]
  list_offset = list_offset_start
  clockcycle = clockcycle_start & 0x007fffff
  prev_clockcycle = clockcycle
  #print(" prev_cc0x%08x" % (prev_clockcycle))
  clockcycle_wrap_counter = 0
  while True:
    if ((list_offset+5)>len(s1)):
      break
    clockcycle = ((s1[list_offset] & 0x7f) << 16) + (s1[list_offset+1] << 8) + s1[list_offset+2]
    #print(" cc0x%08x" % (clockcycle))
    if clockcycle < (prev_clockcycle - 0x400000):
      clockcycle_wrap_counter += 0x0800000
    prev_clockcycle = clockcycle
    clockcycle = clockcycle + clockcycle_wrap_counter
    addr = (s1[list_offset+4] << 8) + s1[list_offset+3]
    byte = s1[list_offset+5]
    io_nmem = (s1[list_offset] & 0x80) >> 7
    #print(" cc0x%08x addr=0x%04x, byte=0x%02x" % (clockcycle, addr, byte))
    change = False
    if (io_nmem == 1) and (addr >= 0xd400) and (addr <= 0xd414):
      # SID writings
      last_value = current_sid[addr-0xd400]
      if byte != last_value:
        change = True
        #print("SID_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_sid[addr-0xd400] = byte
    elif (io_nmem == 1) and (addr >= 0xd416) and (addr <= 0xd418):
      # SID writings
      last_value = current_sid[addr-0xd400]
      if byte != last_value:
        change = True
        #print("SID_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_sid[addr-0xd400] = byte
    elif (io_nmem == 1) and (addr >= 0xd800) and (addr <= 0xdbe7):
      # Colour ram writings
      last_value = current_colour[addr-0xd800]
      byte = byte & 0x0f
      if byte != last_value:
        change = True
        #print("SID_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_colour[addr-0xd800] = byte
    elif (io_nmem == 1) and (addr >= 0xd000) and (addr <= 0xd010):
      last_value = current_vic2_regs[addr-0xd000]
      if byte != last_value:
        change = True
        #print("SPR_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_vic2_regs[addr-0xd000] = byte
    elif (io_nmem == 1) and (addr >= 0xd015) and (addr <= 0xd017):
      last_value = current_vic2_regs[addr-0xd000]
      if (addr == 0xd016):
        # Fix all d016 to make screen 40 chars always:
        byte = (byte | 0x08) & 0xf8
      if byte != last_value:
        change = True
        #print("VIC_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_vic2_regs[addr-0xd000] = byte
      if (addr == 0xd015):
        # Check which sprites that are in use now:
        tmp_d015 = byte
        if (game_name == 'DRUID2'):  # Hide sprite #1, which is just black and ugly.
          byte = byte & 0xfe
        for sprite_no in range(8):
          this_sprite = current_mem[screen_addr + 0x03f8 + sprite_no]
          # Check whether this sprite is enabled:
          if ((tmp_d015 & 0x01) == 0x01):
            sprites_used[this_sprite] += 1
          tmp_d015 = tmp_d015 >> 1
    elif (io_nmem == 1) and (addr >= 0xd01b) and (addr <= 0xd01d):
      last_value = current_vic2_regs[addr-0xd000]
      if byte != last_value:
        change = True
        #print("VIC_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_vic2_regs[addr-0xd000] = byte
    elif (io_nmem == 1) and (addr >= 0xd020) and (addr <= 0xd02e):
      last_value = current_vic2_regs[addr-0xd000]
      if byte != last_value:
        change = True
        #print("VIC_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_vic2_regs[addr-0xd000] = byte
    elif (io_nmem == 0) and (addr >= screen_addr) and (addr <= screen_addr + 0x3e7):
      last_value = current_mem[addr]
      # Ignore writes to erased part of screen (1942):
      if (nof_rows_to_erase_at_top > 0) and (addr < screen_addr+(nof_rows_to_erase_at_top*40)):
        # do nothing
        pass
      elif (nof_rows_to_erase_at_bottom > 0) and (addr >= screen_addr+((25-nof_rows_to_erase_at_bottom)*40)):
        # do nothing
        pass
      elif byte != last_value:
        change = True
        #print("SCREEN_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        # Make sure that this char is added to the export as well:
        chars_used[byte] += 1
        current_mem[addr] = byte
    elif (io_nmem == 0) and (addr >= screen_addr+0x03f8) and (addr <= screen_addr + 0x03ff):
      last_value = current_mem[addr]
      if byte != last_value:
        change = True
        #print("SPRPOI_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        # Make sure that this sprite is added to the export as well:
        sprites_used[byte] += 1
        current_mem[addr] = byte
    elif (io_nmem == 0) and (addr >= charset_addr) and (addr <= charset_addr + 0x7ff):
      last_value = current_mem[addr]
      if byte != last_value:
        change = True
        #print("CHARSET_CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
        current_mem[addr] = byte
    elif (io_nmem == 0) and (addr >= cia2_bank_addr) and (addr <= (cia2_bank_addr + 0x3fff)):
      if game_name != 'SNOKIE':
        last_value = current_mem[addr]
        # This might be a write into a sprite:
        if byte != last_value:
          change = True
          #print("COULD BE SPRITE DATA CHANGE: addr 0x%04x was written to 0x%02x at clock cycle 0x%06x, but was 0x%02x initially." % (addr, byte, clockcycle, last_value))
          current_mem[addr] = byte

    if change:
      if (addr in values_to_track) == False:
        values_to_track[addr] = []
        # Now we need to add "the initial value" into this list, to make encoding easier:
        the_initial = {}
        the_initial['byte'] = last_value
        the_initial['clockcycle'] = clockcycle_start
        the_initial['io_nmem'] = io_nmem
        values_to_track[addr].append(the_initial)
      the_change = {}
      the_change['byte'] = byte
      the_change['clockcycle'] = clockcycle
      the_change['io_nmem'] = io_nmem
      values_to_track[addr].append(the_change)

    list_offset += 6
    if clockcycle >= clockcycle_end:
      break

  # And here, add a last value that is really far away in time, for each address:
  for addr in values_to_track:
    byte = values_to_track[addr][len(values_to_track[addr])-1]['byte']
    cc = values_to_track[addr][len(values_to_track[addr])-1]['clockcycle']
    io_nmem = values_to_track[addr][len(values_to_track[addr])-1]['io_nmem']
    the_change = {}
    the_change['byte'] = byte
    the_change['clockcycle'] = clockcycle + 5000000
    the_change['io_nmem'] = io_nmem
    if (addr in values_to_track) == True:
      values_to_track[addr].append(the_change)


  # Debug print COMMANDO:
  #addr = 0xe1f7
  #print("EVENT LIST: 0x%04x:" % addr)
  ##print(len(values_to_track[addr]))
  #for event_no in range(len(values_to_track[addr])):
  #  print(" cc%08x io=%d byte=0x%02x" % (values_to_track[addr][event_no]['clockcycle'], values_to_track[addr][event_no]['io_nmem'], values_to_track[addr][event_no]['byte']))

  # Debug print for SID:
  #print("SID debug print:")
  #last_clockcycle = 0
  #current_sid = initial_sid[0:0x20]
  #list_offset = pexdump_list_offset
  #while True:
  #  if ((list_offset+5)>len(s1)):
  #    break
  #  clockcycle = ((s1[list_offset] & 0x7f) << 16) + (s1[list_offset+1] << 8) + s1[list_offset+2]
  #  addr = (s1[list_offset+4] << 8) + s1[list_offset+3]
  #  byte = s1[list_offset+5]
  #  if (addr >= 0xd400) and (addr <= 0xd41f):
  #    last_value = current_sid[addr-0xd400]
  #    current_sid[addr-0xd400] = byte
  #    s = "%6d" % (clockcycle - last_clockcycle)
  #    for a in range(0,0x19):
  #      if (addr & 0x1f) == a:
  #        s += "*"
  #      else:
  #        s += " "
  #      s += "%02x" % current_sid[a]
  #    print(s)
  #    last_clockcycle = clockcycle
  #  list_offset += 6
  #  if clockcycle >= clockcycle_end:
  #    break




  # Special case: remove sprites:
  if (remove_all_sprites == True) or (game_name == 'COMMANDO') or (game_name == 'COMMANDO_4'):
    print("Special case %s, removing sprites" % game_name)
    for i in range(256):
      sprites_used[i] = 0
    values_to_track.pop(0xd000, None)
    values_to_track.pop(0xd001, None)
    values_to_track.pop(0xd002, None)
    values_to_track.pop(0xd003, None)
    values_to_track.pop(0xd004, None)
    values_to_track.pop(0xd005, None)
    values_to_track.pop(0xd006, None)
    values_to_track.pop(0xd007, None)
    values_to_track.pop(0xd008, None)
    values_to_track.pop(0xd009, None)
    values_to_track.pop(0xd00a, None)
    values_to_track.pop(0xd00b, None)
    values_to_track.pop(0xd00c, None)
    values_to_track.pop(0xd00d, None)
    values_to_track.pop(0xd00e, None)
    values_to_track.pop(0xd00f, None)
    values_to_track.pop(0xd010, None)
    values_to_track.pop(0xd015, None)
    values_to_track.pop(0xd017, None)
    values_to_track.pop(0xd01b, None)
    values_to_track.pop(0xd01c, None)
    values_to_track.pop(0xd01d, None)
    values_to_track.pop(0xd025, None)
    values_to_track.pop(0xd026, None)
    values_to_track.pop(0xd027, None)
    values_to_track.pop(0xd028, None)
    values_to_track.pop(0xd029, None)
    values_to_track.pop(0xd02a, None)
    values_to_track.pop(0xd02b, None)
    values_to_track.pop(0xd02c, None)
    values_to_track.pop(0xd02d, None)
    values_to_track.pop(0xd02e, None)

  remove_all_audio = False
  if (game_name == 'GAUNTLET'):
    remove_all_audio = True
  if (game_name == 'SKRAMBLE6'):
    remove_all_audio = True
  if (game_name == 'ISOCCR88'):
    remove_all_audio = True
  if (game_name == 'FRAK'):
    remove_all_audio = True
  if (game_name == 'IMPMISSN'):
    remove_all_audio = True
  if (game_name == 'new/OILSWELL'):
    remove_all_audio = True
  if (game_name == 'SKATE-1'):
    remove_all_audio = True
  if (game_name == 'PIRATES1'):
    remove_all_audio = True
  if (game_name == 'WORLDCUP'):
    remove_all_audio = True

  # Special case: remove audio:
  if (remove_all_audio == True):
    print("Special case %s, removing audio" % game_name)
    values_to_track.pop(0xd400, None)
    values_to_track.pop(0xd401, None)
    values_to_track.pop(0xd402, None)
    values_to_track.pop(0xd403, None)
    values_to_track.pop(0xd404, None)
    values_to_track.pop(0xd405, None)
    values_to_track.pop(0xd406, None)
    values_to_track.pop(0xd407, None)
    values_to_track.pop(0xd408, None)
    values_to_track.pop(0xd409, None)
    values_to_track.pop(0xd40a, None)
    values_to_track.pop(0xd40b, None)
    values_to_track.pop(0xd40c, None)
    values_to_track.pop(0xd40d, None)
    values_to_track.pop(0xd40e, None)
    values_to_track.pop(0xd40f, None)
    values_to_track.pop(0xd410, None)
    values_to_track.pop(0xd411, None)
    values_to_track.pop(0xd412, None)
    values_to_track.pop(0xd413, None)
    values_to_track.pop(0xd414, None)
    values_to_track.pop(0xd415, None)
    values_to_track.pop(0xd416, None)
    values_to_track.pop(0xd417, None)
    values_to_track.pop(0xd418, None)


  # Now we know which chars and sprites that are used.
  # Make a translation table to be able to map change addresses pointing
  # to sprites to the correct memory location.

  # Gather the chars to export:
  charset_export = bytearray()
  # The translation from "old char numbers" into the exported charset:
  oldchar_is_now = [-1] * 256
  # First char is always blank:
  charset_export.extend(b"\x00\x00\x00\x00\x00\x00\x00\x00")
  # Second char is always filled:
  charset_export.extend(b"\xff\xff\xff\xff\xff\xff\xff\xff")


  game_counter_colour = info["col"] & 0x0f
  game_counter_char = 2
  game_counter_inverted = (info["col"] & 0x10) / 16

  # Third char is the game counter:
  if game_counter_inverted == 1:
    charset_export.extend(b"\xff\xff\xff\xff\xff\xff\xff\xff")
  else:
    charset_export.extend(b"\x00\x00\x00\x00\x00\x00\x00\x00")

  # Set the colour of the game counter char:
  vic2_initial_colmem[40 + 38] = game_counter_colour
  # We will need to set this again if "erase lines" is used.

  # Order chars from "fewest pixels" into "most pixels"

  # remap a blank one into char #0
  # remap a filled one into char #1
  # Now pack all other chars into the exported charset:
  char_no_in_export = 3
  for char_no in range(256):
    if (chars_used[char_no] > 0):
      mem_addr = charset_addr + char_no*8
      # Check if blank:
      is_empty = True
      is_filled = True
      if (game_name == 'ANTIRIAD'):
        is_empty = False
        is_filled = False
      for x in range(8):
        if initial_mem[mem_addr + x] != 0:
          is_empty = False
        if initial_mem[mem_addr + x] != 255:
          is_filled = False
      if is_empty == True:
        dump_mem("empt",initial_mem,mem_addr,8)
        oldchar_is_now[char_no] = 0
      elif is_filled == True:
        dump_mem("fill",initial_mem,mem_addr,8)
        oldchar_is_now[char_no] = 1
      else:
        charset_export.extend(initial_mem[mem_addr:mem_addr+8])
#        charset_export.extend(b"\x00\x00\x00\x00\x00\x00\x00\x00")
        oldchar_is_now[char_no] = char_no_in_export
        char_no_in_export += 1
  nof_chars_in_export = char_no_in_export
  print("%03d nof_chars_used for game_no=%d in export '%s'" % (nof_chars_in_export, game_no+1, game_name))
  nof_chars_free = 256 - nof_chars_in_export
  print("%03d nof_chars_free for game_no=%d in export '%s'" % (nof_chars_free, game_no+1, game_name))

  # A dummy char at the end that we will remove later:
  charset_export.extend(b"\x00\x00\x00\x00\x00\x00\x00\x00")

  # Reshuffle the chars to make them smaller:
  done_swapping = False
  rounds = 0
  while (rounds < 20) and not done_swapping:
    done_swapping = True
    for char1 in range(3,nof_chars_in_export):
      for char2 in range(char1+1,nof_chars_in_export):
        #print("c1=%02d<>%02d" % (char1, char2))
        # Check if it's a good idea to swap these chars:
        char1_score = 0
        if (charset_export[(char1<<3)] == charset_export[(char1<<3)-1]):
          char1_score += 10
          if (charset_export[(char1<<3)] == charset_export[(char1<<3)-2]):
            char1_score += 10
            if (charset_export[(char1<<3)] == charset_export[(char1<<3)-3]):
              char1_score += 10
        if (charset_export[(char1<<3)+7] == charset_export[(char1<<3)+8]):
          char1_score += 10
          if (charset_export[(char1<<3)+7] == charset_export[(char1<<3)+9]):
            char1_score += 10
            if (charset_export[(char1<<3)+7] == charset_export[(char1<<3)+10]):
              char1_score += 10
        char2_score = 0
        if (charset_export[(char2<<3)] == charset_export[(char2<<3)-1]):
          char2_score += 10
          if (charset_export[(char2<<3)] == charset_export[(char2<<3)-2]):
            char2_score += 10
            if (charset_export[(char2<<3)] == charset_export[(char2<<3)-3]):
              char2_score += 10
        if (charset_export[(char2<<3)+7] == charset_export[(char2<<3)+8]):
          char2_score += 10
          if (charset_export[(char2<<3)+7] == charset_export[(char2<<3)+9]):
            char2_score += 10
            if (charset_export[(char2<<3)+7] == charset_export[(char2<<3)+10]):
              char2_score += 10
        # See what the score would be swapped with 2:
        char1_swapscore = 0
        if (charset_export[(char1<<3)] == charset_export[(char2<<3)-1]):
          char1_swapscore += 10
          if (charset_export[(char1<<3)] == charset_export[(char2<<3)-2]):
            char1_swapscore += 10
            if (charset_export[(char1<<3)] == charset_export[(char2<<3)-3]):
              char1_swapscore += 10
        if (charset_export[(char1<<3)+7] == charset_export[(char2<<3)+8]):
          char1_swapscore += 10
          if (charset_export[(char1<<3)+7] == charset_export[(char2<<3)+9]):
            char1_swapscore += 10
            if (charset_export[(char1<<3)+7] == charset_export[(char2<<3)+10]):
              char1_swapscore += 10
        char2_swapscore = 0
        if (charset_export[(char2<<3)] == charset_export[(char1<<3)-1]):
          char2_swapscore += 10
          if (charset_export[(char2<<3)] == charset_export[(char1<<3)-2]):
            char2_swapscore += 10
            if (charset_export[(char2<<3)] == charset_export[(char1<<3)-3]):
              char2_swapscore += 10
        if (charset_export[(char2<<3)+7] == charset_export[(char1<<3)+8]):
          char2_swapscore += 10
          if (charset_export[(char2<<3)+7] == charset_export[(char1<<3)+9]):
            char2_swapscore += 10
            if (charset_export[(char2<<3)+7] == charset_export[(char1<<3)+10]):
              char2_swapscore += 10
        # Now determine if we should swap these:
        if (char1_score + char2_score) < (char1_swapscore + char2_swapscore):
          # Yes, do swap:
          done_swapping = False
          tmp_char2 = bytearray()
          tmp_char2 = charset_export[char2<<3:((char2<<3)+8)]
          charset_export[char2<<3:((char2<<3)+8)] = charset_export[char1<<3:((char1<<3)+8)]
          charset_export[char1<<3:((char1<<3)+8)] = tmp_char2
          for oldchar_no in range(256):
            if oldchar_is_now[oldchar_no] == char1:
              oldchar_is_now[oldchar_no] = -10
          for oldchar_no in range(256):
            if oldchar_is_now[oldchar_no] == char2:
              oldchar_is_now[oldchar_no] = char1
          for oldchar_no in range(256):
            if oldchar_is_now[oldchar_no] == -10:
              oldchar_is_now[oldchar_no] = char2
          print("Swapped chars %02d<>%02d" % (char1, char2))
    rounds += 1

  # Remove the tmp zeroes:
  charset_export = charset_export[0:(len(charset_export)-8)]

  # Save the chars:
  with open(chars_output_filename, "wb") as newFile:
      newFile.write(charset_export)



  # Need to round the sprite offset upwards to the next 0x40 offset:
  nof_dummy_chars = 8 - (nof_chars_in_export - ((nof_chars_in_export >> 3) << 3))
  if (nof_dummy_chars >= 8):
    nof_dummy_chars -= 8
  print("nof_dummy_chars=0x%02x" % nof_dummy_chars)
  sprite_offset_in_file = 0x0800 + ((nof_chars_in_export + nof_dummy_chars) << 3)
  #print("sprite_offset_in_file=0x%04x" % sprite_offset_in_file)

  # Gather the sprites to export:
  sprites_export = bytearray()
  # The translation from "old char numbers" into the exported charset:
  oldsprite_is_now = [-1] * 256

  # Pack all sprites into the exported sprites:
  #if game_addr == "LO":
  #  # For sprites in LO games, start putting them "after the charset" at $4000-
  #  # up until -$47bf
  #  # Then, put the rest at ;$4c00-      SPRITES_LO_SECONDARY (the rest of them)
  #  spr_no_in_export = ((nof_chars_in_export + nof_dummy_chars) << 3) >> 6
  #  if spr_no_in_export >= (((0x47c0 - 0x4000) >> 6)):
  #    spr_no_in_export = (0x4c00 - 0x4000) >> 6
  #else:
  #  # For sprites in HI games, start putting them "after the charset" at $7800-
  #  # up until -$7fbf
  #  # Then, put the rest at -$73ff
  #  spr_no_in_export = (0x7800 - 0x4000 + ((nof_chars_in_export + nof_dummy_chars) << 3)) >> 6
  #  if spr_no_in_export >= (((0x7fc0 - 0x4000) >> 6)):
  #    spr_no_in_export = (0x73c0 - 0x4000) >> 6

  # NO! - Put all sprites out of the way. Make sure that the last chars in the charset are free to copy greetingstext into:
  if game_addr == "LO":
      spr_no_in_export = (0x4c00 - 0x4000) >> 6
  else:
      spr_no_in_export = (0x73c0 - 0x4000) >> 6

  print("sprites_used:")
  print(sprites_used)
  sprstr = ""
  for spr_no in range(256):
    sprstr += chr(sprites_used[spr_no] + 0x30)
  print(sprstr)

  nof_sprites_in_export = 0
  for spr_no in range(256):
    if (sprites_used[spr_no] > 0):
      mem_addr = cia2_bank_addr + spr_no*0x40
      sprites_export.extend(initial_mem[mem_addr:mem_addr+0x40])
      oldsprite_is_now[spr_no] = spr_no_in_export
      # Switch to new spr_no_in_export
      if spr_no_in_export == (((0x4780 - 0x4000) >> 6)):
        print("### Going from 0x4780 to 0x4c00")
        spr_no_in_export = (0x4c00 - 0x4000) >> 6
      elif spr_no_in_export == (((0x7f80 - 0x4000) >> 6)):
        print("### Going from 0x7f80 to 0x73c0")
        spr_no_in_export = (0x73c0 - 0x4000) >> 6
      elif spr_no_in_export >= (((0x7800 - 0x4000) >> 6)):
        print("### Going from 0x7800 upwards")
        spr_no_in_export += 1
      elif spr_no_in_export >= (((0x6000 - 0x4000) >> 6)):
        print("### Going from 0x6000 downwards")
        spr_no_in_export -= 1
      else:
        spr_no_in_export += 1
      nof_sprites_in_export += 1
  print("nof_sprites_used in export=0x%02x" % nof_sprites_in_export)

  print("oldsprite_is_now table:")
  s = ""
  for i in range(256):
    if (oldsprite_is_now[i] != 0):
      s += "0x%02x->0x%02x, " % (i, oldsprite_is_now[i])
  print(s)

  # Make a curated list of addresses that are changed,
  # and add a last value that is really far away in time...
  nof_addresses_to_track = 0
  string_to_track = ""
  for addr in values_to_track:
    nof_addresses_to_track += 1
    string_to_track += "$%04x " % addr
#    last_value = values_to_track[addr][len(values_to_track[addr])-1]['byte']
#    last_clockcycle = values_to_track[addr][len(values_to_track[addr])-1]['clockcycle']
#    last_io = values_to_track[addr][len(values_to_track[addr])-1]['io_nmem']
#    the_change = {}
#    the_change['byte'] = last_value
#    the_change['clockcycle'] = last_clockcycle + 10000000
#    the_change['io_nmem'] = last_io
#    values_to_track[addr].append(the_change)
  print("All addr to track=%s" % string_to_track)
  print("nof_addresses_to_track=%d" % nof_addresses_to_track)
  if (nof_addresses_to_track > 255):
    print("FATAL: More than 255 addresses to track for %s" % game_name)
    die


  if game_name == "SHAMUS":
    print("Special case: %s" % game_name)
    # Erase all multicolor-events for SHAMUS:
    del values_to_track[0xd016]
    # And make sure it's muticolour all along:
    vic2_regs[0x16] = 0x18
  if game_name == 'URIDIUM':
    print("Special case: %s" % game_name)
    del values_to_track[0xd021]
  #if game_name == 'COMMANDO':
  #  # Not allowed to write into charset, since iomem bit is not correctly recorded:
  #  print("Special case %s" % game_name)
  #  for i in range(0x1000):
  #    addr = 0xd000 + i
  #    if addr in values_to_track:
  #      del values_to_track[addr]
  #  #for i in range(500):
  #  #  addr = screen_addr + i
  #  #  if addr in values_to_track:
  #  #    del values_to_track[addr]

  if game_name == 'DRUID2':
    print("Special case: %s" % game_name)
    try:
      del values_to_track[0xd011]
    except:
      pass
    vic2_regs[0x11] = 0x1b
  if game_name == 'PITFALL2':
    print("Special case: %s" % game_name)
    try:
      del values_to_track[0xd011]
    except:
      pass
    vic2_regs[0x11] = 0x1b
  if game_name == 'PARADROI':
    print("Special case: %s" % game_name)
    try:
      del values_to_track[0xd011]
    except:
      pass
    vic2_regs[0x11] = 0x1b
  # Remove flashing sprites:
  if (game_name == 'GHETTOBL') or (game_name == 'ManiacMansion'):
    print("Special case: %s" % game_name)
    try:
      del values_to_track[0xd025]
    except:
      pass
    try:
      del values_to_track[0xd026]
    except:
      pass
    try:
      del values_to_track[0xd027]
    except:
      pass
    try:
      del values_to_track[0xd028]
    except:
      pass
    try:
      del values_to_track[0xd029]
    except:
      pass
    try:
      del values_to_track[0xd02a]
    except:
      pass
    try:
      del values_to_track[0xd02b]
    except:
      pass
    try:
      del values_to_track[0xd02c]
    except:
      pass
    try:
      del values_to_track[0xd02d]
    except:
      pass
    try:
      del values_to_track[0xd02e]
    except:
      pass

  # Remove all d016 and d011 writes tracking:
  try:
    del values_to_track[0xd011]
  except:
    pass
  try:
    del values_to_track[0xd016]
  except:
    pass


  # Need to translate char, screen and sprite addresses to point to
  # our local addresses.
  values_to_track_translated = {}
  bank_addr = screen_addr & 0xc000
  for addr in values_to_track:
    new_addr = addr
    if (addr >= 0xd000) and (addr <= 0xd02f):
      # No need to translate this
      new_addr = addr
    elif (addr >= 0xd400) and (addr <= 0xd41f):
      # No need to translate this
      new_addr = addr
    elif (addr >= 0xd800) and (addr <= 0xdbe7):
      # No need to translate this
      new_addr = addr
    elif (addr >= 0xdc00) and (addr <= 0xdc0f):
      # No need to translate this
      new_addr = addr
    elif (addr >= 0xdd00) and (addr <= 0xdd0f):
      # No need to translate this
      new_addr = addr
    elif (addr >= screen_addr) and (addr <= screen_addr + 0x3e7):
      if game_addr == "LO":
        new_addr = addr - screen_addr + 0x4800
      else:
        new_addr = addr - screen_addr + 0x7400
      # Go through all in the list and translate chars:
      for event_no in range(len(values_to_track[addr])):
        old_char_no = values_to_track[addr][event_no]['byte']
        new_char_no = oldchar_is_now[old_char_no]
        values_to_track[addr][event_no]['byte'] = new_char_no
    elif (addr >= screen_addr + 0x03f8) and (addr <= screen_addr + 0x03ff):
      if game_addr == "LO":
        new_addr = addr - screen_addr + 0x4800
      else:
        new_addr = addr - screen_addr + 0x7400
      # Go through all in the list and translate sprite numbers:
      for event_no in range(len(values_to_track[addr])):
        old_sprite_no = values_to_track[addr][event_no]['byte']
        #new_sprite_no = oldsprite_is_now[old_sprite_no] + ((0x0800 + ((nof_chars_in_export + nof_dummy_chars) << 3)) >> 6)
        new_sprite_no = oldsprite_is_now[old_sprite_no]
        #print("MOVED SPR: addr=0x%04x, old_sprite_no=0x%02x, new_sprite_no=0x%02x, new_addr=0x%04x" % (addr, old_sprite_no, new_sprite_no, new_addr))
        if (new_sprite_no >= 0):
          values_to_track[addr][event_no]['byte'] = new_sprite_no
        else:
          values_to_track[addr][event_no]['byte'] = 0
          print("ERROR: a sprite pointer was set to a sprite that isn't part of the export. MOVED SPR: addr=0x%04x, old_sprite_no=0x%02x, new_sprite_no=0x%02x, new_addr=0x%04x" % (addr, old_sprite_no, new_sprite_no, new_addr))
    elif (addr >= charset_addr) and (addr <= charset_addr + 0x7ff):
      char_no = (addr - charset_addr) >> 3
      new_char_no = oldchar_is_now[char_no]
      if (new_char_no <= 1):
        # This is writing into a char that is never displayed. Skip this.
        new_addr = 0x10000
      else:
        if game_addr == "LO":
          new_addr = 0x4000 + (new_char_no << 3) + (addr & 0x0007)
        else:
          new_addr = 0x7800 + (new_char_no << 3) + (addr & 0x0007)
      print("WRITING INTO CHARSET: addr=0x%04x, char_no=0x%02x, new_char_no=0x%02x, new_addr=0x%04x" % (addr, char_no, new_char_no, new_addr))
    elif (addr >= bank_addr) and (addr <= bank_addr + 0x3fff):
      # This is probably writing into a sprite.
      old_sprite_no = (addr & 0x3fff) >> 6
      new_sprite_no = oldsprite_is_now[old_sprite_no]
      if (new_sprite_no < 0):
        # This is writing into a sprite that is never displayed. Skip this.
        new_addr = 0x10000
      else:
        #new_addr = 0x0800 + ((nof_chars_in_export + nof_dummy_chars) << 3) + new_sprite_no * 0x40 + (addr & 0x3f)
        new_addr = 0x4000 + new_sprite_no * 0x40 + (addr & 0x3f)
      #print("WRITING INTO SPRITE: addr=0x%04x, old_sprite_no=0x%02x, new_sprite_no=0x%02x, new_addr=0x%04x" % (addr, old_sprite_no, new_sprite_no, new_addr))
    if new_addr != 0x10000:
      # Deep copy the values into the new translated list:
      values_to_track_translated[new_addr] = []
      for event_no in range(len(values_to_track[addr])):
        values_to_track_translated[new_addr].append(values_to_track[addr][event_no])
      # If this is a d404, d40b or d412 write, let's copy it into its d504 d50b d512 counterpart:
      if (new_addr == 0xd404) or (new_addr == 0xd40b) or (new_addr == 0xd412):
        twin_addr = new_addr + 0x0100
        values_to_track_translated[twin_addr] = []
        for event_no in range(len(values_to_track[addr])):
          values_to_track_translated[twin_addr].append(values_to_track[addr][event_no])
    #print("old_addr=0x%04x -> 0x%04x" % (addr, new_addr))


  # And while we're at it, let's sort the memory positions as well:
  values_to_track_translated_order = sorted(values_to_track_translated.keys(), key=sort_order, reverse=True)
  s = "Tracked addresses in order: "
  for addr in values_to_track_translated_order:
    s += "0x%04x " % addr
  print(s)

  nof_addresses_to_track_translated = 0
  for addr in values_to_track_translated_order:
    nof_addresses_to_track_translated += 1
  print("nof_addresses_to_track_translated=%d" % nof_addresses_to_track_translated)


  display_lists_all_values = {}
  display_lists_values_that_need_writing = {}
  for addr in values_to_track_translated_order:
    clockcycle = clockcycle_start
    event_no = 0
    last_value = values_to_track_translated[addr][0]['byte']
    all_values = bytearray()
    values_that_need_writing = bytearray()
    all_values_intermediate = bytearray()
    intermediate_values_that_need_writing = bytearray()

    if (addr == 0xd012):
      die

    if (addr == 0xd404) or (addr == 0xd40b) or (addr == 0xd412) or (addr == 0xd504) or (addr == 0xd50b) or (addr == 0xd512):
      # For these addresses, we need to check if bit 0 or bit 3 has been written to "something else"
      # during this frame. If so, we need to write that as well.
      # This is done by making a "double speed" all_values list, marking neccessary writes as normal,
      # but then splicing the list into addresses d404 + d504.
      # The d404-list corresponds to changes within one frame, and the d504-list is the stable value after the frame.
      all_values_intermediate.append(last_value)
      all_values.append(last_value)
      values_that_need_writing.append(0)
      intermediate_values_that_need_writing.append(0)
      while clockcycle < clockcycle_end:
        clockcycle += clocks_per_frame
        value_at_start_of_frame = last_value
        intermediate_value = last_value
        an_intermediate_write_is_needed = 0
        a_write_is_needed = 0
        while values_to_track_translated[addr][event_no]['clockcycle'] < clockcycle:
          new_byte = values_to_track_translated[addr][event_no]['byte']
          if (a_write_is_needed == 1) and (last_value != new_byte) and (intermediate_value != last_value) and (an_intermediate_write_is_needed == 0):
            intermediate_value = last_value
            an_intermediate_write_is_needed = 1
          if last_value != new_byte:
            last_value = new_byte
            a_write_is_needed = 1
          if (event_no < len(values_to_track_translated[addr]) - 1):
            event_no += 1
          else:
            break
        all_values_intermediate.append(intermediate_value)
        intermediate_values_that_need_writing.append(an_intermediate_write_is_needed)
        all_values.append(last_value)
        values_that_need_writing.append(a_write_is_needed)
      # Choose if this is intermediate or stable version to be packed:
      if (addr == 0xd404) or (addr == 0xd40b) or (addr == 0xd412):
        print("This is intermediate version, since addr is 0x%04x" % addr)
        all_values = all_values_intermediate
        values_that_need_writing = intermediate_values_that_need_writing
      print("* 0x%04x Packing COULD BE INTERMEDIATE d4xx are intermediate:" % addr)
      s = ""
      for i in range(len(all_values)):
        s += "%02x" % all_values[i]
      print(s)
      s = ""
      for i in range(len(values_that_need_writing)):
        s += "%02x" % values_that_need_writing[i]
      print(s)
    else:
      # This is the normal version used for almost all addresses, except d404, d40b, d412
      while clockcycle < clockcycle_end:
        all_values.append(last_value)
        clockcycle += clocks_per_frame
        while values_to_track_translated[addr][event_no]['clockcycle'] < clockcycle:
          last_value = values_to_track_translated[addr][event_no]['byte']
          if (event_no < len(values_to_track_translated[addr]) - 1):
            event_no += 1
          else:
            break
      # First of all, mark the bytes that need to be written in all_values.
      # The first value in the list is already written, so only mark values after that one.
      current_poi = 0
      values_that_need_writing.append(0)
      while current_poi <= NOF_FRAMES_TO_ENCODE:
        if all_values[current_poi] == all_values[current_poi+1]:
          values_that_need_writing.append(0)
        else:
          values_that_need_writing.append(1)
        current_poi += 1
      print("* 0x%04x Packing:" % addr)
      s = ""
      for i in range(len(all_values)):
        s += "%02x" % all_values[i]
      print(s)
      s = ""
      for i in range(len(values_that_need_writing)):
        s += "%02x" % values_that_need_writing[i]
      print(s)

    display_lists_all_values[addr] = all_values
    display_lists_values_that_need_writing[addr] = values_that_need_writing


  # Remove the wheel in GROGSREV_3 after it's gone outside of the screen:
  if game_name == 'GROGSREV_3':
    print("Special case %s, removing the wheel sprite after a while (setting xpos = 0)" % game_name)
    for value_no in range(48,len(display_lists_all_values[0xd008])):
      display_lists_all_values[0xd008][value_no] = 0
    display_lists_values_that_need_writing[0xd008][48] = 1


  # This is the place to do sprite sorting, etc.
  # Each frame's values is present at display_lists_all_values[0xd000][frame_no]
  # Each frame's values is present at display_lists_all_values[0xd001][frame_no]
  # Each frame's values is present at display_lists_all_values[0xd017][frame_no]
  # display_lists_all_values[screen_add+0x3f8][frame_no]
  if game_addr == "LO":
    new_screen_addr = 0x4800
  else:
    new_screen_addr = 0x7400

  # Just sort the sprites depending on y-position.
  for frame_no in range(100):
    all_spr = {}
    #print("frame_no=%d" % frame_no)
    for spr_no in range(8):
      spr = {}
      #print("spr_no=%d" % spr_no)
      spr['ypos'] = vic2_regs[0x01 + spr_no*2]
      spr['xpos'] = vic2_regs[0x00 + spr_no*2]
      spr['xpos_msb'] = (vic2_regs[0x10] >> spr_no) & 0x01
      spr['mc'] = (vic2_regs[0x1c] >> spr_no) & 0x01
      spr['xsize'] = (vic2_regs[0x1d] >> spr_no) & 0x01
      spr['ysize'] = (vic2_regs[0x17] >> spr_no) & 0x01
      spr['prio'] = (vic2_regs[0x1b] >> spr_no) & 0x01
      spr['en'] = (vic2_regs[0x15] >> spr_no) & 0x01
      spr['col'] = vic2_regs[0x27 + spr_no]
      spr['poi'] = initial_mem[screen_addr + 0x03f8 + spr_no]
      try:
        spr['ypos'] = display_lists_all_values[0xd001 + spr_no*2][frame_no]
      except:
        pass
      try:
        spr['xpos_msb'] = (display_lists_all_values[0xd010][frame_no] >> spr_no) & 0x01
      except:
        pass
      try:
        spr['xpos'] = display_lists_all_values[0xd000 + spr_no*2][frame_no] + 0x100 * spr_xpos_msb
      except:
        pass
      try:
        spr['mc'] = (display_lists_all_values[0xd01c][frame_no] >> spr_no) & 0x01
      except:
        pass
      try:
        spr['xsize'] = (display_lists_all_values[0xd01d][frame_no] >> spr_no) & 0x01
      except:
        pass
      try:
        spr['ysize'] = (display_lists_all_values[0xd017][frame_no] >> spr_no) & 0x01
      except:
        pass
      try:
        spr['prio'] = (display_lists_all_values[0xd01b][frame_no] >> spr_no) & 0x01
      except:
        pass
      try:
        spr['en'] = (display_lists_all_values[0xd015][frame_no] >> spr_no) & 0x01
      except:
        pass
      try:
        spr['col'] = display_lists_all_values[0xd027 + spr_no][frame_no]
      except:
        pass
      try:
        spr['poi'] = display_lists_all_values[new_screen_addr + 0x03f8 + spr_no][frame_no]
      except:
        pass
      try:
        spr['old_spr_no'] = spr_no
      except:
        pass
      spr['xpos'] = spr['xpos'] + spr['xpos_msb'] * 0x100
      if spr['en'] != 1:
        spr['ypos'] = -1
      del(spr['xpos_msb'])
      all_spr[spr_no]=spr
    #print(all_spr)

    # Sort the sprites according to ypos and enabled:
    all_spr_sort = all_spr

    # And while we're at it, let's sort the sprites according to y-pos:
    #spr_order = sorted(all_spr.keys(), key=spr_sort_order, reverse=True)


    #spr_order = sorted(all_spr, key=all_spr[].ypos.__getitem__)

    #for key, value in sorted(mydict.items(), key=lambda item: item[1]):
    #    print("%s: %s" % (key, value))

    spr_to_sort = {}
    for spr_no in range(8):
      spr_to_sort[spr_no] = all_spr[spr_no]['ypos']
    spr_order = sorted(spr_to_sort.items(), key=lambda item: item[1])
    s = "sprites in order: "
    for key, value in spr_order:
      if (all_spr[key]['en'] == 1):
        s += "%d " % key  #value
    print(s)

    # Bin the sprites into 14 rows, and see how many of them there are in each bin for all the frames.
    # within a bin, sort the sprites from 0-7.
    nof_sprites_on_this_row = [0] * 313
    for spr_no, spr_ypos in spr_order:
      if (all_spr[spr_no]['en'] == 1):
        height = 21
        if (all_spr[spr_no]['ysize'] > 0):
          height = 42
        ystart = all_spr[spr_no]['ypos']
        for pixel_row in range(height):
          nof_sprites_on_this_row[ystart + pixel_row] += 1
    print(nof_sprites_on_this_row)

    # Find the max number:
    max_nof_sprites_on_a_line = 0
    for pixel_row in range(len(nof_sprites_on_this_row)):
      if nof_sprites_on_this_row[pixel_row] > max_nof_sprites_on_a_line:
        max_nof_sprites_on_a_line = nof_sprites_on_this_row[pixel_row]
    if (this_games_max_nof_sprites_on_a_line < max_nof_sprites_on_a_line):
      this_games_max_nof_sprites_on_a_line = max_nof_sprites_on_a_line

  # Can remove addresses from display_lists, and insert my sorted values somewhere in memory instead.
  # They will get packed, but I have no knowledge if they have been changed or written to this frame in main.s



  # Compensate for resetting d011 to 0x1b:
  for addr in values_to_track_translated_order:
    if (addr >= 0xd000) and (addr <= 0xd00f) and ((addr % 2) == 1):
      for byte_no in range(len(display_lists_all_values[addr])):
        new_value = display_lists_all_values[addr][byte_no] - sprite_yoffset_due_to_d011
        if new_value < 0:
          print ("###WARNING: game %s, yoffset=%d, addr=%04x, value=%d" % (game_name, sprite_yoffset_due_to_d011, addr, new_value))
          new_value = 0
        if new_value > 255:
          print ("###WARNING: game %s, yoffset=%d, addr=%04x, value=%d" % (game_name, sprite_yoffset_due_to_d011, addr, new_value))
          new_value = 255
        display_lists_all_values[addr][byte_no] = new_value
  for sprite_no in range(0,8):
    new_value = vic2_regs[1 + sprite_no * 2] - sprite_yoffset_due_to_d011
    if new_value < 0:
      print ("###WARNING: game %s, yoffset=%d, sprite_no=%04x, value=%d" % (game_name, sprite_yoffset_due_to_d011, sprite_no, new_value))
      new_value = 0
    if new_value > 255:
      print ("###WARNING: game %s, yoffset=%d, addr=%04x, value=%d" % (game_name, sprite_yoffset_due_to_d011, sprite_no, new_value))
      new_value = 255
    vic2_regs[1 + sprite_no * 2] = new_value

  # Compensate for resetting d016 to 0xc8:
  for addr in values_to_track_translated_order:
    if (addr >= 0xd000) and (addr <= 0xd00f) and ((addr % 2) == 0):
      for byte_no in range(len(display_lists_all_values[addr])):
        new_value = display_lists_all_values[addr][byte_no] - sprite_xoffset_due_to_d016
        if new_value < 0:
          print ("###ERROR: game %s, xoffset=%d, addr=%04x, value=%d" % (game_name, sprite_xoffset_due_to_d016, addr, new_value))
#          new_value += 256
          new_value = 0
        if new_value > 255:
          print ("###ERROR: game %s, xoffset=%d, addr=%04x, value=%d" % (game_name, sprite_xoffset_due_to_d016, addr, new_value))
#          new_value -= 256
          new_value = 255
      display_lists_all_values[addr][byte_no] = new_value
  for sprite_no in range(0,8):
    new_value = vic2_regs[sprite_no * 2] - sprite_xoffset_due_to_d016
    if new_value < 0:
      print ("###ERROR: game %s, xoffset=%d, sprite_no=%04x, value=%d" % (game_name, sprite_xoffset_due_to_d016, sprite_no, new_value))
#      new_value += 256
      new_value = 0
    if new_value > 255:
      print ("###ERROR: game %s, xoffset=%d, sprite_no=%04x, value=%d" % (game_name, sprite_xoffset_due_to_d016, sprite_no, new_value))
#      new_value -= 256
      new_value = 255
    vic2_regs[sprite_no * 2] = new_value



  display_lists = {}
  display_list_waits = {}
  for addr in values_to_track_translated_order:
    [list_wait, the_list] = pack_this_list(addr, display_lists_all_values[addr], display_lists_values_that_need_writing[addr])
    display_lists[addr] = the_list
    display_list_waits[addr] = list_wait


  # Translate the chars:
  for screen_cou in range(1000):
    #orig_char = initial_mem[screen_addr+screen_cou]
    #new_char = oldchar_is_now[orig_char]
    #initial_mem[screen_addr+screen_cou] = new_char

    orig_char = initial_screen[screen_cou]
    new_char = oldchar_is_now[orig_char]
    if (new_char >= 0):
      initial_screen[screen_cou] = new_char
    else:
      print("ERROR: initial_screen contains chars that are not saved: screencou=0x%04x, char=0x%02x" % (screen_cou, orig_char))
      initial_screen[screen_cou] = 0

  if nof_rows_to_erase_at_top > 0:
    print("Special case for %s, erasing %d lines at top" % (game_name, nof_rows_to_erase_at_top))
    for row in range(nof_rows_to_erase_at_top):
      for char in range(40):
        initial_screen[row*40 + char] = fillchar
        vic2_initial_colmem[row*40 + char] = fillcol
  if nof_rows_to_erase_at_bottom > 0:
    print("Special case for %s, erasing %d lines at bottom" % (game_name, nof_rows_to_erase_at_bottom))
    for row in range(nof_rows_to_erase_at_bottom):
      this_row = 24-row
      for char in range(40):
        initial_screen[this_row*40 + char] = fillchar
        vic2_initial_colmem[this_row*40 + char] = fillcol




  # Translate the sprite pointers:
  for sprite_no in range(8):
    orig_spr = initial_mem[screen_addr+0x03f8+sprite_no]
    new_spr = oldsprite_is_now[orig_spr]
    if (new_spr != -1):
      initial_mem[screen_addr+0x03f8+sprite_no] = new_spr
    else:
      initial_mem[screen_addr+0x03f8+sprite_no] = 0


  # Set the colour of the game counter char:
  vic2_initial_colmem[40 + 38] = game_counter_colour



  #{"name":'KRAKOUT'           ,"col":0x01, "y0":18,"x0": 2,"z0":40,"ccol0":0x07,"scol0": 7,"y1": 5,"x1":12,"z1":40,"ccol1":0x07,"scol1": 7},   #OK                         ### Silent ones ###       $34c6-$4c00
  #{"name":'SKATE-1'           ,"col":0x01, "y0": 0,"x0": 0,"z0":28,"ccol0":0x07,"scol0": 7,"y1":14,"x1":10,"z1":28,"ccol1":0x07,"scol1": 7},   #OK                                                   $7400-$8a31

  info['spr_x0'] = int(round(((info["x0"] + info["z0"]) / 2 - 20) * 8)) + 128
  info['spr_y0'] = info["y0"] * 8 + 50
  info['spr_x1'] = int(round(((info["x1"] + info["z1"]) / 2 - 20) * 8)) + 128
  info['spr_y1'] = info["y1"] * 8 + 50
  if info['spr_x0'] > 255:
    info['spr_x0'] = 255
  if info['spr_x0'] < 0:
    info['spr_x0'] = 0
  if info['spr_x1'] > 255:
    info['spr_x1'] = 255
  if info['spr_x1'] < 0:
    info['spr_x1'] = 0



  output_mem = bytearray()
  output_mem = [0] * 65536

  # Gather all information into output
  if game_addr == "LO":
    output_lowest_used_address = 0x3800
    output_highest_used_address = 0x4bff

    #LIST_END_LO = $3800
    # Stack the display lists up until $3800:
    current_poi = 0x3800
    for addr in values_to_track_translated_order:
      display_list_len = len(display_lists[addr])
      current_poi -= display_list_len
      output_mem[current_poi:current_poi+display_list_len] = display_lists[addr]
    output_lowest_used_address = current_poi

    #LIST_ADDR_LSB_LO = $3800 ;addr0_lo, addr1_lo, addr2_lo
    addr_no = 0
    for addr in values_to_track_translated_order:
      addr_to_display_list = addr
      if (addr == 0xd504) or (addr == 0xd50b) or (addr == 0xd512):
        addr_to_display_list = addr - 0x0100
      output_mem[0x3801 + addr_no] = addr_to_display_list & 0xff
      addr_no += 1

    #LIST_ADDR_MSB_LO = $3900 ;addr0_hi, addr1_hi,...
    addr_no = 0
    for addr in values_to_track_translated_order:
      addr_to_display_list = addr
      if (addr == 0xd504) or (addr == 0xd50b) or (addr == 0xd512):
        addr_to_display_list = addr - 0x0100
      output_mem[0x3901 + addr_no] = (addr_to_display_list >> 8) & 0xff
      addr_no += 1

    #LIST_POI_LO = $3a00 ;list0_poi, list1_poi,   ...counts downwards to zero. Zero means done. At start=list_length
    addr_no = 0
    for addr in values_to_track_translated_order:
      display_list_len = len(display_lists[addr])
      output_mem[0x3a01 + addr_no] = display_list_len
      addr_no += 1

    #LIST_WAIT_LO = $3b00 ;list0_wait, list1_wait, list2_wait
    addr_no = 0
    for addr in values_to_track_translated_order:
      output_mem[0x3b01 + addr_no] = display_list_waits[addr]
      addr_no += 1

    #COLRAM_LO = $3c00 ;-$3fe7
    output_mem[0x3c00:0x3fe8] = vic2_initial_colmem[0:1000]
    output_mem[0x3fe8] = info['ccol0']
    output_mem[0x3fe9] = info['scol0']
    output_mem[0x3fea] = info['spr_x0']
    output_mem[0x3feb] = info['spr_y0']
    output_mem[0x3fec] = info['ccol1']
    output_mem[0x3fed] = info['scol1']
    output_mem[0x3fee] = info['spr_x1']
    output_mem[0x3fef] = info['spr_y1']

    #CHARSET_LO = $4000
    output_mem[0x4000:0x4000 + len(charset_export)] = charset_export

    #;$4xx0-$47bf SPRITES_LO (some of them)

    #INITIAL_VALUES_LO = $47c0  ;-$47fe d000-d02e + d400-d418
    INITIAL_VALUES = 0x47c0

    #SCREEN_LO = $4800 ;-$4be7 SCREEN_LO
    output_mem[0x4800:0x4be8] = initial_screen[0:1000]

    #SPRPOI_LO = $4bf8 ;-$4bff SPRPOI_LO
    output_mem[0x4bf8:0x4c00] = initial_mem[screen_addr+0x03f8:screen_addr+0x0400]

    #;$4c00-      SPRITES_LO_SECONDARY (the rest of them)

  else:
    output_lowest_used_address = 0x7400
    output_highest_used_address = 0x8800

    #SPRITES2_HI (the rest of them) -$73ff

    #SCREEN_HI = $7400 ;-$77e7
    output_mem[0x7400:0x77e8] = initial_screen[0:1000]

    #SPRPOI_HI = $77f8 ;-$77ff
    output_mem[0x77f8:0x7800] = initial_mem[screen_addr+0x03f8:screen_addr+0x0400]

    INITIAL_VALUES = 0x7fc0

    #CHARSET_HI = $7800 ;-$7
    output_mem[0x7800:0x7800 + len(charset_export)] = charset_export

    #;$7xx0-$7fbf SPRITES_LO (some of them)

    #COLRAM_HI = $8000 ;-$83e7
    output_mem[0x8000:0x83e8] = vic2_initial_colmem[0:1000]
    output_mem[0x83e8] = info['ccol0']
    output_mem[0x83e9] = info['scol0']
    output_mem[0x83ea] = info['spr_x0']
    output_mem[0x83eb] = info['spr_y0']
    output_mem[0x83ec] = info['ccol1']
    output_mem[0x83ed] = info['scol1']
    output_mem[0x83ee] = info['spr_x1']
    output_mem[0x83ef] = info['spr_y1']

    #LIST_ADDR_LSB_HI = $8400 ;addr0_lo, addr1_lo, addr2_lo
    addr_no = 0
    for addr in values_to_track_translated_order:
      addr_to_display_list = addr
      if (addr == 0xd504) or (addr == 0xd50b) or (addr == 0xd512):
        addr_to_display_list = addr - 0x0100
      output_mem[0x8401 + addr_no] = addr_to_display_list & 0xff
      addr_no += 1

    #LIST_ADDR_MSB_HI = $8500 ;addr0_hi, addr1_hi,...
    addr_no = 0
    for addr in values_to_track_translated_order:
      addr_to_display_list = addr
      if (addr == 0xd504) or (addr == 0xd50b) or (addr == 0xd512):
        addr_to_display_list = addr - 0x0100
      output_mem[0x8501 + addr_no] = (addr_to_display_list >> 8) & 0xff
      addr_no += 1

    #LIST_POI_HI = $8600 ;list0_poi, list1_poi,   ...counts downwards to zero. Zero means done. At start=list_length
    addr_no = 0
    for addr in values_to_track_translated_order:
      display_list_len = len(display_lists[addr])
      output_mem[0x8601 + addr_no] = display_list_len
      addr_no += 1

    #LIST_WAIT_HI = $8700 ;list0_wait, list1_wait, list2_wait
    addr_no = 0
    for addr in values_to_track_translated_order:
      output_mem[0x8701 + addr_no] = display_list_waits[addr]
      addr_no += 1

    #LIST_START_HI = $8800
    # Stack the display lists from 0x8800-
    current_poi = 0x8800
    for addr in values_to_track_translated_order:
      display_list_len = len(display_lists[addr])
      output_mem[current_poi:current_poi+display_list_len] = display_lists[addr]
      current_poi += display_list_len
    output_highest_used_address = current_poi


  # Add initial values:
  output_mem[INITIAL_VALUES + 0x00] = vic2_regs[0x00]
  output_mem[INITIAL_VALUES + 0x01] = vic2_regs[0x01]
  output_mem[INITIAL_VALUES + 0x02] = vic2_regs[0x02]
  output_mem[INITIAL_VALUES + 0x03] = vic2_regs[0x03]
  output_mem[INITIAL_VALUES + 0x04] = vic2_regs[0x04]
  output_mem[INITIAL_VALUES + 0x05] = vic2_regs[0x05]
  output_mem[INITIAL_VALUES + 0x06] = vic2_regs[0x06]
  output_mem[INITIAL_VALUES + 0x07] = vic2_regs[0x07]
  output_mem[INITIAL_VALUES + 0x08] = vic2_regs[0x08]
  output_mem[INITIAL_VALUES + 0x09] = vic2_regs[0x09]
  output_mem[INITIAL_VALUES + 0x0a] = vic2_regs[0x0a]
  output_mem[INITIAL_VALUES + 0x0b] = vic2_regs[0x0b]
  output_mem[INITIAL_VALUES + 0x0c] = vic2_regs[0x0c]
  output_mem[INITIAL_VALUES + 0x0d] = vic2_regs[0x0d]
  output_mem[INITIAL_VALUES + 0x0e] = vic2_regs[0x0e]
  output_mem[INITIAL_VALUES + 0x0f] = vic2_regs[0x0f]
  output_mem[INITIAL_VALUES + 0x10] = vic2_regs[0x10]
  output_mem[INITIAL_VALUES + 0x11] = vic2_regs[0x11]
  output_mem[INITIAL_VALUES + 0x12] = vic2_regs[0x15]
  output_mem[INITIAL_VALUES + 0x13] = vic2_regs[0x16]
  output_mem[INITIAL_VALUES + 0x14] = vic2_regs[0x17]
  output_mem[INITIAL_VALUES + 0x15] = vic2_regs[0x1b]
  output_mem[INITIAL_VALUES + 0x16] = vic2_regs[0x1c]
  output_mem[INITIAL_VALUES + 0x17] = vic2_regs[0x1d]
  output_mem[INITIAL_VALUES + 0x18] = vic2_regs[0x20]
  output_mem[INITIAL_VALUES + 0x19] = vic2_regs[0x21]
  output_mem[INITIAL_VALUES + 0x1a] = vic2_regs[0x22]
  output_mem[INITIAL_VALUES + 0x1b] = vic2_regs[0x23]
  output_mem[INITIAL_VALUES + 0x1c] = vic2_regs[0x24]
  output_mem[INITIAL_VALUES + 0x1d] = vic2_regs[0x25]
  output_mem[INITIAL_VALUES + 0x1e] = vic2_regs[0x26]
  output_mem[INITIAL_VALUES + 0x1f] = vic2_regs[0x27]
  output_mem[INITIAL_VALUES + 0x20] = vic2_regs[0x28]
  output_mem[INITIAL_VALUES + 0x21] = vic2_regs[0x29]
  output_mem[INITIAL_VALUES + 0x22] = vic2_regs[0x2a]
  output_mem[INITIAL_VALUES + 0x23] = vic2_regs[0x2b]
  output_mem[INITIAL_VALUES + 0x24] = vic2_regs[0x2c]
  output_mem[INITIAL_VALUES + 0x25] = vic2_regs[0x2d]
  output_mem[INITIAL_VALUES + 0x26] = vic2_regs[0x2e]
  output_mem[INITIAL_VALUES + 0x27] = initial_sid[0x00]
  output_mem[INITIAL_VALUES + 0x28] = initial_sid[0x01]
  output_mem[INITIAL_VALUES + 0x29] = initial_sid[0x02]
  output_mem[INITIAL_VALUES + 0x2a] = initial_sid[0x03]
  output_mem[INITIAL_VALUES + 0x2b] = initial_sid[0x04]
  output_mem[INITIAL_VALUES + 0x2c] = initial_sid[0x05]
  output_mem[INITIAL_VALUES + 0x2d] = initial_sid[0x06]
  output_mem[INITIAL_VALUES + 0x2e] = initial_sid[0x07]
  output_mem[INITIAL_VALUES + 0x2f] = initial_sid[0x08]
  output_mem[INITIAL_VALUES + 0x30] = initial_sid[0x09]
  output_mem[INITIAL_VALUES + 0x31] = initial_sid[0x0a]
  output_mem[INITIAL_VALUES + 0x32] = initial_sid[0x0b]
  output_mem[INITIAL_VALUES + 0x33] = initial_sid[0x0c]
  output_mem[INITIAL_VALUES + 0x34] = initial_sid[0x0d]
  output_mem[INITIAL_VALUES + 0x35] = initial_sid[0x0e]
  output_mem[INITIAL_VALUES + 0x36] = initial_sid[0x0f]
  output_mem[INITIAL_VALUES + 0x37] = initial_sid[0x10]
  output_mem[INITIAL_VALUES + 0x38] = initial_sid[0x11]
  output_mem[INITIAL_VALUES + 0x39] = initial_sid[0x12]
  output_mem[INITIAL_VALUES + 0x3a] = initial_sid[0x13]
  output_mem[INITIAL_VALUES + 0x3b] = initial_sid[0x14]
  output_mem[INITIAL_VALUES + 0x3c] = initial_sid[0x16]
  output_mem[INITIAL_VALUES + 0x3d] = initial_sid[0x17]
  output_mem[INITIAL_VALUES + 0x3e] = initial_sid[0x18]
  output_mem[INITIAL_VALUES + 0x3f] = nof_addresses_to_track_translated

  # Add all the sprites:
  filled_sprite = bytearray()
  filled_sprite = [255] * 63
  for oldsprite_no in range(256):
    new_sprite_no = oldsprite_is_now[oldsprite_no]
    if (new_sprite_no > 0):
      old_addr = (cia2_bank_addr & 0xc000) + oldsprite_no * 0x40
      new_addr = 0x4000 + new_sprite_no * 0x40
      output_mem[new_addr:new_addr+0x40] = initial_mem[old_addr:old_addr+0x40]
#      output_mem[new_addr:new_addr+0x40] = filled_sprite

      # Swizzle sprites to make them more packable:
      #for row in range(0,21):
      #  for byte_no in range(3):
      #    output_mem[new_addr+byte_no*21+row] = initial_mem[old_addr+row*3+byte_no]
      output_mem[new_addr+0x3f] = output_mem[new_addr+0x3e]

      print("Grabbing sprite from mem 0x%04x, putting into 0x%04x-" % (old_addr, new_addr))
      if (output_highest_used_address < new_addr+0x3f):
        output_highest_used_address = new_addr+0x3f
      if (output_lowest_used_address > new_addr):
        output_lowest_used_address = new_addr
      print_sprite(initial_mem, old_addr)

  #display_list_00:
  #  ADDR_LO
  #  ADDR_HI
  #  LIST_LEN = display_list_01 - display_list_00
  #  LIST_POI  (always 0 at start)
  #  LIST_STREAK  (can be != 0 at start)
  #  LIST_WAIT   (can be != 0 at start)
  #  The list:   VALUE
  #              $00 = end, $01-$7f = wait some cycles, $81-$ff = upcoming streak
  #
  #display_list_01:
  #  ADDR_LO
  #  ADDR_HI
  #  ...


  #* file format for a game:
  output = bytearray()
  output.extend((output_lowest_used_address).to_bytes(2, byteorder='little'))
  print("* output_lowest_used_address = 0x%04x" % output_lowest_used_address)
  print("* output_highest_used_address = 0x%04x" % output_highest_used_address)
  dump_mem("outp", output_mem, output_lowest_used_address, output_highest_used_address - output_lowest_used_address)
  output.extend(output_mem[output_lowest_used_address:output_highest_used_address+1])
  with open(output_filename, "wb") as newFile:
      newFile.write(output)

  print("$$$ %s uses a maximum of %d sprites on one line" % (game_name, this_games_max_nof_sprites_on_a_line))

def main():
  # Small unit tests:
  print("addr_lsb, addr_msb, len, 0x06(poi), streak, wait, ... , 0x00")
  av = bytearray(b"\x41\x41\x41\x41\x71")
  wr = bytearray(b"\x00\x00\x00\x00\x01")
  [list_wait, becomes] = pack_this_list(0x1254,av,wr)
  #expect_equal(becomes,b"\x54\x12\x09\x06\x00\x03\x80\x71\x00")
  if list_wait != 0x03:
    die
  #expect_equal(becomes,b"\x80\x71\x00")
  expect_equal_backwards(becomes,b"\x7f\x71")

  av = bytearray(b"\x13\x14\x15\x16")
  wr = bytearray(b"\x00\x00\x00\x00")
  [list_wait, becomes] = pack_this_list(0x1237,av,wr)
  if list_wait != 0x03:
    die
  expect_equal(becomes,b"")

  av = bytearray(b"\x13\x13\x13\x13")
  wr = bytearray(b"\x01\x00\x00\x00")
  [list_wait, becomes] = pack_this_list(0x1238,av,wr)
  if list_wait != 0x03:
    die
  expect_equal(becomes,b"")

  av = bytearray(b"\x13\x13")
  wr = bytearray(b"\x00\x01")
  [list_wait, becomes] = pack_this_list(0x1259,av,wr)
  if list_wait != 0x00:
    die
  #expect_equal(becomes,b"\x59\x12\x09\x06\x00\x00\x80\x13\x00")
  expect_equal_backwards(becomes,b"\x7f\x13")

  print("### full stream until the end of display_list:")
  av = bytearray(b"\x13\x14\x15\x16")
  wr = bytearray(b"\x01\x01\x01\x01")
  [list_wait, becomes] = pack_this_list(0x1236,av,wr)
  if list_wait != 0x00:
    die
#  expect_equal(becomes,b"\x36\x12\x0b\x06\x00\x00\x82\x14\x15\x16\x00")
#  expect_equal_backwards(becomes,b"\x81\x14\x15\x80\x16")
#This is OK:
#  expect_equal_backwards(becomes,b"\x81\x14\x15\x80\x16")
#...but this is better:
  expect_equal_backwards(becomes,b"\x81\x14\x15\x7f\x16")

  av = bytearray(b"\x41\x41\x41\x42\x43\x44")
  wr = bytearray(b"\x00\x00\x00\x01\x01\x01")
  [list_wait, becomes] = pack_this_list(0x123a,av,wr)
  if list_wait != 0x02:
    die
#  expect_equal(becomes,b"\x3a\x12\x0b\x06\x00\x02\x82\x42\x43\x44\x00")
#  expect_equal_backwards(becomes,b"\x81\x42\x43\x80\x44")
  expect_equal_backwards(becomes,b"\x81\x42\x43\x7f\x44")

  av = bytearray(b"\x41\x41\x41\x41\x13\x14\x15\x16")
  wr = bytearray(b"\x00\x00\x00\x00\x01\x01\x01\x01")
  [list_wait, becomes] = pack_this_list(0x1235,av,wr)
  if list_wait != 0x03:
    die
#  expect_equal(becomes,b"\x35\x12\x0c\x06\x00\x03\x83\x13\x14\x15\x16\x00")
#  expect_equal_backwards(becomes,b"\x82\x13\x14\x15\x80\x16")
  expect_equal_backwards(becomes,b"\x82\x13\x14\x15\x7f\x16")

  av = bytearray(b"\x13\x14\x15\x16")
  wr = bytearray(b"\x00\x01\x00\x01")
  [list_wait, becomes] = pack_this_list(0x12a9,av,wr)
  if list_wait != 0x00:
    die
  #expect_equal(becomes,b"\xa9\x12\x0b\x06\x00\x00\x01\x14\x80\x16\x00")
  expect_equal_backwards(becomes,b"\x01\x14\x7f\x16")

  av = bytearray(b"\x41\x41\x41\x41\x81\x81")
  wr = bytearray(b"\x00\x00\x00\x00\x01\x00")
  [list_wait, becomes] = pack_this_list(0x1234,av,wr)
  if list_wait != 0x03:
    die
  #expect_equal(becomes,b"\x34\x12\x09\x06\x00\x03\x01\x81\x00")
  expect_equal_backwards(becomes,b"\x7f\x81")

  av = bytearray(b"\x13\x14\x15\x16\x16")
  wr = bytearray(b"\x01\x01\x01\x01\x00")
  [list_wait, becomes] = pack_this_list(0x1276,av,wr)
  if list_wait != 0x00:
    die
  #expect_equal(becomes,b"\x76\x12\x0b\x06\x00\x00\x82\x14\x15\x16\x00")
  #expect_equal_backwards(becomes,b"\x81\x14\x15\x01\x16")
  #expect_equal_backwards(becomes,b"\x83\x14\x15\x01\x16")
  expect_equal_backwards(becomes,b"\x81\x14\x15\x7f\x16")

  av = bytearray(b"\x13\x13\x13")
  wr = bytearray(b"\x00\x01\x00")
  [list_wait, becomes] = pack_this_list(0x1289,av,wr)
  if list_wait != 0x00:
    die
  #expect_equal(becomes,b"\x89\x12\x09\x06\x00\x00\x01\x13\x00")
  expect_equal_backwards(becomes,b"\x7f\x13")

  av = bytearray(b"\x13\x13\x13\x13")
  wr = bytearray(b"\x00\x01\x00\x00")
  [list_wait, becomes] = pack_this_list(0x1239,av,wr)
  if list_wait != 0x00:
    die
  #expect_equal(becomes,b"\x39\x12\x09\x06\x00\x00\x02\x13\x00")
  expect_equal_backwards(becomes,b"\x7f\x13")


  # Bombjack
  av = bytearray(b"\x41\x80\x81\x82\x83\x84\x85\x86\x87\x88")
  wr = bytearray(b"\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x00:
    die
  #expect_equal(becomes,b"\x00\xff\x0b\x06\x00\x00\x07\x80\x80\x88\x00")
  expect_equal_backwards(becomes,b"\x07\x80\x7f\x88")

  # Bombjack
  av = bytearray(b"\x41\x80\x81\x81\x81\x81\x81\x81\x81\x80\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x40\x41\x41\x41\x41\x41\x41\x41\x40\x41\x41\x41\x41\x41\x41\x41\x80\x81\x81\x81\x81\x81\x81\x81\x40\x41") #414141414141404141414141414180818181818181818081818181818181818181818181818140414141414141414041414141")
  wr = bytearray(b"\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00") #000000000000010000000000000001000000000000000100000000000000000000000000000001000000000000000100000000")
  [list_wait, becomes] = pack_this_list(0xd412,av,wr)
  if list_wait != 0x00:
    die
  #expect_equal(becomes,b"\x12\xd4\x13\x06\x00\x00\x07\x80\x0f\x80\x07\x40\x07\x40\x07\x80\x01\x40\x00")
  expect_equal_backwards(becomes,b"\x07\x80\x0f\x80\x07\x40\x07\x40\x07\x80\x7f\x40")


  print("### Rare writes:")
  av = bytearray(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a")
  wr = bytearray(b"\x00\x00\x01\x00\x00\x00\x01\x00\x01\x00")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x01:
    die
  expect_equal_backwards(becomes,b"\x03\x03\x01\x07\x7f\x09")


  print("### wait + streak:")
  av = bytearray(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a")
  wr = bytearray(b"\x00\x01\x00\x00\x00\x01\x01\x01\x01\x01")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x00:
    die
  expect_equal_backwards(becomes,b"\x03\x02\x83\x06\x07\x08\x09\x7f\x0a")

  print("### streak + wait:")
  av = bytearray(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a")
  wr = bytearray(b"\x00\x01\x01\x01\x00\x01\x00\x00\x00\x00")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x00:
    die
  expect_equal_backwards(becomes,b"\x81\x02\x03\x01\x04\x7f\x06")

  print("### Two streaks after eachother:")
  av = bytearray(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a")
  wr = bytearray(b"\x00\x01\x01\x01\x00\x01\x01\x01\x01\x01")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x00:
    die
  expect_equal_backwards(becomes,b"\x81\x02\x03\x01\x04\x83\x06\x07\x08\x09\x7f\x0a")

  print("### Two streaks after eachother:")
  av = bytearray(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a")
  wr = bytearray(b"\x00\x01\x01\x01\x00\x00\x00\x01\x01\x01")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x00:
    die
  expect_equal_backwards(becomes,b"\x81\x02\x03\x03\x04\x81\x08\x09\x7f\x0a")


  print("### streak + 2wait:")
  av = bytearray(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a")
  wr = bytearray(b"\x00\x01\x01\x01\x00\x00\x01\x01\x01\x00")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x00:
    die
  expect_equal_backwards(becomes,b"\x81\x02\x03\x02\x04\x81\x07\x08\x7f\x09")

# BROKEN:
  print("### streak + 2wait:")
  av = bytearray(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a")
  wr = bytearray(b"\x00\x01\x01\x01\x00\x00\x01\x01\x00\x00")
  [list_wait, becomes] = pack_this_list(0xff00,av,wr)
  if list_wait != 0x00:
    die
  expect_equal_backwards(becomes,b"\x81\x02\x03\x02\x04\x80\x07\x7f\x08")



  if len(sys.argv) == 1:
    batch_no = 0
    nof_batches = 1
  elif len(sys.argv) == 3:
    batch_no = int(sys.argv[1])
    nof_batches = int(sys.argv[2])
  else:
    print("packer.py    OR   packer.py batch_no nof_batches")
    die

  game_no = 0
  game_addr = "LO"
  for info in games:
    game = info['name']
    if ((game_no % nof_batches) == batch_no):
      print("Doing    game #%d %s." % (game_no, game))
      minimize_game(game, game_no, game_addr, info)
    else:
      print("Skipping game #%d %s." % (game_no, game))

    if (game_addr == "LO"):
      game_addr = "HI"
    else:
      game_addr = "LO"
    game_no += 1

if __name__ == "__main__":
  if os.path.isdir('games'):
    main()
  else:
    print("To be able to pack any games, you will need the ~350MB input folder 'games' as well. There's nothing to do without input, so I'm just skipping...")
