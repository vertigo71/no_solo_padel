const { Firestore } = require('@google-cloud/firestore');
const path = require('path');

// Define key file paths using path.join and __dirname
const kProductionFile = path.join(__dirname, './secret_files/secret-production-key.json');
const kStagingFile = path.join(__dirname, './secret_files/secret-staging-key.json');
const kDevelopmentFile = path.join(__dirname, './secret_files/secret-development-key.json');

/**
 * Updates the 'version' field in the 'parameters/parameters' document in Firestore.
 *
 * @param {string} newVersion - The new version string to set.
 * @param {Firestore} firestore -  The Firestore client to use.
 * @returns {Promise<void>} A Promise that resolves when the update is complete, or rejects on error.
 */
async function updateVersion(newVersion, firestore) {
  try {
    // Get a reference to the document.
    const docRef = firestore.doc('parameters/parameters');

    // Update the 'version' field.
    await docRef.update({ version: newVersion });

    console.log(`Successfully updated version to ${newVersion}`);
  } catch (error) {
    console.error('Error updating version:', error);
    throw error; // Re-throw the error to be caught by the caller, if needed
  }
}

// Get the version from the command line.
const flavor = process.argv[2];
const newVersion = process.argv[3];

if (!flavor) {
  console.error('Error: Flavor argument is missing.');
  console.error('Usage: node script.js <flavor> <version>');
  process.exit(1); // Exit with an error code
}

if (!newVersion) {
  console.error('Error: Version argument is missing.');
  console.error('Usage: node script.js <flavor> <version>');
  process.exit(1); // Exit with an error code
}

let firestore; // Declare firestore outside the switch

switch (flavor) {
  case 'prod':
    firestore = new Firestore({
      projectId: 'flutter-no-solo-padel', // Replace with your Google Cloud Project ID
      keyFilename: kProductionFile,
    });
    break;
  case 'stage':
    firestore = new Firestore({
      projectId: 'flutter-no-solo-padel-stage', // Replace with your Google Cloud Project ID
      keyFilename: kStagingFile,
    });
    break;
  case 'dev':
    firestore = new Firestore({
      projectId: 'flutter-no-solo-padel-dev', // Replace with your Google Cloud Project ID
      keyFilename: kDevelopmentFile,
    });
    break;
  default:
    console.error('Error: Invalid flavor argument.');
    console.error('Usage: node script.js <flavor> <version>');
    process.exit(1); // Exit with an error code
}

updateVersion(newVersion, firestore)
  .then(() => {
    console.log('Update complete.');
  })
  .catch((error) => {
    // Handle any errors that occurred during the update process.
    console.error('Update failed:', error);
    process.exit(1); // Exit with an error code
  });
