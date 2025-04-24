#!/bin/bash

FLAVOR="$1"

# FLAVOR must be identical to the ones defined in environment.dart
if [ "$FLAVOR" == "dev" ]; then
  echo "Deploying development flavor..."
  APP=flutter-no-solo-padel-dev
elif [ "$FLAVOR" == "stage" ]; then
  echo "Deploying staging flavor..."
  APP=flutter-no-solo-padel-stage
elif [ "$FLAVOR" == "prod" ]; then
  echo "Deploying production flavor..."
  APP=flutter-no-solo-padel
else
  echo "Invalid flavor (dev/stage/prod): $FLAVOR"
  exit 1
fi

RULES_FILE=config/"$FLAVOR"/firestore.rules
CORS_FILE=config/"$FLAVOR"/cors-json-file.json
BUCKET="$APP".firebasestorage.app

# Function to update URLs in index.html
update_index_html_urls() {
  local version="$1"
  local index_file="build/web/index.html"

  if [ ! -f "$index_file" ]; then
    echo "Error: index.html not found at $index_file"
    return 1
  fi

  echo "Updating URLs in $index_file with version: $version"

  # Use sed to update the URLs, handling existing query parameters correctly.
  sed -r -i "s/(src=\"flutter_bootstrap\.js)[^\"]*/\1?v=$version/g" "$index_file"

  echo "URLs in $index_file updated."
  return 0
}

if firebase use "$APP" \
  && flutter clean \
  && flutter pub get \
  && cp "$RULES_FILE" firestore.rules \
  && flutter build web --dart-define=FLAVOR="$FLAVOR" -t lib/main.dart; then
    # Get the version from pubspec.yaml
    # tr -d "'" deletes all single quote characters
    version=$(grep "version:" pubspec.yaml | awk '{print $2}' | tr -d "'")
    echo "Deploying version: $version"

    # Update index.html with the version
    if ! update_index_html_urls "$version"; then
      echo "Failed to update URLs in index.html. Deployment aborted."
      exit 1
    fi

    if ! firebase deploy; then
      echo "Failed to deploy"
      exit 1
    fi

    # update version
    echo "Updating to version $version in firestore..."
    node ./scripts/update_version.js "$FLAVOR" "$version"

    # Set CORS configuration after successful deployment
    echo "Setting CORS configuration for $BUCKET..."
    gsutil cors set "$CORS_FILE" "gs://$BUCKET"
    echo "CORS configuration set successfully."
else
  echo "Build or deployment failed. Deployment aborted."

  exit 1
fi

exit 0
