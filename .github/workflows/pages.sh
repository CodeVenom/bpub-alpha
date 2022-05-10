#!/bin/bash

create() {
  # TODO: pre-bake page without content
  local snippets="meta style"
  local pages
  pages=$(ls pages/)

  for page in $pages; do
    cp templates/page.html "temp/$page"

    for snippet in $snippets; do
      sed -i -e "/<jj-$snippet><\/jj-$snippet>/r snippets/$snippet.html" "temp/$page"
      sed -i -e "/<jj-$snippet><\/jj-$snippet>/d" "temp/$page"
    done

    # TODO: check if html is already there => html has precedence, otherwise convert md to html
    pandoc -f markdown_strict -t html -o "pages/$page/$page.html" "pages/$page/$page.md"
    sed -i -e "/<jj-content><\/jj-content>/r pages/$page/$page.html" "temp/$page"
    sed -i -e "/<jj-content><\/jj-content>/d" "temp/$page"

    cp -R "pages/$page/assets/" "temp/assets/"
  done
}

if declare -f "$1" >/dev/null; then
  "$@"
else
  echo "invalid function reference" >&2
  exit 1
fi
