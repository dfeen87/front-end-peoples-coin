const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
const axios = require("axios"); // We need axios to call your Python API

admin.initializeApp();

// Your "wall" function remains the same
exports.myAppGatekeeper = functions.https.onRequest((req, res) => {
  const requiredPassword = "bleigh1"; 
  const authHeader = req.headers.authorization || '';
  const encodedCreds = authHeader.split(' ')[1] || '';
  const decodedCreds = Buffer.from(encodedCreds, 'base64').toString();
  const [username, providedPassword] = decodedCreds.split(':');

  if (providedPassword === requiredPassword) {
    res.status(200).send("<h1>Access Granted</h1><p>The Bright Acts app would load here.</p>");
  } else {
    res.setHeader("WWW-Authenticate", 'Basic realm="Protected Area"');
    res.status(401).send("<h1>Authentication Required.</h1>");
  }
});

/**
 * A single, robust function to handle the entire sign-up process.
 */
exports.unifiedSignUp = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    const { email, password, username } = req.body;

    if (!email || !password || !username) {
      return res.status(400).send({ error: "Email, password, and username are required." });
    }

    try {
      // Step 1: Create the user in Firebase Authentication
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: username,
      });

      console.log("Successfully created Firebase Auth user:", userRecord.uid);

      // Step 2: Create the user profile in your Python backend database
      const pythonApiUrl = "https://peoples-coin-service-105378934751.us-central1.run.app/api/v1/users";
      await axios.post(pythonApiUrl, {
        firebase_uid: userRecord.uid,
        email: email,
        username: username,
      });

      console.log("Successfully created user profile in Python backend for:", userRecord.uid);

      // Step 3: Return a success message
      return res.status(200).send({ message: "User created successfully!", uid: userRecord.uid });

    } catch (error) {
      console.error("Error during unified sign-up:", error);
      
      // Handle specific errors, like "email already exists"
      if (error.code === 'auth/email-already-exists') {
        return res.status(409).send({ error: "This email address is already in use." });
      }
      
      return res.status(500).send({ error: "An unexpected error occurred during sign-up." });
    }
  });
});

/**
 * A separate function just for checking username availability.
 */
exports.checkUsername = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    const { username } = req.body;
    if (!username) {
      return res.status(400).send({ error: "Username is required." });
    }
    try {
      // This function calls your Python backend to check the username
      const pythonApiUrl = `https://peoples-coin-service-105378934751.us-central1.run.app/api/v1/users/username-check/${username}`;
      const response = await axios.get(pythonApiUrl);
      return res.status(200).send(response.data);
    } catch (error) {
      console.error("Error checking username:", error);
      return res.status(500).send({ error: "Failed to check username availability." });
    }
  });
});
