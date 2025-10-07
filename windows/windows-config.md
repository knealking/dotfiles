# Windows Config

- [Windows Config](#windows-config)
  - [Basics](#basics)
  - [Security](#security)
  - [Registry hacks](#registry-hacks)

## Basics

Windows command prompt may be useful in some cases, but let's be honest: no one uses that. We can improve this by the following, but make sure to create a restore point before doing these:

1. [Install WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
2. Install [Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/install)
3. Make bash default in Windows Terminal:
   - Open Windows Terminal
   - Open settings
   - Find and copy the Linux distro guild ID
   - Paste it in `defaultProfile`
   - Restart Windows Terminal
4. Install oh-my-zsh via the curl command

   ```zsh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

   or from the official GitHub repository [oh my zsh](https://github.com/ohmyzsh/ohmyzsh)

5. Change your default shell to zsh

   ```zsh
   chsh -s $(which zsh)
   ```

## Security

There are a lot of free antivirus software available, but the one that has a pretty good track record is Bitdefender. Windows, on its own, does not focus on user privacy. So we need to disable some stuff. Instead of going through hundreds of registry changes, we can use a program called Spybot Anti-Beacon, which does this for us.

1. Download [Bitdefender](https://www.bitdefender.com/solutions/free.html) for free
2. Download [Portable Spybot Anti-Beacon](https://download.spybot.info/AntiBeacon/Portable/) linked is the  official safer network page; the latest version is at the bottom

## Registry hacks

1. Add apps to the desktop context menu
   - Open Registry Editor and go to the following path: `Computer\HKEY_CLASSES_ROOT\Directory\Background\shell`
   - Create a new key under the shell folder, name it whatever app you want,
   - Create another key under that folder and name it command.
   - Find the app's exe file, hold the shift key, right-click, and copy it as the path.
   - Paste the path in default.

2. Disable Cortana
   - Open Registry Editor and go to the following path: `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows`
   - Within Windows, create a new key named "Windows Search".
   - In Windows Search create a new DWORD(32-bit) named, "AllowCortana"
   - Set the value equal to '0'
   - Restart

3. Disable Bing
   - Open Registry Editor and go to the following path: `Computer\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search`
   - Create a new DWORD(32-bit) under search named, "BingSearchEnabled"
   - Set the value equal to '0'
   - Log Off and log back in

4. Delete the 3D Objects folder
   - Open Registry Editor and go to the following path: `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace`
   - Find "{0DB7E03F-FC29-4DC6-9020-FE41B59E513A}"
   - Delete the key

5. Disable Lock Screen
   - Open Registry Editor and go to the following path: `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization`
   - Create a new key under Windows, "Personalization."
   - Create a new DWORD(32-bit) value, rename it "NoLockScreen"
   - Set the value to '1'
   - Log Off and log back in
