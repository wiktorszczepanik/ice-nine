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
    	   entry_paths+=($(realpath ./))
    	else
    	    if [ -d $1 ]; then
           	    entry_paths+=($(realpath $arg))
                by_check=1
            else
                entry_paths+=($(readlink -f $arg))
                by_check=1
    		fi
    	fi
    	shift
    done
}

long_flags_collector() {
	case $1 in
		"--recursive") recursive=1;;
		"--all") by_all=1 ; by_check=1;;
		"--by") by_action $2
            shift_bit=1;;
		*) incorrect_flag_error $1;;
	esac
}

short_flags_collector() {
	case $1 in
		"-r") recursive=1;;
		"-a") by_all=1 ; by_check=1;;
		"-b") by_action $2
            shift_bit=1;;
        "-ra" | "-ar") by_all=1;;
		*) incorrect_flag_error $1;;
	esac
}

# Collect files paths listed in file
by_action() {
	file_path="$1"
	file="" ; permission=""
	while IFS= read -r line; do
	   if [[ $line == "" ]]; then
			continue
	   fi
	   file=$(echo $line | awk '{print $NF}')
	   permission=$(echo $line | awk '{print $(NF-1)}' | tr -d '|')
	   entry_keys+=("$file:::$permission")
	done < <(tac "$file_path")
}

# Get input paths for restoring permissions
append_paths() {
    if [[ $by_all -eq 1 ]]; then
        for key in ${entry_keys[@]}; do
            path=$(echo $key | awk -F ':::' '{print $1}')
            mid_paths+=($path)
        done
    elif [ $recursive -eq 1 ]; then
        for element in ${entry_paths[@]}; do
            paths=$(find $element)
            mid_paths+=($paths)
        done
    else
        for element in ${entry_paths[@]}; do
            mid_paths+=($(realpath $element))
        done
    fi
}

# Get unique and sorted paths
clean_mids() {
    unique_paths=($(printf "%s\n" "${mid_paths[@]}" | awk '!seen[$0]++'))
    sorted_paths=($(printf "%s\n" "${unique_paths[@]}" | \
        awk '{print length($0), $0}' | sort -n | cut -d ' ' -f2-))
    cleaned_paths=("${sorted_paths[@]}")
}

# Restore permissions form logs file (e.g. .i9)
set_permissions() {
    for path in ${cleaned_paths[@]}; do
        status=0
        for key_tuple in ${entry_keys[@]}; do
            key_path=$(echo $key_tuple | awk -F ':::' '{print $1}')
            key=$(echo $key_tuple | awk -F ':::' '{print $2}')
            if [[ $path == $key_path ]]; then
                chmod $key $path
                status=1
                break
            fi
        done
        if [[ $status -eq 0 ]]; then
            echo "File mod bits didn't found for: $path"
        fi
    done
}

# Error handler
flags_check() {
    if [[ $any_flags -eq 0 ]]; then
	    echo "$0: Provide arguments for the 'melt' action."
	    exit 1
	fi
	if [[ $by_check -eq 0 ]]; then
	    echo "$0: Provide 'directory / files / --all' for 'melt' action."
	    exit 1
	fi
}

incorrect_flag_error() {
    echo "$1: Invalid flag."
    exit 1
}

# Valid arguments collector
entry_paths=() ; mid_paths=() ; cleaned_paths=()
entry_keys=() ; permissions=()
by_all=0 ; recursive=0 ;
any_flags=0 ; by_check=0;
shift_bit=0

# Flags collector
flag_collector "$@"

# Clear entry files
append_paths # Get input paths
# for i in ${mid_paths[@]}; do
#     echo $i
# done
clean_mids # Unique and sorted paths
flags_check # Error catcher

# Last stage
set_permissions # Restore previous permissions
