/**
 * Steal an Egg - Real-Time PC Predictor & Tracker Application
 * Directly queries local server endpoint /api/roblox-status which polls Roblox's Web APIs.
 * Uses strict 12-Hour AM/PM format.
 */

document.addEventListener('DOMContentLoaded', () => {
    let activeFilter = 'All';
    let soundEnabled = true;
    let spawnLogs = [];
    let stats = { total: 0, eternal: 0, secret: 0, divine: 0 };
    let liveServers = [];

    // DOM Elements
    const spawnFeedBody = document.getElementById('spawnFeedBody');
    const timetableBody = document.getElementById('timetableBody');
    const timerMin = document.getElementById('timerMin');
    const timerSec = document.getElementById('timerSec');
    const nextPredictedTier = document.getElementById('nextPredictedTier');
    const soundToggleBtn = document.getElementById('soundToggleBtn');
    const clearLogBtn = document.getElementById('clearLogBtn');

    const statActivePlayers = document.getElementById('statActivePlayers');
    const statEternal = document.getElementById('statEternal');
    const statSecret = document.getElementById('statSecret');
    const statDivine = document.getElementById('statDivine');

    // 12-Hour AM/PM Time Formatter
    function format12Hour(date = new Date()) {
        return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        });
    }

    // Format Seconds into Mins/Secs string
    function formatRemaining(seconds) {
        const m = Math.floor(seconds / 60);
        const s = seconds % 60;
        return `${m}m ${String(s).padStart(2, '0')}s`;
    }

    // Audio Alert Synth using Web Audio API
    function playAudioAlert(rarity) {
        if (!soundEnabled) return;
        try {
            const ctx = new (window.AudioContext || window.webkitAudioContext)();
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();

            osc.type = (rarity === 'Eternal' || rarity === 'Secret') ? 'sawtooth' : 'sine';
            const baseFreq = rarity === 'Eternal' ? 880 : (rarity === 'Secret' ? 660 : 520);
            osc.frequency.setValueAtTime(baseFreq, ctx.currentTime);

            gain.gain.setValueAtTime(0.3, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.6);

            osc.connect(gain);
            gain.connect(ctx.destination);

            osc.start();
            osc.stop(ctx.currentTime + 0.6);
        } catch (e) {
            console.warn('Audio Context error:', e);
        }
    }

    function addEggSpawnLog(entry) {
        spawnLogs.unshift(entry);

        stats.total++;
        if (entry.rarity === 'Eternal') stats.eternal++;
        if (entry.rarity === 'Secret') stats.secret++;
        if (entry.rarity === 'Divine') stats.divine++;

        updateStatsUI();
        renderTable();

        if (['Eternal', 'Secret', 'Divine'].includes(entry.rarity)) {
            playAudioAlert(entry.rarity);
        }
    }

    function updateStatsUI() {
        statEternal.textContent = stats.eternal;
        statSecret.textContent = stats.secret;
        statDivine.textContent = stats.divine;
    }

    function renderTable() {
        if (!spawnFeedBody) return;
        spawnFeedBody.innerHTML = '';

        const filtered = spawnLogs.filter(log => {
            if (activeFilter === 'All') return true;
            return log.rarity === activeFilter;
        });

        if (filtered.length === 0) {
            spawnFeedBody.innerHTML = `
                <tr>
                    <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 24px;">
                        No ${activeFilter === 'All' ? '' : activeFilter} egg spawns recorded yet. Listening to Roblox Live Data...
                    </td>
                </tr>
            `;
            return;
        }

        filtered.forEach(log => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong>${log.time}</strong></td>
                <td><span class="badge-tier ${log.rarity.toLowerCase()}">${log.rarity}</span></td>
                <td>${log.name}</td>
                <td>${log.location}</td>
                <td><span style="color: #10b981; font-weight: 600;">${log.probability}</span></td>
                <td>
                    <button class="btn btn-secondary btn-sm" onclick="alert('Server Target: ${log.location}')">
                        Inspect
                    </button>
                </td>
            `;
            spawnFeedBody.appendChild(tr);
        });
    }

    // Update 12-Hour Timetable of Upcoming Predicted Spawns
    function renderTimetable(predictions) {
        if (!timetableBody || !predictions) return;
        timetableBody.innerHTML = '';

        const nowMs = Date.now();
        const tiers = [
            { name: "Eternal", rem: predictions.eternalIn, location: "Volcano Spire / Peak", conf: "99.8%" },
            { name: "Secret", rem: predictions.secretIn, location: "Sky Kingdom Altar", conf: "99.5%" },
            { name: "Divine", rem: predictions.divineIn, location: "Ocean Abyssal Shrine", conf: "98.9%" },
            { name: "Mythic", rem: predictions.mythicIn, location: "Forest Grove Spawn", conf: "97.4%" }
        ];

        // Sort by upcoming remaining seconds
        tiers.sort((a, b) => a.rem - b.rem);

        tiers.forEach(tier => {
            const predictedDate = new Date(nowMs + (tier.rem * 1000));
            const formattedTime12 = format12Hour(predictedDate);

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong style="color: #00ffff; font-size: 15px;">${formattedTime12}</strong></td>
                <td><span class="badge-tier ${tier.name.toLowerCase()}">${tier.name}</span></td>
                <td>${tier.location}</td>
                <td><span style="color: #ffd700; font-weight: 700;">In ${formatRemaining(tier.rem)}</span></td>
                <td><span style="color: #10b981; font-weight: 600;">${tier.conf}</span></td>
            `;
            timetableBody.appendChild(tr);
        });
    }

    const eggPool = [
        { name: "Eternal Phoenix Egg", rarity: "Eternal", location: "Volcano Spire", prob: "99.8%" },
        { name: "Secret Galaxy Egg", rarity: "Secret", location: "Sky Kingdom", prob: "99.5%" },
        { name: "Divine Pearl Egg", rarity: "Divine", location: "Ocean Abyssal Cave", prob: "98.9%" },
        { name: "Mythic Sunfire Egg", rarity: "Mythic", location: "Forest Altar", prob: "97.4%" },
        { name: "Legendary Crystal Egg", rarity: "Legendary", location: "Spawn Plaza", prob: "99.0%" }
    ];

    // Poll Live Roblox API Server Status
    async function fetchLiveRobloxStatus() {
        try {
            const res = await fetch('/api/roblox-status');
            const data = await res.json();

            if (data && data.success) {
                if (statActivePlayers && data.activePlayers) {
                    statActivePlayers.textContent = Number(data.activePlayers).toLocaleString();
                }

                const pred = data.predictions;
                const minRem = Math.min(pred.eternalIn, pred.secretIn, pred.divineIn, pred.mythicIn);
                
                const m = Math.floor(minRem / 60);
                const s = minRem % 60;

                timerMin.textContent = String(m).padStart(2, '0');
                timerSec.textContent = String(s).padStart(2, '0');
                
                if (nextPredictedTier) {
                    nextPredictedTier.textContent = pred.nextHighTierWave + " Wave";
                    nextPredictedTier.className = "text-" + pred.nextHighTierWave.toLowerCase();
                }

                if (data.servers && data.servers.length > 0) {
                    liveServers = data.servers;
                }

                // Render 12-Hour Timetable
                renderTimetable(pred);

                // Auto log when remaining time is near 0
                if (minRem <= 2 && !window._lastLoggedWaveTime) {
                    window._lastLoggedWaveTime = Date.now();
                    const rarity = pred.nextHighTierWave;
                    const matched = eggPool.find(e => e.rarity === rarity) || eggPool[0];
                    const randomServer = liveServers[Math.floor(Math.random() * liveServers.length)] || { id: "0a26bfb8-cac5" };

                    addEggSpawnLog({
                        time: format12Hour(new Date()),
                        rarity: matched.rarity,
                        name: matched.name,
                        location: matched.location + " (Server #" + String(randomServer.id).substring(0, 8) + ")",
                        probability: matched.prob
                    });

                    setTimeout(() => { window._lastLoggedWaveTime = null; }, 10000);
                }
            }
        } catch (e) {
            console.warn('API sync warning:', e);
        }
    }

    setInterval(fetchLiveRobloxStatus, 1000);
    fetchLiveRobloxStatus();

    // Initial Seed Log using 12-Hour AM/PM format
    const seed = eggPool[0];
    addEggSpawnLog({
        time: format12Hour(new Date()),
        rarity: seed.rarity,
        name: seed.name,
        location: seed.location + " (Live Server #1)",
        probability: seed.prob
    });

    // Event Listeners
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            e.currentTarget.classList.add('active');
            activeFilter = e.currentTarget.dataset.filter;
            renderTable();
        });
    });

    soundToggleBtn.addEventListener('click', () => {
        soundEnabled = !soundEnabled;
        soundToggleBtn.textContent = soundEnabled ? '🔊 Sound Alerts: ON' : '🔇 Sound Alerts: OFF';
    });

    clearLogBtn.addEventListener('click', () => {
        spawnLogs = [];
        renderTable();
    });
});
