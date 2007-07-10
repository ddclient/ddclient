#!/bin/bash
# whichlist
# * add getopt
# * automatic version

{
cat <<EOF
#
# patch created with \`svn diff -r$1 . > patches/$2\`
# on $(date)
# applied on r$1
#
EOF
svn diff -r$1 ddclient 
} > patches/$2.new

