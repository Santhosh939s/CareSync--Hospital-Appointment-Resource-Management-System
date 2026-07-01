const express = require('express');
const cors = require('cors');
const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config();

const { User, Appointment, Allocation, FinancialLedger, PurchaseOrder, Resource } = require('./models');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname)); // Serve frontend files

// Connect to MongoDB Atlas
mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
      console.log('Connected to MongoDB Atlas');
      
      // Initialize default resources if not exists
      const count = await Resource.countDocuments();
      if (count === 0) {
          await new Resource().save();
          console.log('Initialized default hospital resources in MongoDB.');
      }
  })
  .catch(err => console.error('MongoDB connection error:', err));

// --- API ENDPOINTS ---

// GET entirely database (OData Style Response)
app.get('/api/data', async (req, res) => {
    try {
        const users = await User.find().lean();
        const appointments = await Appointment.find().lean();
        const resources = await Resource.findOne().lean() || {};
        const allocations = await Allocation.find().lean();
        const financial_ledgers = await FinancialLedger.find().lean();
        const purchase_orders = await PurchaseOrder.find().lean();
        
        res.json({
            d: {
                results: {
                    hms_users: users,
                    hms_appointments: appointments,
                    hms_resources: resources,
                    hms_allocations: allocations,
                    hms_financials: financial_ledgers,
                    hms_purchasing: purchase_orders
                }
            }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST to register a new user
app.post('/api/users', async (req, res) => {
    try {
        const newUser = new User(req.body);
        await newUser.save();
        res.json({ success: true, user: newUser });
    } catch (err) {
        res.status(400).json({ success: false, error: err.message });
    }
});

// POST for guest/recruiter login
app.post('/api/guest-login', async (req, res) => {
    const { role } = req.body; // 'patient', 'doctor', or 'admin'
    
    let email = '';
    if (role === 'patient') email = 'abcd@gmail.com';
    else if (role === 'doctor') email = 'ananya@hospital.com';
    else if (role === 'admin') email = 'admin@hospital.com';
    else return res.status(400).json({ success: false, error: 'Invalid role' });
    
    try {
        let user = await User.findOne({ email });
        
        if (!user) {
            return res.status(404).json({ success: false, error: 'Guest account not found. Please run data migration.' });
        }
        
        res.json({ success: true, user });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// POST to save a new appointment
app.post('/api/appointments', async (req, res) => {
    try {
        const newAppointment = new Appointment(req.body);
        await newAppointment.save();
        res.json({ success: true, appointment: newAppointment });
    } catch (err) {
        res.status(400).json({ success: false, error: err.message });
    }
});

// PUT to update an appointment completely or partially
app.put('/api/appointments/:id', async (req, res) => {
    const { id } = req.params;
    const { status, problem, prescription, resources, isUpdated, updatedAt } = req.body;
    
    try {
        const appointment = await Appointment.findOne({ id });
        if (!appointment) return res.status(404).json({ success: false, error: 'Appointment not found' });
        
        if (status) appointment.status = status;
        if (problem !== undefined) appointment.set('problem', problem);
        if (prescription !== undefined) appointment.set('prescription', prescription);
        
        if (isUpdated) {
            appointment.set('isUpdated', true);
            appointment.set('updatedAt', updatedAt);
        }
        
        const resourceDoc = await Resource.findOne();
        const patientId = appointment.patientId;
        const today = new Date().toISOString().split('T')[0];
        
        // If doctor prescribed resources, deduct & allocate
        if (resources && !isUpdated) {
            appointment.set('assignedResources', resources);
            
            if (resources.bed && resourceDoc.beds.available > 0) {
                resourceDoc.beds.available -= 1;
                await new Allocation({ id: 'alc'+Date.now()+'b', type: 'Bed', patientId, amount: 1, date: today, status: 'Active' }).save();
                await new FinancialLedger({ docId: 'FI'+Date.now()+'b', patientId, type: 'Bed Allocation Charge', amount: 500, date: today, status: 'Posted' }).save();
            }
            
            if (resources.blood && resources.blood.type && resources.blood.units > 0) {
                const bType = resources.blood.type;
                if (resourceDoc.bloodBank[bType] >= resources.blood.units) {
                    resourceDoc.bloodBank[bType] -= resources.blood.units;
                    await new Allocation({ id: 'alc'+Date.now()+'bl', type: `Blood (${bType})`, patientId, amount: resources.blood.units, date: today, status: 'Fulfilled' }).save();
                    await new FinancialLedger({ docId: 'FI'+Date.now()+'bl', patientId, type: `Blood Transfusion (${bType})`, amount: resources.blood.units * 150, date: today, status: 'Posted' }).save();
                    
                    if (resourceDoc.bloodBank[bType] <= 10) {
                        await new PurchaseOrder({ prId: 'PR'+Date.now(), material: `Blood ${bType}`, quantityReq: 20, status: 'Created', date: today }).save();
                    }
                }
            }
            await resourceDoc.save();
        }
        
        // FI/CO: Generate generic consultation charge upon completion
        if (status === 'Completed' && !isUpdated) {
            await new FinancialLedger({ docId: 'FI'+Date.now()+'c', patientId, type: 'Consultation Fee', amount: 200, date: today, status: 'Posted' }).save();
        }
        
        await appointment.save();
        res.json({ success: true, appointment });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// POST to book an equipment scan (MRI, etc)
app.post('/api/scans', async (req, res) => {
    const { patientId, equipment, date, slot } = req.body;
    try {
        const resourceDoc = await Resource.findOne();
        if (!resourceDoc) return res.status(500).json({ error: "Resource document missing" });
        
        const eqData = resourceDoc.equipment[equipment];
        if (!eqData) return res.status(400).json({ error: "Unknown equipment" });
        
        // capacity check
        const bookedCount = await Allocation.countDocuments({ type: `Scan: ${equipment}`, date, slot });
        if (bookedCount >= eqData.total) { 
            return res.status(400).json({ error: "No machines available at this time slot" });
        }
        
        if (resourceDoc.equipment[equipment].available > 0) {
            resourceDoc.equipment[equipment].available -= 1;
        }
        
        const newScan = new Allocation({ id: 'scn'+Date.now(), type: `Scan: ${equipment}`, patientId, amount: 1, date, slot, status: 'Scheduled' });
        await newScan.save();
        
        await new FinancialLedger({ docId: 'FI'+Date.now()+'eq', patientId, type: `Equipment Scan (${equipment})`, amount: 1200, date, status: 'Posted' }).save();
        
        if (resourceDoc.equipment[equipment].available <= 1) {
             await new PurchaseOrder({ prId: 'PR'+Date.now()+'eq', material: `Maintenance / Lease for ${equipment}`, quantityReq: 1, status: 'Created', date }).save();
        }
        
        await resourceDoc.save();
        res.json({ success: true, scan: newScan });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT to overwrite entire hospital equipment totals (Admin only)
app.put('/api/resources', async (req, res) => {
    const newResources = req.body.resources;
    if(!newResources) return res.status(400).json({ error: "No resources provided" });
    
    try {
        const resourceDoc = await Resource.findOne();
        if (resourceDoc) {
            resourceDoc.beds = newResources.beds;
            resourceDoc.bloodBank = newResources.bloodBank;
            resourceDoc.equipment = newResources.equipment;
            await resourceDoc.save();
            res.json({ success: true, resources: resourceDoc });
        } else {
            res.status(404).json({ error: "Resource document not found" });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`CareSync Backend Server is actively running on port ${PORT}`));
