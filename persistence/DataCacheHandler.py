import pandas as pd
from pandas import DataFrame
from sqlalchemy import create_engine
import os


class DataCacheHandler:
    def __init__(self, sql_file_path, data_file_path, param=None):
        self.param = param
        self.db_config = {
            "username": "root",
            "password": "admin",
            "host": "localhost",
            "port": "3307",
            "dbname": "qmodel_demo"
        }
        self.file_path = data_file_path
        self.query = open(sql_file_path, 'r').read()
        self.engine = self.create_db_engine()
        self.data = None

    def create_db_engine(self):
        """Create the SQLAlchemy engine to connect to the database."""
        return create_engine(
            f"mysql+pymysql://{self.db_config['username']}:{self.db_config['password']}@{self.db_config['host']}:{self.db_config['port']}/{self.db_config['dbname']}")

    def load_data(self):
        """Retrieve data from the database using the provided SQL query."""
        try:
            return pd.read_sql(self.query, self.engine, params={"owner": self.param})
        except Exception as e:
            print(f"Error loading data: {e}")

    def save_to_csv(self, file_path):
        """Save the DataFrame to a CSV file."""
        if self.data is not None:
            self.data.to_csv(file_path, index=False)
            print(f"Data saved to CSV at {file_path}")
        else:
            self.data = self.load_data()
            self.data.to_csv(file_path, index=False)

    def save_to_parquet(self, file_path):
        """Save the DataFrame to a Parquet file."""
        if self.data is not None:
            self.data.to_parquet(file_path, index=False)
            print(f"Data saved to Parquet at {file_path}")
        else:
            self.data = self.load_data()
            self.data.to_parquet(file_path, index=False)

    def save_to_json(self, file_path):
        """Save the DataFrame to a JSON file."""
        if self.data is not None:
            self.data.to_json(file_path, orient="records")
            print(f"Data saved to JSON at {file_path}")
        else:
            self.data = self.load_data()
            self.data.to_json(file_path, index=False)

    def save_to_pickle(self, file_path):
        """Save the DataFrame to a Pickle file."""
        if self.data is not None:
            self.data.to_pickle(file_path)
        else:
            self.data = self.load_data()
            self.data.to_pickle(file_path, index=False)

    def load_from_csv(self):
        """Load data from a CSV file."""
        if os.path.exists(self.file_path):
            return pd.read_csv(self.file_path)
        else:
            self.save_to_csv(self.file_path)
            return pd.read_csv(self.file_path)

    def load_from_parquet(self) -> DataFrame:
        """Load data from a Parquet file."""
        if os.path.exists(self.file_path):
            return pd.read_parquet(self.file_path)
        else:
            self.save_to_parquet(self.file_path)
            return pd.read_parquet(self.file_path)

    def load_from_json(self):
        """Load data from a JSON file."""
        if os.path.exists(self.file_path):
            return pd.read_json(self.file_path, orient="records")
        else:
            self.save_to_json(self.file_path)
            return pd.read_json(self.file_path, orient="records")

    def load_from_pickle(self):
        """Load data from a Pickle file."""
        if os.path.exists(self.file_path):
            return pd.read_pickle(self.file_path)
        else:
            self.save_to_pickle(self.file_path)
            return pd.read_pickle(self.file_path)
