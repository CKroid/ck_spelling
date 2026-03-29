# CK Spelling

A personalized spelling and dictation web application built with Flutter. 

CK Spelling allows users to create custom lists of words or phrases, listen to them dictated via Text-to-Speech (TTS), and test their spelling skills. Perfect for language learners, students, and parents.

## Features

*   **Custom Spelling Lists:** Create, edit, and delete multiple lists of words or phrases.
*   **Multi-language Support:** Currently supports English (`en-US`) and Simplified Chinese (`zh-CN`).
*   **Interactive Dictation Sessions:** 
    *   Automatically shuffles words for randomized testing.
    *   Adjustable TTS speaking speed (0.25x to 1.5x).
    *   Repeat buttons and hidden words during the session.
    *   Final results reveal at the end of the session.
*   **Local Storage:** All data is saved securely in the browser using Hive.
*   **Data Backup:** Export your lists to a `.json` file and import them back anytime, with options to append to or overwrite existing data.

## Getting Started

This project is primarily targeted for Flutter Web.

### Prerequisites
*   Flutter SDK

### Running the App Locally
1. Clone the repository.
2. Run `flutter pub get` to fetch dependencies.
3. Run `flutter run -d chrome` to launch the app in your web browser.
