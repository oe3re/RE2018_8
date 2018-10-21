# RE2018_8
Minesweeper


Make the game Minesweeper:
http://www.classicgamesarcade.com/game/21649/minesweeper.html
https://en.wikipedia.org/wiki/Minesweeper_(video_game)

Game window(table) is divided into 9x9 fields which are all the same color in the beginning. Mines are kept hidden under 10 randomly selected 9x9 fields. Player is moving through fields by the cursors on the keyboard (make a currently selected field colored in a different way). Also make fields of the size 2x2.
A field is opened when SPACE key is pressed. If at the selected field there is no mine, all other fields that don’t contain mines are also opened recursively (they change colors). On the edges of the open sector, a number is displayed of how many mines there are in surrounding blocks. Pressing SPACE on a mine, the game is over. If player supposes that under a certain field there is a mine, he can mark that field by pressing Left Shift and then that field changes its color.
Game is over when all the fields are opened that don’t contain mines and all mines are flagged. If the field that contains mine is opened game automatically ends. Allow player to also leave the game by pressing ESC.
