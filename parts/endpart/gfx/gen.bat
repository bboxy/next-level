@echo off
rem charconv -1 14 -2 15 -b 0 stage_distance_1.png
rem charconv -1 14 -2 15 -b 0 stage_distance_2.png
rem charconv -1 14 -2 15 -b 0 stage_distance_3.png

charconv -b 0 -h -p stage_font_upper.png

charconv -1 14 -2 15 -b 0 _stage_split_1.png
charconv -1 14 -2 15 -b 0 _stage_split_2.png
charconv -1 14 -2 15 -b 0 _stage_split_3.png
charconv -1 14 -2 15 -b 0 _stage_split_4.png

codegen

rem dasm stage_distance_screen.asm -ostage_distance_screen.prg -v3 -t2 -p8
rem dasm stage_distance_color.asm -ostage_distance_color.prg -v3 -t2 -p8
