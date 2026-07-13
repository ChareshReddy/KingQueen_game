# 👑 KING QUEEN 👑

A premium real-time multiplayer party game built using **Flutter Web** and **Firebase Firestore**, featuring state management powered by **Riverpod** and sleek, modern dark-themed aesthetics.

Inspired by the classic Indian party game *"Raja Rani Chor Mantri"* (King Queen Minister Thief), modernized with a dynamic scale-to-play guessing sequence, deception mechanics, global leaderboards, and a complete match-end scoreboard.

---

## 🎨 Features & Highlights

*   📡 **Real-Time Multiplayer:** Full live synchronization of lobbies, player readiness, and game states powered by Firebase Firestore transactions.
*   🎮 **Dynamic Guessing Chain:** 
    *   Lobby roles automatically scale according to the player count.
    *   Active roles are ranked by points (descending): **King (1000) ➔ Queen (900) ➔ Minister (800) ➔ Spy (700) ➔ Joker (600) ➔ Guard (500) ➔ Fake Queen (400) ➔ Assassin (300) ➔ Commander (200) ➔ Thief (0)**.
    *   Play proceeds down this chain, with each role holder tasked with guessing the identity of the player holding the next role down the list.
    *   If a guess is incorrect, roles are swapped with the wrongly accused player and the new role-holder retries.
    *   The Thief is always the final target at the end of the chain, who never gets a turn to guess.
*   🎭 **Special Role Mechanics:**
    *   **Fake Queen:** If guessed incorrectly, she successfully misleads the guesser, scoring a **+600 points** deception bonus, and no role swap occurs.
*   🏆 **Match End & Game Over:**
    *   The host can conclude the match at any point on the round-reveal screen.
    *   A full Game Over scoreboard displays the final standings of all players sorted by their match points, crowning the overall champion.
    *   Lifetime wins and total scores are securely synchronized to user profiles.
*   ✨ **Vibrant Aesthetics:** Sleek dark-mode interface featuring glassmorphic grids, custom animations (flying cards), emoji reactions, and premium gold accents.

---

## 🛠️ Technology Stack

*   **Frontend Framework:** [Flutter Web / Mobile](https://flutter.dev)
*   **State Management:** [Riverpod](https://riverpod.dev)
*   **Database & Auth:** [Firebase Firestore](https://firebase.google.com/docs/firestore) & [Firebase Authentication](https://firebase.google.com/docs/auth)
*   **Animations:** `flutter_animate` & custom shaders

---

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (stable channel)
*   Firebase CLI installed and logged in
*   Firebase project configured for web

### Setup Instructions

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ChareshReddy/KingQueen_game.git
    cd KingQueen_game
    ```

2.  **Fetch dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run locally:**
    ```bash
    flutter run -d chrome
    ```

---

## ☁️ Deploying on Render (Free Tier)

This application is fully optimized for **Render's Free Static Site hosting**:

### Setup Render Build Pipeline (Recommended)
Configure your Render Static Site to build from source automatically:
*   **Build Command**: `flutter build web --release`
*   **Publish Directory**: `build/web`

---

## 👥 Credits

*   **Developer:** Cherry 😉
*   **Designer:** Bunny 🙄
*   **License**: MIT License
