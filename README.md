# cloud-dl

Bash script to manage files on owncloud via webdav. cloud-dl allows you to list, upload, download, delete, move, create and share files.

Tested in:
    
* ~~owncloud 6.07~~
* ~~owncloud 7.05~~
* ~~owncloud 8.03~~
* ~~Nextcloud 10.0.1~~
* Nextcloud 12.0.3

__Note:__ Current version of cloud-dl has been only tested in Nextcloud 12.0.3 and might not work correctly in older versions.
```
Usage: cloud-dl <options> [file|dir]
Options:
    -l/--list [dir]                 List root directory or [dir]
    -d/--download <file>            Download <file> to current location
    -u/--upload <file> [dir]        Upload <file>. Optionally uploads <file> to [dir]
    -D/--delete <file|dir>          Delete file or directory
    -k/--mkdir <dir>                Create new directory
    -M/--move <source> <target>     Move file from remote <source> to remote <target> (e.g. --move file.txt somedir/file.txt)
    -s/--share <file|dir> [-p]      Create a public share and shows the url. Optionally -p prompts for a password, -q returns only the share URL
    -L/--list-shares                List shares
    -U/--unshare <file|dir>         Delete a public share
    --configure                     Change connection configuration
    -h/--help                       Show this help
```
