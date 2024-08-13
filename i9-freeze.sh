#!/bin/bash

# Collector functions
flag_collector() {
    while [[ $# -gt 0 ]]; do
        arg=$1
        if [[ ${arg:0:2} == "--" ]]; then
            long_flags_collector $arg $2
            if [ $shift_bit -eq 1 ]; then
    		    shift ; shift_bit=0
    		fi
            any_flags=1
    	elif [[ ${arg:0:1} == "-" ]]; then
    	    short_flags_collector $arg $2
    		if [ $shift_bit -eq 1 ]; then
    		    shift ; shift_bit=0
    		fi
    		any_flags=1
    	elif [[ $arg == "*" ]]; then
    	   entry_paths+=("./")
    	else
    	    if [ -d $1 ]; then
           	    entry_paths+=($arg)
            else
                entry_files+=($(readlink -f $arg))
    		fi
    	fi
    	shift
    done
}

long_flags_collector() {
	case $1 in
		"--recursive") recursive=1;;
		"--directories") directories=1;;
		"--appendto") append_list_path=$2
		    shift_bit=1;;
		"--by") by_action $2
            shift_bit=1;;
		*) incorrect_flag_error $1;;
	esac
}

short_flags_collector() {
	case $1 in
		"-r") recursive=1;;
		"-d") directories=1;;
		"-a") append_list_path=$2
		    shift_bit=1;;
		"-b") by_action $2
            shift_bit=1;;
        "-rd" | "-dr") recursive=1
            directories=1;;
		*) incorrect_flag_error $1;;
	esac
}

# Collect files paths listed in file
by_action() {
	path="$1"
	while IFS= read -r line; do
	    if [[ -d $line ]]; then
			entry_paths+=($line)
		else
		    entry_files+=($(readlink -f $line))
		fi
	done < "$path"
}

# Converts paths to necessary files format
path_to_files() {
    files=()
    if [ $recursive -eq 1 ]; then
        for element in ${entry_paths[@]}; do
            if [ -f $element ]; then
                absolute=$(readlink -f $element)
                entry_files+=($absolute)
            else
                files=$(find $element -type f)
                files=$(file_absolute_path "$files")
                entry_files+=($files)
            fi
        done
    else
        for element in ${entry_paths[@]}; do
            if [ -f $element ]; then
                absolute=$(readlink -f $element)
                entry_files+=($absolute)
            else
                files=$(find $element -maxdepth 1 -type f)
                files=$(file_absolute_path "$files")
                entry_files+=($files)
            fi
        done
    fi

    # Cleaned version
    for file in ${entry_files[@]}; do
        cleaned_files+=($file)
    done
}

get_all_dirs() {
    if [[ $directories -eq 1 ]]; then
        for dir in ${entry_paths[@]}; do
            if [[ $recursive -eq 1 ]]; then
                dirs=$(find $dir -type d | tail -n +2)
                entry_paths+=($dirs)
            fi
        done

        # Cleaned version
        sorted_paths=($(printf "%s\n" "${entry_paths[@]}" | \
            awk '{print length($0), $0}' | sort -nr | cut -d ' ' -f2-))
        for dir in ${sorted_paths[@]}; do
            cleaned_paths+=($(realpath $dir))
        done
    fi
}

# Get absolute format of files
file_absolute_path() {
    elements=$1
    files=()
    for element in ${elements[@]}; do
        files+=($(readlink -f $element))
        file=$(readlink -f $element)
    done
    echo ${files[@]}
}

# Dictionary of files with permission bits
with_permission_bits() {
    combined=("${cleaned_files[@]}" "${cleaned_paths[@]}")
    octal_bits=""
    for path in ${combined[@]}; do
        octal_bits=$(stat --format="%a" $path)
        if [[ $octal_bits -eq 0 ]]; then
            octal_bits="000"
        fi
        permissions+=("$path:::$octal_bits")
    done
}

# Send permissions to mapping file
permissions_to_file() {
    if [[ ! -f "$append_list_path" ]]; then
        read -p "File doesn't exist. Do you want to create it? [Y/n] " response
        response=$(echo $response | tr '[:lower:]' '[:upper:]')
        case $response in
            "Y" | "YES") touch $append_list_path;;
            "N" | "NO") exit 1;;
            *) icorrect_response_error $response;;
        esac
    fi
    for element in ${permissions[@]}; do
        file=$(echo $element | awk -F ':::' '{print $1}')
        mod=$(echo $element | awk -F ':::' '{print $2}')
        timestamp=$(date "+%d-%m-%Y %H:%M:%S")
        echo -n "$timestamp |$mod| $file" >> $append_list_path
        echo "" >> $append_list_path
    done
    echo "" >> $append_list_path
}

# Quarantines files e.g. chmod XXX file.txt
# Type of perrmision is set in config file in octal base system
set_quarantine() {
    file_mod=$(awk -F '=' '/^FILE_QUARANTINE_MOD/ {print $2}' "$CONFIG_FILE")
    dir_mod=$(awk -F '=' '/^DIRECTORY_QUARANTINE_MOD/ {print $2}' "$CONFIG_FILE")
    for element in ${combined[@]}; do
        if [[ -f $element ]]; then
            chmod $file_mod $element
        else
            chmod $dir_mod $element
        fi
    done
}

# Error handler
flags_check() {
	if [[ $any_flags -eq 0 ]]; then
	    echo "$0: Provide arguments for 'freeze' action."
	    exit 1
	fi
	if [[ $append_list_path == "" ]]; then
	    echo "$0: Provide an argument relating to the 'append to' action."
	    exit 1
	fi
	if [[ ${#entry_files[@]} == 0 ]]; then
	    echo "$0: Provide 'directory / files' for freeze action."
	    exit 1
	fi
}

incorrect_flag_error() {
    echo "$1: Invalid flag."
    exit 1
}

incorrect_response_error() {
    echo "$1: Invalid response."
    exit 1
}

# Constant
CONFIG_FILE=~/.config/ice-nine


# Valid arguments collector
entry_paths=() ; entry_files=()
cleaned_paths=() ; cleaned_files=()
combined=()
concat_args=() ; permissions=()
append_list_path=""
recursive=0 ; any_flags=0 ; directories=0
shift_bit=0

# Flags collector
flag_collector "$@"

# Clear entry files
path_to_files $entry_paths
get_all_dirs $entry_paths
with_permission_bits $cleaned_files $cleaned_paths
flags_check # Error catcher
permissions_to_file # Send files and permissions to --appendto file

# Last stage
set_quarantine # Files / directories changed to XXX mod
