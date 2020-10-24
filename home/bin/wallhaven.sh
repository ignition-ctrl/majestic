#!/bin/bash
#
# This script gets the beautiful wallpapers from http://wallhaven.cc
# This script is brought to you by MacEarl and is based on the
# script for wallbase.cc (https://github.com/sevensins/Wallbase-Downloader)
#
# This Script is written for GNU Linux, it should work under Mac OS

REVISION=0.2.5

#####################################
###   Needed for NSFW/Favorites   ###
#####################################
# Enter your API key
# you can get it here: https://wallhaven.cc/settings/account
APIKEY=""
#####################################
### End needed for NSFW/Favorites ###
#####################################

#####################################
###     Configuration Options     ###
#####################################
# Where should the Wallpapers be stored?
LOCATION=${HOME}/img/wallhaven
# How many Wallpapers should be downloaded, should be multiples of the
# value in the THUMBS Variable
WPNUMBER=48
# What page to start downloading at, default and minimum of 1.
STARTPAGE=1
# Type standard (newest, oldest, random, hits, mostfav), search, collections
# (for now only the default collection), useruploads (if selected, only
# FILTER variable will change the outcome)
TYPE=standard
# From which Categories should Wallpapers be downloaded, first number is
# for General, second for Anime, third for People, 1 to enable category,
# 0 to disable it
CATEGORIES=100
# filter wallpapers before downloading, first number is for sfw content,
# second for sketchy content, third for nsfw content, 1 to enable,
# 0 to disable
FILTER=110
# Which Resolutions should be downloaded, leave empty for all (most common
# resolutions possible, for details see wallhaven site), separate multiple
# resolutions with , eg. 1920x1080,1920x1200
RESOLUTION="1920x1080"
# alternatively specify a minimum resolution, please note that specifying
# both resolutions and a minimum resolution will result in the desired
# resolutions being ignored, to avoid unwanted behavior only set one of the
# two options and leave the other blank
ATLEAST=
# Which aspectratios should be downloaded, leave empty for all (possible
# values: 4x3, 5x4, 16x9, 16x10, 21x9, 32x9, 48x9, 9x16, 10x16), separate mutliple ratios
# with , eg. 4x3,16x9
ASPECTRATIO="16x9"
# Which Type should be displayed (relevance, random, date_added, views,
# favorites, toplist, toplist-beta)
MODE=random
# if MODE is set to toplist show the toplist for the given timeframe
# possible values: 1d (last day), 3d (last 3 days), 1w (last week),
# 1M (last month), 3M (last 3 months), 6M (last 6 months), 1y (last year)
TOPRANGE=
# How should the wallpapers be ordered (desc, asc)
ORDER=desc
# Collections, only used if TYPE = collections
# specify the name of the collection you want to download
# Default is the default collection name on wallhaven
# If you want to download your own Collections make sure USR is set to your username
# If you want to download someone elses public collection enter the name here
# and the username under USR
# Please note that the only filter option applied to Collections is the Number
# of Wallpapers to download, there is no filter for resolution, purity, ...
COLLECTION="Default"
# Searchterm, only used if TYPE = search
# you can also search by tags, use id:TAGID
# to get the tag id take a look at: https://wallhaven.cc/tags/
# for example: to search for nature related wallpapers via the nature tag
# instead of the keyword use QUERY="id:37"
QUERY=""
# Search images containing color
# values are RGB (000000 = black, ffffff = white, ff0000 = red, ...)
COLOR=""
# Should the search results be saved to a separate subfolder?
# 0 for no separate folder, 1 for separate subfolder
SUBFOLDER=0

# User from which wallpapers should be downloaded
# used for TYPE=useruploads and TYPE=collections
# If you want to download your own Collection this has to be set to your username
USR="AksumkA"

# custom thumbnails per page
# changeable here: https://wallhaven.cc/settings/browsing
# valid values: 24, 32, 64
# if set to 32 or 64 you need to provide an api key
THUMBS=24
#####################################
###   End Configuration Options   ###
#####################################

#function checkDependencies {
# dependencies=(wget jq sed)

# sets the authentication header/API key to give the user more functionality
# requires 1 arguments:
# arg1: API key
function setAPIkeyHeader {
    httpHeader="X-API-Key: $APIKEY"
} # /setAPIkeyHeader

# downloads Page with Thumbnails
function getPage {
    WGET -O tmp "https://wallhaven.cc/api/v1/$1"
}

# downloads all the wallpaper from a wallpaperfile
# arg1: the file containing the wallpapers
function downloadWallpapers {
    for ((i=0; i<THUMBS; i++))
    do
        imgURL=$(jq -r ".data[$i].path" tmp)

        if [[ $page -gt $(jq -r ".meta.last_page" tmp) ]];
        then
            downloadEndReached=true
        fi

        filename=$(echo "$imgURL"| sed "s/.*\///" )
        if grep -w "$filename" downloaded.txt >/dev/null
        then
            printf "\\tWallpaper %s already downloaded!\\n" "$imgURL"
        else
            # check if downloadWallpaper was successful
            if downloadWallpaper "$imgURL"
            then
                echo "$filename" >> downloaded.txt
            fi
        fi
    done

    if [ $PARALLEL == 1 ] && [ -f ./download.txt ]
    then
        # export wget wrapper and download function to make it
        # available for parallel
        export -f WGET downloadWallpaper
        SHELL=$(type -p bash) parallel --gnu --no-notice \
            'imgURL={} && downloadWallpaper $imgURL && echo "$imgURL"| sed "s/.*\///" >> downloaded.txt' < download.txt
            rm tmp download.txt
        else
            rm tmp
    fi
} # /downloadWallpapers

