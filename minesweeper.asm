INCLUDE Irvine32.inc
INCLUDE macros.inc

.386
.model flat, stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword

BufSize = 676


.data
buffer BYTE BufSize DUP(? )
coordinates COORD <27, 27>
light_Gray EQU 7
counter1 DWORD ?
counter2 DWORD ?
outHandle  DWORD ?
consoleInfo CONSOLE_SCREEN_BUFFER_INFO <>
cursorInfo CONSOLE_CURSOR_INFO <>
titleStr BYTE "MINESWEEPER GAME", 0
windowGame    SMALL_RECT <0, 0, 26, 26>
row db ?
col db ?
row1 db ?
col1 db ?
row2 db ?
col2 db ?
rowArray WORD 80 DUP(0)
indexOfArray WORD 1
currentColor WORD 16 * black + LightGreen
notOpenedColor WORD 16 * black + LightGray
markedColor WORD 16 * black + Red
openedColor WORD 16 * black + White
openedColorNum WORD 16 * White + Black
currentNumColor WORD 16 * LightGreen + Black
color WORD ?
count DWORD 11
mines DWORD 10 DUP(? )
state WORD 82 DUP(0);0-neotvoreno, 1-otvoreno, 2-obelezeno
minesAround WORD 82 DUP(0)
pom DWORD ?
pom2 BYTE ?
pom3 WORD ?
numMO WORD 0
numMarked WORD 0

captionL BYTE "YOU LOST", 0
loseMsg	BYTE "You hit a mine, end of the game! ", 0
lose2Msg	BYTE "Mines marked incorrectly, end of the game! ", 0
captionW BYTE "YOU WON", 0
winMsg	BYTE "Congratulations, all mines marked correctly! ", 0


greeting BYTE "Welcome to Minesweeper ", 0dh, 0ah,
0dh, 0ah,
"Commands:", 0dh, 0ah,
"Left arrow - Move left", 0dh, 0ah,
"Right arrow - Move right", 0dh, 0ah,
"Up arrow - Move up", 0dh, 0ah,
"Down arrow - Move down", 0dh, 0ah,
"Reveal cell - Space", 0dh, 0ah,
"Mark cell - Left shift", 0dh, 0ah,
"Exit game - Escape", 0dh, 0ah, 0dh, 0ah,

.code
main proc

INVOKE GetStdHandle, STD_OUTPUT_HANDLE
mov outHandle, eax
INVOKE SetConsoleTitle, ADDR titleStr
INVOKE SetConsoleWindowInfo,
outHandle, TRUE, ADDR windowGame
INVOKE GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo
INVOKE SetConsoleScreenBufferSize,
outHandle, coordinates

call generateRandom

call Clrscr
INVOKE SetConsoleTextAttribute,
outHandle, notOpenedColor
mov  edx, offset greeting
call WriteString
call WaitMsg
call Clrscr

INVOKE SetConsoleWindowInfo,
outHandle, TRUE, ADDR windowGame

INVOKE GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo

INVOKE SetConsoleScreenBufferSize,
outHandle, coordinates


 INVOKE GetStdHandle, STD_OUTPUT_HANDLE
 mov  outHandle, eax
 INVOKE GetConsoleCursorInfo, outHandle, ADDR cursorInfo
 mov  cursorInfo.bVisible, 0
 INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo

call drawCells

INVOKE SetConsoleTextAttribute,
outHandle, currentColor

mov dh, 0
mov dl, 0
mov  al, 0DBh
call gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
dec dl
inc dh
call Gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar

mov dh, 0
mov dl, 0
call gotoxy
mov row, dh
mov col, dl
call playIt

main endp
	


playIt proc
xor ebx, ebx
Get_key :
xor ax, ax
readInput:
mov eax, 20
call Delay
call ReadKey
cmp ax, 0
je readInput
cmp ax, 4B00h
je moveleft
cmp ax, 4800h
je  moveup
cmp ax, 4D00h
je  moveright
cmp ax, 5000h
je  movedown
cmp al, VK_SPACE
je  space
cmp al, VK_ESCAPE
je escape
test ebx, SHIFT_PRESSED
jnz  leftshift
jmp get_key

escape:
exit

moveup :
mov dl, col
mov dh, row
mov row1, dh
mov col1, dl
sub dh, 3
.IF dh< 0 || dh > 25
mov dh, 0
call gotoxy
mov row, dh
mov col, dl
jmp get_key
.ENDIF
call gotoxy
mov row, dh
mov col, dl
call previousCellColor
call currentCellColor
jmp get_key

