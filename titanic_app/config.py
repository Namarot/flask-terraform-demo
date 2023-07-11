"""
Module containing environment configurations
"""
import os
import boto3

class Development:
    """
    Development environment configuration
    """
    DEBUG = True
    TESTING = False
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL')


class Production:
    """
    Production environment configuration
    """
    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = ssm.get_parameter(Name='DATABASE_URL', WithDecryption=True)['Parameter']['Value']


app_config = {
    'development': Development,
    'production': Production,
}
