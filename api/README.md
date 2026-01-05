# Multi-Tenant SaaS API

This is a multi-tenant API built with Go, PostgreSQL, and Redis, featuring tenant isolation, JWT authentication, and rate limiting.

## Features

- **Multi-Tenancy**: Tenant isolation via tenant_id in the database
- **JWT Authentication**: Secure authentication with tenant ID in JWT claims
- **Rate Limiting**: Per-tenant rate limiting using Redis
- **Stateless Services**: No session storage, all state in JWT
- **PostgreSQL Integration**: Single database with tenant isolation
- **Redis Integration**: For rate limiting and caching

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client Apps   │───▶│   API Gateway    │───▶│  Multi-Tenant   │
└─────────────────┘    └──────────────────┘    │      API        │
                                              ├─────────────────┤
                                              │  PostgreSQL     │
                                              │  (Single DB)    │
                                              ├─────────────────┤
                                              │    Redis        │
                                              │  (Rate Limit)   │
                                              └─────────────────┘
```

## Tenant Isolation Strategy

- **Database**: Single PostgreSQL database with tenant_id column in all tables
- **JWT**: Tenant ID stored in JWT claims for authentication
- **Rate Limiting**: Per-tenant limits stored in Redis

## Endpoints

- `GET /health` - Health check endpoint
- `GET /api/data` - Get data for authenticated tenant
- `POST /api/users` - Create a new user for the authenticated tenant

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_ADDR` - Redis address (default: localhost:6379)
- `JWT_SECRET` - Secret key for JWT signing
- `PORT` - Port to run the server on (default: 8080)

## Setup

1. Set up PostgreSQL database with the required schema
2. Set up Redis instance
3. Configure environment variables
4. Run the application

## Security Features

- JWT-based authentication with tenant ID
- Per-tenant rate limiting (100 requests/minute by default)
- Tenant data isolation at the database level
- Secure token validation
- CORS headers configured