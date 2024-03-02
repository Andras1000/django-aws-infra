import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    vus: 1000,  // 1000 virtual users (concurrent connections)
    duration: '240s',  // Total duration of the test
};

export default function () {
    let res = http.get('http://prod-1420744051.eu-west-1.elb.amazonaws.com/health/');
    check(res, {
        'status is 200': (r) => r.status === 200,
    });
    sleep(1); // Sleep for 1 second between iterations
}
