const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

const dbPath = path.join(__dirname, 'database.json');

// Safely read the database file
const readDB = () => {
    try {
        if (!fs.existsSync(dbPath)) {
            // Default fallback structure
             return { users: [], appointments: [], resources: {} };
        }
        const data = fs.readFileSync(dbPath, 'utf8');
        return JSON.parse(data);
    } catch (err) {
        console.error("DB Read Error", err);
        return { users: [], appointments: [], resources: {} };
    }
};

// Safely write the database file
const writeDB = (data) => {
    try {
        fs.writeFileSync(dbPath, JSON.stringify(data, null, 2), 'utf8');
    } catch (err) {
        console.error("DB Write Error", err);
    }
};

// --- API ENDPOINTS ---

// GET entirely database (for easiest client refactor)
app.get('/api/data', (req, res) => {
    const db = readDB();
    if(!db.allocations) { db.allocations = []; writeDB(db); }
    res.json({
        hms_users: db.users,
        hms_appointments: db.appointments,
        hms_resources: db.resources,
        hms_allocations: db.allocations
    });
});

// POST to register a new patient
app.post('/api/users', (req, res) => {
    const db = readDB();
    const newUser = req.body;
    db.users.push(newUser);
    writeDB(db);
    res.json({ success: true, user: newUser });
});

// POST to save a new appointment
app.post('/api/appointments', (req, res) => {
    const db = readDB();
    const newAppointment = req.body;
    db.appointments.push(newAppointment);
    writeDB(db);
    res.json({ success: true, appointment: newAppointment });
});

// PUT to update an appointment completely or partially
app.put('/api/appointments/:id', (req, res) => {
    const db = readDB();
    if(!db.allocations) db.allocations = [];
    
    const { id } = req.params;
    const { status, problem, prescription, resources, isUpdated, updatedAt } = req.body;
    
    const index = db.appointments.findIndex(a => a.id === id);
    if(index !== -1 && status) {
        db.appointments[index].status = status;
        if(problem !== undefined) db.appointments[index].problem = problem;
        if(prescription !== undefined) db.appointments[index].prescription = prescription;
        if(isUpdated) {
            db.appointments[index].isUpdated = true;
            db.appointments[index].updatedAt = updatedAt;
        }
        
        // If doctor prescribed resources, deduct & allocate
        if(resources && !isUpdated) {
            db.appointments[index].assignedResources = resources;
            const patientId = db.appointments[index].patientId;
            const today = new Date().toISOString().split('T')[0];
            
            if(resources.bed) {
                if(db.resources.beds.available > 0) {
                    db.resources.beds.available -= 1;
                    db.allocations.push({ id: 'alc'+Date.now()+'b', type: 'Bed', patientId, amount: 1, date: today, status: 'Active' });
                }
            }
            if(resources.blood && resources.blood.type && resources.blood.units > 0) {
                const bType = resources.blood.type;
                if(db.resources.bloodBank[bType] >= resources.blood.units) {
                    db.resources.bloodBank[bType] -= resources.blood.units;
                    db.allocations.push({ id: 'alc'+Date.now()+'bl', type: `Blood (${bType})`, patientId, amount: resources.blood.units, date: today, status: 'Fulfilled' });
                }
            }
            // Equipment is just written onto the prescription; patient books slot themselves below
        }
        
        writeDB(db);
        res.json({ success: true, appointment: db.appointments[index] });
    } else {
        res.status(404).json({ success: false, error: 'Appointment not found or missing fields' });
    }
});

// POST to book an equipment scan (MRI, etc)
app.post('/api/scans', (req, res) => {
    const db = readDB();
    if(!db.allocations) db.allocations = [];
    
    const { patientId, equipment, date, slot } = req.body;
    const eqData = db.resources.equipment[equipment];
    
    if(!eqData) return res.status(400).json({ error: "Unknown equipment" });
    
    // capacity check
    const bookedCount = db.allocations.filter(a => a.type === `Scan: ${equipment}` && a.date === date && a.slot === slot).length;
    if(bookedCount >= eqData.total) { 
        return res.status(400).json({ error: "No machines available at this time slot" });
    }
    
    // Decrement the global available sum for the Admin Dashboard progress bars
    if (db.resources.equipment[equipment] && db.resources.equipment[equipment].available > 0) {
        db.resources.equipment[equipment].available -= 1;
    }
    
    const newScan = { id: 'scn'+Date.now(), type: `Scan: ${equipment}`, patientId, amount: 1, date, slot, status: 'Scheduled' };
    db.allocations.push(newScan);
    writeDB(db);
    res.json({ success: true, scan: newScan });
});

// PUT to overwrite entire hospital equipment totals (Admin only)
app.put('/api/resources', (req, res) => {
    const db = readDB();
    const newResources = req.body.resources;
    if(!newResources) return res.status(400).json({ error: "No resources provided" });
    
    db.resources = newResources;
    writeDB(db);
    res.json({ success: true, resources: db.resources });
});

const PORT = 3000;
app.listen(PORT, () => console.log(`CareSync Backend Server is actively running on http://localhost:${PORT}`));
