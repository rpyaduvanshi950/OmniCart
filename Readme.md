# OminiCart

An AI-powered Flutter e-commerce application that allows users to shop using natural language and voice commands.

Instead of manually browsing products, users can simply tell the AI what they want, and the assistant will:

* Understand the request
* Ask follow-up questions when needed
* Search products
* Create the cart automatically
* Assist in checkout
* Track orders

---

# ✨ Features

## 🤖 AI Shopping Assistant

The core feature of the application.

### Natural Language Ordering

Users can type:

> Order a gaming mouse under ₹2000

> Buy groceries for a family of 4 for one week

> Get me a protein powder and shaker bottle

The AI understands:

* Product type
* Budget
* Brand preferences
* Quantity
* Specifications

and automatically searches matching products.

---

## 💬 Clarification Engine

When user instructions are incomplete, the AI asks follow-up questions.

Example:

User:

> Buy shoes

AI:

> Men's or Women's?

User:

> Men's

AI:

> Running, Casual, or Formal?

User:

> Running

AI:

> Added suitable running shoes to your cart.

---

## 🎤 Voice Shopping

Users can order products using voice commands.

Flow:

Voice → Speech-to-Text → AI Processing → Product Search → Cart Creation

Example:

> Order two kilograms of basmati rice

---

## 🧠 Personalized Shopping Memory

The AI remembers:

* Favorite brands
* Preferred sizes
* Previous purchases
* Shopping habits

Example:

User:

> Buy protein powder

AI:

> You previously ordered Optimum Nutrition Whey. Would you like to reorder it?

---

## 🛍️ Smart Cart Builder

The AI can create an entire cart automatically.

Example:

User:

> Build a gaming setup under ₹1 lakh

The AI:

* Selects products
* Optimizes within budget
* Creates the cart
* Requests confirmation

---

## 🔍 AI Product Search

Search products using natural language.

Examples:

> Best laptop for coding under ₹50000

> Gift for my father under ₹1500

> Best phone camera under ₹30000

---

## 📊 AI Product Comparison

Compare products intelligently.

Example:

> Compare iPhone and Samsung flagship phones

Displays:

* Specifications
* Price comparison
* Pros & Cons
* AI Recommendation

---

## ⭐ AI Review Summarization

Instead of reading hundreds of reviews, users receive concise summaries.

Example:

> Most customers liked battery life and camera quality but complained about charging speed.

---

## 🥗 AI Grocery Planner

Generate complete grocery lists.

Example:

> Create groceries for a family of 4 for one week

The AI automatically generates:

* Vegetables
* Dairy products
* Staples
* Snacks
* Household items

---

## 🎁 AI Gift Recommendation

Example:

> Gift for a cricket-loving father under ₹2000

The AI suggests suitable products based on interests and budget.

---

# 🔐 Authentication

Implemented using Firebase Authentication.

### Supported Methods

* Email & Password Login
* Email Verification
* Password Reset
* Google Sign-In
* Guest Mode (Optional)

### Email Verification Flow

```text
Sign Up
   ↓
Firebase Auth
   ↓
Verification Email Sent
   ↓
User Verifies Email
   ↓
Account Activated
```

---

# 👤 User Profile

Users can manage:

* Personal Details
* Saved Addresses
* Wishlist
* Payment Methods
* Order History
* AI Preferences

---

# 🏪 Product Catalog

Supported Categories:

* Electronics
* Fashion
* Grocery
* Beauty
* Books
* Home & Kitchen
* Sports

Each product contains:

* Images
* Description
* Price
* Stock Status
* Ratings
* Reviews
* Variants

---

# ❤️ Wishlist

Users can:

* Save Products
* Receive Price Drop Alerts
* Receive Stock Notifications

---

# 🛒 Cart Management

Features:

* Add / Remove Products
* Quantity Updates
* Save For Later
* AI Bundle Recommendations

Example:

Laptop → Mouse → Keyboard → Headphones

