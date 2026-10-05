-- Create a master key for encryption, using a password for security.
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'give your password';

-- Create a database-scoped credential with a managed identity for authentication.
CREATE DATABASE SCOPED CREDENTIAL cred_kiki
WITH
IDENTITY = 'Managed Identity'

CREATE EXTERNAL DATA SOURCE source_silver
WITH
(
    LOCATION ='https://kikiawstoragelake.blob.core.windows.net/silver',
    CREDENTIAL = cred_kiki
)

CREATE EXTERNAL DATA SOURCE source_gold
WITH
(
    LOCATION ='https://kikiawstoragelake.blob.core.windows.net/gold',
    CREDENTIAL = cred_kiki
)

CREATE EXTERNAL FILE FORMAT format_parquet
WITH
(
    FORMAT_TYPE= PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
)


CREATE EXTERNAL TABLE gold.extsales
WITH
(
    LOCATION = 'extsales',
    DATA_SOURCE = source_gold,
    FILE_FORMAT = format_parquet
)
AS
SELECT * FROM gold.sales

SELECT * from gold.extsales

