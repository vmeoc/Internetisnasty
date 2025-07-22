document.addEventListener('DOMContentLoaded', () => {
    const socket = io();

    // Security function to escape HTML and prevent XSS
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

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
        // Load initial data when connected
        loadDailyStats();
        loadRecentAttacks();
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
        if (attackHistory.length === 0) {
            attackEntries.innerHTML = '<div class="no-attacks">🔍 Waiting for attacks...</div>';
            return;
        }
        
        attackEntries.innerHTML = '';
        
        // Show only the most recent 20 attacks for the compact view
        const recentAttacks = attackHistory.slice(0, 20);
        
        recentAttacks.forEach((attack, index) => {
            const entry = document.createElement('div');
            entry.className = 'attack-entry';
            if (index === 0) entry.classList.add('new-entry');
            
            // Create elements safely to prevent XSS
            const timeDiv = document.createElement('div');
            timeDiv.style.color = '#4ecdc4';
            timeDiv.textContent = formatTime(attack.timestamp);
            
            const ipDiv = document.createElement('div');
            ipDiv.style.color = '#ff9500';
            ipDiv.textContent = escapeHtml(attack.ip);
            
            const portDiv = document.createElement('div');
            portDiv.style.color = '#ff6b6b';
            portDiv.textContent = attack.port;
            
            const serviceDiv = document.createElement('div');
            serviceDiv.style.color = '#a8e6cf';
            serviceDiv.textContent = escapeHtml(attack.port_name);
            
            entry.appendChild(timeDiv);
            entry.appendChild(ipDiv);
            entry.appendChild(portDiv);
            entry.appendChild(serviceDiv);
            
            attackEntries.appendChild(entry);
        });
    }

    function formatTime(timestamp) {
        const date = new Date(timestamp);
        // Use user's browser timezone instead of forcing French time
        return date.toLocaleTimeString(navigator.language || 'en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false
        });
    }

    function getPortName(port) {
        const portNames = {
            22: 'SSH',
            23: 'TELNET',
            25: 'SMTP',
            53: 'DNS',
            110: 'POP3',
            135: 'RPC',
            139: 'NetBIOS',
            143: 'IMAP',
            445: 'SMB',
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
                // Reset total threats counter before updating
                totalThreats = 0;
                
                // Update counters with current daily stats
                Object.entries(stats).forEach(([port, count]) => {
                    const portCountElement = document.getElementById(`count-${port}`);
                    if (portCountElement) {
                        portCountElement.textContent = count;
                        totalThreats += count;
                    }
                });
                
                // Reset counters for ports with no attacks today
                const allPorts = [22, 23, 25, 53, 110, 135, 139, 143, 445, 993, 995, 1433, 3306, 3389, 5900, 8080];
                allPorts.forEach(port => {
                    if (!stats[port]) {
                        const portCountElement = document.getElementById(`count-${port}`);
                        if (portCountElement) {
                            portCountElement.textContent = '0';
                        }
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

