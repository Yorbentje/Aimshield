document.addEventListener("DOMContentLoaded", () => {
  let allLogs = [];
  let playersData = {};
  let menuOpen = false;
  
  let notificationSettings = {
    notificationsEnabled: true,
    soundEnabled: true
  };

  function loadSettings() {
    fetch(`https://${GetParentResourceName()}/loadSettings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ player: 'playerIdentifier' })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        notificationSettings = data.settings;
        document.getElementById('toggle-notifications').checked = notificationSettings.notificationsEnabled;
        document.getElementById('toggle-sound').checked = notificationSettings.soundEnabled;
        updateSoundToggleState();
      } else {
        // Use default settings if loading failed
        notificationSettings = {
          notificationsEnabled: true,
          soundEnabled: true
        };
        document.getElementById('toggle-notifications').checked = notificationSettings.notificationsEnabled;
        document.getElementById('toggle-sound').checked = notificationSettings.soundEnabled;
        updateSoundToggleState();
      }
    })
    .catch(error => {
      console.error('Error fetching settings:', error);
      // Use default settings on error
      notificationSettings = {
        notificationsEnabled: true,
        soundEnabled: true
      };
      document.getElementById('toggle-notifications').checked = notificationSettings.notificationsEnabled;
      document.getElementById('toggle-sound').checked = notificationSettings.soundEnabled;
      updateSoundToggleState();
    });
  }

  function updateSoundToggleState() {
    const soundItem = document.querySelector('.setting-item:nth-child(2)');
    const soundToggle = document.getElementById('toggle-sound');
    
    if (!notificationSettings.notificationsEnabled) {
      soundItem.classList.add('disabled');
      soundToggle.checked = false;
      notificationSettings.soundEnabled = false;
      saveSettings();
    } else {
      soundItem.classList.remove('disabled');
    }
  }

  function saveSettings() {
    fetch(`https://${GetParentResourceName()}/saveSettings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ player: 'playerIdentifier', settings: notificationSettings })
    })
    .then(response => response.json())
    .then(data => {
      if (!data.success) {
        console.error('Failed to save settings:', data.message);
      }
    })
    .catch(error => console.error('Error saving settings:', error));
  }

  function isLoadingOverlayActive() {
    const overlay = document.getElementById("overlay");
    return overlay && !overlay.classList.contains("hidden");
  }

  const notification = document.createElement("div");
  notification.id = "custom-notification";
  notification.innerHTML = `<i class="fas fa-exclamation-circle"></i> <span id="notif-text"></span>`;
  document.body.appendChild(notification);
  let hideTimeout = null;

  loadSettings();

  document.getElementById('toggle-notifications')?.addEventListener('change', (e) => {
    notificationSettings.notificationsEnabled = e.target.checked;
    saveSettings();
    updateSoundToggleState();
  });

  document.getElementById('toggle-sound')?.addEventListener('change', (e) => {
    if (notificationSettings.notificationsEnabled) {
      notificationSettings.soundEnabled = e.target.checked;
      saveSettings();
    }
  });

  window.addEventListener("message", (event) => {
    const data = event.data;

    if (data.action === "openDashboard") {
      showMenu();
    }

    if (data.action === "open") {
      allLogs = data.logs || [];
      playersData = data.players || {};
      updatePlayerTable(playersData);
      populateLogs(allLogs);
    }

    if (data.action === "showNotification") {
      showNotification(data.text);
    }

    if (data.action === "showScenarioConfirmation") {
      showScenarioConfirmation(data);
    }
  });

  function showNotification(message) {
    if (!notificationSettings.notificationsEnabled) return;

    clearTimeout(hideTimeout);

    const notificationElement = document.getElementById("custom-notification");
    document.getElementById("notif-text").innerText = message;

    notificationElement.classList.remove("hide");
    notificationElement.classList.add("show");

    if (notificationSettings.soundEnabled) {
      const audio = new Audio('../sounds/notification.mp3');
      audio.volume = 0.4;
      audio.play().catch(error => console.log('Geluid kan niet worden afgespeeld:', error));
    }

    hideTimeout = setTimeout(() => {
      notificationElement.classList.remove("show");
      notificationElement.classList.add("hide");
    }, 5000);
  }

  const showMenu = () => {
    const closeButton = document.getElementById("close-button");
  
    if (closeButton && closeButton.classList.contains("confirmed")) {
      closeButton.classList.remove("confirmed");
      const icon = closeButton.querySelector("i");
      if (icon) {
        icon.classList.remove("fa-check");
        icon.classList.add("fa-times");
      }
    }
  
    const menuContainer = document.getElementById("menu-container");
    const overlay = document.getElementById("overlay");
  
    menuContainer.classList.remove("hidden");
    overlay.classList.remove("hidden");
  
    menuOpen = true;
  
    setTimeout(() => {
      overlay.classList.add("fade-out");
  
      setTimeout(() => {
        overlay.classList.add("hidden");
        overlay.classList.remove("fade-out");
      }, 1000);
    }, 1500);
  };

  document.getElementById("close-button").addEventListener("click", () => {
    if (isLoadingOverlayActive()) return;
    
    const closeButton = document.getElementById("close-button");
    closeButton.classList.add("confirmed");

    const icon = closeButton.querySelector("i");
    if (icon) {
      icon.classList.remove("fa-times");
      icon.classList.add("fa-check");
    }

    const menuContainer = document.getElementById("menu-container");
    menuContainer.classList.add("closing");

    setTimeout(() => {
      menuContainer.classList.add("hidden");
      menuContainer.classList.remove("closing");
      menuOpen = false;
      stopRefreshInterval();
      fetch(`https://${GetParentResourceName()}/closeMenu`, { method: "POST" });
    }, 500);
  });

  function closeActiveMenu() {
    if (isLoadingOverlayActive()) return;

    const logsOverlay = document.getElementById("logs-overlay");
    if (logsOverlay && getComputedStyle(logsOverlay).display === "flex") {
      const logsClose = document.getElementById("logs-close");
      if (logsClose) {
        logsClose.click();
        return;
      }
    }

    const menuContainer = document.getElementById("menu-container");
    if (menuContainer && getComputedStyle(menuContainer).display !== "none") {
      const closeButton = document.getElementById("close-button");
      if (closeButton) {
        closeButton.click();
        return;
      }
    }
  }
  
  document.addEventListener("keydown", (event) => {
    if (isLoadingOverlayActive()) return;
    
    if (event.key === "Escape") {
      const recreateModal = document.getElementById('recreate-modal');
      if (recreateModal && !recreateModal.classList.contains('hidden')) {
        hideRecreateModal();
        return;
      }
      closeActiveMenu();
    }
  });
  
  document.addEventListener("click", (event) => {
    if (isLoadingOverlayActive()) return;

    const recreateModal = document.getElementById('recreate-modal');
    if (recreateModal && !recreateModal.classList.contains('hidden') && event.target === recreateModal) {
      hideRecreateModal();
      return;
    }

    if (!event.target.closest("#menu-container") && !event.target.closest("#logs-overlay")) {
      closeActiveMenu();
    }
  });

  let refreshInterval = null;

  function startRefreshInterval() {
    if (refreshInterval) return;
    refreshInterval = setInterval(() => {
      if (menuOpen) {
        fetch(`https://${GetParentResourceName()}/refreshLogs`, {
          method: "POST",
          headers: { "Content-Type": "application/json" }
        });
      }
    }, 15000);
  }

  function stopRefreshInterval() {
    if (refreshInterval) {
      clearInterval(refreshInterval);
      refreshInterval = null;
    }
  }

  document.querySelectorAll("nav ul li").forEach(tab => {
    tab.addEventListener("click", function () {
      document.querySelector(".tab.active").classList.remove("active");
      document.querySelector(".tab-content.active").classList.remove("active");

      this.classList.add("active");
      document.getElementById(this.dataset.tab).classList.add("active");

      document.querySelector(".search-sort-container").style.display =
        this.dataset.tab === "players-tab" ? "flex" : "none";
    });
  });

const populateLogs = logs => {
  const tbody = document.querySelector("#logs-table tbody");
  tbody.innerHTML = logs.map((log, index) => `
    <tr data-identifier="${log.identifier}" data-index="${index}" data-attacker-coords="${log.attacker_coords || ''}" data-victim-coords="${log.victim_coords || ''}">
      <td>${log.playerName}</td>
      <td>${log.weapon_hash}</td>
      <td>${log.detected_at}</td>
      <td>
        <button class="view-btn copy-log-btn" data-index="${index}">
          📋 Copy Log
        </button>
        <button class="view-btn recreate-btn" data-index="${index}">
          🔄 Recreate
        </button>
      </td>
    </tr>
  `).join('');

  tbody.querySelectorAll("tr").forEach(row => {
    row.addEventListener("click", event => {
      if (event.target.closest("a, button")) return;
      const identifier = row.dataset.identifier;
      if (identifier) {
        viewPlayerInfo(identifier);
      }
    });
  });  

  const hiddenCopyInput = document.getElementById("hidden-copy-input");
  tbody.querySelectorAll(".copy-log-btn").forEach(btn => {
    btn.addEventListener("click", event => {
      event.stopPropagation();
      const index = btn.getAttribute("data-index");
      const log = logs[index];
      if (log) {
        const logText = `Player Name: ${log.playerName}\n | Weapon Hash: ${log.weapon_hash}\n | Date/Time: ${log.detected_at}`;
        hiddenCopyInput.value = logText;
        hiddenCopyInput.select();
        document.execCommand("copy");

        btn.textContent = "✅";
        btn.classList.add("copy-success");

        setTimeout(() => {
          btn.textContent = "📋 Copy Log";
          btn.classList.remove("copy-success");
        }, 3000);
      }
    });
  });

  tbody.querySelectorAll(".recreate-btn").forEach(btn => {
    btn.addEventListener("click", event => {
      event.stopPropagation();
      const row = btn.closest('tr');
      const logData = {
        attackerCoords: row.getAttribute('data-attacker-coords'),
        victimCoords: row.getAttribute('data-victim-coords')
      };
      console.log('Recreate button clicked with data:', logData);
      showRecreateModal(logData);
    });
  });
};
 

  const filterAndSortPlayers = players => {
    const searchInput = document.getElementById("playerSearch");
    const sortSelect = document.getElementById("playerSort");

    const searchQuery = searchInput ? searchInput.value.toLowerCase() : "";
    const sortOption = sortSelect ? sortSelect.value : "recent";

    let filteredPlayers = Object.values(players).filter(player =>
      player.playerName.toLowerCase().includes(searchQuery) ||
      player.identifier.toLowerCase().includes(searchQuery) ||
      player.detection_count.toString().includes(searchQuery)
    );

    if (sortOption === "asc") {
      filteredPlayers.sort((a, b) => a.detection_count - b.detection_count);
    } else if (sortOption === "desc") {
      filteredPlayers.sort((a, b) => b.detection_count - a.detection_count);
    }

    return filteredPlayers;
  };

  const updatePlayerTable = players => {
    const tbody = document.querySelector("#players-table tbody");
    tbody.innerHTML = "";

    const filteredPlayers = filterAndSortPlayers(players);

    filteredPlayers.forEach(player => {
      const row = document.createElement("tr");
      row.innerHTML = `
        <td>${player.playerName} (${player.identifier})</td>
        <td>${player.detection_count}</td>
        <td>
          <button class="view-btn log-btn" data-identifier="${player.identifier}">
            🔍 View Logs
          </button>
        </td>
      `;
      tbody.appendChild(row);
    });

    attachLogButtons();
  };

  const attachLogButtons = () => {
    document.querySelectorAll(".log-btn").forEach(button => {
      button.removeEventListener("click", handleLogClick);
      button.addEventListener("click", handleLogClick);
    });
  };

  const handleLogClick = event => {
    const identifier = event.currentTarget.dataset.identifier;
    viewPlayerInfo(identifier);
  };

  document.getElementById("playerSearch").addEventListener("input", () =>
    updatePlayerTable(playersData)
  );
  document.getElementById("playerSort").addEventListener("change", () =>
    updatePlayerTable(playersData)
  );

  const viewPlayerInfo = (identifier) => {
    const menuContainer = document.getElementById("menu-container");
    const logsOverlay = document.getElementById("logs-overlay");
  
    const logsCloseButton = document.getElementById("logs-close");
    logsCloseButton.classList.remove("confirmed");
    const logsCloseIcon = logsCloseButton.querySelector("i");
    if (logsCloseIcon) {
      logsCloseIcon.classList.remove("fa-check");
      logsCloseIcon.classList.add("fa-times");
    }
  
    menuContainer.classList.add("closing");
  
    setTimeout(() => {
      menuContainer.style.display = "none";
      menuContainer.classList.add("hidden");
      menuContainer.classList.remove("closing");
    }, 500);
  
    logsOverlay.style.display = "flex";
    logsOverlay.classList.remove("hidden");
    logsOverlay.classList.remove("animate-out");
    logsOverlay.classList.add("animate-in");
  
    const logsTbody = document.querySelector("#logs-table-modal tbody");
    const logsPlayerName = document.getElementById("logs-player-name");
    logsTbody.innerHTML = "";
  
    const playerLogs = allLogs.filter(log => log.identifier === identifier);
  
    if (!playerLogs.length) {
      logsTbody.innerHTML = `<tr><td colspan="5">⚠️ No logs found for this player (report to developer)!</td></tr>`;
    } else {
      logsPlayerName.innerText = `Speler: ${playerLogs[0].playerName} (${identifier})`;
      logsTbody.innerHTML = playerLogs.map((log, index) =>
        `<tr data-index="${index}" data-attacker-coords="${log.attacker_coords || ''}" data-victim-coords="${log.victim_coords || ''}">
          <td>${log.playerName}</td>
          <td>${log.weapon_hash}</td>
          <td>${log.detected_at}</td>
          <td>
            <button class="view-btn copy-log-btn" data-index="${index}">
              📋 Copy Log
            </button>
            <button class="view-btn recreate-btn" data-index="${index}">
              🔄 Recreate
            </button>
          </td>
        </tr>`
      ).join('');
  
      logsTbody.querySelectorAll(".copy-log-btn").forEach(btn => {
        btn.addEventListener("click", event => {
          event.stopPropagation();
          const index = btn.getAttribute("data-index");
          const log = playerLogs[index];
          if (log) {
            const logText = `Player Name: ${log.playerName}\n | Weapon Hash: ${log.weapon_hash}\n | Date/Time: ${log.detected_at}`;
  
            let hiddenCopyTextarea = document.getElementById("hidden-copy-textarea");
            if (!hiddenCopyTextarea) {
              hiddenCopyTextarea = document.createElement("textarea");
              hiddenCopyTextarea.id = "hidden-copy-textarea";
              hiddenCopyTextarea.style.position = "absolute";
              hiddenCopyTextarea.style.left = "-9999px";
              document.body.appendChild(hiddenCopyTextarea);
            }
            hiddenCopyTextarea.value = logText;
            hiddenCopyTextarea.select();
            document.execCommand("copy");
  
            btn.textContent = "✅";
            btn.classList.add("copy-success");
  
            setTimeout(() => {
              btn.textContent = "📋 Copy Log";
              btn.classList.remove("copy-success");
            }, 3000);
          }
        });
      });

      // Add event listeners for recreate buttons
      logsTbody.querySelectorAll(".recreate-btn").forEach(btn => {
        btn.addEventListener("click", event => {
          event.stopPropagation();
          const row = btn.closest('tr');
          const logData = {
            attackerCoords: row.getAttribute('data-attacker-coords'),
            victimCoords: row.getAttribute('data-victim-coords')
          };
          console.log('Recreate button clicked in modal with data:', logData);
          
          // Close logs overlay first
          const logsOverlay = document.getElementById("logs-overlay");
          logsOverlay.classList.add("animate-out");
          
          setTimeout(() => {
            logsOverlay.style.display = "none";
            logsOverlay.classList.add("hidden");
            logsOverlay.classList.remove("animate-out");
            showRecreateModal(logData);
          }, 400);
        });
      });
    }
  };  

  document.getElementById("logs-close").addEventListener("click", () => {
    const logsCloseButton = document.getElementById("logs-close");
    logsCloseButton.classList.add("confirmed");
    const icon = logsCloseButton.querySelector("i");
    if (icon) {
      icon.classList.remove("fa-times");
      icon.classList.add("fa-check");
    }

    const logsOverlay = document.getElementById("logs-overlay");
    const menuContainer = document.getElementById("menu-container");

    logsOverlay.classList.remove("animate-in");
    logsOverlay.classList.add("animate-out");

    setTimeout(() => {
      logsOverlay.style.display = "none";
      logsOverlay.classList.add("hidden");
      logsOverlay.classList.remove("animate-out");

      menuContainer.style.display = "block";
      setTimeout(() => {
        menuContainer.classList.remove("hidden");
      }, 10);
    }, 400);
  });

  document.getElementById("modal-close").addEventListener("click", () => {
    document.getElementById("modal").style.display = "none";
  });

  window.addEventListener("click", e => {
    if (e.target === document.getElementById("modal")) {
      document.getElementById("modal").style.display = "none";
    }
  });

  document.getElementById("playerSort").addEventListener("change", function() {
    this.blur();
  });

  let currentRecreateData = null;

  function showRecreateModal(data) {
    currentRecreateData = data;
    const menuContainer = document.getElementById("menu-container");
    const recreateModal = document.getElementById("recreate-modal");
    
    // Reset close button state
    const recreateCloseButton = document.getElementById("recreate-close");
    recreateCloseButton.classList.remove("confirmed");
    const icon = recreateCloseButton.querySelector("i");
    if (icon) {
      icon.classList.remove("fa-check");
      icon.classList.add("fa-times");
    }
    
    menuContainer.classList.add("closing");
    
    setTimeout(() => {
        menuContainer.style.display = "none";
        menuContainer.classList.add("hidden");
        menuContainer.classList.remove("closing");
    }, 500);
    
    recreateModal.style.display = "flex";
    recreateModal.classList.remove("hidden");
    recreateModal.classList.remove("animate-out");
    recreateModal.classList.add("animate-in");
    
    const playerIdInput = document.getElementById('player-id');
    playerIdInput.focus();

    // Add ENTER key functionality to the input field
    playerIdInput.addEventListener('keydown', function(event) {
        if (event.key === 'Enter') {
            const playerId = playerIdInput.value;
            if (playerId) {
                const logData = {
                    targetId: playerId,
                    attackerCoords: currentRecreateData.attackerCoords,
                    victimCoords: currentRecreateData.victimCoords
                };
                
                fetch(`https://${GetParentResourceName()}/recreateScenario`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(logData)
                });
                
                hideRecreateModal();
            }
        }
    });
  }

  function hideRecreateModal() {
    const recreateCloseButton = document.getElementById('recreate-close');
    recreateCloseButton.classList.add("confirmed");
    const icon = recreateCloseButton.querySelector("i");
    if (icon) {
      icon.classList.remove("fa-times");
      icon.classList.add("fa-check");
    }

    const recreateModal = document.getElementById("recreate-modal");
    const menuContainer = document.getElementById("menu-container");

    recreateModal.classList.remove("animate-in");
    recreateModal.classList.add("animate-out");

    setTimeout(() => {
      recreateModal.style.display = "none";
      recreateModal.classList.add("hidden");
      recreateModal.classList.remove("animate-out");

      menuContainer.style.display = "block";
      setTimeout(() => {
        menuContainer.classList.remove("hidden");
      }, 10);

      // Reset data and input
      currentRecreateData = null;
      document.getElementById('player-id').value = '';
    }, 400);
  }

  document.getElementById('recreate-close').addEventListener('click', hideRecreateModal);
  document.getElementById('recreate-cancel').addEventListener('click', hideRecreateModal);

  document.getElementById('recreate-confirm').addEventListener('click', () => {
    const playerId = document.getElementById('player-id').value;
    console.log('Player ID entered:', playerId);
    console.log('Current recreate data:', JSON.stringify(currentRecreateData, null, 2));

    if (!playerId) {
      showNotification('Please enter a player ID');
      return;
    }

    // Ensure coordinates are in the correct format
    const attackerCoords = currentRecreateData.attackerCoords || '';
    const victimCoords = currentRecreateData.victimCoords || '';

    if (!attackerCoords || !victimCoords) {
      showNotification('No coordinates found for this scenario');
      return;
    }

    const logData = {
      targetId: playerId,
      attackerCoords: attackerCoords,
      victimCoords: victimCoords
    };
    console.log('Sending data to server:', JSON.stringify(logData, null, 2));

    // Send data using FiveM event system
    fetch(`https://${GetParentResourceName()}/recreateScenario`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(logData)
    })
    .then(response => {
      console.log('Server response:', response);
      showNotification('Recreating scenario...');
      
      // First close the recreate modal using the existing function
      hideRecreateModal();
      
      // Then close the main menu after a short delay
      setTimeout(() => {
        const closeButton = document.getElementById("close-button");
        if (closeButton && !closeButton.classList.contains("confirmed")) {
          closeButton.classList.add("confirmed");
          const icon = closeButton.querySelector("i");
          if (icon) {
            icon.classList.remove("fa-times");
            icon.classList.add("fa-check");
          }
        }
        
        const menuContainer = document.getElementById("menu-container");
        if (menuContainer) {
          menuContainer.classList.add("closing");
          setTimeout(() => {
            menuContainer.classList.add("hidden");
            menuContainer.classList.remove("closing");
            menuOpen = false;
            fetch(`https://${GetParentResourceName()}/closeMenu`, { method: "POST" });
          }, 500);
        }
      }, 500);
    })
    .catch(error => {
      console.error('Error details:', error);
      showNotification('Failed to recreate scenario');
    });
  });

