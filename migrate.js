require('dotenv').config();
const mongoose = require('mongoose');
const fs = require('fs');
const { User, Appointment, Allocation, Resource } = require('./models');

async function migrateData() {
    try {
        console.log("Connecting to MongoDB Atlas...");
        await mongoose.connect(process.env.MONGODB_URI);
        console.log("Connected successfully.");

        // Read local JSON
        const data = JSON.parse(fs.readFileSync('./database.json', 'utf-8'));

        console.log("Starting Migration...");

        // 1. Migrate Users
        let usersMigrated = 0;
        for (const user of data.users) {
            await User.findOneAndUpdate({ id: user.id }, user, { upsert: true, new: true, setDefaultsOnInsert: true });
            usersMigrated++;
        }
        console.log(`Migrated ${usersMigrated} Users.`);

        // 2. Migrate Appointments
        let aptsMigrated = 0;
        for (const apt of data.appointments) {
            await Appointment.findOneAndUpdate({ id: apt.id }, apt, { upsert: true, new: true, setDefaultsOnInsert: true });
            aptsMigrated++;
        }
        console.log(`Migrated ${aptsMigrated} Appointments.`);

        // 3. Migrate Allocations
        let allocsMigrated = 0;
        if (data.allocations) {
            for (const alloc of data.allocations) {
                await Allocation.findOneAndUpdate({ id: alloc.id }, alloc, { upsert: true, new: true, setDefaultsOnInsert: true });
                allocsMigrated++;
            }
        }
        console.log(`Migrated ${allocsMigrated} Allocations.`);

        // 4. Migrate Resources (Singleton)
        if (data.resources) {
            await Resource.findOneAndUpdate(
                { singletonId: 'default' },
                { singletonId: 'default', ...data.resources },
                { upsert: true, new: true, setDefaultsOnInsert: true }
            );
            console.log("Migrated Resources successfully.");
        }

        console.log("Migration Complete!");
        process.exit(0);
    } catch (err) {
        console.error("Migration Failed:", err);
        process.exit(1);
    }
}

migrateData();
