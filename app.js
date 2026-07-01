// Automatically route to local backend if running locally, otherwise use the live Render backend
const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const API_URL = isLocalhost 
    ? '/api' 
    : 'https://hospital-appointment-and-resource.onrender.com/api';
let DB_CACHE = { hms_users: [], hms_appointments: [], hms_resources: {} };

const TIME_SLOTS = ['10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM', '04:00 PM'];
const MAX_PATIENTS_PER_SLOT = 3;

// Utility: LocalStorage ONLY for Auth Session, DB for everything else
const db = {
    get: (key) => DB_CACHE[key] || (key === 'hms_resources' ? {} : []),
    set: (key, value) => { DB_CACHE[key] = value; },
    getCurrentUser: () => JSON.parse(localStorage.getItem('hms_currentUser')),
    setCurrentUser: (user) => localStorage.setItem('hms_currentUser', JSON.stringify(user)),
    logout: () => localStorage.removeItem('hms_currentUser')
};

let currentUser = db.getCurrentUser();

// Fetch Latest Database State from Node Server
async function fetchDatabase() {
    try {
        const res = await fetch(`${API_URL}/data`);
        if(res.ok) {
            const json = await res.json();
            const data = json.d ? json.d.results : json;
            DB_CACHE['hms_users'] = data.hms_users || [];
            DB_CACHE['hms_appointments'] = data.hms_appointments || [];
            DB_CACHE['hms_resources'] = data.hms_resources || {};
            DB_CACHE['hms_allocations'] = data.hms_allocations || [];
            DB_CACHE['hms_financials'] = data.hms_financials || [];
            DB_CACHE['hms_purchasing'] = data.hms_purchasing || [];
            return true;
        }
    } catch(err) {
        console.error("No Backend:", err);
        showToast("Backend Error. Run 'node server.js'", "error");
        return false;
    }
}

// Boot up
document.addEventListener('DOMContentLoaded', async () => {
    // Before anything, fetch DB from local server
    const ok = await fetchDatabase();
    if(ok) {
        setupEventListeners();
        route();
    }
});

// --- APP STATE & ROUTING ---
async function navigateTo(viewId) {
    document.querySelectorAll('.page-view').forEach(el => el.classList.remove('active'));
    document.getElementById(`view-${viewId}`).classList.add('active');
    updateNav();
    await fetchDatabase(); // Refresh data any time view changes
    loadDashboardData(viewId);
}

function route() {
    if (!currentUser) {
        navigateTo('landing');
    } else {
        navigateTo(`${currentUser.role}-dashboard`);
    }
}

function updateNav() {
    const authSection = document.getElementById('nav-auth');
    const unauthSection = document.getElementById('nav-unauth');
    if (currentUser) {
        authSection.classList.remove('hidden');
        authSection.classList.add('flex');
        unauthSection.classList.add('hidden');
        unauthSection.classList.remove('flex');
        document.getElementById('nav-user-name').innerText = `Welcome, ${currentUser.name}`;
    } else {
        authSection.classList.add('hidden');
        authSection.classList.remove('flex');
        unauthSection.classList.remove('hidden');
        unauthSection.classList.add('flex');
    }
}

// --- TOAST NOTIFICATIONS ---
function showToast(message, type = 'success') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    const color = type === 'success' ? 'bg-teal-500' : 'bg-red-500';
    
    toast.className = `toast-enter ${color} text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3`;
    toast.innerHTML = `<i class="fa-solid fa-${type === 'success' ? 'check-circle' : 'circle-exclamation'}"></i><span>${message}</span>`;
    
    container.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.replace('toast-enter', 'toast-exit');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// --- EVENT LISTENERS SETUP ---
function setupEventListeners() {
    document.getElementById('form-login').addEventListener('submit', handleLogin);
    document.getElementById('form-register').addEventListener('submit', handleRegister);
    document.getElementById('book-dept').addEventListener('change', populateDoctorsByDept);
    document.getElementById('book-doctor').addEventListener('change', checkAvailableSlots);
    document.getElementById('book-date').addEventListener('change', checkAvailableSlots);
    
    // Poll the server every 10 seconds silently to auto-update dashboards
    setInterval(async () => {
        if(currentUser) {
            await fetchDatabase();
            loadDashboardData(`${currentUser.role}-dashboard`);
        }
    }, 10000);
}

// --- AUTHENTICATION ---
function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('login-email').value;
    const pass = document.getElementById('login-pass').value;
    
    const users = db.get('hms_users');
    const user = users.find(u => u.email === email && u.password === pass);
    
    if (user) {
        currentUser = user;
        db.setCurrentUser(user);
        showToast('Login successful!');
        route();
    } else {
        showToast('Invalid credentials!', 'error');
    }
}

