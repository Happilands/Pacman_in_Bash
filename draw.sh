DFX=1 # Draw offset x
DFY=2 # Draw offset y

function getColor(){ #(r, g, b)
    echo "\x1b[38;2;$1;$2;$3m"
}
function getBGColor(){ #(r, g, b)
    echo "\x1b[48;2;$1;$2;$3m"
}
function setGlobalCursorPos(){ #(x, y)
    printf "\e[$(($2));$(($1))H"
}
function setCursorPos(){ #(x, y)
    printf "\e[$(($2+$DFY));$(($1+$DFX))H"
}

BG_COLOR=$ON_BLACK
WALL_COLOR="$(getColor 28 28 191)$BG_COLOR"
PELLET_COLOR="$WHITE$BG_COLOR"
PACMAN_COLOR="$YELLOW$BG_COLOR"

function drawWalls(){
    readarray -t MAP < assets/map.txt

    local LENGTH=${#MAP[@]}
    printf "$WALL_COLOR"

    for ((i=0;i<$LENGTH;i++)); do
        setCursorPos 0 $i
        printf "${MAP[i]}"
    done
}

function drawPellets(){
    readarray -t PELLETS < assets/pellets.txt
    local LENGTH=${#PELLETS[@]}

    printf "$PELLET_COLOR"

    for ((y=0;y<$LENGTH;y++)); do
        local LINE=${PELLETS[y]}
        local WIDTH=${#LINE}
        for ((x=0;x<$WIDTH;x++)); do
            if [ "${LINE:$x:1}" = "." ]; then
                setCursorPos $(($x*2+1)) $y
                printf "·"
            fi
            if [ "${LINE:$x:1}" = "o" ]; then
                setCursorPos $(($x*2+1)) $y
                printf "●"
            fi
        done
    done
}

function drawGhost(){ #(x, y, id)
    setCursorPos $1 $2

    if ((${g_isCaptured[$3]}==1)); then
        printf "$WHITE$BG_COLOR \""
        return
    elif (($energizedSteps>0)); then
        local color="$BLUE$BG_COLOR"
    else
        local color="${gcolor[$3]}$BG_COLOR"
    fi
    printf "$color▐█▌"
}

function drawPacman(){ #(x, y)
    setCursorPos $1 $2
    printf "$PACMAN_COLOR▐█▌"
}

function drawCharactersOnStartScreen(){
    drawPacman $px $py
    drawGhost $((${gx[0]}*2-1)) ${gy[0]} 0
    drawGhost $((${gx[1]}*2-1)) ${gy[1]} 1
    drawGhost $((${gx[2]}*2)) ${gy[2]} 2
    drawGhost $((${gx[3]}*2)) ${gy[3]} 3
}

function initDraw(){
    clear
    drawWalls
    drawPellets
    drawCharactersOnStartScreen
}