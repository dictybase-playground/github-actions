#!/bin/bash

set -e

cd $FILE_PATH

DATE=$(date +%F)
PAYLOAD="## Snapshots generated - $DATE\n\n"

for f in *.png
do
    PAYLOAD=${PAYLOAD}"- ${f}\n![${f}](${BUCKET_PATH}/${f})\n"
done

BODY=$(echo "$PAYLOAD")

curl -X POST "https://api.github.com/repos/$GITHUB_REPOSITORY/issues" \
     -H "Authorization: token $GH_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"title": "Device snapshots ('"$DATE"')", "body": "'"$BODY"'", "labels": ["snapshots"]}'

exit 0