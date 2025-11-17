/* Al Marya Rostery Admin Panel - Main JavaScript File */

// Configuration
const API_BASE_URL = window.location.hostname === 'localhost' 
    ? `http://localhost:${window.location.port || '5001'}` 
    : 'https://almaryahrostery.onrender.com';

// Global variables
let currentSection = 'dashboard';
let charts = {};
let currentUser = null;
let authToken = null;

// Helper function to validate JWT token format
function isValidToken(token) {
    if (!token || typeof token !== 'string') return false;
    const parts = token.split('.');
    return parts.length === 3 && parts.every(part => part.length > 0);
}

// Initialize admin panel
document.addEventListener('DOMContentLoaded', function() {
    // Initialize login form event listeners first
    initializeLoginForm();
    
    // Then check authentication
    checkAuthentication();
    
    // Track performance
    trackPerformance();
    
    // Show welcome message only in development
    if (window.location.hostname === 'localhost') {
        console.log('Al Marya Rostery Admin Panel - Ready');
    }
});

/* ===== AUTHENTICATION FUNCTIONS ===== */

function initializeLoginForm() {
    const usernameInput = document.getElementById('loginUsername');
    const passwordInput = document.getElementById('loginPassword');
    const usernameError = document.getElementById('username-error');
    const passwordError = document.getElementById('password-error');
    const forgotPasswordLink = document.getElementById('forgot-password-link');

    // Focus on username field when page loads
    if (usernameInput && usernameInput.offsetParent !== null) {
        usernameInput.focus();
    }

    // Input validation on blur
    if (usernameInput) {
        usernameInput.addEventListener('blur', function() {
            if (!this.value.trim()) {
                showError(usernameError, 'Username is required');
            } else {
                hideError(usernameError);
            }
        });
    }

    if (passwordInput) {
        passwordInput.addEventListener('blur', function() {
            if (!this.value.trim()) {
                showError(passwordError, 'Password is required');
            } else {
                hideError(passwordError);
            }
        });
    }

    // Forgot password functionality
    if (forgotPasswordLink) {
        forgotPasswordLink.addEventListener('click', function(e) {
            e.preventDefault();
            alert('Please contact system administrator to reset your password.');
        });
    }

    // Form submit handler
    const loginForm = document.getElementById('adminLoginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', function(e) {
            handleLogin(e);
        });
    }
}

function checkAuthentication() {
    authToken = localStorage.getItem('adminToken');
    currentUser = JSON.parse(localStorage.getItem('adminUser') || 'null');
    
    if (authToken && isValidToken(authToken) && currentUser) {
        showAdminPanel();
    } else {
        if (authToken && !isValidToken(authToken)) {
            localStorage.removeItem('adminToken');
            localStorage.removeItem('adminUser');
            authToken = null;
            currentUser = null;
        }
        showLoginPage();
    }
}

function showLoginPage() {
    document.body.className = 'login-mode';
    document.getElementById('loginContainer').style.display = 'flex';
    document.getElementById('adminLayout').style.display = 'none';
    
    setTimeout(() => {
        const usernameInput = document.getElementById('loginUsername');
        if (usernameInput) {
            usernameInput.focus();
        }
    }, 100);
}

function showAdminPanel() {
    document.body.className = 'admin-mode';
    document.getElementById('loginContainer').style.display = 'none';
    document.getElementById('adminLayout').style.display = 'block';
    initializeAdmin();
}

async function handleLogin(event) {
    event.preventDefault();
    
    resetErrors();
    
    const username = document.getElementById('loginUsername').value.trim();
    const password = document.getElementById('loginPassword').value.trim();
    const loginBtn = document.getElementById('loginBtn');
    const loginLoading = document.getElementById('loginLoading');
    const usernameError = document.getElementById('username-error');
    const passwordError = document.getElementById('password-error');
    
    let isValid = true;
    
    if (!username) {
        showError(usernameError, 'Username is required');
        isValid = false;
    }
    
    if (!password) {
        showError(passwordError, 'Password is required');
        isValid = false;
    }
    
    if (!isValid) return;
    
    loginBtn.disabled = true;
    loginBtn.textContent = 'Logging in...';
    loginBtn.classList.add('loading');
    loginLoading.style.display = 'block';
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/auth/admin-login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email: username, password })
        });
        
        const data = await response.json();
        
        if (data.success) {
            authToken = data.data.token;
            currentUser = data.data.user;
            
            // Validate token format before storing
            if (!isValidToken(authToken)) {
                throw new Error('Invalid token format received from server');
            }
            
            localStorage.setItem('adminToken', authToken);
            localStorage.setItem('adminUser', JSON.stringify(currentUser));
            
            document.getElementById('loginSuccess').style.display = 'block';
            
            // Wait a bit longer to ensure token is fully stored and propagated
            setTimeout(() => {
                showAdminPanel();
            }, 1500);
        } else {
            throw new Error('Invalid credentials');
        }
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('Login error:', error);
        document.getElementById('loginError').style.display = 'block';
        document.getElementById('loginPassword').value = '';
        document.getElementById('loginPassword').focus();
    } finally {
        loginBtn.disabled = false;
        loginBtn.textContent = 'Login to Admin Panel';
        loginBtn.classList.remove('loading');
        loginLoading.style.display = 'none';
    }
}

function resetErrors() {
    hideError(document.getElementById('username-error'));
    hideError(document.getElementById('password-error'));
    hideError(document.getElementById('loginError'));
    hideError(document.getElementById('loginSuccess'));
}

function showError(errorElementOrMessage, message) {
    // Support both use cases:
    // showError(element, message) - traditional use
    // showError(message) - new use with toast
    if (typeof errorElementOrMessage === 'string' && !message) {
        // Single parameter - show as toast
        showToast(errorElementOrMessage, 'error', 4000);
    } else if (errorElementOrMessage && message) {
        // Two parameters - traditional use
        errorElementOrMessage.textContent = message;
        errorElementOrMessage.style.display = 'block';
    }
}