---

# 💳 Checkout System

Supported Payment Methods:

* Razorpay
* Cash On Delivery

AI-Assisted Checkout:

Example:

> Place the order using my home address and UPI

---

# 📦 Order Tracking

Real-Time Order Tracking

Order States:

* Ordered
* Packed
* Shipped
* Out for Delivery
* Delivered

AI Tracking Assistant:

> Where is my order?

AI:

> Your order is out for delivery and expected by 6 PM.

---

# 🔔 Push Notifications

Powered by Firebase Cloud Messaging.

Notifications include:

* Order Updates
* Delivery Status
* Promotions
* Price Drops
* Wishlist Alerts

---

# 👨‍💼 Admin Dashboard

Admin Features:

## Product Management

* Add Products
* Edit Products
* Delete Products
* Manage Inventory

## Order Management

* View Orders
* Update Status
* Process Refunds

## Analytics

* Revenue Tracking
* User Growth
* Product Sales
* Conversion Rates

---

# 🏗️ Tech Stack

| Layer              | Technology               |
| ------------------ | ------------------------ |
| Frontend           | Flutter                  |
| State Management   | Riverpod / Bloc          |
| Backend            | Firebase                 |
| Database           | Firestore                |
| Authentication     | Firebase Auth            |
| Storage            | Firebase Storage         |
| Notifications      | Firebase Cloud Messaging |
| Analytics          | Firebase Analytics       |
| Payments           | Razorpay / Stripe        |
| AI                 | OpenAI GPT / Gemini      |
| Speech Recognition | speech_to_text           |
| Text To Speech     | flutter_tts              |

---

# 📂 Project Structure

```text
lib/
│
├── core/
│   ├── constants/
│   ├── services/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── products/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   ├── wishlist/
│   ├── profile/
│   ├── ai_assistant/
│   └── admin/
│
├── models/
│
├── providers/
│
├── routes/
│
└── main.dart
```

---

# 🔥 Firebase Services Used

## Authentication

* Email Password Login
* Email Verification
* Password Reset

## Firestore Collections

```text
users
products
orders
cart
wishlist
reviews
chat_history
notifications
```

## Storage

* Product Images
* User Images
* Review Images

## Cloud Functions

* AI Workflows
* Email Triggers
* Order Processing

---

# 📡 Product APIs

Development APIs:

* Fake Store API
* DummyJSON Products API

Production Options:

* Shopify Storefront API
* Commerce.js
* Custom Vendor APIs

---

# 🚀 Installation

## Clone Repository

```bash
git clone https://github.com/yourusername/ai-commerce.git
```

## Install Dependencies

```bash
flutter pub get
```

## Firebase Setup

1. Create Firebase Project
2. Enable Authentication
3. Enable Firestore
4. Enable Storage
5. Enable Cloud Messaging
6. Download:

```text
google-services.json
GoogleService-Info.plist
```

7. Add files to Flutter project

---

## Environment Variables

Create a `.env` file:

```env
OPENAI_API_KEY=your_openai_api_key

FIREBASE_API_KEY=your_firebase_api_key

RAZORPAY_KEY=your_razorpay_key

PRODUCT_API_BASE_URL=https://your-api-url.com
```

---

## Run Project

```bash
flutter run
```

---

# 🎯 Future Enhancements

* Multi-Vendor Marketplace
* AI Price Negotiation Agent
* AR Product Visualization
* AI Fashion Stylist
* AI Interior Design Assistant
* Subscription-Based Purchases
* Autonomous Reordering
* Multilingual Shopping Assistant
* Smart Inventory Prediction

---

# 🏆 Why This Project?

Most e-commerce apps require users to browse products manually.

This application transforms shopping into a conversation.

Users simply describe what they need, and the AI handles searching, clarification, cart creation, recommendations, checkout assistance, and order tracking automatically.

The goal is to create an AI Shopping Agent rather than just another e-commerce application.