document.addEventListener("DOMContentLoaded", () => {

  document.getElementById("playerSort").addEventListener("change", function() {
    this.blur();
  });

  // Add event listener for Escape key
  document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && !document.getElementById('recreate-modal').classList.contains('hidden')) {
      hideRecreateModal();
    }
  });

  // Add event listener for clicking outside the modal
  document.getElementById('recreate-modal').addEventListener('click', function(event) {
    if (event.target === this) {
      hideRecreateModal();
    }
  });
});

function recreateScenario() {
    const playerId = prompt("Enter the ID of the second player:");
    if (playerId) {
        const currentRow = event.target.closest('tr');
        const logData = {
            targetId: playerId,
            attackerCoords: currentRow.dataset.attackerCoords,
            victimCoords: currentRow.dataset.victimCoords
        };
        
        fetch(`https://${GetParentResourceName()}/recreateScenario`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(logData)
        });
    }
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && !document.getElementById('recreate-modal').classList.contains('hidden')) {
        hideRecreateModal();
    }
});

document.getElementById('recreate-modal').addEventListener('click', function(event) {
    if (event.target === this) {
        hideRecreateModal();
    }
});

// Update menu open handler
function openDashboard() {
    SetNuiFocus(true, true);
    SendNUIMessage({ action: 'openDashboard' });
    menuOpen = true;
    startRefreshInterval();
    TriggerServerEvent('sor9400sduf848s');
}

