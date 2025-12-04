# OlfactoryArtFHE

An immersive privacy-preserving olfactory art platform that personalizes scent experiences based on encrypted audience physiological and emotional data. Fully Homomorphic Encryption (FHE) ensures sensitive data remains confidential while driving real-time scent generation.

## Project Background

Traditional interactive art installations face challenges when integrating personal data:

- **Privacy Concerns**: Audience physiological and emotional data are sensitive.  
- **Limited Personalization**: Most installations cannot adapt scents or stimuli based on individual responses.  
- **Data Misuse Risk**: Centralized processing of personal data may compromise trust.  
- **Immersive Experience Limitation**: Lack of real-time, individualized control reduces audience engagement.

OlfactoryArtFHE solves these problems by:

- Encrypting audience data end-to-end.  
- Utilizing FHE to compute scent combinations without exposing raw data.  
- Enabling highly personalized and secure multi-sensory experiences.  
- Allowing artists to explore new forms of interactive olfactory expression while maintaining privacy.

## Features

### Core Functionality

- **Encrypted Audience Profiles**: Collect physiological and emotional data securely.  
- **FHE-driven Scent Generation**: Compute personalized scent combinations without decrypting sensitive data.  
- **Interactive Control**: Real-time modulation of olfactory output based on encrypted inputs.  
- **Immersive Experience Dashboard**: Visualize scent patterns and audience engagement metrics anonymously.  
- **Multi-Sensory Integration**: Combine scent with visual or auditory cues for richer experiences.

### Privacy & Anonymity

- **Client-side Encryption**: All audience data encrypted before leaving their device.  
- **FHE Computation**: Enables secure processing and personalization without exposing raw data.  
- **Immutable Records**: Stored data and computed patterns cannot be tampered with.  
- **Anonymous Aggregation**: Artists can analyze audience responses without revealing identities.

## Architecture

### Scent Control Engine

- **FHE Computation Module**: Generates individualized scent outputs from encrypted physiological/emotional inputs.  
- **Real-time Output Controller**: Drives scent dispensers based on FHE results.  
- **Data Logger**: Maintains encrypted records of interactions for analysis and iteration.

### Frontend Application

- **React + TypeScript**: Provides interactive visualization and control dashboard.  
- **Sensor Integration**: Interfaces with audience monitoring devices for encrypted data collection.  
- **Real-time Feedback Visualization**: Display anonymous engagement metrics and scent patterns.  
- **Scenario Simulation**: Test different scent combinations and audience responses securely.

### Backend Infrastructure

- **Encrypted Storage**: Stores encrypted audience data and scent profiles.  
- **FHE Computation Service**: Performs secure computation of scent outputs.  
- **Event Scheduler**: Synchronizes scent release with performance cues.

## Technology Stack

- **FHE Libraries**: For secure computation on encrypted audience inputs.  
- **Node.js + Express**: Backend services and API orchestration.  
- **React 18 + TypeScript**: Frontend interactive dashboard.  
- **WebAssembly (WASM)**: High-performance client-side encryption and processing.  
- **IoT Integration**: Controls scent dispensers and environmental sensors.

## Installation

### Prerequisites

- Node.js 18+  
- npm / yarn / pnpm  
- FHE library installed for computation  
- Compatible scent dispensing hardware  

### Running Locally

1. Clone the repository.  
2. Install dependencies: `npm install`  
3. Start backend: `npm run start:backend`  
4. Start frontend: `npm run start:frontend`  
5. Connect sensors and test encrypted audience interactions.

## Usage Examples

- **Personalized Scent Experience**: Generate scent outputs tailored to encrypted audience inputs.  
- **Artistic Experimentation**: Explore new forms of multi-sensory art without compromising audience privacy.  
- **Feedback Analysis**: Aggregate anonymous audience responses to optimize installations.  
- **Immersive Interaction**: Synchronize scent outputs with music, visuals, or motion cues.

## Security Features

- **Encrypted Data Collection**: Audience data encrypted at source.  
- **Immutable Interaction Logs**: Encrypted records cannot be modified.  
- **FHE Computation**: No sensitive data is exposed during processing.  
- **Anonymous Metrics**: Insights are aggregated without linking to individual identities.

## Roadmap

- **Expanded Multi-Sensory Integration**: Combine scent with haptic feedback and soundscapes.  
- **AI-driven Scent Personalization**: Incorporate predictive models for adaptive olfactory experiences.  
- **Scalable Deployments**: Support multiple installations with real-time encrypted computation.  
- **Enhanced User Feedback Analytics**: Secure audience profiling to optimize art experiences.  
- **Mobile Dashboard**: Allow artists to monitor and control installations remotely.  

## Conclusion

OlfactoryArtFHE creates unique, privacy-preserving olfactory art experiences by combining encryption, real-time computation, and immersive design. Audiences enjoy personalized multi-sensory interactions while their sensitive data remains fully protected.

*Built with ❤️ for secure, innovative, and immersive art.*
