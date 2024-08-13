# Ice Nine
Ice IX is a command-line toolset for managing file and directory permissions. It allows you to "freeze" permissions by saving them to a mapping file, and later "melt" them to restore the original settings. With options for recursive operations and directory inclusion, ice nine provides a simple way to revert permissions across your file system.
## Modes of Operation
### 1. **Freeze**

This mod captures the current permissions of specified files and directories, storing them in a mapping file. Mod also adds permissions set in config file (ice-nine).

| Flag | Long Form       | Description                                      |
|------|-----------------|--------------------------------------------------|
| `-a` | `--appendto`    | Adds files to the mapping file.                  |
| `-b` | `--by`          | Appends the mapping file with listed paths.      |
| `-d` | `--directories` | Includes directories for quarantine.             |
| `-r` | `--recursive`   | Appends directories and their files recursively. |

#### Examples
* Freezes permissions for all files and directories ***(-d)*** in *some/directory/with/files/* recursively ***(-r)*** and appends the data to mappingfile ***(-a)***.
```Bash
iceix *freeze -rd some/directory/with/files/ --appendto mappingfile
```
* Freezes permissions for files listed ***(-b)*** in *listfile.txt* and appends ***(-a)*** the data to *mappingfile*.
```Bash
iceix *freeze --by listfile.txt --appendto mappingfile
```
* Freezes permissions for all files in the current directory (*) and appends ***(-a)*** the data to *mappingfile*.
```Bash
iceix *freeze * --appendto mappingfile
```

### 2. **Melt**

This mod restores the permissions of files and directories based on the data stored in the mapping file created by *freeze.
These commands help you preserve file permissions and restore them later, ensuring consistency across different sessions, deployments, or system states.

| Flag | Long Form       | Description                                       |
|------|-----------------|---------------------------------------------------|
| `-b` | `--by`          | Reverses permissions using the mapping file.      |
| `-a` | `--all`         | Runs the mod for all log files.                   |
| `-r` | `--recursive`   | Reverses directories and their files recursively. |

#### Examples
* Restores permissions for all ***(-a)*** files and directories listed ***(-b)*** in *mappingfile*.
```Bash
iceix *melt --all --by mappingfile
```
* Restores permissions recursively ***(-r)*** for all files in *some/directory/* based on *mappingfile* ***(-b)***.
```Bash
iceix *melt --recursive some/directory/ --by mappingfile
```
* Restores permissions for *some/file* based on *mappingfile* ***(-b)***.
```Bash
iceix *melt some/file --by mappingfile
```
### 3. **Config** 
This mod displays base permissions for *freeze action.
```Bash
iceix *config # FILE_QUARANTINE_MOD=000 DIRECTORY_QUARANTINE_MOD=700
```
## Important Note
* It is crucial to add the configuration file **ice-nine** to **~/.config/** or modify the *CONFIG_FILE* constant in the **i9-freeze.sh** script to match the location of the configuration file.
## Installation
Scripts can be used directly without special intervention (after setting config file (**Important Notes** section)) in file placement, but to improve usability and provide global access, it is recommended to follow these installation steps: 
1. Move the main script **iceix.sh** to **/usr/bin**.
2. Remove the **.sh** extension.
3. Set the executable permissions.
4. Ensure that the *SCRIPTS_DIR* constant is updated to correctly locate the path to the program's mod files (**i9-freeze.sh** and **i9-melt.sh**).

After installation, Ice IX will be readily accessible from any terminal session, allowing for easy management of file and directory permissions.
