document.addEventListener('DOMContentLoaded', () => {
    const socket = io();

    const totalThreatsCount = document.getElementById('total-threats-count');
    const attackEntries = document.getElementById('attack-entries');
    const refreshHistoryBtn = document.getElementById('refresh-history');
    const clearHistoryBtn = document.getElementById('clear-history');
    let totalThreats = 0;
    let attackHistory = [];

    socket.on('new_connection', (data) => {
        // 1. Update Total Threats Counter
        totalThreats++;
        totalThreatsCount.textContent = totalThreats;

        // 2. Update the specific port's counter
        const portCountElement = document.getElementById(`count-${data.port}`);
        if (portCountElement) {
            let currentCount = parseInt(portCountElement.textContent, 10);
            portCountElement.textContent = currentCount + 1;
        }

        // 3. Flash the card to highlight the new threat
        const threatCard = document.getElementById(`port-${data.port}`);
        if (threatCard) {
            threatCard.classList.add('flash');
            // Remove the class after the animation finishes to allow it to be re-triggered
            setTimeout(() => {
                threatCard.classList.remove('flash');
            }, 700); // Must match the animation duration in CSS
        }

        // 4. Add to attack history
        addAttackToHistory(data);
    });

    socket.on('connect', () => {
        console.log('Successfully connected to the real-time threat server.');
    });

    socket.on('disconnect', () => {
        console.log('Disconnected from the server.');
    });

    // Attack History Functions
    function addAttackToHistory(data) {
        const attackData = {
            ...data,
            port_name: getPortName(data.port)
        };
        
        attackHistory.unshift(attackData); // Add to beginning
        
        // Keep only last 100 attacks in memory
        if (attackHistory.length > 100) {
            attackHistory = attackHistory.slice(0, 100);
        }
        
        renderAttackHistory();
    }

    function renderAttackHistory() {
        attackEntries.innerHTML = '';
        
        attackHistory.forEach((attack, index) => {
            const entry = document.createElement('div');
            entry.className = 'attack-entry';
            if (index === 0) entry.classList.add('new-entry');
            
            entry.innerHTML = `
                <div class="attack-time">${formatTime(attack.timestamp)}</div>
                <div class="attack-ip">${attack.ip}</div>
                <div class="attack-port">${attack.port}</div>
                <div class="attack-service">${attack.port_name}</div>
            `;
            
            attackEntries.appendChild(entry);
        });
    }

    function formatTime(timestamp) {
        const date = new Date(timestamp);
        return date.toLocaleTimeString('fr-FR', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    }

    function getPortName(port) {
        const portNames = {
            22: 'SSH',
            23: 'TELNET',
            25: 'SMTP',
            53: 'DNS',
            80: 'HTTP',
            110: 'POP3',
            143: 'IMAP',
            443: 'HTTPS',
            993: 'IMAPS',
            995: 'POP3S',
            1433: 'MSSQL',
            3306: 'MySQL',
            3389: 'RDP',
            5900: 'VNC',
            8080: 'HTTP-ALT'
        };
        return portNames[port] || 'Unknown';
    }

    function loadRecentAttacks() {
        fetch('/api/recent-attacks')
            .then(response => response.json())
            .then(data => {
                attackHistory = data;
                renderAttackHistory();
            })
            .catch(error => {
                console.error('Error loading recent attacks:', error);
            });
    }

    function loadDailyStats() {
        fetch('/api/stats')
            .then(response => response.json())
            .then(stats => {
                // Update counters with current daily stats
                Object.entries(stats).forEach(([port, count]) => {
                    const portCountElement = document.getElementById(`count-${port}`);
                    if (portCountElement) {
                        portCountElement.textContent = count;
                        totalThreats += count;
                    }
                });
                totalThreatsCount.textContent = totalThreats;
            })
            .catch(error => {
                console.error('Error loading daily stats:', error);
            });
    }

    // Event Listeners
    refreshHistoryBtn.addEventListener('click', () => {
        loadRecentAttacks();
        loadDailyStats();
    });

    clearHistoryBtn.addEventListener('click', () => {
        attackHistory = [];
        renderAttackHistory();
    });

    // Load initial data
    loadRecentAttacks();
    loadDailyStats();
});

