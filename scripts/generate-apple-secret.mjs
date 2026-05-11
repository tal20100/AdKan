import crypto from "crypto";
import fs from "fs";

const teamId = "STJA5GH4Y9";
const keyId = "6M44P2LT49";
const clientId = "com.talhayun.AdKan.auth";
const keyPath = process.argv[2];

if (!keyPath) {
  console.error("Usage: node generate-apple-secret.mjs <path-to-.p8-file>");
  process.exit(1);
}

const privateKey = fs.readFileSync(keyPath, "utf8");

const header = { alg: "ES256", kid: keyId, typ: "JWT" };
const now = Math.floor(Date.now() / 1000);
const payload = {
  iss: teamId,
  iat: now,
  exp: now + 15777000, // ~6 months
  aud: "https://appleid.apple.com",
  sub: clientId,
};

function base64url(obj) {
  return Buffer.from(JSON.stringify(obj))
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

const unsignedToken = base64url(header) + "." + base64url(payload);
const sign = crypto.createSign("SHA256");
sign.update(unsignedToken);
const signature = sign
  .sign({ key: privateKey, dsaEncoding: "ieee-p1363" })
  .toString("base64")
  .replace(/=/g, "")
  .replace(/\+/g, "-")
  .replace(/\//g, "_");

console.log(unsignedToken + "." + signature);
