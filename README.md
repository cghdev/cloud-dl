# owncloud-dl

Bash script to manage files on owncloud via webdav. owncloud-dl allows list, upload, download, delete, move and create dirs.

Tested in:
    
* owncloud 6.07
* owncloud 7.05
* owncloud 8.03



    Usage: owncloud-dl.sh <options> [file|dir]
    Options:
        -l/--list [dir]                 List root directory or [dir]
        -d/--download <file>            Download <file> to current location
        -u/--upload <file> [dir]        Upload <file>. Optionally uploads <file> to [dir]
        -D/--delete <file|dir>          Delete file or directory
        -k/--mkdir <dir>                Create new directory
        -M/--move <source> <target>     Move file from remote <source> to remote <target> (e.g. --move file.txt somedir/file.txt)
        -h/--help                       Show this help
