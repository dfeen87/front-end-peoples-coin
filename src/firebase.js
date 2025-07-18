import { initializeApp } from "firebase/app";
import {
  getFirestore,
  collection,
  addDoc,
  doc,
  getDoc,
  updateDoc,
  query,
  where,
  getDocs,
} from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyAS6QDkw9jZxb_TXcZUv_D4NB8qcPF5SLY",
  authDomain: "heroic-tide-428421-q7.firebaseapp.com",
  projectId: "heroic-tide-428421-q7",
  storageBucket: "heroic-tide-428421-q7.appspot.com",
  messagingSenderId: "105378934751",
  appId: "1:105378934751:web:28897b3d83884e6c411e6a",
  measurementId: "G-Q4JVFC4LMM",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

// Log a goodwill action to Firestore
export async function logGoodwillAction({ text, loves, timestamp }) {
  const user = auth.currentUser;
  if (!user) throw new Error("User not authenticated");

  const goodwillRef = collection(db, "goodwillActions");
  await addDoc(goodwillRef, {
    userId: user.uid,
    text,
    loves,
    timestamp,
  });
}

// Fetch user's premium status from Firestore
export async function getUserPremiumStatus() {
  const user = auth.currentUser;
  if (!user) return false;

  const userDoc = doc(db, "users", user.uid);
  const docSnap = await getDoc(userDoc);
  if (!docSnap.exists()) return false;

  const data = docSnap.data();
  return data.premium === true;
}

/**
 * Send loves from current authenticated user to recipient wallet by walletCode.
 * Updates both wallets atomically with rollover logic (100 loves = 1 coin).
 * Throws if sender has insufficient loves.
 * 
 * @param {string} toWalletCode - recipient's wallet code
 * @param {number} amount - amount of loves to send
 */
export async function sendLoves(toWalletCode, amount) {
  const user = auth.currentUser;
  if (!user) throw new Error("User not authenticated");
  if (amount <= 0) throw new Error("Amount must be positive");

  const walletsRef = collection(db, "wallets");

  // Get sender wallet
  const senderQuery = query(walletsRef, where("userId", "==", user.uid));
  const senderSnap = await getDocs(senderQuery);
  if (senderSnap.empty) throw new Error("Sender wallet not found");
  const senderDoc = senderSnap.docs[0];
  const senderData = senderDoc.data();

  const senderTotalLoves = senderData.coins * 100 + (senderData.loves || 0);
  if (senderTotalLoves < amount) throw new Error("Insufficient loves");

  // Deduct amount from sender's total loves
  const newSenderTotal = senderTotalLoves - amount;
  const newSenderCoins = Math.floor(newSenderTotal / 100);
  const newSenderLoves = newSenderTotal % 100;

  // Get recipient wallet
  const recipientQuery = query(walletsRef, where("walletCode", "==", toWalletCode));
  const recipientSnap = await getDocs(recipientQuery);
  if (recipientSnap.empty) throw new Error("Recipient wallet not found");
  const recipientDoc = recipientSnap.docs[0];
  const recipientData = recipientDoc.data();

  const recipientTotalLoves = recipientData.coins * 100 + (recipientData.loves || 0);
  const newRecipientTotal = recipientTotalLoves + amount;
  const newRecipientCoins = Math.floor(newRecipientTotal / 100);
  const newRecipientLoves = newRecipientTotal % 100;

  // Update both wallets
  await updateDoc(senderDoc.ref, {
    loves: newSenderLoves,
    coins: newSenderCoins,
  });

  await updateDoc(recipientDoc.ref, {
    loves: newRecipientLoves,
    coins: newRecipientCoins,
  });

  return true;
}

/**
 * Format wallet balance nicely as "X coins and Y loves"
 * Example: 3 coins and 25 loves
 * If coins = 0, returns "25 loves"
 * If loves = 0, returns "3 coins"
 * 
 * @param {number} coins 
 * @param {number} loves 
 * @returns {string}
 */
export function formatWalletBalance(coins, loves) {
  coins = coins || 0;
  loves = loves || 0;

  if (coins > 0 && loves > 0) {
    return `${coins} coin${coins > 1 ? "s" : ""} and ${loves} love${loves > 1 ? "s" : ""}`;
  } else if (coins > 0) {
    return `${coins} coin${coins > 1 ? "s" : ""}`;
  } else {
    return `${loves} love${loves > 1 ? "s" : ""}`;
  }
}

export { db, auth };

