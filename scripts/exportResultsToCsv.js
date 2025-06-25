const { Firestore } = require('@google-cloud/firestore');
const fs = require('fs');
const path = require('path');
const { Parser } = require('json2csv'); // A popular library for JSON to CSV conversion

// --- Configuration ---
const kProductionFile = path.join(__dirname, './secret_files/secret-production-key.json');
const kStagingFile = path.join(__dirname, './secret_files/secret-staging-key.json');
const kDevelopmentFile = path.join(__dirname, './secret_files/secret-development-key.json');

const CSV_HEADERS = [
    { label: 'resultId', value: 'resultId' },
    { label: 'matchId', value: 'matchId' },
    { label: 'teamA.player1', value: 'teamA.player1' },
    { label: 'teamA.player2', value: 'teamA.player2' },
    { label: 'teamA.score', value: 'teamA.score' },
    { label: 'teamB.player1', value: 'teamB.player1' },
    { label: 'teamB.player2', value: 'teamB.player2' },
    { label: 'teamB.score', value: 'teamB.score' },
];

/**
 * Fetches all result documents and converts them to a flat array suitable for CSV.
 * @param {Firestore} firestore - The Firestore client to use.
 * @returns {Promise<Array<Object>>} A Promise that resolves with an array of flattened data.
 */
async function getFlattenedResultsForCsv(firestore) {
    console.log('Fetching documents from "results" collection...');
    const resultsCollectionRef = firestore.collection('results');
    const snapshot = await resultsCollectionRef.get();

    if (snapshot.empty) {
        console.log('No documents found in the "results" collection.');
        return [];
    }

    const flattenedData = [];
    snapshot.docs.forEach(doc => {
        const data = doc.data();
        flattenedData.push({
            resultId: doc.id, // Firestore document ID is the resultId
            matchId: data.matchId || '', // Assuming matchId is a direct field
            'teamA.player1': data?.teamA?.player1 || '',
            'teamA.player2': data?.teamA?.player2 || '',
            'teamA.score': data?.teamA?.score ?? '', // Use ?? for potential null/undefined scores
            'teamB.player1': data?.teamB?.player1 || '',
            'teamB.player2': data?.teamB?.player2 || '',
            'teamB.score': data?.teamB?.score ?? '',
        });
    });

    console.log(`Fetched ${flattenedData.length} documents.`);
    return flattenedData;
}

// --- Main Execution ---

// Get arguments from the command line
const flavor = process.argv[2];
const csvFileName = process.argv[3];

// Validate arguments
if (!flavor) {
    console.error('Error: Flavor argument is missing.');
    console.error('Usage: node exportResultsToCsv.js <flavor> <outputFileName.csv>');
    process.exit(1);
}

if (!csvFileName) {
    console.error('Error: Output CSV file name is missing.');
    console.error('Usage: node exportResultsToCsv.js <flavor> <outputFileName.csv>');
    process.exit(1);
}

// Initialize Firestore based on flavor
let firestoreInstance;
switch (flavor) {
    case 'prod':
        firestoreInstance = new Firestore({
            projectId: 'flutter-no-solo-padel', // <<< REPLACE WITH YOUR PRODUCTION PROJECT ID
            keyFilename: kProductionFile,
        });
        break;
    case 'stage':
        firestoreInstance = new Firestore({
            projectId: 'flutter-no-solo-padel-stage', // <<< REPLACE WITH YOUR STAGING PROJECT ID
            keyFilename: kStagingFile,
        });
        break;
    case 'dev':
        firestoreInstance = new Firestore({
            projectId: 'flutter-no-solo-padel-dev', // <<< REPLACE WITH YOUR DEVELOPMENT PROJECT ID
            keyFilename: kDevelopmentFile,
        });
        break;
    default:
        console.error('Error: Invalid flavor argument.');
        console.error('Usage: node exportResultsToCsv.js <flavor> <outputFileName.csv>');
        process.exit(1);
}

// Run the export process
(async () => {
    try {
        const results = await getFlattenedResultsForCsv(firestoreInstance);

        if (results.length === 0) {
            console.log('No data to write to CSV.');
            return;
        }

        const json2csvParser = new Parser({ fields: CSV_HEADERS });
        const csv = json2csvParser.parse(results);

        fs.writeFileSync(csvFileName, csv);
        console.log(`Successfully exported data to ${csvFileName}`);

    } catch (error) {
        console.error('An error occurred during the export process:', error);
        process.exit(1);
    } finally {
        // You might consider terminating the Firestore client for long-running scripts,
        // but for short scripts like this, it's usually handled by process exit.
        // if (firestoreInstance && typeof firestoreInstance.terminate === 'function') {
        //     await firestoreInstance.terminate();
        // }
    }
})();