function hideError(errorElement) {
    if (errorElement) {
        errorElement.style.display = 'none';
    }
}

function logout() {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    authToken = null;
    currentUser = null;
    showLoginPage();
}

/* ===== API HELPER FUNCTIONS ===== */

async function authenticatedFetch(url, options = {}) {
    const defaultHeaders = {};
    
    // Only set Content-Type for non-FormData requests
    // FormData requires browser to set Content-Type with boundary
    if (!(options.body instanceof FormData)) {
        defaultHeaders['Content-Type'] = 'application/json';
    }
    
    if (authToken && isValidToken(authToken)) {
        defaultHeaders['Authorization'] = `Bearer ${authToken}`;
    } else {
        const logger = window.adminUtils?.logger || console;
        logger.error('No valid auth token available for request');
        throw new Error('No authentication token available');
    }
    
    const config = {
        ...options,
        headers: {
            ...defaultHeaders,
            ...options.headers
        }
    };
    
    try {
        const response = await fetch(url, config);
        const logger = window.adminUtils?.logger || console;
        
        if (response.status === 401) {
            // Log the failure but check if this is a persistent issue
            logger.warn(`Authentication failed for ${url} (401)`);
            logger.warn(`Token being used: ${authToken ? authToken.substring(0, 30) + '...' : 'none'}`);
            
            // Try to parse the error response
            let errorMessage = 'Authentication expired - please login again';
            try {
                const errorData = await response.json();
                errorMessage = errorData.message || errorMessage;
            } catch (e) {
                // Ignore JSON parse errors
            }
            
            // Only logout if this seems like a real auth failure
            // Give backend a chance if it's just starting up
            if (!url.includes('/health')) {
                logout();
            }
            throw new Error(errorMessage);
        }
        
        if (!response.ok) {
            // Try to get error details from response body
            let errorDetails = '';
            try {
                const errorData = await response.clone().json();
                errorDetails = errorData.message || JSON.stringify(errorData);
                logger.error(`HTTP ${response.status} error details:`, errorData);
            } catch (e) {
                // Couldn't parse as JSON, try text
                try {
                    errorDetails = await response.clone().text();
                    logger.error(`HTTP ${response.status} error text:`, errorDetails);
                } catch (e2) {
                    // Ignore
                }
            }
            throw new Error(`HTTP error! status: ${response.status}${errorDetails ? ' - ' + errorDetails : ''}`);
        }
        
        return response;
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('API Request failed:', error);
        throw error;
    }
}

async function handleApiResponse(response) {
    if (!response) {
        throw new Error('No response received');
    }
    
    const data = await response.json();
    return data;
}

/* ===== CORE ADMIN FUNCTIONS ===== */

async function initializeAdmin() {
    showGlobalLoading('Initializing Admin Panel...');
    
    initProductionFeatures();
    
    const logger = window.adminUtils?.logger || console;
    
    // Verify we have a valid token before proceeding
    if (!authToken || !isValidToken(authToken)) {
        logger.error('No valid token found during initialization');
        hideGlobalLoading();
        logout();
        return;
    }
    
    logger.log('Initializing with token:', authToken.substring(0, 20) + '...');
    
    try {
        const healthCheck = await fetch(`${API_BASE_URL}/health`);
        if (!healthCheck.ok) {
            logger.warn('Backend health check failed');
        }
    } catch (error) {
        logger.warn('Backend connectivity check failed:', error.message);
        showErrorById('dashboardStats', 'Backend server unavailable - please check connection');
        hideGlobalLoading();
        return;
    }
    
    // Load dashboard data - but don't let failures cause immediate logout
    try {
        await loadDashboardData();
    } catch (error) {
        logger.warn('Dashboard data load failed:', error.message);
        // Don't throw - let user stay logged in even if dashboard fails
    }
    
    // Load categories if function exists
    if (typeof loadCategories === 'function') {
        loadCategories();
    }
    
    initializeCharts();
    hideGlobalLoading();
}

// Section navigation
function showSection(sectionId) {
    // Update current section
    currentSection = sectionId;
    
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(section => {
        section.classList.remove('active');
    });
    
    // Remove active class from all menu items
    document.querySelectorAll('.menu-item').forEach(item => {
        item.classList.remove('active');
    });
    
    // Show selected section
    const targetSection = document.getElementById(sectionId);
    if (targetSection) {
        targetSection.classList.add('active');
        
        // Add active class to corresponding menu item
        const menuItem = document.querySelector(`.menu-item[onclick="showSection('${sectionId}')"]`);
        if (menuItem) {
            menuItem.classList.add('active');
        }
        
        // Load section-specific data
        loadSectionData(sectionId);
    }
}

// Dashboard tab navigation
function showDashboardTab(tabId) {
    // Hide all tab contents
    document.querySelectorAll('.dashboard-tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    document.querySelectorAll('.tab-button').forEach(button => {
        button.classList.remove('active');
    });
    
    // Show selected tab
    const targetTab = document.getElementById(`${tabId}-tab`);
    if (targetTab) {
        targetTab.classList.add('active');
        
        // Add active class to corresponding tab button
        const tabButton = document.querySelector(`.tab-button[data-tab="${tabId}"]`);
        if (tabButton) {
            tabButton.classList.add('active');
        }
        
        // Load tab-specific data
        loadDashboardTabData(tabId);
    }
}

// Load data for dashboard tabs
function loadDashboardTabData(tabId) {
    switch(tabId) {
        case 'overview':
            loadDashboardData();
            break;
        case 'analytics':
            loadAnalytics();
            break;
        case 'reports':
            loadReports();
            break;
    }
}

