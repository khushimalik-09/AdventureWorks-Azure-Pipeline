# Building an End-to-End Data Engineering Solution with Azure

This project demonstrates an end-to-end data engineering workflow built around the **AdventureWorks dataset**. The solution uses **Azure Data Factory, Azure Data Lake Storage Gen2, Azure Databricks, Azure Synapse Analytics, and Power BI** to move data from ingestion through transformation, serving, and business intelligence reporting.

The implementation follows a **Medallion Architecture**, with data moving through the Bronze, Silver, and Gold layers.

![Project Architecture](screenshots/architecture.jpg)

---

## Architecture Overview

The pipeline is designed as:

**AdventureWorks Dataset → Azure Data Factory → ADLS Gen2 Bronze → Azure Databricks → ADLS Gen2 Silver → Azure Synapse Analytics → Power BI**

The main Azure services used in the solution are:

- **Azure Data Factory (ADF)** – data ingestion and pipeline orchestration
- **Azure Data Lake Storage Gen2 (ADLS Gen2)** – storage for the Bronze and Silver layers
- **Azure Databricks** – PySpark-based data transformation
- **Azure Synapse Analytics** – SQL-based serving and querying of processed data
- **Power BI** – business intelligence reporting and visualization

---

## Step 1: Setting Up the Azure Environment ⚙️

The project uses an Azure-based data engineering environment consisting of Data Factory, Data Lake Storage Gen2, Databricks, and Synapse Analytics.

The AdventureWorks source data is organized as multiple CSV files, including:

- Customers
- Products
- Product Categories
- Product Subcategories
- Calendar
- Returns
- Sales 2015
- Sales 2016
- Sales 2017
- Territories

These datasets form the input for the data pipeline.

### Medallion Architecture

The project separates data processing into three logical layers:

| Layer | Purpose |
|---|---|
| **Bronze** | Stores the ingested source data in its raw CSV form |
| **Silver** | Stores transformed data in Parquet format |
| **Gold** | Provides structured data access for analytics and reporting through Synapse |

---

## Step 2: Implementing the Data Pipeline Using Azure Data Factory 🚀

**Azure Data Factory** is used to orchestrate the ingestion process.

The source AdventureWorks files are made available through the project's source configuration, and ADF is used to move the data into the **Bronze layer of ADLS Gen2**.

### Data Ingestion Flow

The ingestion stage follows this general flow:

1. Identify the required AdventureWorks datasets.
2. Use ADF to ingest the source files.
3. Store the raw CSV data in the **Bronze container**.
4. Keep the source data available for downstream Databricks processing.

The repository contains the exported ADF configuration under:

```text
ADF-Script/
└── git.json
```

The overall ingestion stage is represented in the project architecture below.

![Azure Data Engineering Architecture](screenshots/architecture.jpg)

---

## Step 3: Data Transformation with Azure Databricks 🔄

Once the raw data is available in the Bronze layer, **Azure Databricks** is used for transformation with **PySpark**.

A Databricks cluster was configured for the transformation workload.

![Databricks Cluster](screenshots/databricks-cluster.png)

### Reading Bronze Data

The notebook reads the AdventureWorks CSV datasets from the Bronze container using Spark.

The data is loaded with:

- CSV format
- Header enabled
- Schema inference enabled

The notebook used for this stage is:

```text
NoteBook/
├── Data Transformations(Bronze_to_Silver).ipynb
└── Data Transformations(Bronze_to_Silver).dbc
```

### Transformations Performed

#### Calendar

The Calendar dataset was enhanced by extracting:

- **Month**
- **Year**

Example transformation:

```python
df_cal = df_cal.withColumn(
    'Month', month(col('Date'))
).withColumn(
    'Year', year(col('Date'))
)
```

#### Customers

A new **Fullname** column was created by combining:

- Prefix
- First Name
- Last Name

```python
df_cus = df_cus.withColumn(
    "Fullname",
    concat_ws(" ", col("Prefix"), col("FirstName"), col("LastName"))
)
```

#### Products

The Product SKU and Product Name fields were transformed using string splitting.

```python
df_pro = df_pro.withColumn(
    "ProductSKU", split(col("ProductSKU"), "-")[0]
).withColumn(
    "ProductName", split(col("ProductName"), " ")[0]
)
```

#### Sales

The Sales dataset received several transformations:

- Converted `StockDate` to timestamp
- Replaced `"S"` with `"T"` in `OrderNumber`
- Created a calculated `Multiply` column using `OrderLineItem × OrderQuantity`

```python
df_sales = df_sales.withColumn(
    "StockDate", to_timestamp(col("StockDate"))
).withColumn(
    "OrderNumber", regexp_replace(col("OrderNumber"), "S", "T")
).withColumn(
    "Multiply", col("OrderLineItem") * col("OrderQuantity")
)
```

The transformed datasets are written to the **Silver layer in Parquet format**.

![Databricks Transformations](screenshots/databricks-transformations.png)

### Silver Layer Output

The transformed datasets are written using Spark's Parquet writer with overwrite mode. This provides the structured Silver layer used by the downstream Synapse SQL layer.

---

## Step 4: Data Warehousing with Azure Synapse Analytics 📊

After transformation, **Azure Synapse Analytics** is used as the SQL serving layer for the processed data.

The Synapse implementation uses the Parquet files stored in the Silver layer and exposes them through SQL views and external table functionality.

### Synapse SQL Implementation

The repository contains two SQL scripts:

```text
Synapse SQL Scripts/
├── Create External Table.sql
└── Create Views Gold.sql
```

### Creating the Gold Schema

A `gold` schema is created to organize the serving objects.

```sql
CREATE SCHEMA gold;
```

### Querying Silver Parquet with OPENROWSET()

