function initGame(){
    readarray -t OBSTACLES < assets/pellets.txt
    readarray -t INTERSECTIONS < assets/intersections.txt
    source draw.sh

    px=27
    py=23
    pdx=0
    pdy=0
    pelletsEaten=0

    # Score
    score=0
    eatGhostScore=200

    # Controls
    lcx=0 # control dir X
    lcy=0 # control dir Y

    GAME_STAGE=0

    # Ghosts
    GHOSTS=4
    gx=(14 14 12 15)
    gy=(11 14 14 14)
    gdx=(-1 1 1 -1)
    gdy=(0 0 0 0)
    g_isCaptured=(0 0 0 0)
    g_isActive=(1 1 0 0)
    g_changeDirs=(0 0 0 0)
    scx=(26 1 27 0)
    scy=(-2 -2 32 32)

    gcolor=($RED $PURPLE $CYAN $(getColor 255 184 71))
    goncolor=($ON_RED $ON_PURPLE $ON_CYAN $(getBGColor 255 141 71))
    energizedSteps=0
    energizedDuration=$((5*30))

    initDraw
}

function getIntersection(){ #(x, y)
    if (($1<0 || $1>27)); then
        echo ' '
        return
    fi
    local value=${INTERSECTIONS[$2]}
    echo "${value:$1:1}"
}

function getObstacle(){ #(x, y)
    if (($1<0 || $1>27)); then
        echo ' '
        return
    fi
    local value=${OBSTACLES[$2]}
    echo "${value:$1:1}"
}

function setObstacle(){ #(x, y, c)
    local line=${OBSTACLES[$2]}
    OBSTACLES[$2]="${line:0:$1}$3${line:$1+1}"
}

function eraseCharacter() { #(x, y)
    setCursorPos $(($1*2)) $2
    local obstacle="$(getObstacle $1 $2)"
    if [ "$obstacle" == '.' ]; then
        printf "$PELLET_COLOR · "
        return
    fi
    if (($2==12&&$1<15&&$1>12)); then
        printf "$WALL_COLOR━━━"
        return
    fi
    if [ "$obstacle" == 'o' ]; then
        printf "$PELLET_COLOR ● "
        return
    fi
    printf "$PELLET_COLOR   "
}

function checkCollisions(){
    for ((i=0;i<GHOSTS;i++)); do
        if ((${g_isCaptured[$i]}==1)); then
            continue
        fi
        if ((px==${gx[$i]}&&py==${gy[$i]})); then
            if (($energizedSteps>0));then
                score=$(($score+$eatGhostScore))
                eatGhostScore=$(($eatGhostScore*2))
                g_isCaptured[$i]=1
                g_changeDirs[$i]=1
                continue
            fi
            if ((${g_isCaptured[$i]}==0)); then
                pacmanHit $i
            fi
        fi
    done
}

