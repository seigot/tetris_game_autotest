#!/bin/bash -x

CURRENT_DIR=`pwd`
TMP_LOG="${CURRENT_DIR}/tmp.log"
DISPLAY_PY="${CURRENT_DIR}/display.py"
RESULT_LOG="${CURRENT_DIR}/result.log"

# ffmpeg -i *.mp4 -ac 1 *.wav
# ffmpeg -i *.mp3 *.wav
SOUNDFILE_LIST=(
    "~/Downloads/technotris.wav"
    "~/Downloads/troika.wav"
    "~/Downloads/kalinka.wav"
)

# init RESULT_LOG
echo "repository_name, level, score, line, gameover, 1line, 2line, 3line, 4line" > $RESULT_LOG

# enable pyenv (if necessary)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# function
function do_game(){

    LEVEL=$1

    # get repository list
    if [ ${LEVEL} == 1 ]; then
	# level 1
	CLONE_REPOSITORY_LIST=(
	    "http://github.com/yuin0/tetris_game -b feature/yuin0/improve-controller2"
	    "http://github.com/hirov2/tetris_game"
	    "http://github.com/YSK-2/tetris_game"
	    "http://github.com/Git0214/tetris_game"
	    "http://github.com/tsumekko/tetris_game"
	    "http://github.com/n-nooobu/tetris_game -b develop-rulebase"
	)
    elif [ ${LEVEL} == 2 ]; then
	# level 2
	CLONE_REPOSITORY_LIST=(
	    "http://github.com/yuin0/tetris_game -b feature/yuin0/improve-controller2"
	    "http://github.com/sue-robo/tetris_game -b dev3"
	)
    elif [ ${LEVEL} == 3 ]; then
	# level 3
	CLONE_REPOSITORY_LIST=(
	    "http://github.com/yuin0/tetris_game -b feature/yuin0/improve-controller2"
	)
    elif [ ${LEVEL} == 777 ]; then
	# forever branch
	CLONE_REPOSITORY_LIST=(
	    "http://github.com/kyad/tetris_game -b forever-branch"
	)
    else
	echo "invalid level ${LEVEL}"
	return
    fi

    # main loop
    for (( i = 0; i < ${#CLONE_REPOSITORY_LIST[@]}; i++ ))
    do
	#############
	##
	##  prepare
	##
	#############
	REPOSITORY_OWNER=`echo ${CLONE_REPOSITORY_LIST[$i]} | cut -d' ' -f1 | cut -d'/' -f4`
	#SOUND_NUMBER=`echo $((RANDOM%+3))` # 0-2 random value
	SOUND_NUMBER=`echo $[i]`
	SOUND_NUMBER=`echo $(( $[SOUND_NUMBER] % ${#SOUNDFILE_LIST[@]} ))`
	SOUNDFILE_PATH=${SOUNDFILE_LIST[$SOUND_NUMBER]}
	SOUNDFILE_NAME=`echo ${SOUNDFILE_PATH} | cut -d/ -f3`
	GAMETIME=180

	# pyenv select
	if [ ${LEVEL} == 1 -o ${LEVEL} == 777 ]; then
	    # other env (python3.6.9)
	    pyenv activate myenv3.6.9
	    python -V
	elif [ ${REPOSITORY_OWNER} == "sue-robo" ]; then
	    # sue-robo_env
	    pyenv activate sue-robo_env
	else
	    # default
	    pyenv activate myenv3.6.9
	    python -V
	fi
	
	echo "git clone ${CLONE_REPOSITORY_LIST[$i]}"
	echo "REPOSITORY_OWNER: ${REPOSITORY_OWNER}"
	echo "LEVEL: ${LEVEL}"
	echo "SOUND_NUMBER: ${SOUND_NUMBER}"
	echo "SOUNDFILE_PATH: ${SOUNDFILE_PATH}"

        # wait game start
	WAIT_TIME=180
	#sleep $GAME_TIME
	python3 ${DISPLAY_PY} --player_name "Next... ${REPOSITORY_OWNER}" --level 0 --sound_name "xxx" --max_time ${WAIT_TIME}	
	
	#############
	##
	##  main
	##
	#############
	cd ~
	rm -rf tetris_game
	mkdir tetris_game
	git clone ${CLONE_REPOSITORY_LIST[$i]}
	pushd tetris_game
	if [ ${LEVEL} == 2 -o ${LEVEL} == 3 ]; then
	    # fix random seed
	    echo "fix random seed"
	    TARGET_LINE=`grep --line-number "game_manager.py" start.sh | tail -1 | cut -d: -f1`
	    sed -e "${TARGET_LINE}i RANDOM_SEED=\"20210721\"" start.sh > start.sh.org
	    mv start.sh.org start.sh
	fi
	
	play ${SOUNDFILE_PATH} &
	python3 ${DISPLAY_PY} --player_name ${REPOSITORY_OWNER} --level ${LEVEL} --sound_name ${SOUNDFILE_NAME} &
	touch ${TMP_LOG}
	bash start.sh -l${LEVEL} -t${GAMETIME} > ${TMP_LOG}
	#stdbuf -o0 bash start.sh -l${LEVEL} -t${GAMETIME} > ${TMP_LOG}
	sleep 2

	#############
	##
	##  finish
	##
	#############
	# pyenv deactivate
	pyenv deactivate

	# get result
	SCORE=`grep "YOUR_RESULT" ${TMP_LOG} -2 | grep score | cut -d, -f1 | cut -d: -f2`
	LINE_CNT=`grep "YOUR_RESULT" ${TMP_LOG} -2 | grep score | cut -d, -f2 | cut -d: -f2`
	GAMEOVER_CNT=`grep "YOUR_RESULT" ${TMP_LOG} -2 | grep score | cut -d, -f3 | cut -d: -f2`
	_1LINE_CNT=`grep "SCORE DETAIL" ${TMP_LOG} -5 | grep "1 line" | cut -d= -f2`
	_2LINE_CNT=`grep "SCORE DETAIL" ${TMP_LOG} -5 | grep "2 line" | cut -d= -f2`
	_3LINE_CNT=`grep "SCORE DETAIL" ${TMP_LOG} -5 | grep "3 line" | cut -d= -f2`
	_4LINE_CNT=`grep "SCORE DETAIL" ${TMP_LOG} -5 | grep "4 line" | cut -d= -f2`
	RESULT_STR="${REPOSITORY_OWNER}, ${LEVEL}, ${SCORE}, ${LINE_CNT}, ${GAMEOVER_CNT}, ${_1LINE_CNT}, ${_2LINE_CNT}, ${_3LINE_CNT}, ${_4LINE_CNT}"
	echo ${RESULT_STR}
	echo ${RESULT_STR} >> ${RESULT_LOG}
	popd

    done

    cat ${RESULT_LOG}

    return 0
}

do_game 777 # forever branch
do_game 1   # level1
do_game 2   # level2
do_game 3   # level3


echo "ALL GAME FINISH !!!"
exit 0


"http://github.com/kyad/tetris_game"
"http://github.com/yuin0/tetris_game"
"http://github.com/adelie7273/tetris_game"
"http://github.com/anchobi-no/tetris_game"
"http://github.com/dadada-dada/tetris_game"
"http://github.com/F0CACC1A/tetris_game"
"http://github.com/Git0214/tetris_game"
"http://github.com/hirov2/tetris_game"
"http://github.com/iceball360/tetris_game"
"http://github.com/isshy-you/tetris_game"
"http://github.com/k-onishi/tetris_game"
"http://github.com/Leozyc-waseda/tetris_game"
"http://github.com/n-nooobu/tetris_game"
"http://github.com/neteru141/tetris_game"
"http://github.com/nmurata90/tetris_game"
"http://github.com/nogumasa/tetris_game"
"http://github.com/OhdachiEriko/tetris_game"
"http://github.com/sahitaka/tetris_game"
"http://github.com/sue-robo/tetris_game"
"http://github.com/taichofu/tetris_game"
"http://github.com/tara938/tetris_game"
"http://github.com/tommy-m18/tetris_game"
"http://github.com/tsumekko/tetris_game"
"http://github.com/YSK-2/tetris_game"

