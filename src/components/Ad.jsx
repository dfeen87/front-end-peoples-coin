import React, { useEffect, useState } from "react";

export default function Ad({ onClose }) {
  const [countdown, setCountdown] = useState(5);

  useEffect(() => {
    if (countdown === 0) return;

    const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
    return () => clearTimeout(timer);
  }, [countdown]);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-75 flex flex-col items-center justify-center text-white p-6 z-50">
      <div className="max-w-md text-center">
        <h2 className="text-2xl font-bold mb-4">Sponsored Ad</h2>
        <p className="mb-6">Support the project by checking out this sponsor!</p>
        {/* Placeholder for an actual ad or link */}
        <div className="mb-6 bg-gray-800 p-4 rounded">[Your Ad Here]</div>

        {countdown > 0 ? (
          <p className="mb-4">You can skip this ad in {countdown} second{countdown > 1 ? "s" : ""}.</p>
        ) : (
          <button
            onClick={onClose}
            className="bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded text-white"
          >
            Skip Ad
          </button>
        )}
      </div>
    </div>
  );
}

