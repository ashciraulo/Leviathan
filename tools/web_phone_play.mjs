// Plays the web build on a phone-sized touch screen, by touch only: title,
// new game, walk, swing, hum, pause, map. Screenshots each step.
//   NODE_PATH=$(npm root -g) node tools/web_phone_play.mjs export/web out_dir [cpuRate]
// cpuRate > 1 throttles the page's CPU (CDP) as a low-end phone stand-in, and
// a rAF counter reports frames per second at each step.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const dir = path.resolve(process.argv[2]);
const out = path.resolve(process.argv[3]);
const rate = +(process.argv[4] || 1);
fs.mkdirSync(out, { recursive: true });
const TYPES = { ".html": "text/html", ".js": "application/javascript", ".wasm": "application/wasm", ".pck": "application/octet-stream", ".png": "image/png" };
const server = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || "/").split("?")[0]);
  const file = path.join(dir, url === "/" ? "index.html" : url);
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const port = server.address().port;
const browser = await chromium.launch({ args: ["--autoplay-policy=no-user-gesture-required", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
const ctx = await browser.newContext({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true, deviceScaleFactor: 2 });
const page = await ctx.newPage();
const errors = [];
const log = [];
let up = false;
page.on("console", (m) => {
  const t = m.text();
  if (t.includes("Godot Engine v")) up = true;
  if (/SCRIPT ERROR|^(USER )?ERROR:/.test(t)) errors.push(t);
  log.push(t);
});
page.on("pageerror", (e) => errors.push(`page error: ${e.message}`));
await page.addInitScript(() => {
  window.__frames = 0;
  const tick = () => { window.__frames++; requestAnimationFrame(tick); };
  requestAnimationFrame(tick);
});
const cdp = await ctx.newCDPSession(page);
if (rate > 1) await cdp.send("Emulation.setCPUThrottlingRate", { rate });
const t0 = Date.now();
await page.goto(`http://127.0.0.1:${port}/`);
while (!up && Date.now() - t0 < 180000) await page.waitForTimeout(250);
const bootMs = Date.now() - t0;
for (let i = 0; i < 480 && !(await page.evaluate(() => window.__lvTitleReady === true).catch(() => false)); i++) await page.waitForTimeout(250);
const titleMs = Date.now() - t0;
const touch = (type, x, y, id = 1) => cdp.send("Input.dispatchTouchEvent", { type, touchPoints: type === "touchEnd" ? [] : [{ x, y, id }] });
const fps = async (ms = 3000) => {
  const a = await page.evaluate(() => window.__frames);
  await page.waitForTimeout(ms);
  const b = await page.evaluate(() => window.__frames);
  return ((b - a) * 1000) / ms;
};
const btn = (label) => page.evaluate((l) => {
  const b = [...document.querySelectorAll("#lv-touch .b, #lv-touch [data-code]")].find((e) => e.textContent.trim() === l);
  if (!b) return null;
  const r = b.getBoundingClientRect();
  return [r.left + r.width / 2, r.top + r.height / 2];
}, label);
const tap = async (label, hold = 150) => {
  const p = await btn(label);
  if (!p) { errors.push(`no ${label} button`); return; }
  await touch("touchStart", p[0], p[1]);
  await page.waitForTimeout(hold);
  await touch("touchEnd");
  await page.waitForTimeout(250);
};
const stick = async (dx, dy, ms) => {
  const pad = await page.evaluate(() => { const r = document.getElementById("lv-pad").getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; });
  await touch("touchStart", pad[0], pad[1]);
  await touch("touchMove", pad[0] + dx * 50, pad[1] + dy * 50);
  await page.waitForTimeout(ms);
  await touch("touchEnd");
};
const rows = [];
const step = async (name) => {
  await page.screenshot({ path: path.join(out, `${name}.png`) });
  const f = await fps(2000);
  rows.push(`${name}: ${f.toFixed(1)} fps`);
  console.log(`${name}: ${f.toFixed(1)} fps`);
};
console.log(`boot ${bootMs} ms, title ready ${titleMs} ms`);
// Wake the touch controls, then the title.
await touch("touchStart", 420, 200);
await touch("touchEnd");
await page.waitForTimeout(500);
await step("01_title");
await tap("K");
await page.waitForTimeout(1500);
await step("02_file_select");
await tap("K");
await page.waitForTimeout(3000);
await step("03_after_slot");
// Through the opening: K advances text.
for (let i = 0; i < 40; i++) { await tap("K"); await page.waitForTimeout(400); }
await step("04_opening_done");
await stick(1, 0, 1500);
await step("05_walked_right");
await stick(0, 1, 1200);
await tap("J");
await page.waitForTimeout(80);
await step("06_sword");
await tap("H", 1500);
await step("07_hum");
await tap("Esc");
await page.waitForTimeout(800);
await step("08_pause");
await tap("E");
await page.waitForTimeout(600);
await step("09_pause_next_tab");
await tap("Esc");
await page.waitForTimeout(600);
await tap("M");
await page.waitForTimeout(800);
await step("10_map");
await tap("M");
await page.waitForTimeout(600);
await stick(-1, -1, 2000);
await step("11_walk_back");
fs.writeFileSync(path.join(out, "result.txt"), [`cpu rate ${rate}`, `boot ${bootMs} ms, title ready ${titleMs} ms`, ...rows, `errors: ${errors.length}`, ...errors].join("\n") + "\n");
console.log(`errors: ${errors.length}`);
for (const e of errors) console.log(e);
await browser.close();
server.close();
