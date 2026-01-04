import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// A custom metric to track failure rates
const failureRate = new Rate('failures');

// Options for the test
export const options = {
  // Ramp up from 10 to 1000 users over 5 minutes, then maintain for 5 minutes
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
  },
};

// Default function that k6 will execute
export default function () {
  // Make a request to the API health endpoint
  const response = http.get('http://multitenant-api-service.platform.svc.cluster.local/health');

  // Check that the response is successful
  const isSuccess = check(response, {
    'status is 200': (r) => r.status === 200,
    'response has status success': (r) => r.json().status === 'success',
  });

  // Track failure rate
  failureRate.add(!isSuccess);

  // Add a small delay between requests
  sleep(1);
}