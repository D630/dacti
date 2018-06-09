##### README

[dacti](https://github.com/D630/dacti) is a simple menu driven run or raise
bash shell script. By default, dacti works with
[dmenu](http://tools.suckless.org/dmenu/) and
[wmctrl](https://sites.google.com/site/tstyblo/wmctrl/), but you may
[configure](../master/doc/examples/dactirc) and use your preferred tools.

##### BUGS & REQUESTS

Please feel free to open an issue or put in a pull request on
https://github.com/D630/dacti

##### GIT

To download the very latest source code:

```
git clone https://github.com/D630/dacti
```

In order to use the latest tagged version, do also something like this:

```
cd ./dacti
git checkout $(git describe --abbrev=0 --tags)
```

##### INSTALL

Just put `./bin/dacti` on your PATH.

##### USAGE

###### INVOCATION

```
dacti [ -h | --help ]
```

###### COMMANDS

```
Main selection menu: entries
    BIN-ASC                         Browse executables within PATH. Sort
                                    them in ascending order by their names.
    BIN-DESC                        "" Sort them in descending order by their
                                    names.
    BIN-ATIME-ASC                   "" Sort them in ascending order by their
                                    access times.
    BIN-ATIME-DESC                  "" Sort them in descending order by their
                                    access times.
    INSERT                          Open a menu with an empty list and insert
                                    a command.
    [:MODIFIERS ]COMMAND            Launch application (run or raise) from
                                    DACTI_INDEX_FILE.

Main selecton menu: modifiers
    i                               Declare status 'ign'.
    k                               Keep the process. Wait for a key press
                                    or spawn a new shell instance.
    d                               COMMAND depends on DISPLAY.
    n                               Run COMMAND in a new terminal emulator
                                    window.
    p                               Launch COMMAND directly and create NO
                                    record.
                                    See also env variable DACTI_PRETEND.
    t                               COMMAND needs a controlling tty.
```

###### ENVIRONMENT VARIABLES

```
Environment variables
    DACTI_CONF_FILE                 See function Dacti::Main
    DACTI_INDEX_FILE                ""
    DACTI_PRETEND                   Default: 0
```

###### CONFIGURATION

```
Configuration
    normal scalar variables
        in_tty                      Output of: ps -p "$PPID" -o tty=
        prompt                      Default: >
        term                        Default: xterm
    indexed array variables
        apps                        All app names from DACTI_INDEX_FILE.
        command                     Selected/Typed command list without prefixed
                                    modifiers.
        menu                        See entry section above.
    associative array variables
        App                         Parsed preferences for COMMAND:
                                    <class>
                                    <display>
                                    <flags>
                                    <keep>
                                    <nterminal>
                                    <status>
                                    <terminal>
        DactiApps                   Mapped entries from DACTI_INDEX_FILE:
                                    <app COMMAND>
                                    <class COMMAND>
                                    <flags COMMAND>
                                    <status COMMAND>
    functions
        Dacti::CmdMenuCustom        See doc/examples/dactirc
        Dacti::CmdMenuEmptyCustom   ""
        Dacti::ExecAppCustom        ""
        Dacti::ParseSelectionCustom ""
        Dacti::RaiseAppCustom       ""
```

###### INDEX FILE

Without command modifiers, a record gets the status `reg` (may run OR raise).
With a status `ign`, a command is not allowed to raise an existing window.

A record looks like:

```
# STATUS MODIFIERS WM_CLASS COMMAND

reg d xcalc.XCalc xcalc
reg t - alsamixer
ign tk - task
ign - - ls
```

If a command has more than one record, the last entry is going to be used.

The WM_CLASS string is considered as extended regular expression pattern
(regex(3)).

##### NOTICE

dacti has been written in [GNU bash](http://www.gnu.org/software/bash/) on
[Debian GNU/Linux stretch/sid (4.9.6-3 x86-64)](https://www.debian.org) using
the following programs/packages:

- GNU bash 4.4.11(1)-release
- GNU coreutils 8.26: cut, mkdir, printf, sort, uniq
- GNU findutils 4.7.0-git: find
- GNU grep 2.27
- procps 3.3.12: pgrep, ps
- suckless-tools 42-2: dmenu, stest
- wmctrl 1.07-7
- x11-utils 7.7+3: xprop 1.2.2

##### CREDITS

dacti was a rewrite of acti (v0.8; GNU GPLv3) by D630.

dacti was affected by Scott Garretts dmenu-launch (v0.5.7).

##### LICENCE

GNU GPLv3
