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
  local tempSnippet="temp.txt"

  # TODO: rename temp/ to upload/, also check workflow
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

    # TODO: put file in temp dir?
    local bgImage
    bgImage=$(echo "$(ls "pages/$page/assets/" | grep '\-bg\.' || echo 'not-found.gif')" | head -1)
    local bgImageTitle
    bgImageTitle=$(echo "$bgImage" | sed -E 's/-bg.+//g' | sed 's/-/ /g')

    cp "snippets/article-bg.html" "$tempSnippet"
    sed -i -e "s%\\\$jj{src}%$bgImage%g" "$tempSnippet"
    sed -i -e "s%\\\$jj{title}%$bgImageTitle%g" "$tempSnippet"
    sed -i -e "/<\/nav>/r $tempSnippet" "temp/$page"

    cp -R "pages/$page/assets/" "temp/"
  done
}

if declare -f "$1" >/dev/null; then
  "$@"
else
  echo "invalid function reference" >&2
  exit 1
fi
