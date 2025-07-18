// src/pages/Wallet.jsx
import React, { useEffect, useState } from "react";
import { getOrCreateWallet, sendLoves } from "../firebase";

export default function Wallet({ userId }) {
  const [wallet, setWallet] = useState(null);
  const [loading, setLoading] = useState(true);
  const [sendTo, setSendTo] = useState("");
  const [amount, setAmount] = useState("");
  const [message, setMessage] = useState("");

  useEffect(() => {
    async function loadWallet() {
      setLoading(true);
      try {
        const data = await getOrCreateWallet(userId);
        setWallet(data);
      } catch (e) {
        setMessage("Failed to load wallet: " + e.message);
      }
      setLoading(false);
    }
    loadWallet();
  }, [userId]);

  async function handleSend(e) {
    e.preventDefault();
    setMessage("");
    const amt = parseInt(amount, 10);
    if (!sendTo || !amt || amt <= 0) {
      setMessage("Enter valid wallet and amount");
      return;
    }
    try {
      await sendLoves(userId, sendTo, amt);
      setMessage(`Sent ${amt} Loves to ${sendTo}`);
      // Refresh wallet data after sending
      const updatedWallet = await getOrCreateWallet(userId);
      setWallet(updatedWallet);
      setSendTo("");
      setAmount("");
    } catch (e) {
      setMessage("Error: " + e.message);
    }
  }

  if (loading) return <p>Loading wallet...</p>;

  return (
    <div>
      <h2>Your Wallet</h2>
      <p><strong>Wallet Code:</strong> {wallet.walletCode}</p>
      <p><strong>Loves Balance:</strong> {wallet.lovesBalance}</p>
      <p><strong>Coins (100 Loves = 1 Coin):</strong> {(wallet.lovesBalance / 100).toFixed(2)}</p>

      <hr />

      <h3>Send Loves</h3>
      <form onSubmit={handleSend}>
        <div>
          <label>To Wallet Code:</label><br />
          <input
            value={sendTo}
            onChange={(e) => setSendTo(e.target.value.toUpperCase())}
            placeholder="WLT-XXXXXXX"
            required
          />
        </div>
        <div>
          <label>Amount:</label><br />
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            min="1"
            required
          />
        </div>
        <button type="submit">Send</button>
      </form>

      {message && <p>{message}</p>}
    </div>
  );
}

