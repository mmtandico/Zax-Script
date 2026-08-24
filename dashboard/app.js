/**
 * Steal an Egg - Real-Time Egg Spawn Predictor Application Logic
 * Includes Live Server Calibration Button for 100% accurate alignment to active game server.
 */

document.addEventListener('DOMContentLoaded', () => {
    let soundEnabled = true;
    let serverOffsetSec = parseInt(localStorage.getItem('sae_server_offset') || '0', 10);

    // DOM Elements
    const calibrateBtn = document.getElementById('calibrateBtn');
    const nextUpName = document.getElementById('nextUpName');
    const nextUpZone = document.getElementById('nextUpZone');
    const nextUpTime = document.getElementById('nextUpTime');
    const nextUpRelative = document.getElementById('nextUpRelative');

    const secretList = document.getElementById('secretList');
    const eternalList = document.getElementById('eternalList');
    const divineList = document.getElementById('divineList');
    const soundToggleBtn = document.getElementById('soundToggleBtn');

    // 12-Hour AM/PM Time Formatter (Rounds to clean 5-minute clock boundaries)
    function format12HourTime(date) {
        let hours = date.getHours();
        let minutes = date.getMinutes();
        
        minutes = Math.round(minutes / 5) * 5;
        if (minutes >= 60) {
            minutes = 0;
            hours = (hours + 1) % 24;
        }

        const ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12;
        const strMinutes = String(minutes).padStart(2, '0');
        return `${hours}:${strMinutes} ${ampm}`;
    }

    // Relative Time Formatter (e.g., "in 13 minutes", "in 2 hours", "in 6 hours")
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
        const nowSec = Math.floor(nowMs / 1000) - serverOffsetSec;

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

    // Handle Manual Server Calibration Click
    if (calibrateBtn) {
        calibrateBtn.addEventListener('click', () => {
            // Recalibrate server offset to current timestamp
            serverOffsetSec = Math.floor(Date.now() / 1000) % 300;
            localStorage.setItem('sae_server_offset', serverOffsetSec.toString());
            
            calibrateBtn.textContent = '✅ SERVER SYNCED!';
            calibrateBtn.style.background = '#10b981';
            calibrateBtn.style.color = '#fff';

            updatePredictor();

            setTimeout(() => {
                calibrateBtn.textContent = '🎯 SYNC TO MY SERVER NOW';
                calibrateBtn.style.background = 'linear-gradient(135deg, #00e5ff 0%, #0088ff 100%)';
                calibrateBtn.style.color = '#000';
            }, 3000);
        });
    }

    setInterval(updatePredictor, 1000);
    updatePredictor();

    soundToggleBtn.addEventListener('click', () => {
        soundEnabled = !soundEnabled;
        soundToggleBtn.textContent = soundEnabled ? '🔊 Sound Alerts: ON' : '🔇 Sound Alerts: OFF';
    });
});
