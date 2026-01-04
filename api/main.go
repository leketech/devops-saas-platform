package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/mux"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/prometheus/client_golang/prometheus"
)

// Tenant represents a tenant in the multi-tenant system
type Tenant struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	IsActive  bool      `json:"is_active"`
}

// APIResponse represents the standard API response format
type APIResponse struct {
	Status  string      `json:"status"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

// Claims represents the JWT claims
type Claims struct {
	TenantID string `json:"tenant_id"`
	UserID   string `json:"user_id"`
	jwt.RegisteredClaims
}

// App holds the application dependencies
type App struct {
	DB     *pgxpool.Pool
	Redis  *redis.Client
	Router *mux.Router
	// Prometheus metrics
	RequestDuration *prometheus.HistogramVec
	RequestCounter  *prometheus.CounterVec
	ActiveRequests  prometheus.Gauge
}

// Middleware to extract tenant ID from JWT
func (a *App) tenantMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Authorization header required", http.StatusUnauthorized)
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			http.Error(w, "Bearer token required", http.StatusUnauthorized)
			return
		}

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return []byte(os.Getenv("JWT_SECRET")), nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		// Add tenant ID to request context
		ctx := context.WithValue(r.Context(), "tenant_id", claims.TenantID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// Metrics middleware to track request duration and count
func (a *App) metricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		a.ActiveRequests.Inc()
		defer a.ActiveRequests.Dec()

		// Create a response writer that captures the status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapped, r)

		duration := time.Since(start).Seconds()

		a.RequestDuration.WithLabelValues(
			r.URL.Path,
			r.Method,
			strconv.Itoa(wrapped.statusCode),
		).Observe(duration)

		a.RequestCounter.WithLabelValues(
			r.URL.Path,
			r.Method,
			strconv.Itoa(wrapped.statusCode),
		).Inc()
	})
}

// ResponseWriter wrapper to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// Middleware for rate limiting using Redis
func (a *App) rateLimitMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tenantID := r.Context().Value("tenant_id").(string)
		key := fmt.Sprintf("rate_limit:%s", tenantID)

		// Get current count and reset time from Redis
		countStr, err := a.Redis.Get(r.Context(), key).Result()
		if err != nil && err != redis.Nil {
			log.Printf("Redis error: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		count := 0
		if countStr != "" {
			count, _ = strconv.Atoi(countStr)
		}

		// Check if rate limit exceeded (100 requests per minute per tenant)
		if count >= 100 {
			http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
			return
		}

		// Increment count and set expiration if it's a new key
		if count == 0 {
			a.Redis.SetEX(r.Context(), key, 1, time.Minute)
		} else {
			a.Redis.Incr(r.Context(), key)
		}

		next.ServeHTTP(w, r)
	})
}

// Get tenant ID from context
func getTenantID(r *http.Request) string {
	if tenantID, ok := r.Context().Value("tenant_id").(string); ok {
		return tenantID
	}
	return ""
}

// Health check endpoint
func (a *App) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(APIResponse{
		Status:  "success",
		Message: "API is running",
	})
}

// Example protected endpoint that uses tenant isolation
func (a *App) getDataHandler(w http.ResponseWriter, r *http.Request) {
	tenantID := getTenantID(r)
	if tenantID == "" {
		http.Error(w, "Tenant ID not found", http.StatusInternalServerError)
		return
	}

	// Example query that uses tenant isolation
	query := `
		SELECT id, name, created_at, updated_at, is_active
		FROM users 
		WHERE tenant_id = $1
		ORDER BY created_at DESC
		LIMIT 10
	`

	rows, err := a.DB.Query(r.Context(), query, tenantID)
	if err != nil {
		log.Printf("Database query error: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var users []map[string]interface{}
	for rows.Next() {
		var id, name string
		var createdAt, updatedAt time.Time
		var isActive bool

		err := rows.Scan(&id, &name, &createdAt, &updatedAt, &isActive)
		if err != nil {
			log.Printf("Row scan error: %v", err)
			continue
		}

		user := map[string]interface{}{
			"id":         id,
			"name":       name,
			"created_at": createdAt,
			"updated_at": updatedAt,
			"is_active":  isActive,
		}
		users = append(users, user)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(APIResponse{
		Status: "success",
		Data:   users,
	})
}

// Create a new user (example endpoint with tenant isolation)
func (a *App) createUserHandler(w http.ResponseWriter, r *http.Request) {
	tenantID := getTenantID(r)
	if tenantID == "" {
		http.Error(w, "Tenant ID not found", http.StatusInternalServerError)
		return
	}

	var req struct {
		Name string `json:"name"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Insert user with tenant_id for isolation
	query := `
		INSERT INTO users (id, tenant_id, name, created_at, updated_at, is_active)
		VALUES (gen_random_uuid(), $1, $2, NOW(), NOW(), true)
		RETURNING id
	`

	var userID string
	err := a.DB.QueryRow(r.Context(), query, tenantID, req.Name).Scan(&userID)
	if err != nil {
		log.Printf("Database insert error: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(APIResponse{
		Status: "success",
		Data: map[string]string{
			"user_id": userID,
		},
	})
}

// Initialize the database schema
func (a *App) initDB() error {
	// Create users table with tenant_id for isolation
	usersTable := `
		CREATE TABLE IF NOT EXISTS users (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			tenant_id VARCHAR(255) NOT NULL,
			name VARCHAR(255) NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			is_active BOOLEAN DEFAULT true,
			INDEX idx_tenant_id (tenant_id)
		);
	`

	_, err := a.DB.Exec(context.Background(), usersTable)
	if err != nil {
		return fmt.Errorf("failed to create users table: %w", err)
	}

	return nil
}

// Initialize the application
func (a *App) initialize() error {
	if err := a.initDB(); err != nil {
		return err
	}

	// Initialize Prometheus metrics
	a.RequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name: "http_request_duration_seconds",
			Help: "Duration of HTTP requests in seconds",
		},
		[]string{"path", "method", "status"},
	)

	a.RequestCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"path", "method", "status"},
	)

	a.ActiveRequests = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "http_active_requests",
			Help: "Number of active HTTP requests",
		},
	)

	// Setup routes
	a.Router.Use(a.metricsMiddleware) // Metrics middleware should be first to capture all requests
	a.Router.Use(a.rateLimitMiddleware)
	a.Router.Use(a.tenantMiddleware)

	// Add metrics endpoint
	a.Router.PathPrefix("/metrics").Handler(promhttp.Handler())

	a.Router.HandleFunc("/health", a.healthHandler).Methods("GET")
	a.Router.HandleFunc("/api/data", a.getDataHandler).Methods("GET")
	a.Router.HandleFunc("/api/users", a.createUserHandler).Methods("POST")

	return nil
}

func main() {
	// Initialize database connection
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	db, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Initialize Redis connection
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	// Create app instance
	app := &App{
		DB:     db,
		Redis:  rdb,
		Router: mux.NewRouter(),
	}

	// Initialize the app
	if err := app.initialize(); err != nil {
		log.Fatal("Failed to initialize app:", err)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, app.Router))
}
