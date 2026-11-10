#!/usr/bin/env node
// Runs a performance survey (tests/perf_rooms.tscn or tests/perf_slides.tscn)
// inside the real web build, in headless Chromium, and prints its table.
//     node tools/web_perf.mjs res://tests/perf_slides.tscn
// Release web builds can't take a scene on the command line, so this exports
// a throwaway web build (tests included, the survey as main scene) to
// export/web_perf/ and puts project.godot and export_presets.cfg back after.
// Needs the 4.7.2 web_nothreads_release template installed, like CI's.
// Chromium here draws WebGL in software (SwiftShader), so compare rooms with
// each other, not with the 16.7 ms budget.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const scene = process.argv[2] || "res://tests/perf_rooms.tscn";
const godot = process.env.GODOT || "godot";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const dir = path.join(root, "export", "web_perf");
const TIMEOUT_MS = 1800000;

const project = path.join(root, "project.godot");
const presets = path.join(root, "export_presets.cfg");
const keep = [fs.readFileSync(project, "utf8"), fs.readFileSync(presets, "utf8")];
try {
  fs.writeFileSync(project, keep[0].replace(/^run\/main_scene=.*$/m, `run/main_scene="${scene}"`));
  fs.writeFileSync(presets, keep[1].replace(/exclude_filter="tests\/\*, /g, 'exclude_filter="'));
  fs.mkdirSync(dir, { recursive: true });
  execFileSync(godot, ["--headless", "--path", root, "--export-release", "Web", path.join(dir, "index.html")], { stdio: "ignore" });
} finally {
  fs.writeFileSync(project, keep[0]);
  fs.writeFileSync(presets, keep[1]);
}

const TYPES = { ".html": "text/html", ".js": "application/javascript", ".wasm": "application/wasm" };
const server = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || "/").split("?")[0]);
  const file = path.join(dir, url === "/" ? "index.html" : url);
  if (!file.startsWith(dir + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    res.writeHead(404);
    res.end();
    return;
  }
  res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
  fs.createReadStream(file).pipe(res);
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const browser = await chromium.launch({ args: ["--autoplay-policy=no-user-gesture-required", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1152, height: 648 } });
let done = false;
let table = false;
page.on("console", (msg) => {
  const text = msg.text();
  if (/^(room|from) /.test(text)) table = true;
  if (table || /ERROR/.test(text)) console.log(text);
  if (/^PERF \w+ DONE/.test(text)) done = true;
});
page.on("pageerror", (err) => console.log(`page error: ${err.message}`));
await page.goto(`http://127.0.0.1:${server.address().port}/`);
const deadline = Date.now() + TIMEOUT_MS;
while (!done && Date.now() < deadline) await new Promise((r) => setTimeout(r, 1000));
await browser.close();
server.close();
process.exit(done ? 0 : 1);