async function loginAsGuest(role) {
    showToast(`Initializing Guest ${role} Environment...`, 'success');
    try {
        const res = await fetch(`${API_URL}/guest-login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ role })
        });
        
        const data = await res.json();
        
        if(data.success) {
            currentUser = data.user;
            db.setCurrentUser(data.user);
            await fetchDatabase(); // Force a sync
            showToast(`Logged in as Guest ${role.charAt(0).toUpperCase() + role.slice(1)}!`);
            route();
        } else {
            showToast('Guest login failed: ' + data.error, 'error');
        }
    } catch(err) {
        showToast('Connection error', 'error');
        console.error(err);
    }
}

async function handleRegister(e) {
    e.preventDefault();
    const name = document.getElementById('reg-name').value;
    const email = document.getElementById('reg-email').value;
    const pass = document.getElementById('reg-pass').value;
    
    const users = db.get('hms_users');
    if (users.find(u => u.email === email)) {
        showToast('Email already exists!', 'error');
        return;
    }
    
    const newUser = { id: 'p' + Date.now(), name, email, password: pass, role: 'patient' };
    
    try {
        await fetch(`${API_URL}/users`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(newUser)
        });
        await fetchDatabase();
        
        currentUser = newUser;
        db.setCurrentUser(newUser);
        showToast('Registration successful!');
        route();
    } catch(err) {
        showToast('Backend Error. Form not saved.', 'error');
    }
}

function logout() {
    db.logout();
    currentUser = null;
    route();
    showToast('Logged out successfully');
}

// --- DASHBOARD ROUTERS ---
function loadDashboardData(viewId) {
    if (viewId === 'patient-dashboard' && currentUser?.role === 'patient') {
        initPatientDashboard();
    } else if (viewId === 'doctor-dashboard' && currentUser?.role === 'doctor') {
        initDoctorDashboard();
    } else if (viewId === 'admin-dashboard' && currentUser?.role === 'admin') {
        initAdminDashboard();
    }
}

// --- PATIENT LOGIC ---
let selectedSlot = null;

function initPatientDashboard() {
    const users = db.get('hms_users');
    const doctors = users.filter(u => u.role === 'doctor');
    
    const departments = [...new Set(doctors.map(d => d.specialty))];
    const deptSelect = document.getElementById('book-dept');
    deptSelect.innerHTML = '<option value="">Select Department...</option>' + 
        departments.map(dep => `<option value="${dep}">${dep}</option>`).join('');
    
    const dateInput = document.getElementById('book-date');
    const today = new Date().toISOString().split('T')[0];
    dateInput.min = today;
    if(!dateInput.value) dateInput.value = today;
    
    loadMyPatientAppointments();
}

function populateDoctorsByDept() {
    const dept = document.getElementById('book-dept').value;
    const doctors = db.get('hms_users').filter(u => u.role === 'doctor' && u.specialty === dept);
    
    const docSelect = document.getElementById('book-doctor');
    docSelect.innerHTML = '<option value="">Select Doctor...</option>' + 
        doctors.map(d => `<option value="${d.id}">${d.name}</option>`).join('');
    
    docSelect.disabled = doctors.length === 0;
    
    document.getElementById('slot-container').innerHTML = ''; // reset slots
    selectedSlot = null;
    document.getElementById('btn-confirm-booking').disabled = true;
}

function checkAvailableSlots() {
    const docId = document.getElementById('book-doctor').value;
    const date = document.getElementById('book-date').value;
    const container = document.getElementById('slot-container');
    
    if (!docId || !date) {
        container.innerHTML = '<p class="text-gray-500 text-sm">Select doctor and date to view slots.</p>';
        return;
    }
    
    const appointments = db.get('hms_appointments');
    const docAppointments = appointments.filter(a => a.doctorId === docId && a.date === date);
    
    let html = '';
    
    const now = new Date();
    const todayDateLocal = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
    const isToday = (date === todayDateLocal);

    TIME_SLOTS.forEach(slot => {
        let isPassed = false;
        if (isToday) {
            const [time, period] = slot.split(' ');
            let hour = parseInt(time.split(':')[0], 10);
            if (period === 'PM' && hour !== 12) hour += 12;
            if (period === 'AM' && hour === 12) hour = 0;
            if (now.getHours() >= hour) isPassed = true;
        }
        
        const bookedCount = docAppointments.filter(a => a.slot === slot).length;
        const isFull = bookedCount >= MAX_PATIENTS_PER_SLOT;
        const isDisabled = isFull || isPassed;
        let statusText = isPassed ? 'Time Passed' : (isFull ? 'Fully Booked' : `${bookedCount}/${MAX_PATIENTS_PER_SLOT} Booked`);
        
        html += `
            <button class="slot-btn p-3 rounded-lg border text-center ${isDisabled ? 'bg-gray-100 border-gray-300 text-gray-400' : 'bg-white border-teal-200 hover:border-teal-500 text-gray-700'}"
                    ${isDisabled ? 'disabled' : ''}
                    onclick="selectTimeSlot(this, '${slot}')">
                <div class="font-bold">${slot}</div>
                <div class="text-xs mt-1">${statusText}</div>
            </button>
        `;
    });
    
    container.innerHTML = html || '<p class="text-gray-500 text-sm">No slots available for this date.</p>';
    selectedSlot = null;
    document.getElementById('btn-confirm-booking').disabled = true;
}

function selectTimeSlot(btnElement, slotStr) {
    document.querySelectorAll('.slot-btn').forEach(btn => btn.classList.remove('selected'));
    btnElement.classList.add('selected');
    selectedSlot = slotStr;
    document.getElementById('btn-confirm-booking').disabled = false;
}

async function confirmBooking() {
    const docId = document.getElementById('book-doctor').value;
    const date = document.getElementById('book-date').value;
    
    if (!docId || !date || !selectedSlot) {
        showToast('Please complete all selection steps', 'error');
        return;
    }
    
    await fetchDatabase(); // Refresh fresh capacities
    const appointments = db.get('hms_appointments');
    
    const bookedCount = appointments.filter(a => a.doctorId === docId && a.date === date && a.slot === selectedSlot).length;
    if (bookedCount >= MAX_PATIENTS_PER_SLOT) {
        showToast('Slot just got fully booked by someone else!', 'error');
        checkAvailableSlots();
        return;
    }
    
    const existing = appointments.find(a => a.patientId === currentUser.id && a.date === date && a.slot === selectedSlot);
    if(existing) {
        showToast('You already have an appointment at this time.', 'error');
        return;
    }

    const newAppointment = {
        id: 'apt' + Date.now(),
        patientId: currentUser.id,
        doctorId: docId,
        date: date,
        slot: selectedSlot,
        status: 'Pending'
    };
    
    try {
        await fetch(`${API_URL}/appointments`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(newAppointment)
        });
        await fetchDatabase();
        showToast('Appointment Request Submitted!');
        
        document.getElementById('book-dept').value = '';
        document.getElementById('book-doctor').innerHTML = '<option value="">Select Doctor...</option>';
        document.getElementById('book-doctor').disabled = true;
        document.getElementById('slot-container').innerHTML = '';
        selectedSlot = null;
        document.getElementById('btn-confirm-booking').disabled = true;
        
        loadMyPatientAppointments();
    } catch(err) {
        showToast('Server Failure. Could not book.', 'error');
    }
}

function loadMyPatientAppointments() {
    const appointments = db.get('hms_appointments').filter(a => a.patientId === currentUser.id);
    const seenUpdates = JSON.parse(localStorage.getItem('hms_seen_updates') || '[]');
    const users = db.get('hms_users');
    
    const list = document.getElementById('patient-appointments-list');
    
    if (appointments.length === 0) {
        list.innerHTML = `<tr><td colspan="4" class="px-6 py-4 text-center text-sm text-gray-500">No appointments found.</td></tr>`;
        return;
    }
    
    appointments.sort((a,b) => new Date(b.date) - new Date(a.date));
    
    list.innerHTML = appointments.map(apt => {
        const doctor = users.find(u => u.id === apt.doctorId);
        
        let statusBadge = '';
        if(apt.status === 'Pending') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">Pending</span>';
        else if(apt.status === 'Approved') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Approved</span>';
        else if(apt.status === 'Completed') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">Completed</span>';
        else statusBadge = `<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">${apt.status}</span>`;
        
        let actionBtns = '';
        if(apt.status === 'Pending' || apt.status === 'Approved') {
            const now = new Date();
            const todayLocal = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
            let canWithdraw = false;
            
            if (apt.date > todayLocal) {
                canWithdraw = true;
            } else if (apt.date === todayLocal) {
                const [time, period] = apt.slot.split(' ');
                let hour = parseInt(time.split(':')[0], 10);
                if (period === 'PM' && hour !== 12) hour += 12;
                if (period === 'AM' && hour === 12) hour = 0;
                if (now.getHours() < hour) canWithdraw = true;
            }
            
            if(canWithdraw) {
                actionBtns = `<button onclick="updateAppointmentStatus('${apt.id}', 'Patient Withdrawn')" class="text-red-500 hover:text-red-700 text-xs font-medium bg-red-50 px-2 py-1 rounded border border-red-100">Withdraw</button>`;
            }
        } else if(apt.status === 'Completed') {
            const hasUnseenUpdate = apt.isUpdated && !seenUpdates.includes(apt.id + apt.updatedAt);
            const redDot = hasUnseenUpdate ? '<span class="absolute -top-1 -right-1 flex h-3 w-3"><span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span><span class="relative inline-flex rounded-full h-3 w-3 bg-red-500 border border-white"></span></span>' : '';
            actionBtns = `<button onclick="openPrescriptionModal('${apt.id}')" class="text-teal-600 hover:text-teal-900 text-xs font-bold bg-teal-50 px-3 py-1.5 rounded-full border border-teal-100 shadow-sm transition-transform hover:scale-105 relative"><i class="fa-solid fa-file-medical mr-1"></i> View Prescription${redDot}</button>`;
        }
        
        return `
        <tr class="hover:bg-gray-50 transition-colors">
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${doctor?.name || 'Unknown'} (${doctor?.specialty || ''})</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${new Date(apt.date).toLocaleDateString()}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">${apt.slot}</td>
            <td class="px-6 py-4 whitespace-nowrap">${statusBadge}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-right">${actionBtns}</td>
        </tr>
        `;
    }).join('');
}

