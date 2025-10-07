# Development Environment Setup

This repository contains scripts and configuration files to set up a development environment for macOS. It's tailored for software development, focusing on a clean, minimal, and efficient dotmate.

## Dotfiles Manager

A simple and intuitive Python script to manage your dotfiles between your repository and home directory.

## Features

- **Restore**: Copy config file(s) from repo to home directory
- **Backup**: Copy config file(s) from home directory back to repo
- **Delete**: Delete config file(s) from home directory
- **Status**: Show which files exist where and their sync status
- **Diff**: Show differences between repo and home versions
- **Safety**: Confirmation prompts before overwriting file(s)

## Quick Start

1. Clone the repo and cd into the repo

    ```bash
    git clone git@github.com:knealking/dotfiles.git && cd dotfiles
    ```

2. Add your configs to the `config/`

3. Allow permissions

    ```bash
    # Make the script executable
    chmod u+x dotmate.py
    ```

4. Run the script

    ```bash
    ./dotmate.py
    ```

5. Manage through the interactive shell

    ```bash
    ❯ python3 dotmate.py
    DotMate CLI. Backup, restore, and manage your dotfiles.
    Type help or ? to list commands. Enter Ctrl+C to exit.

    OS: <platform type>
    Managing <#> dotfiles.
    --------------------------------------------------------------------------------
    > ?

    Documented commands (type help <topic>):
    ========================================
    EOF  backup  delete  diff  edit  exit  help  list  restore  status

    >

    ```

## Commands

| Command     | Description                                |
|------------ |--------------------------------------------|
| `help` / `?`| Show help message                          |
| `list`      | Show a list of managed dotfiles            |
| `status`    | Show sync status of all files              |
| `restore`   | Copy config file(s) from repo → home       |
| `backup`    | Copy config file(s) from home → repo       |
| `diff`      | Show file differences                      |
| `edit`      | Edit repo and home files in vertical split |
| `delete`    | Delete config file(s) from home directory  |

## Options

- `--all`: Skip selection prompts (use with caution)

## Status Indicators

- `ok...`           Files are identical
- `diff...`         Files differ (need syncing)
- `repo only...`    Only exists in repo
- `home only...`    Only exists in home directory
- `missing...`      Missing from both locations

## Managed Dotfiles

The following dotfiles are managed by DotMate:

[dotfile_paths.json](config/dotfile_paths.json)

## Adding New Dotfiles

Edit the `dotfile_paths.json`:

`home_path` : relative path to home
`repo_path` : relative path to repo

```json
"common": [
    {
        "name": "example",
        "description": "Example configuration",
        "home_path": ".example",
        "repo_path": "config/example"
    }
]
```

## Safety Features

- Confirmation prompts before overwriting files
- Error handling for missing files or directories
- Automatic directory creation
- Clear status indicators and helpful messages

Enjoy organized dotfiles! 🎉
