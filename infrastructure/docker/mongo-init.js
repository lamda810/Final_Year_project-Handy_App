// MongoDB initialization script for Handy Go
// This script runs when the MongoDB container is first created

// Switch to the handygo database
db = db.getSiblingDB('handygo');

// Create application user
db.createUser({
  user: 'handygo_app',
  pwd: 'handygo_app_password',
  roles: [
    {
      role: 'readWrite',
      db: 'handygo',
    },
  ],
});

// Create collections with validation schemas
db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['phone', 'role', 'password'],
      properties: {
        phone: {
          bsonType: 'string',
          description: 'Phone number is required',
        },
        role: {
          enum: ['CUSTOMER', 'WORKER', 'ADMIN'],
          description: 'Role must be one of: CUSTOMER, WORKER, ADMIN',
        },
        email: {
          bsonType: 'string',
        },
        password: {
          bsonType: 'string',
          description: 'Password is required',
        },
        isVerified: {
          bsonType: 'bool',
        },
        isActive: {
          bsonType: 'bool',
        },
      },
    },
  },
});

db.createCollection('customers');
db.createCollection('workers');
db.createCollection('bookings');
db.createCollection('reviews');
db.createCollection('notifications');
db.createCollection('sos');
db.createCollection('otps');

// Create indexes
db.users.createIndex({ phone: 1 }, { unique: true });
db.users.createIndex({ email: 1 }, { sparse: true });
db.users.createIndex({ role: 1 });

db.customers.createIndex({ user: 1 }, { unique: true });

db.workers.createIndex({ user: 1 }, { unique: true });
db.workers.createIndex({ cnic: 1 }, { unique: true });
db.workers.createIndex({ currentLocation: '2dsphere' });
db.workers.createIndex({ 'skills.category': 1 });
db.workers.createIndex({ status: 1, 'availability.isAvailable': 1 });
db.workers.createIndex({ trustScore: -1 });

db.bookings.createIndex({ bookingNumber: 1 }, { unique: true });
db.bookings.createIndex({ customer: 1, createdAt: -1 });
db.bookings.createIndex({ worker: 1, createdAt: -1 });
db.bookings.createIndex({ status: 1 });
db.bookings.createIndex({ serviceCategory: 1, status: 1 });
db.bookings.createIndex({ scheduledDateTime: 1 });
db.bookings.createIndex({ 'address.coordinates': '2dsphere' });

db.notifications.createIndex({ recipient: 1, createdAt: -1 });
db.notifications.createIndex({ recipient: 1, isRead: 1 });
db.notifications.createIndex({ createdAt: 1 }, { expireAfterSeconds: 2592000 });

db.otps.createIndex({ phone: 1, purpose: 1 });
db.otps.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

db.sos.createIndex({ status: 1, priority: -1 });
db.sos.createIndex({ booking: 1 });
db.sos.createIndex({ location: '2dsphere' });

db.reviews.createIndex({ booking: 1 }, { unique: true });
db.reviews.createIndex({ worker: 1, createdAt: -1 });
db.reviews.createIndex({ customer: 1, createdAt: -1 });

// Seed a local development admin account for the admin panel.
db.users.updateOne(
  { phone: '+920000000000' },
  {
    $setOnInsert: {
      role: 'ADMIN',
      phone: '+920000000000',
      email: 'admin@local.handygo',
      password: '$2a$12$O0TOrETy22mpgOH2uUD/IurYlM8YTkWo3HG1dHqz6LKsOkoMYWL3W',
      isVerified: true,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  },
  { upsert: true }
);

print('Handy Go database initialized successfully!');
