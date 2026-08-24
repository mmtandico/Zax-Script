/**
 * Steal an Egg - Real-Time Egg Spawn Predictor Application Logic
 * Aligned with in-game 5-Minute (300-Second) Day/Night Cycle mechanics.
 */

document.addEventListener('DOMContentLoaded', () => {
    let soundEnabled = true;

    // DOM Elements
    const cyclePhaseIcon = document.getElementById('cyclePhaseIcon');
    const cyclePhaseText = document.getElementById('cyclePhaseText');
    const cycleTimerText = document.getElementById('cycleTimerText');

    const nextUpName = document.getElementById('nextUpName');
    const nextUpZone = document.getElementById('nextUpZone');
    const nextUpTime = document.getElementById('nextUpTime');
    const nextUpRelative = document.getElementById('nextUpRelative');

    const secretList = document.getElementById('secretList');
    const eternalList = document.getElementById('eternalList');
    const divineList = document.getElementById('divineList');
    const soundToggleBtn = document.getElementById('soundToggleBtn');

    function format12HourTime(date) {
        let hours = date.getHours();
        let minutes = date.getMinutes();
        const ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12;
        const strMinutes = String(minutes).padStart(2, '0');
        return `${hours}:${strMinutes} ${ampm}`;
    }

    function formatRelativeTime(seconds) {
        if (seconds <= 60) return 'in 1 minute';
        const mins = Math.floor(seconds / 60);
        if (mins < 60) {
            return `in ${mins} minutes`;
        }
        const hours = Math.floor(mins / 60);
        if (hours === 1) return 'in 1 hour';
        return `in ${hours} hours`;
    }

    function formatMinsSecs(seconds) {
        const m = Math.floor(seconds / 60);
        const s = seconds % 60;
        return `${String(m).padStart(2, '0')}m ${String(s).padStart(2, '0')}s`;
    }

    // Official Steal an Egg Zone & Egg Database
    const eggDatabase = {
        Secret: [
            { name: "Tralaledon", zone: "PREHISTORIC", zoneCss: "prehistoric", cycleSec: 2100, offsetSec: 780 },
            { name: "TyrannosaurusRex", zone: "PREHISTORIC", zoneCss: "prehistoric", cycleSec: 8100, offsetSec: 7200 },
            { name: "King Snake (Warden)", zone: "JUNGLE", zoneCss: "jungle", cycleSec: 9000, offsetSec: 8100 },
            { name: "Cave Dragon", zone: "COSMIC", zoneCss: "cosmic", cycleSec: 10200, offsetSec: 9300 },
            { name: "Alien Skeleton Boss", zone: "COSMIC", zoneCss: "cosmic", cycleSec: 11700, offsetSec: 10800 },
            { name: "Cerberus", zone: "VOLCANO", zoneCss: "volcano", cycleSec: 17400, offsetSec: 16500 },
            { name: "Yeti", zone: "SNOW", zoneCss: "snow", cycleSec: 23400, offsetSec: 22500 },
            { name: "Kraken", zone: "ABYSS", zoneCss: "abyss", cycleSec: 33600, offsetSec: 32700 }
        ],
        Eternal: [
            { name: "Oni Tiger", zone: "CHERRY BLOSSOM", zoneCss: "cherry-blossom", cycleSec: 8400, offsetSec: 7500 },
            { name: "Mosasaurus", zone: "PREHISTORIC", zoneCss: "prehistoric", cycleSec: 10500, offsetSec: 9600 },
            { name: "Eternal Lunar Dragon", zone: "COSMIC", zoneCss: "cosmic", cycleSec: 22200, offsetSec: 21300 },
            { name: "Dragon", zone: "VOLCANO", zoneCss: "volcano", cycleSec: 24000, offsetSec: 23100 },
            { name: "El Maja", zone: "ABYSS", zoneCss: "abyss", cycleSec: 32100, offsetSec: 31200 },
            { name: "Ascended Vermilion Phoenix", zone: "VOLCANO", zoneCss: "volcano", cycleSec: 38100, offsetSec: 37200 },
            { name: "Ice Dragon", zone: "SNOW", zoneCss: "snow", cycleSec: 65400, offsetSec: 64500 }
        ],
        Divine: [
            { name: "Kitsune", zone: "CHERRY BLOSSOM", zoneCss: "cherry-blossom", cycleSec: 14400, offsetSec: 13500 },
            { name: "Unicorn", zone: "SPECIAL", zoneCss: "special", cycleSec: 21900, offsetSec: 21000 }
        ]
    };

    function updatePredictor() {
        const nowMs = Date.now();
        const nowSec = Math.floor(nowMs / 1000);

        // 5-Minute (300s) Day/Night Cycle Status
        const cycleSec = nowSec % 300;
        const isNight = cycleSec >= 180; // Night phase starts at 3m (180s)
        const nextNightIn = isNight ? (300 - cycleSec) : (180 - cycleSec);

        if (cyclePhaseIcon) cyclePhaseIcon.textContent = isNight ? "🌙" : "☀️";
        if (cyclePhaseText) {
            cyclePhaseText.innerHTML = isNight 
                ? 'In-Game Phase: <strong style="color:#dc32ff;">NIGHT SPAWN PHASE ACTIVE</strong>' 
                : 'In-Game Phase: <strong style="color:#00ffff;">DAY PHASE</strong>';
        }
        if (cycleTimerText) {
            cycleTimerText.textContent = isNight 
                ? `Night Wave Ends in ${formatMinsSecs(nextNightIn)}` 
                : `Next Night Spawn Wave in ${formatMinsSecs(nextNightIn)}`;
        }

        let allPredicted = [];
        const tiers = ['Secret', 'Eternal', 'Divine'];

        tiers.forEach(tier => {
            const listEl = tier === 'Secret' ? secretList : (tier === 'Eternal' ? eternalList : divineList);
            if (!listEl) return;

            listEl.innerHTML = '';

            eggDatabase[tier].forEach(item => {
                const rem = item.cycleSec - ((nowSec + item.offsetSec) % item.cycleSec);
                const spawnDate = new Date(nowMs + (rem * 1000));
                const clockStr = format12HourTime(spawnDate);
                const relStr = formatRelativeTime(rem);

                allPredicted.push({
                    tier,
                    name: item.name,
                    zone: item.zone,
                    zoneCss: item.zoneCss,
                    rem,
                    clockStr,
                    relStr
                });

                const row = document.createElement('div');
                row.className = 'egg-row';
                row.innerHTML = `
                    <span class="egg-name">${item.name}</span>
                    <span class="dot-sep">-</span>
                    <span class="zone-badge ${item.zoneCss}">${item.zone}</span>
                    <span class="dot-sep">-</span>
                    <span class="time-badge">${clockStr}</span>
                    <span class="dot-sep">-</span>
                    <span class="time-badge muted">${relStr}</span>
                `;
                listEl.appendChild(row);
            });
        });

        // Find Next Up item
        allPredicted.sort((a, b) => a.rem - b.rem);
        const nextUpItem = allPredicted[0];

        if (nextUpItem) {
            if (nextUpName) nextUpName.textContent = nextUpItem.name;
            if (nextUpZone) {
                nextUpZone.textContent = nextUpItem.zone;
                nextUpZone.className = `zone-badge ${nextUpItem.zoneCss}`;
            }
            if (nextUpTime) nextUpTime.textContent = nextUpItem.clockStr;
            if (nextUpRelative) nextUpRelative.textContent = nextUpItem.relStr;
        }
    }

    setInterval(updatePredictor, 1000);
    updatePredictor();

    soundToggleBtn.addEventListener('click', () => {
        soundEnabled = !soundEnabled;
        soundToggleBtn.textContent = soundEnabled ? '🔊 Sound Alerts: ON' : '🔇 Sound Alerts: OFF';
    });
});
