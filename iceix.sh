#!/bin/bash

# Absolute path to the directory containing::
# 'i9-freeze.sh' and 'i9-melt.sh' script
SCRIPTS_DIR="."

# Local variables
flag_num=$#
action_type=$1 ; shift
flags=()
if [[ $flag_num -eq 0 ]] || \
    [[ $action_type == "-h" ]] || \
    [[ $action_type == "--help" ]]; then
    echo "Ice IX is a command-line toolset for managing 
file and directory permissions.

*freeze: This mod captures the current permissions of specified 
files and directories, storing them in a mapping file.

Flags:

    -a  --appendto      Adds files to mapping file.
    -b  --by            Append file with listed paths.
    -d  --directories   Include directories for quarantine.
    -r  --recursive     Append directories and their files recursively.

Example:

    iceix *freeze * --appendto mappingfile

Freezes permissions for all files in the current directory (*) 
and appends (-a) the data to mappingfile.


*melt: This mod restores the permissions of files and directories 
based on the data stored in the mapping file created by *freeze.

Flags:

    -b  --by            Restore permissions by file.
    -a  --all           Run mod for all log files.
    -r  --recursive     Append directories and their files recursively.

Example:

    iceix *melt some/file --by mappingfile 

Restores permissions for some/file based on mappingfile (-b).

*config: This mod displays base permissions for *freeze action."

    exit 0
fi
# Collect the flags
for flag in "$@"; do
    flags+=($flag)
done

# Selection of action mode
if [[ $action_type == "*freeze" ]]; then
    bash "$SCRIPTS_DIR/i9-freeze.sh" "${flags[@]}"
elif [[ $action_type == "*melt" ]]; then
    bash "$SCRIPTS_DIR/i9-melt.sh" "${flags[@]}"
elif [[ $action_type == "*config" ]]; then
    cat ~/.config/ice-nine
else
    echo "$0: Invalid action type.
Possible are '*freeze', '*melt' or '*config'"
    echo "For more information type: 'iceix -h' or 'iceix --help'"
    exit 1
fi
