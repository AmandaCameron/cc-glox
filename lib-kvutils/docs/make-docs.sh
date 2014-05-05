#!/bin/bash

function compile-kvutils {
	acg-doc-maker $1
	cat $1.bbcode >>post.bbcode
	rm $1.bbcode
}

bbcode "[namedspoiler=Documentation]"

for i in lib-kvutils/docs/*.md; do
	if [[ $i != lib-kvutils/docs/lib-kvutils.md ]]; then
		compile-kvutils $i
		bbcode "[hr]"
	fi
done

bbcode "[/namedspoiler]"