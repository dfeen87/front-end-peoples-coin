import React, { useEffect, useState } from "react";
import { getAuth } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { db } from "../firebase";

function formatCoinsAndLoves(totalLoves) {
  const coins = Math.floor(totalLoves / 100);
  const loves = totalLoves % 100;
  return `${coins} coin${coins !== 1 ? "s" : ""} and ${loves} love${loves !== 1 ? "s" : ""}`;
}

const WalletOverview = () => {
  const [walletAddress, setWalletAddress] = useState("");
  const [totalLoves, setTotalLoves] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchWallet = async () => {
    setLoading(true);
    setError(null);
    try {
      const user = getAuth().currentUser;
      if (!user) {
        setError("User not authenticated");
        setLoading(false);
        return;
      }

      setWalletAddress(user.uid);

      const walletDoc = doc(db, "wallets", user.uid);
      const walletSnap = await getDoc(walletDoc);

      if (walletSnap.exists()) {
        const data = walletSnap.data();
        setTotalLoves(data.loves || 0);
      } else {
        setTotalLoves(0);
      }
    } catch (err) {
      setError("Failed to fetch wallet data");
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWallet();
  }, []);

  if (loading) return <div>Loading wallet...</div>;

  if (error) return <div className="text-red-600">Error: {error}</div>;

  return (
    <div className="wallet-overview p-4">
      <h2 className="text-xl font-bold mb-2">Your Wallet</h2>
      <p><strong>Address:</strong> {walletAddress}</p>
      <p><strong>Balance:</strong> {formatCoinsAndLoves(totalLoves)}</p>
      <button
        className="btn btn-primary mt-4"
        onClick={fetchWallet}
      >
        Refresh Balance
      </button>
      {/* Future buttons */}
      <button className="btn btn-secondary mt-4 ml-4">Send Love</button>
    </div>
  );
};

export default WalletOverview;

