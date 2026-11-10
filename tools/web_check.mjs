#!/usr/bin/env node
// Boots the web build in headless Chromium and fails if it doesn't reach the
// title screen. CI runs it after every web export:
//     node tools/web_check.mjs export/web [screenshot.png]
// With --perf it runs the "Web perf" export instead (tests/web_perf.gd):
//     node tools/web_check.mjs export/web_perf --perf out_dir
// which tours the heavy rooms, saves a table (perf.md) and a few
// screenshots in out_dir, and fails on errors or on a room far slower
// than the overworld screens measured beside it.
// It serves the folder over HTTP (browsers won't run Godot from file://),
// waits for the engine to start, watches the console for script errors, and
// checks the canvas has actually drawn something (not a blank or error page).
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const args = process.argv.slice(2);
const PERF = args.includes("--perf");
const rest = args.filter((a) => a !== "--perf");
const dir = path.resolve(rest[0] || "export/web");
const shot = PERF ? "" : rest[1] || "";
const outDir = PERF ? path.resolve(rest[1] || "web_perf") : "";
// How many times slower than the overworld screens a room may run. The
// browser here draws in software, so only the comparison is meaningful.
const SLOWER_LIMIT = 2.0;
const PERF_TIMEOUT_MS = 15 * 60 * 1000;
const BOOT_TIMEOUT_MS = 90000;
const TYPES = {
  ".html": "text/html", ".js": "application/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".json": "application/json",
};

function serve() {
  const server = http.createServer((req, res) => {
    let file;
    try {
      const url = decodeURIComponent((req.url || "/").split("?")[0]);
      file = path.join(dir, url === "/" ? "index.html" : url);
    } catch {
      file = "";
    }
    if (!file || !file.startsWith(dir + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
      res.writeHead(404);
      res.end();
      return;
    }
    res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
    fs.createReadStream(file).on("error", () => res.destroy()).pipe(res);
  });
  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

const failures = [];
const server = await serve();
const port = server.address().port;
const browser = await chromium.launch({ args: ["--autoplay-policy=no-user-gesture-required", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1152, height: 648 } });
let booted = false;
let perfDone = false;
const perfRows = [];
const shotsWanted = [];
page.on("console", (msg) => {
  const text = msg.text();
  if (process.env.WEB_CHECK_VERBOSE) console.log(`[console.${msg.type()}] ${text}`);
  if (text.includes("Godot Engine v")) booted = true;
  let m;
  if ((m = /^WEB PERF ROW (\S+) (\S+) (\S+) (\S+) (\S+) (\d+) (\d+)/.exec(text))) {
    perfRows.push({ room: m[1], area: m[2], avg: +m[3], worst: +m[4], calls: +m[5], lights: +m[6], nodes: +m[7] });
  }
  if ((m = /^WEB PERF SHOT ([a-z0-9_]+)$/.exec(text))) shotsWanted.push(m[1]);
  if (text.startsWith("WEB PERF DONE")) perfDone = true;
  if (/SCRIPT ERROR|Parse Error|Failed to load|failed to fetch/i.test(text) || /^(USER )?ERROR:/.test(text)) failures.push(text);
});
page.on("pageerror", (err) => failures.push(`page error: ${err.message}`));
page.on("requestfailed", (req) => failures.push(`request failed: ${req.url()} ${req.failure()?.errorText}`));

await page.goto(`http://127.0.0.1:${port}/`);
const deadline = Date.now() + BOOT_TIMEOUT_MS;
while (!booted && failures.length === 0 && Date.now() < deadline) {
  await page.waitForTimeout(500);
}
if (!booted) failures.push("the engine never started (no Godot banner in the console)");
if (PERF && booted) {
  await runPerf();
  await browser.close();
  server.close();
  finish(`WEB PERF CHECK PASSED (${perfRows.length} rooms)`);
}
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
const colours = await colourCount(png);
if (colours < 12) failures.push(`the screen looks blank (${colours} colours)`);
await browser.close();
server.close();
finish(`WEB BUILD CHECK PASSED (title drawn, ${colours} colours)`);

function finish(passed) {
  if (failures.length) {
    for (const f of failures) console.error(`FAIL: ${f}`);
    console.error(PERF ? "WEB PERF CHECK FAILED" : "WEB BUILD CHECK FAILED");
    process.exit(1);
  }
  console.log(passed);
  process.exit(0);
}

// How many colours a screenshot has: a drawn screen has many, a blank or
// error page one or two.
async function colourCount(png) {
  return page.evaluate(async (b64) => {
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
}

// Waits for tests/web_perf.gd to tour its rooms, taking the screenshots it
// asks for, then writes the table and compares each room with the overworld.
async function runPerf() {
  fs.mkdirSync(outDir, { recursive: true });
  const end = Date.now() + PERF_TIMEOUT_MS;
  while (!perfDone && failures.length === 0 && Date.now() < end) {
    while (shotsWanted.length) {
      const name = shotsWanted.shift();
      await page.waitForTimeout(400);
      const png = await page.screenshot();
      fs.writeFileSync(path.join(outDir, `${name}.png`), png);
      const seen = await colourCount(png);
      if (seen < 12) failures.push(`the ${name} screenshot looks blank (${seen} colours)`);
    }
    await page.waitForTimeout(250);
  }
  if (!perfDone && failures.length === 0) failures.push("the perf tour never finished");
  const rows = [...perfRows].sort((a, b) => b.avg - a.avg);
  const base = rows.filter((r) => r.area === "overworld").map((r) => r.avg).sort((a, b) => a - b);
  const baseline = base.length ? base[Math.floor(base.length / 2)] : 0;
  const lines = [
    `Overworld baseline: ${baseline.toFixed(1)} ms a frame (software drawing; a real GPU is much faster).`,
    "",
    "| Room | Area | Frame avg ms | vs overworld | Frame worst ms | Draw calls | Lights | Nodes |",
    "|---|---|---:|---:|---:|---:|---:|---:|",
    ...rows.map((r) => `| ${r.room} | ${r.area} | ${r.avg.toFixed(1)} | ${baseline ? (r.avg / baseline).toFixed(2) + "x" : "-"} | ${r.worst.toFixed(1)} | ${r.calls} | ${r.lights} | ${r.nodes} |`),
  ];
  fs.writeFileSync(path.join(outDir, "perf.md"), lines.join("\n") + "\n");
  console.log(lines.join("\n"));
  if (!baseline) failures.push("no overworld screens were measured to compare with");
  for (const r of rows) {
    if (baseline && r.avg > baseline * SLOWER_LIMIT) failures.push(`room ${r.room} (${r.area}) runs ${(r.avg / baseline).toFixed(2)}x slower than the overworld (limit ${SLOWER_LIMIT}x)`);
  }
}
