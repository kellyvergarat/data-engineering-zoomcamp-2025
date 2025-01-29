import pandas as pd
import argparse
import os
from sqlalchemy import create_engine
from time import time



def main(args):
        user = args.user
        password = args.password
        host = args.host
        port = args.port
        db = args.db
        table_name = args.table_name

        parquet_name = "output.parquet"
        csv_name = "output.csv"

        #download the file
        #This will download the csv file from the url and save it as output.csv 
        os.system(f"wget {args.url} -O {parquet_name}")

        #convert the parquet file to csv
        df = pd.read_parquet(parquet_name)
        df.to_csv(csv_name, index=False)

        engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{db}')
        df_iter = pd.read_csv(csv_name, chunksize=100000, iterator=True)
        df = next(df_iter)

        engine.connect()

        df.head(0).to_sql(name=table_name, con=engine, if_exists="replace", index=False)    

        df.to_sql(name=table_name, con=engine, if_exists="append", index=False)

        while True:
                t_start = time()
                df = next(df_iter)
                df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
                df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

                df.to_sql(name=table_name, con=engine, if_exists="append", index=False)

                t_end = time()

                print(f"inserted another chunk..., took %.3f second" % (t_end - t_start))

if __name__ == '__main__':
        parser = argparse.ArgumentParser(description='Ingest CSV data to PostgreSQL')

        #Parse the arguments
        #user password host port databasename tablename url of the csv file
        parser.add_argument('--user', help='user name for postgresql')
        parser.add_argument('--password', help='password for postgresql')
        parser.add_argument('--host', help='host for postgresql')
        parser.add_argument('--port', help='port for postgresql')
        parser.add_argument('--db', help='database name for postgresql')
        parser.add_argument('--table_name', help='table name where we will write the results to')
        parser.add_argument('--url', help='url of the csv file')

        args = parser.parse_args()
        
        main(args)

