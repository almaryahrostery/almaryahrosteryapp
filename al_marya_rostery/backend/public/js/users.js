// Simple Firebase Users Management
console.log('Loading Firebase Users Management...');

/**
 * Validate UAE phone number format
 * @param {string} phoneNumber - UAE phone number to validate
 * @returns {boolean} - True if valid UAE phone number format
 */
function isValidPhoneNumber(phoneNumber) {
    if (!phoneNumber || typeof phoneNumber !== 'string') {
        return false;
    }
    
    // Remove all non-digit characters except +
    const cleaned = phoneNumber.replace(/[^\d+]/g, '');
    
    // Check various UAE phone number formats
    if (cleaned.startsWith('+971')) {
        // E.164 format: +971XXXXXXXXX (13 digits total, mobile starts with 5)
        return /^\+971[5][0-9]{8}$/.test(cleaned);
    } else if (cleaned.startsWith('00971')) {
        // International format: 00971XXXXXXXXX
        return cleaned.length === 14 && /^00971[5][0-9]{8}$/.test(cleaned);
    } else if (cleaned.startsWith('971')) {
        // Country code without +: 971XXXXXXXXX
        return cleaned.length === 12 && /^971[5][0-9]{8}$/.test(cleaned);
    } else if (cleaned.startsWith('05')) {
        // Local format with leading 0: 05XXXXXXXX
        return cleaned.length === 10 && /^05[0-9]{8}$/.test(cleaned);
    } else if (cleaned.startsWith('5')) {
        // Mobile without country code: 5XXXXXXXX
        return cleaned.length === 9 && /^5[0-9]{8}$/.test(cleaned);
    } else if (cleaned.length >= 7 && cleaned.length <= 9) {
        // Assume it might be a valid UAE number
        return true; // Let backend handle detailed validation
    }
    
    return false;
}

let usersDataTable = null;

async function loadUsers() {
    console.log('loadUsers() called - Loading Firebase users...');
    try {
        showUsersSection();
        await loadFirebaseUsersData();
    } catch (error) {
        console.error('Error in loadUsers:', error);
        alert('Failed to load users: ' + error.message);
    }
}