Synapse uses `OPENROWSET()` to query Parquet data directly from ADLS Gen2.

For example, the project creates a Calendar view over the Silver Parquet data:

```sql
CREATE VIEW gold.calendar
AS
SELECT *
FROM OPENROWSET
(
    BULK '.../silver/AdventureWorks_Calendar/',
    FORMAT = 'PARQUET'
) AS QUER1;
```

Similar Gold views are defined for datasets including:

- Calendar
- Customers
- Products
- Product Categories
- Returns
- Sales
- Product Subcategories
- Territories

![Synapse Gold Views](screenshots/synapse-gold-views.png)

### External Table

The project also includes an external table configuration for the Gold layer.

The SQL script defines:

- Database master key
- Database-scoped credential
- External data sources
- Parquet external file format
- `gold.extsales` external table

The external table is created from the Gold sales data:

```sql
CREATE EXTERNAL TABLE gold.extsales
WITH (
    LOCATION = 'extsales',
    DATA_SOURCE = source_gold,
    FILE_FORMAT = format_parquet
)
AS
SELECT * FROM gold.sales;
```

![Synapse SQL](screenshots/synapse-openrowset.png)

---

## Step 5: Business Intelligence with Power BI 📊

The final stage of the pipeline connects the processed serving layer to **Power BI** for reporting and visualization.

The Power BI report is included in:

```text
PowerBI/
└── AdventureWorks.pbix
```

### Power BI Report

The completed report contains visualizations based on the processed AdventureWorks data.

### 1. Total Customers

A card visual displays the total customer count available in the report.

**Displayed value in the report:** `56.046K`

### 2. Count of OrderNumber by Year

A line chart is used to visualize the count of OrderNumber across the available years in the report.

### 3. Count of CustomerKey by Year

An area chart visualizes the count of CustomerKey across the available year hierarchy.

Together, these visuals provide a reporting layer over the data served through the Gold/Synapse layer.

![Power BI Dashboard](screenshots/powerbi-dashboard.png)

---

## Project Workflow

The complete workflow can be summarized as:

```text
                    AdventureWorks Dataset
                            |
                            v
                 +----------------------+
                 |   Azure Data Factory  |
                 |    Data Ingestion     |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 | ADLS Gen2 - BRONZE   |
                 |     Raw CSV Data     |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 |   Azure Databricks   |
                 |      PySpark         |
                 |   Transformations    |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 | ADLS Gen2 - SILVER   |
                 |   Parquet Data       |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 | Azure Synapse        |
                 | OPENROWSET / Views   |
                 | External Table       |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 |      Power BI        |
                 | Reporting & Visuals  |
                 +----------------------+
```

---

## Repository Structure

```text
AdventureWorks-Azure-Data-Engineering/
│
├── ADF-Script/
│   └── git.json
│
├── Datasets/
│   ├── AdventureWorks_Calendar.csv
│   ├── AdventureWorks_Customers.csv
│   ├── AdventureWorks_Product_Categories.csv
│   ├── AdventureWorks_Product_Subcategories.csv
│   ├── AdventureWorks_Products.csv
│   ├── AdventureWorks_Returns.csv
│   ├── AdventureWorks_Sales_2015.csv
│   ├── AdventureWorks_Sales_2016.csv
│   ├── AdventureWorks_Sales_2017.csv
│   └── AdventureWorks_Territories.csv
│
├── NoteBook/
│   ├── Data Transformations(Bronze_to_Silver).ipynb
│   └── Data Transformations(Bronze_to_Silver).dbc
│
├── PowerBI/
│   └── AdventureWorks.pbix
│
├── Synapse SQL Scripts/
│   ├── Create External Table.sql
│   └── Create Views Gold.sql
│
├── screenshots/
│   ├── architecture.jpg
│   ├── databricks-cluster.png
│   ├── databricks-transformations.png
│   ├── synapse-gold-views.png
│   ├── synapse-openrowset.png
│   └── powerbi-dashboard.png
│
└── README.md
```

---

## Technologies Used

| Technology | Purpose |
|---|---|
| **Azure Data Factory** | Data ingestion and orchestration |
| **Azure Data Lake Storage Gen2** | Bronze and Silver data storage |
| **Azure Databricks** | PySpark-based data transformation |
| **Apache Spark / PySpark** | Distributed data processing |
| **Parquet** | Silver-layer storage format |
| **Azure Synapse Analytics** | SQL serving and analytics |
| **OPENROWSET()** | Querying Parquet data |
| **Power BI** | Business intelligence reporting |
| **GitHub** | Source code and project file management |

---

## Key Takeaways 🌐

This project demonstrates an end-to-end Azure data engineering workflow in which data moves through ingestion, transformation, serving, and reporting stages.

Key areas demonstrated include:

- **Data Ingestion:** Moving source datasets into ADLS Gen2 using Azure Data Factory.
- **Medallion Architecture:** Organizing data into Bronze, Silver, and Gold layers.
- **Data Transformation:** Using PySpark in Azure Databricks to transform AdventureWorks datasets.
- **Column Engineering:** Creating derived fields and transforming date, string, and sales-related columns.
- **Parquet Storage:** Writing transformed datasets in Parquet format for the Silver layer.
- **SQL Data Serving:** Using Synapse `OPENROWSET()` and SQL views over Parquet data.
- **External Tables:** Creating an external serving structure for Gold sales data.
- **Business Intelligence:** Connecting the processed data to Power BI for reporting.

---

## Project Files

The repository includes the complete project artifacts:

- ADF configuration
- AdventureWorks datasets
- Databricks notebook and `.dbc` export
- Synapse SQL scripts
- Power BI report
- Project screenshots
- Documentation

---

## Author

**Khushi Malik**

B.Tech Computer Science & Engineering (Data Science)

---
