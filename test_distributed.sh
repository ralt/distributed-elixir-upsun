#!/bin/bash

# Script to test OTP distribution locally with multiple nodes

echo "Testing Hello Distributed OTP Application"
echo "=========================================="
echo ""
echo "This script will test the distributed counter across multiple nodes."
echo ""

# Check if mix is available
if ! command -v mix &> /dev/null; then
    echo "Error: mix command not found. Please install Elixir first."
    exit 1
fi

# Test the counter on localhost
echo "Testing local endpoint at http://localhost:4000"
echo ""

# Test hello world endpoint
echo "1. Testing GET / (Hello World):"
curl -s http://localhost:4000/ | python3 -m json.tool || echo "Server not running on port 4000"
echo ""

# Test nodes endpoint
echo "2. Testing GET /nodes (Node Information):"
curl -s http://localhost:4000/nodes | python3 -m json.tool || echo "Server not running"
echo ""

# Test counter endpoint
echo "3. Testing GET /counter (Get Counter):"
curl -s http://localhost:4000/counter | python3 -m json.tool || echo "Server not running"
echo ""

# Test increment endpoint
echo "4. Testing POST /counter/increment (Increment Counter):"
curl -s -X POST http://localhost:4000/counter/increment | python3 -m json.tool || echo "Server not running"
echo ""

echo "5. Testing GET /counter (Verify Increment):"
curl -s http://localhost:4000/counter | python3 -m json.tool || echo "Server not running"
echo ""

echo "=========================================="
echo "To run multiple nodes locally:"
echo ""
echo "Terminal 1:"
echo "  iex --name node1@127.0.0.1 --cookie secret -S mix phx.server"
echo ""
echo "Terminal 2:"
echo "  PORT=4001 iex --name node2@127.0.0.1 --cookie secret -S mix phx.server"
echo ""
echo "Then in Terminal 2 IEx console:"
echo "  Node.connect(:\"node1@127.0.0.1\")"
echo "  Node.list()"
echo ""
echo "Test both servers:"
echo "  curl http://localhost:4000/nodes"
echo "  curl http://localhost:4001/nodes"
echo ""