function showUsersSection() {
    const usersSection = document.getElementById('users');
    const usersTableContainer = document.getElementById('usersTable');
    
    if (!usersSection || !usersTableContainer) {
        console.error('Users section or table container not found');
        throw new Error('Users section elements not found');
    }
    
    // Clear the existing table content and replace with our loading/table structure
    usersTableContainer.innerHTML = `
        <!-- Users Stats Cards -->
        <div class="users-stats-grid" style="display: none;" id="usersStatsGrid">
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-users"></i>
                </div>
                <div class="stat-content">
                    <h3 id="totalUsersCount">0</h3>
                    <p>Total Users</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon verified">
                    <i class="fas fa-check-circle"></i>
                </div>
                <div class="stat-content">
                    <h3 id="verifiedUsersCount">0</h3>
                    <p>Verified Users</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon active">
                    <i class="fas fa-user-check"></i>
                </div>
                <div class="stat-content">
                    <h3 id="activeUsersCount">0</h3>
                    <p>Active Users</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon providers">
                    <i class="fas fa-link"></i>
                </div>
                <div class="stat-content">
                    <h3 id="providersCount">0</h3>
                    <p>Auth Providers</p>
                </div>
            </div>
        </div>

        <!-- Loading Spinner -->
        <div id="usersLoadingSpinner" class="loading-container" style="display: block;">
            <div class="loading-spinner">
                <div class="spinner"></div>
                <div class="loading-text">
                    <h3>Loading Firebase Users...</h3>
                    <p>Fetching user data from Firebase Authentication</p>
                </div>
            </div>
        </div>
        
        <!-- Error Message -->
        <div id="usersErrorMessage" class="error-container" style="display: none;">
            <div class="error-content">
                <div class="error-icon">
                    <i class="fas fa-exclamation-triangle"></i>
                </div>
                <h3>Failed to Load Users</h3>
                <p id="errorText">An error occurred while loading user data.</p>
                <button onclick="loadFirebaseUsersData()" class="btn btn-primary retry-btn">
                    <i class="fas fa-redo"></i> Retry Loading
                </button>
            </div>
        </div>
        
        <!-- Users Table Container -->
        <div id="usersTableContainer" class="table-container" style="display: none;">
            <!-- Table Controls -->
            <div class="table-controls">
                <div class="table-controls-left">
                    <div class="search-box">
                        <i class="fas fa-search"></i>
                        <input type="text" id="usersSearchInput" placeholder="Search users by email, name, or UID..." />
                    </div>
                </div>
                <div class="table-controls-right">
                    <div class="view-toggle">
                        <button class="btn btn-sm active" onclick="setTableView('table')">
                            <i class="fas fa-table"></i> Table
                        </button>
                        <button class="btn btn-sm" onclick="setTableView('cards')">
                            <i class="fas fa-th-large"></i> Cards
                        </button>
                    </div>
                    <button class="btn btn-sm btn-secondary" onclick="exportUsers()">
                        <i class="fas fa-download"></i> Export
                    </button>
                </div>
            </div>

            <!-- Users Table -->
            <div class="table-wrapper">
                <table id="firebaseUsersTable" class="data-table users-table">
                    <thead>
                        <tr>
                            <th><i class="fas fa-fingerprint"></i> UID</th>
                            <th><i class="fas fa-envelope"></i> Email</th>
                            <th><i class="fas fa-user"></i> Display Name</th>
                            <th><i class="fas fa-phone"></i> Phone</th>
                            <th><i class="fas fa-link"></i> Provider</th>
                            <th><i class="fas fa-shield-alt"></i> Verified</th>
                            <th><i class="fas fa-calendar-plus"></i> Created</th>
                            <th><i class="fas fa-clock"></i> Last Sign In</th>
                            <th><i class="fas fa-toggle-on"></i> Status</th>
                            <th><i class="fas fa-cog"></i> Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Users will be populated here -->
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

async function loadFirebaseUsersData() {
    console.log('Loading Firebase users from API...');
    
    const loadingSpinner = document.getElementById('usersLoadingSpinner');
    const errorMessage = document.getElementById('usersErrorMessage');
    const tableContainer = document.getElementById('usersTableContainer');
    
    loadingSpinner.style.display = 'block';
    errorMessage.style.display = 'none';
    tableContainer.style.display = 'none';
    
    try {
        const token = localStorage.getItem('adminToken');
        if (!token) {
            throw new Error('Admin token not found. Please login again.');
        }
        
        const response = await fetch('/api/admin/firebase-users?limit=100', {
            method: 'GET',
            headers: {
                'Authorization': 'Bearer ' + token,
                'Content-Type': 'application/json'
            }
        });
        
        console.log('API Response status:', response.status);
        
        if (!response.ok) {
            throw new Error('API request failed: ' + response.status);
        }
        
        const data = await response.json();
        console.log('Response data:', data);
        
        if (data.success && data.data && data.data.users) {
            displayFirebaseUsersTable(data.data.users);
        } else {
            throw new Error(data.message || 'Invalid response format');
        }
        
    } catch (error) {
        console.error('Error loading Firebase users:', error);
        showUsersError(error.message);
    }
}

function displayFirebaseUsersTable(users) {
    console.log('Displaying', users.length, 'users in table');
    
    const loadingSpinner = document.getElementById('usersLoadingSpinner');
    const errorMessage = document.getElementById('usersErrorMessage');
    const tableContainer = document.getElementById('usersTableContainer');
    const statsGrid = document.getElementById('usersStatsGrid');
    
    // Hide loading and error, show stats and table
    if (loadingSpinner) loadingSpinner.style.display = 'none';
    if (errorMessage) errorMessage.style.display = 'none';
    if (statsGrid) statsGrid.style.display = 'grid';
    if (tableContainer) tableContainer.style.display = 'block';
    
    // Update user statistics
    updateUserStats(users);
    
    // Clear and populate table
    const tableBody = document.querySelector('#firebaseUsersTable tbody');
    if (tableBody) {
        tableBody.innerHTML = '';
        
        users.forEach((user, index) => {
            const row = createUserTableRow(user, index);
            tableBody.appendChild(row);
        });
    }
    
    // Simple table functionality without jQuery DataTable
    try {
        // Add simple search functionality
        const searchInput = document.getElementById('usersSearchInput');
        if (searchInput) {
            searchInput.addEventListener('keyup', function() {
                const filter = this.value.toLowerCase();
                const rows = document.querySelectorAll('#firebaseUsersTable tbody tr');
                
                rows.forEach(row => {
                    const text = row.textContent.toLowerCase();
                    row.style.display = text.includes(filter) ? '' : 'none';
                });
            });
        }
        
        console.log('✅ Simple table functionality initialized successfully');
    } catch (error) {
        console.error('⚠️ Table initialization failed:', error);
    }
}

function createUserTableRow(user, index) {
    const row = document.createElement('tr');
    row.className = 'user-row';
    
    // Generate a shorter UID display
    const shortUid = user.uid ? user.uid.substring(0, 8) + '...' : 'N/A';
    
    // Get provider badge
    const providerBadge = getProviderBadge(user.providerData);
    
    // Get verification status
    const verificationStatus = user.emailVerified ? 
        '<span class="status-badge verified"><i class="fas fa-check-circle"></i> Verified</span>' : 
        '<span class="status-badge unverified"><i class="fas fa-times-circle"></i> Not Verified</span>';
    
    // Get user status
    const userStatus = user.disabled ? 
        '<span class="status-badge disabled"><i class="fas fa-ban"></i> Disabled</span>' : 
        '<span class="status-badge active"><i class="fas fa-check"></i> Active</span>';
    
    row.innerHTML = `
        <td class="uid-cell" title="${user.uid}">
            <span class="uid-text">${shortUid}</span>
            <button class="copy-btn" onclick="copyToClipboard('${user.uid}')" title="Copy full UID">
                <i class="fas fa-copy"></i>
            </button>
        </td>
        <td class="email-cell">
            <div class="user-info">
                <span class="email">${user.email || 'N/A'}</span>
                ${user.emailVerified ? '<i class="fas fa-shield-alt verified-icon" title="Email Verified"></i>' : ''}
            </div>
        </td>
        <td class="name-cell">
            <div class="user-profile">
                <div class="user-avatar">
                    ${user.photoURL ? 
                        `<img src="${user.photoURL}" alt="Avatar" class="avatar-img">` : 
                        `<i class="fas fa-user-circle"></i>`
                    }
                </div>
                <span class="display-name">${user.displayName || 'No display name'}</span>
            </div>
        </td>
        <td class="phone-cell">${user.phoneNumber || 'N/A'}</td>
        <td class="provider-cell">${providerBadge}</td>
        <td class="verification-cell">${verificationStatus}</td>
        <td class="date-cell">${formatDate(user.metadata?.creationTime)}</td>
        <td class="date-cell">${formatDate(user.metadata?.lastSignInTime)}</td>
        <td class="status-cell">${userStatus}</td>
        <td class="actions-cell">
            <div class="action-buttons">
                <button class="btn btn-xs btn-info" onclick="viewUserDetails('${user.uid}')" title="View Details">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-xs btn-warning" onclick="editUser('${user.uid}')" title="Edit User">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-xs ${user.disabled ? 'btn-success' : 'btn-secondary'}" 
                        onclick="toggleUserStatus('${user.uid}', ${user.disabled})" 
                        title="${user.disabled ? 'Enable User' : 'Disable User'}">
                    <i class="fas fa-${user.disabled ? 'toggle-on' : 'toggle-off'}"></i>
                </button>
            </div>
        </td>
    `;
    
    return row;
}

function updateUserStats(users) {
    const totalCount = users.length;
    const verifiedCount = users.filter(user => user.emailVerified).length;
    const activeCount = users.filter(user => !user.disabled).length;
    
    // Count unique providers
    const providers = new Set();
    users.forEach(user => {
        if (user.providerData && Array.isArray(user.providerData)) {
            user.providerData.forEach(provider => providers.add(provider.providerId));
        }
    });
    const providersCount = providers.size;
    
    // Update stat elements
    const totalElement = document.getElementById('totalUsersCount');
    const verifiedElement = document.getElementById('verifiedUsersCount');
    const activeElement = document.getElementById('activeUsersCount');
    const providersElement = document.getElementById('providersCount');
    
    if (totalElement) totalElement.textContent = totalCount;
    if (verifiedElement) verifiedElement.textContent = verifiedCount;
    if (activeElement) activeElement.textContent = activeCount;
    if (providersElement) providersElement.textContent = providersCount;
    
    console.log(`📊 Stats updated: ${totalCount} total, ${verifiedCount} verified, ${activeCount} active, ${providersCount} providers`);
}

function showUsersError(message) {
    const loadingSpinner = document.getElementById('usersLoadingSpinner');
    const errorMessage = document.getElementById('usersErrorMessage');
    const tableContainer = document.getElementById('usersTableContainer');
    const errorText = document.getElementById('errorText');
    
    loadingSpinner.style.display = 'none';
    tableContainer.style.display = 'none';
    errorMessage.style.display = 'block';
    errorText.textContent = message;
}

function getProviderInfo(providerData) {
    if (!providerData || !Array.isArray(providerData) || providerData.length === 0) {
        return 'Email';
    }
    
    const providers = providerData.map(provider => {
        switch (provider.providerId) {
            case 'google.com': return 'Google';
            case 'facebook.com': return 'Facebook';
            case 'password': return 'Email';
            default: return provider.providerId;
        }
    });
    
    return providers.join(', ');
}

function getProviderBadge(providerData) {
    if (!providerData || !Array.isArray(providerData) || providerData.length === 0) {
        return '<span class="provider-badge email"><i class="fas fa-envelope"></i> Email</span>';
    }
    
    const badges = providerData.map(provider => {
        switch (provider.providerId) {
            case 'google.com': 
                return '<span class="provider-badge google"><i class="fab fa-google"></i> Google</span>';
            case 'facebook.com': 
                return '<span class="provider-badge facebook"><i class="fab fa-facebook"></i> Facebook</span>';
            case 'password': 
                return '<span class="provider-badge email"><i class="fas fa-envelope"></i> Email</span>';
            default: 
                return `<span class="provider-badge other"><i class="fas fa-link"></i> ${provider.providerId}</span>`;
        }
    });
    
    return badges.join(' ');
}

function formatDate(dateString) {
    if (!dateString) return '<span class="no-data">N/A</span>';
    
    try {
        const date = new Date(dateString);
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        let timeAgo = '';
        if (diffDays === 1) {
            timeAgo = '1 day ago';
        } else if (diffDays < 30) {
            timeAgo = `${diffDays} days ago`;
        } else if (diffDays < 365) {
            const months = Math.floor(diffDays / 30);
            timeAgo = `${months} month${months > 1 ? 's' : ''} ago`;
        } else {
            const years = Math.floor(diffDays / 365);
            timeAgo = `${years} year${years > 1 ? 's' : ''} ago`;
        }
        
        return `
            <div class="date-info">
                <span class="date-primary">${date.toLocaleDateString()}</span>
                <span class="date-secondary">${timeAgo}</span>
            </div>
        `;
    } catch (error) {
        return '<span class="no-data">Invalid Date</span>';
    }
}

// Helper functions for user actions
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showToast('UID copied to clipboard!', 'success');
    }).catch(() => {
        showToast('Failed to copy UID', 'error');
    });
}

function viewUserDetails(uid) {
    // Get user data from table
    const users = getUsersFromTable();
    const user = users.find(u => u.uid === uid);
    
    if (!user) {
        showToast('User not found', 'error');
        return;
    }
    
    // Create and show user detail modal
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="modal-content" style="max-width: 600px;">
            <div class="modal-header">
                <h2>Firebase User Details</h2>
                <button class="btn-close" onclick="this.closest('.modal-overlay').remove()">&times;</button>
            </div>
            <div class="modal-body" style="max-height: 500px; overflow-y: auto;">
                <div class="user-detail-card">
                    <div class="detail-row">
                        <label>UID:</label>
                        <span class="mono" onclick="copyToClipboard('${uid}')" style="cursor: pointer; text-decoration: underline;">
                            ${uid}
                        </span>
                    </div>
                    <div class="detail-row">
                        <label>Email:</label>
                        <span>${user.email || 'N/A'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Display Name:</label>
                        <span>${user.displayName || user['display-name'] || 'Not set'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Phone Number:</label>
                        <span>${user.phoneNumber || user['phone-number'] || 'Not set'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Email Verified:</label>
                        <span class="badge ${user.emailVerified || user['email-verified'] ? 'success' : 'warning'}">
                            ${user.emailVerified || user['email-verified'] ? 'Verified' : 'Not Verified'}
                        </span>
                    </div>
                    <div class="detail-row">
                        <label>Account Status:</label>
                        <span class="badge ${user.disabled ? 'danger' : 'success'}">
                            ${user.disabled ? 'Disabled' : 'Active'}
                        </span>
                    </div>
                    <div class="detail-row">
                        <label>Account Created:</label>
                        <span>${user.createdAt || user['created-at'] || 'N/A'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Last Sign In:</label>
                        <span>${user.lastSignInTime || user['last-sign-in'] || 'Never'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Provider(s):</label>
                        <span>${user.providers || user['auth-provider'] || 'Email/Password'}</span>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="this.closest('.modal-overlay').remove()">Close</button>
                <button class="btn btn-warning" onclick="editUser('${uid}'); this.closest('.modal-overlay').remove()">Edit</button>
                <button class="btn btn-danger" onclick="toggleUserStatus('${uid}', ${!user.disabled}); this.closest('.modal-overlay').remove()">
                    ${user.disabled ? 'Enable' : 'Disable'}
                </button>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Add styles if not present
    addUserDetailStyles();
}

function editUser(uid) {
    console.log('Edit user:', uid);
    
    // Find the user data
    const users = getUsersFromTable();
    const user = users.find(u => u.uid === uid);
    
    if (!user) {
        showToast('User not found', 'error');
        return;
    }
    
    showUserEditModal(user);
}

function getUsersFromTable() {
    // Extract user data from the current table
    const users = [];
    const tableRows = document.querySelectorAll('#firebaseUsersTable tbody tr');
    
    tableRows.forEach(row => {
        const cells = row.querySelectorAll('td');
        if (cells.length >= 9) {
            const uid = cells[0].getAttribute('title') || cells[0].textContent.trim();
            const email = cells[1].querySelector('.email')?.textContent.trim();
            const displayName = cells[2].querySelector('.display-name')?.textContent.trim();
            const phoneNumber = cells[3].textContent.trim() === 'N/A' ? null : cells[3].textContent.trim();
            const emailVerified = cells[5].textContent.includes('Verified');
            const disabled = cells[8].textContent.includes('Disabled');
            
            users.push({
                uid: uid.replace('...', ''),
                email,
                displayName: displayName === 'No display name' ? null : displayName,
                phoneNumber,
                emailVerified,
                disabled
            });
        }
    });
    
    return users;
}

function showUserEditModal(user) {
    // Create modal HTML
    const modalHTML = `
        <div class="modal-overlay" id="userEditModal">
            <div class="user-edit-modal">
                <div class="modal-header">
                    <h3><i class="fas fa-user-edit"></i> Edit User</h3>
                    <button class="close-btn" onclick="closeUserEditModal()">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                
                <div class="modal-body">
                    <form id="userEditForm">
                        <input type="hidden" id="editUserId" value="${user.uid}">
                        
                        <!-- User Info Section -->
                        <div class="form-section">
                            <h4><i class="fas fa-user"></i> User Information</h4>
                            
                            <div class="form-row">
                                <div class="form-group">
                                    <label for="editDisplayName">Display Name</label>
                                    <input type="text" id="editDisplayName" value="${user.displayName || ''}" 
                                           placeholder="Enter display name">
                                </div>
                                <div class="form-group">
                                    <label for="editEmail">Email Address</label>
                                    <input type="email" id="editEmail" value="${user.email || ''}" 
                                           placeholder="Enter email address">
                                </div>
                            </div>
                            
                            <div class="form-row">
                                <div class="form-group">
                                    <label for="editPhoneNumber">UAE Phone Number</label>
                                    <input type="tel" id="editPhoneNumber" value="${user.phoneNumber || ''}" 
                                           placeholder="e.g., +971501234567, 0501234567, or 501234567">
                                    <small class="form-text">UAE mobile numbers only (starting with 05 or 5)</small>
                                </div>
                                <div class="form-group">
                                    <label for="editPhotoURL">Profile Photo URL</label>
                                    <input type="url" id="editPhotoURL" value="${user.photoURL || ''}" 
                                           placeholder="Enter photo URL">
                                </div>
                            </div>
                        </div>
                        
                        <!-- Account Status Section -->
                        <div class="form-section">
                            <h4><i class="fas fa-shield-alt"></i> Account Status</h4>
                            
                            <div class="form-row">
                                <div class="form-group checkbox-group">
                                    <label class="checkbox-label">
                                        <input type="checkbox" id="editEmailVerified" 
                                               ${user.emailVerified ? 'checked' : ''}>
                                        <span class="checkmark"></span>
                                        Email Verified
                                    </label>
                                </div>
                                <div class="form-group checkbox-group">
                                    <label class="checkbox-label">
                                        <input type="checkbox" id="editDisabled" 
                                               ${user.disabled ? 'checked' : ''}>
                                        <span class="checkmark"></span>
                                        Account Disabled
                                    </label>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Custom Claims Section -->
                        <div class="form-section">
                            <h4><i class="fas fa-key"></i> Custom Claims</h4>
                            <div class="form-group">
                                <label for="editCustomClaims">Custom Claims (JSON)</label>
                                <textarea id="editCustomClaims" rows="4" 
                                          placeholder='{"role": "admin", "permissions": ["read", "write"]}'></textarea>
                                <small class="form-help">Enter valid JSON for custom claims</small>
                            </div>
                        </div>
                        
                        <!-- Password Reset Section -->
                        <div class="form-section">
                            <h4><i class="fas fa-lock"></i> Password Management</h4>
                            <div class="form-group">
                                <label for="editNewPassword">New Password (Optional)</label>
                                <input type="password" id="editNewPassword" 
                                       placeholder="Enter new password (leave blank to keep current)">
                                <small class="form-help">Minimum 6 characters required</small>
                            </div>
                        </div>
                    </form>
                </div>
                
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeUserEditModal()">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                    <button type="button" class="btn btn-warning" onclick="sendPasswordResetEmail('${user.uid}')">
                        <i class="fas fa-envelope"></i> Send Password Reset
                    </button>
                    <button type="submit" class="btn btn-primary" onclick="saveUserChanges()">
                        <i class="fas fa-save"></i> Save Changes
                    </button>
                </div>
            </div>
        </div>
    `;
    
    // Add modal to page
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    
    // Show modal
    setTimeout(() => {
        document.getElementById('userEditModal').style.display = 'flex';
    }, 10);
    
    // Load user's custom claims
    loadUserCustomClaims(user.uid);
}

async function loadUserCustomClaims(uid) {
    try {
        const token = localStorage.getItem('adminToken');
        const response = await fetch(`/api/admin/firebase-users/${uid}`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            if (data.success && data.user.customClaims) {
                document.getElementById('editCustomClaims').value = 
                    JSON.stringify(data.user.customClaims, null, 2);
            }
        }
    } catch (error) {
        console.error('Error loading custom claims:', error);
    }
}

function closeUserEditModal() {
    const modal = document.getElementById('userEditModal');
    if (modal) {
        modal.style.display = 'none';
        setTimeout(() => {
            modal.remove();
        }, 300);
    }
}

async function saveUserChanges() {
    const uid = document.getElementById('editUserId').value;
    const displayName = document.getElementById('editDisplayName').value.trim();
    const email = document.getElementById('editEmail').value.trim();
    const phoneNumber = document.getElementById('editPhoneNumber').value.trim();
    const photoURL = document.getElementById('editPhotoURL').value.trim();
    const emailVerified = document.getElementById('editEmailVerified').checked;
    const disabled = document.getElementById('editDisabled').checked;
    const newPassword = document.getElementById('editNewPassword').value.trim();
    const customClaimsText = document.getElementById('editCustomClaims').value.trim();
    
    // Validate required fields
    if (!email) {
        showToast('Email is required', 'error');
        return;
    }
    
    // Validate UAE phone number format if provided
    if (phoneNumber && !isValidPhoneNumber(phoneNumber)) {
        showToast('Invalid UAE phone number format. Please use UAE mobile format (e.g., +971501234567, 0501234567, or 501234567)', 'error');
        return;
    }
    
    // Validate custom claims JSON
    let customClaims = null;
    if (customClaimsText) {
        try {
            customClaims = JSON.parse(customClaimsText);
        } catch (error) {
            showToast('Invalid JSON in custom claims', 'error');
            return;
        }
    }
    
    // Validate password
    if (newPassword && newPassword.length < 6) {
        showToast('Password must be at least 6 characters', 'error');
        return;
    }
    
    try {
        showLoading('Saving user changes...');
        
        const updateData = {
            displayName: displayName || null,
            email,
            phoneNumber: phoneNumber || null,
            photoURL: photoURL || null,
            emailVerified,
            disabled,
            customClaims
        };
        
        if (newPassword) {
            updateData.password = newPassword;
        }
        
        const token = localStorage.getItem('adminToken');
        const response = await fetch(`/api/admin/firebase-users/${uid}`, {
            method: 'PUT',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(updateData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showToast('User updated successfully!', 'success');
            closeUserEditModal();
            // Refresh the users table
            await loadFirebaseUsersData();
        } else {
            showToast(result.message || 'Failed to update user', 'error');
        }
        
    } catch (error) {
        console.error('Error updating user:', error);
        showToast('Failed to update user', 'error');
    } finally {
        hideLoading();
    }
}

async function sendPasswordResetEmail(uid) {
    try {
        showLoading('Sending password reset email...');
        
        const token = localStorage.getItem('adminToken');
        const response = await fetch(`/api/admin/firebase-users/${uid}/reset-password`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });
        
        const result = await response.json();
        
        if (result.success) {
            showToast('Password reset email sent successfully!', 'success');
        } else {
            showToast(result.message || 'Failed to send reset email', 'error');
        }
        
    } catch (error) {
        console.error('Error sending reset email:', error);
        showToast('Failed to send reset email', 'error');
    } finally {
        hideLoading();
    }
}

function showLoading(message = 'Loading...') {
    const existing = document.getElementById('globalLoading');
    if (existing) existing.remove();
    
    const loadingHTML = `
        <div id="globalLoading" class="global-loading">
            <div class="spinner"></div>
            <p>${message}</p>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', loadingHTML);
}

