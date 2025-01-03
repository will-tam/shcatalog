# README

**shcatalog.sh** : only bash text-based interactive media catalog.

Create a list of files within a media as CD, hard drive, USB key, ... to easily find some wanted files on it.

_Will_tam_  - **ver 202501-03**


Choice to use dialog lib instead of whiptail : the venerable dialog has more feature than the other.

-----

# CHANGELOG

  * 2025-01-03 : Check if a given media db name already exists.

  * 2025-01-01 : Read inside a db file, and remove a db file

  * 2024-12-29 : Internationnalization : French, Japanses and C(English)

  * 2024-12-27 : Install script

  * 2024-12-22 : Begin of script writing

-----

# INSTALL

2 ways :

  * For any user :
    * Become **root**
    * Just run **_./install.sh_** script
    * The script **_shcatalog.sh_** will be install in **_/usr/local/bin_**
    * The languages's files **_*.UTF-8_** will be installed in **_/usr/local/etc/shcatalog_LANG_**

  * In a special directory, for example** _my_dir_name_** :
    * Become **root** if the directory is not your own directory.
    * Run **_./install.sh my_dir_name_**
    * The script **_shcatalog.sh_** will be install in **_my_dir_name_**
    * The languages's files **_*.UTF-8_** will be installed in **_my_dir_name/LANG_**

-----

# USING DIRECTORIES AND FILES

  * Main directories and files : see **INSTALL**
  * **${HOME}/.config/shcatalog** : **_dbconf_**. Backup files **_dbconf.bak.*_** are also created along using script.
  * **${HOME}/.local/share/shcatalog** : **_mlocate_** database files created by script.

-----

# LICENSE

**Dialog** library license

-----

# TODO

[X] Internationnalisation
[X] Read inside a db file ?
[X] Remove a db file ?
[X] Check if a db file already exist ?
[ ] Nonintereactive to be used by other scripts ?
[ ] Unused variables clean up shell-script !!!
