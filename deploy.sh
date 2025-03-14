#!/bin/bash

FLAVOR="$1"

# FLAVOR must be identical to the ones defined in environment.dart
if [ "$FLAVOR" == "dev" ]; then
  echo "Deploying development flavor..."
  firebase use flutter-no-solo-padel-dev
elif [ "$FLAVOR" == "stage" ]; then
  echo "Deploying staging flavor..."
  firebase use flutter-no-solo-padel-stage
elif [ "$FLAVOR" == "prod" ]; then
  echo "Deploying production flavor..."
  firebase use flutter-no-solo-padel
else
  echo "Invalid flavor (dev/stage/prod): $FLAVOR"
  exit 1
fi

if flutter clean \
  && flutter pub get \
  && cp config/"$FLAVOR"/firestore.rules firestore.rules \
  && flutter build web --dart-define=FLAVOR="$FLAVOR" -t lib/main.dart; then
    firebase deploy
else
  echo "Build failed. Deployment aborted."
  exit 1
fi


exit 0


