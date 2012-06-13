Version: 0.7

General Info
============

Intended for use with Arch Linux.

AFAIK there are no AUR packages for it. There are LOTS of minecraft-related AUR
packages though, so you should be O.K.

1. ``mv minecraftd /etc/rc.d/minecraftd``
2. ``mv minecraftd.conf /etc/conf.d/minecraftd``
3. ``cd {YOUR SERVER DIR} && wget
   https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar``
4. ``mkdir {YOUR BACKUP DIR}``
5. ``adduser minecraftd``
6. ``chown -R minecraftd {YOUR SERVER DIR}``
7. ``chown -R minecraftd {YOUR BACKUP DIR}``

I think that covers it. Look in the config file for sample directory locations.


Things It Will Do
=================

* Start, stop, and restart Minecraft server with usual daemon commands
* Minecraft runs inside a tmux session so you can "visit" it from the shell.
* Back up server world with ``minecraftd backup``. Backup functionality includes
  a "rolling backup" system wherein the last e.g. 5 world backups are saved.
* Send commands to the server (e.g. "ban playername") with one CLI command:
  ``minecraftd send "ban playername"``
* Runs minecraft server in whatever userspace you want.

Things It Won't Do
==================

* Have any guarantees whatsoever. Honestly. 
