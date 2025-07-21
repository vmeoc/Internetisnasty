document.addEventListener('DOMContentLoaded', () => {
    const socket = io();

    const totalThreatsCount = document.getElementById('total-threats-count');
    let totalThreats = 0;

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
    });

    socket.on('connect', () => {
        console.log('Successfully connected to the real-time threat server.');
    });

    socket.on('disconnect', () => {
        console.log('Disconnected from the server.');
    });
});

