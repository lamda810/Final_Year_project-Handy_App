import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import mongoose from 'mongoose';
import { User, Customer, Worker } from '@handy-go/shared';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// backend/scripts -> backend -> handy-go (repo root)
dotenv.config({ path: resolve(__dirname, '../../.env') });

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/handygo';

// Shared test password for every seeded account. Meets the backend's
// password policy: 8+ chars, upper, lower, number, special char.
const SEED_PASSWORD = 'Passw0rd!';

interface SeedUser {
  phone: string;
  email: string;
  role: 'ADMIN' | 'CUSTOMER' | 'WORKER';
  isActive?: boolean;
}

const seedUsers: SeedUser[] = [
  { phone: '+923000000000', email: 'admin@handygo.pk', role: 'ADMIN' },
  { phone: '+923001234567', email: 'ali@example.com', role: 'CUSTOMER' },
  { phone: '+923009876543', email: 'fatima@example.com', role: 'CUSTOMER' },
  { phone: '+923111111111', email: 'umer.worker@example.com', role: 'WORKER' },
  { phone: '+923222222222', email: 'hina.worker@example.com', role: 'WORKER' },
];

const seedCustomerProfiles: Record<string, { firstName: string; lastName: string }> = {
  'ali@example.com': { firstName: 'Ali', lastName: 'Khan' },
  'fatima@example.com': { firstName: 'Fatima', lastName: 'Noor' },
};

const seedWorkerProfiles: Record<
  string,
  {
    firstName: string;
    lastName: string;
    cnic: string;
    skills: Array<{ category: string; experience: number; hourlyRate: number; isVerified: boolean }>;
    status: string;
  }
> = {
  'umer.worker@example.com': {
    firstName: 'Umer',
    lastName: 'Shah',
    cnic: '42101-1234567-1',
    skills: [{ category: 'PLUMBING', experience: 5, hourlyRate: 1200, isVerified: true }],
    status: 'ACTIVE',
  },
  'hina.worker@example.com': {
    firstName: 'Hina',
    lastName: 'Adeel',
    cnic: '35202-7654321-2',
    skills: [{ category: 'CLEANING', experience: 3, hourlyRate: 900, isVerified: false }],
    status: 'PENDING_VERIFICATION',
  },
};

async function seed() {
  await mongoose.connect(MONGODB_URI);
  console.log(`Connected to ${MONGODB_URI}`);

  for (const seedUser of seedUsers) {
    let user = await User.findOne({ phone: seedUser.phone });

    if (!user) {
      user = await User.create({
        phone: seedUser.phone,
        email: seedUser.email,
        password: SEED_PASSWORD,
        role: seedUser.role,
        isVerified: true,
        isActive: seedUser.isActive ?? true,
      });
      console.log(`Created user ${seedUser.email} (${seedUser.role})`);
    } else {
      user.email = seedUser.email;
      user.password = SEED_PASSWORD;
      user.isVerified = true;
      user.isActive = seedUser.isActive ?? true;
      await user.save();
      console.log(`Updated user ${seedUser.email} (${seedUser.role})`);
    }

    const customerProfile = seedCustomerProfiles[seedUser.email];
    if (customerProfile) {
      const existing = await Customer.findOne({ user: user._id });
      if (!existing) {
        await Customer.create({ user: user._id, ...customerProfile });
        console.log(`  + customer profile: ${customerProfile.firstName} ${customerProfile.lastName}`);
      }
    }

    const workerProfile = seedWorkerProfiles[seedUser.email];
    if (workerProfile) {
      const existing = await Worker.findOne({ user: user._id });
      if (!existing) {
        await Worker.create({ user: user._id, ...workerProfile });
        console.log(`  + worker profile: ${workerProfile.firstName} ${workerProfile.lastName} (${workerProfile.status})`);
      }
    }
  }

  console.log('\nSeed complete. Test credentials (phone or email + password):');
  console.log(`  password for every account: ${SEED_PASSWORD}\n`);
  for (const u of seedUsers) {
    console.log(`  ${u.role.padEnd(8)} phone=${u.phone}  email=${u.email}`);
  }

  await mongoose.connection.close();
}

seed().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
