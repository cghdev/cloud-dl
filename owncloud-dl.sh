#!/bin/bash

conf="$HOME/.owncloud"

list(){
    dir=$(echo $1 | sed 's/ /%20/g')
    res=$(curl $options -X PROPFIND $url/$dir 2>/dev/null)
    [ $? -gt 0 ] && echo "* Error listing files" && exit
    if [ "$platform" == "Linux" ];then
        quota=$(($(echo "$res" | grep -oPm1 "(?<=<d:quota-available-bytes>)[^<]+" | uniq)/(1024*1024)))
        echo -en "\t\t\t[Quota available: "$quota"MB]\n\n"
        echo "$res" | grep -oPm1 "(?<=<d:href>)[^<]+" | sed -e "s|/$path||g" -e 's/%20/ /g'
    else
        quota=$(($(parse_xml "$res" "d:quota-available-bytes" | uniq)/(1024*1024)))
        echo -en "\t\t\t[Quota available: "$quota"MB]\n\n"
        parse_xml "$res" "d:href" | sed -e "s|/$path||g" -e 's/%20/ /g'
    fi
}

download(){
    [ -z "$1" ] && echo "* Error. No file specified" && exit
    fname=$(basename "$1")
    pname=$(echo $1 | sed 's/ /%20/g')
    if [ $(exists $pname) == 1 ];then
        echo "> Downloading $fname..."
        curl --progress-bar -o "$fname" $options -X GET $url/$pname
        [ $? -gt 0 ] && echo "* Error downloading the file" || echo "> Done"
    else
        echo "* File does not exist"
    fi
}

upload(){
    [ -z "$1" ] && echo "* Error. No file specified" && exit
    file=$(echo $1 | sed 's/ /%20/g')
    bname=$(basename "$file")
    if [ -f "$1" ];then
        echo "> Uploading '$1'..."
        curl $options -T "$1" $url/$2/$bname 2>/dev/null
        [ $? -eq 0 ] && echo "> Done" || echo "* Error uploading the file. Verify target directory exists"
    else
        echo "* File '$1' not found"
    fi
}

delete(){
    [ -z "$1" ] && echo "* Error. No file specified" && exit
    read -p "Are you sure you want to delete '$1'? (y/n): " response
    [ "$response" != "y" ] && exit
    file=$(echo $1 | sed 's/ /%20/g')
    echo "> Deleting '$1'..."
    curl $options -X DELETE $url/$file 2>/dev/null
    [ $? -eq 0 ] && echo "> Done" || echo "* There was an error deleting '$1'"
}

_mkdir(){
    [ -z "$1" ] && echo "* Error. No directory specified" && exit
    file=$(echo $1 | sed 's/ /%20/g')
    curl $options -X MKCOL $url/$file 2>/dev/null
    [ $? -eq 0 ] && echo "> Done" || echo "* Unable to create directory"
}

_mv(){
    [ -z "$1" ] && echo "* Error. No file specified" && exit
    [ -z "$2" ] && echo "* Error. You must specify destination" && exit
    source=$(echo $1 | sed 's/ /%20/g')
    target=$(echo $2 | sed 's/ /%20/g')
    curl $options -X MOVE $url/$source --header "Destination: $url/$target" 2>/dev/null
    [ $? -eq 0 ] && echo "> Done" || echo "* Unable to rename file"
}

exists(){ # if exists and is a file
    res=$(curl $options -X PROPFIND $url/$1 2>/dev/null) 
    if [ $? -gt 0 ];then
        echo 0
    else
        [ "$platform" == "Linux" ] && val=$(echo $res | grep -oPm1 "(?<=<d:href>)[^<]+" | head -1) || val=$(parse_xml "$res" "d:href" | head -1)
        [ "${val: -1}" == "/" ] && echo 0 || echo 1
    fi
}

parse_args(){
    [ "$#" == "0" ] && usage && exit
    while [[ $# > 0 ]];do
        opt="$1"
        case $opt in
            -d|--download)  download "$2"
            shift
            ;;
            -l|--list)      list "$2"
            shift
            ;;
            -u|--upload)    upload "$2" "$3"; exit
            shift
            ;;
            -D|--delete)    delete "$2"
            shift
            ;;
            -k|--mkdir)     _mkdir "$2"
            shift
            ;;
            -M|--move)      _mv "$2" "$3"; exit
            shift
            ;;
            -h|--help)      usage; exit
            ;;
            *)              echo -en "Unknown option '$opt'\n\n" && usage && exit
        esac
        shift
        done
}

usage(){
    echo "Usage: $0 <options> [file|dir]"
    echo "Options:"
    echo "   -l/--list [dir]                 List root directory or [dir]"
    echo "   -d/--download <file>            Download <file> to current location"
    echo "   -u/--upload <file> [dir]        Upload <file>. Optionally uploads <file> to [dir]"
    echo "   -D/--delete <file|dir>          Delete file or directory"
    echo "   -k/--mkdir <dir>                Create new directory"
    echo "   -M/--move <source> <target>     Move file from remote <source> to remote <target> (e.g. --move file.txt somedir/file.txt)"
    echo "   -h/--help                       Show this help"
    echo
}
read_dom(){
    local IFS=\>
    read -d \< ENTITY CONTENT
}

parse_xml(){
    echo "$1" | while read_dom; do
        [ "$ENTITY" == "$2" ] && echo $CONTENT
    done
}
create_conf(){
    echo "> Creating new config file:"
    read -p "  Username: " username
    read -s -p "  Password: " password; echo
    read -p "  Hostname: " host
    read -p "  Protocol [https]: " protocol
    read -p "  Port [443]: " port
    [ "$protocol" == "http" ] || read -p "  Trust certificate [yes]: " trust_cert
    read -p "  Webdav path [remote.php/webdav]: " path
    [ -z $protocol ] && protocol="https";[ -z $port ] && port="443";[ -z $trust ] && trust="yes";[ -z $path ] && path="remote.php/webdav"
    echo -en "username=$username\npassword=$password\nhost=$host\nprotocol=$protocol\nport=$port\ntrust_cert=$trust_cert\npath=$path\n" > $conf && chmod 600 $config
}
depCheck(){
    for b in curl grep sed basename ;do
        which $b &>/dev/null
            [ $? != 0 ] && echo "* Some dependencies are missing ($b)" && exit
    done
    [ ! -f "$conf" ] && echo "* Config file not found" && create_conf && exit
}


depCheck
platform=$(uname)

for l in $(cat $conf); do [ "${l::1}" != "#" ] && export $l; done
[ "$trust_cert" == "yes" ] && trust="-k" || trust=''
options="-f $trust --user $username:$password"
url=$protocol://$host:$port/$path

parse_args "$@"