// Load section-specific data
function loadSectionData(sectionId) {
    switch(sectionId) {
        case 'dashboard':
            // For dashboard, load the current active tab
            const activeTab = document.querySelector('.tab-button.active')?.getAttribute('data-tab') || 'overview';
            loadDashboardTabData(activeTab);
            break;
        case 'products':
            if (typeof loadProducts === 'function') loadProducts();
            break;
        case 'attributes':
            if (typeof initializeAttributesSection === 'function') initializeAttributesSection();
            break;
        case 'orders':
            if (typeof loadOrders === 'function') loadOrders();
            break;
        case 'users':
            if (typeof loadUsers === 'function') loadUsers();
            break;
        case 'staff':
            if (typeof staffManager !== 'undefined' && staffManager.init) {
                staffManager.init();
            }
            break;
        case 'drivers':
            if (typeof driverManager !== 'undefined' && driverManager.init) {
                driverManager.init();
            }
            break;
        case 'reviews':
            if (typeof loadReviews === 'function') loadReviews();
            break;
        case 'loyalty':
            if (typeof loadLoyalty === 'function') loadLoyalty();
            break;
        case 'referrals':
            if (typeof loadReferrals === 'function') loadReferrals();
            break;
        case 'subscriptions':
            if (typeof loadSubscriptions === 'function') loadSubscriptions();
            break;
        case 'settings':
            if (typeof loadSettings === 'function') loadSettings();
            break;
        case 'sliders':
            if (typeof loadSliders === 'function') loadSliders();
            break;
        case 'brewing-methods':
            if (typeof brewingMethodsManager !== 'undefined' && brewingMethodsManager.init) {
                brewingMethodsManager.init();
            }
            break;
        case 'accessories':
            if (typeof accessoriesManager !== 'undefined' && accessoriesManager.init) {
                accessoriesManager.init();
            }
            break;
        case 'gift-sets':
            if (typeof giftSetsManager !== 'undefined' && giftSetsManager.init) {
                giftSetsManager.init();
            }
            break;
        case 'contact-inquiries':
            if (typeof contactInquiriesManager !== 'undefined' && contactInquiriesManager.init) {
                contactInquiriesManager.init();
            }
            break;
        case 'newsletters':
            if (typeof newslettersManager !== 'undefined' && newslettersManager.init) {
                newslettersManager.init();
            }
            break;
        case 'support-tickets':
            if (typeof supportTicketsManager !== 'undefined' && supportTicketsManager.init) {
                supportTicketsManager.init();
            }
            break;
        case 'feedback':
            if (typeof feedbackManager !== 'undefined' && feedbackManager.init) {
                feedbackManager.init();
            }
            break;
        default:
            console.log('No specific loader for section:', sectionId);
    }
}

// Enhanced dashboard functions
function refreshDashboard() {
    const activeTab = document.querySelector('.tab-button.active')?.getAttribute('data-tab') || 'overview';
    loadDashboardTabData(activeTab);
}

function exportDashboard() {
    const activeTab = document.querySelector('.tab-button.active')?.getAttribute('data-tab') || 'overview';
    
    switch(activeTab) {
        case 'overview':
            exportDashboardOverview();
            break;
        case 'analytics':
            if (typeof exportAnalytics === 'function') exportAnalytics();
            break;
        case 'reports':
            if (typeof exportReports === 'function') exportReports();
            break;
    }
}

function exportDashboardOverview() {
    // Export basic dashboard overview data
    console.log('Exporting dashboard overview...');
    // Implementation would depend on your specific export requirements
}

/* ===== UTILITY FUNCTIONS ===== */

function showLoading(elementId) {
    document.getElementById(elementId).innerHTML = `
        <div class="loading">
            <i class="fas fa-spinner"></i>
            <p>Loading...</p>
        </div>
    `;
}

function showErrorById(elementId, message) {
    const element = document.getElementById(elementId);
    if (!element) return;
    
    const isBackendDown = message.includes('server') || message.includes('Backend');
    const helpText = isBackendDown ? 
        '<small style="display: block; margin-top: 1rem; opacity: 0.8;">💡 Make sure the backend server is running on port 5001</small>' : 
        '';
        
    element.innerHTML = `
        <div class="text-center" style="padding: 2rem; color: var(--danger);">
            <i class="fas fa-exclamation-triangle" style="font-size: 2rem; margin-bottom: 1rem;"></i>
            <p>${message}</p>
            ${helpText}
        </div>
    `;
}

function showGlobalLoading(message = 'Loading...') {
    const loadingText = document.getElementById('loadingText');
    const globalLoading = document.getElementById('globalLoading');
    
    if (loadingText) {
        loadingText.textContent = message;
    }
    
    if (globalLoading) {
        globalLoading.style.display = 'flex';
    } else {
        console.warn('Global loading element not found, creating temporary one...');
        // Create a temporary loading element if the main one doesn't exist
        createTemporaryLoading(message);
    }
}

function hideGlobalLoading() {
    const globalLoading = document.getElementById('globalLoading');
    const tempLoading = document.getElementById('tempGlobalLoading');
    
    if (globalLoading) {
        globalLoading.style.display = 'none';
    }
    
    if (tempLoading) {
        tempLoading.remove();
    }
}

