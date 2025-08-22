# Smart Building Systems and IoT Integration

A comprehensive blockchain-based system for managing smart building operations, IoT sensor networks, and facility management using Clarity smart contracts.

## Overview

This system provides a decentralized platform for:
- **Sensor Management**: Deploy and coordinate IoT sensors throughout buildings
- **Performance Tracking**: Monitor building energy efficiency and operational metrics
- **Maintenance Scheduling**: Transparent scheduling and cost allocation for building maintenance
- **Predictive Analytics**: Enable data-driven maintenance and system optimization
- **Tenant Services**: Coordinate facility management and tenant interactions

## Architecture

The system consists of five interconnected smart contracts:

### 1. Sensor Registry (`sensor-registry.clar`)
- Manages IoT sensor deployment and registration
- Tracks sensor locations, types, and operational status
- Handles sensor data validation and access control

### 2. Building Performance (`building-performance.clar`)
- Monitors energy consumption and efficiency metrics
- Tracks environmental conditions and system performance
- Provides performance analytics and reporting

### 3. Maintenance Scheduler (`maintenance-scheduler.clar`)
- Manages maintenance task scheduling and assignments
- Handles cost allocation and payment tracking
- Provides transparent maintenance history

### 4. Predictive Analytics (`predictive-analytics.clar`)
- Processes sensor data for predictive insights
- Identifies maintenance needs and system optimization opportunities
- Manages alert systems and notifications

### 5. Tenant Services (`tenant-services.clar`)
- Coordinates tenant requests and facility management
- Manages service agreements and billing
- Provides tenant dashboard and communication tools

## Key Features

- **Decentralized Governance**: Transparent decision-making for building operations
- **Real-time Monitoring**: Continuous tracking of building systems and performance
- **Cost Transparency**: Clear allocation of maintenance and operational costs
- **Predictive Maintenance**: Data-driven maintenance scheduling to prevent failures
- **Energy Optimization**: Automated systems for reducing energy consumption
- **Tenant Engagement**: Direct communication and service request capabilities

## Getting Started

1. Install dependencies: `npm install`
2. Run tests: `npm test`
3. Deploy contracts using Clarinet: `clarinet deploy`

## Testing

The project includes comprehensive tests using Vitest to ensure contract functionality and security.

## Contract Interactions

All contracts are designed to work independently without cross-contract calls, ensuring modularity and security while maintaining system coherence through shared data patterns.
