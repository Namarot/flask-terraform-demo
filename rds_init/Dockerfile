# Use the official PostgreSQL image as the base image
FROM postgres

WORKDIR /task

# Copy the scripts into the Docker image
COPY init.sh .
COPY app.sql .
COPY app.csv .

# Set the execute permission for the script
RUN chmod +x init.sh

# Run the script
CMD [ "./init.sh" ]

