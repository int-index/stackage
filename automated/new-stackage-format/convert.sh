#!/usr/bin/env bash

set -eux

if [[ ! -f convert ]]
then
    curl https://s3.amazonaws.com/www.snoyman.com/convert-old-stackage-f780174e2c84e4fb171f6526228d9243beb7fd71.bz2 > convert.bz2
    chmod +x convert.bz2
    bunzip2 convert.bz2
fi

cd $(dirname ${BASH_SOURCE[0]})

for d in lts-haskell stackage-nightly stackage-snapshots
do
    if [[ ! -d "$d" ]]
    then
        git clone https://github.com/commercialhaskell/$d
    else
        (cd "$d" && git pull || echo "Git pull failed, ignoring")
    fi
done

./convert

cd stackage-snapshots
git add lts nightly
git diff-index --quiet HEAD && echo No changes && exit 0
git config user.name "Stackage build server"
git config user.email "michael@snoyman.com"
git commit -m "More conversions $(date)"
GIT_SSH_COMMAND='ssh -i ../../ssh-lts/id_rsa' git push git@github.com:commercialhaskell/stackage-snapshots master