// Clean up on page unload
window.addEventListener('beforeunload', () => {
    stopRefreshInterval();
});

// Add this function to handle the scenario confirmation modal
function showScenarioConfirmation(data) {
    // Remove any existing modal first
    const existingModal = document.querySelector('.scenario-modal');
    if (existingModal) {
        existingModal.remove();
    }

    const modal = document.createElement('div');
    modal.className = 'scenario-modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <div class="branding-container">
                    <i class="fas fa-sync-alt"></i>
                    <h2 class="title">Recreate Scenario</h2>
                </div>
                <button id="scenario-close" class="close-btn">
                    <i class="fas fa-times"></i>
                    <i class="fas fa-check"></i>
                </button>
            </div>
            <div class="modal-body">
                <div class="info-section">
                    <p class="requester-info">${data.requesterName} wants to recreate a scenario with you.</p>
                    <div class="coords-info">
                        <h3>Coordinates</h3>
                        <div class="coord-details">
                            <div class="coord-item">
                                <span class="coord-label">Attacker Position:</span>
                                <span class="coord-value">${data.attackerCoords}</span>
                            </div>
                            <div class="coord-item">
                                <span class="coord-label">Victim Position:</span>
                                <span class="coord-value">${data.victimCoords}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="confirm-btn" id="scenario-confirm">
                    <i class="fas fa-check"></i> Confirm
                </button>
                <button class="reject-btn" id="scenario-reject">
                    <i class="fas fa-times"></i> Reject
                </button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);

    const closeBtn = document.getElementById('scenario-close');
    const modalElement = document.querySelector('.scenario-modal');

    // Function to close the modal with animation
    const closeModal = () => {
        closeBtn.classList.add('confirmed');
        modalElement.classList.add('closing');
        setTimeout(() => {
            modalElement.remove();
            fetch(`https://${GetParentResourceName()}/closeModal`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });
        }, 400);
    };

    // Add close button functionality
    closeBtn.addEventListener('click', closeModal);

    // Reset close button when modal is opened
    closeBtn.classList.remove('confirmed');

    // Add confirm button functionality
    const confirmBtn = document.getElementById('scenario-confirm');
    const confirmScenario = () => {
        fetch(`https://${GetParentResourceName()}/confirmScenario`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
        closeModal();
    };
    confirmBtn.addEventListener('click', confirmScenario);

    // Add reject button functionality
    const rejectBtn = document.getElementById('scenario-reject');
    const rejectScenario = () => {
        fetch(`https://${GetParentResourceName()}/rejectScenario`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
        closeModal();
    };
    rejectBtn.addEventListener('click', rejectScenario);

    // Add ENTER key functionality
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Enter') {
            confirmScenario();
        }
    });

    // Add ESC key functionality
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeModal();
        }
    });

    // Add click outside modal functionality
    modalElement.addEventListener('click', function(event) {
        if (event.target === modalElement) {
            closeModal();
        }
    });
}

