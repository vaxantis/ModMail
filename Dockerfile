# -----------------------------
# Stage 1: Base image with system deps
# -----------------------------
FROM python:3.11-slim-bookworm AS base

# Install system dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        libcairo2 \
        libpango-1.0-0 \
        libgdk-pixbuf2.0-0 \
        libffi7 \
        wget \
        build-essential \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --shell /usr/sbin/nologin --create-home -d /opt/modmail modmail

WORKDIR /opt/modmail

# -----------------------------
# Stage 2: Builder for venv & Python deps
# -----------------------------
FROM base AS builder

# Copy only requirements first (faster rebuilds)
COPY requirements.txt .

# Create venv and install all Python deps
RUN python -m venv /opt/modmail/.venv \
    && . /opt/modmail/.venv/bin/activate \
    && pip install --upgrade pip wheel \
    && pip install --no-cache-dir -r requirements.txt

# -----------------------------
# Stage 3: Final image
# -----------------------------
FROM base

# Copy venv from builder
COPY --from=builder --chown=modmail:modmail /opt/modmail/.venv /opt/modmail/.venv

# Copy repository files
COPY --chown=modmail:modmail . .

# Use venv by default
ENV PATH="/opt/modmail/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    USING_DOCKER=yes

# Expose port for FastAPI
EXPOSE 8000

# Switch to non-root user
USER modmail:modmail

# Run FastAPI app (replace 'main:app' with your FastAPI entrypoint)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
