#!/bin/bash

create() {
  local snippets="meta style"

  cp templates/page.html temp/test

  for x in $snippets; do
    sed -i -e "/<jj-$x><\/jj-$x>/r snippets/$x.html" temp/test
    sed -i -e "/<jj-$x><\/jj-$x>/d" temp/test
  done
}

if declare -f "$1" > /dev/null
then
  "$@"
else
  echo "invalid function reference" >&2
  exit 1
fi