movedown :
mov dl, col
mov dh, row
mov row1, dh
mov col1, dl
add dh, 3
.IF dh <= 0 || dh >= 25
mov dh, 24
call gotoxy
mov row, dh
mov col, dl
jmp get_key
.ENDIF
call gotoxy
mov row, dh
mov col, dl
call previousCellColor
call currentCellColor
jmp get_key

moveright :
mov dh, row
mov dl, col
mov row1, dh
mov col1, dl
add dl, 3
.IF dl <= 0 || dl >= 25
mov dl, 24
call gotoxy
mov row, dh
mov col, dl
jmp get_key
.ENDIF
call gotoxy
mov row, dh
mov col, dl
call previousCellColor
call currentCellColor
jmp get_key

moveleft :
mov dh, row
mov dl, col
mov row1, dh
mov col1, dl
sub dl, 3
.IF dl < 0 || dl >= 25
mov dl, 0
call gotoxy
mov row, dh
mov col, dl
jmp get_key
.ENDIF
call gotoxy
mov row, dh
mov col, dl
call previousCellColor
call currentCellColor
jmp get_key

space:
mov ch, row
mov cl, col
mov row1, ch
mov col1, cl
call indexFromCoord
cmp minesAround[eax], 9
jne continueGame
INVOKE MessageBox, NULL, ADDR loseMsg,
ADDR captionL, MB_OK
exit
continueGame:
mov ch, row
mov cl, col
call openCell
jmp get_key



leftShift:
mov ch, row
mov cl, col
call indexFromCoord
cmp state[eax], 0
je mark
cmp state[eax], 2
je unmark
cmp state[eax], 1
je endOfMarking

mark:
mov bx, 2
mov state[eax], bx
mov bx, numMO
inc bx
mov numMO, bx
mov bx, numMarked
inc bx
mov numMarked, bx
call checkIfEnd
jmp endOfMarking

unmark:
mov bx, 0
mov state[eax], bx
mov bx, numMO
dec bx
mov numMO, bx
mov bx, numMarked
dec bx
mov numMarked, bx

endOfMarking:
jmp get_key
playIt endp



currentCellColor proc

INVOKE SetConsoleTextAttribute,
outHandle, currentColor
mov dh, row
mov dl, col
mov  al, 0DBh
call gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
dec dl
inc dh
call Gotoxy
call WriteChar
mov ch, row
mov cl, col
call indexFromCoord
cmp state[eax], 2
je noNumber
cmp state[eax], 0
je noNumber
cmp minesAround[eax], 0
je noNumber
xor ebx, ebx
mov bx, minesAround[eax]
mov pom3, bx
INVOKE SetConsoleTextAttribute,
outHandle, currentNumColor
xor eax, eax
mov ax, pom3
mov dh, row
mov dl, col
inc dh
inc dl
call Gotoxy
call WriteDec
mov dh, row
mov dl, col
call Gotoxy
ret
noNumber:
mov dh, row
mov dl, col
mov  al, 0DBh
inc dl
inc dh
call Gotoxy
call WriteChar
mov dh, row
mov dl, col
call Gotoxy
ret
currentCellColor endp


previousCellColor proc
mov ch, row1
mov cl, col1
call indexFromCoord
mov bx, state[eax]
cmp bx, 0
je notOpened
cmp bx, 2
je marked
cmp bx, 1
je opened
notOpened:
mov ax, notOpenedColor
mov Color, ax
jmp coloring
marked:
mov ax, markedColor
mov Color, ax
jmp coloring
opened:
mov pom, eax
INVOKE SetConsoleTextAttribute,
outHandle, openedColor
mov ecx, pom
mov dh, row1
mov dl, col1
mov  al, 0DBh
call gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
dec dl
inc dh
call Gotoxy
call WriteChar
inc dl
mov ax, minesAround[ecx]
mov pom3, ax
call Gotoxy
INVOKE SetConsoleTextAttribute,
outHandle, openedColorNum
xor eax, eax
mov ax, pom3
call WriteDec
mov dh, row
mov dl, col
call Gotoxy
mov eax, pom
cmp minesAround[eax], 0
jne isNotEqual
INVOKE SetConsoleTextAttribute,
outHandle, openedColor
mov dh, row1
mov dl, col1
inc dh 
inc dl
mov  al, 0DBh
call gotoxy
call WriteChar
mov dh, row
mov dl, col
call Gotoxy
isNotEqual:
ret
coloring:
INVOKE SetConsoleTextAttribute,
outHandle, Color
mov dh, row1
mov dl, col1
mov  al, 0DBh
call gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
dec dl
inc dh
call Gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
mov dh, row
mov dl, col
call Gotoxy
ret
previousCellColor endp



