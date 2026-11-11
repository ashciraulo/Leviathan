#!/usr/bin/env node
// Boots the web build in headless Chromium and fails if it doesn't reach the
// title screen. CI runs it after every web export:
//     node tools/web_check.mjs export/web [screenshot.png]
// With --perf it runs the "Web perf" export instead (tests/web_perf.gd):
//     node tools/web_check.mjs export/web_perf --perf out_dir
// which tours every room, saves a table (perf.md) and a few
// screenshots in out_dir, and fails on errors or on a room far slower
// than the overworld screens measured beside it.
// It serves the folder over HTTP (browsers won't run Godot from file://),
// waits for the engine to start, watches the console for script errors, and
// checks the canvas has actually drawn something (not a blank or error page).
// Then it opens the game again on a phone-sized touch screen: the game has to
// fill the screen's height, a touch has to bring up the on-screen controls
// (web/touch.html), and the stick has to press the arrow keys. Last, a save
// goes in through Import on the file select (tests/web_save.json), survives
// a reload, and comes back out through Export the same.
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
const PERF_TIMEOUT_MS = 40 * 60 * 1000;
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
page.on("crash", () => failures.push("the browser tab crashed"));
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
if (failures.length === 0) await phoneCheck();
if (failures.length === 0) await saveCheck();
await browser.close();
server.close();
finish(`WEB BUILD CHECK PASSED (title drawn, ${colours} colours; touch controls and save import/export work)`);

