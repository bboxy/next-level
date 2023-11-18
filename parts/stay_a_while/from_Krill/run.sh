
set -e

64tass --case-sensitive --m6502 --ascii bigprompt.s -o bigprompt.prg
c1541 -format "normal is boring,+h" d64 bigprompt.d64
c1541 -attach bigprompt.d64 -write bigprompt.prg "bigprompt"
x64sc -autostart ./bigprompt.d64 -pal