// --- DOCTOR LOGIC ---
function initDoctorDashboard() {
    const dateInput = document.getElementById('doctor-filter-date');
    const today = new Date().toISOString().split('T')[0];
    if(!dateInput.value) dateInput.value = today;
    
    loadDoctorSchedule();
}

function loadDoctorSchedule() {
    const filterDate = document.getElementById('doctor-filter-date').value;
    const filterStatus = document.getElementById('doctor-filter-status').value;
    
    let appointments = db.get('hms_appointments').filter(a => a.doctorId === currentUser.id);
    const users = db.get('hms_users');
    
    if(filterDate) appointments = appointments.filter(a => a.date === filterDate);
    if(filterStatus) appointments = appointments.filter(a => a.status === filterStatus);
    
    appointments.sort((a,b) => TIME_SLOTS.indexOf(a.slot) - TIME_SLOTS.indexOf(b.slot));
    
    const list = document.getElementById('doctor-appointments-list');
    
    if (appointments.length === 0) {
        list.innerHTML = `<tr><td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">No appointments match your filters.</td></tr>`;
        return;
    }
    
    list.innerHTML = appointments.map(apt => {
        const patient = users.find(u => u.id === apt.patientId);
        
        let statusBadge = '';
        if(apt.status === 'Pending') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">Pending</span>';
        else if(apt.status === 'Approved') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Approved</span>';
        else if(apt.status === 'Completed') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">Completed</span>';
        else statusBadge = `<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">${apt.status}</span>`;
        
        const isEnded = apt.status.includes('Cancelled') || apt.status.includes('Withdrawn') || apt.status.includes('Declined');
        
        let actionBtns = '';
        if(!isEnded) {
            if(apt.status === 'Pending') {
                actionBtns = `
                    <button onclick="updateAppointmentStatus('${apt.id}', 'Approved')" class="text-green-600 hover:text-green-900 mr-3" title="Approve"><i class="fa-solid fa-check"></i></button>
                    <button onclick="updateAppointmentStatus('${apt.id}', 'Doctor Declined')" class="text-red-600 hover:text-red-900" title="Decline"><i class="fa-solid fa-xmark"></i></button>
                `;
            } else if(apt.status === 'Approved') {
                 actionBtns = `
                    <button onclick="openConsultModal('${apt.id}', '${patient?.name.replace(/'/g, "\\'")}')" class="text-white bg-teal-500 hover:bg-teal-600 px-3 py-1 rounded shadow text-xs font-bold mr-2"><i class="fa-solid fa-user-doctor mr-1"></i> Consult</button>
                    <button onclick="updateAppointmentStatus('${apt.id}', 'Doctor Cancelled')" class="text-red-400 hover:text-red-700 mt-2 block text-[10px]" title="Cancel Appointment">Cancel</button>
                `;
            } else if(apt.status === 'Completed') {
                 actionBtns = `<button onclick="openConsultModal('${apt.id}', '${patient?.name.replace(/'/g, "\\'")}')" class="text-indigo-600 hover:text-indigo-900 bg-indigo-50 px-3 py-1.5 rounded-lg border border-indigo-100 font-bold shadow-sm transition-all hover:shadow"><i class="fa-solid fa-pen-to-square mr-1"></i> Edit Rx</button>`;
            }
        }
        
        return `
        <tr class="hover:bg-gray-50 transition-colors">
            <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">${patient?.name || 'Unknown'}</div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${new Date(apt.date).toLocaleDateString()}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-teal-700">${apt.slot}</td>
            <td class="px-6 py-4 whitespace-nowrap">${statusBadge}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-right">${actionBtns}</td>
        </tr>
        `;
    }).join('');
}

