import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  // Optional: you can specify base path if deploying to a subfolder, otherwise remove
  // base: "/",
});

