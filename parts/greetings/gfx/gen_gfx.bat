@echo off
charconv -1 5 -2 13 -b 6 -t 16 greetz.png
charconv -b 6 -h -p -t 32 pattern.png
charconv -b 6 -h -p -t 32 pattern1.png
charconv -b 6 -h -p -t 32 pattern2.png
charconv -b 6 -h -p -t 32 pattern3.png
charconv -b 6 -h -p -t 32 pattern4.png
charconv -b 6 -h -p -t 32 pattern5.png
charconv -b 6 -h -p -t 32 pattern6.png
charconv -b 6 -h -p -t 32 pattern7.png
charconv -b 6 -h -p -t 32 pattern8.png
spriteconv -b 4 -1 15 -2 14 -M -o 2 spritemap.png
