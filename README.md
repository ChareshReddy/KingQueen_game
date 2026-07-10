# 👑 King Queen 👑

A premium real-time multiplayer board game built using **Flutter** and **Firebase Firestore**, featuring state management powered by **Riverpod** and sleek, modern dark-themed aesthetics.

Inspired by the classic Indian party game *"Raja Rani Chor Mantri"* (King Queen Minister Thief), modernized with interactive gameplay mechanics, active abilities, global leaderboards, and lifetime statistics.

---

## 🎨 Features & Highlights

*   📡 **Real-Time Multiplayer:** Full live synchronization of game lobbies, player readiness, and game states powered by Firebase Firestore.
*   🎮 **Active Roles & Strategic Gameplay:**
    *   **King (Raja) & Queen (Rani):** Dealt into the game with high point values.
    *   **Guard (Minister/Mantri):** Tasked with identifying the Thief or Assassin to score points.
    *   **Thief (Chor):** Sneaks into the lobby trying to remain undetected by the Guard.
    *   **Assassin (Special Active Role):** Equipped with a deadly active ability to secretly guess another player's role once per round to steal their points.
    *   **Passive Scored Roles:** Spy, Joker, and Commander roles dealt dynamically to keep opponents guessing.
*   ✨ **Vibrant Aesthetics:** Sleek dark-mode interface featuring glassmorphic grids, custom animations (jumping/flying cards), emoji reactions, and premium gold accents.
*   📈 **Global Leaderboard & Lifetime Stats:** Track your wins, total rounds played, high scores, and view the global ranking of all players.

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
*   Firebase project configured for Flutter web/mobile

### Setup Instructions

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ChareshReddy/KingQueen_game.git
    cd KingQueen_game
    ```

2.  **Configure Firebase:**
    Ensure you have setup Firebase using the FlutterFire CLI or placed your configurations in `lib/firebase_options.dart`.

3.  **Fetch dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Run locally (Web):**
    ```bash
    flutter run -d chrome --web-port 8080
    ```

---

## ☁️ Deploying on Render (Free Tier)

This application is fully optimized for **Render's Free Static Site hosting**:

1.  **Build the release package locally:**
    ```bash
    flutter build web --release
    ```
2.  **Commit the build output:**
    ```bash
    git add .gitignore lib/
    git add -f build/web/
    git commit -m "Prepare production web release"
    git push origin Cherry
    ```
3.  **Deploy on Render:**
    *   Create a **New Static Site** on Render.
    *   Select your repository and target the **`Cherry`** branch.
    *   Leave the **Build Command** blank.
    *   Set the **Publish Directory** to `build/web`.
    *   Deploy!

---

## 👥 Credits

*   **Developer:** Cherry 😉
*   **Designer:** Bunny 🙄
