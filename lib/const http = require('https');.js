const http = require('https');

const options = {
	method: 'GET',
	hostname: 'api-football-v1.p.rapidapi.com',
	port: null,
	path: '/v3/leagues?id=140',
	headers: {
		'x-rapidapi-key': 'f5a78660bbmsh8da2d99f0a17edbp1615aejsn3221c36093ae',
		'x-rapidapi-host': 'api-football-v1.p.rapidapi.com'
	}
};

const req = http.request(options, function (res) {
	const chunks = [];

	res.on('data', function (chunk) {
		chunks.push(chunk);
	});

	res.on('end', function () {
		const body = Buffer.concat(chunks);
		console.log(body.toString());
	});
});

req.end();