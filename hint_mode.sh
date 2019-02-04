#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

current_pane_id=$1
picker_pane_id=$2
last_pane_id=$3
picker_window_id=$4
pane_input_temp=$5

eval "$(tmux show-env -g -s | grep ^PICKER)"

match_lookup_table=$(mktemp)

# exporting it so they can be properly deleted inside handle_exit trap
export match_lookup_table

function lookup_match() {
    local input=$1

    input="$(echo "$input" | tr "A-Z" "a-z")"
    grep -i "^$input:" $match_lookup_table | sed "s/^$input://" | head -n 1
}

function get_pane_contents() {
    cat $pane_input_temp
}

function extract_hints() {
    clear
    export NUM_HINTS_NEEDED=$(get_pane_contents | gawk -f $CURRENT_DIR/counter.awk)
    get_pane_contents | gawk -f $CURRENT_DIR/hinter.awk 3> $match_lookup_table
}

function show_hints_again() {
    local picker_pane_id=$1

    tmux swap-pane -s "$current_pane_id" -t "$picker_pane_id" # hide screen clearing glitch
    extract_hints
    tmux swap-pane -s "$current_pane_id" -t "$picker_pane_id"
}

function show_hints_and_swap() {
    current_pane_id=$1
    picker_pane_id=$2

    extract_hints
    tmux swap-pane -s "$current_pane_id" -t "$picker_pane_id"
}


BACKSPACE=$'\177'

input=''
result=''

function is_pane_zoomed() {
    local pane_id=$1

    tmux list-panes \
        -F "#{pane_id}:#{?pane_active,active,nope}:#{?window_zoomed_flag,zoomed,nope}" \
        | grep -c "^${pane_id}:active:zoomed$"
}

function zoom_pane() {
    local pane_id=$1

    tmux resize-pane -Z -t "$pane_id"
}

function revert_to_original_pane() {
    tmux swap-pane -s "$current_pane_id" -t "$picker_pane_id"

    if [[ ! -z "$last_pane_id" ]]; then
        tmux select-pane -t "$last_pane_id"
        tmux select-pane -t "$current_pane_id"
    fi

    [[ $pane_was_zoomed == "1" ]] && zoom_pane "$current_pane_id"
}

function handle_exit() {
    rm -rf "$pane_input_temp" "$match_lookup_table"
    revert_to_original_pane

    if [[ ! -z "$result" ]]; then
        run_picker_copy_command "$result" "$input"
    fi

    tmux kill-window -t "$picker_window_id"
}


function is_valid_input() {
    local input=$1
    local is_valid=1

    if [[ $input == "" ]] || [[ $input == "<ESC>" ]]; then
        is_valid=1
    else
        for (( i=0; i<${#input}; i++ )); do
            char=${input:$i:1}

            if [[ ! "$char" =~ ^[a-zA-Z]$ ]]; then
                is_valid=0
                break
            fi
        done
    fi

    echo $is_valid
}

function hide_cursor() {
    echo -n $(tput civis)
}

trap "handle_exit" EXIT

export PICKER_PATTERNS=$PICKER_PATTERNS1
export PICKER_BLACKLIST_PATTERNS=$PICKER_BLACKLIST_PATTERNS

pane_was_zoomed=$(is_pane_zoomed "$current_pane_id")
show_hints_and_swap $current_pane_id $picker_pane_id
[[ $pane_was_zoomed == "1" ]] && zoom_pane "$picker_pane_id"

hide_cursor
input=''

function run_picker_copy_command() {
    local result="$1"
    local hint="$2"

    is_uppercase=$(echo "$input" | grep -E '^[a-z]+$' &> /dev/null; echo $?)

    if [[ $is_uppercase == "1" ]] && [ ! -z "$PICKER_COPY_COMMAND_UPPERCASE" ]; then
        command_to_run="$PICKER_COPY_COMMAND_UPPERCASE"
    elif [ ! -z "$PICKER_COPY_COMMAND" ]; then
        command_to_run="$PICKER_COPY_COMMAND"
    fi

    if [[ ! -z "$command_to_run" ]]; then
        tmux run-shell -b "printf '$result' | $command_to_run"
    fi
}

while read -rsn1 char; do
    if [[ $char == "$BACKSPACE" ]]; then
        input=""
    fi

    # Escape sequence, flush input
    if [[ "$char" == $'\x1b' ]]; then
        read -rsn1 -t 0.1 next_char

        if [[ "$next_char" == "[" ]]; then
            read -rsn1 -t 0.1
            continue
        elif [[ "$next_char" == "" ]]; then
            char="<ESC>"
        else
            continue
        fi

    fi

    if [[ ! $(is_valid_input "$char") == "1" ]]; then
        continue
    fi

    if [[ $char == "$BACKSPACE" ]]; then
        input=""
        continue
    elif [[ $char == "<ESC>" ]]; then
            exit
    elif [[ $char == "" ]]; then
        if [ "$PICKER_PATTERNS" = "$PICKER_PATTERNS1" ]; then
                export PICKER_PATTERNS=$PICKER_PATTERNS2;
        else
                export PICKER_PATTERNS=$PICKER_PATTERNS1;
        fi
        show_hints_again "$picker_pane_id"
        continue
    else
        input="$input$char"
    fi

    result=$(lookup_match "$input")

    if [[ -z $result ]]; then
        continue
    fi

    exit 0
done < /dev/tty
