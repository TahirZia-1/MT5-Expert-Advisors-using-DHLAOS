# MT5 Expert Advisors using DHLAOS Strategy

This repository contains modified MetaTrader 5 (MT5) Expert Advisors (EAs) based on the **DHLAOS** strategy. The original implementation was sourced from the [geraked/metatrader5](https://github.com/geraked/metatrader5) public repository.

## 🚀 Overview

The primary focus of this project is to provide a reliable version of the **DHLAOS strategy** (which uses Daily High/Low and Andean Oscillator indicators for scalping). 

While the original bots are great, many traders encounter "unsupported filling mode" errors when running them on certain brokers. **This repository includes crucial fixes for order filling problems**, ensuring the EAs run smoothly on **Pepperstone demo accounts** and other brokers with strict execution policies.

## 🤖 Latest Working Bot

The most up-to-date and fully functional version of the EA, optimized and fixed for Pepperstone, can be found here:

- **Source Code**: [`DHLAOSdeepseek(1).mq5`](https://github.com/TahirZia-1/MT5-Expert-Advisors-using-DHLAOS/blob/master/MQL5/Experts/DHLAOSdeepseek(1).mq5)
- **Compiled Bot**: [`DHLAOSdeepseek(1).ex5`](https://github.com/TahirZia-1/MT5-Expert-Advisors-using-DHLAOS/blob/master/MQL5/Experts/DHLAOSdeepseek(1).ex5)

## 📈 Strategy Details: DHLAOS

**DHLAOS** is a scalping strategy that utilizes two main technical indicators:
1. **Daily High/Low (DHL)**: Identifies key daily support and resistance levels.
2. **Andean Oscillator (AOS)**: Measures trend direction and momentum to identify potential entry and exit points.

By combining these two, the strategy aims to capture short-term price movements effectively.

## 🛠️ Key Fixes & Improvements

- **Order Filling Modes Fixed**: Addressed `ORDER_FILLING_FOK`, `ORDER_FILLING_IOC`, and `ORDER_FILLING_RETURN` issues that previously prevented trades from executing on certain brokers.
- **Broker Compatibility**: Verified and tested to work out-of-the-box on **Pepperstone** demo accounts.

## 📥 Installation

1. Download the latest `.ex5` and `.mq5` files from the links above.
2. Open MetaTrader 5.
3. Go to `File` -> `Open Data Folder`.
4. Navigate to `MQL5/Experts` and paste the downloaded files.
5. Refresh the Expert Advisors list in the Navigator panel or restart MT5.
6. Drag and drop the EA onto your desired chart.
7. Ensure "Allow Algo Trading" is enabled in both the EA settings and the main MT5 toolbar.

## 🏆 Credits

A massive thank you to the original author **[Geraked](https://github.com/geraked)** for providing the foundational open-source trading bots. Check out their [original repository](https://github.com/geraked/metatrader5) for more MT5 strategies.

## 🚨 Disclaimer

**USE AT YOUR OWN RISK**: Trading financial instruments involves a high level of risk, and there are no guarantees of profit. Markets are highly volatile, and past performance is not indicative of future results.

**Not Financial Advice**: The EAs and strategies presented in this repository do not constitute financial advice. Conduct your own research and backtesting before making any trading decisions. You assume full responsibility for your trading activities.
