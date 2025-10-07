#!/usr/bin/env python3
"""
OS-aware dotfiles manager - sync configuration files between repo and home directory.

This script automatically detects your operating system (Linux, macOS, Windows) and
manages the appropriate configuration files for your platform.
"""

import cmd
import filecmp
import json
import platform
import shutil
import subprocess
import sys
from enum import Enum
from pathlib import Path
from typing import Callable, Dict, List, Optional

# Paths
HOME_DIR: Path = Path.home()
REPO_DIR: Path = Path(__file__).parent.resolve()


class Status(Enum):
    """Operation status codes."""

    ERROR = -1
    SUCCESS = 0
    SKIP_MISSING = 1
    SKIP_IDENTICAL = 2
    PENDING = 3


class Dotfile:
    """
    Represents a config file mapping between repo and home directory.
    """

    def __init__(self, entry: Dict[str, str]):
        """Create a new DotFile instance from a configuration entry.

        Args:
            entry: Dictionary containing description, home_path, and repo_path

        Returns:
            A new DotFile instance with absolute paths
        """
        self.name: str = entry.get("name", "").strip()
        self.description: str = entry.get("description", "").strip()
        self.paths: Dict[str, Path] = {
            "home": (HOME_DIR / entry.get("home_path", "").strip())
            .expanduser()
            .resolve(),
            "repo": (REPO_DIR / entry.get("repo_path", "").strip()).resolve(),
        }

        self.exists_both = self.paths["home"].exists() and self.paths["repo"].exists()
        self.exists_home = self.paths["home"].exists()
        self.exists_repo = self.paths["repo"].exists()

        # Set diff attribute (only meaningful if both files exist)
        self.diff: bool = False
        if self.exists_both:
            self.diff = not filecmp.cmp(
                self.paths["home"], self.paths["repo"], shallow=False
            )

    def __repr__(self) -> str:
        return (
            f"Dotfile(name={self.name!r}, "
            f"Exists Repo: {self.exists_repo}, "
            f"Exists Home: {self.exists_home}, "
            f"Exists Both: {self.exists_both}, "
            f"Diff: {self.diff}, "
            f"Repo: {str(self.paths['repo'])!r}, "
            f"Home: {str(self.paths['home'])!r})"
        )

    def __str__(self) -> str:
        return (
            f"{self.name}\n"
            f"Exists Both: {self.exists_both}\n"
            f"Diff: {self.diff}\n"
            f"Repo: {str(self.paths['repo'])}\n"
            f"Home: {str(self.paths['home'])}\n"
        )