async function saveCheck() {
  const ctx = await browser.newContext({ viewport: { width: 1152, height: 648 }, acceptDownloads: true });
  const tab = await ctx.newPage();
  tab.on("pageerror", (err) => failures.push(`saves: page error: ${err.message}`));
  let picker = null;
  tab.on("filechooser", (f) => { picker = f; });
  const boot = async () => {
    let up = false;
    const seen = (msg) => { if (msg.text().includes("Godot Engine v")) up = true; };
    tab.on("console", seen);
    const until = Date.now() + BOOT_TIMEOUT_MS;
    while (!up && Date.now() < until) await tab.waitForTimeout(500);
    tab.off("console", seen);
    // The title says when its menu takes keys (slow CI can take a while to
    // get there); a key pressed before that could be lost.
    let ready = false;
    while (up && !ready && Date.now() < until + 60000) {
      ready = await tab.evaluate(() => window.__lvTitleReady === true).catch(() => false);
      if (!ready) await tab.waitForTimeout(250);
    }
    await tab.waitForTimeout(ready ? 500 : 6000);
    return up;
  };
  // CI draws in software at a few frames a second: hold each key for a
  // couple of frames and leave room between presses and screens.
  const key = async (k, n = 1) => {
    for (let i = 0; i < n; i++) {
      await tab.keyboard.down(k);
      await tab.waitForTimeout(150);
      await tab.keyboard.up(k);
      await tab.waitForTimeout(450);
    }
  };
  // The title's logo is bright; the file select dims it behind dark cards.
  const onFiles = async () => (await brightness(await tab.screenshot({ clip: { x: 300, y: 70, width: 550, height: 120 } }))) < 70;
  // Enter on Journeys (or Continue's neighbour) until the file select is up:
  // the title only takes keys once its menu has faded in.
  const openFiles = async (downs) => {
    for (let tries = 0; tries < 6; tries++) {
      await key("ArrowDown", downs);
      await key("Enter");
      for (let i = 0; i < 10; i++) {
        if (await onFiles()) { await tab.waitForTimeout(800); return true; }
        await tab.waitForTimeout(500);
      }
      await key("ArrowUp", downs);
    }
    return false;
  };
  // The file select's buttons, from the left: Copy, Erase, Export, Import, Back.
  const button = async (index) => { await key("ArrowDown", 3); await key("ArrowLeft", 4); await key("ArrowRight", index); };
  await tab.goto(`http://127.0.0.1:${port}/`);
  if (!(await boot())) return failures.push("saves: the engine never started");
  if (!(await openFiles(0))) return failures.push("saves: Journeys didn't open the file select");
  await button(3);
  await key("k"); // Import, into File 1
  await key("k");
  for (let i = 0; i < 60 && !picker; i++) await tab.waitForTimeout(250);
  if (!picker) {
    // What the page saw, and a picture of the menu, for working out why.
    const seen = await tab.evaluate(() => JSON.stringify({ importing: window.__lvImport, active: navigator.userActivation && navigator.userActivation.isActive }));
    fs.writeFileSync("web_saves.png", await tab.screenshot());
    return failures.push(`saves: Import didn't open the browser's file picker (${seen}; see web_saves.png)`);
  }
  const original = fs.readFileSync(path.resolve("tests/web_save.json"), "utf8");
  await picker.setFiles({ name: "web_save.json", mimeType: "application/json", buffer: Buffer.from(original) });
  // Wait until the browser's storage holds the file (Godot copies user://
  // there a moment after a save is written), then give it a little longer.
  const stored = () => tab.evaluate(() => new Promise((done) => {
    const open = indexedDB.open("/userfs");
    open.onerror = () => done(false);
    open.onsuccess = () => {
      try {
        const db = open.result;
        const keys = db.transaction("FILE_DATA", "readonly").objectStore("FILE_DATA").getAllKeys();
        keys.onsuccess = () => { done(keys.result.some((k) => String(k).endsWith("/save_0.json"))); db.close(); };
        keys.onerror = () => done(false);
      } catch (e) { done(false); }
    };
  }));
  let kept = false;
  for (let i = 0; i < 40 && !(kept = await stored()); i++) await tab.waitForTimeout(250);
  if (!kept) return failures.push("saves: the imported file never reached the browser's storage");
  await tab.waitForTimeout(500);
  // Saves live in the browser's storage: a reload still has the file.
  await tab.reload();
  if (!(await boot())) return failures.push("saves: the engine didn't start again after a reload");
  // With a save the title starts on Continue; Journeys is next.
  if (!(await openFiles(1))) return failures.push("saves: after a reload, Journeys didn't open the file select");
  await button(2);
  await key("k"); // Export; the file select starts on the latest file
  const download = tab.waitForEvent("download", { timeout: 8000 }).catch(() => null);
  await key("k");
  const got = await download;
  if (!got) return failures.push("saves: Export didn't download the file (did Import keep it?)");
  const back = JSON.parse(fs.readFileSync(await got.path(), "utf8"));
  if (JSON.stringify(back.state) !== JSON.stringify(JSON.parse(original).state)) failures.push("saves: the exported file isn't the one imported");
  await ctx.close();
}

