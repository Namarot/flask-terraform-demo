from flask import Flask
from config import app_config
from models import db
from views.people import people_api as people
import os
import boto3

def create_app() -> Flask:
    """
    Initializes the application registers

    Parameters:
        env_name: the name of the environment to initialize the app with

    Returns:
        The initialized app instance
    """
    env_name = os.getenv('FLASK_ENV', 'development')

    app = Flask(__name__)
    config_class = app_config[env_name]
    app.config.from_object(config_class)

    if env_name == 'production':
        # Retrieve DATABASE_URL from SSM Parameter Store
        session = boto3.Session(region_name='eu-central-1')
        ssm = session.client('ssm')
        app.config['SQLALCHEMY_DATABASE_URI'] = ssm.get_parameter(
            Name='DATABASE_URL', WithDecryption=True
        )['Parameter']['Value']
    
    config_class.init_app(app)

    db.init_app(app)

    app.register_blueprint(people, url_prefix="/")

    @app.route('/', methods=['GET'])
    def index():
        """
        Root endpoint for populating root route

        Returns:
            Greeting message
        """
        return """
        Welcome to the Titanic API
        """

    return app


if __name__ == "__main__":
    # Run the Flask app
    app = create_app()
    app.run()