# Final-SafeSpot
Final repository for the fully-functional project SafeSpot

# SafeSpot-CM2
SafeSpot CM is a mobile app (android) designed to enhance personal safety by providing instant emergency alerts for users in danger. The application ensures rapid communication with authorities and trusted contacts, helping to reduce response times and increase overall safety.

# Login Page
The login page has been judge unnecessary for SafeSpot CM since this is supposed to be an app with fast and easy access 
in case of emergency.So it will not be done.

# MVP Structure
Splash screen
Register page
Home (dashboard) page
Maps page
Emergency contact dashboard
Profile page
Settings page

# Splash Screen
Verifies if the user is registered in the database
If yes it redirects user to the home screen
If not redirects user to the register page

# Register page
User name
Phone number
Gender
Blood group
Allergies

# Home Dashboard
Maps screen
Send SOS Button
Quick access to contacts (Emergency contacts)
Profile screen button
Settings screen button

# Emergency Contact Dashboard
Contact list
Add Contact button  /*Fields for contacts name, phone number, cancel button, save button*/
Edit Contact button icon
Delete Contact button icon

# SOS Alert Confirmation Preview 
Countdown timer (5 seconds)
"Are you sure?" message
Confirm SOS
Cancel button

# Live Location Sharing
Current location
Map preview

# Profile
View profile
Edit and Save Profile
Name
Phone number
Blood Group
Gender
Allergies
Medical Notes

# Tech Stack
Core: Flutter
Database: Firebase(spark)
API: Google Maps API, Firebase

# OOP Concepts
Polymorphism (Overiding the method build())
Inheritance (Statleless and Stateful Widgets as well as ThemeProvider, UserProvider, and ChangeNotifier)
Encapsulation (Hiding API implementation details, private field like _isDarkMode, private helper methods)
Abstraction (Mostly at the level of service classes like FirestoreService and SosService)

No abstract class (explicit)

# SOLID Principles Respected
Single Responsibility Principle (each class has a focused role)
Open/Close Principle (classes are separated into extensible services/providers)
Liskov Substitution Principle (ThemeProvider and UserProvider can be used instead of ChangeNotifier)
Interface Segregation Principle (services expose small, focused APIs rather than broad, mixed responsibilities)
Dependency Inversion Principle (MultiProvider injects dependencies rather than creating them inside every widget)

# Design Patterns Used
Observer Pattern (behavioral | notifyListeners triggers UI updates)
Factory method pattern (creational | Map<string> calling UserModel)
Singleton pattern (creational | FirebaseAuth.instance)
Builder pattern
State pattern

# Architecture
MVC-like pattern
Views for the UI
Core (providers, services) for state and data access
Models for data objects

# Software Requirements
Flutter SDK compatible with dart 3.11.5
Android SDK
Android studio
Firebase set-up
Dart packages used

# Hardware Requirements
Device with GPS/location support
SMS capability
WhatsApp installed
Google Play services
At least 8GB RAM
Android Device (8+)