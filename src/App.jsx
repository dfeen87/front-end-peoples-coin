import React from "react";
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

