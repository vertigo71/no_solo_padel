
It uses 2 secret keys: secret-production-key.json and secret-staging-key.json.
    To generate these keys: look for

        How to create production/staging-service-account.json?

    in Programming in Drive

to copy all elements from prod to stage execute:

    node copy-firestore.js

to update version in firestore execute:
    node update-version.js <flavor> <version>

to create players field in results execute:
    node create-players-field-in-results.js <flavor>

