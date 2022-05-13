#!/bin/bash

create() {
  local config="config/j.json"
  local configKeys
  configKeys=$(jq -r 'keys | .[]' "$config")
  local pages
  pages=$(ls pages/)
  local pageTemplate="templates/page.html"
  local prebakedPage="templates/prebaked.html"
  local snippets="meta nav style js-core"

  cp "snippets/j.css" "temp/"
  cp "snippets/j.js" "temp/"
  cp "$pageTemplate" "$prebakedPage"

  for snippet in $snippets; do
    sed -i -e "/<jj-$snippet><\/jj-$snippet>/r snippets/$snippet.html" "$prebakedPage"
    sed -i -e "/<jj-$snippet><\/jj-$snippet>/d" "$prebakedPage"
  done

  for configKey in $configKeys; do
    sed -i -e "s%\\\$jj{$configKey}%$(jq -e -r --arg key "$configKey" '.[$key]' "$config")%g" "$prebakedPage"
  done

  for page in $pages; do
    # TODO: check if html is already there => html has precedence, otherwise convert md to html
    # TODO: update title here
    cp "$prebakedPage" "temp/$page"
    pandoc -f markdown_strict -t html -o "pages/$page/$page.html" "pages/$page/$page.md"
    sed -i -e "/<jj-content><\/jj-content>/r pages/$page/$page.html" "temp/$page"
    sed -i -e "/<jj-content><\/jj-content>/d" "temp/$page"

    cp -R "pages/$page/assets/" "temp/"
  done
}

if declare -f "$1" >/dev/null; then
  "$@"
else
  echo "invalid function reference" >&2
  exit 1
fi
