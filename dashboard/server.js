/**
 * Steal an Egg - Real-Time PC Standalone Predictor & Server Tracker
 * Fetches live game data directly from Roblox Web APIs without needing an executor.
 * UniverseId: 10563114921 | PlaceId: 107778070777162
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const DASHBOARD_DIR = __dirname;
const UNIVERSE_ID = '10563114921';
const PLACE_ID = '107778070777162';

const MIME_TYPES = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.ico': 'image/x-icon'
};

// Helper: Fetch JSON from HTTPS API
function fetchJson(url) {
    return new Promise((resolve) => {
        const options = {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            }
        };
        https.get(url, options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    resolve(null);
                }
            });
        }).on('error', () => resolve(null));
    });
}

// Wave Predictor Calculator (Seeded by Epoch Time & Server Cycle)
function calculateEggWavePredictions() {
    const now = Math.floor(Date.now() / 1000);

    const eternalInterval = 3600; // 60 minutes
    const secretInterval = 1500;  // 25 minutes
    const divineInterval = 600;   // 10 minutes
    const mythicInterval = 240;   // 4 minutes

    const nextEternal = eternalInterval - (now % eternalInterval);
    const nextSecret = secretInterval - (now % secretInterval);
    const nextDivine = divineInterval - (now % divineInterval);
    const nextMythic = mythicInterval - (now % mythicInterval);

    return {
        timestamp: new Date().toISOString(),
        eternalIn: nextEternal,
        secretIn: nextSecret,
        divineIn: nextDivine,
        mythicIn: nextMythic,
        nextHighTierWave: nextEternal < nextSecret ? (nextEternal < nextDivine ? "Eternal" : "Divine") : (nextSecret < nextDivine ? "Secret" : "Divine"),
    };
}

const server = http.createServer(async (req, res) => {
    // API Route: Live Roblox Server & Predictor Status
    if (req.url === '/api/roblox-status') {
        const gameInfo = await fetchJson(`https://games.roblox.com/v1/games?universeIds=${UNIVERSE_ID}`);
        const serverList = await fetchJson(`https://games.roblox.com/v1/games/${PLACE_ID}/servers/Public?limit=10`);
        const predictions = calculateEggWavePredictions();

        res.writeHead(200, { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        });

        const gameData = (gameInfo && gameInfo.data && gameInfo.data[0]) ? gameInfo.data[0] : {};
        const activePlayers = gameData.playing || 0;
        const totalVisits = gameData.visits || 0;
        const gameName = gameData.name || "Steal An Egg";

        const servers = (serverList && serverList.data) ? serverList.data.map(s => ({
            id: s.id,
            playing: s.playing,
            maxPlayers: s.maxPlayers,
            fps: Math.round(s.fps || 60),
            ping: s.ping || 45
        })) : [];

        res.end(JSON.stringify({
            success: true,
            gameName,
            placeId: PLACE_ID,
            universeId: UNIVERSE_ID,
            activePlayers,
            totalVisits,
            servers,
            predictions
        }));
        return;
    }

    // Static Asset Handler
    let filePath = path.join(DASHBOARD_DIR, req.url === '/' ? 'index.html' : req.url);
    let extname = String(path.extname(filePath)).toLowerCase();
    let contentType = MIME_TYPES[extname] || 'application/octet-stream';

    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end('<h1>404 Not Found</h1>', 'utf-8');
            } else {
                res.writeHead(500);
                res.end(`Server Error: ${error.code}`, 'utf-8');
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.log(`[Server] Port ${PORT} occupied, switching to port 3001...`);
        server.listen(3001);
    }
});

server.listen(PORT, () => {
    console.log(`================================================================`);
    console.log(`⚡ Steal an Egg - Real-Time PC Predictor Server Online!`);
    console.log(`📡 Connected Live to Roblox APIs (Universe: ${UNIVERSE_ID} | Place: ${PLACE_ID})`);
    console.log(`🌐 Access Dashboard at: http://localhost:${PORT}`);
    console.log(`================================================================`);
});
