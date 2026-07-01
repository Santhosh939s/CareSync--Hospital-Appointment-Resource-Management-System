const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    role: { type: String, enum: ['patient', 'doctor', 'admin'], required: true },
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    specialty: { type: String },
    maxPatients: { type: Number },
    department: { type: String }
}, { strict: false });

const AppointmentSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    doctorId: { type: String, required: true },
    patientId: { type: String, required: true },
    date: { type: String, required: true },
    slot: { type: String, required: true },
    status: { type: String, enum: ['Scheduled', 'Completed', 'Cancelled'], default: 'Scheduled' }
}, { strict: false });

const AllocationSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    type: { type: String, required: true },
    patientId: { type: String, required: true },
    amount: { type: Number, default: 1 },
    date: { type: String, required: true },
    slot: { type: String },
    status: { type: String, default: 'Scheduled' }
}, { strict: false });

const FinancialLedgerSchema = new mongoose.Schema({
    docId: { type: String, required: true, unique: true },
    patientId: { type: String, required: true },
    type: { type: String, required: true },
    amount: { type: Number, required: true },
    date: { type: String, required: true },
    status: { type: String, default: 'Posted' }
}, { strict: false });

const PurchaseOrderSchema = new mongoose.Schema({
    prId: { type: String, required: true, unique: true },
    material: { type: String, required: true },
    quantityReq: { type: Number, required: true },
    date: { type: String, required: true },
    status: { type: String, default: 'Created' }
}, { strict: false });

const ResourceSchema = new mongoose.Schema({
    singletonId: { type: String, default: 'default', unique: true },
    beds: {
        total: { type: Number, default: 50 },
        available: { type: Number, default: 22 }
    },
    bloodBank: {
        'A+': { type: Number, default: 25 },
        'A-': { type: Number, default: 10 },
        'B+': { type: Number, default: 30 },
        'B-': { type: Number, default: 5 },
        'O+': { type: Number, default: 40 },
        'O-': { type: Number, default: 15 },
        'AB+': { type: Number, default: 20 },
        'AB-': { type: Number, default: 8 }
    },
    equipment: {
        'MRI': { 
            total: { type: Number, default: 2 }, 
            available: { type: Number, default: 1 } 
        },
        'CT-Scan': { 
            total: { type: Number, default: 3 }, 
            available: { type: Number, default: 2 } 
        },
        'X-Ray': { 
            total: { type: Number, default: 5 }, 
            available: { type: Number, default: 4 } 
        },
        'Ventilator': { 
            total: { type: Number, default: 10 }, 
            available: { type: Number, default: 6 } 
        }
    }
}, { strict: false });

module.exports = {
    User: mongoose.model('User', UserSchema),
    Appointment: mongoose.model('Appointment', AppointmentSchema),
    Allocation: mongoose.model('Allocation', AllocationSchema),
    FinancialLedger: mongoose.model('FinancialLedger', FinancialLedgerSchema),
    PurchaseOrder: mongoose.model('PurchaseOrder', PurchaseOrderSchema),
    Resource: mongoose.model('Resource', ResourceSchema)
};
