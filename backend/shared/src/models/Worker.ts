import mongoose, { Document, Schema, Model } from 'mongoose';
import {
  SERVICE_CATEGORIES,
  ServiceCategory,
  WORKER_VERIFICATION_STATUS,
  WorkerVerificationStatus,
  DAYS_OF_WEEK,
  DayOfWeek,
  DEFAULTS,
} from '../constants/index.js';

/**
 * Skill Interface
 */
export interface ISkill {
  category: ServiceCategory;
  experience: number; // Years
  hourlyRate: number;
  isVerified: boolean;
}

/**
 * Schedule Interface
 */
export interface ISchedule {
  day: DayOfWeek;
  startTime: string; // HH:mm format
  endTime: string; // HH:mm format
}

/**
 * Bank Details Interface
 */
export interface IBankDetails {
  accountTitle: string;
  accountNumber: string;
  bankName: string;
}

/**
 * Document Interface (for worker documents like certificates)
 */
export interface IWorkerDocument {
  _id?: mongoose.Types.ObjectId;
  type: string;
  url: string;
  verified: boolean;
  uploadedAt: Date;
}

/**
 * GeoJSON Point Interface
 */
export interface IGeoPoint {
  type: 'Point';
  coordinates: [number, number]; // [longitude, latitude]
}

/**
 * Worker Document Interface
 */
export interface IWorker extends Document {
  _id: mongoose.Types.ObjectId;
  user: mongoose.Types.ObjectId;
  firstName: string;
  lastName: string;
  profileImage?: string;
  contactPhone?: string;
  cnic: string;
  cnicVerified: boolean;
  cnicImages: {
    front?: string;
    back?: string;
  };
  skills: ISkill[];
  currentLocation?: IGeoPoint;
  serviceRadius: number;
  availability: {
    isAvailable: boolean;
    schedule: ISchedule[];
  };
  rating: {
    average: number;
    count: number;
  };
  trustScore: number;
  totalJobsCompleted: number;
  totalEarnings: number;
  bankDetails?: IBankDetails;
  documents: IWorkerDocument[];
  status: WorkerVerificationStatus;
  createdAt: Date;
  updatedAt: Date;

  // Virtuals
  fullName: string;

  // Methods
  updateLocation(lat: number, lng: number): Promise<IWorker>;
  updateRating(newRating: number): Promise<IWorker>;
}

/**
 * Worker Model Interface
 */
export interface IWorkerModel extends Model<IWorker> {
  findByUserId(userId: mongoose.Types.ObjectId | string): Promise<IWorker | null>;
  findByCNIC(cnic: string): Promise<IWorker | null>;
  findNearby(
    lat: number,
    lng: number,
    maxDistance: number,
    category?: ServiceCategory
  ): Promise<IWorker[]>;
}

/**
 * Skill Sub-Schema
 */
const skillSchema = new Schema<ISkill>(
  {
    category: {
      type: String,
      enum: SERVICE_CATEGORIES,
      required: [true, 'Skill category is required'],
    },
    experience: {
      type: Number,
      required: [true, 'Experience is required'],
      min: [0, 'Experience cannot be negative'],
      max: [50, 'Experience cannot exceed 50 years'],
    },
    hourlyRate: {
      type: Number,
      required: [true, 'Hourly rate is required'],
      min: [0, 'Hourly rate cannot be negative'],
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
  },
  { _id: false }
);

/**
 * Schedule Sub-Schema
 */
const scheduleSchema = new Schema<ISchedule>(
  {
    day: {
      type: String,
      enum: DAYS_OF_WEEK,
      required: true,
    },
    startTime: {
      type: String,
      required: true,
      match: [/^([01]\d|2[0-3]):([0-5]\d)$/, 'Time must be in HH:mm format'],
    },
    endTime: {
      type: String,
      required: true,
      match: [/^([01]\d|2[0-3]):([0-5]\d)$/, 'Time must be in HH:mm format'],
    },
  },
  { _id: false }
);

/**
 * Document Sub-Schema
 */
const workerDocumentSchema = new Schema<IWorkerDocument>(
  {
    type: {
      type: String,
      required: true,
      trim: true,
    },
    url: {
      type: String,
      required: true,
      trim: true,
    },
    verified: {
      type: Boolean,
      default: false,
    },
    uploadedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: true }
);

/**
 * GeoJSON Point Schema
 */
const geoPointSchema = new Schema<IGeoPoint>(
  {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
      validate: {
        validator: function (coords: number[]) {
          const lng = coords[0];
          const lat = coords[1];
          return (
            coords.length === 2 &&
            lng !== undefined &&
            lat !== undefined &&
            lng >= -180 &&
            lng <= 180 &&
            lat >= -90 &&
            lat <= 90
          );
        },
        message: 'Invalid coordinates',
      },
    },
  },
  { _id: false }
);

/**
 * Worker Schema
 */
