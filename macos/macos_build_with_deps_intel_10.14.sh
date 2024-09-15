#!/bin/bash

if [[ $# -ne 4 ]] ; then
	echo 'Usage: macos_build_with_deps_intel_10.14.sh https_repo branch where build_type'
	exit 1
fi

DIR=$(dirname "$0")

$DIR/macos_build_with_deps.sh $1 $2 $3 $4 "x86_64" "10.14" "all"

