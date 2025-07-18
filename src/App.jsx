import React, { useState } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

// Import your page components
import WalletOverview from "./pages/WalletOverview";
import Governance from "./pages/Governance";
import Portfolio from "./pages/Portfolio";
import AddGoodwill from "./pages/AddGoodwill";
import Options from "./pages/Options";
import Login from "./pages/Login"; // If you have authentication
import Home from "./pages/Home"; // Front page with whitepaper or intro

function App() {
  const [unlocked, setUnlocked] = useState(false);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  if (!unlocked) {
    return (
      <div style={{ textAlign: "center", marginTop: "20%" }}>
        <h2>Login</h2>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          style={{ marginRight: "10px" }}
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          style={{ marginRight: "10px" }}
        />
        <button
          onClick={() => {
            if (username === "dfeen87" && password === "bleigh1!") {
              setUnlocked(true);
            } else {
              alert("Invalid username or password");
            }
          }}
        >
          Unlock
        </button>
      </div>
    );
  }

  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/wallet" element={<WalletOverview />} />
        <Route path="/governance" element={<Governance />} />
        <Route path="/portfolio" element={<Portfolio />} />
        <Route path="/add-goodwill" element={<AddGoodwill />} />
        <Route path="/options" element={<Options />} />
        <Route path="/login" element={<Login />} />
        {/* Redirect any unknown routes to home */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;

