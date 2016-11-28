#!/bin/sh

cd /Users/tbl/Desktop/GoogleDrive/MacBookSync/git/C/
echo "SUMMARY"
read SUMMARY
git init && git add . && git commit -m "$SUMMARY" && git push -u origin master