// --- MODAL & ACTION LOGIC ---
let currentConsultAptId = null;

function openConsultModal(aptId, patientName) {
    currentConsultAptId = aptId;
    const apt = db.get('hms_appointments').find(a => a.id === aptId);
    if(!apt) return;
    
    document.getElementById('consult-patient-name').innerText = `Patient: ${patientName}`;
    document.getElementById('consult-problem').value = apt.problem || '';
    document.getElementById('consult-prescription').value = apt.prescription || '';
    
    // Manage resources section lock
    const isCompleted = apt.status === 'Completed';
    const resSection = document.getElementById('consult-resources-section');
    if(resSection) {
        if(isCompleted) {
            resSection.style.opacity = '0.4';
            resSection.style.pointerEvents = 'none';
        } else {
            resSection.style.opacity = '1';
            resSection.style.pointerEvents = 'auto';
            if(document.getElementById('consult-bed')) {
                document.getElementById('consult-bed').checked = false;
                document.getElementById('consult-blood-type').value = '';
                document.getElementById('consult-blood-units').value = '1';
                document.getElementById('consult-equipment').value = '';
            }
        }
    }
    
    const submitBtn = document.getElementById('btn-consult-submit');
    if(submitBtn) submitBtn.innerHTML = isCompleted ? `<i class="fa-solid fa-floppy-disk mr-2"></i>Update Prescription` : `<i class="fa-solid fa-check mr-2"></i>Complete Consultation`;
    
    const modal = document.getElementById('modal-consult');
    modal.classList.remove('hidden');
    setTimeout(() => modal.classList.remove('opacity-0'), 10);
}

function closeConsultModal() {
    currentConsultAptId = null;
    const modal = document.getElementById('modal-consult');
    modal.classList.add('opacity-0');
    setTimeout(() => modal.classList.add('hidden'), 300);
}

