#!/usr/bin/env python3

"""A simple dotfiles manager that uses symlinks to manage dotfiles in a git repository."""

import argparse
import logging
import os
import sys
from pathlib import Path, PurePosixPath

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

GREEN = "\033[92m"
RED = "\033[91m"
BLUE = "\033[94m"
RESET = "\033[0m"


def detect_os():
    """Detect the operating system."""

    this_os = None

    if sys.platform.startswith("linux"):
        this_os = "Linux"
    elif sys.platform == "darwin":
        this_os = "macOS"
    elif sys.platform == "win32":
        this_os = "Windows"
    else:
        this_os = "Unknown"

    return this_os


OS_TYPE = detect_os()


def get_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Manage dotfiles with symlinks.")
    parser.add_argument(
        "--source",
        "-s",
        type=Path,
        default=Path("."),
        help="Source directory for dotfiles.",
    )

    parser.add_argument(
        "--target",
        "-t",
        type=Path,
        default=Path.home(),
        help="Target directory for symlinks.",
    )

    parser.add_argument(
        "--ignore",
        "-i",
        type=Path,
        default=Path(".stow-local-ignore"),
        help="File containing a list of files to ignore.",
    )

    parser.add_argument(
        "--adopt",
        "-a",
        action="store_true",
        help="Adopt existing files as symlinks.",
    )

    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output.",
    )

    if parser.parse_args().verbose:
        logger.setLevel(logging.DEBUG)

    return parser.parse_args()


def print_list(title: str, items: list):
    """Print a list of items with a title."""
    logger.debug(f"{title}:")
    for item in items:
        logger.debug(f"  {item}")


def get_ignore_list(ignore_file: Path):
    """Read the ignore file and return a list of files to ignore."""
    if not ignore_file.exists():
        return []

    with open(ignore_file, "r", encoding="utf-8") as file:
        ignore_list = [
            line.strip() for line in file if line.strip() and not line.startswith("#")
        ]
    return ignore_list


def create_symlink(source: Path, target: Path, force: bool = False):
    """Create a symbolic link from source to target."""
    try:
        if force and target.exists():
            if target.is_symlink() or target.is_file():
                target.unlink()
            elif target.is_dir():
                target.rmdir()

        target.parent.mkdir(parents=True, exist_ok=True)
        os.symlink(source.resolve(), target)
        print(f"  {GREEN}{target} -> {source}{RESET}")

    except FileExistsError:
        print(f"  {RED}Symlink already exists: {target}{RESET}")
    except OSError as e:
        print(f"  {RED}Error creating symlink: {e}{RESET}")


def skip_path(path: Path, ignore_list: list) -> bool:
    """Return True if a path should be skipped based on the ignore list."""
    if not ignore_list:
        return False

    normalized_path = PurePosixPath(path.as_posix())

    for entry in ignore_list:
        ignore_path = PurePosixPath(entry.rstrip("/"))
        if normalized_path == ignore_path:
            return True

        try:
            if normalized_path.is_relative_to(ignore_path):
                return True
        except ValueError:
            pass

    return False


def discover_dotfiles(source: Path, ignore_list: list) -> list[Path]:
    """Discover dotfiles while skipping ignored paths."""
    dotfiles = []

    for entry in source.iterdir():
        if entry.name == ".config" and entry.is_dir():
            for child in entry.iterdir():
                if child.is_dir() and not skip_path(
                    child.relative_to(source), ignore_list
                ):
                    dotfiles.append(child)
            continue

        if skip_path(entry.relative_to(source), ignore_list):
            continue

        if entry.is_file() or entry.is_dir():
            dotfiles.append(entry)

    return dotfiles


def dotmate(os_type: str, args: argparse.Namespace, ignore_list: list):
    """Main function to manage dotfiles."""
    if not args.source.exists():
        print(f"Source does not exist: {args.source}")
        return

    match os_type:
        case "Linux" | "macOS":
            print(f"{GREEN}Detected OS: {os_type}{RESET}")

            try:
                dotfiles = discover_dotfiles(args.source, ignore_list)

                print(f"Found {len(dotfiles)} dotfiles in {args.source}")
                dotfile_names = [
                    dotfile.relative_to(args.source).as_posix() for dotfile in dotfiles
                ]
                print_list("Dotfiles", dotfile_names)
                print_list("Ignore list", ignore_list)

                for dotfile in dotfiles:
                    relative_path = dotfile.relative_to(args.source)
                    target_path = args.target / relative_path
                    create_symlink(dotfile, target_path)

            except OSError as e:
                print(f"Error creating symlink: {e}")

        case "Windows":
            print("Windows is not fully supported yet.")
        case _:
            print(f"Unsupported OS: {os_type}")


def main():
    """Main function to manage dotfiles."""

    args = get_args()
    ignore_list = get_ignore_list(args.ignore)
    dotmate(OS_TYPE, args, ignore_list)


if __name__ == "__main__":
    main()