evaluateNumber proc
mov eax, 0
mov ebx, 11
sub ebx, ecx
shl ebx, 1
dec ebx
add ebx, OFFSET mines
mov ax, [ebx]
shl eax, 1
dec eax
mov pom, eax
inc eax
shr eax, 1
xor edx, edx
mov ebx, 9
div ebx
cmp eax, 0
je topEdge
mov eax, pom
inc eax
shr eax, 1
mov ebx, 9
xor edx, edx
div ebx
mov eax, edx
cmp eax, 1
je topLeftCorner
mov eax, pom
sub eax, 20
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
topLeftCorner :
mov eax, pom
sub eax, 18
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
topEdge :
mov eax, pom
inc eax
shr eax, 1
mov dx, 0
mov ebx, 9
xor edx, edx
div ebx
mov eax, edx
cmp eax, 0
je rightEdge
mov eax, pom
inc eax
shr eax, 1
mov ebx, 9
xor edx, edx
div ebx
cmp eax, 0
je topRightCorner
mov eax, pom
sub eax, 16
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
topRightCorner :
mov eax, pom
add eax, 2
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
rightEdge :
mov eax, pom
inc eax
shr eax, 1
cmp eax, 72
je avoidMistake
mov ebx, 9
xor edx, edx
div ebx
cmp eax, 8
je bottomEdge
avoidMistake:
mov eax, pom
inc eax
shr eax, 1
mov dx, 0
mov ebx, 9
xor edx, edx
div ebx
mov eax, edx
cmp eax, 0
je bottomRightCorner
mov eax, pom
add eax, 20
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
bottomRightCorner :
mov eax, pom
add eax, 18
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
bottomEdge :
mov eax, pom
inc eax
shr eax, 1
mov dx, 0
mov ebx, 9
xor edx, edx
div ebx
mov eax, edx
cmp eax, 1
je leftEdge
mov eax, pom
inc eax
shr eax, 1
cmp eax, 72
je avoidMistake2
mov ebx, 9
xor edx, edx
div ebx
cmp eax, 8
je bottomLeftCorner
avoidMistake2:
mov eax, pom
add eax, 16
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
bottomLeftCorner :
mov eax, pom
sub eax, 2
mov bx, minesAround[eax]
inc bx
mov minesAround[eax], bx
leftEdge :
ret
evaluateNumber endp


openCell proc

call indexFromCoord
cmp state[eax], 1
je doNothing
cmp state[eax], 2
je doNothing
cmp minesAround[eax], 0
je emptyCell
cmp minesAround[eax], 9
je doNothing
mov bx, 1
mov state[eax], bx
mov bx, numMO
inc bx
mov numMO, bx
mov ebx, eax
mov  ax, minesAround[ebx]
mov pom3, ax
cmp ch, row
jne notCurrentCell
cmp cl, col
jne notCurrentCell
INVOKE SetConsoleTextAttribute,
outHandle, currentNumColor
mov ax, pom3
mov dh, row
mov dl, col
inc dh
inc dl
call gotoxy
call WriteDec
dec dh
dec dl
call gotoxy
call checkIfEnd
ret

notCurrentCell:
mov row2, ch
mov col2, cl
INVOKE SetConsoleTextAttribute,
outHandle, openedColorNum
mov ax, pom3
mov dh, row2
mov dl, col2
inc dh
inc dl
call gotoxy
call WriteDec
INVOKE SetConsoleTextAttribute,
outHandle, openedColor
mov dh, row2
mov dl, col2
mov  ax, 0DBh
call gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
dec dl
inc dh
call Gotoxy
call WriteChar
mov dh, row
mov dl, col
call Gotoxy
call checkIfEnd
ret