function createTemporaryLoading(message) {
    // Remove any existing temporary loading
    const existing = document.getElementById('tempGlobalLoading');
    if (existing) {
        existing.remove();
    }
    
    // Create temporary loading overlay
    const tempLoading = document.createElement('div');
    tempLoading.id = 'tempGlobalLoading';
    tempLoading.className = 'global-loading';
    tempLoading.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.7);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        z-index: 10000;
        color: white;
        font-size: 18px;
    `;
    
    tempLoading.innerHTML = `
        <div class="spinner" style="
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 4px solid #fff;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin-bottom: 20px;
        "></div>
        <div>${message}</div>
    `;
    
    document.body.appendChild(tempLoading);
}

function showToast(message, type = 'success', duration = 3000) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    
    const container = document.getElementById('toastContainer');
    container.appendChild(toast);
    
    setTimeout(() => toast.classList.add('show'), 100);
    
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => container.removeChild(toast), 300);
    }, duration);
}

function initializeCharts() {
    // Charts will be initialized when data is loaded
}

function refreshDashboard() {
    loadDashboardData();
}

/* ===== PERFORMANCE & UTILITIES ===== */

function trackPerformance() {
    if ('performance' in window) {
        window.addEventListener('load', () => {
            setTimeout(() => {
                const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
                if (loadTime > 0) {
                    const logger = window.adminUtils?.logger || console;
                    logger.log(`Page loaded in ${loadTime}ms`);
                    
                    const perfData = JSON.parse(localStorage.getItem('perfData') || '[]');
                    perfData.push({ 
                        timestamp: Date.now(), 
                        loadTime,
                        userAgent: navigator.userAgent.substring(0, 100)
                    });
                    
                    if (perfData.length > 10) perfData.shift();
                    localStorage.setItem('perfData', JSON.stringify(perfData));
                }
            }, 100);
        });
    }
}

function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey || e.metaKey) {
            switch(e.key) {
                case 'd':
                    e.preventDefault();
                    showSection('dashboard');
                    showToast('Switched to Dashboard', 'info', 1500);
                    break;
                case 'p':
                    e.preventDefault();
                    showSection('products');
                    showToast('Switched to Products', 'info', 1500);
                    break;
                case 'o':
                    e.preventDefault();
                    showSection('orders');
                    showToast('Switched to Orders', 'info', 1500);
                    break;
                case 'u':
                    e.preventDefault();
                    showSection('users');
                    showToast('Switched to Users', 'info', 1500);
                    break;
            }
        }
    });
}

function initProductionFeatures() {
    setupKeyboardShortcuts();
}

function sanitizeInput(input) {
    if (typeof input !== 'string') return input;
    return input
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g, '&#x2F;');
}

// Error Boundary
window.addEventListener('error', (e) => {
    const logger = window.adminUtils?.logger || console;
    logger.error('Global error:', e.error);
    showToast('An unexpected error occurred. Please refresh the page.', 'error', 5000);
});

/* ===== ANALYTICS FUNCTIONS ===== */

async function loadAnalytics() {
    try {
        showLoading('analyticsContent');
        
        // Fetch analytics data
        const [dashboardRes, productAnalyticsRes, categoryAnalyticsRes] = await Promise.all([
            authenticatedFetch(`${API_BASE_URL}/api/analytics/admin/dashboard`),
            authenticatedFetch(`${API_BASE_URL}/api/analytics/admin/products`),
            authenticatedFetch(`${API_BASE_URL}/api/analytics/products/popular`)
        ]);
        
        const dashboard = await dashboardRes.json();
        const productAnalytics = await productAnalyticsRes.json();
        const popularProducts = await categoryAnalyticsRes.json();
        
        renderAnalytics(dashboard.data, productAnalytics.data, popularProducts.data);
        
    } catch (error) {
        console.error('Error loading analytics:', error);
        showErrorById('analyticsContent', 'Failed to load analytics data');
    }
}

function renderAnalytics(dashboardData, productData, popularData) {
    const analyticsContainer = document.querySelector('#analyticsContent');
    
    analyticsContainer.innerHTML = `
        <div class="analytics-dashboard">
            <!-- Key Metrics -->
            <div class="analytics-section">
                <h3><i class="fas fa-chart-line"></i> Key Performance Metrics</h3>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon">👥</div>
                        <div class="stat-info">
                            <h3>${dashboardData?.totalUsers || 0}</h3>
                            <p>Total Users</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">📦</div>
                        <div class="stat-info">
                            <h3>${dashboardData?.totalOrders || 0}</h3>
                            <p>Total Orders</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">💰</div>
                        <div class="stat-info">
                            <h3>AED ${(dashboardData?.totalRevenue || 0).toFixed(2)}</h3>
                            <p>Total Revenue</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">☕</div>
                        <div class="stat-info">
                            <h3>${dashboardData?.totalProducts || 0}</h3>
                            <p>Total Products</p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Popular Products -->
            <div class="analytics-section">
                <h3><i class="fas fa-star"></i> Popular Products</h3>
                <div class="popular-products-list">
                    ${renderPopularProductsList(popularData?.products || [])}
                </div>
            </div>
            
            <!-- Category & Banner Performance -->
            <div class="analytics-section">
                <h3><i class="fas fa-tags"></i> Category & Banner Performance</h3>
                <div class="performance-tabs">
                    <button class="tab-btn active" onclick="switchPerformanceTab('categories')">
                        <i class="fas fa-list"></i> Categories
                    </button>
                    <button class="tab-btn" onclick="switchPerformanceTab('banners')">
                        <i class="fas fa-images"></i> Banners
                    </button>
                </div>
                <div id="categories-performance" class="performance-content">
                    ${renderCategoryPerformance(productData?.categoryPerformance || [])}
                </div>
                <div id="banners-performance" class="performance-content" style="display: none;">
                    <div class="loading-placeholder">Loading banner performance...</div>
                </div>
            </div>
            
            <!-- Quick Actions -->
            <div class="analytics-section">
                <h3><i class="fas fa-tools"></i> Quick Actions</h3>
                <div class="quick-actions">
                    <button class="btn btn-primary" onclick="showSection('reports')">
                        <i class="fas fa-file-alt"></i> View Detailed Reports
                    </button>
                    <button class="btn btn-secondary" onclick="refreshAnalytics()">
                        <i class="fas fa-sync"></i> Refresh Data
                    </button>
                    <button class="btn btn-secondary" onclick="exportAnalytics()">
                        <i class="fas fa-download"></i> Export Analytics
                    </button>
                </div>
            </div>
        </div>
    `;
}

function renderPopularProductsList(products) {
    if (!products.length) {
        return '<p class="no-data">No popular products data available</p>';
    }
    
    return products.map((product, index) => `
        <div class="popular-product-item">
            <span class="rank">#${index + 1}</span>
            <div class="product-info">
                <h4>${product.name || 'Unknown Product'}</h4>
                <p>Views: ${product.views || 0} | Revenue: AED ${(product.revenue || 0).toFixed(2)}</p>
            </div>
        </div>
    `).join('');
}

function renderCategoryPerformance(categories) {
    if (!categories.length) {
        return '<p class="no-data">No category performance data available</p>';
    }
    
    return `
        <div class="category-performance-table">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Category</th>
                        <th>Total Views</th>
                        <th>Total Revenue</th>
                        <th>Purchases</th>
                        <th>Conversion Rate</th>
                    </tr>
                </thead>
                <tbody>
                    ${categories.map(cat => `
                        <tr>
                            <td>${cat._id || 'Unknown'}</td>
                            <td>${cat.totalViews || 0}</td>
                            <td>AED ${(cat.totalRevenue || 0).toFixed(2)}</td>
                            <td>${cat.totalPurchases || 0}</td>
                            <td>${cat.totalViews ? ((cat.totalPurchases / cat.totalViews) * 100).toFixed(1) : 0}%</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// Tab switching for performance analytics
async function switchPerformanceTab(tabType) {
    // Update active tab
    document.querySelectorAll('.performance-tabs .tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`.performance-tabs .tab-btn[onclick*="${tabType}"]`).classList.add('active');
    
    // Show/hide content
    document.getElementById('categories-performance').style.display = tabType === 'categories' ? 'block' : 'none';
    document.getElementById('banners-performance').style.display = tabType === 'banners' ? 'block' : 'none';
    
    // Load banner performance data if switching to banners tab
    if (tabType === 'banners') {
        await loadBannerPerformanceData();
    }
}

async function loadBannerPerformanceData() {
    try {
        const bannerContainer = document.getElementById('banners-performance');
        bannerContainer.innerHTML = '<div class="loading-placeholder">Loading banner performance...</div>';
        
        const bannerStats = await loadBannerAnalytics();
        bannerContainer.innerHTML = renderBannerPerformanceTable(bannerStats);
    } catch (error) {
        console.error('Error loading banner performance:', error);
        document.getElementById('banners-performance').innerHTML = 
            '<p class="error-message">Failed to load banner performance data</p>';
    }
}

function renderBannerPerformanceTable(bannerStats) {
    const topPerforming = bannerStats.topPerforming || [];
    const overview = bannerStats.overview || {};
    
    if (topPerforming.length === 0) {
        return `
            <div class="no-data-message">
                <i class="fas fa-images"></i>
                <h4>No Banner Data Available</h4>
                <p>Create and activate banners to see performance analytics</p>
                <button class="btn btn-primary" onclick="showSection('sliders')">
                    <i class="fas fa-plus"></i> Create Banner
                </button>
            </div>
        `;
    }
    
    return `
        <div class="banner-overview-stats">
            <div class="stat-card">
                <h4>Total Banners</h4>
                <span class="stat-value">${overview.activeSliders || 0}</span>
            </div>
            <div class="stat-card">
                <h4>Total Clicks</h4>
                <span class="stat-value">${overview.totalClicks || 0}</span>
            </div>
            <div class="stat-card">
                <h4>Total Views</h4>
                <span class="stat-value">${overview.totalViews || 0}</span>
            </div>
            <div class="stat-card">
                <h4>Avg CTR</h4>
                <span class="stat-value">${overview.totalViews > 0 ? 
                    ((overview.totalClicks / overview.totalViews) * 100).toFixed(1) : '0.0'}%</span>
            </div>
        </div>
        
        <div class="banner-performance-table">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Banner Title</th>
                        <th>Views</th>
                        <th>Clicks</th>
                        <th>CTR</th>
                        <th>Performance</th>
                    </tr>
                </thead>
                <tbody>
                    ${topPerforming.map(banner => {
                        const ctr = banner.viewCount > 0 ? 
                            ((banner.clickCount / banner.viewCount) * 100).toFixed(1) : '0.0';
                        const performance = ctr > 5 ? 'Excellent' : ctr > 2 ? 'Good' : ctr > 1 ? 'Average' : 'Low';
                        const performanceClass = ctr > 5 ? 'excellent' : ctr > 2 ? 'good' : ctr > 1 ? 'average' : 'low';
                        
                        return `
                            <tr>
                                <td>${banner.title}</td>
                                <td>${banner.viewCount}</td>
                                <td>${banner.clickCount}</td>
                                <td>${ctr}%</td>
                                <td><span class="performance-badge ${performanceClass}">${performance}</span></td>
                            </tr>
                        `;
                    }).join('')}
                </tbody>
            </table>
        </div>
    `;
}

async function refreshAnalytics() {
    showToast('Refreshing analytics data...', 'info');
    await loadAnalytics();
    showToast('Analytics data refreshed!', 'success');
}

async function exportAnalytics() {
    try {
        showToast('Preparing analytics export...', 'info');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/reports/analytics`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `analytics-report-${new Date().toISOString().split('T')[0]}.json`;
            a.click();
            URL.revokeObjectURL(url);
            showToast('Analytics exported successfully!', 'success');
        } else {
            throw new Error('Export failed');
        }
    } catch (error) {
        console.error('Export error:', error);
        showToast('Failed to export analytics', 'error');
    }
}