async function submitConsultation() {
    if(!currentConsultAptId) return;
    
    const problem = document.getElementById('consult-problem').value.trim();
    const prescription = document.getElementById('consult-prescription').value.trim();
    
    if(!problem || !prescription) {
        showToast('Please fill out both diagnosis and medicines.', 'error');
        return;
    }
    
    const resources = {};
    if(document.getElementById('consult-bed') && document.getElementById('consult-bed').checked) resources.bed = true;
    
    if(document.getElementById('consult-blood-type')) {
        const bType = document.getElementById('consult-blood-type').value;
        if(bType) resources.blood = { type: bType, units: parseInt(document.getElementById('consult-blood-units').value, 10) || 1 };
    }
    
    if(document.getElementById('consult-equipment')) {
        const eq = document.getElementById('consult-equipment').value;
        if(eq) resources.equipment = eq;
    }
    
    const apt = db.get('hms_appointments').find(a => a.id === currentConsultAptId);
    const isEditing = apt && apt.status === 'Completed';
    const reqBody = { status: 'Completed', problem, prescription };
    
    if(isEditing) {
        reqBody.isUpdated = true;
        reqBody.updatedAt = new Date().toLocaleString();
    } else {
        reqBody.resources = Object.keys(resources).length > 0 ? resources : null;
    }
    
    try {
        await fetch(`${API_URL}/appointments/${currentConsultAptId}`, {
            method: 'PUT',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(reqBody)
        });
        await fetchDatabase();
        showToast(isEditing ? `Prescription updated successfully!` : `Consultation successfully completed!`);
        closeConsultModal();
        loadDoctorSchedule();
    } catch(err) {
        showToast('Server update failed!', 'error');
    }
}

function openPrescriptionModal(aptId) {
    const apt = db.get('hms_appointments').find(a => a.id === aptId);
    if(!apt) return;
    
    if (apt.isUpdated) {
        const seen = JSON.parse(localStorage.getItem('hms_seen_updates') || '[]');
        const key = apt.id + apt.updatedAt;
        if (!seen.includes(key)) {
            seen.push(key);
            localStorage.setItem('hms_seen_updates', JSON.stringify(seen));
            if(currentUser.role === 'patient') setTimeout(loadMyPatientAppointments, 500); 
        }
    }
    
    const doctor = db.get('hms_users').find(u => u.id === apt.doctorId);
    
    document.getElementById('presc-doctor-name').innerText = doctor?.name || 'Unknown';
    document.getElementById('presc-doctor-spec').innerText = doctor?.specialty || '';
    document.getElementById('presc-problem').innerText = apt.problem || 'No details recorded.';
    document.getElementById('presc-medicines').innerText = apt.prescription || 'No medicines prescribed.';
    
    const banner = document.getElementById('presc-update-banner');
    if(banner) {
        if(apt.isUpdated) {
            banner.classList.remove('hidden');
            let dateStr = apt.updatedAt || 'recently';
            banner.innerHTML = `<i class="fa-solid fa-circle-exclamation mr-2"></i> <strong>Medical Update:</strong> The doctor updated your medical diagnosis or prescribed medications on ${dateStr}. Please review carefully.`;
        } else {
            banner.classList.add('hidden');
        }
    }
    
    let resText = "None Assigned.";
    const actionCont = document.getElementById('presc-scan-action');
    if(actionCont) {
        actionCont.innerHTML = '';
        actionCont.classList.add('hidden');
    }

    if(apt.assignedResources && document.getElementById('presc-resources')) {
        let texts = [];
        if(apt.assignedResources.bed) texts.push("• 1 Hospital Bed Allocated");
        if(apt.assignedResources.blood) texts.push(`• Blood: ${apt.assignedResources.blood.units} Units of ${apt.assignedResources.blood.type}`);
        if(apt.assignedResources.equipment) {
            const eqType = apt.assignedResources.equipment;
            texts.push(`• Mandatory Scan: ${eqType}`);
            
            if(currentUser.role === 'patient') {
                const alreadyBooked = db.get('hms_allocations').some(a => a.patientId === currentUser.id && a.type === `Scan: ${eqType}`);
                actionCont.classList.remove('hidden');
                if(alreadyBooked) {
                    actionCont.innerHTML = `<span class="inline-flex items-center px-3 py-1 bg-green-100 text-green-800 text-xs font-bold rounded-full"><i class="fa-solid fa-check mr-2"></i> Session Already Scheduled</span>`;
                } else {
                    actionCont.innerHTML = `<button onclick="openEquipmentModal('${eqType}')" class="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded shadow text-xs font-bold transition-transform hover:scale-105"><i class="fa-solid fa-calendar-plus mr-2"></i>Book ${eqType} Slot Now</button>`;
                }
            }
        }
        resText = texts.join('\n') || "None Assigned.";
    }
    if(document.getElementById('presc-resources')) document.getElementById('presc-resources').innerText = resText;
    
    const modal = document.getElementById('modal-prescription');
    modal.classList.remove('hidden');
    setTimeout(() => modal.classList.remove('opacity-0'), 10);
}

function closePrescriptionModal() {
    const modal = document.getElementById('modal-prescription');
    modal.classList.add('opacity-0');
    setTimeout(() => modal.classList.add('hidden'), 300);
}

async function updateAppointmentStatus(aptId, newStatus) {
    try {
        await fetch(`${API_URL}/appointments/${aptId}`, {
            method: 'PUT',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ status: newStatus })
        });
        await fetchDatabase();
        showToast(`Appointment status updated.`);
        if(currentUser.role === 'patient') loadMyPatientAppointments();
        if(currentUser.role === 'doctor') loadDoctorSchedule();
        if(currentUser.role === 'admin') loadAdminGlobalAppointments();
    } catch(err) {
        showToast('Server update failed!', 'error');
    }
}

// --- ADMIN LOGIC ---
function initAdminDashboard() {
    loadAdminGlobalAppointments();
    loadAdminDoctorsRoster();
    loadAdminResources();
}

