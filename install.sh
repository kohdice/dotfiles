#!/bin/sh

echo "Checking operating system..."

if [ "$(uname)" == "Darwin" ] ; then
  echo "MacOS"
fi