/* ===== REPORTS FUNCTIONS ===== */

async function loadReports() {
    try {
        showLoading('reportsContent');
        
        // Fetch reports data
        const [salesRes, productsRes, usersRes] = await Promise.all([
            authenticatedFetch(`${API_BASE_URL}/api/admin/reports/sales`),
            authenticatedFetch(`${API_BASE_URL}/api/admin/reports/products`),
            authenticatedFetch(`${API_BASE_URL}/api/admin/reports/users`)
        ]);
        
        const salesData = await salesRes.json();
        const productsData = await productsRes.json();
        const usersData = await usersRes.json();
        
        renderReports(salesData.data, productsData.data, usersData.data);
        
    } catch (error) {
        console.error('Error loading reports:', error);
        showErrorById('reportsContent', 'Failed to load reports data');
    }
}

function renderReports(salesData, productsData, usersData) {
    const reportsContainer = document.querySelector('#reportsContent');
    
    reportsContainer.innerHTML = `
        <div class="reports-dashboard">
            <!-- Report Types -->
            <div class="report-types">
                <div class="report-type-buttons">
                    <button class="btn btn-primary active" onclick="showReportType('sales')">
                        <i class="fas fa-chart-line"></i> Sales Reports
                    </button>
                    <button class="btn btn-secondary" onclick="showReportType('products')">
                        <i class="fas fa-box"></i> Product Reports
                    </button>
                    <button class="btn btn-secondary" onclick="showReportType('categories')">
                        <i class="fas fa-tags"></i> Category & Banner Reports
                    </button>
                    <button class="btn btn-secondary" onclick="showReportType('users')">
                        <i class="fas fa-users"></i> User Reports
                    </button>
                </div>
            </div>
            
            <!-- Report Content -->
            <div class="report-content">
                <div id="sales-report" class="report-section active">
                    ${renderSalesReport(salesData)}
                </div>
                <div id="products-report" class="report-section">
                    ${renderProductsReport(productsData)}
                </div>
                <div id="categories-report" class="report-section">
                    ${renderCategoriesReport()}
                </div>
                <div id="users-report" class="report-section">
                    ${renderUsersReport(usersData)}
                </div>
            </div>
        </div>
    `;
}

