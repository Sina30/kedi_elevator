let currentElevator = null;
let currentFloorIndex = null;
let elevatorData = null;
let isTransitioning = false;

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openElevator') {
        showElevatorUI(data.elevator, data.currentFloor, data.floors);
    } else if (data.action === 'closeElevator') {
        hideElevatorUI();
    } else if (data.action === 'startTransition') {

    } else if (data.action === 'endTransition') {

    } else if (data.action === 'showNotification') {

    }
});

function showElevatorUI(elevator, currentFloor, floors) {
    currentElevator = elevator.id;
    currentFloorIndex = currentFloor;
    elevatorData = elevator;

    document.getElementById('elevator-name').textContent = elevator.settings.name || 'Elevator';
    document.getElementById('building-name').textContent = elevator.settings.buildingName || 'Building';
    
    const currentFloorData = floors[currentFloor - 1];
    if (currentFloorData) {
        document.getElementById('current-floor-name').textContent = currentFloorData.title;
    } else {
        document.getElementById('current-floor-name').textContent = 'Unknown Floor';
    }
    
    const floorsContainer = document.getElementById('floors-container');
    floorsContainer.innerHTML = '';
    
    floors.forEach((floor, index) => {
        const floorItem = document.createElement('div');
        floorItem.className = 'floor-item';
        
        if (index + 1 === currentFloor) {
            floorItem.classList.add('current');
        }
        
        if (floor.groups && floor.groups.length > 0) {
            floorItem.classList.add('restricted');
        }
        
        floorItem.innerHTML = `
            <div class="floor-header">
                <span class="floor-name">${floor.title}</span>
                <div class="floor-icon">
                    <i class="${floor.icon || 'fa-solid fa-elevator'}"></i>
                </div>
            </div>
            <div class="floor-description">${floor.description || ''}</div>
            <div class="floor-meta">
                <div class="floor-level">
                    <i class="fa-solid fa-layer-group"></i>
                    <span>Level ${floor.level}</span>
                </div>
                <div class="floor-access ${floor.groups ? 'restricted' : 'public'}">
                    <i class="fa-solid ${floor.groups ? 'fa-lock' : 'fa-unlock'}"></i>
                    <span>${floor.groups ? 'Restricted' : 'Public'}</span>
                </div>
            </div>
        `;
        
        if (index + 1 !== currentFloor) {
            floorItem.addEventListener('click', () => {
                selectFloor(index + 1);
            });
        } else {
            floorItem.classList.add('disabled');
        }
        
        floorsContainer.appendChild(floorItem);
    });
    
    const closeBtn = document.getElementById('close-btn');
    if (closeBtn) {
        const newCloseBtn = closeBtn.cloneNode(true);
        closeBtn.parentNode.replaceChild(newCloseBtn, closeBtn);
        newCloseBtn.addEventListener('click', () => {
            hideElevatorUI();
        });
    }

    document.getElementById('elevator-container').classList.remove('hidden');
}

function hideElevatorUI() {
    const container = document.getElementById('elevator-container');
    if (container) {
        container.classList.add('hidden');
    }

    isTransitioning = false;

    sendMessage('closeElevator');
}
function selectFloor(floorIndex) {
    if (isTransitioning) return;

    playSound('buttonPress');

    isTransitioning = true;

    hideElevatorUI();
    
    sendMessage('selectFloor', {
        elevator: currentElevator,
        floor: floorIndex
    });
}


function showTransition(fromFloor, toFloor, direction) {}
function hideTransition() {
    isTransitioning = false;
}

function playSound(soundName) {
    sendMessage('playSound', {
        sound: soundName
    });
}

function sendMessage(action, data = {}) {
    try {
        fetch(`https://${GetParentResourceName()}/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        }).catch(error => console.error('Error:', error));
    } catch (error) {
        console.error('Failed to send message:', error);
    }
}


document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        hideElevatorUI();
    }
});

document.addEventListener('DOMContentLoaded', function() {

    const requiredElements = [
        'elevator-container', 'elevator-name', 'building-name', 
        'current-floor-name', 'floors-container', 'close-btn'
    ];
    
    for (const id of requiredElements) {
        if (!document.getElementById(id)) {
            console.error(`Required element #${id} not found in the HTML!`);
        }
    }
});