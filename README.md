# 🏦 NovaBank Banking Transaction Analysis

An end-to-end banking analytics project focused on understanding **customer retention, engagement, transaction behavior, and portfolio health** for a mid-sized retail bank.

This project analyzes why customer engagement was declining despite growing digital transactions and provides **data-driven business recommendations** to improve activation and retention.

---

## 📌 Business Problem

NovaBank's Chief Customer Officer observed that customer engagement and retention were not improving despite increasing transaction activity.

The goal of this project was to answer:

- Why are customers disengaging?
- Are customers using NovaBank as their primary bank?
- What drives customer retention?
- How can the bank improve activation and long-term engagement?

---

## 📊 Dataset Overview

**Analysis Period:** Jan 2022 – Dec 2023

| Metric | Value |
|--------|-------|
| Customers | 5,000 |
| Accounts | 6,356 |
| Transactions | 297,129 |
| Branches | 10 |

---

## 🛠️ Tools & Technologies

- **SQL** → Data cleaning & validation  
- **Python (Pandas, NumPy, Matplotlib, Seaborn)** → Feature engineering & analysis  
- **Tableau** → Executive dashboards & business storytelling  

---

## 🔍 Key Business Findings

### 🚨 Customer Activation is the Real Problem
- **54.42% of customers never made a single transaction**
- Retention issue is driven by **poor activation**, not loyalty

### 📉 Low Retention
- **Retention Rate: 40.59%**
- Well below retail banking benchmark (**75–85%**)

### 📱 Digital Adoption is Strong
- **85.1% of all transactions are digital**
- Monthly active users grew **84× in 2 years**

### ⚠️ Transaction Reliability Issue
- **16.5% transaction failure rate**
- Far above industry benchmark (**2–3%**)

### 💸 Negative Portfolio Cash Flow
- Total outflow exceeds inflow by **₹2 Crore**

### 👥 Customer Engagement is Weak
- **94.3% customers belong to low engagement segments**
- Only **18 High Value customers** identified using **RFM segmentation**

---

## 📈 Tableau Dashboards

This project includes **5 executive dashboards** built in Tableau:

1. **Executive Overview**  
   Customer health, retention, success rate, and portfolio cash flow

2. **Customer Journey & Engagement**  
   Customer lifecycle, engagement patterns, and MATU growth

3. **Retention & Cohort Analysis**  
   Cohort heatmap and onboarding quality analysis

4. **Transaction & Behavioral Analysis**  
   Transaction trends, payment behavior, and digital adoption

5. **Financial & Account Analysis**  
   Account activity, inflow/outflow patterns, and portfolio health

---

## 🧠 Feature Engineering Highlights

Key features engineered in Python:

- **RFM Segmentation**
- **Customer Lifecycle Stage**
- **Days Since Last Transaction**
- **Balance Trend Analysis**
- **Inflow vs Outflow Ratio**
- **Monthly Active Transaction Users (MATU)**
- **Cohort Retention Analysis**

---

## 📂 Project Structure

```text
NovaBank-Banking-Transaction-Analysis/
│── analysis and feature engineering/
│   ├── .ipynb_checkpoints/
│   ├── analysis.ipynb
│   ├── feature_engineering.ipynb
│   └── cohort_heatmap.png
│
│── dashboards/
│   ├── dashboard screenshots
│   └── Tableau Workbook (.twb)
│
│── datasets/
│   └── raw & cleaned data (.zip)
│
│── reports/
│   ├── Executive Summary.pdf
│   ├── Full Project Report.pdf
│   ├── Recommendations.pdf
│   └── Root Cause Analysis.pdf
│
│── queries/
│   └── SQL Data Cleaning.sql
```

---

## 💡 Business Recommendations

Based on the analysis, the highest-priority recommendations include:

- Improve **first-month customer activation**
- Reduce **transaction failure rate**
- Increase **customer engagement through rewards & auto-pay**
- Cross-sell products to **salary-credit customers**
- Protect **high-value customers**

---

## 🎯 Project Outcome

The analysis revealed that **NovaBank does not primarily have a loyalty problem — it has an activation problem.**

Customers who transact early retain strongly, but most customers never begin using the bank after onboarding.

This project demonstrates how **SQL, Python, and Tableau can be combined to solve a real business problem through analytics and storytelling.**
