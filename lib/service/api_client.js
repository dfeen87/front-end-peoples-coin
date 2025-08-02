// src/service/api_client.js
import { PeoplesCoinApiClient as BaseClient } from "./base_api_client"; // your existing client

async function sha256(message) {
    const msgBuffer = new TextEncoder().encode(message);
    const hashBuffer = await crypto.subtle.digest("SHA-256", msgBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

async function solvePoW(challenge, difficulty) {
    let nonce = 0;
    const target = "0".repeat(difficulty);
    while (true) {
        const attempt = challenge + nonce;
        const digest = await sha256(attempt);
        if (digest.startsWith(target)) {
            return nonce.toString();
        }
        nonce++;
        if (nonce % 10000 === 0) {
            await new Promise(r => setTimeout(r, 0)); // let UI breathe
        }
    }
}

export class PeoplesCoinApiClient extends BaseClient {
    constructor(baseUrl, defaultHeaders = {}) {
        super(baseUrl, defaultHeaders);
    }

    async request(path, options = {}) {
        const url = `${this.baseUrl}${path}`;
        let res = await fetch(url, {
            ...options,
            headers: {
                ...this.defaultHeaders,
                ...(options.headers || {})
            }
        });

        let json;
        try {
            json = await res.clone().json();
        } catch (e) {
            return res; // Not JSON → return original
        }

        if (json && json.error === "PoW required" && json.challenge && json.difficulty) {
            console.log(`⚙️ PoW challenge received. Solving... (difficulty ${json.difficulty})`);
            const nonce = await solvePoW(json.challenge, json.difficulty);
            console.log(`✅ PoW solved with nonce: ${nonce}`);

            // Retry with PoW headers
            res = await fetch(url, {
                ...options,
                headers: {
                    ...this.defaultHeaders,
                    ...(options.headers || {}),
                    "X-PoW-Nonce": nonce,
                    "X-PoW-Challenge": json.challenge
                }
            });
        }

        return res;
    }

    async get(path, options = {}) {
        return this.request(path, { ...options, method: "GET" });
    }

    async post(path, body, options = {}) {
        return this.request(path, {
            ...options,
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                ...(options.headers || {})
            },
            body: JSON.stringify(body)
        });
    }

    async put(path, body, options = {}) {
        return this.request(path, {
            ...options,
            method: "PUT",
            headers: {
                "Content-Type": "application/json",
                ...(options.headers || {})
            },
            body: JSON.stringify(body)
        });
    }

    async delete(path, options = {}) {
        return this.request(path, { ...options, method: "DELETE" });
    }
}

