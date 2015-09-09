#!/usr/bin/env bash

# Copyright 2014f. D630
# https://github.com/D630/dacti

# -- DEBUGGING.

#printf '%s (%s)\n' "$BASH_VERSION" "${BASH_VERSINFO[5]}" && exit 0
#set -o errexit
#set -o errtrace
#set -o noexec
#set -o nounset
#set -o pipefail
#set -o verbose
#set -o xtrace
#trap '(read -p "[$BASH_SOURCE:$LINENO] $BASH_COMMAND?")' DEBUG
#exec 2>> ~/dacti.log
#typeset vars_base=$(set -o posix ; set)
#fgrep -v -e "$vars_base" < <(set -o posix ; set) | \
#egrep -v -e "^BASH_REMATCH=" \
#         -e "^OPTIND=" \
#         -e "^REPLY=" \
#         -e "^BASH_LINENO=" \
#         -e "^BASH_SOURCE=" \
#         -e "^FUNCNAME=" | \
#less

# -- FUNCTIONS.

function Dacti::Init
{
        {
                builtin typeset i="$(</dev/fd/0)"
        } <<-'INIT'
builtin typeset \
        invocation_mode \
        predir_datadir=${XDG_DATA_HOME:-${HOME}/.local.share} \
        predir_confdir=${XDG_CONFIG_HOME:-${HOME}/.config} \
        prompt=\> \
        selection \
        term=xterm ;

builtin typeset -i DACTI_PRETEND=$DACTI_PRETEND

builtin typeset \
        DACTI_CONF_FILE=${DACTI_CONF_FILE:-${predir_confdir}/dacti/dactirc} \
        DACTI_INDEX_FILE=${DACTI_INDEX_FILE:-${predir_datadir}/dacti/dacti.index}

builtin typeset -a "menu=(
        BIN-ASC
        BIN-ATIME-ASC
        BIN-ATIME-DESC
        BIN-DESC
)"

if
        command tty -s
then
        invocation_mode=cli
elif
        [[ -n $DISPLAY ]]
then
        invocation_mode=gui
else
        builtin printf '%s\n' "Error: Could not determine invocation mode" 1>&2
        builtin return 1
fi

builtin typeset -r \
        DACTI_CONF_FILE \
        invocation_mode ;

[[ -f $DACTI_CONF_FILE ]] || {
        command mkdir -p "${DACTI_CONF_FILE#*/}"
}

[[ -f $DACTI_INDEX_FILE ]] || {
        command mkdir -p "${DACTI_INDEX_FILE#*/}"
        > "$DACTI_INDEX_FILE"
}
INIT
        builtin printf '%s' "$i"

} 2>/dev/null

function Dacti::ExecApp
if
        command -v "${command[0]}" 1>/dev/null 2>&1
then
        if
                [[
                        ${App[nterminal]} -eq 1 ||
                        $invocation_mode == gui
                ]]
        then
                if
                        (( ${App[background]} == 1 ))
                then
                        if
                                (( ${App[keep]} == 1 ))
                        then
                                ( builtin eval ${term} -e "${command[*]}\;${SHELL:-sh}" \& )
                        else
                                ( builtin eval ${term} -e "${command[*]}\;" \& )
                        fi
                else
                        if
                                (( ${App[keep]} == 1 ))
                        then
                                builtin eval ${term} -e "${command[*]}\;${SHELL:-sh}"
                        else
                                builtin eval ${term} -e "${command[*]}\;"
                        fi
                fi
        else
                if
                        (( ${App[background]} == 1 ))
                then
                        ( builtin eval ${SHELL:-sh} "-c ${command[*]}" \& )
                else
                        if
                                (( ${App[keep]} == 1 ))
                        then
                                builtin eval ${SHELL:-sh} "-c ${command[*]}" \; command printf '%s\\n' \'Press ENTER to continue\' ; builtin read
                        else
                                builtin eval ${SHELL:-sh} "-c ${command[*]}"
                        fi
                fi
        fi

        return 1

        if
                (( ${App[terminal]} == 1 )) &&
                (( ${App[nterminal]} == 1 )) ||
                [[ $invocation_mode == gui ]]
        then
                (
                        2>/dev/null \
                        builtin exec ${term} -e "${command[*]};${SHELL:-sh}" &
                )
        else
                ( builtin exec ${command[*]} 2>/dev/null & )
        fi
else
        launch_status=fail
fi

function Dacti::Main
{
        Dacti::GetArgs "$@" || {
                builtin source <(Dacti::Init)
                [[ -f "$DACTI_CONF_FILE" ]] && {
                        builtin source "$DACTI_CONF_FILE"
                }
                Dacti::MainLoop
        }
}

function Dacti::GetArgs
case $1 in
-h | --help)
        Dacti::PrintHelp
;;
-v | --version)
        Dacti::PrintVersion
;;
*)
        builtin return 1
esac

function Dacti::PrintVersion
{
        builtin printf 'v%s\n' "0.2.0"
}