function loadAdminGlobalAppointments() {
    const filterDoc = document.getElementById('admin-filter-doctor').value;
    
    let appointments = db.get('hms_appointments');
    const users = db.get('hms_users');
    const doctors = users.filter(u => u.role === 'doctor');
    
    const filterSelect = document.getElementById('admin-filter-doctor');
    if(filterSelect.options.length <= 1) {
        doctors.forEach(d => {
            const opt = document.createElement('option');
            opt.value = d.id;
            opt.textContent = `${d.name} (${d.specialty})`;
            filterSelect.appendChild(opt);
        });
    }
    
    if(filterDoc) appointments = appointments.filter(a => a.doctorId === filterDoc);
    
    appointments.sort((a,b) => new Date(b.date) - new Date(a.date));
    
    const list = document.getElementById('admin-global-appointments');
    
    if(appointments.length === 0) {
        list.innerHTML = `<tr><td colspan="6" class="px-6 py-4 text-center text-sm text-gray-500">No appointments found.</td></tr>`;
        return;
    }
    
    list.innerHTML = appointments.map(apt => {
        const patient = users.find(u => u.id === apt.patientId);
        const doctor = users.find(u => u.id === apt.doctorId);
        
        let statusBadge = '';
        if(apt.status === 'Pending') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">Pending</span>';
        else if(apt.status === 'Approved') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Approved</span>';
        else if(apt.status === 'Completed') statusBadge = '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">Completed</span>';
        else statusBadge = `<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">${apt.status}</span>`;
        
        const isEnded = apt.status.includes('Cancelled') || apt.status.includes('Withdrawn') || apt.status.includes('Declined') || apt.status === 'Completed';
        
        let actionBtns = '';
        if(!isEnded) {
            actionBtns = `<button onclick="updateAppointmentStatus('${apt.id}', 'Admin Cancelled')" class="text-red-500 hover:text-red-700 text-xs font-medium">Cancel Force</button>`;
        } else if(apt.status === 'Completed') {
            actionBtns = `<button onclick="openPrescriptionModal('${apt.id}')" class="text-teal-600 hover:text-teal-900 text-[11px] font-bold bg-teal-50 px-2 py-1 rounded-full border border-teal-100"><i class="fa-solid fa-file-medical mr-1"></i> View Rx</button>`;
        }
        
        return `
        <tr class="hover:bg-gray-50 transition-colors">
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${doctor?.name || 'Unknown'}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${patient?.name || 'Unknown'}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${new Date(apt.date).toLocaleDateString()}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-teal-700">${apt.slot}</td>
            <td class="px-6 py-4 whitespace-nowrap">${statusBadge}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-right flex justify-end">
                 ${actionBtns}
            </td>
        </tr>
        `;
    }).join('');
}

function loadAdminDoctorsRoster() {
    const users = db.get('hms_users');
    const doctors = users.filter(u => u.role === 'doctor');
    
    document.getElementById('admin-doctors-roster').innerHTML = doctors.map(d => `
        <div class="bg-white p-4 rounded-lg border border-gray-100 shadow-sm flex items-center justify-between hover:shadow-md transition-shadow">
            <div class="flex items-center gap-4">
                <div class="h-10 w-10 rounded-full bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-lg">
                    ${d.name.charAt(0)}
                </div>
                <div>
                    <h4 class="font-bold text-gray-800">${d.name}</h4>
                    <p class="text-xs text-gray-500"><i class="fa-solid fa-stethoscope mr-1"></i>${d.specialty}</p>
                </div>
            </div>
            <div class="text-right flex flex-col items-end">
                <span class="text-xs font-medium text-teal-600 bg-teal-50 px-2 py-1 rounded">Active Schedule</span>
                <span class="text-[10px] text-gray-400 mt-1">10 AM - 5 PM</span>
            </div>
        </div>
    `).join('');
}

function loadAdminResources() {
    let rawResources = db.get('hms_resources');
    if(!rawResources || !rawResources.beds) return;
    
    // Beds
    const beds = rawResources.beds;
    const bedsPct = Math.round((beds.available / beds.total) * 100);
    let bedColor = bedsPct > 50 ? 'bg-teal-500' : (bedsPct > 20 ? 'bg-yellow-500' : 'bg-red-500');
    
    document.getElementById('res-beds').innerHTML = `
        <div class="flex justify-between items-end mb-2">
            <div>
                <p class="text-sm text-gray-500">Available Beds</p>
                <p class="text-2xl font-bold text-gray-800">${beds.available} / ${beds.total}</p>
            </div>
            <i class="fa-solid fa-bed text-3xl text-gray-200"></i>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2">
            <div class="${bedColor} h-2 rounded-full transition-all duration-500" style="width: ${bedsPct}%"></div>
        </div>
    `;
    
    // Blood Bank
    const bloodBank = rawResources.bloodBank || {};
    const bbHtml = Object.entries(bloodBank).map(([type, qty]) => {
         let color = qty > 20 ? 'text-green-600 bg-green-50' : (qty > 10 ? 'text-yellow-600 bg-yellow-50' : 'text-red-600 bg-red-50');
         return `
         <div class="flex flex-col items-center p-2 rounded-lg ${color} border border-transparent">
             <span class="font-bold text-sm">${type}</span>
             <span class="text-xs opacity-80">${qty} Units</span>
         </div>
         `;
    }).join('');
    
    document.getElementById('res-blood').innerHTML = `
        <div class="grid grid-cols-3 gap-2">
            ${bbHtml}
        </div>
    `;
    
    // Equipment
    const eq = rawResources.equipment || {};
    const eqHtml = Object.entries(eq).map(([item, data]) => {
        let pct = Math.round((data.available / data.total) * 100);
        let color = pct > 50 ? 'bg-blue-500' : (pct > 20 ? 'bg-yellow-500' : 'bg-red-500');
        return `
        <div class="mb-3 last:mb-0">
            <div class="flex justify-between text-xs mb-1">
                <span class="font-medium text-gray-700 text-[13px]">${item}</span>
                <span class="text-gray-500">${data.available}/${data.total} Available</span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-1.5">
                <div class="${color} h-1.5 rounded-full" style="width: ${pct}%"></div>
            </div>
        </div>
        `;
    }).join('');
    
    document.getElementById('res-equipment').innerHTML = eqHtml;
}