function showReportType(type) {
    // Update active button
    document.querySelectorAll('.report-type-buttons .btn').forEach(btn => {
        btn.classList.remove('active');
        btn.classList.add('btn-secondary');
        btn.classList.remove('btn-primary');
    });
    
    event.target.classList.add('active');
    event.target.classList.add('btn-primary');
    event.target.classList.remove('btn-secondary');
    
    // Show selected report
    document.querySelectorAll('.report-section').forEach(section => {
        section.classList.remove('active');
    });
    
    document.getElementById(`${type}-report`).classList.add('active');
}

function renderSalesReport(data) {
    return `
        <h3><i class="fas fa-chart-line"></i> Sales Performance</h3>
        <div class="report-metrics">
            <div class="metric-card">
                <h4>Total Revenue</h4>
                <p class="metric-value">AED ${(data?.totalRevenue || 0).toFixed(2)}</p>
            </div>
            <div class="metric-card">
                <h4>Average Order Value</h4>
                <p class="metric-value">AED ${(data?.averageOrderValue || 0).toFixed(2)}</p>
            </div>
            <div class="metric-card">
                <h4>Total Orders</h4>
                <p class="metric-value">${data?.totalOrders || 0}</p>
            </div>
        </div>
        <div class="report-actions">
            <button class="btn btn-primary" onclick="generateSalesReport()">
                <i class="fas fa-file-download"></i> Generate Detailed Report
            </button>
        </div>
    `;
}

function renderProductsReport(data) {
    return `
        <h3><i class="fas fa-box"></i> Product Performance</h3>
        <div class="report-metrics">
            <div class="metric-card">
                <h4>Best Selling Product</h4>
                <p class="metric-value">${data?.bestSeller?.name || 'N/A'}</p>
            </div>
            <div class="metric-card">
                <h4>Total Products</h4>
                <p class="metric-value">${data?.totalProducts || 0}</p>
            </div>
            <div class="metric-card">
                <h4>Low Stock Items</h4>
                <p class="metric-value">${data?.lowStockCount || 0}</p>
            </div>
        </div>
        <div class="report-actions">
            <button class="btn btn-primary" onclick="generateProductReport()">
                <i class="fas fa-file-download"></i> Generate Product Report
            </button>
        </div>
    `;
}

async function renderCategoriesReport() {
    try {
        // Load actual banner analytics data
        const bannerStats = await loadBannerAnalytics();
        return renderBannerAnalyticsHTML(bannerStats);
    } catch (error) {
        console.error('Error loading banner analytics:', error);
        return renderBannerAnalyticsPlaceholder();
    }
}

