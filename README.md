<div align="center">

<img src="assets/images/nutrinutri.svg" width="120" height="120" alt="NutriNutri logo" />

# [NutriNutri](http://nutrinutri.popelis.sk/)

**Your Personal AI Nutritionist.**
_Simple. Private. Open Source. Not-for-profit._

[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Built with Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev/)
[![Website](https://img.shields.io/badge/Website-nutrinutri.popelis.sk-2EA043)](http://nutrinutri.popelis.sk/)

</div>

---

## About this version

This is my fork of [NutriNutri](https://github.com/riki137/nutrinutri), an open-source AI nutrition tracker. I added Gemini (Google AI Studio, free tier) as an AI provider and built the features below on top of the original app.

### What I added

- **Gemini provider**: use a free Google AI Studio key, with an optional backup key that is tried automatically if the main key fails.
- **Better AI entries**: several photos per meal, the AI's reasoning for each estimate, follow-up corrections, and Run Again.
- **AI review queue**: flag entries where the AI got it wrong, then export the prompt, images and AI chat as a ZIP to check them.
- **Prompt changes**: Indian meals, portion uncertainty, and the device's region.
- **More tracking**: minerals, PUFA, vitamin A, nutrient ratios (potassium:sodium, calcium:phosphorus, zinc:copper), and temperature logging.
- **Export and backup**: daily totals to Excel, CSV import and export, and ZIP backup and restore with an integrity check.

### Install

- **Android**: install the APK I share, or build one yourself with `flutter build apk --release`.
- **iPhone**: not available; distributing it would need TestFlight.

---

[**NutriNutri**](http://nutrinutri.popelis.sk/) makes nutrition tracking feel effortless. Snap a photo of your meal (or just type what you ate in plain English) and let the AI handle the rest: ingredients, portions, calories, macros, all logged in seconds.

No endless food databases. No barcode hunting. No subscriptions. Just a tool that gets out of your way so you can focus on actually eating well.

> Health tools should be accessible to everyone and should respect your privacy. That's why NutriNutri is **non-profit**, **open source (GPLv3)**, and **privacy-first** — by design, not by marketing.

## ✨ What's inside

- **📸 AI Auto-Logging** Photograph your plate or describe your meal. The AI breaks it down into ingredients, estimates portions, and logs everything for you.
- **AI Reasoning** See the user-facing calculation basis behind each AI estimate: detected food, portion assumptions, visible ingredients, and why the calories/macros make sense.
- **Run Again** Re-run AI analysis on an existing food entry when you want a fresh estimate from the latest prompt, images, model, or settings.
- **AI Follow-Up Corrections** Chat with the AI again on an existing entry to add corrections, clarify portions, or refine the nutrition result without starting over.
- **Mark for AI Review** Flag entries that need a second look, then clear the review list once you've checked them.
- **🥗 Full Nutrition Picture** Calories, protein, carbs, fats, fiber, sodium, caffeine, water, and more. Track what matters to *you*.
- **🏃 Activity Tracking** Log workouts and see calories burned alongside what you've eaten.
- **🔒 Privacy-First** Your health data is yours. No analytics, no tracking, no selling - ever.
- **📱 Runs Everywhere** Web, Android, Linux, macOS, and Windows. One app, every device.
- **💸 Free Forever** Bring your own key: [Gemini](https://aistudio.google.com/app/apikey) (free tier from Google AI Studio) or [OpenRouter](https://openrouter.ai/), and pay only for what you use. No middlemen, no markup.
- **❤️ Non-Profit & Open Source** Built in the open under GPLv3. No VC money, no dark patterns, no growth hacks.

## 🏁 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- An API key for the AI features: [Gemini](https://aistudio.google.com/app/apikey) (free tier) or [OpenRouter](https://openrouter.ai/settings/keys)

### Run it locally

```bash
git clone https://github.com/yaswanth-jogireddy/nutrilens.git
cd nutrilens
flutter pub get
flutter run
```

### First-time setup

1. Open the app
2. In onboarding or **Settings**, set **AI Provider** to **Gemini** (or OpenRouter)
3. Paste your **Gemini API Key**, and optionally a backup key

That's it, you're ready to log your first meal.

## 🚀 Roadmap

- [x] Activity tracking with calorie burn
- [x] Extended metrics (fiber, sodium, caffeine, water…)
- [x] AI reasoning explanations for food estimates
- [x] Re-run and follow-up correction flow for AI-generated entries
- [x] Mark entries for AI review
- [ ] **UX polish** — repeated meals, quick stats, smoother flows
- [ ] **Charts & trends** — weekly and monthly insights into your intake
- [ ] **Recipe Builder** — AI-generated recipes tailored to your preferences, saved to your diary

Have an idea? [Open an issue](https://github.com/yaswanth-jogireddy/nutrilens/issues). I'd love to hear it.

## 🛠️ Built With

- [**Flutter**](https://flutter.dev/) one codebase, every platform.
- [**Gemini**](https://ai.google.dev/) through Google AI Studio, including the free tier.
- [**OpenRouter**](https://openrouter.ai/) flexible access to the best models, on your terms.

## 🤝 Contributing

Pull requests, bug reports, and ideas are all welcome. This project belongs to everyone who wants better nutrition tools — that probably includes you.

## 📄 License

Released under the **GNU General Public License v3.0** — see [LICENSE](LICENSE) for the details.

In short: fork it, modify it, share it. Just keep it open, and please give credit where it's due.

---

<div align="center">

_Made with ❤️ for a healthier world._

[nutrinutri.popelis.sk](http://nutrinutri.popelis.sk/)

</div>