// --- EQUIPMENT BOOKING LOGIC ---
let currentEqType = null;
let selectedEqSlot = null;

function openEquipmentModal(eqName) {
    currentEqType = eqName;
    document.getElementById('book-eq-name').innerText = `Equipment: ${eqName}`;
    document.getElementById('book-eq-date').value = '';
    document.getElementById('eq-slot-container').innerHTML = '<p class="text-gray-500 text-sm col-span-2">Select date to view slots.</p>';
    document.getElementById('btn-eq-confirm').disabled = true;
    
    document.getElementById('book-eq-date').onchange = (e) => checkEquipmentSlots(e.target.value);
    
    const prescModal = document.getElementById('modal-prescription');
    if(prescModal) {
        prescModal.classList.add('opacity-0');
        setTimeout(() => prescModal.classList.add('hidden'), 300);
    }
    
    const modal = document.getElementById('modal-equipment');
    modal.classList.remove('hidden');
    setTimeout(() => modal.classList.remove('opacity-0'), 10);
}

function closeEquipmentModal() {
    currentEqType = null;
    const modal = document.getElementById('modal-equipment');
    modal.classList.add('opacity-0');
    setTimeout(() => modal.classList.add('hidden'), 300);
}

function checkEquipmentSlots(date) {
    if(!date) return;
    
    const eqData = db.get('hms_resources').equipment[currentEqType];
    if(!eqData) return;
    
    const totalMachines = eqData.total;
    const availableSlots = ["09:00 AM", "10:00 AM", "11:00 AM", "01:00 PM", "02:00 PM", "03:00 PM", "04:00 PM"];
    const allocations = (db.get('hms_allocations') || []).filter(a => a.type === `Scan: ${currentEqType}` && a.date === date);
    
    let container = document.getElementById('eq-slot-container');
    container.innerHTML = '';
    
    availableSlots.forEach(slot => {
        let occupied = allocations.filter(a => a.slot === slot).length;
        let isFull = occupied >= totalMachines;
        
        const btn = document.createElement('button');
        btn.className = `px-3 py-2 text-sm rounded border ${isFull ? 'bg-gray-100 text-gray-400 cursor-not-allowed opacity-60 relative overflow-hidden' : 'bg-white text-blue-600 border-blue-200 hover:bg-blue-50 focus:ring-2 focus:ring-blue-500 hover:shadow-sm'} transition-all text-center font-medium`;
        
        btn.innerHTML = `
            ${slot} 
            <span class="block text-[10px] ${isFull?'text-red-500 mt-0.5':'text-green-600 mt-0.5 font-bold'}">
                ${isFull ? 'FULLY BOOKED' : (totalMachines - occupied) + ' Available'}
            </span>
        `;
        
        if(!isFull) {
            btn.onclick = () => {
                document.querySelectorAll('#eq-slot-container button').forEach(b => {
                    b.classList.remove('ring-2', 'ring-blue-600', 'bg-blue-50', 'border-blue-600');
                    if(!b.classList.contains('cursor-not-allowed')) {
                        b.classList.add('bg-white', 'border-blue-200');
                    }
                });
                btn.classList.add('ring-2', 'ring-blue-600', 'bg-blue-50', 'border-blue-600');
                btn.classList.remove('bg-white', 'border-blue-200');
                selectedEqSlot = slot;
                document.getElementById('btn-eq-confirm').disabled = false;
            };
        }
        container.appendChild(btn);
    });
}

async function confirmEquipmentBooking() {
    const date = document.getElementById('book-eq-date').value;
    if(!date || !selectedEqSlot || !currentEqType) return;
    
    try {
        const res = await fetch(`${API_URL}/scans`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
                patientId: currentUser.id,
                equipment: currentEqType,
                date: date,
                slot: selectedEqSlot
            })
        });
        
        const json = await res.json();
        if(json.success) {
            showToast(`${currentEqType} Booked Successfully!`);
            await fetchDatabase();
            closeEquipmentModal();
            loadMyPatientAppointments();
        } else {
            showToast(json.error || 'Failed to book slot', 'error');
        }
    } catch(err) {
        showToast('Server connection failed', 'error');
    }
}

