const { Firestore } = require('@google-cloud/firestore');
const path = require('path');

// Define key file paths using path.join and __dirname
const kProductionFile = path.join(__dirname, './secret_files/secret-production-key.json');
const kStagingFile = path.join(__dirname, './secret_files/secret-staging-key.json');
const kDevelopmentFile = path.join(__dirname, './secret_files/secret-development-key.json');

/**
 * Processes all documents in the 'results' collection to add/update the 'players' field.
 * @param {Firestore} firestore - The Firestore client to use.
 * @returns {Promise<void>}
 */
async function processAllResultDocuments(firestore) {
    console.log('Starting to process all result documents...');
    const resultsCollectionRef = firestore.collection('results');

    // Get all documents from the 'results' collection
    const snapshot = await resultsCollectionRef.get();

    if (snapshot.empty) {
        console.log('No documents found in the "results" collection.');
        return;
    }

    const batch = firestore.batch();
    let batchCount = 0;
    const batchSize = 400; // Firestore batch write limit is 500

    for (const doc of snapshot.docs) {
        const docRef = doc.ref; // Reference to the current document
        const data = doc.data();

        // Extract player IDs safely, handling potential nulls or missing fields
        const teamA_player1 = data?.teamA?.player1;
        const teamA_player2 = data?.teamA?.player2;
        const teamB_player1 = data?.teamB?.player1;
        const teamB_player2 = data?.teamB?.player2;

        const playersArray = [];
        if (teamA_player1) playersArray.push(teamA_player1);
        if (teamA_player2) playersArray.push(teamA_player2);
        if (teamB_player1) playersArray.push(teamB_player1);
        if (teamB_player2) playersArray.push(teamB_player2);

        const uniquePlayers = [...new Set(playersArray)];

        batch.update(docRef, { players: uniquePlayers });
        batchCount++;

        // Commit batch when it reaches batchSize or is the last document
        if (batchCount === batchSize) {
            console.log(`Committing a batch of ${batchCount} updates...`);
            await batch.commit();
            batch = firestore.batch(); // Start a new batch
            batchCount = 0;
        }
    }

    // Commit any remaining documents in the last batch
    if (batchCount > 0) {
        console.log(`Committing final batch of ${batchCount} updates...`);
        await batch.commit();
    }

    console.log('Finished processing all result documents.');
}

// --- Main execution flow ---

// Get the flavor from the command line.
const flavor = process.argv[2];

if (!flavor) {
    console.error('Error: Flavor argument is missing.');
    console.error('Usage: node script.js <flavor> [documentId]');
    console.error('To update all documents: node script.js <flavor>');
    process.exit(1); // Exit with an error code
}

// Optional: Get a specific document ID from the command line (if provided)
const documentId = process.argv[3];

let firestoreInstance; // Declare firestoreInstance outside the switch

switch (flavor) {
    case 'prod':
        firestoreInstance = new Firestore({
            projectId: 'flutter-no-solo-padel', // Replace with your Google Cloud Project ID
            keyFilename: kProductionFile,
        });
        break;
    case 'stage':
        firestoreInstance = new Firestore({
            projectId: 'flutter-no-solo-padel-stage', // Replace with your Google Cloud Project ID
            keyFilename: kStagingFile,
        });
        break;
    case 'dev':
        firestoreInstance = new Firestore({
            projectId: 'flutter-no-solo-padel-dev', // Replace with your Google Cloud Project ID
            keyFilename: kDevelopmentFile,
        });
        break;
    default:
        console.error('Error: Invalid flavor argument.');
        console.error('Usage: node script.js <flavor> [documentId]');
        console.error('To update all documents: node script.js <flavor>');
        process.exit(1); // Exit with an error code
}

// Determine whether to update a single document or all documents
(async () => {
    try {
        // Update all documents in the 'results' collection
        await processAllResultDocuments(firestoreInstance);
        console.log('Update complete for all documents in "results" collection.');
    } catch (error) {
        console.error('Operation failed:', error);
        process.exit(1); // Exit with an error code
    } finally {
        // You might need to explicitly close the Firestore instance if your environment requires it.
        // For simple scripts, Node.js process termination usually handles this.
        // If you were to run this as a long-lived process or in a Cloud Function, you might add:
        // await firestoreInstance.terminate();
    }
})();