function ghostChangeDirection(){ #(id, targetX, targetY)
    local rx=(-1 0 1 0)
    local ry=(0 -1 0 1)
    local minDistance=10000
    for ((i=0; i<3; i++)) do
        local x=$((${gx[$1]}+${rx[$i]}))
        local y=$((${gy[$1]}+${ry[$i]}))
        if [ "$(getIntersection $x $y)" != '#' ]
        then
            local absDiff=$(($2-$x))
            # Handle teleporter
            if [ $y -eq 14 ]
            then
                local absDiff=${absDiff#-}
                
                if [ $((28-$absDiff)) -lt $absDiff ]
                then
                    local absDiff=$((28-$absDiff))
                fi
            fi
            local distance=$((($absDiff*$absDiff)+(($3-$y)*($3-$y))))
            if [ $distance -lt $minDistance ]
            then
                local minDistance=$distance
                gdx[$1]=${rx[$i]}
                gdy[$1]=${ry[$i]}
            fi
        fi
    done

    eraseCharacter ${gx[$1]} ${gy[$1]}
    gx[$1]=$(((${gx[$1]}+${gdx[$1]}+28)%28))
    gy[$1]=$((${gy[$1]}+${gdy[$1]}))
}

function moveGhost(){ #(id, targetX, targetY)
    if ((g_changeDirs[$1]==1)); then
        g_changeDirs[$1]=0
        ghostChangeDirection $1 $2 $3
        return
    fi

    #if in ghosthouse do nothing
    #else if dead open door if not dead close door
    if ((${gx[$1]}>12&&${gx[$1]}<15&&${gy[$1]}<15&&${gy[$1]}>11)); then # (In GhostHouse)
        readarray -t INTERSECTIONS < assets/reviveintersections.txt
    else
        if ((${g_isCaptured[$1]}==1)); then
            readarray -t INTERSECTIONS < assets/reviveintersections.txt
        else
            readarray -t INTERSECTIONS < assets/intersections.txt
        fi
    fi

    local intersection="$(getIntersection ${gx[$1]} ${gy[$1]})"

    local ndx=${gdx[$1]}
    local ndy=${gdy[$1]}

    if [ "$intersection" == 'x' ]
    then
        local rx=($((-${gdy[$1]})) ${gdy[$1]} ${gdx[$1]})
        local ry=($((-${gdx[$1]})) ${gdx[$1]} ${gdy[$1]})
        local minDistance=10000
        for ((i=0; i<3; i++)) do
            local x=$((${gx[$1]}+${rx[$i]}))
            local y=$((${gy[$1]}+${ry[$i]}))
            if [ "$(getIntersection $x $y)" != '#' ]
            then
                local absDiff=$(($2-$x))

                # Handle teleporter
                if [ $y -eq 14 ]
                then
                    local absDiff=${absDiff#-}
                    
                    if [ $((28-$absDiff)) -lt $absDiff ]
                    then
                        local absDiff=$((28-$absDiff))
                    fi
                fi
                local distance=$((($absDiff*$absDiff)+(($3-$y)*($3-$y))))

                if [ $distance -lt $minDistance ]
                then
                    local minDistance=$distance
                    local ndx=${rx[$i]}
                    local ndy=${ry[$i]}
                fi
            fi
        done
    else
        # Check for obstacle
        local obstacle="$(getIntersection $((${gx[$1]}+$ndx)) $((${gy[$1]}+$ndy)))"
        if [ "$obstacle" == '#' ]
        then
            local checkX=$((${gx[$1]}+$ndy))
            local checkY=$((${gy[$1]}+$ndx))
            local obstacle="$(getIntersection $checkX $checkY)"
            if [ "$obstacle" == '#' ]
            then
                local ndx=-${gdy[$1]}
                local ndy=-${gdx[$1]}
            else
                local ndx=${gdy[$1]}
                local ndy=${gdx[$1]}
            fi
            # Check left or right
        fi
    fi
    gdx[$1]=$ndx
    gdy[$1]=$ndy

    eraseCharacter ${gx[$1]} ${gy[$1]}
    gx[$1]=$(((${gx[$1]}+$ndx+28)%28))
    gy[$1]=$((${gy[$1]}+$ndy))
}

function ghostBehaviour(){
    local prx=$(($px+$pdx*4)) # predict X
    local pry=$(($py+$pdy*4)) # predict Y
    for ((g=0;g<GHOSTS;g++)); do
        if ((FRAME_COUNT%4!=g)); then continue; fi
        if ((g_isActive[g]==0)); then 
            if ((g==2)); then g_isActive[$g]=$((pelletsEaten>=30)); fi
            if ((g==3)); then g_isActive[$g]=$((pelletsEaten>=90)); fi
            continue
        fi

        if ((g_isCaptured[g]==1)); then
            moveGhost $g 13 11
            if ((gx[g]==13&&gy[g]==14)); then g_isCaptured[$g]=0; fi
            continue
        elif (($energizedSteps>0)); then
            moveGhost $g ${scx[$g]} ${scy[$g]}
            continue
        fi

        case $g in
            0 )
                moveGhost 0 $px $py
                ;;
            1 )
                moveGhost 1 $prx $pry
                ;;
            2 )
                moveGhost 2 $(($px+$prx-${gx[0]})) $(($py+$pry-${gy[0]}))
                ;;
            3 )
                # If less than 8 tiles away from pacman
                if [ $(((${gx[3]}-$px)*(${gx[3]}-$px)+(${gy[3]}-$py)*(${gy[3]}-$py))) -lt 65 ]
                then
                    moveGhost 3 ${scx[3]} ${scy[3]}
                else
                    moveGhost 3 $px $py
                fi
                ;;
        esac
    done
}

function frighten(){
    # Turn around
    for ((g=0;g<GHOSTS;g++)); do
        if ((!g_isCaptured[g]&&g_isActive[g])); then
            gdx[$g]=$((-gdx[g]))
            gdy[$g]=$((-gdy[g]))
        fi
    done
}

