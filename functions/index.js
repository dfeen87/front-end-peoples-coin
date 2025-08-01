const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

// Initialize the Firebase Admin SDK
admin.initializeApp();

/**
 * This is your "wall" function. It password-protects your entire site.
 * It has been improved to only check the password, so any username will work.
 */
exports.myAppGatekeeper = functions.https.onRequest((req, res) => {
  // IMPORTANT: This password should be stored securely, e.g., using secrets.
  const requiredPassword = "bleigh1"; 
  
  const authHeader = req.headers.authorization || '';
  const encodedCreds = authHeader.split(' ')[1] || '';
  const decodedCreds = Buffer.from(encodedCreds, 'base64').toString();
  
  const [username, providedPassword] = decodedCreds.split(':');

  // Check ONLY the password
  if (providedPassword === requiredPassword) {
    // NOTE: This function currently shows a success message. To show your actual app,
    // the logic needs to be integrated with Firebase Hosting's ability to serve files,
    // which is a more advanced setup. For now, it works as a simple gate.
    res.status(200).send("<h1>Access Granted</h1><p>The Bright Acts app would load here.</p>");
  } else {
    // If the password is wrong, demand authentication.
    res.setHeader("WWW-Authenticate", 'Basic realm="Protected Area"');
    res.status(401).send("<h1>Authentication Required.</h1>");
  }
});


/**
 * This is your sign-up function with the CORS fix.
 * Your frontend should make API calls to this endpoint.
 */
exports.signUp = functions.https.onRequest((req, res) => {
  // This `cors` wrapper automatically handles the CORS headers.
  cors(req, res, () => {
    // --- YOUR SIGN-UP LOGIC GOES HERE ---
    // This is an example of how you might create a user.
    // You'll need to adapt it to your app's specific needs.

    const email = req.body.email;
    const password = req.body.password;

    if (!email || !password) {
      return res.status(400).send({ error: "Email and password are required." });
    }

    admin.auth().createUser({
      email: email,
      password: password,
    })
    .then(userRecord => {
      console.log("Successfully created new user:", userRecord.uid);
      // You can add more logic here, like creating a user profile in Firestore.
      return res.status(200).send({ message: "User created successfully!", uid: userRecord.uid });
    })
    .catch(error => {
      console.error("Error creating new user:", error);
      return res.status(500).send({ error: "Failed to create user." });
    });
  });
});
