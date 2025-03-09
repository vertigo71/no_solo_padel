#!/bin/bash

FLAVOR="$1"

if [ "$FLAVOR" == "dev" ]; then
  echo "Deploying development flavor..."
  cp config/dev/firestore.rules firestore.rules
  if flutter build web --dart-define=FLAVOR=dev -t lib/main.dart; then  # Check build success
    firebase deploy
  else
    echo "Build failed. Deployment aborted."
    exit 1  # Or handle the error differently
  fi
elif [ "$FLAVOR" == "prod" ]; then
  echo "Deploying production flavor..."
  cp config/prod/firestore.rules firestore.rules
  if flutter build web --dart-define=FLAVOR=prod -t lib/main.dart; then  # Check build success
    firebase deploy
  else
    echo "Build failed. Deployment aborted."
    exit 1  # Or handle the error differently
  fi
else
  echo "Invalid flavor (dev/prod): $FLAVOR"
  exit 1
fi

exit 0


