#!/bin/bash

function compile() {
	acg-doc-maker $1
	cat $1.bbcode >>post.bbcode
	cat `echo $1 | sed s/\.md/\.txt/` >>desc.txt
	rm $1.bbcode
}

function bbcode() {
	echo $* >>post.bbcode
}

function desc() {
	echo $* >>desc.txt
}

#cat header.md >post

echo >post.bbcode
echo >desc.txt

compile header.md

for i in *; do
	if [[ -e $i/docs/$i.md ]]; then
		desc "$i"
		desc $(echo $i | tr [a-zA-Z0-9-] '=')
		desc

		bbcode "[namedspoiler=$i]"

		compile $i/docs/$i.md

		if [[ -e $i/docs/make-docs.sh ]]; then
			. $i/docs/make-docs.sh
		fi

		bbcode "[/namedspoiler]"
		bbcode
		desc
	fi
done