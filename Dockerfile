# Base image for installing dependencies
FROM python:3.10.6-slim as base

# Set non-root user and home directory
ENV APP_HOME=/application
ENV APP_USER=appuser
RUN groupadd -r $APP_USER && \
    useradd -r -g $APP_USER -d $APP_HOME -s /sbin/nologin -c "Docker non-root user" $APP_USER

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    POETRY_VERSION=1.5.1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=false \
    POETRY_NO_INTERACTION=1 \
    VENV_PATH="/opt/venv" \
    PATH="${POETRY_HOME}/bin:${VENV_PATH}/bin:${PATH}"

# Set working directory
WORKDIR $APP_HOME

# Install Poetry
COPY ./titanic_app/pyproject.toml ./titanic_app/poetry.lock ./
RUN python -m venv ${VENV_PATH} \
    && . /opt/venv/bin/activate \
    && pip install --upgrade pip \
    && pip install poetry==${POETRY_VERSION} \
    && poetry install --only main --no-ansi

# Final image for running the application
FROM base 

# Add venv to PATH
ENV PATH="/opt/venv/bin:$PATH"

# Copy the python virtual environment
COPY --from=base $VENV_PATH $VENV_PATH

# Copy the code
WORKDIR $APP_HOME
COPY ./titanic_app/ .

# Give folder privileges to $APP_USER
RUN chown -R $APP_USER:$APP_USER $APP_HOME
USER $APP_USER

# Expose the port
EXPOSE 5000/tcp

# Set the entrypoint command
CMD [ "poetry", "run", "gunicorn", "-w", "2", "-b", ":5000", "app:create_app('production')" ]