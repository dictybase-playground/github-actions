#!/bin/bash

set -e

DATE=$(date +%F)

# Prepare directory for audit results and sanitize URL to a valid and unique filename.
OUTPUT_FOLDER="report"
OUTPUT_URL="${INPUT_URL}_${DATE}"
OUTPUT_FILENAME=$(echo "$OUTPUT_URL" | sed 's/[^a-zA-Z0-9]/_/g')
OUTPUT_PATH="$GITHUB_WORKSPACE/$OUTPUT_FOLDER/$OUTPUT_FILENAME"
mkdir -p "$OUTPUT_FOLDER"

# Clarify in logs which URL we're auditing.
printf "* Beginning audit of %s ...\n\n" "$INPUT_URL"

# Run Lighthouse!
lighthouse --port=9222 --chrome-flags="--headless --disable-gpu --no-sandbox --no-zygote" --output "html" --output "json" --output-path "${OUTPUT_PATH}" "${INPUT_URL}"

# Parse individual scores from JSON output.
# Unorthodox jq syntax because of dashes -- https://github.com/stedolan/jq/issues/38
SCORE_PERFORMANCE=$(jq '.categories["performance"].score' "$OUTPUT_PATH".report.json)
SCORE_ACCESSIBILITY=$(jq '.categories["accessibility"].score' "$OUTPUT_PATH".report.json)
SCORE_PRACTICES=$(jq '.categories["best-practices"].score' "$OUTPUT_PATH".report.json)
SCORE_SEO=$(jq '.categories["seo"].score' "$OUTPUT_PATH".report.json)
SCORE_PWA=$(jq '.categories["pwa"].score' "$OUTPUT_PATH".report.json)

# Print scores to standard output (0 to 100 instead of 0 to 1)
printf "\n* Completed audit of %s ! Scores are printed below:\n\n" "$INPUT_URL"
printf "+-------------------------------+\n"
printf "|  Performance:           %.0f\t|\n" "$(echo "$SCORE_PERFORMANCE*100" | bc -l)"
printf "|  Accessibility:         %.0f\t|\n" "$(echo "$SCORE_ACCESSIBILITY*100" | bc -l)"
printf "|  Best Practices:        %.0f\t|\n" "$(echo "$SCORE_PRACTICES*100" | bc -l)"
printf "|  SEO:                   %.0f\t|\n" "$(echo "$SCORE_SEO*100" | bc -l)"
printf "|  Progressive Web App:   %.0f\t|\n" "$(echo "$SCORE_PWA*100" | bc -l)"
printf "+-------------------------------+\n\n"
printf "* Detailed results are saved here, use https://github.com/actions/upload-artifact to retrieve them:\n"
printf "    %s\n" "$OUTPUT_PATH.report.html"
printf "    %s\n" "$OUTPUT_PATH.report.json"

PERF=$(echo "$SCORE_PERFORMANCE*100" | bc -l)
ACC=$(echo "$SCORE_ACCESSIBILITY*100" | bc -l)
BP=$(echo "$SCORE_PRACTICES*100" | bc -l)
SEO=$(echo "$SCORE_SEO*100" | bc -l)
PWA=$(echo "$SCORE_PWA*100" | bc -l)

PAYLOAD="## Completed audit - $DATE\n\n$INPUT_URL\n\nScores are printed below:\n\n+-------------------------------+\n- **Performance**: *$PERF*\n- **Accessibility**: *$ACC*\n- **Best Practices**: *$BP*\n- **SEO**: *$SEO*\n- **Progressive Web App**: *$PWA*\n\n+-------------------------------+\n\nView HTML report [here]($BUCKET_PATH/$OUTPUT_FILENAME.report.html)."

curl -X POST "https://api.github.com/repos/$GITHUB_REPOSITORY/issues" \
     -H "Authorization: token $GH_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"title": "Lighthouse audit results ('"$DATE"')", "body": "'"$PAYLOAD"'", "labels": ["lighthouse"]}'

exit 0