// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const functions = require('firebase-functions');
// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

// Import the unidecode library for accent removal
const unidecode = require('unidecode');

/**
 * Normalizes a string by converting it to lowercase and removing accents.
 * @param {string} text The input string.
 * @returns {string} The normalized string.
 */
function normalizeString(text) {
  if (!text) return '';
  // Convert to lowercase, remove accents, and replace non-alphanumeric/space characters
  let normalizedText = unidecode(text).toLowerCase();
  // Remove any characters that are not letters, numbers, or spaces after unidecode
  normalizedText = normalizedText.replace(/[^a-z0-9\s]/g, '');
  return normalizedText;
}

// Cloud Function to automatically update 'normalizedName' on product creation/update
exports.onProductWrite = functions.firestore
  .document('products/{productId}')
  .onWrite(async (change, context) => {
    // Get the product data after the write operation (either create or update)
    const productData = change.after.data();

    // If the document was deleted, do nothing
    if (!productData) {
      console.log("Product document deleted, no normalization needed.");
      return null;
    }

    const productId = context.params.productId;
    const productName = productData.name;

    // Check if the 'name' field exists and is a string
    if (typeof productName !== 'string' || productName.trim() === '') {
      console.log(`Product ${productId} has no valid 'name' field. Skipping normalization.`);
      return null;
    }

    // Normalize the product name
    const normalizedName = normalizeString(productName);

    // Check if normalizedName already exists and is the same
    // This prevents infinite loops if the function itself triggers an update on the same field
    if (productData.normalizedName === normalizedName) {
      console.log(`Product ${productId} 'normalizedName' is already up to date.`);
      return null;
    }

    // Update the product document with the normalized name
    // Use .set with merge: true to add/update only the normalizedName field without overwriting other fields
    try {
      await admin.firestore().collection('products').doc(productId).set(
        { normalizedName: normalizedName },
        { merge: true }
      );
      console.log(`Product ${productId} 'normalizedName' updated to: "${normalizedName}"`);
      return null;
    } catch (error) {
      console.error(`Error updating product ${productId}:`, error);
      return null;
    }
  });

// Cloud Function to normalize existing products in the Firestore collection
exports.normalizeExistingProducts = functions.https.onRequest(async (req, res) => {
  const productsRef = admin.firestore().collection('products');
  let count = 0;
  try {
    const snapshot = await productsRef.get();
    const batch = admin.firestore().batch();

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const productName = data.name;

      if (typeof productName === 'string' && productName.trim() !== '') {
        const normalizedName = normalizeString(productName);
        if (data.normalizedName !== normalizedName) {
          batch.update(doc.ref, { normalizedName: normalizedName });
          count++;
        }
      }
    });

    await batch.commit();
    console.log(`Successfully normalized ${count} existing products.`);
    res.status(200).send(`Successfully normalized ${count} existing products.`);
  } catch (error) {
    console.error("Error normalizing existing products:", error);
    res.status(500).send(`Error normalizing existing products: ${error.message}`);
  }
});