async function phoneCheck() {
  const ctx = await browser.newContext({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true });
  const phone = await ctx.newPage();
  phone.on("pageerror", (err) => failures.push(`phone: page error: ${err.message}`));
  await phone.addInitScript(() => {
    window.__keys = [];
    window.__ups = [];
    addEventListener("keydown", (e) => window.__keys.push(e.code), true);
    addEventListener("keyup", (e) => window.__ups.push(e.code), true);
  });
  let up = false;
  phone.on("console", (msg) => { if (msg.text().includes("Godot Engine v")) up = true; });
  await phone.goto(`http://127.0.0.1:${port}/`);
  const until = Date.now() + BOOT_TIMEOUT_MS;
  while (!up && Date.now() < until) await phone.waitForTimeout(500);
  if (!up) return failures.push("phone: the engine never started");
  await phone.waitForTimeout(6000);
  // At whole-number scaling the game would sit at 1x, leaving the bottom of a
  // 390-pixel-high screen black; scaled to fit, the whale and menu reach it.
  const low = await phone.screenshot({ clip: { x: 200, y: 340, width: 444, height: 46 } });
  const lowColours = await colourCount(low);
  if (lowColours < 3) failures.push(`phone: the game doesn't fill the screen (${lowColours} colours at the bottom)`);
  const cdp = await ctx.newCDPSession(phone);
  const touch = (type, x, y) => cdp.send("Input.dispatchTouchEvent", { type, touchPoints: type === "touchEnd" ? [] : [{ x, y, id: 1 }] });
  await touch("touchStart", 420, 200);
  await touch("touchEnd");
  await phone.waitForTimeout(300);
  if (!(await phone.$("#lv-touch.on"))) return failures.push("phone: a touch didn't bring up the on-screen controls");
  // The stick's centre, then a lean to the right.
  const pad = await phone.evaluate(() => { const r = document.getElementById("lv-pad").getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; });
  await touch("touchStart", pad[0], pad[1]);
  await touch("touchMove", pad[0] + 50, pad[1]);
  await phone.waitForTimeout(200);
  await touch("touchEnd");
  const keys = await phone.evaluate(() => window.__keys);
  if (!keys.includes("ArrowRight")) failures.push(`phone: the stick didn't press Right (${keys.join(" ") || "no keys"})`);
  // And the game itself answers a button: K on the title opens the file
  // select, which dims the logo behind dark cards.
  for (let i = 0; i < 240 && !(await phone.evaluate(() => window.__lvTitleReady === true).catch(() => false)); i++) await phone.waitForTimeout(250);
  const logo = async () => brightness(await phone.screenshot({ clip: { x: 255, y: 42, width: 330, height: 72 } }));
  const before = await logo();
  const k = await phone.evaluate(() => { const b = [...document.querySelectorAll("#lv-touch .b")].find((e) => e.textContent === "K"); if (!b) return null; const r = b.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; });
  if (!k) { await ctx.close(); return failures.push("phone: the K button is missing from the on-screen controls"); }
  let after = before;
  for (let tries = 0; tries < 4 && after > before * 0.75; tries++) {
    await touch("touchStart", k[0], k[1]);
    await phone.waitForTimeout(200);
    await touch("touchEnd");
    for (let i = 0; i < 10 && after > before * 0.75; i++) { await phone.waitForTimeout(500); after = await logo(); }
  }
  if (after > before * 0.75) failures.push(`phone: tapping K on the title didn't open the file select (logo brightness ${before.toFixed(0)} -> ${after.toFixed(0)})`);
  // A remapped action: the game tells the page, and the button follows.
  const remapped = await phone.evaluate(() => {
    window.__lvBind = { KeyJ: ["KeyL", "L"] };
    window.__lvRelabel();
    window.__keys = [];
    const b = [...document.querySelectorAll("#lv-touch .b")].find((e) => e.getAttribute("data-code") === "KeyJ");
    const r = b.getBoundingClientRect();
    return [b.textContent, r.left + r.width / 2, r.top + r.height / 2];
  });
  await touch("touchStart", remapped[1], remapped[2]);
  // A rebind while the button is held (the controls screen takes this very
  // press): the release must still let go of the key that went down.
  await phone.evaluate(() => { window.__lvBind = {}; window.__ups = []; });
  await touch("touchEnd");
  const sent = await phone.evaluate(() => [window.__keys, window.__ups]);
  if (remapped[0] !== "L" || !sent[0].includes("KeyL")) failures.push(`phone: the sword button didn't follow a remap to L (shows ${remapped[0]}, sent ${sent[0].join(" ") || "nothing"})`);
  if (!sent[1].includes("KeyL")) failures.push(`phone: a button let go of a different key than it pressed (${sent[1].join(" ") || "no key up"})`);
  await ctx.close();
}

function finish(passed) {
  if (failures.length) {
    for (const f of failures) console.error(`FAIL: ${f}`);
    console.error(PERF ? "WEB PERF CHECK FAILED" : "WEB BUILD CHECK FAILED");
    process.exit(1);
  }
  console.log(passed);
  process.exit(0);
}

// The average brightness (0-255) of a screenshot.
async function brightness(png) {
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
    let sum = 0;
    for (let i = 0; i < data.length; i += 4) sum += (data[i] + data[i + 1] + data[i + 2]) / 3;
    return sum / (data.length / 4);
  }, png.toString("base64"));
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
