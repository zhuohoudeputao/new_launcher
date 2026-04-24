# Subscription Tracker Provider Implementation

## Overview

The Subscription Tracker provider (`provider_subscription.dart`) manages recurring subscriptions and payments. It helps users track their recurring bills, memberships, and subscriptions with renewal dates and costs.

## Features

- **Subscription tracking**: Add, edit, and delete subscriptions
- **Cost tracking**: Track costs with frequency (weekly, monthly, yearly)
- **Renewal dates**: Set and track renewal dates for each subscription
- **Monthly/yearly totals**: Calculate total monthly and yearly spending
- **Upcoming renewals**: Sort subscriptions by renewal date to show upcoming bills
- **Expired detection**: Identify expired subscriptions for renewal
- **Quick renewal**: Renew expired subscriptions with one tap

## Data Models

### SubscriptionEntry
Stores individual subscription entries:
- `id`: Unique identifier
- `name`: Subscription/service name
- `cost`: Cost per billing cycle
- `frequency`: Billing frequency (weekly, monthly, yearly)
- `renewalDate`: Next renewal/payment date
- `createdAt`: When the subscription was added

## Billing Frequencies

Supported billing frequencies:
- **Weekly**: Bills every week (cost * 4.33 monthly equivalent)
- **Monthly**: Bills every month (cost * 1 monthly equivalent)
- **Yearly**: Bills every year (cost / 12 monthly equivalent)

## Model Properties

### SubscriptionModel
- `isInitialized`: Whether model has been initialized
- `subscriptions`: List of all subscription entries
- `count`: Number of tracked subscriptions
- `totalMonthly`: Total monthly cost across all subscriptions
- `totalYearly`: Total yearly cost across all subscriptions
- `nextRenewal`: The subscription with the nearest renewal date
- `upcomingRenewals`: All subscriptions sorted by renewal date (excluding expired)

## Methods

### SubscriptionModel
- `init()`: Initialize model and load persisted data
- `refresh()`: Refresh state and notify listeners
- `addSubscription()`: Add a new subscription (max 15)
- `updateSubscription()`: Edit existing subscription details
- `deleteSubscription()`: Remove a subscription
- `renewSubscription()`: Extend renewal date for expired subscription
- `clearAll()`: Clear all subscriptions

### SubscriptionEntry
- `daysUntilRenewal()`: Calculate days until next renewal
- `isExpired()`: Check if renewal date has passed
- `monthlyEquivalent()`: Calculate monthly cost equivalent
- `yearlyEquivalent()`: Calculate yearly cost equivalent

## UI Components

### SubscriptionCard
Main widget displaying subscription tracking:
- Header with count indicator
- Monthly and yearly totals display
- Next renewal alert banner
- Subscription list sorted by renewal urgency
- Color-coded urgency indicators (red for 7 days, orange for 30 days)
- Add subscription button
- Clear all button with confirmation

### Add/Edit Dialog
Dialog for adding or editing subscriptions:
- Name input field
- Cost input field with dollar prefix
- Frequency selection (SegmentedButton)
- Renewal date picker
- Delete option for editing existing subscriptions

## Persistence

Data is stored using SharedPreferences:
- `_storageKey`: Subscription entries list
- Maximum 15 subscriptions stored
- Subscriptions sorted by renewal date on load

## Urgency Colors

Subscriptions are color-coded by renewal urgency:
- **Red**: 7 days or less until renewal
- **Orange**: 30 days or less until renewal
- **Green/Teal**: More than 30 days until renewal

## Keywords

`subscription subscribe bill recurring payment netflix spotify membership fee monthly yearly`

## Testing

Tests cover:
- Model initialization
- Add/update/delete subscriptions
- Monthly/yearly total calculations
- Days until renewal calculations
- Expired subscription detection
- Upcoming renewals sorting
- Subscription renewal functionality
- JSON serialization/deserialization
- Widget rendering states
- Provider existence

See `test/widget_test.dart` under "Subscription provider tests" group.

## Test Count Update

With the addition of the Subscription provider:
- Total tests: 1236 (21 new subscription tests)
- Provider count: 46 (Subscription is the 46th provider)