function movePacman(){
    local obstacle="$(getObstacle $(($px+$lcx)) $(($py+$lcy)))"
    if [ "$obstacle" != '#' ]; then
        pdx=$lcx
        pdy=$lcy
    else
        local obstacle="$(getObstacle $(($px+$pdx)) $(($py+$pdy)))"
    fi

    if [ "$obstacle" != '#' ]; then
        eraseCharacter $px $py
        px=$((($px+$pdx+28)%28))
        py=$(($py+$pdy))
    fi

    if [ "$obstacle" == 'o' ]; then
        score=$(($score+50))
        pelletsEaten=$(($pelletsEaten+1))
        energizedSteps=$energizedDuration
        eatGhostScore=200
        setObstacle $px $py " "
        frighten
    fi

    if [ "$obstacle" == '.' ]; then
        score=$(($score+10))
        pelletsEaten=$(($pelletsEaten+1))

        setObstacle $px $py " "
    fi

    if ((pelletsEaten==244)); then
        GAME_STAGE=2
    fi
}

function doGameLogic(){
    if (($energizedSteps>0)); then
        energizedSteps=$(($energizedSteps-1))
    fi

    if (($FRAME_COUNT%3==1)); then
        movePacman
        checkCollisions
    fi
    ghostBehaviour
    checkCollisions

    # Draw stuff
    # Door
    #setCursorPos 26 12
    #printf "$BLUE$ON_BLACK━━━━━"

    drawPacman $(($px*2)) $py "$YELLOW$ON_BLACK"

    # Ghosts should blink when energizer is almost over
    if ((!($energizedSteps>0&&$energizedSteps<31)||$energizedSteps%10>4)); then
        for ((g=0;g<$GHOSTS;g++)); do
            drawGhost $((${gx[$g]}*2)) ${gy[$g]} $g
        done
    fi

    setGlobalCursorPos 0 0
    printf "$ON_BLACK${WHITE}SCORE: $score"
}

function pacmanHit(){ # (ghostId)
    GAME_STAGE=2
    DEATH_TIMER=30
}

function startRound(){
    printf $PELLET_COLOR
    setCursorPos $px $py
    printf "   "
    setCursorPos $((${gx[0]}*2-1)) ${gy[0]}
    printf "   "
    setCursorPos $((${gx[1]}*2-1)) ${gy[1]}
    printf "   "
    setCursorPos 26 17
    printf "      "

    if ((lcy==0)); then
        pdx=$lcx; pdy=$lcy
    else
        pdx=1; pdy=0
    fi
    px=$((($px+$pdx)/2))
}

function doStartScreen(){
    if (($FRAME_COUNT%20==0)); then setCursorPos 26 17; fi

    if (($FRAME_COUNT%40==0)); then printf "$YELLOW${ON_BLACK}READY!"; fi
    if (($FRAME_COUNT%40==20)); then printf "$BLUE${ON_BLACK}READY!"; fi
    
    if (($lcx==0&&$lcy==0)); then return; else GAME_STAGE=1; startRound; fi
}

function deathAnimation(){
    if ((DEATH_TIMER>0)); then
        DEATH_TIMER=$((DEATH_TIMER-1))
    else
        GAME_STAGE=0

        local g=0
        for ((;g<$GHOSTS;g++)); do
            eraseCharacter ${gx[$g]} ${gy[$g]}
        done
        eraseCharacter $px $py
        
        px=27
        py=23
        pdx=0
        pdy=0
        lcx=0 # control dir X
        lcy=0 # control dir Y
        gx=(14 14 12 15)
        gy=(11 14 14 14)
        gdx=(-1 1 1 -1)
        gdy=(0 0 0 0)
        g_isCaptured=(0 0 0 0)
        g_changeDirs=(0 0 0 0)
        energizedSteps=0

        drawCharactersOnStartScreen

        if ((pelletsEaten==244)); then
            readarray -t OBSTACLES < assets/pellets.txt
            pelletsEaten=0
            drawPellets
        fi
    fi
}

FRAME_COUNT=-1
function updateGame(){
    FRAME_COUNT=$(($FRAME_COUNT+1))

    if (($KEY_X!=0||$KEY_Y!=0)); then
        lcx=$KEY_X
        lcy=$KEY_Y
    fi

    if (($GAME_STAGE==0)); then doStartScreen; return; fi
    if (($GAME_STAGE==1)); then doGameLogic; return; fi
    if (($GAME_STAGE==2)); then deathAnimation; return; fi
}
