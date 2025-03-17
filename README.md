#
# No solo Pádel
#
Organising padel matches

# version
to modify version edit pubspec.yaml

# Flavors
There 3 flavors: dev, stage and prod
to deploy each flavor execute
deploy.bat <FLAVOR>

# Firestore rules
Executing deploy.bat will overwrite firestore.rules
Then deploy this firestore.rules into Firestore project
It can be checked in the Firebase console

# Firebase storage rules
these rules are not overwritten. They are defined in Firebase console