// Update the CSS to include closing animation
const style = document.createElement('style');
style.textContent = `
    .scenario-modal {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(23, 22, 32, 0.5);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 9999;
    }
    
    .modal-content {
        background: rgba(10, 10, 10, 0.5);
        border: 3px solid rgba(59,114,199, 0.4);
        border-radius: 20px;
        max-width: 600px;
        width: 90%;
        box-shadow: 0 10px 30px rgba(59,114,199, 0.2);
        overflow: hidden;
        animation: menuOpen 0.4s cubic-bezier(0.25, 1, 0.5, 1);
    }

    .scenario-modal.closing .modal-content {
        animation: menuClose 0.4s cubic-bezier(0.4, 0, 1, 1) forwards;
    }
    
    .modal-header {
        background: linear-gradient(135deg, rgba(59, 114, 199, 0.75), rgba(83, 155, 227, 0.75));
        background-size: 200% 200%;
        animation: gradientShift 5s ease infinite;
        padding: 25px 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-top-left-radius: 10px;
        border-top-right-radius: 10px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
    }
    
    .modal-header h2 {
        color: #f0f0f0;
        margin: 0;
        font-size: 24px;
        font-weight: 500;
        letter-spacing: 1px;
        text-shadow: 0 0 5px rgba(59, 114, 199, 0.25),
                     0 0 8px rgba(16, 13, 46, 0.2);
    }
    
    .modal-body {
        padding: 30px;
        background: linear-gradient(135deg, rgba(28, 26, 59, 0.9), rgba(18, 17, 56, 0.9));
        border-radius: 12px;
        margin: 20px;
        box-shadow: 0 6px 20px rgba(16, 13, 46, 0.5);
    }
    
    .info-section {
        background: rgba(255, 255, 255, 0.05);
        border-radius: 12px;
        padding: 25px;
        box-shadow: 0 4px 16px rgba(16, 13, 46, 0.3);
    }
    
    .requester-info {
        font-size: 18px;
        margin-bottom: 20px;
        text-align: center;
        color: #4CAF50;
        font-weight: 500;
        padding: 15px;
        background: rgba(76, 175, 80, 0.1);
        border-radius: 8px;
        border-left: 3px solid #4CAF50;
    }
    
    .coords-info {
        background: rgba(0, 0, 0, 0.2);
        padding: 20px;
        border-radius: 8px;
        border: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .coords-info h3 {
        margin-top: 0;
        color: #fff;
        font-size: 18px;
        font-weight: 500;
        margin-bottom: 15px;
        text-align: center;
        padding-bottom: 10px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .coord-details {
        font-family: monospace;
        font-size: 14px;
        line-height: 1.5;
    }

    .coord-item {
        margin-bottom: 15px;
        display: flex;
        flex-direction: column;
        background: rgba(0, 0, 0, 0.3);
        padding: 15px;
        border-radius: 8px;
        border: 1px solid rgba(255, 255, 255, 0.1);
    }

    .coord-label {
        color: #888;
        font-size: 12px;
        margin-bottom: 5px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    .coord-value {
        color: #fff;
        word-break: break-all;
        font-size: 15px;
        padding: 8px;
        background: rgba(0, 0, 0, 0.2);
        border-radius: 4px;
        border: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .modal-footer {
        display: flex;
        justify-content: space-between;
        gap: 15px;
        padding: 20px;
        background: linear-gradient(135deg, rgba(28, 26, 59, 0.9), rgba(18, 17, 56, 0.9));
    }
    
    .confirm-btn, .reject-btn {
        flex: 1;
        padding: 15px;
        border: none;
        border-radius: 8px;
        cursor: pointer;
        font-weight: bold;
        font-size: 16px;
        transition: all 0.3s ease;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        text-transform: uppercase;
        letter-spacing: 1px;
    }
    
    .confirm-btn {
        background: linear-gradient(90deg, rgba(59, 114, 199, 0.8), rgba(83, 155, 227, 0.8));
        color: white;
    }
    
    .confirm-btn:hover {
        background: linear-gradient(90deg, rgba(59, 114, 199, 1), rgba(83, 155, 227, 1));
        transform: translateY(-2px);
    }
    
    .reject-btn {
        background: linear-gradient(90deg, rgba(231, 76, 60, 0.8), rgba(192, 57, 43, 0.8));
        color: white;
    }
    
    .reject-btn:hover {
        background: linear-gradient(90deg, rgba(231, 76, 60, 1), rgba(192, 57, 43, 1));
        transform: translateY(-2px);
    }

    .confirm-btn i, .reject-btn i {
        font-size: 14px;
    }

    @keyframes gradientShift {
        0%   { background-position: 0% 50%; }
        50%  { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
    }

    @keyframes menuOpen {
        from {
            transform: translateY(-20px) scale(0.95);
            opacity: 0;
        }
        to {
            transform: translateY(0) scale(1);
            opacity: 1;
        }
    }

    @keyframes menuClose {
        from {
            transform: translateY(0) scale(1);
            opacity: 1;
        }
        to {
            transform: translateY(-20px) scale(0.95);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);
});