const workerSchema = new Schema<IWorker, IWorkerModel>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      unique: true,
    },
    firstName: {
      type: String,
      required: [true, 'First name is required'],
      trim: true,
      maxlength: [50, 'First name cannot exceed 50 characters'],
    },
    lastName: {
      type: String,
      required: [true, 'Last name is required'],
      trim: true,
      maxlength: [50, 'Last name cannot exceed 50 characters'],
    },
    profileImage: {
      type: String,
      trim: true,
    },
    contactPhone: {
      type: String,
      trim: true,
      match: [/^(\+92|0)?3[0-9]{9}$/, 'Contact number must be a valid Pakistani mobile number'],
    },
    cnic: {
      type: String,
      required: [true, 'CNIC is required'],
      unique: true,
      trim: true,
      match: [/^[0-9]{5}-?[0-9]{7}-?[0-9]$/, 'Invalid CNIC format'],
    },
    cnicVerified: {
      type: Boolean,
      default: false,
    },
    cnicImages: {
      front: String,
      back: String,
    },
    skills: {
      type: [skillSchema],
      required: [true, 'At least one skill is required'],
      validate: {
        validator: function (skills: ISkill[]) {
          return skills.length > 0 && skills.length <= 8;
        },
        message: 'Must have between 1 and 8 skills',
      },
    },
    currentLocation: {
      type: geoPointSchema,
      index: '2dsphere',
    },
    serviceRadius: {
      type: Number,
      default: DEFAULTS.SERVICE_RADIUS_KM,
      min: [1, 'Service radius must be at least 1 km'],
      max: [50, 'Service radius cannot exceed 50 km'],
    },
    availability: {
      isAvailable: {
        type: Boolean,
        default: false,
      },
      schedule: {
        type: [scheduleSchema],
        default: [],
      },
    },
    rating: {
      average: {
        type: Number,
        default: 0,
        min: [0, 'Rating cannot be negative'],
        max: [5, 'Rating cannot exceed 5'],
      },
      count: {
        type: Number,
        default: 0,
        min: [0, 'Rating count cannot be negative'],
      },
    },
    trustScore: {
      type: Number,
      default: DEFAULTS.TRUST_SCORE,
      min: [0, 'Trust score cannot be negative'],
      max: [100, 'Trust score cannot exceed 100'],
    },
    totalJobsCompleted: {
      type: Number,
      default: 0,
      min: [0, 'Total jobs cannot be negative'],
    },
    totalEarnings: {
      type: Number,
      default: 0,
      min: [0, 'Total earnings cannot be negative'],
    },
    bankDetails: {
      accountTitle: String,
      accountNumber: String,
      bankName: String,
    },
    documents: {
      type: [workerDocumentSchema],
      default: [],
    },
    status: {
      type: String,
      enum: WORKER_VERIFICATION_STATUS,
      default: 'PENDING_VERIFICATION',
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret) => {
        const { __v, ...rest } = ret;
        return rest;
      },
    },
    toObject: {
      virtuals: true,
    },
  }
);

// Indexes - Note: user, cnic, and currentLocation indexes are created via schema options
workerSchema.index({ 'skills.category': 1 });
workerSchema.index({ status: 1, 'availability.isAvailable': 1 });
workerSchema.index({ trustScore: -1 });
workerSchema.index({ 'rating.average': -1 });

// Virtual for full name
workerSchema.virtual('fullName').get(function () {
  return `${this.firstName} ${this.lastName}`;
});

/**
 * Method to update worker location
 */
workerSchema.methods.updateLocation = async function (lat: number, lng: number): Promise<IWorker> {
  this.currentLocation = {
    type: 'Point',
    coordinates: [lng, lat], // GeoJSON uses [longitude, latitude]
  };
  return this.save();
};

/**
 * Method to update worker rating
 */
workerSchema.methods.updateRating = async function (newRating: number): Promise<IWorker> {
  const currentTotal = this.rating.average * this.rating.count;
  this.rating.count += 1;
  this.rating.average = (currentTotal + newRating) / this.rating.count;
  return this.save();
};

/**
 * Static method to find worker by user ID
 */
workerSchema.statics.findByUserId = function (
  userId: mongoose.Types.ObjectId | string
): Promise<IWorker | null> {
  return this.findOne({ user: userId }).populate('user', '-password');
};

/**
 * Static method to find worker by CNIC
 */
workerSchema.statics.findByCNIC = function (cnic: string): Promise<IWorker | null> {
  return this.findOne({ cnic });
};

/**
 * Static method to find nearby workers
 */
workerSchema.statics.findNearby = function (
  lat: number,
  lng: number,
  maxDistance: number,
  category?: ServiceCategory
): Promise<IWorker[]> {
  const query: any = {
    currentLocation: {
      $nearSphere: {
        $geometry: {
          type: 'Point',
          coordinates: [lng, lat],
        },
        $maxDistance: maxDistance * 1000, // Convert km to meters
      },
    },
    status: 'ACTIVE',
    'availability.isAvailable': true,
  };

  if (category) {
    query['skills.category'] = category;
  }

  return this.find(query).populate('user', '-password');
};

/**
 * Worker Model
 */
export const Worker = mongoose.model<IWorker, IWorkerModel>('Worker', workerSchema);

export default Worker;
