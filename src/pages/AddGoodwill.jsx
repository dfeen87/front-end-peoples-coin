import React, { useState, useEffect } from "react";
import { getUserPremiumStatus, logGoodwillAction } from "../firebase";
import Ad from "../components/Ad";

export default function AddGoodwill() {
  const [goodwillText, setGoodwillText] = useState("");
  const [loves, setLoves] = useState(0);
  const [showAd, setShowAd] = useState(false);
  const [premium, setPremium] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    async function fetchPremium() {
      const isPremium = await getUserPremiumStatus();
      setPremium(isPremium);
    }
    fetchPremium();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!goodwillText.trim()) return;

    // For demo: generate random loves between 1-10
    const lovesCount = Math.floor(Math.random() * 10) + 1;

    await logGoodwillAction({
      text: goodwillText.trim(),
      loves: lovesCount,
      timestamp: new Date(),
    });

    setLoves(lovesCount);
    setSubmitted(true);

    if (!premium) {
      setShowAd(true);
    }
  };

  const handleAdClose = () => {
    setShowAd(false);
    setGoodwillText("");
    setLoves(0);
    setSubmitted(false);
  };

  return (
    <div className="max-w-xl mx-auto p-4">
      {!submitted && (
        <>
          <h2 className="text-xl font-bold mb-4">Log a Goodwill Action</h2>
          <form onSubmit={handleSubmit}>
            <textarea
              className="w-full border rounded p-2 mb-4"
              rows={4}
              placeholder="Describe your goodwill action..."
              value={goodwillText}
              onChange={(e) => setGoodwillText(e.target.value)}
              required
            />
            <button
              type="submit"
              className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
            >
              Submit
            </button>
          </form>
        </>
      )}

      {submitted && !showAd && (
        <div className="mt-6 p-4 border rounded bg-green-50 text-center">
          <h3 className="text-lg font-semibold">Goodwill Logged!</h3>
          <p>You earned <span className="font-bold text-red-600">{loves} ♥</span> loves.</p>
          <button
            className="mt-4 underline text-blue-600"
            onClick={() => {
              setGoodwillText("");
              setLoves(0);
              setSubmitted(false);
            }}
          >
            Log Another
          </button>
        </div>
      )}

      {showAd && <Ad onClose={handleAdClose} />}
    </div>
  );
}

