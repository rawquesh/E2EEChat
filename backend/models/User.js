const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
    },
    firstName: {
      type: String,
      default: '',
    },
    lastName: {
      type: String,
      default: '',
    },
    displayName: {
      type: String,
      default: '',
    },
    mobileNumber: {
      type: String,
      default: '',
    },
    notificationToken: {
      type: String,
      default: '',
    },
    profilePicture: {
      type: String,
      default: '',
    },
    profileCover: {
      type: String,
      default: '',
    },
    gender: {
      type: String,
      default: '',
    },
    authenticationMode: {
      type: String,
      default: 'email',
    },
    age: {
      type: Number,
      default: 0,
    },
    enabled: {
      type: Boolean,
      default: true,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
    country: {
      type: String,
      default: '',
    },
    publicKey: {
      type: String,
      default: '',
    },
    // Creator fields (kept from original model)
    preferredContentGender: {
      type: String,
      default: '',
    },
    isCreator: {
      type: Boolean,
      default: false,
    },
    creatorUsername: {
      type: String,
      default: '',
    },
    contentVisibleTo: {
      type: String,
      default: '',
    },
    creatorCategory: {
      type: String,
      default: '',
    },
    creatorHeadline: {
      type: String,
      default: '',
    },
    creatorStatus: {
      type: String,
      default: '',
    },
    hasCompletedStripeOnboarding: {
      type: Boolean,
      default: false,
    },
    bio: {
      type: String,
      default: '',
    },
    introVideoUrl: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster lookups
userSchema.index({ email: 1 });
userSchema.index({ 'profilePicture': 1 });

const User = mongoose.model('User', userSchema);

module.exports = User;