#
# downloads a single Wallpaper by guessing its extension, this eliminates
# the need to download each wallpaper page, now only the thumbnail page
# needs to be downloaded
#
function downloadWallpaper {
    if [[ "$1" != null ]]
    then
        WGET "$1"
    else
        return 1
    fi
} # /downloadWallpaper

#
# wrapper for wget with some default arguments
# arg0: additional arguments for wget (optional)
# arg1: file to download
#
function WGET {
    # checking parameters -> if not ok print error and exit script
    if [ $# -lt 1 ]
    then
        printf "WGET expects at least 1 argument\\n"
        printf "arg0:\\tadditional arguments for wget (optional)\\n"
        printf "arg1:\\tfile to download\\n\\n"
        printf "press any key to exit\\n"
        read -r
        exit
    fi

    # default wget command
    wget -q --header="$httpHeader" --keep-session-cookies \
         --save-cookies cookies.txt --load-cookies cookies.txt "$@"
} # /WGET

checkDependencies

# optionally create a separate subfolder for each search query
# might download duplicates as each search query has its own list of
# downloaded wallpapers
if [ "$TYPE" == search ] && [ "$SUBFOLDER" == 1 ]
then
    LOCATION+=/$(echo "$QUERY" | sed -e "s/ /_/g" -e "s/+/_/g" -e  "s/\\//_/g")
fi

# creates Location folder if it does not exist
if [ ! -d "$LOCATION" ]
then
    mkdir -p "$LOCATION"
fi

cd "$LOCATION" || exit

# set auth header only when it is required ( for example to download your
# own collections or nsfw content... )
if  [ "$FILTER" == 001 ] || [ "$FILTER" == 011 ] || [ "$FILTER" == 111 ] \
    || [ "$TYPE" == collections ] || [ "$THUMBS" != 24 ]
then
    setAPIkeyHeader "$APIKEY"
fi

if [ "$TYPE" == standard ]
then
    for ((  count=0, page="$STARTPAGE";
            count< "$WPNUMBER";
            count=count+"$THUMBS", page=page+1 ));
    do
        printf "Download Page %s\\n" "$page"
        s1="search?page=$page&categories=$CATEGORIES&purity=$FILTER&"
        s1+="atleast=$ATLEAST&resolutions=$RESOLUTION&ratios=$ASPECTRATIO"
        s1+="&sorting=$MODE&order=$ORDER&topRange=$TOPRANGE&colors=$COLOR"
        getPage "$s1"
        printf "\\t- done!\\n"
        printf "Download Wallpapers from Page %s\\n" "$page"
        downloadWallpapers
        printf "\\t- done!\\n"
        if [ "$downloadEndReached" = true ]
        then
            break
        fi
    done

elif [ "$TYPE" == search ] || [ "$TYPE" == useruploads ]
then
    for ((  count=0, page="$STARTPAGE";
            count< "$WPNUMBER";
            count=count+"$THUMBS", page=page+1 ));
    do
        printf "Download Page %s\\n" "$page"
        s1="search?page=$page&categories=$CATEGORIES&purity=$FILTER&"
        s1+="atleast=$ATLEAST&resolutions=$RESOLUTION&ratios=$ASPECTRATIO"
        s1+="&sorting=$MODE&order=desc&topRange=$TOPRANGE&colors=$COLOR"
        if [ "$TYPE" == search ]
        then
            s1+="&q=$QUERY"
        elif [ "$TYPE" == useruploads ]
        then
            s1+="&q=@$USR"
        fi

        getPage "$s1"
        printf "\\t- done!\\n"
        printf "Download Wallpapers from Page %s\\n" "$page"
        downloadWallpapers
        printf "\\t- done!\\n"
        if [ "$downloadEndReached" = true ]
        then
            break
        fi
    done

elif [ "$TYPE" == collections ]
then
    if [ "$USR" == "" ]
    then
        printf "Please check the value specified for USR\\n"
        printf "to download a Collection it is necessary to specify a User\\n\\n"
        printf "Press any key to exit\\n"
        read -r
        exit
    fi

    getPage "collections/$USR"

    i=0
    while
        label=$(jq -e -r ".data[$i].label" tmp)
        id=$(jq -e -r ".data[$i].id" tmp)
        collectionsize=$(jq -e -r ".data[$i].count" tmp)
        [[ $label != "$COLLECTION" && $label != null ]]
    do
        (( i++ ))
    done

    if [ -z "$id" ]
    then
        printf "Please check the value specified for COLLECTION\\n"
        printf "it seems that a collection with the name \"%s\" does not exist\\n\\n" \
                "$COLLECTION"
        printf "Press any key to exit\\n"
        read -r
        exit
    fi

    for ((  count=0, page="$STARTPAGE";
            count< "$WPNUMBER" && count< "$collectionsize";
            count=count+"$THUMBS", page=page+1 ));
    do
        printf "Download Page %s\\n" "$page"
        getPage "collections/$USR/$id?page=$page"
        printf "\\t- done!\\n"
        printf "Download Wallpapers from Page %s\\n" "$page"
        downloadWallpapers
        printf "\\t- done!\\n"
    done
else
    printf "error in TYPE please check Variable\\n"
fi

rm -f cookies.txt