emptyCell:
mov row1, ch
mov col1, cl
xor ebx, ebx
mov bx, indexOfArray
mov eax, offset rowArray
mov rowArray[ebx], cx
inc bx
inc bx
mov indexOfArray, bx
call indexFromCoord
mov bx, 1
mov state[eax], bx
mov bx, numMO
inc bx
mov numMO, bx
cmp ch, row
jne notCurrentEmptyCell
cmp cl, col
jne notCurrentEmptyCell
retFromNotCurrent:
call checkIfEnd
mov ch, row1
mov cl, col1
cmp ch, 0
je topEdge1
cmp cl, 0
je topLeftCorner1
sub ch, 3
sub cl, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver1
call openCell
jumpOver1:
mov ch, row1
mov cl, col1
topLeftCorner1:
sub ch, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver2
call openCell
jumpOver2:
mov ch, row1
mov cl, col1
topEdge1:
cmp cl, 24
je rightEdge1
cmp ch, 0
je topRightCorner1
sub ch, 3
add cl, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver3
call openCell
jumpOver3 :
mov ch, row1
mov cl, col1
topRightCorner1:
add cl, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver4
call openCell
jumpOver4 :
mov ch, row1
mov cl, col1
rightEdge1:
cmp ch, 24
je bottomEdge1
cmp cl, 24
je bottomRightCorner1
add ch, 3
add cl, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver5
call openCell
jumpOver5 :
mov ch, row1
mov cl, col1
bottomRightCorner1:
add ch, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver6
call openCell
jumpOver6 :
mov ch, row1
mov cl, col1
bottomEdge1:
cmp cl, 0
je leftEdge1
cmp ch, 24
je bottomLeftCorner1
add ch, 3
sub cl, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver7
call openCell
jumpOver7 :
mov ch, row1
mov cl, col1
bottomLeftCorner1:
sub cl, 3
call indexFromCoord
cmp state[eax], 1
je jumpOver8
call openCell
jumpOver8 :
mov ch, row1
mov cl, col1
leftEdge1:
xor ebx, ebx
mov bx, indexOfArray
dec bx
dec bx
mov indexOfArray, bx
dec bx
dec bx
js avoidMistake3
mov cx, rowArray[ebx]
; mov cl, colArray[ebx]
avoidMistake3:
mov row1, ch
mov col1, cl
doNothing:
ret

notCurrentEmptyCell:
INVOKE SetConsoleTextAttribute,
outHandle, openedColor
mov dh, row1
mov dl, col1
mov  al, 0DBh
call gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
dec dl
inc dh
call Gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
mov dh, row
mov dl, col
call Gotoxy
jmp retFromNotCurrent

openCell endp


indexFromCoord proc
xor eax, eax
mov al, cl
xor ebx, ebx
mov bl, 3
div bl
inc al
mov pom2, al
mov al, ch
mov bl, 3
div bl
mov bl, 9
mul bl
add al, pom2
shl eax, 1
dec eax
ret
indexFromCoord endp


checkIfEnd proc
cmp numMO, 81
jne notEnd
cmp numMarked, 10
je correctNumOfMarked
INVOKE MessageBox, NULL, ADDR lose2Msg,
ADDR captionL, MB_OK
exit
correctNumOfMarked:
mov ecx, 10
checkMines :
mov eax, 0
mov ebx, 11
sub ebx, ecx
shl ebx, 1
dec ebx
add ebx, OFFSET mines
mov ax, [ebx]
shl eax, 1
dec eax
cmp state[eax], 2
jne incorrectlyMarked
loop checkMines
INVOKE MessageBox, NULL, ADDR winMsg,
ADDR captionW, MB_OK
exit
incorrectlyMarked:
INVOKE MessageBox, NULL, ADDR lose2Msg,
ADDR captionL, MB_OK
exit
notEnd :
ret
checkIfEnd endp



generateRandom proc

RAND2 :
mov	ecx, 01101100h
RAND1 : 
imul	ebx
imul	ebx
imul	ebx
loop	RAND1
INVOKE GetTickCount
mov edx, 0
mov ebx, 81
div ebx
mov eax, edx
mov pom, eax
mov ecx, 12
sub ecx, count
compareLoop :
mov ebx, ecx
mov eax, ebx
mov ebx, 2
mul ebx
mov ebx, eax
sub ebx, 1
mov eax, pom
cmp eax, mines[ebx]
je RAND2
loop compareLoop
mov eax, pom
jnz notZero
add eax, 81
notZero:
mov ebx, 12
sub ebx, count
mov eax, ebx
mov ebx, 2
mul ebx
mov ebx, eax
sub ebx, 1
mov eax, pom
mov mines[ebx], eax
dec count
mov eax, count
dec eax
jnz RAND2

mov ecx, 10
numberOfMines:
call evaluateNumber
loop numberOfMines

mov ecx, 10
findMine :
mov eax, 0
mov ebx, 11
sub ebx, ecx
shl ebx, 1
dec ebx
add ebx, OFFSET mines
mov ax, [ebx]
shl eax, 1
dec eax
mov minesAround[eax], 9
loop findMine
ret
generateRandom endp



drawCells proc
mov  dl, 0
mov  dh, 0
mov ecx, 9
DrawYl:
mov counter1, ecx
mov ecx, 2
DrawYs :

mov dl, 0
mov counter2, ecx
mov ecx, 9
DrawX :
mov  al, 0DBh

call Gotoxy
call WriteChar
inc dl
call Gotoxy
call WriteChar
inc dl
inc dl
loop DrawX

mov ecx, counter2
inc dh
loop DrawYs
inc dh
mov ecx, counter1

loop DrawYl
ret
drawCells endp

end main