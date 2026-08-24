/**
 * Zxscript Bundler
 * Compiles modular Luau files into a single, standalone, loadstring-compatible distribution script.
 */

const fs = require('fs');
const path = require('path');

const SRC_DIR = path.join(__dirname, 'src');
const DIST_DIR = path.join(__dirname, 'dist');
const OUTPUT_FILE = path.join(DIST_DIR, 'hub.lua');

function getAllFiles(dirPath, arrayOfFiles = []) {
  const files = fs.readdirSync(dirPath);

  files.forEach((file) => {
    const fullPath = path.join(dirPath, file);
    if (fs.statSync(fullPath).isDirectory()) {
      arrayOfFiles = getAllFiles(fullPath, arrayOfFiles);
    } else if (file.endsWith('.lua')) {
      arrayOfFiles.push(fullPath);
    }
  });

  return arrayOfFiles;
}

function normalizeModuleKey(filePath) {
  const relative = path.relative(SRC_DIR, filePath).replace(/\\/g, '/');
  return relative.replace(/\.lua$/, '');
}

function transformModuleSource(source, moduleKey) {
  // Replace relative requires e.g. require(script.Parent.Parent.core.utils) or require(script.core.config)
  let transformed = source
    .replace(/require\(script\.Parent\.Parent\.core\.([a-zA-Z0-9_]+)\)/g, 'require_module("core/$1")')
    .replace(/require\(script\.Parent\.Parent\.modules\.([a-zA-Z0-9_]+)\)/g, 'require_module("modules/$1")')
    .replace(/require\(script\.Parent\.([a-zA-Z0-9_]+)\)/g, (match, p1) => {
      const parts = moduleKey.split('/');
      parts.pop(); // remove file name
      parts.pop(); // Parent
      return `require_module("${parts.join('/')}${parts.length ? '/' : ''}${p1}")`;
    })
    .replace(/require\(script\.core\.([a-zA-Z0-9_]+)\)/g, 'require_module("core/$1")')
    .replace(/require\(script\.modules\.([a-zA-Z0-9_]+)\)/g, 'require_module("modules/$1")')
    .replace(/require\(script\.games\.([a-zA-Z0-9_]+)\)/g, 'require_module("games/$1")');

  return transformed;
}

function build() {
  console.log('[Build] Starting Roblox Script Hub bundling...');
  
  if (!fs.existsSync(DIST_DIR)) {
    fs.mkdirSync(DIST_DIR, { recursive: true });
  }

  const luaFiles = getAllFiles(SRC_DIR);
  const modules = {};
  let initSource = '';

  luaFiles.forEach((file) => {
    const key = normalizeModuleKey(file);
    const rawContent = fs.readFileSync(file, 'utf8');

    if (key === 'init') {
      initSource = transformModuleSource(rawContent, key);
    } else if (key !== 'loader') {
      modules[key] = transformModuleSource(rawContent, key);
    }
  });

  let bundle = `--[[\n    Zxscript - Bundled Standalone Distribution\n    Generated: ${new Date().toISOString()}\n]]\n\n`;
  bundle += `local __modules = {}\nlocal __cache = {}\n\n`;
  bundle += `local function require_module(name)\n`;
  bundle += `    if __cache[name] then return __cache[name] end\n`;
  bundle += `    local mod = __modules[name]\n`;
  bundle += `    if not mod then error("[Bundle Error] Module not found: " .. tostring(name)) end\n`;
  bundle += `    local result = mod()\n`;
  bundle += `    __cache[name] = result\n`;
  bundle += `    return result\n`;
  bundle += `end\n\n`;

  // Register Modules
  Object.keys(modules).forEach((key) => {
    bundle += `----------------------------------------------------------------------\n`;
    bundle += `-- MODULE: ${key}\n`;
    bundle += `----------------------------------------------------------------------\n`;
    bundle += `__modules["${key}"] = function()\n`;
    bundle += modules[key]
      .split('\n')
      .map(line => '    ' + line)
      .join('\n');
    bundle += `\nend\n\n`;
  });

  // Main Script & Game Finder Bridge
  bundle += `----------------------------------------------------------------------\n`;
  bundle += `-- MAIN INITIALIZER\n`;
  bundle += `----------------------------------------------------------------------\n`;

  // Mock script.games finder inside initSource
  let finalInit = initSource.replace(
    /local gameModule = script\.games:FindFirstChild\(gameModuleName\) or script\.games:FindFirstChild\("universal"\)/g,
    'local gameModuleNameKey = "games/" .. gameModuleName\n    local gameModule = __modules[gameModuleNameKey] and gameModuleNameKey or "games/universal"'
  ).replace(
    /return require\(gameModule\)/g,
    'return require_module(gameModule)'
  );

  bundle += `do\n`;
  bundle += finalInit
    .split('\n')
    .map(line => '    ' + line)
    .join('\n');
  bundle += `\nend\n`;

  fs.writeFileSync(OUTPUT_FILE, bundle, 'utf8');
  console.log(`[Build] Successfully compiled ${luaFiles.length} files to: ${OUTPUT_FILE} (${fs.statSync(OUTPUT_FILE).size} bytes)`);
}

build();

if (process.argv.includes('--watch')) {
  console.log('[Watch] Watching for changes in src/...');
  fs.watch(SRC_DIR, { recursive: true }, (eventType, filename) => {
    if (filename && filename.endsWith('.lua')) {
      console.log(`[Watch] File changed: ${filename}, rebuilding...`);
      build();
    }
  });
}
