m = 25
d = 16

init_sierpinsky:
	+GENLERP 0*m/d, 0
	+GENLERP 127*m/d, 1
	+GENLERP 60*m/d, 2
	+GENLERP 42*m/d, 3
	+GENLERP 52*m/d, 4
	+GENLERP 30*m/d, 5
	+GENLERP 120*m/d, 6
	+GENLERP 104*m/d, 7
	rts

update_sierpinsky:

rotate_sierpinsky:
	+ROTPOINT 0, 0, 3, 0
	+ROTPOINT 0, 5, 7, 1
	+ROTPOINT 8, 10, 7, 2
	+ROTPOINT 9, 10, 7, 3
	+ROTPOINT 0, 13, 6, 4
	+ROTPOINT 14, 4, 6, 5
	+ROTPOINT 15, 4, 6, 6
	+ROTPOINT 8, 11, 6, 7
	+ROTPOINT 0, 4, 6, 8
	+ROTPOINT 9, 11, 6, 9

cull_sierpinsky:
	+CULLFACE 5, 4, 0, 0
	+CULLFACE 6, 5, 0, 1
	+CULLFACE 4, 6, 0, 2
	+CULLFACE 4, 5, 6, 3
	+CULLFACE 1, 2, 3, 4
	+CULLFACE 9, 7, 1, 5
	+CULLFACE 7, 8, 2, 6
	+CULLFACE 8, 9, 3, 7

calcedges_sierpinsky:
	+CALCEDGESTEP 1, 2, 4, 0, 0
	+CALCEDGESTEP 2, 3, 4, 1, 1
	+CALCEDGESTEP 3, 1, 4, 2, 2
	+CALCEDGESTEP 9, 7, 5, 3, 3
	+CALCEDGESTEP 7, 1, 5, 0, 4
	+CALCEDGESTEP 1, 9, 5, 2, 5
	+CALCEDGESTEP 7, 8, 6, 3, 6
	+CALCEDGESTEP 8, 2, 6, 1, 7
	+CALCEDGESTEP 2, 7, 6, 0, 8
	+CALCEDGESTEP 8, 9, 7, 3, 9
	+CALCEDGESTEP 9, 3, 7, 2, 10
	+CALCEDGESTEP 3, 8, 7, 1, 11
	+CALCEDGESTEP 1, 0, 0, 2, 12
	+CALCEDGESTEP 0, 2, 0, 1, 13
	+CALCEDGESTEP 0, 3, 1, 2, 14
	+CALCEDGESTEP 7, 4, 0, 3, 15
	+CALCEDGESTEP 4, 1, 0, 2, 16
	+CALCEDGESTEP 4, 9, 2, 3, 17
	+CALCEDGESTEP 8, 5, 1, 3, 18
	+CALCEDGESTEP 5, 2, 1, 0, 19
	+CALCEDGESTEP 5, 7, 0, 3, 20
	+CALCEDGESTEP 9, 6, 2, 3, 21
	+CALCEDGESTEP 6, 3, 2, 1, 22
	+CALCEDGESTEP 6, 8, 1, 3, 23

dopolys_sierpinsky:
	+DOTRI 1, 2, 3, 4, 0, 1, 2, 4
	+DOTRI 9, 7, 1, 5, 3, 4, 5, 5
	+DOTRI 7, 8, 2, 6, 6, 7, 8, 4
	+DOTRI 8, 9, 3, 7, 9, 10, 11, 5
	
	+DOTRI 2, 1, 0, 0, 0, 12, 13, 1
	+DOTRI 3, 2, 0, 1, 1, 13, 14, 2
	+DOTRI 1, 3, 0, 2, 2, 14, 12, 3
	
	+DOTRI 7, 4, 1, 0, 15, 16, 4, 1
	+DOTRI 4, 9, 1, 2, 17, 5, 16, 3
	+DOTRI 7, 9, 4, 3, 3, 17, 15, 0
	
	+DOTRI 5, 7, 2, 0, 20, 8, 19, 1
	+DOTRI 8, 5, 2, 1, 18, 19, 7, 2
	+DOTRI 8, 7, 5, 3, 6, 20, 18, 0
	
	+DOTRI 9, 6, 3, 2, 21, 22, 10, 3
	+DOTRI 6, 8, 3, 1, 23, 11, 22, 2
	+DOTRI 9, 8, 6, 3,  9, 23, 21, 0
	rts
