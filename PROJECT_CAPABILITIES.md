# RealMe: Project Capabilities & Technical Score Card

RealMe is a production-grade, real-time messaging application built with a focus on reliability, clean architecture, and seamless user experience.

## 🚀 Core Features
- **Persistent Biometric-Level Auth**: Integrated Google Authentication that persists sessions across app restarts and device reboots.
- **Real-Time Synchronization**: Firestore-backed messaging with sub-second latency for immediate message delivery and receipt.
- **Hybrid Offline Engine**: Uses Firestore Persistence + Hive-based Outbox to ensure zero message loss even on poor network conditions.
- **Live Presence System**: Real-time user status tracking (Online/Last Seen) integrated with the app's lifecycle.

## 🛠 Technical Excellence
- **Clean Architecture**: Strict separation of concerns (Presentation -> Domain -> Data); zero logic leakage into UI layers.
- **State Management**: Robust implementation using Riverpod for predictable, reactive, and testable state flows.
- **Keyboard-Safe UI**: Production-grade layout handling that manages on-screen keyboard transitions and orientation changes (Adaptive Landscape) without overflows.
- **Stability**: Zero analysis warnings and a clean build pipeline.

## 📈 Scalability & Performance
- **Canonical Chat Protocol**: Scalable 1-on-1 messaging logic using canonical ID generation.
- **Error Resiliency**: User-friendly error boundary system that hides technical failures behind actionable feedback.
