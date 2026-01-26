# Example Dockerfile demonstrating how to run as a non-root user

FROM python:3.9-slim-buster

# 1. Create a working directory
WORKDIR /app

# 2. Create a non-root user and group
#    -r: Create a system user (no home directory, etc.)
#    -g: Add the user to an existing group
RUN groupadd -r appuser && useradd -r -g appuser appuser

# 3. Copy application files and set ownership
#    This ensures that the new user owns the application files
COPY --chown=appuser:appuser . /app

# 4. Switch to the non-root user
#    Any subsequent commands (RUN, CMD, ENTRYPOINT) will be executed as this user
USER appuser

# 5. Install dependencies (as the non-root user)
#    Note: This will install packages to the user's site-packages, not the global site-packages
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# 6. Run the application
#    The application will run as the 'appuser'
CMD ["python", "app.py"]