function Dacti::PrintHelp
{
        {
                builtin typeset help="$(</dev/fd/0)"
        } <<'HELP'
Usage
        dacti [ -h | --help | -v | --version ]

Main selection menu: entries
        [BIN-ASC]                       Browse executables within <PATH>. Sort
                                        them in ascending order by their names
        [BIN-DESC]                      "" Sort them in descending order by their
                                        names
        [BIN-ATIME-ASC]                 "" Sort them in ascending order by their
                                        access times
        [BIN-ATIME-DESC]                "" Sort them in descending order by their
                                        access times
        <COMMAND>                       Launch application (run or raise)

Main selecton menu: command prefixes
        :b                              Execute COMMAND in background
        :c                              Declare mode 'cli'
        :i                              Declare status 'ign'
        :k                              Keep the process. Wait for a key press
                                        or spawn a new shell instance
        :l                              Declare status 'block'
        :n                              Run COMMAND in a new terminal emulator
                                        window
        :p                              Don't check, wheater COMMAND is indexed.
                                        Launch it directly and create NO record.
                                        See env DACTI_PRETEND
        :t                              Declare mode 'tui'
        :u                              Don't check, wheater COMMAND is indexed.
                                        Launch it directly and create a new
                                        record.

Environment variables
        DACTI_CONF_FILE                 See function Dacti::Init
        DACTI_INDEX_FILE                ""
        DACTI_PRETEND                   Default: 0

Configuration
        normal scalar variables
            prompt                      Default: >
            term                        Default: xterm
        indexed array variables
            menu                        See entry section above
        functions
            Dacti::CmdMenuCustom        See doc/examples/dactirc
            Dacti::ParseSelectionCustom ""
            Dacti::RaiseAppPlCustom     ""
            Dacti::RaiseAppSgCustom     ""
HELP
        builtin printf '%s\n' "$help"
}

function Dacti::MainLoop
while
        builtin :
do
        selection=$(
                Dacti::PrintMenu0 \
                | Dacti::CmdMenu
        )
        case ${selection,,} in
        \[bin-asc\])
                Dacti::ParseSelection "$(
                        Dacti::PrintMenuBinAsc \
                        | Dacti::CmdMenu "BIN-ASC"
                )"
        ;;
        \[bin-atime-asc\])
                Dacti::ParseSelection "$(
                        Dacti::PrintMenuBinAtimeAsc \
                        | Dacti::CmdMenu "BIN-ATIME-ASC"
                )"
        ;;
        \[bin-atime-desc\])
                Dacti::ParseSelection "$(
                        Dacti::PrintMenuBinAtimeDesc \
                        | Dacti::CmdMenu "BIN-ATIME-DESC"
                )"
        ;;
        \[bin-desc\])
                Dacti::ParseSelection "$(
                        Dacti::PrintMenuBinDesc \
                        | Dacti::CmdMenu "BIN-DESC"
                )"
        ;;
        \[*\])
                builtin typeset -f Dacti::ParseSelectionCustom 1>/dev/null 2>&1 && {
                        Dacti::ParseSelectionCustom "${selection//[\[\]]/}"
                }
                builtin :
        ;;
        "")
                builtin return 0
        ;;
        *)
                Dacti::ParseSelection "$selection"
        esac
done

function Dacti::IndexApp
{
        >> "$DACTI_INDEX_FILE" \
        builtin printf '%s\n' "${App[status]} ${App[mode]}${opts:+:${opts}} ${App[class]} ${command[0]}"
}

function Dacti::ParseSelection
{
        [[ -z $* ]] && builtin return 0

        builtin typeset \
                launch_status \
                opts \
                pref_status \
                pref_mode ;

        builtin typeset -i \
                pref_background= \
                pref_keep= \
                pref_nterminal= \
                pref_pretend=$DACTI_PRETEND \
                pref_idx= ;

                #pref_terminal=

        builtin typeset -a "command=($1)"

        builtin typeset -A App

        [[ ${command[0]} == :* ]] && {
                while
                        builtin read -r -n 1
                do
                        case $REPLY in
                        b)
                                pref_background=1
                                opts+=b
                        ;;
                        k)
                                pref_keep=1
                                opts+=k
                        ;;
                        l)
                                pref_status=block
                        ;;
                        c)
                                #pref_terminal=1
                                pref_mode=cli
                        ;;
                        i)
                                pref_status=ign
                        ;;
                        n)
                                pref_nterminal=1
                                opts+=n
                        ;;
                        p)
                                pref_pretend=1
                        ;;
                        t)
                                #pref_terminal=1
                                pref_mode=tui
                        ;;
                        u)
                                pref_idx=1
                        esac
                done <<< "${command[0]/:/}"

                command=(${command[@]:1})
        }

        if
                ((
                        pref_pretend == 0 ||
                        pref_idx == 0
                ))
        then
                builtin typeset \
                        idx_app \
                        idx_class \
                        idx_mode \
                        idx_status ;
                while
                        builtin read -r idx_status idx_mode idx_class idx_app
                do
                        [[ $idx_app == ${command[0]} ]] && {
                                App=(
                                        [idx_status]=$idx_status
                                        [idx_mode]=$idx_mode
                                        [idx_class]=$idx_class
                                        [idx_app]=$idx_app
                                )
                                while
                                        builtin read -r -n 1
                                do
                                        case $REPLY in
                                        b)
                                                pref_background=1
                                        ;;
                                        k)
                                                pref_keep=1
                                        ;;
                                        n)
                                                pref_nterminal=1
                                        esac
                                done <<< "${idx_mode##*:}"
                        }
                done < "$DACTI_INDEX_FILE"

                [[ -n ${App[idx_status]} ]] || pref_idx=1
        fi

        App[status]=${pref_status:-${App[idx_status]}}
        App[status]=${App[status]:-reg}
        App[background]=$pref_background
        App[keep]=$pref_keep
        #App[terminal]=$pref_terminal
        App[nterminal]=$pref_nterminal
        App[mode]=${pref_mode:-${App[idx_mode]}}
        App[mode]=${App[mode]:-gui}

        if
                [[ -n ${App[idx_class]} ]]
        then
                App[class]=${App[idx_class]}
        else
                builtin typeset c=${command[0]:0:1}
                App[class]=${c^}${command[0]:1}
        fi

        case ${App[status]} in
        block)
                builtin false
        ;;
        ign)
                Dacti::ExecApp
        ;;
        reg)
                Dacti::RaiseApp
        ;;
        *)
                builtin return 1
        esac

        if
                [[ ${pref_idx}${pref_pretend}${launch_status} == 10 ]]
        then
                Dacti::IndexApp
        fi

        builtin return 1
}

