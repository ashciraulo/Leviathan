#!/usr/bin/env node
// Boots the web build in headless Chromium and fails if it doesn't reach the
// title screen. CI runs it after every web export:
//     node tools/web_check.mjs export/web [screenshot.png]
// It serves the folder over HTTP (browsers won't run Godot from file://),
// waits for the engine to start, watches the console for script errors, and
// checks the canvas has actually drawn something (not a blank or error page).
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const dir = path.resolve(process.argv[2] || "export/web");
const shot = process.argv[3] || "";
const BOOT_TIMEOUT_MS = 90000;
const TYPES = {
  ".html": "text/html", ".js": "application/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".json": "application/json",
};

function serve() {
  const server = http.createServer((req, res) => {
    const url = decodeURIComponent((req.url || "/").split("?")[0]);
    const file = path.join(dir, url === "/" ? "index.html" : url);
    if (!file.startsWith(dir) || !fs.existsSync(file)) {
      res.writeHead(404);
      res.end();
      return;
    }
    res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

const failures = [];
const server = await serve();
const port = server.address().port;
const browser = await chromium.launch({ args: ["--autoplay-policy=no-user-gesture-required"] });
const page = await browser.newPage({ viewport: { width: 1152, height: 648 } });
let booted = false;
page.on("console", (msg) => {
  const text = msg.text();
  if (process.env.WEB_CHECK_VERBOSE) console.log(`[console.${msg.type()}] ${text}`);
  if (text.includes("Godot Engine v")) booted = true;
  if (/SCRIPT ERROR|Parse Error|Failed to load|failed to fetch/i.test(text)) failures.push(text);
});
page.on("pageerror", (err) => failures.push(`page error: ${err.message}`));
page.on("requestfailed", (req) => failures.push(`request failed: ${req.url()} ${req.failure()?.errorText}`));

await page.goto(`http://127.0.0.1:${port}/`);
const deadline = Date.now() + BOOT_TIMEOUT_MS;
while (!booted && failures.length === 0 && Date.now() < deadline) {
  await page.waitForTimeout(500);
}
if (!booted) failures.push("the engine never started (no Godot banner in the console)");
// Give the title screen a few seconds to fade in, then look at the canvas.
await page.waitForTimeout(6000);
const status = await page.evaluate(() => {
  const el = document.getElementById("status");
  return el && getComputedStyle(el).display !== "none" && getComputedStyle(el).visibility !== "hidden" ? el.innerText : "";
});
if (status.trim()) failures.push(`the loading screen is still up: ${status.trim()}`);
const png = await page.screenshot();
if (shot) fs.writeFileSync(shot, png);
// A drawn title has many colours; a blank or error page has one or two.
const colours = await page.evaluate(async (b64) => {
  const img = new Image();
  img.src = `data:image/png;base64,${b64}`;
  await img.decode();
  const c = document.createElement("canvas");
  c.width = img.width;
  c.height = img.height;
  const g = c.getContext("2d");
  g.drawImage(img, 0, 0);
  const data = g.getImageData(0, 0, c.width, c.height).data;
  const seen = new Set();
  for (let i = 0; i < data.length; i += 4 * 97) seen.add((data[i] << 16) | (data[i + 1] << 8) | data[i + 2]);
  return seen.size;
}, png.toString("base64"));
if (colours < 12) failures.push(`the screen looks blank (${colours} colours)`);
await browser.close();
server.close();

if (failures.length) {
  for (const f of failures) console.error(`FAIL: ${f}`);
  console.error("WEB BUILD CHECK FAILED");
  process.exit(1);
}
console.log(`WEB BUILD CHECK PASSED (title drawn, ${colours} colours)`);
