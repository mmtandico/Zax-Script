/**
 * Steal an Egg - Real-Time Egg Spawn Predictor Application Logic
 * Replicates the exact reference structure with exact egg names by tier (Secret, Eternal, Divine).
 */

document.addEventListener('DOMContentLoaded', () => {
    let soundEnabled = true;

    // DOM Elements
    const nextUpName = document.getElementById('nextUpName');
    const nextUpTime = document.getElementById('nextUpTime');
    const nextUpRelative = document.getElementById('nextUpRelative');

    const secretList = document.getElementById('secretList');
    const eternalList = document.getElementById('eternalList');
    const divineList = document.getElementById('divineList');
    const soundToggleBtn = document.getElementById('soundToggleBtn');

    // 12-Hour AM/PM Time Formatter (e.g., "6:30 pm", "12:25 am")
    function format12HourTime(date) {
        let hours = date.getHours();
        let minutes = date.getMinutes();
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

    // Exact Egg Definitions & Intervals from Reference Image
    const eggDatabase = {
        Secret: [
            { name: "Tralaledon", cycleSec: 2100, offsetSec: 780 },
            { name: "TyrannosaurusRex", cycleSec: 8100, offsetSec: 7200 },
            { name: "Warden", cycleSec: 9000, offsetSec: 8100 },
            { name: "Cave Dragon", cycleSec: 10200, offsetSec: 9300 },
            { name: "Alien Skeleton Boss", cycleSec: 11700, offsetSec: 10800 },
            { name: "Cerberus", cycleSec: 17400, offsetSec: 16500 },
            { name: "Yeti", cycleSec: 23400, offsetSec: 22500 },
            { name: "Kraken", cycleSec: 33600, offsetSec: 32700 }
        ],
        Eternal: [
            { name: "Mosasaurus", cycleSec: 10500, offsetSec: 9600 },
            { name: "Eternal Lunar Dragon", cycleSec: 22200, offsetSec: 21300 },
            { name: "Dragon", cycleSec: 24000, offsetSec: 23100 },
            { name: "El Maja", cycleSec: 32100, offsetSec: 31200 },
            { name: "Ascended Vermilion Phoenix", cycleSec: 38100, offsetSec: 37200 },
            { name: "Ice Dragon", cycleSec: 65400, offsetSec: 64500 }
        ],
        Divine: [
            { name: "Unicorn", cycleSec: 21900, offsetSec: 21000 }
        ]
    };

    // Calculate predictions for all items
    function updatePredictor() {
        const nowMs = Date.now();
        const nowSec = Math.floor(nowMs / 1000);

        let allPredicted = [];

        // Calculate for each tier
        const tiers = ['Secret', 'Eternal', 'Divine'];

        tiers.forEach(tier => {
            const listEl = tier === 'Secret' ? secretList : (tier === 'Eternal' ? eternalList : divineList);
            if (!listEl) return;

            listEl.innerHTML = '';

            eggDatabase[tier].forEach(item => {
                // Calculate next spawn remaining seconds seeded by epoch time
                const rem = item.cycleSec - ((nowSec + item.offsetSec) % item.cycleSec);
                const spawnDate = new Date(nowMs + (rem * 1000));
                const clockStr = format12HourTime(spawnDate);
                const relStr = formatRelativeTime(rem);

                allPredicted.push({
                    tier,
                    name: item.name,
                    rem,
                    clockStr,
                    relStr
                });

                // Create egg row item matching exact reference format
                const row = document.createElement('div');
                row.className = 'egg-row';
                row.innerHTML = `
                    <span class="egg-name">${item.name}</span>
                    <span class="dot-sep">-</span>
                    <span class="time-badge">${clockStr}</span>
                    <span class="dot-sep">-</span>
                    <span class="time-badge muted">${relStr}</span>
                `;
                listEl.appendChild(row);
            });
        });

        // Find the absolute Next Up egg across all categories
        allPredicted.sort((a, b) => a.rem - b.rem);
        const nextUpItem = allPredicted[0];

        if (nextUpItem) {
            if (nextUpName) nextUpName.textContent = nextUpItem.name;
            if (nextUpTime) nextUpTime.textContent = nextUpItem.clockStr;
            if (nextUpRelative) nextUpRelative.textContent = nextUpItem.relStr;
        }
    }

    // Run ticker loop every second
    setInterval(updatePredictor, 1000);
    updatePredictor();

    soundToggleBtn.addEventListener('click', () => {
        soundEnabled = !soundEnabled;
        soundToggleBtn.textContent = soundEnabled ? '🔊 Sound Alerts: ON' : '🔇 Sound Alerts: OFF';
    });
});