async function loadBannerAnalytics() {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/sliders/stats`);
        const data = await handleApiResponse(response);
        
        if (data.success) {
            return data.data;
        } else {
            throw new Error('Failed to load banner stats');
        }
    } catch (error) {
        console.error('Error fetching banner analytics:', error);
        throw error;
    }
}

function renderBannerAnalyticsHTML(bannerStats) {
    const overview = bannerStats.overview || {};
    const topPerforming = bannerStats.topPerforming || [];
    
    const clickRate = overview.totalViews > 0 ? 
        ((overview.totalClicks / overview.totalViews) * 100).toFixed(2) : '0.00';
    
    return `
        <h3><i class="fas fa-tags"></i> Category & Banner Analytics</h3>
        <div class="banner-analytics-section">
            <h4>Banner Performance Metrics</h4>
            <div class="report-metrics">
                <div class="metric-card">
                    <h4>Banner Click Rate</h4>
                    <p class="metric-value">${clickRate}%</p>
                    <small>${overview.totalClicks} clicks / ${overview.totalViews} views</small>
                </div>
                <div class="metric-card">
                    <h4>Total Impressions</h4>
                    <p class="metric-value">${overview.totalViews || 0}</p>
                    <small>Total banner views</small>
                </div>
                <div class="metric-card">
                    <h4>Active Banners</h4>
                    <p class="metric-value">${overview.activeSliders || 0}</p>
                    <small>Currently active banners</small>
                </div>
            </div>
            
            ${topPerforming.length > 0 ? `
            <div class="top-performing-banners">
                <h4>Top Performing Banners</h4>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Banner Title</th>
                            <th>Clicks</th>
                            <th>Views</th>
                            <th>CTR</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${topPerforming.map(banner => {
                            const ctr = banner.viewCount > 0 ? 
                                ((banner.clickCount / banner.viewCount) * 100).toFixed(2) : '0.00';
                            return `
                                <tr>
                                    <td>${banner.title}</td>
                                    <td>${banner.clickCount}</td>
                                    <td>${banner.viewCount}</td>
                                    <td>${ctr}%</td>
                                </tr>
                            `;
                        }).join('')}
                    </tbody>
                </table>
            </div>
            ` : ''}
            
            <div class="banner-actions">
                <button class="btn btn-primary" onclick="refreshBannerAnalytics()">
                    <i class="fas fa-sync-alt"></i> Refresh Analytics
                </button>
                <button class="btn btn-secondary" onclick="showSection('sliders')">
                    <i class="fas fa-images"></i> Manage Banners
                </button>
                <button class="btn btn-success" onclick="exportBannerReport()">
                    <i class="fas fa-file-download"></i> Export Report
                </button>
            </div>
            
            <div class="analytics-info">
                <p><i class="fas fa-info-circle"></i> Banner analytics tracking includes:</p>
                <ul>
                    <li><strong>Impressions:</strong> How many times banners were viewed</li>
                    <li><strong>Clicks:</strong> How many times banners were clicked</li>
                    <li><strong>Click-through Rate (CTR):</strong> Percentage of views that resulted in clicks</li>
                    <li><strong>Performance Rankings:</strong> Top performing banners by engagement</li>
                </ul>
            </div>
        </div>
    `;
}

function renderBannerAnalyticsPlaceholder() {
    return `
        <h3><i class="fas fa-tags"></i> Category & Banner Analytics</h3>
        <div class="banner-analytics-section">
            <h4>Banner Performance Metrics</h4>
            <div class="report-metrics">
                <div class="metric-card">
                    <h4>Banner Click Rate</h4>
                    <p class="metric-value">Loading...</p>
                    <small>Track banner clicks vs impressions</small>
                </div>
                <div class="metric-card">
                    <h4>Category Engagement</h4>
                    <p class="metric-value">Loading...</p>
                    <small>Category-wise user interaction</small>
                </div>
                <div class="metric-card">
                    <h4>Banner Conversion</h4>
                    <p class="metric-value">Loading...</p>
                    <small>Banner clicks to purchases</small>
                </div>
            </div>
            <div class="report-note">
                <p><i class="fas fa-info-circle"></i> Banner analytics tracking will be implemented to measure:</p>
                <ul>
                    <li>Banner impression counts</li>
                    <li>Click-through rates by category</li>
                    <li>Conversion from banner clicks to purchases</li>
                    <li>Most effective banner placements</li>
                    <li>Category performance metrics</li>
                </ul>
            </div>
            <div class="report-actions">
                <button class="btn btn-primary" onclick="implementBannerTracking()">
                    <i class="fas fa-cog"></i> Setup Banner Tracking
                </button>
                <button class="btn btn-secondary" onclick="generateCategoryReport()">
                    <i class="fas fa-file-download"></i> Generate Category Report
                </button>
            </div>
        </div>
    `;
}

function renderUsersReport(data) {
    return `
        <h3><i class="fas fa-users"></i> User Analytics</h3>
        <div class="report-metrics">
            <div class="metric-card">
                <h4>Total Users</h4>
                <p class="metric-value">${data?.totalUsers || 0}</p>
            </div>
            <div class="metric-card">
                <h4>Active Users</h4>
                <p class="metric-value">${data?.activeUsers || 0}</p>
            </div>
            <div class="metric-card">
                <h4>New Signups</h4>
                <p class="metric-value">${data?.newSignups || 0}</p>
            </div>
        </div>
        <div class="report-actions">
            <button class="btn btn-primary" onclick="generateUserReport()">
                <i class="fas fa-file-download"></i> Generate User Report
            </button>
        </div>
    `;
}

/* ===== REPORT GENERATION FUNCTIONS ===== */

async function generateSalesReport() {
    try {
        showToast('Generating sales report...', 'info');
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/reports/sales?format=csv`);
        const blob = await response.blob();
        downloadBlob(blob, `sales-report-${new Date().toISOString().split('T')[0]}.csv`);
        showToast('Sales report generated!', 'success');
    } catch (error) {
        console.error('Error generating sales report:', error);
        showToast('Failed to generate sales report', 'error');
    }
}

async function generateProductReport() {
    try {
        showToast('Generating product report...', 'info');
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/reports/products?format=csv`);
        const blob = await response.blob();
        downloadBlob(blob, `product-report-${new Date().toISOString().split('T')[0]}.csv`);
        showToast('Product report generated!', 'success');
    } catch (error) {
        console.error('Error generating product report:', error);
        showToast('Failed to generate product report', 'error');
    }
}

async function generateCategoryReport() {
    showToast('Category banner analytics coming soon!', 'info');
}

async function generateUserReport() {
    try {
        showToast('Generating user report...', 'info');
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/reports/users?format=csv`);
        const blob = await response.blob();
        downloadBlob(blob, `user-report-${new Date().toISOString().split('T')[0]}.csv`);
        showToast('User report generated!', 'success');
    } catch (error) {
        console.error('Error generating user report:', error);
        showToast('Failed to generate user report', 'error');
    }
}

function downloadBlob(blob, filename) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
}

function implementBannerTracking() {
    refreshBannerAnalytics();
    showToast('Banner tracking is now active! Analytics data is being collected.', 'success', 3000);
}

// Banner Analytics Functions
async function refreshBannerAnalytics() {
    try {
        showToast('Refreshing banner analytics...', 'info');
        
        // Reload the reports section to show updated data
        await loadReports();
        
        showToast('Banner analytics refreshed successfully!', 'success');
    } catch (error) {
        console.error('Error refreshing banner analytics:', error);
        showToast('Failed to refresh banner analytics', 'error');
    }
}

