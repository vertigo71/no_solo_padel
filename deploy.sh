#!/bin/bash

FLAVOR="$1"

# FLAVOR must be identical to the ones defined in environment.dart
if [ "$FLAVOR" == "dev" ]; then
  echo "Deploying development flavor..."
  firebase use flutter-no-solo-padel-dev
  cp config/dev/firestore.rules firestore.rules
  if flutter build web --dart-define=FLAVOR=dev -t lib/main.dart; then  # Check build success
    firebase deploy
  else
    echo "Build failed. Deployment aborted."
    exit 1
  fi
elif [ "$FLAVOR" == "stage" ]; then
  echo "Deploying staging flavor..."
  firebase use flutter-no-solo-padel-stage
  cp config/stage/firestore.rules firestore.rules
  if flutter build web --dart-define=FLAVOR=stage -t lib/main.dart; then  # Check build success
    firebase deploy
  else
    echo "Build failed. Deployment aborted."
    exit 1
  fi
elif [ "$FLAVOR" == "prod" ]; then
  echo "Deploying production flavor..."
  firebase use flutter-no-solo-padel
  cp config/prod/firestore.rules firestore.rules
  if flutter build web --dart-define=FLAVOR=prod -t lib/main.dart; then  # Check build success
    firebase deploy
  else
    echo "Build failed. Deployment aborted."
    exit 1
  fi
else
  echo "Invalid flavor (dev/stage/prod): $FLAVOR"
  exit 1
fi

exit 0


