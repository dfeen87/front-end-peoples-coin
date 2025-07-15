import React, { useState, useEffect } from "react";
import { sendLoves, formatWalletBalance } from "../firebase";
import { getFirestore, collection, query, where, getDocs } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const db = getFirestore();
const auth = getAuth();

export default function SendLoves() {
  const [toWallet, setToWallet] = useState("");
  const [amount, setAmount] = useState("");
  const [message, setMessage] = useState("");
  const [balance, setBalance] = useState({ coins: 0, loves: 0 });
  const [loading, setLoading] = useState(false);

  // Fetch and set the current user's wallet balance
  async function fetchWalletBalance() {
    const user = auth.currentUser;
    if (!user) {
      setMessage("Please log in first.");
      return;
    }
    const walletsRef = collection(db, "wallets");
    const q = query(walletsRef, where("userId", "==", user.uid));
    const snap = await getDocs(q);
    if (snap.empty) {
      setMessage("Wallet not found.");
      return;
    }
    const wallet = snap.docs[0].data();
    setBalance({ coins: wallet.coins || 0, loves: wallet.loves || 0 });
  }

  useEffect(() => {
    fetchWalletBalance();
  }, []);

  async function handleSend(e) {
    e.preventDefault();
    setMessage("");
    setLoading(true);
    try {
      const lovesToSend = parseInt(amount, 10);
      if (isNaN(lovesToSend) || lovesToSend <= 0) {
        setMessage("Enter a valid amount of loves.");
        setLoading(false);
        return;
      }
      if (!toWallet) {
        setMessage("Enter recipient wallet code.");
        setLoading(false);
        return;
      }
      await sendLoves(toWallet, lovesToSend);
      setMessage("Loves sent successfully!");
      setToWallet("");
      setAmount("");
      await fetchWalletBalance();
    } catch (error) {
      setMessage(`Error: ${error.message}`);
    }
    setLoading(false);
  }

  return (
    <div style={{ maxWidth: 400, margin: "auto", padding: 20 }}>
      <h2>Send Loves</h2>
      <p>Your balance: {formatWalletBalance(balance.coins, balance.loves)}</p>

      <form onSubmit={handleSend}>
        <label>
          Recipient Wallet Code:
          <input
            type="text"
            value={toWallet}
            onChange={(e) => setToWallet(e.target.value)}
            required
          />
        </label>
        <br />
        <label>
          Amount (loves):
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            min="1"
            required
          />
        </label>
        <br />
        <button type="submit" disabled={loading}>
          {loading ? "Sending..." : "Send Loves"}
        </button>
      </form>
      {message && <p>{message}</p>}
    </div>
  );
}