class Dotmate(cmd.Cmd):
    """Dotmate CLI interactive shell."""

    class Operation(Enum):
        """Supported operations."""

        BACKUP = "backup"
        RESTORE = "restore"
        DELETE = "delete"
        EDIT = "edit"
        DIFF = "diff"

    def __init__(self) -> None:
        super().__init__()
        self.dotfiles: Dict[str, Dotfile] = self._get_dotfiles()
        self.os_type: str = platform.system().lower()
        self.intro: str = "  DotMate CLI. Backup, restore, and manage your dotfiles.\n"
        self.intro += "  Type help or ? to list commands. Enter Ctrl+C to exit.\n\n"
        self.intro += f"  OS: {self.os_type}\n"
        self.intro += f"  Managing {len(self.dotfiles)} dotfiles.\n"
        self.intro += "-" * 80
        self.prompt: str = "> "

    def _load_paths(self) -> Dict[str, List[Dict[str, str]]]:
        """Load all dotfile paths from JSON file.

        Returns:
            dict: Dictionary with OS types as keys and lists of dotfile entries
        """
        config_file: Path = REPO_DIR / "config/dotfile_paths.json"
        try:
            with open(config_file, encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Error: Configuration file not found: {config_file}")
            sys.exit(1)
        except PermissionError:
            print(f"Error: Permission denied when accessing: {config_file}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Couldn't parse configuration file: {e}")
            sys.exit(1)

    def _get_dotfiles(self) -> Dict[str, Dotfile]:
        """Get the appropriate dotfiles configuration for the OS.

        Files are processed in priority order:
        1. Common dotfiles first (for all Unix-like systems)
        2. OS-specific dotfiles second

        Returns:
            dict: Dictionary of DotFile objects for the OS, keyed by their name
        """
        config: Dict[str, List[Dict[str, str]]] = self._load_paths()

        dotfiles: Dict[str, Dotfile] = {}
        os_type: str = platform.system().lower()

        # PRIORITY 1: Add common dotfiles first (for all Unix-like systems)
        # Windows gets minimal config, so skip common files for Windows
        if os_type != "windows":
            for entry in config.get("common", []):
                dotfiles[entry["name"]] = Dotfile(entry)
        # PRIORITY 2: Add OS-specific dotfiles after common files
        for entry in config.get(os_type, []):
            dotfiles[entry["name"]] = Dotfile(entry)

        return dotfiles

    def _prompt(self, files: List[Dotfile], message: str) -> Optional[int]:
        """Prompt the user for input and return the response as a Dotfile.

        Args:
            files: List of Dotfile objects to display
            message: The prompt message to show the user
        Returns:
            The user's choice as a Dotfile, or None if cancelled
        """
        for i, dotfile in enumerate(files, 1):
            print(f" {i}: {dotfile.name}")

        while True:
            try:
                choice: str = input(message).lower().strip()
                choice_int = int(choice)
                if not 1 <= choice_int <= len(files):
                    print(f"Invalid choice. Enter a number between 1 and {len(files)}.")
                    continue
                return choice_int - 1

            except ValueError:
                print("Invalid choice. Enter a valid number.")
                continue

            except (KeyboardInterrupt, EOFError):
                print("\nCancelled.")
                return None

    def do_exit(self, _) -> bool:
        """Exit DotMate CLI."""
        print("Exiting DotMate.")
        return True

    def do_status(self, _) -> None:
        """Show the status of all dotfiles.

        Usage:
            -> status

        Aliases:
            s, check
        """
        print("[...] Dotfiles status:")
        for i, dotfile in enumerate(self.dotfiles.values(), 1):
            if dotfile.exists_both:
                if dotfile.diff:
                    status = "diff"
                else:
                    status = "ok"
            elif dotfile.exists_repo:
                status = "repo-only"
            elif dotfile.exists_home:
                status = "home-only"
            else:
                status = "missing-both"

            left = f"{i:>2}:"
            padding = f"{dotfile.name:<25}"
            dotted = padding.replace(" ", ".")
            print(f"{left} {dotted}{status}")

    def do_list(self, arg) -> None:
        """List all managed dotfiles with their paths.

        Usage:
            -> list
            -> list <file>         - View dotfile info

        Aliases:
            ls
        """
        arg = arg.strip().lower()
        if arg:
            if arg not in self.dotfiles:
                print(f"{arg} not found in managed dotfiles\n")
                return
            print(self.dotfiles[arg])
            return

        print(f"[...] Available dotfiles for {self.os_type.capitalize()}:")
        for i, name in enumerate(self.dotfiles.keys(), 1):
            print(f" {i:>2}: {name}")

    def _get_named_files(self, file_names: List[str]) -> List[Dotfile]:
        """Get files by their names, with warnings for missing ones.

        Args:
            file_names: List of dotfile names to retrieve

        Returns:
            List of Dotfile objects corresponding to the provided names
        """
        files: List[Dotfile] = []
        for name in file_names:
            if name in self.dotfiles:
                files.append(self.dotfiles[name])
            else:
                print(f"Warning: '{name}' not found in managed dotfiles\n")

        if not files:
            print("No valid files found.\n")

        return files

    def _execute(self, files: List[Dotfile], operation: Operation) -> None:
        """Execute the specified operation and report results.

        Args:
            files: List of dotfiles to operate on
            operation: Either 'backup', 'restore', or 'delete'
        """
        success_count = skip_count = 0

        # Map operation to function
        try:
            operation_func: Callable[..., Status] = {
                self.Operation.BACKUP: backup,
                self.Operation.RESTORE: restore,
                self.Operation.DELETE: delete,
            }[operation]
        except KeyError:
            print(f"Error: Unknown operation '{operation}'")
            return

        for dotfile in files:
            result: Status = operation_func(dotfile)
            if result == Status.SUCCESS:
                success_count += 1
            elif result in [Status.SKIP_MISSING, Status.SKIP_IDENTICAL]:
                skip_count += 1

        print(f"{operation.value}... {success_count} files, {skip_count} skipped.")

    def _get_files(self, operation: Operation) -> List[Dotfile]:
        """Show files with differences and let user select one.

        Args:
            operation: Operation enum to determine filtering logic
        Returns:
            List of selected Dotfile objects
        """

        def filter_cond(f: Dotfile) -> bool:
            if operation == self.Operation.BACKUP:
                return f.exists_home and (not f.exists_repo or f.diff)

            if operation == self.Operation.RESTORE:
                return f.exists_repo and (not f.exists_home or f.diff)

            if operation == self.Operation.DELETE:
                # only show files that exist in home
                # To delete/update on repo, do_backup
                return f.exists_home

            if operation in [self.Operation.EDIT, self.Operation.DIFF]:
                return f.exists_both and f.diff

            return False

        diff_files: List[Dotfile] = [
            f for f in self.dotfiles.values() if filter_cond(f)
        ]

        if not diff_files:
            print(f"No files found to {operation.value}.")
            return []

        # prompt returns -1 aligned index
        selection: Optional[int] = self._prompt(
            diff_files, f"Enter file number to {operation.value}: "
        )
        if selection is None:
            return []

        return [diff_files[selection]]

    def do_restore(self, arg: str) -> None:
        """Restore configuration files from repo to home directory.
        Usage:
            -> restore           - List diff files and select interactively
            -> restore --all     - Restore all dotfiles
            -> restore <name>    - Restore specific dotfile by name
        """
        restore_files: List[Dotfile] = []
        arg = arg.strip().lower()
        if arg == "--all":
            print("Restoring... all dotfiles from repo to home directory")
            restore_files = [f for f in self.dotfiles.values() if f.exists_repo]

        elif arg == "":
            restore_files = self._get_files(self.Operation.RESTORE)

        else:
            restore_files = self._get_named_files(arg.split())

        if not restore_files:
            print(f"No files found to {self.Operation.RESTORE.value}.")
            return

        print(f"Restoring {len(restore_files)} files...")
        self._execute(restore_files, self.Operation.RESTORE)

    def do_backup(self, arg: str) -> None:
        """Collect configuration files from home directory to repo.
        Usage:
            -> backup           - List diff files and select interactively
            -> backup --all     - Back up all dotfiles
            -> backup <name>    - Back up specific dotfile by name
        """
        backup_files: List[Dotfile]
        arg = arg.strip().lower()
        if arg == "--all":
            print("Backing up... all dotfiles from home directory to repo")
            backup_files = [f for f in self.dotfiles.values() if f.exists_home]

        elif arg == "":
            backup_files = self._get_files(self.Operation.BACKUP)
        else:
            backup_files = self._get_named_files(arg.split())

        if not backup_files:
            print(f"No files found to {self.Operation.BACKUP.value}.")
            return

        print(f"Backing up {len(backup_files)} files...")
        self._execute(backup_files, self.Operation.BACKUP)

    def do_delete(self, arg: str) -> None:
        """Delete configuration files from home directory.

        Usage:
            -> delete           - List diff files and select interactively
            -> delete --all     - Delete all dotfiles from home directory
            -> delete <name>    - Delete specific dotfile by name
        """
        arg = arg.strip().lower()
        if arg == "--all":
            print("Deleting... all dotfiles from home directory")
            delete_files: List[Dotfile] = [
                f for f in self.dotfiles.values() if f.exists_home
            ]

        elif arg == "":
            delete_files = self._get_files(self.Operation.DELETE)
            if not delete_files:
                return

        else:
            delete_files = self._get_named_files(arg.split())
            if not delete_files:
                print(f"No files found to {self.Operation.DELETE.value}.")
                return

        self._execute(delete_files, self.Operation.DELETE)

    def do_diff(self, arg: str) -> None:
        """Show differences between repo and home files.

        Usage:
            -  diff             - interactively select a file to diff
            -> diff <file>      - Show diff for a specific file
        """
        file: Optional[Dotfile] = None
        if arg:
            file_name = arg.strip()
            if file_name not in self.dotfiles:
                print(f"'{file_name}' not found in managed dotfiles\n")
                return

            file = self.dotfiles[file_name]
            if not file.exists_both:
                print(f"Error: '{file_name}' does not exist in both repo and home\n")
                return
            if not file.diff:
                print(f"'{file_name}' files are identical, no differences to show\n")
                return
        else:
            diff_files: List[Dotfile] = self._get_files(self.Operation.DIFF)
            if not diff_files:
                print("No differences found between repo and home files!")
                return

            file = diff_files[0]

        show_diffs(file)

    def do_edit(self, arg: str) -> None:
        """Open repo and home versions of dotfiles in Vim vertical split.

        Usage:
            -> edit             - interactively select a file to edit
            -> edit <file>      - Edit a specific file
        """
        file: Optional[Dotfile] = None
        if arg:
            file_name: str = arg.strip()
            if file_name not in self.dotfiles:
                print(f"'{file_name}' not found in managed dotfiles\n")
                return

            file = self.dotfiles[file_name]
            if not file.exists_both:
                print(f"Error: '{file_name}' does not exist in both repo and home\n")
                return
            if not file.diff:
                print(f"'{file_name}' files are identical, no differences to show\n")
                return
        else:
            diff_files: List[Dotfile] = self._get_files(self.Operation.DIFF)

            if not diff_files:
                print("No differences found between repo and home files!")
                return

            file = diff_files[0]

        split_edit(file)

    def do_EOF(self, _) -> bool:  # pylint: disable=invalid-name
        """Exit the interactive shell."""
        print("exit.")
        return True


def restore(dotfile: Dotfile) -> Status:
    """Restore a single dotfile from repo to home directory.

    Args:
        dotfile: The DotFile instance to restore

    Returns:
        str: 'success', 'skip_missing', 'skip_identical', or 'error'
    """
    if not dotfile.exists_repo:
        print(f"Skipping... {dotfile.paths['repo']} (doesn't exist in repo)")
        return Status.SKIP_MISSING

    if not dotfile.diff:
        print(f"Skipping... {dotfile.paths['home']} (files are identical)")
        return Status.SKIP_IDENTICAL

    try:
        # Ensure parent directory exists
        dotfile.paths["home"].parent.mkdir(parents=True, exist_ok=True)

        # Copy file from repo to home
        shutil.copy2(dotfile.paths["repo"], dotfile.paths["home"])

        print(f"Restored... ({dotfile.name}) from repo -> home")
        return Status.SUCCESS

    except (PermissionError, FileNotFoundError, IOError) as e:
        print(f"Error... Failed to restore: \n  {dotfile.paths['repo']}: {e}")
        return Status.ERROR


def backup(dotfile: Dotfile) -> Status:
    """Backup a single dotfile from home to repo directory.

    Args:
        dotfile: The DotFile instance to backup

    Returns:
        Status: The status of the backup operation
    """
    if not dotfile.exists_home:
        print(f"Skipping... {dotfile.paths['home']} (doesn't exist in home)")
        return Status.SKIP_MISSING

    if not dotfile.diff:
        print(f"Skipping... {dotfile.paths['repo']} (files are identical)")
        return Status.SKIP_IDENTICAL

    try:
        # Ensure parent directory exists
        dotfile.paths["repo"].parent.mkdir(parents=True, exist_ok=True)

        # Copy file from home to repo
        shutil.copy2(dotfile.paths["home"], dotfile.paths["repo"])

        print(f"Backed Up... {dotfile.paths['home']} from home -> repo")
        return Status.SUCCESS

    except (PermissionError, FileNotFoundError, IOError) as e:
        print(f"Error... failed to backup: \n  {dotfile.paths['repo']}: {e}")
        return Status.ERROR


def delete(dotfile: Dotfile) -> Status:
    """Delete a single dotfile from home directory.

    Args:
        dotfile: The DotFile instance to delete from home directory

    Returns:
        Status: The result of the delete operation.
    """
    if not dotfile.exists_home:
        print(f"Skipping... {dotfile.paths['home']} (doesn't exist in home)")
        return Status.SKIP_MISSING

    try:
        # Remove this file or link. If the path is a directory, use rmdir() instead.
        dotfile.paths["home"].unlink()

        print(f"Deleted... {dotfile.paths['home']}")
        return Status.SUCCESS

    except (PermissionError, FileNotFoundError, IOError) as e:
        print(f"Error: Failed to delete: \n  {dotfile.paths['home']}: {e}")
        return Status.ERROR


def show_diffs(file: Dotfile) -> None:
    """Show differences between repo and home versions of a dotfile using 'diff' command.

    Args:
        file: The DotFile instance to show differences for
    """
    try:
        repo_path = str(file.paths["repo"])
        home_path = str(file.paths["home"])

        diff_command: List[str] = [
            "diff",
            "-u",
            "--color=always",
            repo_path,
            home_path,
        ]

        # check=False to avoid raising exception on non-zero exit codes
        # For example if user exits with an error
        subprocess.run(diff_command, check=False)

    except FileNotFoundError:
        print("Error: diff command not found. Please make sure diff is installed")
    except (IOError, subprocess.SubprocessError, OSError) as e:
        print(f"Error opening diff: {e}")


def split_edit(file: Dotfile) -> None:
    """Open repo and home versions of dotfiles in Vim vertical split.

    Provides an interactive menu to select a file and opens both the repo
    and home versions side by side in Vim for easy comparison and editing.
    """
    try:
        repo_path = str(file.paths["repo"])
        home_path = str(file.paths["home"])

        vim_command: List[str] = [
            "vim",
            "-O",
            repo_path,
            home_path,
        ]
        # check=False to avoid raising exception on non-zero exit codes
        # For example if user exits vim with an error
        subprocess.run(vim_command, check=False)

    except FileNotFoundError:
        print("Error: vim not found. Please make sure vim is installed")
    except (IOError, subprocess.SubprocessError, OSError) as e:
        print(f"Error opening vim: {e}")


def main() -> None:
    """Main entry point - parse command and execute action.

    Processes command line arguments and calls the appropriate function.
    """
    try:
        Dotmate().cmdloop()

    except (KeyboardInterrupt, EOFError):
        print("exit.")


if __name__ == "__main__":
    main()
