#!/bin/bash

set -e

# Prepare directory for audit results and sanitize URL to a valid and unique filename.
OUTPUT_FOLDER="report"
OUTPUT_FILENAME=$(echo "$INPUT_URL" | sed 's/[^a-zA-Z0-9]/_/g')
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
printf "  Also check pull request for additional information"

PERF=$(echo "$SCORE_PERFORMANCE*100" | bc -l)
ACC=$(echo "$SCORE_ACCESSIBILITY*100" | bc -l)
BP=$(echo "$SCORE_PRACTICES*100" | bc -l)
SEO=$(echo "$SCORE_SEO*100" | bc -l)
PWA=$(echo "$SCORE_PWA*100" | bc -l)
URL=$(echo "https://lighthouse-dot-webdotdevsite.appspot.com/lh/html?url=$INPUT_URL")

PAYLOAD=$(echo '{}' | jq --arg body "### Completed audit

$INPUT_URL

Scores are printed below:

+-------------------------------+
|  Performance:           $PERF
|  Accessibility:         $ACC
|  Best Practices:        $BP
|  SEO:                   $SEO
|  Progressive Web App:   $PWA
+-------------------------------+

View HTML report here: 
$URL" '.body = $body')

curl -X POST "https://api.github.com/repos/$GITHUB_REPOSITORY/issues" \
     -H "Authorization: token $GITHUB_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"title": "Lighthouse audit results -- commit $GITHUB_SHA", "body": "$PAYLOAD", "labels": ["lighthouse"]}'

exit 0