function hideLoading() {
    const loading = document.getElementById('globalLoading');
    if (loading) {
        loading.remove();
    }
}

function toggleUserStatus(uid, currentlyDisabled) {
    // Implement user status toggle
    console.log('Toggle user status:', uid, 'Currently disabled:', currentlyDisabled);
    showToast('User status toggle feature coming soon!', 'info');
}

function setTableView(view) {
    // Implement table/cards view toggle
    console.log('Set table view:', view);
    
    // Update button states
    document.querySelectorAll('.view-toggle .btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.closest('.btn').classList.add('active');
}

function exportUsers() {
    // Implement user export functionality
    console.log('Export users');
    showToast('Export feature coming soon!', 'info');
}

function showToast(message, type = 'info') {
    // Simple toast notification
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(() => toast.classList.add('show'), 100);
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => document.body.removeChild(toast), 300);
    }, 3000);
}

window.loadUsers = loadUsers;
window.loadFirebaseUsersData = loadFirebaseUsersData;

console.log('Simple Firebase Users Management loaded successfully!');

// Helper function to add modal styles
function addUserDetailStyles() {
    if (document.getElementById('user-detail-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'user-detail-styles';
    style.innerHTML = `
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
        }
        
        .modal-content {
            background: white;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
            display: flex;
            flex-direction: column;
            max-height: 90vh;
        }
        
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px;
            border-bottom: 1px solid #eee;
        }
        
        .modal-header h2 {
            margin: 0;
            font-size: 20px;
            color: #333;
        }
        
        .modal-body {
            padding: 20px;
            overflow-y: auto;
            flex: 1;
        }
        
        .modal-footer {
            padding: 15px 20px;
            border-top: 1px solid #eee;
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        
        .user-detail-card {
            background: #f9f9f9;
            border-radius: 8px;
            padding: 15px;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #eee;
        }
        
        .detail-row:last-child {
            border-bottom: none;
        }
        
        .detail-row label {
            font-weight: 600;
            color: #555;
            min-width: 150px;
        }
        
        .detail-row span {
            color: #333;
        }
        
        .detail-row .mono {
            font-family: monospace;
            font-size: 12px;
            color: #666;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge.success {
            background: #d4edda;
            color: #155724;
        }
        
        .badge.warning {
            background: #fff3cd;
            color: #856404;
        }
        
        .badge.danger {
            background: #f8d7da;
            color: #721c24;
        }
        
        .btn-close {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #555;
        }
        
        .btn-close:hover {
            color: #000;
        }
    `;
    
    document.head.appendChild(style);
}

/**
 * Show modal to add a new user
 * This function is called from the Add User button in the Users section
 */
function showAddUserModal() {
    const modalHTML = `
        <div class="modal-overlay" id="addUserModal">
            <div class="user-edit-modal">
                <div class="modal-header">
                    <h3><i class="fas fa-user-plus"></i> Add New User</h3>
                    <button class="close-btn" onclick="closeAddUserModal()">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                
                <div class="modal-body">
                    <div style="padding: 2rem; text-align: center; color: #666;">
                        <i class="fas fa-info-circle" style="font-size: 2rem; margin-bottom: 1rem; color: var(--info);"></i>
                        <p style="margin: 1rem 0;"><strong>Add User Feature Coming Soon</strong></p>
                        <p>User management is currently handled through Firebase Admin Panel.</p>
                        <p>To add users, please use the Firebase Console or the registration endpoint.</p>
                        <button class="btn btn-secondary" onclick="closeAddUserModal()" style="margin-top: 1rem;">
                            Close
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Remove any existing modal
    const existing = document.getElementById('addUserModal');
    if (existing) {
        existing.remove();
    }
    
    // Create and show modal
    const temp = document.createElement('div');
    temp.innerHTML = modalHTML;
    document.body.appendChild(temp.firstElementChild);
    
    // Add click outside to close
    document.getElementById('addUserModal').addEventListener('click', function(e) {
        if (e.target === this) {
            closeAddUserModal();
        }
    });
}

/**
 * Close the add user modal
 */
function closeAddUserModal() {
    const modal = document.getElementById('addUserModal');
    if (modal) {
        modal.remove();
    }
}

