import aws4 from 'aws4';

export async function handler(event) {
    console.log(JSON.stringify(event));
    
    const request = event.Records[0].cf.request;

    const opts = {
        method: request.method, 
        host: request.headers['host'][0].value, 
        path: request.origin['s3'].path + request.uri, 
        originType: 's3'
    };

    const { AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN } = process.env;

    aws4.sign(opts,{ accessKeyId: AWS_ACCESS_KEY_ID, secretAccessKey: AWS_SECRET_ACCESS_KEY, sessionToken: AWS_SESSION_TOKEN });

    request.headers['authorization'] = [{ key: 'Authorization', value: opts.headers['Authorization'] }];
    request.headers['x-amz-date'] = [{ key: 'X-Amz-Date', value: opts.headers['X-Amz-Date'] }];
    request.headers['x-amz-content-sha256'] = [{ key: 'X-Amz-Content-Sha256', value: opts.headers['X-Amz-Content-Sha256'] }];
    request.headers['x-amz-security-token'] = [{ key: 'X-Amz-Security-Token', value: opts.headers['X-Amz-Security-Token'] }];

    console.log(JSON.stringify(request));

    return request;
} 
