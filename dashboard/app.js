/**
 * Steal an Egg - PC Predictor & Tracker Application Logic
 * Manages live egg spawn history, timer countdowns, audio notifications, and rarity filters.
 */

document.addEventListener('DOMContentLoaded', () => {
    let activeFilter = 'All';
    let soundEnabled = true;
    let spawnLogs = [];
    let stats = { total: 0, eternal: 0, secret: 0, divine: 0 };

    // DOM Elements
    const spawnFeedBody = document.getElementById('spawnFeedBody');
    const timerMin = document.getElementById('timerMin');
    const timerSec = document.getElementById('timerSec');
    const soundToggleBtn = document.getElementById('soundToggleBtn');
    const clearLogBtn = document.getElementById('clearLogBtn');

    const statTotal = document.getElementById('statTotal');
    const statEternal = document.getElementById('statEternal');
    const statSecret = document.getElementById('statSecret');
    const statDivine = document.getElementById('statDivine');

    // Audio Alert Synth using Web Audio API (No external mp3 assets needed)
    function playAudioAlert(rarity) {
        if (!soundEnabled) return;
        try {
            const ctx = new (window.AudioContext || window.webkitAudioContext)();
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();

            osc.type = rarity === 'Eternal' ? 'sawtooth' : 'sine';
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

    // Add Egg Spawn Entry to Log Table
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
        statTotal.textContent = stats.total;
        statEternal.textContent = stats.eternal;
        statSecret.textContent = stats.secret;
        statDivine.textContent = stats.divine;
    }

    function renderTable() {
        spawnFeedBody.innerHTML = '';

        const filtered = spawnLogs.filter(log => {
            if (activeFilter === 'All') return true;
            return log.rarity === activeFilter;
        });

        if (filtered.length === 0) {
            spawnFeedBody.innerHTML = `
                <tr>
                    <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 24px;">
                        No ${activeFilter === 'All' ? '' : activeFilter} egg spawns recorded yet. Waiting for live events...
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
                    <button class="btn btn-secondary btn-sm" onclick="alert('Spawn coordinates: ${log.location}')">
                        Inspect
                    </button>
                </td>
            `;
            spawnFeedBody.appendChild(tr);
        });
    }

    // Countdown Timer Loop (Simulates wave countdown)
    let countdownSeconds = 300; // 5 minutes initial
    setInterval(() => {
        countdownSeconds--;
        if (countdownSeconds <= 0) {
            countdownSeconds = Math.floor(Math.random() * 120) + 180; // Reset between 3-5 min
            triggerRandomPredictedSpawn();
        }

        const m = Math.floor(countdownSeconds / 60);
        const s = countdownSeconds % 60;

        timerMin.textContent = String(m).padStart(2, '0');
        timerSec.textContent = String(s).padStart(2, '0');
    }, 1000);

    // Initial Mock & Live Generator for demonstration
    const sampleEggTypes = [
        { name: "Golden Phoenix Egg", rarity: "Eternal", location: "Volcano Peak (Zone 4)", prob: "99.4%" },
        { name: "Celestial Dragon Egg", rarity: "Secret", location: "Sky Realm (Zone 3)", prob: "98.1%" },
        { name: "Abyssal Pearl Egg", rarity: "Divine", location: "Deep Cave (Zone 2)", prob: "96.5%" },
        { name: "Shadow Strike Egg", rarity: "Mythic", location: "Forest Grove (Zone 1)", prob: "95.0%" },
        { name: "Sunfire Crystal Egg", rarity: "Legendary", location: "Main Plaza", prob: "99.0%" }
    ];

    function triggerRandomPredictedSpawn() {
        const item = sampleEggTypes[Math.floor(Math.random() * sampleEggTypes.length)];
        const timeStr = new Date().toLocaleTimeString();

        addEggSpawnLog({
            time: timeStr,
            rarity: item.rarity,
            name: item.name,
            location: item.location,
            probability: item.prob
        });
    }

    // Seed initial historical records
    triggerRandomPredictedSpawn();
    setTimeout(triggerRandomPredictedSpawn, 1200);

    // Event Listeners
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            activeFilter = btn.dataset.filter;
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
