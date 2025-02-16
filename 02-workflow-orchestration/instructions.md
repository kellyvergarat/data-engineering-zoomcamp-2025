# Workflow Orchestration

Notes credits to https://github.com/ManuelGuerra1987/data-engineering-zoomcamp-notes/blob/main/2_Workflow-Orchestration-(Kestra)/README.md?plain=1

### Table of contents

- [0. Module 1 recap](#0-module-1-recap)
- [1. Conceptual Material: Introduction to Orchestration and Kestra](#1-conceptual-material-introduction-to-orchestration-and-kestra)
  - [Introduction to Workflow Orchestration](#introduction-to-workflow-orchestration)
  - [Introduction to Kestra](#introduction-to-kestra)
  - [Getting started pipeline](#getting-started-pipeline)
  - [Launch Kestra using Docker Compose](#launch-kestra-using-docker-compose)
- [2. Hands-On Coding Project: Build Data Pipelines with Kestra](#2-hands-on-coding-project-build-data-pipelines-with-kestra)
  - [Load Data to Local Postgres](#load-data-to-local-postgres)
  - [Load Data to Local Postgres with backfill](#load-data-to-local-postgres-with-backfill)
  - [Load Data to GCP](#load-data-to-gcp)
  - [Load Data to GCP with backfill](#load-data-to-gcp-with-backfill)



# 0. Module 1 recap

_([Video source](https://www.youtube.com/watch?v=0yK7LXwYeD0))_

In the previous module we created a script that:

- Downloads a file and unzips it.
- Saves it locally as a CSV file.
- Loads and inserts the data into a PostgreSQL database.

This is what our "pipeline" looked like:

![pipeline1new](images/pipeline1new.jpg)


The script we created is an example of how **NOT** to create a pipeline, because it contains two steps that could be separated (downloading and inserting data). 

**Problems with the current pipeline:**

- If data download succeeds but insertion fails due to a database connection issue, the script needs to restart, including re-downloading the data.
- if we're simply testing the script, it will have to download the CSV file every single time that we run the script.
- Adding retry mechanisms and fail-safe logic for each stage becomes cumbersome.


**Improved pipeline structure**

To address these problems, we can split the script into two distinct steps or tasks:

![pipeline1modnew](images/pipeline1modnew.jpg)

This structure has dependencies between tasks, where one task's output is the next task's input and Task 2 is only performed if task 1 was executed successfully. 

*This is where the need for orchestrators arises*. Workflow orchestration tools help define, parameterize, and manage workflows. These tools provide:

- Ensuring tasks are executed in the right sequence or simultaneously, based on predefined rules or dependencies
- Retry mechanisms.
- Logging and execution history.
- Scheduling and monitoring.


This week we will work on a slightly more complex pipeline. This will involve extracting data from the web. Convert this CSV to a more effective format - parquet. We'll take this file and upload to Google Cloud Storage (data lake). Finally we'll create an external table in Google BigQuery(data warehouse):


![pipeline2new](images/pipeline2new.jpg)  


**Data Lake:**

- Purpose: Stores raw, unprocessed data from various sources, often for exploratory or advanced analytics.
- Data Format: Stores data in its original format (structured, semi-structured, or unstructured).
- Tools: Google Cloud Storage, Amazon S3, or Azure Data Lake.

**Data Warehouse:**

- Purpose: Stores structured and cleaned data optimized for querying and reporting.
- Data Format: Stores structured and pre-processed data.
- Performance: Optimized for complex SQL queries and business intelligence (BI) tools.
- Tools: Google BigQuery, Snowflake, Amazon Redshift or Microsoft Azure Synapse.



# 1. Conceptual Material: Introduction to Orchestration and Kestra

## Introduction to Workflow Orchestration

_([Video source](https://www.youtube.com/watch?v=ZV6CPZDiJFA))_

Think of an orchestrator a bit like an orchestra where an orchestra has multiple different instruments and they all need to come together in unison. Now, instead of those instruments, think of those as maybe tasks, different pipelines, microservices, etc. That's where an orchestrator comes in to tie all of those together and make sure they can work in unison. 

You probably also wondering: what's the difference between orchestration and automation? They are very similar, but orchestration is all about the bigger picture. For example, maybe you have multiple tasks running, and maybe they depend on one another. So you can make sure that certain tasks only run when other tasks are finished. If there are any errors, it can cancel other tasks, especially let you know about those as well. While automation is fantastic for scheduling singular tasks, orchestration is where you tie all of that together to make one great system.

Workflow Orchestration refers to the process of organizing, managing, and automating complex workflows, where multiple tasks or processes are coordinated to achieve a specific outcome. It involves ensuring that tasks are executed in the correct order, handling dependencies between them, and managing resources or systems involved in the workflow.


- Task Coordination: Ensuring tasks are executed in the right sequence or simultaneously, based on predefined rules or dependencies.

- Automation: Automating repetitive or complex processes to reduce manual intervention.

- Error Handling: Managing errors or failures in tasks, often with retry mechanisms or alternative execution paths.

- Resource Management: Allocating resources (e.g., computing power, APIs, or data) to tasks as needed.

- Monitoring and Reporting: Tracking the progress of workflows, identifying bottlenecks, and providing logs or reports for analysis.


Now let's discuss a few common use cases for orchestrators so you can understand when you might want to use one in your scenario.

**Data-driven environments**

Orchestrators are key for being able to allow extract, transform, and load tasks, making sure you can load them from a variety of different sources as well as load those into a data warehouse. An orchestrator can make sure that each of these steps can happen successfully. If there are any errors, it can both retry steps as well as make sure that later steps do not happen.

![kestra1](images/kestra1.jpg)


**CI/CD pipelines**

In CI/CD pipelines, they can be super useful for being able to build, test, and publish your code to various different places at the same time and manage all of the different steps there to make sure they happen in unison.

![kestra2](images/kestra2.jpg)


**Provision Resources**

If your infrastructure is cloud-based, you can use your orchestrator to help provision resources too, allowing you to just press a button, and it will set up your cloud environment for you.


## Introduction to Kestra

_([Video source](https://www.youtube.com/watch?v=Np6QmmcgLCs))_

Kestra is an orchestration platform that’s highly flexible and well-equipped to manage all types of pipelines  Kestra provides a user-friendly interface and a YAML-based configuration format, making it easy to define, monitor, and manage workflows.

Kestra gives you the flexibility on how you control your workflows and gives you the option to do it in no code low code or full code.

Run the following command to start up your instance (bash/ubuntu wsl terminal):

```
docker run --pull=always --rm -it -p 8080:8080 --user=root \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp:/tmp kestra/kestra:latest server local
```

First-time build can take up to 10 mins.

Head over to your browser and open https://localhost:8080 to launch the interface

![kestra3](images/kestra3.jpg)


**Properties**

Workflows are referenced as Flows and they are declared using YAML. Within each flow, there are 3 required properties you’ll need:

- id: which is the name of your flow. 

- Namespace: which allows you to specify the environments you want your flow to execute in, e.g. production vs development.

- Tasks: which is a list of the tasks that will execute when the flow is executed, in the order they’re defined in. Tasks contain an id as well as a type with each different type having their own additional properties.

**Optional Properties**

- Inputs: Instead of hardcoding values into your flows, you can set them as constant values separately. Great if you plan to reuse them in multiple tasks. 

- Outputs: Tasks will often generate outputs that you’ll want to pass on to a later task. Outputs let you connect both variables as well as files to later tasks. 

- Triggers: Instead of manually executing your flow, you can setup triggers to execute it based on a set of conditions such as time schedule or a webhook.


## Getting started pipeline

_([Video source](https://www.youtube.com/watch?v=Np6QmmcgLCs))_


Flow: [`01_getting_started_data_pipeline.yaml`](flows/01_getting_started_data_pipeline.yaml)

This introductory flow is added just to demonstrate a simple data pipeline which extracts data via
 HTTP REST API, transforms that data in Python and then queries it using DuckDB.

Is going to run an extract task, a transform task, and a query task:

![pipeline0](images/pipeline0.jpg) 

**Declaring the flow**

Click on Create my first flow. Flows are declared using YAML. This YAML file describes a Kestra workflow configuration: 

```yaml

id: 01_getting_started_data_pipeline
namespace: zoomcamp

inputs:
  - id: columns_to_keep
    type: ARRAY
    itemType: STRING
    defaults:
      - brand
      - price

tasks:
  - id: extract
    type: io.kestra.plugin.core.http.Download
    uri: https://dummyjson.com/products

  - id: transform
    type: io.kestra.plugin.scripts.python.Script
    containerImage: python:3.11-alpine
    inputFiles:
      data.json: "{{outputs.extract.uri}}"
    outputFiles:
      - "*.json"
    env:
      COLUMNS_TO_KEEP: "{{inputs.columns_to_keep}}"
    script: |
      import json
      import os

      columns_to_keep_str = os.getenv("COLUMNS_TO_KEEP")
      columns_to_keep = json.loads(columns_to_keep_str)

      with open("data.json", "r") as file:
          data = json.load(file)

      filtered_data = [
          {column: product.get(column, "N/A") for column in columns_to_keep}
          for product in data["products"]
      ]

      with open("products.json", "w") as file:
          json.dump(filtered_data, file, indent=4)

  - id: query
    type: io.kestra.plugin.jdbc.duckdb.Query
    inputFiles:
      products.json: "{{outputs.transform.outputFiles['products.json']}}"
    sql: |
      INSTALL json;
      LOAD json;
      SELECT brand, round(avg(price), 2) as avg_price
      FROM read_json_auto('{{workingDir}}/products.json')
      GROUP BY brand
      ORDER BY avg_price DESC;
    fetchType: STORE
```    

Then click on save button


### Step-by-step explanation of the flow:


**Id and namespace**

To begin with, here we have the ID, which is the name of our workflow. Followed by that, we have the namespace, which is sort of like a folder where we're going to store this. 

```yaml

id: 01_getting_started_data_pipeline
namespace: zoomcamp
```

**Inputs**

Following that, we have inputs, which are values we can pass in at the start of our workflow execution to then be able to define what happens. Now this one's looking for an array with two values inside of it, in this case, brand and price, which are default. But if you press execution, you can actually change what these values will be so that we can get different results for different executions.

The flow accepts a single input, an array of strings that specifies which columns to retain when processing the data:

```yaml
inputs:
  - id: columns_to_keep
    type: ARRAY
    itemType: STRING
    defaults:
      - brand
      - price
```      

**Task 1: Extract**

Afterwards, we've got our tasks, and as you can see here, the first task is going to extract data.

Downloads a JSON dataset from the URL https://dummyjson.com/products

The downloaded file's URI is accessible in subsequent tasks using {{outputs.extract.uri}}.

```yaml
tasks:
  - id: extract
    type: io.kestra.plugin.core.http.Download
    uri: https://dummyjson.com/products

```  

**Task 2: Transform**

in the Python code we're starting to transform the data to produce a new file, which is called products.json. Afterwards, we can then pass products.json to our query task


task 2:

```yaml
tasks:

  - id: transform
    type: io.kestra.plugin.scripts.python.Script
    containerImage: python:3.11-alpine
    inputFiles:
      data.json: "{{outputs.extract.uri}}"
    outputFiles:
      - "*.json"
    env:
      COLUMNS_TO_KEEP: "{{inputs.columns_to_keep}}"
    script: |
      import json
      import os

      columns_to_keep_str = os.getenv("COLUMNS_TO_KEEP")
      columns_to_keep = json.loads(columns_to_keep_str)

      with open("data.json", "r") as file:
          data = json.load(file)

      filtered_data = [
          {column: product.get(column, "N/A") for column in columns_to_keep}
          for product in data["products"]
      ]

      with open("products.json", "w") as file:
          json.dump(filtered_data, file, indent=4)
```     

- Environment: Runs a Python script in a container using the python:3.11-alpine image
- Takes the JSON file downloaded in the previous task (data.json).
- Sets COLUMNS_TO_KEEP from the input columns_to_keep
- Reads the data.json file
- Extracts only the specified columns (brand and price by default) for each product.
- Saves the transformed data to products.json.
- Outputs the filtered JSON file as products.json.


Python code is directly inside of our workflow, but we can also use Python code in separate files using the command task 

Python script explanation:

```python
import json
import os

# Load the columns to keep from the environment variable
columns_to_keep_str = os.getenv("COLUMNS_TO_KEEP")
columns_to_keep = json.loads(columns_to_keep_str)

# Read the input JSON data
with open("data.json", "r") as file:
    data = json.load(file)

# Filter data to retain specified columns
filtered_data = [
    {column: product.get(column, "N/A") for column in columns_to_keep}
    for product in data["products"]
]

# Write the filtered data to a new JSON file
with open("products.json", "w") as file:
    json.dump(filtered_data, file, indent=4)

```



**Task 3: Query**

- Input Data: Reads the products.json file output from the transform task.
- Installs and loads DuckDB's JSON extension (INSTALL json; LOAD json;).
- Reads the products.json file and processes the data: Calculates the average price (avg_price) for 
each brand. Groups the results by brand. Orders the results in descending order of avg_price.
- fetchType: STORE: It saves the results of the SQL query to a file. This allows the results to be used by subsequent tasks in the flow


```yaml
tasks:

  - id: query
    type: io.kestra.plugin.jdbc.duckdb.Query
    inputFiles:
      products.json: "{{outputs.transform.outputFiles['products.json']}}"
    sql: |
      INSTALL json;
      LOAD json;
      SELECT brand, round(avg(price), 2) as avg_price
      FROM read_json_auto('{{workingDir}}/products.json')
      GROUP BY brand
      ORDER BY avg_price DESC;
    fetchType: STORE
```    

### 2: Execute

Now let’s test this by saving our flow and executing it! 

We get this wonderful Gantt view that helps us visualize which task has run when and at what point the workflow is at. If I click into these, it gives me some log messages


![pipeline2](images/pipeline2.jpg) 


If you go to the outputs tab now, I will be able to view some of the data generated for the different tasks.

![pipeline4](images/pipeline4.jpg) 


Click on preview:

![pipeline5](images/pipeline5.jpg) 

We can see we’ve got the JSON that was extracted at the beginning. There’s a lot of data here that is not very useful to us in its current form

Then transform task also produced some data. I can see that we’ve got a JSON file here with products.json and another one called data.json. For example this is the preview from products.json:


![pipeline6](images/pipeline6.jpg) 


Then finally, we have the query, and here is where we get a table with the data in a much more organized, sorted format. It’s much more useful to us than that original JSON value. We can then download this or pass it to another task

Tasks Query --> Outputs uri --> Preview :


![pipeline7](images/pipeline7.jpg) 



## Launch Kestra using Docker Compose


### 1: Create a Docker-compose.yaml

Lets create a docker-compose.yml file inside your 02-workflow-orchestration:

```yaml

volumes:
  postgres-data:
    driver: local
  kestra-data:
    driver: local

services:
  postgres:
    image: postgres
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: kestra
      POSTGRES_USER: kestra
      POSTGRES_PASSWORD: kestra
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 10
    ports:
      - "5432:5432"

  kestra:
    image: kestra/kestra:latest
    pull_policy: always
    user: "root"
    command: server standalone
    volumes:
      - kestra-data:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp/kestra-wd:/tmp/kestra-wd
    environment:
      KESTRA_CONFIGURATION: |
        datasources:
          postgres:
            url: jdbc:postgresql://postgres:5432/kestra
            driverClassName: org.postgresql.Driver
            username: kestra
            password: kestra
        kestra:
          server:
            basicAuth:
              enabled: false
              username: "admin@kestra.io" # it must be a valid email address
              password: kestra
          repository:
            type: postgres
          storage:
            type: local
            local:
              basePath: "/app/storage"
          queue:
            type: postgres
          tasks:
            tmpDir:
              path: /tmp/kestra-wd/tmp
          url: http://localhost:8080/
    ports:
      - "8080:8080"
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_started


  pgdatabase:
    image: postgres
    environment:
      - POSTGRES_USER=root
      - POSTGRES_PASSWORD=root
      - POSTGRES_DB=ny_taxi
    volumes:
      - "./ny_taxi_postgres_data:/var/lib/postgresql/data:rw"
    ports:
      - "5433:5432"


  pgadmin:
    image: dpage/pgadmin4
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=root
    volumes:
      - "./data_pgadmin:/var/lib/pgadmin"
    ports:
      - "8090:80"
    depends_on:
      - postgres       
```

This docker-compose.yml file defines four services: postgres, kestra, pgdatabase, and pgadmin, along with two named volumes: postgres-data and kestra-data.

**Volumes:**

- postgres-data: Stores PostgreSQL data persistently.
- kestra-data: Stores Kestra-related metadata persistently.

**Services**

- postgres: PostgreSQL Database for kestra metadata
- kestra: Kestra Workflow Orchestrator
- pgdatabase: Another PostgreSQL Database for NY Taxi Data
- pgadmin: pgAdmin for Database Management

> [!NOTE]  
I added the pgadmin service myself, it is optional but recommended to interact with the database

---

### 2: Create ny_taxi_postgres_data folder

Create a ny_taxi_postgres_data folder in the same directory as the docker-compose.yaml file.

The directory structure now should look like this:

```

├── Workflow-Orchestration
    ├── flows
    |
    ├── ny_taxi_postgres_data
    |
    └── docker-compose.yaml

```

### 3: Run Kestra and Postgres

In a new terminal, go to the path where the docker-compose file is and run the following command:

```
docker-compose up -p kestra-postgres up -d
```

The -p option specifies a custom project name (kestra-postgres in this case).

The -d option stands for "detached mode," meaning the containers will run in the background, allowing you to continue using the terminal without being attached to the container logs.

Once the container starts, you can access the Kestra UI at http://localhost:8080 and the pgadmin web 
in http://localhost:8090

To connect pgadmin with the postgress db: Right-click on Servers on the left sidebar --> Register--> Server

Under General give the Server a name: kestra taxi

Under Connection add:

- host name: pgdatabase
- port:5432 
- user:root
- password:root

<br>

![kestra17](images/kestra17.jpg)

<br><br>


# 2. Hands-On Coding Project: Build Data Pipelines with Kestra


## Load Data to Local Postgres

_([Video source](https://www.youtube.com/watch?v=OkfLX28Ecjg))_

- CSV files accessible here: https://github.com/DataTalksClub/nyc-tlc-data/releases
- Flow: [`02_postgres_taxi.yaml`](flows/02_postgres_taxi.yaml)



![local1](images/local1.jpg) 


### 1: Flow explanation step by step

#### Variables

```yaml
variables:
  file: "{{inputs.taxi}}_tripdata_{{inputs.year}}-{{inputs.month}}.csv"
  staging_table: "public.{{inputs.taxi}}_tripdata_staging"
  table: "public.{{inputs.taxi}}_tripdata"
  data: "{{outputs.extract.outputFiles[inputs.taxi ~ '_tripdata_' ~ inputs.year ~ '-' ~ inputs.month ~ '.csv']}}""
```  

- file: Constructs the filename of the CSV file to be processed based on the selected taxi type, year, and month. The result will be a string like "yellow_tripdata_2019-01.csv"
- staging_table: Temporary table for the given taxi, year, and month.
- table: Specifies the final table name in PostgreSQL where the merged data will be stored for a specific taxi type. Example: public.green_tripdata
- data:  Refers to the output file generated by the extract task, used as input for the CopyIn tasks. Example: If inputs.taxi = green, inputs.year = 2020, and inputs.month = 02, and the file was downloaded successfully: outputs.extract.outputFiles['green_tripdata_2020-02.csv']




#### Task: Set Labels

Adds labels to the flow execution to track the selected file and taxi type.

Labels are metadata tags that help organize, identify, and track workflow executions. They can provide valuable contextual information during runtime or when reviewing logs and monitoring workflow executions.

Labels appear in the Kestra UI or logs, making it easier to understand the context of an execution. Useful for filtering or searching workflow executions by specific criteria

#### Task: Extract Data

```yaml
  - id: extract
    type: io.kestra.plugin.scripts.shell.Commands
    outputFiles:
      - "*.csv"
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    commands:
      - wget -qO- https://github.com/DataTalksClub/nyc-tlc-data/releases/download/{{inputs.taxi}}/{{render(vars.file)}}.gz | gunzip > {{render(vars.file)}}

```

Downloads the compressed CSV file using wget from the GitHub repository and decompresses it and saves it as a .csv file.

#### Task: yellow_table/green_table

```yaml
  - id: yellow_table
    runIf: "{{inputs.taxi == 'yellow'}}"
    type: io.kestra.plugin.jdbc.postgresql.Queries
    sql: |
      CREATE TABLE IF NOT EXISTS {{render(vars.table)}} (
          unique_row_id          text,
          filename                text,
          VendorID               text,

        ...
      );
```      

Creates a yellow/green taxi final table in PostgreSQL if it doesn't already exist, with specific schema columns.

The reason we have to use the render function inside of this expression:

```
CREATE TABLE IF NOT EXISTS {{render(vars.final_table)}}
```

is because we need to be able to render the variable which has an expression in it so we get a string which will contain green or yellow and then we can use it otherwise we will just receive a string and it will not have the dynamic value.

Schema has two extra columns: unique grow ID and file name so we can see which file the data came and a unique ID generated based on the data in order to prevent adding duplicates later 


#### Task: yellow_create_staging_table/green_create_staging_table

```yaml
  - id: yellow_create_staging_table
    runIf: "{{inputs.taxi == 'yellow'}}"
    type: io.kestra.plugin.jdbc.postgresql.Queries
    sql: |
      CREATE TABLE IF NOT EXISTS {{render(vars.staging_table)}} (
          VendorID               text,
          tpep_pickup_datetime   timestamp,
          tpep_dropoff_datetime  timestamp,
          passenger_count        integer,

          ...
      );
```      

Creates a temporary table for monthly yellow/green taxi data with schema aligned to the CSV file.


#### Task: truncate_table

```yaml
  - id: truncate_table
    type: io.kestra.plugin.jdbc.postgresql.Queries
    sql: |
      TRUNCATE TABLE {{render(vars.staging_table)}};
```      

Ensures the staging table is empty before loading new data.

#### Task: green_copy_in_to_staging_table/yellow_copy_in_to_staging_table

```yaml
  - id: green_copy_in_to_staging_table
    runIf: "{{inputs.taxi == 'green'}}"
    type: io.kestra.plugin.jdbc.postgresql.CopyIn
    format: CSV
    from: "{{render(vars.data)}}"
    table: "{{render(vars.staging_table)}}"
    header: true
    columns: [VendorID,lpep_pickup_datetime, ...]

```

This task is responsible for copying data from the extracted CSV file into a temporary PostgreSQL table for processing

- runIf: "{{inputs.taxi == 'green'}}": This ensures the task runs only when the user selects green as the taxi type
- type: io.kestra.plugin.jdbc.postgresql.CopyIn: The task uses the CopyIn plugin, which supports PostgreSQL's COPY command for bulk data loading.
- format: CSV: Indicates that the input file format is a CSV.
- from: "{{render(vars.data)}}": Refers to the location of the extracted CSV file. The vars.data variable resolves to the path of the downloaded green taxi data file, such as outputs.extract.outputFiles['green_tripdata_2020-02.csv'].
- table: "{{render(vars.staging_table)}}": Specifies the target temporary table where the data will be imported. The vars.table variable dynamically generates the table name, for example "public.green_tripdata_temp".
- header: true: Indicates that the first row of the CSV contains column headers (e.g., VendorID, lpep_pickup_datetime, etc.).
- columns: Lists the columns in the PostgreSQL table that correspond to the data in the CSV file. These include fields like VendorID, lpep_pickup_datetime, trip_distance, etc., ensuring the data is mapped correctly during the import.


#### Task: yellow_add_unique_id_and_filename/green_add_unique_id_and_filename

```yaml
  - id: yellow_add_unique_id_and_filename
    runIf: "{{inputs.taxi == 'yellow'}}"
    type: io.kestra.plugin.jdbc.postgresql.Queries
    sql: |
      ALTER TABLE {{render(vars.staging_table)}}
      ADD COLUMN IF NOT EXISTS unique_row_id text,
      ADD COLUMN IF NOT EXISTS filename text;
  
      UPDATE {{render(vars.staging_table)}}
      SET 
        unique_row_id = md5(
          COALESCE(CAST(VendorID AS text), '') ||
          COALESCE(CAST(tpep_pickup_datetime AS text), '') || 
          COALESCE(CAST(tpep_dropoff_datetime AS text), '') || 
          COALESCE(PULocationID, '') || 
          COALESCE(DOLocationID, '') || 
          COALESCE(CAST(fare_amount AS text), '') || 
          COALESCE(CAST(trip_distance AS text), '')      
        ),
        filename = '{{render(vars.file)}}';
```        

- Adds columns unique_row_id and filename if they don't exist in the temporary table
- Updates the table by generating a unique hash ID for each row and stores the file name.


#### Task: yellow_merge_data/green_merge_data

```yaml
  - id: yellow_merge_data
    runIf: "{{inputs.taxi == 'yellow'}}"
    type: io.kestra.plugin.jdbc.postgresql.Queries
    sql: |
      MERGE INTO {{render(vars.table)}} AS T
      USING {{render(vars.staging_table)}} AS S
      ON T.unique_row_id = S.unique_row_id
      WHEN NOT MATCHED THEN
        INSERT (
          unique_row_id, filename, VendorID, tpep_pickup_datetime, tpep_dropoff_datetime,
          passenger_count, trip_distance, RatecodeID, store_and_fwd_flag, PULocationID,
          DOLocationID, payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount,
          improvement_surcharge, total_amount, congestion_surcharge
        )
        VALUES (
          S.unique_row_id, S.filename, S.VendorID, S.tpep_pickup_datetime, S.tpep_dropoff_datetime,
          S.passenger_count, S.trip_distance, S.RatecodeID, S.store_and_fwd_flag, S.PULocationID,
          S.DOLocationID, S.payment_type, S.fare_amount, S.extra, S.mta_tax, S.tip_amount, S.tolls_amount,
          S.improvement_surcharge, S.total_amount, S.congestion_surcharge
        );
```        

Merges monthly data from the temporary table into the yellow_table/green_table using the unique_row_id as the key

- type: io.kestra.plugin.jdbc.postgresql.Queries: Executes SQL queries on a PostgreSQL database.
- SQL Query:

  ```sql
  MERGE INTO {{render(vars.table)}} AS T
  USING {{render(vars.staging_table)}} AS S
  ON T.unique_row_id = S.unique_row_id
  ```

  MERGE INTO {{render(vars.table)}} AS T: Combines data from the monthly table (S) into the final table (T).

  USING {{render(vars.staging_table)}} AS S: Refers to the source table (S), which is dynamically rendered from the variable vars.table (e.g., public.yellow_tripdata_2019_01).

  ON T.unique_row_id = S.unique_row_id: Matches rows from the source (S) and target (T) based on the unique_row_id column. If a record with the same unique_row_id exists in T, it is ignored.


- SQL Query:

  ```sql
  WHEN NOT MATCHED THEN
  INSERT (
    unique_row_id, filename, VendorID, tpep_pickup_datetime, tpep_dropoff_datetime,
    passenger_count, trip_distance, RatecodeID, store_and_fwd_flag, PULocationID,
    DOLocationID, payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount,
    improvement_surcharge, total_amount, congestion_surcharge
  )
  VALUES (
    S.unique_row_id, S.filename, S.VendorID, S.tpep_pickup_datetime, S.tpep_dropoff_datetime,
    S.passenger_count, S.trip_distance, S.RatecodeID, S.store_and_fwd_flag, S.PULocationID,
    S.DOLocationID, S.payment_type, S.fare_amount, S.extra, S.mta_tax, S.tip_amount, S.tolls_amount,
    S.improvement_surcharge, S.total_amount, S.congestion_surcharge
  );
  ```

  WHEN NOT MATCHED THEN: Ensures that only records that do not already exist in T are inserted.

  INSERT VALUES: Inserts all relevant columns from the monthly table,



#### Task: purge_files

This task ensures that any files downloaded or generated during the flow execution are deleted once they are no longer needed. Its purpose is to keep the storage clean and free of unnecessary clutter.


#### Plugin Defaults

All PostgreSQL tasks use a pre-configured connection:

URL: jdbc:postgresql://host.docker.internal:5433/ny_taxi
Username: root
Password: root


### 2: Execute flow


Lets try with this example:

![local2](images/local2.jpg) 


### 3: Check PgAdmin

Head over to PgAdmin --> Servers --> kestra taxi --> Databases --> ny_taxi --> Schemas --> public --> Tables --> green_tripdata

final table for green taxi looks like this:

![local2](images/kestra18.jpg) 


## Load Data to Local Postgres with backfill

_([Video source](https://www.youtube.com/watch?v=_-li_z97zog))_

- Flow: [`02_postgres_taxi_scheduled.yaml`](flows/02_postgres_taxi_scheduled.yaml)

Backfill is the process of running a workflow or data pipeline for historical data that wasn't processed when it originally occurred. It involves replaying or processing past data to ensure the dataset is complete and up to date.

Now we can start using schedules and backfills to automate our pipeline. All we need here is an input for the type of taxi. Previously, we had the month and the year to go with that too. We don't need that this time because we're going to use the trigger to automatically add that.

### 1: Flow explanation

**concurrency**

```yaml
concurrency:
    limit: 1
```

It's worth noting that we need to run these one at a time because we only have one staging table here meaning we can only run one execution of this workflow at a time to prevent multiple flows from writing different months to the same staging table. If we want to run multiple months at a time, we should create staging tables for each of the months. 


**Triggers: green_schedule**

- Cron Expression: "0 9 1 * *": Runs at 9:00 AM on the first day of every month.
-  Initiates the workflow to process monthly data for green taxis at the scheduled time.

**Triggers: yellow_schedule**

- Cron Expression: "0 10 1 * *": Runs at 10:00 AM on the first day of every month.
- Initiates the workflow to process monthly data for yellow taxis at the scheduled time.


### 2: Execute flow

Select triggers --> Backfill executions

Lets try with this example:

<br>

![local19](images/kestra19.jpg) 

<br>

Select executions:

<br>

![local20](images/kestra20.jpg) 

<br>

### 3: Check PgAdmin

After backfilling January and February and manually loading May 2019, you can now, for example, run queries on the table:

![local21](images/kestra21.jpg) 



## Run kestra with persistence
```shell
docker compose build
docker compose up
```