// --- ADMIN RESOURCES EDITOR ---
function openResourceEditor() {
    const res = db.get('hms_resources');
    if(!res) return;
    
    let html = `
        <div class="grid grid-cols-2 gap-6">
            <div class="col-span-2 shadow-sm border p-4 rounded-lg bg-gray-50">
                <h4 class="font-bold text-gray-700 mb-3 border-b pb-2"><i class="fa-solid fa-bed mr-2 text-teal-500"></i>Hospital Beds</h4>
                <div class="grid grid-cols-2 gap-4">
                    <div><label class="block text-xs text-gray-500 mb-1">Total Beds</label><input type="number" id="edit-bed-total" value="${res.beds.total}" class="w-full px-3 py-2 border rounded"></div>
                    <div><label class="block text-xs text-gray-500 mb-1">Available Beds</label><input type="number" id="edit-bed-avail" value="${res.beds.available}" class="w-full px-3 py-2 border rounded"></div>
                </div>
            </div>
            
            <div class="col-span-2 shadow-sm border p-4 rounded-lg bg-red-50">
                <h4 class="font-bold text-gray-700 mb-3 border-b pb-2 border-red-200"><i class="fa-solid fa-droplet mr-2 text-red-500"></i>Blood Bank (Units)</h4>
                <div class="grid grid-cols-3 md:grid-cols-5 gap-3">
                    ${Object.keys(res.bloodBank).map(type => `
                        <div><label class="block text-xs font-bold text-red-600 mb-1">${type}</label><input type="number" id="edit-blood-${type.replace('+','p').replace('-','m')}" value="${res.bloodBank[type]}" class="w-full px-2 py-1.5 border border-red-200 rounded text-sm"></div>
                    `).join('')}
                </div>
            </div>

            <div class="col-span-2 shadow-sm border p-4 rounded-lg bg-blue-50">
                <h4 class="font-bold text-gray-700 mb-3 border-b pb-2 border-blue-200"><i class="fa-solid fa-microscope mr-2 text-blue-500"></i>Critical Equipment</h4>
                <div class="space-y-3">
                    ${Object.keys(res.equipment).map((eq, i) => `
                        <div class="flex items-center gap-4 bg-white p-2 rounded border border-blue-100">
                            <span class="w-1/3 font-bold text-sm text-gray-700">${eq}</span>
                            <div class="w-1/3"><label class="text-[10px] text-gray-400 block">Total</label><input type="number" id="edit-eq-total-${i}" value="${res.equipment[eq].total}" class="w-full px-2 py-1 border rounded text-sm"></div>
                            <div class="w-1/3"><label class="text-[10px] text-gray-400 block">Available</label><input type="number" id="edit-eq-avail-${i}" value="${res.equipment[eq].available}" class="w-full px-2 py-1 border rounded text-sm"></div>
                        </div>
                    `).join('')}
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('admin-inventory-form').innerHTML = html;
    
    const modal = document.getElementById('modal-admin-resources');
    modal.classList.remove('hidden');
    setTimeout(() => modal.classList.remove('opacity-0'), 10);
}

function closeResourceEditor() {
    const modal = document.getElementById('modal-admin-resources');
    modal.classList.add('opacity-0');
    setTimeout(() => modal.classList.add('hidden'), 300);
}

async function saveResourceInventory() {
    const res = db.get('hms_resources');
    const newRes = JSON.parse(JSON.stringify(res));
    
    newRes.beds.total = parseInt(document.getElementById('edit-bed-total').value, 10) || 0;
    newRes.beds.available = parseInt(document.getElementById('edit-bed-avail').value, 10) || 0;
    
    Object.keys(newRes.bloodBank).forEach(type => {
        const id = `edit-blood-${type.replace('+','p').replace('-','m')}`;
        newRes.bloodBank[type] = parseInt(document.getElementById(id).value, 10) || 0;
    });
    
    Object.keys(newRes.equipment).forEach((eq, i) => {
        newRes.equipment[eq].total = parseInt(document.getElementById(`edit-eq-total-${i}`).value, 10) || 0;
        newRes.equipment[eq].available = parseInt(document.getElementById(`edit-eq-avail-${i}`).value, 10) || 0;
    });
    
    try {
        const resp = await fetch(`${API_URL}/resources`, {
            method: 'PUT',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ resources: newRes })
        });
        const json = await resp.json();
        if(json.success) {
            showToast('Inventory saved perfectly!');
            await fetchDatabase();
            closeResourceEditor();
            loadAdminResources();
        } else {
            showToast('Failed to save', 'error');
        }
    } catch(err) {
        showToast('Server update failed!', 'error');
    }
}

// --- DARK MODE LOGIC (SAP Fiori Horizon) ---
function toggleDarkMode() {
    const html = document.documentElement;
    const body = document.body;
    const icon = document.getElementById('theme-icon');
    
    // Fallback to body class toggle if documentElement doesn't have dark mode setup
    if (body.classList.contains('dark')) {
        body.classList.remove('dark');
        icon.classList.replace('fa-sun', 'fa-moon');
        localStorage.setItem('sap_theme', 'light');
    } else {
        body.classList.add('dark');
        icon.classList.replace('fa-moon', 'fa-sun');
        localStorage.setItem('sap_theme', 'dark');
    }
}

// Check saved theme on load
document.addEventListener('DOMContentLoaded', () => {
    if (localStorage.getItem('sap_theme') === 'dark') {
        document.body.classList.add('dark');
        const icon = document.getElementById('theme-icon');
        if(icon) icon.classList.replace('fa-moon', 'fa-sun');
    }
});
