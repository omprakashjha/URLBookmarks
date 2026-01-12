#!/bin/bash

# Script to toggle demo mode for URL Bookmarks web app

ENV_FILE=".env"

if [ "$1" = "on" ]; then
    echo "REACT_APP_DEMO_MODE=true" > $ENV_FILE
    echo "✅ Demo mode enabled"
    echo "Restart the development server to see changes"
elif [ "$1" = "off" ]; then
    echo "REACT_APP_DEMO_MODE=false" > $ENV_FILE
    echo "✅ Demo mode disabled"
    echo "Restart the development server to see changes"
else
    echo "Usage: ./demo-mode.sh [on|off]"
    echo ""
    echo "Current setting:"
    if [ -f "$ENV_FILE" ]; then
        grep REACT_APP_DEMO_MODE $ENV_FILE || echo "REACT_APP_DEMO_MODE not set (defaults to false)"
    else
        echo "No .env file found (demo mode defaults to false)"
    fi
fi
