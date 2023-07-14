"""
Module containing environment configurations
"""
import os
import boto3

class Config:
    # Base Config class
    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL')

    # Making sure the AWS calls aren't made during import time
    @staticmethod
    def init_app(app):
        pass

class Development(Config):
    """
    Development environment configuration
    """
    DEBUG = True


class Production(Config):
    """
    Production environment configuration
    """
    @classmethod
    def init_app(cls, app):
        session = boto3.Session(region_name='eu-central-1')
        ssm = session.client('ssm')
        cls.SQLALCHEMY_DATABASE_URI = ssm.get_parameter(Name='DATABASE_URL', WithDecryption=True)['Parameter']['Value']


app_config = {
    'development': Development,
    'production': Production,
}