function Dacti::PrintMenu0
{
        builtin typeset \
                app \
                class \
                mode \
                status ;

        builtin printf '[%s]\n' "${menu[@]}"

        while
                builtin read -r status mode class app
        do
                [[ $status == block ]] || {
                        builtin printf '%s\n' "$app"
                }
        done < "$DACTI_INDEX_FILE" \
        | command sort -u
}

function Dacti::PrintMenuBinAsc
{
        command lsx ${PATH//:/ } \
        | command sort -u
}

function Dacti::PrintMenuBinAtimeAsc
{
        command find ${PATH//:/ } \( -type f -o -type l \) -printf '%A@\t%P\n' \
        | command sort -n \
        | command cut -f2 \
        | command fgrep -xf <(command lsx ${PATH//:/ }) \
        | command uniq
}

function Dacti::PrintMenuBinAtimeDesc
{
        command find ${PATH//:/ } \( -type f -o -type l \) -printf '%A@\t%P\n' \
        | command sort -rn \
        | command cut -f2 \
        | command fgrep -xf <(command lsx ${PATH//:/ }) \
        | command uniq
}

function Dacti::PrintMenuBinDesc
{
        command lsx ${PATH//:/ } \
        | command sort -ru
}

function Dacti::CmdMenu
if
        builtin typeset -f Dacti::CmdMenuCustom 1>/dev/null 2>&1
then
        Dacti::CmdMenuCustom "${1:-$prompt}"
else
        command dmenu -p "${1:-$prompt}"
fi

function Dacti::RaiseApp
{
        builtin typeset \
                id \
                pid \
                wm_pid \
                xlist ;

        builtin typeset -a \
                pid_list \
                xids ;

        builtin read -r _ _ _ _ xlist < <(
                command xprop -root _NET_CLIENT_LIST
        )

        if
                [[ ${App[mode]} == gui ]]
        then
                for id in ${xlist//,/}
                do
                        [[ $(command xprop -id "$id" WM_CLASS) =~ ${App[class]} ]] && {
                                xids+=($id)
                        }
                done
        else
                for pid in $(command pgrep -d ' ' "${command[0]}")
                do
                        until
                                [[ ${pid// /} -eq 0 ]]
                        do
                                pid=$(
                                        2>/dev/null \
                                        command ps -p "${pid// /}" -o ppid=
                                )
                                pid_list+=(${pid// /})
                        done
                done
                for id in ${xlist//,/}
                do
                        builtin read -r _ _ wm_pid < <(
                                command xprop -id "$id" _NET_WM_PID
                        )
                        for pid in "${pid_list[@]}"
                        do
                                [[ $wm_pid == $pid ]] && xids+=($id)
                        done
                done
        fi

        case ${#xids[@]} in
        0)
                Dacti::ExecApp
        ;;
        1)
                if
                        builtin typeset -f Dacti::RaiseAppSgCustom 1>/dev/null 2>&1
                then
                        Dacti::RaiseAppSgCustom "${xids[0]}"
                else
                        Dacti::RaiseAppSg "${xids[0]}"
                fi
        ;;
        *)
                if
                        builtin typeset -f Dacti::RaiseAppPlCustom 1>/dev/null 2>&1
                then
                        Dacti::RaiseAppPl "${xids[@]}"
                else
                        Dacti::RaiseAppPl "${xids[@]}"
                fi
        esac
}

function Dacti::RaiseAppSg
{
        command wmctrl -i -a "$1" || {
                launch_status=fail
                builtin return 1
        }
}

function Dacti::RaiseAppPl
{
        builtin typeset id

        for id
        do
                Dacti::RaiseAppSg "$id" || {
                        launch_status=fail
                        builtin return 1
                }
        done
}

# -- MAIN.

Dacti::Main "$@"
