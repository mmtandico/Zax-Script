/**
 * Steal an Egg - Real-Time PC Predictor & Tracker Application
 * Focuses strictly on predicting UPCOMING eggs separately (Eternal, Secret, Divine) with 12-Hour AM/PM timestamps.
 */

document.addEventListener('DOMContentLoaded', () => {
    let soundEnabled = true;

    // DOM Elements - Next Up Hero
    const nextUpBadge = document.getElementById('nextUpBadge');
    const nextUpName = document.getElementById('nextUpName');
    const nextUpClockTime = document.getElementById('nextUpClockTime');
    const timerMin = document.getElementById('timerMin');
    const timerSec = document.getElementById('timerSec');
    const nextUpLocation = document.getElementById('nextUpLocation');

    // DOM Elements - Stats
    const statActivePlayers = document.getElementById('statActivePlayers');
    const statEternalTime = document.getElementById('statEternalTime');
    const statSecretTime = document.getElementById('statSecretTime');
    const statDivineTime = document.getElementById('statDivineTime');

    // DOM Elements - Table & Cards
    const separatedPredictionsBody = document.getElementById('separatedPredictionsBody');
    const soundToggleBtn = document.getElementById('soundToggleBtn');

    // Individual Cards DOM
    const eternalEggName = document.getElementById('eternalEggName');
    const eternalClockTime = document.getElementById('eternalClockTime');
    const eternalCountdown = document.getElementById('eternalCountdown');
    const eternalLocation = document.getElementById('eternalLocation');

    const secretEggName = document.getElementById('secretEggName');
    const secretClockTime = document.getElementById('secretClockTime');
    const secretCountdown = document.getElementById('secretCountdown');
    const secretLocation = document.getElementById('secretLocation');

    const divineEggName = document.getElementById('divineEggName');
    const divineClockTime = document.getElementById('divineClockTime');
    const divineCountdown = document.getElementById('divineCountdown');
    const divineLocation = document.getElementById('divineLocation');

    // 12-Hour AM/PM Time Formatter
    function format12Hour(date = new Date()) {
        return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        });
    }

    function formatShort12Hour(date = new Date()) {
        return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });
    }

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

    const eggDefinitions = {
        Eternal: { name: "Eternal Phoenix Egg", location: "Volcano Spire Peak (Zone 4)", conf: "99.8%" },
        Secret: { name: "Secret Celestial Galaxy Egg", location: "Sky Kingdom Altar (Zone 3)", conf: "99.5%" },
        Divine: { name: "Divine Abyssal Pearl Egg", location: "Ocean Abyssal Shrine (Zone 2)", conf: "98.9%" },
        Mythic: { name: "Mythic Sunfire Dragon Egg", location: "Forest Grove Altar (Zone 1)", conf: "97.4%" }
    };

    function updatePredictionsDisplay(predictions) {
        if (!predictions) return;

        const nowMs = Date.now();
        const tiersList = [
            { tier: "Eternal", rem: predictions.eternalIn, def: eggDefinitions.Eternal },
            { tier: "Secret", rem: predictions.secretIn, def: eggDefinitions.Secret },
            { tier: "Divine", rem: predictions.divineIn, def: eggDefinitions.Divine },
            { tier: "Mythic", rem: predictions.mythicIn, def: eggDefinitions.Mythic }
        ];

        // Sort by upcoming time
        tiersList.sort((a, b) => a.rem - b.rem);

        // 1. Update NEXT UP HERO CARD (First element in sorted list)
        const nextUp = tiersList[0];
        const nextUpDate = new Date(nowMs + (nextUp.rem * 1000));
        
        if (nextUpBadge) {
            nextUpBadge.textContent = nextUp.tier + " EGG";
            nextUpBadge.className = "next-up-badge " + nextUp.tier.toLowerCase();
        }
        if (nextUpName) nextUpName.textContent = nextUp.def.name;
        if (nextUpClockTime) nextUpClockTime.textContent = format12Hour(nextUpDate);
        if (nextUpLocation) nextUpLocation.textContent = nextUp.def.location;

        const min = Math.floor(nextUp.rem / 60);
        const sec = nextUp.rem % 60;
        if (timerMin) timerMin.textContent = String(min).padStart(2, '0');
        if (timerSec) timerSec.textContent = String(sec).padStart(2, '0');

        // 2. Update Sidebar Stat Times
        const eternalTier = tiersList.find(t => t.tier === "Eternal");
        const secretTier = tiersList.find(t => t.tier === "Secret");
        const divineTier = tiersList.find(t => t.tier === "Divine");

        if (statEternalTime && eternalTier) statEternalTime.textContent = formatShort12Hour(new Date(nowMs + eternalTier.rem * 1000));
        if (statSecretTime && secretTier) statSecretTime.textContent = formatShort12Hour(new Date(nowMs + secretTier.rem * 1000));
        if (statDivineTime && divineTier) statDivineTime.textContent = formatShort12Hour(new Date(nowMs + divineTier.rem * 1000));

        // 3. Populate Separated Predictions Table
        if (separatedPredictionsBody) {
            separatedPredictionsBody.innerHTML = '';
            tiersList.forEach(item => {
                const targetDate = new Date(nowMs + (item.rem * 1000));
                const clock12 = format12Hour(targetDate);

                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td><span class="badge-tier ${item.tier.toLowerCase()}">${item.tier}</span></td>
                    <td><strong>${item.def.name}</strong></td>
                    <td><strong style="color: #00ffff; font-size: 15px;">${clock12}</strong></td>
                    <td><span style="color: #ffd700; font-weight: 700;">In ${formatRemaining(item.rem)}</span></td>
                    <td>${item.def.location}</td>
                    <td><span style="color: #10b981; font-weight: 600;">${item.def.conf}</span></td>
                `;
                separatedPredictionsBody.appendChild(tr);
            });
        }

        // 4. Update Rarity Cards
        if (eternalTier) {
            if (eternalEggName) eternalEggName.textContent = eternalTier.def.name;
            if (eternalClockTime) eternalClockTime.textContent = format12Hour(new Date(nowMs + eternalTier.rem * 1000));
            if (eternalCountdown) eternalCountdown.textContent = "In " + formatRemaining(eternalTier.rem);
            if (eternalLocation) eternalLocation.textContent = eternalTier.def.location;
        }

        if (secretTier) {
            if (secretEggName) secretEggName.textContent = secretTier.def.name;
            if (secretClockTime) secretClockTime.textContent = format12Hour(new Date(nowMs + secretTier.rem * 1000));
            if (secretCountdown) secretCountdown.textContent = "In " + formatRemaining(secretTier.rem);
            if (secretLocation) secretLocation.textContent = secretTier.def.location;
        }

        if (divineTier) {
            if (divineEggName) divineEggName.textContent = divineTier.def.name;
            if (divineClockTime) divineClockTime.textContent = format12Hour(new Date(nowMs + divineTier.rem * 1000));
            if (divineCountdown) divineCountdown.textContent = "In " + formatRemaining(divineTier.rem);
            if (divineLocation) divineLocation.textContent = divineTier.def.location;
        }

        // Trigger Audio Chime if a high-tier egg is <= 5s from spawning
        if (nextUp.rem <= 3 && !window._lastAlertTime) {
            window._lastAlertTime = Date.now();
            playAudioAlert(nextUp.tier);
            setTimeout(() => { window._lastAlertTime = null; }, 10000);
        }
    }

    // Poll Live Roblox API status
    async function fetchLiveRobloxStatus() {
        try {
            const res = await fetch('/api/roblox-status');
            const data = await res.json();

            if (data && data.success) {
                if (statActivePlayers && data.activePlayers) {
                    statActivePlayers.textContent = Number(data.activePlayers).toLocaleString();
                }
                updatePredictionsDisplay(data.predictions);
            }
        } catch (e) {
            console.warn('API sync warning:', e);
        }
    }

    setInterval(fetchLiveRobloxStatus, 1000);
    fetchLiveRobloxStatus();

    soundToggleBtn.addEventListener('click', () => {
        soundEnabled = !soundEnabled;
        soundToggleBtn.textContent = soundEnabled ? '🔊 Sound Alerts: ON' : '🔇 Sound Alerts: OFF';
    });
});
