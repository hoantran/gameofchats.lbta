#!/bin/bash

episode=$1

re='^[0-9]+$'
if ! [[ $episode =~ $re ]] ; then
   echo "error: [$episode] is NOT a number" >&2
   echo "Usage: $0 <episode_number>"
   exit 1
fi

echo "Checking in Episode $episode ..."
git add .
git commit -m "Episode $episode"
git push -u origin master
git status
