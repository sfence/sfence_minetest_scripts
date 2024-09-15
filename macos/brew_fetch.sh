#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: "
	echo "	brew_fetch.sh package_name bottle_sha256"
fi

curl --disable --cookie /dev/null --globoff --show-error --user-agent Homebrew/4.3.18-40-g638a3dc\ \(Macintosh\;\ arm64\ Mac\ OS\ X\ 14.6.1\)\ curl/8.7.1 --header Accept-Language:\ en --fail --retry 3 --header Authorization:\ Bearer\ QQ== --remote-time --output $1.bottle.tar.gz --location https://ghcr.io/v2/homebrew/core/$1/blobs/sha256:$2

