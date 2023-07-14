"""
Module containing environment configurations
"""
import os

class Config:
    # Base Config class
    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL')

    @staticmethod
    def init_app(app):
        pass

class Development(Config):
    """
    Development environment configuration
    """
    DEBUG = True

class Test(Config):
    """
    Test environment configuration
    """
    TESTING = True


class Production(Config):
    """
    Production environment configuration
    """
    pass

app_config = {
    'development': Development,
    'test': Test,
    'production': Production,
}
