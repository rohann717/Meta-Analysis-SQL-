# Instagram User Analysis for Marketing Strategy

![Project Status](https://img.shields.io/badge/status-completed-green)
![Project Score](https://img.shields.io/badge/score-9/10-brightgreen)
![SQL](https://img.shields.io/badge/SQL-MySQL-blue)
![Tools](https://img.shields.io/badge/Tools-Gamma_AI-orange)



This repository contains the complete SQL analysis project focused on leveraging a cloned Instagram database to derive actionable insights for a marketing team. The project aims to develop data-driven strategies to boost user engagement, retention, and acquisition.



---



\## 📂 Repository Structure

.

├── Instagram\_Analysis\_Report.pdf

├── Instagram\_Analysis\_Presentation.pdf

├── SQL\_Queries/

│ ├── 01\_Objective\_Questions.sql

│ └── 02\_Subjective\_Questions\_Support.sql

├── database\_schema/

│ └── schema\_diagram.png

└── README.md




\## 📝 Project Overview



\### 1. Context

The project simulates a real-world scenario where a data analyst collaborates with the Meta Marketing team. The core task is to analyze user behavior data from an Instagram-like platform to address key business objectives.



\### 2. Objectives

The primary goals of the analysis are to provide data-backed recommendations that help:

\-   \*\*Increase User Engagement:\*\* Identify what drives user interactions (likes, comments, posts).

\-   \*\*Increase User Retention:\*\* Understand characteristics of loyal users and identify inactive users for re-engagement.

\-   \*\*Increase User Acquisition:\*\* Provide insights that can inform strategies to attract and activate new users, focusing on influencer and community analysis.



\### 3. Database Schema

The analysis was performed on a relational database consisting of 7 interconnected tables: `users`, `photos`, `likes`, `comments`, `follows`, `tags`, and the `photo\_tags` junction table.



!\[Database ERD](database\_schema/schema\_diagram.png)



---



\## 🛠️ Technical Skills \& Tools



\*   \*\*Language:\*\* SQL (MySQL dialect)

\*   \*\*Key SQL Concepts:\*\*

&nbsp;   \*   Joins (`INNER`, `LEFT`)

&nbsp;   \*   Common Table Expressions (CTEs)

&nbsp;   \*   Subqueries (Correlated and Uncorrelated)

&nbsp;   \*   Window Functions (`RANK()`)

&nbsp;   \*   Aggregate Functions (`COUNT`, `AVG`, `SUM`, `MIN`, `MAX`)

&nbsp;   \*   Data Grouping \& Filtering (`GROUP BY`, `HAVING`)

&nbsp;   \*   Data Manipulation (`UPDATE` - discussed hypothetically)

\*   \*\*Tools:\*\* MySQL Workbench (or your SQL client), Gamma AI (for presentation), Git \& GitHub.



---



\## 📊 Key Findings \& Insights



The analysis yielded several key insights:



1\.  \*\*Skewed User Activity:\*\* A small group of "power users" generates a disproportionately high volume of content and engagement, making them a high-value segment.

2\.  \*\*High-Performance Content:\*\* Specific content themes, identified via hashtags (e.g., `#smile`, `#beach`), consistently receive higher-than-average engagement.

3\.  \*\*Key User Identification:\*\* A data-driven approach was developed to identify potential brand ambassadors and influencers by combining metrics for both audience reach (followers) and audience engagement (likes/comments received).

4\.  \*\*Inactive User Segment:\*\* A significant number of users with zero recorded activity were identified, representing a clear target for re-engagement campaigns.

5\.  \*\*Peak Activity Times:\*\* Analysis of timestamps revealed optimal windows for posting content and scheduling ad campaigns to maximize visibility.



---



\## 🚀 Strategic Recommendations



Based on the findings, the following high-level strategies were proposed:

\*   \*\*Engagement:\*\* Launch campaigns and curate content feeds around high-performing hashtag themes.

\*   \*\*Retention:\*\* Implement a brand ambassador program to reward top users and launch personalized re-engagement campaigns for inactive users.

\*   \*\*Acquisition/Growth:\*\* Partner with identified influencers who have both high reach and high engagement rates for marketing initiatives.



---



\## 💡 How to Use This Repository



1\.  \*\*Database Setup:\*\* The SQL scripts assume you have a MySQL server running and have created a database (e.g., `ig\_clone`). You will need to load the provided data first.

2\.  \*\*Run SQL Queries:\*\* The SQL files in the `SQL\_Queries/` directory contain all the queries used for the analysis, with comments explaining each step.

3\.  \*\*Review Findings:\*\* The `Instagram\_Analysis\_Report.pdf` and `Instagram\_Analysis\_Presentation.pdf` files provide a comprehensive overview of the project's findings and strategic recommendations.

