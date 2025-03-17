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

if firebase use "$APP" \
  && flutter clean \
  && flutter pub get \
  && cp "$RULES_FILE" firestore.rules \
  && flutter build web --dart-define=FLAVOR="$FLAVOR" -t lib/main.dart; then
    firebase deploy
    # Set CORS configuration after successful deployment
    echo "Setting CORS configuration for $BUCKET..."
    # 17-03-2025 it requires python3.12
    gsutil cors set "$CORS_FILE" "gs://$BUCKET"
    echo "CORS configuration set successfully."
else
  echo "Build or deployment failed. Deployment aborted."
  exit 1
fi

exit 0
