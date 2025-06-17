const admin = require('firebase-admin');
const path = require('path');

// WITH SUBCOLLECTIONS. NOT FULLY TESTED

const kProductionFile = path.join(__dirname, './secret_files/secret-production-key.json');
const kStagingFile = path.join(__dirname, './secret_files/secret-staging-key.json');
const kDevelopmentFile = path.join(__dirname, './secret_files/secret-development-key.json');

async function copyFirestoreData() {
    try {
        // Initialize Production Firestore
        const productionApp = admin.initializeApp({
            credential: admin.credential.cert(kProductionFile),
        }, 'production');
        const productionFirestore = productionApp.firestore();

        // Initialize Staging Firestore
        const stagingApp = admin.initializeApp({
            credential: admin.credential.cert(kStagingFile),
        }, 'staging');
        const stagingFirestore = stagingApp.firestore();

        // Erase Staging Database including subcollections
        await eraseStagingDatabase(stagingFirestore);

        // Get all collections from the production Database.
        const collections = await productionFirestore.listCollections();

        for (const collection of collections) {
            console.log(`Copying collection: ${collection.id}`);
            await copyCollection(productionFirestore, stagingFirestore, collection.id);
        }

        console.log('Firestore data copy completed!');
        // Clean up the apps.
        await productionApp.delete();
        await stagingApp.delete();

    } catch (error) {
        console.error('Error copying Firestore data:', error);
    }
}

async function copyCollection(productionFirestore, stagingFirestore, collectionId) {
    const snapshot = await productionFirestore.collection(collectionId).get();

    for (const doc of snapshot.docs) {
        const data = doc.data();
        await stagingFirestore.collection(collectionId).doc(doc.id).set(data);
        console.log(`Copied document: ${doc.id} from collection: ${collectionId}`);

        // Copy subcollections
        const subcollections = await productionFirestore.collection(collectionId).doc(doc.id).listCollections();
        for (const subcollection of subcollections) {
            console.log(`  Copying subcollection: ${subcollection.id} in document: ${doc.id}`);
            await copySubcollection(productionFirestore, stagingFirestore, collectionId, doc.id, subcollection.id);
        }
    }
}

async function copySubcollection(productionFirestore, stagingFirestore, parentCollectionId, parentDocId, subcollectionId) {
    const snapshot = await productionFirestore
        .collection(parentCollectionId)
        .doc(parentDocId)
        .collection(subcollectionId)
        .get();

    for (const doc of snapshot.docs) {
        await stagingFirestore
            .collection(parentCollectionId)
            .doc(parentDocId)
            .collection(subcollectionId)
            .doc(doc.id)
            .set(doc.data());
        console.log(`    Copied document: ${doc.id} from subcollection: ${subcollectionId} in document: ${parentDocId}`);
    }
}

async function eraseStagingDatabase(stagingFirestore) {
    console.log('Erasing staging database including subcollections...');

    const collections = await stagingFirestore.listCollections();

    for (const collection of collections) {
        console.log(`Deleting collection: ${collection.id} and its subcollections...`);
        await deleteCollectionAndSubcollections(stagingFirestore, collection.id);
    }

    console.log('Staging database erased.');
}

async function deleteCollectionAndSubcollections(db, collectionPath, batchSize = 500) {
    const collectionRef = db.collection(collectionPath);
    const query = collectionRef.orderBy('__name__').limit(batchSize);

    const snapshot = await query.get();
    await Promise.all(snapshot.docs.map(async (doc) => {
        const subcollections = await doc.ref.listCollections();
        for (const subcollection of subcollections) {
            console.log(`  Deleting subcollection: ${subcollection.id} in document: ${doc.id}`);
            await deleteCollection(db, subcollection.path); // Recursively delete subcollection
        }
        return db.batch().delete(doc.ref).commit(); // Delete the document itself
    }));

    // Check if there are more documents to delete in the current collection
    if (snapshot.size >= batchSize) {
        await deleteCollectionAndSubcollections(db, collectionPath, batchSize); // Recursive call for the rest
    }
}

async function deleteCollection(db, collectionPath, batchSize = 500) {
    const collectionRef = db.collection(collectionPath);
    const query = collectionRef.orderBy('__name__').limit(batchSize);

    return new Promise((resolve, reject) => {
        deleteQueryBatch(db, query, batchSize, resolve, reject);
    });
}

async function deleteQueryBatch(db, query, batchSize, resolve, reject) {
    query.get().then((snapshot) => {
        if (snapshot.size === 0) {
            return 0;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });

        return batch.commit().then(() => {
            return snapshot.size;
        });
    }).then((numDeleted) => {
        if (numDeleted === 0) {
            resolve();
            return;
        }
        process.nextTick(() => {
            deleteQueryBatch(db, query, batchSize, resolve, reject);
        });
    }).catch(reject);
}

copyFirestoreData();