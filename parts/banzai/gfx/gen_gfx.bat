@echo off
charconv -1 0 -2 8 -b 3 -t 16 -f levelmap.png
charconv -1 0 -2 8 -b 3 -t 16 -p charanims.png
rem charconv -b 0 -h -p -t 32 pattern.png
spriteconv -1 10 -2 1 -b 0 -m handles.png
spriteconv -b 3 -h -m clouds.png
spriteconv -1 2 -2 10 -b 0 ship.png

