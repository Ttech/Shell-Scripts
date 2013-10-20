#!/bin/bash
## Piano Beeps
## Simply the best piano emulator for *nix

# Change the variables here to get different output (Designed for basic songs only)
notes=(F# F C C# G G# C C D E F G F E D C E G E C) # put list of notes here.
length=250 # 200 miliseconds seems pretty good timing for general

function get_note {
	## Generic Key Mapping

	# check for "Sharps" before the rest
	if [[ $1 = "f#" || $1 == "F#" ]]
	then
		echo 370
	elif [[ $1 = "a#" || $1 == "A#" ]]
	then
		echo 466
	elif [[ $1 == "c#" || $1 == "C#" ]]
	then
		echo 277
	elif [[ $1 == "d#" || $1 == "D#" ]]
	then
		echo 311
	elif [[ $1 == "g#" || $1 == "G#" ]]
	then
		echo 415
	# Start check with White keys.
	# these also will catch any spaces or extras
	elif [[ $1 == *A* || $1 == *a* ]]
	then
		echo 440
        elif [[ $1 == *b* || $1 == *B* ]]
        then
                echo 494
        elif [[ $1 == *c* || $1 == *C* ]]
        then
                echo 262
        elif [[ $1 == *d* || $1 == *D* ]]
        then
                echo 295
        elif [[ $1 == *e* || $1 == *E* ]]
        then
                echo 330
        elif [[ $1 == *F* || $1 == *f* ]]
        then
                echo 349
        elif [[ $1 == *g* || $1 == *G* ]]
        then
                echo 392
        fi
}

for note in "${notes[@]}"
do
        freq=$(get_note $note)
        # Display what we are doing, and then run it (minus errors in output)
        echo "beep -f $freq -l 200 # $note at $length miliseconds"
        beep -f $freq -l $length >/dev/null
done