async function exportBannerReport() {
    try {
        showGlobalLoading('Generating banner analytics report...');
        
        const bannerStats = await loadBannerAnalytics();
        const reportData = generateBannerReportCSV(bannerStats);
        
        const blob = new Blob([reportData], { type: 'text/csv' });
        const filename = `banner-analytics-report-${new Date().toISOString().split('T')[0]}.csv`;
        
        downloadBlob(blob, filename);
        hideGlobalLoading();
        
        showToast('Banner analytics report exported successfully!', 'success');
    } catch (error) {
        console.error('Error exporting banner report:', error);
        hideGlobalLoading();
        showToast('Failed to export banner report', 'error');
    }
}

function generateBannerReportCSV(bannerStats) {
    const overview = bannerStats.overview || {};
    const topPerforming = bannerStats.topPerforming || [];
    
    let csv = 'Banner Analytics Report\n\n';
    csv += 'Overview\n';
    csv += 'Metric,Value\n';
    csv += `Total Banners,${overview.totalSliders || 0}\n`;
    csv += `Active Banners,${overview.activeSliders || 0}\n`;
    csv += `Total Clicks,${overview.totalClicks || 0}\n`;
    csv += `Total Views,${overview.totalViews || 0}\n`;
    csv += `Average Clicks per Banner,${(overview.averageClicks || 0).toFixed(2)}\n`;
    csv += `Average Views per Banner,${(overview.averageViews || 0).toFixed(2)}\n`;
    
    const clickRate = overview.totalViews > 0 ? 
        ((overview.totalClicks / overview.totalViews) * 100).toFixed(2) : '0.00';
    csv += `Overall Click-through Rate,${clickRate}%\n\n`;
    
    if (topPerforming.length > 0) {
        csv += 'Top Performing Banners\n';
        csv += 'Banner Title,Clicks,Views,Click-through Rate\n';
        
        topPerforming.forEach(banner => {
            const ctr = banner.viewCount > 0 ? 
                ((banner.clickCount / banner.viewCount) * 100).toFixed(2) : '0.00';
            csv += `"${banner.title}",${banner.clickCount},${banner.viewCount},${ctr}%\n`;
        });
    }
    
    csv += `\nReport generated on: ${new Date().toLocaleString()}\n`;
    
    return csv;
}

// Client-side Banner Tracking Functions
function trackBannerView(bannerId) {
    if (!bannerId) return;
    
    // Send view tracking to backend
    fetch(`${API_BASE_URL}/api/sliders/${bannerId}/view`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    }).catch(error => {
        console.warn('Failed to track banner view:', error);
    });
}

function trackBannerClick(bannerId) {
    if (!bannerId) return;
    
    // Send click tracking to backend
    fetch(`${API_BASE_URL}/api/sliders/${bannerId}/click`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    }).catch(error => {
        console.warn('Failed to track banner click:', error);
    });
}

// Initialize banner tracking on page load
document.addEventListener('DOMContentLoaded', function() {
    // Set up Intersection Observer for view tracking
    if (typeof IntersectionObserver !== 'undefined') {
        const bannerObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const bannerId = entry.target.dataset.bannerId;
                    if (bannerId && !entry.target.dataset.viewed) {
                        trackBannerView(bannerId);
                        entry.target.dataset.viewed = 'true';
                    }
                }
            });
        }, {
            threshold: 0.5 // Trigger when 50% of banner is visible
        });
        
        // Observe all banner elements
        document.querySelectorAll('[data-banner-id]').forEach(banner => {
            bannerObserver.observe(banner);
        });
        
        // Set up click tracking for banner links
        document.addEventListener('click', function(event) {
            const bannerElement = event.target.closest('[data-banner-id]');
            if (bannerElement) {
                const bannerId = bannerElement.dataset.bannerId;
                trackBannerClick(bannerId);
            }
        });
    }
});

/* ===== UTILITY FUNCTIONS FOR NEW MODULES ===== */

/**
 * Show loading spinner for a specific element
 */
function showLoader(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = `
            <div class="loading-container" style="text-align: center; padding: 40px;">
                <div class="spinner" style="
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid #8B4513;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 0 auto;
                "></div>
                <p style="margin-top: 15px; color: #666;">Loading...</p>
            </div>
            <style>
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
            </style>
        `;
    }
}

/**
 * Show error message
 */
function showErrorMessage(message) {
    // Create error notification
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-notification';
    errorDiv.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background-color: #dc3545;
        color: white;
        padding: 15px 20px;
        border-radius: 5px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        z-index: 10000;
        max-width: 300px;
        word-wrap: break-word;
    `;
    errorDiv.innerHTML = `
        <strong>Error:</strong> ${message}
        <button onclick="this.parentElement.remove()" style="
            background: none;
            border: none;
            color: white;
            float: right;
            cursor: pointer;
            font-size: 18px;
            margin-left: 10px;
        ">&times;</button>
    `;
    
    document.body.appendChild(errorDiv);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (errorDiv.parentElement) {
            errorDiv.remove();
        }
    }, 5000);
    
    console.error('Error:', message);
}

/**
 * Show success message
 */
function showSuccessMessage(message) {
    // Create success notification
    const successDiv = document.createElement('div');
    successDiv.className = 'success-notification';
    successDiv.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background-color: #28a745;
        color: white;
        padding: 15px 20px;
        border-radius: 5px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        z-index: 10000;
        max-width: 300px;
        word-wrap: break-word;
    `;
    successDiv.innerHTML = `
        <strong>Success:</strong> ${message}
        <button onclick="this.parentElement.remove()" style="
            background: none;
            border: none;
            color: white;
            float: right;
            cursor: pointer;
            font-size: 18px;
            margin-left: 10px;
        ">&times;</button>
    `;
    
    document.body.appendChild(successDiv);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        if (successDiv.parentElement) {
            successDiv.remove();
        }
    }, 3000);
}

/**
 * Hide loader for a specific element
 */
function hideLoader(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        const loader = element.querySelector('.loading-container');
        if (loader) {
            loader.remove();
        }
    }
}

/**
 * Close modal function
 */
function closeModal() {
    const modal = document.querySelector('.modal-overlay');
    if (modal) {
        modal.remove();
    }
}
