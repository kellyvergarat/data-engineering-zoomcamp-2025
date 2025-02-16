#download python image to the container
FROM python:3.9.1

#install pandas
RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2 pyarrow

#create a directory in the container and set it as the working directory
WORKDIR /app

#copy the pipeline.py file from the local directory to the container (/app folder) with the same name
#COPY pipeline.py pipeline.py
COPY ingest_data.py ingest_data.py

#entrypoint to run the pipeline.py file
# ENTRYPOINT ["bash"]

#run the pipeline.py file
ENTRYPOINT [ "python", "ingest_data.py" ]
