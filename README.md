# Dotfiles

OS-specific dotfiles are stored in separate branches. Switch to the branch matching your OS to get the relevant configs.

## Usage

Clone the repo:

```sh
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
   ```

Switch to OS branch and apply configuration files.

MacOS:

```sh
git switch macos
```

Linux:

```sh
git switch linux
```

Windows:

```sh
git switch windows
```

Apply the dotfiles (e.g. symlink or copy them):

```sh
# Example: symlink configs to your home directory
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
```
