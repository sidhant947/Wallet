# Wallet 

[![IzzyOnDroid Yearly Downloads](https://img.shields.io/badge/dynamic/json?url=https://dlstats.izzyondroid.org/iod-stats-collector/stats/basic/yearly/rolling.json&query=$.['com.sidhant.wallet']&label=IzzyOnDroid%20yearly%20downloads)](https://apt.izzysoft.de/packages/com.sidhant.wallet) [![License](https://img.shields.io/github/license/sidhant947/Wallet)](LICENSE) ![Downloads last month](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fgithub.com%2Fkitswas%2Ffdroid-metrics-dashboard%2Fraw%2Frefs%2Fheads%2Fmain%2Fprocessed%2Fmonthly%2Fcom.sidhant.wallet.json&query=%24.total_downloads&logo=fdroid&label=Downloads%20last%20month)

**Wallet** is a privacy-first, zero-knowledge card management application. It empowers you to store credit, debit, loyalty, and identity cards locally with military-grade encryption and **absolute zero internet access**.

---

## 📥 Download

Stay secure on your favorite platform. Secure Wallet is available on several privacy-respecting and official stores:

<div align="center">

| **Play Store** | **IzzyOnDroid** | **F-Droid** |
| :---: | :---: | :---: |
| <a href="https://play.google.com/store/apps/details?id=com.sidhant.wallet"><img src="https://github.com/user-attachments/assets/5ff479ee-9c86-47fd-a583-2a4f8f10633e" height="60"></a> | <a href="https://apt.izzysoft.de/packages/com.sidhant.wallet"><img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" height="60"></a> | <a href="https://f-droid.org/packages/com.sidhant.wallet"><img src="https://f-droid.org/badge/get-it-on.png" height="60"></a> |

[**Download Latest APK**](https://github.com/sidhant947/Wallet/releases/latest)

</div>

---

## ✨ Key Features

*   🚫 **Zero Internet Access**: The app does not request the `INTERNET` permission. Your data is physically impossible to leak online.
*   🛡️ **Military-Grade Encryption**: All sensitive fields, custom data, and card images are encrypted using **AES-256-GCM**.
*   🔐 **Biometric Security**: Protect your vault with fingerprint or face unlock using platform-native security.
*   🎨 **Liquid Glass UI**: A premium, modern design featuring smooth glassmorphism, staggered animations, and dynamic transitions.
*   📲 **Apple Wallet Support**: Import `.pkpass` files directly into your local vault.
*   🔄 **Secure E2EE Sharing**: Share cards via encrypted QR codes. Data is decrypted only by the receiving app instance.
*   💾 **Encrypted Backups**: Export your entire vault into a `.wbk` file secured with **PBKDF2-HMAC-SHA256** key derivation.
*   📸 **Encrypted Image Vault**: Store front/back photos of cards; images are encrypted on disk and decrypted directly into memory.
*   🌓 **True OLED Dark Mode**: Optimized for battery saving and premium aesthetics.

---

## 🛠️ Technical Implementation

- **Encryption**: AES-256-GCM (Galois/Counter Mode) for authenticated encryption.
- **Key Storage**: Master keys are stored in the **Android Keystore** / **iOS Keychain**.
- **Key Derivation**: Backups use **PBKDF2** with **100,000 iterations** to protect against brute-force attacks.
- **Privacy**: Implements `FLAG_SECURE` to prevent screenshots and screen recording of sensitive information.
- **Framework**: Built with **Flutter** for high-performance rendering and a native feel.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

Check our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

## 📄 License

This project is licensed under the terms of the **GPL License**. See [LICENSE](LICENSE) for more details.
