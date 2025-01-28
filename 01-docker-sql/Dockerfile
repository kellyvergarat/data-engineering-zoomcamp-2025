#download python image to the container
FROM python:3.9

#install pandas
RUN pip install pandas

#create a directory in the container and set it as the working directory
WORKDIR /app

#copy the pipeline.py file from the local directory to the container (/app folder) with the same name
COPY pipeline.py pipeline.py

#entrypoint to run the pipeline.py file
# ENTRYPOINT ["bash"]

#run the pipeline.py file
ENTRYPOINT [ "python", "pipeline.py" ]
