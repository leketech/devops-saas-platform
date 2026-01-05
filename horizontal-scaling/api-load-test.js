import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const failureRate = new Rate('failures');
const responseTime = new Trend('response_time');

// Options for the test
export const options = {
  // Ramp up from 10 to 1000 users over 10 minutes, then maintain for 5 minutes
  stages: [
    { duration: '2m', target: 10 },    // Ramp up to 10 users
    { duration: '3m', target: 100 },   // Ramp up to 100 users over 3 minutes
    { duration: '3m', target: 500 },   // Ramp up to 500 users over 3 minutes
    { duration: '2m', target: 1000 },  // Ramp up to 1000 users over 2 minutes
    { duration: '5m', target: 1000 },  // Maintain 1000 users for 5 minutes
    { duration: '2m', target: 0 },     // Scale down to 0
  ],
  thresholds: {
    // HTTP error rate should be less than 1%
    'http_req_failed': ['rate<0.01'],
    // 95% of requests should be below 500ms
    'http_req_duration': ['p(95)<500'],
    // 99% of requests should be below 1000ms
    'http_req_duration': ['p(99)<1000'],
    // Average response time should be below 200ms
    'http_req_duration_avg': ['value<200'],
  },
};

// Function to generate a JWT token for testing (in real scenario, this would be obtained from auth service)
function getJWTToken() {
  // In a real scenario, you would obtain a valid JWT token
  // For this test, we'll use a placeholder
  return __ENV.API_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJ0ZW5hbnRfaWQiOiJ0ZXN0LXRlbmFudCJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
}

export default function () {
  const token = getJWTToken();
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };

  // Test the health endpoint
  let response = http.get('http://multitenant-api-service.platform.svc.cluster.local/health', {
    headers: headers,
  });

  const healthCheck = check(response, {
    'health status is 200': (r) => r.status === 200,
    'health response has status success': (r) => r.json().status === 'success',
  });

  failureRate.add(!healthCheck);
  responseTime.add(response.timings.duration);

  // Test the data endpoint
  response = http.get('http://multitenant-api-service.platform.svc.cluster.local/api/data', {
    headers: headers,
  });

  const dataCheck = check(response, {
    'data status is 200': (r) => r.status === 200,
    'data response has status success': (r) => r.json().status === 'success',
  });

  failureRate.add(!dataCheck);
  responseTime.add(response.timings.duration);

  // Test creating a user (if applicable)
  const userData = JSON.stringify({
    name: `Test User ${Math.floor(Math.random() * 10000)}`,
  });

  response = http.post('http://multitenant-api-service.platform.svc.cluster.local/api/users', userData, {
    headers: headers,
  });

  const createUserCheck = check(response, {
    'create user status is 200': (r) => r.status === 200,
    'create user response has status success': (r) => r.json().status === 'success',
  });

  failureRate.add(!createUserCheck);
  responseTime.add(response.timings.duration);

  // Add a small delay between requests to simulate real user behavior
  sleep(0.5);
}