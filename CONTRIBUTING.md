# Contributing to Wallet 💳

First off, thank you for taking the time to contribute! It is contributors like you that make this a secure, community-driven tool for everyone.

As a local-first, privacy-focused application, we have specific standards to ensure user data remains safe and the codebase remains maintainable.

---

## 🚀 How Can I Contribute?

### 1. Reporting Bugs
* **Search First:** Check the [Issues](https://github.com/sidhant947/Wallet/issues) tab to see if the bug has already been reported.
* **Be Specific:** Provide a clear title, steps to reproduce, and your environment details (Flutter version, OS, Device).
* **Logs:** If the app crashed, provide the stack trace from your terminal.

### 2. Suggesting Enhancements
* Open an issue titled `[Feature Request] Your Feature Name`.
* **Privacy Check:** Since this app operates **without internet permissions**, any feature request that requires a backend, cloud sync, or external API will likely be declined to maintain the "Offline First" philosophy.

### 3. Pull Requests (PRs)
* **Branching:** Create a feature branch from `main`.
* **Formatting:** Run `flutter format .` before committing.
* **Atomic Commits:** Keep your commits small and descriptive.
* **Update Documentation:** If you add a feature, ensure the README or relevant documentation is updated.

---

## 🛠️ Development Setup

1.  **Prerequisites:** Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2.  **Fork & Clone:**
    ```bash
    git clone [https://github.com/sidhant947/Wallet.git](https://github.com/sidhant947/Wallet.git)
    cd Wallet
    ```
3.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the App:**
    ```bash
    flutter run
    ```

---

## 🎨 Style Guidelines

### Dart & Flutter
* Follow the [Official Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
* Prefer `const` constructors wherever possible to optimize performance.
* Keep UI components modular. If a widget is becoming too large, break it down into smaller, reusable widgets.

### Security Standards
* **No Network Requests:** Do not add dependencies or code that attempt to connect to the internet.
* **Local Storage:** Ensure any sensitive data is handled securely within the local database.
* **Permissions:** Do not add unnecessary Android or iOS permissions to the manifest files.

---

## ⚖️ Code of Conduct
Please be kind and respectful to fellow contributors. We are all here to build something useful!

## 📜 License
By contributing, you agree that your contributions will be licensed under the project's [GPL3 License](LICENSE).
