#!/bin/bash

FLAVOR="$1"

if [ "$FLAVOR" == "dev" ]; then
  echo "Deploying development flavor..."
  cp config/dev/firestore.rules firestore.rules
  flutter build web --dart-define=FLAVOR=dev -t lib/main.dart
  firebase deploy
elif [ "$FLAVOR" == "prod" ]; then
  echo "Deploying production flavor..."
  cp config/prod/firestore.rules firestore.rules
  flutter build web --dart-define=FLAVOR=prod -t lib/main.dart
  firebase deploy
else
  echo "Invalid flavor: $FLAVOR"
  exit 1
fi

# ... any other deployment steps